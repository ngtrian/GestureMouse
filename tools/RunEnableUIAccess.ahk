#SingleInstance Force
#include "EnableUIAccess.ahk" ; Tự động include file EnableUIAccess.ahk cùng thư mục

; Hiển thị hộp thoại chọn file
SelectedFile := FileSelect(, , "Chọn file .exe để kích hoạt UIAccess", "*.exe")
if (SelectedFile = "") {
    ExitApp
}

try {
    EnableUIAccess(SelectedFile)
    MsgBox "Đã kích hoạt UIAccess cho " SelectedFile ". Hãy đặt file vào C:\Program Files\AutoHotkey để chạy."
} catch as e {
    MsgBox "Lỗi: " e.Message
}

ExitApp
