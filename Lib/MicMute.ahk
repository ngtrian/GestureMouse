; MicMute.ahk - Quản lý tắt/bật Microphone (WASAPI Core Audio + Toggle / Push-to-Talk / Push-to-Mute + GDI+ OSD tự ẩn)
#NoEnv

; ========================================================
; KHỞI TẠO MODULE MIC MUTE
; ========================================================
InitMicMute() {
    global MicMuteEnabled, MicMuteMode, MicMuteHotkey, MicMuteAllDevices
    global MicMuteReleaseDelay, MicMuteOsdEnabled, MicMuteOsdDuration, MicMuteBeepEnabled
    global MicMuteRegisteredHk, MicMuteRegisteredUpHk, MicMuteKeyHeld
    global MicMutePtmPrevMuted, MicMutePendingRelease
    global hMicOsdGui, MicOsdVisible, MicOsdAlpha, MicOsdBitmap, MicOsdW, MicOsdH, MicOsdX, MicOsdY
    global MicGdipModule, MicGdipToken

    MicMuteEnabled       := 1
    MicMuteMode          := 0          ; 0: Toggle, 1: Push-to-Talk, 2: Push-to-Mute
    MicMuteHotkey        := "^+a"      ; Mặc định: Ctrl + Shift + A (giống PowerToys)
    MicMuteAllDevices    := 1          ; 1: Áp dụng tất cả thiết bị thu đang hoạt động, 0: Chỉ thiết bị mặc định
    MicMuteReleaseDelay  := 200        ; Độ trễ (ms) trước khi tắt mic lại khi nhả phím ở chế độ Push-to-Talk
    MicMuteOsdEnabled    := 1          ; 1: Hiển thị OSD GDI+ tự ẩn khi chuyển trạng thái
    MicMuteOsdDuration   := 1500       ; Thời gian hiển thị OSD (ms) trước khi mờ dần
    MicMuteBeepEnabled   := 0          ; 1: Phát tiếng bíp nhẹ phản hồi khi đổi trạng thái

    MicMuteRegisteredHk   := ""
    MicMuteRegisteredUpHk := ""
    MicMuteKeyHeld        := false
    MicMutePtmPrevMuted   := false
    MicMutePendingRelease := false

    hMicOsdGui   := 0
    MicOsdVisible := false
    MicOsdAlpha  := 255
    MicOsdBitmap := 0
    MicOsdW := 0, MicOsdH := 0, MicOsdX := 0, MicOsdY := 0
    MicGdipModule := 0
    MicGdipToken  := 0

    LoadMicMuteSettings()
    ApplyMicMuteHotkey()

    ; Nếu đang ở chế độ Push-to-Talk khi khởi động, đảm bảo mic mặc định ở trạng thái tắt
    if (MicMuteEnabled && MicMuteMode = 1)
        SetMicMuteState(true, false)

    OnExit("CleanupMicMute")
}

LoadMicMuteSettings() {
    global MicMuteEnabled, MicMuteMode, MicMuteHotkey, MicMuteAllDevices
    global MicMuteReleaseDelay, MicMuteOsdEnabled, MicMuteOsdDuration, MicMuteBeepEnabled

    regKey := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"

    RegRead, val, %regKey%, MicMuteEnabled
    if (!ErrorLevel && val != "")
        MicMuteEnabled := val ? 1 : 0

    RegRead, val, %regKey%, MicMuteMode
    if (!ErrorLevel && val != "") {
        val += 0
        if (val >= 0 && val <= 2)
            MicMuteMode := val
    }

    RegRead, val, %regKey%, MicMuteHotkey
    if (!ErrorLevel && val != "")
        MicMuteHotkey := val

    RegRead, val, %regKey%, MicMuteAllDevices
    if (!ErrorLevel && val != "")
        MicMuteAllDevices := val ? 1 : 0

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

    RegRead, val, %regKey%, MicMuteBeepEnabled
    if (!ErrorLevel && val != "")
        MicMuteBeepEnabled := val ? 1 : 0
}

SaveMicMuteSettings() {
    global MicMuteEnabled, MicMuteMode, MicMuteHotkey, MicMuteAllDevices
    global MicMuteReleaseDelay, MicMuteOsdEnabled, MicMuteOsdDuration, MicMuteBeepEnabled

    regKey := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"
    RegWrite, REG_DWORD, %regKey%, MicMuteEnabled, %MicMuteEnabled%
    RegWrite, REG_DWORD, %regKey%, MicMuteMode, %MicMuteMode%
    RegWrite, REG_SZ,    %regKey%, MicMuteHotkey, %MicMuteHotkey%
    RegWrite, REG_DWORD, %regKey%, MicMuteAllDevices, %MicMuteAllDevices%
    RegWrite, REG_DWORD, %regKey%, MicMuteReleaseDelay, %MicMuteReleaseDelay%
    RegWrite, REG_DWORD, %regKey%, MicMuteOsdEnabled, %MicMuteOsdEnabled%
    RegWrite, REG_DWORD, %regKey%, MicMuteOsdDuration, %MicMuteOsdDuration%
    RegWrite, REG_DWORD, %regKey%, MicMuteBeepEnabled, %MicMuteBeepEnabled%
}

; ========================================================
; ĐĂNG KÝ & XỬ LÝ PHÍM TẮT (TOGGLE / PTT / PTM)
; ========================================================
ApplyMicMuteHotkey() {
    global MicMuteEnabled, MicMuteHotkey, MicMuteMode
    global MicMuteRegisteredHk, MicMuteRegisteredUpHk

    ; Gỡ phím tắt cũ nếu có
    if (MicMuteRegisteredHk != "") {
        try Hotkey, %MicMuteRegisteredHk%, MicMuteKeyDownHandler, Off
        MicMuteRegisteredHk := ""
    }
    if (MicMuteRegisteredUpHk != "") {
        try Hotkey, %MicMuteRegisteredUpHk%, MicMuteKeyUpHandler, Off
        MicMuteRegisteredUpHk := ""
    }

    if (!MicMuteEnabled || MicMuteHotkey = "")
        return

    hkDown := MicMuteHotkey
    try {
        Hotkey, %hkDown%, MicMuteKeyDownHandler, On
        MicMuteRegisteredHk := hkDown
    } catch {
        MicMuteRegisteredHk := ""
        return
    }

    ; Nếu là Push-to-Talk hoặc Push-to-Mute, đăng ký thêm sự kiện nhả phím
    if (MicMuteMode = 1 || MicMuteMode = 2) {
        hkUp := MicMuteHotkey . " Up"
        try {
            Hotkey, %hkUp%, MicMuteKeyUpHandler, On
            MicMuteRegisteredUpHk := hkUp
        } catch {
            MicMuteRegisteredUpHk := ""
        }
    }
}

; Cập nhật chế độ hoạt động từ bên ngoài (Toggle / PTT / PTM)
SetMicMuteMode(newMode) {
    global MicMuteMode, MicMuteEnabled, MicMuteKeyHeld, MicMutePendingRelease
    if (newMode < 0 || newMode > 2)
        return
    SetTimer, MicMuteWatchKeyUpTimer, Off
    SetTimer, MicMutePttReleaseTimer, Off
    MicMuteKeyHeld := false
    MicMutePendingRelease := false
    MicMuteMode := newMode
    SaveMicMuteSettings()
    ApplyMicMuteHotkey()
    if (MicMuteEnabled && MicMuteMode = 1)
        SetMicMuteState(true, true)
}

MicMuteKeyDownHandler:
    HandleMicMuteKeyDown()
return

MicMuteKeyUpHandler:
    HandleMicMuteKeyUp()
return

HandleMicMuteKeyDown() {
    global MicMuteEnabled, MicMuteMode, MicMuteKeyHeld, MicMutePtmPrevMuted, MicMutePendingRelease
    if (!MicMuteEnabled)
        return

    if (MicMuteMode = 0) {
        ; Chế độ Toggle: Đảo trạng thái hiện tại
        ToggleMicMute(true)
        return
    }

    ; Chế độ PTT (1) hoặc PTM (2): Bỏ qua sự kiện lặp phím (auto-repeat) khi đang giữ
    if (MicMuteKeyHeld)
        return
    MicMuteKeyHeld := true

    if (MicMuteMode = 1) {
        ; Push-to-Talk: Hủy timer trễ (nếu đang chờ tắt) và mở mic ngay
        if (MicMutePendingRelease) {
            SetTimer, MicMutePttReleaseTimer, Off
            MicMutePendingRelease := false
        }
        if (GetMicMuteState() != 0)
            SetMicMuteState(false, true)
        else
            ShowMicMuteOsd(false)
    } else if (MicMuteMode = 2) {
        ; Push-to-Mute: Lưu trạng thái trước khi nhấn và tắt mic tạm thời
        curMuted := GetMicMuteState()
        MicMutePtmPrevMuted := (curMuted = 1)
        if (!MicMutePtmPrevMuted)
            SetMicMuteState(true, true)
        else
            ShowMicMuteOsd(true)
    }

    ; Timer dự phòng đề phòng người dùng nhả phím bổ trợ (Ctrl/Shift/Alt/Win) trước phím chính
    SetTimer, MicMuteWatchKeyUpTimer, 30
}

HandleMicMuteKeyUp() {
    global MicMuteMode, MicMuteKeyHeld, MicMuteReleaseDelay, MicMutePtmPrevMuted, MicMutePendingRelease
    if (!MicMuteKeyHeld)
        return
    MicMuteKeyHeld := false
    SetTimer, MicMuteWatchKeyUpTimer, Off

    if (MicMuteMode = 1) {
        ; Push-to-Talk: Tắt mic lại (có hỗ trợ trễ nhả phím để không mất âm cuối câu)
        if (MicMuteReleaseDelay > 0) {
            MicMutePendingRelease := true
            SetTimer, MicMutePttReleaseTimer, % -MicMuteReleaseDelay
        } else {
            SetMicMuteState(true, true)
        }
    } else if (MicMuteMode = 2) {
        ; Push-to-Mute: Chỉ mở lại mic nếu trước đó mic không bị tắt sẵn
        if (!MicMutePtmPrevMuted)
            SetMicMuteState(false, true)
    }
}

MicMutePttReleaseTimer:
    MicMutePendingRelease := false
    if (!MicMuteKeyHeld && MicMuteMode = 1)
        SetMicMuteState(true, true)
return

MicMuteWatchKeyUpTimer:
    if (!IsMicHotkeyPhysicallyDown(MicMuteHotkey))
        HandleMicMuteKeyUp()
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

; Lấy trạng thái mute của thiết bị thu mặc định (1: đang tắt, 0: đang bật, -1: không tìm thấy mic)
GetMicMuteState() {
    enumerator := 0, device := 0, epVol := 0
    result := -1
    try {
        enumerator := ComObjCreate("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
        if (!enumerator)
            return -1
        ; IMMDeviceEnumerator::GetDefaultAudioEndpoint(eCapture = 1, eConsole = 0, &device)
        hr := DllCall(NumGet(NumGet(enumerator + 0) + 4 * A_PtrSize), "Ptr", enumerator, "UInt", 1, "UInt", 0, "Ptr*", device)
        if (hr != 0 || !device) {
            ; Fallback sang eCommunications = 2
            hr := DllCall(NumGet(NumGet(enumerator + 0) + 4 * A_PtrSize), "Ptr", enumerator, "UInt", 1, "UInt", 2, "Ptr*", device)
        }
        if (hr = 0 && device) {
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

; Đặt trạng thái mute cho thiết bị thu (tất cả thiết bị đang bật hoặc chỉ thiết bị mặc định)
SetMicMuteState(mute, showFeedback := true) {
    global MicMuteAllDevices, MicMuteOsdEnabled, MicMuteBeepEnabled

    bMute := mute ? 1 : 0
    changedAny := false
    enumerator := 0, collection := 0, device := 0, epVol := 0

    try {
        enumerator := ComObjCreate("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
        if (!enumerator)
            return false

        if (MicMuteAllDevices) {
            ; IMMDeviceEnumerator::EnumAudioEndpoints(eCapture = 1, DEVICE_STATE_ACTIVE = 1, &collection) - index 3
            hr := DllCall(NumGet(NumGet(enumerator + 0) + 3 * A_PtrSize), "Ptr", enumerator, "UInt", 1, "UInt", 1, "Ptr*", collection)
            if (hr = 0 && collection) {
                count := 0
                ; IMMDeviceCollection::GetCount(&count) - index 3
                DllCall(NumGet(NumGet(collection + 0) + 3 * A_PtrSize), "Ptr", collection, "UInt*", count)
                Loop, %count% {
                    idx := A_Index - 1
                    dev := 0, vol := 0
                    ; IMMDeviceCollection::Item(idx, &dev) - index 4
                    if (DllCall(NumGet(NumGet(collection + 0) + 4 * A_PtrSize), "Ptr", collection, "UInt", idx, "Ptr*", dev) = 0 && dev) {
                        vol := ActivateAudioEndpointVolume(dev)
                        if (vol) {
                            ; IAudioEndpointVolume::SetMute(bMute, NULL) - index 14
                            if (DllCall(NumGet(NumGet(vol + 0) + 14 * A_PtrSize), "Ptr", vol, "Int", bMute, "Ptr", 0) = 0)
                                changedAny := true
                            ObjRelease(vol)
                        }
                        ObjRelease(dev)
                    }
                }
            }
        }

        ; Đảm bảo thiết bị mặc định (eConsole + eCommunications) cũng được đồng bộ
        if (!MicMuteAllDevices || !changedAny) {
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

    if (changedAny && showFeedback) {
        if (MicMuteOsdEnabled)
            ShowMicMuteOsd(bMute)
        if (MicMuteBeepEnabled)
            PlayMicMuteBeep(bMute)
    }
    return changedAny
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
    global MicMuteMode, MicOsdW, MicOsdH, MicOsdX, MicOsdY

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

    duration := (MicMuteOsdDuration >= 400) ? MicMuteOsdDuration : 1500
    SetTimer, MicMuteOsdHoldTimer, % -duration
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
    global MicMuteMode
    if (MicMuteMode = 1)
        return "Push-to-Talk"
    if (MicMuteMode = 2)
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
; DỌN DẸP TÀI NGUYÊN KHI THOÁT
; ========================================================
CleanupMicMute() {
    global hMicOsdGui, MicOsdBitmap, MicGdipToken, MicGdipModule
    SetTimer, MicMuteWatchKeyUpTimer, Off
    SetTimer, MicMutePttReleaseTimer, Off
    HideMicMuteOsd()
    if (hMicOsdGui) {
        try Gui, MicOsd:Destroy
        hMicOsdGui := 0
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
