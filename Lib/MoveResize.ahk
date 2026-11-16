; MoveResize.ahk - Di chuyển và đổi kích thước cửa sổ nhanh (tương tự PowerToys GrabAndMove)
#NoEnv

global MoveResizeEnabled := 1
global MoveResizeModifier := "Alt"          ; "Alt" hoặc "Win"
global MoveResizeDisableGameMode := 1
global MoveResizeShowOSD := 1

global hMROsdGui := 0
global MROsdText := ""
global MROsdLastText := ""
global MROsdVisible := false

global isMoveResizing := 0
global MR_AltTabSession := false
global MR_Mode := ""                        ; "Move" hoặc "Resize"
global MR_Button := ""                      ; "LButton" hoặc "RButton"
global MR_TargetHwnd := 0
global MR_StartX := 0
global MR_StartY := 0
global MR_WinX := 0
global MR_WinY := 0
global MR_WinW := 0
global MR_WinH := 0
global MR_CurX := 0
global MR_CurY := 0
global MR_CurW := 0
global MR_CurH := 0
global MR_LastMouseX := -99999
global MR_LastMouseY := -99999
global MR_Col := 0                          ; -1 (Trái), 0 (Giữa), 1 (Phải)
global MR_Row := 0                          ; -1 (Trên), 0 (Giữa), 1 (Dưới)
global MR_CursorModified := false

InitMoveResize() {
    global MoveResizeEnabled, MoveResizeModifier, MoveResizeDisableGameMode, MoveResizeShowOSD

    RegRead, valEnabled, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, MoveResizeEnabled
    if (valEnabled != "")
        MoveResizeEnabled := (valEnabled ? 1 : 0)

    RegRead, valMod, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, MoveResizeModifier
    if (valMod = "Alt" || valMod = "Win")
        MoveResizeModifier := valMod

    RegRead, valGame, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, MoveResizeDisableGameMode
    if (valGame != "")
        MoveResizeDisableGameMode := (valGame ? 1 : 0)

    RegRead, valOSD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, MoveResizeShowOSD
    if (valOSD != "")
        MoveResizeShowOSD := (valOSD ? 1 : 0)

    OnExit("RestoreMoveResizeCursor")
}

SaveMoveResizeSettings() {
    global MoveResizeEnabled, MoveResizeModifier, MoveResizeDisableGameMode, MoveResizeShowOSD
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, MoveResizeEnabled, %MoveResizeEnabled%
    RegWrite, REG_SZ,    HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, MoveResizeModifier, %MoveResizeModifier%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, MoveResizeDisableGameMode, %MoveResizeDisableGameMode%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, MoveResizeShowOSD, %MoveResizeShowOSD%
}

; Kiểm tra Windows Game Mode / Fullscreen D3D qua SHQueryUserNotificationState
IsWindowsGameModeActive() {
    state := 0
    hr := DllCall("Shell32\SHQueryUserNotificationState", "Int*", state, "Int")
    if (hr = 0 && (state = 2 || state = 3 || state = 4))
        return true
    return false
}

; Kiểm tra xem giao diện Alt+Tab (Task Switcher) của Windows có đang mở không
IsAltTabActive() {
    activeHwnd := WinExist("A")
    if (!activeHwnd)
        return false
    WinGetClass, activeCls, ahk_id %activeHwnd%
    if (activeCls = "MultitaskingViewFrame" || activeCls = "TaskSwitcherWnd" || activeCls = "XamlExplorerHostIslandWindow")
        return true
    return false
}

; Điều kiện cho phép kích hoạt Move & Resize Windows trong #If hook
CanMoveResize(reqMod) {
    global MoveResizeEnabled, MoveResizeModifier, MoveResizeDisableGameMode, isMoveResizing, MR_AltTabSession
    if (!MoveResizeEnabled || isMoveResizing || MoveResizeModifier != reqMod)
        return false
    if (reqMod = "Alt" && MR_AltTabSession)
        return false
    if (IsAltTabActive())
        return false
    if (MoveResizeDisableGameMode && IsWindowsGameModeActive())
        return false
    if (IsMoveResizeAppExcluded())
        return false
    return true
}

IsMoveResizeKeyHeld() {
    global MoveResizeEnabled, MoveResizeModifier
    if (!MoveResizeEnabled)
        return false
    if (MoveResizeModifier = "Alt")
        return GetKeyState("Alt", "P")
    return GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
}

; Đổi con trỏ chuột hệ thống tạm thời khi kéo/resize
SetMoveResizeCursor(idcId) {
    global MR_CursorModified
    static slots := [32512, 32513, 32649] ; OCR_NORMAL, OCR_IBEAM, OCR_HAND

    hCur := DllCall("LoadCursor", "Ptr", 0, "Ptr", idcId, "Ptr")
    if (!hCur)
        return

    for idx, slotId in slots {
        hCopy := DllCall("CopyIcon", "Ptr", hCur, "Ptr")
        if (hCopy)
            DllCall("SetSystemCursor", "Ptr", hCopy, "UInt", slotId)
    }
    MR_CursorModified := true
}

RestoreMoveResizeCursor() {
    global MR_CursorModified
    if (MR_CursorModified) {
        DllCall("SystemParametersInfo", "UInt", 0x0057, "UInt", 0, "Ptr", 0, "UInt", 0) ; SPI_SETCURSORS
        MR_CursorModified := false
    }
}

; Lấy vùng làm việc của màn hình chứa điểm (ptX, ptY)
GetMonitorWorkAreaAtPoint(ptX, ptY, ByRef mLeft, ByRef mTop, ByRef mRight, ByRef mBottom) {
    pt := (ptX & 0xFFFFFFFF) | ((ptY & 0xFFFFFFFF) << 32)
    hMon := DllCall("MonitorFromPoint", "Int64", pt, "UInt", 2, "Ptr") ; MONITOR_DEFAULTTONEAREST
    if (hMon) {
        VarSetCapacity(mi, 40, 0)
        NumPut(40, mi, 0, "UInt")
        if (DllCall("GetMonitorInfo", "Ptr", hMon, "Ptr", &mi)) {
            mLeft   := NumGet(mi, 20, "Int")
            mTop    := NumGet(mi, 24, "Int")
            mRight  := NumGet(mi, 28, "Int")
            mBottom := NumGet(mi, 32, "Int")
            return true
        }
    }
    SysGet, mArea, MonitorWorkArea
    mLeft := mAreaLeft, mTop := mAreaTop, mRight := mAreaRight, mBottom := mAreaBottom
    return false
}

ComputeResizeGridZone(ptX, ptY, wX, wY, wW, wH, ByRef outCol, ByRef outRow) {
    relX := ptX - wX
    relY := ptY - wY
    outCol := (relX < wW / 3) ? -1 : ((relX > (wW * 2) / 3) ? 1 : 0)
    outRow := (relY < wH / 3) ? -1 : ((relY > (wH * 2) / 3) ? 1 : 0)
    ; Nếu bấm vào đúng ô chính giữa (0, 0) -> resize cạnh trên
    if (outCol = 0 && outRow = 0)
        outRow := -1
}

ApplyResizeCursorForZone(col, row) {
    if ((col = -1 && row = -1) || (col = 1 && row = 1))
        SetMoveResizeCursor(32642) ; IDC_SIZENWSE
    else if ((col = 1 && row = -1) || (col = -1 && row = 1))
        SetMoveResizeCursor(32643) ; IDC_SIZENESW
    else if (col != 0 && row = 0)
        SetMoveResizeCursor(32644) ; IDC_SIZEWE
    else
        SetMoveResizeCursor(32645) ; IDC_SIZENS
}

; Bắt đầu thao tác Move ("Move") hoặc Resize ("Resize")
StartMoveResize(mode) {
    global isMoveResizing, MR_Mode, MR_Button, MR_TargetHwnd
    global MR_StartX, MR_StartY, MR_LastMouseX, MR_LastMouseY
    global MR_WinX, MR_WinY, MR_WinW, MR_WinH
    global MR_CurX, MR_CurY, MR_CurW, MR_CurH, MR_Col, MR_Row

    if (isMoveResizing)
        return

    CoordMode, Mouse, Screen
    MouseGetPos, mX, mY, hoverHwnd
    if (!hoverHwnd)
        return

    ; Lấy cửa sổ top-level thực sự (GA_ROOT = 2)
    targetHwnd := DllCall("GetAncestor", "Ptr", hoverHwnd, "UInt", 2, "Ptr")
    if (!targetHwnd)
        targetHwnd := hoverHwnd

    WinGetClass, winCls, ahk_id %targetHwnd%
    if (winCls = "Progman" || winCls = "WorkerW" || winCls = "Shell_TrayWnd" || winCls = "Shell_SecondaryTrayWnd")
        return

    ; Kiểm tra cửa sổ đang phóng to toàn màn hình (Maximized)
    WinGet, minMax, MinMax, ahk_id %targetHwnd%
    if (minMax = -1) ; Đang thu nhỏ
        return

    ; Nếu Resize, kiểm tra xem cửa sổ có cho phép đổi kích thước (WS_THICKFRAME = 0x40000) không
    if (mode = "Resize") {
        WinGet, winStyle, Style, ahk_id %targetHwnd%
        if (!(winStyle & 0x40000))
            return
    }

    ; Gửi phím mặt nạ không chức năng để ngăn Windows mở Menu Bar (Alt) hoặc Start Menu (Win) khi nhả phím
    Send, {Blind}{vkE8}

    ; Nếu đang Maximized: dùng SetWindowPlacement để restore thẳng về đúng vị trí đặt chuột trong 1 bước (không chớp, không active)
    if (minMax = 1) {
        GetMonitorWorkAreaAtPoint(mX, mY, mLeft, mTop, mRight, mBottom)
        monW := Max(1, mRight - mLeft)
        monH := Max(1, mBottom - mTop)
        ratioX := (mX - mLeft) / monW
        ratioY := (mY - mTop) / monH

        VarSetCapacity(wp, 44, 0)
        NumPut(44, wp, 0, "UInt")
        if (DllCall("GetWindowPlacement", "Ptr", targetHwnd, "Ptr", &wp)) {
            nLeft   := NumGet(wp, 28, "Int")
            nTop    := NumGet(wp, 32, "Int")
            nRight  := NumGet(wp, 36, "Int")
            nBottom := NumGet(wp, 40, "Int")
            curW := nRight - nLeft
            curH := nBottom - nTop
            if (curW > 0 && curH > 0) {
                newX := Round(mX - curW * ratioX)
                newY := Round(mY - curH * ratioY)
                if (newY < mTop)
                    newY := mTop
                NumPut(4, wp, 8, "UInt") ; SW_SHOWNOACTIVATE
                NumPut(newX, wp, 28, "Int")
                NumPut(newY, wp, 32, "Int")
                NumPut(newX + curW, wp, 36, "Int")
                NumPut(newY + curH, wp, 40, "Int")
                ; Tạm tắt hiệu ứng chuyển tiếp DWM để restore tức thì không bị chớp
                DllCall("Dwmapi\DwmSetWindowAttribute", "Ptr", targetHwnd, "UInt", 3, "Int*", 1, "UInt", 4)
                DllCall("SetWindowPlacement", "Ptr", targetHwnd, "Ptr", &wp)
                DllCall("Dwmapi\DwmSetWindowAttribute", "Ptr", targetHwnd, "UInt", 3, "Int*", 0, "UInt", 4)
            } else {
                WinRestore, ahk_id %targetHwnd%
            }
        } else {
            WinRestore, ahk_id %targetHwnd%
        }
    }

    WinGetPos, wX, wY, wW, wH, ahk_id %targetHwnd%
    if (wW <= 0 || wH <= 0)
        return

    MR_Mode := mode
    MR_Button := (mode = "Move") ? "LButton" : "RButton"
    MR_TargetHwnd := targetHwnd
    MR_StartX := mX
    MR_StartY := mY
    MR_LastMouseX := mX
    MR_LastMouseY := mY
    MR_WinX := wX
    MR_WinY := wY
    MR_WinW := wW
    MR_WinH := wH
    MR_CurX := wX
    MR_CurY := wY
    MR_CurW := wW
    MR_CurH := wH

    if (mode = "Move") {
        SetMoveResizeCursor(32646) ; IDC_SIZEALL
    } else {
        ComputeResizeGridZone(mX, mY, wX, wY, wW, wH, MR_Col, MR_Row)
        ApplyResizeCursorForZone(MR_Col, MR_Row)
    }

    isMoveResizing := 1
    ShowOrUpdateMoveResizeOSD(wX, wY, wW, wH, mX, mY)
    SetTimer, MoveResizeTick, 10
}

MoveResizeTick() {
    global isMoveResizing, MR_Mode, MR_Button, MR_TargetHwnd
    global MR_StartX, MR_StartY, MR_LastMouseX, MR_LastMouseY
    global MR_WinX, MR_WinY, MR_WinW, MR_WinH
    global MR_CurX, MR_CurY, MR_CurW, MR_CurH, MR_Col, MR_Row

    if (!isMoveResizing) {
        SetTimer, MoveResizeTick, Off
        return
    }

    if (!GetKeyState(MR_Button, "P") || !WinExist("ahk_id " . MR_TargetHwnd)) {
        StopMoveResize()
        return
    }

    CoordMode, Mouse, Screen
    MouseGetPos, curMX, curMY
    if (curMX = MR_LastMouseX && curMY = MR_LastMouseY)
        return
    MR_LastMouseX := curMX
    MR_LastMouseY := curMY

    if (MR_Mode = "Move") {
        dx := curMX - MR_StartX
        dy := curMY - MR_StartY
        newX := MR_WinX + dx
        newY := MR_WinY + dy
        MR_CurX := newX
        MR_CurY := newY
        ; SWP_NOSIZE (0x1) | SWP_NOZORDER (0x4) | SWP_NOACTIVATE (0x10) | SWP_ASYNCWINDOWPOS (0x4000)
        DllCall("SetWindowPos", "Ptr", MR_TargetHwnd, "Ptr", 0, "Int", newX, "Int", newY, "Int", 0, "Int", 0, "UInt", 0x4015)
        ShowOrUpdateMoveResizeOSD(MR_CurX, MR_CurY, MR_CurW, MR_CurH, curMX, curMY)
    } else {
        ; Kiểm tra xem chuột có di chuyển sang vùng lưới 3x3 khác không; nếu có -> đổi hướng và reset mốc để không giật
        ComputeResizeGridZone(curMX, curMY, MR_CurX, MR_CurY, MR_CurW, MR_CurH, newCol, newRow)
        if (newCol != MR_Col || newRow != MR_Row) {
            MR_Col := newCol
            MR_Row := newRow
            MR_WinX := MR_CurX
            MR_WinY := MR_CurY
            MR_WinW := MR_CurW
            MR_WinH := MR_CurH
            MR_StartX := curMX
            MR_StartY := curMY
            ApplyResizeCursorForZone(MR_Col, MR_Row)
            return
        }

        dx := curMX - MR_StartX
        dy := curMY - MR_StartY

        SysGet, minTrackW, 34 ; SM_CXMINTRACK
        SysGet, minTrackH, 35 ; SM_CYMINTRACK
        minW := (minTrackW > 120) ? minTrackW : 120
        minH := (minTrackH > 80)  ? minTrackH : 80

        newX := MR_WinX
        newY := MR_WinY
        newW := MR_WinW
        newH := MR_WinH

        if (MR_Col = -1) {
            newW := MR_WinW - dx
            if (newW < minW)
                newW := minW
            newX := MR_WinX + (MR_WinW - newW)
        } else if (MR_Col = 1) {
            newW := MR_WinW + dx
            if (newW < minW)
                newW := minW
        }

        if (MR_Row = -1) {
            newH := MR_WinH - dy
            if (newH < minH)
                newH := minH
            newY := MR_WinY + (MR_WinH - newH)
        } else if (MR_Row = 1) {
            newH := MR_WinH + dy
            if (newH < minH)
                newH := minH
        }

        MR_CurX := newX
        MR_CurY := newY
        MR_CurW := newW
        MR_CurH := newH

        ; SWP_NOZORDER (0x4) | SWP_NOACTIVATE (0x10) | SWP_ASYNCWINDOWPOS (0x4000)
        DllCall("SetWindowPos", "Ptr", MR_TargetHwnd, "Ptr", 0, "Int", newX, "Int", newY, "Int", newW, "Int", newH, "UInt", 0x4014)
        ShowOrUpdateMoveResizeOSD(MR_CurX, MR_CurY, MR_CurW, MR_CurH, curMX, curMY)
    }
}

StopMoveResize() {
    global isMoveResizing, MR_TargetHwnd
    SetTimer, MoveResizeTick, Off
    HideMoveResizeOSD()
    RestoreMoveResizeCursor()
    isMoveResizing := 0
    MR_TargetHwnd := 0
}

ShowOrUpdateMoveResizeOSD(winX, winY, winW, winH, mouseX, mouseY) {
    global MoveResizeShowOSD, hMROsdGui, MROsdText, MROsdLastText, MROsdVisible
    if (!MoveResizeShowOSD)
        return

    static osdW := 136, osdH := 38
    if (!hMROsdGui) {
        ; WS_EX_NOACTIVATE (0x08000000) | WS_EX_TRANSPARENT (0x00000020)
        Gui, MoveResizeOSD:New, +AlwaysOnTop -Caption +ToolWindow +E0x08000020 +HwndhMROsdGui
        Gui, MoveResizeOSD:Color, 1E1E1E
        Gui, MoveResizeOSD:Margin, 0, 0
        Gui, MoveResizeOSD:Font, s8.5 Norm cFFFFFF, Segoe UI
        Gui, MoveResizeOSD:Add, Text, x0 y4 w%osdW% h30 Center vMROsdText,
        ; Bo góc trên Windows 11 (DWMWA_WINDOW_CORNER_PREFERENCE = 33, DWMWCP_ROUND = 2)
        DllCall("Dwmapi\DwmSetWindowAttribute", "Ptr", hMROsdGui, "UInt", 33, "Int*", 2, "UInt", 4)
        WinSet, Transparent, 210, ahk_id %hMROsdGui%
        Gui, MoveResizeOSD:Show, Hide w%osdW% h%osdH%
    }

    txt := "X: " . winX . "   Y: " . winY . "`n" . winW . " × " . winH
    if (txt != MROsdLastText) {
        GuiControl, MoveResizeOSD:, MROsdText, %txt%
        MROsdLastText := txt
    }

    centerX := winX + (winW // 2)
    centerY := winY + (winH // 2)
    GetMonitorWorkAreaAtPoint(centerX, centerY, mLeft, mTop, mRight, mBottom)
    osdX := Round(centerX - osdW / 2)
    osdY := Round(centerY - osdH / 2)
    if (osdX + osdW > mRight - 4)
        osdX := mRight - osdW - 4
    if (osdY + osdH > mBottom - 4)
        osdY := mBottom - osdH - 4
    if (osdX < mLeft + 4)
        osdX := mLeft + 4
    if (osdY < mTop + 4)
        osdY := mTop + 4

    if (!MROsdVisible) {
        Gui, MoveResizeOSD:Show, NoActivate x%osdX% y%osdY% w%osdW% h%osdH%
        MROsdVisible := true
    } else {
        ; HWND_TOPMOST (-1), SWP_NOSIZE (0x1) | SWP_NOACTIVATE (0x10) | SWP_ASYNCWINDOWPOS (0x4000)
        DllCall("SetWindowPos", "Ptr", hMROsdGui, "Ptr", -1, "Int", osdX, "Int", osdY, "Int", 0, "Int", 0, "UInt", 0x4011)
    }
}

HideMoveResizeOSD() {
    global hMROsdGui, MROsdVisible, MROsdLastText
    if (MROsdVisible && hMROsdGui) {
        Gui, MoveResizeOSD:Hide
        MROsdVisible := false
        MROsdLastText := ""
    }
}
