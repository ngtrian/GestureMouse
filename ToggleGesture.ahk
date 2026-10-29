; ToggleGesture.ahk - Quản lý bật/tắt tính năng cử chỉ chuột và cuộn
#NoEnv

; Hàm khởi tạo trạng thái từ Registry
InitGestureScroll() {
    global GestureScrollEnabled
    GestureScrollEnabled := 1 ; Mặc định là bật
    RegRead, valEnabled, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, GestureEnabled
    if (valEnabled != "")
        GestureScrollEnabled := valEnabled
}

; Label xử lý sự kiện khi nhấn menu khay hệ thống
ToggleGestureScrollLabel:
    ToggleGestureScroll()
return

; Hàm thực hiện bật/tắt tính năng
ToggleGestureScroll() {
    global GestureScrollEnabled, AutoScrollActive
    GestureScrollEnabled := !GestureScrollEnabled

    ; Lưu trạng thái vào registry
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, GestureEnabled, %GestureScrollEnabled%

    ; Nếu tắt, dừng ngay các timer đang cuộn hay hint
    if (!GestureScrollEnabled) {
        AutoScrollActive := 0
        SetTimer, AutoScroll, Off
        SetTimer, CheckGesture, Off
        HideGestureHint()
    }

    ; Cập nhật biểu tượng khay hệ thống (màu hoặc xám trắng)
    UpdateTrayIcon()

    ; Cập nhật tooltip và menu khay hệ thống
    UpdateTrayTip()
    UpdateTrayMenu()

    ; Thông báo trực quan nhanh
    ToolTip, % "Cử chỉ chuột & cuộn: " . (GestureScrollEnabled ? "ĐÃ BẬT" : "ĐÃ TẮT")
    SetTimer, RemoveToggleToolTip, -1200
}

RemoveToggleToolTip:
    ToolTip
return

; Cập nhật biểu tượng System Tray: màu khi Bật, xám trắng khi Tắt
UpdateTrayIcon() {
    global GestureScrollEnabled
    iconName := GestureScrollEnabled ? "unnamed.ico" : "unnamed_gray.ico"
    if (A_IsCompiled) {
        resId := GestureScrollEnabled ? 1 : 311
        try {
            Menu, Tray, Icon, %A_ScriptFullPath%, -%resId%
            return
        }
    }
    targetIcon := A_ScriptDir . "\" . iconName
    if FileExist(targetIcon)
        Menu, Tray, Icon, %targetIcon%
    else
        Menu, Tray, Icon, %iconName%
}

; Bật/tắt tính năng cuộn và cử chỉ chuột bằng phím tắt Ctrl + Alt
~^Alt Up::
~!Ctrl Up::
    if (A_PriorKey = "LAlt" || A_PriorKey = "RAlt" || A_PriorKey = "LControl" || A_PriorKey = "RControl") {
        ToggleGestureScroll()
    }
return
