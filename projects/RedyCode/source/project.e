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


include redylib_0_9/gui.e as gui
include redylib_0_9/gui/dialogs/dialog_file.e as dlgfile
include redylib_0_9/gui/dialogs/msgbox.e as msgbox
include redylib_0_9/gui/objects/textdoc.e as txtdoc
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
pError = 0,         --current error from ex.err (noerror: 0, error: {errfile, errline, errtxt})

pEubinPath = 0,    --0=use default eubin path, sequence=override eubin path
pIncludePath = 0,   --0=use default include path, sequence=override include path

pHeader = {},       --Header text to put at the top of every source file (typically version, copyright, and license info)
pIncludes = {},     --List of additional include folders
pModified = 0,      --Whether or not any files in project are modified

--pProjectNode = 0,   --project properties node
--pBuildNode = 0,     --build node
--pDocsNode = 0,      --docs folder node
pSourceNode = 0,    --source folder node
pIncludesNode = 0,  --redylib, stdlib, and additional include folders node
pFileNodes = {},     --list of file tree nodes, so clicking on node can open the associated file (each one is {nodeid, filepath, filename, readonly})
pFolderNodes = {},   --list of folder tree nodes (each one is {nodeid, path})
pExpandedFolders = {}, --list of paths that are expanded in the project tree (so when refreshing the tree, expanded nodes can be recalled)

pInfoVars = {}, --list of info vars used in header and appinfo. Example: {{"title", "App Title"}, {"author", "Firstname Lastname"}, ...}

pBookmarks = {}, --list of bookmarks to remember: {{"file1", {num1, num2, num3, ...}, {"file2", {num1, num2, num3, ...}, ...}
pOpenFiles = {}  --list of files to open automatically when project is opened

atom SettingsTabWid = 0

atom
CurrInfoVarIdx = 0
sequence InfoVars = {},
prevProjectList = {}

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
    --{"label", "Save Project"},
    --{"icon", "project-save"},
    --{"description", "Save current project"},
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

action:define({
    {"name", "project_show_error"},
    {"do_proc", routine_id("do_project_show_error")},
    {"label", "Go to Error"},
    {"icon", "go-jump"},
    {"description", "Go to error in code reported by ex.err"},
    {"enabled", 0}
})


procedure do_project_show_error()
    if sequence(pError) then --{errfile, errline, errtxt}
        atom readonly = 0, linenum = pError[2]
        if match(filesys:pathname(pPath), filesys:pathname(pError[1])) != 1 then
            readonly = 1
        end if
        action:do_proc("file_load", {{{filesys:pathname(pError[1]) & "\\", filesys:filename(pError[1]), readonly}}})
        if linenum > 0 then
            if txtdoc:is_locked(action:getfocus() & ".filepage") then
                txtdoc:queue_cmd(action:getfocus() & ".filepage", "jump", {"location", linenum, 0, linenum, "$"})
            else
                txtdoc:queue_cmd(action:getfocus() & ".filepage", "jump", {"location", linenum, 0})
                gui:set_key_focus(action:getfocus() & ".canvas")
            end if
        end if
    end if
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
    projEubinPath = 0,
    projIncludePath = 0,
    projHeader = {},
    projIncludes = {},
    projModified = 0,
    projInfoVars = {},
    projBookmarks = {},
    projOpenFiles = {}
    
    sequence dSections = {}, dNames = {}, dValues = {}

    atom fn, eq
    object ln, cdata = {}, vdata, selfiles, varval
    sequence csection = "", vname, pvars
    
    if length(projfile) = 0 then
        selfiles = dlgfile:os_select_open_file("winMain", {{"RedyCode Project", "*.redy"}}, 0)
        if sequence(selfiles) then
            projfile = selfiles
        end if
    end if
    
    projPath = pathname(projfile)
    projName = filebase(projfile)
    
    
    cfg:load_config(projfile)
    pvars = cfg:list_vars(projfile, "App Info")
    if length(pvars) > 0 then
        for v = 1 to length(pvars) do
            if match("AppInfo.", pvars[v]) = 1 then
                varval = cfg:get_var(projfile, "App Info", pvars[v])
                if sequence(varval) then
                    --varval = escape(varval)
                    projInfoVars &= {{pvars[v][9..$], split(varval, "\\n")}}
                end if
            end if
        end for
    end if
    
    pvars = cfg:list_vars(projfile, "Header")
    if length(pvars) > 0 then
        for v = 1 to length(pvars) do
            if match("Header.", pvars[v]) = 1 then
                varval = cfg:get_var(projfile, "Header", pvars[v])
                if sequence(varval) then
                    --varval = escape(varval)
                    projHeader &= {varval}
                end if
            end if
        end for
    end if
    
    --Open Files
    
    --Bookmarks
    
    cfg:close_config(projfile)
    
    
    if atom(projIncludePath) then
        projIncludePath = cfg:get_var("", "Paths", "IncludePath")
    end if
    if sequence(projIncludePath) then
        projIncludes &= {projIncludePath}
    end if
    
    gui:wdestroy("cntProject")
    gui:wcreate({
        {"name", "cntProject"},
        {"parent", "panelProject"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", "btnRun"},
        {"parent", "cntProject"},
        {"class", "button"},
        {"label", "Run " & pDefaultApp}
    })
    gui:wcreate({
        {"name", "treeProject"},
        {"parent", "cntProject"},
        {"class", "treebox"}
    })
    
    
    pPath = projPath
    pName = projName
    pDefaultApp = projDefaultApp
    pError = 0
    
    pEubinPath = projEubinPath
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
    pFolderNodes = {}
    pExpandedFolders = {}
    
    pInfoVars = projInfoVars

    pBookmarks = projBookmarks
    pOpenFiles = projOpenFiles

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
        pError = 0
        
        pEubinPath = 0
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
        pFolderNodes = {}
        pExpandedFolders = {}
        
        pInfoVars = {}
        
        pBookmarks = {}
        pOpenFiles = {}
        
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
    
    if length(pPath) > 0 and length(pName) > 0 then
        save_project_settings(pPath & "\\" & pName & ".redy")
    end if
end procedure


procedure do_project_explore_folder()
    if length(pPath) > 0 then
        atom wh = gui:widget_get_handle("winMain")
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
    object prevError = pError
    
    if length(pPath) = 0 then
        action:do_proc("list_projects", {})
    else
        gui:wproc("treeProject", "clear_tree", {})
        --pProjectNode = gui:wfunc("treeProject", "add_item", {0, "redy16", "Project: " & pName, 0})
        --pBuildNode = gui:wfunc("treeProject", "add_item", {0, "ex16", "Build", 0})
        --pDocsNode = gui:wfunc("treeProject", "add_item", {0, "folder_open_16", "Docs", 0})
        pSourceNode = gui:wfunc("treeProject", "add_item", {0, "folder_open_16", "Source", 1})
        pIncludesNode = gui:wfunc("treeProject", "add_item", {0, "folder_open_16", "Includes", 1})
        pFileNodes = {}
        pFolderNodes = {}
        
        build_dir(pSourceNode, pPath & "\\source\\", 0)
        build_app_list()
        
        for f = 1 to length(pIncludes) do --TODO: only show libraries that are actually included
        --    fnode = gui:wfunc("treeProject", "add_item", {pIncludesNode, "folder_open_16", pIncludes[f][1], 0})
        --    build_dir(fnode, pIncludes[f][2], 1)
            build_dir(pIncludesNode, pIncludes[f] & "\\", 1)
        end for
        
        /*pError = build:check_error() --noerror: 0, error: {errfile, errline, errtxt}
        
        if sequence(pError) > 0 then
            action:set_enabled("project_show_error", 1)
            if not equal(prevError, pError) then
                action:do_proc("project_show_error", {})
            end if
        else
            action:set_enabled("project_show_error", 0)
        end if*/
    end if
end procedure


procedure show_project_settings(atom newproj)
    sequence wintitle
    object projPath, projName, projDefaultApp, projTemplate, projHeader
    object projEubinPath, projIncludePath, projInfoVars, projBookmarks, projOpenFiles --, projRedyLibPath
    atom defEubinPath, defIncludePath --, defRedyLibPath
    atom overrideEubinPath, overrideIncludePath --, overrideRedyLibPath
    sequence EubinPathTxt, IncludePathTxt --, RedyLibPathTxt
    
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
        
        projEubinPath = 0
        --projRedyLibPath = 0
        projIncludePath = 0
        
        projInfoVars = {}
        projHeader = {}
        sequence pvars = cfg:list_vars("", "Projects")
        object varval
        for v = 1 to length(pvars) do
            if match("DefaultInfoVar.", pvars[v]) = 1 then
                varval = cfg:get_var("", "Projects", pvars[v])
                if sequence(varval) then
                    projInfoVars &= {{pvars[v][16..$], split(varval, "\\n")}}
                end if
            elsif match("DefaultHeader.", pvars[v]) = 1 then
                varval = cfg:get_var("", "Projects", pvars[v])
                if sequence(varval) then
                    projHeader &= {varval}
                end if
            end if
        end for
        InfoVars = projInfoVars
       
        
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
        
        projEubinPath = pEubinPath
        projIncludePath = pIncludePath
        
        projInfoVars = pInfoVars
        InfoVars = pInfoVars
        projHeader = pHeader
    end if
    
    /*if atom(projEubinPath) then
        defEubinPath = 1
        overrideEubinPath = 0
        EubinPathTxt = cfg:get_var("", "Paths", "EubinPath")
    else
        defEubinPath = 0
        overrideEubinPath = 1
        EubinPathTxt = projEubinPath
    end if
    
    if atom(projIncludePath) then
        defIncludePath = 1
        overrideIncludePath = 0
        IncludePathTxt = cfg:get_var("", "Paths", "IncludePath")
    else
        defIncludePath = 0
        overrideIncludePath = 0 --1 --temp fix, need to make check boxes override properly
        IncludePathTxt = projIncludePath
    end if*/
    
    gui:wcreate({
        {"name", "winProjectSettings"},
        {"class", "window"},
        --{"mode", "dialog"},
        {"handler", routine_id("gui_event")},
        {"title", wintitle},
        {"topmost", 1},
        {"size", {800, 600}}
    })
    gui:wcreate({
        {"name", "winProjectSettings.cntMain"},
        {"parent", "winProjectSettings"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    gui:wcreate({
        {"name", "winProjectSettings.cntTop"},
        {"parent", "winProjectSettings.cntMain"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
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
    
    -- project template
    gui:wcreate({
        {"name",  "winProjectSettings.txtTemplate"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Template"},
        {"text", projTemplate}
    })
    
    if newproj then
        gui:wcreate({
            {"name", "winProjectSettings.cntTemplate"},
            {"parent", "winProjectSettings.cntTop"},
            {"class", "container"},
            {"orientation", "horizontal"},
            {"justify_x", "left"},
            {"sizemode_x", "normal"},
            {"sizemode_y", "normal"}
        })
        gui:wcreate({
            {"name",  "winProjectSettings.togTemplate"},
            {"parent",  "winProjectSettings.cntTemplate"},
            {"class", "toggle"},
            {"style", "button"},
            {"label", "Select Template"}
        })
        gui:wcreate({
            {"name", "winProjectSettings.cntTemplateList"},
            {"parent", "winProjectSettings.cntTop"},
            {"class", "container"},
            {"orientation", "vertical"},
            {"sizemode_x", "expand"},
            {"sizemode_y", "expand"}
        })
    end if
    
    gui:wcreate({
        {"name",  "winProjectSettings.lstInfoVars"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "listbox"},
        {"label", "App Info Variables"},
        {"text", ""}
    })
    gui:wproc("winProjectSettings.lstInfoVars", "add_column", {{"Name", 150, 0, 0}})
    gui:wproc("winProjectSettings.lstInfoVars", "add_column", {{"Text", 300, 0, 0}})
    
    refresh_infovar_list()
    
    gui:wcreate({
        {"name",  "winProjectSettings.txtVarName"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Variable Name"},
        {"mode", "string"}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.txtVarString"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Variable Text"},
        {"mode", "text"},
        {"monowidth", 1}
    })
    gui:wcreate({
        {"name", "winProjectSettings.cntInfoVars"},
        {"parent", "winProjectSettings.cntTop"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"justify_x", "left"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.btnInfoVarsAdd"},
        {"parent",  "winProjectSettings.cntInfoVars"},
        {"class", "button"},
        {"label", "Add"}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.btnInfoVarsRemove"},
        {"parent",  "winProjectSettings.cntInfoVars"},
        {"class", "button"},
        {"label", "Remove"}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.btnInfoVarsInsert"},
        {"parent",  "winProjectSettings.cntInfoVars"},
        {"class", "button"},
        {"label", "Insert into Header"}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.btnInfoVarTextLoad"},
        {"parent",  "winProjectSettings.cntInfoVars"},
        {"class", "button"},
        {"label", "Load Text File..."}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.btnInfoVarsReset"},
        {"parent",  "winProjectSettings.cntInfoVars"},
        {"class", "button"},
        {"label", "Load Defaults"}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.txtHeader"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Source File Header"},
        {"mode", "text"},
        {"label_position", "above"},
        {"monowidth", 1},
        {"text", projHeader}
    })
    gui:wcreate({
        {"name", "winProjectSettings.cntHeader"},
        {"parent", "winProjectSettings.cntTop"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"justify_x", "left"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.btnHeaderLoad"},
        {"parent",  "winProjectSettings.cntHeader"},
        {"class", "button"},
        {"label", "Load Text File..."}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.btnHeaderReset"},
        {"parent",  "winProjectSettings.cntHeader"},
        {"class", "button"},
        {"label", "Load Default"}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.txtHeader"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Source File Header"},
        {"mode", "text"},
        {"monowidth", 1},
        {"text", projHeader}
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
            {"label", "Save project file"}
            
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
    cfg:load_config(projfile)
    cfg:delete_section(projfile, "App Info")
    for i = 1 to length(pInfoVars) do
        cfg:set_var(projfile, "App Info", "AppInfo." & pInfoVars[i][1], join(pInfoVars[i][2], "\\n"))
    end for
    
    cfg:delete_section(projfile, "Header")
    for i = 1 to length(pHeader) do
        cfg:set_var(projfile, "Header", "Header." & sprint(i), pHeader[i])
    end for
    
    cfg:delete_section(projfile, "Open Files")
    --for i = 1 to length(pOpenFiles) do
    --    cfg:set_var(projfile, "Open Files", pOpenFiles[i][1], pOpenFiles[i][2])
    --end for
    
    cfg:delete_section(projfile, "Bookmarks")
    --for i = 1 to length(pBookmarks) do
    --    cfg:set_var(projfile, "Bookmarks", pBookmarks[i][1], pBookmarks[i][2])
    --end for
    
    cfg:save_config(projfile)
    cfg:close_config(projfile)
    
    --Scan project source files
    
     
    --update headers
    
    --update app:define({})
    
end procedure


procedure do_list_projects()
    sequence listitems = {}
    object projpath = get_projects_path()
    object plist = dir(projpath), flist
    
    if not gui:wexists("panelProject") then
        gui:wcreate({
            {"name", "panelProject"},
            {"parent", "winMain"},
            {"class", "panel"},
            {"label", "Project"},
            {"dock", "left"},
            {"handler", routine_id("gui_event")}
        })
    end if
    if not gui:wexists("lstProjects") then
        prevProjectList = {}
        gui:wdestroy("cntProject")
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
            {"label", "Create new project..."}
        })
        gui:wcreate({
            {"name", "btnOpenProject"},
            {"parent", "cntProject"},
            {"class", "button"},
            {"label", "Open other project..."}
        })
        gui:wcreate({
            {"name", "lstProjects"},
            {"parent", "cntProject"},
            {"class", "fancylist"},
            {"label", "Open a project:"}
        })
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
    
    if not equal(prevProjectList, listitems) then
        prevProjectList = listitems
        gui:wproc("lstProjects", "select_items", {0})
        gui:wproc("lstProjects", "clear_list", {})
        gui:wproc("lstProjects", "add_list_items", {listitems})
    end if
end procedure


procedure create_project()
    object
    projname = gui:wfunc("winProjectSettings.txtName", "get_text", {}),
    projpath = gui:wfunc("winProjectSettings.txtPath", "get_text", {}) & "\\" & projname,
    projdefaultapp = gui:wfunc("winProjectSettings.txtDefaultApp", "get_text", {}),
    projtemplatename = gui:wfunc("winProjectSettings.txtTemplate", "get_text", {}),
    projtemplate = cfg:get_var("", "Paths", "TemplatePath") & "\\" & projtemplatename,
    projheader = gui:wfunc("winProjectSettings.txtHeader", "get_text", {})
    atom ofn, ifn
    
    if atom(projtemplate) or not file_exists(projtemplate) then
        if not equal("empty", projtemplatename) then
            msgbox:msg("Template '" & projtemplate & "' does not exist. Defaulted to empty project.", "Error")
        end if
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
        
        object ln, fq = {}, sf = dir(projtemplate & "\\source\\")
        
        if sequence(sf) and length(sf) > 0 then
            for f = 1 to length(sf) do
                fq &= {{"", sf[f]}}
            end for
        end if
        
        while length(fq) > 0 do
            --pretty_print(1, {fq[1][1], fq[1][2][D_NAME]}, {2}) 
            
            if find('d', fq[1][2][D_ATTRIBUTES]) then
                if not find(fq[1][2][D_NAME], {".", ".."}) then
                    sf = dir(projtemplate & "\\source\\" & fq[1][1] & fq[1][2][D_NAME] & "\\")
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
                        puts(ofn, context:header_code(InfoVars, projheader))
                    end if
                    
                    --append copy of source file
                    ifn = open(projtemplate & "\\source\\" & fq[1][1] & fq[1][2][D_NAME], "r")
                    if ifn = -1 then
                        --msgbox:msg("Unable to open file'" & projtemplate & "\\" & fq[1][1] & fq[1][2][D_NAME] & "'.", "Error")
                        --return
                    else
                        while 1 do
                            ln = gets(ifn)
                            if sequence(ln) then
                            
                                if match("app:define({})", ln) then
                                    puts(ofn, context:app_info_code(InfoVars))
                                else
                                    puts(ofn, ln)
                                end if
                            else
                                exit
                            end if
                        end while
                        close(ifn)
                    end if
                    close(ofn)
                    
                else
                    filesys:copy_file(
                        projtemplate & "\\source\\" & fq[1][1] & fq[1][2][D_NAME],
                        projpath & "\\source\\" & fq[1][1] & fq[1][2][D_NAME]
                    )
                end if
            end if
            
            fq = fq[2..$]
        end while
        
    else --create empty project
        
        /*if not create_directory(projpath & "\\source\\docs") then
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
        end if*/
        
        
        --create main source file
        if not create_file(projpath & "\\source\\" & projname & ".exw") then
            msgbox:msg("Unable to create file '" & projpath & "\\source\\" & projname & ".exw'.", "Error")
            return
        end if
        if sequence(projheader) and length(projheader) > 0 then
            ofn = open(projpath & "\\source\\" & projname & ".exw", "w")
            puts(ofn, context:header_code(InfoVars, projheader))
            puts(ofn, "\n\n\n")
            close(ofn)
        end if
        
    end if
    
    pPath = projpath
    pName = projname
    pDefaultApp = projdefaultapp
    pInfoVars = InfoVars
    pHeader = projheader
    --get_project_settings()
    
    save_project_settings(projpath & "\\" & projname & ".redy")
    gui:wdestroy("winProjectSettings")
    action:do_proc("project_load", {projpath & "\\" & projname & ".redy"})
end procedure


procedure get_project_settings()
    pHeader = gui:wfunc("winProjectSettings.txtHeader", "get_text", {})
    pInfoVars = InfoVars
end procedure


-------------------------------


function get_projects_path()
    object ppath = cfg:get_var("", "Paths", "ProjectPath")
    if atom(ppath) or not file_exists(ppath) then
        ppath = ""
    end if
    
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
    atom dnode, expanded
     
    flist = dir(path)
    
    if sequence(flist) then
        --scan for subfolders
        for f = 1 to length(flist) do 
            ficon = ""
            if find('d', flist[f][D_ATTRIBUTES]) and not find(flist[f][D_NAME], {".", ".."}) then
                ficon = "folder_open_16"
                
                --pExpandedFolders: {path1, path2, ...}
                expanded = (find(path & flist[f][D_NAME], pExpandedFolders) > 0) 
                
                dnode = gui:wfunc("treeProject", "add_item", {parentnodeid, ficon, flist[f][D_NAME], expanded})
                --build_dir(dnode, path & "\\" & flist[f][D_NAME] & "\\", readonly)
                build_dir(dnode, path & flist[f][D_NAME] & "\\", readonly)
                pFolderNodes &= {{dnode, path & flist[f][D_NAME]}}
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


export procedure update_bookmarks(sequence iname, sequence bookmarks)
    --sequence tablist = app:list_tabs() --needed to match iname with tab?
    
end procedure


export procedure refresh_infovar_list()
    sequence itms = {}
    for i = 1 to length(InfoVars) do
        itms &= {{rgb(255, 255, 255), InfoVars[i][1], join(InfoVars[i][2], "\\n")}}
    end for
    gui:wproc("winProjectSettings.lstInfoVars", "set_list_items", {itms})
end procedure


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
        
        if equal(evtype, "expand_item") then
            for f = 1 to length(pFolderNodes) do
                if pFolderNodes[f][1] = evdata[1] then
                    pExpandedFolders &= {pFolderNodes[f][2]}
                    --puts(1, "expand:<" & pFolderNodes[f][2] & ">")
                    exit
                end if
            end for
            
        elsif equal(evtype, "collapse_item") then
            for f = 1 to length(pFolderNodes) do
                if pFolderNodes[f][1] = evdata[1] then
                    atom ef = find(pFolderNodes[f][2], pExpandedFolders)
                    if ef > 0 then
                        pExpandedFolders = remove(pExpandedFolders, ef)
                        --puts(1, "collapse:<" & pFolderNodes[f][2] & ">")
                        exit
                    end if
                end if
            end for
            
        else
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
        end if
        
        
    case "winProjectSettings.togTemplate" then
        if equal(evtype, "value") then
            if evdata then
                gui:wcreate({
                    {"name",  "winProjectSettings.lstTemplates"},
                    {"parent",  "winProjectSettings.cntTemplateList"},
                    {"class", "listbox"},
                    {"label", "Templates"}
                })
                --gui:wproc("winProjectSettings.lstTemplates", "clear_list", {})
                gui:wproc("winProjectSettings.lstTemplates", "add_column", {{"Name", 150, 0, 0}})
                gui:wproc("winProjectSettings.lstTemplates", "add_column", {{"Description", 300, 0, 0}})
                
                object tpath = cfg:get_var("", "Paths", "TemplatePath")
                sequence tlist = {
                    {"document-new", "empty", "One empty source file"}
                }
                if sequence(tpath) and file_exists(tpath) then
                    object flist = dir(tpath), TempInfo, TempDescription
                    if sequence(flist) then
                        for f = 1 to length(flist) do
                            if find('d', flist[f][D_ATTRIBUTES]) and not find(flist[f][D_NAME], {".", ".."}) then
                                if file_exists(tpath & "\\" & flist[f][D_NAME] & "\\source\\TempMain.exw") then
                                    TempInfo = io:read_lines(tpath & "\\" & flist[f][D_NAME] & "\\TempInfo.txt")
                                    
                                    if sequence(TempInfo) and length(TempInfo) > 0 then
                                        TempDescription = TempInfo[1]
                                    else
                                        TempDescription = ""
                                    end if
                                    tlist &= {
                                        --{"text-x-generic-template", "default", "Template path"},
                                        {"document-new", flist[f][D_NAME], TempDescription}
                                    }
                                end if
                            end if
                        end for
                    end if
                else
                    tlist = {
                        {"dialog-error", "", "Error: Invalid template path."}
                    }
                end if                    

                gui:wproc("winProjectSettings.lstTemplates", "set_list_items", {tlist})
            else
                gui:wdestroy("winProjectSettings.lstTemplates")
            end if
        end if
        
    case "winProjectSettings.lstTemplates" then
        if equal(evtype, "selection") and length(evdata) > 0 then
            gui:wproc("winProjectSettings.txtTemplate", "set_text", {evdata[1][2][1]})
            
            --projtemplate = cfg:get_var("", "Paths", "TemplatePath") & "\\" & gui:wfunc("winProjectSettings.txtTemplate", "get_text", {}),
        end if
        
        
        
        
        
        
    case "winProjectSettings.lstInfoVars" then
    if equal(evtype, "selection") and length(evdata) > 0 then
        CurrInfoVarIdx = evdata[1][1]
        gui:wproc("winProjectSettings.txtVarName", "set_text", {evdata[1][2][1]})
        gui:wproc("winProjectSettings.txtVarString", "set_text", {split(evdata[1][2][2], "\\n")})
        
    elsif equal(evtype, "left_double_click") then
        if sequence(evdata) and length(evdata) > 0 then
            gui:wproc("winProjectSettings.txtHeader", "insert_text", {"$" & evdata[1][2][1]})
        end if
    end if
        
    case "winProjectSettings.txtVarName" then
        if equal(evtype, "changed") then
            sequence txt = gui:wfunc("winProjectSettings.txtVarName", "get_text", {})
            if CurrInfoVarIdx > 0 and CurrInfoVarIdx <= length(InfoVars) then
                InfoVars[CurrInfoVarIdx][1] = flatten(txt)
                refresh_infovar_list()
            end if
        end if
        
    case "winProjectSettings.txtVarString" then
        if equal(evtype, "changed") then
            sequence txt = gui:wfunc("winProjectSettings.txtVarString", "get_text", {})
            if CurrInfoVarIdx > 0 and CurrInfoVarIdx <= length(InfoVars) then
                InfoVars[CurrInfoVarIdx][2] = txt
                refresh_infovar_list()
            end if
        end if
        
    case "winProjectSettings.btnInfoVarsAdd" then
        if CurrInfoVarIdx > 0 and CurrInfoVarIdx <= length(InfoVars) then
            InfoVars = InfoVars[1..CurrInfoVarIdx] & {{"NewVar", {"NewString"}}} & InfoVars[CurrInfoVarIdx+1..$]
            CurrInfoVarIdx += 1
        else
            InfoVars &= {{"NewVar", {"NewString"}}}
            CurrInfoVarIdx = length(InfoVars)
        end if
        refresh_infovar_list()
        gui:wproc("winProjectSettings.lstInfoVars", "select_items", {{CurrInfoVarIdx}})
        
    case "winProjectSettings.btnInfoVarsRemove" then
        if CurrInfoVarIdx > 0 and CurrInfoVarIdx <= length(InfoVars) then
            InfoVars = remove(InfoVars, CurrInfoVarIdx)
            if CurrInfoVarIdx > length(InfoVars) then
                CurrInfoVarIdx = length(InfoVars)
            end if
        end if
        refresh_infovar_list()
        gui:wproc("winProjectSettings.lstInfoVars", "select_items", {{CurrInfoVarIdx}})
    
    case "winProjectSettings.btnInfoVarsReset" then
        InfoVars = {}
        sequence pvars = cfg:list_vars("", "Projects")
        object varval
        for v = 1 to length(pvars) do
            if match("DefaultInfoVar.", pvars[v]) = 1 then
                varval = cfg:get_var("", "Projects", pvars[v])
                if sequence(varval) then
                    InfoVars &= {{pvars[v][16..$], split(varval, "\\n")}}
                end if
            end if
        end for
        refresh_infovar_list()
    if CurrInfoVarIdx > length(InfoVars) then
        CurrInfoVarIdx = length(InfoVars)
    end if
    gui:wproc("winProjectSettings.lstInfoVars", "select_items", {{CurrInfoVarIdx}})
        
    case "winProjectSettings.btnInfoVarsInsert" then
        if CurrInfoVarIdx > 0 and CurrInfoVarIdx <= length(InfoVars) then
            gui:wproc("winProjectSettings.txtHeader", "insert_text", {"$" & InfoVars[CurrInfoVarIdx][1]})
        end if
    case "winProjectSettings.btnInfoVarTextLoad" then
        object selfiles = dlgfile:os_select_open_file("winProjectSettings", {{"Text Files", "*.txt"}, {"All Files", "*.*"}}, 0)
        if sequence(selfiles) then
            object txt = read_file(selfiles)
            if sequence(txt) then
                gui:wproc("winProjectSettings.txtVarString", "set_text", {txt})
            end if
        end if
        
    case "winProjectSettings.txtHeader" then
    case "winProjectSettings.btnHeaderReset" then
        sequence txt = {}
        sequence pvars = cfg:list_vars("", "Projects")
        object varval
        for v = 1 to length(pvars) do
            if match("DefaultHeader.", pvars[v]) = 1 then
                varval = cfg:get_var("", "Projects", pvars[v])
                if sequence(varval) then
                    txt &= {varval}
                end if
            end if
        end for
        gui:wproc("winProjectSettings.txtHeader", "set_text", {txt})
        
    case "winProjectSettings.btnHeaderLoad" then
        object selfiles = dlgfile:os_select_open_file("winProjectSettings", {{"Text Files", "*.txt"}, {"All Files", "*.*"}}, 0)
        if sequence(selfiles) then
            object txt = read_file(selfiles)
            if sequence(txt) then
                gui:wproc("winProjectSettings.txtHeader", "set_text", {txt})
            end if
        end if
            
            
            
          
            
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















