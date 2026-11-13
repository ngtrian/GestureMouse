; MicMute.ahk - Quản lý tắt/bật Microphone (WASAPI Core Audio + Toggle / Push-to-Talk / Push-to-Mute + GDI+ OSD tự ẩn)
#NoEnv

; ========================================================
; KHỞI TẠO MODULE MIC MUTE
; ========================================================
InitMicMute() {
    global MicMuteEnabled, MicMuteHotkey, MicPttHotkey, MicPttInvert
    global MicMuteAllDevices, MicTargetDeviceId, MicMuteReleaseDelay
    global MicMuteOsdEnabled, MicMuteOsdDuration, MicMuteBadgeEnabled, MicMuteBeepEnabled
    global MicMuteRegToggleHk, MicMuteRegPttDownHk, MicMuteRegPttUpHk
    global MicPttKeyHeld, MicPttActionMode, MicMutePendingRelease
    global hMicOsdGui, MicOsdVisible, MicOsdAlpha, MicOsdBitmap, MicOsdW, MicOsdH, MicOsdX, MicOsdY
    global hMicBadgeGui, MicBadgeVisible, MicBadgeLastMuted
    global MicGdipModule, MicGdipToken

    MicMuteEnabled       := 1
    MicMuteHotkey        := "#!m"      ; Phím tắt Toggle mặc định: Win + Alt + M
    MicPttHotkey         := "LCtrl"    ; Phím tắt Push-to-Talk mặc định: Left Ctrl
    MicPttInvert         := 1          ; 1: Đảo chiều thông minh (nếu mic đang bật -> giữ để tắt tạm thời)
    MicMuteAllDevices    := 1          ; 1: Áp dụng tất cả thiết bị thu đang hoạt động, 0: Thiết bị chỉ định hoặc mặc định
    MicTargetDeviceId    := ""         ; Rỗng = thiết bị mặc định (khi MicMuteAllDevices = 0)
    MicMuteReleaseDelay  := 200        ; Độ trễ (ms) trước khi tắt mic lại khi nhả phím Push-to-Talk
    MicMuteOsdEnabled    := 1          ; 1: Hiển thị OSD GDI+ tự ẩn khi chuyển trạng thái
    MicMuteOsdDuration   := 1500       ; Thời gian hiển thị OSD (ms) trước khi mờ dần
    MicMuteBadgeEnabled  := 1          ; 1: Ghim badge mờ ở góc trên-phải khi Mic đang tắt
    MicMuteBeepEnabled   := 0          ; 1: Phát tiếng bíp nhẹ phản hồi khi đổi trạng thái

    MicMuteRegToggleHk    := ""
    MicMuteRegPttDownHk   := ""
    MicMuteRegPttUpHk     := ""
    MicPttKeyHeld         := false
    MicPttActionMode      := ""        ; "talk" hoặc "mute"
    MicPttLastActionMode  := ""
    MicMutePendingRelease := false

    hMicOsdGui   := 0
    MicOsdVisible := false
    MicOsdAlpha  := 255
    MicOsdBitmap := 0
    MicOsdW := 0, MicOsdH := 0, MicOsdX := 0, MicOsdY := 0

    hMicBadgeGui      := 0
    MicBadgeVisible   := false
    MicBadgeLastMuted := -1

    MicGdipModule := 0
    MicGdipToken  := 0

    LoadMicMuteSettings()
    ApplyMicMuteHotkey()
    UpdateMicBadge()
    SyncMicBadgeTimer()

    OnExit("CleanupMicMute")
}

LoadMicMuteSettings() {
    global MicMuteEnabled, MicMuteHotkey, MicPttHotkey, MicPttInvert
    global MicMuteAllDevices, MicTargetDeviceId, MicMuteReleaseDelay
    global MicMuteOsdEnabled, MicMuteOsdDuration, MicMuteBadgeEnabled, MicMuteBeepEnabled

    regKey := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"

    RegRead, val, %regKey%, MicMuteEnabled
    if (!ErrorLevel && val != "")
        MicMuteEnabled := val ? 1 : 0

    RegRead, val, %regKey%, MicMuteHotkey
    if (!ErrorLevel && val != "")
        MicMuteHotkey := val

    RegRead, val, %regKey%, MicPttHotkey
    if (!ErrorLevel && val != "")
        MicPttHotkey := val

    RegRead, val, %regKey%, MicPttInvert
    if (!ErrorLevel && val != "")
        MicPttInvert := val ? 1 : 0

    RegRead, val, %regKey%, MicMuteAllDevices
    if (!ErrorLevel && val != "")
        MicMuteAllDevices := val ? 1 : 0

    RegRead, val, %regKey%, MicTargetDeviceId
    if (!ErrorLevel)
        MicTargetDeviceId := val

    RegRead, val, %regKey%, MicMuteReleaseDelay
    if (!ErrorLevel && val != "") {
        val += 0
        if (val >= 0 && val <= 2000)
            MicMuteReleaseDelay := val
    }

    RegRead, val, %regKey%, MicMuteOsdEnabled
    if (!ErrorLevel && val != "")
        MicMuteOsdEnabled := val ? 1 : 0

    RegRead, val, %regKey%, MicMuteOsdDuration
    if (!ErrorLevel && val != "") {
        val += 0
        if (val >= 400 && val <= 10000)
            MicMuteOsdDuration := val
    }

    RegRead, val, %regKey%, MicMuteBadgeEnabled
    if (!ErrorLevel && val != "")
        MicMuteBadgeEnabled := val ? 1 : 0

    RegRead, val, %regKey%, MicMuteBeepEnabled
    if (!ErrorLevel && val != "")
        MicMuteBeepEnabled := val ? 1 : 0
}

SaveMicMuteSettings() {
    global MicMuteEnabled, MicMuteHotkey, MicPttHotkey, MicPttInvert
    global MicMuteAllDevices, MicTargetDeviceId, MicMuteReleaseDelay
    global MicMuteOsdEnabled, MicMuteOsdDuration, MicMuteBadgeEnabled, MicMuteBeepEnabled

    regKey := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"
    RegWrite, REG_DWORD, %regKey%, MicMuteEnabled, %MicMuteEnabled%
    RegWrite, REG_SZ,    %regKey%, MicMuteHotkey, %MicMuteHotkey%
    RegWrite, REG_SZ,    %regKey%, MicPttHotkey, %MicPttHotkey%
    RegWrite, REG_DWORD, %regKey%, MicPttInvert, %MicPttInvert%
    RegWrite, REG_DWORD, %regKey%, MicMuteAllDevices, %MicMuteAllDevices%
    RegWrite, REG_SZ,    %regKey%, MicTargetDeviceId, %MicTargetDeviceId%
    RegWrite, REG_DWORD, %regKey%, MicMuteReleaseDelay, %MicMuteReleaseDelay%
    RegWrite, REG_DWORD, %regKey%, MicMuteOsdEnabled, %MicMuteOsdEnabled%
    RegWrite, REG_DWORD, %regKey%, MicMuteOsdDuration, %MicMuteOsdDuration%
    RegWrite, REG_DWORD, %regKey%, MicMuteBadgeEnabled, %MicMuteBadgeEnabled%
    RegWrite, REG_DWORD, %regKey%, MicMuteBeepEnabled, %MicMuteBeepEnabled%
}

; ========================================================
; ĐĂNG KÝ & XỬ LÝ PHÍM TẮT (TOGGLE & PUSH-TO-TALK)
; ========================================================
ApplyMicMuteHotkey() {
    global MicMuteEnabled, MicMuteHotkey, MicPttHotkey
    global MicMuteRegToggleHk, MicMuteRegPttDownHk, MicMuteRegPttUpHk

    ; Gỡ các phím tắt cũ nếu có
    if (MicMuteRegToggleHk != "") {
        try Hotkey, %MicMuteRegToggleHk%, MicToggleKeyHandler, Off
        MicMuteRegToggleHk := ""
    }
    if (MicMuteRegPttDownHk != "") {
        try Hotkey, %MicMuteRegPttDownHk%, MicPttKeyDownHandler, Off
        MicMuteRegPttDownHk := ""
    }
    if (MicMuteRegPttUpHk != "") {
        try Hotkey, %MicMuteRegPttUpHk%, MicPttKeyUpHandler, Off
        MicMuteRegPttUpHk := ""
    }

    if (!MicMuteEnabled)
        return

    ; 1. Đăng ký phím tắt Toggle (Bật/Tắt)
    if (MicMuteHotkey != "") {
        try {
            Hotkey, %MicMuteHotkey%, MicToggleKeyHandler, On
            MicMuteRegToggleHk := MicMuteHotkey
        } catch {
            MicMuteRegToggleHk := ""
        }
    }

    ; 2. Đăng ký phím tắt Push-to-Talk (hỗ trợ cả phím đơn như LCtrl/RCtrl mà không chặn Ctrl+C/A/V)
    if (MicPttHotkey != "") {
        isSingleMod := (MicPttHotkey ~= "i)^(L|R)(Ctrl|Shift|Alt|Win)$")
        hkPrefix := isSingleMod ? "~*" : "*"
        hkPtt := (SubStr(MicPttHotkey, 1, 1) = "*" || SubStr(MicPttHotkey, 1, 1) = "~") ? MicPttHotkey : (hkPrefix . MicPttHotkey)
        try {
            Hotkey, %hkPtt%, MicPttKeyDownHandler, On
            MicMuteRegPttDownHk := hkPtt
        } catch {
            MicMuteRegPttDownHk := ""
            return
        }
        hkPttUp := hkPtt . " Up"
        try {
            Hotkey, %hkPttUp%, MicPttKeyUpHandler, On
            MicMuteRegPttUpHk := hkPttUp
        } catch {
            MicMuteRegPttUpHk := ""
        }
    }
}

MicToggleKeyHandler:
    MicPttLastActionMode := ""
    if (MicMuteEnabled)
        ToggleMicMute(true)
return

MicPttKeyDownHandler:
    HandleMicPttKeyDown()
return

MicPttKeyUpHandler:
    HandleMicPttKeyUp()
return

HandleMicPttKeyDown() {
    global MicMuteEnabled, MicPttInvert, MicPttKeyHeld, MicPttActionMode, MicPttLastActionMode, MicMutePendingRelease, MicMuteOsdEnabled
    if (!MicMuteEnabled || MicPttKeyHeld)
        return
    MicPttKeyHeld := true

    if (MicMutePendingRelease) {
        SetTimer, MicMutePttReleaseTimer, Off
        MicMutePendingRelease := false
        MicPttActionMode := "talk"
        MicPttLastActionMode := "talk"
        if (MicMuteOsdEnabled)
            ShowMicMuteOsd(false)
        SetTimer, MicMuteWatchKeyUpTimer, 30
        return
    }

    curMuted := GetMicMuteState()
    if (curMuted = 1) {
        ; Mic đang tắt -> Nhấn giữ để nói (Push-to-Talk)
        MicPttActionMode := "talk"
        MicPttLastActionMode := "talk"
        SetMicMuteState(false, true)
    } else if (curMuted = 0 && MicPttInvert) {
        ; Mic đang bật & cho phép đảo -> Nhấn giữ để tắt tạm thời (Push-to-Mute)
        MicPttActionMode := "mute"
        MicPttLastActionMode := "mute"
        SetMicMuteState(true, true)
    } else {
        MicPttActionMode := ""
        MicPttLastActionMode := ""
    }

    SetTimer, MicMuteWatchKeyUpTimer, 30
}

HandleMicPttKeyUp() {
    global MicPttKeyHeld, MicPttActionMode, MicPttLastActionMode, MicMuteReleaseDelay, MicMutePendingRelease
    if (!MicPttKeyHeld)
        return
    MicPttKeyHeld := false
    SetTimer, MicMuteWatchKeyUpTimer, Off

    MicPttLastActionMode := MicPttActionMode
    if (MicPttActionMode = "talk") {
        if (MicMuteReleaseDelay > 0) {
            MicMutePendingRelease := true
            SetTimer, MicMutePttReleaseTimer, % -MicMuteReleaseDelay
        } else {
            SetMicMuteState(true, true)
            MicPttLastActionMode := ""
        }
    } else if (MicPttActionMode = "mute") {
        SetMicMuteState(false, true)
        MicPttLastActionMode := ""
    }
    MicPttActionMode := ""
}

MicMutePttReleaseTimer:
    MicMutePendingRelease := false
    if (!MicPttKeyHeld) {
        SetMicMuteState(true, true)
        MicPttLastActionMode := ""
    }
return

MicMuteWatchKeyUpTimer:
    if (!IsMicHotkeyPhysicallyDown(MicPttHotkey))
        HandleMicPttKeyUp()
return

; Kiểm tra phím chính của hotkey có còn đang được giữ vật lý hay không
IsMicHotkeyPhysicallyDown(hk) {
    if (hk = "")
        return false
    baseKey := RegExReplace(hk, "^[*~$#!^+<>]+", "")
    if (baseKey = "")
        return false
    return GetKeyState(baseKey, "P") ? true : false
}

; ========================================================
; ĐIỀU KHIỂN MICROPHONE QUA WINDOWS CORE AUDIO (WASAPI COM)
; ========================================================
ToggleMicMute(showFeedback := true) {
    curMuted := GetMicMuteState()
    if (curMuted = -1)
        return -1
    newMuted := !curMuted
    SetMicMuteState(newMuted, showFeedback)
    return newMuted ? 1 : 0
}

; Lấy trạng thái mute của thiết bị thu mục tiêu (1: đang tắt, 0: đang bật, -1: không tìm thấy mic)
GetMicMuteState() {
    global MicMuteAllDevices, MicTargetDeviceId
    enumerator := 0, device := 0, epVol := 0
    result := -1
    try {
        enumerator := ComObjCreate("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
        if (!enumerator)
            return -1

        if (!MicMuteAllDevices && MicTargetDeviceId != "") {
            ; IMMDeviceEnumerator::GetDevice(pwstrId, &device) - index 5
            DllCall(NumGet(NumGet(enumerator + 0) + 5 * A_PtrSize), "Ptr", enumerator, "WStr", MicTargetDeviceId, "Ptr*", device)
        }
        if (!device) {
            ; IMMDeviceEnumerator::GetDefaultAudioEndpoint(eCapture = 1, eConsole = 0, &device)
            hr := DllCall(NumGet(NumGet(enumerator + 0) + 4 * A_PtrSize), "Ptr", enumerator, "UInt", 1, "UInt", 0, "Ptr*", device)
            if (hr != 0 || !device) {
                ; Fallback sang eCommunications = 2
                DllCall(NumGet(NumGet(enumerator + 0) + 4 * A_PtrSize), "Ptr", enumerator, "UInt", 1, "UInt", 2, "Ptr*", device)
            }
        }
        if (device) {
            epVol := ActivateAudioEndpointVolume(device)
            if (epVol) {
                muted := 0
                ; IAudioEndpointVolume::GetMute(&muted) - vtable index 15
                hr := DllCall(NumGet(NumGet(epVol + 0) + 15 * A_PtrSize), "Ptr", epVol, "Int*", muted)
                if (hr = 0)
                    result := muted ? 1 : 0
            }
        }
    }
    if (epVol)
        ObjRelease(epVol)
    if (device)
        ObjRelease(device)
    if (enumerator)
        ObjRelease(enumerator)
    return result
}

; Đặt trạng thái mute cho thiết bị thu (tất cả thiết bị đang bật, thiết bị chỉ định, hoặc thiết bị mặc định)
SetMicMuteState(mute, showFeedback := true) {
    global MicMuteAllDevices, MicTargetDeviceId, MicMuteOsdEnabled, MicMuteBeepEnabled

    bMute := mute ? 1 : 0
    changedAny := false
    enumerator := 0, collection := 0

    try {
        enumerator := ComObjCreate("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
        if (!enumerator)
            return false

        if (MicMuteAllDevices) {
            ; IMMDeviceEnumerator::EnumAudioEndpoints(eCapture = 1, DEVICE_STATE_ACTIVE = 1, &collection) - index 3
            hr := DllCall(NumGet(NumGet(enumerator + 0) + 3 * A_PtrSize), "Ptr", enumerator, "UInt", 1, "UInt", 1, "Ptr*", collection)
            if (hr = 0 && collection) {
                count := 0
                DllCall(NumGet(NumGet(collection + 0) + 3 * A_PtrSize), "Ptr", collection, "UInt*", count)
                Loop, %count% {
                    idx := A_Index - 1
                    dev := 0, vol := 0
                    if (DllCall(NumGet(NumGet(collection + 0) + 4 * A_PtrSize), "Ptr", collection, "UInt", idx, "Ptr*", dev) = 0 && dev) {
                        vol := ActivateAudioEndpointVolume(dev)
                        if (vol) {
                            if (DllCall(NumGet(NumGet(vol + 0) + 14 * A_PtrSize), "Ptr", vol, "Int", bMute, "Ptr", 0) = 0)
                                changedAny := true
                            ObjRelease(vol)
                        }
                        ObjRelease(dev)
                    }
                }
            }
        } else if (MicTargetDeviceId != "") {
            dev := 0, vol := 0
            if (DllCall(NumGet(NumGet(enumerator + 0) + 5 * A_PtrSize), "Ptr", enumerator, "WStr", MicTargetDeviceId, "Ptr*", dev) = 0 && dev) {
                vol := ActivateAudioEndpointVolume(dev)
                if (vol) {
                    if (DllCall(NumGet(NumGet(vol + 0) + 14 * A_PtrSize), "Ptr", vol, "Int", bMute, "Ptr", 0) = 0)
                        changedAny := true
                    ObjRelease(vol)
                }
                ObjRelease(dev)
            }
        }

        ; Đảm bảo thiết bị mặc định (eConsole + eCommunications) nếu đang chọn Default hoặc không tìm thấy thiết bị chỉ định
        if ((!MicMuteAllDevices && !changedAny) || (MicMuteAllDevices && !changedAny)) {
            Loop, 2 {
                role := (A_Index = 1) ? 0 : 2
                dev := 0, vol := 0
                if (DllCall(NumGet(NumGet(enumerator + 0) + 4 * A_PtrSize), "Ptr", enumerator, "UInt", 1, "UInt", role, "Ptr*", dev) = 0 && dev) {
                    vol := ActivateAudioEndpointVolume(dev)
                    if (vol) {
                        if (DllCall(NumGet(NumGet(vol + 0) + 14 * A_PtrSize), "Ptr", vol, "Int", bMute, "Ptr", 0) = 0)
                            changedAny := true
                        ObjRelease(vol)
                    }
                    ObjRelease(dev)
                }
            }
        }
    }

    if (collection)
        ObjRelease(collection)
    if (enumerator)
        ObjRelease(enumerator)

    if (changedAny) {
        UpdateMicBadge(bMute)
        if (showFeedback) {
            if (MicMuteOsdEnabled)
                ShowMicMuteOsd(bMute)
            if (MicMuteBeepEnabled)
                PlayMicMuteBeep(bMute)
        }
    }
    return changedAny
}

; Liệt kê toàn bộ thiết bị thu âm đang hoạt động (giống Windows Sound Input)
GetCaptureDevices() {
    devices := []
    enumerator := 0, collection := 0, defDev := 0
    defaultId := ""

    try {
        enumerator := ComObjCreate("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
        if (!enumerator)
            return devices

        ; Lấy ID của thiết bị mặc định hiện tại để đánh dấu
        if (DllCall(NumGet(NumGet(enumerator + 0) + 4 * A_PtrSize), "Ptr", enumerator, "UInt", 1, "UInt", 0, "Ptr*", defDev) = 0 && defDev) {
            pDefId := 0
            if (DllCall(NumGet(NumGet(defDev + 0) + 5 * A_PtrSize), "Ptr", defDev, "Ptr*", pDefId) = 0 && pDefId) {
                defaultId := StrGet(pDefId, "UTF-16")
                DllCall("ole32\CoTaskMemFree", "Ptr", pDefId)
            }
            ObjRelease(defDev)
        }

        if (DllCall(NumGet(NumGet(enumerator + 0) + 3 * A_PtrSize), "Ptr", enumerator, "UInt", 1, "UInt", 1, "Ptr*", collection) = 0 && collection) {
            count := 0
            DllCall(NumGet(NumGet(collection + 0) + 3 * A_PtrSize), "Ptr", collection, "UInt*", count)
            Loop, %count% {
                idx := A_Index - 1
                dev := 0
                if (DllCall(NumGet(NumGet(collection + 0) + 4 * A_PtrSize), "Ptr", collection, "UInt", idx, "Ptr*", dev) = 0 && dev) {
                    devId := "", devName := ""
                    pId := 0
                    if (DllCall(NumGet(NumGet(dev + 0) + 5 * A_PtrSize), "Ptr", dev, "Ptr*", pId) = 0 && pId) {
                        devId := StrGet(pId, "UTF-16")
                        DllCall("ole32\CoTaskMemFree", "Ptr", pId)
                    }
                    devName := GetAudioDeviceFriendlyName(dev)
                    if (devId != "" && devName != "")
                        devices.Push({id: devId, name: devName, isDefault: (devId = defaultId)})
                    ObjRelease(dev)
                }
            }
        }
    }
    if (collection)
        ObjRelease(collection)
    if (enumerator)
        ObjRelease(enumerator)
    return devices
}

GetAudioDeviceFriendlyName(pDevice) {
    static initKey := 0, pkeyFriendly
    if (!initKey) {
        VarSetCapacity(pkeyFriendly, 20, 0)
        ; PKEY_Device_FriendlyName = {A45C254E-DF1C-4EFD-8020-67D146A850E0}, pid = 14
        DllCall("ole32\CLSIDFromString", "WStr", "{A45C254E-DF1C-4EFD-8020-67D146A850E0}", "Ptr", &pkeyFriendly)
        NumPut(14, pkeyFriendly, 16, "UInt")
        initKey := 1
    }
    name := ""
    pProps := 0
    ; IMMDevice::OpenPropertyStore(STGM_READ = 0, &pProps) - index 4
    if (DllCall(NumGet(NumGet(pDevice + 0) + 4 * A_PtrSize), "Ptr", pDevice, "UInt", 0, "Ptr*", pProps) = 0 && pProps) {
        VarSetCapacity(pv, 24, 0)
        ; IPropertyStore::GetValue(&key, &pv) - index 5
        if (DllCall(NumGet(NumGet(pProps + 0) + 5 * A_PtrSize), "Ptr", pProps, "Ptr", &pkeyFriendly, "Ptr", &pv) = 0) {
            vt := NumGet(pv, 0, "UShort")
            if (vt = 31) { ; VT_LPWSTR
                pStr := NumGet(pv, 8, "Ptr")
                if (pStr)
                    name := StrGet(pStr, "UTF-16")
            }
            DllCall("ole32\PropVariantClear", "Ptr", &pv)
        }
        ObjRelease(pProps)
    }
    return name
}

ActivateAudioEndpointVolume(pDevice) {
    static initGuid := 0, iidAudioEndpointVolume
    if (!initGuid) {
        VarSetCapacity(iidAudioEndpointVolume, 16, 0)
        ; {5CDF2C82-841E-4546-9722-0CF74078229A}
        DllCall("ole32\CLSIDFromString", "WStr", "{5CDF2C82-841E-4546-9722-0CF74078229A}", "Ptr", &iidAudioEndpointVolume)
        initGuid := 1
    }
    pVol := 0
    ; IMMDevice::Activate(iid, CLSCTX_ALL = 23, NULL, &pVol) - index 3
    hr := DllCall(NumGet(NumGet(pDevice + 0) + 3 * A_PtrSize), "Ptr", pDevice, "Ptr", &iidAudioEndpointVolume, "UInt", 23, "Ptr", 0, "Ptr*", pVol)
    return (hr = 0) ? pVol : 0
}

PlayMicMuteBeep(isMuted) {
    if (isMuted) {
        SoundBeep, 520, 45
        SoundBeep, 390, 60
    } else {
        SoundBeep, 520, 45
        SoundBeep, 740, 60
    }
}

; ========================================================
; GDI+ OSD TỰ ẨN (BO GÓC MỊN, CLICK-THROUGH, KHÔNG CƯỚP FOCUS)
; ========================================================
EnsureMicGdip() {
    global MicGdipModule, MicGdipToken
    if (MicGdipToken)
        return true
    if (!MicGdipModule)
        MicGdipModule := DllCall("LoadLibrary", "Str", "gdiplus", "Ptr")
    if (!MicGdipModule)
        return false
    VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0)
    NumPut(1, si, 0, "UInt")
    token := 0
    if (DllCall("gdiplus\GdiplusStartup", "Ptr*", token, "Ptr", &si, "Ptr", 0) != 0)
        return false
    MicGdipToken := token
    return true
}

ShowMicMuteOsd(isMuted) {
    global hMicOsdGui, MicOsdVisible, MicOsdAlpha, MicMuteOsdDuration
    global MicPttKeyHeld, MicPttLastActionMode, MicOsdW, MicOsdH, MicOsdX, MicOsdY

    if (!EnsureMicGdip())
        return

    SetTimer, MicMuteOsdHoldTimer, Off
    SetTimer, MicMuteOsdFadeTimer, Off

    if (!hMicOsdGui) {
        Gui, MicOsd:New, +AlwaysOnTop -Caption +ToolWindow +E0x80000 +E0x20 +E0x08000000 +HwndhMicOsdGui
    }

    scale := A_ScreenDPI / 96.0
    osdW := Round(216 * scale)
    osdH := Round(58 * scale)

    ; Định vị OSD ở giữa-dưới vùng làm việc màn hình chính (phía trên Taskbar)
    SysGet, wa, MonitorWorkArea
    osdX := Round(waLeft + (waRight - waLeft - osdW) / 2)
    osdY := Round(waBottom - osdH - 28 * scale)

    MicOsdW := osdW
    MicOsdH := osdH
    MicOsdX := osdX
    MicOsdY := osdY

    titleText := GetMicOsdTitle(isMuted)
    subText   := GetMicOsdSubtitle()

    if (!RenderMicOsdBitmap(osdW, osdH, scale, isMuted, titleText, subText))
        return

    MicOsdAlpha := 255
    PresentMicOsdBitmap(255)
    DllCall("ShowWindow", "Ptr", hMicOsdGui, "Int", 8) ; SW_SHOWNA (không cướp focus)
    DllCall("SetWindowPos", "Ptr", hMicOsdGui, "Ptr", -1, "Int", osdX, "Int", osdY, "Int", osdW, "Int", osdH, "UInt", 0x0053) ; SWP_NOSIZE|SWP_NOMOVE|SWP_NOACTIVATE|SWP_SHOWWINDOW
    MicOsdVisible := true

    ; Khi đang nhấn giữ Push-to-Talk/Mute thì giữ OSD sáng liên tục, chỉ đếm ngược ẩn sau khi nhả phím
    if (!MicPttKeyHeld) {
        duration := (MicMuteOsdDuration >= 400) ? MicMuteOsdDuration : 1500
        if (MicPttLastActionMode != "" && duration > 800)
            duration := 800
        SetTimer, MicMuteOsdHoldTimer, % -duration
    }
}

GetMicOsdTitle(isMuted) {
    if (IsFunc("L")) {
        key := isMuted ? "Mic_OsdMuted" : "Mic_OsdUnmuted"
        val := L(key)
        if (val != "" && val != key)
            return val
    }
    return isMuted ? "Mic đã tắt" : "Mic đang bật"
}

GetMicOsdSubtitle() {
    global MicPttKeyHeld, MicPttActionMode, MicPttLastActionMode
    mode := MicPttKeyHeld ? MicPttActionMode : MicPttLastActionMode
    if (mode = "talk")
        return "Push-to-Talk"
    if (mode = "mute")
        return "Push-to-Mute"
    return "Microphone"
}

RenderMicOsdBitmap(w, h, scale, isMuted, titleText, subText) {
    global MicOsdBitmap

    if (MicOsdBitmap) {
        DllCall("DeleteObject", "Ptr", MicOsdBitmap)
        MicOsdBitmap := 0
    }

    pBitmap := 0, pGraphics := 0
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", w, "Int", h, "Int", 0, "Int", 0xE200B, "Ptr", 0, "Ptr*", pBitmap) ; PixelFormat32bppPARGB
    if (!pBitmap)
        return false

    DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBitmap, "Ptr*", pGraphics)
    if (!pGraphics) {
        DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
        return false
    }

    DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", 4)      ; SmoothingModeAntiAlias
    DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", pGraphics, "Int", 2)   ; PixelOffsetModeHalf
    DllCall("gdiplus\GdipSetTextRenderingHint", "Ptr", pGraphics, "Int", 4) ; TextRenderingHintAntiAliasGridFit
    DllCall("gdiplus\GdipGraphicsClear", "Ptr", pGraphics, "UInt", 0x00000000)

    ; Nền pill bo góc tối mờ (0xE81C1E22) + viền mảnh
    radius := h / 2.0
    bgColor := 0xE81C1E22
    borderColor := isMuted ? 0x66FF4D4F : 0x662ECC71

    pPath := CreateRoundedRectPath(1.0, 1.0, w - 2.0, h - 2.0, radius - 1.0)
    if (pPath) {
        pBgBrush := 0
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", bgColor, "Ptr*", pBgBrush)
        if (pBgBrush) {
            DllCall("gdiplus\GdipFillPath", "Ptr", pGraphics, "Ptr", pBgBrush, "Ptr", pPath)
            DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBgBrush)
        }
        pBorderPen := 0
        DllCall("gdiplus\GdipCreatePen1", "UInt", borderColor, "Float", 1.2 * scale, "Int", 2, "Ptr*", pBorderPen)
        if (pBorderPen) {
            DllCall("gdiplus\GdipDrawPath", "Ptr", pGraphics, "Ptr", pBorderPen, "Ptr", pPath)
            DllCall("gdiplus\GdipDeletePen", "Ptr", pBorderPen)
        }
        DllCall("gdiplus\GdipDeletePath", "Ptr", pPath)
    }

    ; Vòng tròn nền cho icon micro bên trái
    badgeSize := 36.0 * scale
    badgeX := 11.0 * scale
    badgeY := (h - badgeSize) / 2.0
    badgeFill := isMuted ? 0x33FF4D4F : 0x332ECC71
    accentColor := isMuted ? 0xFFFF5A5F : 0xFF34D399

    pBadgeBrush := 0
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", badgeFill, "Ptr*", pBadgeBrush)
    if (pBadgeBrush) {
        DllCall("gdiplus\GdipFillEllipse", "Ptr", pGraphics, "Ptr", pBadgeBrush, "Float", badgeX, "Float", badgeY, "Float", badgeSize, "Float", badgeSize)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBadgeBrush)
    }

    ; Vẽ icon vector Microphone ở tâm vòng tròn
    DrawMicVectorIcon(pGraphics, badgeX + badgeSize / 2.0, badgeY + badgeSize / 2.0, scale, accentColor, isMuted)

    ; Vẽ chữ tiêu đề & phụ đề
    textX := badgeX + badgeSize + 12.0 * scale
    textW := w - textX - 14.0 * scale
    DrawMicOsdText(pGraphics, titleText, textX, 9.0 * scale, textW, 22.0 * scale, 11.0 * scale, 1, 0xFFFFFFFF)
    DrawMicOsdText(pGraphics, subText,   textX, 30.0 * scale, textW, 18.0 * scale, 8.5 * scale,  0, 0xFFB8C0CC)

    hBitmap := 0
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", hBitmap, "UInt", 0x00000000)
    DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGraphics)
    DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)

    if (!hBitmap)
        return false

    MicOsdBitmap := hBitmap
    return true
}

CreateRoundedRectPath(x, y, w, h, r) {
    maxR := (w < h ? w : h) / 2.0
    if (r > maxR)
        r := maxR
    pPath := 0
    DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pPath)
    if (!pPath)
        return 0
    d := r * 2.0
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", x, "Float", y, "Float", d, "Float", d, "Float", 180.0, "Float", 90.0)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", x + w - d, "Float", y, "Float", d, "Float", d, "Float", 270.0, "Float", 90.0)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", x + w - d, "Float", y + h - d, "Float", d, "Float", d, "Float", 0.0, "Float", 90.0)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", x, "Float", y + h - d, "Float", d, "Float", d, "Float", 90.0, "Float", 90.0)
    DllCall("gdiplus\GdipClosePathFigure", "Ptr", pPath)
    return pPath
}

DrawMicVectorIcon(pGraphics, cx, cy, scale, color, isMuted) {
    ; Thân micro (viên nang bo tròn ở giữa)
    capW := 7.6 * scale
    capH := 12.5 * scale
    capX := cx - capW / 2.0
    capY := cy - 8.5 * scale
    pCapPath := CreateRoundedRectPath(capX, capY, capW, capH, capW / 2.0)
    if (pCapPath) {
        pBrush := 0
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", color, "Ptr*", pBrush)
        if (pBrush) {
            DllCall("gdiplus\GdipFillPath", "Ptr", pGraphics, "Ptr", pBrush, "Ptr", pCapPath)
            DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrush)
        }
        DllCall("gdiplus\GdipDeletePath", "Ptr", pCapPath)
    }

    pPen := 0
    DllCall("gdiplus\GdipCreatePen1", "UInt", color, "Float", 1.8 * scale, "Int", 2, "Ptr*", pPen)
    if (pPen) {
        DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pPen, "Int", 2) ; LineCapRound
        DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pPen, "Int", 2)

        ; Khung chữ U đỡ micro
        arcR := 6.6 * scale
        DllCall("gdiplus\GdipDrawArc", "Ptr", pGraphics, "Ptr", pPen, "Float", cx - arcR, "Float", cy - 5.5 * scale, "Float", arcR * 2.0, "Float", 13.0 * scale, "Float", 0.0, "Float", 180.0)
        ; Chân đứng & đế
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPen, "Float", cx, "Float", cy + 7.5 * scale, "Float", cx, "Float", cy + 10.5 * scale)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPen, "Float", cx - 4.0 * scale, "Float", cy + 10.5 * scale, "Float", cx + 4.0 * scale, "Float", cy + 10.5 * scale)
        DllCall("gdiplus\GdipDeletePen", "Ptr", pPen)
    }

    ; Gạch chéo khi Mic đang tắt
    if (isMuted) {
        pSlashPen := 0
        DllCall("gdiplus\GdipCreatePen1", "UInt", 0xFFFF5A5F, "Float", 2.2 * scale, "Int", 2, "Ptr*", pSlashPen)
        if (pSlashPen) {
            DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pSlashPen, "Int", 2)
            DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pSlashPen, "Int", 2)
            DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pSlashPen, "Float", cx - 9.0 * scale, "Float", cy + 9.0 * scale, "Float", cx + 9.0 * scale, "Float", cy - 9.0 * scale)
            DllCall("gdiplus\GdipDeletePen", "Ptr", pSlashPen)
        }
    }
}

DrawMicOsdText(pGraphics, text, x, y, w, h, fontSize, isBold, color) {
    pFamily := 0, pFont := 0, pFormat := 0, pBrush := 0
    DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", "Segoe UI", "Ptr", 0, "Ptr*", pFamily)
    if (!pFamily)
        return
    DllCall("gdiplus\GdipCreateFont", "Ptr", pFamily, "Float", fontSize, "Int", isBold ? 1 : 0, "Int", 3, "Ptr*", pFont) ; UnitPoint = 3
    DllCall("gdiplus\GdipCreateStringFormat", "Int", 0x1000, "UShort", 0, "Ptr*", pFormat) ; StringFormatFlagsNoWrap
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", color, "Ptr*", pBrush)

    if (pFont && pFormat && pBrush) {
        DllCall("gdiplus\GdipSetStringFormatAlign", "Ptr", pFormat, "Int", 0)     ; Near (Left)
        DllCall("gdiplus\GdipSetStringFormatLineAlign", "Ptr", pFormat, "Int", 1) ; Center
        VarSetCapacity(rectF, 16, 0)
        NumPut(x, rectF, 0, "Float"), NumPut(y, rectF, 4, "Float")
        NumPut(w, rectF, 8, "Float"), NumPut(h, rectF, 12, "Float")
        DllCall("gdiplus\GdipDrawString", "Ptr", pGraphics, "WStr", text, "Int", -1, "Ptr", pFont, "Ptr", &rectF, "Ptr", pFormat, "Ptr", pBrush)
    }

    if (pBrush)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrush)
    if (pFormat)
        DllCall("gdiplus\GdipDeleteStringFormat", "Ptr", pFormat)
    if (pFont)
        DllCall("gdiplus\GdipDeleteFont", "Ptr", pFont)
    DllCall("gdiplus\GdipDeleteFontFamily", "Ptr", pFamily)
}

PresentMicOsdBitmap(alpha) {
    global hMicOsdGui, MicOsdBitmap, MicOsdW, MicOsdH, MicOsdX, MicOsdY
    if (!hMicOsdGui || !MicOsdBitmap)
        return

    hdcScreen := DllCall("GetDC", "Ptr", 0, "Ptr")
    hdcMem := DllCall("CreateCompatibleDC", "Ptr", hdcScreen, "Ptr")
    oldBmp := DllCall("SelectObject", "Ptr", hdcMem, "Ptr", MicOsdBitmap, "Ptr")

    VarSetCapacity(ptDst, 8, 0), NumPut(MicOsdX, ptDst, 0, "Int"), NumPut(MicOsdY, ptDst, 4, "Int")
    VarSetCapacity(sz, 8, 0), NumPut(MicOsdW, sz, 0, "Int"), NumPut(MicOsdH, sz, 4, "Int")
    VarSetCapacity(ptSrc, 8, 0)
    VarSetCapacity(blend, 4, 0)
    NumPut(0, blend, 0, "UChar")
    NumPut(0, blend, 1, "UChar")
    NumPut(alpha, blend, 2, "UChar")
    NumPut(1, blend, 3, "UChar") ; AC_SRC_ALPHA

    DllCall("UpdateLayeredWindow", "Ptr", hMicOsdGui, "Ptr", hdcScreen, "Ptr", &ptDst, "Ptr", &sz, "Ptr", hdcMem, "Ptr", &ptSrc, "UInt", 0, "Ptr", &blend, "UInt", 2)

    DllCall("SelectObject", "Ptr", hdcMem, "Ptr", oldBmp)
    DllCall("DeleteDC", "Ptr", hdcMem)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcScreen)
}

MicMuteOsdHoldTimer:
    SetTimer, MicMuteOsdFadeTimer, 16
return

MicMuteOsdFadeTimer:
    MicOsdAlpha -= 24
    if (MicOsdAlpha <= 0) {
        MicOsdAlpha := 0
        SetTimer, MicMuteOsdFadeTimer, Off
        HideMicMuteOsd()
    } else {
        PresentMicOsdBitmap(MicOsdAlpha)
    }
return

HideMicMuteOsd() {
    global hMicOsdGui, MicOsdVisible, MicOsdBitmap
    SetTimer, MicMuteOsdHoldTimer, Off
    SetTimer, MicMuteOsdFadeTimer, Off
    if (hMicOsdGui && MicOsdVisible) {
        DllCall("ShowWindow", "Ptr", hMicOsdGui, "Int", 0) ; SW_HIDE
        MicOsdVisible := false
    }
    if (MicOsdBitmap) {
        DllCall("DeleteObject", "Ptr", MicOsdBitmap)
        MicOsdBitmap := 0
    }
}

; ========================================================
; BADGE GHIM CỐ ĐỊNH Ở GÓC TRÊN-PHẢI KHI MIC TẮT (KIỂU POWERTOYS)
; ========================================================
SyncMicBadgeTimer() {
    global MicMuteEnabled, MicMuteBadgeEnabled
    if (MicMuteEnabled && MicMuteBadgeEnabled)
        SetTimer, MicBadgeSyncTimer, 600
    else
        SetTimer, MicBadgeSyncTimer, Off
}

MicBadgeSyncTimer:
    UpdateMicBadge()
return

UpdateMicBadge(forceState := -1) {
    global MicMuteEnabled, MicMuteBadgeEnabled, MicBadgeLastMuted, MicBadgeVisible
    if (!MicMuteEnabled || !MicMuteBadgeEnabled) {
        MicBadgeLastMuted := -1
        HideMicBadge()
        return
    }
    isMuted := (forceState != -1) ? (forceState ? 1 : 0) : GetMicMuteState()
    if (isMuted = 1) {
        if (!MicBadgeVisible || MicBadgeLastMuted != 1)
            ShowMicBadge()
        MicBadgeLastMuted := 1
    } else {
        if (MicBadgeVisible)
            HideMicBadge()
        MicBadgeLastMuted := (isMuted = 0) ? 0 : -1
    }
}

ShowMicBadge() {
    global hMicBadgeGui, MicBadgeVisible
    if (!EnsureMicGdip())
        return

    if (!hMicBadgeGui)
        Gui, MicBadge:New, +AlwaysOnTop -Caption +ToolWindow +E0x80000 +E0x20 +E0x08000000 +HwndhMicBadgeGui

    scale := A_ScreenDPI / 96.0
    size := Round(38 * scale)

    SysGet, wa, MonitorWorkArea
    bx := Round(waRight - size - 24 * scale)
    by := Round(waTop + 48 * scale)

    pBitmap := 0, pGraphics := 0
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", size, "Int", size, "Int", 0, "Int", 0xE200B, "Ptr", 0, "Ptr*", pBitmap)
    if (!pBitmap)
        return
    DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBitmap, "Ptr*", pGraphics)
    if (!pGraphics) {
        DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
        return
    }

    DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", 4)
    DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", pGraphics, "Int", 2)
    DllCall("gdiplus\GdipGraphicsClear", "Ptr", pGraphics, "UInt", 0x00000000)

    ; Vòng tròn tối mờ nhẹ + viền đỏ dịu
    pBgBrush := 0
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0xCC1C1E22, "Ptr*", pBgBrush)
    if (pBgBrush) {
        DllCall("gdiplus\GdipFillEllipse", "Ptr", pGraphics, "Ptr", pBgBrush, "Float", 1.5, "Float", 1.5, "Float", size - 3.0, "Float", size - 3.0)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBgBrush)
    }
    pPen := 0
    DllCall("gdiplus\GdipCreatePen1", "UInt", 0xAAFF4D4F, "Float", 1.3 * scale, "Int", 2, "Ptr*", pPen)
    if (pPen) {
        DllCall("gdiplus\GdipDrawEllipse", "Ptr", pGraphics, "Ptr", pPen, "Float", 1.5, "Float", 1.5, "Float", size - 3.0, "Float", size - 3.0)
        DllCall("gdiplus\GdipDeletePen", "Ptr", pPen)
    }

    DrawMicVectorIcon(pGraphics, size / 2.0, size / 2.0, scale * 0.85, 0xFFFF5A5F, true)

    hBitmap := 0
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", hBitmap, "UInt", 0x00000000)
    DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGraphics)
    DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
    if (!hBitmap)
        return

    hdcScreen := DllCall("GetDC", "Ptr", 0, "Ptr")
    hdcMem := DllCall("CreateCompatibleDC", "Ptr", hdcScreen, "Ptr")
    oldBmp := DllCall("SelectObject", "Ptr", hdcMem, "Ptr", hBitmap, "Ptr")

    VarSetCapacity(ptDst, 8, 0), NumPut(bx, ptDst, 0, "Int"), NumPut(by, ptDst, 4, "Int")
    VarSetCapacity(sz, 8, 0), NumPut(size, sz, 0, "Int"), NumPut(size, sz, 4, "Int")
    VarSetCapacity(ptSrc, 8, 0)
    VarSetCapacity(blend, 4, 0)
    NumPut(0, blend, 0, "UChar")
    NumPut(0, blend, 1, "UChar")
    NumPut(185, blend, 2, "UChar") ; Mờ nhẹ (~72% opacity)
    NumPut(1, blend, 3, "UChar")

    DllCall("UpdateLayeredWindow", "Ptr", hMicBadgeGui, "Ptr", hdcScreen, "Ptr", &ptDst, "Ptr", &sz, "Ptr", hdcMem, "Ptr", &ptSrc, "UInt", 0, "Ptr", &blend, "UInt", 2)

    DllCall("SelectObject", "Ptr", hdcMem, "Ptr", oldBmp)
    DllCall("DeleteObject", "Ptr", hBitmap)
    DllCall("DeleteDC", "Ptr", hdcMem)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcScreen)

    DllCall("ShowWindow", "Ptr", hMicBadgeGui, "Int", 8) ; SW_SHOWNA
    DllCall("SetWindowPos", "Ptr", hMicBadgeGui, "Ptr", -1, "Int", bx, "Int", by, "Int", size, "Int", size, "UInt", 0x0053)
    MicBadgeVisible := true
}

HideMicBadge() {
    global hMicBadgeGui, MicBadgeVisible
    if (hMicBadgeGui && MicBadgeVisible) {
        DllCall("ShowWindow", "Ptr", hMicBadgeGui, "Int", 0) ; SW_HIDE
        MicBadgeVisible := false
    }
}

; ========================================================
; DỌN DẸP TÀI NGUYÊN KHI THOÁT
; ========================================================
CleanupMicMute() {
    global hMicOsdGui, hMicBadgeGui, MicOsdBitmap, MicGdipToken, MicGdipModule
    SetTimer, MicMuteWatchKeyUpTimer, Off
    SetTimer, MicMutePttReleaseTimer, Off
    SetTimer, MicBadgeSyncTimer, Off
    HideMicMuteOsd()
    HideMicBadge()
    if (hMicOsdGui) {
        try Gui, MicOsd:Destroy
        hMicOsdGui := 0
    }
    if (hMicBadgeGui) {
        try Gui, MicBadge:Destroy
        hMicBadgeGui := 0
    }
    if (MicOsdBitmap) {
        DllCall("DeleteObject", "Ptr", MicOsdBitmap)
        MicOsdBitmap := 0
    }
    if (MicGdipToken) {
        DllCall("gdiplus\GdiplusShutdown", "Ptr", MicGdipToken)
        MicGdipToken := 0
    }
    if (MicGdipModule) {
        DllCall("FreeLibrary", "Ptr", MicGdipModule)
        MicGdipModule := 0
    }
}

; Chuyển đổi chuỗi phím tắt AHK (vd: #!m, RCtrl, XButton1) sang dạng dễ đọc
FormatMicHotkeyText(hk) {
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
    else if (StrLen(keyPart) = 1)
        StringUpper, keyPart, keyPart
    return res . keyPart
}
