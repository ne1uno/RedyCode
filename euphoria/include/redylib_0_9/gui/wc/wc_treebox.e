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
    wcpLabel,

    wcpLabelPos,
    wcpTreeRect,
    wcpVisibleSize, --size of visible area
    wcpContentSize, --size of actual content
    wcpScrollPosX,
    wcpScrollPosY,
    
    wcpItemHeight,
    wcpIndentWidth, 
    
    --wcpIconList, --sequence of icon pointers
 
    wcpScrollV, --vertical scrollbar widgetid
    wcpScrollH, --horizontal scrollbar widgetid
    
    wcpSelection,
    wcpHover,
     
    wcpItemIDs, --unique id for each item
    wcpItemText, --text for each item or seqeunce of strings for multiple columns
    wcpItemIcons, --icon id for each item
    wcpItemParent,
    wcpItemExpand, --  -1 = no children, 0 = children hidden, 1 = children shown
    wcpItemHasChildren,
    
    wcpVisibleItemIdx,
    wcpVisibleItemIndent

    
constant wcpLENGTH = wcpVisibleItemIndent

wcprops = repeat({}, wcpLENGTH)


-- Theme variables -------------------------------

atom stripe = 1, brctlsize = 16, iconsize = 16

-- local routines ---------------------------------------------------------------------------

procedure send_selection_event(atom idx, sequence wname, atom sel)
    atom iidx
    sequence itm
    
    if sel > 0 then
        iidx = wcprops[wcpVisibleItemIdx][idx][sel]
        
        if iidx > 0 and iidx <= length(wcprops[wcpItemIDs][idx]) then
            itm = {
                wcprops[wcpItemIDs][idx][iidx],
                wcprops[wcpItemText][idx][iidx],
                wcprops[wcpItemIcons][idx][iidx],
                wcprops[wcpItemParent][idx][iidx],
                wcprops[wcpItemExpand][idx][iidx],
                wcprops[wcpItemHasChildren][idx][iidx]
            }
            widget:wc_send_event(wname, "selection", itm)
        end if
    end if
end procedure


procedure send_double_click_event(atom idx, sequence wname, atom sel)
    atom iidx
    sequence itm
    
    if sel > 0 then
        iidx = wcprops[wcpVisibleItemIdx][idx][sel]
        
        if iidx > 0 and iidx <= length(wcprops[wcpItemIDs][idx]) then
            itm = {
                wcprops[wcpItemIDs][idx][iidx],
                wcprops[wcpItemText][idx][iidx],
                wcprops[wcpItemIcons][idx][iidx],
                wcprops[wcpItemParent][idx][iidx],
                wcprops[wcpItemExpand][idx][iidx],
                wcprops[wcpItemHasChildren][idx][iidx]
            }
            widget:wc_send_event(wname, "left_double_click", itm)
        end if
    end if
end procedure


procedure show_context_menu(atom idx, sequence wname, atom sel)
    
end procedure



function nextID(atom idx)
    object mx = 0

    if length(wcprops[wcpItemIDs][idx]) > 0 then
        mx =  max(wcprops[wcpItemIDs][idx])
    end if

    if atom(mx) then
        return mx + 1
    else
        return 1
    end if
end function

function list_children(atom idx, atom itmid) --lists children items (by index, not id, for convenience)
    sequence chlist = {}
    
    for i = 1 to length(wcprops[wcpItemIDs][idx]) do
        if wcprops[wcpItemParent][idx][i] = itmid then
            chlist &= i
        end if
    end for
    
    return chlist
end function


procedure build_tree(atom wid)
    atom idx, ilvl, i
    sequence ch, vidx = {}, vind = {}
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        for r = 1 to length(wcprops[wcpItemIDs][idx]) do
            if wcprops[wcpItemParent][idx][r] = 0 then
                vidx &= {r}
                vind &= {0}
            end if
        end for
        
        i = 1
        while i <= length(vidx) do
            if wcprops[wcpItemExpand][idx][vidx[i]] = 1 then
                ch = list_children(idx, wcprops[wcpItemIDs][idx][vidx[i]])
                if length(ch) > 0 then
                    ilvl = vind[i] + 1
                    vidx = vidx[1..i] & ch & vidx[i+1..$]
                    vind = vind[1..i] & repeat(ilvl, length(ch)) & vind[i+1..$]
                end if
            end if
            i += 1
        end while
        
        wcprops[wcpVisibleItemIdx][idx] = vidx
        wcprops[wcpVisibleItemIndent][idx] = vind
    end if
    
    --puts(1, "\n\n")
    --for d = 1 to length(vidx) do
    --    ? {vidx[d], vind[d]}
    --end for
end procedure


function get_item_under_pos(atom wid, atom xpos, atom ypos)
    atom idx, itm = 0, brctrl = 0, xp, yp, ih, iw, scrx, scry
    sequence wrect, trect, vidx, vind

    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wrect = widget_get_rect(wid)
        
        trect = wcprops[wcpTreeRect][idx]
        trect[1] += wrect[1]
        trect[2] += wrect[2]
        trect[3] += wrect[1]
        trect[4] += wrect[2]
        
        scrx = floor(wcprops[wcpScrollPosX][idx])
        scry = floor(wcprops[wcpScrollPosY][idx])
        
        vidx = wcprops[wcpVisibleItemIdx][idx]
        vind = wcprops[wcpVisibleItemIndent][idx]

        ih = wcprops[wcpItemHeight][idx]
        iw = wcprops[wcpIndentWidth][idx]
        
        yp = trect[2]
        for i = 1 to length(vidx) do
            if yp - scry > trect[2] - ih and yp - scry - ih < trect[4] then
                if in_rect(xpos, ypos, {trect[1], yp - scry, trect[3], yp - scry + ih}) then
                    itm = i
                    brctrl = in_rect(xpos, ypos, {trect[1] - scrx, yp - scry, trect[1] - scrx + vind[i] * iw + brctlsize, yp - scry + ih})
                    exit
                end if
            end if
            yp += ih
        end for
    end if
    
    return {itm, brctrl} --{item_index, is_over_branch_control} branch control is the part that the user clicks on to expand or collapse an item
end function


procedure move_cursor(atom idx, atom wid, atom relpos)
    atom citem
    sequence wname
    
    citem = wcprops[wcpSelection][idx]

    if relpos = -1 then
        citem -= 1
    elsif relpos = 0 then
        citem = 0
    elsif relpos = 1 then
        citem += 1
    elsif relpos = 2 then
        citem = length(wcprops[wcpVisibleItemIdx][idx])
    end if
    
    if citem < 1 then
        citem = 1
    elsif citem > length(wcprops[wcpVisibleItemIdx][idx]) then
        citem = length(wcprops[wcpVisibleItemIdx][idx])
    end if
    
    wcprops[wcpIsSelecting][idx] = 0
    wcprops[wcpSelection][idx] = citem
    wname = widget_get_name(wid)
    send_selection_event(idx, wname, wcprops[wcpSelection][idx])
    
end procedure
                        

procedure check_scrollbars(atom idx, atom wid) --check contents and size of widget to determine if scrollbars are needed, then create or destroy scrollbars when required. 
    sequence wpos, wsize, trect
    atom th, vh
    
    if wcprops[wcpContentSize][idx][2] > wcprops[wcpVisibleSize][idx][2] and wcprops[wcpScrollV][idx] = 0 then
        wpos = widget_get_pos(wid)
        wsize = widget_get_size(wid)
        trect = wcprops[wcpTreeRect][idx]
        trect[3] -= scrwidth
        
        wcprops[wcpScrollV][idx] = widget:widget_create(widget_get_name(wid) & ".scrV", wid, "scrollbar", {
            {"attach", wid},
            {"orientation", 0},
            {"min", 0},
            {"position", {wpos[1] + trect[3]+1, wpos[2] + trect[2]}}
            --{"size", {scrwidth, wcprops[wcpVisibleSize][idx][2]}}
        })
        
        widget_set_size(wcprops[wcpScrollV][idx], scrwidth, wcprops[wcpVisibleSize][idx][2])
        wc_call_arrange(wcprops[wcpScrollV][idx])
        
    elsif wcprops[wcpContentSize][idx][2] <= wcprops[wcpVisibleSize][idx][2] and wcprops[wcpScrollV][idx] > 0 then
        widget:widget_destroy(wcprops[wcpScrollV][idx])
        wcprops[wcpScrollV][idx] = 0
        wcprops[wcpScrollPosY][idx] = 0
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
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do         
                case "label" then
                    wlabel = wprops[p][2]
            end switch
        end if
    end for
        
    wcprops[wcpID] &= {wid}
    wcprops[wcpSoftFocus] &= {0}
    wcprops[wcpHardFocus] &= {0}
    wcprops[wcpKeyFocus] &= {0}
    wcprops[wcpIsSelecting] &= {0}
    wcprops[wcpLabel] &= {wlabel}

    wcprops[wcpLabelPos] &= {{0, 0}}
    wcprops[wcpTreeRect] &= {{0, 0, 0, 0}}
    wcprops[wcpVisibleSize] &= {{0, 0}}
    wcprops[wcpContentSize] &= {{0, 0}}
    wcprops[wcpScrollPosX] &= {0}
    wcprops[wcpScrollPosY] &= {0}
    
    wcprops[wcpItemHeight] &= {20}
    wcprops[wcpIndentWidth] &= {16}
    
    --wcprops[wcpIconList] &= {{}}
 
    wcprops[wcpScrollV] &= {0}
    wcprops[wcpScrollH] &= {0}
    
    wcprops[wcpSelection] &= {0}
    wcprops[wcpHover] &= {0}
     
    wcprops[wcpItemIDs] &= {{}}
    wcprops[wcpItemText] &= {{}}
    wcprops[wcpItemIcons] &= {{}}
    wcprops[wcpItemParent] &= {{}}
    wcprops[wcpItemExpand] &= {{}}
    wcprops[wcpItemHasChildren] &= {{}}
    
    wcprops[wcpVisibleItemIdx] &= {{}}
    wcprops[wcpVisibleItemIndent] &= {{}}
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
    sequence cmds, wrect, chwid, txex, txpos, trect, crect, ccenter, lpos
    atom idx, hlcolor, shcolor, bcolor, fillcolor, txtcolor, hicolor, stripecolor
    atom wh, wf, ih, iw, xp, yp, ss
    sequence vidx, vind, itmtxt, itmexpand, itmicon
    atom scry,scrx, hover, selection
    sequence iconlist
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wh = widget_get_handle(wid)
        wf = (wh = oswin:get_window_focus())
        
        wrect = widget_get_rect(wid)
        lpos = wcprops[wcpLabelPos][idx]
        trect = wcprops[wcpTreeRect][idx]
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
            
        --tree border:
            {DR_PenColor, bcolor},
            {DR_Rectangle, True, trect[1] - 1, trect[2] - 1, trect[3] - 1, trect[4] - 1},
        
            {DR_PenColor, shcolor},
            {DR_Line, trect[1], trect[2], trect[3], trect[2]},
            {DR_Line, trect[1], trect[2], trect[1], trect[4]},
            
            {DR_PenColor, hlcolor},
            
            {DR_Line, trect[3], trect[2] + 1, trect[3], trect[4]},
            {DR_Line, trect[1], trect[4], trect[3], trect[4]}

        }
        
        scrx = floor(wcprops[wcpScrollPosX][idx])
        scry = floor(wcprops[wcpScrollPosY][idx])
        
        
        --tree items:
        trect[1] += 1
        trect[2] += 1
        trect[3] -= 1
        trect[4] -= 1
        oswin:set_font(wh, "Arial", 9, Normal)
        
        cmds &= {
            {DR_Restrict} & trect,
            {DR_PenColor, th:cInnerFill},
            {DR_Rectangle, True} & trect
        }
        
        itmtxt = wcprops[wcpItemText][idx]
        itmicon = wcprops[wcpItemIcons][idx]
        itmexpand = wcprops[wcpItemExpand][idx]        

        vidx = wcprops[wcpVisibleItemIdx][idx]
        vind = wcprops[wcpVisibleItemIndent][idx] 
        
        ih = wcprops[wcpItemHeight][idx]
        iw = wcprops[wcpIndentWidth][idx]
        
        selection = wcprops[wcpSelection][idx]
        hover = wcprops[wcpHover][idx]              
        
        xp = trect[1]
        yp = trect[2]
        for i = 1 to length(vidx) do
            if yp - scry > trect[2] - ih and yp - scry - ih < trect[4] then
                if selection = i then
                    if hover = i then
                        fillcolor = th:cInnerItemOddSelHover
                        txtcolor = th:cInnerItemTextSelHover 
                    else
                        if wcprops[wcpHardFocus][idx] and wf then
                          fillcolor = th:cInnerItemOddSel
                          txtcolor = th:cInnerItemTextSel 
                        else             
                          fillcolor = th:cInnerItemOddSelInact
                          txtcolor = th:cInnerItemTextSelInact 
                        end if
                    end if
                else
                    if hover = i then
                        fillcolor = th:cInnerItemOddHover
                        txtcolor = th:cInnerItemTextHover 
                    else
                        fillcolor = th:cInnerItemOdd
                        txtcolor = th:cInnerItemText 
                    end if                 
                end if
                
                --branch control handle
                xp += vind[i] * iw
                if wcprops[wcpItemHasChildren][idx][vidx[i]] = 1 then
                    crect = {xp - scrx + 6, yp - scry + 5, xp - scrx + brctlsize - 1, yp - scry + brctlsize - 2}
                    ccenter = {crect[1] + floor((crect[3] - crect[1]) / 2), crect[2] + floor((crect[4] - crect[2]) / 2)}
                    if itmexpand[vidx[i]] = 0 then
                        cmds &= {
                            {DR_PenColor, rgb(100, 100, 0)},
                            {DR_Rectangle, False} & crect,
                            {DR_Line, crect[1] + 2, ccenter[2], crect[3] - 2, ccenter[2]},
                            {DR_Line, ccenter[1], crect[2] + 2, ccenter[1], crect[4] - 2}
                        }
                    elsif itmexpand[vidx[i]] = 1 then
                        cmds &= {
                            {DR_PenColor, rgb(100, 100, 50)},
                            {DR_Rectangle, False} & crect,
                            {DR_Line, crect[1] + 2, ccenter[2], crect[3] - 2, ccenter[2]}
                        }
                    end if
                end if
                --item icon and text
                xp += brctlsize + 2
                txex = oswin:get_text_extent(wh, itmtxt[vidx[i]])
                txex[1] += 5 + iconsize
                txex[2] += 4
                cmds &= {
                    --item background
                    {DR_PenColor, fillcolor},
                    {DR_Rectangle, True, xp - scrx, yp - scry, xp - scrx + txex[1], yp - scry + iconsize + 2}
                }
                if atom(itmicon[vidx[i]]) then
                    cmds &= {
                        --item icon - solid color
                        {DR_PenColor, itmicon[vidx[i]]},
                        {DR_Rectangle, True, xp - scrx + 1, yp - scry + 1, xp - scrx + 1 + iconsize, yp - scry + 1 + iconsize}
                    }
                elsif length(itmicon[vidx[i]]) > 0 then
                    cmds &= {
                        --item icon - image (must be 16 x 16!)
                        {DR_Image, itmicon[vidx[i]], xp - scrx + 1, yp - scry + 1, 0} --TODO: allow optional background color
                    }
                else
                    cmds &= {
                        --item icon - default solid color
                        {DR_PenColor, rgb(255, 255, 200)},
                        {DR_Rectangle, True, xp - scrx + 1, yp - scry + 1, xp - scrx + 1 + iconsize, yp - scry + 1 + iconsize}
                    }
                end if
                cmds &= {
                    --item text
                    {DR_Font, "Arial", 9, Normal},
                    {DR_TextColor, txtcolor},
                    {DR_PenPos, xp - scrx + iconsize + 3, yp - scry + 1}, --floor(iconsize / 2 - txex[2] / 2)},
                    {DR_Puts, itmtxt[vidx[i]]}
                }
            end if
            xp = trect[1]
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
    sequence ampos, wpos, wsize, wrect, lpos, trect, citem, itm
    atom idx, doredraw = 0, wh, ss, se, skip = 0
    atom th, vh, vidx
    sequence wname
    
    idx = find(wid, wcprops[wcpID])

    if idx > 0 then
        wh = widget:widget_get_handle(wid)
        wrect = widget_get_rect(wid)
        wname = widget_get_name(wid)
        
        lpos = wcprops[wcpLabelPos][idx]
        trect = wcprops[wcpTreeRect][idx]
        lpos[1] += wrect[1]
        lpos[2] += wrect[2]
        trect[1] += wrect[1]
        trect[2] += wrect[2]
        trect[3] += wrect[1]
        trect[4] += wrect[2]
        if wcprops[wcpScrollV][idx] then
            trect[3] -= scrwidth
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
                
                if in_rect(evdata[1], evdata[2], trect) then
                    citem = get_item_under_pos(wid, evdata[1], evdata[2])
                    if citem[1] > 0 then
                        if wcprops[wcpIsSelecting][idx] = 1 then
                            if wcprops[wcpSelection][idx] != citem[1] then
                                wcprops[wcpSelection][idx] = citem[1]
                                doredraw = 1
                            end if
                        else
                            if wcprops[wcpHover][idx] != citem[1] then
                                wcprops[wcpHover][idx] = citem[1]
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
                    if in_rect(evdata[1], evdata[2], trect) then
                        oswin:capture_mouse(wh)
                        citem = get_item_under_pos(wid, evdata[1], evdata[2])
                        if citem[1] > 0 then
                            vidx = wcprops[wcpVisibleItemIdx][idx][citem[1]]
                            if citem[2] = 1 then  --expand or collapse item
                                itm = {
                                    wcprops[wcpItemIDs][idx][vidx],
                                    wcprops[wcpItemText][idx][vidx],
                                    wcprops[wcpItemIcons][idx][vidx],
                                    wcprops[wcpItemParent][idx][vidx],
                                    wcprops[wcpItemExpand][idx][vidx],
                                    wcprops[wcpItemHasChildren][idx][vidx]
                                }
                                if wcprops[wcpItemExpand][idx][vidx] = 0 then
                                    wc_call_command(wid, "expand_item", {wcprops[wcpItemIDs][idx][vidx]})
                                    widget:wc_send_event(wname, "expand_item", itm)
                                elsif wcprops[wcpItemExpand][idx][vidx] = 1 then
                                    wc_call_command(wid, "collapse_item", {wcprops[wcpItemIDs][idx][vidx]})
                                    widget:wc_send_event(wname, "collapse_item", itm)
                                end if
                            else
                                wcprops[wcpIsSelecting][idx] = 1
                                wcprops[wcpSelection][idx] = citem[1]
                            end if
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
                if in_rect(evdata[1], evdata[2], trect) then
                    -------
                    doredraw = 1
                end if
                if wcprops[wcpIsSelecting][idx] = 1 then
                    wcprops[wcpIsSelecting][idx] = 0
                    send_selection_event(idx, wname, wcprops[wcpSelection][idx])
                    doredraw = 1
                end if
            
            case "LeftDoubleClick" then
                if in_rect(evdata[1], evdata[2], trect) then
                    send_double_click_event(idx, wname, wcprops[wcpSelection][idx])
                end if
                
            case "RightDown" then
                if in_rect(evdata[1], evdata[2], trect) and wcprops[wcpIsSelecting][idx] = 0 then
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
                    
                    if evdata[1] > 13 then --normal characters
                    
                    end if
                    
                    doredraw = 1
                end if
                  
            case "scroll" then
                if evdata[1] = wcprops[wcpScrollV][idx] then
                     wcprops[wcpScrollPosY][idx] = evdata[2]
                     doredraw = 1
                end if
                          
            case "changed" then 
                build_tree(wid)
                th = length(wcprops[wcpVisibleItemIdx][idx]) * wcprops[wcpItemHeight][idx]
                wcprops[wcpContentSize][idx] = {50, th}
                check_scrollbars(idx, wid)

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
        --trect = {3, txex[2] + 6, wsize[1] - 3, wsize[2] - 3}
        --lpos = {3, 3}
        
        --wcprops[wcpLabelPos][idx] = lpos
        --wcprops[wcpTreeRect][idx] = trect
        --wcprops[wcpVisibleSize][idx] = {trect[3] - trect[1], trect[4] - trect[2]}
        
        widget:widget_set_min_size(wid, wsize[1] + 6, wsize[2])
        widget:widget_set_natural_size(wid, 0, 0)

        wparent = parent_of(wid)
        if wparent > 0 then
            wc_call_resize(wparent)
        end if
    end if
end procedure


-- Fix below: -------------------------------------------------------------------

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
        
        if not equal(wcprops[wcpTreeRect][idx], trect) then
            wcprops[wcpTreeRect][idx] = trect
            check_scrollbars(idx, wid)
        end if
        
        wcprops[wcpLabelPos][idx] = {3, 3}
        
        wcprops[wcpVisibleSize][idx] = {trect[3] - trect[1], trect[4] - trect[2]}

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
            {"Label", wcprops[wcpLabel][idx]},
                               
            {"LabelPos", wcprops[wcpLabelPos][idx]},
            {"TreeRect", wcprops[wcpTreeRect][idx]},
            {"VisibleSize", wcprops[wcpVisibleSize][idx]},
            {"ContentSize", wcprops[wcpContentSize][idx]},
            {"ScrollPosX", wcprops[wcpScrollPosX][idx]},
            {"ScrollPosY", wcprops[wcpScrollPosY][idx]},
                               
            {"ItemHeight", wcprops[wcpItemHeight][idx]},
            {"IndentWidth", wcprops[wcpIndentWidth][idx]},
                               
            --{"IconList", wcprops[wcpIconList][idx]},
                               
            {"ScrollV", wcprops[wcpScrollV][idx]},
            {"ScrollH", wcprops[wcpScrollH][idx]},
                               
            {"Selection", wcprops[wcpSelection][idx]},
            {"Hover", wcprops[wcpHover][idx]},
                               
            {"ItemIDs", wcprops[wcpItemIDs][idx]},
            {"ItemText", wcprops[wcpItemText][idx]},
            {"ItemIcons", wcprops[wcpItemIcons][idx]},
            {"ItemParent", wcprops[wcpItemParent][idx]},
            {"ItemExpand", wcprops[wcpItemExpand][idx]},
            {"ItemHasChildren", wcprops[wcpItemHasChildren][idx]},
                               
            {"VisibleItemIdx", wcprops[wcpVisibleItemIdx][idx]},
            {"VisibleItemIndent", wcprops[wcpVisibleItemIndent][idx]}
        }
    end if
    return debuginfo
end function



wc_define(
    "treebox",
    routine_id("wc_create"),
    routine_id("wc_destroy"),
    routine_id("wc_draw"),
    routine_id("wc_event"),
    routine_id("wc_resize"),
    routine_id("wc_arrange"),
    routine_id("wc_debug")
)   
    

-- widgetclass commands -------------------------------------------------------



function cmd_add_item(atom wid, integer pitm, object iconid, sequence lbltxt, atom itmexpand)
    atom idx, pidx, iid = -1

    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        if pitm > 0 then
            pidx = find(pitm, wcprops[wcpItemIDs][idx])
            wcprops[wcpItemHasChildren][idx][pidx] = 1
        end if
        if pitm = 0 or pidx > 0 then
            iid = nextID(idx)
            wcprops[wcpItemIDs][idx] &= {iid}
            wcprops[wcpItemText][idx] &= {lbltxt}
            wcprops[wcpItemIcons][idx] &= {iconid}
            wcprops[wcpItemParent][idx] &= {pitm}
            wcprops[wcpItemExpand][idx] &= {itmexpand}
            wcprops[wcpItemHasChildren][idx] &= {0}

        end if
        
        wc_call_event(wid, "changed", {})
        widget:rearrange_widgets() --needed to prevent incorrect scrollbar (due to skipped arrange requests)
    end if
    return iid 
end function
wc_define_function("treebox", "add_item", routine_id("cmd_add_item"))


procedure cmd_del_item(atom wid, atom itmid)
    atom idx, itmidx, pidx
    sequence dlist, ch

    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        itmidx = find(itmid, wcprops[wcpItemIDs][idx])
        
        if itmidx > 0 then
            dlist = {itmidx}
            
            pidx = find(wcprops[wcpItemParent][idx][itmidx], wcprops[wcpItemIDs][idx])
            if pidx > 0 then
                ch = list_children(idx, wcprops[wcpItemIDs][idx][pidx])
                if length(ch) = 0 then
                    wcprops[wcpItemHasChildren][idx][pidx] = 0
                end if
            end if        
                        
            while 1 do
                for i = 1 to length(wcprops[wcpItemIDs][idx]) do
                    if wcprops[wcpItemParent][idx][i] > 0 and find(wcprops[wcpItemParent][idx][i], wcprops[wcpItemIDs][idx]) = 0 then
                        dlist &= i
                    end if
                end for
                if length(dlist) = 0 then
                    exit
                else
                    for d = length(dlist) to 1 by -1 do
                        wcprops[wcpItemIDs][idx] = remove(wcprops[wcpItemIDs][idx], dlist[d])
                        wcprops[wcpItemText][idx] = remove(wcprops[wcpItemText][idx], dlist[d])
                        wcprops[wcpItemIcons][idx] = remove(wcprops[wcpItemIcons][idx], dlist[d])
                        wcprops[wcpItemParent][idx] = remove(wcprops[wcpItemParent][idx], dlist[d])
                        wcprops[wcpItemExpand][idx] = remove(wcprops[wcpItemExpand][idx], dlist[d])
                        wcprops[wcpItemHasChildren][idx] = remove(wcprops[wcpItemHasChildren][idx], dlist[d])
                    end for
                end if
                dlist = {}
            end while
        end if
        
        wc_call_event(wid, "changed", {})
    end if
end procedure
wc_define_command("treebox", "del_item", routine_id("cmd_del_item"))


procedure cmd_clear_tree(atom wid)
    atom idx

    idx = find(wid, wcprops[wcpID])    
    if idx > 0 then
        wcprops[wcpItemIDs][idx] = {}
        wcprops[wcpItemText][idx] = {}
        wcprops[wcpItemIcons][idx] = {}
        wcprops[wcpItemParent][idx] = {}
        wcprops[wcpItemExpand][idx] = {}
        wcprops[wcpItemHasChildren][idx] = {}
        
        wc_call_event(wid, "changed", {})
    end if
end procedure
wc_define_command("treebox", "clear_tree", routine_id("cmd_clear_tree"))


procedure cmd_select_item(atom wid, atom itmid)
    atom idx, itmidx

    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        itmidx = find(itmid, wcprops[wcpItemIDs][idx])
        if itmidx > 0 then
            wcprops[wcpSelection][idx] = wcprops[wcpItemIDs][idx][itmidx]  --itmidx
        end if
        
        wc_call_event(wid, "changed", {})
    end if
end procedure
wc_define_command("treebox", "select_item", routine_id("cmd_select_item"))


procedure cmd_expand_item(atom wid, atom itmid)
    atom idx, itmidx

    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        itmidx = find(itmid, wcprops[wcpItemIDs][idx])
        if itmidx > 0 then
            wcprops[wcpItemExpand][idx][itmidx] = 1
        end if
        
        wc_call_event(wid, "changed", {})
    end if
end procedure
wc_define_command("treebox", "expand_item", routine_id("cmd_expand_item"))


procedure cmd_collapse_item(atom wid, atom itmid)
    atom idx, itmidx

    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        itmidx = find(itmid, wcprops[wcpItemIDs][idx])
        if itmidx > 0 then
            wcprops[wcpItemExpand][idx][itmidx] = 0
        end if
        
        wc_call_event(wid, "changed", {})
    end if
end procedure
wc_define_command("treebox", "collapse_item", routine_id("cmd_collapse_item"))




























