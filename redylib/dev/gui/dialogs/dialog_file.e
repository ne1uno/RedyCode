-- This file is part of redylib
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


without warning

include gui/gui.e as gui
--include std/task.e
include std/text.e
include std/pretty.e
include std/sequence.e


public function os_select_open_file(object parwid, sequence filefilter, atom allowmultiselect = 0) --filefilter example: {{"All", "*.*"}, {"Euphoria", "*.ex;*.exw;*.e"}}
    object FileName, FileFilterStr = ""
    atom wh
    
    wh = gui:widget_get_handle(parwid)
    for f = 1 to length(filefilter) do
        FileFilterStr &= filefilter[f][1] & " (" & filefilter[f][2] & ")" & 0 & filefilter[f][2] & 0
    end for
    FileName = GetOpenFileName(wh, FileFilterStr, allowmultiselect)
    
    if allowmultiselect = 1 and sequence(FileName) then
        return split(FileName, 0) --format: {path, file1, file2, file3, ...}
    else
        return FileName
    end if
end function


public function os_select_save_file(object parwid, sequence defautfile)
    object FileName
    atom wh
    
    wh = gui:widget_get_handle(parwid)
    --for f = 1 to length(filefilter) do
    --    FileFilterStr &= filefilter[f][1] & " (" & filefilter[f][2] & ")" & 0 & filefilter[f][2] & 0
    --end for
    FileName = GetSaveFileName(wh, defautfile & 0)
    
    return FileName
end function



/*
    pretty_print(1, FileName, {2})
    if sequence(FileName) then
        fh = open(FileName,"r")
        if fh = -1  then
        else
            buffer = {}
        while add_line(fh) do end while
    end if
    
    
export procedure gui_event(object evwidget, object evtype, object evdata)

    switch evwidget do
         case "winFile.btnOk" then
            gui:wdestroy(wn)
            
         case "winFile.btnCancel" then
            gui:wdestroy(wn)
            
         case "winFile.btnApply" then
            gui:wdestroy(wn)
            
    end switch
end procedure


constant wn = "winFile"

export procedure show()

    if gui:wexists(wn) then
        return
    end if
    
    gui:wcreate({
        {"name", wn},
        {"class", "window"},
        {"mode", "dialog"},
        {"handler", routine_id("gui_event")},
        {"title", "Open/Save File"},
        {"modal", 1}
        --{"position", {350, 350}}
        --{"visible", 0}
    })
    gui:wcreate({
        {"name", wn & ".cntMain"},
        {"parent", wn},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", wn & ".cntTop"},
        {"parent", wn & ".cntMain"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"},
        {"size", {250, 0}}
    })
    
 
    for t = 1 to 8 do
        gui:wcreate({
            {"name",  wn & ".txtSomething" & sprint(t)},
            {"parent",  wn & ".cntTop"},
            {"class", "textbox"},
            {"label", "Something" & sprint(t)},
            {"text", "nothing easnu"}
        })
    end for
    
    gui:wcreate({
        {"name",  wn & ".div1"},
        {"parent",  wn & ".cntTop"},
        {"class", "divider"}
    })
       
    

    gui:wcreate({
        {"name", wn & ".cntBottom"},
        {"parent", wn & ".cntMain"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "equal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"}
    })
    
    gui:wcreate({
        {"name",  wn & ".btnOk"},
        {"parent",  wn & ".cntBottom"},
        {"class", "button"},
        {"label", "OK"}
    })
    
    gui:wcreate({
        {"name", wn & ".btnCancel"},
        {"parent",  wn & ".cntBottom"},
        {"class", "button"},
        {"label", "Cancel"}
    })
    
    gui:wcreate({
        {"name", wn & ".btnApply"},
        {"parent",  wn & ".cntBottom"},
        {"class", "button"},
        {"label", "Apply"}
    })
    

end procedure
*/


