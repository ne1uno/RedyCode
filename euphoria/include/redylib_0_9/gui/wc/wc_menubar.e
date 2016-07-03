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
wcpMenus,
wcpPressed,
wcpSelection, --index of menu item shown
wcpMenuID

enum --for wcpMenus
mnuLabel,
mnuSubmenu,
mnuLabelRect,
mnuLabelTextPos


constant wcpLENGTH = wcpMenuID

wcprops = repeat({}, wcpLENGTH)




-- Theme variables -------------------------------


-- widgetclass handlers ----------------------------

procedure wc_create(atom wid, object wprops)
    sequence wmenus = {{}, {}, {}, {}}, mnus = {}
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do          
                case "menus" then
                    mnus = wprops[p][2]
                    for m = 1 to length(mnus) do
                        wmenus[mnuLabel] &= {mnus[m][1]}
                        wmenus[mnuSubmenu] &= {mnus[m][2]}
                        wmenus[mnuLabelRect] &= {{0, 0, 0, 0}}
                        wmenus[mnuLabelTextPos] &= {{0, 0}}
                    end for
                      
            end switch
        end if
    end for
    
    wcprops[wcpID] &= {wid}
    wcprops[wcpSoftFocus] &= {0}
    wcprops[wcpHardFocus] &= {0}
    wcprops[wcpMenus] &= {wmenus}
    wcprops[wcpPressed] &= {0}
    wcprops[wcpSelection] &= {0}
    wcprops[wcpMenuID] &= {0}
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
    sequence cmds, wrect, chwid, txex, box, wmenus
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
        
        wmenus = wcprops[wcpMenus][idx]
        for m = 1 to length(wmenus[mnuLabel]) do            
            box = wmenus[mnuLabelRect][m]
            box[2] += 1
            box[4] -= 1
            itmdisabled = (find('*', wmenus[mnuLabel][m]) = 1)

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
                    {DR_PenPos} & wmenus[mnuLabelTextPos][m],
                    {DR_Puts, wmenus[mnuLabel][m][2..$]}
                }
            else
                cmds &= {
                    {DR_Font, "Arial", 9, Normal},
                    {DR_TextColor, txtcolor},
                    {DR_PenPos} & wmenus[mnuLabelTextPos][m],
                    {DR_Puts, wmenus[mnuLabel][m]}
                }                
            end if

            
        end for
        
        oswin:draw(wh, cmds, "", wrect)
        
        chwid = children_of(wid)
        for ch = 1 to length(chwid) do
            wc_call_draw(chwid[ch])
        end for
    end if
end procedure


procedure wc_event(atom wid, sequence evtype, object evdata)
    sequence ampos, wrect, wmenus, winpos, avrect
    atom idx, wh, doredraw = 0, sel, sf = 0
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wrect = widget_get_rect(wid)
        wh = widget:widget_get_handle(wid)
        wrect[3] -= 1
        wrect[4] -= 1
        wmenus = wcprops[wcpMenus][idx]
        sel = wcprops[wcpSelection][idx]
        
        switch evtype do        
            case "MouseMove" then --{x, y, shift, mousepos[1], mousepos[2]}
                sf = 0
                for m = 1 to length(wmenus[mnuLabel]) do
                    if in_rect(evdata[1], evdata[2], wmenus[mnuLabelRect][m]) then
                        sf = m
                        if sel > 0 then
                            sel = m
                            doredraw = 1
                        end if
                        --if find('*', wmenus[mnuLabel][m]) = 0 then
                        --    set_mouse_pointer(wh, mArrow)
                        --else
                        --    set_mouse_pointer(wh, mNo)
                        --end if
                        set_mouse_pointer(wh, mArrow)
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
                for m = 1 to length(wmenus[mnuLabel]) do
                    if in_rect(evdata[1], evdata[2], wmenus[mnuLabelRect][m]) then
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
                if wcprops[wcpMenuID][idx] > 0 then
                    widget:wc_call_event(wcprops[wcpMenuID][idx], "unpressed", wid)
                end if
                doredraw = 1
                --end if
                if wcprops[wcpSelection][idx] > 0 then
                    for m = 1 to length(wmenus[mnuLabel]) do
                        if in_rect(evdata[1], evdata[2], wmenus[mnuLabelRect][m]) then
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
                if wcprops[wcpMenuID][idx] > 0 then
                    widget:wc_call_event(wcprops[wcpMenuID][idx], "unpressed", wid)
                end if
                doredraw = 1
                
            
            case "MenuClosed" then
                wcprops[wcpMenuID][idx] = 0
                wcprops[wcpPressed][idx] = 0
                --wcprops[wcpSelection][idx] = 0
                sel = 0
                doredraw = 1
                oswin:close_all_popups("1")
                
            case "MenuItemClicked" then
                --puts(1, "MenuItemClicked: " & evdata[2] & "\n")                
            
            case "LostFocus" then
                wcprops[wcpSoftFocus][idx] = 0
                wcprops[wcpMenuID][idx] = 0
                wcprops[wcpPressed][idx] = 0
                --wcprops[wcpSelection][idx] = 0
                sel = 0
                doredraw = 1
                --oswin:close_all_popups("1")
                
            case "changed" then
                wc_call_resize(wid)
                doredraw = 1
            
        end switch
        
        if sel != wcprops[wcpSelection][idx] then
            wcprops[wcpSelection][idx] = sel
            doredraw = 1
            --if wcprops[wcpMenuID][idx] > 0 then
                --widget:widget_destroy(wcprops[wcpMenuID][idx])
            wcprops[wcpMenuID][idx] = 0
            oswin:close_all_popups("2")
            --end if
            if sel > 0 and find('*', wcprops[wcpMenus][idx][mnuLabel][sel]) = 0 then --if not disabled then
                winpos = client_area_offset(wh)
                
                avrect = wcprops[wcpMenus][idx][mnuLabelRect][sel]
                avrect[1] += winpos[1]
                avrect[2] += winpos[2]
                avrect[3] += winpos[1]
                avrect[4] += winpos[2]

                wcprops[wcpMenuID][idx] = widget_create(widget_get_name(wid) & ".mnu" & wcprops[wcpMenus][idx][mnuLabel][sel], wid, "menu", {
                    {"title", wcprops[wcpMenus][idx][mnuLabel][sel]},
                    --{"items", wcprops[wcpMenus][idx][mnuSubmenu][sel]},
                    {"actions", wcprops[wcpMenus][idx][mnuSubmenu][sel]},
                    {"avoid", avrect & 0},
                    {"root", wid},
                    {"pressed", wcprops[wcpPressed][idx]}
                })
                if wcprops[wcpPressed][idx] = 0 then
                    widget:wc_call_event(wcprops[wcpMenuID][idx], "unpressed", wid)
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
        
        for m = 1 to length(wcprops[wcpMenus][idx][mnuLabel]) do
            txex = oswin:get_text_extent(wh, wcprops[wcpMenus][idx][mnuLabel][m])
            if find('*', wcprops[wcpMenus][idx][mnuLabel][m]) = 1 then
                txex = oswin:get_text_extent(wh, wcprops[wcpMenus][idx][mnuLabel][m][2..$])
            else
                txex = oswin:get_text_extent(wh, wcprops[wcpMenus][idx][mnuLabel][m])
            end if
            wcprops[wcpMenus][idx][mnuLabelRect][m] = {cx, 1, cx + txex[1] + 10, txex[2] + 6}
            wcprops[wcpMenus][idx][mnuLabelTextPos][m] = {cx + 5, floor((txex[2] + 6) / 2 - txex[2] / 2)}
            
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
            {"Menus", wcprops[wcpMenus][idx]},
            {"Pressed", wcprops[wcpPressed][idx]},
            {"Selection", wcprops[wcpSelection][idx]},
            {"MenuID", wcprops[wcpMenuID][idx]}
        }
    end if
    return debuginfo
end function



wc_define(
    "menubar",
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
procedure wc_deselect(atom wid, object params)  --menu is requesting to be disassociated because it has been pinned or closed
    atom idx, doredraw = 0, sel
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wcprops[wcpPressed][idx] = 0
        wcprops[wcpSelection][idx] = 0
        wcprops[wcpMenuID][idx] = 0
        wc_call_draw(wid)
    end if
end procedure
wc_define_command("menubar", "deselect", routine_id("wc_deselect"))
*/

procedure cmd_set_menus(atom wid, sequence wsubmenus)
    atom idx
    sequence wmenus = {{}, {}, {}, {}}

    idx = find(wid, wcprops[wcpID])    
    if idx > 0 then
        for m = 1 to length(wsubmenus) do
            wmenus[mnuLabel] &= {wsubmenus[m][1]}
            wmenus[mnuSubmenu] &= {wsubmenus[m][2]}
            wmenus[mnuLabelRect] &= {{0, 0, 0, 0}}
            wmenus[mnuLabelTextPos] &= {{0, 0}}
        end for
        wcprops[wcpMenus][idx] = wmenus

        wc_call_event(wid, "changed", {})
    end if
    
end procedure
wc_define_command("menubar", "set_menus", routine_id("cmd_set_menus"))



/*
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
wc_define_function("menubar", "add_item", routine_id("cmd_add_item"))


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


procedure cmd_clear_items(atom wid)
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
wc_define_command("menubar", "clear_items", routine_id("cmd_clear_items"))
*/

