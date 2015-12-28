-- This file is part of redylib
-- <http://redy-project.org/>
-- 
-- Copyright 2015 Ryan W. Johnson
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




public include win32const.e

include std/os.e
include std/dll.e
include std/machine.e
include std/math.e
include std/error.e
include std/sequence.e
include std/convert.e

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
    xSelectClipPath, xCreateRectRgn, xSelectClipRgn, xGetDeviceCaps, xSetBkColor, xSetBkMode, xGetBkColor, xGetTextExtentPoint, xSetTextColor, xTextOut, xCreateFont,
    xBeginPath, xEndPath, xAbortPath, xStrokePath, xFillPath, xStrokeAndFillPath

public atom xBitBlt, xScrollDC, xArc, xLineTo, xMoveToEx, xPolyBezier, xPolyBezierTo, xPolyLine, xPolyLineTo, xPolyPolyLine, xChord, xEllipse,
    xFillRect, xFrameRect, xInvertRect, xPie, xPolygon, xPolyPolygon, xRectangle, xRoundRect, xSetPixelV, xGetPixel, xGetBitmapDimensionEx

public atom xGetPolyFillMode, xSetPolyFillMode, xCreateSolidBrush, xCreateHatchBrush, xDeleteObject, xCreatePen, xGetCurrentObject

public atom xChangeClipboardChain,xCloseClipboard, xCountClipboardFormats, xEmptyClipboard, xEnumClipboardFormats, xGetClipboardData, 
    xGetClipboardFormatName, xGetClipboardOwner, xGetClipboardViewer, xGetOpenClipboardWindow, xGetPriorityClipboardFormat, xIsClipboardFormatAvailable,
    xOpenClipboard, xRegisterClipboardFormat, xSetClipboardData, xSetClipboardViewer, xGlobalAlloc, xGlobalFree, xDeleteMetaFile, xGlobalLock, xGlobalUnlock
 
public atom xClientToScreen, xSetMapMode, xGetMapMode, xDPtoLP, xTrackMouseEvent, xSetCapture, xReleaseCapture, xGetCapture

public atom xGetOpenFileName, xGetSaveFileName, xCommDlgExtendedError, xGetFileTitle, xBrowseForFolder, xShellExecute

public atom xGetLogicalDriveStrings, xlstrlen, xGetDiskFreeSpaceEx, xGetDriveType
    
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
	atom user32, gdi32, winmm, kernel32, comdlg32, shell32
	
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
    
    xCreateCompatibleDC = link_c_func(gdi32, "CreateCompatibleDC", {C_HANDLE}, C_HANDLE)    
    xCreateCompatibleBitmap = link_c_func(gdi32, "CreateCompatibleBitmap", {C_HANDLE, C_INT, C_INT}, C_HANDLE)
    --xCreateDIBitmap = link_c_func(gdi32, "CreateDIBitmap", {C_POINTER, C_POINTER, C_LONG, C_LONG, C_POINTER, C_LONG}, C_LONG )
    xSelectObject = link_c_func(gdi32, "SelectObject", {C_HANDLE, C_HANDLE}, C_HANDLE)
    xGetObject = link_c_func(gdi32, "GetObjectA", {C_HANDLE, C_INT, C_POINTER}, C_INT)
    -- Bitmaps
    xSelectClipPath = link_c_func(gdi32, "SelectClipPath", {C_HANDLE, C_INT}, C_BOOL)
    --xCreateRectRgn = link_c_func(gdi32, "CreateRectRgn", {C_INT, C_INT, C_INT, C_INT}, C_HANDLE)
    --xSelectClipRgn =  link_c_func(gdi32, "SelectClipRgn", {C_HANDLE, C_HANDLE}, C_INT)
    --xSelectClipPath = 
    xBitBlt = link_c_func(gdi32, "BitBlt", {C_HANDLE, C_INT, C_INT, C_INT, C_INT, C_HANDLE, C_INT, C_INT, C_DWORD}, C_BOOL)
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
    xBrowseForFolder = link_c_func(shell32, "SHBrowseForFolderA", {C_POINTER}, C_ULONG)
    xShellExecute = link_c_func(shell32, "ShellExecuteA", {C_HWND, C_POINTER, C_POINTER, C_POINTER, C_POINTER, C_INT}, C_HWND)

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



---
----------------

public function rgb(atom r, atom g, atom b)
    return r + g * 256 + b * 65536
end function


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



global function get_sys_color(atom color)
    return rgb(128,128,128) --getSysColor(color)
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
    atom void = c_func(xSetCapture, {hwnd})
    MouseCaptured = 1
end procedure

global procedure release_mouse()
    if MouseCaptured > 0 then
        MouseCaptured = 0
        atom void = c_func(xReleaseCapture, {})
    end if
end procedure
















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


--** from tinewg
-- Starts or open the given program, file or directory, using the given parameters,
-- if any. Not-executable files can be run directly, but only if their extension is already associated with an executable application.
-- Note that this procedure DOES NOT change the working directory to the one of the started application;
-- should it be necessary to change working directory, just use the Euphoria function chdir() before calling this procedure.
--
-- [sequence program] is the complete pathname of the program or file to run\\
-- [sequence parameters] are the parameters to use when running the specified program\\
-- 


public procedure RunApp(atom WinHwnd, sequence appname, sequence parameter)
    atom result,szapp,szpara,szaction
    --RunApp_old(appname,parameter)
    -- in Shell32.dll ShellExecuteA
    --HINSTANCE ShellExecute(
    --  __in_opt    HWND hwnd,
    --  __in_opt    LPCTSTR lpOperation,
    --  __in        LPCTSTR lpFile,
    --  __in_opt    LPCTSTR lpParameters,
    --  __in_opt    LPCTSTR lpDirectory,
    --  __in        INT nShowCmd
    --);
    szaction=allocate_string("open")
    szapp=allocate_string(appname)
    szpara=allocate_string(parameter)
    result=c_func(xShellExecute,{WinHwnd,szaction,szapp,szpara,0,SW_SHOWNORMAL})
    free(szaction)
    free(szpara)
    free(szapp)
end procedure







/*
-------------------------------------------------
--
-- Memory Sharing Library
-- Version: 3.3
-- Created by: Jason Mirwald and Mario Steele
-- Emails: mirwalds@prodigy.net -- systemcrashalpha@yahoo.com
--
-------------------------------------------------

without warning

-------------------------------------------------
-- C Types
-------------------------------------------------

constant
    C_LONG = #01000004,
    C_ULONG = #02000004

-------------------------------------------------
-- kernel32 Definations
-------------------------------------------------

constant
 kernel32 = machine_func( 50, "kernel32.dll" ),

 xGetLastError = machine_func( 51, {kernel32, "GetLastError", {}, C_ULONG}),
 xCloseHandle = machine_func( 51, {kernel32, "CloseHandle", {C_ULONG}, C_ULONG}),
 xCreateFileMapping = machine_func( 51, {kernel32, "CreateFileMappingA", {C_LONG,C_LONG,C_ULONG,C_ULONG,C_ULONG,C_LONG}, C_ULONG}),
 xMapViewOfFile = machine_func( 51, {kernel32, "MapViewOfFile", {C_LONG,C_ULONG,C_ULONG,C_ULONG,C_ULONG}, C_ULONG}),
 xUnmapViewOfFile = machine_func( 51, {kernel32, "UnmapViewOfFile", {C_ULONG}, C_ULONG}),
 xOpenFileMapping = machine_func( 51, {kernel32, "OpenFileMappingA", {C_ULONG,C_LONG,C_LONG}, C_ULONG})

sequence 
    strHandles,
    smHandles,
    smPointers

strHandles = {}
smHandles = {}
smPointers = {}

global constant
   SM_CREATE_EXIST = -1,
   SM_CREATE_FAIL = -2,
   SM_OPEN_FAIL = -3,
   SM_MEM_FAIL = -4

-------------------------------------------------

global function sm_create(sequence strHandle, atom size)
   atom lpszHandle, wHandle, lPointer, VOID, error
   VOID = find(strHandle,strHandles)
   if VOID then
      return smPointers[VOID]
   end if
   lpszHandle = machine_func(16, length(strHandle)+1)
   if lpszHandle > 0 then
      poke(lpszHandle,strHandle)
      poke(lpszHandle+length(strHandle),0)
      wHandle = c_func(xCreateFileMapping, {-1,0,#4,0,size,lpszHandle})
      machine_proc(17,lpszHandle)
      if wHandle > 0 then
         error = c_func( xGetLastError, {} )
         if error = 0 then
            lPointer = c_func(xMapViewOfFile,{wHandle,#F001F,0,0,0})
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

-----------------------------------------------------------------

global function sm_open(sequence strHandle)
   atom lpszHandle, wHandle, lPointer, VOID
   VOID = find(strHandle,strHandles)
   if VOID then
      return smPointers[VOID]
   end if
   lpszHandle = machine_func(16, length(strHandle)+1)
   if lpszHandle > 0 then
      poke(lpszHandle,strHandle)
      poke(lpszHandle+length(strHandle),0)
      wHandle = c_func(xOpenFileMapping,{#F001F,0,lpszHandle})
      machine_proc(17,lpszHandle)
      if wHandle > 0 then
         lPointer = c_func(xMapViewOfFile,{wHandle,#F001F,0,0,0})
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

-------------------------------------------------

global procedure sm_close(object smPointer)
   atom ack, VOID
   if sequence(smPointer) then
      VOID = find(smPointer,strHandles)
   else
      VOID = find(smPointer,smPointers)
   end if
   if VOID then
    ack = c_func(xUnmapViewOfFile,{smPointers[VOID]})
    ack = c_func(xCloseHandle,{smHandles[VOID]})
    strHandles = strHandles[1..VOID-1] & strHandles[VOID+1..length(strHandles)]
    smHandles = smHandles[1..VOID-1] & smHandles[VOID+1..length(smHandles)]
    smPointers = smPointers[1..VOID-1] & smPointers[VOID+1..length(smPointers)]
   end if
end procedure

-------------------------------------------------

global function sm_alloc_lpsz(sequence strHandle, sequence string)
    atom lPointer
    lPointer = sm_create(strHandle,length(string)+1)
    if lPointer > 0 then
        poke(lPointer,string)
        poke(lPointer+length(string),0)
    end if
    return lPointer
end function
*/


