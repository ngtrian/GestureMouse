; LockManager.ahk - Trung tâm Khóa hợp nhất (Khóa phím & chuột, Khóa màn hình Windows, Focus Lock, Hẹn giờ & Lặp lại)
#NoEnv

#Include *i Language.ahk

; ========================================================
; KHAI BÁO BIẾN TOÀN CỤC CHO HỆ THỐNG KHÓA HỢP NHẤT
; ========================================================
global isLocked                  := 0         ; Trạng thái khóa thiết bị (1: Đang khóa, 0: Mở)
global lockMode                  := 0         ; 0: Full Lock, 1: Focus Lock
global hFocusWnd                 := 0         ; HWND cửa sổ đang được Focus Lock
global focusWndTitle             := ""        ; Tiêu đề cửa sổ Focus Lock
global hPendingFocusWnd          := 0         ; HWND cửa sổ active ngay trước khi mở Trung tâm Khóa
global pendingFocusTitle         := ""        ; Tiêu đề cửa sổ mục tiêu tiềm năng

; Cấu hình thiết bị & ngoại lệ (Lưu trong Settings)
global lockKeyboardEnabled       := 1
global mouseLockEnabled          := 1
global lockMouseClick            := 1
global lockMouseWheel            := 0
global lockMouseMove             := 0
global allowMouseMove            := 1
global allowMouseWheel           := 0
global allowSpace                := 0
global allowMedia                := 0
global allowNav                  := 0
global autoLockIdleEnabled       := 1
global autoLockIdleMinutes       := 5
global preventScreenOff          := 0
global preventSleep              := 1
global UNLOCK_KEYWORD            := "unlock"
global KEYWORD_LENGTH            := 6
global requireCodeForTimerEdit   := 1         ; Yêu cầu mã mở khóa khi sửa/hủy hẹn giờ đang chạy
global windowsLogonOnly          := 0         ; Chỉ dùng màn hình khóa Windows để mở khóa (bỏ qua mã riêng)
global alwaysShowLockToast       := 1         ; 1: Luôn hiện thông báo khóa, 0: Tự ẩn sau 4.5 giây

; Cấu hình Trung tâm Khóa gần nhất
global centerLockType            := 0         ; 0: Full Lock, 1: Windows Screen Lock, 2: Focus Lock
global centerUseTimer            := 0         ; 0: Khóa ngay, 1: Hẹn giờ
global centerTimerMinutes        := 5         ; Số phút hẹn giờ mặc định
global centerRepeat              := 0         ; 0: Một lần, 1: Lặp lại định kỳ

; Trạng thái bộ đếm ngược đang chạy
global lockTimerActive           := 0
global lockTimerType             := 0         ; 0: Full Lock, 1: Windows Screen Lock
global lockTimerMinutes          := 5
global lockTimerRepeat           := 0
global lockTimerTargetTick       := 0
global lockTimerLastDisplayed    := ""
global pendingRepeatFullLock     := 0
global pendingRepeatMinutes      := 0

; Handles & UI state
global hKeyboardHook             := 0
global hMouseHook                := 0
global Buffer                    := ""
global hLockCenterGui            := 0
global hLockCountdownGui         := 0
global hToastBannerGui           := 0
global hFocusUnlockGui           := 0
global centerEditUnlocked        := 1
global focusCandidateHwnds       := []
global focusCandidateTitles      := []
global LockCenterTooltips        := {}
global LastLockCenterTipHwnd     := 0
global isLockCenterBuilding      := 0

; Biến control của GUI Trung tâm Khóa & Mở khóa Focus Lock
global FocusUnlockCodeInput, FocusUnlockErrorTxt
global CenterActiveBanner, CenterType0, CenterType1, CenterType2, CenterIconKB, CenterIconMouse, CenterIconWarn, CenterBtnLockSettings
global hCenterIconKB, hCenterIconMouse, hCenterIconWarn
global CenterTimerGroup, CenterTimingNow, CenterTimingTimer, CenterMinutesInput, CenterMinutesUpDown, CenterMinUnitTxt
global CenterPreset5, CenterPreset15, CenterPreset30, CenterPreset60, CenterRepeatCheck
global CenterFocusInfoGroup, CenterFocusSelectLbl, CenterFocusWndChoice, CenterFocusInfoTxt
global CenterAuthGroup, CenterAuthLabel, CenterAuthInput, CenterAuthBtn
global CenterBtnApply, CenterBtnCancelTimer, CenterBtnClose

; ========================================================
; PHÍM TẮT DUY NHẤT CTRL + ALT + L (HOẠT ĐỘNG MỌI LÚC)
; ========================================================
#If
LockCenterHotkey:
^!l::
    KeyWait, Ctrl
    KeyWait, Alt
    KeyWait, l
    HandleLockCenterHotkey()
return

; ========================================================
; KHỞI TẠO & ĐỌC CẤU HÌNH TỪ REGISTRY
; ========================================================
InitLockManager() {
    LoadLockSettings()
    InitAutoLockTimer()
    ResumePendingRepeatIfNeeded()
}

LoadLockSettings() {
    global
    regPath := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"

    RegRead, val, %regPath%, LockKeyboard
    lockKeyboardEnabled := (val != "") ? val : 1

    RegRead, val, %regPath%, mouseLockEnabled
    mouseLockEnabled := (val != "") ? val : 1

    RegRead, val, %regPath%, LockMouseClick
    lockMouseClick := (val != "") ? val : 1

    RegRead, val, %regPath%, LockMouseWheel
    lockMouseWheel := (val != "") ? val : 0

    RegRead, val, %regPath%, LockMouseMove
    lockMouseMove := (val != "") ? val : 0

    RegRead, val, %regPath%, AllowMouseMove
    allowMouseMove := (val != "") ? val : 1

    RegRead, val, %regPath%, AllowMouseWheel
    allowMouseWheel := (val != "") ? val : 0

    RegRead, val, %regPath%, AllowSpace
    allowSpace := (val != "") ? val : 0

    RegRead, val, %regPath%, AllowMedia
    allowMedia := (val != "") ? val : 0

    RegRead, val, %regPath%, AllowNav
    allowNav := (val != "") ? val : 0

    RegRead, val, %regPath%, AutoLockIdleEnabled
    autoLockIdleEnabled := (val != "") ? val : 1

    RegRead, val, %regPath%, AutoLockIdleMinutes
    if (val != "")
        autoLockIdleMinutes := val
    else {
        RegRead, valOld, %regPath%, AutoLockMinutes
        autoLockIdleMinutes := (valOld != "") ? valOld : 5
    }

    RegRead, val, %regPath%, UnlockKeyword
    if (val != "")
        UNLOCK_KEYWORD := val
    else if (!UNLOCK_KEYWORD)
        UNLOCK_KEYWORD := "unlock"
    KEYWORD_LENGTH := StrLen(UNLOCK_KEYWORD)

    RegRead, valLegacy, %regPath%, DisableAutoLockScreen
    RegRead, valScreenOff, %regPath%, PreventScreenOff
    if (valScreenOff != "")
        preventScreenOff := valScreenOff ? 1 : 0
    else
        preventScreenOff := 0

    RegRead, valSleep, %regPath%, PreventSleep
    if (valSleep != "")
        preventSleep := valSleep ? 1 : 0
    else
        preventSleep := (valLegacy != "") ? (valLegacy ? 1 : 0) : 1

    RegRead, val, %regPath%, RequireCodeForTimerEdit
    requireCodeForTimerEdit := (val != "") ? val : 1

    RegRead, val, %regPath%, WindowsLogonOnly
    windowsLogonOnly := (val != "") ? (val ? 1 : 0) : 0

    RegRead, val, %regPath%, AlwaysShowLockToast
    alwaysShowLockToast := (val != "") ? (val ? 1 : 0) : 1

    RegRead, val, %regPath%, CenterLockType
    centerLockType := (val != "" && val >= 0 && val <= 2) ? val + 0 : 0

    RegRead, val, %regPath%, CenterUseTimer
    centerUseTimer := (val != "") ? (val ? 1 : 0) : 0

    RegRead, val, %regPath%, CenterTimerMinutes
    centerTimerMinutes := (val != "" && val > 0) ? val + 0 : 5

    RegRead, val, %regPath%, CenterRepeat
    centerRepeat := (val != "") ? (val ? 1 : 0) : 0
}

SaveLockCenterPreferences() {
    global centerLockType, centerUseTimer, centerTimerMinutes, centerRepeat
    regPath := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"
    RegWrite, REG_DWORD, %regPath%, CenterLockType, %centerLockType%
    RegWrite, REG_DWORD, %regPath%, CenterUseTimer, %centerUseTimer%
    RegWrite, REG_DWORD, %regPath%, CenterTimerMinutes, %centerTimerMinutes%
    RegWrite, REG_DWORD, %regPath%, CenterRepeat, %centerRepeat%
}

; ========================================================
; TỰ ĐỘNG KHÓA KHI KHÔNG DÙNG MÁY (IDLE AUTO-LOCK)
; ========================================================
global lastIdleBusyTick := 0

InitAutoLockTimer() {
    global autoLockIdleEnabled, autoLockIdleMinutes, lastIdleBusyTick
    lastIdleBusyTick := A_TickCount
    if (autoLockIdleEnabled && autoLockIdleMinutes > 0)
        SetTimer, CheckAutoLockIdle, 4000
    else
        SetTimer, CheckAutoLockIdle, Off
}

CheckAutoLockIdle:
    if (isLocked || lockTimerActive) {
        lastIdleBusyTick := A_TickCount
        return
    }
    if (autoLockIdleEnabled && autoLockIdleMinutes > 0) {
        if (IsUserBusyWatchingVideo()) {
            lastIdleBusyTick := A_TickCount
            return
        }
        idleMs := A_TimeIdlePhysical
        if (lastIdleBusyTick > 0) {
            sinceBusyMs := A_TickCount - lastIdleBusyTick
            if (sinceBusyMs < idleMs)
                idleMs := sinceBusyMs
        }
        idleSeconds := idleMs // 1000
        thresholdSec := autoLockIdleMinutes * 60
        if (idleSeconds >= thresholdSec) {
            ActivateLock(0)
        }
    }
return

; Nhận biết người dùng đang xem video / chạy ứng dụng toàn màn hình (SMTC + Fullscreen)
IsUserBusyWatchingVideo() {
    if (IsFullscreenOrPresentationBusy())
        return true
    if (IsVideoOrMediaPlayingSMTC())
        return true
    return false
}

; Kiểm tra trạng thái Fullscreen / Direct3D Fullscreen / Presentation Mode của Windows
IsFullscreenOrPresentationBusy() {
    state := 0
    hr := DllCall("shell32\SHQueryUserNotificationState", "Int*", state)
    if (hr != 0)
        return false
    ; 2: QUNS_BUSY (Fullscreen), 3: QUNS_RUNNING_D3D_FULL_SCREEN, 4: QUNS_PRESENTATION_MODE, 7: QUNS_APP
    return (state = 2 || state = 3 || state = 4 || state = 7)
}

; Kiểm tra phiên media đang ở trạng thái Playing qua Windows SMTC (WinRT)
IsVideoOrMediaPlayingSMTC() {
    static hCombase := 0, roInited := 0
    if (!hCombase) {
        hCombase := DllCall("LoadLibrary", "Str", "combase.dll", "Ptr")
        if (!hCombase)
            return false
    }
    if (!roInited) {
        DllCall("combase\RoInitialize", "Int", 0)
        roInited := 1
    }

    className := "Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager"
    hStr := 0
    hr := DllCall("combase\WindowsCreateString", "WStr", className, "UInt", StrLen(className), "Ptr*", hStr)
    if (hr != 0 || !hStr)
        return false

    VarSetCapacity(iidStatics, 16, 0)
    DllCall("ole32\CLSIDFromString", "WStr", "{2050C4EE-11A0-57DE-AED7-C97C70338245}", "Ptr", &iidStatics)

    pStatics := 0
    hr := DllCall("combase\RoGetActivationFactory", "Ptr", hStr, "Ptr", &iidStatics, "Ptr*", pStatics)
    DllCall("combase\WindowsDeleteString", "Ptr", hStr)
    if (hr != 0 || !pStatics)
        return false

    pAsync := 0
    hr := DllCall(NumGet(NumGet(pStatics+0)+6*A_PtrSize), "Ptr", pStatics, "Ptr*", pAsync)
    ObjRelease(pStatics)
    if (hr != 0 || !pAsync)
        return false

    VarSetCapacity(iidAsyncInfo, 16, 0)
    DllCall("ole32\CLSIDFromString", "WStr", "{00000036-0000-0000-C000-000000000046}", "Ptr", &iidAsyncInfo)
    pAsyncInfo := 0
    hr := DllCall(NumGet(NumGet(pAsync+0)+0*A_PtrSize), "Ptr", pAsync, "Ptr", &iidAsyncInfo, "Ptr*", pAsyncInfo)
    if (hr != 0 || !pAsyncInfo) {
        ObjRelease(pAsync)
        return false
    }

    status := 0
    loopCount := 0
    Loop {
        hr := DllCall(NumGet(NumGet(pAsyncInfo+0)+7*A_PtrSize), "Ptr", pAsyncInfo, "Int*", status)
        if (hr != 0 || status != 0 || loopCount >= 30)
            break
        Sleep, 10
        loopCount++
    }
    ObjRelease(pAsyncInfo)

    if (status != 1) {
        ObjRelease(pAsync)
        return false
    }

    pManager := 0
    hr := DllCall(NumGet(NumGet(pAsync+0)+8*A_PtrSize), "Ptr", pAsync, "Ptr*", pManager)
    ObjRelease(pAsync)
    if (hr != 0 || !pManager)
        return false

    isPlaying := false
    pSessions := 0
    hr := DllCall(NumGet(NumGet(pManager+0)+7*A_PtrSize), "Ptr", pManager, "Ptr*", pSessions)
    if (hr = 0 && pSessions) {
        count := 0
        hr := DllCall(NumGet(NumGet(pSessions+0)+7*A_PtrSize), "Ptr", pSessions, "UInt*", count)
        if (hr = 0 && count > 0) {
            Loop, %count% {
                idx := A_Index - 1
                pSession := 0
                hr := DllCall(NumGet(NumGet(pSessions+0)+6*A_PtrSize), "Ptr", pSessions, "UInt", idx, "Ptr*", pSession)
                if (hr = 0 && pSession) {
                    hAppId := 0
                    appId := ""
                    if (DllCall(NumGet(NumGet(pSession+0)+6*A_PtrSize), "Ptr", pSession, "Ptr*", hAppId) = 0 && hAppId) {
                        pBuf := DllCall("combase\WindowsGetStringRawBuffer", "Ptr", hAppId, "UInt*", len, "Ptr")
                        if (pBuf)
                            appId := StrGet(pBuf, len, "UTF-16")
                        DllCall("combase\WindowsDeleteString", "Ptr", hAppId)
                    }

                    pInfo := 0
                    if (DllCall(NumGet(NumGet(pSession+0)+9*A_PtrSize), "Ptr", pSession, "Ptr*", pInfo) = 0 && pInfo) {
                        playbackStatus := 0
                        if (DllCall(NumGet(NumGet(pInfo+0)+7*A_PtrSize), "Ptr", pInfo, "Int*", playbackStatus) = 0) {
                            ; 4 = GlobalSystemMediaTransportControlsSessionPlaybackStatus_Playing
                            if (playbackStatus = 4) {
                                ; Loại trừ các ứng dụng thuần nghe nhạc
                                if (!RegExMatch(appId, "i)(spotify|applemusic|itunes|foobar2000|aimp|musicbee|winamp|groove|zunemusic|tidal|deezer)"))
                                    isPlaying := true
                            }
                        }
                        ObjRelease(pInfo)
                    }
                    ObjRelease(pSession)
                    if (isPlaying)
                        break
                }
            }
        }
        ObjRelease(pSessions)
    }
    ObjRelease(pManager)
    return isPlaying
}

; ========================================================
; XỬ LÝ PHÍM TẮT TRUNG TÂM KHÓA & KHÔI PHỤC CHU KỲ LẶP LẠI
; ========================================================
HandleLockCenterHotkey() {
    global isLocked, hLockCenterGui, hPendingFocusWnd, pendingFocusTitle

    if (isLocked) {
        SetTimer, TriggerWindowsAuthPrompt, -1
        return
    }

    candHwnd := FindBestFocusTarget(WinExist("A"))
    if (candHwnd) {
        hPendingFocusWnd := candHwnd
        WinGetTitle, pendingFocusTitle, ahk_id %hPendingFocusWnd%
    }

    ShowLockCenterGUI()
}

; Gọi từ Settings hoặc Menu Tray để lấy cửa sổ nền bên dưới làm mục tiêu Focus
OpenLockCenterFromUI(hideOwnerGui := "") {
    global hPendingFocusWnd, pendingFocusTitle, isLocked
    if (isLocked) {
        SetTimer, TriggerWindowsAuthPrompt, -1
        return
    }
    if (hideOwnerGui != "") {
        Gui, %hideOwnerGui%:Hide
        Sleep, 150
    }
    candHwnd := FindBestFocusTarget(WinExist("A"))
    hPendingFocusWnd := candHwnd
    if (hPendingFocusWnd)
        WinGetTitle, pendingFocusTitle, ahk_id %hPendingFocusWnd%
    else
        pendingFocusTitle := ""
    ShowLockCenterGUI()
}

IsValidFocusTargetWnd(hwnd, allowMinimized := false) {
    global hLockCenterGui, hSettingsGui, hAboutGui, hLockOpt, hAutoLock, hLockCountdownGui, hFocusUnlockGui, hExcludedGui, hWhitelistGui, hChangeCodeGui
    if (!hwnd || !DllCall("IsWindow", "Ptr", hwnd))
        return false
    if (hwnd = hLockCenterGui || hwnd = hSettingsGui || hwnd = hAboutGui || hwnd = hLockOpt || hwnd = hAutoLock || hwnd = hLockCountdownGui || hwnd = hFocusUnlockGui || hwnd = hExcludedGui || hwnd = hWhitelistGui || hwnd = hChangeCodeGui || hwnd = A_ScriptHwnd)
        return false
    if (!DllCall("IsWindowVisible", "Ptr", hwnd))
        return false

    cloaked := 0
    DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 14, "UInt*", cloaked, "UInt", 4)
    if (cloaked)
        return false

    if (!allowMinimized) {
        WinGet, mmState, MinMax, ahk_id %hwnd%
        if (mmState = -1)
            return false
    }

    WinGetClass, wClass, ahk_id %hwnd%
    if (wClass = "Shell_TrayWnd" || wClass = "Shell_SecondaryTrayWnd" || wClass = "NotifyIconOverflowWindow" || wClass = "Progman" || wClass = "WorkerW" || wClass = "#32768" || wClass = "Windows.UI.Core.CoreWindow" || wClass = "DV2ControlHost" || wClass = "TopLevelWindowForOverflowXamlIsland")
        return false

    WinGet, exStyle, ExStyle, ahk_id %hwnd%
    if (exStyle & 0x00000080) ; WS_EX_TOOLWINDOW
        return false
    if (exStyle & 0x08000000) ; WS_EX_NOACTIVATE
        return false
    if (!(exStyle & 0x00040000)) { ; Nếu không có WS_EX_APPWINDOW, chỉ bỏ qua cửa sổ con có owner đang hiển thị
        ownerHwnd := DllCall("GetWindow", "Ptr", hwnd, "UInt", 4, "Ptr")
        if (ownerHwnd && DllCall("IsWindowVisible", "Ptr", ownerHwnd))
            return false
    }

    WinGetTitle, wTitle, ahk_id %hwnd%
    if (Trim(wTitle) = "")
        return false
    return true
}

FindBestFocusTarget(preferredHwnd := 0) {
    dhw := A_DetectHiddenWindows
    DetectHiddenWindows, On
    if (IsValidFocusTargetWnd(preferredHwnd, false)) {
        DetectHiddenWindows, %dhw%
        return preferredHwnd
    }
    enumState := {"hwnds": [], "titles": [], "seen": {}, "allowMin": false}
    pState := Object(enumState)
    static cbBest := 0
    if (!cbBest)
        cbBest := RegisterCallback("EnumFocusWindowsProc", "Fast", 2)
    DllCall("EnumWindows", "Ptr", cbBest, "Ptr", pState)
    ObjRelease(pState)
    DetectHiddenWindows, %dhw%
    return (enumState.hwnds.MaxIndex() >= 1) ? enumState.hwnds[1] : 0
}

EnumFocusWindowsProc(hwnd, lParam) {
    state := Object(lParam)
    if (!state.seen.HasKey(hwnd) && IsValidFocusTargetWnd(hwnd, state.allowMin)) {
        WinGetTitle, wTitle, ahk_id %hwnd%
        state.hwnds.Push(hwnd)
        state.titles.Push(wTitle)
        state.seen[hwnd] := true
    }
    return true
}

PopulateFocusCandidates(preferredHwnd := 0) {
    global focusCandidateHwnds, focusCandidateTitles
    focusCandidateHwnds := []
    focusCandidateTitles := []
    selIdx := 1

    dhw := A_DetectHiddenWindows
    DetectHiddenWindows, On

    enumState := {"hwnds": [], "titles": [], "seen": {}, "allowMin": true}
    if (IsValidFocusTargetWnd(preferredHwnd, true)) {
        WinGetTitle, pTitle, ahk_id %preferredHwnd%
        enumState.hwnds.Push(preferredHwnd)
        enumState.titles.Push(pTitle)
        enumState.seen[preferredHwnd] := true
    }

    pState := Object(enumState)
    static cbList := 0
    if (!cbList)
        cbList := RegisterCallback("EnumFocusWindowsProc", "Fast", 2)
    DllCall("EnumWindows", "Ptr", cbList, "Ptr", pState)
    ObjRelease(pState)
    DetectHiddenWindows, %dhw%

    focusCandidateHwnds := enumState.hwnds
    focusCandidateTitles := enumState.titles

    ddlList := ""
    for idx, t in focusCandidateTitles {
        cleanT := StrReplace(t, "|", "-")
        if (StrLen(cleanT) > 55)
            cleanT := SubStr(cleanT, 1, 55) . "..."
        ddlList .= (idx > 1 ? "|" : "") . cleanT
    }
    return {list: ddlList, sel: selIdx}
}

ResumePendingRepeatIfNeeded() {
    regPath := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"
    RegRead, resumeNow, %regPath%, PendingRepeatResumeNow
    if (resumeNow == 1) {
        RegRead, rType, %regPath%, PendingRepeatType
        RegRead, rMins, %regPath%, PendingRepeatMinutes
        RegWrite, REG_DWORD, %regPath%, PendingRepeatResumeNow, 0
        RegWrite, REG_DWORD, %regPath%, PendingRepeatActive, 0
        rType := (rType = 1) ? 1 : 0
        rMins := (rMins > 0) ? rMins + 0 : 5
        StartLockCountdown(rType, rMins, 1)
    }
}

OnWindowsSessionUnlocked() {
    global isLocked, pendingRepeatFullLock, pendingRepeatMinutes
    regPath := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"

    RegRead, waitUnlock, %regPath%, PendingRepeatActive
    if (waitUnlock == 1) {
        RegWrite, REG_DWORD, %regPath%, PendingRepeatResumeNow, 1
        RegWrite, REG_DWORD, %regPath%, PendingRepeatActive, 0
    } else if (isLocked && pendingRepeatFullLock && pendingRepeatMinutes > 0) {
        RegWrite, REG_DWORD, %regPath%, PendingRepeatType, 0
        RegWrite, REG_DWORD, %regPath%, PendingRepeatMinutes, %pendingRepeatMinutes%
        RegWrite, REG_DWORD, %regPath%, PendingRepeatResumeNow, 1
        pendingRepeatFullLock := 0
    }

    if (isLocked)
        UnlockKeyboard(true)
}

; ========================================================
; GIAO DIỆN TRUNG TÂM KHÓA HỢP NHẤT (LOCK CENTER GUI)
; ========================================================
ShowLockCenterGUI() {
    global
    if (!LangTable || !LangTable.HasKey("en")) {
        if (IsFunc("InitLanguage"))
            InitLanguage()
    }
    LoadLockSettings()

    if (hLockCenterGui && WinExist("ahk_id " . hLockCenterGui)) {
        WinActivate, ahk_id %hLockCenterGui%
        return
    }

    ClearLockCenterTooltip()
    Gui, LockCenter:Destroy
    Gui, LockCenter:New, -MaximizeBox -MinimizeBox +HwndhLockCenterGui, % L("LC_Title")
    if (IsFunc("SetGuiYellowIcon"))
        SetGuiYellowIcon(hLockCenterGui)

    isLockCenterBuilding := 1
    LockCenterTooltips := {}
    LastLockCenterTipHwnd := 0

    Gui, Font, s9.5 Norm c222222, Segoe UI

    ; Xác định trạng thái bảo vệ khi đang có hẹn giờ đếm ngược
    centerEditUnlocked := (lockTimerActive && requireCodeForTimerEdit && !windowsLogonOnly) ? 0 : 1

    ; Nếu đang chạy đếm ngược: ưu tiên hiển thị cấu hình đang chạy
    dispType := lockTimerActive ? lockTimerType : centerLockType
    dispTiming := lockTimerActive ? 1 : centerUseTimer
    dispMinutes := lockTimerActive ? lockTimerMinutes : centerTimerMinutes
    dispRepeat := lockTimerActive ? lockTimerRepeat : centerRepeat

    chkType0 := (dispType == 0) ? 1 : 0
    chkType1 := (dispType == 1) ? 1 : 0
    chkType2 := (dispType == 2) ? 1 : 0

    chkTimeNow := (dispTiming == 0) ? 1 : 0
    chkTimeSet := (dispTiming == 1) ? 1 : 0

    yOffset := 12

    ; Banner trạng thái khi đang đếm ngược
    if (lockTimerActive) {
        Gui, Add, Progress, x15 y12 w440 h36 BackgroundE5F1FB cE5F1FB -Theme Disabled, 100
        Gui, Add, Progress, x15 y12 w4 h36 Background0067C0 c0067C0 -Theme Disabled, 100
        Gui, Font, s9.5 Bold c004499, Segoe UI
        Gui, Add, Text, x28 y12 w420 h36 +0x200 +0x80 +BackgroundTrans vCenterActiveBanner, % "⏱️ " . GetActiveTimerStatusText()
        Gui, Font, s9.5 Norm c222222, Segoe UI
        yOffset := 58
    }

    ; Nhóm 1: Kiểu khóa
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x15 y%yOffset% w440 h118, % "  🔐 " . L("LC_GroupMode")
    Gui, Font, s9.5 Norm c222222, Segoe UI

    yR1 := yOffset + 26
    yR1Btn := yOffset + 24
    yR1Icon := yOffset + 27
    yR2 := yOffset + 55
    yR3 := yOffset + 84

    Gui, Add, Radio, x30 y%yR1% w232 h22 vCenterType0 gOnLockCenterTypeChange Group Checked%chkType0%, % "🔒 " . L("LC_ModeFull")
    Gui, Add, Radio, x30 y%yR2% w410 h22 vCenterType1 gOnLockCenterTypeChange Checked%chkType1%, % "🖥️ " . L("LC_ModeScreen")
    Gui, Add, Radio, x30 y%yR3% w410 h22 vCenterType2 gOnLockCenterTypeChange Checked%chkType2%, % "🎯 " . L("LC_ModeFocus")

    ; Icon trạng thái thiết bị khóa (chỉ hiển thị khi chọn Khóa bàn phím & chuột, có tooltip giải thích)
    Gui, Add, Picture, x266 y%yR1Icon% w20 h20 +0x100 vCenterIconKB +HwndhCenterIconKB Icon28, %A_WinDir%\System32\ddores.dll
    Gui, Add, Picture, x292 y%yR1Icon% w20 h20 +0x100 vCenterIconMouse +HwndhCenterIconMouse Icon32, %A_WinDir%\System32\ddores.dll
    Gui, Add, Picture, x266 y%yR1Icon% w20 h20 +0x100 vCenterIconWarn +HwndhCenterIconWarn Icon2, %A_WinDir%\System32\user32.dll
    LockCenterTooltips[hCenterIconKB] := L("LC_TipIconKB")
    LockCenterTooltips[hCenterIconMouse] := L("LC_TipIconMouse")
    LockCenterTooltips[hCenterIconWarn] := L("LC_TipNoDevice")

    Gui, Font, s8.5 Norm, Segoe UI
    Gui, Add, Button, x324 y%yR1Btn% w118 h24 gOnOpenLockSettingsFromCenter vCenterBtnLockSettings, % "⚙️ " . L("LC_BtnSettings")
    Gui, Font, s9.5 Norm c222222, Segoe UI

    focusData := PopulateFocusCandidates(hPendingFocusWnd)

    ; Nhóm 2: Thời gian & Lặp lại (ẩn khi chọn Focus Lock)
    ySec2 := yOffset + 128
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x15 y%ySec2% w440 h148 vCenterTimerGroup, % "  ⏱️ " . L("LC_GroupTiming")
    Gui, Font, s9.5 Norm c222222, Segoe UI

    yT1 := ySec2 + 28
    yT2 := ySec2 + 58
    yPre := ySec2 + 89
    yRep := ySec2 + 119

    Gui, Add, Radio, x30 y%yT1% w410 h22 vCenterTimingNow gOnLockCenterTimingChange Group Checked%chkTimeNow%, % "⚡ " . L("LC_TimingNow")
    Gui, Add, Radio, x30 y%yT2% w165 h24 vCenterTimingTimer gOnLockCenterTimingChange Checked%chkTimeSet%, % "⏱️ " . L("LC_TimingTimer")
    Gui, Add, Edit, x200 y%yT2% w72 h24 Number vCenterMinutesInput gOnLockCenterMinEdit
    Gui, Add, UpDown, vCenterMinutesUpDown Range1-1440, %dispMinutes%
    Gui, Add, Text, x278 y%yT2% w60 h24 +0x200 vCenterMinUnitTxt, % L("LC_UnitMin")

    presetUnit := L("LC_PresetSuffix")
    Gui, Font, s8.5 Norm, Segoe UI
    Gui, Add, Button, x200 y%yPre% w46 h23 gOnLockCenterPreset5 vCenterPreset5, % "5" . presetUnit
    Gui, Add, Button, x252 y%yPre% w46 h23 gOnLockCenterPreset15 vCenterPreset15, % "15" . presetUnit
    Gui, Add, Button, x304 y%yPre% w46 h23 gOnLockCenterPreset30 vCenterPreset30, % "30" . presetUnit
    Gui, Add, Button, x356 y%yPre% w46 h23 gOnLockCenterPreset60 vCenterPreset60, % "60" . presetUnit
    Gui, Font, s9.5 Norm c222222, Segoe UI

    Gui, Add, Checkbox, x30 y%yRep% w410 h22 vCenterRepeatCheck Checked%dispRepeat%, % "🔁 " . L("LC_RepeatCheck")

    ; Nhóm 2b: Thông tin & Chọn cửa sổ Focus Lock (hiển thị thay cho Thời gian khi chọn Focus Lock)
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x15 y%ySec2% w440 h148 vCenterFocusInfoGroup, % "  🎯 " . L("LC_GroupFocusInfo")
    Gui, Font, s9 Norm c222222, Segoe UI
    yFSel := ySec2 + 30
    yFInfo := ySec2 + 66
    Gui, Add, Text, x30 y%yFSel% w115 h24 +0x200 vCenterFocusSelectLbl, % L("LC_FocusSelectLabel")
    ddlOpt := (focusData.list != "") ? ("Choose" . focusData.sel) : "Disabled"
    ddlContent := (focusData.list != "") ? focusData.list : L("LC_FocusNoTarget")
    Gui, Add, DropDownList, x150 y%yFSel% w290 vCenterFocusWndChoice gOnFocusTargetChoiceChange AltSubmit %ddlOpt%, %ddlContent%
    Gui, Font, s8.5 Norm c555555, Segoe UI
    Gui, Add, Text, x30 y%yFInfo% w410 h72 vCenterFocusInfoTxt, % L("LC_FocusDesc")
    Gui, Font, s9.5 Norm c222222, Segoe UI

    yNext := ySec2 + 158

    ; Nhóm 3 (Tùy chọn): Yêu cầu mã mở khóa khi đang chạy hẹn giờ
    if (lockTimerActive && requireCodeForTimerEdit && !windowsLogonOnly) {
        Gui, Font, s9.5 Bold c9C4A00, Segoe UI
        Gui, Add, GroupBox, x15 y%yNext% w440 h86 vCenterAuthGroup, % "  🔑 " . L("LC_AuthPrompt")
        Gui, Font, s9.5 Norm c222222, Segoe UI
        yAuthCtrl := yNext + 36
        Gui, Add, Edit, x30 y%yAuthCtrl% w285 h25 Password vCenterAuthInput
        Gui, Add, Button, x325 y%yAuthCtrl% w115 h26 gOnVerifyCenterAuth vCenterAuthBtn Default, % L("LC_AuthUnlockBtn")
        yBtn := yNext + 98
    } else {
        yBtn := yNext
    }

    ; Nút hành động chân trang
    if (lockTimerActive) {
        defOpt := centerEditUnlocked ? "Default" : ""
        Gui, Add, Button, x130 y%yBtn% w100 h32 gOnLockCenterApply vCenterBtnApply %defOpt%, % "✔ " . L("LC_BtnUpdate")
        Gui, Add, Button, x238 y%yBtn% w115 h32 gOnLockCenterCancelTimer vCenterBtnCancelTimer, % "⏹ " . L("LC_BtnCancelTimer")
        Gui, Add, Button, x361 y%yBtn% w94 h32 gLockCenterGuiClose vCenterBtnClose, % L("LC_BtnClose")
    } else {
        Gui, Add, Button, x235 y%yBtn% w120 h32 gOnLockCenterApply vCenterBtnApply Default, % "🔒 " . L("LC_BtnStart")
        Gui, Add, Button, x363 y%yBtn% w92 h32 gLockCenterGuiClose vCenterBtnClose, % L("LC_BtnCancel")
    }

    totalH := yBtn + 46
    isLockCenterBuilding := 0
    UpdateLockCenterUIState()

    OnMessage(0x200, "WM_MOUSEMOVE_LOCKCENTER")
    Gui, Show, w470 h%totalH% Center, % L("LC_Title")
    if (IsFunc("SetGuiYellowIcon"))
        SetGuiYellowIcon(hLockCenterGui)
    WinActivate, ahk_id %hLockCenterGui%

    if (lockTimerActive && requireCodeForTimerEdit && !windowsLogonOnly && !centerEditUnlocked)
        GuiControl, LockCenter:Focus, CenterAuthInput
}

UpdateLockCenterDeviceStatusIcons(showIcons) {
    global lockKeyboardEnabled, mouseLockEnabled
    if (!showIcons) {
        GuiControl, LockCenter:Hide, CenterIconKB
        GuiControl, LockCenter:Hide, CenterIconMouse
        GuiControl, LockCenter:Hide, CenterIconWarn
        return
    }

    if (lockKeyboardEnabled && mouseLockEnabled) {
        GuiControl, LockCenter:MoveDraw, CenterIconKB, x266
        GuiControl, LockCenter:MoveDraw, CenterIconMouse, x292
        GuiControl, LockCenter:Show, CenterIconKB
        GuiControl, LockCenter:Show, CenterIconMouse
        GuiControl, LockCenter:Hide, CenterIconWarn
    } else if (lockKeyboardEnabled) {
        GuiControl, LockCenter:MoveDraw, CenterIconKB, x266
        GuiControl, LockCenter:Show, CenterIconKB
        GuiControl, LockCenter:Hide, CenterIconMouse
        GuiControl, LockCenter:Hide, CenterIconWarn
    } else if (mouseLockEnabled) {
        GuiControl, LockCenter:MoveDraw, CenterIconMouse, x266
        GuiControl, LockCenter:Hide, CenterIconKB
        GuiControl, LockCenter:Show, CenterIconMouse
        GuiControl, LockCenter:Hide, CenterIconWarn
    } else {
        GuiControl, LockCenter:Hide, CenterIconKB
        GuiControl, LockCenter:Hide, CenterIconMouse
        GuiControl, LockCenter:Show, CenterIconWarn
    }
}

WM_MOUSEMOVE_LOCKCENTER(wParam, lParam, msg, hwnd) {
    global LockCenterTooltips, LastLockCenterTipHwnd, hLockCenterGui
    if (!hLockCenterGui || !WinExist("ahk_id " . hLockCenterGui))
        return

    MouseGetPos, , , idUnderMouse, ctrlUnderMouse, 2
    if (idUnderMouse == hLockCenterGui && ctrlUnderMouse && LockCenterTooltips.HasKey(ctrlUnderMouse)) {
        if (LastLockCenterTipHwnd != ctrlUnderMouse) {
            LastLockCenterTipHwnd := ctrlUnderMouse
            ToolTip, % LockCenterTooltips[ctrlUnderMouse]
            SetTimer, CheckLockCenterTooltipLeave, 120
        }
    } else if (LastLockCenterTipHwnd) {
        ClearLockCenterTooltip()
    }
}

ClearLockCenterTooltip() {
    global LastLockCenterTipHwnd
    if (LastLockCenterTipHwnd) {
        ToolTip
        LastLockCenterTipHwnd := 0
    }
    SetTimer, CheckLockCenterTooltipLeave, Off
}

CheckLockCenterTooltipLeave:
    MouseGetPos, , , idUnderMouse, ctrlUnderMouse, 2
    if (!hLockCenterGui || idUnderMouse != hLockCenterGui || !LockCenterTooltips.HasKey(ctrlUnderMouse))
        ClearLockCenterTooltip()
return

UpdateLockCenterUIState() {
    global lockTimerActive, centerEditUnlocked, focusCandidateHwnds, lockKeyboardEnabled, mouseLockEnabled
    Gui, LockCenter:Submit, NoHide
    GuiControlGet, t0, LockCenter:, CenterType0
    GuiControlGet, t1, LockCenter:, CenterType1
    GuiControlGet, t2, LockCenter:, CenterType2
    GuiControlGet, isTimer, LockCenter:, CenterTimingTimer

    selType := t2 ? 2 : (t1 ? 1 : 0)
    isFull := (selType == 0)
    isFocus := (selType == 2)
    canEdit := centerEditUnlocked ? 1 : 0

    ; Luôn hiển thị icon trạng thái thiết bị khóa; nút Tùy chọn chỉ bật khi chọn Khóa bàn phím & chuột
    UpdateLockCenterDeviceStatusIcons(true)

    ; Ẩn/Hiện nhóm Thời gian vs Thông tin Focus Lock
    visTimer := isFocus ? "Hide" : "Show"
    visFocus := isFocus ? "Show" : "Hide"

    GuiControl, LockCenter:%visTimer%, CenterTimerGroup
    GuiControl, LockCenter:%visTimer%, CenterTimingNow
    GuiControl, LockCenter:%visTimer%, CenterTimingTimer
    GuiControl, LockCenter:%visTimer%, CenterMinutesInput
    GuiControl, LockCenter:%visTimer%, CenterMinutesUpDown
    GuiControl, LockCenter:%visTimer%, CenterMinUnitTxt
    GuiControl, LockCenter:%visTimer%, CenterPreset5
    GuiControl, LockCenter:%visTimer%, CenterPreset15
    GuiControl, LockCenter:%visTimer%, CenterPreset30
    GuiControl, LockCenter:%visTimer%, CenterPreset60
    GuiControl, LockCenter:%visTimer%, CenterRepeatCheck

    GuiControl, LockCenter:%visFocus%, CenterFocusInfoGroup
    GuiControl, LockCenter:%visFocus%, CenterFocusSelectLbl
    GuiControl, LockCenter:%visFocus%, CenterFocusWndChoice
    GuiControl, LockCenter:%visFocus%, CenterFocusInfoTxt

    ; Enable/Disable toàn bộ tùy chọn khi đang bảo vệ bằng mã
    enMode := canEdit ? "Enable" : "Disable"
    GuiControl, LockCenter:%enMode%, CenterType0
    GuiControl, LockCenter:%enMode%, CenterType1
    GuiControl, LockCenter:%enMode%, CenterType2
    enSettings := (canEdit && isFull) ? "Enable" : "Disable"
    GuiControl, LockCenter:%enSettings%, CenterBtnLockSettings
    GuiControl, LockCenter:%enMode%, CenterTimingNow
    GuiControl, LockCenter:%enMode%, CenterTimingTimer
    GuiControl, LockCenter:%enMode%, CenterPreset5
    GuiControl, LockCenter:%enMode%, CenterPreset15
    GuiControl, LockCenter:%enMode%, CenterPreset30
    GuiControl, LockCenter:%enMode%, CenterPreset60

    canStart := (canEdit && !(isFull && !lockKeyboardEnabled && !mouseLockEnabled)) ? "Enable" : "Disable"
    GuiControl, LockCenter:%canStart%, CenterBtnApply

    if (focusCandidateHwnds.MaxIndex() >= 1)
        GuiControl, LockCenter:%enMode%, CenterFocusWndChoice

    if (lockTimerActive)
        GuiControl, LockCenter:%enMode%, CenterBtnCancelTimer

    ; Ô nhập phút luôn cho nhập để tự chuyển sang Hẹn giờ (trừ khi đang khóa mã / Focus Lock)
    enMinEdit := (canEdit && !isFocus) ? "Enable" : "Disable"
    GuiControl, LockCenter:%enMinEdit%, CenterMinutesInput
    GuiControl, LockCenter:%enMinEdit%, CenterMinutesUpDown

    enRep := (canEdit && !isFocus && isTimer) ? "Enable" : "Disable"
    GuiControl, LockCenter:%enRep%, CenterRepeatCheck
}

OnFocusTargetChoiceChange:
    Gui, LockCenter:Submit, NoHide
return

OnOpenLockSettingsFromCenter:
    if (lockTimerActive && !centerEditUnlocked)
        return
    ClearLockCenterTooltip()
    currentSettingsTab := 3
    Gosub, Settings
    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) {
        if (IsFunc("SwitchSettingsTab"))
            SwitchSettingsTab(3)
        WinActivate, ahk_id %hSettingsGui%
    }
return

RefreshLockCenterDeviceIcons() {
    global hLockCenterGui
    if (hLockCenterGui && WinExist("ahk_id " . hLockCenterGui)) {
        UpdateLockCenterUIState()
    }
}

OnLockCenterTypeChange:
    ClearLockCenterTooltip()
    UpdateLockCenterUIState()
return

OnLockCenterTimingChange:
    UpdateLockCenterUIState()
return

OnLockCenterMinEdit:
    if (isLockCenterBuilding)
        return
    GuiControlGet, isTimerNow, LockCenter:, CenterTimingTimer
    if (!isTimerNow) {
        GuiControl, LockCenter:, CenterTimingTimer, 1
        UpdateLockCenterUIState()
    }
return

OnLockCenterPreset5:
    SetLockCenterPreset(5)
return
OnLockCenterPreset15:
    SetLockCenterPreset(15)
return
OnLockCenterPreset30:
    SetLockCenterPreset(30)
return
OnLockCenterPreset60:
    SetLockCenterPreset(60)
return

SetLockCenterPreset(mins) {
    global isLockCenterBuilding
    isLockCenterBuilding := 1
    GuiControl, LockCenter:, CenterTimingTimer, 1
    GuiControl, LockCenter:, CenterMinutesInput, %mins%
    isLockCenterBuilding := 0
    UpdateLockCenterUIState()
}

OnVerifyCenterAuth:
    Gui, LockCenter:Submit, NoHide
    if (CenterAuthInput == UNLOCK_KEYWORD) {
        centerEditUnlocked := 1
        GuiControl, LockCenter:Disable, CenterAuthInput
        GuiControl, LockCenter:Disable, CenterAuthBtn
        GuiControl, LockCenter:, CenterAuthInput,
        GuiControl, LockCenter:-Default, CenterAuthBtn
        GuiControl, LockCenter:+Default, CenterBtnApply
        UpdateLockCenterUIState()
        GuiControl, LockCenter:Focus, CenterBtnApply
    } else {
        MsgBox, 48, % L("LC_Title"), % L("LC_AuthWrong")
        GuiControl, LockCenter:, CenterAuthInput,
        GuiControl, LockCenter:Focus, CenterAuthInput
    }
return

OnLockCenterApply:
    if (lockTimerActive && !centerEditUnlocked)
        return

    Gui, LockCenter:Submit, NoHide
    selType := CenterType2 ? 2 : (CenterType1 ? 1 : 0)
    selTimer := CenterTimingTimer ? 1 : 0
    selMins := CenterMinutesInput + 0
    selRepeat := CenterRepeatCheck ? 1 : 0
    selFocusIdx := CenterFocusWndChoice + 0

    if (selType != 2 && selTimer && selMins <= 0) {
        MsgBox, 48, % L("Hot_ErrTitle"), % L("LC_ErrMinutes")
        GuiControl, LockCenter:Focus, CenterMinutesInput
        return
    }

    targetFocusHwnd := (selFocusIdx >= 1 && selFocusIdx <= focusCandidateHwnds.MaxIndex()) ? focusCandidateHwnds[selFocusIdx] : hPendingFocusWnd
    if (selType == 2 && (!targetFocusHwnd || !WinExist("ahk_id " . targetFocusHwnd))) {
        MsgBox, 48, % L("LC_Title"), % L("LC_FocusNoTarget")
        return
    }

    if (selType == 0 && !lockKeyboardEnabled && !mouseLockEnabled)
        return

    ; Lưu lựa chọn gần nhất
    centerLockType := selType
    centerUseTimer := (selType == 2) ? 0 : selTimer
    if (selMins > 0)
        centerTimerMinutes := selMins
    centerRepeat := (selType == 2 || !selTimer) ? 0 : selRepeat
    SaveLockCenterPreferences()

    ClearLockCenterTooltip()
    Gui, LockCenter:Destroy
    hLockCenterGui := 0

    ; Thực thi kiểu khóa đã chọn
    if (selType == 2) {
        ; Focus Lock: khóa ngay lên cửa sổ mục tiêu đã chọn
        CancelLockCountdown(false)
        TriggerFocusLockDirect(targetFocusHwnd)
        return
    }

    if (!selTimer) {
        ; Khóa ngay lập tức (Full Lock hoặc Windows Screen Lock)
        CancelLockCountdown(false)
        if (selType == 1) {
            ClearLockPowerPolicy()
            DllCall("user32.dll\LockWorkStation")
        } else {
            ActivateLock(0)
        }
        return
    }

    ; Hẹn giờ đếm ngược
    StartLockCountdown(selType, selMins, selRepeat)
return

OnLockCenterCancelTimer:
    if (lockTimerActive && !centerEditUnlocked)
        return
    CancelLockCountdown(true)
    ClearLockCenterTooltip()
    Gui, LockCenter:Destroy
    hLockCenterGui := 0
return

LockCenterGuiClose:
LockCenterGuiEscape:
    ClearLockCenterTooltip()
    Gui, LockCenter:Destroy
    hLockCenterGui := 0
return

; ========================================================
; BỘ ĐẾM NGƯỢC HẸN GIỜ & HIỂN THỊ PHÚT -> GIÂY (< 1 PHÚT)
; ========================================================
FormatCountdownUnit(remainingSec) {
    if (remainingSec < 0)
        remainingSec := 0
    if (remainingSec >= 60) {
        mins := Ceil(remainingSec / 60)
        return mins . " " . L("LC_UnitMin")
    }
    return remainingSec . " " . L("LC_UnitSec")
}

GetActiveTimerStatusText() {
    global lockTimerActive, lockTimerType, lockTimerTargetTick, lockTimerRepeat
    if (!lockTimerActive)
        return ""
    remSec := Ceil((lockTimerTargetTick - A_TickCount) / 1000)
    if (remSec < 0)
        remSec := 0
    timeStr := FormatCountdownUnit(remSec)
    modeName := (lockTimerType == 1) ? L("LC_ModeNameScreen") : L("LC_ModeNameFull")
    msg := StrReplace(StrReplace(L("LC_ActiveTimerBanner"), "{mode}", modeName), "{time}", timeStr)
    if (lockTimerRepeat)
        msg .= L("LC_RepeatSuffix")
    return msg
}

StartLockCountdown(type, minutes, repeat := 0) {
    global lockTimerActive, lockTimerType, lockTimerMinutes, lockTimerRepeat
    global lockTimerTargetTick, lockTimerLastDisplayed, hLockCountdownGui
    global pendingRepeatFullLock, pendingRepeatMinutes

    if (minutes <= 0)
        return

    SetTimer, UpdateLockCountdown, Off
    Gui, LockCountdown:Destroy
    hLockCountdownGui := 0

    pendingRepeatFullLock := 0
    pendingRepeatMinutes := 0
    regPath := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"
    RegWrite, REG_DWORD, %regPath%, PendingRepeatActive, 0

    lockTimerActive := 1
    lockTimerType := (type == 1) ? 1 : 0
    lockTimerMinutes := minutes + 0
    lockTimerRepeat := repeat ? 1 : 0
    lockTimerTargetTick := A_TickCount + (lockTimerMinutes * 60 * 1000)
    lockTimerLastDisplayed := ""

    Gosub, UpdateLockCountdown
    SetTimer, UpdateLockCountdown, 1000

    fnTip := "UpdateTrayTip"
    if (IsFunc(fnTip))
        %fnTip%()
}

MeasureToastTextWidth(hwndCtrl, text) {
    VarSetCapacity(rc, 16, 0)
    hdc := DllCall("GetDC", "Ptr", hwndCtrl, "Ptr")
    hFont := DllCall("SendMessage", "Ptr", hwndCtrl, "UInt", 0x0031, "Ptr", 0, "Ptr", 0, "Ptr")
    hOld := hFont ? DllCall("SelectObject", "Ptr", hdc, "Ptr", hFont, "Ptr") : 0
    ; DT_CALCRECT (0x0400) | DT_SINGLELINE (0x0020) | DT_NOPREFIX (0x0800) = 0x0C20
    DllCall("DrawText", "Ptr", hdc, "Str", text, "Int", -1, "Ptr", &rc, "UInt", 0x0C20)
    w := NumGet(rc, 8, "Int") - NumGet(rc, 0, "Int")
    if (w <= 0) {
        VarSetCapacity(sz, 8, 0)
        DllCall("GetTextExtentPoint32", "Ptr", hdc, "Str", text, "Int", StrLen(text), "Ptr", &sz)
        w := NumGet(sz, 0, "Int")
    }
    if (hOld)
        DllCall("SelectObject", "Ptr", hdc, "Ptr", hOld, "Ptr")
    DllCall("ReleaseDC", "Ptr", hwndCtrl, "Ptr", hdc)
    return w
}

GetToastWorkArea(ByRef waLeft, ByRef waTop, ByRef waRight, ByRef waBottom) {
    global isLocked, lockMode, hFocusWnd

    SysGet, wa, MonitorWorkArea
    if (isLocked && lockMode == 1 && hFocusWnd && WinExist("ahk_id " . hFocusWnd)) {
        WinGetPos, fx, fy, fw, fh, ahk_id %hFocusWnd%
        if (fw > 0 && fh > 0) {
            cx := fx + (fw // 2)
            cy := fy + (fh // 2)
            SysGet, monCount, MonitorCount
            Loop, %monCount% {
                SysGet, m, MonitorWorkArea, %A_Index%
                if (cx >= mLeft && cx < mRight && cy >= mTop && cy < mBottom) {
                    waLeft := mLeft, waTop := mTop, waRight := mRight, waBottom := mBottom
                    break
                }
            }
        }
    }

    if (waRight <= waLeft || waBottom <= waTop) {
        waLeft := 0
        waTop := 0
        waRight := A_ScreenWidth
        waBottom := A_ScreenHeight
    }
}

ComputeToastPos(gw, gh, ByRef posX, ByRef posY, stackAboveBanner := false) {
    global hToastBannerGui

    GetToastWorkArea(waLeft, waTop, waRight, waBottom)
    scale := A_ScreenDPI / 96.0
    margin := Round(16 * scale)
    gap := Round(8 * scale)

    posX := waRight - gw - margin
    posY := waBottom - gh - margin

    if (stackAboveBanner && hToastBannerGui) {
        if (WinExist("ahk_id " . hToastBannerGui) && DllCall("IsWindowVisible", "Ptr", hToastBannerGui)) {
            WinGetPos, bx, by, bw, bh, ahk_id %hToastBannerGui%
            ; Chỉ đẩy lên trên nếu banner đang nằm trên cùng màn hình workarea
            if (bx >= waLeft && bx < waRight && by >= waTop && by < waBottom) {
                candidateY := by - gh - gap
                if (candidateY >= waTop + margin)
                    posY := candidateY
            }
        }
    }
}

RepositionCountdownToast() {
    global hLockCountdownGui
    if (!hLockCountdownGui || !WinExist("ahk_id " . hLockCountdownGui))
        return
    if (!DllCall("IsWindowVisible", "Ptr", hLockCountdownGui))
        return
    WinGetPos,,, gw, gh, ahk_id %hLockCountdownGui%
    if (gw <= 0 || gh <= 0)
        return
    ComputeToastPos(gw, gh, posX, posY, true)
    WinMove, ahk_id %hLockCountdownGui%,, %posX%, %posY%
}

BuildToastGui(guiName, msg, wrapLogicalW, ByRef outGuiHwnd, ByRef outTextHwnd) {
    Gui, %guiName%:Destroy
    Gui, %guiName%:New, +LastFound +AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x08000000 +HwndlocalGui
    Gui, %guiName%:Margin, 16, 10
    Gui, %guiName%:Color, 1F2421, FFFFFF ; Nền tối sang trọng
    Gui, %guiName%:Font, s9.5 Norm cF0F0F0, Segoe UI
    textOpt := "Center +0x80 +HwndlocalText"
    if (wrapLogicalW > 0)
        textOpt .= " w" . wrapLogicalW
    Gui, %guiName%:Add, Text, %textOpt%, %msg%
    Gui, %guiName%:Show, Hide

    outGuiHwnd := localGui
    outTextHwnd := localText
}

FinalizeToastWindow(guiHwnd, gw, gh) {
    WinSet, Transparent, 235, ahk_id %guiHwnd%
    WinSet, Region, 0-0 w%gw% h%gh% R12-12, ahk_id %guiHwnd%
}

ShowCountdownToast(msg) {
    global hLockCountdownGui
    static hCountdownText := 0, sPadX := 0, sCurCW := 0, sCurCH := 0, sGw := 0, sGh := 0

    prevGui := A_DefaultGui

    if (!hLockCountdownGui || !WinExist("ahk_id " . hLockCountdownGui) || !hCountdownText) {
        BuildToastGui("LockCountdown", msg, 0, hLockCountdownGui, hCountdownText)

        dhw := A_DetectHiddenWindows
        DetectHiddenWindows, On
        WinGetPos,,, gw, gh, ahk_id %hLockCountdownGui%
        ControlGetPos,,, cw, ch,, ahk_id %hCountdownText%
        DetectHiddenWindows, %dhw%

        if (!gw || !gh)
            gw := 300, gh := 38
        if (!cw || !ch)
            cw := gw - 32, ch := gh - 20

        sPadX := gw - cw
        sCurCW := cw
        sCurCH := ch
        sGw := gw
        sGh := gh

        FinalizeToastWindow(hLockCountdownGui, sGw, sGh)
        ComputeToastPos(sGw, sGh, posX, posY, true)
        Gui, LockCountdown:Show, x%posX% y%posY% NoActivate

        if (prevGui != "")
            try Gui, %prevGui%:Default
        return
    }

    wantCW := MeasureToastTextWidth(hCountdownText, msg) + 12
    if (wantCW > sCurCW || (sCurCW - wantCW) > 16) {
        sCurCW := wantCW + 8
        sGw := sCurCW + sPadX
        DllCall("SetWindowPos", "Ptr", hCountdownText, "Ptr", 0, "Int", 0, "Int", 0, "Int", sCurCW, "Int", sCurCH, "UInt", 0x16)
        ComputeToastPos(sGw, sGh, posX, posY, true)
        WinMove, ahk_id %hLockCountdownGui%,, %posX%, %posY%, %sGw%, %sGh%
        WinSet, Region, 0-0 w%sGw% h%sGh% R12-12, ahk_id %hLockCountdownGui%
    }
    GuiControl, LockCountdown:, %hCountdownText%, %msg%

    if (prevGui != "")
        try Gui, %prevGui%:Default
}

UpdateLockCountdown:
    if (!lockTimerActive) {
        SetTimer, UpdateLockCountdown, Off
        return
    }

    remMs := lockTimerTargetTick - A_TickCount
    if (remMs <= 0) {
        SetTimer, UpdateLockCountdown, Off
        Gui, LockCountdown:Destroy
        hLockCountdownGui := 0

        ; Đóng hộp thoại Lock Center nếu đang mở để tránh kẹt focus
        if (hLockCenterGui && WinExist("ahk_id " . hLockCenterGui)) {
            Gui, LockCenter:Destroy
            hLockCenterGui := 0
        }

        execType := lockTimerType
        execMins := lockTimerMinutes
        execRepeat := lockTimerRepeat

        lockTimerActive := 0
        lockTimerLastDisplayed := ""

        if (execType == 1) {
            if (execRepeat) {
                regPath := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"
                RegWrite, REG_DWORD, %regPath%, PendingRepeatActive, 1
                RegWrite, REG_DWORD, %regPath%, PendingRepeatType, 1
                RegWrite, REG_DWORD, %regPath%, PendingRepeatMinutes, %execMins%
            }
            fnTip := "UpdateTrayTip"
            if (IsFunc(fnTip))
                %fnTip%()
            ClearLockPowerPolicy()
            DllCall("user32.dll\LockWorkStation")
        } else {
            if (execRepeat) {
                pendingRepeatFullLock := 1
                pendingRepeatMinutes := execMins
                regPath := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"
                RegWrite, REG_DWORD, %regPath%, PendingRepeatActive, 1
                RegWrite, REG_DWORD, %regPath%, PendingRepeatType, 0
                RegWrite, REG_DWORD, %regPath%, PendingRepeatMinutes, %execMins%
            }
            ActivateLock(0)
        }
        return
    }

    remSec := Ceil(remMs / 1000)
    timeStr := FormatCountdownUnit(remSec)
    tpl := (lockTimerType == 1) ? L("LC_CountdownScreen") : L("LC_CountdownFull")
    msg := (lockTimerType == 1 ? "🖥️ " : "🔒 ") . StrReplace(tpl, "{time}", timeStr)
    if (lockTimerRepeat)
        msg .= " 🔁"

    if (msg != lockTimerLastDisplayed) {
        lockTimerLastDisplayed := msg
        ShowCountdownToast(msg)
        if (hLockCenterGui && WinExist("ahk_id " . hLockCenterGui)) {
            Gui, LockCenter:Default
            GuiControl,, CenterActiveBanner, % "⏱️ " . GetActiveTimerStatusText()
        }
    }
return

CancelLockCountdown(showNotice := false) {
    global lockTimerActive, lockTimerLastDisplayed, hLockCountdownGui
    global pendingRepeatFullLock, pendingRepeatMinutes

    SetTimer, UpdateLockCountdown, Off
    Gui, LockCountdown:Destroy
    hLockCountdownGui := 0
    lockTimerActive := 0
    lockTimerLastDisplayed := ""
    pendingRepeatFullLock := 0
    pendingRepeatMinutes := 0

    regPath := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"
    RegWrite, REG_DWORD, %regPath%, PendingRepeatActive, 0
    RegWrite, REG_DWORD, %regPath%, PendingRepeatResumeNow, 0

    fnTip := "UpdateTrayTip"
    if (IsFunc(fnTip))
        %fnTip%()

    if (showNotice)
        ShowToastBanner("✔ " . L("LC_TimerCancelled"), 2000)
}

; ========================================================
; THÔNG BÁO TRỰC QUAN (TOAST)
; ========================================================
ShowToastBanner(msg, autoHideMs := 0) {
    global hToastBannerGui

    prevGui := A_DefaultGui
    SetTimer, HideNotification, Off
    Gui, Notification:Destroy
    hToastBannerGui := 0

    BuildToastGui("Notification", msg, 0, hToastBannerGui, hBannerText)

    dhw := A_DetectHiddenWindows
    DetectHiddenWindows, On
    WinGetPos,,, GuiWidth, GuiHeight, ahk_id %hToastBannerGui%
    DetectHiddenWindows, %dhw%

    GetToastWorkArea(waLeft, waTop, waRight, waBottom)
    scale := A_ScreenDPI / 96.0
    maxPhysW := Max(Round(320 * scale), Round((waRight - waLeft) * 0.48))
    if (GuiWidth > maxPhysW) {
        wrapLogicalW := Max(220, Round((maxPhysW - Round(32 * scale)) / scale))
        BuildToastGui("Notification", msg, wrapLogicalW, hToastBannerGui, hBannerText)
        dhw := A_DetectHiddenWindows
        DetectHiddenWindows, On
        WinGetPos,,, GuiWidth, GuiHeight, ahk_id %hToastBannerGui%
        DetectHiddenWindows, %dhw%
    }

    if (!GuiWidth || !GuiHeight)
        GuiWidth := 320, GuiHeight := 38

    FinalizeToastWindow(hToastBannerGui, GuiWidth, GuiHeight)
    ComputeToastPos(GuiWidth, GuiHeight, posX, posY, false)
    Gui, Notification:Show, x%posX% y%posY% NoActivate

    RepositionCountdownToast()

    if (autoHideMs > 0)
        SetTimer, HideNotification, % -autoHideMs

    if (prevGui != "")
        try Gui, %prevGui%:Default
}

ShowNotification() {
    global isLocked, lockMode, focusWndTitle, windowsLogonOnly, alwaysShowLockToast

    if (isLocked) {
        if (lockMode == 1) {
            shortTitle := (focusWndTitle != "") ? (": " . SubStr(focusWndTitle, 1, 24) . (StrLen(focusWndTitle) > 24 ? "..." : "")) : ""
            hint := windowsLogonOnly ? L("Lock_FocusToastHintWinOnly") : L("Lock_FocusToastHint")
            msg := "🎯 " . L("Lock_NotificationFocus") . shortTitle . " — " . hint
        } else {
            hint := windowsLogonOnly ? L("Lock_ToastHintWinOnly") : L("Lock_ToastHint")
            msg := "🔒 " . L("Lock_NotificationFull") . " — " . hint
        }
        autoHideMs := alwaysShowLockToast ? 0 : 4500
        ShowToastBanner(msg, autoHideMs)
    } else {
        ShowToastBanner("✔ " . L("Lock_Unlocked"), 2500)
    }

    fnTip := "UpdateTrayTip"
    if (IsFunc(fnTip))
        %fnTip%()
}

HideNotification:
    Gui, Notification:Destroy
    hToastBannerGui := 0
    RepositionCountdownToast()
return

; ========================================================
; KÍCH HOẠT & MỞ KHÓA THIẾT BỊ (FULL LOCK / FOCUS LOCK)
; ========================================================
ApplyFocusClipCursor() {
    global isLocked, lockMode, hFocusWnd
    if (!isLocked || lockMode != 1 || !hFocusWnd || !WinExist("ahk_id " . hFocusWnd))
        return
    WinGetPos, fX, fY, fW, fH, ahk_id %hFocusWnd%
    if (fW > 0 && fH > 0) {
        VarSetCapacity(rect, 16, 0)
        NumPut(fX, rect, 0, "Int")
        NumPut(fY, rect, 4, "Int")
        NumPut(fX + fW, rect, 8, "Int")
        NumPut(fY + fH, rect, 12, "Int")
        DllCall("ClipCursor", "Ptr", &rect)
    }
}

ApplyLockPowerPolicy() {
    global isLocked, lockMode, preventScreenOff, preventSleep
    ; Chỉ áp dụng cho Khóa bàn phím & chuột (lockMode = 0) và Focus Lock (lockMode = 1)
    if (!isLocked || (lockMode != 0 && lockMode != 1)) {
        ClearLockPowerPolicy()
        return
    }
    flags := 0x80000000 ; ES_CONTINUOUS
    if (preventSleep)
        flags |= 0x00000001 ; ES_SYSTEM_REQUIRED
    if (preventScreenOff)
        flags |= 0x00000002 ; ES_DISPLAY_REQUIRED
    DllCall("SetThreadExecutionState", "UInt", flags)
}

ClearLockPowerPolicy() {
    DllCall("SetThreadExecutionState", "UInt", 0x80000000) ; ES_CONTINUOUS
}

; Đánh thức màn hình khi người dùng mở khóa trực tiếp bằng mã
WakeDisplayOnUnlock() {
    DllCall("SetThreadExecutionState", "UInt", 0x00000002) ; ES_DISPLAY_REQUIRED (one-shot)
    DllCall("mouse_event", "UInt", 0x0001, "Int", 0, "Int", 0, "UInt", 0, "UPtr", 0) ; MOUSEEVENTF_MOVE (0, 0)
    PostMessage, 0x112, 0xF170, -1,, Program Manager ; WM_SYSCOMMAND, SC_MONITORPOWER, Monitor On
}

ActivateLock(mode := 0, targetHwnd := 0) {
    global isLocked, hKeyboardHook, hMouseHook, lockMode, hFocusWnd, focusWndTitle
    global lockKeyboardEnabled, mouseLockEnabled, Buffer

    LoadLockSettings()

    lockMode := (mode == 1) ? 1 : 0
    isLocked := 1
    Buffer := ""

    if (lockMode == 1) {
        hFocusWnd := (targetHwnd && WinExist("ahk_id " . targetHwnd)) ? targetHwnd : FindBestFocusTarget(WinExist("A"))
        if (hFocusWnd) {
            WinGet, mmState, MinMax, ahk_id %hFocusWnd%
            if (mmState = -1)
                WinRestore, ahk_id %hFocusWnd%
            WinActivate, ahk_id %hFocusWnd%
            Sleep, 80
            WinGetTitle, focusWndTitle, ahk_id %hFocusWnd%
            ApplyFocusClipCursor()
        } else {
            lockMode := 0
        }
    } else {
        hFocusWnd := 0
        focusWndTitle := ""
    }

    if (!hKeyboardHook) {
        hKeyboardHook := DllCall("SetWindowsHookEx", "Int", 13
            , "Ptr", RegisterCallback("KeyboardProc", "Fast")
            , "Ptr", DllCall("GetModuleHandle", "Ptr", 0, "Ptr")
            , "UInt", 0, "Ptr")
        if (!hKeyboardHook) {
            MsgBox, 16, GestureMouse, % L("Lock_HookError")
            isLocked := 0
            return
        }
    }

    if (!hMouseHook && (mouseLockEnabled || lockMode == 1)) {
        hMouseHook := DllCall("SetWindowsHookEx", "Int", 14
            , "Ptr", RegisterCallback("MouseProc", "Fast")
            , "Ptr", DllCall("GetModuleHandle", "Ptr", 0, "Ptr")
            , "UInt", 0, "Ptr")
    }

    ApplyLockPowerPolicy()

    ShowNotification()
}

TriggerFocusLockDirect(targetHwnd := 0) {
    ActivateLock(1, targetHwnd)
}

ToggleLock(forceState := -1) {
    global isLocked, lockMode
    targetState := (forceState != -1) ? forceState : (!isLocked)
    if (!targetState)
        UnlockKeyboard()
    else
        ActivateLock(lockMode)
}

UnlockKeyboard(fromWindowsSession := false) {
    global isLocked, hKeyboardHook, hMouseHook, Buffer, hFocusUnlockGui
    global pendingRepeatFullLock, pendingRepeatMinutes

    if (!isLocked)
        return

    isLocked := 0
    Buffer := ""

    DllCall("ClipCursor", "Ptr", 0)

    if (hFocusUnlockGui && WinExist("ahk_id " . hFocusUnlockGui)) {
        Gui, FocusUnlock:Destroy
        hFocusUnlockGui := 0
    }

    if (hKeyboardHook) {
        DllCall("UnhookWindowsHookEx", "Ptr", hKeyboardHook)
        hKeyboardHook := 0
    }
    if (hMouseHook) {
        DllCall("UnhookWindowsHookEx", "Ptr", hMouseHook)
        hMouseHook := 0
    }

    ClearLockPowerPolicy()

    SendLevel, 1
    SendInput, {Ctrl Up}{Alt Up}
    SendLevel, 0

    if (!fromWindowsSession)
        WakeDisplayOnUnlock()

    ShowNotification()

    ; Nếu là mở khóa trực tiếp (bằng mã) từ chu kỳ lặp lại -> đếm tiếp chu kỳ mới
    if (!fromWindowsSession && pendingRepeatFullLock && pendingRepeatMinutes > 0) {
        mins := pendingRepeatMinutes
        pendingRepeatFullLock := 0
        pendingRepeatMinutes := 0
        StartLockCountdown(0, mins, 1)
    }

    fnTip := "UpdateTrayTip"
    if (IsFunc(fnTip))
        %fnTip%()
}

; ========================================================
; LOW-LEVEL KEYBOARD HOOK
; ========================================================
; Lấy ký tự thật đang gõ theo layout bàn phím, Shift, CapsLock và NumLock
GetRealTypedChar(vkCode, scanCode, isShift) {
    ; Bỏ qua phím bổ trợ / phím trạng thái đơn lẻ
    if (vkCode = 0x10 || vkCode = 0x11 || vkCode = 0x12 || vkCode = 0x14
        || vkCode = 0x5B || vkCode = 0x5C || vkCode = 0x90 || vkCode = 0x91
        || (vkCode >= 0xA0 && vkCode <= 0xA5))
        return ""

    VarSetCapacity(keyState, 256, 0)
    VarSetCapacity(outBuff, 8, 0)
    DllCall("GetKeyboardState", "Ptr", &keyState)

    ; Đồng bộ trạng thái Shift / CapsLock / NumLock thực tế trong ngữ cảnh hook
    NumPut(isShift ? 0x80 : 0, keyState, 0x10, "UChar")
    NumPut(isShift ? 0x80 : 0, keyState, 0xA0, "UChar")
    NumPut(isShift ? 0x80 : 0, keyState, 0xA1, "UChar")
    NumPut(GetKeyState("CapsLock", "T") ? 0x01 : 0, keyState, 0x14, "UChar")
    NumPut(GetKeyState("NumLock", "T") ? 0x01 : 0, keyState, 0x90, "UChar")

    ; Xóa bit Ctrl/Alt sót lại để ToUnicodeEx không biến chữ cái thành ký tự điều khiển
    NumPut(0, keyState, 0x11, "UChar")
    NumPut(0, keyState, 0xA2, "UChar")
    NumPut(0, keyState, 0xA3, "UChar")
    NumPut(0, keyState, 0x12, "UChar")
    NumPut(0, keyState, 0xA4, "UChar")
    NumPut(0, keyState, 0xA5, "UChar")

    fgWnd := WinExist("A")
    tid := fgWnd ? DllCall("GetWindowThreadProcessId", "Ptr", fgWnd, "Ptr", 0, "UInt") : 0
    kbLayout := DllCall("GetKeyboardLayout", "UInt", tid, "Ptr")
    if (!kbLayout)
        kbLayout := DllCall("GetKeyboardLayout", "UInt", 0, "Ptr")

    res := DllCall("ToUnicodeEx", "UInt", vkCode, "UInt", scanCode, "Ptr", &keyState, "Ptr", &outBuff, "Int", 4, "UInt", 0, "Ptr", kbLayout)
    if (res > 0) {
        ch := StrGet(&outBuff, res, "UTF-16")
        if (ch != "" && Asc(SubStr(ch, 1, 1)) >= 32)
            return ch
    }
    return ""
}

KeyboardProc(nCode, wParam, lParam) {
    global isLocked, Buffer, UNLOCK_KEYWORD, KEYWORD_LENGTH, windowsLogonOnly
    global lockMode, hFocusWnd, hFocusUnlockGui, lockKeyboardEnabled, allowSpace, allowMedia, allowNav
    static ctrlState := 0
    static altState := 0
    static lShiftState := 0
    static rShiftState := 0
    Critical

    if (nCode < 0 || !isLocked) {
        ctrlState := 0
        altState := 0
        lShiftState := 0
        rShiftState := 0
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
    }

    vkCode   := NumGet(lParam+0, 0, "UInt")
    scanCode := NumGet(lParam+0, 4, "UInt")
    flags    := NumGet(lParam+0, 8, "UInt")
    isKeyDown := (wParam = 0x100 || wParam = 0x104)
    isAltDown := (flags & 0x20) != 0

    if (vkCode = 0x11 || vkCode = 0xA2 || vkCode = 0xA3)
        ctrlState := isKeyDown
    if (vkCode = 0x12 || vkCode = 0xA4 || vkCode = 0xA5)
        altState := isKeyDown
    if (vkCode = 0xA0)
        lShiftState := isKeyDown
    else if (vkCode = 0xA1)
        rShiftState := isKeyDown
    else if (vkCode = 0x10) {
        lShiftState := isKeyDown
        rShiftState := isKeyDown
    }

    isCtrl  := ctrlState || ((DllCall("GetAsyncKeyState", "Int", 0x11) & 0x8000) != 0) || GetKeyState("Ctrl", "P")
    isAlt   := altState || isAltDown || ((DllCall("GetAsyncKeyState", "Int", 0x12) & 0x8000) != 0) || GetKeyState("Alt", "P")
    isShift := lShiftState || rShiftState || ((DllCall("GetAsyncKeyState", "Int", 0x10) & 0x8000) != 0) || GetKeyState("Shift", "P")

    ; 1. ƯU TIÊN SỐ 1: Bấm Ctrl + Alt + L khi đang khóa
    if (isKeyDown && vkCode = 0x4C && isCtrl && isAlt) {
        static lastHotkeyPress := 0
        if (A_TickCount - lastHotkeyPress > 700) {
            lastHotkeyPress := A_TickCount
            ctrlState := 0
            altState := 0
            lShiftState := 0
            rShiftState := 0
            Buffer := ""
            if (lockMode == 1 && !windowsLogonOnly && !(hFocusUnlockGui && WinExist("ahk_id " . hFocusUnlockGui)))
                SetTimer, TriggerFocusUnlockPrompt, -1
            else
                SetTimer, TriggerWindowsAuthPrompt, -1
        }
        return 1
    }

    ; 2. Xử lý Focus Lock (Hướng A: không nghe lén gõ tự do; chỉ mở qua popup Ctrl+Alt+L hoặc khóa Windows)
    if (lockMode == 1 && hFocusWnd) {
        if (vkCode = 0x5B || vkCode = 0x5C || (isAlt && (vkCode = 0x09 || vkCode = 0x1B)) || (vkCode = 0x1B && isCtrl)) {
            return 1
        }
        curActive := WinExist("A")
        if (hFocusUnlockGui && curActive == hFocusUnlockGui) {
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
        }
        if (curActive == hFocusWnd) {
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
        } else {
            if (hFocusUnlockGui && WinExist("ahk_id " . hFocusUnlockGui))
                WinActivate, ahk_id %hFocusUnlockGui%
            else
                WinActivate, ahk_id %hFocusWnd%
            return 1
        }
    }

    ; 3. Bắt mã mở khóa trực tiếp cho Full Lock (lấy ký tự thật, phân biệt hoa/thường đồng nhất với hộp thoại)
    if (!windowsLogonOnly && isKeyDown && !(isCtrl && !isAlt)) {
        char := GetRealTypedChar(vkCode, scanCode, isShift)
        if (char != "") {
            Buffer .= char
            if (StrLen(Buffer) >= KEYWORD_LENGTH) {
                lastChars := SubStr(Buffer, -KEYWORD_LENGTH + 1)
                if (lastChars == UNLOCK_KEYWORD) {
                    Buffer := ""
                    SetTimer, TriggerDirectUnlock, -1
                    return 1
                }
            }
            if (StrLen(Buffer) > 50)
                Buffer := SubStr(Buffer, -30)
        }
    }

    ; 4. Kiểm tra Whitelist (Full Lock)
    if (isKeyDown) {
        if (allowSpace && vkCode = 0x20)
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
        if (allowMedia && (vkCode >= 0xAD && vkCode <= 0xB3))
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
        if (allowNav && (vkCode >= 0x25 && vkCode <= 0x28 || vkCode = 0x0D || vkCode = 0x1B))
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
    }

    if (!lockKeyboardEnabled)
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)

    return 1
}

TriggerFocusUnlockPrompt:
    ShowFocusUnlockGUI()
return

ShowFocusUnlockGUI() {
    global hFocusUnlockGui, FocusUnlockCodeInput, FocusUnlockErrorTxt
    if (!isLocked || lockMode != 1)
        return
    if (hFocusUnlockGui && WinExist("ahk_id " . hFocusUnlockGui)) {
        WinActivate, ahk_id %hFocusUnlockGui%
        GuiControl, FocusUnlock:Focus, FocusUnlockCodeInput
        return
    }

    ; Tạm giải phóng ClipCursor để chuột thao tác được trên popup mở khóa
    DllCall("ClipCursor", "Ptr", 0)

    Gui, FocusUnlock:Destroy
    Gui, FocusUnlock:New, +AlwaysOnTop -MaximizeBox -MinimizeBox +HwndhFocusUnlockGui, % L("LC_FocusUnlockTitle")
    if (IsFunc("SetGuiYellowIcon"))
        SetGuiYellowIcon(hFocusUnlockGui)

    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Text, x16 y14 w308, % "🔑 " . L("LC_FocusUnlockPrompt")
    Gui, Add, Edit, x16 y38 w308 h24 Password vFocusUnlockCodeInput

    Gui, Font, s8.5 Bold cC62828, Segoe UI
    Gui, Add, Text, x16 y66 w308 h16 vFocusUnlockErrorTxt,

    Gui, Font, s9 Norm, Segoe UI
    Gui, Add, Button, x16 y88 w94 h28 gSubmitFocusUnlock Default, % L("LC_FocusUnlockBtn")
    Gui, Add, Button, x116 y88 w132 h28 gSwitchFocusToWinLock, % L("LC_FocusWinLockBtn")
    Gui, Add, Button, x254 y88 w70 h28 gFocusUnlockGuiClose, % L("LC_BtnCancel")

    Gui, Show, w340 h132 Center, % L("LC_FocusUnlockTitle")
    if (IsFunc("SetGuiYellowIcon"))
        SetGuiYellowIcon(hFocusUnlockGui)
    WinActivate, ahk_id %hFocusUnlockGui%
    GuiControl, FocusUnlock:Focus, FocusUnlockCodeInput
}

SubmitFocusUnlock:
    Gui, FocusUnlock:Submit, NoHide
    if (FocusUnlockCodeInput == UNLOCK_KEYWORD) {
        Gui, FocusUnlock:Destroy
        hFocusUnlockGui := 0
        UnlockKeyboard(false)
    } else {
        GuiControl, FocusUnlock:, FocusUnlockErrorTxt, % "❌ " . L("LC_AuthWrong")
        GuiControl, FocusUnlock:, FocusUnlockCodeInput,
        GuiControl, FocusUnlock:Focus, FocusUnlockCodeInput
    }
return

SwitchFocusToWinLock:
    Gui, FocusUnlock:Destroy
    hFocusUnlockGui := 0
    Gosub, TriggerWindowsAuthPrompt
return

FocusUnlockGuiClose:
FocusUnlockGuiEscape:
    Gui, FocusUnlock:Destroy
    hFocusUnlockGui := 0
    if (isLocked && lockMode == 1 && hFocusWnd && WinExist("ahk_id " . hFocusWnd)) {
        WinActivate, ahk_id %hFocusWnd%
        ApplyFocusClipCursor()
    }
return

TriggerDirectUnlock:
    UnlockKeyboard(false)
return

TriggerWindowsAuthPrompt:
    if (hFocusUnlockGui && WinExist("ahk_id " . hFocusUnlockGui)) {
        Gui, FocusUnlock:Destroy
        hFocusUnlockGui := 0
    }
    if (hKeyboardHook) {
        DllCall("UnhookWindowsHookEx", "Ptr", hKeyboardHook)
        hKeyboardHook := 0
    }
    if (hMouseHook) {
        DllCall("UnhookWindowsHookEx", "Ptr", hMouseHook)
        hMouseHook := 0
    }
    DllCall("ClipCursor", "Ptr", 0)
    ClearLockPowerPolicy()
    DllCall("user32.dll\LockWorkStation")
return

; ========================================================
; LOW-LEVEL MOUSE HOOK
; ========================================================
MouseProc(nCode, wParam, lParam) {
    global isLocked, lockMode, hFocusWnd, hFocusUnlockGui, mouseLockEnabled, lockMouseClick
    global lockMouseWheel, lockMouseMove, allowMouseMove, allowMouseWheel
    Critical

    if (nCode < 0 || !isLocked)
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)

    if (lockMode == 1 && hFocusWnd) {
        ptX := NumGet(lParam+0, 0, "Int")
        ptY := NumGet(lParam+0, 4, "Int")
        ptWnd := DllCall("WindowFromPoint", "Int64", (ptY << 32) | (ptX & 0xFFFFFFFF), "Ptr")
        rootWnd := DllCall("GetAncestor", "Ptr", ptWnd, "UInt", 2, "Ptr")

        if (hFocusUnlockGui && (ptWnd == hFocusUnlockGui || rootWnd == hFocusUnlockGui))
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)

        if (ptWnd != hFocusWnd && rootWnd != hFocusWnd)
            return 1
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
    }

    if (!mouseLockEnabled)
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)

    switch wParam {
        case 0x0200: ; WM_MOUSEMOVE
            if (allowMouseMove)
                return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
            if (lockMouseMove)
                return 1
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)

        case 0x020A, 0x020E: ; WM_MOUSEWHEEL, WM_MOUSEHWHEEL
            if (allowMouseWheel)
                return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
            if (lockMouseWheel || mouseLockEnabled)
                return 1
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)

        default: ; Click chuột
            if (lockMouseClick || mouseLockEnabled)
                return 1
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
    }
}

; ========================================================
; DỌN DẸP KHI THOÁT SCRIPT
; ========================================================
OnExit("LockCleanup")
LockCleanup() {
    global hKeyboardHook, hMouseHook
    DllCall("ClipCursor", "Ptr", 0)
    if (hKeyboardHook)
        DllCall("UnhookWindowsHookEx", "Ptr", hKeyboardHook)
    if (hMouseHook)
        DllCall("UnhookWindowsHookEx", "Ptr", hMouseHook)
    ClearLockPowerPolicy()
}
