; AlwaysOnTop.ahk - Quản lý tính năng ghim cửa sổ luôn nổi (Always On Top) kèm viền mỏng
#NoEnv

; Khởi tạo module Always On Top
InitAlwaysOnTop() {
    global AOTEnabled, AOTHotkey, AOTBorderEnabled, AOTBorderColor, AOTBorderThickness
    global AOTPinnedWindows, AOTGuiCounter

    AOTEnabled := 1
    AOTHotkey := "#^t" ; Mặc định: Win + Ctrl + T
    AOTBorderEnabled := 1
    AOTBorderColor := "FFB900" ; Vàng cam mặc định
    AOTBorderThickness := Round(3 * (A_ScreenDPI / 96))
    if (AOTBorderThickness < 2)
        AOTBorderThickness := 2
    AOTPinnedWindows := {}
    AOTGuiCounter := 0

    RegRead, valEnabled, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AOTEnabled
    if (!ErrorLevel && valEnabled != "")
        AOTEnabled := valEnabled ? 1 : 0

    RegRead, valHotkey, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AOTHotkey
    if (!ErrorLevel && valHotkey != "")
        AOTHotkey := valHotkey

    RegRead, valBorder, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AOTBorderEnabled
    if (!ErrorLevel && valBorder != "")
        AOTBorderEnabled := valBorder ? 1 : 0

    ApplyAOTHotkey()
    OnExit("CleanupAlwaysOnTop")
}

; Đăng ký hoặc hủy đăng ký phím tắt Always On Top
ApplyAOTHotkey() {
    global AOTEnabled, AOTHotkey
    static registeredHotkey := ""

    if (registeredHotkey != "") {
        try Hotkey, %registeredHotkey%, ToggleAlwaysOnTopLabel, Off
        registeredHotkey := ""
    }

    if (AOTEnabled && AOTHotkey != "") {
        try {
            Hotkey, %AOTHotkey%, ToggleAlwaysOnTopLabel, On
            registeredHotkey := AOTHotkey
        }
    }
}

ToggleAlwaysOnTopLabel:
    ToggleAlwaysOnTop()
return

; Bật/Tắt ghim Always On Top cho cửa sổ đang active (hoặc hWnd chỉ định)
ToggleAlwaysOnTop(hWnd := 0) {
    global AOTEnabled, AOTPinnedWindows

    if (!AOTEnabled)
        return

    if (!hWnd)
        hWnd := WinExist("A")
    hWnd := hWnd + 0
    if (!hWnd || !IsAOTAllowedWindow(hWnd))
        return

    WinGet, exStyle, ExStyle, ahk_id %hWnd%
    isTopmost := (exStyle & 0x8) != 0

    if (AOTPinnedWindows.HasKey(hWnd) && isTopmost) {
        UnpinAlwaysOnTopWindow(hWnd)
        ShowAOTFeedback(L("AOT_Unpinned"))
    } else {
        WinSet, AlwaysOnTop, On, ahk_id %hWnd%
        WinGet, exStyleAfter, ExStyle, ahk_id %hWnd%
        if (!(exStyleAfter & 0x8)) {
            ShowAOTFeedback(L("AOT_AdminError"))
            return
        }

        if (!AOTPinnedWindows.HasKey(hWnd)) {
            AOTPinnedWindows[hWnd] := { borderName: "", borderHwnd: 0, x: -99999, y: -99999, w: 0, h: 0, visible: false }
        }
        UpdateAOTBorderForWindow(hWnd)
        SetTimer, AOTSyncTimer, 25
        ShowAOTFeedback(L("AOT_Pinned"))
    }

    if (IsFunc("UpdateTrayTip"))
        UpdateTrayTip()
}

; Kiểm tra cửa sổ có hợp lệ để ghim không (loại trừ cửa sổ hệ thống và GUI nội bộ)
IsAOTAllowedWindow(hWnd) {
    if (!hWnd || !WinExist("ahk_id " . hWnd))
        return false

    WinGet, winPid, PID, ahk_id %hWnd%
    if (winPid = DllCall("GetCurrentProcessId", "UInt"))
        return false

    WinGetClass, winClass, ahk_id %hWnd%
    static blockedClasses := { "Progman": 1
        , "WorkerW": 1
        , "Shell_TrayWnd": 1
        , "Shell_SecondaryTrayWnd": 1
        , "Windows.UI.Core.CoreWindow": 1
        , "MultitaskingViewFrame": 1
        , "TaskListThumbnailWnd": 1
        , "NotifyIconOverflowWindow": 1
        , "#32768": 1
        , "tooltips_class32": 1 }

    if (blockedClasses.HasKey(winClass))
        return false

    return true
}

; Gỡ ghim một cửa sổ cụ thể và hủy viền của nó
UnpinAlwaysOnTopWindow(hWnd) {
    global AOTPinnedWindows
    hWnd := hWnd + 0
    if (WinExist("ahk_id " . hWnd))
        WinSet, AlwaysOnTop, Off, ahk_id %hWnd%
    if (AOTPinnedWindows.HasKey(hWnd)) {
        DestroyAOTBorderGui(AOTPinnedWindows[hWnd])
        AOTPinnedWindows.Delete(hWnd)
    }
    if (!AOTPinnedWindows.Count())
        SetTimer, AOTSyncTimer, Off
}

; Gỡ ghim tất cả cửa sổ đang ghim
UnpinAllAlwaysOnTop() {
    global AOTPinnedWindows
    keys := []
    for hWnd in AOTPinnedWindows
        keys.Push(hWnd)
    for _, hWnd in keys
        UnpinAlwaysOnTopWindow(hWnd)
    if (IsFunc("UpdateTrayTip"))
        UpdateTrayTip()
}

; Dọn dẹp khi thoát GestureMouse: gỡ Always On Top cho mọi cửa sổ đã ghim
CleanupAlwaysOnTop() {
    UnpinAllAlwaysOnTop()
    return 0
}

; Đồng bộ vị trí, trạng thái hiển thị và Z-order của viền cho các cửa sổ đang ghim
AOTSyncTimer:
    SyncAllAOTBorders()
return

SyncAllAOTBorders() {
    global AOTPinnedWindows
    if (!AOTPinnedWindows.Count()) {
        SetTimer, AOTSyncTimer, Off
        return
    }

    toRemove := []
    for hWnd, info in AOTPinnedWindows {
        if (!WinExist("ahk_id " . hWnd)) {
            toRemove.Push(hWnd)
            continue
        }
        UpdateAOTBorderForWindow(hWnd)
    }

    for _, hWnd in toRemove {
        if (AOTPinnedWindows.HasKey(hWnd)) {
            DestroyAOTBorderGui(AOTPinnedWindows[hWnd])
            AOTPinnedWindows.Delete(hWnd)
        }
    }

    if (!AOTPinnedWindows.Count()) {
        SetTimer, AOTSyncTimer, Off
        if (IsFunc("UpdateTrayTip"))
            UpdateTrayTip()
    }
}

; Cập nhật viền cho 1 cửa sổ cụ thể
UpdateAOTBorderForWindow(hWnd) {
    global AOTPinnedWindows, AOTBorderEnabled, AOTBorderColor, AOTBorderThickness, AOTGuiCounter

    info := AOTPinnedWindows[hWnd]
    if (!info)
        return

    if (!AOTBorderEnabled) {
        HideAOTBorderGui(info)
        return
    }

    ; Ẩn viền nếu cửa sổ đang thu nhỏ, bị ẩn hoặc bị cloaked (Virtual Desktop khác)
    WinGet, minMax, MinMax, ahk_id %hWnd%
    if (minMax = -1 || !DllCall("IsWindowVisible", "Ptr", hWnd)) {
        HideAOTBorderGui(info)
        return
    }
    cloaked := 0
    DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hWnd, "UInt", 14, "UInt*", cloaked, "UInt", 4)
    if (cloaked) {
        HideAOTBorderGui(info)
        return
    }

    ; Lấy khung hiển thị thực tế (bỏ qua bóng mờ vô hình của Win 10/11)
    if (!GetAOTWindowBounds(hWnd, bx, by, bw, bh) || bw <= 0 || bh <= 0) {
        HideAOTBorderGui(info)
        return
    }

    ; Ẩn viền khi cửa sổ đang ở chế độ Fullscreen
    if (IsAOTWindowFullscreen(hWnd, bx, by, bw, bh)) {
        HideAOTBorderGui(info)
        return
    }

    ; Tạo GUI viền nếu chưa có
    if (!info.borderHwnd || !WinExist("ahk_id " . info.borderHwnd)) {
        AOTGuiCounter++
        guiName := "AOTBorder_" . AOTGuiCounter
        Gui, %guiName%:New, +AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x08000000 +HwndhBorder
        Gui, %guiName%:Color, %AOTBorderColor%
        Gui, %guiName%:Show, NoActivate Hide x%bx% y%by% w%bw% h%bh%
        info.borderName := guiName
        info.borderHwnd := hBorder
        info.x := -99999
        info.y := -99999
        info.w := 0
        info.h := 0
        info.visible := false
    }

    hBorder := info.borderHwnd
    sizeChanged := (bw != info.w || bh != info.h)
    posChanged := (bx != info.x || by != info.y || sizeChanged || !info.visible)

    ; Cập nhật vùng rỗng ở giữa để tạo thành viền mỏng
    if (sizeChanged) {
        t := AOTBorderThickness
        ix := t
        iy := t
        iw := bw - t
        ih := bh - t
        if (iw > ix && ih > iy) {
            regionStr := "0-0 " . bw . "-0 " . bw . "-" . bh . " 0-" . bh . " 0-0 "
                . ix . "-" . iy . " " . iw . "-" . iy . " " . iw . "-" . ih . " " . ix . "-" . ih . " " . ix . "-" . iy
            WinSet, Region, %regionStr%, ahk_id %hBorder%
        }
    }

    ; Giữ Z-order của viền nằm ngay trên cửa sổ được ghim (để cửa sổ ghim khác khi active sẽ nổi đè lên)
    hPrev := DllCall("GetWindow", "Ptr", hWnd, "UInt", 3, "Ptr") ; GW_HWNDPREV = 3
    zNeedsUpdate := (hPrev != hBorder)

    if (posChanged || zNeedsUpdate) {
        insertAfter := (hPrev = 0 || hPrev = hBorder) ? -1 : hPrev ; -1 = HWND_TOPMOST
        ; SWP_NOACTIVATE (0x10) | SWP_SHOWWINDOW (0x40)
        DllCall("SetWindowPos", "Ptr", hBorder, "Ptr", insertAfter, "Int", bx, "Int", by, "Int", bw, "Int", bh, "UInt", 0x0050)
        info.x := bx
        info.y := by
        info.w := bw
        info.h := bh
        info.visible := true
    }
}

; Lấy tọa độ hiển thị thực tế qua DWMWA_EXTENDED_FRAME_BOUNDS (fallback sang GetWindowRect)
GetAOTWindowBounds(hWnd, ByRef x, ByRef y, ByRef w, ByRef h) {
    VarSetCapacity(rect, 16, 0)
    hr := DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hWnd, "UInt", 9, "Ptr", &rect, "UInt", 16)
    if (hr != 0) {
        if (!DllCall("GetWindowRect", "Ptr", hWnd, "Ptr", &rect))
            return false
    }
    left := NumGet(rect, 0, "Int")
    top := NumGet(rect, 4, "Int")
    right := NumGet(rect, 8, "Int")
    bottom := NumGet(rect, 12, "Int")
    x := left
    y := top
    w := right - left
    h := bottom - top
    return true
}

; Kiểm tra cửa sổ có đang phủ toàn màn hình (Fullscreen) không
IsAOTWindowFullscreen(hWnd, bx, by, bw, bh) {
    hMon := DllCall("MonitorFromWindow", "Ptr", hWnd, "UInt", 2, "Ptr") ; MONITOR_DEFAULTTONEAREST = 2
    if (!hMon)
        return false

    VarSetCapacity(mi, 40, 0)
    NumPut(40, mi, 0, "UInt")
    if (!DllCall("GetMonitorInfo", "Ptr", hMon, "Ptr", &mi))
        return false

    monLeft   := NumGet(mi, 4, "Int")
    monTop    := NumGet(mi, 8, "Int")
    monRight  := NumGet(mi, 12, "Int")
    monBottom := NumGet(mi, 16, "Int")

    ; Cho phép sai số 1px do DPI scaling
    coversMonitor := (bx <= monLeft + 1 && by <= monTop + 1 && (bx + bw) >= monRight - 1 && (by + bh) >= monBottom - 1)
    if (!coversMonitor)
        return false

    ; Nếu là cửa sổ Maximized bình thường vẫn có tiêu đề/viền hoặc không phủ Taskbar -> chỉ coi là Fullscreen khi phủ trọn monitor rect
    return true
}

HideAOTBorderGui(info) {
    if (info && info.visible && info.borderHwnd) {
        DllCall("ShowWindow", "Ptr", info.borderHwnd, "Int", 0) ; SW_HIDE
        info.visible := false
    }
}

DestroyAOTBorderGui(info) {
    if (info && info.borderName != "") {
        guiName := info.borderName
        try Gui, %guiName%:Destroy
        info.borderName := ""
        info.borderHwnd := 0
        info.visible := false
    }
}

; Cập nhật hiển thị viền cho tất cả cửa sổ đang ghim khi bật/tắt tùy chọn viền trong Settings
RefreshAllAOTBorders() {
    global AOTPinnedWindows
    for hWnd in AOTPinnedWindows
        UpdateAOTBorderForWindow(hWnd)
}

; Chuyển đổi chuỗi phím tắt AHK (vd: #^t) sang dạng dễ đọc (Win + Ctrl + T)
FormatAOTHotkeyText(hk) {
    if (hk = "")
        return L("AOT_NoHotkey")
    res := ""
    if (InStr(hk, "#"))
        res .= "Win + "
    if (InStr(hk, "^"))
        res .= "Ctrl + "
    if (InStr(hk, "!"))
        res .= "Alt + "
    if (InStr(hk, "+"))
        res .= "Shift + "
    keyPart := RegExReplace(hk, "[#^!+]", "")
    StringUpper, keyPart, keyPart
    return res . keyPart
}

; Hiển thị thông báo nhanh khi ghim / bỏ ghim
ShowAOTFeedback(msg) {
    ToolTip, %msg%
    SetTimer, HideAOTFeedbackTimer, -1200
}

HideAOTFeedbackTimer:
    ToolTip
return
