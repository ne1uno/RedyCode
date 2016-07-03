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

include redylib_0_9/gui.e as gui
include redylib_0_9/app.e as app
include redylib_0_9/actions.e as action

include std/task.e
include std/text.e
include euphoria/info.e
include std/sequence.e



action:define({
    {"name", "show_about"},
    {"do_proc", routine_id("show")},
    {"label", "Colors..."},
    {"icon", "application-x-executable"},
    {"description", "Show Colors dialog"}
})


export procedure gui_event(object evwidget, object evtype, object evdata)
    switch evwidget do
        case "winColors.btnOk" then
            gui:wdestroy("winColors")
    end switch
end procedure


procedure colors_task()
    get_color_list()
    
    gui:wcreate({
        {"name", "winColors"},
        {"class", "window"},
        {"mode", "dialog"},
        {"handler", routine_id("gui_event")},
        {"modal", 1},
        {"title", app:info("name") & " " & app:info("version")}
    })
    gui:wcreate({
        {"name", "winColors.cntMain"},
        {"parent", "winColors"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", "winColors.cntTop"},
        {"parent", "winColors.cntMain"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", "winColors.canLogo"},
        {"parent", "winColors.cntTop"},
        {"class", "canvas"},
        {"size", {600, 107}},
        {"border", 0},
        {"handle_debug", 0}
    })
    sequence cmds = {
        {DR_Font, "Tahoma", 16, Bold},
        {DR_TextColor, rgb(47, 80, 113)},
        {DR_PenPos, 210, 5},
        {DR_Puts, app:info("name") & " " & app:info("version")},
        {DR_Font, "Arial", 10, Normal},
        {DR_TextColor, rgb(0, 0, 0)},
        {DR_PenPos, 210, 40},
        {DR_Puts, "Written in the Euphoria programming language"},
        {DR_PenPos, 210, 60},
        {DR_Puts, "Built using the Redy" & 153 & " application environment"}
    }
    gui:wproc("winColors.canLogo", "draw_background", {cmds})
    
    sequence txtsysinfo = 
    app:info("colors") & "\n" &
    "\n" &
    "Copyright " & app:info("copyright") & "\n" &
    "\n" &
    app:info("license") & "\n" &
    "\n" &
    "Euphoria version " & version_string(0) & "\n"
        
    ifdef EU4_1 then
        txtsysinfo &= "for " & platform_name() & " " & arch_bits() & "\n"
    end ifdef

    txtsysinfo &= "\n" &
    "RedyLib version " & RedyAE_Version & "\n"
    



    --"Euphoria version: " & version_string(0) --& "\n" &
    --"version_node: " & version_node(0) & "\n" &
    --"version_date: " & version_date(0) & "\n" &
    --"version_type: " & version_type() & "\n" &
    --"version_string_long: " & version_string_long(0) & "\n"
    --"include_paths: " & pretty_sprint(include_paths(0), {2}) & "\n" &
    --"option_switches: " & pretty_sprint(option_switches(), {2})
    
    gui:wcreate({
        {"name", "winColors.txtInfo"},
        {"parent", "winColors.cntTop"},
        {"class", "textbox"},
        {"mode", "text"},
        --{"label", "Application Information"},
        {"monowidth", 1},
        {"text", txtsysinfo},
        {"size", {600, 280}}
    })
    
    gui:wcreate({
        {"name", "winColors.cntBottom"},
        {"parent", "winColors.cntMain"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "equal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"}
    })
    gui:wcreate({
        {"name", "winColors.btnOk"},
        {"parent", "winColors.cntBottom"},
        {"class", "button"},
        {"label", "OK"},
        {"size", {50, 0}}
    })
    
    task_schedule(task_self(), {0.5, 0.6})
    while 1 do
        cmds = {
            {DR_Image, "redy_logo", 0, 0}
        }
        gui:wproc("winColors.canLogo", "draw_foreground", {cmds})
        task_yield()
        
        cmds = {
            {DR_Image, "redy_logo_no_cursor", 0, 0}
        }
        gui:wproc("winColors.canLogo", "draw_foreground", {cmds})
        task_yield()
        
        if gui:wexists("winColors") = 0 then
            exit
        end if
    end while
end procedure


export procedure show()
    if gui:wexists("winColors") = 0 then
        gui:call_task(routine_id("colors_task"), {})
    end if
end procedure



