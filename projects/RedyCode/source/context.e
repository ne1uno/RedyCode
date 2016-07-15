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
include redylib_0_9/gui/dialogs/msgbox.e as msgbox
include redylib_0_9/actions.e as action
include redylib_0_9/app.e as app
include redylib_0_9/gui/objects/textdoc.e as txtdoc

include std/task.e
include std/text.e
include std/pretty.e
include std/sequence.e
include std/filesys.e
include std/error.e
include std/datetime.e as dt
include std/filesys.e
include std/utils.e


action:define({
    {"name", "comment"},
    {"do_proc", routine_id("do_comment")},
    {"label", "Comment"},
    {"icon", "comment"},
    {"description", "Comment"},
    {"enabled", 0}
})

action:define({
    {"name", "uncomment"},
    {"do_proc", routine_id("do_uncomment")},
    {"label", "Uncomment"},
    {"icon", "uncomment"},
    {"description", "Uncomment"},
    {"enabled", 0}
})

action:define({
    {"name", "beautify"},
    {"do_proc", routine_id("do_beautify")},
    {"label", "Beautify Code"},
    {"icon", "beautify"},
    {"description", "Beautify"},
    {"enabled", 0}
})

action:define({
    {"name", "show_code_builder"},
    {"do_proc", routine_id("do_show_code_builder")},
    {"label", "Code Builder..."},
    {"icon", "text-x-script"},
    {"description", "show code builder"},
    {"enabled", 0}
})

action:define({
    {"name", "show_ascii_chart"},
    {"do_proc", routine_id("do_show_ascii_chart")},
    {"label", "Show ASCII Chart..."},
    {"icon", "accessories-character-map"},
    {"description", "Show ASCII chart"},
    {"enabled", 0}
})

action:define({
    {"name", "show_color_selector"},
    {"do_proc", routine_id("do_show_color_selector")},
    {"label", "Show Color Selector..."},
    {"icon", "show_color_selector"},
    {"description", "Show color selector"},
    {"enabled", 0}
})


action:define({
    {"name", "show_color_selector"},
    {"do_proc", routine_id("do_show_color_selector")},
    {"label", "Show Color Selector..."},
    {"icon", "show_color_selector"},
    {"description", "Show color selector"},
    {"enabled", 0}
})


procedure do_comment()
end procedure


procedure do_uncomment()
end procedure


procedure do_beautify()
end procedure


procedure do_show_ascii_chart()
end procedure


procedure do_show_color_selector()
end procedure


procedure do_show_code_builder()

end procedure


export function header_code(sequence InfoVars, sequence HeaderTxt)
    sequence txt = ""
    atom ch, found
     
    for li = 1 to length(HeaderTxt) do
        HeaderTxt[li] = escape(HeaderTxt[li])
        txt &= "-- "
        ch = 1
        while ch <= length(HeaderTxt[li]) do
            found = 0
            if HeaderTxt[li][ch] = '$' then
                for i = 1 to length(InfoVars) do
                    if match(InfoVars[i][1], HeaderTxt[li], ch + 1) = ch + 1 then
                        found = 1
                        ch += length('$' & InfoVars[i][1])
                        
                        if length(InfoVars[i][2]) > 1 then
                            for s = 1 to length(InfoVars[i][2]) do
                                txt &= InfoVars[i][2][s]
                                if s < length(InfoVars[i][2]) then
                                    txt &= "\n-- "
                                end if
                            end for
                        elsif length(InfoVars[i][2]) = 1 then
                            txt &= InfoVars[i][2][1]
                        end if
                        exit
                    end if
                end for
            end if
            if found = 0 then
                txt &= HeaderTxt[li][ch]
                ch += 1
            end if
        end while
        txt &= "\n"
    end for
    txt &= repeat('-', 80) & "\n\n"
    
    return txt
end function


export function app_info_code(sequence InfoVars)
    sequence txt = "app:define({\n"
    
    for v = 1 to length(InfoVars) do
        if length(InfoVars[v][2]) > 1 then
            --    {"license", {
            --        "See the License for the specific language governing permissions and",
            --        "limitations under the License."
            --    }},
            
            txt &= "    {\"" & InfoVars[v][1] & "\", {\n"
            for i = 1 to length(InfoVars[v][2]) do
                txt &= "        \"" & escape(InfoVars[v][2][i]) & "\""
                if i < length(InfoVars[v][2]) then
                    txt &= ",\n"
                else
                    txt &= "\n"
                end if
            end for
            txt &= "    }}"
        elsif length(InfoVars[v][2]) = 1 then
            --    {"title", "RedyCode"},
            txt &= "    {\"" & InfoVars[v][1] & "\", \"" & escape(InfoVars[v][2][1]) & "\"}"
        else
            --    {"title", "RedyCode"},
            txt &= "    {\"" & escape(InfoVars[v][1]) & "\", \"\"}"
        end if
        if v < length(InfoVars) then
            txt &= ",\n"
        else
            txt &= "\n"
        end if
    end for
    txt &= "})\n\n"
    
    return txt
end function


export procedure gui_event(object evwidget, object evtype, object evdata)

end procedure


