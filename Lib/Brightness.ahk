; Brightness.ahk - Điều chỉnh độ sáng màn hình bằng lớp phủ & GDI+ Pill OSD (bước nhảy 5%, hỗ trợ kéo trực tiếp trên OSD)

; ========================================================
; KHỞI TẠO GUI LỚP PHỦ & HỆ THỐNG OSD ĐỘ SÁNG
; ========================================================
BrightnessGui:
    global Brightness, BrightnessPercent, GuiOn, hwndBrightness
    global hBrightnessOsdGui, BrightnessOsdVisible, BrightnessOsdAlpha, BrightnessOsdBitmap
    global BrightnessOsdW, BrightnessOsdH, BrightnessOsdX, BrightnessOsdY
    global BrightnessBarX, BrightnessBarW, BrightnessOsdDragging
    global BrightnessGdipModule, BrightnessGdipToken

    if (!BrightnessPercent)
        BrightnessPercent := 100
    Brightness := 0
    GuiOn := false

    hBrightnessOsdGui     := 0
    BrightnessOsdVisible  := false
    BrightnessOsdAlpha    := 255
    BrightnessOsdBitmap   := 0
    BrightnessOsdW := 0, BrightnessOsdH := 0, BrightnessOsdX := 0, BrightnessOsdY := 0
    BrightnessBarX := 0, BrightnessBarW := 0
    BrightnessOsdDragging := false
    BrightnessGdipModule  := 0
    BrightnessGdipToken   := 0

    Gui, BrightnessGui:New, +LastFound +AlwaysOnTop -Caption +ToolWindow +E0x20 +HwndhwndBrightness   ; Không viền, luôn trên cùng, nhấp xuyên qua
    Gui, Color, 000000  ; Màu đen
    Gui, -DPIScale      ; Đảm bảo GUI phù hợp với màn hình DPI cao
    WinSet, Transparent, 0, ahk_id %hwndBrightness%

    OnMessage(0x0201, "OnBrightnessOsdLButtonDown") ; WM_LBUTTONDOWN: Nhấn/kéo trên OSD
    OnMessage(0x020A, "OnBrightnessOsdMouseWheel")  ; WM_MOUSEWHEEL: Cuộn chuột trên OSD
    OnExit("CleanupBrightnessOsd")
return

; ========================================================
; PHÍM TẮT TĂNG / GIẢM ĐỘ SÁNG (BƯỚC NHẢY 5%)
; ========================================================
#If (GestureScrollEnabled)
; Phím F9: Giảm độ sáng 5%
F9::
    SetBrightnessPercent(BrightnessPercent - 5)
return

; Phím F10: Tăng độ sáng 5%
F10::
    SetBrightnessPercent(BrightnessPercent + 5)
return
#If

; ========================================================
; CẬP NHẬT ĐỘ SÁNG THEO PHẦN TRĂM (5% - 100%)
; ========================================================
SetBrightnessPercent(newPercent, showOsd := true) {
    global Brightness, BrightnessPercent, GuiOn, hwndBrightness

    newPercent := Round(newPercent)
    if (newPercent < 5)
        newPercent := 5
    if (newPercent > 100)
        newPercent := 100

    BrightnessPercent := newPercent
    Brightness := Round((100 - BrightnessPercent) * 2.55)

    if (BrightnessPercent >= 100) {
        Brightness := 0
        GuiOn := false
        Gui, BrightnessGui:Hide
    } else {
        GuiOn := true
        Gui, BrightnessGui:Show, x0 y0 w%A_ScreenWidth% h%A_ScreenHeight% NoActivate
        WinSet, Transparent, %Brightness%, ahk_id %hwndBrightness%
    }

    UpdateTrayTip()
    if (showOsd)
        ShowBrightnessOsd()
}

BrightnessTip:
    ShowBrightnessOsd()
return

; ========================================================
; GDI+ PILL OSD (TỰ ẨN, KHÔNG CƯỚP FOCUS, CHO PHÉP KÉO)
; ========================================================
EnsureBrightnessGdip() {
    global BrightnessGdipModule, BrightnessGdipToken
    if (BrightnessGdipToken)
        return true
    if (!BrightnessGdipModule)
        BrightnessGdipModule := DllCall("LoadLibrary", "Str", "gdiplus", "Ptr")
    if (!BrightnessGdipModule)
        return false
    VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0)
    NumPut(1, si, 0, "UInt")
    token := 0
    if (DllCall("gdiplus\GdiplusStartup", "Ptr*", token, "Ptr", &si, "Ptr", 0) != 0)
        return false
    BrightnessGdipToken := token
    return true
}

ShowBrightnessOsd() {
    global hBrightnessOsdGui, BrightnessOsdVisible, BrightnessOsdAlpha
    global BrightnessOsdW, BrightnessOsdH, BrightnessOsdX, BrightnessOsdY
    global BrightnessPercent, BrightnessOsdDragging

    if (!EnsureBrightnessGdip())
        return

    SetTimer, BrightnessOsdHoldTimer, Off
    SetTimer, BrightnessOsdFadeTimer, Off

    ; Không gắn +E0x20 (click-through) để cho phép nhấn/kéo trực tiếp trên OSD
    ; Gắn +E0x08000000 (WS_EX_NOACTIVATE) để không cướp focus cửa sổ đang dùng
    if (!hBrightnessOsdGui) {
        Gui, BrightnessOsd:New, +AlwaysOnTop -Caption +ToolWindow +E0x80000 +E0x08000000 +HwndhBrightnessOsdGui
    }

    scale := A_ScreenDPI / 96.0
    osdW := Round(218 * scale)
    osdH := Round(40 * scale)

    ; Định vị OSD ở giữa-dưới vùng làm việc màn hình chính (phía trên Taskbar)
    SysGet, wa, MonitorWorkArea
    osdX := Round(waLeft + (waRight - waLeft - osdW) / 2)
    osdY := Round(waBottom - osdH - 28 * scale)

    BrightnessOsdW := osdW
    BrightnessOsdH := osdH
    BrightnessOsdX := osdX
    BrightnessOsdY := osdY

    if (!RenderBrightnessOsdBitmap(osdW, osdH, scale, BrightnessPercent, BrightnessOsdDragging))
        return

    BrightnessOsdAlpha := 255
    PresentBrightnessOsdBitmap(255)
    DllCall("ShowWindow", "Ptr", hBrightnessOsdGui, "Int", 8) ; SW_SHOWNA
    ; Đưa OSD lên trên lớp phủ màn hình (HWND_TOPMOST = -1)
    DllCall("SetWindowPos", "Ptr", hBrightnessOsdGui, "Ptr", -1, "Int", osdX, "Int", osdY, "Int", osdW, "Int", osdH, "UInt", 0x0053)
    BrightnessOsdVisible := true

    if (!BrightnessOsdDragging)
        SetTimer, BrightnessOsdHoldTimer, -2000
}

RenderBrightnessOsdBitmap(w, h, scale, percent, isDragging) {
    global BrightnessOsdBitmap, BrightnessBarX, BrightnessBarW

    if (BrightnessOsdBitmap) {
        DllCall("DeleteObject", "Ptr", BrightnessOsdBitmap)
        BrightnessOsdBitmap := 0
    }

    pBitmap := 0, pGraphics := 0
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", w, "Int", h, "Int", 0, "Int", 0xE200B, "Ptr", 0, "Ptr*", pBitmap) ; PixelFormat32bppPARGB
    if (!pBitmap)
        return false

    DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBitmap, "Ptr*", pGraphics)
    if (!pGraphics) {
        DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
        return false
    }

    DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", 4)      ; SmoothingModeAntiAlias
    DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", pGraphics, "Int", 2)   ; PixelOffsetModeHalf
    DllCall("gdiplus\GdipSetTextRenderingHint", "Ptr", pGraphics, "Int", 4) ; TextRenderingHintAntiAliasGridFit
    DllCall("gdiplus\GdipGraphicsClear", "Ptr", pGraphics, "UInt", 0x00000000)

    ; Lấy màu nhấn (Accent Color) của Windows cho thanh trượt, mặc định xanh Win11 Dark (#60CDFF)
    accentColor := GetWindowsOsdAccentColor()

    ; Nền pill bo góc tối trung tính kiểu Windows 11 + viền mảnh
    radius := h / 2.0
    bgColor := 0xEB1F2124
    borderColor := isDragging ? 0x55FFFFFF : 0x28FFFFFF

    pPath := BrightnessCreateRoundedRectPath(1.0, 1.0, w - 2.0, h - 2.0, radius - 1.0)
    if (pPath) {
        pBgBrush := 0
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", bgColor, "Ptr*", pBgBrush)
        if (pBgBrush) {
            DllCall("gdiplus\GdipFillPath", "Ptr", pGraphics, "Ptr", pBgBrush, "Ptr", pPath)
            DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBgBrush)
        }
        pBorderPen := 0
        DllCall("gdiplus\GdipCreatePen1", "UInt", borderColor, "Float", 1.2 * scale, "Int", 2, "Ptr*", pBorderPen)
        if (pBorderPen) {
            DllCall("gdiplus\GdipDrawPath", "Ptr", pGraphics, "Ptr", pBorderPen, "Ptr", pPath)
            DllCall("gdiplus\GdipDeletePen", "Ptr", pBorderPen)
        }
        DllCall("gdiplus\GdipDeletePath", "Ptr", pPath)
    }

    ; Vòng tròn nền & Icon Mặt trời bên trái (tông trắng sáng chuẩn Win11)
    badgeSize := 25.0 * scale
    badgeX := 8.0 * scale
    badgeY := (h - badgeSize) / 2.0
    sunColor := (percent >= 35) ? 0xFFF3F4F6 : 0xFFA1A1AA

    pBadgeBrush := 0
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0x14FFFFFF, "Ptr*", pBadgeBrush)
    if (pBadgeBrush) {
        DllCall("gdiplus\GdipFillEllipse", "Ptr", pGraphics, "Ptr", pBadgeBrush, "Float", badgeX, "Float", badgeY, "Float", badgeSize, "Float", badgeSize)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBadgeBrush)
    }
    DrawSunVectorIcon(pGraphics, badgeX + badgeSize / 2.0, badgeY + badgeSize / 2.0, scale, sunColor, percent)

    ; Vùng hiển thị chữ % bên phải
    textW := 38.0 * scale
    textX := w - textW - 10.0 * scale

    ; Vùng thanh trượt độ sáng ở giữa
    barX := badgeX + badgeSize + 9.0 * scale
    barW := textX - barX - 8.0 * scale
    barH := 4.5 * scale
    barY := (h - barH) / 2.0

    ; Lưu tọa độ logic của thanh bar để phục vụ thao tác nhấn/kéo
    BrightnessBarX := barX
    BrightnessBarW := barW

    ; Track nền
    pTrackPath := BrightnessCreateRoundedRectPath(barX, barY, barW, barH, barH / 2.0)
    if (pTrackPath) {
        pTrackBrush := 0
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0x38FFFFFF, "Ptr*", pTrackBrush)
        if (pTrackBrush) {
            DllCall("gdiplus\GdipFillPath", "Ptr", pGraphics, "Ptr", pTrackBrush, "Ptr", pTrackPath)
            DllCall("gdiplus\GdipDeleteBrush", "Ptr", pTrackBrush)
        }
        DllCall("gdiplus\GdipDeletePath", "Ptr", pTrackPath)
    }

    ; Thanh Fill theo phần trăm
    ratio := percent / 100.0
    if (ratio < 0.0)
        ratio := 0.0
    if (ratio > 1.0)
        ratio := 1.0
    fillW := barW * ratio
    if (fillW < barH)
        fillW := barH

    pFillPath := BrightnessCreateRoundedRectPath(barX, barY, fillW, barH, barH / 2.0)
    if (pFillPath) {
        pFillBrush := 0
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", accentColor, "Ptr*", pFillBrush)
        if (pFillBrush) {
            DllCall("gdiplus\GdipFillPath", "Ptr", pGraphics, "Ptr", pFillBrush, "Ptr", pFillPath)
            DllCall("gdiplus\GdipDeleteBrush", "Ptr", pFillBrush)
        }
        DllCall("gdiplus\GdipDeletePath", "Ptr", pFillPath)
    }

    ; Núm kéo (Thumb) tại đầu thanh trượt
    knobR := (isDragging ? 5.6 : 4.6) * scale
    knobCx := barX + barW * ratio
    if (knobCx < barX + knobR)
        knobCx := barX + knobR
    if (knobCx > barX + barW - knobR)
        knobCx := barX + barW - knobR
    knobCy := h / 2.0

    pKnobBrush := 0
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0xFFFFFFFF, "Ptr*", pKnobBrush)
    if (pKnobBrush) {
        DllCall("gdiplus\GdipFillEllipse", "Ptr", pGraphics, "Ptr", pKnobBrush, "Float", knobCx - knobR, "Float", knobCy - knobR, "Float", knobR * 2.0, "Float", knobR * 2.0)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pKnobBrush)
    }
    pKnobPen := 0
    DllCall("gdiplus\GdipCreatePen1", "UInt", accentColor, "Float", 1.5 * scale, "Int", 2, "Ptr*", pKnobPen)
    if (pKnobPen) {
        DllCall("gdiplus\GdipDrawEllipse", "Ptr", pGraphics, "Ptr", pKnobPen, "Float", knobCx - knobR, "Float", knobCy - knobR, "Float", knobR * 2.0, "Float", knobR * 2.0)
        DllCall("gdiplus\GdipDeletePen", "Ptr", pKnobPen)
    }

    ; Chữ phần trăm bên phải
    DrawBrightnessOsdText(pGraphics, percent . "%", textX, 0.0, textW, h, 9.5 * scale, 1, 0xFFFFFFFF)

    hBitmap := 0
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", hBitmap, "UInt", 0x00000000)
    DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGraphics)
    DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)

    if (!hBitmap)
        return false

    BrightnessOsdBitmap := hBitmap
    return true
}

GetWindowsOsdAccentColor() {
    defaultAccent := 0xFF60CDFF ; Xanh dương chuẩn Windows 11 Dark Mode
    RegRead, raw, HKEY_CURRENT_USER\Software\Microsoft\Windows\DWM, AccentColor
    if (ErrorLevel || raw = "")
        return defaultAccent

    raw += 0
    ; DWM AccentColor lưu theo thứ tự byte ABGR
    r := raw & 0xFF
    g := (raw >> 8) & 0xFF
    b := (raw >> 16) & 0xFF

    ; Làm sáng nhẹ nếu màu gốc quá tối để nổi rõ trên nền tối
    luma := 0.299 * r + 0.587 * g + 0.114 * b
    if (luma < 140) {
        r := Round(r + (255 - r) * 0.35)
        g := Round(g + (255 - g) * 0.35)
        b := Round(b + (255 - b) * 0.35)
        if (r > 255)
            r := 255
        if (g > 255)
            g := 255
        if (b > 255)
            b := 255
    }
    return 0xFF000000 | (r << 16) | (g << 8) | b
}

BrightnessCreateRoundedRectPath(x, y, w, h, r) {
    maxR := (w < h ? w : h) / 2.0
    if (r > maxR)
        r := maxR
    pPath := 0
    DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pPath)
    if (!pPath)
        return 0
    d := r * 2.0
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", x, "Float", y, "Float", d, "Float", d, "Float", 180.0, "Float", 90.0)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", x + w - d, "Float", y, "Float", d, "Float", d, "Float", 270.0, "Float", 90.0)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", x + w - d, "Float", y + h - d, "Float", d, "Float", d, "Float", 0.0, "Float", 90.0)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", x, "Float", y + h - d, "Float", d, "Float", d, "Float", 90.0, "Float", 90.0)
    DllCall("gdiplus\GdipClosePathFigure", "Ptr", pPath)
    return pPath
}

DrawSunVectorIcon(pGraphics, cx, cy, scale, color, percent) {
    ; Tâm mặt trời
    coreR := 3.2 * scale
    pBrush := 0
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", color, "Ptr*", pBrush)
    if (pBrush) {
        DllCall("gdiplus\GdipFillEllipse", "Ptr", pGraphics, "Ptr", pBrush, "Float", cx - coreR, "Float", cy - coreR, "Float", coreR * 2.0, "Float", coreR * 2.0)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrush)
    }

    ; 8 tia sáng xung quanh (độ dài tia thay đổi nhẹ theo độ sáng)
    rayInner := 4.8 * scale
    rayOuter := (6.0 + (percent / 100.0) * 1.2) * scale
    pPen := 0
    DllCall("gdiplus\GdipCreatePen1", "UInt", color, "Float", 1.4 * scale, "Int", 2, "Ptr*", pPen)
    if (pPen) {
        DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pPen, "Int", 2)
        DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pPen, "Int", 2)
        pi := 3.141592653589793
        Loop, 8 {
            angle := (A_Index - 1) * (pi / 4.0)
            x1 := cx + Cos(angle) * rayInner
            y1 := cy + Sin(angle) * rayInner
            x2 := cx + Cos(angle) * rayOuter
            y2 := cy + Sin(angle) * rayOuter
            DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPen, "Float", x1, "Float", y1, "Float", x2, "Float", y2)
        }
        DllCall("gdiplus\GdipDeletePen", "Ptr", pPen)
    }
}

DrawBrightnessOsdText(pGraphics, text, x, y, w, h, fontSize, isBold, color) {
    pFamily := 0, pFont := 0, pFormat := 0, pBrush := 0
    DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", "Segoe UI", "Ptr", 0, "Ptr*", pFamily)
    if (!pFamily)
        return
    DllCall("gdiplus\GdipCreateFont", "Ptr", pFamily, "Float", fontSize, "Int", isBold ? 1 : 0, "Int", 3, "Ptr*", pFont)
    DllCall("gdiplus\GdipCreateStringFormat", "Int", 0x1000, "UShort", 0, "Ptr*", pFormat)
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", color, "Ptr*", pBrush)

    if (pFont && pFormat && pBrush) {
        DllCall("gdiplus\GdipSetStringFormatAlign", "Ptr", pFormat, "Int", 2)     ; Far (Right)
        DllCall("gdiplus\GdipSetStringFormatLineAlign", "Ptr", pFormat, "Int", 1) ; Center
        VarSetCapacity(rectF, 16, 0)
        NumPut(x, rectF, 0, "Float"), NumPut(y, rectF, 4, "Float")
        NumPut(w, rectF, 8, "Float"), NumPut(h, rectF, 12, "Float")
        DllCall("gdiplus\GdipDrawString", "Ptr", pGraphics, "WStr", text, "Int", -1, "Ptr", pFont, "Ptr", &rectF, "Ptr", pFormat, "Ptr", pBrush)
    }

    if (pBrush)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrush)
    if (pFormat)
        DllCall("gdiplus\GdipDeleteStringFormat", "Ptr", pFormat)
    if (pFont)
        DllCall("gdiplus\GdipDeleteFont", "Ptr", pFont)
    DllCall("gdiplus\GdipDeleteFontFamily", "Ptr", pFamily)
}

PresentBrightnessOsdBitmap(alpha) {
    global hBrightnessOsdGui, BrightnessOsdBitmap, BrightnessOsdW, BrightnessOsdH, BrightnessOsdX, BrightnessOsdY
    if (!hBrightnessOsdGui || !BrightnessOsdBitmap)
        return

    hdcScreen := DllCall("GetDC", "Ptr", 0, "Ptr")
    hdcMem := DllCall("CreateCompatibleDC", "Ptr", hdcScreen, "Ptr")
    oldBmp := DllCall("SelectObject", "Ptr", hdcMem, "Ptr", BrightnessOsdBitmap, "Ptr")

    VarSetCapacity(ptDst, 8, 0), NumPut(BrightnessOsdX, ptDst, 0, "Int"), NumPut(BrightnessOsdY, ptDst, 4, "Int")
    VarSetCapacity(sz, 8, 0), NumPut(BrightnessOsdW, sz, 0, "Int"), NumPut(BrightnessOsdH, sz, 4, "Int")
    VarSetCapacity(ptSrc, 8, 0)
    VarSetCapacity(blend, 4, 0)
    NumPut(0, blend, 0, "UChar")
    NumPut(0, blend, 1, "UChar")
    NumPut(alpha, blend, 2, "UChar")
    NumPut(1, blend, 3, "UChar") ; AC_SRC_ALPHA

    DllCall("UpdateLayeredWindow", "Ptr", hBrightnessOsdGui, "Ptr", hdcScreen, "Ptr", &ptDst, "Ptr", &sz, "Ptr", hdcMem, "Ptr", &ptSrc, "UInt", 0, "Ptr", &blend, "UInt", 2)

    DllCall("SelectObject", "Ptr", hdcMem, "Ptr", oldBmp)
    DllCall("DeleteDC", "Ptr", hdcMem)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcScreen)
}

; ========================================================
; TƯƠNG TÁC KÉO & CUỘN CHUỘT TRỰC TIẾP TRÊN OSD
; ========================================================
OnBrightnessOsdLButtonDown(wParam, lParam, msg, hWnd) {
    global hBrightnessOsdGui, BrightnessOsdDragging, BrightnessOsdAlpha
    if (hWnd != hBrightnessOsdGui)
        return

    BrightnessOsdDragging := true
    BrightnessOsdAlpha := 255
    SetTimer, BrightnessOsdHoldTimer, Off
    SetTimer, BrightnessOsdFadeTimer, Off

    UpdateBrightnessFromCursor(true)
    SetTimer, BrightnessOsdDragTimer, 16
    return 0
}

OnBrightnessOsdMouseWheel(wParam, lParam, msg, hWnd) {
    global hBrightnessOsdGui, BrightnessPercent
    if (hWnd != hBrightnessOsdGui)
        return

    delta := (wParam >> 16) & 0xFFFF
    if (delta >= 0x8000)
        delta -= 0x10000
    step := (delta > 0) ? 5 : -5
    SetBrightnessPercent(BrightnessPercent + step)
    return 0
}

BrightnessOsdDragTimer:
    if (!GetKeyState("LButton", "P")) {
        BrightnessOsdDragging := false
        SetTimer, BrightnessOsdDragTimer, Off
        ShowBrightnessOsd()
        return
    }
    UpdateBrightnessFromCursor(false)
return

UpdateBrightnessFromCursor(forceRedraw := false) {
    global BrightnessOsdX, BrightnessBarX, BrightnessBarW, BrightnessPercent
    if (BrightnessBarW <= 0)
        return

    VarSetCapacity(pt, 8, 0)
    DllCall("GetCursorPos", "Ptr", &pt)
    curX := NumGet(pt, 0, "Int")

    rel := (curX - (BrightnessOsdX + BrightnessBarX)) / BrightnessBarW
    if (rel < 0.0)
        rel := 0.0
    if (rel > 1.0)
        rel := 1.0

    newPercent := Round(rel * 100)
    if (newPercent < 5)
        newPercent := 5
    if (newPercent > 100)
        newPercent := 100

    if (forceRedraw || newPercent != BrightnessPercent)
        SetBrightnessPercent(newPercent, true)
}

; ========================================================
; TIMER ẨN MƯỢT & DỌN DẸP TÀI NGUYÊN
; ========================================================
BrightnessOsdHoldTimer:
    SetTimer, BrightnessOsdFadeTimer, 16
return

BrightnessOsdFadeTimer:
    if (BrightnessOsdDragging) {
        SetTimer, BrightnessOsdFadeTimer, Off
        return
    }
    BrightnessOsdAlpha -= 24
    if (BrightnessOsdAlpha <= 0) {
        BrightnessOsdAlpha := 0
        SetTimer, BrightnessOsdFadeTimer, Off
        HideBrightnessOsd()
    } else {
        PresentBrightnessOsdBitmap(BrightnessOsdAlpha)
    }
return

HideBrightnessOsd() {
    global hBrightnessOsdGui, BrightnessOsdVisible, BrightnessOsdBitmap
    SetTimer, BrightnessOsdHoldTimer, Off
    SetTimer, BrightnessOsdFadeTimer, Off
    if (hBrightnessOsdGui && BrightnessOsdVisible) {
        DllCall("ShowWindow", "Ptr", hBrightnessOsdGui, "Int", 0) ; SW_HIDE
        BrightnessOsdVisible := false
    }
    if (BrightnessOsdBitmap) {
        DllCall("DeleteObject", "Ptr", BrightnessOsdBitmap)
        BrightnessOsdBitmap := 0
    }
}

CleanupBrightnessOsd() {
    global hBrightnessOsdGui, BrightnessOsdBitmap, BrightnessGdipToken, BrightnessGdipModule
    SetTimer, BrightnessOsdDragTimer, Off
    HideBrightnessOsd()
    if (hBrightnessOsdGui) {
        try Gui, BrightnessOsd:Destroy
        hBrightnessOsdGui := 0
    }
    if (BrightnessOsdBitmap) {
        DllCall("DeleteObject", "Ptr", BrightnessOsdBitmap)
        BrightnessOsdBitmap := 0
    }
    if (BrightnessGdipToken) {
        DllCall("gdiplus\GdiplusShutdown", "Ptr", BrightnessGdipToken)
        BrightnessGdipToken := 0
    }
    if (BrightnessGdipModule) {
        DllCall("FreeLibrary", "Ptr", BrightnessGdipModule)
        BrightnessGdipModule := 0
    }
}
