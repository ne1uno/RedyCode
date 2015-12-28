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


without warning

include gui/gui.e as gui
include app/msg.e as msg
include app/config.e as cfg

include std/task.e
include std/text.e
include std/pretty.e

/*
Editor font, size
highlight colors

*/


procedure save_prefs()
--gui:wfunc(txtboxname, "get_text", {})

    cfg:set_var(App_Name & ".cfg", "Section1", "Something1", gui:wfunc("winPreferences.txtSomething1", "get_text", {}))
    cfg:set_var(App_Name & ".cfg", "Section1", "Something2", gui:wfunc("winPreferences.txtSomething2", "get_text", {}))
    cfg:set_var(App_Name & ".cfg", "Section1", "Something3", gui:wfunc("winPreferences.txtSomething3", "get_text", {}))
    cfg:set_var(App_Name & ".cfg", "Section2", "Something4", gui:wfunc("winPreferences.chkSomething4", "get_value", {}))
    cfg:set_var(App_Name & ".cfg", "Section2", "Something5", gui:wfunc("winPreferences.chkSomething5", "get_value", {}))
    cfg:set_var(App_Name & ".cfg", "Section2", "Something6", gui:wfunc("winPreferences.chkSomething6", "get_value", {}))
    
    cfg:save_config(App_Name & ".cfg")
end procedure


export procedure gui_event(object evwidget, object evtype, object evdata)

    switch evwidget do
         case "winPreferences.btnOk" then
            save_prefs()
            gui:wdestroy("winPreferences")
            
         case "winPreferences.btnCancel" then
            gui:wdestroy("winPreferences")
            
         case "winPreferences.btnApply" then
            save_prefs()
            --gui:wenable("winPreferences.btnOk", 0)
            --gui:wenable("winPreferences.btnApply", 0)
            
         case "winPreferences" then
            if equal(evtype, "closed") then
                gui:wdestroy("winPreferences")
            end if
            
    end switch
end procedure


function msg_event(sequence subscribername, sequence topicname, sequence msgname, object msgdata)
    switch topicname do
        case "command" then
            if equal(msgname, "preferences") then
                show()
            end if
    end switch
    
    return 1
end function


procedure show()
    object
    Something1 = cfg:get_var(App_Name & ".cfg", "Section1", "Something1"),
    Something2 = cfg:get_var(App_Name & ".cfg", "Section1", "Something2"),
    Something3 = cfg:get_var(App_Name & ".cfg", "Section1", "Something3"),
    Something4 = cfg:get_var(App_Name & ".cfg", "Section2", "Something4"),
    Something5 = cfg:get_var(App_Name & ".cfg", "Section2", "Something5"),
    Something6 = cfg:get_var(App_Name & ".cfg", "Section2", "Something6")
    
    if not sequence(Something1) then
        Something1 = ""
    end if
    if not sequence(Something2) then
        Something2 = ""
    end if
    if not sequence(Something3) then
        Something3 = ""
    end if
    if not atom(Something4) then
        Something4 = 0
    end if
    if not atom(Something5) then
        Something5 = 0
    end if
    if not atom(Something6) then
        Something6 = 0
    end if
    
    if gui:wexists("winPreferences") then
         gui:wdestroy("winPreferences")
    end if
    
    gui:wcreate({
        {"name", "winPreferences"},
        {"class", "window"},
        {"mode", "dialog"},
        {"handler", routine_id("gui_event")},
        {"title", "Preferences"},
        --{"modal", 1},
        {"topmost", 1} 
        --{"position", {350, 350}}
        --{"visible", 0}
    })
    gui:wcreate({
        {"name", "winPreferences.cntMain"},
        {"parent", "winPreferences"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", "winPreferences.cntTop"},
        {"parent", "winPreferences.cntMain"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"},
        {"size", {300, 0}}
    })
    
    --data entry:
    gui:wcreate({
        {"name",  "winPreferences.txtSomething1"},
        {"parent",  "winPreferences.cntTop"},
        {"class", "textbox"},
        {"label", "Something 1"},
        {"text", Something1}
    })
    gui:wcreate({
        {"name",  "winPreferences.txtSomething2"},
        {"parent",  "winPreferences.cntTop"},
        {"class", "textbox"},
        {"label", "Something 2"},
        {"text", Something2}
    })
    gui:wcreate({
        {"name",  "winPreferences.txtSomething3"},
        {"parent",  "winPreferences.cntTop"},
        {"class", "textbox"},
        {"label", "Something 3"},
        {"text", Something3}
    })
    
    gui:wcreate({
        {"name",  "winPreferences.chkSomething4"},
        {"parent",  "winPreferences.cntTop"},
        {"class", "toggle"},
        {"label", "Something 4"},
        {"value", Something4}
    })
    gui:wcreate({
        {"name",  "winPreferences.chkSomething5"},
        {"parent",  "winPreferences.cntTop"},
        {"class", "toggle"},
        {"label", "Something 5"},
        {"value", Something5}
    })
    gui:wcreate({
        {"name",  "winPreferences.chkSomething6"},
        {"parent",  "winPreferences.cntTop"},
        {"class", "toggle"},
        {"label", "Something 6"},
        {"value", Something6}
    })
    
    gui:wcreate({
        {"name", "winPreferences.cntBottom"},
        {"parent", "winPreferences.cntMain"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "equal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"}
    })
    
    gui:wcreate({
        {"name",  "winPreferences.btnOk"},
        {"parent",  "winPreferences.cntBottom"},
        {"class", "button"},
        {"label", "OK"}
    })
    
    gui:wcreate({
        {"name", "winPreferences.btnCancel"},
        {"parent",  "winPreferences.cntBottom"},
        {"class", "button"},
        {"label", "Cancel"}
    })
    
    gui:wcreate({
        {"name", "winPreferences.btnApply"},
        {"parent",  "winPreferences.cntBottom"},
        {"class", "button"},
        {"label", "Apply"}
    })
    
    /*gui:wenable("winPreferences.btnOk", 0)
    gui:wenable("winPreferences.btnApply", 0)*/
end procedure


export procedure start()
    msg:subscribe("preferences", "command", routine_id("msg_event"))
end procedure

