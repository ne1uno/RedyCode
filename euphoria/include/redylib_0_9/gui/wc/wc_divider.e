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
wcpHardFocus,
wcpOrientation,
wcpMoveable,
wcpAdjust, --not really necessary, except to set initial position
wcpAttachedWidget,
wcpOffset,
wcpPressed

constant wcpLENGTH = wcpPressed

wcprops = repeat({}, wcpLENGTH)

constant
    scrV = 0,
    scrH = 1,

    divsize = 8,
    divmargin = 2
    
    
-- Theme variables -------------------------------



-- widgetclass handlers ----------------------------

procedure wc_create(atom wid, object wprops)
    atom wparent, wmoveable = 1, worient = 0, wadjust = 0
    sequence wattach = ""
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do          
                case "attach" then
                    if widget:wexists(wprops[p][2]) then
                        wattach = wprops[p][2]
                        --wmoveable = 1
                    end if
                case "adjust" then
                    wadjust = wprops[p][2]
                
                case "orientation" then
                    worient = wprops[p][2]
                    
            end switch
        end if
    end for
    
    wparent = parent_of(wid)
    if wparent > 0 and equal(widget_get_class(wparent), "container") then
        worient = widget:wc_call_function(wparent, "get_orientation", {})
    end if
    if widget:wexists(wattach) then --and wadjust > 0 then
        if worient = scrV then
            widget:widget_set_default_height(wattach, wadjust)
        else
            widget:widget_set_default_width(wattach, wadjust)
        end if
        wc_call_resize(wattach)
    end if
    
    wcprops[wcpID] &= {wid}
    wcprops[wcpSoftFocus] &= {0}
    wcprops[wcpHardFocus] &= {0}
    wcprops[wcpOrientation] &= {worient}
    wcprops[wcpMoveable] &= {wmoveable}
    wcprops[wcpAdjust] &= {wadjust}
    wcprops[wcpAttachedWidget] &= {wattach}
    wcprops[wcpOffset] &= {0}
    wcprops[wcpPressed] &= {0}
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
    sequence cmds, wrect, chwid
    atom idx, wh, wf, hlcolor, shcolor, hicolor
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wrect = widget_get_rect(wid)
        
        wrect[1] += divmargin
        wrect[2] += divmargin
        wrect[3] -= divmargin
        wrect[4] -= divmargin
        
        if wcprops[wcpMoveable][idx] then
            
            wh = widget:widget_get_handle(wid)
            wf = (wh = oswin:get_window_focus())
        
            if (wcprops[wcpHardFocus][idx] or wcprops[wcpPressed][idx]) and wf then
                hicolor = th:cButtonActive
            elsif wcprops[wcpSoftFocus][idx] then
                hicolor = th:cButtonHover
            else
                hicolor = th:cButtonFace
            end if
            shcolor = th:cButtonShadow
            hlcolor = th:cButtonHighlight
            
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
                {DR_Line, wrect[1]+1, wrect[4]-1, wrect[3] - 1, wrect[4]-1}
                --thicker border:
                --{DR_Line, wrect[3], wrect[2], wrect[3], wrect[4] - 1},
                --{DR_Line, wrect[1], wrect[4], wrect[3], wrect[4]}
            }
            oswin:draw(wh, cmds, "", wrect)
                
        else
            /*hicolor = th:cButtonFace
            
            cmds = {
                --fill:
                {DR_PenColor, hicolor},
                {DR_Rectangle, True} & wrect
            }*/
        end if
        
        chwid = children_of(wid)
        for ch = 1 to length(chwid) do
            wc_call_draw(chwid[ch])
        end for
    end if
end procedure


procedure wc_event(atom wid, sequence evtype, object evdata)
    sequence ampos, wrect
    atom idx, wh, doredraw = 0, mpos
    sequence wname, attachedpos
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wh = widget:widget_get_handle(wid)
        wrect = widget_get_rect(wid)
        wrect[3] -= 1
        wrect[4] -= 1
        
        switch evtype do
            case "MouseMove" then --{x, y, shift, mousepos[1], mousepos[2]}
                if wcprops[wcpMoveable][idx] and wcprops[wcpPressed][idx] = 1 then
                    if widget:wexists(wcprops[wcpAttachedWidget][idx]) then
                        --wcprops[wcpPressed][idx] = 0
                        if wcprops[wcpOrientation][idx] = scrV then
                            mpos = evdata[2] - wcprops[wcpOffset][idx]
                            widget:widget_set_default_height(wcprops[wcpAttachedWidget][idx], mpos)
                        else
                            mpos = evdata[1] - wcprops[wcpOffset][idx]
                            widget:widget_set_default_width(wcprops[wcpAttachedWidget][idx], mpos)
                        end if
                        wc_call_resize(wcprops[wcpAttachedWidget][idx])
                        
                    else
                        atom wp = widget:parent_of(wid)  --widget:widget_get_name(widget:parent_of(wid))
                        
                        if wcprops[wcpOrientation][idx] = scrV then
                            mpos = evdata[2] - wcprops[wcpOffset][idx]
                        else
                            mpos = evdata[1] - wcprops[wcpOffset][idx]
                        end if
                        --widget:wc_send_event(wparname, "divider moved", {wid, mpos})
                        wc_call_event(wp, "divider moved", {wid, mpos})
                    end if
                    if wcprops[wcpOrientation][idx] = scrV then
                        set_mouse_pointer(wh, mNS)
                    else
                        set_mouse_pointer(wh, mEW)
                    end if
                    doredraw = 1
                end if
                if in_rect(evdata[1], evdata[2], wrect) then
                    if wcprops[wcpSoftFocus][idx] = 0 then
                        wcprops[wcpSoftFocus][idx] = 1
                        if wcprops[wcpMoveable][idx] = 0 then
                            set_mouse_pointer(wh, mArrow)
                        else
                            if wcprops[wcpOrientation][idx] = scrV then
                                set_mouse_pointer(wh, mNS)
                            else
                                set_mouse_pointer(wh, mEW)
                            end if
                            doredraw = 1
                        end if
                    end if
                else
                    if wcprops[wcpSoftFocus][idx] = 1 then
                        wcprops[wcpSoftFocus][idx] = 0
                        doredraw = 1
                    end if
                end if
            
            case "LeftDown" then        
                if wcprops[wcpMoveable][idx] and in_rect(evdata[1], evdata[2], wrect) then
                    oswin:capture_mouse(wh)
                    wcprops[wcpHardFocus][idx] = 1
                    wcprops[wcpPressed][idx] = 1
                    if widget:wexists(wcprops[wcpAttachedWidget][idx]) then
                        attachedpos = widget:widget_get_pos(wcprops[wcpAttachedWidget][idx])
                    else
                        attachedpos = {wrect[3] - wrect[1], wrect[4] - wrect[2]} --widget:widget_get_pos(wid)
                    end if
                    if wcprops[wcpOrientation][idx] = scrV then
                        wcprops[wcpOffset][idx] = evdata[2] - wrect[2] + attachedpos[2]
                    else
                        wcprops[wcpOffset][idx] = evdata[1] - wrect[1] + attachedpos[1]
                    end if
                    --widget:wc_send_event(widget_get_name(wid), "GotFocus", {})
                    --widget:set_key_focus(wid)
                    doredraw = 1
                else
                    if wcprops[wcpHardFocus][idx] = 1 then
                        wcprops[wcpHardFocus][idx] = 0
                        doredraw = 1
                    end if
                end if

            case "LeftUp" then      
                if wcprops[wcpPressed][idx] = 1 then
                    wcprops[wcpPressed][idx] = 0
                    doredraw = 1
                end if

            case "RightUp" then        
                if wcprops[wcpMoveable][idx] and in_rect(evdata[1], evdata[2], wrect) then
                    --wcprops[wcpHardFocus][idx] = 1
                    if widget:wexists(wcprops[wcpAttachedWidget][idx]) then
                        if wcprops[wcpOrientation][idx] = scrV then
                            widget:widget_set_default_height(wcprops[wcpAttachedWidget][idx], 0) --reset to expand mode
                        else
                            widget:widget_set_default_width(wcprops[wcpAttachedWidget][idx], 0)  --reset to expand mode
                        end if
                        wc_call_resize(wcprops[wcpAttachedWidget][idx])
                    end if
                    --doredraw = 1
                else
                    if wcprops[wcpHardFocus][idx] = 1 then
                        wcprops[wcpHardFocus][idx] = 0
                        doredraw = 1
                    end if
                end if
                
            case "KeyDown" then
                if wcprops[wcpMoveable][idx] and wcprops[wcpHardFocus][idx] and widget:wexists(wcprops[wcpAttachedWidget][idx]) then
                    attachedpos = widget:widget_get_default_size(wcprops[wcpAttachedWidget][idx])
                    
                    if wcprops[wcpOrientation][idx] = scrV then
                        if evdata[1] = 38 then --up
                            widget:widget_set_default_height(wcprops[wcpAttachedWidget][idx], attachedpos[2] - 5)
                        elsif evdata[1] = 40 then --down
                            widget:widget_set_default_height(wcprops[wcpAttachedWidget][idx], attachedpos[2] + 5)
                        end if
                    else
                        if evdata[1] = 37 then --left
                            widget:widget_set_default_width(wcprops[wcpAttachedWidget][idx], attachedpos[1] - 5)
                        elsif evdata[1] = 39 then --right
                            widget:widget_set_default_width(wcprops[wcpAttachedWidget][idx], attachedpos[1] + 5)
                        end if
                    end if
                    
                    wc_call_resize(wcprops[wcpAttachedWidget][idx])
                    doredraw = 1
                end if
                
            case "LostFocus" then
                wcprops[wcpSoftFocus][idx] = 0
                doredraw = 1
                
            /*case "KeyFocus" then
                if evdata = wid then
                    wcprops[wcpKeyFocus][idx] = 1
                else
                    wcprops[wcpKeyFocus][idx] = 0
                end if*/
                
            case else

        end switch
        
        if doredraw = 1 then
            wc_call_draw(wid)
        end if        
    end if
end procedure


procedure wc_resize(atom wid)
    atom idx, wh, wparent
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        if wcprops[wcpOrientation][idx] = scrV then
            widget:widget_set_min_size(wid, divsize, divsize)
            widget:widget_set_natural_size(wid, 0, divsize)
        else
            widget:widget_set_min_size(wid, divsize, divsize)
            widget:widget_set_natural_size(wid, divsize, 0)
        end if
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
        wc_call_draw(wid)
    end if
end procedure

function wc_debug(atom wid)
    atom idx
    sequence debuginfo = {}
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then    
        debuginfo = {
            {"wcpID", wcprops[wcpID][idx]},
            {"wcpSoftFocus", wcprops[wcpSoftFocus][idx]},
            {"wcpHardFocus",  wcprops[wcpHardFocus][idx]},
            {"wcpOrientation", wcprops[wcpOrientation][idx]},
            {"wcpMoveable", wcprops[wcpMoveable][idx]},
            {"wcpAdjust", wcprops[wcpAdjust][idx]},
            {"wcpAttachedWidget", wcprops[wcpAttachedWidget][idx]},
            {"wcpOffset", wcprops[wcpOffset][idx]},
            {"wcpPressed", wcprops[wcpPressed][idx]}
        }
    end if
    return debuginfo
end function

wc_define(
    "divider",
    routine_id("wc_create"),
    routine_id("wc_destroy"),
    routine_id("wc_draw"),
    routine_id("wc_event"),
    routine_id("wc_resize"),
    routine_id("wc_arrange"),
    routine_id("wc_debug")
)


-- widgetclass commands -------------------------------------------------------

