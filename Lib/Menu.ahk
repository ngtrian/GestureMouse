; Menu.ahk - Quản lý Menu Tray, Cài đặt và Giới thiệu
#NoEnv

Menu:
    global hSettingsGui := 0, hAboutGui := 0, hLockOpt := 0, hAutoLock := 0, hExcludedGui := 0, hRunningAppsGui := 0
    ; Khởi tạo ngôn ngữ và trạng thái cử chỉ
    InitLanguage()
    InitGestureScroll()
    InitExcludedApps()
    if (IsFunc("LoadLockSettings"))
        LoadLockSettings()
    if (IsFunc("InitAutoLockTimer"))
        InitAutoLockTimer()

    ; Xây dựng menu khay hệ thống ban đầu
    RebuildTrayMenu()

    ; Đăng ký sự kiện nhấp chuột trên icon khay (Click: Bật/Tắt ngay, Double-click: Mở Cài đặt)
    OnMessage(0x404, "AHK_NOTIFYICON")

    ; Cập nhật biểu tượng và tray tip lần đầu
    UpdateTrayIcon()
    UpdateTrayTip()  
    Gosub, BrightnessGui  ; Tạo GUI độ sáng

; Cập nhật tray tip tổng hợp
UpdateTrayTip() {
    global Brightness, GuiOn, isLocked, mouseLockEnabled, GestureScrollEnabled, lockMode, focusWndTitle
    TrayTip := L("Tip_Title")
    
    GestureTip := L("Tip_Gesture") . (GestureScrollEnabled ? L("Tip_On") : L("Tip_Off")) . "`n"
    if (isLocked) {
        if (lockMode == 1) {
            shortTitle := SubStr(focusWndTitle, 1, 20) . (StrLen(focusWndTitle) > 20 ? "..." : "")
            LockKeyboardTip := "Focus Lock: " . shortTitle . "`n"
        } else {
            LockKeyboardTip := L("Tip_LockKB") . L("Tip_On") . "`n"
        }
    } else {
        LockKeyboardTip := L("Tip_LockKB") . L("Tip_Off") . "`n"
    }
    LockMouseTip := L("Tip_LockMouse") . (mouseLockEnabled && isLocked ? L("Tip_On") : L("Tip_Off")) . "`n"

    TrayTip .= GestureTip
    TrayTip .= LockKeyboardTip
    TrayTip .= LockMouseTip

    ; Độ sáng
    BrightnessPercent := Round((255 - Brightness) / 255 * 100)
    TrayTip .= L("Tip_Brightness") . BrightnessPercent . "%" . (GuiOn ? L("Tip_GuiOn") : L("Tip_GuiOff"))
    Menu, Tray, Tip, %TrayTip%
}

; Xây dựng lại toàn bộ menu khay theo ngôn ngữ hiện tại
RebuildTrayMenu() {
    global GestureScrollEnabled, CurrentLang

    ; Xóa menu cũ
    try Menu, Tray, DeleteAll
    try Menu, PhimTat, DeleteAll
    try Menu, LangMenu, DeleteAll

    ; Sub-menu Phím tắt
    Menu, PhimTat, Add, % L("Sub_LockKB"), LockKeyboard
    Menu, PhimTat, Add, % L("Sub_AutoLock"), ShowLockScreenGUI
    Menu, PhimTat, Add, % L("Sub_PlainText"), PastePlainText
    Menu, PhimTat, Add, % L("Sub_Mute"), MuteFunc

    ; Sub-menu Ngôn ngữ / Language kèm icon lá cờ
    if (A_IsCompiled) {
        flagVnFile := A_ScriptFullPath, flagVnIcon := -312
        flagEnFile := A_ScriptFullPath, flagEnIcon := -313
    } else {
        flagVnFile := A_ScriptDir . "\image\flag_vn.ico", flagVnIcon := 1
        flagEnFile := A_ScriptDir . "\image\flag_en.ico", flagEnIcon := 1
    }

    Menu, LangMenu, Add, Tiếng Việt, SetLangVI
    if (A_IsCompiled || FileExist(flagVnFile))
        Menu, LangMenu, Icon, Tiếng Việt, %flagVnFile%, %flagVnIcon%

    Menu, LangMenu, Add, English, SetLangEN
    if (A_IsCompiled || FileExist(flagEnFile))
        Menu, LangMenu, Icon, English, %flagEnFile%, %flagEnIcon%

    ; Checkmark cho ngôn ngữ đang dùng
    if (CurrentLang = "en") {
        Menu, LangMenu, Check, English
        Menu, LangMenu, Uncheck, Tiếng Việt
    } else {
        Menu, LangMenu, Check, Tiếng Việt
        Menu, LangMenu, Uncheck, English
    }

    ; Menu Tray chính
    menuGestureText := GestureScrollEnabled ? L("Tray_Enabled") : L("Tray_Disabled")
    Menu, Tray, Add, %menuGestureText%, ToggleGestureScrollLabel
    Menu, Tray, Add  ; Dòng phân cách
    Menu, Tray, Add, % L("Tray_Settings"), Settings

    ; Mục Cài đặt vào hệ thống (chỉ hiển thị khi file .exe chưa nằm trong Program Files)
    isInstalledDir := (InStr(A_ScriptDir, "Program Files") > 0)
    if (!isInstalledDir && A_IsCompiled) {
        Menu, Tray, Add, % L("Tray_Install"), InstallToSystem
    }
    Menu, Tray, Add, % L("Tray_Shortcuts"), :PhimTat

    ; Menu chọn ngôn ngữ (gắn cờ của ngôn ngữ hiện tại)
    langMenuLabel := L("Tray_Language")
    Menu, Tray, Add, %langMenuLabel%, :LangMenu
    currentFlagFile := (CurrentLang = "en") ? flagEnFile : flagVnFile
    currentFlagIcon := (CurrentLang = "en") ? flagEnIcon : flagVnIcon
    if (A_IsCompiled || FileExist(currentFlagFile))
        Menu, Tray, Icon, %langMenuLabel%, %currentFlagFile%, %currentFlagIcon%

    Menu, Tray, Add  ; Dòng phân cách
    if (!A_IsCompiled) {
        if (!A_IsCompiled) {
        Menu, Tray, Add, % L("Tray_Reload"), ReloadApp
    }
    }
    Menu, Tray, Add, % L("Tray_CheckUpdate"), CheckForUpdates
    Menu, Tray, Add  ; Dòng phân cách
    Menu, Tray, Add, % L("Tray_About"), ShowAbout
    Menu, Tray, Add
    Menu, Tray, Add, % L("Tray_Exit"), ExitMenu

    ; Cấu hình System Tray
    Menu, Tray, NoStandard
    Menu, Tray, Default, 1&
    UpdateTrayMenu()
}

; Cập nhật trạng thái và tên menu trên Menu Tray
UpdateTrayMenu() {
    global GestureScrollEnabled, hSettingsGui
    try {
        menuGestureText := GestureScrollEnabled ? L("Tray_Enabled") : L("Tray_Disabled")
        Menu, Tray, Rename, 1&, %menuGestureText%
        if (GestureScrollEnabled) {
            Menu, Tray, Check, 1&
            try Menu, Tray, Enable, % L("Tray_Shortcuts")
        }
        else
        {
            Menu, Tray, Uncheck, 1&
            try Menu, Tray, Disable, % L("Tray_Shortcuts")
        }
        Menu, Tray, Default, 1&

        if (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) {
            GuiControl, Settings:, GestureEnabled, %GestureScrollEnabled%
        }
    }
}

; Xử lý sự kiện chuột trên icon khay:
; - Click 1 lần: Bật/Tắt ngay lập tức không cần chờ delay
; - Double-click: Mở ngay cửa sổ Cài đặt
AHK_NOTIFYICON(wParam, lParam) {
    if (lParam = 0x202) { ; WM_LBUTTONUP: Nhấp chuột trái -> Bật/Tắt ngay lập tức
        ToggleGestureScroll()
        return 0
    } else if (lParam = 0x203) { ; WM_LBUTTONDBLCLK: Nhấp đúp -> Hoàn lại trạng thái ban đầu và mở Cài đặt
        ToggleGestureScroll() ; Đảo trạng thái lần 2 để sau 2 lần nhấp vẫn giữ nguyên trạng thái ban đầu
        ToolTip ; Tắt thông báo tooltip bật/tắt
        Gosub, Settings
        return 0
    }
}

; khởi tạo ban đầu gồm menu, icon tray, script dừng ở đây và chờ sự kiện từ menu khay hệ thống, "return" ngăn không cho các label khác tự động chạy
return


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
        selIdleIdx := 3
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


CreateOption() {
    global mouseLockEnabled, disableAutoLockScreen, hSettingsGui, hLockOpt

    if (hLockOpt && WinExist("ahk_id " . hLockOpt)) {
        Gui, LockOptions:Show
        WinActivate, ahk_id %hLockOpt%
        return
    }

    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) {
        Gui, Settings:+Disabled
    }

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, mouseLockEnabled 
    if (val != "")
        mouseLockEnabled := val

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, disableAutoLockScreen
    if (val != "")
        disableAutoLockScreen := val

    ownerOpt := (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) ? "+Owner" . hSettingsGui : ""
    Gui, LockOptions:New, +LastFound %ownerOpt% +HwndhLockOpt, % L("Opt_Title")
    SetGuiYellowIcon(hLockOpt)
    Gui, Font, s10, Arial
    Gui, Add, Checkbox, Checked Disabled, % L("Opt_LockKB")
    Gui, Add, Checkbox, vmouseLockEnabled gSaveOption Checked%mouseLockEnabled%, % L("Opt_LockMouse")
    Gui, Add, Checkbox, vdisableAutoLockScreen gSaveOption Checked%disableAutoLockScreen% Disabled, % L("Opt_PreventAutoLock")
    Gui, LockOptions:Show, AutoSize Center, % L("Opt_Title")
    SetGuiYellowIcon(hLockOpt)
    return
}

SaveOption:
    ; Lưu trạng thái của các checkbox
    Gui, Submit, NoHide
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, mouseLockEnabled, %mouseLockEnabled%
return

; Chạy quyền Admin RunAsAdmin
RunAsAdmin:
    ; Kiểm tra xem script đã chạy với quyền Admin chưa
    if (A_IsAdmin) {
        MsgBox, 64, % L("Admin_Notice"), % L("Admin_Already")
        return
    }
    ; Nếu chưa, yêu cầu quyền Admin
    try 
    {
        if A_IsCompiled
            Run *RunAs "%A_ScriptFullPath%" /restart
        else
            Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
    }
return



LockOptionsGuiClose:
LockOptionsGuiEscape:
    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) {
        Gui, Settings:-Disabled
        WinActivate, ahk_id %hSettingsGui%
    }
    Gui, LockOptions:Destroy
    hLockOpt := 0
return

SetLangVI:
    SetLanguage("vi")
return

SetLangEN:
    SetLanguage("en")
return

InstallToSystem:
    InstallAppToSystem()
return

InstallAppToSystem() {
    if (!A_IsCompiled) {
        MsgBox, 64, GestureMouse, % "Tính năng này chỉ dành cho file .exe đã biên dịch!"
        return
    }

    ; Xác nhận từ người dùng
    MsgBox, 36, GestureMouse, % L("Install_Confirm")
    IfMsgBox, No
        return

    ; Nếu chưa có quyền Admin, yêu cầu chạy lại với tham số /install
    if (!A_IsAdmin) {
        try {
            Run *RunAs "%A_ScriptFullPath%" /install
        }
        return
    }

    PerformInstallation()
}

PerformInstallation() {
    destDir := "C:\Program Files\GestureMouse"
    destExe := destDir . "\GestureMouse.exe"

    ; 1. Nạp chứng chỉ từ chính file exe vào Local Machine Root của máy mới
    TrustEmbeddedCertificate(A_ScriptFullPath)

    ; 2. Tạo thư mục đích
    FileCreateDir, %destDir%

    ; 3. Tắt nhẹ tiến trình GestureMouse trong Program Files nếu đang chạy để tránh khóa file
    currentPid := DllCall("GetCurrentProcessId")
    RunWait, %ComSpec% /c powershell -NoProfile -Command "Get-Process -Name GestureMouse -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne %currentPid% } | Stop-Process -Force",, Hide
    Sleep, 400

    ; 4. Copy file vào Program Files
    FileCopy, %A_ScriptFullPath%, %destExe%, 1
    if (ErrorLevel) {
        MsgBox, 16, GestureMouse, % L("Install_Error") . "Không thể sao chép file vào " . destDir
        return
    }

    ; 5. Tạo Shortcut trong Start Menu (Shortcut ứng dụng và Shortcut gỡ cài đặt)
    startMenuDir := A_AppDataCommon . "\Microsoft\Windows\Start Menu\Programs\GestureMouse"
    FileCreateDir, %startMenuDir%
    FileCreateShortcut, %destExe%, %startMenuDir%\GestureMouse.lnk, %destDir%,, GestureMouse, %destExe%,, 1
    FileCreateShortcut, %destExe%, %startMenuDir%\Uninstall GestureMouse.lnk, %destDir%, /uninstall, "Uninstall GestureMouse", %A_WinDir%\System32\shell32.dll,, 32
    ; Tạo shortcut gỡ cài đặt ngay trong thư mục Program Files
    FileCreateShortcut, %destExe%, %destDir%\Uninstall GestureMouse.lnk, %destDir%, /uninstall, "Uninstall GestureMouse", %A_WinDir%\System32\shell32.dll,, 32
    ; Tạo shortcut gỡ cài đặt ngay trong thư mục Program Files
    FileCreateShortcut, %destExe%, %destDir%\Uninstall GestureMouse.lnk, %destDir%, /uninstall, "Uninstall GestureMouse", %A_WinDir%\System32\shell32.dll,, 32

    ; 6. Tự động thêm vào Startup (Khởi động cùng Windows)
    RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, GestureMouse, "%destExe%"

    ; 7. Khởi chạy bản đã cài đặt trong Program Files kèm cờ thông báo thành công
    Run, "%destExe%" /installed_notify

    ; 8. Thoát bản chạy tạm thời
    ExitApp
}

UninstallFromSystem:
    UninstallApp()
return

UninstallApp() {
    if (!A_IsCompiled) {
        MsgBox, 64, GestureMouse, % "Tính năng này chỉ dành cho file .exe đã cài đặt!"
        return
    }

    ; Xác nhận từ người dùng
    MsgBox, 36, GestureMouse, % L("Uninstall_Confirm")
    IfMsgBox, No
        return

    ; Nếu chưa có quyền Admin, yêu cầu nâng quyền và chuyển sang chế độ đã xác nhận
    if (!A_IsAdmin) {
        try {
            Run *RunAs "%A_ScriptFullPath%" /uninstall_confirmed
        }
        return
    }

    PerformUninstallation()
}

PerformUninstallationCLI(isConfirmed := false) {
    if (!isConfirmed) {
        MsgBox, 36, GestureMouse, % L("Uninstall_Confirm")
        IfMsgBox, No
            return
    }

    if (!A_IsAdmin) {
        try {
            Run *RunAs "%A_ScriptFullPath%" /uninstall_confirmed
        }
        return
    }

    PerformUninstallation()
}

PerformUninstallation() {
    destDir := "C:\Program Files\GestureMouse"
    startMenuDir := A_AppDataCommon . "\Microsoft\Windows\Start Menu\Programs\GestureMouse"

    ; 1. Tắt các tiến trình GestureMouse khác đang chạy
    currentPid := DllCall("GetCurrentProcessId")
    RunWait, %ComSpec% /c powershell -NoProfile -Command "Get-Process -Name GestureMouse -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne %currentPid% } | Stop-Process -Force",, Hide

    ; 2. Xóa khỏi danh sách khởi động cùng Windows
    try {
        RegDelete, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, GestureMouse
    }

    ; 3. Xóa thư mục và shortcut trong Start Menu
    FileRemoveDir, %startMenuDir%, 1

    ; 4. Thông báo cho người dùng đã gỡ cài đặt thành công
    MsgBox, 64, GestureMouse, % L("Uninstall_Success")

    ; 5. Dọn dẹp thư mục Program Files sau khi tiến trình thoát
    cmdCleanup := "cmd.exe /c timeout /t 2 /nobreak >nul & rmdir /s /q """ . destDir . """"
    Run, %cmdCleanup%,, Hide

    ExitApp
}

TrustEmbeddedCertificate(exePath) {
    hCertStore := 0, hMsg := 0
    if DllCall("Crypt32\CryptQueryObject"
        , "UInt", 1 ; CERT_QUERY_OBJECT_FILE
        , "WStr", exePath
        , "UInt", 0x3FFF ; CERT_QUERY_CONTENT_FLAG_ALL
        , "UInt", 0x0E ; CERT_QUERY_FORMAT_FLAG_ALL
        , "UInt", 0
        , "Ptr*", 0, "Ptr*", 0, "Ptr*", 0
        , "Ptr*", hCertStore, "Ptr*", hMsg, "Ptr*", 0) {

        hRootStore := DllCall("Crypt32\CertOpenStore"
            , "Ptr", 10 ; STORE_PROV_SYSTEM_W
            , "UInt", 0, "Ptr", 0
            , "UInt", 0x20000 ; SYSTEM_STORE_LOCAL_MACHINE
            , "WStr", "Root", "Ptr")

        if (hRootStore) {
            pCert := DllCall("Crypt32\CertEnumCertificatesInStore", "Ptr", hCertStore, "Ptr", 0, "Ptr")
            if (pCert) {
                DllCall("Crypt32\CertAddCertificateContextToStore", "Ptr", hRootStore, "Ptr", pCert, "UInt", 3, "Ptr", 0)
                DllCall("Crypt32\CertFreeCertificateContext", "Ptr", pCert)
            }
            DllCall("Crypt32\CertCloseStore", "Ptr", hRootStore, "UInt", 0)
        }
        if (hCertStore)
            DllCall("Crypt32\CertCloseStore", "Ptr", hCertStore, "UInt", 0)
        if (hMsg)
            DllCall("Crypt32\CryptMsgClose", "Ptr", hMsg)
    }
}

CheckForUpdates:
    CheckUpdates(false)
return

CheckUpdates(silentIfLatest := false) {
    global AppVersion, AppGitHubRepo
    repo := AppGitHubRepo ? AppGitHubRepo : "ngtrian/GestureMouse"
    currVer := AppVersion ? AppVersion : "1.1.0"
    url := "https://api.github.com/repos/" . repo . "/releases/latest"

    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", url, true)
        whr.SetRequestHeader("User-Agent", "GestureMouse-App")
        whr.Send()
        whr.WaitForResponse(5)
        response := whr.ResponseText

        if RegExMatch(response, "i)""tag_name""\s*:\s*""v?([^""]+)""", match) {
            latestVer := match1
            if (CompareVersions(latestVer, currVer) > 0) {
                msg := StrReplace(StrReplace(L("Update_Available"), "{new}", latestVer), "{curr}", currVer)
                MsgBox, 36, GestureMouse, %msg%
                IfMsgBox, Yes
                    Run, % "https://github.com/" . repo . "/releases/latest"
                return
            }
        }

        if (!silentIfLatest) {
            msg := StrReplace(L("Update_Latest"), "{ver}", currVer)
            MsgBox, 64, GestureMouse, %msg%
        }
    } catch {
        if (!silentIfLatest)
            MsgBox, 48, GestureMouse, % L("Update_Failed")
    }
}

CompareVersions(v1, v2) {
    StringSplit, a, v1, .
    StringSplit, b, v2, .
    maxParts := (a0 > b0) ? a0 : b0
    Loop, %maxParts% {
        p1 := (a%A_Index% != "") ? a%A_Index% + 0 : 0
        p2 := (b%A_Index% != "") ? b%A_Index% + 0 : 0
        if (p1 > p2)
            return 1
        if (p1 < p2)
            return -1
    }
    return 0
}

ExitMenu:
    ExitApp
return

ReloadApp:
    Reload
return


; Đặt icon màu vàng mặc định cho mọi cửa sổ GUI (Taskbar, Titlebar, Alt+Tab luôn là màu vàng)
; Đặt icon màu vàng mặc định cho mọi cửa sổ GUI (Taskbar, Titlebar, Alt+Tab luôn là màu vàng)
SetGuiYellowIcon(guiHwnd) {
    if (!guiHwnd)
        return
    static hBig := 0, hSmall := 0
    if (!hBig) {
        if (A_IsCompiled) {
            hMod := DllCall("GetModuleHandle", "Ptr", 0, "Ptr")
            hBig := DllCall("LoadImage", "Ptr", hMod, "UInt", 1, "UInt", 1, "Int", 32, "Int", 32, "UInt", 0, "Ptr")
            hSmall := DllCall("LoadImage", "Ptr", hMod, "UInt", 1, "UInt", 1, "Int", 16, "Int", 16, "UInt", 0, "Ptr")
        }
        if (!hBig) {
            iconPath := A_ScriptDir . "\image\unnamed.ico"
            if FileExist(iconPath) {
                hBig := DllCall("LoadImage", "Ptr", 0, "Str", iconPath, "UInt", 1, "Int", 32, "Int", 32, "UInt", 0x10, "Ptr")
                hSmall := DllCall("LoadImage", "Ptr", 0, "Str", iconPath, "UInt", 1, "Int", 16, "Int", 16, "UInt", 0x10, "Ptr")
            }
        }
    }
    fnSetClass := (A_PtrSize = 8) ? "SetClassLongPtr" : "SetClassLong"
    if (hSmall) {
        SendMessage, 0x80, 0, hSmall,, ahk_id %guiHwnd% ; ICON_SMALL
        DllCall(fnSetClass, "Ptr", guiHwnd, "Int", -34, "Ptr", hSmall, "Ptr") ; GCLP_HICONSM
    }
    if (hBig) {
        SendMessage, 0x80, 1, hBig,, ahk_id %guiHwnd%   ; ICON_BIG
        DllCall(fnSetClass, "Ptr", guiHwnd, "Int", -14, "Ptr", hBig, "Ptr")  ; GCLP_HICON
    }
}

; Giữ icon chính của ứng dụng và các cửa sổ GUI LUÔN là màu vàng
SetScriptYellowIcon() {
    global hSettingsGui, hAboutGui, hLockOpt, hAutoLock
    dhw := A_DetectHiddenWindows
    DetectHiddenWindows, On
    SetGuiYellowIcon(A_ScriptHwnd)
    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui))
        SetGuiYellowIcon(hSettingsGui)
    if (hAboutGui && WinExist("ahk_id " . hAboutGui))
        SetGuiYellowIcon(hAboutGui)
    if (hLockOpt && WinExist("ahk_id " . hLockOpt))
        SetGuiYellowIcon(hLockOpt)
    if (hAutoLock && WinExist("ahk_id " . hAutoLock))
        SetGuiYellowIcon(hAutoLock)
    if (hExcludedGui && WinExist("ahk_id " . hExcludedGui))
        SetGuiYellowIcon(hExcludedGui)
    if (hRunningAppsGui && WinExist("ahk_id " . hRunningAppsGui))
        SetGuiYellowIcon(hRunningAppsGui)
    DetectHiddenWindows, %dhw%
}
