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
global TabScrollNames       := ["Tab1Scroll", "Tab2Scroll", "Tab3Scroll", "ShortcutsScroll"]
global TabScrollHwnds       := [0, 0, 0, 0]
global TabScrollHwndToNum   := {}
global TabCards             := [[], [], [], []]
global TabScrollPos         := [0, 0, 0, 0]
global TabContentH          := [0, 0, 0, 0]
global TabStaticColors      := [{}, {}, {}, {}]

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
            if (!isVisible) {
                Loop, 4 {
                    if (TabScrollHwnds[A_Index] && TabScrollPos[A_Index] != 0)
                        ScrollTabTo(A_Index, 0)
                }
            }
            Gui, Settings:Show, w780 h520 Center, % "GestureMouse - " . L("Set_Title")
            if (currentSettingsTab >= 1 && currentSettingsTab <= 4 && TabScrollHwnds[currentSettingsTab]) {
                SyncTabScrollPanelSize(currentSettingsTab)
                UpdateTabScrollInfo(currentSettingsTab)
                DllCall("RedrawWindow", "Ptr", TabScrollHwnds[currentSettingsTab], "Ptr", 0, "Ptr", 0, "UInt", 0x0185)
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
    Gui, Settings:Color, F3F3F3
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
    RegRead, valSleepUnlim, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, PreventSleepUnlimited
    preventSleepUnlimited := (valSleepUnlim != "") ? (valSleepUnlim ? 1 : 0) : 1
    RegRead, valSleepHrs, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, PreventSleepHours
    preventSleepHours := (valSleepHrs != "" && valSleepHrs >= 0 && valSleepHrs <= 24) ? (valSleepHrs + 0) : 0
    RegRead, valSleepMins, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, PreventSleepMinutes
    preventSleepMinutes := (valSleepMins != "" && valSleepMins >= 0 && valSleepMins <= 59) ? (valSleepMins + 0) : 30

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

    ; ========================================================
    ; VÙNG NỘI DUNG BÊN PHẢI (TAB 1-4 DÙNG CHILD GUI CARD CUỘN DỌC, TAB 5 DÙNG TAB2)
    ; ========================================================
    Gui, Add, Tab2, x216 y-35 w564 h504 +Buttons -Theme -Wrap +0x04000000 vSettingsTabNav +HwndhSettingsTabNav, TabGeneral|TabScrollGesture|TabLock|TabShortcuts|TabAbout

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
    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x228 y483 w415 +BackgroundTrans vSettingsAutoSaveHint, % L("Set_AutoSaveHint")
    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Button, x658 y476 w106 h30 vSettingsCloseBtn gSettingsCloseBtn Default, % L("Set_Close")

    ; Đăng ký tô màu Card trước khi dựng các tab
    OnMessage(0x138, "WM_CTLCOLORSTATIC_SETTINGS")

    ; Dựng các Tab 1-4 theo kiến trúc Card cuộn dọc thống nhất
    TabScrollNames := ["Tab1Scroll", "Tab2Scroll", "Tab3Scroll", "ShortcutsScroll"]
    TabScrollHwnds := [0, 0, 0, 0]
    TabScrollHwndToNum := {}
    TabCards := [[], [], [], []]
    TabScrollPos := [0, 0, 0, 0]
    TabContentH := [0, 0, 0, 0]
    TabStaticColors := [{}, {}, {}, {}]

    isSettingsBuilding := 1
    BuildTab1ScrollPanel(AutoStart, hasPriv)
    BuildTab2ScrollPanel(chkS1, chkS2)
    BuildTab3ScrollPanel(idleMinutesList, selIdleIdx, preventScreenOff, preventSleep)
    BuildShortcutsScrollPanel(aboutIcon)
    isSettingsBuilding := 0

    ; Khởi tạo trạng thái Enable/Disable của control
    GuiControl, Tab3Scroll:Enable%autoLockIdleEnabled%, autoLockIdleMinutesChoice
    UpdatePreventSleepControlsState()
    UpdateLockAuthControlsState(windowsLogonOnly)
    GuiControl, ShortcutsScroll:Enable%AOTEnabled%, AOTHotkeyBtn
    GuiControl, ShortcutsScroll:Enable%AOTEnabled%, AOTBorderEnabled
    GuiControl, ShortcutsScroll:Enable%AOTEnabled%, AOTUnpinAllBtn
    GuiControl, ShortcutsScroll:Enable%ScreenOffEnabled%, ScreenOffHotkeyBtn
    GuiControl, ShortcutsScroll:Enable%WinHopperEnabled%, WinHopperHotkeyBtn
    GuiControl, ShortcutsScroll:Enable%WinHopperEnabled%, WinHopperBackHotkeyBtn
    GuiControl, ShortcutsScroll:Enable%WinHopperEnabled%, WinHopperShowPreview
    UpdateMicControlsState()

    ; Khởi tạo hiển thị tab hiện tại với background sidebar được tô màu
    SwitchSettingsTab(currentSettingsTab ? currentSettingsTab : 1, true)

    ; Đăng ký theo dõi hover, cuộn dọc & lăn chuột cho vùng nội dung
    OnMessage(0x200, "WM_MOUSEMOVE_SETTINGS")
    OnMessage(0x115, "OnShortcutsVScroll")
    OnMessage(0x20A, "OnShortcutsMouseWheel")

    DllCall("SendMessage", "Ptr", hSettingsGui, "UInt", 0x000B, "Ptr", 1, "Ptr", 0) ; WM_SETREDRAW = TRUE
    SetBatchLines, %prevBatchLines%

    ; Khi preload nền: Show với Hide để AHK tính sẵn kích thước w780 h520 & vị trí Center
    ; Khi mở trực tiếp: hiển thị ngay lập tức
    if (isPreload)
        Gui, Settings:Show, Hide w780 h520 Center, % "GestureMouse - " . L("Set_Title")
    else
        Gui, Settings:Show, w780 h520 Center, % "GestureMouse - " . L("Set_Title")
    if (currentSettingsTab >= 1 && currentSettingsTab <= 4 && TabScrollHwnds[currentSettingsTab]) {
        SyncTabScrollPanelSize(currentSettingsTab)
        UpdateTabScrollInfo(currentSettingsTab)
        if (!isPreload)
            DllCall("RedrawWindow", "Ptr", TabScrollHwnds[currentSettingsTab], "Ptr", 0, "Ptr", 0, "UInt", 0x0185)
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
    Gui, Settings:Add, Progress, x10 y%yPos% w192 h34 BackgroundEAEAEA cEAEAEA vNavBg%idx% -Theme Disabled, 100
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

AddSettingsIcon(x, y, w, h, relPath, resId := 0, guiName := "Settings") {
    hPic := 0
    if (A_IsCompiled && resId > 0) {
        Gui, %guiName%:Add, Picture, x%x% y%y% w%w% h%h% Icon-%resId% +HwndhPic, %A_ScriptFullPath%
    } else {
        fullPath := A_ScriptDir . "\" . relPath
        if (FileExist(fullPath))
            Gui, %guiName%:Add, Picture, x%x% y%y% w%w% h%h% +HwndhPic, %fullPath%
    }
    return hPic
}

AddMouseActionRow(card, icoRelPath, resId, labelKey, descKey) {
    yPos := card.curY
    icoY := yPos - 1
    hIco := AddSettingsIcon(28, icoY, 20, 20, icoRelPath, resId, "Tab2Scroll")
    CardAddItem(card, hIco, icoY)
    Gui, Tab2Scroll:Font, s9 Norm c222222, Segoe UI
    Gui, Tab2Scroll:Add, Text, x58 y%yPos% w154 +HwndhLbl, % L(labelKey)
    Gui, Tab2Scroll:Font, s8.5 Norm c555555, Segoe UI
    Gui, Tab2Scroll:Add, Text, x216 y%yPos% w306 +HwndhDesc, % "→ " . L(descKey)
    CardAddItem(card, hLbl, yPos)
    CardAddItem(card, hDesc, yPos)
    card.curY += 26
}

AddBrowserGestureRow(card, hBmp1, labelKey1, tipKey1, hBmp2, labelKey2, tipKey2) {
    global SettingsTooltips
    yPos := card.curY
    badgeY := yPos - 2
    Gui, Tab2Scroll:Font, s9 Norm c222222, Segoe UI
    Gui, Tab2Scroll:Add, Text, x28 y%yPos% w154 +HwndhLbl1, % L(labelKey1)
    CardAddItem(card, hLbl1, yPos)
    if (hBmp1) {
        Gui, Tab2Scroll:Add, Picture, x186 y%badgeY% +0x100 +HwndhBadge1, HBITMAP:*%hBmp1%
        SettingsTooltips[hBadge1] := L(tipKey1)
        CardAddItem(card, hBadge1, badgeY)
    }

    Gui, Tab2Scroll:Font, s9 Norm c222222, Segoe UI
    Gui, Tab2Scroll:Add, Text, x274 y%yPos% w166 +HwndhLbl2, % L(labelKey2)
    CardAddItem(card, hLbl2, yPos)
    if (hBmp2) {
        Gui, Tab2Scroll:Add, Picture, x446 y%badgeY% +0x100 +HwndhBadge2, HBITMAP:*%hBmp2%
        SettingsTooltips[hBadge2] := L(tipKey2)
        CardAddItem(card, hBadge2, badgeY)
    }
    card.curY += 24
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
    GuiControl, Tab1Scroll:, AutoStart, %AutoStart%

    ; Đọc phương pháp cuộn chuột
    RegRead, ScrollStyle, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, ScrollStyle
    if (ErrorLevel || ScrollStyle = "" || ScrollStyle < 1 || ScrollStyle > 2)
        ScrollStyle := 1
    chkS1 := (ScrollStyle = 1) ? 1 : 0
    chkS2 := (ScrollStyle = 2) ? 1 : 0
    GuiControl, Tab2Scroll:, ScrollStyle1, %chkS1%
    GuiControl, Tab2Scroll:, ScrollStyle2, %chkS2%

    ; Đọc trạng thái Cử chỉ chuột
    GuiControl, Tab2Scroll:, GestureEnabled, %GestureScrollEnabled%

    ; Cập nhật cấu hình khóa
    if (IsFunc("LoadLockSettings"))
        LoadLockSettings()

    GuiControl, Tab3Scroll:, lockKeyboardEnabled, %lockKeyboardEnabled%
    GuiControl, Tab3Scroll:, mouseLockEnabled, %mouseLockEnabled%

    GuiControl, Tab3Scroll:, autoLockIdleEnabled, %autoLockIdleEnabled%
    GuiControl, Tab3Scroll:Enable%autoLockIdleEnabled%, autoLockIdleMinutesChoice
    selIdleIdx := GetIdleMinuteIndex(autoLockIdleMinutes)
    GuiControl, Tab3Scroll:Choose, autoLockIdleMinutesChoice, %selIdleIdx%

    GuiControl, Tab3Scroll:, preventScreenOff, %preventScreenOff%
    GuiControl, Tab3Scroll:, preventSleep, %preventSleep%
    GuiControl, Tab3Scroll:, preventSleepUnlimited, %preventSleepUnlimited%
    GuiControl, Tab3Scroll:, preventSleepHours, %preventSleepHours%
    GuiControl, Tab3Scroll:, preventSleepMinutes, %preventSleepMinutes%
    UpdatePreventSleepControlsState()
    GuiControl, Tab3Scroll:, alwaysShowLockToast, %alwaysShowLockToast%
    GuiControl, Tab3Scroll:, requireCodeForTimerEdit, %requireCodeForTimerEdit%
    GuiControl, Tab3Scroll:, UnlockCodeDisplay, %UNLOCK_KEYWORD%
    UpdateLockAuthControlsState(windowsLogonOnly)

    chkVI := (CurrentLang = "vi") ? 1 : 0
    chkEN := (CurrentLang = "en") ? 1 : 0
    GuiControl, Tab1Scroll:, LangVI, %chkVI%
    GuiControl, Tab1Scroll:, LangEN, %chkEN%

    GuiControl, ShortcutsScroll:, AOTEnabled, %AOTEnabled%
    GuiControl, ShortcutsScroll:, AOTBorderEnabled, %AOTBorderEnabled%
    if (IsFunc("FormatAOTHotkeyText"))
        GuiControl, ShortcutsScroll:, AOTHotkeyBtn, % FormatAOTHotkeyText(AOTHotkey)
    GuiControl, ShortcutsScroll:Enable%AOTEnabled%, AOTHotkeyBtn
    GuiControl, ShortcutsScroll:Enable%AOTEnabled%, AOTBorderEnabled
    GuiControl, ShortcutsScroll:Enable%AOTEnabled%, AOTUnpinAllBtn

    GuiControl, ShortcutsScroll:, ScreenOffEnabled, %ScreenOffEnabled%
    if (IsFunc("FormatScreenOffHotkeyText"))
        GuiControl, ShortcutsScroll:, ScreenOffHotkeyBtn, % FormatScreenOffHotkeyText(ScreenOffHotkey)
    GuiControl, ShortcutsScroll:Enable%ScreenOffEnabled%, ScreenOffHotkeyBtn

    GuiControl, ShortcutsScroll:, WinHopperEnabled, %WinHopperEnabled%
    GuiControl, ShortcutsScroll:, WinHopperShowPreview, %WinHopperShowPreview%
    if (IsFunc("FormatWinHopperHotkeyText")) {
        GuiControl, ShortcutsScroll:, WinHopperHotkeyBtn, % FormatWinHopperHotkeyText(WinHopperHotkey)
        GuiControl, ShortcutsScroll:, WinHopperBackHotkeyBtn, % FormatWinHopperHotkeyText(WinHopperBackHotkey)
    }
    GuiControl, ShortcutsScroll:Enable%WinHopperEnabled%, WinHopperHotkeyBtn
    GuiControl, ShortcutsScroll:Enable%WinHopperEnabled%, WinHopperBackHotkeyBtn
    GuiControl, ShortcutsScroll:Enable%WinHopperEnabled%, WinHopperShowPreview
    GuiControl, ShortcutsScroll:Enable%WinHopperEnabled%, WinHopperHotkeyBtn
    GuiControl, ShortcutsScroll:Enable%WinHopperEnabled%, WinHopperBackHotkeyBtn
    GuiControl, ShortcutsScroll:Enable%WinHopperEnabled%, WinHopperShowPreview

    SyncMicControlsFromState()
    UpdateAllCardSummaries()
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
    global currentSettingsTab, hSettingsGui, hSettingsTabNav, TabScrollHwnds, SidebarNavBitmaps, SidebarIconHwnds
    ClearSettingsTooltip()
    if (tabNum < 1 || tabNum > 5)
        tabNum := 1
    prevTab := currentSettingsTab
    currentSettingsTab := tabNum
    if (!hSettingsGui)
        return
    Gui, Settings:Default

    Loop, 4 {
        hPanel := TabScrollHwnds[A_Index]
        if (!hPanel)
            continue
        if (A_Index == tabNum) {
            SyncTabScrollPanelSize(A_Index)
            DllCall("SetWindowPos", "Ptr", hPanel, "Ptr", 0, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0053) ; HWND_TOP|SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE|SWP_SHOWWINDOW
            UpdateTabScrollInfo(A_Index)
            DllCall("RedrawWindow", "Ptr", hPanel, "Ptr", 0, "Ptr", 0, "UInt", 0x0185)
        } else {
            DllCall("ShowWindow", "Ptr", hPanel, "Int", 0) ; SW_HIDE
        }
    }

    if (tabNum = 5) {
        GuiControl, Settings:Show, SettingsTabNav
        GuiControl, Settings:Choose, SettingsTabNav, 5
    } else {
        GuiControl, Settings:Hide, SettingsTabNav
    }

    ; Khóa vẽ tạm thời vùng sidebar để gom toàn bộ thay đổi vào 1 lần repaint duy nhất, tránh chớp
    if (!skipRedraw)
        DllCall("SendMessage", "Ptr", hSettingsGui, "UInt", 0x000B, "Ptr", 0, "Ptr", 0) ; WM_SETREDRAW = FALSE

    Loop 5 {
        isActive := (A_Index == tabNum)
        if (!skipRedraw && A_Index != tabNum && A_Index != prevTab)
            continue
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
        if (SidebarIconHwnds.HasKey(A_Index) && SidebarNavBitmaps.HasKey(A_Index)) {
            hBmp := isActive ? SidebarNavBitmaps[A_Index].active : SidebarNavBitmaps[A_Index].inactive
            DllCall("SendMessage", "Ptr", SidebarIconHwnds[A_Index], "UInt", 0x0172, "Ptr", 0, "Ptr", hBmp)
        }
    }

    if (!skipRedraw) {
        DllCall("SendMessage", "Ptr", hSettingsGui, "UInt", 0x000B, "Ptr", 1, "Ptr", 0) ; WM_SETREDRAW = TRUE
        VarSetCapacity(rcSidebar, 16, 0)
        NumPut(215, rcSidebar, 8, "Int")
        NumPut(472, rcSidebar, 12, "Int")
        DllCall("RedrawWindow", "Ptr", hSettingsGui, "Ptr", &rcSidebar, "Ptr", 0, "UInt", 0x0185)
    }
}

; ========================================================
; THAO TÁC XEM/ẨN MÃ MỞ KHÓA (REVEAL / HIDE CODE)
; ========================================================
ToggleRevealCode:
    isCodeRevealed := !isCodeRevealed
    if (isCodeRevealed) {
        GuiControl, Tab3Scroll:-Password, UnlockCodeDisplay
    } else {
        GuiControl, Tab3Scroll:+Password, UnlockCodeDisplay
    }
    UpdateRevealButtonVisual(isCodeRevealed)
    GuiControl, Tab3Scroll:, UnlockCodeDisplay, %UNLOCK_KEYWORD%
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
    GuiControl, Tab3Scroll:, UnlockCodeDisplay, %UNLOCK_KEYWORD%

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
    Gui, Tab3Scroll:Submit, NoHide
    GuiControl, Tab3Scroll:Enable%autoLockIdleEnabled%, autoLockIdleMinutesChoice
    Gosub, SaveSettings
return

OnTogglePreventSleep:
    Gui, Tab3Scroll:Submit, NoHide
    UpdatePreventSleepControlsState()
    Gosub, SaveSettings
return

OnChangePreventSleepTime:
    if (isSettingsBuilding)
        return
    Gui, Tab3Scroll:Submit, NoHide
    if (preventSleepHours = "" || preventSleepMinutes = "")
        return
    Gosub, SaveSettings
return

UpdatePreventSleepControlsState() {
    global preventSleep, preventSleepUnlimited
    enUnlim := preventSleep ? 1 : 0
    enTime  := (preventSleep && !preventSleepUnlimited) ? 1 : 0
    GuiControl, Tab3Scroll:Enable%enUnlim%, preventSleepUnlimited
    GuiControl, Tab3Scroll:Enable%enTime%, preventSleepHours
    GuiControl, Tab3Scroll:Enable%enTime%, UdSleepHrs
    GuiControl, Tab3Scroll:Enable%enTime%, TxtSleepHrs
    GuiControl, Tab3Scroll:Enable%enTime%, preventSleepMinutes
    GuiControl, Tab3Scroll:Enable%enTime%, UdSleepMins
    GuiControl, Tab3Scroll:Enable%enTime%, TxtSleepMins
}

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
    GuiControl, Tab3Scroll:, UnlockModeCustom, %enableCustom%
    GuiControl, Tab3Scroll:, UnlockModeWinOnly, %winOnlyFlag%
    if (winOnlyFlag && isCodeRevealed) {
        isCodeRevealed := 0
        GuiControl, Tab3Scroll:+Password, UnlockCodeDisplay
        UpdateRevealButtonVisual(false)
        GuiControl, Tab3Scroll:, UnlockCodeDisplay, %UNLOCK_KEYWORD%
    }
    GuiControl, Tab3Scroll:Enable%enableCustom%, LockKeyPromptLbl
    GuiControl, Tab3Scroll:Enable%enableCustom%, UnlockCodeDisplay
    GuiControl, Tab3Scroll:Enable%enableCustom%, BtnToggleReveal
    GuiControl, Tab3Scroll:Enable%enableCustom%, BtnChangeCode
    GuiControl, Tab3Scroll:Enable%enableCustom%, requireCodeForTimerEdit
}

OnLangRadio:
    Gui, Tab1Scroll:Submit, NoHide
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
    Gui, Tab2Scroll:Submit, NoHide
    if (GestureEnabled != GestureScrollEnabled) {
        ToggleGestureScroll()
    }
    UpdateAllCardSummaries()
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
    Gui, Tab1Scroll:Submit, NoHide
    Gui, Tab2Scroll:Submit, NoHide
    Gui, Tab3Scroll:Submit, NoHide

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
    preventSleepUnlimited := preventSleepUnlimited ? 1 : 0
    preventSleepHours := (preventSleepHours != "" && preventSleepHours >= 0) ? Floor(preventSleepHours) : 0
    if (preventSleepHours > 24)
        preventSleepHours := 24
    preventSleepMinutes := (preventSleepMinutes != "" && preventSleepMinutes >= 0) ? Floor(preventSleepMinutes) : 0
    if (preventSleepMinutes > 59)
        preventSleepMinutes := 59
    alwaysShowLockToast := alwaysShowLockToast ? 1 : 0
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, PreventScreenOff, %preventScreenOff%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, PreventSleep, %preventSleep%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, PreventSleepUnlimited, %preventSleepUnlimited%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, PreventSleepHours, %preventSleepHours%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, PreventSleepMinutes, %preventSleepMinutes%
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AlwaysShowLockToast, %alwaysShowLockToast%
    if (IsFunc("ApplyLockPowerPolicy"))
        ApplyLockPowerPolicy()

    ; Cập nhật tray tip
    fnTip := "UpdateTrayTip"
    if (IsFunc(fnTip))
        %fnTip%()
    UpdateAllCardSummaries()
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
    UpdateShortcutsCardSummaries()
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
    global AOTHotkey
    ShowHotkeyPickerDialog({id: "aot"
        , title: L("AOT_ChangeHotkeyBtn")
        , prompt: L("AOT_HotkeyPrompt")
        , current: AOTHotkey
        , default: "^!t"
        , allowSingleModifier: false
        , allowMouse: true
        , allowClear: true
        , onSave: Func("SavePickedAOTHotkey")})
return

SavePickedAOTHotkey(newHk) {
    global AOTHotkey
    AOTHotkey := newHk
    RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, AOTHotkey, %AOTHotkey%
    GuiControl, ShortcutsScroll:, AOTHotkeyBtn, % FormatHotkeyText(AOTHotkey)
    UpdateShortcutsCardSummaries()
}

; ========================================================
; TẮT MÀN HÌNH NHANH (SCREEN OFF)
; ========================================================
OnToggleScreenOffEnabled:
    Gui, ShortcutsScroll:Submit, NoHide
    ScreenOffEnabled := ScreenOffEnabled ? 1 : 0
    GuiControl, ShortcutsScroll:Enable%ScreenOffEnabled%, ScreenOffHotkeyBtn
    GuiControl, ShortcutsScroll:Enable%WinHopperEnabled%, WinHopperHotkeyBtn
    GuiControl, ShortcutsScroll:Enable%WinHopperEnabled%, WinHopperBackHotkeyBtn
    GuiControl, ShortcutsScroll:Enable%WinHopperEnabled%, WinHopperShowPreview
    if (IsFunc("SaveScreenOffSettings"))
        SaveScreenOffSettings()
    if (IsFunc("ApplyScreenOffHotkey"))
        ApplyScreenOffHotkey()
    if (IsFunc("RebuildTrayMenu"))
        RebuildTrayMenu()
    UpdateShortcutsCardSummaries()
return

; ========================================================
; CHẶN POPUP TỰ ĐỘNG (POPUP BLOCKER)
; ========================================================
OnTogglePopupBlockerEnabled:
    Gui, ShortcutsScroll:Submit, NoHide
    PopupBlockerEnabled := PopupBlockerEnabled ? 1 : 0
    if (IsFunc("SavePopupBlockerSettings"))
        SavePopupBlockerSettings()
    if (IsFunc("ApplyPopupBlockerState"))
        ApplyPopupBlockerState()
    if (IsFunc("RebuildTrayMenu"))
        RebuildTrayMenu()
    if (IsFunc("UpdateTrayTip"))
        UpdateTrayTip()
    UpdateShortcutsCardSummaries()
return

OnOpenPopupBlockerMgr:
    if (IsFunc("OpenPopupBlockerGui"))
        OpenPopupBlockerGui()
return

OnQuickPickPopupTarget:
    if (IsFunc("StartPopupWindowPicker"))
        StartPopupWindowPicker("quick")
return

OnChangePopupPickHotkey:
    global PopupPickHotkey
    ShowHotkeyPickerDialog({id: "popuppick"
        , title: L("Popup_ChangeHotkeyBtn")
        , prompt: L("Popup_HotkeyPrompt")
        , current: PopupPickHotkey
        , default: "^!p"
        , allowSingleModifier: false
        , allowMouse: true
        , allowClear: true
        , onSave: Func("SavePickedPopupPickHotkey")})
return

SavePickedPopupPickHotkey(newHk) {
    global PopupPickHotkey
    PopupPickHotkey := newHk
    if (IsFunc("SavePopupBlockerSettings"))
        SavePopupBlockerSettings()
    if (IsFunc("ApplyPopupPickHotkey"))
        ApplyPopupPickHotkey()
    GuiControl, ShortcutsScroll:, PopupPickHotkeyBtn, % FormatHotkeyText(PopupPickHotkey)
    if (IsFunc("RebuildTrayMenu"))
        RebuildTrayMenu()
    UpdateShortcutsCardSummaries()
}

SyncPopupBlockerSettingsUI() {
    global PopupBlockerEnabled, hSettingsGui
    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) {
        GuiControl, ShortcutsScroll:, PopupBlockerEnabled, % (PopupBlockerEnabled ? 1 : 0)
        UpdateShortcutsCardSummaries()
    }
}

OnChangeScreenOffHotkey:
    global ScreenOffHotkey
    ShowHotkeyPickerDialog({id: "screenoff"
        , title: L("ScreenOff_ChangeHotkeyBtn")
        , prompt: L("ScreenOff_HotkeyPrompt")
        , current: ScreenOffHotkey
        , default: "#!s"
        , allowSingleModifier: false
        , allowMouse: true
        , allowClear: true
        , onSave: Func("SavePickedScreenOffHotkey")})
return

SavePickedScreenOffHotkey(newHk) {
    global ScreenOffHotkey
    ScreenOffHotkey := newHk
    if (IsFunc("SaveScreenOffSettings"))
        SaveScreenOffSettings()
    GuiControl, ShortcutsScroll:, ScreenOffHotkeyBtn, % FormatHotkeyText(ScreenOffHotkey)
    if (IsFunc("RebuildTrayMenu"))
        RebuildTrayMenu()
    UpdateShortcutsCardSummaries()
}

OnTestScreenOff:
    if (IsFunc("TurnOffMonitor"))
        TurnOffMonitor(false)
return

; ========================================================
; WINDOW HOPPER (CHUYỂN CỬA SỔ CÙNG ỨNG DỤNG)
; ========================================================
OnToggleWinHopperEnabled:
    Gui, ShortcutsScroll:Submit, NoHide
    WinHopperEnabled := WinHopperEnabled ? 1 : 0
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, WinHopperEnabled, %WinHopperEnabled%
    GuiControl, ShortcutsScroll:Enable%WinHopperEnabled%, WinHopperHotkeyBtn
    GuiControl, ShortcutsScroll:Enable%WinHopperEnabled%, WinHopperBackHotkeyBtn
    GuiControl, ShortcutsScroll:Enable%WinHopperEnabled%, WinHopperShowPreview
    if (IsFunc("ApplyWindowHopperHotkeys"))
        ApplyWindowHopperHotkeys()
    UpdateShortcutsCardSummaries()
return

OnToggleWinHopperPreview:
    Gui, ShortcutsScroll:Submit, NoHide
    WinHopperShowPreview := WinHopperShowPreview ? 1 : 0
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, WinHopperShowPreview, %WinHopperShowPreview%
return

OnChangeWinHopperFwdHotkey:
    global WinHopperHotkey
    ShowHotkeyPickerDialog({id: "winhopper_fwd"
        , title: L("WH_ChangeFwdBtn")
        , prompt: L("WH_HotkeyPrompt")
        , current: WinHopperHotkey
        , default: "!vkC0"
        , allowSingleModifier: false
        , allowMouse: false
        , allowClear: true
        , onSave: Func("SavePickedWinHopperFwdHotkey")})
return

SavePickedWinHopperFwdHotkey(newHk) {
    global WinHopperHotkey
    WinHopperHotkey := newHk
    RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, WinHopperHotkey, %WinHopperHotkey%
    GuiControl, ShortcutsScroll:, WinHopperHotkeyBtn, % FormatHotkeyText(WinHopperHotkey)
    if (IsFunc("ApplyWindowHopperHotkeys"))
        ApplyWindowHopperHotkeys()
    UpdateShortcutsCardSummaries()
}

OnChangeWinHopperBackHotkey:
    global WinHopperBackHotkey
    ShowHotkeyPickerDialog({id: "winhopper_back"
        , title: L("WH_ChangeBackBtn")
        , prompt: L("WH_HotkeyPrompt")
        , current: WinHopperBackHotkey
        , default: "!+vkC0"
        , allowSingleModifier: false
        , allowMouse: false
        , allowClear: true
        , onSave: Func("SavePickedWinHopperBackHotkey")})
return

SavePickedWinHopperBackHotkey(newHk) {
    global WinHopperBackHotkey
    WinHopperBackHotkey := newHk
    RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, WinHopperBackHotkey, %WinHopperBackHotkey%
    GuiControl, ShortcutsScroll:, WinHopperBackHotkeyBtn, % FormatHotkeyText(WinHopperBackHotkey)
    if (IsFunc("ApplyWindowHopperHotkeys"))
        ApplyWindowHopperHotkeys()
    UpdateShortcutsCardSummaries()
}

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

    if (currentSettingsTab >= 1 && currentSettingsTab <= 4 && TabScrollHwnds[currentSettingsTab]) {
        SyncTabScrollPanelSize(currentSettingsTab)
        UpdateTabScrollInfo(currentSettingsTab)
    }
}

SyncTabScrollPanelSize(tabNum) {
    global hSettingsGui, TabScrollHwnds
    hPanel := TabScrollHwnds[tabNum]
    if (!hSettingsGui || !hPanel)
        return
    VarSetCapacity(rc, 16, 0)
    DllCall("GetClientRect", "Ptr", hSettingsGui, "Ptr", &rc)
    clientW := NumGet(rc, 8, "Int")
    clientH := NumGet(rc, 12, "Int")
    scale := A_ScreenDPI / 96.0
    if (clientW <= 0 || clientH <= 0) {
        clientW := Round(780 * scale)
        clientH := Round(520 * scale)
    }
    leftPx := Round(216 * scale)
    bottomMarginPx := Round(48 * scale)
    panelW := (clientW > leftPx) ? (clientW - leftPx) : Round(564 * scale)
    panelH := (clientH > bottomMarginPx) ? (clientH - bottomMarginPx) : Round(472 * scale)
    DllCall("SetWindowPos", "Ptr", hPanel, "Ptr", 0, "Int", leftPx, "Int", 0, "Int", panelW, "Int", panelH, "UInt", 0x0010) ; HWND_TOP|SWP_NOACTIVATE
}

; ========================================================
; TAB 1: CÀI ĐẶT CHUNG && HỆ THỐNG (CARD CUỘN DỌC)
; ========================================================
BuildTab1ScrollPanel(initAutoStart, hasPriv) {
    global
    BeginCardTab(1, "Tab1Scroll", L("Set_HeaderGeneral"), L("Set_SubGeneral"))

    ; Card 1: Cài đặt chung (Khởi động + Ngôn ngữ)
    c1 := BeginCard(1, "Tab1Scroll", "t1_gen", L("Set_GroupGeneral"), 1, "OnToggleT1Gen")
    y := c1.curY
    Gui, Tab1Scroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, Tab1Scroll:Add, Checkbox, x28 y%y% w490 vAutoStart gSaveSettings Checked%initAutoStart% +HwndhChkAuto, % L("Set_AutoStart")
    CardAddItem(c1, hChkAuto, y)
    c1.curY += 30

    y := c1.curY
    Gui, Tab1Scroll:Add, Text, x28 y%y% w142 +HwndhLangLbl, % L("Set_Language")
    CardAddItem(c1, hLangLbl, y)
    chkVI := (CurrentLang = "vi") ? 1 : 0
    chkEN := (CurrentLang = "en") ? 1 : 0
    hFlagVn := AddSettingsIcon(176, y + 1, 16, 16, "image\flag_vn.ico", 312, "Tab1Scroll")
    Gui, Tab1Scroll:Add, Radio, x198 y%y% w105 vLangVI gOnLangRadio Group Checked%chkVI% +HwndhRadVi, Tiếng Việt
    hFlagEn := AddSettingsIcon(316, y + 1, 16, 16, "image\flag_en.ico", 313, "Tab1Scroll")
    Gui, Tab1Scroll:Add, Radio, x338 y%y% w90 vLangEN gOnLangRadio Checked%chkEN% +HwndhRadEn, English
    CardAddItem(c1, hFlagVn, y + 1)
    CardAddItem(c1, hRadVi, y)
    CardAddItem(c1, hFlagEn, y + 1)
    CardAddItem(c1, hRadEn, y)
    c1.curY += 24
    EndCard(c1, 8)

    ; Card 2: Đặc quyền hệ thống (UIPI & UIAccess)
    c2 := BeginCard(1, "Tab1Scroll", "t1_priv", L("Set_Privilege"), 1, "OnToggleT1Priv")
    y := c2.curY
    if (hasPriv = "Admin") {
        Gui, Tab1Scroll:Font, s9.5 Bold c007A00, Segoe UI
        Gui, Tab1Scroll:Add, Text, x28 y%y% w490 +HwndhPrivTitle, % "✔ " . L("Set_PrivAdmin")
        Gui, Tab1Scroll:Font, s8.5 Norm c555555, Segoe UI
        Gui, Tab1Scroll:Add, Text, % "x28 y" . (y + 21) . " w490 +HwndhPrivSub", % L("Set_PrivSubAdmin")
        CardAddItem(c2, hPrivTitle, y)
        CardAddItem(c2, hPrivSub, y + 21)
    } else if (hasPriv = "UIAccess") {
        Gui, Tab1Scroll:Font, s9.5 Bold c0078D7, Segoe UI
        Gui, Tab1Scroll:Add, Text, x28 y%y% w490 +HwndhPrivTitle, % "✔ " . L("Set_PrivUIA")
        Gui, Tab1Scroll:Font, s8.5 Norm c555555, Segoe UI
        Gui, Tab1Scroll:Add, Text, % "x28 y" . (y + 21) . " w490 +HwndhPrivSub", % L("Set_PrivSubUIA")
        CardAddItem(c2, hPrivTitle, y)
        CardAddItem(c2, hPrivSub, y + 21)
    } else {
        Gui, Tab1Scroll:Font, s9.5 Bold cC0392B, Segoe UI
        Gui, Tab1Scroll:Add, Text, x28 y%y% w328 +HwndhPrivTitle, % "⚠ " . L("Set_PrivStandard")
        Gui, Tab1Scroll:Font, s8.5 Norm c555555, Segoe UI
        Gui, Tab1Scroll:Add, Text, % "x28 y" . (y + 21) . " w328 +HwndhPrivSub", % L("Set_PrivSubStandard")
        Gui, Tab1Scroll:Font, s9 Norm c222222, Segoe UI
        Gui, Tab1Scroll:Add, Button, x364 y%y% w156 h30 gRunAsAdmin +HwndhPrivBtn, % L("Set_RunAdminBtn")
        CardAddItem(c2, hPrivTitle, y)
        CardAddItem(c2, hPrivSub, y + 21)
        CardAddItem(c2, hPrivBtn, y)
    }
    c2.curY += 44
    y := c2.curY
    Gui, Tab1Scroll:Font, s8.5 Norm c666666, Segoe UI
    Gui, Tab1Scroll:Add, Text, x28 y%y% w490 h46 +HwndhPrivHelp, % L("Set_PrivHelp")
    CardAddItem(c2, hPrivHelp, y)
    c2.curY += 46
    EndCard(c2, 8)

    ; Card 3: Lưu ý nhanh
    c3 := BeginCard(1, "Tab1Scroll", "t1_tips", L("Set_GroupTips"), 1, "OnToggleT1Tips")
    y := c3.curY
    Gui, Tab1Scroll:Font, s8.5 Norm c444444, Segoe UI
    Gui, Tab1Scroll:Add, Text, x28 y%y% w490 h72 +HwndhTipsTxt, % L("Set_QuickTips")
    CardAddItem(c3, hTipsTxt, y)
    c3.curY += 72
    EndCard(c3, 8)

    Gui, Tab1Scroll:Show, Hide x216 y0 w564 h472
    LayoutCardTab(1, true)
}

; ========================================================
; TAB 2: CUỘN && CỬ CHỈ CHUỘT (CARD CUỘN DỌC)
; ========================================================
BuildTab2ScrollPanel(chkS1, chkS2) {
    global
    BeginCardTab(2, "Tab2Scroll", L("Set_HeaderScrollGesture"), L("Set_SubScrollGesture"))

    ; Card 1: Bật/tắt, Ứng dụng loại trừ & Phương pháp cuộn
    c1 := BeginCard(2, "Tab2Scroll", "t2_gesture", L("Set_GroupGesture"), 1, "OnToggleT2Gesture")
    y := c1.curY
    Gui, Tab2Scroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, Tab2Scroll:Add, Checkbox, % "x28 y" . (y + 2) . " w294 vGestureEnabled gOnToggleGestureCheckbox Checked" . GestureScrollEnabled . " +HwndhChkGest", % L("Set_EnableGesture")
    Gui, Tab2Scroll:Font, s9 Norm c222222, Segoe UI
    Gui, Tab2Scroll:Add, Button, x330 y%y% w190 h26 gOpenExcludedAppsGui +HwndhBtnExcl, % L("Set_ExcludedAppsBtn")
    CardAddItem(c1, hChkGest, y + 2)
    CardAddItem(c1, hBtnExcl, y)
    c1.curY += 34

    y := c1.curY
    Gui, Tab2Scroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, Tab2Scroll:Add, Radio, x28 y%y% w492 vScrollStyle1 gSaveSettings Group Checked%chkS1% +HwndhRadS1, % L("Set_ScrollStyle1")
    CardAddItem(c1, hRadS1, y)
    c1.curY += 22
    y := c1.curY
    Gui, Tab2Scroll:Add, Radio, x28 y%y% w492 vScrollStyle2 gSaveSettings Checked%chkS2% +HwndhRadS2, % L("Set_ScrollStyle2")
    CardAddItem(c1, hRadS2, y)
    c1.curY += 24
    EndCard(c1, 8)

    ; Card 2: Thao tác chuột & Cử chỉ trình duyệt
    c2 := BeginCard(2, "Tab2Scroll", "t2_actions", L("Set_GroupMouseActions"), 1, "OnToggleT2Actions")
    AddMouseActionRow(c2, "image\scroll_manual.ico", 314, "Set_ManualScroll", "Set_ManualScrollBtn")
    AddMouseActionRow(c2, "image\scroll_auto.ico",   315, "Set_AutoScroll",   "Set_AutoScrollBtn")
    AddMouseActionRow(c2, "image\scroll_page.ico",   316, "Set_PgScroll",     "Set_PgScrollBtn")
    AddMouseActionRow(c2, "image\mouse_volume.ico",  317, "Set_MouseVolume",  "Set_MouseVolumeBtn")

    c2.curY += 4
    y := c2.curY
    Gui, Tab2Scroll:Font, s9 Bold c004499, Segoe UI
    Gui, Tab2Scroll:Add, Text, x28 y%y% w492 +HwndhBrTitle, % L("Set_BrowserGesturesTitle")
    CardAddItem(c2, hBrTitle, y)
    c2.curY += 24

    AddBrowserGestureRow(c2, GestureBadgeBitmaps["L"],  "Set_Back",     "Set_TipGestureL",  GestureBadgeBitmaps["R"],  "Set_Forward", "Set_TipGestureR")
    AddBrowserGestureRow(c2, GestureBadgeBitmaps["LU"], "Set_PrevTab",  "Set_TipGestureLU", GestureBadgeBitmaps["LD"], "Set_NextTab", "Set_TipGestureLD")
    AddBrowserGestureRow(c2, GestureBadgeBitmaps["RU"], "Set_CloseTab", "Set_TipGestureRU", GestureBadgeBitmaps["RD"], "Set_Refresh", "Set_TipGestureRD")
    EndCard(c2, 8)

    Gui, Tab2Scroll:Show, Hide x216 y0 w564 h472
    LayoutCardTab(2, true)
}

; ========================================================
; TAB 3: KHÓA BÀN PHÍM && CHUỘT (CARD CUỘN DỌC)
; ========================================================
BuildTab3ScrollPanel(idleMinutesList, selIdleIdx, initPreventScreenOff, initPreventSleep) {
    global

    BeginCardTab(3, "Tab3Scroll", L("Set_HeaderLock"), L("Set_SubLock"), 346)
    Gui, Tab3Scroll:Font, s8.5 Bold c004499, Segoe UI
    Gui, Tab3Scroll:Add, Button, x368 y6 w168 h34 +0x2000 gActionOpenLockCenter +HwndhBtnLockCenterHeader, % L("Lock_CenterBtnTwoLine")
    SettingsTooltips[hBtnLockCenterHeader] := L("Lock_CenterBtnTip")

    ; Card 1: Thiết lập khóa thiết bị
    c1 := BeginCard(3, "Tab3Scroll", "t3_target", L("Lock_Card1Title"), 1, "OnToggleT3Target")
    y := c1.curY
    Gui, Tab3Scroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, Tab3Scroll:Add, Picture, x28 y%y% w22 h22 Icon28 +HwndhPicKB, %A_WinDir%\System32\ddores.dll
    Gui, Tab3Scroll:Add, Checkbox, % "x54 y" . (y + 1) . " w116 h22 vlockKeyboardEnabled gSaveSettings Checked" . lockKeyboardEnabled . " +HwndhChkKB", % L("Lock_TargetKB")
    Gui, Tab3Scroll:Add, Picture, x176 y%y% w22 h22 Icon32 +HwndhPicMs, %A_WinDir%\System32\ddores.dll
    Gui, Tab3Scroll:Add, Checkbox, % "x202 y" . (y + 1) . " w96 h22 vmouseLockEnabled gSaveSettings Checked" . mouseLockEnabled . " +HwndhChkMs", % L("Lock_TargetMouse")
    Gui, Tab3Scroll:Font, s9 Norm c222222, Segoe UI
    Gui, Tab3Scroll:Add, Button, x304 y%y% w216 h26 gOpenWhitelistGui +HwndhBtnWL, % L("Lock_WhitelistBtn")
    CardAddItem(c1, hPicKB, y)
    CardAddItem(c1, hChkKB, y + 1)
    CardAddItem(c1, hPicMs, y)
    CardAddItem(c1, hChkMs, y + 1)
    CardAddItem(c1, hBtnWL, y)
    c1.curY += 32

    y := c1.curY
    Gui, Tab3Scroll:Font, s9.5 Norm c222222, Segoe UI
    if (LockTabIcons["idle"]) {
        Gui, Tab3Scroll:Add, Picture, % "x28 y" . (y + 2) . " w20 h20 +HwndhPicIdle", % "HICON:*" . LockTabIcons["idle"]
        CardAddItem(c1, hPicIdle, y + 2)
    }
    Gui, Tab3Scroll:Add, Checkbox, % "x54 y" . (y + 3) . " w244 vautoLockIdleEnabled gOnToggleIdleCheck Checked" . autoLockIdleEnabled . " +HwndhChkIdle", % L("Lock_AutoIdleCheck")
    Gui, Tab3Scroll:Font, s9 Norm c222222, Segoe UI
    Gui, Tab3Scroll:Add, DropDownList, x304 y%y% w216 vautoLockIdleMinutesChoice gSaveSettings Choose%selIdleIdx% +HwndhDdlIdle, %idleMinutesList%
    CardAddItem(c1, hChkIdle, y + 3)
    CardAddItem(c1, hDdlIdle, y)
    c1.curY += 28
    EndCard(c1, 8)

    ; Card 2: Hành vi khi đang khóa
    c2 := BeginCard(3, "Tab3Scroll", "t3_behavior", L("Lock_Card2BehaviorTitle"), 1, "OnToggleT3Behavior")
    y := c2.curY
    Gui, Tab3Scroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, Tab3Scroll:Add, Checkbox, x28 y%y% w240 h22 vpreventScreenOff gSaveSettings Checked%initPreventScreenOff% +HwndhChkScrOff, % L("Lock_PreventScreenOff")
    Gui, Tab3Scroll:Font, s8.5 Norm c666666, Segoe UI
    Gui, Tab3Scroll:Add, Text, % "x276 y" . (y + 3) . " w244 h18 +Right +HwndhPwrHint", % L("Lock_PowerScopeHint")
    CardAddItem(c2, hChkScrOff, y)
    CardAddItem(c2, hPwrHint,   y + 3)
    c2.curY += 28

    y := c2.curY
    Gui, Tab3Scroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, Tab3Scroll:Add, Checkbox, x28 y%y% w132 h22 vpreventSleep gOnTogglePreventSleep Checked%initPreventSleep% +HwndhChkSleep, % L("Lock_PreventSleep")
    Gui, Tab3Scroll:Add, Checkbox, x164 y%y% w120 h22 vpreventSleepUnlimited gOnTogglePreventSleep Checked%preventSleepUnlimited% +HwndhChkSleepUnlim, % L("Lock_PreventSleepUnlimited")
    Gui, Tab3Scroll:Add, Edit, x288 y%y% w44 h22 Number Right vpreventSleepHours gOnChangePreventSleepTime +HwndhEdtSleepHrs
    Gui, Tab3Scroll:Add, UpDown, Range0-24 vUdSleepHrs +HwndhUdSleepHrs, %preventSleepHours%
    Gui, Tab3Scroll:Add, Text, % "x336 y" . (y + 3) . " w34 h18 vTxtSleepHrs +HwndhTxtSleepHrs", % L("Lock_HoursUnit")
    Gui, Tab3Scroll:Add, Edit, x374 y%y% w44 h22 Number Right vpreventSleepMinutes gOnChangePreventSleepTime +HwndhEdtSleepMins
    Gui, Tab3Scroll:Add, UpDown, Range0-59 vUdSleepMins +HwndhUdSleepMins, %preventSleepMinutes%
    Gui, Tab3Scroll:Add, Text, % "x422 y" . (y + 3) . " w48 h18 vTxtSleepMins +HwndhTxtSleepMins", % L("Lock_MinutesUnit")
    CardAddItem(c2, hChkSleep,      y)
    CardAddItem(c2, hChkSleepUnlim, y)
    CardAddItem(c2, hEdtSleepHrs,   y)
    CardAddItem(c2, hUdSleepHrs,    y)
    CardAddItem(c2, hTxtSleepHrs,   y + 3)
    CardAddItem(c2, hEdtSleepMins,  y)
    CardAddItem(c2, hUdSleepMins,   y)
    CardAddItem(c2, hTxtSleepMins,  y + 3)
    c2.curY += 28

    y := c2.curY
    Gui, Tab3Scroll:Font, s9.5 Norm c222222, Segoe UI
    if (LockTabIcons["toast"]) {
        Gui, Tab3Scroll:Add, Picture, x28 y%y% w20 h20 +HwndhPicToast, % "HICON:*" . LockTabIcons["toast"]
        CardAddItem(c2, hPicToast, y)
    }
    Gui, Tab3Scroll:Add, Checkbox, x54 y%y% w466 h22 valwaysShowLockToast gSaveSettings Checked%alwaysShowLockToast% +HwndhChkToast, % L("Lock_AlwaysShowToast")
    CardAddItem(c2, hChkToast, y)
    c2.curY += 26
    EndCard(c2, 8)

    ; Card 3: Bảo mật & Mở khóa
    c3 := BeginCard(3, "Tab3Scroll", "t3_auth", L("Lock_Card2Title"), 1, "OnToggleT3Auth")
    chkCustomMode := windowsLogonOnly ? 0 : 1
    chkWinOnlyMode := windowsLogonOnly ? 1 : 0
    y := c3.curY
    Gui, Tab3Scroll:Font, s9.5 Norm c222222, Segoe UI
    if (LockTabIcons["key"]) {
        Gui, Tab3Scroll:Add, Picture, x28 y%y% w20 h20 +HwndhPicKey, % "HICON:*" . LockTabIcons["key"]
        CardAddItem(c3, hPicKey, y)
    }
    Gui, Tab3Scroll:Add, Radio, x54 y%y% w466 h22 vUnlockModeCustom gOnSelectUnlockModeCustom Checked%chkCustomMode% +HwndhRadCustom, % L("Lock_ModeCustom")
    CardAddItem(c3, hRadCustom, y)
    c3.curY += 29

    y := c3.curY
    Gui, Tab3Scroll:Add, Text, % "x44 y" . (y + 3) . " w92 vLockKeyPromptLbl +HwndhLblKeyPrm", % L("Lock_KeyPrompt")
    Gui, Tab3Scroll:Font, s9 Norm c222222, Segoe UI
    Gui, Tab3Scroll:Add, Edit, x140 y%y% w182 h24 vUnlockCodeDisplay ReadOnly Password +HwndhEdtCode, %UNLOCK_KEYWORD%
    Gui, Tab3Scroll:Add, Button, % "x328 y" . (y - 1) . " w34 h26 +0x0040 gToggleRevealCode vBtnToggleReveal +HwndhBtnToggleReveal"
    if (LockTabIcons["eye_show"]) {
        DllCall("SendMessage", "Ptr", hBtnToggleReveal, "UInt", 0x00F7, "Ptr", 1, "Ptr", LockTabIcons["eye_show"])
        SettingsTooltips[hBtnToggleReveal] := L("Lock_RevealShowTip")
    }
    Gui, Tab3Scroll:Add, Button, % "x368 y" . (y - 1) . " w152 h26 gOpenChangeCodeGui vBtnChangeCode +HwndhBtnChgCode", % L("Lock_ChangeCodeBtn")
    CardAddItem(c3, hLblKeyPrm,       y + 3)
    CardAddItem(c3, hEdtCode,         y)
    CardAddItem(c3, hBtnToggleReveal, y - 1)
    CardAddItem(c3, hBtnChgCode,      y - 1)
    c3.curY += 32

    y := c3.curY
    Gui, Tab3Scroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, Tab3Scroll:Add, Checkbox, x44 y%y% w476 h22 vrequireCodeForTimerEdit gSaveSettings Checked%requireCodeForTimerEdit% +HwndhChkReqCode, % L("Lock_ReqTimerEditCode")
    CardAddItem(c3, hChkReqCode, y)
    c3.curY += 30

    y := c3.curY
    if (LockTabIcons["winlock"]) {
        Gui, Tab3Scroll:Add, Picture, x28 y%y% w20 h20 +HwndhPicWin, % "HICON:*" . LockTabIcons["winlock"]
        CardAddItem(c3, hPicWin, y)
    }
    Gui, Tab3Scroll:Add, Radio, x54 y%y% w466 h22 vUnlockModeWinOnly gOnSelectUnlockModeWinOnly Checked%chkWinOnlyMode% +HwndhRadWin, % L("Lock_ModeWinOnly")
    CardAddItem(c3, hRadWin, y)
    c3.curY += 26
    EndCard(c3, 8)

    Gui, Tab3Scroll:Show, Hide x216 y0 w564 h472
    LayoutCardTab(3, true)
}

; ========================================================
; TAB 4: PHÍM TẮT && TIỆN ÍCH (CARD CUỘN DỌC)
; ========================================================
BuildShortcutsScrollPanel(aboutIcon) {
    global
    hShortcutsScroll := BeginCardTab(4, "ShortcutsScroll", L("Set_HeaderShortcuts"), L("Set_SubShortcuts"))

    ; CARD 1: PHÍM TẮT HỆ THỐNG (MẶC ĐỊNH MỞ)
    sysCard := BeginCard(4, "ShortcutsScroll", "sys", L("Set_GroupSystemHotkeys"), 1, "OnToggleSysExpand")
    CardAddShortcutRow(sysCard, "Icon28",  A_WinDir . "\System32\ddores.dll",  "Set_LockCenter", "Ctrl + Alt + L",     "ActionOpenLockCenter")
    CardAddShortcutRow(sysCard, "Icon261", A_WinDir . "\System32\shell32.dll", "Set_PastePlain", "Ctrl + Shift + V",   "ActionPastePlain")
    CardAddDescText(sysCard, L("Set_PastePlainDesc"), 58, 18, 4)
    CardAddShortcutRow(sysCard, "Icon3",   A_WinDir . "\System32\SndVol.exe",  "Set_Mute",       "Ctrl + Shift + M",   "ActionMute")
    CardAddShortcutRow(sysCard, "Icon2",   A_WinDir . "\System32\SndVol.exe",  "Set_Volume",     L("Set_VolUpBtn"),    "ActionVolUp",     L("Set_VolDownBtn"), "ActionVolDown")
    CardAddShortcutRow(sysCard, "Icon26",  A_WinDir . "\System32\shell32.dll", "Set_Brightness", L("Set_BrightDownBtn"), "ActionBrightDown", L("Set_BrightUpBtn"), "ActionBrightUp")
    CardAddDescText(sysCard, L("Set_ShortcutsTip"), 28, 18, 2)
    EndCard(sysCard, 8)

    ; CARD 2: MICROPHONE (MẶC ĐỊNH THU GỌN, CHECKBOX TRÊN HEADER)
    micCard := BeginCard(4, "ShortcutsScroll", "mic", L("Set_GroupMic"), 0, "OnToggleMicExpand", "MicMuteEnabled", "OnToggleMicMuteEnabled", MicMuteEnabled)
    CardAddSubHeader(micCard, L("Mic_SecHotkeys"), 0)

    y := micCard.curY
    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Text, x32 y%y% w210 h20 +HwndhMicToggleLbl Hidden, % L("Mic_ToggleHkLbl")
    micHkDisplay := IsFunc("FormatMicHotkeyText") ? FormatMicHotkeyText(MicMuteHotkey) : "Win + Alt + M"
    Gui, ShortcutsScroll:Font, s9 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Button, % "x248 y" . (y - 3) . " w272 h26 vMicHotkeyBtn +HwndhMicToggleBtn gOnChangeMicToggleHotkey Hidden", %micHkDisplay%
    CardAddItem(micCard, hMicToggleLbl, y)
    CardAddItem(micCard, hMicToggleBtn, y - 3)
    micCard.curY += 30

    y := micCard.curY
    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Text, x32 y%y% w210 h20 +HwndhMicPttLbl Hidden, % L("Mic_PttHkLbl")
    pttHkDisplay := IsFunc("FormatMicHotkeyText") ? FormatMicHotkeyText(MicPttHotkey) : "Right Ctrl"
    Gui, ShortcutsScroll:Font, s9 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Button, % "x248 y" . (y - 3) . " w272 h26 vMicPttHotkeyBtn +HwndhMicPttBtn gOnChangeMicPttHotkey Hidden", %pttHkDisplay%
    CardAddItem(micCard, hMicPttLbl, y)
    CardAddItem(micCard, hMicPttBtn, y - 3)
    micCard.curY += 29

    y := micCard.curY
    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Checkbox, x32 y%y% w496 h22 vMicPttInvert +HwndhMicPttInv gOnSaveMicSettings Checked%MicPttInvert% Hidden, % L("Mic_PttInvertChk")
    CardAddItem(micCard, hMicPttInv, y)
    micCard.curY += 22
    CardAddDescText(micCard, L("Mic_PttInvertDesc"), 52, 18, 4)

    y := micCard.curY
    Gui, ShortcutsScroll:Font, s9 Norm c555555, Segoe UI
    Gui, ShortcutsScroll:Add, Text, % "x32 y" . (y + 3) . " w218 h18 +HwndhMicDelayLbl Hidden", % L("Mic_DelayLbl")
    Gui, ShortcutsScroll:Font, s9 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Edit, x254 y%y% w72 h22 Number vMicReleaseDelayInput +HwndhMicDelayEdit gOnChangeMicDelay Hidden, %MicMuteReleaseDelay%
    Gui, ShortcutsScroll:Add, UpDown, Range0-2000 vMicReleaseDelayUpDown +HwndhMicDelayUD Hidden, %MicMuteReleaseDelay%
    Gui, ShortcutsScroll:Font, s8.5 Norm c666666, Segoe UI
    Gui, ShortcutsScroll:Add, Text, % "x334 y" . (y + 3) . " w120 h18 +HwndhMicDelayUnit Hidden", (0 - 2000 ms)
    CardAddItem(micCard, hMicDelayLbl,  y + 3)
    CardAddItem(micCard, hMicDelayEdit, y)
    CardAddItem(micCard, hMicDelayUD,   y)
    CardAddItem(micCard, hMicDelayUnit, y + 3)
    micCard.curY += 28

    CardAddSubHeader(micCard, L("Mic_SecDevice"), 6)

    y := micCard.curY
    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, DropDownList, x32 y%y% w454 AltSubmit vMicDeviceChoice +HwndhMicDevDDL gOnSelectMicDevice Hidden, % L("Mic_DevAll")
    Gui, ShortcutsScroll:Add, Button, % "x492 y" . (y - 1) . " w28 h24 vMicRefreshDevBtn +HwndhMicDevRefresh gOnRefreshMicDevices Hidden", ↻
    CardAddItem(micCard, hMicDevDDL,     y)
    CardAddItem(micCard, hMicDevRefresh, y - 1)
    micCard.curY += 26
    CardAddDescText(micCard, L("Mic_AllDevicesDesc"), 32, 18, 4)

    CardAddSubHeader(micCard, L("Mic_SecOsd"), 6)

    y := micCard.curY
    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Checkbox, x32 y%y% w496 h22 vMicMuteBadgeEnabled +HwndhMicBadgeChk gOnToggleMicBadge Checked%MicMuteBadgeEnabled% Hidden, % L("Mic_BadgeChk")
    CardAddItem(micCard, hMicBadgeChk, y)
    micCard.curY += 24

    y := micCard.curY
    Gui, ShortcutsScroll:Add, Checkbox, x32 y%y% w496 h22 vMicOsdEnabled +HwndhMicOsdChk gOnToggleMicOsd Checked%MicMuteOsdEnabled% Hidden, % L("Mic_OsdChk")
    CardAddItem(micCard, hMicOsdChk, y)
    micCard.curY += 26

    y := micCard.curY
    Gui, ShortcutsScroll:Font, s9 Norm c555555, Segoe UI
    Gui, ShortcutsScroll:Add, Text, % "x52 y" . (y + 3) . " w198 h18 +HwndhMicOsdDurLbl Hidden", % L("Mic_OsdDurLbl")
    Gui, ShortcutsScroll:Font, s9 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Edit, x254 y%y% w72 h22 Number vMicOsdDurationInput +HwndhMicOsdEdit gOnChangeMicOsdDuration Hidden, %MicMuteOsdDuration%
    Gui, ShortcutsScroll:Add, UpDown, Range400-10000 vMicOsdDurationUpDown +HwndhMicOsdUD Hidden, %MicMuteOsdDuration%
    Gui, ShortcutsScroll:Add, Button, % "x336 y" . (y - 2) . " w116 h25 vMicTestOsdBtn +HwndhMicTestBtn gOnTestMicOsd Hidden", % L("Mic_TestOsdBtn")
    CardAddItem(micCard, hMicOsdDurLbl, y + 3)
    CardAddItem(micCard, hMicOsdEdit,   y)
    CardAddItem(micCard, hMicOsdUD,     y)
    CardAddItem(micCard, hMicTestBtn,   y - 2)
    micCard.curY += 28

    y := micCard.curY
    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Checkbox, x32 y%y% w496 h22 vMicBeepEnabled +HwndhMicBeepChk gOnSaveMicSettings Checked%MicMuteBeepEnabled% Hidden, % L("Mic_BeepChk")
    CardAddItem(micCard, hMicBeepChk, y)
    micCard.curY += 24
    EndCard(micCard, 8)

    ; CARD 3: GHIM CỬA SỔ LUÔN NỔI (MẶC ĐỊNH MỞ, CHECKBOX TRÊN HEADER)
    aotCard := BeginCard(4, "ShortcutsScroll", "aot", L("Set_GroupAOT"), 1, "OnToggleAotExpand", "AOTEnabled", "OnToggleAOTEnabled", AOTEnabled)
    y := aotCard.curY
    Gui, ShortcutsScroll:Font, s9 Norm c555555, Segoe UI
    Gui, ShortcutsScroll:Add, Text, % "x28 y" . (y + 4) . " w64 h18 vAOTHotkeyLbl +HwndhAotHkLbl", % L("AOT_HotkeyLbl")
    Gui, ShortcutsScroll:Font, s9 Norm c222222, Segoe UI
    aotHkDisplay := IsFunc("FormatAOTHotkeyText") ? FormatAOTHotkeyText(AOTHotkey) : "Ctrl + Alt + T"
    Gui, ShortcutsScroll:Add, Button, x96 y%y% w168 h25 vAOTHotkeyBtn +HwndhAotHkBtn gOnChangeAOTHotkey, %aotHkDisplay%
    Gui, ShortcutsScroll:Add, Button, x272 y%y% w128 h25 vAOTUnpinAllBtn +HwndhAotUnpinBtn gOnUnpinAllAOT, % L("AOT_UnpinAllBtn")
    CardAddItem(aotCard, hAotHkLbl,    y + 4)
    CardAddItem(aotCard, hAotHkBtn,    y)
    CardAddItem(aotCard, hAotUnpinBtn, y)
    aotCard.curY += 30

    y := aotCard.curY
    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Checkbox, x28 y%y% w492 h22 vAOTBorderEnabled +HwndhAotBorderChk gOnToggleAOTBorder Checked%AOTBorderEnabled%, % L("AOT_BorderChk")
    CardAddItem(aotCard, hAotBorderChk, y)
    aotCard.curY += 24
    EndCard(aotCard, 8)

    ; CARD: WINDOW HOPPER (CHUYỂN CỬA SỔ CÙNG ỨNG DỤNG, CHECKBOX TRÊN HEADER)
    whCard := BeginCard(4, "ShortcutsScroll", "winhopper", L("Set_GroupWinHopper"), 1, "OnToggleWinHopperExpand", "WinHopperEnabled", "OnToggleWinHopperEnabled", WinHopperEnabled)
    y := whCard.curY
    Gui, ShortcutsScroll:Font, s9 Norm c555555, Segoe UI
    Gui, ShortcutsScroll:Add, Text, % "x28 y" . (y + 4) . " w44 h18 vWinHopperFwdLbl +HwndhWhFwdLbl", % L("WH_FwdHotkeyLbl")
    Gui, ShortcutsScroll:Font, s9 Norm c222222, Segoe UI
    whFwdDisplay := IsFunc("FormatWinHopperHotkeyText") ? FormatWinHopperHotkeyText(WinHopperHotkey) : "Alt + ``"
    Gui, ShortcutsScroll:Add, Button, x74 y%y% w160 h25 vWinHopperHotkeyBtn +HwndhWhFwdBtn gOnChangeWinHopperFwdHotkey, %whFwdDisplay%
    Gui, ShortcutsScroll:Font, s9 Norm c555555, Segoe UI
    Gui, ShortcutsScroll:Add, Text, % "x248 y" . (y + 4) . " w44 h18 vWinHopperBackLbl +HwndhWhBackLbl", % L("WH_BackHotkeyLbl")
    Gui, ShortcutsScroll:Font, s9 Norm c222222, Segoe UI
    whBackDisplay := IsFunc("FormatWinHopperHotkeyText") ? FormatWinHopperHotkeyText(WinHopperBackHotkey) : "Alt + Shift + ``"
    Gui, ShortcutsScroll:Add, Button, x294 y%y% w168 h25 vWinHopperBackHotkeyBtn +HwndhWhBackBtn gOnChangeWinHopperBackHotkey, %whBackDisplay%
    CardAddItem(whCard, hWhFwdLbl,  y + 4)
    CardAddItem(whCard, hWhFwdBtn,  y)
    CardAddItem(whCard, hWhBackLbl, y + 4)
    CardAddItem(whCard, hWhBackBtn, y)
    whCard.curY += 30

    y := whCard.curY
    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Checkbox, x28 y%y% w492 h22 vWinHopperShowPreview +HwndhWhPreviewChk gOnToggleWinHopperPreview Checked%WinHopperShowPreview%, % L("WH_PreviewChk")
    CardAddItem(whCard, hWhPreviewChk, y)
    whCard.curY += 26
    CardAddDescText(whCard, L("WH_Desc"), 28, 18, 2)
    EndCard(whCard, 8)

    ; CARD 4: TẮT MÀN HÌNH NHANH (MẶC ĐỊNH MỞ, CHECKBOX TRÊN HEADER)
    screenCard := BeginCard(4, "ShortcutsScroll", "screenoff", L("Set_GroupScreenOff"), 1, "OnToggleScreenOffExpand", "ScreenOffEnabled", "OnToggleScreenOffEnabled", ScreenOffEnabled)
    y := screenCard.curY
    Gui, ShortcutsScroll:Font, s9 Norm c555555, Segoe UI
    Gui, ShortcutsScroll:Add, Text, % "x28 y" . (y + 4) . " w64 h18 vScreenOffHotkeyLbl +HwndhScrHkLbl", % L("ScreenOff_HotkeyLbl")
    Gui, ShortcutsScroll:Font, s9 Norm c222222, Segoe UI
    scrHkDisplay := IsFunc("FormatScreenOffHotkeyText") ? FormatScreenOffHotkeyText(ScreenOffHotkey) : "Win + Alt + S"
    Gui, ShortcutsScroll:Add, Button, x96 y%y% w168 h25 vScreenOffHotkeyBtn +HwndhScrHkBtn gOnChangeScreenOffHotkey, %scrHkDisplay%
    Gui, ShortcutsScroll:Add, Button, x272 y%y% w148 h25 vScreenOffTestBtn +HwndhScrTestBtn gOnTestScreenOff, % L("ScreenOff_TestBtn")
    CardAddItem(screenCard, hScrHkLbl,   y + 4)
    CardAddItem(screenCard, hScrHkBtn,   y)
    CardAddItem(screenCard, hScrTestBtn, y)
    screenCard.curY += 30
    CardAddDescText(screenCard, L("ScreenOff_Desc"), 28, 18, 2)
    EndCard(screenCard, 8)

    ; CARD 5: THAO TÁC NHANH TRÊN KHAY HỆ THỐNG (MẶC ĐỊNH MỞ)
    trayCard := BeginCard(4, "ShortcutsScroll", "tray", L("Set_GroupTrayActions"), 1, "OnToggleTrayExpand")
    y := trayCard.curY
    if (aboutIcon != "" && FileExist(aboutIcon)) {
        Gui, ShortcutsScroll:Add, Picture, % "x28 y" . (y + 3) . " w20 h20 Icon1 vTrayToggleIco +HwndhTrayIco", %aboutIcon%
        CardAddItem(trayCard, hTrayIco, y + 3)
    }
    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Text, % "x56 y" . (y + 4) . " w252 vTrayToggleLbl +HwndhTrayLbl", % L("Set_TrayToggleLabel")
    Gui, ShortcutsScroll:Font, s9 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Button, x314 y%y% w206 h26 Center gActionToggleGestures vTrayToggleBtn +HwndhTrayBtn, % L("Set_TrayToggleBtn")
    CardAddItem(trayCard, hTrayLbl, y + 4)
    CardAddItem(trayCard, hTrayBtn, y)
    trayCard.curY += 30
    CardAddDescText(trayCard, "• " . L("Set_TrayDblClickTip"), 28, 18, 2)
    EndCard(trayCard, 8)

    ; CARD 6: CHẶN POPUP (CHECKBOX TRÊN HEADER)
    popupCard := BeginCard(4, "ShortcutsScroll", "popup", L("Set_GroupPopupBlocker"), 1, "OnTogglePopupBlockerExpand", "PopupBlockerEnabled", "OnTogglePopupBlockerEnabled", PopupBlockerEnabled)
    y := popupCard.curY
    Gui, ShortcutsScroll:Font, s9.5 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Text, % "x28 y" . (y + 4) . " w280 h20 +0x200 vPopupManageLbl +HwndhPopupLbl", % L("Popup_CardLabel")
    Gui, ShortcutsScroll:Font, s9 Norm c222222, Segoe UI
    Gui, ShortcutsScroll:Add, Button, x314 y%y% w206 h26 Center gOnOpenPopupBlockerMgr vPopupManageBtn +HwndhPopupBtn, % L("Popup_ManageBtn")
    CardAddItem(popupCard, hPopupLbl, y + 4)
    CardAddItem(popupCard, hPopupBtn, y)
    popupCard.curY += 34

    y := popupCard.curY
    Gui, ShortcutsScroll:Font, s9 Norm c555555, Segoe UI
    Gui, ShortcutsScroll:Add, Text, % "x28 y" . (y + 4) . " w106 h18 vPopupPickHotkeyLbl +HwndhPopupHkLbl", % L("Popup_HotkeyLbl")
    Gui, ShortcutsScroll:Font, s9 Norm c222222, Segoe UI
    pickHkDisplay := IsFunc("FormatPopupPickHotkeyText") ? FormatPopupPickHotkeyText(PopupPickHotkey) : "Ctrl + Alt + P"
    Gui, ShortcutsScroll:Add, Button, x138 y%y% w170 h25 vPopupPickHotkeyBtn +HwndhPopupHkBtn gOnChangePopupPickHotkey, %pickHkDisplay%
    Gui, ShortcutsScroll:Add, Button, x314 y%y% w206 h25 Center gOnQuickPickPopupTarget vPopupQuickPickBtn +HwndhPopupPickBtn, % L("Popup_QuickPickShortBtn")
    SettingsTooltips[hPopupPickBtn] := L("Popup_QuickPickTip")
    CardAddItem(popupCard, hPopupHkLbl, y + 4)
    CardAddItem(popupCard, hPopupHkBtn, y)
    CardAddItem(popupCard, hPopupPickBtn, y)
    popupCard.curY += 34

    CardAddDescText(popupCard, L("Popup_Desc"), 28, 18, 2)
    EndCard(popupCard, 8)

    Gui, ShortcutsScroll:Show, Hide x216 y0 w564 h472
    RefreshMicDeviceDropdown()
    UpdateAllCardSummaries()
    LayoutCardTab(4, true)
}

; ========================================================
; UNIFIED CARD BUILDER & SCROLL ENGINE (TAB 1 - 4)
; ========================================================
BeginCardTab(tabNum, guiName, headerTitle, headerSub := "", headerTitleW := 524) {
    global hSettingsGui, TabScrollHwnds, TabScrollHwndToNum, TabCards, TabScrollPos, TabContentH, TabStaticColors
    TabCards[tabNum] := []
    TabScrollPos[tabNum] := 0
    TabContentH[tabNum] := 472
    TabStaticColors[tabNum] := {}

    Gui, %guiName%:New, -Caption +0x40000000 +0x04000000 +0x200000 +Parent%hSettingsGui% +HwndhPanel
    Gui, %guiName%:Color, F3F3F3
    Gui, %guiName%:Font, s9.5 Norm c222222, Segoe UI

    Gui, %guiName%:Font, s13 Bold c004499, Segoe UI
    Gui, %guiName%:Add, Text, x12 y12 w%headerTitleW% +BackgroundTrans +HwndhTabTitle, %headerTitle%

    TabScrollHwnds[tabNum] := hPanel
    TabScrollHwndToNum[hPanel] := tabNum
    TabStaticColors[tabNum][hTabTitle] := "body"
    return hPanel
}

BeginCard(tabNum, guiName, id, titleText, expanded, toggleGLabel, toggleVar := "", toggleChkGLabel := "", toggleChecked := 0) {
    global TabCards, TabStaticColors, ShortcutsOnLabelMap, ChevronBitmaps
    if (!IsObject(ShortcutsOnLabelMap))
        ShortcutsOnLabelMap := {}
    headerH := 48
    collapsedH := 50

    ; Khung nền Card dùng Static + WM_CTLCOLORSTATIC: viền phẳng 1px #E5E5E5 cả 4 cạnh, nền #FBFBFB
    Gui, %guiName%:Add, Text, x12 y0 w524 h50 Disabled +HwndhBorder
    Gui, %guiName%:Add, Text, x13 y1 w522 h48 Disabled +HwndhBody
    Gui, %guiName%:Add, Text, x22 y48 w504 h1 Disabled +HwndhHeaderDiv
    TabStaticColors[tabNum][hBorder]    := "border"
    TabStaticColors[tabNum][hBody]      := "card"
    TabStaticColors[tabNum][hHeaderDiv] := "border"

    Gui, %guiName%:Font, s9.5 Bold c222222, Segoe UI
    Gui, %guiName%:Add, Text, x22 y7 w415 h18 +0x200 +HwndhTitle, %titleText%

    Gui, %guiName%:Font, s8.5 Norm c666666, Segoe UI
    Gui, %guiName%:Add, Text, x22 y26 w415 h16 +0x200 +HwndhSummary

    hToggleChk := 0
    hOnLbl := 0
    hitW := 490
    if (toggleVar != "") {
        Gui, %guiName%:Font, s9 Norm c444444, Segoe UI
        Gui, %guiName%:Add, Text, x448 y15 w28 h18 +Right +0x200 gOnClickCardOnLabel +HwndhOnLbl, On
        Gui, %guiName%:Add, Checkbox, x480 y16 w16 h16 v%toggleVar% g%toggleChkGLabel% Checked%toggleChecked% +HwndhToggleChk
        ShortcutsOnLabelMap[hOnLbl] := {gui: guiName, var: toggleVar, gLabel: toggleChkGLabel}
        hitW := 432
    }

    hArrowBmp := IsObject(ChevronBitmaps) ? ChevronBitmaps[expanded ? "up" : "down"] : 0
    if (hArrowBmp) {
        Gui, %guiName%:Add, Picture, x508 y16 +0x100 g%toggleGLabel% +HwndhArrow, HBITMAP:*%hArrowBmp%
    } else {
        Gui, %guiName%:Font, s9.5 Bold c555555, Segoe UI
        Gui, %guiName%:Add, Text, x504 y14 w24 h20 +Center +0x200 g%toggleGLabel% +HwndhArrow, % expanded ? "⌃" : "⌄"
    }

    Gui, %guiName%:Add, Text, x12 y1 w%hitW% h47 +BackgroundTrans g%toggleGLabel% +HwndhHit
    TabStaticColors[tabNum][hHit] := "trans"

    card := {id: id
        , tabNum: tabNum
        , guiName: guiName
        , expanded: expanded ? 1 : 0
        , headerH: headerH
        , collapsedH: collapsedH
        , expandedH: collapsedH
        , curY: headerH + 10
        , hBorder: hBorder
        , hBody: hBody
        , hHeaderDiv: hHeaderDiv
        , hOnLbl: hOnLbl
        , hToggleChk: hToggleChk
        , hTitle: hTitle
        , hSummary: hSummary
        , hArrow: hArrow
        , hHit: hHit
        , items: []}
    TabCards[tabNum].Push(card)
    return card
}

WM_CTLCOLORSTATIC_SETTINGS(wParam, lParam, msg, hwnd) {
    global TabScrollHwndToNum, TabStaticColors
    static hBrBorder := 0, hBrCard := 0, hBrBody := 0
    if (!IsObject(TabScrollHwndToNum) || !TabScrollHwndToNum.HasKey(hwnd))
        return ""
    tabNum := TabScrollHwndToNum[hwnd]
    if (!hBrBorder) {
        hBrBorder := DllCall("CreateSolidBrush", "UInt", 0xE5E5E5, "Ptr")
        hBrCard   := DllCall("CreateSolidBrush", "UInt", 0xFBFBFB, "Ptr")
        hBrBody   := DllCall("CreateSolidBrush", "UInt", 0xF3F3F3, "Ptr")
    }
    role := IsObject(TabStaticColors[tabNum]) ? TabStaticColors[tabNum][lParam] : ""
    if (role = "border")
        return hBrBorder
    if (role = "trans") {
        DllCall("SetBkMode", "Ptr", wParam, "Int", 1) ; TRANSPARENT
        return DllCall("GetStockObject", "Int", 5, "Ptr") ; NULL_BRUSH
    }
    if (role = "body") {
        DllCall("SetBkMode", "Ptr", wParam, "Int", 1) ; TRANSPARENT
        return hBrBody
    }
    DllCall("SetBkColor", "Ptr", wParam, "UInt", 0xFBFBFB)
    return hBrCard
}

CardAddItem(card, hwnd, relY) {
    if (hwnd)
        card.items.Push({hwnd: hwnd, relY: relY})
}

CardAddSubHeader(card, titleText, topGap := 2) {
    guiName := card.guiName
    card.curY += topGap
    y := card.curY
    Gui, %guiName%:Font, s9 Bold c005FB8, Segoe UI
    Gui, %guiName%:Add, Text, x28 y%y% w492 h18 +HwndhSub Hidden, %titleText%
    DllCall("ShowWindow", "Ptr", hSub, "Int", card.expanded ? 5 : 0)
    CardAddItem(card, hSub, y)
    card.curY += 22
}

CardAddDescText(card, textStr, indentX := 28, height := 18, bottomGap := 4) {
    guiName := card.guiName
    y := card.curY
    w := 520 - indentX
    Gui, %guiName%:Font, s8.5 Norm c666666, Segoe UI
    Gui, %guiName%:Add, Text, x%indentX% y%y% w%w% h%height% +HwndhDesc, %textStr%
    CardAddItem(card, hDesc, y)
    card.curY += height + bottomGap
}

CardAddShortcutRow(card, iconOpt, iconFile, labelKey, btn1Text, gLabel1, btn2Text := "", gLabel2 := "") {
    guiName := card.guiName
    y := card.curY
    icoY := y + 3
    lblY := y + 4
    if (iconFile != "" && FileExist(iconFile)) {
        Gui, %guiName%:Add, Picture, x28 y%icoY% w20 h20 %iconOpt% +HwndhPic, %iconFile%
        CardAddItem(card, hPic, icoY)
    }
    Gui, %guiName%:Font, s9.5 Norm c222222, Segoe UI
    Gui, %guiName%:Add, Text, x56 y%lblY% w252 +HwndhLbl, % L(labelKey)
    CardAddItem(card, hLbl, lblY)

    Gui, %guiName%:Font, s9 Norm c222222, Segoe UI
    if (btn2Text = "") {
        Gui, %guiName%:Add, Button, x314 y%y% w206 h26 Center +HwndhBtn1 g%gLabel1%, %btn1Text%
        CardAddItem(card, hBtn1, y)
    } else {
        Gui, %guiName%:Add, Button, x314 y%y% w100 h26 Center +HwndhBtn1 g%gLabel1%, %btn1Text%
        Gui, %guiName%:Add, Button, x420 y%y% w100 h26 Center +HwndhBtn2 g%gLabel2%, %btn2Text%
        CardAddItem(card, hBtn1, y)
        CardAddItem(card, hBtn2, y)
    }
    card.curY += 29
}

EndCard(card, bottomPad := 8) {
    card.expandedH := card.curY + bottomPad
}

OnClickCardOnLabel:
    MouseGetPos,,,, hClickedOnLbl, 2
    if (IsObject(ShortcutsOnLabelMap) && ShortcutsOnLabelMap.HasKey(hClickedOnLbl)) {
        info := ShortcutsOnLabelMap[hClickedOnLbl]
        guiName := info.gui
        GuiControlGet, curChkVal, %guiName%:, % info.var
        newChkVal := curChkVal ? 0 : 1
        GuiControl, %guiName%:, % info.var, %newChkVal%
        Gosub, % info.gLabel
    }
return

UpdateAllCardSummaries() {
    global TabCards, TabScrollNames, CurrentLang, MicMuteHotkey, AOTHotkey
    global AutoStart, GestureScrollEnabled, ScrollStyle
    global lockKeyboardEnabled, mouseLockEnabled, autoLockIdleEnabled, autoLockIdleMinutes, windowsLogonOnly

    if (!IsObject(TabCards))
        return

    isEn := (CurrentLang = "en")
    hkPrefix := isEn ? "Hotkey: " : "Phím tắt: "
    noHkTxt  := isEn ? "No hotkey assigned" : "Chưa gán phím tắt"

    Loop, 4 {
        tNum := A_Index
        guiName := TabScrollNames[tNum]
        cards := TabCards[tNum]
        if (!IsObject(cards))
            continue

        for _, card in cards {
            summary := ""
            if (card.id = "t1_gen") {
                langTxt := isEn ? "English" : "Tiếng Việt"
                bootTxt := AutoStart ? (isEn ? "Auto-start: On" : "Khởi động cùng Windows: Bật") : (isEn ? "Auto-start: Off" : "Khởi động cùng Windows: Tắt")
                summary := bootTxt . " • " . langTxt
            } else if (card.id = "t1_priv") {
                hasPriv := A_IsAdmin ? "Admin" : (IsFunc("HasUIAccessOrAdmin") && HasUIAccessOrAdmin() ? "UIAccess" : "Standard")
                summary := isEn ? ("Privilege: " . hasPriv) : ("Quyền hiện tại: " . hasPriv)
            } else if (card.id = "t1_tips") {
                summary := isEn ? "Quick tips for gestures && lock" : "Mẹo dùng cử chỉ && khóa nhanh"
            } else if (card.id = "t2_gesture") {
                if (GestureScrollEnabled) {
                    stTxt := (ScrollStyle = 1) ? (isEn ? "Drag content" : "Kéo nội dung") : (isEn ? "Drag scrollbar" : "Kéo thanh cuộn")
                    summary := (isEn ? "Enabled • " : "Đang bật • ") . stTxt
                } else {
                    summary := isEn ? "Disabled" : "Đang tắt"
                }
            } else if (card.id = "t2_actions") {
                summary := isEn ? "4 mouse actions • 6 browser gestures" : "4 thao tác chuột • 6 cử chỉ trình duyệt"
            } else if (card.id = "t3_target") {
                tParts := ""
                if (lockKeyboardEnabled && mouseLockEnabled)
                    tParts := isEn ? "Keyboard && Mouse" : "Bàn phím && Chuột"
                else if (lockKeyboardEnabled)
                    tParts := isEn ? "Keyboard only" : "Chỉ bàn phím"
                else if (mouseLockEnabled)
                    tParts := isEn ? "Mouse only" : "Chỉ chuột"
                else
                    tParts := isEn ? "No device selected" : "Chưa chọn thiết bị"
                idleTxt := autoLockIdleEnabled ? (isEn ? (" • Idle: " . autoLockIdleMinutes . "m") : (" • Tự khóa: " . autoLockIdleMinutes . " phút")) : ""
                summary := tParts . idleTxt
            } else if (card.id = "t3_behavior") {
                summary := isEn ? "Power policy && lock notifications" : "Nguồn điện && Thông báo khi khóa"
            } else if (card.id = "t3_auth") {
                summary := windowsLogonOnly ? (isEn ? "Windows Logon only" : "Chỉ mở khóa Windows") : (isEn ? "Custom unlock code" : "Mã mở khóa tùy chỉnh")
            } else if (card.id = "sys") {
                summary := isEn ? "5 system shortcuts" : "5 phím tắt hệ thống"
            } else if (card.id = "mic") {
                hk := IsFunc("FormatMicHotkeyText") ? FormatMicHotkeyText(MicMuteHotkey) : "Win + Alt + M"
                summary := (hk != "") ? (hkPrefix . hk) : noHkTxt
            } else if (card.id = "aot") {
                hk := IsFunc("FormatAOTHotkeyText") ? FormatAOTHotkeyText(AOTHotkey) : "Ctrl + Alt + T"
                summary := (hk != "") ? (hkPrefix . hk) : noHkTxt
            } else if (card.id = "winhopper") {
                hk := IsFunc("FormatWinHopperHotkeyText") ? FormatWinHopperHotkeyText(WinHopperHotkey) : "Alt + ``"
                summary := (hk != "") ? (hkPrefix . hk) : noHkTxt
            } else if (card.id = "screenoff") {
                hk := IsFunc("FormatScreenOffHotkeyText") ? FormatScreenOffHotkeyText(ScreenOffHotkey) : "Win + Alt + S"
                summary := (hk != "") ? (hkPrefix . hk) : noHkTxt
            } else if (card.id = "tray") {
                summary := isEn ? "Double-click tray icon to toggle" : "Click đúp biểu tượng khay để bật/tắt"
            }
            GuiControl, %guiName%:, % card.hSummary, %summary%
        }
    }
}

UpdateShortcutsCardSummaries() {
    UpdateAllCardSummaries()
}

ToggleCard(tabNum, cardId) {
    global TabCards
    cards := TabCards[tabNum]
    if (!IsObject(cards))
        return
    for _, card in cards {
        if (card.id = cardId) {
            card.expanded := !card.expanded
            break
        }
    }
    LayoutCardTab(tabNum, false)
}

LayoutCardTab(tabNum, resetScroll := false) {
    global TabScrollHwnds, TabScrollNames, TabCards, TabScrollPos, TabContentH, ChevronBitmaps
    hPanel := TabScrollHwnds[tabNum]
    guiName := TabScrollNames[tabNum]
    cards := TabCards[tabNum]
    if (!hPanel || !IsObject(cards))
        return

    if (resetScroll && TabScrollPos[tabNum] != 0)
        ScrollTabTo(tabNum, 0)

    DllCall("SendMessage", "Ptr", hPanel, "UInt", 0x000B, "Ptr", 0, "Ptr", 0) ; WM_SETREDRAW = FALSE

    off := TabScrollPos[tabNum]
    curY := 44

    for _, card in cards {
        cardH := card.expanded ? card.expandedH : card.collapsedH
        yVis := curY - off

        GuiControl, %guiName%:Move, % card.hBorder, % "y" . yVis . " h" . cardH
        GuiControl, %guiName%:Move, % card.hBody,   % "y" . (yVis + 1) . " h" . (cardH - 2)

        DllCall("ShowWindow", "Ptr", card.hHeaderDiv, "Int", card.expanded ? 5 : 0)
        if (card.expanded)
            GuiControl, %guiName%:Move, % card.hHeaderDiv, % "y" . (yVis + card.headerH)

        if (card.hOnLbl)
            GuiControl, %guiName%:Move, % card.hOnLbl, % "y" . (yVis + 15)
        if (card.hToggleChk)
            GuiControl, %guiName%:Move, % card.hToggleChk, % "y" . (yVis + 16)
        GuiControl, %guiName%:Move, % card.hTitle,   % "y" . (yVis + 7)
        GuiControl, %guiName%:Move, % card.hSummary, % "y" . (yVis + 26)
        if (IsObject(ChevronBitmaps) && ChevronBitmaps.HasKey("down")) {
            GuiControl, %guiName%:Move, % card.hArrow, % "y" . (yVis + 16)
            DllCall("SendMessage", "Ptr", card.hArrow, "UInt", 0x0172, "Ptr", 0, "Ptr", ChevronBitmaps[card.expanded ? "up" : "down"])
        } else {
            GuiControl, %guiName%:Move, % card.hArrow, % "y" . (yVis + 14)
            GuiControl, %guiName%:,     % card.hArrow, % card.expanded ? "⌃" : "⌄"
        }
        GuiControl, %guiName%:Move, % card.hHit,     % "y" . (yVis + 1)

        ApplyAccordionGroupLayout(guiName, card.items, curY, off, card.expanded)
        curY += cardH + 10
    }

    TabContentH[tabNum] := curY + 4

    DllCall("SendMessage", "Ptr", hPanel, "UInt", 0x000B, "Ptr", 1, "Ptr", 0) ; WM_SETREDRAW = TRUE
    DllCall("RedrawWindow", "Ptr", hPanel, "Ptr", 0, "Ptr", 0, "UInt", 0x0185) ; RDW_INVALIDATE|RDW_ERASE|RDW_ALLCHILDREN|RDW_UPDATENOW

    UpdateTabScrollInfo(tabNum)
}

ApplyAccordionGroupLayout(guiName, itemsArr, groupY, scrollOff, isExpanded) {
    showFlag := isExpanded ? 5 : 0 ; SW_SHOW : SW_HIDE
    for _, item in itemsArr {
        DllCall("ShowWindow", "Ptr", item.hwnd, "Int", showFlag)
        if (isExpanded)
            GuiControl, %guiName%:Move, % item.hwnd, % "y" . (groupY + item.relY - scrollOff)
    }
}

OnToggleT1Gen:
    ToggleCard(1, "t1_gen")
return
OnToggleT1Priv:
    ToggleCard(1, "t1_priv")
return
OnToggleT1Tips:
    ToggleCard(1, "t1_tips")
return

OnToggleT2Gesture:
    ToggleCard(2, "t2_gesture")
return
OnToggleT2Actions:
    ToggleCard(2, "t2_actions")
return

OnToggleT3Target:
    ToggleCard(3, "t3_target")
return
OnToggleT3Behavior:
    ToggleCard(3, "t3_behavior")
return
OnToggleT3Auth:
    ToggleCard(3, "t3_auth")
return

OnToggleSysExpand:
    ToggleCard(4, "sys")
return
OnToggleMicExpand:
    ToggleCard(4, "mic")
return
OnToggleAotExpand:
    ToggleCard(4, "aot")
return
OnToggleScreenOffExpand:
    ToggleCard(4, "screenoff")
return
OnToggleWinHopperExpand:
    ToggleCard(4, "winhopper")
return
OnToggleTrayExpand:
    ToggleCard(4, "tray")
return
OnTogglePopupBlockerExpand:
    ToggleCard(4, "popup")
return

UpdateTabScrollInfo(tabNum) {
    global TabScrollHwnds, TabContentH, TabScrollPos
    hPanel := TabScrollHwnds[tabNum]
    if (!hPanel)
        return

    VarSetCapacity(rc, 16, 0)
    DllCall("GetClientRect", "Ptr", hPanel, "Ptr", &rc)
    viewH := NumGet(rc, 12, "Int")
    if (viewH <= 0)
        return

    scale := A_ScreenDPI / 96.0
    totalPx := Round(TabContentH[tabNum] * scale)
    maxScrollPx := (totalPx > viewH) ? (totalPx - viewH) : 0
    maxScrollLogical := Round(maxScrollPx / scale)

    if (TabScrollPos[tabNum] > maxScrollLogical)
        ScrollTabTo(tabNum, maxScrollLogical)

    posPx := Round(TabScrollPos[tabNum] * scale)
    VarSetCapacity(si, 28, 0)
    NumPut(28, si, 0, "UInt")
    NumPut(0x17, si, 4, "UInt") ; SIF_ALL
    NumPut(0, si, 8, "Int")
    NumPut(totalPx > 0 ? totalPx - 1 : 0, si, 12, "Int")
    NumPut(viewH, si, 16, "UInt")
    NumPut(posPx, si, 20, "Int")
    DllCall("SetScrollInfo", "Ptr", hPanel, "Int", 1, "Ptr", &si, "Int", 1) ; SB_VERT = 1
}

ScrollTabTo(tabNum, newLogicalPos) {
    global TabScrollHwnds, TabContentH, TabScrollPos
    hPanel := TabScrollHwnds[tabNum]
    if (!hPanel)
        return

    VarSetCapacity(rc, 16, 0)
    DllCall("GetClientRect", "Ptr", hPanel, "Ptr", &rc)
    viewH := NumGet(rc, 12, "Int")
    scale := A_ScreenDPI / 96.0
    totalPx := Round(TabContentH[tabNum] * scale)
    maxLogical := (totalPx > viewH) ? Round((totalPx - viewH) / scale) : 0

    if (newLogicalPos < 0)
        newLogicalPos := 0
    if (newLogicalPos > maxLogical)
        newLogicalPos := maxLogical

    if (newLogicalPos = TabScrollPos[tabNum])
        return

    oldPx := Round(TabScrollPos[tabNum] * scale)
    newPx := Round(newLogicalPos * scale)
    deltaPx := oldPx - newPx
    TabScrollPos[tabNum] := newLogicalPos

    DllCall("ScrollWindowEx", "Ptr", hPanel, "Int", 0, "Int", deltaPx, "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr", 0, "UInt", 0x0007) ; SW_SCROLLCHILDREN|SW_INVALIDATE|SW_ERASE
    DllCall("RedrawWindow", "Ptr", hPanel, "Ptr", 0, "Ptr", 0, "UInt", 0x0185) ; RDW_INVALIDATE|RDW_ERASE|RDW_ALLCHILDREN|RDW_UPDATENOW

    VarSetCapacity(si, 28, 0)
    NumPut(28, si, 0, "UInt")
    NumPut(0x04, si, 4, "UInt") ; SIF_POS
    NumPut(newPx, si, 20, "Int")
    DllCall("SetScrollInfo", "Ptr", hPanel, "Int", 1, "Ptr", &si, "Int", 1)
}

OnShortcutsVScroll(wParam, lParam, msg, hwnd) {
    global TabScrollHwndToNum, TabScrollPos
    if (!IsObject(TabScrollHwndToNum) || !TabScrollHwndToNum.HasKey(hwnd))
        return
    tabNum := TabScrollHwndToNum[hwnd]

    sbCode := wParam & 0xFFFF
    scale := A_ScreenDPI / 96.0
    VarSetCapacity(rc, 16, 0)
    DllCall("GetClientRect", "Ptr", hwnd, "Ptr", &rc)
    pageLogical := Round(NumGet(rc, 12, "Int") / scale)

    newPos := TabScrollPos[tabNum]
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
        DllCall("GetScrollInfo", "Ptr", hwnd, "Int", 1, "Ptr", &si)
        trackPx := NumGet(si, 24, "Int")
        newPos := Round(trackPx / scale)
    } else {
        return
    }
    ScrollTabTo(tabNum, newPos)
    return 0
}

OnShortcutsMouseWheel(wParam, lParam, msg, hwnd) {
    global TabScrollHwnds, TabScrollPos, currentSettingsTab
    if (currentSettingsTab < 1 || currentSettingsTab > 4)
        return
    hPanel := TabScrollHwnds[currentSettingsTab]
    if (!hPanel)
        return
    if (hwnd != hPanel && !DllCall("IsChild", "Ptr", hPanel, "Ptr", hwnd))
        return

    delta := (wParam >> 16) & 0xFFFF
    if (delta > 0x7FFF)
        delta -= 0x10000
    step := (delta > 0) ? -45 : 45
    ScrollTabTo(currentSettingsTab, TabScrollPos[currentSettingsTab] + step)
    return 0
}

; ========================================================
; CÀI ĐẶT MICROPHONE (BẮT PHÍM TẮT & ĐỒNG BỘ TRẠNG THÁI)
; ========================================================
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
    UpdateShortcutsCardSummaries()
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
    UpdateShortcutsCardSummaries()
}

OnChangeMicToggleHotkey:
    global MicMuteHotkey
    ShowHotkeyPickerDialog({id: "mic_toggle"
        , title: L("Mic_HotkeyDlgTitle")
        , prompt: L("Mic_HotkeyPrompt")
        , current: MicMuteHotkey
        , default: "#!m"
        , allowSingleModifier: false
        , allowMouse: true
        , allowClear: true
        , onSave: Func("SavePickedMicToggleHotkey")})
return

OnChangeMicPttHotkey:
    global MicPttHotkey
    ShowHotkeyPickerDialog({id: "mic_ptt"
        , title: L("Mic_HotkeyDlgTitle")
        , prompt: L("Mic_PttPrompt")
        , current: MicPttHotkey
        , default: "RCtrl"
        , allowSingleModifier: true
        , allowMouse: true
        , allowClear: true
        , onSave: Func("SavePickedMicPttHotkey")})
return

SavePickedMicToggleHotkey(newHk) {
    global MicMuteHotkey
    MicMuteHotkey := newHk
    GuiControl, ShortcutsScroll:, MicHotkeyBtn, % FormatHotkeyText(MicMuteHotkey)
    if (IsFunc("RebuildTrayMenu"))
        RebuildTrayMenu()
    if (IsFunc("SaveMicMuteSettings"))
        SaveMicMuteSettings()
    UpdateShortcutsCardSummaries()
}

SavePickedMicPttHotkey(newHk) {
    global MicPttHotkey
    MicPttHotkey := newHk
    GuiControl, ShortcutsScroll:, MicPttHotkeyBtn, % FormatHotkeyText(MicPttHotkey)
    if (IsFunc("SaveMicMuteSettings"))
        SaveMicMuteSettings()
    UpdateShortcutsCardSummaries()
}
