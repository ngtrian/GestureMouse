; Language.ahk - Quản lý đa ngôn ngữ (Tiếng Việt & English)
#NoEnv

global CurrentLang := "en"
global LangTable := {}

; Khởi tạo bảng ngôn ngữ và đọc cài đặt từ Registry
InitLanguage() {
    global CurrentLang, LangTable, AppVersion, AppReleaseDate
    LangTable["vi"] := {}
    LangTable["en"] := {}
    
    ; Đọc ngôn ngữ đã lưu từ Registry
    RegRead, savedLang, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, Language
    if (savedLang = "en" || savedLang = "vi")
        CurrentLang := savedLang
    else
        CurrentLang := "en"

    ; =============================================
    ; ĐỊNH NGHĨA CHUỖI TIẾNG VIỆT
    ; =============================================
    v := LangTable["vi"]
    v["Tray_Enabled"]           := "Đang bật (Ctrl+Alt)"
    v["Tray_Disabled"]          := "Đang tắt (Ctrl+Alt)"
    v["Tray_Settings"]          := "Cài đặt..."
    v["Tray_RunAsAdmin"]        := "Chạy quyền Admin"
    v["Tray_Install"]           := "Cài đặt vào hệ thống (UIAccess)"
    v["Tray_Uninstall"]         := "Gỡ cài đặt khỏi hệ thống"
    v["Install_Confirm"]        := "Bạn có muốn cài đặt GestureMouse vào Program Files và đăng ký UIAccess (để cuộn được Task Manager, khởi động cùng Windows và không bao giờ bị hỏi UAC) không?"
    v["Install_Success"]        := "Đã cài đặt thành công GestureMouse vào hệ thống!`n`nPhần mềm đã được cấp đặc quyền UIAccess và tự động khởi động cùng Windows."
    v["Install_Error"]          := "Cài đặt thất bại: "
    v["Uninstall_Confirm"]      := "Bạn có chắc chắn muốn gỡ cài đặt GestureMouse khỏi hệ thống không?`n`nThao tác này sẽ xóa ứng dụng khỏi Program Files, Start Menu và danh sách tự khởi động."
    v["Uninstall_Success"]      := "Đã gỡ cài đặt GestureMouse thành công khỏi hệ thống!"
    v["Uninstall_Error"]        := "Gỡ cài đặt thất bại: "
    v["Tray_Shortcuts"]         := "Phím tắt"
    v["Tray_Language"]          := "Ngôn ngữ"
    v["Tray_About"]             := "Giới thiệu..."
    v["Tray_Exit"]              := "Thoát"
    v["Tray_Reload"]            := "Khởi động lại"
    v["Sub_LockKB"]             := "Khóa bàn phím`tCtrl + Alt + L"
    v["Sub_AutoLock"]           := "Tự động khóa màn hình`tCtrl + Shift + L"
    v["Sub_PlainText"]          := "Dán văn bản thuần`tCtrl + Shift + V"
    v["Sub_Mute"]               := "Tắt/Bật âm thanh`tCtrl + Shift + M"
    v["Tray_CheckUpdate"]       := "Kiểm tra cập nhật..."
    v["Update_Available"]       := "Đã có phiên bản mới v{new} (bản hiện tại: v{curr})!`n`nBạn có muốn mở trang GitHub Releases để cập nhật không?"
    v["Update_Latest"]          := "Bạn đang sử dụng phiên bản mới nhất (v{ver})."
    v["Update_Failed"]          := "Không thể kiểm tra bản cập nhật. Vui lòng kiểm tra lại kết nối mạng."
    v["Tip_Title"]              := "GestureMouse v" . (AppVersion ? AppVersion : "1.0.0") . "`n"
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
    v["Set_MouseVolume"]        := "Tăng/giảm âm lượng"
    v["Set_MouseVolumeBtn"]     := "Giữ chuột trái + cuộn con lăn lên hoặc xuống"
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
    v["Set_PastePlain"]         := "Dán văn bản thuần"
    v["Set_OptionsBtn"]         := "Tùy chọn.."
    v["Set_ExcludedAppsBtn"]    := "Ứng dụng loại trừ..."
    v["TT_ExApps"]              := "Quản lý danh sách ứng dụng không áp dụng cử chỉ chuột và cuộn chuột"
    
    ; Ứng dụng loại trừ - Excluded Apps
    v["Ex_Title"]               := "Ứng dụng loại trừ cử chỉ chuột"
    v["Ex_SelectOrSearch"]      := "Ứng dụng:"
    v["Ex_AddBtn"]              := "+ Thêm"
    v["Ex_AddBrowse"]           := "Chọn file (.exe)..."
    v["Ex_ColProcess"]          := "Tên tiến trình (.exe)"
    v["Ex_ColTitle"]            := "Tên ứng dụng"
    v["Ex_ColAction"]           := "Thao tác"
    v["Ex_ActionDelete"]        := "✕ Xóa"
    v["Ex_DeleteTip"]           := "* Chọn ứng dụng rồi bấm 'Xóa' hoặc phím Delete."
    v["Ex_AlreadyAdded"]        := "Đã có trong danh sách loại trừ!"
    v["Ex_AddSuccess"]          := "Đã thêm: "
    v["Ex_RemoveSuccess"]       := "Đã xóa: "
    v["Ex_Close"]               := "Đóng"
    v["Ex_Remove"]              := "Xóa"
    v["Set_GroupGeneral"]       := "Cài đặt chung"
    v["Set_AutoStart"]          := "Khởi chạy cùng Windows"
    v["Set_ScrollMethodLabel"]  := "Phương pháp cuộn (cuộn kéo thủ công và cuộn tự động):"
    v["Set_ScrollStyle1"]       := "Rê chuột lên xuống để kéo nội dung lên xuống (như trên điện thoại)"
    v["Set_ScrollStyle2"]       := "Rê chuột lên xuống để kéo thanh cuộn lên xuống"
    
    ; Tooltips trong Cài đặt
    v["TT_1"]                   := "Kéo chuột thủ công để cuộn nội dung"
    v["TT_2"]                   := "Vuốt và thả để cuộn tự động"
    v["TT_3"]                   := "Cuộn từng trang bằng bánh xe chuột"
    v["TT_MouseVolume"]          := "Giữ chuột trái và cuộn con lăn để tăng hoặc giảm âm lượng"
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
    v["TT_PastePlain"]          := "Dán văn bản thuần túy (tự động xóa khoảng trắng và dòng trống ở đầu/cuối)"
    
    ; Tùy chọn LockOptions
    v["Opt_Title"]              := "Tùy chọn"
    v["Opt_LockKB"]             := "Khóa bàn phím"
    v["Opt_LockMouse"]          := "Khóa nhấp chuột (trừ rê chuột và lăn chuột)"
    v["Opt_PreventAutoLock"]    := "Ngăn khóa màn hình tự động khi đang ở chế độ khóa"
    
    ; Giới thiệu - About
    v["About_Title"]            := "Giới thiệu về Gesture Mouse"
    v["About_Headline"]         := "Hỗ trợ thao tác cử chỉ, phím tắt và cuộn tự động"
    v["About_Version"]          := "Phiên bản: " . (AppVersion ? AppVersion : "1.0.0") . " | Ngày phát hành: " . (AppReleaseDate ? AppReleaseDate : "02/11/2026")
    v["About_GuideTitle"]       := "Hướng dẫn sử dụng:"
    v["About_Author"]           := "Tác giả: Nguyễn Tri Ân"
    v["About_Donate"]           := "Donate"
    v["About_Close"]            := "Đóng"
    v["About_TabGestures"]      := "Cử chỉ"
    v["About_TabShortcuts"]     := "Phím tắt"
    v["About_TabSystem"]        := "Hệ thống"
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
    e["Tray_Install"]           := "Install to System (UIAccess)"
    e["Tray_Uninstall"]         := "Uninstall from System"
    e["Install_Confirm"]        := "Do you want to install GestureMouse into Program Files and register UIAccess (to scroll in Task Manager, start with Windows, and never get prompted by UAC)?"
    e["Install_Success"]        := "GestureMouse has been successfully installed into the system!`n`nIt is now granted UIAccess privilege and set to start with Windows."
    e["Install_Error"]          := "Installation failed: "
    e["Uninstall_Confirm"]      := "Are you sure you want to uninstall GestureMouse from the system?`n`nThis will remove the application from Program Files, Start Menu, and Startup."
    e["Uninstall_Success"]      := "GestureMouse has been successfully uninstalled from the system!"
    e["Uninstall_Error"]        := "Uninstallation failed: "
    e["Tray_Shortcuts"]         := "Shortcuts"
    e["Tray_Language"]          := "Language"
    e["Tray_About"]             := "About..."
    e["Tray_Exit"]              := "Exit"
    e["Tray_Reload"]            := "Restart / Reload"
    e["Sub_LockKB"]             := "Lock Keyboard`tCtrl + Alt + L"
    e["Sub_AutoLock"]           := "Auto Screen Lock`tCtrl + Shift + L"
    e["Sub_PlainText"]          := "Paste as Plain Text`tCtrl + Shift + V"
    e["Sub_Mute"]               := "Mute / Unmute`tCtrl + Shift + M"
    e["Tray_CheckUpdate"]       := "Check for Updates..."
    e["Update_Available"]       := "A new version v{new} is available (current: v{curr})!`n`nWould you like to open GitHub Releases to download it?"
    e["Update_Latest"]          := "You are using the latest version (v{ver})."
    e["Update_Failed"]          := "Unable to check for updates. Please check your internet connection."
    e["Tip_Title"]              := "GestureMouse v" . (AppVersion ? AppVersion : "1.0.0") . "`n"
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
    e["Set_MouseVolume"]        := "Volume up/down"
    e["Set_MouseVolumeBtn"]     := "Hold Left Click + scroll wheel up or down"
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
    e["Set_PastePlain"]         := "Paste Plain Text"
    e["Set_OptionsBtn"]         := "Options.."
    e["Set_ExcludedAppsBtn"]    := "Excluded Apps..."
    e["TT_ExApps"]              := "Manage applications excluded from mouse gestures and right-click scroll"
    
    ; Excluded Apps
    e["Ex_Title"]               := "Excluded Applications"
    e["Ex_SelectOrSearch"]      := "Application:"
    e["Ex_AddBtn"]              := "+ Add"
    e["Ex_AddBrowse"]           := "Browse (.exe)..."
    e["Ex_ColProcess"]          := "Process Name (.exe)"
    e["Ex_ColTitle"]            := "Application Name"
    e["Ex_ColAction"]           := "Action"
    e["Ex_ActionDelete"]        := "✕ Delete"
    e["Ex_DeleteTip"]           := "* Select an application and click 'Delete' or press Delete key."
    e["Ex_AlreadyAdded"]        := "Already in the exclusion list!"
    e["Ex_AddSuccess"]          := "Added: "
    e["Ex_RemoveSuccess"]       := "Removed: "
    e["Ex_Close"]               := "Close"
    e["Ex_Remove"]              := "Delete"
    e["Set_GroupGeneral"]       := "General Settings"
    e["Set_AutoStart"]          := "Start with Windows"
    e["Set_ScrollMethodLabel"]  := "Scroll method (manual and auto-scroll):"
    e["Set_ScrollStyle1"]       := "Drag up/down to scroll content (like on phones)"
    e["Set_ScrollStyle2"]       := "Drag up/down to scroll the scrollbar"
    
    ; Tooltips
    e["TT_1"]                   := "Manually drag mouse to scroll content"
    e["TT_2"]                   := "Flick and release to auto-scroll"
    e["TT_3"]                   := "Scroll pages using mouse wheel"
    e["TT_MouseVolume"]          := "Hold left click and scroll wheel to quickly adjust volume"
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
    e["TT_PastePlain"]          := "Paste plain text (automatically trims whitespace & empty lines)"
    
    ; Options
    e["Opt_Title"]              := "Options"
    e["Opt_LockKB"]             := "Lock Keyboard"
    e["Opt_LockMouse"]          := "Lock mouse clicks (except moving and scrolling)"
    e["Opt_PreventAutoLock"]    := "Prevent auto screen lock while in lock mode"
    
    ; About
    e["About_Title"]            := "About Gesture Mouse"
    e["About_Headline"]         := "Mouse gestures, shortcuts and auto-scroll utility"
    e["About_Version"]          := "Version: " . (AppVersion ? AppVersion : "1.0.0") . " | Release Date: " . (AppReleaseDate ? AppReleaseDate : "02/11/2026")
    e["About_GuideTitle"]       := "User Guide:"
    e["About_Author"]           := "Author: Nguyen Tri An"
    e["About_Donate"]           := "Donate"
    e["About_Close"]            := "Close"
    e["About_TabGestures"]      := "Gestures"
    e["About_TabShortcuts"]     := "Shortcuts"
    e["About_TabSystem"]        := "System"
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
    if (!LangTable || !LangTable.HasKey("vi"))
        InitLanguage()
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
