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

    ; Header: Luôn hiển thị (Icon liên kết email, Tên ứng dụng, Slogan và Phiên bản)
    aboutIcon := A_IsCompiled ? A_ScriptFullPath : (A_ScriptDir . "\image\unnamed.ico")
    Gui, Add, Picture, x20 y16 w38 h38 Icon1, %aboutIcon%
    
    Gui, Font, s15 Bold c004499, Segoe UI
    Gui, Add, Text, x68 y12 w435, Gesture Mouse
    Gui, Font, s10 Norm c222222, Segoe UI
    Gui, Add, Text, x68 y36 w435, % L("About_Headline")
    Gui, Font, s9 Norm c555555, Segoe UI
    Gui, Add, Text, x68 y57 w435, % L("About_Version")

    ; Tab Control: Tab headers chữ thường (không in đậm), tên ngắn gọn
    Gui, Font, s9.5 Norm c222222, Segoe UI
    Gui, Add, Tab2, x15 y85 w490 h250 vAboutTab gOnAboutTabChange, % L("About_TabGestures") . "|" . L("About_TabShortcuts") . "|" . L("About_TabSystem")

    if (CurrentLang = "en") {
        TabGesturesText =
        ( LTrim Join`n
        [ RIGHT MOUSE GESTURES (BROWSERS & FILE EXPLORER) ]
        Hold Right Mouse Button (RButton) and move in direction:
          • Left (←)                : Go back to previous page (Back)
          • Right (→)               : Go forward to next page (Forward)
          • Left then Up (↑__ )     : Switch to previous tab
          • Left then Down (↓¯¯)    : Switch to next tab
          • Right then Up (__↑)     : Close current tab
          • Right then Down (¯¯↓)   : Reload / Refresh page

        * Supported on Chrome, Edge, Firefox, CocCoc, Brave, Opera... and File Explorer (when no files are selected).

        [ MOUSE SCROLLING (ALL WINDOWS) ]
          • Hold Right Click + drag Up / Down:
            Smooth scrolling (scroll content or scrollbar, configurable in Settings).
          • Hold Right Click + flick Up / Down and release:
            Inertial Auto-Scroll. Click mouse or move slightly to stop.
          • Hold Right Click + scroll mouse wheel:
            Fast page navigation (Page Up / Page Down).
        )

        TabShortcutsText =
        ( LTrim Join`n
        [ VOLUME & BRIGHTNESS CONTROL ]
          • Hold Left Click + scroll wheel  : Quickly adjust volume up / down
          • Win + Scroll wheel (or PgUp/Dn) : Increase / Decrease system volume
          • Ctrl + Shift + M               : Mute / Unmute system audio
          • F9 / F10                       : Decrease / Increase screen brightness

        [ HANDY SHORTCUTS & UTILITIES ]
          • Ctrl + Alt (or click tray icon):
            Toggle Gestures & Scrolling on/off (Colored icon: On | Gray icon: Off).
          • Ctrl + Alt + L:
            Lock keyboard (and optional mouse clicks configured in Settings).
            => Type "unlock" on keyboard to unlock.
          • Ctrl + Shift + L:
            Schedule auto screen lock countdown timer.
          • Ctrl + Shift + V:
            Paste plain text (automatically trims leading/trailing whitespace & empty lines).
        )

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
        TabGesturesText =
        ( LTrim Join`n
        [ CỬ CHỈ CHUỘT PHẢI (TRÌNH DUYỆT & FILE EXPLORER) ]
        Giữ chuột phải (RButton) và di chuyển theo hướng:
          • Sang Trái (←)           : Quay lại trang trước (Back)
          • Sang Phải (→)           : Tiến tới trang tiếp theo (Forward)
          • Trái rồi Lên (↑__ )      : Chuyển sang tab trước đó
          • Trái rồi Xuống (↓¯¯)     : Chuyển sang tab tiếp theo
          • Phải rồi Lên (__↑)       : Đóng tab hiện tại
          • Phải rồi Xuống (¯¯↓)     : Tải lại / Làm mới trang (Reload)

        * Áp dụng trên: Chrome, Edge, Firefox, Cốc Cốc, Brave, Opera... và File Explorer (khi không chọn file).

        [ THAO TÁC CUỘN NÂNG CAO (MỌI CỬA SỔ) ]
          • Giữ chuột phải + rê Lên / Xuống:
            Cuộn trang mượt mà (chế độ kéo nội dung hoặc kéo thanh cuộn theo Cài đặt).
          • Giữ chuột phải + vuốt Lên / Xuống rồi thả:
            Cuộn tự động theo quán tính (Auto-Scroll). Nhấp chuột hoặc rê nhẹ để dừng.
          • Giữ chuột phải + lăn bánh xe:
            Cuộn nhanh từng trang (Page Up / Page Down).
        )

        TabShortcutsText =
        ( LTrim Join`n
        [ ĐIỀU KHIỂN ÂM LƯỢNG & ĐỘ SÁNG ]
          • Giữ chuột trái + lăn bánh xe   : Tăng / Giảm âm lượng nhanh chóng
          • Win + Lăn chuột (hoặc PgUp/Dn) : Tăng / Giảm âm lượng hệ thống
          • Ctrl + Shift + M               : Bật / Tắt âm thanh hệ thống (Mute)
          • F9 / F10                       : Giảm / Tăng độ sáng màn hình

        [ CÁC CÔNG CỤ TIỆN ÍCH ]
        • Ctrl + Alt (hoặc click icon khay):
          Bật / Tắt nhanh cử chỉ & cuộn chuột (Icon màu: Bật | Icon xám: Tắt).
        • Ctrl + Alt + L:
          Khóa bàn phím (và khóa click chuột nếu bật trong Cài đặt).
          => Gõ chữ "unlock" trên bàn phím để mở khóa.
        • Ctrl + Shift + L:
          Mở giao diện hẹn giờ tự động khóa màn hình máy tính.
        • Ctrl + Shift + V:
          Dán văn bản thuần túy (Plain Text), tự động cắt bỏ khoảng trắng và dòng thừa ở đầu/cuối.
        )

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

    ; Nội dung các Tab: Chữ màu đen sắc nét (c000000, Segoe UI s9.5)
    Gui, Font, s9.5 Norm c000000, Segoe UI

    ; Tab 1: Cử chỉ
    Gui, Tab, 1
    Gui, Add, Edit, x23 y118 w474 h208 ReadOnly +Border +VScroll HwndhEdit1, %TabGesturesText%

    ; Tab 2: Phím tắt
    Gui, Tab, 2
    Gui, Add, Edit, x23 y118 w474 h208 ReadOnly +Border +VScroll HwndhEdit2, %TabShortcutsText%

    ; Tab 3: Hệ thống
    Gui, Tab, 3
    Gui, Add, Edit, x23 y118 w474 h208 ReadOnly +Border +VScroll HwndhEdit3, %TabSystemText%

    ; Footer: Tác giả ngắn gọn, Icon Email & Nút Donate / Đóng (Luôn hiển thị)
    Gui, Tab
    Gui, Font, s9.5 Norm c555555, Segoe UI
    Gui, Add, Text, x18 y347, % L("About_Author")

    ; Icon email phong bì thư tích hợp sẵn của hệ thống Windows
    Gui, Add, Picture, x+8 yp-1 w18 h18 Icon157 gOpenEmailLink +Cursor, %A_WinDir%\System32\shell32.dll

    Gui, Add, Button, x330 y343 w90 h26 gOpenDonateLink, % "❤ " . L("About_Donate")
    Gui, Add, Button, x428 y343 w77 h26 vAboutCloseBtn gAboutGuiClose Default, % L("About_Close")

    ; Hiển thị GUI
    Gui, Show, w520 h380 Center, % L("About_Title")
    SetGuiYellowIcon(hAboutGui)

    ; Bỏ chọn toàn bộ text và chuyển focus sang nút Đóng (tránh tự động select all)
    PostMessage, 0x00B1, -1, 0,, ahk_id %hEdit1%
    PostMessage, 0x00B1, -1, 0,, ahk_id %hEdit2%
    PostMessage, 0x00B1, -1, 0,, ahk_id %hEdit3%
    GuiControl, About:Focus, AboutCloseBtn
return

OnAboutTabChange:
    PostMessage, 0x00B1, -1, 0,, ahk_id %hEdit1%
    PostMessage, 0x00B1, -1, 0,, ahk_id %hEdit2%
    PostMessage, 0x00B1, -1, 0,, ahk_id %hEdit3%
    GuiControl, About:Focus, AboutCloseBtn
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
    Gui, About:Destroy
    hAboutGui := 0
return
