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

--****
--== Widgets
--
--<<LEVELTOC level=2 depth=4>>
--widget library

include redylib_0_9/oswin.e as oswin
include redylib_0_9/gui/themes.e as th

include std/sequence.e
include std/math.e
include std/search.e
include std/text.e
include std/pretty.e


enum
wpID,
wpName,
wpHandle, --window handle
wpClass,
wpEventHandler,

wpParent,
wpChildren,

wpPosition,
wpSize,
wpMinSize,
wpNaturalSize, --if natural size is 0, then allow widget to expand.
wpDefaultSize, --if > 0, a widget will be the default size instead of the minimum size in a dialog
wpOrder,
wpTabOrder,    --0=not a tab stop

wpEnabled,
wpVisible,
wpBusy,
wpAckTime,

wpMousePointer

    
constant wpLENGTH = wpMousePointer
constant AckTimeOut = 500 


sequence widgets = repeat({}, wpLENGTH)


--internal widgetclass handers
enum
wcName,
wcCommands,
wcFunctions,
wcCreateRoutine,
wcDestroyRoutine,
wcDrawRoutine,
wcEventRoutine,
wcResizeRoutine,
wcArrangeRoutine,
wcDebugRoutine
constant wcLENGTH = wcDebugRoutine


enum
wcCmdName,
wcCmdRoutine


enum
wcFuncName,
wcFuncRoutine


sequence wclasses = repeat({}, wcLENGTH)


enum
drOrder,
drWidgetID,
drDrawRoutine
constant drLENGTH = drDrawRoutine
sequence drawbuff = repeat({}, drLENGTH)


enum
reaWidgetID,
reaAction,
reaRoutine
constant reaLENGTH = reaRoutine
sequence reabuff = repeat({}, reaLENGTH)


public function widget_idx(object widorname)
    atom idx
    
    if atom(widorname) then
        idx = find(widorname, widgets[wpID])
    else
        idx = find(widorname, widgets[wpName])
    end if
    return idx
end function


public function widget_get_id(object widorname)
    object idx = widget_idx(widorname)
    
    if idx > 0 then
        return widgets[wpID][idx]
    else
        return 0
    end if
end function


public function widget_get_name(object widorname)
    atom idx = widget_idx(widorname)
    
    if idx > 0 then
        return widgets[wpName][idx]
    else
        wc_send_event("_debug", "widget_get_name", "Widget '" & widorname & "' does not exist.")
        return 0
    end if
end function


public function widget_get_class(object widorname)
    object idx = widget_idx(widorname)
    
    if idx > 0 then
        return widgets[wpClass][idx]
    else
        return ""
    end if
end function


public function widget_get_order(object widorname)
    atom idx = widget_idx(widorname)
    
    if idx > 0 then
        return widgets[wpOrder][idx]
    else
        return 0
    end if
end function


public procedure widget_set_handle(object widorname, atom winhandle)
    atom idx = widget_idx(widorname)
    
    if idx > 0 then
        widgets[wpHandle][idx] = winhandle
    end if
end procedure


public function widget_get_handle(object widorname)
    atom idx
    idx = widget_idx(widorname)
    
    if idx > 0 then
        return widgets[wpHandle][idx]
    else
        return 0
    end if
end function


public function widget_draw_enabled(object widorname)
    integer idx = widget_idx(widorname)
    
    if idx > 0 then 
        return oswin:draw_enabled(widget_get_handle(widgets[wpID][idx]))
    else
        return 0
    end if
end function


public procedure widget_enable_draw(object widorname)
    integer idx = widget_idx(widorname)
    
    if idx > 0 then 
        oswin:enable_draw(widget_get_handle(widgets[wpID][idx]))
    end if
end procedure


public procedure widget_disable_draw(object widorname)
    integer idx = widget_idx(widorname)
    
    if idx > 0 then 
        oswin:disable_draw(widget_get_handle(widgets[wpID][idx]))
    end if
end procedure


public procedure wc_call_create(object widorname, object wprops)
    atom idx = widget_idx(widorname), wcidx, wparent
    
    if idx then
        wcidx = find(widgets[wpClass][idx], wclasses[wcName])
        if wcidx then
            call_proc(wclasses[wcCreateRoutine][wcidx], {widgets[wpID][idx], wprops})
            wparent = parent_of(widgets[wpID][idx])
            if wparent > 0 then
                wc_call_event(wparent, "child created", {widgets[wpID][idx], wprops})
            end if
            wc_call_resize(widgets[wpID][idx])
        end if
    end if
end procedure


public procedure wc_call_destroy(object widorname)
    atom idx = widget_idx(widorname), wcidx, wparent
    
    if idx then
        wcidx = find(widgets[wpClass][idx], wclasses[wcName])
        if wcidx then
            wparent = parent_of(widgets[wpID][idx])
            if wparent > 0 then
                wc_call_event(wparent, "child destroyed", widgets[wpID][idx])
            end if
            call_proc(wclasses[wcDestroyRoutine][wcidx], {widgets[wpID][idx]})
        end if
    end if
end procedure


public procedure draw_widgets()
    atom morder
    sequence dbuff
    
    while length(drawbuff[drWidgetID]) > 0 do
        dbuff = drawbuff
        drawbuff = repeat({}, drLENGTH)
        if length(dbuff[drOrder]) > 0 then
            morder = max(dbuff[drOrder])
            for o = 1 to morder do
                for b = 1 to length(dbuff[drOrder]) do
                    if dbuff[drOrder][b] = o and dbuff[drWidgetID][b] > 0 then
                        call_proc(dbuff[drDrawRoutine][b], {dbuff[drWidgetID][b]})
                    end if
                end for
            end for
        end if
    end while
    oswin:update_windows()
end procedure


public procedure wc_call_draw(object widorname)
    atom idx = widget_idx(widorname), wcidx
    
    if idx then
        if widget_draw_enabled(widgets[wpID][idx]) and widgets[wpVisible][idx] then
            wcidx = find(widgets[wpClass][idx], wclasses[wcName])
            if wcidx then
                drawbuff[drWidgetID] = find_replace(widgets[wpID][idx], drawbuff[drWidgetID], 0)
                drawbuff[drOrder] &= {widgets[wpOrder][idx]}
                drawbuff[drWidgetID] &= {widgets[wpID][idx]}
                drawbuff[drDrawRoutine] &= {wclasses[wcDrawRoutine][wcidx]}
            end if
        end if
    end if
end procedure


public procedure wc_call_event(object widorname, sequence evtype, object evdata)
    atom idx = widget_idx(widorname), wcidx, wh
    
    if idx then
        wcidx = find(widgets[wpClass][idx], wclasses[wcName])
        if wcidx then
            call_proc(wclasses[wcEventRoutine][wcidx], {widgets[wpID][idx], evtype, evdata})
        end if
    end if
end procedure


public procedure rearrange_widgets()
    sequence rbuff
    
    while length(reabuff[reaWidgetID]) > 0 do
        rbuff = reabuff
        reabuff = repeat({}, reaLENGTH)
        for b = 1 to length(rbuff[reaWidgetID]) do
            if rbuff[reaWidgetID][b] > 0 then
                call_proc(rbuff[reaRoutine][b], {rbuff[reaWidgetID][b]})
            end if
        end for
    end while
end procedure


public procedure wc_call_resize(object widorname)
    atom idx = widget_idx(widorname), wcidx
    
    if idx then
        wcidx = find(widgets[wpClass][idx], wclasses[wcName])
        if wcidx then
            for b = 1 to length(reabuff[reaWidgetID]) do
                if reabuff[reaWidgetID][b] = widgets[wpID][idx] and reabuff[reaAction][b] = 1 then
                    reabuff[reaWidgetID][b] = 0
                end if
            end for
            reabuff[reaWidgetID] &= {widgets[wpID][idx]}
            reabuff[reaAction] &= 1
            reabuff[reaRoutine] &= {wclasses[wcResizeRoutine][wcidx]}
        end if
    end if
end procedure


public procedure wc_call_arrange(object widorname)
    atom idx = widget_idx(widorname), wcidx
    
    if idx then
        wcidx = find(widgets[wpClass][idx], wclasses[wcName])
        if wcidx then
            for b = 1 to length(reabuff[reaWidgetID]) do
                if reabuff[reaWidgetID][b] = widgets[wpID][idx] and reabuff[reaAction][b] = 2 then
                    reabuff[reaWidgetID][b] = 0
                end if
            end for
            reabuff[reaWidgetID] &= {widgets[wpID][idx]}
            reabuff[reaAction] &= 2
            reabuff[reaRoutine] &= {wclasses[wcArrangeRoutine][wcidx]}
        end if
    end if
end procedure


public function wc_call_debug(object widorname)
    atom idx = widget_idx(widorname), wcidx
    object result = {}
    
    if idx then
        wcidx = find(widgets[wpClass][idx], wclasses[wcName])
        if wcidx then
            result = {
                {"ID", widgets[wpID][idx]},
                {"Name", widgets[wpName][idx]},
                {"Handle", widgets[wpHandle][idx]},
                {"Class", widgets[wpClass][idx]},
                {"EventHandler", widgets[wpEventHandler][idx]},
                {"Parent", widgets[wpParent][idx]},
                {"Children", widgets[wpChildren][idx]},
                {"Position", widgets[wpPosition][idx]},
                {"Size", widgets[wpSize][idx]},
                {"MinSize", widgets[wpMinSize][idx]},
                {"NaturalSize,", widgets[wpNaturalSize][idx]},
                {"DefaultSize,", widgets[wpDefaultSize][idx]},
                {"Order", widgets[wpOrder][idx]},
                {"TabOrder", widgets[wpTabOrder][idx]},
                {"Enabled", widgets[wpEnabled][idx]},
                {"Visible", widgets[wpVisible][idx]},
                {"Busy", widgets[wpBusy][idx]},
                {"AckTime,", widgets[wpAckTime][idx]},
                {"MousePointer", widgets[wpMousePointer][idx]}
            }
            result &= call_func(wclasses[wcDebugRoutine][wcidx], {widgets[wpID][idx]})
        end if
    end if
    
    return result
end function


public procedure wc_call_command(object widorname, sequence cname, object params)
    atom idx = widget_idx(widorname), wcidx, cmdidx
    
    if idx then
        wcidx = find(widgets[wpClass][idx], wclasses[wcName])
        
        if wcidx then
            cmdidx = find(cname, wclasses[wcCommands][wcidx][wcCmdName])         
            if cmdidx then
                call_proc(wclasses[wcCommands][wcidx][wcCmdRoutine][cmdidx], {widgets[wpID][idx]} & params)
                --wc_send_event("_debug", "wc_call_command", {widorname})
            else
                wc_send_event("_debug", "wproc", "Procedure '" & cname & "' does not exist for widget class '"
                              & widgets[wpClass][idx] & "' (Widget '" & widgets[wpName][idx] & "').")
            end if
        end if
    end if
end procedure


public function wc_call_function(object widorname, sequence cname, object params)
    atom idx = widget_idx(widorname), wcidx, cmdidx
    object retval = 0
    
    if idx then
        wcidx = find(widgets[wpClass][idx], wclasses[wcName])
        if wcidx then
            cmdidx = find(cname, wclasses[wcFunctions][wcidx][wcFuncName])         
            if cmdidx then
                retval = call_func(wclasses[wcFunctions][wcidx][wcFuncRoutine][cmdidx], {widgets[wpID][idx]} & params)
            else
                wc_send_event("_debug", "wfunc", "Function '" & cname & "' does not exist for widget class '"
                              & widgets[wpClass][idx] & "' (Widget '" & widgets[wpName][idx] & "').")
            end if
        end if
    end if
    
    return retval
end function


sequence evbuff = {}
atom DefaultEventHandler = 0, DebugEventHandler = 0
--each widget can be assiged an event handler. Otherwise, it inherits the eventhandler from it's parent.
--If none is defined, the DefaultEventHandler set by gui:start() will be used.
    
    
public procedure set_default_event_handler(atom evh) 
    DefaultEventHandler = evh
end procedure


public procedure set_debug_event_handler(atom evh) 
    DebugEventHandler = evh
end procedure


public function get_app_events()
    sequence eb = evbuff
    
    evbuff = {}
    return eb
end function


public procedure wc_send_event(sequence wname, sequence evname, object evdata) --send an event to the application
    atom idx = widget_idx(wname)
    
    if idx then
        evbuff &= {{widgets[wpEventHandler][idx], wname, evname, evdata}}
        --pretty_print(1, {wname, evname, evdata}, {2})
        --event_ack_start(widorname)
    elsif equal(wname, "_debug") then
        evbuff &= {{DebugEventHandler, wname, evname, evdata}}
    else
        --wc_send_event("_debug", "send_event", "Unable to send event to widget '" & wname & "'. It does not exist.")
    end if
end procedure


public procedure wc_define(sequence cname, atom createrid = 0, atom destroyrid = 0, atom drawrid = 0, 
                           atom eventrid = 0, atom resizerid = 0, atom arrangerid = 0, atom debugid = 0)
    if not find(cname, wclasses[wcName]) then
        wclasses[wcName] &= {cname}
        wclasses[wcCommands] &= {{{}, {}}}
        wclasses[wcFunctions] &= {{{}, {}}}
        wclasses[wcCreateRoutine] &= {createrid}
        wclasses[wcDestroyRoutine] &= {destroyrid}
        wclasses[wcDrawRoutine] &= {drawrid}
        wclasses[wcEventRoutine] &= {eventrid}
        wclasses[wcResizeRoutine] &= {resizerid}
        wclasses[wcArrangeRoutine] &= {arrangerid}
        wclasses[wcDebugRoutine] &= {debugid}
    end if
end procedure


public procedure wc_define_command(sequence cname, sequence mname, atom mrid)
    atom idx = find(cname, wclasses[wcName])
    
    if idx then
        wclasses[wcCommands][idx][wcCmdName] &= {mname}
        wclasses[wcCommands][idx][wcCmdRoutine] &= {mrid}
    end if
end procedure


public procedure wc_define_function(sequence cname, sequence mname, atom mrid)
    atom idx = find(cname, wclasses[wcName])
    
    if idx then
        wclasses[wcFunctions][idx][wcFuncName] &= {mname}
        wclasses[wcFunctions][idx][wcFuncRoutine] &= {mrid}
    end if
end procedure


function nextID(sequence ids)
    object mx = 0
    
    if length(ids) > 0 then
        mx =  max(ids)
    end if
    if atom(mx) then
        return mx + 1
    else
        return 1
    end if
end function


public function in_rect(atom xpos, atom ypos, sequence rect)
    if xpos >= rect[1] and xpos <= rect[3] and ypos >= rect[2] and ypos <= rect[4] then
        return 1
    else
        return 0
    end if
end function


public function parent_of(object widorname)
    atom idx = widget_idx(widorname)
    
    if idx then
        return widgets[wpParent][idx]
    else
        return 0
    end if
end function


public function children_of(object widorname)
    atom idx = widget_idx(widorname)
    
    if idx then
        return widgets[wpChildren][idx]
    else
        return {}
    end if
end function


public function siblings_of(object widorname)
    atom idx = widget_idx(widorname)
    
    if idx then
        return children_of(widgets[wpParent][idx]) --todo: remove self id from list
    else
        return {}
    end if
end function


/*
public function ancestors_of(atom handle)
    return {}
end function


public function offspring_of(atom handle)
    return {}
end function
*/


public function screen_size()
    return oswin:getPrimaryDisplaySize()
end function


public function widget_create(sequence wname, object wparentidorname, sequence wclass, object wprops)
    object wid, pidx, pwin = 0
    sequence
    wposition = {-1, -1},
    wsize = {0, 0},
    wminsize = {10, 10},
    wnatsize = {0, 0}
    atom
    wparent = 0,
    whandler = DefaultEventHandler,
    wzorder = widget_get_order(wparent) + 1,
    wtaborder = 0,
    wenabled = 1,
    wvisible = 1
    
    if widget_idx(wname) > 0 then
        wc_send_event("_debug", "wcreate", "Unable to create widget '" & wname & "': Widget name already exists.")
        return 0 --do not create widget if widget name already exsists
    end if
    
    if find(wclass, wclasses[wcName]) = 0 then
        wc_send_event("_debug", "wcreate", "Unable to create widget '" & wname & "': Widget class '" & wclass & "' does not exist.")
        return 0 --do not create widget if widget name already exsists
    end if
    
    wid = nextID(widgets[wpID])
    
    if atom(wparentidorname) then
        if wparentidorname = 0 then
            pidx = 0
        else
            pidx = find(wparentidorname, widgets[wpID])
            if pidx = 0 then
                wc_send_event("_debug", "wcreate", "Unable to create widget '" & wname & "': Parent Widget ID " & sprint(wparentidorname) & " does not exist.")
                return 0 --do not create widget if parent is invalid
            end if
            whandler = widgets[wpEventHandler][pidx]
        end if
    else
        if equal(wparentidorname, "") then
            pidx = 0
        else
            pidx = find(wparentidorname, widgets[wpName])
            if pidx = 0 then
                wc_send_event("_debug", "wcreate", "Unable to create widget '" & wname & "': Parent widget '" & wparentidorname & "' does not exist.")
                return 0 --do not create widget if parent is invalid
            end if
            whandler = widgets[wpEventHandler][pidx]
        end if
    end if
    
    if pidx > 0 then
        widgets[wpChildren][pidx] &= {wid}
        pwin = widgets[wpHandle][pidx]
        wparent = widgets[wpID][pidx]
    end if
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do
                case "handler" then
                    whandler = wprops[p][2]
                case "position" then
                    wposition = wprops[p][2]
                case "size" then
                    wsize = wprops[p][2]
                case "min_size" then
                    wminsize = wprops[p][2]
                case "zorder" then
                    wzorder = wprops[p][2]
                case "taborder" then
                    wtaborder = wprops[p][2]
                case "enabled" then
                    wenabled = wprops[p][2]
                case "visible" then
                    wvisible = wprops[p][2]
            end switch
        end if
    end for
    
    widgets[wpID] &= {wid}
    if sequence(wname) then
        widgets[wpName] &= {wname}
    else
        widgets[wpName] &= {""}
    end if
    widgets[wpHandle] &= {pwin}
    widgets[wpClass] &= {wclass}
    widgets[wpEventHandler] &= {whandler}

    widgets[wpParent] &= {wparent}
    widgets[wpChildren] &= {{}}

    widgets[wpPosition] &= {wposition}
    widgets[wpSize] &= {wminsize}
    widgets[wpMinSize] &= {wminsize}
    widgets[wpNaturalSize] &= {wnatsize}
    widgets[wpDefaultSize] &= {wsize}
    
    widgets[wpOrder] &= {wzorder}
    widgets[wpTabOrder] &= {wtaborder}

    widgets[wpEnabled] &= {wenabled}
    widgets[wpVisible] &= {wvisible}
    widgets[wpBusy] &= {0}
    widgets[wpAckTime] &= {1}

    widgets[wpMousePointer] &= {0}
    wc_call_create(wid, wprops)
    
    if wvisible = 1 then
        wc_call_event(wname, "Visible", 1)
    end if
    
    if match("_winDebug", wname) = 0 then
        wc_send_event("_debug", "refresh_widget_tree", widgets[wpID..wpMousePointer])
    end if
    
    return wid
end function


procedure w_destroy(object widorname)
    object idx = widget_idx(widorname)
    sequence ch
    
    if idx then
        wc_call_destroy(widgets[wpID][idx])
        ch = widgets[wpChildren][idx]
        for wp = 1 to length(widgets) do     
            widgets[wp] = remove(widgets[wp], idx)
        end for
        for wch = 1 to length(ch) do
            w_destroy(ch[wch])
        end for
    end if
end procedure


public procedure widget_destroy(object widorname)
    integer idx = widget_idx(widorname), wid, wpar, pidx, pf
    sequence wname
    
    if idx > 0 then
        wname = widgets[wpName][idx]
        wid = widgets[wpID][idx]
        wpar = widgets[wpParent][idx]
        wc_send_event(wname, "destroyed", {wname})
        w_destroy(widgets[wpID][idx])
        pidx = find(wpar, widgets[wpID])
        if pidx then
            pf = find(wid, widgets[wpChildren][pidx])
            if pf then
                widgets[wpChildren][pidx] = remove(widgets[wpChildren][pidx], pf)
            end if
            wc_call_event(wpar, "child destroyed", wid)
            wc_call_resize(wpar)
        end if
        if match("_winDebug", wname) = 0 then
            wc_send_event("_debug", "refresh_widget_tree", widgets[wpID..wpChildren])
        end if
    else
        if sequence(widorname) then
            wc_send_event("_debug", "wdestroy", "Unable to destroy widget '" & widorname & "'. It does not exist.")
        else
            wc_send_event("_debug", "wdestroy", "Unable to destroy widget ID " & sprint(widorname) & ". It does not exist.")
        end if
    end if
end procedure


public function widget_check_size(object widorname, integer xsize, integer ysize)
    atom idx = widget_idx(widorname)
    
    if idx > 0 then
        if xsize < widgets[wpMinSize][idx][1] then
            xsize = widgets[wpMinSize][idx][1]
        end if
        if ysize < widgets[wpMinSize][idx][2] then
            ysize = widgets[wpMinSize][idx][2]
        end if
        
        return {xsize, ysize}
    else
        return {0, 0}
    end if
end function


public function widget_get_rect(object widorname)
    atom idx = widget_idx(widorname)
    
    sequence rect
    if idx > 0 then
        rect = widgets[wpPosition][idx] & widgets[wpPosition][idx] + widgets[wpSize][idx]
        if length(rect) = 4 then
            return rect
        else
            return {0, 0, 0, 0}
        end if
    else
        return {0, 0, 0, 0}
    end if
end function


public procedure widget_set_pos(object widorname, integer xpos, integer ypos)
    atom idx = widget_idx(widorname)
    
    if idx > 0 then
        widgets[wpPosition][idx] = {xpos, ypos}
    end if
end procedure


public function widget_get_pos(object widorname)
    atom idx = widget_idx(widorname)
    
    if idx > 0 and length(widgets[wpPosition][idx]) = 2 then
        return widgets[wpPosition][idx]
    else
        return {0, 0}
    end if
end function


public procedure widget_set_size(object widorname, integer xsize, integer ysize)
    atom idx = widget_idx(widorname)
    
    if idx > 0 then
        widgets[wpSize][idx] = widget_check_size(widgets[wpID][idx], xsize, ysize)
    end if
end procedure


public function widget_get_size(object widorname)
    atom idx = widget_idx(widorname)
    
    if idx > 0 and length(widgets[wpSize][idx]) = 2 then
        return widgets[wpSize][idx]
    else
        return {0, 0}
    end if
end function


public function widget_get_min_size(object widorname)
    atom idx = widget_idx(widorname)
    
    if idx > 0 and length(widgets[wpMinSize][idx]) = 2 then
        return widgets[wpMinSize][idx]
    else
        return {0, 0}
    end if
end function


public function widget_get_natural_size(object widorname)
    atom idx = widget_idx(widorname)
    
    if idx > 0 and length(widgets[wpNaturalSize][idx]) = 2 then
        return widgets[wpNaturalSize][idx]
    else
        return {0, 0}
    end if
end function


public procedure widget_set_default_size(object widorname, integer xsize, integer ysize)
    atom idx = widget_idx(widorname)
    
    if idx > 0 then
        widgets[wpDefaultSize][idx] = {xsize, ysize}
    end if
end procedure


public procedure widget_set_default_width(object widorname, integer xsize)
    atom idx = widget_idx(widorname)
    
    if idx > 0 then
        widgets[wpDefaultSize][idx][1] = xsize
    end if
end procedure


public procedure widget_set_default_height(object widorname, integer ysize)
    atom idx = widget_idx(widorname)
    
    if idx > 0 then
        widgets[wpDefaultSize][idx][2] = ysize
    end if
end procedure


public function widget_get_default_size(object widorname)
    atom idx = widget_idx(widorname)
    
    if idx > 0 and length(widgets[wpDefaultSize][idx]) = 2 then
        return widgets[wpDefaultSize][idx]
    else
        return {0, 0}
    end if
end function


public procedure widget_set_min_size(object widorname, atom xsize, atom ysize)
    atom idx = widget_idx(widorname)
    
    widgets[wpMinSize][idx] = {xsize, ysize}
end procedure


public procedure widget_set_natural_size(object widorname, atom xsize, atom ysize)
    atom idx = widget_idx(widorname)
    
    if idx > 0 then
        widgets[wpNaturalSize][idx] = {xsize, ysize}
    end if
end procedure


/*
public procedure widget_set_tab_order(object widorname)
    atom idx
    
    idx = widget_idx(widorname)

    if idx > 0 then
        widgets[wpTabOrder][idx] = {xsize, ysize}
    end if
end procedure


public function widget_get_tab_order(object widorname)
    atom idx
    
    idx = widget_idx(widorname)

    if idx > 0 then
        return widgets[wpTabOrder][idx]
    else
        return 0
    end if
end function
*/


public function widget_is_enabled(object widorname)
    atom idx = widget_idx(widorname)
    
    if idx > 0 then
        return widgets[wpEnabled][idx]
    else
        return 0
    end if
end function


public function widget_is_visible(object widorname)
    atom idx = widget_idx(widorname)
    
    if idx > 0 then
        return widgets[wpVisible][idx]
    else
        return 0
    end if
end function



procedure show_children(object widorname)
    atom idx = widget_idx(widorname), chidx
    sequence chlist
    
    if idx > 0 then
        chlist = children_of(widgets[wpID][idx])
        for ch = 1 to length(chlist) do
            chidx = widget_idx(chlist[ch])
            widgets[wpVisible][chidx] = 1
            wc_call_event(widgets[wpName][chidx], "Visible", 1)
            show_children(chlist[ch])
            wc_call_resize(widgets[wpID][idx])
        end for
    end if
end procedure


public procedure widget_show(object widorname)
    integer idx = widget_idx(widorname), wp
    sequence rlist
    if idx > 0 then
        --wp = find(widgets[wpParent][idx], widgets[wpID])
        widgets[wpVisible][idx] = 1
        wc_call_event(widgets[wpName][idx], "Visible", 1)
        
        show_children(widgets[wpID][idx])
        wc_call_event(parent_of(widorname), "child shown", widgets[wpName][idx])
        --wc_call_arrange(widgets[wpID][idx])
        wc_call_resize(widgets[wpID][idx])
        
    end if
end procedure


procedure hide_children(object widorname)
    atom idx = widget_idx(widorname), chidx
    sequence chlist
    
    if idx > 0 then
        chlist = children_of(widgets[wpID][idx])
        for ch = 1 to length(chlist) do
            chidx = widget_idx(chlist[ch])
            widgets[wpVisible][chidx] = 0
            wc_call_event(widgets[wpName][chidx], "Visible", 0)
            hide_children(chlist[ch])
        end for
    end if
end procedure


public procedure widget_hide(object widorname)
    integer idx = widget_idx(widorname), wp
    sequence rlist
    if idx > 0 then
        wp = find(widgets[wpParent][idx], widgets[wpID])
        widgets[wpVisible][idx] = 0
        wc_call_event(widgets[wpName][idx], "Visible", 0)
        hide_children(widgets[wpID][idx])
        wc_call_event(parent_of(widorname), "child hidden", widgets[wpName][idx])
        --wc_call_arrange(widgets[wpID][idx])
        --wc_call_resize(widgets[wpID][idx])
    end if
end procedure


public procedure set_key_focus(object widorname)
    integer idx = widget_idx(widorname), whandle
    if idx > 0 then
        whandle = widget_get_handle(widorname)
        --puts(1, "set_key_focus: " & widget_get_name(widorname) & "\n")
        for w = 1 to length(widgets[wpID]) do
            if widgets[wpHandle][w] = whandle then
                wc_call_event(widgets[wpID][w], "KeyFocus", widgets[wpID][idx])
            end if
        end for
        --rootwid = oswin:get_window_owner(whandle)
        --wc_call_event(rootwid, "SetKeyFocus", widgets[wpName][idx])
    end if
end procedure


/*
public procedure next_key_focus(object widorname)
    integer idx = widget_idx(widorname), whandle, foundidx
    if idx > 0 then
        whandle = widget_get_handle(idx)
        foundidx = idx --todo: find next
        for w = 1 to length(widgets[wpID]) do
            if widgets[wpHandle][w] = whandle then
                wc_call_event(widgets[wpID][w], "SetKeyFocus", widgets[wpID][foundidx])
            end if
        end for
    end if
end procedure


public procedure prev_key_focus(object widorname)
    integer idx = widget_idx(widorname), whandle, foundidx
    if idx > 0 then
        whandle = widget_get_handle(idx)
        foundidx = idx --todo: find previous
        for w = 1 to length(widgets[wpID]) do
            if widgets[wpHandle][w] = whandle then
                wc_call_event(widgets[wpID][w], "SetKeyFocus", widgets[wpID][foundidx])
            end if
        end for
    end if
end procedure
*/
                        
                        
/*
public procedure widget_set_busy(atom sesid)
   for w = 1 to length(widgets[wpID]) do
      if widgets[wpSessionID][w] = sesid or sesid = 0 then
         widgets[wpBusy][w] = 1
         if widgets[wpParent][w] = 0 then
--          fgSetMousePointer(rectGetWindowID(widgets[wpProps][w][1]), mBusy)
         end if
      end if
   end for
end procedure

public procedure widget_set_ready(atom sesid)
--puts(1, "set widgets ready\n")
   for w = 1 to length(widgets[wpID]) do
      if widgets[wpSessionID][w] = sesid or sesid = 0 then
         widgets[wpBusy][w] = 0
      end if
   end for
end procedure

public function widget_is_busy(object widorname)
   atom idx
    if atom(widorname) then
        idx = find(widorname, widgets[wpID])
    else
        idx = find(widorname, widgets[wpName])
    end if
   
    if idx > 0 and length(widgets[wpNaturalSize][idx]) = 2 then
        return widgets[wpBusy][idx]
    else
        return 0
    end if
end function
*/

--wpLabel,
--wpTooltip,
--wpMousePointer,

/*
public procedure widget_set_mouse_pointer(object widorname, atom mouseP)
    integer idx = widget_idx(widorname)
    if idx > 0 then
      --if widgets[wpMousePointer][idx] != mouseP then
         --widgets[wpMousePointer][idx] = mouseP
         if widgets[wpBusy][idx] = 1 then
--          fgSetMousePointer(rectGetWindowID(widgets[wpProps][idx][1]), mBusy)
         else
--          fgSetMousePointer(rectGetWindowID(widgets[wpProps][idx][1]), mouseP)
         end if
      --end if
   end if
end procedure


public function is_timed_out(object widorname)
    atom idx = widget_idx(widorname)
    if idx > 0 then
        return widgets[wpAckTime][idx] > AckTimeOut
    else
        return 0
    end if
end function


public procedure event_ack_start(object widorname)
    atom idx = widget_idx(widorname)
    if idx > 0 then
        widgets[wpAckTime][idx] = 1
    end if
end procedure


public procedure event_ack(object widorname)
    atom idx = widget_idx(widorname)
    if idx > 0 then
        widgets[wpAckTime][idx] = 0
    end if
end procedure
*/


public procedure process_events(atom ecount)
    object ev
    for c = 1 to ecount do
        ev = oswin:window_get_event()
        if sequence(ev) then --{windowid, evtype, evdata}
            for w = 1 to length(widgets[wpID]) do
                if w > length(widgets[wpID]) then
                    exit
                end if
                if widgets[wpHandle][w] = ev[1] and widgets[wpVisible][w] then
                    wc_call_event(widgets[wpID][w], ev[2], ev[3])
                end if
            end for
        end if
    end for
end procedure


-- API Routines --------------------------------------------------------

--**
-- Creates and schedules a task in one simple step.
--
-- Parameters:
--		# ##rid## : routine id
--		# ##args## : routine arguments
--		# ##schedule## :task schedule (defaults to 1).
--
-- Returns:
--	An **integer**, 1 if a sequence operation is valid between ##a## and ##b##, else 0.
--
-- Example 1:
-- <eucode>
-- i = binop_ok({1,2,3},{4,5})
-- -- i is 0
--
-- i = binop_ok({1,2,3},4)
-- -- i is 1
--
-- i = binop_ok({1,2,3},{4,{5,6},7})
-- -- i is 1
-- </eucode>
--
-- See Also:
--     [[:series]]
public procedure wcreate(object cprops)
    object wname = "", wparent = "", wclass = "", wprops = {}
    atom void
    
    for p = 1 to length(cprops) do
        if length(cprops[p]) = 2 then
            switch cprops[p][1] do
                case "name" then
                    wname = cprops[p][2]
                case "parent" then
                    wparent = cprops[p][2]
                case "class" then
                    wclass = cprops[p][2]
                case else  
                    wprops &= {cprops[p]}
            end switch
        end if
    end for
    void = widget_create(wname, wparent, wclass, wprops)
end procedure


public function wexists(object widorname)
    atom idx = widget_idx(widorname)
    
    if idx > 0 then
        return 1
    else
        return 0
    end if
end function


public procedure wdestroy(object wname)
    widget_destroy(wname)
end procedure


public function wfunc(object wname, object funcname, object params)
    return wc_call_function(wname, funcname, params)
end function


public procedure wproc(object wname, object procname, object params)
    wc_call_command(wname, procname, params)
end procedure


public procedure wenable(object wname, atom en = 1)
    atom idx = widget_idx(wname)
    
    if idx > 0 and widgets[wpEnabled][idx] != en then
        widgets[wpEnabled][idx] = en
        wc_call_event(widgets[wpID][idx], "SetEnabled", en)
    end if
end procedure


public procedure wdisable(object wname, atom en = 0)
    atom idx = widget_idx(wname)
    
    if idx > 0 and widgets[wpEnabled][idx] != en then
        widgets[wpEnabled][idx] = en
        wc_call_event(widgets[wpID][idx], "SetEnabled", en)
    end if
end procedure


public procedure wset(object wname, object wprops)
    
end procedure


public function wget(object wname, object wprops)
    return 0
end function


public function wdebug(object wname)
    return wc_call_debug(wname)
end function



