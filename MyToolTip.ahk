; MyToolTip.ahk - Hàm hiển thị tooltip tùy chỉnh
#Persistent
CoordMode, Mouse, Screen

MyToolTip(text, x="", y="", which=1) {
    static LastGui := {}  ; Lưu trữ GUI để quản lý nhiều tooltip

    ; Nếu text rỗng, xóa tooltip
    if (text = "") {
        if (LastGui[which]) {
            Gui % LastGui[which] ":Destroy"
            LastGui[which] := ""
        }
        return
    }

    ; Xóa tooltip cũ nếu tồn tại
    if (LastGui[which]) {
        Gui % LastGui[which] ":Destroy"
    }

    ; Tạo GUI mới
    Gui %which%:+LastFound +AlwaysOnTop -Caption +ToolWindow
    Gui %which%:Font, s20  ; Kích thước chữ
    Gui %which%:Color, 333333  ; Màu nền 
    Gui %which%:Add, Text, cFFFFF0, %text%  ; Nội dung tooltip, màu chữ

    ; Xác định vị trí
    if (x = "" || y = "") {
        MouseGetPos, mx, my
        x := mx
        y := my
    }

    ; Hiển thị tooltip
    Gui %which%:Show, x%x% y%y% NoActivate
    LastGui[which] := which  ; Lưu ID GUI
}