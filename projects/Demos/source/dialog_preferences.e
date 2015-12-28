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


without warning

include gui/gui.e as gui
include std/task.e
include std/text.e
include std/pretty.e


export procedure gui_event(object evwidget, object evtype, object evdata)

    switch evwidget do
         case "Preferences.btnOk" then
            gui:wdestroy("Preferences")
            
         case "Preferences.btnCancel" then
            gui:wdestroy("Preferences")
            
         case "Preferences.btnApply" then
            gui:wdestroy("Preferences")
            
    end switch
end procedure


constant wn = "Preferences"

export procedure show()
    if gui:wexists(wn) then
        return
    end if
    
    gui:wcreate({
        {"name", wn},
        {"class", "window"},
        {"mode", "dialog"},
        {"handler", routine_id("gui_event")},
        {"title", "Preferences"},
        {"modal", 1},
        {"topmost", 1} 
        --{"position", {350, 350}}
        --{"visible", 0}
    })
    gui:wcreate({
        {"name", wn & ".cntMain"},
        {"parent", wn},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", wn & ".cntTop"},
        {"parent", wn & ".cntMain"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"},
        {"size", {250, 0}}
    })
    
 
    for t = 1 to 6 do
        gui:wcreate({
            {"name",  wn & ".txtSomething" & sprint(t)},
            {"parent",  wn & ".cntTop"},
            {"class", "textbox"},
            {"label", "Textbox " & sprint(t)},
            {"text", "nothing " & sprint(t)}
        })
    end for
    
    for t = 1 to 4 do
        gui:wcreate({
            {"name",  wn & ".chkSomething" & sprint(t)},
            {"parent",  wn & ".cntTop"},
            {"class", "toggle"},
            {"label", "Toggle " & sprint(t)},
            {"value", 1}
        })
    end for
    
    for t = 1 to 4 do    
        gui:wcreate({
            {"name", wn & ".optSomething" & sprint(t)},
            {"parent", wn & ".cntTop"},
            {"class", "option"},
            {"label", "Option " & sprint(t)},
            {"group",  wn & ".optSomething1"},
            {"style", "button"}
        })
    end for
    
    gui:wproc(wn & ".optSomething2", "set_group_value", {})
    
    
    gui:wcreate({
        {"name",  wn & ".div1"},
        {"parent",  wn & ".cntTop"},
        {"class", "divider"}
    })
       
    

    gui:wcreate({
        {"name", wn & ".cntBottom"},
        {"parent", wn & ".cntMain"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "equal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"}
    })
    
    gui:wcreate({
        {"name",  wn & ".btnOk"},
        {"parent",  wn & ".cntBottom"},
        {"class", "button"},
        {"label", "OK"}
    })
    
    gui:wcreate({
        {"name", wn & ".btnCancel"},
        {"parent",  wn & ".cntBottom"},
        {"class", "button"},
        {"label", "Cancel"}
    })
    
    gui:wcreate({
        {"name", wn & ".btnApply"},
        {"parent",  wn & ".cntBottom"},
        {"class", "button"},
        {"label", "Apply"}
    })
    
    gui:wenable(wn & ".btnOk", 0)
    gui:wenable(wn & ".btnApply", 0)
    
end procedure



