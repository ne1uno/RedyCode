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
wcpOrientation, --0: Vertical 1: Horizontal
wcpTools,
wcpMonitoring,
wcpPressed,
wcpSelection,
wcpTitle


enum --for wcpTools
itmType,
itmLabel,
itmIcon,
itmEnabled,
itmRect,
itmActionName,
itmActionState,
itmActionList

enum
ttSeparator,    --space between tools "-"
ttLabel,        --label, to display info such as mouse coords "--label text"
ttTrigger,      --Momentary button that triggers "action_name" or "action_name={paramaters}"
ttToggle,       --Toggle button that triggers "action_name", switching between 2 paramater values
ttList,         --Dropdown list that triggers "action_name" with the selected paramater value
ttTextbox,      --Textbox that triggers "action_name" with the text as a paramater value
ttNumberbox     --Number range selector that triggers "action_name"  with the number as a paramater value 


constant wcpLENGTH = wcpTitle

wcprops = repeat({}, wcpLENGTH)


-- Theme variables -------------------------------

atom
thToolIconSize = 16,
thToolButtonSize = thToolIconSize + 6,
thToolbarSize = thToolButtonSize + 6,
thToolbarHandleSize = 12

-- Local routines ----------------------------------
    

procedure update_tool(sequence actionname, sequence propname, object propdata)
    atom t
    for idx = 1 to length(wcprops[wcpID]) do
        t = find(actionname, wcprops[wcpTools][idx][itmActionName])
        if t > 0 then
            switch propname do
            case "enabled" then
                --puts(1, "update: " & actionname & ", ")
                --pretty_print(1, {propname, propdata}, {2})
                
                widget:wc_call_event(wcprops[wcpID][idx], "ActionChanged", {actionname, "enabled", propdata})
            case "state" then
                widget:wc_call_event(wcprops[wcpID][idx], "ActionChanged", {actionname, "state", propdata})
            case "list" then
                widget:wc_call_event(wcprops[wcpID][idx], "ActionChanged", {actionname, "list", propdata})
            case "hotkey" then
                --widget:wc_call_event(wcprops[wcpID][idx], "ActionChanged", {actionname, "hotkey", propdata})
            end switch
        end if
    end for
end procedure


-- widgetclass handlers ----------------------------

procedure wc_create(atom wid, object wprops) 
    atom wparent
    sequence wsize = {20, 20}, wactions = {}, 
    tools = {{}, {}, {}, {}, {}, {}, {}, {}}, avrect = {0, 0, 0, 0, 0}, wtitle = ""
    object atype, alabel, aicon, adescription, aundoable, aenabled, ahotkey, astate, alist
    
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do          
                case "tools" then
                    wactions = wprops[p][2]
                    
                case "title" then
                    wtitle = wprops[p][2]
                    
            end switch
        end if
    end for
    
    for i = 1 to length(wactions) do
        if equal(wactions[i], "-") then
            tools[itmType] &= {ttSeparator}
            tools[itmLabel] &= {"-"}
            tools[itmIcon] &= {0}
            tools[itmEnabled] &= {0}
            tools[itmRect] &= {0}
            tools[itmActionName] &= {0}
            tools[itmActionState] &= {{}}
            tools[itmActionList] &= {{}}
            
        else
            atype = action:get_type(wactions[i])
            alabel = action:get_label(wactions[i])
            aicon = action:get_icon(wactions[i])
            
            if sequence(atype) then
                switch atype do
                case "label" then
                    tools[itmType] &= {ttLabel}
                case "trigger" then
                    tools[itmType] &= {ttTrigger}
                case "toggle" then
                    tools[itmType] &= {ttToggle}
                case "list" then
                    tools[itmType] &= {ttList}
                case "text" then
                    tools[itmType] &= {ttTextbox}
                case "number" then
                    tools[itmType] &= {ttNumberbox}
                end switch
                
                tools[itmLabel] &= {alabel}
                tools[itmIcon] &= {aicon}
                tools[itmEnabled] &= {0}
                tools[itmRect] &= {0}
                tools[itmActionName] &= {wactions[i]}
                tools[itmActionState] &= {{}}
                tools[itmActionList] &= {{}}
            end if
            --action:monitor(wactions[i], routine_id("update_tool"))
        end if
    end for
    
    --pretty_print(1, wactions, {2})
    --pretty_print(1, tools, {2})
    
    widget:widget_set_size(wid, wsize[1], wsize[2])
    
    wcprops[wcpID] &= {wid}
    wcprops[wcpSoftFocus] &= {0}
    wcprops[wcpHardFocus] &= {0}
    wcprops[wcpOrientation] &= {0}
    wcprops[wcpTools] &= {tools}
    wcprops[wcpMonitoring] &= {0}
    wcprops[wcpPressed] &= {0}
    wcprops[wcpSelection] &= {0}
    wcprops[wcpTitle] &= {wtitle}
    
    --wparent = parent_of(wid)
    --if wparent > 0 then
    --    widget:wc_call_event(wparent, "child created", {wid, wprops})
    --end if
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
    sequence cmds = {}, wrect, hrect, chwid, txex, box, tools, ttpos
    atom idx = find(wid, wcprops[wcpID]), wh, wf, hlcolor, shcolor, hicolor, fillcolor, txtcolor, chkcolor, x1, y1, c
    object ttcmds = {}, invalidrect = 0
    
    if idx > 0 then
        wrect = widget_get_rect(wid)
        wh = widget:widget_get_handle(wid)
        wf = (wh = oswin:get_window_focus())
        
        hicolor = th:cOuterFill
        shcolor = th:cButtonShadow
        hlcolor = th:cButtonHighlight
        
        --draw border and handle:
        cmds &= {
        --fill:
            {DR_PenColor, hicolor},
            {DR_Rectangle, True} & wrect
        }
        
        --hrect = {wrect[1]+3, wrect[2]+3, wrect[1]+7, wrect[4]-3}
        hrect = {wrect[1]+5, wrect[2]+4, wrect[1]+6, wrect[4]-4}
        cmds &= {
        --handle:
            {DR_PenColor, hlcolor},
            {DR_Line, hrect[1]-1, hrect[2]-1, hrect[3], hrect[2]-1},
            {DR_Line, hrect[1]-1, hrect[2]-1, hrect[1]-1, hrect[4]},
            
            {DR_PenColor, shcolor},
            
            {DR_Line, hrect[3], hrect[2]-1, hrect[3], hrect[4]},
            {DR_Line, hrect[1]-1, hrect[4], hrect[3], hrect[4]}
        }
        
        cmds &= {
        --border:
            {DR_PenColor, hlcolor},
            {DR_Line, wrect[1]-1, wrect[2]-1, wrect[3], wrect[2]-1},
            {DR_Line, wrect[1]-1, wrect[2]-1, wrect[1]-1, wrect[4]},
            
            {DR_PenColor, shcolor},
            
            {DR_Line, wrect[3], wrect[2]-1, wrect[3], wrect[4]},
            {DR_Line, wrect[1]-1, wrect[4], wrect[3], wrect[4]}
        }
        
        
        --Draw tools -------------------------------------------
        
        --tools[itmType]
        --tools[itmLabel]
        --tools[itmIcon]
        --tools[itmEnabled]
        --tools[itmRect]
        --tools[itmActionName]
        --tools[itmActionState]
        --tools[itmActionList]
        
        --thToolIconSize
        --thToolButtonSize
        --thToolbarSize
        --thToolbarHandleSize
        
        tools = wcprops[wcpTools][idx]
        for t = 1 to length(tools[itmType]) do
            if sequence(tools[itmRect][t]) then
                box = tools[itmRect][t]
                box[1] += wrect[1]
                box[2] += wrect[2]
                box[3] += wrect[1]
                box[4] += wrect[2]
                
                if tools[itmType][t] = ttSeparator then
                    --item fill:
                    chkcolor = th:cOuterFill
                    cmds &= {
                        {DR_PenColor, chkcolor},
                        {DR_Rectangle, True} & box
                    }
                    --line:
                    c = box[1] + floor((box[3] - box[1]) / 2)
                    box[1] = c - 1
                    box[2] += 1
                    box[3] = c + 1
                    box[4] -= 1
                    
                    hlcolor = th:cButtonShadow
                    shcolor = th:cButtonHighlight
                    cmds &= {
                        {DR_PenColor, hlcolor},
                        {DR_Line, box[1] + 1, box[2], box[3] - 1, box[2]},
                        {DR_Line, box[1], box[2] + 1, box[1], box[4] - 1},
                        {DR_PenColor, shcolor},
                        {DR_Line, box[3] - 1, box[2], box[3] - 1, box[4] - 1},
                        {DR_Line, box[1], box[4] - 1, box[3] - 1, box[4] - 1}
                    }
                    
                elsif tools[itmType][t] = ttLabel then
                    chkcolor = th:cButtonFace
                    txtcolor = th:cButtonLabel
                    cmds &= {
                        {DR_PenColor, chkcolor},
                        {DR_Rectangle, True} & box,
                        {DR_Font, "Arial", 9, Normal},
                        {DR_TextColor, txtcolor},
                        {DR_PenPos, box[1], box[2]},
                        {DR_Puts, tools[itmLabel][t]}
                    }
                /*
                elsif tools[itmType][t] = ttTrigger then
                elsif tools[itmType][t] = ttToggle then
                elsif tools[itmType][t] = ttList then
                elsif tools[itmType][t] = ttTextbox then
                elsif tools[itmType][t] = ttNumberbox then
                */
                
                else --other types have borders around them and respond to user input
                    if wcprops[wcpSelection][idx] = t and tools[itmEnabled][t] then
                        chkcolor = th:cInnerSel
                        txtcolor = th:cInnerTextSel
                    else
                        if wcprops[wcpSoftFocus][idx] = t and tools[itmEnabled][t] then
                            chkcolor = th:cInnerSel
                            txtcolor = th:cInnerTextSel
                        else
                            chkcolor = th:cOuterFill --cButtonFace
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
                        {DR_Rectangle, False, box[1]-1, box[2]-1, box[3]+1, box[4]+1}
                    }
                    
                    --icon
                    if tools[itmEnabled][t] then
                        cmds &= {
                            {DR_Image, tools[itmIcon][t], 
                                box[1] + floor(thToolButtonSize / 2 - thToolIconSize / 2),
                                box[2] + floor(thToolButtonSize / 2 - thToolIconSize / 2),
                                rgb(0, 0, 0)
                            }
                        }
                    else
                        --bitmap_effect(atom hwnd, sequence bitmapname, sequence effectname, atom refresh = 0)
                        cmds &= {
                            {DR_Image, oswin:bitmap_effect(wh, tools[itmIcon][t], "disabled"), 
                                box[1] + floor(thToolButtonSize / 2 - thToolIconSize / 2),
                                box[2] + floor(thToolButtonSize / 2 - thToolIconSize / 2),
                                rgb(0, 0, 0) --transparancy color
                            }
                        }
                    end if
                    --thToolIconSize
                    --thToolButtonSize
                    --thToolbarSize
                    --thToolbarHandleSize
                    
                    --border:
                    if wcprops[wcpSoftFocus][idx] = t and tools[itmEnabled][t] then
                        cmds &= {
                            {DR_PenColor, hlcolor},
                            {DR_Line, box[1] + 1, box[2], box[3] - 1, box[2]},
                            {DR_Line, box[1], box[2] + 1, box[1], box[4] - 1},
                            {DR_PenColor, shcolor},
                            {DR_Line, box[3] - 1, box[2], box[3] - 1, box[4] - 1},
                            {DR_Line, box[1], box[4] - 1, box[3] - 1, box[4] - 1}
                        }
                    end if
                    --tooltip:
                    if wcprops[wcpSoftFocus][idx] = t and tools[itmEnabled][t] then
                        ttpos = {box[1], box[4] + 6} --todo: reposition if outside window dimensions
                        oswin:set_font(wh, "Arial", 9, Normal)
                        txex = oswin:get_text_extent(wh, tools[itmLabel][t])
                        --invalidrect = {ttpos[1], ttpos[2], ttpos[1] + txex[1] + 6, ttpos[2] + txex[2] + 6}
                        ttcmds = {
                            {DR_PenColor, rgb(255, 255, 200)},
                            {DR_Rectangle, True, ttpos[1], ttpos[2], ttpos[1] + txex[1] + 6, ttpos[2] + txex[2] + 6},
                            {DR_PenColor, rgb(140, 140, 140)},
                            {DR_Rectangle, False, ttpos[1], ttpos[2], ttpos[1] + txex[1] + 6, ttpos[2] + txex[2] + 6},
                            
                            {DR_Font, "Arial", 9, Normal},
                            {DR_TextColor, rgb(0, 0, 0)},
                            {DR_PenPos, ttpos[1] + 3, ttpos[2] + 3},
                            {DR_Puts, tools[itmLabel][t]}
                        }
                    end if
                end if
            end if
        end for
        
        
        
        
        /*
        tools = wcprops[wcpTools][idx]
        --tools[itmType]
        --tools[itmLabel]
        --tools[itmIcon]
        --tools[itmEnabled]
        --tools[itmRect]
        --tools[itmActionName]
        --tools[itmActionState]
        --tools[itmActionList]
        
        for m = 1 to length(tools[itmLabel]) do            
            box = tools[itmRect][m]
            
            if wcprops[wcpSelection][idx] = m and tools[itmType][m] != 2 and tools[itmEnabled][m] then
                chkcolor = th:cInnerSel
                txtcolor = th:cInnerTextSel
            else
                if wcprops[wcpSoftFocus][idx] = m and tools[itmType][m] != 2 and tools[itmEnabled][m] then
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
            if wcprops[wcpSoftFocus][idx] = m and tools[itmType][m] != 2 and tools[itmEnabled][m] then
                cmds &= {
                    {DR_PenColor, hlcolor},
                    {DR_Line, box[1] + 1, box[2], box[3] - 1, box[2]},
                    {DR_Line, box[1], box[2] + 1, box[1], box[4] - 1},
                    {DR_PenColor, shcolor},
                    {DR_Line, box[3] - 1, box[2], box[3] - 1, box[4] - 1},
                    {DR_Line, box[1], box[4] - 1, box[3] - 1, box[4] - 1}
                }
            end if
            
            if tools[itmType][m] = 0 then --special pin button
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
                
            elsif tools[itmType][m] = 1 then --normal (depreciated, now 4 is used - action name)
                --label:
                if tools[itmEnabled][m] then
                    cmds &= {
                        {DR_Font, "Arial", 9, Normal},
                        {DR_TextColor, txtcolor},
                        {DR_PenPos} & tools[itmTextPos][m],
                        {DR_Puts, tools[itmLabel][m]}
                    }
                else
                    cmds &= {
                        {DR_Font, "Arial", 9, Normal},
                        {DR_TextColor, rgb(120, 120, 120)},
                        {DR_PenPos} & tools[itmTextPos][m],
                        {DR_Puts, tools[itmLabel][m][2..$]}
                    }
                end if
                
            elsif tools[itmType][m] = 2 then --separator
                cmds &= {
                    {DR_PenColor, th:cButtonHighlight},
                    {DR_Line, box[1] + 3, box[2] + 2, box[3] - 3, box[2] + 2},
                    {DR_PenColor, th:cButtonShadow},
                    {DR_Line, box[1] + 3, box[2] + 3, box[3] - 3, box[2] + 3}
                }
                
            elsif tools[itmType][m] = 3 then --submenu
                itmh = 16
                x1 = box[3] - itmh - 2
                y1 = box[2] + 2
                
                if tools[itmEnabled][m] then
                    cmds &= {
                    --label:
                        {DR_Font, "Arial", 9, Normal},
                        {DR_TextColor, txtcolor},
                        {DR_PenPos} & tools[itmTextPos][m],
                        {DR_Puts, tools[itmLabel][m]},
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
                        {DR_PenPos} & tools[itmTextPos][m],
                        {DR_Puts, tools[itmLabel][m][2..$]},
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
                
            elsif tools[itmType][m] = 4 then --action name
                --icon or color
                if atom(tools[itmIcon][m]) then --a rgb color
                    cmds &= {
                        --item icon - solid color
                        {DR_PenColor, tools[itmIcon][m]},
                        {DR_Rectangle, True, box[1] + 2, box[2] + 2, box[1] + 2 + iconsize, box[2] + 2 + iconsize}
                    }
                elsif length(tools[itmIcon][m]) > 0 then --a string representing the bitmap already loaded by load_bitmap()
                    cmds &= {
                        --item icon - image (must be 16 x 16!)
                        {DR_Image, tools[itmIcon][m], box[1] + 2, box[2] + 2}
                    }
                else   --empty string - no icon
                    
                end if
            
            
            
                --label:
                if tools[itmEnabled][m] then
                    cmds &= {
                        {DR_Font, "Arial", 9, Normal},
                        {DR_TextColor, txtcolor},
                        {DR_PenPos} & tools[itmTextPos][m],
                        {DR_Puts, tools[itmLabel][m]}
                    }
                else
                    cmds &= {
                        {DR_Font, "Arial", 9, Normal},
                        {DR_TextColor, rgb(120, 120, 120)},
                        {DR_PenPos} & tools[itmTextPos][m],
                        {DR_Puts, tools[itmLabel][m][2..$]}
                    }
                    
                end if
            end if
        end for*/
        
        oswin:draw(wh, cmds, "", wrect)
        
        if sequence(ttcmds) then
            oswin:draw_direct(wh, ttcmds, 1, invalidrect) --(atom hwnd, sequence cmds, atom clearcmds = 1, object invalidrect = 0)
        end if
    end if
end procedure


procedure wc_event(atom wid, sequence evtype, object evdata)
    sequence ampos, wrect, tools, wsize, wtitle, wpos, winpos, avrect
    atom idx, t, wh, doredraw = 0, winhandle, wparent, cy, clicked = 0, sel, sf = 0
    sequence wname
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wrect = widget_get_rect(wid)
        wh = widget:widget_get_handle(wid)
        wrect[3] -= 1
        wrect[4] -= 1
        tools = wcprops[wcpTools][idx]
        sel = wcprops[wcpSelection][idx]
        sf = wcprops[wcpSoftFocus][idx]
        
        
        
        switch evtype do
        case "ActionChanged" then
            --pretty_print(1, {idx, evtype, evdata}, {2})
            
            --tools[itmType]
            --tools[itmLabel]
            --tools[itmIcon]
            --tools[itmEnabled]
            --tools[itmRect]
            --tools[itmActionName]
            --tools[itmActionState]
            --tools[itmActionList]
            
            t = find(evdata[1], wcprops[wcpTools][idx][itmActionName])
            if t > 0 then
                switch evdata[2] do
                case "enabled" then
                    wcprops[wcpTools][idx][itmEnabled][t] = evdata[3]
                    --? wcprops[wcpTools][idx][itmEnabled][t]
                    doredraw = 1
                case "state" then
                    wcprops[wcpTools][idx][itmActionState][t] = evdata[3]
                    wc_call_resize(wid)
                case "list" then
                    wcprops[wcpTools][idx][itmActionList][t] = evdata[3]
                    wc_call_resize(wid)
                case "hotkey" then
                    
                end switch
            end if
            
        case "MouseMove" then --{x, y, shift, mousepos[1], mousepos[2]}
            sf = 0
            for m = 1 to length(tools[itmLabel]) do
                if sequence(tools[itmRect][m]) and in_rect(evdata[1] - wrect[1], evdata[2] - wrect[2], tools[itmRect][m]) then
                    sf = m
                    if sel > 0 then
                        sel = m
                        doredraw = 1
                    end if
                    set_mouse_pointer(wh, mArrow)
                end if
            end for
            
        case "NonClientMouseMove" then
            wcprops[wcpSoftFocus][idx] = 0
            wcprops[wcpPressed][idx] = 0
            wcprops[wcpSelection][idx] = 0
            doredraw = 1
            
        case "LeftDown" then
            if wcprops[wcpPressed][idx] = 0 then
                wcprops[wcpPressed][idx] = 1
                doredraw = 1
            end if
            for m = 1 to length(tools[itmLabel]) do
                if sequence(tools[itmRect][m]) and in_rect(evdata[1] - wrect[1], evdata[2] - wrect[2], tools[itmRect][m]) then
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
            for m = 1 to length(tools[itmLabel]) do
                if sequence(tools[itmRect][m]) and in_rect(evdata[1] - wrect[1], evdata[2] - wrect[2], tools[itmRect][m]) then
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
            
            wcprops[wcpPressed][idx] = 0
            
            doredraw = 1
            
            for m = 1 to length(tools[itmLabel]) do
                if sequence(tools[itmRect][m]) and in_rect(evdata[1] - wrect[1], evdata[2] - wrect[2], tools[itmRect][m]) then
                    clicked = m
                    exit
                end if
            end for
            --end if
            if wcprops[wcpSelection][idx] > 0 then
                for m = 1 to length(tools[itmLabel]) do
                    if sequence(tools[itmRect][m]) and in_rect(evdata[1] - wrect[1], evdata[2] - wrect[2], tools[itmRect][m]) then
                        sel = m
                        exit
                    end if
                end for
                doredraw = 1
            end if
            
        case "RightUp" then
            sel = 0
            
            wcprops[wcpPressed][idx] = 0
            
            doredraw = 1
            
            for m = 1 to length(tools[itmLabel]) do
                if sequence(tools[itmRect][m]) and in_rect(evdata[1] - wrect[1], evdata[2] - wrect[2], tools[itmRect][m]) then
                    clicked = m
                    exit
                end if
            end for
            --end if
            if wcprops[wcpSelection][idx] > 0 then
                for m = 1 to length(tools[itmLabel]) do
                    if sequence(tools[itmRect][m]) and in_rect(evdata[1] - wrect[1], evdata[2] - wrect[2], tools[itmRect][m]) then
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
            
        end switch
        
        
        if sel != wcprops[wcpSelection][idx] then
            wcprops[wcpSelection][idx] = sel
            doredraw = 1
        end if
            
        if sf != wcprops[wcpSoftFocus][idx] then
            wcprops[wcpSoftFocus][idx] = sf
            doredraw = 1
        end if
        
        if clicked > 0 and sequence(tools[itmActionName][clicked]) and tools[itmEnabled][clicked] then
            --tools[itmType]
            --tools[itmLabel]
            --tools[itmIcon]
            --tools[itmEnabled]
            --tools[itmRect]
            --tools[itmActionName]
            --tools[itmActionState]
            --tools[itmActionList]
            
            if tools[itmType][clicked] = ttSeparator then
                --do nothing
            elsif tools[itmType][clicked] = ttLabel then
                --do nothing
            elsif tools[itmType][clicked] = ttTrigger then
                action:do_proc(tools[itmActionName][clicked], tools[itmActionState][clicked])
                --tools[itmActionList]
            elsif tools[itmType][clicked] = ttToggle then
                --action:do_proc(tools[itmActionName][clicked], tools[][clicked])
            elsif tools[itmType][clicked] = ttList then
                --show dropdown list (create "list" widget)
            elsif tools[itmType][clicked] = ttTextbox then
                --move text cursor
            elsif tools[itmType][clicked] = ttNumberbox then
                --adjust value
            end if
        end if
        
        if doredraw then
            wc_call_draw(wid)
        end if
    end if
end procedure


procedure wc_resize(atom wid)
    atom idx, wh, wparent, tx, ty, sp
    sequence wsize, txex, tools
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wh = widget_get_handle(wid)
        oswin:set_font(wh, "Arial", 9, Normal)
        
        --tools[itmType]
        --tools[itmLabel]
        --tools[itmIcon]
        --tools[itmEnabled]
        --tools[itmRect]
        --tools[itmActionName]
        --tools[itmActionState]
        --tools[itmActionList]
        
        --thToolIconSize
        --thToolButtonSize
        --thToolbarSize
        --thToolbarHandleSize
        
        sp = floor(thToolbarSize / 2 - thToolButtonSize / 2)
        
        tx = thToolbarHandleSize
        ty = sp
        
        
        
        tools = wcprops[wcpTools][idx]
        for t = 1 to length(tools[itmType]) do
            if tools[itmType][t] = ttSeparator then
                tools[itmRect][t] = {tx, ty, tx + sp * 3, ty + thToolButtonSize}
                tx += sp * 3
                
            elsif tools[itmType][t] = ttLabel then
                --txex = oswin:get_text_extent(wh, tools[itmLabel][t])
                --tools[itmRect][t] = {tx, ty, tx + txex[1] + 16 + 8, ty + 16}
                --tx += txex[1] + 20 + 10
                
            elsif tools[itmType][t] = ttTrigger then
                tools[itmRect][t] = {tx, ty, tx + thToolButtonSize, ty + thToolButtonSize}
                tx += thToolButtonSize + sp
                
            elsif tools[itmType][t] = ttToggle then
                tools[itmRect][t] = {tx, ty, tx + thToolButtonSize, ty + thToolButtonSize}
                tx += thToolButtonSize + sp
                
            elsif tools[itmType][t] = ttList then
                --txex = oswin:get_text_extent(wh, tools[itmLabel][t])
                --tools[itmRect][t] = {tx, ty, tx + txex[1] + 16 + 8, ty + 16}
                --tx += txex[1] + 16 + 10
                
            elsif tools[itmType][t] = ttTextbox then
                --txex = oswin:get_text_extent(wh, tools[itmLabel][t])
                --tools[itmRect][t] = {tx, ty, tx + txex[1] + 16 + 8, ty + 16}
                --tx += txex[1] + 16 + 10
                
            elsif tools[itmType][t] = ttNumberbox then
                --txex = oswin:get_text_extent(wh, tools[itmLabel][t])
                --tools[itmRect][t] = {tx, ty, tx + txex[1] + 16 + 8, ty + 16}
                --tx += txex[1] + 16 + 10
                
            end if
        end for
        wcprops[wcpTools][idx] = tools
        
        wsize = {tx + floor((thToolButtonSize - thToolButtonSize) / 2), thToolbarSize}
        
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
        if not wcprops[wcpMonitoring][idx] then
            wcprops[wcpMonitoring][idx] = 1
            
            for t = 1 to length(wcprops[wcpTools][idx][itmType]) do
                if wcprops[wcpTools][idx][itmType][t] != ttSeparator then
                    action:monitor(wcprops[wcpTools][idx][itmActionName][t], routine_id("update_tool"))
                end if
            end for
        end if
        
        --wh = widget_get_handle(wid)
        --oswin:set_font(wh, "Arial", 9, Normal)
        --txex = oswin:get_text_extent(wh, wcprops[wcpLabel][idx])
        --wsize = widget_get_size(wid)
        --wcprops[wcpTextPos][idx] = {
        --    floor((wsize[1]) / 2 - txex[1] / 2),
        --    floor((wsize[2]) / 2 - txex[2] / 2)
        --}
        
        
        --puts(1, "\narrange: ")
        --pretty_print(1, wcprops[wcpTools][idx][itmRect], {2})
        
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
            {"Orientation", wcprops[wcpOrientation][idx]},
            {"Monitoring", wcprops[wcpMonitoring][idx]},
            {"Items", wcprops[wcpTools][idx]},
            {"Pressed", wcprops[wcpPressed][idx]},
            {"Selection", wcprops[wcpSelection][idx]},
            {"Title", wcprops[wcpTitle][idx]}
        }
    end if
    return debuginfo
end function


wc_define(
    "toolbar",
    routine_id("wc_create"),
    routine_id("wc_destroy"),
    routine_id("wc_draw"),
    routine_id("wc_event"),
    routine_id("wc_resize"),
    routine_id("wc_arrange"),
    routine_id("wc_debug")
)   
    

-- widgetclass commands -------------------------------------------------------



