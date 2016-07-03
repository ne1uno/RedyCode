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
include redylib_0_9/actions.e as action
include redylib_0_9/gui.e as gui
include redylib_0_9/config.e as cfg
include redylib_0_9/msg.e as msg
include redylib_0_9/err.e as err

include redylib_0_9/gui/dialogs/msgbox.e as msgbox
include redylib_0_9/gui/dialogs/about.e as about
include redylib_0_9/gui/dialogs/error_report.e as errreport

include redylib_0_9/gui/dialogs/edit_toolbars.e as edittb


include redylib_0_9/gui/images/tango-icon-theme_16x16.e as icons

include std/task.e
include std/text.e
include std/pretty.e
include std/sequence.e
include std/filesys.e
include std/error.e
include std/datetime.e as dt
include std/filesys.e
include std/utils.e


atom
LastTabNum = 0,
ActiveTab = 0,  --TODO
MainEvHandlerRid = 0 --optional routine to forward "winMain" gui events

sequence tabDoubleClickAction = "file_close" --action to do when a tab is double-clicked (typically "file_close")
sequence tabSelectAction = "file_switch_to" --action to do when a tab is selected (typically "file_switch_to"})

sequence
tName = {},         --name of tab widget
tLabel = {},        --tab label
tTitle = {},        --tab title (displayed on window title when tab is selected)
tContextMenu = {},  --menu to show when tab is right-clicked
tModified = {},     --tab contents are modified
tReadOnly = {}      --tab contents are read-only


action:define({
    {"name", "confirm_exit"},
    {"do_proc", routine_id("do_confirm_exit")},
    {"label", "Exit"},
    {"icon", "system-log-out"},
    {"hotkey", "Alt+F4"},
    {"description", "Exit the application"}
})


procedure do_confirm_exit()
    sequence ans = "Discard"
    if modified_count() > 0 then
        ans = msgbox:waitmsg("Some data has not been saved. Are you sure you want to exit?", "Question", {"Save and Exit", "Discard", "Cancel"})
    end if
    if equal(ans, "Save and Exit") then
        action:do_proc("file_save_all", {})
        action:do_proc("confirm_exit", {})
        --gui:wdestroy("winMain")
        
    elsif equal(ans, "Discard") then
        gui:wdestroy("winMain")
    end if
end procedure


public procedure reload_toolbars()
    sequence
    tools = app:load_toolbars(),
    wch = gui:children_of("winMain")
    
    for w = 1 to length(wch) do
        if equal("toolbar", gui:widget_get_class(wch[w])) then
            gui:wdestroy(wch[w])
        end if
    end for
    
    if length(tools) > 0 then
        for t = 1 to length(tools) do
            if sequence(tools[t]) and length(tools[t]) = 3 then
                if find(tools[t][2], {"top", "bottom", "left", "right"}) then
                    gui:wcreate({
                        {"name", "toolbar" & tools[t][1]},
                        {"parent", "winMain"},
                        {"class", "toolbar"},
                        --{"dock", tools[t][2]}, --incomplete feature (need to fix wc_window.e)
                        {"dock", "top"},         --force to "top" for now
                        {"tools", tools[t][3]}
                    })
                end if
            end if
        end for
    end if
end procedure


function msg_event(sequence subscribername, sequence topicname, sequence msgname, object msgdata)
    return 1
end function


procedure gui_event(object evwidget, object evtype, object evdata)
    switch evwidget do
        case "tabMain" then
            if equal(evtype, "selection") or equal(evtype, "KeyFocus")  then
                object wname = gui:widget_get_name(evdata)
                ActiveTab = 0
                if sequence(wname) then
                    ActiveTab = find(wname, tName)
                    if length(tTitle[ActiveTab]) > 0 then
                        gui:wproc("winMain", "set_title", {app:info("title") & " - " & tTitle[ActiveTab]})
                    else
                        gui:wproc("winMain", "set_title", {app:info("title")})
                    end if
                    --msg:publish("mainwin", "maintabs", "tab_selected", {wname})
                end if
                if ActiveTab > 0 then
                    action:do_proc(tabSelectAction, {tName[ActiveTab]})
                else
                    action:do_proc(tabSelectAction, {""})
                end if
                
            elsif equal(evtype, "LeftDoubleClick") then
                object wname = gui:widget_get_name(evdata)
                if sequence(wname) then
                    ActiveTab = find(wname, tName)
                    action:do_proc(tabDoubleClickAction, {})
                end if
                
            elsif equal(evtype, "RightClick") then
                --todo: context menu for tab
            
            --elsif equal(evtype, "flag") then
                --msg:publish("mainwin", "maintabs", "flag_color", evdata)
                --tContextMenu[ActiveTab]
                
            end if
        case "winMain" then
            if MainEvHandlerRid > 0 then
                call_proc(MainEvHandlerRid, {evwidget, evtype, evdata})
            end if
        case else
            
    end switch
end procedure


export procedure start(atom evhandlerrid = 0)
    --sequence
    --displaysize = gui:getPrimaryDisplaySize()
    --atom
    --wwidth = floor(displaysize[1] * 1 / 2),
    --wheight = floor(displaysize[2] * 2 / 3)
    
    MainEvHandlerRid = evhandlerrid
    
    gui:wcreate({
        {"name", "winMain"},
        {"class", "window"},
        {"title", app:info("title")},
        {"handler", routine_id("gui_event")},
        --{"position", {wleft, wtop}}, --this is now handled automatically by default
        --{"size", {wwidth, wheight}},
        {"remember", 1},
        {"action-close", "confirm_exit"}
    })
    gui:wcreate({
        {"name", "cntMain"},
        {"parent", "winMain"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    errreport:enable()
    
    /*sequence ImgPath = app:info("path") & "\\images\\"
    gui:load_bitmap("folder_open_16", ImgPath & "folder_open_16.bmp")
    gui:load_bitmap("redy16", ImgPath & "redy16.bmp")
    gui:load_bitmap("e16", ImgPath & "e16.bmp")
    gui:load_bitmap("ex16", ImgPath & "ex16.bmp")
    gui:load_bitmap("err16", ImgPath & "err16.bmp")
    gui:load_bitmap("txt16", ImgPath & "txt16.bmp")
    gui:load_bitmap("img16", ImgPath & "img16.bmp")
    */
    
    icons:load_images(gui:widget_get_handle("winMain"))
    
    sequence menus = app:load_menus()
    if length(menus) > 0 then
        gui:wcreate({
            {"name", "mnuMain"},
            {"parent", "winMain"},
            {"class", "menubar"},
            {"menus", menus}
        })
    end if
    
    reload_toolbars()
    
    --err:warn("actions.exw", "Something happened.")
    --err:die("actions.exw:gui_event", "You broke the Internet!")
    
    
    --Tabs--------------------------------------------
    
    gui:wcreate({
        {"name", "cntEditor"},
        {"parent", "cntMain"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    
    --create_tab("project", "Untitled", "project_untitled", "untitled", "untitled")
    
    msg:subscribe("mainwin.e", "maintabs", routine_id("msg_event"))
    
end procedure


public function modified_count()
    atom m = 0
    for t = 1 to length(tModified) do
        if tModified[t] then
            m += 1
        end if
    end for
    return m
end function


function next_tab_name()
    LastTabNum += 1
    return "tabMain" & sprintf("%d", {LastTabNum})
end function


public procedure set_tabs_double_click_action(sequence actionname)
    tabDoubleClickAction = actionname
end procedure

public procedure set_tabs_select_action(sequence actionname)
    tabSelectAction = actionname
end procedure



public procedure set_tab_context_menu(sequence tabname, sequence tabmenu)
    atom tidx = find(tabname, tName)
    if tidx > 0 then
        tContextMenu[tidx] = tabmenu
    end if
end procedure


public function create_tab(sequence tablabel, sequence tabtitle, atom readonly = 0)
    sequence tabname = next_tab_name()
    
    if not wexists("tabMain") then
        gui:wcreate({
            {"name", "tabMain"},
            {"parent", "cntEditor"},
            {"class", "tabs"},
            {"handler", routine_id("gui_event")}
        })
    end if
    
    tName &= {tabname}
    tLabel &= {tablabel}
    tTitle &= {tabtitle}
    tContextMenu &= {0}
    tModified &= {0}
    tReadOnly &= {readonly}
    --ActiveTab = find(tabname, tName)
    
    gui:wcreate({
        {"name", tabname},
        {"parent", "tabMain"},
        {"class", "container"},
        {"label", tablabel},
        --{"flag", tabflagcolor},
        --{"tab", 1},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    set_tab_readonly(tabname, readonly)
    
    
    return tabname
end function


public procedure destroy_tab(sequence tabname)
    atom tidx = find(tabname, tName)
    if tidx > 0 then
        gui:wdestroy(tabname)
        tName = remove(tName, tidx)
        tLabel = remove(tLabel, tidx)
        tTitle = remove(tTitle, tidx)
        tContextMenu = remove(tContextMenu, tidx)
        tModified = remove(tModified, tidx)
        tReadOnly = remove(tReadOnly, tidx)
        --if ActiveTab  > length(tName) then
        --    ActiveTab = length(tName)
        --end if
    end if
end procedure


public procedure select_tab(sequence tabname)
    atom tidx = find(tabname, tName)
    if tidx > 0 then
        --ActiveTab = tidx 
        gui:wproc("tabMain", "select_tab_by_widget", {tabname})
    end if
end procedure


public function list_tabs()
    return {tName, tLabel, tTitle} 
end function


public procedure set_tab_label(sequence tabname, sequence tablabel)
    atom tidx = find(tabname, tName)
    if tidx > 0 then
        tLabel[tidx] = tablabel
        gui:wproc("tabMain", "set_tab_label", {tabname, tablabel})
    end if
end procedure


public procedure set_tab_title(sequence tabname, sequence tabtitle)
    atom tidx = find(tabname, tName)
    if tidx > 0 then
        tTitle[tidx] = tabtitle
        if ActiveTab = tidx then
            if length(tTitle[ActiveTab]) > 0 then
                gui:wproc("winMain", "set_title", {app:info("title") & " - " & tTitle[ActiveTab]})
            else
                gui:wproc("winMain", "set_title", {app:info("title")})
            end if
        end if
    end if
end procedure


public procedure set_tab_modified(sequence tabname, atom modified)
    
    atom tidx = find(tabname, tName)
    if tidx > 0 then
        tModified[tidx] = modified
        --pretty_print(1, {tabname, modified}, {2})
        if modified then
            gui:wproc("tabMain", "set_tab_flag", {tabname, rgb(255, 0, 0)})
        else
            gui:wproc("tabMain", "set_tab_flag", {tabname, -1})
        end if
    end if
end procedure


public procedure set_tab_readonly(sequence tabname, atom readonly)
    atom tidx = find(tabname, tName)
    if tidx > 0 then
        tReadOnly[tidx] = readonly
        if readonly then
            gui:wproc("tabMain", "set_tab_flag", {tabname, rgb(0, 0, 255)})
        else
            gui:wproc("tabMain", "set_tab_flag", {tabname, -1})
        end if
    end  if
end procedure


