#SingleInstance Force

global isEnable := False ;Bật hoặc tắt chức năng hiện Buffer
global Buffer := ""

InitInputHook() {
    global ih
    ih := InputHook("V" ) ; Tạo InputHook với chế độ "V" (nhận ký tự)
    ih.NotifyNonText := 1 ; Nhận thông báo cho các ký tự không phải văn bản
    ih.OnChar := Func("CheckChar") ; Kiểm tra mỗi ký tự
    ih.Start() 
}

CheckChar(ih, char) {
    global isEnable, Buffer
    if (isEnable) {
        Buffer .= char ; Thêm ký tự vào buffer
        CharCode := Asc(char) ; Lấy mã ASCII của ký tự
        hexCode := Format("{:X}", CharCode) ; Chuyển đổi thành chuỗi hexa (vkcode)

        ToolTip, Buffer: %Buffer%`nASCII: %CharCode%`nHex (vkCode): 0x%hexCode%`n, 200, 200 
    }
}

;phím tắt ctrl+esc để bật tắt chức năng
^esc::
    global isEnable
    if (!isEnable){
        isEnable := True
        ToolTip, Buffer:`nASCII:`nHex:, 200, 200
        InitInputHook()
    } else{
        isEnable := False
        Buffer := ""
        Tooltip,
        if (ih) 
            ih.Stop()
    }
return

; thêm phím tắt esc để reset tooltip và xóa buffer
esc::
    global Buffer
    if (isEnable) {
        Buffer := ""
        ToolTip, Buffer:`nASCII:`nHex:, 200, 200
    }
return

