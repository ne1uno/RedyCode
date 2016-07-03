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

-- Internal class variables and routines

sequence wcprops

enum
wcpID,
wcpSoftFocus,
wcpKeyFocus,
wcpLabel,
wcpBoxStyle,
wcpPressed,
wcpClicked,
wcpValue

constant wcpLENGTH = wcpValue

wcprops = repeat({}, wcpLENGTH)




-- Theme variables -------------------------------

constant
thBoxSize = 16,
thBoxOnColor = th:cButtonActive,
thBoxOffColor = th:cButtonFace,
thCheckColor = th:cInnerShape


-- widgetclass handlers --------------------------

procedure wc_create(atom wid, object wprops) 
    atom wval = 0, bstyle = 1
    sequence wlabel = ""
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do          
                case "label" then
                    wlabel = wprops[p][2]
                    
                case "style" then
                    if equal(wprops[p][2], "button") then
                        bstyle = 0
                    end if
                    
                case "value" then
                    wval = wprops[p][2] = 1
                    
            end switch
        end if
    end for
    
    wcprops[wcpID] &= {wid}
    wcprops[wcpSoftFocus] &= {0}
    wcprops[wcpKeyFocus] &= {0}
    wcprops[wcpLabel] &= {wlabel}
    wcprops[wcpBoxStyle] &= {bstyle}
    wcprops[wcpPressed] &= {0}
    wcprops[wcpClicked] &= {0}
    wcprops[wcpValue] &= {wval}
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
    sequence cmds, wrect, chwid, txex, txpos, box
    atom idx, wh, wf, hlcolor, shcolor, hicolor, txtcolor, chkcolor, pressedcolor, wenabled
    idx = find(wid, wcprops[wcpID])    
    
    if idx > 0 then
        wrect = widget_get_rect(wid)
        wrect[3] -= 1
        wrect[4] -= 1

        wh = widget:widget_get_handle(wid)
        wf = (wh = oswin:get_window_focus())
        wenabled = widget:widget_is_enabled(wid)
        
        if wenabled = 0 then
            hicolor = th:cOuterFill
            txtcolor = th:cButtonDisLabel
        elsif wcprops[wcpKeyFocus][idx] and wf then
            hicolor = th:cOuterActive
            txtcolor = th:cButtonLabel
        elsif wcprops[wcpSoftFocus][idx] then
            hicolor = th:cButtonHover
            txtcolor = th:cButtonLabel
        else
            hicolor = th:cOuterFill
            txtcolor = th:cButtonLabel
        end if
        
        if wcprops[wcpValue][idx] and wenabled = 1 and not wcprops[wcpPressed][idx] then
            chkcolor = thBoxOnColor
            pressedcolor = thCheckColor
        else
            chkcolor = thBoxOffColor
            pressedcolor = thBoxOffColor
        end if

        wrect = widget_get_rect(wid)
        wrect[3] -= 1
        wrect[4] -= 1
        
        if wcprops[wcpBoxStyle][idx] = 1 then
            box = {wrect[1] + 4, wrect[2] + 4, wrect[1] + 2 + thBoxSize, wrect[2] + 2 + thBoxSize}
            txpos = {
                wrect[1] + thBoxSize + 6,
                wrect[2] + 3
            }
        else
            box = wrect
            txpos = {
                wrect[1] + 6,
                wrect[2] + 2
            }
        end if
        
        
        if wcprops[wcpPressed][idx] or wcprops[wcpValue][idx] then
            hlcolor = th:cButtonShadow
            shcolor = th:cButtonHighlight
            if wcprops[wcpBoxStyle][idx] = 0 then
                txpos += 1
            end if
        else
            shcolor = th:cButtonShadow
            hlcolor = th:cButtonHighlight
        end if
        
        
                    
        cmds = {
            --fill:
            {DR_PenColor, hicolor},
            {DR_Rectangle, True} & wrect,
            --checkbox fill:
            {DR_PenColor, chkcolor},
            {DR_Rectangle, True} & box,
        
            --border:
            {DR_PenColor, hlcolor},
            {DR_Line, box[1] + 1, box[2], box[3] - 1, box[2]},
            {DR_Line, box[1], box[2] + 1, box[1], box[4] - 1},
                    
            {DR_PenColor, shcolor},
        
            {DR_Line, box[3] - 1, box[2], box[3] - 1, box[4] - 1},
            {DR_Line, box[1], box[4] - 1, box[3] - 1, box[4] - 1}
        }
            
        if wcprops[wcpBoxStyle][idx] = 1 then
            if wcprops[wcpValue][idx] then
                cmds &= {
                    {DR_PenColor, pressedcolor},
                    {DR_Rectangle, True, box[1] + 3, box[2] + 3, box[3] - 3, box[4] - 3}
                }
            end if
        else
            if wcprops[wcpSoftFocus][idx] and wenabled = 1 then
                cmds &= {
                    {DR_PenColor, th:cButtonHover},
                    {DR_Rectangle, True, box[1] + 1, box[2] + 1, box[3] - 1, box[4] - 1}
                }
            end if
        end if
        cmds &= {
            --label:
            {DR_Font, "Arial", 9, Normal},
            {DR_TextColor, txtcolor},
            {DR_PenPos} & txpos,
            {DR_Puts, wcprops[wcpLabel][idx]}
        }
        
        oswin:draw(wh, cmds, "", wrect)
        
        chwid = children_of(wid)
        for ch = 1 to length(chwid) do
            wc_call_draw(chwid[ch])
        end for
        
        
        /*
        cmds = {
            --fill:
            {DR_PenColor, hicolor},
            {DR_Rectangle, True} & wrect,
            
            --border:
            {DR_PenColor, hlcolor},
            {DR_Line, wrect[1] + 1, wrect[2], wrect[3] - 1, wrect[2]},
            {DR_Line, wrect[1], wrect[2] + 1, wrect[1], wrect[4] - 1},
            --thicker border:
            --{DR_Line, wrect[1] + 1, wrect[2] - 1, wrect[3] - 2, wrect[2] - 1},
            --{DR_Line, wrect[1] - 1, wrect[2] + 1, wrect[1] - 1, wrect[4] - 1},


            {DR_PenColor, shcolor},
            {DR_Line, wrect[3] - 1, wrect[2]+1, wrect[3] - 1, wrect[4] - 1},
            {DR_Line, wrect[1]+1, wrect[4] - 1, wrect[3] - 1, wrect[4] - 1},
            --thicker border:

            --{DR_Line, wrect[3], wrect[2], wrect[3], wrect[4] - 1},
            --{DR_Line, wrect[1], wrect[4], wrect[3], wrect[4]},
            
            
            --label:
            {DR_Font, "Arial", 9, Normal},
            {DR_TextColor, th:cButtonLabel},
            {DR_PenPos} & txpos,
            {DR_Puts, wcprops[wcpLabel][idx]}
        }
        
        if wcprops[wcpKeyFocus][idx] then
            cmds &= {
                {DR_PenColor, shcolor},
                {DR_Line, wrect[1] + 1 + 2, wrect[2] + 2, wrect[3] - 1 - 2, wrect[2] + 2},
                {DR_Line, wrect[1] + 2, wrect[2] + 1 + 2, wrect[1] + 2, wrect[4] - 1 - 2},
                
                {DR_PenColor, hlcolor},
                {DR_Line, wrect[3] - 1 - 2, wrect[2] + 2, wrect[3] - 1 - 2, wrect[4] - 1 - 2},
                {DR_Line, wrect[1] + 2, wrect[4] - 1 - 2, wrect[3] - 1 - 2, wrect[4] - 1 - 2}
            }
        end if
        */

    /*
    sequence cmds, wrect, chwid, txex, txpos, box
    atom idx, hlcolor, shcolor, fillcolor, txtcolor, chkcolor
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wrect = widget_get_rect(wid)
        wrect[3] -= 1
        wrect[4] -= 1
        box = {wrect[1] + 4, wrect[2] + 4, wrect[1] + 2 + wcprops[wcpBoxSize][idx], wrect[2] + 2 + wcprops[wcpBoxSize][idx]}
        
        if wcprops[wcpValue][idx] and not wcprops[wcpPressed][idx] then
            chkcolor = rgb(200, 200, 230)
            txtcolor = get_sys_color(COLOR_BTNTEXT) --rgb(0, 0, 60)
        else
            chkcolor = get_sys_color(COLOR_BTNFACE) --rgb(150, 150, 150)
            txtcolor = get_sys_color(COLOR_BTNTEXT) --rgb(0, 0, 40)
        end if

        if wcprops[wcpSoftFocus][idx] then
            fillcolor = rgb(230, 230, 255) --get_sys_color(COLOR_BTNFACE) --rgb(160, 160, 170)
            txtcolor = get_sys_color(COLOR_BTNTEXT) --rgb(0, 0, 60)
        else
            fillcolor = get_sys_color(COLOR_WINDOW) --rgb(150, 150, 150)
            txtcolor = get_sys_color(COLOR_BTNTEXT) --rgb(0, 0, 40)
        end if
        
        if wcprops[wcpPressed][idx] or wcprops[wcpValue][idx] then
            hlcolor = get_sys_color(COLOR_BTNSHADOW) --rgb(20, 20, 20)
            shcolor = get_sys_color(COLOR_BTNHIGHLIGHT) --rgb(200, 200, 200)
        else
            hlcolor = get_sys_color(COLOR_BTNHIGHLIGHT) --rgb(200, 200, 200)
            shcolor = get_sys_color(COLOR_BTNSHADOW) --rgb(20, 20, 20)
        end if
        
        txpos = {
            wrect[1] + wcprops[wcpTextPos][idx][1],
            wrect[2] + wcprops[wcpTextPos][idx][2]
        }
                    
        cmds = {
            --fill:
            {DR_PenColor, fillcolor},
            {DR_Rectangle, True} & wrect,
            --checkbox fill:
            {DR_PenColor, chkcolor},
            {DR_Rectangle, True} & box,

            --border:
            {DR_PenColor, hlcolor},
            {DR_Line, box[1] + 1, box[2], box[3] - 1, box[2]},
            {DR_Line, box[1], box[2] + 1, box[1], box[4] - 1},
                    
            {DR_PenColor, shcolor},

            {DR_Line, box[3] - 1, box[2], box[3] - 1, box[4] - 1},
            {DR_Line, box[1], box[4] - 1, box[3] - 1, box[4] - 1},
            
            --label:
            --{DR_Font, "Arial", 9, Normal},
            {DR_TextColor, txtcolor},
            {DR_PenPos} & txpos,
            {DR_Puts, wcprops[wcpLabel][idx]}
        }
        
        draw(widget:widget_get_handle(wid), cmds)
        
        chwid = children_of(wid)
        for ch = 1 to length(chwid) do
            wc_call_draw(chwid[ch])
        end for*/
    end if
end procedure


procedure wc_event(atom wid, sequence evtype, object evdata)
    sequence ampos, wrect
    atom idx, wh, doredraw = 0, wenabled
    sequence wname
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wh = widget:widget_get_handle(wid)
        wrect = widget_get_rect(wid)
        wrect[3] -= 1
        wrect[4] -= 1
        wenabled = widget:widget_is_enabled(wid)
        
        switch evtype do        
            case "MouseMove" then --{x, y, shift, mousepos[1], mousepos[2]}
                if in_rect(evdata[1], evdata[2], wrect) then
                    if wcprops[wcpSoftFocus][idx] = 0 then
                        wcprops[wcpSoftFocus][idx] = 1
                        --if wenabled = 1 then
                        --    set_mouse_pointer(wh, mArrow)
                        --else
                        --    set_mouse_pointer(wh, mNo)
                        --end if
                        set_mouse_pointer(wh, mArrow)
                        doredraw = 1
                    end if
                    --if evdata[3] = 16 and
                    if wcprops[wcpClicked][idx] = 1 then --if button is down?
                        wcprops[wcpPressed][idx] = 1
                        doredraw = 1
                    end if
                else
                    if wcprops[wcpSoftFocus][idx] = 1 then
                        wcprops[wcpSoftFocus][idx] = 0
                        wc_call_draw(wid)
                        doredraw = 1
                    end if
                    if wcprops[wcpPressed][idx] = 1 and wcprops[wcpClicked][idx] = 1 then
                        wcprops[wcpPressed][idx] = 0
                        wc_call_draw(wid)
                        doredraw = 1
                    end if
                end if
            
            case "LeftDown" then        
                if in_rect(evdata[1], evdata[2], wrect) and wenabled = 1 then
                    oswin:capture_mouse(wh)
                    wcprops[wcpPressed][idx] = 1
                    wcprops[wcpClicked][idx] = 1
                    wcprops[wcpKeyFocus][idx] = 1
                    --widget:wc_send_event(widget_get_name(wid), "GotFocus", {})
                    widget:set_key_focus(wid)
                    doredraw = 1
                end if

            case "LeftUp" then      
                if wcprops[wcpClicked][idx] = 1 and wcprops[wcpPressed][idx] = 1 and wenabled then
                    if wcprops[wcpValue][idx] = 0 then
                        wcprops[wcpValue][idx] = 1
                    else
                        wcprops[wcpValue][idx] = 0
                    end if
                    doredraw = 1
                    wname = widget_get_name(wid)
                    widget:wc_send_event(wname, "value", wcprops[wcpValue][idx])
                end if
                
                wcprops[wcpClicked][idx] = 0
                wcprops[wcpPressed][idx] = 0
            
            case "LostFocus" then
                wcprops[wcpSoftFocus][idx] = 0
                doredraw = 1
            
            case "KeyFocus" then
                if evdata = wid then
                    if wcprops[wcpKeyFocus][idx] != 1 then
                        wcprops[wcpKeyFocus][idx] = 1
                        doredraw = 1
                    end if
                else
                    if wcprops[wcpKeyFocus][idx] != 0 then
                        wcprops[wcpKeyFocus][idx] = 0
                        doredraw = 1
                    end if
                end if
                
            case "SetEnabled" then
                if evdata = 0 then
                    wcprops[wcpKeyFocus][idx] = 0
                    wcprops[wcpClicked][idx] = 0
                    wcprops[wcpPressed][idx] = 0
                end if
                doredraw = 1
                
            case else
                --statusUpdateMsg(0, "gui: window event:" & evtype & sprint(evdata), 0)
        end switch
        
        if doredraw = 1 then
            wc_call_draw(wid)
        end if
        
    end if
end procedure


procedure wc_resize(atom wid)
    atom idx, wh, wparent
    sequence wsize, txex
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wh = widget_get_handle(wid)
        oswin:set_font(wh, "Arial", 9, Normal)
        txex = oswin:get_text_extent(wh, wcprops[wcpLabel][idx])
        wsize = {txex[1] + 14, txex[2] + 8}
        
        if wcprops[wcpBoxStyle][idx] = 1 then
            wsize[1] += thBoxSize
        end if
        
        widget:widget_set_min_size(wid, wsize[1], wsize[2])
        widget:widget_set_natural_size(wid, 0, wsize[2]) 
    
        wparent = parent_of(wid)
        if wparent > 0 then
            wc_call_resize(wparent)
        end if
    end if
end procedure


procedure wc_arrange(atom wid)
    integer idx

    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wc_call_draw(wid)
    end if
end procedure


function wc_debug(atom wid)
    atom idx
    sequence debuginfo = {}
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then    
        debuginfo = {
            {"SoftFocus", wcprops[wcpSoftFocus][idx]},
            {"HardFocus", wcprops[wcpKeyFocus][idx]},
            {"KeyFocus", wcprops[wcpKeyFocus][idx]},
            {"Label", wcprops[wcpLabel][idx]},
            {"BoxStyle", wcprops[wcpBoxStyle][idx]},
            {"Pressed", wcprops[wcpPressed][idx]},
            {"Clicked", wcprops[wcpClicked][idx]},
            {"Value", wcprops[wcpValue][idx]}
        }
    end if
    return debuginfo
end function



wc_define(
    "toggle",
    routine_id("wc_create"),
    routine_id("wc_destroy"),
    routine_id("wc_draw"),
    routine_id("wc_event"),
    routine_id("wc_resize"),
    routine_id("wc_arrange"),
    routine_id("wc_debug")
)   
    

-- widgetclass commands -------------------------------------------------------

function cmd_get_value(atom wid)
    atom idx, togval
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        togval = wcprops[wcpValue][idx]
    end if
    
    return togval
end function
wc_define_function("toggle", "get_value", routine_id("cmd_get_value"))


procedure cmd_set_value(atom wid, atom newval)
    atom idx = find(wid, wcprops[wcpID])   
    if idx > 0 then
        if newval = 0 or newval = 1 then
            wcprops[wcpValue][idx] = newval
            widget:wc_send_event(widget_get_name(wid), "value", wcprops[wcpValue][idx])
            wc_call_draw(wid)
        end if
    end if
    
end procedure
wc_define_command("toggle", "set_value", routine_id("cmd_set_value"))


