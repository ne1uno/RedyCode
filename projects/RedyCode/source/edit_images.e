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

atom ImagesTabWid = 0

export procedure load_img(sequence fpathname, atom readonly = 0)
    if ImagesTabWid > 0 then --file is already open, so switch to it's tab instead
        select_tab(ImagesTabWid)
        return
    end if
    
    atom tabid = tabs:create("Images")
    sequence parname = gui:widget_get_name(tabid)
    sequence wname = sprint(tabid)
    ImagesTabWid = tabid
    
    --create file command buttons
    gui:wcreate({
        {"name", "cntImages" & wname},
        {"parent", parname},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"},
        {"handler", routine_id("gui_event")}
    })
    gui:wcreate({
        {"name", "cntCommands" & wname},
        {"parent", "cntImages" & wname},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "normal"}
    })
    gui:wcreate({
        {"name", "cntCommandsLeft" & wname},
        {"parent", "cntCommands" & wname},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"},
        {"justify_x", "left"}
    })
    gui:wcreate({
        {"name", "cntCommandsRight" & wname},
        {"parent", "cntCommands" & wname},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"}
    })
    gui:wcreate({
        {"name", "btnClose" & wname},
        {"parent", "cntCommandsRight" & wname},
        {"class", "button"},
        {"label", "Close"}
    })
    
    gui:wcreate({
        {"name", "txtImages" & wname},
        {"parent", "cntImages" & wname},
        {"class", "textbox"},
        {"mode", "text"},
        {"label", "Images Editor"},
        {"text", "Sorry, images are not supported yet."}
    })
end procedure


export procedure hide()
    if ImagesTabWid > 0 then
        tabs:destroy_tab(ImagesTabWid)
        ImagesTabWid = 0
    end if
end procedure


export function is_any_modified()
    atom modified = 0
    /*for f = 1 to length(srcfiles[fModified]) do
        if srcfiles[fModified][f] then
            modified = 1
            exit
        end if
    end for*/
    return modified
end function


export function tab_file(atom tabwid)
    sequence fname = ""
    atom saveenabled = 0
    --atom fidx = find(tabwid, srcfiles[fTabWid])
    --if fidx > 0 then
    --    fname = srcfiles[fFilePathName][fidx]
    --    saveenabled = srcfiles[fModified][fidx]
    --end if
    
    return {fname, saveenabled}
end function


-----------------------------------


procedure gui_event(object evwidget, object evtype, object evdata)
    sequence wname = sprint(ImagesTabWid)
    
    if equal(evwidget, "btnClose" & wname) then
        hide()
    end if
end procedure

