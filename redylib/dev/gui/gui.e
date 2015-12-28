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


global constant RedyAE_Version  = "1.0.a5",
RedyAE_Copyright = "Copyright" & 169 & " 2014-2015 Ryan W. Johnson",
RedyAE_AboutText = 
    "Redy" & 153 & " application environment version " & RedyAE_Version & "\n" &
    RedyAE_Copyright & "\n" &
    "http://redy-project.org/\n" &
    "\n" & 
    "Licensed under the Apache License, Version 2.0 (the \"License\"); " &
    "you may not use this file except in compliance with the License. " &
    "You may obtain a copy of the License at\n" &
    "\n" &
    "  http://www.apache.org/licenses/LICENSE-2.0\n" &
    "\n" &
    "Unless required by applicable law or agreed to in writing, software " &
    "distributed under the License is distributed on an \"AS IS\" BASIS, " &
    "WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. " &
    "See the License for the specific language governing permissions and " &
    "limitations under the License."




-- Redy Graphical User Interface library
-- Author: Ryan Johnson (ryanj@redy-project.org)
-- http://redy-project.org/

public include oswin/oswin.e as oswin
public include themes.e as th
public include widgets.e as widget
public include debugconsole.e as dbug

--widgets that control windows
include wc/wc_window.e
include wc/wc_menu.e
include wc/wc_list.e

--widgets that organise other widgets
include wc/wc_container.e
include wc/wc_panel.e
include wc/wc_tabs.e
include wc/wc_divider.e
include wc/wc_menubar.e
include wc/wc_toolbar.e
include wc/wc_infobar.e

--widgets that manage data
include wc/wc_scrollbar.e
include wc/wc_progress.e
include wc/wc_slider.e
include wc/wc_button.e
include wc/wc_toggle.e
include wc/wc_option.e
include wc/wc_treebox.e
include wc/wc_listbox.e
include wc/wc_fancylist.e
include wc/wc_textbox.e
include wc/wc_textedit.e --depreciated, will be replaced with canvas object library: objects/textedit.e
include wc/wc_canvas.e


include std/task.e
include std/text.e


atom task_start, task_gui_1, task_gui_2, task_gui_3, evhandler, debughandler
sequence evbuffer


procedure guitask()
    atom TaskIdle = 1
    while 1 do
        widget:process_events(100)
        widget:rearrange_widgets()
        widget:draw_widgets()
        evbuffer = widget:get_app_events() --wname, evname, evdata
        /*if length(evbuffer) > 1 and TaskIdle = 1 then
            task_schedule(task_self(), length(evbuffer)*2)
            TaskIdle = 0
        else
            task_schedule(task_self(), {0.01, 0.5})
            TaskIdle = 1
        end if*/
        for e = 1 to length(evbuffer) do
            if e > length(evbuffer) then
                --? evbuffer
                exit
            end if
            if match("_winDebug", evbuffer[e][2]) > 0 then
                call_proc(debughandler, evbuffer[e][2..4])
            else
                call_proc(debughandler, evbuffer[e][2..4])
                call_proc(evbuffer[e][1], evbuffer[e][2..4])
            end if
        end for
        task_yield()
    end while
end procedure


export procedure call_task(integer rid, sequence args, object schedule = 1)
    --void = task_create(routine_id("temp_task"), {rid, args})
    atom void = task_create(rid, args)
    task_schedule(void, schedule)
    --task_yield()
end procedure


export procedure start(atom startrid, atom eventh) --eventh: the default event handler
    evhandler = eventh
    widget:set_default_event_handler(eventh)
    oswin:start()
    th:load_default_theme()
    debughandler = dubug_initialize()
    task_gui_1 = task_create(routine_id("guitask"), {})
    task_gui_2 = task_create(routine_id("guitask"), {})
    task_gui_3 = task_create(routine_id("guitask"), {})
    task_schedule(task_gui_1, 5)
    task_schedule(task_gui_2, 5)
    task_schedule(task_gui_3, {0.25, 0.5})
    
    task_start = task_create(startrid, {})
    task_schedule(task_start, 1)
    
    task_schedule(task_self(), 1)
    while 1 do
        --some sort of system monitor here?
        --perhaps warn if no windows are created, or end program when no windows exist?
        task_yield()
    end while
end procedure

