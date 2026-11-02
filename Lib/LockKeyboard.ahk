#SingleInstance, force
#NoEnv
#Persistent

#Include *i Language.ahk

SetBatchLines -1 ; Tăng tốc độ thực thi script

; Phím tắt Ctrl+Alt+L để khóa/mở khóa bàn phím
LockKeyboard:
    ^!l::
    KeyWait, Ctrl ; don't block Ctrl key-up
    KeyWait, Alt  ; or Alt key-up
    KeyWait, l    ; or l-up
    ToggleLock()
return

;tạo 1 hàm hiển thị gui thông báo để dễ dàng gọi lại
ShowNotification() {
    global isLocked, mouseLockEnabled

    msg := isLocked ? L("Lock_Locked") : L("Lock_Unlocked")
    if (mouseLockEnabled)
        msg .= L("Lock_AndMouse")
    
    ; Lấy chiều cao của taskbar
    if (WinExist("ahk_class Shell_TrayWnd")) ; Nếu taskbar đang chạy thì lấy chiều cao của nó 
        WinGetPos,,,,hTaskbar, ahk_class Shell_TrayWnd
    else
        hTaskbar := 60 ; Mặc định là 60px nếu không tìm thấy taskbar

    ;Hủy timer và GUI thông báo trước đó nếu còn tồn tại
    SetTimer, HideNotification, Off
    Gui, Notification:Destroy

    ; Tạo GUI tạm để đo kích thước text
    Gui, Notification:New, +AlwaysOnTop +ToolWindow -Caption +LastFound
    Gui, Font, s11, Segoe UI
    Gui, Color, FFFFCB
    Gui, Add, Text, Center , %msg%
    Gui, Show, Hide
    WinGetPos, , , GuiWidth, GuiHeight
 
    ; Tính vị trí góc phải dưới
    posX := A_ScreenWidth - GuiWidth - 5
    posY := A_ScreenHeight - GuiHeight - hTaskbar - 5
    
    ; Tạo GUI thông báo
    Gui, Show, x%posX% y%posY% NoActivate
    WinSet, Transparent , 220
    WinSet, Region, 0-0 w%GuiWidth% h%GuiHeight% R15-15  ; Bo tròn góc

    fnTip := "UpdateTrayTip"
    if (IsFunc(fnTip))
        %fnTip%()

    if (!isLocked) {
        SetTimer, HideNotification, -2000
    }
    return
    
    HideNotification:
        Gui, Notification:Destroy
    return
}


; Hàm bật/tắt khóa bàn phím
ToggleLock() {
    global isLocked, hKeyboardHook, hMouseHook
    if (isLocked) {
        UnlockKeyboard()
    } else {
        isLocked := 1 ; Đặt trạng thái khóa bàn phím thành 1 (đã khóa)

        ;Đọc từ Registry, nếu có thì gán lại cho mouseLockEnabled. Nếu Registry không có key, thì mouseLockEnabled giữ nguyên giá trị toàn cục đã khai báo trước đó.
        RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, mouseLockEnabled 
        if (val != "") 
            mouseLockEnabled := val


        RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, disableAutoLockScreen
        if (val != "")
            disableAutoLockScreen := val
        
        ; Cài đặt low-level keyboard hook
        hKeyboardHook := DllCall("SetWindowsHookEx", "Int", 13, "Ptr", RegisterCallback("KeyboardProc", "Fast"), "Ptr", DllCall("GetModuleHandle", "Ptr", 0, "Ptr"), "UInt", 0, "Ptr")
        if (!hKeyboardHook) {
            MsgBox, % L("Lock_HookError")
            isLocked := 0
            return
        }

        ; Điều kiện bật khoá chuột
        if(mouseLockEnabled) {
            hMouseHook := DllCall("SetWindowsHookEx", "Int", 14, "Ptr", RegisterCallback("MouseProc", "Fast"), "Ptr", DllCall("GetModuleHandle", "Ptr", 0, "Ptr"), "UInt", 0, "Ptr")
            if (!hMouseHook) {
                DllCall("UnhookWindowsHookEx", "Ptr", hKeyboardHook)
                hKeyboardHook := 0
                isLocked := 0
                return
            }
        }

        ; Ngăn khóa màn hình và screensaver
        if (disableAutoLockScreen)
        DllCall("SetThreadExecutionState", "UInt", 0x80000003) ; ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED

        ; Menu, Tray, Tip, Bàn phím đã khóa`nGõ %UNLOCK_KEYWORD% để mở khóa
        ShowNotification()
        return
    }
}

; Hàm mở khóa bàn phím
UnlockKeyboard() {
    global isLocked, hKeyboardHook, Buffer, hMouseHook
    
    if (!isLocked) ; Nếu bàn phím không bị khóa, không làm gì cả và kết thúc hàm
        return
        
    isLocked := 0
    Buffer := "" ; Xóa buffer 
    
    ; Gỡ hook
    if (hKeyboardHook) {
        DllCall("UnhookWindowsHookEx", "Ptr", hKeyboardHook)
        hKeyboardHook := 0 
    }
    if (hMouseHook) {
        DllCall("UnhookWindowsHookEx", "Ptr", hMouseHook)
        hMouseHook := 0 
    }

    ; Khôi phục trạng thái hệ thống (cho phép khóa màn hình)
    DllCall("SetThreadExecutionState", "UInt", 0x80000000) ; ES_CONTINUOUS
    
    ToolTip, ; Xóa tooltip
    ShowNotification()
    fnTip := "UpdateTrayTip"
    if (IsFunc(fnTip))
        %fnTip%()
}

; Hàm xử lý low-level keyboard hook, mục tiêu là chặn các phím khác khi bàn phím bị khóa
; và theo dõi các ký tự để mở khóa
KeyboardProc(nCode, wParam, lParam) {
    global isLocked, Buffer, UNLOCK_KEYWORD, KEYWORD_LENGTH
    Critical ; Đảm bảo không có sự kiện khác xảy ra trong khi xử lý hook
    
    if (nCode < 0) ; Nếu nCode < 0, phải gọi hook tiếp theo
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)

    ; Lấy mã phím từ lParam (cấu trúc KBDLLHOOKSTRUCT)
    ; xác định phím nào đang được nhấn (ASCII)
    ; scanCode là mã scan của phím (tương ứng với vị trí trên bàn phím vật lý)
    ; flags là các bit biểu thị trạng thái của phím (ví dụ: Shift, Alt, Control)
    vkCode := NumGet(lParam+0, 0, "UInt")
    scanCode := NumGet(lParam+0, 4, "UInt")
    flags := NumGet(lParam+0, 8, "UInt")
    
    ; Chỉ xử lý khi phím được nhấn xuống (không phải nhả ra)
    isKeyDown := (wParam = 0x100 || wParam = 0x104) ; WM_KEYDOWN hoặc WM_SYSKEYDOWN

    if (isLocked && isKeyDown) {
        ; Kiểm tra nếu là phím Windows (VK_LWIN = 0x5B, VK_RWIN = 0x5C)
        ; if (vkCode = 0x5B || vkCode = 0x5C) {
        ;     ; Cho phép phím Windows hoạt động bình thường
        ;     return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
        ; }
        
        ; Chuyển đổi mã phím thành ký tự
        ; Tạo buffer để nhận ký tự
        VarSetCapacity(keyState, 256, 0) 
        VarSetCapacity(outBuff, 4, 0)
        DllCall("GetKeyboardState", "Ptr", &keyState)
        kbLayout := DllCall("GetKeyboardLayout", "UInt", 0, "Ptr")

        ; Chuyển đổi mã phím thành ký tự
        result := DllCall("ToUnicodeEx", "UInt", vkCode, "UInt", scanCode, "Ptr", &keyState, "Ptr", &outBuff, "Int", 2, "UInt", 0, "Ptr", kbLayout)
        
        ; Nếu chuyển đổi thành công
        if (result > 0) {
            char := StrGet(&outBuff, result, "UTF-16")
            Buffer .= char             ; Thêm ký tự vào buffer

            ; ToolTip, Buffer: %Buffer%, 100, 100 ;Hiện tooltip từ đã gõ (buffer)
            
            ; Kiểm tra nếu buffer chứa từ khóa "unlock"
            if (StrLen(Buffer) >= KEYWORD_LENGTH) {
                lastChars := SubStr(Buffer, -KEYWORD_LENGTH + 1)
                
                ; Nếu khớp với từ khóa, mở khóa bàn phím
                if (lastChars = UNLOCK_KEYWORD) {
                    SetTimer, DelayedUnlock, -1 ; Trì hoãn mở khóa
                    return 1 ; Chặn ký tự cuối cùng
                }
            }
        }
        
        ; Giới hạn kích thước buffer để tránh tràn bộ nhớ
        if (StrLen(Buffer) > 50)
            Buffer := SubStr(Buffer, -30)
            
        return 1 ; Chặn phím
    }
    
    ; Gọi hook tiếp theo nếu bàn phím không bị khóa
    return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
}

; Hàm trì hoãn mở khóa
DelayedUnlock:
    UnlockKeyboard()
return

MouseProc(nCode, wParam, lParam) {
    global isLocked
    Critical ; Đảm bảo không có sự kiện khác xảy ra trong khi xử lý hook
    
    if (isLocked && nCode >= 0) {  
        ; Kiểm tra loại sự kiện chuột
        switch wParam {
            case 0x0200, 0x020A, 0x020E: ; WM_MOUSEMOVE(0x200), WM_MOUSEWHEEL(0x020A), WM_MOUSEHWHEEL(0x020E)
                return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam) ; Cho phép di chuyển và wheel
            default:
                return 1 ; Chặn các phím khác bằng cách trả về 1    
        }
    }
    
    return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
}

; Dọn dẹp khi thoát script
OnExit("Cleanup") 
Cleanup() {
    global hKeyboardHook , hMouseHook
    if (hKeyboardHook)
        DllCall("UnhookWindowsHookEx", "Ptr", hKeyboardHook)
    if (hMouseHook)
        DllCall("UnhookWindowsHookEx", "Ptr", hMouseHook)
    DllCall("SetThreadExecutionState", "UInt", 0x80000000) ; Reset execution state to allow screen locking and sleep
}