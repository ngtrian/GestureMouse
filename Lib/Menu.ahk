; Menu.ahk - Quản lý Menu Tray, Cài đặt và Giới thiệu
#NoEnv

Menu:
    global hSettingsGui := 0, hAboutGui := 0, hLockOpt := 0, hAutoLock := 0, hExcludedGui := 0, hRunningAppsGui := 0
    ; Khởi tạo ngôn ngữ và trạng thái cử chỉ
    InitLanguage()
    InitGestureScroll()
    InitExcludedApps()
    if (IsFunc("InitLockManager"))
        InitLockManager()
    if (IsFunc("InitAlwaysOnTop"))
        InitAlwaysOnTop()
    if (IsFunc("InitMicMute"))
        InitMicMute()
    if (IsFunc("InitScreenOff"))
        InitScreenOff()
    if (IsFunc("InitPopupBlocker"))
        InitPopupBlocker()

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
    global Brightness, GuiOn, isLocked, mouseLockEnabled, GestureScrollEnabled, lockMode, focusWndTitle, lockTimerActive
    TrayTip := L("Tip_Title")
    
    GestureTip := L("Tip_Gesture") . (GestureScrollEnabled ? L("Tip_On") : L("Tip_Off")) . "`n"
    if (isLocked) {
        if (lockMode == 1) {
            shortTitle := SubStr(focusWndTitle, 1, 20) . (StrLen(focusWndTitle) > 20 ? "..." : "")
            LockKeyboardTip := "Focus Lock: " . shortTitle . "`n"
        } else {
            LockKeyboardTip := L("Tip_LockKB") . L("Tip_On") . "`n"
        }
    } else {
        LockKeyboardTip := L("Tip_LockKB") . L("Tip_Off") . "`n"
    }
    LockMouseTip := L("Tip_LockMouse") . (mouseLockEnabled && isLocked ? L("Tip_On") : L("Tip_Off")) . "`n"
    LockTimerTip := (lockTimerActive && IsFunc("GetActiveTimerStatusText")) ? (L("Tip_LockTimer") . GetActiveTimerStatusText() . "`n") : ""

    TrayTip .= GestureTip
    TrayTip .= LockKeyboardTip
    TrayTip .= LockMouseTip
    TrayTip .= LockTimerTip

    ; Độ sáng
    BrightnessPercent := Round((255 - Brightness) / 255 * 100)
    TrayTip .= L("Tip_Brightness") . BrightnessPercent . "%" . (GuiOn ? L("Tip_GuiOn") : L("Tip_GuiOff"))
    if (IsObject(AOTPinnedWindows) && AOTPinnedWindows.Count() > 0)
        TrayTip .= "`n" . L("AOT_TrayCount") . AOTPinnedWindows.Count()
    Menu, Tray, Tip, %TrayTip%
}

; Xây dựng lại toàn bộ menu khay theo ngôn ngữ hiện tại
RebuildTrayMenu() {
    global GestureScrollEnabled, CurrentLang

    ; Xóa menu cũ
    try Menu, Tray, DeleteAll
    try Menu, PhimTat, DeleteAll
    try Menu, LangMenu, DeleteAll

    ; Sub-menu Phím tắt (gắn với GestureScrollEnabled)
    Menu, PhimTat, Add, % L("Sub_PlainText"), PastePlainText
    Menu, PhimTat, Add, % L("Sub_Mute"), MuteFunc
    micHkTxt := (IsFunc("FormatMicHotkeyText") && MicMuteHotkey != "") ? ("`t" . FormatMicHotkeyText(MicMuteHotkey)) : ""
    Menu, PhimTat, Add, % L("Sub_MicMute") . micHkTxt, MenuActionToggleMicMute
    screenHkTxt := (ScreenOffEnabled && IsFunc("FormatScreenOffHotkeyText") && ScreenOffHotkey != "") ? ("`t" . FormatScreenOffHotkeyText(ScreenOffHotkey)) : ""
    Menu, PhimTat, Add, % L("Sub_ScreenOff") . screenHkTxt, MenuActionTurnOffScreen
    Menu, PhimTat, Add
    Menu, PhimTat, Add, % L("Sub_PopupBlocker"), MenuActionTogglePopupBlocker
    if (PopupBlockerEnabled)
        Menu, PhimTat, Check, % L("Sub_PopupBlocker")
    else
        Menu, PhimTat, Uncheck, % L("Sub_PopupBlocker")
    Menu, PhimTat, Add, % L("Sub_PopupBlockerRules"), MenuActionOpenPopupBlocker
    Menu, PhimTat, Add
    Menu, PhimTat, Add, % L("Sub_ShortcutSettings"), MenuActionOpenShortcuts

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
    Menu, Tray, Add, % L("Tray_Settings"), MenuActionSettings
    Menu, Tray, Add, % L("Sub_LockCenter"), MenuActionLockCenter

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
    if (!A_IsCompiled) {
        Menu, Tray, Add, % L("Tray_Reload"), ReloadApp
        Menu, Tray, Add  ; Dòng phân cách
    }
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
    global GestureScrollEnabled, hSettingsGui
    try {
        menuGestureText := GestureScrollEnabled ? L("Tray_Enabled") : L("Tray_Disabled")
        Menu, Tray, Rename, 1&, %menuGestureText%
        if (GestureScrollEnabled) {
            Menu, Tray, Check, 1&
            try Menu, Tray, Enable, % L("Tray_Shortcuts")
        }
        else
        {
            Menu, Tray, Uncheck, 1&
            try Menu, Tray, Disable, % L("Tray_Shortcuts")
        }
        Menu, Tray, Default, 1&

        if (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) {
            GuiControl, Settings:, GestureEnabled, %GestureScrollEnabled%
        }
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


; Giao diện Cài đặt (Settings GUI) đã được tách riêng sang Lib\Settings.ahk



CreateOption() {
    global mouseLockEnabled, disableAutoLockScreen, hSettingsGui, hLockOpt

    if (hLockOpt && WinExist("ahk_id " . hLockOpt)) {
        Gui, LockOptions:Show
        WinActivate, ahk_id %hLockOpt%
        return
    }

    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) {
        Gui, Settings:+Disabled
    }

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, mouseLockEnabled 
    if (val != "")
        mouseLockEnabled := val

    RegRead, val, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, disableAutoLockScreen
    if (val != "")
        disableAutoLockScreen := val

    ownerOpt := (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) ? "+Owner" . hSettingsGui : ""
    Gui, LockOptions:New, +LastFound %ownerOpt% +HwndhLockOpt, % L("Opt_Title")
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



LockOptionsGuiClose:
LockOptionsGuiEscape:
    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) {
        Gui, Settings:-Disabled
        WinActivate, ahk_id %hSettingsGui%
    }
    Gui, LockOptions:Destroy
    hLockOpt := 0
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

    ; 3. Tắt nhẹ tiến trình GestureMouse trong Program Files nếu đang chạy để tránh khóa file
    currentPid := DllCall("GetCurrentProcessId")
    RunWait, %ComSpec% /c powershell -NoProfile -Command "Get-Process -Name GestureMouse -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne %currentPid% } | Stop-Process -Force",, Hide
    Sleep, 400

    ; 4. Copy file vào Program Files
    FileCopy, %A_ScriptFullPath%, %destExe%, 1
    if (ErrorLevel) {
        MsgBox, 16, GestureMouse, % L("Install_Error") . "Không thể sao chép file vào " . destDir
        return
    }

    ; 5. Tạo Shortcut trong Start Menu (Shortcut ứng dụng và Shortcut gỡ cài đặt)
    startMenuDir := A_AppDataCommon . "\Microsoft\Windows\Start Menu\Programs\GestureMouse"
    FileCreateDir, %startMenuDir%
    FileCreateShortcut, %destExe%, %startMenuDir%\GestureMouse.lnk, %destDir%,, GestureMouse, %destExe%,, 1
    FileCreateShortcut, %destExe%, %startMenuDir%\Uninstall GestureMouse.lnk, %destDir%, /uninstall, "Uninstall GestureMouse", %A_WinDir%\System32\shell32.dll,, 32
    ; Tạo shortcut gỡ cài đặt ngay trong thư mục Program Files
    FileCreateShortcut, %destExe%, %destDir%\Uninstall GestureMouse.lnk, %destDir%, /uninstall, "Uninstall GestureMouse", %A_WinDir%\System32\shell32.dll,, 32
    ; Tạo shortcut gỡ cài đặt ngay trong thư mục Program Files
    FileCreateShortcut, %destExe%, %destDir%\Uninstall GestureMouse.lnk, %destDir%, /uninstall, "Uninstall GestureMouse", %A_WinDir%\System32\shell32.dll,, 32

    ; 6. Tự động thêm vào Startup (Khởi động cùng Windows)
    RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, GestureMouse, "%destExe%"

    ; 7. Khởi chạy bản đã cài đặt trong Program Files kèm cờ thông báo thành công
    Run, "%destExe%" /installed_notify

    ; 8. Thoát bản chạy tạm thời
    ExitApp
}

UninstallFromSystem:
    UninstallApp()
return

UninstallApp() {
    if (!A_IsCompiled) {
        MsgBox, 64, GestureMouse, % "Tính năng này chỉ dành cho file .exe đã cài đặt!"
        return
    }

    ; Xác nhận từ người dùng
    MsgBox, 36, GestureMouse, % L("Uninstall_Confirm")
    IfMsgBox, No
        return

    ; Nếu chưa có quyền Admin, yêu cầu nâng quyền và chuyển sang chế độ đã xác nhận
    if (!A_IsAdmin) {
        try {
            Run *RunAs "%A_ScriptFullPath%" /uninstall_confirmed
        }
        return
    }

    PerformUninstallation()
}

PerformUninstallationCLI(isConfirmed := false) {
    if (!isConfirmed) {
        MsgBox, 36, GestureMouse, % L("Uninstall_Confirm")
        IfMsgBox, No
            return
    }

    if (!A_IsAdmin) {
        try {
            Run *RunAs "%A_ScriptFullPath%" /uninstall_confirmed
        }
        return
    }

    PerformUninstallation()
}

PerformUninstallation() {
    destDir := "C:\Program Files\GestureMouse"
    startMenuDir := A_AppDataCommon . "\Microsoft\Windows\Start Menu\Programs\GestureMouse"

    ; 1. Tắt các tiến trình GestureMouse khác đang chạy
    currentPid := DllCall("GetCurrentProcessId")
    RunWait, %ComSpec% /c powershell -NoProfile -Command "Get-Process -Name GestureMouse -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne %currentPid% } | Stop-Process -Force",, Hide

    ; 2. Xóa khỏi danh sách khởi động cùng Windows
    try {
        RegDelete, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, GestureMouse
    }

    ; 3. Xóa thư mục và shortcut trong Start Menu
    FileRemoveDir, %startMenuDir%, 1

    ; 4. Thông báo cho người dùng đã gỡ cài đặt thành công
    MsgBox, 64, GestureMouse, % L("Uninstall_Success")

    ; 5. Dọn dẹp thư mục Program Files sau khi tiến trình thoát
    cmdCleanup := "cmd.exe /c timeout /t 2 /nobreak >nul & rmdir /s /q """ . destDir . """"
    Run, %cmdCleanup%,, Hide

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

CheckForUpdates:
    CheckUpdates(false)
return

CheckUpdates(silentIfLatest := false) {
    global AppVersion, AppGitHubRepo
    repo := AppGitHubRepo ? AppGitHubRepo : "ngtrian/GestureMouse"
    currVer := AppVersion ? AppVersion : "1.1.0"
    url := "https://api.github.com/repos/" . repo . "/releases/latest"

    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", url, true)
        whr.SetRequestHeader("User-Agent", "GestureMouse-App")
        whr.Send()
        whr.WaitForResponse(5)
        response := whr.ResponseText

        if RegExMatch(response, "i)""tag_name""\s*:\s*""v?([^""]+)""", match) {
            latestVer := match1
            if (CompareVersions(latestVer, currVer) > 0) {
                msg := StrReplace(StrReplace(L("Update_Available"), "{new}", latestVer), "{curr}", currVer)
                MsgBox, 36, GestureMouse, %msg%
                IfMsgBox, Yes
                    Run, % "https://github.com/" . repo . "/releases/latest"
                return
            }
        }

        if (!silentIfLatest) {
            msg := StrReplace(L("Update_Latest"), "{ver}", currVer)
            MsgBox, 64, GestureMouse, %msg%
        }
    } catch {
        if (!silentIfLatest)
            MsgBox, 48, GestureMouse, % L("Update_Failed")
    }
}

CompareVersions(v1, v2) {
    StringSplit, a, v1, .
    StringSplit, b, v2, .
    maxParts := (a0 > b0) ? a0 : b0
    Loop, %maxParts% {
        p1 := (a%A_Index% != "") ? a%A_Index% + 0 : 0
        p2 := (b%A_Index% != "") ? b%A_Index% + 0 : 0
        if (p1 > p2)
            return 1
        if (p1 < p2)
            return -1
    }
    return 0
}

ExitMenu:
    ExitApp
return

MenuActionSettings:
    SetTimer, Settings, -30
return

MenuActionToggleMicMute:
    if (IsFunc("ToggleMicMute"))
        ToggleMicMute(true)
return

MenuActionTurnOffScreen:
    if (IsFunc("TurnOffMonitor"))
        TurnOffMonitor(false)
return

MenuActionTogglePopupBlocker:
    if (IsFunc("TogglePopupBlocker"))
        TogglePopupBlocker()
    if (IsFunc("SyncPopupBlockerSettingsUI"))
        SyncPopupBlockerSettingsUI()
return

MenuActionOpenPopupBlocker:
    if (IsFunc("OpenPopupBlockerGui"))
        OpenPopupBlockerGui()
return

MenuActionOpenShortcuts:
    currentSettingsTab := 4
    SetTimer, Settings, -30
return

ReloadApp:
    Reload
return

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

MenuActionLockCenter:
    Sleep, 150
    if (IsFunc("OpenLockCenterFromUI"))
        OpenLockCenterFromUI()
return

MenuActionFocusLock:
    Sleep, 200
    if (IsFunc("TriggerFocusLockDirect")) {
        fnFocus := "TriggerFocusLockDirect"
        %fnFocus%(WinExist("A"))
    }
return

; Giữ icon chính của ứng dụng và các cửa sổ GUI LUÔN là màu vàng
SetScriptYellowIcon() {
    global hSettingsGui, hAboutGui, hLockOpt, hAutoLock, hLockCenterGui
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
    if (hLockCenterGui && WinExist("ahk_id " . hLockCenterGui))
        SetGuiYellowIcon(hLockCenterGui)
    if (hExcludedGui && WinExist("ahk_id " . hExcludedGui))
        SetGuiYellowIcon(hExcludedGui)
    if (hRunningAppsGui && WinExist("ahk_id " . hRunningAppsGui))
        SetGuiYellowIcon(hRunningAppsGui)
    DetectHiddenWindows, %dhw%
}
