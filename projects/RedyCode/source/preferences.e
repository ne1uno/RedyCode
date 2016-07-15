-- This file is part of RedyCode(TM) Integrated Development Environment
-- http://redy-project.org/
-- 
-- Copyright 2016 Ryan W. Johnson
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
-- http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--------------------------------------------------------------------------------


without warning

include redylib_0_9/app.e as app
include redylib_0_9/gui.e as gui
include redylib_0_9/msg.e as msg
include redylib_0_9/config.e as cfg
include redylib_0_9/actions.e as action

include redylib_0_9/gui/dialogs/msgbox.e as msgbox
include redylib_0_9/gui/dialogs/dialog_file.e as dlgfile

include std/task.e
include std/text.e
include std/pretty.e
include std/filesys.e
include std/sequence.e
include std/io.e
         

object ConfigPath, TemplatePath, ProjectPath, EubinPath, IncludePath,
DefaultInfoVars, DefaultHeader, CurrDefaultInfoVarIdx


constant
InitialInfoVars = {
    {"title", {"New App"}},
    {"version", {"1.0.0"}},
    {"website", {""}},
    {"author", {""}},
    {"year", {""}},
    {"license", {
        "Licensed under the Apache License, Version 2.0 (the \"License\");",
        "you may not use this file except in compliance with the License.",
        "You may obtain a copy of the License at",
        "",
          "http://www.apache.org/licenses/LICENSE-2.0",
        "",
        "Unless required by applicable law or agreed to in writing, software",
        "distributed under the License is distributed on an \"AS IS\" BASIS,",
        "WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.",
        "See the License for the specific language governing permissions and",
        "limitations under the License."
    }},
    {"about", {""}}
},
InitialHeader = {
    "This file is part of $title",
    "$website",
    "",
    "Copyright $year $author",
    "",
    "$license"
}

action:define({
    {"name", "show_preferences"},
    {"do_proc", routine_id("do_show_preferences")},
    {"label", "Preferences..."},
    {"icon", "preferences-desktop"},
    {"description", "Show Preferences dialog"}
})


procedure detect_paths()
    sequence patherr = {}
    atom rescan
    object sp
    
    -- Detect if cfg has moved -------------------------------------
    if sequence(ConfigPath) and file_exists(ConfigPath) and equal(ConfigPath, ExePath) then
        rescan = 0
    else
        rescan = 1
        ConfigPath = ExePath
        cfg:set_var("", "Paths", "ConfigPath", ConfigPath)
    end if
    
    --only redetect paths that are within the RedyCode folder structure (leave external paths alone)
    if sequence(TemplatePath) then
        if rescan and match(ExePath, TemplatePath) = 1 then
            TemplatePath = 0
        end if
    end if
    if sequence(ProjectPath) then
        if rescan and match(ExePath, ProjectPath) = 1 then
            ProjectPath = 0
        end if
    end if
    if sequence(EubinPath) then
        if rescan and match(ExePath, EubinPath) = 1 then
            EubinPath = 0
        end if
    end if
    if sequence(IncludePath) then
        if rescan and match(ExePath, IncludePath) = 1 then
            IncludePath = 0
        end if
    end if
    
    --detect undefined paths
    if atom(TemplatePath) then
        TemplatePath = ExePath & "\\templates"
        if not file_exists(TemplatePath) then --see if running from project source folder
            sp = split_path(ExePath)
            if length(sp) > 3 then
                TemplatePath = join_path(sp[1..$-3]) & "\\templates"
            end if
            --TemplatePath = ExePath & "\\..\\..\\..\\templates"
        end if
    end if
    if atom(ProjectPath) then
        ProjectPath = ExePath & "\\projects"
        if not file_exists(ProjectPath) then
            sp = split_path(ExePath)
            if length(sp) > 2 then
                ProjectPath = join_path(sp[1..$-2])
            end if
            --ProjectPath = ExePath & "\\..\\.."
        end if
    end if
    if atom(EubinPath) then
        EubinPath = ExePath & "\\euphoria\\bin"
        if not file_exists(EubinPath) then
            sp = split_path(ExePath)
            if length(sp) > 3 then
                EubinPath = join_path(sp[1..$-3]) & "\\euphoria\\bin"
            end if
            --EubinPath = ExePath & "\\..\\..\\..\\euphoria\\bin"
        end if
    end if
    if atom(IncludePath) then
        IncludePath = ExePath & "\\euphoria\\include"
        if not file_exists(IncludePath) then
            sp = split_path(ExePath)
            if length(sp) > 3 then
                IncludePath = join_path(sp[1..$-3]) & "\\euphoria\\include"
            end if
            --IncludePath = ExePath & "\\..\\..\\..\\euphoria\\include"
        end if
    end if
    
    --verify paths
    if file_exists(TemplatePath) then
        cfg:set_var("", "Paths", "TemplatePath", filesys:pathname(TemplatePath & "\\"))
    else
        TemplatePath = ""
        patherr &= {"Templates"}
    end if
    if file_exists(ProjectPath) then
        cfg:set_var("", "Paths", "ProjectPath", filesys:pathname(ProjectPath & "\\"))
    else
        ProjectPath = ""
        patherr &= {"Projects"}
    end if
    if file_exists(EubinPath) then
        cfg:set_var("", "Paths", "EubinPath", filesys:pathname(EubinPath & "\\"))
    else
        EubinPath = ""
        patherr &= {"Euphoria"}
    end if
    if file_exists(IncludePath) then
        cfg:set_var("", "Paths", "IncludePath", filesys:pathname(IncludePath & "\\"))
    else
        IncludePath = ""
        patherr &= {"Includes"}
    end if
    --if file_exists(RedyLibPath) then
    --    cfg:set_var("", "Paths", "RedyLibPath", RedyLibPath)
    --else
    --    RedyLibPath = ""
    --end if
    
    path_error(patherr)
end procedure


export procedure check_config()
    ConfigPath = cfg:get_var("", "Paths", "ConfigPath")
    TemplatePath = cfg:get_var("", "Paths", "TemplatePath")
    ProjectPath = cfg:get_var("", "Paths", "ProjectPath")
    EubinPath = cfg:get_var("", "Paths", "EubinPath")
    IncludePath = cfg:get_var("", "Paths", "IncludePath")
    
    object 
    prevConfigPath = ConfigPath,
    prevTemplatePath = TemplatePath,
    prevProjectPath = ProjectPath,
    prevEubinPath = EubinPath,
    prevIncludePath = IncludePath,
    dosave = 0

    detect_paths()
    
    DefaultInfoVars = {}
    DefaultHeader = {}
    CurrDefaultInfoVarIdx = 0
    sequence pvars = cfg:list_vars("", "Projects")
    object varval
    if length(pvars) = 0 then
        DefaultInfoVars = InitialInfoVars
        DefaultHeader = InitialHeader
        dosave = 1
    else
        for v = 1 to length(pvars) do
            if match("DefaultInfoVar.", pvars[v]) = 1 then
                varval = cfg:get_var("", "Projects", pvars[v])
                if sequence(varval) then
                    --varval = escape(varval)
                    DefaultInfoVars &= {{pvars[v][16..$], split(varval, "\\n")}}
                end if
            elsif match("DefaultHeader.", pvars[v]) = 1 then
                varval = cfg:get_var("", "Projects", pvars[v])
                if sequence(varval) then
                    --varval = escape(varval)
                    DefaultHeader &= {varval}
                end if
            end if
        end for
    end if
    
    cfg:delete_section("", "Projects")
    for v = 1 to length(DefaultInfoVars) do
        cfg:set_var("", "Projects", "DefaultInfoVar." & DefaultInfoVars[v][1], join(DefaultInfoVars[v][2], "\\n"))
    end for
    for v = 1 to length(DefaultHeader) do
        cfg:set_var("", "Projects", "DefaultHeader." & sprint(v), DefaultHeader[v])
    end for
    
    if not equal(prevConfigPath, ConfigPath) or not equal(prevTemplatePath, TemplatePath) or not equal(prevProjectPath, ProjectPath) or not equal(prevEubinPath, EubinPath) or not equal(prevIncludePath, IncludePath) then
        dosave = 1
    end if
    
    if dosave then
        cfg:save_config("")
    end if
    --msg:publish("config", "command", "refresh_projects", 0)
    
end procedure


procedure path_error(sequence patherr)
    if length(patherr) > 0 then
        sequence errtxt = "Invalid path: "
        
        action:do_proc("show_preferences", {})
        
        gui:wproc("winPreferences.tabCategories", "select_tab_by_widget", {"winPreferences.cntPathsTab"})
        
        
        for p = 1 to length(patherr)-1 do
            errtxt &= patherr[p] & ", "
        end for
        errtxt &= patherr[$]
        msgbox:msg(errtxt, "Error")
    end if
end procedure


procedure save_prefs()
    sequence patherr = {}
    
    TemplatePath = gui:wfunc("winPreferences.txtTemplatePath", "get_text", {})
    ProjectPath = gui:wfunc("winPreferences.txtProjectPath", "get_text", {})
    EubinPath = gui:wfunc("winPreferences.txtEubinPath", "get_text", {})
    IncludePath = gui:wfunc("winPreferences.txtIncludePath", "get_text", {})
    --RedyLibPath = gui:wfunc("winPreferences.txtRedyLibPath", "get_text", {})
        
    if file_exists(TemplatePath) then
        cfg:set_var("", "Paths", "TemplatePath", filesys:pathname(TemplatePath & "\\"))
    else
        ProjectPath = ""
        patherr &= {"Templates"}
    end if
    if file_exists(ProjectPath) then
        cfg:set_var("", "Paths", "ProjectPath", filesys:pathname(ProjectPath & "\\"))
    else
        ProjectPath = ""
        patherr &= {"Projects"}
    end if
    if file_exists(EubinPath) then
        cfg:set_var("", "Paths", "EubinPath", filesys:pathname(EubinPath & "\\"))
    else
        EubinPath = ""
        patherr &= {"Euphoria"}
    end if
    if file_exists(IncludePath) then
        cfg:set_var("", "Paths", "IncludePath", filesys:pathname(IncludePath & "\\"))
    else
        IncludePath = ""
        patherr &= {"Includes"}
    end if
    --if file_exists(RedyLibPath) then
    --    cfg:set_var("", "Paths", "RedyLibPath", RedyLibPath)
    --else
    --    RedyLibPath = ""
    --end if
    
    cfg:delete_section("", "Projects")
    
    for v = 1 to length(DefaultInfoVars) do
        cfg:set_var("", "Projects", "DefaultInfoVar." & DefaultInfoVars[v][1], join(DefaultInfoVars[v][2], "\\n"))
    end for
    DefaultHeader = gui:wfunc("winPreferences.txtDefaultHeader", "get_text", {})
    for v = 1 to length(DefaultHeader) do
        cfg:set_var("", "Projects", "DefaultHeader." & sprint(v), DefaultHeader[v])
    end for
    
    cfg:save_config("")
    
    action:do_proc("project_refresh", {})
    
end procedure


procedure refresh_infovar_list()
    sequence itms = {}
    for i = 1 to length(DefaultInfoVars) do
        itms &= {{rgb(255, 255, 255), DefaultInfoVars[i][1], join(DefaultInfoVars[i][2], "\\n")}}
    end for
    gui:wproc("winPreferences.lstDefaultInfoVars", "set_list_items", {itms})
end procedure


export procedure gui_event(object evwidget, object evtype, object evdata)
    switch evwidget do
    case "winPreferences.txtTemplatePath" then
        
    case "winPreferences.btnTemplatePath" then
        object selfiles = dlgfile:os_select_open_file("winPreferences", {{"RedyCode Template", "TempMain.exw"}}, 0)
        if sequence(selfiles) then
            object flist = split_path(pathname(selfiles))
            if length(flist) > 1 then
                gui:wproc("winPreferences.txtTemplatePath", "set_text", {join_path(flist[1..$-1])})
            end if
        end if


    case "winPreferences.txtProjectPath" then
        
    case "winPreferences.btnProjectPath" then
        object selfiles = dlgfile:os_select_open_file("winPreferences", {{"RedyCode Project", "*.redy"}}, 0)
        if sequence(selfiles) then
            object flist = split_path(pathname(selfiles))
            if length(flist) > 1 then
                gui:wproc("winPreferences.txtProjectPath", "set_text", {join_path(flist[1..$-1])})
            end if
        end if
        
    case "winPreferences.txtEubinPath" then
        
    case "winPreferences.btnEubinPath" then
        object selfiles = dlgfile:os_select_open_file("winPreferences", {{"Euphoria Interpretor", "eui.exe"}}, 0)
        if sequence(selfiles) then
            gui:wproc("winPreferences.txtEubinPath", "set_text", {pathname(selfiles)})
        end if
        
    case "winPreferences.txtIncludePath" then
        
    case "winPreferences.btnIncludePath" then
        object selfiles = dlgfile:os_select_open_file("winPreferences", {{"Euphoria Include Path", "euphoria.h"}}, 0)
        if sequence(selfiles) then
            gui:wproc("winPreferences.txtIncludePath", "set_text", {pathname(selfiles)})
        end if
        
    --case "winPreferences.txtRedyLibPath" then
    --    
    --case "winPreferences.btnRedyLibPath" then
    --    object selfiles = dlgfile:os_select_open_file("winPreferences", {{"Redylib Path", "redylib.txt"}}, 0)
    --    if sequence(selfiles) then
    --        gui:wproc("winPreferences.txtRedyLibPath", "set_text", {pathname(selfiles)})
    --    end if
        
    case "winPreferences.btnReset" then
        TemplatePath = 0
        ProjectPath = 0
        EubinPath = 0
        IncludePath = 0
        detect_paths()
        TemplatePath = cfg:get_var("", "Paths", "TemplatePath")
        ProjectPath = cfg:get_var("", "Paths", "ProjectPath")
        EubinPath = cfg:get_var("", "Paths", "EubinPath")
        IncludePath = cfg:get_var("", "Paths", "IncludePath")
        gui:wproc("winPreferences.txtTemplatePath", "set_text", {TemplatePath})
        gui:wproc("winPreferences.txtProjectPath", "set_text", {ProjectPath})
        gui:wproc("winPreferences.txtEubinPath", "set_text", {EubinPath})
        gui:wproc("winPreferences.txtIncludePath", "set_text", {IncludePath})
           
    case "winPreferences.lstDefaultInfoVars" then
        if equal(evtype, "selection") then
            if length(evdata) > 0 then
                CurrDefaultInfoVarIdx = evdata[1][1]
                gui:wproc("winPreferences.txtVarName", "set_text", {evdata[1][2][1]})
                gui:wproc("winPreferences.txtVarString", "set_text", {split(evdata[1][2][2], "\\n")})
            else
                CurrDefaultInfoVarIdx = 0
                gui:wproc("winPreferences.txtVarName", "set_text", {""})
                gui:wproc("winPreferences.txtVarString", "set_text", {""})
            end if
        elsif equal(evtype, "left_double_click") then
            if sequence(evdata) and length(evdata) > 0 then
                gui:wproc("winPreferences.txtDefaultHeader", "insert_text", {"$" & evdata[1][2][1]})
            end if
        end if
        
    case "winPreferences.txtVarName" then
        if equal(evtype, "changed") then
            sequence txt = gui:wfunc("winPreferences.txtVarName", "get_text", {})
            if CurrDefaultInfoVarIdx > 0 and CurrDefaultInfoVarIdx <= length(DefaultInfoVars) then
                DefaultInfoVars[CurrDefaultInfoVarIdx][1] = flatten(txt)
                refresh_infovar_list()
            end if
        end if
        
    case "winPreferences.txtVarString" then
        if equal(evtype, "changed") then
            sequence txt = gui:wfunc("winPreferences.txtVarString", "get_text", {})
            if CurrDefaultInfoVarIdx > 0 and CurrDefaultInfoVarIdx <= length(DefaultInfoVars) then
                DefaultInfoVars[CurrDefaultInfoVarIdx][2] = txt
                refresh_infovar_list()
            end if
        end if
        
    case "winPreferences.btnDefaultInfoVarsAdd" then
        if CurrDefaultInfoVarIdx > 0 and CurrDefaultInfoVarIdx <= length(DefaultInfoVars) then
            DefaultInfoVars = DefaultInfoVars[1..CurrDefaultInfoVarIdx] & {{"NewVar", {"NewString"}}} & DefaultInfoVars[CurrDefaultInfoVarIdx+1..$]
            CurrDefaultInfoVarIdx += 1
        else
            DefaultInfoVars &= {{"NewVar", {"NewString"}}}
            CurrDefaultInfoVarIdx = length(DefaultInfoVars)
        end if
        refresh_infovar_list()
        gui:wproc("winPreferences.lstDefaultInfoVars", "select_items", {{CurrDefaultInfoVarIdx}})
        
    case "winPreferences.btnDefaultInfoVarsRemove" then
        if CurrDefaultInfoVarIdx > 0 and CurrDefaultInfoVarIdx <= length(DefaultInfoVars) then
            DefaultInfoVars = remove(DefaultInfoVars, CurrDefaultInfoVarIdx)
            if CurrDefaultInfoVarIdx > length(DefaultInfoVars) then
                CurrDefaultInfoVarIdx = length(DefaultInfoVars)
            end if
        end if
        refresh_infovar_list()
        gui:wproc("winPreferences.lstDefaultInfoVars", "select_items", {{CurrDefaultInfoVarIdx}})
        
    case "winPreferences.btnDefaultInfoVarsInsert" then
        if CurrDefaultInfoVarIdx > 0 and CurrDefaultInfoVarIdx <= length(DefaultInfoVars) then
            gui:wproc("winPreferences.txtDefaultHeader", "insert_text", {"$" & DefaultInfoVars[CurrDefaultInfoVarIdx][1]})
        end if
    case "winPreferences.btnDefaultInfoVarTextLoad" then
        object selfiles = dlgfile:os_select_open_file("winPreferences", {{"Text Files", "*.txt"}, {"All Files", "*.*"}}, 0)
        if sequence(selfiles) then
            object txt = read_file(selfiles)
            if sequence(txt) then
                gui:wproc("winPreferences.txtVarString", "set_text", {txt})
            end if
        end if
        
    case "winPreferences.btnDefaultInfoVarsReset" then
        DefaultInfoVars = InitialInfoVars
        if CurrDefaultInfoVarIdx > length(DefaultInfoVars) then
            CurrDefaultInfoVarIdx = length(DefaultInfoVars)
        end if
        refresh_infovar_list()
        gui:wproc("winPreferences.lstDefaultInfoVars", "select_items", {{CurrDefaultInfoVarIdx}})
        
    case "winPreferences.txtDefaultHeader" then
    case "winPreferences.btnDefaultHeaderLoad" then
        object selfiles = dlgfile:os_select_open_file("winPreferences", {{"Text Files", "*.txt"}, {"All Files", "*.*"}}, 0)
        if sequence(selfiles) then
            object txt = read_file(selfiles)
            if sequence(txt) then
                gui:wproc("winPreferences.txtDefaultHeader", "set_text", {txt})
            end if
        end if
        
    case  "winPreferences.btnDefaultHeaderReset" then
        DefaultHeader = InitialHeader
        gui:wproc("winPreferences.txtDefaultHeader", "set_text", {InitialHeader})
        
    case "winPreferences.lstControls" then
    case "winPreferences.txtMonoFont" then
    case "winPreferences.txtMonoFontSize" then
    case "winPreferences.txtScrollPast" then
    case "winPreferences.txtViewShift" then
    case "winPreferences.txtActiveSelBackColor" then
    case "winPreferences.txtActiveSelTextColor" then
    case "winPreferences.txtInactiveSelBackColor" then
    case "winPreferences.txtInactiveSelTextColor" then
    case "winPreferences.txtActiveCurrLineBkColor" then
    case "winPreferences.txtInactiveCurrLineBkColor" then
    case "winPreferences.txtCursorColor" then
    case "winPreferences.chkEnableHighlighting" then
        
    case "winPreferences.btnOk" then
        save_prefs()
        gui:wdestroy("winPreferences")
        check_config()
        
    case "winPreferences.btnCancel" then
        cfg:close_config("")
        cfg:load_config("")
        gui:wdestroy("winPreferences")
        check_config()
        
    case "winPreferences" then
        if equal(evtype, "closed") then
            gui:wdestroy("winPreferences")
        end if
    
    end switch
end procedure


procedure do_show_preferences()
    if gui:wexists("winPreferences") then
        gui:set_window_top(gui:widget_get_handle("winPreferences"))
        return
    end if
    
    --check_config()
    --cfg:clear_config("")
    --cfg:load_config("")
    
    gui:wcreate({
        {"name", "winPreferences"},
        {"class", "window"},
        {"mode", "window"},
        {"handler", routine_id("gui_event")},
        {"title", "Preferences"},
        --{"topmost", 1},
        {"size", {800, 600}}
    })
    gui:wcreate({
        {"name", "winPreferences.cntMain"},
        {"parent", "winPreferences"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    gui:wcreate({
        {"name", "winPreferences.tabCategories"},
        {"parent", "winPreferences.cntMain"},
        {"class", "tabs"}
        --{"orientation", "vertical"},
        --{"sizemode_x", "expand"},
        --{"sizemode_y", "expand"}
    })
    
    
-- Paths Tab --------------------------------------
    gui:wcreate({
        {"name", "winPreferences.cntPathsTab"},
        {"parent", "winPreferences.tabCategories"},
        {"class", "container"},
        {"label", "Paths"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    -- Template path
    gui:wcreate({
        {"name",  "winPreferences.txtTemplatePath"},
        {"parent",  "winPreferences.cntPathsTab"},
        {"class", "textbox"},
        {"label", "Default Template Path"},
        {"text", TemplatePath}
    })
    gui:wcreate({
        {"name", "winPreferences.cntTemplatePath"},
        {"parent", "winPreferences.cntPathsTab"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"justify_x", "left"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"}
    })
    gui:wcreate({
        {"name",  "winPreferences.btnTemplatePath"},
        {"parent",  "winPreferences.cntTemplatePath"},
        {"class", "button"},
        {"label", "Select Template Path..."}
    })
    -- Project path
    gui:wcreate({
        {"name",  "winPreferences.txtProjectPath"},
        {"parent",  "winPreferences.cntPathsTab"},
        {"class", "textbox"},
        {"label", "Default Project Path"},
        {"text", ProjectPath}
    })
    gui:wcreate({
        {"name", "winPreferences.cntProjectPath"},
        {"parent", "winPreferences.cntPathsTab"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"justify_x", "left"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"}
    })
    gui:wcreate({
        {"name",  "winPreferences.btnProjectPath"},
        {"parent",  "winPreferences.cntProjectPath"},
        {"class", "button"},
        {"label", "Select Project Path..."}
    })
    -- location of eui
    gui:wcreate({
        {"name",  "winPreferences.txtEubinPath"},
        {"parent",  "winPreferences.cntPathsTab"},
        {"class", "textbox"},
        {"label", "Default Euphoria Path"},
        {"text", EubinPath}
    })
    gui:wcreate({
        {"name", "winPreferences.cntEubinPath"},
        {"parent", "winPreferences.cntPathsTab"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"justify_x", "left"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"}
    })
    gui:wcreate({
        {"name",  "winPreferences.btnEubinPath"},
        {"parent",  "winPreferences.cntEubinPath"},
        {"class", "button"},
        {"label", "Select Euphoria Path..."}
    })
    -- location of include
    gui:wcreate({
        {"name",  "winPreferences.txtIncludePath"},
        {"parent",  "winPreferences.cntPathsTab"},
        {"class", "textbox"},
        {"label", "Default Include Path"},
        {"text", IncludePath}
    })
    gui:wcreate({
        {"name", "winPreferences.cntIncludePath"},
        {"parent", "winPreferences.cntPathsTab"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"justify_x", "left"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"}
    })
    gui:wcreate({
        {"name",  "winPreferences.btnIncludePath"},
        {"parent",  "winPreferences.cntIncludePath"},
        {"class", "button"},
        {"label", "Select Include Path..."}
    })
    gui:wcreate({
        {"name", "winPreferences.cntReset"},
        {"parent", "winPreferences.cntPathsTab"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"justify_x", "left"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"}
    })
    gui:wcreate({
        {"name",  "winPreferences.btnReset"},
        {"parent",  "winPreferences.cntReset"},
        {"class", "button"},
        {"label", "Rescan Paths"}
    })
    


-- Projects Tab --------------------------------------
    gui:wcreate({
        {"name", "winPreferences.cntProjectsTab"},
        {"parent", "winPreferences.tabCategories"},
        {"class", "container"},
        {"label", "Projects"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name",  "winPreferences.lstDefaultInfoVars"},
        {"parent",  "winPreferences.cntProjectsTab"},
        {"class", "listbox"},
        {"label", "Default App Info Variables"},
        {"text", ""}
    })
    gui:wproc("winPreferences.lstDefaultInfoVars", "add_column", {{"Name", 150, 0, 0}})
    gui:wproc("winPreferences.lstDefaultInfoVars", "add_column", {{"Text", 300, 0, 0}})
    refresh_infovar_list()
    gui:wcreate({
        {"name",  "winPreferences.txtVarName"},
        {"parent",  "winPreferences.cntProjectsTab"},
        {"class", "textbox"},
        {"label", "Variable Name"},
        {"mode", "string"}
    })
    gui:wcreate({
        {"name",  "winPreferences.txtVarString"},
        {"parent",  "winPreferences.cntProjectsTab"},
        {"class", "textbox"},
        {"label", "Variable Text"},
        {"mode", "text"},
        {"monowidth", 1}
    })
    gui:wcreate({
        {"name", "winPreferences.cntDefaultInfoVars"},
        {"parent", "winPreferences.cntProjectsTab"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"justify_x", "left"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"}
    })
    gui:wcreate({
        {"name",  "winPreferences.btnDefaultInfoVarsAdd"},
        {"parent",  "winPreferences.cntDefaultInfoVars"},
        {"class", "button"},
        {"label", "Add"}
    })
    gui:wcreate({
        {"name",  "winPreferences.btnDefaultInfoVarsRemove"},
        {"parent",  "winPreferences.cntDefaultInfoVars"},
        {"class", "button"},
        {"label", "Remove"}
    })
    gui:wcreate({
        {"name",  "winPreferences.btnDefaultInfoVarsInsert"},
        {"parent",  "winPreferences.cntDefaultInfoVars"},
        {"class", "button"},
        {"label", "Insert into Header"}
    })
    gui:wcreate({
        {"name",  "winPreferences.btnDefaultInfoVarTextLoad"},
        {"parent",  "winPreferences.cntDefaultInfoVars"},
        {"class", "button"},
        {"label", "Load Text File..."}
    })
    gui:wcreate({
        {"name",  "winPreferences.btnDefaultInfoVarsReset"},
        {"parent",  "winPreferences.cntDefaultInfoVars"},
        {"class", "button"},
        {"label", "Load Defaults"}
    })
    
    gui:wcreate({
        {"name",  "winPreferences.txtDefaultHeader"},
        {"parent",  "winPreferences.cntProjectsTab"},
        {"class", "textbox"},
        {"label", "Default Source File Header"},
        {"mode", "text"},
        {"label_position", "above"},
        {"monowidth", 1},
        {"text", DefaultHeader}
    })
    gui:wcreate({
        {"name", "winPreferences.cntDefaultHeader"},
        {"parent", "winPreferences.cntProjectsTab"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"justify_x", "left"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"}
    })
    gui:wcreate({
        {"name",  "winPreferences.btnDefaultHeaderLoad"},
        {"parent",  "winPreferences.cntDefaultHeader"},
        {"class", "button"},
        {"label", "Load Text File..."}
    })
    gui:wcreate({
        {"name",  "winPreferences.btnDefaultHeaderReset"},
        {"parent",  "winPreferences.cntDefaultHeader"},
        {"class", "button"},
        {"label", "Load Default"}
    })
    
    /*
-- Tools Tab --------------------------------------
    gui:wcreate({
        {"name", "winPreferences.cntToolsTab"},
        {"parent", "winPreferences.tabCategories"},
        {"class", "container"},
        {"label", "Tools"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    -- code templates
    gui:wcreate({
        {"name",  "winPreferences.lstTemplates"},
        {"parent",  "winPreferences.cntToolsTab"},
        {"class", "listbox"},
        {"label", "Code Templates"}
    })
    -- IndentSpace
    gui:wcreate({
        {"name",  "winPreferences.txtTabs"},
        {"parent",  "winPreferences.cntToolsTab"},
        {"class", "textbox"},
        {"label", "Smart Tabs"},
        {"text", ""}
    })

    
-- Controls Tab --------------------------------------
    gui:wcreate({
        {"name", "winPreferences.cntControlsTab"},
        {"parent", "winPreferences.tabCategories"},
        {"class", "container"},
        {"label", "Controls"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name",  "winPreferences.lstControls"},
        {"parent",  "winPreferences.cntControlsTab"},
        {"class", "listbox"},
        {"label", "Customize Controls"}
    })
    gui:wproc("winPreferences.lstControls", "clear_list", {})
    gui:wproc("winPreferences.lstControls", "add_column", {{"Key Combo", 100, 0, 0}})
    gui:wproc("winPreferences.lstControls", "add_column", {{"Command", 300, 0, 0}})
    gui:wproc("winPreferences.lstControls", "add_list_items", {{
        {rgb(127, 127, 255), "Ctrl+X", "Cut"},
        {rgb(127, 127, 255), "Ctrl+C", "Copy"},
        {rgb(127, 127, 255), "Ctrl+V", "Paste"},
        {rgb(127, 127, 255), "Ctrl+A", "Select All"}
    }})
    
    
-- Editor Tab --------------------------------------
    gui:wcreate({
        {"name", "winPreferences.cntEditorTab"},
        {"parent", "winPreferences.tabCategories"},
        {"class", "container"},
        {"label", "Editor"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
-- thMonoFonts = {"Courier New", "Consolas"}, --, "DejaVu Sans Mono", "Liberation Mono"}
    gui:wcreate({
        {"name",  "winPreferences.txtMonoFont"},
        {"parent",  "winPreferences.cntEditorTab"},
        {"class", "textbox"},
        {"label", "Editor Font"},
        {"text", "Courier New"}
    })
-- thMonoFontSize = 10,
    gui:wcreate({
        {"name",  "winPreferences.txtMonoFontSize"},
        {"parent",  "winPreferences.cntEditorTab"},
        {"class", "textbox"},
        {"label", "Editor Font Size"},
        {"text", "10"}
    })
    
-- thBackColor = th:cInnerFill, --th:cButtonFace
    gui:wcreate({
        {"name",  "winPreferences.txtBackColor"},
        {"parent",  "winPreferences.cntEditorTab"},
        {"class", "textbox"},
        {"label", "Editor Back Color"},
        {"text", ""}
    })
-- optScrollPast = 0.5,  --amount to scroll past bottom line (must be in the range of 0 to 1.0)
    gui:wcreate({
        {"name",  "winPreferences.txtScrollPast"},
        {"parent",  "winPreferences.cntEditorTab"},
        {"class", "textbox"},
        {"label", "Scroll Past Amount"},
        {"text", "50%"}
    })
-- optViewShift = 0.8,  --amount to scroll up or down to keep active line in view (must be in the range of 0 to 1.0)
    gui:wcreate({
        {"name",  "winPreferences.txtViewShift"},
        {"parent",  "winPreferences.cntEditorTab"},
        {"class", "textbox"},
        {"label", "View Shift Amount"},
        {"text", "80%"}
    })
    
-- optActiveSelBackColor = th:cInnerSel, --rgb(80, 80, 150)
    gui:wcreate({
        {"name",  "winPreferences.txtActiveSelBackColor"},
        {"parent",  "winPreferences.cntEditorTab"},
        {"class", "textbox"},
        {"label", "Active Sel Back Color"},
        {"text", ""}
    })
-- optActiveSelTextColor = th:cInnerTextSel, --rgb(255, 255, 255)
    gui:wcreate({
        {"name",  "winPreferences.txtActiveSelTextColor"},
        {"parent",  "winPreferences.cntEditorTab"},
        {"class", "textbox"},
        {"label", "Active Sel Text Color"},
        {"text", ""}
    })
-- optInactiveSelBackColor = th:cInnerSelInact
    gui:wcreate({
        {"name",  "winPreferences.txtInactiveSelBackColor"},
        {"parent",  "winPreferences.cntEditorTab"},
        {"class", "textbox"},
        {"label", "Inactive Sel Back Color"},
        {"text", ""}
    })
-- optInactiveSelTextColor = th:cInnerTextSelInact
    gui:wcreate({
        {"name",  "winPreferences.txtInactiveSelTextColor"},
        {"parent",  "winPreferences.cntEditorTab"},
        {"class", "textbox"},
        {"label", "Inactive Sel Text Color"},
        {"text", ""}
    })
-- optActiveCurrLineBkColor = rgb(250, 250, 180)
    gui:wcreate({
        {"name",  "winPreferences.txtActiveCurrLineBkColor"},
        {"parent",  "winPreferences.cntEditorTab"},
        {"class", "textbox"},
        {"label", "Active Curr Line Bk Color"},
        {"text", ""}
    })
-- optInactiveCurrLineBkColor = rgb(220, 220, 220)
    gui:wcreate({
        {"name",  "winPreferences.txtInactiveCurrLineBkColor"},
        {"parent",  "winPreferences.cntEditorTab"},
        {"class", "textbox"},
        {"label", "Inactive Curr Line Bk Color"},
        {"text", ""}
    })
-- optCursorColor = rgb(80, 80, 250)
    gui:wcreate({
        {"name",  "winPreferences.txtCursorColor"},
        {"parent",  "winPreferences.cntEditorTab"},
        {"class", "textbox"},
        {"label", "Cursor Color"},
        {"text", ""}
    })


-- Highlighter Tab --------------------------------------
    gui:wcreate({
        {"name", "winPreferences.cntHighlightingTab"},
        {"parent", "winPreferences.tabCategories"},
        {"class", "container"},
        {"label", "Highlighting"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    --enable highlighting
    gui:wcreate({
        {"name",  "winPreferences.chkEnableHighlighting"},
        {"parent",  "winPreferences.cntHighlightingTab"},
        {"class", "toggle"},
        {"label", "Enable syntax highlighting"},
        {"value", 1}
    })
    
    -- ttStyles = repeat({}, ttComment) --token styles: {textfont, textsize, textstyle, textcolor}
    -- ttStyles[ttNone] = {Normal, th:cButtonLabel}
    -- ttStyles[ttInvalid] = {Normal, th:cButtonLabel}
    -- ttStyles[ttFound] = {Normal, th:cButtonLabel}
    -- ttStyles[ttIdentifier] = {Normal, rgb(100, 0, 0)}
    -- ttStyles[ttKeyword] = {Bold, rgb(0, 0, 100)}
    -- ttStyles[ttBuiltin] = {Bold, rgb(0, 0, 128)}
    -- ttStyles[ttNumber] = {Normal, rgb(0, 0, 80)}
    -- ttStyles[ttSymbol] = {Normal, rgb(0, 0, 0)}
    -- ttStyles[ttBracket] = {Normal,  rgb(200, 0, 0)}
    -- ttStyles[ttString] = {Normal, rgb(0, 128, 0)}
    -- ttStyles[ttComment] = {Italic, rgb(120, 100, 160)}
    
    */
    
    gui:wcreate({
        {"name", "winPreferences.cntBottom"},
        {"parent", "winPreferences.cntMain"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "equal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"}
    })
    gui:wcreate({
        {"name", "winPreferences.btnOk"},
        {"parent", "winPreferences.cntBottom"},
        {"class", "button"},
        {"label", "OK"}
    })
    gui:wcreate({
        {"name", "winPreferences.btnCancel"},
        {"parent", "winPreferences.cntBottom"},
        {"class", "button"},
        {"label", "Cancel"}
    })
    
    --gui:wproc("winPreferences.tabCategories", "select_tab", {"Paths"})
    gui:wproc("winPreferences.tabCategories", "select_tab", {1})
end procedure

















