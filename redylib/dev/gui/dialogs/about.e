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
include euphoria/info.e


export procedure gui_event(object evwidget, object evtype, object evdata)
    switch evwidget do
        case "winAbout.btnOk" then
            gui:wdestroy("winAbout")
    end switch
end procedure


procedure about_task()
    gui:wcreate({
        {"name", "winAbout"},
        {"class", "window"},
        {"mode", "dialog"},
        {"handler", routine_id("gui_event")},
        {"modal", 1},
        {"title", App_Name & " " & App_Version}
    })
    gui:wcreate({
        {"name", "winAbout.cntMain"},
        {"parent", "winAbout"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", "winAbout.cntTop"},
        {"parent", "winAbout.cntMain"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", "winAbout.canLogo"},
        {"parent", "winAbout.cntTop"},
        {"class", "canvas"},
        {"size", {600, 107}},
        {"border", 0},
        {"handle_debug", 0}
    })
    sequence cmds = {
        {DR_Font, "Palatino Linotype", 16, Bold},
        {DR_TextColor, rgb(47, 80, 113)},
        {DR_PenPos, 210, 5},
        {DR_Puts, App_Name & " " & App_Version},
        {DR_Font, "Lucida Sans Unicode", 10, Normal},
        {DR_TextColor, rgb(0, 0, 0)},
        {DR_PenPos, 210, 40},
        {DR_Puts, "Written in the Euphoria programming language"},
        {DR_PenPos, 210, 60},
        {DR_Puts, "Built using the Redy" & 153 & " application environment"}
    }
    gui:wproc("winAbout.canLogo", "draw_background", {cmds})
    
    sequence txtsysinfo = 
        "Euphoria version " & version_string(0) & "\n" &
        RedyAE_AboutText
    
    ifdef EU4_1 then
        txtsysinfo = 
        "Euphoria version " & version_string(0) & "\n" &
        "for " & platform_name() & " " & arch_bits() & "\n" &
        "\n" &
        RedyAE_AboutText
    end ifdef


    



    --"Euphoria version: " & version_string(0) --& "\n" &
    --"version_node: " & version_node(0) & "\n" &
    --"version_date: " & version_date(0) & "\n" &
    --"version_type: " & version_type() & "\n" &
    --"version_string_long: " & version_string_long(0) & "\n"
    --"include_paths: " & pretty_sprint(include_paths(0), {2}) & "\n" &
    --"option_switches: " & pretty_sprint(option_switches(), {2})
    
    gui:wcreate({
        {"name", "winAbout.txtInfo"},
        {"parent", "winAbout.cntTop"},
        {"class", "textbox"},
        {"mode", "text"},
        {"label", "System Information"},
        {"monowidth", 1},
        {"text", txtsysinfo},
        {"size", {600, 130}}
    })
    
    gui:wcreate({
        {"name", "winAbout.cntBottom"},
        {"parent", "winAbout.cntMain"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "equal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"}
    })
    gui:wcreate({
        {"name", "winAbout.btnOk"},
        {"parent", "winAbout.cntBottom"},
        {"class", "button"},
        {"label", "OK"},
        {"size", {50, 0}}
    })
    
    task_schedule(task_self(), {0.5, 0.6})
    while 1 do
        cmds = {
            {DR_Image, "redy_logo", 0, 0}
        }
        gui:wproc("winAbout.canLogo", "draw_foreground", {cmds})
        task_yield()
        
        cmds = {
            {DR_Image, "redy_logo_no_cursor", 0, 0}
        }
        gui:wproc("winAbout.canLogo", "draw_foreground", {cmds})
        task_yield()
        
        if gui:wexists("winAbout") = 0 then
            exit
        end if
    end while
end procedure


export procedure show()
    if gui:wexists("winAbout") = 0 then
        gui:call_task(routine_id("about_task"), {})
    end if
end procedure


