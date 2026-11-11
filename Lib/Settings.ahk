; Settings.ahk - Quản lý Giao diện Cài đặt (Settings GUI) phong cách Windows 11 Fluent Cards
#NoEnv

#Include *i Language.ahk

global currentSettingsTab := 1
global isCodeRevealed     := 0
global hChangeCodeGui     := 0

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

    ; Đọc trạng thái giữ màn hình sáng khi khóa
    RegRead, valDisableSleep, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, DisableAutoLockScreen
    disableAutoLockScreen := (valDisableSleep != "") ? valDisableSleep : 1

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
    ; SIDEBAR ĐIỀU HƯỚNG BÊN TRÁI
    ; ========================================================
    Gui, Add, Picture, x16 y14 w32 h32 Icon1, %aboutIcon%
    Gui, Font, s11 Bold c004499, Segoe UI
    Gui, Add, Text, x56 y12 w148 h20, GestureMouse
    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x56 y32 w148 h16, % L("Set_Title")

    Gui, Add, Text, x12 y54 w190 h1 0x10

    AddSidebarNav(1, 64,  "⚙️", L("Nav_General"))
    AddSidebarNav(2, 104, "🖱️", L("Nav_ScrollAndGesture"))
    AddSidebarNav(3, 144, "🔒", L("Nav_Lock"))
    AddSidebarNav(4, 184, "⌨️", L("Nav_Shortcuts"))
    AddSidebarNav(5, 224, "ℹ️", L("Nav_About"))

    ; Chân Sidebar: Chỉ hiển thị phiên bản (không lặp tên ứng dụng)
    Gui, Font, s8.5 Norm c888888, Segoe UI
    Gui, Add, Text, x12 y421 w190 h18 Center, % "v" . (AppVersion ? AppVersion : "1.1.0")

    ; Vách phân cách dọc giữa Sidebar và Vùng nội dung
    Gui, Add, Text, x212 y12 w1 h431 0x11

    ; ========================================================
    ; VÙNG NỘI DUNG BÊN PHẢI (TAB2 ẨN HEADER ĐỂ ĐIỀU HƯỚNG MƯỢT)
    ; ========================================================
    Gui, Add, Tab2, x216 y-35 w564 h439 -Theme -Wrap vSettingsTabNav, TabGeneral|TabScrollGesture|TabLock|TabShortcuts|TabAbout

    ; --------------------------------------------------------
    ; TAB 1: CÀI ĐẶT CHUNG && HỆ THỐNG
    ; --------------------------------------------------------
    Gui, Tab, TabGeneral
    AddSettingsTabHeader("Set_HeaderGeneral", "Set_SubGeneral")

    ; Card 1: Cài đặt chung (Khởi động + Ngôn ngữ)
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y58 w536 h92, % L("Set_GroupGeneral")
    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Checkbox, x246 y80 w490 vAutoStart gSaveSettings Checked%AutoStart%, % L("Set_AutoStart")
    Gui, Add, Text, x246 y107 w500 h1 0x10

    Gui, Add, Text, x246 y120 w115, % L("Set_Language")
    chkVI := (CurrentLang = "vi") ? 1 : 0
    chkEN := (CurrentLang = "en") ? 1 : 0
    AddSettingsIcon(366, 121, 16, 16, "image\flag_vn.ico", 312)
    Gui, Add, Radio, x388 y120 w105 vLangVI gOnLangRadio Group Checked%chkVI%, Tiếng Việt
    AddSettingsIcon(506, 121, 16, 16, "image\flag_en.ico", 313)
    Gui, Add, Radio, x528 y120 w90 vLangEN gOnLangRadio Checked%chkEN%, English

    ; Card 2: Đặc quyền hệ thống (UIPI & UIAccess)
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y160 w536 h122, % L("Set_Privilege")

    if (hasPriv = "Admin") {
        Gui, Font, s9.5 Bold c007A00, Segoe UI
        Gui, Add, Text, x246 y183 w500, % "✔ " . L("Set_PrivAdmin")
        Gui, Font, s8.5 Norm c555555, Segoe UI
        Gui, Add, Text, x246 y204 w500, % L("Set_PrivSubAdmin")
    } else if (hasPriv = "UIAccess") {
        Gui, Font, s9.5 Bold c0078D7, Segoe UI
        Gui, Add, Text, x246 y183 w500, % "✔ " . L("Set_PrivUIA")
        Gui, Font, s8.5 Norm c555555, Segoe UI
        Gui, Add, Text, x246 y204 w500, % L("Set_PrivSubUIA")
    } else {
        Gui, Font, s9.5 Bold cC0392B, Segoe UI
        Gui, Add, Text, x246 y183 w335, % "⚠ " . L("Set_PrivStandard")
        Gui, Font, s8.5 Norm c555555, Segoe UI
        Gui, Add, Text, x246 y204 w335, % L("Set_PrivSubStandard")
        Gui, Font, s9 Norm c222222, Segoe UI
        Gui, Add, Button, x590 y183 w156 h30 gRunAsAdmin, % L("Set_RunAdminBtn")
    }

    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x246 y228 w500 h46, % L("Set_PrivHelp")

    ; Card 3: Lưu ý nhanh
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y292 w536 h104, % L("Set_GroupTips")
    Gui, Font, s8.5 Norm c444444, Segoe UI
    Gui, Add, Text, x246 y314 w500 h72, % L("Set_QuickTips")

    ; --------------------------------------------------------
    ; TAB 2: CUỘN && CỬ CHỈ CHUỘT
    ; --------------------------------------------------------
    Gui, Tab, TabScrollGesture
    AddSettingsTabHeader("Set_HeaderScrollGesture", "Set_SubScrollGesture")

    ; Card 1: Bật/tắt, Ứng dụng loại trừ & Phương pháp cuộn
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y58 w536 h106, % L("Set_GroupGesture")
    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Checkbox, x246 y80 w300 vGestureEnabled gOnToggleGestureCheckbox Checked%GestureScrollEnabled%, % L("Set_EnableGesture")
    Gui, Font, s9 Norm c222222, Segoe UI
    Gui, Add, Button, x556 y76 w190 h26 gOpenExcludedAppsGui, % L("Set_ExcludedAppsBtn")
    Gui, Add, Text, x246 y108 w500 h1 0x10

    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Radio, x246 y117 w500 vScrollStyle1 gSaveSettings Group Checked%chkS1%, % L("Set_ScrollStyle1")
    Gui, Add, Radio, x246 y140 w500 vScrollStyle2 gSaveSettings Checked%chkS2%, % L("Set_ScrollStyle2")

    ; Card 2: Thao tác chuột & Cử chỉ trình duyệt (Dùng icon .ico thực tế)
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y174 w536 h224, % L("Set_GroupMouseActions")

    AddMouseActionRow(196, "image\scroll_manual.ico", 314, "Set_ManualScroll", "Set_ManualScrollBtn")
    AddMouseActionRow(221, "image\scroll_auto.ico",   315, "Set_AutoScroll",   "Set_AutoScrollBtn")
    AddMouseActionRow(246, "image\scroll_page.ico",   316, "Set_PgScroll",     "Set_PgScrollBtn")
    AddMouseActionRow(271, "image\mouse_volume.ico",  317, "Set_MouseVolume",  "Set_MouseVolumeBtn")

    Gui, Add, Text, x246 y296 w500 h1 0x10
    Gui, Font, s9 Bold c004499, Segoe UI
    Gui, Add, Text, x246 y305 w500, % L("Set_BrowserGesturesTitle")

    AddBrowserGestureRow(329, "image\L.ico",  301, "Set_Back",     "←",   "image\R.ico",  304, "Set_Forward", "→")
    AddBrowserGestureRow(352, "image\LU.ico", 303, "Set_PrevTab",  "← ↑", "image\LD.ico", 302, "Set_NextTab", "← ↓")
    AddBrowserGestureRow(375, "image\RU.ico", 306, "Set_CloseTab", "→ ↑", "image\RD.ico", 305, "Set_Refresh", "→ ↓")

    ; --------------------------------------------------------
    ; TAB 3: KHÓA BÀN PHÍM && CHUỘT
    ; --------------------------------------------------------
    Gui, Tab, TabLock
    AddSettingsTabHeader("Set_HeaderLock", "Set_SubLock")

    ; Card 1: Thiết lập khóa thiết bị
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y58 w536 h126, % L("Lock_Card1Title")

    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Checkbox, x246 y81 w130 vlockKeyboardEnabled gSaveSettings Checked%lockKeyboardEnabled%, % L("Lock_TargetKB")
    Gui, Add, Checkbox, x382 y81 w120 vmouseLockEnabled gSaveSettings Checked%mouseLockEnabled%, % L("Lock_TargetMouse")
    Gui, Font, s9 Norm c222222, Segoe UI
    Gui, Add, Button, x516 y76 w230 h26 gOpenWhitelistGui, % L("Lock_WhitelistBtn")

    Gui, Add, Text, x246 y110 w500 h1 0x10

    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Checkbox, x246 y121 w260 vautoLockIdleEnabled gOnToggleIdleCheck Checked%autoLockIdleEnabled%, % L("Lock_AutoIdleCheck")
    Gui, Font, s9 Norm c222222, Segoe UI
    Gui, Add, DropDownList, x516 y118 w230 vautoLockIdleMinutesChoice gSaveSettings Choose%selIdleIdx%, %idleMinutesList%

    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Checkbox, x246 y152 w500 vdisableAutoLockScreen gSaveSettings Checked%disableAutoLockScreen%, % L("Lock_PreventSleep")

    ; Card 2: Bảo mật & Mở khóa
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y194 w536 h204, % L("Lock_Card2Title")

    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Checkbox, x246 y216 w500 vwindowsLogonOnly gOnToggleWindowsLogonOnly Checked%windowsLogonOnly%, % L("Lock_WinLogonOnly")

    Gui, Add, Text, x246 y249 w105 vLockKeyPromptLbl, % L("Lock_KeyPrompt")
    Gui, Font, s9 Norm c222222, Segoe UI
    Gui, Add, Edit, x356 y246 w184 h24 vUnlockCodeDisplay ReadOnly Password, %UNLOCK_KEYWORD%
    Gui, Add, Button, x546 y245 w64 h26 gToggleRevealCode vBtnToggleReveal Center, % L("Lock_ShowBtn")
    Gui, Add, Button, x616 y245 w130 h26 gOpenChangeCodeGui vBtnChangeCode, % L("Lock_ChangeCodeBtn")

    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Checkbox, x246 y280 w500 vrequireCodeForTimerEdit gSaveSettings Checked%requireCodeForTimerEdit%, % L("Lock_ReqTimerEditCode")

    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x246 y308 w500 h30 vLockMethodHintTxt, % ("• " . (windowsLogonOnly ? L("Lock_MethodHintWinOnly") : L("Lock_MethodHint")))

    Gui, Add, Text, x246 y343 w500 h1 0x10

    Gui, Font, s9.5 Bold c004499, Segoe UI
    Gui, Add, Button, x246 y354 w500 h34 gActionOpenLockCenter, % L("Lock_CenterBtn")

    ; --------------------------------------------------------
    ; TAB 4: PHÍM TẮT && TIỆN ÍCH
    ; --------------------------------------------------------
    Gui, Tab, TabShortcuts
    AddSettingsTabHeader("Set_HeaderShortcuts", "Set_SubShortcuts")

    ; Card 1: Phím tắt hệ thống
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y58 w536 h234, % L("Set_GroupSystemHotkeys")

    AddShortcutRow(82,  "Icon28",  A_WinDir . "\System32\ddores.dll",  "Set_LockCenter", "Ctrl + Alt + L",   "ActionOpenLockCenter")
    AddShortcutRow(116, "Icon261", A_WinDir . "\System32\shell32.dll", "Set_PastePlain", "Ctrl + Shift + V", "ActionPastePlain")
    AddShortcutRow(150, "Icon3",   A_WinDir . "\System32\SndVol.exe",  "Set_Mute",       "Ctrl + Shift + M", "ActionMute")
    AddShortcutRow(184, "Icon2",   A_WinDir . "\System32\SndVol.exe",  "Set_Volume",     L("Set_VolUpBtn"),    "ActionVolUp",     L("Set_VolDownBtn"),  "ActionVolDown")
    AddShortcutRow(218, "Icon26",  A_WinDir . "\System32\shell32.dll", "Set_Brightness", L("Set_BrightDownBtn"), "ActionBrightDown", L("Set_BrightUpBtn"), "ActionBrightUp")

    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x246 y258 w500 h26, % L("Set_ShortcutsTip")

    ; Card 2: Thao tác nhanh trên khay hệ thống
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y302 w536 h96, % L("Set_GroupTrayActions")

    AddShortcutRow(326, "Icon1", aboutIcon, "Set_TrayToggleLabel", L("Set_TrayToggleBtn"), "ActionToggleGestures")
    Gui, Font, s8.5 Norm c555555, Segoe UI
    Gui, Add, Text, x246 y360 w500 h28, % "• " . L("Set_TrayDblClickTip")

    ; --------------------------------------------------------
    ; TAB 5: THÔNG TIN && BẢN QUYỀN
    ; --------------------------------------------------------
    Gui, Tab, TabAbout
    AddSettingsTabHeader("Set_HeaderAbout", "Set_SubAbout")

    ; Card 1: Thông tin ứng dụng & Liên kết nhanh
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y58 w536 h142, GestureMouse
    Gui, Add, Picture, x246 y82 w44 h44 Icon1, %aboutIcon%

    Gui, Font, s13 Bold c004499, Segoe UI
    Gui, Add, Text, x302 y80 w300, GestureMouse
    Gui, Font, s9 Norm c333333, Segoe UI
    Gui, Add, Text, x302 y104 w300, % L("About_Headline")
    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x302 y124 w300, % L("About_Version")

    Gui, Font, s9 Norm c222222, Segoe UI
    Gui, Add, Button, x616 y82 w130 h30 gOpenDonateLink, % "❤ " . L("About_Donate")

    Gui, Add, Text, x246 y148 w500 h1 0x10

    Gui, Add, Button, x246 y159 w160 h28 gCheckForUpdates, % L("Tray_CheckUpdate")
    Gui, Add, Button, x416 y159 w160 h28 gOpenGitHubLink, GitHub Releases
    Gui, Add, Button, x586 y159 w160 h28 gOpenEmailLink, % L("About_ContactBtn")

    ; Card 2: Giới thiệu & Bản quyền
    Gui, Font, s9.5 Bold c222222, Segoe UI
    Gui, Add, GroupBox, x228 y210 w536 h188, % L("About_GroupDetails")
    Gui, Font, s9 Norm c333333, Segoe UI
    Gui, Add, Text, x246 y233 w500 h156, % L("About_DetailText")

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

    ; Hiển thị giao diện kích thước tinh gọn (w780 h455)
    Gui, Show, w780 h455 Center, % "GestureMouse - " . L("Set_Title")
    SetGuiYellowIcon(hSettingsGui)
return

; ========================================================
; HELPER DỰNG LAYOUT THỐNG NHẤT CHO CÁC TAB & CONTROL
; ========================================================
AddSidebarNav(idx, yPos, iconChar, labelText) {
    indY := yPos + 7
    Gui, Settings:Font, s9.5 Norm c444444, Segoe UI
    Gui, Settings:Add, Progress, x10 y%yPos% w192 h34 BackgroundE5F1FB cE5F1FB vNavBg%idx% -Theme Disabled, 100
    Gui, Settings:Add, Progress, x10 y%indY% w3 h20 Background0067C0 c0067C0 vNavInd%idx% -Theme Disabled, 100
    Gui, Settings:Add, Text, x20 y%yPos% w180 h34 +0x200 +BackgroundTrans gOnNav%idx% vNavTxt%idx%, % "  " . iconChar . "  " . labelText
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

AddMouseActionRow(yPos, icoRelPath, resId, labelKey, descKey) {
    icoY := yPos - 1
    AddSettingsIcon(246, icoY, 18, 18, icoRelPath, resId)
    Gui, Settings:Font, s9 Norm c222222, Segoe UI
    Gui, Settings:Add, Text, x272 y%yPos% w160, % L(labelKey)
    Gui, Settings:Font, s8.5 Norm c555555, Segoe UI
    Gui, Settings:Add, Text, x436 y%yPos% w310, % "→ " . L(descKey)
}

AddBrowserGestureRow(yPos, ico1, res1, key1, sym1, ico2, res2, key2, sym2) {
    AddSettingsIcon(246, yPos, 16, 16, ico1, res1)
    Gui, Settings:Font, s9 Norm c222222, Segoe UI
    Gui, Settings:Add, Text, x270 y%yPos% w155, % L(key1)
    Gui, Settings:Font, s8.5 Bold c004499, Segoe UI
    Gui, Settings:Add, Text, x430 y%yPos% w45, %sym1%

    AddSettingsIcon(500, yPos, 16, 16, ico2, res2)
    Gui, Settings:Font, s9 Norm c222222, Segoe UI
    Gui, Settings:Add, Text, x524 y%yPos% w165, % L(key2)
    Gui, Settings:Font, s8.5 Bold c004499, Segoe UI
    Gui, Settings:Add, Text, x694 y%yPos% w52, %sym2%
}

AddShortcutRow(yPos, iconOpt, iconFile, labelKey, btn1Text, gLabel1, btn2Text := "", gLabel2 := "") {
    icoY := yPos - 1
    btnY := yPos - 4
    if (iconFile != "" && FileExist(iconFile))
        Gui, Settings:Add, Picture, x246 y%icoY% w20 h20 %iconOpt%, %iconFile%
    Gui, Settings:Font, s9.5 Norm c222222, Segoe UI
    Gui, Settings:Add, Text, x274 y%yPos% w252, % L(labelKey)
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

    GuiControl, Settings:, disableAutoLockScreen, %disableAutoLockScreen%
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
    global currentSettingsTab, hSettingsGui
    currentSettingsTab := tabNum
    if (!hSettingsGui)
        return
    Gui, Settings:Default
    GuiControl, Settings:Choose, SettingsTabNav, %tabNum%
    Loop 5 {
        if (A_Index == tabNum) {
            GuiControl, Settings:Show, NavBg%A_Index%
            GuiControl, Settings:Show, NavInd%A_Index%
            Gui, Settings:Font, s9.5 Bold c005FB8, Segoe UI
            GuiControl, Settings:Font, NavTxt%A_Index%
            GuiControl, Settings:+BackgroundTrans, NavTxt%A_Index%
            GuiControl, Settings:MoveDraw, NavTxt%A_Index%
        } else {
            GuiControl, Settings:Hide, NavBg%A_Index%
            GuiControl, Settings:Hide, NavInd%A_Index%
            Gui, Settings:Font, s9.5 Norm c444444, Segoe UI
            GuiControl, Settings:Font, NavTxt%A_Index%
            GuiControl, Settings:+BackgroundTrans, NavTxt%A_Index%
            GuiControl, Settings:MoveDraw, NavTxt%A_Index%
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

    ; Lưu trạng thái giữ màn hình luôn sáng khi khóa
    disableAutoLockScreen := disableAutoLockScreen ? 1 : 0
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, DisableAutoLockScreen, %disableAutoLockScreen%

    ; Cập nhật tray tip
    fnTip := "UpdateTrayTip"
    if (IsFunc(fnTip))
        %fnTip%()
return

OpenGitHubLink:
    Run, https://github.com/ngtrian/GestureMouse/releases
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
