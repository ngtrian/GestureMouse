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
global hAboutHeroBmp        := 0

; Tạo GUI cài đặt - Settings (Giao diện Fluent Cards gọn gàng, Singleton pattern)
Settings:
    if (hSettingsGui) {
        DetectHiddenWindows, On
        guiExists := WinExist("ahk_id " . hSettingsGui)
        DetectHiddenWindows, Off
        if (guiExists) {
            UpdateSettingsGuiControls()
            SwitchSettingsTab(currentSettingsTab ? currentSettingsTab : 1)
            Gui, Settings:Show, Center, % "GestureMouse - " . L("Set_Title")
            WinActivate, ahk_id %hSettingsGui%
            return
        }
    }

    if (IsFunc("LoadLockSettings"))
        LoadLockSettings()

    isCodeRevealed := 0
    SettingsTooltips := {}
    LastSettingsTipHwnd := 0
    SidebarIconHwnds := {}
    if (!SidebarNavBitmaps.HasKey(1))
        SidebarNavBitmaps := CreateSidebarNavBitmaps(20)

    Gui, Settings:New, -MaximizeBox -MinimizeBox +HwndhSettingsGui, % "GestureMouse - " . L("Set_Title")
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

    gestureBadges := CreateGestureBadgeBitmaps(32, 22)
    AddBrowserGestureRow(323, gestureBadges["L"],  "Set_Back",     "Set_TipGestureL",  gestureBadges["R"],  "Set_Forward", "Set_TipGestureR")
    AddBrowserGestureRow(347, gestureBadges["LU"], "Set_PrevTab",  "Set_TipGestureLU", gestureBadges["LD"], "Set_NextTab", "Set_TipGestureLD")
    AddBrowserGestureRow(371, gestureBadges["RU"], "Set_CloseTab", "Set_TipGestureRU", gestureBadges["RD"], "Set_Refresh", "Set_TipGestureRD")

    ; --------------------------------------------------------
    ; TAB 3: KHÓA BÀN PHÍM && CHUỘT
    ; --------------------------------------------------------
    Gui, Tab, TabLock
    AddSettingsTabHeader("Set_HeaderLock", "Set_SubLock")

    ; Card 1: Thiết lập khóa thiết bị
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y58 w536 h122, % L("Lock_Card1Title")

    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Picture, x246 y77 w24 h24 Icon28, %A_WinDir%\System32\ddores.dll
    Gui, Add, Checkbox, x274 y78 w118 h22 vlockKeyboardEnabled gSaveSettings Checked%lockKeyboardEnabled%, % L("Lock_TargetKB")
    Gui, Add, Picture, x398 y77 w24 h24 Icon32, %A_WinDir%\System32\ddores.dll
    Gui, Add, Checkbox, x426 y78 w96 h22 vmouseLockEnabled gSaveSettings Checked%mouseLockEnabled%, % L("Lock_TargetMouse")
    Gui, Font, s9 Norm c222222, Segoe UI
    Gui, Add, Button, x528 y76 w218 h26 gOpenWhitelistGui, % L("Lock_WhitelistBtn")

    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Checkbox, x246 y117 w276 vautoLockIdleEnabled gOnToggleIdleCheck Checked%autoLockIdleEnabled%, % L("Lock_AutoIdleCheck")
    Gui, Font, s9 Norm c222222, Segoe UI
    Gui, Add, DropDownList, x528 y114 w218 vautoLockIdleMinutesChoice gSaveSettings Choose%selIdleIdx%, %idleMinutesList%

    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Checkbox, x246 y148 w172 h22 vpreventScreenOff gSaveSettings Checked%preventScreenOff%, % L("Lock_PreventScreenOff")
    Gui, Add, Checkbox, x426 y148 w142 h22 vpreventSleep gSaveSettings Checked%preventSleep%, % L("Lock_PreventSleep")
    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x574 y151 w172 h18 +Right, % L("Lock_PowerScopeHint")

    ; Card 2: Bảo mật & Mở khóa
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y190 w536 h204, % L("Lock_Card2Title")

    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Checkbox, x246 y212 w500 vwindowsLogonOnly gOnToggleWindowsLogonOnly Checked%windowsLogonOnly%, % L("Lock_WinLogonOnly")

    Gui, Add, Text, x246 y245 w105 vLockKeyPromptLbl, % L("Lock_KeyPrompt")
    Gui, Font, s9 Norm c222222, Segoe UI
    Gui, Add, Edit, x356 y242 w184 h24 vUnlockCodeDisplay ReadOnly Password, %UNLOCK_KEYWORD%
    Gui, Add, Button, x546 y241 w64 h26 gToggleRevealCode vBtnToggleReveal Center, % L("Lock_ShowBtn")
    Gui, Add, Button, x616 y241 w130 h26 gOpenChangeCodeGui vBtnChangeCode, % L("Lock_ChangeCodeBtn")

    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Checkbox, x246 y276 w500 vrequireCodeForTimerEdit gSaveSettings Checked%requireCodeForTimerEdit%, % L("Lock_ReqTimerEditCode")

    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x246 y304 w500 h30 vLockMethodHintTxt, % ("• " . (windowsLogonOnly ? L("Lock_MethodHintWinOnly") : L("Lock_MethodHint")))

    Gui, Font, s9.5 Bold c004499, Segoe UI
    Gui, Add, Button, x246 y348 w500 h34 gActionOpenLockCenter, % L("Lock_CenterBtn")

    ; --------------------------------------------------------
    ; TAB 4: PHÍM TẮT && TIỆN ÍCH
    ; --------------------------------------------------------
    Gui, Tab, TabShortcuts
    AddSettingsTabHeader("Set_HeaderShortcuts", "Set_SubShortcuts")

    ; Card 1: Phím tắt hệ thống
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y58 w536 h232, % L("Set_GroupSystemHotkeys")

    AddShortcutRow(82,  "Icon28",  A_WinDir . "\System32\ddores.dll",  "Set_LockCenter", "Ctrl + Alt + L",   "ActionOpenLockCenter")
    AddShortcutRow(114, "Icon261", A_WinDir . "\System32\shell32.dll", "Set_PastePlain", "Ctrl + Shift + V", "ActionPastePlain")
    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x274 y137 w472 h18, % L("Set_PastePlainDesc")
    AddShortcutRow(162, "Icon3",   A_WinDir . "\System32\SndVol.exe",  "Set_Mute",       "Ctrl + Shift + M", "ActionMute")
    AddShortcutRow(194, "Icon2",   A_WinDir . "\System32\SndVol.exe",  "Set_Volume",     L("Set_VolUpBtn"),    "ActionVolUp",     L("Set_VolDownBtn"),  "ActionVolDown")
    AddShortcutRow(226, "Icon26",  A_WinDir . "\System32\shell32.dll", "Set_Brightness", L("Set_BrightDownBtn"), "ActionBrightDown", L("Set_BrightUpBtn"), "ActionBrightUp")

    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x246 y260 w500 h22, % L("Set_ShortcutsTip")

    ; Card 2: Thao tác nhanh trên khay hệ thống
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y300 w536 h94, % L("Set_GroupTrayActions")

    AddShortcutRow(324, "Icon1", aboutIcon, "Set_TrayToggleLabel", L("Set_TrayToggleBtn"), "ActionToggleGestures")
    Gui, Font, s8.5 Norm c555555, Segoe UI
    Gui, Add, Text, x246 y358 w500 h26, % "• " . L("Set_TrayDblClickTip")

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

    ; Khởi tạo hiển thị tab hiện tại với background sidebar được tô màu
    SwitchSettingsTab(currentSettingsTab ? currentSettingsTab : 1)

    ; Đăng ký theo dõi hover để hiển thị chú thích cho icon cử chỉ
    OnMessage(0x200, "WM_MOUSEMOVE_SETTINGS")

    ; Hiển thị giao diện kích thước tinh gọn (w780 h455)
    Gui, Show, w780 h455 Center, % "GestureMouse - " . L("Set_Title")
    SetGuiYellowIcon(hSettingsGui)
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

CreateSidebarNavBitmaps(iconSize := 20) {
    result := {}
    hGdip := DllCall("LoadLibrary", "Str", "gdiplus", "Ptr")
    if (!hGdip)
        return result

    VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0)
    NumPut(1, si, 0, "UInt")
    pToken := 0
    if (DllCall("gdiplus\GdiplusStartup", "Ptr*", pToken, "Ptr", &si, "Ptr", 0) != 0) {
        DllCall("FreeLibrary", "Ptr", hGdip)
        return result
    }

    scale := A_ScreenDPI / 96.0
    pix := Round(iconSize * scale)

    bgr := DllCall("GetSysColor", "Int", 15, "UInt")
    argbWin := 0xFF000000 | ((bgr & 0xFF) << 16) | (bgr & 0xFF00) | ((bgr >> 16) & 0xFF)
    argbActiveBg := 0xFFE5F1FB
    argbActiveFg := 0xFF005FB8
    argbNormFg := 0xFF4A5568

    Loop, 5 {
        idx := A_Index
        result[idx] := {}
        for stateIdx, stateName in ["inactive", "active"] {
            bgCol := (stateName = "active") ? argbActiveBg : argbWin
            fgCol := (stateName = "active") ? argbActiveFg : argbNormFg

            pBitmap := 0, pGraphics := 0, hBmp := 0
            DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", pix, "Int", pix, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", pBitmap)
            DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBitmap, "Ptr*", pGraphics)
            DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", 4)
            DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", pGraphics, "Int", 2)
            DllCall("gdiplus\GdipGraphicsClear", "Ptr", pGraphics, "UInt", bgCol)

            DrawSidebarVectorIcon(pGraphics, idx, fgCol, bgCol, scale)

            DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", hBmp, "UInt", bgCol)
            result[idx][stateName] := hBmp
            DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGraphics)
            DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
        }
    }

    DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
    DllCall("FreeLibrary", "Ptr", hGdip)
    return result
}

DrawSidebarVectorIcon(pGraphics, idx, fgCol, bgCol, scale) {
    DllCall("gdiplus\GdipCreatePen1", "UInt", fgCol, "Float", 1.7 * scale, "Int", 2, "Ptr*", pPen)
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", fgCol, "Ptr*", pBrush)
    DllCall("gdiplus\GdipSetPenLineJoin", "Ptr", pPen, "Int", 2)

    if (idx == 1) {
        ; Cài đặt chung: bánh răng sắc nét 8 răng
        DllCall("gdiplus\GdipCreatePen1", "UInt", fgCol, "Float", 2.2 * scale, "Int", 2, "Ptr*", pPenTooth)
        Loop, 8 {
            ang := (A_Index - 1) * 45.0 * 0.01745329252
            x1 := (10.0 + 5.2 * Cos(ang)) * scale
            y1 := (10.0 + 5.2 * Sin(ang)) * scale
            x2 := (10.0 + 8.3 * Cos(ang)) * scale
            y2 := (10.0 + 8.3 * Sin(ang)) * scale
            DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPenTooth, "Float", x1, "Float", y1, "Float", x2, "Float", y2)
        }
        DllCall("gdiplus\GdipDeletePen", "Ptr", pPenTooth)
        DllCall("gdiplus\GdipCreatePen1", "UInt", fgCol, "Float", 2.1 * scale, "Int", 2, "Ptr*", pPenRing)
        DllCall("gdiplus\GdipDrawEllipse", "Ptr", pGraphics, "Ptr", pPenRing, "Float", 4.9 * scale, "Float", 4.9 * scale, "Float", 10.2 * scale, "Float", 10.2 * scale)
        DllCall("gdiplus\GdipDeletePen", "Ptr", pPenRing)
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", bgCol, "Ptr*", pBrushHole)
        DllCall("gdiplus\GdipFillEllipse", "Ptr", pGraphics, "Ptr", pBrushHole, "Float", 7.3 * scale, "Float", 7.3 * scale, "Float", 5.4 * scale, "Float", 5.4 * scale)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrushHole)
        DllCall("gdiplus\GdipDrawEllipse", "Ptr", pGraphics, "Ptr", pPen, "Float", 7.5 * scale, "Float", 7.5 * scale, "Float", 5.0 * scale, "Float", 5.0 * scale)
    } else if (idx == 2) {
        ; Cuộn & Cử chỉ: chuột hiện đại với con lăn
        DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pPath)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", 5.0 * scale, "Float", 2.0 * scale, "Float", 10.0 * scale, "Float", 10.0 * scale, "Float", 180.0, "Float", 180.0)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", 5.0 * scale, "Float", 8.0 * scale, "Float", 10.0 * scale, "Float", 10.0 * scale, "Float", 0.0, "Float", 180.0)
        DllCall("gdiplus\GdipClosePathFigure", "Ptr", pPath)
        DllCall("gdiplus\GdipDrawPath", "Ptr", pGraphics, "Ptr", pPen, "Ptr", pPath)
        DllCall("gdiplus\GdipDeletePath", "Ptr", pPath)

        DllCall("gdiplus\GdipCreatePen1", "UInt", fgCol, "Float", 1.3 * scale, "Int", 2, "Ptr*", pPenThin)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPenThin, "Float", 5.2 * scale, "Float", 8.5 * scale, "Float", 14.8 * scale, "Float", 8.5 * scale)
        DllCall("gdiplus\GdipDeletePen", "Ptr", pPenThin)

        DllCall("gdiplus\GdipCreatePen1", "UInt", fgCol, "Float", 2.2 * scale, "Int", 2, "Ptr*", pPenWheel)
        DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pPenWheel, "Int", 2)
        DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pPenWheel, "Int", 2)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPenWheel, "Float", 10.0 * scale, "Float", 4.4 * scale, "Float", 10.0 * scale, "Float", 7.0 * scale)
        DllCall("gdiplus\GdipDeletePen", "Ptr", pPenWheel)
    } else if (idx == 3) {
        ; Khóa: ổ khóa rõ nét
        DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pShackle)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pShackle, "Float", 6.8 * scale, "Float", 2.4 * scale, "Float", 6.4 * scale, "Float", 6.4 * scale, "Float", 180.0, "Float", 180.0)
        DllCall("gdiplus\GdipDrawPath", "Ptr", pGraphics, "Ptr", pPen, "Ptr", pShackle)
        DllCall("gdiplus\GdipDeletePath", "Ptr", pShackle)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPen, "Float", 6.8 * scale, "Float", 5.6 * scale, "Float", 6.8 * scale, "Float", 8.5 * scale)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPen, "Float", 13.2 * scale, "Float", 5.6 * scale, "Float", 13.2 * scale, "Float", 8.5 * scale)

        DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pBody)
        d := 3.6 * scale
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pBody, "Float", 4.5 * scale, "Float", 8.5 * scale, "Float", d, "Float", d, "Float", 180.0, "Float", 90.0)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pBody, "Float", 15.5 * scale - d, "Float", 8.5 * scale, "Float", d, "Float", d, "Float", 270.0, "Float", 90.0)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pBody, "Float", 15.5 * scale - d, "Float", 17.5 * scale - d, "Float", d, "Float", d, "Float", 0.0, "Float", 90.0)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pBody, "Float", 4.5 * scale, "Float", 17.5 * scale - d, "Float", d, "Float", d, "Float", 90.0, "Float", 90.0)
        DllCall("gdiplus\GdipClosePathFigure", "Ptr", pBody)
        DllCall("gdiplus\GdipDrawPath", "Ptr", pGraphics, "Ptr", pPen, "Ptr", pBody)
        DllCall("gdiplus\GdipDeletePath", "Ptr", pBody)

        DllCall("gdiplus\GdipFillEllipse", "Ptr", pGraphics, "Ptr", pBrush, "Float", 8.9 * scale, "Float", 11.1 * scale, "Float", 2.2 * scale, "Float", 2.2 * scale)
        DllCall("gdiplus\GdipCreatePen1", "UInt", fgCol, "Float", 1.8 * scale, "Int", 2, "Ptr*", pPenSlot)
        DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pPenSlot, "Int", 2)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPenSlot, "Float", 10.0 * scale, "Float", 12.2 * scale, "Float", 10.0 * scale, "Float", 14.9 * scale)
        DllCall("gdiplus\GdipDeletePen", "Ptr", pPenSlot)
    } else if (idx == 4) {
        ; Phím tắt: bàn phím gọn rõ nét
        DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pKb)
        d := 3.6 * scale
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pKb, "Float", 2.0 * scale, "Float", 4.8 * scale, "Float", d, "Float", d, "Float", 180.0, "Float", 90.0)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pKb, "Float", 18.0 * scale - d, "Float", 4.8 * scale, "Float", d, "Float", d, "Float", 270.0, "Float", 90.0)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pKb, "Float", 18.0 * scale - d, "Float", 15.2 * scale - d, "Float", d, "Float", d, "Float", 0.0, "Float", 90.0)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pKb, "Float", 2.0 * scale, "Float", 15.2 * scale - d, "Float", d, "Float", d, "Float", 90.0, "Float", 90.0)
        DllCall("gdiplus\GdipClosePathFigure", "Ptr", pKb)
        DllCall("gdiplus\GdipDrawPath", "Ptr", pGraphics, "Ptr", pPen, "Ptr", pKb)
        DllCall("gdiplus\GdipDeletePath", "Ptr", pKb)

        Loop, 4 {
            kx := (4.4 + (A_Index - 1) * 3.1) * scale
            DllCall("gdiplus\GdipFillRectangle", "Ptr", pGraphics, "Ptr", pBrush, "Float", kx, "Float", 7.3 * scale, "Float", 1.9 * scale, "Float", 1.7 * scale)
            DllCall("gdiplus\GdipFillRectangle", "Ptr", pGraphics, "Ptr", pBrush, "Float", kx, "Float", 9.9 * scale, "Float", 1.9 * scale, "Float", 1.7 * scale)
        }
        DllCall("gdiplus\GdipFillRectangle", "Ptr", pGraphics, "Ptr", pBrush, "Float", 5.8 * scale, "Float", 12.5 * scale, "Float", 8.4 * scale, "Float", 1.6 * scale)
    } else if (idx == 5) {
        ; Thông tin: vòng tròn chữ i
        DllCall("gdiplus\GdipDrawEllipse", "Ptr", pGraphics, "Ptr", pPen, "Float", 2.5 * scale, "Float", 2.5 * scale, "Float", 15.0 * scale, "Float", 15.0 * scale)
        DllCall("gdiplus\GdipFillEllipse", "Ptr", pGraphics, "Ptr", pBrush, "Float", 8.85 * scale, "Float", 5.5 * scale, "Float", 2.3 * scale, "Float", 2.3 * scale)
        DllCall("gdiplus\GdipCreatePen1", "UInt", fgCol, "Float", 2.1 * scale, "Int", 2, "Ptr*", pPenI)
        DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pPenI, "Int", 2)
        DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pPenI, "Int", 2)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPenI, "Float", 10.0 * scale, "Float", 9.2 * scale, "Float", 10.0 * scale, "Float", 14.3 * scale)
        DllCall("gdiplus\GdipDeletePen", "Ptr", pPenI)
    }

    DllCall("gdiplus\GdipDeletePen", "Ptr", pPen)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrush)
}

AddSettingsTabHeader(titleKey, subKey) {
    Gui, Settings:Font, s13 Bold c004499, Segoe UI
    Gui, Settings:Add, Text, x228 y12 w536, % L(titleKey)
    Gui, Settings:Font, s8.5 Norm c666666, Segoe UI
    Gui, Settings:Add, Text, x228 y35 w536, % L(subKey)
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

CreateAboutHeroIconBitmap(iconSize := 56, bgRgb := 0xEEF5FC) {
    scale := A_ScreenDPI / 96.0
    pix := Round(iconSize * scale)

    hIcon := 0
    if (A_IsCompiled) {
        hMod := DllCall("GetModuleHandle", "Ptr", 0, "Ptr")
        hIcon := DllCall("LoadImage", "Ptr", hMod, "UInt", 159, "UInt", 1, "Int", pix, "Int", pix, "UInt", 0, "Ptr")
        if (!hIcon)
            DllCall("Shell32\ExtractIconEx", "Str", A_ScriptFullPath, "Int", 0, "Ptr*", hIcon, "Ptr", 0, "UInt", 1)
    } else {
        icoPath := A_ScriptDir . "\image\unnamed.ico"
        if (FileExist(icoPath))
            hIcon := DllCall("LoadImage", "Ptr", 0, "Str", icoPath, "UInt", 1, "Int", pix, "Int", pix, "UInt", 0x10, "Ptr")
    }
    if (!hIcon)
        return 0

    hdcScreen := DllCall("GetDC", "Ptr", 0, "Ptr")
    hdcMem := DllCall("CreateCompatibleDC", "Ptr", hdcScreen, "Ptr")
    hBmp := DllCall("CreateCompatibleBitmap", "Ptr", hdcScreen, "Int", pix, "Int", pix, "Ptr")
    hOld := DllCall("SelectObject", "Ptr", hdcMem, "Ptr", hBmp, "Ptr")

    bgr := ((bgRgb & 0xFF) << 16) | (bgRgb & 0xFF00) | ((bgRgb >> 16) & 0xFF)
    hBrush := DllCall("CreateSolidBrush", "UInt", bgr, "Ptr")
    VarSetCapacity(rc, 16, 0)
    NumPut(pix, rc, 8, "Int")
    NumPut(pix, rc, 12, "Int")
    DllCall("FillRect", "Ptr", hdcMem, "Ptr", &rc, "Ptr", hBrush)
    DllCall("DeleteObject", "Ptr", hBrush)

    DllCall("DrawIconEx", "Ptr", hdcMem, "Int", 0, "Int", 0, "Ptr", hIcon, "Int", pix, "Int", pix, "UInt", 0, "Ptr", 0, "UInt", 0x3)

    DllCall("SelectObject", "Ptr", hdcMem, "Ptr", hOld, "Ptr")
    DllCall("DeleteDC", "Ptr", hdcMem)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcScreen)
    DllCall("DestroyIcon", "Ptr", hIcon)
    return hBmp
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
        Gui, Settings:Add, Picture, x412 y%badgeY% +0x100 HwndhBadge1, HBITMAP:%hBmp1%
        SettingsTooltips[hBadge1] := L(tipKey1)
    }

    Gui, Settings:Font, s9 Norm c222222, Segoe UI
    Gui, Settings:Add, Text, x500 y%yPos% w170, % L(labelKey2)
    if (hBmp2) {
        Gui, Settings:Add, Picture, x676 y%badgeY% +0x100 HwndhBadge2, HBITMAP:%hBmp2%
        SettingsTooltips[hBadge2] := L(tipKey2)
    }
}

CreateGestureBadgeBitmaps(badgeW := 32, badgeH := 22) {
    result := {}
    hGdip := DllCall("LoadLibrary", "Str", "gdiplus", "Ptr")
    if (!hGdip)
        return result

    VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0)
    NumPut(1, si, 0, "UInt")
    pToken := 0
    if (DllCall("gdiplus\GdiplusStartup", "Ptr*", pToken, "Ptr", &si, "Ptr", 0) != 0) {
        DllCall("FreeLibrary", "Ptr", hGdip)
        return result
    }

    scale := A_ScreenDPI / 96.0
    pixW := Round(badgeW * scale)
    pixH := Round(badgeH * scale)

    bgr := DllCall("GetSysColor", "Int", 15, "UInt")
    argbWin := 0xFF000000 | ((bgr & 0xFF) << 16) | (bgr & 0xFF00) | ((bgr >> 16) & 0xFF)

    DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pPath)
    d := 8.0 * scale
    pad := 0.5 * scale
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", pad, "Float", pad, "Float", d, "Float", d, "Float", 180.0, "Float", 90.0)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", pixW - 1.0 * scale - d, "Float", pad, "Float", d, "Float", d, "Float", 270.0, "Float", 90.0)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", pixW - 1.0 * scale - d, "Float", pixH - 1.0 * scale - d, "Float", d, "Float", d, "Float", 0.0, "Float", 90.0)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", pad, "Float", pixH - 1.0 * scale - d, "Float", d, "Float", d, "Float", 90.0, "Float", 90.0)
    DllCall("gdiplus\GdipClosePathFigure", "Ptr", pPath)

    DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0xFFEBF3FB, "Ptr*", pBrushBg)
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0xFF005FB8, "Ptr*", pBrushArrow)
    DllCall("gdiplus\GdipCreatePen1", "UInt", 0xFFBDD6F0, "Float", 1.0 * scale, "Int", 2, "Ptr*", pPenBorder)
    DllCall("gdiplus\GdipCreatePen1", "UInt", 0xFF005FB8, "Float", 2.0 * scale, "Int", 2, "Ptr*", pPenArrow)
    DllCall("gdiplus\GdipSetPenLineJoin", "Ptr", pPenArrow, "Int", 2)
    DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pPenArrow, "Int", 2)
    DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pPenArrow, "Int", 0)

    shapes := {}
    shapes["L"]  := {shaft: [24.0, 11.0, 11.5, 11.0],               head: [ 7.0, 11.0, 13.0,  6.5, 13.0, 15.5]}
    shapes["R"]  := {shaft: [ 8.0, 11.0, 20.5, 11.0],               head: [25.0, 11.0, 19.0,  6.5, 19.0, 15.5]}
    shapes["LU"] := {shaft: [23.0, 16.5, 11.5, 16.5, 11.5,  8.5],   head: [11.5,  4.5,  7.0, 10.0, 16.0, 10.0]}
    shapes["LD"] := {shaft: [23.0,  5.5, 11.5,  5.5, 11.5, 13.5],   head: [11.5, 17.5,  7.0, 12.0, 16.0, 12.0]}
    shapes["RU"] := {shaft: [ 9.0, 16.5, 20.5, 16.5, 20.5,  8.5],   head: [20.5,  4.5, 16.0, 10.0, 25.0, 10.0]}
    shapes["RD"] := {shaft: [ 9.0,  5.5, 20.5,  5.5, 20.5, 13.5],   head: [20.5, 17.5, 16.0, 12.0, 25.0, 12.0]}

    for dirKey, geom in shapes {
        pBitmap := 0, pGraphics := 0, hBmp := 0
        DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", pixW, "Int", pixH, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", pBitmap)
        DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBitmap, "Ptr*", pGraphics)
        DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", 4)
        DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", pGraphics, "Int", 2)
        DllCall("gdiplus\GdipGraphicsClear", "Ptr", pGraphics, "UInt", argbWin)
        DllCall("gdiplus\GdipFillPath", "Ptr", pGraphics, "Ptr", pBrushBg, "Ptr", pPath)
        DllCall("gdiplus\GdipDrawPath", "Ptr", pGraphics, "Ptr", pPenBorder, "Ptr", pPath)

        DrawGdipPolyline(pGraphics, pPenArrow, geom.shaft, scale)
        FillGdipPolygon(pGraphics, pBrushArrow, geom.head, scale)

        DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", hBmp, "UInt", argbWin)
        result[dirKey] := hBmp
        DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGraphics)
        DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
    }

    DllCall("gdiplus\GdipDeletePen", "Ptr", pPenArrow)
    DllCall("gdiplus\GdipDeletePen", "Ptr", pPenBorder)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrushArrow)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrushBg)
    DllCall("gdiplus\GdipDeletePath", "Ptr", pPath)
    DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
    DllCall("FreeLibrary", "Ptr", hGdip)
    return result
}

DrawGdipPolyline(pGraphics, pPen, coords, scale := 1.0) {
    cnt := coords.Length() // 2
    VarSetCapacity(pts, cnt * 8, 0)
    Loop, %cnt% {
        idx := (A_Index - 1) * 2
        NumPut(coords[idx + 1] * scale, pts, idx * 4, "Float")
        NumPut(coords[idx + 2] * scale, pts, (idx + 1) * 4, "Float")
    }
    DllCall("gdiplus\GdipDrawLines", "Ptr", pGraphics, "Ptr", pPen, "Ptr", &pts, "Int", cnt)
}

FillGdipPolygon(pGraphics, pBrush, coords, scale := 1.0) {
    cnt := coords.Length() // 2
    VarSetCapacity(pts, cnt * 8, 0)
    Loop, %cnt% {
        idx := (A_Index - 1) * 2
        NumPut(coords[idx + 1] * scale, pts, idx * 4, "Float")
        NumPut(coords[idx + 2] * scale, pts, (idx + 1) * 4, "Float")
    }
    DllCall("gdiplus\GdipFillPolygon", "Ptr", pGraphics, "Ptr", pBrush, "Ptr", &pts, "Int", cnt, "Int", 0)
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
    GuiControl, Settings:, windowsLogonOnly, %windowsLogonOnly%
    GuiControl, Settings:, requireCodeForTimerEdit, %requireCodeForTimerEdit%
    GuiControl, Settings:, UnlockCodeDisplay, %UNLOCK_KEYWORD%
    UpdateLockAuthControlsState(windowsLogonOnly)

    chkVI := (CurrentLang = "vi") ? 1 : 0
    chkEN := (CurrentLang = "en") ? 1 : 0
    GuiControl, Settings:, LangVI, %chkVI%
    GuiControl, Settings:, LangEN, %chkEN%
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

SwitchSettingsTab(tabNum) {
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
        GuiControl, Settings:MoveDraw, NavTxt%A_Index%
        if (SidebarIconHwnds.HasKey(A_Index) && SidebarNavBitmaps.HasKey(A_Index)) {
            hBmp := isActive ? SidebarNavBitmaps[A_Index].active : SidebarNavBitmaps[A_Index].inactive
            DllCall("SendMessage", "Ptr", SidebarIconHwnds[A_Index], "UInt", 0x0172, "Ptr", 0, "Ptr", hBmp)
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
        GuiControl,, BtnToggleReveal, % L("Lock_HideBtn")
    } else {
        GuiControl, +Password, UnlockCodeDisplay
        GuiControl,, BtnToggleReveal, % L("Lock_ShowBtn")
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

OnToggleWindowsLogonOnly:
    Gui, Settings:Submit, NoHide
    UpdateLockAuthControlsState(windowsLogonOnly)
    Gosub, SaveSettings
return

UpdateLockAuthControlsState(winOnly) {
    global isCodeRevealed, UNLOCK_KEYWORD
    enableCustom := !winOnly
    if (winOnly && isCodeRevealed) {
        isCodeRevealed := 0
        GuiControl, Settings:+Password, UnlockCodeDisplay
        GuiControl, Settings:, BtnToggleReveal, % L("Lock_ShowBtn")
        GuiControl, Settings:, UnlockCodeDisplay, %UNLOCK_KEYWORD%
    }
    GuiControl, Settings:Enable%enableCustom%, LockKeyPromptLbl
    GuiControl, Settings:Enable%enableCustom%, UnlockCodeDisplay
    GuiControl, Settings:Enable%enableCustom%, BtnToggleReveal
    GuiControl, Settings:Enable%enableCustom%, BtnChangeCode
    GuiControl, Settings:Enable%enableCustom%, requireCodeForTimerEdit
    hintTxt := "• " . (winOnly ? L("Lock_MethodHintWinOnly") : L("Lock_MethodHint"))
    GuiControl, Settings:, LockMethodHintTxt, %hintTxt%
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
    windowsLogonOnly := windowsLogonOnly ? 1 : 0
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, WindowsLogonOnly, %windowsLogonOnly%

    requireCodeForTimerEdit := requireCodeForTimerEdit ? 1 : 0
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, RequireCodeForTimerEdit, %requireCodeForTimerEdit%

    ; Lưu trạng thái ngăn tắt màn hình & ngăn Sleep khi khóa
    preventScreenOff := preventScreenOff ? 1 : 0
    preventSleep := preventSleep ? 1 : 0
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, PreventScreenOff, %preventScreenOff%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, PreventSleep, %preventSleep%
    if (IsFunc("ApplyLockPowerPolicy"))
        ApplyLockPowerPolicy()

    ; Cập nhật tray tip
    fnTip := "UpdateTrayTip"
    if (IsFunc(fnTip))
        %fnTip%()
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
