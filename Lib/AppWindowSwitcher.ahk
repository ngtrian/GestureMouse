; AppWindowSwitcher.ahk - Chuyển đổi nhanh giữa các cửa sổ cùng ứng dụng (App Window Switcher)
#NoEnv

InitAppWindowSwitcher() {
    global AppWinSwitchEnabled, AppWinSwitchHotkey, AppWinSwitchBackHotkey, AppWinSwitchShowPreview
    global AppWinSwitchRegFwdHk, AppWinSwitchRegBackHk
    global AppWinSwitchActive, AppWinSwitchWindows, AppWinSwitchSelectedIdx, AppWinSwitchHoldMod
    global AppWinSwitchThumbIds, hAppWinSwitchGui, AppWinSwitchTileRects, AppWinSwitchTileCtrls

    AppWinSwitchEnabled := 1
    AppWinSwitchHotkey := "!vkC0"      ; Mặc định: Alt + `
    AppWinSwitchBackHotkey := "!+vkC0" ; Mặc định: Alt + Shift + `
    AppWinSwitchShowPreview := 1
    AppWinSwitchRegFwdHk := ""
    AppWinSwitchRegBackHk := ""

    AppWinSwitchActive := false
    AppWinSwitchWindows := []
    AppWinSwitchSelectedIdx := 1
    AppWinSwitchHoldMod := ""
    AppWinSwitchThumbIds := []
    AppWinSwitchTileRects := []
    AppWinSwitchTileCtrls := []
    hAppWinSwitchGui := 0

    RegRead, valEn, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AppWinSwitchEnabled
    if (!ErrorLevel && valEn != "")
        AppWinSwitchEnabled := valEn ? 1 : 0

    RegRead, valFwd, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AppWinSwitchHotkey
    if (!ErrorLevel && valFwd != "")
        AppWinSwitchHotkey := valFwd

    RegRead, valBack, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AppWinSwitchBackHotkey
    if (!ErrorLevel && valBack != "")
        AppWinSwitchBackHotkey := valBack

    RegRead, valPrev, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AppWinSwitchShowPreview
    if (!ErrorLevel && valPrev != "")
        AppWinSwitchShowPreview := valPrev ? 1 : 0

    ApplyAppWindowSwitcherHotkeys()
    OnExit("CleanupAppWindowSwitcher")
}

ApplyAppWindowSwitcherHotkeys() {
    global AppWinSwitchEnabled, AppWinSwitchHotkey, AppWinSwitchBackHotkey
    global AppWinSwitchRegFwdHk, AppWinSwitchRegBackHk

    if (AppWinSwitchRegFwdHk != "") {
        try Hotkey, %AppWinSwitchRegFwdHk%, AppWinSwitchForwardHandler, Off
        AppWinSwitchRegFwdHk := ""
    }
    if (AppWinSwitchRegBackHk != "") {
        try Hotkey, %AppWinSwitchRegBackHk%, AppWinSwitchBackwardHandler, Off
        AppWinSwitchRegBackHk := ""
    }

    if (!AppWinSwitchEnabled)
        return

    if (AppWinSwitchHotkey != "") {
        try {
            Hotkey, %AppWinSwitchHotkey%, AppWinSwitchForwardHandler, On
            AppWinSwitchRegFwdHk := AppWinSwitchHotkey
        }
    }
    if (AppWinSwitchBackHotkey != "") {
        try {
            Hotkey, %AppWinSwitchBackHotkey%, AppWinSwitchBackwardHandler, On
            AppWinSwitchRegBackHk := AppWinSwitchBackHotkey
        }
    }
}

FormatAppWinSwitchHotkeyText(hk) {
    return FormatHotkeyText(hk)
}

AppWinSwitchForwardHandler:
    TriggerAppWindowSwitcher(1, AppWinSwitchHotkey)
return

AppWinSwitchBackwardHandler:
    TriggerAppWindowSwitcher(-1, AppWinSwitchBackHotkey)
return

#If (AppWinSwitchActive)
*Esc::CancelAppWindowSwitcher()
*Left::MoveAppWinSwitchSelection(-1)
*Right::MoveAppWinSwitchSelection(1)
*Up::MoveAppWinSwitchRow(-1)
*Down::MoveAppWinSwitchRow(1)
*Enter::CommitAppWindowSwitcher()
#If

TriggerAppWindowSwitcher(dir := 1, triggeredHk := "") {
    global AppWinSwitchEnabled, AppWinSwitchActive, AppWinSwitchWindows, AppWinSwitchSelectedIdx, AppWinSwitchHoldMod

    if (!AppWinSwitchEnabled)
        return

    if (AppWinSwitchActive) {
        MoveAppWinSwitchSelection(dir)
        return
    }

    activeHwnd := WinExist("A") + 0
    if (!activeHwnd)
        return

    windows := GetSameAppWindows(activeHwnd)
    if (windows.Length() < 2)
        return

    AppWinSwitchWindows := windows
    activeIdx := 1
    for i, item in windows {
        if (item.hwnd = activeHwnd) {
            activeIdx := i
            break
        }
    }

    nextIdx := activeIdx + dir
    if (nextIdx > windows.Length())
        nextIdx := 1
    else if (nextIdx < 1)
        nextIdx := windows.Length()
    AppWinSwitchSelectedIdx := nextIdx

    AppWinSwitchHoldMod := DetectAppWinSwitchHoldMod(triggeredHk)

    ; Nếu phím tắt không có modifier giữ hoặc người dùng đã nhả modifier ngay lập tức -> chuyển nhanh
    if (AppWinSwitchHoldMod = "" || !IsAppWinSwitchHoldModDown(AppWinSwitchHoldMod)) {
        targetHwnd := AppWinSwitchWindows[AppWinSwitchSelectedIdx].hwnd
        AppWinSwitchWindows := []
        SwitchToAppWindow(targetHwnd)
        return
    }

    AppWinSwitchActive := true
    ShowAppWindowSwitcherOverlay()
    SetTimer, WatchAppWinSwitchModifier, 20
}

DetectAppWinSwitchHoldMod(hk) {
    if (InStr(hk, "!"))
        return "Alt"
    if (InStr(hk, "^"))
        return "Ctrl"
    if (InStr(hk, "#"))
        return "Win"
    if (InStr(hk, "+"))
        return "Shift"
    return ""
}

IsAppWinSwitchHoldModDown(modName) {
    if (modName = "Alt")
        return GetKeyState("Alt", "P")
    if (modName = "Ctrl")
        return GetKeyState("Ctrl", "P")
    if (modName = "Win")
        return GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
    if (modName = "Shift")
        return GetKeyState("Shift", "P")
    return false
}

WatchAppWinSwitchModifier:
    if (!AppWinSwitchActive) {
        SetTimer, WatchAppWinSwitchModifier, Off
        return
    }
    if (AppWinSwitchHoldMod != "" && !IsAppWinSwitchHoldModDown(AppWinSwitchHoldMod)) {
        SetTimer, WatchAppWinSwitchModifier, Off
        CommitAppWindowSwitcher()
    }
return

MoveAppWinSwitchSelection(delta) {
    global AppWinSwitchActive, AppWinSwitchWindows, AppWinSwitchSelectedIdx
    if (!AppWinSwitchActive || !AppWinSwitchWindows.Length())
        return

    cnt := AppWinSwitchWindows.Length()
    AppWinSwitchSelectedIdx += delta
    if (AppWinSwitchSelectedIdx > cnt)
        AppWinSwitchSelectedIdx := 1
    else if (AppWinSwitchSelectedIdx < 1)
        AppWinSwitchSelectedIdx := cnt

    UpdateAppWinSwitchSelectionVisual()
}

MoveAppWinSwitchRow(rowDelta) {
    global AppWinSwitchActive, AppWinSwitchWindows, AppWinSwitchSelectedIdx, AppWinSwitchCols
    if (!AppWinSwitchActive || !AppWinSwitchWindows.Length())
        return

    cols := AppWinSwitchCols ? AppWinSwitchCols : 1
    cnt := AppWinSwitchWindows.Length()
    newIdx := AppWinSwitchSelectedIdx + (rowDelta * cols)
    if (newIdx >= 1 && newIdx <= cnt) {
        AppWinSwitchSelectedIdx := newIdx
        UpdateAppWinSwitchSelectionVisual()
    }
}

CommitAppWindowSwitcher() {
    global AppWinSwitchActive, AppWinSwitchWindows, AppWinSwitchSelectedIdx
    if (!AppWinSwitchActive)
        return

    targetHwnd := 0
    if (AppWinSwitchSelectedIdx >= 1 && AppWinSwitchSelectedIdx <= AppWinSwitchWindows.Length())
        targetHwnd := AppWinSwitchWindows[AppWinSwitchSelectedIdx].hwnd

    CloseAppWindowSwitcherOverlay()
    if (targetHwnd)
        SwitchToAppWindow(targetHwnd)
}

CancelAppWindowSwitcher() {
    global AppWinSwitchActive
    if (!AppWinSwitchActive)
        return
    CloseAppWindowSwitcherOverlay()
}

SwitchToAppWindow(hwnd) {
    if (!hwnd || !DllCall("IsWindow", "Ptr", hwnd))
        return

    ; Triệt tiêu kích hoạt thanh menu khi nhả Alt
    Send, {Blind}{vkE8}

    if (DllCall("IsIconic", "Ptr", hwnd))
        DllCall("ShowWindow", "Ptr", hwnd, "Int", 9) ; SW_RESTORE

    WinActivate, ahk_id %hwnd%
    if (!WinActive("ahk_id " . hwnd)) {
        fgHwnd := DllCall("GetForegroundWindow", "Ptr")
        fgTid := fgHwnd ? DllCall("GetWindowThreadProcessId", "Ptr", fgHwnd, "Ptr", 0, "UInt") : 0
        curTid := DllCall("GetCurrentThreadId", "UInt")
        if (fgTid && fgTid != curTid)
            DllCall("AttachThreadInput", "UInt", curTid, "UInt", fgTid, "Int", 1)
        DllCall("SetForegroundWindow", "Ptr", hwnd)
        DllCall("BringWindowToTop", "Ptr", hwnd)
        if (fgTid && fgTid != curTid)
            DllCall("AttachThreadInput", "UInt", curTid, "UInt", fgTid, "Int", 0)
    }
}

; ==============================================================================
; Lọc cửa sổ hợp lệ thuộc cùng một ứng dụng theo Z-order
; ==============================================================================
GetSameAppWindows(activeHwnd) {
    result := []
    activeKey := GetAppWindowSwitcherAppKey(activeHwnd)
    if (activeKey = "")
        return result

    WinGet, idList, List
    Loop, %idList% {
        hwnd := idList%A_Index% + 0
        if (!IsEligibleSwitcherWindow(hwnd))
            continue
        if (GetAppWindowSwitcherAppKey(hwnd) != activeKey)
            continue

        WinGetTitle, wTitle, ahk_id %hwnd%
        if (Trim(wTitle) = "")
            continue

        result.Push({ hwnd: hwnd
            , title: wTitle
            , isMinimized: (DllCall("IsIconic", "Ptr", hwnd) != 0) })
    }
    return result
}

IsEligibleSwitcherWindow(hwnd) {
    global hAppWinSwitchGui
    if (!hwnd || hwnd = hAppWinSwitchGui)
        return false
    if (!DllCall("IsWindowVisible", "Ptr", hwnd))
        return false

    WinGetClass, wClass, ahk_id %hwnd%
    if wClass in Progman,WorkerW,Shell_TrayWnd,Shell_SecondaryTrayWnd,Windows.UI.Core.CoreWindow,MultitaskingViewFrame,ForegroundStaging,NotifyIconOverflowWindow
        return false

    exStyle := GetWindowLongPtrCompat(hwnd, -20) ; GWL_EXSTYLE
    if ((exStyle & 0x80) && !(exStyle & 0x40000)) ; WS_EX_TOOLWINDOW without WS_EX_APPWINDOW
        return false

    owner := DllCall("GetWindow", "Ptr", hwnd, "UInt", 4, "Ptr") ; GW_OWNER
    if (owner && !(exStyle & 0x40000))
        return false

    ; Loại bỏ cửa sổ bị DWM cloaked (ẩn trên Virtual Desktop khác hoặc UWP suspended)
    cloaked := 0
    hr := DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 14, "UInt*", cloaked, "UInt", 4)
    if (hr = 0 && cloaked != 0)
        return false

    VarSetCapacity(rc, 16, 0)
    if (!DllCall("GetWindowRect", "Ptr", hwnd, "Ptr", &rc))
        return false
    w := NumGet(rc, 8, "Int") - NumGet(rc, 0, "Int")
    h := NumGet(rc, 12, "Int") - NumGet(rc, 4, "Int")
    if (w <= 1 || h <= 1)
        return false

    return true
}

GetAppWindowSwitcherAppKey(hwnd) {
    WinGet, procName, ProcessName, ahk_id %hwnd%
    WinGet, procPath, ProcessPath, ahk_id %hwnd%
    StringLower, procNameLower, procName

    ; Xử lý riêng cho UWP apps (ApplicationFrameHost.exe) để phân biệt từng app UWP
    if (procNameLower = "applicationframehost.exe") {
        realPath := FindUwpRealProcessPath(hwnd)
        if (realPath != "") {
            StringLower, realPathLower, realPath
            return "uwp:" . realPathLower
        }
    }

    key := (procPath != "") ? procPath : procName
    StringLower, key, key
    return key
}

FindUwpRealProcessPath(parentHwnd) {
    WinGet, parentPid, PID, ahk_id %parentHwnd%
    childHwnd := 0
    Loop {
        childHwnd := DllCall("FindWindowEx", "Ptr", parentHwnd, "Ptr", childHwnd, "Str", "Windows.UI.Core.CoreWindow", "Ptr", 0, "Ptr")
        if (!childHwnd)
            break
        WinGet, childPid, PID, ahk_id %childHwnd%
        if (childPid && childPid != parentPid) {
            WinGet, childPath, ProcessPath, ahk_id %childHwnd%
            if (childPath != "")
                return childPath
        }
    }
    return ""
}

GetAppWindowSwitcherDisplayName(hwnd) {
    WinGet, procName, ProcessName, ahk_id %hwnd%
    WinGet, procPath, ProcessPath, ahk_id %hwnd%
    StringLower, procNameLower, procName
    if (procNameLower = "applicationframehost.exe") {
        realPath := FindUwpRealProcessPath(hwnd)
        if (realPath != "")
            procPath := realPath
    }
    if (procPath != "") {
        SplitPath, procPath, , , , nameNoExt
        if (nameNoExt != "")
            return nameNoExt
    }
    if (procName != "")
        return RegExReplace(procName, "i)\.exe$", "")
    return "Application"
}

; ==============================================================================
; Giao diện Overlay Fluent + DWM Live Thumbnails
; ==============================================================================
ShowAppWindowSwitcherOverlay() {
    global AppWinSwitchWindows, AppWinSwitchSelectedIdx, AppWinSwitchShowPreview
    global hAppWinSwitchGui, AppWinSwitchThumbIds, AppWinSwitchTileRects, AppWinSwitchTileCtrls
    global AppWinSwitchCols, AppWinSwitchOverlayW, AppWinSwitchOverlayH, AppWinSwitchHeaderH

    CloseAppWindowSwitcherOverlay(false)

    cnt := AppWinSwitchWindows.Length()
    if (cnt < 2)
        return

    maxShow := (cnt > 12) ? 12 : cnt
    scale := A_ScreenDPI / 96.0

    padX := 18
    padY := 16
    headerH := 38
    gapX := 12
    gapY := 12
    AppWinSwitchHeaderH := headerH

    if (AppWinSwitchShowPreview) {
        cols := (maxShow <= 4) ? maxShow : 4
        rows := Ceil(maxShow / cols)
        tileW := 220
        tileH := 162
    } else {
        cols := 1
        rows := maxShow
        tileW := 380
        tileH := 40
        gapY := 6
    }

    AppWinSwitchCols := cols
    overlayW := padX * 2 + cols * tileW + (cols - 1) * gapX
    overlayH := padY + headerH + rows * tileH + (rows - 1) * gapY + padY
    AppWinSwitchOverlayW := overlayW
    AppWinSwitchOverlayH := overlayH

    ; Tính vị trí căn giữa màn hình chứa cửa sổ đang active
    mon := GetMonitorWorkAreaForHwnd(AppWinSwitchWindows[1].hwnd)
    monW := Round((mon.right - mon.left) / scale)
    monH := Round((mon.bottom - mon.top) / scale)
    posX := Round(mon.left / scale) + Round((monW - overlayW) / 2)
    posY := Round(mon.top / scale) + Round((monH - overlayH) / 2)

    Gui, AppWinSwitchGui:New, -Caption +ToolWindow +AlwaysOnTop +E0x08000000 +HwndhAppWinSwitchGui
    Gui, AppWinSwitchGui:Color, 202020
    Gui, AppWinSwitchGui:Margin, 0, 0

    ; Bo góc & Dark Mode trên Windows 11
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hAppWinSwitchGui, "UInt", 20, "Int*", 1, "UInt", 4) ; DWMWA_USE_IMMERSIVE_DARK_MODE
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hAppWinSwitchGui, "UInt", 33, "Int*", 2, "UInt", 4) ; DWMWCP_ROUND

    ; Header: Tên ứng dụng & số lượng cửa sổ
    appName := GetAppWindowSwitcherDisplayName(AppWinSwitchWindows[1].hwnd)
    countLabel := IsFunc("L") ? StrReplace(L("AWS_WindowCount"), "{1}", cnt) : (cnt . " cửa sổ")
    escHint := IsFunc("L") ? L("AWS_EscHint") : "Esc: Hủy"

    Gui, AppWinSwitchGui:Font, s10.5 Bold cFFFFFF, Segoe UI
    Gui, AppWinSwitchGui:Add, Text, % "x" . padX . " y14 w" . (overlayW - padX * 2 - 110) . " h22 +0x200 BackgroundTrans", % appName . "  (" . countLabel . ")"
    Gui, AppWinSwitchGui:Font, s8.5 Norm c9A9A9A, Segoe UI
    Gui, AppWinSwitchGui:Add, Text, % "x" . (overlayW - padX - 105) . " y16 w105 h20 Right +0x200 BackgroundTrans", % escHint

    AppWinSwitchTileRects := []
    AppWinSwitchTileCtrls := []
    AppWinSwitchThumbIds := []

    Loop, %maxShow% {
        idx := A_Index
        item := AppWinSwitchWindows[idx]
        colIdx := Mod(idx - 1, cols)
        rowIdx := Floor((idx - 1) / cols)

        tx := padX + colIdx * (tileW + gapX)
        ty := padY + headerH + rowIdx * (tileH + gapY)

        AppWinSwitchTileRects.Push({ x: tx, y: ty, w: tileW, h: tileH })

        Gui, AppWinSwitchGui:Add, Text, x%tx% y%ty% w%tileW% h%tileH% +HwndhBorderCtrl Background2D2D2D
        inX := tx + 2, inY := ty + 2, inW := tileW - 4, inH := tileH - 4
        Gui, AppWinSwitchGui:Add, Text, x%inX% y%inY% w%inW% h%inH% +HwndhBgCtrl Background2B2B2B

        shortTitle := item.title
        if (StrLen(shortTitle) > (AppWinSwitchShowPreview ? 26 : 44))
            shortTitle := SubStr(shortTitle, 1, AppWinSwitchShowPreview ? 25 : 43) . "…"

        if (AppWinSwitchShowPreview) {
            Gui, AppWinSwitchGui:Font, s8.5 Norm cEAEAEA, Segoe UI
            Gui, AppWinSwitchGui:Add, Text, % "x" . (tx + 10) . " y" . (ty + 7) . " w" . (tileW - 20) . " h18 +0x200 +0x80 BackgroundTrans +HwndhTitleCtrl", % shortTitle
        } else {
            Gui, AppWinSwitchGui:Font, s9.5 Norm cEAEAEA, Segoe UI
            Gui, AppWinSwitchGui:Add, Text, % "x" . (tx + 12) . " y" . (ty + 9) . " w" . (tileW - 44) . " h22 +0x200 +0x80 BackgroundTrans +HwndhTitleCtrl", % shortTitle
            Gui, AppWinSwitchGui:Font, s8.5 Bold c888888, Segoe UI
            Gui, AppWinSwitchGui:Add, Text, % "x" . (tx + tileW - 30) . " y" . (ty + 10) . " w20 h20 Right +0x200 BackgroundTrans", % idx
        }

        AppWinSwitchTileCtrls.Push({ border: hBorderCtrl, bg: hBgCtrl, title: hTitleCtrl })
    }

    Gui, AppWinSwitchGui:Show, NoActivate x%posX% y%posY% w%overlayW% h%overlayH%, AppWindowSwitcherOverlay

    ; Đăng ký DWM Live Thumbnails sau khi cửa sổ overlay đã có HWND hiển thị
    if (AppWinSwitchShowPreview) {
        Loop, %maxShow% {
            idx := A_Index
            rc := AppWinSwitchTileRects[idx]
            thumbX := Round((rc.x + 8) * scale)
            thumbY := Round((rc.y + 30) * scale)
            thumbW := Round((rc.w - 16) * scale)
            thumbH := Round((rc.h - 38) * scale)
            tid := RegisterFittedDwmThumbnail(hAppWinSwitchGui, AppWinSwitchWindows[idx].hwnd, thumbX, thumbY, thumbW, thumbH)
            if (tid)
                AppWinSwitchThumbIds.Push(tid)
        }
    }

    UpdateAppWinSwitchSelectionVisual()
    OnMessage(0x0201, "OnAppWinSwitchClick") ; WM_LBUTTONDOWN
}

RegisterFittedDwmThumbnail(destHwnd, srcHwnd, boxX, boxY, boxW, boxH) {
    hThumb := 0
    hr := DllCall("dwmapi\DwmRegisterThumbnail", "Ptr", destHwnd, "Ptr", srcHwnd, "Ptr*", hThumb)
    if (hr != 0 || !hThumb)
        return 0

    VarSetCapacity(srcSize, 8, 0)
    srcW := boxW, srcH := boxH
    if (DllCall("dwmapi\DwmQueryThumbnailSourceSize", "Ptr", hThumb, "Ptr", &srcSize) = 0) {
        sw := NumGet(srcSize, 0, "Int")
        sh := NumGet(srcSize, 4, "Int")
        if (sw > 0 && sh > 0) {
            srcW := sw
            srcH := sh
        }
    }

    ratio := Min(boxW / srcW, boxH / srcH)
    drawW := Round(srcW * ratio)
    drawH := Round(srcH * ratio)
    drawX := boxX + Round((boxW - drawW) / 2)
    drawY := boxY + Round((boxH - drawH) / 2)

    ; DWM_THUMBNAIL_PROPERTIES (45 bytes -> 48 bytes aligned)
    VarSetCapacity(props, 48, 0)
    NumPut(0x0000001D, props, 0, "UInt") ; DWM_TNP_RECTDESTINATION | DWM_TNP_OPACITY | DWM_TNP_VISIBLE | DWM_TNP_SOURCECLIENTAREAONLY
    NumPut(drawX, props, 4, "Int")
    NumPut(drawY, props, 8, "Int")
    NumPut(drawX + drawW, props, 12, "Int")
    NumPut(drawY + drawH, props, 16, "Int")
    NumPut(255, props, 36, "UChar") ; opacity
    NumPut(1, props, 37, "Int")     ; fVisible
    NumPut(0, props, 41, "Int")     ; fSourceClientAreaOnly

    DllCall("dwmapi\DwmUpdateThumbnailProperties", "Ptr", hThumb, "Ptr", &props)
    return hThumb
}

UpdateAppWinSwitchSelectionVisual() {
    global AppWinSwitchTileCtrls, AppWinSwitchSelectedIdx
    if (!IsObject(AppWinSwitchTileCtrls))
        return

    accentRgb := IsFunc("GetWindowsAccentRgb") ? GetWindowsAccentRgb() : 0x0078D7
    accentHex := Format("{:06X}", accentRgb)

    for idx, ctrls in AppWinSwitchTileCtrls {
        isSel := (idx = AppWinSwitchSelectedIdx)
        borderColor := isSel ? accentHex : "383838"
        bgColor := isSel ? "353535" : "262626"
        GuiControl, +Background%borderColor%, % ctrls.border
        GuiControl, +Background%bgColor%, % ctrls.bg
        DllCall("RedrawWindow", "Ptr", ctrls.border, "Ptr", 0, "Ptr", 0, "UInt", 0x0105)
        DllCall("RedrawWindow", "Ptr", ctrls.bg, "Ptr", 0, "Ptr", 0, "UInt", 0x0105)
        DllCall("RedrawWindow", "Ptr", ctrls.title, "Ptr", 0, "Ptr", 0, "UInt", 0x0105)
    }
}

OnAppWinSwitchClick(wParam, lParam, msg, hwnd) {
    global hAppWinSwitchGui, AppWinSwitchActive, AppWinSwitchTileRects, AppWinSwitchSelectedIdx
    if (!AppWinSwitchActive || !hAppWinSwitchGui)
        return
    if (hwnd != hAppWinSwitchGui && !DllCall("IsChild", "Ptr", hAppWinSwitchGui, "Ptr", hwnd))
        return

    VarSetCapacity(pt, 8, 0)
    DllCall("GetCursorPos", "Ptr", &pt)
    DllCall("ScreenToClient", "Ptr", hAppWinSwitchGui, "Ptr", &pt)
    scale := A_ScreenDPI / 96.0
    cx := NumGet(pt, 0, "Int") / scale
    cy := NumGet(pt, 4, "Int") / scale

    for idx, rc in AppWinSwitchTileRects {
        if (cx >= rc.x && cx <= (rc.x + rc.w) && cy >= rc.y && cy <= (rc.y + rc.h)) {
            AppWinSwitchSelectedIdx := idx
            SetTimer, AppWinSwitchCommitDeferred, -1
            return 0
        }
    }
}

AppWinSwitchCommitDeferred:
    CommitAppWindowSwitcher()
return

CloseAppWindowSwitcherOverlay(clearState := true) {
    global AppWinSwitchActive, AppWinSwitchThumbIds, hAppWinSwitchGui, AppWinSwitchTileRects, AppWinSwitchTileCtrls, AppWinSwitchWindows

    SetTimer, WatchAppWinSwitchModifier, Off
    OnMessage(0x0201, "OnAppWinSwitchClick", 0)

    if (IsObject(AppWinSwitchThumbIds)) {
        for _, tid in AppWinSwitchThumbIds {
            if (tid)
                DllCall("dwmapi\DwmUnregisterThumbnail", "Ptr", tid)
        }
    }
    AppWinSwitchThumbIds := []

    if (hAppWinSwitchGui) {
        try Gui, AppWinSwitchGui:Destroy
        hAppWinSwitchGui := 0
    }

    AppWinSwitchTileRects := []
    AppWinSwitchTileCtrls := []
    if (clearState) {
        AppWinSwitchActive := false
        AppWinSwitchWindows := []
    }
}

GetMonitorWorkAreaForHwnd(hwnd) {
    hMon := DllCall("MonitorFromWindow", "Ptr", hwnd, "UInt", 2, "Ptr") ; MONITOR_DEFAULTTONEAREST
    VarSetCapacity(mi, 40, 0)
    NumPut(40, mi, 0, "UInt")
    if (hMon && DllCall("GetMonitorInfo", "Ptr", hMon, "Ptr", &mi)) {
        return { left: NumGet(mi, 20, "Int")
            , top: NumGet(mi, 24, "Int")
            , right: NumGet(mi, 28, "Int")
            , bottom: NumGet(mi, 32, "Int") }
    }
    return { left: 0, top: 0, right: A_ScreenWidth, bottom: A_ScreenHeight }
}

CleanupAppWindowSwitcher() {
    global AppWinSwitchRegFwdHk, AppWinSwitchRegBackHk
    CloseAppWindowSwitcherOverlay()
    if (AppWinSwitchRegFwdHk != "")
        try Hotkey, %AppWinSwitchRegFwdHk%, AppWinSwitchForwardHandler, Off
    if (AppWinSwitchRegBackHk != "")
        try Hotkey, %AppWinSwitchRegBackHk%, AppWinSwitchBackwardHandler, Off
}
