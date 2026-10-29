; Language.ahk - Quản lý đa ngôn ngữ (Tiếng Việt & English)
#NoEnv

global CurrentLang := "vi"
global LangTable := {}

; Khởi tạo bảng ngôn ngữ và đọc cài đặt từ Registry
InitLanguage() {
    global CurrentLang, LangTable
    LangTable["vi"] := {}
    LangTable["en"] := {}
    
    ; Đọc ngôn ngữ đã lưu từ Registry
    RegRead, savedLang, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, Language
    if (savedLang = "en" || savedLang = "vi")
        CurrentLang := savedLang
    else
        CurrentLang := "vi"

    ; =============================================
    ; ĐỊNH NGHĨA CHUỖI TIẾNG VIỆT
    ; =============================================
    v := LangTable["vi"]
    v["Tray_Enabled"]           := "Đang bật (Ctrl+Alt)"
    v["Tray_Disabled"]          := "Đang tắt (Ctrl+Alt)"
    v["Tray_Settings"]          := "Cài đặt..."
    v["Tray_RunAsAdmin"]        := "Chạy quyền Admin"
    v["Tray_Shortcuts"]         := "Phím tắt"
    v["Tray_Language"]          := "Ngôn ngữ"
    v["Tray_About"]             := "Giới thiệu..."
    v["Tray_Exit"]              := "Thoát"
    v["Sub_Toggle"]             := "Bật/Tắt cử chỉ & cuộn (Ctrl + Alt)"
    v["Sub_LockKB"]             := "Khóa bàn phím (Ctrl + Alt + L)"
    v["Sub_AutoLock"]           := "Tự động khóa màn hình (Ctrl + Shift + L)"
    v["Sub_PlainText"]          := "Dán văn bản thuần (Ctrl + Shift + V)"
    v["Sub_Mute"]               := "Tắt/Bật âm thanh (Ctrl + Shift + M)"
    v["Tip_Title"]              := "Gesture Mouse 1.0`n"
    v["Tip_Gesture"]            := "Cử chỉ chuột & cuộn: "
    v["Tip_LockKB"]             := "Khóa bàn phím: "
    v["Tip_LockMouse"]          := "Khóa chuột: "
    v["Tip_Brightness"]         := "Độ sáng: "
    v["Tip_On"]                 := "Bật"
    v["Tip_Off"]                := "Tắt"
    v["Tip_GuiOn"]              := " (GUI bật)"
    v["Tip_GuiOff"]             := " (GUI tắt)"
    v["Toggle_On"]              := "Cử chỉ chuột & cuộn: ĐÃ BẬT"
    v["Toggle_Off"]             := "Cử chỉ chuột & cuộn: ĐÃ TẮT"
    v["Admin_Notice"]           := "Thông báo"
    v["Admin_Already"]          := "Ứng dụng đã chạy với quyền Admin rồi."
    
    ; Cài đặt - Settings
    v["Set_Title"]              := "Cài đặt"
    v["Set_GroupGesture"]       := "Cử chỉ chuột phải"
    v["Set_ManualScroll"]       := "Cuộn kéo thủ công"
    v["Set_ManualScrollBtn"]    := "Giữ chuột phải + rê chuột lên hoặc xuống"
    v["Set_AutoScroll"]         := "Cuộn tự động"
    v["Set_AutoScrollBtn"]      := "Giữ chuột phải + vuốt lên hoặc xuống rồi thả chuột"
    v["Set_PgScroll"]           := "Cuộn trang PgUp/PgDn"
    v["Set_PgScrollBtn"]        := "Giữ chuột phải + xoay con lăn lên hoặc xuống"
    v["Set_Back"]               := "Quay lại"
    v["Set_Forward"]            := "Tiến Tới"
    v["Set_PrevTab"]            := "Chuyển tab trước đó"
    v["Set_NextTab"]            := "Chuyển tab tiếp theo"
    v["Set_CloseTab"]           := "Đóng tab"
    v["Set_Refresh"]            := "Làm mới trang"
    v["Set_GroupHotkeys"]       := "Phím tắt - Hotkeys"
    v["Set_Mute"]               := "Tắt/Bật âm thanh"
    v["Set_AutoLock"]           := "Tự động khóa màn hình"
    v["Set_Volume"]             := "Tăng/giảm âm lượng"
    v["Set_Brightness"]         := "Độ sáng"
    v["Set_LockKBAndMouse"]     := "Khóa bàn phím và chuột"
    v["Set_OptionsBtn"]         := "Tùy chọn.."
    v["Set_GroupGeneral"]       := "Cài đặt chung"
    v["Set_AutoStart"]          := "Khởi chạy cùng Windows"
    v["Set_ScrollMethodLabel"]  := "Phương pháp cuộn (cuộn kéo thủ công và cuộn tự động):"
    v["Set_ScrollStyle1"]       := "Rê chuột lên xuống để kéo nội dung lên xuống (như trên điện thoại)"
    v["Set_ScrollStyle2"]       := "Rê chuột lên xuống để kéo thanh cuộn lên xuống"
    
    ; Tooltips trong Cài đặt
    v["TT_1"]                   := "Kéo chuột thủ công để cuộn nội dung"
    v["TT_2"]                   := "Vuốt và thả để cuộn tự động"
    v["TT_3"]                   := "Cuộn từng trang bằng bánh xe chuột"
    v["TT_4"]                   := "Quay lại trang trước"
    v["TT_5"]                   := "Tiến tới trang tiếp theo"
    v["TT_6"]                   := "Chuyển sang tab trước đó"
    v["TT_7"]                   := "Chuyển sang tab tiếp theo"
    v["TT_8"]                   := "Đóng tab hiện tại"
    v["TT_9"]                   := "Tải lại trang hiện tại"
    v["TT_10"]                  := "Tắt tiếng âm thanh"
    v["TT_11"]                  := "Khóa màn hình tự động"
    v["TT_12"]                  := "Tăng hoặc giảm âm lượng, còn có thể dùng phím tắt Win + PgUp/PgDn"
    v["TT_13"]                  := "Điều chỉnh độ sáng màn hình"
    v["TT_14"]                  := "Khóa bàn phím và chuột (gõ 'unlock' để mở)"
    v["TT_15"]                  := "Chọn phương pháp cuộn chuột"
    v["TT_Info"]                := "Gõ 'unlock' để mở khóa bàn phím và chuột"
    
    ; Tùy chọn LockOptions
    v["Opt_Title"]              := "Tùy chọn"
    v["Opt_LockKB"]             := "Khóa bàn phím"
    v["Opt_LockMouse"]          := "Khóa nhấp chuột (trừ rê chuột và lăn chuột)"
    v["Opt_PreventAutoLock"]    := "Ngăn khóa màn hình tự động khi đang ở chế độ khóa"
    
    ; Giới thiệu - About
    v["About_Title"]            := "Giới thiệu về Gesture Mouse"
    v["About_Headline"]         := "Hỗ trợ thao tác cử chỉ, phím tắt và cuộn tự động"
    v["About_Version"]          := "Phiên bản: 1.0 | Ngày cập nhật: 20/04/2025"
    v["About_GuideTitle"]       := "Hướng dẫn sử dụng:"
    v["About_Author"]           := "Tác giả: Nguyễn Tri Ân | "
    v["About_Donate"]           := "Donate"
    ; Gesture Hints khi vẽ cử chỉ chuột
    v["Hint_CloseTab"]          := "Đóng tab"
    v["Hint_Refresh"]           := "Làm mới trang"
    v["Hint_PrevTab"]           := "Chuyển tab trước đó"
    v["Hint_NextTab"]           := "Chuyển tab tiếp theo"
    v["Hint_Back"]              := "Quay lại"
    v["Hint_Forward"]           := "Tiến tới"
    v["Hint_Restore"]           := "Phục hồi`ncửa sổ"
    v["Hint_Minimize"]          := "Thu nhỏ`ncửa sổ"
    v["Hint_Invalid"]           := "Cử chỉ không đúng"
    
    ; Khóa bàn phím - LockKeyboard
    v["Lock_Locked"]            := "Đã khóa bàn phím"
    v["Lock_Unlocked"]          := "Đã mở khóa bàn phím"
    v["Lock_AndMouse"]          := " và nhấp chuột"
    v["Lock_HookError"]         := "Không thể cài đặt keyboard hook!"
    
    ; Tự động khóa màn hình - Hotkey
    v["Hot_LockTitle"]          := "Tự động khóa màn hình"
    v["Hot_Prompt"]             := "Nhập thời gian (phút) để tự động khóa màn hình:"
    v["Hot_Start"]              := "Bắt đầu"
    v["Hot_Cancel"]             := "Hủy đếm ngược"
    v["Hot_ErrTitle"]           := "Lỗi"
    v["Hot_ErrMsg"]             := "Vui lòng nhập thời gian lớn hơn 0 phút."
    v["Hot_Countdown"]          := "Màn hình sẽ khóa sau {time}"


    ; =============================================
    ; ĐỊNH NGHĨA CHUỖI TIẾNG ANH
    ; =============================================
    e := LangTable["en"]
    e["Tray_Enabled"]           := "Enabled (Ctrl+Alt)"
    e["Tray_Disabled"]          := "Disabled (Ctrl+Alt)"
    e["Tray_Settings"]          := "Settings..."
    e["Tray_RunAsAdmin"]        := "Run as Administrator"
    e["Tray_Shortcuts"]         := "Shortcuts"
    e["Tray_Language"]          := "Language"
    e["Tray_About"]             := "About..."
    e["Tray_Exit"]              := "Exit"
    e["Sub_Toggle"]             := "Toggle Gesture & Scroll (Ctrl + Alt)"
    e["Sub_LockKB"]             := "Lock Keyboard (Ctrl + Alt + L)"
    e["Sub_AutoLock"]           := "Auto Screen Lock (Ctrl + Shift + L)"
    e["Sub_PlainText"]          := "Paste as Plain Text (Ctrl + Shift + V)"
    e["Sub_Mute"]               := "Mute / Unmute (Ctrl + Shift + M)"
    e["Tip_Title"]              := "Gesture Mouse 1.0`n"
    e["Tip_Gesture"]            := "Gesture & Scroll: "
    e["Tip_LockKB"]             := "Lock Keyboard: "
    e["Tip_LockMouse"]          := "Lock Mouse: "
    e["Tip_Brightness"]         := "Brightness: "
    e["Tip_On"]                 := "On"
    e["Tip_Off"]                := "Off"
    e["Tip_GuiOn"]              := " (GUI on)"
    e["Tip_GuiOff"]             := " (GUI off)"
    e["Toggle_On"]              := "Gesture & Scroll: ENABLED"
    e["Toggle_Off"]             := "Gesture & Scroll: DISABLED"
    e["Admin_Notice"]           := "Notice"
    e["Admin_Already"]          := "Application is already running as Administrator."
    
    ; Settings
    e["Set_Title"]              := "Settings"
    e["Set_GroupGesture"]       := "Right Click Gestures"
    e["Set_ManualScroll"]       := "Manual Drag Scroll"
    e["Set_ManualScrollBtn"]    := "Hold Right Click + drag mouse up or down"
    e["Set_AutoScroll"]         := "Auto Scroll"
    e["Set_AutoScrollBtn"]      := "Hold Right Click + flick up or down, then release"
    e["Set_PgScroll"]           := "Page Scroll PgUp/PgDn"
    e["Set_PgScrollBtn"]        := "Hold Right Click + scroll mouse wheel up or down"
    e["Set_Back"]               := "Back"
    e["Set_Forward"]            := "Forward"
    e["Set_PrevTab"]            := "Previous Tab"
    e["Set_NextTab"]            := "Next Tab"
    e["Set_CloseTab"]           := "Close Tab"
    e["Set_Refresh"]            := "Reload Page"
    e["Set_GroupHotkeys"]       := "Hotkeys"
    e["Set_Mute"]               := "Mute / Unmute"
    e["Set_AutoLock"]           := "Auto Screen Lock"
    e["Set_Volume"]             := "Volume up/down"
    e["Set_Brightness"]         := "Brightness"
    e["Set_LockKBAndMouse"]     := "Lock keyboard and mouse"
    e["Set_OptionsBtn"]         := "Options.."
    e["Set_GroupGeneral"]       := "General Settings"
    e["Set_AutoStart"]          := "Start with Windows"
    e["Set_ScrollMethodLabel"]  := "Scroll method (manual and auto-scroll):"
    e["Set_ScrollStyle1"]       := "Drag up/down to scroll content (like on phones)"
    e["Set_ScrollStyle2"]       := "Drag up/down to scroll the scrollbar"
    
    ; Tooltips
    e["TT_1"]                   := "Manually drag mouse to scroll content"
    e["TT_2"]                   := "Flick and release to auto-scroll"
    e["TT_3"]                   := "Scroll pages using mouse wheel"
    e["TT_4"]                   := "Go back to previous page"
    e["TT_5"]                   := "Go forward to next page"
    e["TT_6"]                   := "Switch to previous tab"
    e["TT_7"]                   := "Switch to next tab"
    e["TT_8"]                   := "Close current tab"
    e["TT_9"]                   := "Reload current page"
    e["TT_10"]                  := "Mute / Unmute system sound"
    e["TT_11"]                  := "Schedule automatic screen lock"
    e["TT_12"]                  := "Adjust volume, or use shortcut Win + PgUp/PgDn"
    e["TT_13"]                  := "Adjust screen brightness"
    e["TT_14"]                  := "Lock keyboard and mouse (type 'unlock' to unlock)"
    e["TT_15"]                  := "Select mouse scroll method"
    e["TT_Info"]                := "Type 'unlock' to unlock keyboard and mouse"
    
    ; Options
    e["Opt_Title"]              := "Options"
    e["Opt_LockKB"]             := "Lock Keyboard"
    e["Opt_LockMouse"]          := "Lock mouse clicks (except moving and scrolling)"
    e["Opt_PreventAutoLock"]    := "Prevent auto screen lock while in lock mode"
    
    ; About
    e["About_Title"]            := "About Gesture Mouse"
    e["About_Headline"]         := "Mouse gestures, shortcuts and auto-scroll utility"
    e["About_Version"]          := "Version: 1.0 | Updated: 20/04/2025"
    e["About_GuideTitle"]       := "User Guide:"
    e["About_Author"]           := "Author: Nguyen Tri An | "
    e["About_Donate"]           := "Donate"
    ; Gesture Hints
    e["Hint_CloseTab"]          := "Close Tab"
    e["Hint_Refresh"]           := "Reload Page"
    e["Hint_PrevTab"]           := "Previous Tab"
    e["Hint_NextTab"]           := "Next Tab"
    e["Hint_Back"]              := "Back"
    e["Hint_Forward"]           := "Forward"
    e["Hint_Restore"]           := "Restore`nWindow"
    e["Hint_Minimize"]          := "Minimize`nWindow"
    e["Hint_Invalid"]           := "Invalid Gesture"
    
    ; LockKeyboard
    e["Lock_Locked"]            := "Keyboard is locked"
    e["Lock_Unlocked"]          := "Keyboard is unlocked"
    e["Lock_AndMouse"]          := " and mouse clicks"
    e["Lock_HookError"]         := "Cannot install keyboard hook!"
    
    ; Auto Screen Lock - Hotkey
    e["Hot_LockTitle"]          := "Auto Screen Lock"
    e["Hot_Prompt"]             := "Enter time (minutes) to auto lock screen:"
    e["Hot_Start"]              := "Start"
    e["Hot_Cancel"]             := "Cancel"
    e["Hot_ErrTitle"]           := "Error"
    e["Hot_ErrMsg"]             := "Please enter a time greater than 0 minutes."
    e["Hot_Countdown"]          := "Screen will lock in {time}"

}

; Hàm tra cứu chuỗi theo key
L(key) {
    global CurrentLang, LangTable
    if (LangTable[CurrentLang].HasKey(key))
        return LangTable[CurrentLang][key]
    if (LangTable["vi"].HasKey(key))
        return LangTable["vi"][key]
    return key
}

; Đổi ngôn ngữ và cập nhật toàn bộ Menu & ToolTip
SetLanguage(newLang) {
    global CurrentLang
    if (newLang != "vi" && newLang != "en")
        return
    CurrentLang := newLang
    RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, Language, %CurrentLang%
    fnRebuild := "RebuildTrayMenu"
    if (IsFunc(fnRebuild))
        %fnRebuild%()
    fnTip := "UpdateTrayTip"
    if (IsFunc(fnTip))
        %fnTip%()
}
