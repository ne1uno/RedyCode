-- This file is part of RedyCode™ Integrated Development Environment
-- <http://redy-project.org/>
-- 
-- Copyright 2016 Ryan W. Johnson
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--   http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-------------------------------------------------------------------------------




public include redylib_0_9/oswin/win32/win32const.e

include std/os.e
include std/dll.e
include std/machine.e
include std/math.e
include std/error.e
include std/convert.e
include std/sort.e
include std/sequence.e as seq
 
 
object VOID

/*
constant
    C_BYTE = C_UCHAR,  
    C_BOOL = C_INT, 
    C_ATOM = C_USHORT, 
    C_WORD = C_USHORT, 
    C_DWORD=  C_ULONG, 
    C_WPARAM = C_POINTER, 
    C_LPARAM = C_POINTER, 
    C_HFILE = C_INT,  
    C_HWND = C_POINTER, 
    C_HANDLE = C_POINTER,  --all other H* are HANDLE 
    C_WNDPROC = C_POINTER, 
    C_LPSTR = C_POINTER, 
    C_LRESULT = C_POINTER, 
    C_LANGID =  C_WORD,   
    C_COLORREF =  C_DWORD,    --0x00bbggrr 
    $
*/
    
public atom xLoadIcon, xLoadCursor, xLoadImage, xGetStockObject, xRegisterClassEx, xCreateWindowEx, xShowWindow, xUpdateWindow, xPeekMessage, xGetMessage,
    xTranslateMessage, xDispatchMessage, xPlaySound, xBeginPaint, xGetClientRect, xGetWindowRect, xDrawText, xEndPaint, xPostQuitMessage, xDefWindowProc,
    xGetSystemMetrics, xCreateCursor, xDestroyCursor, xSetCursor, xGetUpdateRect, xInvalidateRect, xValidateRect, xInvalidateRgn,
    xSetTimer, xKillTimer, xSetWindowPos, xSetWindowText
    
public atom xMoveWindow, xDestroyWindow, xGetDC, xGetWindowDC, xReleaseDC, xDeleteDC, xCreateCompatibleDC, xCreateCompatibleBitmap, xSelectObject, xGetObject,
    xSelectClipPath, xCreateRectRgn, xSelectClipRgn, xGetDeviceCaps, xSetBkColor, xSetBkMode, xGetBkColor, xGetTextExtentPoint, xSetTextColor, xTextOut, xCreateFont, xEnumFontFamiliesEx,
    xBeginPath, xEndPath, xAbortPath, xStrokePath, xFillPath, xStrokeAndFillPath

public atom xBitBlt, xTransparentBlt, xScrollDC, xArc, xLineTo, xMoveToEx, xPolyBezier, xPolyBezierTo, xPolyLine, xPolyLineTo, xPolyPolyLine, xChord, xEllipse,
    xFillRect, xFrameRect, xInvertRect, xPie, xPolygon, xPolyPolygon, xRectangle, xRoundRect, xSetPixelV, xGetPixel, xGetBitmapDimensionEx

public atom xGetPolyFillMode, xSetPolyFillMode, xCreateSolidBrush, xCreateHatchBrush, xDeleteObject, xCreatePen, xGetCurrentObject

public atom xChangeClipboardChain,xCloseClipboard, xCountClipboardFormats, xEmptyClipboard, xEnumClipboardFormats, xGetClipboardData, 
    xGetClipboardFormatName, xGetClipboardOwner, xGetClipboardViewer, xGetOpenClipboardWindow, xGetPriorityClipboardFormat, xIsClipboardFormatAvailable,
    xOpenClipboard, xRegisterClipboardFormat, xSetClipboardData, xSetClipboardViewer, xGlobalAlloc, xGlobalFree, xDeleteMetaFile, xGlobalLock, xGlobalUnlock
 
public atom xClientToScreen, xSetMapMode, xGetMapMode, xDPtoLP, xTrackMouseEvent, xSetCapture, xReleaseCapture, xGetCapture

public atom xGetOpenFileName, xGetSaveFileName, xCommDlgExtendedError, xGetFileTitle, xBrowseForFolder, xShellExecute, xReadDirectoryChanges 

public atom xGetLogicalDriveStrings, xlstrlen, xGetDiskFreeSpaceEx, xGetDriveType

public atom xCreateProcess, xTerminateProcess

public atom xGetLastError, xCloseHandle, xCreateFileMapping, xMapViewOfFile, xUnmapViewOfFile, xOpenFileMapping 

    
-- dynamically link a C routine as a Euphoria function
function link_c_func(atom dll, sequence name, sequence args, atom result)
    atom handle
    
    handle = define_c_func(dll, name, args, result)
    if handle = -1 then
        crash("Couldn't find " & name)
    end if
    return handle
end function
    
-- dynamically link a C routine as a Euphoria procedure
function link_c_proc(atom dll, sequence name, sequence args)
    atom handle
    
    handle = define_c_proc(dll, name, args)
    if handle = -1 then
        crash("Couldn't find " & name)
    end if
    return handle
end function

-- get handles to all dll routines that we need
public procedure link_dll_routines()
    atom user32, gdi32, winmm, kernel32, comdlg32, shell32, msimg32
    
    -- open the .DLL files
    user32 = open_dll("user32.dll")
    if user32 = NULL then
        crash("Couldn't find user32.dll")
    end if
    gdi32 = open_dll("gdi32.dll")
    if gdi32 = NULL then
        crash("Couldn't find gdi32.dll")
    end if
    kernel32 = open_dll("kernel32.dll")
    if kernel32 = NULL then
        crash("Couldn't find kernel32.dll")
    end if
    winmm = open_dll("winmm.dll")
    if winmm = NULL then
        crash("Couldn't find winmm.dll")
    end if
    comdlg32 = open_dll("comdlg32.dll")
    if comdlg32 = NULL then
        crash("Couldn't find comdlg32.dll")
    end if    
    comdlg32 = open_dll("comdlg32.dll")
    if comdlg32 = NULL then
        crash("Couldn't find comdlg32.dll")
    end if  
    shell32 = open_dll("shell32.dll")
    if shell32 = NULL then
        crash("Couldn't find shell32.dll")
    end if   
    msimg32 = open_dll("Msimg32.dll")
    if msimg32 = NULL then
        crash("Couldn't find Msimg32.dll")
    end if  




    
    -- link the C routines
    --new code would use LoadImage    
    xLoadIcon = link_c_func(user32, "LoadIconA", {C_HANDLE, C_LPSTR}, C_HANDLE)
    xLoadCursor = link_c_func(user32, "LoadCursorA", {C_HANDLE, C_LPSTR}, C_HANDLE)
    xLoadImage = link_c_func(user32, "LoadImageA",{C_HANDLE, C_POINTER, C_UINT, C_INT, C_INT, C_UINT}, C_HANDLE)
    
    xRegisterClassEx = link_c_func(user32, "RegisterClassExA", {C_POINTER}, C_ATOM)
    xCreateWindowEx = link_c_func(user32, "CreateWindowExA", {C_DWORD, C_LPSTR, C_LPSTR,C_DWORD,C_INT,C_INT,C_INT,C_INT, C_HWND,C_HANDLE,C_HANDLE, C_POINTER}, C_HWND)

    xShowWindow = link_c_proc(user32, "ShowWindow", {C_HWND, C_INT})
    xUpdateWindow = link_c_proc(user32, "UpdateWindow", {C_HWND})
    xPeekMessage = link_c_func(user32, "PeekMessageA", {C_LPSTR, C_HWND, C_UINT, C_UINT, C_UINT}, C_BOOL)
    xGetMessage = link_c_func(user32, "GetMessageA", {C_LPSTR, C_HWND, C_UINT, C_UINT}, C_BOOL)

    xTranslateMessage = link_c_proc(user32, "TranslateMessage", {C_LPSTR})
    xDispatchMessage = link_c_proc(user32, "DispatchMessageA", {C_LPSTR})
    xPlaySound = link_c_proc(winmm, "PlaySound", {C_LPSTR, C_HANDLE, C_DWORD})
    xBeginPaint = link_c_func(user32, "BeginPaint", {C_HWND, C_POINTER}, C_HANDLE)
    xGetClientRect = link_c_proc(user32, "GetClientRect", {C_HWND, C_POINTER})
    xGetWindowRect = link_c_proc(user32, "GetWindowRect", {C_HWND, C_POINTER})
    xDrawText = link_c_proc(user32, "DrawTextA", {C_HANDLE, C_LPSTR, C_INT, C_POINTER, C_UINT})
    

    xEndPaint = link_c_proc(user32, "EndPaint", {C_HWND, C_POINTER})
    xPostQuitMessage = link_c_proc(user32, "PostQuitMessage", {C_INT})
    xDefWindowProc = link_c_func(user32, "DefWindowProcA", {C_HWND, C_UINT, C_WPARAM, C_LPARAM}, C_LRESULT)
    xGetStockObject = link_c_func(gdi32, "GetStockObject", {C_UINT}, C_HANDLE)

    xGetSystemMetrics = link_c_func(user32, "GetSystemMetrics", {C_INT}, C_INT)
    xCreateCursor = link_c_func(user32, "CreateCursor", {C_HANDLE, C_INT, C_INT, C_INT, C_INT, C_POINTER, C_POINTER}, C_HANDLE)
    xDestroyCursor = link_c_func(user32, "DestroyCursor", {C_HANDLE}, C_BOOL)
    xSetCursor = link_c_func(user32, "SetCursor", {C_HANDLE}, C_HANDLE)
    
    xSetTimer = link_c_func(user32, "SetTimer", {C_HWND , C_UINT, C_UINT, C_POINTER}, C_UINT)
    xKillTimer = link_c_func(user32, "KillTimer", {C_HWND, C_UINT}, C_BOOL)

    xSetWindowPos = link_c_func(user32, "SetWindowPos", {C_HWND, C_HWND, C_INT, C_INT, C_INT, C_INT, C_UINT}, C_BOOL)
    xSetWindowText = link_c_proc(user32, "SetWindowTextA", {C_HWND, C_POINTER})
    
    
    
    xMoveWindow = link_c_func(user32, "MoveWindow", {C_HWND, C_INT, C_INT, C_INT, C_INT, C_BOOL}, C_BOOL)
    --xGetWindowPlacement = link_c_func(user32, "GetWindowPlacement", {C_POINTER, C_POINTER}, C_LONG)
    --xSetWindowPlacement = link_c_func(user32, "SetWindowPlacement", {C_POINTER, C_POINTER}, C_LONG)
    xDestroyWindow = link_c_func(user32, "DestroyWindow", {C_HWND}, C_BOOL)
    
    xGetDC = link_c_func(user32, "GetDC", {C_HWND}, C_HANDLE)
    xGetWindowDC = link_c_func(user32, "GetWindowDC", {C_HWND}, C_HANDLE)
    xReleaseDC = link_c_func(user32, "ReleaseDC", {C_HWND, C_HANDLE}, C_INT)
    xDeleteDC = link_c_func(gdi32, "DeleteDC", {C_HANDLE}, C_BOOL)
    
    xBeginPath = link_c_func(gdi32, "BeginPath", {C_HANDLE}, C_BOOL)
    xEndPath = link_c_func(gdi32, "EndPath", {C_HANDLE}, C_BOOL)
    xAbortPath = link_c_func(gdi32, "AbortPath", {C_HANDLE}, C_BOOL)
    xStrokePath = link_c_func(gdi32, "StrokePath", {C_HANDLE}, C_BOOL)
    xFillPath = link_c_func(gdi32, "FillPath", {C_HANDLE}, C_BOOL)
    xStrokeAndFillPath = link_c_func(gdi32, "StrokeAndFillPath", {C_HANDLE}, C_BOOL)
    
    xGetUpdateRect = link_c_func(user32, "GetUpdateRect", {C_HANDLE, C_POINTER, C_BOOL}, C_BOOL)
    --xGetUpdateRgn = link_c_func(user32, "GetUpdateRgn", {C_POINTER, C_POINTER, C_LONG}, C_LONG)
    --xExcludeUpdateRgn = link_c_func(user32, "ExcludeUpdateRgn", {C_POINTER, C_POINTER}, C_LONG)
    xInvalidateRect = link_c_func(user32, "InvalidateRect", {C_HWND, C_POINTER, C_LONG}, C_BOOL)
    xValidateRect = link_c_func(user32, "ValidateRect", {C_HWND, C_POINTER}, C_BOOL)
    xInvalidateRgn = link_c_func(user32, "InvalidateRgn", {C_HWND, C_HANDLE, C_BOOL}, C_BOOL)
    --xValidateRgn = link_c_func(user32, "ValidateRgn", {C_HWND, C_POINTER}, C_BOOL)
    --xRedrawWindow = link_c_func(user32, "RedrawWindow", {C_POINTER, C_POINTER, C_POINTER, C_UINT}, C_LONG)
    
    xGetDeviceCaps = link_c_func(gdi32, "GetDeviceCaps", {C_HANDLE, C_INT}, C_INT)    
    --getSystemMetrics = link_c_func(user32, "GetSystemMetrics", {C_INT},C_LONG)    
    xTextOut = link_c_func(gdi32, "TextOutA", {C_HANDLE, C_INT, C_INT, C_POINTER, C_INT}, C_BOOL)
    xGetTextExtentPoint = link_c_func(gdi32, "GetTextExtentPoint32A", {C_HANDLE, C_POINTER, C_INT, C_POINTER}, C_BOOL)
    
    -- extending the text attributes    
    xSetTextColor = link_c_func(gdi32, "SetTextColor", {C_HANDLE, C_LONG}, C_LONG)
    --xSetTextAlign = link_c_func(gdi32, "SetTextAlign", {C_POINTER, C_UINT}, C_UINT)
    --xSetTextJustification = link_c_func(gdi32, "SetTextJustification", {C_POINTER, C_INT, C_INT}, C_LONG)
    xSetBkColor = link_c_func(gdi32, "SetBkColor", {C_HANDLE, C_LONG}, C_LONG)
    xSetBkMode = link_c_func(gdi32, "SetBkMode", {C_HANDLE, C_INT}, C_INT)
    xGetBkColor = link_c_func(gdi32, "GetBkColor", {C_HANDLE}, C_LONG)
    xCreateFont = link_c_func(gdi32, "CreateFontA", {C_INT, C_INT, C_INT, C_INT, C_INT,
                C_DWORD, C_DWORD, C_DWORD, C_DWORD, C_DWORD, C_DWORD, C_DWORD, C_DWORD, C_POINTER}, C_HANDLE)
                --HFONT CreateFont(int nHeight, int nWidth, int nEscapement, int nOrientation, int fnWeight, 
                --DWORD fdwItalic, DWORD fdwUnderline, DWORD fdwStrikeOut, DWORD fdwCharSet, DWORD fdwOutputPrecision,
                --DWORD fdwClipPrecision, DWORD fdwQuality, DWORD fdwPitchAndFamily, LPCTSTR lpszFace);
    xEnumFontFamiliesEx = link_c_func(gdi32, "EnumFontFamiliesExA", {C_HANDLE, C_POINTER, C_POINTER, C_LPARAM, C_DWORD}, C_INT)
    
    xCreateCompatibleDC = link_c_func(gdi32, "CreateCompatibleDC", {C_HANDLE}, C_HANDLE)    
    xCreateCompatibleBitmap = link_c_func(gdi32, "CreateCompatibleBitmap", {C_HANDLE, C_INT, C_INT}, C_HANDLE)
    --xCreateDIBitmap = link_c_func(gdi32, "CreateDIBitmap", {C_POINTER, C_POINTER, C_LONG, C_LONG, C_POINTER, C_LONG}, C_LONG)
    xSelectObject = link_c_func(gdi32, "SelectObject", {C_HANDLE, C_HANDLE}, C_HANDLE)
    xGetObject = link_c_func(gdi32, "GetObjectA", {C_HANDLE, C_INT, C_POINTER}, C_INT)
    -- Bitmaps
    xSelectClipPath = link_c_func(gdi32, "SelectClipPath", {C_HANDLE, C_INT}, C_BOOL)
    xCreateRectRgn = link_c_func(gdi32, "CreateRectRgn", {C_INT, C_INT, C_INT, C_INT}, C_HANDLE)
    --xSelectClipRgn =  link_c_func(gdi32, "SelectClipRgn", {C_HANDLE, C_HANDLE}, C_INT)
    --xSelectClipPath = 
    xBitBlt = link_c_func(gdi32, "BitBlt", {C_HANDLE, C_INT, C_INT, C_INT, C_INT, C_HANDLE, C_INT, C_INT, C_DWORD}, C_BOOL)
    xTransparentBlt = link_c_func(msimg32, "TransparentBlt", {
        C_HANDLE, C_INT, C_INT, C_INT, C_INT, C_HANDLE, C_INT, C_INT, C_INT, C_INT, C_INT}, C_BOOL)
    
    xScrollDC = link_c_func(user32, "ScrollDC", {C_HANDLE, C_INT, C_INT, C_POINTER, C_POINTER, C_HANDLE, C_POINTER}, C_BOOL)
    
    -- Graphics
    xArc = link_c_func(gdi32, "Arc", {C_HANDLE, C_INT, C_INT, C_INT, C_INT, C_INT, C_INT, C_INT, C_INT}, C_BOOL)
    xLineTo = link_c_func(gdi32, "LineTo", {C_HANDLE, C_INT, C_INT}, C_INT)
    xMoveToEx = link_c_func(gdi32, "MoveToEx", {C_HANDLE, C_INT, C_INT, C_POINTER}, C_BOOL)
    xPolyBezier = link_c_func(gdi32, "PolyBezier", {C_HANDLE, C_POINTER, C_DWORD}, C_BOOL)
    --xPolyBezierTo = link_c_func(gdi32, "PolyBezierTo",{C_INT,C_INT,C_INT})
    xPolyLine = link_c_func(gdi32, "Polyline", {C_HANDLE, C_INT, C_INT}, C_BOOL)
    --xPolyLineTo = link_c_func(gdi32, "PolylineTo",{C_INT,C_INT,C_INT})
    --xPolyPolyLine = link_c_func(gdi32, "PolyPolyline", {C_INT,C_INT,C_INT,C_INT})
    xChord = link_c_func(gdi32, "Chord", {C_HANDLE, C_INT, C_INT, C_INT, C_INT, C_INT, C_INT, C_INT, C_INT}, C_BOOL)
    
    xEllipse = link_c_func(gdi32, "Ellipse", {C_HANDLE, C_INT, C_INT, C_INT, C_INT}, C_BOOL)
    
    --xFillRect = link_c_proc(user32, "FillRect",{C_INT,C_INT,C_INT})
    --xFrameRect = link_c_proc(user32, "FrameRect",{C_INT,C_INT,C_INT})
    --xInvertRect = link_c_proc(user32, "InvertRect",{C_INT,C_INT})
    xPie = link_c_func(gdi32, "Pie", {C_HANDLE, C_INT, C_INT, C_INT, C_INT, C_INT, C_INT, C_INT, C_INT}, C_BOOL)
    xPolygon = link_c_func(gdi32, "Polygon", {C_HANDLE, C_POINTER, C_INT}, C_BOOL)
    --xPolyPolygon = link_c_proc(gdi32, "PolyPolygon",{C_INT,C_INT,C_INT,C_INT})
    xRectangle = link_c_func(gdi32, "Rectangle", {C_HANDLE, C_INT, C_INT, C_INT, C_INT}, C_BOOL)
    xRoundRect = link_c_func(gdi32, "RoundRect", {C_HANDLE, C_INT, C_INT, C_INT, C_INT, C_INT, C_INT}, C_BOOL)
    
    --xGetPolyFillMode = link_c_func(gdi32, "GetPolyFillMode",{C_INT},C_INT)
    --xSetPolyFillMode = link_c_proc(gdi32, "SetPolyFillMode",{C_INT,C_INT})
    xCreateSolidBrush = link_c_func(gdi32, "CreateSolidBrush", {C_INT}, C_HANDLE)
    xCreateHatchBrush = link_c_func(gdi32, "CreateHatchBrush", {C_INT, C_INT}, C_INT)
    xDeleteObject = link_c_proc(gdi32, "DeleteObject",{C_HANDLE})
    xCreatePen = link_c_func(gdi32, "CreatePen", {C_INT, C_INT, C_INT}, C_HANDLE)
    xGetCurrentObject = link_c_func(gdi32, "GetCurrentObject", {C_HANDLE, C_UINT}, C_HANDLE)
    
    xSetPixelV = link_c_func(gdi32, "SetPixelV", {C_HANDLE, C_INT, C_INT, C_INT}, C_BOOL)
    xGetPixel = link_c_func(gdi32, "GetPixel", {C_HANDLE, C_INT, C_INT}, C_INT)
    xGetBitmapDimensionEx = link_c_func(gdi32, "GetBitmapDimensionEx", {C_HANDLE, C_POINTER}, C_BOOL)
  
    --Clipboard functions:
    --xChangeClipboardChain = link_c_proc(user32, "ChangeClipboardChain", {C_UINT,C_UINT})
    xCloseClipboard = link_c_func(user32, "CloseClipboard", {}, C_BOOL)
    --xCountClipboardFormats = link_c_func(user32, "CountClipboardFormats",{},C_INT)
    xEmptyClipboard = link_c_func(user32, "EmptyClipboard", {}, C_BOOL)
    --xEnumClipboardFormats = link_c_func(user32, "EnumClipboardFormats",{C_UINT},C_UINT)
    xGetClipboardData = link_c_func(user32, "GetClipboardData", {C_UINT}, C_HANDLE)
    --xGetClipboardFormatName = link_c_func(user32, "GetClipboardFormatNameA",{C_UINT,C_UINT,C_UINT},C_UINT)
    --xGetClipboardOwner = link_c_func(user32, "GetClipboardOwner",{},C_UINT)
    --xGetClipboardViewer = link_c_func(user32, "GetClipboardViewer",{},C_UINT)
    --xGetOpenClipboardWindow = link_c_func(user32, "GetOpenClipboardWindow",{},C_UINT)
    --xGetPriorityClipboardFormat = link_c_func(user32, "GetPriorityClipboardFormat",{C_UINT,C_UINT},C_UINT)
    xIsClipboardFormatAvailable = link_c_func(user32, "IsClipboardFormatAvailable", {C_UINT}, C_BOOL)
    xOpenClipboard = link_c_func(user32, "OpenClipboard", {C_HANDLE}, C_BOOL)
    --xRegisterClipboardFormat = link_c_func(user32, "RegisterClipboardFormatA",{C_UINT},C_UINT)
    xSetClipboardData = link_c_func(user32, "SetClipboardData", {C_UINT, C_HANDLE}, C_HANDLE)
    --xSetClipboardViewer  = link_c_func(user32, "SetClipboardViewer",{C_UINT},C_UINT)
    xGlobalAlloc = link_c_func(kernel32, "GlobalAlloc", {C_UINT, C_DWORD}, C_HANDLE)
    xGlobalFree = link_c_func(kernel32, "GlobalFree", {C_HANDLE}, C_HANDLE)
    xDeleteMetaFile = link_c_func(gdi32, "DeleteMetaFile", {C_HANDLE}, C_BOOL)
    xGlobalLock = link_c_func(kernel32, "GlobalLock", {C_HANDLE}, C_POINTER)
    xGlobalUnlock = link_c_func(kernel32, "GlobalUnlock", {C_HANDLE}, C_BOOL)

    xGetSystemMetrics = link_c_func(user32, "GetSystemMetrics", {C_INT}, C_INT)
    
    
    xClientToScreen = link_c_func(user32, "ClientToScreen", {C_HWND, C_POINTER}, C_BOOL)
    
    xSetMapMode = link_c_func(gdi32, "SetMapMode", {C_HWND, C_INT}, C_INT)
    xGetMapMode = link_c_func(gdi32, "GetMapMode", {C_HANDLE}, C_INT)
    
    xDPtoLP = link_c_func(gdi32, "DPtoLP", {C_HANDLE, C_POINTER, C_INT}, C_BOOL)
    
    xTrackMouseEvent = link_c_func(user32, "TrackMouseEvent", {C_POINTER}, C_BOOL)
    xSetCapture = link_c_func(user32, "SetCapture", {C_HWND}, C_HWND)
    xReleaseCapture = link_c_func(user32, "ReleaseCapture", {}, C_BOOL)
    --xGetCapture = link_c_func(user32, "GetCapture", {}, C_POINTER)
    
    
    --Common Dialogs:
    xCommDlgExtendedError = link_c_func(comdlg32, "CommDlgExtendedError", {}, C_DWORD)
    xGetOpenFileName = link_c_func(comdlg32, "GetOpenFileNameA", {C_POINTER}, C_BOOL)
    xGetSaveFileName = link_c_func(comdlg32, "GetSaveFileNameA", {C_POINTER}, C_BOOL)
    xGetFileTitle = link_c_func(comdlg32, "GetFileTitleA", {C_POINTER, C_POINTER, C_WORD}, C_SHORT)
    
    --Shell functions:
    --xBrowseForFolder = link_c_func(shell32, "SHBrowseForFolderA", {C_POINTER}, C_ULONG)
    xShellExecute = link_c_func(shell32, "ShellExecuteA", {C_HWND, C_POINTER, C_POINTER, C_POINTER, C_POINTER, C_INT}, C_INT) --C_HWND)
    --xReadDirectoryChanges= link_c_func(shell32, "ReadDirectoryChangesW", {}, )
    
    --IPC:
    xCreateProcess = link_c_func(kernel32, "CreateProcessA", {C_POINTER, C_POINTER, C_POINTER, C_POINTER, C_BOOL, C_DWORD, C_POINTER, C_POINTER, C_POINTER, C_POINTER},C_BOOL)
    xTerminateProcess = link_c_func(kernel32,"TerminateProcess", {C_POINTER, C_UINT}, C_BOOL)
    
    --xGetLastError = link_c_func(kernel32, "GetLastError", {}, C_DWORD)
    --xCloseHandle = link_c_func(kernel32,"CloseHandle", {C_HANDLE}, C_BOOL)
    --xCreateFileMapping = link_c_func(kernel32, "CreateFileMappingA", {C_HANDLE, C_POINTER, C_DWORD, C_DWORD, C_DWORD, C_POINTER}, C_HANDLE)
    --xMapViewOfFile = link_c_func(kernel32, "MapViewOfFile", {C_HANDLE, C_DWORD, C_DWORD, C_DWORD, C_POINTER}, C_LONG)
    --xUnmapViewOfFile = link_c_func(kernel32, "UnmapViewOfFile", {C_POINTER}, C_BOOL)
    --xOpenFileMapping = link_c_func(kernel32, "OpenFileMappingA", {C_DWORD, C_BOOL, C_POINTER}, C_HANDLE)
    
    --xShellExecute = link_c_func(shell32, "ShellExecuteA", {C_HWND, C_POINTER, C_POINTER, C_POINTER, C_POINTER, C_INT}, C_LONG)
    
    
    

    --Drives information:
    --xGetLogicalDriveStrings = link_c_func(kernel32, "GetLogicalDriveStringsA", {C_ULONG,C_POINTER}, C_ULONG)
    --xlstrlen = link_c_func(kernel32, "lstrlen", {C_POINTER}, C_INT)
    --xGetDiskFreeSpaceEx = link_c_func(kernel32, "GetDiskFreeSpaceExA",{C_POINTER,C_POINTER,C_POINTER,C_POINTER}, C_ULONG)
    --xGetDriveType = link_c_func(kernel32, "GetDriveTypeA",{C_POINTER}, C_UINT)

end procedure



function deg_to_rad(atom angle) -- convert degree to radian
    return angle/180*3.141592654
end function


public function RegisterClassEx(
    atom AcbSize,
    atom Astyle,
    atom AlpfnWndProc,
    atom AcbClsExtra,
    atom AcbWndExtra,
    atom AhInstance,
    atom AhIcon,
    atom AhCursor,
    atom AhbrBackground,
    sequence AlpszMenuName,
    sequence AlpszClassName,
    atom AhIconSm
)
    -- Wolfgang Fritz observes that you can set an icon
    -- dynamically using:
    -- junk = sendMessage(YourWindow, 128, 1, icon_handle) 
    -- where 128 is WM_SETICON   

    atom
    wndclass = allocate(AcbSize),
    szAlpszMenuName = allocate_string(AlpszMenuName),
    szAlpszClassName = allocate_string(AlpszClassName)

    poke4(wndclass + cbSize, AcbSize)
    poke4(wndclass + style, Astyle)
    poke4(wndclass + lpfnWndProc, AlpfnWndProc)
    poke4(wndclass + cbClsExtra, AcbClsExtra)
    poke4(wndclass + cbWndExtra, AcbWndExtra)
    poke4(wndclass + hInstance, AhInstance)
    poke4(wndclass + hIcon, AhIcon)
    poke4(wndclass + hCursor, AhCursor)
    poke4(wndclass + hbrBackground, AhbrBackground)
    poke4(wndclass + lpszMenuName, szAlpszMenuName)
    poke4(wndclass + lpszClassName, szAlpszClassName)
    poke4(wndclass + hIconSm, AhIconSm)

    return c_func(xRegisterClassEx, {wndclass})
end function

public function CreateWindowEx(
    atom AdwExStyle,
    sequence AlpClassName,
    sequence AlpWindowName,
    atom AdwStyle,
    atom Ax,
    atom Ay,
    atom AnWidth,
    atom AnHeight,
    atom AhWndParent,
    atom AhMenu,
    atom AhInstance,
    atom AlpParam
)
    atom 
    szAlpClassName = allocate_string(AlpClassName),
    szAlpWindowName = allocate_string(AlpWindowName)

    return c_func(xCreateWindowEx, {
        AdwExStyle,
        szAlpClassName,
        szAlpWindowName,
        AdwStyle,
        Ax,
        Ay,
        AnWidth,
        AnHeight,
        AhWndParent,
        AhMenu,
        AhInstance,
        AlpParam}
    )
             
end function




------------------------------------------------------------------------------

public function short_int( atom i ) --from win32lib

    -- converts numbers ( 4 bytes #0000 to #FFFF)
    -- to signed short ints (2 bytes -32768 to 32767 )

    -- Force the use of only the rightmost 2 bytes.
    i = and_bits(i, #FFFF)

    if i >= 0 and i <= #7FFF then
        return i
    else
        return i - #10000
    end if

end function
            
            
--/topic Support Routines
--/func w32lo_word( atom pData)
--/desc returns the low-16 bits of /i pData
--/ret INTEGER: Bits 15-0 of the parameter
public function lo_word( atom pData) --from win32lib
    return and_bits(pData, #FFFF)
end function


--/topic Support Routines
--/func w32hi_word( atom pData)
--/desc returns the high 16 bits of /i pData
--/ret INTEGER: Bits 31-16 of the parameter as a 16 bit value.
public function hi_word( atom pData)
    return and_bits(and_bits(pData, #FFFF0000) / #10000, #FFFF)
end function


function codeToBytes( sequence bits ) --from win32lib
    -- Convert a sequence of text into bytes
    -- This is a support routine for createMonochromeBitmap
    -- Ex:  "1,1,1,1,1,1,1,1,0,0"
    --      --> { #FF, #00 }

    atom byte, extra
    sequence slice, bytes

    -- add extra bits: must be multiple of 16
    extra = remainder( length(bits), 16 )
    if extra then
        bits = bits & repeat( 1, 16-extra )
    end if

    -- convert bits to bytes
    bytes = {}

    for i = 1 to length( bits ) by 8 do
        -- get an 8 bit slice
        slice = bits[i..i+7]
        -- reverse it for conversion
        slice = reverse( slice )
        -- convert bits to a byte
        byte = bits_to_int( slice )
        -- add to list
        bytes = append( bytes, byte )
    end for
    return bytes
end function


-- Multiple-monitor detection --------------------------

/*  
BOOL EnumDisplayDevices(
  _In_   LPCTSTR lpDevice,
  _In_   DWORD iDevNum,
  _Out_  PDISPLAY_DEVICE lpDisplayDevice,
  _In_   DWORD dwFlags
);


typedef struct _DISPLAY_DEVICE {
  DWORD cb;
  TCHAR DeviceName[32];
  TCHAR DeviceString[128];
  DWORD StateFlags;
  TCHAR DeviceID[128];
  TCHAR DeviceKey[128];
} DISPLAY_DEVICE, *PDISPLAY_DEVICE;

*/

public function getPrimaryDisplaySize() --get size of primary display
    atom cx, cy
    cx = c_func( xGetSystemMetrics, { SM_CXSCREEN } )
    cy = c_func( xGetSystemMetrics, { SM_CYSCREEN } )
    
    return {cx, cy}
end function


public function createMousePointer( atom x, atom y, sequence image ) --from win32lib
    -- load the cursor
    atom cx, cy, diff
    atom andPlane, xorPlane, hCursor
    sequence data, maskBits

    -- get the metrics for the cursor
    cx = c_func( xGetSystemMetrics, { SM_CXCURSOR } )
    cy = c_func( xGetSystemMetrics, { SM_CYCURSOR } )

    -- ensure image is wide enough
    diff = cx - length( image[1] )
    for i = 1 to length( image ) do

        -- add padding...
        image[i] &= repeat( ' ', cx )

        -- trim
        image[i] = image[i][1..cx]

    end for

    -- ensure the image is tall enough
    for i = 1 to cy do
        -- add extra padding
        image = append( image, repeat( ' ', cx ) )
    end for
    -- trim
    image = image[1..cy]

    -- create the and mask
    maskBits = ( image = ' ' )

    -- convert the bits to bytes
    data = {}
    for i = 1 to length( maskBits ) do
        data = data & codeToBytes( maskBits[i] )
    end for

    -- Allocate and poke the and plane data
    andPlane = allocate(length(data))
    poke( andPlane, data )

    -- create the xor mask
    maskBits = (image = '.')

    -- convert the bits to bytes
    data = {}
    for i = 1 to length( maskBits ) do
        data = data & codeToBytes( maskBits[i] )
    end for

    -- Allocate and poke the xor plane data
    xorPlane = allocate(length(data), 0)
    poke( xorPlane, data )

    -- create the cursor
    hCursor = c_func( xCreateCursor,
            { instance(),       -- application instance
              x, y,             -- x and y of hotspot
              length( image ),    -- cursor width
              length( image[1] ), -- cursor height
              andPlane,
              xorPlane } )

    
    -- keep track of cursor
    --trackCursor( hCursor )

    return hCursor
end function


public function TrackMouseEvent(atom hwndTrack)
    atom ret
    --DWORD cbSize;
    --DWORD dwFlags;
    --HWND  hwndTrack;
    --DWORD dwHoverTime;
    atom cbSize = 16,
    lpEventTrack = allocate(cbSize)

    poke4(lpEventTrack + 0, cbSize)
    poke4(lpEventTrack + 4, TME_LEAVE)
    poke4(lpEventTrack + 8, hwndTrack)
    poke4(lpEventTrack + 12, 400)
    
    ret = c_func(xTrackMouseEvent, {lpEventTrack})
    free(lpEventTrack)
    
    return ret
end function

/*
sequence hBitmaps = {}

global function load_bitmap(sequence bmpfile)
    hBitmaps &= loadBitmapFromFile(bmpfile)
    return hBitmaps[$] 
end function
*/

public function create_font(atom hdc, sequence fName, object fSize, atom fWeight, atom fItalic, atom fUnderline, atom fStrikeout)
    atom hfont, fh, fwt, szfname
    --HFONT CreateFont(int nHeight, int nWidth, int nEscapement, int nOrientation, int fnWeight, 
    --DWORD fdwItalic, DWORD fdwUnderline, DWORD fdwStrikeOut, DWORD fdwCharSet, DWORD fdwOutputPrecision,
    --DWORD fdwClipPrecision, DWORD fdwQuality, DWORD fdwPitchAndFamily, LPCTSTR lpszFace);
    
    --fh = -MulDiv(fSize, GetDeviceCaps(hDC, LOGPIXELSY), 72);
    fh = -floor(fSize * c_func(xGetDeviceCaps, {hdc, LOGPIXELSY}) / 72)
    
    if fWeight = True then
        fwt = 700 --FW_BOLD
    else 
        fwt = 400 --FW_NORMAL
    end if
    szfname = allocate_string(fName)
    hfont = c_func(xCreateFont, {fh, 0, 0, 0, fwt, 
            fItalic, fUnderline, fStrikeout, ANSI_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH, szfname})
    free(szfname)
    
    return hfont
end function



global function get_sys_color(atom color) --why is this here?
    return 0 --rgb(128,128,128) --getSysColor(color)
end function



global function ClientToScreen(atom hWnd, sequence xyin)
    sequence xy
    atom result, ptrpoint
    
    ptrpoint = allocate(szLong * 2)
    poke4(ptrpoint, xyin)
    result = c_func(xClientToScreen, {hWnd, ptrpoint})
    xy = peek4s({ptrpoint, 2})
    free(ptrpoint)
    
    return xy
end function

atom MouseCaptured = 0

global procedure capture_mouse(atom hwnd)
    --if MouseCaptured != 1 then
    atom void = c_func(xSetCapture, {hwnd})
    MouseCaptured = 1
    --end if
end procedure

global procedure release_mouse()
    if MouseCaptured > 0 then
        MouseCaptured = 0
        atom void = c_func(xReleaseCapture, {})
    end if
end procedure


-- Enumerate Fonts ------------------------------------------------------------
-- Based on Font Enumerator by Greg Haberek

 
constant
-- LOGFONT structure
lfHeight            = struct_allot(szLong),
lfWidth             = struct_allot(szLong),
lfEscapement        = struct_allot(szLong),
lfOrientation       = struct_allot(szLong),
lfWeight            = struct_allot(szLong),
lfItalic            = struct_allot(szByte),
lfUnderline         = struct_allot(szByte),
lfStrikeOut         = struct_allot(szByte),
lfCharSet           = struct_allot(szByte),
lfOutPrecision      = struct_allot(szByte),
lfClipPrecision     = struct_allot(szByte),
lfQuality           = struct_allot(szByte),
lfPitchAndFamily    = struct_allot(szByte),
lfFaceName          = struct_allot(LF_FACESIZE),
SIZEOF_LOGFONT      = struct_allotted_size()

constant
-- ENUMLOGFONT structure
elfLogFont          = struct_allot(SIZEOF_LOGFONT),
elfFullName         = struct_allot(LF_FULLFACESIZE),
elfStyle            = struct_allot(LF_FACESIZE),
SIZEOF_ENUMLOGFONT  = struct_allotted_size()

constant
-- NEWTEXTMETRIC structure
tmHeight            = struct_allot(szLong),
tmAscent            = struct_allot(szLong),
tmDescent           = struct_allot(szLong),
tmInternalLeading   = struct_allot(szLong),
tmExternalLeading   = struct_allot(szLong),
tmAveCharWidth      = struct_allot(szLong),
tmMaxCharWidth      = struct_allot(szLong),
tmWidth             = struct_allot(szLong),
tmOverhang          = struct_allot(szLong),
tmDigitizedAspectX  = struct_allot(szLong),
tmDigitizedAspectY  = struct_allot(szLong),
tmFirstChar         = struct_allot(szByte),
tmLastChar          = struct_allot(szByte),
tmDefaultChar       = struct_allot(szByte),
tmBreakChar         = struct_allot(szByte),
tmItalic            = struct_allot(szByte),
tmUnderlined        = struct_allot(szByte),
tmStruckOut         = struct_allot(szByte),
tmPitchAndFamily    = struct_allot(szByte),
tmCharSet           = struct_allot(szByte),
ntmFlags            = struct_allot(szDWord),
ntmSizeEM           = struct_allot(szUInt),
ntmCellHeight       = struct_allot(szUInt),
ntmAvgWidth         = struct_allot(szUInt),
SIZEOF_NEWTEXTMETRIC = struct_allotted_size()

sequence avail_fonts, font_styles

function EnumFontFamProc(atom lpelf, atom lpntm, atom FontType, atom lParam)
    sequence FullName, Style
    integer id
    
    --FullName = "name" --fetch(lpelf, elfFullName)
    --Style = "style" --fetch(lpelf, elfStyle)
    
    FullName = peek_string(lpelf + lfFaceName)
    
    --pretty_print(1, FullName, {2})
    
    id = find(FullName, avail_fonts)
    if id then
        --if not find(Style, font_styles[id]) then
        --    font_styles[id] = append( font_styles[id], Style)
        --end if
    else
        avail_fonts = append(avail_fonts, FullName)
        --font_styles = append(font_styles, {Style})
    end if
    
    return True
end function
constant lpEnumFontFamProc = call_back(routine_id("EnumFontFamProc"))


global function EnumFonts(atom hWnd)
-- returns a list of { {"font name", {"style 1", "style 2", ... }}, ... }
    atom hDC, lpLogfont, lParam
    sequence fonts
    
    hDC = c_func(xGetDC, {hWnd})
    lpLogfont = 0 --allocate_data(SIZEOF_LOGFONT)
    lParam = 0 --allocate_data(4)
    
    avail_fonts = {}
    font_styles = {}
    VOID = c_func(xEnumFontFamiliesEx, {hDC, lpLogfont, lpEnumFontFamProc, lParam, 0})
    c_func(xReleaseDC, {hWnd, hDC})
    --free({lpLogfont, lParam})
    
    fonts = {}
    for i = 1 to length(avail_fonts) do
        fonts = append(fonts, {avail_fonts[i]}) --, font_styles[i]} )
    end for
    
    return sort(fonts)
end function



-- Create/Terminate processes, copied from std/pipeio.e and modified to not inherit handles or redirect STDIN and STDOUT


constant
--PIPE_WRITE_HANDLE = 1,
--PIPE_READ_HANDLE = 2,
--HANDLE_FLAG_INHERIT = 1,
--STARTF_USESHOWWINDOW = 1,
--STARTF_USESTDHANDLES = 256,
FAIL = 0

ifdef BITS32 then
    constant
    SA_SIZE = 12,
    SUIdwFlags = 44, 
    SUIhStdInput = 56, 
    STARTUPINFO_SIZE = 68,
    PROCESS_INFORMATION_SIZE = 16
elsedef
    constant
    SA_SIZE = 24,
    SUIdwFlags = 60, 
    SUIhStdInput = 80, 
    STARTUPINFO_SIZE = 104,
    PROCESS_INFORMATION_SIZE = 24
end ifdef


ifdef EU4_0 then
    public function peek_pointer(object x)
        return peek4u(x)
    end function
end ifdef


export function CreateProcess(sequence CommandLine)
    object fnVal
    atom pPI, pSUI, pCmdLine
    sequence ProcInfo
    
    pCmdLine = machine:allocate_string(CommandLine)
    
    pPI = machine:allocate(PROCESS_INFORMATION_SIZE)
    mem_set(pPI,0,PROCESS_INFORMATION_SIZE)
    
    pSUI = machine:allocate(STARTUPINFO_SIZE)
    mem_set( pSUI, 0, STARTUPINFO_SIZE)
    poke4( pSUI, STARTUPINFO_SIZE)
    --poke4( pSUI + SUIdwFlags, or_bits( STARTF_USESTDHANDLES, STARTF_USESHOWWINDOW ) )
    --poke_pointer( pSUI + SUIhStdInput, StdHandles)
    
    --fnVal = c_func(xCreateProcess,{0, pCmdLine, 0, 0, 1, 0, 0, 0, pSUI, pPI})
    fnVal = c_func(xCreateProcess, {0, pCmdLine, 0, 0, 0, 0, 0, 0, pSUI, pPI})
    
    machine:free(pCmdLine)
    machine:free(pSUI)
    

    
    
    ifdef BITS32 then
        ProcInfo = peek4u({pPI,4})
        elsedef
        ProcInfo = peek_pointer({pPI, 2}) & peek4u({pPI + 16, 2})
    end ifdef
    machine:free(pPI)
    if not fnVal then
        return 0
    end if
    return ProcInfo
end function


export function TerminateProcess(atom hProcess, atom signal = 15)
    --ifdef WINDOWS then
    atom ret = c_func(xTerminateProcess,{hProcess, signal and 0})
    --elsedef
    --    c_func(KILL, {p[PID], signal})
    --end ifdef
    return ret
end function

-- Shared Memory Messaging system --------------------------------------------

-- based on Memory Sharing Library, Version: 3.3 by Jason Mirwald and Mario Steele
/*
sequence 
strHandles = {}, smHandles = {}, smPointers = {}

export constant
SM_CREATE_EXIST = -1,
SM_CREATE_FAIL = -2,
SM_OPEN_FAIL = -3,
SM_MEM_FAIL = -4


export function sm_create(sequence strHandle, integer size)
    atom lpszHandle, wHandle, lPointer, idx, error
    idx = find(strHandle,strHandles)
    
    if idx then
        return smPointers[idx]
    end if
    
    lpszHandle = allocate_string(strHandle)
    
    if lpszHandle > 0 then
        wHandle = c_func(xCreateFileMapping, {-1, 0, #4, 0, size, lpszHandle})
        free(lpszHandle)
        
        if wHandle > 0 then
            error = c_func(xGetLastError, {})
            if error = 0 then
                lPointer = c_func(xMapViewOfFile, {wHandle, #F001F, 0 , 0, 0})
                if lPointer > 0 then
                    strHandles &= {strHandle}
                    smHandles &= wHandle
                    smPointers &= lPointer
                    
                    return lPointer
                end if
            end if -- lPointer
            
            VOID = c_func(xCloseHandle, {wHandle})
            if error = 183 then
                return SM_CREATE_EXIST
            end if
        end if -- wHandle
        
        return SM_CREATE_FAIL
    end if -- lpszHandle
    
    return SM_MEM_FAIL
end function


export function sm_open(sequence strHandle)
    atom lpszHandle, wHandle, lPointer, idx
    idx = find(strHandle, strHandles)
    
    if idx then
        return smPointers[idx]
    end if
    
    lpszHandle = allocate_string(strHandle)
    if lpszHandle > 0 then
        wHandle = c_func(xOpenFileMapping, {#F001F, 0, lpszHandle})
        free(lpszHandle)
        
        if wHandle > 0 then
            lPointer = c_func(xMapViewOfFile, {wHandle, #F001F, 0, 0, 0})
            if lPointer > 0 then
                strHandles &= {strHandle}
                smHandles &= wHandle
                smPointers &= lPointer
                
                return lPointer
            end if -- lPointer
            VOID = c_func(xCloseHandle, {wHandle})
        end if -- wHandle
        
        return SM_OPEN_FAIL
    end if -- lpszHandle
    
    return SM_MEM_FAIL
end function


export procedure sm_close(object smPointer)
    atom ack, idx
    
    if sequence(smPointer) then
        idx = find(smPointer, strHandles)
    else
        idx = find(smPointer, smPointers)
    end if
    
    if idx then
        ack = c_func(xUnmapViewOfFile, {smPointers[idx]})
        ack = c_func(xCloseHandle, {smHandles[idx]})
        strHandles = remove(strHandles, idx)
        smHandles = remove(smHandles, idx)
        smPointers = remove(smPointers, idx)
    end if
end procedure
*/









--Drives Info
--Code converted from GetDrivesInfo.exw by Al Getz (08/2003)
/*
constant BYTE_STANDARD=1024*1024      --Choose either 1024*1024 or 1000000 bytes per megabyte standards.
                                      --1024*1024 is recommended, but you can use 1 to return bytes also.
                               
function peek_pui64_to_ui3232(atom pui64)
    --This function returns {lower32 bits,upper32 bits}.
    --pui64 must be a valid ui64 pointer.

    return peek4u({pui64,2})
end function


function peek_pui64_to_atom(atom pui64)
    --This function works for lower range ui64's.
    --ui64's close to the upper limit will round off,
    --which is probably around 2^59.  This means a ui64
    --cant always be converted to an atom accurately.
    --Its ok for disk sizes though as there arent
    --any 524,288 gigabyte drives around (yet), and
    --we are rounding to nearest kilobyte anyway.
    --If more range is needed, call peek_pui64_to_ui3232
    --and handle result as a two part number instead of
    --converting to atom.

    sequence ui3232

    ui3232=peek_pui64_to_ui3232(pui64)
    return ui3232[1]+ui3232[2]*#100000000
    --really requires 20 digits for the full range,
    --but we dont need that many.
end function


function GetDriveInfo(sequence drive)
    --works with any size disk
    --returns:
    --  {readystatus,kbytes free to caller,total kbytes,free bytes,disk type}
    --where
    --  readystatus=1 for drive ready, 0 for not ready
    --  kbytes free to caller= kbytes free to program that calls this
    --  total kbytes=total kbytes on logical disk
    --  disk type = pointer to string in DiskTypeStrings[] (above)
    --  which can take on only one of the following values:
    --    DRIVE_UNKNOWN=0,
    --    DRIVE_NO_ROOT_DIR=1,
    --    DRIVE_REMOVABLE=2,
    --    DRIVE_FIXED=3,
    --    DRIVE_REMOTE=4,
    --    DRIVE_CDROM=5,
    --    DRIVE_RAMDISK=6,
    --    GETDRIVEINFO_ERROR_UNKNOWN=7

    atom lpPathName,pui64FreeBytesToCaller,pui64TotalBytes,
         pui64FreeBytes,bool,retv,bdiv
    sequence info

    bdiv=1/BYTE_STANDARD
    lpPathName=allocate_string(drive)
    pui64FreeBytesToCaller=allocate(8)
    pui64TotalBytes=allocate(8)
    pui64FreeBytes=allocate(8)

    bool=c_func(xGetDiskFreeSpaceEx,
         {lpPathName,
          pui64FreeBytesToCaller,
          pui64TotalBytes,
          pui64FreeBytes
         })

    retv=c_func(xGetDriveType,{lpPathName})
    if retv<0 or retv>6 then
      retv=7
    end if
  
    bdiv=bdiv*bool

    info={
          bool,
          peek_pui64_to_atom(pui64FreeBytesToCaller)*bdiv,
          peek_pui64_to_atom(pui64TotalBytes)*bdiv,
          peek_pui64_to_atom(pui64FreeBytes)*bdiv,
          retv
         }

    free(lpPathName)
    free(pui64FreeBytesToCaller)
    free(pui64TotalBytes)
    free(pui64FreeBytes)

    return info
end function



public function GetDrivesInfo()  --get info on all logical drives in the system
    --Usage example:
    --printf(1, "%s\n\n",{"Drive  Status   StatusString   FreeToCaller   Total   DiskType"})
    --for k=1 to length(DrivesInfo) do
    --    printf(1, "%s\t",{DrivesInfo[k][DRIVESINFO_DRIVE_LETTER]})--letter
    --    printf(1, "%d\t",{DrivesInfo[k][DRIVESINFO_READY_STATUS]})--ready=1, not ready=0
    --    printf(1, "%s\t",{DriveStatusStrings[DrivesInfo[k][DRIVESINFO_READY_STATUS]+1]})
    --    printf(1, "%9d  ",{DrivesInfo[k][DRIVESINFO_KBYTES_FREE_TO_CALLER]})--free space available to caller (megabytes)
    --    printf(1, "%9d  ",{DrivesInfo[k][DRIVESINFO_KBYTES_TOTAL]})--total size of drive (megabytes)
    --    printf(1, "%s\n",{DriveTypeStrings[DrivesInfo[k][DRIVESINFO_DISK_TYPE]+1]})
    --end for
    
    sequence drivesinfo,info,drive
    atom bit,retv,pBuff,index,len,size
    atom DriveLetter,BuffSize
    
    BuffSize=25
    pBuff=allocate(BuffSize)
    bit=1
    drivesinfo={}
    --retv=c_func(xGetLogicalDrives,{}) --no longer used.
    retv=c_func(xGetLogicalDriveStrings,{BuffSize,pBuff})
    if retv>BuffSize then
    free(pBuff)
    BuffSize=retv
    pBuff=allocate(BuffSize)
    retv=c_func(xGetLogicalDriveStrings,{BuffSize,pBuff})
    end if
    
    if retv>BuffSize or retv=0 then
        --mbretv=message_box( "Error trying to get logical drive strings",
        --  "GetDrivesInfo.exw",
        --  MB_ICONHAND+MB_TASKMODAL)
        --abort(1)        
    end if
    
    size=retv
    index=0
    for k=1 to 999 do
        if index>=size then
            exit
        end if
        len=c_func(xlstrlen,{pBuff+index})
        drive=peek({pBuff+index,len})
        index=index+length(drive)+1
        info=GetDriveInfo(drive)
        drivesinfo=append(drivesinfo,{drive}&info)
    end for
    
    free(pBuff)    
    return drivesinfo
end function
*/

----------------------------------------------------













/*
public function GetLastDlgError()  -- return last common dialogs error code.
   return c_func(xCommDlgExtendedError,{})
end function


public function GetFileTitle(sequence File)
    atom pFile, pTitle
    atom ok
    sequence Title
    
    pFile = allocate_string(File)
    pTitle = allocate(length(File)+1)
    ok = c_func(xGetFileTitle,{pFile,pTitle,length(File)+1})
    free(pFile)
    
    if ok then
        free(pTitle)
        return -1
    end if
    
    Title = peek({pTitle,length(File)})
    free(pTitle)
    
    return Title[1..find(0,Title)-1]
end function
*/



/*
--File associations: from tinAndi
 
constant   
  ASSOCF_NONE                  = #00000, 
  ASSOCF_INIT_NOREMAPCLSID     = #00001, 
  ASSOCF_INIT_BYEXENAME        = #00002, 
  ASSOCF_OPEN_BYEXENAME        = #00002, 
  ASSOCF_INIT_DEFAULTTOSTAR    = #00004, 
  ASSOCF_INIT_DEFAULTTOFOLDER  = #00008, 
  ASSOCF_NOUSERSETTINGS        = #00010, 
  ASSOCF_NOTRUNCATE            = #00020, 
  ASSOCF_VERIFY                = #00040, 
  ASSOCF_REMAPRUNDLL           = #00080, 
  ASSOCF_NOFIXUPS              = #00100, 
  ASSOCF_IGNOREBASECLASS       = #00200, 
  ASSOCF_INIT_IGNOREUNKNOWN    = #00400, 
  ASSOCF_INIT_FIXED_PROGID     = #00800, 
  ASSOCF_IS_PROTOCOL           = #01000, 
  ASSOCF_INIT_FOR_FILE         = #02000 
  
enum   
  ASSOCSTR_COMMAND = 1, 
  ASSOCSTR_EXECUTABLE, 
  ASSOCSTR_FRIENDLYDOCNAME, 
  ASSOCSTR_FRIENDLYAPPNAME, 
  ASSOCSTR_NOOPEN, 
  ASSOCSTR_SHELLNEWVALUE, 
  ASSOCSTR_DDECOMMAND, 
  ASSOCSTR_DDEIFEXEC, 
  ASSOCSTR_DDEAPPLICATION, 
  ASSOCSTR_DDETOPIC, 
  ASSOCSTR_INFOTIP, 
  ASSOCSTR_QUICKTIP, 
  ASSOCSTR_TILEINFO, 
  ASSOCSTR_CONTENTTYPE, 
  ASSOCSTR_DEFAULTICON, 
  ASSOCSTR_SHELLEXTENSION, 
  ASSOCSTR_DROPTARGET, 
  ASSOCSTR_DELEGATEEXECUTE, 
  ASSOCSTR_SUPPORTED_URI_PROTOCOLS, 
  ASSOCSTR_MAX 
   

atom shwl=open_dll("shlwapi.dll") 
if shwl<0  then 
    puts(1,"shlwapi.dll not found!\n") 
    any_key() 
    abort(1) 
end if 
 
atom getassoc=define_c_func(shwl,"AssocQueryStringA",{C_INT,C_INT,C_POINTER,C_POINTER,C_POINTER,C_POINTER},C_POINTER) 
if getassoc<0  then 
    puts(1,"AssocQueryStringA no found!\n") 
    any_key() 
    abort(1) 
end if
 
function GetAssoc(atom flag1,atom flag,sequence assoc,sequence extra) 
atom pzbuffer,pbuffer_size 
sequence result 
atom text=allocate_string(assoc) 
atom addon=allocate_string(extra) 
 
    pzbuffer=allocate(260) 
    pbuffer_size=allocate(4) 
    poke4(pbuffer_size,260) 
    poke4(pzbuffer,0) 
        c_func(getassoc,{flag1,flag,text,addon,pzbuffer,pbuffer_size}) 
    result = peek_string(pzbuffer) 
    free(pzbuffer) 
    free(pbuffer_size) 
    free(text) 
    free(addon) 
    return result 
 
end function 
 
--example = GetAssoc(ASSOCF_NONE,ASSOCSTR_EXECUTABLE,".png","open")&"\n") 
*/







