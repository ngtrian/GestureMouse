#SingleInstance Force
#MaxHotkeysPerInterval 200  ; Tăng giới hạn hotkeys để tránh lỗi

#PgUp::
#WheelUp::  ; Win + Wheel Up -> Tăng âm lượng
    Send {Blind}{Volume_Up}  ; Giả lập phím tăng âm lượng
    return

#PgDn::
#WheelDown::  ; Win + Wheel Down -> Giảm âm lượng
    Send {Blind}{Volume_Down}  ; Giả lập phím giảm âm lượng
    return

~LButton & WheelUp::  ; Left Click + Wheel Up -> Tăng âm lượng
    Send {Blind}{Volume_Up}
    return

~LButton & WheelDown::  ; Left Click + Wheel Down -> Giảm âm lượng
    Send {Blind}{Volume_Down}
    return

#WheelUp Up::
#WheelDown Up::
    return  ; Ngăn Windows xử lý thêm hành động 

; Ngăn các phím Win + bất kỳ bị kích hoạt khi cuộn chuột
~LWin::return
~RWin::return