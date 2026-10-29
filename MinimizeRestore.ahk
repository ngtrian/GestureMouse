; Khai báo MinizeRestore
global MinimizedWindows := [] ; Khởi tạo mảng để lưu ID các cửa sổ đã thu nhỏ
global MaxWindows := 100  ; Giới hạn số cửa sổ tối đa

;Thu nhỏ cửa sổ đang active (bao gồm cửa sổ không có nút thu nhỏ)
MinimizeActiveWindow(){
    WinGet, ActiveID, ID, A  ; Lấy ID của cửa sổ đang active
    if (ActiveID) {
        ; Kiểm tra trạng thái cửa sổ
        WinGet, WinState, MinMax, ahk_id %ActiveID%
        if (WinState != -1) {  ; Nếu chưa thu nhỏ
            try {
                ; Gửi thông điệp WM_SYSCOMMAND với SC_MINIMIZE
                PostMessage, 0x112, 0xF020,,, ahk_id %ActiveID%  ; 0x112 = WM_SYSCOMMAND, 0xF020 = SC_MINIMIZE
                ; Kiểm tra xem cửa sổ đã thực sự thu nhỏ chưa
                Sleep 30  ; Đợi ngắn để trạng thái cập nhật
                WinGet, NewState, MinMax, ahk_id %ActiveID%
                if (NewState = -1) {  ; Nếu đã thu nhỏ thành công
                    if (MinimizedWindows.Length() < MaxWindows) {
                        MinimizedWindows.Insert(1, ActiveID)
                        ; ShowTooltip("Đã thu nhỏ cửa sổ (ID: " . ActiveID . ")")
                    } else {
                        ShowTooltip("Đạt giới hạn " . MaxWindows . " cửa sổ!", 2000)
                    }
                } else {
                    ; ShowTooltip("Không thể thu nhỏ cửa sổ (có thể do quyền admin hoặc cấu hình đặc biệt)", 2000)
                }
            } catch {
                ; ShowTooltip("Lỗi khi thu nhỏ cửa sổ (có thể do quyền admin)", 2000)
            }
        } else {
            ; ShowTooltip("Cửa sổ đã ở trạng thái thu nhỏ!", 2000)
        }
    } else {
        ; ShowTooltip("Không có cửa sổ active!", 2000)
    }
    return
}

RestoreLastWindow(){
    if (MinimizedWindows.Length() > 0) {
        ; Lấy ID của cửa sổ mới thu nhỏ nhất
        RestoreID := MinimizedWindows[1]
        ; Kiểm tra xem cửa sổ còn tồn tại
        if WinExist("ahk_id " . RestoreID) {
            try {
                WinRestore, ahk_id %RestoreID%  ; Thử phục hồi cửa sổ
                WinActivate, ahk_id %RestoreID%  ; Kích hoạt cửa sổ
                ; ShowTooltip("Đã phục hồi cửa sổ (ID: " . RestoreID . ")")
                MinimizedWindows.Remove(1)  ; Xóa ID khỏi mảng
            } catch {
                ; ShowTooltip("Không thể phục hồi cửa sổ (có thể do quyền admin hoặc lỗi)", 2000)
                MinimizedWindows.Remove(1)  ; Xóa ID và thử cửa sổ tiếp theo
                RestoreLastWindow()  ; Thử phục hồi cửa sổ tiếp theo
            }
        } else {
            ShowTooltip("Cửa sổ không còn tồn tại, thử cửa sổ tiếp theo...", 2000)
            MinimizedWindows.Remove(1)  ; Xóa ID và thử cửa sổ tiếp theo
            RestoreLastWindow()
        }
    } else {
        ; ShowTooltip("Không có cửa sổ nào để phục hồi!", 2000)
    }
    return
}

; Hàm hiển thị thông báo
ShowTooltip(message, timeout := 1000) {
    ToolTip, %message%, 0, 0
    SetTimer, RemoveTooltip, -%timeout%
}

RemoveTooltip:
    ToolTip
return

; Ví dụ gọi hàm (tùy chọn, có thể xóa)
; ^F1::MinimizeActiveWindow()  ; Gọi hàm thu nhỏ
; ^F2::RestoreLastWindow()     ; Gọi hàm phục hồi