; SettingsIcons.ahk - Khởi tạo icon vector GDI+ & bitmap sắc nét cho giao diện Cài đặt
#NoEnv

GdipBeginSession(ByRef hGdip, ByRef pToken) {
    hGdip := DllCall("LoadLibrary", "Str", "gdiplus", "Ptr")
    if (!hGdip)
        return false

    VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0)
    NumPut(1, si, 0, "UInt")
    pToken := 0
    if (DllCall("gdiplus\GdiplusStartup", "Ptr*", pToken, "Ptr", &si, "Ptr", 0) != 0) {
        DllCall("FreeLibrary", "Ptr", hGdip)
        hGdip := 0
        return false
    }
    return true
}

GdipEndSession(hGdip, pToken) {
    if (pToken)
        DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
    if (hGdip)
        DllCall("FreeLibrary", "Ptr", hGdip)
}

GdipCreateCanvas(pixW, pixH, bgArgb, ByRef pBitmap, ByRef pGraphics) {
    pBitmap := 0, pGraphics := 0
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", pixW, "Int", pixH, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", pBitmap)
    DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBitmap, "Ptr*", pGraphics)
    DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", 4)
    DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", pGraphics, "Int", 2)
    DllCall("gdiplus\GdipGraphicsClear", "Ptr", pGraphics, "UInt", bgArgb)
}

GdipReleaseCanvas(pBitmap, pGraphics) {
    if (pGraphics)
        DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGraphics)
    if (pBitmap)
        DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
}

GetSysWinArgb() {
    bgr := DllCall("GetSysColor", "Int", 15, "UInt")
    return 0xFF000000 | ((bgr & 0xFF) << 16) | (bgr & 0xFF00) | ((bgr >> 16) & 0xFF)
}

EnsureSettingsVectorIcons() {
    global SidebarNavBitmaps, LockTabIcons, GestureBadgeBitmaps, ChevronBitmaps
    needSidebar := !SidebarNavBitmaps.HasKey(1)
    needLock := !LockTabIcons.HasKey("idle")
    needBadges := !GestureBadgeBitmaps.HasKey("L")
    needChevron := !IsObject(ChevronBitmaps) || !ChevronBitmaps.HasKey("down")
    if (!needSidebar && !needLock && !needBadges && !needChevron)
        return

    if (!GdipBeginSession(hGdip, pToken))
        return

    if (needSidebar)
        SidebarNavBitmaps := CreateSidebarNavBitmaps(20, false)
    if (needLock)
        LockTabIcons := CreateLockTabIcons(false)
    if (needBadges)
        GestureBadgeBitmaps := CreateGestureBadgeBitmaps(32, 22, false)
    if (needChevron)
        ChevronBitmaps := CreateChevronBitmaps(16, 0xFFFBFBFB, false)

    GdipEndSession(hGdip, pToken)
}

CreateSidebarNavBitmaps(iconSize := 20, manageSession := true) {
    result := {}
    if (manageSession && !GdipBeginSession(hGdip, pToken))
        return result

    scale := A_ScreenDPI / 96.0
    pix := Round(iconSize * scale)

    argbInactiveBg := 0xFFF3F3F3
    argbActiveBg := 0xFFE5F1FB
    argbActiveFg := 0xFF005FB8
    argbNormFg := 0xFF4A5568

    Loop, 5 {
        idx := A_Index
        result[idx] := {}
        for stateIdx, stateName in ["inactive", "active"] {
            bgCol := (stateName = "active") ? argbActiveBg : argbInactiveBg
            fgCol := (stateName = "active") ? argbActiveFg : argbNormFg

            GdipCreateCanvas(pix, pix, bgCol, pBitmap, pGraphics)
            DrawSidebarVectorIcon(pGraphics, idx, fgCol, bgCol, scale)

            hBmp := 0
            DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", hBmp, "UInt", bgCol)
            result[idx][stateName] := hBmp
            GdipReleaseCanvas(pBitmap, pGraphics)
        }
    }

    if (manageSession)
        GdipEndSession(hGdip, pToken)
    return result
}

DrawSidebarVectorIcon(pGraphics, idx, fgCol, bgCol, scale) {
    DllCall("gdiplus\GdipCreatePen1", "UInt", fgCol, "Float", 1.7 * scale, "Int", 2, "Ptr*", pPen)
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", fgCol, "Ptr*", pBrush)
    DllCall("gdiplus\GdipSetPenLineJoin", "Ptr", pPen, "Int", 2)

    if (idx == 1) {
        ; Cài đặt chung: bánh răng sắc nét 8 răng
        DllCall("gdiplus\GdipCreatePen1", "UInt", fgCol, "Float", 2.2 * scale, "Int", 2, "Ptr*", pPenTooth)
        Loop, 8 {
            ang := (A_Index - 1) * 45.0 * 0.01745329252
            x1 := (10.0 + 5.2 * Cos(ang)) * scale
            y1 := (10.0 + 5.2 * Sin(ang)) * scale
            x2 := (10.0 + 8.3 * Cos(ang)) * scale
            y2 := (10.0 + 8.3 * Sin(ang)) * scale
            DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPenTooth, "Float", x1, "Float", y1, "Float", x2, "Float", y2)
        }
        DllCall("gdiplus\GdipDeletePen", "Ptr", pPenTooth)
        DllCall("gdiplus\GdipCreatePen1", "UInt", fgCol, "Float", 2.1 * scale, "Int", 2, "Ptr*", pPenRing)
        DllCall("gdiplus\GdipDrawEllipse", "Ptr", pGraphics, "Ptr", pPenRing, "Float", 4.9 * scale, "Float", 4.9 * scale, "Float", 10.2 * scale, "Float", 10.2 * scale)
        DllCall("gdiplus\GdipDeletePen", "Ptr", pPenRing)
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", bgCol, "Ptr*", pBrushHole)
        DllCall("gdiplus\GdipFillEllipse", "Ptr", pGraphics, "Ptr", pBrushHole, "Float", 7.3 * scale, "Float", 7.3 * scale, "Float", 5.4 * scale, "Float", 5.4 * scale)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrushHole)
        DllCall("gdiplus\GdipDrawEllipse", "Ptr", pGraphics, "Ptr", pPen, "Float", 7.5 * scale, "Float", 7.5 * scale, "Float", 5.0 * scale, "Float", 5.0 * scale)
    } else if (idx == 2) {
        ; Cuộn & Cử chỉ: chuột hiện đại với con lăn
        DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pPath)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", 5.0 * scale, "Float", 2.0 * scale, "Float", 10.0 * scale, "Float", 10.0 * scale, "Float", 180.0, "Float", 180.0)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", 5.0 * scale, "Float", 8.0 * scale, "Float", 10.0 * scale, "Float", 10.0 * scale, "Float", 0.0, "Float", 180.0)
        DllCall("gdiplus\GdipClosePathFigure", "Ptr", pPath)
        DllCall("gdiplus\GdipDrawPath", "Ptr", pGraphics, "Ptr", pPen, "Ptr", pPath)
        DllCall("gdiplus\GdipDeletePath", "Ptr", pPath)

        DllCall("gdiplus\GdipCreatePen1", "UInt", fgCol, "Float", 1.3 * scale, "Int", 2, "Ptr*", pPenThin)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPenThin, "Float", 5.2 * scale, "Float", 8.5 * scale, "Float", 14.8 * scale, "Float", 8.5 * scale)
        DllCall("gdiplus\GdipDeletePen", "Ptr", pPenThin)

        DllCall("gdiplus\GdipCreatePen1", "UInt", fgCol, "Float", 2.2 * scale, "Int", 2, "Ptr*", pPenWheel)
        DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pPenWheel, "Int", 2)
        DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pPenWheel, "Int", 2)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPenWheel, "Float", 10.0 * scale, "Float", 4.4 * scale, "Float", 10.0 * scale, "Float", 7.0 * scale)
        DllCall("gdiplus\GdipDeletePen", "Ptr", pPenWheel)
    } else if (idx == 3) {
        ; Khóa: ổ khóa rõ nét
        DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pShackle)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pShackle, "Float", 6.8 * scale, "Float", 2.4 * scale, "Float", 6.4 * scale, "Float", 6.4 * scale, "Float", 180.0, "Float", 180.0)
        DllCall("gdiplus\GdipDrawPath", "Ptr", pGraphics, "Ptr", pPen, "Ptr", pShackle)
        DllCall("gdiplus\GdipDeletePath", "Ptr", pShackle)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPen, "Float", 6.8 * scale, "Float", 5.6 * scale, "Float", 6.8 * scale, "Float", 8.5 * scale)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPen, "Float", 13.2 * scale, "Float", 5.6 * scale, "Float", 13.2 * scale, "Float", 8.5 * scale)

        DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pBody)
        d := 3.6 * scale
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pBody, "Float", 4.5 * scale, "Float", 8.5 * scale, "Float", d, "Float", d, "Float", 180.0, "Float", 90.0)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pBody, "Float", 15.5 * scale - d, "Float", 8.5 * scale, "Float", d, "Float", d, "Float", 270.0, "Float", 90.0)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pBody, "Float", 15.5 * scale - d, "Float", 17.5 * scale - d, "Float", d, "Float", d, "Float", 0.0, "Float", 90.0)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pBody, "Float", 4.5 * scale, "Float", 17.5 * scale - d, "Float", d, "Float", d, "Float", 90.0, "Float", 90.0)
        DllCall("gdiplus\GdipClosePathFigure", "Ptr", pBody)
        DllCall("gdiplus\GdipDrawPath", "Ptr", pGraphics, "Ptr", pPen, "Ptr", pBody)
        DllCall("gdiplus\GdipDeletePath", "Ptr", pBody)

        DllCall("gdiplus\GdipFillEllipse", "Ptr", pGraphics, "Ptr", pBrush, "Float", 8.9 * scale, "Float", 11.1 * scale, "Float", 2.2 * scale, "Float", 2.2 * scale)
        DllCall("gdiplus\GdipCreatePen1", "UInt", fgCol, "Float", 1.8 * scale, "Int", 2, "Ptr*", pPenSlot)
        DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pPenSlot, "Int", 2)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPenSlot, "Float", 10.0 * scale, "Float", 12.2 * scale, "Float", 10.0 * scale, "Float", 14.9 * scale)
        DllCall("gdiplus\GdipDeletePen", "Ptr", pPenSlot)
    } else if (idx == 4) {
        ; Phím tắt: bàn phím gọn rõ nét
        DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pKb)
        d := 3.6 * scale
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pKb, "Float", 2.0 * scale, "Float", 4.8 * scale, "Float", d, "Float", d, "Float", 180.0, "Float", 90.0)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pKb, "Float", 18.0 * scale - d, "Float", 4.8 * scale, "Float", d, "Float", d, "Float", 270.0, "Float", 90.0)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pKb, "Float", 18.0 * scale - d, "Float", 15.2 * scale - d, "Float", d, "Float", d, "Float", 0.0, "Float", 90.0)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pKb, "Float", 2.0 * scale, "Float", 15.2 * scale - d, "Float", d, "Float", d, "Float", 90.0, "Float", 90.0)
        DllCall("gdiplus\GdipClosePathFigure", "Ptr", pKb)
        DllCall("gdiplus\GdipDrawPath", "Ptr", pGraphics, "Ptr", pPen, "Ptr", pKb)
        DllCall("gdiplus\GdipDeletePath", "Ptr", pKb)

        Loop, 4 {
            kx := (4.4 + (A_Index - 1) * 3.1) * scale
            DllCall("gdiplus\GdipFillRectangle", "Ptr", pGraphics, "Ptr", pBrush, "Float", kx, "Float", 7.3 * scale, "Float", 1.9 * scale, "Float", 1.7 * scale)
            DllCall("gdiplus\GdipFillRectangle", "Ptr", pGraphics, "Ptr", pBrush, "Float", kx, "Float", 9.9 * scale, "Float", 1.9 * scale, "Float", 1.7 * scale)
        }
        DllCall("gdiplus\GdipFillRectangle", "Ptr", pGraphics, "Ptr", pBrush, "Float", 5.8 * scale, "Float", 12.5 * scale, "Float", 8.4 * scale, "Float", 1.6 * scale)
    } else if (idx == 5) {
        ; Thông tin: vòng tròn chữ i
        DllCall("gdiplus\GdipDrawEllipse", "Ptr", pGraphics, "Ptr", pPen, "Float", 2.5 * scale, "Float", 2.5 * scale, "Float", 15.0 * scale, "Float", 15.0 * scale)
        DllCall("gdiplus\GdipFillEllipse", "Ptr", pGraphics, "Ptr", pBrush, "Float", 8.85 * scale, "Float", 5.5 * scale, "Float", 2.3 * scale, "Float", 2.3 * scale)
        DllCall("gdiplus\GdipCreatePen1", "UInt", fgCol, "Float", 2.1 * scale, "Int", 2, "Ptr*", pPenI)
        DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pPenI, "Int", 2)
        DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pPenI, "Int", 2)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPenI, "Float", 10.0 * scale, "Float", 9.2 * scale, "Float", 10.0 * scale, "Float", 14.3 * scale)
        DllCall("gdiplus\GdipDeletePen", "Ptr", pPenI)
    }

    DllCall("gdiplus\GdipDeletePen", "Ptr", pPen)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrush)
}

CreateLockTabIcons(manageSession := true) {
    result := {}
    if (manageSession && !GdipBeginSession(hGdip, pToken))
        return result

    scale := A_ScreenDPI / 96.0
    specs := {idle: 20, toast: 20, winlock: 20, key: 20, eye_show: 18, eye_hide: 18}

    for iconKey, logicalSize in specs {
        pix := Round(logicalSize * scale)
        GdipCreateCanvas(pix, pix, 0x00000000, pBitmap, pGraphics)
        DrawLockTabVectorIcon(pGraphics, iconKey, scale)

        hIcon := 0
        DllCall("gdiplus\GdipCreateHICONFromBitmap", "Ptr", pBitmap, "Ptr*", hIcon)
        if (hIcon)
            result[iconKey] := hIcon
        GdipReleaseCanvas(pBitmap, pGraphics)
    }

    if (manageSession)
        GdipEndSession(hGdip, pToken)
    return result
}

DrawLockTabVectorIcon(pGraphics, iconKey, scale) {
    fgBlue := 0xFF005FB8
    bgSoft := 0xFFE5F1FB
    fgDark := 0xFF222222

    if (iconKey = "idle") {
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", bgSoft, "Ptr*", pFill)
        DllCall("gdiplus\GdipCreatePen1", "UInt", fgBlue, "Float", 1.7 * scale, "Int", 2, "Ptr*", pPen)
        DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pPen, "Int", 2)
        DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pPen, "Int", 2)
        DllCall("gdiplus\GdipSetPenLineJoin", "Ptr", pPen, "Int", 2)

        DllCall("gdiplus\GdipFillEllipse", "Ptr", pGraphics, "Ptr", pFill, "Float", 3.0 * scale, "Float", 4.2 * scale, "Float", 14.0 * scale, "Float", 14.0 * scale)
        DllCall("gdiplus\GdipDrawEllipse", "Ptr", pGraphics, "Ptr", pPen, "Float", 3.0 * scale, "Float", 4.2 * scale, "Float", 14.0 * scale, "Float", 14.0 * scale)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPen, "Float", 8.0 * scale, "Float", 1.8 * scale, "Float", 12.0 * scale, "Float", 1.8 * scale)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPen, "Float", 10.0 * scale, "Float", 1.8 * scale, "Float", 10.0 * scale, "Float", 4.2 * scale)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPen, "Float", 10.0 * scale, "Float", 7.0 * scale, "Float", 10.0 * scale, "Float", 11.2 * scale)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPen, "Float", 10.0 * scale, "Float", 11.2 * scale, "Float", 13.3 * scale, "Float", 12.8 * scale)

        DllCall("gdiplus\GdipDeletePen", "Ptr", pPen)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pFill)
    } else if (iconKey = "toast") {
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", bgSoft, "Ptr*", pFill)
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", fgBlue, "Ptr*", pBrush)
        DllCall("gdiplus\GdipCreatePen1", "UInt", fgBlue, "Float", 1.6 * scale, "Int", 2, "Ptr*", pPen)
        DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pPen, "Int", 2)
        DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pPen, "Int", 2)
        DllCall("gdiplus\GdipSetPenLineJoin", "Ptr", pPen, "Int", 2)

        DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pPath)
        DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", 5.2 * scale, "Float", 3.6 * scale, "Float", 9.6 * scale, "Float", 9.2 * scale, "Float", 180.0, "Float", 180.0)
        DllCall("gdiplus\GdipAddPathLine", "Ptr", pPath, "Float", 14.8 * scale, "Float", 8.2 * scale, "Float", 16.5 * scale, "Float", 14.2 * scale)
        DllCall("gdiplus\GdipAddPathLine", "Ptr", pPath, "Float", 16.5 * scale, "Float", 14.2 * scale, "Float", 3.5 * scale, "Float", 14.2 * scale)
        DllCall("gdiplus\GdipAddPathLine", "Ptr", pPath, "Float", 3.5 * scale, "Float", 14.2 * scale, "Float", 5.2 * scale, "Float", 8.2 * scale)
        DllCall("gdiplus\GdipClosePathFigure", "Ptr", pPath)
        DllCall("gdiplus\GdipFillPath", "Ptr", pGraphics, "Ptr", pFill, "Ptr", pPath)
        DllCall("gdiplus\GdipDrawPath", "Ptr", pGraphics, "Ptr", pPen, "Ptr", pPath)
        DllCall("gdiplus\GdipDeletePath", "Ptr", pPath)

        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPen, "Float", 10.0 * scale, "Float", 2.0 * scale, "Float", 10.0 * scale, "Float", 3.6 * scale)
        DllCall("gdiplus\GdipFillEllipse", "Ptr", pGraphics, "Ptr", pBrush, "Float", 8.4 * scale, "Float", 15.0 * scale, "Float", 3.2 * scale, "Float", 3.0 * scale)

        DllCall("gdiplus\GdipDeletePen", "Ptr", pPen)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrush)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pFill)
    } else if (iconKey = "winlock") {
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0xFF0067C0, "Ptr*", pBrush)
        DllCall("gdiplus\GdipFillRectangle", "Ptr", pGraphics, "Ptr", pBrush, "Float", 3.0 * scale, "Float", 3.0 * scale, "Float", 6.2 * scale, "Float", 6.2 * scale)
        DllCall("gdiplus\GdipFillRectangle", "Ptr", pGraphics, "Ptr", pBrush, "Float", 10.8 * scale, "Float", 3.0 * scale, "Float", 6.2 * scale, "Float", 6.2 * scale)
        DllCall("gdiplus\GdipFillRectangle", "Ptr", pGraphics, "Ptr", pBrush, "Float", 3.0 * scale, "Float", 10.8 * scale, "Float", 6.2 * scale, "Float", 6.2 * scale)
        DllCall("gdiplus\GdipFillRectangle", "Ptr", pGraphics, "Ptr", pBrush, "Float", 10.8 * scale, "Float", 10.8 * scale, "Float", 6.2 * scale, "Float", 6.2 * scale)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrush)
    } else if (iconKey = "key") {
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", bgSoft, "Ptr*", pFill)
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", fgBlue, "Ptr*", pBrush)
        DllCall("gdiplus\GdipCreatePen1", "UInt", fgBlue, "Float", 1.7 * scale, "Int", 2, "Ptr*", pPen)
        DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pPen, "Int", 2)
        DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pPen, "Int", 2)

        DllCall("gdiplus\GdipFillEllipse", "Ptr", pGraphics, "Ptr", pFill, "Float", 2.2 * scale, "Float", 6.0 * scale, "Float", 7.6 * scale, "Float", 7.6 * scale)
        DllCall("gdiplus\GdipDrawEllipse", "Ptr", pGraphics, "Ptr", pPen, "Float", 2.2 * scale, "Float", 6.0 * scale, "Float", 7.6 * scale, "Float", 7.6 * scale)
        DllCall("gdiplus\GdipFillEllipse", "Ptr", pGraphics, "Ptr", pBrush, "Float", 4.9 * scale, "Float", 8.7 * scale, "Float", 2.2 * scale, "Float", 2.2 * scale)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPen, "Float", 9.8 * scale, "Float", 9.8 * scale, "Float", 17.6 * scale, "Float", 9.8 * scale)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPen, "Float", 14.3 * scale, "Float", 9.8 * scale, "Float", 14.3 * scale, "Float", 13.4 * scale)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPen, "Float", 17.1 * scale, "Float", 9.8 * scale, "Float", 17.1 * scale, "Float", 12.4 * scale)

        DllCall("gdiplus\GdipDeletePen", "Ptr", pPen)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrush)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pFill)
    } else if (iconKey = "eye_show" || iconKey = "eye_hide") {
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", fgDark, "Ptr*", pBrush)
        DllCall("gdiplus\GdipCreatePen1", "UInt", fgDark, "Float", 1.5 * scale, "Int", 2, "Ptr*", pPen)
        DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pPen, "Int", 2)
        DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pPen, "Int", 2)
        DllCall("gdiplus\GdipSetPenLineJoin", "Ptr", pPen, "Int", 2)

        DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pEye)
        DllCall("gdiplus\GdipAddPathBezier", "Ptr", pEye, "Float", 1.6 * scale, "Float", 9.0 * scale, "Float", 5.2 * scale, "Float", 3.6 * scale, "Float", 12.8 * scale, "Float", 3.6 * scale, "Float", 16.4 * scale, "Float", 9.0 * scale)
        DllCall("gdiplus\GdipAddPathBezier", "Ptr", pEye, "Float", 16.4 * scale, "Float", 9.0 * scale, "Float", 12.8 * scale, "Float", 14.4 * scale, "Float", 5.2 * scale, "Float", 14.4 * scale, "Float", 1.6 * scale, "Float", 9.0 * scale)
        DllCall("gdiplus\GdipClosePathFigure", "Ptr", pEye)
        DllCall("gdiplus\GdipDrawPath", "Ptr", pGraphics, "Ptr", pPen, "Ptr", pEye)
        DllCall("gdiplus\GdipDeletePath", "Ptr", pEye)

        DllCall("gdiplus\GdipFillEllipse", "Ptr", pGraphics, "Ptr", pBrush, "Float", 6.6 * scale, "Float", 6.6 * scale, "Float", 4.8 * scale, "Float", 4.8 * scale)

        if (iconKey = "eye_hide") {
            DllCall("gdiplus\GdipSetCompositingMode", "Ptr", pGraphics, "Int", 1)
            DllCall("gdiplus\GdipCreatePen1", "UInt", 0x00000000, "Float", 3.2 * scale, "Int", 2, "Ptr*", pPenCut)
            DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPenCut, "Float", 2.8 * scale, "Float", 15.2 * scale, "Float", 15.2 * scale, "Float", 2.8 * scale)
            DllCall("gdiplus\GdipDeletePen", "Ptr", pPenCut)
            DllCall("gdiplus\GdipSetCompositingMode", "Ptr", pGraphics, "Int", 0)
            DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPen, "Float", 2.8 * scale, "Float", 15.2 * scale, "Float", 15.2 * scale, "Float", 2.8 * scale)
        }

        DllCall("gdiplus\GdipDeletePen", "Ptr", pPen)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrush)
    }
}

CreateAboutHeroIconBitmap(iconSize := 56, bgRgb := 0xEEF5FC) {
    scale := A_ScreenDPI / 96.0
    pix := Round(iconSize * scale)

    hIcon := 0
    if (A_IsCompiled) {
        hMod := DllCall("GetModuleHandle", "Ptr", 0, "Ptr")
        hIcon := DllCall("LoadImage", "Ptr", hMod, "UInt", 159, "UInt", 1, "Int", pix, "Int", pix, "UInt", 0, "Ptr")
        if (!hIcon)
            DllCall("Shell32\ExtractIconEx", "Str", A_ScriptFullPath, "Int", 0, "Ptr*", hIcon, "Ptr", 0, "UInt", 1)
    } else {
        icoPath := A_ScriptDir . "\image\unnamed.ico"
        if (FileExist(icoPath))
            hIcon := DllCall("LoadImage", "Ptr", 0, "Str", icoPath, "UInt", 1, "Int", pix, "Int", pix, "UInt", 0x10, "Ptr")
    }
    if (!hIcon)
        return 0

    hdcScreen := DllCall("GetDC", "Ptr", 0, "Ptr")
    hdcMem := DllCall("CreateCompatibleDC", "Ptr", hdcScreen, "Ptr")
    hBmp := DllCall("CreateCompatibleBitmap", "Ptr", hdcScreen, "Int", pix, "Int", pix, "Ptr")
    hOld := DllCall("SelectObject", "Ptr", hdcMem, "Ptr", hBmp, "Ptr")

    bgr := ((bgRgb & 0xFF) << 16) | (bgRgb & 0xFF00) | ((bgRgb >> 16) & 0xFF)
    hBrush := DllCall("CreateSolidBrush", "UInt", bgr, "Ptr")
    VarSetCapacity(rc, 16, 0)
    NumPut(pix, rc, 8, "Int")
    NumPut(pix, rc, 12, "Int")
    DllCall("FillRect", "Ptr", hdcMem, "Ptr", &rc, "Ptr", hBrush)
    DllCall("DeleteObject", "Ptr", hBrush)

    DllCall("DrawIconEx", "Ptr", hdcMem, "Int", 0, "Int", 0, "Ptr", hIcon, "Int", pix, "Int", pix, "UInt", 0, "Ptr", 0, "UInt", 0x3)

    DllCall("SelectObject", "Ptr", hdcMem, "Ptr", hOld, "Ptr")
    DllCall("DeleteDC", "Ptr", hdcMem)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcScreen)
    DllCall("DestroyIcon", "Ptr", hIcon)
    return hBmp
}

CreateGestureBadgeBitmaps(badgeW := 32, badgeH := 22, manageSession := true) {
    result := {}
    if (manageSession && !GdipBeginSession(hGdip, pToken))
        return result

    scale := A_ScreenDPI / 96.0
    pixW := Round(badgeW * scale)
    pixH := Round(badgeH * scale)
    argbWin := GetSysWinArgb()

    DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", pPath)
    d := 8.0 * scale
    pad := 0.5 * scale
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", pad, "Float", pad, "Float", d, "Float", d, "Float", 180.0, "Float", 90.0)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", pixW - 1.0 * scale - d, "Float", pad, "Float", d, "Float", d, "Float", 270.0, "Float", 90.0)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", pixW - 1.0 * scale - d, "Float", pixH - 1.0 * scale - d, "Float", d, "Float", d, "Float", 0.0, "Float", 90.0)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", pad, "Float", pixH - 1.0 * scale - d, "Float", d, "Float", d, "Float", 90.0, "Float", 90.0)
    DllCall("gdiplus\GdipClosePathFigure", "Ptr", pPath)

    DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0xFFEBF3FB, "Ptr*", pBrushBg)
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0xFF005FB8, "Ptr*", pBrushArrow)
    DllCall("gdiplus\GdipCreatePen1", "UInt", 0xFFBDD6F0, "Float", 1.0 * scale, "Int", 2, "Ptr*", pPenBorder)
    DllCall("gdiplus\GdipCreatePen1", "UInt", 0xFF005FB8, "Float", 2.0 * scale, "Int", 2, "Ptr*", pPenArrow)
    DllCall("gdiplus\GdipSetPenLineJoin", "Ptr", pPenArrow, "Int", 2)
    DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pPenArrow, "Int", 2)
    DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pPenArrow, "Int", 0)

    shapes := {}
    shapes["L"]  := {shaft: [24.0, 11.0, 11.5, 11.0],               head: [ 7.0, 11.0, 13.0,  6.5, 13.0, 15.5]}
    shapes["R"]  := {shaft: [ 8.0, 11.0, 20.5, 11.0],               head: [25.0, 11.0, 19.0,  6.5, 19.0, 15.5]}
    shapes["LU"] := {shaft: [23.0, 16.5, 11.5, 16.5, 11.5,  8.5],   head: [11.5,  4.5,  7.0, 10.0, 16.0, 10.0]}
    shapes["LD"] := {shaft: [23.0,  5.5, 11.5,  5.5, 11.5, 13.5],   head: [11.5, 17.5,  7.0, 12.0, 16.0, 12.0]}
    shapes["RU"] := {shaft: [ 9.0, 16.5, 20.5, 16.5, 20.5,  8.5],   head: [20.5,  4.5, 16.0, 10.0, 25.0, 10.0]}
    shapes["RD"] := {shaft: [ 9.0,  5.5, 20.5,  5.5, 20.5, 13.5],   head: [20.5, 17.5, 16.0, 12.0, 25.0, 12.0]}

    for dirKey, geom in shapes {
        GdipCreateCanvas(pixW, pixH, argbWin, pBitmap, pGraphics)
        DllCall("gdiplus\GdipFillPath", "Ptr", pGraphics, "Ptr", pBrushBg, "Ptr", pPath)
        DllCall("gdiplus\GdipDrawPath", "Ptr", pGraphics, "Ptr", pPenBorder, "Ptr", pPath)

        DrawGdipPolyline(pGraphics, pPenArrow, geom.shaft, scale)
        FillGdipPolygon(pGraphics, pBrushArrow, geom.head, scale)

        hBmp := 0
        DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", hBmp, "UInt", argbWin)
        result[dirKey] := hBmp
        GdipReleaseCanvas(pBitmap, pGraphics)
    }

    DllCall("gdiplus\GdipDeletePen", "Ptr", pPenArrow)
    DllCall("gdiplus\GdipDeletePen", "Ptr", pPenBorder)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrushArrow)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrushBg)
    DllCall("gdiplus\GdipDeletePath", "Ptr", pPath)
    if (manageSession)
        GdipEndSession(hGdip, pToken)
    return result
}

DrawGdipPolyline(pGraphics, pPen, coords, scale := 1.0) {
    cnt := coords.Length() // 2
    VarSetCapacity(pts, cnt * 8, 0)
    Loop, %cnt% {
        idx := (A_Index - 1) * 2
        NumPut(coords[idx + 1] * scale, pts, idx * 4, "Float")
        NumPut(coords[idx + 2] * scale, pts, (idx + 1) * 4, "Float")
    }
    DllCall("gdiplus\GdipDrawLines", "Ptr", pGraphics, "Ptr", pPen, "Ptr", &pts, "Int", cnt)
}

FillGdipPolygon(pGraphics, pBrush, coords, scale := 1.0) {
    cnt := coords.Length() // 2
    VarSetCapacity(pts, cnt * 8, 0)
    Loop, %cnt% {
        idx := (A_Index - 1) * 2
        NumPut(coords[idx + 1] * scale, pts, idx * 4, "Float")
        NumPut(coords[idx + 2] * scale, pts, (idx + 1) * 4, "Float")
    }
    DllCall("gdiplus\GdipFillPolygon", "Ptr", pGraphics, "Ptr", pBrush, "Ptr", &pts, "Int", cnt, "Int", 0)
}

CreateChevronBitmaps(size := 16, bgArgb := 0xFFFBFBFB, manageSession := true) {
    result := {}
    if (manageSession && !GdipBeginSession(hGdip, pToken))
        return result

    scale := A_ScreenDPI / 96.0
    pix := Round(size * scale)

    for _, dir in ["down", "up"] {
        GdipCreateCanvas(pix, pix, bgArgb, pBitmap, pGraphics)
        pPen := 0
        DllCall("gdiplus\GdipCreatePen1", "UInt", 0xFF3A3A3A, "Float", 1.25 * scale, "Int", 2, "Ptr*", pPen)
        DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pPen, "Int", 2) ; Round
        DllCall("gdiplus\GdipSetPenEndCap",   "Ptr", pPen, "Int", 2)
        DllCall("gdiplus\GdipSetPenLineJoin", "Ptr", pPen, "Int", 2)

        if (dir = "down")
            DrawGdipPolyline(pGraphics, pPen, [3.0, 5.5, 8.0, 10.5, 13.0, 5.5], scale)
        else
            DrawGdipPolyline(pGraphics, pPen, [3.0, 10.5, 8.0, 5.5, 13.0, 10.5], scale)

        DllCall("gdiplus\GdipDeletePen", "Ptr", pPen)
        hBmp := 0
        DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", hBmp, "UInt", bgArgb)
        result[dir] := hBmp
        GdipReleaseCanvas(pBitmap, pGraphics)
    }

    if (manageSession)
        GdipEndSession(hGdip, pToken)
    return result
}
