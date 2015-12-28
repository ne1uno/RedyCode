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
--include app/msg.e as msg

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
fTabWid,            --widget ID of file's tab
fRoutineNames,      --list of file's routine names
fRoutineLineNums,   --list of file's routine line numbers
fContext            --current context info

constant fLENGTH = fContext

sequence srcfiles = repeat({}, fLENGTH)


export procedure load_src(sequence fpathname)
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
            {"sizemode_x", "normal"},
            {"sizemode_y", "normal"}
        })
        gui:wcreate({
            {"name", "btnClose" & wname},
            {"parent", "cntCommands" & wname},
            {"class", "button"},
            {"label", "Close"}
        })
        
        --create text editor instance
        
        txte:create({
            {"name", "txt" & wname},
            {"label", fpathname},
            --{"view_mode", "syntax"},
            {"syntax_mode", "euphoria"}, --syntax highlighting is very unstable!
            {"text", txt}
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
            {"text", "top level"}
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
        srcfiles[fTabWid] &= {tabid}
        srcfiles[fRoutineNames] &= {{}}
        srcfiles[fRoutineLineNums] &= {{}}
        srcfiles[fContext] &= {{}}
    end if
end procedure


export procedure save_src(sequence fname) --save data to file from tab
    
end procedure


export procedure close_src(sequence fname)
    atom fidx = find(fname, srcfiles[fFilePathName])
    if fidx > 0 then
        tabs:destroy_tab(srcfiles[fTabWid][fidx])
        srcfiles[fFilePathName] = remove(srcfiles[fFilePathName], fidx)
        srcfiles[fModified] = remove(srcfiles[fModified], fidx)
        srcfiles[fTabWid] = remove(srcfiles[fTabWid], fidx)
        srcfiles[fRoutineNames] = remove(srcfiles[fRoutineNames], fidx)
        srcfiles[fRoutineLineNums] = remove(srcfiles[fRoutineLineNums], fidx)
        srcfiles[fContext] = remove(srcfiles[fContext], fidx)
    end if
end procedure



export procedure save_all_src() --save data to file from tab
    sequence flist = srcfiles[fFilePathName]
    for f = 1 to length(flist) do
        save_src(flist[f])
    end for
end procedure


export procedure close_all_src()
    sequence flist = srcfiles[fFilePathName]
    for f = 1 to length(flist) do
        close_src(flist[f])
    end for
end procedure

export function is_modified()
    atom modified = 0
    for f = 1 to length(srcfiles[fModified]) do
        if srcfiles[fModified][f] then
            modified = 1
        end if
    end for
    return modified
end function


-----------------------------------


procedure gui_event(object evwidget, object evtype, object evdata)
    switch evwidget do
        case "tabEditor" then
            if equal(evtype, "selection") then
                atom tabwid = evdata
                ? tabwid                
            end if
            
        case else
            for f = 1 to length(srcfiles[fTabWid]) do
                if equal(evwidget, "btnClose" & sprint(srcfiles[fTabWid][f])) then
                    sequence ans = "Yes"
                    if srcfiles[fModified][f] then
                        ans = msgbox:waitmsg("File is not saved. Are you sure you want to close it?", "Question")
                    end if
                    if equal(ans, "Yes") then
                        close_src(srcfiles[fFilePathName][f])
                        exit
                    end if
                end if
            end for
    end switch
end procedure


/*function msg_event(sequence subscribername, sequence topicname, sequence msgname, object msgdata)
    switch topicname do
        case "command" then
    end switch
    
    return 1
end function*/


export procedure start()
    gui:wcreate({
        {"name", "cntMain"},
        {"parent", "winMain"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"},
        {"handler", routine_id("gui_event")}
    })
    
    gui:wcreate({
        {"name", "cntEditor"},
        {"parent", "cntMain"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    
    --srcfiles
    gui:wcreate({
        {"name", "tabEditor"},
        {"parent", "cntEditor"},
        {"class", "srcfiles"}
    })
    
    /*
    gui:wcreate({
        {"name", "panelNav"},
        {"parent", "winMain"},
        {"class", "panel"},
        {"label", "Navigation"},
        {"dock", "right"},
        {"handler", routine_id("gui_event")}
    })
    gui:wcreate({
        {"name", "cntNav"},
        {"parent", "panelNav"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", "lstNav"},
        {"parent", "cntNav"},
        {"class", "listbox"}
    })
    
    --temp example:
    gui:wproc("lstNav", "clear_list", {})
    gui:wproc("lstNav", "add_list_items", {{
        {rgb(127, 127, 127), "top"}
    }})
    
    gui:wcreate({
        {"name", "panelBuilder"},
        {"parent", "winMain"},
        {"class", "panel"},
        {"label", "Code Builder"},
        {"dock", "right"},
        {"handler", routine_id("gui_event")}
    })
    gui:wcreate({
        {"name", "cntBuilder"},
        {"parent", "panelBuilder"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    gui:wcreate({
        {"name", "txtBuilder"},
        {"parent", "cntBuilder"},
        {"class", "textbox"},
        {"mode", "text"},
        {"label", "Current Context:"},
        {"text", "top level"}
    })
    gui:wcreate({
        {"name", "lstBuilder"},
        {"parent", "cntBuilder"},
        {"class", "listbox"},
        {"label", "Create code:"}
    })
    
    --temp example:
    gui:wproc("lstBuilder", "clear_list", {})
    gui:wproc("lstBuilder", "add_list_items", {{
        {rgb(127, 127, 127), "include"},
        {rgb(127, 127, 127), "object"},
        {rgb(127, 127, 127), "sequence"},
        {rgb(127, 127, 127), "atom"},
        {rgb(127, 127, 127), "integer"},
        {rgb(127, 127, 127), "procedure"},
        {rgb(127, 127, 127), "function"}
    }})*/
    
    --msg:subscribe("editor", "command", routine_id("msg_event"))

end procedure



