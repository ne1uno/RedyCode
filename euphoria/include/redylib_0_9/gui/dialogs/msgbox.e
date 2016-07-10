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

include std/sequence.e
include std/search.e
include std/pretty.e
include std/text.e
include std/stack.e
include std/math.e
include std/search.e
include std/convert.e



sequence
msgWindows = {},
msgButtons = {},
QuestionQueue = {},
AnswerQueue = {}

--atom
--ImagesLoaded = 0  --Important! App_Image_Path must be declared in the main file!

constant
MsgFont = {"Arial", 10, Bold},
MaxWidth = 500




function word_wrap(sequence wname, sequence txt)
    sequence src, words = {}, wtxt = {""}, txex, tsize = {64, 64}
    atom whnd, st, spx, spy, tx = 0, ty = 0
    
    src = match_replace("\n", txt, " ")
    src = match_replace("\r", src, " ")
    src = match_replace("\t", src, " ")
    src = split_any(src, " ")
    
    whnd = gui:widget_get_handle(wname)
    set_font(whnd, MsgFont[1], MsgFont[2], MsgFont[3])
    txex = get_text_extent(whnd, " ")
    spx = txex[1]
    spy = txex[2]
    for w = 1 to length(src) do
        st = 1
        txex = get_text_extent(whnd, src[w])
        if txex[1] > MaxWidth then
            for e = st to length(src[w]) do
                txex = get_text_extent(whnd, src[w][st..e])
                if txex[1] > MaxWidth then
                    words &= {src[w][st..e-1]}
                    st = e
                    exit
                end if
            end for
            words &= {src[w][st..$]}
        else
            words &= {src[w]}
        end if
    end for
    for w = 1 to length(words) do
        txex = get_text_extent(whnd, words[w])
        tx += txex[1] + spx
        if tx > MaxWidth then
            tx = txex[1]
            ty += spy
            wtxt &= {""}
        end if
        wtxt[$] &= words[w] & " "
        if tx > tsize[1] then
            tsize[1] = tx
        end if
        if ty + spy > tsize[2] then
            tsize[2] = ty + spy
        end if
    end for
    if tsize[1] > MaxWidth then
        tsize[1] = MaxWidth
    end if
    --if tsize[2] > 600 then
    --    tsize[2] = ScreenY - 600
    --end if
    --pretty_print(1, words, {2})
    --pretty_print(1, wtxt, {2})
    return {wtxt, spy, tsize[1], tsize[2]}
end function


procedure remove_all_wids(sequence wname, sequence wanswer = "")
    sequence keepw = {}, keepb = {}
    --puts(1, "remove_all_wids: '" & wname & "', '" & wanswer & "'\n")           
    for i = 1 to length(msgWindows) do
        if equal(wname, msgWindows[i]) then
            atom qa = find(wname, QuestionQueue)
            if qa > 0 then
                AnswerQueue[qa] = wanswer
            end if
            gui:wdestroy(wname)
        else
            keepw &= {msgWindows[i]}
        end if
    end for
    for i = 1 to length(msgButtons) do
        if match(wname & ".", msgButtons[i]) != 1 then
            keepb &= {msgButtons[i]}
        end if
    end for
    msgWindows = keepw
    msgButtons = keepb
end procedure


procedure msg_event_handler(object evwidget, object evtype, object evdata)
    --puts(1, evwidget)
    atom idx = find(evwidget, msgButtons)
    if idx > 0 then
        switch evtype do
            case "clicked" then
                atom e = find('.', evwidget)
                if e > 0 then
                    remove_all_wids(evwidget[1..e-1], evwidget[e+4..$])
                end if
        end switch
    else
        idx = find(evwidget, msgWindows)
        if idx > 0 then
            switch evtype do
                case "destroyed" then
                    remove_all_wids(evwidget)
                case "closed" then
                    remove_all_wids(evwidget)
            end switch
        end if
    end if
end procedure


function msgbox(sequence msgtxt, sequence msgicon, sequence msgbuttons, atom msgmodal)
    sequence wname, wwrap, wtxt, tsize, csize, BackCmds = {}, ForeCmds = {}
    atom tx, ty, dy, vwidth, vheight
    
    loop do
        wname = "winMessage_" & sprintf("%4d", rand(9999))
        until not wexists(wname)
    end loop
    
    if not find(msgicon, {"Info", "Warning", "Error", "Question"}) then
        msgicon = "Message"
    end if
    gui:wcreate({
        {"name", wname},
        {"class", "window"},
        {"mode", "dialog"},
        {"title", msgicon},
        {"visible", 1},
        {"topmost", 1},
        {"modal", msgmodal},
        {"handler", routine_id("msg_event_handler")}
    })
    
    wwrap = word_wrap(wname, msgtxt)
    wtxt = wwrap[1]
    dy = wwrap[2]
    tsize = wwrap[3..4]
    
    /*if not ImagesLoaded then
        gui:load_bitmap("msgIconInfo", App_Image_Path & "/msg_info.bmp")
        gui:load_bitmap("msgIconWarning", App_Image_Path & "/msg_warning.bmp")
        gui:load_bitmap("msgIconError", App_Image_Path & "/msg_error.bmp")
        gui:load_bitmap("msgIconQuestion", App_Image_Path & "/msg_question.bmp")
        ImagesLoaded = 1
    end if*/
    if find(msgicon, {"Info", "Warning", "Error", "Question"}) then
        csize = {tsize[1] + 76, tsize[2] + 8}
        tx = 72
        ty = 4
        BackCmds = {
            {DR_PenColor, cOuterFill},
            {DR_Rectangle, True, 0, 0, csize[1], csize[2]},
            {DR_Image, "msgIcon" & msgicon, 0, 0}
        }
    else
        csize = {tsize[1] + 8, tsize[2] + 8}
        tx = 4
        ty = 4
        BackCmds = {
            {DR_PenColor, cOuterFill},
            {DR_Rectangle, True, 0, 0, csize[1], csize[2]}
        }
    end if
    
    /*BackCmds = { --debugging
        {DR_PenColor, rgb(200, 200, 0)},
        {DR_Rectangle, False, tx, ty, csize[1]-1, csize[2]-1}
    }*/
    ForeCmds = {
        {DR_PenColor, cOuterFill},
        {DR_Font} & MsgFont,
        {DR_TextColor, rgb(0, 0, 0)}
    }
    
    for li = 1 to length(wtxt) do
        ForeCmds &= {
            {DR_PenPos, tx, ty},
            {DR_Puts, wtxt[li]}
        }
        ty += dy
    end for
    
    gui:wcreate({
        {"name", wname & ".cntMain"},
        {"parent", wname},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    vwidth = csize[1]
    vheight = csize[2]
    if vheight > floor(ScreenY / 2) then
        vheight = floor(ScreenY / 2)
        vwidth += 16
    end  if
    gui:wcreate({
        {"name", wname & ".canMsg"},
        {"parent", wname & ".cntMain"},
        {"class", "canvas"},
        {"size", {vwidth, vheight}},
        {"border", 0}
    })
    
    if vheight < csize[2] then
        gui:wproc(wname & ".canMsg", "set_canvas_size", csize)
    end  if
    gui:wproc(wname & ".canMsg", "draw_background", {BackCmds})
    gui:wproc(wname & ".canMsg", "draw_foreground", {ForeCmds})
    gui:wcreate({
        {"name", wname & ".cntButtons"},
        {"parent", wname & ".cntMain"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "equal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"}
    })
    
    msgWindows &= {wname}
    if length(msgbuttons) = 0 then
        if equal(msgicon, "Question") then
            gui:wcreate({
                {"name", wname & ".btnYes"},
                {"parent", wname & ".cntButtons"},
                {"class", "button"},
                {"label", "Yes"},
                {"size", {50, 0}}
            })
            gui:wcreate({
                {"name", wname & ".btnNo"},
                {"parent", wname & ".cntButtons"},
                {"class", "button"},
                {"label", "No"},
                {"size", {50, 0}}
            })
            msgButtons &= {wname & ".btnYes", wname & ".btnNo"}
        else
            gui:wcreate({
                {"name", wname & ".btnOk"},
                {"parent", wname & ".cntButtons"},
                {"class", "button"},
                {"label", "OK"},
                {"size", {50, 0}}
            })
            gui:set_key_focus(wname & ".btnOk")
            msgButtons &= {wname & ".btnOk"}
        end if
    else
        sequence blist = {}
        for b = 1 to length(msgbuttons) do
            gui:wcreate({
                {"name", wname & ".btn" & msgbuttons[b]},
                {"parent", wname & ".cntButtons"},
                {"class", "button"},
                {"label", msgbuttons[b]},
                {"size", {50, 0}}
            })
            blist &= {wname & ".btn" & msgbuttons[b]}
        end for
        msgButtons &= blist
    end if
    
    return wname
end function


export procedure msg(sequence msgtxt, sequence msgicon = "Info")
    if equal(msgicon, "Question") then
        msgicon = "Message"
    end if
    object void = msgbox(msgtxt, msgicon, {}, 0)
end procedure


export function waitmsg(sequence msgtxt, sequence msgicon = "Info", sequence msgbuttons = {})
    object wname = msgbox(msgtxt, msgicon, msgbuttons, 1)
    sequence answer = ""
    atom qa
    
    QuestionQueue &= {wname}
    AnswerQueue &= {0}
    --pretty_print(1, QuestionQueue, {2})
    --pretty_print(1, AnswerQueue, {2})
    --? task_self()
    while 1 do
        qa = find(wname, QuestionQueue)
        if qa > 0 then
            if sequence(AnswerQueue[qa]) then
                answer = AnswerQueue[qa]
                QuestionQueue = remove(QuestionQueue, qa)
                AnswerQueue = remove(AnswerQueue, qa)
                exit
            end if
        end if
        task_yield()
    end while
    
    return answer
end function


