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
include std/rand.e


atom currtip = 1
sequence tips = {
    {"Welcome to RedyCode! Go to the Help menu -> Help for complete documentation for RedyCode and the RedyLib API. Enjoy! :-)"}
}


action:define({
    {"name", "show_tips"},
    {"do_proc", routine_id("do_show_tips")},
    {"label", "Show Tips..."},
    {"icon", "dialog-information"},
    {"description", "Show Tips dialog"}
})


procedure save_prefs()
    cfg:set_var("", "Startup", "Disable tips", gui:wfunc("winTips.chkDisableStartup", "get_value", {}))
    cfg:save_config("")
end procedure


procedure show_tip(atom tipidx)
    gui:wproc("winTips.txtTip", "set_label", {"Tip #" & sprint(tipidx)})
    gui:wproc("winTips.txtTip", "set_text", {tips[tipidx]})
end procedure


export procedure gui_event(object evwidget, object evtype, object evdata)
    switch evwidget do
    case "winTips.btnOk" then
        gui:wdestroy("winTips")
        
    case "winTips.btnNext" then
        currtip += 1
        if currtip > length(tips) then
            currtip = 1
        end if
        show_tip(currtip)
        
    case "winTips.btnPrev" then
        currtip -= 1
        if currtip < 1 then
            currtip = length(tips)
        end if
        show_tip(currtip)
        
    case "winTips.chkDisableStartup" then
        if equal(evtype, "value") then
            save_prefs()
        end if
    case "winTips" then
        if equal(evtype, "closed") then
            gui:wdestroy("winTips")
        end if
    end switch
end procedure


procedure do_show_tips()
    object prefDisableTips = cfg:get_var("", "Startup", "Disable tips")
    if not atom(prefDisableTips) then
        prefDisableTips = 0
        save_prefs()
    end if
    
    gui:wcreate({
        {"name", "winTips"},
        {"class", "window"},
        {"mode", "dialog"},
        {"handler", routine_id("gui_event")},
        {"title", "Useful Tips"}
        --{"modal", 1},
        --{"topmost", 1} 
        --{"position", {350, 350}}
        --{"visible", 0}
    })
    gui:wcreate({
        {"name", "winTips.cntMain"},
        {"parent", "winTips"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", "winTips.cntTop"},
        {"parent", "winTips.cntMain"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"},
        {"size", {400, 200}}
    })
    
    --data entry:
    gui:wcreate({
        {"name",  "winTips.txtTip"},
        {"parent",  "winTips.cntTop"},
        {"class", "textbox"},
        {"mode", "text"},
        {"label", "tip"}
    })
    currtip = 1 --rand_range(1, length(tips))
    show_tip(currtip)
    
    gui:wcreate({
        {"name",  "winTips.chkDisableStartup"},
        {"parent",  "winTips.cntTop"},
        {"class", "toggle"},
        {"label", "Do not show tips on startup"},
        {"value", prefDisableTips}
    })
    
    gui:wcreate({
        {"name", "winTips.cntBottom"},
        {"parent", "winTips.cntMain"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "equal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"}
    })
    
    if length(tips) > 1 then
        gui:wcreate({
            {"name", "winTips.btnPrev"},
            {"parent",  "winTips.cntBottom"},
            {"class", "button"},
            {"label", "<< Previous"}
        })
        gui:wcreate({
            {"name", "winTips.btnNext"},
            {"parent",  "winTips.cntBottom"},
            {"class", "button"},
            {"label", "Next >>"}
        })
    end if
    
    gui:wcreate({
        {"name",  "winTips.btnOk"},
        {"parent",  "winTips.cntBottom"},
        {"class", "button"},
        {"label", "OK, Thanks!"}
    })
end procedure


export procedure start()
    object prefDisableTips = cfg:get_var("", "Startup", "Disable tips")
    if not atom(prefDisableTips) then
        prefDisableTips = 0
        save_prefs()
    end if
    msg:subscribe("tips", "command", routine_id("msg_event"))
    
    if gui:wexists("winTips") then
         gui:wdestroy("winTips")
    end if
    
    if prefDisableTips = 0 then
        action:do_proc("show_tips")
    end if
end procedure

