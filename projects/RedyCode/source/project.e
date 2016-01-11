-- This file is part of RedyCode™ Integrated Development Environment
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


include gui/gui.e as gui
include gui/objects/textedit.e as txte
include gui/dialogs/dialog_file.e as dlgfile
include gui/dialogs/msgbox.e as msgbox
include app/msg.e as msg

include redy_config.e as config --redy environment config dialog
include tablist.e as tabs --tab manager
include edit_images.e as images
include edit_source.e as source
include edit_build.e as build
include edit_docs.e as docs

include std/task.e
include std/text.e
include std/pretty.e
include std/utils.e
include std/filesys.e
include std/sequence.e as seq
include std/convert.e
include std/error.e


--puts(1, curdir() & "\n")
--puts(1, canonical_path(ImgPath) & "\n")

------------------------

object
pPath = "",         --project folder path
pName = "",         --project name (used for name of *.redy file)
pEuphoria = 0,      --0=use default eu version, sequence=override eu version
pRedyLib = 0,       --0=use default RedyLib version, sequence=override RedyLib version
pVersion = "",      --Project Version
pAuthor = "",       --Project Author
pDescription = {},  --Project Description
pLicense = {},      --Project License
pIncludes = "",     --List of addition include folders
pModified = 0,      --Whether or not any files in project are modified

pProjectNode = 0,   --project properties node
pBuildNode = 0,     --build node
pDocsNode = 0,      --docs folder node
pSourceNode = 0,    --source folder node
pIncludesNode = 0,  --redylib, stdlib, and additional include folders node
pFileNodes = {}     --list of file tree nodes, so clicking on node can open the associated file (each one is {nodeid, filepath, filename, readonly})


atom SettingsTabWid = 0


procedure build_app_list()
    object flist = dir(pPath & "\\source\\")
    sequence AppList = {}
    
    if sequence(flist) then
        for f = 1 to length(flist) do
            if not find('d', flist[f][D_ATTRIBUTES]) and not find(flist[f][D_NAME], {".", ".."}) then
                if find(fileext(flist[f][D_NAME]), {"ex", "exw", "eu"}) then --euphoria executable
                    AppList &= {flist[f][D_NAME]}
                end if
            end if
        end for
    end if
    msg:publish("project", "command", "AppList", AppList)
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
                if find(fileext(flist[f][D_NAME]), {"cfg", "ini"}) then --config file
                    ficon = "txt16"
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
                    ficon = "img16"
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


procedure refresh_source_tree() --scan source folders for files and subfolders, rebuild tree
    atom fnode
    
    gui:wproc("treeProject", "clear_tree", {})
    pProjectNode = gui:wfunc("treeProject", "add_item", {0, "redy16", "Project: " & pName, 0})
    pBuildNode = gui:wfunc("treeProject", "add_item", {0, "ex16", "Build", 0})
    pDocsNode = gui:wfunc("treeProject", "add_item", {0, "folder_open_16", "Docs", 0})
    pSourceNode = gui:wfunc("treeProject", "add_item", {0, "folder_open_16", "Source", 1})
    pIncludesNode = gui:wfunc("treeProject", "add_item", {0, "folder_open_16", "Includes", 1})
    pFileNodes = {}
    
    build_dir(pSourceNode, pPath & "\\source\\", 0)
    build_app_list()
    
    for f = 1 to length(pIncludes) do
        fnode = gui:wfunc("treeProject", "add_item", {pIncludesNode, "folder_open_16", pIncludes[f][1], 0})
        build_dir(fnode, pIncludes[f][2], 1)
    end for
end procedure


procedure load_project(sequence projfile)
    object
    projPath = dirname(projfile),
    projName = filebase(projfile),
    projEuphoria = 0,
    projRedyLib = 0,
    projVersion = "",
    projAuthor = "",
    projDescription = {},
    projLicense = {},
    projIncludes = "",
    projModified = 0
    
    sequence dSections = {}, dNames = {}, dValues = {}

    atom fn, eq
    object ln, cdata = {}, vdata
    sequence csection = "", vname
    
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
                    case "version" then
                        projVersion = dValues[v]
                    case "author" then
                        projAuthor = dValues[v]
                    case "description" then
                        projDescription &= {dValues[v]}
                    case "license" then 
                        projLicense &= {dValues[v]}
                end switch
            case "Euphoria" then
                switch dNames[v] do
                    case "version" then 
                        projEuphoria = dValues[v]
                end switch
            case "RedyLib" then
                switch dNames[v] do
                    case "version" then 
                        projRedyLib = dValues[v]
                end switch
            case "Include Paths" then
                if sequence(dValues[v]) and length(dValues[v]) > 0 then
                    projIncludes &= {{dNames[v], dValues[v]}}
                end if
        end switch
    end for
    
    if atom(projEuphoria) then
        projIncludes &=  {{"stdlib",  get_default_include_path()}} -- & "std\\"}}
    else
        projIncludes &=  {{"stdlib",  projEuphoria}}
    end if
    if atom(projRedyLib) then
        projIncludes &=  {{"redylib",  get_default_redylib_path()}}
    else
        projIncludes &=  {{"redylib",  projRedyLib}}
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
    pEuphoria = projEuphoria
    pRedyLib = projRedyLib
    pVersion = projVersion
    pAuthor = projAuthor
    pDescription = projDescription
    pLicense = projLicense
    pIncludes = projIncludes
    pModified = projModified
    
    pProjectNode = 0
    pBuildNode = 0
    pDocsNode = 0
    pSourceNode = 0
    pIncludesNode = 0
    pFileNodes = {}
    
    refresh_source_tree()
    
--msg:publish("project", "command", "RecentProjectList", 0)
    msg:publish("project", "command", "project_title", pPath)
end procedure


procedure create_project()
    object
    projpath = gui:wfunc("winProjectSettings.txtPath", "get_text", {}),
    projname = gui:wfunc("winProjectSettings.txtName", "get_text", {})
    --projfile = gui:wfunc("winProjectSettings.txtProjectFile", "get_text", {}),
    --projapp = gui:wfunc("winProjectSettings.txtAppFile", "get_text", {}),
    --projdefeu = gui:wfunc("winProjectSettings.chkDefaultEu", "get_value", {}),
    --projeu = gui:wfunc("winProjectSettings.txtEuphoria", "get_text", {}),
    --projdefredylib = gui:wfunc("winProjectSettings.chkDefaultRedylib", "get_value", {}),
    --projredylib = gui:wfunc("winProjectSettings.txtRedylib", "get_text", {}),
    --projversion = gui:wfunc("winProjectSettings.txtVersion", "get_text", {}),
    --projauthor = gui:wfunc("winProjectSettings.txtAuthor", "get_text", {}),
    --projdescription = gui:wfunc("winProjectSettings.txtDescription", "get_text", {}),
    --projlicense = gui:wfunc("winProjectSettings.txtLicense", "get_text", {})
    
    if not sequence(projpath) then
        msgbox:msg("Invalid project path.", "Error")
        return
    end if
    if not sequence(projname) then
        msgbox:msg("Invalid project name.", "Error")
        return
    end if
    
    --create projname folder and subfolders
    if file_exists(projpath & projname) then
        msgbox:msg("Unable to create project '" & projname & "'. Folder '" & projpath & projname
        & "' already exists. Please use a different project name.", "Error")
        return
    end if
    if not create_directory(projpath & projname) then
        msgbox:msg("Unable to create folder '" & projpath & projname & "'.", "Error")
        return
    end if
    if not create_directory(projpath & projname & "\\build") then
        msgbox:msg("Unable to create folder '" & projpath & projname & "\\build'.", "Error")
        return
    end if
    if not create_directory(projpath & projname & "\\build\\bin") then
        msgbox:msg("Unable to create folder '" & projpath & projname & "\\build\\bin'.", "Error")
        return
    end if
    if not create_directory(projpath & projname & "\\build\\install") then
        msgbox:msg("Unable to create folder '" & projpath & projname & "\\build\\install'.", "Error")
        return
    end if
    if not create_directory(projpath & projname & "\\docs") then
        msgbox:msg("Unable to create folder '" & projpath & projname & "\\docs'.", "Error")
        return
    end if
    if not create_directory(projpath & projname & "\\source") then
        msgbox:msg("Unable to create folder '" & projpath & projname & "\\source'.", "Error")
        return
    end if
    if not create_directory(projpath & projname & "\\source\\images") then
        msgbox:msg("Unable to create folder '" & projpath & projname & "\\source\\images'.", "Error")
        return
    end if
    
    --create projname.redy file
    if not create_file(projpath & projname & "\\" & projname & ".redy") then
        msgbox:msg("Unable to create file '" & projpath & projname & "\\" & projname & ".redy'.", "Error")
        return
    end if
    
    --create projname/source/projname.exw file
    if not create_file(projpath & projname & "\\source\\" & projname & ".exw") then
        msgbox:msg("Unable to create folder '" & projpath & projname & "\\source\\" & projname & ".exw'.", "Error")
        return
    end if
    
    pPath = projpath
    pName = projname
    
    get_project_settings()
    save_project(projpath & projname & "\\" & projname & ".redy.")
    gui:wdestroy("winProjectSettings")
    load_project(projpath & projname & "\\" & projname & ".redy.")
end procedure


procedure get_project_settings()
    object
    DefEuphoria = gui:wfunc("winProjectSettings.chkDefaultEu", "get_value", {}),
    EuphoriaTxt = gui:wfunc("winProjectSettings.txtEuphoria", "get_text", {}),
    DefRedyLib = gui:wfunc("winProjectSettings.chkDefaultRedylib", "get_value", {}),
    RedyLibTxt = gui:wfunc("winProjectSettings.txtRedylib", "get_text", {}),
    
    VersionTxt = gui:wfunc("winProjectSettings.txtVersion", "get_text", {}),
    AuthorTxt = gui:wfunc("winProjectSettings.txtAuthor", "get_text", {}),
    DescriptionTxt = gui:wfunc("winProjectSettings.txtDescription", "get_text", {}),
    LicenseTxt = gui:wfunc("winProjectSettings.txtLicense", "get_text", {})
    
    if DefEuphoria then
        pEuphoria = 0
    else
        pEuphoria = EuphoriaTxt
    end if
    if DefRedyLib then
        pRedyLib = 0
    else
        pRedyLib = RedyLibTxt
    end if
    pVersion = VersionTxt
    pAuthor = AuthorTxt
    pDescription = DescriptionTxt
    pLicense = LicenseTxt
    --pIncludes =  --TODO: implement editor for additional include paths 
end procedure 


procedure save_project(sequence projfile)
    object fn = open(projfile, "w")
    
    if fn = -1 then
        msgbox:msg("Unable to save project file '" & projfile & "'!", "Error")
    else
        puts(fn, "[Project]\n")
        puts(fn, "version = \"" & pVersion & "\"\n")
        puts(fn, "author = \"" & pAuthor & "\"\n")
        for li = 1 to length(pDescription) do
            puts(fn, "description = \"" & pDescription[li] & "\"\n")
        end for
        for li = 1 to length(pLicense) do
            puts(fn, "license = \"" & pLicense[li] & "\"\n")
        end for
        puts(fn, "\n")
        puts(fn, "[Euphoria]\n")
        if atom(pEuphoria) then
            puts(fn, "version = " & sprint(pEuphoria) & "\n")
        else
            puts(fn, "version = \"" & pEuphoria & "\"\n")
        end if
        puts(fn, "\n")
        puts(fn, "[RedyLib]\n")
        if atom(pRedyLib) then
            puts(fn, "version = " & sprint(pRedyLib) & "\n")
        else
            puts(fn, "version = \"" & pRedyLib & "\"\n")
        end if
        puts(fn, "\n")
        puts(fn, "[Include Paths]\n")
        puts(fn, "\n")
        
        for i = 1 to length(pIncludes) do
            if not find(pIncludes[i][1], {"stdlib", "redylib"}) then
                puts(fn, pIncludes[i][1] & " = \"" & pIncludes[i][2] & "\"\n")
            end if
        end for
        close(fn)
    end if
end procedure


procedure close_project()
    source:close_all()
    build:hide()
    images:hide()
    docs:hide()
    
    gui:wdestroy("winProjectSettings")
    gui:wproc("treeProject", "clear_tree", {})
    
    pPath = ""
    pName = ""
    pEuphoria = 0
    pRedyLib = 0
    pVersion = ""
    pAuthor = ""
    pDescription = {}
    pLicense = {}
    pIncludes = ""
    pModified = 0
    
    pProjectNode = 0
    pBuildNode = 0
    pDocsNode = 0
    pSourceNode = 0
    pIncludesNode = 0
    pFileNodes = {}
    
    msg:publish("project", "command", "project_title", "")
end procedure


procedure show_project_list()
    sequence listitems = {}
    object projpath = config:get_projects_path()
    object plist = dir(projpath), flist
    
    if sequence(plist) then
        for p = 1 to length(plist) do 
            if find('d', plist[p][D_ATTRIBUTES]) and not find(plist[p][D_NAME], {".", ".."}) then
                flist = dir(projpath & plist[p][D_NAME])
                if sequence(flist) then
                    for f = 1 to length(flist) do
                        if not find('d', flist[f][D_ATTRIBUTES]) then
                            if match(".redy", flist[f][D_NAME]) = length(flist[f][D_NAME]) - 4 then --project config file
                                listitems &= {{1, flist[f][D_NAME][1..$-5], canonical_path(projpath), plist[p][D_NAME] & "\\" & flist[f][D_NAME]}}
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
    
    gui:wproc("lstProjects", "clear_list", {})
    gui:wproc("lstProjects", "add_list_items", {listitems})
end procedure


procedure run_app(sequence appfile)
    if file_exists(appfile) then
        --puts(1, "Running '" & appfile & "'...\n")
        sequence cmdline = 
        --" -EUDIR \"\"" & eupath --is this needed to override possible conflicts with installed version of euphoria? 
        " -I \"" & get_redylib_path() & "\" -I \"" & get_euinclude_path() & "\" \"" & appfile & "\""
        --puts(1, cmdline & "\n")
        --puts(1, pPath & "\\source\\" & "\n")
        gui:ShellExecute(gui:widget_get_handle("winMain"), get_euiw_path(), cmdline, "open", pPath & "\\source\\")
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
                save_project(pPath & "\\" & pName & ".redy.")
                source:save_all()
                --images:
                --docs:
            end if
            close_project()
            show_project_list()
        elsif equal(ans, "No") then
            close_project()
            show_project_list()
        end if
    end if
end procedure

------------------------


procedure gui_event(object evwidget, object evtype, object evdata)
    switch evwidget do
        case "lstProjects" then
            --if equal(evtype, "left_double_click") then
            if equal(evtype, "selection") then
                if sequence(evdata) and length(evdata) > 0 then
                    --pretty_print(1, evdata, {2})
                    load_project(evdata[1][2][2] & evdata[1][2][3])
                end if
            end if
            
        case "btnNewProject" then
            msg:publish("project", "command", "new_project", 0)
            
        case "btnOpenProject" then
            msg:publish("project", "command", "open_project", 0)
            
        case "btnRun" then
            msg:publish("project", "command", "run_app", 0)
            
        case "treeProject" then
            -- "expand_item"
            
            if evdata[1] = pProjectNode then
                if equal(evtype, "selection") then
                    msg:publish("project", "command", "edit_project", 0)
                end if
                
            elsif evdata[1] = pBuildNode then
                if equal(evtype, "selection") then
                    msg:publish("project", "command", "edit_build", 0)
                end if
                
            elsif evdata[1] = pDocsNode then
                if equal(evtype, "selection") then
                    msg:publish("project", "command", "edit_docs", 0)
                end if
                
            elsif evdata[1] = pSourceNode then
                if equal(evtype, "selection") then
                    --msg:publish("project", "command", "edit_apps", 0)
                end if
                
            elsif evdata[1] = pIncludesNode then
                if equal(evtype, "selection") then
                    --msg:publish("project", "command", "edit_include_paths", 0)
                end if
                
            else
                --msg:publish("project", "command", "RecentFileList", 0)
                for f = 1 to length(pFileNodes) do
                    if pFileNodes[f][1] = evdata[1] then
                        if find(fileext(pFileNodes[f][3]), {"ex", "exw", "exu"}) then
                            if equal(evtype, "selection") then
                                source:load_file(pFileNodes[f][2] & pFileNodes[f][3], pFileNodes[f][4])
                            elsif equal(evtype, "left_double_click") then
                                run_app(pFileNodes[f][2] & pFileNodes[f][3])
                            end if
                        
                        elsif find(fileext(pFileNodes[f][3]), {"e", "ew", "eu"}) then
                            if equal(evtype, "selection") then
                                source:load_file(pFileNodes[f][2] & pFileNodes[f][3], pFileNodes[f][4])
                            end if
                            
                        elsif find(fileext(pFileNodes[f][3]), {"txt", "cfg", "ini", "bat", "xml"}) then
                            if equal(evtype, "selection") then
                                source:load_file(pFileNodes[f][2] & pFileNodes[f][3], pFileNodes[f][4])
                            end if
                            
                        elsif find(fileext(pFileNodes[f][3]), {"err"}) then
                            if equal(evtype, "selection") then
                                source:load_file(pFileNodes[f][2] & pFileNodes[f][3], pFileNodes[f][4])
                            end if
                            
                        elsif find(fileext(pFileNodes[f][3]), {"bmp", "ico", "png", "jpg", "gif", "svg"}) then
                            if equal(evtype, "selection") then
                                images:load_img(pFileNodes[f][2] & pFileNodes[f][3], pFileNodes[f][4])
                            end if
                            
                        else
                            --source:load_file(pFileNodes[f][2] & pFileNodes[f][3], pFileNodes[f][4])
                            if equal(evtype, "selection") then
                                msgbox:msg("Sorry, '" & fileext(pFileNodes[f][3]) & "' file type is not currently supported.", "Error")
                            end if
                            
                        end if
                    end if
                end for
            end if
            
        case "winProjectSettings.btnCreate" then
            create_project()
            
        case "winProjectSettings.btnClose" then
            if SettingsTabWid > 0 then
                tabs:destroy_tab(SettingsTabWid)
                SettingsTabWid = 0
            end if
            
        case "winProjectSettings.btnSave" then
            get_project_settings()
            msg:publish("project", "command", "save_project", 0)
            gui:wdestroy("winProjectSettings")
            
        case "winProjectSettings.btnCancel" then
            gui:wdestroy("winProjectSettings")
            
        case "winProjectSettings.txtName" then
            if equal(evtype, "changed") then
                sequence projname = gui:wfunc("winProjectSettings.txtName", "get_text", {})
                gui:wproc("winProjectSettings.txtProjectFile", "set_text", {projname & "\\" & projname & ".redy"})
                gui:wproc("winProjectSettings.txtAppFile", "set_text", {projname & "\\source\\" & projname & ".exw"})
            end if
            
    end switch
end procedure


function msg_event(sequence subscribername, sequence topicname, sequence msgname, object msgdata)
    switch topicname do
        case "command" then
            if equal(msgname, "tab_selected") then
                object tabfile, filetype = 0
                
                tabfile = source:tab_file(msgdata)
                if length(tabfile[1]) > 0 then
                    filetype = "source"
                end if
                
                if atom(filetype) then
                    tabfile = images:tab_file(msgdata)
                    if length(tabfile[1]) > 0 then
                        filetype = "image"
                    end if
                end if
                
                if atom(filetype) then
                    tabfile = docs:tab_file(msgdata)
                    if length(tabfile[1]) > 0 then
                        filetype = "doc"
                    end if
                end if
                
                if atom(filetype) then
                    --if projsettingstab = 1 then 
                    --    msg:publish("project", "command", "active_file", {"settings", msgdata[1], msgdata[2]})
                    --end if
                end if
                
                if sequence(filetype) then
                    msg:publish("project", "command", "active_file", {filetype, tabfile[1], tabfile[2]})
                else
                    msg:publish("project", "command", "active_file", 0)
                end if
                
                --check if any files have modified flag set
                atom isanymodified = 0
                if source:is_any_modified() then
                    isanymodified = 1
                end if
                if images:is_any_modified() then
                    isanymodified = 1
                end if
                if docs:is_any_modified() then
                    isanymodified = 1
                end if
                --if settingschanged then
                --    isanymodified = 1
                --end if
                pModified = isanymodified
                msg:publish("project", "command", "project_modified", isanymodified)
                
            elsif equal(msgname, "list_projects") then
                show_project_list()
                
            elsif equal(msgname, "new_project") then
                confirm_close_project()
                if length(pPath) = 0 then
                    show_project_settings(1)
                end if
                
            elsif equal(msgname, "open_project") then
                confirm_close_project()
                if length(pPath) = 0 then
                    if sequence(msgdata) then
                        load_project(msgdata)
                    else  --file not specified, show open file standard dialog instead
                        sequence ttype, tlabel, tname, tpathname, tfilename
                        object selfiles = dlgfile:os_select_open_file("winMain", {{"RedyCode Project", "*.redy"}}, 0)
                        
                        --pretty_print(1, selfiles, {2})
                        if sequence(selfiles) then
                            load_project(selfiles)
                        end if
                    end if
                end if
                
            elsif equal(msgname, "close_project") then
                confirm_close_project()
                
            elsif equal(msgname, "confirm_exit") then
                confirm_close_project()
                if length(pPath) = 0 then
                    msg:publish("menu", "command", "exit", 0)
                end if
                
            elsif equal(msgname, "reopen_project") then
                msgbox:msg("Sorry, this feature doesn't work yet :-(", "Info")
            elsif equal(msgname, "save_project") then
                if length(pPath) > 0 then
                    save_project(pPath & "\\" & pName & ".redy.")
                    source:save_all()
                    --images:
                    --docs:
                end if
                
            elsif equal(msgname, "save_project_as") then
                msgbox:msg("Sorry, this feature doesn't work yet :-(", "Info")
            elsif equal(msgname, "rename_project") then
                msgbox:msg("Sorry, this feature doesn't work yet :-(", "Info")
            elsif equal(msgname, "copy_project_to") then
                --todo: copy project folder to specified location
                msgbox:msg("Sorry, this feature doesn't work yet :-(", "Info")
                if length(pPath) > 0 then
                end if
                
            elsif equal(msgname, "delete_project") then
                
            elsif equal(msgname, "edit_project") then
                if length(pPath) > 0 then
                    show_project_settings(0)
                end if
                
            elsif equal(msgname, "edit_build") then
                build:show()
                
            elsif equal(msgname, "edit_docs") then
                docs:show()
                
            elsif equal(msgname, "edit_apps") then
                
            elsif equal(msgname, "edit_include_paths") then
                
            elsif equal(msgname, "explore") then
                if length(pPath) > 0 then
                    if atom(msgdata) then
                        gui:ShellExecute(gui:widget_get_handle("winMain"), pPath, "", "explore")
                    else
                        gui:ShellExecute(gui:widget_get_handle("winMain"), pPath & "\\" & msgdata, "", "explore")
                    end if
                end if
                 
            elsif equal(msgname, "refresh_projects") then
                if length(pPath) = 0 then
                    show_project_list()
                end if
                
            elsif equal(msgname, "refresh_source_tree") then
                refresh_source_tree() 
                
            elsif equal(msgname, "new_file") then
                msgbox:msg("Sorry, this feature doesn't work yet :-(", "Info")
                
            elsif equal(msgname, "open_file") then
                msgbox:msg("Sorry, this feature doesn't work yet :-(", "Info")
                --object selfiles = dlgfile:os_select_open_file("winMain", {{"File Type", "*.fileext"}}, 0)...
                
                
            elsif equal(msgname, "close_file") then
                if equal(msgdata[1], "source") then
                    source:confirm_close_file(msgdata[2])
                elsif equal(msgdata[1], "image") then
                    
                elsif equal(msgdata[1], "doc") then
                    
                elsif equal(msgdata[1], "settings") then
                    
                end if
                
            elsif equal(msgname, "close_all_files") then
                source:close_all()
                
            elsif equal(msgname, "reopen_file") then
                msgbox:msg("Sorry, this feature doesn't work yet :-(", "Info")
                if equal(msgdata[1], "source") then
                    
                elsif equal(msgdata[1], "image") then
                    
                elsif equal(msgdata[1], "doc") then
                    
                elsif equal(msgdata[1], "settings") then
                    
                end if
                
            elsif equal(msgname, "save_file") then
                if equal(msgdata[1], "source") then
                    source:save_file(msgdata[2])
                    
                elsif equal(msgdata[1], "image") then
                    
                elsif equal(msgdata[1], "doc") then
                    
                elsif equal(msgdata[1], "settings") then
                    
                end if
                
            elsif equal(msgname, "save_all_files") then
                --todo: all open source, docs, and image files 
                if length(pPath) > 0 then
                    --images:save_all_imgs()
                    source:save_all()
                    --docs:save_all_docs()
                end if
                
            elsif equal(msgname, "save_file_as") then
                msgbox:msg("Sorry, this feature doesn't work yet :-(", "Info")
                if equal(msgdata[1], "source") then
                    source:save_file_as(msgdata[2])
                elsif equal(msgdata[1], "image") then
                    
                elsif equal(msgdata[1], "doc") then
                    
                elsif equal(msgdata[1], "settings") then
                    
                end if
                
            elsif equal(msgname, "rename_file") then
                msgbox:msg("Sorry, this feature doesn't work yet :-(", "Info")
            elsif equal(msgname, "copy_file_to") then
                msgbox:msg("Sorry, this feature doesn't work yet :-(", "Info")
            elsif equal(msgname, "delete_file") then
                msgbox:msg("Sorry, this feature doesn't work yet :-(", "Info")
            elsif equal(msgname, "build") then
                msgbox:msg("Sorry, this feature doesn't work yet :-(", "Info")
            elsif equal(msgname, "error_report") then
                msgbox:msg("Sorry, this feature doesn't work yet :-(", "Info")
            elsif equal(msgname, "run_app") then
                if length(pPath) > 0 then
                    if atom(msgdata) then
                        run_app(pPath & "\\source\\" & pName & ".exw")
                    else
                        run_app(pPath & "\\source\\" & msgdata)
                    end if
                end if
                
            end if
    end switch
    
    return 1
end function

    
procedure show_project_settings(atom newproj)
    sequence wintitle
    object projPath, projName, projEuphoria, projRedyLib, projVersion, projAuthor, projDescription, projLicense
    atom defEuphoria, overrideEuphoria, defRedyLib, overrideRedyLib
    sequence EuphoriaTxt, RedyLibTxt
    
    if gui:wexists("winProjectSettings") then
         gui:wdestroy("winProjectSettings")
    end if
    
    if newproj then
        wintitle = "Create New Project"
        projPath = canonical_path(config:get_projects_path())
        projName = "NewProject"
        projEuphoria = 0
        projRedyLib = 0
        projVersion = "1.0.0"
        projAuthor = "ProjectAuthor"
        projDescription = "ProjectDescription"
        projLicense = ApacheLicense
    else
        if SettingsTabWid > 0 then --file is already open, so switch to it's tab instead
            select_tab(SettingsTabWid)
            return
        end if
        
        atom tabid = tabs:create("Project Settings")
        sequence parname = gui:widget_get_name(tabid) 
        sequence wname = sprint(tabid)
        SettingsTabWid = tabid
        
        wintitle = "Project Settings"
        projPath = pPath
        projName = pName
        projEuphoria = pEuphoria
        projRedyLib = pRedyLib
        projVersion = pVersion
        projAuthor = pAuthor
        projDescription = pDescription
        projLicense = pLicense
    end if
    
    if atom(projEuphoria) then
        defEuphoria = 1
        overrideEuphoria = 0
        EuphoriaTxt = get_default_eu()
    else
        defEuphoria = 0
        overrideEuphoria = 1
        EuphoriaTxt = projEuphoria
    end if
    if atom(projRedyLib) then
        defRedyLib = 1
        overrideRedyLib = 0
        RedyLibTxt = get_default_redylib()
    else
        defRedyLib = 0
        overrideRedyLib = 1
        RedyLibTxt = projRedyLib
    end if
    
    if newproj then
        gui:wcreate({
            {"name", "winProjectSettings"},
            {"class", "window"},
            --{"mode", "dialog"},
            {"handler", routine_id("gui_event")},
            {"title", wintitle},
            {"topmost", 1},
            {"size", {500, 550}}
        })
        gui:wcreate({
            {"name", "winProjectSettings.cntMain"},
            {"parent", "winProjectSettings"},
            {"class", "container"},
            {"orientation", "vertical"},
            {"sizemode_x", "expand"},
            {"sizemode_y", "expand"}
        })
    else
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
    end if
    
    
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
        {"text", projName},
        {"enabled", newproj}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.txtProjectFile"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Project File"},
        {"text", projName & "\\" & projName &".redy"},
        {"enabled", 0}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.txtAppFile"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Primary Application"},
        {"text", projName & "\\source\\" & projName & ".exw"},
        {"enabled", 0}
    })
    
    gui:wcreate({
        {"name",  "winProjectSettings.chkDefaultEu"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "toggle"},
        {"label", "Use default Euphoria version"},
        {"value", defEuphoria}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.txtEuphoria"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Euphoria Version"},
        {"text", EuphoriaTxt},
        {"enabled", overrideEuphoria}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.txtRedylib"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "toggle"},
        {"label", "Use default Redylib version"},
        {"value", defRedyLib}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.chkDefaultRedylib"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Redylib Version"},
        {"text", RedyLibTxt},
        {"enabled", overrideRedyLib}
    })
    
    gui:wcreate({
        {"name",  "winProjectSettings.txtVersion"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Project Version"},
        {"text", projVersion}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.txtAuthor"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Project Author"},
        {"text", projAuthor}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.txtDescription"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Project Description"},
        {"mode", "text"},
        {"monowidth", 1},
        {"text", projDescription}
    })
    gui:wcreate({
        {"name",  "winProjectSettings.txtLicense"},
        {"parent",  "winProjectSettings.cntTop"},
        {"class", "textbox"},
        {"label", "Project License"},
        {"mode", "text"},
        {"monowidth", 1},
        {"text", projLicense
        }
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
    end if
    
    
end procedure

export procedure start()
    gui:load_bitmap("folder_open_16", ImgPath & "folder_open_16.bmp")
    gui:load_bitmap("redy16", ImgPath & "redy16.bmp")
    gui:load_bitmap("e16", ImgPath & "e16.bmp")
    gui:load_bitmap("ex16", ImgPath & "ex16.bmp")
    gui:load_bitmap("err16", ImgPath & "err16.bmp")
    gui:load_bitmap("txt16", ImgPath & "txt16.bmp")
    gui:load_bitmap("img16", ImgPath & "img16.bmp")
    
    --http://findicons.com/
    
    /*gui:wcreate({
        {"name", "winProject"},
        {"class", "window"},
        {"mode", "normal"},
        {"handler", routine_id("gui_event")},
        {"title", "m_project"},
        {"position", {0, 30}},
        {"size", {200, 600}}
    })*/
    
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
        {"label", "Run"},
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
        {"name", "divProjects"},
        {"parent", "cntProject"},
        {"class", "divider"},
        {"attach", "treeProject"}
        --{"adjust", 200}
    })
    gui:wcreate({
        {"name", "treeContents"},
        {"parent", "cntProject"},
        {"class", "treebox"},
        {"label", "Jump to:"},
        {"visible", 0}
    })*/
    
    gui:wcreate({
        {"name", "cntMain"},
        {"parent", "winMain"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"},
        {"handler", routine_id("gui_event")}
    })
    
    tabs:start()
    
    msg:subscribe("project", "command", routine_id("msg_event"))
end procedure


