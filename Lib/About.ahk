; About.ahk - Quản lý cửa sổ Giới thiệu và Hướng dẫn sử dụng
#NoEnv

global DonateURL := "https://paypal.me/nguyentrian87"

ShowAbout:
    if (hAboutGui && WinExist("ahk_id " . hAboutGui)) {
        WinActivate, ahk_id %hAboutGui%
        return
    }

    Gui, About:New, -MaximizeBox -MinimizeBox +HwndhAboutGui, % L("About_Title")
    SetGuiYellowIcon(hAboutGui)

    ; Header: Luôn hiển thị (Logo, Tên ứng dụng, Slogan, Phiên bản, Tác giả và Nút Donate)
    aboutIcon := A_IsCompiled ? A_ScriptFullPath : (A_ScriptDir . "\image\unnamed.ico")
    iconManual := A_ScriptDir . "\image\scroll_manual.ico"
    iconAuto   := A_ScriptDir . "\image\scroll_auto.ico"
    iconPage   := A_ScriptDir . "\image\scroll_page.ico"
    iconVol    := A_ScriptDir . "\image\mouse_volume.ico"

    Gui, Add, Picture, x20 y15 w40 h40 Icon1, %aboutIcon%
    
    Gui, Font, s14 Bold c004499, Segoe UI
    Gui, Add, Text, x68 y10 w380, Gesture Mouse
    Gui, Font, s9 Norm c222222, Segoe UI
    Gui, Add, Text, x68 y32 w380, % L("About_Headline")
    Gui, Font, s8.5 Norm c666666, Segoe UI
    Gui, Add, Text, x68 y52, % L("About_Version") . "  •  " . L("About_Author")
    Gui, Add, Picture, x+6 yp w15 h15 Icon157 gOpenEmailLink +Cursor, %A_WinDir%\System32\shell32.dll

    ; Nút Donate góc trên bên phải
    Gui, Font, s9.5 Norm, Segoe UI
    Gui, Add, Button, x470 y16 w90 h28 gOpenDonateLink, % "❤ " . L("About_Donate")

    ; Tab Control: Tab headers chữ thường (không in đậm), tên ngắn gọn
    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Tab2, x15 y76 w545 h270 vAboutTab gOnAboutTabChange, % L("About_TabGestures") . "|" . L("About_TabShortcuts") . "|" . L("About_TabSystem")

    ; Tạo mảng liên kết cho tooltip đa ngôn ngữ trên trang About
    AboutTooltips := {}
    AboutTooltips["Text1"] := L("TT_1")
    AboutTooltips["Text2"] := L("TT_2")
    AboutTooltips["Text3"] := L("TT_3")
    AboutTooltips["TextVol"] := L("TT_MouseVolume")
    AboutTooltips["Text4"] := L("TT_4")
    AboutTooltips["Text5"] := L("TT_5")
    AboutTooltips["Text6"] := L("TT_6")
    AboutTooltips["Text7"] := L("TT_7")
    AboutTooltips["Text8"] := L("TT_8")
    AboutTooltips["Text9"] := L("TT_9")
    AboutTooltips["Text10"] := L("TT_10")
    AboutTooltips["Text11"] := L("TT_11")
    AboutTooltips["Text12"] := L("TT_12")
    AboutTooltips["Text13"] := L("TT_13")
    AboutTooltips["Text14"] := L("TT_14")
    AboutTooltips["TextInfo"] := L("TT_Info")
    AboutTooltips["TextPaste"] := L("TT_PastePlain")
    AboutTooltips["TextToggle"] := (CurrentLang = "en") ? "Toggle gestures and advanced scroll on/off" : "Bật hoặc tắt nhanh toàn bộ cử chỉ và cuộn chuột (hoặc nhấp chuột vào icon khay)"

    if (CurrentLang = "en") {
        TabSystemText =
        ( LTrim Join`n
        [ SYSTEM PERMISSIONS & ELEVATED APPS (UIPI) ]
        Windows User Interface Privilege Isolation (UIPI) blocks standard applications from sending mouse/keyboard input to elevated Administrator windows (e.g., Task Manager, Registry Editor, software installers...).

        To allow GestureMouse to work seamlessly across all windows:
          1. Right-click the system tray icon.
          2. Select "Run as Administrator".
          3. Or choose "Install to System (UIAccess)" to run with UI access on startup without annoying UAC prompts.

        [ QUICK TIPS ]
          • In File Explorer, gestures work when no files are selected. If files are selected, dragging is treated as standard file drag & drop.
          • Double-click the tray icon to quickly open Settings.
          • Press Ctrl + Alt to quickly toggle gestures off while gaming.
        )
    } else {
        TabSystemText =
        ( LTrim Join`n
        [ QUYỀN HỆ THỐNG & ỨNG DỤNG QUẢN TRỊ (UIPI) ]
        Windows có cơ chế bảo mật (UIPI) ngăn ứng dụng quyền thường gửi thao tác chuột/phím vào các cửa sổ chạy quyền Administrator (ví dụ: Task Manager, Registry Editor, cửa sổ cài đặt phần mềm...).

        Để GestureMouse hoạt động trơn tru trên mọi cửa sổ:
          1. Nhấp chuột phải vào biểu tượng khay hệ thống.
          2. Chọn "Chạy với quyền Administrator" (Run as Admin).
          3. Hoặc chọn "Cài đặt vào hệ thống (UIAccess)" để tự động kích hoạt mỗi lần máy tính khởi động mà không bị hộp thoại UAC hỏi phiền phức.

        [ MẸO SỬ DỤNG NHANH ]
        • Trong File Explorer, cử chỉ vẽ hoạt động khi bạn không chọn file nào. Nếu đang chọn file, thao tác kéo chuột sẽ hiểu là kéo thả file bình thường.
        • Nhấp đúp chuột trái vào icon khay hệ thống để mở nhanh cửa sổ Cài đặt.
        • Để tắt tạm thời chức năng cử chỉ khi chơi game, chỉ cần bấm Ctrl + Alt.
        )
    }

    ; ========================================================
    ; TAB 1: CỬ CHỈ CHUỘT & CUỘN (Kèm Icon thao tác chuột riêng)
    ; ========================================================
    Gui, Tab, 1
    Gui, Font, s9.5 Norm c000000, Segoe UI

    ; 4 thao tác cuộn chuột & âm lượng (Kèm icon chuột minh họa thao tác rõ ràng)
    if FileExist(iconManual)
        Gui, Add, Picture, x28 y116 w24 h24, %iconManual%
    Gui, Add, Text, x58 y118 w145, % L("Set_ManualScroll")
    Gui, Add, Button, x210 y115 w335 h25 Center gShowAboutTooltip vText1, % L("Set_ManualScrollBtn")

    if FileExist(iconAuto)
        Gui, Add, Picture, x28 y146 w24 h24, %iconAuto%
    Gui, Add, Text, x58 y148 w145, % L("Set_AutoScroll")
    Gui, Add, Button, x210 y145 w335 h25 Center gShowAboutTooltip vText2, % L("Set_AutoScrollBtn")

    if FileExist(iconPage)
        Gui, Add, Picture, x28 y176 w24 h24, %iconPage%
    Gui, Add, Text, x58 y178 w145, % L("Set_PgScroll")
    Gui, Add, Button, x210 y175 w335 h25 Center gShowAboutTooltip vText3, % L("Set_PgScrollBtn")

    if FileExist(iconVol)
        Gui, Add, Picture, x28 y206 w24 h24, %iconVol%
    Gui, Add, Text, x58 y208 w145, % L("Set_MouseVolume")
    Gui, Add, Button, x210 y205 w335 h25 Center gShowAboutTooltip vTextVol, % L("Set_MouseVolumeBtn")

    ; Dòng tiêu đề cử chỉ trình duyệt
    Gui, Font, s9.5 Bold c004499, Segoe UI
    Gui, Add, Text, x28 y244, % (CurrentLang = "en" ? "Browser & File Explorer Gestures (Hold Right Mouse Button):" : "Cử chỉ trình duyệt & File Explorer (Giữ chuột phải):")
    Gui, Font, s9.5 Norm c000000, Segoe UI

    ; 6 cử chỉ trình duyệt chia 2 cột đối xứng
    Gui, Add, Text, x28 y274 w145, % L("Set_Back")
    Gui, Add, Button, x178 y270 w44 h25 Center gShowAboutTooltip vText4, ←
    Gui, Add, Text, x285 y274 w145, % L("Set_Forward")
    Gui, Add, Button, x501 y270 w44 h25 Center gShowAboutTooltip vText5, →

    Gui, Add, Text, x28 y304 w145, % L("Set_PrevTab")
    Gui, Add, Button, x178 y300 w44 h25 Center gShowAboutTooltip vText6, ↑__
    Gui, Add, Text, x285 y304 w145, % L("Set_NextTab")
    Gui, Add, Button, x501 y300 w44 h25 Center gShowAboutTooltip vText7, ↓¯¯

    Gui, Add, Text, x28 y334 w145, % L("Set_CloseTab")
    Gui, Add, Button, x178 y330 w44 h25 Center gShowAboutTooltip vText8, __↑
    Gui, Add, Text, x285 y334 w145, % L("Set_Refresh")
    Gui, Add, Button, x501 y330 w44 h25 Center gShowAboutTooltip vText9, ¯¯↓

    ; ========================================================
    ; TAB 2: PHÍM TẮT & TIỆN ÍCH (Kèm Icon hệ thống Windows)
    ; ========================================================
    Gui, Tab, 2
    Gui, Font, s9.5 Norm c000000, Segoe UI

    Gui, Add, Picture, x28 y116 w22 h22 Icon3, %A_WinDir%\System32\SndVol.exe
    Gui, Add, Text, x58 y118 w150, % L("Set_Mute")
    Gui, Add, Button, x218 y115 w185 h25 Center gShowAboutTooltip vText10, Ctrl + Shift + M

    Gui, Add, Picture, x28 y146 w22 h22 Icon48, %A_WinDir%\System32\shell32.dll
    Gui, Add, Text, x58 y148 w150, % L("Set_AutoLock")
    Gui, Add, Button, x218 y145 w185 h25 Center gShowAboutTooltip vText11, Ctrl + Shift + L

    Gui, Add, Picture, x28 y176 w22 h22 Icon2, %A_WinDir%\System32\SndVol.exe
    Gui, Add, Text, x58 y178 w150, % L("Set_Volume")
    Gui, Add, Button, x218 y175 w220 h25 Center gShowAboutTooltip vText12, Win + Lăn chuột / PgUp/Dn

    Gui, Add, Picture, x28 y206 w22 h22 Icon26, %A_WinDir%\System32\shell32.dll
    Gui, Add, Text, x58 y208 w150, % L("Set_Brightness")
    Gui, Add, Button, x218 y205 w185 h25 Center gShowAboutTooltip vText13, F9 / F10

    Gui, Add, Picture, x28 y236 w22 h22 Icon28, %A_WinDir%\System32\ddores.dll
    Gui, Add, Text, x58 y238 w150, % L("Set_LockKBAndMouse")
    Gui, Add, Button, x218 y235 w185 h25 Center gShowAboutTooltip vText14, Ctrl + Alt + L
    Gui, Add, Picture, x410 y241 w14 h14 gShowAboutTooltip vTextInfo Icon-200, %A_WinDir%\System32\shell32.dll

    Gui, Add, Picture, x28 y266 w22 h22 Icon261, %A_WinDir%\System32\shell32.dll
    Gui, Add, Text, x58 y268 w150, % L("Set_PastePlain")
    Gui, Add, Button, x218 y265 w185 h25 Center gShowAboutTooltip vTextPaste, Ctrl + Shift + V

    Gui, Add, Picture, x28 y296 w22 h22 Icon1, %aboutIcon%
    Gui, Add, Text, x58 y298 w150, % (CurrentLang = "en" ? "Toggle Gestures & Scroll" : "Bật / Tắt Cử chỉ & Cuộn")
    Gui, Add, Button, x218 y295 w185 h25 Center gShowAboutTooltip vTextToggle, Ctrl + Alt

    ; ========================================================
    ; TAB 3: HỆ THỐNG & MẸO
    ; ========================================================
    Gui, Tab, 3
    Gui, Font, s9.5 Norm c000000, Segoe UI
    Gui, Add, Edit, x23 y115 w528 h245 ReadOnly +Border +VScroll HwndhEdit3, %TabSystemText%

    ; Đăng ký sự kiện theo dõi chuột để hiển thị tooltip trên các nút
    OnMessage(0x200, "WM_MOUSEMOVE_ABOUT")

    ; Hiển thị GUI thu gọn (không cần thanh chân trang)
    Gui, Show, w575 h365 Center, % L("About_Title")
    SetGuiYellowIcon(hAboutGui)

    ; Bỏ chọn toàn bộ text trong Tab 3 và focus vào Tab
    if (hEdit3 && WinExist("ahk_id " . hEdit3))
        PostMessage, 0x00B1, -1, 0,, ahk_id %hEdit3%
    GuiControl, About:Focus, AboutTab
return

; Xử lý di chuyển chuột trên GUI About để hiện Tooltip
global LastHoveredAboutHwnd := ""
global LastHoveredAboutControl := ""

WM_MOUSEMOVE_ABOUT() {
    global LastHoveredAboutHwnd, LastHoveredAboutControl, AboutTooltips, hAboutGui
    if (!hAboutGui || !WinExist("ahk_id " . hAboutGui))
        return

    MouseGetPos, , , idUnderMouse, CtrlUnderMouse, 2
    if (idUnderMouse != hAboutGui) {
        if (LastHoveredAboutHwnd) {
            ToolTip
            LastHoveredAboutHwnd := ""
            LastHoveredAboutControl := ""
        }
        return
    }

    if (CtrlUnderMouse != LastHoveredAboutHwnd) {
        LastHoveredAboutHwnd := ""
        LastHoveredAboutControl := ""
    }

    Gosub, ShowAboutTooltip
}

ShowAboutTooltip:
    MouseGetPos, , , , CtrlUnderMouse, 2
    GuiControlGet, CtrlName, About:Name, %CtrlUnderMouse%
    if (!CtrlName)
        GuiControlGet, CtrlName, Name, %CtrlUnderMouse%

    if (CtrlUnderMouse && AboutTooltips[CtrlName]) {
        if (LastHoveredAboutHwnd != CtrlUnderMouse) {
            ToolTip, % AboutTooltips[CtrlName]
            LastHoveredAboutControl := CtrlName
            LastHoveredAboutHwnd := CtrlUnderMouse
        }
    } else {
        ToolTip
        LastHoveredAboutControl := ""
        LastHoveredAboutHwnd := ""
    }
return

OnAboutTabChange:
    ToolTip
    LastHoveredAboutHwnd := ""
    LastHoveredAboutControl := ""
    if (hEdit3 && WinExist("ahk_id " . hEdit3))
        PostMessage, 0x00B1, -1, 0,, ahk_id %hEdit3%
    GuiControl, About:Focus, AboutTab
return

OpenEmailLink:
    Run, mailto:nguyentrian87@gmail.com
return

OpenDonateLink:
    if (DonateURL != "" && !InStr(DonateURL, "your-donation-link")) {
        Run, %DonateURL%
    } else {
        Run, https://paypal.me/nguyentrian
    }
return

AboutGuiClose:
AboutGuiEscape:
    ToolTip
    LastHoveredAboutHwnd := ""
    LastHoveredAboutControl := ""
    Gui, About:Destroy
    hAboutGui := 0
    hEdit3 := 0
return
