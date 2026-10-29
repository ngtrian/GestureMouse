; Scroll.ahk - Xử lý cuộn tự động với phương pháp mũ
#NoEnv

; Khai báo biến toàn cục (được chia sẻ với Main.ahk)
global VelocityY
global AutoScrollActive
global MouseStopThreshold
global LastMouseX
global LastMouseY
global AutoScrollStartTime
global scrollInterval

AutoScroll:
    if (!AutoScrollActive)
    {
        SetTimer, AutoScroll, Off
        return
    }
    
    MouseGetPos, CurrentMouseX, CurrentMouseY
    DeltaMouseX := CurrentMouseX - LastMouseX
    DeltaMouseY := CurrentMouseY - LastMouseY
    MouseMoveDistance := Sqrt(DeltaMouseX**2 + DeltaMouseY**2)
    
    CurrentTime := A_TickCount
    ElapsedTime := (CurrentTime - AutoScrollStartTime) / 1000.0
    
    ; Dừng nếu chuột di chuyển quá ngưỡng sau 0.5 giây
    if (ElapsedTime > 0.5 && MouseMoveDistance > MouseStopThreshold)
    {
        AutoScrollActive := false
        SetTimer, AutoScroll, Off
        return
    }
    
    LastMouseX := CurrentMouseX
    LastMouseY := CurrentMouseY
    
    ; Giảm vận tốc dần dần với ma sát động
    friction := 0.95 - (Abs(VelocityY) / 20000)
    VelocityY *= friction

    ; Dừng nếu vận tốc quá nhỏ
    if (Abs(VelocityY) < 2)
    {
        AutoScrollActive := false
        SetTimer, AutoScroll, Off
        return
    }
    
    ; Tính số lần cuộn theo phương pháp mũ
    scrollAmount := Max(1, Floor((Abs(VelocityY) / 100) ** 1.5))
    scrollAmount := Min(10, scrollAmount)  ; Giới hạn tối đa để tránh cuộn quá nhanh
    
    ; Gửi lệnh cuộn
    Loop %scrollAmount% {
        key := (ScrollStyle = 1)
            ? (VelocityY  < 0 ? "WheelDown" : "WheelUp") ; ScrollStyle = 1 - Kéo nội dung lên xuống
            : (VelocityY  < 0 ? "WheelUp" : "WheelDown") ; ScrollStyle = 2 - Kéo thanh cuộn lên xuống
        if (DY != 0)
            Send {Blind}{%key%}
    }
return

; #If (AutoScrollActive) ; Chỉ kích hoạt khi cuộn tự động đang hoạt động
; LButton::
;     AutoScrollActive := false
;     SetTimer, AutoScroll, Off
;     Send {LButton up} ; Đảm bảo nút chuột phải không bị giữ lại
;     return
; #If