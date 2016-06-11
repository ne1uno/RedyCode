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


--action.e : Action system
--
--Actions are commands that can be called from anywhere in the application to
--manipulate data or application state in some way, by calling a routine
--associated with that action. When actions are called, an undo system keeps
--track of action history so actions can be undone.
--
--Actions are typically called from tool buttons, menu items, key combos,
--list items, tree nodes, scripts/macros, or plugins. Widgets can be assigned
--actions so instead of processing events through an event handler routine, an
--action can be triggered directly from widget events. This reduces the 
--complexity and redundancy of event-handling code. For example, you don't need
--to write event handlers for dozens of menu items and dozens of tool buttons
--for common actions, simply assign actions to each menu item or tool button
--upon creation.
--
--Each action must be defined and assigned a handler routine id. An action may
--have undo enabled or disabled, because it is possible that certain actions
--should not be allowed to be undone (such as saving a file, starting the app,
--reporting an error, printing, etc.)
--
--When an action is called, it is first appeneded to the undo history (if
--applicable), then the handler function is called, and returns 0 for success or
--non-zero for failure.
--
--The action system has some built-in pre-defined actions, such as "undo" and
--"redo".
--
--Typically, most actions will be defined by and handled by the applications's
--main "document" library (whatever library is responsible for editing and 
--displaying the application's data). However, it would make sense to have other
--parts of the application define some actions, such as showing or applying
--preferences. Some application-wide actions should probably be defined by the
--application's main file, such as "confirm_quit", "quit", etc. 
-- 
--Actions can have labels, icons, hotkeys, and descriptions, which makes it 
--easy to integrate actions into application design. This provides the necessary
--data needed to create toolbuttons, menu items, hot keys, tool tips, and macro
--editors, all from a centralized location.  
--
--Types of actions:
--[[Trigger]]
--An action with no paramaters
--
--[[Toggle]]
--An action with property {"toggle", {val1, val2}})
--
--[[List]]
--An action with property {"list", {{icon1, label1, data1}, {icon2, label2, data2}, ...}}
--
--[[Text]]
--An action with property {"text", routine_id("validate_func")})
--
--[[Number]]
--An action with property {"number", routine_id("validate_func")})
--
--Actions that have paramaters (all types besides "trigger" actions) retain a state 
--value, set by the most recent "do_proc" paramaters, or by set_state(). This value can
--be read by get_state() or monitored by calling
--action:monitor("action_name", routine_id("callback_routine")). An example
--of this is a "text_style_font" tool that displays the font of the current cursor
--position. If the cursor is moved to a different paragraph with a different font, the
--tool will be automatically refreshed to show the new font name. 
--State is not really relevent to any actual data, merely a way to manage what the GUI
--displays to the user, and it needs to be updated based on the context (which file is
--currently being edited, cursor location, edit mode, etc.).


--include std/text.e
--include std/pretty.e
--include std/error.e
--include euphoria/info.e

include redylib_0_9/err.e as err
include redylib_0_9/msg.e as msg

include std/pretty.e
include std/text.e

enum --action types
atLabel,        --no do_proc, only used to display state (such as mouse coordinates cursor position, object dimensions, etc.)
atTrigger,      --Normal action, usually empty paramaters {}
atToggle,       --Toggle button that triggers "action_name", switching between 2 paramater values
atList,         --Dropdown list that triggers "action_name" with the selected paramater value
atTextbox,      --Textbox that triggers "action_name" with the text as a paramater value
atNumberbox     --Number range selector that triggers "action_name"  with the number as a paramater value 


atom initialized = 0
object CurrentFocus = "" --which "object" is being acted upon

sequence
--Static (readonly) properties
aNames = {},
aTypes = {},
aLabels = {},
aIcons = {},
aDescriptions = {},
aDoProcs = {},
aUndoProcs = {},
aValidateFuncs = {},

--Dynamic properties
aMonitors = {},
aEnableds = {},
aHotkeys = {},
aStates = {},
aLists = {}
        

define({
    {"name", "undo"},
    {"do_proc", routine_id("do_undo")},
    {"label", "Undo"},
    {"icon", "edit-undo"},
    {"hotkey", "Ctrl+Z"},
    {"description", "Undo the last action"},
    {"enabled", 0}
})

define({
    {"name", "redo"},
    {"do_proc", routine_id("do_redo")},
    {"label", "Redo"},
    {"icon", "edit-redo"},
    {"hotkey", "Shift+Ctrl+Z"},
    {"description", "Redo the last undone action"},
    {"enabled", 0}
})


--Internal Routines-----------------------------------------


procedure push_undo_history(sequence actionname, sequence actionparams = {})
    --add an entry to the undo history
    atom idx = find(actionname, aNames)
    if idx > 0 then
        
    end if
end procedure


procedure pull_undo_history(sequence actionname, sequence actionparams = {})
    --move an entry from the undo history to the redo history
    atom idx = find(actionname, aNames)
    if idx > 0 then
        
    end if
end procedure


procedure do_undo(object adata)
    
end procedure


procedure do_redo(object adata)
    
end procedure


-- Public Routines -------------------------------------------


public procedure setfocus(object focusid) --set which "object" is being acted upon
    --TODO: not really implemented yet, redesign actions to use this for v1.0
    --I realized i will need this as apps get more complex
    --Probably insert CurrentFocus as the first parameter when calling do_proc()
    
    CurrentFocus = focusid
end procedure 


public function getfocus() --return which "object" is being acted upon
    return CurrentFocus
end function 


public procedure define(object actionprops)
--Define an action

/* --Example:

action:define({
    {"name", "file_open_recent"},
    {"do_proc", routine_id("do_file_open_recent")},
    --{"list_func", routine_id("list_file_open_recent")}
    {"list", {list of choices: {icon, label, data}}}, 
    {"label", "Open Recent"},
    {"icon", "icon_file_open_recent"},
    {"description", "Open a recent file"}
})
*/
    
    object
    pName = 0,
    pType = atLabel,
    pLabel = "",
    pIcon = 0,
    pDescription = "",
    pDoProc = 0,
    pUndoProc = 0,
    pValidateFunc = 0,
    
    pMonitor = {},
    pEnabled = 1,
    pHotKey = "",
    pState = {},
    pList = 0
    
    for p = 1 to length(actionprops) do
        switch lower(actionprops[p][1]) do
            case "name" then
                pName = actionprops[p][2]
            case "do_proc" then
                pDoProc = actionprops[p][2]
                if pType = atLabel then
                    pType = atTrigger
                end if
            case "undo_proc" then
                pUndoProc = actionprops[p][2]
            case "list" then
                pList = actionprops[p][2]
                pType = atList
            case "toggle" then
                if atom(actionprops[p][2]) and actionprops[p][2] = 1 then
                    pList = {0, 1}
                    pType = atToggle
                end if
            case "enabled" then
                pEnabled = actionprops[p][2]
            case "label" then
                pLabel = actionprops[p][2]
            case "text" then
                pValidateFunc = actionprops[p][2]
                pType = atTextbox
            case "number" then
                pValidateFunc = actionprops[p][2]
                pType = atNumberbox
            case "icon" then
                pIcon = actionprops[p][2]
            case "hotkey" then
                pHotKey = actionprops[p][2]
            case "description" then
                pDescription = actionprops[p][2]
            case else
                
        end switch
    end for
    
    if atom(pName) then
        err:warn("action:define", "invalid action name.", actionprops)
        return
    end if
    
    --puts(1, "Action defined: " & pName & ": " & pDescription & "\n") 
    
    atom idx = find(pName, aNames)
    if idx > 0 then
        --action already exists
        err:warn("action:define", "action '" & pName & "' already exists.")
        
        aNames[idx] = pName
        aTypes[idx] = pType
        aLabels[idx] = pLabel
        aIcons[idx] = pIcon
        aDescriptions[idx] = pDescription
        aDoProcs[idx] = pDoProc
        aUndoProcs[idx] = pUndoProc
        aValidateFuncs[idx] = pValidateFunc
        aMonitors[idx] = pMonitor
        aEnableds[idx] = pEnabled
        aHotkeys[idx] = pHotKey
        aStates[idx] = pState
        aLists[idx] = pList
    else
        aNames &= {pName}
        aTypes &= {pType}
        aLabels &= {pLabel}
        aIcons &= {pIcon}
        aDescriptions &= {pDescription}
        aDoProcs &= {pDoProc}
        aUndoProcs &= {pUndoProc}
        aValidateFuncs &= {pValidateFunc}
        aMonitors &= {pMonitor}
        aEnableds &= {pEnabled}
        aHotkeys &= {pHotKey}
        aStates &= {pState}
        aLists &= {pList}
    end if
end procedure


public function names()
    return aNames
end function


public function get_undo_history()
    return {}
end function


public procedure monitor(sequence actionname, atom callbackproc)
    --callbackproc must accept the paramaters (sequence actionname, sequence propname, sequence propdata)
    --propname/propdata can be:
    --"enabled", 0 or 1
    --"state", statedata
    --"list", listdata
    --"hotkey", hotkeydata
    
    atom idx = find(actionname, aNames)
    if idx > 0 then
        atom midx = find(callbackproc, aMonitors)
        if midx = 0 then
            aMonitors[idx] &= {callbackproc}
            --notify new monitor of initial status:
            call_proc(callbackproc, {actionname, "enabled", aEnableds[idx]})
            call_proc(callbackproc, {actionname, "state", aStates[idx]})
            call_proc(callbackproc, {actionname, "list", aLists[idx]})
            call_proc(callbackproc, {actionname, "hotkey", aHotkeys[idx]})
        end if
    end if
end procedure


public procedure do_proc(sequence actionname, object actionparams = {})
    --execute an action. Behavior depends on what type of action.
    --Action's do_proc is responsible for changing the actions's
    --state, enabled status, etc. as needed
    
    atom idx = find(actionname, aNames)
    
    if idx > 0 then
        if atom(actionparams) then
            actionparams = {}
        end if
        --puts(1, "action:do_proc(\"" & actionname & "\", " & pretty_sprint(actiondata, {2}) & ")\n")
        
        switch aTypes[idx] do
        case atLabel then
            --displays data only, no do_proc
            
        case atTrigger then
            if aDoProcs[idx] > 0 then
                call_proc(aDoProcs[idx], actionparams)
            end if
            
        case atToggle then
            if aDoProcs[idx] > 0 then
                if atom(aStates[idx]) and aStates[idx] = 1 then
                    call_proc(aDoProcs[idx], {0})
                else
                    call_proc(aDoProcs[idx], {1})
                end if
            end if
            
        case atList then
            if aDoProcs[idx] > 0 and length(actionparams) > 0 then
                for i = 1 to length(aLists[idx]) do --list format: {{icon1, label1, data1}, {icon2, label2, data2}, ...}
                    if equal(actionparams[1], aLists[idx][i][3]) then
                        call_proc(aDoProcs[idx], actionparams)
                        exit
                    end if
                end for
            end if
            
        case atTextbox then
            if aDoProcs[idx] > 0 then
                if aValidateFuncs[idx] > 0 then
                    object valid = call_func(aValidateFuncs[idx], actionparams)
                    if atom(valid) and valid = 1 then
                        call_proc(aDoProcs[idx], actionparams)
                    elsif sequence(valid) then --invalid data, error message text returned
                        --display an error somehow?
                    end if
                else
                    call_proc(aDoProcs[idx], actionparams)
                end if
            end if
            
        case atNumberbox then
            if aDoProcs[idx] > 0 then
                if aValidateFuncs[idx] > 0 then
                    object valid = call_func(aValidateFuncs[idx], actionparams)
                    if atom(valid) and valid = 1 then
                        call_proc(aDoProcs[idx], actionparams)
                    elsif sequence(valid) then --invalid data, error message text returned
                        --display an error somehow?
                    end if
                else
                    call_proc(aDoProcs[idx], actionparams)
                end if
            end if
            
        end switch
    end if
end procedure


public procedure undo_proc(sequence actionname, sequence actionparams = {})
    --undo an action
    atom idx = find(actionname, aNames)
    
    if idx > 0 and aUndoProcs[idx] > 0 then
        call_proc(aUndoProcs[idx], {actionparams})
    end if
end procedure


--Static Properties


public function get_type(sequence actionname)
    atom idx = find(actionname, aNames)
    if idx > 0 then
        switch aTypes[idx] do
        case atLabel then
            return "label"
        case atTrigger then
            return "trigger"
        case atToggle then
            return "toggle"
        case atList then
            return "list"
        case atTextbox then
            return "text"
        case atNumberbox then
            return "number"
        case else
            return 0
        end switch
    else
        return 0
    end if
end function


public function get_label(sequence actionname)
    atom idx = find(actionname, aNames)
    if idx > 0 then
        return aLabels[idx]
    else
        return 0
    end if
end function


public function get_icon(sequence actionname)
    atom idx = find(actionname, aNames)
    if idx > 0 then
        return aIcons[idx]
    else
        return 0
    end if
end function


public function get_description(sequence actionname)
    atom idx = find(actionname, aNames)
    if idx > 0 then
        return aDescriptions[idx]
    else
        return 0
    end if
end function


public function get_undoable(sequence actionname)
    atom idx = find(actionname, aNames)
    if idx > 0 then
        return (aUndoProcs[idx] > 0)
    else
        return 0
    end if
end function


-- Dynamic (Monitored) Properties ---------------------------------------------------------


public function get_enabled(sequence actionname)
    atom idx = find(actionname, aNames)
    if idx > 0 then
        return aEnableds[idx]
    else
        return 0
    end if
end function


public procedure set_enabled(sequence actionname, atom actionenabled)
    atom idx = find(actionname, aNames)
    if idx > 0 then
        aEnableds[idx] = actionenabled
        for m = 1 to length(aMonitors[idx]) do
            --pretty_print(1, {aMonitors[idx], m, {actionname, "enabled", actionenabled}}, {2})
            call_proc(aMonitors[idx][m], {actionname, "enabled", actionenabled})
        end for
    end if
end procedure


public function get_hotkey(sequence actionname)
    atom idx = find(actionname, aNames)
    if idx > 0 then
        return aHotkeys[idx]
    else
        return 0
    end if
end function


public procedure set_hotkey(sequence actionname, sequence actionhotkey)
    atom idx = find(actionname, aNames)
    if idx > 0 then
        aHotkeys[idx] = actionhotkey
        for m = 1 to length(aMonitors[idx]) do
            call_proc(aMonitors[idx][m], {actionname, "hotkey", actionhotkey})
        end for
    end if
end procedure


public function get_state(sequence actionname)
    atom idx = find(actionname, aNames)
    if idx > 0 then
        return aStates[idx]
    else
        return 0
    end if
end function


public procedure set_state(sequence actionname, sequence actionstate)
    atom idx = find(actionname, aNames)
    if idx > 0 then
        aStates[idx] = actionstate
        for m = 1 to length(aMonitors[idx]) do
            call_proc(aMonitors[idx][m], {actionname, "state", actionstate})
        end for
    end if
end procedure


public function get_list(sequence actionname)
    atom idx = find(actionname, aNames)
    if idx > 0 then
        return aLists[idx]
    else
        return 0
    end if
end function


public procedure set_list(sequence actionname, object actionlist)
--list format:
--{
--    {icon, label, data},
--    {icon, label, data},
--    {icon, label, data}...
--}
    atom idx = find(actionname, aNames)
    if idx > 0 then
        aLists[idx] = actionlist
        for m = 1 to length(aMonitors[idx]) do
            call_proc(aMonitors[idx][m], {actionname, "list", actionlist})
        end for
    end if
end procedure

