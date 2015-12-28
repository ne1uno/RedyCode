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
include std/text.e


-- Internal class variables and routines

sequence wcprops

enum
wcpID,
wcpTitle,
wcpFormRect,
wcpSoftFocus,
wcpHardFocus,

wcpMode,

wcpMenubarID,
wcpInfobarID,
wcpFormID,

wcpToolbars,        --list of toolbar docked widgets {top, right, bottom, left}
wcpToolbarRects,    --list of rectangles representing toolbar positions and sizes {top, right, bottom, left}
wcpToolDockSizes,   --sizes of {top, right, bottom, left} toolbar dock areas

wcpPanels,          --list of panels (and tabs treated like panels because they are containing panels)
wcpDockSizes,       --sizes of {top, right, bottom, left} dock areas
wcpDockDividers,    --divider widget IDs of {top, right, bottom, left} dock areas
wcpPanelSizes,      --divider widget IDs in  {top, right, bottom, left}
wcpPanelDividers,   --sizes of panels/tabs in {top, right, bottom, left}
wcpTabs

constant wcpLENGTH = wcpTabs

wcprops = repeat({}, wcpLENGTH)

enum    --panel properties:
pnlId,      --panel widget ids
pnlDock,    --panel dock area (1 = top, 2 = right, 3 = bottom, 4 = left)
pnlDockIdx, --position in dock area
pnlTabIdx,  --position in tabs
pnlSize     --height or width of panel

atom
DefaultPanelSize = 300,
PanelSizerWidth = 8


-- Theme variables -------------------------------




-- widgetclass handlers ----------------------------

procedure wc_create(atom wid, object wprops)
    sequence wname, wtitle = "", wpos, wsize, displaysize
    atom winhandle, wallowclose = 1, wmode = 0, wtopmost = 0, wmodal = 0, bcolor
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do
                case "allow_close" then
                    wallowclose = wprops[p][2]          
                case "title" then
                    wtitle = wprops[p][2]
                case "topmost" then
                    wtopmost = wprops[p][2]
                case "modal" then
                    wmodal = wprops[p][2]
                case "mode" then
                    if equal(wprops[p][2], "window") then
                        wmode = 0
                    elsif equal(wprops[p][2], "dialog") then
                        wmode = 1
                    elsif equal(wprops[p][2], "screen") then
                        wmode = 2
                    elsif equal(wprops[p][2], "dock") then
                        wmode = 3
                    end if
            end switch
        end if
    end for
    
    if wmode = 0 then  --"window"
        wname = widget:widget_get_name(wid)
        wpos = widget:widget_get_pos(wid)
        wsize = widget:widget_get_default_size(wid)
        displaysize = oswin:getPrimaryDisplaySize()
        if wpos[1] = -1 then
            wpos[1] = floor(displaysize[1] / 2 - wsize[1] / 2)
        end if
        if wpos[2] = -1 then
            wpos[2] = floor(displaysize[2] / 2 - wsize[2] / 2)
        end if
        if match("_winDebug", wname) then
            bcolor = rgb(255, 255, 200)
        else
            bcolor = th:cOuterFill
        end  if
        winhandle = oswin:create_window(wid, wtitle, "normal", wpos[1], wpos[2], wsize[1], wsize[2], bcolor)
        oswin:enable_close(winhandle, wallowclose)
        if wtopmost = 1 then
            oswin:set_window_topmost(winhandle)
        end if
        if wmodal = 1 then
            oswin:set_window_modal(winhandle)
        end if
        widget:widget_set_handle(wid, winhandle)
        
        if equal("_winDebug", wname) then
            set_window_modal_override(winhandle, 1)
        end if
        
        wcprops[wcpID] &= wid
        wcprops[wcpTitle] &= {wtitle}
        wcprops[wcpFormRect] &= {{0, 0, wsize[1], wsize[2]}}
        wcprops[wcpSoftFocus] &= 0
        wcprops[wcpHardFocus] &= 0
        wcprops[wcpMode] &= wmode
        wcprops[wcpMenubarID] &= 0
        wcprops[wcpInfobarID] &= 0
        wcprops[wcpFormID] &= 0
        
        wcprops[wcpToolbars] &= {{{}, {}, {}, {}}}  --{top, right, bottom, left}
        wcprops[wcpToolbarRects] &= {{{}, {}, {}, {}}}  --{top, right, bottom, left}
        wcprops[wcpToolDockSizes] &= {{0, 0, 0, 0}}  --{top, right, bottom, left}
        
        wcprops[wcpPanels] &= {{}}
        wcprops[wcpDockSizes] &= {{0, 0, 0, 0}}  --{top, right, bottom, left}
        wcprops[wcpDockDividers] &= {{0, 0, 0, 0}}  --{top, right, bottom, left}
        wcprops[wcpPanelSizes] &= {{{}, {}, {}, {}}}  --{top, right, bottom, left}
        wcprops[wcpPanelDividers] &= {{{}, {}, {}, {}}}  --{top, right, bottom, left}
        wcprops[wcpTabs] &= {{}}
        
        wc_call_event(wid, "Show", wid) --todo: only show if Visible = 1
          
    elsif wmode = 1 then  --"dialog"
        wpos = widget:widget_get_pos(wid)
        wsize = {60, 40}
        --widget:widget_set_size(wid, wsize[1], wsize[2])
        widget:widget_set_min_size(wid, wsize[1], wsize[2])
        
        displaysize = oswin:getPrimaryDisplaySize()
        if wpos[1] = -1 then
            wpos[1] = floor(displaysize[1] / 2 - wsize[1] / 2)
        end if
        if wpos[2] = -1 then
            wpos[2] = floor(displaysize[2] / 2 - wsize[2] / 2)
        end if
        winhandle = oswin:create_window(wid, wtitle, "noresize", wpos[1], wpos[2], wsize[1], wsize[2], th:cOuterFill)
        oswin:enable_close(winhandle, wallowclose)
        if wtopmost = 1 then
            oswin:set_window_topmost(winhandle)
        end if
        if wmodal = 1 then
            oswin:set_window_modal(winhandle)
        end if
        widget:widget_set_handle(wid, winhandle)
        wname = widget:widget_get_name(wid)
        if equal("_winDebug", wname) then
            set_window_modal_override(winhandle, 1)
        end if
        
        wcprops[wcpID] &= wid
        wcprops[wcpTitle] &= {wtitle}
        wcprops[wcpFormRect] &= {{0, 0, wsize[1], wsize[2]}}
        wcprops[wcpSoftFocus] &= 0
        wcprops[wcpHardFocus] &= 0
        wcprops[wcpMode] &= wmode
        wcprops[wcpMenubarID] &= 0
        wcprops[wcpInfobarID] &= 0
        wcprops[wcpFormID] &= 0
        
        wcprops[wcpToolbars] &= {{{}, {}, {}, {}}}  --{top, right, bottom, left}
        wcprops[wcpToolbarRects] &= {{{}, {}, {}, {}}}  --{top, right, bottom, left}
        wcprops[wcpToolDockSizes] &= {{0, 0, 0, 0}}  --{top, right, bottom, left}
        
        wcprops[wcpPanels] &= {{}}
        wcprops[wcpDockSizes] &= {{0, 0, 0, 0}}  --{top, right, bottom, left}
        wcprops[wcpDockDividers] &= {{0, 0, 0, 0}}  --{top, right, bottom, left}
        wcprops[wcpPanelSizes] &= {{{}, {}, {}, {}}}  --{top, right, bottom, left}
        wcprops[wcpPanelDividers] &= {{{}, {}, {}, {}}}  --{top, right, bottom, left}
        wcprops[wcpTabs] &= {{}}
        
        wc_call_event(wid, "Show", wid)
        
    elsif wmode = 2 then  --"screen"
        for p = 1 to length(wprops) do
            if length(wprops[p]) = 2 then
                switch wprops[p][1] do          
                    case "title" then
                        wtitle = wprops[p][2]
                    case "topmost" then
                        wtopmost = 1 
                    break
                    
                end switch
            end if
        end for
        
        --wtitle = "<wid=" & sprint(wid) & "> " & wtitle--DEBUGGING
        
        wpos = widget:widget_get_pos(wid)
        wsize = {60, 40}
        --widget:widget_set_size(wid, wsize[1], wsize[2])
        widget:widget_set_min_size(wid, wsize[1], wsize[2])
        
        displaysize = oswin:getPrimaryDisplaySize()
        if wpos[1] = -1 then
            wpos[1] = floor(displaysize[1] / 2 - wsize[1] / 2)
        end if
        if wpos[2] = -1 then
            wpos[2] = floor(displaysize[2] / 2 - wsize[2] / 2)
        end if
        winhandle = oswin:create_window(wid, wtitle, "noborder", wpos[1], wpos[2], wsize[1], wsize[2], th:cOuterFill)
        oswin:enable_close(winhandle, wallowclose)
        if wtopmost = 1 then
            oswin:set_window_topmost(winhandle)
        end if
        widget:widget_set_handle(wid, winhandle)
        
        wcprops[wcpID] &= wid
        wcprops[wcpTitle] &= {wtitle}
        wcprops[wcpFormRect] &= {{0, 0, wsize[1], wsize[2]}}
        wcprops[wcpSoftFocus] &= 0
        wcprops[wcpHardFocus] &= 0
        wcprops[wcpMode] &= wmode
        wcprops[wcpMenubarID] &= 0
        wcprops[wcpInfobarID] &= 0
        wcprops[wcpFormID] &= 0
        
        wcprops[wcpToolbars] &= {{{}, {}, {}, {}}}  --{top, right, bottom, left}
        wcprops[wcpToolbarRects] &= {{{}, {}, {}, {}}}  --{top, right, bottom, left}
        wcprops[wcpToolDockSizes] &= {{0, 0, 0, 0}}  --{top, right, bottom, left}
        
        wcprops[wcpPanels] &= {{}}
        wcprops[wcpDockSizes] &= {{0, 0, 0, 0}}  --{top, right, bottom, left}
        wcprops[wcpDockDividers] &= {{0, 0, 0, 0}}  --{top, right, bottom, left}
        wcprops[wcpPanelSizes] &= {{{}, {}, {}, {}}}  --{top, right, bottom, left}
        wcprops[wcpPanelDividers] &= {{{}, {}, {}, {}}}  --{top, right, bottom, left}
        wcprops[wcpTabs] &= {{}}
        
        wc_call_event(wid, "Show", wid)
        
    elsif wmode = 3 then  --"toolbox"
        
    end if
end procedure


procedure wc_destroy(atom wid)
    atom idx, wh
    sequence wname
    
    idx = find(wid, wcprops[wcpID])
    
    wname = widget_get_name(wid)
                
    if idx > 0 then
        for p = 1 to wcpLENGTH do
            wcprops[p] = remove(wcprops[p], idx)
        end for
    end if
    wh = widget_get_handle(wid)
    oswin:enable_close(wh, 1)
    oswin:destroy_window(wh)
end procedure


procedure wc_draw(atom wid)
    sequence cmds, wsize, chwid
    atom idx, fcolor
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wsize = widget_get_size(wid)
        --if wcprops[wcpHardFocus][idx] then
        --    fcolor = th:cOuterActive
        --else
            fcolor = th:cOuterFill
        --end if
        
        if match("_winDebug", widget_get_name(wid)) then
            fcolor = rgb(255, 255, 200)
        end  if
        cmds = {
            {DR_PenColor, fcolor},
            {DR_Rectangle, True, 0, 0, wsize[1], wsize[2]}
            --{DR_PenColor, rgb(255, 64, 64)},
            --{DR_Rectangle, False, 0, 0, wsize[1], wsize[2]}
        }
        
        draw(widget:widget_get_handle(wid), cmds)
        
        chwid = children_of(wid)
        for ch = 1 to length(chwid) do
            wc_call_draw(chwid[ch])
        end for
    end if
end procedure


procedure wc_event(atom wid, sequence evtype, object evdata)
    sequence cmds, wsize, wclass
    atom idx
    sequence wname
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        switch evtype do
            case "Show" then
                oswin:show_window(widget_get_handle(wid))
                widget_enable_draw(wid)
                wc_call_resize(wid)
                
            case "Hide" then
                oswin:hide_window(widget_get_handle(wid))
                widget_disable_draw(wid)
                
            case "Resize" then
                if wcprops[wcpMode][idx] = 0 then  --"window"
                    widget_set_default_size(wid, evdata[1], evdata[2])
                    wc_call_resize(wid)
                    --task_yield()
                    wname = widget_get_name(wid)
                    widget:wc_send_event(wname, "resized", {evdata[1], evdata[2]})
                    
                elsif wcprops[wcpMode][idx] = 1 then  --"dialog"
                    
                elsif wcprops[wcpMode][idx] = 2 then  --"screen"
                    
                elsif wcprops[wcpMode][idx] = 3 then  --"toolbox"
                    
                end if
                
            case "MouseMove" then
                if in_rect(evdata[1], evdata[2], wcprops[wcpFormRect][idx]) then
                    if wcprops[wcpSoftFocus][idx] = 0 then
                        wcprops[wcpSoftFocus][idx] = 1
                        --wc_call_draw(wid)
                        set_mouse_pointer(widget_get_handle(wid), mArrow)
                    end if
                else
                    if wcprops[wcpSoftFocus][idx] = 1 then
                        wcprops[wcpSoftFocus][idx] = 0
                        --wc_call_draw(wid)
                    end if
                end if
                
            case "child created" then
                wclass = widget_get_class(evdata[1])
                if equal(wclass, "menubar") then
                    wcprops[wcpMenubarID][idx] = evdata[1]
                    
                elsif equal(wclass, "container") then
                    wcprops[wcpFormID][idx] = evdata[1]
                    
                elsif equal(wclass, "panel") or equal(wclass, "tabs") then
                    sequence pdata = {evdata[1], 2, 0, 0, 0} --{pnlId, pnlDock, pnlDockIdx, pnlTabIdx, pnlSize}
                    wname = widget_get_name(wid)
                    
                    for p = 1 to length(evdata[2]) do
                        if length(evdata[2][p]) = 2 then
                            switch evdata[2][p][1] do
                                case "dock" then
                                    if equal(evdata[2][p][2], "top") then
                                        pdata[pnlDock] = 1
                                        wcprops[wcpPanelDividers][idx][1] &= widget:widget_create(
                                            wname & ".divPanelTop." & sprint(evdata[1]), wid, "divider", {
                                            {"orientation", 1},
                                            {"min", 0}
                                        })
                                    elsif equal(evdata[2][p][2], "right") then
                                        pdata[pnlDock] = 2
                                        wcprops[wcpPanelDividers][idx][2] &= widget:widget_create(
                                            wname & ".divPanelTop." & sprint(evdata[1]), wid, "divider", {
                                            {"orientation", 0},
                                            {"min", 0}
                                        })
                                    elsif equal(evdata[2][p][2], "bottom") then
                                        pdata[pnlDock] = 3
                                        wcprops[wcpPanelDividers][idx][3] &= widget:widget_create(
                                            wname & ".divPanelTop." & sprint(evdata[1]), wid, "divider", {
                                            {"orientation", 1},
                                            {"min", 0}
                                        })
                                    elsif equal(evdata[2][p][2], "left") then
                                        pdata[pnlDock] = 4
                                        wcprops[wcpPanelDividers][idx][4] &= widget:widget_create(
                                            wname & ".divPanelTop." & sprint(evdata[1]), wid, "divider", {
                                            {"orientation", 0},
                                            {"min", 0}
                                        })
                                    end if
                            end switch
                        end if
                    end for
                    wcprops[wcpPanels][idx] &= {pdata}
                    
                    if wcprops[wcpDockSizes][idx][pdata[pnlDock]] = 0 then
                        wcprops[wcpDockSizes][idx][pdata[pnlDock]] = DefaultPanelSize
                    end if
                    
                    /*if sequence(wcprops[wcpPanelDividers][idx]) then
                        for pd = 1 to length(wcprops[wcpPanelDividers][idx]) do
                            widget:widget_destroy(wcprops[wcpPanelDividers][idx][pd])
                        end for
                        wcprops[wcpPanelDividers][idx] = 0
                    end if*/
                    
                elsif equal(wclass, "toolbar") then
                    for p = 1 to length(evdata[2]) do
                        if length(evdata[2][p]) = 2 then
                            switch evdata[2][p][1] do
                                case "dock" then
                                    if equal(evdata[2][p][2], "top") then
                                        wcprops[wcpToolbars][idx][1] &= evdata[1]
                                        wcprops[wcpToolbarRects][idx][1] &= {{0, 0, 0, 0}}
                                        
                                    elsif equal(evdata[2][p][2], "right") then
                                        wcprops[wcpToolbars][idx][2] &= evdata[1]
                                        wcprops[wcpToolbarRects][idx][2] &= {{0, 0, 0, 0}}
                                        
                                    elsif equal(evdata[2][p][2], "bottom") then
                                        wcprops[wcpToolbars][idx][3] &= evdata[1]
                                        wcprops[wcpToolbarRects][idx][3] &= {{0, 0, 0, 0}}
                                        
                                    elsif equal(evdata[2][p][2], "left") then
                                        wcprops[wcpToolbars][idx][4] &= evdata[1]
                                        wcprops[wcpToolbarRects][idx][4] &= {{0, 0, 0, 0}}
                                        
                                    end if
                            end switch
                        end if
                    end for
                    
                elsif equal(wclass, "infobar") then
                    wcprops[wcpInfobarID][idx] = evdata[1]
                    
                end if
                
            case "divider moved" then --{wid, mpos}
                --? {evdata, {wcprops[wcpDockDividers][idx], wcprops[wcpDockSizes][idx]}}
                sequence prect
                wsize = widget_get_size(wid)
            
                atom mspace = 0, ispace = 0
                
                if wcprops[wcpMenubarID][idx] > 0 then
                    mspace = 20
                end if
                if wcprops[wcpInfobarID][idx] > 0 then
                    ispace = 20
                end if
                --todo: add space for toolbars
                
                --dock dividers
                if evdata[1] = wcprops[wcpDockDividers][idx][1] then --top dock
                    wcprops[wcpDockSizes][idx][1] = evdata[2] - mspace + 4 + PanelSizerWidth
                    
                elsif evdata[1] = wcprops[wcpDockDividers][idx][2] then --right dock
                    wcprops[wcpDockSizes][idx][2] = wsize[1] - evdata[2] - 2
                    
                elsif evdata[1] = wcprops[wcpDockDividers][idx][3] then --bottom dock
                    wcprops[wcpDockSizes][idx][3] = wsize[2] - evdata[2] - ispace - PanelSizerWidth
                    
                elsif evdata[1] = wcprops[wcpDockDividers][idx][4] then --left dock
                    wcprops[wcpDockSizes][idx][4] = evdata[2] + 4 + PanelSizerWidth
                    
                --panel dividers
                else
                    --wcprops[wcpPanelSizes][idx]
                    --wcprops[wcpPanelDividers][idx]
                end if
                wc_call_arrange(wid)
                
            case "GotFocus" then
                wcprops[wcpHardFocus][idx] = 1
                widget:wc_call_draw(wid)
                
            case "LostFocus" then
                wcprops[wcpHardFocus][idx] = 0
                widget:wc_call_draw(wid)
                
            case "Close" then
                wname = widget_get_name(wid)
                widget:wc_send_event(wname, "closed", {})
                if get_enable_close(widget_get_handle(wid)) then
                    widget:widget_destroy(wid)
                    return
                end if
            case else
                --statusUpdateMsg(0, "gui: window event:" & evtype & sprint(evdata), 0)
        end switch
        --statusUpdateMsg(0, "gui: window event:" & evtype & sprint(evdata), 0)
    end if
end procedure


procedure wc_resize(atom wid) --resizing affects parent and ancestors
    sequence wsize, wmsize, wnsize
    atom idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        if wcprops[wcpMode][idx] = 0 then  --"window"
            --wsize = widget:widget_get_default_size(wid)
            --widget:widget_set_min_size(wid, wsize[1], wsize[2])
            --widget:widget_set_natural_size(wid, wsize[1], wsize[2])
            wc_call_arrange(wid)
            
        elsif wcprops[wcpMode][idx] = 1 then  --"dialog"
            wmsize = widget_get_min_size(wcprops[wcpFormID][idx])
            wnsize = widget_get_natural_size(wcprops[wcpFormID][idx])
            
            widget:widget_set_min_size(wid, wmsize[1], wmsize[2])
            widget:widget_set_natural_size(wid, wnsize[1], wnsize[2])
            
            wc_call_arrange(wid)
            
        elsif wcprops[wcpMode][idx] = 2 then  --"screen"
            wmsize = widget_get_min_size(wcprops[wcpFormID][idx])
            wnsize = widget_get_natural_size(wcprops[wcpFormID][idx])
            
            widget:widget_set_min_size(wid, wmsize[1], wmsize[2])
            widget:widget_set_natural_size(wid, wnsize[1], wnsize[2])
            
            wc_call_arrange(wid)
        elsif wcprops[wcpMode][idx] = 3 then  --"toolbox"
            
        end if
        
    end if
end procedure


procedure wc_arrange(atom wid) --arranging affects children and offspring
    atom wh, mspace = 0, ispace = 0
    sequence wname, wmsize, wnsize, wdsize, wsize, pwsize, wpos, displaysize
    
    atom idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        if wcprops[wcpMode][idx] = 0 then  --"window"
            wname = widget_get_name(wid)
            
            wmsize = widget_get_min_size(wid)
            wnsize = widget_get_natural_size(wid)
            wdsize = widget_get_default_size(wid)
            
            --Because this is a root widget, it must set it's own Actual size.
            wsize = {max({60, wmsize[1], wnsize[1], wdsize[1]}), max({1, wmsize[2], wnsize[2], wdsize[2]})}
            
            widget_set_size(wid, wsize[1], wsize[2])
            --oswin:set_window_size(widget_get_handle(wid), wsize[1], wsize[2])
            
            --Now, set the children's sizes.
            if wcprops[wcpMenubarID][idx] > 0 then
                mspace = 20
                widget_set_pos(wcprops[wcpMenubarID][idx], 0, 0)
                widget_set_size(wcprops[wcpMenubarID][idx], wsize[1], mspace)
                wc_call_arrange(wcprops[wcpMenubarID][idx])
            else
                mspace = 0
            end if
            
            if wcprops[wcpInfobarID][idx] > 0 then
                ispace = 20
                widget_set_pos(wcprops[wcpInfobarID][idx], 0, wsize[2] - 2 - ispace)
                widget_set_size(wcprops[wcpInfobarID][idx], wsize[1], ispace)
                wc_call_arrange(wcprops[wcpInfobarID][idx])
            else
                ispace = 0
            end if
            
            --Arrange Toolbars:
            --wcpToolbars,        --list of toolbar docked widgets {top, right, bottom, left}
            --wcpToolbarRects,    --list of rectangles representing toolbar positions and sizes {top, right, bottom, left}
            --wcpToolDockSizes,   --sizes of {top, right, bottom, left} toolbar dock areas
            sequence tbrect, tbmsize, tbnsize
            
            --top toolbar dock
            if length(wcprops[wcpToolbars][idx][1]) > 0 then
                for tb = 1 to length(wcprops[wcpToolbars][idx][1]) do
                    --tbrect = {2, mspace + 4, 300, 50} --wsize[1] - 2, wsize[2] - 2 - ispace}
                    
                    --tbmsize = widget_get_min_size(wcprops[wcpToolbars][idx][1][tb])
                    tbnsize = widget_get_natural_size(wcprops[wcpToolbars][idx][1][tb])
                    tbrect = {2, mspace + 4, 2 + tbnsize[1], mspace + 4 + tbnsize[2]}
                    
                    wcprops[wcpToolbarRects][idx][1][tb] = tbrect
                    widget_set_pos(wcprops[wcpToolbars][idx][1][tb], tbrect[1], tbrect[2])
                    widget_set_size(wcprops[wcpToolbars][idx][1][tb], tbrect[3] - tbrect[1], tbrect[4] - tbrect[2])
                    wc_call_arrange(wcprops[wcpToolbars][idx][1][tb])
                end for
                wcprops[wcpToolDockSizes][idx][1] = tbrect[4] - tbrect[2] + 4
                
            end if
            
            --right toolbar dock
            
            --bottom toolbar dock
            
            --left toolbar dock
            
            
            
            
            --Arrange Panels:
            if length(wcprops[wcpPanels][idx]) > 0 then
                sequence psize, prect, ptop = {}, pright = {}, pbottom = {}, pleft = {},
                pspace = {
                    wcprops[wcpToolDockSizes][idx][1] + mspace + 2, --top
                    wcprops[wcpToolDockSizes][idx][2] + 2,          --right
                    wcprops[wcpToolDockSizes][idx][3] + ispace + 2, --bottom
                    wcprops[wcpToolDockSizes][idx][4] + 2           --left
                }
                
                --sort panels by dock location
                for pidx = 1 to length(wcprops[wcpPanels][idx]) do
                    if wcprops[wcpPanels][idx][pidx][pnlDock] = 1 then    --top
                        ptop &= pidx
                    elsif wcprops[wcpPanels][idx][pidx][pnlDock] = 2 then --right
                        pright &= pidx
                    elsif wcprops[wcpPanels][idx][pidx][pnlDock] = 3 then --bottom
                        pbottom &= pidx
                    elsif wcprops[wcpPanels][idx][pidx][pnlDock] = 4 then --left
                        pleft &= pidx
                    end if
                end for
                
                --top dock
                if length(ptop) > 0 then
                    --psize = {((wsize[1] - 2) - (2) - (length(ptop) * PanelSizerWidth)) / length(ptop), wcprops[wcpDockSizes][idx][1] - PanelSizerWidth}
                    psize = {((wsize[1] - pspace[2] - pspace[4]) - (2) - (length(ptop) * PanelSizerWidth)) / length(ptop), wcprops[wcpDockSizes][idx][1] - PanelSizerWidth}
                    --create panel divider if necessary
                    if wcprops[wcpDockDividers][idx][1] = 0 then
                        wcprops[wcpDockDividers][idx][1] = widget:widget_create(
                            wname & ".divTop", wid, "divider", {
                            --{"attach", wname},
                            {"orientation", 0},
                            {"min", 0},
                            {"adjust", wcprops[wcpDockSizes][idx][1]}
                        })
                    end if
                    --arrange panel divider
                    /*prect = {
                        2, mspace + 4 + wcprops[wcpDockSizes][idx][1] - PanelSizerWidth,
                        wsize[1] - 2, mspace + 4 + wcprops[wcpDockSizes][idx][1]
                    }*/
                    prect = {
                        pspace[4], pspace[1] + wcprops[wcpDockSizes][idx][1] - PanelSizerWidth,
                        wsize[1] - pspace[2] - pspace[4], pspace[1] + wcprops[wcpDockSizes][idx][1]
                    }
                    widget_set_pos(wcprops[wcpDockDividers][idx][1], prect[1], prect[2])
                    widget_set_size(wcprops[wcpDockDividers][idx][1], prect[3] - prect[1], prect[4] - prect[2])
                    wc_call_arrange(wcprops[wcpDockDividers][idx][1])
                    --arrange panels
                    for pb = 1 to length(ptop) do
                        /*prect = {
                            floor(2 + (pb - 1) * psize[1] + (pb - 1) * PanelSizerWidth), mspace + 4,
                            floor(2 + (pb) * psize[1] + (pb - 1) * PanelSizerWidth), mspace + 4 + psize[2]
                        }*/
                        prect = {
                            floor(pspace[4] + (pb - 1) * psize[1] + (pb - 1) * PanelSizerWidth), pspace[1],
                            floor(pspace[4] + (pb) * psize[1] + (pb - 1) * PanelSizerWidth), pspace[1] + psize[2]
                        }
                        
                        widget_set_pos(wcprops[wcpPanels][idx][ptop[pb]][pnlId], prect[1], prect[2])
                        widget_set_size(wcprops[wcpPanels][idx][ptop[pb]][pnlId], prect[3] - prect[1], prect[4] - prect[2])
                        wc_call_arrange(wcprops[wcpPanels][idx][ptop[pb]][pnlId])
                        
                        --divider after panel
                        widget_set_pos(wcprops[wcpPanelDividers][idx][1][pb], prect[3], prect[2])
                        widget_set_size(wcprops[wcpPanelDividers][idx][1][pb], PanelSizerWidth, prect[4] - prect[2])
                        wc_call_arrange(wcprops[wcpPanelDividers][idx][1][pb])
                    end for
                end if
                
                --right dock
                if length(pright) > 0 then
                    --psize = {wcprops[wcpDockSizes][idx][2] - PanelSizerWidth, ((wsize[2] - 2 - ispace) - (mspace + 4) - wcprops[wcpDockSizes][idx][1] - wcprops[wcpDockSizes][idx][3] - (length(pright) * PanelSizerWidth)) / length(pright)}
                    psize = {wcprops[wcpDockSizes][idx][2] - PanelSizerWidth, ((wsize[2] - 2 - ispace) - (mspace + 4) - wcprops[wcpDockSizes][idx][1] - wcprops[wcpDockSizes][idx][3] - (length(pright) * PanelSizerWidth)) / length(pright)}
                    --create panel divider if necessary
                    if wcprops[wcpDockDividers][idx][2] = 0 then
                        wcprops[wcpDockDividers][idx][2] = widget:widget_create(
                            wname & ".divRight", wid, "divider", {
                            --{"attach", wname},
                            {"orientation", 1},
                            {"min", 0},
                            {"adjust", wcprops[wcpDockSizes][idx][2]}
                        })
                    end if
                    --arrange panel divider
                    prect = {
                        wsize[1] - 2 - psize[1], pspace[1] + wcprops[wcpDockSizes][idx][1] - PanelSizerWidth,
                        wsize[1] - 2 - psize[1] + PanelSizerWidth, wsize[2] - 2 - ispace - wcprops[wcpDockSizes][idx][3]
                    }
                    widget_set_pos(wcprops[wcpDockDividers][idx][2], prect[1], prect[2])
                    widget_set_size(wcprops[wcpDockDividers][idx][2], prect[3] - prect[1], prect[4] - prect[2])
                    wc_call_arrange(wcprops[wcpDockDividers][idx][2])
                    --arrange panels
                    for pb = 1 to length(pright) do
                        prect = {wsize[1] - 2 - psize[1] + PanelSizerWidth, floor(mspace + 4 + wcprops[wcpDockSizes][idx][1] + (pb - 1) * psize[2] + (pb - 1) * PanelSizerWidth), wsize[1] - 2, floor(mspace + 4 + wcprops[wcpDockSizes][idx][1] + pb * psize[2] + (pb - 1) * PanelSizerWidth)}
                        widget_set_pos(wcprops[wcpPanels][idx][pright[pb]][pnlId], prect[1], prect[2])
                        widget_set_size(wcprops[wcpPanels][idx][pright[pb]][pnlId], prect[3] - prect[1], prect[4] - prect[2])
                        wc_call_arrange(wcprops[wcpPanels][idx][pright[pb]][pnlId])
                        
                        --divider after panel
                        widget_set_pos(wcprops[wcpPanelDividers][idx][2][pb], prect[1], prect[4])
                        widget_set_size(wcprops[wcpPanelDividers][idx][2][pb], prect[3] - prect[1], PanelSizerWidth)
                        wc_call_arrange(wcprops[wcpPanelDividers][idx][2][pb])
                    end for
                end if
                
                --bottom dock
                if length(pbottom) > 0 then
                    --psize = {((wsize[1] - 2) - (2) - (length(pbottom) * PanelSizerWidth)) / length(pbottom), wcprops[wcpDockSizes][idx][3] - PanelSizerWidth}
                    psize = {((wsize[1] - pspace[2] - pspace[4]) - (2) - (length(pbottom) * PanelSizerWidth)) / length(pbottom), wcprops[wcpDockSizes][idx][3] - PanelSizerWidth}
                    
                    --create panel divider if necessary
                    if wcprops[wcpDockDividers][idx][3] = 0 then
                        wcprops[wcpDockDividers][idx][3] = widget:widget_create(
                            wname & ".divBottom", wid, "divider", {
                            --{"attach", wname},
                            {"orientation", 0},
                            {"min", 0},
                            {"adjust", wcprops[wcpDockSizes][idx][3]}
                        })
                    end if
                    --arrange panel divider
                    prect = {
                        2, wsize[2] - 2 - ispace - wcprops[wcpDockSizes][idx][3],
                        wsize[1] - 2, wsize[2] - 2 - ispace - wcprops[wcpDockSizes][idx][3] + PanelSizerWidth
                    }
                    widget_set_pos(wcprops[wcpDockDividers][idx][3], prect[1], prect[2])
                    widget_set_size(wcprops[wcpDockDividers][idx][3], prect[3] - prect[1], prect[4] - prect[2])
                    wc_call_arrange(wcprops[wcpDockDividers][idx][3])
                    --arrange panels
                    for pb = 1 to length(pbottom) do
                        prect = {floor(2 + (pb - 1) * psize[1] + (pb - 1) * PanelSizerWidth), wsize[2] - 2 - ispace - psize[2], floor(2 + (pb) * psize[1] + (pb - 1) * PanelSizerWidth), wsize[2] - 2 - ispace}
                        widget_set_pos(wcprops[wcpPanels][idx][pbottom[pb]][pnlId], prect[1], prect[2])
                        widget_set_size(wcprops[wcpPanels][idx][pbottom[pb]][pnlId], prect[3] - prect[1], prect[4] - prect[2])
                        wc_call_arrange(wcprops[wcpPanels][idx][pbottom[pb]][pnlId])
                        
                        --divider after panel
                        widget_set_pos(wcprops[wcpPanelDividers][idx][3][pb], prect[3], prect[2])
                        widget_set_size(wcprops[wcpPanelDividers][idx][3][pb], PanelSizerWidth, prect[4] - prect[2])
                        wc_call_arrange(wcprops[wcpPanelDividers][idx][3][pb])
                    end for
                    --arrange dividers
                    /*for pb = 1 to length(pbottom) do
                        prect = {floor(2 + (pb - 1) * psize[1] + pb * PanelSizerWidth), wsize[2] - 2 - ispace - psize[2], floor(2 + (pb) * psize[1] + pb * PanelSizerWidth), wsize[2] - 2 - ispace}
                        widget_set_pos(wcprops[wcpPanels][idx][pbottom[pb]][pnlId], prect[1], prect[2])
                        widget_set_size(wcprops[wcpPanels][idx][pbottom[pb]][pnlId], prect[3] - prect[1], prect[4] - prect[2])
                        wc_call_arrange(wcprops[wcpPanels][idx][pbottom[pb]][pnlId])
                    end for*/
                end if
                
                --left dock
                if length(pleft) > 0 then
                    psize = {wcprops[wcpDockSizes][idx][4] - PanelSizerWidth, ((wsize[2] - 2 - ispace) - (mspace + 4) - wcprops[wcpDockSizes][idx][1] - wcprops[wcpDockSizes][idx][3] - (length(pleft) * PanelSizerWidth)) / length(pleft)}
                    --create panel divider if necessary
                    if wcprops[wcpDockDividers][idx][4] = 0 then
                        wcprops[wcpDockDividers][idx][4] = widget:widget_create(
                            wname & ".divLeft", wid, "divider", {
                            --{"attach", wname},
                            {"orientation", 1},
                            {"min", 0},
                            {"adjust", wcprops[wcpDockSizes][idx][4]}
                        })
                    end if
                    --arrange panel divider
                    prect = {
                        2 + wcprops[wcpDockSizes][idx][4] - PanelSizerWidth, mspace + 4 + wcprops[wcpDockSizes][idx][1],
                        2 + wcprops[wcpDockSizes][idx][4], wsize[2] - 2 - ispace - wcprops[wcpDockSizes][idx][3]
                    }
                    widget_set_pos(wcprops[wcpDockDividers][idx][4], prect[1], prect[2])
                    widget_set_size(wcprops[wcpDockDividers][idx][4], prect[3] - prect[1], prect[4] - prect[2])
                    wc_call_arrange(wcprops[wcpDockDividers][idx][4])
                    --arrange panels
                    for pb = 1 to length(pleft) do
                        prect = {2, floor(mspace + 4 + wcprops[wcpDockSizes][idx][1] + (pb - 1) * psize[2] + (pb - 1) * PanelSizerWidth), psize[1], floor(mspace + 4 + wcprops[wcpDockSizes][idx][1] + pb * psize[2] + (pb - 1) * PanelSizerWidth)}
                        widget_set_pos(wcprops[wcpPanels][idx][pleft[pb]][pnlId], prect[1], prect[2])
                        widget_set_size(wcprops[wcpPanels][idx][pleft[pb]][pnlId], prect[3] - prect[1], prect[4] - prect[2])
                        wc_call_arrange(wcprops[wcpPanels][idx][pleft[pb]][pnlId])
                        
                        --divider after panel
                        widget_set_pos(wcprops[wcpPanelDividers][idx][4][pb], prect[1], prect[4])
                        widget_set_size(wcprops[wcpPanelDividers][idx][4][pb], prect[3] - prect[1], PanelSizerWidth)
                        wc_call_arrange(wcprops[wcpPanelDividers][idx][4][pb])
                    end for
                end if
            end if
            
            --Form (main area)
            if wcprops[wcpFormID][idx] > 0 then
                --wcprops[wcpFormRect][idx] = {2, mspace + 4, wsize[1] - 2, wsize[2] - 2 - ispace}
                wcprops[wcpFormRect][idx] = {
                    wcprops[wcpToolDockSizes][idx][4] + 2 + wcprops[wcpDockSizes][idx][4],
                    wcprops[wcpToolDockSizes][idx][1] + mspace + 2 + wcprops[wcpDockSizes][idx][1],
                    wsize[1] - wcprops[wcpToolDockSizes][idx][2] - 2 - wcprops[wcpDockSizes][idx][2],
                    wsize[2] - wcprops[wcpToolDockSizes][idx][3] - ispace - 2 - wcprops[wcpDockSizes][idx][3]
                }
                
                widget_set_pos(wcprops[wcpFormID][idx], wcprops[wcpFormRect][idx][1], wcprops[wcpFormRect][idx][2])
                widget_set_size(wcprops[wcpFormID][idx], wcprops[wcpFormRect][idx][3] - wcprops[wcpFormRect][idx][1], wcprops[wcpFormRect][idx][4] - wcprops[wcpFormRect][idx][2])
                wc_call_arrange(wcprops[wcpFormID][idx])
            end if
            
            wc_call_draw(wid)
            
        elsif wcprops[wcpMode][idx] = 1 then  --"dialog"
            wmsize = widget_get_min_size(wid)
            wnsize = widget_get_natural_size(wid)
            wdsize = widget_get_default_size(wid)
            
            --Because this is a root widget, it must set it's own Actual size.
            wsize = {max({60, wmsize[1], wnsize[1], wdsize[1]}) + 4, max({1, wmsize[2], wnsize[2], wdsize[2]}) + 4}
            displaysize = oswin:getPrimaryDisplaySize()
            wh = widget_get_handle(wid)
            wpos = oswin:get_window_pos(wh)
            pwsize = widget_get_size(wid) --oswin:get_window_size(wh)
            wpos[1] += floor((pwsize[1] - wsize[1]) / 2)
            wpos[2] += floor((pwsize[2] - wsize[2]) / 2)
            
            if wpos[1] < 50 then
                wpos[1] = 50
            end if
            if wpos[1] > displaysize[1] - wsize[1] - 50 then
                wpos[1] = displaysize[1] - wsize[1] - 50
            end if
            if wpos[2] < 50 then
                wpos[2] = 50
            end if
            if wpos[2] > displaysize[2] - wsize[2] - 50 then
                wpos[2] = displaysize[2] - wsize[2] - 50
            end if
            widget_set_size(wid, wsize[1], wsize[2])
            oswin:set_window_pos(wh, wpos[1], wpos[2])
            oswin:set_window_size(wh, wsize[1], wsize[2])
            
            --Now, set the children's sizes.
            if wcprops[wcpFormID][idx] > 0 then
                wcprops[wcpFormRect][idx] = {2, 2, wsize[1] - 2, wsize[2] - 2}
                widget_set_pos(wcprops[wcpFormID][idx], wcprops[wcpFormRect][idx][1], wcprops[wcpFormRect][idx][2])
                widget_set_size(wcprops[wcpFormID][idx], wcprops[wcpFormRect][idx][3] - wcprops[wcpFormRect][idx][1],
                    wcprops[wcpFormRect][idx][4] - wcprops[wcpFormRect][idx][2])
                wc_call_arrange(wcprops[wcpFormID][idx])
            end if
            
            wc_call_draw(wid)
            
        elsif wcprops[wcpMode][idx] = 2 then  --"screen"
             wmsize = widget_get_min_size(wid)
            wnsize = widget_get_natural_size(wid)
            wdsize = widget_get_default_size(wid)
            
            --Because this is a root widget, it must set it's own Actual size.
            wsize = {max({60, wmsize[1], wnsize[1], wdsize[1]}) + 4, max({1, wmsize[2], wnsize[2], wdsize[2]}) + 2}
            displaysize = oswin:getPrimaryDisplaySize()
            wh = widget_get_handle(wid)
            wpos = oswin:get_window_pos(wh)
            pwsize = widget_get_size(wid) --oswin:get_window_size(wh)
            wpos[1] += floor((pwsize[1] - wsize[1]) / 2)
            wpos[2] += floor((pwsize[2] - wsize[2]) / 2)
            --? {pwsize, wsize, {floor((pwsize[1] - wsize[1]) / 2), floor((pwsize[2] - wsize[2]) / 2)}, wpos}
            
            if wpos[1] < 0 then
                wpos[1] = 0
            end if
            if wpos[1] > displaysize[1] - wsize[1] then
                wpos[1] = displaysize[1] - wsize[1]
            end if
            if wpos[2] < 0 then
                wpos[2] = 0
            end if
            if wpos[2] > displaysize[2] - wsize[2] then
                wpos[2] = displaysize[2] - wsize[2]
            end if
            widget_set_size(wid, wsize[1], wsize[2])
            oswin:set_window_pos(wh, wpos[1], wpos[2])
            oswin:set_window_size(wh, wsize[1], wsize[2])
            
            --Now, set the children's sizes.
            if wcprops[wcpFormID][idx] > 0 then
                wcprops[wcpFormRect][idx] = {2, 2, wsize[1] - 2, wsize[2] - 2}
                widget_set_pos(wcprops[wcpFormID][idx], wcprops[wcpFormRect][idx][1], wcprops[wcpFormRect][idx][2])
                widget_set_size(wcprops[wcpFormID][idx], wcprops[wcpFormRect][idx][3] - wcprops[wcpFormRect][idx][1],
                    wcprops[wcpFormRect][idx][4] - wcprops[wcpFormRect][idx][2])
                wc_call_arrange(wcprops[wcpFormID][idx])
            end if
            
            wc_call_draw(wid)
            
        elsif wcprops[wcpMode][idx] = 3 then  --"toolbox"
            
        end if
    end if
end procedure


function wc_debug(atom wid)
    atom idx
    sequence debuginfo = {}
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then    
        debuginfo = {
            {"Title", wcprops[wcpTitle][idx]},
            {"FormRect", wcprops[wcpFormRect][idx]},
            {"SoftFocus", wcprops[wcpSoftFocus][idx]},
            {"HardFocus", wcprops[wcpHardFocus][idx]},
            {"Mode", wcprops[wcpMode][idx]},
            {"MenubarID", wcprops[wcpMenubarID][idx]},
            {"InfobarID", wcprops[wcpInfobarID][idx]},
            {"FormID", wcprops[wcpFormID][idx]},
            {"Toolbars", wcprops[wcpToolbars][idx]},
            {"ToolbarRects", wcprops[wcpToolbarRects][idx]},
            {"ToolDockSizes", wcprops[wcpToolDockSizes][idx]},
            {"Panels", wcprops[wcpPanels][idx]},
            {"DockSizes", wcprops[wcpDockSizes][idx]},
            {"DockDividers", wcprops[wcpDockDividers][idx]},
            {"PanelSizes", wcprops[wcpPanelSizes][idx]},
            {"PanelDividers", wcprops[wcpPanelDividers][idx]},
            {"Tabs", wcprops[wcpTabs][idx]}
        }
    end if
    return debuginfo
end function



wc_define(
    "window",
    routine_id("wc_create"),
    routine_id("wc_destroy"),
    routine_id("wc_draw"),
    routine_id("wc_event"),
    routine_id("wc_resize"),
    routine_id("wc_arrange"),
    routine_id("wc_debug")
)   
    

-- widgetclass commands -------------------------------------------------------

procedure cmd_resize(atom wid, atom width, atom height)
    --? {width, height}
    oswin:set_window_size(widget_get_handle(wid), width, height)
end procedure
wc_define_command("window", "resize", routine_id("cmd_resize"))


procedure cmd_set_title(atom wid, sequence title)
    atom idx
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then    
        wcprops[wcpTitle][idx] = title
        oswin:set_window_title(widget_get_handle(wid), title)
    end if
end procedure
wc_define_command("window", "set_title", routine_id("cmd_set_title"))




