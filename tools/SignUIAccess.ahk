#Requires AutoHotkey v2.0
#SingleInstance Force
#Include EnableUIAccess.ahk

if (A_Args.Length < 1)
    ExitApp 1

targetExe := A_Args[1]
if (!FileExist(targetExe))
    ExitApp 1

try {
    EnableUIAccess(targetExe)
    
    ; Kiem tra xac thuc chu ky
    err := EnableUIAccess_Verify(targetExe)
    if (err == 0) {
        ExitApp 0
    } else {
        ExitApp 0
    }
} catch as e {
    MsgBox "Loi khi kich hoat UIAccess:`n" e.Message, "GestureMouse Error", 16
    ExitApp 1
}