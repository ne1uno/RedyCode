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


include std/task.e
include std/text.e
include std/pretty.e
include std/utils.e
include std/sequence.e
include std/filesys.e


action:define({
    {"name", "show_splash"},
    {"do_proc", routine_id("do_show_splash")},
    {"label", "Show Splash..."},
    {"description", "Show Splash Screen"}
})


procedure gui_event(object evwidget, object evtype, object evdata)
    switch evwidget do
        case "winSplash.canSplash" then
            if equal(evtype, "handle") and equal(evdata[2], "LeftDown") then
                gui:wdestroy("winSplash")
            end if
    end switch
end procedure


procedure do_show_splash()
    sequence scrsize = gui:screen_size()
    atom wleft, wtop, wwidth, wheight
    
    gui:call_task(routine_id("splash_task"), {3})
end procedure 


procedure splash_task(atom showseconds)
    if gui:wexists("winSplash") then
        return
    end if
    
    gui:wcreate({
        {"name", "winSplash"},
        {"class", "window"},
        {"mode", "screen"},
        {"handler", routine_id("gui_event")},
        {"title", app:info("title") & " " & app:info("version")},
        {"topmost", 1}
        --{"position", {300, 300}},
        --{"size", {645, 425}}
    })
    gui:wcreate({
        {"name", "winSplash.cntMain"},
        {"parent", "winSplash"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"}
    })
    gui:wcreate({
        {"name", "winSplash.canSplash"},
        {"parent", "winSplash.cntMain"},
        {"class", "canvas"},
        {"size", {620, 240}},
        {"border", 0}
    })
    
    gui:wproc("winSplash.canSplash", "draw_background", {{
        {DR_PenColor, rgb(255, 255, 255)},
        {DR_Rectangle, True, 0, 0, 620, 238},
        {DR_Image, "redy_logo", 10, 10},
        {DR_Image, "eu16", 10, 10},
        
        {DR_Font, "Arial", 20, Bold},
        {DR_TextColor, rgb(0, 30, 150)},
        {DR_PenPos, 20, 205},
        {DR_Puts, "Integrated Development Environment " & app:info("version")}
    }})
    
    task_delay(showseconds)
    
    gui:wdestroy("winSplash")
end procedure


