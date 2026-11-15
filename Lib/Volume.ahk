#SingleInstance Force
#MaxHotkeysPerInterval 200  ; Tăng giới hạn hotkeys để tránh lỗi

; Kiểm tra con trỏ chuột có đang nằm trên Taskbar (màn hình chính hoặc màn hình phụ) hay không
IsMouseOverTaskbar() {
    MouseGetPos, , , hwndUnderMouse
    if (!hwndUnderMouse)
        return false
    WinGetClass, winClass, ahk_id %hwndUnderMouse%
    return (winClass = "Shell_TrayWnd" || winClass = "Shell_SecondaryTrayWnd")
}

; Cho phép cuộn chỉnh âm lượng khi ở Taskbar, sát mép phải (mọi lúc), hoặc sát mép dưới (khi Fullscreen)
ShouldScrollChangeVolume() {
    if (IsMouseOverTaskbar())
        return true

    VarSetCapacity(pt, 8, 0)
    if (!DllCall("GetCursorPos", "Ptr", &pt))
        return false
    mx := NumGet(pt, 0, "Int")
    my := NumGet(pt, 4, "Int")

    ; Tìm màn hình đang chứa con trỏ chuột (hỗ trợ đa màn hình)
    SysGet, monCount, MonitorCount
    mLeft := 0, mTop := 0, mRight := A_ScreenWidth, mBottom := A_ScreenHeight
    Loop, %monCount% {
        SysGet, m, Monitor, %A_Index%
        if (mx >= mLeft && mx < mRight && my >= mTop && my < mBottom) {
            mLeft := mLeft, mTop := mTop, mRight := mRight, mBottom := mBottom
            break
        }
    }

    edgePx := Round(10 * (A_ScreenDPI / 96.0))

    ; Mép phải: luôn cho phép cuộn chỉnh âm lượng (cả khi chưa Fullscreen)
    if (mx >= mRight - edgePx)
        return true

    ; Mép dưới: chỉ kích hoạt khi cửa sổ đang Fullscreen (lúc bình thường đã có Taskbar)
    if (my < mBottom - edgePx)
        return false

    MouseGetPos, , , hwndUnderMouse
    if (!hwndUnderMouse)
        return false
    WinGetClass, winClass, ahk_id %hwndUnderMouse%
    if (winClass = "Progman" || winClass = "WorkerW" || winClass = "Shell_TrayWnd" || winClass = "Shell_SecondaryTrayWnd")
        return false

    WinGetPos, wx, wy, ww, wh, ahk_id %hwndUnderMouse%
    if (wx = "" || wy = "" || ww = "" || wh = "")
        return false

    return (wx <= mLeft && wy <= mTop && (wx + ww) >= mRight && (wy + wh) >= mBottom)
}

; 1. Win + Wheel -> Tăng / Giảm âm lượng
#If (GestureScrollEnabled)
#WheelUp::
    Send {Blind}{Volume_Up}
return

#WheelDown::
    Send {Blind}{Volume_Down}
return

#WheelUp Up::
#WheelDown Up::
    return  ; Ngăn Windows xử lý thêm hành động

; Ngăn các phím Win + bất kỳ bị kích hoạt khi cuộn chuột
~LWin::return
~RWin::return

; 2. Cuộn trên Taskbar (bình thường) hoặc sát mép dưới / mép phải (khi Fullscreen) -> Tăng / Giảm âm lượng
#If (GestureScrollEnabled && ShouldScrollChangeVolume())
WheelUp::
    Send {Blind}{Volume_Up}
return

WheelDown::
    Send {Blind}{Volume_Down}
return

#If
