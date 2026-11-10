; Settings.ahk - Quản lý Giao diện Cài đặt (Settings GUI) phong cách Windows Settings
#NoEnv

#Include *i Language.ahk

; Tạo GUI cài đặt - Settings (Giao diện Sidebar dọc phong cách Windows Settings)
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

    aboutIcon := A_IsCompiled ? A_ScriptFullPath : (A_ScriptDir . "\image\unnamed.ico")
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

    ; Danh sách lựa chọn thời gian tự động khóa khi rảnh rỗi (Idle)
    autoLockIdleOptions := "0 (" . L("Lock_AutoOff") . ")|1 " . L("Lock_AutoMin") . "|3 " . L("Lock_AutoMin") . "|5 " . L("Lock_AutoMin") . "|10 " . L("Lock_AutoMin") . "|15 " . L("Lock_AutoMin") . "|30 " . L("Lock_AutoMin") . "|60 " . L("Lock_AutoMin")

    ; Danh sách lựa chọn hẹn giờ tự động khóa (Scheduled Timer)
    scheduledLockOptions := "0 (" . L("Lock_AutoOff") . ")|15 " . L("Lock_AutoMin") . "|30 " . L("Lock_AutoMin") . "|45 " . L("Lock_AutoMin") . "|60 " . L("Lock_AutoMin") . "|90 " . L("Lock_AutoMin") . "|120 " . L("Lock_AutoMin")

    ; Xác định đặc quyền hệ thống (Admin / UIAccess / Standard)
    hasPriv := A_IsAdmin ? "Admin" : (IsFunc("HasUIAccessOrAdmin") && HasUIAccessOrAdmin() ? "UIAccess" : "Standard")

    ; ========================================================
    ; SIDEBAR BÊN TRÁI (WINDOWS SETTINGS STYLE)
    ; ========================================================
    Gui, Add, Picture, x20 y18 w32 h32 Icon1, %aboutIcon%
    Gui, Font, s11.5 Bold c004499, Segoe UI
    Gui, Add, Text, x60 y15 w145 h22, Gesture Mouse
    Gui, Font, s8.5 Norm c777777, Segoe UI
    Gui, Add, Text, x60 y37 w145 h18, % L("Set_Title")

    ; Vách phân cách ngang trên sidebar
    Gui, Add, Text, x15 y60 w195 h1 0x10

    ; Danh sách các nút điều hướng sidebar (5 Tab)
    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Button, x15 y72 w195 h40 Left gOnNavGeneral vNavBtn1, % "  ⚙️  " . L("Nav_General")
    Gui, Add, Button, x15 y118 w195 h40 Left gOnNavScrollGesture vNavBtn2, % "  🖱️  " . L("Nav_ScrollAndGesture")
    Gui, Add, Button, x15 y164 w195 h40 Left gOnNavLock vNavBtn3, % "  🔒  " . L("Nav_Lock")
    Gui, Add, Button, x15 y210 w195 h40 Left gOnNavShortcuts vNavBtn4, % "  ⌨️  " . L("Nav_Shortcuts")
    Gui, Add, Button, x15 y256 w195 h40 Left gOnNavAbout vNavBtn5, % "  ℹ️  " . L("Nav_About")

    ; Chân Sidebar: Thông tin phiên bản & trạng thái
    Gui, Font, s8.5 Norm c888888, Segoe UI
    Gui, Add, Text, x15 y595 w195 h20 Center, % "Gesture Mouse v" . (AppVersion ? AppVersion : "1.1.0")

    ; Vách phân cách dọc giữa Sidebar và Content Area
    Gui, Add, Text, x220 y15 w1 h610 0x11

    ; ========================================================
    ; VÙNG NỘI DUNG BÊN PHẢI (TAB2 ẨN HEADER ĐỂ ĐIỀU HƯỚNG MƯỢT MÀ)
    ; ========================================================
    Gui, Add, Tab2, x230 y-35 w640 h660 -Theme -Wrap vSettingsTabNav, TabGeneral|TabScrollGesture|TabLock|TabShortcuts|TabAbout

    ; --------------------------------------------------------
    ; TAB 1: CÀI ĐẶT CHUNG && HỆ THỐNG
    ; --------------------------------------------------------
    Gui, Tab, TabGeneral
    Gui, Font, s13 Bold c004499, Segoe UI
    Gui, Add, Text, x240 y18 w620, % L("Set_HeaderGeneral")
    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x240 y42 w620, % L("Set_SubGeneral")

    ; Khởi động cùng Windows
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x240 y68 w625 h65, % "       " . L("Set_GroupGeneral")
    Gui, Add, Picture, x253 y67 w16 h16 Icon22, %A_WinDir%\System32\shell32.dll
    Gui, Font, Normal
    Gui, Add, Checkbox, x260 y90 vAutoStart gSaveSettings Checked%AutoStart%, % L("Set_AutoStart")

    ; Ngôn ngữ hiển thị
    Gui, Font, Bold
    Gui, Add, GroupBox, x240 y142 w625 h75, % "       " . L("Set_Language")
    Gui, Add, Picture, x253 y141 w16 h16 Icon24, %A_WinDir%\System32\ddores.dll
    Gui, Font, Normal
    chkVI := (CurrentLang = "vi") ? 1 : 0
    chkEN := (CurrentLang = "en") ? 1 : 0
    if (A_IsCompiled || FileExist(flagVnFile))
        Gui, Add, Picture, x265 y172 w16 h16, %flagVnFile%
    Gui, Add, Radio, x287 y171 vLangVI gOnLangRadio Group Checked%chkVI%, Tiếng Việt
    if (A_IsCompiled || FileExist(flagEnFile))
        Gui, Add, Picture, x410 y172 w16 h16, %flagEnFile%
    Gui, Add, Radio, x432 y171 vLangEN gOnLangRadio Checked%chkEN%, English

    ; Đặc quyền hệ thống (UIPI & UIAccess)
    Gui, Font, Bold
    Gui, Add, GroupBox, x240 y228 w625 h160, % "       " . L("Set_Privilege")
    Gui, Add, Picture, x253 y227 w16 h16 Icon77, %A_WinDir%\System32\shell32.dll
    Gui, Font, Normal

    if (hasPriv = "Admin") {
        Gui, Font, s10 Bold c007A00, Segoe UI
        Gui, Add, Text, x265 y255 w580, % "✔ " . L("Set_PrivAdmin")
        Gui, Font, s9 Norm c555555, Segoe UI
        Gui, Add, Text, x265 y280 w580, % L("Set_PrivSubAdmin")
    } else if (hasPriv = "UIAccess") {
        Gui, Font, s10 Bold c0078D7, Segoe UI
        Gui, Add, Text, x265 y255 w580, % "✔ " . L("Set_PrivUIA")
        Gui, Font, s9 Norm c555555, Segoe UI
        Gui, Add, Text, x265 y280 w580, % L("Set_PrivSubUIA")
    } else {
        Gui, Font, s10 Bold cC0392B, Segoe UI
        Gui, Add, Text, x265 y252 w400, % "⚠ " . L("Set_PrivStandard")
        Gui, Font, s9 Norm c555555, Segoe UI
        Gui, Add, Text, x265 y275 w400, % L("Set_PrivSubStandard")
        Gui, Font, s9 Norm, Segoe UI
        Gui, Add, Button, x480 y255 w160 h30 gRunAsAdmin, % L("Set_RunAdminBtn")
    }

    ; Mẹo hệ thống
    sysHelpText := (CurrentLang = "en") ? "Windows User Interface Privilege Isolation (UIPI) blocks standard apps from sending input to elevated windows (e.g., Task Manager, Registry Editor, Installers). Installing with UIAccess or running as Administrator ensures full compatibility across all applications." : "Cơ chế bảo mật Windows (UIPI) ngăn ứng dụng quyền thường gửi thao tác chuột/phím vào các cửa sổ quản trị (Task Manager, Registry Editor, phần mềm cài đặt). Khởi chạy quyền Administrator hoặc cài đặt UIAccess giúp GestureMouse hoạt động trơn tru trên mọi cửa sổ."
    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x265 y315 w580 h65, %sysHelpText%

    ; Mẹo sử dụng nhanh
    Gui, Font, Bold
    Gui, Add, GroupBox, x240 y398 w625 h165, % "  " . ((CurrentLang = "en") ? "Quick Tips" : "Mẹo sử dụng nhanh")
    Gui, Font, s9 Norm c444444, Segoe UI
    quickTipText := (CurrentLang = "en") ? "• In File Explorer, gestures work when no files are selected. When files are selected, dragging moves files normally.`n`n• Double-click the system tray icon anytime to quickly open Settings.`n`n• Press Ctrl + Alt to instantly toggle gestures off while gaming." : "• Trong File Explorer, cử chỉ chuột hoạt động khi không chọn file nào. Khi đang chọn file, thao tác kéo chuột sẽ kéo thả file bình thường.`n`n• Nhấp đúp chuột trái vào icon khay hệ thống để mở nhanh cửa sổ Cài đặt bất kỳ lúc nào.`n`n• Bấm Ctrl + Alt để bật hoặc tắt nhanh toàn bộ cử chỉ khi chơi game."
    Gui, Add, Text, x260 y425 w585 h125, %quickTipText%

    ; --------------------------------------------------------
    ; TAB 2: CUỘN && CỬ CHỈ CHUỘT
    ; --------------------------------------------------------
    Gui, Tab, TabScrollGesture
    Gui, Font, s13 Bold c004499, Segoe UI
    Gui, Add, Text, x240 y18 w620, % L("Set_HeaderScrollGesture")
    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x240 y42 w620, % L("Set_SubScrollGesture")

    ; Phương pháp cuộn chuột
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x240 y68 w625 h100, % "       " . L("Set_GroupScroll")
    if FileExist(iconManual)
        Gui, Add, Picture, x253 y67 w16 h16, %iconManual%
    Gui, Font, Normal
    Gui, Add, Radio, x260 y93 vScrollStyle1 gSaveSettings Group Checked%chkS1%, % L("Set_ScrollStyle1")
    Gui, Add, Radio, x260 y125 vScrollStyle2 gSaveSettings Checked%chkS2%, % L("Set_ScrollStyle2")

    ; Cử chỉ chuột & Ngoại lệ
    Gui, Font, Bold
    Gui, Add, GroupBox, x240 y178 w625 h80, % "       " . L("Set_GroupGesture")
    Gui, Add, Picture, x253 y177 w16 h16 Icon24, %A_WinDir%\System32\shell32.dll
    Gui, Font, Normal
    Gui, Add, Checkbox, x260 y200 vGestureEnabled gOnToggleGestureCheckbox Checked%GestureScrollEnabled%, % L("Set_EnableGesture")
    Gui, Add, Button, x260 y225 w260 h26 gOpenExcludedAppsGui, % L("Set_ExcludedAppsBtn")

    ; Minh họa cử chỉ chuột (Tích hợp từ About)
    Gui, Font, Bold
    Gui, Add, GroupBox, x240 y268 w625 h305, % "  " . ((CurrentLang = "en") ? "Mouse Gestures & Navigation (Hold Right Mouse Button)" : "Minh họa cử chỉ chuột && Thao tác kéo (Giữ chuột phải)")
    Gui, Font, s9 Norm c333333, Segoe UI

    if FileExist(iconManual)
        Gui, Add, Picture, x260 y295 w20 h20, %iconManual%
    Gui, Add, Text, x290 y297 w150, % L("Set_ManualScroll")
    Gui, Add, Text, x450 y297 w380 c666666, % "→ " . L("Set_ManualScrollBtn")

    if FileExist(iconAuto)
        Gui, Add, Picture, x260 y325 w20 h20, %iconAuto%
    Gui, Add, Text, x290 y327 w150, % L("Set_AutoScroll")
    Gui, Add, Text, x450 y327 w380 c666666, % "→ " . L("Set_AutoScrollBtn")

    if FileExist(iconPage)
        Gui, Add, Picture, x260 y355 w20 h20, %iconPage%
    Gui, Add, Text, x290 y357 w150, % L("Set_PgScroll")
    Gui, Add, Text, x450 y357 w380 c666666, % "→ " . L("Set_PgScrollBtn")

    if FileExist(iconVol)
        Gui, Add, Picture, x260 y385 w20 h20, %iconVol%
    Gui, Add, Text, x290 y387 w150, % L("Set_MouseVolume")
    Gui, Add, Text, x450 y387 w380 c666666, % "→ " . L("Set_MouseVolumeBtn")

    Gui, Add, Text, x260 y420 w580 h1 0x10

    Gui, Font, Bold c004499, Segoe UI
    Gui, Add, Text, x260 y430 w580, % (CurrentLang = "en" ? "Web Browser && File Explorer Gestures:" : "Cử chỉ trình duyệt Web && File Explorer:")
    Gui, Font, s9 Norm c333333, Segoe UI

    Gui, Add, Text, x260 y462 w125, % L("Set_Back")
    Gui, Add, Button, x390 y458 w50 h24 Center, ←
    Gui, Add, Text, x480 y462 w125, % L("Set_Forward")
    Gui, Add, Button, x610 y458 w50 h24 Center, →

    Gui, Add, Text, x260 y497 w125, % L("Set_PrevTab")
    Gui, Add, Button, x390 y493 w50 h24 Center, ↑__
    Gui, Add, Text, x480 y497 w125, % L("Set_NextTab")
    Gui, Add, Button, x610 y493 w50 h24 Center, ↓¯¯

    Gui, Add, Text, x260 y532 w125, % L("Set_CloseTab")
    Gui, Add, Button, x390 y528 w50 h24 Center, __↑
    Gui, Add, Text, x480 y532 w125, % L("Set_Refresh")
    Gui, Add, Button, x610 y528 w50 h24 Center, ¯¯↓

    ; --------------------------------------------------------
    ; TAB 3: KHÓA BÀN PHÍM && CHUỘT NÂNG CAO
    ; --------------------------------------------------------
    Gui, Tab, TabLock
    Gui, Font, s13 Bold c004499, Segoe UI
    Gui, Add, Text, x240 y18 w620, % L("Set_HeaderLock")
    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x240 y40 w620, % L("Set_SubLock")

    ; Nhóm Chế độ khóa
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x240 y65 w625 h76, % "       " . L("Lock_ModeGroup")
    Gui, Add, Picture, x253 y64 w16 h16 Icon28, %A_WinDir%\System32\ddores.dll
    Gui, Font, Normal
    Gui, Add, Radio, x260 y85 vlockModeFull gSaveSettings Group Checked%chkModeFull%, % L("Lock_ModeFull")
    Gui, Add, Radio, x260 y110 vlockModeFocus gSaveSettings Checked%chkModeFocus%, % L("Lock_ModeFocus")
    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x550 y112 w300, % "(" . L("Lock_ModeFocusHint") . ")"

    ; Khung Thiết bị khóa && Whitelist (Rộng rãi w625, chia 2 cột w290 không bao giờ bị tràn)
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x240 y148 w625 h155, % "  " . L("Lock_TargetGroup") . " && " . L("Lock_AllowGroup")
    
    ; Cột 1: Thiết bị khóa
    Gui, Font, Bold c004499, Segoe UI
    Gui, Add, Text, x260 y168 w270, % L("Lock_TargetGroup") . ":"
    Gui, Font, s9 Norm c222222, Segoe UI
    Gui, Add, Checkbox, x260 y190 vlockKeyboardEnabled gSaveSettings Checked%lockKeyboardEnabled%, % L("Lock_TargetKB")
    Gui, Add, Checkbox, x260 y212 vmouseLockEnabled gSaveSettings Checked%mouseLockEnabled%, % L("Lock_TargetMouseClick")
    Gui, Add, Checkbox, x260 y234 vlockMouseWheel gSaveSettings Checked%lockMouseWheel%, % L("Lock_TargetMouseWheel")
    Gui, Add, Checkbox, x260 y256 vlockMouseMove gSaveSettings Checked%lockMouseMove%, % L("Lock_TargetMouseMove")
    Gui, Add, Checkbox, x260 y278 vdisableAutoLockScreen gSaveSettings Checked%disableAutoLockScreen%, % L("Lock_PreventSleep")

    ; Cột 2: Whitelist (Cho phép gì)
    Gui, Font, Bold c004499, Segoe UI
    Gui, Add, Text, x560 y168 w280, % L("Lock_AllowGroup") . ":"
    Gui, Font, s9 Norm c222222, Segoe UI
    Gui, Add, Checkbox, x560 y190 vallowMouseMove gSaveSettings Checked%allowMouseMove%, % L("Lock_AllowMouseMove")
    Gui, Add, Checkbox, x560 y212 vallowSpace gSaveSettings Checked%allowSpace%, % L("Lock_AllowSpace")
    Gui, Add, Checkbox, x560 y234 vallowMedia gSaveSettings Checked%allowMedia%, % L("Lock_AllowMedia")
    Gui, Add, Checkbox, x560 y256 vallowNav gSaveSettings Checked%allowNav%, % L("Lock_AllowNav")

    ; Tự động khóa: 2 kiểu riêng biệt
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x240 y310 w625 h95, % "  " . L("Lock_AutoGroup")
    Gui, Font, s9 Norm c222222, Segoe UI

    ; Kiểu 1: Rảnh rỗi
    Gui, Add, Text, x260 y332 w270, % L("Lock_AutoIdleLabel")
    selIdleIdx := 1
    if (autoLockIdleMinutes == 1)
        selIdleIdx := 2
    else if (autoLockIdleMinutes == 3)
        selAutoIdx := 3
    else if (autoLockIdleMinutes == 5)
        selIdleIdx := 4
    else if (autoLockIdleMinutes == 10)
        selIdleIdx := 5
    else if (autoLockIdleMinutes == 15)
        selIdleIdx := 6
    else if (autoLockIdleMinutes == 30)
        selIdleIdx := 7
    else if (autoLockIdleMinutes == 60)
        selIdleIdx := 8
    Gui, Add, DropDownList, x260 y356 w260 vautoLockIdleChoice gSaveSettings Choose%selIdleIdx%, %autoLockIdleOptions%

    ; Kiểu 2: Hẹn giờ sau khoảng thời gian
    Gui, Add, Text, x560 y332 w280, % L("Lock_AutoTimerLabel")
    selSchedIdx := 1
    if (scheduledLockMinutes == 15)
        selSchedIdx := 2
    else if (scheduledLockMinutes == 30)
        selSchedIdx := 3
    else if (scheduledLockMinutes == 45)
        selSchedIdx := 4
    else if (scheduledLockMinutes == 60)
        selSchedIdx := 5
    else if (scheduledLockMinutes == 90)
        selSchedIdx := 6
    else if (scheduledLockMinutes == 120)
        selSchedIdx := 7
    Gui, Add, DropDownList, x560 y356 w260 vscheduledLockChoice gSaveSettings Choose%selSchedIdx%, %scheduledLockOptions%

    ; Bảo mật & Phương thức mở khóa
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x240 y413 w625 h95, % "  " . L("Lock_MethodGroup")
    Gui, Font, s9 Norm c222222, Segoe UI

    Gui, Add, Text, x260 y437 w260, % L("Lock_MethodDefault")
    Gui, Add, Edit, x525 y434 w130 h24 vUNLOCK_KEYWORD gSaveSettings, %UNLOCK_KEYWORD%

    Gui, Add, Checkbox, x260 y468 vrequireWindowsPassword gSaveSettings Checked%requireWindowsPassword%, % L("Lock_ReqWinPass")

    ; Nút Khóa ngay bây giờ
    Gui, Add, Button, x240 y522 w260 h34 gActionLockKeyboard, % "🔒 " . L("Lock_LockNow") . " (Ctrl+Alt+L)"

    ; --------------------------------------------------------
    ; TAB 4: PHÍM TẮT && TIỆN ÍCH
    ; --------------------------------------------------------
    Gui, Tab, TabShortcuts
    Gui, Font, s13 Bold c004499, Segoe UI
    Gui, Add, Text, x240 y18 w620, % L("Set_HeaderShortcuts")
    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x240 y42 w620, % L("Set_SubShortcuts")

    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x240 y68 w625 h500, % "  " . L("About_TabShortcuts")
    Gui, Font, s9.5 Norm c222222, Segoe UI

    Gui, Add, Picture, x260 y102 w22 h22 Icon1, %aboutIcon%
    Gui, Add, Text, x290 y104 w220, % (CurrentLang = "en" ? "Toggle Gestures && Scroll" : "Bật / Tắt Cử chỉ && Cuộn")
    Gui, Add, Button, x520 y100 w200 h28 Center gActionToggleGestures, Ctrl + Alt

    Gui, Add, Picture, x260 y142 w22 h22 Icon28, %A_WinDir%\System32\ddores.dll
    Gui, Add, Text, x290 y144 w220, % L("Set_LockKBAndMouse")
    Gui, Add, Button, x520 y140 w200 h28 Center gActionLockKeyboard, Ctrl + Alt + L

    Gui, Add, Picture, x260 y182 w22 h22 Icon48, %A_WinDir%\System32\shell32.dll
    Gui, Add, Text, x290 y184 w220, % L("Set_AutoLock")
    Gui, Add, Button, x520 y180 w200 h28 Center gActionAutoLock, Ctrl + Shift + L

    Gui, Add, Picture, x260 y222 w22 h22 Icon261, %A_WinDir%\System32\shell32.dll
    Gui, Add, Text, x290 y224 w220, % L("Set_PastePlain")
    Gui, Add, Button, x520 y220 w200 h28 Center gActionPastePlain, Ctrl + Shift + V

    Gui, Add, Picture, x260 y262 w22 h22 Icon3, %A_WinDir%\System32\SndVol.exe
    Gui, Add, Text, x290 y264 w220, % L("Set_Mute")
    Gui, Add, Button, x520 y260 w200 h28 Center gActionMute, Ctrl + Shift + M

    Gui, Add, Picture, x260 y302 w22 h22 Icon2, %A_WinDir%\System32\SndVol.exe
    Gui, Add, Text, x290 y304 w220, % L("Set_Volume")
    Gui, Add, Button, x520 y300 w95 h28 Center gActionVolUp, % (CurrentLang = "en" ? "Win + ↑" : "Win + Cuộn ↑")
    Gui, Add, Button, x625 y300 w95 h28 Center gActionVolDown, % (CurrentLang = "en" ? "Win + ↓" : "Win + Cuộn ↓")

    Gui, Add, Picture, x260 y342 w22 h22 Icon26, %A_WinDir%\System32\shell32.dll
    Gui, Add, Text, x290 y344 w220, % L("Set_Brightness")
    Gui, Add, Button, x520 y340 w95 h28 Center gActionBrightDown, % (CurrentLang = "en" ? "F9 (Darker)" : "F9 (Tối)")
    Gui, Add, Button, x625 y340 w95 h28 Center gActionBrightUp, % (CurrentLang = "en" ? "F10 (Brighter)" : "F10 (Sáng)")

    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x260 y400 w580, % (CurrentLang = "en" ? "Tip: You can click directly on any of the shortcut buttons above to trigger the action immediately." : "Mẹo: Bạn có thể nhấp trực tiếp vào bất kỳ nút phím tắt nào ở trên để kích hoạt hành động ngay lập tức.")

    ; --------------------------------------------------------
    ; TAB 5: GIỚI THIỆU && BẢN QUYỀN
    ; --------------------------------------------------------
    Gui, Tab, TabAbout
    Gui, Font, s13 Bold c004499, Segoe UI
    Gui, Add, Text, x240 y18 w620, % L("Set_HeaderAbout")
    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x240 y42 w620, % L("Set_SubAbout")

    ; Thông tin ứng dụng
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x240 y68 w625 h220, Gesture Mouse
    Gui, Add, Picture, x260 y95 w48 h48 Icon1, %aboutIcon%

    Gui, Font, s15 Bold c004499, Segoe UI
    Gui, Add, Text, x320 y95 w350, Gesture Mouse
    Gui, Font, s9.5 Norm c333333, Segoe UI
    Gui, Add, Text, x320 y123 w350, % L("About_Headline")
    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x320 y145 w350, % L("About_Version") . "  •  " . L("About_Author")

    ; Nút Donate
    Gui, Font, s9.5 Norm, Segoe UI
    Gui, Add, Button, x690 y95 w155 h32 gOpenDonateLink, % "❤ " . L("About_Donate")

    ; Các nút kiểm tra cập nhật & GitHub
    Gui, Add, Button, x260 y230 w180 h32 gCheckForUpdates, % L("Tray_CheckUpdate")
    Gui, Add, Button, x455 y230 w180 h32 gOpenGitHubLink, % "GitHub Releases"

    ; Bản quyền & Liên hệ
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x240 y300 w625 h268, % (CurrentLang = "en" ? "Credits & Contact" : "Tác giả && Liên hệ")
    Gui, Font, s9 Norm c333333, Segoe UI
    aboutDetailText := (CurrentLang = "en") ? "Gesture Mouse is an advanced mouse productivity tool built with AutoHotkey.`n`nDesigned to eliminate finger fatigue with inertial drag scrolling, intuitive navigation gestures, screen & device protection, and smart accessibility integrations.`n`nAuthor: TRIAN (nguyentrian87@gmail.com)`nLicense: MIT License`nProject: https://github.com/hoangtrian/GestureMouse" : "Gesture Mouse là công cụ nâng cao năng suất thao tác chuột được phát triển trên nền tảng AutoHotkey.`n`nĐược thiết kế để giải phóng ngón tay khỏi việc cuộn bánh xe chuột liên tục bằng cơ chế cuộn kéo quán tính, cử chỉ chuột thông minh, khóa bảo vệ thiết bị và tích hợp sâu vào hệ thống Windows.`n`nTác giả: TRIAN (nguyentrian87@gmail.com)`nBản quyền: Giấy phép nguồn mở MIT License`nDự án: https://github.com/hoangtrian/GestureMouse"
    Gui, Add, Text, x260 y330 w585 h210, %aboutDetailText%

    ; ========================================================
    ; NÚT ĐÓNG CHÂN TRANG
    ; ========================================================
    Gui, Tab
    Gui, Font, s9.5 Norm, Segoe UI
    Gui, Add, Button, x770 y590 w95 h32 gSettingsCloseBtn Default, % L("Set_Close")

    ; Hiển thị giao diện Windows Settings
    Gui, Show, w880 h640 Center, % "Gesture Mouse - " . L("Set_Title")
    SetGuiYellowIcon(hSettingsGui)
return

; ========================================================
; ĐIỀU HƯỚNG SIDEBAR
; ========================================================
OnNavGeneral:
    GuiControl, Choose, SettingsTabNav, 1
return
OnNavScrollGesture:
    GuiControl, Choose, SettingsTabNav, 2
return
OnNavLock:
    GuiControl, Choose, SettingsTabNav, 3
return
OnNavShortcuts:
    GuiControl, Choose, SettingsTabNav, 4
return
OnNavAbout:
    GuiControl, Choose, SettingsTabNav, 5
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

SaveSettings:
Save:
    ; Lấy giá trị hiện tại từ GUI mà không đóng GUI
    Gui, Submit, NoHide
    
    ; Lưu cài đặt khởi động cùng Windows
    if (AutoStart) {
        RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, GestureMouse, %A_ScriptFullPath%
    } else {
        RegDelete, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, GestureMouse
    }

    ; Xác định và lưu ScrollStyle
    ScrollStyle := ScrollStyle1 ? 1 : 2 
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, ScrollStyle, %ScrollStyle%

    ; Lưu trạng thái chế độ khóa (LockMode: 0 = Full, 1 = Focus)
    lockMode := lockModeFocus ? 1 : 0
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, LockMode, %lockMode%

    ; Lưu trạng thái thiết bị khóa
    lockMouseClick := mouseLockEnabled
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, LockKeyboard, %lockKeyboardEnabled%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, mouseLockEnabled, %mouseLockEnabled%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, LockMouseClick, %lockMouseClick%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, LockMouseWheel, %lockMouseWheel%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, LockMouseMove, %lockMouseMove%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, disableAutoLockScreen, %disableAutoLockScreen%

    ; Lưu trạng thái Whitelist (Cho phép gì)
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AllowMouseMove, %allowMouseMove%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AllowSpace, %allowSpace%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AllowMedia, %allowMedia%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AllowNav, %allowNav%

    ; Phân tích thời gian tự động khóa khi rảnh rỗi (Idle)
    autoLockIdleMinutes := 0
    if (RegExMatch(autoLockIdleChoice, "^\d+", m1))
        autoLockIdleMinutes := m1
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AutoLockIdleMinutes, %autoLockIdleMinutes%

    ; Phân tích hẹn giờ tự động khóa (Scheduled Timer)
    scheduledLockMinutes := 0
    if (RegExMatch(scheduledLockChoice, "^\d+", m2))
        scheduledLockMinutes := m2
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, ScheduledLockMinutes, %scheduledLockMinutes%

    if (scheduledLockMinutes > 0)
        scheduledLockTargetTick := A_TickCount + (scheduledLockMinutes * 60 * 1000)
    else
        scheduledLockTargetTick := 0

    if (IsFunc("InitAutoLockTimer"))
        InitAutoLockTimer()

    ; Lưu tùy chọn mở rộng xác thực Mật khẩu Windows
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, RequireWindowsPassword, %requireWindowsPassword%

    ; Lưu mã mở khóa cốt lõi (PIN / Từ khóa)
    if (UNLOCK_KEYWORD = "")
        UNLOCK_KEYWORD := "unlock"
    KEYWORD_LENGTH := StrLen(UNLOCK_KEYWORD)
    RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, UnlockKeyword, %UNLOCK_KEYWORD%

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
    if (hExcludedGui && WinExist("ahk_id " . hExcludedGui) && IsFunc("CloseExcludedGui")) {
        fnCloseEx := "CloseExcludedGui"
        %fnCloseEx%()
    }
    if (hLockOpt && WinExist("ahk_id " . hLockOpt)) {
        Gui, LockOptions:Destroy
        hLockOpt := 0
    }
    Gui, Settings:Destroy
    hSettingsGui := 0
return
