; AutoScroll.ahk - Xử lý cuộn tự động theo quán tính (Kinetic Fling Inertia)
#NoEnv

; Khai báo biến toàn cục (được chia sẻ với Main.ahk)
global VelocityY
global AutoScrollActive
global scrollInterval
global ScrollStyle
global PixelsPerScrollStep
global FlingVelocityY
global FlingAccumulator
global LastFlingTick
global TargetHwnd
global TargetControl
global TargetStartX
global TargetStartY
global AutoScrollStartTime
global AutoScrollStartX
global AutoScrollStartY
global LastAutoScrollMouseX
global LastAutoScrollMouseY

AutoScroll:
    if (!AutoScrollActive)
    {
        SetTimer, AutoScroll, Off
        return
    }
    
    CurrentTick := A_TickCount
    dt := (CurrentTick - LastFlingTick) / 1000.0
    if (dt < 0.005)  ; Tránh tick lặp do timer jitter khi chưa đủ 5ms
        return
    LastFlingTick := CurrentTick
    
    ; Giới hạn dt an toàn đề phòng timer bị delay đột ngột
    if (dt > 0.05)
        dt := 0.016
    
    ; --- 1. KIỂM TRA DI CHUYỂN CHUỘT ĐỂ DỪNG CUỘN QUÁN TÍNH ---
    MouseGetPos, curMouseX, curMouseY
    currentElapsed := (CurrentTick - AutoScrollStartTime) / 1000.0
    frameDist := Sqrt((curMouseX - LastAutoScrollMouseX)**2 + (curMouseY - LastAutoScrollMouseY)**2)
    LastAutoScrollMouseX := curMouseX
    LastAutoScrollMouseY := curMouseY
    
    ; Dành 300ms đầu cho quán tính vung tay tự nhiên (follow-through) khi vừa hất và thả chuột
    ; Sau 300ms: người dùng chủ động di chuyển chuột (>= 4px trong 1 frame) -> DỪNG NGAY LẬP TỨC!
    if (currentElapsed >= 0.30 && frameDist >= 4)
    {
        StopAutoScroll()
        return
    }
    
    ; --- 2. ÁP DỤNG MA SÁT SUY GIẢM CO GIÃN THEO ĐỘ MẠNH CỦA CÚ HẤT ---
    absV := Abs(FlingVelocityY)
    ; Khi hất mạnh (> 3000 px/s): ma sát cực thấp 0.982 giúp trôi cực xa và lâu (3.0 - 4.5 giây)
    ; Khi hất vừa (1200 - 3000 px/s): ma sát 0.972 giúp trôi 2.0 - 2.5 giây
    ; Khi hất nhẹ (400 - 1200 px/s): ma sát 0.958 giúp dừng êm ái
    ; Khi chậm dần (< 400 px/s): tăng ma sát (0.915) để hãm phanh dứt khoát ở nhịp cuối
    if (absV > 3000)
        baseFriction := 0.982
    else if (absV > 1200)
        baseFriction := 0.972
    else if (absV > 400)
        baseFriction := 0.958
    else
        baseFriction := 0.915
        
    frictionFactor := baseFriction ** (dt / 0.016)
    FlingVelocityY *= frictionFactor
    
    ; --- CẮT ĐUÔI SỚM (EARLY CUTOFF) ---
    ; Ngắt khi vận tốc giảm xuống dưới ngưỡng 130 px/s (~6-7 nấc/giây).
    ; Khi vận tốc < 130 px/s, khoảng cách giữa 2 nấc cuộn sẽ giãn ra > 150ms.
    ; Hiệu ứng cuộn mượt của trình duyệt chỉ kéo dài ~100-150ms, nếu trôi tiếp
    ; mắt sẽ thấy trang dừng lại rồi giật từng nấc rời rạc ("thoi thóp").
    ; Cắt đuôi tại đây giúp trang dừng lại êm ái và dứt khoát.
    if (absV < 130)
    {
        StopAutoScroll()
        return
    }
    
    ; --- 3. TÍCH LŨY QUÃNG ĐƯỜNG DI CHUYỂN TRONG FRAME NÀY ---
    FlingAccumulator += FlingVelocityY * dt
    
    ; --- 4. PHÁT LỆNH CUỘN KHI ĐẠT ĐỦ NGƯỠNG PIXEL ---
    if (Abs(FlingAccumulator) >= PixelsPerScrollStep)
    {
        steps := Floor(Abs(FlingAccumulator) / PixelsPerScrollStep)
        
        ; Phân phối nhịp cuộn mượt mà: Cú hất mạnh cho phép bùng nổ lên tới 8 nấc/nhịp ở đầu rồi giảm dần
        maxSteps := (absV > 8000) ? 8 : (absV > 4000 ? 5 : (absV > 1500 ? 3 : 2))
        if (steps > maxSteps)
            steps := maxSteps
            
        key := (ScrollStyle = 1)
            ? (FlingAccumulator < 0 ? "WheelDown" : "WheelUp")
            : (FlingAccumulator < 0 ? "WheelUp" : "WheelDown")
            
        ; Kiểm tra xem con trỏ chuột hiện tại có đang nằm trong TargetHwnd không
        MouseGetPos, curX, curY, curHwnd
        isCurInside := false
        if (TargetHwnd) {
            if (curHwnd == TargetHwnd || DllCall("IsChild", "Ptr", TargetHwnd, "Ptr", curHwnd)) {
                isCurInside := true
            } else {
                WinGetPos, tX, tY, tW, tH, ahk_id %TargetHwnd%
                if (curX >= tX && curX <= (tX + tW) && curY >= tY && curY <= (tY + tH))
                    isCurInside := true
            }
        }
        
        if (isCurInside) {
            ; Chuột đang ở trong cửa sổ mục tiêu: gửi phím cuộn bình thường
            Loop %steps% {
                Send {Blind}{%key%}
            }
        } else {
            ; Chuột đang ở NGOÀI cửa sổ mục tiêu (do vuốt nhanh ra ngoài rồi thả):
            ; Gửi thông điệp WM_MOUSEWHEEL (0x020A) trực tiếp vào TargetControl/TargetHwnd
            ; kèm tọa độ ban đầu lúc nhấn chuột (TargetStartX, TargetStartY)
            ; Tuyệt đối không làm cuộn cửa sổ nền phía sau!
            wheelDelta := (key = "WheelUp" ? 120 : -120)
            wParam := (wheelDelta << 16) & 0xFFFFFFFF
            lParam := (TargetStartY << 16) | (TargetStartX & 0xFFFF)
            hDest := TargetControl ? TargetControl : TargetHwnd
            Loop %steps% {
                PostMessage, 0x020A, %wParam%, %lParam%,, ahk_id %hDest%
                if (TargetControl && TargetControl != TargetHwnd) {
                    PostMessage, 0x020A, %wParam%, %lParam%,, ahk_id %TargetHwnd%
                }
            }
        }
        FlingAccumulator -= (FlingAccumulator > 0 ? 1 : -1) * (steps * PixelsPerScrollStep)
    }
return

; Hàm dừng cuộn tự động
StopAutoScroll() {
    global AutoScrollActive, FlingVelocityY, FlingAccumulator
    AutoScrollActive := false
    FlingVelocityY := 0
    FlingAccumulator := 0
    SetTimer, AutoScroll, Off
}

; Dừng cuộn tự động khi click bất kỳ nút chuột nào hoặc lăn chuột (chạm để dừng)
; Riêng RButton được xử lý ở Main.ahk để làm phanh hãm mà không mở context menu
#If (GestureScrollEnabled && AutoScrollActive)
~LButton::
~MButton::
~XButton1::
~XButton2::
~WheelUp::
~WheelDown::
    StopAutoScroll()
return
#If