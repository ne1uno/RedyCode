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
include redylib_0_9/gui/dialogs/msgbox.e as msgbox

include std/task.e
include std/text.e
include std/pretty.e
include std/filesys.e
include std/convert.e
include std/sequence.e


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
    exfile = filesys:pathname(exfile) & "\\" & filesys:filename(exfile)
    
    if file_exists(exfile) then
        object
        EuiPath = cfg:get_var("", "Projects", "EuiPath"),
        IncludePath = cfg:get_var("", "Projects", "IncludePath")
        --RedyLibPath = cfg:get_var("", "Projects", "RedyLibPath")
        atom wh = gui:widget_get_handle("winMain")
        
        if sequence(EuiPath) and sequence(IncludePath) then --and sequence(RedyLibPath) then
            clear_error()
            sequence cmdline = 
            --" -EUDIR \"\"" & eupath --is this needed to override possible conflicts with installed version of euphoria? 
            --"-I \"" & IncludePath & "\" -I \"" & RedyLibPath & "\" \"" & exfile & "\""
            "-I \"" & IncludePath & "\" \"" & exfile & "\""
            
            --puts(1, "<" & cmdline & ">\n")
            
            --Old version:
            --gui:ShellExecute(gui:widget_get_handle("winMain"), EuiPath, cmdline, "open", filesys:pathname(exfile))
            --ShellExecute(atom WinHwnd, sequence filename, sequence parameter, sequence verb = "", sequence workingdir = "")
            
            --New version:
            atom ret = gui:ShellExecute(wh, "open", EuiPath, cmdline, filesys:pathname(exfile))
            --ShellExecute(atom hwnd, object lpOperation, object lpFile, object lpParameters = NULL, object lpDirectory = NULL, atom nShowCmd = SW_SHOWNORMAL )
            
            if ret > 32 then 
              -- success
            else 
              -- failure
                msgbox:msg("Unable to run '" & exfile & "'. ShellExecute returned: " & sprint(ret) & "", "Error")
            end if
        else
            msgbox:msg("Unable to run '" & exfile & "'. Invalid eui or include path.", "Error")
        end if
    else
        msgbox:msg("Unable to run '" & exfile & "'. File does not exist.", "Error")
    end if
end procedure


procedure do_app_bind()
    clear_error()
    show_build()
end procedure


procedure do_app_build()
    clear_error()
    show_build()
end procedure


procedure clear_error()
    sequence errfile = pPath & "\\source\\ex.err"
    if file_exists(errfile) then
        if not delete_file(errfile) then
            atom fn = open(errfile, "w")
            if fn = -1 then
            else
                puts(fn, "") --Just incase it fails to delete the file, try to make it empty at least.
                close(fn)
            end if
        end if
    end if
    pError = 0 
    action:set_enabled("project_show_error", 0)
end procedure


export function check_error()
    atom fn = -1, sp, errline = 0
    object ln, txt = ""
    sequence errfile = "", errtxt
    
    if length(pPath) > 0 then
        fn = open(pPath & "\\source\\ex.err", "r")
    end if
    if fn = -1 then
        clear_error()
    else
        for li = 1 to 4 do
            ln = gets(fn)
            if sequence(ln) then
                ln = remove_all(10, ln)
                ln = remove_all(13, ln)
                txt &= {ln}
            else
                exit
            end if
        end for
        close(fn)
        
        --Examples:
        
        --C:\RedyCode\projects\RedyCode\source\context.e:250
        --<0132>:: Syntax error - expected to see possibly 'then', not a procedure
        --                action:do_proc("set_selection", {sln, scol, eln, ecol})
        --                             ^
        
        ------------------------ TASK ID 5 guitask ---------------------------------
        --C:\RedyCode\projects\RedyCode\source\build.e:121 in procedure do_app_run() 
        --subscript value -48 is out of bounds, reading from a sequence of length 49 - in subscript #1 of 'exfile' 
        
        
        
        if length(txt) > 1 then
            sp = find(':', txt[1], 4)
            if sp > 0 then --seems to be a syntax error or runtime error in main task
                errfile = txt[1][1..sp-1]
                for ec = sp+1 to length(txt[1]) + 1 do
                    if ec = length(txt[1]) + 1 or not find(txt[1][ec], "0123456789") then
                        errline = to_number(txt[1][sp+1..ec-1])
                        exit
                    end if
                end for
                errtxt = txt[2..$]
                
            else
                sp = find(':', txt[2], 4)
                if sp > 0 then --seems to be a runtime error in another task
                    errfile = txt[2][1..sp-1]
                    for ec = sp+1 to length(txt[2]) + 1 do
                    if ec = length(txt[2]) + 1 or not find(txt[2][ec], "0123456789") then
                        errline = to_number(txt[2][sp+1..ec-1])
                        exit
                    end if
                end for
                    errtxt = {txt[1]} & txt[3..$]
                end if
            end if
        end if
        
        if length(errfile) > 0 then
            return {filesys:pathname(errfile) & "\\" & filesys:filename(errfile), errline, errtxt}
        end if
    end if
    
    return 0
end function


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

