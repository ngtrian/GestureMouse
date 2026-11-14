; AppWindowSwitcher.ahk - Chuyển đổi nhanh giữa các cửa sổ cùng ứng dụng (App Window Switcher)
#NoEnv

InitAppWindowSwitcher() {
    global AppWinSwitchEnabled, AppWinSwitchHotkey, AppWinSwitchBackHotkey, AppWinSwitchShowPreview
    global AppWinSwitchRegFwdHk, AppWinSwitchRegBackHk
    global AppWinSwitchActive, AppWinSwitchWindows, AppWinSwitchSelectedIdx, AppWinSwitchHoldMod
    global AppWinSwitchThumbIds, hAppWinSwitchGui, AppWinSwitchTileRects
    global AppWinSwitchGdipMod, AppWinSwitchGdipToken, AppWinSwitchHoverIdx, AppWinSwitchHoverClose

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
    hAppWinSwitchGui := 0
    AppWinSwitchGdipMod := 0
    AppWinSwitchGdipToken := 0
    AppWinSwitchHoverIdx := 0
    AppWinSwitchHoverClose := false

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
*Tab::MoveAppWinSwitchSelection(1)
*+Tab::MoveAppWinSwitchSelection(-1)
*Left::MoveAppWinSwitchSelection(-1)
*Right::MoveAppWinSwitchSelection(1)
*Up::MoveAppWinSwitchRow(-1)
*Down::MoveAppWinSwitchRow(1)
*Enter::CommitAppWindowSwitcher()
~*LButton::CheckAppWinSwitchOutsideClick()
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
    global AppWinSwitchActive, AppWinSwitchTileRects, AppWinSwitchSelectedIdx
    if (!AppWinSwitchActive || !AppWinSwitchTileRects.Length())
        return

    prevIdx := AppWinSwitchSelectedIdx
    cnt := AppWinSwitchTileRects.Length()
    AppWinSwitchSelectedIdx += delta
    if (AppWinSwitchSelectedIdx > cnt)
        AppWinSwitchSelectedIdx := 1
    else if (AppWinSwitchSelectedIdx < 1)
        AppWinSwitchSelectedIdx := cnt

    UpdateAppWinSwitchSelectionVisual(prevIdx)
}

MoveAppWinSwitchRow(rowDelta) {
    global AppWinSwitchActive, AppWinSwitchTileRects, AppWinSwitchSelectedIdx
    if (!AppWinSwitchActive || !AppWinSwitchTileRects.Length())
        return

    cur := AppWinSwitchTileRects[AppWinSwitchSelectedIdx]
    if (!IsObject(cur) || !cur.HasKey("row"))
        return

    targetRow := cur.row + rowDelta
    curCenterX := cur.x + (cur.w / 2.0)
    bestIdx := 0
    bestDist := 999999

    for idx, rc in AppWinSwitchTileRects {
        if (rc.row = targetRow) {
            dist := Abs((rc.x + (rc.w / 2.0)) - curCenterX)
            if (dist < bestDist) {
                bestDist := dist
                bestIdx := idx
            }
        }
    }

    if (bestIdx) {
        prevIdx := AppWinSwitchSelectedIdx
        AppWinSwitchSelectedIdx := bestIdx
        UpdateAppWinSwitchSelectionVisual(prevIdx)
    }
}

CheckAppWinSwitchOutsideClick() {
    global AppWinSwitchActive, hAppWinSwitchGui
    if (!AppWinSwitchActive || !hAppWinSwitchGui)
        return
    MouseGetPos, , , winUnderMouse
    if (winUnderMouse != hAppWinSwitchGui && !DllCall("IsChild", "Ptr", hAppWinSwitchGui, "Ptr", winUnderMouse))
        CancelAppWindowSwitcher()
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
    pidCache := {}
    activeKey := GetAppWindowSwitcherAppKey(activeHwnd, pidCache)
    if (activeKey = "")
        return result

    WinGet, idList, List
    Loop, %idList% {
        hwnd := idList%A_Index% + 0
        if (!IsEligibleSwitcherWindow(hwnd))
            continue
        if (GetAppWindowSwitcherAppKey(hwnd, pidCache) != activeKey)
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

GetAppWindowSwitcherAppKey(hwnd, pidCache := "") {
    WinGet, pid, PID, ahk_id %hwnd%
    if (IsObject(pidCache) && pid && pidCache.HasKey(pid))
        return pidCache[pid]

    WinGet, procName, ProcessName, ahk_id %hwnd%
    StringLower, procNameLower, procName

    ; Xử lý riêng cho UWP apps (ApplicationFrameHost.exe): không cache theo PID vì nhiều UWP app dùng chung host PID
    if (procNameLower = "applicationframehost.exe") {
        realPath := FindUwpRealProcessPath(hwnd)
        if (realPath != "") {
            StringLower, realPathLower, realPath
            return "uwp:" . realPathLower
        }
    }

    WinGet, procPath, ProcessPath, ahk_id %hwnd%
    key := (procPath != "") ? procPath : procName
    StringLower, key, key
    if (IsObject(pidCache) && pid && key != "")
        pidCache[pid] := key
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
; Giao diện Overlay phong cách Alt+Tab Windows 11 (GDI+ bo góc + Theme Windows)
; ==============================================================================
IsWindowsLightTheme() {
    RegRead, sysLight, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize, SystemUsesLightTheme
    if (!ErrorLevel && sysLight != "")
        return (sysLight = 1)
    RegRead, appLight, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize, AppsUseLightTheme
    if (!ErrorLevel && appLight != "")
        return (appLight = 1)
    return false
}

ShowAppWindowSwitcherOverlay() {
    global AppWinSwitchWindows, AppWinSwitchSelectedIdx, AppWinSwitchShowPreview
    global hAppWinSwitchGui, hAppWinSwitchViewGui, AppWinSwitchThumbIds, AppWinSwitchTileRects, AppWinSwitchTileSizes
    global AppWinSwitchCols, AppWinSwitchOwnedIcons, AppWinSwitchTileIcons, AppWinSwitchMonRect
    global AppWinSwitchOverlayW, AppWinSwitchOverlayH, AppWinSwitchContentH, AppWinSwitchScrollY, AppWinSwitchScrollMax
    global AppWinSwitchCanvasDC, AppWinSwitchCanvasBmp, AppWinSwitchCanvasOldBmp, AppWinSwitchIsLight, AppWinSwitchHoverIdx, AppWinSwitchHoverClose

    CloseAppWindowSwitcherOverlay(false)

    cnt := AppWinSwitchWindows.Length()
    if (cnt < 2)
        return

    maxShow := cnt
    scale := A_ScreenDPI / 96.0
    AppWinSwitchIsLight := IsWindowsLightTheme()

    AppWinSwitchTileRects := []
    AppWinSwitchTileSizes := []
    AppWinSwitchThumbIds := []
    AppWinSwitchOwnedIcons := []
    AppWinSwitchTileIcons := []
    AppWinSwitchCanvasDC := 0
    AppWinSwitchCanvasBmp := 0
    AppWinSwitchCanvasOldBmp := 0
    AppWinSwitchScrollY := 0
    AppWinSwitchScrollMax := 0
    AppWinSwitchHoverIdx := 0
    AppWinSwitchHoverClose := false

    ; Tạo GUI khung ngoài trước (ẩn) và GUI con bên trong để hỗ trợ cuộn mượt không giới hạn số cửa sổ
    guiBgHex := AppWinSwitchIsLight ? "F3F3F3" : "202020"
    borderDwmColor := AppWinSwitchIsLight ? 0xD2D2D2 : 0x424242

    Gui, AppWinSwitchGui:New, -Caption +ToolWindow +AlwaysOnTop +E0x08080000 +0x02000000 +HwndhAppWinSwitchGui ; WS_EX_NOACTIVATE | WS_EX_LAYERED | WS_CLIPCHILDREN
    Gui, AppWinSwitchGui:Color, %guiBgHex%
    Gui, AppWinSwitchGui:Margin, 0, 0

    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hAppWinSwitchGui, "UInt", 20, "Int*", AppWinSwitchIsLight ? 0 : 1, "UInt", 4)
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hAppWinSwitchGui, "UInt", 33, "Int*", 2, "UInt", 4)
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hAppWinSwitchGui, "UInt", 34, "UInt*", borderDwmColor, "UInt", 4)

    Gui, AppWinSwitchViewGui:New, +Parent%hAppWinSwitchGui% -Caption -Border +0x02000000 +HwndhAppWinSwitchViewGui ; WS_CLIPCHILDREN
    Gui, AppWinSwitchViewGui:Color, %guiBgHex%
    Gui, AppWinSwitchViewGui:Margin, 0, 0

    ; Tính kích thước từng ô (tự co nhỏ dần khi có nhiều cửa sổ để chứa 6-7 ô/hàng như Alt+Tab Win 11)
    ; Lưu ý: DwmRegisterThumbnail bắt buộc phải đăng ký lên Top-Level Window (hAppWinSwitchGui)
    if (AppWinSwitchShowPreview) {
        if (maxShow <= 5) {
            tileH := 174, pvMinW := 124, pvMaxW := 268
        } else if (maxShow <= 10) {
            tileH := 152, pvMinW := 112, pvMaxW := 216
        } else {
            tileH := 134, pvMinW := 104, pvMaxW := 184
        }
        pvMaxH := tileH - 38
        Loop, %maxShow% {
            idx := A_Index
            hwndSrc := AppWinSwitchWindows[idx].hwnd
            hThumb := 0
            srcW := 16, srcH := 10
            if (DllCall("dwmapi\DwmRegisterThumbnail", "Ptr", hAppWinSwitchGui, "Ptr", hwndSrc, "Ptr*", hThumb) = 0 && hThumb) {
                VarSetCapacity(srcSize, 8, 0)
                if (DllCall("dwmapi\DwmQueryThumbnailSourceSize", "Ptr", hThumb, "Ptr", &srcSize) = 0) {
                    sw := NumGet(srcSize, 0, "Int")
                    sh := NumGet(srcSize, 4, "Int")
                    if (sw > 0 && sh > 0)
                        srcW := sw, srcH := sh
                }
                AppWinSwitchThumbIds.Push(hThumb)
            } else {
                AppWinSwitchThumbIds.Push(0)
            }

            fitW := Round(pvMaxH * (srcW / srcH))
            if (fitW < pvMinW)
                fitW := pvMinW
            else if (fitW > pvMaxW)
                fitW := pvMaxW

            ratio := Min(fitW / srcW, pvMaxH / srcH)
            drawW := Round(srcW * ratio)
            drawH := Round(srcH * ratio)
            tileW := fitW + 16
            AppWinSwitchTileSizes.Push({ w: tileW, h: tileH, drawW: drawW, drawH: drawH })
        }
    } else {
        Loop, %maxShow%
            AppWinSwitchTileSizes.Push({ w: 380, h: 42, drawW: 0, drawH: 0 })
    }

    AppWinSwitchMonRect := GetMonitorWorkAreaForHwnd(AppWinSwitchWindows[1].hwnd)
    ComputeAppWinSwitchLayout(posX, posY)

    overlayW := AppWinSwitchOverlayW
    overlayH := AppWinSwitchOverlayH
    contentH := AppWinSwitchContentH

    Loop, %maxShow% {
        idx := A_Index
        item := AppWinSwitchWindows[idx]
        hIcon := GetSwitcherWindowIcon(item.hwnd, owned)
        if (owned && hIcon)
            AppWinSwitchOwnedIcons.Push(hIcon)
        AppWinSwitchTileIcons.Push(hIcon)
    }

    if (AppWinSwitchSelectedIdx > maxShow)
        AppWinSwitchSelectedIdx := maxShow
    OnMessage(0x0014, "OnAppWinSwitchEraseBg") ; WM_ERASEBKGND: chống chớp
    OnMessage(0x000F, "OnAppWinSwitchViewPaint") ; WM_PAINT: blit vùng thay đổi từ CanvasDC
    InitAppWinSwitchCanvas()
    Gui, AppWinSwitchViewGui:Show, NoActivate x0 y0 w%overlayW% h%contentH%
    EnsureAppWinSwitchTileVisible(AppWinSwitchSelectedIdx)

    DllCall("SetLayeredWindowAttributes", "Ptr", hAppWinSwitchGui, "UInt", 0, "UChar", 242, "UInt", 2) ; LWA_ALPHA = 2
    Gui, AppWinSwitchGui:Show, NoActivate x%posX% y%posY% w%overlayW% h%overlayH%, AppWindowSwitcherOverlay

    UpdateAppWinSwitchThumbnailsPos()

    OnMessage(0x0200, "OnAppWinSwitchMouseMove") ; WM_MOUSEMOVE
    OnMessage(0x02A3, "OnAppWinSwitchMouseLeave") ; WM_MOUSELEAVE
    OnMessage(0x0201, "OnAppWinSwitchClick") ; WM_LBUTTONDOWN
    OnMessage(0x020A, "OnAppWinSwitchWheel") ; WM_MOUSEWHEEL
}

ComputeAppWinSwitchLayout(ByRef outPosX, ByRef outPosY) {
    global AppWinSwitchTileSizes, AppWinSwitchTileRects, AppWinSwitchShowPreview, AppWinSwitchMonRect
    global AppWinSwitchCols, AppWinSwitchOverlayW, AppWinSwitchOverlayH, AppWinSwitchContentH, AppWinSwitchScrollMax

    scale := A_ScreenDPI / 96.0
    padX := 16, padY := 16, gapX := 10, gapY := 10
    cnt := AppWinSwitchTileSizes.Length()
    mon := AppWinSwitchMonRect
    monW := Round((mon.right - mon.left) / scale)
    monH := Round((mon.bottom - mon.top) / scale)

    maxRowW := Min(Round(monW * 0.90), 1440)
    maxColsLimit := AppWinSwitchShowPreview ? 7 : 1
    rowsList := LayoutAppWinSwitchRows(AppWinSwitchTileSizes, maxColsLimit, maxRowW, gapX)
    if (AppWinSwitchShowPreview && rowsList.Length() > 1) {
        balancedCols := Ceil(cnt / rowsList.Length())
        if (balancedCols < maxColsLimit) {
            balancedRows := LayoutAppWinSwitchRows(AppWinSwitchTileSizes, balancedCols, maxRowW, gapX)
            if (balancedRows.Length() <= rowsList.Length())
                rowsList := balancedRows
        }
    }

    AppWinSwitchCols := maxColsLimit
    maxContentW := 0
    for _, r in rowsList {
        if (r.totalW > maxContentW)
            maxContentW := r.totalW
    }

    overlayW := padX * 2 + maxContentW
    rowH := AppWinSwitchTileSizes[1].h
    contentH := padY * 2 + rowsList.Length() * rowH + (rowsList.Length() - 1) * gapY
    maxOverlayH := Floor(monH * 0.82)
    overlayH := (contentH > maxOverlayH) ? maxOverlayH : contentH

    AppWinSwitchOverlayW := overlayW
    AppWinSwitchOverlayH := overlayH
    AppWinSwitchContentH := contentH
    AppWinSwitchScrollMax := (contentH > overlayH) ? (contentH - overlayH) : 0

    AppWinSwitchTileRects := []
    Loop, %cnt%
        AppWinSwitchTileRects.Push({})

    for rIdx, r in rowsList {
        ty := padY + (rIdx - 1) * (rowH + gapY)
        tx := padX + Round((maxContentW - r.totalW) / 2)
        for _, idx in r.items {
            ts := AppWinSwitchTileSizes[idx]
            AppWinSwitchTileRects[idx] := { x: tx, y: ty, w: ts.w, h: ts.h, drawW: ts.drawW, drawH: ts.drawH, row: rIdx }
            tx += ts.w + gapX
        }
    }

    outPosX := Round(mon.left / scale) + Round((monW - overlayW) / 2)
    outPosY := Round(mon.top / scale) + Round((monH - overlayH) / 2)
}

LayoutAppWinSwitchRows(tileSizes, maxColsPerRow, maxRowW, gapX) {
    rowsList := []
    curRow := []
    curRowW := 0
    Loop, % tileSizes.Length() {
        idx := A_Index
        tw := tileSizes[idx].w
        needW := curRow.Length() ? (curRowW + gapX + tw) : tw
        if (curRow.Length() >= maxColsPerRow || (curRow.Length() > 0 && needW > maxRowW)) {
            rowsList.Push({ items: curRow, totalW: curRowW })
            curRow := [idx]
            curRowW := tw
        } else {
            curRow.Push(idx)
            curRowW := needW
        }
    }
    if (curRow.Length())
        rowsList.Push({ items: curRow, totalW: curRowW })
    return rowsList
}

UpdateAppWinSwitchThumbnailsPos() {
    global AppWinSwitchShowPreview, AppWinSwitchThumbIds, AppWinSwitchTileRects
    global AppWinSwitchScrollY, AppWinSwitchOverlayH
    if (!AppWinSwitchShowPreview || !IsObject(AppWinSwitchThumbIds))
        return

    scale := A_ScreenDPI / 96.0
    Loop, % AppWinSwitchThumbIds.Length() {
        idx := A_Index
        hThumb := AppWinSwitchThumbIds[idx]
        if (!hThumb)
            continue
        rc := AppWinSwitchTileRects[idx]
        visTop := rc.y - AppWinSwitchScrollY
        visBot := visTop + rc.h
        ; Ẩn thumbnail nếu ô nằm hoàn toàn ngoài khung nhìn hiện tại
        if (visBot <= 0 || visTop >= AppWinSwitchOverlayH) {
            UpdateFittedDwmThumbnailRect(hThumb, 0, 0, 1, 1, false)
            continue
        }

        boxX := Round((rc.x + 8) * scale)
        boxY := Round((visTop + 30) * scale)
        boxW := Round((rc.w - 16) * scale)
        boxH := Round((rc.h - 38) * scale)
        drawW := Round(rc.drawW * scale)
        drawH := Round(rc.drawH * scale)
        drawX := boxX + Round((boxW - drawW) / 2)
        drawY := boxY + Round((boxH - drawH) / 2)
        UpdateFittedDwmThumbnailRect(hThumb, drawX, drawY, drawW, drawH, true)
    }
}

UpdateFittedDwmThumbnailRect(hThumb, drawX, drawY, drawW, drawH, isVisible := true) {
    VarSetCapacity(props, 48, 0)
    NumPut(0x0000001D, props, 0, "UInt") ; DWM_TNP_RECTDESTINATION | DWM_TNP_OPACITY | DWM_TNP_VISIBLE | DWM_TNP_SOURCECLIENTAREAONLY
    NumPut(drawX, props, 4, "Int")
    NumPut(drawY, props, 8, "Int")
    NumPut(drawX + drawW, props, 12, "Int")
    NumPut(drawY + drawH, props, 16, "Int")
    NumPut(255, props, 36, "UChar")
    NumPut(isVisible ? 1 : 0, props, 37, "Int")
    NumPut(0, props, 41, "Int")
    DllCall("dwmapi\DwmUpdateThumbnailProperties", "Ptr", hThumb, "Ptr", &props)
}

CreateAppWinSwitchRoundPath(x, y, w, h, r) {
    pPath := 0
    DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pPath)
    d := r * 2.0
    if (d > w)
        d := w
    if (d > h)
        d := h
    if (d > 0.5) {
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", x, "Float", y, "Float", d, "Float", d, "Float", 180.0, "Float", 90.0)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", x + w - d, "Float", y, "Float", d, "Float", d, "Float", 270.0, "Float", 90.0)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", x + w - d, "Float", y + h - d, "Float", d, "Float", d, "Float", 0.0, "Float", 90.0)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", x, "Float", y + h - d, "Float", d, "Float", d, "Float", 90.0, "Float", 90.0)
        DllCall("gdiplus\GdipClosePathFigure", "Ptr", pPath)
    } else {
        DllCall("gdiplus\GdipAddPathRectangle", "Ptr", pPath, "Float", x, "Float", y, "Float", w, "Float", h)
    }
    return pPath
}

InitAppWinSwitchCanvas() {
    global AppWinSwitchOverlayW, AppWinSwitchContentH, AppWinSwitchTileRects
    global AppWinSwitchIsLight, AppWinSwitchGdipMod, AppWinSwitchGdipToken
    global AppWinSwitchCanvasDC, AppWinSwitchCanvasBmp, AppWinSwitchCanvasOldBmp, hAppWinSwitchViewGui

    if (!AppWinSwitchGdipToken && !GdipBeginSession(AppWinSwitchGdipMod, AppWinSwitchGdipToken))
        return false

    scale := A_ScreenDPI / 96.0
    pixW := Round(AppWinSwitchOverlayW * scale)
    pixH := Round(AppWinSwitchContentH * scale)
    bgArgb := AppWinSwitchIsLight ? 0xFFF3F3F3 : 0xFF202020

    GdipCreateCanvas(pixW, pixH, bgArgb, pBitmap, pGraphics)
    indices := []
    Loop, % AppWinSwitchTileRects.Length()
        indices.Push(A_Index)
    DrawAppWinSwitchTiles(pGraphics, indices, false)

    hBmp := 0
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", hBmp, "UInt", bgArgb)
    GdipReleaseCanvas(pBitmap, pGraphics)
    if (!hBmp)
        return false

    if (AppWinSwitchCanvasDC) {
        if (AppWinSwitchCanvasOldBmp)
            DllCall("SelectObject", "Ptr", AppWinSwitchCanvasDC, "Ptr", AppWinSwitchCanvasOldBmp)
        if (AppWinSwitchCanvasBmp)
            DllCall("DeleteObject", "Ptr", AppWinSwitchCanvasBmp)
        DllCall("DeleteDC", "Ptr", AppWinSwitchCanvasDC)
    }

    AppWinSwitchCanvasDC := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")
    AppWinSwitchCanvasBmp := hBmp
    AppWinSwitchCanvasOldBmp := DllCall("SelectObject", "Ptr", AppWinSwitchCanvasDC, "Ptr", hBmp, "Ptr")

    if (hAppWinSwitchViewGui) {
        DllCall("InvalidateRect", "Ptr", hAppWinSwitchViewGui, "Ptr", 0, "Int", 0)
        DllCall("UpdateWindow", "Ptr", hAppWinSwitchViewGui)
    }
    return true
}

PatchAppWinSwitchBackdropBmp(indices) {
    global AppWinSwitchCanvasDC, hAppWinSwitchViewGui, AppWinSwitchTileRects
    global AppWinSwitchGdipMod, AppWinSwitchGdipToken

    if (!AppWinSwitchCanvasDC || !hAppWinSwitchViewGui || !IsObject(indices) || !indices.Length())
        return false
    if (!AppWinSwitchGdipToken && !GdipBeginSession(AppWinSwitchGdipMod, AppWinSwitchGdipToken))
        return false

    pGraphics := 0
    DllCall("gdiplus\GdipCreateFromHDC", "Ptr", AppWinSwitchCanvasDC, "Ptr*", pGraphics)
    if (pGraphics) {
        DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", 4)
        DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", pGraphics, "Int", 2)
        DrawAppWinSwitchTiles(pGraphics, indices, true)
        DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGraphics)
    }

    scale := A_ScreenDPI / 96.0
    VarSetCapacity(rcDirty, 16, 0)
    for _, idx in indices {
        if (!AppWinSwitchTileRects.HasKey(idx))
            continue
        rc := AppWinSwitchTileRects[idx]
        NumPut(Floor(rc.x * scale),          rcDirty, 0, "Int")
        NumPut(Floor(rc.y * scale),          rcDirty, 4, "Int")
        NumPut(Ceil((rc.x + rc.w) * scale),  rcDirty, 8, "Int")
        NumPut(Ceil((rc.y + rc.h) * scale),  rcDirty, 12, "Int")
        DllCall("InvalidateRect", "Ptr", hAppWinSwitchViewGui, "Ptr", &rcDirty, "Int", 0)
    }
    DllCall("UpdateWindow", "Ptr", hAppWinSwitchViewGui)
    return true
}

RedrawAppWinSwitchRowBand(rowY, rowH, rowIndices) {
    global AppWinSwitchCanvasDC, hAppWinSwitchViewGui, AppWinSwitchOverlayW, AppWinSwitchIsLight
    global AppWinSwitchGdipMod, AppWinSwitchGdipToken

    if (!AppWinSwitchCanvasDC || !hAppWinSwitchViewGui || !IsObject(rowIndices) || !rowIndices.Length())
        return false
    if (!AppWinSwitchGdipToken && !GdipBeginSession(AppWinSwitchGdipMod, AppWinSwitchGdipToken))
        return false

    scale := A_ScreenDPI / 96.0
    bandX := 0
    bandY := Max(0, Floor(rowY * scale) - 2)
    bandW := Ceil(AppWinSwitchOverlayW * scale)
    bandH := Ceil(rowH * scale) + 4

    pGraphics := 0
    DllCall("gdiplus\GdipCreateFromHDC", "Ptr", AppWinSwitchCanvasDC, "Ptr*", pGraphics)
    if (pGraphics) {
        DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", 4)
        DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", pGraphics, "Int", 2)
        bgArgb := AppWinSwitchIsLight ? 0xFFF3F3F3 : 0xFF202020
        pBrushBg := 0
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", bgArgb, "Ptr*", pBrushBg)
        if (pBrushBg) {
            DllCall("gdiplus\GdipFillRectangle", "Ptr", pGraphics, "Ptr", pBrushBg, "Float", bandX, "Float", bandY, "Float", bandW, "Float", bandH)
            DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrushBg)
        }
        DrawAppWinSwitchTiles(pGraphics, rowIndices, false)
        DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGraphics)
    }

    VarSetCapacity(rcDirty, 16, 0)
    NumPut(bandX, rcDirty, 0, "Int")
    NumPut(bandY, rcDirty, 4, "Int")
    NumPut(bandX + bandW, rcDirty, 8, "Int")
    NumPut(bandY + bandH, rcDirty, 12, "Int")
    DllCall("InvalidateRect", "Ptr", hAppWinSwitchViewGui, "Ptr", &rcDirty, "Int", 0)
    DllCall("UpdateWindow", "Ptr", hAppWinSwitchViewGui)
    return true
}

OnAppWinSwitchViewPaint(wParam, lParam, msg, hwnd) {
    global hAppWinSwitchViewGui, AppWinSwitchCanvasDC
    if (hwnd != hAppWinSwitchViewGui || !AppWinSwitchCanvasDC)
        return
    VarSetCapacity(ps, A_PtrSize = 8 ? 72 : 64, 0)
    hdc := DllCall("BeginPaint", "Ptr", hwnd, "Ptr", &ps, "Ptr")
    if (hdc) {
        rx := NumGet(ps, A_PtrSize = 8 ? 12 : 8, "Int")
        ry := NumGet(ps, A_PtrSize = 8 ? 16 : 12, "Int")
        rw := NumGet(ps, A_PtrSize = 8 ? 20 : 16, "Int") - rx
        rh := NumGet(ps, A_PtrSize = 8 ? 24 : 20, "Int") - ry
        if (rw > 0 && rh > 0)
            DllCall("BitBlt", "Ptr", hdc, "Int", rx, "Int", ry, "Int", rw, "Int", rh, "Ptr", AppWinSwitchCanvasDC, "Int", rx, "Int", ry, "UInt", 0x00CC0020) ; SRCCOPY
        DllCall("EndPaint", "Ptr", hwnd, "Ptr", &ps)
    }
    return 0
}

DrawAppWinSwitchTiles(pGraphics, indices, clearTileFirst := false) {
    global AppWinSwitchTileRects, AppWinSwitchWindows, AppWinSwitchSelectedIdx
    global AppWinSwitchShowPreview, AppWinSwitchIsLight, AppWinSwitchTileIcons
    global AppWinSwitchHoverIdx, AppWinSwitchHoverClose

    scale := A_ScreenDPI / 96.0
    bgArgb        := AppWinSwitchIsLight ? 0xFFF3F3F3 : 0xFF202020
    tileNormArgb  := AppWinSwitchIsLight ? 0xFFEAEAEA : 0xFF272727
    tileSelArgb   := AppWinSwitchIsLight ? 0xFFFFFFFF : 0xFF333333
    normPenArgb   := AppWinSwitchIsLight ? 0xFFD5D5D5 : 0xFF383838
    txtNormArgb   := AppWinSwitchIsLight ? 0xFF333333 : 0xFFD4D4D4
    txtSelArgb    := AppWinSwitchIsLight ? 0xFF000000 : 0xFFFFFFFF
    accentRgb     := IsFunc("GetWindowsAccentRgb") ? GetWindowsAccentRgb() : 0x0078D7
    selPenArgb    := 0xFF000000 | accentRgb

    DllCall("gdiplus\GdipSetTextRenderingHint", "Ptr", pGraphics, "Int", 5) ; ClearTypeGridFit

    DllCall("gdiplus\GdipCreateSolidFill", "UInt", bgArgb,       "Ptr*", pBrushBg)
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", tileNormArgb, "Ptr*", pBrushNorm)
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", tileSelArgb,  "Ptr*", pBrushSel)
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", txtNormArgb,  "Ptr*", pBrushTxtNorm)
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", txtSelArgb,   "Ptr*", pBrushTxtSel)
    DllCall("gdiplus\GdipCreatePen1", "UInt", normPenArgb, "Float", 1.0 * scale, "Int", 2, "Ptr*", pPenNorm)
    DllCall("gdiplus\GdipCreatePen1", "UInt", selPenArgb,  "Float", 2.0 * scale, "Int", 2, "Ptr*", pPenSel)

    pFontFamily := 0, pFont := 0, pStrFmt := 0
    fontSizePx := (AppWinSwitchShowPreview ? 12.0 : 12.8) * scale
    DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", "Segoe UI", "Ptr", 0, "Ptr*", pFontFamily)
    if (pFontFamily)
        DllCall("gdiplus\GdipCreateFont", "Ptr", pFontFamily, "Float", fontSizePx, "Int", 0, "Int", 2, "Ptr*", pFont) ; UnitPixel = 2
    DllCall("gdiplus\GdipCreateStringFormat", "Int", 0x1000, "UShort", 0, "Ptr*", pStrFmt) ; StringFormatFlagsNoWrap
    if (pStrFmt) {
        DllCall("gdiplus\GdipSetStringFormatLineAlign", "Ptr", pStrFmt, "Int", 1)
        DllCall("gdiplus\GdipSetStringFormatTrimming", "Ptr", pStrFmt, "Int", 3)
    }

    tileRadius := 8.0 * scale
    iconPix := Round(16 * scale)
    VarSetCapacity(rectF, 16, 0)

    for _, idx in indices {
        if (!AppWinSwitchTileRects.HasKey(idx))
            continue
        rc := AppWinSwitchTileRects[idx]
        isSel := (idx = AppWinSwitchSelectedIdx)
        rx := rc.x * scale
        ry := rc.y * scale
        rw := rc.w * scale
        rh := rc.h * scale

        if (clearTileFirst)
            DllCall("gdiplus\GdipFillRectangle", "Ptr", pGraphics, "Ptr", pBrushBg, "Float", rx, "Float", ry, "Float", rw, "Float", rh)

        inset := isSel ? (1.0 * scale) : (0.5 * scale)
        pTilePath := CreateAppWinSwitchRoundPath(rx + inset, ry + inset, rw - inset * 2, rh - inset * 2, tileRadius)
        DllCall("gdiplus\GdipFillPath", "Ptr", pGraphics, "Ptr", isSel ? pBrushSel : pBrushNorm, "Ptr", pTilePath)
        DllCall("gdiplus\GdipDrawPath", "Ptr", pGraphics, "Ptr", isSel ? pPenSel : pPenNorm, "Ptr", pTilePath)
        DllCall("gdiplus\GdipDeletePath", "Ptr", pTilePath)

        hIcon := AppWinSwitchTileIcons[idx]
        if (hIcon) {
            pIconBmp := 0
            if (DllCall("gdiplus\GdipCreateBitmapFromHICON", "Ptr", hIcon, "Ptr*", pIconBmp) = 0 && pIconBmp) {
                ix := Round((rc.x + 10) * scale)
                iy := Round((AppWinSwitchShowPreview ? (rc.y + 8) : (rc.y + 13)) * scale)
                DllCall("gdiplus\GdipDrawImageRectI", "Ptr", pGraphics, "Ptr", pIconBmp, "Int", ix, "Int", iy, "Int", iconPix, "Int", iconPix)
                DllCall("gdiplus\GdipDisposeImage", "Ptr", pIconBmp)
            }
        }

        isHoverTile := (idx = AppWinSwitchHoverIdx)
        if (pFont && pStrFmt && AppWinSwitchWindows.HasKey(idx)) {
            txOff := hIcon ? 31.0 : 10.0
            tyOff := AppWinSwitchShowPreview ? 6.0 : 9.0
            thVal := AppWinSwitchShowPreview ? 20.0 : 24.0
            rightPad := isHoverTile ? 30.0 : 10.0
            twVal := rc.w - txOff - rightPad
            if (twVal > 10) {
                NumPut((rc.x + txOff) * scale, rectF, 0, "Float")
                NumPut((rc.y + tyOff) * scale, rectF, 4, "Float")
                NumPut(twVal * scale,          rectF, 8, "Float")
                NumPut(thVal * scale,          rectF, 12, "Float")
                DllCall("gdiplus\GdipDrawString", "Ptr", pGraphics, "WStr", AppWinSwitchWindows[idx].title, "Int", -1, "Ptr", pFont, "Ptr", &rectF, "Ptr", pStrFmt, "Ptr", isSel ? pBrushTxtSel : pBrushTxtNorm)
            }
        }

        if (isHoverTile) {
            cb := GetAppWinSwitchCloseRect(rc)
            cx := cb.x * scale, cy := cb.y * scale, cw := cb.w * scale, ch := cb.h * scale
            cbBgArgb := AppWinSwitchHoverClose ? 0xFFC42B1C : (AppWinSwitchIsLight ? 0x22000000 : 0x28FFFFFF)
            cbXArgb  := AppWinSwitchHoverClose ? 0xFFFFFFFF : (AppWinSwitchIsLight ? 0xFF333333 : 0xFFE6E6E6)
            pCbPath := CreateAppWinSwitchRoundPath(cx, cy, cw, ch, 4.0 * scale)
            DllCall("gdiplus\GdipCreateSolidFill", "UInt", cbBgArgb, "Ptr*", pCbBrush)
            DllCall("gdiplus\GdipFillPath", "Ptr", pGraphics, "Ptr", pCbBrush, "Ptr", pCbPath)
            DllCall("gdiplus\GdipDeleteBrush", "Ptr", pCbBrush)
            DllCall("gdiplus\GdipDeletePath", "Ptr", pCbPath)

            DllCall("gdiplus\GdipCreatePen1", "UInt", cbXArgb, "Float", 1.35 * scale, "Int", 2, "Ptr*", pCbPen)
            DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pCbPen, "Int", 2)
            DllCall("gdiplus\GdipSetPenEndCap",   "Ptr", pCbPen, "Int", 2)
            padXBtn := 5.5 * scale
            DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pCbPen, "Float", cx + padXBtn, "Float", cy + padXBtn, "Float", cx + cw - padXBtn, "Float", cy + ch - padXBtn)
            DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pCbPen, "Float", cx + cw - padXBtn, "Float", cy + padXBtn, "Float", cx + padXBtn, "Float", cy + ch - padXBtn)
            DllCall("gdiplus\GdipDeletePen", "Ptr", pCbPen)
        }
    }

    if (pStrFmt)
        DllCall("gdiplus\GdipDeleteStringFormat", "Ptr", pStrFmt)
    if (pFont)
        DllCall("gdiplus\GdipDeleteFont", "Ptr", pFont)
    if (pFontFamily)
        DllCall("gdiplus\GdipDeleteFontFamily", "Ptr", pFontFamily)
    DllCall("gdiplus\GdipDeletePen", "Ptr", pPenSel)
    DllCall("gdiplus\GdipDeletePen", "Ptr", pPenNorm)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrushTxtSel)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrushTxtNorm)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrushSel)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrushNorm)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrushBg)
}

GetSwitcherWindowIcon(hwnd, ByRef isOwned) {
    isOwned := false
    hIcon := 0
    ; Thử lấy icon nhỏ từ cửa sổ (timeout ngắn tránh treo nếu app đang bận)
    for _, iconType in [2, 0, 1] { ; ICON_SMALL2, ICON_SMALL, ICON_BIG
        res := 0
        if (DllCall("SendMessageTimeout", "Ptr", hwnd, "UInt", 0x007F, "Ptr", iconType, "Ptr", 0, "UInt", 0x0002, "UInt", 40, "Ptr*", res) && res) {
            hIcon := res
            break
        }
    }
    if (!hIcon)
        hIcon := GetClassLongPtrCompat(hwnd, -34) ; GCL_HICONSM
    if (!hIcon)
        hIcon := GetClassLongPtrCompat(hwnd, -14) ; GCL_HICON

    if (!hIcon) {
        WinGet, procPath, ProcessPath, ahk_id %hwnd%
        if (procPath != "") {
            VarSetCapacity(shfi, A_PtrSize = 8 ? 696 : 692, 0)
            if (DllCall("shell32\SHGetFileInfoW", "WStr", procPath, "UInt", 0, "Ptr", &shfi, "UInt", A_PtrSize = 8 ? 696 : 692, "UInt", 0x000000101)) { ; SHGFI_ICON | SHGFI_SMALLICON
                hIcon := NumGet(shfi, 0, "Ptr")
                if (hIcon)
                    isOwned := true
            }
        }
    }
    return hIcon
}

GetClassLongPtrCompat(hwnd, index) {
    if (A_PtrSize = 8)
        return DllCall("GetClassLongPtr", "Ptr", hwnd, "Int", index, "Ptr")
    return DllCall("GetClassLong", "Ptr", hwnd, "Int", index, "UInt")
}

OnAppWinSwitchEraseBg(wParam, lParam, msg, hwnd) {
    global hAppWinSwitchGui, hAppWinSwitchViewGui
    if (hwnd = hAppWinSwitchGui || hwnd = hAppWinSwitchViewGui)
        return 1
}

GetAppWinSwitchCloseRect(rc) {
    global AppWinSwitchShowPreview
    yOff := AppWinSwitchShowPreview ? 6 : 11
    return { x: rc.x + rc.w - 25, y: rc.y + yOff, w: 20, h: 20 }
}

IsPointInRect(px, py, rc) {
    return (px >= rc.x && px <= (rc.x + rc.w) && py >= rc.y && py <= (rc.y + rc.h))
}

OnAppWinSwitchMouseMove(wParam, lParam, msg, hwnd) {
    global AppWinSwitchActive, hAppWinSwitchGui, hAppWinSwitchViewGui
    global AppWinSwitchTileRects, AppWinSwitchHoverIdx, AppWinSwitchHoverClose
    if (!AppWinSwitchActive || !hAppWinSwitchViewGui)
        return
    if (hwnd != hAppWinSwitchGui && hwnd != hAppWinSwitchViewGui && !DllCall("IsChild", "Ptr", hAppWinSwitchGui, "Ptr", hwnd))
        return

    VarSetCapacity(tme, A_PtrSize = 8 ? 24 : 16, 0)
    NumPut(A_PtrSize = 8 ? 24 : 16, tme, 0, "UInt")
    NumPut(0x00000002, tme, 4, "UInt") ; TME_LEAVE
    NumPut(hwnd, tme, 8, "Ptr")
    DllCall("TrackMouseEvent", "Ptr", &tme)

    VarSetCapacity(pt, 8, 0)
    DllCall("GetCursorPos", "Ptr", &pt)
    DllCall("ScreenToClient", "Ptr", hAppWinSwitchViewGui, "Ptr", &pt)
    scale := A_ScreenDPI / 96.0
    cx := NumGet(pt, 0, "Int") / scale
    cy := NumGet(pt, 4, "Int") / scale

    newHoverIdx := 0
    newHoverClose := false
    for idx, rc in AppWinSwitchTileRects {
        if (IsPointInRect(cx, cy, rc)) {
            newHoverIdx := idx
            cb := GetAppWinSwitchCloseRect(rc)
            if (IsPointInRect(cx, cy, cb))
                newHoverClose := true
            break
        }
    }

    if (newHoverIdx != AppWinSwitchHoverIdx || newHoverClose != AppWinSwitchHoverClose) {
        prevHover := AppWinSwitchHoverIdx
        AppWinSwitchHoverIdx := newHoverIdx
        AppWinSwitchHoverClose := newHoverClose
        patchList := []
        if (prevHover > 0)
            patchList.Push(prevHover)
        if (newHoverIdx > 0 && newHoverIdx != prevHover)
            patchList.Push(newHoverIdx)
        if (patchList.Length())
            PatchAppWinSwitchBackdropBmp(patchList)
    }
}

OnAppWinSwitchMouseLeave(wParam, lParam, msg, hwnd) {
    global AppWinSwitchActive, AppWinSwitchHoverIdx, AppWinSwitchHoverClose, hAppWinSwitchGui
    if (!AppWinSwitchActive || !hAppWinSwitchGui)
        return
    ; Bỏ qua WM_MOUSELEAVE giả giữa các control con khi con trỏ vẫn nằm trong khung overlay
    VarSetCapacity(pt, 8, 0)
    VarSetCapacity(rcWin, 16, 0)
    if (DllCall("GetCursorPos", "Ptr", &pt) && DllCall("GetWindowRect", "Ptr", hAppWinSwitchGui, "Ptr", &rcWin)) {
        px := NumGet(pt, 0, "Int"), py := NumGet(pt, 4, "Int")
        if (px >= NumGet(rcWin, 0, "Int") && px < NumGet(rcWin, 8, "Int") && py >= NumGet(rcWin, 4, "Int") && py < NumGet(rcWin, 12, "Int"))
            return
    }
    if (AppWinSwitchHoverIdx != 0 || AppWinSwitchHoverClose) {
        prevHover := AppWinSwitchHoverIdx
        AppWinSwitchHoverIdx := 0
        AppWinSwitchHoverClose := false
        if (prevHover > 0)
            PatchAppWinSwitchBackdropBmp([prevHover])
    }
}

UpdateAppWinSwitchSelectionVisual(prevIdx := 0, ensureVis := true) {
    global AppWinSwitchCanvasDC, AppWinSwitchSelectedIdx
    if (!AppWinSwitchCanvasDC)
        return

    if (prevIdx > 0) {
        patchList := [prevIdx]
        if (AppWinSwitchSelectedIdx != prevIdx)
            patchList.Push(AppWinSwitchSelectedIdx)
        PatchAppWinSwitchBackdropBmp(patchList)
    } else {
        InitAppWinSwitchCanvas()
    }
    if (ensureVis)
        EnsureAppWinSwitchTileVisible(AppWinSwitchSelectedIdx)
}

ScrollAppWinSwitchTo(newY) {
    global hAppWinSwitchViewGui, AppWinSwitchScrollY, AppWinSwitchScrollMax
    if (!hAppWinSwitchViewGui || AppWinSwitchScrollMax <= 0)
        return
    if (newY < 0)
        newY := 0
    else if (newY > AppWinSwitchScrollMax)
        newY := AppWinSwitchScrollMax
    if (newY = AppWinSwitchScrollY)
        return
    AppWinSwitchScrollY := newY
    scale := A_ScreenDPI / 96.0
    DllCall("SetWindowPos", "Ptr", hAppWinSwitchViewGui, "Ptr", 0, "Int", 0, "Int", -Round(newY * scale), "Int", 0, "Int", 0, "UInt", 0x0015) ; SWP_NOSIZE|SWP_NOZORDER|SWP_NOACTIVATE
    UpdateAppWinSwitchThumbnailsPos()
}

EnsureAppWinSwitchTileVisible(idx) {
    global AppWinSwitchTileRects, AppWinSwitchOverlayH, AppWinSwitchScrollY, AppWinSwitchScrollMax
    if (AppWinSwitchScrollMax <= 0 || !AppWinSwitchTileRects.HasKey(idx))
        return
    rc := AppWinSwitchTileRects[idx]
    pad := 16
    topY := rc.y - pad
    botY := rc.y + rc.h + pad
    if (topY < AppWinSwitchScrollY)
        ScrollAppWinSwitchTo(topY)
    else if (botY > (AppWinSwitchScrollY + AppWinSwitchOverlayH))
        ScrollAppWinSwitchTo(botY - AppWinSwitchOverlayH)
}

OnAppWinSwitchWheel(wParam, lParam, msg, hwnd) {
    global AppWinSwitchActive, AppWinSwitchScrollY, AppWinSwitchScrollMax, hAppWinSwitchGui
    if (!AppWinSwitchActive || !hAppWinSwitchGui || AppWinSwitchScrollMax <= 0)
        return
    delta := (wParam << 32 >> 48) ; signed HIWORD
    step := (delta > 0) ? -60 : 60
    ScrollAppWinSwitchTo(AppWinSwitchScrollY + step)
    return 0
}

OnAppWinSwitchClick(wParam, lParam, msg, hwnd) {
    global hAppWinSwitchGui, hAppWinSwitchViewGui, AppWinSwitchActive, AppWinSwitchTileRects, AppWinSwitchSelectedIdx, AppWinSwitchCloseIdx
    if (!AppWinSwitchActive || !hAppWinSwitchViewGui)
        return
    if (hwnd != hAppWinSwitchGui && hwnd != hAppWinSwitchViewGui && !DllCall("IsChild", "Ptr", hAppWinSwitchGui, "Ptr", hwnd))
        return

    VarSetCapacity(pt, 8, 0)
    DllCall("GetCursorPos", "Ptr", &pt)
    DllCall("ScreenToClient", "Ptr", hAppWinSwitchViewGui, "Ptr", &pt)
    scale := A_ScreenDPI / 96.0
    cx := NumGet(pt, 0, "Int") / scale
    cy := NumGet(pt, 4, "Int") / scale

    for idx, rc in AppWinSwitchTileRects {
        if (IsPointInRect(cx, cy, rc)) {
            cb := GetAppWinSwitchCloseRect(rc)
            if (IsPointInRect(cx, cy, cb)) {
                AppWinSwitchCloseIdx := idx
                SetTimer, AppWinSwitchCloseTileDeferred, -1
                return 0
            }
            AppWinSwitchSelectedIdx := idx
            SetTimer, AppWinSwitchCommitDeferred, -1
            return 0
        }
    }
}

AppWinSwitchCommitDeferred:
    CommitAppWindowSwitcher()
return

AppWinSwitchCloseTileDeferred:
    CloseTileFromAppWindowSwitcher(AppWinSwitchCloseIdx)
return

CloseTileFromAppWindowSwitcher(idx) {
    global AppWinSwitchActive, AppWinSwitchWindows, AppWinSwitchPendingCloseHwnds

    if (!AppWinSwitchActive || idx < 1 || idx > AppWinSwitchWindows.Length())
        return

    targetHwnd := AppWinSwitchWindows[idx].hwnd
    if (!targetHwnd || !DllCall("IsWindow", "Ptr", targetHwnd)) {
        RemoveTileFromAppWindowSwitcher(idx)
        return
    }

    PostMessage, 0x0010, 0, 0, , ahk_id %targetHwnd% ; WM_CLOSE

    if (!IsObject(AppWinSwitchPendingCloseHwnds))
        AppWinSwitchPendingCloseHwnds := []
    for _, item in AppWinSwitchPendingCloseHwnds {
        if (item.hwnd = targetHwnd) {
            item.tick := A_TickCount
            SetTimer, WatchAppWinSwitchPendingClose, 40
            return
        }
    }
    AppWinSwitchPendingCloseHwnds.Push({ hwnd: targetHwnd, tick: A_TickCount })
    SetTimer, WatchAppWinSwitchPendingClose, 40
}

WatchAppWinSwitchPendingClose:
    if (!AppWinSwitchActive || !IsObject(AppWinSwitchPendingCloseHwnds) || !AppWinSwitchPendingCloseHwnds.Length()) {
        SetTimer, WatchAppWinSwitchPendingClose, Off
        return
    }
    pIdx := AppWinSwitchPendingCloseHwnds.Length()
    while (pIdx >= 1) {
        item := AppWinSwitchPendingCloseHwnds[pIdx]
        hwnd := item.hwnd
        isAlive := hwnd && DllCall("IsWindow", "Ptr", hwnd) && DllCall("IsWindowVisible", "Ptr", hwnd)
        if (!isAlive) {
            AppWinSwitchPendingCloseHwnds.RemoveAt(pIdx)
            foundIdx := 0
            for wIdx, wInfo in AppWinSwitchWindows {
                if (wInfo.hwnd = hwnd) {
                    foundIdx := wIdx
                    break
                }
            }
            if (foundIdx > 0)
                RemoveTileFromAppWindowSwitcher(foundIdx)
        } else if (DllCall("IsWindowEnabled", "Ptr", hwnd) && (A_TickCount - item.tick > 1500)) {
            AppWinSwitchPendingCloseHwnds.RemoveAt(pIdx)
        }
        pIdx -= 1
    }
    if (!AppWinSwitchActive || !AppWinSwitchPendingCloseHwnds.Length())
        SetTimer, WatchAppWinSwitchPendingClose, Off
return

RemoveTileFromAppWindowSwitcher(idx) {
    global AppWinSwitchActive, AppWinSwitchWindows, AppWinSwitchSelectedIdx
    global AppWinSwitchThumbIds, AppWinSwitchTileSizes, AppWinSwitchTileIcons, AppWinSwitchTileRects
    global AppWinSwitchHoverIdx, AppWinSwitchHoverClose, AppWinSwitchScrollY, AppWinSwitchScrollMax
    global hAppWinSwitchGui, hAppWinSwitchViewGui
    global AppWinSwitchOverlayW, AppWinSwitchOverlayH, AppWinSwitchContentH

    if (!AppWinSwitchActive || idx < 1 || idx > AppWinSwitchWindows.Length())
        return

    closedRow := AppWinSwitchTileRects.HasKey(idx) ? AppWinSwitchTileRects[idx].row : 0

    ; Chỉ hủy đúng thumbnail của ô bị đóng, giữ nguyên toàn bộ thumbnail và GUI còn lại
    if (AppWinSwitchThumbIds.HasKey(idx) && AppWinSwitchThumbIds[idx])
        DllCall("dwmapi\DwmUnregisterThumbnail", "Ptr", AppWinSwitchThumbIds[idx])
    if (AppWinSwitchThumbIds.HasKey(idx))
        AppWinSwitchThumbIds.RemoveAt(idx)
    if (AppWinSwitchTileSizes.HasKey(idx))
        AppWinSwitchTileSizes.RemoveAt(idx)
    if (AppWinSwitchTileIcons.HasKey(idx))
        AppWinSwitchTileIcons.RemoveAt(idx)
    if (AppWinSwitchTileRects.HasKey(idx))
        AppWinSwitchTileRects.RemoveAt(idx)
    AppWinSwitchWindows.RemoveAt(idx)

    if (AppWinSwitchWindows.Length() < 2) {
        CloseAppWindowSwitcherOverlay()
        return
    }

    if (AppWinSwitchSelectedIdx > AppWinSwitchWindows.Length())
        AppWinSwitchSelectedIdx := AppWinSwitchWindows.Length()
    else if (AppWinSwitchSelectedIdx > idx)
        AppWinSwitchSelectedIdx -= 1

    AppWinSwitchHoverIdx := 0
    AppWinSwitchHoverClose := false

    ; Nếu hàng chứa ô vừa đóng vẫn còn ô, giữ nguyên bố cục các hàng khác và kích thước overlay
    rowIndices := []
    if (closedRow > 0) {
        Loop, % AppWinSwitchTileRects.Length() {
            if (AppWinSwitchTileRects[A_Index].row = closedRow)
                rowIndices.Push(A_Index)
        }
    }

    if (rowIndices.Length() > 0) {
        padX := 16, gapX := 10
        maxContentW := AppWinSwitchOverlayW - padX * 2
        rowTotalW := 0
        for rPos, k in rowIndices
            rowTotalW += AppWinSwitchTileRects[k].w + (rPos > 1 ? gapX : 0)
        rowY := AppWinSwitchTileRects[rowIndices[1]].y
        rowH := AppWinSwitchTileRects[rowIndices[1]].h
        tx := padX + Round((maxContentW - rowTotalW) / 2)
        for _, k in rowIndices {
            AppWinSwitchTileRects[k].x := tx
            tx += AppWinSwitchTileRects[k].w + gapX
        }
        RedrawAppWinSwitchRowBand(rowY, rowH, rowIndices)
        UpdateAppWinSwitchThumbnailsPos()
        return
    }

    ComputeAppWinSwitchLayout(posX, posY)
    if (AppWinSwitchScrollY > AppWinSwitchScrollMax)
        AppWinSwitchScrollY := AppWinSwitchScrollMax

    scale := A_ScreenDPI / 96.0
    DllCall("SetWindowPos", "Ptr", hAppWinSwitchGui, "Ptr", 0, "Int", Round(posX * scale), "Int", Round(posY * scale), "Int", Round(AppWinSwitchOverlayW * scale), "Int", Round(AppWinSwitchOverlayH * scale), "UInt", 0x0014) ; SWP_NOZORDER|SWP_NOACTIVATE
    DllCall("SetWindowPos", "Ptr", hAppWinSwitchViewGui, "Ptr", 0, "Int", 0, "Int", -Round(AppWinSwitchScrollY * scale), "Int", Round(AppWinSwitchOverlayW * scale), "Int", Round(AppWinSwitchContentH * scale), "UInt", 0x0014)

    InitAppWinSwitchCanvas()
    UpdateAppWinSwitchThumbnailsPos()
}

CloseAppWindowSwitcherOverlay(clearState := true) {
    global AppWinSwitchActive, AppWinSwitchThumbIds, hAppWinSwitchGui, hAppWinSwitchViewGui, AppWinSwitchTileRects, AppWinSwitchWindows, AppWinSwitchOwnedIcons
    global AppWinSwitchCanvasDC, AppWinSwitchCanvasBmp, AppWinSwitchCanvasOldBmp, AppWinSwitchScrollY, AppWinSwitchScrollMax
    global AppWinSwitchGdipMod, AppWinSwitchGdipToken, AppWinSwitchHoverIdx, AppWinSwitchHoverClose, AppWinSwitchPendingCloseHwnds

    SetTimer, WatchAppWinSwitchModifier, Off
    SetTimer, WatchAppWinSwitchPendingClose, Off
    AppWinSwitchPendingCloseHwnds := []
    OnMessage(0x000F, "OnAppWinSwitchViewPaint", 0)
    OnMessage(0x0014, "OnAppWinSwitchEraseBg", 0)
    OnMessage(0x0200, "OnAppWinSwitchMouseMove", 0)
    OnMessage(0x02A3, "OnAppWinSwitchMouseLeave", 0)
    OnMessage(0x0201, "OnAppWinSwitchClick", 0)
    OnMessage(0x020A, "OnAppWinSwitchWheel", 0)

    if (IsObject(AppWinSwitchThumbIds)) {
        for _, tid in AppWinSwitchThumbIds {
            if (tid)
                DllCall("dwmapi\DwmUnregisterThumbnail", "Ptr", tid)
        }
    }
    AppWinSwitchThumbIds := []

    if (hAppWinSwitchViewGui) {
        try Gui, AppWinSwitchViewGui:Destroy
        hAppWinSwitchViewGui := 0
    }
    if (hAppWinSwitchGui) {
        try Gui, AppWinSwitchGui:Destroy
        hAppWinSwitchGui := 0
    }
    AppWinSwitchScrollY := 0
    AppWinSwitchScrollMax := 0
    AppWinSwitchHoverIdx := 0
    AppWinSwitchHoverClose := false

    if (AppWinSwitchCanvasDC) {
        if (AppWinSwitchCanvasOldBmp)
            DllCall("SelectObject", "Ptr", AppWinSwitchCanvasDC, "Ptr", AppWinSwitchCanvasOldBmp)
        DllCall("DeleteDC", "Ptr", AppWinSwitchCanvasDC)
        AppWinSwitchCanvasDC := 0
        AppWinSwitchCanvasOldBmp := 0
    }
    if (AppWinSwitchCanvasBmp) {
        DllCall("DeleteObject", "Ptr", AppWinSwitchCanvasBmp)
        AppWinSwitchCanvasBmp := 0
    }

    if (IsObject(AppWinSwitchOwnedIcons)) {
        for _, hIco in AppWinSwitchOwnedIcons {
            if (hIco)
                DllCall("DestroyIcon", "Ptr", hIco)
        }
    }
    AppWinSwitchOwnedIcons := []

    AppWinSwitchTileRects := []
    AppWinSwitchTileIcons := []
    if (AppWinSwitchGdipToken || AppWinSwitchGdipMod) {
        GdipEndSession(AppWinSwitchGdipMod, AppWinSwitchGdipToken)
        AppWinSwitchGdipMod := 0
        AppWinSwitchGdipToken := 0
    }
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
