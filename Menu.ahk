Menu:
    ; Tạo sub-menu Phím tắt (PhimTat)
    Menu, PhimTat, Add, Bật/Tắt cử chỉ & cuộn (Ctrl + Alt), ToggleGestureScrollLabel
    Menu, PhimTat, Add, Lock Keyboard (Ctrl + Alt + L), LockKeyboard
    Menu, PhimTat, Add, Auto Screen Lock (Ctrl + Shift + L), ShowLockScreenGUI
    Menu, PhimTat, Add, Paste as PlainText (Ctrl + Shift + V), PastePlainText
    Menu, PhimTat, Add, Mute (Ctrl + Shift + M), MuteFunc

    ; Thêm menu vào menu khay hệ thống
    Menu, Tray, Add, Cử chỉ chuột & cuộn (Ctrl+Alt), ToggleGestureScrollLabel
    Menu, Tray, Add  ; Dòng phân cách
    Menu, Tray, Add, Cài đặt..., Settings
    Menu, Tray, Add, Chạy quyền Admin, RunAsAdmin
    Menu, Tray, Add, Phím tắt, :PhimTat

    Menu, Tray, Add  ; Dòng phân cách
    Menu, Tray, Add, Giới thiệu..., ShowAbout
    Menu, Tray, Add
    Menu, Tray, Add, Thoát, ExitMenu
    
    ; Cấu hình System Tray
    Menu, Tray, NoStandard ; Xóa menu mặc định của AutoHotkey
    Menu, Tray, Default, Cử chỉ chuột & cuộn (Ctrl+Alt) ; Đặt mặc định khi nhấp chuột trái vào icon khay
    Menu, Tray, Click, 1 ; Nhấp 1 lần chuột trái vào icon khay để kích hoạt mặc định
    
    ; Cập nhật biểu tượng và menu khay lần đầu
    UpdateTrayIcon()
    UpdateTrayMenu()
    UpdateTrayTip()  
    Gosub, BrightnessGui  ; Tạo GUI độ sáng

; Cập nhật tray tip tổng hợp
UpdateTrayTip() {
    global Brightness, GuiOn, isLocked, mouseLockEnabled, GestureScrollEnabled
    TrayTip := "Gesture Mouse 1.0`n"
    
    GestureTip := "Cử chỉ chuột & cuộn: " . (GestureScrollEnabled ? "Bật" : "Tắt") . "`n"
    LockKeyboardTip := "Khóa bàn phím: " . (isLocked ? "Bật" : "Tắt") . "`n"
    LockMouseTip := "Khóa chuột: " . (mouseLockEnabled && isLocked ? "Bật" : "Tắt") . "`n"

    TrayTip .= GestureTip
    TrayTip .= LockKeyboardTip
    TrayTip .= LockMouseTip

    ; Độ sáng
    BrightnessPercent := Round((255 - Brightness) / 255 * 100)
    TrayTip .= "Độ sáng: " . BrightnessPercent . "%" . (GuiOn ? " (GUI bật)" : " (GUI tắt)")
    Menu, Tray, Tip, %TrayTip%
}

; Cập nhật trạng thái checkmark trên Menu Tray
UpdateTrayMenu() {
    global GestureScrollEnabled
    try {
        if (GestureScrollEnabled)
            Menu, Tray, Check, Cử chỉ chuột & cuộn (Ctrl+Alt)
        else
            Menu, Tray, Uncheck, Cử chỉ chuột & cuộn (Ctrl+Alt)
    }
}
; khởi tạo ban đầu gồm menu, icon tray, script dừng ở đây và chờ sự kiện từ menu khay hệ thống, "return" ngăn không cho các label khác tự động chạy
return


; Tạo GUI cài đặt - Settings
Settings:
Gui, Settings:New,, Cài đặt
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
; Tạo mảng liên kết cho tooltip
Tooltips := {}
Tooltips["Text1"] := "Kéo chuột thủ công để cuộn nội dung"
Tooltips["Text2"] := "Vuốt và thả để cuộn tự động"
Tooltips["Text3"] := "Cuộn từng trang bằng bánh xe chuột"
Tooltips["Text4"] := "Quay lại trang trước"
Tooltips["Text5"] := "Tiến tới trang tiếp theo"
Tooltips["Text6"] := "Chuyển sang tab trước đó"
Tooltips["Text7"] := "Chuyển sang tab tiếp theo"
Tooltips["Text8"] := "Đóng tab hiện tại"
Tooltips["Text9"] := "Tải lại trang hiện tại"
Tooltips["Text10"] := "Tắt tiếng âm thanh"
Tooltips["Text11"] := "Khóa màn hình tự động"
Tooltips["Text12"] := "Tăng hoặc giảm âm lượng, còn có thể dùng phím tắt Win + PgUp/PgDn"
Tooltips["Text13"] := "Điều chỉnh độ sáng màn hình"
Tooltips["Text14"] := "Khóa bàn phím và chuột (gõ 'unlock' để mở)"
Tooltips["Text15"] := "Chọn phương pháp cuộn chuột"
Tooltips["TextInfo"] := "Gõ 'unlock' để mở khóa bàn phím và chuột"

; Nhóm Gesture Mouse
Gui, Font, Bold
Gui, Add, GroupBox, w500 h260, Cử chỉ chuột phải
Gui, Add, Picture, x140 yp+1 w14 h14 Icon100, %A_WinDir%\System32\shell32.dll
Gui, Font, Normal
Gui, Add, Text, x20 y35, Cuộn kéo thủ công
Gui, Add, Button, x200 y30 Center gShowTooltip vText1, Giữ chuột phải + rê chuột lên hoặc xuống
Gui, Add, Text, x20 y60, Cuộn tự động
Gui, Add, Button, x200 y55 Center gShowTooltip vText2, Giữ chuột phải + vuốt lên hoặc xuống rồi thả chuột
Gui, Add, Text, x20 y82, Cuộn trang PgUp/PgDn
Gui, Add, Button, x200 y80 Center gShowTooltip vText3, Giữ chuột phải + xoay con lăn lên hoặc xuống
Gui, Add, Text, x20 y110, Quay lại
Gui, Add, Button, x200 y105 w38 Center gShowTooltip vText4,  ←
Gui, Add, Text, x20 y135, Tiến Tới
Gui, Add, Button, x200 y130 w38 Center gShowTooltip vText5,  →
Gui, Add, Text, x20 y160, Chuyển tab trước đó
Gui, Add, Button, x200 y155 w38 Center gShowTooltip vText6,  ↑__
Gui, Add, Text, x20 y185, Chuyển tab tiếp theo
Gui, Add, Button, x200 y180 w38 Center gShowTooltip vText7,  ↓¯¯
Gui, Add, Text, x20 y210, Đóng tab
Gui, Add, Button, x200 y205 w38 Center gShowTooltip vText8,  __↑
Gui, Add, Text, x20 y235, Làm mới trang
Gui, Add, Button, x200 y230 w38 Center gShowTooltip vText9,  ¯¯↓

; Nhóm Hotkeys
Gui, Font, Bold
Gui, Add, GroupBox, xs w500 h170, Phím tắt - Hotkeys
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
; Gui, Add, Picture, x18 yp+1 w14 h14 Icon334, %A_WinDir%\System32\imageres.dll
Gui, Add, Picture, x18 yp+1 w14 h14 Icon26, %A_WinDir%\System32\shell32.dll
Gui, Add, Button, x200 y375 w130 Center gShowTooltip vText13, F9/F10

Gui, Add, Text, x38 y405, Lock keyboard and mouse
Gui, Add, Picture, x18 yp+1 w14 h14 Icon28, %A_WinDir%\System32\ddores.dll
Gui, Add, Button, x200 y400 w130 Center gShowTooltip vText14, Ctrl + Alt + L
Gui, Add, Picture, x335 yp+5 w14 h14 gShowTooltip vTextInfo Icon-200, %A_WinDir%\System32\shell32.dll

;thêm sự kiện nhấn nút để chạy hàm CreateOption()
Gui, Add, Button, x355 y400 w80 Center gCreateOption, Tùy chọn..

; Nhóm Cài đặt chung
Gui, Font, Bold
Gui, Add, GroupBox, xs w500 h115, Cài đặt chung
Gui, Font, Normal
Gui, Add, Checkbox, x30 y475 vAutoStart gSave Checked%AutoStart%, Khởi chạy cùng Windows
; Gui, Add, DropDownList, x30 y495 w450 vColorChoice, Rê chuột lên xuống để kéo nội dung lên xuống|Rê chuột lên xuống để kéo thanh cuộn lên xuống
Gui, Add, Text, x20 y500, Phương pháp cuộn (cuộn kéo thủ công và cuộn tự động):
Gui, Add, Radio, x30 y525 vScrollStyle1 gSave Group Checked%ScrollStyle1%, Rê chuột lên xuống để kéo nội dung lên xuống (như trên điện thoại)
Gui, Add, Radio, x30 y545 vScrollStyle2 gSave Checked%ScrollStyle2%, Rê chuột lên xuống để kéo thanh cuộn lên xuống


; Checked radio theo giá trị từ registry
GuiControl,, ScrollStyle1, % (ScrollStyle = 1) 
GuiControl,, ScrollStyle2, % (ScrollStyle = 2)

; Theo dõi sự kiện chuột
Gui, +LastFound
OnMessage(0x200, "WM_MOUSEMOVE")  ; Theo dõi di chuyển chuột cho tooltip

; Hiển thị giao diện
Gui, Show, AutoSize Center, Gesture Mouse - Cài đặt
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
    ; Lấy giá trị của ScrollMethod (1 hoặc 2)
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

    Gui, LockOptions:New, +LastFound +OwnerSettings, Tùy chọn
    Gui, Font, s10, Arial
    Gui, Add, Checkbox, Checked Disabled, Khóa bàn phím
    Gui, Add, Checkbox, vmouseLockEnabled gSaveOption Checked%mouseLockEnabled%, Khóa nhấp chuột (trừ rê chuột và lăn chuột)
    Gui, Add, Checkbox, vdisableAutoLockScreen gSaveOption Checked%disableAutoLockScreen% Disabled, Ngăn khóa màn hình tự động khi đang ở chế độ khóa
    Gui, LockOptions:Show, AutoSize Center, Tùy chọn
    return
}

SaveOption:
    ; Lưu trạng thái của các checkbox
    Gui, Submit, NoHide
    RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, mouseLockEnabled, %mouseLockEnabled%
    ; RegWrite, REG_DWORD, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, disableAutoLockScreen, %disableAutoLockScreen%
return

;Chạy quyền Admin RunAsAdmin
RunAsAdmin:
    ; Kiểm tra xem script đã chạy với quyền Admin chưa
    if (A_IsAdmin) {
        MsgBox, 64, Thông báo, Ứng dụng đã chạy với quyền Admin rồi.
        return
    }
    ; Nếu chưa, yêu cầu quyền Admin
    try ; try để bắt lỗi nếu không thể chạy với quyền Admin
    {
        if A_IsCompiled
            Run *RunAs "%A_ScriptFullPath%" /restart
        else
            Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
    }

return

ShowAbout:
    Gui, About:New, -MaximizeBox -MinimizeBox, Giới thiệu
    Gui, Font, s10, Segoe UI

    Gui, Add, GroupBox, x10 y5 w420 h95,
    ; Icon (bên trong GroupBox)
    Gui, Add, Picture, x20 y25 w32 h32, unnamed.ico ; Tọa độ Y tương đối với cửa sổ
    ; Dòng 1: Tên ứng dụng (chữ to, ngang icon)
    Gui, Font, s18, Segoe UI
    Gui, Add, Text, x65 y18 w360, Gesture Mouse ; Tọa độ Y để căn giữa với icon
    Gui, Font, s10 Normal, Segoe UI
    ; Dòng 2: Headline
    Gui, Add, Text, x65 y50 w360, Hỗ trợ thao tác cử chỉ, phím tắt và cuộn tự động ; Tọa độ Y dưới tên ứng dụng
    ; Dòng 3: Phiên bản và Ngày cập nhật
    Gui, Font, s9, Segoe UI
    Gui, Add, Text, x65 y70 w360, Phiên bản: 1.0 | Ngày cập nhật: 20/04/2025 ; Tọa độ Y dưới headline

    ; Gui, Add, GroupBox, x10 y105 w420 h245, 
    Gui, Add, Text, x20 y125, Hướng dẫn sử dụng:
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
    - Ctrl+Alt (hoac nhap chuot trai vao icon khay he thong): Bat/Tat cu chi chuot va cuon (icon xam trang khi tat).
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
    Gui, Add, Edit, x20 y145 w400 h190 ReadOnly +VScroll ClassEdit1 +Border, %UsageGuideText% ; Tọa độ Y dưới nhãn, điều chỉnh chiều cao Edit

    Gui, Font, s9, Segoe UI
    Gui, Add, Text, x15 y360 Left, Tác giả: Nguyễn Tri Ân |
    Gui, Add, Link, x+2 y360 Left, <a href="mailto:nguyentrian87@gmail.com">Email</a>
    Gui, Add, Button, x350 y358 w70 gOpenDonateLink, Donate

    ; Hiển thị GUI (AutoSize sẽ tự tính chiều cao cuối cùng)
    Gui, Show, AutoSize Center, Giới thiệu về Gesture Mouse
    GuiControl, About:Focus, Static1 ;static 1 là tên của text đầu tiên trong GUI, ngăn focus làm select all Edit
return

OpenDonateLink:
    Run, https://your-donation-link.com ; 
return

SettingsGuiEscape:
AboutGuiEscape:
LockOptionsGuiEscape:
    Gui, Destroy
return

ExitMenu:
    ExitApp
return
