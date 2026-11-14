; ScreenOff.ahk - Tắt màn hình nhanh (WM_SYSCOMMAND / SC_MONITORPOWER)
#NoEnv

; ========================================================
; KHỞI TẠO & LƯU CẤU HÌNH TẮT MÀN HÌNH
; ========================================================
InitScreenOff() {
    global ScreenOffEnabled, ScreenOffHotkey, ScreenOffRegHk

    ScreenOffEnabled := 1
    ScreenOffHotkey  := "#!s" ; Mặc định: Win + Alt + S
    ScreenOffRegHk   := ""

    LoadScreenOffSettings()
    ApplyScreenOffHotkey()
}

LoadScreenOffSettings() {
    global ScreenOffEnabled, ScreenOffHotkey
    regKey := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"

    RegRead, valEnabled, %regKey%, ScreenOffEnabled
    if (!ErrorLevel && valEnabled != "")
        ScreenOffEnabled := valEnabled ? 1 : 0

    RegRead, valHotkey, %regKey%, ScreenOffHotkey
    if (!ErrorLevel)
        ScreenOffHotkey := valHotkey
}

SaveScreenOffSettings() {
    global ScreenOffEnabled, ScreenOffHotkey
    regKey := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"

    RegWrite, REG_DWORD, %regKey%, ScreenOffEnabled, %ScreenOffEnabled%
    RegWrite, REG_SZ,    %regKey%, ScreenOffHotkey, %ScreenOffHotkey%
}

; ========================================================
; ĐĂNG KÝ & HỦY PHÍM TẮT TẮT MÀN HÌNH
; ========================================================
ApplyScreenOffHotkey() {
    global ScreenOffEnabled, ScreenOffHotkey, ScreenOffRegHk

    if (ScreenOffRegHk != "") {
        try Hotkey, %ScreenOffRegHk%, ScreenOffHotkeyHandler, Off
        ScreenOffRegHk := ""
    }

    if (ScreenOffEnabled && ScreenOffHotkey != "") {
        try {
            Hotkey, %ScreenOffHotkey%, ScreenOffHotkeyHandler, On
            ScreenOffRegHk := ScreenOffHotkey
        }
    }
}

ScreenOffHotkeyHandler:
    TurnOffMonitor(true)
return

; ========================================================
; THỰC THI TẮT MÀN HÌNH AN TOÀN
; ========================================================
TurnOffMonitor(waitKeys := true) {
    if (waitKeys) {
        ; Chờ người dùng nhả các phím bổ trợ để tránh sự kiện KeyUp đánh thức màn hình ngay lập tức
        mods := ["LControl", "RControl", "LAlt", "RAlt", "LShift", "RShift", "LWin", "RWin"]
        for _, keyName in mods {
            if GetKeyState(keyName, "P")
                KeyWait, %keyName%, T1.5
        }
        Sleep, 450
    } else {
        ; Chờ nhẹ sau khi click chuột từ menu hoặc nút bấm
        Sleep, 550
    }

    ; WM_SYSCOMMAND (0x0112), SC_MONITORPOWER (0xF170), 2 = Tắt nguồn màn hình
    SendMessage, 0x0112, 0xF170, 2,, Program Manager
}

FormatScreenOffHotkeyText(hk) {
    if (IsFunc("FormatHotkeyText"))
        return FormatHotkeyText(hk)
    return hk
}
