-- This file is part of RedyCode™ Integrated Development Environment
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


include gui/gui.e as gui
include gui/objects/textedit.e as txte
include gui/dialogs/dialog_file.e as dlgfile
include gui/dialogs/msgbox.e as msgbox
include app/msg.e as msg

include std/task.e
include std/text.e
include std/pretty.e
include std/sequence.e
include std/filesys.e
include std/error.e
include std/datetime.e as dt
include std/filesys.e
include std/utils.e


atom lastid = 0

function next_tabnum()
    lastid += 1
    return sprintf("%d", {lastid})
end function

export function create(sequence tablabel)
    sequence tabnum = next_tabnum()
    gui:wcreate({
        {"name", "tabEditor" & tabnum},
        {"parent", "tabEditor"},
        {"class", "container"},
        {"label", tablabel},
        --{"tab", 1},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    return gui:widget_get_id("tabEditor" & tabnum)
end function


export procedure destroy_tab(object tabnameorid)
     gui:wdestroy(tabnameorid)
end procedure


export procedure select_tab(object tabnameorid)
     gui:wproc("tabEditor", "select_tab_by_widget", {tabnameorid})
end procedure


-----------------------------------


procedure gui_event(object evwidget, object evtype, object evdata)
    switch evwidget do
        case "tabEditor" then
            if equal(evtype, "selection") then
                /*sequence wname = gui:widget_get_name(evdata)
                
                for t = 1 to length(tabs[tName]) do
                    if equal(wname, "tabEditor_" & tabs[tName][t]) then
                        CurrentTab = tabs[tName][t]
                        exit
                    end if
                end for*/
            end if
            
        case else
            /*if equal(evwidget, "btnClose_" & CurrentTab) then
                msg:publish("editor", "command", "close_file", CurrentTab)
            end if*/
            
    end switch
end procedure


function msg_event(sequence subscribername, sequence topicname, sequence msgname, object msgdata)
    return 1
end function


export procedure start()
    gui:wcreate({
        {"name", "cntMain"},
        {"parent", "winMain"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"},
        {"handler", routine_id("gui_event")}
    })
    
    gui:wcreate({
        {"name", "cntEditor"},
        {"parent", "cntMain"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    
    --tabs
    gui:wcreate({
        {"name", "tabEditor"},
        {"parent", "cntEditor"},
        {"class", "tabs"}
    })
    
    /*
    gui:wcreate({
        {"name", "panelNav"},
        {"parent", "winMain"},
        {"class", "panel"},
        {"label", "Navigation"},
        {"dock", "right"},
        {"handler", routine_id("gui_event")}
    })
    gui:wcreate({
        {"name", "cntNav"},
        {"parent", "panelNav"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", "lstNav"},
        {"parent", "cntNav"},
        {"class", "listbox"}
    })
    
    --temp example:
    gui:wproc("lstNav", "clear_list", {})
    gui:wproc("lstNav", "add_list_items", {{
        {rgb(127, 127, 127), "top"}
    }})
    
    gui:wcreate({
        {"name", "panelBuilder"},
        {"parent", "winMain"},
        {"class", "panel"},
        {"label", "Code Builder"},
        {"dock", "right"},
        {"handler", routine_id("gui_event")}
    })
    gui:wcreate({
        {"name", "cntBuilder"},
        {"parent", "panelBuilder"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    gui:wcreate({
        {"name", "txtBuilder"},
        {"parent", "cntBuilder"},
        {"class", "textbox"},
        {"mode", "text"},
        {"label", "Current Context:"},
        {"text", "top level"}
    })
    gui:wcreate({
        {"name", "lstBuilder"},
        {"parent", "cntBuilder"},
        {"class", "listbox"},
        {"label", "Create code:"}
    })
    
    --temp example:
    gui:wproc("lstBuilder", "clear_list", {})
    gui:wproc("lstBuilder", "add_list_items", {{
        {rgb(127, 127, 127), "include"},
        {rgb(127, 127, 127), "object"},
        {rgb(127, 127, 127), "sequence"},
        {rgb(127, 127, 127), "atom"},
        {rgb(127, 127, 127), "integer"},
        {rgb(127, 127, 127), "procedure"},
        {rgb(127, 127, 127), "function"}
    }})*/
    
    --create_tab("project", "Untitled", "project_untitled", "untitled", "untitled")
    
    msg:subscribe("editor", "command", routine_id("msg_event"))
end procedure

