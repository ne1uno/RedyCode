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
wcpIcon,
wcpToolMode,    --0=normal, 1=toolbutton
wcpTextPos,
wcpCommand,
wcpPressed,
wcpClicked,
wcpDefault, --has an extra border to indicate button will respond to enter key
wcpCancel   --button will respond to ESC key

constant wcpLENGTH = wcpDefault

wcprops = repeat({}, wcpLENGTH)




-- Theme variables -------------------------------



-- widgetclass handlers ----------------------------

procedure wc_create(atom wid, object wprops) 
    sequence wlabel = "", wicon = "", wcommand = {}
    atom wtoolmode
    
    if equal(widget:widget_get_class(widget:parent_of(wid)), "toolbar") then
        wtoolmode = 1
    else
        wtoolmode = 0
    end if
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do          
                case "label" then
                    wlabel = wprops[p][2]
                case "icon" then
                    wicon = wprops[p][2]
                case "toolmode" then
                    wtoolmode = wprops[p][2]
                case "command" then
                    wcommand = wprops[p][2]
                                
            end switch
        end if
    end for
    
    wcprops[wcpID] &= {wid}
    wcprops[wcpSoftFocus] &= {0}
    wcprops[wcpKeyFocus] &= {0}
    wcprops[wcpLabel] &= {wlabel}
    wcprops[wcpIcon] &= {wicon}
    wcprops[wcpToolMode] &= {wtoolmode}
    wcprops[wcpTextPos] &= {{0, 0}}
    wcprops[wcpCommand] &= {wcommand}
    wcprops[wcpPressed] &= {0}
    wcprops[wcpClicked] &= {0}
    wcprops[wcpDefault] &= {0}
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
    sequence cmds, wrect, chwid, txex, txpos
    atom idx, wh, wf, hlcolor, shcolor, hicolor, lblcolor
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wrect = widget_get_rect(wid)
        --wrect[3] -= 1
        --wrect[4] -= 1

        wh = widget:widget_get_handle(wid)
        wf = (wh = oswin:get_window_focus())
        
        if widget:widget_is_enabled(wid) = 0 then
            hicolor = th:cOuterFill
            lblcolor = th:cButtonDisLabel
        elsif wcprops[wcpKeyFocus][idx] and wf then
            hicolor = th:cButtonActive
            lblcolor = th:cButtonLabel
        elsif wcprops[wcpSoftFocus][idx] then
            hicolor = th:cButtonHover
            lblcolor = th:cButtonLabel
        else
            hicolor = th:cButtonFace
            lblcolor = th:cButtonLabel
        end if
        
        
        if wcprops[wcpPressed][idx] then
            hlcolor = th:cButtonShadow
            shcolor = th:cButtonHighlight
            txpos = {
                wrect[1] + wcprops[wcpTextPos][idx][1] + 1,
                wrect[2] + wcprops[wcpTextPos][idx][2] + 1
            }
        else
            shcolor = th:cButtonShadow
            hlcolor = th:cButtonHighlight
            txpos = {
                wrect[1] + wcprops[wcpTextPos][idx][1],
                wrect[2] + wcprops[wcpTextPos][idx][2]
            }
        end if
        
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
            {DR_Line, wrect[3] - 1, wrect[2]+1, wrect[3] - 1, wrect[4]},
            {DR_Line, wrect[1]+1, wrect[4], wrect[3] - 1, wrect[4]},
            --thicker border:

            --{DR_Line, wrect[3], wrect[2], wrect[3], wrect[4] - 1},
            --{DR_Line, wrect[1], wrect[4], wrect[3], wrect[4]},
            
            
            --label:
            {DR_Font, "Arial", 9, Normal},
            {DR_TextColor, lblcolor},
            {DR_PenPos} & txpos,
            {DR_Puts, wcprops[wcpLabel][idx]}
            
            --icon:
            --wcprops[wcpIcon][idx]
        }
        
        if wcprops[wcpKeyFocus][idx] and wf then
            cmds &= {
                {DR_PenColor, shcolor},
                {DR_Line, wrect[1] + 1 + 2, wrect[2] + 2, wrect[3] - 1 - 2, wrect[2] + 2},
                {DR_Line, wrect[1] + 2, wrect[2] + 1 + 2, wrect[1] + 2, wrect[4] - 1 - 2},
                
                {DR_PenColor, hlcolor},
                {DR_Line, wrect[3] - 1 - 2, wrect[2] + 2, wrect[3] - 1 - 2, wrect[4] - 2},
                {DR_Line, wrect[1] + 2, wrect[4] - 2, wrect[3] - 1 - 2, wrect[4] - 2}
            }
        end if
        
        
        draw(wh, cmds)
        
        chwid = children_of(wid)
        for ch = 1 to length(chwid) do
            wc_call_draw(chwid[ch])
        end for
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
                        --wc_call_draw(wid)
                        doredraw = 1
                    end if
                    if wcprops[wcpPressed][idx] = 1 and wcprops[wcpClicked][idx] = 1 then
                        wcprops[wcpPressed][idx] = 0
                        --wc_call_draw(wid)
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
                else
                    if wcprops[wcpKeyFocus][idx] = 1 then
                        wcprops[wcpKeyFocus][idx] = 0
                        doredraw = 1
                    end if
                end if

            case "LeftUp" then      
                if wcprops[wcpClicked][idx] = 1 and wcprops[wcpPressed][idx] = 1 and wenabled = 1 then
                    --doWidgetAction(wID, wcprops[wcpAction])
                    wname = widget_get_name(wid)
                    widget:wc_send_event(wname, "clicked", {})
                    doredraw = 1
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
        
        if wcprops[wcpToolMode][idx] = 0 then
            wsize = {txex[1] + 14, txex[2] + 12}
        else
            
            wsize = {txex[1] + 10, 20} --todo: get global toolbutton size from theme/user preferences
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
    atom idx, wh
    sequence wsize, txex
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wh = widget_get_handle(wid)
        oswin:set_font(wh, "Arial", 9, Normal)
        txex = oswin:get_text_extent(wh, wcprops[wcpLabel][idx])
        wsize = widget_get_size(wid)
        wcprops[wcpTextPos][idx] = {
            floor((wsize[1]) / 2 - txex[1] / 2),
            floor((wsize[2]) / 2 - txex[2] / 2)
        }
        
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
            {"KeyFocus", wcprops[wcpKeyFocus][idx]},
            {"Label", wcprops[wcpLabel][idx]},
            {"Icon", wcprops[wcpIcon][idx]},
            {"ToolMode", wcprops[wcpToolMode][idx]},
            {"TextPos", wcprops[wcpTextPos][idx]},
            {"Command", wcprops[wcpCommand][idx]},
            {"Pressed", wcprops[wcpPressed][idx]},
            {"Clicked", wcprops[wcpClicked][idx]},
            {"Default", wcprops[wcpDefault][idx]}
        }
    end if
    return debuginfo
end function

wc_define(
    "button",
    routine_id("wc_create"),
    routine_id("wc_destroy"),
    routine_id("wc_draw"),
    routine_id("wc_event"),
    routine_id("wc_resize"),
    routine_id("wc_arrange"),
    routine_id("wc_debug")
)


-- widgetclass commands -------------------------------------------------------

procedure cmd_set_label(atom wid, sequence txt)
    atom idx
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wcprops[wcpLabel][idx] = txt
        wc_call_resize(wid)
    end if
end procedure
wc_define_command("button", "set_label", routine_id("cmd_set_label"))


