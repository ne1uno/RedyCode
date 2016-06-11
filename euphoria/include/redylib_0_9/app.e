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


--redy application info


public include redylib_0_9/gui/dialogs/mainwin.e as mainwin

include redylib_0_9/err.e as err
include redylib_0_9/config.e as cfg

include std/datetime.e as dt
include std/filesys.e
include std/text.e
include std/pretty.e

sequence
defaultMenus = {
    {"File", {
        "confirm_exit"}
    },
    {"Help", {
        "show_about"}
    }
},
defaultToolbars = {}


public procedure set_menus(sequence menus)
    defaultMenus = menus
end procedure


public procedure set_default_toolbars(sequence tools)
    defaultToolbars = tools
end procedure


public function get_default_toolbars()
    return defaultToolbars
end function


--cfg:get_var("", "Menus", "EuiPath")
--pretty_print(1, cfg:list_vars("", "Menus"), {2})
--pretty_print(1, cfg:list_vars("", "Toolbars"), {2})


public function load_menus()
/*  --Customizable menus is not implemented, it seems unnecessary
    sequence menus = defaultMenus
    object currmenu = "", vdata, vmenu, vlist = cfg:list_vars("", "Menus")
    atom p1, p2
    if sequence(vlist) then
        menus = {}
        for i = 1 to length(vlist) do
            vdata = cfg:get_var("", "Menus", vlist[i])
            if sequence(vdata) then
                p1 = find('.', vlist[i])
                if p1 > 0 then
                    p2 = find('.', vlist[i][p1+1..$])
                    p1 -= 1
                else
                    p1 = length(vlist[i])
                    p2 = 0
                end if
                
                if p1 > 0 then
                    if p2 > 0 then
                        --submenu
                    else
                        vmenu = vlist[i][1..p1]
                        if equal(vmenu, currmenu) then
                            menus[$][2] &= {vdata} 
                        else
                            currmenu = vmenu
                            menus &= {{currmenu, {vdata}}}
                        end if
                    end if
                end if
            end if
        end for
    end if
    return menus*/
    return defaultMenus
end function


public function load_toolbars()
    sequence tools = defaultToolbars, dockpos = "hidden"
    object currtoolbar = "", vdata, vtoolbar, vlist = cfg:list_vars("", "Toolbars")
    atom p1
    
    if sequence(vlist) then
        tools = {}
        if length(vlist) = 0 then
            tools = defaultToolbars
        else
            for i = 1 to length(vlist) do
                vdata = cfg:get_var("", "Toolbars", vlist[i])
            
                if i = 1 and equal(vlist[i], "empty") and equal(vdata, "none") then
                    return {}
                end if
                
                p1 = find('.', vlist[i])
                if p1 > 0 then
                    if equal(vlist[i][p1+1..$], "position") then
                        dockpos = vdata
                        p1 = 0
                    else
                        p1 -= 1
                    end if
                else
                    p1 = length(vlist[i])
                end if
                
                if p1 > 0 then
                    vtoolbar = vlist[i][1..p1]
                    if equal(vtoolbar, currtoolbar) then
                        tools[$][3] &= {vdata} 
                    else
                        currtoolbar = vtoolbar
                        tools &= {{currtoolbar, dockpos, {vdata}}}
                        dockpos = "hidden"
                    end if
                end if
            end for
        end if
    end if
    
    --pretty_print(1, tools, {2})
    return tools
end function


public procedure save_toolbars(sequence tools)
/*
tools = {
    {"File", {
        "file_new",
        "file_open",
        "file_save",
        "file_save_as"}
    },
    {"Edit", {
        "undo",
        "redo",
        "-",
        "cut",
        "copy",
        "paste",
        "delete",
        "-",
        "find",
        "find_replace",
        "-",
        "format_indent_less",
        "format_indent_more"}
    }
}
*/
    
    cfg:delete_section("", "Toolbars")
    
    if length(tools) > 0 then
        for tb = 1 to length(tools) do
            cfg:set_var("", "Toolbars", tools[tb][1] & ".position", tools[tb][2])
            for t = 1 to length(tools[tb][3]) do
                cfg:set_var("", "Toolbars", tools[tb][1] & "." & sprint(t), tools[tb][3][t])
            end for
        end for
    else
        cfg:set_var("", "Toolbars", "empty", "none")
    end if
    
    cfg:save_config("")
end procedure

sequence
iNames = {},
iValues = {}


--Initialize app info
if length(iNames) = 0 then
    sequence cmdline = command_line()
    --1) The path, to either the Euphoria executable, (eui, eui.exe, euid.exe euiw.exe) or to your bound executable file.
    --2) The next word, is either the name of your Euphoria main file, or (again) the path to your bound executable file.
    --3) Any extra words, typed by the user. You can use these words in your program.
    define({
        {"name", filebase(cmdline[2])},
        {"version", "0"},
        --{"date", dt:format(dt:now(), "%Y-%m-%d %H:%M:%S")}, 
        {"path", pathname(cmdline[2])}
    })
end if


public procedure define(object appinfo)
--Define application info
    atom idx
    sequence txt
    for i = 1 to length(appinfo) do
        if sequence(appinfo[i][2]) and length(appinfo[i][2]) > 0 then
            if atom(appinfo[i][2][1]) then
                txt = appinfo[i][2]
            else
                txt = ""
                for li = 1 to length(appinfo[i][2]) do
                    txt &= appinfo[i][2][li] & "\n"
                end for
            end if
        else
            txt = pretty_sprint(appinfo[i][2], {2})
        end if
        
        idx = find(appinfo[i][1], iNames)
        if idx > 0 then
            iValues[idx] = txt
        else
            iNames &= {appinfo[i][1]}
            iValues &= {txt}
        end if
    end for
end procedure


public function info(object infoname = 0)
    if atom(infoname) then --return all info
        sequence infolist = {}
        for i = 1 to length(iNames) do
            infolist &= {{iNames[i], iValues[i]}}
        end for
        return infolist
        
    else --return specified info
        atom idx = find(infoname, iNames)
        if idx > 0 then
            return iValues[idx]
        else
            return ""
        end if
    end if
end function

public procedure create_main_window(atom evhandlerrid = 0)
    mainwin:start(evhandlerrid)
end procedure

