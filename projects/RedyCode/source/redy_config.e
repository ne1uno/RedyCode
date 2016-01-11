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

-- Edit configuration file for Redy environment (redy.cfg)
--
--"C:\RedyCode\projects\RedyCode\source\RedyExec.exw"
--"C:\RedyCode\bin\RedyExec.exe"
--
--scan euphoria folders:
--"C:\euphoria\"
--"C:\RedyCode\euphoria\"
--"..\..\..\euphoria\" (if starting from "\projects\RedyCode\source\RedyExec.exw")
--"..\euphoria\" (if starting from "\bin\RedyExec.exe")
--
--eu files:
--EuiCon = eufolder & "bin\eui.exe"
--EuiWin = eufolder & "bin\euiw.exe"
--Euc = eufolder & "bin\euc.exe"
--Eub = eufolder & "bin\eub.exe"
--
--EuInclude = eufolder & "include"
--EuDocs = eufolder & "docs\html\index.html"
--
--scan project folders:
--"..\..\" (if starting from "projects\RedyCode\source\RedyExec.exw")
--"..\projects\" (if starting from "bin\RedyExec.exe")
--
--each project's project file:
--ProjFile = projectsfolder & "*.redy"
--
--each project's apps:
--BinApps = projectsfolder & "build\*.exe"
--SrcApps = projectsfolder & "source\*.ex" or projectsfolder & "source\*.exw"
--
-------------------------------------------------------------------------------
-- 
-- "redy.cfg" format:
-- 
-- [Euphoria_4.1.0 dev 32-bit]
-- EuiCon = "C:\Euphoria\bin\eui.exe"
-- EuiWin = "C:\Euphoria\bin\euiw.exe"
-- Euc ="C:\Euphoria\bin\euc.exe"
-- Eub = "C:\Euphoria\bin\eub.exe"
-- EuInclude = "C:\Euphoria\include"
-- EuDocs = "C:\Euphoria\docs\html\index.html"
-- 
-- [Redy Paths]
-- RedyLib = "C:\RedyCode\redylib"
-- Projects = "C:\RedyCode\projects"
-- 
-- [Defaults]
-- EuVersion = "Euphoria_4.1.0 dev 32-bit"
-- Redylib = "dev"


without warning

include gui/gui.e as gui
include gui/dialogs/msgbox.e as msgbox
include app/msg.e as msg
include app/config.e as cfg

include std/task.e
include std/text.e
include std/pretty.e
include std/filesys.e

sequence 
EuVersions = {},
EuiCons = {},
EuiWins = {},
Eucs = {},
Eubs = {},
EuIncludes = {},
EuDocs = {},

RedylibVersions = {},
RedylibPaths = {}

object
ProjectsPath = ""

atom
DefaultEuIdx = 0,
DefaultRedylibIdx = 0,

selectedEuIdx = 0,
selectedRedylibIdx = 0

constant
ActiveEuIcon = rgb(140, 140, 255),
InactiveEuIcon = rgb(190, 190, 190),
ActiveRedyIcon = rgb(140, 140, 255),
InactiveRedyIcon = rgb(190, 190, 190)


atom lastnum = 0
function nextnum()
    lastnum += 1
    return sprint(lastnum)
end function

procedure scan_euphoria_paths()
    object flist
    sequence currpath, scanpaths = {
        current_dir() & "/euphoria/",
        "C:/Euphoria/",
        "C:/RedyCode/euphoria/"
    }
    sequence euicons, euiwin, euc, eub, euinclude, eudocs
    atom found
    
    EuVersions = {}
    EuiCons = {}
    EuiWins = {}
    Eucs = {}
    Eubs = {}
    EuIncludes = {}
    EuDocs = {}
    DefaultEuIdx = 0
    selectedEuIdx = 0
    
    while length(scanpaths) > 0 do
        currpath = scanpaths[1]
        scanpaths = scanpaths[2..$]
        
        euicons = ""
        euiwin = ""
        euc = ""
        eub = ""
        euinclude = ""
        eudocs = ""
        
        flist = dir(currpath)
        if sequence(flist) then
            found = 0
            for f = 1 to length(flist) do 
                if find('d', flist[f][D_ATTRIBUTES]) and equal(flist[f][D_NAME], "bin") then
                    found = 1
                    if file_exists(currpath & "bin/eui.exe") then
                        euicons = currpath & "bin/eui.exe"
                    end if
                    if file_exists(currpath & "bin/euiw.exe") then
                        euiwin = currpath & "bin/euiw.exe"
                    end if
                    if file_exists(currpath & "bin/euc.exe") then
                        euc = currpath & "bin/euc.exe"
                    end if
                    if file_exists(currpath & "bin/eub.exe") then
                        eub = currpath & "bin/eub.exe"
                    end if
                    if file_exists(currpath & "include/std/sequence.e") then
                        euinclude = currpath & "include/"
                    end if
                    if file_exists(currpath & "docs/html/index.html") then
                        eudocs = currpath & "docs/html/"
                    end if
                end if
            end for
            
            if length(euicons) > 0 and length(euiwin) > 0 and length(euc) > 0 and length(eub) > 0 and length(euinclude) > 0 then
                EuVersions &= {currpath}
                EuiCons &= {euicons}
                EuiWins &= {euiwin}
                Eucs &= {euc}
                Eubs &= {eub}
                EuIncludes &= {euinclude}
                EuDocs &= {eudocs}
            end if
            
            if found = 0 then
                for f = 1 to length(flist) do 
                    if find('d', flist[f][D_ATTRIBUTES]) and not find(flist[f][D_NAME], {".", ".."}) then
                        scanpaths &= {currpath & flist[f][D_NAME] & "/"}
                    end if
                end for
            end if
        end if
    end while
end procedure


procedure scan_redy_paths()
    object flist
    sequence currpath, scanpaths = {
        current_dir() & "/redylib/"
    }
    sequence redylibpath
    --atom found = 0
    RedylibVersions = {}
    RedylibPaths = {}
    DefaultRedylibIdx = 0
    selectedRedylibIdx = 0
    
    while length(scanpaths) > 0 do --and found = 0 do
        currpath = scanpaths[1]
        scanpaths = scanpaths[2..$]
        
        flist = dir(currpath)
        if sequence(flist) then
            for f = 1 to length(flist) do 
                if find('d', flist[f][D_ATTRIBUTES]) and not find(flist[f][D_NAME], {".", ".."}) then
                    if file_exists(currpath & flist[f][D_NAME] & "/gui/gui.e") then
                        RedylibVersions &= {flist[f][D_NAME]}
                        RedylibPaths &= {currpath & flist[f][D_NAME] & "/"}
                        --found = 1
                    end if
                end if
            end for
        end if
    end while
end procedure


procedure scan_project_paths()
    object flist
    sequence currpath, scanpaths = {
        current_dir() & "/"
    }
    
    while length(scanpaths) > 0 do
        currpath = scanpaths[1]
        scanpaths = scanpaths[2..$]
        
        flist = dir(currpath)
        if sequence(flist) then
            for f = 1 to length(flist) do 
                if find('d', flist[f][D_ATTRIBUTES]) and equal(flist[f][D_NAME], "projects") then
                    ProjectsPath = currpath & flist[f][D_NAME] & "/"
                    return
                end if
            end for
        end if
    end while
end procedure


procedure save_config()
    cfg:clear_config("redy.cfg")
    
    for s = 1 to length(EuVersions) do
        cfg:set_var("redy.cfg", "Euphoria_" & EuVersions[s], "EuiCon", EuiCons[s])
        cfg:set_var("redy.cfg", "Euphoria_" & EuVersions[s], "EuiWin", EuiWins[s])
        cfg:set_var("redy.cfg", "Euphoria_" & EuVersions[s], "Euc", Eucs[s])
        cfg:set_var("redy.cfg", "Euphoria_" & EuVersions[s], "Eub", Eubs[s])
        cfg:set_var("redy.cfg", "Euphoria_" & EuVersions[s], "EuInclude", EuIncludes[s])
        cfg:set_var("redy.cfg", "Euphoria_" & EuVersions[s], "EuDoc", EuDocs[s])
    end for
    
    for s = 1 to length(RedylibVersions) do
        cfg:set_var("redy.cfg", "Redylib_" & RedylibVersions[s], "Path", RedylibPaths[s])
    end for
    
    if sequence(ProjectsPath) then
        cfg:set_var("redy.cfg", "Projects", "Projects", ProjectsPath)
    end if
    cfg:set_var("redy.cfg", "Defaults", "EuphoriaIdx", DefaultEuIdx)
    cfg:set_var("redy.cfg", "Defaults", "RedylibIdx", DefaultRedylibIdx)
    
    cfg:save_config("redy.cfg")
    
    msg:publish("config", "command", "refresh_projects", 0)
end procedure


procedure load_config()
    EuVersions = {}
    EuiCons = {}
    EuiWins = {}
    Eucs = {}
    Eubs = {}
    EuIncludes = {}
    EuDocs = {}
    
    RedylibVersions = {}
    RedylibPaths = {}
    
    ProjectsPath = ""
    
    cfg:load_config("redy.cfg")
    
    sequence csections = cfg:list_sections("redy.cfg")
    for s = 1 to length(csections) do
        if match("Euphoria_", csections[s]) = 1 then
            EuVersions &= {csections[s][10..$]}
            EuiCons &= {cfg:get_var("redy.cfg", csections[s], "EuiCon")}
            EuiWins &= {cfg:get_var("redy.cfg", csections[s], "EuiWin")}
            Eucs &= {cfg:get_var("redy.cfg", csections[s], "Euc")}
            Eubs &= {cfg:get_var("redy.cfg", csections[s], "Eub")}
            EuIncludes &= {cfg:get_var("redy.cfg", csections[s], "EuInclude")}
            EuDocs &= {cfg:get_var("redy.cfg", csections[s], "EuDoc")}
            
        elsif match("Redylib_", csections[s]) = 1 then
            RedylibVersions &= {csections[s][9..$]}
            RedylibPaths &= {cfg:get_var("redy.cfg", csections[s], "Path")}
        end if
    end for
    
    ProjectsPath = cfg:get_var("redy.cfg", "Projects", "Projects")
    if atom(ProjectsPath) then
        ProjectsPath = ""
    end if
    
    DefaultEuIdx = cfg:get_var("redy.cfg", "Defaults", "EuphoriaIdx")
    DefaultRedylibIdx = cfg:get_var("redy.cfg", "Defaults", "RedylibIdx")
    
    if DefaultEuIdx = 0 then
        DefaultEuIdx = 1
    end if
    if DefaultEuIdx > length(EuVersions) then
        DefaultEuIdx = length(EuVersions)
    end if
    if DefaultRedylibIdx = 0 then
        DefaultRedylibIdx = 1
    end if
    if DefaultRedylibIdx > length(RedylibVersions) then
        DefaultRedylibIdx = length(RedylibVersions)
    end if
    
    /*
    sequence cvars
    for s = 1 to length(csections) do
        cvars = cfg:list_vars("redy.cfg", csections[s])
        for v = 1 to length(cvars) do
            --gui:debug(csections[s] & ":" & cvars[v], cfg:get_var("redy.cfg", csections[s], cvars[v]))
        end for
    end for*/
end procedure


procedure refresh_lists()
    --Euphoria:
    if DefaultEuIdx = 0 then
        DefaultEuIdx = 1
    end if
    if DefaultEuIdx > length(EuVersions) then
        DefaultEuIdx = length(EuVersions)
    end if
    if selectedEuIdx = 0 then
        selectedEuIdx = 1
    end if
    if selectedEuIdx > length(EuVersions) then
        selectedEuIdx = length(EuVersions)
    end if
    sequence listitems = {}
    for i = 1 to length(EuVersions) do
        if i = DefaultEuIdx then
            listitems &= {{ActiveEuIcon, EuVersions[i]}}
        else
            listitems &= {{InactiveEuIcon, EuVersions[i]}}
        end if
    end for
    gui:wproc("winConfig.lstEuphoria", "clear_list", {})
    gui:wproc("winConfig.lstEuphoria", "add_list_items", {listitems})
    if selectedEuIdx > 0 then
        gui:wproc("winConfig.lstEuphoria", "set_selection", {selectedEuIdx, 0})
    end if
    
    if DefaultRedylibIdx = 0 then
        DefaultRedylibIdx = 1
    end if
    if DefaultRedylibIdx > length(RedylibVersions) then
        DefaultRedylibIdx = length(RedylibVersions)
    end if
    if selectedRedylibIdx = 0 then
        selectedRedylibIdx = 1
    end if
    if selectedRedylibIdx > length(RedylibVersions) then
        selectedRedylibIdx = length(RedylibVersions)
    end if
    listitems = {}
    for i = 1 to length(RedylibVersions) do
        if i = DefaultRedylibIdx then
            listitems &= {{ActiveRedyIcon, RedylibVersions[i]}}
        else
            listitems &= {{InactiveRedyIcon, RedylibVersions[i]}}
        end if
    end for
    gui:wproc("winConfig.lstRedylib", "clear_list", {})
    gui:wproc("winConfig.lstRedylib", "add_list_items", {listitems})
    if selectedRedylibIdx > 0 then
        gui:wproc("winConfig.lstRedylib", "set_selection", {selectedRedylibIdx, 0})
    end if
end procedure


procedure refresh_euphoria()
    sequence euversion = "",
    euicons = "",
    euiwin = "",
    euc = "",
    eub = "",
    euinclude = "",
    eudoc = ""
    atom eudefault = 0
    
    if selectedEuIdx > 0 and selectedEuIdx <= length(EuVersions) then
        euversion = EuVersions[selectedEuIdx]
        euicons = EuiCons[selectedEuIdx]
        euiwin = EuiWins[selectedEuIdx]
        euc = Eucs[selectedEuIdx]
        eub = Eubs[selectedEuIdx]
        euinclude = EuIncludes[selectedEuIdx]
        eudoc = EuDocs[selectedEuIdx]
        if DefaultEuIdx = selectedEuIdx then
            eudefault = 1
        end if
    end if
    gui:wproc("winConfig.txtEuVersion", "set_text", {euversion})
    gui:wproc("winConfig.txtEuEuiCon", "set_text", {euicons})
    gui:wproc("winConfig.txtEuEuiWin", "set_text", {euiwin})
    gui:wproc("winConfig.txtEuc", "set_text", {euc})
    gui:wproc("winConfig.txtEub", "set_text", {eub})
    gui:wproc("winConfig.txtEuInclude", "set_text", {euinclude})
    gui:wproc("winConfig.txtEuDoc", "set_text", {eudoc})
    gui:wproc("winConfig.chkEuDefault", "set_value", {eudefault})
end procedure


procedure refresh_redylib()
    sequence redylibversion = "",
    redylibpath = ""
    atom redylibdefault = 0
    
    if selectedRedylibIdx > 0 and selectedRedylibIdx <= length(RedylibVersions) then
        redylibversion = RedylibVersions[selectedRedylibIdx]
        redylibpath = RedylibPaths[selectedRedylibIdx]
        if DefaultRedylibIdx = selectedRedylibIdx then
            redylibdefault = 1
        end if
    end if
    gui:wproc("winConfig.txtRedylibVersion", "set_text", {redylibversion})
    gui:wproc("winConfig.txtRedylibPath", "set_text", {redylibpath})
    gui:wproc("winConfig.chkRedylibDefault", "set_value", {redylibdefault})
end procedure


procedure refresh_projects()
    gui:wproc("winConfig.txtProjectsPath", "set_text", {ProjectsPath})
end procedure


export function get_eui_path(atom idx = 0)
    sequence ret = ""
    if idx = 0 then
        idx = DefaultEuIdx
    end if
    if idx > 0 and idx <= length(EuiCons) then
        ret = EuiCons[idx]
    end if
    return ret
end function


export function get_euiw_path(atom idx = 0)
    sequence ret = ""
    if idx = 0 then
        idx = DefaultEuIdx
    end if
    if idx > 0 and idx <= length(EuiCons) then
        ret = EuiWins[idx]
    end if
    return ret
end function


export function get_euc_path(atom idx = 0)
    sequence ret = ""
    if idx = 0 then
        idx = DefaultEuIdx
    end if
    if idx > 0 and idx <= length(Eucs) then
        ret = Eucs[idx]
    end if
    return ret
end function


export function get_eub_path(atom idx = 0)
    sequence ret = ""
    if idx = 0 then
        idx = DefaultEuIdx
    end if
    if idx > 0 and idx <= length(Eubs) then
        ret = Eubs[idx]
    end if
    return ret
end function


export function get_euinclude_path(atom idx = 0)
    sequence ret = ""
    if idx = 0 then
        idx = DefaultEuIdx
    end if
    if idx > 0 and idx <= length(EuIncludes) then
        ret = EuIncludes[idx][1..$-1]
    end if
    return ret
end function


export function get_eudocs_path(atom idx = 0)
    sequence ret = ""
    if idx = 0 then
        idx = DefaultEuIdx
    end if
    if idx > 0 and idx <= length(EuDocs) then
        ret = EuDocs[idx]
    end if
    return ret
end function


export function get_redylib_path(atom idx = 0)
    sequence ret = ""
    if idx = 0 then
        idx = DefaultRedylibIdx
    end if
    if idx > 0 and idx <= length(RedylibPaths) then
        ret = RedylibPaths[idx][1..$-1]
    end if
    return ret
end function


export function get_default_eu()
    sequence ret = ""
    if DefaultEuIdx > 0 and DefaultEuIdx <= length(EuVersions) then
        ret = EuVersions[DefaultEuIdx]
    end if
    return ret
end function


export function get_default_redylib()
    sequence ret = ""
    if DefaultRedylibIdx > 0 and DefaultRedylibIdx <= length(RedylibVersions) then
        ret = RedylibVersions[DefaultRedylibIdx]
    end if
    return ret
end function


export function get_default_include_path()
    sequence ret = ""
    if DefaultEuIdx > 0 and DefaultEuIdx <= length(EuIncludes) then
        ret = EuIncludes[DefaultEuIdx]
    end if
    return ret
end function


export function get_default_redylib_path()
    sequence ret = ""
    if DefaultRedylibIdx > 0 and DefaultRedylibIdx <= length(RedylibPaths) then
        ret = RedylibPaths[DefaultRedylibIdx]
    end if
    return ret
end function


export function get_projects_path()
    return ProjectsPath
end function


export procedure gui_event(object evwidget, object evtype, object evdata)
    switch evwidget do
        case "winConfig.tabCategories" then
            --if equal(evtype, "selection") then
            --end if
            
        case "winConfig.cmdEuScan" then
            scan_euphoria_paths()
            refresh_lists()
            refresh_euphoria()
            
        case "winConfig.cmdEuAdd" then
            EuVersions &= {"newversion" & nextnum()}
            EuiCons &= {"NEWPATH/bin/euic.exe"}
            EuiWins &= {"NEWPATH/bin/euiw.exe"}
            Eucs &= {"NEWPATH/bin/euc.exe"}
            Eubs &= {"NEWPATH/bin/eub.exe"}
            EuIncludes &= {"NEWPATH/include/"}
            EuDocs &= {"NEWPATH/docs/html"}
            if DefaultEuIdx = 0 then
                DefaultEuIdx = 1
            end if
            if selectedEuIdx = 0 then
                selectedEuIdx = 1
            end if
            refresh_lists()
            refresh_euphoria()
            refresh_redylib()
            refresh_projects()
            
        case "winConfig.cmdEuRemove" then
            EuVersions = remove(EuVersions, selectedEuIdx)
            EuiCons = remove(EuiCons, selectedEuIdx)
            EuiWins = remove(EuiWins, selectedEuIdx)
            Eucs = remove(Eucs, selectedEuIdx)
            Eubs = remove(Eubs, selectedEuIdx)
            EuIncludes = remove(EuIncludes, selectedEuIdx)
            EuDocs = remove(EuDocs, selectedEuIdx)
            refresh_lists()
            refresh_euphoria()
            
        case "winConfig.lstEuphoria" then
            if equal(evtype, "selection") and length(evdata) > 0 then
                if selectedEuIdx != evdata[1][1] then
                    selectedEuIdx = evdata[1][1]
                    refresh_euphoria()
                end if
            end if
            
        case "winConfig.txtEuVersion" then
            if equal(evtype, "changed") then
                if selectedEuIdx > 0 and selectedEuIdx <= length(EuVersions) then
                    EuVersions[selectedEuIdx] = gui:wfunc("winConfig.txtEuVersion", "get_text", {})
                    refresh_lists()
                end if
            end if
            
        case "winConfig.txtEuEuiCon" then
            if equal(evtype, "changed") then
                if selectedEuIdx > 0 and selectedEuIdx <= length(EuVersions) then
                    EuiCons[selectedEuIdx] = gui:wfunc("winConfig.txtEuEuiCon", "get_text", {})
                end if
            end if
            
        case "winConfig.txtEuEuiWin" then
            if equal(evtype, "changed") then
                if selectedEuIdx > 0 and selectedEuIdx <= length(EuVersions) then
                    EuiWins[selectedEuIdx] = gui:wfunc("winConfig.txtEuEuiWin", "get_text", {})
                end if
            end if
            
        case "winConfig.txtEuc" then
            if equal(evtype, "changed") then
                if selectedEuIdx > 0 and selectedEuIdx <= length(EuVersions) then
                    Eucs[selectedEuIdx] = gui:wfunc("winConfig.txtEuc", "get_text", {})
                end if
            end if
            
        case "winConfig.txtEub" then
            if equal(evtype, "changed") then
                if selectedEuIdx > 0 and selectedEuIdx <= length(EuVersions) then
                    Eubs[selectedEuIdx] = gui:wfunc("winConfig.txtEub", "get_text", {})
                end if
            end if
            
        case "winConfig.txtEuInclude" then
            if equal(evtype, "changed") then
                if selectedEuIdx > 0 and selectedEuIdx <= length(EuVersions) then
                    EuIncludes[selectedEuIdx] = gui:wfunc("winConfig.txtEuInclude", "get_text", {})
                end if
            end if
            
        case "winConfig.txtEuDoc" then
            if equal(evtype, "changed") then
                if selectedEuIdx > 0 and selectedEuIdx <= length(EuVersions) then
                    EuDocs[selectedEuIdx] = gui:wfunc("winConfig.txtEuDoc", "get_text", {})
                end if
            end if
            
        case "winConfig.chkEuDefault" then
            if equal(evtype, "value") then
                if selectedEuIdx > 0 and selectedEuIdx <= length(EuVersions) then
                    if evdata = 1 then
                        DefaultEuIdx = selectedEuIdx
                        refresh_lists()
                    else
                        if DefaultEuIdx = selectedEuIdx then
                            gui:wproc("winConfig.chkEuDefault", "set_value", {1})
                        end if
                    end if
                end if
            end if
            
        case "winConfig.cmdRedylibScan" then
            scan_redy_paths()
            refresh_lists()
            refresh_redylib()
            
        case "winConfig.cmdRedylibAdd" then
            RedylibVersions &= {"newversion" & nextnum()}
            RedylibPaths &= {"NEWPATH"}
            if DefaultRedylibIdx = 0 then
                DefaultRedylibIdx = 1
            end if
            if selectedRedylibIdx = 0 then
                selectedRedylibIdx = 1
            end if
            refresh_lists()
            refresh_redylib()
            
        case "winConfig.cmdRedylibRemove" then
            RedylibVersions = remove(RedylibVersions, selectedRedylibIdx)
            RedylibPaths = remove(RedylibPaths, selectedRedylibIdx)
            refresh_lists()
            refresh_redylib()
            
        case "winConfig.lstRedylib" then
            if equal(evtype, "selection") and length(evdata) > 0 then
                if selectedRedylibIdx != evdata[1][1] then
                    selectedRedylibIdx = evdata[1][1]
                    refresh_redylib()
                end if
            end if
            
        case "winConfig.txtRedylibVersion" then
            if equal(evtype, "changed") then
                if selectedRedylibIdx > 0 and selectedRedylibIdx <= length(RedylibVersions) then
                    RedylibVersions[selectedRedylibIdx] = gui:wfunc("winConfig.txtRedylibVersion", "get_text", {})
                    refresh_lists()
                end if
            end if
            
        case "winConfig.txtRedylibPath" then
            if equal(evtype, "changed") then
                if selectedRedylibIdx > 0 and selectedRedylibIdx <= length(RedylibVersions) then
                    RedylibPaths[selectedRedylibIdx] = gui:wfunc("winConfig.txtRedylibPath", "get_text", {})
                end if
            end if
            
        case "winConfig.chkRedylibDefault" then
            if equal(evtype, "value") then
                if selectedRedylibIdx > 0 and selectedRedylibIdx <= length(RedylibVersions) then
                    if evdata = 1 then
                        DefaultRedylibIdx = selectedRedylibIdx
                        refresh_lists()
                    else
                        if DefaultRedylibIdx = selectedRedylibIdx then
                            gui:wproc("winConfig.chkRedylibDefault", "set_value", {1})
                        end if
                    end if
                end if
            end if
            
        case "winConfig.cmdProjectsScan" then
            scan_project_paths()
            refresh_projects()
            
        case "winConfig.txtProjectsPath" then
            if equal(evtype, "changed") then
                ProjectsPath = gui:wfunc("winConfig.txtProjectsPath", "get_text", {})
            end if
            
        case "winConfig.btnSave" then
            save_config()
            gui:wdestroy("winConfig")
            
        case "winConfig.btnCancel" then
            gui:wdestroy("winConfig")
            
        case "winConfig" then
            if equal(evtype, "closed") then
                gui:wdestroy("winConfig")
            end if
            
    end switch
end procedure


function msg_event(sequence subscribername, sequence topicname, sequence msgname, object msgdata)
    switch topicname do
        case "command" then
            if equal(msgname, "config") then
                show()
            end if
    end switch
    
    return 1
end function


procedure show()
    load_config()
    if gui:wexists("winConfig") then
         gui:wdestroy("winConfig")
    end if
    
    gui:wcreate({
        {"name", "winConfig"},
        {"class", "window"},
        {"mode", "window"},
        {"handler", routine_id("gui_event")},
        {"title", "Redy Environment Configuration"},
        {"topmost", 1},
        {"size", {750, 400}}
    })
    gui:wcreate({
        {"name", "winConfig.cntMain"},
        {"parent", "winConfig"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    gui:wcreate({
        {"name", "winConfig.tabCategories"},
        {"parent", "winConfig.cntMain"},
        {"class", "tabs"}
        --{"orientation", "vertical"},
        --{"sizemode_x", "expand"},
        --{"sizemode_y", "expand"}
    })
    
    --Euphoria Config
    gui:wcreate({
        {"name", "winConfig.cntEuTab"},
        {"parent", "winConfig.tabCategories"},
        {"class", "container"},
        {"label", "Euphoria"},
        {"orientation", "horizontal"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", "winConfig.cntEuLeft"},
        {"parent", "winConfig.cntEuTab"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", "winConfig.cntEuLeftCmds"},
        {"parent", "winConfig.cntEuLeft"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"},
        {"justsify_x", "center"}
    })
    gui:wcreate({
        {"name", "winConfig.cmdEuScan"},
        {"parent", "winConfig.cntEuLeftCmds"},
        {"class", "button"},
        {"label", "Scan folders"}
    })
    gui:wcreate({
        {"name", "winConfig.cmdEuAdd"},
        {"parent", "winConfig.cntEuLeftCmds"},
        {"class", "button"},
        {"label", "Add"}
    })
    gui:wcreate({
        {"name", "winConfig.cmdEuRemove"},
        {"parent", "winConfig.cntEuLeftCmds"},
        {"class", "button"},
        {"label", "Remove"}
    })
    gui:wcreate({
        {"name", "winConfig.lstEuphoria"},
        {"parent", "winConfig.cntEuLeft"},
        {"class", "listbox"},
        {"label", "Euphoria Versions"}
    })
    gui:wcreate({
        {"name", "winConfig.divEu"},
        {"parent", "winConfig.cntEuTab"},
        {"class", "divider"},
        {"attach", "winConfig.cntEuLeft"},
        {"adjust", 300}
    })
    gui:wcreate({
        {"name", "winConfig.cntEuRight"},
        {"parent", "winConfig.cntEuTab"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", "winConfig.txtEuVersion"},
        {"parent", "winConfig.cntEuRight"},
        {"class", "textbox"},
        {"label", "Version"},
        {"text", ""}
    })
    gui:wcreate({
        {"name", "winConfig.txtEuEuiCon"},
        {"parent", "winConfig.cntEuRight"},
        {"class", "textbox"},
        {"label", "Eui Path"},
        {"text", ""}
    })
    gui:wcreate({
        {"name", "winConfig.txtEuEuiWin"},
        {"parent", "winConfig.cntEuRight"},
        {"class", "textbox"},
        {"label", "Euiw Path"},
        {"text", ""}
    })
    gui:wcreate({
        {"name", "winConfig.txtEuc"},
        {"parent", "winConfig.cntEuRight"},
        {"class", "textbox"},
        {"label", "Euc Path"},
        {"text", ""}
    })
    gui:wcreate({
        {"name", "winConfig.txtEub"},
        {"parent", "winConfig.cntEuRight"},
        {"class", "textbox"},
        {"label", "Eub Path"},
        {"text", ""}
    })
    gui:wcreate({
        {"name", "winConfig.txtEuInclude"},
        {"parent", "winConfig.cntEuRight"},
        {"class", "textbox"},
        {"label", "Eu Include Path"},
        {"text", ""}
    })
    gui:wcreate({
        {"name", "winConfig.txtEuDoc"},
        {"parent", "winConfig.cntEuRight"},
        {"class", "textbox"},
        {"label", "Eu Docs Path"},
        {"text", ""}
    })
    gui:wcreate({
        {"name", "winConfig.chkEuDefault"},
        {"parent", "winConfig.cntEuRight"},
        {"class", "toggle"},
        {"label", "Use as Default"}
    })
    
    --Redylib Config
    gui:wcreate({
        {"name", "winConfig.cntRedylibTab"},
        {"parent", "winConfig.tabCategories"},
        {"class", "container"},
        {"label", "Redylib"},
        {"orientation", "horizontal"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", "winConfig.cntRedylibLeft"},
        {"parent", "winConfig.cntRedylibTab"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", "winConfig.cntRedylibLeftCmds"},
        {"parent", "winConfig.cntRedylibLeft"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"},
        {"justsify_x", "center"}
    })
    gui:wcreate({
        {"name", "winConfig.cmdRedylibScan"},
        {"parent", "winConfig.cntRedylibLeftCmds"},
        {"class", "button"},
        {"label", "Scan folders"}
    })
    gui:wcreate({
        {"name", "winConfig.cmdRedylibAdd"},
        {"parent", "winConfig.cntRedylibLeftCmds"},
        {"class", "button"},
        {"label", "Add"}
    })
    gui:wcreate({
        {"name", "winConfig.cmdRedylibRemove"},
        {"parent", "winConfig.cntRedylibLeftCmds"},
        {"class", "button"},
        {"label", "Remove"}
    })
    gui:wcreate({
        {"name", "winConfig.lstRedylib"},
        {"parent", "winConfig.cntRedylibLeft"},
        {"class", "listbox"},
        {"label", "Redylib Versions"}
    })
    gui:wcreate({
        {"name", "winConfig.divRedylib"},
        {"parent", "winConfig.cntRedylibTab"},
        {"class", "divider"},
        {"attach", "winConfig.cntRedylibLeft"},
        {"adjust", 300}
    })
    gui:wcreate({
        {"name", "winConfig.cntRedylibRight"},
        {"parent", "winConfig.cntRedylibTab"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", "winConfig.txtRedylibVersion"},
        {"parent", "winConfig.cntRedylibRight"},
        {"class", "textbox"},
        {"label", "Version"},
        {"text", ""}
    })
    gui:wcreate({
        {"name", "winConfig.txtRedylibPath"},
        {"parent", "winConfig.cntRedylibRight"},
        {"class", "textbox"},
        {"label", "Path"},
        {"text", ""}
    })
    gui:wcreate({
        {"name", "winConfig.chkRedylibDefault"},
        {"parent", "winConfig.cntRedylibRight"},
        {"class", "toggle"},
        {"label", "Use as Default"}
    })
    
    --Projects Config
    gui:wcreate({
        {"name", "winConfig.cntProjectsTab"},
        {"parent", "winConfig.tabCategories"},
        {"class", "container"},
        {"label", "Projects"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", "winConfig.cntProjectsCmds"},
        {"parent", "winConfig.cntProjectsTab"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "normal"},
        {"sizemode_y", "normal"},
        {"justsify_x", "center"}
    })
    gui:wcreate({
        {"name", "winConfig.cmdProjectsScan"},
        {"parent", "winConfig.cntProjectsCmds"},
        {"class", "button"},
        {"label", "Scan folders"}
    })
    gui:wcreate({
        {"name", "winConfig.txtProjectsPath"},
        {"parent", "winConfig.cntProjectsTab"},
        {"class", "textbox"},
        {"label", "Projects Path"},
        {"text", ""}
    })
    
    gui:wcreate({
        {"name", "winConfig.cntBottom"},
        {"parent", "winConfig.cntMain"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "equal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"}
    })
    gui:wcreate({
        {"name", "winConfig.btnSave"},
        {"parent", "winConfig.cntBottom"},
        {"class", "button"},
        {"label", "Save"}
    })
    gui:wcreate({
        {"name", "winConfig.btnCancel"},
        {"parent", "winConfig.cntBottom"},
        {"class", "button"},
        {"label", "Cancel"}
    })
    
    gui:wproc("winConfig.tabCategories", "select_tab", {"Euphoria"})
    
    refresh_lists()
    refresh_euphoria()
    refresh_redylib()
    refresh_projects()
end procedure


export procedure start()
    msg:subscribe("config", "command", routine_id("msg_event"))
    load_config()
    
    if length(EuIncludes) = 0
    or length(EuiWins) = 0
    or length(RedylibPaths) = 0
    or length(ProjectsPath) = 0 then
        show()
        msgbox:msg("It appears that the Redy environment needs to be configured. Please set up paths to Euphoria, RedyLib, and your Projects folder.", "Info")
    end if
end procedure

