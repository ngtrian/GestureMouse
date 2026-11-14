; WindowHopper.ahk - Chuyển đổi nhanh giữa các cửa sổ cùng ứng dụng (tương tự PowerToys Window Hopper)
#NoEnv

InitWindowHopper() {
    global WinHopperEnabled, WinHopperHotkey, WinHopperBackHotkey, WinHopperShowPreview
    global WinHopperRegFwdHk, WinHopperRegBackHk
    global WinHopperActive, WinHopperWindows, WinHopperSelectedIdx, WinHopperHoldMod
    global WinHopperThumbIds, hWinHopperGui, WinHopperTileRects, WinHopperTileCtrls

    WinHopperEnabled := 1
    WinHopperHotkey := "!vkC0"      ; Mặc định: Alt + `
    WinHopperBackHotkey := "!+vkC0" ; Mặc định: Alt + Shift + `
    WinHopperShowPreview := 1
    WinHopperRegFwdHk := ""
    WinHopperRegBackHk := ""

    WinHopperActive := false
    WinHopperWindows := []
    WinHopperSelectedIdx := 1
    WinHopperHoldMod := ""
    WinHopperThumbIds := []
    WinHopperTileRects := []
    WinHopperTileCtrls := []
    hWinHopperGui := 0

    RegRead, valEn, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, WinHopperEnabled
    if (!ErrorLevel && valEn != "")
        WinHopperEnabled := valEn ? 1 : 0

    RegRead, valFwd, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, WinHopperHotkey
    if (!ErrorLevel && valFwd != "")
        WinHopperHotkey := valFwd

    RegRead, valBack, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, WinHopperBackHotkey
    if (!ErrorLevel && valBack != "")
        WinHopperBackHotkey := valBack

    RegRead, valPrev, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, WinHopperShowPreview
    if (!ErrorLevel && valPrev != "")
        WinHopperShowPreview := valPrev ? 1 : 0

    ApplyWindowHopperHotkeys()
    OnExit("CleanupWindowHopper")
}

ApplyWindowHopperHotkeys() {
    global WinHopperEnabled, WinHopperHotkey, WinHopperBackHotkey
    global WinHopperRegFwdHk, WinHopperRegBackHk

    if (WinHopperRegFwdHk != "") {
        try Hotkey, %WinHopperRegFwdHk%, WinHopperForwardHandler, Off
        WinHopperRegFwdHk := ""
    }
    if (WinHopperRegBackHk != "") {
        try Hotkey, %WinHopperRegBackHk%, WinHopperBackwardHandler, Off
        WinHopperRegBackHk := ""
    }

    if (!WinHopperEnabled)
        return

    if (WinHopperHotkey != "") {
        try {
            Hotkey, %WinHopperHotkey%, WinHopperForwardHandler, On
            WinHopperRegFwdHk := WinHopperHotkey
        }
    }
    if (WinHopperBackHotkey != "") {
        try {
            Hotkey, %WinHopperBackHotkey%, WinHopperBackwardHandler, On
            WinHopperRegBackHk := WinHopperBackHotkey
        }
    }
}

FormatWinHopperHotkeyText(hk) {
    return FormatHotkeyText(hk)
}

WinHopperForwardHandler:
    TriggerWindowHopper(1, WinHopperHotkey)
return

WinHopperBackwardHandler:
    TriggerWindowHopper(-1, WinHopperBackHotkey)
return

#If (WinHopperActive)
*Esc::CancelWindowHopper()
*Left::MoveWinHopperSelection(-1)
*Right::MoveWinHopperSelection(1)
*Up::MoveWinHopperRow(-1)
*Down::MoveWinHopperRow(1)
*Enter::CommitWindowHopper()
#If

TriggerWindowHopper(dir := 1, triggeredHk := "") {
    global WinHopperEnabled, WinHopperActive, WinHopperWindows, WinHopperSelectedIdx, WinHopperHoldMod

    if (!WinHopperEnabled)
        return

    if (WinHopperActive) {
        MoveWinHopperSelection(dir)
        return
    }

    activeHwnd := WinExist("A") + 0
    if (!activeHwnd)
        return

    windows := GetSameAppWindows(activeHwnd)
    if (windows.Length() < 2)
        return

    WinHopperWindows := windows
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
    WinHopperSelectedIdx := nextIdx

    WinHopperHoldMod := DetectWinHopperHoldMod(triggeredHk)

    ; Nếu phím tắt không có modifier giữ hoặc người dùng đã nhả modifier ngay lập tức -> chuyển nhanh
    if (WinHopperHoldMod = "" || !IsWinHopperHoldModDown(WinHopperHoldMod)) {
        targetHwnd := WinHopperWindows[WinHopperSelectedIdx].hwnd
        WinHopperWindows := []
        SwitchToHopperWindow(targetHwnd)
        return
    }

    WinHopperActive := true
    ShowWindowHopperOverlay()
    SetTimer, WatchWinHopperModifier, 20
}

DetectWinHopperHoldMod(hk) {
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

IsWinHopperHoldModDown(modName) {
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

WatchWinHopperModifier:
    if (!WinHopperActive) {
        SetTimer, WatchWinHopperModifier, Off
        return
    }
    if (WinHopperHoldMod != "" && !IsWinHopperHoldModDown(WinHopperHoldMod)) {
        SetTimer, WatchWinHopperModifier, Off
        CommitWindowHopper()
    }
return

MoveWinHopperSelection(delta) {
    global WinHopperActive, WinHopperWindows, WinHopperSelectedIdx
    if (!WinHopperActive || !WinHopperWindows.Length())
        return

    cnt := WinHopperWindows.Length()
    WinHopperSelectedIdx += delta
    if (WinHopperSelectedIdx > cnt)
        WinHopperSelectedIdx := 1
    else if (WinHopperSelectedIdx < 1)
        WinHopperSelectedIdx := cnt

    UpdateWinHopperSelectionVisual()
}

MoveWinHopperRow(rowDelta) {
    global WinHopperActive, WinHopperWindows, WinHopperSelectedIdx, WinHopperCols
    if (!WinHopperActive || !WinHopperWindows.Length())
        return

    cols := WinHopperCols ? WinHopperCols : 1
    cnt := WinHopperWindows.Length()
    newIdx := WinHopperSelectedIdx + (rowDelta * cols)
    if (newIdx >= 1 && newIdx <= cnt) {
        WinHopperSelectedIdx := newIdx
        UpdateWinHopperSelectionVisual()
    }
}

CommitWindowHopper() {
    global WinHopperActive, WinHopperWindows, WinHopperSelectedIdx
    if (!WinHopperActive)
        return

    targetHwnd := 0
    if (WinHopperSelectedIdx >= 1 && WinHopperSelectedIdx <= WinHopperWindows.Length())
        targetHwnd := WinHopperWindows[WinHopperSelectedIdx].hwnd

    CloseWindowHopperOverlay()
    if (targetHwnd)
        SwitchToHopperWindow(targetHwnd)
}

CancelWindowHopper() {
    global WinHopperActive
    if (!WinHopperActive)
        return
    CloseWindowHopperOverlay()
}

SwitchToHopperWindow(hwnd) {
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
    activeKey := GetWindowHopperAppKey(activeHwnd)
    if (activeKey = "")
        return result

    WinGet, idList, List
    Loop, %idList% {
        hwnd := idList%A_Index% + 0
        if (!IsEligibleHopperWindow(hwnd))
            continue
        if (GetWindowHopperAppKey(hwnd) != activeKey)
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

IsEligibleHopperWindow(hwnd) {
    global hWinHopperGui
    if (!hwnd || hwnd = hWinHopperGui)
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

GetWindowHopperAppKey(hwnd) {
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

GetWindowHopperAppDisplayName(hwnd) {
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
ShowWindowHopperOverlay() {
    global WinHopperWindows, WinHopperSelectedIdx, WinHopperShowPreview
    global hWinHopperGui, WinHopperThumbIds, WinHopperTileRects, WinHopperTileCtrls
    global WinHopperCols, WinHopperOverlayW, WinHopperOverlayH, WinHopperHeaderH

    CloseWindowHopperOverlay(false)

    cnt := WinHopperWindows.Length()
    if (cnt < 2)
        return

    maxShow := (cnt > 12) ? 12 : cnt
    scale := A_ScreenDPI / 96.0

    padX := 18
    padY := 16
    headerH := 38
    gapX := 12
    gapY := 12
    WinHopperHeaderH := headerH

    if (WinHopperShowPreview) {
        cols := (maxShow <= 4) ? maxShow : (maxShow <= 8 ? 4 : 4)
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

    WinHopperCols := cols
    overlayW := padX * 2 + cols * tileW + (cols - 1) * gapX
    overlayH := padY + headerH + rows * tileH + (rows - 1) * gapY + padY
    WinHopperOverlayW := overlayW
    WinHopperOverlayH := overlayH

    ; Tính vị trí căn giữa màn hình chứa cửa sổ đang active
    mon := GetMonitorWorkAreaForHwnd(WinHopperWindows[1].hwnd)
    monW := Round((mon.right - mon.left) / scale)
    monH := Round((mon.bottom - mon.top) / scale)
    posX := Round(mon.left / scale) + Round((monW - overlayW) / 2)
    posY := Round(mon.top / scale) + Round((monH - overlayH) / 2)

    Gui, WinHopperGui:New, -Caption +ToolWindow +AlwaysOnTop +E0x08000000 +HwndhWinHopperGui
    Gui, WinHopperGui:Color, 202020
    Gui, WinHopperGui:Margin, 0, 0

    ; Bo góc & Dark Mode trên Windows 11
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hWinHopperGui, "UInt", 20, "Int*", 1, "UInt", 4) ; DWMWA_USE_IMMERSIVE_DARK_MODE
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hWinHopperGui, "UInt", 33, "Int*", 2, "UInt", 4) ; DWMWCP_ROUND

    ; Header: Tên ứng dụng & số lượng cửa sổ
    appName := GetWindowHopperAppDisplayName(WinHopperWindows[1].hwnd)
    countLabel := IsFunc("L") ? StrReplace(L("WH_WindowCount"), "{1}", cnt) : (cnt . " cửa sổ")
    escHint := IsFunc("L") ? L("WH_EscHint") : "Esc: Hủy"

    Gui, WinHopperGui:Font, s10.5 Bold cFFFFFF, Segoe UI
    Gui, WinHopperGui:Add, Text, % "x" . padX . " y14 w" . (overlayW - padX * 2 - 110) . " h22 +0x200 BackgroundTrans", % appName . "  (" . countLabel . ")"
    Gui, WinHopperGui:Font, s8.5 Norm c9A9A9A, Segoe UI
    Gui, WinHopperGui:Add, Text, % "x" . (overlayW - padX - 105) . " y16 w105 h20 Right +0x200 BackgroundTrans", % escHint

    WinHopperTileRects := []
    WinHopperTileCtrls := []
    WinHopperThumbIds := []

    Loop, %maxShow% {
        idx := A_Index
        item := WinHopperWindows[idx]
        colIdx := Mod(idx - 1, cols)
        rowIdx := Floor((idx - 1) / cols)

        tx := padX + colIdx * (tileW + gapX)
        ty := padY + headerH + rowIdx * (tileH + gapY)

        WinHopperTileRects.Push({ x: tx, y: ty, w: tileW, h: tileH })

        ; Tạo khung card bằng Progress/Text để đổi màu viền/nền mượt mà không cần vẽ lại toàn bộ
        Gui, WinHopperGui:Add, Text, x%tx% y%ty% w%tileW% h%tileH% +HwndhBorderCtrl Background2D2D2D
        inX := tx + 2, inY := ty + 2, inW := tileW - 4, inH := tileH - 4
        Gui, WinHopperGui:Add, Text, x%inX% y%inY% w%inW% h%inH% +HwndhBgCtrl Background2B2B2B

        shortTitle := item.title
        if (StrLen(shortTitle) > (WinHopperShowPreview ? 26 : 44))
            shortTitle := SubStr(shortTitle, 1, WinHopperShowPreview ? 25 : 43) . "…"

        if (WinHopperShowPreview) {
            Gui, WinHopperGui:Font, s8.5 Norm cEAEAEA, Segoe UI
            Gui, WinHopperGui:Add, Text, % "x" . (tx + 10) . " y" . (ty + 7) . " w" . (tileW - 20) . " h18 +0x200 +0x80 BackgroundTrans +HwndhTitleCtrl", % shortTitle
        } else {
            Gui, WinHopperGui:Font, s9.5 Norm cEAEAEA, Segoe UI
            Gui, WinHopperGui:Add, Text, % "x" . (tx + 12) . " y" . (ty + 9) . " w" . (tileW - 44) . " h22 +0x200 +0x80 BackgroundTrans +HwndhTitleCtrl", % shortTitle
            Gui, WinHopperGui:Font, s8.5 Bold c888888, Segoe UI
            Gui, WinHopperGui:Add, Text, % "x" . (tx + tileW - 30) . " y" . (ty + 10) . " w20 h20 Right +0x200 BackgroundTrans", % idx
        }

        WinHopperTileCtrls.Push({ border: hBorderCtrl, bg: hBgCtrl, title: hTitleCtrl })
    }

    Gui, WinHopperGui:Show, NoActivate x%posX% y%posY% w%overlayW% h%overlayH%, WindowHopperOverlay

    ; Đăng ký DWM Live Thumbnails sau khi cửa sổ overlay đã có HWND hiển thị
    if (WinHopperShowPreview) {
        Loop, %maxShow% {
            idx := A_Index
            rc := WinHopperTileRects[idx]
            thumbX := Round((rc.x + 8) * scale)
            thumbY := Round((rc.y + 30) * scale)
            thumbW := Round((rc.w - 16) * scale)
            thumbH := Round((rc.h - 38) * scale)
            tid := RegisterFittedDwmThumbnail(hWinHopperGui, WinHopperWindows[idx].hwnd, thumbX, thumbY, thumbW, thumbH)
            if (tid)
                WinHopperThumbIds.Push(tid)
        }
    }

    UpdateWinHopperSelectionVisual()
    OnMessage(0x0201, "OnWinHopperClick") ; WM_LBUTTONDOWN
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

UpdateWinHopperSelectionVisual() {
    global WinHopperTileCtrls, WinHopperSelectedIdx
    if (!IsObject(WinHopperTileCtrls))
        return

    accentRgb := IsFunc("GetWindowsAccentRgb") ? GetWindowsAccentRgb() : 0x0078D7
    accentHex := Format("{:06X}", accentRgb)

    for idx, ctrls in WinHopperTileCtrls {
        isSel := (idx = WinHopperSelectedIdx)
        borderColor := isSel ? accentHex : "383838"
        bgColor := isSel ? "353535" : "262626"
        GuiControl, +Background%borderColor%, % ctrls.border
        GuiControl, +Background%bgColor%, % ctrls.bg
        DllCall("RedrawWindow", "Ptr", ctrls.border, "Ptr", 0, "Ptr", 0, "UInt", 0x0105)
        DllCall("RedrawWindow", "Ptr", ctrls.bg, "Ptr", 0, "Ptr", 0, "UInt", 0x0105)
        DllCall("RedrawWindow", "Ptr", ctrls.title, "Ptr", 0, "Ptr", 0, "UInt", 0x0105)
    }
}

OnWinHopperClick(wParam, lParam, msg, hwnd) {
    global hWinHopperGui, WinHopperActive, WinHopperTileRects, WinHopperSelectedIdx
    if (!WinHopperActive || !hWinHopperGui)
        return
    if (hwnd != hWinHopperGui && !DllCall("IsChild", "Ptr", hWinHopperGui, "Ptr", hwnd))
        return

    ; Lấy tọa độ chuột theo client của hWinHopperGui
    VarSetCapacity(pt, 8, 0)
    DllCall("GetCursorPos", "Ptr", &pt)
    DllCall("ScreenToClient", "Ptr", hWinHopperGui, "Ptr", &pt)
    scale := A_ScreenDPI / 96.0
    cx := NumGet(pt, 0, "Int") / scale
    cy := NumGet(pt, 4, "Int") / scale

    for idx, rc in WinHopperTileRects {
        if (cx >= rc.x && cx <= (rc.x + rc.w) && cy >= rc.y && cy <= (rc.y + rc.h)) {
            WinHopperSelectedIdx := idx
            SetTimer, WinHopperCommitDeferred, -1
            return 0
        }
    }
}

WinHopperCommitDeferred:
    CommitWindowHopper()
return

CloseWindowHopperOverlay(clearState := true) {
    global WinHopperActive, WinHopperThumbIds, hWinHopperGui, WinHopperTileRects, WinHopperTileCtrls, WinHopperWindows

    SetTimer, WatchWinHopperModifier, Off
    OnMessage(0x0201, "OnWinHopperClick", 0)

    if (IsObject(WinHopperThumbIds)) {
        for _, tid in WinHopperThumbIds {
            if (tid)
                DllCall("dwmapi\DwmUnregisterThumbnail", "Ptr", tid)
        }
    }
    WinHopperThumbIds := []

    if (hWinHopperGui) {
        try Gui, WinHopperGui:Destroy
        hWinHopperGui := 0
    }

    WinHopperTileRects := []
    WinHopperTileCtrls := []
    if (clearState) {
        WinHopperActive := false
        WinHopperWindows := []
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

CleanupWindowHopper() {
    global WinHopperRegFwdHk, WinHopperRegBackHk
    CloseWindowHopperOverlay()
    if (WinHopperRegFwdHk != "")
        try Hotkey, %WinHopperRegFwdHk%, WinHopperForwardHandler, Off
    if (WinHopperRegBackHk != "")
        try Hotkey, %WinHopperRegBackHk%, WinHopperBackwardHandler, Off
}
