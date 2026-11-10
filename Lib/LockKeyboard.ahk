#SingleInstance, force
#NoEnv
#Persistent

#Include *i Language.ahk

SetBatchLines -1 ; Tăng tốc độ thực thi script

; ========================================================
; KHAI BÁO BIẾN TOÀN CỤC CHO HỆ THỐNG KHÓA NÂNG CAO
; ========================================================
global isLocked                 := 0         ; Trạng thái khóa (1: Đang khóa, 0: Mở)
global lockMode                 := 0         ; 0: Toàn diện (Full Lock), 1: Focus Lock (Chỉ cửa sổ hiện tại)
global hFocusWnd                := 0         ; HWND cửa sổ đang được Focus Lock
global focusWndTitle            := ""        ; Tiêu đề cửa sổ Focus Lock
global lockKeyboardEnabled      := 1         ; Bật/tắt khóa bàn phím
global mouseLockEnabled         := 1         ; Bật/tắt khóa chuột tổng quát
global lockMouseClick           := 1         ; Khóa các click chuột (Trái, Phải, Giữa, XButton)
global lockMouseWheel           := 0         ; Khóa con lăn chuột
global lockMouseMove            := 0         ; Khóa cứng / Đóng băng con trỏ chuột
global allowMouseMove           := 1         ; Cho phép rê chuột khi chỉ chặn click
global allowMouseWheel          := 0         ; Cho phép cuộn con lăn chuột khi chuột bị khóa
global allowSpace               := 0         ; Ngoại lệ: Cho phép phím Space (Xem phim / Pause)
global allowMedia               := 0         ; Ngoại lệ: Cho phép các phím âm lượng / media
global allowNav                 := 0         ; Ngoại lệ: Cho phép các phím mũi tên, Enter, Esc
global autoLockIdleEnabled      := 1         ; Tự động khóa khi không dùng máy (Thiết lập sẵn, 1: Bật, 0: Tắt)
global autoLockIdleMinutes      := 5         ; Số phút rảnh rỗi trước khi tự động khóa
global scheduledLockEnabled     := 0         ; Hẹn giờ tự động khóa (Hoạt động độc lập)
global scheduledLockMinutes     := 0         ; Khoảng thời gian hẹn giờ khóa (0: Tắt)
global scheduledLockTargetTick  := 0         ; Thời điểm sẽ kích hoạt hẹn giờ khóa
global requireWindowsPassword   := 0         ; Cho phép mở khóa bằng xác thực tài khoản Windows (Ctrl + Alt + L)
global UNLOCK_KEYWORD           := "unlock"  ; Từ khóa mở khóa cốt lõi mặc định
global KEYWORD_LENGTH           := StrLen(UNLOCK_KEYWORD)
global disableAutoLockScreen    := 1         ; Ngăn tắt màn hình khi đang khóa
global hKeyboardHook            := 0         ; Handle của Keyboard Hook
global hMouseHook               := 0         ; Handle của Mouse Hook
global Buffer                   := ""        ; Buffer lưu các ký tự đã nhập khi khóa
global hAuthGui                 := 0         ; HWND hộp thoại xác thực Windows

; Tải cấu hình khi nạp file
LoadLockSettings()
InitAutoLockTimer()

; ========================================================
; PHÍM TẮT KHÓA / MỞ KHÓA
; ========================================================
#If (GestureScrollEnabled)
LockKeyboard:
    ^!l::
    KeyWait, Ctrl ; Tránh kẹt trạng thái nhả phím
    KeyWait, Alt
    KeyWait, l
    ToggleLock()
return
#If

; ========================================================
; HÀM TẢI CẤU HÌNH TỪ REGISTRY
; ========================================================
LoadLockSettings() {
    global

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, LockMode
    lockMode := (val != "") ? val : 0

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, LockKeyboard
    lockKeyboardEnabled := (val != "") ? val : 1

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, mouseLockEnabled
    mouseLockEnabled := (val != "") ? val : 1

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, LockMouseClick
    lockMouseClick := (val != "") ? val : 1

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, LockMouseWheel
    lockMouseWheel := (val != "") ? val : 0

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, LockMouseMove
    lockMouseMove := (val != "") ? val : 0

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AllowMouseMove
    allowMouseMove := (val != "") ? val : 1

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AllowMouseWheel
    allowMouseWheel := (val != "") ? val : 0

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AllowSpace
    allowSpace := (val != "") ? val : 0

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AllowMedia
    allowMedia := (val != "") ? val : 0

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AllowNav
    allowNav := (val != "") ? val : 0

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AutoLockIdleEnabled
    autoLockIdleEnabled := (val != "") ? val : 1

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AutoLockIdleMinutes
    if (val != "")
        autoLockIdleMinutes := val
    else {
        ; Tương thích ngược nếu trước đó lưu AutoLockMinutes
        RegRead, valOld, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AutoLockMinutes
        autoLockIdleMinutes := (valOld != "") ? valOld : 5
    }

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, ScheduledLockEnabled
    scheduledLockEnabled := (val != "") ? val : 0

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, ScheduledLockMinutes
    scheduledLockMinutes := (val != "") ? val : 0
    if (scheduledLockEnabled && scheduledLockMinutes > 0)
        scheduledLockTargetTick := A_TickCount + (scheduledLockMinutes * 60 * 1000)
    else
        scheduledLockTargetTick := 0

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, RequireWindowsPassword
    if (val != "")
        requireWindowsPassword := val
    else {
        RegRead, valW, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, EnableWindowsAuth
        requireWindowsPassword := (valW != "") ? valW : 0
    }

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, UnlockKeyword
    if (val != "")
        UNLOCK_KEYWORD := val
    else if (!UNLOCK_KEYWORD)
        UNLOCK_KEYWORD := "unlock"
    KEYWORD_LENGTH := StrLen(UNLOCK_KEYWORD)

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, disableAutoLockScreen
    disableAutoLockScreen := (val != "") ? val : 1
}

; ========================================================
; HÀM KHỞI TẠO VÀ THEO DÕI 2 KIỂU TỰ ĐỘNG KHÓA
; ========================================================
InitAutoLockTimer() {
    global autoLockIdleEnabled, autoLockIdleMinutes, scheduledLockEnabled, scheduledLockMinutes
    if ((autoLockIdleEnabled && autoLockIdleMinutes > 0) || (scheduledLockEnabled && scheduledLockMinutes > 0))
        SetTimer, CheckAutoLockDual, 4000
    else
        SetTimer, CheckAutoLockDual, Off
}

CheckAutoLockDual:
    if (isLocked)
        return

    ; Kiểu 1: Hẹn giờ tự động khóa sau khoảng thời gian chỉ định (hoạt động độc lập)
    if (scheduledLockEnabled && scheduledLockMinutes > 0 && scheduledLockTargetTick > 0) {
        if (A_TickCount >= scheduledLockTargetTick) {
            ; Đã tới hạn hẹn giờ -> Kích hoạt khóa
            ToggleLock(1)
            ; Đặt lại mốc tiếp theo nếu người dùng muốn duy trì chu kỳ
            scheduledLockTargetTick := A_TickCount + (scheduledLockMinutes * 60 * 1000)
            return
        }
    }

    ; Kiểu 2: Tự động khóa khi rảnh rỗi không dùng máy (thiết lập sẵn, hoạt động độc lập)
    if (autoLockIdleEnabled && autoLockIdleMinutes > 0) {
        idleSeconds := A_TimeIdlePhysical // 1000
        thresholdSec := autoLockIdleMinutes * 60
        if (idleSeconds >= thresholdSec) {
            ToggleLock(1)
            return
        }
    }
return

; ========================================================
; HÀM HIỂN THỊ THÔNG BÁO TRỰC QUAN (TOAST)
; ========================================================
ShowNotification() {
    global isLocked, lockMode, focusWndTitle

    if (isLocked) {
        if (lockMode == 1 && focusWndTitle != "") {
            shortTitle := SubStr(focusWndTitle, 1, 35) . (StrLen(focusWndTitle) > 35 ? "..." : "")
            msg := "🎯  " . L("Lock_NotificationFocus") . shortTitle
        } else {
            msg := "🔒  " . L("Lock_NotificationFull")
        }
    } else {
        msg := "✔  " . L("Lock_Unlocked")
    }

    ; Lấy chiều cao taskbar để căn vị trí
    hTaskbar := 60
    if (WinExist("ahk_class Shell_TrayWnd"))
        WinGetPos,,,,hTaskbar, ahk_class Shell_TrayWnd

    SetTimer, HideNotification, Off
    Gui, Notification:Destroy

    Gui, Notification:New, +AlwaysOnTop +ToolWindow -Caption +LastFound
    Gui, Font, s10.5 Bold, Segoe UI
    Gui, Color, FFF9C4, 2B1E00 ; Nền vàng nhạt nổi bật, chữ nâu sẫm dễ đọc
    Gui, Font, c2B1E00
    Gui, Add, Text, Center, %msg%
    Gui, Show, Hide
    WinGetPos, , , GuiWidth, GuiHeight

    posX := A_ScreenWidth - GuiWidth - 16
    posY := A_ScreenHeight - GuiHeight - hTaskbar - 16

    Gui, Show, x%posX% y%posY% NoActivate
    WinSet, Transparent, 240
    WinSet, Region, 0-0 w%GuiWidth% h%GuiHeight% R12-12

    fnTip := "UpdateTrayTip"
    if (IsFunc(fnTip))
        %fnTip%()

    ; Khi đang khóa: LUÔN HIỆN để người dùng biết máy đang khóa
    ; Khi mở khóa: tự tắt sau 2.5 giây
    if (!isLocked) {
        SetTimer, HideNotification, -2500
    }
    return

HideNotification:
    Gui, Notification:Destroy
return
}

; ========================================================
; HÀM BẬT / TẮT KHÓA (TOGGLE LOCK)
; ========================================================
ToggleLock(forceState := -1) {
    global isLocked, hKeyboardHook, hMouseHook, lockMode, hFocusWnd, focusWndTitle
    global lockKeyboardEnabled, mouseLockEnabled, disableAutoLockScreen

    LoadLockSettings()

    targetState := (forceState != -1) ? forceState : (!isLocked)

    if (!targetState) {
        UnlockKeyboard()
        return
    }

    ; Bắt đầu kích hoạt khóa
    isLocked := 1
    Buffer := ""

    ; Xử lý Focus Lock
    if (lockMode == 1) {
        hFocusWnd := WinExist("A")
        if (hFocusWnd) {
            WinGetTitle, focusWndTitle, ahk_id %hFocusWnd%
            WinGetPos, fX, fY, fW, fH, ahk_id %hFocusWnd%
            if (fW > 0 && fH > 0) {
                VarSetCapacity(rect, 16, 0)
                NumPut(fX, rect, 0, "Int")
                NumPut(fY, rect, 4, "Int")
                NumPut(fX + fW, rect, 8, "Int")
                NumPut(fY + fH, rect, 12, "Int")
                DllCall("ClipCursor", "Ptr", &rect)
            }
        } else {
            lockMode := 0
        }
    } else {
        hFocusWnd := 0
        focusWndTitle := ""
    }

    ; Cài đặt Keyboard Hook
    if (!hKeyboardHook) {
        hKeyboardHook := DllCall("SetWindowsHookEx", "Int", 13
            , "Ptr", RegisterCallback("KeyboardProc", "Fast")
            , "Ptr", DllCall("GetModuleHandle", "Ptr", 0, "Ptr")
            , "UInt", 0, "Ptr")
        if (!hKeyboardHook) {
            MsgBox, 16, GestureMouse, % L("Lock_HookError")
            isLocked := 0
            return
        }
    }

    ; Cài đặt Mouse Hook
    if (!hMouseHook && (mouseLockEnabled || lockMode == 1)) {
        hMouseHook := DllCall("SetWindowsHookEx", "Int", 14
            , "Ptr", RegisterCallback("MouseProc", "Fast")
            , "Ptr", DllCall("GetModuleHandle", "Ptr", 0, "Ptr")
            , "UInt", 0, "Ptr")
    }

    ; Ngăn Windows tự tắt màn hình / sleep khi đang khóa
    if (disableAutoLockScreen)
        DllCall("SetThreadExecutionState", "UInt", 0x80000003)

    ShowNotification()
}

; ========================================================
; HÀM MỞ KHÓA THIẾT BỊ (UNLOCK)
; ========================================================
UnlockKeyboard() {
    global isLocked, hKeyboardHook, hMouseHook, Buffer, hAuthGui

    if (!isLocked)
        return

    isLocked := 0
    Buffer := ""

    ; Giải phóng nhốt chuột (ClipCursor)
    DllCall("ClipCursor", "Ptr", 0)

    ; Gỡ các Hooks
    if (hKeyboardHook) {
        DllCall("UnhookWindowsHookEx", "Ptr", hKeyboardHook)
        hKeyboardHook := 0
    }
    if (hMouseHook) {
        DllCall("UnhookWindowsHookEx", "Ptr", hMouseHook)
        hMouseHook := 0
    }

    ; Đóng hộp thoại xác thực nếu đang mở
    if (hAuthGui && WinExist("ahk_id " . hAuthGui)) {
        Gui, WinAuthPrompt:Destroy
        hAuthGui := 0
    }

    ; Khôi phục trạng thái quản lý nguồn điện của hệ thống
    DllCall("SetThreadExecutionState", "UInt", 0x80000000)

    ShowNotification()

    fnTip := "UpdateTrayTip"
    if (IsFunc(fnTip))
        %fnTip%()
}

; ========================================================
; XỬ LÝ LOW-LEVEL KEYBOARD HOOK
; ========================================================
KeyboardProc(nCode, wParam, lParam) {
    global isLocked, Buffer, UNLOCK_KEYWORD, KEYWORD_LENGTH, requireWindowsPassword, hAuthGui
    global lockMode, hFocusWnd, lockKeyboardEnabled, allowSpace, allowMedia, allowNav
    Critical

    if (nCode < 0 || !isLocked)
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)

    ; ĐẶC BIỆT: Nếu cửa sổ nhập mật khẩu Windows đang hiển thị và active -> CHO PHÉP gõ phím bình thường
    if (hAuthGui && WinActive("ahk_id " . hAuthGui)) {
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
    }

    vkCode   := NumGet(lParam+0, 0, "UInt")
    scanCode := NumGet(lParam+0, 4, "UInt")
    flags    := NumGet(lParam+0, 8, "UInt")
    isKeyDown := (wParam = 0x100 || wParam = 0x104) ; WM_KEYDOWN hoặc WM_SYSKEYDOWN
    isAltDown := (flags & 0x20)

    ; 1. Xử lý Focus Lock
    if (lockMode == 1 && hFocusWnd) {
        curActive := WinExist("A")
        ; Chặn các tổ hợp phím thoát cửa sổ: Win, Alt+Tab, Alt+Esc, Ctrl+Esc
        if (vkCode = 0x5B || vkCode = 0x5C || (isAltDown && (vkCode = 0x09 || vkCode = 0x1B)) || (vkCode = 0x1B && GetKeyState("Ctrl", "P"))) {
            return 1
        }
        ; Nếu đang tương tác đúng cửa sổ Focus
        if (curActive == hFocusWnd) {
            ; Kiểm tra nếu bấm Ctrl+Alt+L để kích hoạt hành động mở khóa
            if (isKeyDown && vkCode = 0x4C && GetKeyState("Ctrl", "P") && GetKeyState("Alt", "P")) {
                static lastFocusUnlock := 0
                if (A_TickCount - lastFocusUnlock > 700) {
                    lastFocusUnlock := A_TickCount
                    if (requireWindowsPassword)
                        SetTimer, TriggerWindowsAuthPrompt, -1
                    else
                        SetTimer, TriggerDirectUnlock, -1
                }
                return 1
            }
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
        } else {
            WinActivate, ahk_id %hFocusWnd%
            return 1
        }
    }

    ; 2. Kiểm tra Whitelist (Cho phép phím cụ thể)
    if (isKeyDown) {
        ; Phím Space
        if (allowSpace && vkCode = 0x20)
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)

        ; Phím Media (Mute, VolDown, VolUp, Next, Prev, Stop, Play/Pause)
        if (allowMedia && (vkCode >= 0xAD && vkCode <= 0xB3))
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)

        ; Phím Điều hướng (Left, Up, Right, Down, Enter, Esc)
        if (allowNav && (vkCode >= 0x25 && vkCode <= 0x28 || vkCode = 0x0D || vkCode = 0x1B))
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
    }

    ; 3. Tổ hợp phím mở khóa: Ctrl + Alt + L (Chống chớp giật và lặp phím)
    if (isKeyDown && vkCode = 0x4C && GetKeyState("Ctrl", "P") && GetKeyState("Alt", "P")) {
        static lastHotkeyPress := 0
        if (A_TickCount - lastHotkeyPress > 700) {
            lastHotkeyPress := A_TickCount
            if (requireWindowsPassword)
                SetTimer, TriggerWindowsAuthPrompt, -1
            else
                SetTimer, TriggerDirectUnlock, -1
        }
        return 1
    }

    ; 4. Bắt mã PIN / Từ khóa cốt lõi (luôn luôn mở khóa trực tiếp, không hỏi 2 lần)
    if (isKeyDown) {
        char := ""
        if (vkCode >= 0x30 && vkCode <= 0x39) { ; Ký tự số 0 - 9
            char := Chr(vkCode)
        } else if (vkCode >= 0x60 && vkCode <= 0x69) { ; Ký tự số Numpad 0 - 9
            char := Chr(vkCode - 0x30)
        } else if (vkCode >= 0x41 && vkCode <= 0x5A) { ; Ký tự chữ cái A - Z
            char := Chr(vkCode + 32)
        } else {
            VarSetCapacity(keyState, 256, 0)
            VarSetCapacity(outBuff, 4, 0)
            DllCall("GetKeyboardState", "Ptr", &keyState)
            kbLayout := DllCall("GetKeyboardLayout", "UInt", 0, "Ptr")
            res := DllCall("ToUnicodeEx", "UInt", vkCode, "UInt", scanCode, "Ptr", &keyState, "Ptr", &outBuff, "Int", 2, "UInt", 0, "Ptr", kbLayout)
            if (res > 0)
                char := StrGet(&outBuff, res, "UTF-16")
        }

        if (char != "") {
            Buffer .= char
            if (StrLen(Buffer) >= KEYWORD_LENGTH) {
                lastChars := SubStr(Buffer, -KEYWORD_LENGTH + 1)
                if (lastChars = UNLOCK_KEYWORD) {
                    Buffer := ""
                    SetTimer, TriggerDirectUnlock, -1
                    return 1
                }
            }
            if (StrLen(Buffer) > 50)
                Buffer := SubStr(Buffer, -30)
        }
    }

    ; Nếu không bật khóa bàn phím thì cho qua
    if (!lockKeyboardEnabled)
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)

    return 1 ; Chặn phím
}

TriggerDirectUnlock:
    UnlockKeyboard()
return

TriggerWindowsAuthPrompt:
    PromptWindowsAuth()
return

TriggerUnlockAction:
    if (requireWindowsPassword) {
        PromptWindowsAuth()
    } else {
        UnlockKeyboard()
    }
return

; ========================================================
; XỬ LÝ LOW-LEVEL MOUSE HOOK
; ========================================================
MouseProc(nCode, wParam, lParam) {
    global isLocked, lockMode, hFocusWnd, mouseLockEnabled, lockMouseClick
    global lockMouseWheel, lockMouseMove, allowMouseMove, allowMouseWheel, hAuthGui
    Critical

    if (nCode < 0 || !isLocked)
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)

    ; ĐẶC BIỆT: Nếu cửa sổ nhập mật khẩu Windows đang hiển thị và active -> CHO PHÉP click chuột bình thường
    if (hAuthGui && WinActive("ahk_id " . hAuthGui)) {
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
    }

    ; 1. Xử lý Focus Lock
    if (lockMode == 1 && hFocusWnd) {
        ptX := NumGet(lParam+0, 0, "Int")
        ptY := NumGet(lParam+0, 4, "Int")
        ptWnd := DllCall("WindowFromPoint", "Int64", (ptY << 32) | (ptX & 0xFFFFFFFF), "Ptr")
        rootWnd := DllCall("GetAncestor", "Ptr", ptWnd, "UInt", 2, "Ptr")

        if (ptWnd != hFocusWnd && rootWnd != hFocusWnd) {
            return 1
        }
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
    }

    ; 2. Nếu không bật khóa chuột thì cho qua
    if (!mouseLockEnabled)
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)

    ; 3. Xử lý Full Lock theo từng loại sự kiện chuột
    switch wParam {
        case 0x0200: ; WM_MOUSEMOVE
            if (allowMouseMove)
                return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
            if (lockMouseMove)
                return 1
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)

        case 0x020A, 0x020E: ; WM_MOUSEWHEEL, WM_MOUSEHWHEEL
            if (allowMouseWheel)
                return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
            if (lockMouseWheel || mouseLockEnabled)
                return 1
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)

        default: ; Các sự kiện Click chuột (Trái, Phải, Giữa, XButton)
            if (lockMouseClick || mouseLockEnabled)
                return 1
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
    }

    return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
}

; Kích hoạt Focus Lock trực tiếp lên cửa sổ chỉ định (hoặc cửa sổ active)
TriggerFocusLockDirect(targetHwnd := 0) {
    global lockMode
    lockMode := 1
    if (targetHwnd && WinExist("ahk_id " . targetHwnd)) {
        WinActivate, ahk_id %targetHwnd%
    }
    ToggleLock(1)
}

; ========================================================
; HỘP THOẠI XÁC THỰC MẬT KHẨU WINDOWS (WINDOWS AUTHENTICATION)
; ========================================================
PromptWindowsAuth() {
    global hAuthGui

    if (hAuthGui && WinExist("ahk_id " . hAuthGui)) {
        WinActivate, ahk_id %hAuthGui%
        GuiControl, Focus, WinAuthPassInput
        return
    }

    ; Tạm thời mở chuột để người dùng có thể thao tác với hộp thoại
    DllCall("ClipCursor", "Ptr", 0)

    promptMsg := StrReplace(L("Lock_PassPrompt"), "{user}", A_UserName)

    Gui, WinAuthPrompt:Destroy
    Gui, WinAuthPrompt:New, +AlwaysOnTop -MaximizeBox -MinimizeBox +HwndhAuthGui, % L("Lock_PassTitle")
    SetGuiYellowIcon(hAuthGui)
    Gui, Font, s10, Segoe UI
    Gui, Add, Picture, x22 y22 w36 h36 Icon28, %A_WinDir%\System32\ddores.dll
    Gui, Add, Text, x70 y20 w335, %promptMsg%
    Gui, Add, Edit, x70 y62 w335 h26 Password vWinAuthPassInput
    Gui, Add, Button, x215 y104 w90 h28 Default gSubmitWinAuth, % L("Lock_PassSubmit")
    Gui, Add, Button, x315 y104 w90 h28 gCancelWinAuth, % L("Lock_PassCancel")
    Gui, Show, w430 h152 Center, % L("Lock_PassTitle")
    SetGuiYellowIcon(hAuthGui)
    WinActivate, ahk_id %hAuthGui%
    GuiControl, Focus, WinAuthPassInput
}

SubmitWinAuth:
    Gui, WinAuthPrompt:Submit, NoHide
    if (WinAuthPassInput = "")
        return

    ; Xác thực qua LogonUserW của Windows Advapi32
    hToken := 0
    authSuccess := DllCall("Advapi32.dll\LogonUserW"
        , "WStr", A_UserName
        , "WStr", A_ComputerName
        , "WStr", WinAuthPassInput
        , "UInt", 2  ; LOGON32_LOGON_INTERACTIVE
        , "UInt", 0  ; LOGON32_PROVIDER_DEFAULT
        , "Ptr*", hToken)

    if (!authSuccess || !hToken) {
        authSuccess := DllCall("Advapi32.dll\LogonUserW"
            , "WStr", A_UserName
            , "WStr", "."
            , "WStr", WinAuthPassInput
            , "UInt", 2
            , "UInt", 0
            , "Ptr*", hToken)
    }

    if (authSuccess && hToken) {
        DllCall("CloseHandle", "Ptr", hToken)
        Gui, WinAuthPrompt:Destroy
        hAuthGui := 0
        UnlockKeyboard()
    } else {
        MsgBox, 48, % L("Lock_PassTitle"), % L("Lock_PassError")
        GuiControl,, WinAuthPassInput,
        if (hAuthGui && WinExist("ahk_id " . hAuthGui)) {
            WinActivate, ahk_id %hAuthGui%
            GuiControl, Focus, WinAuthPassInput
        }
    }
return

CancelWinAuth:
WinAuthPromptGuiClose:
WinAuthPromptGuiEscape:
    Gui, WinAuthPrompt:Destroy
    hAuthGui := 0
    ; Nếu vẫn đang trong Focus Lock thì tái lập lại ClipCursor
    if (isLocked && lockMode == 1 && hFocusWnd && WinExist("ahk_id " . hFocusWnd)) {
        WinGetPos, fX, fY, fW, fH, ahk_id %hFocusWnd%
        if (fW > 0 && fH > 0) {
            VarSetCapacity(rect, 16, 0)
            NumPut(fX, rect, 0, "Int"), NumPut(fY, rect, 4, "Int")
            NumPut(fX + fW, rect, 8, "Int"), NumPut(fY + fH, rect, 12, "Int")
            DllCall("ClipCursor", "Ptr", &rect)
        }
    }
return

; ========================================================
; DỌN DẸP KHI THOÁT SCRIPT
; ========================================================
OnExit("LockCleanup")
LockCleanup() {
    global hKeyboardHook, hMouseHook
    DllCall("ClipCursor", "Ptr", 0)
    if (hKeyboardHook)
        DllCall("UnhookWindowsHookEx", "Ptr", hKeyboardHook)
    if (hMouseHook)
        DllCall("UnhookWindowsHookEx", "Ptr", hMouseHook)
    DllCall("SetThreadExecutionState", "UInt", 0x80000000)
}
