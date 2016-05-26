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
include std/text.e

-- Internal class variables and routines

sequence wcprops

enum
    wcpID,
    wcpSoftFocus,
    wcpHardFocus,
    wcpKeyFocus,
    
    wcpLabel,
    wcpShowBorder,           --1 = show border and, if specified, a lable. 0 = no border (tabs rect covers the entire widget rect)
    wcpTabWidgets,  --list of widget ids of containers or panels assocciated with each tab page
    wcpTabLabels,
    wcpTabFlags,   --colored spot on each tab
    wcpTabWidths,
    
    wcpSelectedTab,
    
    wcpLabelPos,
    wcpTabsRect,
    wcpVisibleSize, --size of visible area
    wcpContentSize, --size of actual content
    wcpScrollXEnabled,
    wcpScrollYEnabled,
    wcpScrollPosX,
    wcpScrollPosY,
 
    wcpScrollV, --vertial scrollbar widgetid
    wcpScrollH --horizontal scrollbar widgetid
    
constant wcpLENGTH = wcpScrollH

wcprops = repeat({}, wcpLENGTH)

-- Theme variables -------------------------------

atom
thBoxSize = 14,
BoxOffset = 3,
InnerBox = 3,
TabGap = 12,
optScrollIncrement = 32,
headingheight = 22,
thFlagSize = 7


-- local routines ---------------------------------------------------------------------------


procedure select_tab(atom idx, atom wid, atom tabidx)
    wcprops[wcpSelectedTab][idx] = tabidx
    
    if tabidx = 0 then
         wc_call_resize(wid)
         widget:wc_send_event(widget_get_name(wid), "selection", 0)
    else
        for t = 1 to length(wcprops[wcpTabWidgets][idx]) do
            if t = tabidx then
                widget_show(wcprops[wcpTabWidgets][idx][t])
                wc_call_resize(wcprops[wcpTabWidgets][idx][t])
                --wc_call_arrange(wcprops[wcpTabWidgets][idx][t])
                widget:wc_send_event(widget_get_name(wid), "selection", wcprops[wcpTabWidgets][idx][t])
            else
                widget_hide(wcprops[wcpTabWidgets][idx][t])
            end if
        end for
    end if
end procedure


function tab_under_mouse(atom idx, atom wid, sequence trect, atom mx, atom my)
    atom mousetab = 0, tx = trect[1]-5, ty = trect[2] + 1
    sequence box
    
    for t = 1 to length(wcprops[wcpTabWidgets][idx]) do
        box = {tx, ty, tx + wcprops[wcpTabWidths][idx][t], ty + headingheight-2}
        if in_rect(mx, my, box) then
            mousetab = t
            exit
        end if
        
        tx += wcprops[wcpTabWidths][idx][t]
    end for
    
    return mousetab
end function


procedure check_scrollbars(atom idx, atom wid)
--check contents and size of widget to determine if scrollbars are needed, then create or destroy scrollbars when required.
    sequence wpos, wsize, trect, csize, vsize
    atom needV = 0, needH = 0
    
    wpos = widget_get_pos(wid)
    wsize = widget_get_size(wid)
    trect = wcprops[wcpTabsRect][idx]
    csize = wcprops[wcpContentSize][idx]
    vsize = wcprops[wcpVisibleSize][idx]
    if csize[1] > vsize[1] then
        needH = 1
    end if
    if csize[2] > vsize[2] then
        needV = 1
    end if
    if needH = 1 then
        vsize[2] -= scrwidth
    end if
    if needV = 1 then
        vsize[1] -= scrwidth
    end if
    if csize[1] > vsize[1] then
        needH = 1
    end if
    if csize[2] > vsize[2] then
        needV = 1
    end if
    if needH = 1 and wcprops[wcpScrollH][idx] = 0 then
        wcprops[wcpScrollH][idx] = widget:widget_create(widget_get_name(wid) & ".scrH", wid, "scrollbar", {
            {"attach", wid},
            {"orientation", 1},
            {"min", 0}
            --{"position", {wpos[1] + trect[1]+1, wpos[2] + trect[2]+1}}
            --{"position", {wpos[1] + trect[3]+1, wpos[2] + trect[2]}}
        })
        --widget_set_size(wcprops[wcpScrollH][idx], scrwidth, vsize[1])
        wc_call_arrange(wcprops[wcpScrollH][idx])
    elsif needH = 0 and wcprops[wcpScrollH][idx] > 0 then
        widget:widget_destroy(wcprops[wcpScrollH][idx])
        wcprops[wcpScrollH][idx] = 0
        wcprops[wcpScrollPosX][idx] = 0
    end if
    if needV = 1 and wcprops[wcpScrollV][idx] = 0 then
        wcprops[wcpScrollV][idx] = widget:widget_create(widget_get_name(wid) & ".scrV", wid, "scrollbar", {
            {"attach", wid},
            {"orientation", 0},
            {"min", 0}
            --{"position", {wpos[1] + trect[3]+1, wpos[2] + trect[2]}}
            --{"size", {scrwidth, wcprops[wcpVisibleSize][idx][2]}}
        })
        --widget_set_size(wcprops[wcpScrollV][idx], scrwidth, vsize[2])
        wc_call_arrange(wcprops[wcpScrollV][idx])
    elsif needV = 0 and wcprops[wcpScrollV][idx] > 0 then
        widget:widget_destroy(wcprops[wcpScrollV][idx])
        wcprops[wcpScrollV][idx] = 0
        wcprops[wcpScrollPosY][idx] = 0
    end if
    if wcprops[wcpScrollH][idx] > 0 then
        wc_call_command(wcprops[wcpScrollH][idx], "set_max", csize[1])
        wc_call_command(wcprops[wcpScrollH][idx], "set_range", vsize[1])
        wc_call_command(wcprops[wcpScrollH][idx], "set_value", wcprops[wcpScrollPosX][idx])
    end if
    if wcprops[wcpScrollV][idx] > 0 then
        wc_call_command(wcprops[wcpScrollV][idx], "set_max", csize[2])
        wc_call_command(wcprops[wcpScrollV][idx], "set_range", vsize[2])
        wc_call_command(wcprops[wcpScrollV][idx], "set_value", wcprops[wcpScrollPosY][idx])
    end if
end procedure


-- widgetclass handlers ----------------------------

procedure wc_create(atom wid, object wprops) 
    atom wh, wshowborder = 1, whandleroutine = 0, wbackgroundpointer = mArrow,
    whandledebug = 0, wpreformancedebug = 0, wscrollforeground = 1
    sequence wname, wbackgroundimage, whandleimage, wlabel = ""
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do         
                case "label" then
                    wlabel = wprops[p][2]
                    
                case "border" then
                    wshowborder = wprops[p][2]
                    
            end switch
        end if
    end for
    
    wh = widget:widget_get_handle(wid)
    wname = widget:widget_get_name(wid)
    
    wcprops[wcpID] &= {wid}
    wcprops[wcpSoftFocus] &= {0}
    wcprops[wcpHardFocus] &= {0}
    wcprops[wcpKeyFocus] &= {0}
    
    wcprops[wcpLabel] &= {wlabel}
    wcprops[wcpShowBorder] &= {wshowborder}
    wcprops[wcpTabWidgets] &= {{}}
    wcprops[wcpTabLabels] &= {{}}
    wcprops[wcpTabFlags] &= {{}}
    wcprops[wcpTabWidths] &= {{}}
    
    wcprops[wcpSelectedTab] &= {0}
    
    wcprops[wcpLabelPos] &= {{0, 0}}
    wcprops[wcpTabsRect] &= {{0, 0, 0, 0}}
    wcprops[wcpVisibleSize] &= {{0, 0}}
    wcprops[wcpContentSize] &= {{0, 0}}
    wcprops[wcpScrollXEnabled] &= {0}
    wcprops[wcpScrollYEnabled] &= {0}
    wcprops[wcpScrollPosX] &= {0}
    wcprops[wcpScrollPosY] &= {0}

    wcprops[wcpScrollV] &= {0}
    wcprops[wcpScrollH] &= {0}
end procedure


procedure wc_destroy(atom wid)
    atom idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        
        for p = 1 to wcpLENGTH do
            wcprops[p] = remove(wcprops[p], idx)
        end for
    end if
end procedure


procedure wc_draw(atom wid)
    sequence cmds = {}, wrect, trect, chwid, txex, txpos, lrect, lpos, irect, box
    atom idx = find(wid, wcprops[wcpID]), wh, wf, hlcolor, shcolor, fillcolor, txtcolor, hicolor --, stripecolor
    --atom ih, xp, yp, ss
    --sequence clabels, cwidths, csort,
    atom scry,scrx, hover
    
    if idx > 0 then
        wrect = widget_get_rect(wid)
        --wrect[3] -= 1
        --wrect[4] -= 1
        
        wh = widget:widget_get_handle(wid)
        wf = (wh = oswin:get_window_focus())
        
        if wcprops[wcpShowBorder][idx] = 1 then
            lpos = wcprops[wcpLabelPos][idx]
            lrect = wcprops[wcpTabsRect][idx]
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
            
            --if wcprops[wcpHardFocus][idx] and wf then
            --    hicolor = th:cOuterActive
            --elsif wcprops[wcpSoftFocus][idx] then
            --    hicolor = th:cOuterHover
            --else
            hicolor = th:cOuterFill
            --end if
            
            shcolor = th:cButtonShadow
            hlcolor = th:cButtonHighlight
            
            --draw border and label:
            cmds &= {
            --fill:
                {DR_PenColor, hicolor},
                {DR_Rectangle, True} & wrect
            }
            
            if equal(widget:widget_get_class(widget:parent_of(wid)), "window") then
                box = {wrect[1] + 2 + BoxOffset, wrect[2] + 2 + BoxOffset, wrect[1] + 2 + BoxOffset + thBoxSize, wrect[2] + 2 + BoxOffset + thBoxSize}
                trect = {wrect[1] + 2, wrect[2] + 2, wrect[3] - 2, wrect[2] + 2 + headingheight - 2}
                cmds &= {
                --handle:
                    {DR_PenColor, hlcolor},
                    {DR_Line, box[1] + 1, box[2], box[3] - 1, box[2]},
                    {DR_Line, box[1], box[2] + 1, box[1], box[4] - 1},
                    
                    {DR_Line, box[3] - 1 - InnerBox, box[2] + InnerBox, box[3] - 1 - InnerBox, box[4] - 1 - InnerBox},
                    {DR_Line, box[1] + InnerBox, box[4] - 1 - InnerBox, box[3] - 1 - InnerBox, box[4] - 1 - InnerBox}, 
                    
                    {DR_PenColor, shcolor},
                    
                    {DR_Line, box[3] - 1, box[2], box[3] - 1, box[4] - 1},
                    {DR_Line, box[1], box[4] - 1, box[3] - 1, box[4] - 1}, 
                    
                    {DR_Line, box[1] + 1 + InnerBox, box[2] + InnerBox, box[3] - 1 - InnerBox, box[2] + InnerBox},
                    {DR_Line, box[1] + InnerBox, box[2] + 1 + InnerBox, box[1] + InnerBox, box[4] - 1 - InnerBox},
                    
                    --label area border    
                    {DR_PenColor, shcolor},
                    {DR_Line, trect[1] + 1, trect[2], trect[3] - 1, trect[2]},
                    {DR_Line, trect[1], trect[2] + 1, trect[1], trect[4] - 1},
                     
                    {DR_PenColor, hlcolor},
                    {DR_Line, trect[3] - 1, trect[2], trect[3] - 1, trect[4] - 1},
                    {DR_Line, trect[1], trect[4] - 1, trect[3] - 1, trect[4] - 1}
                    
                /*--inner lable area border
                    {DR_PenColor, hlcolor},
                    {DR_Line, trect[1] + headingheight - 3 + 1, trect[2] + 1, trect[3] - 1, trect[2] + 1},
                    {DR_Line, trect[1] + headingheight - 3, trect[2] + 1 + 1, trect[1] + headingheight - 3, trect[4] - 1 - 1},
                     
                    {DR_PenColor, shcolor},
                    {DR_Line, trect[3] - 1 - 1, trect[2] + 1, trect[3] - 1 - 1, trect[4] - 1 - 1},
                    {DR_Line, trect[1] + headingheight - 3, trect[4] - 1 - 1, trect[3] - 1 - 1, trect[4] - 1 - 1}*/
                }
                
                trect = {wrect[1] + 2 + headingheight + 2, wrect[2] + 2, wrect[3] - 2, wrect[2] + 2 + headingheight - 2}
            else
                trect = {wrect[1] + 10, wrect[2] + 2, wrect[3] - 2, wrect[2] + 3 + headingheight}
            end if
            
            cmds &= {
            --border:
                {DR_PenColor, hlcolor},
                {DR_Line, lrect[1]-1, lrect[2]-1, lrect[3], lrect[2]-1},
                {DR_Line, lrect[1]-1, lrect[2]-1, lrect[1]-1, lrect[4]},
                {DR_PenColor, shcolor},
                {DR_Line, lrect[3], lrect[2]-1, lrect[3], lrect[4]},
                {DR_Line, lrect[1]-1, lrect[4], lrect[3], lrect[4]}
            }
            
            atom tx = trect[1]-5, ty = trect[2] + 1
            
            for t = 1 to length(wcprops[wcpTabWidgets][idx]) do
                if wcprops[wcpSelectedTab][idx] = t then
                    hicolor = th:cOuterActive
                    box = {tx, ty, tx + wcprops[wcpTabWidths][idx][t], ty + trect[4] - trect[2]} --+ headingheight-2}
                    cmds &= {
                    --background:
                        {DR_PenColor, hicolor},
                        {DR_Rectangle, True, box[1], box[2], box[3], box[4]-1}
                    }
                    --Flag:
                    if wcprops[wcpTabFlags][idx][t] >= 0 then
                        cmds &= {
                            {DR_PenColor, wcprops[wcpTabFlags][idx][t]},
                            {DR_BrushColor, wcprops[wcpTabFlags][idx][t]},
                            {DR_PolyLine, True, {
                                {box[1]+1, box[2]+1},
                                {box[1]+thFlagSize, box[2]+1},
                                {box[1]+1, box[2]+thFlagSize},
                                {box[1]+1, box[2]+1}
                            }}
                        }
                    end if
                    cmds &= {
                    --label:
                        {DR_Font, "Arial", 9, Normal},
                        {DR_TextColor, th:cOuterLabel},
                        {DR_PenPos} & {tx + floor(TabGap/2), ty + 3}, --todo: account for different font sizes
                        {DR_Puts, wcprops[wcpTabLabels][idx][t]},
                    --label area border    
                        {DR_PenColor, hlcolor},
                        {DR_Line, box[1] + 1, box[2], box[3] - 1, box[2]},
                        {DR_Line, box[1], box[2] + 1, box[1], box[4] - 2},
                         
                        {DR_PenColor, shcolor},
                        {DR_Line, box[3] - 1, box[2], box[3] - 1, box[4] - 2}
                    /*--erase line under tab
                        {DR_PenColor, hicolor},
                        {DR_Line, box[1], box[4]-1, box[3] - 1, box[4]-1},
                        {DR_Line, box[1], box[4]-3, box[3] - 1, box[4]-3},
                        {DR_Line, box[1], box[4]-2, box[3] - 1, box[4]-2}
                      */  
                    }
                else
                    hicolor = th:cOuterFill
                    box = {tx, ty+2, tx + wcprops[wcpTabWidths][idx][t], ty + trect[4] - trect[2]} --+ headingheight-2}
                    cmds &= {
                    --background:
                        {DR_PenColor, hicolor},
                        {DR_Rectangle, True, box[1], box[2], box[3], box[4]-2}
                    }
                    --Flag:
                    if wcprops[wcpTabFlags][idx][t] >= 0 then
                        cmds &= {
                            {DR_PenColor, wcprops[wcpTabFlags][idx][t]},
                            {DR_BrushColor, wcprops[wcpTabFlags][idx][t]},
                            {DR_PolyLine, True, {
                                {box[1]+1, box[2]+1},
                                {box[1]+thFlagSize, box[2]+1},
                                {box[1]+1, box[2]+thFlagSize},
                                {box[1]+1, box[2]+1}
                            }}
                        }
                    end if
                    cmds &= {
                    --label:
                        {DR_Font, "Arial", 9, Normal},
                        {DR_TextColor, th:cOuterLabel},
                        {DR_PenPos} & {tx + floor(TabGap/2), ty + 3},
                        {DR_Puts, wcprops[wcpTabLabels][idx][t]},
                    --label area border    
                        {DR_PenColor, hlcolor},
                        {DR_Line, box[1] + 1, box[2], box[3] - 1, box[2]},
                        {DR_Line, box[1], box[2] + 1, box[1], box[4] - 2},
                         
                        {DR_PenColor, shcolor},
                        {DR_Line, box[3] - 1, box[2], box[3] - 1, box[4] - 2}
                    }
                end if
                    

                
                tx += wcprops[wcpTabWidths][idx][t]
            end for

        else  --don't show border or label (use entire widget rect for the drawing area)
            lrect = wrect 
        end if
        
        draw(wh, cmds)
        
        chwid = children_of(wid)
        for ch = 1 to length(chwid) do
            wc_call_draw(chwid[ch])
        end for
    end if
end procedure


procedure wc_event(atom wid, sequence evtype, object evdata)
    sequence ampos, wrect, lpos, lrect, txex, trect
    atom idx = find(wid, wcprops[wcpID]), doredraw = 0, wh, ss, se, skip = 0, citem
    atom th, vh, hidx
    sequence wname, hname
    
    if idx > 0 then
        wh = widget:widget_get_handle(wid)
        wrect = widget_get_rect(wid)
        --wrect[3] -= 1
        --wrect[4] -= 1
        if wcprops[wcpShowBorder][idx] = 1 then
            lpos = wcprops[wcpLabelPos][idx]
            lrect = wcprops[wcpTabsRect][idx]
            lpos[1] += wrect[1]
            lpos[2] += wrect[2]
            lrect[1] += wrect[1]
            lrect[2] += wrect[2]
            lrect[3] += wrect[1]
            lrect[4] += wrect[2]
        else
            lrect = wrect
        end if
        if wcprops[wcpScrollH][idx] then
            lrect[4] -= scrwidth
        end if
        if wcprops[wcpScrollV][idx] then
            lrect[3] -= scrwidth
        end if
        
        if equal(widget:widget_get_class(widget:parent_of(wid)), "window") then
            trect = {wrect[1] + 2 + headingheight + 2, wrect[2] + 2, wrect[3] - 2, wrect[2] + 2 + headingheight - 2}
        else
            trect = {wrect[1] + 8, wrect[2] + 2, wrect[3] - 2, wrect[2] + 2 + headingheight - 2}
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
                
            case "LeftDown" then        
                if in_rect(evdata[1], evdata[2], wrect) then
                    if wcprops[wcpHardFocus][idx] = 0 then
                        wcprops[wcpHardFocus][idx] = 1
                        --widget:set_key_focus(wid)
                        doredraw = 1
                    end if
                    
                    atom mousetab = tab_under_mouse(idx, wid, trect, evdata[1], evdata[2])
                    if mousetab > 0 then
                        select_tab(idx, wid, mousetab)
                        --doredraw = 1
                        --wc_call_arrange(wid)
                    end if
                else
                    if wcprops[wcpHardFocus][idx] = 1 then
                        wcprops[wcpHardFocus][idx] = 0
                        doredraw = 1
                    end if
                end if

            case "LeftUp" then      
                --todo: drag tab to new position
                if in_rect(evdata[1], evdata[2], wrect) then
                    if wcprops[wcpHardFocus][idx] = 0 then
                        wcprops[wcpHardFocus][idx] = 1
                        doredraw = 1
                    end if
                    atom mousetab = tab_under_mouse(idx, wid, trect, evdata[1], evdata[2])
                    if mousetab > 0 then
                        widget:wc_send_event(widget_get_name(wid), "LeftUp", wcprops[wcpTabWidgets][idx][mousetab])
                    end if
                end if
                
            case "LeftDoubleClick" then
                if in_rect(evdata[1], evdata[2], wrect) then
                    if wcprops[wcpHardFocus][idx] = 0 then
                        wcprops[wcpHardFocus][idx] = 1
                        doredraw = 1
                    end if
                    atom mousetab = tab_under_mouse(idx, wid, trect, evdata[1], evdata[2])
                    if mousetab > 0 then
                        widget:wc_send_event(widget_get_name(wid), "LeftDoubleClick", wcprops[wcpTabWidgets][idx][mousetab])
                    end if
                end if
                
            case "RightDown" then        
                if in_rect(evdata[1], evdata[2], wrect) then
                    if wcprops[wcpHardFocus][idx] = 0 then
                        wcprops[wcpHardFocus][idx] = 1
                        doredraw = 1
                    end if
                    atom mousetab = tab_under_mouse(idx, wid, trect, evdata[1], evdata[2])
                    if mousetab > 0 then
                        widget:wc_send_event(widget_get_name(wid), "RightDown", wcprops[wcpTabWidgets][idx][mousetab])
                    end if
                end if

            case "RightUp" then      
                if in_rect(evdata[1], evdata[2], wrect) then
                    if wcprops[wcpHardFocus][idx] = 0 then
                        wcprops[wcpHardFocus][idx] = 1
                        doredraw = 1
                    end if
                    atom mousetab = tab_under_mouse(idx, wid, trect, evdata[1], evdata[2])
                    if mousetab > 0 then
                        widget:wc_send_event(widget_get_name(wid), "RightUp", wcprops[wcpTabWidgets][idx][mousetab])
                    end if
                end if
                
            case "RightDoubleClick" then
                if in_rect(evdata[1], evdata[2], wrect) then
                    if wcprops[wcpHardFocus][idx] = 0 then
                        wcprops[wcpHardFocus][idx] = 1
                        doredraw = 1
                    end if
                    atom mousetab = tab_under_mouse(idx, wid, trect, evdata[1], evdata[2])
                    if mousetab > 0 then
                        widget:wc_send_event(widget_get_name(wid), "RightDoubleClick", wcprops[wcpTabWidgets][idx][mousetab])
                    end if
                end if
                
            case "WheelMove" then
                if wcprops[wcpSoftFocus][idx] > 0 then
                    wc_call_command(wcprops[wcpScrollV][idx], "set_value_rel", -evdata[2] * optScrollIncrement)
                end if
            
            case "KeyDown" then
                
            case "KeyPress" then
                
            case "scroll" then
                if evdata[1] = wcprops[wcpScrollH][idx] then
                    wcprops[wcpScrollPosX][idx] = evdata[2]
                    doredraw = 1
                    wname = widget_get_name(wid)
                    widget:wc_send_event(wname, "scroll", {wcprops[wcpScrollPosX][idx], wcprops[wcpScrollPosY][idx]})
                end if
                if evdata[1] = wcprops[wcpScrollV][idx] then
                    wcprops[wcpScrollPosY][idx] = evdata[2]
                    doredraw = 1
                    wname = widget_get_name(wid)
                    widget:wc_send_event(wname, "scroll", {wcprops[wcpScrollPosX][idx], wcprops[wcpScrollPosY][idx]})
                end if
                
            case "LostFocus" then
                wcprops[wcpSoftFocus][idx] = 0
                doredraw = 1
                
            case "KeyFocus" then
                if evdata = wid then
                    wcprops[wcpKeyFocus][idx] = 1
                else
                    wcprops[wcpKeyFocus][idx] = 0
                end if
                
            case "Timer" then
                
            case "changed" then
            
            case "child created" then
                if find(widget_get_class(evdata[1]), {"container", "panel"}) then
                    sequence tlabel = "New Tab"
                    atom tflag = -1, tindex = 0
                    wcprops[wcpTabWidgets][idx] &= evdata[1]
                    
                    for p = 1 to length(evdata[2]) do
                        if length(evdata[2][p]) = 2 then
                            switch evdata[2][p][1] do
                                case "label" then
                                    tlabel = evdata[2][p][2]
                                case "flag" then
                                    tflag = evdata[2][p][2]
                                case "tab" then
                                    tindex = evdata[2][p][2]
                                    --todo: insert new tab at specified index
                            end switch
                        end if
                    end for
                    wcprops[wcpTabLabels][idx] &= {tlabel}
                    wcprops[wcpTabFlags][idx] &= {tflag}
                    oswin:set_font(wh, "Arial", 9, Normal)
                    txex = oswin:get_text_extent(wh, tlabel)
                    wcprops[wcpTabWidths][idx] &= {txex[1] + TabGap}
                    
                    select_tab(idx, wid, length(wcprops[wcpTabWidgets][idx]))
                end if
                
            case "child destroyed" then
                atom tidx = find(evdata, wcprops[wcpTabWidgets][idx])
                if tidx > 0 then
                    wcprops[wcpTabWidgets][idx] = remove(wcprops[wcpTabWidgets][idx], tidx)
                    wcprops[wcpTabLabels][idx] = remove(wcprops[wcpTabLabels][idx], tidx)
                    wcprops[wcpTabFlags][idx] = remove(wcprops[wcpTabFlags][idx], tidx)
                    wcprops[wcpTabWidths][idx] = remove(wcprops[wcpTabWidths][idx], tidx)
                    if tidx > length(wcprops[wcpTabWidgets][idx]) then
                        tidx = length(wcprops[wcpTabWidgets][idx])
                    end if
                    select_tab(idx, wid, tidx)
                end if
                
            case "child hidden" then
                wc_call_resize(wid)
                
            case "child shown" then
                wc_call_resize(wid)
                
            case else
                
        end switch     
           
        if doredraw then
            wc_call_draw(wid)
        end if
    end if
end procedure


procedure wc_resize(atom wid)  --resizing affects parent and ancestors
    atom tidx, wch, idx = find(wid, wcprops[wcpID]), wh, wparent
    sequence wsize, txex, lpos, trect, msize, nsize
    
    if idx > 0 then
        wh = widget_get_handle(wid)
        --label:
        oswin:set_font(wh, "Arial", 9, Normal)
        txex = oswin:get_text_extent(wh, wcprops[wcpLabel][idx])
        wsize = {txex[1] + 6, txex[2] + 6 + 30}
        
        widget:widget_set_min_size(wid, wsize[1] + 6, wsize[2])
        widget:widget_set_natural_size(wid, 0, 0)

        --tidx = wcprops[wcpSelectedTab][idx]
        --wch = wcprops[wcpTabWidgets][idx][tidx]
        --msize = widget_get_min_size(wch)
        --nsize = widget_get_natural_size(wch)
        
        --widget:widget_set_min_size(wid, msize[1], msize[2])
        --widget:widget_set_natural_size(wid, nsize[1], nsize[2])

        wparent = parent_of(wid)
        if wparent > 0 then
            wc_call_resize(wparent)
        end if
    end if
end procedure



procedure wc_arrange(atom wid)  --arranging affects children and offspring
    atom idx = find(wid, wcprops[wcpID]), wh
    sequence wpos, wsize, txex, trect, oldsize, newsize
    
    if idx > 0 then
        wpos = widget_get_pos(wid)
        wsize = widget_get_size(wid)
        
        wh = widget_get_handle(wid)
        
        if wcprops[wcpShowBorder][idx] = 1 then
            --label:
            oswin:set_font(wh, "Arial", 9, Normal)
            txex = oswin:get_text_extent(wh, wcprops[wcpLabel][idx])
            --trect = {3, txex[2] + 8, wsize[1] - 3, wsize[2] - 3}
            trect = {3, headingheight + 3, wsize[1] - 3, wsize[2] - 3}
            
            wcprops[wcpLabelPos][idx] = {3, 3}
        else
            trect = {0, 0, wsize[1], wsize[2]}
            wcprops[wcpLabelPos][idx] = {0, 0}
        end if
        
        if not equal(wcprops[wcpTabsRect][idx], trect) then
            wcprops[wcpTabsRect][idx] = trect
            oldsize = wcprops[wcpVisibleSize][idx]
            newsize = {trect[3] - trect[1], trect[4] - trect[2]}
            if not equal(oldsize, newsize) then
                wcprops[wcpVisibleSize][idx] = newsize
                
                check_scrollbars(idx, wid)
                widget:wc_send_event(widget_get_name(wid), "resized", wcprops[wcpVisibleSize][idx])
            end if
        end if
        
        --Resize child container
        if wcprops[wcpSelectedTab][idx] > 0 then
            atom tidx = wcprops[wcpSelectedTab][idx]
            sequence crect = wcprops[wcpTabsRect][idx]
            crect[1] += wpos[1] + 3
            crect[2] += wpos[2] + 3
            crect[3] += wpos[1] - 3
            crect[4] += wpos[2] - 3
            
            widget_set_pos(wcprops[wcpTabWidgets][idx][tidx], crect[1], crect[2])
            widget_set_size(wcprops[wcpTabWidgets][idx][tidx], crect[3] - crect[1], crect[4] - crect[2])
            wc_call_arrange(wcprops[wcpTabWidgets][idx][tidx])
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
    atom idx = find(wid, wcprops[wcpID])
    sequence debuginfo = {}
    
    if idx > 0 then    
        debuginfo = {
            {"SoftFocus", wcprops[wcpSoftFocus][idx]},
            {"HardFocus", wcprops[wcpHardFocus][idx]},
            {"KeyFocus", wcprops[wcpKeyFocus][idx]},
            
            {"Label", wcprops[wcpLabel][idx]},
            {"ShowBorder", wcprops[wcpShowBorder][idx]},
            {"TabWidgets", wcprops[wcpTabWidgets][idx]},
            {"TabLabels", wcprops[wcpTabLabels][idx]},
            {"TabFlags", wcprops[wcpTabFlags][idx]},
            {"TabWidths", wcprops[wcpTabWidths][idx]},
            
            {"SelectedTab", wcprops[wcpSelectedTab][idx]},
    
            {"LabelPos", wcprops[wcpLabelPos][idx]},
            {"TabsRect", wcprops[wcpTabsRect][idx]},
            {"VisibleSize", wcprops[wcpVisibleSize][idx]},
            {"ContentSize", wcprops[wcpContentSize][idx]},
            {"ScrollXEnabled", wcprops[wcpScrollXEnabled][idx]},
            {"ScrollYEnabled", wcprops[wcpScrollYEnabled][idx]},
            {"ScrollPosX", wcprops[wcpScrollPosX][idx]},
            {"ScrollPosY", wcprops[wcpScrollPosY][idx]},
            
            {"ScrollV", wcprops[wcpScrollV][idx]},
            {"ScrollH", wcprops[wcpScrollH][idx]}
        }
    end if
    return debuginfo
end function



wc_define(
    "tabs",
    routine_id("wc_create"),
    routine_id("wc_destroy"),
    routine_id("wc_draw"),
    routine_id("wc_event"),
    routine_id("wc_resize"),
    routine_id("wc_arrange"),
    routine_id("wc_debug")
)   
    

-- widgetclass commands -------------------------------------------------------



procedure cmd_select_tab_by_widget(atom wid, object tabwidget)
    atom idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        atom tabwid = widget_get_id(tabwidget)
        atom tidx = find(tabwid, wcprops[wcpTabWidgets][idx])
        if tidx > 0 then
            select_tab(idx, wid, tidx)
        end if
    end if
end procedure
wc_define_command("tabs", "select_tab_by_widget", routine_id("cmd_select_tab_by_widget"))


procedure cmd_select_tab(atom wid, object tabidx_or_label)
    atom idx
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        if atom(tabidx_or_label) then
            if tabidx_or_label > 0 and tabidx_or_label <= length(wcprops[wcpTabWidgets][idx]) then
                select_tab(idx, wid, tabidx_or_label)
            end if
        elsif sequence(tabidx_or_label) then
            atom tidx = find(tabidx_or_label, wcprops[wcpTabLabels][idx])
            if tidx > 0 then
                select_tab(idx, wid, tidx)
            end if
        end if
    end if
end procedure
wc_define_command("tabs", "select_tab", routine_id("cmd_select_tab"))


procedure cmd_set_tab_label(atom wid, object tabwidget, object lbl)
    atom idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        atom tabwid = widget_get_id(tabwidget)
        atom tidx = find(tabwid, wcprops[wcpTabWidgets][idx])
        if tidx > 0 then
            wcprops[wcpTabLabels][idx][tidx] = lbl
            atom wh = widget:widget_get_handle(wid)
            sequence txex
            oswin:set_font(wh, "Arial", 9, Normal)
            for t = 1 to length(wcprops[wcpTabLabels][idx]) do
                txex = oswin:get_text_extent(wh, wcprops[wcpTabLabels][idx][t])
                wcprops[wcpTabWidths][idx][t] = txex[1] + TabGap
            end for
            wc_call_resize(wid)
        end if
    end if
end procedure
wc_define_command("tabs", "set_tab_label", routine_id("cmd_set_tab_label"))


procedure cmd_set_tab_flag(atom wid, object tabwidget, object flagcolor)
    atom idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        atom tabwid = widget_get_id(tabwidget)
        atom tidx = find(tabwid, wcprops[wcpTabWidgets][idx])
        if tidx > 0 then
            wcprops[wcpTabFlags][idx][tidx] = flagcolor
            wc_call_draw(wid)
            widget:wc_send_event(widget_get_name(wid), "flag", {tabwid, flagcolor})
        end if
    end if
end procedure
wc_define_command("tabs", "set_tab_flag", routine_id("cmd_set_tab_flag"))



