; Settings.ahk - Quản lý Giao diện Cài đặt (Settings GUI) phong cách Windows 11 Fluent Cards
#NoEnv

#Include *i Language.ahk

global currentSettingsTab := 1
global isCodeRevealed     := 0
global hChangeCodeGui     := 0

; Tạo GUI cài đặt - Settings (Giao diện Fluent Cards hiện đại)
Settings:
    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) {
        WinActivate, ahk_id %hSettingsGui%
        return
    }

    if (IsFunc("LoadLockSettings"))
        LoadLockSettings()

    Gui, Settings:New, -MaximizeBox -MinimizeBox +HwndhSettingsGui, % "Gesture Mouse - " . L("Set_Title")
    SetGuiYellowIcon(hSettingsGui)
    Gui, Font, s9.5 Norm c222222, Segoe UI

    aboutIcon  := A_IsCompiled ? A_ScriptFullPath : (A_ScriptDir . "\image\unnamed.ico")
    iconManual := A_ScriptDir . "\image\scroll_manual.ico"
    iconAuto   := A_ScriptDir . "\image\scroll_auto.ico"
    iconPage   := A_ScriptDir . "\image\scroll_page.ico"
    iconVol    := A_ScriptDir . "\image\mouse_volume.ico"
    flagVnFile := A_IsCompiled ? A_ScriptFullPath : (A_ScriptDir . "\image\flag_vn.ico")
    flagEnFile := A_IsCompiled ? A_ScriptFullPath : (A_ScriptDir . "\image\flag_en.ico")

    ; Đọc trạng thái khởi động cùng Windows
    RegRead, AutoStart, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, GestureMouse
    AutoStart := (AutoStart != "") ? 1 : 0 

    ; Đọc phương pháp cuộn chuột
    RegRead, ScrollStyle, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, ScrollStyle
    if (ErrorLevel || ScrollStyle = "" || ScrollStyle < 1 || ScrollStyle > 2) {
        ScrollStyle := 1
        RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, ScrollStyle, %ScrollStyle%
    }
    chkS1 := (ScrollStyle = 1) ? 1 : 0
    chkS2 := (ScrollStyle = 2) ? 1 : 0

    ; Trạng thái các tùy chọn Khóa
    chkModeFull  := (lockMode == 0) ? 1 : 0
    chkModeFocus := (lockMode == 1) ? 1 : 0

    ; Đọc trạng thái giữ màn hình sáng khi khóa
    RegRead, valDisableSleep, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, DisableAutoLockScreen
    disableAutoLockScreen := (valDisableSleep != "") ? valDisableSleep : 1

    ; Danh sách phút tự động khóa khi rảnh rỗi (Idle)
    if (CurrentLang = "en") {
        idleMinutesList := "1 min|3 mins|5 mins|10 mins|15 mins|30 mins|60 mins"
        timerMinutesList := "15 mins|30 mins|45 mins|60 mins|120 mins"
    } else {
        idleMinutesList := "1 phút|3 phút|5 phút|10 phút|15 phút|30 phút|60 phút"
        timerMinutesList := "15 phút|30 phút|45 phút|60 phút|120 phút"
    }

    selIdleIdx := 3 ; Mặc định 5 phút
    if (autoLockIdleMinutes == 1)
        selIdleIdx := 1
    else if (autoLockIdleMinutes == 3)
        selIdleIdx := 2
    else if (autoLockIdleMinutes == 5)
        selIdleIdx := 3
    else if (autoLockIdleMinutes == 10)
        selIdleIdx := 4
    else if (autoLockIdleMinutes == 15)
        selIdleIdx := 5
    else if (autoLockIdleMinutes == 30)
        selIdleIdx := 6
    else if (autoLockIdleMinutes == 60)
        selIdleIdx := 7

    selTimerIdx := 1 ; Mặc định 15 phút
    if (scheduledLockMinutes == 15)
        selTimerIdx := 1
    else if (scheduledLockMinutes == 30)
        selTimerIdx := 2
    else if (scheduledLockMinutes == 45)
        selTimerIdx := 3
    else if (scheduledLockMinutes == 60)
        selTimerIdx := 4
    else if (scheduledLockMinutes == 120)
        selTimerIdx := 5

    ; Xác định đặc quyền hệ thống (Admin / UIAccess / Standard)
    hasPriv := A_IsAdmin ? "Admin" : (IsFunc("HasUIAccessOrAdmin") && HasUIAccessOrAdmin() ? "UIAccess" : "Standard")

    ; ========================================================
    ; SIDEBAR BÊN TRÁI (KHÔNG CÓ LỚP NỀN NGUYÊN KHỐI, RỘNG RÃI KHÔNG BỊ KHUẤT CHỮ)
    ; ========================================================
    ; Logo & Tiêu đề
    Gui, Add, Picture, x16 y14 w32 h32 Icon1, %aboutIcon%
    Gui, Font, s11 Bold c004499, Segoe UI
    Gui, Add, Text, x56 y12 w145 h20, Gesture Mouse
    Gui, Font, s8 Norm c777777, Segoe UI
    Gui, Add, Text, x56 y32 w145 h16, % L("Set_Title")

    ; Vách phân cách ngang trên sidebar
    Gui, Add, Text, x10 y52 w198 h1 0x10

    ; Danh sách 5 mục điều hướng sidebar (Rộng rãi 198px, chữ không bao giờ bị khuất)
    navY1 := 60
    navY2 := 102
    navY3 := 144
    navY4 := 186
    navY5 := 228

    ; Khối Progress làm background highlight và indicator bar bên trái cho tab đang chọn
    Gui, Add, Progress, x10 y%navY1% w198 h36 BackgroundE5F1FB cE5F1FB vNavBg1 -Theme Disabled, 100
    Gui, Add, Progress, x10 y68 w3 h20 Background0067C0 c0067C0 vNavInd1 -Theme Disabled, 100
    Gui, Add, Text, x18 y%navY1% w190 h36 +0x200 +BackgroundTrans gOnNav1 vNavTxt1, % "  ⚙️  " . L("Nav_General")

    Gui, Add, Progress, x10 y%navY2% w198 h36 BackgroundE5F1FB cE5F1FB vNavBg2 -Theme Disabled, 100
    Gui, Add, Progress, x10 y110 w3 h20 Background0067C0 c0067C0 vNavInd2 -Theme Disabled, 100
    Gui, Add, Text, x18 y%navY2% w190 h36 +0x200 +BackgroundTrans gOnNav2 vNavTxt2, % "  🖱️  " . L("Nav_ScrollAndGesture")

    Gui, Add, Progress, x10 y%navY3% w198 h36 BackgroundE5F1FB cE5F1FB vNavBg3 -Theme Disabled, 100
    Gui, Add, Progress, x10 y152 w3 h20 Background0067C0 c0067C0 vNavInd3 -Theme Disabled, 100
    Gui, Add, Text, x18 y%navY3% w190 h36 +0x200 +BackgroundTrans gOnNav3 vNavTxt3, % "  🔒  " . L("Nav_Lock")

    Gui, Add, Progress, x10 y%navY4% w198 h36 BackgroundE5F1FB cE5F1FB vNavBg4 -Theme Disabled, 100
    Gui, Add, Progress, x10 y194 w3 h20 Background0067C0 c0067C0 vNavInd4 -Theme Disabled, 100
    Gui, Add, Text, x18 y%navY4% w190 h36 +0x200 +BackgroundTrans gOnNav4 vNavTxt4, % "  ⌨️  " . L("Nav_Shortcuts")

    Gui, Add, Progress, x10 y%navY5% w198 h36 BackgroundE5F1FB cE5F1FB vNavBg5 -Theme Disabled, 100
    Gui, Add, Progress, x10 y236 w3 h20 Background0067C0 c0067C0 vNavInd5 -Theme Disabled, 100
    Gui, Add, Text, x18 y%navY5% w190 h36 +0x200 +BackgroundTrans gOnNav5 vNavTxt5, % "  ℹ️  " . L("Nav_About")

    ; Chân Sidebar: Thông tin phiên bản
    Gui, Font, s8 Norm c888888, Segoe UI
    Gui, Add, Text, x10 y480 w198 h18 Center, % "Gesture Mouse v" . (AppVersion ? AppVersion : "1.1.0")

    ; Vách phân cách dọc giữa Sidebar và Content Area
    Gui, Add, Text, x216 y10 w1 h495 0x11

    ; ========================================================
    ; VÙNG NỘI DUNG BÊN PHẢI (TAB2 ẨN HEADER ĐỂ ĐIỀU HƯỚNG MƯỢT MÀ)
    ; ========================================================
    Gui, Add, Tab2, x220 y-35 w565 h560 -Theme -Wrap vSettingsTabNav, TabGeneral|TabScrollGesture|TabLock|TabShortcuts|TabAbout

    ; --------------------------------------------------------
    ; TAB 1: CÀI ĐẶT CHUNG && HỆ THỐNG
    ; --------------------------------------------------------
    Gui, Tab, TabGeneral
    Gui, Font, s12.5 Bold c004499, Segoe UI
    Gui, Add, Text, x230 y12 w535, % L("Set_HeaderGeneral")
    Gui, Font, s8 Norm c666666, Segoe UI
    Gui, Add, Text, x230 y32 w535, % L("Set_SubGeneral")

    ; Card 1: Khởi động cùng Windows
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y50 w535 h54, % "       " . L("Set_GroupGeneral")
    Gui, Add, Picture, x241 y49 w16 h16 Icon22, %A_WinDir%\System32\shell32.dll
    Gui, Font, Normal
    Gui, Add, Checkbox, x248 y70 vAutoStart gSaveSettings Checked%AutoStart%, % L("Set_AutoStart")

    ; Card 2: Ngôn ngữ hiển thị
    Gui, Font, Bold
    Gui, Add, GroupBox, x228 y110 w535 h62, % "       " . L("Set_Language")
    Gui, Add, Picture, x241 y109 w16 h16 Icon24, %A_WinDir%\System32\ddores.dll
    Gui, Font, Normal
    chkVI := (CurrentLang = "vi") ? 1 : 0
    chkEN := (CurrentLang = "en") ? 1 : 0
    if (A_IsCompiled || FileExist(flagVnFile))
        Gui, Add, Picture, x253 y135 w16 h16, %flagVnFile%
    Gui, Add, Radio, x275 y134 vLangVI gOnLangRadio Group Checked%chkVI%, Tiếng Việt
    if (A_IsCompiled || FileExist(flagEnFile))
        Gui, Add, Picture, x398 y135 w16 h16, %flagEnFile%
    Gui, Add, Radio, x420 y134 vLangEN gOnLangRadio Checked%chkEN%, English

    ; Card 3: Đặc quyền hệ thống (UIPI & UIAccess)
    Gui, Font, Bold
    Gui, Add, GroupBox, x228 y178 w535 h144, % "       " . L("Set_Privilege")
    Gui, Add, Picture, x241 y177 w16 h16 Icon77, %A_WinDir%\System32\shell32.dll
    Gui, Font, Normal

    if (hasPriv = "Admin") {
        Gui, Font, s9.5 Bold c007A00, Segoe UI
        Gui, Add, Text, x253 y200 w485, % "✔ " . L("Set_PrivAdmin")
        Gui, Font, s8.5 Norm c555555, Segoe UI
        Gui, Add, Text, x253 y222 w485, % L("Set_PrivSubAdmin")
    } else if (hasPriv = "UIAccess") {
        Gui, Font, s9.5 Bold c0078D7, Segoe UI
        Gui, Add, Text, x253 y200 w485, % "✔ " . L("Set_PrivUIA")
        Gui, Font, s8.5 Norm c555555, Segoe UI
        Gui, Add, Text, x253 y222 w485, % L("Set_PrivSubUIA")
    } else {
        Gui, Font, s9.5 Bold cC0392B, Segoe UI
        Gui, Add, Text, x253 y198 w340, % "⚠ " . L("Set_PrivStandard")
        Gui, Font, s8.5 Norm c555555, Segoe UI
        Gui, Add, Text, x253 y218 w340, % L("Set_PrivSubStandard")
        Gui, Font, s8.5 Norm, Segoe UI
        Gui, Add, Button, x595 y200 w155 h28 gRunAsAdmin, % L("Set_RunAdminBtn")
    }

    sysHelpText := (CurrentLang = "en") ? "Windows User Interface Privilege Isolation (UIPI) blocks standard apps from sending input to elevated windows (e.g., Task Manager). Installing with UIAccess or running as Admin ensures full compatibility." : "Cơ chế bảo mật Windows (UIPI) ngăn ứng dụng quyền thường tương tác với các cửa sổ quản trị (Task Manager, Registry Editor). Cài đặt UIAccess hoặc khởi chạy quyền Administrator giúp GestureMouse hoạt động trơn tru trên mọi ứng dụng."
    Gui, Font, s8 Norm c666666, Segoe UI
    Gui, Add, Text, x253 y252 w490 h60, %sysHelpText%

    ; Card 4: Mẹo sử dụng nhanh
    Gui, Font, Bold
    Gui, Add, GroupBox, x228 y328 w535 h136, % "  " . ((CurrentLang = "en") ? "Quick Tips" : "Mẹo sử dụng nhanh")
    Gui, Font, s8.5 Norm c444444, Segoe UI
    quickTipText := (CurrentLang = "en") ? "• In File Explorer, gestures work when no files are selected. When files are selected, dragging moves files normally.`n`n• Double-click the system tray icon anytime to quickly open Settings.`n`n• Press Ctrl + Alt to instantly toggle gestures off while gaming." : "• Trong File Explorer, cử chỉ chuột hoạt động khi không chọn file nào. Khi chọn file, kéo chuột sẽ kéo thả file bình thường.`n`n• Nhấp đúp vào icon khay hệ thống để mở nhanh cửa sổ Cài đặt bất kỳ lúc nào.`n`n• Bấm Ctrl + Alt để bật hoặc tắt nhanh toàn bộ cử chỉ khi chơi game."
    Gui, Add, Text, x243 y352 w505 h104, %quickTipText%

    ; --------------------------------------------------------
    ; TAB 2: CUỘN && CỬ CHỈ CHUỘT
    ; --------------------------------------------------------
    Gui, Tab, TabScrollGesture
    Gui, Font, s12.5 Bold c004499, Segoe UI
    Gui, Add, Text, x230 y12 w535, % L("Set_HeaderScrollGesture")
    Gui, Font, s8 Norm c666666, Segoe UI
    Gui, Add, Text, x230 y32 w535, % L("Set_SubScrollGesture")

    ; Card 1: Phương pháp cuộn chuột
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y50 w535 h76, % "       " . L("Set_GroupScroll")
    if FileExist(iconManual)
        Gui, Add, Picture, x241 y49 w16 h16, %iconManual%
    Gui, Font, Normal
    Gui, Add, Radio, x248 y70 vScrollStyle1 gSaveSettings Group Checked%chkS1%, % L("Set_ScrollStyle1")
    Gui, Add, Radio, x248 y96 vScrollStyle2 gSaveSettings Checked%chkS2%, % L("Set_ScrollStyle2")

    ; Card 2: Cử chỉ chuột & Ngoại lệ
    Gui, Font, Bold
    Gui, Add, GroupBox, x228 y132 w535 h68, % "       " . L("Set_GroupGesture")
    Gui, Add, Picture, x241 y131 w16 h16 Icon24, %A_WinDir%\System32\shell32.dll
    Gui, Font, Normal
    Gui, Add, Checkbox, x248 y150 vGestureEnabled gOnToggleGestureCheckbox Checked%GestureScrollEnabled%, % L("Set_EnableGesture")
    Gui, Add, Button, x248 y171 w230 h24 gOpenExcludedAppsGui, % L("Set_ExcludedAppsBtn")

    ; Card 3: Minh họa cử chỉ chuột (Cột 1 rộng 145px, không bị rớt dòng)
    Gui, Font, Bold
    Gui, Add, GroupBox, x228 y206 w535 h258, % "  " . ((CurrentLang = "en") ? "Mouse Gestures & Navigation (Hold Right Mouse Button)" : "Minh họa cử chỉ chuột && Thao tác kéo (Giữ chuột phải)")
    Gui, Font, s8.5 Norm c333333, Segoe UI

    if FileExist(iconManual)
        Gui, Add, Picture, x244 y228 w18 h18, %iconManual%
    Gui, Add, Text, x268 y230 w145, % L("Set_ManualScroll")
    Gui, Add, Text, x418 y230 w335 c666666, % "→ " . L("Set_ManualScrollBtn")

    if FileExist(iconAuto)
        Gui, Add, Picture, x244 y254 w18 h18, %iconAuto%
    Gui, Add, Text, x268 y256 w145, % L("Set_AutoScroll")
    Gui, Add, Text, x418 y256 w335 c666666, % "→ " . L("Set_AutoScrollBtn")

    if FileExist(iconPage)
        Gui, Add, Picture, x244 y280 w18 h18, %iconPage%
    Gui, Add, Text, x268 y282 w145, % L("Set_PgScroll")
    Gui, Add, Text, x418 y282 w335 c666666, % "→ " . L("Set_PgScrollBtn")

    if FileExist(iconVol)
        Gui, Add, Picture, x244 y306 w18 h18, %iconVol%
    Gui, Add, Text, x268 y308 w145, % L("Set_MouseVolume")
    Gui, Add, Text, x418 y308 w335 c666666, % "→ " . L("Set_MouseVolumeBtn")

    Gui, Add, Text, x244 y334 w505 h1 0x10

    Gui, Font, Bold c004499, Segoe UI
    Gui, Add, Text, x244 y342 w505, % (CurrentLang = "en" ? "Web Browser && File Explorer Gestures:" : "Cử chỉ trình duyệt Web && File Explorer:")
    Gui, Font, s8.5 Norm c333333, Segoe UI

    Gui, Add, Text, x244 y368 w95, % L("Set_Back")
    Gui, Add, Button, x340 y365 w45 h22 Center, ←
    Gui, Add, Text, x435 y368 w95, % L("Set_Forward")
    Gui, Add, Button, x535 y365 w45 h22 Center, →

    Gui, Add, Text, x244 y398 w130, % L("Set_PrevTab")
    Gui, Add, Button, x375 y395 w45 h22 Center, ↑__
    Gui, Add, Text, x445 y398 w130, % L("Set_NextTab")
    Gui, Add, Button, x580 y395 w45 h22 Center, ↓¯¯

    Gui, Add, Text, x244 y428 w95, % L("Set_CloseTab")
    Gui, Add, Button, x340 y425 w45 h22 Center, __↑
    Gui, Add, Text, x435 y428 w95, % L("Set_Refresh")
    Gui, Add, Button, x535 y425 w45 h22 Center, ¯¯↓

    ; --------------------------------------------------------
    ; TAB 3: KHÓA BÀN PHÍM && CHUỘT (TỐI ƯU 2 CARD LỚN GỌN GÀNG)
    ; --------------------------------------------------------
    Gui, Tab, TabLock

    ; Header
    Gui, Add, Picture, x230 y12 w28 h28 Icon28, %A_WinDir%\System32\ddores.dll
    Gui, Font, s13 Bold c004499, Segoe UI
    Gui, Add, Text, x264 y10 w500, % (CurrentLang = "en" ? "Lock Keyboard && Mouse" : "Khóa bàn phím && chuột")
    Gui, Font, s8 Norm c666666, Segoe UI
    Gui, Add, Text, x264 y32 w500, % (CurrentLang = "en" ? "Customizable locking, idle/timer auto-lock, and instant unlocking." : "Tùy chỉnh khóa thiết bị, tự động khóa độc lập và mở khóa trực tiếp.")

    ; ========================================================
    ; CARD 1: THIẾT LẬP KHÓA (LOCKING SETUP)
    ; ========================================================
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y50 w535 h166, % "  " . L("Lock_Card1Title")
    Gui, Font, s9 Norm c222222, Segoe UI

    ; Hàng 1: Thiết bị khóa + Nút Ngoại lệ
    Gui, Add, Picture, x243 y72 w18 h18 Icon74, %A_WinDir%\System32\shell32.dll
    Gui, Add, Checkbox, x266 y72 w115 vlockKeyboardEnabled gSaveSettings Checked%lockKeyboardEnabled%, % L("Lock_TargetKB")

    Gui, Add, Picture, x390 y72 w18 h18 Icon28, %A_WinDir%\System32\ddores.dll
    Gui, Add, Checkbox, x413 y72 w105 vmouseLockEnabled gSaveSettings Checked%mouseLockEnabled%, % L("Lock_TargetMouse")

    Gui, Add, Button, x528 y67 w222 h27 gOpenWhitelistGui, % L("Lock_WhitelistBtn")

    Gui, Add, Text, x243 y101 w505 h1 0x10

    ; Hàng 2: Tự động khóa khi rảnh rỗi (Thiết lập sẵn mặc định)
    Gui, Add, Picture, x243 y112 w18 h18 Icon48, %A_WinDir%\System32\shell32.dll
    Gui, Add, Checkbox, x266 y112 w250 vautoLockIdleEnabled gOnToggleIdleCheck Checked%autoLockIdleEnabled%, % L("Lock_AutoIdleCheck")
    Gui, Add, DropDownList, x520 y109 w230 vautoLockIdleMinutesChoice gSaveSettings Choose%selIdleIdx%, %idleMinutesList%

    ; Hàng 3: Hẹn giờ khóa sau khoảng thời gian (Hoạt động độc lập)
    Gui, Add, Picture, x243 y146 w18 h18 Icon240, %A_WinDir%\System32\shell32.dll
    Gui, Add, Checkbox, x266 y146 w250 vscheduledLockEnabled gOnToggleTimerCheck Checked%scheduledLockEnabled%, % L("Lock_AutoTimerCheck")
    Gui, Add, DropDownList, x520 y143 w230 vscheduledLockMinutesChoice gSaveSettings Choose%selTimerIdx%, %timerMinutesList%

    ; Hàng 4: Giữ màn hình sáng khi khóa
    Gui, Add, Picture, x243 y180 w18 h18 Icon16, %A_WinDir%\System32\shell32.dll
    Gui, Add, Checkbox, x266 y179 w485 vdisableAutoLockScreen gSaveSettings Checked%disableAutoLockScreen%, % L("Lock_PreventSleep")

    ; ========================================================
    ; CARD 2: MỞ KHÓA && THAO TÁC KÍCH HOẠT (UNLOCKING & ACTIONS)
    ; ========================================================
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y224 w535 h238, % "  " . L("Lock_Card2Title")
    Gui, Font, s9 Norm c222222, Segoe UI

    ; Hàng 1: Mã mở khóa bảo mật (Mask Password + Xem/Ẩn + Đổi mã)
    Gui, Add, Picture, x243 y248 w18 h18 Icon28, %A_WinDir%\System32\ddores.dll
    Gui, Add, Text, x266 y250 w90, % L("Lock_KeyPrompt")
    Gui, Add, Edit, x360 y247 w115 h24 vUnlockCodeDisplay ReadOnly Password, %UNLOCK_KEYWORD%
    Gui, Add, Button, x480 y246 w36 h25 gToggleRevealCode vBtnToggleReveal Center, 👁️
    Gui, Add, Button, x522 y246 w110 h25 gOpenChangeCodeGui, % L("Lock_ChangeCodeBtn")

    ; Hàng 2: Xác thực tài khoản Windows
    Gui, Add, Picture, x243 y284 w18 h18 Icon77, %A_WinDir%\System32\shell32.dll
    Gui, Add, Checkbox, x266 y283 w480 vrequireWindowsPassword gSaveSettings Checked%requireWindowsPassword%, % L("Lock_ReqWinPass")
    Gui, Font, s8 Norm c666666, Segoe UI
    Gui, Add, Text, x286 y306 w460, % ("• " . L("Lock_MethodHint"))

    Gui, Add, Text, x243 y332 w505 h1 0x10

    ; Hàng 3: Các nút hành động kích hoạt (Focus Lock & Khóa toàn diện)
    Gui, Font, s9.5 Bold c004499, Segoe UI
    Gui, Add, Button, x243 y348 w245 h36 gActionFocusLockFromSettings, % L("Lock_FocusBtn")
    Gui, Add, Button, x500 y348 w250 h36 gActionLockKeyboard, % L("Lock_FullBtn")

    Gui, Font, s8 Norm c777777, Segoe UI
    lockActionTip := (CurrentLang = "en") ? "• Tip: You can unlock anytime by typing your secret code or pressing Ctrl+Alt+L." : "• Mẹo: Có thể mở khóa bất kỳ lúc nào bằng cách gõ mã bí mật hoặc bấm Ctrl+Alt+L."
    Gui, Add, Text, x243 y394 w505 Center, %lockActionTip%

    ; --------------------------------------------------------
    ; TAB 4: PHÍM TẮT && TIỆN ÍCH
    ; --------------------------------------------------------
    Gui, Tab, TabShortcuts
    Gui, Font, s12.5 Bold c004499, Segoe UI
    Gui, Add, Text, x230 y12 w535, % L("Set_HeaderShortcuts")
    Gui, Font, s8 Norm c666666, Segoe UI
    Gui, Add, Text, x230 y32 w535, % L("Set_SubShortcuts")

    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y50 w535 h414, % "  " . L("About_TabShortcuts")
    Gui, Font, s9 Norm c222222, Segoe UI

    Gui, Add, Picture, x246 y76 w20 h20 Icon1, %aboutIcon%
    Gui, Add, Text, x273 y78 w180, % (CurrentLang = "en" ? "Toggle Gestures && Scroll" : "Bật / Tắt Cử chỉ && Cuộn")
    Gui, Add, Button, x475 y74 w180 h26 Center gActionToggleGestures, Ctrl + Alt

    Gui, Add, Picture, x246 y112 w20 h20 Icon28, %A_WinDir%\System32\ddores.dll
    Gui, Add, Text, x273 y114 w180, % L("Set_LockKBAndMouse")
    Gui, Add, Button, x475 y110 w180 h26 Center gActionLockKeyboard, Ctrl + Alt + L

    Gui, Add, Picture, x246 y148 w20 h20 Icon48, %A_WinDir%\System32\shell32.dll
    Gui, Add, Text, x273 y150 w180, % L("Set_AutoLock")
    Gui, Add, Button, x475 y146 w180 h26 Center gActionAutoLock, Ctrl + Shift + L

    Gui, Add, Picture, x246 y184 w20 h20 Icon261, %A_WinDir%\System32\shell32.dll
    Gui, Add, Text, x273 y186 w180, % L("Set_PastePlain")
    Gui, Add, Button, x475 y182 w180 h26 Center gActionPastePlain, Ctrl + Shift + V

    Gui, Add, Picture, x246 y220 w20 h20 Icon3, %A_WinDir%\System32\SndVol.exe
    Gui, Add, Text, x273 y222 w180, % L("Set_Mute")
    Gui, Add, Button, x475 y218 w180 h26 Center gActionMute, Ctrl + Shift + M

    Gui, Add, Picture, x246 y256 w20 h20 Icon2, %A_WinDir%\System32\SndVol.exe
    Gui, Add, Text, x273 y258 w180, % L("Set_Volume")
    Gui, Add, Button, x475 y254 w85 h26 Center gActionVolUp, % (CurrentLang = "en" ? "Win + ↑" : "Win + Cuộn ↑")
    Gui, Add, Button, x570 y254 w85 h26 Center gActionVolDown, % (CurrentLang = "en" ? "Win + ↓" : "Win + Cuộn ↓")

    Gui, Add, Picture, x246 y292 w20 h20 Icon26, %A_WinDir%\System32\shell32.dll
    Gui, Add, Text, x273 y294 w180, % L("Set_Brightness")
    Gui, Add, Button, x475 y290 w85 h26 Center gActionBrightDown, % (CurrentLang = "en" ? "F9 (Darker)" : "F9 (Tối)")
    Gui, Add, Button, x570 y290 w85 h26 Center gActionBrightUp, % (CurrentLang = "en" ? "F10 (Brighter)" : "F10 (Sáng)")

    Gui, Font, s8 Norm c666666, Segoe UI
    Gui, Add, Text, x246 y340 w495, % (CurrentLang = "en" ? "Tip: You can click directly on any of the shortcut buttons above to trigger the action immediately." : "Mẹo: Bạn có thể nhấp trực tiếp vào bất kỳ nút phím tắt nào ở trên để kích hoạt hành động ngay lập tức.")

    ; --------------------------------------------------------
    ; TAB 5: GIỚI THIỆU && BẢN QUYỀN
    ; --------------------------------------------------------
    Gui, Tab, TabAbout
    Gui, Font, s12.5 Bold c004499, Segoe UI
    Gui, Add, Text, x230 y12 w535, % L("Set_HeaderAbout")
    Gui, Font, s8 Norm c666666, Segoe UI
    Gui, Add, Text, x230 y32 w535, % L("Set_SubAbout")

    ; Thông tin ứng dụng
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y50 w535 h160, Gesture Mouse
    Gui, Add, Picture, x246 y72 w40 h40 Icon1, %aboutIcon%

    Gui, Font, s13 Bold c004499, Segoe UI
    Gui, Add, Text, x296 y70 w305, Gesture Mouse
    Gui, Font, s8.5 Norm c333333, Segoe UI
    Gui, Add, Text, x296 y94 w305, % L("About_Headline")
    Gui, Font, s8 Norm c666666, Segoe UI
    Gui, Add, Text, x296 y114 w305, % L("About_Version") . "  •  " . L("About_Author")

    ; Nút Donate
    Gui, Font, s8.5 Norm, Segoe UI
    Gui, Add, Button, x615 y70 w135 h30 gOpenDonateLink, % "❤ " . L("About_Donate")

    ; Các nút kiểm tra cập nhật & GitHub
    Gui, Add, Button, x246 y165 w150 h28 gCheckForUpdates, % L("Tray_CheckUpdate")
    Gui, Add, Button, x408 y165 w150 h28 gOpenGitHubLink, % "GitHub Releases"

    ; Bản quyền & Liên hệ
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y218 w535 h246, % (CurrentLang = "en" ? "Credits & Contact" : "Tác giả && Liên hệ")
    Gui, Font, s8.5 Norm c333333, Segoe UI
    aboutDetailText := (CurrentLang = "en") ? "Gesture Mouse is an advanced mouse productivity tool built with AutoHotkey.`n`nDesigned to eliminate finger fatigue with inertial drag scrolling, intuitive navigation gestures, screen & device protection, and smart accessibility integrations.`n`nAuthor: TRIAN (nguyentrian87@gmail.com)`nLicense: MIT License`nProject: https://github.com/hoangtrian/GestureMouse" : "Gesture Mouse là công cụ nâng cao năng suất thao tác chuột được phát triển trên nền tảng AutoHotkey.`n`nĐược thiết kế để giải phóng ngón tay khỏi việc cuộn bánh xe chuột liên tục bằng cơ chế cuộn kéo quán tính, cử chỉ chuột thông minh, khóa bảo vệ thiết bị và tích hợp sâu vào hệ thống Windows.`n`nTác giả: TRIAN (nguyentrian87@gmail.com)`nBản quyền: Giấy phép nguồn mở MIT License`nDự án: https://github.com/hoangtrian/GestureMouse"
    Gui, Add, Text, x243 y242 w505 h210, %aboutDetailText%

    ; ========================================================
    ; CHÂN TRANG GỌN GÀNG: CHỈ NÚT ĐÓNG (LƯU TỰ ĐỘNG)
    ; ========================================================
    Gui, Tab
    Gui, Font, s9 Norm, Segoe UI
    Gui, Add, Button, x675 y472 w88 h30 gSettingsCloseBtn Default, % L("Set_Close")

    ; Khởi tạo trạng thái Enable/Disable của dropdown theo checkbox
    GuiControl, Enable%autoLockIdleEnabled%, autoLockIdleMinutesChoice
    GuiControl, Enable%scheduledLockEnabled%, scheduledLockMinutesChoice

    ; Khởi tạo hiển thị tab hiện tại với background sidebar được tô màu
    SwitchSettingsTab(currentSettingsTab ? currentSettingsTab : 1)

    ; Hiển thị giao diện kích thước nhỏ gọn mới (w780 h515)
    Gui, Show, w780 h515 Center, % "Gesture Mouse - " . L("Set_Title")
    SetGuiYellowIcon(hSettingsGui)
return

; ========================================================
; HÀM VÀ LABEL ĐIỀU HƯỚNG SIDEBAR (TÔ NỀN ACTIVE TAB)
; ========================================================
OnNav1:
    SwitchSettingsTab(1)
return
OnNav2:
    SwitchSettingsTab(2)
return
OnNav3:
    SwitchSettingsTab(3)
return
OnNav4:
    SwitchSettingsTab(4)
return
OnNav5:
    SwitchSettingsTab(5)
return

SwitchSettingsTab(tabNum) {
    global currentSettingsTab
    currentSettingsTab := tabNum
    GuiControl, Choose, SettingsTabNav, %tabNum%
    Loop 5 {
        if (A_Index == tabNum) {
            GuiControl, Show, NavBg%A_Index%
            GuiControl, Show, NavInd%A_Index%
            Gui, Font, s9.5 Bold c005FB8, Segoe UI
            GuiControl, Font, NavTxt%A_Index%
            GuiControl, +BackgroundTrans, NavTxt%A_Index%
            GuiControl, MoveDraw, NavTxt%A_Index%
        } else {
            GuiControl, Hide, NavBg%A_Index%
            GuiControl, Hide, NavInd%A_Index%
            Gui, Font, s9.5 Norm c444444, Segoe UI
            GuiControl, Font, NavTxt%A_Index%
            GuiControl, +BackgroundTrans, NavTxt%A_Index%
            GuiControl, MoveDraw, NavTxt%A_Index%
        }
    }
}

; ========================================================
; THAO TÁC XEM/ẨN MÃ MỞ KHÓA (REVEAL / HIDE CODE)
; ========================================================
ToggleRevealCode:
    isCodeRevealed := !isCodeRevealed
    if (isCodeRevealed) {
        GuiControl, -Password, UnlockCodeDisplay
        GuiControl,, BtnToggleReveal, 🔒
    } else {
        GuiControl, +Password, UnlockCodeDisplay
        GuiControl,, BtnToggleReveal, 👁️
    }
    GuiControl,, UnlockCodeDisplay, %UNLOCK_KEYWORD%
return

; ========================================================
; DIALOG ĐỔI MÃ MỞ KHÓA (POPUP CHUYÊN DỤNG XÁC THỰC 2 LẦN)
; ========================================================
OpenChangeCodeGui:
    if (hChangeCodeGui && WinExist("ahk_id " . hChangeCodeGui)) {
        WinActivate, ahk_id %hChangeCodeGui%
        return
    }

    Gui, Settings:-Disabled
    Gui, ChangeCodeGui:New, +Owner%hSettingsGui% +AlwaysOnTop -MaximizeBox -MinimizeBox +HwndhChangeCodeGui, % L("Lock_ChangeCodeTitle")
    SetGuiYellowIcon(hChangeCodeGui)
    Gui, Font, s9.5 Norm c222222, Segoe UI

    Gui, Add, GroupBox, x15 y12 w350 h125, % "  🔑 " . L("Lock_ChangeCodeTitle")
    Gui, Add, Text, x30 y40 w130, % L("Lock_NewCode")
    Gui, Add, Edit, x165 y37 w180 h24 Password vNewUnlockCodeInput
    Gui, Add, Text, x30 y78 w130, % L("Lock_ConfirmCode")
    Gui, Add, Edit, x165 y75 w180 h24 Password vConfirmUnlockCodeInput

    Gui, Font, s9.5 Norm, Segoe UI
    Gui, Add, Button, x145 y150 w105 h32 gSubmitChangeCode Default, % "✔ " . L("Set_Apply")
    Gui, Add, Button, x260 y150 w105 h32 gCloseChangeCodeGui, % L("Lock_PassCancel")

    Gui, Show, w380 h195 Center, % L("Lock_ChangeCodeTitle")
return

SubmitChangeCode:
    Gui, ChangeCodeGui:Submit, NoHide
    if (NewUnlockCodeInput = "") {
        MsgBox, 48, GestureMouse, % L("Lock_CodeEmpty")
        GuiControl, Focus, NewUnlockCodeInput
        return
    }
    if (NewUnlockCodeInput != ConfirmUnlockCodeInput) {
        MsgBox, 48, GestureMouse, % L("Lock_CodeMismatch")
        GuiControl,, ConfirmUnlockCodeInput,
        GuiControl, Focus, ConfirmUnlockCodeInput
        return
    }

    ; Cập nhật mã mở khóa thành công
    UNLOCK_KEYWORD := NewUnlockCodeInput
    KEYWORD_LENGTH := StrLen(UNLOCK_KEYWORD)
    RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, UnlockKeyword, %UNLOCK_KEYWORD%

    ; Cập nhật hiển thị trên GUI Settings
    GuiControl, Settings:, UnlockCodeDisplay, %UNLOCK_KEYWORD%

    MsgBox, 64, GestureMouse, % L("Lock_CodeSuccess"), 1.2
    Gosub, CloseChangeCodeGui
return

CloseChangeCodeGui:
ChangeCodeGuiClose:
ChangeCodeGuiEscape:
    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui))
        Gui, Settings:-Disabled
    if (hChangeCodeGui && WinExist("ahk_id " . hChangeCodeGui)) {
        Gui, ChangeCodeGui:Destroy
        hChangeCodeGui := 0
    }
    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui))
        WinActivate, ahk_id %hSettingsGui%
return

; ========================================================
; KÍCH HOẠT FOCUS LOCK TỪ NÚT BẤM TRÊN SETTINGS
; ========================================================
ActionFocusLockFromSettings:
    ; Tạm ẩn cửa sổ Settings để xác định cửa sổ làm việc mục tiêu
    Gui, Settings:Hide
    Sleep, 150
    ; Kích hoạt Focus Lock trên cửa sổ active kế tiếp
    if (IsFunc("TriggerFocusLockDirect")) {
        fnFocus := "TriggerFocusLockDirect"
        %fnFocus%(WinExist("A"))
    }
return

OnToggleIdleCheck:
    Gui, Settings:Submit, NoHide
    GuiControl, Enable%autoLockIdleEnabled%, autoLockIdleMinutesChoice
    Gosub, SaveSettings
return

OnToggleTimerCheck:
    Gui, Settings:Submit, NoHide
    GuiControl, Enable%scheduledLockEnabled%, scheduledLockMinutesChoice
    Gosub, SaveSettings
return

OnLangRadio:
    Gui, Settings:Submit, NoHide
    if (LangVI && CurrentLang != "vi") {
        SetLanguage("vi")
        Gosub, RefreshSettingsGui
    } else if (LangEN && CurrentLang != "en") {
        SetLanguage("en")
        Gosub, RefreshSettingsGui
    }
return

RefreshSettingsGui:
    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) {
        Gui, Settings:Destroy
        hSettingsGui := 0
        Gosub, Settings
    }
return

OnToggleGestureCheckbox:
    Gui, Settings:Submit, NoHide
    if (GestureEnabled != GestureScrollEnabled) {
        ToggleGestureScroll()
    }
return

OpenAboutFromSettings:
    Gosub, ShowAbout
return

; ========================================================
; TỰ ĐỘNG LƯU CÀI ĐẶT (AUTO-SAVE MỖI KHI THAY ĐỔI)
; ========================================================
SaveSettings:
Save:
    ; Lấy giá trị hiện tại từ GUI mà không đóng GUI
    Gui, Settings:Submit, NoHide
    
    ; Lưu cài đặt khởi động cùng Windows
    if (AutoStart) {
        RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, GestureMouse, %A_ScriptFullPath%
    } else {
        RegDelete, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, GestureMouse
    }

    ; Xác định và lưu ScrollStyle
    ScrollStyle := ScrollStyle1 ? 1 : 2 
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, ScrollStyle, %ScrollStyle%

    ; Lưu trạng thái thiết bị khóa
    lockKeyboardEnabled := lockKeyboardEnabled ? 1 : 0
    mouseLockEnabled    := mouseLockEnabled ? 1 : 0
    lockMouseClick      := mouseLockEnabled

    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, LockKeyboard, %lockKeyboardEnabled%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, mouseLockEnabled, %mouseLockEnabled%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, LockMouseClick, %lockMouseClick%

    ; Lưu Tự động khóa khi không dùng máy (Idle)
    autoLockIdleEnabled := autoLockIdleEnabled ? 1 : 0
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AutoLockIdleEnabled, %autoLockIdleEnabled%
    if (RegExMatch(autoLockIdleMinutesChoice, "(\d+)", mIdle))
        autoLockIdleMinutes := mIdle1
    else
        autoLockIdleMinutes := 5
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AutoLockIdleMinutes, %autoLockIdleMinutes%

    ; Lưu Hẹn giờ tự động khóa (Scheduled timer lock)
    scheduledLockEnabled := scheduledLockEnabled ? 1 : 0
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, ScheduledLockEnabled, %scheduledLockEnabled%
    if (RegExMatch(scheduledLockMinutesChoice, "(\d+)", mTimer))
        scheduledLockMinutes := mTimer1
    else
        scheduledLockMinutes := 0
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, ScheduledLockMinutes, %scheduledLockMinutes%

    if (scheduledLockEnabled && scheduledLockMinutes > 0)
        scheduledLockTargetTick := A_TickCount + (scheduledLockMinutes * 60 * 1000)
    else
        scheduledLockTargetTick := 0

    if (IsFunc("InitAutoLockTimer"))
        InitAutoLockTimer()

    ; Lưu tùy chọn xác thực Windows (không yêu cầu 2 lần)
    requireWindowsPassword := requireWindowsPassword ? 1 : 0
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, RequireWindowsPassword, %requireWindowsPassword%

    ; Lưu trạng thái giữ màn hình luôn sáng khi khóa
    disableAutoLockScreen := disableAutoLockScreen ? 1 : 0
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, DisableAutoLockScreen, %disableAutoLockScreen%

    ; Cập nhật tray tip
    fnTip := "UpdateTrayTip"
    if (IsFunc(fnTip))
        %fnTip%()
return

OpenGitHubLink:
    Run, https://github.com/hoangtrian/GestureMouse/releases
return

SettingsCloseBtn:
SettingsGuiClose:
SettingsGuiEscape:
    ; Tự động lưu tất cả thiết lập trước khi đóng
    Gosub, SaveSettings

    if (hChangeCodeGui && WinExist("ahk_id " . hChangeCodeGui)) {
        Gui, ChangeCodeGui:Destroy
        hChangeCodeGui := 0
    }
    if (hExcludedGui && WinExist("ahk_id " . hExcludedGui) && IsFunc("CloseExcludedGui")) {
        fnCloseEx := "CloseExcludedGui"
        %fnCloseEx%()
    }
    if (hWhitelistGui && WinExist("ahk_id " . hWhitelistGui)) {
        Gui, WhitelistGui:Destroy
        hWhitelistGui := 0
    }
    if (hLockOpt && WinExist("ahk_id " . hLockOpt)) {
        Gui, LockOptions:Destroy
        hLockOpt := 0
    }
    Gui, Settings:Destroy
    hSettingsGui := 0
return

; ========================================================
; DIALOG CẤU HÌNH NGOẠI LỆ (WHITELIST - CÓ THÊM CUỘN CHUỘT)
; ========================================================
OpenWhitelistGui:
    if (hWhitelistGui && WinExist("ahk_id " . hWhitelistGui)) {
        WinActivate, ahk_id %hWhitelistGui%
        return
    }

    Gui, Settings:-Disabled
    Gui, WhitelistGui:New, +Owner%hSettingsGui% +AlwaysOnTop -MaximizeBox -MinimizeBox +HwndhWhitelistGui, % L("Lock_WhitelistTitle")
    SetGuiYellowIcon(hWhitelistGui)
    Gui, Font, s9.5 Norm c222222, Segoe UI

    Gui, Add, GroupBox, x15 y12 w430 h215, % "  🛡️ " . L("Lock_AllowGroup")
    Gui, Add, Checkbox, x30 y38 w400 vwl_allowMouseMove Checked%allowMouseMove%, % L("Lock_AllowMouseMove")
    Gui, Add, Checkbox, x30 y70 w400 vwl_allowMouseWheel Checked%allowMouseWheel%, % L("Lock_AllowMouseWheel")
    Gui, Add, Checkbox, x30 y102 w400 vwl_allowSpace Checked%allowSpace%, % L("Lock_AllowSpace")
    Gui, Add, Checkbox, x30 y134 w400 vwl_allowMedia Checked%allowMedia%, % L("Lock_AllowMedia")
    Gui, Add, Checkbox, x30 y166 w400 vwl_allowNav Checked%allowNav%, % L("Lock_AllowNav")

    Gui, Font, s8.5 Norm c777777, Segoe UI
    Gui, Add, Text, x15 y235 w430, % L("Lock_WhitelistTip")

    Gui, Font, s9.5 Norm, Segoe UI
    Gui, Add, Button, x225 y265 w110 h32 gApplyWhitelist Default, % "✔ " . L("Set_Apply")
    Gui, Add, Button, x345 y265 w100 h32 gCloseWhitelistGui, % L("Set_Close")

    Gui, Show, w460 h310 Center, % L("Lock_WhitelistTitle")
return

ApplyWhitelist:
    Gui, WhitelistGui:Submit, NoHide
    allowMouseMove  := wl_allowMouseMove ? 1 : 0
    allowMouseWheel := wl_allowMouseWheel ? 1 : 0
    allowSpace      := wl_allowSpace ? 1 : 0
    allowMedia      := wl_allowMedia ? 1 : 0
    allowNav        := wl_allowNav ? 1 : 0

    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AllowMouseMove, %allowMouseMove%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AllowMouseWheel, %allowMouseWheel%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AllowSpace, %allowSpace%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AllowMedia, %allowMedia%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AllowNav, %allowNav%

    Gosub, CloseWhitelistGui
return

CloseWhitelistGui:
WhitelistGuiClose:
WhitelistGuiEscape:
    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui))
        Gui, Settings:-Disabled
    if (hWhitelistGui && WinExist("ahk_id " . hWhitelistGui)) {
        Gui, WhitelistGui:Destroy
        hWhitelistGui := 0
    }
    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui))
        WinActivate, ahk_id %hSettingsGui%
return
