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
*Tab::MoveAppWinSwitchSelection(1)
*+Tab::MoveAppWinSwitchSelection(-1)
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
    global hAppWinSwitchGui, AppWinSwitchThumbIds, AppWinSwitchTileRects, AppWinSwitchTileCtrls
    global AppWinSwitchCols, AppWinSwitchOwnedIcons, AppWinSwitchTileIcons
    global AppWinSwitchOverlayW, AppWinSwitchOverlayH, hAppWinSwitchBgPic, AppWinSwitchBgBmp, AppWinSwitchIsLight

    CloseAppWindowSwitcherOverlay(false)

    cnt := AppWinSwitchWindows.Length()
    if (cnt < 2)
        return

    maxShow := (cnt > 12) ? 12 : cnt
    scale := A_ScreenDPI / 96.0
    AppWinSwitchIsLight := IsWindowsLightTheme()

    padX := 16
    padY := 16
    gapX := 10
    gapY := 10

    AppWinSwitchTileRects := []
    AppWinSwitchTileCtrls := []
    AppWinSwitchThumbIds := []
    AppWinSwitchOwnedIcons := []
    AppWinSwitchTileIcons := []
    AppWinSwitchBgBmp := 0

    ; Tạo GUI trước (ẩn) để có thể query DwmQueryThumbnailSourceSize chính xác cho từng cửa sổ
    guiBgHex := AppWinSwitchIsLight ? "F3F3F3" : "202020"
    borderDwmColor := AppWinSwitchIsLight ? 0xD2D2D2 : 0x424242

    Gui, AppWinSwitchGui:New, -Caption +ToolWindow +AlwaysOnTop +E0x08000000 +HwndhAppWinSwitchGui
    Gui, AppWinSwitchGui:Color, %guiBgHex%
    Gui, AppWinSwitchGui:Margin, 0, 0

    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hAppWinSwitchGui, "UInt", 20, "Int*", AppWinSwitchIsLight ? 0 : 1, "UInt", 4)
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hAppWinSwitchGui, "UInt", 33, "Int*", 2, "UInt", 4)
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hAppWinSwitchGui, "UInt", 34, "UInt*", borderDwmColor, "UInt", 4)

    ; Tính kích thước từng ô (ô preview co giãn theo đúng tỷ lệ thật của cửa sổ như Alt+Tab Win 11)
    tileSizes := []
    if (AppWinSwitchShowPreview) {
        tileH := 174
        pvMaxH := tileH - 38 ; 136px
        pvMinW := 124
        pvMaxW := 268
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

            ; Tính kích thước ảnh thumbnail thực tế bên trong ô (không dư khoảng đen 2 bên)
            ratio := Min(fitW / srcW, pvMaxH / srcH)
            drawW := Round(srcW * ratio)
            drawH := Round(srcH * ratio)
            tileW := fitW + 16
            tileSizes.Push({ w: tileW, h: tileH, drawW: drawW, drawH: drawH })
        }
    } else {
        Loop, %maxShow%
            tileSizes.Push({ w: 380, h: 42, drawW: 0, drawH: 0 })
    }

    ; Chia hàng linh hoạt (tối đa 4 ô/hàng và không vượt quá ~980px), căn giữa từng hàng
    rowsList := []
    curRow := []
    curRowW := 0
    maxRowW := 960
    maxColsPerRow := AppWinSwitchShowPreview ? 4 : 1

    Loop, %maxShow% {
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

    AppWinSwitchCols := maxColsPerRow
    maxContentW := 0
    for _, r in rowsList {
        if (r.totalW > maxContentW)
            maxContentW := r.totalW
    }

    overlayW := padX * 2 + maxContentW
    rowH := tileSizes[1].h
    overlayH := padY * 2 + rowsList.Length() * rowH + (rowsList.Length() - 1) * gapY
    AppWinSwitchOverlayW := overlayW
    AppWinSwitchOverlayH := overlayH

    ; Khởi tạo mảng tọa độ theo đúng thứ tự idx 1..maxShow
    Loop, %maxShow%
        AppWinSwitchTileRects.Push({})

    for rIdx, r in rowsList {
        ty := padY + (rIdx - 1) * (rowH + gapY)
        tx := padX + Round((maxContentW - r.totalW) / 2)
        for _, idx in r.items {
            ts := tileSizes[idx]
            AppWinSwitchTileRects[idx] := { x: tx, y: ty, w: ts.w, h: ts.h, drawW: ts.drawW, drawH: ts.drawH }
            tx += ts.w + gapX
        }
    }

    ; Tính vị trí căn giữa màn hình chứa cửa sổ đang active
    mon := GetMonitorWorkAreaForHwnd(AppWinSwitchWindows[1].hwnd)
    monW := Round((mon.right - mon.left) / scale)
    monH := Round((mon.bottom - mon.top) / scale)
    posX := Round(mon.left / scale) + Round((monW - overlayW) / 2)
    posY := Round(mon.top / scale) + Round((monH - overlayH) / 2)

    ; Nền GDI+ vẽ toàn bộ các ô bo góc mượt, viền Accent và icon alpha chuẩn (không bị nền đen)
    Gui, AppWinSwitchGui:Add, Picture, x0 y0 w%overlayW% h%overlayH% +0xE +HwndhAppWinSwitchBgPic ; SS_BITMAP

    titleNormColor := AppWinSwitchIsLight ? "c333333" : "cD8D8D8"
    Loop, %maxShow% {
        idx := A_Index
        item := AppWinSwitchWindows[idx]
        rc := AppWinSwitchTileRects[idx]
        tx := rc.x, ty := rc.y, tw := rc.w

        hIcon := GetSwitcherWindowIcon(item.hwnd, owned)
        if (owned && hIcon)
            AppWinSwitchOwnedIcons.Push(hIcon)
        AppWinSwitchTileIcons.Push(hIcon)

        titleX := hIcon ? (tx + 32) : (tx + 10)
        availTitleW := tw - (titleX - tx) - 10
        maxChars := Floor(availTitleW / 6.8)
        if (maxChars < 8)
            maxChars := 8

        shortTitle := item.title
        if (StrLen(shortTitle) > maxChars)
            shortTitle := SubStr(shortTitle, 1, maxChars - 1) . "…"

        if (AppWinSwitchShowPreview) {
            Gui, AppWinSwitchGui:Font, s9 Norm %titleNormColor%, Segoe UI
            Gui, AppWinSwitchGui:Add, Text, % "x" . titleX . " y" . (ty + 7) . " w" . availTitleW . " h18 +0x200 +0x80 BackgroundTrans +HwndhTitleCtrl", % shortTitle
        } else {
            Gui, AppWinSwitchGui:Font, s9.5 Norm %titleNormColor%, Segoe UI
            Gui, AppWinSwitchGui:Add, Text, % "x" . titleX . " y" . (ty + 10) . " w" . availTitleW . " h22 +0x200 +0x80 BackgroundTrans +HwndhTitleCtrl", % shortTitle
        }

        AppWinSwitchTileCtrls.Push({ title: hTitleCtrl })
    }

    UpdateAppWinSwitchSelectionVisual()
    Gui, AppWinSwitchGui:Show, NoActivate x%posX% y%posY% w%overlayW% h%overlayH%, AppWindowSwitcherOverlay
    WinSet, Transparent, 242, ahk_id %hAppWinSwitchGui%

    ; Cập nhật vị trí DWM Live Thumbnails khớp chính xác với kích thước ảnh thật, căn giữa trong ô
    if (AppWinSwitchShowPreview) {
        Loop, %maxShow% {
            idx := A_Index
            hThumb := AppWinSwitchThumbIds[idx]
            if (!hThumb)
                continue
            rc := AppWinSwitchTileRects[idx]
            boxX := Round((rc.x + 8) * scale)
            boxY := Round((rc.y + 30) * scale)
            boxW := Round((rc.w - 16) * scale)
            boxH := Round((rc.h - 38) * scale)
            drawW := Round(rc.drawW * scale)
            drawH := Round(rc.drawH * scale)
            drawX := boxX + Round((boxW - drawW) / 2)
            drawY := boxY + Round((boxH - drawH) / 2)
            UpdateFittedDwmThumbnailRect(hThumb, drawX, drawY, drawW, drawH)
        }
    }

    OnMessage(0x0201, "OnAppWinSwitchClick") ; WM_LBUTTONDOWN
}

UpdateFittedDwmThumbnailRect(hThumb, drawX, drawY, drawW, drawH) {
    VarSetCapacity(props, 48, 0)
    NumPut(0x0000001D, props, 0, "UInt") ; DWM_TNP_RECTDESTINATION | DWM_TNP_OPACITY | DWM_TNP_VISIBLE | DWM_TNP_SOURCECLIENTAREAONLY
    NumPut(drawX, props, 4, "Int")
    NumPut(drawY, props, 8, "Int")
    NumPut(drawX + drawW, props, 12, "Int")
    NumPut(drawY + drawH, props, 16, "Int")
    NumPut(255, props, 36, "UChar")
    NumPut(1, props, 37, "Int")
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

BuildAppWinSwitchBackdropBmp() {
    global AppWinSwitchOverlayW, AppWinSwitchOverlayH, AppWinSwitchTileRects
    global AppWinSwitchSelectedIdx, AppWinSwitchShowPreview, AppWinSwitchIsLight, AppWinSwitchTileIcons

    if (!GdipBeginSession(hGdip, pToken))
        return 0

    scale := A_ScreenDPI / 96.0
    pixW := Round(AppWinSwitchOverlayW * scale)
    pixH := Round(AppWinSwitchOverlayH * scale)

    bgArgb        := AppWinSwitchIsLight ? 0xFFF3F3F3 : 0xFF202020
    tileNormArgb  := AppWinSwitchIsLight ? 0xFFEAEAEA : 0xFF272727
    tileSelArgb   := AppWinSwitchIsLight ? 0xFFFFFFFF : 0xFF333333
    normPenArgb   := AppWinSwitchIsLight ? 0xFFD5D5D5 : 0xFF383838
    accentRgb     := IsFunc("GetWindowsAccentRgb") ? GetWindowsAccentRgb() : 0x0078D7
    selPenArgb    := 0xFF000000 | accentRgb

    GdipCreateCanvas(pixW, pixH, bgArgb, pBitmap, pGraphics)

    DllCall("gdiplus\GdipCreateSolidFill", "UInt", tileNormArgb, "Ptr*", pBrushNorm)
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", tileSelArgb,  "Ptr*", pBrushSel)
    DllCall("gdiplus\GdipCreatePen1", "UInt", normPenArgb, "Float", 1.0 * scale, "Int", 2, "Ptr*", pPenNorm)
    DllCall("gdiplus\GdipCreatePen1", "UInt", selPenArgb,  "Float", 2.0 * scale, "Int", 2, "Ptr*", pPenSel)

    tileRadius := 8.0 * scale
    iconPix := Round(16 * scale)

    for idx, rc in AppWinSwitchTileRects {
        isSel := (idx = AppWinSwitchSelectedIdx)
        rx := rc.x * scale
        ry := rc.y * scale
        rw := rc.w * scale
        rh := rc.h * scale

        ; Chừa nửa độ dày nét vẽ để viền không bị cắt mép
        inset := isSel ? (1.0 * scale) : (0.5 * scale)
        pTilePath := CreateAppWinSwitchRoundPath(rx + inset, ry + inset, rw - inset * 2, rh - inset * 2, tileRadius)
        DllCall("gdiplus\GdipFillPath", "Ptr", pGraphics, "Ptr", isSel ? pBrushSel : pBrushNorm, "Ptr", pTilePath)
        DllCall("gdiplus\GdipDrawPath", "Ptr", pGraphics, "Ptr", isSel ? pPenSel : pPenNorm, "Ptr", pTilePath)
        DllCall("gdiplus\GdipDeletePath", "Ptr", pTilePath)

        ; Vẽ icon trực tiếp lên canvas GDI+ để giữ alpha trong suốt, không bị nền đen
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
    }

    DllCall("gdiplus\GdipDeletePen", "Ptr", pPenSel)
    DllCall("gdiplus\GdipDeletePen", "Ptr", pPenNorm)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrushSel)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrushNorm)

    hBmp := 0
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", hBmp, "UInt", bgArgb)
    GdipReleaseCanvas(pBitmap, pGraphics)
    GdipEndSession(hGdip, pToken)
    return hBmp
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
    global AppWinSwitchTileCtrls, AppWinSwitchSelectedIdx, AppWinSwitchShowPreview
    global hAppWinSwitchBgPic, AppWinSwitchBgBmp, AppWinSwitchIsLight
    if (!IsObject(AppWinSwitchTileCtrls) || !hAppWinSwitchBgPic)
        return

    newBmp := BuildAppWinSwitchBackdropBmp()
    if (newBmp) {
        oldBmp := AppWinSwitchBgBmp
        AppWinSwitchBgBmp := newBmp
        DllCall("SendMessage", "Ptr", hAppWinSwitchBgPic, "UInt", 0x0172, "Ptr", 0, "Ptr", newBmp) ; STM_SETIMAGE, IMAGE_BITMAP
        if (oldBmp)
            DllCall("DeleteObject", "Ptr", oldBmp)
    }

    for idx, ctrls in AppWinSwitchTileCtrls {
        isSel := (idx = AppWinSwitchSelectedIdx)
        colorOpt := AppWinSwitchIsLight ? (isSel ? "c000000" : "c444444") : (isSel ? "cFFFFFF" : "cD4D4D4")
        if (AppWinSwitchShowPreview)
            Gui, AppWinSwitchGui:Font, % "s9 Norm " . colorOpt, Segoe UI
        else
            Gui, AppWinSwitchGui:Font, % "s9.5 Norm " . colorOpt, Segoe UI
        GuiControl, AppWinSwitchGui:Font, % ctrls.title
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
    global AppWinSwitchActive, AppWinSwitchThumbIds, hAppWinSwitchGui, AppWinSwitchTileRects, AppWinSwitchTileCtrls, AppWinSwitchWindows, AppWinSwitchOwnedIcons
    global hAppWinSwitchBgPic, AppWinSwitchBgBmp

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
    hAppWinSwitchBgPic := 0

    if (AppWinSwitchBgBmp) {
        DllCall("DeleteObject", "Ptr", AppWinSwitchBgBmp)
        AppWinSwitchBgBmp := 0
    }

    if (IsObject(AppWinSwitchOwnedIcons)) {
        for _, hIco in AppWinSwitchOwnedIcons {
            if (hIco)
                DllCall("DestroyIcon", "Ptr", hIco)
        }
    }
    AppWinSwitchOwnedIcons := []

    AppWinSwitchTileRects := []
    AppWinSwitchTileCtrls := []
    AppWinSwitchTileIcons := []
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
