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



include redylib_0_9/gui/widgets.e as widget
include redylib_0_9/oswin.e as oswin
include redylib_0_9/gui/themes.e as th
include redylib_0_9/actions.e as action

include std/sequence.e
include std/pretty.e

-- Internal class variables and routines

sequence wcprops

enum
wcpID,
wcpSoftFocus,
wcpHardFocus,
wcpPinned,
wcpSubMenu,
wcpAvoidRect, --{left, top, width, height, direction} (direction: 0=below, 1=right)
wcpItems,
wcpPressed,
wcpSelection,
wcpRoot,

wcpOptShowPin,

wcpTitle


enum --for wcpItems
itmLabel,
itmIcon,
itmHotkey,
itmEnabled,
itmRect,
itmTextPos,
itmSubMenu,
itmActionName,
itmActionData,
itmType   --0=pinbutton, 1=normal, 2=separator, 3=submenu, 4=action

constant wcpLENGTH = wcpTitle

wcprops = repeat({}, wcpLENGTH)


-- Theme variables -------------------------------

atom thPinButtonHeight = 12, showpin = 0, iconsize = 16

-- widgetclass handlers ----------------------------

procedure wc_create(atom wid, object wprops) 
    atom orientation = 0, wparent, cy, maxx = 100, winhandle, wphw, wroot = 0, wpressed = 1
    sequence wsize = {6, 6}, txex, txexhotkey, itms = {}, actions = {}, 
    mitems = {{}, {}, {}, {}, {}, {}, {}, {}, {}, {}}, avrect = {0, 0, 0, 0, 0}, wtitle = ""
    object atype, alabel, aicon, adescription, aundoable, aenabled, ahotkey, astate, alist
    atom old_item_mode = 0 --for compatibility with old api
    
    --wph = widget:widget_get_handle(wid) --widget:parent_of(wid))
    
    --oswin:menu_active(1)
    winhandle = oswin:create_window(wid, "menu", "popup", 0, 0, 128, 128, 0, th:cOuterFill) --, wph)
    widget:widget_set_handle(wid, winhandle)
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do          
                case "items" then --depreciated, use "actions" instead
                    actions = wprops[p][2]
                    old_item_mode = 1
                    
                case "actions" then --new api, allows generation of menu items based on action properties
                    actions = wprops[p][2]
                    
                case "avoid" then
                    avrect = wprops[p][2]
                    
                case "title" then
                    wtitle = wprops[p][2]
                    
                case "root" then
                    wroot = wprops[p][2]
                    
                case "pin" then
                    showpin = wprops[p][2] 
                    
                case "pressed" then
                    wpressed = wprops[p][2]
                    
            end switch
        end if
    end for
    
    oswin:set_font(winhandle, "Arial", 9, Normal)
    
    if showpin then
        --special pin button
        mitems[itmLabel] &= {"[pin]"}
        mitems[itmIcon] &= {0}
        mitems[itmHotkey] &= {""}
        mitems[itmEnabled] &= {1}
        mitems[itmType] &= {0}
        mitems[itmSubMenu] &= {{}}
        
        mitems[itmActionName] &= {0}
        mitems[itmActionData] &= {{}}
        
        txex = oswin:get_text_extent(winhandle, "[pin]")
        
        mitems[itmRect] &= {{2, 2, txex[1] + 6, 2 + thPinButtonHeight}}
        mitems[itmTextPos] &= {{4, 2 + floor((txex[2] + 6) / 2 - txex[2] / 2)}}
                                      
        cy = thPinButtonHeight + 3
    else
        cy = 2
    end if
    
    -- new "actions" mode: generate menu items based on action properties
    for m = 1 to length(actions) do
        if equal(actions[m], "-") then --separator
            mitems[itmLabel] &= {"-"}
            mitems[itmIcon] &= {0}
            mitems[itmHotkey] &= {""}
            mitems[itmEnabled] &= {1}
            mitems[itmType] &= {2}
            mitems[itmSubMenu] &= {{}}
            
            mitems[itmActionName] &= {0}
            mitems[itmActionData] &= {{}}
            
            txex = {0, 0, 0, 0, 0, 0}
            
            mitems[itmRect] &= {{2, cy, txex[1] + 6, cy + txex[2] + 5}}
            mitems[itmTextPos] &= {{6, cy + floor((txex[2] + 5) / 2 - txex[2] / 2)}}
            
            cy += txex[2] + 6
            if txex[1] + 16 + 32 > maxx then
                maxx = txex[1] + 16 + 32
            end if
            wsize = {maxx+2, cy + 1}
            
        elsif sequence(actions[m][1]) then --submenu
            mitems[itmLabel] &= {actions[m][1]}
            mitems[itmIcon] &= {0}
            mitems[itmHotkey] &= {""}
            mitems[itmEnabled] &= {1}
            mitems[itmType] &= {3}
            mitems[itmSubMenu] &= {actions[m][2]}
            
            mitems[itmActionName] &= {0}
            mitems[itmActionData] &= {{}}
            
            txex = oswin:get_text_extent(winhandle, actions[m][1])
            
            mitems[itmRect] &= {{2, cy, txex[1] + 6 + 18, cy + txex[2] + 5}}
            mitems[itmTextPos] &= {{6 + 18, cy + floor((txex[2] + 5) / 2 - txex[2] / 2)}}
            
            cy += txex[2] + 6
            if txex[1] + 16 + 32 > maxx then
                maxx = txex[1] + 16 + 32
            end if
            wsize = {maxx+2, cy + 1}
            
        else --normal
            if old_item_mode then --for compatibility with old api
                mitems[itmLabel] &= {actions[m]}
                mitems[itmIcon] &= {0}
                mitems[itmHotkey] &= {""}
                mitems[itmEnabled] &= {1}
                mitems[itmType] &= {1}
                mitems[itmSubMenu] &= {{}}
                
                mitems[itmActionName] &= {0}
                mitems[itmActionData] &= {{}}
                
                txex = oswin:get_text_extent(winhandle, actions[m])
                
                mitems[itmRect] &= {{2, cy, txex[1] + 6 + 18, cy + txex[2] + 5}}
                mitems[itmTextPos] &= {{6 + 18, cy + floor((txex[2] + 5) / 2 - txex[2] / 2)}}
                
                cy += txex[2] + 6
                if txex[1] + 16 + 32 > maxx then
                    maxx = txex[1] + 16 + 32
                end if
                wsize = {maxx+2, cy + 1}
                
            else
                atype = action:get_type(actions[m])
                alabel = action:get_label(actions[m])
                aicon = action:get_icon(actions[m])
                adescription = action:get_description(actions[m])
                aundoable = action:get_undoable(actions[m])
                aenabled = action:get_enabled(actions[m])
                ahotkey = action:get_hotkey(actions[m])
                astate = action:get_state(actions[m])
                alist = action:get_list(actions[m])
                
                switch atype do
                case "label" then
                    
                case "trigger" then
                    if sequence(alabel) then
                        mitems[itmLabel] &= {alabel}
                        mitems[itmIcon] &= {aicon}
                        mitems[itmHotkey] &= {ahotkey}
                        mitems[itmEnabled] &= {aenabled}
                        mitems[itmType] &= {4}
                        mitems[itmSubMenu] &= {{}}
                        
                        mitems[itmActionName] &= {actions[m]}
                        mitems[itmActionData] &= {{}}
                        
                        txexhotkey = oswin:get_text_extent(winhandle, ahotkey)
                        txex = oswin:get_text_extent(winhandle, alabel)
                        
                        mitems[itmRect] &= {{2, cy, txex[1] + 6 + 18, cy + txex[2] + 5}}
                        mitems[itmTextPos] &= {{6 + 18, cy + floor((txex[2] + 5) / 2 - txex[2] / 2), txexhotkey[1]}}
                        
                        cy += txex[2] + 6
                        if txex[1] + 16 + 32 > maxx then
                            maxx = txex[1] + 16 + 32
                        end if
                        wsize = {maxx+2, cy + 1}
                    end if
                    
                case "toggle" then
                    
                case "list" then
                    if sequence(alist) then
                        --list format:
                        --{
                        --    {icon, label, data},
                        --    {icon, label, data},
                        --    {icon, label, data}...
                        --}
                        for li = 1 to length(alist) do
                            mitems[itmLabel] &= {alist[li][2]}
                            mitems[itmIcon] &= {alist[li][1]}
                            mitems[itmHotkey] &= {""}
                            mitems[itmEnabled] &= {aenabled}
                            mitems[itmType] &= {4}
                            mitems[itmSubMenu] &= {{}}
                            
                            mitems[itmActionName] &= {actions[m]}
                            mitems[itmActionData] &= {alist[li][3]}
                            
                            txex = oswin:get_text_extent(winhandle, alist[li][2])
                            
                            mitems[itmRect] &= {{2, cy, txex[1] + 6 + 18, cy + txex[2] + 5}}
                            mitems[itmTextPos] &= {{6 + 18, cy + floor((txex[2] + 5) / 2 - txex[2] / 2)}}
                            
                            cy += txex[2] + 6
                            if txex[1] + 16 + 32 > maxx then
                                maxx = txex[1] + 16 + 32
                            end if
                            wsize = {maxx+2, cy + 1}
                        end for
                    end if
                    
                case "text" then
                    
                case "number" then
                    
                end switch
            end if
        end if
    end for
    
    for m = 1 to length(mitems[itmRect]) do
        mitems[itmRect][m][3] = maxx
    end for
    
    if showpin then
        txex = oswin:get_text_extent(winhandle, "[pin]")
        mitems[itmTextPos][1][1] = maxx - txex[1] - 4
    end if
    
    widget:widget_set_size(wid, wsize[1], wsize[2])
    if avrect[5] = 0 then --below
        set_window_pos(winhandle, avrect[1], avrect[4])
    else --to the right
        set_window_pos(winhandle, avrect[3], avrect[2])
    end if
    set_window_size(winhandle, wsize[1], wsize[2])
    set_window_title(winhandle, wtitle)
    
    wcprops[wcpID] &= {wid}
    wcprops[wcpSoftFocus] &= {0}
    wcprops[wcpHardFocus] &= {0}
    wcprops[wcpPinned] &= {0}
    wcprops[wcpSubMenu] &= {0}
    wcprops[wcpAvoidRect] &= {avrect}
    wcprops[wcpItems] &= {mitems}
    wcprops[wcpPressed] &= {wpressed}
    wcprops[wcpSelection] &= {0}
    wcprops[wcpRoot] &= {wroot}
    wcprops[wcpOptShowPin] &= {showpin}
    wcprops[wcpTitle] &= {wtitle}
    
    oswin:show_window(winhandle)
    oswin:enable_close(winhandle, 1)
    
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
    sequence cmds, wrect, chwid, txex, box, mitems
    atom idx, wh, itmh, hlcolor, shcolor, fillcolor, txtcolor, chkcolor, x1, y1
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wrect = widget_get_rect(wid)
        wrect[1] = 0
        wrect[2] = 0
        --wrect[3] -= 1
        --wrect[4] -= 1
        wh = widget_get_handle(wid)
        
        --fill:
        cmds = {
            {DR_PenColor, th:cButtonFace},
            {DR_Rectangle, True} & wrect,
            --{DR_PenColor, rgb(128,128,180)},
            --{DR_Rectangle, True} & wrect,
        --text border:
            --{DR_PenColor, rgb(255,128,180)}, 
            {DR_PenColor, th:cButtonHighlight},
            {DR_Line, wrect[1] + 0, wrect[2] + 0, wrect[3] - 1, wrect[2] + 0},
            {DR_Line, wrect[1] + 0, wrect[2] + 0, wrect[1] + 0, wrect[4] - 1},
            --{DR_PenColor, rgb(128,255,180)},
            {DR_PenColor, th:cButtonShadow},
            {DR_Line, wrect[3] - 1, wrect[2] + 0, wrect[3] - 1, wrect[4] - 1},
            {DR_Line, wrect[1] + 0, wrect[4] - 1, wrect[3] - 1, wrect[4] - 1}
        }
        
        mitems = wcprops[wcpItems][idx]
        for m = 1 to length(mitems[itmLabel]) do            
            box = mitems[itmRect][m]
            
            if wcprops[wcpSelection][idx] = m and mitems[itmType][m] != 2 and mitems[itmEnabled][m] then
                chkcolor = th:cInnerSel
                txtcolor = th:cInnerTextSel
            else
                if wcprops[wcpSoftFocus][idx] = m and mitems[itmType][m] != 2 and mitems[itmEnabled][m] then
                    chkcolor = th:cInnerSel
                    txtcolor = th:cInnerTextSel
                else
                    chkcolor = th:cButtonFace
                    txtcolor = th:cButtonLabel
                end if                
            end if
            
            if wcprops[wcpPressed][idx] then --and wcprops[wcpSelection][idx] = m then
                hlcolor = th:cButtonShadow
                shcolor = th:cButtonHighlight
            else
                hlcolor = th:cButtonHighlight
                shcolor = th:cButtonShadow
            end if
            
            --item fill:
            cmds &= {
                {DR_PenColor, chkcolor},
                {DR_Rectangle, True} & box  --, box[1]-1, box[2]-1, box[3]+1, box[4]+1}
            }
            
            --border:
            if wcprops[wcpSoftFocus][idx] = m and mitems[itmType][m] != 2 and mitems[itmEnabled][m] then
                cmds &= {
                    {DR_PenColor, hlcolor},
                    {DR_Line, box[1] + 1, box[2], box[3] - 1, box[2]},
                    {DR_Line, box[1], box[2] + 1, box[1], box[4] - 1},
                    {DR_PenColor, shcolor},
                    {DR_Line, box[3] - 1, box[2], box[3] - 1, box[4] - 1},
                    {DR_Line, box[1], box[4] - 1, box[3] - 1, box[4] - 1}
                }
            end if
            
            if mitems[itmType][m] = 0 then --special pin button
                x1 = box[3] - 33
                y1 = box[2] + 4
                cmds &= {  --draw a staple! :-D
                    {DR_PenColor, txtcolor},
                    {DR_PolyLine, True, {
                        {x1 + 11, y1 + 2},
                        {x1 + 10, y1 + 3},
                        {x1 + 1,  y1 + 3},
                        {x1 + 0,  y1 + 2},
                        {x1 + 0,  y1 + 1},
                        {x1 + 1,  y1 + 0},
                        {x1 + 28, y1 + 0},
                        {x1 + 29, y1 + 1},
                        {x1 + 29, y1 + 2},
                        {x1 + 28, y1 + 3},
                        {x1 + 19, y1 + 3},
                        {x1 + 17, y1 + 1}
                    }}
                }
                
            elsif mitems[itmType][m] = 1 then --normal (depreciated, now 4 is used - action name)
                --label:
                if mitems[itmEnabled][m] then
                    cmds &= {
                        {DR_Font, "Arial", 9, Normal},
                        {DR_TextColor, txtcolor},
                        {DR_PenPos} & mitems[itmTextPos][m],
                        {DR_Puts, mitems[itmLabel][m]}
                    }
                else
                    cmds &= {
                        {DR_Font, "Arial", 9, Normal},
                        {DR_TextColor, rgb(120, 120, 120)},
                        {DR_PenPos} & mitems[itmTextPos][m],
                        {DR_Puts, mitems[itmLabel][m][2..$]}
                    }
                end if
                
            elsif mitems[itmType][m] = 2 then --separator
                cmds &= {
                    {DR_PenColor, th:cButtonHighlight},
                    {DR_Line, box[1] + 3, box[2] + 2, box[3] - 3, box[2] + 2},
                    {DR_PenColor, th:cButtonShadow},
                    {DR_Line, box[1] + 3, box[2] + 3, box[3] - 3, box[2] + 3}
                }
                
            elsif mitems[itmType][m] = 3 then --submenu
                itmh = 16
                x1 = box[3] - itmh - 2
                y1 = box[2] + 2
                
                if mitems[itmEnabled][m] then
                    cmds &= {
                    --label:
                        {DR_Font, "Arial", 9, Normal},
                        {DR_TextColor, txtcolor},
                        {DR_PenPos} & mitems[itmTextPos][m],
                        {DR_Puts, mitems[itmLabel][m]},
                    --draw a right arrow:
                        {DR_PenColor, th:cButtonDark},
                        {DR_BrushColor, th:cButtonDark},
                        {DR_PolyLine, True, {  --fill triangle
                            {floor(x1 + itmh *.2), floor(y1 + itmh *.2)},
                            {floor(x1 + itmh *.2), floor(y1 + itmh *.8)},
                            {floor(x1 + itmh *.9), floor(y1 + itmh *.5)},
                            {floor(x1 + itmh *.2), floor(y1 + itmh *.2)}
                        }},
                        {DR_PenColor, th:cButtonShadow},
                        {DR_Line, floor(x1 + itmh *.2), floor(y1 + itmh *.2), floor(x1 + itmh *.2), floor(y1 + itmh *.8)},
                        {DR_Line, floor(x1 + itmh *.2), floor(y1 + itmh *.2), floor(x1 + itmh *.9), floor(y1 + itmh *.5)},
                        {DR_PenColor, th:cButtonHighlight},
                        {DR_Line, floor(x1 + itmh *.2), floor(y1 + itmh *.8), floor(x1 + itmh *.9), floor(y1 + itmh *.5)}
                    }
                else
                    cmds &= {
                    --label:
                        {DR_Font, "Arial", 9, Normal},
                        {DR_TextColor, th:cButtonDisLabel},
                        {DR_PenPos} & mitems[itmTextPos][m],
                        {DR_Puts, mitems[itmLabel][m][2..$]},
                    --draw a right arrow:
                        {DR_PenColor, th:cButtonDark},
                        {DR_BrushColor, th:cButtonDark},
                        {DR_PolyLine, True, {  --fill triangle
                            {floor(x1 + itmh *.2), floor(y1 + itmh *.2)},
                            {floor(x1 + itmh *.2), floor(y1 + itmh *.8)},
                            {floor(x1 + itmh *.9), floor(y1 + itmh *.5)},
                            {floor(x1 + itmh *.2), floor(y1 + itmh *.2)}
                        }}
                    }
                    
                end if
                
            elsif mitems[itmType][m] = 4 then --action name
                --icon or color
                if atom(mitems[itmIcon][m]) then --a rgb color
                    cmds &= {
                        --item icon - solid color
                        {DR_PenColor, mitems[itmIcon][m]},
                        {DR_Rectangle, True, box[1] + 2, box[2] + 2, box[1] + 2 + iconsize, box[2] + 2 + iconsize}
                    }
                elsif length(mitems[itmIcon][m]) > 0 then --a string representing the bitmap already loaded by load_bitmap()
                    --cmds &= {
                        --item icon - image (must be 16 x 16!)
                    --    {DR_Image, mitems[itmIcon][m], box[1] + 2, box[2] + 2}
                   -- }
                   
                   
                    --icon
                    if mitems[itmEnabled][m] then
                        cmds &= {
                            {DR_Image, mitems[itmIcon][m], box[1] + 2, box[2] + 2, rgb(0, 0, 0)}
                        }
                    else
                        --bitmap_effect(atom hwnd, sequence bitmapname, sequence effectname, atom refresh = 0)
                        cmds &= {
                            {DR_Image, oswin:bitmap_effect(wh, mitems[itmIcon][m], "disabled"), 
                                box[1] + 2, box[2] + 2,
                                rgb(0, 0, 0) --transparancy color
                            }
                        }
                    end if
                   
                   
                   
                   
                   
                else   --empty string - no icon
                    
                end if
                
                --label:
                if mitems[itmEnabled][m] then
                    cmds &= {
                        {DR_Font, "Arial", 9, Normal},
                        {DR_TextColor, txtcolor},
                        {DR_PenPos} & mitems[itmTextPos][m],
                        {DR_Puts, mitems[itmLabel][m]}
                    }
                else
                    cmds &= {
                        {DR_Font, "Arial", 9, Normal},
                        {DR_TextColor, rgb(120, 120, 120)},
                        {DR_PenPos} & mitems[itmTextPos][m],
                        {DR_Puts, mitems[itmLabel][m]}
                    }
                end if
            end if
        end for
        
        draw(widget:widget_get_handle(wid), cmds)
        
        chwid = children_of(wid)
        for ch = 1 to length(chwid) do
            wc_call_draw(chwid[ch])
        end for
    end if
end procedure


procedure wc_event(atom wid, sequence evtype, object evdata)
    sequence ampos, wrect, mitems, wsize, wtitle, wpos, winpos, avrect
    atom idx, wh, doredraw = 0, winhandle, wparent, cy, clicked = 0, sel, sf = 0
    sequence wname
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wrect = widget_get_rect(wid)
        wh = widget:widget_get_handle(wid)
        wrect[3] -= 1
        wrect[4] -= 1
        mitems = wcprops[wcpItems][idx]
        sel = wcprops[wcpSelection][idx]
        sf = wcprops[wcpSoftFocus][idx]
        
        switch evtype do        
            case "MouseMove" then --{x, y, shift, mousepos[1], mousepos[2]}
                --sf = 0
                for m = 1 to length(mitems[itmLabel]) do
                    if in_rect(evdata[1], evdata[2], mitems[itmRect][m]) then
                        sf = m
                        if sel > 0 then
                            sel = m
                            doredraw = 1
                        end if
                        set_mouse_pointer(wh, mArrow)
                    end if
                end for
                
            case "NonClientMouseMove" then
                --wcprops[wcpSoftFocus][idx] = 0
                --wcprops[wcpPressed][idx] = 0
                --wcprops[wcpSelection][idx] = 0
                --doredraw = 1
                sf = 0
                for m = 1 to length(mitems[itmLabel]) do
                    if in_rect(evdata[1], evdata[2], mitems[itmRect][m]) then
                        sf = m
                        if sel > 0 then
                            sel = m
                            doredraw = 1
                        end if
                        set_mouse_pointer(wh, mArrow)
                    end if
                end for
                
            case "LeftDown" then
                if wcprops[wcpPressed][idx] = 0 then
                    wcprops[wcpPressed][idx] = 1
                    doredraw = 1
                end if
                for m = 1 to length(mitems[itmLabel]) do
                    if in_rect(evdata[1], evdata[2], mitems[itmRect][m]) then
                        if wcprops[wcpSelection][idx] > 0 then
                            sel = 0
                        else
                            sel = m
                        end if
                        doredraw = 1
                        exit
                    end if
                end for
                
            case "RightDown" then
                if wcprops[wcpPressed][idx] = 0 then
                    wcprops[wcpPressed][idx] = 1
                    doredraw = 1
                end if
                for m = 1 to length(mitems[itmLabel]) do
                    if in_rect(evdata[1], evdata[2], mitems[itmRect][m]) then
                        if wcprops[wcpSelection][idx] > 0 then
                            sel = 0
                        else
                            sel = m
                        end if
                        doredraw = 1
                        exit
                    end if
                end for
                
            case "LeftUp" then
                sel = 0
                --if wcprops[wcpPressed][idx] = 1 then
                wcprops[wcpPressed][idx] = 0
                widget:wc_call_event(wcprops[wcpRoot][idx], "unpressed", wid)
                doredraw = 1
                
                for m = 1 to length(mitems[itmLabel]) do
                    if in_rect(evdata[1], evdata[2], mitems[itmRect][m]) then
                        clicked = m
                        exit
                    end if
                end for
                --end if
                if wcprops[wcpSelection][idx] > 0 then
                    for m = 1 to length(mitems[itmLabel]) do
                        if in_rect(evdata[1], evdata[2], mitems[itmRect][m]) then
                            sel = m
                            exit
                        end if
                    end for
                    doredraw = 1
                end if
                
            case "RightUp" then
                sel = 0
                --if wcprops[wcpPressed][idx] = 1 then
                wcprops[wcpPressed][idx] = 0
                widget:wc_call_event(wcprops[wcpRoot][idx], "unpressed", wid)
                doredraw = 1
                
                for m = 1 to length(mitems[itmLabel]) do
                    if in_rect(evdata[1], evdata[2], mitems[itmRect][m]) then
                        clicked = m
                        exit
                    end if
                end for
                --end if
                if wcprops[wcpSelection][idx] > 0 then
                    for m = 1 to length(mitems[itmLabel]) do
                        if in_rect(evdata[1], evdata[2], mitems[itmRect][m]) then
                            sel = m
                            exit
                        end if
                    end for
                    doredraw = 1
                end if
                
            case "unpressed" then
                if wcprops[wcpPressed][idx] = 1 then
                    wcprops[wcpPressed][idx] = 0
                    doredraw = 1
                end if
                if wcprops[wcpSubMenu][idx] > 0 then
                    widget:wc_call_event(wcprops[wcpSubMenu][idx], "unpressed", wid)
                end if
                
            /*
            case "deselected" then
                if wcprops[wcpSubMenu][idx] > 0 then
                    widget:wc_call_event(wcprops[wcpSubMenu][idx], "deselected", wid)
                end if
                widget:widget_destroy(wid)
                return
                      
            case "MenuClosed" then
                if wcprops[wcpPinned][idx] = 0 then
                    wc_call_event(widget:parent_of(wid), "MenuClosed", {{}})
                    widget:widget_destroy(wid)
                    --oswin:close_all_popups()
                    return
                end if
            */
              
            case "Close" then
                --puts(1, "Close")
                --wc_call_event(widget:parent_of(wid), "MenuClosed", {{}})
                widget:widget_destroy(wid)
                return
        end switch
        
        
        if sel != wcprops[wcpSelection][idx] then
            wcprops[wcpSelection][idx] = sel
            doredraw = 1
        end if
            
        if sf != wcprops[wcpSoftFocus][idx] then
            wcprops[wcpSoftFocus][idx] = sf
            doredraw = 1
            
            if sf > 0 then
                if wcprops[wcpSubMenu][idx] > 0 then
                    widget:widget_destroy(wcprops[wcpSubMenu][idx])
                    wcprops[wcpSubMenu][idx] = 0
                end if
                if sf > 0 and mitems[itmType][sf] = 3 and mitems[itmEnabled][sf] then
                    winpos = get_window_pos(widget_get_handle(wid))
                    
                    avrect = mitems[itmRect][sf]
                    avrect[1] += winpos[1]
                    avrect[2] += winpos[2]
                    avrect[3] += winpos[1]
                    avrect[4] += winpos[2]
                    
                    wcprops[wcpSubMenu][idx] = widget_create(widget_get_name(wid) & ".mnu" & mitems[itmLabel][sf], wid, "menu", {
                        {"title", mitems[itmLabel][sf]},
                        --{"items", mitems[itmSubMenu][sf]},
                        {"actions", mitems[itmSubMenu][sf]},
                        {"avoid", avrect & 1},
                        {"root", wcprops[wcpRoot][idx]},
                        {"pressed", wcprops[wcpPressed][idx]}
                    })
                end if
            end if
        end if
        
        if clicked > 0 then
            if mitems[itmType][clicked] = 0 then  --Pin item
                if wcprops[wcpPinned][idx] = 0 then
                    wcprops[wcpPinned][idx] = 1
                    
                    winhandle = widget_get_handle(wid)           
                    wsize = widget:widget_get_size(wid)
                    wtitle = wcprops[wcpTitle][idx]
                    wpos = oswin:get_window_pos(winhandle)   
                    
                    --remove pin button
                    cy = mitems[itmRect][1][4]  --get height of pin button
                    
                    mitems[itmLabel] = remove(mitems[itmLabel], 1)
                    mitems[itmIcon] = remove(mitems[itmIcon], 1)
                    mitems[itmHotkey] = remove(mitems[itmHotkey], 1)
                    mitems[itmEnabled] = remove(mitems[itmEnabled], 1)
                    mitems[itmRect] = remove(mitems[itmRect], 1)
                    mitems[itmTextPos] = remove(mitems[itmTextPos], 1)
                    mitems[itmSubMenu] = remove(mitems[itmSubMenu], 1)
                    mitems[itmActionName] = remove(mitems[itmActionName], 1)
                    mitems[itmActionData] = remove(mitems[itmActionData], 1)
                    mitems[itmType] = remove(mitems[itmType], 1)
                    
                    for i = 1 to length(mitems[itmRect]) do
                        mitems[itmRect][i][2] -= cy
                        mitems[itmRect][i][4] -= cy
                        mitems[itmTextPos][i][2] -= cy
                    end for
                    wcprops[wcpItems][idx] = mitems
                    
                    wsize[2] -= cy + 1
                    widget:widget_set_size(wid, wsize[1], wsize[2])
                    
                    --oswin:destroy_window(winhandle)
                    
                    
                    winhandle = oswin:create_window(wid, wtitle, "tool", wpos[1], wpos[2], wsize[1], wsize[2], 0, th:cOuterFill)
                    --oswin:set_window_size(winhandle, wsize[1]+2, wsize[2]+2)
                    
                    widget:widget_set_handle(wid, winhandle)
                    oswin:show_window(winhandle)
                    --oswin:enable_close(winhandle)
                    
                    oswin:close_all_popups("pin")
                    
                    
                    doredraw = 1
                    wcprops[wcpPressed][idx] = 0
                    
                    return
                end if
                
            elsif mitems[itmType][clicked] = 1 then  --Normal item
                if mitems[itmEnabled][clicked] then
                    --wc_call_event(widget:parent_of(wid), "deselect", {{}})
                    --widget:wc_call_event(wcprops[wcpRoot][idx], "unpressed", wid)
                    wname = widget_get_name(wid)
                    widget:wc_send_event(wname, "clicked", mitems[itmLabel][clicked])
                    --puts(1, "clicked: " & wcprops[wcpTitle][idx] & ":" & mitems[itmLabel][clicked])
                    widget:wc_call_event(wcprops[wcpRoot][idx], "MenuItemClicked", {wid, mitems[itmLabel][clicked]})
                    
                    
                    if not wcprops[wcpPinned][idx] then
                        widget:wc_call_event(wcprops[wcpRoot][idx], "MenuClosed", {{}})
                        
                        oswin:close_all_popups("item")
                        
                        --oswin:close_all_popups()
                        --widget:widget_destroy(wid)
                    end if
                    return
                end if
                
            elsif mitems[itmType][clicked] = 2 then  --Separator item
                
            elsif mitems[itmType][clicked] = 3 then  --Submenu item
                
            elsif mitems[itmType][clicked] = 4 then  --action item
                if sequence(mitems[itmActionName][clicked]) and mitems[itmEnabled][clicked] then --action
                    --wname = widget_get_name(wid)
                    --widget:wc_send_event(wname, "clicked", mitems[itmLabel][clicked])
                    --widget:wc_call_event(wcprops[wcpRoot][idx], "MenuItemClicked", {wid, mitems[itmLabel][clicked]})
                    
                    if not wcprops[wcpPinned][idx] then
                        widget:wc_call_event(wcprops[wcpRoot][idx], "MenuClosed", {{}})
                        oswin:close_all_popups("item")
                    end if
                    
                    action:do_proc(mitems[itmActionName][clicked], mitems[itmActionData][clicked])
                    return
                end if
                
            end if
        end if
        
        if doredraw then
            wc_call_draw(wid)
        end if
    end if
end procedure


procedure wc_resize(atom wid)
    atom idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wc_call_draw(wid)
        wc_call_draw(parent_of(wid))

    end if
end procedure


procedure wc_arrange(atom wid)
    integer idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wc_call_draw(wid)
    end if
end procedure


function wc_debug(atom wid)
    sequence debuginfo = {}
    atom idx = find(wid, wcprops[wcpID])
    if idx > 0 then    
        debuginfo = {
            {"SoftFocus", wcprops[wcpSoftFocus][idx]},
            {"HardFocus", wcprops[wcpHardFocus][idx]},
            {"Pinned", wcprops[wcpPinned][idx]},
            {"SubMenu", wcprops[wcpSubMenu][idx]},
            {"AvoidRect", wcprops[wcpAvoidRect][idx]},
            {"Items", wcprops[wcpItems][idx]},
            {"Pressed", wcprops[wcpPressed][idx]},
            {"Selection", wcprops[wcpSelection][idx]},
            {"Root", wcprops[wcpRoot][idx]},
            
            {"OptShowPin", wcprops[wcpOptShowPin][idx]},
            
            {"Title", wcprops[wcpTitle][idx]}
        }
    end if
    return debuginfo
end function


wc_define(
    "menu",
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

