; ExcludedApps.ahk - Quản lý danh sách ứng dụng loại trừ khỏi cử chỉ chuột và cuộn chuột
#NoEnv

global ExcludedAppsList := []     ; Danh sách mảng tên tiến trình (ví dụ: ["photoshop.exe", "figma.exe"])
global ExcludedAppsMap := {}      ; Hash table tra cứu siêu nhanh O(1)
global ExcludedAppsCount := 0     ; Số lượng ứng dụng bị loại trừ
global hExcludedGui := 0          ; HWND của GUI Quản lý ứng dụng loại trừ
global hExListView := 0           ; HWND của ListView
global hSearchCombo := 0          ; HWND của DropDownList
global ExListView := 0            ; Biến control ListView
global SearchCombo := ""          ; Biến control DropDownList chọn tiến trình
global AllRunningAppsData := []   ; Danh sách cache toàn bộ ứng dụng đang chạy

; Khởi tạo danh sách ứng dụng loại trừ từ Registry
InitExcludedApps() {
    global ExcludedAppsList, ExcludedAppsMap, ExcludedAppsCount
    ExcludedAppsList := []
    ExcludedAppsMap := {}
    ExcludedAppsCount := 0

    RegRead, savedApps, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, ExcludedApps
    if (savedApps != "") {
        Loop, Parse, savedApps, |
        {
            item := Trim(A_LoopField)
            if (item != "") {
                StringLower, itemLower, item
                if (!ExcludedAppsMap.HasKey(itemLower)) {
                    ExcludedAppsList.Push(itemLower)
                    ExcludedAppsMap[itemLower] := 1
                    ExcludedAppsCount++
                }
            }
        }
    }

    ; Bắt thông điệp khi người dùng chọn một mục từ danh sách sổ xuống của ComboBox
    OnMessage(0x0111, "ExcludedApps_WM_COMMAND")
}

; Lưu danh sách ứng dụng loại trừ vào Registry
SaveExcludedApps() {
    global ExcludedAppsList
    savedStr := ""
    for idx, proc in ExcludedAppsList {
        if (proc != "") {
            savedStr .= (savedStr = "" ? "" : "|") . proc
        }
    }
    RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\TRIAN\GestureMouse, ExcludedApps, %savedStr%
}

; Kiểm tra xem cửa sổ hiện tại (dưới chuột hoặc active) có thuộc danh sách loại trừ không
; Hàm này được tối ưu cực nhanh (O(1)), an toàn tuyệt đối khi gọi từ #If hook
IsAppExcluded() {
    global ExcludedAppsCount, ExcludedAppsMap
    if (!ExcludedAppsCount)
        return false

    ; 1. Kiểm tra cửa sổ dưới con trỏ chuột
    MouseGetPos,,, hoverHwnd
    if (hoverHwnd) {
        WinGet, hoverProc, ProcessName, ahk_id %hoverHwnd%
        if (hoverProc != "") {
            StringLower, hoverProc, hoverProc
            if (ExcludedAppsMap.HasKey(hoverProc))
                return true
        }
    }

    ; 2. Kiểm tra cửa sổ đang Active nếu khác cửa sổ hover
    activeHwnd := WinExist("A")
    if (activeHwnd && activeHwnd != hoverHwnd) {
        WinGet, activeProc, ProcessName, ahk_id %activeHwnd%
        if (activeProc != "") {
            StringLower, activeProc, activeProc
            if (ExcludedAppsMap.HasKey(activeProc))
                return true
        }
    }

    return false
}

; Hiển thị tooltip thông báo nhẹ nhàng không cần MsgBox
ShowNoticeToolTip(msg) {
    MouseGetPos, mX, mY
    ToolTip, %msg%, mX + 15, mY + 15
    fnCloseTip := Func("RemoveNoticeToolTip")
    SetTimer, %fnCloseTip%, -1200
}

RemoveNoticeToolTip() {
    ToolTip
}

; Gán icon vàng đồng bộ cho cửa sổ GUI
SetExcludedGuiIcon(guiHwnd) {
    if (!guiHwnd)
        return
    if (IsFunc("SetGuiYellowIcon")) {
        fn := "SetGuiYellowIcon"
        %fn%(guiHwnd)
    }
}

; Lấy tên ứng dụng thân thiện từ tiêu đề cửa sổ (VD: "Inbox - Google Chrome" -> "Google Chrome")
GetCleanAppName(winTitle, procName) {
    clean := RegExReplace(winTitle, "[\r\n\t|]+", " ")
    clean := Trim(clean)

    ; Nếu có dấu gạch ngang phân cách, lấy tên ứng dụng ở phần cuối cùng
    lastDash := InStr(clean, " - ", false, 0)
    if (lastDash) {
        candidate := Trim(SubStr(clean, lastDash + 3))
        if (candidate != "" && StrLen(candidate) <= 35)
            return candidate
    }

    ; Nếu không có " - " hoặc quá dài, rút gọn
    if (StrLen(clean) > 35)
        clean := SubStr(clean, 1, 32) . "..."

    ; Nếu tiêu đề rỗng, tạo tên đẹp từ tên file exe (vd: notepad.exe -> Notepad)
    if (clean = "") {
        base := RegExReplace(procName, "i)\.exe$", "")
        return Format("{:U}{:L}", SubStr(base, 1, 1), SubStr(base, 2))
    }
    return clean
}

; Quét danh sách các ứng dụng đang chạy (lấy cả tên tiến trình và tên ứng dụng)
ScanAllRunningApps() {
    global AllRunningAppsData
    AllRunningAppsData := []
    seenProcs := {}

    WinGet, winList, List
    Loop, %winList%
    {
        hwnd := winList%A_Index%
        WinGet, style, Style, ahk_id %hwnd%
        if !(style & 0x10000000) ; Chỉ lấy cửa sổ có WS_VISIBLE
            continue

        WinGetTitle, winTitle, ahk_id %hwnd%
        if (winTitle = "")
            continue

        WinGetClass, winClass, ahk_id %hwnd%
        if (winClass ~= "^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd|DV2ControlHost|Windows\.UI\.Core\.CoreWindow)$")
            continue

        WinGet, procName, ProcessName, ahk_id %hwnd%
        if (procName = "" || procName ~= "i)^(GestureMouse.*|AutoHotkey.*)$")
            continue

        StringLower, procLower, procName
        procLower := Trim(procLower)
        if (procLower != "" && !seenProcs.HasKey(procLower)) {
            seenProcs[procLower] := 1
            appName := GetCleanAppName(winTitle, procLower)
            disp := procLower . " - " . appName
            AllRunningAppsData.Push({"proc": procLower, "name": appName, "display": disp})
        }
    }

    ; Sắp xếp danh sách theo thứ tự bảng chữ cái A-Z
    sortStr := ""
    for idx, item in AllRunningAppsData {
        sortStr .= (sortStr = "" ? "" : "`n") . item.proc . "`t" . item.name . "`t" . item.display
    }
    Sort, sortStr
    AllRunningAppsData := []
    Loop, Parse, sortStr, `n
    {
        if (A_LoopField != "") {
            parts := StrSplit(A_LoopField, "`t")
            AllRunningAppsData.Push({"proc": parts[1], "name": parts[2], "display": parts[3]})
        }
    }
}

; Lấy chuỗi danh sách ứng dụng cho ComboBox (phân cách bởi dấu |)
GetRunningProcsComboList() {
    global AllRunningAppsData
    comboStr := ""
    for idx, item in AllRunningAppsData {
        comboStr .= (comboStr = "" ? "" : "|") . item.display
    }
    return comboStr
}

; ==============================================================================
; GUI QUẢN LÝ ỨNG DỤNG LOẠI TRỪ (MODAL DIALOG - NATIVE COMBOBOX)
; ==============================================================================

OpenExcludedAppsGui(ctrlHwnd := 0, guiEvent := "", eventInfo := "") {
    ShowExcludedAppsGui()
}

ShowExcludedAppsGui() {
    global hExcludedGui, hSettingsGui, ExExcludedAppsList, ExListView, SearchCombo
    global hExListView, hSearchCombo

    ; Nếu cửa sổ đã tồn tại, kích hoạt lại
    if (hExcludedGui && WinExist("ahk_id " . hExcludedGui)) {
        Gui, ExcludedApps:Show
        WinActivate, ahk_id %hExcludedGui%
        return
    }

    ; Vô hiệu hóa tương tác cửa sổ Settings cha trong khi mở cửa sổ con (Modal)
    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) {
        Gui, Settings:+Disabled
    }

    ; Quét danh sách ứng dụng đang chạy
    ScanAllRunningApps()
    comboList := GetRunningProcsComboList()

    ownerOpt := (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) ? "+Owner" . hSettingsGui : ""
    Gui, ExcludedApps:New, %ownerOpt% +HwndhExcludedGui, % L("Ex_Title")
    SetExcludedGuiIcon(hExcludedGui)
    Gui, ExcludedApps:Font, s10, Arial

    ; 1. Hàng trên đầu: Nhãn, DropDownList chọn tiến trình đang chạy (không cho gõ text), Nút chọn file .exe
    Gui, ExcludedApps:Add, Text, x15 y14, % L("Ex_SelectOrSearch")
    Gui, ExcludedApps:Add, DropDownList, x80 y11 w325 r20 +HwndhSearchCombo vSearchCombo gOnComboSelect, %comboList%
    Gui, ExcludedApps:Add, Button, x415 y10 w110 h26 gBrowseExeFile, % L("Ex_AddBrowse")

    ; 2. Bảng danh sách tiến trình loại trừ gồm 2 cột: Tên tiến trình (.exe) và Tên ứng dụng
    Gui, ExcludedApps:Add, ListView, x15 y45 w510 h260 +HwndhExListView vExListView gOnExListViewEvent Grid -Multi, % L("Ex_ColProcess") . "|" . L("Ex_ColTitle")

    ; 3. Hàng dưới cùng: Hướng dẫn xóa và nút Xóa đơn giản (không có nút Đóng)
    Gui, ExcludedApps:Add, Text, x15 y318 w390 c777777, % L("Ex_DeleteTip")
    Gui, ExcludedApps:Add, Button, x435 y313 w90 h28 gRemoveSelectedApp, % L("Ex_Remove")

    ; Đăng ký phím Delete khi cửa sổ ExcludedApps kích hoạt để xóa mục được chọn
    Hotkey, IfWinActive, ahk_id %hExcludedGui%
    Hotkey, Delete, OnExListViewDelete, On

    RefreshExcludedAppsListView()
    Gui, ExcludedApps:Show, AutoSize Center, % L("Ex_Title")
    SetExcludedGuiIcon(hExcludedGui)

    ; Đặt focus ban đầu vào ListView (không tự động nhảy con trỏ vào ô chọn)
    GuiControl, ExcludedApps:Focus, ExListView
}

; Cập nhật dữ liệu vào ListView của cửa sổ loại trừ (có cả Tên tiến trình và Tên ứng dụng)
RefreshExcludedAppsListView() {
    global ExcludedAppsList, AllRunningAppsData
    Gui, ExcludedApps:Default
    LV_Delete()

    nameMap := {}
    for idx, item in AllRunningAppsData {
        nameMap[item.proc] := item.name
    }

    for idx, proc in ExcludedAppsList {
        appName := nameMap.HasKey(proc) ? nameMap[proc] : ""
        if (appName = "") {
            base := RegExReplace(proc, "i)\.exe$", "")
            appName := Format("{:U}{:L}", SubStr(base, 1, 1), SubStr(base, 2))
        }
        LV_Add("", proc, appName)
    }
    LV_ModifyCol(1, 180)
    LV_ModifyCol(2, 305)
}

; Khi người dùng chọn 1 mục từ danh sách sổ xuống -> Thêm ngay!
OnComboSelect(ctrlHwnd := 0, guiEvent := "", eventInfo := "") {
    OnComboSelEndOk()
}

OnComboSelEndOk() {
    global hSearchCombo
    GuiControlGet, selItem, ExcludedApps:, SearchCombo
    selItem := Trim(selItem)
    if (selItem != "") {
        GuiControl, ExcludedApps:Choose, SearchCombo, 0
        GuiControl, ExcludedApps:Focus, ExListView
        ProcessAndAddApp(selItem)
    }
}

; Xử lý và thêm ứng dụng vào danh sách
ProcessAndAddApp(inputVal) {
    global ExcludedAppsList, ExcludedAppsMap, ExcludedAppsCount
    inputVal := Trim(inputVal)
    if (inputVal = "")
        return

    ; Trích xuất tên tiến trình nếu có định dạng "proc.exe - App Name"
    if (InStr(inputVal, " - "))
        procName := Trim(SubStr(inputVal, 1, InStr(inputVal, " - ") - 1))
    else if (InStr(inputVal, "|"))
        procName := Trim(SubStr(inputVal, 1, InStr(inputVal, "|") - 1))
    else
        procName := inputVal

    ; Tách lấy tên file nếu người dùng dán đường dẫn
    if (InStr(procName, "\"))
        SplitPath, procName, procName

    ; Tự động thêm đuôi .exe nếu người dùng chỉ gõ tên chương trình
    if (!InStr(procName, "."))
        procName .= ".exe"

    StringLower, procName, procName

    if (ExcludedAppsMap.HasKey(procName)) {
        ShowNoticeToolTip(L("Ex_AlreadyAdded"))
        return
    }

    ; Thêm trực tiếp không cần xác nhận
    ExcludedAppsList.Push(procName)
    ExcludedAppsMap[procName] := 1
    ExcludedAppsCount++

    SaveExcludedApps()
    RefreshExcludedAppsListView()

    ; Chọn luôn dòng vừa thêm
    total := LV_GetCount()
    if (total > 0)
        LV_Modify(total, "Select Focus Vis")

    ShowNoticeToolTip(L("Ex_AddSuccess") . procName)
}

; Chọn file .exe từ máy tính
BrowseExeFile(ctrlHwnd := 0, guiEvent := "", eventInfo := "") {
    global ExcludedAppsList, ExcludedAppsMap, ExcludedAppsCount

    FileSelectFile, selectedPath, 3, , % L("Ex_AddBrowse"), Executable Files (*.exe)
    if (selectedPath = "" || ErrorLevel)
        return

    SplitPath, selectedPath, fileName
    StringLower, fileLower, fileName

    if (ExcludedAppsMap.HasKey(fileLower)) {
        ShowNoticeToolTip(L("Ex_AlreadyAdded"))
        return
    }

    ; Thêm trực tiếp không cần xác nhận
    ExcludedAppsList.Push(fileLower)
    ExcludedAppsMap[fileLower] := 1
    ExcludedAppsCount++

    SaveExcludedApps()
    RefreshExcludedAppsListView()

    total := LV_GetCount()
    if (total > 0)
        LV_Modify(total, "Select Focus Vis")

    ShowNoticeToolTip(L("Ex_AddSuccess") . fileLower)
}

; Xóa trực tiếp một hàng và tự động chọn hàng kế tiếp để xóa liên tục dễ dàng
RemoveRowDirectly(rowIndex) {
    global ExcludedAppsList, ExcludedAppsMap, ExcludedAppsCount
    if (!rowIndex)
        return

    Gui, ExcludedApps:Default
    LV_GetText(procName, rowIndex, 1)
    if (procName = "")
        return

    StringLower, procLower, procName
    newArr := []
    for idx, item in ExcludedAppsList {
        if (item != procLower)
            newArr.Push(item)
    }
    ExcludedAppsList := newArr
    ExcludedAppsMap.Delete(procLower)
    ExcludedAppsCount := ExcludedAppsList.Length() ? ExcludedAppsList.Length() : 0

    SaveExcludedApps()
    RefreshExcludedAppsListView()
    ShowNoticeToolTip(L("Ex_RemoveSuccess") . procLower)

    ; Tự động chọn tiến trình kế tiếp để người dùng bấm xóa tiếp dễ dàng
    totalRows := LV_GetCount()
    if (totalRows > 0) {
        nextRow := (rowIndex <= totalRows) ? rowIndex : totalRows
        LV_Modify(nextRow, "Select Focus Vis")
    }
}

; Nút Xóa hàng đang chọn ở footer
RemoveSelectedApp(ctrlHwnd := 0, guiEvent := "", eventInfo := "") {
    Gui, ExcludedApps:Default
    selectedRow := LV_GetNext(0, "Focused")
    if (!selectedRow)
        selectedRow := LV_GetNext(0)
    if (selectedRow)
        RemoveRowDirectly(selectedRow)
}

; Bắt phím Delete trên ListView
OnExListViewDelete(key := "") {
    global hExcludedGui
    GuiControlGet, fCtrl, ExcludedApps:Focus
    ; Nếu focus đang ở ListView hoặc đang chọn dòng trong ListView
    if (fCtrl = "ExListView" || InStr(fCtrl, "SysListView32")) {
        RemoveSelectedApp()
    } else {
        Send, {Delete}
    }
}

OnExListViewEvent(ctrlHwnd := 0, guiEvent := "", eventInfo := "") {
    if ((guiEvent = "K" || A_GuiEvent = "K") && (eventInfo = 46 || A_EventInfo = 46)) { ; 46 = VK_DELETE
        RemoveSelectedApp()
    }
}

; Đóng GUI ExcludedApps và mở lại tương tác cho cửa sổ Settings cha
CloseExcludedGui(ctrlHwnd := 0, guiEvent := "", eventInfo := "") {
    global hExcludedGui, hSettingsGui

    if (!hExcludedGui)
        return

    ; Tắt hotkey phím Delete (bọc trong try để tuyệt đối an toàn)
    try {
        Hotkey, IfWinActive, ahk_id %hExcludedGui%
        Hotkey, Delete, Off
    }

    if (hSettingsGui && WinExist("ahk_id " . hSettingsGui)) {
        Gui, Settings:-Disabled
        WinActivate, ahk_id %hSettingsGui%
    }

    if (WinExist("ahk_id " . hExcludedGui)) {
        Gui, ExcludedApps:Destroy
    }
    hExcludedGui := 0
}

ExcludedAppsGuiClose(guiHwnd := 0) {
    CloseExcludedGui()
}

ExcludedAppsGuiEscape(guiHwnd := 0) {
    CloseExcludedGui()
}

; ==============================================================================
; WINDOWS MESSAGES
; ==============================================================================

ExcludedApps_WM_COMMAND(wParam, lParam, msg, hwnd) {
    global hSearchCombo
    if (lParam = hSearchCombo) {
        code := wParam >> 16
        if (code = 9) { ; CBN_SELENDOK: Người dùng nhấn chọn 1 mục từ danh sách sổ xuống
            fnProcess := Func("OnComboSelEndOk")
            SetTimer, %fnProcess%, -20
        }
    }
}
