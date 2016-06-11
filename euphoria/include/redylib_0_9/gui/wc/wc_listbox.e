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



public include redylib_0_9/gui/widgets.e as widget
public include redylib_0_9/oswin.e as oswin
public include redylib_0_9/gui/themes.e as th

include std/sequence.e
include std/math.e

-- Internal class variables and routines

sequence wcprops

enum
    wcpID,
    wcpSoftFocus,
    wcpHardFocus,
    wcpKeyFocus,
    wcpIsSelecting,
    wcpOptLabelPos,  --0=left side, 1=above
    wcpOptStripes,
    wcpStayAtBottom,
    wcpLabel,

    wcpLabelPos,
    wcpListRect,
    wcpVisibleSize, --size of visible area
    wcpContentSize, --size of actual content
    wcpScrollPosX,
    wcpScrollPosY,
    wcpIndent, --indent to make room for icon
    wcpCheckBoxes,
    wcpNumbered,
    wcpItemHeight,
    
    wcpMultiSelect,
    
    wcpColumnLabels,
    wcpColumWidths,   
    
    wcpIconList, --sequence of icon pointers
    
    wcpSortColumns,
    wcpSortDirection,
 
    wcpScrollV, --vertial scrollbar widgetid
    wcpScrollH, --horizontal scrollbar widgetid
    
    wcpSelStart,
    wcpSelection,
    wcpHover,
     
    --wcpItemIDs, --unique id for each item (not used for now)
    wcpItemText, --text for each item or seqeunce of strings for multiple columns
    wcpItemIcons, --icon id for each item
    wcpItemSelected


    
constant wcpLENGTH = wcpItemSelected

wcprops = repeat({}, wcpLENGTH)


-- Theme variables -------------------------------

atom stripe = 1, headingheight = 18, iconsize = 16

-- local routines ---------------------------------------------------------------------------


procedure send_selection_event(atom idx, sequence wname, sequence sel)
    sequence itms = {}
    
    for i = 1 to length(sel) do
        if sel[i] > 0 and sel[i] <= length(wcprops[wcpItemText][idx]) then
            itms &= {{
                sel[i],  --wcprops[wcpItemIDs][idx][sel[i]],
                wcprops[wcpItemText][idx][sel[i]]
                --wcprops[wcpItemIcons][idx][sel[i]]
            }}
        end if
    end for
    widget:wc_send_event(wname, "selection", itms)
end procedure


procedure send_double_click_event(atom idx, sequence wname, sequence sel)
    sequence itms = {}
    
    for i = 1 to length(sel) do
        if sel[i] > 0 and sel[i] <= length(wcprops[wcpItemText][idx]) then
            itms &= {{
                sel[i],
                wcprops[wcpItemText][idx][sel[i]]
            }}
        end if
    end for
    widget:wc_send_event(wname, "left_double_click", itms)
end procedure


procedure send_keypress_event(atom idx, sequence wname, atom keycode)
    widget:wc_send_event(wname, "KeyPress", keycode)
end procedure


procedure show_context_menu(atom idx, sequence wname, sequence sel)
    
end procedure


function get_item_under_pos(atom wid, atom xpos, atom ypos)
    sequence cmds, wrect, chwid, txex, txpos, lrect, lpos, irect
    atom idx, hlcolor, shcolor, fillcolor, txtcolor, hicolor
    atom indent, checkbox, numbered, ih, xp, yp, ss, citem = 0
    sequence clabels, cwidths, csort, sortdir, itexts, iicons, iselected
    atom scry,scrx
    sequence iconlist
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wrect = widget_get_rect(wid)
        wrect[3] -= 1
        wrect[4] -= 1
        lpos = wcprops[wcpLabelPos][idx]
        lrect = wcprops[wcpListRect][idx]
        lpos[1] += wrect[1]
        lpos[2] += wrect[2]
        lrect[1] += wrect[1]
        lrect[2] += wrect[2]
        lrect[3] += wrect[1]
        lrect[4] += wrect[2]

        indent = wcprops[wcpIndent][idx]
        --checkbox = wcprops[wcpCheckBoxes][idx]
        --numbered = wcprops[wcpNumbered][idx]
        ih = wcprops[wcpItemHeight][idx]

        clabels = wcprops[wcpColumnLabels][idx]
        cwidths = wcprops[wcpColumWidths][idx]
        --csort = wcprops[wcpSortColumns][idx]
        --sortdir = wcprops[wcpSortDirection][idx]
         
        --iids = wcprops[wcpItemIDs][idx]
        itexts = wcprops[wcpItemText][idx]
        iicons = wcprops[wcpItemIcons][idx]
        iselected = wcprops[wcpItemSelected][idx]
        
        scrx = floor(wcprops[wcpScrollPosX][idx])
        scry = floor(wcprops[wcpScrollPosY][idx])
        
        --iconlist = wcprops[wcpIconList][idx]
        
        --corumn headings:
        xp = lrect[1]
        yp = lrect[2]
            
        if length(clabels) > 0 then
            --xp += indent
            --for ch = 1 to length(clabels) do
            --    irect = {xp - scrx, yp, xp - scrx + cwidths[ch]-1, yp + headingheight}
            --    if in_rect(xpos, ypos, irect) then
            --        --
            --    end if
            --end for
            
            xp = lrect[1]
            yp = lrect[2] + headingheight + 1
        end if
        
        --list items:   --iids, itexts, iicons, iselected
                  
        for li = 1 to length(itexts) do
            
            if yp - scry > lrect[2] - ih and yp - scry - ih < lrect[4] then
                if in_rect(xpos, ypos, {lrect[1], yp - scry, lrect[3], yp - scry + ih}) then
                    citem = li
                    exit
                end if
            end if
            xp = lrect[1]
            yp += ih
        end for
    end if
    
    return citem
end function


procedure move_cursor(atom idx, atom wid, atom relpos)
    atom citem
    sequence wname
    
    if length(wcprops[wcpSelection][idx]) > 0 then
        citem = wcprops[wcpSelection][idx][1]
    else
        citem = 1
    end if

    if relpos = -1 then
        citem -= 1
        if citem < 1 then
            citem = 1
        end if
    elsif relpos = 0 then
        citem = 0
    elsif relpos = 1 then
        citem += 1
    elsif relpos = 2 then
        citem = length(wcprops[wcpItemText][idx])
    end if
    
    if citem < 0 then
        citem = 0
    elsif citem > length(wcprops[wcpItemText][idx]) then
        citem = length(wcprops[wcpItemText][idx])
    end if
    
    wcprops[wcpSelStart][idx] = citem
    wcprops[wcpIsSelecting][idx] = 0
    wcprops[wcpSelection][idx] = {citem}
    wname = widget_get_name(wid)
    
    send_selection_event(idx, wname, wcprops[wcpSelection][idx])
end procedure
                        

procedure check_scrollbars(atom idx, atom wid) --check contents and size of widget to determine if scrollbars are needed, then create or destroy scrollbars when required. 
    sequence wpos, wsize, trect
    atom th, vh
    
    if wcprops[wcpContentSize][idx][2] > wcprops[wcpVisibleSize][idx][2] then
        if wcprops[wcpScrollV][idx] = 0 then
            wpos = widget_get_pos(wid)
            wsize = widget_get_size(wid)
            trect = wcprops[wcpListRect][idx]
            trect[3] -= scrwidth
            
            wcprops[wcpScrollV][idx] = widget:widget_create(widget_get_name(wid) & ".scrV", wid, "scrollbar", {
                {"attach", wid},
                {"orientation", 0},
                {"min", 0},
                {"position", {wpos[1] + trect[3]+1, wpos[2] + trect[2]}}
                --{"size", {scrwidth, wcprops[wcpVisibleSize][idx][2]}}
            })
            
            widget_set_size(wcprops[wcpScrollV][idx], scrwidth, trect[4] - trect[2] + 1) --wcprops[wcpVisibleSize][idx][2])
            wc_call_arrange(wcprops[wcpScrollV][idx])
        end if
        
    else --if wcprops[wcpContentSize][idx][2] <= wcprops[wcpVisibleSize][idx][2] then
        if wcprops[wcpScrollV][idx] > 0 then
            widget:widget_destroy(wcprops[wcpScrollV][idx])
            wcprops[wcpScrollV][idx] = 0
            wcprops[wcpScrollPosY][idx] = 0
        end if
    end if
    
    if wcprops[wcpScrollV][idx] > 0 then
        th = wcprops[wcpContentSize][idx][2]
        vh = wcprops[wcpVisibleSize][idx][2]
        
        wc_call_command(wcprops[wcpScrollV][idx], "set_max", th)
        wc_call_command(wcprops[wcpScrollV][idx], "set_range", vh)
        wc_call_command(wcprops[wcpScrollV][idx], "set_value", wcprops[wcpScrollPosY][idx])
    end if
end procedure                        


-- widgetclass handlers ----------------------------

procedure wc_create(atom wid, object wprops) 
    sequence wlabel = ""
    atom optLabelPos = 1, stayatbottom = 0, multiselect = 0
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do         
                case "label" then
                    wlabel = wprops[p][2]
                
                case "stay_at_bottom" then
                    stayatbottom = wprops[p][2]
                
                case "label_pos" then
                    optLabelPos = wprops[p][2]
                    
                case "multi_select" then
                    multiselect = wprops[p][2]
                                
            end switch
        end if
    end for
    
    wcprops[wcpID] &= {wid}
    wcprops[wcpSoftFocus] &= {0}
    wcprops[wcpHardFocus] &= {0}
    wcprops[wcpKeyFocus] &= {0}
    
    wcprops[wcpIsSelecting] &= {0}
    wcprops[wcpOptLabelPos] &= {optLabelPos}
    wcprops[wcpOptStripes] &= {0}
    wcprops[wcpStayAtBottom] &= {stayatbottom}

    wcprops[wcpLabelPos] &= {{0, 0}}
    wcprops[wcpListRect] &= {{0, 0, 0, 0}}
    wcprops[wcpVisibleSize] &= {{0, 0}}
    wcprops[wcpContentSize] &= {{0, 0}}
    wcprops[wcpScrollPosX] &= {0}
    wcprops[wcpScrollPosY] &= {0}

    wcprops[wcpScrollV] &= {0}
    wcprops[wcpScrollH] &= {0}
    
    wcprops[wcpSelStart] &= {{}}
    wcprops[wcpSelection] &= {{}}
    wcprops[wcpHover] &= {0}
    
    wcprops[wcpIndent] &= {20}
    wcprops[wcpCheckBoxes] &= {0}
    wcprops[wcpNumbered] &= {0}
    wcprops[wcpItemHeight] &= {20}
    
    wcprops[wcpMultiSelect] &= {multiselect}
    
    wcprops[wcpIconList] &= {{}}
    
    wcprops[wcpColumnLabels] &= {{}}
    wcprops[wcpColumWidths] &= {{}}
    wcprops[wcpSortColumns] &= {{}}
    wcprops[wcpSortDirection] &= {{}}
     
    --wcprops[wcpItemIDs] &= {{}}
    wcprops[wcpItemText] &= {{}}
    wcprops[wcpItemIcons] &= {{}}
    wcprops[wcpItemSelected] &= {{}}

    wcprops[wcpLabel] &= {wlabel}
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
    sequence cmds, wrect, chwid, txex, txpos, lrect, lpos, irect
    atom idx, wh, wf, hlcolor, shcolor, bcolor, fillcolor, txtcolor, hicolor, stripecolor
    atom indent, checkbox, numbered, ih, xp, yp, ss
    sequence clabels, cwidths, csort, sortdir, itexts, iicons, iselected
    atom scry,scrx, hover
    sequence iconlist, selection
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wrect = widget_get_rect(wid)
        --wrect[3] -= 1
        --wrect[4] -= 1
        lpos = wcprops[wcpLabelPos][idx]
        lrect = wcprops[wcpListRect][idx]
        lpos[1] += wrect[1]
        lpos[2] += wrect[2]
        lrect[1] += wrect[1]
        lrect[2] += wrect[2]
        lrect[3] += wrect[1]
        lrect[4] += wrect[2]
        if wcprops[wcpScrollV][idx] then
            lrect[3] -= scrwidth
        end if
        if wcprops[wcpScrollH][idx] then
            lrect[4] -= scrwidth
        end if
        
        wh = widget:widget_get_handle(wid)
        wf = (wh = oswin:get_window_focus())
        
        if wcprops[wcpHardFocus][idx] and wf then
            hicolor = th:cOuterActive
            bcolor = th:cOuterHighlight
        elsif wcprops[wcpSoftFocus][idx] then
            hicolor = th:cOuterHover
            bcolor = th:cOuterHover
        else
            hicolor = th:cOuterFill
            bcolor = th:cOuterFill
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
            {DR_Font, "Arial", 9, Normal},
            {DR_TextColor, th:cOuterLabel},
            {DR_PenPos} & txpos,
            {DR_Puts, wcprops[wcpLabel][idx]},
            
        --text border:
            {DR_PenColor, bcolor},
            {DR_Rectangle, True, lrect[1] - 1, lrect[2] - 1, wrect[3] - 1, wrect[4] - 1},
            
            {DR_PenColor, shcolor},
            {DR_Line, lrect[1], lrect[2], lrect[3], lrect[2]},
            {DR_Line, lrect[1], lrect[2], lrect[1], lrect[4]},
            
            {DR_PenColor, hlcolor},
            
            {DR_Line, lrect[3], lrect[2] + 1, lrect[3], lrect[4]},
            {DR_Line, lrect[1], lrect[4], lrect[3], lrect[4]},
            
            {DR_Restrict, lrect[1], lrect[2], lrect[3], lrect[4]}, --restrict drawing to list area
            
            {DR_PenColor, th:cInnerFill},
            {DR_Rectangle, True} & lrect
        }
        
        
        indent = wcprops[wcpIndent][idx]
        --checkbox = wcprops[wcpCheckBoxes][idx]
        --numbered = wcprops[wcpNumbered][idx]
        ih = wcprops[wcpItemHeight][idx]
        
        clabels = wcprops[wcpColumnLabels][idx]
        cwidths = wcprops[wcpColumWidths][idx]
        
        --csort = wcprops[wcpSortColumns][idx]
        --sortdir = wcprops[wcpSortDirection][idx]
        
        --iids = wcprops[wcpItemIDs][idx]
        itexts = wcprops[wcpItemText][idx]
        iicons = wcprops[wcpItemIcons][idx]
        --iselected = wcprops[wcpItemSelected][idx]
        
        scrx = floor(wcprops[wcpScrollPosX][idx])
        scry = floor(wcprops[wcpScrollPosY][idx])
        
        selection = wcprops[wcpSelection][idx]
        hover = wcprops[wcpHover][idx]
        --iconlist = wcprops[wcpIconList][idx]
        
        --column headings:
        xp = lrect[1]
        yp = lrect[2]
        
        if length(clabels) > 0 then
            irect = {xp, yp, xp + indent-1, yp + headingheight}
            cmds &= {
                {DR_PenColor, th:cButtonFace},
                {DR_Rectangle, True} & irect,
                
                {DR_PenColor, th:cButtonHighlight},
                {DR_Line, irect[1], irect[2], irect[3], irect[2]},
                {DR_Line, irect[1], irect[2], irect[1], irect[4]},
                
                {DR_PenColor, th:cButtonShadow},
                {DR_Line, irect[3], irect[2] + 1, irect[3], irect[4]},
                {DR_Line, irect[1], irect[4], irect[3], irect[4]},
                
                {DR_Font, "Arial", 9, Normal},
                {DR_TextColor, cButtonLabel}
            }
            
            xp += indent
            for ch = 1 to length(clabels) do
                irect = {xp - scrx, yp, xp - scrx + cwidths[ch]-1, yp + headingheight}
                if ch = length(clabels) then
                    irect[3] = lrect[3] - 1
                end if
                
                cmds &= {
                    {DR_PenColor, th:cButtonFace},
                    {DR_Rectangle, True} & irect,
                    {DR_PenColor, rgb(250, 250, 250)},
                    {DR_Line, irect[1], irect[2], irect[3], irect[2]},
                    {DR_Line, irect[1], irect[2], irect[1], irect[4]},
                    
                    {DR_PenColor, th:cButtonShadow},
                    
                    {DR_Line, irect[3], irect[2] + 1, irect[3], irect[4]},
                    {DR_Line, irect[1], irect[4], irect[3], irect[4]},
                    
                    {DR_PenPos, irect[1] + 2, irect[2] + 2},
                    {DR_Puts, clabels[ch]}
                } 
                xp += cwidths[ch]
            end for
            
            cmds &= {
                {DR_Release}
            }
            xp = lrect[1]
            yp = lrect[2] + headingheight + 1
        end if
        
        
        --list items:   --iids, itexts, iicons, iselected
        cmds &= {
            {DR_Font, "Arial", 9, Normal},
            {DR_Restrict, xp, yp, lrect[3], lrect[4]}
        }
        
        ss = stripe+1               
        for li = 1 to length(itexts) do
            ss += 1
            if ss > stripe then
                ss = 0
                stripecolor = 0
            else
                stripecolor = 1            
            end if
            
            if yp - scry > lrect[2] - ih and yp - scry - ih < lrect[4] then
                if find(li, selection) then
                    if li = hover then
                        if stripecolor = 1 then
                          fillcolor = th:cInnerItemOddSelHover
                        else
                          fillcolor = th:cInnerItemEvenSelHover
                        end if
                        txtcolor = th:cInnerItemTextSelHover 
                    else
                        if wcprops[wcpHardFocus][idx] and wf then
                          if stripecolor = 1 then
                            fillcolor = th:cInnerItemOddSel
                          else
                            fillcolor = th:cInnerItemEvenSel
                          end if
                          txtcolor = th:cInnerItemTextSel 
                        else             
                          if stripecolor = 1 then
                            fillcolor = th:cInnerItemOddSelInact
                          else
                            fillcolor = th:cInnerItemEvenSelInact
                          end if
                          txtcolor = th:cInnerItemTextSelInact 
                        end if
                    end if
                else
                    if li = hover then
                        if stripecolor = 1 then
                          fillcolor = th:cInnerItemOddHover
                        else
                          fillcolor = th:cInnerItemEvenHover
                        end if
                        txtcolor = th:cInnerItemTextHover 
                    else
                        if stripecolor = 1 then
                          fillcolor = th:cInnerItemOdd
                        else
                          fillcolor = th:cInnerItemEven
                        end if
                        txtcolor = th:cInnerItemText 
                    end if                 
                end if
                
                
                cmds &= {
                    {DR_PenColor, fillcolor},
                    {DR_Rectangle, True, lrect[1], yp - scry, lrect[3], yp - scry + ih}
                }
                
                if atom(iicons[li]) then --a rgb color
                    cmds &= {
                        --item icon - solid color
                        {DR_PenColor, iicons[li]},
                        {DR_Rectangle, True, xp - scrx + 2, yp - scry + 2, xp - scrx + 2 + iconsize, yp - scry + 2 + iconsize}
                    }
                elsif length(iicons[li]) > 0 then --a string representing the bitmap already loaded by load_bitmap()
                    cmds &= {
                        --item icon - image (must be 16 x 16!)
                        {DR_Image, iicons[li], xp - scrx + 2, yp - scry + 2, rgb(0, 0, 0)}
                    }
                else   --empty string to use default solid color
                    cmds &= {
                        --item icon - default solid color
                        {DR_PenColor, rgb(255, 255, 200)},
                        {DR_Rectangle, True, xp - scrx + 2, yp - scry + 2, xp - scrx + 2 + iconsize, yp - scry + 2 + iconsize}
                    }
                end if
                
                cmds &= {
                    {DR_TextColor, txtcolor}
                }
                
                if length(clabels) = 0 then
                    cmds &= {
                        {DR_PenPos, indent + xp - scrx + 2, yp - scry},
                        {DR_Puts, itexts[li][1]}
                    }
                else
                    for ch = 1 to length(clabels) do --itexts[li]) do
                        if ch <= length(itexts[li]) then
                             cmds &= {
                                {DR_PenPos, indent + xp - scrx + 2, yp - scry + 2},
                                {DR_Puts, itexts[li][ch]}
                            }
                        end if
                        xp += cwidths[ch]
                    end for
                end if
            end if
            xp = lrect[1]
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
    sequence ampos, wrect, lpos, lrect
    atom idx, doredraw = 0, wh, ss, se, skip = 0, citem
    atom th, vh
    sequence wname    
    
    idx = find(wid, wcprops[wcpID])

    if idx > 0 then
        wh = widget:widget_get_handle(wid)
        wrect = widget_get_rect(wid)
        --wrect[3] -= 1
        --wrect[4] -= 1
        
        lpos = wcprops[wcpLabelPos][idx]
        lrect = wcprops[wcpListRect][idx]
        lpos[1] += wrect[1]
        lpos[2] += wrect[2]
        lrect[1] += wrect[1]
        lrect[2] += wrect[2]
        lrect[3] += wrect[1]
        lrect[4] += wrect[2]
        if wcprops[wcpScrollV][idx] then
            lrect[3] -= scrwidth
        end if
        
        switch evtype do        
            case "MouseMove" then --{x, y, shift, mousepos[1], mousepos[2]}
                if in_rect(evdata[1], evdata[2], wrect) then
                    if wcprops[wcpSoftFocus][idx] = 0 then
                        wcprops[wcpSoftFocus][idx] = 1
                        set_mouse_pointer(wh, mArrow)
                        doredraw = 1
                    end if
                else
                    if wcprops[wcpSoftFocus][idx] = 1 then
                        wcprops[wcpSoftFocus][idx] = 0
                        doredraw = 1
                    end if
                end if
                
                if in_rect(evdata[1], evdata[2], lrect) then
                    citem = get_item_under_pos(wid, evdata[1], evdata[2])
                    if citem > 0 then
                        if wcprops[wcpIsSelecting][idx] = 1 then
                            if wcprops[wcpMultiSelect][idx] = 1 then                            
                                wcprops[wcpSelection][idx] = {}
                                wcprops[wcpHover][idx] = 0
                                if wcprops[wcpSelStart][idx] > citem then
                                    for i = citem to wcprops[wcpSelStart][idx] do
                                        wcprops[wcpSelection][idx] &= i
                                    end for
                                else
                                    for i = wcprops[wcpSelStart][idx] to citem do
                                        wcprops[wcpSelection][idx] &= i
                                    end for                            
                                end if
                            else
                                wcprops[wcpSelStart][idx] = citem
                                wcprops[wcpSelection][idx] = {citem}
                            end if
                            doredraw = 1
                        else
                            if wcprops[wcpHover][idx] != citem then
                                wcprops[wcpHover][idx] = citem
                                doredraw = 1
                            end if
                        end if
                    end if
                else
                    if wcprops[wcpHover][idx] > 0 then
                        wcprops[wcpHover][idx] = 0
                        doredraw = 1
                    end if
                end if
            
            case "LeftDown" then        
                if in_rect(evdata[1], evdata[2], wrect) then
                    if in_rect(evdata[1], evdata[2], lrect) then
                        oswin:capture_mouse(wh)
                        wcprops[wcpIsSelecting][idx] = 1
                        citem = get_item_under_pos(wid, evdata[1], evdata[2])
                        if citem > 0 then
                            wcprops[wcpSelStart][idx] = citem
                            wcprops[wcpSelection][idx] = {citem}
                            doredraw = 1   
                        end if
                    end if
                    
                    if wcprops[wcpHardFocus][idx] = 0 then
                        wcprops[wcpHardFocus][idx] = 1
                        --widget:wc_send_event(widget_get_name(wid), "GotFocus", {})
                        widget:set_key_focus(wid)
                        doredraw = 1
                    end if
                else
                    if wcprops[wcpHardFocus][idx] = 1 then
                        wcprops[wcpHardFocus][idx] = 0
                        doredraw = 1
                    end if
                end if

            case "LeftUp" then    
                if in_rect(evdata[1], evdata[2], lrect) then
                    -------
                    doredraw = 1
                end if
                if wcprops[wcpIsSelecting][idx] = 1 then
                    --oswin:release_mouse()
                    wcprops[wcpIsSelecting][idx] = 0
                    wname = widget_get_name(wid)
                    send_selection_event(idx, wname, wcprops[wcpSelection][idx])
                    doredraw = 1
                end if
            
            case "LeftDoubleClick" then
                if in_rect(evdata[1], evdata[2], lrect) then
                    wname = widget_get_name(wid)
                    send_double_click_event(idx, wname, wcprops[wcpSelection][idx])
                end if
            case "RightDown" then
                if wcprops[wcpIsSelecting][idx] = 0 and in_rect(evdata[1], evdata[2], lrect) then
                    wname = widget_get_name(wid)
                    show_context_menu(idx, wname, wcprops[wcpSelection][idx])
                end if
                
            case "WheelMove" then
                if wcprops[wcpSoftFocus][idx] > 0 then
                    wc_call_command(wcprops[wcpScrollV][idx], "set_value_rel", -evdata[2]*wcprops[wcpItemHeight][idx])
                end if
            
            case "KeyDown" then
                if wcprops[wcpHardFocus][idx] then
                    if evdata[1] = 38 then --up
                        move_cursor(idx, wid, -1)
                    elsif evdata[1] = 40 then --down
                        move_cursor(idx, wid, 1)
                    elsif evdata[1] = 33 then --pgup
                    elsif evdata[1] = 34 then --pgdown
                    elsif evdata[1] = 36 then --home
                        move_cursor(idx, wid, 0)
                    elsif evdata[1] = 35 then --end
                        move_cursor(idx, wid, 2)
                    end if
                    doredraw = 1
                end if
                
            case "KeyPress" then
                if wcprops[wcpHardFocus][idx] then
                    --if evdata[1] = 13 then --Enter key  
                    --elsif evdata[1] > 13 then --normal characters
                    --end if
                    wname = widget_get_name(wid)
                    send_keypress_event(idx, wname, evdata[1])
                    --doredraw = 1
                end if
                  
            case "scroll" then
                if evdata[1] = wcprops[wcpScrollV][idx] then
                     wcprops[wcpScrollPosY][idx] = evdata[2]
                     doredraw = 1
                end if  
                          
            case "changed" then    
                th = length(wcprops[wcpItemText][idx]+1) * wcprops[wcpItemHeight][idx]
                vh = lrect[4] - lrect[2] - 1

               
                if length(wcprops[wcpColumnLabels][idx]) > 0 then
                    vh -= headingheight - 1
                end if
                
                wcprops[wcpContentSize][idx] = {50, th}
                check_scrollbars(idx, wid)
                
                
                --wc_call_command(wcprops[wcpScrollV][idx], "set_max", th)
                --wc_call_command(wcprops[wcpScrollV][idx], "set_range", vh)
                if wcprops[wcpStayAtBottom][idx] then
                    wc_call_command(wcprops[wcpScrollV][idx], "set_value", th)
                --else
                --    wc_call_command(wcprops[wcpScrollV][idx], "set_value", wcprops[wcpScrollPosY][idx])
                end if
                doredraw = 1
                
            case "LostFocus" then
                wcprops[wcpSoftFocus][idx] = 0
                doredraw = 1
                
            case "KeyFocus" then
                if evdata = wid then
                    wcprops[wcpKeyFocus][idx] = 1
                else
                    wcprops[wcpKeyFocus][idx] = 0
                end if
                
            case else
                --statusUpdateMsg(0, "gui: window event:" & evtype & sprint(evdata), 0)

        end switch     
        
                       
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
        oswin:set_font(wh, "Arial", 9, Normal)
        txex = oswin:get_text_extent(wh, wcprops[wcpLabel][idx])
        wsize = {txex[1] + 6, txex[2] + 6 + 30}
        
        widget:widget_set_min_size(wid, wsize[1] + 6, wsize[2])
        widget:widget_set_natural_size(wid, 0, 0)

        wparent = parent_of(wid)
        if wparent > 0 then
            wc_call_resize(wparent)
        end if
    end if
end procedure



procedure wc_arrange(atom wid)
    atom idx, wh
    sequence wpos, wsize, txex, trect
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wpos = widget_get_pos(wid)
        wsize = widget_get_size(wid)
        
        wh = widget_get_handle(wid)
        --label:
        oswin:set_font(wh, "Arial", 9, Normal)
        txex = oswin:get_text_extent(wh, wcprops[wcpLabel][idx])
        trect = {3, txex[2] + 6, wsize[1] - 3, wsize[2] - 3}
        wcprops[wcpLabelPos][idx] = {3, 3}
        wcprops[wcpVisibleSize][idx] = {trect[3] - trect[1], trect[4] - trect[2] - headingheight - 1}
        
        if not equal(wcprops[wcpListRect][idx], trect) then
            wcprops[wcpListRect][idx] = trect
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
            {"KeyFocus", wcprops[wcpKeyFocus][idx]},
            {"IsSelecting", wcprops[wcpIsSelecting][idx]},
            {"OptLabelPos", wcprops[wcpOptLabelPos][idx]},
            {"OptStripes", wcprops[wcpOptStripes][idx]},
            {"StayAtBottom", wcprops[wcpStayAtBottom][idx]},
            {"Label", wcprops[wcpLabel][idx]},
                           
            {"LabelPos", wcprops[wcpLabelPos][idx]},
            {"ListRect", wcprops[wcpListRect][idx]},
            {"VisibleSize", wcprops[wcpVisibleSize][idx]},
            {"ContentSize", wcprops[wcpContentSize][idx]},
            {"ScrollPosX", wcprops[wcpScrollPosX][idx]},
            {"ScrollPosY", wcprops[wcpScrollPosY][idx]},
            {"Indent", wcprops[wcpIndent][idx]},
            {"CheckBoxes", wcprops[wcpCheckBoxes][idx]},
            {"Numbered", wcprops[wcpNumbered][idx]},
            {"ItemHeight", wcprops[wcpItemHeight][idx]},
                           
            {"MultiSelect", wcprops[wcpMultiSelect][idx]},
                           
            {"ColumnLabels", wcprops[wcpColumnLabels][idx]},
            {"ColumWidths", wcprops[wcpColumWidths][idx]},
                           
            {"IconList", wcprops[wcpIconList][idx]},
                           
            {"SortColumns", wcprops[wcpSortColumns][idx]},
            {"SortDirection", wcprops[wcpSortDirection][idx]},
                           
            {"ScrollV", wcprops[wcpScrollV][idx]},
            {"ScrollH", wcprops[wcpScrollH][idx]},
                           
            {"SelStart", wcprops[wcpSelStart][idx]},
            {"Selection", wcprops[wcpSelection][idx]},
            {"Hover", wcprops[wcpHover][idx]}
                           
            --{"ItemIDs", wcprops[wcpItemIDs][idx]},
            --{"ItemText", wcprops[wcpItemText][idx]},
            --{"ItemIcons", wcprops[wcpItemIcons][idx]},
            --{"ItemSelected", wcprops[wcpItemSelected][idx]}
        }
    end if
    return debuginfo
end function



wc_define(
    "listbox",
    routine_id("wc_create"),
    routine_id("wc_destroy"),
    routine_id("wc_draw"),
    routine_id("wc_event"),
    routine_id("wc_resize"),
    routine_id("wc_arrange"),
    routine_id("wc_debug")
)   
    

-- widgetclass commands -------------------------------------------------------


procedure cmd_clear_columns(atom wid)
    atom idx

    idx = find(wid, wcprops[wcpID])    
    if idx > 0 then
        wcprops[wcpColumnLabels][idx] = {}
        wcprops[wcpColumWidths][idx] = {}
        wcprops[wcpSortColumns][idx] = {}
        wcprops[wcpSortDirection][idx] = {}
        widget:widget_set_min_size(wid, 40, 80)
        
        wc_call_event(wid, "changed", {})
    end if
    
end procedure
wc_define_command("listbox", "clear_columns", routine_id("cmd_clear_columns"))


procedure cmd_add_column(atom wid, sequence coldata)
--coldata:{label, width, sort_on_off, sort_asc_desc}
    atom idx, w
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wcprops[wcpColumnLabels][idx] &= {coldata[1]}
        if length(coldata) > 1 and integer(coldata[2]) then
            wcprops[wcpColumWidths][idx] &= {coldata[2]}
        else
            wcprops[wcpColumWidths][idx] &= {100} --TODO: set to width of text
        end if
        if length(coldata) > 2 and integer(coldata[3]) then
            wcprops[wcpSortColumns][idx] &= {coldata[3]}
        else
            wcprops[wcpSortColumns][idx] &= {0}
        end if
        if length(coldata) > 3 and integer(coldata[4]) then
            wcprops[wcpSortDirection][idx] &= {coldata[4]}
        else
            wcprops[wcpSortDirection][idx] &= {0}
        end if
        
        w = sum(wcprops[wcpColumWidths][idx]) + 40
        
        widget:widget_set_min_size(wid, w, 80)
        --widget:widget_set_natural_size(wid, w, 100) 
        --widget:widget_set_size(wid, wsize[1], wsize[2]) 
        
        wc_call_event(wid, "changed", {})
    end if
    
end procedure
wc_define_command("listbox", "add_column", routine_id("cmd_add_column"))


procedure cmd_set_list_items(atom wid, sequence items) --items:{{icon1, "col1", "col2",...},{icon2, "col1", "col2"...}...}
    atom idx, len
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        len = length(items)
        wcprops[wcpItemText][idx] = repeat({}, len)
        wcprops[wcpItemIcons][idx] = repeat({}, len)
        wcprops[wcpItemSelected][idx] = repeat(0, len)
        for i = 1 to len do
            wcprops[wcpItemText][idx][i] = items[i][2..$]
            wcprops[wcpItemIcons][idx][i] = items[i][1]
        end for
        wc_call_event(wid, "changed", {})
    end if
end procedure
wc_define_command("listbox", "set_list_items", routine_id("cmd_set_list_items"))

/*
procedure cmd_replace_list_items(atom wid, sequence items) --items:{{icon1, "col1", "col2",...},{icon2, "col1", "col2"...}...}
    atom idx, st, len, oldlen
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        st = length(wcprops[wcpItemText][idx])
        len = length(items)
        oldlen = length(wcprops[wcpItemText][idx])
        if len > oldlen then
            wcprops[wcpItemText][idx] &= repeat({}, len - oldlen)
            wcprops[wcpItemIcons][idx] &= repeat({}, len - oldlen)
            wcprops[wcpItemSelected][idx] &= repeat(0, len - oldlen)
        elsif len < oldlen then
            wcprops[wcpItemText][idx] = wcprops[wcpItemText][idx][1..len]
            wcprops[wcpItemIcons][idx] = wcprops[wcpItemIcons][idx][1..len]
            wcprops[wcpItemSelected][idx] = wcprops[wcpItemSelected][idx][1..len]
        end if
        for i = 1 to len do
            wcprops[wcpItemText][idx][i] = items[i][2..$]
            wcprops[wcpItemIcons][idx][i] = items[i][1]
        end for
        wc_call_event(wid, "changed", {})
    end if
end procedure
wc_define_command("listbox", "replace_list_items", routine_id("cmd_replace_list_items"))
*/

procedure cmd_add_list_items(atom wid, sequence items) --items:{{icon1, "col1", "col2",...},{icon2, "col1", "col2"...}...}
    atom idx, st, len
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        st = length(wcprops[wcpItemText][idx])
        len = length(items)
        wcprops[wcpItemText][idx] &= repeat({}, len)
        wcprops[wcpItemIcons][idx] &= repeat({}, len)
        wcprops[wcpItemSelected][idx] &= repeat(0, len)
        for i = 1 to len do
            wcprops[wcpItemText][idx][st+i] = items[i][2..$]
            wcprops[wcpItemIcons][idx][st+i] = items[i][1]
        end for
        wc_call_event(wid, "changed", {})
    end if
end procedure
wc_define_command("listbox", "add_list_items", routine_id("cmd_add_list_items"))


procedure cmd_clear_list(atom wid)
    atom idx

    idx = find(wid, wcprops[wcpID])    
    if idx > 0 then
        --wcprops[wcpItemIDs][idx] = {} --not used for now
        wcprops[wcpItemText][idx] = {}
        wcprops[wcpItemIcons][idx] = {}
        wcprops[wcpItemSelected][idx] = {}

        wc_call_event(wid, "changed", {})
    end if
    
end procedure
wc_define_command("listbox", "clear_list", routine_id("cmd_clear_list"))


procedure cmd_set_selection(atom wid, atom setsel, atom setrelative = 0)
    atom idx
    sequence wname

    idx = find(wid, wcprops[wcpID])    
    --? {wid, idx, setsel, setrelative}
    
    if idx > 0 then
        if setrelative != 0 then
            wcprops[wcpSelStart][idx] += setsel
        else
            wcprops[wcpSelStart][idx] = setsel
        end if
        if wcprops[wcpSelStart][idx] < 1 then
            wcprops[wcpSelStart][idx] = 1
        end if
        if wcprops[wcpSelStart][idx] > length(wcprops[wcpItemText][idx]) then
            wcprops[wcpSelStart][idx] = length(wcprops[wcpItemText][idx])
        end if    
        
        wcprops[wcpSelection][idx] = {wcprops[wcpSelStart][idx]}
        wc_call_draw(wid)
        
        wname = widget_get_name(wid)
        send_selection_event(idx, wname, wcprops[wcpSelection][idx])
        
    end if
end procedure
wc_define_command("listbox", "set_selection", routine_id("cmd_set_selection"))


procedure cmd_select_items(atom wid, object sel)
    atom idx

    idx = find(wid, wcprops[wcpID])    
    if idx > 0 then
        if atom(sel) and sel > 0 and sel <= length(wcprops[wcpItemText][idx]) then
            wcprops[wcpSelStart][idx] = sel
            wcprops[wcpSelection][idx] = {sel}
            send_selection_event(idx, widget_get_name(wid), wcprops[wcpSelection][idx])
        elsif sequence(sel) and length(sel) > 0 then
            wcprops[wcpSelStart][idx] = sel[1]
            wcprops[wcpSelection][idx] = sel
            send_selection_event(idx, widget_get_name(wid), wcprops[wcpSelection][idx])
        else
            wcprops[wcpSelStart][idx] = 0
            wcprops[wcpSelection][idx] = {}
        end if
        wc_call_event(wid, "changed", {})
    end if
    
end procedure
wc_define_command("listbox", "select_items", routine_id("cmd_select_items"))




