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

include std/task.e
include std/text.e
include std/pretty.e
include std/filesys.e
         

action:define({
    {"name", "find"},
    {"do_proc", routine_id("do_show_find")},
    {"label", "Find..."},
    {"icon", "edit-find"},
    {"hotkey", "Ctrl+F"},
    {"description", "Find"},
    {"enabled", 0}
})

action:define({
    {"name", "find_next"},
    {"do_proc", routine_id("do_find_next")},
    {"label", "Find Next"},
    {"icon", "edit-find"},
    {"hotkey", "F3"},
    {"description", "Find"},
    {"enabled", 0}
})

action:define({
    {"name", "find_prev"},
    {"do_proc", routine_id("do_find_prev")},
    {"label", "Find Previous"},
    {"icon", "edit-find"},
    {"hotkey", "Shift+F3"},
    {"description", "Find"},
    {"enabled", 0}
})

action:define({
    {"name", "find_replace"},
    {"do_proc", routine_id("do_show_find_replace")},
    {"undo_proc", routine_id("undo_find_replace")},
    {"label", "Find and Replace..."},
    {"icon", "edit-find-replace"},
    {"hotkey", "Ctrl+H"},
    {"description", "find_replace"},
    {"enabled", 0}
})



export procedure gui_event(object evwidget, object evtype, object evdata)
    switch evwidget do

        case "winFind.btnOk" then
            gui:wdestroy("winFind")
            
        case "winFind.btnCancel" then
            gui:wdestroy("winFind")
            
        case "winFind" then
            if equal(evtype, "closed") then
                gui:wdestroy("winFind")
            end if
        
        case "winFindReplace.btnOk" then
            gui:wdestroy("winFindReplace")
            
        case "winFindReplace.btnCancel" then
            gui:wdestroy("winFindReplace")
            
        case "winFindReplace" then
            if equal(evtype, "closed") then
                gui:wdestroy("winFindReplace")
            end if
        
    end switch
end procedure


procedure do_show_find()
    if gui:wexists("winFind") then
         gui:wdestroy("winFind")
    end if
    
    gui:wcreate({
        {"name", "winFind"},
        {"class", "window"},
        {"mode", "window"},
        {"handler", routine_id("gui_event")},
        {"title", "Find"},
        {"topmost", 1},
        {"size", {450, 250}}
    })
    gui:wcreate({
        {"name", "winFind.cntMain"},
        {"parent", "winFind"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    gui:wcreate({
        {"name", "winFind.cntTop"},
        {"parent", "winFind.cntMain"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    gui:wcreate({
        {"name",  "winFind.txtFind"},
        {"parent", "winFind.cntTop"},
        {"class", "textbox"},
        {"label", "Find:"},
        {"text", ""}
    })
    
    gui:wcreate({
        {"name",  "winFind.togCaseSensitive"},
        {"parent", "winFind.cntTop"},
        {"class", "toggle"},
        {"label", "Case sensitive"},
        {"value", 1}
    })
    
    gui:wcreate({
        {"name", "winFind.cntBottom"},
        {"parent", "winFind.cntMain"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "equal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"},
        {"justify_y", "bottom"}
    })
    gui:wcreate({
        {"name", "winFind.btnOk"},
        {"parent", "winFind.cntBottom"},
        {"class", "button"},
        {"label", "OK"}
    })
    gui:wcreate({
        {"name", "winFind.btnCancel"},
        {"parent", "winFind.cntBottom"},
        {"class", "button"},
        {"label", "Cancel"}
    })
    
end procedure


procedure do_show_find_replace()
if gui:wexists("winFindReplace") then
         gui:wdestroy("winFindReplace")
    end if
    
    gui:wcreate({
        {"name", "winFindReplace"},
        {"class", "window"},
        {"mode", "window"},
        {"handler", routine_id("gui_event")},
        {"title", "Find and Replace"},
        {"topmost", 1},
        {"size", {350, 250}}
    })
    gui:wcreate({
        {"name", "winFindReplace.cntMain"},
        {"parent", "winFindReplace"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    gui:wcreate({
        {"name", "winFindReplace.cntTop"},
        {"parent", "winFindReplace.cntMain"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    gui:wcreate({
        {"name",  "winFindReplace.txtFind"},
        {"parent", "winFindReplace.cntTop"},
        {"class", "textbox"},
        {"label", "Find:"},
        {"text", ""}
    })
    
    gui:wcreate({
        {"name",  "winFindReplace.togCaseSensitive"},
        {"parent", "winFindReplace.cntTop"},
        {"class", "toggle"},
        {"label", "Case sensitive"},
        {"value", 1}
    })
    
    gui:wcreate({
        {"name", "winFindReplace.cntBottom"},
        {"parent", "winFindReplace.cntMain"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "equal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"}
    })
    gui:wcreate({
        {"name", "winFindReplace.btnOk"},
        {"parent", "winFindReplace.cntBottom"},
        {"class", "button"},
        {"label", "OK"}
    })
    gui:wcreate({
        {"name", "winFindReplace.btnCancel"},
        {"parent", "winFindReplace.cntBottom"},
        {"class", "button"},
        {"label", "Cancel"}
    })
    
end procedure

