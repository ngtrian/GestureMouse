; LockManager.ahk - Trung tâm Khóa hợp nhất (Khóa phím & chuột, Khóa màn hình Windows, Focus Lock, Hẹn giờ & Lặp lại)
#NoEnv

#Include *i Language.ahk

; ========================================================
; KHAI BÁO BIẾN TOÀN CỤC CHO HỆ THỐNG KHÓA HỢP NHẤT
; ========================================================
global isLocked                  := 0         ; Trạng thái khóa thiết bị (1: Đang khóa, 0: Mở)
global lockMode                  := 0         ; 0: Full Lock, 1: Focus Lock
global hFocusWnd                 := 0         ; HWND cửa sổ đang được Focus Lock
global focusWndTitle             := ""        ; Tiêu đề cửa sổ Focus Lock
global hPendingFocusWnd          := 0         ; HWND cửa sổ active ngay trước khi mở Trung tâm Khóa
global pendingFocusTitle         := ""        ; Tiêu đề cửa sổ mục tiêu tiềm năng

; Cấu hình thiết bị & ngoại lệ (Lưu trong Settings)
global lockKeyboardEnabled       := 1
global mouseLockEnabled          := 1
global lockMouseClick            := 1
global lockMouseWheel            := 0
global lockMouseMove             := 0
global allowMouseMove            := 1
global allowMouseWheel           := 0
global allowSpace                := 0
global allowMedia                := 0
global allowNav                  := 0
global autoLockIdleEnabled       := 1
global autoLockIdleMinutes       := 5
global disableAutoLockScreen     := 1
global UNLOCK_KEYWORD            := "unlock"
global KEYWORD_LENGTH            := 6
global requireCodeForTimerEdit   := 1         ; Yêu cầu mã mở khóa khi sửa/hủy hẹn giờ đang chạy

; Cấu hình Trung tâm Khóa gần nhất
global centerLockType            := 0         ; 0: Full Lock, 1: Windows Screen Lock, 2: Focus Lock
global centerUseTimer            := 0         ; 0: Khóa ngay, 1: Hẹn giờ
global centerTimerMinutes        := 5         ; Số phút hẹn giờ mặc định
global centerRepeat              := 0         ; 0: Một lần, 1: Lặp lại định kỳ

; Trạng thái bộ đếm ngược đang chạy
global lockTimerActive           := 0
global lockTimerType             := 0         ; 0: Full Lock, 1: Windows Screen Lock
global lockTimerMinutes          := 5
global lockTimerRepeat           := 0
global lockTimerTargetTick       := 0
global lockTimerLastDisplayed    := ""
global pendingRepeatFullLock     := 0
global pendingRepeatMinutes      := 0

; Handles & UI state
global hKeyboardHook             := 0
global hMouseHook                := 0
global Buffer                    := ""
global hLockCenterGui            := 0
global hLockCountdownGui         := 0
global centerEditUnlocked        := 1

; Biến control của GUI Trung tâm Khóa
global CenterActiveBanner, CenterType0, CenterType1, CenterType2, CenterFocusTargetTxt
global CenterTimerGroup, CenterTimingNow, CenterTimingTimer, CenterMinutesInput, CenterMinutesUpDown, CenterMinUnitTxt
global CenterPreset5, CenterPreset15, CenterPreset30, CenterPreset60, CenterRepeatCheck
global CenterFocusInfoGroup, CenterFocusInfoTxt
global CenterAuthGroup, CenterAuthLabel, CenterAuthInput, CenterAuthBtn
global CenterBtnApply, CenterBtnCancelTimer, CenterBtnClose

; ========================================================
; PHÍM TẮT DUY NHẤT CTRL + ALT + L (HOẠT ĐỘNG MỌI LÚC)
; ========================================================
#If
LockCenterHotkey:
^!l::
    KeyWait, Ctrl
    KeyWait, Alt
    KeyWait, l
    HandleLockCenterHotkey()
return

; ========================================================
; KHỞI TẠO & ĐỌC CẤU HÌNH TỪ REGISTRY
; ========================================================
InitLockManager() {
    LoadLockSettings()
    InitAutoLockTimer()
    ResumePendingRepeatIfNeeded()
}

LoadLockSettings() {
    global
    regPath := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"

    RegRead, val, %regPath%, LockKeyboard
    lockKeyboardEnabled := (val != "") ? val : 1

    RegRead, val, %regPath%, mouseLockEnabled
    mouseLockEnabled := (val != "") ? val : 1

    RegRead, val, %regPath%, LockMouseClick
    lockMouseClick := (val != "") ? val : 1

    RegRead, val, %regPath%, LockMouseWheel
    lockMouseWheel := (val != "") ? val : 0

    RegRead, val, %regPath%, LockMouseMove
    lockMouseMove := (val != "") ? val : 0

    RegRead, val, %regPath%, AllowMouseMove
    allowMouseMove := (val != "") ? val : 1

    RegRead, val, %regPath%, AllowMouseWheel
    allowMouseWheel := (val != "") ? val : 0

    RegRead, val, %regPath%, AllowSpace
    allowSpace := (val != "") ? val : 0

    RegRead, val, %regPath%, AllowMedia
    allowMedia := (val != "") ? val : 0

    RegRead, val, %regPath%, AllowNav
    allowNav := (val != "") ? val : 0

    RegRead, val, %regPath%, AutoLockIdleEnabled
    autoLockIdleEnabled := (val != "") ? val : 1

    RegRead, val, %regPath%, AutoLockIdleMinutes
    if (val != "")
        autoLockIdleMinutes := val
    else {
        RegRead, valOld, %regPath%, AutoLockMinutes
        autoLockIdleMinutes := (valOld != "") ? valOld : 5
    }

    RegRead, val, %regPath%, UnlockKeyword
    if (val != "")
        UNLOCK_KEYWORD := val
    else if (!UNLOCK_KEYWORD)
        UNLOCK_KEYWORD := "unlock"
    KEYWORD_LENGTH := StrLen(UNLOCK_KEYWORD)

    RegRead, val, %regPath%, DisableAutoLockScreen
    disableAutoLockScreen := (val != "") ? val : 1

    RegRead, val, %regPath%, RequireCodeForTimerEdit
    requireCodeForTimerEdit := (val != "") ? val : 1

    RegRead, val, %regPath%, CenterLockType
    centerLockType := (val != "" && val >= 0 && val <= 2) ? val + 0 : 0

    RegRead, val, %regPath%, CenterUseTimer
    centerUseTimer := (val != "") ? (val ? 1 : 0) : 0

    RegRead, val, %regPath%, CenterTimerMinutes
    centerTimerMinutes := (val != "" && val > 0) ? val + 0 : 5

    RegRead, val, %regPath%, CenterRepeat
    centerRepeat := (val != "") ? (val ? 1 : 0) : 0
}

SaveLockCenterPreferences() {
    global centerLockType, centerUseTimer, centerTimerMinutes, centerRepeat
    regPath := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"
    RegWrite, REG_DWORD, %regPath%, CenterLockType, %centerLockType%
    RegWrite, REG_DWORD, %regPath%, CenterUseTimer, %centerUseTimer%
    RegWrite, REG_DWORD, %regPath%, CenterTimerMinutes, %centerTimerMinutes%
    RegWrite, REG_DWORD, %regPath%, CenterRepeat, %centerRepeat%
}

; ========================================================
; TỰ ĐỘNG KHÓA KHI KHÔNG DÙNG MÁY (IDLE AUTO-LOCK)
; ========================================================
InitAutoLockTimer() {
    global autoLockIdleEnabled, autoLockIdleMinutes
    if (autoLockIdleEnabled && autoLockIdleMinutes > 0)
        SetTimer, CheckAutoLockIdle, 4000
    else
        SetTimer, CheckAutoLockIdle, Off
}

CheckAutoLockIdle:
    if (isLocked)
        return
    if (autoLockIdleEnabled && autoLockIdleMinutes > 0) {
        idleSeconds := A_TimeIdlePhysical // 1000
        thresholdSec := autoLockIdleMinutes * 60
        if (idleSeconds >= thresholdSec) {
            ActivateLock(0)
        }
    }
return

; ========================================================
; XỬ LÝ PHÍM TẮT TRUNG TÂM KHÓA & KHÔI PHỤC CHU KỲ LẶP LẠI
; ========================================================
HandleLockCenterHotkey() {
    global isLocked, hLockCenterGui, hPendingFocusWnd, pendingFocusTitle

    if (isLocked) {
        SetTimer, TriggerWindowsAuthPrompt, -1
        return
    }

    candHwnd := WinExist("A")
    if (candHwnd && candHwnd != hLockCenterGui) {
        hPendingFocusWnd := candHwnd
        WinGetTitle, pendingFocusTitle, ahk_id %hPendingFocusWnd%
    }

    ShowLockCenterGUI()
}

; Gọi từ Settings hoặc Menu Tray để lấy cửa sổ nền bên dưới làm mục tiêu Focus
OpenLockCenterFromUI(hideOwnerGui := "") {
    global hPendingFocusWnd, pendingFocusTitle, isLocked
    if (isLocked) {
        SetTimer, TriggerWindowsAuthPrompt, -1
        return
    }
    if (hideOwnerGui != "") {
        Gui, %hideOwnerGui%:Hide
        Sleep, 150
    }
    hPendingFocusWnd := WinExist("A")
    if (hPendingFocusWnd)
        WinGetTitle, pendingFocusTitle, ahk_id %hPendingFocusWnd%
    else
        pendingFocusTitle := ""
    ShowLockCenterGUI()
}

ResumePendingRepeatIfNeeded() {
    regPath := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"
    RegRead, resumeNow, %regPath%, PendingRepeatResumeNow
    if (resumeNow == 1) {
        RegRead, rType, %regPath%, PendingRepeatType
        RegRead, rMins, %regPath%, PendingRepeatMinutes
        RegWrite, REG_DWORD, %regPath%, PendingRepeatResumeNow, 0
        RegWrite, REG_DWORD, %regPath%, PendingRepeatActive, 0
        rType := (rType = 1) ? 1 : 0
        rMins := (rMins > 0) ? rMins + 0 : 5
        StartLockCountdown(rType, rMins, 1)
    }
}

OnWindowsSessionUnlocked() {
    global isLocked, pendingRepeatFullLock, pendingRepeatMinutes
    regPath := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"

    RegRead, waitUnlock, %regPath%, PendingRepeatActive
    if (waitUnlock == 1) {
        RegWrite, REG_DWORD, %regPath%, PendingRepeatResumeNow, 1
        RegWrite, REG_DWORD, %regPath%, PendingRepeatActive, 0
    } else if (isLocked && pendingRepeatFullLock && pendingRepeatMinutes > 0) {
        RegWrite, REG_DWORD, %regPath%, PendingRepeatType, 0
        RegWrite, REG_DWORD, %regPath%, PendingRepeatMinutes, %pendingRepeatMinutes%
        RegWrite, REG_DWORD, %regPath%, PendingRepeatResumeNow, 1
        pendingRepeatFullLock := 0
    }

    if (isLocked)
        UnlockKeyboard(true)
}

; ========================================================
; GIAO DIỆN TRUNG TÂM KHÓA HỢP NHẤT (LOCK CENTER GUI)
; ========================================================
ShowLockCenterGUI() {
    global
    if (!LangTable || !LangTable.HasKey("en")) {
        if (IsFunc("InitLanguage"))
            InitLanguage()
    }
    LoadLockSettings()

    if (hLockCenterGui && WinExist("ahk_id " . hLockCenterGui)) {
        WinActivate, ahk_id %hLockCenterGui%
        return
    }

    Gui, LockCenter:Destroy
    Gui, LockCenter:New, +AlwaysOnTop -MaximizeBox -MinimizeBox +HwndhLockCenterGui, % L("LC_Title")
    if (IsFunc("SetGuiYellowIcon"))
        SetGuiYellowIcon(hLockCenterGui)

    Gui, Font, s9.5 Norm c222222, Segoe UI

    ; Xác định trạng thái bảo vệ khi đang có hẹn giờ đếm ngược
    centerEditUnlocked := (lockTimerActive && requireCodeForTimerEdit) ? 0 : 1

    ; Nếu đang chạy đếm ngược: ưu tiên hiển thị cấu hình đang chạy
    dispType := lockTimerActive ? lockTimerType : centerLockType
    dispTiming := lockTimerActive ? 1 : centerUseTimer
    dispMinutes := lockTimerActive ? lockTimerMinutes : centerTimerMinutes
    dispRepeat := lockTimerActive ? lockTimerRepeat : centerRepeat

    chkType0 := (dispType == 0) ? 1 : 0
    chkType1 := (dispType == 1) ? 1 : 0
    chkType2 := (dispType == 2) ? 1 : 0

    chkTimeNow := (dispTiming == 0) ? 1 : 0
    chkTimeSet := (dispTiming == 1) ? 1 : 0

    yOffset := 12

    ; Banner trạng thái khi đang đếm ngược
    if (lockTimerActive) {
        Gui, Add, Progress, x15 y12 w390 h36 BackgroundE5F1FB cE5F1FB -Theme Disabled, 100
        Gui, Add, Progress, x15 y12 w4 h36 Background0067C0 c0067C0 -Theme Disabled, 100
        Gui, Font, s9.5 Bold c004499, Segoe UI
        Gui, Add, Text, x28 y12 w370 h36 +0x200 +BackgroundTrans vCenterActiveBanner, % "⏱️ " . GetActiveTimerStatusText()
        Gui, Font, s9.5 Norm c222222, Segoe UI
        yOffset := 58
    }

    ; Nhóm 1: Kiểu khóa
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x15 y%yOffset% w390 h124, % "  🔐 " . L("LC_GroupMode")
    Gui, Font, s9.5 Norm c222222, Segoe UI

    yR1 := yOffset + 25
    yR2 := yOffset + 51
    yR3 := yOffset + 77
    yTarget := yOffset + 100

    Gui, Add, Radio, x30 y%yR1% w360 vCenterType0 gOnLockCenterTypeChange Group Checked%chkType0%, % "🔒 " . L("LC_ModeFull")
    Gui, Add, Radio, x30 y%yR2% w360 vCenterType1 gOnLockCenterTypeChange Checked%chkType1%, % "🖥️ " . L("LC_ModeScreen")
    Gui, Add, Radio, x30 y%yR3% w360 vCenterType2 gOnLockCenterTypeChange Checked%chkType2%, % "🎯 " . L("LC_ModeFocus")

    shortTarget := GetShortFocusTargetTitle()
    targetText := (shortTarget != "") ? StrReplace(L("LC_FocusTarget"), "{title}", shortTarget) : L("LC_FocusNoTarget")
    Gui, Font, s8.5 Norm c005FB8, Segoe UI
    Gui, Add, Text, x48 y%yTarget% w342 vCenterFocusTargetTxt, %targetText%
    Gui, Font, s9.5 Norm c222222, Segoe UI

    ; Nhóm 2: Thời gian & Lặp lại (ẩn khi chọn Focus Lock)
    ySec2 := yOffset + 134
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x15 y%ySec2% w390 h136 vCenterTimerGroup, % "  ⏱️ " . L("LC_GroupTiming")
    Gui, Font, s9.5 Norm c222222, Segoe UI

    yT1 := ySec2 + 26
    yT2 := ySec2 + 54
    yPre := ySec2 + 83
    yRep := ySec2 + 111

    Gui, Add, Radio, x30 y%yT1% w360 vCenterTimingNow gOnLockCenterTimingChange Group Checked%chkTimeNow%, % "⚡ " . L("LC_TimingNow")
    Gui, Add, Radio, x30 y%yT2% w155 vCenterTimingTimer gOnLockCenterTimingChange Checked%chkTimeSet%, % "⏱️ " . L("LC_TimingTimer")
    Gui, Add, Edit, x190 y%yT2% w68 h24 Number vCenterMinutesInput gOnLockCenterMinEdit
    Gui, Add, UpDown, vCenterMinutesUpDown Range1-1440, %dispMinutes%
    Gui, Add, Text, x264 y%yT2% w60 h24 +0x200 vCenterMinUnitTxt, % L("LC_UnitMin")

    Gui, Font, s8.5 Norm, Segoe UI
    Gui, Add, Button, x190 y%yPre% w45 h22 gOnLockCenterPreset5 vCenterPreset5, 5p
    Gui, Add, Button, x240 y%yPre% w45 h22 gOnLockCenterPreset15 vCenterPreset15, 15p
    Gui, Add, Button, x290 y%yPre% w45 h22 gOnLockCenterPreset30 vCenterPreset30, 30p
    Gui, Add, Button, x340 y%yPre% w45 h22 gOnLockCenterPreset60 vCenterPreset60, 60p
    Gui, Font, s9.5 Norm c222222, Segoe UI

    Gui, Add, Checkbox, x30 y%yRep% w360 vCenterRepeatCheck Checked%dispRepeat%, % "🔁 " . L("LC_RepeatCheck")

    ; Nhóm 2b: Thông tin Focus Lock (hiển thị thay cho Thời gian khi chọn Focus Lock)
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x15 y%ySec2% w390 h136 vCenterFocusInfoGroup, % "  🎯 " . L("LC_GroupFocusInfo")
    Gui, Font, s9 Norm c444444, Segoe UI
    yFInfo := ySec2 + 28
    Gui, Add, Text, x30 y%yFInfo% w360 h94 vCenterFocusInfoTxt, % L("LC_FocusDesc")
    Gui, Font, s9.5 Norm c222222, Segoe UI

    yNext := ySec2 + 146

    ; Nhóm 3 (Tùy chọn): Yêu cầu mã mở khóa khi đang chạy hẹn giờ
    if (lockTimerActive && requireCodeForTimerEdit) {
        Gui, Font, s9.5 Bold c9C4A00, Segoe UI
        Gui, Add, GroupBox, x15 y%yNext% w390 h84 vCenterAuthGroup, % "  🔑 " . L("LC_AuthPrompt")
        Gui, Font, s9.5 Norm c222222, Segoe UI
        yAuthCtrl := yNext + 36
        Gui, Add, Edit, x30 y%yAuthCtrl% w240 h25 Password vCenterAuthInput
        Gui, Add, Button, x280 y%yAuthCtrl% w110 h26 gOnVerifyCenterAuth vCenterAuthBtn Default, % L("LC_AuthUnlockBtn")
        yBtn := yNext + 96
    } else {
        yBtn := yNext
    }

    ; Nút hành động chân trang
    if (lockTimerActive) {
        defOpt := centerEditUnlocked ? "Default" : ""
        Gui, Add, Button, x95 y%yBtn% w100 h32 gOnLockCenterApply vCenterBtnApply %defOpt%, % "✔ " . L("LC_BtnUpdate")
        Gui, Add, Button, x203 y%yBtn% w110 h32 gOnLockCenterCancelTimer vCenterBtnCancelTimer, % "⏹ " . L("LC_BtnCancelTimer")
        Gui, Add, Button, x321 y%yBtn% w84 h32 gLockCenterGuiClose vCenterBtnClose, % L("LC_BtnClose")
    } else {
        Gui, Add, Button, x195 y%yBtn% w115 h32 gOnLockCenterApply vCenterBtnApply Default, % "🔒 " . L("LC_BtnStart")
        Gui, Add, Button, x320 y%yBtn% w85 h32 gLockCenterGuiClose vCenterBtnClose, % L("LC_BtnCancel")
    }

    totalH := yBtn + 46
    UpdateLockCenterUIState()

    Gui, Show, w420 h%totalH% Center, % L("LC_Title")
    if (IsFunc("SetGuiYellowIcon"))
        SetGuiYellowIcon(hLockCenterGui)

    if (lockTimerActive && requireCodeForTimerEdit && !centerEditUnlocked)
        GuiControl, LockCenter:Focus, CenterAuthInput
}

GetShortFocusTargetTitle() {
    global hPendingFocusWnd, pendingFocusTitle
    if (!hPendingFocusWnd || !WinExist("ahk_id " . hPendingFocusWnd))
        return ""
    title := pendingFocusTitle
    if (title = "")
        WinGetTitle, title, ahk_id %hPendingFocusWnd%
    if (StrLen(title) > 40)
        return SubStr(title, 1, 40) . "..."
    return title
}

UpdateLockCenterUIState() {
    global lockTimerActive, centerEditUnlocked
    Gui, LockCenter:Submit, NoHide
    GuiControlGet, t0, LockCenter:, CenterType0
    GuiControlGet, t1, LockCenter:, CenterType1
    GuiControlGet, t2, LockCenter:, CenterType2
    GuiControlGet, isTimer, LockCenter:, CenterTimingTimer

    selType := t2 ? 2 : (t1 ? 1 : 0)
    isFocus := (selType == 2)
    canEdit := centerEditUnlocked ? 1 : 0

    ; Ẩn/Hiện nhóm Thời gian vs Thông tin Focus Lock
    visTimer := isFocus ? "Hide" : "Show"
    visFocus := isFocus ? "Show" : "Hide"

    GuiControl, LockCenter:%visTimer%, CenterTimerGroup
    GuiControl, LockCenter:%visTimer%, CenterTimingNow
    GuiControl, LockCenter:%visTimer%, CenterTimingTimer
    GuiControl, LockCenter:%visTimer%, CenterMinutesInput
    GuiControl, LockCenter:%visTimer%, CenterMinutesUpDown
    GuiControl, LockCenter:%visTimer%, CenterMinUnitTxt
    GuiControl, LockCenter:%visTimer%, CenterPreset5
    GuiControl, LockCenter:%visTimer%, CenterPreset15
    GuiControl, LockCenter:%visTimer%, CenterPreset30
    GuiControl, LockCenter:%visTimer%, CenterPreset60
    GuiControl, LockCenter:%visTimer%, CenterRepeatCheck

    GuiControl, LockCenter:%visFocus%, CenterFocusInfoGroup
    GuiControl, LockCenter:%visFocus%, CenterFocusInfoTxt

    ; Enable/Disable toàn bộ tùy chọn khi đang bảo vệ bằng mã
    enMode := canEdit ? "Enable" : "Disable"
    GuiControl, LockCenter:%enMode%, CenterType0
    GuiControl, LockCenter:%enMode%, CenterType1
    GuiControl, LockCenter:%enMode%, CenterType2
    GuiControl, LockCenter:%enMode%, CenterTimingNow
    GuiControl, LockCenter:%enMode%, CenterTimingTimer
    GuiControl, LockCenter:%enMode%, CenterPreset5
    GuiControl, LockCenter:%enMode%, CenterPreset15
    GuiControl, LockCenter:%enMode%, CenterPreset30
    GuiControl, LockCenter:%enMode%, CenterPreset60
    GuiControl, LockCenter:%enMode%, CenterBtnApply

    if (lockTimerActive)
        GuiControl, LockCenter:%enMode%, CenterBtnCancelTimer

    ; Ô nhập phút và checkbox lặp lại chỉ bật khi cho phép sửa AND đang chọn Hẹn giờ
    enMin := (canEdit && !isFocus && isTimer) ? "Enable" : "Disable"
    GuiControl, LockCenter:%enMin%, CenterMinutesInput
    GuiControl, LockCenter:%enMin%, CenterMinutesUpDown
    GuiControl, LockCenter:%enMin%, CenterRepeatCheck
}

OnLockCenterTypeChange:
    UpdateLockCenterUIState()
return

OnLockCenterTimingChange:
    UpdateLockCenterUIState()
return

OnLockCenterMinEdit:
return

OnLockCenterPreset5:
    SetLockCenterPreset(5)
return
OnLockCenterPreset15:
    SetLockCenterPreset(15)
return
OnLockCenterPreset30:
    SetLockCenterPreset(30)
return
OnLockCenterPreset60:
    SetLockCenterPreset(60)
return

SetLockCenterPreset(mins) {
    GuiControl, LockCenter:, CenterTimingTimer, 1
    GuiControl, LockCenter:, CenterMinutesInput, %mins%
    UpdateLockCenterUIState()
}

OnVerifyCenterAuth:
    Gui, LockCenter:Submit, NoHide
    if (CenterAuthInput == UNLOCK_KEYWORD) {
        centerEditUnlocked := 1
        GuiControl, LockCenter:Disable, CenterAuthInput
        GuiControl, LockCenter:Disable, CenterAuthBtn
        GuiControl, LockCenter:, CenterAuthInput,
        GuiControl, LockCenter:-Default, CenterAuthBtn
        GuiControl, LockCenter:+Default, CenterBtnApply
        UpdateLockCenterUIState()
        GuiControl, LockCenter:Focus, CenterBtnApply
    } else {
        MsgBox, 48, % L("LC_Title"), % L("LC_AuthWrong")
        GuiControl, LockCenter:, CenterAuthInput,
        GuiControl, LockCenter:Focus, CenterAuthInput
    }
return

OnLockCenterApply:
    if (lockTimerActive && !centerEditUnlocked)
        return

    Gui, LockCenter:Submit, NoHide
    selType := CenterType2 ? 2 : (CenterType1 ? 1 : 0)
    selTimer := CenterTimingTimer ? 1 : 0
    selMins := CenterMinutesInput + 0
    selRepeat := CenterRepeatCheck ? 1 : 0

    if (selType != 2 && selTimer && selMins <= 0) {
        MsgBox, 48, % L("Hot_ErrTitle"), % L("LC_ErrMinutes")
        GuiControl, LockCenter:Focus, CenterMinutesInput
        return
    }

    ; Lưu lựa chọn gần nhất
    centerLockType := selType
    centerUseTimer := (selType == 2) ? 0 : selTimer
    if (selMins > 0)
        centerTimerMinutes := selMins
    centerRepeat := (selType == 2 || !selTimer) ? 0 : selRepeat
    SaveLockCenterPreferences()

    Gui, LockCenter:Destroy
    hLockCenterGui := 0

    ; Thực thi kiểu khóa đã chọn
    if (selType == 2) {
        ; Focus Lock: khóa ngay lên cửa sổ mục tiêu đã bắt trước khi mở GUI
        CancelLockCountdown(false)
        TriggerFocusLockDirect(hPendingFocusWnd)
        return
    }

    if (!selTimer) {
        ; Khóa ngay lập tức (Full Lock hoặc Windows Screen Lock)
        CancelLockCountdown(false)
        if (selType == 1) {
            DllCall("user32.dll\LockWorkStation")
        } else {
            ActivateLock(0)
        }
        return
    }

    ; Hẹn giờ đếm ngược
    StartLockCountdown(selType, selMins, selRepeat)
return

OnLockCenterCancelTimer:
    if (lockTimerActive && !centerEditUnlocked)
        return
    CancelLockCountdown(true)
    Gui, LockCenter:Destroy
    hLockCenterGui := 0
return

LockCenterGuiClose:
LockCenterGuiEscape:
    Gui, LockCenter:Destroy
    hLockCenterGui := 0
return

; ========================================================
; BỘ ĐẾM NGƯỢC HẸN GIỜ & HIỂN THỊ PHÚT -> GIÂY (< 1 PHÚT)
; ========================================================
FormatCountdownUnit(remainingSec) {
    if (remainingSec < 0)
        remainingSec := 0
    if (remainingSec >= 60) {
        mins := Ceil(remainingSec / 60)
        return mins . " " . L("LC_UnitMin")
    }
    return remainingSec . " " . L("LC_UnitSec")
}

GetActiveTimerStatusText() {
    global lockTimerActive, lockTimerType, lockTimerTargetTick, lockTimerRepeat
    if (!lockTimerActive)
        return ""
    remSec := Ceil((lockTimerTargetTick - A_TickCount) / 1000)
    if (remSec < 0)
        remSec := 0
    timeStr := FormatCountdownUnit(remSec)
    modeName := (lockTimerType == 1) ? L("LC_ModeNameScreen") : L("LC_ModeNameFull")
    msg := StrReplace(StrReplace(L("LC_ActiveTimerBanner"), "{mode}", modeName), "{time}", timeStr)
    if (lockTimerRepeat)
        msg .= L("LC_RepeatSuffix")
    return msg
}

StartLockCountdown(type, minutes, repeat := 0) {
    global lockTimerActive, lockTimerType, lockTimerMinutes, lockTimerRepeat
    global lockTimerTargetTick, lockTimerLastDisplayed, hLockCountdownGui
    global pendingRepeatFullLock, pendingRepeatMinutes

    if (minutes <= 0)
        return

    SetTimer, UpdateLockCountdown, Off
    Gui, LockCountdown:Destroy
    hLockCountdownGui := 0

    pendingRepeatFullLock := 0
    pendingRepeatMinutes := 0
    regPath := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"
    RegWrite, REG_DWORD, %regPath%, PendingRepeatActive, 0

    lockTimerActive := 1
    lockTimerType := (type == 1) ? 1 : 0
    lockTimerMinutes := minutes + 0
    lockTimerRepeat := repeat ? 1 : 0
    lockTimerTargetTick := A_TickCount + (lockTimerMinutes * 60 * 1000)
    lockTimerLastDisplayed := ""

    CreateCountdownGui()
    Gosub, UpdateLockCountdown
    SetTimer, UpdateLockCountdown, 1000

    fnTip := "UpdateTrayTip"
    if (IsFunc(fnTip))
        %fnTip%()
}

CreateCountdownGui() {
    global hLockCountdownGui
    hTaskbar := 48
    if (WinExist("ahk_class Shell_TrayWnd"))
        WinGetPos,,,, hTaskbar, ahk_class Shell_TrayWnd

    Gui, LockCountdown:Destroy
    Gui, LockCountdown:New, +LastFound +AlwaysOnTop -Caption +ToolWindow +E0x20 +HwndhLockCountdownGui
    Gui, Margin, 14, 8
    Gui, Color, 1E293B
    Gui, Font, s10 Norm cF8FAFC, Segoe UI
    Gui, Add, Text, vLockCountdownText w290 Center, ...
    Gui, Show, Hide
    WinGetPos,,, gw, gh, ahk_id %hLockCountdownGui%
    if (!gw)
        gw := 318, gh := 36
    posX := A_ScreenWidth - gw - 16
    posY := A_ScreenHeight - gh - hTaskbar - 16
    Gui, Show, x%posX% y%posY% NoActivate
    WinSet, Transparent, 215, ahk_id %hLockCountdownGui%
    WinSet, Region, 0-0 w%gw% h%gh% R10-10, ahk_id %hLockCountdownGui%
}

UpdateLockCountdown:
    if (!lockTimerActive) {
        SetTimer, UpdateLockCountdown, Off
        return
    }

    remMs := lockTimerTargetTick - A_TickCount
    if (remMs <= 0) {
        SetTimer, UpdateLockCountdown, Off
        Gui, LockCountdown:Destroy
        hLockCountdownGui := 0

        ; Đóng hộp thoại Lock Center nếu đang mở để tránh kẹt focus
        if (hLockCenterGui && WinExist("ahk_id " . hLockCenterGui)) {
            Gui, LockCenter:Destroy
            hLockCenterGui := 0
        }

        execType := lockTimerType
        execMins := lockTimerMinutes
        execRepeat := lockTimerRepeat

        lockTimerActive := 0
        lockTimerLastDisplayed := ""

        if (execType == 1) {
            if (execRepeat) {
                regPath := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"
                RegWrite, REG_DWORD, %regPath%, PendingRepeatActive, 1
                RegWrite, REG_DWORD, %regPath%, PendingRepeatType, 1
                RegWrite, REG_DWORD, %regPath%, PendingRepeatMinutes, %execMins%
            }
            fnTip := "UpdateTrayTip"
            if (IsFunc(fnTip))
                %fnTip%()
            DllCall("user32.dll\LockWorkStation")
        } else {
            if (execRepeat) {
                pendingRepeatFullLock := 1
                pendingRepeatMinutes := execMins
                regPath := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"
                RegWrite, REG_DWORD, %regPath%, PendingRepeatActive, 1
                RegWrite, REG_DWORD, %regPath%, PendingRepeatType, 0
                RegWrite, REG_DWORD, %regPath%, PendingRepeatMinutes, %execMins%
            }
            ActivateLock(0)
        }
        return
    }

    remSec := Ceil(remMs / 1000)
    timeStr := FormatCountdownUnit(remSec)
    tpl := (lockTimerType == 1) ? L("LC_CountdownScreen") : L("LC_CountdownFull")
    msg := (lockTimerType == 1 ? "🖥️ " : "🔒 ") . StrReplace(tpl, "{time}", timeStr)
    if (lockTimerRepeat)
        msg .= " 🔁"

    if (msg != lockTimerLastDisplayed) {
        lockTimerLastDisplayed := msg
        if (hLockCountdownGui && WinExist("ahk_id " . hLockCountdownGui)) {
            Gui, LockCountdown:Default
            GuiControl,, LockCountdownText, %msg%
        }
        if (hLockCenterGui && WinExist("ahk_id " . hLockCenterGui)) {
            Gui, LockCenter:Default
            GuiControl,, CenterActiveBanner, % "⏱️ " . GetActiveTimerStatusText()
        }
    }
return

CancelLockCountdown(showNotice := false) {
    global lockTimerActive, lockTimerLastDisplayed, hLockCountdownGui
    global pendingRepeatFullLock, pendingRepeatMinutes

    SetTimer, UpdateLockCountdown, Off
    Gui, LockCountdown:Destroy
    hLockCountdownGui := 0
    lockTimerActive := 0
    lockTimerLastDisplayed := ""
    pendingRepeatFullLock := 0
    pendingRepeatMinutes := 0

    regPath := "HKEY_CURRENT_USER\Software\TRIAN\GestureMouse"
    RegWrite, REG_DWORD, %regPath%, PendingRepeatActive, 0
    RegWrite, REG_DWORD, %regPath%, PendingRepeatResumeNow, 0

    fnTip := "UpdateTrayTip"
    if (IsFunc(fnTip))
        %fnTip%()

    if (showNotice)
        ShowToastBanner("✔ " . L("LC_TimerCancelled"), 2000)
}

; ========================================================
; THÔNG BÁO TRỰC QUAN (TOAST)
; ========================================================
ShowToastBanner(msg, autoHideMs := 0) {
    hTaskbar := 60
    if (WinExist("ahk_class Shell_TrayWnd"))
        WinGetPos,,,, hTaskbar, ahk_class Shell_TrayWnd

    SetTimer, HideNotification, Off
    Gui, Notification:Destroy

    Gui, Notification:New, +AlwaysOnTop +ToolWindow -Caption +LastFound
    Gui, Margin, 16, 10
    Gui, Font, s9.5 Norm, Segoe UI
    Gui, Color, FFF9C4, 2B1E00
    Gui, Font, c2B1E00
    Gui, Add, Text, Center, %msg%
    Gui, Show, Hide
    WinGetPos,,, GuiWidth, GuiHeight

    posX := A_ScreenWidth - GuiWidth - 16
    posY := A_ScreenHeight - GuiHeight - hTaskbar - 16

    Gui, Show, x%posX% y%posY% NoActivate
    WinSet, Transparent, 240
    WinSet, Region, 0-0 w%GuiWidth% h%GuiHeight% R12-12

    if (autoHideMs > 0)
        SetTimer, HideNotification, % -autoHideMs
}

ShowNotification() {
    global isLocked, lockMode, focusWndTitle

    if (isLocked) {
        if (lockMode == 1 && focusWndTitle != "") {
            shortTitle := SubStr(focusWndTitle, 1, 35) . (StrLen(focusWndTitle) > 35 ? "..." : "")
            msg := "🎯 " . L("Lock_NotificationFocus") . shortTitle
        } else {
            msg := "🔒 " . L("Lock_NotificationFull")
        }
        msg .= "`n" . L("Lock_ToastHint")
        ShowToastBanner(msg, 0)
    } else {
        ShowToastBanner("✔ " . L("Lock_Unlocked"), 2500)
    }

    fnTip := "UpdateTrayTip"
    if (IsFunc(fnTip))
        %fnTip%()
}

HideNotification:
    Gui, Notification:Destroy
return

; ========================================================
; KÍCH HOẠT & MỞ KHÓA THIẾT BỊ (FULL LOCK / FOCUS LOCK)
; ========================================================
ActivateLock(mode := 0, targetHwnd := 0) {
    global isLocked, hKeyboardHook, hMouseHook, lockMode, hFocusWnd, focusWndTitle
    global lockKeyboardEnabled, mouseLockEnabled, disableAutoLockScreen, Buffer

    LoadLockSettings()

    lockMode := (mode == 1) ? 1 : 0
    isLocked := 1
    Buffer := ""

    if (lockMode == 1) {
        hFocusWnd := (targetHwnd && WinExist("ahk_id " . targetHwnd)) ? targetHwnd : WinExist("A")
        if (hFocusWnd) {
            WinActivate, ahk_id %hFocusWnd%
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

    if (!hMouseHook && (mouseLockEnabled || lockMode == 1)) {
        hMouseHook := DllCall("SetWindowsHookEx", "Int", 14
            , "Ptr", RegisterCallback("MouseProc", "Fast")
            , "Ptr", DllCall("GetModuleHandle", "Ptr", 0, "Ptr")
            , "UInt", 0, "Ptr")
    }

    if (disableAutoLockScreen)
        DllCall("SetThreadExecutionState", "UInt", 0x80000003)

    ShowNotification()
}

TriggerFocusLockDirect(targetHwnd := 0) {
    ActivateLock(1, targetHwnd)
}

ToggleLock(forceState := -1) {
    global isLocked, lockMode
    targetState := (forceState != -1) ? forceState : (!isLocked)
    if (!targetState)
        UnlockKeyboard()
    else
        ActivateLock(lockMode)
}

UnlockKeyboard(fromWindowsSession := false) {
    global isLocked, hKeyboardHook, hMouseHook, Buffer
    global pendingRepeatFullLock, pendingRepeatMinutes

    if (!isLocked)
        return

    isLocked := 0
    Buffer := ""

    DllCall("ClipCursor", "Ptr", 0)

    if (hKeyboardHook) {
        DllCall("UnhookWindowsHookEx", "Ptr", hKeyboardHook)
        hKeyboardHook := 0
    }
    if (hMouseHook) {
        DllCall("UnhookWindowsHookEx", "Ptr", hMouseHook)
        hMouseHook := 0
    }

    DllCall("SetThreadExecutionState", "UInt", 0x80000000)

    SendLevel, 1
    SendInput, {Ctrl Up}{Alt Up}
    SendLevel, 0

    ShowNotification()

    ; Nếu là mở khóa trực tiếp (bằng mã) từ chu kỳ lặp lại -> đếm tiếp chu kỳ mới
    if (!fromWindowsSession && pendingRepeatFullLock && pendingRepeatMinutes > 0) {
        mins := pendingRepeatMinutes
        pendingRepeatFullLock := 0
        pendingRepeatMinutes := 0
        StartLockCountdown(0, mins, 1)
    }

    fnTip := "UpdateTrayTip"
    if (IsFunc(fnTip))
        %fnTip%()
}

; ========================================================
; LOW-LEVEL KEYBOARD HOOK
; ========================================================
KeyboardProc(nCode, wParam, lParam) {
    global isLocked, Buffer, UNLOCK_KEYWORD, KEYWORD_LENGTH
    global lockMode, hFocusWnd, lockKeyboardEnabled, allowSpace, allowMedia, allowNav
    static ctrlState := 0
    static altState := 0
    Critical

    if (nCode < 0 || !isLocked) {
        ctrlState := 0
        altState := 0
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
    }

    vkCode   := NumGet(lParam+0, 0, "UInt")
    scanCode := NumGet(lParam+0, 4, "UInt")
    flags    := NumGet(lParam+0, 8, "UInt")
    isKeyDown := (wParam = 0x100 || wParam = 0x104)
    isAltDown := (flags & 0x20) != 0

    if (vkCode = 0x11 || vkCode = 0xA2 || vkCode = 0xA3)
        ctrlState := isKeyDown
    if (vkCode = 0x12 || vkCode = 0xA4 || vkCode = 0xA5)
        altState := isKeyDown

    isCtrl := ctrlState || ((DllCall("GetAsyncKeyState", "Int", 0x11) & 0x8000) != 0) || GetKeyState("Ctrl", "P")
    isAlt  := altState || isAltDown || ((DllCall("GetAsyncKeyState", "Int", 0x12) & 0x8000) != 0) || GetKeyState("Alt", "P")

    ; 1. ƯU TIÊN SỐ 1: Bấm Ctrl + Alt + L khi đang khóa -> LUÔN chuyển sang màn hình khóa Windows
    if (isKeyDown && vkCode = 0x4C && isCtrl && isAlt) {
        static lastHotkeyPress := 0
        if (A_TickCount - lastHotkeyPress > 700) {
            lastHotkeyPress := A_TickCount
            ctrlState := 0
            altState := 0
            Buffer := ""
            SetTimer, TriggerWindowsAuthPrompt, -1
        }
        return 1
    }

    ; 2. ƯU TIÊN SỐ 2: Bắt mã mở khóa (áp dụng cho cả Full Lock và Focus Lock)
    if (isKeyDown) {
        char := ""
        if (vkCode >= 0x30 && vkCode <= 0x39) {
            char := Chr(vkCode)
        } else if (vkCode >= 0x60 && vkCode <= 0x69) {
            char := Chr(vkCode - 0x30)
        } else if (vkCode >= 0x41 && vkCode <= 0x5A) {
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

    ; 3. Xử lý Focus Lock
    if (lockMode == 1 && hFocusWnd) {
        curActive := WinExist("A")
        if (vkCode = 0x5B || vkCode = 0x5C || (isAlt && (vkCode = 0x09 || vkCode = 0x1B)) || (vkCode = 0x1B && isCtrl)) {
            return 1
        }
        if (curActive == hFocusWnd) {
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
        } else {
            WinActivate, ahk_id %hFocusWnd%
            return 1
        }
    }

    ; 4. Kiểm tra Whitelist (Full Lock)
    if (isKeyDown) {
        if (allowSpace && vkCode = 0x20)
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
        if (allowMedia && (vkCode >= 0xAD && vkCode <= 0xB3))
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
        if (allowNav && (vkCode >= 0x25 && vkCode <= 0x28 || vkCode = 0x0D || vkCode = 0x1B))
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
    }

    if (!lockKeyboardEnabled)
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)

    return 1
}

TriggerDirectUnlock:
    UnlockKeyboard(false)
return

TriggerWindowsAuthPrompt:
    if (hKeyboardHook) {
        DllCall("UnhookWindowsHookEx", "Ptr", hKeyboardHook)
        hKeyboardHook := 0
    }
    if (hMouseHook) {
        DllCall("UnhookWindowsHookEx", "Ptr", hMouseHook)
        hMouseHook := 0
    }
    DllCall("ClipCursor", "Ptr", 0)
    DllCall("user32.dll\LockWorkStation")
return

; ========================================================
; LOW-LEVEL MOUSE HOOK
; ========================================================
MouseProc(nCode, wParam, lParam) {
    global isLocked, lockMode, hFocusWnd, mouseLockEnabled, lockMouseClick
    global lockMouseWheel, lockMouseMove, allowMouseMove, allowMouseWheel
    Critical

    if (nCode < 0 || !isLocked)
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)

    if (lockMode == 1 && hFocusWnd) {
        ptX := NumGet(lParam+0, 0, "Int")
        ptY := NumGet(lParam+0, 4, "Int")
        ptWnd := DllCall("WindowFromPoint", "Int64", (ptY << 32) | (ptX & 0xFFFFFFFF), "Ptr")
        rootWnd := DllCall("GetAncestor", "Ptr", ptWnd, "UInt", 2, "Ptr")

        if (ptWnd != hFocusWnd && rootWnd != hFocusWnd)
            return 1
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
    }

    if (!mouseLockEnabled)
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)

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

        default: ; Click chuột
            if (lockMouseClick || mouseLockEnabled)
                return 1
            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
    }
}

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
