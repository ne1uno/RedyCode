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

--Displays a nice gui error report window for redylib1_dev/err.e


include redylib_0_9/gui.e as gui
include redylib_0_9/err.e as err
include redylib_0_9/app.e as app

include std/task.e
include std/text.e
include std/pretty.e
include euphoria/info.e

atom enabled = 0


procedure gui_event(object evwidget, object evtype, object evdata)
    switch evwidget do
        case "winErrorReport" then
            if equal(evtype, "closed") then
                gui:wdestroy("winErrorReport")
                gui:wdestroy("winMain")
                abort(1)
            end if
            
        case "winErrorReport.btnQuit" then
            gui:wdestroy("winErrorReport")
            gui:wdestroy("winMain")
            abort(1)
            
        case "winErrorReport.btnResume" then
            gui:wdestroy("winErrorReport")
    end switch
end procedure


procedure warn_proc(sequence errdata, sequence errnicetxt)
    show_error_report(errdata)
end procedure


procedure die_proc(sequence errdata, sequence errnicetxt)
    show_error_report(errdata)

end procedure      

        
procedure show_error_report(sequence errdata)
    --errdata = {errtime, errtype, errorigin, errmsgtxt, errdebugdata}
    sequence cmds = {}, title = "Error", txt = "Error"
    atom allowresume = 0
    
    if equal(errdata[2], "warn") then
        cmds = {
            {DR_Image, "msgIconWarning", 0, 0},
            {DR_Font, "Tahoma", 18, Bold},
            {DR_TextColor, rgb(80, 80, 0)},
            {DR_PenPos, 75, 5},
            {DR_Puts, "Application Error :-("}
        }
        title = app:info("name") & ": Error Report"
        txt = "The following error has occured in '" & errdata[3] & "':\n" & errdata[4] & "\n"
        ifdef debug then
            txt &= "\nDebug Data = " & pretty_sprint(errdata[5], {2})
        end ifdef
        allowresume = 1
        
    elsif equal(errdata[2], "die") then
        cmds = {
            {DR_Image, "msgIconError", 0, 0},
            {DR_Font, "Tahoma", 18, Bold},
            {DR_TextColor, rgb(80, 0, 0)},
            {DR_PenPos, 75, 5},
            {DR_Puts, "Fatal Application Error!"}
        }
        title = app:info("name") & ": Error Report"
        txt = "The following error has occured in '" & errdata[3] & "':\n" & errdata[4] & "\n"
        ifdef debug then
            txt &= "\nDebug Data = " & pretty_sprint(errdata[5], {2})
        end ifdef
    end if
    
    if gui:wexists("winErrorReport") then
        gui:wdestroy("winErrorReport")
    end if
    
    gui:wcreate({
        {"name", "winErrorReport"},
        {"class", "window"},
        {"mode", "window"},
        {"handler", routine_id("gui_event")},
        {"topmost", 1},
        {"title", title},
        {"size", {500, 300}},
        {"remember", 0},
        {"allow_close", 0}
    })
    
    gui:wcreate({
        {"name", "winErrorReport.cntMain"},
        {"parent", "winErrorReport"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", "winErrorReport.cntTop"},
        {"parent", "winErrorReport.cntMain"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    gui:wcreate({
        {"name", "winErrorReport.canImage"},
        {"parent", "winErrorReport.cntTop"},
        {"class", "canvas"},
        {"size", {0, 64}},
        {"border", 0},
        {"handle_debug", 0}
    })
    
    gui:wproc("winErrorReport.canImage", "draw_background", {cmds})
    
    gui:wcreate({
        {"name", "winErrorReport.txtInfo"},
        {"parent", "winErrorReport.cntTop"},
        {"class", "textbox"},
        {"mode", "text"},
        --{"monowidth", 1},
        {"text", txt}
    })
    
    gui:wcreate({
        {"name", "winErrorReport.cntBottom"},
        {"parent", "winErrorReport.cntMain"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "equal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"}
    })
    gui:wcreate({
        {"name", "winErrorReport.btnQuit"},
        {"parent", "winErrorReport.cntBottom"},
        {"class", "button"},
        {"label", "Quit"},
        {"size", {50, 0}}
    })
    
    if allowresume then
        gui:wcreate({
            {"name", "winErrorReport.btnResume"},
            {"parent", "winErrorReport.cntBottom"},
            {"class", "button"},
            {"label", "Resume"},
            {"size", {50, 0}}
        })
    end if
    
end procedure


export procedure enable()
    if not enabled then
        set_warn_callback(routine_id("warn_proc"))
        set_die_callback(routine_id("die_proc"))
        enabled = 1
    end if
end procedure


export procedure disable()
    if enabled then
        set_warn_callback(-1)
        set_die_callback(-1)
        enabled = 0
    end if
end procedure


