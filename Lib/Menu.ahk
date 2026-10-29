; Menu.ahk - Quản lý Menu Tray, Cài đặt và Giới thiệu
#NoEnv

Menu:
    global hSettingsGui := 0, hAboutGui := 0, hLockOpt := 0, hAutoLock := 0
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
    Menu, Tray, Add, % L("Tray_RunAsAdmin"), RunAsAdmin

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
    Menu, Tray, Add, % L("Tray_Reload"), ReloadApp
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
    } else if (lParam = 0x203) { ; WM_LBUTTONDBLCLK: Nhấp đúp -> Hoàn lại trạng thái ban đầu và mở Cài đặt
        ToggleGestureScroll() ; Đảo trạng thái lần 2 để sau 2 lần nhấp vẫn giữ nguyên trạng thái ban đầu
        ToolTip ; Tắt thông báo tooltip bật/tắt
        Gosub, Settings
        return 0
    }
}

; khởi tạo ban đầu gồm menu, icon tray, script dừng ở đây và chờ sự kiện từ menu khay hệ thống, "return" ngăn không cho các label khác tự động chạy
return


; Tạo GUI cài đặt - Settings
Settings:
Gui, Settings:New, +HwndhSettingsGui,, % L("Set_Title")
SetGuiYellowIcon(hSettingsGui)
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

Gui, Add, Text, x38 y305, % L("Set_Mute")
Gui, Add, Picture, x18 yp+1 w14 h14 Icon3, %A_WinDir%\System32\SndVol.exe
Gui, Add, Button, x200 y300 w130 Center gShowTooltip vText10, Ctrl + Shift + M

Gui, Add, Text, x38 y330, % L("Set_AutoLock")
Gui, Add, Picture, x15 yp+1 w14 h14 Icon48, %A_WinDir%\System32\shell32.dll
Gui, Add, Button, x200 y325 w130 Center gShowTooltip vText11, Ctrl + Shift + L

Gui, Add, Text, x38 y355, % L("Set_Volume")
Gui, Add, Picture, x18 yp+1 w14 h14 Icon2, %A_WinDir%\System32\SndVol.exe
Gui, Add, Button, x200 y350 w155 Center gShowTooltip vText12, Win + Scroll Up/Down

Gui, Add, Text, x38 y380, % L("Set_Brightness")
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
SetGuiYellowIcon(hSettingsGui)
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

    Gui, LockOptions:New, +LastFound +OwnerSettings +HwndhLockOpt, % L("Opt_Title")
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

ShowAbout:
    Gui, About:New, -MaximizeBox -MinimizeBox +HwndhAboutGui, % L("About_Title")
    SetGuiYellowIcon(hAboutGui)
    Gui, Font, s10, Segoe UI

    Gui, Add, GroupBox, x10 y5 w420 h95,
    ; Icon (bên trong GroupBox)
    aboutIcon := A_IsCompiled ? A_ScriptFullPath : (A_ScriptDir . "\image\unnamed.ico")
    Gui, Add, Picture, x20 y25 w32 h32 Icon1, %aboutIcon%
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
        1. Right Mouse Gestures (Browsers & File Explorer):
        - Hold Right Mouse Button and move in direction:
          • Left (←): Go back to previous page
          • Right (→): Go forward to next page
          • Up then Left (↑__): Switch to previous tab
          • Down then Left (↓¯¯): Switch to next tab
          • Right then Up (__↑): Close current tab
          • Right then Down (¯¯↓): Reload / Refresh current page
        * Drawing gestures work in Chrome, Edge, Firefox, CocCoc, Brave... and File Explorer (when no file is selected).

        2. Mouse Scrolling (All Windows):
        - Hold Right Click + drag up/down: Direct scroll (scroll content or scrollbar, configurable in Settings).
        - Hold Right Click + flick up/down then release: Trigger inertial Auto-Scroll. Click left/middle button or move mouse to stop.
        - Hold Right Click + scroll mouse wheel: Fast page scroll (Page Up / Page Down).

        3. Volume & Brightness:
        - Hold Left Click + scroll wheel: Quickly adjust volume up / down.
        - Win + Scroll (or Win + PgUp/PgDn): Increase / Decrease system volume.
        - Ctrl + Shift + M: Mute / Unmute system audio.
        - F9 / F10: Decrease / Increase screen brightness.

        4. Useful Hotkeys:
        - Ctrl + Alt (or click tray icon): Toggle gestures & mouse scrolling (colored icon: On, gray icon: Off).
        - Ctrl + Alt + L: Lock keyboard (and optional mouse clicks). Type 'unlock' to unlock.
        - Ctrl + Shift + L: Schedule auto screen lock countdown timer.
        - Ctrl + Shift + V: Paste plain text (automatically trims whitespace and empty newlines at start/end).

        5. System Permissions & Elevated Apps:
        - To use in Task Manager or elevated Administrator windows (UIPI):
          => Right-click tray icon > select "Run as Administrator" or "Install to System (UIAccess)".
        )
    } else {
        UsageGuideText =
        ( LTrim Join`n
        1. Cử chỉ chuột phải (Trình duyệt & File Explorer):
        Giữ chuột phải và rê theo các hướng để thao tác nhanh:
          - Sang trái (←): Quay lại trang trước (Back)
          - Sang phải (→): Tiến tới trang tiếp theo (Forward)
          - Lên rồi Trái (↑__): Chuyển sang tab trước đó
          - Xuống rồi Trái (↓¯¯): Chuyển sang tab tiếp theo
          - Phải rồi Lên (__↑): Đóng tab hiện tại
          - Phải rồi Xuống (¯¯↓): Tải lại / Làm mới trang
        * Cử chỉ vẽ hỗ trợ trên Chrome, Edge, Firefox, Cốc Cốc, Brave... và File Explorer (khi không chọn file).

        2. Thao tác cuộn chuột (Tất cả cửa sổ):
        - Giữ chuột phải + rê lên/xuống: Cuộn trang trực tiếp (cuộn nội dung hoặc kéo thanh cuộn tùy Cài đặt).
        - Giữ chuột phải + vuốt nhanh lên/xuống rồi thả: Cuộn tự động theo quán tính (Auto-Scroll). Nhấp chuột trái/giữa hoặc rê chuột để dừng cuộn.
        - Giữ chuột phải + lăn bánh xe: Cuộn nhanh từng trang (Page Up / Page Down).

        3. Âm lượng & Độ sáng:
        - Giữ chuột trái + lăn bánh xe: Tăng / Giảm âm lượng nhanh chóng.
        - Win + Lăn chuột (hoặc Win + PgUp/PgDn): Tăng / Giảm âm lượng hệ thống.
        - Ctrl + Shift + M: Bật / Tắt âm thanh hệ thống (Mute).
        - F9 / F10: Giảm / Tăng độ sáng màn hình.

        4. Phím tắt tiện ích:
        - Ctrl + Alt (hoặc click chuột trái icon khay): Bật / Tắt cử chỉ và cuộn chuột (icon màu: Bật, icon xám: Tắt).
        - Ctrl + Alt + L: Khóa bàn phím (và chuột tùy chọn). Gõ chữ 'unlock' để mở khóa.
        - Ctrl + Shift + L: Hẹn giờ tự động khóa màn hình.
        - Ctrl + Shift + V: Dán văn bản thuần túy (tự động xóa khoảng trắng và dòng trống ở đầu/cuối).

        5. Quyền hệ thống & Ứng dụng Quản trị:
        - Để hoạt động trên Task Manager hoặc ứng dụng chạy quyền Administrator (UIPI):
          => Nhấp chuột phải icon khay > chọn "Chạy với quyền Administrator" hoặc "Cài đặt vào hệ thống (UIAccess)".
        )
    }
    
    Gui, Add, Edit, x20 y145 w400 h190 ReadOnly +VScroll ClassEdit1 +Border, %UsageGuideText%

    Gui, Font, s9, Segoe UI
    Gui, Add, Text, x15 y360 Left, % L("About_Author")
    Gui, Add, Link, x+2 y360 Left, <a href="mailto:nguyentrian87@gmail.com">Email</a>
    Gui, Add, Button, x350 y358 w70 gOpenDonateLink, % L("About_Donate")

    ; Hiển thị GUI
    Gui, Show, AutoSize Center, % L("About_Title")
    SetGuiYellowIcon(hAboutGui)
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

    ; 3. Copy file vào Program Files
    FileCopy, %A_ScriptFullPath%, %destExe%, 1
    if (ErrorLevel) {
        MsgBox, 16, GestureMouse, % L("Install_Error") . "Không thể sao chép file vào " . destDir
        return
    }

    ; 4. Tạo Shortcut trong Start Menu
    startMenuDir := A_AppDataCommon . "\Microsoft\Windows\Start Menu\Programs\GestureMouse"
    FileCreateDir, %startMenuDir%
    FileCreateShortcut, %destExe%, %startMenuDir%\GestureMouse.lnk, %destDir%,, GestureMouse

    ; 5. Khởi chạy bản đã cài đặt trong Program Files
    Run, "%destExe%"

    ; 6. Thoát bản hiện tại
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
    DetectHiddenWindows, %dhw%
}
