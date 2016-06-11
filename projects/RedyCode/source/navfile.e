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
include redylib_0_9/gui/objects/textdoc.e as txtdoc
include redylib_0_9/gui/dialogs/msgbox.e as msgbox

include std/task.e
include std/text.e
include std/pretty.e
include std/filesys.e
include std/convert.e
include std/sequence.e

action:define({
    {"name", "find"},
    {"do_proc", routine_id("do_show_find")},
    {"label", "Find..."},
    {"icon", "edit-find"},
    {"hotkey", "Ctrl+F"},
    {"description", "Find matching text in current file"},
    {"enabled", 0}
})

action:define({
    {"name", "find_first"},
    {"do_proc", routine_id("do_find_first")},
    {"label", "Find Previous"},
    {"icon", "go-first"},
    {"hotkey", "Shift+F3"},
    {"description", "Find first match"},
    {"enabled", 0}
})

action:define({
    {"name", "find_prev"},
    {"do_proc", routine_id("do_find_prev")},
    {"label", "Find Previous"},
    {"icon", "go-previous"},
    {"hotkey", "Shift+F3"},
    {"description", "Find previous match"},
    {"enabled", 0}
})

action:define({
    {"name", "find_next"},
    {"do_proc", routine_id("do_find_next")},
    {"label", "Find Next"},
    {"icon", "go-next"},
    {"hotkey", "F3"},
    {"description", "Find next match"},
    {"enabled", 0}
})

action:define({
    {"name", "find_last"},
    {"do_proc", routine_id("do_find_last")},
    {"label", "Find Next"},
    {"icon", "go-last"},
    {"hotkey", "F3"},
    {"description", "Find last match"},
    {"enabled", 0}
})

action:define({
    {"name", "replace_all"},
    {"do_proc", routine_id("do_replace_all")},
    {"label", "Find Next"},
    {"icon", ""},
    {"hotkey", "F3"},
    {"description", "Find and replace all matching occurences in current file"},
    {"enabled", 0}
})

action:define({
    {"name", "find_replace"},
    {"do_proc", routine_id("do_show_find_replace")},
    {"undo_proc", routine_id("undo_find_replace")},
    {"label", "Find and Replace..."},
    {"icon", "edit-find-replace"},
    {"hotkey", "Ctrl+H"},
    {"description", "Find and replace matching text in current file"},
    {"enabled", 0}
})

action:define({
    {"name", "show_goto"},
    {"do_proc", routine_id("do_show_goto_section")},
    {"label", "Go to Line Number..."},
    {"icon", "go-jump"},
    {"hotkey", "Ctrl+G"},
    {"description", "Go to line number in current file"},
    {"enabled", 0}
})

action:define({
    {"name", "show_bookmarks"},
    {"do_proc", routine_id("do_show_bookmarks")},
    {"label", "Go to Bookmark..."},
    {"icon", "emblem-favorite"},
    {"hotkey", "Ctrl+F"},
    {"description", "bookmarks"},
    {"enabled", 0}
})


procedure do_find_prev()
    do_find(-1)
end procedure


procedure do_find_next()
    do_find(1)
end procedure


procedure do_find_first()
    do_find(-2)
end procedure


procedure do_find_last()
    do_find(2)
end procedure


procedure do_find(atom direction)
    object iname, ans, findstr, replacestr, casesensitive, wholewords, startpos, doreplace, replaceall, matchpos
    atom rcount = 0
    
    iname = action:getfocus()
    if length(iname) > 0 then
        findstr = gui:wfunc("cntReplace.txtFind", "get_text", {})
        if sequence(findstr) then
            findstr = flatten(findstr)
        end if
        if length(findstr) > 0 then
            casesensitive = gui:wfunc("cntReplace.togCaseSensitive", "get_value", {})
            wholewords = gui:wfunc("cntReplace.togWholeWords", "get_value", {})
            startpos = gui:wfunc("cntReplace.optStartTop", "get_group_value", {})
            if not gui:widget_is_enabled("cntReplace.togReplace") then
                doreplace = 0
            else
                doreplace = gui:wfunc("cntReplace.togReplace", "get_value", {})
            end if
            if not gui:widget_is_enabled("cntReplace.togReplaceAll") then
                replaceall = 0
            else
                replaceall = gui:wfunc("cntReplace.togReplaceAll", "get_value", {})
            end if
            replacestr = gui:wfunc("cntReplace.txtReplace", "get_text", {})
            if sequence(replacestr) then
                replacestr = flatten(replacestr)
            else
                replacestr = ""
            end if
            gui:set_key_focus(iname & ".filepage" & ".canvas")
            
            if equal(startpos, "cntReplace.optStartTop") then
                --if direction = 1 then
                direction = -2
                --end if
                gui:wproc("cntReplace.optStartCursor", "set_group_value", {})
            end if
            
            if replaceall then --optimized replace all
                if direction = -2 then
                    ans = msgbox:waitmsg("Replace all occurrences of \"" & findstr & "\" from the top?", "Question", {"Yes", "No"})
                else
                    ans = msgbox:waitmsg("Replace all occurrences of \"" & findstr & "\" from current position?", "Question", {"Yes", "No"})
                end if
                
                if equal(ans, "Yes") then
                    rcount = txtdoc:match_replace_all(iname & ".filepage", findstr, replacestr, direction, casesensitive, wholewords)
                    if rcount = 0 then
                        msgbox:msg("Next occurrence of \"" & findstr & "\" not found.", "Info")
                    else
                        msgbox:msg(sprint(rcount) & " occurrences of \"" & findstr & "\" replaced.", "Info")
                    end if
                end if
            else
                
                --find/replace one match at a time
                matchpos = txtdoc:match_string(iname & ".filepage", findstr, direction, casesensitive, wholewords)
                
                --set selection
                if sequence(matchpos) then
                    txtdoc:queue_cmd(iname & ".filepage", "jump", {"location", matchpos[1], matchpos[2]-1, matchpos[1], matchpos[2]+length(findstr)-1})
                    --replace selection
                    if doreplace and txtdoc:is_locked(iname & ".filepage") = 0 then
                        txtdoc:queue_cmd(iname & ".filepage", "char", {replacestr})
                        if direction = -1 then
                            txtdoc:queue_cmd(iname & ".filepage", "jump", {"location", 
                                matchpos[1], matchpos[2]-1, matchpos[1], matchpos[2]+length(replacestr)-1
                            })
                        else --reverse selection (cursor is at the end so the next search/replace will not be recursive)
                            txtdoc:queue_cmd(iname & ".filepage", "jump", {"location", 
                                matchpos[1], matchpos[2]+length(replacestr)-1, matchpos[1], matchpos[2]-1
                            })
                        end if
                    end if
                else
                    if direction = -2 then
                        msgbox:msg("Next occurrence of \"" & findstr & "\" not found.", "Info")
                    else
                        ans = msgbox:waitmsg("Next occurrence of \"" & findstr & "\" not found. Search from the top?", "Question", {"Yes", "No"})
                        if equal(ans, "Yes") then
                            do_find(-2)
                        end if
                    end if
                end if
                
                
                
            end if
            
            
            
        end if
    end if
end procedure


procedure do_replace_all()
    
end procedure


procedure do_goto_line()
    sequence iname
    object txt
    atom gotoln = 0
    
    iname = action:getfocus()
    txt = gui:wfunc("cntGoto.txtLineNum", "get_text", {})
    if sequence(txt) then
        gotoln = to_number(txt)
    end if
    if gotoln > 0 then
        if txtdoc:is_locked(iname & ".filepage") then
            txtdoc:queue_cmd(iname & ".filepage", "jump", {"location", gotoln, 0, gotoln, "$"})
        else
            txtdoc:queue_cmd(iname & ".filepage", "jump", {"location", gotoln, 0})
        end if
        gui:set_key_focus(iname & ".filepage" & ".canvas")
    end if
end procedure


procedure gui_event(object evwidget, object evtype, object evdata)
    switch evwidget do
    --match_string(sequence iname, sequence findstr, atom direction = 1, atom casesensitive = 1, atom wholewords = 0)
    -- gui:wproc("cntReplace.grpStartPos", "set_group_value", {})
    
    case "cntReplace.txtFind" then
        if find(evtype, {"KeyPress", "KeyDown", "changed"}) then
            object findstr = gui:wfunc("cntReplace.txtFind", "get_text", {})
            if sequence(findstr) then
                findstr = flatten(findstr)
            end if
            if sequence(findstr) and length(findstr) > 0 and length(action:getfocus()) > 0 then
                gui:wenable("cntReplace.btnPrev")
                gui:wenable("cntReplace.btnNext")
            else
                gui:wdisable("cntReplace.btnPrev")
                gui:wdisable("cntReplace.btnNext")
            end if
            
        elsif equal(evtype, "Enter") then
            do_find(1)
        end if
        
    case "cntReplace.togCaseSensitive" then
        if equal(evtype, "value") then
            cfg:set_var("", "Search", "CaseSensitive", evdata)
        end if
        
    case "cntReplace.togWholeWords" then
        if equal(evtype, "value") then
            cfg:set_var("", "Search", "WholeWords", evdata)
        end if
        
    case "cntReplace.togReplace" then
        if equal(evtype, "value") then
            gui:wenable("cntReplace.togReplaceAll", evdata)
            gui:wenable("cntReplace.txtReplace", evdata)
        end if
        
    case "cntReplace.txtReplace" then
        if equal(evtype, "Enter") then
            do_find(1)
        end if
        
    case "cntReplace.btnPrev" then
        action:do_proc("find_prev", {})
        
    case "cntReplace.btnNext" then
        action:do_proc("find_next", {})
        
    case "cntGoto.lstContents" then
        if equal(evtype, "selection") then
            if sequence(evdata) and length(evdata) > 0 then
                gui:wproc("cntGoto.txtLineNum", "set_text", {evdata[1][2][1]})
                do_goto_line()
            end if
            
        --elsif equal(evtype, "left_double_click") then
        --    do_goto_line()
        --elsif equal(evtype, "KeyPress") then
        --    if atom(evdata) and evdata = 13 then
        --        do_goto_line()
        --        gui:set_key_focus("cntGoto.lstContents")
        --    end if
        end if
        
    case "cntGoto.txtLineNum" then
        if equal(evtype, "Enter") then
            do_goto_line()
        end if
        
    case "cntGoto.btnGo" then
        do_goto_line()
        
    case "cntBookmarks.lstBookmarks" then
        if equal(evtype, "selection") then
            if sequence(evdata) and length(evdata) > 0 then
                sequence iname = action:getfocus()
                if length(iname) > 0 then
                    atom ln = to_number(evdata[1][2][1])
                    if ln > 0 then
                        if txtdoc:is_locked(iname & ".filepage") then
                            txtdoc:queue_cmd(iname & ".filepage", "jump", {"location", ln, 0, ln, "$"})
                        else
                            txtdoc:queue_cmd(iname & ".filepage", "jump", {"location", ln, 0})
                        end if
                        gui:set_key_focus(iname & ".filepage" & ".canvas")
                    end if
                end if
            end if
        end if
    end switch
end procedure


procedure do_show_goto_line()
    sequence iname
    atom li
    
    if not gui:wexists("cntSearch") then
        refresh_toc()
    end if
    iname = action:getfocus()
    li = txtdoc:get_current_line_num(iname & ".filepage")
    
    gui:wproc("tabSearch", "select_tab", {1})
    gui:wproc("cntGoto.txtLineNum", "set_text", {sprint(li)})
    gui:set_key_focus("cntGoto.txtLineNum")
end procedure


procedure do_show_goto_section()
    sequence iname
    atom li
    
    if not gui:wexists("cntSearch") then
        refresh_toc()
    end if
    iname = action:getfocus() & ".filepage"
    li = txtdoc:get_current_line_num(iname)
    
    gui:wproc("tabSearch", "select_tab", {1})
    gui:wproc("cntGoto.txtLineNum", "set_text", {sprint(li)})
    gui:set_key_focus("cntGoto.txtLineNum")
end procedure


procedure do_show_find()
    sequence iname, findtxt
    
    if not gui:wexists("cntSearch") then
        refresh_toc()
    end if
    gui:wproc("tabSearch", "select_tab", {3})
    iname = action:getfocus()
    findtxt = txtdoc:get_selected_text(iname & ".filepage") 
    if length(findtxt) = 1 and length(findtxt[1]) > 0 then
        gui:wproc("cntReplace.txtFind", "set_text", {findtxt[1]})
        gui:wproc("cntReplace.optStartTop", "set_group_value", {})
        gui:wenable("cntReplace.btnPrev")
        gui:wenable("cntReplace.btnNext")
    end if
    gui:wproc("cntReplace.txtFind", "select_all", {})
    gui:wproc("cntReplace.togReplace", "set_value", {0})
    gui:set_key_focus("cntReplace.txtFind")
    
end procedure


procedure do_show_find_replace()
    sequence iname, findtxt
    
    if not gui:wexists("cntSearch") then
        refresh_toc()
    end if
    gui:wproc("tabSearch", "select_tab", {3})
    iname = action:getfocus()
    findtxt = txtdoc:get_selected_text(iname & ".filepage") 
    
    if length(findtxt) = 1 and length(findtxt[1]) > 0 then
        gui:wproc("cntReplace.txtFind", "set_text", {findtxt[1]})
        gui:wproc("cntReplace.optStartTop", "set_group_value", {})
        gui:wenable("cntReplace.btnPrev")
        gui:wenable("cntReplace.btnNext")
    end if
    if txtdoc:is_locked(iname & ".filepage") = 0 then
        gui:wproc("cntReplace.togReplace", "set_value", {1})
        --gui:wproc("cntReplace.txtReplace", "set_text", {"ReplaceMe"})
        gui:wproc("cntReplace.txtReplace", "select_all", {})
        gui:set_key_focus("cntReplace.txtReplace")
    else
        gui:wproc("cntReplace.txtFind", "select_all", {})
        gui:wproc("cntReplace.togReplace", "set_value", {0})
        gui:set_key_focus("cntReplace.txtFind")
    end if
end procedure


procedure do_show_bookmarks()
    if not gui:wexists("cntSearch") then
        refresh_toc()
    end if
    gui:wproc("tabSearch", "select_tab", {2})
end procedure


export procedure refresh_toc()
    sequence iname, itms, bookmarks
    if not gui:wexists("cntGoto.lstContents") then
        create_search_panel()
    end if
    
    iname = action:getfocus()
    if length(iname) > 0 then
        itms = txtdoc:get_toc(iname & ".filepage")
        bookmarks = txtdoc:get_bookmarks(iname & ".filepage")
        
        gui:wproc("cntGoto.lstContents", "set_list_items", {itms})
        gui:wproc("cntBookmarks.lstBookmarks", "set_list_items", {bookmarks})
        
        object findstr = gui:wfunc("cntReplace.txtFind", "get_text", {})
        if sequence(findstr) then
            findstr = flatten(findstr)
        end if
        if sequence(findstr) and length(findstr) > 0 then
            gui:wenable("cntReplace.btnPrev")
            gui:wenable("cntReplace.btnNext")
        else
            gui:wdisable("cntReplace.btnPrev")
            gui:wdisable("cntReplace.btnNext")
        end if
        --gui:wenable("cntBookmarks.btnAdd")
        --gui:wenable("cntBookmarks.btnRemove")
        gui:wenable("cntGoto.btnGo")
        
        
        if txtdoc:is_locked(iname & ".filepage") = 0 then
            gui:wenable("cntReplace.togReplace")
            if gui:wfunc("cntReplace.togReplace", "get_value", {}) = 1 then
                gui:wenable("cntReplace.togReplaceAll")
                gui:wenable("cntReplace.txtReplace")
            else
                gui:wdisable("cntReplace.togReplaceAll")
                gui:wdisable("cntReplace.txtReplace")
            end if
        else
            gui:wdisable("cntReplace.togReplace")
            gui:wdisable("cntReplace.togReplaceAll")
            gui:wdisable("cntReplace.txtReplace")
        end if
        
        
    else
        gui:wdisable("cntReplace.togReplace")
        gui:wdisable("cntReplace.togReplaceAll")
        gui:wdisable("cntReplace.txtReplace")
        
        gui:wproc("cntGoto.lstContents", "clear_list", {})
        gui:wproc("cntBookmarks.lstBookmarks", "clear_list", {})
        
        gui:wdisable("cntReplace.btnPrev")
        gui:wdisable("cntReplace.btnNext")
        gui:wdisable("cntBookmarks.btnAdd")
        gui:wdisable("cntBookmarks.btnRemove")
        gui:wdisable("cntGoto.btnGo")
        
    end if
end procedure


export procedure create_search_panel()
    object
    prefCaseSensitive = cfg:get_var("", "Search", "CaseSensitive"),
    prefWholeWords = cfg:get_var("", "Search", "WholeWords")
    if not atom(prefCaseSensitive) then
        prefCaseSensitive = 0
    end if
    if not atom(prefWholeWords) then
        prefWholeWords = 0
    end if
    
    --This is supposed to be a panel, but unfortunately, panel layout is fully working yet,
    --so i have to do a hack job of adding a divider and container to panelProject for now.
    /*gui:wcreate({
        {"name", "panelSearch"},
        {"parent", "winMain"},
        {"class", "panel"},
        {"label", "Search"},
        {"dock", "left"},
        {"handler", routine_id("gui_event")}
    })*/
    

    
    if gui:wexists("cntSearch") then
        gui:wdestroy("cntSearch")
    end if
    
    gui:wcreate({
        {"name", "divSearch"},
        {"parent", "cntProject"},
        {"class", "divider"},
        {"attach", "treeProject"}
    })
    gui:wcreate({
        {"name", "cntSearch"},
        {"parent", "cntProject"}, --"panelSearch"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"},
        {"handler", routine_id("gui_event")}
    })
    gui:wcreate({
        {"name", "tabSearch"},
        {"parent", "cntSearch"},
        {"class", "tabs"}
    })
    
    --Goto line number
    gui:wcreate({
        {"name", "cntGoto"},
        {"parent", "tabSearch"},
        {"class", "container"},
        {"label", "Go to"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name",  "cntGoto.lstContents"},
        {"parent",  "cntGoto"},
        {"class", "listbox"},
        {"label", "File Contents"}
    })
    gui:wproc("cntGoto.lstContents", "add_column", {{"Ln", 36, 0, 0}})
    gui:wproc("cntGoto.lstContents", "add_column", {{"Text", 300, 0, 0}})
    
    refresh_toc()
    
    gui:wcreate({
        {"name",  "cntGoto.txtLineNum"},
        {"parent", "cntGoto"},
        {"class", "textbox"},
        {"label", "Line Number:"},
        {"string", ""}
    })
    gui:wcreate({
        {"name", "cntGoto.cntBottom"},
        {"parent", "cntGoto"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "equal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"}
    })
    gui:wcreate({
        {"name", "cntGoto.btnGo"},
        {"parent", "cntGoto.cntBottom"},
        {"class", "button"},
        {"label", "Go"}
    })
    
    --Bookmarks
    gui:wcreate({
        {"name", "cntBookmarks"},
        {"parent", "tabSearch"},
        {"class", "container"},
        {"label", "Bookmarks"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name",  "cntBookmarks.lstBookmarks"},
        {"parent",  "cntBookmarks"},
        {"class", "listbox"},
        {"label", "Bookmarks"}
    })
    --gui:wproc("cntBookmarks.lstBookmarks", "clear_list", {})
    gui:wproc("cntBookmarks.lstBookmarks", "add_column", {{"Ln", 50, 0, 0}})
    gui:wproc("cntBookmarks.lstBookmarks", "add_column", {{"Text", 300, 0, 0}})
    gui:wcreate({
        {"name", "cntBookmarks.cntBottom"},
        {"parent", "cntBookmarks"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "equal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"}
    })
    /*gui:wcreate({
        {"name", "cntBookmarks.btnAdd"},
        {"parent", "cntBookmarks.cntBottom"},
        {"class", "button"},
        {"label", "Add"}
    })
    gui:wcreate({
        {"name", "cntBookmarks.btnRemove"},
        {"parent", "cntBookmarks.cntBottom"},
        {"class", "button"},
        {"label", "Remove"}
    })
    gui:wdisable("cntBookmarks.btnAdd")
    gui:wdisable("cntBookmarks.btnRemove")*/
    
    --Find/Replace
    gui:wcreate({
        {"name", "cntReplace"},
        {"parent", "tabSearch"},
        {"class", "container"},
        {"label", "Find/Replace"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", "cntReplace.cntTop"},
        {"parent", "cntReplace"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name",  "cntReplace.txtFind"},
        {"parent", "cntReplace.cntTop"},
        {"class", "textbox"},
        {"label", "Find:"},
        {"text", ""},
        {"mode", "text"},
        {"label_position", "above"},
        {"allow_newline", 0},
        {"monowidth", 1}
    })
    gui:wcreate({
        {"name",  "cntReplace.togCaseSensitive"},
        {"parent", "cntReplace.cntTop"},
        {"class", "toggle"},
        {"label", "Case sensitive"},
        {"value", prefCaseSensitive}
    })
    gui:wcreate({
        {"name",  "cntReplace.togWholeWords"},
        {"parent", "cntReplace.cntTop"},
        {"class", "toggle"},
        {"label", "Whole words only"},
        {"value", prefWholeWords}
    })
    gui:wcreate({
        {"name", "cntReplace.optStartTop"},
        {"parent", "cntReplace.cntTop"},
        {"class", "option"},
        {"group", "cntReplace.grpStartPos"},
        --{"style", "button"},
        {"label", "Start at top"},
        {"value", 1}
    })
    gui:wcreate({
        {"name", "cntReplace.optStartCursor"},
        {"parent", "cntReplace.cntTop"},
        {"class", "option"},
        {"group", "cntReplace.grpStartPos"},
        --{"style", "button"},
        {"label", "Continue from cursor"}
    })
    gui:wcreate({
        {"name",  "cntReplace.togReplace"},
        {"parent", "cntReplace.cntTop"},
        {"class", "toggle"},
        {"label", "Replace with:"},
        {"value", 0}
    })
    gui:wcreate({
        {"name",  "cntReplace.togReplaceAll"},
        {"parent", "cntReplace.cntTop"},
        {"class", "toggle"},
        {"label", "Replace all occurrences"},
        {"value", 1}
    })
    gui:wcreate({
        {"name",  "cntReplace.txtReplace"},
        {"parent", "cntReplace.cntTop"},
        {"class", "textbox"},
        --{"label", "Replace with:"},
        {"text", ""},
        {"mode", "text"},
        {"label_position", "above"},
        {"monowidth", 1},
        {"allow_newline", 0},
        {"enabled", 0}
    })
    gui:wcreate({
        {"name", "cntReplace.cntBottom"},
        {"parent", "cntReplace"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "equal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"}
    })
    gui:wcreate({
        {"name", "cntReplace.btnPrev"},
        {"parent", "cntReplace.cntBottom"},
        {"class", "button"},
        {"label", "Prev"}
    })
    gui:wcreate({
        {"name", "cntReplace.btnNext"},
        {"parent", "cntReplace.cntBottom"},
        {"class", "button"},
        {"label", "Next"}
    })
    
    gui:wproc("tabSearch", "select_tab", {1})
end procedure





