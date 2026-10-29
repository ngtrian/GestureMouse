#Requires AutoHotkey v2.0
#SingleInstance Force
#Include EnableUIAccess.ahk

if (A_Args.Length < 1) {
    FileAppend "[!] Thiếu tham số đường dẫn file .exe cần ký.
", "*"
    ExitApp 1
}

targetExe := A_Args[1]
if (!FileExist(targetExe)) {
    FileAppend "[!] Không tìm thấy file: " targetExe "
", "*"
    ExitApp 1
}

FileAppend "[*] Đang bật UIAccess và ký số cho file: " targetExe "
", "*"

try {
    EnableUIAccess(targetExe)
    
    ; Kiểm tra xác thực chữ ký
    err := EnableUIAccess_Verify(targetExe)
    if (err == 0) {
        FileAppend "[+] Xác thực chữ ký: HỢP LỆ (Thành công).
", "*"
        FileAppend "[+] Đã kích hoạt UIAccess và ký số thành công!
", "*"
        ExitApp 0
    } else {
        FileAppend "[!] Cảnh báo: Xác thực chữ ký trả về mã lỗi: " err "
", "*"
        ExitApp 0
    }
} catch as e {
    FileAppend "[X] Lỗi khi kích hoạt UIAccess: " e.Message "
", "*"
    ExitApp 1
}