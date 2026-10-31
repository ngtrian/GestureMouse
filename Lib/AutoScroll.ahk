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

AutoScroll:
    if (!AutoScrollActive)
    {
        SetTimer, AutoScroll, Off
        return
    }
    
    CurrentTick := A_TickCount
    dt := (CurrentTick - LastFlingTick) / 1000.0
    LastFlingTick := CurrentTick
    
    ; Giới hạn dt an toàn đề phòng timer bị delay đột ngột
    if (dt <= 0 || dt > 0.1)
        dt := 0.016
    
    ; 1. Áp dụng ma sát suy giảm theo thời gian (Exponential Deceleration)
    ; Hệ số ma sát động: ở tốc độ cao ma sát thấp (0.965) giúp trôi dài và mượt;
    ; ở tốc độ thấp ma sát tăng dần (0.940) giúp dừng dứt khoát và êm ái như trên điện thoại.
    baseFriction := (Abs(FlingVelocityY) > 500) ? 0.965 : 0.940
    frictionFactor := baseFriction ** (dt / 0.016)
    FlingVelocityY *= frictionFactor
    
    ; 2. Dừng nếu vận tốc đã giảm xuống dưới ngưỡng tối thiểu (40 px/s)
    if (Abs(FlingVelocityY) < 40)
    {
        StopAutoScroll()
        return
    }
    
    ; 3. Tích lũy quãng đường di chuyển trong frame này
    FlingAccumulator += FlingVelocityY * dt
    
    ; 4. Phát lệnh cuộn khi đạt đủ ngưỡng pixel
    if (Abs(FlingAccumulator) >= PixelsPerScrollStep)
    {
        steps := Floor(Abs(FlingAccumulator) / PixelsPerScrollStep)
        if (steps > 8)  ; Cho phép tối đa 8 nấc mỗi tick khi vuốt cực nhanh
            steps := 8
            
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
#If (AutoScrollActive)
~LButton::
~RButton::
~MButton::
~XButton1::
~XButton2::
~WheelUp::
~WheelDown::
    StopAutoScroll()
return
#If