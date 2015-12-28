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

include tablist.e as tabs --tab manager

include std/task.e
include std/text.e
include std/pretty.e
include std/sequence.e
include std/filesys.e
include std/error.e
include std/datetime.e as dt
include std/filesys.e
include std/utils.e

atom BuildTabWid = 0

export procedure show()
    if BuildTabWid > 0 then --file is already open, so switch to it's tab instead
        select_tab(BuildTabWid)
        return
    end if
    
    atom tabid = tabs:create("Build")
    sequence parname = gui:widget_get_name(tabid) 
    sequence wname = sprint(tabid)
    BuildTabWid = tabid
    
    --create file command buttons
    gui:wcreate({
        {"name", "cntBuild" & wname},
        {"parent", parname},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"},
        {"handler", routine_id("gui_event")}
    })
    gui:wcreate({
        {"name", "cntCommands" & wname},
        {"parent", "cntBuild" & wname},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"}
    })
    gui:wcreate({
        {"name", "btnClose" & wname},
        {"parent", "cntCommands" & wname},
        {"class", "button"},
        {"label", "Close"}
    })
    
    gui:wcreate({
        {"name", "txtBuild" & wname},
        {"parent", "cntBuild" & wname},
        {"class", "textbox"},
        {"mode", "text"},
        {"label", "Build Console"},
        {"text", "Sorry, this doesn't work yet."}
    })
end procedure


export procedure hide()
    if BuildTabWid > 0 then
        tabs:destroy_tab(BuildTabWid)
        BuildTabWid = 0
    end if
end procedure

-----------------------------------


procedure gui_event(object evwidget, object evtype, object evdata)
    sequence wname = sprint(BuildTabWid)
    
    if equal(evwidget, "btnClose" & wname) then
        hide()
    end if
end procedure

