#SingleInstance Force
#MaxHotkeysPerInterval 200  ; Tăng giới hạn hotkeys để tránh lỗi

#If (GestureScrollEnabled)
#PgUp::
#WheelUp::  ; Win + Wheel Up -> Tăng âm lượng
    Send {Blind}{Volume_Up}  ; Giả lập phím tăng âm lượng
    return

#PgDn::
#WheelDown::  ; Win + Wheel Down -> Giảm âm lượng
    Send {Blind}{Volume_Down}  ; Giả lập phím giảm âm lượng
    return

#If (GestureScrollEnabled && GetKeyState("LButton", "P"))
WheelUp::  ; Left Click + Wheel Up -> Tăng âm lượng
    Send {Blind}{Volume_Up}
return

WheelDown::  ; Left Click + Wheel Down -> Giảm âm lượng
    Send {Blind}{Volume_Down}
return
#If (GestureScrollEnabled)

#WheelUp Up::
#WheelDown Up::
    return  ; Ngăn Windows xử lý thêm hành động 

; Ngăn các phím Win + bất kỳ bị kích hoạt khi cuộn chuột
~LWin::return
~RWin::return
#If