#SingleInstance Force
#Persistent

#Include *i Language.ahk

; Các phím tắt tiện ích (chỉ hoạt động khi bật Cử chỉ & Phím tắt)
#If (GestureScrollEnabled)

; Paste (dán) văn bản mà không định dạng, không có khoảng trắng, không có \r, \n
PastePlainText:
$^+v::
    ClipSaved := ClipboardAll  ; Lưu clipboard gốc
    text := Clipboard         ; Lấy nội dung clipboard
    text := RegExReplace(text, "^[\s\r\n]+|[\s\r\n]+$", "")  ; Xóa khoảng trắng, \r, \n
    Clipboard := text         ; Ghi nội dung đã xử lý
    ClipWait, 1               ; Đợi clipboard sẵn sàng
    Send ^v                   ; Dán nội dung
    Sleep 50                  ; Đợi ngắn
    Clipboard := ClipSaved    ; Khôi phục clipboard gốc
return

; Hàm bật/tắt âm thanh
MuteFunc:
^+m::
    SoundSet, +1, MASTER, MUTE
    SoundGet, MuteState, MASTER, MUTE
return

#If
