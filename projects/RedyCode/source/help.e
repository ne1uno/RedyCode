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

sequence TempText =
"Thank you for trying Redy" & 153 & " application environment!\n" &
"\n~~~~\n\n" &
"Redy is the first widget toolkit for the Euphoria programing language that " &
"is written in pure Euphoria code. The Redy widget system was designed from " &
"scratch and has a unique API that makes it very easy to build a professional " &
"quality graphical interface for your Euphoria programs.\n" &
"\n" &
"Welcome to the Demo Application. This program should give you a good idea of " &
"what Redy can do and how it might be useful for your next project.\n" &
"\n~~~~\n\n"


include gui/gui.e as gui
include gui/objects/textedit.e as txte
include gui/dialogs/dialog_file.e as dlgfile
include gui/dialogs/msgbox.e as msgbox
include app/msg.e as msg
include app/config.e as cfg

include std/task.e
include std/text.e
include std/pretty.e
include std/utils.e
include std/sequence.e
include std/filesys.e
    
    
procedure gui_event(object evwidget, object evtype, object evdata)
    switch evwidget do
        case "winHelp" then
            if equal(evtype, "closed") then
                sequence winpos = gui:get_window_pos(widget_get_handle("winHelp"))
                sequence winsize = gui:get_window_size(widget_get_handle("winHelp"))
                cfg:set_var(App_Name & ".cfg", "GUI", "winHelp.left", winpos[1])
                cfg:set_var(App_Name & ".cfg", "GUI", "winHelp.top", winpos[2])
                cfg:set_var(App_Name & ".cfg", "GUI", "winHelp.width", winsize[1])
                cfg:set_var(App_Name & ".cfg", "GUI", "winHelp.height", winsize[2])
                cfg:save_config(App_Name & ".cfg")
                
                gui:wdestroy("winHelp")
            end if
    end switch
end procedure


function msg_event(sequence subscribername, sequence topicname, sequence msgname, object msgdata)
    --gui:debug("msg_event", {"subscribername=" & subscribername, "topicname=" & topicname, "msgname=" & msgname, "msgdata=" & sprint(msgdata)})
    switch topicname do
        case "command" then
            if equal(msgname, "help") then
                show_help()
            end if
    end switch
    return 1
end function


procedure show_help()
    sequence scrsize = gui:screen_size()
    atom wleft, wtop, wwidth, wheight
    
    if gui:wexists("winHelp") then
        return
    end if
    wleft = cfg:get_var(App_Name & ".cfg", "GUI", "winHelp.left")
    wtop = cfg:get_var(App_Name & ".cfg", "GUI", "winHelp.top")
    wwidth = cfg:get_var(App_Name & ".cfg", "GUI", "winHelp.width")
    wheight = cfg:get_var(App_Name & ".cfg", "GUI", "winHelp.height")
    
    --TODO: Improve window size handling and remember when maximized
    if wwidth = 0 then
        wwidth = 1280
    end if
    if wheight = 0 then
        wheight = 768
    end if
    if wwidth < 0 then
        wwidth = scrsize[1]
    end if
    if wheight < 0 then
        wheight = scrsize[2]
    end if
    if wwidth > scrsize[1] then
        wwidth = scrsize[1]
    end if
    if wheight > scrsize[2] then
        wheight = scrsize[2]
    end if
    
    if wleft > scrsize[1] then
        wleft = scrsize[1] - wwidth
    end if
    if wtop > scrsize[2] then
        wtop = scrsize[2] - wtop
    end if
    if wleft > scrsize[1] then
        wleft = 0
    end if
    if wtop > scrsize[2] then
        wtop = 0
    end if
    if wleft < 0 then
        wleft = 0
    end if
    if wtop < 0 then
        wtop = 0
    end if
    
    gui:wcreate({
        {"name", "winHelp"},
        {"class", "window"},
        {"title", App_Name & " Help"},
        {"position", {wleft, wtop}},
        {"size", {wwidth, wheight}},
        {"visible", 1},
        {"topmost", 1},
        {"allow_close", 0},
        {"handler", routine_id("gui_event")}
    })
    
    gui:wcreate({
        {"name", "cntHelp"},
        {"parent", "winHelp"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    gui:wcreate({
        {"name", "txtHelp"},
        {"parent", "cntHelp"},
        {"class", "textbox"},
        {"text", TempText}
    })
end procedure 


export procedure start()
    msg:subscribe("help", "command", routine_id("msg_event"))
end procedure


