; AlwaysOnTop.ahk - Quản lý tính năng ghim cửa sổ luôn nổi (Always On Top) kèm viền mỏng
#NoEnv

; Khởi tạo module Always On Top
InitAlwaysOnTop() {
    global AOTEnabled, AOTHotkey, AOTBorderEnabled, AOTBorderColor, AOTBorderAlpha, AOTBorderThickness
    global AOTPinnedWindows, AOTGuiCounter, AOTWinEventHooks, AOTWinEventCallback

    AOTEnabled := 1
    AOTHotkey := "^!t" ; Mặc định: Ctrl + Alt + T
    AOTBorderEnabled := 1
    AOTBorderColor := "FFB900" ; Vàng cam mặc định
    AOTBorderAlpha := 185 ; Độ mờ viền (~72% opacity để rõ nét nhưng dịu mắt)
    AOTBorderThickness := Round(1.2 * (A_ScreenDPI / 96))
    if (AOTBorderThickness < 1)
        AOTBorderThickness := 1
    AOTPinnedWindows := {}
    AOTGuiCounter := 0
    AOTWinEventHooks := []
    AOTWinEventCallback := 0

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

    exStyle := GetWindowExStyle(hWnd)
    isTopmost := (exStyle & 0x8) != 0

    if (AOTPinnedWindows.HasKey(hWnd) && isTopmost) {
        UnpinAlwaysOnTopWindow(hWnd)
        ShowAOTFeedback(L("AOT_Unpinned"))
    } else {
        ; Dùng Win32 SetWindowPos với HWND_TOPMOST (-1)
        DllCall("SetWindowPos", "Ptr", hWnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0013) ; SWP_NOSIZE|SWP_NOMOVE|SWP_NOACTIVATE
        exStyleAfter := GetWindowExStyle(hWnd)
        if (!(exStyleAfter & 0x8)) {
            ShowAOTFeedback(L("AOT_AdminError"))
            return
        }

        if (!AOTPinnedWindows.HasKey(hWnd)) {
            AOTPinnedWindows[hWnd] := { borderName: "", borderHwnd: 0, x: -99999, y: -99999, w: 0, h: 0, visible: false, layeredInit: false }
        }
        StartAOTTracking()
        UpdateAOTBorderForWindow(hWnd)
        ShowAOTFeedback(L("AOT_Pinned"))
    }

    if (IsFunc("UpdateTrayTip"))
        UpdateTrayTip()
}

; Lấy ExStyle trực tiếp qua Win32 API (không phụ thuộc DetectHiddenWindows)
GetWindowExStyle(hWnd) {
    if (A_PtrSize = 8)
        return DllCall("GetWindowLongPtr", "Ptr", hWnd, "Int", -20, "Ptr")
    return DllCall("GetWindowLong", "Ptr", hWnd, "Int", -20, "Int")
}

; Kiểm tra cửa sổ có hợp lệ để ghim không (loại trừ cửa sổ hệ thống và GUI nội bộ)
IsAOTAllowedWindow(hWnd) {
    if (!hWnd || !DllCall("IsWindow", "Ptr", hWnd))
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

; Đăng ký Win32 SetWinEventHook để bám cửa sổ tức thì (di chuyển, đổi focus, thu nhỏ, đóng)
StartAOTTracking() {
    global AOTWinEventHooks, AOTWinEventCallback

    if (!AOTWinEventCallback)
        AOTWinEventCallback := RegisterCallback("AOTWinEventProc", "F")

    if (!AOTWinEventHooks.Length() && AOTWinEventCallback) {
        ; Hook 1: EVENT_SYSTEM_FOREGROUND (0x0003) -> EVENT_SYSTEM_MINIMIZEEND (0x0017)
        h1 := DllCall("SetWinEventHook", "UInt", 0x0003, "UInt", 0x0017, "Ptr", 0, "Ptr", AOTWinEventCallback, "UInt", 0, "UInt", 0, "UInt", 0, "Ptr")
        ; Hook 2: EVENT_OBJECT_DESTROY (0x8001) -> EVENT_OBJECT_LOCATIONCHANGE (0x800B)
        h2 := DllCall("SetWinEventHook", "UInt", 0x8001, "UInt", 0x800B, "Ptr", 0, "Ptr", AOTWinEventCallback, "UInt", 0, "UInt", 0, "UInt", 0, "Ptr")
        if (h1)
            AOTWinEventHooks.Push(h1)
        if (h2)
            AOTWinEventHooks.Push(h2)
    }

    ; Timer dự phòng nhẹ (120ms) để giữ trạng thái TOPMOST nếu ứng dụng tự gỡ khi mất focus
    SetTimer, AOTSyncTimer, 120
}

StopAOTTracking() {
    global AOTWinEventHooks
    SetTimer, AOTSyncTimer, Off
    for _, hHook in AOTWinEventHooks {
        if (hHook)
            DllCall("UnhookWinEvent", "Ptr", hHook)
    }
    AOTWinEventHooks := []
}

AOTWinEventProc(hWinEventHook, event, hWnd, idObject, idChild, dwEventThread, dwmsEventTime) {
    global AOTPinnedWindows
    if (!AOTPinnedWindows.Count())
        return

    ; Chỉ xử lý sự kiện cấp cửa sổ (OBJID_WINDOW = 0) hoặc sự kiện hệ thống
    if (event >= 0x8000 && idObject != 0)
        return

    if (event = 0x0003) { ; EVENT_SYSTEM_FOREGROUND: cửa sổ active thay đổi
        SetTimer, AOTSyncSoonTimer, -15
        return
    }

    hWnd := hWnd + 0
    if (AOTPinnedWindows.HasKey(hWnd)) {
        if (event = 0x8001) { ; EVENT_OBJECT_DESTROY
            SetTimer, AOTSyncSoonTimer, -10
        } else {
            UpdateAOTBorderForWindow(hWnd)
        }
    }
}

AOTSyncSoonTimer:
    SyncAllAOTBorders()
return

; Gỡ ghim một cửa sổ cụ thể và hủy viền của nó
UnpinAlwaysOnTopWindow(hWnd) {
    global AOTPinnedWindows
    hWnd := hWnd + 0
    if (DllCall("IsWindow", "Ptr", hWnd))
        DllCall("SetWindowPos", "Ptr", hWnd, "Ptr", -2, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0013) ; HWND_NOTOPMOST (-2)
    if (AOTPinnedWindows.HasKey(hWnd)) {
        DestroyAOTBorderGui(AOTPinnedWindows[hWnd])
        AOTPinnedWindows.Delete(hWnd)
    }
    if (!AOTPinnedWindows.Count())
        StopAOTTracking()
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
    StopAOTTracking()
    return 0
}

; Đồng bộ vị trí, trạng thái hiển thị, chống mất TOPMOST và giữ Z-order của viền
AOTSyncTimer:
    SyncAllAOTBorders()
return

SyncAllAOTBorders() {
    global AOTPinnedWindows
    if (!AOTPinnedWindows.Count()) {
        StopAOTTracking()
        return
    }

    hActive := WinExist("A") + 0
    toRemove := []

    for hWnd, info in AOTPinnedWindows {
        if (!DllCall("IsWindow", "Ptr", hWnd)) {
            toRemove.Push(hWnd)
            continue
        }

        ; Chống mất Always On Top khi một số ứng dụng tự hạ cờ WS_EX_TOPMOST khi đổi focus
        if (!(GetWindowExStyle(hWnd) & 0x8)) {
            DllCall("SetWindowPos", "Ptr", hWnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0013)
        }

        UpdateAOTBorderForWindow(hWnd)
    }

    ; Nếu cửa sổ đang active cũng là cửa sổ được ghim, đảm bảo nó nổi trên các cửa sổ ghim khác
    if (hActive && AOTPinnedWindows.HasKey(hActive)) {
        DllCall("SetWindowPos", "Ptr", hActive, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0013)
        UpdateAOTBorderForWindow(hActive)
    }

    for _, hWnd in toRemove {
        if (AOTPinnedWindows.HasKey(hWnd)) {
            DestroyAOTBorderGui(AOTPinnedWindows[hWnd])
            AOTPinnedWindows.Delete(hWnd)
        }
    }

    if (!AOTPinnedWindows.Count()) {
        StopAOTTracking()
        if (IsFunc("UpdateTrayTip"))
            UpdateTrayTip()
    }
}

; Cập nhật viền cho 1 cửa sổ cụ thể
UpdateAOTBorderForWindow(hWnd) {
    global AOTPinnedWindows, AOTBorderEnabled, AOTBorderColor, AOTBorderAlpha, AOTBorderThickness, AOTGuiCounter

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
    if (!GetAOTWindowBounds(hWnd, wx, wy, ww, wh) || ww <= 0 || wh <= 0) {
        HideAOTBorderGui(info)
        return
    }

    ; Ẩn viền khi cửa sổ đang ở chế độ Fullscreen
    if (IsAOTWindowFullscreen(hWnd, wx, wy, ww, wh)) {
        HideAOTBorderGui(info)
        return
    }

    ; Vẽ viền bao sát ra ngoài mép cửa sổ 1px để không bị mép DWM che mất
    t := AOTBorderThickness
    bx := wx - t
    by := wy - t
    bw := ww + (t * 2)
    bh := wh + (t * 2)

    ; Tạo GUI viền nếu chưa có (-DPIScale để khớp pixel thực, +E0x80000 WS_EX_LAYERED để làm mờ)
    if (!info.borderHwnd || !DllCall("IsWindow", "Ptr", info.borderHwnd)) {
        AOTGuiCounter++
        guiName := "AOTBorder_" . AOTGuiCounter
        Gui, %guiName%:New, +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x20 +E0x80000 +E0x08000000 +HwndhBorder
        Gui, %guiName%:Color, %AOTBorderColor%
        Gui, %guiName%:Show, NoActivate Hide x%bx% y%by% w%bw% h%bh%
        info.borderName := guiName
        info.borderHwnd := hBorder
        info.x := -99999
        info.y := -99999
        info.w := 0
        info.h := 0
        info.visible := false
        info.layeredInit := false
    }

    hBorder := info.borderHwnd
    sizeChanged := (bw != info.w || bh != info.h)
    posChanged := (bx != info.x || by != info.y || sizeChanged || !info.visible)

    ; Cập nhật vùng rỗng ở giữa bằng Win32 Region (RGN_DIFF)
    if (sizeChanged) {
        if (bw > t * 2 && bh > t * 2) {
            hOuter := DllCall("CreateRectRgn", "Int", 0, "Int", 0, "Int", bw, "Int", bh, "Ptr")
            hInner := DllCall("CreateRectRgn", "Int", t, "Int", t, "Int", bw - t, "Int", bh - t, "Ptr")
            DllCall("CombineRgn", "Ptr", hOuter, "Ptr", hOuter, "Ptr", hInner, "Int", 4) ; RGN_DIFF = 4
            DllCall("DeleteObject", "Ptr", hInner)
            DllCall("SetWindowRgn", "Ptr", hBorder, "Ptr", hOuter, "Int", 1)
        }
    }

    ; Tìm cửa sổ hiển thị gần nhất nằm ngay trên hWnd để đặt viền theo đúng Z-order
    insertAfter := GetAOTInsertAfterHwnd(hWnd, hBorder)
    hImmediatePrev := DllCall("GetWindow", "Ptr", hWnd, "UInt", 3, "Ptr")
    zNeedsUpdate := (hImmediatePrev != hBorder)

    if (posChanged || zNeedsUpdate) {
        ; SWP_NOACTIVATE (0x10) | SWP_SHOWWINDOW (0x40)
        ok := DllCall("SetWindowPos", "Ptr", hBorder, "Ptr", insertAfter, "Int", bx, "Int", by, "Int", bw, "Int", bh, "UInt", 0x0050)
        if (!ok && insertAfter != -1) {
            ok := DllCall("SetWindowPos", "Ptr", hBorder, "Ptr", -1, "Int", bx, "Int", by, "Int", bw, "Int", bh, "UInt", 0x0050)
        }
        if (ok) {
            if (!info.layeredInit) {
                DllCall("SetLayeredWindowAttributes", "Ptr", hBorder, "UInt", 0, "UChar", AOTBorderAlpha, "UInt", 2)
                info.layeredInit := true
            }
            info.x := bx
            info.y := by
            info.w := bw
            info.h := bh
            info.visible := true
        }
    }
}

; Tìm HWND tham chiếu để đặt viền nằm ngay phía trên hWnd trong Z-order
GetAOTInsertAfterHwnd(hWnd, hBorder) {
    curr := hWnd
    Loop, 20 {
        prev := DllCall("GetWindow", "Ptr", curr, "UInt", 3, "Ptr") ; GW_HWNDPREV = 3
        if (!prev)
            return -1 ; HWND_TOPMOST
        if (prev != hBorder && DllCall("IsWindowVisible", "Ptr", prev)) {
            if (GetWindowExStyle(prev) & 0x8)
                return prev
            return -1
        }
        curr := prev
    }
    return -1
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

    return (bx <= monLeft + 1 && by <= monTop + 1 && (bx + bw) >= monRight - 1 && (by + bh) >= monBottom - 1)
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
        info.layeredInit := false
    }
}

; Cập nhật hiển thị viền cho tất cả cửa sổ đang ghim khi bật/tắt tùy chọn viền trong Settings
RefreshAllAOTBorders() {
    global AOTPinnedWindows
    for hWnd in AOTPinnedWindows
        UpdateAOTBorderForWindow(hWnd)
}

; Chuyển đổi chuỗi phím tắt AHK (vd: ^!t) sang dạng dễ đọc (Ctrl + Alt + T)
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
