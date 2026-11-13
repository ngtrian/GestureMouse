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
global hSettingsSep         := 0
global hSettingsTabNav      := 0
global hShortcutsScroll     := 0
global sysExpanded          := 1
global micExpanded          := 0
global aotExpanded          := 1
global trayExpanded         := 1
global shortcutsScrollPos   := 0
global shortcutsContentH    := 470
global SysGroupItems        := []
global MicGroupItems        := []
global AotGroupItems        := []
global TrayGroupItems       := []
global hMicHotkeyDlg        := 0
global MicHotkeyCaptured    := ""
global MicHotkeyCapturing   := false

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
            SwitchSettingsTab(targetTab, !isVisible)
            Gui, Settings:Show, w780 h455 Center, % "GestureMouse - " . L("Set_Title")
            if (currentSettingsTab = 4 && hShortcutsScroll) {
                SyncShortcutsScrollPanelSize()
                UpdateShortcutsScrollInfo()
            }
            WinActivate, ahk_id %hSettingsGui%
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
    Gui, Add, Text, x212 y12 w1 h428 0x11 +HwndhSettingsSep

    ; ========================================================
    ; VÙNG NỘI DUNG BÊN PHẢI (TAB2 +Buttons ẨN HOÀN TOÀN VIỀN KHUNG)
    ; ========================================================
    Gui, Add, Tab2, x216 y-35 w564 h439 +Buttons -Theme -Wrap +0x04000000 vSettingsTabNav +HwndhSettingsTabNav, TabGeneral|TabScrollGesture|TabLock|TabShortcuts|TabAbout

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
    ; TAB 4: PHÍM TẮT && TIỆN ÍCH (DỰNG TRONG CHILD GUI CÓ THANH CUỘN DỌC)
    ; --------------------------------------------------------
    Gui, Tab, TabShortcuts

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
    Gui, Add, Text, x228 y418 w415 vSettingsAutoSaveHint, % L("Set_AutoSaveHint")
    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Button, x658 y411 w106 h30 vSettingsCloseBtn gSettingsCloseBtn Default, % L("Set_Close")

    ; Dựng vùng cuộn dọc cho Tab Phím tắt & Tiện ích
    BuildShortcutsScrollPanel(aboutIcon)

    ; Khởi tạo trạng thái Enable/Disable của control
    GuiControl, Settings:Enable%autoLockIdleEnabled%, autoLockIdleMinutesChoice
    UpdateLockAuthControlsState(windowsLogonOnly)
    GuiControl, ShortcutsScroll:Enable%AOTEnabled%, AOTHotkeyBtn
    GuiControl, ShortcutsScroll:Enable%AOTEnabled%, AOTBorderEnabled
    GuiControl, ShortcutsScroll:Enable%AOTEnabled%, AOTUnpinAllBtn
    UpdateMicControlsState()

    ; Khởi tạo hiển thị tab hiện tại với background sidebar được tô màu
    SwitchSettingsTab(currentSettingsTab ? currentSettingsTab : 1, true)

    ; Đăng ký theo dõi hover, cuộn dọc & lăn chuột cho vùng Phím tắt
    OnMessage(0x200, "WM_MOUSEMOVE_SETTINGS")
    OnMessage(0x115, "OnShortcutsVScroll")
    OnMessage(0x20A, "OnShortcutsMouseWheel")

    DllCall("SendMessage", "Ptr", hSettingsGui, "UInt", 0x000B, "Ptr", 1, "Ptr", 0) ; WM_SETREDRAW = TRUE
    SetBatchLines, %prevBatchLines%

    ; Khi preload nền: Show với Hide để AHK tính sẵn kích thước w780 h455 & vị trí Center
    ; Khi mở trực tiếp: hiển thị ngay lập tức
    if (isPreload)
        Gui, Settings:Show, Hide w780 h455 Center, % "GestureMouse - " . L("Set_Title")
    else
        Gui, Settings:Show, w780 h455 Center, % "GestureMouse - " . L("Set_Title")
    if (currentSettingsTab = 4 && hShortcutsScroll) {
        SyncShortcutsScrollPanelSize()
        UpdateShortcutsScrollInfo()
    }
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

AddShortcutRow(yPos, iconOpt, iconFile, labelKey, btn1Text, gLabel1, btn2Text := "", gLabel2 := "", itemsArr := 0, groupBaseY := 54) {
    icoY := yPos - 1
    btnY := yPos - 4
    if (iconFile != "" && FileExist(iconFile)) {
        Gui, ShortcutsScroll:Add, Picture, x30 y%icoY% w20 h20 %iconOpt% +HwndhPic, %iconFile%
        if (IsObject(itemsArr))
            itemsArr.Push({hwnd: hPic, relY: icoY - groupBaseY})
    }
    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Text, x58 y%yPos% w256 +HwndhLbl, % L(labelKey)
    if (IsObject(itemsArr))
        itemsArr.Push({hwnd: hLbl, relY: yPos - groupBaseY})
    Gui, ShortcutsScroll:Font, s9 Norm c222222, Segoe UI
    if (btn2Text = "") {
        Gui, ShortcutsScroll:Add, Button, x320 y%btnY% w210 h26 Center +HwndhBtn1 g%gLabel1%, %btn1Text%
        if (IsObject(itemsArr))
            itemsArr.Push({hwnd: hBtn1, relY: btnY - groupBaseY})
    } else {
        Gui, ShortcutsScroll:Add, Button, x320 y%btnY% w102 h26 Center +HwndhBtn1 g%gLabel1%, %btn1Text%
        Gui, ShortcutsScroll:Add, Button, x428 y%btnY% w102 h26 Center +HwndhBtn2 g%gLabel2%, %btn2Text%
        if (IsObject(itemsArr)) {
            itemsArr.Push({hwnd: hBtn1, relY: btnY - groupBaseY})
            itemsArr.Push({hwnd: hBtn2, relY: btnY - groupBaseY})
        }
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

    GuiControl, ShortcutsScroll:, AOTEnabled, %AOTEnabled%
    GuiControl, ShortcutsScroll:, AOTBorderEnabled, %AOTBorderEnabled%
    if (IsFunc("FormatAOTHotkeyText"))
        GuiControl, ShortcutsScroll:, AOTHotkeyBtn, % FormatAOTHotkeyText(AOTHotkey)
    GuiControl, ShortcutsScroll:Enable%AOTEnabled%, AOTHotkeyBtn
    GuiControl, ShortcutsScroll:Enable%AOTEnabled%, AOTBorderEnabled
    GuiControl, ShortcutsScroll:Enable%AOTEnabled%, AOTUnpinAllBtn

    SyncMicControlsFromState()
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
    global currentSettingsTab, hSettingsGui, hShortcutsScroll, SidebarNavBitmaps, SidebarIconHwnds
    ClearSettingsTooltip()
    currentSettingsTab := tabNum
    if (!hSettingsGui)
        return
    Gui, Settings:Default
    GuiControl, Settings:Choose, SettingsTabNav, %tabNum%
    if (hShortcutsScroll) {
        if (tabNum = 4) {
            SyncShortcutsScrollPanelSize()
            DllCall("SetWindowPos", "Ptr", hShortcutsScroll, "Ptr", 0, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0053) ; HWND_TOP|SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE|SWP_SHOWWINDOW
            UpdateShortcutsScrollInfo()
            DllCall("RedrawWindow", "Ptr", hShortcutsScroll, "Ptr", 0, "Ptr", 0, "UInt", 0x0185)
        } else {
            DllCall("ShowWindow", "Ptr", hShortcutsScroll, "Int", 0) ; SW_HIDE
        }
    }
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
    Gui, ShortcutsScroll:Submit, NoHide
    AOTEnabled := AOTEnabled ? 1 : 0
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AOTEnabled, %AOTEnabled%
    GuiControl, ShortcutsScroll:Enable%AOTEnabled%, AOTHotkeyBtn
    GuiControl, ShortcutsScroll:Enable%AOTEnabled%, AOTBorderEnabled
    GuiControl, ShortcutsScroll:Enable%AOTEnabled%, AOTUnpinAllBtn
    if (IsFunc("ApplyAOTHotkey"))
        ApplyAOTHotkey()
    if (!AOTEnabled && IsFunc("UnpinAllAlwaysOnTop"))
        UnpinAllAlwaysOnTop()
return

OnToggleAOTBorder:
    Gui, ShortcutsScroll:Submit, NoHide
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
    global AOTNewKeyCtrl

    if (hAOTHotkeyGui && WinExist("ahk_id " . hAOTHotkeyGui)) {
        WinActivate, ahk_id %hAOTHotkeyGui%
        return
    }

    ; Tạm tắt phím tắt hiện tại để có thể bấm chính tổ hợp đó vào ô nhập
    if (AOTHotkey != "")
        try Hotkey, %AOTHotkey%, ToggleAlwaysOnTopLabel, Off

    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui))
        Gui, Settings:+Disabled

    ownerOpt := (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) ? "+Owner" . hSettingsGui : ""
    Gui, AOTHotkeyDlg:New, -MaximizeBox -MinimizeBox %ownerOpt% +HwndhAOTHotkeyGui, % L("AOT_ChangeHotkeyBtn")
    if (IsFunc("SetGuiYellowIcon"))
        SetGuiYellowIcon(hAOTHotkeyGui)
    Gui, AOTHotkeyDlg:Color, FFFFFF
    Gui, AOTHotkeyDlg:Font, s9.5 Norm c222222, Segoe UI
    Gui, AOTHotkeyDlg:Add, Hotkey, x16 y16 w280 h26 vAOTNewKeyCtrl, %AOTHotkey%
    Gui, AOTHotkeyDlg:Add, Button, x16 y52 w68 h26 Default gOnSaveAOTHotkey, OK
    Gui, AOTHotkeyDlg:Add, Button, x90 y52 w104 h26 gOnResetAOTHotkey, Ctrl + Alt + T
    Gui, AOTHotkeyDlg:Add, Button, x228 y52 w68 h26 gAOTHotkeyDlgGuiClose, % L("Set_Close")
    Gui, AOTHotkeyDlg:Show, w312 h90 Center
}

OnResetAOTHotkey:
    GuiControl, AOTHotkeyDlg:, AOTNewKeyCtrl, ^!t
return

OnSaveAOTHotkey:
    Gui, AOTHotkeyDlg:Submit, NoHide
    if (AOTNewKeyCtrl = "")
        return
    AOTHotkey := AOTNewKeyCtrl
    RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AOTHotkey, %AOTHotkey%
    if (IsFunc("FormatAOTHotkeyText"))
        GuiControl, ShortcutsScroll:, AOTHotkeyBtn, % FormatAOTHotkeyText(AOTHotkey)
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
    if (IsFunc("ApplyAOTHotkey"))
        ApplyAOTHotkey()
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

; ========================================================
; RESIZE CỬA SỔ SETTINGS & VÙNG CUỘN DỌC TAB PHÍM TẮT
; ========================================================
SettingsGuiSize:
    if (A_EventInfo = 1) ; Đang thu nhỏ (Minimize)
        return
    HandleSettingsGuiResize(A_GuiWidth, A_GuiHeight)
return

HandleSettingsGuiResize(guiW, guiH) {
    global hSettingsGui, hSettingsSep, hSettingsTabNav, hShortcutsScroll, currentSettingsTab
    if (!hSettingsGui)
        return

    sepH := (guiH > 28) ? (guiH - 28) : 10
    if (hSettingsSep)
        GuiControl, Settings:MoveDraw, %hSettingsSep%, % "h" . sepH

    tabW := (guiW > 216) ? (guiW - 216) : 100
    tabH := (guiH > 16) ? (guiH - 16) : 100
    if (hSettingsTabNav)
        GuiControl, Settings:Move, %hSettingsTabNav%, % "w" . tabW . " h" . tabH

    hintY := guiH - 37
    btnY := guiH - 44
    btnX := guiW - 122
    hintW := (btnX - 240 > 120) ? (btnX - 240) : 120
    GuiControl, Settings:MoveDraw, SettingsAutoSaveHint, % "y" . hintY . " w" . hintW
    GuiControl, Settings:MoveDraw, SettingsCloseBtn, % "x" . btnX . " y" . btnY

    if (hShortcutsScroll) {
        SyncShortcutsScrollPanelSize()
        if (currentSettingsTab = 4)
            UpdateShortcutsScrollInfo()
    }
}

SyncShortcutsScrollPanelSize() {
    global hSettingsGui, hShortcutsScroll
    if (!hSettingsGui || !hShortcutsScroll)
        return
    VarSetCapacity(rc, 16, 0)
    DllCall("GetClientRect", "Ptr", hSettingsGui, "Ptr", &rc)
    clientW := NumGet(rc, 8, "Int")
    clientH := NumGet(rc, 12, "Int")
    scale := A_ScreenDPI / 96.0
    if (clientW <= 0 || clientH <= 0) {
        clientW := Round(780 * scale)
        clientH := Round(455 * scale)
    }
    leftPx := Round(216 * scale)
    bottomMarginPx := Round(48 * scale)
    panelW := (clientW > leftPx) ? (clientW - leftPx) : Round(564 * scale)
    panelH := (clientH > bottomMarginPx) ? (clientH - bottomMarginPx) : Round(407 * scale)
    DllCall("SetWindowPos", "Ptr", hShortcutsScroll, "Ptr", 0, "Int", leftPx, "Int", 0, "Int", panelW, "Int", panelH, "UInt", 0x0010) ; HWND_TOP|SWP_NOACTIVATE
}

BuildShortcutsScrollPanel(aboutIcon) {
    global
    sysExpanded := 1
    micExpanded := 0
    aotExpanded := 1
    trayExpanded := 1
    shortcutsScrollPos := 0
    SysGroupItems := []
    MicGroupItems := []
    AotGroupItems := []
    TrayGroupItems := []

    Gui, ShortcutsScroll:New, -Caption +0x40000000 +0x04000000 +0x200000 +Parent%hSettingsGui% +HwndhShortcutsScroll
    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI

    ; Tiêu đề Tab 4
    Gui, ShortcutsScroll:Font, s13 Bold c004499, Segoe UI
    Gui, ShortcutsScroll:Add, Text, x12 y12 w536, % L("Set_HeaderShortcuts")
    Gui, ShortcutsScroll:Font, s8.5 Norm c666666, Segoe UI
    Gui, ShortcutsScroll:Add, Text, x12 y35 w536, % L("Set_SubShortcuts")

    ; --------------------------------------------------------
    ; ACCORDION 1: PHÍM TẮT HỆ THỐNG (MẶC ĐỊNH MỞ)
    ; --------------------------------------------------------
    Gui, ShortcutsScroll:Font, s9.5 Bold c222222, Segoe UI
    Gui, ShortcutsScroll:Add, GroupBox, x12 y54 w536 h202 vSysGroupBox
    Gui, ShortcutsScroll:Add, Text, x20 y52 w260 h18 vSysHeaderTxt gOnToggleSysExpand, % " ▾  " . L("Set_GroupSystemHotkeys") . " "

    AddShortcutRow(76,  "Icon28",  A_WinDir . "\System32\ddores.dll",  "Set_LockCenter", "Ctrl + Alt + L",     "ActionOpenLockCenter", "", "", SysGroupItems, 54)
    AddShortcutRow(104, "Icon261", A_WinDir . "\System32\shell32.dll", "Set_PastePlain", "Ctrl + Shift + V",   "ActionPastePlain", "", "", SysGroupItems, 54)
    Gui, ShortcutsScroll:Font, s8.5 Norm c666666, Segoe UI
    Gui, ShortcutsScroll:Add, Text, x58 y126 w472 h18 +HwndhSysPasteDesc, % L("Set_PastePlainDesc")
    SysGroupItems.Push({hwnd: hSysPasteDesc, relY: 126 - 54})
    AddShortcutRow(148, "Icon3",   A_WinDir . "\System32\SndVol.exe",  "Set_Mute",       "Ctrl + Shift + M",   "ActionMute", "", "", SysGroupItems, 54)
    AddShortcutRow(176, "Icon2",   A_WinDir . "\System32\SndVol.exe",  "Set_Volume",     L("Set_VolUpBtn"),    "ActionVolUp",     L("Set_VolDownBtn"), "ActionVolDown", SysGroupItems, 54)
    AddShortcutRow(204, "Icon26",  A_WinDir . "\System32\shell32.dll", "Set_Brightness", L("Set_BrightDownBtn"), "ActionBrightDown", L("Set_BrightUpBtn"), "ActionBrightUp", SysGroupItems, 54)

    Gui, ShortcutsScroll:Font, s8.5 Norm c666666, Segoe UI
    Gui, ShortcutsScroll:Add, Text, x30 y235 w500 h18 +HwndhSysTip, % L("Set_ShortcutsTip")
    SysGroupItems.Push({hwnd: hSysTip, relY: 235 - 54})

    ; --------------------------------------------------------
    ; ACCORDION 2: MICROPHONE (MẶC ĐỊNH THU GỌN)
    ; --------------------------------------------------------
    micBaseY := 264
    Gui, ShortcutsScroll:Font, s9.5 Bold c222222, Segoe UI
    Gui, ShortcutsScroll:Add, GroupBox, x12 y%micBaseY% w536 h54 vMicGroupBox
    Gui, ShortcutsScroll:Add, Text, x20 y262 w280 h18 vMicHeaderTxt gOnToggleMicExpand, % " ▸  " . L("Set_GroupMic") . " "

    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Checkbox, x30 y285 w496 h22 vMicMuteEnabled gOnToggleMicMuteEnabled Checked%MicMuteEnabled%, % L("Mic_EnableChk")

    ; Phần mở rộng 1 cột của Card Microphone (tọa độ tương đối so với micBaseY = 264)
    Gui, ShortcutsScroll:Add, Text, x30 y316 w502 h1 0x10 +HwndhMicDiv Hidden
    MicGroupItems.Push({hwnd: hMicDiv, relY: 316 - micBaseY})

    Gui, ShortcutsScroll:Font, s9 Bold c005FB8, Segoe UI
    Gui, ShortcutsScroll:Add, Text, x30 y326 w502 h18 +HwndhMicSecMode Hidden, % L("Mic_SecHotkeys")
    MicGroupItems.Push({hwnd: hMicSecMode, relY: 326 - micBaseY})

    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Text, x38 y352 w212 h20 +HwndhMicToggleLbl Hidden, % L("Mic_ToggleHkLbl")
    micHkDisplay := IsFunc("FormatMicHotkeyText") ? FormatMicHotkeyText(MicMuteHotkey) : "Win + Alt + M"
    Gui, ShortcutsScroll:Font, s9 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Button, x256 y348 w278 h26 vMicHotkeyBtn +HwndhMicToggleBtn gOnChangeMicToggleHotkey Hidden, %micHkDisplay%
    MicGroupItems.Push({hwnd: hMicToggleLbl, relY: 352 - micBaseY})
    MicGroupItems.Push({hwnd: hMicToggleBtn, relY: 348 - micBaseY})

    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Text, x38 y384 w212 h20 +HwndhMicPttLbl Hidden, % L("Mic_PttHkLbl")
    pttHkDisplay := IsFunc("FormatMicHotkeyText") ? FormatMicHotkeyText(MicPttHotkey) : "Right Ctrl"
    Gui, ShortcutsScroll:Font, s9 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Button, x256 y380 w278 h26 vMicPttHotkeyBtn +HwndhMicPttBtn gOnChangeMicPttHotkey Hidden, %pttHkDisplay%
    MicGroupItems.Push({hwnd: hMicPttLbl, relY: 384 - micBaseY})
    MicGroupItems.Push({hwnd: hMicPttBtn, relY: 380 - micBaseY})

    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Checkbox, x38 y412 w494 h22 vMicPttInvert +HwndhMicPttInv gOnSaveMicSettings Checked%MicPttInvert% Hidden, % L("Mic_PttInvertChk")
    Gui, ShortcutsScroll:Font, s8.5 Norm c666666, Segoe UI
    Gui, ShortcutsScroll:Add, Text, x58 y434 w474 h18 +HwndhMicPttInvDesc Hidden, % L("Mic_PttInvertDesc")
    MicGroupItems.Push({hwnd: hMicPttInv, relY: 412 - micBaseY})
    MicGroupItems.Push({hwnd: hMicPttInvDesc, relY: 434 - micBaseY})

    Gui, ShortcutsScroll:Font, s9 Norm c555555, Segoe UI
    Gui, ShortcutsScroll:Add, Text, x38 y461 w214 h18 +HwndhMicDelayLbl Hidden, % L("Mic_DelayLbl")
    Gui, ShortcutsScroll:Font, s9 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Edit, x258 y458 w72 h22 Number vMicReleaseDelayInput +HwndhMicDelayEdit gOnChangeMicDelay Hidden, %MicMuteReleaseDelay%
    Gui, ShortcutsScroll:Add, UpDown, Range0-2000 vMicReleaseDelayUpDown +HwndhMicDelayUD Hidden, %MicMuteReleaseDelay%
    Gui, ShortcutsScroll:Font, s8.5 Norm c666666, Segoe UI
    Gui, ShortcutsScroll:Add, Text, x336 y461 w120 h18 +HwndhMicDelayUnit Hidden, (0 - 2000 ms)
    MicGroupItems.Push({hwnd: hMicDelayLbl,  relY: 461 - micBaseY})
    MicGroupItems.Push({hwnd: hMicDelayEdit, relY: 458 - micBaseY})
    MicGroupItems.Push({hwnd: hMicDelayUD,   relY: 458 - micBaseY})
    MicGroupItems.Push({hwnd: hMicDelayUnit, relY: 461 - micBaseY})

    Gui, ShortcutsScroll:Font, s9 Bold c005FB8, Segoe UI
    Gui, ShortcutsScroll:Add, Text, x30 y490 w502 h18 +HwndhMicSecDev Hidden, % L("Mic_SecDevice")
    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, DropDownList, x38 y513 w464 AltSubmit vMicDeviceChoice +HwndhMicDevDDL gOnSelectMicDevice Hidden, % L("Mic_DevAll")
    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Button, x506 y512 w28 h24 vMicRefreshDevBtn +HwndhMicDevRefresh gOnRefreshMicDevices Hidden, ↻
    Gui, ShortcutsScroll:Font, s8.5 Norm c666666, Segoe UI
    Gui, ShortcutsScroll:Add, Text, x38 y540 w492 h18 +HwndhMicAllDesc Hidden, % L("Mic_AllDevicesDesc")
    MicGroupItems.Push({hwnd: hMicSecDev,     relY: 490 - micBaseY})
    MicGroupItems.Push({hwnd: hMicDevDDL,     relY: 513 - micBaseY})
    MicGroupItems.Push({hwnd: hMicDevRefresh, relY: 512 - micBaseY})
    MicGroupItems.Push({hwnd: hMicAllDesc,    relY: 540 - micBaseY})

    Gui, ShortcutsScroll:Font, s9 Bold c005FB8, Segoe UI
    Gui, ShortcutsScroll:Add, Text, x30 y564 w502 h18 +HwndhMicSecOsd Hidden, % L("Mic_SecOsd")
    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Checkbox, x38 y586 w492 h22 vMicMuteBadgeEnabled +HwndhMicBadgeChk gOnToggleMicBadge Checked%MicMuteBadgeEnabled% Hidden, % L("Mic_BadgeChk")
    Gui, ShortcutsScroll:Add, Checkbox, x38 y610 w492 h22 vMicOsdEnabled +HwndhMicOsdChk gOnToggleMicOsd Checked%MicMuteOsdEnabled% Hidden, % L("Mic_OsdChk")
    MicGroupItems.Push({hwnd: hMicSecOsd,   relY: 564 - micBaseY})
    MicGroupItems.Push({hwnd: hMicBadgeChk, relY: 586 - micBaseY})
    MicGroupItems.Push({hwnd: hMicOsdChk,   relY: 610 - micBaseY})

    Gui, ShortcutsScroll:Font, s9 Norm c555555, Segoe UI
    Gui, ShortcutsScroll:Add, Text, x58 y637 w196 h18 +HwndhMicOsdDurLbl Hidden, % L("Mic_OsdDurLbl")
    Gui, ShortcutsScroll:Font, s9 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Edit, x258 y634 w72 h22 Number vMicOsdDurationInput +HwndhMicOsdEdit gOnChangeMicOsdDuration Hidden, %MicMuteOsdDuration%
    Gui, ShortcutsScroll:Add, UpDown, Range400-10000 vMicOsdDurationUpDown +HwndhMicOsdUD Hidden, %MicMuteOsdDuration%
    Gui, ShortcutsScroll:Add, Button, x340 y632 w116 h25 vMicTestOsdBtn +HwndhMicTestBtn gOnTestMicOsd Hidden, % L("Mic_TestOsdBtn")
    MicGroupItems.Push({hwnd: hMicOsdDurLbl, relY: 637 - micBaseY})
    MicGroupItems.Push({hwnd: hMicOsdEdit,   relY: 634 - micBaseY})
    MicGroupItems.Push({hwnd: hMicOsdUD,     relY: 634 - micBaseY})
    MicGroupItems.Push({hwnd: hMicTestBtn,   relY: 632 - micBaseY})

    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Checkbox, x38 y663 w492 h22 vMicBeepEnabled +HwndhMicBeepChk gOnSaveMicSettings Checked%MicMuteBeepEnabled% Hidden, % L("Mic_BeepChk")
    MicGroupItems.Push({hwnd: hMicBeepChk, relY: 663 - micBaseY})

    ; --------------------------------------------------------
    ; ACCORDION 3: GHIM CỬA SỔ LUÔN NỔI (MẶC ĐỊNH MỞ)
    ; --------------------------------------------------------
    aotBaseY := 326
    Gui, ShortcutsScroll:Font, s9.5 Bold c222222, Segoe UI
    Gui, ShortcutsScroll:Add, GroupBox, x12 y%aotBaseY% w536 h82 vAOTGroupBox
    Gui, ShortcutsScroll:Add, Text, x20 y324 w280 h18 vAotHeaderTxt gOnToggleAotExpand, % " ▾  " . L("Set_GroupAOT") . " "

    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Checkbox, x30 y347 w214 h22 vAOTEnabled +HwndhAotChk gOnToggleAOTEnabled Checked%AOTEnabled%, % L("AOT_EnableChk")
    Gui, ShortcutsScroll:Font, s9 Norm c555555, Segoe UI
    Gui, ShortcutsScroll:Add, Text, x248 y350 w56 h18 vAOTHotkeyLbl +HwndhAotHkLbl, % L("AOT_HotkeyLbl")
    Gui, ShortcutsScroll:Font, s9 Norm c222222, Segoe UI
    aotHkDisplay := IsFunc("FormatAOTHotkeyText") ? FormatAOTHotkeyText(AOTHotkey) : "Ctrl + Alt + T"
    Gui, ShortcutsScroll:Add, Button, x306 y345 w120 h25 vAOTHotkeyBtn +HwndhAotHkBtn gOnChangeAOTHotkey, %aotHkDisplay%
    Gui, ShortcutsScroll:Add, Button, x432 y345 w104 h25 vAOTUnpinAllBtn +HwndhAotUnpinBtn gOnUnpinAllAOT, % L("AOT_UnpinAllBtn")
    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Checkbox, x30 y375 w500 h22 vAOTBorderEnabled +HwndhAotBorderChk gOnToggleAOTBorder Checked%AOTBorderEnabled%, % L("AOT_BorderChk")
    AotGroupItems.Push({hwnd: hAotChk,       relY: 21})
    AotGroupItems.Push({hwnd: hAotHkLbl,     relY: 24})
    AotGroupItems.Push({hwnd: hAotHkBtn,     relY: 19})
    AotGroupItems.Push({hwnd: hAotUnpinBtn,  relY: 19})
    AotGroupItems.Push({hwnd: hAotBorderChk, relY: 49})

    ; --------------------------------------------------------
    ; ACCORDION 4: THAO TÁC NHANH TRÊN KHAY HỆ THỐNG (MẶC ĐỊNH MỞ)
    ; --------------------------------------------------------
    trayBaseY := 416
    Gui, ShortcutsScroll:Font, s9.5 Bold c222222, Segoe UI
    Gui, ShortcutsScroll:Add, GroupBox, x12 y%trayBaseY% w536 h64 vTrayGroupBox
    Gui, ShortcutsScroll:Add, Text, x20 y414 w280 h18 vTrayHeaderTxt gOnToggleTrayExpand, % " ▾  " . L("Set_GroupTrayActions") . " "

    if (aboutIcon != "" && FileExist(aboutIcon)) {
        Gui, ShortcutsScroll:Add, Picture, x30 y434 w20 h20 Icon1 vTrayToggleIco +HwndhTrayIco, %aboutIcon%
        TrayGroupItems.Push({hwnd: hTrayIco, relY: 18})
    }
    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Text, x58 y435 w256 vTrayToggleLbl +HwndhTrayLbl, % L("Set_TrayToggleLabel")
    Gui, ShortcutsScroll:Font, s9 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Button, x320 y431 w210 h26 Center gActionToggleGestures vTrayToggleBtn +HwndhTrayBtn, % L("Set_TrayToggleBtn")
    Gui, ShortcutsScroll:Font, s8.5 Norm c555555, Segoe UI
    Gui, ShortcutsScroll:Add, Text, x30 y458 w500 h16 vTrayDblClickLbl +HwndhTrayTip, % "• " . L("Set_TrayDblClickTip")
    TrayGroupItems.Push({hwnd: hTrayLbl, relY: 19})
    TrayGroupItems.Push({hwnd: hTrayBtn, relY: 15})
    TrayGroupItems.Push({hwnd: hTrayTip, relY: 42})

    Gui, ShortcutsScroll:Show, Hide x216 y0 w564 h407
    RefreshMicDeviceDropdown()
    LayoutShortcutsTab(true)
}

LayoutShortcutsTab(resetScroll := false) {
    global hShortcutsScroll, sysExpanded, micExpanded, aotExpanded, trayExpanded
    global SysGroupItems, MicGroupItems, AotGroupItems, TrayGroupItems
    global shortcutsScrollPos, shortcutsContentH
    if (!hShortcutsScroll)
        return

    if (resetScroll && shortcutsScrollPos != 0)
        ScrollShortcutsTo(0)

    DllCall("SendMessage", "Ptr", hShortcutsScroll, "UInt", 0x000B, "Ptr", 0, "Ptr", 0) ; WM_SETREDRAW = FALSE

    off := shortcutsScrollPos
    curY := 54

    ; 1. System Shortcuts
    sysH := sysExpanded ? 202 : 28
    GuiControl, ShortcutsScroll:Move, SysGroupBox, % "y" . (curY - off) . " h" . sysH
    GuiControl, ShortcutsScroll:Move, SysHeaderTxt, % "y" . (curY - 2 - off)
    GuiControl, ShortcutsScroll:, SysHeaderTxt, % (sysExpanded ? " ▾  " : " ▸  ") . L("Set_GroupSystemHotkeys") . " "
    ApplyAccordionGroupLayout(SysGroupItems, curY, off, sysExpanded)
    curY += sysH + 8

    ; 2. Microphone
    micH := micExpanded ? 432 : 54
    GuiControl, ShortcutsScroll:Move, MicGroupBox,    % "y" . (curY - off) . " h" . micH
    GuiControl, ShortcutsScroll:Move, MicHeaderTxt,   % "y" . (curY - 2 - off)
    GuiControl, ShortcutsScroll:, MicHeaderTxt, % (micExpanded ? " ▾  " : " ▸  ") . L("Set_GroupMic") . " "
    GuiControl, ShortcutsScroll:Move, MicMuteEnabled, % "y" . (curY + 21 - off)
    ApplyAccordionGroupLayout(MicGroupItems, curY, off, micExpanded)
    curY += micH + 8

    ; 3. Always On Top
    aotH := aotExpanded ? 82 : 28
    GuiControl, ShortcutsScroll:Move, AOTGroupBox,  % "y" . (curY - off) . " h" . aotH
    GuiControl, ShortcutsScroll:Move, AotHeaderTxt, % "y" . (curY - 2 - off)
    GuiControl, ShortcutsScroll:, AotHeaderTxt, % (aotExpanded ? " ▾  " : " ▸  ") . L("Set_GroupAOT") . " "
    ApplyAccordionGroupLayout(AotGroupItems, curY, off, aotExpanded)
    curY += aotH + 8

    ; 4. Tray Actions
    trayH := trayExpanded ? 64 : 28
    GuiControl, ShortcutsScroll:Move, TrayGroupBox,  % "y" . (curY - off) . " h" . trayH
    GuiControl, ShortcutsScroll:Move, TrayHeaderTxt, % "y" . (curY - 2 - off)
    GuiControl, ShortcutsScroll:, TrayHeaderTxt, % (trayExpanded ? " ▾  " : " ▸  ") . L("Set_GroupTrayActions") . " "
    ApplyAccordionGroupLayout(TrayGroupItems, curY, off, trayExpanded)
    curY += trayH + 12

    shortcutsContentH := curY

    DllCall("SendMessage", "Ptr", hShortcutsScroll, "UInt", 0x000B, "Ptr", 1, "Ptr", 0) ; WM_SETREDRAW = TRUE
    DllCall("RedrawWindow", "Ptr", hShortcutsScroll, "Ptr", 0, "Ptr", 0, "UInt", 0x0185) ; RDW_INVALIDATE|RDW_ERASE|RDW_ALLCHILDREN|RDW_UPDATENOW

    UpdateShortcutsScrollInfo()
}

ApplyAccordionGroupLayout(itemsArr, groupY, scrollOff, isExpanded) {
    showFlag := isExpanded ? 5 : 0 ; SW_SHOW : SW_HIDE
    for _, item in itemsArr {
        DllCall("ShowWindow", "Ptr", item.hwnd, "Int", showFlag)
        if (isExpanded)
            GuiControl, ShortcutsScroll:Move, % item.hwnd, % "y" . (groupY + item.relY - scrollOff)
    }
}

OnToggleSysExpand:
    sysExpanded := !sysExpanded
    LayoutShortcutsTab(false)
return

OnToggleAotExpand:
    aotExpanded := !aotExpanded
    LayoutShortcutsTab(false)
return

OnToggleTrayExpand:
    trayExpanded := !trayExpanded
    LayoutShortcutsTab(false)
return

UpdateShortcutsScrollInfo() {
    global hShortcutsScroll, shortcutsContentH, shortcutsScrollPos
    if (!hShortcutsScroll)
        return

    VarSetCapacity(rc, 16, 0)
    DllCall("GetClientRect", "Ptr", hShortcutsScroll, "Ptr", &rc)
    viewH := NumGet(rc, 12, "Int")
    if (viewH <= 0)
        return

    scale := A_ScreenDPI / 96.0
    totalPx := Round(shortcutsContentH * scale)
    maxScrollPx := (totalPx > viewH) ? (totalPx - viewH) : 0
    maxScrollLogical := Round(maxScrollPx / scale)

    if (shortcutsScrollPos > maxScrollLogical)
        ScrollShortcutsTo(maxScrollLogical)

    posPx := Round(shortcutsScrollPos * scale)
    VarSetCapacity(si, 28, 0)
    NumPut(28, si, 0, "UInt")
    NumPut(0x17, si, 4, "UInt") ; SIF_ALL
    NumPut(0, si, 8, "Int")
    NumPut(totalPx > 0 ? totalPx - 1 : 0, si, 12, "Int")
    NumPut(viewH, si, 16, "UInt")
    NumPut(posPx, si, 20, "Int")
    DllCall("SetScrollInfo", "Ptr", hShortcutsScroll, "Int", 1, "Ptr", &si, "Int", 1) ; SB_VERT = 1
}

ScrollShortcutsTo(newLogicalPos) {
    global hShortcutsScroll, shortcutsContentH, shortcutsScrollPos
    if (!hShortcutsScroll)
        return

    VarSetCapacity(rc, 16, 0)
    DllCall("GetClientRect", "Ptr", hShortcutsScroll, "Ptr", &rc)
    viewH := NumGet(rc, 12, "Int")
    scale := A_ScreenDPI / 96.0
    totalPx := Round(shortcutsContentH * scale)
    maxLogical := (totalPx > viewH) ? Round((totalPx - viewH) / scale) : 0

    if (newLogicalPos < 0)
        newLogicalPos := 0
    if (newLogicalPos > maxLogical)
        newLogicalPos := maxLogical

    if (newLogicalPos = shortcutsScrollPos)
        return

    oldPx := Round(shortcutsScrollPos * scale)
    newPx := Round(newLogicalPos * scale)
    deltaPx := oldPx - newPx
    shortcutsScrollPos := newLogicalPos

    DllCall("ScrollWindowEx", "Ptr", hShortcutsScroll, "Int", 0, "Int", deltaPx, "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr", 0, "UInt", 0x0007) ; SW_SCROLLCHILDREN|SW_INVALIDATE|SW_ERASE
    DllCall("RedrawWindow", "Ptr", hShortcutsScroll, "Ptr", 0, "Ptr", 0, "UInt", 0x0185) ; RDW_INVALIDATE|RDW_ERASE|RDW_ALLCHILDREN|RDW_UPDATENOW

    VarSetCapacity(si, 28, 0)
    NumPut(28, si, 0, "UInt")
    NumPut(0x04, si, 4, "UInt") ; SIF_POS
    NumPut(newPx, si, 20, "Int")
    DllCall("SetScrollInfo", "Ptr", hShortcutsScroll, "Int", 1, "Ptr", &si, "Int", 1)
}

OnShortcutsVScroll(wParam, lParam, msg, hwnd) {
    global hShortcutsScroll, shortcutsScrollPos, shortcutsContentH
    if (!hShortcutsScroll || hwnd != hShortcutsScroll)
        return

    sbCode := wParam & 0xFFFF
    scale := A_ScreenDPI / 96.0
    VarSetCapacity(rc, 16, 0)
    DllCall("GetClientRect", "Ptr", hShortcutsScroll, "Ptr", &rc)
    pageLogical := Round(NumGet(rc, 12, "Int") / scale)

    newPos := shortcutsScrollPos
    if (sbCode = 0)        ; SB_LINEUP
        newPos -= 24
    else if (sbCode = 1)   ; SB_LINEDOWN
        newPos += 24
    else if (sbCode = 2)   ; SB_PAGEUP
        newPos -= pageLogical
    else if (sbCode = 3)   ; SB_PAGEDOWN
        newPos += pageLogical
    else if (sbCode = 4 || sbCode = 5) { ; SB_THUMBPOSITION / SB_THUMBTRACK
        VarSetCapacity(si, 28, 0)
        NumPut(28, si, 0, "UInt")
        NumPut(0x10, si, 4, "UInt") ; SIF_TRACKPOS
        DllCall("GetScrollInfo", "Ptr", hShortcutsScroll, "Int", 1, "Ptr", &si)
        trackPx := NumGet(si, 24, "Int")
        newPos := Round(trackPx / scale)
    } else {
        return
    }
    ScrollShortcutsTo(newPos)
    return 0
}

OnShortcutsMouseWheel(wParam, lParam, msg, hwnd) {
    global hShortcutsScroll, shortcutsScrollPos, currentSettingsTab
    if (!hShortcutsScroll || currentSettingsTab != 4)
        return
    if (hwnd != hShortcutsScroll && !DllCall("IsChild", "Ptr", hShortcutsScroll, "Ptr", hwnd))
        return

    delta := (wParam >> 16) & 0xFFFF
    if (delta > 0x7FFF)
        delta -= 0x10000
    step := (delta > 0) ? -45 : 45
    ScrollShortcutsTo(shortcutsScrollPos + step)
    return 0
}

; ========================================================
; CÀI ĐẶT MICROPHONE (MỞ RỘNG ACCORDION & BẮT PHÍM TẮT)
; ========================================================
OnToggleMicExpand:
    micExpanded := !micExpanded
    LayoutShortcutsTab(false)
return

OnToggleMicMuteEnabled:
    Gui, ShortcutsScroll:Submit, NoHide
    MicMuteEnabled := MicMuteEnabled ? 1 : 0
    if (IsFunc("SaveMicMuteSettings"))
        SaveMicMuteSettings()
    if (IsFunc("ApplyMicMuteHotkey"))
        ApplyMicMuteHotkey()
    if (IsFunc("UpdateMicBadge"))
        UpdateMicBadge()
    if (IsFunc("SyncMicBadgeTimer"))
        SyncMicBadgeTimer()
    UpdateMicControlsState()
return

OnChangeMicDelay:
    Gui, ShortcutsScroll:Submit, NoHide
    val := MicReleaseDelayInput + 0
    if (val < 0)
        val := 0
    else if (val > 2000)
        val := 2000
    MicMuteReleaseDelay := val
    if (IsFunc("SaveMicMuteSettings"))
        SaveMicMuteSettings()
return

OnToggleMicBadge:
    Gui, ShortcutsScroll:Submit, NoHide
    MicMuteBadgeEnabled := MicMuteBadgeEnabled ? 1 : 0
    if (IsFunc("SaveMicMuteSettings"))
        SaveMicMuteSettings()
    if (IsFunc("UpdateMicBadge"))
        UpdateMicBadge()
    if (IsFunc("SyncMicBadgeTimer"))
        SyncMicBadgeTimer()
return

OnToggleMicOsd:
    Gui, ShortcutsScroll:Submit, NoHide
    MicMuteOsdEnabled := MicMuteOsdEnabled ? 1 : 0
    if (IsFunc("SaveMicMuteSettings"))
        SaveMicMuteSettings()
    UpdateMicControlsState()
return

OnChangeMicOsdDuration:
    Gui, ShortcutsScroll:Submit, NoHide
    val := MicOsdDurationInput + 0
    if (val < 400)
        val := 400
    else if (val > 10000)
        val := 10000
    MicMuteOsdDuration := val
    if (IsFunc("SaveMicMuteSettings"))
        SaveMicMuteSettings()
return

OnTestMicOsd:
    if (IsFunc("ShowMicMuteOsd")) {
        curMuted := IsFunc("GetMicMuteState") ? GetMicMuteState() : 1
        ShowMicMuteOsd(curMuted = 0 ? false : true)
    }
return

OnSaveMicSettings:
    Gui, ShortcutsScroll:Submit, NoHide
    MicPttInvert := MicPttInvert ? 1 : 0
    MicMuteBeepEnabled := MicMuteBeepEnabled ? 1 : 0
    if (IsFunc("SaveMicMuteSettings"))
        SaveMicMuteSettings()
return

OnSelectMicDevice:
    Gui, ShortcutsScroll:Submit, NoHide
    if (IsObject(MicDeviceIdList) && MicDeviceChoice >= 1 && MicDeviceChoice <= MicDeviceIdList.Length()) {
        selId := MicDeviceIdList[MicDeviceChoice]
        if (selId = "__ALL__") {
            MicMuteAllDevices := 1
            MicTargetDeviceId := ""
        } else if (selId = "__DEFAULT__") {
            MicMuteAllDevices := 0
            MicTargetDeviceId := ""
        } else {
            MicMuteAllDevices := 0
            MicTargetDeviceId := selId
        }
        if (IsFunc("SaveMicMuteSettings"))
            SaveMicMuteSettings()
        if (IsFunc("UpdateMicBadge"))
            UpdateMicBadge()
    }
return

OnRefreshMicDevices:
    RefreshMicDeviceDropdown()
return

RefreshMicDeviceDropdown() {
    global MicDeviceIdList, MicMuteAllDevices, MicTargetDeviceId, CurrentLang
    MicDeviceIdList := ["__ALL__", "__DEFAULT__"]
    listStr := L("Mic_DevAll") . "|" . L("Mic_DevDefault")
    selIdx := MicMuteAllDevices ? 1 : 2

    if (IsFunc("GetCaptureDevices")) {
        devs := GetCaptureDevices()
        defTag := (CurrentLang = "en") ? " (Default)" : " (Mặc định)"
        for _, d in devs {
            cleanName := StrReplace(d.name, "|", "-")
            dispName := d.isDefault ? (cleanName . defTag) : cleanName
            listStr .= "|" . dispName
            MicDeviceIdList.Push(d.id)
            if (!MicMuteAllDevices && MicTargetDeviceId != "" && d.id = MicTargetDeviceId)
                selIdx := MicDeviceIdList.Length()
        }
    }

    GuiControl, ShortcutsScroll:, MicDeviceChoice, |%listStr%
    GuiControl, ShortcutsScroll:Choose, MicDeviceChoice, %selIdx%
}

UpdateMicControlsState() {
    global MicMuteEnabled, MicMuteOsdEnabled
    en := MicMuteEnabled ? 1 : 0
    osdEn := (en && MicMuteOsdEnabled) ? 1 : 0

    GuiControl, ShortcutsScroll:Enable%en%, MicHotkeyBtn
    GuiControl, ShortcutsScroll:Enable%en%, MicPttHotkeyBtn
    GuiControl, ShortcutsScroll:Enable%en%, MicPttInvert
    GuiControl, ShortcutsScroll:Enable%en%, MicReleaseDelayInput
    GuiControl, ShortcutsScroll:Enable%en%, MicReleaseDelayUpDown
    GuiControl, ShortcutsScroll:Enable%en%, MicDeviceChoice
    GuiControl, ShortcutsScroll:Enable%en%, MicRefreshDevBtn
    GuiControl, ShortcutsScroll:Enable%en%, MicMuteBadgeEnabled
    GuiControl, ShortcutsScroll:Enable%en%, MicOsdEnabled
    GuiControl, ShortcutsScroll:Enable%en%, MicBeepEnabled

    GuiControl, ShortcutsScroll:Enable%osdEn%, MicOsdDurationInput
    GuiControl, ShortcutsScroll:Enable%osdEn%, MicOsdDurationUpDown
    GuiControl, ShortcutsScroll:Enable%osdEn%, MicTestOsdBtn
}

SyncMicControlsFromState() {
    global MicMuteEnabled, MicMuteHotkey, MicPttHotkey, MicPttInvert
    global MicMuteReleaseDelay, MicMuteBadgeEnabled, MicMuteOsdEnabled, MicMuteOsdDuration, MicMuteBeepEnabled

    GuiControl, ShortcutsScroll:, MicMuteEnabled, %MicMuteEnabled%
    if (IsFunc("FormatMicHotkeyText")) {
        GuiControl, ShortcutsScroll:, MicHotkeyBtn, % FormatMicHotkeyText(MicMuteHotkey)
        GuiControl, ShortcutsScroll:, MicPttHotkeyBtn, % FormatMicHotkeyText(MicPttHotkey)
    }
    GuiControl, ShortcutsScroll:, MicPttInvert, %MicPttInvert%
    GuiControl, ShortcutsScroll:, MicReleaseDelayInput, %MicMuteReleaseDelay%
    RefreshMicDeviceDropdown()
    GuiControl, ShortcutsScroll:, MicMuteBadgeEnabled, %MicMuteBadgeEnabled%
    GuiControl, ShortcutsScroll:, MicOsdEnabled, %MicMuteOsdEnabled%
    GuiControl, ShortcutsScroll:, MicOsdDurationInput, %MicMuteOsdDuration%
    GuiControl, ShortcutsScroll:, MicBeepEnabled, %MicMuteBeepEnabled%
    UpdateMicControlsState()
}

OnChangeMicToggleHotkey:
    ShowMicHotkeyDialog("toggle")
return

OnChangeMicPttHotkey:
    ShowMicHotkeyDialog("ptt")
return

ShowMicHotkeyDialog(targetMode := "toggle") {
    global MicMuteHotkey, MicPttHotkey, MicMuteRegToggleHk, MicMuteRegPttDownHk, MicMuteRegPttUpHk
    global hSettingsGui, hMicHotkeyDlg, MicHotkeyCaptured, MicHotkeyCapturing, MicHotkeyPreview
    global MicHotkeyTargetMode, MicHotkeyPendingMod

    if (hMicHotkeyDlg && WinExist("ahk_id " . hMicHotkeyDlg)) {
        WinActivate, ahk_id %hMicHotkeyDlg%
        return
    }

    if (MicMuteRegToggleHk != "")
        try Hotkey, %MicMuteRegToggleHk%, MicToggleKeyHandler, Off
    if (MicMuteRegPttDownHk != "")
        try Hotkey, %MicMuteRegPttDownHk%, MicPttKeyDownHandler, Off
    if (MicMuteRegPttUpHk != "")
        try Hotkey, %MicMuteRegPttUpHk%, MicPttKeyUpHandler, Off

    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui))
        Gui, Settings:+Disabled

    MicHotkeyTargetMode := targetMode
    MicHotkeyCaptured := (targetMode = "ptt") ? MicPttHotkey : MicMuteHotkey
    MicHotkeyPendingMod := ""
    MicHotkeyCapturing := true

    ownerOpt := (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) ? "+Owner" . hSettingsGui : ""
    Gui, MicHotkeyDlg:New, -MaximizeBox -MinimizeBox %ownerOpt% +HwndhMicHotkeyDlg, % L("Mic_HotkeyDlgTitle")
    if (IsFunc("SetGuiYellowIcon"))
        SetGuiYellowIcon(hMicHotkeyDlg)
    Gui, MicHotkeyDlg:Color, FFFFFF
    Gui, MicHotkeyDlg:Font, s9 Norm c555555, Segoe UI
    promptTxt := (targetMode = "ptt") ? L("Mic_PttPrompt") : L("Mic_HotkeyPrompt")
    Gui, MicHotkeyDlg:Add, Text, x16 y12 w368 h32, %promptTxt%
    Gui, MicHotkeyDlg:Font, s10.5 Bold c005FB8, Segoe UI
    disp := IsFunc("FormatMicHotkeyText") ? FormatMicHotkeyText(MicHotkeyCaptured) : MicHotkeyCaptured
    Gui, MicHotkeyDlg:Add, Edit, x16 y48 w368 h28 ReadOnly Center vMicHotkeyPreview, %disp%
    Gui, MicHotkeyDlg:Font, s9.5 Norm c222222, Segoe UI
    Gui, MicHotkeyDlg:Add, Button, x16 y86 w82 h26 Default gOnSaveMicHotkey, OK
    Gui, MicHotkeyDlg:Add, Button, x104 y86 w132 h26 gOnResetMicHotkey, % L("Mic_ResetBtn")
    Gui, MicHotkeyDlg:Add, Button, x302 y86 w82 h26 gMicHotkeyDlgGuiClose, % L("Set_Close")
    Gui, MicHotkeyDlg:Show, w400 h124 Center

    OnMessage(0x100, "OnMicHotkeyDlgKeyDown")    ; WM_KEYDOWN
    OnMessage(0x104, "OnMicHotkeyDlgKeyDown")    ; WM_SYSKEYDOWN
    OnMessage(0x101, "OnMicHotkeyDlgKeyUp")      ; WM_KEYUP
    OnMessage(0x105, "OnMicHotkeyDlgKeyUp")      ; WM_SYSKEYUP
    OnMessage(0x207, "OnMicHotkeyDlgMouseBtn")   ; WM_MBUTTONDOWN
    OnMessage(0x20B, "OnMicHotkeyDlgMouseBtn")   ; WM_XBUTTONDOWN
}

GetSideModifierName(wParam, lParam) {
    isExt := (lParam >> 24) & 1
    if (wParam = 17) ; VK_CONTROL
        return isExt ? "RCtrl" : "LCtrl"
    if (wParam = 18) ; VK_MENU (Alt)
        return isExt ? "RAlt" : "LAlt"
    if (wParam = 16) { ; VK_SHIFT
        sc := (lParam >> 16) & 0xFF
        vkEx := DllCall("MapVirtualKey", "UInt", sc, "UInt", 3, "UInt") ; MAPVK_VSC_TO_VK_EX
        return (vkEx = 0xA1) ? "RShift" : "LShift"
    }
    if (wParam = 91)
        return "LWin"
    if (wParam = 92)
        return "RWin"
    if (wParam = 160)
        return "LShift"
    if (wParam = 161)
        return "RShift"
    if (wParam = 162)
        return "LCtrl"
    if (wParam = 163)
        return "RCtrl"
    if (wParam = 164)
        return "LAlt"
    if (wParam = 165)
        return "RAlt"
    return ""
}

OnMicHotkeyDlgKeyDown(wParam, lParam, msg, hwnd) {
    global hMicHotkeyDlg, MicHotkeyCaptured, MicHotkeyCapturing, MicHotkeyTargetMode, MicHotkeyPendingMod
    if (!MicHotkeyCapturing || !hMicHotkeyDlg)
        return
    if (hwnd != hMicHotkeyDlg && !DllCall("IsChild", "Ptr", hMicHotkeyDlg, "Ptr", hwnd))
        return

    modName := GetSideModifierName(wParam, lParam)
    if (modName != "") {
        if (MicHotkeyTargetMode = "ptt")
            MicHotkeyPendingMod := modName
        return 0
    }

    MicHotkeyPendingMod := ""
    if (wParam = 27) ; Esc để đóng
        return

    vkHex := Format("vk{:02X}", wParam)
    keyName := GetKeyName(vkHex)
    if (keyName = "")
        return 0

    mods := ""
    if (GetKeyState("Ctrl", "P"))
        mods .= "^"
    if (GetKeyState("Alt", "P"))
        mods .= "!"
    if (GetKeyState("Shift", "P"))
        mods .= "+"
    if (GetKeyState("LWin", "P") || GetKeyState("RWin", "P"))
        mods .= "#"

    MicHotkeyCaptured := mods . keyName
    GuiControl, MicHotkeyDlg:, MicHotkeyPreview, % IsFunc("FormatMicHotkeyText") ? FormatMicHotkeyText(MicHotkeyCaptured) : MicHotkeyCaptured
    return 0
}

OnMicHotkeyDlgKeyUp(wParam, lParam, msg, hwnd) {
    global hMicHotkeyDlg, MicHotkeyCaptured, MicHotkeyCapturing, MicHotkeyTargetMode, MicHotkeyPendingMod
    if (!MicHotkeyCapturing || !hMicHotkeyDlg || MicHotkeyTargetMode != "ptt")
        return
    if (hwnd != hMicHotkeyDlg && !DllCall("IsChild", "Ptr", hMicHotkeyDlg, "Ptr", hwnd))
        return

    modName := GetSideModifierName(wParam, lParam)
    if (modName != "" && MicHotkeyPendingMod != "" && modName = MicHotkeyPendingMod) {
        MicHotkeyPendingMod := ""
        MicHotkeyCaptured := modName
        GuiControl, MicHotkeyDlg:, MicHotkeyPreview, % IsFunc("FormatMicHotkeyText") ? FormatMicHotkeyText(MicHotkeyCaptured) : MicHotkeyCaptured
        return 0
    }
}

OnMicHotkeyDlgMouseBtn(wParam, lParam, msg, hwnd) {
    global hMicHotkeyDlg, MicHotkeyCaptured, MicHotkeyCapturing, MicHotkeyPendingMod
    if (!MicHotkeyCapturing || !hMicHotkeyDlg)
        return
    if (hwnd != hMicHotkeyDlg && !DllCall("IsChild", "Ptr", hMicHotkeyDlg, "Ptr", hwnd))
        return

    MicHotkeyPendingMod := ""
    btnName := ""
    if (msg = 0x207) {
        btnName := "MButton"
    } else if (msg = 0x20B) {
        xBtn := (wParam >> 16) & 0xFFFF
        btnName := (xBtn = 1) ? "XButton1" : (xBtn = 2 ? "XButton2" : "")
    }
    if (btnName = "")
        return

    mods := ""
    if (GetKeyState("Ctrl", "P"))
        mods .= "^"
    if (GetKeyState("Alt", "P"))
        mods .= "!"
    if (GetKeyState("Shift", "P"))
        mods .= "+"
    if (GetKeyState("LWin", "P") || GetKeyState("RWin", "P"))
        mods .= "#"

    MicHotkeyCaptured := mods . btnName
    GuiControl, MicHotkeyDlg:, MicHotkeyPreview, % IsFunc("FormatMicHotkeyText") ? FormatMicHotkeyText(MicHotkeyCaptured) : MicHotkeyCaptured
    return 0
}

OnResetMicHotkey:
    if (MicHotkeyTargetMode = "ptt")
        MicHotkeyCaptured := "RCtrl"
    else
        MicHotkeyCaptured := "#!m"
    GuiControl, MicHotkeyDlg:, MicHotkeyPreview, % IsFunc("FormatMicHotkeyText") ? FormatMicHotkeyText(MicHotkeyCaptured) : MicHotkeyCaptured
return

OnSaveMicHotkey:
    if (MicHotkeyCaptured = "")
        return
    if (MicHotkeyTargetMode = "ptt") {
        MicPttHotkey := MicHotkeyCaptured
        if (IsFunc("FormatMicHotkeyText"))
            GuiControl, ShortcutsScroll:, MicPttHotkeyBtn, % FormatMicHotkeyText(MicPttHotkey)
    } else {
        MicMuteHotkey := MicHotkeyCaptured
        if (IsFunc("FormatMicHotkeyText"))
            GuiControl, ShortcutsScroll:, MicHotkeyBtn, % FormatMicHotkeyText(MicMuteHotkey)
        if (IsFunc("RebuildTrayMenu"))
            RebuildTrayMenu()
    }
    if (IsFunc("SaveMicMuteSettings"))
        SaveMicMuteSettings()
    Gosub, MicHotkeyDlgGuiClose
return

MicHotkeyDlgGuiClose:
MicHotkeyDlgGuiEscape:
    MicHotkeyCapturing := false
    MicHotkeyPendingMod := ""
    OnMessage(0x100, "OnMicHotkeyDlgKeyDown", 0)
    OnMessage(0x104, "OnMicHotkeyDlgKeyDown", 0)
    OnMessage(0x101, "OnMicHotkeyDlgKeyUp", 0)
    OnMessage(0x105, "OnMicHotkeyDlgKeyUp", 0)
    OnMessage(0x207, "OnMicHotkeyDlgMouseBtn", 0)
    OnMessage(0x20B, "OnMicHotkeyDlgMouseBtn", 0)
    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) {
        Gui, Settings:-Disabled
        WinActivate, ahk_id %hSettingsGui%
    }
    Gui, MicHotkeyDlg:Destroy
    hMicHotkeyDlg := 0
    if (IsFunc("ApplyMicMuteHotkey"))
        ApplyMicMuteHotkey()
return
