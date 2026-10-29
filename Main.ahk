#Persistent 
#SingleInstance Force
CoordMode, Mouse, Screen
#NoEnv
SendMode, Input
SetWorkingDir, %A_ScriptDir%

; #Warn

;@Ahk2Exe-ExeName GestureMouse2.exe
;@Ahk2Exe-SetName GestureMouse2
;@Ahk2Exe-SetDescription Ứng dụng hỗ trợ cử chỉ chuột
;@Ahk2Exe-SetCompanyName NGUYENTRIAN
;@Ahk2Exe-SetVersion 1.0.0
;@Ahk2Exe-SetCopyright © 2025 NGUYENTRIAN. All rights reserved.
;@Ahk2Exe-Base %A_ScriptDir%\CustomClass.bin

;@Ahk2Exe-SetMainIcon unnamed.ico
;@Ahk2Exe-AddResource unnamed_gray.ico, 311

;@Ahk2Exe-AddResource image\L.ico, 301
;@Ahk2Exe-AddResource image\LD.ico, 302   
;@Ahk2Exe-AddResource image\LU.ico, 303
;@Ahk2Exe-AddResource image\R.ico, 304
;@Ahk2Exe-AddResource image\RD.ico, 305
;@Ahk2Exe-AddResource image\RU.ico, 306
;@Ahk2Exe-AddResource image\2h.ico, 307
;@Ahk2Exe-AddResource image\4h.ico, 308
;@Ahk2Exe-AddResource image\8h.ico, 309
;@Ahk2Exe-AddResource image\10h.ico, 310

; Khai báo biến toàn cục
global MousePath := ""            ; Chuỗi lưu các hướng cử chỉ (L, R, U, D)
global GestureActive := 0         ; Trạng thái kích hoạt cử chỉ ngang
global Direction := ""            ; Hướng di chuyển: "Horizontal" hoặc "Vertical"
global LastY := 0                 ; Vị trí Y trước đó để tính vận tốc
global VelocityY := 0             ; Vận tốc rê chuột theo trục Y (pixel/giây)
global AutoScrollActive := 0      ; Trạng thái tự động cuộn sau khi thả chuột
global MouseStopThreshold := 5    ; Ngưỡng dừng chuột (không dùng trong mã hiện tại)
global LastMouseX := 0            ; Vị trí X cuối cùng cho AutoScroll
global LastMouseY := 0            ; Vị trí Y cuối cùng cho AutoScroll
global AutoScrollStartTime := 0   ; Thời điểm bắt đầu AutoScroll
global LastMoveTime := 0          ; Thời điểm di chuyển cuối cùng
global positionsCount := 0        ; Số lượng điểm đo trong mảng positions
global scrollInterval := 20       ; Khoảng thời gian giữa các lần cuộn tự động (ms)
global totalDeltaY := 0           ; Tổng khoảng cách di chuyển dọc (dùng cho AutoScroll)
global ScrollTriggered := 0       ; Theo dõi trạng thái cuộn bằng bánh xe
global IsGestureHintVisible := 0  ; Trạng thái hiển thị của GestureHint
global LastGestureHintTime := 0   ; Thời điểm cuối cùng hiển thị GestureHint
global Brightness := 0            ; Mặc định trong suốt hoàn toàn (độ sáng 100%)
global GuiOn := false             ; Trạng thái GUI (hiện/ẩn)
global MainHwnd := 0              ; HWND của GUI GestureHint
global isReleasingRButton := 0
global ScrollStyle := 1           ; Phương pháp cuộn: 1 - kéo nội dung lên xuống, 2 - kéo thanh cuộn lên xuống


; Khai báo biến toàn cục LockKeyboard
global isLocked := 0 ; Trạng thái khóa 
global mouseLockEnabled := 0 ; Bật tắt khoá chuột mặc định
global disableAutoLockScreen := 1
global hKeyboardHook := 0 ; Biến lưu hook
global hMouseHook := 0 ; Hook cho chuột
global Buffer := "" ; Biến lưu trữ ký tự đã nhập
global UNLOCK_KEYWORD := "unlock" ; Từ khóa để mở khóa
global KEYWORD_LENGTH := StrLen(UNLOCK_KEYWORD) ; Độ dài từ khóa

; Đọc giá trị ScrollStyle đã lưu từ registry khi script khởi động
RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, ScrollStyle
if (val != "") 
    ScrollStyle := val

;Lấy handle module một lần để tái sử dụng

global hModule
hModule := DllCall("GetModuleHandle", "Ptr", 0)

; Tải và lưu tất cả biểu tượng vào bộ nhớ khi khởi động
global IconHandles := {}  ; Mảng lưu HICON
LoadIcons()  ; Gọi hàm tải biểu tượng

InitGestureScroll()  ; Khởi tạo trạng thái cử chỉ & cuộn từ registry

#Include ToggleGesture.ahk ; Quản lý bật/tắt cử chỉ và cuộn chuột
#Include Menu.ahk ; Menu, UpdateTrayTip, Settings, ShowAbout, ExitMenu
#Include Hotkey.ahk ;AutoScreenLock, Mute
#Include Brightness.ahk
#Include Scroll.ahk ; AutoScroll
#Include LockKeyboard.ahk ; Khóa bàn phím
#Include Volume.ahk
; #Include MinimizeRestore.ahk
; #Include MyToolTip.ahk

; Đăng ký hàm thoát để giải phóng HICON
OnExit("CleanupIcons")

; Hàm tải tất cả biểu tượng vào bộ nhớ
LoadIcons() {
    global hModule, IconHandles
    ; Tạo object iconData cho AutoHotkey v1
    static iconData := Object()
    iconData["L"] := Object("id", 301, "path", "image\L.ico")
    iconData["LD"] := Object("id", 302, "path", "image\LD.ico")
    iconData["LU"] := Object("id", 303, "path", "image\LU.ico")
    iconData["R"] := Object("id", 304, "path", "image\R.ico")
    iconData["RD"] := Object("id", 305, "path", "image\RD.ico")
    iconData["RU"] := Object("id", 306, "path", "image\RU.ico")
    iconData["2h"] := Object("id", 307, "path", "image\2h.ico")
    iconData["4h"] := Object("id", 308, "path", "image\4h.ico")
    iconData["8h"] := Object("id", 309, "path", "image\8h.ico")
    iconData["10h"] := Object("id", 310, "path", "image\10h.ico")

    for gesture, data in iconData {
        if (A_IsCompiled) {
            ; hIcon := DllCall("LoadIcon", "Ptr", hModule, "UInt", data["id"])
            ;Dùng LoadImage để lấy ảnh kích thước 64x64
            hIcon := DllCall("LoadImage", "Ptr", hModule, "UInt", data["id"], "UInt", 1, "Int", 64, "Int", 64, "UInt", 0)
            IconHandles[gesture] := hIcon
        } else {
            IconHandles[gesture] := A_ScriptDir "\" data["path"]
        }
    }
}

; Hàm giải phóng tất cả HICON khi thoát
CleanupIcons() {
    global IconHandles
    if (A_IsCompiled) {
        for gesture, hIcon in IconHandles {
            DllCall("DestroyIcon", "Ptr", hIcon)
        }
    }
    ExitApp
}

; Hàm kiểm tra chuột có nằm trong vùng cửa sổ đang active không
IsMouseInActiveWindow() {
    MouseGetPos, MouseX, MouseY, HoverWindow ; Lấy tọa độ chuột và ID của cửa sổ hover
    WinGetPos, WinX, WinY, WinWidth, WinHeight, A ; Lấy vị trí và kích thước của cửa sổ 
    WinGetClass, HoverClass, ahk_id %HoverWindow% ; Lấy class của cửa sổ hover
    WinGetClass, ActiveClass, A

    ; Loại trừ các class hệ thống (desktop, taskbar, start menu, v.v.)
    if (HoverClass ~= "^(Progman|WorkerW|Shell_TrayWnd|DV2ControlHost|Windows.UI.Core.CoreWindow)$")
        return false

    if (ActiveClass ~= "^(Progman|WorkerW|Shell_TrayWnd|DV2ControlHost|Windows.UI.Core.CoreWindow)$")
        return false

    ; Kiểm tra nếu chuột nằm trong vùng cửa sổ active
    if (MouseX >= WinX && MouseX <= (WinX + WinWidth) && MouseY >= WinY && MouseY <= (WinY + WinHeight)) {
        ; Kiểm tra nếu chuột đang ở Explorer và có file được chọn
        if (HoverClass ~= "^(CabinetWClass|ExploreWClass)$" || ActiveClass = "ShellTabWindowClass1") {
            tab := GetActiveExplorerTab(HoverWindow)
            if (tab && tab.Document.SelectedItems.Count > 0) {
                return false ; Nếu đang ở Explorer và có file được chọn, không kích hoạt cử chỉ
            }
        }
        return true
    }

    return false    
}

; Hàm lấy tab đang hoạt động trong Explorer
GetActiveExplorerTab(hwnd:="") {
    static IID_IShellBrowser := "{000214E2-0000-0000-C000-000000000046}"

    activeTab := 0, hwnd := hwnd ? hwnd : WinExist("A")
    try {
        ControlGet, activeTab, Hwnd,, ShellTabWindowClass1, ahk_id %hwnd% ; File Explorer (Windows 11)
    } catch {
        return false  ; Nếu không tìm thấy tab, thoát hàm.
    }

    ; Trì hoãn việc gọi đối tượng COM để tránh lỗi 0x8001010D
    Sleep, 50

    try {
        for w in ComObjCreate("Shell.Application").Windows {
            if (w.hwnd != hwnd)
                continue
            if (activeTab) { ; The window has tabs, so make sure this is the right one.
                shellBrowser := ComObjQuery(w, IID_IShellBrowser, IID_IShellBrowser)
                DllCall(NumGet(NumGet(shellBrowser+0), 3*A_PtrSize), "UPtr",shellBrowser, "UIntP",thisTab:=0)
                if (thisTab != activeTab)
                    continue
            }
            ; Kiểm tra nếu tab có mục được chọn
            if (w.Document.SelectedItems.Count > 0)
                return w
        }
    } catch {
        return false  ; Nếu xảy ra lỗi, trả về false.
    }

    return false  ; Không tìm thấy tab hoặc không có mục nào được chọn.
}

#If (GestureScrollEnabled && IsMouseInActiveWindow())  ; Chỉ kích hoạt khi đã BẬT cử chỉ/cuộn và chuột nằm trong cửa sổ active
; Khi nhấn chuột phải: Khởi tạo biến và bắt đầu kiểm tra cử chỉ + bánh xe
RButton:: 
    if GetKeyState("LButton", "P") ; Kiểm tra xem nút trái có đang được nhấn giữ không
    {
        return
    }
        
    MousePath := "" 
    GestureActive := 0 
    Direction := ""
    VelocityY := 0
    AutoScrollActive := 0
    totalDeltaY := 0
    ScrollTriggered := 0  ; Reset trạng thái cuộn bánh xe
    MouseGetPos, StartX, StartY   ; Lấy tọa độ ban đầu
    LastY := StartY
    LastMoveTime := A_TickCount   ; Lưu thời điểm bắt đầu
    positionsCount := 0
    Loop, 5                       ; Xóa mảng positions (5 điểm đo vận tốc)
        positions%A_Index%y := "", positions%A_Index%time := ""
    SetTimer, CheckGesture, 15     ; Kiểm tra cử chỉ mỗi 15ms
    return

; Khi thả chuột phải: Xử lý cử chỉ, AutoScroll, hoặc chuột phải mặc định
RButton Up::
    isReleasingRButton := 1     ; Đặt cờ ngay khi bắt đầu xử lý thả chuột
    SetTimer, CheckGesture, Off   ; Tắt kiểm tra cử chỉ

    ; Ẩn mọi tooltip sau khi thả chuột phải
    Tooltip

    ; --- KIỂM TRA ĐIỀU KIỆN ĐỂ KÍCH HOẠT CỬ CHỈ NGANG ---
    if (GestureActive && Direction = "Horizontal") {  ; Nếu có cử chỉ ngang
        PerformGesture(MousePath) ; Thực thi phím tắt tương ứng
        MousePath := "" 
        GestureActive := 0
    } else if (GestureActive && Direction = "Diagonal") {  ; Nếu có cử chỉ chéo
        PerformGesture(MousePath) ; Thực thi phím tắt tương ứng
        MousePath := "" 
        GestureActive := 0
    } else if (!ScrollTriggered && !GestureActive && Direction != "Vertical") {  ; Nếu không có cử chỉ
        Click, Right             ; Thực hiện click phải bình thường
    }
    ScrollTriggered := 0         ; Reset trạng thái cuộn bánh xe
    HideGestureHint()            ; Ẩn hint
    SetTimer, HideGestureHint, -50  ; Kiểm tra sau 50ms nữa để đảm bảo ẩn hint
    
    ; --- KIỂM TRA ĐIỀU KIỆN ĐỂ KÍCH HOẠT AUTOSCROLL ---
    if (Direction = "Vertical" OR !GestureActive) { ; Nếu có cử chỉ dọc và chưa cuộn bánh xe
        TimeSinceLastMove := (A_TickCount - LastMoveTime) / 1000.0  ; Thời gian kể từ lần di chuyển cuối (giây)
        if (Abs(VelocityY) > 50 && totalDeltaY > 20 && TimeSinceLastMove < 0.15) {
            AutoScrollActive := 1
            AutoScrollStartTime := A_TickCount
            LastMouseX := StartX
            LastMouseY := StartY
            SetTimer, AutoScroll, %scrollInterval%  ; Bắt đầu AutoScroll
        }
    }
    isReleasingRButton := 0     ; Reset cờ khi kết thúc xử lý
    return

; Hotkey cho WheelUp khi giữ RButton
~RButton & WheelUp::
    if (GetKeyState("RButton", "P") && GestureActive = 0) {  ; Đảm bảo chuột phải đang được giữ
        Send, {PgUp}
        ScrollTriggered := 1
    }
return

; Hotkey cho WheelDown khi giữ RButton
~RButton & WheelDown::
    if (GetKeyState("RButton", "P") && GestureActive = 0) {  ; Đảm bảo chuột phải đang được giữ
        Send, {PgDn}
        ScrollTriggered := 1
    }
return

#If (!GestureScrollEnabled || !IsMouseInActiveWindow()) 
~RButton:: ; Khi TẮT hoặc ngoài active window: chuột phải hoạt động mặc định
    return

#If ; Kết thúc điều kiện



CheckGesture:
    ; ToolTip, CheckGesture Running: %A_TickCount% ; Thêm dòng này để kiểm tra xem hàm có chạy không
    global isReleasingRButton, ScrollStyle

    ; --- THÊM KIỂM TRA CỜ VÀ TRẠNG THÁI NÚT ---
    if (!GetKeyState("RButton", "P") || isReleasingRButton) ; Nếu nút đã thả HOẶC đang trong quá trình xử lý thả
    {
        SetTimer, CheckGesture, Off
        HideGestureHint()
        return                     ; Thoát ngay lập tức
    }
    ; --- KẾT THÚC KIỂM TRA ---

    MouseGetPos, X, Y            ; Lấy tọa độ chuột hiện tại
    DX := X - StartX             ; Khoảng cách di chuyển ngang
    DY := Y - StartY             ; Khoảng cách di chuyển dọc
    MinMove := 10                ; Ngưỡng di chuyển tối thiểu (pixel)
    DiagonalAngleMin := 30       ; Góc tối thiểu cho cử chỉ chéo (độ)
    DiagonalAngleMax := 70       ; Góc tối đa cho cử chỉ chéo (độ)

    ; Tính tổng khoảng cách di chuyển
    Distance := Sqrt(DX*DX + DY*DY)

    if (Distance > MinMove) {  ; Nếu chuột di chuyển đủ lớn (10 pixel)
        if (Direction = "") {    ; Xác định hướng lần đầu tiên, nếu chưa xác định
            ; Tính góc di chuyển (độ)
            Angle := Abs(ATan(DY / (DX ? DX : 0.0001))) * 180 / 3.14159  ; Tránh chia cho 0
            
            ; Xác định hướng dựa trên góc
            if (Angle >= DiagonalAngleMin && Angle <= DiagonalAngleMax) {
                Direction := "Diagonal"
            } else if (Angle < DiagonalAngleMin) {
                Direction := "Horizontal"
            } else {
                Direction := "Vertical"
            }
            
            ; Debug: Hiển thị hướng
            ToolTip, Hướng: %Direction% (Góc: %Angle%°), %X%, %Y%

        }
        ; --- XỬ LÝ CỬ CHỈ NGANG ---
        if (IsMouseInActiveWindow() && Direction = "Horizontal" && ScrollTriggered = 0) {  ; Xử lý cử chỉ ngang và bánh xe chưa cuộn
            GestureActive := 1
            ; Xác định hướng: R (phải), L (trái), U (lên), D (xuống)
            Dir := (Abs(DX) > Abs(DY)) ? (DX > 0 ? "R" : "L") : (DY > 0 ? "D" : "U")
            ; Lưu chuỗi cũ trước khi thêm
            OldMousePath := MousePath
            if (StrLen(MousePath) = 0 || SubStr(MousePath, -1) != Dir) {
                MousePath .= Dir
                ; Làm sạch MousePath ngay lập tức
                CleanedMousePath := CleanGesture(MousePath)
                ; Chỉ gọi ShowGestureHint nếu cử chỉ thay đổi và thời gian đã đủ lâu 
                if (CleanedMousePath != CleanGesture(OldMousePath) && (A_TickCount - LastGestureHintTime > 30)) { 
                    if (!isReleasingRButton)
                        ShowGestureHint(CleanedMousePath)
                    LastGestureHintTime := A_TickCount
                }
                MousePath := CleanedMousePath  ; Cập nhật MousePath đã làm sạch
            }
            StartX := X
            StartY := Y
        }
        ; --- XỬ LÝ CỬ CHỈ CHÉO ---
        else if (Direction = "Diagonal" && ScrollTriggered = 0) {
            GestureActive := 1
            ; Xác định loại đường chéo cụ thể
            if (DX > 0)
                Dir := (DY < 0) ? "2h" : "4h" ; Đường chéo góc 2h và 4h
            else
                Dir := (DY < 0) ? "10h" : "8h" ; Đường chéo góc 10h và 8h
            OldMousePath := MousePath 
            if (StrLen(MousePath) = 0 || SubStr(MousePath, -1) != Dir) { 
                MousePath .= Dir
                CleanedMousePath := CleanGesture(MousePath)
                if (CleanedMousePath != CleanGesture(OldMousePath) && (A_TickCount - LastGestureHintTime > 30)) { ;
                    if (!isReleasingRButton)
                        ShowGestureHint(CleanedMousePath) ; Cần cập nhật ShowGestureHint
                    LastGestureHintTime := A_TickCount
                }
                MousePath := CleanedMousePath
            }
            StartX := X
            StartY := Y
        }
        
        ; -- XỬ LÝ CỬ CHỈ DỌC ---
        else if (Direction = "Vertical" OR !GestureActive ) {  ; Xử lý cuộn dọc (thủ công) khi không có cử chỉ ngang kích hoạt
            if (DY != 0) {
                ; Lưu vị trí và thời gian để tính vận tốc
                CurrentTime := A_TickCount
                positionsCount := positionsCount < 5 ? positionsCount + 1 : 5 
                if (positionsCount > 1) {  ; Dịch chuyển mảng positions
                    Loop % positionsCount - 1 {
                        idx := A_Index 
                        nextIdx := A_Index + 1
                        positions%idx%y := positions%nextIdx%y
                        positions%idx%time := positions%nextIdx%time
                    }
                }
                positions%positionsCount%y := Y
                positions%positionsCount%time := CurrentTime
                
                ; Tính vận tốc và cuộn thủ công theo hàm logarit
                if (positionsCount >= 2) {
                    firstY := positions1y
                    firstTime := positions1time
                    lastY := positions%positionsCount%y
                    lastTime := positions%positionsCount%time
                    totalDeltaYForVelocity := lastY - firstY ;Khoảng cách di chuyển
                    totalTimeDelta := (lastTime - firstTime) / 1000.0 ; Thời gian (giây)
                    if (totalTimeDelta > 0) {
                        VelocityY := totalDeltaYForVelocity / totalTimeDelta  ; Vận tốc (px/s)
                        AbsVelocityY := Abs(VelocityY)
                        ; Dùng hàm logarit để tính số lần cuộn
                        if (AbsVelocityY > 50) {  ; Ngưỡng tối thiểu 50 px/s
                            scrollAmount := Round(4 * Log(AbsVelocityY) - 8)  ; 2.5 * ln(|VelocityY|) - 8
                            if (scrollAmount < 1)  ; Đảm bảo ít nhất 1 dòng khi vượt ngưỡng
                                scrollAmount := 1
                            if (scrollAmount > 10)  ; Giới hạn tối đa 10 dòng/lần
                                scrollAmount := 10
                            Loop %scrollAmount% {
                                key := (ScrollStyle = 1)
                                    ? (DY < 0 ? "WheelDown" : "WheelUp") ; ScrollStyle = 1 -> kéo nội dung lên xuống
                                    : (DY < 0 ? "WheelUp" : "WheelDown") ; ScrollStyle = 2 -> kéo thanh cuộn lên xuống
                                if (DY != 0)
                                    Send {Blind}{%key%} ; Gửi lệnh cuộn
                            }
                            
                        }
                    }
                }
                LastY := Y
                LastMoveTime := A_TickCount
                totalDeltaY += Abs(DY) ; Tổng khoảng cách di chuyển dọc
            }
            StartX := X  ; Cập nhật cả StartX để tránh lỗi khi chuyển hướng
            StartY := Y
        }
    }
    Sleep 1  ; Độ trễ nhỏ để giảm tải CPU
return

; Hàm loại bỏ ký tự lặp trong chuỗi cử chỉ (ví dụ: "RR" → "R")
CleanGesture(Gesture) {
    CleanedGesture := ""
    LastChar := ""
    Loop, Parse, Gesture
        if (A_LoopField != LastChar) {
            CleanedGesture .= A_LoopField
            LastChar := A_LoopField
        }
    return CleanedGesture
}

; Hàm thực thi phím tắt dựa trên cử chỉ
PerformGesture(Gesture) {
    Gesture := CleanGesture(Gesture)
    if (Gesture = "RU")
        Send ^w           ; Đóng tab (Ctrl+W)
    else if (Gesture = "RD")
        Send ^r           ; Làm mới trang (Ctrl+R)
    else if (Gesture = "LU")
        Send ^+{Tab}      ; Chuyển tab trước (Ctrl+Shift+Tab)
    else if (Gesture = "LD")
        Send ^{Tab}       ; Chuyển tab tiếp (Ctrl+Tab)
    else if (Gesture = "L") {
        ; UnfocusVideo()
        Send !{Left}      ; Quay lại (Alt+Left)
    }
    else if (Gesture = "R") {
        ; UnfocusVideo()
        Send !{Right}     ; Tiến tới (Alt+Right)
    }
    ; Thêm hành động cử chỉ chéo
    ; else if (Gesture = "2h")
    ;     RestoreLastWindow()
    ; else if (Gesture = "8h")
    ;     MinimizeActiveWindow()
    ;Tạm thời không dùng 4h và 10h
    ; else if (Gesture = "4h")
    ; else if (Gesture = "10h")

    HideGestureHint() ; Ẩn hint sau khi thực hiện cử chỉ
}

UnfocusVideo() {
    WinGet, ActiveProcess, ProcessName, A
    BrowserList := ["chrome.exe", "firefox.exe", "msedge.exe", "opera.exe", "vivaldi.exe", "brave.exe"]
    for index, browser in BrowserList {
        if (ActiveProcess = browser) {
            if (browser = "vivaldi.exe")
                Send ^l
            else if (browser = "firefox.exe")
                Send {F6}
            else
                Send !d ; Focus vào thanh địa chỉ
            Sleep 100 
            ; Send {Left} ;Bỏ highlight URL
            ; Sleep 50
        }
    }
}
; Hàm hiển thị hint cho cử chỉ ngang
ShowGestureHint(Gesture) {
    Global IconHandles, IsGestureHintVisible, LastGestureHintTime, MainHwnd, GestureIcon, GestureText
    Gesture := CleanGesture(Gesture)
    
    ; --- KHỐI KHỞI TẠO HÌNH ẢNH VÀ TEXT ---
    static hintImages := ""
    static hintTexts := ""
    if (hintImages = "") {
        hintImages := Object()
        hintTexts := Object()
        hintImages["L"] := "L" ; Key ánh xạ tới HICON trong IconHandles
        hintImages["LD"] := "LD" 
        hintImages["LU"] := "LU"  
        hintImages["R"] := "R"  
        hintImages["RD"] := "RD" 
        hintImages["RU"] := "RU"
        hintTexts["RU"] := "Đóng tab"
        hintTexts["RD"] := "Làm mới trang"
        hintTexts["LU"] := "Chuyển tab trước đó"
        hintTexts["LD"] := "Chuyển tab tiếp theo"
        hintTexts["L"] := "Quay lại"
        hintTexts["R"] := "Tiến tới"

        ; Thêm ánh xạ cho các cử chỉ chéo
        hintImages["2h"] := "2h" ; Key ánh xạ tới HICON trong IconHandles
        ; hintImages["4h"] := "4h"
        hintImages["8h"] := "8h"
        ; hintImages["10h"] := "10h"
        hintTexts["2h"] := "Phục hồi`ncửa sổ"
        ; hintTexts["4h"] := "Thu nhỏ`ncửa sổ"
        hintTexts["8h"] := "Thu nhỏ`ncửa sổ"
        ; hintTexts["10h"] := "Cử chỉ chéo 10h"
    }
    ; --- KẾT THÚC KHỐI KHỞI TẠO ---

    ; Lấy HICON và Text tương ứng
    ImageKey := hintImages[Gesture]
    hIcon := IconHandles[ImageKey]
    CurrentText := hintTexts[Gesture]

    ; --- KIỂM TRA VÀ TẠO GUI LẦN ĐẦU HOẶC CẬP NHẬT ---
    if (IsGestureHintVisible and MainHwnd) { ; Nếu GUI đã hiển thị -> Chỉ cập nhật nội dung
        if (ImageKey && CurrentText) { ; Cử chỉ hợp lệ
            ; Hiển thị lại Icon nếu nó đang bị ẩn
            GuiControl, GestureHint:Show, GestureIcon
            ; Cập nhật hình ảnh
            if (A_IsCompiled) {
                hIconCopy := DllCall("CopyIcon", "Ptr", hIcon)
                GuiControl, GestureHint:, GestureIcon, *Icon HICON:%hIconCopy%
            } else {
                GuiControl, GestureHint:, GestureIcon, %hIcon%
            }
            ; Cập nhật Text
            GuiControl, GestureHint:, GestureText, %CurrentText%
        } else { ; Cử chỉ không hợp lệ
            GuiControl, GestureHint:Hide, GestureIcon ; Ẩn Icon
            GuiControl, GestureHint:, GestureText, Cử chỉ không đúng ; Cập nhật Text
            GuiControl, GestureHint:Move, GestureText, x10 y30 w100 h140 Center ; Căn giữa Text

        }
    } else { ; Nếu GUI chưa hiển thị hoặc chưa được tạo -> Tạo mới
        ; Kích thước và vị trí
        GuiWidth := 150, GuiHeight := 140
        CenterX := (A_ScreenWidth  - GuiWidth) / 2
        CenterY := (A_ScreenHeight  - GuiHeight) / 2

        ; Tạo GUI chính - Chỉ tạo một lần
        Gui, GestureHint:New, +LastFound +AlwaysOnTop -Caption +E0x08000000 +HwndMainHwnd
        Gui, GestureHint:Color, 010101  ;1A1A1A là màu cũ
        Gui, GestureHint:Font, s12 Bold, Arial
        Winset, Transparent, 220

        ; Thêm các control với tên biến (v-option)
        if (ImageKey && CurrentText) { ; Cử chỉ hợp lệ ban đầu
            if (A_IsCompiled) {
                hIconCopy := DllCall("CopyIcon", "Ptr", hIcon)
                Gui, GestureHint:Add, Picture, w64 h64 x28 y5 vGestureIcon, HICON:%hIconCopy% 
                DllCall("DestroyIcon", "Ptr", hIconCopy)
            } else {
                Gui, GestureHint:Add, Picture, w64 h64 x28 y5 vGestureIcon, %hIcon% 
            }
            Gui, GestureHint:Add, Text, cFFFFFF x10 y64 w100 h140 Center vGestureText, %CurrentText% 
        } else { ; Cử chỉ không hợp lệ ban đầu
            Gui, GestureHint:Add, Picture, vGestureIcon Hidden 
            Gui, GestureHint:Add, Text, cFFFFFF x10 y30 w100 Center vGestureText, Cử chỉ không đúng
        }

        WinSet, Region, 0-0 w150 h140 R45-45  ; Bo tròn góc
        Gui, GestureHint:Show, x%CenterX%y%CenterY%w%GuiWidth%h%GuiHeight% NoActivate
        ; WinSet, TransColor, 1A1A1A 200, ahk_id %MainHwnd% ; 200 là mức độ đục (0-255), bạn có thể chỉnh

        IsGestureHintVisible := 1
    }
}

; Hàm ẩn hint
HideGestureHint() {
    global IsGestureHintVisible, MainHwnd
    if (MainHwnd)
        Gui, GestureHint:Hide 
    IsGestureHintVisible := 0
}
