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

    wcpLabel,
    wcpShowBorder,           --1 = show border and, if specified, a lable. 0 = no border (panel rect covers the entire widget rect)
    wcpFormID,
    
    wcpLabelPos,
    wcpPanelRect,
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
optScrollIncrement = 32,
headingheight = 22



-- local routines ---------------------------------------------------------------------------



procedure check_scrollbars(atom idx, atom wid)
--check contents and size of widget to determine if scrollbars are needed, then create or destroy scrollbars when required.
    sequence wpos, wsize, trect, csize, vsize
    atom needV = 0, needH = 0
    
    wpos = widget_get_pos(wid)
    wsize = widget_get_size(wid)
    trect = wcprops[wcpPanelRect][idx]
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
    sequence wname, wbackgroundimage, whandleimage, wlabel = "", wparclass
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do         
                case "label" then
                    wlabel = wprops[p][2]
                    
                --case "border" then
                --    wshowborder = wprops[p][2]
                
            end switch
        end if
    end for
    
    wh = widget:widget_get_handle(wid)
    wname = widget:widget_get_name(wid)
    wparclass = widget:widget_get_class(widget:parent_of(wid))
    if equal(wparclass, "tabs") then
        wshowborder = 0
    else
        wshowborder = 1
    end if
    
    wcprops[wcpID] &= {wid}
    wcprops[wcpSoftFocus] &= {0}
    wcprops[wcpHardFocus] &= {0}
    
    wcprops[wcpLabel] &= {wlabel}
    wcprops[wcpShowBorder] &= {wshowborder}
    wcprops[wcpFormID] &= 0
    
    wcprops[wcpLabelPos] &= {{0, 0}}
    wcprops[wcpPanelRect] &= {{0, 0, 0, 0}}
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
            lrect = wcprops[wcpPanelRect][idx]
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
            
            trect = {wrect[1] + 2, wrect[2] + 2, wrect[3] - 2, wrect[2] + 2 + headingheight - 2}
            box = {trect[1] + BoxOffset, trect[2] + BoxOffset, trect[1] + BoxOffset + thBoxSize, trect[2] + BoxOffset + thBoxSize}
            txpos = {
                trect[1] + headingheight + 2,
                trect[2] + 3
            }
            
            if length(wcprops[wcpLabel][idx]) > 0 then 
                cmds &= {
                --label:
                    {DR_Font, "Arial", 9, Normal},
                    {DR_TextColor, th:cOuterLabel},
                    {DR_PenPos} & txpos,
                    {DR_Puts, wcprops[wcpLabel][idx]}
                }
            end if
            
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
                {DR_Line, trect[1], trect[4] - 1, trect[3] - 1, trect[4] - 1},
                
            --inner lable area border
                {DR_PenColor, hlcolor},
                {DR_Line, trect[1] + headingheight - 3 + 1, trect[2] + 1, trect[3] - 1, trect[2] + 1},
                {DR_Line, trect[1] + headingheight - 3, trect[2] + 1 + 1, trect[1] + headingheight - 3, trect[4] - 1 - 1},
                 
                {DR_PenColor, shcolor},
                {DR_Line, trect[3] - 1 - 1, trect[2] + 1, trect[3] - 1 - 1, trect[4] - 1 - 1},
                {DR_Line, trect[1] + headingheight - 3, trect[4] - 1 - 1, trect[3] - 1 - 1, trect[4] - 1 - 1}
            }
            
            cmds &= {
            --border:
                {DR_PenColor, shcolor},
                {DR_Line, lrect[1]-1, lrect[2]-1, lrect[3], lrect[2]-1},
                {DR_Line, lrect[1]-1, lrect[2]-1, lrect[1]-1, lrect[4]},
                
                {DR_PenColor, hlcolor},
                
                {DR_Line, lrect[3], lrect[2]-1, lrect[3], lrect[4]},
                {DR_Line, lrect[1]-1, lrect[4], lrect[3], lrect[4]}
            }

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
    sequence ampos, wrect, lpos, lrect
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
            lrect = wcprops[wcpPanelRect][idx]
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
                        doredraw = 1
                    end if
                else
                    if wcprops[wcpHardFocus][idx] = 1 then
                        wcprops[wcpHardFocus][idx] = 0
                        doredraw = 1
                    end if
                end if

            case "LeftUp" then      
                if in_rect(evdata[1], evdata[2], wrect) then
                    
                end if
            
            case "RightDown" then        
                if in_rect(evdata[1], evdata[2], wrect) then
                   
                end if

            case "RightUp" then      
                if in_rect(evdata[1], evdata[2], wrect) then
                   
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
                
            case "Timer" then
                
            case "changed" then
            
            case "child created" then
                if equal(widget_get_class(evdata[1]), "container") then
                    wcprops[wcpFormID][idx] = evdata[1]
                end if
            case else
                
        end switch     
           
        if doredraw then
            wc_call_draw(wid)
        end if
    end if
end procedure


procedure wc_resize(atom wid)
    atom idx = find(wid, wcprops[wcpID]), wh, wparent
    sequence wsize, txex, lpos, trect
    
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
        
        if not equal(wcprops[wcpPanelRect][idx], trect) then
            wcprops[wcpPanelRect][idx] = trect
            oldsize = wcprops[wcpVisibleSize][idx]
            newsize = {trect[3] - trect[1], trect[4] - trect[2]}
            if not equal(oldsize, newsize) then
                wcprops[wcpVisibleSize][idx] = newsize
                
                check_scrollbars(idx, wid)
                widget:wc_send_event(widget_get_name(wid), "resized", wcprops[wcpVisibleSize][idx])
            end if
        end if
        
        --Resize child container
        if wcprops[wcpFormID][idx] > 0 then
            sequence crect = wcprops[wcpPanelRect][idx]
            crect[1] += wpos[1]
            crect[2] += wpos[2]
            crect[3] += wpos[1]
            crect[4] += wpos[2]
            
            widget_set_pos(wcprops[wcpFormID][idx], crect[1], crect[2])
            widget_set_size(wcprops[wcpFormID][idx], crect[3] - crect[1], crect[4] - crect[2])
            wc_call_arrange(wcprops[wcpFormID][idx])
        end if
        ------------
        
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
            
            {"Label", wcprops[wcpLabel][idx]},
            {"ShowBorder", wcprops[wcpShowBorder][idx]},
            {"FormID", wcprops[wcpFormID][idx]},
            
            {"LabelPos", wcprops[wcpLabelPos][idx]},
            {"DocRect", wcprops[wcpPanelRect][idx]},
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
    "panel",
    routine_id("wc_create"),
    routine_id("wc_destroy"),
    routine_id("wc_draw"),
    routine_id("wc_event"),
    routine_id("wc_resize"),
    routine_id("wc_arrange"),
    routine_id("wc_debug")
)   
    

-- widgetclass commands -------------------------------------------------------
