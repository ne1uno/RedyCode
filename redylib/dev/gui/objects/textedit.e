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


include gui/gui.e as gui
include gui/themes.e as th

include std/sequence.e
include std/search.e
include std/pretty.e
include std/text.e
include std/task.e
include std/stack.e
include std/math.e
include std/search.e
include std/convert.e

--include euphoria/tokenize.e
include euphoria/syncolor.e


enum            --iSyntaxMode - syntax modes
synPlain,
synEuphoria,
synCreole,
synHTML,
synCSS,
synXML,
synINI,
synC

enum            --iEditMode
emNormal,           --normal selection editing
emBlock,            --block selection
emGrid              --grid (allign tokens into columns and for special row/column editing)

enum            --iParaTokens (paragraphs are split into groups of characters)
tokenText,          --text of token
tokenX,             --X pixel position of token (relative to paragraph position)
tokenY,             --Y pixel position of token (relative to paragraph position)
tokenWidth,         --Width of token 
tokenHeight,        --Hight of token 
tokenType,          --what kind of data is in the token
tokenInfo           --Extra information related to token type (to determine color, behavior, etc.)

-- Style configuration -------------------------------

enum            --tokenType
ttNone,             --none (plain text)
ttInvalid,          --invalid syntax
ttFound,            --highlight text of search result
ttIdentifier,       --identifier string
ttKeyword,          --keyword string
ttBuiltin,          --builtin word
ttNumber,           --number
ttSymbol,           --operator or other punctuation
ttBracket,          --() {} []
ttString,           --string inside quotes
ttComment           --comment text

object --todo: clean up options and styles
headingheight = 16,
thMonoFonts = {"Courier New", "Consolas"}, --, "DejaVu Sans Mono", "Liberation Mono"},
--todo: enumerate list of monowidth fonts availible and pick one
--Need to add some wrappers to oswin/win32:  EnumFontFamiliesEx function, LOGFONT structure, lfPitchAndFamily
thMonoFontSize = 10,
thLineNumberWidth = 40,
thBookmarkWidth = 16,
thLineFoldingWidth = 16,
thBackColor = th:cInnerFill, --th:cButtonFace
IndentSpace = repeat(' ', 4), --number of spaces to replace \t char with
optScrollPast = 0.5,  --amount to scroll past bottom line (must be in the range of 0 to 1.0) 
optViewShift = 0.8,  --amount to scroll up or down to keep active line in view (must be in the range of 0 to 1.0) 
optActiveSelBackColor = th:cInnerSel, --rgb(80, 80, 150),
optActiveSelTextColor = th:cInnerTextSel, --rgb(255, 255, 255)
optInactiveSelBackColor = th:cInnerSelInact,
optInactiveSelTextColor = th:cInnerTextSelInact,
optActiveCurrLineBkColor = rgb(250, 250, 180),
optInactiveCurrLineBkColor = rgb(220, 220, 220),
optCursorColor = rgb(80, 80, 250)

sequence
euIdentifiers = {}, --words recognised as declared identifiers (from analyzing existing source)
ttStyles = repeat({}, ttComment) --token styles: {textfont, textsize, textstyle, textcolor}
ttStyles[ttNone] = {Normal, th:cButtonLabel}
ttStyles[ttInvalid] = {Normal, th:cButtonLabel}
ttStyles[ttFound] = {Normal, th:cButtonLabel}
ttStyles[ttIdentifier] = {Normal, rgb(100, 0, 0)}
ttStyles[ttKeyword] = {Bold, rgb(0, 0, 100)}
ttStyles[ttBuiltin] = {Bold, rgb(0, 0, 128)}
ttStyles[ttNumber] = {Normal, rgb(0, 0, 80)}
ttStyles[ttSymbol] = {Normal, rgb(0, 0, 0)}
ttStyles[ttBracket] = {Normal,  rgb(200, 0, 0)}
ttStyles[ttString] = {Normal, rgb(0, 128, 0)}
ttStyles[ttComment] = {Italic, rgb(120, 100, 160)}

constant ctable = {  --color table, just to make it easy to give each plot a unique default color
    rgb(#04, #FF, #00),
    rgb(#FF, #BB, #00),
    rgb(#00, #C4, #FF),
    rgb(#FF, #7B, #00),
    rgb(#00, #FF, #BB),
    rgb(#FF, #3C, #00),
    rgb(#00, #FF, #FB),
    rgb(#FF, #FB, #00),
    rgb(#00, #84, #FF),
    rgb(#C3, #FF, #00)
}


sequence            --Info about each textedit instances
iName = {},             --Unique String that identifies instance
iCanvasName = {},       --Name of canvas currently being used or "" if hidden
iParentName = {},       --Name of parentn of canvas currently being used
iLabel = {},            --Label text (file name, page title, etc.)
iEventRid = {},         --Routine ID of external event handler

iSyntaxMode = {},       --type of syntax
iEditMode = {},         --edit mode (normal, block, or grid)
iLineNumbers = {},      --1=display line numbers, 0=hide line numbers
iLocked = {},           --editing: 0=unlocked, 1=locked
iModified = {},         --has been modified
iWordWrap = {},         --1=word wrapping, 0=no word wrapping

iTokenStyles = {},      --syntax highlighting styles
iSyntaxFont = {},       --font name to use
iSyntaxSize = {},       --font size to use

iTxtLnText = {},        --text line: raw text
iTxtLnTokens = {},      --text line: tokens {tokenTexts, tokenXs, tokenYs, tokenWidths, tokenHights, tokenTypes, tokenInfos}
iTxtLnSyntaxState = {}, --text line: ending state of syntax highlighting (so next line can start in correct state)
iTxtLnBookmark = {},    --text line: bookmark number, or 0 for not bookmarked
iTxtLnFold = {},        --text line: fold status: 0=not foldable, 1=not folded, 2=folded
iTxtLnVisible = {},     --text line: visible: 0=no, 1=yes (line may be hidden by folding a section or hiding comments)
iTxtLnTag = {},         --text line: string to identify line (for jumping to a routine)
iTxtLnPosX = {},        --text line: X pixel position of text line
iTxtLnPosY = {},        --text line: Y pixel position of text line
iTxtLnWidth = {},       --text line: Width pixel size of text line
iTxtLnHeight = {},      --text line: Hight pixel size of text line

iHardFocus = {},        --canvas has hardfocus
iCursorState = {},      --is cursor visible or not
iIsSelecting = {},      --is currently selecting text
iSelStartLine = {},     --selection start line
iSelStartCol = {},      --selection start column in line
iSelEndLine = {},       --selection end line
iSelEndCol = {},        --selection end column in line
iVirtualColX = {},       --virtual end column, to remember previous col when moving cursor up or down through shorter lines
iScrollX = {},          --Scroll X position
iScrollY = {},          --Scroll Y position

iLineNumWidth = {},     --width of line number area (automatically adjusts)
iTotalHeight = {},      --total width of all text lines
iTotalWidth = {},       --total height of all text lines

iBusyStatus = {},       --0 = ready, 1-100 = busy
iBusyTime = {},         --time busy became > 0 (if busy for longer than 0.5s, show progress indicator)
iCmdQueue = {},         --queue of commands to process
iUndoQueue = {}         --history of commands that can be undone

--Rules for using scol and ecol:
--
--When getting slices inside selection, the range must be [scol+1..ecol].
--Examples: "12345"
--scol = 0, ecol = 5 --> [1..5] --> "12345"
--scol = 2, ecol = 4 --> [3..4] --> "34"
--scol = 4, ecol = 5 --> [5..5] --> "5"
--scol = 0, ecol = 1 --> [1..1] --> "1"
--scol = 0, ecol = 0 --> [1..0] --> ""
--scol = 5, ecol = 5 --> [6..5] --> ""
--
--When getting slices outside selection, the ranges must be [1..scol] and [ecol+1..$].
--Examples: "12345"
--scol = 0, ecol = 5 --> [1..0] and [6..5] --> "" and ""
--scol = 2, ecol = 4 --> [1..2] and [5..5] --> "12" and "5"
--scol = 4, ecol = 5 --> [1..4] and [6..5] --> "1234" and ""
--scol = 0, ecol = 1 --> [1..0] and [2..5] --> "" and "2345"
--scol = 0, ecol = 0 --> [1..0] and [1..5] --> "" and "12345"
--scol = 5, ecol = 5 --> [1..5] and [6..5] --> "12345" and ""


--Tasks

atom
RebuildTask = task_create(routine_id("rebuild_lines_task"), {}),
CursorBlinkTask = task_create(routine_id("cursor_blink_task"), {})
sequence RebuildQueue = {}


procedure cursor_blink_task()
    while 1 do
        for idx = 1 to length(iName) do
            if gui:wexists(iCanvasName[idx]) and gui:widget_is_visible(iCanvasName[idx]) then
                --blink cursor if editor has focus
                if iCursorState[idx] > 1 then
                    iCursorState[idx] = 1
                elsif iCursorState[idx] = 0 then
                    iCursorState[idx] = 1
                    draw_lines(idx, iSelEndLine[idx], iSelEndLine[idx])
                else
                    iCursorState[idx] = 0
                    draw_lines(idx, iSelEndLine[idx], iSelEndLine[idx])
                end if
            end if
        end for
        task_yield()
    end while
end procedure


procedure rebuild_lines_task() --get syntax tokens to rebuild syntax state at end of each line, wordwrap, positions, sizes
    atom idx, startline, endline, whnd, prevlnw, MaxWidth, tt, tx, ty, SkipBelow = 0
    sequence tokens, txex, te, csize, emptysize, vislines, prevtotalsize
    
    while 1 do
        if length(RebuildQueue) > 0 then
            task_suspend(CursorBlinkTask)
            idx = find(RebuildQueue[1][1], iName)
            startline = RebuildQueue[1][2]
            endline = RebuildQueue[1][3]
            
            if idx > 0 then
                iBusyTime[idx] = time()
                
                if startline < 1 then
                    startline = 1
                end if
                if endline > length(iTxtLnText[idx]) then
                    endline = length(iTxtLnText[idx])
                end if
                whnd = gui:widget_get_handle(iCanvasName[idx])
                --set linenumber width:
                set_font(whnd, iSyntaxFont[idx], iSyntaxSize[idx], Normal)
                te = get_text_extent(whnd, sprint(length(iTxtLnText[idx]))) --get width of string of maximum line number
                prevlnw = iLineNumWidth[idx]
                iLineNumWidth[idx] = te[1] + iSyntaxSize[idx] * 2 + 12 --add extra space for bookmark/line folding symbols
                --get canvas size, etc.
                set_font(whnd, iSyntaxFont[idx], iSyntaxSize[idx], Normal)
                
                csize = gui:wfunc(iCanvasName[idx], "get_canvas_size", {})
                emptysize = get_text_extent(whnd, " ")
                MaxWidth = csize[1] - iLineNumWidth[idx] - th:scrwidth
                
                prevtotalsize = {iTotalWidth[idx], iTotalHeight[idx]}
                
                tt = time()
                
                if prevlnw != iLineNumWidth[idx] then --rebuild all lines if line number width changes
                    startline = 1
                    endline = length(iTxtLnText[idx])
                end if
                
                iTotalWidth[idx] = iLineNumWidth[idx] + MaxWidth
                iTotalHeight[idx] = floor((csize[2] - emptysize[2]) * optScrollPast)
                
                for li = startline to length(iTxtLnText[idx]) do
                    --update paragraph position (based on previous paragraph)
                    iTxtLnPosX[idx][li] = iLineNumWidth[idx]
                    if li = 1 then
                        iTxtLnPosY[idx][li] = 0
                    elsif li > 1 then
                        if li > endline and iTxtLnPosY[idx][li] = iTxtLnPosY[idx][li-1] + iTxtLnHeight[idx][li-1] then
                            SkipBelow = 1
                            exit
                        end if
                        iTxtLnPosY[idx][li] = iTxtLnPosY[idx][li-1] + iTxtLnHeight[idx][li-1]
                    end if
                    if li <= endline then --get tokens to calculate wordwrap and paragraph size 
                        tokenize_line(idx, li, MaxWidth)
                    end if
                    
                    --if taking too long, caculate percentage completed and yield
                    --todo: draw visible lines asap even if more lines need to be built below active area
                    if time() - iBusyTime[idx] > 0.05 then
                        gui:wproc(iCanvasName[idx], "set_background_pointer", {"Busy"})
                        iBusyStatus[idx] = floor(li / (length(iTxtLnText[idx]) - startline))
                        task_yield()
                        --iBusyTime[idx] = time()
                        set_font(whnd, iSyntaxFont[idx], iSyntaxSize[idx], Normal)
                    end if
                end for
                iTotalHeight[idx] = iTxtLnPosY[idx][$] + iTxtLnHeight[idx][$] + floor((csize[2] - emptysize[2]) * optScrollPast)
                if not equal(prevtotalsize, {iTotalWidth[idx], iTotalHeight[idx]}) then
                    gui:wproc(iCanvasName[idx], "set_canvas_size", {iTotalWidth[idx], iTotalHeight[idx]})
                end if
                iBusyStatus[idx] = 0
                iBusyTime[idx] = 0
                gui:wproc(iCanvasName[idx], "set_background_pointer", {"Ibeam"})
                
                if not scroll_to_active_line(idx) then
                    vislines = visible_lines(idx)
                    if startline < vislines[1] then
                        startline = vislines[1]
                    end if
                    if endline > vislines[2] then
                        endline = vislines[2]
                    end if
                    if startline > vislines[2] or endline < vislines[1] then --out of range, nothing needs to be redrawn
                    else
                        if SkipBelow = 0 then --lines that shifted up or down need to be drawn
                            endline = vislines[2]
                        end if
                        
                        draw_lines(idx, startline, endline)
                    end if
                end if
            end if
            task_schedule(CursorBlinkTask, {0.5, 0.6})
            RebuildQueue = RebuildQueue[2..$]
        end if
        task_yield()
    end while
end procedure


task_schedule(RebuildTask, 100)
task_schedule(CursorBlinkTask, {0.5, 0.6})


--Internal Functions

procedure tokenize_line(atom idx, atom li, atom liw)
--build tokens for line and calculate token positions with wordwrap based on specified width
--Note: set_font() must be called prior to calling this function, otherwise results of text_extent will be invalid
    sequence txt, tokens = {}, txex, temptokens, emptysize
    atom tx = 0, ty = 0, whnd
    
    if idx > 0 and li > 0 and li <= length(iTxtLnText[idx]) then
        --Parse text syntax into tokens
        if iSyntaxMode[idx] = synPlain then
            txt = iTxtLnText[idx][li]
            txt = match_replace("\t", txt, IndentSpace) --todo: handle tabs proprely by indenting tokens
            txt = filter(txt, "in",  {32,255}, "[]") --todo: replace invalid characters with placeholder
            --txt = split(txt)
            --if length(txt) > 1 then
            --    for tt = 1 to length(txt)-1 do
            --        txt[tt] &= ' '
            --    end for
            --end if
            if length(txt) = 0 then
                txt = "" --todo: indent as much as previous line?
            end if
            tokens = {
                {txt}, -- tokenText,          
                repeat(0, length(txt)), -- tokenX,             
                repeat(0, length(txt)), -- tokenY,             
                repeat(0, length(txt)), -- tokenWidth,         
                repeat(0, length(txt)), -- tokenHeight,        
                repeat(ttNone, length(txt)), -- tokenType,          
                repeat(0, length(txt))  -- tokenInfo
            }
            
        elsif iSyntaxMode[idx] = synEuphoria then
            txt = iTxtLnText[idx][li]
            txt = match_replace("\t", txt, IndentSpace)
            txt = filter(txt, "in",  {32,255}, "[]")
            --txt = split(txt)
            --if length(txt) = 0 then
            --    txt = {""} --todo: indent as much as previous line?
            --end if
            
-----------------------------------------------------------------------------------------------------------------------------------------------
            syncolor:reset()
    
        --{"NORMAL", ttNone},
        --{"COMMENT", ttComment},
        --{"KEYWORD", ttKeyword},
        --{"BUILTIN", ttBuiltin},
        --{"STRING", ttString},
        --{"BRACKET", {ttBracket, -1, -2, -3, -4, -5, -6, -7, -8, -9, -10}}
        
            sequence syntoks = syncolor:SyntaxColor(txt), tokwords
            object toktype
            sequence ttexts, ttypes, tinfos
            
            ttexts = {}
            ttypes = {}
            tinfos = {}
            
            for t = 1 to length(syntoks) do
                toktype = syntoks[t][1]
                tokwords = {syntoks[t][2]}
                for tt = 1 to length(tokwords) do
                    if toktype < 0 then
                        ttypes &= {ttBracket}
                        tinfos &= {0}
                        --tinfos &= {-toktype} --wierd negative number hack to identify different bracket colors
                    else
                        ttypes &= {toktype}
                        tinfos &= {0}
                    end if
                    ttexts &= {tokwords[tt]}
                end for
            end for
                
            if length(ttexts) = 0 then
                ttexts &= {""}
            end if
            ttypes &= repeat(ttNone, length(ttexts))
            tinfos &= repeat(0, length(ttexts))  
-----------------------------------------------------------------------------------------------------------------------------------------------


            tokens = {
                ttexts, -- tokenText,          
                repeat(0, length(ttexts)), -- tokenX,             
                repeat(0, length(ttexts)), -- tokenY,             
                repeat(0, length(ttexts)), -- tokenWidth,         
                repeat(0, length(ttexts)), -- tokenHeight,        
                ttypes, -- tokenType,          
                tinfos  -- tokenInfo
            }
            
        elsif iSyntaxMode[idx] = synCreole then
            
        elsif iSyntaxMode[idx] = synHTML then
            
        elsif iSyntaxMode[idx] = synCSS then
            
        elsif iSyntaxMode[idx] = synXML then
            
        elsif iSyntaxMode[idx] = synINI then
            
        elsif iSyntaxMode[idx] = synC then
            
        end if
        
        --Process tokens that are so long that they need to be wrapped (split them into additional tokens)
        temptokens = repeat({}, length(tokens))
        whnd = gui:widget_get_handle(iCanvasName[idx])
        for t = 1 to length(tokens[tokenText]) do
            if atom(tokens[tokenText][t]) then
                tokens[tokenText][t] = {tokens[tokenText][t]}
            end if
            txex = get_text_extent(whnd, tokens[tokenText][t]) -- & " ")
            if txex[1] > liw then --breakup into multiple tokens
                for ch = 2 to length(tokens[tokenText][t]) do
                    txex = get_text_extent(whnd, tokens[tokenText][t][1..ch])
                    if txex[1] > liw then
                        txt = breakup(tokens[tokenText][t], ch-1)
                        --txt[$] &= " "
                        exit
                    end if
                end for
            else
                txt = {tokens[tokenText][t]} -- & " "}
            end if
            if atom(txt) then
                txt = {txt}
            end if
            temptokens[tokenText] &= txt
            temptokens[tokenX] &= repeat(0, length(txt))
            temptokens[tokenY] &= repeat(0, length(txt))
            temptokens[tokenWidth] &= repeat(0, length(txt))
            temptokens[tokenHeight] &= repeat(0, length(txt))
            temptokens[tokenType] &= repeat(tokens[tokenType][t], length(txt))
            temptokens[tokenInfo] &= repeat(tokens[tokenInfo][t], length(txt))
        end for
        
        --Calculate token positions
        tokens = temptokens
        tx = 0
        ty = 0
        for t = 1 to length(tokens[tokenText]) do
            if atom(tokens[tokenText][t]) then
                tokens[tokenText][t] = {tokens[tokenText][t]}
            end if
            txex = get_text_extent(whnd, tokens[tokenText][t])
            if tx + txex[1] > liw then
                tx = 0
                ty += txex[2]
            end if
            tokens[tokenX][t] = tx
            tokens[tokenY][t] = ty
            tokens[tokenWidth][t] = txex[1]
            tokens[tokenHeight][t] = txex[2]
            tx += txex[1]
        end for
            
        iTxtLnTokens[idx][li] = tokens
        iTxtLnWidth[idx][li] = liw
        if length(tokens[tokenText]) > 0 then
            iTxtLnHeight[idx][li] = ty + txex[2]
        end if
        emptysize = get_text_extent(whnd, " ")
        if iTxtLnHeight[idx][li] < emptysize[2] then
            iTxtLnHeight[idx][li] = emptysize[2]
        end if
    end if
end procedure


function visible_lines(atom idx) --find text lines that are within view
    atom startline = 0, endline = 0
    object csize
    
    if idx > 0 then
        csize = gui:wfunc(iCanvasName[idx], "get_canvas_size", {})
        if sequence(csize) then
            for li = 1 to length(iTxtLnText[idx]) do
                if iTxtLnVisible[idx][li] then
                    if iTxtLnPosY[idx][li] + iTxtLnHeight[idx][li] - iScrollY[idx] > 0 and iTxtLnPosY[idx][li] - iScrollY[idx] < csize[2] then
                        if startline = 0 then
                            startline = li
                        end if
                        endline = li
                    end if
                end if
            end for
        end if
        if startline = 0 or endline = 0 then
            startline = length(iTxtLnText[idx])
            endline = length(iTxtLnText[idx])
        end if
        if startline > length(iTxtLnText[idx]) then
            startline = length(iTxtLnText[idx])
        end if
        if endline > length(iTxtLnText[idx]) then
            endline = length(iTxtLnText[idx])
        end if
    end if
    
    return {startline, endline}
end function


function char_coords(atom idx, atom li, atom col) --find X,Y, token number, and token col of a character (of specified textline)
    atom whnd, cx = 0, cy = 0, tnum = 0, tcol = 0, ccol, thight = 0, sch
    object txex, tokens
    
    if idx > 0 then
        tokens = iTxtLnTokens[idx][li]
        whnd = gui:widget_get_handle(iCanvasName[idx])
        if sequence(tokens) and whnd != 0 then
            txex = get_text_extent(whnd, " ")
            thight = txex[2]
            ccol = 0
            for t = 1 to length(tokens[tokenText]) do
                if t = 1 then
                    sch = 0
                else
                    sch = 1
                end if
                for ch = sch to length(tokens[tokenText][t]) do
                    if ccol > col-1 then --was ccol >= col
                        txex = get_text_extent(whnd, tokens[tokenText][t][1..ch])
                        cx = tokens[tokenX][t] + txex[1]
                        cy = tokens[tokenY][t]
                        tnum = t
                        tcol = ch
                        txex = get_text_extent(whnd, " ")
                        thight = txex[2]
                        exit
                    end if
                    ccol += 1
                end for
                if tnum > 0 then
                    exit
                end if
            end for
        end if
    end if
    
    return {cx, cy, tnum, tcol, thight}
end function


function get_mouse_pos(atom idx, atom mx, atom my)
    atom mline = 0, mcol = 0, mtoken = 0
    
    if idx > 0 then
        object tokens
        atom px, py, ccol
        sequence txex
        sequence vislines = visible_lines(idx)
        atom whnd = gui:widget_get_handle(iCanvasName[idx])
        set_font(whnd, iSyntaxFont[idx], iSyntaxSize[idx], Normal)
        
        for li = vislines[1] to vislines[2] do
            if iTxtLnVisible[idx][li] then
                px = iTxtLnPosX[idx][li] - iScrollX[idx]
                py = iTxtLnPosY[idx][li] - iScrollY[idx]
                if my >= py and my < py + iTxtLnHeight[idx][li] then
                    mline = li
                    ccol = 0
                    tokens = iTxtLnTokens[idx][li]
                    whnd = gui:widget_get_handle(iCanvasName[idx])
                    if sequence(tokens) and whnd != 0 then
                        for t = 1 to length(tokens[tokenText]) do
                            if my >= py + tokens[tokenY][t] and my < py + tokens[tokenY][t] + tokens[tokenHeight][t] then
                            --and mx >= px + tokens[tokenX][t] and mx < px + tokens[tokenX][t] + tokens[tokenWidth][t]
                                mtoken = t
                                for ch = 0 to length(tokens[tokenText][t]) do
                                    txex = get_text_extent(whnd, tokens[tokenText][t][1..ch])
                                    if px + tokens[tokenX][t] + txex[1] < mx then
                                        mcol = ccol + ch -- - 1
                                    end if
                                end for
                                if mx >= px + tokens[tokenX][t] and mx < px + tokens[tokenX][t] + tokens[tokenWidth][t] then
                                exit
                                end if
                            end if
                            ccol += length(tokens[tokenText][t])
                        end for
                        exit
                    end if
                    exit
                end if
            end if
            
         end for
    end if
    
    if mline > 0 then
        return {mline, mcol, mtoken}
    else
        return 0
    end if
end function


function pick_color(atom colornum) --pick a color from the color table
    atom len = length(ctable)
    while colornum > len do  --wrap around if idx > length(ctable)
        colornum -= len
    end while
    return ctable[colornum]
end function


--Internal procedures

procedure rebuild_lines(atom idx, atom startline, atom endline)
    if idx > 0 then
        iBusyStatus[idx] = 1
        iBusyTime[idx] = 0
        gui:wproc(iCanvasName[idx], "set_background_pointer", {"Busy"})
        RebuildQueue &= {{iName[idx], startline, endline}}
    end if
end procedure


procedure draw_lines(atom idx, atom startline, atom endline)
    if idx > 0 and startline > 0 and endline >= startline then
        atom bwidth, ih, whnd, px, py, tx, ty, sline, scol, eline, ecol, lnx, MaxWidth, starty, endy, currchar,
        hasfocus, selbackcolor, seltextcolor, currlinebackcolor
        sequence tokens, tokstyle, txex, emptysize, csize, brect, trect, ccmds, bcmds, tcmds, lcmds, hshape, scc, ecc
        
        --? {{iSelStartLine[idx], iSelEndCol[idx], iSelEndLine[idx], iSelStartCol[idx]}, {startline, endline}}
        whnd = gui:widget_get_handle(iCanvasName[idx])
        if whnd = 0 then
            return
        end if
        
        if iHardFocus[idx] and whnd = gui:get_window_focus() then
            hasfocus = 1
            selbackcolor = optActiveSelBackColor
            seltextcolor = optActiveSelTextColor
            currlinebackcolor = optActiveCurrLineBkColor
        else
            hasfocus = 0
            selbackcolor = optInactiveSelBackColor
            seltextcolor = optInactiveSelTextColor
            currlinebackcolor = optInactiveCurrLineBkColor
        end if
        
        bwidth = iLineNumWidth[idx]
        ih = iSyntaxSize[idx]+4
        
        set_font(whnd, iSyntaxFont[idx], iSyntaxSize[idx], Normal)
        emptysize = get_text_extent(whnd, " ")
        csize = gui:wfunc(iCanvasName[idx], "get_canvas_size", {})
        
        starty = iTxtLnPosY[idx][startline] - iScrollY[idx]
        if endline = length(iTxtLnText[idx]) then
            endy = csize[2]
        else
            endy = iTxtLnPosY[idx][endline] + iTxtLnHeight[idx][endline] - iScrollY[idx]
        end if
        if starty < 0  then
            starty = 0
        end if
        if endy > csize[2]  then
            endy = csize[2]
        end if
        
        brect = {0, starty, bwidth, endy}
        trect = {bwidth, starty, csize[1], endy}
        ccmds = {   --cursor commands
            --{DR_PenColor, rgb(0, 0, 0)},
            --{DR_Line, cx, cy, cx, cy+ih}
        }
        bcmds = {
            {DR_PenColor, th:cButtonFace},
            {DR_Rectangle, True, brect[1], brect[2], brect[3], brect[4]}
        }
        tcmds = {   --text area commands
            {DR_PenColor, thBackColor},
            {DR_Rectangle, True, trect[1], trect[2], trect[3], trect[4]}
            --{DR_TextColor, th:cButtonLabel},
            --{DR_Font, iSyntaxFont[idx], iSyntaxSize[idx], Normal}
            --{DR_Restrict, trect[1], trect[2], trect[3], trect[4]}
        }
        lcmds = {   --line number, bookmark, folding (margin) area commands
            --{DR_Release},
            {DR_TextColor, th:cButtonLabel},
            {DR_Font, iSyntaxFont[idx], iSyntaxSize[idx], Normal}
        }
        hshape = {  --handle shape for line number, bookmark, folding (margin) area
            {DR_Rectangle, True, brect[1], brect[2], brect[3], brect[4]}
        }
        lnx = brect[1] + iSyntaxSize[idx] + 6
        
        if iSelStartLine[idx] > iSelEndLine[idx] then
            sline = iSelEndLine[idx]
            scol = iSelEndCol[idx]
            eline = iSelStartLine[idx]
            ecol = iSelStartCol[idx]
        elsif iSelStartLine[idx] = iSelEndLine[idx] and iSelStartCol[idx] > iSelEndCol[idx] then
            sline = iSelStartLine[idx]
            scol = iSelEndCol[idx]
            eline = iSelEndLine[idx]
            ecol = iSelStartCol[idx]
        else
            sline = iSelStartLine[idx]
            scol = iSelStartCol[idx]
            eline = iSelEndLine[idx]
            ecol = iSelEndCol[idx]
        end if
        
        for li = startline to endline do
            if iTxtLnVisible[idx][li] then
                if atom(iTxtLnTokens[idx][li]) then --this shouldn't happen, but just in case
                    --refresh_lines(idx, li, endline)
                    exit
                end if
                tokens = iTxtLnTokens[idx][li]
                
                px = iTxtLnPosX[idx][li] - iScrollX[idx]
                py = iTxtLnPosY[idx][li] - iScrollY[idx]
                scc = char_coords(idx, sline, scol) --{cx, cy, tnum, tcol, thight}
                ecc = char_coords(idx, eline, ecol)
                
                
                --append line number drawing commands
                lcmds &= {
                    {DR_PenPos, lnx, py},
                    {DR_Puts, sprintf("%d", {li})}
                }
                if iTxtLnBookmark[idx][li] = 1 then
                    lcmds &= {  --draw bookmark symbol
                        {DR_PenColor, rgb(180, 180, 250)},
                        {DR_RoundRect, True, brect[1]+2, py+1, brect[1]+ih, py+ih-1, ih, ih}
                    }
                end if
                if iTxtLnFold[idx][li] = 1 then
                    lcmds &= {  --draw fold symbol
                        {DR_PenColor, rgb(128, 128, 128)},
                        {DR_Rectangle, False, brect[3]-ih, py+1, brect[3]-2, py+ih-1},
                        {DR_Line, floor((brect[3]-ih + brect[3]-2) / 2), py+1+2, floor((brect[3]-ih + brect[3]-2) / 2), py+ih-1-2},
                        {DR_Line, brect[3]-ih+2, floor((py+1 + py+ih-1) / 2), brect[3]-2-2, floor((py+1 + py+ih-1) / 2)}
                    }
                end if
                
                --draw tokens
                for t = 1 to length(tokens[tokenText]) do
                    /*tokens[tokenText][t]
                    tokens[tokenX][t]
                    tokens[tokenY][t]
                    tokens[tokenWidth][t]
                    tokens[tokenHeight][t]
                    tokens[tokenType][t]
                    tokens[tokenInfo][t]*/
                    tokstyle = ttStyles[tokens[tokenType][t]]
                    
                    if tokens[tokenType][t] = ttBracket and tokens[tokenInfo][t] > 0 then
                        tokstyle[2] = pick_color(tokens[tokenInfo][t])
                    end if
                    
                     --draw text
                    if li > sline and li < eline then --line in middle of selection
                        --mode 1: highlight background for entire line (before drawing 1st token only)
                        if t = 1 then
                            tcmds &= {
                                {DR_PenColor, selbackcolor},
                                {DR_Rectangle, True,
                                    px, py,
                                    csize[1], py + iTxtLnHeight[idx][li]
                                }
                            }
                        end if
                        tcmds &= {
                            --selected text:
                            /*
                            --mode 2: highlight background for each token (not currently used)
                            {DR_PenColor, selbackcolor},
                            {DR_Rectangle, True,
                                px + tokens[tokenX][t], py + tokens[tokenY][t],
                                px + tokens[tokenX][t] + tokens[tokenWidth][t], py + tokens[tokenY][t] + tokens[tokenHeight][t]
                            },
                            */
                            {DR_TextColor, seltextcolor},
                            {DR_Font, iSyntaxFont[idx], iSyntaxSize[idx], tokstyle[1]},
                            {DR_PenPos, px + tokens[tokenX][t], py + tokens[tokenY][t]},
                            {DR_Puts, tokens[tokenText][t]}
                        }
                        
                    else
                        if t = 1 then --before drawing tokens, draw background color
                            if li = iSelEndLine[idx] then
                            --draw highlight background color for active line
                                tcmds &= {
                                    {DR_PenColor, currlinebackcolor},
                                    {DR_Rectangle, True, px, py, csize[1], py + iTxtLnHeight[idx][li]}
                                }
                            end if
                        end if

                        tcmds &= {
                            --unselected text: 
                            {DR_PenColor, rgb(255,255,255)}, --temp color
                            {DR_TextColor, rgb(0,0,40)}, --temp color
                            {DR_TextColor, tokstyle[2]},
                            {DR_Font, iSyntaxFont[idx], iSyntaxSize[idx], tokstyle[1]},
                            {DR_PenPos, px + tokens[tokenX][t], py + tokens[tokenY][t]},
                            {DR_Puts, tokens[tokenText][t]}
                            
                            --Token debug:
                            --{DR_PenColor, rgb(200,0,0)},
                            --{DR_Rectangle, False, px + tokens[tokenX][t], py + tokens[tokenY][t],
                            --    px + tokens[tokenX][t] + tokens[tokenWidth][t], py + tokens[tokenY][t] + tokens[tokenHeight][t]}
                        }
                        
                        --draw selected text if needed
                        if li = sline and li = eline then --selection starts and ends on same line
                            --scc = char_coords(idx, sline, scol) --{cx, cy, tnum, tcol, thight}
                            --ecc = char_coords(idx, eline, ecol) --{cx, cy, tnum, tcol, thight}
                            
                            if t = scc[3] and t = ecc[3] then --selection starts and ends in same token
                                tcmds &= {
                                    {DR_PenColor, selbackcolor},
                                    {DR_Rectangle, True,
                                        px + scc[1], py + tokens[tokenY][t],
                                        px + ecc[1], py + tokens[tokenY][t] + tokens[tokenHeight][t]
                                    },
                                    {DR_TextColor, seltextcolor},
                                    {DR_Font, iSyntaxFont[idx], iSyntaxSize[idx], tokstyle[1]},
                                    {DR_PenPos, px + scc[1], py + tokens[tokenY][t]},
                                    {DR_Puts, tokens[tokenText][t][scc[4]+1..ecc[4]]}
                                }
                                
                            elsif t = scc[3] then --selection starts in this token
                                if ecc[2] > scc[2] then
                                    tcmds &= {
                                        {DR_PenColor, selbackcolor},
                                        {DR_Rectangle, True,
                                            px + scc[1], py + tokens[tokenY][t],
                                            csize[1], py + ecc[2]
                                        }
                                    }
                                else
                                    tcmds &= {
                                        {DR_PenColor, selbackcolor},
                                        {DR_Rectangle, True,
                                            px + scc[1], py + tokens[tokenY][t],
                                            px + tokens[tokenX][t] +  tokens[tokenWidth][t], py + tokens[tokenY][t] + tokens[tokenHeight][t]
                                        }
                                    }
                                end if
                                tcmds &= {
                                    {DR_TextColor, seltextcolor},
                                    {DR_Font, iSyntaxFont[idx], iSyntaxSize[idx], tokstyle[1]},
                                    {DR_PenPos, px + scc[1], py + tokens[tokenY][t]},
                                    {DR_Puts, tokens[tokenText][t][scc[4]+1..$]}
                                }
                            elsif t > scc[3] and t < ecc[3] then --token is in middle of selection
                                tcmds &= {
                                    {DR_PenColor, selbackcolor},
                                    {DR_Rectangle, True,
                                        px + tokens[tokenX][t], py + tokens[tokenY][t],
                                        px + tokens[tokenX][t] + tokens[tokenWidth][t], py + tokens[tokenY][t] + tokens[tokenHeight][t]
                                    },
                                    {DR_TextColor, seltextcolor},
                                    {DR_Font, iSyntaxFont[idx], iSyntaxSize[idx], tokstyle[1]},
                                    {DR_PenPos, px + tokens[tokenX][t], py + tokens[tokenY][t]},
                                    {DR_Puts, tokens[tokenText][t]}
                                }
                            elsif t = ecc[3] then --selection ends in this token
                                tcmds &= {
                                    {DR_PenColor, selbackcolor},
                                    {DR_Rectangle, True,
                                        px + tokens[tokenX][t], py + tokens[tokenY][t],
                                        px + ecc[1], py + tokens[tokenY][t] + tokens[tokenHeight][t]
                                    },
                                    {DR_TextColor, seltextcolor},
                                    {DR_Font, iSyntaxFont[idx], iSyntaxSize[idx], tokstyle[1]},
                                    {DR_PenPos, px + tokens[tokenX][t], py + tokens[tokenY][t]},
                                    {DR_Puts, tokens[tokenText][t][1..ecc[4]]}
                                }
                            end if
                            
                        elsif li = sline then --selection starts on this line
                            if t = scc[3] then --selection starts in this token
                                tcmds &= {
                                    {DR_PenColor, selbackcolor},
                                    {DR_Rectangle, True,
                                        px + scc[1], py + tokens[tokenY][t],
                                        csize[1], py + tokens[tokenY][t] + tokens[tokenHeight][t]
                                    },
                                    {DR_Rectangle, True,
                                        px, py + tokens[tokenY][t] + tokens[tokenHeight][t],
                                        csize[1], py + iTxtLnHeight[idx][li]
                                    },
                                    {DR_TextColor, seltextcolor},
                                    {DR_Font, iSyntaxFont[idx], iSyntaxSize[idx], tokstyle[1]},
                                    {DR_PenPos, px + scc[1], py + tokens[tokenY][t]},
                                    {DR_Puts, tokens[tokenText][t][scc[4]+1..$]}
                                }
                            elsif t > scc[3] then --token is in middle of selection
                                tcmds &= {
                                    {DR_PenColor, selbackcolor},
                                    {DR_Rectangle, True,
                                        px + tokens[tokenX][t], py + tokens[tokenY][t],
                                        px + tokens[tokenX][t] + tokens[tokenWidth][t], py + tokens[tokenY][t] + tokens[tokenHeight][t]
                                    },
                                    {DR_TextColor, seltextcolor},
                                    {DR_Font, iSyntaxFont[idx], iSyntaxSize[idx], tokstyle[1]},
                                    {DR_PenPos, px + tokens[tokenX][t], py + tokens[tokenY][t]},
                                    {DR_Puts, tokens[tokenText][t]}
                                }
                            end if
                        elsif li = eline then --selection ends on this line
                            if t < ecc[3] then --token is in middle of selection
                                if t = 1 then
                                    tcmds &= {
                                        {DR_PenColor, selbackcolor},
                                        {DR_Rectangle, True,
                                            px + tokens[tokenX][t], py + tokens[tokenY][t],
                                            csize[1], py + ecc[2]
                                        }
                                    }
                                end if
                                tcmds &= {
                                    {DR_PenColor, selbackcolor},
                                    {DR_Rectangle, True,
                                        px + tokens[tokenX][t], py + tokens[tokenY][t],
                                        px + tokens[tokenX][t] + tokens[tokenWidth][t], py + tokens[tokenY][t] + tokens[tokenHeight][t]
                                    },
                                    {DR_TextColor, seltextcolor},
                                    {DR_Font, iSyntaxFont[idx], iSyntaxSize[idx], tokstyle[1]},
                                    {DR_PenPos, px + tokens[tokenX][t], py + tokens[tokenY][t]},
                                    {DR_Puts, tokens[tokenText][t]}
                                }
                            elsif t = ecc[3] then --selection ends in this token
                                tcmds &= {
                                    {DR_PenColor, selbackcolor},
                                    {DR_Rectangle, True,
                                        px + tokens[tokenX][t], py + tokens[tokenY][t],
                                        px + ecc[1], py + tokens[tokenY][t] + tokens[tokenHeight][t]
                                    },
                                    {DR_TextColor, seltextcolor},
                                    {DR_Font, iSyntaxFont[idx], iSyntaxSize[idx], tokstyle[1]},
                                    {DR_PenPos, px + tokens[tokenX][t], py + tokens[tokenY][t]},
                                    {DR_Puts, tokens[tokenText][t][1..ecc[4]]}
                                }
                            end if
                        end if
                    end if
                end for
                
                --draw cursor if no selection
                if hasfocus and iCursorState[idx] > 0 and li = sline and li = eline and scol = ecol then
                    --draw_cursor
                    tcmds &= {
                        {DR_PenColor, optCursorColor},
                        {DR_Rectangle, True,
                            px + ecc[1] - 1, py + ecc[2],
                            px + ecc[1] + 1, py + ecc[2] + ecc[5]
                        }
                    }
                end if
            end if
        end for
        
        gui:wproc(iCanvasName[idx], "draw_background", {tcmds & bcmds & lcmds})
        --gui:wproc(iCanvasName[idx], "clear_handles", {})
        gui:wproc(iCanvasName[idx], "set_handle", {"lineheaders", hshape, "Arrow"})
        gui:wproc(iCanvasName[idx], "set_background_pointer", {"Ibeam"})
    end if
end procedure


function clean_text(object raw)  --clean up text
    --Possible forms of raw:
    --'a'
    --""
    --"abc"
    --"abc\ndef"
    --{""}
    --{"abc"}
    --{"abc", "def"}
    
    sequence txt = {""}
    
    --convert to sequence of text lines
    if atom(raw) then --'a'
        txt = {{raw}}
    elsif sequence(raw) then
        if length(raw) = 0 then --""
            txt = {""}
        elsif length(raw) > 0 then
            if atom(raw[1]) then --"abc" or "abc\ndef"
                txt = remove_all(13, raw)
                txt = split(txt, 10)
            elsif sequence(raw[1]) then --{""} or {"abc"} or {"abc", "def"}
                txt = raw
            end if
        end if
    end if
    
    --pretty_print(1, txt, {2})
    -- remove unwanted character codes
    --for li = 1 to length(txt) do
    --    txt[li] = filter(txt[li], "in",  {32,255}, "[]")
    --end for
    
    return txt
end function


function get_rel_pos(atom idx, atom lis, atom cols)
    atom li, col, yoffset, chkli
    atom whnd = gui:widget_get_handle(iCanvasName[idx])
    object cc, mpos
    
    li = 0
    col = 0
    
    --check if the current line or the line that would be selected has multiple rows, which requires a different method to move up and down
    if lis != 0 and whnd != 0 then
        chkli = iSelEndLine[idx]
        if length(iTxtLnTokens[idx][chkli][tokenText]) > 0 and iTxtLnHeight[idx][chkli] > iTxtLnTokens[idx][chkli][tokenHeight][1] then
            li = iSelEndLine[idx]
        end if
        chkli = iSelEndLine[idx] + lis
        if chkli < 1 then
            chkli = 1
        end if
        if chkli > length(iTxtLnText[idx]) then
            chkli = length(iTxtLnText[idx])
        end if
        if length(iTxtLnTokens[idx][chkli][tokenText]) > 0 and iTxtLnHeight[idx][chkli] > iTxtLnTokens[idx][chkli][tokenHeight][1] then
            li = iSelEndLine[idx]
        end if
    end if
    
    if li > 0 then
    --this line has more that one row (wrapped around):
        set_font(whnd, iSyntaxFont[idx], iSyntaxSize[idx], Normal)
        cc = char_coords(idx, iSelEndLine[idx], iSelEndCol[idx]+1) --{cx, cy, tnum, tcol, thight}
        
        yoffset = cc[5] * lis
        mpos = get_mouse_pos(idx, 
            iTxtLnPosX[idx][li] - iScrollX[idx] + cc[1],
            iTxtLnPosY[idx][li] - iScrollY[idx] + cc[2] + floor(cc[5]/2) + yoffset
        )
        if sequence(mpos) then --{mline, mcol, mtoken}
            li = mpos[1]
            col = mpos[2]
        end if
    else
    --this line is a single row
        li = iSelEndLine[idx] + lis
        col = iSelEndCol[idx]
        if li < 1 then
            li = 1
        end if
        if li > length(iTxtLnText[idx]) then
            li = length(iTxtLnText[idx])
        end if
        
        if lis = 0 then
            iVirtualColX[idx] = 0
        elsif iVirtualColX[idx] > 0 then
            col = iVirtualColX[idx]
            iVirtualColX[idx] = 0
        end if
        if col > length(iTxtLnText[idx][li]) then
            iVirtualColX[idx] = col
            col = length(iTxtLnText[idx][li])
        end if
    end if
    
    --Relative Line Position (before applying relative row position, but normally lis and cols are not both used at the same time) 
    if li < 1 then
        li = 1
        col = 0
    end if
    if li > length(iTxtLnText[idx]) then
        li = length(iTxtLnText[idx])
        col = length(iTxtLnText[idx][li])
    end if
    
    if lis = 0 and cols != 0 then
        --Relative Column position
        while cols != 0 do
            if cols < 0 then
                cols += 1
                col -= 1
                if col < 0 then
                    li -= 1
                    if li < 1 then
                        li = 1
                        col = 0
                        exit
                    end if
                    col = length(iTxtLnText[idx][li])
                end if
            elsif cols > 0 then
                cols -= 1
                col += 1
                if col > length(iTxtLnText[idx][li]) then
                    li += 1
                    if li > length(iTxtLnText[idx]) then
                        li = length(iTxtLnText[idx])
                        col = length(iTxtLnText[idx][li])
                        exit
                    end if
                    col = 0
                end if
            end if
        end while
    end if
    
    return {li, col}
end function

function is_selection(atom idx)
    atom issel = 0
    if idx > 0 then
        if iSelStartLine[idx] != iSelEndLine[idx] or iSelStartCol[idx] != iSelEndCol[idx] then
            issel = 1
        end if
    end if
    return issel
end function


function scroll_to_active_line(atom idx)
    if idx > 0 and gui:wexists(iCanvasName[idx]) then
        sequence vislines = visible_lines(idx)
        sequence csize = gui:wfunc(iCanvasName[idx], "get_canvas_size", {})
        if iSelEndLine[idx] > vislines[1] + 1 and iSelEndLine[idx] < vislines[2] - 1 then
            return 0 --didn't need to scroll
        else
            if iSelEndLine[idx] <= (vislines[2] - vislines[1]) / 2 then --scroll up
                gui:wproc(iCanvasName[idx], "scroll_to", 
                    {0, iTxtLnPosY[idx][iSelEndLine[idx]] - floor(csize[2] * optViewShift)
                })
            else
                gui:wproc(iCanvasName[idx], "scroll_to", 
                    {0, iTxtLnPosY[idx][iSelEndLine[idx]] - csize[2] + floor(csize[2] * optViewShift)
                })
            end if
            iCursorState[idx] = 2
            --return 1 --needed to scroll, don't need to manually redraw after calling this function
            return 0 --disabled this, because it causes a problem when there are only a few lines of text
        end if
    end if
    return 0
end function

--Text Lines Operations: These routines perform specific modifications to text lines data, called by "commands" 

procedure move_cursor_to(atom idx, object li, object col)  --move cursor to position (absolute {line, col})
    if idx > 0 then
        sequence refreshlines
        if sequence(li) then
            if equal(li, ".") then
                li = iSelEndLine[idx]
            elsif equal(li, "$") then
                li = length(iTxtLnText[idx])
            else
                li = 1
            end if
        end if
        if li < 1 then
            li = 1
        end if
        if li > length(iTxtLnText[idx]) then
            li = length(iTxtLnText[idx])
        end if
        if sequence(col) then
            if equal(col, ".") then
                col = iSelEndCol[idx]
            elsif equal(col, "$") then
                col = length(iTxtLnText[idx][li])
            else
                col = 0
            end if
        end if
        if col < 0 then
            col = 0
        end if
        if col > length(iTxtLnText[idx][li]) then
            col = length(iTxtLnText[idx][li])
        end if
        
        refreshlines = {li, li}
        if iSelStartLine[idx] != li or iSelEndLine[idx] != li then
            refreshlines = visible_lines(idx)
        end if
        iSelStartLine[idx] = li
        iSelStartCol[idx] = col
        iSelEndLine[idx] = li
        iSelEndCol[idx] = col
        iCursorState[idx] = 2
        
        if not scroll_to_active_line(idx) then --keep end of selection in view
            draw_lines(idx, refreshlines[1], refreshlines[2])
        end if
    end if
end procedure


procedure move_cursor_rel(atom idx, atom lis, atom cols) --move cursor to position (forward or backward, relative to cursor)
    if idx > 0 then
        sequence relpos = get_rel_pos(idx, lis, cols)
        move_cursor_to(idx, relpos[1], relpos[2])
    end if
end procedure


procedure select_to(atom idx, object li, object col) --select from cursor to position (absolute {line, col})
    if idx > 0 then
        sequence refreshlines
        if sequence(li) then
            if equal(li, ".") then
                li = iSelEndLine[idx]
            elsif equal(li, "$") then
                li = length(iTxtLnText[idx])
            else
                li = 1
            end if
        end if
        if li < 1 then
            li = 1
        end if
        if li > length(iTxtLnText[idx]) then
            li = length(iTxtLnText[idx])
        end if
        if sequence(col) then
            if equal(col, ".") then
                col = iSelEndCol[idx]
            elsif equal(col, "$") then
                col = length(iTxtLnText[idx][li])
            else
                col = 0
            end if
        end if
        if col < 0 then
            col = 0
        end if
        if col > length(iTxtLnText[idx][li]) then
            col = length(iTxtLnText[idx][li])
        end if
        
        refreshlines = {li, li}
        if iSelStartLine[idx] != li or iSelEndLine[idx] != li then
            refreshlines = visible_lines(idx)
        end if
        iSelEndLine[idx] = li
        iSelEndCol[idx] = col
        
        if not scroll_to_active_line(idx) then --keep end of selection in view
            draw_lines(idx, refreshlines[1], refreshlines[2])
        end if
    end if
end procedure


procedure select_rel(atom idx, atom lis, atom cols) --select number of characters (forward or backward, relative to cursor)
    if idx > 0 then
        sequence relpos = get_rel_pos(idx, lis, cols)
        select_to(idx, relpos[1], relpos[2])
    end if
end procedure


procedure delete_selection(atom idx) --Delete selection
    sequence txt = {""}
    if idx > 0 then
        sequence refreshlines
        atom sline, scol, eline, ecol
        if iSelStartLine[idx] > iSelEndLine[idx] then
            sline = iSelEndLine[idx]
            scol = iSelEndCol[idx]
            eline = iSelStartLine[idx]
            ecol = iSelStartCol[idx]
        elsif iSelStartLine[idx] = iSelEndLine[idx] and iSelStartCol[idx] > iSelEndCol[idx] then
            sline = iSelStartLine[idx]
            scol = iSelEndCol[idx]
            eline = iSelEndLine[idx]
            ecol = iSelStartCol[idx]
        else
            sline = iSelStartLine[idx]
            scol = iSelStartCol[idx]
            eline = iSelEndLine[idx]
            ecol = iSelEndCol[idx]
        end if
        
        refreshlines = {sline, eline}
        if sline = eline and scol = ecol then --nothing is selected
        else  --delete selection --When getting slices outside selection, the ranges must be [1..scol] and [ecol+1..$].
            iTxtLnText[idx][sline]      = iTxtLnText[idx][sline][1..scol]   & iTxtLnText[idx][eline][ecol+1..$]
            if eline > sline then --multiple lines of text
                iTxtLnText[idx]         = iTxtLnText[idx][1..sline]         & iTxtLnText[idx][eline+1..$]
                iTxtLnTokens[idx]       = iTxtLnTokens[idx][1..sline]       & iTxtLnTokens[idx][eline+1..$]
                iTxtLnSyntaxState[idx]  = iTxtLnSyntaxState[idx][1..sline]  & iTxtLnSyntaxState[idx][eline+1..$]
                iTxtLnBookmark[idx]     = iTxtLnBookmark[idx][1..sline]     & iTxtLnBookmark[idx][eline+1..$]
                iTxtLnFold[idx]         = iTxtLnFold[idx][1..sline]         & iTxtLnFold[idx][eline+1..$]
                iTxtLnVisible[idx]      = iTxtLnVisible[idx][1..sline]      & iTxtLnVisible[idx][eline+1..$]
                iTxtLnTag[idx]          = iTxtLnTag[idx][1..sline]          & iTxtLnTag[idx][eline+1..$]
                iTxtLnPosX[idx]         = iTxtLnPosX[idx][1..sline]         & iTxtLnPosX[idx][eline+1..$]
                iTxtLnPosY[idx]         = iTxtLnPosY[idx][1..sline]         & iTxtLnPosY[idx][eline+1..$]
                iTxtLnWidth[idx]        = iTxtLnWidth[idx][1..sline]        & iTxtLnWidth[idx][eline+1..$]
                iTxtLnHeight[idx]       = iTxtLnHeight[idx][1..sline]       & iTxtLnHeight[idx][eline+1..$]
            end if
        end if
        iSelStartLine[idx] = sline
        iSelStartCol[idx] = scol
        iSelEndLine[idx] = sline
        iSelEndCol[idx] = scol
        iCursorState[idx] = 2
        rebuild_lines(idx, refreshlines[1], refreshlines[2])
    end if
end procedure


--procedure delete_rel(atom idx, object chars) --delete one or more chars (forward or backward, relative to cursor) (invalid if text is selected)
--end procedure


procedure text_put(atom idx, object chars)  --Insert 1 or more characters at cursor (invalid if text is selected)
    if idx > 0 then
        sequence txt = clean_text(chars)
        atom sline, scol, eline, ecol, oldtextendlen
        sequence pretext, posttext
        if iSelStartLine[idx] > iSelEndLine[idx] then
            sline = iSelEndLine[idx]
            scol = iSelEndCol[idx]
            eline = iSelStartLine[idx]
            ecol = iSelStartCol[idx]
        elsif iSelStartLine[idx] = iSelEndLine[idx] and iSelStartCol[idx] > iSelEndCol[idx] then
            sline = iSelStartLine[idx]
            scol = iSelEndCol[idx]
            eline = iSelEndLine[idx]
            ecol = iSelStartCol[idx]
        else
            sline = iSelStartLine[idx]
            scol = iSelStartCol[idx]
            eline = iSelEndLine[idx]
            ecol = iSelEndCol[idx]
        end if
        
        if sline != eline or scol != ecol then
            delete_selection(idx)
        end if
        
        --When getting slices outside selection, the ranges must be [1..scol] and [ecol+1..$].
        pretext = iTxtLnText[idx][sline][1..scol]
        posttext = iTxtLnText[idx][eline][ecol+1..$]
        if length(txt) = 1 then
            iTxtLnText[idx][sline] = pretext & txt[1] & posttext
            
        elsif length(txt) > 1 then
            iTxtLnText[idx][sline] = pretext & txt[1]
            oldtextendlen = length(txt[$])
            txt[$] = posttext & txt[$]
            iTxtLnText[idx]         = iTxtLnText[idx][1..sline]         & txt[2..$]                & iTxtLnText[idx][eline+1..$]
            iTxtLnTokens[idx]       = iTxtLnTokens[idx][1..sline]       & repeat(0, length(txt)-1) & iTxtLnTokens[idx][eline+1..$]
            iTxtLnSyntaxState[idx]  = iTxtLnSyntaxState[idx][1..sline]  & repeat(0, length(txt)-1) & iTxtLnSyntaxState[idx][eline+1..$]
            iTxtLnBookmark[idx]     = iTxtLnBookmark[idx][1..sline]     & repeat(0, length(txt)-1) & iTxtLnBookmark[idx][eline+1..$]
            iTxtLnFold[idx]         = iTxtLnFold[idx][1..sline]         & repeat(0, length(txt)-1) & iTxtLnFold[idx][eline+1..$]
            iTxtLnVisible[idx]      = iTxtLnVisible[idx][1..sline]      & repeat(1, length(txt)-1) & iTxtLnVisible[idx][eline+1..$]
            iTxtLnTag[idx]          = iTxtLnTag[idx][1..sline]          & repeat(0, length(txt)-1) & iTxtLnTag[idx][eline+1..$]
            iTxtLnPosX[idx]         = iTxtLnPosX[idx][1..sline]         & repeat(0, length(txt)-1) & iTxtLnPosX[idx][eline+1..$]
            iTxtLnPosY[idx]         = iTxtLnPosY[idx][1..sline]         & repeat(0, length(txt)-1) & iTxtLnPosY[idx][eline+1..$]
            iTxtLnWidth[idx]        = iTxtLnWidth[idx][1..sline]        & repeat(0, length(txt)-1) & iTxtLnWidth[idx][eline+1..$]
            iTxtLnHeight[idx]       = iTxtLnHeight[idx][1..sline]       & repeat(0, length(txt)-1) & iTxtLnHeight[idx][eline+1..$]
        end if
        
        if length(txt) > 0 then
            iSelStartLine[idx] = sline + length(txt) - 1
            if length(txt) = 1 then
                iSelStartCol[idx] = scol + length(txt[1])
            elsif length(txt) > 1 then
                iSelStartCol[idx] = oldtextendlen
            end if
            iSelEndLine[idx] = iSelStartLine[idx]
            iSelEndCol[idx] = iSelStartCol[idx]
            iCursorState[idx] = 2
            --scroll_to_active_line(idx)
            rebuild_lines(idx, sline, iSelEndLine[idx]+1)
        end if
    end if
end procedure


function text_get(atom idx)  --Get selected text
    sequence txt = {""}
    if idx > 0 then
        atom sline, scol, eline, ecol
        if iSelStartLine[idx] > iSelEndLine[idx] then
            sline = iSelEndLine[idx]
            scol = iSelEndCol[idx]
            eline = iSelStartLine[idx]
            ecol = iSelStartCol[idx]
        elsif iSelStartLine[idx] = iSelEndLine[idx] and iSelStartCol[idx] > iSelEndCol[idx] then
            sline = iSelStartLine[idx]
            scol = iSelEndCol[idx]
            eline = iSelEndLine[idx]
            ecol = iSelStartCol[idx]
        else
            sline = iSelStartLine[idx]
            scol = iSelStartCol[idx]
            eline = iSelEndLine[idx]
            ecol = iSelEndCol[idx]
        end if
        
        if sline = eline and scol = ecol then --nothing is selected
        else  --Get selection --When getting slices inside selection, the range must be [scol+1..ecol].
            if sline = eline then --1 line of text
                txt = {iTxtLnText[idx][sline][scol+1..ecol]}
            elsif eline = sline + 1 then --2 lines of text
                txt = {iTxtLnText[idx][sline][scol+1..$]} & {iTxtLnText[idx][eline][1..ecol]}
            else --multiple lines of text
                txt = {iTxtLnText[idx][sline][scol+1..$]} & iTxtLnText[idx][sline+1..eline-1] & {iTxtLnText[idx][eline][1..ecol]}
            end if
        end if
    end if
    
    return txt
end function


--Command and event handlers

procedure call_cmd(atom idx, sequence cmd, object args)
--Process a command and call appropriate series of operations to modify the text lines

--move_cursor_to(idx, li, col)
--move_cursor_rel(idx, lis, cols)
--select_to(idx, li, col)
--select_rel(idx, lis, cols)
--delete_selection(idx)
--text_put(idx, chars)
--text_get(idx)

    atom issel, wh, li, col
    sequence txt, vislines

    switch cmd do
        case "move" then
            switch args[1] do
                case "to" then
                    move_cursor_to(idx, args[2], args[3])
                case "rel" then
                    move_cursor_rel(idx, args[2], args[3])
                case "left" then
                    move_cursor_rel(idx, 0, -args[2])
                case "right" then
                    move_cursor_rel(idx, 0, args[2])
                case "up" then
                    move_cursor_rel(idx, -args[2], 0)
                case "down" then
                    move_cursor_rel(idx, args[2], 0)
                case "pgup" then
                    vislines = visible_lines(idx)
                    move_cursor_rel(idx, -(vislines[2] - vislines[1]), 0)
                case "pgdown" then
                    vislines = visible_lines(idx)
                    move_cursor_rel(idx, (vislines[2] - vislines[1]), 0)
            end switch
            
        case "select" then
            switch args[1] do
                case "to" then
                    select_to(idx, args[2], args[3])
                case "rel" then
                    select_rel(idx, args[2], args[3])
                case "left" then
                    select_rel(idx, 0, -args[2])
                case "right" then
                    select_rel(idx, 0, args[2])
                case "up" then
                    select_rel(idx, -args[2], 0)
                case "down" then
                    select_rel(idx, args[2], 0)
                case "pgup" then
                    vislines = visible_lines(idx)
                    select_rel(idx, -(vislines[2] - vislines[1]), 0)
                case "pgdown" then
                    vislines = visible_lines(idx)
                    select_rel(idx, (vislines[2] - vislines[1]), 0)
                case "all" then
                    move_cursor_to(idx, 1, 0) 
                    select_to(idx, "$", "$")
                case "none" then
                    move_cursor_rel(idx, 0, 0)
            end switch
            
        case "char" then
            if is_selection(idx) then
                delete_selection(idx)
            end if
            txt = clean_text(args[1])
            text_put(idx, txt)
            set_modified(idx, 1)
            --vislines = visible_lines(idx)
            --draw_lines(idx, vislines[1], vislines[2])
            
        case "tab" then
            --todo: smart tabs
            if is_selection(idx) then
                --indent_selection(idx)
            else
                --text_put(idx, "\t")
                text_put(idx, IndentSpace)
            end if
            set_modified(idx, 1)
            --vislines = visible_lines(idx)
            --draw_lines(idx, vislines[1], vislines[2])
            
        case "backspace" then
            if is_selection(idx) then
                delete_selection(idx)
            else
                select_rel(idx, 0, -1)
                delete_selection(idx)
            end if
            set_modified(idx, 1)
            --vislines = visible_lines(idx)
            --draw_lines(idx, vislines[1], vislines[2])
            
        case "delete" then
            if is_selection(idx) then
                delete_selection(idx)
            else
                select_rel(idx, 0, 1)
                delete_selection(idx)
            end if
            set_modified(idx, 1)
            --vislines = visible_lines(idx)
            --draw_lines(idx, vislines[1], vislines[2])
            
        case "newline" then
            if is_selection(idx) then
                delete_selection(idx)
            end if
            text_put(idx, {"", ""})
            set_modified(idx, 1)
            --vislines = visible_lines(idx)
            --draw_lines(idx, vislines[1], vislines[2])
            
        case "scroll" then
            iScrollX[idx] = args[1]
            iScrollY[idx] = args[2]
            
            vislines = visible_lines(idx)
            draw_lines(idx, vislines[1], vislines[2])
                        
        case "cut" then
            if is_selection(idx) then
                txt = text_get(idx)
                wh = gui:widget_get_handle(iCanvasName[idx])
                gui:clipboard_write_txt(wh, txt)
                delete_selection(idx)
            end if
            set_modified(idx, 1)
            
        case "copy" then
            if is_selection(idx) then
                txt = text_get(idx)
                wh = gui:widget_get_handle(iCanvasName[idx])
                gui:clipboard_write_txt(wh, txt)
            end if
            
        case "paste" then
            if is_selection(idx) then
                delete_selection(idx)
            end if
            wh = gui:widget_get_handle(iCanvasName[idx])
            txt = clean_text(gui:clipboard_read_txt(wh))
            text_put(idx, txt)
            set_modified(idx, 1)
            
        case "undo" then
            
        case "redo" then
            
        case "clear" then
            
        case "get" then
            
        case "set" then
        
        case "resize" then
            rebuild_lines(idx, 1, length(iTxtLnText[idx]))
            --vislines = visible_lines(idx)
            --draw_lines(idx, vislines[1], vislines[2])
    end switch
end procedure


procedure textedit_event_handler(object evwidget, object evtype, object evdata)
-- Handle events from the text editor instance's associated canvas widget
    atom idx = find(evwidget, iCanvasName)
    if idx > 0 then
        switch evtype do
            case "resized" then
                call_cmd(idx, "resize", {})
                
            case "HardFocus" then
                if evdata[1] != iHardFocus[idx] then
                    iHardFocus[idx] = evdata[1]
                    sequence vislines = visible_lines(idx)
                    draw_lines(idx, vislines[1], vislines[2])
                end if
                
            case "handle" then  --evdata = {"HandleName", "EventType", data1, data2})
                if length(evdata[1]) = 0 then --background area
                    atom whnd = gui:widget_get_handle(iCanvasName[idx])
                    set_font(whnd, iSyntaxFont[idx], iSyntaxSize[idx], Normal)
                    object mpos = get_mouse_pos(idx, evdata[3], evdata[4])
                    if sequence(mpos) then --{mline, mcol, mtoken}
                        switch evdata[2] do
                            case "MouseMove" then
                                if iIsSelecting[idx] then
                                    call_cmd(idx, "select", {"to", mpos[1], mpos[2]})
                                end if
                                
                            case "LeftDown" then
                                if evdata[5] then --shift key
                                    call_cmd(idx, "select", {"to", mpos[1], mpos[2]})
                                else
                                    call_cmd(idx, "move", {"to", mpos[1], mpos[2]})
                                end if
                                iIsSelecting[idx] = 1
                                
                            case "LeftDoubleClick" then
                                --select word/token under mpos[1], mpos[2]
                                
                            case "LeftUp" then
                                if iIsSelecting[idx] then
                                    call_cmd(idx, "select", {"to", mpos[1], mpos[2]})
                                end if
                                iIsSelecting[idx] = 0
                                
                            case "RightDown" then
                                
                            case "RightUp" then
                                
                        end switch
                    end if
                    
                elsif equal(evdata[1], "lineheaders") then
                    --if equal(evdata[2], "MouseMove") then --evdata = {"handle", {hname, "MouseMove", mx, my}}
                    --    grect = graphs[grRect][gr[i]]
                    --    if gui:in_rect(evdata[3], evdata[4], grect) then --in_rect(atom xpos, atom ypos, sequence rect)
                    --    end if
                    --end if
                end if
                
            case "KeyDown" then
                --puts(1, "KeyDown:" & sprint(evdata) & "\n")
                if evdata[1] = 37 then --left
                    if evdata[2] then --shift
                        call_cmd(idx, "select", {"left", 1})
                    else
                        call_cmd(idx, "move", {"left", 1})
                    end if
                elsif evdata[1] = 39 then --right
                    if evdata[2] then --shift
                        call_cmd(idx, "select", {"right", 1})
                    else
                        call_cmd(idx, "move", {"right", 1})
                    end if
                elsif evdata[1] = 38 then --up
                    if evdata[2] then --shift
                        call_cmd(idx, "select", {"up", 1})
                    else
                        call_cmd(idx, "move", {"up", 1})
                    end if
                elsif evdata[1] = 40 then --down
                    if evdata[2] then --shift
                        call_cmd(idx, "select", {"down", 1})
                    else
                        call_cmd(idx, "move", {"down", 1})
                    end if
                elsif evdata[1] = 33 then --pgup
                    if evdata[2] then --shift
                        call_cmd(idx, "select", {"pgup", 1})
                    else
                        call_cmd(idx, "move", {"pgup", 1})
                    end if
                elsif evdata[1] = 34 then --pgdown
                    if evdata[2] then --shift
                        call_cmd(idx, "select", {"pgdown", 1})
                    else
                        call_cmd(idx, "move", {"pgdown", 1})
                    end if
                elsif evdata[1] = 36 then --home
                    if evdata[3] then --ctrl (beginning of file)
                        if evdata[2] then --shift
                            call_cmd(idx, "select", {"to", 1, 0})
                        else
                            call_cmd(idx, "move", {"to", 1, 0})
                        end if
                    else              --(beginning of line)
                        if evdata[2] then --shift
                            call_cmd(idx, "select", {"to", ".", 0})
                        else
                            call_cmd(idx, "move", {"to", ".", 0})
                        end if
                    end if
                elsif evdata[1] = 35 then --end
                    if evdata[3] then --ctrl (end of file)
                        if evdata[2] then --shift
                            call_cmd(idx, "select", {"to", "$", "$"})
                        else
                            call_cmd(idx, "move", {"to", "$", "$"})
                        end if
                    else              --(end of line)
                        if evdata[2] then --shift
                            call_cmd(idx, "select", {"to", ".", "$"})
                        else
                            call_cmd(idx, "move", {"to", ".", "$"})
                        end if
                    end if
                elsif evdata[1] = 8 and iLocked[idx] = 0 then --backspace
                    call_cmd(idx, "backspace", {})
                    
                elsif evdata[1] = 46 and iLocked[idx] = 0 then --delete
                    call_cmd(idx, "delete", {})
                    
                elsif evdata[1] = 112 then --F1
                elsif evdata[1] = 113 then --F2
                elsif evdata[1] = 114 then --F3
                elsif evdata[1] = 115 then --F4
                elsif evdata[1] = 116 then --F5
                elsif evdata[1] = 117 then --F6
                elsif evdata[1] = 118 then --F7
                elsif evdata[1] = 119 then --F8
                elsif evdata[1] = 120 then --F9
                elsif evdata[1] = 121 then --F10
                elsif evdata[1] = 122 then --F11
                elsif evdata[1] = 123 then --F12
                
                end if
                
            case "KeyUp" then
                --puts(1, "KeyUp:" & sprint(evdata) & "\n")
                
            case "KeyPress" then
                --puts(1, "KeyPress:" & sprint(evdata) & "\n")
                if evdata[2] = 0 and evdata[3] = 1 and evdata[4] = 0 then --ctrl
                --puts(1, "KeyPress: Ctrl+" & sprint(evdata[1] + 96) & "\n")
                    if evdata[1] + 96 = 'x' then --copy
                        call_cmd(idx, "cut", {})
                        
                    elsif evdata[1] + 96 = 'c' then --copy
                        call_cmd(idx, "copy", {})
                        
                    elsif evdata[1] + 96 = 'v' then --paste
                        call_cmd(idx, "paste", {})
                        
                    elsif evdata[1] + 96 = 'a' then --paste
                        call_cmd(idx, "select", {"all"})
                    end if
                    
                elsif evdata[2] = 1 and evdata[3] = 1 and evdata[4] = 0 then --shift+ctrl
                    
                else --no ctrl or alt
                    if evdata[1] = 13 and iLocked[idx] = 0 then --newline
                        call_cmd(idx, "newline", {})
                    elsif evdata[1] = 9 and iLocked[idx] = 0 then --tab
                        call_cmd(idx, "tab", {})
                    elsif evdata[1] > 13 and iLocked[idx] = 0 then --normal character
                        call_cmd(idx, "char", {evdata[1]})
                    end if
                end if
                
            --case "destroyed" then
                
            case "scroll" then
                --call_cmd(iName[idx], cmdScroll, {})
                call_cmd(idx, "scroll", {evdata[1], evdata[2]})
                
        end switch
    end if
end procedure


procedure send_txt_event(atom idx, sequence evtype, object evdata)
    --send an event to an external event handler
    if idx > 0 and iEventRid[idx] > 0 then
        call_proc(iEventRid[idx], {iName[idx], evtype, evdata}) 
    end if 
end procedure


--------------------------------------------------------------------------------

--Routines that are exported/public 

export procedure create(sequence wprops) --Create a text editor instance
    object nText    = "",
    nName           = "",
    nCanvasName     = "",
    nParentName     = "",
    nLabel          = "", 
    nEventRid       = 0,
    
    nSyntaxMode     = synPlain,
    nEditMode       = emNormal,
    nLineNumbers    = 1,
    nLocked         = 0,
    nWordWrap       = 1,
    
    nTokenStyles    = {     --each token type: {tsBackColor, tsTextColor, tsBold, tsItalic, tsUnderline}
        {thBackColor, rgb(0, 0, 0), 0, 0, 0},  --ttNone
        {thBackColor, rgb(0, 0, 0), 0, 0, 0},  --ttInvalid
        {thBackColor, rgb(0, 0, 0), 0, 0, 0},  --ttFound
        {thBackColor, rgb(0, 0, 0), 0, 0, 0},  --ttIdentifier
        {thBackColor, rgb(0, 0, 0), 0, 0, 0},  --ttKeyword
        {thBackColor, rgb(0, 0, 0), 0, 0, 0},  --ttBuiltin
        {thBackColor, rgb(0, 0, 0), 0, 0, 0},  --ttNumber
        {thBackColor, rgb(0, 0, 0), 0, 0, 0},  --ttSymbol
        {thBackColor, rgb(0, 0, 0), 0, 0, 0},  --ttBracket
        {thBackColor, rgb(0, 0, 0), 0, 0, 0},  --ttString
        {thBackColor, rgb(0, 0, 0), 0, 0, 0}   --ttComment
    },
    nSyntaxFont     = thMonoFonts[1],
    nSyntaxSize     = thMonoFontSize
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do         
                case "name" then
                    nName = wprops[p][2]
                    
                case "label" then
                    nLabel = wprops[p][2]
                    
                case "handler" then
                    nEventRid = wprops[p][2]
                        
                case "text" then
                    nText = wprops[p][2]
                    
                case "syntax_mode" then
                    if equal(text:lower(wprops[p][2]), "euphoria") then
                        nSyntaxMode = synEuphoria
                    elsif equal(text:lower(wprops[p][2]), "creole") then
                        nSyntaxMode = synCreole
                    elsif equal(text:lower(wprops[p][2]), "html") then
                        nSyntaxMode = synHTML
                    elsif equal(text:lower(wprops[p][2]), "css") then
                        nSyntaxMode = synCSS
                    elsif equal(text:lower(wprops[p][2]), "xml") then
                        nSyntaxMode = synXML
                    elsif equal(text:lower(wprops[p][2]), "ini") then
                        nSyntaxMode = synINI
                    elsif equal(text:lower(wprops[p][2]), "c") then
                        nSyntaxMode = synC
                    end if
                    
                case "edit_mode" then
                    if equal(text:lower(wprops[p][2]), "normal") then
                        nEditMode = emNormal
                    elsif equal(text:lower(wprops[p][2]), "block") then
                        nEditMode = emBlock
                    elsif equal(text:lower(wprops[p][2]), "table") then
                        nEditMode = emGrid 
                    end if
                    
                case "line_numbers" then
                    nLineNumbers = wprops[p][2]
                    
                case "locked" then
                    nLocked = wprops[p][2]
                    
                --case "word_wrap" then
                --    nWordWrap = wprops[p][2]
                    
                --case "token_styles" then
                --    nTokenStyles = wprops[p][2]
                    
                case "syntax_font" then
                    nSyntaxFont = wprops[p][2]
                    
                case "syntax_size" then
                    nSyntaxSize = wprops[p][2]
                    
            end switch
        end if
    end for
    
    iName               &= {nName}
    iCanvasName         &= {nCanvasName}
    iParentName         &= {nParentName}
    iLabel              &= {nLabel}
    iEventRid           &= {nEventRid}
    
    iSyntaxMode         &= {nSyntaxMode}
    iEditMode           &= {nEditMode}
    iLineNumbers        &= {nLineNumbers}
    iLocked             &= {nLocked}
    iModified           &= {0}
    iWordWrap           &= {nWordWrap}
    
    iTokenStyles        &= {nTokenStyles}
    iSyntaxFont         &= {nSyntaxFont}
    iSyntaxSize         &= {nSyntaxSize}
    
    iTxtLnText          &= {{""}}
    iTxtLnTokens        &= {{0}}
    iTxtLnSyntaxState   &= {{0}}
    iTxtLnBookmark      &= {{0}}
    iTxtLnFold          &= {{0}}
    iTxtLnVisible       &= {{1}}
    iTxtLnTag           &= {{0}}
    iTxtLnPosX          &= {{0}}
    iTxtLnPosY          &= {{0}}
    iTxtLnWidth         &= {{0}}
    iTxtLnHeight        &= {{0}}
    
    iHardFocus          &= {0}
    iCursorState        &= {0}
    iIsSelecting        &= {0}
    iSelStartLine       &= {1}
    iSelStartCol        &= {0}
    iSelEndLine         &= {1}
    iSelEndCol          &= {0}
    iVirtualColX        &= {0}
    iScrollX            &= {0}
    iScrollY            &= {0}
    
    iLineNumWidth       &= {0}
    iTotalHeight        &= {0}
    iTotalWidth         &= {0}
    
    iBusyStatus         &= {0}
    iBusyTime           &= {0}
    iCmdQueue           &= {{}}
    iUndoQueue          &= {{}}
    
    syncolor:set_colors({
        {"NORMAL", ttNone},
        {"COMMENT", ttComment},
        {"KEYWORD", ttKeyword},
        {"BUILTIN", ttBuiltin},
        {"STRING", ttString},
        {"BRACKET", {ttBracket, -1, -2, -3, -4, -5, -6, -7, -8, -9, -10}}
    })
    
    if length(nText) > 0 then
        atom idx = length(iName)
        --text_put(idx, nText)
        call_cmd(idx, "char", {nText})
        call_cmd(idx, "move", {"to", 1, 0})
        set_modified(idx, 0)
    end if
end procedure


export procedure destroy(sequence iname) --Destroy a text editor instance (after hiding it if currently shown)
    atom idx = find(iname, iName)
    if idx > 0 then
        --gui:wdestroy(iName[idx])
        hide(iname)
        
        iName[idx]              = remove(iName, idx)
        iCanvasName[idx]        = remove(iCanvasName, idx)
        iParentName[idx]        = remove(iParentName, idx)
        iLabel[idx]             = remove(iLabel, idx)
        iEventRid[idx]          = remove(iEventRid, idx)
        
        iSyntaxMode[idx]        = remove(iSyntaxMode, idx)
        iEditMode[idx]          = remove(iEditMode, idx)
        iLineNumbers[idx]       = remove(iLineNumbers, idx)
        iLocked[idx]            = remove(iLocked, idx)
        iModified[idx]          = remove(iModified, idx)
        iWordWrap[idx]          = remove(iWordWrap, idx)
        
        iTokenStyles[idx]       = remove(iTokenStyles, idx)
        iSyntaxFont[idx]        = remove(iSyntaxFont, idx)
        iSyntaxSize[idx]        = remove(iSyntaxSize, idx)
        
        iTxtLnText[idx]         = remove(iTxtLnText, idx)
        iTxtLnTokens[idx]       = remove(iTxtLnTokens, idx)
        iTxtLnSyntaxState[idx]  = remove(iTxtLnSyntaxState, idx)
        iTxtLnBookmark[idx]     = remove(iTxtLnBookmark, idx)
        iTxtLnFold[idx]         = remove(iTxtLnFold, idx)
        iTxtLnVisible[idx]      = remove(iTxtLnVisible, idx)
        iTxtLnTag[idx]          = remove(iTxtLnTag, idx)
        iTxtLnPosX[idx]         = remove(iTxtLnPosX, idx)
        iTxtLnPosY[idx]         = remove(iTxtLnPosY, idx)
        iTxtLnWidth[idx]        = remove(iTxtLnWidth, idx)
        iTxtLnHeight[idx]       = remove(iTxtLnHeight, idx)
        
        iHardFocus[idx]         = remove(iHardFocus, idx)
        iCursorState[idx]       = remove(iCursorState, idx)
        iIsSelecting[idx]       = remove(iIsSelecting, idx)
        iSelStartLine[idx]      = remove(iSelStartLine, idx)
        iSelStartCol[idx]       = remove(iSelStartCol, idx)
        iSelEndLine[idx]        = remove(iSelEndLine, idx)
        iSelEndCol[idx]         = remove(iSelEndCol, idx)
        iVirtualColX[idx]       = remove(iVirtualColX, idx)
        iScrollX[idx]           = remove(iScrollX, idx)
        iScrollY[idx]           = remove(iScrollY, idx)
        
        iLineNumWidth[idx]      = remove(iLineNumWidth, idx)
        iTotalHeight[idx]       = remove(iTotalHeight, idx)
        iTotalWidth[idx]        = remove(iTotalWidth, idx)
        
        iBusyStatus[idx]        = remove(iBusyStatus, idx)
        iBusyTime[idx]          = remove(iBusyTime, idx)
        iCmdQueue[idx]          = remove(iCmdQueue, idx)
        iUndoQueue[idx]         = remove(iUndoQueue, idx)
    end if                      
end procedure


export procedure show(sequence iname, sequence cname, sequence cparent) --Show a text editor instance in specified canvas widget
    atom idx = find(iname, iName)
    if idx > 0 then
        if gui:wexists(iname) then
            gui:wdestroy(iname)
        end if
        
        atom inuse = find(cname, iCanvasName) --if a text editor is already using this canvas, then unlink it
        if inuse > 0 then
            iCanvasName[inuse] = ""
            iParentName[inuse] = ""
        end if
        iCanvasName[idx] = cname
        iParentName[idx] = cparent
        
        gui:wcreate({
            {"name", cname},
            {"parent", cparent},
            {"class", "canvas"},
            {"label", iLabel[idx]},
            {"scroll_foreground", 0},
            {"background_pointer", "Ibeam"},
            {"handler", routine_id("textedit_event_handler")}
        })
        
        gui:wproc(iCanvasName[idx], "set_background_pointer", {"Busy"})
        
        call_cmd(idx, "resize", {})
    end if
end procedure


export procedure hide(sequence iname) --Hide a text editor instance (and recreate empty canvas widget)
    atom idx = find(iname, iName)
    if idx > 0 then
        if gui:wexists(iname) then
            gui:wdestroy(iname)
            gui:wcreate({
                {"name", iCanvasName[idx]},
                {"parent", iParentName[idx]},
                {"class", "canvas"},
                --{"label", ""},
                --{"background_pointer", "Ibeam"},
                {"handler", routine_id("textedit_event_handler")}
            })
        end if
        
        iCanvasName[idx] = ""
        iParentName[idx] = ""
    end if
end procedure


export procedure docmd(sequence iname, sequence cmd, object args)
    atom idx = find(iname, iName)
    if idx > 0 then
        call_cmd(idx, cmd, args)
    end if
end procedure


export function is_modified(sequence iname)
    atom idx = find(iname, iName)
    atom ismodified = 0
    if idx > 0 then
        ismodified = iModified[idx]
    end if
    return ismodified
end function


export procedure set_modified(object inameoridx, atom ismodified)
    atom idx
    if atom(inameoridx) then
        idx = inameoridx
    else
        idx = find(inameoridx, iName)
    end if
    if idx > 0 and iLocked[idx] = 0 and iModified[idx] != ismodified then
        iModified[idx] = ismodified
        send_txt_event(idx, "modified", ismodified)
    end if
end procedure


export function get_prop(object inameoridx, sequence opt, object val)
    atom idx
    object ret = -1
    if atom(inameoridx) then
        idx = inameoridx
    else
        idx = find(inameoridx, iName)
    end if
    if idx > 0 then
        switch opt do
            case "syntax_mode" then
                if iSyntaxMode[idx] = synEuphoria then
                    ret = "euphoria"
                elsif iSyntaxMode[idx] = synCreole then
                    ret = "creole"
                elsif iSyntaxMode[idx] = synHTML then
                    ret = "html"
                elsif iSyntaxMode[idx] = synCSS then
                    ret = "css"
                elsif iSyntaxMode[idx] = synXML then
                    ret = "xml"
                elsif iSyntaxMode[idx] = synINI then
                    ret = "ini"
                elsif iSyntaxMode[idx] = synC then
                    ret = "c"
                else
                    ret = "plain"
                end if
                
            /*case "edit_mode" then
                if iEditMode[idx] = emNormal
                    ret = "normal"
                elsif iEditMode[idx] = emBlock
                    ret = "block"
                elsif iEditMode[idx] = emGrid
                    ret = "table"
                end if*/
                
            --case "line_numbers" then
            --    ret = iLineNumbers[idx]
                
            case "locked" then
                ret = iLocked[idx]
                
            --case "word_wrap" then
            --    ret = iWordWrap[idx]
                
            --case "token_styles" then
            --    ret = nTokenStyles
                
            case "syntax_font" then
                ret = iSyntaxFont[idx]
                
            case "syntax_size" then
                ret = iSyntaxSize[idx]
        
        end switch
    end if
    
    return ret
end function


export procedure set_prop(object inameoridx, sequence opt, object val)
    atom idx
    if atom(inameoridx) then
        idx = inameoridx
    else
        idx = find(inameoridx, iName)
    end if
    if idx > 0 then
        switch opt do
            case "syntax_mode" then
                if equal(text:lower(val), "euphoria") then
                    iSyntaxMode[idx] = synEuphoria
                elsif equal(text:lower(val), "creole") then
                    iSyntaxMode[idx] = synCreole
                elsif equal(text:lower(val), "html") then
                    iSyntaxMode[idx] = synHTML
                elsif equal(text:lower(val), "css") then
                    iSyntaxMode[idx] = synCSS
                elsif equal(text:lower(val), "xml") then
                    iSyntaxMode[idx] = synXML
                elsif equal(text:lower(val), "ini") then
                    iSyntaxMode[idx] = synINI
                elsif equal(text:lower(val), "c") then
                    iSyntaxMode[idx] = synC
                else
                    iSyntaxMode[idx] = synPlain
                end if
                
            /*case "edit_mode" then
                if equal(text:lower(val), "normal") then
                    iEditMode[idx] = emNormal
                elsif equal(text:lower(val), "block") then
                    iEditMode[idx] = emBlock
                elsif equal(text:lower(val), "table") then
                    iEditMode[idx] = emGrid 
                end if*/
                
            --case "line_numbers" then
            --    iLineNumbers[idx] = val
                
            case "locked" then
                iLocked[idx] = val
                
            --case "word_wrap" then
            --    iWordWrap[idx] = val
                
            --case "token_styles" then
            --    nTokenStyles = val
                
            case "syntax_font" then
                iSyntaxFont[idx] = val
                
            case "syntax_size" then
                iSyntaxSize[idx] = val
                
            case "label" then
                gui:wproc(iCanvasName[idx], "set_label", {val})
                
        end switch
    end if
end procedure


export function save_to_file(sequence iname, sequence filename)
    atom idx = find(iname, iName)
    atom success = 0
    if idx > 0 then
        --write to specified file
        atom fn = open(filename, "w")
        if fn = -1 then
            success = 0
        else
            for t = 1 to length(iTxtLnText[idx]) do
                puts(fn, iTxtLnText[idx][t] & "\n")
            end for
            close(fn)
            success = 1
        end if
    end if
    return success
end function

