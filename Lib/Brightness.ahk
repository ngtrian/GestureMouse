; Tạo GUI lớp phủ
BrightnessGui:
    Gui, BrightnessGui:New, +LastFound +AlwaysOnTop -Caption +ToolWindow +E0x20 +HwndhwndBrightness   ; Không viền, luôn trên cùng, nhấp xuyên qua
    Gui, Color, 000000  ; Màu đen
    Gui, -DPIScale  ; Đảm bảo GUI phù hợp với màn hình DPI cao
    ; Gui, Show, x0 y0 w%A_ScreenWidth% h%A_ScreenHeight% NoActivate  ; Hiển thị toàn màn hình mà không kích hoạt cửa sổ

WinSet, Transparent, 0, ahk_id %hwndBrightness%  ; Giá trị từ 0 đến 225, giá trị ban đầu là 0 (trong suốt hoàn toàn)
return 

; Phím F9: Làm tối hơn (255 là hết trong suốt)
F9::
GuiOn := true
Gui, BrightnessGui:Show, x0 y0 w%A_ScreenWidth% h%A_ScreenHeight% NoActivate
Brightness +=20
if (Brightness > 255)
    Brightness := 255
WinSet, Transparent, %Brightness%, ahk_id %hwndBrightness%
UpdateTrayTip()
Gosub, BrightnessTip
return

; Phím F10: Làm sáng hơn (0 là trong suốt hoàn toàn)
F10::
Brightness -=20
if (Brightness <= 0){
    Brightness := 0
    GuiOn := false 
    Gui, BrightnessGui:Hide  ; Ẩn GUI nếu trong suốt hoàn toàn
}

WinSet, Transparent, %Brightness%, ahk_id %hwndBrightness%
UpdateTrayTip()
Gosub, BrightnessTip
return

BrightnessTip:
    BrightnessPercent := Round((255 - Brightness) / 255 * 100)
    msg := BrightnessPercent . "%"

    IfWinNotExist, Độ sáng
    {
        Gui, 1:New, +AlwaysOnTop +ToolWindow -Caption +LastFound, Độ sáng  ; Tạo GUI mới với ID 1
        Gui, Font, s12, Segoe UI
        Gui, Color, fefeab
        Gui, 1:Add, Text, vBrightnessText x0 w80 h40 Center, %msg%  ; Tạo Text control với biến TimeText
        WinSet, Region, 8-8 w85 h40 R15-15  ; Bo tròn góc
        WinSet, Transparent, 180
        Gui, 1:Show, AutoSize  ; Hiển thị
    }
    else
    {
        Gui, 1:Default  ; Đặt GUI 1 làm mặc định
        GuiControl, 1:Text, BrightnessText, %msg%  ; Cập nhật nội dung với kiểu Text
        GuiControl, 1:, BrightnessText, %msg%  ; Đảm bảo nội dung cập nhật
        ; GuiControl, +Center, BrightnessText  ; Căn giữa nội dung
    }
    SetTimer, HideGui, -2000  ; Đặt timer một lần để ẩn GUI sau 2 giây
    return

HideGui:
Gui, 1:Destroy
SetTimer, HideGui, Off  ; Tắt timer sau khi ẩn GUI
return