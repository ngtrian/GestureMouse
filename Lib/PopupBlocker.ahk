; PopupBlocker.ahk - Tự động phát hiện và chặn/đóng popup của phần mềm desktop
#NoEnv

global PopupBlockerEnabled := 0
global PopupBlockerBlockedCount := 0
global PopupRules := []
global PopupRulesByProc := {}
global PopupActiveRuleCount := 0
global PopupPendingHwnds := {}
global PopupHandledCache := {}
global PopupPidCache := {}
global PopupBlockerLogs := []
global PopupWinEventHooks := []
global PopupWinEventCallback := 0
global PopupRulesFilePath := ""

; GUI handles & controls
global hPopupGui := 0
global hPopupEnableChk := 0
global hPopupLV := 0
global PopupLV := ""
global PopupEnableChk := 0
global PopupStatsLbl := ""
global hPopupRuleGui := 0
global hPopupLogGui := 0
global hPopupLogLV := 0
global PopupLogLV := ""
global hPopupPickFrame := 0
global PopupLastHoverHwnd := 0
global PopupLastFrameW := 0
global PopupLastFrameH := 0
global PopupCachedHoverTip := ""
global PopupPickerMode := "editor" ; "editor" hoặc "quick"

; State cho Rule Editor
global PopupEditIndex := 0
global PopupRuleEnabledChk := 1
global PopupRuleNameEdit := ""
global PopupRuleProcEdit := ""
global PopupRuleClassEdit := ""
global PopupRuleTitleEdit := ""
global PopupRuleTextEdit := ""
global PopupRuleActionDDL := ""
global PopupRuleButtonEdit := ""
global PopupRuleButtonLbl := ""
global PopupRulePickBtn := ""
global PopupIsPicking := 0

InitPopupBlocker() {
    global PopupBlockerEnabled, PopupRulesFilePath
    global PopupBlockerLogs, PopupPendingHwnds, PopupHandledCache, PopupPidCache, PopupWinEventHooks, PopupBlockerBlockedCount
    if (!IsObject(PopupBlockerLogs))
        PopupBlockerLogs := []
    if (!IsObject(PopupPendingHwnds))
        PopupPendingHwnds := {}
    if (!IsObject(PopupHandledCache))
        PopupHandledCache := {}
    if (!IsObject(PopupPidCache))
        PopupPidCache := {}
    if (!IsObject(PopupWinEventHooks))
        PopupWinEventHooks := []
    if (PopupBlockerBlockedCount = "")
        PopupBlockerBlockedCount := 0

    RegRead, savedEnabled, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, PopupBlockerEnabled
    PopupBlockerEnabled := (savedEnabled = "1") ? 1 : 0

    PopupRulesFilePath := GetPopupRulesFilePath()
    LoadPopupRules()
    OnExit("CleanupPopupBlocker")
    ApplyPopupBlockerState()
}

GetPopupRulesFilePath() {
    portablePath := A_ScriptDir . "\PopupRules.ini"
    if (FileExist(portablePath))
        return portablePath

    appDir := A_AppData . "\GestureMouse"
    if (!FileExist(appDir))
        FileCreateDir, %appDir%
    return appDir . "\PopupRules.ini"
}

SavePopupBlockerSettings() {
    global PopupBlockerEnabled
    RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, PopupBlockerEnabled, % (PopupBlockerEnabled ? 1 : 0)
}

TogglePopupBlocker() {
    global PopupBlockerEnabled
    PopupBlockerEnabled := !PopupBlockerEnabled
    SavePopupBlockerSettings()
    ApplyPopupBlockerState()
    if (IsFunc("RebuildTrayMenu"))
        RebuildTrayMenu()
    if (IsFunc("UpdateTrayTip"))
        UpdateTrayTip()
}

ApplyPopupBlockerState() {
    global PopupBlockerEnabled, PopupActiveRuleCount
    if (PopupBlockerEnabled && PopupActiveRuleCount > 0) {
        StartPopupWinEventHooks()
        ; Chỉ quét 1 lần lúc vừa bật/thêm rule, sau đó thuần 100% event-driven (0% polling)
        SetTimer, PopupBlocker_InitialScan, -100
    } else {
        StopPopupWinEventHooks()
        SetTimer, PopupBlocker_InitialScan, Off
        SetTimer, PopupBlocker_ProcessQueue, Off
    }
}

StartPopupWinEventHooks() {
    global PopupWinEventHooks, PopupWinEventCallback
    if (PopupWinEventHooks.Length() > 0)
        return

    if (!PopupWinEventCallback)
        PopupWinEventCallback := RegisterCallback("PopupBlocker_WinEventProc", "F", 7)

    ; WINEVENT_OUTOFCONTEXT | WINEVENT_SKIPOWNPROCESS = 2
    ; EVENT_SYSTEM_FOREGROUND = 0x0003, EVENT_OBJECT_SHOW = 0x8002
    h1 := DllCall("SetWinEventHook", "UInt", 0x0003, "UInt", 0x0003, "Ptr", 0, "Ptr", PopupWinEventCallback, "UInt", 0, "UInt", 0, "UInt", 2, "Ptr")
    h2 := DllCall("SetWinEventHook", "UInt", 0x8002, "UInt", 0x8002, "Ptr", 0, "Ptr", PopupWinEventCallback, "UInt", 0, "UInt", 0, "UInt", 2, "Ptr")
    if (h1)
        PopupWinEventHooks.Push(h1)
    if (h2)
        PopupWinEventHooks.Push(h2)
}

StopPopupWinEventHooks() {
    global PopupWinEventHooks
    for _, hHook in PopupWinEventHooks {
        if (hHook)
            DllCall("UnhookWinEvent", "Ptr", hHook)
    }
    PopupWinEventHooks := []
}

CleanupPopupBlocker() {
    global PopupWinEventCallback
    StopPopupWinEventHooks()
    if (PopupWinEventCallback) {
        DllCall("GlobalFree", "Ptr", PopupWinEventCallback)
        PopupWinEventCallback := 0
    }
}

; Callback nhận sự kiện từ Windows - chỉ đẩy HWND vào queue rồi thoát ngay để không block hệ thống
PopupBlocker_WinEventProc(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime) {
    global PopupBlockerEnabled, PopupPendingHwnds
    if (!PopupBlockerEnabled || !hwnd || idObject != 0 || idChild != 0)
        return
    if (!IsObject(PopupPendingHwnds))
        PopupPendingHwnds := {}
    PopupPendingHwnds[hwnd] := 1
    SetTimer, PopupBlocker_ProcessQueue, -25
}

PopupBlocker_ProcessQueue:
    ProcessPopupPendingQueue()
return

ProcessPopupPendingQueue() {
    global PopupBlockerEnabled, PopupPendingHwnds
    if (!PopupBlockerEnabled) {
        PopupPendingHwnds := {}
        return
    }
    batch := PopupPendingHwnds
    PopupPendingHwnds := {}
    for hwnd, _ in batch {
        PopupBlocker_EvaluateWindow(hwnd)
    }
}

PopupBlocker_InitialScan:
    ScanVisiblePopupWindows()
return

ScanVisiblePopupWindows() {
    global PopupBlockerEnabled, PopupActiveRuleCount
    if (!PopupBlockerEnabled || PopupActiveRuleCount <= 0)
        return

    WinGet, winList, List
    Loop, %winList% {
        hwnd := winList%A_Index%
        if (hwnd)
            PopupBlocker_EvaluateWindow(hwnd)
    }
}

PopupBlocker_GetWindowStyle(hwnd) {
    return DllCall(A_PtrSize = 8 ? "GetWindowLongPtrW" : "GetWindowLongW", "Ptr", hwnd, "Int", -16, "Ptr")
}

PopupBlocker_GetWindowClass(hwnd) {
    VarSetCapacity(buf, 512, 0)
    DllCall("GetClassNameW", "Ptr", hwnd, "Str", buf, "Int", 256)
    return buf
}

PopupBlocker_GetWindowTitle(hwnd) {
    len := DllCall("GetWindowTextLengthW", "Ptr", hwnd)
    if (len <= 0)
        return ""
    VarSetCapacity(buf, (len + 1) * 2, 0)
    DllCall("GetWindowTextW", "Ptr", hwnd, "Str", buf, "Int", len + 1)
    return buf
}

PopupBlocker_GetProcessInfo(hwnd, ByRef procName, ByRef procLower) {
    global PopupPidCache
    if (!IsObject(PopupPidCache))
        PopupPidCache := {}

    pid := 0
    DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "UInt*", pid)
    if (!pid)
        return false

    now := A_TickCount
    if (PopupPidCache.HasKey(pid)) {
        entry := PopupPidCache[pid]
        if (now - entry.ts < 60000) {
            procName := entry.name
            procLower := entry.lower
            return (procLower != "")
        }
    }

    procName := ""
    ; PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
    hProc := DllCall("OpenProcess", "UInt", 0x1000, "Int", 0, "UInt", pid, "Ptr")
    if (hProc) {
        size := 520
        VarSetCapacity(fullPath, size * 2, 0)
        ok := DllCall("Kernel32\QueryFullProcessImageNameW", "Ptr", hProc, "UInt", 0, "Str", fullPath, "UInt*", size)
        DllCall("CloseHandle", "Ptr", hProc)
        if (ok && fullPath != "") {
            SplitPath, fullPath, procName
        }
    }
    if (procName = "")
        WinGet, procName, ProcessName, ahk_id %hwnd%
    if (procName = "")
        return false

    StringLower, procLower, procName
    if (PopupPidCache.Count() > 250)
        PopupPidCache := {}
    PopupPidCache[pid] := {name: procName, lower: procLower, ts: now}
    return true
}

PopupBlocker_EvaluateWindow(hwnd) {
    global PopupBlockerEnabled, PopupActiveRuleCount, PopupRulesByProc, PopupHandledCache
    if (!PopupBlockerEnabled || PopupActiveRuleCount <= 0 || !hwnd || !DllCall("IsWindowVisible", "Ptr", hwnd))
        return false

    ; Bỏ qua nhanh cửa sổ con (WS_CHILD = 0x40000000) qua Win32 API
    if (PopupBlocker_GetWindowStyle(hwnd) & 0x40000000)
        return false

    ; Cooldown tránh xử lý lặp lại cùng một HWND trong thời gian ngắn
    now := A_TickCount
    if (PopupHandledCache.HasKey(hwnd) && (now - PopupHandledCache[hwnd] < 1500))
        return false

    ; Lọc O(1) theo PID Cache + ProcessName trước khi đọc Class/Title/Text
    if (!PopupBlocker_GetProcessInfo(hwnd, procName, procLower))
        return false
    if (!PopupRulesByProc.HasKey(procLower))
        return false

    winClass := PopupBlocker_GetWindowClass(hwnd)
    if (PopupBlocker_IsSafeToSkip(hwnd, procLower, winClass))
        return false

    winTitle := PopupBlocker_GetWindowTitle(hwnd)
    winText := ""
    hasLoadedText := false

    for _, rule in PopupRulesByProc[procLower] {
        if (rule._cClass && !PopupBlocker_MatchCompiled(winClass, rule._cClass))
            continue

        if (rule._cTitle && !PopupBlocker_MatchCompiled(winTitle, rule._cTitle))
            continue

        if (rule._cText) {
            if (!hasLoadedText) {
                WinGetText, winText, ahk_id %hwnd%
                hasLoadedText := true
            }
            if (!PopupBlocker_MatchCompiled(winText, rule._cText))
                continue
        }

        ; Đã khớp rule -> thực thi hành động
        PopupHandledCache[hwnd] := now
        CleanupPopupHandledCache(now)
        PopupBlocker_ExecuteAction(hwnd, procName, winTitle, rule)
        return true
    }
    return false
}

CleanupPopupHandledCache(now) {
    global PopupHandledCache
    if (PopupHandledCache.Count() < 120)
        return
    toRemove := []
    for k, ts in PopupHandledCache {
        if (now - ts > 5000)
            toRemove.Push(k)
    }
    for _, k in toRemove
        PopupHandledCache.Delete(k)
}

PopupBlocker_IsSafeToSkip(hwnd, procLower, winClass) {
    ; Bỏ qua cửa sổ hệ thống cốt lõi
    if (procLower = "explorer.exe") {
        if (winClass = "Shell_TrayWnd" || winClass = "Shell_SecondaryTrayWnd" || winClass = "Progman" || winClass = "WorkerW" || winClass = "NotifyIconOverflowWindow")
            return true
    }
    if (procLower = "shellexperiencehost.exe" || procLower = "searchhost.exe" || procLower = "startmenuexperiencehost.exe")
        return true

    ; Bỏ qua hộp thoại Open / Save As chuẩn của Windows (#32770 có ComboBoxEx321 + Edit1)
    if (winClass = "#32770") {
        ControlGet, hCombo, Hwnd,, ComboBoxEx321, ahk_id %hwnd%
        ControlGet, hEdit, Hwnd,, Edit1, ahk_id %hwnd%
        if (hCombo && hEdit)
            return true
    }
    return false
}

PopupBlocker_CompilePattern(pattern) {
    if (pattern = "")
        return ""
    if (SubStr(pattern, 1, 6) = "regex:")
        return {isRegex: true, raw: SubStr(pattern, 7)}
    parts := []
    Loop, Parse, pattern, |
    {
        part := Trim(A_LoopField)
        if (part != "")
            parts.Push(part)
    }
    return parts.Length() ? {isRegex: false, parts: parts} : ""
}

PopupBlocker_MatchCompiled(haystack, compiled) {
    if (!IsObject(compiled))
        return true
    if (compiled.isRegex) {
        try {
            return (RegExMatch(haystack, compiled.raw) > 0)
        } catch {
            return false
        }
    }
    for _, part in compiled.parts {
        if (InStr(haystack, part))
            return true
    }
    return false
}

PopupBlocker_ExecuteAction(hwnd, procName, winTitle, rule) {
    global PopupBlockerBlockedCount, PopupBlockerLogs, hPopupGui, PopupStatsLbl, hPopupLogGui
    action := rule.action
    if (action = "Hide") {
        WinHide, ahk_id %hwnd%
    } else if (action = "Minimize") {
        WinMinimize, ahk_id %hwnd%
    } else if (action = "Click" && rule.button != "") {
        btnText := rule.button
        ControlClick, %btnText%, ahk_id %hwnd%,,,, NA
    } else {
        ; Mặc định: Close
        PostMessage, 0x0010, 0, 0,, ahk_id %hwnd% ; WM_CLOSE
    }

    if (!IsObject(PopupBlockerLogs))
        PopupBlockerLogs := []
    PopupBlockerBlockedCount++
    FormatTime, timeStr,, HH:mm:ss
    PopupBlockerLogs.InsertAt(1, {time: timeStr, proc: procName, title: (winTitle != "" ? winTitle : rule.name), action: action, ruleName: rule.name})
    if (PopupBlockerLogs.Length() > 100)
        PopupBlockerLogs.Pop()

    if (hPopupGui && WinExist("ahk_id " . hPopupGui)) {
        GuiControl, PopupMgr:, PopupStatsLbl, % Format(L("Popup_StatsFormat"), PopupBlockerBlockedCount)
    }
    if (hPopupLogGui && WinExist("ahk_id " . hPopupLogGui)) {
        RefreshPopupLogListView()
    }
}

; ========================================================
; ĐỌC / GHI RULE & PRESET MẶC ĐỊNH
; ========================================================
LoadPopupRules() {
    global PopupRules, PopupRulesFilePath
    PopupRules := []

    if (!FileExist(PopupRulesFilePath)) {
        CreateDefaultPopupRules()
        SavePopupRules()
        RebuildPopupRulesIndex()
        return
    }

    IniRead, countStr, %PopupRulesFilePath%, Meta, Count, 0
    count := countStr + 0
    Loop, %count% {
        sec := "Rule_" . A_Index
        IniRead, rEnabled, %PopupRulesFilePath%, %sec%, Enabled, 1
        IniRead, rName,    %PopupRulesFilePath%, %sec%, Name, 
        IniRead, rProc,    %PopupRulesFilePath%, %sec%, Process, 
        IniRead, rClass,   %PopupRulesFilePath%, %sec%, Class, 
        IniRead, rTitle,   %PopupRulesFilePath%, %sec%, Title, 
        IniRead, rText,    %PopupRulesFilePath%, %sec%, Text, 
        IniRead, rAction,  %PopupRulesFilePath%, %sec%, Action, Close
        IniRead, rButton,  %PopupRulesFilePath%, %sec%, Button, 

        if (rProc != "") {
            PopupRules.Push({enabled: (rEnabled = "1" ? 1 : 0)
                , name: rName
                , process: rProc
                , class: rClass
                , title: rTitle
                , text: rText
                , action: (rAction != "" ? rAction : "Close")
                , button: rButton})
        }
    }
    RebuildPopupRulesIndex()
}

SavePopupRules() {
    global PopupRules, PopupRulesFilePath
    if (FileExist(PopupRulesFilePath))
        FileDelete, %PopupRulesFilePath%

    count := PopupRules.Length()
    IniWrite, %count%, %PopupRulesFilePath%, Meta, Count
    for idx, rule in PopupRules {
        sec := "Rule_" . idx
        IniWrite, % (rule.enabled ? 1 : 0), %PopupRulesFilePath%, %sec%, Enabled
        IniWrite, % rule.name,    %PopupRulesFilePath%, %sec%, Name
        IniWrite, % rule.process, %PopupRulesFilePath%, %sec%, Process
        IniWrite, % rule.class,   %PopupRulesFilePath%, %sec%, Class
        IniWrite, % rule.title,   %PopupRulesFilePath%, %sec%, Title
        IniWrite, % rule.text,    %PopupRulesFilePath%, %sec%, Text
        IniWrite, % rule.action,  %PopupRulesFilePath%, %sec%, Action
        IniWrite, % rule.button,  %PopupRulesFilePath%, %sec%, Button
    }
}

RebuildPopupRulesIndex() {
    global PopupRules, PopupRulesByProc, PopupActiveRuleCount
    PopupRulesByProc := {}
    PopupActiveRuleCount := 0
    for _, rule in PopupRules {
        if (!rule.enabled || rule.process = "")
            continue
        if (rule.class = "" && rule.title = "" && rule.text = "")
            continue

        rule._cClass := PopupBlocker_CompilePattern(rule.class)
        rule._cTitle := PopupBlocker_CompilePattern(rule.title)
        rule._cText  := PopupBlocker_CompilePattern(rule.text)

        tmpProc := rule.process
        StringLower, procLower, tmpProc
        if (!PopupRulesByProc.HasKey(procLower))
            PopupRulesByProc[procLower] := []
        PopupRulesByProc[procLower].Push(rule)
        PopupActiveRuleCount++
    }
    ApplyPopupBlockerState()
}

CreateDefaultPopupRules() {
    global PopupRules
    PopupRules := []
    PopupRules.Push({enabled: 1, name: "WinRAR - License Reminder", process: "WinRAR.exe", class: "#32770", title: "Please purchase WinRAR|WinRAR Evaluation", text: "", action: "Close", button: ""})
    PopupRules.Push({enabled: 1, name: "IDM - Update Available", process: "IDMan.exe", class: "#32770", title: "Internet Download Manager Update|New version of IDM", text: "", action: "Close", button: ""})
    PopupRules.Push({enabled: 1, name: "IDM - Registration Prompt", process: "IDMan.exe", class: "#32770", title: "Internet Download Manager Registration", text: "", action: "Close", button: ""})
    PopupRules.Push({enabled: 1, name: "Adobe Reader - Updater", process: "AdobeARM.exe", class: "", title: "Adobe Reader|Update", text: "", action: "Close", button: ""})
    PopupRules.Push({enabled: 0, name: "Driver Booster - Promo / Pro", process: "DriverBooster.exe", class: "", title: "Special Offer|Upgrade|PRO|Update", text: "", action: "Close", button: ""})
    PopupRules.Push({enabled: 0, name: "Zalo - Update / Promo Popup", process: "Zalo.exe", class: "Qt5QWindowPopupDropShadowSaveBits", title: "Cập nhật|Update|Quảng cáo", text: "", action: "Close", button: ""})
    PopupRules.Push({enabled: 0, name: "Teams - Update Notification", process: "ms-teams.exe", class: "", title: "Update|Cập nhật", text: "", action: "Close", button: ""})
}

; ========================================================
; GIAO DIỆN QUẢN LÝ CHẶN POPUP
; ========================================================
OpenPopupBlockerGui() {
    global hPopupGui, hPopupEnableChk, hPopupLV, PopupLV, PopupEnableChk, PopupStatsLbl
    global PopupBlockerEnabled, PopupBlockerBlockedCount, hSettingsGui

    if (hPopupGui && WinExist("ahk_id " . hPopupGui)) {
        RefreshPopupRulesListView()
        Gui, PopupMgr:Show
        WinActivate, ahk_id %hPopupGui%
        return
    }

    ownerOpt := (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) ? "+Owner" . hSettingsGui : ""
    Gui, PopupMgr:New, %ownerOpt% +AlwaysOnTop -MaximizeBox -MinimizeBox +HwndhPopupGui, % L("Popup_MgrTitle")
    Gui, PopupMgr:Color, F8F9FA
    Gui, PopupMgr:Font, s9.5 Bold c1E293B, Segoe UI
    Gui, PopupMgr:Add, Checkbox, x16 y12 w360 h22 vPopupEnableChk gOnPopupMgrToggleEnable Checked%PopupBlockerEnabled% +HwndhPopupEnableChk, % L("Popup_EnableLabel")

    Gui, PopupMgr:Font, s9 Norm c475569, Segoe UI
    Gui, PopupMgr:Add, Text, x386 y14 w240 h20 Right vPopupStatsLbl, % Format(L("Popup_StatsFormat"), PopupBlockerBlockedCount)

    Gui, PopupMgr:Font, s9 Norm c1E293B, Segoe UI
    Gui, PopupMgr:Add, ListView, x16 y42 w610 h270 Checked Grid NoSortHdr vPopupLV gOnPopupListViewEvent +HwndhPopupLV
        , % L("Popup_ColName") . "|" . L("Popup_ColProc") . "|" . L("Popup_ColMatch") . "|" . L("Popup_ColAction")

    Gui, PopupMgr:Add, Button, x16 y322 w138 h28 gOnPopupQuickPickBtn, % L("Popup_QuickPickBtn")
    Gui, PopupMgr:Add, Button, x160 y322 w100 h28 gOnPopupAddBtn, % L("Popup_BtnAdd")
    Gui, PopupMgr:Add, Button, x266 y322 w76 h28 gOnPopupEditBtn, % L("Popup_BtnEdit")
    Gui, PopupMgr:Add, Button, x348 y322 w76 h28 gOnPopupDeleteBtn, % L("Popup_BtnDelete")
    Gui, PopupMgr:Add, Button, x430 y322 w94 h28 gOnPopupLogBtn, % L("Popup_BtnLog")
    Gui, PopupMgr:Add, Button, x530 y322 w96 h28 gOnPopupCloseBtn, % L("Set_Close")

    Gui, PopupMgr:Font, s8.5 Norm c64748B, Segoe UI
    Gui, PopupMgr:Add, Text, x16 y358 w610 h20, % L("Popup_HintSafety")

    RefreshPopupRulesListView()
    Gui, PopupMgr:Show, w642 h386 Center, % L("Popup_MgrTitle")
}

RefreshPopupRulesListView() {
    global PopupRules, hPopupLV
    if (!hPopupLV)
        return
    Gui, PopupMgr:Default
    Gui, PopupMgr:ListView, PopupLV
    LV_Delete()
    for _, rule in PopupRules {
        matchSummary := ""
        if (rule.title != "")
            matchSummary .= rule.title
        if (rule.class != "")
            matchSummary .= (matchSummary != "" ? " | " : "") . "[" . rule.class . "]"
        if (rule.text != "")
            matchSummary .= (matchSummary != "" ? " | " : "") . "{" . rule.text . "}"

        actTxt := rule.action
        if (rule.action = "Click" && rule.button != "")
            actTxt := "Click: " . rule.button

        checkOpt := rule.enabled ? "Check" : ""
        LV_Add(checkOpt, rule.name, rule.process, matchSummary, actTxt)
    }
    LV_ModifyCol(1, 170)
    LV_ModifyCol(2, 115)
    LV_ModifyCol(3, 210)
    LV_ModifyCol(4, 90)
}

OnPopupMgrToggleEnable:
    Gui, PopupMgr:Submit, NoHide
    PopupBlockerEnabled := PopupEnableChk ? 1 : 0
    SavePopupBlockerSettings()
    ApplyPopupBlockerState()
    if (IsFunc("RebuildTrayMenu"))
        RebuildTrayMenu()
    if (IsFunc("UpdateTrayTip"))
        UpdateTrayTip()
    if (IsFunc("SyncPopupBlockerSettingsUI"))
        SyncPopupBlockerSettingsUI()
return

OnPopupListViewEvent:
    if (A_GuiEvent = "I" && InStr(ErrorLevel, "C", true)) {
        row := A_EventInfo
        if (row >= 1 && row <= PopupRules.Length()) {
            Gui, PopupMgr:Default
            Gui, PopupMgr:ListView, PopupLV
            isChecked := (LV_GetNext(row - 1, "Checked") = row) ? 1 : 0
            if (PopupRules[row].enabled != isChecked) {
                PopupRules[row].enabled := isChecked
                SavePopupRules()
                RebuildPopupRulesIndex()
            }
        }
    } else if (A_GuiEvent = "DoubleClick" && A_EventInfo >= 1) {
        OpenPopupRuleEditor(A_EventInfo)
    }
return

OnPopupQuickPickBtn:
    StartPopupWindowPicker("quick")
return

OnPopupAddBtn:
    OpenPopupRuleEditor(0)
return

OnPopupEditBtn:
    Gui, PopupMgr:Default
    Gui, PopupMgr:ListView, PopupLV
    selRow := LV_GetNext(0, "Focused")
    if (!selRow)
        selRow := LV_GetNext(0)
    if (selRow >= 1)
        OpenPopupRuleEditor(selRow)
return

OnPopupDeleteBtn:
    Gui, PopupMgr:Default
    Gui, PopupMgr:ListView, PopupLV
    selRow := LV_GetNext(0, "Focused")
    if (!selRow)
        selRow := LV_GetNext(0)
    if (selRow >= 1 && selRow <= PopupRules.Length()) {
        PopupRules.RemoveAt(selRow)
        SavePopupRules()
        RebuildPopupRulesIndex()
        RefreshPopupRulesListView()
    }
return

OnPopupLogBtn:
    OpenPopupBlockerLogGui()
return

OnPopupCloseBtn:
PopupMgrGuiClose:
PopupMgrGuiEscape:
    Gui, PopupMgr:Destroy
    hPopupGui := 0
    hPopupLV := 0
return

; ========================================================
; HỘP THOẠI THÊM / SỬA RULE + BẮT CỬA SỔ MẪU (WINDOW PICKER)
; ========================================================
OpenPopupRuleEditor(editIdx := 0, prefill := "") {
    global hPopupRuleGui, hPopupGui, PopupEditIndex, PopupRules
    global PopupRuleEnabledChk, PopupRuleNameEdit, PopupRuleProcEdit, PopupRuleClassEdit
    global PopupRuleTitleEdit, PopupRuleTextEdit, PopupRuleActionDDL, PopupRuleButtonEdit, PopupRuleButtonLbl, PopupRulePickBtn

    PopupEditIndex := editIdx
    initBtns := ""
    if (editIdx >= 1 && editIdx <= PopupRules.Length()) {
        r := PopupRules[editIdx]
        initEn := r.enabled
        initName := r.name
        initProc := r.process
        initClass := r.class
        initTitle := r.title
        initText := r.text
        initAct := r.action
        initBtn := r.button
        dlgTitle := L("Popup_EditRuleTitle")
    } else if (IsObject(prefill)) {
        initEn := 1
        initName := prefill.name
        initProc := prefill.process
        initClass := prefill.class
        initTitle := prefill.title
        initText := prefill.text
        initAct := "Close"
        initBtn := ""
        initBtns := prefill.buttons
        dlgTitle := L("Popup_AddRuleTitle")
    } else {
        initEn := 1
        initName := ""
        initProc := ""
        initClass := ""
        initTitle := ""
        initText := ""
        initAct := "Close"
        initBtn := ""
        dlgTitle := L("Popup_AddRuleTitle")
    }

    if (hPopupRuleGui && WinExist("ahk_id " . hPopupRuleGui))
        Gui, PopupRule:Destroy

    ownerOpt := (hPopupGui && WinExist("ahk_id " . hPopupGui)) ? "+Owner" . hPopupGui : ""
    Gui, PopupRule:New, %ownerOpt% +AlwaysOnTop -MaximizeBox -MinimizeBox +HwndhPopupRuleGui, %dlgTitle%
    Gui, PopupRule:Color, F8F9FA
    Gui, PopupRule:Font, s9 Norm c1E293B, Segoe UI

    Gui, PopupRule:Add, Button, x16 y12 w418 h30 vPopupRulePickBtn gOnPopupStartWindowPicker, % L("Popup_PickWindowBtn")

    Gui, PopupRule:Add, Text, x16 y54 w110 h20, % L("Popup_FieldName")
    Gui, PopupRule:Add, Edit, x130 y51 w304 h23 vPopupRuleNameEdit, %initName%

    Gui, PopupRule:Add, Text, x16 y86 w110 h20, % L("Popup_FieldProc")
    Gui, PopupRule:Add, Edit, x130 y83 w304 h23 vPopupRuleProcEdit, %initProc%

    Gui, PopupRule:Add, Text, x16 y118 w110 h20, % L("Popup_FieldClass")
    Gui, PopupRule:Add, Edit, x130 y115 w304 h23 vPopupRuleClassEdit, %initClass%

    Gui, PopupRule:Add, Text, x16 y150 w110 h20, % L("Popup_FieldTitle")
    Gui, PopupRule:Add, Edit, x130 y147 w304 h23 vPopupRuleTitleEdit, %initTitle%

    Gui, PopupRule:Add, Text, x16 y182 w110 h20, % L("Popup_FieldText")
    Gui, PopupRule:Add, Edit, x130 y179 w304 h23 vPopupRuleTextEdit, %initText%

    actIdx := (initAct = "Hide") ? 2 : (initAct = "Minimize") ? 3 : (initAct = "Click") ? 4 : 1
    Gui, PopupRule:Add, Text, x16 y214 w110 h20, % L("Popup_FieldAction")
    Gui, PopupRule:Add, DropDownList, x130 y211 w304 vPopupRuleActionDDL gOnPopupActionDDLChange Choose%actIdx%, Close|Hide|Minimize|Click

    Gui, PopupRule:Add, Text, x16 y246 w110 h20 vPopupRuleButtonLbl, % L("Popup_FieldButton")
    btnList := (initBtns != "") ? initBtns : ((initBtn != "") ? initBtn . "||Close|Cancel|Later|No|OK" : "Close|Cancel|Later|No|OK")
    Gui, PopupRule:Add, ComboBox, x130 y243 w304 vPopupRuleButtonEdit, %btnList%
    if (initBtn != "")
        GuiControl, PopupRule:Text, PopupRuleButtonEdit, %initBtn%

    Gui, PopupRule:Add, Checkbox, x130 y276 w250 h22 vPopupRuleEnabledChk Checked%initEn%, % L("Popup_FieldEnabled")

    Gui, PopupRule:Add, Button, x246 y308 w90 h28 Default gOnPopupRuleSaveBtn, % L("Popup_BtnSave")
    Gui, PopupRule:Add, Button, x344 y308 w90 h28 gPopupRuleGuiClose, % L("Popup_BtnCancel")

    btnEnable := (actIdx = 4) ? 1 : 0
    GuiControl, PopupRule:Enable%btnEnable%, PopupRuleButtonEdit
    Gui, PopupRule:Show, w450 h350 Center, %dlgTitle%
}

OnPopupActionDDLChange:
    Gui, PopupRule:Submit, NoHide
    isClick := (PopupRuleActionDDL = "Click") ? 1 : 0
    GuiControl, PopupRule:Enable%isClick%, PopupRuleButtonEdit
return

OnPopupStartWindowPicker:
    StartPopupWindowPicker("editor")
return

StartPopupWindowPicker(mode := "editor") {
    global PopupIsPicking, PopupPickerMode, hPopupRuleGui, hPopupGui, hSettingsGui
    global PopupLastHoverHwnd, PopupLastFrameW, PopupLastFrameH, PopupCachedHoverTip
    if (PopupIsPicking)
        return
    PopupIsPicking := 1
    PopupPickerMode := mode
    PopupLastHoverHwnd := 0
    PopupLastFrameW := 0
    PopupLastFrameH := 0
    PopupCachedHoverTip := L("Popup_PickGuideTip")

    if (hPopupRuleGui)
        Gui, PopupRule:Hide
    if (hPopupGui)
        Gui, PopupMgr:Hide
    if (mode = "quick" && hSettingsGui && WinExist("ahk_id " . hSettingsGui))
        Gui, Settings:Hide

    ; Đổi con trỏ chuột sang Crosshair để báo hiệu chế độ chọn cửa sổ
    hCross := DllCall("LoadCursor", "Ptr", 0, "Ptr", 32515, "Ptr")
    if (hCross) {
        for _, cid in [32512, 32513, 32649] {
            hCopy := DllCall("CopyIcon", "Ptr", hCross, "Ptr")
            DllCall("SetSystemCursor", "Ptr", hCopy, "UInt", cid)
        }
    }

    ToolTip, %PopupCachedHoverTip%
    SetTimer, PopupPicker_TrackHover, 45
    Hotkey, *LButton, OnPopupPickConfirm, On
    Hotkey, Esc, OnPopupPickCancel, On
}

PopupPicker_TrackHover:
    UpdatePopupPickerHover()
return

UpdatePopupPickerHover() {
    global PopupIsPicking, PopupLastHoverHwnd, PopupCachedHoverTip, hPopupPickFrame, hPopupRuleGui, hPopupGui, hSettingsGui
    if (!PopupIsPicking)
        return

    MouseGetPos, mx, my, hoverHwnd
    if (!hoverHwnd || hoverHwnd = hPopupPickFrame || hoverHwnd = hPopupRuleGui || hoverHwnd = hPopupGui || hoverHwnd = hSettingsGui)
        return

    if (hoverHwnd != PopupLastHoverHwnd) {
        PopupLastHoverHwnd := hoverHwnd
        WinGet, hProc, ProcessName, ahk_id %hoverHwnd%
        WinGetClass, hClass, ahk_id %hoverHwnd%
        WinGetTitle, hTitle, ahk_id %hoverHwnd%
        WinGetPos, wx, wy, ww, wh, ahk_id %hoverHwnd%
        if (ww > 0 && wh > 0)
            ShowPopupPickHighlightFrame(wx, wy, ww, wh)

        shortTitle := StrLen(hTitle) > 45 ? SubStr(hTitle, 1, 45) . "..." : hTitle
        PopupCachedHoverTip := L("Popup_PickGuideTip") . "`n[" . hProc . "]  Class: " . hClass . (shortTitle != "" ? "`nTitle: " . shortTitle : "")
    }
    ToolTip, %PopupCachedHoverTip%, % (mx + 18), % (my + 18)
}

ShowPopupPickHighlightFrame(x, y, w, h) {
    global hPopupPickFrame, PopupLastFrameW, PopupLastFrameH
    b := 3
    if (!hPopupPickFrame || !WinExist("ahk_id " . hPopupPickFrame)) {
        Gui, PopupPickFrame:New, +AlwaysOnTop -Caption +ToolWindow +E0x20 +HwndhPopupPickFrame
        Gui, PopupPickFrame:Color, FF5722
        PopupLastFrameW := 0
        PopupLastFrameH := 0
    }
    Gui, PopupPickFrame:Show, NoActivate x%x% y%y% w%w% h%h%
    if (w != PopupLastFrameW || h != PopupLastFrameH) {
        PopupLastFrameW := w
        PopupLastFrameH := h
        ix := b, iy := b, iw := w - b, ih := h - b
        if (iw > ix && ih > iy) {
            WinSet, Region, 0-0 %w%-0 %w%-%h% 0-%h% 0-0  %ix%-%iy% %iw%-%iy% %iw%-%ih% %ix%-%ih% %ix%-%iy%, ahk_id %hPopupPickFrame%
        }
    }
}

HidePopupPickHighlightFrame() {
    global hPopupPickFrame, PopupLastFrameW, PopupLastFrameH
    if (hPopupPickFrame && WinExist("ahk_id " . hPopupPickFrame))
        Gui, PopupPickFrame:Destroy
    hPopupPickFrame := 0
    PopupLastFrameW := 0
    PopupLastFrameH := 0
}

OnPopupPickConfirm:
    FinishPopupWindowPicker(true)
return

OnPopupPickCancel:
    FinishPopupWindowPicker(false)
return

FinishPopupWindowPicker(confirmed) {
    global PopupIsPicking, PopupPickerMode, hPopupRuleGui, hPopupGui, hSettingsGui, hPopupPickFrame, PopupLastHoverHwnd
    SetTimer, PopupPicker_TrackHover, Off
    Hotkey, *LButton, Off
    Hotkey, Esc, Off
    ToolTip
    HidePopupPickHighlightFrame()
    DllCall("SystemParametersInfo", "UInt", 0x57, "UInt", 0, "Ptr", 0, "UInt", 0)
    PopupIsPicking := 0

    pickedData := ""
    if (confirmed) {
        MouseGetPos,,, pickedHwnd
        if (!pickedHwnd || pickedHwnd = hPopupPickFrame)
            pickedHwnd := PopupLastHoverHwnd
        if (pickedHwnd && pickedHwnd != hPopupRuleGui && pickedHwnd != hPopupGui && pickedHwnd != hSettingsGui) {
            WinGet, pProc, ProcessName, ahk_id %pickedHwnd%
            WinGetClass, pClass, ahk_id %pickedHwnd%
            WinGetTitle, pTitle, ahk_id %pickedHwnd%
            suggestedName := pProc . (pTitle != "" ? " - " . SubStr(pTitle, 1, 28) : "")
            pTextHint := ""
            if (pTitle = "") {
                WinGetText, pText, ahk_id %pickedHwnd%
                Loop, Parse, pText, `n, `r
                {
                    lineTxt := Trim(A_LoopField)
                    if (StrLen(lineTxt) >= 4) {
                        pTextHint := SubStr(lineTxt, 1, 60)
                        break
                    }
                }
            }
            btnItems := CollectPopupWindowButtons(pickedHwnd)
            pickedData := {name: suggestedName, process: pProc, class: pClass, title: pTitle, text: pTextHint, buttons: btnItems}
        }
    }

    if (PopupPickerMode = "quick") {
        if (hSettingsGui && WinExist("ahk_id " . hSettingsGui))
            Gui, Settings:Show
        if (hPopupGui)
            Gui, PopupMgr:Show
        if (IsObject(pickedData))
            OpenPopupRuleEditor(0, pickedData)
        return
    }

    if (IsObject(pickedData)) {
        GuiControl, PopupRule:, PopupRuleProcEdit, % pickedData.process
        GuiControl, PopupRule:, PopupRuleClassEdit, % pickedData.class
        GuiControl, PopupRule:, PopupRuleTitleEdit, % pickedData.title
        GuiControlGet, curName, PopupRule:, PopupRuleNameEdit
        if (curName = "")
            GuiControl, PopupRule:, PopupRuleNameEdit, % pickedData.name
        if (pickedData.text != "")
            GuiControl, PopupRule:, PopupRuleTextEdit, % pickedData.text
        if (pickedData.buttons != "")
            GuiControl, PopupRule:, PopupRuleButtonEdit, % "|" . pickedData.buttons
    }

    if (hPopupGui)
        Gui, PopupMgr:Show
    if (hPopupRuleGui)
        Gui, PopupRule:Show
}

CollectPopupWindowButtons(hwnd) {
    WinGet, ctrlList, ControlList, ahk_id %hwnd%
    btns := ""
    seen := {}
    Loop, Parse, ctrlList, `n
    {
        ctrl := Trim(A_LoopField)
        if (SubStr(ctrl, 1, 6) = "Button") {
            ControlGetText, btnTxt, %ctrl%, ahk_id %hwnd%
            btnTxt := Trim(StrReplace(btnTxt, "&", ""))
            if (btnTxt != "" && !seen.HasKey(btnTxt)) {
                seen[btnTxt] := 1
                btns .= (btns = "" ? "" : "|") . btnTxt
            }
        }
    }
    return btns
}

OnPopupRuleSaveBtn:
    Gui, PopupRule:Submit, NoHide
    rProc := Trim(PopupRuleProcEdit)
    rClass := Trim(PopupRuleClassEdit)
    rTitle := Trim(PopupRuleTitleEdit)
    rText := Trim(PopupRuleTextEdit)
    rName := Trim(PopupRuleNameEdit)
    rBtn := Trim(PopupRuleButtonEdit)

    if (rProc = "") {
        MsgBox, 48, % L("Popup_MgrTitle"), % L("Popup_ErrNoProc")
        return
    }
    if (rClass = "" && rTitle = "" && rText = "") {
        MsgBox, 48, % L("Popup_MgrTitle"), % L("Popup_ErrNoCondition")
        return
    }
    if (rName = "")
        rName := rProc . (rTitle != "" ? " - " . SubStr(rTitle, 1, 28) : "")

    newRule := {enabled: (PopupRuleEnabledChk ? 1 : 0)
        , name: rName
        , process: rProc
        , class: rClass
        , title: rTitle
        , text: rText
        , action: PopupRuleActionDDL
        , button: rBtn}

    if (PopupEditIndex >= 1 && PopupEditIndex <= PopupRules.Length())
        PopupRules[PopupEditIndex] := newRule
    else
        PopupRules.Push(newRule)

    SavePopupRules()
    RebuildPopupRulesIndex()
    RefreshPopupRulesListView()
    Gui, PopupRule:Destroy
    hPopupRuleGui := 0
return

PopupRuleGuiClose:
PopupRuleGuiEscape:
    if (PopupIsPicking)
        FinishPopupWindowPicker(false)
    Gui, PopupRule:Destroy
    hPopupRuleGui := 0
return

; ========================================================
; HỘP THOẠI NHẬT KÝ ĐÃ CHẶN
; ========================================================
OpenPopupBlockerLogGui() {
    global hPopupLogGui, hPopupLogLV, hPopupGui, PopupLogLV, PopupBlockerLogs
    if (hPopupLogGui && WinExist("ahk_id " . hPopupLogGui)) {
        RefreshPopupLogListView()
        Gui, PopupLog:Show
        return
    }

    Gui, PopupLog:New, +Owner%hPopupGui% +AlwaysOnTop -MaximizeBox -MinimizeBox +HwndhPopupLogGui, % L("Popup_LogTitle")
    Gui, PopupLog:Color, F8F9FA
    Gui, PopupLog:Font, s9 Norm c1E293B, Segoe UI
    Gui, PopupLog:Add, ListView, x14 y14 w540 h240 Grid NoSortHdr vPopupLogLV +HwndhPopupLogLV
        , % L("Popup_LogColTime") . "|" . L("Popup_ColProc") . "|" . L("Popup_LogColTitle") . "|" . L("Popup_ColAction")
    Gui, PopupLog:Add, Button, x14 y264 w110 h26 gOnPopupClearLogBtn, % L("Popup_BtnClearLog")
    Gui, PopupLog:Add, Button, x464 y264 w90 h26 gPopupLogGuiClose, % L("Set_Close")

    RefreshPopupLogListView()
    Gui, PopupLog:Show, w568 h302 Center, % L("Popup_LogTitle")
}

RefreshPopupLogListView() {
    global PopupBlockerLogs, hPopupLogLV
    Gui, PopupLog:Default
    if (hPopupLogLV)
        Gui, PopupLog:ListView, %hPopupLogLV%
    else
        Gui, PopupLog:ListView, PopupLogLV
    LV_Delete()
    if (IsObject(PopupBlockerLogs)) {
        for _, item in PopupBlockerLogs {
            LV_Add("", item.time, item.proc, item.title, item.action)
        }
    }
    LV_ModifyCol(1, 70)
    LV_ModifyCol(2, 120)
    LV_ModifyCol(3, 250)
    LV_ModifyCol(4, 80)
}

OnPopupClearLogBtn:
    PopupBlockerLogs := []
    RefreshPopupLogListView()
return

PopupLogGuiClose:
PopupLogGuiEscape:
    Gui, PopupLog:Destroy
    hPopupLogGui := 0
    hPopupLogLV := 0
return
