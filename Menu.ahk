; Menu.ahk - Quản lý Menu Tray, Cài đặt và Giới thiệu
#NoEnv

Menu:
    ; Khởi tạo ngôn ngữ và trạng thái cử chỉ
    InitLanguage()
    InitGestureScroll()

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
    global Brightness, GuiOn, isLocked, mouseLockEnabled, GestureScrollEnabled
    TrayTip := L("Tip_Title")
    
    GestureTip := L("Tip_Gesture") . (GestureScrollEnabled ? L("Tip_On") : L("Tip_Off")) . "`n"
    LockKeyboardTip := L("Tip_LockKB") . (isLocked ? L("Tip_On") : L("Tip_Off")) . "`n"
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
    Menu, PhimTat, Add, % L("Sub_Toggle"), ToggleGestureScrollLabel
    Menu, PhimTat, Add, % L("Sub_LockKB"), LockKeyboard
    Menu, PhimTat, Add, % L("Sub_AutoLock"), ShowLockScreenGUI
    Menu, PhimTat, Add, % L("Sub_PlainText"), PastePlainText
    Menu, PhimTat, Add, % L("Sub_Mute"), MuteFunc

    ; Sub-menu Ngôn ngữ / Language kèm icon lá cờ
    flagVn := A_ScriptDir . "\image\flag_vn.ico"
    flagEn := A_ScriptDir . "\image\flag_en.ico"

    Menu, LangMenu, Add, Tiếng Việt, SetLangVI
    if FileExist(flagVn)
        Menu, LangMenu, Icon, Tiếng Việt, %flagVn%

    Menu, LangMenu, Add, English, SetLangEN
    if FileExist(flagEn)
        Menu, LangMenu, Icon, English, %flagEn%

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
    Menu, Tray, Add, % L("Tray_RunAsAdmin"), RunAsAdmin
    Menu, Tray, Add, % L("Tray_Shortcuts"), :PhimTat

    ; Menu chọn ngôn ngữ (gắn cờ của ngôn ngữ hiện tại)
    langMenuLabel := L("Tray_Language")
    Menu, Tray, Add, %langMenuLabel%, :LangMenu
    currentFlag := (CurrentLang = "en") ? flagEn : flagVn
    if FileExist(currentFlag)
        Menu, Tray, Icon, %langMenuLabel%, %currentFlag%

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
    global GestureScrollEnabled
    try {
        menuGestureText := GestureScrollEnabled ? L("Tray_Enabled") : L("Tray_Disabled")
        Menu, Tray, Rename, 1&, %menuGestureText%
        if (GestureScrollEnabled)
            Menu, Tray, Check, 1&
        else
            Menu, Tray, Uncheck, 1&
        Menu, Tray, Default, 1&
    }
}

; Xử lý sự kiện chuột trên icon khay:
; - Click 1 lần: Bật/Tắt ngay lập tức không cần chờ delay
; - Double-click: Mở ngay cửa sổ Cài đặt
AHK_NOTIFYICON(wParam, lParam) {
    if (lParam = 0x202) { ; WM_LBUTTONUP: Nhấp chuột trái -> Bật/Tắt ngay lập tức
        ToggleGestureScroll()
        return 0
    } else if (lParam = 0x203) { ; WM_LBUTTONDBLCLK: Nhấp đúp -> Mở Cài đặt
        Gosub, Settings
        return 0
    }
}

; khởi tạo ban đầu gồm menu, icon tray, script dừng ở đây và chờ sự kiện từ menu khay hệ thống, "return" ngăn không cho các label khác tự động chạy
return


; Tạo GUI cài đặt - Settings
Settings:
Gui, Settings:New,, % L("Set_Title")
Gui, Font, s10, Arial

; Tải trạng thái cài đặt từ registry, Autostart là giá trị, AutoStart là tên giá trị trong registry
RegRead, AutoStart, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, GestureMouse
AutoStart := (AutoStart != "") ? 1 : 0 

; Đọc từ registry để thiết lập radio
RegRead, ScrollStyle, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, ScrollStyle
if (ErrorLevel || ScrollStyle = "" || ScrollStyle < 1 || ScrollStyle > 2) {
    ScrollStyle := 1  ; Mặc định chọn radio 1
    ; Ghi giá trị mặc định vào registry nếu không tồn tại hoặc không hợp lệ
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, ScrollStyle, %ScrollStyle%
}
; Tạo mảng liên kết cho tooltip đa ngôn ngữ
Tooltips := {}
Tooltips["Text1"] := L("TT_1")
Tooltips["Text2"] := L("TT_2")
Tooltips["Text3"] := L("TT_3")
Tooltips["Text4"] := L("TT_4")
Tooltips["Text5"] := L("TT_5")
Tooltips["Text6"] := L("TT_6")
Tooltips["Text7"] := L("TT_7")
Tooltips["Text8"] := L("TT_8")
Tooltips["Text9"] := L("TT_9")
Tooltips["Text10"] := L("TT_10")
Tooltips["Text11"] := L("TT_11")
Tooltips["Text12"] := L("TT_12")
Tooltips["Text13"] := L("TT_13")
Tooltips["Text14"] := L("TT_14")
Tooltips["Text15"] := L("TT_15")
Tooltips["TextInfo"] := L("TT_Info")

; Nhóm Gesture Mouse
Gui, Font, Bold
Gui, Add, GroupBox, w500 h260, % L("Set_GroupGesture")
Gui, Add, Picture, x160 yp+1 w14 h14 Icon100, %A_WinDir%\System32\shell32.dll
Gui, Font, Normal
Gui, Add, Text, x20 y35, % L("Set_ManualScroll")
Gui, Add, Button, x200 y30 Center gShowTooltip vText1, % L("Set_ManualScrollBtn")
Gui, Add, Text, x20 y60, % L("Set_AutoScroll")
Gui, Add, Button, x200 y55 Center gShowTooltip vText2, % L("Set_AutoScrollBtn")
Gui, Add, Text, x20 y82, % L("Set_PgScroll")
Gui, Add, Button, x200 y80 Center gShowTooltip vText3, % L("Set_PgScrollBtn")
Gui, Add, Text, x20 y110, % L("Set_Back")
Gui, Add, Button, x200 y105 w38 Center gShowTooltip vText4,  ←
Gui, Add, Text, x20 y135, % L("Set_Forward")
Gui, Add, Button, x200 y130 w38 Center gShowTooltip vText5,  →
Gui, Add, Text, x20 y160, % L("Set_PrevTab")
Gui, Add, Button, x200 y155 w38 Center gShowTooltip vText6,  ↑__
Gui, Add, Text, x20 y185, % L("Set_NextTab")
Gui, Add, Button, x200 y180 w38 Center gShowTooltip vText7,  ↓¯¯
Gui, Add, Text, x20 y210, % L("Set_CloseTab")
Gui, Add, Button, x200 y205 w38 Center gShowTooltip vText8,  __↑
Gui, Add, Text, x20 y235, % L("Set_Refresh")
Gui, Add, Button, x200 y230 w38 Center gShowTooltip vText9,  ¯¯↓

; Nhóm Hotkeys
Gui, Font, Bold
Gui, Add, GroupBox, xs w500 h170, % L("Set_GroupHotkeys")
Gui, Font, Normal

Gui, Add, Text, x38 y305, Mute
Gui, Add, Picture, x18 yp+1 w14 h14 Icon3, %A_WinDir%\System32\SndVol.exe
Gui, Add, Button, x200 y300 w130 Center gShowTooltip vText10, Ctrl + Shift + M

Gui, Add, Text, x38 y330, Auto Screen Lock
Gui, Add, Picture, x15 yp+1 w14 h14 Icon48, %A_WinDir%\System32\shell32.dll
Gui, Add, Button, x200 y325 w130 Center gShowTooltip vText11, Ctrl + Shift + L

Gui, Add, Text, x38 y355, Volume up/down
Gui, Add, Picture, x18 yp+1 w14 h14 Icon2, %A_WinDir%\System32\SndVol.exe
Gui, Add, Button, x200 y350 w155 Center gShowTooltip vText12, Win + Scroll Up/Down

Gui, Add, Text, x38 y380, Brightness
Gui, Add, Picture, x18 yp+1 w14 h14 Icon26, %A_WinDir%\System32\shell32.dll
Gui, Add, Button, x200 y375 w130 Center gShowTooltip vText13, F9/F10

Gui, Add, Text, x38 y405, % L("Set_LockKBAndMouse")
Gui, Add, Picture, x18 yp+1 w14 h14 Icon28, %A_WinDir%\System32\ddores.dll
Gui, Add, Button, x200 y400 w130 Center gShowTooltip vText14, Ctrl + Alt + L
Gui, Add, Picture, x335 yp+5 w14 h14 gShowTooltip vTextInfo Icon-200, %A_WinDir%\System32\shell32.dll

; Thêm sự kiện nhấn nút để chạy hàm CreateOption()
Gui, Add, Button, x355 y400 w80 Center gCreateOption, % L("Set_OptionsBtn")

; Nhóm Cài đặt chung
Gui, Font, Bold
Gui, Add, GroupBox, xs w500 h115, % L("Set_GroupGeneral")
Gui, Font, Normal
Gui, Add, Checkbox, x30 y475 vAutoStart gSave Checked%AutoStart%, % L("Set_AutoStart")
Gui, Add, Text, x20 y500, % L("Set_ScrollMethodLabel")
Gui, Add, Radio, x30 y525 vScrollStyle1 gSave Group Checked%ScrollStyle1%, % L("Set_ScrollStyle1")
Gui, Add, Radio, x30 y545 vScrollStyle2 gSave Checked%ScrollStyle2%, % L("Set_ScrollStyle2")

; Checked radio theo giá trị từ registry
GuiControl,, ScrollStyle1, % (ScrollStyle = 1) 
GuiControl,, ScrollStyle2, % (ScrollStyle = 2)

; Theo dõi sự kiện chuột
Gui, +LastFound
OnMessage(0x200, "WM_MOUSEMOVE")  ; Theo dõi di chuyển chuột cho tooltip

; Hiển thị giao diện
Gui, Show, AutoSize Center, % "Gesture Mouse - " . L("Set_Title")
return

; Biến toàn cục để theo dõi trạng thái chuột
global LastHoveredControl := ""
global LastHoveredHwnd := ""

; Xử lý di chuyển chuột – cập nhật tooltip
WM_MOUSEMOVE() {
    global LastHoveredHwnd, LastHoveredControl
    MouseGetPos,,, , CtrlUnderMouse

    ; Nếu di chuyển sang control khác => reset
    if (CtrlUnderMouse != LastHoveredHwnd) {
        LastHoveredHwnd := ""      ; reset để ShowTooltip xử lý lại
        LastHoveredControl := ""
    }

    Gosub, ShowTooltip
}

; Hiển thị tooltip nếu có control hợp lệ
ShowTooltip:
    MouseGetPos, , , , CtrlUnderMouse, A
    GuiControlGet, CtrlName, Name, %CtrlUnderMouse%

    if (CtrlUnderMouse && Tooltips[CtrlName]) {
        if (LastHoveredHwnd != CtrlUnderMouse) {
            ToolTip, % Tooltips[CtrlName]
            LastHoveredControl := CtrlName
            LastHoveredHwnd := CtrlUnderMouse
        }
    } else {
        ToolTip
        LastHoveredControl := ""
        LastHoveredHwnd := ""
    }
return

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
    
    ; Lưu cài đặt phong cách cuộn vào registry TRIAN\GestureMouse
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, ScrollStyle, %ScrollStyle%
return

CreateOption() {
    global mouseLockEnabled, disableAutoLockScreen

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, mouseLockEnabled 
    if (val != "")
        mouseLockEnabled := val

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, disableAutoLockScreen
    if (val != "")
        disableAutoLockScreen := val

    Gui, LockOptions:New, +LastFound +OwnerSettings, % L("Opt_Title")
    Gui, Font, s10, Arial
    Gui, Add, Checkbox, Checked Disabled, % L("Opt_LockKB")
    Gui, Add, Checkbox, vmouseLockEnabled gSaveOption Checked%mouseLockEnabled%, % L("Opt_LockMouse")
    Gui, Add, Checkbox, vdisableAutoLockScreen gSaveOption Checked%disableAutoLockScreen% Disabled, % L("Opt_PreventAutoLock")
    Gui, LockOptions:Show, AutoSize Center, % L("Opt_Title")
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

ShowAbout:
    Gui, About:New, -MaximizeBox -MinimizeBox, % L("About_Title")
    Gui, Font, s10, Segoe UI

    Gui, Add, GroupBox, x10 y5 w420 h95,
    ; Icon (bên trong GroupBox)
    Gui, Add, Picture, x20 y25 w32 h32, unnamed.ico
    ; Dòng 1: Tên ứng dụng
    Gui, Font, s18, Segoe UI
    Gui, Add, Text, x65 y18 w360, Gesture Mouse
    Gui, Font, s10 Normal, Segoe UI
    ; Dòng 2: Headline
    Gui, Add, Text, x65 y50 w360, % L("About_Headline")
    ; Dòng 3: Phiên bản và Ngày cập nhật
    Gui, Font, s9, Segoe UI
    Gui, Add, Text, x65 y70 w360, % L("About_Version")

    Gui, Add, Text, x20 y125, % L("About_GuideTitle")
    
    if (CurrentLang = "en") {
        UsageGuideText =
        ( LTrim Join`n
        Right Mouse Gestures:
        - Hold Right Mouse Button and draw gestures (L, R, U, D, LU, LD, RU, RD) to perform actions (back, forward, close tab, reload, switch tab).
        - See details and custom settings in Settings.

        Scrolling:
        - Hold Right Click + drag up/down: Direct content scroll (or scrollbar, per settings).
        - Hold Right Click + flick up/down then release: Trigger Auto-Scroll.
        - Hold Right Click + scroll mouse wheel: Page scroll (PgUp/PgDn).

        Hotkeys:
        - Ctrl+Alt (or click tray icon): Toggle mouse gestures & scroll (gray icon when disabled).
        - Ctrl+Alt+L: Lock/Unlock keyboard (+optional mouse lock). Type 'unlock' to unlock.
        - Ctrl+Shift+L: Open Auto Screen Lock countdown timer.
        - Ctrl+Shift+M: Mute/Unmute system audio.
        - Win + Scroll / Win + PgUp/PgDn: Increase/Decrease system volume.
        - F9 / F10: Decrease/Increase screen brightness.

        Other:
        - Some system apps (e.g. Task Manager) or elevated admin apps require Gesture Mouse to run as Administrator.
        - Press Ctrl + Shift + V to paste plain text (trims whitespace, tabs, newlines).
        - Minimize active window and restore recent windows with Ctrl + F1 and Ctrl + F2.
        )
    } else {
        UsageGuideText =
        ( LTrim Join`n
        Cử chỉ chuột phải:
        - Giữ chuột phải và vẽ các hình dạng (L, R, U, D, LU, LD, RU, RD) để thực hiện hành động (quay lại, tới, đóng tab, làm mới, chuyển tab).
        - Xem chi tiết và tùy chỉnh (nếu có) trong Cài đặt.

        Cuộn:
        - Giữ chuột phải + rê lên/xuống: Cuộn nội dung trực tiếp (hoặc thanh cuộn, tùy cài đặt).
        - Giữ chuột phải + vuốt nhanh lên/xuống rồi thả: Kích hoạt cuộn tự động (AutoScroll).
        - Giữ chuột phải + lăn bánh xe: Cuộn trang (PgUp/PgDn).

        Phím tắt (Hotkeys):
        - Ctrl+Alt (hoặc nhấp chuột trái vào icon khay hệ thống): Bật/Tắt cử chỉ chuột và cuộn (icon xám trắng khi tắt).
        - Ctrl+Alt+L: Khóa/Mở khóa bàn phím (+chuột tùy chọn). Gõ 'unlock' để mở khóa.
        - Ctrl+Shift+L: Mở cửa sổ hẹn giờ khóa màn hình.
        - Ctrl+Shift+M: Tắt/Bật âm thanh hệ thống (Mute).
        - Win + Lăn chuột / Win + PgUp/PgDn: Tăng/Giảm âm lượng hệ thống.
        - F9 / F10: Giảm/Tăng độ sáng màn hình.

        Khác:
        - Một số ứng dụng hệ thống (như Task Manager) hoặc ứng dụng chạy quyền Administrator (UIPI) có thể không hoạt động với cử chỉ chuột phải
        => Cách khắc phục là chạy Gesture Mouse với quyền Administrator.
        - Nhấn Ctrl + Shift + V để dán văn bản không định dạng (bỏ qua khoảng trắng, tab, xuống dòng trước và sau).
        - Thu nhỏ window đang active và phục hồi window mới thu nhỏ nhất bằng Ctrl + F1 và Ctrl + F2. 
        )
    }
    
    Gui, Add, Edit, x20 y145 w400 h190 ReadOnly +VScroll ClassEdit1 +Border, %UsageGuideText%

    Gui, Font, s9, Segoe UI
    Gui, Add, Text, x15 y360 Left, % L("About_Author")
    Gui, Add, Link, x+2 y360 Left, <a href="mailto:nguyentrian87@gmail.com">Email</a>
    Gui, Add, Button, x350 y358 w70 gOpenDonateLink, % L("About_Donate")

    ; Hiển thị GUI
    Gui, Show, AutoSize Center, % L("About_Title")
    GuiControl, About:Focus, Static1
return

OpenDonateLink:
    Run, https://your-donation-link.com
return

SettingsGuiEscape:
AboutGuiEscape:
LockOptionsGuiEscape:
    Gui, Destroy
return

ExitMenu:
    ExitApp
return
