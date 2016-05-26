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
wcpInfos,
wcpPressed,
wcpSelection, --index of info item shown
wcpInfoID

enum --for wcpInfos
infLabel,
infSubinfo,
infLabelRect,
infLabelTextPos


constant wcpLENGTH = wcpInfoID

wcprops = repeat({}, wcpLENGTH)




-- Theme variables -------------------------------


-- widgetclass handlers ----------------------------

procedure wc_create(atom wid, object wprops)
    sequence winfos = {{}, {}, {}, {}}, wsubinfos = {}
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do          
                case "infos" then
                    wsubinfos = wprops[p][2]
                    for m = 1 to length(wsubinfos) do
                        winfos[infLabel] &= {wsubinfos[m][1]}
                        winfos[infSubinfo] &= {wsubinfos[m][2]}
                        winfos[infLabelRect] &= {{0, 0, 0, 0}}
                        winfos[infLabelTextPos] &= {{0, 0}}
                    end for
                    
            end switch
        end if
    end for
    
    wcprops[wcpID] &= {wid}
    wcprops[wcpSoftFocus] &= {0}
    wcprops[wcpHardFocus] &= {0}
    wcprops[wcpInfos] &= {winfos}
    wcprops[wcpPressed] &= {0}
    wcprops[wcpSelection] &= {0}
    wcprops[wcpInfoID] &= {0}
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
    sequence cmds, wrect, chwid, txex, box, winfos
    atom idx, wh, wf, hlcolor, shcolor, fillcolor, txtcolor, chkcolor, itmdisabled
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wrect = widget_get_rect(wid)
        --wrect[3] -= 1
        --wrect[4] -= 1
        
        wh = widget:widget_get_handle(wid)
        wf = (wh = oswin:get_window_focus())
        
        --fill:
        cmds = {
            {DR_PenColor, th:cButtonFace},
            {DR_Rectangle, True} & wrect,

            {DR_PenColor, cButtonHighlight},
            {DR_Line, wrect[1] + 1, wrect[2], wrect[3] - 1, wrect[2]},
            {DR_Line, wrect[1], wrect[2] + 1, wrect[1], wrect[4] - 1},
            
            {DR_PenColor, cButtonShadow},
            {DR_Line, wrect[3] - 1, wrect[2], wrect[3] - 1, wrect[4] - 1},
            {DR_Line, wrect[1], wrect[4] - 1, wrect[3] - 1, wrect[4] - 1}
        }
        
        winfos = wcprops[wcpInfos][idx]
        for m = 1 to length(winfos[infLabel]) do            
            box = winfos[infLabelRect][m]
            box[2] += 1
            box[4] -= 1
            itmdisabled = (find('*', winfos[infLabel][m]) = 1)

            if wcprops[wcpSelection][idx] = m and wf and itmdisabled = 0 then
                chkcolor = th:cInnerSel
                txtcolor = th:cInnerTextSel
            else
                if wcprops[wcpSoftFocus][idx] = m and itmdisabled = 0 then
                    chkcolor = th:cInnerSel
                    txtcolor = th:cInnerTextSel
                    --chkcolor = th:cInnerHover
                    --txtcolor = th:cInnerTextHover
                else
                    chkcolor = th:cButtonFace
                    txtcolor = th:cButtonLabel
                end if                
            end if
            
                       
            if wcprops[wcpPressed][idx] and wf then  --and wcprops[wcpSelection][idx] = m then
                hlcolor = th:cButtonShadow
                shcolor = th:cButtonHighlight
            else
                hlcolor = th:cButtonHighlight
                shcolor = th:cButtonShadow
            end if
            
            --checkbox fill:
            cmds &= {
                {DR_PenColor, chkcolor},
                {DR_Rectangle, True} & box
            }

            --border:
            if (wcprops[wcpSelection][idx] = m and wf and itmdisabled = 0) or wcprops[wcpSoftFocus][idx] = m then
                cmds &= {
                    {DR_PenColor, hlcolor},
                    {DR_Line, box[1] + 1, box[2], box[3] - 1, box[2]},
                    {DR_Line, box[1], box[2] + 1, box[1], box[4] - 1},
                    
                    {DR_PenColor, shcolor},
                    {DR_Line, box[3] - 1, box[2], box[3] - 1, box[4] - 1},
                    {DR_Line, box[1], box[4] - 1, box[3] - 1, box[4] - 1}
                }
            end if
            
            --label:
            if itmdisabled = 1 then --disabled item
                cmds &= {
                    {DR_Font, "Arial", 9, Normal},
                    {DR_TextColor, th:cButtonDisLabel},
                    {DR_PenPos} & winfos[infLabelTextPos][m],
                    {DR_Puts, winfos[infLabel][m][2..$]}
                }
            else
                cmds &= {
                    {DR_Font, "Arial", 9, Normal},
                    {DR_TextColor, txtcolor},
                    {DR_PenPos} & winfos[infLabelTextPos][m],
                    {DR_Puts, winfos[infLabel][m]}
                }                
            end if

            
        end for
        
        draw(wh, cmds)
        
        chwid = children_of(wid)
        for ch = 1 to length(chwid) do
            wc_call_draw(chwid[ch])
        end for
    end if
end procedure


procedure wc_event(atom wid, sequence evtype, object evdata)
    sequence ampos, wrect, winfos, winpos, avrect
    atom idx, wh, doredraw = 0, sel, sf = 0
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wrect = widget_get_rect(wid)
        wh = widget:widget_get_handle(wid)
        wrect[3] -= 1
        wrect[4] -= 1
        winfos = wcprops[wcpInfos][idx]
        sel = wcprops[wcpSelection][idx]
        
        switch evtype do        
            case "MouseMove" then --{x, y, shift, mousepos[1], mousepos[2]}
                sf = 0
                for m = 1 to length(winfos[infLabel]) do
                    if in_rect(evdata[1], evdata[2], winfos[infLabelRect][m]) then
                        sf = m
                        if sel > 0 then
                            sel = m
                            doredraw = 1
                        end if
                        if find('*', winfos[infLabel][m]) = 0 then
                            set_mouse_pointer(wh, mArrow)
                        else
                            set_mouse_pointer(wh, mNo)
                        end if
                    end if
                end for
                if sf != wcprops[wcpSoftFocus][idx] then
                    wcprops[wcpSoftFocus][idx] = sf
                    doredraw = 1
                end if
            
            case "LeftDown" then
                if wcprops[wcpPressed][idx] = 0 then
                    wcprops[wcpPressed][idx] = 1
                    doredraw = 1
                end if
                for m = 1 to length(winfos[infLabel]) do
                    if in_rect(evdata[1], evdata[2], winfos[infLabelRect][m]) then
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
                if wcprops[wcpInfoID][idx] > 0 then
                    widget:wc_call_event(wcprops[wcpInfoID][idx], "unpressed", wid)
                end if
                doredraw = 1
                --end if
                if wcprops[wcpSelection][idx] > 0 then
                    for m = 1 to length(winfos[infLabel]) do
                        if in_rect(evdata[1], evdata[2], winfos[infLabelRect][m]) then
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
                if wcprops[wcpInfoID][idx] > 0 then
                    widget:wc_call_event(wcprops[wcpInfoID][idx], "unpressed", wid)
                end if
                doredraw = 1
                
            
            case "InfoClosed" then
                wcprops[wcpInfoID][idx] = 0
                wcprops[wcpPressed][idx] = 0
                wcprops[wcpSelection][idx] = 0
                sel = 0
                doredraw = 1
                oswin:close_all_popups("1")
                
            case "InfoItemClicked" then
                --puts(1, "InfoItemClicked: " & evdata[2] & "\n")                
            
            case "LostFocus" then
                wcprops[wcpSoftFocus][idx] = 0
                wcprops[wcpInfoID][idx] = 0
                wcprops[wcpPressed][idx] = 0
                wcprops[wcpSelection][idx] = 0
                sel = 0
                doredraw = 1
                
            case "changed" then
                wc_call_resize(wid)
                doredraw = 1
            
        end switch
        
        if sel != wcprops[wcpSelection][idx] then
            wcprops[wcpSelection][idx] = sel
            doredraw = 1
            --if wcprops[wcpInfoID][idx] > 0 then
                --widget:widget_destroy(wcprops[wcpInfoID][idx])
            wcprops[wcpInfoID][idx] = 0
            oswin:close_all_popups("2")
            --end if
            if sel > 0 and find('*', wcprops[wcpInfos][idx][infLabel][sel]) = 0 then --if not disabled then
                winpos = client_area_offset(wh)
                
                avrect = wcprops[wcpInfos][idx][infLabelRect][sel]
                avrect[1] += winpos[1]
                avrect[2] += winpos[2]
                avrect[3] += winpos[1]
                avrect[4] += winpos[2]

                wcprops[wcpInfoID][idx] = widget_create(widget_get_name(wid) & ".inf" & wcprops[wcpInfos][idx][infLabel][sel], wid, "info", {
                    {"title", wcprops[wcpInfos][idx][infLabel][sel]},
                    {"items", wcprops[wcpInfos][idx][infSubinfo][sel]}, --wcprops[wcpInfos][idx][infSubInfo][sel]}, --not implemented yet
                    {"avoid", avrect & 0},
                    {"root", wid},
                    {"pressed", wcprops[wcpPressed][idx]}
                })
                if wcprops[wcpPressed][idx] = 0 then
                    widget:wc_call_event(wcprops[wcpInfoID][idx], "unpressed", wid)
                end if
            end if
        end if
        
        if doredraw then
            wc_call_draw(wid)
        end if
        
    end if
end procedure


procedure wc_resize(atom wid)
    atom idx, wh, wparent, cx
    sequence wsize = {4, 4}, txex
        
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wh = widget_get_handle(wid)
        oswin:set_font(wh, "Arial", 9, Normal)
        cx = 5
        
        for m = 1 to length(wcprops[wcpInfos][idx][infLabel]) do
            txex = oswin:get_text_extent(wh, wcprops[wcpInfos][idx][infLabel][m])
            if find('*', wcprops[wcpInfos][idx][infLabel][m]) = 1 then
                txex = oswin:get_text_extent(wh, wcprops[wcpInfos][idx][infLabel][m][2..$])
            else
                txex = oswin:get_text_extent(wh, wcprops[wcpInfos][idx][infLabel][m])
            end if
            wcprops[wcpInfos][idx][infLabelRect][m] = {cx, 1, cx + txex[1] + 10, txex[2] + 6}
            wcprops[wcpInfos][idx][infLabelTextPos][m] = {cx + 5, floor((txex[2] + 6) / 2 - txex[2] / 2)}
            
            cx += txex[1] + 10
            wsize = {cx, txex[2] + 7}
        end for
        
        widget:widget_set_min_size(wid, wsize[1], wsize[2])
        widget:widget_set_natural_size(wid, wsize[1], 0)
        
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
            {"HardFocus", wcprops[wcpHardFocus][idx]},
            {"Infos", wcprops[wcpInfos][idx]},
            {"Pressed", wcprops[wcpPressed][idx]},
            {"Selection", wcprops[wcpSelection][idx]},
            {"InfoID", wcprops[wcpInfoID][idx]}
        }
    end if
    return debuginfo
end function



wc_define(
    "infobar",
    routine_id("wc_create"),
    routine_id("wc_destroy"),
    routine_id("wc_draw"),
    routine_id("wc_event"),
    routine_id("wc_resize"),
    routine_id("wc_arrange"),
    routine_id("wc_debug")
)   
    

-- widgetclass commands -------------------------------------------------------

/*
procedure wc_deselect(atom wid, object params)  --info is requesting to be disassociated because it has been pinned or closed
    atom idx, doredraw = 0, sel
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wcprops[wcpPressed][idx] = 0
        wcprops[wcpSelection][idx] = 0
        wcprops[wcpInfoID][idx] = 0
        wc_call_draw(wid)
    end if
end procedure
wc_define_command("infobar", "deselect", routine_id("wc_deselect"))
*/

procedure cmd_set_infos(atom wid, sequence wsubinfos)
    atom idx
    sequence winfos = {{}, {}, {}, {}}

    idx = find(wid, wcprops[wcpID])    
    if idx > 0 then
        for m = 1 to length(wsubinfos) do
            winfos[infLabel] &= {wsubinfos[m][1]}
            winfos[infSubinfo] &= {wsubinfos[m][2]}
            winfos[infLabelRect] &= {{0, 0, 0, 0}}
            winfos[infLabelTextPos] &= {{0, 0}}
        end for
        wcprops[wcpInfos][idx] = winfos

        wc_call_event(wid, "changed", {})
    end if
    
end procedure
wc_define_command("infobar", "set_infos", routine_id("cmd_set_infos"))

