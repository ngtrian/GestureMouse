; AlwaysOnTop.ahk - Quản lý tính năng ghim cửa sổ luôn nổi (Always On Top) kèm viền GDI+ bo góc
#NoEnv

; Khởi tạo module Always On Top
InitAlwaysOnTop() {
    global AOTEnabled, AOTHotkey, AOTBorderEnabled, AOTBorderAlpha, AOTBorderThickness
    global AOTPinnedWindows, AOTGuiCounter, AOTWinEventHooks, AOTWinEventCallback
    global AOTGdipModule, AOTGdipToken, AOTLastSyncTick, AOTSyncPending

    AOTEnabled := 1
    AOTHotkey := "^!t" ; Mặc định: Ctrl + Alt + T
    AOTBorderEnabled := 1
    AOTBorderAlpha := 165 ; Độ mờ dịu (~65% opacity) cho nét vẽ 1px khử răng cưa
    AOTBorderThickness := 1.2 ; Viền siêu mảnh ~1px
    AOTPinnedWindows := {}
    AOTGuiCounter := 0
    AOTWinEventHooks := []
    AOTWinEventCallback := 0
    AOTGdipModule := 0
    AOTGdipToken := 0
    AOTLastSyncTick := 0
    AOTSyncPending := false

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

; Lấy màu Accent hiện tại của Windows (fallback sang vàng cam #FFB900)
GetWindowsAccentRgb() {
    RegRead, accentAbgr, HKEY_CURRENT_USER\Software\Microsoft\Windows\DWM, AccentColor
    if (!ErrorLevel && accentAbgr != "") {
        r := accentAbgr & 0xFF
        g := (accentAbgr >> 8) & 0xFF
        b := (accentAbgr >> 16) & 0xFF
        return (r << 16) | (g << 8) | b
    }
    RegRead, colorArgb, HKEY_CURRENT_USER\Software\Microsoft\Windows\DWM, ColorizationColor
    if (!ErrorLevel && colorArgb != "")
        return colorArgb & 0xFFFFFF
    return 0xFFB900
}

; Khởi tạo/giải phóng phiên GDI+ dùng cho vẽ viền bo góc
EnsureAOTGdip() {
    global AOTGdipModule, AOTGdipToken
    if (AOTGdipToken)
        return true
    return GdipBeginSession(AOTGdipModule, AOTGdipToken)
}

ReleaseAOTGdip() {
    global AOTGdipModule, AOTGdipToken
    if (AOTGdipToken || AOTGdipModule) {
        GdipEndSession(AOTGdipModule, AOTGdipToken)
        AOTGdipModule := 0
        AOTGdipToken := 0
    }
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

    exStyle := GetWindowLongPtrCompat(hWnd, -20) ; GWL_EXSTYLE
    isTopmost := (exStyle & 0x8) != 0

    if (AOTPinnedWindows.HasKey(hWnd) && isTopmost) {
        UnpinAlwaysOnTopWindow(hWnd)
    } else {
        DllCall("SetWindowPos", "Ptr", hWnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0013) ; SWP_NOSIZE|SWP_NOMOVE|SWP_NOACTIVATE
        exStyleAfter := GetWindowLongPtrCompat(hWnd, -20)
        if (!(exStyleAfter & 0x8)) {
            ShowAOTFeedback(L("AOT_AdminError"))
            return
        }

        if (!AOTPinnedWindows.HasKey(hWnd)) {
            AOTPinnedWindows[hWnd] := { borderName: "", borderHwnd: 0, x: -99999, y: -99999, w: 0, h: 0, visible: false, clipKey: "", accentRgb: -1, forceZ: false }
        }
        StartAOTTracking()
        SyncAllAOTBorders()
    }

    if (IsFunc("UpdateTrayTip"))
        UpdateTrayTip()
}

; Lấy GWL_STYLE (-16) hoặc GWL_EXSTYLE (-20) trực tiếp qua Win32 API
GetWindowLongPtrCompat(hWnd, idx) {
    if (A_PtrSize = 8)
        return DllCall("GetWindowLongPtr", "Ptr", hWnd, "Int", idx, "Ptr")
    return DllCall("GetWindowLong", "Ptr", hWnd, "Int", idx, "Int")
}

; Kiểm tra cửa sổ có hợp lệ để ghim không (loại trừ cửa sổ con, hệ thống, kích thước 0 và GUI nội bộ)
IsAOTAllowedWindow(hWnd) {
    if (!hWnd || !DllCall("IsWindow", "Ptr", hWnd))
        return false

    WinGet, winPid, PID, ahk_id %hWnd%
    if (winPid = DllCall("GetCurrentProcessId", "UInt"))
        return false

    ; Bỏ qua cửa sổ con (WS_CHILD = 0x40000000)
    if (GetWindowLongPtrCompat(hWnd, -16) & 0x40000000)
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

    if (!GetAOTWindowBounds(hWnd, wx, wy, ww, wh) || ww <= 0 || wh <= 0)
        return false

    return true
}

; Đăng ký Win32 SetWinEventHook thu hẹp đúng các sự kiện cần thiết
StartAOTTracking() {
    global AOTWinEventHooks, AOTWinEventCallback

    if (!AOTWinEventCallback)
        AOTWinEventCallback := RegisterCallback("AOTWinEventProc")

    if (!AOTWinEventHooks.Length() && AOTWinEventCallback) {
        ; Hook đúng 4 sự kiện: Foreground (0x0003), Minimize (0x0016-0x0017), Destroy (0x8001), LocationChange (0x800B)
        h1 := DllCall("SetWinEventHook", "UInt", 0x0003, "UInt", 0x0003, "Ptr", 0, "Ptr", AOTWinEventCallback, "UInt", 0, "UInt", 0, "UInt", 0, "Ptr")
        h2 := DllCall("SetWinEventHook", "UInt", 0x0016, "UInt", 0x0017, "Ptr", 0, "Ptr", AOTWinEventCallback, "UInt", 0, "UInt", 0, "UInt", 0, "Ptr")
        h3 := DllCall("SetWinEventHook", "UInt", 0x8001, "UInt", 0x8001, "Ptr", 0, "Ptr", AOTWinEventCallback, "UInt", 0, "UInt", 0, "UInt", 0, "Ptr")
        h4 := DllCall("SetWinEventHook", "UInt", 0x800B, "UInt", 0x800B, "Ptr", 0, "Ptr", AOTWinEventCallback, "UInt", 0, "UInt", 0, "UInt", 0, "Ptr")
        for _, hHook in [h1, h2, h3, h4] {
            if (hHook)
                AOTWinEventHooks.Push(hHook)
        }
    }

    SetTimer, AOTSyncTimer, 150
}

StopAOTTracking() {
    global AOTWinEventHooks, AOTSyncPending
    SetTimer, AOTSyncTimer, Off
    SetTimer, AOTSyncSoonTimer, Off
    AOTSyncPending := false
    for _, hHook in AOTWinEventHooks {
        if (hHook)
            DllCall("UnhookWinEvent", "Ptr", hHook)
    }
    AOTWinEventHooks := []
}

AOTWinEventProc(hWinEventHook, event, hWnd, idObject, idChild, dwEventThread, dwmsEventTime) {
    global AOTPinnedWindows, AOTLastSyncTick, AOTSyncPending

    if (event >= 0x8000 && idObject != 0)
        return
    if (!AOTPinnedWindows.Count())
        return

    if (event = 0x0003 || event = 0x0016 || event = 0x0017) {
        ScheduleAOTSync(15)
        return
    }

    hWnd := hWnd + 0
    if (!AOTPinnedWindows.HasKey(hWnd))
        return

    if (event = 0x800B) { ; EVENT_OBJECT_LOCATIONCHANGE
        ; Nếu chỉ có 1 cửa sổ ghim và chỉ đổi vị trí (kéo), di chuyển viền ngay không qua timer
        if (AOTPinnedWindows.Count() = 1 && TryFastMoveSingleAOTBorder(hWnd))
            return
        ; Nhiều cửa sổ ghim hoặc đổi kích thước: throttle ~60 FPS (16ms)
        elapsed := A_TickCount - AOTLastSyncTick
        if (elapsed >= 16)
            SyncAllAOTBorders()
        else
            ScheduleAOTSync(16 - elapsed)
    } else if (event = 0x8001) { ; EVENT_OBJECT_DESTROY
        ScheduleAOTSync(10)
    }
}

ScheduleAOTSync(delayMs) {
    global AOTSyncPending
    if (AOTSyncPending)
        return
    AOTSyncPending := true
    SetTimer, AOTSyncSoonTimer, % -delayMs
}

AOTSyncSoonTimer:
    AOTSyncPending := false
    SyncAllAOTBorders()
return

; Đường nhanh: chỉ dịch chuyển tọa độ (x, y) của viền khi kéo 1 cửa sổ mà kích thước giữ nguyên
TryFastMoveSingleAOTBorder(hWnd) {
    global AOTPinnedWindows, AOTBorderEnabled
    if (!AOTBorderEnabled)
        return false
    info := AOTPinnedWindows[hWnd]
    if (!info || !info.visible || !info.borderHwnd || !DllCall("IsWindow", "Ptr", info.borderHwnd))
        return false
    if (!GetAOTWindowBounds(hWnd, wx, wy, ww, wh) || ww <= 0 || wh <= 0)
        return false
    pad := 1
    bx := wx - pad
    by := wy - pad
    bw := ww + (pad * 2)
    bh := wh + (pad * 2)
    if (bw != info.w || bh != info.h)
        return false
    if (bx != info.x || by != info.y) {
        DllCall("SetWindowPos", "Ptr", info.borderHwnd, "Ptr", 0, "Int", bx, "Int", by, "Int", 0, "Int", 0, "UInt", 0x0055)
        info.x := bx
        info.y := by
    }
    return true
}

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
    if (!AOTPinnedWindows.Count()) {
        StopAOTTracking()
        ReleaseAOTGdip()
    } else {
        SyncAllAOTBorders()
    }
}

; Gỡ ghim tất cả cửa sổ đang ghim
UnpinAllAlwaysOnTop() {
    global AOTPinnedWindows
    keys := []
    for hWnd in AOTPinnedWindows
        keys.Push(hWnd)
    for _, hWnd in keys {
        hWnd := hWnd + 0
        if (DllCall("IsWindow", "Ptr", hWnd))
            DllCall("SetWindowPos", "Ptr", hWnd, "Ptr", -2, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0013)
        if (AOTPinnedWindows.HasKey(hWnd)) {
            DestroyAOTBorderGui(AOTPinnedWindows[hWnd])
            AOTPinnedWindows.Delete(hWnd)
        }
    }
    StopAOTTracking()
    ReleaseAOTGdip()
    if (IsFunc("UpdateTrayTip"))
        UpdateTrayTip()
}

; Dọn dẹp khi thoát GestureMouse: gỡ Always On Top cho mọi cửa sổ đã ghim
CleanupAlwaysOnTop() {
    UnpinAllAlwaysOnTop()
    return 0
}

; Đồng bộ vị trí, trạng thái hiển thị, chống mất TOPMOST và cắt vùng viền bị che theo Z-order
AOTSyncTimer:
    SyncAllAOTBorders()
return

SyncAllAOTBorders() {
    global AOTPinnedWindows, AOTLastSyncTick, AOTSyncPending
    AOTSyncPending := false
    AOTLastSyncTick := A_TickCount

    if (!AOTPinnedWindows.Count()) {
        StopAOTTracking()
        return
    }

    toRemove := []
    for hWnd, info in AOTPinnedWindows {
        if (!DllCall("IsWindow", "Ptr", hWnd)) {
            toRemove.Push(hWnd)
            continue
        }
        if (!(GetWindowLongPtrCompat(hWnd, -20) & 0x8)) {
            DllCall("SetWindowPos", "Ptr", hWnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0013)
            info.forceZ := true
        }
    }

    for _, hWnd in toRemove {
        if (AOTPinnedWindows.HasKey(hWnd)) {
            DestroyAOTBorderGui(AOTPinnedWindows[hWnd])
            AOTPinnedWindows.Delete(hWnd)
        }
    }

    if (!AOTPinnedWindows.Count()) {
        StopAOTTracking()
        ReleaseAOTGdip()
        if (IsFunc("UpdateTrayTip"))
            UpdateTrayTip()
        return
    }

    zRanks := GetAOTPinnedZOrderRanks(belowNormalList)
    hMenu := WinExist("ahk_class #32768")
    menuOpen := (hMenu && DllCall("IsWindowVisible", "Ptr", hMenu)) ? true : false
    shellOverlay := IsAOTShellOverlayActive()

    if (!menuOpen && !shellOverlay && belowNormalList.Length()) {
        for _, hTarget in belowNormalList {
            DllCall("SetWindowPos", "Ptr", hTarget, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0013)
            if (AOTPinnedWindows.HasKey(hTarget))
                AOTPinnedWindows[hTarget].forceZ := true
        }
        zRanks := GetAOTPinnedZOrderRanks(belowNormalList)
    }

    if (shellOverlay) {
        for hWnd, info in AOTPinnedWindows
            HideAOTBorderGui(info)
        return
    }

    accentRgb := GetWindowsAccentRgb()
    for hWnd in AOTPinnedWindows
        UpdateAOTBorderForWindow(hWnd, zRanks, accentRgb)
}

; Kiểm tra xem Start Menu / Search / Quick Settings của Windows có đang mở không
IsAOTShellOverlayActive() {
    hFg := DllCall("GetForegroundWindow", "Ptr")
    if (!hFg)
        return false
    WinGet, fgProc, ProcessName, ahk_id %hFg%
    StringLower, fgProc, fgProc
    if (fgProc = "startmenuexperiencehost.exe" || fgProc = "searchhost.exe" || fgProc = "shellexperiencehost.exe" || fgProc = "searchapp.exe")
        return true
    WinGetClass, fgClass, ahk_id %hFg%
    if (fgClass = "Windows.UI.Core.CoreWindow")
        return true
    return false
}

; Duyệt Z-order hệ thống từ trên xuống để xếp hạng các cửa sổ đang ghim
; Đồng thời phát hiện cửa sổ ghim nào bị lọt xuống dưới cửa sổ thường
GetAOTPinnedZOrderRanks(ByRef belowNormalList := "") {
    global AOTPinnedWindows
    ranks := {}
    belowNormalList := []
    total := AOTPinnedWindows.Count()
    if (!total)
        return ranks

    curr := DllCall("GetTopWindow", "Ptr", 0, "Ptr")
    rank := 0
    sawNormalWindow := false
    while (curr) {
        currInt := curr + 0
        if (AOTPinnedWindows.HasKey(currInt)) {
            rank++
            ranks[currInt] := rank
            if (sawNormalWindow || !(GetWindowLongPtrCompat(currInt, -20) & 0x8))
                belowNormalList.Push(currInt)
            if (rank >= total)
                break
        } else if (DllCall("IsWindowVisible", "Ptr", curr)) {
            if (!(GetWindowLongPtrCompat(curr, -20) & 0x8))
                sawNormalWindow := true
        }
        curr := DllCall("GetWindow", "Ptr", curr, "UInt", 2, "Ptr") ; GW_HWNDNEXT = 2
    }
    return ranks
}

; Cập nhật viền GDI+ bo góc cho 1 cửa sổ cụ thể
UpdateAOTBorderForWindow(hWnd, zRanks := "", accentRgb := -1) {
    global AOTPinnedWindows, AOTBorderEnabled, AOTBorderAlpha, AOTBorderThickness, AOTGuiCounter

    info := AOTPinnedWindows[hWnd]
    if (!info)
        return

    if (!AOTBorderEnabled) {
        HideAOTBorderGui(info)
        return
    }

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

    if (!GetAOTWindowBounds(hWnd, wx, wy, ww, wh) || ww <= 0 || wh <= 0) {
        HideAOTBorderGui(info)
        return
    }

    if (IsAOTWindowFullscreen(hWnd, wx, wy, ww, wh)) {
        HideAOTBorderGui(info)
        return
    }

    ; Mở rộng khung vẽ ra ngoài mép cửa sổ 1px để ôm khít viền bo góc Windows 11
    pad := 1
    bx := wx - pad
    by := wy - pad
    bw := ww + (pad * 2)
    bh := wh + (pad * 2)

    if (accentRgb < 0)
        accentRgb := GetWindowsAccentRgb()

    ; Thu thập vùng che khuất của các cửa sổ ghim nằm PHÍA TRÊN hWnd trong Z-order
    if (!IsObject(zRanks))
        zRanks := GetAOTPinnedZOrderRanks()
    myRank := zRanks.HasKey(hWnd) ? zRanks[hWnd] : 999999
    occluders := []
    clipKey := ""
    for otherHwnd in AOTPinnedWindows {
        if (otherHwnd = hWnd)
            continue
        otherRank := zRanks.HasKey(otherHwnd) ? zRanks[otherHwnd] : 999999
        if (otherRank >= myRank)
            continue
        WinGet, oMinMax, MinMax, ahk_id %otherHwnd%
        if (oMinMax = -1 || !DllCall("IsWindowVisible", "Ptr", otherHwnd))
            continue
        oCloaked := 0
        DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", otherHwnd, "UInt", 14, "UInt*", oCloaked, "UInt", 4)
        if (oCloaked)
            continue
        if (!GetAOTWindowBounds(otherHwnd, ox, oy, ow, oh) || ow <= 0 || oh <= 0)
            continue

        rl := ox - bx
        rt := oy - by
        if (rl + ow > 0 && rt + oh > 0 && rl < bw && rt < bh) {
            occluders.Push({ l: rl, t: rt, w: ow, h: oh })
            clipKey .= rl . "," . rt . "," . ow . "," . oh . ";"
        }
    }

    ; Tạo GUI layered (WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_NOACTIVATE)
    if (!info.borderHwnd || !DllCall("IsWindow", "Ptr", info.borderHwnd)) {
        AOTGuiCounter++
        guiName := "AOTBorder_" . AOTGuiCounter
        Gui, %guiName%:New, +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x20 +E0x80000 +E0x08000000 +HwndhBorder
        Gui, %guiName%:Show, NoActivate Hide x%bx% y%by% w%bw% h%bh%
        info.borderName := guiName
        info.borderHwnd := hBorder
        info.x := -99999
        info.y := -99999
        info.w := 0
        info.h := 0
        info.visible := false
        info.clipKey := "__init__"
        info.accentRgb := -1
        info.forceZ := true
    }

    hBorder := info.borderHwnd
    sizeChanged := (bw != info.w || bh != info.h)
    clipChanged := (clipKey != info.clipKey)
    colorChanged := (accentRgb != info.accentRgb)
    posChanged := (bx != info.x || by != info.y)

    if (sizeChanged || clipChanged || colorChanged || !info.visible) {
        radius := GetAOTWindowCornerRadius(hWnd)
        argb := ((AOTBorderAlpha & 0xFF) << 24) | (accentRgb & 0xFFFFFF)
        if (DrawAOTBorderGdip(hBorder, bx, by, bw, bh, radius, AOTBorderThickness, argb, occluders)) {
            info.x := bx
            info.y := by
            info.w := bw
            info.h := bh
            info.clipKey := clipKey
            info.accentRgb := accentRgb
            if (!info.visible || info.forceZ) {
                ; SWP_NOSIZE (0x01) | SWP_NOMOVE (0x02) | SWP_NOACTIVATE (0x10) | SWP_SHOWWINDOW (0x40) = 0x0053
                DllCall("SetWindowPos", "Ptr", hBorder, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0053)
                info.visible := true
                info.forceZ := false
            }
        }
    } else if (posChanged || info.forceZ) {
        if (info.forceZ) {
            DllCall("SetWindowPos", "Ptr", hBorder, "Ptr", -1, "Int", bx, "Int", by, "Int", 0, "Int", 0, "UInt", 0x0051) ; SWP_NOSIZE|SWP_NOACTIVATE|SWP_SHOWWINDOW
            info.forceZ := false
        } else {
            DllCall("SetWindowPos", "Ptr", hBorder, "Ptr", 0, "Int", bx, "Int", by, "Int", 0, "Int", 0, "UInt", 0x0055) ; SWP_NOSIZE|SWP_NOZORDER|SWP_NOACTIVATE|SWP_SHOWWINDOW
        }
        info.x := bx
        info.y := by
    }
}

; Xác định bán kính bo góc phù hợp với cửa sổ trên Windows 10/11
GetAOTWindowCornerRadius(hWnd) {
    if (A_OSVersion != "" && SubStr(A_OSVersion, 1, 3) = "10.") {
        StringSplit, ver, A_OSVersion, .
        if (ver3 < 22000)
            return 0
    }
    cornerPref := 0
    hr := DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hWnd, "UInt", 33, "UInt*", cornerPref, "UInt", 4) ; DWMWA_WINDOW_CORNER_PREFERENCE
    if (hr != 0)
        return 0
    if (cornerPref = 1) ; DWMWCP_DONOTROUND
        return 0
    if (cornerPref = 3) ; DWMWCP_ROUNDSMALL
        return 4 * (A_ScreenDPI / 96)
    return 8 * (A_ScreenDPI / 96) ; DWMWCP_DEFAULT / DWMWCP_ROUND
}

; Vẽ viền bo góc khử răng cưa chuẩn PARGB (0xE200B) cho UpdateLayeredWindow
DrawAOTBorderGdip(hBorder, bx, by, bw, bh, radius, penWidth, argb, occluders) {
    if (!EnsureAOTGdip() || bw <= 2 || bh <= 2)
        return false

    pBitmap := 0, pGraphics := 0
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", bw, "Int", bh, "Int", 0, "Int", 0xE200B, "Ptr", 0, "Ptr*", pBitmap) ; PixelFormat32bppPARGB
    if (!pBitmap)
        return false
    DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBitmap, "Ptr*", pGraphics)
    if (!pGraphics) {
        DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
        return false
    }
    DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", 4)
    DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", pGraphics, "Int", 2)
    DllCall("gdiplus\GdipGraphicsClear", "Ptr", pGraphics, "UInt", 0x00000000)

    for _, occ in occluders {
        DllCall("gdiplus\GdipSetClipRect", "Ptr", pGraphics, "Float", occ.l, "Float", occ.t, "Float", occ.w, "Float", occ.h, "Int", 4) ; CombineModeExclude = 4
    }

    rx := 0.5
    ry := 0.5
    rw := bw - 1.0
    rh := bh - 1.0
    maxR := (rw < rh ? rw : rh) / 2.0
    if (radius > maxR)
        radius := maxR

    pPath := 0
    pPen := 0
    DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pPath)
    if (pPath) {
        if (radius > 0.5) {
            d := radius * 2.0
            DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", rx, "Float", ry, "Float", d, "Float", d, "Float", 180.0, "Float", 90.0)
            DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", rx + rw - d, "Float", ry, "Float", d, "Float", d, "Float", 270.0, "Float", 90.0)
            DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", rx + rw - d, "Float", ry + rh - d, "Float", d, "Float", d, "Float", 0.0, "Float", 90.0)
            DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", rx, "Float", ry + rh - d, "Float", d, "Float", d, "Float", 90.0, "Float", 90.0)
            DllCall("gdiplus\GdipClosePathFigure", "Ptr", pPath)
        } else {
            DllCall("gdiplus\GdipAddPathRectangle", "Ptr", pPath, "Float", rx, "Float", ry, "Float", rw, "Float", rh)
        }

        DllCall("gdiplus\GdipCreatePen1", "UInt", argb, "Float", penWidth, "Int", 2, "Ptr*", pPen) ; UnitPixel = 2
        if (pPen) {
            DllCall("gdiplus\GdipDrawPath", "Ptr", pGraphics, "Ptr", pPen, "Ptr", pPath)
            DllCall("gdiplus\GdipDeletePen", "Ptr", pPen)
        }
        DllCall("gdiplus\GdipDeletePath", "Ptr", pPath)
    }

    hBitmap := 0
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", hBitmap, "UInt", 0x00000000)
    GdipReleaseCanvas(pBitmap, pGraphics)
    if (!hBitmap)
        return false

    hdcScreen := DllCall("GetDC", "Ptr", 0, "Ptr")
    hdcMem := DllCall("CreateCompatibleDC", "Ptr", hdcScreen, "Ptr")
    oldBmp := DllCall("SelectObject", "Ptr", hdcMem, "Ptr", hBitmap, "Ptr")

    VarSetCapacity(ptDst, 8, 0), NumPut(bx, ptDst, 0, "Int"), NumPut(by, ptDst, 4, "Int")
    VarSetCapacity(sz, 8, 0), NumPut(bw, sz, 0, "Int"), NumPut(bh, sz, 4, "Int")
    VarSetCapacity(ptSrc, 8, 0)
    VarSetCapacity(blend, 4, 0), NumPut(0, blend, 0, "UChar"), NumPut(0, blend, 1, "UChar"), NumPut(255, blend, 2, "UChar"), NumPut(1, blend, 3, "UChar")

    ok := DllCall("UpdateLayeredWindow", "Ptr", hBorder, "Ptr", hdcScreen, "Ptr", &ptDst, "Ptr", &sz, "Ptr", hdcMem, "Ptr", &ptSrc, "UInt", 0, "Ptr", &blend, "UInt", 2)

    DllCall("SelectObject", "Ptr", hdcMem, "Ptr", oldBmp)
    DllCall("DeleteObject", "Ptr", hBitmap)
    DllCall("DeleteDC", "Ptr", hdcMem)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcScreen)
    return ok ? true : false
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
        info.clipKey := ""
        info.accentRgb := -1
        info.forceZ := false
    }
}

; Cập nhật hiển thị viền cho tất cả cửa sổ đang ghim khi bật/tắt tùy chọn viền trong Settings
RefreshAllAOTBorders() {
    SyncAllAOTBorders()
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

; Hiển thị thông báo nhanh khi có lỗi quyền Admin
ShowAOTFeedback(msg) {
    ToolTip, %msg%
    SetTimer, HideAOTFeedbackTimer, -1200
}

HideAOTFeedbackTimer:
    ToolTip
return
