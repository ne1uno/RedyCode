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


public include gui/widgets.e as widget
public include oswin/win32/win32.e as oswin
public include gui/themes.e as th
include std/sequence.e
include std/math.e

-- Internal class variables and routines

sequence wcprops

enum
    wcpID,
    wcpSoftFocus,
    wcpHardFocus,
    wcpIsSelecting,
    wcpLabel,
    wcpLabelPosition,

    wcpLabelPos,
    wcpEditRect,
    wcpVisibleSize, --size of visible area
    wcpContentSize, --size of actual content
    wcpScrollPosX,
    wcpScrollPosY,

    wcpIndent, --indent to make room for line numbers and bookmarks
    wcpOptLineNumbers,
    wcpOptBookmarks,
    wcpOptLineFolding,
    wcpOptSameWidth,
    wcpOptLocked,
    wcpLineHeight,
    wcpStayAtBottom,
 
    wcpScrollV, --vertial scrollbar widgetid
    wcpScrollH, --horizontal scrollbar widgetid
    
    wcpHover,

    wcpMenuID,
     
    wcpTextLine,
    wcpTextLineWidths,
    --wcpTextLineFormatted,
    --wcpTextLineBookmarked,
    
    wcpSelStartLine,
    wcpSelStartCol,
    wcpSelEndLine,
    wcpSelEndCol,
    
    wcpSelStartX,
    wcpSelEndX,
    
    wcpCursorState
    
constant wcpLENGTH = wcpCursorState

wcprops = repeat({}, wcpLENGTH)


-- Theme variables -------------------------------
atom headingheight = 16, thCurrLineBkColor = rgb(255, 255, 200)
constant
thMonoFont = "DejaVu Sans Mono",
thNormalFont = "Arial",
thLineNumberWidth = 40,
thBookmarkWidth = 16,
thLineFoldingWidth = 16


-- local routines ---------------------------------------------------------------------------

function get_line_width(atom idx, atom wh, atom cLine)
    if idx > 0 and cLine > 0 and cLine <= length(wcprops[wcpTextLineWidths][idx]) then
        if wcprops[wcpTextLineWidths][idx][cLine] = 0 then
            if length(wcprops[wcpTextLine][idx][cLine]) = 0 then
                wcprops[wcpTextLineWidths][idx][cLine] = 6
            else
                wcprops[wcpTextLineWidths][idx][cLine] = get_text_width(wh, wcprops[wcpTextLine][idx][cLine])
            end if
        end if
        return wcprops[wcpTextLineWidths][idx][cLine]
    end if
    return 0
end function



function get_line_under_pos(atom wid, atom xpos, atom ypos)
    sequence  wrect, trect, itexts, iformats, ibookmarked, iconlist
    atom idx, scry, indent, numbered, ih, yp, cLine = 1
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wrect = widget_get_rect(wid)
        trect = wcprops[wcpEditRect][idx]
        trect[2] += wrect[2]
        
        indent = wcprops[wcpIndent][idx]
        numbered = wcprops[wcpOptLineNumbers][idx]
        ih = wcprops[wcpLineHeight][idx]

        itexts = wcprops[wcpTextLine][idx]
        --iformats = wcprops[wcpTextLineFormatted][idx]
        --ibookmarked = wcprops[wcpTextLineBookmarked][idx]
        
        scry = floor(wcprops[wcpScrollPosY][idx])
        yp = trect[2] - scry + ih * length(itexts)
        
        cLine = length(itexts)
        for li = length(itexts) to 1 by -1 do
            if ypos < yp then
                cLine = li
            end if
            yp -= ih
        end for
    end if
    
    return cLine
end function

function locate_cursor(atom idx, atom wh, atom xpos, atom cLine)
    atom len, mcol, scrx, indent
    sequence cc
    len = length(wcprops[wcpTextLine][idx][cLine])
    scrx = floor(wcprops[wcpScrollPosX][idx])
    mcol = len

    indent = wcprops[wcpIndent][idx]

    if wcprops[wcpOptSameWidth][idx] then
        oswin:set_font(wh, thMonoFont, 9, Normal)
    else
        oswin:set_font(wh, thNormalFont, 9, Normal)
    end if
    
    --find which column the mouse is on
    for p = 1 to len do
        cc = indent + oswin:get_text_extent(wh, wcprops[wcpTextLine][idx][cLine][1..p])
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
    
    if relline = -2 then
        wcprops[wcpSelStartLine][idx] = 1
    elsif relline = -1 then
        wcprops[wcpSelStartLine][idx] -= 1
    elsif relline = 0 then
        --do nothing
    elsif relline = 1 then
        wcprops[wcpSelStartLine][idx] += 1
    elsif relline = 2 then
        wcprops[wcpSelStartLine][idx] = length(wcprops[wcpTextLine][idx])
    end if
    
    if wcprops[wcpSelStartLine][idx] < 1 then
        wcprops[wcpSelStartLine][idx] = 1
        wcprops[wcpSelStartCol][idx] = 0
    elsif wcprops[wcpSelStartLine][idx] > length(wcprops[wcpTextLine][idx]) then
        wcprops[wcpSelStartLine][idx] = length(wcprops[wcpTextLine][idx])
        wcprops[wcpSelStartCol][idx] = length(wcprops[wcpTextLine][idx][wcprops[wcpSelStartLine][idx]])
    end if

    if relcol = -2 then
        wcprops[wcpSelStartCol][idx] = 0
    elsif relcol = -1 then
        wcprops[wcpSelStartCol][idx] -= 1
    elsif relcol = 0 then
        --do nothing
    elsif relcol = 1 then
        wcprops[wcpSelStartCol][idx] += 1
    elsif relcol = 2 then
        wcprops[wcpSelStartCol][idx] = length(wcprops[wcpTextLine][idx][wcprops[wcpSelStartLine][idx]])
    end if
    
    if wcprops[wcpSelStartCol][idx] < 0 then
        wcprops[wcpSelStartLine][idx] -= 1
        if wcprops[wcpSelStartLine][idx] < 1 then
            wcprops[wcpSelStartLine][idx] = 1
            wcprops[wcpSelStartCol][idx] = 0
        else
            wcprops[wcpSelStartCol][idx] = length(wcprops[wcpTextLine][idx][wcprops[wcpSelStartLine][idx]])
        end if
    elsif wcprops[wcpSelStartCol][idx] > length(wcprops[wcpTextLine][idx][wcprops[wcpSelStartLine][idx]]) then
        wcprops[wcpSelStartLine][idx] += 1
        
        if wcprops[wcpSelStartLine][idx] > length(wcprops[wcpTextLine][idx]) then
            wcprops[wcpSelStartLine][idx] = length(wcprops[wcpTextLine][idx])
            wcprops[wcpSelStartCol][idx] = length(wcprops[wcpTextLine][idx][wcprops[wcpSelStartLine][idx]])
        else
            wcprops[wcpSelStartCol][idx] = 0
        end if
        
    end if
    
    wcprops[wcpSelStartX][idx] = get_text_width(wh, wcprops[wcpTextLine][idx][wcprops[wcpSelStartLine][idx]][1..wcprops[wcpSelStartCol][idx]])
    wcprops[wcpSelEndLine][idx] = wcprops[wcpSelStartLine][idx]
    wcprops[wcpSelEndCol][idx] = wcprops[wcpSelStartCol][idx]
    wcprops[wcpSelEndX][idx] = wcprops[wcpSelStartX][idx]
end procedure


procedure keep_cursor_in_view(atom idx, sequence trect)
    atom cx, cy

    cx = trect[1] + wcprops[wcpIndent][idx] - floor(wcprops[wcpScrollPosX][idx]) + 2 + wcprops[wcpSelStartX][idx]
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
        
        th = length(wcprops[wcpTextLine][idx]+1) * wcprops[wcpLineHeight][idx]
        vh = trect[4] - trect[2] - 1
                        
        tw = {}
        for li = 1 to length(wcprops[wcpTextLine][idx]) do
            tw &= get_line_width(idx, wh, li)  --get_text_width(wh, wcprops[wcpTextLine][idx][li])
        end for
        vw = trect[3] - trect[1] - 1
        
        wcprops[wcpContentSize][idx] = {max(tw) + scrwidth + 8, th + scrwidth}
    end if
    
end procedure


procedure check_scrollbars(atom idx, atom wid) --check contents and size of widget to determine if scrollbars are needed, then create or destroy scrollbars when required. 
    sequence wpos, wsize, trect = {}
    atom th, vh, setsize = 0

        
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
        if wcprops[wcpStayAtBottom][idx] then
            wc_call_command(wcprops[wcpScrollV][idx], "set_value", th)
        else
            wc_call_command(wcprops[wcpScrollV][idx], "set_value", wcprops[wcpScrollPosY][idx])
        end if
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
end procedure


-- widgetclass handlers ----------------------------

procedure wc_create(atom wid, object wprops) 
    atom orientation = 0, smx = 0, smy = 0, wparent, wh, optLineNumbers = 0, optBookmarks = 0, optLineFolding = 0,
     optSameWidth = 0, optLocked = 0, wlabelpos = 0, stayatbottom = 0
    sequence wpos, wsize, wlabel = "", wtext = {""}, txex, lpos, trect
    object sprect
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do         
                case "label" then
                    wlabel = wprops[p][2]
                case "label_position" then
                    if equal("side", wprops[p][2]) then
                        wlabelpos = 1
                    end if
                    
                case "stay_at_bottom" then
                    stayatbottom = wprops[p][2]
                case "text" then
                    wtext = wprops[p][2]
                    
                    if length(wtext) > 0 then
                        if atom(wtext[1]) then --if this is an atom, it means that this is raw text, not a sequence of lines of text)
                            wtext = remove_all(13, wtext)
                            wtext = split(wtext, 10)
                        end if
                    end if
                case "monowidth" then
                    optSameWidth = wprops[p][2]
                case "locked" then
                    optLocked = wprops[p][2]
                case "line_numbers" then
                    optLineNumbers = 1
                case "bookmarks" then
                    optLineNumbers = 1
                case "line_folding" then
                    optLineNumbers = 1
            end switch
        end if
    end for
           
    wcprops[wcpID] &= {wid}
    wcprops[wcpSoftFocus] &= {0}
    wcprops[wcpHardFocus] &= {0}
    
    wcprops[wcpIsSelecting] &= {0}
    wcprops[wcpCursorState] &= {0}
    
    wcprops[wcpLabel] &= {wlabel}    
    wcprops[wcpLabelPosition] &= {wlabelpos}

    wcprops[wcpLabelPos] &= {{0, 0}}
    wcprops[wcpEditRect] &= {{0, 0, 0, 0}}
    wcprops[wcpVisibleSize] &= {{0, 0}}
    wcprops[wcpContentSize] &= {{0, 0}}
    wcprops[wcpScrollPosX] &= {0}
    wcprops[wcpScrollPosY] &= {0}

    wcprops[wcpScrollV] &= {0}
    wcprops[wcpScrollH] &= {0}
    
    wcprops[wcpIndent] &= {thLineNumberWidth * optLineNumbers + thBookmarkWidth * optBookmarks + thLineFoldingWidth * optLineFolding}
    wcprops[wcpOptLineNumbers] &= {optLineNumbers}
    wcprops[wcpOptBookmarks] &= {optBookmarks}
    wcprops[wcpOptLineFolding] &= {optLineFolding}
    wcprops[wcpOptSameWidth] &= {optSameWidth}
    wcprops[wcpOptLocked] &= {optLocked}
    wcprops[wcpLineHeight] &= {16}
    wcprops[wcpStayAtBottom] &= {stayatbottom}

    wcprops[wcpHover] &= {0}
    
    wcprops[wcpMenuID] &= {0}

    wcprops[wcpTextLine] &= {wtext}
    wcprops[wcpTextLineWidths] &= {repeat(0, length(wtext))}
    --wcprops[wcpTextLineFormatted] &= {{}}
    --wcprops[wcpTextLineBookmarked] &= {{}} 
    
    wcprops[wcpSelStartLine] &= {1}
    wcprops[wcpSelStartCol] &= {0}
    wcprops[wcpSelEndLine] &= {1}
    wcprops[wcpSelEndCol] &= {0}
  
    wcprops[wcpSelStartX] &= {0}
    wcprops[wcpSelEndX] &= {0}
    wcprops[wcpCursorState] &= {0}

    
    update_content_size(wid)
    
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
    sequence cmds, wrect, chwid, txex, txpos, trect, irect
    atom idx, wh, wf, hlcolor, shcolor, fillcolor, txtcolor, txtselcolor, txtselhicolor, hicolor, txtbkcolor
    atom sStartLine, sStartCol, sStartX, sEndLine, sEndCol, sEndX
    atom indent, numbered, ih, xp, yp, ss
    sequence itexts, iformats, ibookmarked
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

        if wcprops[wcpHardFocus][idx] and wf then
            hicolor = th:cOuterActive
            txtselcolor = th:cInnerTextSel
            txtselhicolor = th:cInnerSel
        elsif wcprops[wcpSoftFocus][idx] then
            hicolor = th:cOuterHover
        else
            hicolor = th:cOuterFill
        end if
        
        shcolor = th:cButtonShadow
        hlcolor = th:cButtonHighlight

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
            {DR_TextColor, cOuterLabel},
            {DR_PenPos} & txpos,
            {DR_Puts, wcprops[wcpLabel][idx]},
            
        --text border:
            {DR_PenColor, shcolor},
            {DR_Line, trect[1], trect[2], trect[3], trect[2]},
            {DR_Line, trect[1], trect[2], trect[1], trect[4]},
            
            {DR_PenColor, hlcolor},
            
            {DR_Line, trect[3], trect[2] + 1, trect[3], trect[4]},
            {DR_Line, trect[1], trect[4], trect[3], trect[4]}
        }
        
        indent = wcprops[wcpIndent][idx]
        ih = wcprops[wcpLineHeight][idx]
         
        itexts = wcprops[wcpTextLine][idx]
        --iformats = wcprops[wcpTextLineFormatted][idx]
        --ibookmarked = wcprops[wcpTextLineBookmarked][idx]
        
        scrx = floor(wcprops[wcpScrollPosX][idx])
        scry = floor(wcprops[wcpScrollPosY][idx])
        
        --selection = wcprops[wcpSelection][idx]
        hover = wcprops[wcpHover][idx]
        
        xp = trect[1] + indent
        yp = trect[2]
        
--Bookmarks, Line Folding, and Line Numbers:
        cmds &= {
            {DR_Restrict} & trect, --restrict drawing to list area
            {DR_PenColor, th:cButtonFace},
            {DR_Rectangle, True, trect[1], trect[2], trect[3], trect[4]},
            {DR_TextColor, cButtonLabel},
            {DR_Font, thMonoFont, 9, Normal}
        }
        
        for li = 1 to length(itexts) do                      
            if yp - scry > trect[2] - ih and yp - scry - ih < trect[4] then
                --if wcprops[wcpOptBookmarks][idx] then
                --if wcprops[wcpOptLineFolding][idx] then
                if wcprops[wcpOptLineNumbers][idx] then
                    cmds &= {
                        {DR_PenPos, trect[1] + 4, yp - scry + 0},
                        {DR_Puts, sprintf("%d", {li})}
                    }
                end if
            end if
            yp += ih
        end for
         
--Text Lines:
        xp = trect[1] + indent
        yp = trect[2]
        
        cmds &= {
            {DR_Release},
            {DR_Restrict, xp, yp, trect[3], trect[4]},
            {DR_PenColor, th:cInnerFill},
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
                     
        for li = 1 to length(itexts) do                      
            if yp - scry > trect[2] - ih and yp - scry - ih < trect[4] then
                if li = sStartLine then
                    cmds &= {
                        {DR_PenColor, thCurrLineBkColor},
                        {DR_Rectangle, True,
                            xp - scrx + 2, yp - scry,
                            trect[3], yp - scry + ih
                        }
                    }
                end if
                
                --selection:
                if li < sStartLine or li > sEndLine then      --draw a line of normal text only
                    cmds &= {
                        {DR_TextColor, th:cInnerText},
                        {DR_PenPos, xp - scrx + 2, yp - scry + 0},
                        {DR_Puts, itexts[li]}
                    }
                elsif li = sStartLine and li = sEndLine then  --draw a line of normal text first, then...
                    cmds &= {
                        {DR_TextColor, th:cInnerText},
                        {DR_PenPos, xp - scrx + 2, yp - scry + 0},
                        {DR_Puts, itexts[li]}
                    }
                    if sStartCol != sEndCol then              --...draw selected text from start to end
                        cmds &= {
                            {DR_PenColor, txtselhicolor},
                            {DR_Rectangle, True,
                                xp - scrx + 2 + sStartX, yp - scry,
                                xp - scrx + 2 + sEndX, yp - scry + ih
                            },
                            {DR_TextColor, txtselcolor},
                            {DR_PenPos,  xp - scrx + 2 + sStartX, yp - scry + 0},
                            {DR_Puts, itexts[li][sStartCol+1..sEndCol]}
                        }
                    else  --temporary: draw non-blinking cursor
                        cmds &= { 
                            {DR_PenColor, th:cInnerDark},
                            {DR_Line,
                                xp - scrx + 2 + sStartX, yp - scry,
                                xp - scrx + 2 + sStartX, yp - scry + ih}
                        }
                    end if
                elsif li = sStartLine and li < sEndLine then  --draw selected text from start
                    cmds &= { 
                        {DR_TextColor, th:cInnerText},
                        {DR_PenPos, xp - scrx + 2, yp - scry + 0},
                        {DR_Puts, itexts[li][1..sStartCol]},
                        --draw selected text:
                        {DR_PenColor, txtselhicolor},
                        {DR_Rectangle, True,
                            xp - scrx + 2 + sStartX, yp - scry,
                            xp - scrx + 2 + get_line_width(idx, wh, li), yp - scry + ih
                            --xp - scrx + 2 + get_text_width(wh, wcprops[wcpTextLine][idx][li]), yp - scry + ih
                        },
                        {DR_TextColor, txtselcolor},
                        {DR_PenPos,  xp - scrx + 2 + sStartX, yp - scry + 0},
                        {DR_Puts, itexts[li][sStartCol+1..$]}
                    }
                elsif li > sStartLine and li < sEndLine then  --draw selected text only
                    cmds &= {
                        {DR_PenColor, txtselhicolor},
                        {DR_Rectangle, True,
                            xp - scrx + 2, yp - scry,
                            xp - scrx + 2 + get_line_width(idx, wh, li), yp - scry + ih
                            --xp - scrx + 2 + get_text_width(wh, wcprops[wcpTextLine][idx][li]), yp - scry + ih
                        },
                        {DR_TextColor, txtselcolor},
                        {DR_PenPos,  xp - scrx + 2, yp - scry + 0},
                        {DR_Puts, itexts[li]}
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
                        {DR_Puts, itexts[li][1..sEndCol]},
                        --draw normal text
                        {DR_TextColor, th:cInnerText},
                        {DR_PenPos, xp - scrx + 2 + sEndX, yp - scry + 0},
                        {DR_Puts, itexts[li][sEndCol+1..$]}
                    }
                end if
            end if
            yp += ih
        end for
        
        cmds &= {
            {DR_Release}
        }
        
        draw(wh, cmds)
        
        chwid = children_of(wid)
        for ch = 1 to length(chwid) do
            wc_call_draw(chwid[ch])
        end for
    end if
end procedure


procedure wc_event(atom wid, sequence evtype, object evdata)
    sequence ampos, wrect, lpos, trect, tw, avrect, winpos, cbaction = "", txt
    atom idx, doredraw = 0, wh, ss, se, skip = 0, cLine, sStartLine, sStartCol, sEndLine, sEndCol
    atom th, vh, vw 
    
    idx = find(wid, wcprops[wcpID])

    if idx > 0 then
        wh = widget:widget_get_handle(wid)
        wrect = widget_get_rect(wid)
        --wrect[3] -= 1
        --wrect[4] -= 1
        
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
                    elsif cLine > length(wcprops[wcpTextLine][idx]) then
                        cLine = length(wcprops[wcpTextLine][idx])
                    end if
                    if wcprops[wcpOptSameWidth][idx] then
                        oswin:set_font(wh, thMonoFont, 9, Normal)
                    else
                        oswin:set_font(wh, thNormalFont, 9, Normal)
                    end if
                    wcprops[wcpSelEndLine][idx] = cLine
                    wcprops[wcpSelEndCol][idx] = locate_cursor(idx, wh, evdata[1] - trect[1], cLine)   --changed trect[1] to trect[1]
                    wcprops[wcpSelEndX][idx] = get_text_width(wh, wcprops[wcpTextLine][idx][cLine][1..wcprops[wcpSelEndCol][idx]])
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
                        elsif cLine > length(wcprops[wcpTextLine][idx]) then
                            cLine = length(wcprops[wcpTextLine][idx])
                        end if
                        wcprops[wcpSelStartLine][idx] = cLine
                        wcprops[wcpSelEndLine][idx] = cLine
                        
                        if wcprops[wcpOptSameWidth][idx] then
                            oswin:set_font(wh, thMonoFont, 9, Normal)
                        else
                            oswin:set_font(wh, thNormalFont, 9, Normal)
                        end if
                        wcprops[wcpSelStartCol][idx] = locate_cursor(idx, wh, evdata[1] - trect[1], wcprops[wcpSelStartLine][idx])  --(atom idx, atom wh, atom xpos)
                        wcprops[wcpSelStartX][idx] = get_text_width(wh, wcprops[wcpTextLine][idx][cLine][1..wcprops[wcpSelStartCol][idx]])
                        wcprops[wcpSelEndCol][idx] = wcprops[wcpSelStartCol][idx]
                        wcprops[wcpSelEndX][idx] = wcprops[wcpSelStartX][idx]
                        doredraw = 1
                    end if
                    
                    if wcprops[wcpHardFocus][idx] = 0 then
                        wcprops[wcpHardFocus][idx] = 1
                        doredraw = 1
                    end if
                else
                    if wcprops[wcpHardFocus][idx] = 1 then
                        wcprops[wcpHardFocus][idx] = 0
                        doredraw = 1
                    end if
                end if
                  
                if wcprops[wcpMenuID][idx] > 0 then
                    --widget:widget_destroy(wcprops[wcpMenuID][idx])
                    wcprops[wcpMenuID][idx] = 0
                    oswin:close_all_popups("5")
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
                --winpos[1] += 6
                --winpos[2] += 30 --temporary hack to offset client area position (need to find a more correct way that works on all windows versions/themes)
                
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
                doredraw = 1
                
            case "WheelMove" then
                if wcprops[wcpSoftFocus][idx] > 0 then
                    wc_call_command(wcprops[wcpScrollV][idx], "set_value_rel", -evdata[2]*wcprops[wcpLineHeight][idx]*4)
                end if    
            
            case "KeyDown" then
                if wcprops[wcpHardFocus][idx] then
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
                    elsif evdata[1] = 8 then --backspace
                        if sStartLine = sEndLine and sStartCol = sEndCol then --if nothing is selected, then backspace (delete character to the left of cursor)
                            if sStartCol = 0 then --beginning of line, so shift text up
                                if sStartLine > 1 then
                                    txt = wcprops[wcpTextLine][idx][sStartLine]
                                    move_cursor(idx, wh, 0, -1)
                                    move_cursor(idx, wh, 2, 0)
                                    wcprops[wcpTextLine][idx] = remove(wcprops[wcpTextLine][idx], sStartLine)
                                    wcprops[wcpTextLine][idx][sStartLine-1] &= txt
                                    wcprops[wcpTextLineWidths][idx] = remove(wcprops[wcpTextLineWidths][idx], sStartLine)
                                    wcprops[wcpTextLineWidths][idx][sStartLine-1] = 0
                                end if
                            else --middle of line, so shift text right
                                wcprops[wcpTextLine][idx][sStartLine] = wcprops[wcpTextLine][idx][sStartLine][1..sStartCol-1] & wcprops[wcpTextLine][idx][sStartLine][sStartCol+1..$]
                                wcprops[wcpTextLineWidths][idx][sStartLine] = 0
                                move_cursor(idx, wh, -1, 0)
                            end if
                        else --delete selection
                            if sStartLine = sEndLine then
                                wcprops[wcpTextLine][idx][sStartLine] = wcprops[wcpTextLine][idx][sStartLine][1..sStartCol] & wcprops[wcpTextLine][idx][sStartLine][sEndCol+1..$]
                                wcprops[wcpTextLineWidths][idx][sStartLine] = 0
                                move_cursor(idx, wh, 0, 0)
                            else
                                txt = wcprops[wcpTextLine][idx][sStartLine][1..sStartCol] & wcprops[wcpTextLine][idx][sEndLine][sEndCol+1..$]
                                wcprops[wcpTextLine][idx] = remove(wcprops[wcpTextLine][idx], sStartLine+1, sEndLine)
                                wcprops[wcpTextLine][idx][sStartLine] = txt
                                wcprops[wcpTextLineWidths][idx] = remove(wcprops[wcpTextLineWidths][idx], sStartLine+1, sEndLine)
                                wcprops[wcpTextLineWidths][idx][sStartLine] = 0
                            end if
                            move_cursor(idx, wh, 0, 0)
                        end if
                    elsif evdata[1] = 46 then --delete
                        if sStartLine = sEndLine and sStartCol = sEndCol then --if nothing is selected, then delete (delete character to the right of cursor)
                            if sStartCol = length(wcprops[wcpTextLine][idx][sStartLine]) then --end of line, so shift text up
                                if sStartLine < length(wcprops[wcpTextLine][idx]) then
                                    txt = wcprops[wcpTextLine][idx][sStartLine+1]
                                    wcprops[wcpTextLine][idx] = remove(wcprops[wcpTextLine][idx], sStartLine+1)
                                    wcprops[wcpTextLine][idx][sStartLine] &= txt
                                    wcprops[wcpTextLineWidths][idx] = remove(wcprops[wcpTextLineWidths][idx], sStartLine+1)
                                    wcprops[wcpTextLineWidths][idx][sStartLine] = 0
                                    move_cursor(idx, wh, 0, 0)
                                end if
                            else --middle of line, so shift text right
                                wcprops[wcpTextLine][idx][sStartLine] = wcprops[wcpTextLine][idx][sStartLine][1..sStartCol] & wcprops[wcpTextLine][idx][sStartLine][sStartCol+2..$]
                                wcprops[wcpTextLineWidths][idx][sStartLine] = 0
                                move_cursor(idx, wh, 0, 0)
                            end if
                        else --delete selection
                            if sStartLine = sEndLine then
                                wcprops[wcpTextLine][idx][sStartLine] = wcprops[wcpTextLine][idx][sStartLine][1..sStartCol] & wcprops[wcpTextLine][idx][sStartLine][sEndCol+1..$]
                                wcprops[wcpTextLineWidths][idx][sStartLine] = 0
                            else
                                txt = wcprops[wcpTextLine][idx][sStartLine][1..sStartCol] & wcprops[wcpTextLine][idx][sEndLine][sEndCol+1..$]
                                wcprops[wcpTextLine][idx] = remove(wcprops[wcpTextLine][idx], sStartLine+1, sEndLine)
                                wcprops[wcpTextLine][idx][sStartLine] = txt
                                wcprops[wcpTextLineWidths][idx] = remove(wcprops[wcpTextLineWidths][idx], sStartLine+1, sEndLine)
                                wcprops[wcpTextLineWidths][idx][sStartLine] = 0
                            end if
                            move_cursor(idx, wh, 0, 0)
                        end if
                    end if
                    keep_cursor_in_view(idx, trect)
                    
                    wcprops[wcpCursorState][idx] = 3
                    doredraw = 1
                    wc_call_event(wid, "changed", {})
                end if
                
            case "KeyPress" then
                if wcprops[wcpHardFocus][idx] then
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

                    if evdata[1] = 13 then --newline
                        --first, delete selection (if anything selected)
                        if sStartLine = sEndLine then
                            wcprops[wcpTextLine][idx][sStartLine] = wcprops[wcpTextLine][idx][sStartLine][1..sStartCol] & wcprops[wcpTextLine][idx][sStartLine][sEndCol+1..$]
                            wcprops[wcpTextLineWidths][idx][sStartLine] = 0
                        else
                            txt = wcprops[wcpTextLine][idx][sStartLine][1..sStartCol] & wcprops[wcpTextLine][idx][sEndLine][sEndCol+1..$]
                            wcprops[wcpTextLine][idx] = remove(wcprops[wcpTextLine][idx], sStartLine+1, sEndLine)
                            wcprops[wcpTextLine][idx][sStartLine] = txt
                            wcprops[wcpTextLineWidths][idx] = remove(wcprops[wcpTextLineWidths][idx], sStartLine+1, sEndLine)
                            wcprops[wcpTextLineWidths][idx][sStartLine] = 0
                        end if
                        move_cursor(idx, wh, 0, 0)
                        --now shift anything on the right of the cursor to the next line
                        txt = wcprops[wcpTextLine][idx][sStartLine][sStartCol+1..$]
                        wcprops[wcpTextLine][idx][sStartLine] = wcprops[wcpTextLine][idx][sStartLine][1..sStartCol]
                        wcprops[wcpTextLine][idx] = wcprops[wcpTextLine][idx][1..sStartLine] & {txt} & wcprops[wcpTextLine][idx][sStartLine+1..$]
                        wcprops[wcpTextLineWidths][idx][sStartLine] = 0
                        wcprops[wcpTextLineWidths][idx] = wcprops[wcpTextLineWidths][idx][1..sStartLine] & {0} & wcprops[wcpTextLineWidths][idx][sStartLine+1..$]
                        move_cursor(idx, wh, 1, 0)
                    elsif evdata[1] > 13 then
                        if sStartLine = sEndLine and sStartCol = sEndCol then --if nothing is selected, then insert character
                            wcprops[wcpTextLine][idx][sStartLine] = wcprops[wcpTextLine][idx][sStartLine][1..sStartCol] & evdata[1] & wcprops[wcpTextLine][idx][sStartLine][sStartCol+1..$]
                            wcprops[wcpTextLineWidths][idx][sStartLine] = 0
                            move_cursor(idx, wh, 1, 0)
                        else --delete selection
                            if sStartLine = sEndLine then
                                wcprops[wcpTextLine][idx][sStartLine] = wcprops[wcpTextLine][idx][sStartLine][1..sStartCol] & wcprops[wcpTextLine][idx][sStartLine][sEndCol+1..$]
                                wcprops[wcpTextLineWidths][idx][sStartLine] = 0
                                move_cursor(idx, wh, 0, 0)
                            else
                                txt = wcprops[wcpTextLine][idx][sStartLine][1..sStartCol] & evdata[1] & wcprops[wcpTextLine][idx][sEndLine][sEndCol+1..$]
                                wcprops[wcpTextLine][idx] = remove(wcprops[wcpTextLine][idx], sStartLine+1, sEndLine)
                                wcprops[wcpTextLine][idx][sStartLine] = txt
                                wcprops[wcpTextLineWidths][idx] = remove(wcprops[wcpTextLineWidths][idx], sStartLine+1, sEndLine)
                                wcprops[wcpTextLineWidths][idx][sStartLine] = 0
                                move_cursor(idx, wh, 1, 0)
                            end if
                        end if
                    end if
                    
                    keep_cursor_in_view(idx, trect)

                    
                    wcprops[wcpCursorState][idx] = 3
                    doredraw = 1
                    wc_call_event(wid, "changed", {})
                end if

            case "Timer" then
                if wcprops[wcpHardFocus][idx] and evdata[1] = 3 then
                    if wcprops[wcpCursorState][idx] > 0 then
                        wcprops[wcpCursorState][idx] -= 1
                    else
                        wcprops[wcpCursorState][idx] = 1
                    end if
                    --doredraw = 1
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

            case "MenuClosed" then
                wcprops[wcpMenuID][idx] = 0
                
            case "MenuItemClicked" then
                --puts(1, "Textedit: MenuItemClicked: " & evdata[2] & "\n")                
                cbaction = evdata[2]
                oswin:close_all_popups("textedit")
                
            case "LostFocus" then
                wcprops[wcpSoftFocus][idx] = 0
                doredraw = 1
                
        end switch     




        if length(cbaction) > 0 then
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

            switch cbaction do 
                case "Cut" then
                    if sStartLine = sEndLine then
                        if sStartCol != sEndCol then
                            clipboard_write_txt(wh, wcprops[wcpTextLine][idx][sStartLine][sStartCol+1..sEndCol])
                        end if
                    else
                        txt = ""
                        for li = sStartLine to sEndLine do
                            if li = sStartLine then
                                txt &= wcprops[wcpTextLine][idx][li][sStartCol+1..$] & {13, 10}
                            elsif li = sEndLine then
                                txt &= wcprops[wcpTextLine][idx][li][1..sEndCol]
                            else
                                txt &= wcprops[wcpTextLine][idx][li] & {13, 10}
                            end if
                        end for
                        clipboard_write_txt(wh, txt)
                    end if
                    --Delete selection
                    if sStartLine = sEndLine then
                        wcprops[wcpTextLine][idx][sStartLine] = wcprops[wcpTextLine][idx][sStartLine][1..sStartCol] & wcprops[wcpTextLine][idx][sStartLine][sEndCol+1..$]
                        wcprops[wcpTextLineWidths][idx][sStartLine] = 0
                    else
                        txt = wcprops[wcpTextLine][idx][sStartLine][1..sStartCol] & wcprops[wcpTextLine][idx][sEndLine][sEndCol+1..$]
                        wcprops[wcpTextLine][idx] = remove(wcprops[wcpTextLine][idx], sStartLine+1, sEndLine)
                        wcprops[wcpTextLine][idx][sStartLine] = txt
                        wcprops[wcpTextLineWidths][idx] = remove(wcprops[wcpTextLineWidths][idx], sStartLine+1, sEndLine)
                        wcprops[wcpTextLineWidths][idx][sStartLine] = 0
                    end if
                    move_cursor(idx, wh, 0, 0)
                    
                case "Copy" then
                    if sStartLine = sEndLine then
                        if sStartCol != sEndCol then
                            clipboard_write_txt(wh, wcprops[wcpTextLine][idx][sStartLine][sStartCol+1..sEndCol])
                        end if
                    else
                        txt = ""
                        for li = sStartLine to sEndLine do
                            if li = sStartLine then
                                txt &= wcprops[wcpTextLine][idx][li][sStartCol+1..$] & {13, 10}
                            elsif li = sEndLine then
                                txt &= wcprops[wcpTextLine][idx][li][1..sEndCol]
                            else
                                txt &= wcprops[wcpTextLine][idx][li] & {13, 10}
                            end if
                        end for
                        clipboard_write_txt(wh, txt)
                    end if

                case "Paste" then
                    --Delete selection
                    if sStartLine = sEndLine then
                        wcprops[wcpTextLine][idx][sStartLine] = wcprops[wcpTextLine][idx][sStartLine][1..sStartCol] & wcprops[wcpTextLine][idx][sStartLine][sEndCol+1..$]
                        wcprops[wcpTextLineWidths][idx][sStartLine] = 0
                    else
                        txt = wcprops[wcpTextLine][idx][sStartLine][1..sStartCol] & wcprops[wcpTextLine][idx][sEndLine][sEndCol+1..$]
                        wcprops[wcpTextLine][idx] = remove(wcprops[wcpTextLine][idx], sStartLine+1, sEndLine)
                        wcprops[wcpTextLine][idx][sStartLine] = txt
                        wcprops[wcpTextLineWidths][idx] = remove(wcprops[wcpTextLineWidths][idx], sStartLine+1, sEndLine)
                        wcprops[wcpTextLineWidths][idx][sStartLine] = 0
                    end if
                    move_cursor(idx, wh, 0, 0)
                    txt = remove_all(13, clipboard_read_txt(wh))
                    txt = split(txt, 10)
                    if length(txt) > 0 then
                        txt[1] = wcprops[wcpTextLine][idx][sStartLine][1..sStartCol] & txt[1] 
                        txt[$] = txt[$] & wcprops[wcpTextLine][idx][sStartLine][sStartCol+1..$]
                        --txt[$] = txt[$] & wcprops[wcpTextLine][idx][sEndLine][sEndCol+1..$]
                        wcprops[wcpTextLine][idx] = wcprops[wcpTextLine][idx][1..sStartLine-1] & txt & wcprops[wcpTextLine][idx][sStartLine+1..$]
                        wcprops[wcpTextLineWidths][idx] = wcprops[wcpTextLineWidths][idx][1..sStartLine-1] & repeat(0, length(txt)) & wcprops[wcpTextLineWidths][idx][sStartLine+1..$]
                    end if
                    
                case "Delete" then
                    --Delete selection
                    if sStartLine = sEndLine then
                        wcprops[wcpTextLine][idx][sStartLine] = wcprops[wcpTextLine][idx][sStartLine][1..sStartCol] & wcprops[wcpTextLine][idx][sStartLine][sEndCol+1..$]
                        wcprops[wcpTextLineWidths][idx][sStartLine] = 0
                    else
                        txt = wcprops[wcpTextLine][idx][sStartLine][1..sStartCol] & wcprops[wcpTextLine][idx][sEndLine][sEndCol+1..$]
                        wcprops[wcpTextLine][idx] = remove(wcprops[wcpTextLine][idx], sStartLine+1, sEndLine)
                        wcprops[wcpTextLine][idx][sStartLine] = txt
                        wcprops[wcpTextLineWidths][idx] = remove(wcprops[wcpTextLineWidths][idx], sStartLine+1, sEndLine)
                        wcprops[wcpTextLineWidths][idx][sStartLine] = 0
                    end if
                    move_cursor(idx, wh, 0, 0)
                    
                case "Undo" then
                
                case "Redo" then
                
                case "Select All" then
                
                    sStartLine = 1
                    sStartCol = 0
                    sEndLine = length(wcprops[wcpTextLine][idx])
                    sEndCol =length(wcprops[wcpTextLine][idx][sEndLine])
                    if wcprops[wcpOptSameWidth][idx] then
                        oswin:set_font(wh, thMonoFont, 9, Normal)
                    else
                        oswin:set_font(wh, thNormalFont, 9, Normal)
                    end if
                    wcprops[wcpSelStartLine][idx] = sStartLine
                    wcprops[wcpSelStartCol][idx] = sStartCol
                    wcprops[wcpSelStartX][idx] = 0
                    wcprops[wcpSelEndLine][idx] = sEndLine
                    wcprops[wcpSelEndCol][idx] = sEndCol
                    wcprops[wcpSelEndX][idx] = get_text_width(wh, wcprops[wcpTextLine][idx][sEndLine])
                    
            end switch
            wc_call_event(wid, "changed", {})
        end if
                       
        if doredraw then
            wc_call_draw(wid)
        end if
        
    end if

end procedure


procedure wc_resize(atom wid)
    atom idx, wh, wparent
    sequence wsize, txex, lpos, trect
        
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wh = widget_get_handle(wid)
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
    end if
end procedure



procedure wc_arrange(atom wid)
    atom idx, wh, wparent, bw
    sequence wpos, wsize, txex, trect
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wpos = widget_get_pos(wid)
        wsize = widget_get_size(wid)
        
        wh = widget_get_handle(wid)
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
        
        wc_call_draw(wid)
        
        if wcprops[wcpScrollV][idx] then
            wc_call_arrange(wcprops[wcpScrollV][idx])
        end if
        if wcprops[wcpScrollH][idx] then
            wc_call_arrange(wcprops[wcpScrollH][idx])
        end if
    end if
end procedure


function wc_debug(atom wid)
    atom idx
    sequence debuginfo = {}
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then    
        debuginfo = {
            {"SoftFocus", wcprops[wcpSoftFocus][idx]},
            {"HardFocus", wcprops[wcpHardFocus][idx]},
            {"IsSelecting", wcprops[wcpIsSelecting][idx]},
            {"Label", wcprops[wcpLabel][idx]},
            {"LabelPosition", wcprops[wcpLabelPosition][idx]},  
            
            {"LabelPos", wcprops[wcpLabelPos][idx]},
            {"EditRect", wcprops[wcpEditRect][idx]},
            {"VisibleSize", wcprops[wcpVisibleSize][idx]},
            {"ContentSize", wcprops[wcpContentSize][idx]},
            {"ScrollPosX", wcprops[wcpScrollPosX][idx]},
            {"ScrollPosY", wcprops[wcpScrollPosY][idx]},
            
            
            {"Indent", wcprops[wcpIndent][idx]},
            {"OptLineNumbers", wcprops[wcpOptLineNumbers][idx]},
            {"OptBookmarks", wcprops[wcpOptBookmarks][idx]},
            {"OptLineFolding", wcprops[wcpOptLineFolding][idx]},
            {"OptSameWidth", wcprops[wcpOptSameWidth][idx]},
            {"OptLocked", wcprops[wcpOptLocked][idx]},
            {"LineHeight", wcprops[wcpLineHeight][idx]},
            {"StayAtBottom", wcprops[wcpStayAtBottom][idx]},
            
            {"ScrollV", wcprops[wcpScrollV][idx]},
            {"ScrollH", wcprops[wcpScrollH][idx]},
            
            {"Hover", wcprops[wcpHover][idx]},
            
            {"MenuID", wcprops[wcpMenuID][idx]},
            
            {"TextLine", wcprops[wcpTextLine][idx]},
            {"TextLineWidths", wcprops[wcpTextLineWidths][idx]},
            --{"TextLineFormatted", wcprops[wcpTextLineFormatted][idx]},
            --{"TextLineBookmarked", wcprops[wcpTextLineBookmarked][idx]},
            
            {"SelStartLine", wcprops[wcpSelStartLine][idx]},
            {"SelStartCol", wcprops[wcpSelStartCol][idx]},
            {"SelEndLine", wcprops[wcpSelEndLine][idx]},
            {"SelEndCol", wcprops[wcpSelEndCol][idx]},
            
            {"SelStartX", wcprops[wcpSelStartX][idx]},
            {"SelEndX", wcprops[wcpSelEndX][idx]},
            
            {"CursorState", wcprops[wcpCursorState][idx]}
        }
    end if
    return debuginfo
end function



wc_define(
    "textedit",
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
        
        wcprops[wcpTextLine][idx] = {""}
        wcprops[wcpTextLineWidths][idx] = {0}
        --wcprops[wcpTextLineFormatted][idx] = {""}
        --wcprops[wcpTextLineBookmarked][idx] = {0}
    
        --wcprops[wcpSelStartLine][idx] = 1
        --wcprops[wcpSelStartCol][idx] = 0
        --wcprops[wcpSelEndLine][idx] = 1
        --wcprops[wcpSelEndCol][idx] = 0
        move_cursor(idx, wh, -2, -2)
        
        wc_call_event(wid, "changed", {})
    end if
    
end procedure
wc_define_command("textedit", "clear_text", routine_id("cmd_clear_text"))


procedure cmd_set_text(atom wid, sequence txtlines)
--Lines:{{icon1, "col1", "col2",...},{icon2, "col1", "col2"...}...}
    atom idx, wh, st, len

    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wh = widget_get_handle(wid)
        if length(txtlines) > 0 then
            if atom(txtlines[1]) then --if this is an atom, it means that this is raw text, not a sequence of lines of text)
                txtlines = remove_all(13, txtlines)
                txtlines = split(txtlines, 10)
            end if
            
            wcprops[wcpTextLine][idx] = {}
            wcprops[wcpTextLineWidths][idx] = {}
            
            
            st = length(wcprops[wcpTextLine][idx])
            len = length(txtlines)
            wcprops[wcpTextLine][idx] &= repeat({}, len)
            wcprops[wcpTextLineWidths][idx] &= repeat(0, len)
            for i = 1 to len do
                wcprops[wcpTextLine][idx][st+i] = txtlines[i]
                wcprops[wcpTextLineWidths][idx][st+i] = 0
            end for
            if wcprops[wcpStayAtBottom][idx] then
                move_cursor(idx, wh, -2, 2)
            else
                move_cursor(idx, wh, -2, -2)
            end if
            
            wc_call_event(wid, "changed", {})
        else
            wcprops[wcpTextLine][idx] = {""}
            wcprops[wcpTextLineWidths][idx] = {0}
            --wcprops[wcpTextLineFormatted][idx] = {""}
            --wcprops[wcpTextLineBookmarked][idx] = {0}
        
            --wcprops[wcpSelStartLine][idx] = 1
            --wcprops[wcpSelStartCol][idx] = 0
            --wcprops[wcpSelEndLine][idx] = 1
            --wcprops[wcpSelEndCol][idx] = 0
            if wcprops[wcpStayAtBottom][idx] then
                move_cursor(idx, wh, -2, 2)
            else
                move_cursor(idx, wh, -2, -2)
            end if
            
            wc_call_event(wid, "changed", {})
        end if
    end if
end procedure
wc_define_command("textedit", "set_text", routine_id("cmd_set_text"))


procedure cmd_append_text(atom wid, sequence txtlines) --Lines:{{icon1, "col1", "col2",...},{icon2, "col1", "col2"...}...}
    atom idx, st, len, wh
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        if length(txtlines) > 0 then
            if atom(txtlines[1]) then --if this is an atom, it means that this is raw text, not a sequence of lines of text)
                txtlines = remove_all(13, txtlines)
                txtlines = split(txtlines, 10)
            end if
            
            st = length(wcprops[wcpTextLine][idx])
            len = length(txtlines)
            wcprops[wcpTextLine][idx] &= repeat({}, len)
            wcprops[wcpTextLineWidths][idx] &= repeat(0, len)
            for i = 1 to len do
                wcprops[wcpTextLine][idx][st+i] = txtlines[i]
                wcprops[wcpTextLineWidths][idx][st+i] = 0
                --wcprops[wcpTextLineFormatted][idx] &= {txtlines[i]}
                --wcprops[wcpTextLineBookmarked][idx] &= {0}
            end for
            if wcprops[wcpStayAtBottom][idx] then
                wh = widget_get_handle(wid)
                move_cursor(idx, wh, -2, 2)
            end if
            wc_call_event(wid, "changed", {})
        end if
    end if
end procedure
wc_define_command("textedit", "append_text", routine_id("cmd_append_text"))


function cmd_get_text(atom wid)
    atom idx
    sequence txt = {}

    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        txt = wcprops[wcpTextLine][idx]
    end if
    
    return txt
end function
wc_define_function("textedit", "get_text", routine_id("cmd_get_text"))

