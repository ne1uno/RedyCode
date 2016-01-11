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

include tablist.e as tabs --tab manager

include std/task.e
include std/text.e
include std/pretty.e
include std/sequence.e
include std/filesys.e
include std/error.e
include std/datetime.e as dt
include std/filesys.e
include std/utils.e


enum    --srcfiles
fFilePathName,      --file path and name
fModified,          --file modified
fLocked,            --file locked (read only)
fTabWid,            --widget ID of file's tab
fRoutineNames,      --list of file's routine names
fRoutineLineNums,   --list of file's routine line numbers
fContext            --current context info

constant fLENGTH = fContext

sequence srcfiles = repeat({}, fLENGTH)


procedure txt_event(sequence evname, sequence evtype, object evdata)
    for f = 1 to length(srcfiles[fTabWid]) do
        if equal(evname, "txt" & sprint(srcfiles[fTabWid][f])) then
            switch evtype do
                case "modified" then
                    if evdata = 1 then
                        --set_tab_label(srcfiles[fTabWid][f], "*" & filename(srcfiles[fFilePathName][f]))
                        srcfiles[fModified][f] = 1
                        set_tab_flag(srcfiles[fTabWid][f], rgb(200, 0, 0))
                    else
                        --set_tab_label(srcfiles[fTabWid][f], filename(srcfiles[fFilePathName][f]))
                        srcfiles[fModified][f] = 0
                        set_tab_flag(srcfiles[fTabWid][f], -1)
                    end if
            end switch
            exit
        end if
    end for
end procedure

procedure select_tool(sequence wname, sequence toolname)
    gui:wcreate({
        {"name", "btnSmart" & wname},
        {"parent", "cntCommandsLeft" & wname},
        {"class", "toggle"},
        {"style", "button"},
        {"label", "Smart Tools"}
    })
end procedure


procedure create_edit_tools(sequence wname)
    gui:wcreate({
        {"name", "btnSmart" & wname},
        {"parent", "cntCommandsLeft" & wname},
        {"class", "toggle"},
        {"style", "button"},
        {"label", "Smart Tools"}
    })
end procedure


export procedure load_file(sequence fpathname, atom readonly = 0)
    atom fidx = find(fpathname, srcfiles[fFilePathName])
    if fidx > 0 then --file is already open, so switch to it's tab instead
        select_tab(srcfiles[fTabWid][fidx])
        return
    end if
    --read file
    atom fn, t = time()
    object ln, txt = {}
    
    fn = open(fpathname, "r")
    if fn = -1 then     --error
        txt = {"read_file() error!"}
    else
        while 1 do
            ln = gets(fn)
            if sequence(ln) then
                ln = remove_all(10, ln)
                ln = remove_all(13, ln)
               txt &= {ln}
            else
                exit
            end if
            if time() - t > 0.25 then
                task_yield()
                t = time()
            end if
        end while
        close(fn)
        
        if length(txt) = 0 then --temporary fix for textedit breaking when text is empty!
            txt = {""}
        end if
        
        atom tabid = tabs:create(filename(fpathname))
        sequence parname = gui:widget_get_name(tabid)
        sequence wname = sprint(tabid)
        sequence txtlbl, syntaxmode
        
        if readonly then
            set_tab_flag(tabid, rgb(0, 0, 200))
        end if
        
        --create file command buttons
        gui:wcreate({
            {"name", "cntSource" & wname},
            {"parent", parname},
            {"class", "container"},
            {"orientation", "vertical"},
            {"sizemode_x", "expand"},
            {"sizemode_y", "expand"},
            {"handler", routine_id("gui_event")}
        })
        gui:wcreate({
            {"name", "cntCommands" & wname},
            {"parent", "cntSource" & wname},
            {"class", "container"},
            {"orientation", "horizontal"},
            {"sizemode_x", "expand"},
            {"sizemode_y", "normal"}
        })
        gui:wcreate({
            {"name", "cntCommandsLeft" & wname},
            {"parent", "cntCommands" & wname},
            {"class", "container"},
            {"orientation", "horizontal"},
            {"sizemode_x", "normal"},
            {"sizemode_y", "normal"},
            {"justify_x", "left"}
        })
        gui:wcreate({
            {"name", "cntCommandsRight" & wname},
            {"parent", "cntCommands" & wname},
            {"class", "container"},
            {"orientation", "horizontal"},
            {"sizemode_x", "normal"},
            {"sizemode_y", "normal"},
            {"justify_x", "right"}
        })
        gui:wcreate({
            {"name", "btnFind" & wname},
            {"parent", "cntCommandsLeft" & wname},
            {"class", "toggle"},
            {"style", "button"},
            {"label", "Find"}
        })
        if readonly then
            gui:wcreate({
                {"name", "btnEdit" & wname},
                {"parent", "cntCommandsRight" & wname},
                {"class", "button"},
                {"label", "Edit"}
            })
        else
            create_edit_tools(wname)
        end if
        gui:wcreate({
            {"name", "btnClose" & wname},
            {"parent", "cntCommandsRight" & wname},
            {"class", "button"},
            {"label", "Close"}
        })
        
        --create text editor instance
        if find(fileext(fpathname), {"ex", "exw", "eu", "e", "exu", "err"}) then
            syntaxmode = "euphoria"
        /*
        elsif find(fileext(fpathname), {"cfg", "ini"}) then
            syntaxmode = "ini"
        elsif find(fileext(fpathname), {"html"}) then
            syntaxmode = "html"
        elsif find(fileext(fpathname), {"css"}) then
            syntaxmode = "css"
        elsif find(fileext(fpathname), {"xml"}) then
            syntaxmode = "xml"
        elsif find(fileext(fpathname), {"c", "h", "cpp"}) then
            syntaxmode = "c"
        */
        else
            syntaxmode = "plain"
        end if
        if readonly then
            txtlbl = fpathname & " (Read Only)"
        else
            txtlbl = fpathname
        end if
        txte:create({
            {"name", "txt" & wname},
            {"label", txtlbl},
            --{"view_mode", "syntax"},
            {"syntax_mode", syntaxmode},
            {"text", txt},
            {"locked", readonly},
            {"handler", routine_id("txt_event")}
        })
        
        txte:show("txt" & wname, "canFiles" & wname, "cntSource" & wname)
        --(sequence iname, sequence cname, sequence cparent)
        
        gui:wcreate({
            {"name", "cntBuilder" & wname},
            {"parent", "cntSource" & wname},
            {"class", "container"},
            {"orientation", "horizontal"},
            {"sizemode_x", "expand"},
            {"sizemode_y", "expand"},
            {"size", {0, 150}}
        })
        gui:wcreate({
            {"name", "txtBuilder" & wname},
            {"parent", "cntBuilder" & wname},
            {"class", "textbox"},
            {"mode", "text"},
            {"label", "Current Context:"},
            {"text", "Sorry, this doesn't work yet."}
        })
        gui:wcreate({
            {"name", "lstBuilder" & wname},
            {"parent", "cntBuilder" & wname},
            {"class", "listbox"},
            {"label", "Create code:"}
        })
        
        --temp example:
        gui:wproc("lstBuilder" & wname, "clear_list", {})
        gui:wproc("lstBuilder" & wname, "add_list_items", {{
            {rgb(127, 127, 127), "Sorry, this doesn't work yet."},
            {rgb(127, 127, 127), "include"},
            {rgb(127, 127, 127), "object"},
            {rgb(127, 127, 127), "sequence"},
            {rgb(127, 127, 127), "atom"},
            {rgb(127, 127, 127), "integer"},
            {rgb(127, 127, 127), "procedure"},
            {rgb(127, 127, 127), "function"}
        }})
        
        srcfiles[fFilePathName] &= {fpathname}
        srcfiles[fModified] &= {0}
        srcfiles[fLocked] &= {readonly}
        srcfiles[fTabWid] &= {tabid}
        srcfiles[fRoutineNames] &= {{}}
        srcfiles[fRoutineLineNums] &= {{}}
        srcfiles[fContext] &= {{}}
    end if
end procedure


export procedure save_file(sequence fname)
    atom fidx = find(fname, srcfiles[fFilePathName])
    if fidx > 0 then
        if txte:save_to_file("txt" & sprint(srcfiles[fTabWid][fidx]), fname) then
            txte:set_modified("txt" & sprint(srcfiles[fTabWid][fidx]), 0)
            --msgbox:msg("Saved file\"" & fname & "\".", "Info")
        else
            msgbox:msg("Unable to save file\"" & fname & "\".", "Error")
        end if
    end if
end procedure


export procedure save_file_as(sequence fname) --save as different file and update tab to new file name
    
end procedure


export procedure confirm_close_file(sequence fname)
    atom fidx = find(fname, srcfiles[fFilePathName])
    if fidx > 0 then
        sequence ans = "Cancel"
        if srcfiles[fModified][fidx] then
            ans = msgbox:waitmsg("File \"" & fname & "\" is not saved. Save before closing?", "Question", {"Yes", "No", "Cancel"})
        else
            ans = "No"
        end if
        if equal(ans, "Yes") then
            save_file(fname)
            close_file(fname)
        elsif equal(ans, "No") then
            close_file(fname)
        end if
    end if
end procedure


export procedure close_file(sequence fname)
    atom fidx = find(fname, srcfiles[fFilePathName])
    if fidx > 0 then
        txte:destroy("txt" & sprint(srcfiles[fTabWid][fidx]))
        tabs:destroy_tab(srcfiles[fTabWid][fidx])
        srcfiles[fFilePathName] = remove(srcfiles[fFilePathName], fidx)
        srcfiles[fModified] = remove(srcfiles[fModified], fidx)
        srcfiles[fLocked] = remove(srcfiles[fLocked], fidx)
        srcfiles[fTabWid] = remove(srcfiles[fTabWid], fidx)
        srcfiles[fRoutineNames] = remove(srcfiles[fRoutineNames], fidx)
        srcfiles[fRoutineLineNums] = remove(srcfiles[fRoutineLineNums], fidx)
        srcfiles[fContext] = remove(srcfiles[fContext], fidx)
    end if
end procedure


export procedure save_all() --save data to file from tab
    sequence flist = srcfiles[fFilePathName]
    for f = 1 to length(flist) do
        save_file(flist[f])
    end for
end procedure


export procedure close_all()
    sequence flist = srcfiles[fFilePathName]
    for f = 1 to length(flist) do
        confirm_close_file(flist[f])
    end for
end procedure


export function is_any_modified()
    atom modified = 0
    for f = 1 to length(srcfiles[fModified]) do
        if srcfiles[fModified][f] then
            modified = 1
            exit
        end if
    end for
    return modified
end function


export function tab_file(atom tabwid)
    sequence fname = ""
    atom saveenabled = 0
    atom fidx = find(tabwid, srcfiles[fTabWid])
    if fidx > 0 then
        fname = srcfiles[fFilePathName][fidx]
        saveenabled = srcfiles[fModified][fidx]
    end if
    
    return {fname, saveenabled}
end function

-----------------------------------


procedure gui_event(object evwidget, object evtype, object evdata)
    --switch evwidget do
        --case "tabEditor" then
        --    if equal(evtype, "selection") then
        --        atom tabwid = evdata             
        --    end if
        --    
        --case else
            for f = 1 to length(srcfiles[fTabWid]) do
                if equal(evwidget, "btnClose" & sprint(srcfiles[fTabWid][f])) then
                    confirm_close_file(srcfiles[fFilePathName][f])
                    exit
                    
                elsif equal(evwidget, "btnEdit" & sprint(srcfiles[fTabWid][f])) then
                    srcfiles[fLocked][f] = 0
                    set_tab_flag(srcfiles[fTabWid][f], -1)
                    txte:set_prop("txt" & sprint(srcfiles[fTabWid][f]), "locked", 0)
                    txte:set_prop("txt" & sprint(srcfiles[fTabWid][f]), "label", srcfiles[fFilePathName][f])
                    gui:wdestroy("btnEdit" & sprint(srcfiles[fTabWid][f]))
                    create_edit_tools(sprint(srcfiles[fTabWid][f]))
                    exit
                    
                elsif equal(evwidget, "btnFind" & sprint(srcfiles[fTabWid][f])) then
                    select_tool(sprint(srcfiles[fTabWid][f]), "btnFind")
                    exit
                    
                elsif equal(evwidget, "btnSmart" & sprint(srcfiles[fTabWid][f])) then
                    select_tool(sprint(srcfiles[fTabWid][f]), "btnSmart")
                    exit
                    
                end if
            end for
    --end switch
end procedure

