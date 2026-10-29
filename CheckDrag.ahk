#NoEnv
SetBatchLines, -1
CoordMode, Mouse, Screen
#Persistent

SetTimer, CheckDraggingFileOrDesktop, 100
return

CheckDraggingFileOrDesktop:
if GetKeyState("LButton", "P") || GetKeyState("RButton", "P")
{
    MouseGetPos, , , hwndUnderCursor
    WinGetClass, classUnderMouse, ahk_id %hwndUnderCursor%

    ; Kiểm tra nếu chuột đang ở Explorer
    if (classUnderMouse ~= "^(CabinetWClass|ExploreWClass)$")
    {
        tab := GetActiveExplorerTab(hwndUnderCursor)
        if (tab && tab.Document.SelectedItems.Count > 0)
        {
            msg := "🟡 Đang kéo file từ Explorer (Tab: " . tab.Document.Folder.Self.Path . ")"
            ToolTip %msg%
            return
        }
    }
}
; ToolTip  ; Ẩn nếu không thỏa điều kiện
return

; Hàm lấy tab đang hoạt động trong Explorer
GetActiveExplorerTab(hwnd:="") {
    static IID_IShellBrowser := "{000214E2-0000-0000-C000-000000000046}"

    activeTab := 0, hwnd := hwnd ? hwnd : WinExist("A")
    try
        ControlGet, activeTab, Hwnd,, ShellTabWindowClass1, ahk_id %hwnd% ; File Explorer (Windows 11)
    catch
        return  ; Nếu không tìm thấy tab, thoát hàm.
    for w in ComObjCreate("Shell.Application").Windows {
        if (w.hwnd != hwnd)
            continue
        if (activeTab) { ; The window has tabs, so make sure this is the right one.
            shellBrowser := ComObjQuery(w, IID_IShellBrowser, IID_IShellBrowser)
            DllCall(NumGet(NumGet(shellBrowser+0), 3*A_PtrSize), "UPtr",shellBrowser, "UIntP",thisTab:=0)
            if (thisTab != activeTab)
                continue
        }
      ; Kiểm tra nếu tab có mục được chọn
        if (w.Document.SelectedItems.Count > 0)
            return true
    }
    return false  ; Không tìm thấy tab hoặc không có mục nào được chọn.
    ; return w ; trả về đối tượng Explorer hiện tại
}
~RButton:: 
if GetActiveExplorerTab() 
    Tooltip % "🟡 Đang kéo file từ Explorer (Tab: " . GetActiveExplorerTab().Document.Folder.Self.Path . ")"