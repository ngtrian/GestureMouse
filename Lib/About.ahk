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

    ; Tab Control: Đặt chiều cao h28 để chỉ hiển thị thanh tiêu đề Tab, loại bỏ hoàn toàn khung viền bao quanh nội dung
    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Tab2, x15 y76 w545 h28 vAboutTab gOnAboutTabChange, % L("About_TabGestures") . "|" . L("About_TabShortcuts") . "|" . L("About_TabSystem")

    ; Tạo mảng liên kết cho tooltip đa ngôn ngữ trên trang About
    AboutTooltips := {}
    tipClickSuffix := (CurrentLang = "en") ? "`n[ Click to test / execute now ]" : "`n[ Nhấp chuột để thử / thực thi ngay ]"
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
    AboutTooltips["Text10"] := L("TT_10") . tipClickSuffix
    AboutTooltips["Text11"] := L("TT_11") . tipClickSuffix
    AboutTooltips["Text12"] := L("TT_12") . tipClickSuffix
    AboutTooltips["Text13"] := L("TT_13") . tipClickSuffix
    AboutTooltips["Text14"] := L("TT_14") . tipClickSuffix
    AboutTooltips["TextInfo"] := L("TT_Info")
    AboutTooltips["TextPaste"] := L("TT_PastePlain") . tipClickSuffix
    AboutTooltips["TextToggle"] := ((CurrentLang = "en") ? "Toggle gestures and advanced scroll on/off" : "Bật hoặc tắt nhanh toàn bộ cử chỉ và cuộn chuột (hoặc nhấp chuột vào icon khay)") . tipClickSuffix

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
        Gui, Add, Picture, x24 y113 w24 h24, %iconManual%
    Gui, Add, Text, x54 y115 w145, % L("Set_ManualScroll")
    Gui, Add, Button, x205 y111 w355 h26 Center gShowAboutTooltip vText1, % L("Set_ManualScrollBtn")

    if FileExist(iconAuto)
        Gui, Add, Picture, x24 y143 w24 h24, %iconAuto%
    Gui, Add, Text, x54 y145 w145, % L("Set_AutoScroll")
    Gui, Add, Button, x205 y141 w355 h26 Center gShowAboutTooltip vText2, % L("Set_AutoScrollBtn")

    if FileExist(iconPage)
        Gui, Add, Picture, x24 y173 w24 h24, %iconPage%
    Gui, Add, Text, x54 y175 w145, % L("Set_PgScroll")
    Gui, Add, Button, x205 y171 w355 h26 Center gShowAboutTooltip vText3, % L("Set_PgScrollBtn")

    if FileExist(iconVol)
        Gui, Add, Picture, x24 y203 w24 h24, %iconVol%
    Gui, Add, Text, x54 y205 w145, % L("Set_MouseVolume")
    Gui, Add, Button, x205 y201 w355 h26 Center gShowAboutTooltip vTextVol, % L("Set_MouseVolumeBtn")

    ; Dòng tiêu đề cử chỉ trình duyệt
    Gui, Font, s9.5 Bold c004499, Segoe UI
    Gui, Add, Text, x24 y238, % (CurrentLang = "en" ? "Browser && File Explorer Gestures (Hold Right Mouse Button):" : "Cử chỉ trình duyệt && File Explorer (Giữ chuột phải):")
    Gui, Font, s9.5 Norm c000000, Segoe UI

    ; 6 cử chỉ trình duyệt chia 2 cột đối xứng
    Gui, Add, Text, x24 y268 w135, % L("Set_Back")
    Gui, Add, Button, x164 y264 w46 h26 Center gShowAboutTooltip vText4, ←
    Gui, Add, Text, x295 y268 w155, % L("Set_Forward")
    Gui, Add, Button, x514 y264 w46 h26 Center gShowAboutTooltip vText5, →

    Gui, Add, Text, x24 y298 w135, % L("Set_PrevTab")
    Gui, Add, Button, x164 y294 w46 h26 Center gShowAboutTooltip vText6, ↑__
    Gui, Add, Text, x295 y298 w155, % L("Set_NextTab")
    Gui, Add, Button, x514 y294 w46 h26 Center gShowAboutTooltip vText7, ↓¯¯

    Gui, Add, Text, x24 y328 w135, % L("Set_CloseTab")
    Gui, Add, Button, x164 y324 w46 h26 Center gShowAboutTooltip vText8, __↑
    Gui, Add, Text, x295 y328 w155, % L("Set_Refresh")
    Gui, Add, Button, x514 y324 w46 h26 Center gShowAboutTooltip vText9, ¯¯↓

    ; ========================================================
    ; TAB 2: PHÍM TẮT & TIỆN ÍCH (Kèm Icon hệ thống Windows - Nhấp để thực thi ngay)
    ; ========================================================
    Gui, Tab, 2
    Gui, Font, s9.5 Norm c000000, Segoe UI

    Gui, Add, Picture, x24 y115 w22 h22 Icon3, %A_WinDir%\System32\SndVol.exe
    Gui, Add, Text, x54 y117 w150, % L("Set_Mute")
    Gui, Add, Button, x210 y113 w190 h26 Center gActionMute vText10, Ctrl + Shift + M

    Gui, Add, Picture, x24 y145 w22 h22 Icon48, %A_WinDir%\System32\shell32.dll
    Gui, Add, Text, x54 y147 w150, % L("Set_AutoLock")
    Gui, Add, Button, x210 y143 w190 h26 Center gActionAutoLock vText11, Ctrl + Shift + L

    Gui, Add, Picture, x24 y175 w22 h22 Icon2, %A_WinDir%\System32\SndVol.exe
    Gui, Add, Text, x54 y177 w150, % L("Set_Volume")
    Gui, Add, Button, x210 y173 w235 h26 Center gActionVolumeTest vText12, Win + Lăn chuột / PgUp/Dn

    Gui, Add, Picture, x24 y205 w22 h22 Icon26, %A_WinDir%\System32\shell32.dll
    Gui, Add, Text, x54 y207 w150, % L("Set_Brightness")
    Gui, Add, Button, x210 y203 w190 h26 Center gActionBrightnessTest vText13, F9 / F10

    Gui, Add, Picture, x24 y235 w22 h22 Icon28, %A_WinDir%\System32\ddores.dll
    Gui, Add, Text, x54 y237 w150, % L("Set_LockKBAndMouse")
    Gui, Add, Button, x210 y233 w190 h26 Center gActionLockKeyboard vText14, Ctrl + Alt + L
    Gui, Add, Picture, x410 y239 w14 h14 gShowAboutTooltip vTextInfo Icon-200, %A_WinDir%\System32\shell32.dll

    Gui, Add, Picture, x24 y265 w22 h22 Icon261, %A_WinDir%\System32\shell32.dll
    Gui, Add, Text, x54 y267 w150, % L("Set_PastePlain")
    Gui, Add, Button, x210 y263 w190 h26 Center gActionPastePlain vTextPaste, Ctrl + Shift + V

    Gui, Add, Picture, x24 y295 w22 h22 Icon1, %aboutIcon%
    Gui, Add, Text, x54 y297 w150, % (CurrentLang = "en" ? "Toggle Gestures & Scroll" : "Bật / Tắt Cử chỉ & Cuộn")
    Gui, Add, Button, x210 y293 w190 h26 Center gActionToggleGestures vTextToggle, Ctrl + Alt

    ; ========================================================
    ; TAB 3: HỆ THỐNG & MẸO
    ; ========================================================
    Gui, Tab, 3
    Gui, Font, s9.5 Norm c000000, Segoe UI
    Gui, Add, Edit, x18 y112 w539 h242 ReadOnly +Border +VScroll HwndhEdit3, %TabSystemText%

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

; ========================================================
; HÀNH ĐỘNG KHI NHẤP CHUỘT TRỰC TIẾP VÀO CÁC NÚT PHÍM TẮT TRÊN TAB 2
; ========================================================
ActionMute:
    SoundSet, +1, , mute
    SoundGet, isMuted, , mute
    tipMsg := (isMuted = "On" || isMuted = 1) ? (CurrentLang = "en" ? "Audio Muted" : "Đã tắt tiếng hệ thống") : (CurrentLang = "en" ? "Audio Unmuted" : "Đã bật tiếng hệ thống")
    ToolTip, % tipMsg
    SetTimer, ClearAboutTip, -2000
return

ActionAutoLock:
    ToolTip
    if (IsLabel("ShowLockScreenGUI"))
        Gosub, ShowLockScreenGUI
return

ActionVolumeTest:
    Send, {Blind}{Volume_Up}
    ToolTip, % (CurrentLang = "en" ? "Tested: Volume Up" : "Thử nghiệm: Tăng âm lượng")
    SetTimer, ClearAboutTip, -1500
return

ActionBrightnessTest:
    if (IsLabel("F10"))
        Gosub, F10
    else if (IsLabel("BrightnessTip"))
        Gosub, BrightnessTip
return

ActionLockKeyboard:
    ToolTip
    if (IsFunc("ToggleLock"))
        ToggleLock()
return

ActionPastePlain:
    ToolTip
    if (IsLabel("PastePlainText"))
        Gosub, PastePlainText
return

ActionToggleGestures:
    if (IsFunc("ToggleGestureScroll"))
        ToggleGestureScroll()
    tipMsg := GestureScrollEnabled ? (CurrentLang = "en" ? "Gestures: ENABLED" : "Cử chỉ chuột: ĐÃ BẬT") : (CurrentLang = "en" ? "Gestures: DISABLED" : "Cử chỉ chuột: ĐÃ TẮT")
    ToolTip, % tipMsg
    SetTimer, ClearAboutTip, -2000
return

ClearAboutTip:
    ToolTip
return
