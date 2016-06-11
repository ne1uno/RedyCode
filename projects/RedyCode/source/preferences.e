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
         

object TemplatePath, ProjectPath, EuiPath, EubindPath, IncludePath


action:define({
    {"name", "show_preferences"},
    {"do_proc", routine_id("do_show_preferences")},
    {"label", "Preferences..."},
    {"icon", "preferences-desktop"},
    {"description", "Show Preferences dialog"}
})




procedure check_config()
    
    TemplatePath = cfg:get_var("", "Projects", "TemplatePath")
    ProjectPath = cfg:get_var("", "Projects", "ProjectPath")
    EuiPath = cfg:get_var("", "Projects", "EuiPath")
    EubindPath = cfg:get_var("", "Projects", "EubindPath")
    IncludePath = cfg:get_var("", "Projects", "IncludePath")
    
    object
    prevTemplatePath = TemplatePath,
    prevProjectPath = ProjectPath,
    prevEuiPath = EuiPath,
    prevEubindPath = EubindPath,
    prevIncludePath = IncludePath 
    
    
    if not sequence(TemplatePath) then
        TemplatePath = ExePath & "\\templates"
        if not file_exists(TemplatePath) then
            TemplatePath = ExePath & "\\..\\..\\..\\templates"
        end if
        if not file_exists(TemplatePath) then
            TemplatePath = "C:\\RedyCode\\templates"
        end if
    end if
    if not sequence(ProjectPath) then
        ProjectPath = ExePath & "\\projects"
        if not file_exists(ProjectPath) then
            ProjectPath = ExePath & "\\..\\.."
        end if
        if not file_exists(ProjectPath) then
            ProjectPath = "C:\\RedyCode\\projects"
        end if
    end if
    
    if not sequence(EuiPath) then
        ifdef WINDOWS then
            EuiPath = ExePath & "\\euphoria\\bin\\euiw.exe"
            if not file_exists(EuiPath) then
                EuiPath = ExePath & "\\..\\..\\..\\euphoria\\bin\\euiw.exe"
            end if
            if not file_exists(EuiPath) then
                EuiPath = "C:\\RedyCode\\euphoria\\bin\\euiw.exe"
            end if
        elsedef
            EuiPath = ExePath & "\\euphoria\\bin\\eui.exe"
            if not file_exists(EuiPath) then
                EuiPath = ExePath & "\\..\\..\\..\\euphoria\\bin\\eui.exe"
            end if
            if not file_exists(EuiPath) then
                EuiPath = "C:\\RedyCode\\euphoria\\bin\\eui.exe"
            end if
        end ifdef
    end if
    
    if not sequence(EubindPath) then
        EubindPath = ExePath & "\\euphoria\\bin\\eubind.exe"
        if not file_exists(EubindPath) then
            EubindPath = ExePath & "\\..\\..\\..\\euphoria\\bin\\eubind.exe"
        end if
        if not file_exists(EubindPath) then
            EubindPath = "C:\\RedyCode\\euphoria\\bin\\eubind.exe"
        end if
    end if
    
    if not sequence(IncludePath) then
        IncludePath = ExePath & "\\euphoria\\include"
        if not file_exists(IncludePath) then
            IncludePath = ExePath & "\\..\\..\\..\\euphoria\\include"
        end if
        if not file_exists(IncludePath) then
            IncludePath = "C:\\RedyCode\\euphoria\\include"
        end if
    end if
    
    if file_exists(TemplatePath) then
        cfg:set_var("", "Projects", "TemplatePath", filesys:pathname(TemplatePath & "\\"))
    else
        TemplatePath = ""
    end if
    if file_exists(ProjectPath) then
        cfg:set_var("", "Projects", "ProjectPath", filesys:pathname(ProjectPath & "\\"))
    else
        ProjectPath = ""
    end if
    if file_exists(EuiPath) then
        cfg:set_var("", "Projects", "EuiPath", filesys:pathname(EuiPath) & "\\" & filesys:filename(EuiPath))
    else
        EuiPath = ""
    end if
    if file_exists(EubindPath) then
        cfg:set_var("", "Projects", "EubindPath", filesys:pathname(EubindPath) & "\\" & filesys:filename(EubindPath))
    else
        EubindPath = ""
    end if
    if file_exists(IncludePath) then
        cfg:set_var("", "Projects", "IncludePath", filesys:pathname(IncludePath & "\\"))
    else
        IncludePath = ""
    end if
    --if file_exists(RedyLibPath) then
    --    cfg:set_var("", "Projects", "RedyLibPath", RedyLibPath)
    --else
    --    RedyLibPath = ""
    --end if
    
    if not equal(prevTemplatePath, TemplatePath)
    or not equal(prevProjectPath, ProjectPath)
    or not equal(prevEuiPath, EuiPath)
    or not equal(prevEubindPath, EubindPath)
    or not equal(prevIncludePath, IncludePath) 
    then
        cfg:save_config("")
    end if
    --msg:publish("config", "command", "refresh_projects", 0)
end procedure


procedure save_prefs()
    TemplatePath = gui:wfunc("winPreferences.txtTemplatePath", "get_text", {})
    ProjectPath = gui:wfunc("winPreferences.txtProjectPath", "get_text", {})
    EuiPath = gui:wfunc("winPreferences.txtEuiPath", "get_text", {})
    EubindPath = gui:wfunc("winPreferences.txtEubindPath", "get_text", {})
    IncludePath = gui:wfunc("winPreferences.txtIncludePath", "get_text", {})
    --RedyLibPath = gui:wfunc("winPreferences.txtRedyLibPath", "get_text", {})
    
    if file_exists(TemplatePath) then
        cfg:set_var("", "Projects", "TemplatePath", filesys:pathname(TemplatePath & "\\"))
    else
        ProjectPath = ""
    end if
    if file_exists(ProjectPath) then
        cfg:set_var("", "Projects", "ProjectPath", filesys:pathname(ProjectPath & "\\"))
    else
        ProjectPath = ""
    end if
    if file_exists(EuiPath) then
        cfg:set_var("", "Projects", "EuiPath", filesys:pathname(EuiPath) & "\\" & filesys:filename(EuiPath))
    else
        EuiPath = ""
    end if
    if file_exists(EubindPath) then
        cfg:set_var("", "Projects", "EubindPath", filesys:pathname(EubindPath) & "\\" & filesys:filename(EubindPath))
    else
        EubindPath = ""
    end if
    if file_exists(IncludePath) then
        cfg:set_var("", "Projects", "IncludePath", filesys:pathname(IncludePath & "\\"))
    else
        IncludePath = ""
    end if
    --if file_exists(RedyLibPath) then
    --    cfg:set_var("", "Projects", "RedyLibPath", RedyLibPath)
    --else
    --    RedyLibPath = ""
    --end if
    
    cfg:save_config("")
    
    --msg:publish("config", "command", "refresh_projects", 0)
    
end procedure


export procedure gui_event(object evwidget, object evtype, object evdata)
    switch evwidget do
        case "winPreferences.txtTemplatePath" then
            
        case "winPreferences.btnTemplatePath" then
            object selfiles = dlgfile:os_select_open_file("winPreferences", {{"RedyCode Template", "TempMain.exw"}}, 0)
            if sequence(selfiles) then
                object flist = split_path(pathname(selfiles))
                for f = length(flist) to 1 by -1 do
                    if equal(lower(flist[f]), "templates") then
                        gui:wproc("winPreferences.txtTemplatePath", "set_text", {join_path(flist[1..f])})
                        exit
                    end if
                end for
            end if
    
    
        case "winPreferences.txtProjectPath" then
            
        case "winPreferences.btnProjectPath" then
            object selfiles = dlgfile:os_select_open_file("winPreferences", {{"RedyCode Project", "*.redy"}}, 0)
            if sequence(selfiles) then
                object flist = split_path(pathname(selfiles))
                for f = length(flist) to 1 by -1 do
                    if equal(lower(flist[f]), "projects") then
                        gui:wproc("winPreferences.txtProjectPath", "set_text", {join_path(flist[1..f])})
                        exit
                    end if
                end for
            end if
            
        case "winPreferences.txtEuiPath" then
            
        case "winPreferences.btnEuiPath" then
            object selfiles
            ifdef WINDOWS then
                selfiles = dlgfile:os_select_open_file("winPreferences", {{"Euphoria Interpretor", "euiw.exe"}}, 0)
            elsedef
                selfiles = dlgfile:os_select_open_file("winPreferences", {{"Euphoria Interpretor", "eui.exe"}}, 0)
            end ifdef
            if sequence(selfiles) then
                gui:wproc("winPreferences.txtEuiPath", "set_text", {selfiles})
            end if
            
        case "winPreferences.txtEubindPath" then
            
        case "winPreferences.btnEubindPath" then
            object selfiles = dlgfile:os_select_open_file("winPreferences", {{"Euphoria Binder", "eubind.exe"}}, 0)
            if sequence(selfiles) then
                gui:wproc("winPreferences.txtEubindPath", "set_text", {selfiles})
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
            
        case "winPreferences.txtVersion" then
        case "winPreferences.txtAuthor" then
        case "winPreferences.txtLicense" then
        case "winPreferences.btnLicenseFile" then
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
            
        case "winPreferences.btnCancel" then
            gui:wdestroy("winPreferences")
            
        case "winPreferences" then
            if equal(evtype, "closed") then
                gui:wdestroy("winPreferences")
            end if
        
    end switch
end procedure


procedure do_show_preferences()
    if gui:wexists("winPreferences") then
         return
    end if
    check_config()
    
    gui:wcreate({
        {"name", "winPreferences"},
        {"class", "window"},
        {"mode", "window"},
        {"handler", routine_id("gui_event")},
        {"title", "Preferences"},
        --{"topmost", 1},
        {"size", {550, 450}}
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
    
    
-- Paths Tab
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
        {"label", "Select Folder..."}
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
        {"label", "Select Folder..."}
    })
    -- location of eui
    gui:wcreate({
        {"name",  "winPreferences.txtEuiPath"},
        {"parent",  "winPreferences.cntPathsTab"},
        {"class", "textbox"},
        {"label", "Default Eui Path"},
        {"text", EuiPath}
    })
    gui:wcreate({
        {"name", "winPreferences.cntEuiPath"},
        {"parent", "winPreferences.cntPathsTab"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"justify_x", "left"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"}
    })
    gui:wcreate({
        {"name",  "winPreferences.btnEuiPath"},
        {"parent",  "winPreferences.cntEuiPath"},
        {"class", "button"},
        {"label", "Select Folder..."}
    })
    -- location of eubind
    gui:wcreate({
        {"name",  "winPreferences.txtEubindPath"},
        {"parent",  "winPreferences.cntPathsTab"},
        {"class", "textbox"},
        {"label", "Default Eubind Path"},
        {"text", EubindPath}
    })
    gui:wcreate({
        {"name", "winPreferences.cntEubindPath"},
        {"parent", "winPreferences.cntPathsTab"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"justify_x", "left"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"}
    })
    gui:wcreate({
        {"name",  "winPreferences.btnEubindPath"},
        {"parent",  "winPreferences.cntEubindPath"},
        {"class", "button"},
        {"label", "Select Folder..."}
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
        {"label", "Select Folder..."}
    })
    
    
/*    
-- Projects Tab
    gui:wcreate({
        {"name", "winPreferences.cntProjectsTab"},
        {"parent", "winPreferences.tabCategories"},
        {"class", "container"},
        {"label", "Projects"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    -- default version
    gui:wcreate({
        {"name",  "winPreferences.txtVersion"},
        {"parent",  "winPreferences.cntProjectsTab"},
        {"class", "textbox"},
        {"label", "Default Project Version"},
        {"text", ""}
    })
    -- default author
    gui:wcreate({
        {"name",  "winPreferences.txtAuthor"},
        {"parent",  "winPreferences.cntProjectsTab"},
        {"class", "textbox"},
        {"label", "Default Project Author"},
        {"text", ""}
    })
    -- default project license
    gui:wcreate({
        {"name",  "winPreferences.txtLicense"},
        {"parent",  "winPreferences.cntProjectsTab"},
        {"class", "textbox"},
        {"label", "Default Project License"},
        {"mode", "text"},
        {"monowidth", 1},
        {"text", ""}
    })
    gui:wcreate({
        {"name", "winPreferences.cntLicense"},
        {"parent", "winPreferences.cntProjectsTab"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"justify_x", "left"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"}
    })
    gui:wcreate({
        {"name",  "winPreferences.btnLicenseFile"},
        {"parent",  "winPreferences.cntLicense"},
        {"class", "button"},
        {"label", "Load Text File..."}
    })
    
    
-- Tools Tab
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
    */
    
-- Controls Tab
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
    
    /*
-- Editor Tab
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
    */

    /*
-- Highlighter Tab
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
    */
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
    
    --gui:wproc("winPreferences.tabCategories", "select_tab", {"Projects"})
    gui:wproc("winPreferences.tabCategories", "select_tab", {1})
end procedure

check_config()


