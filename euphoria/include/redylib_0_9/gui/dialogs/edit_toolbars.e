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


without warning

include redylib_0_9/app.e as app
include redylib_0_9/gui.e as gui
include redylib_0_9/msg.e as msg
include redylib_0_9/config.e as cfg
include redylib_0_9/actions.e as action

include redylib_0_9/gui/dialogs/dialog_file.e as dlgfile

include std/task.e
include std/text.e
include std/pretty.e
include std/filesys.e
include std/sort.e as stdsort
include std/search.e
include std/sequence.e

object ProjectPath, EuiPath, EubindPath, IncludePath --, RedyLibPath


action:define({
    {"name", "show_edit_toolbars"},
    {"do_proc", routine_id("do_show_edit_toolbars")},
    {"label", "Customize Toolbars..."},
    {"icon", "preferences-system"},
    {"description", "Customize toolbar layout"}
})


sequence loadedTools = {}, tbNames = {}, selToolItems = {}, selActions = {}
atom selTbIdx = 0


procedure refresh_enabled_widgets()
    if length(tbNames) > 0 then
        gui:wenable("winEditToolbars.txtToolbarName")
        gui:wenable("winEditToolbars.optToolbarPosTop")
        gui:wenable("winEditToolbars.optToolbarPosLeft")
        gui:wenable("winEditToolbars.optToolbarPosBottom")
        gui:wenable("winEditToolbars.optToolbarPosRight")
        gui:wenable("winEditToolbars.optToolbarPosHidden")
        gui:wenable("winEditToolbars.btnToolbarDelete")
        gui:wenable("winEditToolbars.btnToolbarDuplicate")
        gui:wenable("winEditToolbars.lstTools")
        gui:wenable("winEditToolbars.lstActions")
        if length(selToolItems) > 0 then
            gui:wenable("winEditToolbars.btnToolMoveUp")
            gui:wenable("winEditToolbars.btnToolMoveDown")
            gui:wenable("winEditToolbars.btnActionsRemove")
        else
            gui:wdisable("winEditToolbars.btnToolMoveUp")
            gui:wdisable("winEditToolbars.btnToolMoveDown")
            gui:wdisable("winEditToolbars.btnActionsRemove")
        end if
        if length(selActions) > 0 then
            gui:wenable("winEditToolbars.btnActionsAdd")
        else
            gui:wdisable("winEditToolbars.btnActionsAdd")
        end if
    else
        gui:wdisable("winEditToolbars.txtToolbarName")
        gui:wdisable("winEditToolbars.optToolbarPosTop")
        gui:wdisable("winEditToolbars.optToolbarPosLeft")
        gui:wdisable("winEditToolbars.optToolbarPosBottom")
        gui:wdisable("winEditToolbars.optToolbarPosRight")
        gui:wdisable("winEditToolbars.optToolbarPosHidden")
        gui:wdisable("winEditToolbars.btnToolbarDelete")
        gui:wdisable("winEditToolbars.btnToolbarDuplicate")
        gui:wdisable("winEditToolbars.lstTools")
        gui:wdisable("winEditToolbars.btnToolMoveUp")
        gui:wdisable("winEditToolbars.btnToolMoveDown")
        gui:wdisable("winEditToolbars.btnActionsRemove")
        gui:wdisable("winEditToolbars.lstActions")
        gui:wdisable("winEditToolbars.btnActionsAdd")
    end if
end procedure


procedure load_toolbar_data(sequence tools)
    sequence
    toolbarItems = {},
    actions = action:names(),
    actionItems = {}
    object aicon, atype, alabel
    
    loadedTools = tools
    
    tbNames = {}
    for i = 1 to length(tools) do
        tbNames &= {tools[i][1]}
        toolbarItems &= {{rgb(255, 255, 255), tools[i][2], tools[i][1]}}
    end for
    
    for i = 1 to length(actions) do
        aicon = get_icon(actions[i])
        atype = get_type(actions[i])
        alabel = get_label(actions[i])
        if sequence(alabel) and length(alabel) > 0 and sequence(aicon) and length(aicon) > 0 then
            actionItems &= {{aicon, atype, alabel, actions[i]}}
        end if
    end for
    
    actionItems = stdsort:sort_columns(actionItems, {3})
    actionItems = {
        {rgb(255, 255, 255), "separator", "----------", "-"}
    } & actionItems
    
    
    gui:wproc("winEditToolbars.lstToolbars", "clear_list", {})
    gui:wproc("winEditToolbars.lstToolbars", "add_list_items", {toolbarItems})
    
    gui:wproc("winEditToolbars.lstTools", "clear_list", {})
    
    gui:wproc("winEditToolbars.lstActions", "clear_list", {})
    gui:wproc("winEditToolbars.lstActions", "add_list_items", {actionItems})
    
    gui:wproc("winEditToolbars.lstToolbars", "select_items", {{1}})
    gui:wproc("winEditToolbars.lstActions", "select_items", {{1}})
    
    refresh_enabled_widgets()
end procedure


export procedure gui_event(object evwidget, object evtype, object evdata)
    switch evwidget do
    case "winEditToolbars.lstToolbars" then
        if equal(evtype, "selection") then
            if length(evdata) > 0 then
                sequence tools = {}, toolItems = {}
                object aicon, atype, alabel
                
                selTbIdx = evdata[1][1]
                tools = loadedTools[selTbIdx] --tools={"toolbarname", dockposition, {action_list}}
                for a = 1 to length(tools[3]) do
                    atype = get_type(tools[3][a])
                    if atom(atype) then
                        if equal("-", tools[3][a]) then
                            toolItems &= {{rgb(255, 255, 255), "separator", "----------", "-"}}
                        end if
                    else
                        aicon = get_icon(tools[3][a])
                        alabel = get_label(tools[3][a])
                        if sequence(alabel) and length(alabel) > 0 and sequence(aicon) and length(aicon) > 0 then
                            toolItems &= {{aicon, atype, alabel, tools[3][a]}}
                        end if
                    end if
                end for
                --toolItems &= {{rgb(255, 255, 255), "", "", ""}}
                
                gui:wproc("winEditToolbars.lstTools", "clear_list", {})
                gui:wproc("winEditToolbars.lstTools", "add_list_items", {toolItems})
                gui:wproc("winEditToolbars.lstTools", "select_items", {{1}})
                gui:wproc("winEditToolbars.txtToolbarName", "set_text", {tbNames[selTbIdx]})
                
                switch tools[2] do
                case "top" then
                    gui:wproc("winEditToolbars.optToolbarPosTop", "set_group_value", {})
                case "left" then
                    gui:wproc("winEditToolbars.optToolbarPosLeft", "set_group_value", {})
                case "bottom" then
                    gui:wproc("winEditToolbars.optToolbarPosBottom", "set_group_value", {})
                case "right" then
                    gui:wproc("winEditToolbars.optToolbarPosRight", "set_group_value", {})
                case else
                    gui:wproc("winEditToolbars.optToolbarPosHidden", "set_group_value", {})
                end switch
            end if
        end if
        
    case "winEditToolbars.lstTools" then
        if equal(evtype, "selection") then
            selToolItems = {}
            for i = 1 to length(evdata) do
                if length(evdata[i]) = 2 and length(evdata[i][2]) = 3 then
                    if evdata[i][1] <= length(loadedTools[selTbIdx][3]) then
                        selToolItems &= {evdata[i][1]}
                    end if
                end if
            end for
            if length(selToolItems) > 0 then
                gui:wenable("winEditToolbars.btnToolMoveUp")
                gui:wenable("winEditToolbars.btnToolMoveDown")
                gui:wenable("winEditToolbars.btnActionsRemove")
            else
                gui:wdisable("winEditToolbars.btnToolMoveUp")
                gui:wdisable("winEditToolbars.btnToolMoveDown")
                gui:wdisable("winEditToolbars.btnActionsRemove")
            end if
        end if
        
    case "winEditToolbars.lstActions" then
        if equal(evtype, "selection") then
            selActions = {}
            for i = 1 to length(evdata) do
                if length(evdata[i]) = 2 and length(evdata[i][2]) = 3 then
                    selActions &= {evdata[i][2][3]}
                end if
            end for
            if length(tbNames) > 0 and length(selActions) > 0 then
                gui:wenable("winEditToolbars.btnActionsAdd")
            else
                gui:wdisable("winEditToolbars.btnActionsAdd")
            end if
        end if
        
    case "winEditToolbars.txtToolbarName" then
        sequence txt = gui:wfunc("winEditToolbars.txtToolbarName", "get_text", {}),
        itms = {}, testname
        atom refresh = 0, trynum = 1
        
        if equal(evtype, "changed") then
            if selTbIdx > 0 and selTbIdx <= length(loadedTools) then
                tbNames[selTbIdx] = txt
                loadedTools[selTbIdx][1] = txt
                
                for i = 1 to length(loadedTools) do
                    itms &= {{rgb(255, 255, 255), loadedTools[i][2], loadedTools[i][1]}}
                end for
                gui:wproc("winEditToolbars.lstToolbars", "set_list_items", {itms})
            end if
            
        elsif equal(evtype, "LostFocus") or equal(evtype, "enter") then  
            if selTbIdx > 0 and selTbIdx <= length(loadedTools) then
                --prevent toolbar name from being an empty string
                if length(txt) = 0 then
                    txt = "Untitled"
                end if
                --prevent duplicate toolbar names
                testname = txt
                while length(find_all(testname, tbNames)) > 1 do
                    testname = txt & sprint(trynum)
                    trynum += 1
                end while 
                tbNames[selTbIdx] = testname
                loadedTools[selTbIdx][1] = testname
                gui:wproc("winEditToolbars.txtToolbarName", "set_text", {tbNames[selTbIdx]})
            end if
        end if
        
    case "winEditToolbars.optToolbarPosTop" then
        if equal(evtype, "selected") and selTbIdx > 0 and selTbIdx <= length(loadedTools) then
            sequence itms = {}
            loadedTools[selTbIdx][2] = "top"
            
            for i = 1 to length(loadedTools) do
                itms &= {{rgb(255, 255, 255), loadedTools[i][2], loadedTools[i][1]}}
            end for
            gui:wproc("winEditToolbars.lstToolbars", "set_list_items", {itms})
        end if
        
    case "winEditToolbars.optToolbarPosLeft" then
        if equal(evtype, "selected") and selTbIdx > 0 and selTbIdx <= length(loadedTools) then
            sequence itms = {}
            loadedTools[selTbIdx][2] = "left"
            
            for i = 1 to length(loadedTools) do
                itms &= {{rgb(255, 255, 255), loadedTools[i][2], loadedTools[i][1]}}
            end for
            gui:wproc("winEditToolbars.lstToolbars", "set_list_items", {itms})
        end if
        
    case "winEditToolbars.optToolbarPosBottom" then
        if equal(evtype, "selected") and selTbIdx > 0 and selTbIdx <= length(loadedTools) then
            sequence itms = {}
            loadedTools[selTbIdx][2] = "bottom"
            
            for i = 1 to length(loadedTools) do
                itms &= {{rgb(255, 255, 255), loadedTools[i][2], loadedTools[i][1]}}
            end for
            gui:wproc("winEditToolbars.lstToolbars", "set_list_items", {itms})
        end if
        
    case "winEditToolbars.optToolbarPosRight" then
        if equal(evtype, "selected") and selTbIdx > 0 and selTbIdx <= length(loadedTools) then
            sequence itms = {}
            loadedTools[selTbIdx][2] = "right"
            
            for i = 1 to length(loadedTools) do
                itms &= {{rgb(255, 255, 255), loadedTools[i][2], loadedTools[i][1]}}
            end for
            gui:wproc("winEditToolbars.lstToolbars", "set_list_items", {itms})
        end if
        
    case "winEditToolbars.optToolbarPosHidden" then
        if equal(evtype, "selected") and selTbIdx > 0 and selTbIdx <= length(loadedTools) then
            sequence itms = {}
            loadedTools[selTbIdx][2] = "hidden"
            
            for i = 1 to length(loadedTools) do
                itms &= {{rgb(255, 255, 255), loadedTools[i][2], loadedTools[i][1]}}
            end for
            gui:wproc("winEditToolbars.lstToolbars", "set_list_items", {itms})
        end if
        
    case "winEditToolbars.btnToolbarCreate" then
        if equal(evtype, "clicked") then
            sequence tools = loadedTools, txt = "Untitled", testname
            atom trynum = 1
            
            --prevent duplicate toolbar names
            testname = txt
            while length(find_all(testname, tbNames)) > 0 do
                testname = txt & sprint(trynum)
                trynum += 1
            end while 
            tools &= {{testname, "top", {}}}
            selTbIdx = length(tools)
            load_toolbar_data(tools)
            gui:wproc("winEditToolbars.lstToolbars", "select_items", {{selTbIdx}})
        end if
        
    case "winEditToolbars.btnToolbarDelete" then
        if equal(evtype, "clicked") then
            load_toolbar_data(remove(loadedTools, selTbIdx))
            if selTbIdx > length(loadedTools) then
                selTbIdx = length(loadedTools)
            end if
            gui:wproc("winEditToolbars.lstToolbars", "select_items", {{selTbIdx}})
            refresh_enabled_widgets()
        end if
        
    case "winEditToolbars.btnToolbarDuplicate" then
        if equal(evtype, "clicked") then
            if selTbIdx > 0 and selTbIdx <= length(loadedTools) then
                sequence tools = loadedTools, txt = loadedTools[selTbIdx][1], testname
                atom trynum = 1
                
                tools &= {loadedTools[selTbIdx]}
                --prevent toolbar name from being an empty string
                if length(txt) = 0 then
                    txt = "Untitled"
                end if
                --prevent duplicate toolbar names
                testname = txt
                while length(find_all(testname, tbNames)) > 0 do
                    testname = txt & sprint(trynum)
                    trynum += 1
                end while
                tools[$][1] = testname
                selTbIdx = length(tools)
                load_toolbar_data(tools)
                gui:wproc("winEditToolbars.lstToolbars", "select_items", {{selTbIdx}})
            end if
        end if
        
    case "winEditToolbars.btnToolMoveUp" then
        /*if equal(evtype, "clicked") and selTbIdx > 0 and selTbIdx <= length(loadedTools) and length(selToolItems) = 0 then
            sequence tools = {}, toolItems = {}
            object aicon, atype, alabel
            
            
            loadedTools[selTbIdx][3] = loadedTools[selTbIdx][3][1..selToolItems[1]-1] & loadedTools[selTbIdx][3][selToolItems[$]+1..$]
            
            loadedTools[selTbIdx][3] = loadedTools[selTbIdx][3][1..selToolItems[1]-1] & loadedTools[selTbIdx][3][selToolItems[$]+1..$]
            
            
            
            selToolItems = {selToolItems[1]}
            if selToolItems[1] > length(loadedTools[selTbIdx][3]) then
                selToolItems[1] = length(loadedTools[selTbIdx][3])
            end if
            
            tools = loadedTools[selTbIdx] --tools={"toolbarname", dockposition, {action_list}}
            for a = 1 to length(tools[3]) do
                atype = get_type(tools[3][a])
                if atom(atype) then
                    if equal("-", tools[3][a]) then
                        toolItems &= {{rgb(255, 255, 255), "separator", "----------", "-"}}
                    end if
                else
                    aicon = get_icon(tools[3][a])
                    alabel = get_label(tools[3][a])
                    if sequence(alabel) and length(alabel) > 0 and sequence(aicon) and length(aicon) > 0 then
                        toolItems &= {{aicon, atype, alabel, tools[3][a]}}
                    end if
                end if
            end for
            
            gui:wproc("winEditToolbars.lstTools", "clear_list", {})
            gui:wproc("winEditToolbars.lstTools", "add_list_items", {toolItems})
            gui:wproc("winEditToolbars.lstTools", "select_items", {selToolItems})
        end if*/
        
    case "winEditToolbars.btnToolMoveDown" then
        if equal(evtype, "clicked") then
        end if
        
    case "winEditToolbars.btnActionsRemove" then
        if equal(evtype, "clicked") and selTbIdx > 0 and selTbIdx <= length(loadedTools) and length(selToolItems) > 0 then
            sequence tools = {}, toolItems = {}
            object aicon, atype, alabel
            
            loadedTools[selTbIdx][3] = loadedTools[selTbIdx][3][1..selToolItems[1]-1] & loadedTools[selTbIdx][3][selToolItems[$]+1..$]
            selToolItems = {selToolItems[1]}
            if selToolItems[1] > length(loadedTools[selTbIdx][3]) then
                selToolItems[1] = length(loadedTools[selTbIdx][3])
            end if
            
            tools = loadedTools[selTbIdx] --tools={"toolbarname", dockposition, {action_list}}
            for a = 1 to length(tools[3]) do
                atype = get_type(tools[3][a])
                if atom(atype) then
                    if equal("-", tools[3][a]) then
                        toolItems &= {{rgb(255, 255, 255), "separator", "----------", "-"}}
                    end if
                else
                    aicon = get_icon(tools[3][a])
                    alabel = get_label(tools[3][a])
                    if sequence(alabel) and length(alabel) > 0 and sequence(aicon) and length(aicon) > 0 then
                        toolItems &= {{aicon, atype, alabel, tools[3][a]}}
                    end if
                end if
            end for
            --toolItems &= {{rgb(255, 255, 255), "", "", ""}}
            
            gui:wproc("winEditToolbars.lstTools", "clear_list", {})
            gui:wproc("winEditToolbars.lstTools", "add_list_items", {toolItems})
            gui:wproc("winEditToolbars.lstTools", "select_items", {selToolItems})
        end if
        
    case "winEditToolbars.btnActionsAdd" then
        if equal(evtype, "clicked") and selTbIdx > 0 and selTbIdx <= length(loadedTools) then
            sequence tools = {}, toolItems = {}
            object aicon, atype, alabel
            
            if length(selToolItems) = 0 then
                selToolItems = {1}
            end if
            loadedTools[selTbIdx][3] = loadedTools[selTbIdx][3][1..selToolItems[1]-1] & selActions & loadedTools[selTbIdx][3][selToolItems[1]..$]
            selToolItems = series(selToolItems[1], 1, length(selActions))
            
            tools = loadedTools[selTbIdx] --tools={"toolbarname", dockposition, {action_list}}
            for a = 1 to length(tools[3]) do
                atype = get_type(tools[3][a])
                if atom(atype) then
                    if equal("-", tools[3][a]) then
                        toolItems &= {{rgb(255, 255, 255), "separator", "----------", "-"}}
                    end if
                else
                    aicon = get_icon(tools[3][a])
                    alabel = get_label(tools[3][a])
                    if sequence(alabel) and length(alabel) > 0 and sequence(aicon) and length(aicon) > 0 then
                        toolItems &= {{aicon, atype, alabel, tools[3][a]}}
                    end if
                end if
            end for
            selActions = {1}
            --toolItems &= {{rgb(255, 255, 255), "", "", ""}}
            
            gui:wproc("winEditToolbars.lstTools", "clear_list", {})
            gui:wproc("winEditToolbars.lstTools", "add_list_items", {toolItems})
            gui:wproc("winEditToolbars.lstTools", "select_items", {selToolItems})
            gui:wproc("winEditToolbars.lstActions", "select_items", {{1}})
        end if
        
    case "winEditToolbars.btnOk" then
        app:save_toolbars(loadedTools)
        app:reload_toolbars()
        gui:wdestroy("winEditToolbars")
        
    case "winEditToolbars.btnCancel" then
        gui:wdestroy("winEditToolbars")
        
    case "winEditToolbars.btnDefaults" then
        load_toolbar_data(app:get_default_toolbars())
        
    case "winEditToolbars" then
        if equal(evtype, "closed") then
            gui:wdestroy("winEditToolbars")
        end if
        
    end switch
end procedure


--procedure load_toolbars()
--    get_default_toolbars()
--end procedure

procedure do_show_edit_toolbars()
    if gui:wexists("winEditToolbars") then
         gui:wdestroy("winEditToolbars")
    end if
    
    gui:wcreate({
        {"name", "winEditToolbars"},
        {"class", "window"},
        {"mode", "window"},
        {"handler", routine_id("gui_event")},
        {"title", "Customize Toolbars"},
        {"topmost", 1},
        {"size", {750, 450}}
    })
    gui:wcreate({
        {"name", "winEditToolbars.cntMain"},
        {"parent", "winEditToolbars"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", "winEditToolbars.cntTop"},
        {"parent", "winEditToolbars.cntMain"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    --Toolbars
    gui:wcreate({
        {"name", "winEditToolbars.cntToolbars"},
        {"parent", "winEditToolbars.cntTop"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name",  "winEditToolbars.lstToolbars"},
        {"parent",  "winEditToolbars.cntToolbars"},
        {"class", "listbox"},
        {"label", "Toolbars"},
        {"multi_select", 0}
    })
    gui:wproc("winEditToolbars.lstToolbars", "add_column", {{"Location", 70, 0, 0}})
    gui:wproc("winEditToolbars.lstToolbars", "add_column", {{"Name", 200, 0, 0}})
    gui:wcreate({
        {"name", "winEditToolbars.txtToolbarName"},
        {"parent", "winEditToolbars.cntToolbars"},
        {"class", "textbox"},
        {"label", "Name"}
    })
    gui:wcreate({
        {"name", "winEditToolbars.cntToolbarsPos"},
        {"parent", "winEditToolbars.cntToolbars"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"},
        {"justify_x", "center"}
    })
    gui:wcreate({
        {"name", "winEditToolbars.optToolbarPosTop"},
        {"parent", "winEditToolbars.cntToolbarsPos"},
        {"class", "option"},
        {"group", "winEditToolbars.ToolbarPos"},
        {"style", "button"},
        {"label", "Top"},
        {"value", 1}
    })
    gui:wcreate({
        {"name", "winEditToolbars.optToolbarPosLeft"},
        {"parent", "winEditToolbars.cntToolbarsPos"},
        {"class", "option"},
        {"group", "winEditToolbars.ToolbarPos"},
        {"style", "button"},
        {"label", "Left"}
    })
    gui:wcreate({
        {"name", "winEditToolbars.optToolbarPosBottom"},
        {"parent", "winEditToolbars.cntToolbarsPos"},
        {"class", "option"},
        {"group", "winEditToolbars.ToolbarPos"},
        {"style", "button"},
        {"label", "Bottom"}
    })
    gui:wcreate({
        {"name", "winEditToolbars.optToolbarPosRight"},
        {"parent", "winEditToolbars.cntToolbarsPos"},
        {"class", "option"},
        {"group", "winEditToolbars.ToolbarPos"},
        {"style", "button"},
        {"label", "Right"}
    })
    gui:wcreate({
        {"name", "winEditToolbars.optToolbarPosHidden"},
        {"parent", "winEditToolbars.cntToolbarsPos"},
        {"class", "option"},
        {"group", "winEditToolbars.ToolbarPos"},
        {"style", "button"},
        {"label", "Hidden"}
    })
    gui:wcreate({
        {"name", "winEditToolbars.cntToolbarsCmds"},
        {"parent", "winEditToolbars.cntToolbars"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"},
        {"justify_x", "center"}
    })
    gui:wcreate({
        {"name", "winEditToolbars.btnToolbarCreate"},
        {"parent", "winEditToolbars.cntToolbarsCmds"},
        {"class", "button"},
        {"label", "Create"}
    })
    gui:wcreate({
        {"name", "winEditToolbars.btnToolbarDelete"},
        {"parent", "winEditToolbars.cntToolbarsCmds"},
        {"class", "button"},
        {"label", "Delete"}
    })
    gui:wcreate({
        {"name", "winEditToolbars.btnToolbarDuplicate"},
        {"parent", "winEditToolbars.cntToolbarsCmds"},
        {"class", "button"},
        {"label", "Duplicate"}
    })
    
    --Tools
    gui:wcreate({
        {"name", "winEditToolbars.cntTools"},
        {"parent", "winEditToolbars.cntTop"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name",  "winEditToolbars.lstTools"},
        {"parent",  "winEditToolbars.cntTools"},
        {"class", "listbox"},
        {"label", "Selected Tools"},
        {"multi_select", 1}
    })
    gui:wproc("winEditToolbars.lstTools", "add_column", {{"Type", 70, 0, 0}})
    gui:wproc("winEditToolbars.lstTools", "add_column", {{"Label", 200, 0, 0}})
    gui:wcreate({
        {"name", "winEditToolbars.cntToolsCmds"},
        {"parent", "winEditToolbars.cntTools"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"},
        {"justify_x", "center"}
    })
    /* --not implemented yet
    gui:wcreate({
        {"name", "winEditToolbars.btnToolMoveUp"},
        {"parent", "winEditToolbars.cntToolsCmds"},
        {"class", "button"},
        {"label", "Move Up"}
    })
    gui:wcreate({
        {"name", "winEditToolbars.btnToolMoveDown"},
        {"parent", "winEditToolbars.cntToolsCmds"},
        {"class", "button"},
        {"label", "Move Down"}
    })*/
    
    gui:wcreate({
        {"name", "winEditToolbars.btnActionsRemove"},
        {"parent", "winEditToolbars.cntToolsCmds"},
        {"class", "button"},
        {"label", ">> Remove"}
    })
    
    --Actions
    gui:wcreate({
        {"name", "winEditToolbars.cntActions"},
        {"parent", "winEditToolbars.cntTop"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name",  "winEditToolbars.lstActions"},
        {"parent",  "winEditToolbars.cntActions"},
        {"class", "listbox"},
        {"label", "Availible Actions"},
        {"multi_select", 1}
    })
    gui:wproc("winEditToolbars.lstActions", "add_column", {{"Type", 70, 0, 0}})
    gui:wproc("winEditToolbars.lstActions", "add_column", {{"Label", 200, 0, 0}})
    gui:wcreate({
        {"name", "winEditToolbars.cntActionsCmds"},
        {"parent", "winEditToolbars.cntActions"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"},
        {"justify_x", "center"}
    })
    gui:wcreate({
        {"name", "winEditToolbars.btnActionsAdd"},
        {"parent", "winEditToolbars.cntActionsCmds"},
        {"class", "button"},
        {"label", "<< Add"}
    })
    
    --Bottom
    gui:wcreate({
        {"name", "winEditToolbars.cntBottom"},
        {"parent", "winEditToolbars.cntMain"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "equal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"}
    })
    gui:wcreate({
        {"name", "winEditToolbars.btnDefaults"},
        {"parent", "winEditToolbars.cntBottom"},
        {"class", "button"},
        {"label", "Defaults"}
    })
    gui:wcreate({
        {"name", "winEditToolbars.btnOk"},
        {"parent", "winEditToolbars.cntBottom"},
        {"class", "button"},
        {"label", "OK"}
    })
    gui:wcreate({
        {"name", "winEditToolbars.btnCancel"},
        {"parent", "winEditToolbars.cntBottom"},
        {"class", "button"},
        {"label", "Cancel"}
    })
    
    load_toolbar_data(app:load_toolbars())
end procedure

