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

include redylib_0_9/gui/dialogs/dialog_file.e as dlgfile

include std/task.e
include std/text.e
include std/pretty.e
include std/filesys.e
         

object ProjectPath, EuiPath, EubindPath, IncludePath
sequence SourcePath = "", IncludePaths = {}, DefaultApp = "", AppList = {}



action:define({
    {"name", "app_run_default"},
    {"do_proc", routine_id("do_app_run_default")},
    {"label", "Run"},
    {"icon", "redy16"},
    {"description", "Run Default Program"},
    {"enabled", 0}
})

action:define({
    {"name", "app_run"},
    {"do_proc", routine_id("do_app_run")},
    {"label", "Run"},
    {"icon", ""},
    --{"list", {}},
    {"description", "Run Application"},
    {"enabled", 0}
})

action:define({
    {"name", "app_bind"},
    {"do_proc", routine_id("do_app_bind")},
    {"label", "Bind..."},
    {"icon", "ex16"},
    {"description", "Bind Program"},
    {"enabled", 0}
})

action:define({
    {"name", "app_build"},
    {"do_proc", routine_id("do_app_build")},
    {"label", "Translate..."},
    {"icon", "ex16"},
    {"description", "Build Application"},
    {"enabled", 0}
})



export procedure set_source_path(sequence sourcepath)
    SourcePath = sourcepath
end procedure


--export procedure set_include_paths(sequence includepaths)
--    IncludePaths = includepaths
--end procedure


export procedure set_default_app(sequence defaultapp)
    DefaultApp = defaultapp
end procedure


export procedure set_app_list(sequence applist)
    AppList = applist
end procedure


procedure do_app_run_default()
    if length(SourcePath) > 0 and length(DefaultApp) > 0 then
        action:do_proc("app_run", {SourcePath & "\\" & DefaultApp})
    end if
end procedure


procedure do_app_run(sequence exfile)
    if file_exists(exfile) then
        object
        EuiPath = cfg:get_var("", "Projects", "EuiPath"),
        IncludePath = cfg:get_var("", "Projects", "IncludePath")
        --RedyLibPath = cfg:get_var("", "Projects", "RedyLibPath")
        
        if sequence(EuiPath) and sequence(IncludePath) then --and sequence(RedyLibPath) then
            sequence cmdline = 
            --" -EUDIR \"\"" & eupath --is this needed to override possible conflicts with installed version of euphoria? 
            --"-I \"" & IncludePath & "\" -I \"" & RedyLibPath & "\" \"" & exfile & "\""
            "-I \"" & IncludePath & "\" \"" & exfile & "\""
            
            --puts(1, "<" & cmdline & ">\n")
            gui:ShellExecute(gui:widget_get_handle("winMain"), EuiPath, cmdline, "open", filesys:pathname(exfile))
            
            --gui:ShellExecute(gui:widget_get_handle("winMain"), EuiPath, cmdline, "open", driveid(exfile) & ":" & pathname(exfile))
        end if
    end if
end procedure

procedure do_app_bind()
    show_build()
end procedure

procedure do_app_build()
    show_build()
end procedure


procedure gui_event(object evwidget, object evtype, object evdata)
    switch evwidget do  
        case "winBuild.btnTest" then
            gui:wdestroy("winBuild")
            
        case "winBuild.btnClose" then
            gui:wdestroy("winBuild")
            
        case "winBuild" then
            if equal(evtype, "closed") then
                gui:wdestroy("winBuild")
            end if
        
    end switch
end procedure


procedure show_build()
    if gui:wexists("winBuild") then
         return
    end if
    
    gui:wcreate({
        {"name", "winBuild"},
        {"class", "window"},
        {"mode", "window"},
        {"handler", routine_id("gui_event")},
        {"title", "Build"},
        --{"topmost", 1},
        {"size", {550, 450}}
    })
    gui:wcreate({
        {"name", "winBuild.cntMain"},
        {"parent", "winBuild"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    gui:wcreate({
        {"name", "winBuild.txtBuildLog"},
        {"parent", "winBuild.cntMain"},
        {"class", "textbox"},
        {"mode", "text"},
        {"label", "Build Log"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    gui:wcreate({
        {"name", "winBuild.cntBottom"},
        {"parent", "winBuild.cntMain"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "equal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"}
    })
    gui:wcreate({
        {"name", "winBuild.btnTest"},
        {"parent", "winBuild.cntBottom"},
        {"class", "button"},
        {"label", "Run"}
    })
    gui:wcreate({
        {"name", "winBuild.btnClose"},
        {"parent", "winBuild.cntBottom"},
        {"class", "button"},
        {"label", "Close"}
    })
end procedure

