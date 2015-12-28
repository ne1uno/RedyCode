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
public include oswin/oswin.e as oswin
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
wcpSelection, --what item is selected
wcpHover,     --what item is hovered over

wcpAttachedWidget,

wcpOptStripes,
wcpOptItemHeight,
wcpOptMaxLines,

wcpAvoidRect,
wcpListRect,

wcpScrollPosX,
wcpScrollPosY,

wcpScrollV, --vertial scrollbar widgetid
wcpScrollH, --horizontal scrollbar widgetid

wcpItems

constant wcpLENGTH = wcpItems

wcprops = repeat({}, wcpLENGTH)


-- Theme variables -------------------------------

atom stripe = 1, thItemHeight = 20 --set to match treebox item height

function get_item_under_pos(atom wid, atom xpos, atom ypos)
    sequence cmds, wrect, chwid, txpos, lrect, irect
    atom idx, hlcolor, shcolor, fillcolor, txtcolor, hicolor
    atom ih, xp, yp, ss, citem = 0
    sequence itexts
    atom scry,scrx
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wrect = {0, 0} & widget_get_size(wid)
        --wrect[3] -= 1
        --wrect[4] -= 1
        lrect = wcprops[wcpListRect][idx]
        lrect[1] += wrect[1]
        lrect[2] += wrect[2]
        lrect[3] += wrect[1]
        lrect[4] += wrect[2]

        ih = wcprops[wcpOptItemHeight][idx]
        itexts = wcprops[wcpItems][idx]
        
        scrx = floor(wcprops[wcpScrollPosX][idx])
        scry = floor(wcprops[wcpScrollPosY][idx])

        --list items:   --iids, itexts, iicons, iselected
        yp = lrect[2]         
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


-- widgetclass handlers ----------------------------

procedure wc_create(atom wid, object wprops) 
    atom wAttachedWidget = 0, wOptMaxLines = 20, orientation = 0, wparent, cy, maxx = 100, winhandle, wph, scrollV
    sequence wsize = {6, 6}, litems = {}, avrect = {0, 0, 0, 0}, lrect = {0, 0, 0, 0}

    --wph = widget:widget_get_handle(wid) --widget:parent_of(wid))
    
    --oswin:menu_active(1)
    winhandle = oswin:create_window(wid, "", "popup", 0, 0, 6, 6, th:cOuterFill) --, wph)
    --winhandle = oswin:create_window(wid, "", "normal", 0, 0, 6, 6, th:cOuterFill) --, wph)
    widget:widget_set_handle(wid, winhandle)
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do          
                case "items" then
                    litems = wprops[p][2]
                case "avoid" then
                    avrect = wprops[p][2]
                case "max_lines" then
                    wOptMaxLines = wprops[p][2]  
                case "attach" then
                    wAttachedWidget = wprops[p][2]
            end switch
        end if
    end for
    
    wcprops[wcpID] &= wid
    wcprops[wcpSoftFocus] &= 0
    wcprops[wcpHardFocus] &= 0
    wcprops[wcpIsSelecting] &= 0
    wcprops[wcpSelection] &= 0
    wcprops[wcpHover] &= 0
    
    wcprops[wcpAttachedWidget] &= wAttachedWidget
    
    wcprops[wcpOptStripes] &= 0
    wcprops[wcpOptItemHeight] &= thItemHeight
    wcprops[wcpOptMaxLines] &= {wOptMaxLines}
    
    wsize = {avrect[3] - avrect[1], min({wcprops[wcpOptItemHeight][$]*length(litems) + 4, wcprops[wcpOptItemHeight][$]*wOptMaxLines + 4})}
    widget:widget_set_size(wid, wsize[1], wsize[2])
    set_window_pos(winhandle, avrect[1], avrect[4])
    set_window_size(winhandle, wsize[1], wsize[2])
    set_window_title(winhandle, "")

    lrect = {2, 2, wsize[1]-2, wsize[2]-2}
    wcprops[wcpAvoidRect] &= {avrect}
    wcprops[wcpListRect] &= {lrect}

    wcprops[wcpItems] &= {litems}
        
    wcprops[wcpScrollPosX] &= 0
    wcprops[wcpScrollPosY] &= 0
    
    if length(litems) > wOptMaxLines then
        scrollV = widget:widget_create(widget_get_name(wid) & ".scrV", wid, "scrollbar", {
            {"attach", wid},
            {"orientation", 0},
            {"min", 0}
            --{"max", 30},
            --{"value", 0},
            --{"range", 10} 
            --{"length", 0}
        })
    else
        scrollV = 0
    end if
    wcprops[wcpScrollV] &= scrollV
    wcprops[wcpScrollH] &= 0
    
    oswin:show_window(winhandle)
    oswin:enable_close(winhandle, 1)
        
    --wc_call_draw(wid)
    --wc_call_draw(parent_of(wid))
    
    --set up list and scrollbar:
    wc_call_command(scrollV, "set_max", length(litems) * thItemHeight)
    wc_call_command(scrollV, "set_range", lrect[4] - lrect[2])
    wc_call_command(scrollV, "set_value", 0)
    
    widget:wc_call_arrange(wid)    

    
    wparent = parent_of(wid)
    if wparent > 0 then
        widget:wc_call_event(wparent, "child created", {wid, wprops})
    end if

end procedure


procedure wc_destroy(atom wid)
    atom idx, wh
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        for p = 1 to wcpLENGTH do
            wcprops[p] = remove(wcprops[p], idx)
        end for
        wh = widget_get_handle(wid)
        oswin:enable_close(wh, 1)
        oswin:destroy_window(wh)
        --oswin:menu_active(0)
    end if
end procedure


procedure wc_draw(atom wid)
    sequence cmds, wrect, chwid, txpos, lrect, irect, itexts
    atom idx, hlcolor, shcolor, fillcolor, txtcolor, hicolor, stripecolor
    atom ih, xp, yp, ss, scry,scrx, hover, selection
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wrect = {0, 0} & widget_get_size(wid)
        lrect = wcprops[wcpListRect][idx]
        lrect[1] += wrect[1]
        lrect[2] += wrect[2]
        lrect[3] += wrect[1]
        lrect[4] += wrect[2]
        
        
        if wcprops[wcpHardFocus][idx] then
            hicolor = th:cOuterActive
        elsif wcprops[wcpSoftFocus][idx] then
            hicolor = th:cOuterHover
        else
            hicolor = th:cOuterFill
        end if
        
        shcolor = th:cButtonShadow
        hlcolor = th:cButtonHighlight

        
        cmds = {
        --fill:
            {DR_PenColor, rgb(128,128,180)},
            {DR_Rectangle, True} & wrect,
          
            
        --text border:
            {DR_PenColor, shcolor},
            {DR_Line, wrect[1] + 1, wrect[2] + 1, wrect[3] - 2, wrect[2] + 1},
            {DR_Line, wrect[1] + 1, wrect[2] + 1, wrect[1] + 1, wrect[4] - 2},
            
            {DR_PenColor, hlcolor},
            
            {DR_Line, wrect[3] - 2, wrect[2] + 1, wrect[3] - 2, wrect[4] - 2},
            {DR_Line, wrect[1] + 1, wrect[4] - 2, wrect[3] - 1, wrect[4] - 2},
        
            {DR_Restrict} & lrect,
            {DR_PenColor, th:cInnerFill},
            {DR_Rectangle, True} & lrect
        }

        ih = wcprops[wcpOptItemHeight][idx]
        itexts = wcprops[wcpItems][idx]
        
        scrx = floor(wcprops[wcpScrollPosX][idx])
        scry = floor(wcprops[wcpScrollPosY][idx])
        
        selection = wcprops[wcpSelection][idx]
        hover = wcprops[wcpHover][idx]
        
        xp = lrect[1]
        yp = lrect[2]
        
        --list items:
        cmds &= {
            {DR_Font, "Arial", 9, Normal},
            {DR_Restrict, xp, yp, lrect[3], lrect[4]},
            {DR_PenColor, cOuterFill},
            {DR_Rectangle, True} & lrect
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
                if li = selection then
                    if li = hover then
                        if stripecolor = 1 then
                          fillcolor = th:cInnerItemOddSelHover
                        else
                          fillcolor = th:cInnerItemEvenSelHover
                        end if
                        txtcolor = th:cInnerItemTextSelHover 
                    else
                        if wcprops[wcpHardFocus][idx] then
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
                    {DR_Rectangle, True, lrect[1], yp - scry, lrect[3], yp - scry + ih},
                    {DR_TextColor, txtcolor}
                }
                
                cmds &= {
                    {DR_PenPos, xp - scrx + 2, yp - scry + 2},
                    {DR_Puts, itexts[li]}
                }
            end if
            xp = lrect[1]
            yp += ih
        end for
        
        cmds &= {
            {DR_Release}
        }              
        draw(widget:widget_get_handle(wid), cmds)
        
        chwid = children_of(wid)
        for ch = 1 to length(chwid) do
            wc_call_draw(chwid[ch])
        end for
    end if
end procedure


procedure wc_event(atom wid, sequence evtype, object evdata)
    sequence ampos, wrect, lpos, lrect, litems, wsize, wpos
    atom idx, doredraw = 0, wh, ss, se, skip = 0, citem, winhandle, wparent, cy, th, vh
    sequence wname    
    
    idx = find(wid, wcprops[wcpID])

    if idx > 0 then
        wh = widget:widget_get_handle(wid)
        wrect = {0, 0} & widget_get_size(wid)
        --wrect[3] -= 1
        --wrect[4] -= 1

        litems = wcprops[wcpItems][idx]
        lrect = wcprops[wcpListRect][idx]
        lrect[1] += wrect[1]
        lrect[2] += wrect[2]
        lrect[3] += wrect[1]
        lrect[4] += wrect[2]
        
        switch evtype do        
            case "MouseMove" then --{x, y, shift, mousepos[1], mousepos[2]}
                --wcprops[wcpSoftFocus][idx] = 0
                --wcprops[wcpPressed][idx] = 0
                
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
                                
                if in_rect(evdata[1], evdata[2], lrect) then
                    citem = get_item_under_pos(wid, evdata[1], evdata[2])
                    if citem > 0 then
                        if wcprops[wcpIsSelecting][idx] = 1 then
                            wcprops[wcpSelection][idx] = citem
                        else
                            wcprops[wcpHover][idx] = citem
                        end if
                    end if
                    doredraw = 1
                else
                    if wcprops[wcpHover][idx] > 0 then
                        wcprops[wcpHover][idx] = 0
                        doredraw = 1
                    end if
                end if

                
                
            case "NonClientMouseMove" then
                if wcprops[wcpSoftFocus][idx] = 1 then
                    wcprops[wcpSoftFocus][idx] = 0
                    wcprops[wcpSelection][idx] = 0
                    doredraw = 1                    
                end if
                

                
            case "LeftDown" then
                 if in_rect(evdata[1], evdata[2], wrect) then
                    if in_rect(evdata[1], evdata[2], lrect) then
                        oswin:capture_mouse(wh)
                        wcprops[wcpIsSelecting][idx] = 1
                        citem = get_item_under_pos(wid, evdata[1], evdata[2])
                        if citem > 0 then
                            wcprops[wcpSelection][idx] = citem
                            doredraw = 1   
                        end if
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
                
            case "LeftUp" then
                if in_rect(evdata[1], evdata[2], lrect) then
                    doredraw = 1
                end if
                if wcprops[wcpIsSelecting][idx] = 1 then
                    wcprops[wcpIsSelecting][idx] = 0
                    --sesid = widget_get_name(wid)
                    widget:wc_call_event(wcprops[wcpAttachedWidget][idx], "selection", {wid, wcprops[wcpSelection][idx], wcprops[wcpItems][idx][wcprops[wcpSelection][idx]]})
                    doredraw = 1
                    widget:widget_destroy(wid)
                end if
                
            case "scroll" then
                if evdata[1] = wcprops[wcpScrollV][idx] then
                     wcprops[wcpScrollPosY][idx] = evdata[2]
                     doredraw = 1
                end if                  
                
            case "WheelMove" then
                if wcprops[wcpSoftFocus][idx] > 0 then
                    wc_call_command(wcprops[wcpScrollV][idx], "set_value_rel", -evdata[2]*wcprops[wcpOptItemHeight][idx])
                end if
            
            case "LostFocus" then
                wcprops[wcpSoftFocus][idx] = 0
                doredraw = 1
                
            case "Close" then
                --widget:wc_call_event(widget:parent_of(wid), "list_closed", {})
                widget:widget_destroy(wid)
                return
                
            case else
                
        end switch
        
        if doredraw = 1 then
            wc_call_draw(wid)
        end if
    end if
end procedure


procedure wc_resize(atom wid)
    integer idx

    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        --wc_call_draw(wid)
    end if
end procedure


procedure wc_arrange(atom wid)
    atom idx, th, vh, scrwidth = 16 --hard-coded for now, but this will be a theme variable
    sequence wpos, wsize, lrect
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then        
        --arrange:
        wpos = {0, 0} --widget_get_pos(wid)
        wsize = widget_get_size(wid)
        
        if wcprops[wcpScrollV][idx] then
            wcprops[wcpListRect][idx][3] = wsize[1] - scrwidth - 2
            widget_set_pos(wcprops[wcpScrollV][idx], wpos[1] + wcprops[wcpListRect][idx][3], wpos[2] + wcprops[wcpListRect][idx][2])
            widget_set_size(wcprops[wcpScrollV][idx], scrwidth, wcprops[wcpListRect][idx][4] - wcprops[wcpListRect][idx][2])
        end if
        
        if wcprops[wcpScrollH][idx] then
            wcprops[wcpListRect][idx][4] = wsize[2] - scrwidth - 2
            widget_set_pos(wcprops[wcpScrollH][idx], wpos[1] + wcprops[wcpListRect][idx][1], wpos[2] + wcprops[wcpListRect][idx][4])
            widget_set_size(wcprops[wcpScrollH][idx], wcprops[wcpListRect][idx][3] - wcprops[wcpListRect][idx][1], scrwidth)
        end if
        if wcprops[wcpScrollV][idx] then
            wc_call_arrange(wcprops[wcpScrollV][idx])
        end if
        if wcprops[wcpScrollH][idx] then
            wc_call_arrange(wcprops[wcpScrollH][idx])
        end if
    end if
    wc_call_draw(wid)
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
            {"Selection", wcprops[wcpSelection][idx]},
            {"Hover", wcprops[wcpHover][idx]},
            
            {"AttachedWidget", wcprops[wcpAttachedWidget][idx]},
            
            {"OptStripes", wcprops[wcpOptStripes][idx]},
            {"OptItemHeight", wcprops[wcpOptItemHeight][idx]},
            {"OptMaxLines", wcprops[wcpOptMaxLines][idx]},
            
            {"AvoidRect", wcprops[wcpAvoidRect][idx]},
            {"ListRect", wcprops[wcpListRect][idx]},
            
            {"ScrollPosX", wcprops[wcpScrollPosX][idx]},
            {"ScrollPosY", wcprops[wcpScrollPosY][idx]},
            
            {"ScrollV", wcprops[wcpScrollV][idx]},
            {"ScrollH", wcprops[wcpScrollH][idx]},
            
            {"Items", wcprops[wcpItems][idx]}
        }
    end if
    return debuginfo
end function



wc_define(
    "list",
    routine_id("wc_create"),
    routine_id("wc_destroy"),
    routine_id("wc_draw"),
    routine_id("wc_event"),
    routine_id("wc_resize"),
    routine_id("wc_arrange"),
    routine_id("wc_debug")
)   
    

-- widgetclass commands -------------------------------------------------------

--procedure cmd_resize(atom wid, atom width, atom height)
--  oswin:set_window_size(widget_get_handle(wid), width, height)
--end procedure
--wc_define_command("container", "maximize", routine_id("wc_maximize"))

