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


--Interface Library for Microsoft Windows API
--Written by Ryan Johnson
--http://redy-project.org/
--Some of this code is loosely based on win32lib:
-- * Long lists of constants and dll function links have been copied and then modified, rather than typing them up from scratch
-- * Some small support functions such as codeToBytes(), rgb(), etc. have been copied
-- * A few routines, such as createMousePointer(), etc. are copied and modified to not use any win32lib resource management.
-- * Most of the time, I simply looked at win32lib code to see examples of how to access windows api


include std/os.e
include std/dll.e
include std/machine.e
include std/math.e
include std/error.e
include std/sequence.e
include std/task.e
include std/text.e
include std/pretty.e

include redy_images.e as redyimg

public include win32dll.e
export atom ScreenX = 1920, ScreenY = 1200 --temporary

atom started = 0, mainwin, MainTimer = 0, ScrollTimer = 0, CursorTimer = 0,
UseMainTimer = 1, MenuActive = 0, WindowFocus = 0, WindowModal = 0,
BitmapDC, hdc, hPen = 0, hBrush = 0, hFont = 0,
penX = 0, penY = 0, PenStyle = PS_SOLID, PenWidth = 1, PenColor = 0,
BrushStyle = BS_SOLID, BrushHatch = 0, BrushColor = 0,
FontSize = 12, FontBold = 0, FontItalic = 0, FontUnderline = 0, FontStrikeout = 0,
GlobalBusy = 0, LastMouseCursor = 0, ImagesLoaded = 0
sequence FontName = "Arial", whandles = {}, LastMousePos = {0, 0}
object VOID

sequence
windowList = {},
windowDCs = {},
windowBitmaps = {},
windowBackColor = {},
windowNeedRefresh = {}, --0=no 1=yes 2=disable
windowOwner = {},       --id of widget that created the window
windowCloseAllow = {},  --routine to call on close event (if 0, then just close window)
windowModalOverride = {}, --allow window to ignore modal blocking (used for debug console and error dialogs)
windowEvents = {},      --all windows events are combined in one buffer
windowCursor = {},
windowStyle = {},
windowTrackCursor = {},
--windowRects = {}        --keep track of window rect when WM_MOVE or WM_SIZE messages are received

InvalidatedWindows = {}  --windows that have been invalidated (the os needs to update the window bitmap)


public procedure window_add_event(atom winid, sequence evtype, object evdata)
    if winid > 0 then
        atom widx = find(winid, windowList)
        if widx > 0 and (WindowModal = 0 or WindowModal = winid
        or equal(evtype, "Resize") or equal(windowStyle[widx], "popup") or windowModalOverride[widx] = 1) then
            windowEvents &= {{winid, evtype, evdata}}
        end if
    end if
end procedure


public function window_get_event()
    object ev = 0
    
    if length(windowEvents) > 0 then
        ev = windowEvents[1]
        windowEvents = windowEvents[2..$]
    end if
    return ev
end function


public procedure close_all_popups(sequence dbug)
    for w = 1 to length(windowList) do
        if equal(windowStyle[w], "popup") then
            window_add_event(windowList[w], "Close", {})
        end if
    end for
end procedure


atom msg = allocate(SIZE_OF_MESSAGE)


-- callback routine to handle Window class
function WndProc(atom hwnd, atom iMsg, atom wParam, atom lParam)
    atom widx = find(hwnd, windowList), ptrPs, hdc
    sequence params
    object rect
    
    params = { 
        short_int(lo_word(wParam)),
        short_int(hi_word(wParam)),
        short_int(lo_word(lParam)),
        short_int(hi_word(lParam))
    }
    
    switch iMsg do
        case WM_CREATE then
            
        case WM_SHOWWINDOW then
            
        case WM_PAINT then
            if widx > 0 then
                ptrPs = allocate(
                    szUInt --HDC  hdc;
                    + szByte --BOOL fErase;
                    + szLong * 4 --RECT rcPaint;
                    + szByte --BOOL fRestore;
                    + szByte --BOOL fIncUpdate;
                    + szByte * 32 --BYTE rgbReserved[32];
                )
                --ptrRect = allocate(szLong * 4)
                --c_proc(xGetClientRect, {hwnd, ptrRect})
                --VOID = c_func(xGetUpdateRect, {hwnd, ptrRect, 0}) --(_In_   HWND hWnd,  _Out_  LPRECT lpRect,  _In_   BOOL bErase)
                --rect = peek4u({ptrRect,4}) --{RECT_Left, RECT_Top, RECT_Right, RECT_Bottom}
                
                hdc = c_func(xBeginPaint, {hwnd, ptrPs})
                if hdc = 0 then
                    --puts(1, "error: BeginPaint\n")
                end if
                rect = peek4u({ptrPs + szUInt + szLong , 4}) --get update rect
                VOID = c_func(xBitBlt, {hdc, rect[RECT_Left], rect[RECT_Top], rect[RECT_Right], rect[RECT_Bottom], 
                                        windowDCs[widx], rect[RECT_Left], rect[RECT_Top], SRCCOPY})
                if VOID != 1 then
                    puts(1, "error: BitBlit\n")
                end if
                
                -------
                /*
                atom hPen = c_func(xCreatePen, {PenStyle, PenWidth, rgb(255, 100, 100)})
                VOID = c_func(xSelectObject, {hdc, hPen})
                atom hBrush = c_func(xGetStockObject, {HOLLOW_BRUSH})
                VOID = c_func(xSelectObject, {hdc, hBrush})
                VOID = c_func(xRectangle, {hdc, rect[RECT_Left], rect[RECT_Top], rect[RECT_Right], rect[RECT_Bottom]})
                c_proc(xDeleteObject, {hPen})
                c_proc(xDeleteObject, {hBrush})
                */
                ------
                
                --? {rect[RECT_Left], rect[RECT_Top], rect[RECT_Right], rect[RECT_Bottom]}
                
                c_proc(xEndPaint, {hwnd, ptrPs})
                
                free({ptrPs})
                
                if equal(windowStyle[widx], "popup") then
                    MenuActive = 0
                end if
                return 0
            end if
            
        case WM_ERASEBKGND then
            --return 1
        
        case WM_SIZE then    
            if widx > 0 then
                --get size of old bitmap
                atom bm = allocate(SIZEOF_BITMAP)
                atom objsz = c_func(xGetObject, {windowBitmaps[widx], SIZEOF_BITMAP, bm})
                if objsz = 0 or objsz != SIZEOF_BITMAP then
                    puts(1, "DR_Image Error: GetObject hBitmap")
                end if
                atom oldWidth = peek4s(bm + szLong)
                atom oldHeight = peek4s(bm + szLong + szLong)
                free(bm)
                
                --delete old bitmap, create new one
                hdc = c_func(xGetDC, {windowList[widx]})
            	c_proc(xDeleteObject, {windowBitmaps[widx]})
                windowBitmaps[widx] = c_func(xCreateCompatibleBitmap, {hdc, params[3], params[4]})
                
                --if new bitmap is larger than old bitmap, fill with backgroudn color
                if params[3] > oldWidth or params[4] > oldHeight then
                    atom hPen = c_func(xCreatePen, {PenStyle, PenWidth, windowBackColor[widx]})
                    VOID = c_func(xSelectObject, {hdc, hPen})
                    atom hBrush = c_func(xCreateSolidBrush, {windowBackColor[widx]})
                    VOID = c_func(xSelectObject, {hdc, hBrush})
                    if params[3] > oldWidth then
                        VOID = c_func(xRectangle, {hdc, oldWidth, 0, params[3], params[4]})
                    end if
                    if params[4] > oldHeight then
                        VOID = c_func(xRectangle, {hdc, 0, oldHeight, params[3], params[4]})
                    end if
                    c_proc(xDeleteObject, {hPen})
                    c_proc(xDeleteObject, {hBrush})
                end if
                
                VOID = c_func(xReleaseDC, {windowList[widx], hdc})
                
                window_add_event(hwnd, "Resize", {params[3], params[4]})
                return 1
            end if
            
        case WM_MOVE then
            window_add_event(hwnd, "Move", {params[3], params[4]})
            
    	case WM_CLOSE then
            if windowCloseAllow[widx] = 1 and (WindowModal = 0 or WindowModal = hwnd) then
                window_add_event(hwnd, "Close", {})
            elsif windowCloseAllow[widx] = 0 then
                window_add_event(hwnd, "Close", {})
                return 1
            end if
            
    	case WM_DESTROY then
            if widx > 0 then
                VOID = c_func(xDeleteDC, {windowDCs[widx]})
                c_proc(xDeleteObject, {windowBitmaps[widx]})
                atom wowner = windowOwner[widx]
                
                windowList = remove(windowList, widx)
                --destroy(windowBuffers[locwin])
                windowDCs = remove(windowDCs, widx)
                windowBitmaps = remove(windowBitmaps, widx)
                windowBackColor = remove(windowBackColor, widx)
                windowNeedRefresh = remove(windowNeedRefresh, widx)
                windowOwner = remove(windowOwner, widx)
                windowCloseAllow = remove(windowCloseAllow, widx)
                windowModalOverride = remove(windowModalOverride, widx)
                windowCursor = remove(windowCursor, widx)
                windowStyle = remove(windowStyle, widx)
                windowTrackCursor = remove(windowTrackCursor, widx)
                
                if WindowModal = hwnd then
                    WindowModal = 0
                end if
                if wowner = 1 then --or widx = 1 then
                    --c_proc(xPostQuitMessage, {0}) ???
                    abort(0)
                end if
            end if
                
    	case WM_ACTIVATE then
            --params[1] value:
            --  WA_ACTIVE = 1 : Activated by some method other than a mouse click
            --    (for example, by a call to the SetActiveWindow function or by use of the keyboard interface to select the window).
            --  WA_CLICKACTIVE = 2 : Activated by a mouse click.
            --  WA_INACTIVE = 0 : Deactivated.
    	    --printf(1, "WM_ACTIVATE: {%d,%d,%d,%d,%d}\n", {widx, params[1], params[2], params[3], params[4]})        
            
        case WM_MOUSEMOVE then
            if widx > 0 then
                LastMouseCursor = windowCursor[widx]
                if WindowModal = 0 or WindowModal = hwnd or equal(windowStyle[widx], "popup") or windowModalOverride[widx] = 1 then
                    if GlobalBusy = 1 then
                        VOID = c_func(xSetCursor, {mBusy})
                    else
                        VOID = c_func(xSetCursor, {windowCursor[widx]})
                    end if
                else
                    VOID = c_func(xSetCursor, {mNo})
                end if
                if windowTrackCursor[widx] = 0 then
                    windowTrackCursor[widx] = 1
                    TrackMouseEvent(hwnd)
                end if
            end if
            LastMousePos = {params[3], params[4]}
            window_add_event(hwnd, "MouseMove", {params[3], params[4], 0, params[3], params[4]})
            
        case WM_LBUTTONDOWN then
            window_add_event(hwnd, "LeftDown", {params[3], params[4], params[1], params[2]})
            
        case WM_LBUTTONUP then
            window_add_event(hwnd, "LeftUp", {params[3], params[4], params[1], params[2]})
            release_mouse()
            
        case WM_LBUTTONDBLCLK then
            window_add_event(hwnd, "LeftDoubleClick", {params[3], params[4], params[1], params[2]})
            
        case WM_RBUTTONDOWN then
            window_add_event(hwnd, "RightDown", {params[3], params[4], params[1], params[2]})
            
        case WM_RBUTTONUP then
            window_add_event(hwnd, "RightUp", {params[3], params[4], params[1], params[2]})
            release_mouse()
            
        case WM_RBUTTONDBLCLK then
            window_add_event(hwnd, "RightDoubleClick", {params[3], params[4], params[1], params[2]})
            
        case WM_MBUTTONDOWN then
            window_add_event(hwnd, "MiddleDown", {params[3], params[4], params[1], params[2]})
            
        case WM_MBUTTONUP then
            window_add_event(hwnd, "MiddleUp", {params[3], params[4], params[1], params[2]})
            release_mouse()
            
        case WM_MBUTTONDBLCLK then
            window_add_event(hwnd, "MiddleDoubleClick", {params[3], params[4], params[1], params[2]})
            
        case WM_MOUSEWHEEL then
            window_add_event(hwnd, "WheelMove", {params[1], sign(params[2]), params[3], params[4]})
            for w = 1 to length(windowList) do
                if equal(windowStyle[w], "popup") then
                    window_add_event(windowList[w], "WheelMove", {params[1], sign(params[2]), params[3], params[4]})
                end if
            end for
            
        case WM_NCHITTEST then
        	
        case WM_SETCURSOR then
          	
        case WM_NCMOUSEMOVE then
        	window_add_event(hwnd, "NonClientMouseMove", {params[3], params[4], params[3], params[4]})
            
        case WM_MOUSEACTIVATE then
            if equal(windowStyle[widx], "popup") then
                MenuActive = 1
                window_add_event(hwnd, "LeftDown", {LastMousePos[1], LastMousePos[2], LastMousePos[1], LastMousePos[2]})
            end if
        	
        case WM_NCACTIVATE then
            if widx > 0 then
                if MenuActive = 1 and not equal(windowStyle[widx], "popup") then
                    return 0
                end if
        	end if
        	
        case WM_KEYDOWN then    
            window_add_event(hwnd, "KeyDown", {params[1], params[2], params[3], params[4]})
            
        case WM_KEYUP then
            window_add_event(hwnd, "KeyUp", {params[1], params[2], params[3], params[4]})
            
        case WM_CHAR then
            window_add_event(hwnd, "KeyPress", {params[1], params[2], params[3], params[4]})
            
        case WM_SETFOCUS then
            WindowFocus = hwnd
            window_add_event(hwnd, "GotFocus", {params[1], params[2], params[3], params[4]})
        	close_all_popups("7")
            
        case WM_KILLFOCUS then
            WindowFocus = 0
            window_add_event(hwnd, "LostFocus", {params[1], params[2], params[3], params[4]})
            
        case WM_ACTIVATEAPP then
        	if params[1] = 0 then
                close_all_popups("8")
            end if
            
        case WM_ENTERSIZEMOVE then
            task_schedule(task_oswin, 1)
            close_all_popups("9")
            
        case WM_EXITSIZEMOVE then
            task_schedule(task_oswin, 10)
            
        case WM_MOUSELEAVE then --Posted to a window when the cursor leaves the client area of the window specified in a prior call to TrackMouseEvent
            if widx > 0 then
                windowTrackCursor[widx] = 0
                window_add_event(hwnd, "MouseMove", {-10, -10, 0, 0})
            end if
            
        case WM_TIMER then
            if params[1] = 1 and UseMainTimer then
                task_yield()
            else
                window_add_event(hwnd, "Timer", {params[1]})
            end if
            
        case else
            
    end switch
	return c_func(xDefWindowProc, {hwnd, iMsg, wParam, lParam})
end function


atom task_oswin


public procedure win_main()
    while 1 do
        if c_func(xGetMessage, {msg, NULL, 0, 0}) then
        --if c_func(xPeekMessage, {msg, NULL, 0, 0, 1}) then
            c_proc(xTranslateMessage, {msg})
            c_proc(xDispatchMessage, {msg})
        end if
        task_yield()
    end while
end procedure


public procedure start()
	atom hwnd, class, hdc, id, WndProcAddress, icon_handle
	
	if started then
	   return
	end if
	started = 1
    link_dll_routines()
	id = routine_id("WndProc")
	if id = -1 then
		crash("routine_id failed!")
	end if
	WndProcAddress = call_back(id) -- get address for callback
	--icon_handle = c_func(xLoadIcon, {instance(), allocate_string("eui")})
	
	class = RegisterClassEx(	
        SIZE_OF_WNDCLASS,
        or_all({CS_HREDRAW, CS_VREDRAW, CS_DBLCLKS}),
        WndProcAddress,
        0,
        0,
        0,
        NULL, --icon_handle,
        NULL, --c_func(xLoadCursor, {NULL, IDC_ARROW}),
        NULL, /*c_func(xGetStockObject, {WHITE_BRUSH}),*/ 
        "",
        "AppWindow",
        NULL --icon_handle
    )
	if class = 0 then
		crash("Couldn't register AppWindow class")
	end if
	
	class = RegisterClassEx(
        SIZE_OF_WNDCLASS,
        or_all({CS_HREDRAW, CS_VREDRAW, CS_DROPSHADOW, CS_SAVEBITS}),
        WndProcAddress,
        0,
        0,
        0,
        NULL, --icon_handle,
        NULL, --c_func(xLoadCursor, {NULL, IDC_ARROW}),
        NULL, --c_func(xGetStockObject, {WHITE_BRUSH}),
        "",
        "MenuWindow",
        NULL --icon_handle
    )
	if class = 0 then
		crash("Couldn't register MenuWindow class")
	end if
	
	--Create Main window
	hwnd = CreateWindowEx(
		0,                       -- extended style
		"AppWindow",               -- window class name
		"Main Window",                -- window caption
		or_all({WS_OVERLAPPEDWINDOW}),     -- window style
		1000,                          --CW_USEDEFAULT,           -- initial x position
		50,           -- initial y position
		600,           -- initial x size
		350,           -- initial y size
		HWND_MESSAGE,                    -- parent window handle
		NULL,                    -- window menu handle
		0 ,                 --hInstance // program instance handle
		NULL              -- creation parameters
    )
	if hwnd = 0 then
		crash("Couldn't CreateWindow")
	end if
	
    load_mouse_cursors()
    
	mainwin = hwnd
    hdc = c_func(xGetDC, {hwnd})
    --BitmapDC = c_func(xCreateCompatibleDC, {hdc})
	--ClipScreenDC = c_func(xCreateCompatibleDC, {hdc})
	--ClipScreenBM = c_func(xCreateCompatibleBitmap, {hdc, ScreenX, ScreenY})
    VOID  = c_func(xReleaseDC, {hwnd, hdc})
    MainTimer = c_func(xSetTimer, {hwnd, 1, 1, NULL})
    task_oswin = task_create(routine_id("win_main"), {})
    task_schedule(task_oswin, 10)
end procedure


--procedure drawWindow(atom winid)
--  copyBlt(winid, 0, 0, windowBuffers[find(winid, windowList)])
--end procedure


--procedure drawWindowPartial(atom winid, integer srcX, integer srcY, integer wide, integer high)
--  bitBlt(winid, srcX, srcY, windowBuffers[find(winid, windowList)], srcX, srcY, wide, high, SrcCopy)
--end procedure


public function create_window(atom wid, sequence wtitle, object wstyle, atom wleft, atom wtop, atom wwidth, atom wheight, atom wbackcolor, atom wparent = 0)
    atom winstyle, winexstyle, hWnd, hdc, memdc, hbit, ptrRect
    sequence winclass, rect
    
    switch wstyle do
        case "normal" then
            winstyle = or_all({WS_OVERLAPPEDWINDOW})
            winexstyle = 0
            winclass = "AppWindow"
        case "noborder" then
            winstyle = or_all({WS_POPUP})
            winexstyle = 0
            winclass = "AppWindow"
        case "notitlebar" then
            winstyle = or_all({WS_POPUP, WS_THICKFRAME})
            winexstyle = 0
            winclass = "AppWindow"
        case "noresize" then
            winstyle = or_all({WS_POPUP, WS_NO_RESIZE})
            winexstyle = 0
            winclass = "AppWindow"
        case "popup" then
            winstyle = or_all({WS_POPUP})
            winexstyle = or_all({WS_EX_TOPMOST,WS_EX_NOACTIVATE})
            winclass = "MenuWindow"
        case "tool" then
            winstyle = or_all({WS_OVERLAPPEDWINDOW})
            winexstyle = or_all({WS_EX_TOPMOST, WS_EX_NOACTIVATE, WS_EX_TOOLWINDOW})
            winclass = "AppWindow"
        case else
            winstyle = or_all({WS_OVERLAPPEDWINDOW})
            winexstyle = 0
            winclass = "AppWindow"
    end switch
    
    hWnd = CreateWindowEx(
		winexstyle,  -- extended style
		winclass,    -- window class name
		wtitle,      -- window caption
		winstyle,    -- window style
		wleft,       -- initial x position
		wtop,        -- initial y position
		wwidth,      -- initial x size
		wheight,     -- initial y size
		NULL,     -- parent window handle
		NULL,        -- window menu handle
		0 ,          --hInstance // program instance handle
		NULL)        -- creation parameters
	
	if hWnd = 0 then
		crash("Couldn't Create Window")
	end if
	
    hdc = c_func(xGetDC, {hWnd})
	memdc = c_func(xCreateCompatibleDC, {hdc})
	hbit = c_func(xCreateCompatibleBitmap, {hdc, ScreenX, ScreenY})
    VOID = c_func(xReleaseDC, {hWnd, hdc})

    windowList &= hWnd
    windowDCs &= memdc
    windowBitmaps &= hbit
    windowBackColor &= wbackcolor
    windowNeedRefresh &= 2
    windowOwner &= wid
    windowCloseAllow &= 0
    windowModalOverride &= 0
    windowCursor &= mArrow
    windowStyle &= {wstyle}
    windowTrackCursor &= 0
    
    ScrollTimer = c_func(xSetTimer, {hWnd, 2, 10, NULL})
    CursorTimer = c_func(xSetTimer, {hWnd, 3, 500, NULL})
    TrackMouseEvent(hWnd)
    
    if equal(wstyle, "popup") then
        MenuActive = 1
    end if
    
    if ImagesLoaded = 0 then
        ImagesLoaded = 1
        redyimg:load_images(hWnd)
    end if
    
    return hWnd
end function


public procedure destroy_window(atom hWnd)
    atom widx = find(hWnd, windowList)
    
    if widx > 0 then
        VOID = c_func(xDestroyWindow, {hWnd})
    end if
end procedure


public procedure show_window(atom hWnd)
    atom widx = find(hWnd, windowList), ptrRect 
    sequence rect
    
    if widx > 0 then    
        c_proc(xShowWindow, {hWnd, SW_SHOWNORMAL})
    	c_proc(xUpdateWindow, {hWnd})
        ptrRect = allocate(szLong * 4)
        c_proc(xGetClientRect, {hWnd, ptrRect})
        rect = peek4u({ptrRect,4}) --{RECT_Left, RECT_Top, RECT_Right, RECT_Bottom}
        free(ptrRect)
        window_add_event(hWnd, "Resize", {rect[3], rect[4]})
        windowNeedRefresh[widx] = 1
    end if
end procedure


public procedure hide_window(atom hWnd)
    atom widx = find(hWnd, windowList), ptrRect 
    sequence rect
    
    if widx > 0 then
        windowNeedRefresh[widx] = 2
    end if
end procedure


public function get_window_owner(atom hWnd)
    atom widx = find(hWnd, windowList)
    
    if widx > 0 then
        return windowOwner[widx]
    else
        return 0
    end if
end function


public function draw_enabled(atom hWnd)
    atom widx = find(hWnd, windowList)
    
    if widx > 0 then
        if windowNeedRefresh[widx] < 2 then
            return 1
        else
            return 0
        end if
    else
        return 0
    end if
end function


public procedure enable_draw(atom hWnd)
    atom widx = find(hWnd, windowList)
    
    if widx > 0 then
        windowNeedRefresh[widx] = 1
    end if
end procedure


public procedure disable_draw(atom hWnd)
    atom widx = find(hWnd, windowList)
    
    if widx > 0 then
        windowNeedRefresh[widx] = 2
    end if
end procedure


public procedure enable_close(atom hWnd, atom en)
    atom widx = find(hWnd, windowList)
    
    if widx > 0 then
        windowCloseAllow[widx] = en
    end if
end procedure


public function get_enable_close(atom hWnd)
    atom widx = find(hWnd, windowList)
    
    if widx > 0 then
        return windowCloseAllow[widx]
    else
        return 0
    end if
end function


public procedure set_window_title(atom hWnd, sequence title)
    atom widx = find(hWnd, windowList), lpsz
    
    if widx > 0 then
        lpsz = allocate_string(title)
        c_proc(xSetWindowText, {hWnd, lpsz})
        free(lpsz)
    end if
end procedure


public procedure set_window_size(atom hWnd, atom width, atom height) --set window size by client size
    atom widx = find(hWnd, windowList), ptrRect
    sequence wrect, crect, diff
    
    if widx > 0 then
        ptrRect = allocate(szLong * 4)
        c_proc(xGetWindowRect, {hWnd, ptrRect})
        wrect = peek4u({ptrRect,4}) --{RECT_Left, RECT_Top, RECT_Right, RECT_Bottom}
        c_proc(xGetClientRect, {hWnd, ptrRect})
        crect = peek4u({ptrRect,4}) --{RECT_Left, RECT_Top, RECT_Right, RECT_Bottom}
        free(ptrRect)
        -- get current window size and subtract client size
        diff = (wrect[3..4] - wrect[1..2]) - crect[3..4] 
        -- add difference to specified window size
        VOID = c_func(xSetWindowPos, {hWnd, 0, 0, 0, width + diff[1], height + diff[2], SWP_NOMOVE + SWP_NOZORDER})
        window_add_event(hWnd, "Resize", {width + diff[1], height + diff[2]})
    end if
end procedure


public function get_window_size(atom hWnd)
    atom widx = find(hWnd, windowList), ptrRect
    sequence wrect = {0, 0, 0, 0}, diff
    
    if widx > 0 then
        ptrRect = allocate(szLong * 4)
        c_proc(xGetWindowRect, {hWnd, ptrRect})
        wrect = peek4u({ptrRect,4}) --{RECT_Left, RECT_Top, RECT_Right, RECT_Bottom}
        free(ptrRect)
    end if    
    return {wrect[3] - wrect[1], wrect[4] - wrect[2]}
end function


public procedure set_window_pos(atom hWnd, atom x, atom y)
    VOID = c_func(xSetWindowPos, {hWnd, 0, x, y, 0, 0, SWP_NOSIZE + SWP_NOZORDER})
    --HWND hWnd, HWND hWndInsertAfter, int X, int Y, int cx, int cy, UINT uFlags
end procedure


public function get_window_pos(atom hWnd)
    atom widx = find(hWnd, windowList), ptrRect
    sequence wrect = {0, 0, 0, 0}, diff
    
    if widx > 0 then
        ptrRect = allocate(szLong * 4)
        c_proc(xGetWindowRect, {hWnd, ptrRect})
        wrect = peek4u({ptrRect,4}) --{RECT_Left, RECT_Top, RECT_Right, RECT_Bottom}
        free(ptrRect)
    end if    
    return wrect[1..2]
end function


public function client_area_offset(atom hWnd)
	sequence cpos = ClientToScreen(hWnd, {0, 0})
    return cpos
end function


public procedure set_window_topmost(atom hWnd)
    VOID = c_func(xSetWindowPos, {hWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE})
end procedure


public procedure set_window_not_topmost(atom hWnd)
    VOID = c_func(xSetWindowPos, {hWnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE})
end procedure


public procedure set_window_top(atom hWnd)
    VOID = c_func(xSetWindowPos, {hWnd, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE})
end procedure


public procedure set_window_bottom(atom hWnd)
    VOID = c_func(xSetWindowPos, {hWnd, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE})
end procedure


-- Modal window (causes all other windows to ignore keyboard/mouse events
-- and shows a "No" mouse cursor on all windows except on the specified modal window
public procedure set_window_modal(atom hWnd)
    WindowModal = hWnd
    set_window_topmost(hWnd)
end procedure


public function get_window_modal(atom hWnd)
    return WindowModal
end function


public procedure set_window_modal_override(atom hWnd, atom mo) --don't allow modal windows to block specified window (used for debug console and error messages)
    atom widx = find(hWnd, windowList)
    
    if widx > 0 then
        windowModalOverride[widx] = mo
    end if
end procedure


public function get_window_modal_override(atom hWnd)
    atom widx = find(hWnd, windowList)
    
    if widx > 0 then
        return windowModalOverride[widx]
    else
        return 0
    end if
end function


-- Timers -------------------

-- set a timer to go off every uElapse milliseconds
public procedure setTimer(atom hWnd, atom nIDEvent, atom uElapse)
    VOID = c_func(xSetTimer, {hWnd, nIDEvent, uElapse, 0})
end procedure


public procedure killTimer(atom hWnd, atom uIDEvent)
    VOID = c_func(xKillTimer, {hWnd, uIDEvent})
end procedure


-- Mouse ---------------------

public procedure set_global_busy(atom busyornot) --set mouse cursor to "Busy" (or clear) for all fluidae windows
    if busyornot = 1 then
        GlobalBusy = 1
        VOID = c_func(xSetCursor, {mBusy})
    else
        GlobalBusy = 0
        VOID = c_func(xSetCursor, {LastMouseCursor})
    end if
end procedure


public procedure refresh_mouse_pointer(atom hWnd)
    atom widx = find(hWnd, windowList)
    if widx > 0 then
        if GlobalBusy = 1 then
            VOID = c_func(xSetCursor, {mBusy})
        else
            VOID = c_func(xSetCursor, {windowCursor[widx]})
        end if
    end if
end procedure


public procedure set_mouse_pointer(atom hWnd, atom mouseP)
    atom widx = find(hWnd, windowList)
    
    if widx > 0 then
        windowCursor[widx] = mouseP
        LastMouseCursor = mouseP
    end if
end procedure


public function get_mouse_pos()
    return LastMousePos
end function


public function get_window_focus()
    return WindowFocus
end function


-- File Open/Save Dialogs -----------------------

--Used some code from COMMDLG.E by Jacques Deschenes (November 6th, 1997) as a starting point, and adapted pieces of it to work with Redy

-- "Open" and "Save as..." dialogs use a structure named OPENFILENAME
-- the following constant are to access that structure members.

constant
OPENFILENAME_lStructSize = 0,         --4u DWORD        
OPENFILENAME_hwndOwner = 4,           --4u HWND         
OPENFILENAME_hInstance = 8,           --4u HINSTANCE    
OPENFILENAME_lpstrFilter = 12,        --4u LPCTSTR      
OPENFILENAME_lpstrCustomFilter = 16,  --4u LPTSTR       
OPENFILENAME_nMaxCustFilter = 20,     --4u DWORD        
OPENFILENAME_nFilterIndex = 24,       --4u DWORD        
OPENFILENAME_lpstrFile = 28,          --4u LPTSTR       
OPENFILENAME_nMaxFile = 32,           --4u DWORD        
OPENFILENAME_lpstrFileTitle = 36,     --4u LPTSTR       
OPENFILENAME_nMaxFileTitle = 40,      --4u DWORD        
OPENFILENAME_lpstrInitialDir = 44,    --4u LPCTSTR      
OPENFILENAME_lpstrTitle = 48,         --4u LPCTSTR      
OPENFILENAME_Flags = 52,              --4u DWORD        
OPENFILENAME_nFileOffset = 56,        --2u WORD         
OPENFILENAME_nFileExtension = 58,     --2u WORD         
OPENFILENAME_lpstrDefExt = 60,        --4u LPCTSTR      
OPENFILENAME_lCustData = 64,          --4u LPARAM       
OPENFILENAME_lpfnHook = 68,           --4u LPOFNHOOKPROC
OPENFILENAME_lpTemplateName = 72,     --4u LPCTSTR      

OPENFILENAME_ofn_struc_size = 76


public function GetOpenFileName(atom hwnd, sequence Filter, atom allowmultiselect = 0)
    atom pFilter, pOFN, pFileName
    atom OK, strlen = 2048, ofnFlags
    sequence FileName
    object retval
    
    pFilter = allocate_string(Filter)
    pOFN = allocate_data(OPENFILENAME_ofn_struc_size)
    pFileName = allocate_data(strlen)
    ofnFlags = OFN_EXPLORER + OFN_PATHMUSTEXIST + OFN_FILEMUSTEXIST
    if allowmultiselect = 1 then
        ofnFlags += OFN_ALLOWMULTISELECT
    end if
    mem_set(pFileName, 0, strlen)
    mem_set(pOFN, 0, OPENFILENAME_ofn_struc_size)
    poke4(pOFN+OPENFILENAME_lStructSize, OPENFILENAME_ofn_struc_size)
    poke4(pOFN+OPENFILENAME_hwndOwner, hwnd)
    poke4(pOFN+OPENFILENAME_lpstrFile, pFileName)
    poke4(pOFN+OPENFILENAME_nMaxFile, strlen)
    poke4(pOFN+OPENFILENAME_lpstrFilter, pFilter)
    poke4(pOFN+OPENFILENAME_nFilterIndex, 1)
    poke4(pOFN+OPENFILENAME_Flags, ofnFlags)
    
    UseMainTimer = 0
    OK = c_func(xGetOpenFileName, {pOFN})
    UseMainTimer = 1
    
    free(pOFN)
    free(pFilter)
    
    if not OK then
        free(pFileName)
        retval = -1
    else
        FileName = peek({pFileName, strlen})
        free(pFileName)
        if allowmultiselect = 1 then
            retval = FileName[1..match({0, 0}, FileName) - 1]
        else
            retval = FileName[1..match({0, 0}, FileName) - 1]
        end if
    end if
    
    return retval
end function


public function GetSaveFileName(atom hwnd, sequence currentName)
    atom pOFN, pFileName
    atom OK
    sequence FileName
    
    pOFN = allocate(OPENFILENAME_ofn_struc_size)
    pFileName = allocate(260)
    mem_set(pFileName, 0, 260)
    poke(pFileName, currentName)
    mem_set(pOFN, 0, OPENFILENAME_ofn_struc_size)
    poke4(pOFN+OPENFILENAME_lStructSize, OPENFILENAME_ofn_struc_size)
    poke4(pOFN+OPENFILENAME_hwndOwner, hwnd)
    poke4(pOFN+OPENFILENAME_lpstrFile, pFileName)
    poke4(pOFN+OPENFILENAME_nMaxFile, 260)
    poke4(pOFN+OPENFILENAME_Flags, OFN_EXPLORER + OFN_PATHMUSTEXIST)
    
    UseMainTimer = 0
    OK = c_func(xGetSaveFileName, {pOFN})
    UseMainTimer = 1
    
    free(pOFN)
    
    if not OK then
        free(pFileName)
        return -1
    else
        FileName = peek({pFileName, 260})
        free(pFileName)
        return FileName[1..find(0, FileName) - 1]
    end if
end function


-- Clipboard ------------------------

public function clipboard_write_txt(atom hWnd, sequence txt) --"cut" or "copy" text to the clipboard. hWnd is a Window handle
    atom lptStr, hglbCopy, lptstrCopy
    
    --Open Clipboard
    if c_func(xOpenClipboard, {hWnd}) = 0 then
        return 0
    end if
    VOID = c_func(xEmptyClipboard, {})
    
    lptStr = allocate_string(txt)
    
    -- Allocate a export memory object for the text
    hglbCopy = c_func(xGlobalAlloc, {GMEM_MOVEABLE, length(txt) + 1})
    if hglbCopy = 0 then
        VOID = c_func(xCloseClipboard, {})
        return 0
    end if
    
    -- Lock the handle and copy the text to the buffer
    lptstrCopy = c_func(xGlobalLock, {hglbCopy})
    mem_copy(lptstrCopy, lptStr, length(txt)+1)
    c_func(xGlobalUnlock, {hglbCopy})
    free(lptStr)
    
    -- Place the handle on the clipboard
    VOID = c_func(xSetClipboardData, {CF_TEXT, hglbCopy})
    VOID = c_func(xCloseClipboard, {})
    
    return 1
end function


public function clipboard_read_txt(atom hWnd) --
    sequence txt
    atom hglb, lptStr
    
    if c_func(xIsClipboardFormatAvailable, {CF_TEXT}) = 0 then
        return ""
    end if
    if c_func(xOpenClipboard, {hWnd}) = 0 then
        return ""
    end if
    hglb = c_func(xGetClipboardData, {CF_TEXT})
    if hglb = 0 then
        return ""
    end if
    lptStr = c_func(xGlobalLock, {hglb})
    txt = peek_string(lptStr)
    VOID = c_func(xGlobalUnlock, {hglb}) 
    VOID = c_func(xCloseClipboard, {})
    return txt
end function


--Fonts-----------------------------

public function get_text_extent(atom windowid, sequence txt) --SEQUENCE: {width, height}
    atom widx = find(windowid, windowList), width = 0, height = 0, hdc, lpString, lpSize
    
    if widx > 0 then
        hdc = windowDCs[widx]
        lpString = allocate_string(txt)
        lpSize = allocate(szLong * 2)
        
        hFont = create_font(hdc, FontName, FontSize, FontBold, FontItalic, FontUnderline, FontStrikeout)
        VOID = c_func(xSelectObject, {hdc, hFont})
        VOID = c_func(xGetTextExtentPoint, {hdc, lpString, length(txt), lpSize})
        width = peek4s(lpSize)
        height = peek4s(lpSize + szLong)
        free({lpString, lpSize})
        
        c_proc(xDeleteObject, {hFont})
    end if
    return {width, height}
end function


public function get_text_width(atom windowid, sequence txt) 
    sequence txtex = get_text_extent(windowid, txt)
    
    return txtex[1] 
end function


public function get_text_height(atom windowid, sequence txt) 
    sequence txtex = get_text_extent(windowid, txt)
    
    return txtex[2] 
end function


-- Graphics ---------------------------------------

public enum
DR_SelectBitmap,
DR_Restrict,
DR_Release,
DR_Offset,
DR_Scroll,

DR_Arc,
DR_Image,
DR_Chord,
DR_Ellipse,
DR_Line,
DR_PolyLine,
DR_Pie,
DR_Polygon,
DR_Rectangle,
DR_RoundRect,
DR_BackColor,
DR_PenBkColor,
DR_PenBkMode,
DR_PenBrushColor,
DR_PenColor,
DR_PenMode,
DR_PenStyle,
DR_PenWidth,
DR_Pixel,
DR_TextColor,
DR_Font,
DR_PenPos,
DR_Print,
DR_Printf,
DR_Puts,

DR_BrushStyle,
DR_BrushHatch,
DR_BrushColor


sequence hBitmapNames = {}, hBitmaps = {}, hBitmapSizes = {}


public procedure load_bitmap(sequence bitmapname, sequence fName) --loads a bitmap, returns the handle
    atom bidx, hImage, lImageType, zstxt, pBitmap, bWidth, bHeight
    
    lImageType = IMAGE_BITMAP
    --if match(".ico", lower(fName)) = length(fName) - 3 then
    --    lImageType = IMAGE_ICON
    --end if
    
    --HANDLE WINAPI LoadImage(HINSTANCE hinst, LPCTSTR lpszName, UINT uType, int cxDesired, int cyDesired, UINT fuLoad);
    zstxt = allocate_string(fName)
    hImage = c_func(xLoadImage, {NULL, zstxt, lImageType, 0, 0, LR_LOADFROMFILE})
    free(zstxt)
    
    --get size of bitmap:
    pBitmap = allocate(SIZEOF_BITMAP)
    VOID = c_func(xGetObject, {hImage, SIZEOF_BITMAP, pBitmap})
    bWidth = peek4u(pBitmap + szLong)
    bHeight = peek4u(pBitmap + szLong + szLong)
    --? {VOID, bWidth, bHeight}
    free(pBitmap)
        
    
    --puts(1, bitmapname & ", " & fName)
    --? hImage
     
    if hImage != 0 then
        bidx = find(bitmapname, hBitmapNames)
        
        if bidx > 0 then --if name already exists, replace previous bitmap with new one
            c_proc(xDeleteObject, {hBitmaps[bidx]})
            hBitmaps[bidx] = hImage
            hBitmapSizes[bidx] = {bWidth, bHeight}
        else
            hBitmapNames &= {bitmapname}
            hBitmaps &= {hImage}
            hBitmapSizes &= {{bWidth, bHeight}}
        end if
    end if
    
    --puts(1, "\n\nload_bitmap: '" & bitmapname & "' = " & sprint(hImage) & "\n")
    --pretty_print(1, hBitmapNames, {2})
    --pretty_print(1, hBitmaps, {2})
end procedure


public procedure create_bitmap(sequence bitmapname, atom xs, atom ys)
    if length(windowList) > 0 then
        atom hdc = c_func(xGetDC, {windowList[1]})
    	atom hbit = c_func(xCreateCompatibleBitmap, {hdc, xs, ys})
        VOID = c_func(xReleaseDC, {windowList[1], hdc})
        
        --puts(1, bitmapname)
        --? hbit
        atom bidx = find(bitmapname, hBitmapNames)
        if bidx > 0 then --if name already exists, replace previous bitmap with new one
            c_proc(xDeleteObject, {hBitmaps[bidx]})
            hBitmaps[bidx] = hbit
            hBitmapSizes[bidx] = {xs, ys}
        else
            hBitmapNames &= {bitmapname}
            hBitmaps &= {hbit}
            hBitmapSizes &= {{xs, ys}}
        end if
        
        --puts(1, "\n\ncreate_bitmap: '" & bitmapname & "' = " & sprint(hbit) & "\n")
        --pretty_print(1, hBitmapNames, {2})
        --pretty_print(1, hBitmaps, {2})
    --else
        --puts(1, "Error: create_bitmap: There are no windows to create a bitmap for.\n")
    end if
    
    
end procedure


public procedure destroy_bitmap(object hbit)
    atom idx = find(hbit, hBitmaps)
    
    if idx > 0 then
        c_proc(xDeleteObject, {hBitmaps[idx]})
        hBitmapNames = remove(hBitmapNames, idx)
        hBitmaps = remove(hBitmaps, idx)
        hBitmapSizes = remove(hBitmapSizes, idx)
    end if
end procedure


procedure check_styles()
    hPen = c_func(xCreatePen, {PenStyle, PenWidth, PenColor})
    VOID = c_func(xSelectObject, {hdc, hPen})
    --if hdc = BitmapDC then
    --    puts(1, "check_styles: ")
    --    ? {hPen, VOID}
    --end if
    if BrushStyle = BS_SOLID then
        hBrush = c_func(xCreateSolidBrush, {BrushColor})
        VOID = c_func(xSelectObject, {hdc, hBrush})
        --if hdc = BitmapDC then
        --    puts(1, "BS_SOLID: ")
        --    ? {hPen, VOID}
        --end if
    --elsif BrushStyle = BS_HATCHED then
    --    hBrush = c_func(CreateHatchBrush, {something, BrushColor})
    --    VOID = c_func(xSelectObject, {hdc, hBrush})
    --elsif BrushStyle = BS_PATTERN then
    --    hBrush = c_func(CreatePatternBrush, {hBitmap})
    --    VOID = c_func(xSelectObject, {hdc, hBrush})
    else --BrushStyle = BS_HOLLOW then
        --if hdc = BitmapDC then
        --    puts(1, "BS_HOLLOW: ")
        --    ? {hPen, VOID}
        --end if
        hBrush = c_func(xGetStockObject, {HOLLOW_BRUSH})
        VOID = c_func(xSelectObject, {hdc, hBrush})
    end if
end procedure


public function get_pixel_color(sequence bitmapname, atom wh, atom xpos, atom ypos)
    atom bidx, hdc, memdc, bc = 0
    
    bidx = find(bitmapname, hBitmapNames)
    if bidx > 0 then
        hdc = c_func(xGetDC, {wh})
    	memdc = c_func(xCreateCompatibleDC, {hdc})
        VOID = c_func(xReleaseDC, {wh, hdc})
        VOID = c_func(xSelectObject, {memdc, hBitmaps[bidx]})
        bc = c_func(xGetPixel, {memdc, xpos, ypos})
        VOID = c_func(xDeleteDC, {memdc})
    end if
    return bc
end function


public function get_bitmap_size(sequence bitmapname)
    atom bidx = find(bitmapname, hBitmapNames)
    if bidx > 0 then
        return hBitmapSizes[bidx]
    else
        return {0, 0}
    end if
end function


public function bitmap_to_sequence(sequence bitmapname, atom wh)
    atom bidx, hdc, memdc, bc, DimX, DimY
    
    sequence bitmapdata = {}
    
    bidx = find(bitmapname, hBitmapNames)
    if bidx > 0 then
        hdc = c_func(xGetDC, {wh})
    	memdc = c_func(xCreateCompatibleDC, {hdc})
        VOID = c_func(xReleaseDC, {wh, hdc})
        
        DimX = hBitmapSizes[bidx][1]
        DimY = hBitmapSizes[bidx][2]
        
        /*pBitmap = allocate(bitmaplen)
        VOID = c_func(xGetObject, {hBitmaps[bidx], bitmaplen, pBitmap})
        DimX = peek4u(pBitmap+szLong)
        DimY = peek4u(pBitmap+szLong+szLong)
        --? {VOID, DimX, DimY}
        free(pBitmap)*/
        
        VOID = c_func(xSelectObject, {memdc, hBitmaps[bidx]})
        if DimX > 0 and DimY > 0 then
            bitmapdata = repeat(repeat(0, DimX), DimY)
            for y = 1 to DimY do
                for x = 1 to DimX do
                    bitmapdata[y][x] = c_func(xGetPixel, {memdc, x-1, y-1})
                end for
            end for
        end if
        
        VOID = c_func(xDeleteDC, {memdc})
    end if
    return bitmapdata
end function



public procedure sequence_to_bitmap(atom hwnd, sequence bitmapname, sequence bitmapdata)
    atom idx, bmpidx, memdc, DimX, DimY
    idx = find(hwnd, windowList)
    
    if idx > 0 and length(bitmapdata) > 0 and length(bitmapdata[1]) > 0 then
        DimX = length(bitmapdata[1])
        DimY = length(bitmapdata)
        create_bitmap(bitmapname, DimX, DimY)
        bmpidx = find(bitmapname, hBitmapNames)
        if bmpidx > 0 then
            memdc = c_func(xCreateCompatibleDC, {windowDCs[idx]})
            VOID = c_func(xSelectObject, {memdc, hBitmaps[bmpidx]})
            --? VOID
            for y = 1 to DimY do
                for x = 1 to DimX do
                    VOID = c_func(xSetPixelV, {memdc, x-1, y-1, bitmapdata[y][x]})
                end for
            end for
            VOID = c_func(xDeleteDC, {memdc})
        end if
    end if
end procedure



public procedure set_font(object windowid, sequence fontname, object size, object attributes)
    --TODO: delete references to windowid
    FontName = fontname
    FontSize = size
    FontBold = 0
    FontItalic = 0
    FontUnderline = 0
    FontStrikeout = 0
    if and_bits(Bold, attributes) then
        FontBold = True
    end if
    if and_bits(Italic, attributes) then
        FontItalic = True
    end if
    if and_bits(Underline, attributes) then
        FontUnderline = True
    end if
    if and_bits(Strikeout, attributes) then
        FontStrikeout = True
    end if
end procedure


public procedure draw(atom hwnd, sequence cmds, sequence bmpname = "", object invalidrect = 0)
    atom idx, wdc, bmpidx = 0, bidx, bmp, xoff = 0, yoff = 0, sbDC = 0, zstxt
    sequence rect = {0, 0, 0, 0}, ccmd
    
    if length(bmpname) > 0 then
        bmpidx = find(bmpname, hBitmapNames)
    end if
    if bmpidx = 0 then --draw to a window's DC
        idx = find(hwnd, windowList)
        if idx > 0 then
            hdc = windowDCs[idx]
            bmp = windowBitmaps[idx]
        else
            return
        end if
    else --draw to a memory bitmap's DC
        idx = find(hwnd, windowList)
        if idx > 0 then
            --hdc = windowDCs[idx]
            hdc = c_func(xCreateCompatibleDC, {windowDCs[idx]})
            bmp = hBitmaps[bmpidx]
        else
            return
        end if
    end if
    
    --wdc = c_func(xGetDC, {hwnd})
	--hdc = c_func(xCreateCompatibleDC, {wdc})
    --VOID = c_func(xReleaseDC, {hwnd, wdc})
    
    VOID = c_func(xSelectObject, {hdc, bmp})
    if VOID = NULL then --error
        puts(1, "Error: SelectObject (draw ini)\n")
    end if
    VOID = c_func(xSetBkMode, {hdc, TRANSPARENT})
    
    for dc = 0 to length(cmds) do
        if dc = 0 then
            ccmd = {DR_Release}
        else
            ccmd = cmds[dc]
        end if
        switch ccmd[1] do
--resticted regions and bitmaps
            case DR_Restrict then --restrict drawing to (integer xpos, integer ypos, integer wide, integer high)
                /*VOID = c_func(xSelectObject, {ClipScreenDC, ClipScreenBM})
                if VOID = NULL then --error
                    puts(1, "Error: SelectObject (DR_Restrict)\n")
                end if
                hdc = ClipScreenDC
                */
                
                --rect = {50, 50, 150, 150}
                rect = {ccmd[2], ccmd[3], ccmd[4], ccmd[5]}
                --rect = {ccmd[2], ccmd[3], ccmd[2] + ccmd[4], ccmd[3] + ccmd[5]}
                
                --atom hRgn = c_func(xCreateRectRgn, rect)
                --xSelectClipRgn =  c_func(xSelectClipRgn, {hdc, hRgn})
                --xSelectClipRgn =  c_func(xSelectClipRgn, {hdc, 0})
                --c_proc(xDeleteObject, {hRgn})
                atom phPen = c_func(xGetStockObject, {WHITE_PEN})
                VOID = c_func(xSelectObject, {hdc, phPen})
                atom phBrush = c_func(xGetStockObject, {WHITE_BRUSH})
                VOID = c_func(xSelectObject, {hdc, phBrush})
                VOID = c_func(xBeginPath, {hdc})
                VOID = c_func(xRectangle, {hdc, rect[1], rect[2], rect[3], rect[4]})
                VOID = c_func(xEndPath, {hdc})
                VOID = c_func(xSelectClipPath, {hdc, RGN_COPY})
                c_proc(xDeleteObject, {phPen})
                c_proc(xDeleteObject, {phBrush})
                
            case DR_Release then --copy restriction area to buffer
                /*VOID = c_func(xSelectObject, {iniDC, iniBM})
                if VOID = NULL then --error
                    puts(1, "Error: SelectObject (DR_Release)\n")
                end if
                hdc = iniDC
                VOID = c_func(xBitBlt, {hdc, xoff + rect[RECT_Left], yoff + rect[RECT_Top], 
                                             rect[RECT_Right] - rect[RECT_Left], rect[RECT_Bottom] - rect[RECT_Top], 
                                        ClipScreenDC, xoff + rect[RECT_Left], yoff + rect[RECT_Top], SRCCOPY})
                */
                
                atom bm = allocate(SIZEOF_BITMAP)
                atom objsz = c_func(xGetObject, {bmp, SIZEOF_BITMAP, bm})
                if objsz = 0 or objsz != SIZEOF_BITMAP then
                    puts(1, "DR_Image Error: GetObject hBitmap")
                end if
                atom bmWidth = peek4s(bm + szLong)
                atom bmHeight = peek4s(bm + szLong + szLong)
                atom phPen = c_func(xGetStockObject, {WHITE_PEN})
                VOID = c_func(xSelectObject, {hdc, phPen})
                atom phBrush = c_func(xGetStockObject, {WHITE_BRUSH})
                VOID = c_func(xSelectObject, {hdc, phBrush})
                VOID = c_func(xBeginPath, {hdc})
                VOID = c_func(xRectangle, {hdc, 0, 0, bmWidth+1, bmHeight+1})
                VOID = c_func(xEndPath, {hdc})
                VOID = c_func(xSelectClipPath, {hdc, RGN_COPY})
                c_proc(xDeleteObject, {phPen})
                c_proc(xDeleteObject, {phBrush})
                free(bm)
                
            case DR_Offset then --setPenPos ( window, x, y )
                xoff = ccmd[2]
                yoff = ccmd[3]
                
                
            case DR_Scroll then --dx, dy, rectscroll, rectclip
                /*BOOL ScrollDC(
                  _In_   HDC hDC,
                  _In_   int dx,
                  _In_   int dy,
                  _In_   const RECT *lprcScroll,
                  _In_   const RECT *lprcClip,
                  _In_   HRGN hrgnUpdate,
                  _Out_  LPRECT lprcUpdate
                );*/
                --atom rectscroll, rectclip, rgnupdate, rectupdate
                --VOID = c_func(xScrollDC, {hdc, ccmd[2], ccmd[3], rectscroll, rectclip, rgnupdate, rectupdate)

                
            case DR_Image then --{hBitmap, x, y} --todo: allow specific height, widgth, point of origin, etc.
                atom bm, bmDC, objsz, ptSize, ptOrg, bmWidth, bmHeight, bmOrgX, bmOrgY, hBitmap
                
                --ccmd[2] = "Redy"
                --puts(1, "DR_Image: '" & ccmd[2] & "'\n")
                bidx = find(ccmd[2], hBitmapNames)
                if bidx > 0 then --if name already exists, replace previous bitmap with new one
                    hBitmap = hBitmaps[bidx]
                    bm = allocate(SIZEOF_BITMAP)
                    ptSize = allocate(szLong + szLong)
                    ptOrg = allocate(szLong + szLong)
                   
                   
                    /*
                    objsz = c_func(xGetObject, {hBitmap, SIZEOF_BITMAP, bm})    --int GetObject(  _In_   HGDIOBJ hgdiobj,  _In_   int cbBuffer,  _Out_  LPVOID lpvObject);
                    if objsz = 0 or objsz != SIZEOF_BITMAP then
                        puts(1, "DR_Image Error: GetObject hBitmap")
                    end if
                    */
                    
                    -- create a memory device context based on the destination
                    bmDC = c_func(xCreateCompatibleDC, {hdc})
                    if bmDC = NULL then --error
                    end if
                    
                    -- select the bitmap into it
                    VOID = c_func(xSelectObject, {bmDC, hBitmap})
                    --? VOID
                    
                    -- set mapping mode to same as destination
                    VOID = c_func(xSetMapMode, {bmDC, c_func(xGetMapMode, {hdc})})
                    -- int SetMapMode(  _In_  HDC hdc,  _In_  int fnMapMode);    int GetMapMode(  _In_  HDC hdc);
                    
                    
                    -- move the size into the point structure ptSize (logical coordinates)
                    --bmWidth = peek4s(bm + szLong)
                    --bmHeight = peek4s(bm + szLong + szLong)
                    bmWidth = hBitmapSizes[bidx][1]
                    bmHeight = hBitmapSizes[bidx][2]
                    poke4(ptSize, {bmWidth, bmHeight})
                    VOID = c_func(xDPtoLP, {hdc, ptSize, 1}) --BOOL DPtoLP(  _In_     HDC hdc,  _Inout_  LPPOINT lpPoints,  _In_     int nCount);
                    bmWidth = peek4s(ptSize)
                    bmHeight = peek4s(ptSize + szLong)
                    
                    
                    -- get the origin of the bitmap (logical coordinates)
                    poke4(ptOrg, {0, 0})
                    VOID = c_func(xDPtoLP, {hdc, ptOrg, 1})
                    bmOrgX = peek4s(ptOrg)
                    bmOrgY = peek4s(ptOrg + szLong)
                    
                    -- copy bitmap to device context
                    VOID = c_func(xBitBlt, {hdc, xoff + ccmd[3], yoff + ccmd[4], bmWidth, bmHeight, bmDC, bmOrgX, bmOrgY, SRCCOPY})
                    --BOOL BitBlt(HDC hdcDest, int nXDest, int nYDest, int nWidth, int nHeight, HDC hdcSrc, int nXSrc, int nYSrc, DWORD dwRop);
                    --? VOID
                    -- release resourses
                    VOID = c_func(xDeleteDC, {bmDC})
                    free({bm, ptSize, ptOrg})
                else
                    --puts(1, "DR_Image error: Image '" & ccmd[2] & "' does not exist!\n")
                    --pretty_print(1, hBitmapNames, {2})
                end if
                
--pens, brushes, and colors
            case DR_BackColor then --# proc setBackColor( integer id, object color )     Set the color for used for the pen fill color in id.
                --COLORREF SetBkColor(HDC hdc, COLORREF crColor);
                
            case DR_PenBkColor then --# proc setPenBkColor( window, color ) Determines the background color for text.
                --VOID = c_func(xSetBkColor, {hdc, ccmd[2]}) --int SetBkMode(_In_  HDC hdc, _In_  int iBkMode);
                
            case DR_PenBkMode then --# proc setPenBkMode( window, mode )    Determines if the background color for lines and text.
                --VOID = c_func(xSetBkMode, {hdc, ccmd[2]}) --int SetBkMode(HDC hdc, int iBkMode);   OPAQUE or TRANSPARENT
                
            case DR_BrushStyle then --# proc setPenBrushColor( window, color )    Determines the solid brush color for filled shapes.
                BrushStyle = ccmd[2]
                
            case DR_BrushHatch then --# proc setPenBrushColor( window, color )    Determines the solid brush color for filled shapes.
                --setPenBrushColor(wb, ccmd[2])
                --COLORREF SetDCBrushColor(  _In_  HDC hdc,  _In_  COLORREF crColor);
                --if hBrush > 0 then
                --    c_proc(xDeleteObject, {hBrush})
                --    hBrush = 0
                --end if
                BrushHatch = ccmd[2]
                
            case DR_BrushColor then --# proc setPenBrushColor( window, color )    Determines the solid brush color for filled shapes.
                BrushColor = ccmd[2]                
                
            case DR_PenStyle then --# proc setPenStyle( window, style ) Set the style that lines are drawn in.
                PenStyle = ccmd[2]
                
            case DR_PenWidth then --# proc setPenWidth( window, pixel width )  Set the the pen width used in window.
                PenWidth = ccmd[2]
                
            case DR_PenColor then --# proc setPenColor( window, color )  Set the the pen color used in window.
                PenColor = ccmd[2]
                
--drawing lines, curves, and shapes
            case DR_Arc then --# proc drawArc( window, filled, x1, y1, x2, y2, xStart, yStart, xEnd, yEnd )  Draw an arc.
                --if ccmd[2] = True then --filled
                check_styles()
                VOID = c_func(xArc,{hdc,   ccmd[3], ccmd[4], ccmd[5], ccmd[6],   ccmd[7], ccmd[8], ccmd[9], ccmd[10]})
                --HDC hdc, int nLeftRect, int nTopRect, int nRightRect, int nBottomRect, int nXStartArc, int nYStartArc, int nXEndArc, int nYEndArc    
                c_proc(xDeleteObject, {hPen})
                c_proc(xDeleteObject, {hBrush})
                
            case DR_Chord then --# proc drawChord( window, filled, x1, y1, x2, y2, xStart, yStart, xEnd, yEnd )  Draw a chord.
                check_styles()
                VOID = c_func(xChord, {hdc,   ccmd[3], ccmd[4], ccmd[5], ccmd[6],   ccmd[7], ccmd[8], ccmd[9], ccmd[10]})
                --HDC hdc, int nLeftRect, int nTopRect, int nRightRect, int nBottomRect, int nXRadial1, int nYRadial1, int nXRadial2, int nYRadial2
                c_proc(xDeleteObject, {hPen})
                c_proc(xDeleteObject, {hBrush})
                
            case DR_Ellipse then --# proc drawEllipse( window, filled, x1, y1, x2, y2 )  Draw an ellipse.
                check_styles()
                VOID = c_func(xEllipse, {hdc, cmds[2], cmds[3], cmds[4], cmds[5]})
                --HDC hdc, int nLeftRect, int nTopRect, int nRightRect, int nBottomRect
                c_proc(xDeleteObject, {hPen})
                c_proc(xDeleteObject, {hBrush})
                
            case DR_Line then --# proc drawLine( window, pStartX, pStartY, pEndX, pEndY ) Draw a line.
                check_styles()
                VOID = c_func(xMoveToEx, {hdc, xoff + ccmd[2], yoff + ccmd[3], NULL})
                --BOOL MoveToEx(  _In_   HDC hdc,  _In_   int X,  _In_   int Y,  _Out_  LPPOINT lpPoint)
                VOID = c_func(xLineTo, {hdc, xoff + ccmd[4], yoff + ccmd[5]})
                --BOOL LineTo(  _In_  HDC hdc,  _In_  int nXEnd,  _In_  int nYEnd)
                c_proc(xDeleteObject, {hPen})
                c_proc(xDeleteObject, {hBrush})
                
            case DR_PolyLine then --# proc drawLines( integer id, sequence coords )    Draws zero or more lines.
                if length(ccmd[3]) > 1 then
                    sequence pts = ccmd[3]
                    
                    if ccmd[2] = True then  --filled
                        VOID = c_func(xBeginPath, {hdc})
                        check_styles()
                        
                        VOID = c_func(xMoveToEx, {hdc, xoff + pts[1][1], yoff + pts[1][2], NULL})
                        for p = 2 to length(pts) do
                            VOID = c_func(xLineTo, {hdc, xoff + pts[p][1], yoff + pts[p][2]})
                        end for
                        VOID = c_func(xEndPath, {hdc})
                        VOID = c_func(xFillPath, {hdc})
                        
                        c_proc(xDeleteObject, {hPen})
                        c_proc(xDeleteObject, {hBrush})
                    else                        --unfilled
                        check_styles()
                        
                        VOID = c_func(xMoveToEx, {hdc, xoff + pts[1][1], yoff + pts[1][2], NULL})
                        for p = 2 to length(pts) do
                            VOID = c_func(xLineTo, {hdc, xoff + pts[p][1], yoff + pts[p][2]})
                        end for
                        
                        c_proc(xDeleteObject, {hPen})
                        c_proc(xDeleteObject, {hBrush})
                    end if
                end if
                
            --case DR_PolyBezier then 
                --VOID = c_func(xPolyBezier, {})
                
            case DR_Pie then --# proc drawPie( window, filled, x1, y1, x2, y2, xStart, yStart, xEnd, yEnd )  Draw a pie slice.
                check_styles()
                VOID = c_func(xPie, {hdc,   ccmd[3], ccmd[4], ccmd[5], ccmd[6],   ccmd[7], ccmd[8], ccmd[9], ccmd[10]})
                --HDC hdc, int nLeftRect, int nTopRect, int nRightRect, int nBottomRect, int nXRadial1, int nYRadial1, int nXRadial2, int nYRadial2
                
            --case DR_Polygon then --# proc drawPolygon( integer id, integer filled, sequence points ) Draw a polygon.
                --VOID = c_func(xPolygon", {C_INT,C_INT,C_INT})  --HDC hdc, const POINT *lpPoints, int nCount
                c_proc(xDeleteObject, {hPen})
                c_proc(xDeleteObject, {hBrush})
                
            case DR_Rectangle then --# proc drawRectangle( window, filled, x1, y1, x2, y2 )  Draw a rectangle.
                if ccmd[2] = True then --filled
                    BrushStyle = BS_SOLID
                    BrushColor = PenColor
                else
                    BrushStyle = BS_HOLLOW
                end if
                check_styles()
                VOID = c_func(xRectangle, {hdc, xoff + ccmd[3], yoff + ccmd[4], xoff + ccmd[5], yoff + ccmd[6]})  --HDC hdc, int nLeftRect, int nTopRect, int nRightRect, int nBottomRect
                c_proc(xDeleteObject, {hPen})
                c_proc(xDeleteObject, {hBrush})
                
            case DR_RoundRect then --# proc drawRoundRect( window, filled, x1, y1, x2, y2, xc, yc )  Draw a rounded rectangle.
                if ccmd[2] = True then --filled
                    BrushStyle = BS_SOLID
                    BrushColor = PenColor
                else
                    BrushStyle = BS_HOLLOW
                end if
                check_styles()
                VOID = c_func(xRoundRect, {hdc, xoff + ccmd[3], yoff + ccmd[4], xoff + ccmd[5], yoff + ccmd[6],   ccmd[7], ccmd[8]})
                --HDC hdc, int nLeftRect, int nTopRect, int nRightRect, int nBottomRect, int nWidth, int nHeight
                c_proc(xDeleteObject, {hPen})
                c_proc(xDeleteObject, {hBrush})
                
            case DR_Pixel then --# proc setPixel( window, x, y, rgb color )   Set a pixel value in window's client area. 
                check_styles()
                VOID = c_func(xSetPixelV, {hdc, xoff + ccmd[2], yoff + ccmd[3], ccmd[4]})
                c_proc(xDeleteObject, {hPen})
                c_proc(xDeleteObject, {hBrush})
                
--fonts and text
            case DR_TextColor then --setTextColor ( integer window, object color )
                VOID = c_func(xSetTextColor, {hdc, ccmd[2]})  --COLORREF SetTextColor(_In_  HDC hdc, _In_  COLORREF crColor);
                --VOID = c_func(xSetTextColor, {ClipScreenDC, ccmd[2]}) 
                --xSetTextAlign       = link_c_func(gdi32, "SetTextAlign", {C_POINTER, C_UINT}, C_UINT)
                --xSetTextJustification = link_c_func(gdi32, "SetTextJustification", {C_POINTER, C_INT, C_INT}, C_LONG)
                
            case DR_Font then --setFont ( object id, sequence fontname, object size, object attributes )
                set_font(hwnd, ccmd[2], ccmd[3], ccmd[4])
                
            case DR_PenPos then --setPenPos ( window, x, y )
                penX = xoff + ccmd[2]
                penY = yoff + ccmd[3]
                
            case DR_Print then --wPrint ( window, object )
                
            case DR_Printf then --wPrintf ( window, format, data )
                
            case DR_Puts then --wPuts ( object window, object text )
                check_styles()
                hFont = create_font(hdc, FontName, FontSize, FontBold, FontItalic, FontUnderline, FontStrikeout)
                VOID = c_func(xSelectObject, {hdc, hFont})
                VOID = c_func(xMoveToEx, {hdc, penX, penY, NULL})  --(HDC hdc, int X, int Y, LPPOINT lpPoint)
                zstxt = allocate_string(ccmd[2])
                VOID = c_func(xTextOut, {hdc, penX, penY, zstxt, length(ccmd[2])})
                --BOOL TextOut(_In_  HDC hdc, _In_  int nXStart, _In_  int nYStart, _In_  LPCTSTR lpString, _In_  int cchString);
                free(zstxt)
                c_proc(xDeleteObject, {hFont})
                c_proc(xDeleteObject, {hPen})
                c_proc(xDeleteObject, {hBrush})
                hFont = 0
                
        end switch
    end for
    
    if bmpidx != 0 then
        VOID = c_func(xDeleteDC, {hdc})
    end if
    
    --if sbDC > 0 then
    --    VOID = c_func(xDeleteDC, {sbDC})
    --end if
    if bmpidx = 0 then
        if atom(invalidrect) then
            InvalidatedWindows &= {hwnd}
        end if
        --VOID = c_func(xInvalidateRgn, {windowid, NULL, 0})  --_In_  HWND hWnd,  _In_  HRGN hRgn,  _In_  BOOL bErase
    end if
end procedure


public procedure update_windows()
    atom widx
    
    for w = 1 to length(InvalidatedWindows) do
        widx = find(InvalidatedWindows[w], windowList)
        if widx > 0 then
            VOID = c_func(xInvalidateRgn, {InvalidatedWindows[w], NULL, 0})  --_In_  HWND hWnd,  _In_  HRGN hRgn,  _In_  BOOL bErase
        end if
    end for
    InvalidatedWindows = {}
end procedure





