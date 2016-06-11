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


/*
Textbox modes:

Number : numerical value
    wcpOptMode              "number"
    wcpOptModeOptions       {"min_value", "max_value"}
    wcpOptDataFormat        number format
    wcpOptControlVisible    "show_control" : +- buttons to adjust value
    
Text : multiple lines of text
    wcpOptMode              "text"
    wcpOptModeOptions       {"wordwrap", "visible_lines"}
    wcpOptDataFormat        string format
    wcpOptControlVisible    "spell_check"  : indicates misspelled words "Check Spelling..." appears in right-click menu
    
String : string of text that can be formatted or restricted to a maximum length
    wcpOptMode              "string"
    wcpOptModeOptions       {list of auto-complete items}
    wcpOptDataFormat        string format
    wcpOptControlVisible    "show_control" : "..." button to display custom window for editing data
    
Item : string selected from a list
    wcpOptMode              "item"
    wcpOptModeOptions       {list of items}
    wcpOptDataFormat        "restrict_to_list"
    wcpOptControlVisible    "show_control" : Dropdown button to show popup list
    
Datetime : string representing a date/time
    wcpOptMode              "datetime"
    wcpOptModeOptions       precision" : the smallest unit allowed to be adjusted {"year", "month", "day", "minute", "second"}
    wcpOptDataFormat        date/time format
    wcpOptControlVisible    "show_control" : Button to display popup Calendar/clock
    
Password : masked string of text for entering a password
    wcpOptMode              "password"
    wcpOptModeOptions       mask character
    wcpOptDataFormat        password character requirements
    wcpOptControlVisible    "show_control" : Button to display password generator
*/  


public include redylib_0_9/gui/widgets.e as widget
public include redylib_0_9/oswin.e as oswin
public include redylib_0_9/gui/themes.e as th

include std/sequence.e
include std/math.e
include std/pretty.e
include std/search.e
include std/text.e

-- Internal class variables and routines

sequence wcprops

enum
wcpID,
wcpSoftFocus,
wcpKeyFocus,
wcpAutoFocus,
wcpIsSelecting,
wcpLabel,
wcpLabelPosition,
wcpHover,
wcpCursorState,
wcpKeyShift,             --Shift key (16) is pressed
wcpKeyCtrl,              --Ctrl key (17) is pressed
wcpKeyAlt,               --Alt key (18) is pressed

wcpMenuID,      
wcpSpecialRect,
wcpSpecialHover,
wcpSpecialPressed,
wcpSpecialWidgetID,
wcpSpecialMaxSize,

wcpOptMode,         --{"number", "text", "string", "item", "datetime", "password"}
wcpOptModeOptions,
wcpOptDataFormat,
wcpOptControlVisible,
wcpOptSameWidth,
wcpOptHighlightLine,
wcpOptLocked,
wcpOptAllowNewline, --allow newline character to be inserted when pressing Enter in "text" mode

wcpLineHeight,
wcpLabelPos,
wcpEditRect,
wcpVisibleSize,     --size of visible area
wcpContentSize,     --size of actual content
wcpScrollPosX,
wcpScrollPosY,
wcpScrollV,         --vertial scrollbar widgetid
wcpScrollH,         --horizontal scrollbar widgetid

wcpSelStartLine,
wcpSelStartCol,
wcpSelEndLine,
wcpSelEndCol,

wcpSelStartX,
wcpSelEndX,

wcpText,            --raw text
wcpTextLinesLine,   --Line index of corresponding text
wcpTextLinesCol,    --Column index of corresponding text
wcpTextLinesLength, --length of each line of text
wcpTextLinesWidth   --width of each line of text


constant wcpLENGTH = wcpTextLinesWidth

wcprops = repeat({}, wcpLENGTH)


-- Theme variables -------------------------------

atom headingheight = 16, thCurrLineBkColor = rgb(255, 255, 200)
constant
thMonoFonts = {"Consolas", "Courier New", "Lucida Console", "Liberation Mono", "DejaVu Sans Mono"},
thNormalFont = "Arial",
thSpButtonWidth = 20

sequence
thMonoFont = "DejaVu Sans Mono",
FontList = {}

procedure set_default_monofont(atom hWnd, sequence monofonts)
--set default monofont to the first matching font in list of preferred fonts
    if length(FontList) = 0 then
        FontList = EnumFonts(hWnd) -- returns a list of { {"font name", {"style 1", "style 2", ... }}, ... }
    end if
    
    thMonoFont = thMonoFonts[1]
    
    for mf = 1 to length(monofonts) do
        for f = 1 to length(FontList) do
            if match(monofonts[mf], FontList[f][1]) then
                thMonoFont = FontList[f][1]
                return
            end if
        end for
    end for
end procedure

-- local routines ---------------------------------------------------------------------------

function rawtext(atom idx, atom cLine, atom sst, atom slen) --gets part of a line of text 
    atom 
    l = wcprops[wcpTextLinesLine][idx][cLine],
    s = wcprops[wcpTextLinesCol][idx][cLine] + sst,
    e = wcprops[wcpTextLinesCol][idx][cLine] + slen
    
    --temporary out-of-bounds protection (the root of the problems seems to be in wordwrap)
    /*if s > length(wcprops[wcpText][idx][l]) then
        s = length(wcprops[wcpText][idx][l])
    end if
    if e > length(wcprops[wcpText][idx][l]) then
        e = length(wcprops[wcpText][idx][l])
    end if
    if s < 1 then
        s = 1
    end if
    if e < s - 1 then
        e = s - 1
    end if*/
    
    return wcprops[wcpText][idx][l][s..e]
end function


function wordwrap(atom idx, atom wh, atom li)
 --returns sequences of {{ncol1, nlen1}, {ncol2, nlen2}, {ncol3, nlen3},...}
    --if srl > 0 then wordwrap starting at line srl column src and continue to end of line
    --if srl = 0 then wordwrap starting at line srl column 1 and continue to end of last line
    
    if equal(wcprops[wcpVisibleSize][idx], {0, 0}) then --size has not been set yet
        return {wcprops[wcpText][idx][li]}
    end if
    
    sequence txt, src, words = {}, wtxt = {""}, txex, tsize = {64, 64}, tfont
    atom st, spx, spy, tx = 0, ty = 0, twidth, wcount
    
    txt = wcprops[wcpText][idx][li]
    twidth = wcprops[wcpVisibleSize][idx][1] - 32
    
    if wcprops[wcpOptSameWidth][idx] then
        oswin:set_font(wh, thMonoFont, 9, Normal)
    else
        oswin:set_font(wh, thNormalFont, 9, Normal)
    end if
    
    src = match_replace("\n", txt, " ")
    src = match_replace("\r", src, " ")
    src = match_replace("\t", src, " ")
    src = split_any(src, " ")
    
    txex = get_text_extent(wh, " ")
    spx = txex[1]
    spy = txex[2]
    wcount = length(src)
    for w = 1 to wcount do
        st = 1
        txex = get_text_extent(wh, src[w])
        if txex[1] > twidth then --todo: fix character wrapping of words that are too long
            /*for e = st to length(src[w]) do
                txex = get_text_extent(wh, src[w][st..e])
                if txex[1] > twidth then
                    words &= {src[w][st..e-1]}
                    st = e
                    exit
                end if
            end for
            words &= {src[w][st..$]}
            */
            if w < wcount then
                words &= {src[w] & " "}
            else
                words &= {src[w]}
            end if
            
        else
            if w < wcount then
                words &= {src[w] & " "}
            else
                words &= {src[w]}
            end if
        end if
    end for
    for w = 1 to length(words) do
        txex = get_text_extent(wh, words[w])
        tx += txex[1] --+ spx
        if tx > twidth then
            tx = txex[1]
            if w > 1 then
                ty += spy
            end if
            wtxt &= {""}
        end if
        wtxt[$] &= words[w] --& " "
        if tx > tsize[1] then
            tsize[1] = tx
        end if
        if ty + spy > tsize[2] then
            tsize[2] = ty + spy
        end if
    end for
    if tsize[1] > twidth then
        tsize[1] = twidth
    end if
    --if tsize[2] > 600 then
    --    tsize[2] = ScreenY - 600
    --end if
    --pretty_print(1, words, {2})
    --pretty_print(1, wtxt, {2})
    
    return wtxt
end function


function get_selected_text(atom idx, atom wh)
    sequence txt = {}
    atom sStartLine, sStartCol, sEndLine, sEndCol, rStartLine, rStartCol, rEndLine, rEndCol
    
    if wcprops[wcpSelStartLine][idx] > wcprops[wcpSelEndLine][idx] then
        sStartLine = wcprops[wcpSelEndLine][idx]
        sStartCol = wcprops[wcpSelEndCol][idx]
        sEndLine = wcprops[wcpSelStartLine][idx]
        sEndCol = wcprops[wcpSelStartCol][idx]
    elsif wcprops[wcpSelStartLine][idx] = wcprops[wcpSelEndLine][idx] and wcprops[wcpSelStartCol][idx] > wcprops[wcpSelEndCol][idx] then
        sStartLine = wcprops[wcpSelStartLine][idx]
        sStartCol = wcprops[wcpSelEndCol][idx]
        sEndLine = wcprops[wcpSelEndLine][idx]
        sEndCol = wcprops[wcpSelStartCol][idx]
    else
        sStartLine = wcprops[wcpSelStartLine][idx]
        sStartCol = wcprops[wcpSelStartCol][idx]
        sEndLine = wcprops[wcpSelEndLine][idx]
        sEndCol = wcprops[wcpSelEndCol][idx]
    end if
    rStartLine = wcprops[wcpTextLinesLine][idx][sStartLine]
    rStartCol = wcprops[wcpTextLinesCol][idx][sStartLine] + sStartCol
    rEndLine = wcprops[wcpTextLinesLine][idx][sEndLine]
    rEndCol = wcprops[wcpTextLinesCol][idx][sEndLine] + sEndCol
    
    if rStartLine = rEndLine and rStartCol = rEndCol then --nothing is selected
    else  --Get selection
        if rStartLine = rEndLine then
            txt = wcprops[wcpText][idx][rStartLine][rStartCol+1..rEndCol]
        else
            for li = rStartLine to rEndLine do
                if li = rStartLine then
                    txt &= wcprops[wcpText][idx][li][rStartCol+1..$] & {13, 10}
                elsif li = sEndLine then
                    txt &= wcprops[wcpText][idx][li][1..rEndCol]
                else
                    txt &= wcprops[wcpText][idx][li] & {13, 10}
                end if
            end for
        end if
    end if
    
    --puts(1, "'" & txt & "'")
    return txt
    
    return {}
end function


procedure rebuild_text_lines(atom idx, atom wh)
    sequence txt, nline = {}, ncol = {}, nlen = {}, nwidth = {}
    atom llen, ccol
    
    --Build new text lines
    wcprops[wcpTextLinesLine][idx] = {}
    wcprops[wcpTextLinesCol][idx] = {}
    wcprops[wcpTextLinesLength][idx] = {}
    wcprops[wcpTextLinesWidth][idx] = {} 
    
    
    
    if equal(wcprops[wcpOptMode][idx], "text") and wcprops[wcpOptModeOptions][idx][1] = 1 then --wordwrap enabled
        --for li = rStartLine to length(wcprops[wcpText][idx]) do  --sEndLine do
        for li = 1 to length(wcprops[wcpText][idx]) do
            --wordwrap
            txt = wordwrap(idx, wh, li) --returns sequences of {{ncol1, nlen1}, {ncol2, nlen2}, {ncol3, nlen3},...}
            ccol = 0
            for wwl = 1 to length(txt) do
                --puts(1, ">" & txt[wwl] & "<\n")
                llen = length(txt[wwl])
                
                nline &= {li}
                ncol &= {ccol}
                nlen &= {llen}
                nwidth &= {0}
                
                --? {li, ccol, llen}
                
                ccol += llen
                
            end for
            --? {nline, ncol, nlen, nwidth}
        end for
    else --wordwrap disabled
        --for li = rStartLine to length(wcprops[wcpText][idx]) do  --sEndLine do
        for li = 1 to length(wcprops[wcpText][idx]) do  --sEndLine do
            nline &= {li}
            ncol &= {0}
            nlen &= {length(wcprops[wcpText][idx][li])}
            nwidth &= {0}
        end for
    end if
    
    --? {nline, ncol, nlen, nwidth}
    --Update text lines
    wcprops[wcpTextLinesLine][idx]   = nline   --wcprops[wcpTextLinesLine][idx][1..rStartLine-1] & nline & aline
    wcprops[wcpTextLinesCol][idx]    = ncol    --wcprops[wcpTextLinesCol][idx][1..rStartLine-1] & ncol & acol
    wcprops[wcpTextLinesLength][idx] = nlen    --wcprops[wcpTextLinesLength][idx][1..rStartLine-1] & nlen & alen 
    wcprops[wcpTextLinesWidth][idx]  = nwidth  --wcprops[wcpTextLinesWidth][idx][1..rStartLine-1] & nwidth & awidth 
    
    if wcprops[wcpSelStartLine][idx] > length(wcprops[wcpTextLinesLength][idx]) then
        wcprops[wcpSelStartLine][idx] = length(wcprops[wcpTextLinesLength][idx])
    end if
    if wcprops[wcpSelStartCol][idx] > wcprops[wcpTextLinesLength][idx][wcprops[wcpSelStartLine][idx]] then
        wcprops[wcpSelStartCol][idx] = wcprops[wcpTextLinesLength][idx][wcprops[wcpSelStartLine][idx]]
    end if
    
    if wcprops[wcpSelEndLine][idx] > length(wcprops[wcpTextLinesLength][idx]) then
        wcprops[wcpSelEndLine][idx] = length(wcprops[wcpTextLinesLength][idx])
    end if
    if wcprops[wcpSelEndCol][idx] > wcprops[wcpTextLinesLength][idx][wcprops[wcpSelEndLine][idx]] then
        wcprops[wcpSelEndCol][idx] = wcprops[wcpTextLinesLength][idx][wcprops[wcpSelEndLine][idx]]
    end if
end procedure


procedure delete_selection(atom idx, atom wh, atom dobackspace=0)
    sequence txt, nline = {}, ncol = {}, nlen = {}, nwidth = {}, aline = {}, acol = {}, alen = {}, awidth = {}
    atom sStartLine, sStartCol, sEndLine, sEndCol, rStartLine, rStartCol, rEndLine, rEndCol, nl, nc, llen, ccol
    
    if wcprops[wcpSelStartLine][idx] > wcprops[wcpSelEndLine][idx] then
        sStartLine = wcprops[wcpSelEndLine][idx]
        sStartCol = wcprops[wcpSelEndCol][idx]
        sEndLine = wcprops[wcpSelStartLine][idx]
        sEndCol = wcprops[wcpSelStartCol][idx]
    elsif wcprops[wcpSelStartLine][idx] = wcprops[wcpSelEndLine][idx] and wcprops[wcpSelStartCol][idx] > wcprops[wcpSelEndCol][idx] then
        sStartLine = wcprops[wcpSelStartLine][idx]
        sStartCol = wcprops[wcpSelEndCol][idx]
        sEndLine = wcprops[wcpSelEndLine][idx]
        sEndCol = wcprops[wcpSelStartCol][idx]
    else
        sStartLine = wcprops[wcpSelStartLine][idx]
        sStartCol = wcprops[wcpSelStartCol][idx]
        sEndLine = wcprops[wcpSelEndLine][idx]
        sEndCol = wcprops[wcpSelEndCol][idx]
    end if
    rStartLine = wcprops[wcpTextLinesLine][idx][sStartLine]
    rStartCol = wcprops[wcpTextLinesCol][idx][sStartLine] + sStartCol
    rEndLine = wcprops[wcpTextLinesLine][idx][sEndLine]
    rEndCol = wcprops[wcpTextLinesCol][idx][sEndLine] + sEndCol
    
    if dobackspace then
        if rStartLine = rEndLine and rStartCol = rEndCol then --if nothing is selected, then backspace (delete character to the left of cursor)
            if rStartCol = 0 then --beginning of line, so shift text up
                if rStartLine > 1 then
                    txt = wcprops[wcpText][idx][rStartLine]
                    move_cursor(idx, wh, 0, -1)
                    move_cursor(idx, wh, 2, 0)
                    wcprops[wcpText][idx] = remove(wcprops[wcpText][idx], rStartLine)
                    wcprops[wcpText][idx][rStartLine-1] &= txt
                end if
            else --middle of line, so shift text right
                wcprops[wcpText][idx][rStartLine] = wcprops[wcpText][idx][rStartLine][1..rStartCol-1] & wcprops[wcpText][idx][rStartLine][rStartCol+1..$]
                move_cursor(idx, wh, -1, 0)
            end if
        else --delete selection
            if sStartLine = sEndLine then
                wcprops[wcpText][idx][rStartLine] = wcprops[wcpText][idx][rStartLine][1..rStartCol] & wcprops[wcpText][idx][rStartLine][rEndCol+1..$]
                move_cursor(idx, wh, 0, 0)
            else
                txt = wcprops[wcpText][idx][rStartLine][1..rStartCol] & wcprops[wcpText][idx][rEndLine][rEndCol+1..$]
                wcprops[wcpText][idx] = remove(wcprops[wcpText][idx], rStartLine+1, rEndLine)
                wcprops[wcpText][idx][rStartLine] = txt
            end if
            move_cursor(idx, wh, 0, 0)
        end if
    else
        if rStartLine = rEndLine and rStartCol = rEndCol then --nothing is selected, so delete character to the right of cursor
            if rStartCol >= length(wcprops[wcpText][idx][rStartLine]) then --end of line, so shift text up
                if sStartLine < length(wcprops[wcpText][idx]) then
                    txt = wcprops[wcpText][idx][rStartLine+1]
                    wcprops[wcpText][idx] = remove(wcprops[wcpText][idx], rStartLine+1)
                    wcprops[wcpText][idx][rStartLine] &= txt
                    move_cursor(idx, wh, 0, 0)
                end if
            else --middle of line, so shift text right
                wcprops[wcpText][idx][rStartLine] = wcprops[wcpText][idx][rStartLine][1..rStartCol] & wcprops[wcpText][idx][rStartLine][rStartCol+2..$]
                move_cursor(idx, wh, 0, 0)
            end if
        else
            --delete selection:
            if rStartLine = rEndLine then
                wcprops[wcpText][idx][rStartLine] = wcprops[wcpText][idx][rStartLine][1..rStartCol] & wcprops[wcpText][idx][rStartLine][rEndCol+1..$]
            else
                txt = wcprops[wcpText][idx][rStartLine][1..rStartCol] & wcprops[wcpText][idx][rEndLine][rEndCol+1..$]
                wcprops[wcpText][idx] = remove(wcprops[wcpText][idx], rStartLine+1, rEndLine)
                wcprops[wcpText][idx][rStartLine] = txt
            end if
            move_cursor(idx, wh, 0, 0)
        end if
    end if
    --nc = wcprops[wcpSelEndCol][idx]
    
    if wcprops[wcpSelStartLine][idx] > wcprops[wcpSelEndLine][idx] then
        sStartLine = wcprops[wcpSelEndLine][idx]
        sStartCol = wcprops[wcpSelEndCol][idx]
        sEndLine = wcprops[wcpSelStartLine][idx]
        sEndCol = wcprops[wcpSelStartCol][idx]
    elsif wcprops[wcpSelStartLine][idx] = wcprops[wcpSelEndLine][idx] and wcprops[wcpSelStartCol][idx] > wcprops[wcpSelEndCol][idx] then
        sStartLine = wcprops[wcpSelStartLine][idx]
        sStartCol = wcprops[wcpSelEndCol][idx]
        sEndLine = wcprops[wcpSelEndLine][idx]
        sEndCol = wcprops[wcpSelStartCol][idx]
    else
        sStartLine = wcprops[wcpSelStartLine][idx]
        sStartCol = wcprops[wcpSelStartCol][idx]
        sEndLine = wcprops[wcpSelEndLine][idx]
        sEndCol = wcprops[wcpSelEndCol][idx]
    end if
    rStartLine = wcprops[wcpTextLinesLine][idx][sStartLine]
    rStartCol = wcprops[wcpTextLinesCol][idx][sStartLine] + sStartCol
    rEndLine = wcprops[wcpTextLinesLine][idx][sEndLine]
    rEndCol = wcprops[wcpTextLinesCol][idx][sEndLine] + sEndCol
    
    --If called from wc_create() then don't build text lines (will be done later during arrange)
    --if equal(wcprops[wcpVisibleSize][idx], {0, 0}) then
    --    return
    --end if
    
    rebuild_text_lines(idx, wh)
    move_cursor(idx, wh, 0, 0)
end procedure


procedure insert_txt(atom idx, atom wh, sequence newtxt)
    --Insert text at cursor position, then move cursor to end of new text
    --move_cursor(atom idx, atom wh, atom relcol, atom relline)
    sequence txt, aline = {}, acol = {}, alen = {}, awidth = {}
    atom sStartLine, sStartCol, sEndLine, sEndCol, rStartLine, rStartCol, rEndLine, rEndCol, nl, nc
    
    if length(newtxt) > 0 then
        if wcprops[wcpSelStartLine][idx] > wcprops[wcpSelEndLine][idx] then
            sStartLine = wcprops[wcpSelEndLine][idx]
            sStartCol = wcprops[wcpSelEndCol][idx]
            sEndLine = wcprops[wcpSelStartLine][idx]
            sEndCol = wcprops[wcpSelStartCol][idx]
        elsif wcprops[wcpSelStartLine][idx] = wcprops[wcpSelEndLine][idx] and wcprops[wcpSelStartCol][idx] > wcprops[wcpSelEndCol][idx] then
            sStartLine = wcprops[wcpSelStartLine][idx]
            sStartCol = wcprops[wcpSelEndCol][idx]
            sEndLine = wcprops[wcpSelEndLine][idx]
            sEndCol = wcprops[wcpSelStartCol][idx]
        else
            sStartLine = wcprops[wcpSelStartLine][idx]
            sStartCol = wcprops[wcpSelStartCol][idx]
            sEndLine = wcprops[wcpSelEndLine][idx]
            sEndCol = wcprops[wcpSelEndCol][idx]
        end if
        rStartLine = wcprops[wcpTextLinesLine][idx][sStartLine]
        rStartCol = wcprops[wcpTextLinesCol][idx][sStartLine] + sStartCol
        rEndLine = wcprops[wcpTextLinesLine][idx][sEndLine]
        rEndCol = wcprops[wcpTextLinesCol][idx][sEndLine] + sEndCol
        
        if rStartLine = rEndLine and rStartCol = rEndCol then --nothing is selected, so just insert text
        else
            --delete selection:
            if rStartLine = rEndLine then
                wcprops[wcpText][idx][rStartLine] = wcprops[wcpText][idx][rStartLine][1..rStartCol] & wcprops[wcpText][idx][rStartLine][rEndCol+1..$]
            else
                txt = wcprops[wcpText][idx][rStartLine][1..rStartCol] & wcprops[wcpText][idx][rEndLine][rEndCol+1..$]
                wcprops[wcpText][idx] = remove(wcprops[wcpText][idx], rStartLine+1, rEndLine)
                wcprops[wcpText][idx][rStartLine] = txt
            end if
            move_cursor(idx, wh, 0, 0)
        end if
        --nc = wcprops[wcpSelEndCol][idx]
        
        if wcprops[wcpSelStartLine][idx] > wcprops[wcpSelEndLine][idx] then
            sStartLine = wcprops[wcpSelEndLine][idx]
            sStartCol = wcprops[wcpSelEndCol][idx]
            sEndLine = wcprops[wcpSelStartLine][idx]
            sEndCol = wcprops[wcpSelStartCol][idx]
        elsif wcprops[wcpSelStartLine][idx] = wcprops[wcpSelEndLine][idx] and wcprops[wcpSelStartCol][idx] > wcprops[wcpSelEndCol][idx] then
            sStartLine = wcprops[wcpSelStartLine][idx]
            sStartCol = wcprops[wcpSelEndCol][idx]
            sEndLine = wcprops[wcpSelEndLine][idx]
            sEndCol = wcprops[wcpSelStartCol][idx]
        else
            sStartLine = wcprops[wcpSelStartLine][idx]
            sStartCol = wcprops[wcpSelStartCol][idx]
            sEndLine = wcprops[wcpSelEndLine][idx]
            sEndCol = wcprops[wcpSelEndCol][idx]
        end if
        rStartLine = wcprops[wcpTextLinesLine][idx][sStartLine]
        rStartCol = wcprops[wcpTextLinesCol][idx][sStartLine] + sStartCol
        rEndLine = wcprops[wcpTextLinesLine][idx][sEndLine]
        rEndCol = wcprops[wcpTextLinesCol][idx][sEndLine] + sEndCol
        
        --insert new text
        if length(newtxt) > 0 then
            if atom(newtxt[1]) then --if this is an atom, it means that this is raw text, not a sequence of lines of text)
                txt = remove_all(13, newtxt)
                txt = split(txt, 10)
            else
                txt = newtxt
            end if
            --txt = remove_all(13, newtxt)
            --todo: add more filters to remove invalid characters
            
            if length(txt) > 0 then
                --? {rStartLine, rStartCol, length(wcprops[wcpText][idx][rStartLine])}
                --if rStartCol <= length(wcprops[wcpText][idx][rStartLine]) then
                --    txt[1] = wcprops[wcpText][idx][rStartLine][1..rStartCol] & txt[1]
                --end if
                --nc = wcprops[wcpSelEndCol][idx] + length(txt[$])
                --? {rStartLine, rStartCol, rEndLine, rEndCol}
                --if rEndCol <= length(wcprops[wcpText][idx][rEndLine]) then
                --    txt[$] = txt[$] & wcprops[wcpText][idx][rEndLine][rEndCol..$]
                --end if
                --wcprops[wcpText][idx] = wcprops[wcpText][idx][1..rStartLine-1] & txt & wcprops[wcpText][idx][rStartLine+1..$]
                
                txt[1] = wcprops[wcpText][idx][rStartLine][1..rStartCol] & txt[1] 
                txt[$] = txt[$] & wcprops[wcpText][idx][rStartLine][rStartCol+1..$]
                wcprops[wcpText][idx] = wcprops[wcpText][idx][1..rStartLine-1] & txt & wcprops[wcpText][idx][rStartLine+1..$]
                
            end if
        end if
    end if
    
    --If called from wc_create() then don't build text lines (will be done later during arrange)
    --if equal(wcprops[wcpVisibleSize][idx], {0, 0}) then
    --    return
    --end if
    
    rebuild_text_lines(idx, wh)
    move_cursor(idx, wh, 0, 0)
    
    --move cursor to end of new text
    --wcprops[wcpSelStartLine][idx] += length(txt) - 1
    --wcprops[wcpSelStartCol][idx] = nc
    --wcprops[wcpSelEndLine][idx] = wcprops[wcpSelStartLine][idx]
    --wcprops[wcpSelEndCol][idx] = wcprops[wcpSelStartCol][idx]

    --? {wcprops[wcpTextLinesLine][idx], wcprops[wcpTextLinesCol][idx], wcprops[wcpTextLinesLength][idx], wcprops[wcpTextLinesWidth][idx]}
    
end procedure


function get_line_width(atom idx, atom wh, atom cLine)
    if idx > 0 and cLine > 0 and cLine <= length(wcprops[wcpTextLinesWidth][idx]) then
        if wcprops[wcpTextLinesWidth][idx][cLine] = 0 then
            if wcprops[wcpTextLinesLength][idx][cLine] = 0 then
                wcprops[wcpTextLinesWidth][idx][cLine] = 6
            else
                --?  wcprops[wcpTextLinesLength][idx][cLine]
                wcprops[wcpTextLinesWidth][idx][cLine] = get_text_width(wh, rawtext(idx, cLine, 1, wcprops[wcpTextLinesLength][idx][cLine]))
            end if
        end if
        return wcprops[wcpTextLinesWidth][idx][cLine]
    end if
    return 0
end function


function get_line_under_pos(atom wid, atom xpos, atom ypos)
    sequence  wrect, trect, iformats, ibookmarked, iconlist
    atom idx, scry, ilen, numbered, ih, yp, cLine = 1
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wrect = widget_get_rect(wid)
        trect = wcprops[wcpEditRect][idx]
        trect[2] += wrect[2]
        
        ih = wcprops[wcpLineHeight][idx]
        ilen = length(wcprops[wcpTextLinesLength][idx])
        
        scry = floor(wcprops[wcpScrollPosY][idx])
        yp = trect[2] - scry + ih * ilen
        
        cLine = ilen
        for li = ilen to 1 by -1 do
            if ypos < yp then
                cLine = li
            end if
            yp -= ih
        end for
    end if
    
    return cLine
end function

function locate_cursor(atom idx, atom wh, atom xpos, atom cLine)
    atom len, mcol, scrx
    sequence cc
    len = wcprops[wcpTextLinesLength][idx][cLine]
    scrx = floor(wcprops[wcpScrollPosX][idx])
    mcol = len
    
    if wcprops[wcpOptSameWidth][idx] then
        oswin:set_font(wh, thMonoFont, 9, Normal)
    else
        oswin:set_font(wh, thNormalFont, 9, Normal)
    end if
    
    --find which column the mouse is on
    for p = 1 to len do
        cc = oswin:get_text_extent(wh, rawtext(idx, cLine, 1, p))

        if cc[1] > xpos + scrx then
            mcol = p - 1
            exit
        end if
    end for
    
    if mcol < 0 then
        mcol = 0
    elsif mcol > len then
        mcol = len
    end if
    
    return mcol
end function


procedure move_cursor(atom idx, atom wh, atom relcol, atom relline)
    atom cLine
    
    if wcprops[wcpSelStartLine][idx] > wcprops[wcpSelEndLine][idx] then --we only care about the start of selection
        wcprops[wcpSelStartLine][idx] = wcprops[wcpSelEndLine][idx]
        wcprops[wcpSelStartCol][idx] = wcprops[wcpSelEndCol][idx]
    elsif wcprops[wcpSelStartLine][idx] = wcprops[wcpSelEndLine][idx] and wcprops[wcpSelStartCol][idx] > wcprops[wcpSelEndCol][idx] then
        wcprops[wcpSelStartLine][idx] = wcprops[wcpSelEndLine][idx]
        wcprops[wcpSelStartCol][idx] = wcprops[wcpSelEndCol][idx]
    end if
    
    if wcprops[wcpOptSameWidth][idx] then
        oswin:set_font(wh, thMonoFont, 9, Normal)
    else
        oswin:set_font(wh, thNormalFont, 9, Normal)
    end if
    
    --Move vertical direction:
    if relline = -2 then
        wcprops[wcpSelStartLine][idx] = 1
    elsif relline = -1 then
        wcprops[wcpSelStartLine][idx] -= 1
    elsif relline = 0 then
        --do nothing
    elsif relline = 1 then
        wcprops[wcpSelStartLine][idx] += 1
    elsif relline = 2 then
        wcprops[wcpSelStartLine][idx] = length(wcprops[wcpTextLinesLength][idx])
    end if
    
    if wcprops[wcpSelStartLine][idx] < 1 then
        wcprops[wcpSelStartLine][idx] = 1
        wcprops[wcpSelStartCol][idx] = 0
    elsif wcprops[wcpSelStartLine][idx] > length(wcprops[wcpTextLinesLength][idx]) then
        wcprops[wcpSelStartLine][idx] = length(wcprops[wcpTextLinesLength][idx])
        wcprops[wcpSelStartCol][idx] = wcprops[wcpTextLinesLength][idx][wcprops[wcpSelStartLine][idx]]
    end if
    
    --Move horizontal direction:
    if relcol = -2 then
        wcprops[wcpSelStartCol][idx] = 0
    elsif relcol = -1 then
        wcprops[wcpSelStartCol][idx] -= 1
    elsif relcol = 0 then
        --do nothing
    elsif relcol = 1 then
        wcprops[wcpSelStartCol][idx] += 1
    elsif relcol = 2 then
        wcprops[wcpSelStartCol][idx] = wcprops[wcpTextLinesLength][idx][wcprops[wcpSelStartLine][idx]]
    end if
    
    if wcprops[wcpSelStartCol][idx] < 0 then
        wcprops[wcpSelStartLine][idx] -= 1
        if wcprops[wcpSelStartLine][idx] < 1 then
            wcprops[wcpSelStartLine][idx] = 1
            wcprops[wcpSelStartCol][idx] = 0
        else
            wcprops[wcpSelStartCol][idx] = wcprops[wcpTextLinesLength][idx][wcprops[wcpSelStartLine][idx]]
        end if
    elsif wcprops[wcpSelStartCol][idx] > wcprops[wcpTextLinesLength][idx][wcprops[wcpSelStartLine][idx]] then
        wcprops[wcpSelStartLine][idx] += 1
        
        if wcprops[wcpSelStartLine][idx] > length(wcprops[wcpTextLinesLength][idx]) then
            wcprops[wcpSelStartLine][idx] = length(wcprops[wcpTextLinesLength][idx])
            wcprops[wcpSelStartCol][idx] = wcprops[wcpTextLinesLength][idx][wcprops[wcpSelStartLine][idx]]
        else
            wcprops[wcpSelStartCol][idx] = 0
        end if
        
    end if
    
    wcprops[wcpSelStartX][idx] = get_text_width(wh, rawtext(idx, wcprops[wcpSelStartLine][idx], 1, wcprops[wcpSelStartCol][idx]))
    wcprops[wcpSelEndLine][idx] = wcprops[wcpSelStartLine][idx]
    wcprops[wcpSelEndCol][idx] = wcprops[wcpSelStartCol][idx]
    wcprops[wcpSelEndX][idx] = wcprops[wcpSelStartX][idx]
end procedure


procedure keep_cursor_in_view(atom idx, sequence trect)
    atom cx, cy
    
    cx = trect[1] + floor(wcprops[wcpScrollPosX][idx]) + 2 + wcprops[wcpSelStartX][idx]
    if equal(wcprops[wcpOptMode][idx], "text") then
        cy = trect[2] - floor(wcprops[wcpScrollPosY][idx]) + wcprops[wcpSelStartLine][idx] * wcprops[wcpLineHeight][idx] - wcprops[wcpLineHeight][idx]
        
        if cx > trect[3] - 20 then --to the right
            if wcprops[wcpScrollH][idx] > 0 then
                wc_call_command(wcprops[wcpScrollH][idx], "set_value_rel", cx - trect[1] - floor((trect[3] - trect[1]) / 2))
            end if
        elsif cx < trect[1] + 20 then --to the left
            if wcprops[wcpScrollH][idx] > 0 then
                wc_call_command(wcprops[wcpScrollH][idx], "set_value_rel", cx - trect[1] - floor((trect[3] - trect[1]) / 2))
            end if
        end if
        
        if cy > trect[4] - wcprops[wcpLineHeight][idx] - 20 then --below
            if wcprops[wcpScrollV][idx] > 0 then
                wc_call_command(wcprops[wcpScrollV][idx], "set_value_rel", cy - trect[2] - floor((trect[4] - trect[2]) / 2) + wcprops[wcpLineHeight][idx])
            end if
        elsif cy < trect[2] + wcprops[wcpLineHeight][idx] + 20 then --above
            if wcprops[wcpScrollV][idx] > 0 then
                wc_call_command(wcprops[wcpScrollV][idx], "set_value_rel", cy - trect[2] - floor((trect[4] - trect[2]) / 2))
            end if
        end if
    end if
end procedure


procedure update_content_size(atom wid)
    sequence wrect, lpos, trect, tw
    atom idx, wh, th, vh, vw 
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wh = widget:widget_get_handle(wid)
        wrect = widget_get_rect(wid)
        wrect[3] -= 1
        wrect[4] -= 1
        
        lpos = wcprops[wcpLabelPos][idx]
        trect = wcprops[wcpEditRect][idx]
        lpos[1] += wrect[1]
        lpos[2] += wrect[2]
        trect[1] += wrect[1]
        trect[2] += wrect[2]
        trect[3] += wrect[1]
        trect[4] += wrect[2]
        if wcprops[wcpScrollV][idx] then
            trect[3] -= scrwidth
        end if
        if wcprops[wcpScrollH][idx] then
            trect[4] -= scrwidth
        end if
        
        if wcprops[wcpOptSameWidth][idx] then
            oswin:set_font(wh, thMonoFont, 9, Normal)
        else
            oswin:set_font(wh, thNormalFont, 9, Normal)
        end if
        
        th = length(wcprops[wcpTextLinesLength][idx]+1) * wcprops[wcpLineHeight][idx]
        vh = trect[4] - trect[2] - 1
        tw = {}
        for li = 1 to length(wcprops[wcpTextLinesLength][idx]) do
            tw &= get_line_width(idx, wh, li)  --get_text_width(wh, wcprops[wcpTextLinesLength][idx][li])
        end for
        vw = trect[3] - trect[1] - 1
        
        wcprops[wcpContentSize][idx] = {max(tw) + scrwidth + 8, th + scrwidth}
    end if
end procedure


procedure check_scrollbars(atom idx, atom wid) --check contents and size of widget to determine if scrollbars are needed, then create or destroy scrollbars when required. 
    sequence wpos, wsize, trect = {}
    atom th, vh, setsize = 0
    
    if equal(wcprops[wcpOptMode][idx], "text") then
        if wcprops[wcpContentSize][idx][2] > wcprops[wcpVisibleSize][idx][2] and wcprops[wcpScrollV][idx] = 0 then
            wpos = widget_get_pos(wid)
            wsize = widget_get_size(wid)
            trect = wcprops[wcpEditRect][idx]
            trect[3] -= scrwidth
            
            wcprops[wcpScrollV][idx] = widget:widget_create(widget_get_name(wid) & ".scrV", wid, "scrollbar", {
                {"attach", wid},
                {"orientation", 0},
                {"min", 0},
                {"position", {wpos[1] + trect[3]+1, wpos[2] + trect[2]}} --wpos[1] + trect[3]+1, wpos[2] + trect[2]
                --{"size", {scrwidth, trect[4] - trect[2] + 1}}     --scrwidth, wcprops[wcpVisibleSize][idx][2]
            })
            setsize = 1
            
        elsif wcprops[wcpContentSize][idx][2] <= wcprops[wcpVisibleSize][idx][2] and wcprops[wcpScrollV][idx] > 0 then
            widget:widget_destroy(wcprops[wcpScrollV][idx])
            wcprops[wcpScrollV][idx] = 0
            wcprops[wcpScrollPosY][idx] = 0
            setsize = 1
        end if
        
        if wcprops[wcpContentSize][idx][1] > wcprops[wcpVisibleSize][idx][1] and wcprops[wcpScrollH][idx] = 0 then
            wpos = widget_get_pos(wid)
            wsize = widget_get_size(wid)
            trect = wcprops[wcpEditRect][idx]
            trect[4] -= scrwidth
            
            wcprops[wcpScrollH][idx] = widget:widget_create(widget_get_name(wid) & ".scrH", wid, "scrollbar", {
                {"attach", wid},
                {"orientation", 1},
                {"min", 0},
                {"position", {wpos[1] + trect[1], wpos[2] + trect[4]+1}} --wpos[1] + 1, wpos[2] + trect[4]
                --{"size", {, scrwidth}} --wcprops[wcpVisibleSize][idx][1], scrwidth
            })
            setsize = 1
            
        elsif wcprops[wcpContentSize][idx][1] <= wcprops[wcpVisibleSize][idx][1] and wcprops[wcpScrollH][idx] > 0 then
            widget:widget_destroy(wcprops[wcpScrollH][idx])
            wcprops[wcpScrollH][idx] = 0
            wcprops[wcpScrollPosX][idx] = 0
            setsize = 1
        end if
        
        if setsize = 1 then
            trect = wcprops[wcpEditRect][idx]
            if wcprops[wcpScrollV][idx] > 0 then
                trect[3] -= scrwidth
            end if
            if wcprops[wcpScrollH][idx] > 0 then
                trect[4] -= scrwidth
            end if
        end if
        
        if wcprops[wcpScrollV][idx] > 0 then
            th = wcprops[wcpContentSize][idx][2]
            vh = wcprops[wcpVisibleSize][idx][2]
            
            if setsize = 1 then
                widget_set_size(wcprops[wcpScrollV][idx], scrwidth, trect[4] - trect[2] + 1)
                wc_call_arrange(wcprops[wcpScrollV][idx])
            end if
            
            wc_call_command(wcprops[wcpScrollV][idx], "set_max", th)
            wc_call_command(wcprops[wcpScrollV][idx], "set_range", vh)        
            --if wcprops[wcpStayAtBottom][idx] then
            --    wc_call_command(wcprops[wcpScrollV][idx], "set_value", th)
            --else
                wc_call_command(wcprops[wcpScrollV][idx], "set_value", wcprops[wcpScrollPosY][idx])
            --end if
        end if
        
        if wcprops[wcpScrollH][idx] > 0 then
            th = wcprops[wcpContentSize][idx][1]
            vh = wcprops[wcpVisibleSize][idx][1]
            
            if setsize = 1 then
                widget_set_size(wcprops[wcpScrollH][idx], trect[3] - trect[1] + 1, scrwidth)
                wc_call_arrange(wcprops[wcpScrollH][idx])
            end if
            
            wc_call_command(wcprops[wcpScrollH][idx], "set_max", th)
            wc_call_command(wcprops[wcpScrollH][idx], "set_range", vh)
            wc_call_command(wcprops[wcpScrollH][idx], "set_value", wcprops[wcpScrollPosX][idx])
        end if
    end if
end procedure


-- widgetclass handlers ----------------------------

procedure wc_create(atom wid, object wprops) 
    atom orientation = 0, smx = 0, smy = 0, wparent, wh, optSameWidth = 0, optHighlightLine = 0, optLocked = 0, optAllowNewline = 1,
    wlabelpos = 0
    sequence wpos, wsize, wlabel = "", wtext = {""}, txex, lpos, trect
    object optMode = "string", optModeOptions = 0, optMin = 0, optMax = 0, optDataFormat = 0, optControlVisible = 0,
    optWordWrap = 1, optVisibleLines = 3, optList = {}, optRestrict = 0, optPrecision = "second", optMask = 149,
    optSpecialMaxSize = 20, sprect = 0
    atom wautofocus = 0
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do         
                case "autofocus" then
                    wautofocus = wprops[p][2]
                case "label" then
                    wlabel = wprops[p][2]
                case "label_position" then
                    if equal("side", wprops[p][2]) then
                        wlabelpos = 1
                    elsif equal("above", wprops[p][2]) then
                        wlabelpos = 2
                    end if
                case "text" then
                    wtext = wprops[p][2]
                    if length(wtext) > 0 then
                        if atom(wtext[1]) then  --if this is an atom, it means that this is raw text, not a sequence of lines of text)
                            wtext = remove_all(13, wtext)
                            wtext = split(wtext, 10)
                        end if
                    end if
                case "monowidth" then
                    optSameWidth = wprops[p][2]
                case "highlight" then
                    optHighlightLine = wprops[p][2]
                case "locked" then
                    optLocked = wprops[p][2]
                case "mode" then
                    optMode = wprops[p][2]  --{"number", "text", "string", "item", "datetime", "password"}
                case "min" then
                    optMin = wprops[p][2]
                case "max" then
                    optMax = wprops[p][2]
                case "format" then
                    optDataFormat = wprops[p][2]
                case "show_control" then
                    optControlVisible = wprops[p][2]
                --case "spell_check" then
                    --optControlVisible = wprops[p][2]
                case "wordwrap" then
                    optWordWrap = wprops[p][2]
                case "visible_lines" then
                    optVisibleLines = wprops[p][2]
                case "allow_newline" then  --{"year", "month", "day", "minute", "second"}
                    optAllowNewline = wprops[p][2]
                case "list" then
                    optList = wprops[p][2]
                case "restrict_to_list" then
                    optRestrict = wprops[p][2]
                case "precision" then  --{"year", "month", "day", "minute", "second"}
                    optPrecision = wprops[p][2]
                case "mask" then
                    optMask = wprops[p][2]
            end switch
        end if
    end for
    
    if length(wtext) > 1 and equal(optMode, "string") then
        optMode = "text"
    end if
    switch optMode do
        case "number" then
            optModeOptions = {optMin, optMax}
            if wlabelpos = 0 then
                wlabelpos = 2 --single line default: side
            end if
        case "text" then
            optModeOptions = {optWordWrap, optVisibleLines}
            optControlVisible = 0
            if wlabelpos = 0 then
                --if optVisibleLines > 1 then
                --    wlabelpos = 1 --multiline default: above
                --else
                --    wlabelpos = 2 --single line default: side
                --end if
                wlabelpos = 1
            end if
        case "string" then
            optModeOptions = optList
            if wlabelpos = 0 then
                wlabelpos = 2 --single line default: side
            end if
        case "item" then
            optModeOptions = optList
            optDataFormat = optRestrict
            if wlabelpos = 0 then
                wlabelpos = 2 --single line default: side
            end if
        case "datetime" then
            optModeOptions = optPrecision
            if wlabelpos = 0 then
                wlabelpos = 2 --single line default: side
            end if
        case "password" then
            optModeOptions = optMask
            if wlabelpos = 0 then
                wlabelpos = 2 --single line default: side
            end if
    end switch
    
    if optControlVisible > 0 then
        sprect = {0, 0, 0, 0}
    else
        sprect = 0
    end if
    
    wcprops[wcpID] &= {wid}
    wcprops[wcpSoftFocus] &= {0}
    --wcprops[wcpHardFocus] &= {0}
    wcprops[wcpKeyFocus] &= {0}
    wcprops[wcpAutoFocus] &= {wautofocus}
    wcprops[wcpIsSelecting] &= {0}
    wcprops[wcpCursorState] &= {0}
    wcprops[wcpKeyShift] &= {0}
    wcprops[wcpKeyCtrl] &= {0}
    wcprops[wcpKeyAlt] &= {0}
    
    wcprops[wcpLabel] &= {wlabel}    
    wcprops[wcpLabelPosition] &= {wlabelpos}
    wcprops[wcpHover] &= {0}  
    wcprops[wcpMenuID] &= {0}
    
    wcprops[wcpSpecialRect] &= {sprect}
    wcprops[wcpSpecialHover] &= {0}
    wcprops[wcpSpecialPressed] &= {0}
    wcprops[wcpSpecialWidgetID] &= {0}
    wcprops[wcpSpecialMaxSize] &= {optSpecialMaxSize}
    
    wcprops[wcpOptMode] &= {optMode}
    wcprops[wcpOptModeOptions] &= {optModeOptions}
    wcprops[wcpOptDataFormat] &= {optDataFormat}
    wcprops[wcpOptControlVisible] &= {optControlVisible}
    wcprops[wcpOptSameWidth] &= {optSameWidth}
    wcprops[wcpOptHighlightLine] &= {optHighlightLine}    
    wcprops[wcpOptLocked] &= {optLocked}
    wcprops[wcpOptAllowNewline] &= {optAllowNewline}
    
    wcprops[wcpLineHeight] &= {16}
    wcprops[wcpLabelPos] &= {{0, 0}}
    wcprops[wcpEditRect] &= {{0, 0, 0, 0}}
    wcprops[wcpVisibleSize] &= {{0, 0}}
    wcprops[wcpContentSize] &= {{0, 0}}
    wcprops[wcpScrollPosX] &= {0}
    wcprops[wcpScrollPosY] &= {0}
    wcprops[wcpScrollV] &= {0}
    wcprops[wcpScrollH] &= {0}
    
    wcprops[wcpSelStartLine] &= {1}
    wcprops[wcpSelStartCol] &= {0}
    wcprops[wcpSelEndLine] &= {1}
    wcprops[wcpSelEndCol] &= {0}
    wcprops[wcpSelStartX] &= {0}
    wcprops[wcpSelEndX] &= {0}    
    
    wcprops[wcpText] &= {{""}}
    
    
    wcprops[wcpTextLinesLine] &= {{1}}
    wcprops[wcpTextLinesCol] &= {{0}}
    wcprops[wcpTextLinesLength] &= {{0}}
    wcprops[wcpTextLinesWidth] &= {{0}}
    
    atom idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wh = widget:widget_get_handle(wid)
        if length(FontList) = 0 then
            set_default_monofont(wh, thMonoFonts)
        end if
        insert_txt(idx, wh, wtext)
        
        --rebuild_text_lines(idx, wh)
        
        --pretty_print(1, wcprops[wcpText][idx], {2})
        --update_content_size(wid)
        --check_scrollbars(idx, wid)
        
        if wautofocus then
            widget:set_key_focus(wid)
        end if
    end if
    --wc_call_event(wid, "changed", {})
end procedure


procedure wc_destroy(atom wid)
    atom idx
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        for p = 1 to wcpLENGTH do
            wcprops[p] = remove(wcprops[p], idx)
        end for
    end if
end procedure


procedure wc_draw(atom wid)
    sequence cmds, wrect, chwid, txex, txpos, trect, irect, sprect
    atom idx, wh, wf, hlcolor, shcolor, fillcolor, lblcolor, txtcolor, txtselcolor, txtselhicolor, hicolor, txtbkcolor, arrowcolor
    atom sStartLine, sStartCol, sStartX, sEndLine, sEndCol, sEndX
    atom numbered, ih, xp, yp, ss, bsz
    sequence iformats, ibookmarked
    atom scry,scrx, hover
    sequence selection
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wh = widget:widget_get_handle(wid)
        wrect = widget_get_rect(wid)
        --wrect[3] -= 1
        --wrect[4] -= 1
        trect = wcprops[wcpEditRect][idx]
        trect[1] += wrect[1]
        trect[2] += wrect[2]
        trect[3] += wrect[1]
        trect[4] += wrect[2]
        if wcprops[wcpScrollV][idx] then
            trect[3] -= scrwidth
        end if
        if wcprops[wcpScrollH][idx] then
            trect[4] -= scrwidth
        end if        
        
        txtselcolor = th:cInnerTextSelInact
        txtselhicolor = th:cInnerSelInact
        
        wh = widget:widget_get_handle(wid)
        wf = (wh = oswin:get_window_focus())
        
        if wf and wcprops[wcpKeyFocus][idx] then
            hicolor = th:cOuterActive
            txtselcolor = th:cInnerTextSel
            txtselhicolor = th:cInnerSel
        elsif wcprops[wcpSoftFocus][idx] then
            hicolor = th:cOuterHover
        else
            hicolor = th:cOuterFill
        end if
        
        arrowcolor = th:cButtonDark
        shcolor = th:cButtonShadow
        hlcolor = th:cButtonHighlight
        lblcolor = th:cOuterLabel
        txtcolor = th:cInnerText
        txtbkcolor = th:cInnerFill
        
        if widget:widget_is_enabled(wid) = 0 then
            hicolor = th:cOuterFill
            lblcolor = th:cButtonDisLabel
            txtselcolor = th:cButtonDisLabel
            txtcolor = th:cButtonDisLabel
            txtbkcolor = th:cInnerItemOddSelInact --th:cButtonFace --th:cOuterFill
        end if
        
        txpos = {
            wrect[1] + wcprops[wcpLabelPos][idx][1] + 1,
            wrect[2] + wcprops[wcpLabelPos][idx][2] + 1
        }
        
        cmds = {
        --fill:
            {DR_PenColor, hicolor},
            {DR_Rectangle, True} & wrect,
            
        --label:
            {DR_Font, thNormalFont, 9, Normal},
            {DR_TextColor, lblcolor},
            {DR_PenPos} & txpos,
            {DR_Puts, wcprops[wcpLabel][idx]},
            
        --text border:
            {DR_PenColor, shcolor},
            {DR_Line, trect[1], trect[2]-1, trect[3]-1, trect[2]-1},
            {DR_Line, trect[1], trect[2]-1, trect[1], trect[4]-1},
            
            {DR_PenColor, hlcolor},
            {DR_Line, trect[3]-1, trect[2] + 1-1, trect[3]-1, trect[4]-1},
            {DR_Line, trect[1], trect[4]-1, trect[3]-1, trect[4]-1}
        }
        
        ih = wcprops[wcpLineHeight][idx]
        --itexts = wcprops[wcpTextLinesLength][idx]
        
        scrx = floor(wcprops[wcpScrollPosX][idx])
        scry = floor(wcprops[wcpScrollPosY][idx])
        
        --selection = wcprops[wcpSelection][idx]
        hover = wcprops[wcpHover][idx]
        
--Text Lines:
        xp = trect[1]+1
        yp = trect[2]
        
        cmds &= {
            {DR_Release},
            {DR_Restrict, xp, yp, trect[3], trect[4]},
            {DR_PenColor, txtbkcolor},
            {DR_Rectangle, True, xp, yp, trect[3], trect[4]}
        }
        
        if wcprops[wcpOptSameWidth][idx] then
            cmds &= {{DR_Font, thMonoFont, 9, Normal}}
            oswin:set_font(wh, thMonoFont, 9, Normal)
        else
            cmds &= {{DR_Font, thNormalFont, 9, Normal}}
            oswin:set_font(wh, thNormalFont, 9, Normal)
        end if
        
        if wcprops[wcpSelStartLine][idx] > wcprops[wcpSelEndLine][idx] then
            sStartLine = wcprops[wcpSelEndLine][idx]
            sStartCol = wcprops[wcpSelEndCol][idx]
            sStartX = wcprops[wcpSelEndX][idx]
            sEndLine = wcprops[wcpSelStartLine][idx]
            sEndCol = wcprops[wcpSelStartCol][idx]
            sEndX = wcprops[wcpSelStartX][idx]
        elsif wcprops[wcpSelStartLine][idx] = wcprops[wcpSelEndLine][idx] and wcprops[wcpSelStartCol][idx] > wcprops[wcpSelEndCol][idx] then
            sStartLine = wcprops[wcpSelStartLine][idx]
            sStartCol = wcprops[wcpSelEndCol][idx]
            sStartX = wcprops[wcpSelEndX][idx]
            sEndLine = wcprops[wcpSelEndLine][idx]
            sEndCol = wcprops[wcpSelStartCol][idx]
            sEndX = wcprops[wcpSelStartX][idx]
        else
            sStartLine = wcprops[wcpSelStartLine][idx]
            sStartCol = wcprops[wcpSelStartCol][idx]
            sStartX = wcprops[wcpSelStartX][idx]
            sEndLine = wcprops[wcpSelEndLine][idx]
            sEndCol = wcprops[wcpSelEndCol][idx]
            sEndX = wcprops[wcpSelEndX][idx]
        end if
        
        /*if wcprops[wcpUpdateCursor][idx] and sStartLine = sEndLine and sStartCol = sEndCol then --not implemented yet: draw current line of text and the cursor only
            wcprops[wcpUpdateCursor][idx] = 0
            txtbkcolor = thCurrLineBkColor
            cmds &= {
                {DR_PenColor, txtbkcolor},
                {DR_Rectangle, True,
                    xp - scrx + 2, yp - scry,
                    trect[3], yp - scry + ih
                },
                {DR_TextColor, th:cInnerText},
                {DR_PenPos, xp - scrx + 2, yp - scry + 0},
                {DR_Puts, itexts[li]}
            }
            if wcprops[wcpHardFocus][idx] and wcprops[wcpCursorState][idx] then --draw cursor
                cmds &= {
                    {DR_PenColor, th:cInnerDark},
                    {DR_Line,
                        xp - scrx + 2 + wcprops[wcpSelStartX][idx], yp - scry,
                        xp - scrx + 2 + wcprops[wcpSelStartX][idx], yp - scry + ih}
                }
            end if
        end if*/
        
        xp = trect[1]+1
        yp = trect[2]+1
        
        for li = 1 to length(wcprops[wcpTextLinesLine][idx]) do                      
            if yp - scry > trect[2] - ih and yp - scry - ih < trect[4] then
                if li = sStartLine and equal(wcprops[wcpOptMode][idx], "text") and wcprops[wcpOptHighlightLine][idx] = 1 then
                    cmds &= {
                        {DR_PenColor, thCurrLineBkColor},
                        {DR_Rectangle, True,
                            xp - scrx + 2, yp - scry,
                            trect[3], yp - scry + ih
                        }
                    }
                end if
                
                --TODO: if equal(wcprops[wcpOptMode][idx], "password") then print *** instead of real text
                
                --selection:
                if li < sStartLine or li > sEndLine then      --draw a line of normal text only
                    cmds &= {
                        {DR_TextColor, txtcolor},
                        {DR_PenPos, xp - scrx + 2, yp - scry + 0},
                        {DR_Puts, rawtext(idx, li, 1, wcprops[wcpTextLinesLength][idx][li])}
                    }
                elsif li = sStartLine and li = sEndLine then  --draw a line of normal text first...
                    cmds &= {
                        {DR_TextColor, txtcolor},
                        {DR_PenPos, xp - scrx + 2, yp - scry + 0},
                        {DR_Puts, rawtext(idx, li, 1, wcprops[wcpTextLinesLength][idx][li])}
                    }
                    if sStartCol != sEndCol then              --then draw selected text from start to end
                        cmds &= {
                            {DR_PenColor, txtselhicolor},
                            {DR_Rectangle, True,
                                xp - scrx + 2 + sStartX, yp - scry,
                                xp - scrx + 2 + sEndX, yp - scry + ih
                            },
                            {DR_TextColor, txtselcolor},
                            {DR_PenPos,  xp - scrx + 2 + sStartX, yp - scry + 0},
                            {DR_Puts, rawtext(idx, li, sStartCol+1, sEndCol)}
                        }
                    else  --temporary: draw non-blinking cursor
                        if wf and wcprops[wcpKeyFocus][idx] and wcprops[wcpOptLocked][idx] = 0 and wcprops[wcpCursorState][idx] then
                            cmds &= { 
                                {DR_PenColor, th:cInnerDark},
                                {DR_Line,
                                    xp - scrx + 2 + sStartX, yp - scry,
                                    xp - scrx + 2 + sStartX, yp - scry + ih}
                            }
                        end if
                    end if
                elsif li = sStartLine and li < sEndLine then  --draw selected text from start
                    cmds &= {
                        --draw normal text:
                        {DR_TextColor, txtcolor},
                        {DR_PenPos, xp - scrx + 2, yp - scry + 0},
                        {DR_Puts, rawtext(idx, li, 1, sStartCol)},
                        --draw selected text:
                        {DR_PenColor, txtselhicolor},
                        {DR_Rectangle, True,
                            xp - scrx + 2 + sStartX, yp - scry,
                            xp - scrx + 2 + get_line_width(idx, wh, li), yp - scry + ih
                        },
                        {DR_TextColor, txtselcolor},
                        {DR_PenPos,  xp - scrx + 2 + sStartX, yp - scry + 0},
                        {DR_Puts, rawtext(idx, li, sStartCol+1, wcprops[wcpTextLinesLength][idx][li])}
                    }
                elsif li > sStartLine and li < sEndLine then  --draw selected text only
                    cmds &= {
                        {DR_PenColor, txtselhicolor},
                        {DR_Rectangle, True,
                            xp - scrx + 2, yp - scry,
                            xp - scrx + 2 + get_line_width(idx, wh, li), yp - scry + ih
                        },
                        {DR_TextColor, txtselcolor},
                        {DR_PenPos,  xp - scrx + 2, yp - scry + 0},
                        {DR_Puts, rawtext(idx, li, 1, wcprops[wcpTextLinesLength][idx][li])}
                    }
                elsif li > sStartLine and li = sEndLine then  --draw selected text to end
                    cmds &= { 
                        --draw selected text:
                        {DR_PenColor, txtselhicolor},
                        {DR_Rectangle, True,
                            xp - scrx + 2, yp - scry,
                            xp - scrx + 2 + sEndX, yp - scry + ih
                        },
                        {DR_TextColor, txtselcolor},
                        {DR_PenPos,  xp - scrx + 2, yp - scry + 0},
                        {DR_Puts, rawtext(idx, li, 1, sEndCol)},
                        --draw normal text:
                        {DR_TextColor, txtcolor},
                        {DR_PenPos, xp - scrx + 2 + sEndX, yp - scry + 0},
                        {DR_Puts, rawtext(idx, li, sEndCol+1, wcprops[wcpTextLinesLength][idx][li])}
                    }
                end if
            end if
            yp += ih
        end for
        
        cmds &= {
            {DR_Release}
        }
        
        --special button:
        --if wcprops[wcpOptControlVisible][idx] > 0 then
        --i don't remember what my original intention was for the values of wcpOptControlVisible
        
        if wcprops[wcpOptControlVisible][idx] = 1 then
            sprect = wcprops[wcpSpecialRect][idx]
            sprect[1] += wrect[1]
            sprect[2] += wrect[2]
            sprect[3] += wrect[1]
            sprect[4] += wrect[2]
            
            if wcprops[wcpSpecialHover][idx] then
                hicolor = th:cButtonHover
            else
                hicolor = th:cButtonFace
            end if
            if wcprops[wcpSpecialPressed][idx] then
                hlcolor = th:cButtonShadow
                shcolor = th:cButtonHighlight
            else
                shcolor = th:cButtonShadow
                hlcolor = th:cButtonHighlight
            end if
                    
            cmds &= {
                {DR_PenColor, hicolor},
                {DR_Rectangle, True} & sprect,
                
                {DR_PenColor, hlcolor},
                {DR_Line, sprect[1], sprect[2], sprect[3], sprect[2]},
                {DR_Line, sprect[1], sprect[2], sprect[1], sprect[4]},
                
                {DR_PenColor, shcolor},
                
                {DR_Line, sprect[3], sprect[2], sprect[3], sprect[4]},
                {DR_Line, sprect[1], sprect[4], sprect[3], sprect[4]}
            }
            
            --if wcprops[wcpOptControlVisible][idx] = 1 then --dropdown
            --i don't remember what my original intention was for the values of wcpOptControlVisible
            
            if equal(wcprops[wcpOptMode][idx], "item") then
                bsz = sprect[3] - sprect[1]
                cmds &= {
                    {DR_PenColor, arrowcolor},
                    {DR_BrushColor, arrowcolor},
                
                    {DR_PolyLine, True, {  --fill triangle
                        {floor(sprect[1] + bsz *.7), floor(sprect[2] + bsz *.3)},
                        {floor(sprect[1] + bsz *.5), floor(sprect[2] + bsz *.7)},
                        {floor(sprect[1] + bsz *.3), floor(sprect[2] + bsz *.3)},
                        {floor(sprect[1] + bsz *.7), floor(sprect[2] + bsz *.3)}
                    }},
                    
                    {DR_PenColor, shcolor},
                    {DR_Line, floor(sprect[1] + bsz *.3), floor(sprect[2] + bsz *.3), floor(sprect[1] + bsz *.7), floor(sprect[2] + bsz *.3)},
                    {DR_Line, floor(sprect[1] + bsz *.3), floor(sprect[2] + bsz *.3), floor(sprect[1] + bsz *.5), floor(sprect[2] + bsz *.7)},
                     
                    {DR_PenColor, hlcolor},
                    {DR_Line, floor(sprect[1] + bsz *.7), floor(sprect[2] + bsz *.3), floor(sprect[1] + bsz *.5), floor(sprect[2] + bsz *.7)}
                    
                }
            
            --elsif equal(wcprops[wcpOptMode][idx], "number") then
            --elsif equal(wcprops[wcpOptMode][idx], "text") then
            --elsif equal(wcprops[wcpOptMode][idx], "string") then
            --elsif equal(wcprops[wcpOptMode][idx], "item") then
            --elsif equal(wcprops[wcpOptMode][idx], "datetime") then
            --elsif equal(wcprops[wcpOptMode][idx], "password") then
            end if
        end if
        draw(wh, cmds)
        
        chwid = children_of(wid)
        for ch = 1 to length(chwid) do
            wc_call_draw(chwid[ch])
        end for
    end if
end procedure


procedure wc_event(atom wid, sequence evtype, object evdata)
    sequence ampos, wrect, lpos, trect, tw, avrect, winpos, cbaction = "", txt
    atom idx, doredraw = 0, wh, ss, se, skip = 0, cLine, th, vh, vw, enabled
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        --if not equal(evtype, "Timer") then
        --    pretty_print(1, {evtype, evdata}, {2})
        --end if
        
        enabled = widget:widget_is_enabled(wid)
        wh = widget:widget_get_handle(wid)
        wrect = widget_get_rect(wid)
        --wrect[3] -= 1
        --wrect[4] -= 1
        
        lpos = wcprops[wcpLabelPos][idx]
        trect = wcprops[wcpEditRect][idx]
        lpos[1] += wrect[1]
        lpos[2] += wrect[2]
        trect[1] += wrect[1] + 1
        trect[2] += wrect[2] + 1
        trect[3] += wrect[1]
        trect[4] += wrect[2]
        if wcprops[wcpScrollV][idx] then
            trect[3] -= scrwidth
        end if
        if wcprops[wcpScrollH][idx] then
            trect[4] -= scrwidth
        end if
        
        switch evtype do        
            case "MouseMove" then --{x, y, shift, mousepos[1], mousepos[2]}
                if in_rect(evdata[1], evdata[2], wrect) then
                    if wcprops[wcpSoftFocus][idx] = 0 then
                        wcprops[wcpSoftFocus][idx] = 1
                        doredraw = 1
                    end if
                else
                    if wcprops[wcpSoftFocus][idx] = 1 then
                        wcprops[wcpSoftFocus][idx] = 0
                        doredraw = 1
                    end if
                end if
                
                if in_rect(evdata[1], evdata[2], trect) then
                    if wcprops[wcpSoftFocus][idx] then
                        set_mouse_pointer(wh, mIbeam)
                    end if
                else
                    if wcprops[wcpHover][idx] > 0 then
                        wcprops[wcpHover][idx] = 0
                        doredraw = 1
                    end if
                    if wcprops[wcpSoftFocus][idx] then
                        set_mouse_pointer(wh, mArrow)
                    end if
                end if
                if wcprops[wcpIsSelecting][idx] = 1 then
                    if evdata[1] > trect[3] then --to the right
                        if wcprops[wcpScrollH][idx] > 0 then
                            wc_call_command(wcprops[wcpScrollH][idx], "set_value_rel", wcprops[wcpLineHeight][idx])
                        end if
                    elsif evdata[2] > trect[4] then --below
                        if wcprops[wcpScrollV][idx] > 0 then
                            wc_call_command(wcprops[wcpScrollV][idx], "set_value_rel", wcprops[wcpLineHeight][idx])
                        end if
                    elsif evdata[1] < trect[1] then --to the left
                        if wcprops[wcpScrollH][idx] > 0 then
                            wc_call_command(wcprops[wcpScrollH][idx], "set_value_rel", -wcprops[wcpLineHeight][idx])
                        end if
                    elsif evdata[2] < trect[2] then --above
                        if wcprops[wcpScrollV][idx] > 0 then
                            wc_call_command(wcprops[wcpScrollV][idx], "set_value_rel", -wcprops[wcpLineHeight][idx])
                        end if
                    end if
                    cLine = get_line_under_pos(wid, evdata[1], evdata[2])
                    if cLine < 1 then
                        cLine = 1
                    elsif cLine > length(wcprops[wcpTextLinesLength][idx]) then
                        cLine = length(wcprops[wcpTextLinesLength][idx])
                    end if
                    if wcprops[wcpOptSameWidth][idx] then
                        oswin:set_font(wh, thMonoFont, 9, Normal)
                    else
                        oswin:set_font(wh, thNormalFont, 9, Normal)
                    end if
                    wcprops[wcpSelEndLine][idx] = cLine
                    wcprops[wcpSelEndCol][idx] = locate_cursor(idx, wh, evdata[1] - trect[1], cLine)
                    wcprops[wcpSelEndX][idx] = get_text_width(wh, rawtext(idx, cLine, 1, wcprops[wcpSelEndCol][idx]))
                    doredraw = 1
                end if
                
            case "LeftDown" then        
                if in_rect(evdata[1], evdata[2], wrect) then
                    if in_rect(evdata[1], evdata[2], trect) then
                        oswin:capture_mouse(wh)
                        wcprops[wcpIsSelecting][idx] = 1
                        cLine = get_line_under_pos(wid, evdata[1], evdata[2])
                        if cLine < 1 then
                            cLine = 1
                        elsif cLine > length(wcprops[wcpTextLinesLength][idx]) then
                            cLine = length(wcprops[wcpTextLinesLength][idx])
                        end if
                        wcprops[wcpSelStartLine][idx] = cLine
                        wcprops[wcpSelEndLine][idx] = cLine
                        
                        if wcprops[wcpOptSameWidth][idx] then
                            oswin:set_font(wh, thMonoFont, 9, Normal)
                        else
                            oswin:set_font(wh, thNormalFont, 9, Normal)
                        end if
                        wcprops[wcpSelStartCol][idx] = locate_cursor(idx, wh, evdata[1] - trect[1], wcprops[wcpSelStartLine][idx])
                        wcprops[wcpSelStartX][idx] = get_text_width(wh, rawtext(idx, cLine, 1, wcprops[wcpSelStartCol][idx]))
                        wcprops[wcpSelEndCol][idx] = wcprops[wcpSelStartCol][idx]
                        wcprops[wcpSelEndX][idx] = wcprops[wcpSelStartX][idx]
                        doredraw = 1
                    end if
                    
                    --if wcprops[wcpKeyFocus][idx] = 0 then
                    --    wcprops[wcpKeyFocus][idx] = 1
                    --    widget:wc_send_event(widget_get_name(wid), "GotFocus", {})
                    widget:set_key_focus(wid)
                    --doredraw = 1
                    --end if
                --else
                    --if wcprops[wcpKeyFocus][idx] = 1 then
                    --    wcprops[wcpKeyFocus][idx] = 0
                    --    widget:wc_send_event(widget_get_name(wid), "LostFocus", {})
                    --    doredraw = 1
                    --end if
                end if
                  
                if wcprops[wcpMenuID][idx] > 0 then
                    --widget:widget_destroy(wcprops[wcpMenuID][idx])
                    wcprops[wcpMenuID][idx] = 0
                    oswin:close_all_popups("5")
                end if
                
            case "LeftDoubleClick" then
                if in_rect(evdata[1], evdata[2], trect) then --and not equal(wcprops[wcpOptMode][idx], "text") then
                    wcprops[wcpIsSelecting][idx] = 0
                    cbaction = "Select All"
                    doredraw = 1
                end if
                
            case "LeftUp" then      
                if in_rect(evdata[1], evdata[2], trect) then
                    -------
                    doredraw = 1
                end if
                if wcprops[wcpIsSelecting][idx] = 1 then
                    wcprops[wcpIsSelecting][idx] = 0
                    doredraw = 1
                end if
                
            case "RightDown" then
                winpos = client_area_offset(wh)
                avrect = {
                    winpos[1] + evdata[1],
                    winpos[2] + evdata[2],
                    winpos[1] + evdata[1] + 1,
                    winpos[2] + evdata[2] + 1
                }

                if in_rect(evdata[1], evdata[2], trect) then     
                    wcprops[wcpMenuID][idx] = 0
                    oswin:close_all_popups("6")
                    
                    wcprops[wcpMenuID][idx] = widget_create(widget_get_name(wid) & ".mnuContext", wid, "menu", {
                        {"title", "Edit"},
                        {"items", {"Cut", "Copy", "Paste", "-", "Delete", "-", "Select All"}},
                        {"avoid", avrect & 1},
                        {"pin", 0},
                        {"root", wid}
                    })
                end if
                
            case "RightUp" then
                if wcprops[wcpMenuID][idx] > 0 then
                    widget:wc_call_event(wcprops[wcpMenuID][idx], "unpressed", wid)
                end if
                --doredraw = 1
                
            case "WheelMove" then
                if wcprops[wcpSoftFocus][idx] > 0 then
                    wc_call_command(wcprops[wcpScrollV][idx], "set_value_rel", -evdata[2]*wcprops[wcpLineHeight][idx]*4)
                end if    
                
            case "KeyDown" then
                if wcprops[wcpKeyFocus][idx] then
                    if evdata[1] = 16 then --shift
                        wcprops[wcpKeyShift][idx] = 1
                    elsif evdata[1] = 17 then --ctrl
                        wcprops[wcpKeyCtrl][idx] = 1
                    elsif evdata[1] = 18 then --alt
                        wcprops[wcpKeyAlt][idx] = 1
                    elsif evdata[1] = 92 then --win
                    end if
                    
                    if evdata[1] = 37 then --left
                        move_cursor(idx, wh, -1, 0)
                    elsif evdata[1] = 39 then --right
                        move_cursor(idx, wh, 1, 0)
                    elsif evdata[1] = 38 then --up
                        move_cursor(idx, wh, 0, -1)
                    elsif evdata[1] = 40 then --down
                        move_cursor(idx, wh, 0, 1)
                    elsif evdata[1] = 33 then --pgup
                        
                    elsif evdata[1] = 34 then --pgdown
                        
                    elsif evdata[1] = 36 then --home
                        move_cursor(idx, wh, -2, 0)
                    elsif evdata[1] = 35 then --end
                        move_cursor(idx, wh, 2, 0)
                    elsif evdata[1] = 8 then
                        if wcprops[wcpOptLocked][idx] = 0 and enabled then --backspace
                            --if wcprops[wcpSelStartLine][idx] = wcprops[wcpSelEndLine][idx] and wcprops[wcpSelStartCol][idx] = wcprops[wcpSelEndCol][idx] then
                            --    move_cursor(idx, wh, -1, 0)
                            --else
                            --end if
                            delete_selection(idx, wh, 1)
                        end if
                        
                    elsif evdata[1] = 45 then
                        if wcprops[wcpKeyShift][idx] = 0 and wcprops[wcpKeyCtrl][idx] = 1 and wcprops[wcpKeyAlt][idx] = 0 then --ctrl
                            cbaction = "Copy"
                        elsif wcprops[wcpKeyShift][idx] = 1 and wcprops[wcpKeyCtrl][idx] = 0 and wcprops[wcpKeyAlt][idx] = 0 then --shift
                            if wcprops[wcpOptLocked][idx] = 0 and enabled then --insert
                                cbaction = "Paste"
                            end if
                        end if
                        
                    elsif evdata[1] = 46 then
                        if wcprops[wcpOptLocked][idx] = 0 and enabled then --delete
                            if wcprops[wcpKeyShift][idx] = 1 and wcprops[wcpKeyCtrl][idx] = 0 and wcprops[wcpKeyAlt][idx] = 0 then --shift
                                cbaction = "Cut"
                            else
                                delete_selection(idx, wh)
                            end if
                        end if
                        
                    end if
                    keep_cursor_in_view(idx, trect)
                    
                    wcprops[wcpCursorState][idx] = 3
                    doredraw = 1
                    wc_call_event(wid, "changed", {})
                end if
                
            case "KeyUp" then
                if wcprops[wcpKeyFocus][idx] then
                    if evdata[1] = 16 then --shift
                        wcprops[wcpKeyShift][idx] = 0
                    elsif evdata[1] = 17 then --ctrl
                        wcprops[wcpKeyCtrl][idx] = 0
                    elsif evdata[1] = 18 then --alt
                        wcprops[wcpKeyAlt][idx] = 0
                    elsif evdata[1] = 92 then --win
                    end if
                end if
                
            case "KeyPress" then
                if wcprops[wcpKeyFocus][idx] then
                    if wcprops[wcpKeyShift][idx] = 0 and wcprops[wcpKeyCtrl][idx] = 1 and wcprops[wcpKeyAlt][idx] = 0 then --ctrl
                        if evdata[1] + 96 = 'x' then
                            if wcprops[wcpOptLocked][idx] = 0 and enabled then --copy
                                cbaction = "Cut"
                            end if
                            
                        elsif evdata[1] + 96 = 'c' then --copy
                            cbaction = "Copy"
                            
                        elsif evdata[1] + 96 = 'v' then
                            if wcprops[wcpOptLocked][idx] = 0 and enabled then --paste
                                cbaction = "Paste"
                            end if
                            
                        elsif evdata[1] + 96 = 'a' then
                            cbaction = "Select All"
                        end if
                        
                    elsif evdata[1] = 13 then --newline
                        if equal(wcprops[wcpOptMode][idx], "text") and wcprops[wcpOptAllowNewline][idx] then
                            if wcprops[wcpOptLocked][idx] = 0 and enabled then
                                if wcprops[wcpSelStartLine][idx] != wcprops[wcpSelEndLine][idx] or wcprops[wcpSelStartCol][idx] != wcprops[wcpSelEndCol][idx] then
                                    delete_selection(idx, wh)
                                end if
                                insert_txt(idx, wh, {10})
                                move_cursor(idx, wh, 1, 0)
                            end if
                            --widget:wc_send_event(widget_get_name(wid), "enter", wcprops[wcpTextLinesLength][idx]) --why?
                        else
                            widget:wc_send_event(widget_get_name(wid), "Enter", wcprops[wcpText][idx][1])
                        end if
                        
                    elsif evdata[1] > 13 then
                        if wcprops[wcpOptLocked][idx] = 0 and enabled then
                            if wcprops[wcpSelStartLine][idx] = wcprops[wcpSelEndLine][idx] and wcprops[wcpSelStartCol][idx] = wcprops[wcpSelEndCol][idx] then
                                --if OverwriteMode = 1 then --if in over-write mode, delete character before inserting character
                                --    delete_selection(idx, wh)
                                --end if
                            else
                                delete_selection(idx, wh)
                            end if
                            insert_txt(idx, wh, {evdata[1]})
                            move_cursor(idx, wh, 1, 0)
                        end if
                    end if
                    
                    keep_cursor_in_view(idx, trect)
                    
                    wcprops[wcpCursorState][idx] = 3
                    doredraw = 1
                    wc_call_event(wid, "changed", {})
                end if
                
            case "Timer" then
                if wcprops[wcpKeyFocus][idx] and evdata[1] = 3 and wcprops[wcpOptLocked][idx] = 0 and enabled then
                    if wcprops[wcpCursorState][idx] > 0 then
                        wcprops[wcpCursorState][idx] -= 1
                    else
                        wcprops[wcpCursorState][idx] = 1
                    end if
                    doredraw = 1
                end if
                
            case "scroll" then
                if evdata[1] = wcprops[wcpScrollV][idx] then
                     wcprops[wcpScrollPosY][idx] = evdata[2]
                     doredraw = 1
                elsif evdata[1] = wcprops[wcpScrollH][idx] then
                     wcprops[wcpScrollPosX][idx] = evdata[2]
                     doredraw = 1
                end if  
                
            case "changed" then
                update_content_size(wid)
                check_scrollbars(idx, wid)
                doredraw = 1
                keep_cursor_in_view(idx, trect)
                widget:wc_send_event(widget_get_name(wid), "changed", {})
                
            case "MenuClosed" then
                wcprops[wcpMenuID][idx] = 0
                
            case "MenuItemClicked" then            
                if evdata[1] > 0 and evdata[1] = wcprops[wcpMenuID][idx] then
                    cbaction = evdata[2]
                    oswin:close_all_popups("textedit")
                end if
                
            case "LostFocus" then
                wcprops[wcpSoftFocus][idx] = 0
                doredraw = 1
                
            case "KeyFocus" then
                if evdata = wid then
                    if wcprops[wcpKeyFocus][idx] = 0 then
                        wcprops[wcpKeyFocus][idx] = 1
                        widget:wc_send_event(widget_get_name(wid), "KeyFocus", 1)
                        doredraw = 1
                    end if
                else
                    if wcprops[wcpKeyFocus][idx] = 1 then
                        wcprops[wcpKeyFocus][idx] = 0
                        widget:wc_send_event(widget_get_name(wid), "KeyFocus", 0)
                        doredraw = 1
                    end if
                end if
                
            case "Visible" then
                widget:wc_send_event(widget_get_name(wid), "Visible", evdata)
                
                if evdata = 0 then
                    --wcprops[wcpKeyFocus][idx] = 0
                elsif evdata = 1 and wcprops[wcpAutoFocus][idx] then
                    --puts(1, "AutoFocus(" & widget_get_name(wid) & ") = " & sprint(evdata) & "\n")
                    widget:set_key_focus(wid)
                end if
                
            case "SetEnabled" then
                doredraw = 1
        end switch
        
        if length(cbaction) > 0 then
            switch cbaction do 
            case "Cut" then
                if wcprops[wcpOptLocked][idx] = 0 and enabled then 
                    if wcprops[wcpSelStartLine][idx] = wcprops[wcpSelEndLine][idx] and wcprops[wcpSelStartCol][idx] = wcprops[wcpSelEndCol][idx] then
                    else
                        clipboard_write_txt(wh, get_selected_text(idx, wh))
                        delete_selection(idx, wh)
                        keep_cursor_in_view(idx, trect)
                        wcprops[wcpCursorState][idx] = 3
                        doredraw = 1
                        wc_call_event(wid, "changed", {}) 
                    end if
                end if
                
            case "Copy" then
                if wcprops[wcpSelStartLine][idx] = wcprops[wcpSelEndLine][idx] and wcprops[wcpSelStartCol][idx] = wcprops[wcpSelEndCol][idx] then
                else
                    clipboard_write_txt(wh, get_selected_text(idx, wh))
                end if
                
            case "Paste" then
                if wcprops[wcpOptLocked][idx] = 0 and enabled then 
                    if wcprops[wcpSelStartLine][idx] = wcprops[wcpSelEndLine][idx] and wcprops[wcpSelStartCol][idx] = wcprops[wcpSelEndCol][idx] then
                    else
                        delete_selection(idx, wh)
                    end if
                    insert_txt(idx, wh, clipboard_read_txt(wh))
                    keep_cursor_in_view(idx, trect)
                    wcprops[wcpCursorState][idx] = 3
                    doredraw = 1
                    wc_call_event(wid, "changed", {})
                end if
                
            case "Delete" then
                if wcprops[wcpOptLocked][idx] = 0 and enabled then 
                    if wcprops[wcpSelStartLine][idx] = wcprops[wcpSelEndLine][idx] and wcprops[wcpSelStartCol][idx] = wcprops[wcpSelEndCol][idx] then
                    else
                        delete_selection(idx, wh)
                        keep_cursor_in_view(idx, trect)
                        wcprops[wcpCursorState][idx] = 3
                        doredraw = 1
                        wc_call_event(wid, "changed", {})
                    end if
                end if
                
            case "Undo" then
                
            case "Redo" then
                
            case "Select All" then
                atom
                sStartLine = 1,
                sStartCol = 0,
                sEndLine = length(wcprops[wcpTextLinesLength][idx]),
                sEndCol = wcprops[wcpTextLinesLength][idx][sEndLine]
                
                if wcprops[wcpOptSameWidth][idx] then
                    oswin:set_font(wh, thMonoFont, 9, Normal)
                else
                    oswin:set_font(wh, thNormalFont, 9, Normal)
                end if
                wcprops[wcpIsSelecting][idx] = 0
                wcprops[wcpSelStartLine][idx] = sStartLine
                wcprops[wcpSelStartCol][idx] = sStartCol
                wcprops[wcpSelStartX][idx] = 0
                wcprops[wcpSelEndLine][idx] = sEndLine
                wcprops[wcpSelEndCol][idx] = sEndCol
                wcprops[wcpSelEndX][idx] = get_text_width(wh, rawtext(idx, sEndLine, 1, sEndCol))
                
                doredraw = 1
                
            end switch
        end if
        
        if doredraw then
            /*pretty_print(1, 
                {wcprops[wcpSelStartLine][idx],
                wcprops[wcpSelStartCol][idx],
                wcprops[wcpSelStartX][idx],
                wcprops[wcpSelEndLine][idx],
                wcprops[wcpSelEndCol][idx],
                wcprops[wcpSelEndX][idx]}, {2}
            )*/
            wc_call_draw(wid)
        end if
        
    end if
end procedure


procedure wc_resize(atom wid)
    atom idx, wh, wparent
    sequence wsize, txex, lpos, trect
    object sprect    
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wh = widget_get_handle(wid)
        
        if equal(wcprops[wcpOptMode][idx], "text") then
            --label:
            oswin:set_font(wh, thNormalFont, 9, Normal)
            txex = oswin:get_text_extent(wh, wcprops[wcpLabel][idx])
            wsize = {txex[1] + 6, txex[2] + 6 + 30}
            
            widget:widget_set_min_size(wid, wsize[1] + 6, wsize[2])
            widget:widget_set_natural_size(wid, 0, 0)
    
            wparent = parent_of(wid)
            if wparent > 0 then
                if equal(widget_get_class(wparent), "container") then
                    widget:wc_call_event(wparent, "setboxwidth", {wid, txex[1]})
                end if
                wc_call_resize(wparent)
            end if
            rebuild_text_lines(idx, wh)
            update_content_size(wid)
            check_scrollbars(idx, wid)
            
        else  --{"number", "string", "item", "datetime", "password"}
            --label:
            oswin:set_font(wh, "Arial", 9, Normal)
            txex = oswin:get_text_extent(wh, wcprops[wcpLabel][idx] & ":")
            trect = {txex[1] + 5, 1, txex[1] + 5 + 30, 20}
            lpos = {3, floor((txex[2] + 6) / 2 - txex[2] / 2)}
            --text:
            /*if wcprops[wcpOptSameWidth][idx] then
                oswin:set_font(wh, "Lucida Console", 9, Normal)
            else
                oswin:set_font(wh, "Arial", 9, Normal)
            end if
            txex = oswin:get_text_extent(wh, "h")
            trect[3] += txex[1] * wcprops[wcpOptMaxChars][idx]
            */
            
            --special button:
            if wcprops[wcpOptControlVisible][idx] > 0 then
                sprect = {trect[3], trect[2], trect[3] + thSpButtonWidth, trect[4]}
                wsize = {sprect[3] + 1, trect[4] + 1}
            else
                sprect = 0
                wsize = {trect[3] + 3, trect[4] + 1}
            end if
            
            wcprops[wcpLabelPos][idx] = lpos
            --wcprops[wcpTextRect][idx] = trect
            --wcprops[wcpSpecialRect][idx] = sprect
            
            widget:widget_set_min_size(wid, wsize[1], wsize[2])
            widget:widget_set_natural_size(wid, 0, wsize[2]) 
            
            wparent = parent_of(wid)
            if wparent > 0 then
                if equal(widget_get_class(wparent), "container") then
                    widget:wc_call_event(wparent, "setboxwidth", {wid, txex[1]})
                end if
                wc_call_resize(wparent)
            end if
            rebuild_text_lines(idx, wh)
            update_content_size(wid)
            check_scrollbars(idx, wid)
        end if
    end if
end procedure


procedure wc_arrange(atom wid)
    atom idx, wh, wparent, bw
    sequence wpos, wsize, txex, trect, lpos
    object sprect
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wpos = widget_get_pos(wid)
        wsize = widget_get_size(wid)
        wh = widget_get_handle(wid)
        
        if equal(wcprops[wcpOptMode][idx], "text") then
            --label:
            oswin:set_font(wh, thNormalFont, 9, Normal)
            txex = oswin:get_text_extent(wh, wcprops[wcpLabel][idx])
            if wcprops[wcpLabelPosition][idx] = 1 then --label on the left side
                wparent = parent_of(wid)
                if wparent > 0 and equal(widget_get_class(wparent), "container") then
                    bw = widget:wc_call_function(wparent, "get_box_width", {})
                    if bw > 0 then
                        txex[1] = bw
                    end if
                end if
                trect = {txex[1] + 6, 3, wsize[1] - 3, wsize[2] - 3}
            else --label above
                trect = {3, txex[2] + 6, wsize[1] - 3, wsize[2] - 3}
            end if
            wcprops[wcpLabelPos][idx] = {3, 3}
            wcprops[wcpVisibleSize][idx] = {trect[3] - trect[1], trect[4] - trect[2]}
            
            if not equal(wcprops[wcpEditRect][idx], trect) then
                wcprops[wcpEditRect][idx] = trect
                check_scrollbars(idx, wid)
            end if
            
            if wcprops[wcpScrollV][idx] then
                trect[3] -= scrwidth
            end if
            if wcprops[wcpScrollH][idx] then
                trect[4] -= scrwidth
            end if
            
            if wcprops[wcpScrollV][idx] then
                widget_set_pos(wcprops[wcpScrollV][idx], wpos[1] + trect[3]+1, wpos[2] + trect[2])
                widget_set_size(wcprops[wcpScrollV][idx], scrwidth, trect[4] - trect[2] + 1)
            end if
            
            if wcprops[wcpScrollH][idx] then
                widget_set_pos(wcprops[wcpScrollH][idx], wpos[1] + trect[1]+1, wpos[2] + trect[4])
                widget_set_size(wcprops[wcpScrollH][idx], trect[3] - trect[1] + 1, scrwidth)
            end if
            
            rebuild_text_lines(idx, wh)
            update_content_size(wid)
            check_scrollbars(idx, wid)
            wc_call_draw(wid)
            
            if wcprops[wcpScrollV][idx] then
                wc_call_arrange(wcprops[wcpScrollV][idx])
            end if
            if wcprops[wcpScrollH][idx] then
                wc_call_arrange(wcprops[wcpScrollH][idx])
            end if
            
        else  --{"number", "string", "item", "datetime", "password"}
            --label:
            oswin:set_font(wh, "Arial", 9, Normal)
            txex = oswin:get_text_extent(wh, wcprops[wcpLabel][idx] & ":")
            
            wparent = parent_of(wid)
            if wparent > 0 and equal(widget_get_class(wparent), "container") then
                bw = widget:wc_call_function(wparent, "get_box_width", {})
                if bw > 0 then
                    txex[1] = bw
                end if
            end if
            
            if wcprops[wcpOptControlVisible][idx] > 0 then
                trect = {txex[1] + 5, 2, wsize[1] - thSpButtonWidth - 2, wsize[2] - 1}
                --trect = {txex[1] + 5, 1, wsize[1] - thSpButtonWidth - 3, wsize[2] - 1}
                sprect = {wsize[1] - thSpButtonWidth - 2, 1, wsize[1] - 2, wsize[2] - 1}
            else
                trect = {txex[1] + 5, 2, wsize[1] - 2, wsize[2] - 1}
                --trect = {txex[1] + 5, 1, wsize[1] - 2, wsize[2] - 1}
                sprect = 0
            end if
            
            wcprops[wcpLabelPos][idx] = {3, 3}
            wcprops[wcpVisibleSize][idx] = {trect[3] - trect[1], trect[4] - trect[2]}
            wcprops[wcpEditRect][idx] = trect
            wcprops[wcpSpecialRect][idx] = sprect
            
            rebuild_text_lines(idx, wh)
            update_content_size(wid)
            check_scrollbars(idx, wid)
            wc_call_draw(wid)
        end if
    end if
end procedure


function wc_debug(atom wid)
    atom idx
    sequence debuginfo = {}
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then    
        debuginfo = {
            --{"ID", wcprops[wcpID][idx]},
            {"SoftFocus", wcprops[wcpSoftFocus][idx]},
            --{"HardFocus", wcprops[wcpHardFocus][idx]},
            {"KeyFocus", wcprops[wcpKeyFocus][idx]},
            {"AutoFocus", wcprops[wcpAutoFocus][idx]},
            {"IsSelecting", wcprops[wcpIsSelecting][idx]},
            {"Label", wcprops[wcpLabel][idx]},
            {"LabelPosition", wcprops[wcpLabelPosition][idx]},
            {"Hover", wcprops[wcpHover][idx]},
            {"CursorState", wcprops[wcpCursorState][idx]},
            {"KeyShift", wcprops[wcpKeyShift][idx]},
            {"KeyCtrl", wcprops[wcpKeyCtrl][idx]},
            {"KeyAlt", wcprops[wcpKeyAlt][idx]},
            
            {"MenuID", wcprops[wcpMenuID][idx]},
            {"SpecialRect", wcprops[wcpSpecialRect][idx]},
            {"SpecialHover", wcprops[wcpSpecialHover][idx]},
            {"SpecialPressed", wcprops[wcpSpecialPressed][idx]},
            {"SpecialWidgetID", wcprops[wcpSpecialWidgetID][idx]},
            {"SpecialMaxSize", wcprops[wcpSpecialMaxSize][idx]},
            
            {"OptMode", wcprops[wcpOptMode][idx]},
            {"OptModeOptions", wcprops[wcpOptModeOptions][idx]},
            {"OptDataFormat", wcprops[wcpOptDataFormat][idx]},
            {"OptControlVisible", wcprops[wcpOptControlVisible][idx]},
            {"OptSameWidth", wcprops[wcpOptSameWidth][idx]},
            {"OptHighlightLine", wcprops[wcpOptHighlightLine][idx]},            
            {"OptLocked", wcprops[wcpOptLocked][idx]},
            {"OptAllowNewline", wcprops[wcpOptAllowNewline][idx]},
            
            {"LineHeight", wcprops[wcpLineHeight][idx]},
            {"LabelPos", wcprops[wcpLabelPos][idx]},
            {"EditRect", wcprops[wcpEditRect][idx]},
            {"VisibleSize", wcprops[wcpVisibleSize][idx]},
            {"ContentSize", wcprops[wcpContentSize][idx]},
            {"ScrollPosX", wcprops[wcpScrollPosX][idx]},
            {"ScrollPosY", wcprops[wcpScrollPosY][idx]},
            {"ScrollV", wcprops[wcpScrollV][idx]},
            {"ScrollH", wcprops[wcpScrollH][idx]},
            
            {"SelStartLine", wcprops[wcpSelStartLine][idx]},
            {"SelStartCol", wcprops[wcpSelStartCol][idx]},
            {"SelEndLine", wcprops[wcpSelEndLine][idx]},
            {"SelEndCol", wcprops[wcpSelEndCol][idx]},
            
            {"SelStartX", wcprops[wcpSelStartX][idx]},
            {"SelEndX", wcprops[wcpSelEndX][idx]},
            
            {"Text", wcprops[wcpText][idx]},
            {"TextLinesLine", wcprops[wcpTextLinesLine][idx]},
            {"TextLinesCol", wcprops[wcpTextLinesCol][idx]},
            {"TextLinesLength", wcprops[wcpTextLinesLength][idx]},
            {"TextLinesWidth", wcprops[wcpTextLinesWidth][idx]}
        }
    end if
    return debuginfo
end function


wc_define(
    "textbox",
    routine_id("wc_create"),
    routine_id("wc_destroy"),
    routine_id("wc_draw"),
    routine_id("wc_event"),
    routine_id("wc_resize"),
    routine_id("wc_arrange"),
    routine_id("wc_debug")
)   
    

-- widgetclass commands -------------------------------------------------------

procedure cmd_clear_text(atom wid)
--Lines:{{icon1, "col1", "col2",...},{icon2, "col1", "col2"...}...}
    atom idx, wh
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wh = widget_get_handle(wid)
        
        wcprops[wcpText][idx] = {""}
        wcprops[wcpTextLinesLine][idx] = {1}
        wcprops[wcpTextLinesCol][idx] = {0}
        wcprops[wcpTextLinesLength][idx] = {0}
        wcprops[wcpTextLinesWidth][idx] = {0}
        
        wcprops[wcpSelStartLine][idx] = 1
        wcprops[wcpSelStartCol][idx] = 0
        wcprops[wcpSelEndLine][idx] = 1
        wcprops[wcpSelEndCol][idx] = 0
        
        move_cursor(idx, wh, -2, -2)
        
        wc_call_event(wid, "changed", {})
    end if
end procedure
wc_define_command("textbox", "clear_text", routine_id("cmd_clear_text"))


procedure cmd_set_text(atom wid, sequence txtlines)
--Lines:{{icon1, "col1", "col2",...},{icon2, "col1", "col2"...}...}
    atom idx, wh, st, len
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wh = widget:widget_get_handle(wid)
        wcprops[wcpText][idx] = {""}
        wcprops[wcpTextLinesLine][idx] = {1}
        wcprops[wcpTextLinesCol][idx] = {0}
        wcprops[wcpTextLinesLength][idx] = {0}
        wcprops[wcpTextLinesWidth][idx] = {0}
        
        wcprops[wcpSelStartLine][idx] = 1
        wcprops[wcpSelStartCol][idx] = 0
        wcprops[wcpSelEndLine][idx] = 1
        wcprops[wcpSelEndCol][idx] = 0
        
        move_cursor(idx, wh, -2, -2)
        
        insert_txt(idx, wh, txtlines)
        keep_cursor_in_view(idx, wcprops[wcpEditRect][idx])
        wcprops[wcpCursorState][idx] = 3
        --wc_call_draw(wid)
        wc_call_event(wid, "changed", {})
    
        /*wh = widget_get_handle(wid)
        if length(txtlines) > 0 then
            if atom(txtlines[1]) then --if this is an atom, it means that this is raw text, not a sequence of lines of text)
                txtlines = remove_all(13, txtlines)
                txtlines = split(txtlines, 10)
            end if
            
            --st = length(wcprops[wcpText][idx])
            --len = length(txtlines)
            
            --for i = 1 to len do
            --    wcprops[wcpText][idx][st+i] = txtlines[i]
            --end for
            --if wcprops[wcpStayAtBottom][idx] then
            --    move_cursor(idx, wh, -2, 2)
            --else
            --move_cursor(idx, wh, -2, -2)
            --end if
            
            wcprops[wcpText][idx] = {""}
            wcprops[wcpTextLinesLine][idx] = {1}
            wcprops[wcpTextLinesCol][idx] = {0}
            wcprops[wcpTextLinesLength][idx] = {0}
            wcprops[wcpTextLinesWidth][idx] = {0}
            
            wcprops[wcpSelStartLine][idx] = 1
            wcprops[wcpSelStartCol][idx] = 0
            wcprops[wcpSelEndLine][idx] = 1
            wcprops[wcpSelEndCol][idx] = 0
            
            insert_txt(idx, widget:widget_get_handle(wid), txtlines)
            update_content_size(wid)
            
            wc_call_event(wid, "changed", {})
        else
            wcprops[wcpText][idx] = {""}
            wcprops[wcpTextLinesLine][idx] = {1}
            wcprops[wcpTextLinesCol][idx] = {0}
            wcprops[wcpTextLinesLength][idx] = {0}
            wcprops[wcpTextLinesWidth][idx] = {0}
            
            wcprops[wcpSelStartLine][idx] = 1
            wcprops[wcpSelStartCol][idx] = 0
            wcprops[wcpSelEndLine][idx] = 1
            wcprops[wcpSelEndCol][idx] = 0
            --if wcprops[wcpStayAtBottom][idx] then
            --    move_cursor(idx, wh, -2, 2)
            --else
            --move_cursor(idx, wh, -2, -2)
            --end if
            rebuild_text_lines(idx, wh)
            move_cursor(idx, wh, 0, 0)
            update_content_size(wid)
            
            wc_call_event(wid, "changed", {})
        end if*/
    end if
end procedure
wc_define_command("textbox", "set_text", routine_id("cmd_set_text"))


procedure cmd_append_text(atom wid, sequence txtlines) --Lines:{{icon1, "col1", "col2",...},{icon2, "col1", "col2"...}...}
    atom idx, wh
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wh = widget:widget_get_handle(wid)
        if atom(txtlines[1]) then --if this is an atom, it means that this is raw text, not a sequence of lines of text)
            txtlines = remove_all(13, txtlines)
            txtlines = split(txtlines, 10)
        end if
        if length(txtlines) > 0 then
            move_cursor(idx, wh, 2, 2)
            insert_txt(idx, wh, txtlines)
        end if
        move_cursor(idx, wh, 2, 2)
    end if
end procedure
wc_define_command("textbox", "append_text", routine_id("cmd_append_text"))


function cmd_get_text(atom wid)
    atom idx
    sequence txt = {}
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        if equal(wcprops[wcpOptMode][idx], "text") then
            txt = wcprops[wcpText][idx]
        else
            txt = wcprops[wcpText][idx][1]
        end if
    end if
    
    return txt
end function
wc_define_function("textbox", "get_text", routine_id("cmd_get_text"))


function cmd_get_label(atom wid)
    atom idx
    sequence txt = ""
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        txt = wcprops[wcpLabel][idx]
    end if
    
    return txt
end function
wc_define_function("textbox", "get_label", routine_id("cmd_get_label"))


procedure cmd_set_label(atom wid, sequence txt)
    atom idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wcprops[wcpLabel][idx] = txt
        wc_call_event(wid, "changed", {})
    end if
end procedure
wc_define_command("textbox", "set_label", routine_id("cmd_set_label"))


procedure cmd_select_all(atom wid)
    atom idx, wh, sStartLine, sStartCol, sEndLine, sEndCol
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wh = widget:widget_get_handle(wid)
        
        rebuild_text_lines(idx, wh)
        move_cursor(idx, wh, 0, 0)
        
        sStartLine = 1
        sStartCol = 0
        sEndLine = length(wcprops[wcpTextLinesLength][idx])
        sEndCol = wcprops[wcpTextLinesLength][idx][sEndLine]
        
        if wcprops[wcpOptSameWidth][idx] then
            oswin:set_font(wh, thMonoFont, 9, Normal)
        else
            oswin:set_font(wh, thNormalFont, 9, Normal)
        end if
        wcprops[wcpIsSelecting][idx] = 0
        wcprops[wcpSelStartLine][idx] = sStartLine
        wcprops[wcpSelStartCol][idx] = sStartCol
        wcprops[wcpSelStartX][idx] = 0
        wcprops[wcpSelEndLine][idx] = sEndLine
        wcprops[wcpSelEndCol][idx] = sEndCol
        wcprops[wcpSelEndX][idx] = get_text_width(wh, rawtext(idx, sEndLine, 1, sEndCol))
        
        wc_call_draw(wid)
    end if
end procedure
wc_define_command("textbox", "select_all", routine_id("cmd_select_all"))

