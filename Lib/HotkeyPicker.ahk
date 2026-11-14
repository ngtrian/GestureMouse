; HotkeyPicker.ahk - Hộp thoại chọn phím tắt dùng chung (InputHook + Mouse + Conflict Check) & FormatHotkeyText
#NoEnv

global hHotkeyPickerGui   := 0
global HpOptions          := ""
global HpCaptured         := ""
global HpCapturing        := false
global HpPendingMod       := ""
global HpInputHook        := ""
global HpPreview          := ""
global HpConflictTxt      := ""

; Chuyển đổi chuỗi phím tắt AHK (vd: ^!t, #!m, RCtrl, XButton1) sang dạng dễ đọc
FormatHotkeyText(hk) {
    static sideNames := {RCtrl: "Right Ctrl", LCtrl: "Left Ctrl"
        , RShift: "Right Shift", LShift: "Left Shift"
        , RAlt: "Right Alt", LAlt: "Left Alt"
        , LWin: "Left Win", RWin: "Right Win"}

    if (hk = "")
        return IsFunc("L") ? L("AOT_NoHotkey") : "Chưa gán"
    if (sideNames.HasKey(hk))
        return sideNames[hk]

    res := ""
    if (InStr(hk, "#"))
        res .= "Win + "
    if (InStr(hk, "^"))
        res .= "Ctrl + "
    if (InStr(hk, "!"))
        res .= "Alt + "
    if (InStr(hk, "+"))
        res .= "Shift + "

    keyPart := RegExReplace(hk, "^[*~$#!^+<>]+", "")
    if (sideNames.HasKey(keyPart))
        keyPart := sideNames[keyPart]
    else if (keyPart = "vkC0" || keyPart = "SC029" || keyPart = "``")
        keyPart := "``"
    else if (StrLen(keyPart) = 1)
        StringUpper, keyPart, keyPart
    return res . keyPart
}

; Chuẩn hóa chuỗi phím tắt để so sánh trùng lặp
NormalizeHotkeyForCompare(hk) {
    if (hk = "")
        return ""
    norm := RegExReplace(hk, "^[*~$<>]+", "")
    StringLower, norm, norm
    norm := StrReplace(norm, "vkc0", "``")
    norm := StrReplace(norm, "sc029", "``")
    return norm
}

; Kiểm tra phím tắt có trùng với tính năng khác đang bật hay không
CheckHotkeyConflict(hk, excludeId := "") {
    global AOTEnabled, AOTHotkey, MicMuteEnabled, MicMuteHotkey, MicPttHotkey, ScreenOffEnabled, ScreenOffHotkey
    global AppWinSwitchEnabled, AppWinSwitchHotkey, AppWinSwitchBackHotkey

    norm := NormalizeHotkeyForCompare(hk)
    if (norm = "")
        return ""

    if (excludeId != "aot" && AOTEnabled && AOTHotkey != "") {
        if (NormalizeHotkeyForCompare(AOTHotkey) = norm)
            return IsFunc("L") ? L("Set_GroupAOT") : "Always On Top"
    }
    if (excludeId != "screenoff" && ScreenOffEnabled && ScreenOffHotkey != "") {
        if (NormalizeHotkeyForCompare(ScreenOffHotkey) = norm)
            return IsFunc("L") ? L("Set_GroupScreenOff") : "Quick Screen Off"
    }
    if (excludeId != "mic_toggle" && MicMuteEnabled && MicMuteHotkey != "") {
        if (NormalizeHotkeyForCompare(MicMuteHotkey) = norm) {
            lbl := IsFunc("L") ? L("Mic_ToggleHkLbl") : "Mute Microphone"
            return RTrim(lbl, ": ")
        }
    }
    if (excludeId != "mic_ptt" && MicMuteEnabled && MicPttHotkey != "") {
        if (NormalizeHotkeyForCompare(MicPttHotkey) = norm) {
            lbl := IsFunc("L") ? L("Mic_PttHkLbl") : "Push-to-Talk"
            return RTrim(lbl, ": ")
        }
    }
    if (excludeId != "appwinswitch_fwd" && AppWinSwitchEnabled && AppWinSwitchHotkey != "") {
        if (NormalizeHotkeyForCompare(AppWinSwitchHotkey) = norm)
            return IsFunc("L") ? L("Set_GroupAppWinSwitch") : "App Window Switcher"
    }
    if (excludeId != "appwinswitch_back" && AppWinSwitchEnabled && AppWinSwitchBackHotkey != "") {
        if (NormalizeHotkeyForCompare(AppWinSwitchBackHotkey) = norm)
            return IsFunc("L") ? L("Set_GroupAppWinSwitch") : "App Window Switcher"
    }
    return ""
}

; Mở hộp thoại chọn phím tắt dùng chung
; opts: { id, title, prompt, current, default, allowSingleModifier, allowMouse, allowClear, onSave }
ShowHotkeyPickerDialog(opts) {
    global hSettingsGui, hHotkeyPickerGui, HpOptions, HpCaptured, HpCapturing
    global HpPendingMod, HpInputHook, HpPreview, HpConflictTxt

    if (hHotkeyPickerGui && WinExist("ahk_id " . hHotkeyPickerGui)) {
        WinActivate, ahk_id %hHotkeyPickerGui%
        return
    }

    HpOptions := IsObject(opts) ? opts : {}
    SuspendAppHotkeysForPicker()

    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui))
        Gui, Settings:+Disabled

    HpCaptured   := HpOptions.HasKey("current") ? HpOptions.current : ""
    HpPendingMod := ""
    HpCapturing  := true

    titleText  := (HpOptions.HasKey("title") && HpOptions.title != "") ? HpOptions.title : (IsFunc("L") ? L("AOT_ChangeHotkeyBtn") : "Đổi phím tắt")
    promptText := (HpOptions.HasKey("prompt") && HpOptions.prompt != "") ? HpOptions.prompt : (IsFunc("L") ? L("Mic_HotkeyPrompt") : "")
    allowClear := HpOptions.HasKey("allowClear") ? HpOptions.allowClear : true

    ownerOpt := (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) ? "+Owner" . hSettingsGui : ""
    Gui, HotkeyPickerDlg:New, -MaximizeBox -MinimizeBox %ownerOpt% +HwndhHotkeyPickerGui, %titleText%
    if (IsFunc("SetGuiYellowIcon"))
        SetGuiYellowIcon(hHotkeyPickerGui)
    Gui, HotkeyPickerDlg:Color, FFFFFF

    Gui, HotkeyPickerDlg:Font, s9 Norm c555555, Segoe UI
    Gui, HotkeyPickerDlg:Add, Text, x16 y12 w388 h32, %promptText%

    Gui, HotkeyPickerDlg:Font, s10.5 Bold c005FB8, Segoe UI
    previewW := allowClear ? 354 : 388
    Gui, HotkeyPickerDlg:Add, Edit, x16 y46 w%previewW% h28 ReadOnly Center vHpPreview, % FormatHotkeyText(HpCaptured)
    if (allowClear) {
        Gui, HotkeyPickerDlg:Font, s10 Norm c666666, Segoe UI
        Gui, HotkeyPickerDlg:Add, Button, x374 y46 w30 h28 gOnHpClear, ✕
    }

    Gui, HotkeyPickerDlg:Font, s8.5 Norm cD97706, Segoe UI
    Gui, HotkeyPickerDlg:Add, Text, x16 y78 w388 h18 vHpConflictTxt,

    Gui, HotkeyPickerDlg:Font, s9.5 Norm c222222, Segoe UI
    Gui, HotkeyPickerDlg:Add, Button, x16 y104 w86 h26 Default gOnHpSave, OK
    resetLbl := IsFunc("L") ? L("Mic_ResetBtn") : "Đặt lại mặc định"
    Gui, HotkeyPickerDlg:Add, Button, x108 y104 w144 h26 gOnHpReset, %resetLbl%
    closeLbl := IsFunc("L") ? L("Set_Close") : "Đóng"
    Gui, HotkeyPickerDlg:Add, Button, x318 y104 w86 h26 gHotkeyPickerDlgGuiClose, %closeLbl%

    Gui, HotkeyPickerDlg:Show, w420 h142 Center
    UpdateHpPreviewAndConflict()

    HpInputHook := InputHook("L0")
    HpInputHook.KeyOpt("{All}", "N S")
    HpInputHook.OnKeyDown := Func("OnHpKeyDown")
    HpInputHook.OnKeyUp   := Func("OnHpKeyUp")
    HpInputHook.Start()

    OnMessage(0x0006, "OnHpActivate")
    if (!HpOptions.HasKey("allowMouse") || HpOptions.allowMouse) {
        OnMessage(0x0207, "OnHpMouseBtn") ; WM_MBUTTONDOWN
        OnMessage(0x020B, "OnHpMouseBtn") ; WM_XBUTTONDOWN
    }
}

UpdateHpPreviewAndConflict() {
    global HpCaptured, HpOptions
    GuiControl, HotkeyPickerDlg:, HpPreview, % FormatHotkeyText(HpCaptured)

    excludeId := HpOptions.HasKey("id") ? HpOptions.id : ""
    conflictWith := CheckHotkeyConflict(HpCaptured, excludeId)
    if (conflictWith != "") {
        warnPrefix := IsFunc("L") ? L("Hk_ConflictWarn") : "⚠ Trùng phím tắt với: "
        GuiControl, HotkeyPickerDlg:, HpConflictTxt, % warnPrefix . conflictWith
    } else {
        GuiControl, HotkeyPickerDlg:, HpConflictTxt,
    }
}

SuspendAppHotkeysForPicker() {
    global AOTHotkey, MicMuteRegToggleHk, MicMuteRegPttDownHk, MicMuteRegPttUpHk, ScreenOffRegHk
    global AppWinSwitchRegFwdHk, AppWinSwitchRegBackHk
    if (AOTHotkey != "")
        try Hotkey, %AOTHotkey%, ToggleAlwaysOnTopLabel, Off
    if (MicMuteRegToggleHk != "")
        try Hotkey, %MicMuteRegToggleHk%, MicToggleKeyHandler, Off
    if (MicMuteRegPttDownHk != "")
        try Hotkey, %MicMuteRegPttDownHk%, MicPttKeyDownHandler, Off
    if (MicMuteRegPttUpHk != "")
        try Hotkey, %MicMuteRegPttUpHk%, MicPttKeyUpHandler, Off
    if (ScreenOffRegHk != "")
        try Hotkey, %ScreenOffRegHk%, ScreenOffHotkeyHandler, Off
    if (AppWinSwitchRegFwdHk != "")
        try Hotkey, %AppWinSwitchRegFwdHk%, AppWinSwitchForwardHandler, Off
    if (AppWinSwitchRegBackHk != "")
        try Hotkey, %AppWinSwitchRegBackHk%, AppWinSwitchBackwardHandler, Off
}

RestoreAppHotkeysAfterPicker() {
    if (IsFunc("ApplyAOTHotkey"))
        ApplyAOTHotkey()
    if (IsFunc("ApplyMicMuteHotkey"))
        ApplyMicMuteHotkey()
    if (IsFunc("ApplyScreenOffHotkey"))
        ApplyScreenOffHotkey()
    if (IsFunc("ApplyAppWindowSwitcherHotkeys"))
        ApplyAppWindowSwitcherHotkeys()
}

OnHpActivate(wParam, lParam, msg, hwnd) {
    global hHotkeyPickerGui, HpCapturing, HpInputHook
    if (!HpCapturing || !hHotkeyPickerGui || hwnd != hHotkeyPickerGui || !IsObject(HpInputHook))
        return
    if ((wParam & 0xFFFF) = 0)
        HpInputHook.Stop()
    else
        HpInputHook.Start()
}

HpGetSideModifierFromVK(vk) {
    static vkMap := {91: "LWin", 92: "RWin"
        , 160: "LShift", 161: "RShift"
        , 162: "LCtrl",  163: "RCtrl"
        , 164: "LAlt",   165: "RAlt"}
    return vkMap.HasKey(vk) ? vkMap[vk] : ""
}

HpGetCurrentModsPrefix() {
    mods := ""
    if (GetKeyState("Ctrl", "P"))
        mods .= "^"
    if (GetKeyState("Alt", "P"))
        mods .= "!"
    if (GetKeyState("Shift", "P"))
        mods .= "+"
    if (GetKeyState("LWin", "P") || GetKeyState("RWin", "P"))
        mods .= "#"
    return mods
}

OnHpKeyDown(ih, vk, sc) {
    global hHotkeyPickerGui, HpCaptured, HpCapturing, HpOptions, HpPendingMod
    if (!HpCapturing || !hHotkeyPickerGui || !WinActive("ahk_id " . hHotkeyPickerGui))
        return

    modName := HpGetSideModifierFromVK(vk)
    if (modName != "") {
        if (HpOptions.HasKey("allowSingleModifier") && HpOptions.allowSingleModifier)
            HpPendingMod := modName
        return
    }

    HpPendingMod := ""
    if (vk = 27) { ; Esc để đóng
        SetTimer, HotkeyPickerDlgGuiClose, -1
        return
    }

    keyName := GetKeyName(Format("vk{:02X}", vk))
    if (keyName = "")
        keyName := GetKeyName(Format("sc{:03X}", sc))
    if (keyName = "")
        return

    HpCaptured := HpGetCurrentModsPrefix() . keyName
    UpdateHpPreviewAndConflict()
}

OnHpKeyUp(ih, vk, sc) {
    global hHotkeyPickerGui, HpCaptured, HpCapturing, HpOptions, HpPendingMod
    if (!HpCapturing || !hHotkeyPickerGui)
        return
    if (!HpOptions.HasKey("allowSingleModifier") || !HpOptions.allowSingleModifier)
        return

    modName := HpGetSideModifierFromVK(vk)
    if (modName != "" && HpPendingMod != "" && modName = HpPendingMod) {
        HpPendingMod := ""
        HpCaptured := modName
        UpdateHpPreviewAndConflict()
    }
}

OnHpMouseBtn(wParam, lParam, msg, hwnd) {
    global hHotkeyPickerGui, HpCaptured, HpCapturing, HpPendingMod
    if (!HpCapturing || !hHotkeyPickerGui)
        return
    if (hwnd != hHotkeyPickerGui && !DllCall("IsChild", "Ptr", hHotkeyPickerGui, "Ptr", hwnd))
        return

    HpPendingMod := ""
    btnName := ""
    if (msg = 0x0207) {
        btnName := "MButton"
    } else if (msg = 0x020B) {
        xBtn := (wParam >> 16) & 0xFFFF
        btnName := (xBtn = 1) ? "XButton1" : (xBtn = 2 ? "XButton2" : "")
    }
    if (btnName = "")
        return

    HpCaptured := HpGetCurrentModsPrefix() . btnName
    UpdateHpPreviewAndConflict()
    return 0
}

OnHpReset:
    HpPendingMod := ""
    HpCaptured := HpOptions.HasKey("default") ? HpOptions.default : ""
    UpdateHpPreviewAndConflict()
return

OnHpClear:
    HpPendingMod := ""
    HpCaptured := ""
    UpdateHpPreviewAndConflict()
return

OnHpSave:
    if (IsObject(HpOptions) && IsObject(HpOptions.onSave))
        HpOptions.onSave.Call(HpCaptured)
    Gosub, HotkeyPickerDlgGuiClose
return

HotkeyPickerDlgGuiClose:
HotkeyPickerDlgGuiEscape:
    HpCapturing  := false
    HpPendingMod := ""
    if (IsObject(HpInputHook)) {
        HpInputHook.Stop()
        HpInputHook := ""
    }
    OnMessage(0x0006, "OnHpActivate", 0)
    OnMessage(0x0207, "OnHpMouseBtn", 0)
    OnMessage(0x020B, "OnHpMouseBtn", 0)
    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) {
        Gui, Settings:-Disabled
        WinActivate, ahk_id %hSettingsGui%
    }
    if (hHotkeyPickerGui) {
        Gui, HotkeyPickerDlg:Destroy
        hHotkeyPickerGui := 0
    }
    RestoreAppHotkeysAfterPicker()
return
