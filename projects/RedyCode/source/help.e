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


include redylib_0_9/app.e as app
include redylib_0_9/gui.e as gui
include redylib_0_9/actions.e as action

include redylib_0_9/gui/objects/textdoc.e as txtdoc
include redylib_0_9/gui/dialogs/dialog_file.e as dlgfile
include redylib_0_9/gui/dialogs/msgbox.e as msgbox
include redylib_0_9/msg.e as msg
include redylib_0_9/config.e as cfg

include std/task.e
include std/text.e
include std/utils.e
include std/sequence.e
include std/filesys.e
--include std/pretty.e
--include std/console.e


action:define({
    {"name", "show_help"},
    {"do_proc", routine_id("do_show_help")},
    {"label", "Help..."},
    {"icon", "help-browser"},
    {"hotkey", "F1"},
    {"description", "Show Help dialog"}
})

action:define({
    {"name", "help_navigate"},
    {"do_proc", routine_id("do_help_navigate")}
})


procedure gui_event(object evwidget, object evtype, object evdata)
    switch evwidget do
        case "winHelp" then
            /*if equal(evtype, "closed") then
                sequence winpos = gui:get_window_pos(widget_get_handle("winHelp"))
                sequence winsize = gui:get_window_size(widget_get_handle("winHelp"))
                cfg:set_var("", "GUI", "winHelp.left", winpos[1])
                cfg:set_var("", "GUI", "winHelp.top", winpos[2])
                cfg:set_var("", "GUI", "winHelp.width", winsize[1])
                cfg:set_var("", "GUI", "winHelp.height", winsize[2])
                cfg:save_config("")
                
                gui:wdestroy("winHelp")
            end if*/
            
        case "winHelp.btnBack" then
            action:do_proc("help_navigate", {"back"})
            
        case "winHelp.btnIndex" then
            action:do_proc("help_navigate", {"index"})
            
        case "winHelp.btnTOC" then
            action:do_proc("help_navigate", {"toc"})
            
        case "winHelp.btnRedyLib" then
            action:do_proc("help_navigate", {"RedyLib/Api"})
            
        case "winHelp.txtHelp" then
            if equal(evtype, "hyperlink") then
                action:do_proc("help_navigate", {evdata})
            end if
    end switch
end procedure

/*
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
*/

sequence UrlHistory = {}
sequence CurrFile = ""

procedure do_help_navigate(sequence helpurl)
    atom fn, ss
    object ln, txt
    sequence filename, sectionname = ""
    
    if equal(helpurl, "back") then
        if length(UrlHistory) > 1 then
            UrlHistory = UrlHistory[1..$-1]
        elsif length(UrlHistory) = 0 then
            return
        end if
        helpurl = UrlHistory[$]
    else
        if length(helpurl) = 0 then
            return
        end if
        if length(UrlHistory) = 0 or not equal(helpurl, UrlHistory[$]) then
            UrlHistory &= {helpurl}
        end if
    end if
    
    ss = find('#', helpurl)
    if ss > 0 then
        sectionname = helpurl[ss+1..$]
    end if
    if ss = 0 then
        ss = length(helpurl)
    else
        ss -= 1
    end if
    filename = ExePath & "\\docs\\" & helpurl[1..ss] & ".htd"
    
    if not equal(filename, CurrFile) then --load a different help file
        txt = ""
        
        fn = open(filename, "r")
        if fn = -1 then -- open file error
            txt = "===Page not found\nSorry, the file \"" & filename & "\" does not exist.\n"
        else
            while 1 do
                ln = gets(fn)
                if sequence(ln) then
                    --ln = remove_all(10, ln)
                    --ln = remove_all(13, ln)
                    txt &= ln
                else
                    exit
                end if
            end while
            close(fn)
        end if
        
        txtdoc:destroy("winHelp.txtHelp")
        txtdoc:create({
            {"name", "winHelp.txtHelp"},
            {"text", txt},
            {"view_mode", 1},
            {"syntax_mode", "creole"},
            {"show_hidden", 0},
            {"locked", 1},
            {"autofocus", 1},
            {"handler", routine_id("gui_event")}
        })
        
        txtdoc:show("winHelp.txtHelp", "winHelp.cntHelp")
    end if
    
    if length(sectionname) > 0 or not equal(filename, CurrFile) then
        task_delay(0.3) --temp fix: Text doesn't get processed until after "find" is called, causing it to not find any sections because they don't exist yet!
        txtdoc:docmd("winHelp.txtHelp", "find", {"section", sectionname})
    end if
    CurrFile = filename
end procedure


procedure do_show_help()
    sequence scrsize = gui:screen_size()
    atom wleft, wtop, wwidth, wheight
    
    if gui:wexists("winHelp") then
        return
    end if
    
    gui:wcreate({
        {"name", "winHelp"},
        {"class", "window"},
        {"title", app:info("name") & " Help"},
        --{"position", {wleft, wtop}},
        --{"size", {400, 600}},
        --{"topmost", 1},
        {"remember", 1},
        {"handler", routine_id("gui_event")}
    })
    
    gui:wcreate({
        {"name", "winHelp.cntHelp"},
        {"parent", "winHelp"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    gui:wcreate({
        {"name", "winHelp.cntTop"},
        {"parent", "winHelp.cntHelp"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "normal"}
    })
    
    gui:wcreate({
        {"name", "winHelp.cntTopLeft"},
        {"parent", "winHelp.cntTop"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"},
        {"justify_x", "left"}
    })
    gui:wcreate({
        {"name", "winHelp.btnBack"},
        {"parent", "winHelp.cntTopLeft"},
        {"class", "button"},
        {"label", "Back"}
    })
    gui:wcreate({
        {"name", "winHelp.btnIndex"},
        {"parent", "winHelp.cntTopLeft"},
        {"class", "button"},
        {"label", "Index"},
        {"enabled", 0}
    })
    
    gui:wcreate({
        {"name", "winHelp.cntTopRight"},
        {"parent", "winHelp.cntTop"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"}
    })
    gui:wcreate({
        {"name", "winHelp.btnTOC"},
        {"parent", "winHelp.cntTopRight"},
        {"class", "button"},
        {"label", "TOC"}
    })
    
    action:do_proc("help_navigate", {"toc"})
end procedure 


--export procedure start()
--    msg:subscribe("help", "command", routine_id("msg_event"))
--end procedure




















