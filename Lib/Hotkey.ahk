#SingleInstance Force
#Persistent

#Include *i Language.ahk

; Hàm chính để khởi tạo GUI khóa màn hình
ShowLockScreenGUI:
^+L::
    if (!LangTable || !LangTable.HasKey("en")) {
        if (IsFunc("InitLanguage"))
            InitLanguage()
    }
    Gui, AutoScreenLock:Destroy ; Hủy GUI cũ nếu tồn tại
    Gui, AutoScreenLock:New, -MaximizeBox -MinimizeBox +HwndhAutoLock, % L("Hot_LockTitle")
    if (IsFunc("SetGuiYellowIcon"))

        fnIcon := "SetGuiYellowIcon"
    if (IsFunc(fnIcon))
        %fnIcon%(hAutoLock)
    Gui, Font, s10, Segoe UI
    Gui, Add, Text, xm ym, % L("Hot_Prompt")
    Gui, Add, Edit, Number ; Ô nhập số
    Gui, Add, UpDown, xm yp+30 w100 vLockTimeInput Range0-1000, 5 ; Mặc định là 5 phút
    Gui, Add, Button, xm yp+30 w80 gStartLock Default, % L("Hot_Start")
    Gui, Add, Button, x+10 gCancelCountdown, % L("Hot_Cancel")
    Gui, Show, AutoSize, % L("Hot_LockTitle")
    if (IsFunc("SetGuiYellowIcon"))

        fnIcon := "SetGuiYellowIcon"
    if (IsFunc(fnIcon))
        %fnIcon%(hAutoLock)
return

; Xử lý khi nhấn nút "Bắt đầu"
StartLock:
    global CountdownTime
    Gui, AutoScreenLock:Submit ; Lấy giá trị từ GUI
    LockTimeInput := LockTimeInput * 60 ; Chuyển phút sang giây
    if (LockTimeInput <= 0) {
        MsgBox, 48, % L("Hot_ErrTitle"), % L("Hot_ErrMsg")
        Gui, AutoScreenLock:Show, AutoSize, % L("Hot_LockTitle") ; Hiển thị lại GUI nếu lỗi

        if (IsFunc("SetGuiYellowIcon"))

        fnIcon := "SetGuiYellowIcon"
    if (IsFunc(fnIcon))
        %fnIcon%(hAutoLock)
        return
    }
    Gui, AutoScreenLock:Destroy
    Gui, Countdown:New, +LastFound +AlwaysOnTop -Caption +ToolWindow +E0x20 +Border ; Đếm ngược khóa màn hình
    WinSet, Transparent, 180 ; Làm cửa sổ trong suốt (giá trị từ 0 đến 255, 0 là trong suốt hoàn toàn)
    Gui, Font, s12, Segoe UI
    ; Chuyển đổi LockTimeInput sang mm:ss
    Minutes := Floor(LockTimeInput / 60)
    Seconds := Mod(LockTimeInput, 60)
    FormattedTime := Format("{:02d}:{:02d}", Minutes, Seconds)
    countMsg := StrReplace(L("Hot_Countdown"), "{time}", FormattedTime)
    Gui, Add, Text, xm ym vCountdownText w250, %countMsg%
    SysGet, ScreenWidth, 0  ; Lấy chiều rộng màn hình
    SysGet, ScreenHeight, 1 ; Lấy chiều cao màn hình
    posX := (ScreenWidth - 300)
    posY := (ScreenHeight - 200)
    Gui, Show, x%posX% y%posY% w280 h40 NoActivate ; Hiển thị GUI đếm ngược ở góc dưới bên phải
    CountdownTime := LockTimeInput
    SetTimer, UpdateCountdown, 1000 ; Kích hoạt timer cập nhật mỗi giây
return

; Hủy đếm ngược đang chạy và tắt GUI bằng cách mở lại Gui Nhập thời gian và nhấn nút "Hủy"
CancelCountdown:
    SetTimer, UpdateCountdown, Off
    Gui, Countdown:Destroy
    Gui, AutoScreenLock:Destroy
return

; Cập nhật thời gian đếm ngược
UpdateCountdown:
    global CountdownTime
    if (CountdownTime <= 0) {
        SetTimer, UpdateCountdown, Off
        Gui, Countdown:Destroy
        DllCall("LockWorkStation")
        return
    }
    ; Chỉ định GUI Countdown làm mặc định
    Gui, Countdown:Default
    ; Chuyển đổi CountdownTime sang định dạng mm:ss
    Minutes := Floor(CountdownTime / 60)
    Seconds := Mod(CountdownTime, 60)
    FormattedTime := Format("{:02d}:{:02d}", Minutes, Seconds)
    countMsg := StrReplace(L("Hot_Countdown"), "{time}", FormattedTime)
    GuiControl,, CountdownText, %countMsg%
    CountdownTime -= 1
return

; Paste (dán) văn bản mà không định dạng, không có khoảng trắng, không có \r, \n
PastePlainText:
$^+v::
    ClipSaved := ClipboardAll  ; Lưu clipboard gốc
    text := Clipboard         ; Lấy nội dung clipboard
    text := RegExReplace(text, "^[\s\r\n]+|[\s\r\n]+$", "")  ; Xóa khoảng trắng, \r, \n
    Clipboard := text         ; Ghi nội dung đã xử lý
    ClipWait, 1               ; Đợi clipboard sẵn sàng
    Send ^v                   ; Dán nội dung
    Sleep 50                  ; Đợi ngắn
    Clipboard := ClipSaved    ; Khôi phục clipboard gốc
return

; Hàm bật/tắt âm thanh
MuteFunc:
^+m::
    SoundSet, +1, MASTER, MUTE
    SoundGet, MuteState, MASTER, MUTE
return

AutoScreenLockGuiEscape:
    Gui, AutoScreenLock:Destroy
return
