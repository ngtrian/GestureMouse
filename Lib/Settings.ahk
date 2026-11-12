; Settings.ahk - Quản lý Giao diện Cài đặt (Settings GUI) phong cách Windows 11 Fluent Cards
#NoEnv

#Include *i Language.ahk

global currentSettingsTab   := 1
global isCodeRevealed       := 0
global hChangeCodeGui       := 0
global SettingsTooltips     := {}
global LastSettingsTipHwnd  := 0
global SidebarNavBitmaps    := {}
global SidebarIconHwnds     := {}
global LockTabIcons         := {}
global GestureBadgeBitmaps  := {}
global hBtnToggleReveal     := 0
global hAboutHeroBmp        := 0
global SettingsPreloadOnly  := false

; Dựng sẵn GUI Cài đặt ở trạng thái ẩn sau khi khởi động app để lần mở đầu tiên tức thì
PreloadSettingsGui:
    if (hSettingsGui) {
        DetectHiddenWindows, On
        guiExists := WinExist("ahk_id " . hSettingsGui)
        DetectHiddenWindows, Off
        if (guiExists)
            return
    }
    SettingsPreloadOnly := true
    Gosub, Settings
return

; Tạo GUI cài đặt - Settings (Giao diện Fluent Cards gọn gàng, Singleton pattern)
Settings:
    isPreload := SettingsPreloadOnly
    SettingsPreloadOnly := false

    if (hSettingsGui) {
        DetectHiddenWindows, On
        guiExists := WinExist("ahk_id " . hSettingsGui)
        DetectHiddenWindows, Off
        if (guiExists) {
            if (isPreload)
                return
            isVisible := DllCall("IsWindowVisible", "Ptr", hSettingsGui)
            UpdateSettingsGuiControls()
            targetTab := currentSettingsTab ? currentSettingsTab : 1
            if (!isVisible || targetTab != currentSettingsTab)
                SwitchSettingsTab(targetTab, !isVisible)
            Gui, Settings:Show, Center, % "GestureMouse - " . L("Set_Title")
            return
        }
    }

    prevBatchLines := A_BatchLines
    SetBatchLines, -1

    if (IsFunc("LoadLockSettings"))
        LoadLockSettings()

    isCodeRevealed := 0
    SettingsTooltips := {}
    LastSettingsTipHwnd := 0
    SidebarIconHwnds := {}
    EnsureSettingsVectorIcons()

    Gui, Settings:New, -MaximizeBox -MinimizeBox +HwndhSettingsGui, % "GestureMouse - " . L("Set_Title")
    DllCall("SendMessage", "Ptr", hSettingsGui, "UInt", 0x000B, "Ptr", 0, "Ptr", 0) ; WM_SETREDRAW = FALSE
    SetGuiYellowIcon(hSettingsGui)
    Gui, Font, s9.5 Norm c222222, Segoe UI

    aboutIcon := A_IsCompiled ? A_ScriptFullPath : (A_ScriptDir . "\image\unnamed.ico")

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

    ; Đọc trạng thái ngăn tắt màn hình & ngăn Sleep khi khóa (chỉ dùng cho Khóa phím/chuột & Focus Lock)
    RegRead, valLegacyDisableSleep, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, DisableAutoLockScreen
    RegRead, valScreenOff, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, PreventScreenOff
    preventScreenOff := (valScreenOff != "") ? (valScreenOff ? 1 : 0) : 0
    RegRead, valSleep, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, PreventSleep
    if (valSleep != "")
        preventSleep := valSleep ? 1 : 0
    else
        preventSleep := (valLegacyDisableSleep != "") ? (valLegacyDisableSleep ? 1 : 0) : 1

    ; Danh sách phút tự động khóa khi rảnh rỗi (Idle)
    if (CurrentLang = "en") {
        idleMinutesList := "1 min|3 mins|5 mins|10 mins|15 mins|30 mins|60 mins"
    } else {
        idleMinutesList := "1 phút|3 phút|5 phút|10 phút|15 phút|30 phút|60 phút"
    }
    selIdleIdx := GetIdleMinuteIndex(autoLockIdleMinutes)

    ; Xác định đặc quyền hệ thống (Admin / UIAccess / Standard)
    hasPriv := A_IsAdmin ? "Admin" : (IsFunc("HasUIAccessOrAdmin") && HasUIAccessOrAdmin() ? "UIAccess" : "Standard")

    ; ========================================================
    ; SIDEBAR ĐIỀU HƯỚNG BÊN TRÁI (GỌN SẠCH, KHÔNG LOGO/VERSION)
    ; ========================================================
    AddSidebarNav(1, 16,  "⚙️", L("Nav_General"))
    AddSidebarNav(2, 56,  "🖱️", L("Nav_ScrollAndGesture"))
    AddSidebarNav(3, 96,  "🔒", L("Nav_Lock"))
    AddSidebarNav(4, 136, "⌨️", L("Nav_Shortcuts"))
    AddSidebarNav(5, 176, "ℹ️", L("Nav_About"))

    ; Vách phân cách dọc duy nhất giữa Sidebar và Vùng nội dung
    Gui, Add, Text, x212 y12 w1 h428 0x11

    ; ========================================================
    ; VÙNG NỘI DUNG BÊN PHẢI (TAB2 +Buttons ẨN HOÀN TOÀN VIỀN KHUNG)
    ; ========================================================
    Gui, Add, Tab2, x216 y-35 w564 h439 +Buttons -Theme -Wrap vSettingsTabNav, TabGeneral|TabScrollGesture|TabLock|TabShortcuts|TabAbout

    ; --------------------------------------------------------
    ; TAB 1: CÀI ĐẶT CHUNG && HỆ THỐNG
    ; --------------------------------------------------------
    Gui, Tab, TabGeneral
    AddSettingsTabHeader("Set_HeaderGeneral", "Set_SubGeneral")

    ; Card 1: Cài đặt chung (Khởi động + Ngôn ngữ)
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y58 w536 h82, % L("Set_GroupGeneral")
    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Checkbox, x246 y80 w490 vAutoStart gSaveSettings Checked%AutoStart%, % L("Set_AutoStart")

    Gui, Add, Text, x246 y110 w145, % L("Set_Language")
    chkVI := (CurrentLang = "vi") ? 1 : 0
    chkEN := (CurrentLang = "en") ? 1 : 0
    AddSettingsIcon(398, 111, 16, 16, "image\flag_vn.ico", 312)
    Gui, Add, Radio, x420 y110 w105 vLangVI gOnLangRadio Group Checked%chkVI%, Tiếng Việt
    AddSettingsIcon(538, 111, 16, 16, "image\flag_en.ico", 313)
    Gui, Add, Radio, x560 y110 w90 vLangEN gOnLangRadio Checked%chkEN%, English

    ; Card 2: Đặc quyền hệ thống (UIPI & UIAccess)
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y150 w536 h122, % L("Set_Privilege")

    if (hasPriv = "Admin") {
        Gui, Font, s9.5 Bold c007A00, Segoe UI
        Gui, Add, Text, x246 y173 w500, % "✔ " . L("Set_PrivAdmin")
        Gui, Font, s8.5 Norm c555555, Segoe UI
        Gui, Add, Text, x246 y194 w500, % L("Set_PrivSubAdmin")
    } else if (hasPriv = "UIAccess") {
        Gui, Font, s9.5 Bold c0078D7, Segoe UI
        Gui, Add, Text, x246 y173 w500, % "✔ " . L("Set_PrivUIA")
        Gui, Font, s8.5 Norm c555555, Segoe UI
        Gui, Add, Text, x246 y194 w500, % L("Set_PrivSubUIA")
    } else {
        Gui, Font, s9.5 Bold cC0392B, Segoe UI
        Gui, Add, Text, x246 y173 w335, % "⚠ " . L("Set_PrivStandard")
        Gui, Font, s8.5 Norm c555555, Segoe UI
        Gui, Add, Text, x246 y194 w335, % L("Set_PrivSubStandard")
        Gui, Font, s9 Norm c222222, Segoe UI
        Gui, Add, Button, x590 y173 w156 h30 gRunAsAdmin, % L("Set_RunAdminBtn")
    }

    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x246 y218 w500 h46, % L("Set_PrivHelp")

    ; Card 3: Lưu ý nhanh
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y282 w536 h104, % L("Set_GroupTips")
    Gui, Font, s8.5 Norm c444444, Segoe UI
    Gui, Add, Text, x246 y304 w500 h72, % L("Set_QuickTips")

    ; --------------------------------------------------------
    ; TAB 2: CUỘN && CỬ CHỈ CHUỘT
    ; --------------------------------------------------------
    Gui, Tab, TabScrollGesture
    AddSettingsTabHeader("Set_HeaderScrollGesture", "Set_SubScrollGesture")

    ; Card 1: Bật/tắt, Ứng dụng loại trừ & Phương pháp cuộn
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y58 w536 h102, % L("Set_GroupGesture")
    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Checkbox, x246 y80 w300 vGestureEnabled gOnToggleGestureCheckbox Checked%GestureScrollEnabled%, % L("Set_EnableGesture")
    Gui, Font, s9 Norm c222222, Segoe UI
    Gui, Add, Button, x556 y76 w190 h26 gOpenExcludedAppsGui, % L("Set_ExcludedAppsBtn")

    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Radio, x246 y112 w500 vScrollStyle1 gSaveSettings Group Checked%chkS1%, % L("Set_ScrollStyle1")
    Gui, Add, Radio, x246 y134 w500 vScrollStyle2 gSaveSettings Checked%chkS2%, % L("Set_ScrollStyle2")

    ; Card 2: Thao tác chuột & Cử chỉ trình duyệt (Dùng icon .ico thực tế)
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y170 w536 h224, % L("Set_GroupMouseActions")

    AddMouseActionRow(191, "image\scroll_manual.ico", 314, "Set_ManualScroll", "Set_ManualScrollBtn")
    AddMouseActionRow(217, "image\scroll_auto.ico",   315, "Set_AutoScroll",   "Set_AutoScrollBtn")
    AddMouseActionRow(243, "image\scroll_page.ico",   316, "Set_PgScroll",     "Set_PgScrollBtn")
    AddMouseActionRow(269, "image\mouse_volume.ico",  317, "Set_MouseVolume",  "Set_MouseVolumeBtn")

    Gui, Font, s9 Bold c004499, Segoe UI
    Gui, Add, Text, x246 y299 w500, % L("Set_BrowserGesturesTitle")

    AddBrowserGestureRow(323, GestureBadgeBitmaps["L"],  "Set_Back",     "Set_TipGestureL",  GestureBadgeBitmaps["R"],  "Set_Forward", "Set_TipGestureR")
    AddBrowserGestureRow(347, GestureBadgeBitmaps["LU"], "Set_PrevTab",  "Set_TipGestureLU", GestureBadgeBitmaps["LD"], "Set_NextTab", "Set_TipGestureLD")
    AddBrowserGestureRow(371, GestureBadgeBitmaps["RU"], "Set_CloseTab", "Set_TipGestureRU", GestureBadgeBitmaps["RD"], "Set_Refresh", "Set_TipGestureRD")

    ; --------------------------------------------------------
    ; TAB 3: KHÓA BÀN PHÍM && CHUỘT
    ; --------------------------------------------------------
    Gui, Tab, TabLock
    AddSettingsTabHeader("Set_HeaderLock", "Set_SubLock", 364)
    Gui, Font, s8.5 Bold c004499, Segoe UI
    Gui, Add, Button, x598 y9 w166 h39 +0x2000 gActionOpenLockCenter +HwndhBtnLockCenterHeader, % L("Lock_CenterBtnTwoLine")
    SettingsTooltips[hBtnLockCenterHeader] := L("Lock_CenterBtnTip")

    ; Card 1: Thiết lập khóa thiết bị
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y58 w536 h88, % L("Lock_Card1Title")

    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Picture, x246 y78 w22 h22 Icon28, %A_WinDir%\System32\ddores.dll
    Gui, Add, Checkbox, x272 y79 w120 h22 vlockKeyboardEnabled gSaveSettings Checked%lockKeyboardEnabled%, % L("Lock_TargetKB")
    Gui, Add, Picture, x398 y78 w22 h22 Icon32, %A_WinDir%\System32\ddores.dll
    Gui, Add, Checkbox, x424 y79 w98 h22 vmouseLockEnabled gSaveSettings Checked%mouseLockEnabled%, % L("Lock_TargetMouse")
    Gui, Font, s9 Norm c222222, Segoe UI
    Gui, Add, Button, x528 y77 w218 h26 gOpenWhitelistGui, % L("Lock_WhitelistBtn")

    Gui, Font, s9.5 Norm c222222, Segoe UI
    if (LockTabIcons["idle"])
        Gui, Add, Picture, x246 y112 w20 h20, % "HICON:*" . LockTabIcons["idle"]
    Gui, Add, Checkbox, x272 y113 w250 vautoLockIdleEnabled gOnToggleIdleCheck Checked%autoLockIdleEnabled%, % L("Lock_AutoIdleCheck")
    Gui, Font, s9 Norm c222222, Segoe UI
    Gui, Add, DropDownList, x528 y110 w218 vautoLockIdleMinutesChoice gSaveSettings Choose%selIdleIdx%, %idleMinutesList%

    ; Card 2: Hành vi khi đang khóa
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y156 w536 h82, % L("Lock_Card2BehaviorTitle")

    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Checkbox, x246 y176 w174 h22 vpreventScreenOff gSaveSettings Checked%preventScreenOff%, % L("Lock_PreventScreenOff")
    Gui, Add, Checkbox, x426 y176 w142 h22 vpreventSleep gSaveSettings Checked%preventSleep%, % L("Lock_PreventSleep")
    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x574 y179 w172 h18 +Right, % L("Lock_PowerScopeHint")

    Gui, Font, s9.5 Norm c222222, Segoe UI
    if (LockTabIcons["toast"])
        Gui, Add, Picture, x246 y205 w20 h20, % "HICON:*" . LockTabIcons["toast"]
    Gui, Add, Checkbox, x272 y205 w474 h22 valwaysShowLockToast gSaveSettings Checked%alwaysShowLockToast%, % L("Lock_AlwaysShowToast")

    ; Card 3: Bảo mật & Mở khóa
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y248 w536 h150, % L("Lock_Card2Title")

    chkCustomMode := windowsLogonOnly ? 0 : 1
    chkWinOnlyMode := windowsLogonOnly ? 1 : 0
    Gui, Font, s9.5 Norm c222222, Segoe UI
    if (LockTabIcons["key"])
        Gui, Add, Picture, x246 y269 w20 h20, % "HICON:*" . LockTabIcons["key"]
    Gui, Add, Radio, x272 y269 w474 h22 vUnlockModeCustom gOnSelectUnlockModeCustom Checked%chkCustomMode%, % L("Lock_ModeCustom")

    Gui, Add, Text, x288 y301 w94 vLockKeyPromptLbl, % L("Lock_KeyPrompt")
    Gui, Font, s9 Norm c222222, Segoe UI
    Gui, Add, Edit, x384 y298 w184 h24 vUnlockCodeDisplay ReadOnly Password, %UNLOCK_KEYWORD%
    Gui, Add, Button, x574 y297 w34 h26 +0x0040 gToggleRevealCode vBtnToggleReveal +HwndhBtnToggleReveal
    if (LockTabIcons["eye_show"]) {
        DllCall("SendMessage", "Ptr", hBtnToggleReveal, "UInt", 0x00F7, "Ptr", 1, "Ptr", LockTabIcons["eye_show"])
        SettingsTooltips[hBtnToggleReveal] := L("Lock_RevealShowTip")
    }
    Gui, Add, Button, x614 y297 w132 h26 gOpenChangeCodeGui vBtnChangeCode, % L("Lock_ChangeCodeBtn")

    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Checkbox, x288 y331 w458 h22 vrequireCodeForTimerEdit gSaveSettings Checked%requireCodeForTimerEdit%, % L("Lock_ReqTimerEditCode")

    if (LockTabIcons["winlock"])
        Gui, Add, Picture, x246 y362 w20 h20, % "HICON:*" . LockTabIcons["winlock"]
    Gui, Add, Radio, x272 y362 w474 h22 vUnlockModeWinOnly gOnSelectUnlockModeWinOnly Checked%chkWinOnlyMode%, % L("Lock_ModeWinOnly")

    ; --------------------------------------------------------
    ; TAB 4: PHÍM TẮT && TIỆN ÍCH
    ; --------------------------------------------------------
    Gui, Tab, TabShortcuts
    AddSettingsTabHeader("Set_HeaderShortcuts", "Set_SubShortcuts")

    ; Card 1: Phím tắt hệ thống
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y54 w536 h202, % L("Set_GroupSystemHotkeys")

    AddShortcutRow(74,  "Icon28",  A_WinDir . "\System32\ddores.dll",  "Set_LockCenter", "Ctrl + Alt + L",   "ActionOpenLockCenter")
    AddShortcutRow(102, "Icon261", A_WinDir . "\System32\shell32.dll", "Set_PastePlain", "Ctrl + Shift + V", "ActionPastePlain")
    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x274 y124 w472 h18, % L("Set_PastePlainDesc")
    AddShortcutRow(146, "Icon3",   A_WinDir . "\System32\SndVol.exe",  "Set_Mute",       "Ctrl + Shift + M", "ActionMute")
    AddShortcutRow(174, "Icon2",   A_WinDir . "\System32\SndVol.exe",  "Set_Volume",     L("Set_VolUpBtn"),    "ActionVolUp",     L("Set_VolDownBtn"),  "ActionVolDown")
    AddShortcutRow(202, "Icon26",  A_WinDir . "\System32\shell32.dll", "Set_Brightness", L("Set_BrightDownBtn"), "ActionBrightDown", L("Set_BrightUpBtn"), "ActionBrightUp")

    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x246 y233 w500 h18, % L("Set_ShortcutsTip")

    ; Card 2: Ghim cửa sổ luôn nổi (Always On Top)
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y262 w536 h78, % L("Set_GroupAOT")
    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Checkbox, x246 y283 w214 h22 vAOTEnabled gOnToggleAOTEnabled Checked%AOTEnabled%, % L("AOT_EnableChk")
    Gui, Font, s9 Norm c555555, Segoe UI
    Gui, Add, Text, x464 y286 w56 h18, % L("AOT_HotkeyLbl")
    Gui, Font, s9 Norm c222222, Segoe UI
    aotHkDisplay := IsFunc("FormatAOTHotkeyText") ? FormatAOTHotkeyText(AOTHotkey) : "Win + Ctrl + T"
    Gui, Add, Button, x522 y281 w120 h25 vAOTHotkeyBtn gOnChangeAOTHotkey, %aotHkDisplay%
    Gui, Add, Button, x648 y281 w104 h25 vAOTUnpinAllBtn gOnUnpinAllAOT, % L("AOT_UnpinAllBtn")
    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Checkbox, x246 y310 w500 h22 vAOTBorderEnabled gOnToggleAOTBorder Checked%AOTBorderEnabled%, % L("AOT_BorderChk")

    ; Card 3: Thao tác nhanh trên khay hệ thống
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y344 w536 h60, % L("Set_GroupTrayActions")

    AddShortcutRow(362, "Icon1", aboutIcon, "Set_TrayToggleLabel", L("Set_TrayToggleBtn"), "ActionToggleGestures")
    Gui, Font, s8.5 Norm c555555, Segoe UI
    Gui, Add, Text, x246 y385 w500 h16, % "• " . L("Set_TrayDblClickTip")

    ; --------------------------------------------------------
    ; TAB 5: THÔNG TIN && BẢN QUYỀN (HERO BANNER HIỆN ĐẠI)
    ; --------------------------------------------------------
    Gui, Tab, TabAbout

    ; Hero Card nền xanh nhạt (#EEF5FC) với viền nhẹ & thanh nhấn xanh
    Gui, Add, Progress, x228 y14 w536 h116 BackgroundD0E3F7 cD0E3F7 -Theme Disabled, 100
    Gui, Add, Progress, x229 y15 w534 h114 BackgroundEEF5FC cEEF5FC -Theme Disabled, 100
    Gui, Add, Progress, x229 y15 w4 h114 Background0067C0 c0067C0 -Theme Disabled, 100

    if (!hAboutHeroBmp)
        hAboutHeroBmp := CreateAboutHeroIconBitmap(56, 0xEEF5FC)
    if (hAboutHeroBmp)
        Gui, Add, Picture, x248 y43, HBITMAP:*%hAboutHeroBmp%
    else
        AddSettingsIcon(248, 43, 56, 56, "image\unnamed.ico", 1)

    Gui, Font, s15 Bold c004499, Segoe UI
    Gui, Add, Text, x318 y24 w285 +BackgroundTrans, GestureMouse
    Gui, Font, s9.5 Norm c2C3E50, Segoe UI
    Gui, Add, Text, x318 y52 w288 h34 +BackgroundTrans, % L("About_Headline")
    Gui, Font, s8.5 Norm c5A6B7C, Segoe UI
    Gui, Add, Text, x318 y93 w288 +BackgroundTrans, % L("About_HeroMeta")

    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Button, x616 y55 w130 h32 gOpenDonateLink, % "❤ " . L("About_Donate")

    ; Dải 3 nút hành động nhanh
    Gui, Font, s9 Norm c222222, Segoe UI
    Gui, Add, Button, x228 y142 w172 h30 gCheckForUpdates, % L("Tray_CheckUpdate")
    Gui, Add, Button, x410 y142 w172 h30 gOpenGitHubLink, GitHub Releases
    Gui, Add, Button, x592 y142 w172 h30 gOpenEmailLink, % L("About_ContactBtn")

    Gui, Add, Text, x228 y184 w536 h1 0x10

    ; Đoạn giới thiệu ngắn gọn (bôi đen copy được, không thanh cuộn)
    Gui, Font, s9.5 Norm c333333, Segoe UI
    Gui, Add, Edit, x228 y196 w536 h44 ReadOnly -E0x200 -VScroll -Tabstop HwndhAboutDetailEdit, % L("About_ShortDesc")
    DllCall("SendMessage", "Ptr", hAboutDetailEdit, "UInt", 0x00D3, "Ptr", 1, "Ptr", 0)

    Gui, Add, Text, x228 y248 w536 h1 0x10

    ; Bảng thông tin 2 cột (Tác giả, Giấy phép, Email, Mã nguồn)
    Gui, Font, s9 Norm c666666, Segoe UI
    Gui, Add, Text, x228 y264 w108, % L("About_LblAuthor")
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, Edit, x340 y263 w424 h20 ReadOnly -E0x200 -VScroll -Tabstop HwndhAboutAuthorEdit, % L("About_ValAuthor")
    DllCall("SendMessage", "Ptr", hAboutAuthorEdit, "UInt", 0x00D3, "Ptr", 1, "Ptr", 0)

    Gui, Font, s9 Norm c666666, Segoe UI
    Gui, Add, Text, x228 y292 w108, % L("About_LblLicense")
    Gui, Font, s9.5 Norm c333333, Segoe UI
    Gui, Add, Text, x340 y292 w424 h20, % L("About_ValLicense")

    Gui, Font, s9 Norm c666666, Segoe UI
    Gui, Add, Text, x228 y320 w108, % L("About_LblEmail")
    Gui, Font, s9.5 Norm c333333, Segoe UI
    Gui, Add, Link, x340 y320 w424 h20 gOnAboutLinkClick, <a href="mailto:nguyentrian87@gmail.com">nguyentrian87@gmail.com</a>

    Gui, Font, s9 Norm c666666, Segoe UI
    Gui, Add, Text, x228 y348 w108, % L("About_LblRepo")
    Gui, Font, s9.5 Norm c333333, Segoe UI
    Gui, Add, Link, x340 y348 w424 h20 gOnAboutLinkClick, <a href="https://github.com/ngtrian/GestureMouse">https://github.com/ngtrian/GestureMouse</a>

    ; ========================================================
    ; CHÂN TRANG GỌN GÀNG (AUTO-SAVE + NÚT ĐÓNG)
    ; ========================================================
    Gui, Tab
    Gui, Font, s8.5 Norm c777777, Segoe UI
    Gui, Add, Text, x228 y418 w415, % L("Set_AutoSaveHint")
    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Button, x658 y411 w106 h30 gSettingsCloseBtn Default, % L("Set_Close")

    ; Khởi tạo trạng thái Enable/Disable của control
    GuiControl, Enable%autoLockIdleEnabled%, autoLockIdleMinutesChoice
    UpdateLockAuthControlsState(windowsLogonOnly)
    GuiControl, Enable%AOTEnabled%, AOTHotkeyBtn
    GuiControl, Enable%AOTEnabled%, AOTBorderEnabled
    GuiControl, Enable%AOTEnabled%, AOTUnpinAllBtn

    ; Khởi tạo hiển thị tab hiện tại với background sidebar được tô màu
    SwitchSettingsTab(currentSettingsTab ? currentSettingsTab : 1, true)

    ; Đăng ký theo dõi hover để hiển thị chú thích cho icon cử chỉ
    OnMessage(0x200, "WM_MOUSEMOVE_SETTINGS")

    DllCall("SendMessage", "Ptr", hSettingsGui, "UInt", 0x000B, "Ptr", 1, "Ptr", 0) ; WM_SETREDRAW = TRUE
    SetBatchLines, %prevBatchLines%

    ; Khi preload nền: Show với Hide để AHK tính sẵn kích thước w780 h455 & vị trí Center
    ; Khi mở trực tiếp: hiển thị ngay lập tức
    if (isPreload)
        Gui, Settings:Show, Hide w780 h455 Center, % "GestureMouse - " . L("Set_Title")
    else
        Gui, Settings:Show, w780 h455 Center, % "GestureMouse - " . L("Set_Title")
return

; ========================================================
; HELPER DỰNG LAYOUT THỐNG NHẤT CHO CÁC TAB & CONTROL
; ========================================================
AddSidebarNav(idx, yPos, iconChar, labelText) {
    global NavBg1, NavBg2, NavBg3, NavBg4, NavBg5
    global NavInd1, NavInd2, NavInd3, NavInd4, NavInd5
    global NavIco1, NavIco2, NavIco3, NavIco4, NavIco5
    global NavTxt1, NavTxt2, NavTxt3, NavTxt4, NavTxt5
    global SidebarNavBitmaps, SidebarIconHwnds
    indY := yPos + 7
    Gui, Settings:Font, s9.5 Norm c444444, Segoe UI
    Gui, Settings:Add, Progress, x10 y%yPos% w192 h34 BackgroundE5F1FB cE5F1FB vNavBg%idx% -Theme Disabled, 100
    Gui, Settings:Add, Progress, x10 y%indY% w3 h20 Background0067C0 c0067C0 vNavInd%idx% -Theme Disabled, 100
    if (SidebarNavBitmaps.HasKey(idx)) {
        hBmpInit := SidebarNavBitmaps[idx].inactive
        Gui, Settings:Add, Picture, x22 y%indY% +0x100 gOnNav%idx% vNavIco%idx% +HwndhIco, HBITMAP:*%hBmpInit%
        SidebarIconHwnds[idx] := hIco
        Gui, Settings:Add, Text, x48 y%yPos% w150 h34 +0x200 +BackgroundTrans gOnNav%idx% vNavTxt%idx%, %labelText%
    } else {
        Gui, Settings:Add, Text, x20 y%yPos% w180 h34 +0x200 +BackgroundTrans gOnNav%idx% vNavTxt%idx%, % "  " . iconChar . "  " . labelText
    }
}

AddSettingsTabHeader(titleKey, subKey, titleWidth := 536) {
    Gui, Settings:Font, s13 Bold c004499, Segoe UI
    Gui, Settings:Add, Text, x228 y12 w%titleWidth%, % L(titleKey)
    Gui, Settings:Font, s8.5 Norm c666666, Segoe UI
    Gui, Settings:Add, Text, x228 y35 w%titleWidth%, % L(subKey)
}

AddSettingsIcon(x, y, w, h, relPath, resId := 0) {
    if (A_IsCompiled && resId > 0) {
        Gui, Settings:Add, Picture, x%x% y%y% w%w% h%h% Icon-%resId%, %A_ScriptFullPath%
    } else {
        fullPath := A_ScriptDir . "\" . relPath
        if (FileExist(fullPath))
            Gui, Settings:Add, Picture, x%x% y%y% w%w% h%h%, %fullPath%
    }
}

AddMouseActionRow(yPos, icoRelPath, resId, labelKey, descKey) {
    icoY := yPos - 1
    AddSettingsIcon(246, icoY, 20, 20, icoRelPath, resId)
    Gui, Settings:Font, s9 Norm c222222, Segoe UI
    Gui, Settings:Add, Text, x278 y%yPos% w154, % L(labelKey)
    Gui, Settings:Font, s8.5 Norm c555555, Segoe UI
    Gui, Settings:Add, Text, x436 y%yPos% w310, % "→ " . L(descKey)
}

AddBrowserGestureRow(yPos, hBmp1, labelKey1, tipKey1, hBmp2, labelKey2, tipKey2) {
    global SettingsTooltips
    badgeY := yPos - 2
    Gui, Settings:Font, s9 Norm c222222, Segoe UI
    Gui, Settings:Add, Text, x246 y%yPos% w160, % L(labelKey1)
    if (hBmp1) {
        Gui, Settings:Add, Picture, x412 y%badgeY% +0x100 HwndhBadge1, HBITMAP:*%hBmp1%
        SettingsTooltips[hBadge1] := L(tipKey1)
    }

    Gui, Settings:Font, s9 Norm c222222, Segoe UI
    Gui, Settings:Add, Text, x500 y%yPos% w170, % L(labelKey2)
    if (hBmp2) {
        Gui, Settings:Add, Picture, x676 y%badgeY% +0x100 HwndhBadge2, HBITMAP:*%hBmp2%
        SettingsTooltips[hBadge2] := L(tipKey2)
    }
}

WM_MOUSEMOVE_SETTINGS(wParam, lParam, msg, hwnd) {
    global SettingsTooltips, LastSettingsTipHwnd, hSettingsGui
    if (!hSettingsGui || !WinExist("ahk_id " . hSettingsGui))
        return

    MouseGetPos, , , idUnderMouse, ctrlUnderMouse, 2
    if (idUnderMouse == hSettingsGui && ctrlUnderMouse && SettingsTooltips.HasKey(ctrlUnderMouse)) {
        if (LastSettingsTipHwnd != ctrlUnderMouse) {
            LastSettingsTipHwnd := ctrlUnderMouse
            ToolTip, % SettingsTooltips[ctrlUnderMouse]
            SetTimer, CheckSettingsTooltipLeave, 120
        }
    } else if (LastSettingsTipHwnd) {
        ClearSettingsTooltip()
    }
}

ClearSettingsTooltip() {
    global LastSettingsTipHwnd
    if (LastSettingsTipHwnd) {
        ToolTip
        LastSettingsTipHwnd := 0
    }
    SetTimer, CheckSettingsTooltipLeave, Off
}

CheckSettingsTooltipLeave:
    MouseGetPos, , , idUnderMouse, ctrlUnderMouse, 2
    if (!hSettingsGui || idUnderMouse != hSettingsGui || !SettingsTooltips.HasKey(ctrlUnderMouse)) {
        ClearSettingsTooltip()
    }
return

AddShortcutRow(yPos, iconOpt, iconFile, labelKey, btn1Text, gLabel1, btn2Text := "", gLabel2 := "") {
    icoY := yPos - 1
    btnY := yPos - 4
    if (iconFile != "" && FileExist(iconFile))
        Gui, Settings:Add, Picture, x246 y%icoY% w20 h20 %iconOpt%, %iconFile%
    Gui, Settings:Font, s9.5 Norm c222222, Segoe UI
    Gui, Settings:Add, Text, x274 y%yPos% w256, % L(labelKey)
    Gui, Settings:Font, s9 Norm c222222, Segoe UI
    if (btn2Text = "") {
        Gui, Settings:Add, Button, x536 y%btnY% w210 h26 Center g%gLabel1%, %btn1Text%
    } else {
        Gui, Settings:Add, Button, x536 y%btnY% w102 h26 Center g%gLabel1%, %btn1Text%
        Gui, Settings:Add, Button, x644 y%btnY% w102 h26 Center g%gLabel2%, %btn2Text%
    }
}

GetIdleMinuteIndex(mins) {
    static minuteOptions := [1, 3, 5, 10, 15, 30, 60]
    for idx, val in minuteOptions {
        if (mins == val)
            return idx
    }
    return 3 ; Mặc định 5 phút
}

; ========================================================
; HÀM CẬP NHẬT NHANH CÁC CONTROL KHI TÁI SỬ DỤNG GUI (SINGLETON)
; ========================================================
UpdateSettingsGuiControls() {
    global

    ; Đọc trạng thái khởi động cùng Windows
    RegRead, AutoStart, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, GestureMouse
    AutoStart := (AutoStart != "") ? 1 : 0
    GuiControl, Settings:, AutoStart, %AutoStart%

    ; Đọc phương pháp cuộn chuột
    RegRead, ScrollStyle, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, ScrollStyle
    if (ErrorLevel || ScrollStyle = "" || ScrollStyle < 1 || ScrollStyle > 2)
        ScrollStyle := 1
    chkS1 := (ScrollStyle = 1) ? 1 : 0
    chkS2 := (ScrollStyle = 2) ? 1 : 0
    GuiControl, Settings:, ScrollStyle1, %chkS1%
    GuiControl, Settings:, ScrollStyle2, %chkS2%

    ; Đọc trạng thái Cử chỉ chuột
    GuiControl, Settings:, GestureEnabled, %GestureScrollEnabled%

    ; Cập nhật cấu hình khóa
    if (IsFunc("LoadLockSettings"))
        LoadLockSettings()

    GuiControl, Settings:, lockKeyboardEnabled, %lockKeyboardEnabled%
    GuiControl, Settings:, mouseLockEnabled, %mouseLockEnabled%

    GuiControl, Settings:, autoLockIdleEnabled, %autoLockIdleEnabled%
    GuiControl, Settings:Enable%autoLockIdleEnabled%, autoLockIdleMinutesChoice
    selIdleIdx := GetIdleMinuteIndex(autoLockIdleMinutes)
    GuiControl, Settings:Choose, autoLockIdleMinutesChoice, %selIdleIdx%

    GuiControl, Settings:, preventScreenOff, %preventScreenOff%
    GuiControl, Settings:, preventSleep, %preventSleep%
    GuiControl, Settings:, alwaysShowLockToast, %alwaysShowLockToast%
    GuiControl, Settings:, requireCodeForTimerEdit, %requireCodeForTimerEdit%
    GuiControl, Settings:, UnlockCodeDisplay, %UNLOCK_KEYWORD%
    UpdateLockAuthControlsState(windowsLogonOnly)

    chkVI := (CurrentLang = "vi") ? 1 : 0
    chkEN := (CurrentLang = "en") ? 1 : 0
    GuiControl, Settings:, LangVI, %chkVI%
    GuiControl, Settings:, LangEN, %chkEN%

    GuiControl, Settings:, AOTEnabled, %AOTEnabled%
    GuiControl, Settings:, AOTBorderEnabled, %AOTBorderEnabled%
    if (IsFunc("FormatAOTHotkeyText"))
        GuiControl, Settings:, AOTHotkeyBtn, % FormatAOTHotkeyText(AOTHotkey)
    GuiControl, Settings:Enable%AOTEnabled%, AOTHotkeyBtn
    GuiControl, Settings:Enable%AOTEnabled%, AOTBorderEnabled
    GuiControl, Settings:Enable%AOTEnabled%, AOTUnpinAllBtn
}

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

SwitchSettingsTab(tabNum, skipRedraw := false) {
    global currentSettingsTab, hSettingsGui, SidebarNavBitmaps, SidebarIconHwnds
    ClearSettingsTooltip()
    currentSettingsTab := tabNum
    if (!hSettingsGui)
        return
    Gui, Settings:Default
    GuiControl, Settings:Choose, SettingsTabNav, %tabNum%
    Loop 5 {
        isActive := (A_Index == tabNum)
        if (isActive) {
            GuiControl, Settings:Show, NavBg%A_Index%
            GuiControl, Settings:Show, NavInd%A_Index%
            Gui, Settings:Font, s9.5 Bold c005FB8, Segoe UI
        } else {
            GuiControl, Settings:Hide, NavBg%A_Index%
            GuiControl, Settings:Hide, NavInd%A_Index%
            Gui, Settings:Font, s9.5 Norm c444444, Segoe UI
        }
        GuiControl, Settings:Font, NavTxt%A_Index%
        GuiControl, Settings:+BackgroundTrans, NavTxt%A_Index%
        if (!skipRedraw)
            GuiControl, Settings:MoveDraw, NavTxt%A_Index%
        if (SidebarIconHwnds.HasKey(A_Index) && SidebarNavBitmaps.HasKey(A_Index)) {
            hBmp := isActive ? SidebarNavBitmaps[A_Index].active : SidebarNavBitmaps[A_Index].inactive
            DllCall("SendMessage", "Ptr", SidebarIconHwnds[A_Index], "UInt", 0x0172, "Ptr", 0, "Ptr", hBmp)
            if (!skipRedraw)
                GuiControl, Settings:MoveDraw, NavIco%A_Index%
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
    } else {
        GuiControl, +Password, UnlockCodeDisplay
    }
    UpdateRevealButtonVisual(isCodeRevealed)
    GuiControl,, UnlockCodeDisplay, %UNLOCK_KEYWORD%
return

UpdateRevealButtonVisual(revealed) {
    global LockTabIcons, hBtnToggleReveal, SettingsTooltips
    if (!hBtnToggleReveal)
        return
    hIcon := revealed ? LockTabIcons["eye_hide"] : LockTabIcons["eye_show"]
    if (hIcon)
        DllCall("SendMessage", "Ptr", hBtnToggleReveal, "UInt", 0x00F7, "Ptr", 1, "Ptr", hIcon)
    SettingsTooltips[hBtnToggleReveal] := revealed ? L("Lock_RevealHideTip") : L("Lock_RevealShowTip")
}

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

    Gui, Add, GroupBox, x15 y12 w350 h125, % L("Lock_ChangeCodeTitle")
    Gui, Add, Text, x30 y42 w130, % L("Lock_NewCode")
    Gui, Add, Edit, x165 y39 w180 h24 Password vNewUnlockCodeInput
    Gui, Add, Text, x30 y80 w130, % L("Lock_ConfirmCode")
    Gui, Add, Edit, x165 y77 w180 h24 Password vConfirmUnlockCodeInput

    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Button, x145 y150 w105 h30 gSubmitChangeCode Default, % L("Set_Apply")
    Gui, Add, Button, x260 y150 w105 h30 gCloseChangeCodeGui, % L("Lock_PassCancel")

    Gui, Show, w380 h192 Center, % L("Lock_ChangeCodeTitle")
return

SubmitChangeCode:
    Gui, ChangeCodeGui:Submit, NoHide
    if (NewUnlockCodeInput = "") {
        MsgBox, 48, GestureMouse, % L("Lock_CodeEmpty")
        GuiControl, Focus, NewUnlockCodeInput
        return
    }
    if !(NewUnlockCodeInput == ConfirmUnlockCodeInput) {
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
; MỞ TRUNG TÂM KHÓA TỪ SETTINGS
; ========================================================
ActionOpenLockCenter:
    if (IsFunc("OpenLockCenterFromUI"))
        OpenLockCenterFromUI()
return

ActionFocusLockFromSettings:
    Gui, Settings:Hide
    Sleep, 150
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

OnSelectUnlockModeCustom:
    windowsLogonOnly := 0
    UpdateLockAuthControlsState(0)
    Gosub, SaveSettings
return

OnSelectUnlockModeWinOnly:
    windowsLogonOnly := 1
    UpdateLockAuthControlsState(1)
    Gosub, SaveSettings
return

UpdateLockAuthControlsState(winOnly) {
    global isCodeRevealed, UNLOCK_KEYWORD
    winOnlyFlag := winOnly ? 1 : 0
    enableCustom := winOnlyFlag ? 0 : 1
    GuiControl, Settings:, UnlockModeCustom, %enableCustom%
    GuiControl, Settings:, UnlockModeWinOnly, %winOnlyFlag%
    if (winOnlyFlag && isCodeRevealed) {
        isCodeRevealed := 0
        GuiControl, Settings:+Password, UnlockCodeDisplay
        UpdateRevealButtonVisual(false)
        GuiControl, Settings:, UnlockCodeDisplay, %UNLOCK_KEYWORD%
    }
    GuiControl, Settings:Enable%enableCustom%, LockKeyPromptLbl
    GuiControl, Settings:Enable%enableCustom%, UnlockCodeDisplay
    GuiControl, Settings:Enable%enableCustom%, BtnToggleReveal
    GuiControl, Settings:Enable%enableCustom%, BtnChangeCode
    GuiControl, Settings:Enable%enableCustom%, requireCodeForTimerEdit
}

OnLangRadio:
    Gui, Settings:Submit, NoHide
    if (LangVI && CurrentLang != "vi") {
        SetLanguage("vi")
    } else if (LangEN && CurrentLang != "en") {
        SetLanguage("en")
    }
return

RefreshSettingsGui:
    if (hSettingsGui) {
        DetectHiddenWindows, On
        isVis := WinExist("ahk_id " . hSettingsGui) && DllCall("IsWindowVisible", "Ptr", hSettingsGui)
        Gui, Settings:Destroy
        hSettingsGui := 0
        DetectHiddenWindows, Off
        if (isVis)
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

    if (IsFunc("RefreshLockCenterDeviceIcons"))
        RefreshLockCenterDeviceIcons()

    ; Lưu Tự động khóa khi không dùng máy (Idle)
    autoLockIdleEnabled := autoLockIdleEnabled ? 1 : 0
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AutoLockIdleEnabled, %autoLockIdleEnabled%
    if (RegExMatch(autoLockIdleMinutesChoice, "(\d+)", mIdle))
        autoLockIdleMinutes := mIdle1
    else
        autoLockIdleMinutes := 5
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AutoLockIdleMinutes, %autoLockIdleMinutes%

    if (IsFunc("InitAutoLockTimer"))
        InitAutoLockTimer()

    ; Lưu tùy chọn chỉ dùng Windows Logon & yêu cầu mã khi chỉnh sửa hẹn giờ
    windowsLogonOnly := UnlockModeWinOnly ? 1 : 0
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, WindowsLogonOnly, %windowsLogonOnly%

    requireCodeForTimerEdit := requireCodeForTimerEdit ? 1 : 0
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, RequireCodeForTimerEdit, %requireCodeForTimerEdit%

    ; Lưu trạng thái ngăn tắt màn hình, ngăn Sleep & thông báo khi khóa
    preventScreenOff := preventScreenOff ? 1 : 0
    preventSleep := preventSleep ? 1 : 0
    alwaysShowLockToast := alwaysShowLockToast ? 1 : 0
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, PreventScreenOff, %preventScreenOff%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, PreventSleep, %preventSleep%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AlwaysShowLockToast, %alwaysShowLockToast%
    if (IsFunc("ApplyLockPowerPolicy"))
        ApplyLockPowerPolicy()

    ; Cập nhật tray tip
    fnTip := "UpdateTrayTip"
    if (IsFunc(fnTip))
        %fnTip%()
return

; ========================================================
; CÀI ĐẶT ALWAYS ON TOP
; ========================================================
OnToggleAOTEnabled:
    Gui, Settings:Submit, NoHide
    AOTEnabled := AOTEnabled ? 1 : 0
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AOTEnabled, %AOTEnabled%
    GuiControl, Settings:Enable%AOTEnabled%, AOTHotkeyBtn
    GuiControl, Settings:Enable%AOTEnabled%, AOTBorderEnabled
    GuiControl, Settings:Enable%AOTEnabled%, AOTUnpinAllBtn
    if (IsFunc("ApplyAOTHotkey"))
        ApplyAOTHotkey()
    if (!AOTEnabled && IsFunc("UnpinAllAlwaysOnTop"))
        UnpinAllAlwaysOnTop()
return

OnToggleAOTBorder:
    Gui, Settings:Submit, NoHide
    AOTBorderEnabled := AOTBorderEnabled ? 1 : 0
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AOTBorderEnabled, %AOTBorderEnabled%
    if (IsFunc("RefreshAllAOTBorders"))
        RefreshAllAOTBorders()
return

OnUnpinAllAOT:
    if (IsFunc("UnpinAllAlwaysOnTop"))
        UnpinAllAlwaysOnTop()
return

OnChangeAOTHotkey:
    ShowAOTHotkeyDialog()
return

ShowAOTHotkeyDialog() {
    global AOTHotkey, hSettingsGui, hAOTHotkeyGui
    global AOTNewWinMod, AOTNewKeyCtrl

    if (hAOTHotkeyGui && WinExist("ahk_id " . hAOTHotkeyGui)) {
        WinActivate, ahk_id %hAOTHotkeyGui%
        return
    }

    hasWin := InStr(AOTHotkey, "#") ? 1 : 0
    baseHk := StrReplace(AOTHotkey, "#")

    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui))
        Gui, Settings:+Disabled

    ownerOpt := (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) ? "+Owner" . hSettingsGui : ""
    Gui, AOTHotkeyDlg:New, -MaximizeBox -MinimizeBox %ownerOpt% +HwndhAOTHotkeyGui, % L("AOT_ChangeHotkeyBtn")
    if (IsFunc("SetGuiYellowIcon"))
        SetGuiYellowIcon(hAOTHotkeyGui)
    Gui, AOTHotkeyDlg:Color, FFFFFF
    Gui, AOTHotkeyDlg:Font, s9.5 Norm c222222, Segoe UI
    Gui, AOTHotkeyDlg:Add, Text, x16 y14 w310, % L("AOT_HotkeyPrompt")
    Gui, AOTHotkeyDlg:Add, Checkbox, x16 y44 w70 h24 vAOTNewWinMod Checked%hasWin%, Win +
    Gui, AOTHotkeyDlg:Add, Hotkey, x92 y43 w234 h24 vAOTNewKeyCtrl, %baseHk%
    Gui, AOTHotkeyDlg:Add, Button, x16 y82 w110 h28 gOnResetAOTHotkey, Win + Ctrl + T
    Gui, AOTHotkeyDlg:Add, Button, x176 y82 w72 h28 Default gOnSaveAOTHotkey, OK
    Gui, AOTHotkeyDlg:Add, Button, x254 y82 w72 h28 gAOTHotkeyDlgGuiClose, % L("Set_Close")
    Gui, AOTHotkeyDlg:Show, w342 h124 Center
}

OnResetAOTHotkey:
    GuiControl, AOTHotkeyDlg:, AOTNewWinMod, 1
    GuiControl, AOTHotkeyDlg:, AOTNewKeyCtrl, ^t
return

OnSaveAOTHotkey:
    Gui, AOTHotkeyDlg:Submit, NoHide
    if (AOTNewKeyCtrl = "")
        return
    newHk := (AOTNewWinMod ? "#" : "") . AOTNewKeyCtrl
    AOTHotkey := newHk
    RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AOTHotkey, %AOTHotkey%
    if (IsFunc("ApplyAOTHotkey"))
        ApplyAOTHotkey()
    if (IsFunc("FormatAOTHotkeyText"))
        GuiControl, Settings:, AOTHotkeyBtn, % FormatAOTHotkeyText(AOTHotkey)
    Gosub, AOTHotkeyDlgGuiClose
return

AOTHotkeyDlgGuiClose:
AOTHotkeyDlgGuiEscape:
    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) {
        Gui, Settings:-Disabled
        WinActivate, ahk_id %hSettingsGui%
    }
    Gui, AOTHotkeyDlg:Destroy
    hAOTHotkeyGui := 0
return

OpenGitHubLink:
    Run, https://github.com/ngtrian/GestureMouse/releases
return

OnAboutLinkClick:
    if (ErrorLevel != "") {
        try Run, %ErrorLevel%
    }
return

SettingsCloseBtn:
SettingsGuiClose:
SettingsGuiEscape:
    ClearSettingsTooltip()
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
    ; Ẩn giao diện Settings thay vì Destroy để lần sau mở tức thì (Singleton GUI)
    Gui, Settings:Hide
return

; ========================================================
; DIALOG CẤU HÌNH NGOẠI LỆ (WHITELIST)
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

    Gui, Add, GroupBox, x15 y12 w430 h215, % L("Lock_AllowGroup")
    Gui, Add, Checkbox, x30 y38 w400 vwl_allowMouseMove Checked%allowMouseMove%, % L("Lock_AllowMouseMove")
    Gui, Add, Checkbox, x30 y70 w400 vwl_allowMouseWheel Checked%allowMouseWheel%, % L("Lock_AllowMouseWheel")
    Gui, Add, Checkbox, x30 y102 w400 vwl_allowSpace Checked%allowSpace%, % L("Lock_AllowSpace")
    Gui, Add, Checkbox, x30 y134 w400 vwl_allowMedia Checked%allowMedia%, % L("Lock_AllowMedia")
    Gui, Add, Checkbox, x30 y166 w400 vwl_allowNav Checked%allowNav%, % L("Lock_AllowNav")

    Gui, Font, s8.5 Norm c777777, Segoe UI
    Gui, Add, Text, x15 y235 w430, % L("Lock_WhitelistTip")

    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Button, x225 y265 w110 h30 gApplyWhitelist Default, % L("Set_Apply")
    Gui, Add, Button, x345 y265 w100 h30 gCloseWhitelistGui, % L("Set_Close")

    Gui, Show, w460 h308 Center, % L("Lock_WhitelistTitle")
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

; Giải phóng các GDI HBITMAP và HICON đã cache của giao diện Cài đặt khi thoát ứng dụng
CleanupSettingsIcons() {
    global SidebarNavBitmaps, LockTabIcons, GestureBadgeBitmaps, hAboutHeroBmp
    for idx, states in SidebarNavBitmaps {
        if (states.inactive)
            DllCall("DeleteObject", "Ptr", states.inactive)
        if (states.active)
            DllCall("DeleteObject", "Ptr", states.active)
    }
    SidebarNavBitmaps := {}

    for dirKey, hBmp in GestureBadgeBitmaps {
        if (hBmp)
            DllCall("DeleteObject", "Ptr", hBmp)
    }
    GestureBadgeBitmaps := {}

    for iconKey, hIcon in LockTabIcons {
        if (hIcon)
            DllCall("DestroyIcon", "Ptr", hIcon)
    }
    LockTabIcons := {}

    if (hAboutHeroBmp) {
        DllCall("DeleteObject", "Ptr", hAboutHeroBmp)
        hAboutHeroBmp := 0
    }
}
