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


include redylib_0_9/gui.e as gui
include redylib_0_9/gui/dialogs/dialog_file.e as dlgfile
include redylib_0_9/gui/dialogs/msgbox.e as msgbox
include redylib_0_9/app.e as app
include redylib_0_9/config.e as cfg
include redylib_0_9/actions.e as action
include redylib_0_9/err.e as err

include std/task.e
include std/text.e
include std/pretty.e
include std/utils.e
include std/filesys.e
include std/sequence.e as seq
include std/convert.e
include std/error.e

include build.e as build
include context.e as context


global object
pPath = "",         --project folder path
pName = "",         --project name (used for name of *.redy file)
pDefaultApp = "",   --default app file name

pEuiPath = 0,       --0=use default eui, sequence=override eui location
pEubindPath = 0,    --0=use default eubind, sequence=override eubind location
pIncludePath = 0,   --0=use default include path, sequence=override include path

pHeader = {},       --Header text to put at the top of every source file (typically version, copyright, and license info)
pIncludes = {},     --List of additional include folders
pModified = 0,      --Whether or not any files in project are modified

--pProjectNode = 0,   --project properties node
--pBuildNode = 0,     --build node
--pDocsNode = 0,      --docs folder node
pSourceNode = 0,    --source folder node
pIncludesNode = 0,  --redylib, stdlib, and additional include folders node
pFileNodes = {}     --list of file tree nodes, so clicking on node can open the associated file (each one is {nodeid, filepath, filename, readonly})


atom SettingsTabWid = 0

sequence DefaultHeader = 
"This file is part of $title$\n" &
"$url$\n" &
"\n" &
"Copyright $year$ $author$\n" &
"\n" &
"Licensed under the Apache License, Version 2.0 (the \"License\");\n" &
"you may not use this file except in compliance with the License.\n" &
"You may obtain a copy of the License at\n" &
"\n" &
"  http://www.apache.org/licenses/LICENSE-2.0\n" &
"\n" &
"Unless required by applicable law or agreed to in writing, software\n" &
"distributed under the License is distributed on an \"AS IS\" BASIS,\n" &
"WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n" &
"See the License for the specific language governing permissions and\n" &
"limitations under the License.\n"




action:define({
    {"name", "project_new"},
    {"do_proc", routine_id("do_project_new")},
    {"label", "New Project..."},
    {"icon", "project-new"},
    {"description", "Create new project"},
    {"enabled", 1}
})

action:define({
    {"name", "project_open"},
    {"do_proc", routine_id("do_project_open")},
    {"label", "Open Project..."},
    {"icon", "project-open"},
    {"description", "Open a project"},
    {"enabled", 1}
})

action:define({
    {"name", "project_load"},
    {"do_proc", routine_id("do_project_load")},
    {"label", "Load Project"},
    {"description", "Load specified project file"}
})

action:define({
    {"name", "project_close"},
    {"do_proc", routine_id("do_project_close")},
    {"label", "Close Project"},
    {"icon", "project-close"},
    {"description", "Close current project"},
    {"enabled", 0}
})

action:define({
    {"name", "project_save"},
    {"do_proc", routine_id("do_project_save")},
    {"label", "Save Project"},
    {"icon", "project-save"},
    {"description", "Save current project"},
    {"enabled", 0}
})

action:define({
    {"name", "project_copy_to"},
    {"do_proc", routine_id("do_project_copy_to")},
    {"label", "Copy Project To..."},
    {"icon", "project-save-as"},
    {"description", "Copy current project to a different location"},
    {"enabled", 0} --not implemented yet
})

action:define({
    {"name", "project_explore_folder"},
    {"do_proc", routine_id("do_project_explore_folder")},
    {"label", "Explore Project Folder"},
    {"icon", "folder"},
    {"description", "Close all open projects"},
    {"enabled", 0}
})


action:define({
    {"name", "project_refresh"},
    {"do_proc", routine_id("do_project_refresh")},
    {"label", "Refresh Project Tree"},
    {"icon", "view-refresh"},
    {"hotkey", "F5"},
    {"description", "Refresh project tree"},
    {"enabled", 0}
})

action:define({
    {"name", "project_settings"},
    {"do_proc", routine_id("do_project_settings")},
    {"label", "Project Settings..."},
    {"icon", "redy16"},
    {"description", "Edit project settings"},
    {"enabled", 0}
})

action:define({
    {"name", "list_projects"},
    {"do_proc", routine_id("do_list_projects")},
    {"description", "List projects in default folder"}
})


procedure run_app(sequence exfile)
    
end procedure


procedure do_project_new()
    show_project_settings(1)
end procedure


procedure do_project_settings()
    show_project_settings(0)
end procedure


procedure do_project_open()
    action:do_proc("project_load", {""})
end procedure


procedure do_project_load(sequence projfile)
    object
    projPath,
    projName,
    projDefaultApp  = "",
    projEuiPath = 0,
    projEubindPath = 0,
    projIncludePath = 0,
    projHeader = {},
    projIncludes = {},
    projModified = 0
    
    sequence dSections = {}, dNames = {}, dValues = {}

    atom fn, eq
    object ln, cdata = {}, vdata, selfiles
    sequence csection = "", vname
    
    if length(projfile) = 0 then
        selfiles = dlgfile:os_select_open_file("winMain", {{"RedyCode Project", "*.redy"}}, 0)
        if sequence(selfiles) then
            projfile = selfiles
        end if
    end if
    
    projPath = pathname(projfile)
    projName = filebase(projfile)
    
    fn = open(projfile, "r")
    if fn = -1 then
        msgbox:msg("Unable to open project file'" & projfile & "'.", "Error")
        return
    else
        while 1 do
            ln = gets(fn)
            if sequence(ln) then
                ln = trim_head(ln)
                ln = trim_tail(ln)
                ln = seq:filter(ln, "in",  {32,255}, "[]")
                cdata &= {ln}
            else
                exit
            end if
        end while
        close(fn)
    end if
    
    gui:debug(projName & " Project", cdata)
    
    for i = 1 to length(cdata) do
        if length(cdata[i]) > 2 and cdata[i][1] = '['  and cdata[i][$] = ']' then
            csection = cdata[i][2..$-1]
        elsif length(cdata[i]) > 0 and find(cdata[i][1], ";#") then --comment
        else
            eq = find('=', cdata[i])
            if eq > 1 and eq < length(cdata[i])-1 then
                vname = cdata[i][1..eq-1]
                vname = trim_tail(vname)
                vdata = cdata[i][eq+1..$]
                vdata = trim_head(vdata)
                if vdata[1] = '\"' and vdata[$] = '\"' then
                    vdata = vdata[2..$-1]
                    dSections &= {csection} 
                    dNames &= {vname} 
                    dValues &= {vdata}
                else
                    vdata = to_number(vdata)
                    dSections &= {csection} 
                    dNames &= {vname} 
                    dValues &= {vdata}
                end if
            end if
        end if
    end for
    
    gui:debug("dSections", dSections)
    gui:debug("dNames", dNames)
    gui:debug("dValues", dValues)
    
    for v = 1 to length(dSections) do
        switch dSections[v] do
        case "Project" then
            switch dNames[v] do
            case "DefaultApp" then 
                projDefaultApp = dValues[v]
            case "header" then 
                projHeader &= {dValues[v]}
            end switch
        case "Euphoria" then
            switch dNames[v] do
            case "EuiPath" then 
                projEuiPath = dValues[v]
            case "EubindPath" then 
                projEubindPath = dValues[v]
            case "IncludePath" then 
                projIncludePath = dValues[v]
            --case "RedyLibPath" then 
            --    projRedyLibPath = dValues[v]
            end switch
        --case "Additional Include Paths" then
        --    if sequence(dValues[v]) and length(dValues[v]) > 0 then
        --        projIncludes &= {{dNames[v], dValues[v]}}
        --    end if
        end switch
    end for
    
    if atom(projIncludePath) then
        projIncludePath = cfg:get_var("", "Projects", "IncludePath")
    end if
    if sequence(projIncludePath) then
        projIncludes &= {projIncludePath}
    end if
    
    gui:widget_hide("lstProjects")
    gui:widget_hide("btnNewProject")
    gui:widget_hide("btnOpenProject")
    gui:widget_show("btnRun")
    gui:widget_show("treeProject")
    gui:widget_show("divProjects")
    gui:widget_show("treeContents")
    
    pPath = projPath
    pName = projName
    pDefaultApp = projDefaultApp
    
    pEuiPath = projEuiPath
    pEubindPath = projEubindPath
    pIncludePath = projIncludePath
    
    pHeader = projHeader
    pIncludes = projIncludes
    pModified = projModified
    
    --pProjectNode = 0
    --pBuildNode = 0
    --pDocsNode = 0
    pSourceNode = 0
    pIncludesNode = 0
    pFileNodes = {}
    
    --refresh_source_tree()
    action:do_proc("project_refresh", {})
    
    --action:do_proc("RecentProjectList", {})
    --action:do_proc("project_title", pPath)
    
    action:set_enabled("project_new", 0)
    action:set_enabled("project_open", 0)
    action:set_enabled("project_close", 1)
    action:set_enabled("project_save", 1)
    action:set_enabled("project_copy_to", 0) --not implemented yet
    action:set_enabled("project_explore_folder", 1)
    action:set_enabled("project_refresh", 1)
    action:set_enabled("project_settings", 1)
    
    action:set_enabled("file_new", 1)
    action:set_enabled("file_open", 1)
    
    action:set_enabled("app_run_default", 1)
    action:set_enabled("app_run", 1)
    action:set_enabled("app_bind", 0) --not implemented yet
    action:set_enabled("app_build", 0) --not implemented yet
end procedure


procedure do_project_close()
    sequence ans = "Discard"
    if app:modified_count() > 0 then
        ans = msgbox:waitmsg("Some files has not been saved. Are you sure you want to close the project?", "Question", {"Save and Close", "Discard", "Cancel"})
    end if
    if equal(ans, "Save and Close") then
        action:do_proc("file_save_all", {})
        action:do_proc("file_close_all", {})
        
    elsif equal(ans, "Discard") then
        action:do_proc("file_close_all", {})
    end if
    
    if app:modified_count() = 0 then
        action:do_proc("file_close_all", {})
        
        action:set_enabled("project_new", 1)
        action:set_enabled("project_open", 1)
        action:set_enabled("project_close", 0)
        action:set_enabled("project_save", 0)
        action:set_enabled("project_copy_to", 0)
        action:set_enabled("project_explore_folder", 0)
        action:set_enabled("project_refresh", 0)
        action:set_enabled("project_settings", 0)
        
        action:set_enabled("file_new", 0)
        action:set_enabled("file_open", 0)
        
        action:set_enabled("app_run_default", 0)
        action:set_enabled("app_run", 0)
        action:set_enabled("app_bind", 0)
        action:set_enabled("app_build", 0)
        
        gui:wdestroy("winProjectSettings")
        gui:wproc("treeProject", "clear_tree", {})
        
        pPath = ""
        pName = ""
        pDefaultApp = ""
        
        pEuiPath = 0
        pEubindPath = 0
        pIncludePath = 0
        
        pHeader = {}
        pIncludes = {}
        pModified = 0
        
        --pProjectNode = 0
        --pBuildNode = 0
        --pDocsNode = 0
        pSourceNode = 0
        pIncludesNode = 0
        pFileNodes = {}
        
        build:set_source_path("")
        --build:set_include_paths(pIncludes)
        build:set_default_app("")
        build:set_app_list({})
        
        --action:do_proc("project_title", "")
        action:do_proc("list_projects", {})
    end if
end procedure


procedure do_project_save()
    --actually, this just does a "save all"
    action:do_proc("file_save_all", {})
    
    --if length(pPath) > 0 and length(pName) > 0 then
    --    save_project_settings(pPath & "\\" & pName & ".redy")
    --end if
end procedure


procedure do_project_explore_folder()
    if length(pPath) > 0 then
        --puts(1, pPath)
        
        atom wh = gui:widget_get_handle("winMain")
        --Old version:
        --atom ret = gui:ShellExecute(wh, pPath, "", "explore")
        
        --New version:
        atom ret = gui:ShellExecute(wh, "explore", pPath, "")
        
        if ret > 32 then 
          -- success
        else 
          -- failure
            msgbox:msg("Unable to explore folder '" & pPath & "'. ShellExecute returned: " & sprint(ret) & "", "Error")
        end if
        
        
    end if
end procedure


procedure do_project_refresh() --scan source folders for files and subfolders, rebuild tree
    atom fnode
    
    gui:wproc("treeProject", "clear_tree", {})
    --pProjectNode = gui:wfunc("treeProject", "add_item", {0, "redy16", "Project: " & pName, 0})
    --pBuildNode = gui:wfunc("treeProject", "add_item", {0, "ex16", "Build", 0})
    --pDocsNode = gui:wfunc("treeProject", "add_item", {0, "folder_open_16", "Docs", 0})
    pSourceNode = gui:wfunc("treeProject", "add_item", {0, "folder_open_16", "Source", 1})
    pIncludesNode = gui:wfunc("treeProject", "add_item", {0, "folder_open_16", "Includes", 1})
    pFileNodes = {}
    
    build_dir(pSourceNode, pPath & "\\source\\", 0)
    build_app_list()
    
    for f = 1 to length(pIncludes) do --TODO: only show libraries that are actually included
    --    fnode = gui:wfunc("treeProject", "add_item", {pIncludesNode, "folder_open_16", pIncludes[f][1], 0})
    --    build_dir(fnode, pIncludes[f][2], 1)
        build_dir(pIncludesNode, pIncludes[f] & "\\", 1)
    end for
end procedure


procedure show_project_settings(atom newproj)
    sequence wintitle
    object projPath, projName, projDefaultApp, projTemplate, projHeader
    object projEuiPath, projEubindPath, projIncludePath --, projRedyLibPath
    atom defEuiPath, defEubindPath, defIncludePath --, defRedyLibPath
    atom overrideEuiPath, overrideEubindPath, overrideIncludePath --, overrideRedyLibPath
    sequence EuiPathTxt, EubindPathTxt, IncludePathTxt --, RedyLibPathTxt
    
    if gui:wexists("winProjectSettings") then
        if newproj = 1 then
            gui:wdestroy("winProjectSettings")
        else
            return
        end if
    end if
    
    if newproj then
        wintitle = "Create New Project"
        projPath = get_projects_path()
        projName = "NewProject"
        projDefaultApp = "NewProject.exw"
        projTemplate = "default"
        
        projEuiPath = 0
        projEubindPath = 0
        --projRedyLibPath = 0
        projIncludePath = 0
        
        projHeader = DefaultHeader
    else
        /*if SettingsTabWid > 0 then --file is already open, so switch to it's tab instead
            select_tab(SettingsTabWid)
            return
        end if
        
        atom tabid = tabs:create("Project Settings")
        sequence parname = gui:widget_get_name(tabid) 
        sequence wname = sprint(tabid)
        SettingsTabWid = tabid
        */
        wintitle = "Project Settings"
        projPath = pPath
        projName = pName
        projDefaultApp = pDefaultApp
        projTemplate = "default"
        
        projEuiPath = pEuiPath
        projEubindPath = pEubindPath
        projIncludePath = pIncludePath
        
        projHeader = pHeader
    end if
    
    if atom(projEuiPath) then
        defEuiPath = 1
        overrideEuiPath = 0
        EuiPathTxt = cfg:get_var("", "Projects", "EuiPath")
    else
        defEuiPath = 0
        overrideEuiPath = 1
        EuiPathTxt = projEuiPath
    end if
    if atom(projEubindPath) then
        defEubindPath = 1
        overrideEubindPath = 0
        EubindPathTxt = cfg:get_var("", "Projects", "EubindPath")
    else
        defEubindPath = 0
        overrideEubindPath = 1
        EubindPathTxt = projEubindPath
    end if
    
    if atom(projIncludePath) then
        defIncludePath = 1
        overrideIncludePath = 0
        IncludePathTxt = cfg:get_var("", "Projects", "IncludePath")
    else
        defIncludePath = 0
        overrideIncludePath = 0 --1 --temp fix, need to make check boxes override properly
        IncludePathTxt = projIncludePath
    end if
    
    --if newproj then
    gui:wcreate({
        {"name", "winProjectSettings"},
        {"class", "window"},
        --{"mode", "dialog"},
        {"handler", routine_id("gui_event")},
        {"title", wintitle},
        {"topmost", 1},
        {"size", {700, 550}}
    })
    gui:wcreate({
        {"name", "winProjectSettings.cntMain"},
        {"parent", "winProjectSettings"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    /*else
    
        gui:wcreate({
            {"name", "winProjectSettings.cntMain"},
            {"parent", gui:widget_get_name(SettingsTabWid)},
            {"class", "container"},
            {"orientation", "vertical"},
            {"sizemode_x", "expand"},
            {"sizemode_y", "expand"},
            {"handler", routine_id("gui_event")}
        })
        gui:wcreate({
            {"name", "winProjectSettings.cntCommands"},
            {"parent", "winProjectSettings.cntMain"},
            {"class", "container"},
            {"orientation", "horizontal"},
            {"sizemode_x", "expand"},
            {"sizemode_y", "normal"}
        })
        gui:wcreate({
            {"name", "winProjectSettings.cntCommandsLeft"},
            {"parent", "winProjectSettings.cntCommands"},
            {"class", "container"},
            {"orientation", "horizontal"},
            {"sizemode_x", "normal"},
            {"sizemode_y", "normal"},
            {"justify_x", "left"}
        })
        gui:wcreate({
            {"name", "winProjectSettings.cntCommandsRight"},
            {"parent", "winProjectSettings.cntCommands"},
            {"class", "container"},
            {"orientation", "horizontal"},
            {"sizemode_x", "normal"},
            {"sizemode_y", "normal"},
            {"justify_x", "right"}
        })
        gui:wcreate({
            {"name", "winProjectSettings.btnClose"},
            {"parent", "winProjectSettings.cntCommandsRight"},
            {"class", "button"},
            {"label", "Close"}
        })
        gui:wcreate({
            {"name", "winProjectSettings.btnSave"},
            {"parent", "winProjectSettings.cntCommandsLeft"},
            {"class", "button"},
            {"label", "Save Project Settings"}
        })
    end if*/
    
    
    gui:wcreate({
        {"name", "winProjectSettings.cntTop"},
        {"parent", "winProjectSettings.cntMain"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    --data entry:
    gui:wcreate({
        {"name",  "winProjectSettings.txtPath"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Project Location"},
        {"text", projPath},
        {"enabled", newproj}
    })
    
    gui:wcreate({
        {"name",  "winProjectSettings.txtName"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Project Name"},
        {"autofocus", 1},
        {"text", projName},
        {"enabled", newproj}
    })
    /*gui:wcreate({
        {"name",  "winProjectSettings.txtProjectFile"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Project File"},
        {"text", projName & "\\" & projName &".redy"},
        {"enabled", 0}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.txtDefaultApp"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Default Application"},
        {"text", projDefaultApp}, --{projName & "\\source\\" & projName & ".exw"},
        {"enabled", 0}
    })*/
    
    --paths
    gui:wcreate({
        {"name",  "winProjectSettings.chkDefEuiPath"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "toggle"},
        {"label", "Use Default Eui"},
        {"value", defEuiPath},
        {"enabled", 0}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.txtEuiPath"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Eui Location"},
        {"text", EuiPathTxt},
        {"enabled", overrideEuiPath}
    })
    /*gui:wcreate({
        {"name", "winProjectSettings.cntEuiPath"},
        {"parent", "winProjectSettings.cntTop"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"justify_x", "left"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.btnEuiPath"},
        {"parent",  "winProjectSettings.cntEuiPath"},
        {"class", "button"},
        {"label", "Select Folder..."}
    })*/
    
    
    gui:wcreate({
        {"name",  "winProjectSettings.chkDefEubindPath"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "toggle"},
        {"label", "Use Default Eubind"},
        {"value", defEubindPath},
        {"enabled", 0}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.txtEubindPath"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Eubind Location"},
        {"text", EubindPathTxt},
        {"enabled", overrideEubindPath}
    })
    /*gui:wcreate({
        {"name", "winProjectSettings.cntEubindPath"},
        {"parent", "winProjectSettings.cntTop"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"justify_x", "left"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.btnEubindPath"},
        {"parent",  "winProjectSettings.cntEubindPath"},
        {"class", "button"},
        {"label", "Select Folder..."}
    })*/
    
    
    gui:wcreate({
        {"name",  "winProjectSettings.chkDefIncludePath"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "toggle"},
        {"label", "Use Default Include Path"},
        {"value", defIncludePath},
        {"enabled", 0}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.txtIncludePath"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Include Path"},
        {"text", IncludePathTxt},
        {"enabled", overrideIncludePath}
    })
    /*gui:wcreate({
        {"name", "winProjectSettings.cntIncludePath"},
        {"parent", "winProjectSettings.cntTop"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"justify_x", "left"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.btnIncludePath"},
        {"parent",  "winProjectSettings.cntIncludePath"},
        {"class", "button"},
        {"label", "Select Folder..."}
    })*/
    
    --new project template
    if newproj then
        gui:wcreate({
            {"name",  "winProjectSettings.txtTemplate"},
            {"parent",  "winProjectSettings.cntTop"},
            {"class", "textbox"},
            {"label", "Template"},
            {"text", projTemplate},
            {"enabled", 0}
        })
        /*gui:wcreate({
            {"name", "winProjectSettings.cntTemplate"},
            {"parent", "winProjectSettings.cntTop"},
            {"class", "container"},
            {"orientation", "horizontal"},
            {"justify_x", "left"},
            {"sizemode_x", "normal"},
            {"sizemode_y", "normal"}
        })
        gui:wcreate({
            {"name",  "winProjectSettings.btnTemplate"},
            {"parent",  "winProjectSettings.cntTemplate"},
            {"class", "button"},
            {"label", "Select Template..."}
        })*/
    end if
    
    gui:wcreate({
        {"name",  "winProjectSettings.txtHeader"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Source File Header"},
        {"mode", "text"},
        {"monowidth", 1},
        {"text", projHeader},
        {"enabled", newproj} --temporarily disable when not a new project, because it doesn't do anything yet
    })
    
    gui:wcreate({
        {"name", "winProjectSettings.cntBottom"},
        {"parent", "winProjectSettings.cntMain"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"}
    })
    
    if newproj then
        gui:wcreate({
            {"name",  "winProjectSettings.btnCreate"},
            {"parent",  "winProjectSettings.cntBottom"},
            {"class", "button"},
            {"label", "Create new project"}
        })
        gui:wcreate({
            {"name", "winProjectSettings.btnCancel"},
            {"parent",  "winProjectSettings.cntBottom"},
            {"class", "button"},
            {"label", "Cancel"}
        })
    else
        gui:wcreate({
            {"name",  "winProjectSettings.btnSave"},
            {"parent",  "winProjectSettings.cntBottom"},
            {"class", "button"},
            {"label", "Save project file"},
            {"enabled", 0} --temporarily disabled, because project settings doesn't do anything yet
            
        })
        gui:wcreate({
            {"name", "winProjectSettings.btnCancel"},
            {"parent",  "winProjectSettings.cntBottom"},
            {"class", "button"},
            {"label", "Cancel"}
        })
    end if
end procedure


procedure save_project_settings(sequence projfile)
    object fn = open(projfile, "w")
    
    if fn = -1 then
        msgbox:msg("Unable to save project file '" & projfile & "'!", "Error")
    else
        puts(fn, "[Project]\n")
        
        for li = 1 to length(pHeader) do
            puts(fn, "Header = \"" & pHeader[li] & "\"\n")
        end for
        puts(fn, "\n")
        
        puts(fn, "[Euphoria]\n")
        if atom(pEuiPath) then
            puts(fn, "EuiPath = " & sprint(pEuiPath) & "\n")
        else
            puts(fn, "EuiPath = \"" & pEuiPath & "\"\n")
        end if
        if atom(pEubindPath) then
            puts(fn, "EubindPath = " & sprint(pEubindPath) & "\n")
        else
            puts(fn, "EubindPath = \"" & pEubindPath & "\"\n")
        end if
        if atom(pIncludePath) then
            puts(fn, "IncludePath = " & sprint(pIncludePath) & "\n")
        else
            puts(fn, "IncludePath = \"" & pIncludePath & "\"\n")
        end if
        --if atom(pRedyLibPath) then
        --    puts(fn, "RedyLibPath = " & sprint(pRedyLibPath) & "\n")
        --else
        --    puts(fn, "RedyLibPath = \"" & pRedyLibPath & "\"\n")
        --end if
        
        close(fn)
    end if
end procedure


procedure do_list_projects()
    sequence listitems = {}
    object projpath = get_projects_path()
    object plist = dir(projpath), flist
    
    if not wexists("panelProject") then
        gui:wcreate({
            {"name", "panelProject"},
            {"parent", "winMain"},
            {"class", "panel"},
            {"label", "Project"},
            {"dock", "left"},
            {"handler", routine_id("gui_event")}
        })
        
        gui:wcreate({
            {"name", "cntProject"},
            {"parent", "panelProject"},
            {"class", "container"},
            {"orientation", "vertical"},
            {"sizemode_x", "expand"},
            {"sizemode_y", "expand"}
        })
        gui:wcreate({
            {"name", "btnNewProject"},
            {"parent", "cntProject"},
            {"class", "button"},
            {"label", "Create new project..."},
            {"visible", 0}
        })
        gui:wcreate({
            {"name", "btnOpenProject"},
            {"parent", "cntProject"},
            {"class", "button"},
            {"label", "Open other project..."},
            {"visible", 0}
        })
        gui:wcreate({
            {"name", "btnRun"},
            {"parent", "cntProject"},
            {"class", "button"},
            {"label", "Run " & pDefaultApp},
            {"visible", 0}
        })
        
        gui:wcreate({
            {"name", "btnProjectFiles"},
            {"parent", "cntProject"},
            {"class", "button"},
            {"label", "Project Files"},
            {"visible", 0}
        })
        gui:wcreate({
            {"name", "btnSourceTree"},
            {"parent", "cntProject"},
            {"class", "button"},
            {"label", "Source Map"},
            {"visible", 0}
        })
        gui:wcreate({
            {"name", "lstProjects"},
            {"parent", "cntProject"},
            {"class", "fancylist"},
            {"label", "Open a project:"},
            {"visible", 0}
        })
        
        gui:wcreate({
            {"name", "treeProject"},
            {"parent", "cntProject"},
            {"class", "treebox"},
            {"visible", 0}
        })
        
        /*gui:wcreate({
            {"name", "cntMain"},
            {"parent", "winMain"},
            {"class", "container"},
            {"orientation", "vertical"},
            {"sizemode_x", "expand"},
            {"sizemode_y", "expand"},
            {"handler", routine_id("gui_event")}
        })*/
        
        --tabs:start()
        
        --msg:subscribe("project", "command", routine_id("msg_event"))
    end if
    
    if sequence(plist) then
        for p = 1 to length(plist) do 
            if find('d', plist[p][D_ATTRIBUTES]) and not find(plist[p][D_NAME], {".", ".."}) then
                flist = dir(projpath & "\\" & plist[p][D_NAME])
                
                if sequence(flist) then
                    for f = 1 to length(flist) do
                        if not find('d', flist[f][D_ATTRIBUTES]) then
                            if match(".redy", flist[f][D_NAME]) = length(flist[f][D_NAME]) - 4 then --project config file
                                listitems &= {{1, flist[f][D_NAME][1..$-5], projpath, plist[p][D_NAME] & "\\" & flist[f][D_NAME]}}
                            end if
                        end if
                    end for
                end if
            end if
        end for
    end if
    
    gui:widget_show("lstProjects")
    gui:widget_show("btnNewProject")
    gui:widget_show("btnOpenProject")
    gui:widget_hide("btnRun")
    gui:widget_hide("treeProject")
    gui:widget_hide("divProjects")
    gui:widget_hide("treeContents")
    
    gui:wproc("lstProjects", "select_items", {0})
    gui:wproc("lstProjects", "clear_list", {})
    gui:wproc("lstProjects", "add_list_items", {listitems})
end procedure


procedure create_project()
    object
    projname = gui:wfunc("winProjectSettings.txtName", "get_text", {}),
    projpath = gui:wfunc("winProjectSettings.txtPath", "get_text", {}) & "\\" & projname,
    projdefaultapp = gui:wfunc("winProjectSettings.txtDefaultApp", "get_text", {}),
    projtemplate = cfg:get_var("", "Projects", "TemplatePath") & "\\" & gui:wfunc("winProjectSettings.txtTemplate", "get_text", {}),
    projheader = gui:wfunc("winProjectSettings.txtHeader", "get_text", {})
    
    if atom(projtemplate) or not file_exists(projtemplate) then
        msgbox:msg("Template '" & projtemplate & "' does not exist. Defaulted to empty project.", "Error")
        projtemplate = ""
    end if
    
    if not sequence(projpath) then
        msgbox:msg("Invalid project path.", "Error")
        return
    end if
    if not sequence(projname) then
        msgbox:msg("Invalid project name.", "Error")
        return
    end if
    
    --create projname folder and subfolders
    if file_exists(projpath) then
        msgbox:msg("Unable to create project '" & projpath & "'. Folder '" & projpath 
        & "' already exists. Please use a different project name.", "Error")
        return
    end if
    if not create_directory(projpath) then
        msgbox:msg("Unable to create folder '" & projpath & "'.", "Error")
        return
    end if
    if not create_directory(projpath & "\\build") then
        msgbox:msg("Unable to create folder '" & projpath & "\\build'.", "Error")
        return
    end if
    /*if not create_directory(projpath & "\\" & projname & "\\build\\bin") then
        msgbox:msg("Unable to create folder '" & projpath & "\\" & projname & "\\build\\bin'.", "Error")
        return
    end if
    if not create_directory(projpath & "\\build\\install") then
        msgbox:msg("Unable to create folder '" & projpath & "\\build\\install'.", "Error")
        return
    end if*/
    if not create_directory(projpath & "\\source") then
        msgbox:msg("Unable to create folder '" & projpath & "\\source'.", "Error")
        return
    end if
    
    --create projname.redy file
    if not create_file(projpath & "\\" & projname & ".redy") then
        msgbox:msg("Unable to create file '" & projpath & "\\" & projname & ".redy'.", "Error")
        return
    end if
    
    
    if length(projtemplate) > 0 then --copy source template files
        --copy files from template folder to project\source folder recursively.
        --when copying files, prepend eu source files with projheader
        --rename "TempMain.exw" to projname & ".exw" 
        
        object ln, fq = {}, sf = dir(projtemplate & "\\")
        atom ofn, ifn
        
        if sequence(sf) and length(sf) > 0 then
            for f = 1 to length(sf) do
                fq &= {{"", sf[f]}}
            end for
        end if
        
        while length(fq) > 0 do
            --pretty_print(1, {fq[1][1], fq[1][2][D_NAME]}, {2}) 
            
            if find('d', fq[1][2][D_ATTRIBUTES]) then
                if not find(fq[1][2][D_NAME], {".", ".."}) then
                    sf = dir(projtemplate & "\\" & fq[1][1] & fq[1][2][D_NAME] & "\\")
                    if sequence(sf) and length(sf) > 0 then
                        for f = 1 to length(sf) do
                            fq &= {{fq[1][1] & fq[1][2][D_NAME] & "\\", sf[f]}}
                        end for
                    end if
                    --make dir
                    filesys:create_directory(projpath & "\\source\\" & fq[1][1] & fq[1][2][D_NAME])
                end if
                
            else
                if find(filesys:fileext(fq[1][1] & fq[1][2][D_NAME]), {"e", "eu", "ew", "ex", "exw"}) then --euphoria source file
                    --rename main file to projname.exw
                    if equal(fq[1][2][D_NAME], "TempMain.exw") then
                        ofn = open(projpath & "\\source\\" & fq[1][1] & projname & ".exw", "w")
                    else
                        ofn = open(projpath & "\\source\\" & fq[1][1] & fq[1][2][D_NAME], "w")
                    end if
                    
                    --prepend file with projheader, then copy text from source file
                    if sequence(projheader) and length(projheader) > 0 then
                        for li = 1 to length(projheader) do
                            puts(ofn, "-- " & projheader[li] & "\n")
                        end for
                        puts(ofn, "\n")
                    end if
                    
                    --append copy of source file
                    ifn = open(projtemplate & "\\" & fq[1][1] & fq[1][2][D_NAME], "r")
                    if ifn = -1 then
                        --msgbox:msg("Unable to open file'" & projtemplate & "\\" & fq[1][1] & fq[1][2][D_NAME] & "'.", "Error")
                        --return
                    else
                        while 1 do
                            ln = gets(ifn)
                            if sequence(ln) then
                                puts(ofn, ln)
                            else
                                exit
                            end if
                        end while
                        close(ifn)
                    end if
                    close(ofn)
                    
                else
                    filesys:copy_file(
                        projtemplate & "\\" & fq[1][1] & fq[1][2][D_NAME],
                        projpath & "\\source\\" & fq[1][1] & fq[1][2][D_NAME]
                    )
                end if
            end if
            
            fq = fq[2..$]
        end while
        
    else --create empty project
        
        if not create_directory(projpath & "\\source\\docs") then
            msgbox:msg("Unable to create folder '" & projpath & "\\source\\docs'.", "Error")
            return
        end if
        if not create_directory(projpath & "\\source\\images") then
            msgbox:msg("Unable to create folder '" & projpath & "\\source\\images'.", "Error")
            return
        end if
    --create main doc file
        if not create_file(projpath & "\\source\\docs\\toc.htd") then
            msgbox:msg("Unable to create file '" & projpath & "\\source\\docs\\toc.htd'.", "Error")
            return
        end if
        --create main source file
        if not create_file(projpath & "\\source\\" & projname & ".exw") then
            msgbox:msg("Unable to create file '" & projpath & "\\source\\" & projname & ".exw'.", "Error")
            return
        end if
    end if
    
    pPath = projpath
    pName = projname
    pDefaultApp = projdefaultapp
    
    get_project_settings()
    
    save_project_settings(projpath & "\\" & projname & ".redy")
    gui:wdestroy("winProjectSettings")
    action:do_proc("project_load", {projpath & "\\" & projname & ".redy"})
end procedure


procedure get_project_settings()
    object
    HeaderTxt = gui:wfunc("winProjectSettings.txtHeader", "get_text", {}),
    
    DefEuiPath = gui:wfunc("winProjectSettings.chkDefEuiPath", "get_value", {}),
    EuiPath = gui:wfunc("winProjectSettings.txtEuiPath", "get_text", {}),
    DefEubindPath = gui:wfunc("winProjectSettings.chkDefEubindPath", "get_value", {}),
    EubindPath = gui:wfunc("winProjectSettings.txtEubindPath", "get_text", {}),
    --DefRedyLibPath = gui:wfunc("winProjectSettings.chkDefRedyLibPath", "get_value", {}),
    --RedyLibPath = gui:wfunc("winProjectSettings.txtRedyLibPath", "get_text", {}),
    DefIncludePath = gui:wfunc("winProjectSettings.chkDefIncludePath", "get_value", {}),
    IncludePath = gui:wfunc("winProjectSettings.txtIncludePath", "get_text", {})
    
    if DefEuiPath then
        pEuiPath = 0
    else
        pEuiPath = EuiPath
    end if
    if DefEubindPath then
        pEubindPath = 0
    else
        pEubindPath = EubindPath
    end if
    --if DefRedyLibPath then
    --    pRedyLibPath = 0
    --else
    --    pRedyLibPath = RedyLibPath
    --end if
    if DefIncludePath then
        pIncludePath = 0
    else
        pIncludePath = IncludePath
    end if
    
    pHeader = HeaderTxt
end procedure



-------------------------------



function get_projects_path()
    object ppath = cfg:get_var("", "Projects", "ProjectPath")
    if not sequence(ppath) then
        ppath = ExePath & "\\projects"
        if not file_exists(ppath) then
            ppath = ExePath & "\\..\\.."
        end if
        if not file_exists(ppath) then
            ppath = "C:\\RedyCode\\projects"
        end if
        if not file_exists(ppath) then
            ppath = ""
        end if
    end if
    
    --if ppath[$] != '\\' then
    --    ppath &= '\\'
    --end if
    
    return ppath
end function


procedure build_app_list()
    object flist = dir(pPath & "\\source")
    sequence AppList = {}
    
    if sequence(flist) then
        for f = 1 to length(flist) do
            if not find('d', flist[f][D_ATTRIBUTES]) and not find(flist[f][D_NAME], {".", ".."}) then
                if find(filesys:fileext(flist[f][D_NAME]), {"ex", "exw", "eu"}) then --euphoria executable
                    AppList &= {flist[f][D_NAME]}
                    if length(pDefaultApp) = 0 and equal(pName, filesys:filebase(flist[f][D_NAME])) then
                        pDefaultApp = flist[f][D_NAME]
                    end if
                end if
            end if
        end for
    end if
    
    if length(pDefaultApp) = 0 and length(AppList) > 0 then
        pDefaultApp = AppList[1]
    end if
    
    gui:wproc("btnRun", "set_label", {"Run " & pDefaultApp})
    build:set_source_path(pPath & "\\source")
    --build:set_include_paths(pIncludes)
    build:set_default_app(pDefaultApp)
    build:set_app_list(AppList)
    
    --context:set_source_path(pPath & "\\source")
    --context:set_include_paths(pIncludes)
    --context:set_default_app(defaultApp)
    --context:set_app_list(AppList)
end procedure


procedure build_dir(atom parentnodeid, sequence path, atom readonly)
    object ficon, flist
    atom dnode
     
    flist = dir(path)
    
    if sequence(flist) then
        --scan for subfolders
        for f = 1 to length(flist) do 
            ficon = ""
            if find('d', flist[f][D_ATTRIBUTES]) and not find(flist[f][D_NAME], {".", ".."}) then
                ficon = "folder_open_16"
                dnode = gui:wfunc("treeProject", "add_item", {parentnodeid, ficon, flist[f][D_NAME], 0})
                --build_dir(dnode, path & "\\" & flist[f][D_NAME] & "\\", readonly)
                build_dir(dnode, path & flist[f][D_NAME] & "\\", readonly)
            end if
        end for
        --scan for executable files
        for f = 1 to length(flist) do
            ficon = ""
            if not find('d', flist[f][D_ATTRIBUTES]) and not find(flist[f][D_NAME], {".", ".."}) then
                if find(fileext(flist[f][D_NAME]), {"ex", "exw", "eu"}) then --euphoria executable
                    ficon = "ex16"
                end if
            end if
            
            if length(ficon) > 0 then
                pFileNodes &= {{
                    gui:wfunc("treeProject", "add_item", {parentnodeid, ficon, flist[f][D_NAME], 0}),
                    path,
                    flist[f][D_NAME],
                    readonly
                }}
            end if
        end for
        --scan for other source files
        for f = 1 to length(flist) do
            ficon = ""
            if not find('d', flist[f][D_ATTRIBUTES]) and not find(flist[f][D_NAME], {".", ".."}) then
                if find(fileext(flist[f][D_NAME]), {"e"}) then --euphoria library
                    ficon = "e16"
                end if
            end if
            
            if length(ficon) > 0 then
                pFileNodes &= {{
                    gui:wfunc("treeProject", "add_item", {parentnodeid, ficon, flist[f][D_NAME], 0}),
                    path,
                    flist[f][D_NAME],
                    readonly
                }}
            end if
        end for
        --scan for err files
        for f = 1 to length(flist) do
            ficon = ""
            if not find('d', flist[f][D_ATTRIBUTES]) and not find(flist[f][D_NAME], {".", ".."}) then
                if find(fileext(flist[f][D_NAME]), {"err"}) then --euphoria error report
                    ficon = "err16"
                end if
            end if
            if length(ficon) > 0 then
                pFileNodes &= {{
                    gui:wfunc("treeProject", "add_item", {parentnodeid, ficon, flist[f][D_NAME], 0}),
                    path,
                    flist[f][D_NAME],
                    readonly
                }}
            end if
        end for
        --scan for config files
        for f = 1 to length(flist) do
            ficon = ""
            if not find('d', flist[f][D_ATTRIBUTES]) and not find(flist[f][D_NAME], {".", ".."}) then
                if find(fileext(flist[f][D_NAME]), {"cfg", "ini", "txt"}) then --config file
                    ficon = "text-x-generic"
                end if
            end if
            
            if length(ficon) > 0 then
                pFileNodes &= {{
                    gui:wfunc("treeProject", "add_item", {parentnodeid, ficon, flist[f][D_NAME], 0}),
                    path,
                    flist[f][D_NAME],
                    readonly
                }}
            end if
        end for
        --scan for doc files
        for f = 1 to length(flist) do
            ficon = ""
            if not find('d', flist[f][D_ATTRIBUTES]) and not find(flist[f][D_NAME], {".", ".."}) then
                if find(fileext(flist[f][D_NAME]), {"htd", "htm", "html"}) then --doc/text file
                    ficon = "text-html"
                end if
            end if
            
            if length(ficon) > 0 then
                pFileNodes &= {{
                    gui:wfunc("treeProject", "add_item", {parentnodeid, ficon, flist[f][D_NAME], 0}),
                    path,
                    flist[f][D_NAME],
                    readonly
                }}
            end if
        end for
        --scan for image files
        for f = 1 to length(flist) do
            ficon = ""
            if not find('d', flist[f][D_ATTRIBUTES]) and not find(flist[f][D_NAME], {".", ".."}) then
                if find(fileext(flist[f][D_NAME]), {"bmp", "ico", "png", "jpg", "gif", "svg"}) then --image file
                    ficon = "image-x-generic"
                end if
            end if
            
            if length(ficon) > 0 then
                pFileNodes &= {{
                    gui:wfunc("treeProject", "add_item", {parentnodeid, ficon, flist[f][D_NAME], 0}),
                    path,
                    flist[f][D_NAME],
                    readonly
                }}
            end if
        end for
    end if
end procedure








procedure confirm_close_project()
    if length(pPath) > 0 then
        sequence ans = "Yes"
        if pModified then
            ans = msgbox:waitmsg("Save project before closing?", "Question", {"Yes", "No", "Cancel"})
        end if
        if equal(ans, "Yes") then
            if length(pPath) > 0 then
                --save_project(pPath & "\\" & pName & ".redy")
                --source:save_all()
                --images:
                --docs:
            end if
            action:do_proc("project_close", {})
            --action:do_proc("list_projects", {})
        elsif equal(ans, "No") then
            action:do_proc("project_close", {})
            --action:do_proc("list_projects", {})
        end if
    end if
end procedure









------------------------


procedure gui_event(object evwidget, object evtype, object evdata)
    switch evwidget do
        case "lstProjects" then
            if equal(evtype, "left_double_click") then
            --if equal(evtype, "selection") then
                if sequence(evdata) and length(evdata) > 0 then
                    action:do_proc("project_load", {evdata[1][2][2] & "\\" & evdata[1][2][3]})
                end if
            end if
            
        case "btnNewProject" then
            action:do_proc("project_new", {})
            
            
        case "btnOpenProject" then
            action:do_proc("project_open", {})
            
        case "btnRun" then
            action:do_proc("app_run_default", {})
            
        case "treeProject" then
            -- "expand_item"
            
            --if evdata[1] = pProjectNode then
            --    if equal(evtype, "selection") then
            --        action:do_proc("project_settings", {})
            --    end if
            --
            --elsif evdata[1] = pBuildNode then
            --    if equal(evtype, "selection") then
            --        action:do_proc("build_project", {})
            --    end if
            --
            --elsif evdata[1] = pDocsNode then
            --    if equal(evtype, "selection") then
            --        --action:do_proc("edit_docs", {})
            --    end if
            --
            --elsif evdata[1] = pSourceNode then
            --    if equal(evtype, "selection") then
            --        --action:do_proc("edit_apps", {})
            --    end if
            --
            --elsif evdata[1] = pIncludesNode then
            --    if equal(evtype, "selection") then
            --        --action:do_proc("edit_include_paths", {})
            --    end if
            --
            --else
                --action:do_proc("RecentFileList", {})
                
            for f = 1 to length(pFileNodes) do
                if pFileNodes[f][1] = evdata[1] then
                    if equal(evtype, "selection") then
                        action:do_proc("file_load", {{{pFileNodes[f][2], pFileNodes[f][3], pFileNodes[f][4]}}})
                        exit
                        
                    elsif equal(evtype, "left_double_click") then
                        if find(filesys:fileext(pFileNodes[f][3]), {"ex", "exw", "exu"}) then
                            action:do_proc("app_run", {pFileNodes[f][2] & "\\" & pFileNodes[f][3]})
                        else
                            --shell execute
                        end if
                    end if
                end if
            end for
            --end if
            
        case "winProjectSettings.btnCreate" then
            create_project()
            
        case "winProjectSettings.btnClose" then
            if SettingsTabWid > 0 then
                --tabs:destroy_tab(SettingsTabWid)
                SettingsTabWid = 0
            end if
            
        case "winProjectSettings.btnSave" then
            get_project_settings()
            --action:do_proc("save_project", {})
            if length(pPath) > 0 and length(pName) > 0 then
                save_project_settings(pPath & "\\" & pName & ".redy")
            end if
            gui:wdestroy("winProjectSettings")
            
        case "winProjectSettings.btnCancel" then
            gui:wdestroy("winProjectSettings")
            
        case "winProjectSettings.txtName" then
            if equal(evtype, "changed") then
                sequence projname = gui:wfunc("winProjectSettings.txtName", "get_text", {})
                gui:wproc("winProjectSettings.txtProjectFile", "set_text", {projname & "\\" & projname & ".redy"})
                gui:wproc("winProjectSettings.txtDefaultApp", "set_text", {projname & ".exw"})
            end if
            
    end switch

end procedure


