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


--public include syslib/oswin/win32/win32.e as oswin
--public include themes.e as th
include widgets.e as widget

include std/text.e
include std/pretty.e
include std/error.e
include euphoria/info.e


atom debugon = 1, DebugRealTime = 1, MaxHistory = 100

sequence debugErrors = {}, debugEvents = {}, debugWidgetData = {}, debugWidgetTreeItms = {}, debugVars = {{}, {}}
sequence LastWidgetName = "", CurrVarName = ""


procedure debug_add_error(object msgtype, object msgdata)
    if debugon = 1 then
        if equal(msgtype, "refresh_widget_tree") then
            debug_update_widget_tree(msgdata)
        else
            debugErrors &= {{{}, msgtype, msgdata}}
            if length(debugErrors) > MaxHistory then
                debugErrors = debugErrors[$-MaxHistory+1..$]
            end if
            if widget:wexists("_winDebug.lstErrors") then
                widget:wproc("_winDebug.lstErrors", "add_list_items", {{
                    {{}, msgtype, msgdata}
                }})
            end if
        end if
    end if
end procedure


procedure debug_add_event(object evsource, object evtype, object evdata)
    if debugon = 1 then
        debugEvents &= {{{}, evsource, evtype, pretty_sprint(evdata, {2})}}
        if length(debugEvents) > MaxHistory then
                debugEvents = debugEvents[$-MaxHistory+1..$]
            end if
        if widget:wexists("_winDebug.lstEvents") then
            widget:wproc("_winDebug.lstEvents", "add_list_items", {{
                {{}, evsource, evtype, pretty_sprint(evdata, {2})}
            }})
        end if
    end if
end procedure


enum
wpID,
wpName,
wpHandle,
wpClass,
wpEventHandler,

wpParent,
wpChildren


procedure build_tree()
    sequence itmlist = {0}, itmwids = {0}
    atom citm = 0, cwid = 0, itmid

    widget:wproc("_winDebug.treWidgets", "clear_tree", {})
    debugWidgetTreeItms = {}
    while length(itmlist) > 0 do
        citm = itmlist[1]
        cwid = itmwids[1]
         
        itmlist = itmlist[2..$]
        itmwids = itmwids[2..$]
        
        for i = 1 to length(debugWidgetData[wpID]) do
            if debugWidgetData[wpParent][i] = cwid then
                itmid = widget:wfunc("_winDebug.treWidgets", "add_item", {citm, {}, debugWidgetData[wpName][i] & " (" & debugWidgetData[wpClass][i] & ")", 1})
                itmlist &= itmid 
                itmwids &= debugWidgetData[wpID][i]
                debugWidgetTreeItms &= {{itmid, debugWidgetData[wpID][i]}}
            end if
        end for
    end while
end procedure


procedure debug_update_widget_tree(sequence wdata)
    if debugon = 1 then
        debugWidgetData = repeat({}, wpChildren)
        for w = 1 to length(wdata[wpID]) do
            if match("_winDebug", wdata[wpName][w]) = 0 then
                debugWidgetData[wpID] &= {wdata[wpID][w]}
                debugWidgetData[wpName] &= {wdata[wpName][w]}
                debugWidgetData[wpHandle] &= {wdata[wpHandle][w]}
                debugWidgetData[wpClass] &= {wdata[wpClass][w]}
                debugWidgetData[wpParent] &= {wdata[wpParent][w]}
                debugWidgetData[wpChildren] &= {wdata[wpChildren][w]}
            end if
        end for
        if widget:wexists("_winDebug.treWidgets") then
            build_tree()
        end if
    end if
end procedure


procedure update_widget_details(sequence wname)
    sequence winfo, txt
    object tmp
    
    if widget:wexists("_winDebug.txtWidgetDetails") then
        if length(wname) = 0 then
            txt = "<-- Select a widget"
        elsif widget:wexists(wname) then
            txt = "[Widget Properties]\n"
            winfo = widget:wdebug(wname)
            for i = 1 to length(winfo) do
                tmp = {pretty_sprint(winfo[i][2], {2}), pretty_sprint(winfo[i][2], {0})}
                if equal(tmp[1], tmp[2]) then
                    txt &= "* " & winfo[i][1] & " = " & tmp[1] & "\n"
                else
                    txt &= "* " & winfo[i][1] & " = " & tmp[1] & "  " & tmp[2] & "\n"
                end if
            end for
        else
            txt = "Widget '" & wname & "' does not exist."
        end if
        widget:wproc("_winDebug.txtWidgetDetails", "set_text", {txt})
    end if
end procedure


public procedure debug(sequence varname, object vardata, atom appendmode = 0)
    atom vidx = find(varname, debugVars[1])
    sequence varlist = {}
    
    if debugon = 1 then
        if vidx > 0 then
            if appendmode = 1 then
                debugVars[2][vidx] &= "\n" & pretty_sprint(vardata, {2})
            else
                debugVars[2][vidx] = pretty_sprint(vardata, {2})
            end if
        else
            debugVars[1] &= {varname}
            debugVars[2] &= {pretty_sprint(vardata, {2})}
        end if
        if widget:wexists("_winDebug.lstDebug") then
            update_var_list()
            if equal(varname, CurrVarName) and DebugRealTime = 1 then
                update_var_data(CurrVarName)
            end if
        end if
    end if
end procedure


procedure update_var_list()
    sequence varlist = {}
    
    for v = 1 to length(debugVars[1]) do
        varlist &= {{{}, debugVars[1][v]}}
    end for
    widget:wproc("_winDebug.lstDebug", "clear_list", {})    
    widget:wproc("_winDebug.lstDebug", "add_list_items", {varlist})
end procedure


procedure update_var_data(sequence varname)
    sequence txt
    
    if debugon = 1 then
        if widget:wexists("_winDebug.txtDebugData") then
            if length(varname) = 0 then
                txt = "<-- Select a debug variable"
            else
                atom vidx = find(varname, debugVars[1])
                if vidx = 0 then
                    txt = "Variable '" & varname & "' does not exist."
                else
                    txt = debugVars[2][vidx]
                end if
            end if
            widget:wproc("_winDebug.txtDebugData", "set_text", {txt})
        end if
    end if
end procedure


procedure sysinfo_update()
    sequence debugSysinfo = 
    "Redy Application Environment™ version " & RedyAE_Version & "\n" &
    RedyAE_Copyright & "\n" &
    "http://redy-project.org/\n" &
    "\n" &
    "[Platform Information]\n" &
    "platform_name: " & platform_name() & "\n" &
    "\n" &
    "[Euphoria Information]\n" &
    "version_string: " & version_string(0) & "\n" &
    "version_node: " & version_node(0) & "\n" &
    "version_date: " & version_date(0) & "\n" &
    "version_type: " & version_type() & "\n" &
    "version_string_long: " & version_string_long(0) & "\n" &
    "include_paths: " & pretty_sprint(include_paths(0), {2}) & "\n" &
    "option_switches: " & pretty_sprint(option_switches(), {2})
    
    if widget:wexists("_winDebug.txtSysinfo") then
        widget:wproc("_winDebug.txtSysinfo", "set_text", {debugSysinfo})
    end if
end procedure


procedure debug_event(object evsource, object evtype, object evdata)
    atom idx = 0
    sequence txt = "", tmp, winfo
    
    if debugon = 0 then
        return
    end if
    switch evsource do
        case "_debug" then
            if match("_winDebug", evdata) = 0 then
                debug_add_error(evtype, evdata)
            end if

        case "_winDebug" then
            if equal(evtype, "closed") then
                debugon = 0
            end if
            
        case "_winDebug.optPage.Errors" then
            if equal(evtype, "selected") then
                widget:wdestroy("_winDebug.cntCmds")
                widget:wcreate({
                    {"parent", "_winDebug.cntTopRight"},
                    {"name", "_winDebug.cntCmds"},
                    {"class", "container"},
                    {"orientation", "horizontal"},
                    {"sizemode_x", "equal"},
                    {"sizemode_y", "normal"},
                    {"justify_x", "right"}
                })
                
                widget:wcreate({
                    {"parent", "_winDebug.cntCmds"},
                    {"name", "_winDebug.btnClearErrors"},
                    {"class", "button"},
                    {"label", "Clear"}
                })
            
                widget:wdestroy("_winDebug.cntBottom")
                widget:wcreate({
                    {"parent", "_winDebug.cntMain"},
                    {"name", "_winDebug.cntBottom"},
                    {"class", "container"},
                    {"orientation", "horizontal"},
                    {"sizemode_x", "expand"},
                    {"sizemode_y", "expand"}
                })
                
                widget:wcreate({
                    {"parent", "_winDebug.cntBottom"},
                    {"name", "_winDebug.lstErrors"},
                    {"class", "listbox"},
                    {"stay_at_bottom", 1},
                    {"label", "Errors"}
                })
                
                widget:wproc("_winDebug.lstErrors", "clear_list", {})
                widget:wproc("_winDebug.lstErrors", "add_column", {{"Routine", 70, 0, 0}})           
                widget:wproc("_winDebug.lstErrors", "add_column", {{"Error", 250, 0, 0}})           
                widget:wproc("_winDebug.lstErrors", "add_list_items", {debugErrors})
            end if
        
        case "_winDebug.optPage.Events" then
            if equal(evtype, "selected") then
                widget:wdestroy("_winDebug.cntCmds")
                widget:wcreate({
                    {"parent", "_winDebug.cntTopRight"},
                    {"name", "_winDebug.cntCmds"},
                    {"class", "container"},
                    {"orientation", "horizontal"},
                    {"sizemode_x", "equal"},
                    {"sizemode_y", "normal"},
                    {"justify_x", "right"}
                })
                
                widget:wcreate({
                    {"parent", "_winDebug.cntCmds"},
                    {"name", "_winDebug.btnClearEvents"},
                    {"class", "button"},
                    {"label", "Clear"}
                })
            
                widget:wdestroy("_winDebug.cntBottom")
                widget:wcreate({
                    {"parent", "_winDebug.cntMain"},
                    {"name", "_winDebug.cntBottom"},
                    {"class", "container"},
                    {"orientation", "horizontal"},
                    {"sizemode_x", "expand"},
                    {"sizemode_y", "expand"}
                })
                --Event List
                widget:wcreate({
                    {"parent", "_winDebug.cntBottom"},
                    {"name", "_winDebug.lstEvents"},
                    {"class", "listbox"},
                    {"stay_at_bottom", 1},
                    {"label", "Events"}
                })
                widget:wproc("_winDebug.lstEvents", "clear_list", {})
                widget:wproc("_winDebug.lstEvents", "add_column", {{"Widget", 200, 0, 0}})
                widget:wproc("_winDebug.lstEvents", "add_column", {{"Event Type", 80, 0, 0}})
                widget:wproc("_winDebug.lstEvents", "add_column", {{"Event Data", 200, 0, 0}})
                widget:wproc("_winDebug.lstEvents", "add_list_items", {debugEvents})
            end if
            
        case "_winDebug.optPage.Widgets" then
            if equal(evtype, "selected") then
                widget:wdestroy("_winDebug.cntCmds")
                widget:wcreate({
                    {"parent", "_winDebug.cntTopRight"},
                    {"name", "_winDebug.cntCmds"},
                    {"class", "container"},
                    {"orientation", "horizontal"},
                    {"sizemode_x", "equal"},
                    {"sizemode_y", "normal"},
                    {"justify_x", "right"}
                })
                
                widget:wcreate({
                    {"parent", "_winDebug.cntCmds"},
                    {"name", "_winDebug.btnRefreshWidget"},
                    {"class", "button"},
                    {"label", "Refresh"}
                })
            
                widget:wdestroy("_winDebug.cntBottom")
                widget:wcreate({
                    {"parent", "_winDebug.cntMain"},
                    {"name", "_winDebug.cntBottom"},
                    {"class", "container"},
                    {"orientation", "horizontal"},
                    {"sizemode_x", "expand"},
                    {"sizemode_y", "expand"}
                })
                --Widget Tree
                widget:wcreate({
                    {"parent", "_winDebug.cntBottom"},
                    {"name", "_winDebug.treWidgets"},
                    {"class", "treebox"},
                    --{"natural_size", {80, 0}},
                    {"label", "Widget Tree"}
                })
                build_tree()
                
                widget:wcreate({
                    {"name", "_winDebug.divWidgets"},
                    {"parent", "_winDebug.cntBottom"},
                    {"class", "divider"},
                    {"attach", "_winDebug.treWidgets"}
                })
                widget:wcreate({
                    {"name", "_winDebug.txtWidgetDetails"},
                    {"parent", "_winDebug.cntBottom"},
                    {"class", "textbox"},
                    {"mode", "text"},
                    {"label", "Widget Details"}
                })
                update_widget_details("")
            end if
            
        case "_winDebug.optPage.Debug" then
            if equal(evtype, "selected") then
                widget:wdestroy("_winDebug.cntCmds")
                widget:wcreate({
                    {"parent", "_winDebug.cntTopRight"},
                    {"name", "_winDebug.cntCmds"},
                    {"class", "container"},
                    {"orientation", "horizontal"},
                    {"sizemode_x", "equal"},
                    {"sizemode_y", "normal"},
                    {"justify_x", "right"}
                })
                
                widget:wcreate({
                    {"parent", "_winDebug.cntCmds"},
                    {"name", "_winDebug.chkRealTime"},
                    {"class", "toggle"},
                    {"label", "Realtime updates"},
                    {"value", DebugRealTime}
                })
            
                widget:wdestroy("_winDebug.cntBottom")
                widget:wcreate({
                    {"parent", "_winDebug.cntMain"},
                    {"name", "_winDebug.cntBottom"},
                    {"class", "container"},
                    {"orientation", "horizontal"},
                    {"sizemode_x", "expand"},
                    {"sizemode_y", "expand"}
                })
                --Debug Messages
                widget:wcreate({
                    {"parent", "_winDebug.cntBottom"},
                    {"name", "_winDebug.lstDebug"},
                    {"class", "listbox"},
                    --{"stay_at_bottom", 1},
                    {"label", "Debug Variables"},
                    {"size", {250, 0}}
                })
                update_var_list()
                
                widget:wcreate({
                    {"name", "_winDebug.divDebug"},
                    {"parent", "_winDebug.cntBottom"},
                    {"class", "divider"},
                    {"attach", "_winDebug.lstDebug"}
                })
                widget:wcreate({
                    {"name", "_winDebug.txtDebugData"},
                    {"parent", "_winDebug.cntBottom"},
                    {"class", "textbox"},
                    {"mode", "text"},
                    {"label", "Debug Data"}
                })
                update_var_data("")
            end if
            
        case "_winDebug.optPage.Sysinfo" then
            if equal(evtype, "selected") then
                widget:wdestroy("_winDebug.cntCmds")
                widget:wcreate({
                    {"parent", "_winDebug.cntTopRight"},
                    {"name", "_winDebug.cntCmds"},
                    {"class", "container"},
                    {"orientation", "horizontal"},
                    {"sizemode_x", "equal"},
                    {"sizemode_y", "normal"},
                    {"justify_x", "right"}
                })
                
                widget:wdestroy("_winDebug.cntBottom")
                widget:wcreate({
                    {"parent", "_winDebug.cntMain"},
                    {"name", "_winDebug.cntBottom"},
                    {"class", "container"},
                    {"orientation", "horizontal"},
                    {"sizemode_x", "expand"},
                    {"sizemode_y", "expand"}
                })
                --Sytem Information
                widget:wcreate({
                    {"name", "_winDebug.txtSysinfo"},
                    {"parent", "_winDebug.cntBottom"},
                    {"class", "textbox"},
                    {"mode", "text"},
                    {"label", "System Information"}
                })
                sysinfo_update()
            end if
            
        case "_winDebug.lstErrors" then
            if equal(evtype, "selection") and length(evdata) > 0 then
                txt = "Message Details:\n" & 
                    "Message Type = " & evdata[1][2][1] & "\n" &
                    "Message Data = " & evdata[1][2][2] & "\n"
            end if
            
        case "_winDebug.lstEvents" then
            if equal(evtype, "selection") and length(evdata) > 0 then
                txt = "Event Details:\n" &
                    "Widget = " & evdata[1][2][1] & "\n" &
                    "Event Type = " & evdata[1][2][2] & "\n" &
                    "Event Data = " & evdata[1][2][3] & "\n"
            end if
            
        case "_winDebug.treWidgets" then
            LastWidgetName = ""
            if equal(evtype, "selection") then
                for wi = 1 to length(debugWidgetTreeItms) do --{itmid, debugWidgetData[wpID][i]}
                    if debugWidgetTreeItms[wi][1] = evdata[1] then
                        idx = find(debugWidgetTreeItms[wi][2], debugWidgetData[wpID])
                        exit
                    end if
                end for
                if idx > 0 then
                    LastWidgetName = debugWidgetData[wpName][idx]
                    update_widget_details(LastWidgetName)
                end if
            end if
            
        case "_winDebug.btnRefreshWidget" then
            update_widget_details(LastWidgetName)
            
        case "_winDebug.lstDebug" then
            if equal(evtype, "selection") and length(evdata) > 0 then
                CurrVarName = evdata[1][2][1]
                update_var_data(CurrVarName)
            end if
            
        case "_winDebug.btnClearErrors" then
            debugErrors = {}
            if widget:wexists("_winDebug.lstErrors") then
                widget:wproc("_winDebug.lstErrors", "clear_list", {})
            end if
            
        case "_winDebug.btnClearEvents" then
            debugEvents = {}
            if widget:wexists("_winDebug.lstEvents") then
                widget:wproc("_winDebug.lstEvents", "clear_list", {})
            end if
            
        case "_winDebug.chkRealTime" then
            --debug("_winDebug.chkRealTime-evtype", evtype) --hah! i used my new debug feature to debug the new debug feature! lol
            --debug("_winDebug.chkRealTime-evdata", evdata)
            if equal(evtype, "value") then
                DebugRealTime = evdata
            end if
            
        case else
            if match("_winDebug", evsource) = 0 then
                debug_add_event(evsource, evtype, evdata)
            end if
    end switch
end procedure


public procedure show_debug()
    debugon = 1
    if widget:wexists("_winDebug") = 0 then
        sequence scrsize = widget:screen_size()
        widget:wcreate({
            {"name", "_winDebug"},
            {"class", "window"},
            {"title", "Redy Debug Console"},
            {"position", {floor(scrsize[1] / 2), floor(scrsize[2] / 2)}},
            {"size", {floor(scrsize[1] / 2) - 40, floor(scrsize[2] / 2) - 40}},
            {"handler", routine_id("debug_event")}
        })
        widget:wcreate({
            {"parent", "_winDebug"},
            {"name", "_winDebug.cntMain"},
            {"class", "container"},
            {"orientation", "vertical"},
            {"sizemode_x", "expand"},
            {"sizemode_y", "expand"}
        })
        widget:wcreate({
            {"parent", "_winDebug.cntMain"},
            {"name", "_winDebug.cntTop"},
            {"class", "container"},
            {"orientation", "horizontal"},
            {"sizemode_x", "expand"},
            {"sizemode_y", "normal"}
        })
        widget:wcreate({
            {"parent", "_winDebug.cntTop"},
            {"name", "_winDebug.cntTopPages"},
            {"class", "container"},
            {"orientation", "horizontal"},
            {"sizemode_x", "equal"},
            {"sizemode_y", "normal"}
        })
        
        --Page Select Option Group (In the future, use a tab bar)
        widget:wcreate({
            {"parent", "_winDebug.cntTopPages"},
            {"name", "_winDebug.optPage.Errors"},
            {"class", "option"},
            {"group", "_winDebug.optPage"},
            {"label", "Errors"},
            {"style", "button"},
            {"value", 1}
        })
        widget:wcreate({
            {"parent", "_winDebug.cntTopPages"},
            {"name", "_winDebug.optPage.Events"},
            {"class", "option"},
            {"group", "_winDebug.optPage"},
            {"label", "Events"},
            {"style", "button"},
            {"value", 0}
        })
        widget:wcreate({
            {"parent", "_winDebug.cntTopPages"},
            {"name", "_winDebug.optPage.Widgets"},
            {"class", "option"},
            {"group", "_winDebug.optPage"},
            {"label", "Widgets"},
            {"style", "button"},
            {"value", 0}
        })
        widget:wcreate({
            {"parent", "_winDebug.cntTopPages"},
            {"name", "_winDebug.optPage.Debug"},
            {"class", "option"},
            {"group", "_winDebug.optPage"},
            {"label", "Debug"},
            {"style", "button"},
            {"value", 0}
        })
        widget:wcreate({
            {"parent", "_winDebug.cntTopPages"},
            {"name", "_winDebug.optPage.Sysinfo"},
            {"class", "option"},
            {"group", "_winDebug.optPage"},
            {"label", "Sys info"},
            {"style", "button"},
            {"value", 0}
        })
        widget:wcreate({
            {"parent", "_winDebug.cntTop"},
            {"name", "_winDebug.cntTopRight"},
            {"class", "container"},
            {"orientation", "horizontal"},
            {"sizemode_x", "expand"},
            {"sizemode_y", "normal"}
        })
        widget:wcreate({
            {"parent", "_winDebug.cntMain"},
            {"name", "_winDebug.cntBottom"},
            {"class", "container"},
            {"orientation", "horizontal"},
            {"sizemode_x", "expand"},
            {"sizemode_y", "expand"}
        })
        
        debug_event("_winDebug.optPage.Errors", "selected", 1)
    end if
end procedure


export function dubug_initialize()
    widget:set_debug_event_handler(routine_id("debug_event"))
    return routine_id("debug_event")
end function

