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




global constant False = 0, True = not 0

include std/os.e
include std/dll.e
include std/machine.e
include std/math.e
include std/error.e


public constant
szByte = 1,
szWord = 2,
szLong = 4,
szLpsz = 4,
szUInt = 4,
szShort = 2,
SIZEOF_BITMAP = szLong + szLong + szLong + szLong + szWord + szWord + szLpsz
/*typedef struct tagBITMAP {
    LONG   bmType;
    LONG   bmWidth;
    LONG   bmHeight;
    LONG   bmWidthBytes;
    WORD   bmPlanes;
    WORD   bmBitsPixel;
    LPVOID bmBits;
} BITMAP, *PBITMAP;*/









public enum RECT_Left, RECT_Top, RECT_Right, RECT_Bottom

public constant
    HWND_MESSAGE = -3

public constant 
	C_BYTE = C_UCHAR,  
	--C_BOOL = C_INT, 
	C_ATOM = C_USHORT, 
	--C_WORD = C_USHORT, 
	--C_DWORD=  C_ULONG, 
	--C_WPARAM = C_POINTER, 
	--C_LPARAM = C_POINTER, 
	C_HFILE = C_INT,  
	--C_HWND = C_POINTER, 
	--C_HANDLE = C_POINTER,  --all other H* are HANDLE 
	C_WNDPROC = C_POINTER, 
	C_LPSTR = C_POINTER, 
	C_LRESULT = C_POINTER, 
	C_LANGID =  C_WORD,   
	C_COLORREF =  C_DWORD    --0x00bbggrr 

public constant -- hatch style
    HS_BDIAGONAL   = 3,
    HS_CROSS       = 4,
    HS_DIAGCROSS   = 5,
    HS_FDIAGONAL   = 2,
    HS_HORIZONTAL  = 0,
    HS_VERTICAL    = 1
    
public constant -- pen style
    PS_GEOMETRIC   = 65536,
    PS_COSMETIC    = 0,
    PS_ALTERNATE   = 8,
    PS_SOLID       = 0,
    PS_DASH        = 1,
    PS_DOT         = 2,
    PS_DASHDOT     = 3,
    PS_DASHDOTDOT  = 4,
    PS_NULL        = 5,
    PS_USERSTYLE   = 7,
    PS_INSIDEFRAME = 6,
    PS_ENDCAP_ROUND = 0,
    PS_ENDCAP_SQUARE = 256,
    PS_ENDCAP_FLAT = 512,
    PS_JOIN_BEVEL  = 4096,
    PS_JOIN_MITER  = 8192,
    PS_JOIN_ROUND  = 0,
    PS_STYLE_MASK  = 15,
    PS_ENDCAP_MASK = 3840,
    PS_TYPE_MASK   = 983040
public constant -- Background mode
  OPAQUE = 2,
  TRANSPARENT = 1
  
public constant --Regions
    RGN_AND  = 1,
    RGN_OR   = 2,
    RGN_XOR  = 3,
    RGN_DIFF = 4,
    RGN_COPY = 5,
    RGN_MIN  = RGN_AND,
    RGN_MAX  = RGN_COPY,
    NULLREGION = 1,
    SIMPLEREGION = 2,
    COMPLEXREGION = 3
  
public constant -- stock objects
    BLACK_BRUSH = 4,
    DKGRAY_BRUSH = 3,
    GRAY_BRUSH = 2,
    HOLLOW_BRUSH = 5,
    LTGRAY_BRUSH = 1,
    NULL_BRUSH = 5,
    WHITE_BRUSH = 0,
    BLACK_PEN = 7,
    NULL_PEN = 8,
    WHITE_PEN = 6,
    ANSI_FIXED_FONT = 11,
    ANSI_VAR_FONT = 12,
    DEVICE_DEFAULT_FONT = 14,
    DEFAULT_GUI_FONT = 17,
    OEM_FIXED_FONT = 10,
    SYSTEM_FONT = 13,
    SYSTEM_FIXED_FONT = 16
  
public constant -- brush style 
    BS_DIBPATTERN = 5,
    BS_DIBPATTERN8X8 = 8,
    BS_DIBPATTERNPT = 6,
    BS_HATCHED = 2,
    BS_HOLLOW = 1,
    BS_NULL = 1,
    BS_PATTERN = 3,
    BS_PATTERN8X8 = 7,
    BS_SOLID = 0

public constant -- fonts
    FW_DONTCARE = 0,
    FW_THIN = 100,
    FW_EXTRALIGHT = 200,
    FW_LIGHT = 300,
    FW_NORMAL = 400,
    FW_MEDIUM = 500,
    FW_SEMIBOLD = 600,
    FW_BOLD = 700,
    FW_EXTRABOLD = 800,
    FW_HEAVY = 900,
    ANSI_CHARSET = 0,
    DEFAULT_CHARSET = 1,
    SYMBOL_CHARSET = 2,
    SHIFTJIS_CHARSET = 128,
    HANGEUL_CHARSET = 129,
    GB2312_CHARSET = 134,
    CHINESEBIG5_CHARSET = 136,
    GREEK_CHARSET = 161,
    TURKISH_CHARSET = 162,
    HEBREW_CHARSET = 177,
    ARABIC_CHARSET = 178,
    BALTIC_CHARSET = 186,
    RUSSIAN_CHARSET = 204,
    THAI_CHARSET = 222,
    EASTEUROPE_CHARSET = 238,
    OEM_CHARSET = 255,
    OUT_DEFAULT_PRECIS = 0,
    OUT_STRING_PRECIS = 1,
    OUT_CHARACTER_PRECIS = 2,
    OUT_STROKE_PRECIS = 3,
    OUT_TT_PRECIS = 4,
    OUT_DEVICE_PRECIS = 5,
    OUT_RASTER_PRECIS = 6,
    OUT_TT_ONLY_PRECIS = 7,
    OUT_OUTLINE_PRECIS = 8,
    CLIP_DEFAULT_PRECIS = 0,
    CLIP_CHARACTER_PRECIS = 1,
    CLIP_STROKE_PRECIS = 2,
    CLIP_MASK = 15,
    CLIP_LH_ANGLES = 16,
    CLIP_TT_ALWAYS = 32,
    CLIP_EMBEDDED = 128,
    DEFAULT_QUALITY = 0,
    DRAFT_QUALITY = 1,
    PROOF_QUALITY = 2,
    DEFAULT_PITCH = 0,
    FIXED_PITCH = 1,
    VARIABLE_PITCH = 2,
    FF_DECORATIVE = 80,
    FF_DONTCARE = 0,
    FF_MODERN = 48,
    FF_ROMAN = 16,
    FF_SCRIPT = 64,
    FF_SWISS = 32
 

public constant --GetDeviceCaps
    DRIVERVERSION = 0,
    TECHNOLOGY = 2,
    DT_PLOTTER = 0,
    DT_RASDISPLAY = 1,
    DT_RASPRINTER = 2,
    DT_RASCAMERA = 3,
    DT_CHARSTREAM = 4,
    DT_METAFILE = 5,
    DT_DISPFILE = 6,
    HORZSIZE = 4,
    VERTSIZE = 6,
    HORZRES = 8,
    VERTRES = 10,
    LOGPIXELSX = 88,
    LOGPIXELSY = 90,
    BITSPIXEL = 12,
    PLANES = 14,
    NUMBRUSHES = 16,
    NUMPENS = 18,
    NUMFONTS = 22,
    NUMCOLORS = 24,
    NUMMARKERS = 20,
    ASPECTX = 40,
    ASPECTY = 42,
    ASPECTXY = 44,
    PDEVICESIZE = 26,
    CLIPCAPS = 36,
    SIZEPALETTE = 104,
    NUMRESERVED = 106,
    COLORRES = 108,
    VREFRESH = 116,
    DESKTOPHORZRES = 118,
    DESKTOPVERTRES = 117,
    BLTALIGNMENT = 119,
    RASTERCAPS = 38,
    RC_BANDING = 2,
    RC_BITBLT = 1,
    RC_BITMAP64 = 8,
    RC_DI_BITMAP = 128,
    RC_DIBTODEV = 512,
    RC_FLOODFILL = 4096,
    RC_GDI20_OUTPUT = 16,
    RC_PALETTE = 256,
    RC_SCALING = 4,
    RC_STRETCHBLT = 2048,
    RC_STRETCHDIB = 8192,
    RC_DEVBITS =  #8000,
    RC_OP_DX_OUTPUT =  #4000,
    CURVECAPS = 28,
    CC_NONE = 0,
    CC_CIRCLES = 1,
    CC_PIE = 2,
    CC_CHORD = 4,
    CC_ELLIPSES = 8,
    CC_WIDE = 16,
    CC_STYLED = 32,
    CC_WIDESTYLED = 64,
    CC_INTERIORS = 128,
    CC_ROUNDRECT = 256,
    LINECAPS = 30,
    LC_NONE = 0,
    LC_POLYLINE = 2,
    LC_MARKER = 4,
    LC_POLYMARKER = 8,
    LC_WIDE = 16,
    LC_STYLED = 32,
    LC_WIDESTYLED = 64,
    LC_INTERIORS = 128,
    POLYGONALCAPS = 32,
    RC_BIGFONT = 1024,
    RC_GDI20_STATE = 32,
    RC_NONE = 0,
    RC_SAVEBITMAP = 64,
    PC_NONE = 0,
    PC_POLYGON = 1,
    PC_POLYPOLYGON = 256,
    PC_PATHS = 512,
    PC_RECTANGLE = 2,
    PC_WINDPOLYGON = 4,
    PC_SCANLINE = 8,
    PC_TRAPEZOID = 4,
    PC_WIDE = 16,
    PC_STYLED = 32,
    PC_WIDESTYLED = 64,
    PC_INTERIORS = 128,
    TEXTCAPS = 34,
    TC_OP_CHARACTER = 1,
    TC_OP_STROKE = 2,
    TC_CP_STROKE = 4,
    TC_CR_90 = 8,
    TC_CR_ANY = 16,
    TC_SF_X_YINDEP = 32,
    TC_SA_DOUBLE = 64,
    TC_SA_INTEGER = 128,
    TC_SA_CONTIN = 256,
    TC_EA_DOUBLE = 512,
    TC_IA_ABLE = 1024,
    TC_UA_ABLE = 2048,
    TC_SO_ABLE = 4096,
    TC_RA_ABLE = 8192,
    TC_VA_ABLE = 16384,
    TC_RESERVED = 32768,
    TC_SCROLLBLT = 65536
   
public constant -- Object types
     OBJ_BRUSH       =2,
     OBJ_PEN =1,
     OBJ_PAL =5,
     OBJ_FONT        =6,
     OBJ_BITMAP      =7,
     OBJ_EXTPEN      =11,
     OBJ_REGION      =8,
     OBJ_DC  =3,
     OBJ_MEMDC       =10,
     OBJ_METAFILE    =9,
     OBJ_METADC      =4,
     OBJ_ENHMETAFILE =13,
     OBJ_ENHMETADC   =12
     
public constant cbSize = 0,
	 style  = 4,
	 lpfnWndProc = 8,
	 cbClsExtra = 12,
	 cbWndExtra = 16,
	 hInstance  = 20,
	 hIcon      = 24,
	 hCursor    = 28,
	 hbrBackground = 32,
	 lpszMenuName  = 36,
	 lpszClassName = 40,
	 hIconSm = 44,
	 SIZE_OF_WNDCLASS = 48

public constant SIZE_OF_MESSAGE = 40

public constant CS_HREDRAW = 2,
	 CS_VREDRAW = 1,
     CS_DROPSHADOW = #00020000,
     CS_DBLCLKS = #0008,
     CS_SAVEBITS = #0800

public constant SW_SHOWNORMAL = 1

public constant 
	WM_NULL     = #0,
    WM_CREATE   = #1,
    WM_DESTROY  = #2,
    WM_MOVE     = #3,
    WM_SIZE     = #5,

    WM_ACTIVATE = #6,
--
--  WM_ACTIVATE state values

    WA_INACTIVE = 0,
    WA_ACTIVE = 1,
    WA_CLICKACTIVE = 2,

    -- key commands
    WM_KEYDOWN      = #100,         -- key pressed
    WM_KEYUP        = #101,
    WM_CHAR         = #102,
    
    WM_TIMER = #113,

    -- system key commands
    WM_SYSCHAR      = 262,
    WM_SYSDEADCHAR  = 263,
    WM_SYSKEYDOWN   = 260,
    WM_SYSKEYUP     = 261,
    
    
    -- edit commands
    WM_CUT = #300,
    WM_COPY = #301,
    WM_PASTE = #302,
    WM_CLEAR = #303,
    WM_UNDO = #304,


    WM_SETFOCUS         = #7,
    WM_KILLFOCUS        = #8,
    WM_ENABLE           = #A,
    WM_SETREDRAW        = #B,
    WM_SETTEXT          = #C,
    WM_GETTEXT          = #D,
    WM_GETTEXTLENGTH    = #E,
    WM_PAINT            = #F,
    WM_CLOSE            = #10,
    WM_QUERYENDSESSION  = #11,
    WM_QUIT             = #12,
    WM_QUERYOPEN        = #13,
    WM_ERASEBKGND       = #14,
    WM_SYSCOLORCHANGE   = #15,
    WM_ENDSESSION       = #16,
    WM_SHOWWINDOW       = #18,
    WM_WININICHANGE     = #1A,
    WM_DEVMODECHANGE    = #1B,
    WM_ACTIVATEAPP      = #1C,
    WM_FONTCHANGE       = #1D,
    WM_TIMECHANGE       = #1E,
    WM_CANCELMODE       = #1F,
    WM_SETCURSOR        = #20,
    WM_MOUSEACTIVATE    = #21,
    WM_CHILDACTIVATE    = #22,
    WM_QUEUESYNC        = #23,
    WM_GETMINMAXINFO    = #24,
    -- setting fonts in controls
    WM_SETFONT          = #30,
    WM_GETFONT          = #31,

    WM_NOTIFY           = #4E,
    WM_SETICON          = #80,
    -- non-client messages
    WM_NCCREATE         = #81,
    WM_NCDESTROY        = #82,
    WM_NCCALCSIZE       = #83,
    WM_NCHITTEST        = #84,
    WM_NCPAINT          = #85,
    WM_NCACTIVATE       = #86,
    WM_GETDLGCODE       = #87,
    WM_SYNCPAINT        = #88,
    WM_NCMOUSEMOVE      = #A0,
    WM_NCLBUTTONDOWN    = #A1,
    WM_NCLBUTTONUP      = #A2,
    WM_NCLBUTTONDBLCLK  = #A3,
    WM_NCRBUTTONDOWN    = #A4,
    WM_NCRBUTTONUP      = #A5,
    WM_NCRBUTTONDBLCLK  = #A6,
    WM_NCMBUTTONDOWN    = #A7,
    WM_NCMBUTTONUP      = #A8,
    WM_NCMBUTTONDBLCLK  = #A9,
    WM_NCXBUTTONDOWN    = #AB,
    WM_NCXBUTTONUP      = #AC,
    WM_NCXBUTTONDBLCLK  = #AD,

    WM_SYSTIMER         = #118,  -- 280

    WM_PARENTNOTIFY     = #210,
    WM_DROPFILES        = #233,

-- MDI messages

    WM_MDICREATE        = #220,
    WM_MDIDESTROY       = #221,
    WM_MDIACTIVATE      = #222,
    WM_MDIRESTORE       = #223,
    WM_MDINEXT          = #224,
    WM_MDIMAXIMIZE      = #225,
    WM_MDITILE          = #226,
    WM_MDICASCADE       = #227,
    WM_MDIICONARANGE    = #228,
    WM_MDIGETACTIVE     = #229,
    WM_MDISETMENU       = #230,
    WM_ENTERSIZEMOVE    = #231,
    WM_EXITSIZEMOVE     = #232,
    WM_MDIREFRSHMENU    = #234,
    -- mouse events
    WM_MOUSEMOVE        = #200, -- mouse moved
    WM_LBUTTONDOWN      = #201, -- (513) mouse button down
    WM_LBUTTONUP        = #202, -- left button released
    WM_LBUTTONDBLCLK    = #203, -- (515) mouse button double clicked
    WM_RBUTTONDOWN      = #204, -- right button down
    WM_RBUTTONUP        = #205, -- right button released
    WM_RBUTTONDBLCLK    = #206, -- mouse right button double clicked
    WM_MBUTTONDOWN      = #207, -- middle button down
    WM_MBUTTONUP        = #208, -- middle button released
    WM_MBUTTONDBLCLK    = #209, -- middle button double click
    WM_MOUSEWHEEL       = #20A, -- mouse wheel moved
    WM_XBUTTONDOWN      = #20B,
    WM_XBUTTONUP        = #20C,
    WM_XBUTTONDBLCLK    = #20D,
    
    WM_MOUSELEAVE       = #02A3
    
 
public constant 
    SWP_NOSIZE          = #0001,
    SWP_NOMOVE          = #0002,
    SWP_NOZORDER        = #0004,
    SWP_NOREDRAW        = #0008,
    SWP_NOACTIVATE      = #0010,
    SWP_FRAMECHANGED    = #0020,
    SWP_SHOWWINDOW      = #0040,
    SWP_HIDEWINDOW      = #0080,
    SWP_NOCOPYBITS      = #0100,
    SWP_NOOWNERZORDER   = #0200,
    SWP_NOSENDCHANGING  = #0400,
    SWP_DRAWFRAME       = SWP_FRAMECHANGED,
    SWP_NOREPOSITION    = SWP_NOOWNERZORDER,
    SWP_DEFERERASE      = #2000,
    SWP_ASYNCWINDOWPOS  = #4000,
    SWP_UPDATECACHE     = SWP_NOSIZE+SWP_NOMOVE+SWP_NOZORDER+SWP_FRAMECHANGED,
    HWND_TOP            = 0,
    HWND_BOTTOM         = 1,
    HWND_TOPMOST        = -1,
    HWND_NOTOPMOST      = -2

   

public constant SND_FILENAME = #00020000,
	 SND_ASYNC    = #00000001
	 
public constant DT_SINGLELINE = #0020,
	 DT_CENTER     = #0001,
	 DT_VCENTER    = #0004

public constant -- Window Styles
    WS_OVERLAPPED   = #0,
    WS_POPUP        = #80000000,
    WS_CHILD        = #40000000,
    WS_MINIMIZE     = #20000000,
    WS_VISIBLE      = #10000000,
    WS_DISABLED     = #08000000,
    WS_CLIPPINGCHILD= #44000000,
    WS_CLIPSIBLINGS = #04000000,
    WS_CLIPCHILDREN = #02000000,
    WS_MAXIMIZE     = #01000000,
    WS_CAPTION      = #00C00000,      --  WS_BORDER Or WS_DLGFRAME
    WS_BORDER       = #00800000,      -- creates border on window
    WS_DLGFRAME     = #00400000,
    WS_HSCROLL      = #00100000,    -- horizontal scroll bar
    WS_VSCROLL      = #00200000,    -- vertical scroll bar
    WS_SYSMENU      = #00080000,
    WS_THICKFRAME   = #00040000,
    WS_GROUP        = #00020000,
    WS_TABSTOP      = #00010000,   -- use tab stop
    WS_SCROLLBARS   = #00300000,    -- set both vertical and horizontal scrollbars
    WS_MINIMIZEBOX  = #00020000,
    WS_MAXIMIZEBOX  = #00010000,

    WS_NO_RESIZE = {WS_CAPTION,WS_SYSMENU}, --> Win32lib special.
    WS_TILED = WS_OVERLAPPED,
    WS_ICONIC = WS_MINIMIZE,
    WS_SIZEBOX = WS_THICKFRAME,
    /* WS_OVERLAPPEDWINDOW = or_all({  WS_BORDER,
	    	        WS_DLGFRAME,
	    	        WS_SYSMENU,
	    	        WS_THICKFRAME,
	    	        WS_MINIMIZEBOX,
	    	        WS_MAXIMIZEBOX}),*/
	    	        
   WS_OVERLAPPEDWINDOW = or_all({WS_OVERLAPPED, WS_CAPTION, WS_SYSMENU,
					   WS_THICKFRAME, WS_MINIMIZEBOX, 
					   WS_MAXIMIZEBOX}),


    WS_TILEDWINDOW = WS_OVERLAPPEDWINDOW,

--   Common Window Styles
    WS_POPUPWINDOW = or_all({WS_POPUP, WS_BORDER, WS_SYSMENU}),
    WS_CHILDWINDOW = WS_CHILD,

-- Extended styles
    WS_EX_ACCEPTFILES     = #00000010,
    WS_EX_APPWINDOW       = #00040000,
    WS_EX_CLIENTEDGE      = #00000200,
    WS_EX_CONTEXTHELP     = #00000400,
    WS_EX_CONTROLPARENT   = #00010000,
    WS_EX_DLGMODALFRAME   = #00000001,
    WS_EX_LEFT            = #00000000,
    WS_EX_LEFTSCROLLBAR   = #00004000,
    WS_EX_LTRREADING      = #00000000,
    WS_EX_MDICHILD        = #00000040, --64,
    WS_EX_NOPARENTNOTIFY  = #00000004,
    WS_EX_OVERLAPPEDWINDOW =#00000300,
    WS_EX_PALETTEWINDOW   = #00000188,
    WS_EX_RIGHT           = #00001000,
    WS_EX_RIGHTSCROLLBAR  = #00000000,
    WS_EX_RTLREADING      = #00002000,
    WS_EX_STATICEDGE      = #00020000,
    WS_EX_TOOLWINDOW      = #00000080, --128,
    WS_EX_TOPMOST         = #00000008,
    WS_EX_TRANSPARENT     = #00000020, --32,
    WS_EX_WINDOWEDGE      = #00000100,
    WS_EX_LAYERED         = #00080000,
    WS_EX_NOINHERITLAYOUT = #00100000, -- Disable inheritence of mirroring by children
    WS_EX_LAYOUTRTL       = #00400000, --Right to left mirroring
    WS_EX_NOACTIVATE      = #08000000

public constant
-- GetSystemMetrics
    SM_CYMIN            = 29,
    SM_CXMIN            = 28,
    SM_ARRANGE          = 56,
    SM_CLEANBOOT        = 67,
    -- The right value for SM_CEMETRICS for NT 3.5 is 75.  For Windows 95
   -- and NT 4.0, it is 76.  The meaning is undocumented, anyhow.
    SM_CMONITORS        = 80, 
    SM_CMETRICS         = 76,
    SM_CMOUSEBUTTONS    = 43,
    SM_CXBORDER         = 5,
    SM_CYBORDER         = 6,
    SM_CXCURSOR         = 13,
    SM_CYCURSOR         = 14,
    SM_CXDLGFRAME       = 7,
    SM_CYDLGFRAME       = 8,
    SM_CXDOUBLECLK      = 36,
    SM_CYDOUBLECLK      = 37,
    SM_CXDRAG           = 68,
    SM_CYDRAG           = 69,
    SM_CXEDGE           = 45,
    SM_CYEDGE           = 46,
    SM_CXFIXEDFRAME     = 7,
    SM_CYFIXEDFRAME     = 8,
    SM_CXFRAME          = 32,
    SM_CYFRAME          = 33,
    SM_CXFULLSCREEN     = 16,
    SM_CYFULLSCREEN     = 17,
    SM_CXHSCROLL        = 21,
    SM_CYHSCROLL        = 3,
    SM_CXHTHUMB         = 10,
    SM_CXICON           = 11,
    SM_CYICON           = 12,
    SM_CXICONSPACING    = 38,
    SM_CYICONSPACING    = 39,
    SM_CXMAXIMIZED      = 61,
    SM_CYMAXIMIZED      = 62,
    SM_CXMAXTRACK       = 59,
    SM_CYMAXTRACK       = 60,
    SM_CXMENUCHECK      = 71,
    SM_CYMENUCHECK      = 72,
    SM_CXMENUSIZE       = 54,
    SM_CYMENUSIZE       = 55,
    SM_CXMINIMIZED      = 57,
    SM_CYMINIMIZED      = 58,
    SM_CXMINSPACING     = 47,
    SM_CYMINSPACING     = 48,
    SM_CXMINTRACK       = 34,
    SM_CYMINTRACK       = 35,
    SM_CXSCREEN         = 0,
    SM_CYSCREEN         = 1,
    SM_CXSIZE           = 30,
    SM_CYSIZE           = 31,
    SM_CXSIZEFRAME      = 32,
    SM_CYSIZEFRAME      = 33,
    SM_CXSMICON         = 49,
    SM_CYSMICON         = 50,
    SM_CXSMSIZE         = 52,
    SM_CYSMSIZE         = 53,
    SM_CXVSCROLL        = 2,
    SM_CYVSCROLL        = 20,
    SM_CYVTHUMB         = 9,
    SM_CYCAPTION        = 4,
    SM_CYKANJIWINDOW    = 18,
    SM_CYMENU           = 15,
    SM_CYSMCAPTION      = 51,
    SM_DBCSENABLED      = 42,
    SM_DEBUG            = 22,
    SM_MENUDROPALIGNMENT= 40,
    SM_MIDEASTENABLED   = 74,
    SM_MOUSEPRESENT     = 19,
    SM_MOUSEWHEELPRESENT= 75,
    SM_NETWORK          = 63,
    SM_PENWINDOWS       = 41,
    SM_RESERVED1        = 24,
    SM_RESERVED2        = 25,
    SM_RESERVED3        = 26,
    SM_RESERVED4        = 27,
    SM_SECURE           = 44,
    SM_SHOWSOUNDS       = 70,
    SM_SLOWMACHINE      = 73,
    SM_SWAPBUTTON       = 23,
    ARW_BOTTOMLEFT      = 0,
    ARW_BOTTOMRIGHT     = #1,
    ARW_HIDE            = #8,
    ARW_TOPLEFT         = #2,
    ARW_TOPRIGHT        = #3,
    ARW_DOWN            = #4,
    ARW_LEFT            = 0,
    ARW_RIGHT           = 0,
    ARW_UP              = #4    

public constant
    -- System Colors
    COLOR_SCROLLBAR             = 0,
    COLOR_BACKGROUND            = 1,
    COLOR_DESKTOP               = COLOR_BACKGROUND,
    COLOR_ACTIVECAPTION         = 2,
    COLOR_INACTIVECAPTION       = 3,
    COLOR_MENU                  = 4,
    COLOR_WINDOW                = 5,
    COLOR_WINDOWFRAME           = 6,
    COLOR_MENUTEXT              = 7,
    COLOR_WINDOWTEXT            = 8,
    COLOR_CAPTIONTEXT           = 9,
    COLOR_ACTIVEBORDER          = 10,
    COLOR_INACTIVEBORDER        = 11,
    COLOR_APPWORKSPACE          = 12,
    COLOR_HIGHLIGHT             = 13,
    COLOR_HIGHLIGHTTEXT         = 14,
    COLOR_BTNFACE               = 15,
    COLOR_3DFACE                = COLOR_BTNFACE,
    COLOR_BTNSHADOW             = 16,
    COLOR_3DSHADOW              = COLOR_BTNSHADOW,
    COLOR_GRAYTEXT              = 17,
    COLOR_BTNTEXT               = 18,
    COLOR_INACTIVECAPTIONTEXT   = 19,
    COLOR_BTNHIGHLIGHT          = 20,
    COLOR_3DHILIGHT             = COLOR_BTNHIGHLIGHT,
    COLOR_3DDKSHADOW            = 21,
    COLOR_3DLIGHT               = 22,
    COLOR_INFOTEXT              = 23,
    COLOR_TOOLTIPTEXT           = COLOR_INFOTEXT,
    COLOR_INFOBK                = 24,
    COLOR_TOOLTIPBK             = COLOR_INFOBK

public constant 
-- attributes for EZ_FONTS
    Normal          = 0,
    Bold            = 1,
    Italic          = 2,
    Underline       = 4,
    Strikeout       = 8

public constant IDC_ARROW = 32512,
	 CW_USEDEFAULT = #80000000,

--  Ternary raster operations
    SRCCOPY = #CC0020, -- (DWORD) dest = source
    SRCPAINT = #EE0086,        -- (DWORD) dest = source OR dest
    SRCAND = #8800C6,  -- (DWORD) dest = source AND dest
    SRCINVERT = #660046,       -- (DWORD) dest = source XOR dest
    SRCERASE = #440328,        -- (DWORD) dest = source AND (NOT dest )
    NOTSRCCOPY = #330008,      -- (DWORD) dest = (NOT source)
    NOTSRCERASE = #1100A6,     -- (DWORD) dest = (NOT src) AND (NOT dest)
    MERGECOPY = #C000CA,       -- (DWORD) dest = (source AND pattern)
    MERGEPAINT = #BB0226,      -- (DWORD) dest = (NOT source) OR dest
    PATCOPY = #F00021, -- (DWORD) dest = pattern
    PATPAINT = #FB0A09,        -- (DWORD) dest = DPSnoo
    PATINVERT = #5A0049,       -- (DWORD) dest = pattern XOR dest
    DSTINVERT = #550009,       -- (DWORD) dest = (NOT dest)
    BLACKNESS = #42, -- (DWORD) dest = BLACK
    WHITENESS = #FF0062       -- (DWORD) dest = WHITE	 

public constant --global memory
    GHND = 66,
    GMEM_FIXED = 0,
    GMEM_MOVEABLE = 2,
    GMEM_ZEROINIT = 64,
    GPTR = 64

public constant  --clipboard data formats
    CF_BITMAP     =  2,
    CF_DIB =  8,
    CF_PALETTE    =  9,
    CF_ENHMETAFILE =  14,
    CF_METAFILEPICT = 3,
    CF_OEMTEXT      = 7,
    CF_TEXT = 1,
    CF_UNICODETEXT  = 13,
    CF_DIF  = 5,
    CF_DSPBITMAP    = 130,
    CF_DSPENHMETAFILE       = 142,
    CF_DSPMETAFILEPICT      = 131,
    CF_DSPTEXT      = 129,
    CF_GDIOBJFIRST  = 768,
    CF_GDIOBJLAST   = 1023,
    CF_HDROP        = 15,
    CF_LOCALE       = 16,
    CF_OWNERDISPLAY = 128,
    CF_PENDATA      = 10,
    CF_PRIVATEFIRST = 512,
    CF_PRIVATELAST  = 767,
    CF_RIFF = 11,
    CF_SYLK = 4,
    CF_WAVE = 12,
    CF_TIFF = 6

public constant --LoadImage
    IMAGE_BITMAP = 0,
    IMAGE_CURSOR = 2,
    IMAGE_ICON = 1,

    LR_CREATEDIBSECTION = #00002000,
    LR_DEFAULTCOLOR = #00000000,
    LR_DEFAULTSIZE = #00000040,
    LR_LOADFROMFILE = #00000010,
    LR_LOADMAP3DCOLORS = #00001000,
    LR_LOADTRANSPARENT = #00000020,
    LR_MONOCHROME = #00000001,
    LR_SHARED = #00008000,
    LR_VGACOLOR = #00000080 

public constant --TRACKMOUSEEVENT structure
    TME_LEAVE = #00000002





public constant

--  Common dialog error return codes
  CDERR_DIALOGFAILURE    = #FFFF,

  CDERR_GENERALCODES     = #0000,
  CDERR_STRUCTSIZE       = #0001,
  CDERR_INITIALIZATION   = #0002,
  CDERR_NOTEMPLATE       = #0003,
  CDERR_NOHINSTANCE      = #0004,
  CDERR_LOADSTRFAILURE   = #0005,
  CDERR_FINDRESFAILURE   = #0006,
  CDERR_LOADRESFAILURE   = #0007,
  CDERR_LOCKRESFAILURE   = #0008,
  CDERR_MEMALLOCFAILURE  = #0009,
  CDERR_MEMLOCKFAILURE   = #000A,
  CDERR_NOHOOK           = #000B,
  CDERR_REGISTERMSGFAIL  = #000C,

  PDERR_PRINTERCODES     = #1000,
  PDERR_SETUPFAILURE     = #1001,
  PDERR_PARSEFAILURE     = #1002,
  PDERR_RETDEFFAILURE    = #1003,
  PDERR_LOADDRVFAILURE   = #1004,
  PDERR_GETDEVMODEFAIL   = #1005,
  PDERR_INITFAILURE      = #1006,
  PDERR_NODEVICES        = #1007,
  PDERR_NODEFAULTPRN     = #1008,
  PDERR_DNDMMISMATCH     = #1009,
  PDERR_CREATEICFAILURE  = #100A,
  PDERR_PRINTERNOTFOUND  = #100B,
  PDERR_DEFAULTDIFFERENT = #100C,

  CFERR_CHOOSEFONTCODES  = #2000,
  CFERR_NOFONTS          = #2001,
  CFERR_MAXLESSTHANMIN   = #2002,

  FNERR_FILENAMECODES    = #3000,
  FNERR_SUBCLASSFAILURE  = #3001,
  FNERR_INVALIDFILENAME  = #3002,
  FNERR_BUFFERTOOSMALL   = #3003,

  FRERR_FINDREPLACECODES = #4000,
  FRERR_BUFFERLENGTHZERO = #4001,

  CCERR_CHOOSECOLORCODES = #5000


--  flags constants for open and save dialogs
public constant
  OFN_READONLY = #00000001,
  OFN_OVERWRITEPROMPT = #00000002,
  OFN_HIDEREADONLY = #00000004,
  OFN_NOCHANGEDIR = #00000008,
  OFN_SHOWHELP = #00000010,
  OFN_ENABLEHOOK = #00000020,
  OFN_ENABLETEMPLATE = #00000040,
  OFN_ENABLETEMPLATEHANDLE = #00000080,
  OFN_NOVALIDATE = #00000100,
  OFN_ALLOWMULTISELECT = #00000200,
  OFN_EXTENSIONDIFFERENT = #00000400,
  OFN_PATHMUSTEXIST = #00000800,
  OFN_FILEMUSTEXIST = #00001000,
  OFN_CREATEPROMPT = #00002000,
  OFN_SHAREAWARE = #00004000,
  OFN_NOREADONLYRETURN = #00008000,
  OFN_NOTESTFILECREATE = #00010000,
  OFN_NONETWORKBUTTON = #00020000,
  OFN_NOLONGNAMES = #00040000,
  OFN_EXPLORER = #00080000,
  OFN_NODEREFERENCELINKS = #00100000,
  OFN_LONGNAMES = #00200000


--drives info:
public constant
  DRIVE_UNKNOWN = 0,
  DRIVE_NO_ROOT_DIR = 1,
  DRIVE_REMOVABLE = 2,
  DRIVE_FIXED = 3,
  DRIVE_REMOTE = 4,
  DRIVE_CDROM = 5,
  DRIVE_RAMDISK = 6

public constant
  DRIVESINFO_DRIVE_LETTER = 1,
  DRIVESINFO_READY_STATUS = 2,
  DRIVESINFO_KBYTES_FREE_TO_CALLER = 3,
  DRIVESINFO_KBYTES_TOTAL = 4,
  DRIVESINFO_KBYTES_FREE = 5,
  DRIVESINFO_DISK_TYPE = 6

public constant DriveTypeStrings={"Unknown","No Root Directory","Removable","Fixed","Remote","CD Rom","Ram Disk","error"}

public constant DriveStatusStrings={"Not Ready","Ready"}

