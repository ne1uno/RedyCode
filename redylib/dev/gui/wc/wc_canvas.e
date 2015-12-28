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



public include gui/widgets.e as widget
public include oswin/oswin.e as oswin
public include gui/themes.e as th
include std/sequence.e
include std/math.e

-- Internal class variables and routines

sequence wcprops

enum
    wcpID,
    wcpSoftFocus,
    wcpHardFocus,

    wcpLabel,
    wcpShowBorder,           --1 = show border and, if specified, a lable. 0 = no border (canvas rect covers the entire widget rect)
    wcpScrollForeground,
    
    wcpBackgroundImage,      --handle of background bitmap
    wcpHandleImage,          --handle of Handle bitmap (bitmap used for identifying which handle the mouse is over) 
    wcpForegroundDrawCmds,   --foreground drawing commands
    wcpBackgroundDrawCmds,   --background drawing commands (only called once then cleared)
    
    --wcpHandleRoutine,        --routine to call when handle events occur
     
    wcpHandleNames,          --string names of handles
    wcpHandleColors,         --color to use when drawing handle on HandleImage (automatically assigned)
    wcpHandleShapeCmds,      --drawing commands for drawing the visible part a Handle on top of the foreground
    --wcpHandleDrawCmds,       --drawing commands for drawing the shape of a Handle on the Handle Image
    wcpHandlePointers,       --what mouse pointer to show when hovering over a handle
    
    wcpBackgroundPointer,    --what mouse pointer to show when over the background
    wcpOverridePointer,      --what mouse pointer to show to temporarily override other pointers(useful for when dragging a handle), 0 = no override 

    wcpShowHandleDebug,      --show handle bitmap instead of normal drawing
    wcpShowPerformanceDebug, --show performance info for debugging (number of draw cmds, handles, and drawing times)

    wcpLabelPos,
    wcpCanvasRect,
    wcpVisibleSize, --size of visible area
    wcpContentSize, --size of actual content
    wcpScrollXEnabled,
    wcpScrollYEnabled,
    wcpScrollPosX,
    wcpScrollPosY,
 
    wcpScrollV, --vertial scrollbar widgetid
    wcpScrollH --horizontal scrollbar widgetid
    
constant wcpLENGTH = wcpScrollH

wcprops = repeat({}, wcpLENGTH)

-- Theme variables -------------------------------

atom optScrollIncrement = 32
atom headingheight = 18

-- local routines ---------------------------------------------------------------------------


function next_handle_color(atom idx)  --r + g * 256 + b * 65536, color value between 1 and 16777216 (color 0 is for the background)
    atom hc = max(0 & wcprops[wcpHandleColors][idx]) + 64 --makes colors more distiguishable when viewing the handle image for debugging
    --hc = max(wcprops[wcpHandleColors][idx]) + 1
    return hc
end function


procedure check_pointer(atom idx, atom wh, atom hidx)
    --decide which pointer to show based on list of priorities:
    --1) wcprops[wcpOverridePointer][idx], if > 0
    --2) wcprops[wcpHandlePointers][idx][hidx], if hidx > 0
    --3) wcprops[wcpBackgroundPointer][idx]
    atom mousep
    
    if wcprops[wcpOverridePointer][idx] > 0 then
        set_mouse_pointer(wh, wcprops[wcpOverridePointer][idx])
    elsif hidx > 0 and hidx <= length(wcprops[wcpHandlePointers][idx]) then
        switch wcprops[wcpHandlePointers][idx][hidx] do
            case "Arrow" then
                mousep = mArrow
            case "ArrowBusy" then
                mousep = mArrowBusy
            case "Ibeam" then
                mousep = mIbeam
            case "Busy" then
                mousep = mBusy
            case "No" then
                mousep = mNo
            case "NS" then
                mousep = mNS
            case "EW" then
                mousep = mEW
            case "NWSE" then
                mousep = mNWSE
            case "NESW" then
                mousep = mNESW
            case "Crosshair" then
                mousep = mCrosshair
            case "None" then
                mousep = mNone
            case "Sleeping" then
                mousep = mSleeping
            case "Link" then
                mousep = mLink
            case else
                mousep = 0
        end switch
                    
        set_mouse_pointer(wh, mousep)
        refresh_mouse_pointer(wh)
    else
        set_mouse_pointer(wh, wcprops[wcpBackgroundPointer][idx])
        refresh_mouse_pointer(wh)
    end if
end procedure


function identify_handle(atom idx, atom wh, atom mx, atom my)
    --use wcprops[wcpHandleImage][idx] to determine which handle the mouse is over
    --the handle is identified by finding the color of pixel (mx, my) in wcprops[wcpHandleColors][idx]
    atom
    pc = oswin:get_pixel_color(wcprops[wcpHandleImage][idx], wh, mx, my),
    hidx = find(pc, wcprops[wcpHandleColors][idx])
    
    return hidx
end function


procedure draw_handles(atom wid, atom idx)   --draw handles to wcpHandleImage
    sequence crect, csize, cmds, hshape
    atom wh = widget:widget_get_handle(wid)
    csize = {ScreenX, ScreenY}
    --crect = wcprops[wcpCanvasRect][idx]
    --csize[1] = crect[3] - crect[1]
    --csize[2] = crect[4] - crect[2]
    
    cmds = {
        --{DR_SelectBitmap, wcprops[wcpHandleImage][idx]},
        {DR_PenColor, rgb(0, 0, 0)},
        {DR_Rectangle, True, 0, 0, csize[1], csize[2]}
    }
    for h = 1 to length(wcprops[wcpHandleColors][idx]) do
        hshape = wcprops[wcpHandleShapeCmds][idx][h]
        cmds &= {
            {DR_PenColor, wcprops[wcpHandleColors][idx][h]}
        } & hshape
    end for
    oswin:draw(wh, cmds, wcprops[wcpHandleImage][idx])
end procedure


procedure check_scrollbars(atom idx, atom wid)
--check contents and size of widget to determine if scrollbars are needed, then create or destroy scrollbars when required.
    sequence wpos, wsize, trect, csize, vsize
    atom needV = 0, needH = 0
    
    wpos = widget_get_pos(wid)
    wsize = widget_get_size(wid)
    trect = wcprops[wcpCanvasRect][idx]
    csize = wcprops[wcpContentSize][idx]
    vsize = wcprops[wcpVisibleSize][idx]
    if csize[1] > vsize[1] then
        needH = 1
    end if
    if csize[2] > vsize[2] then
        needV = 1
    end if
    if needH = 1 then
        vsize[2] -= scrwidth
    end if
    if needV = 1 then
        vsize[1] -= scrwidth
    end if
    if csize[1] > vsize[1] then
        needH = 1
    end if
    if csize[2] > vsize[2] then
        needV = 1
    end if
    if needH = 1 and wcprops[wcpScrollH][idx] = 0 then
        wcprops[wcpScrollH][idx] = widget:widget_create(widget_get_name(wid) & ".scrH", wid, "scrollbar", {
            {"attach", wid},
            {"orientation", 1},
            {"min", 0}
            --{"position", {wpos[1] + trect[1]+1, wpos[2] + trect[2]+1}}
            --{"position", {wpos[1] + trect[3]+1, wpos[2] + trect[2]}}
        })
        --widget_set_size(wcprops[wcpScrollH][idx], scrwidth, vsize[1])
        wc_call_arrange(wcprops[wcpScrollH][idx])
    elsif needH = 0 and wcprops[wcpScrollH][idx] > 0 then
        widget:widget_destroy(wcprops[wcpScrollH][idx])
        wcprops[wcpScrollH][idx] = 0
        wcprops[wcpScrollPosX][idx] = 0
    end if
    if needV = 1 and wcprops[wcpScrollV][idx] = 0 then
        wcprops[wcpScrollV][idx] = widget:widget_create(widget_get_name(wid) & ".scrV", wid, "scrollbar", {
            {"attach", wid},
            {"orientation", 0},
            {"min", 0}
            --{"position", {wpos[1] + trect[3]+1, wpos[2] + trect[2]}}
            --{"size", {scrwidth, wcprops[wcpVisibleSize][idx][2]}}
        })
        --widget_set_size(wcprops[wcpScrollV][idx], scrwidth, vsize[2])
        wc_call_arrange(wcprops[wcpScrollV][idx])
    elsif needV = 0 and wcprops[wcpScrollV][idx] > 0 then
        widget:widget_destroy(wcprops[wcpScrollV][idx])
        wcprops[wcpScrollV][idx] = 0
        wcprops[wcpScrollPosY][idx] = 0
    end if
    if wcprops[wcpScrollH][idx] > 0 then
        wc_call_command(wcprops[wcpScrollH][idx], "set_max", csize[1])
        wc_call_command(wcprops[wcpScrollH][idx], "set_range", vsize[1])
        wc_call_command(wcprops[wcpScrollH][idx], "set_value", wcprops[wcpScrollPosX][idx])
    end if
    if wcprops[wcpScrollV][idx] > 0 then
        wc_call_command(wcprops[wcpScrollV][idx], "set_max", csize[2])
        wc_call_command(wcprops[wcpScrollV][idx], "set_range", vsize[2])
        wc_call_command(wcprops[wcpScrollV][idx], "set_value", wcprops[wcpScrollPosY][idx])
    end if
end procedure


-- widgetclass handlers ----------------------------

procedure wc_create(atom wid, object wprops) 
    atom wh, wshowborder = 1, whandleroutine = 0, wbackgroundpointer = mArrow,
    whandledebug = 0, wpreformancedebug = 0, wscrollforeground = 1
    sequence wname, wbackgroundimage, whandleimage, wlabel = ""
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do         
                case "label" then
                    wlabel = wprops[p][2]
                    
                case "border" then
                    wshowborder = wprops[p][2]
                    
                case "scroll_foreground" then
                    wscrollforeground = wprops[p][2]
                    
                case "handle_routine" then
                    whandleroutine = wprops[p][2]
                    
                case "background_pointer" then
                    if equal(wprops[p][2], "Arrow") then
                        wbackgroundpointer = mArrow
                    elsif equal(wprops[p][2], "ArrowBusy") then
                        wbackgroundpointer = mArrowBusy
                    elsif equal(wprops[p][2], "Ibeam") then
                        wbackgroundpointer = mIbeam
                    elsif equal(wprops[p][2], "Busy") then
                        wbackgroundpointer = mBusy
                    elsif equal(wprops[p][2], "No") then
                        wbackgroundpointer = mNo
                    elsif equal(wprops[p][2], "NS") then
                        wbackgroundpointer = mNS
                    elsif equal(wprops[p][2], "EW") then
                        wbackgroundpointer = mEW
                    elsif equal(wprops[p][2], "NWSE") then
                        wbackgroundpointer = mNWSE
                    elsif equal(wprops[p][2], "NESW") then
                        wbackgroundpointer = mNESW
                    elsif equal(wprops[p][2], "Crosshair") then
                        wbackgroundpointer = mCrosshair
                    elsif equal(wprops[p][2], "None") then
                        wbackgroundpointer = mNone
                    elsif equal(wprops[p][2], "Sleeping") then
                        wbackgroundpointer = mSleeping
                    elsif equal(wprops[p][2], "Link") then
                        wbackgroundpointer = mLink
                    end if

                case "handle_debug" then
                    whandledebug = wprops[p][2]
                                       
                case "performance_debug" then
                    wpreformancedebug = wprops[p][2]
                    
            end switch
        end if
    end for
    
    wh = widget:widget_get_handle(wid)
    wname = widget:widget_get_name(wid)
    wbackgroundimage = wname & "_BackgroundImage"
    create_bitmap(wbackgroundimage, ScreenX, ScreenY)
    whandleimage = wname & "_HandleImage"
    create_bitmap(whandleimage, ScreenX, ScreenY)
    
    sequence cmds = {
        --Fill background with color to match theme (otherwise, it would be black)
        --{DR_SelectBitmap, wbackgroundimage},
        {DR_PenColor, th:cOuterFill},
        {DR_Rectangle, True, 0, 0, ScreenX, ScreenY}
    }
    oswin:draw(wh, cmds, wbackgroundimage)
    
    wcprops[wcpID] &= {wid}
    wcprops[wcpSoftFocus] &= {0}
    wcprops[wcpHardFocus] &= {0}
    
    wcprops[wcpLabel] &= {wlabel}
    wcprops[wcpShowBorder] &= {wshowborder}
    wcprops[wcpScrollForeground] &= {wscrollforeground}
    
    wcprops[wcpBackgroundImage] &= {wbackgroundimage}
    wcprops[wcpHandleImage] &= {whandleimage}
    wcprops[wcpForegroundDrawCmds] &= {{}}
    wcprops[wcpBackgroundDrawCmds] &= {{}}
         
    wcprops[wcpHandleNames] &= {{}}
    wcprops[wcpHandleColors] &= {{}}
    wcprops[wcpHandleShapeCmds] &= {{}}
    --wcprops[wcpHandleDrawCmds] &= {{}}
    wcprops[wcpHandlePointers] &= {{}}
         
    wcprops[wcpBackgroundPointer] &= {wbackgroundpointer}
    wcprops[wcpOverridePointer] &= {0}
    
    wcprops[wcpShowHandleDebug] &= {whandledebug}
    wcprops[wcpShowPerformanceDebug] &= {wpreformancedebug}
    
    wcprops[wcpLabelPos] &= {{0, 0}}
    wcprops[wcpCanvasRect] &= {{0, 0, 0, 0}}
    wcprops[wcpVisibleSize] &= {{0, 0}}
    wcprops[wcpContentSize] &= {{0, 0}}
    wcprops[wcpScrollXEnabled] &= {0}
    wcprops[wcpScrollYEnabled] &= {0}
    wcprops[wcpScrollPosX] &= {0}
    wcprops[wcpScrollPosY] &= {0}

    wcprops[wcpScrollV] &= {0}
    wcprops[wcpScrollH] &= {0}
end procedure


procedure wc_destroy(atom wid)
    atom idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        oswin:destroy_bitmap(wcprops[wcpBackgroundImage][idx])
        oswin:destroy_bitmap(wcprops[wcpHandleImage][idx])
    
        for p = 1 to wcpLENGTH do
            wcprops[p] = remove(wcprops[p], idx)
        end for
    end if
end procedure


procedure wc_draw(atom wid)
    sequence cmds = {}, wrect, chwid, txex, txpos, lrect, lpos, irect
    atom idx = find(wid, wcprops[wcpID]), wh, wf, hlcolor, shcolor, fillcolor, txtcolor, hicolor, stripecolor
    atom indent, checkbox, numbered, ih, xp, yp, ss
    sequence clabels, cwidths, csort, sortdir, iids, itexts, iicons, iselected
    atom scry,scrx, hover
    sequence iconlist, selection
    
    if idx > 0 then
        wrect = widget_get_rect(wid)
        --wrect[3] -= 1
        --wrect[4] -= 1
        
        wh = widget:widget_get_handle(wid)
        wf = (wh = oswin:get_window_focus())
        
        if wcprops[wcpShowBorder][idx] = 1 then
            lpos = wcprops[wcpLabelPos][idx]
            lrect = wcprops[wcpCanvasRect][idx]
            lpos[1] += wrect[1]
            lpos[2] += wrect[2]
            lrect[1] += wrect[1]
            lrect[2] += wrect[2]
            lrect[3] += wrect[1]
            lrect[4] += wrect[2]
            if wcprops[wcpScrollV][idx] then
                lrect[3] -= scrwidth
            end if
            if wcprops[wcpScrollH][idx] then
                lrect[4] -= scrwidth
            end if
            
            if wcprops[wcpHardFocus][idx] and wf then
                hicolor = th:cOuterActive
            elsif wcprops[wcpSoftFocus][idx] then
                hicolor = th:cOuterHover
            else
                hicolor = th:cOuterFill
            end if
            
            shcolor = th:cButtonShadow
            hlcolor = th:cButtonHighlight
            
            txpos = {
                wrect[1] + wcprops[wcpLabelPos][idx][1] + 1,
                wrect[2] + wcprops[wcpLabelPos][idx][2] + 1
            }
            
            --draw border and label:
            cmds &= {
            --fill:
                {DR_PenColor, hicolor},
                {DR_Rectangle, True} & wrect
            }
            
            if length(wcprops[wcpLabel][idx]) > 0 then 
                cmds &= {
                --label:
                    {DR_Font, "Arial", 9, Normal},
                    {DR_TextColor, th:cOuterLabel},
                    {DR_PenPos} & txpos,
                    {DR_Puts, wcprops[wcpLabel][idx]}
                }
            end if
            
            cmds &= {
            --border:
                {DR_PenColor, shcolor},
                {DR_Line, lrect[1]-1, lrect[2]-1, lrect[3], lrect[2]-1},
                {DR_Line, lrect[1]-1, lrect[2]-1, lrect[1]-1, lrect[4]},
                
                {DR_PenColor, hlcolor},
                
                {DR_Line, lrect[3], lrect[2]-1, lrect[3], lrect[4]},
                {DR_Line, lrect[1]-1, lrect[4], lrect[3], lrect[4]},
                
                {DR_PenColor, th:cInnerFill},
                {DR_Rectangle, True, lrect[1], lrect[2], lrect[3], lrect[4]}
            }

        else  --don't show border or label (use entire widget rect for the drawing area)
            lrect = wrect 
        end if
        
        --Draw background to background image, if there are drawing commands in queue
        --if length(wcprops[wcpBackgroundDrawCmds][idx]) > 0 then
        --    draw(wcprops[wcpBackgroundImage][idx], wcprops[wcpBackgroundDrawCmds][idx])
        --    wcprops[wcpBackgroundDrawCmds][idx] = {}
        --end if
        
        --Draw background and foreground:
        cmds &= {
            {DR_Restrict, lrect[1], lrect[2], lrect[3], lrect[4]}, --restrict drawing to canvas area
            {DR_Image, wcprops[wcpBackgroundImage][idx], lrect[1], lrect[2], lrect[3], lrect[4]}
            --{DR_Image, wcprops[wcpHandleImage][idx], lrect[1], lrect[2], lrect[3], lrect[4]},
            --{DR_Image, "redy_logo", lrect[1], lrect[2], lrect[3], lrect[4]},
        }
        if wcprops[wcpScrollForeground][idx] = 1 then
            cmds &= {
                {DR_Offset, lrect[1] - wcprops[wcpScrollPosX][idx], lrect[2] - wcprops[wcpScrollPosY][idx]}
            }
        else
            cmds &= {
                {DR_Offset, lrect[1], lrect[2]}
            }
        end if
        cmds &= wcprops[wcpForegroundDrawCmds][idx]
        
        --Draw handles (visible parts):
        --for h = 1 to length(wcprops[wcpHandleDrawCmds][idx]) do
        --    cmds &= wcprops[wcpHandleDrawCmds][idx][h]
        --end for
        
        
        cmds &= {
            {DR_Offset, 0, 0}
        }
        
        
        --Draw Debug Information
        if wcprops[wcpShowHandleDebug][idx] = 1 then
            cmds &= {
                {DR_Image, wcprops[wcpHandleImage][idx], lrect[1], lrect[2], lrect[3], lrect[4]}
                --{DR_Image, "redy_logo", lrect[1]+50, lrect[2]+150, lrect[3], lrect[4]}
            }
        end if
        if wcprops[wcpShowPerformanceDebug][idx] = 1 then
            cmds &= {
                {DR_Font, "Arial", 9, Bold},
                {DR_TextColor, rgb(200, 200, 0)},
                {DR_PenPos, lrect[1] + 2, lrect[2] + 2},
                {DR_Puts, "Debug Information:"}
            }
        end if
        
        
        cmds &= {
            {DR_Release}
        }
        
        draw(wh, cmds)
        
        chwid = children_of(wid)
        for ch = 1 to length(chwid) do
            wc_call_draw(chwid[ch])
        end for
    end if
end procedure


procedure wc_event(atom wid, sequence evtype, object evdata)
    sequence ampos, wrect, lpos, lrect
    atom idx = find(wid, wcprops[wcpID]), doredraw = 0, wh, ss, se, skip = 0, citem
    atom th, vh, hidx
    sequence wname, hname
    
    if idx > 0 then
        wh = widget:widget_get_handle(wid)
        wrect = widget_get_rect(wid)
        --wrect[3] -= 1
        --wrect[4] -= 1
        if wcprops[wcpShowBorder][idx] = 1 then
            lpos = wcprops[wcpLabelPos][idx]
            lrect = wcprops[wcpCanvasRect][idx]
            lpos[1] += wrect[1]
            lpos[2] += wrect[2]
            lrect[1] += wrect[1]
            lrect[2] += wrect[2]
            lrect[3] += wrect[1]
            lrect[4] += wrect[2]
        else
            lrect = wrect
        end if
        if wcprops[wcpScrollH][idx] then
            lrect[4] -= scrwidth
        end if
        if wcprops[wcpScrollV][idx] then
            lrect[3] -= scrwidth
        end if
        
        switch evtype do        
            case "MouseMove" then --{x, y, shift, mousepos[1], mousepos[2]}
                if in_rect(evdata[1], evdata[2], wrect) then
                    if wcprops[wcpSoftFocus][idx] = 0 then
                        wcprops[wcpSoftFocus][idx] = 1
                        doredraw = 1
                    end if
                else
                    if wcprops[wcpSoftFocus][idx] = 1 then
                        wcprops[wcpSoftFocus][idx] = 0
                        doredraw = 1
                    end if
                end if
                
                if in_rect(evdata[1], evdata[2], lrect) then
                    wname = widget_get_name(wid)
                    hidx = identify_handle(idx, wh, evdata[1] - lrect[1], evdata[2] - lrect[2])
                    check_pointer(idx, wh, hidx)
                    if hidx > 0 then
                        hname = wcprops[wcpHandleNames][idx][hidx]
                    else
                        hname = ""
                    end if
                    widget:wc_send_event(wname, "handle", {hname, "MouseMove", evdata[1] - lrect[1], evdata[2] - lrect[2]})
                else
                    if wcprops[wcpSoftFocus][idx] then
                        set_mouse_pointer(wh, mArrow)
                    end if
                end if
            
            case "LeftDown" then        
                if in_rect(evdata[1], evdata[2], wrect) then
                    if in_rect(evdata[1], evdata[2], lrect) then
                        oswin:capture_mouse(wh)
                        wname = widget_get_name(wid)
                        --widget:wc_send_event(wname, "LeftDown", {evdata[1], evdata[2]})
                        hidx = identify_handle(idx, wh, evdata[1] - lrect[1], evdata[2] - lrect[2])
                        check_pointer(idx, wh, hidx)
                        if hidx > 0 then
                            hname = wcprops[wcpHandleNames][idx][hidx]
                        else
                            hname = ""
                        end if
                        widget:wc_send_event(wname, "handle", {hname, "LeftDown", evdata[1] - lrect[1], evdata[2] - lrect[2]})
                    end if
                    
                    if wcprops[wcpHardFocus][idx] = 0 then
                        wcprops[wcpHardFocus][idx] = 1
                        doredraw = 1
                    end if
                else
                    if wcprops[wcpHardFocus][idx] = 1 then
                        wcprops[wcpHardFocus][idx] = 0
                        doredraw = 1
                    end if
                end if

            case "LeftUp" then      
                if in_rect(evdata[1], evdata[2], lrect) then
                    wname = widget_get_name(wid)
                    --widget:wc_send_event(wname, "LeftUp", {evdata[1], evdata[2]})
                    hidx = identify_handle(idx, wh, evdata[1] - lrect[1], evdata[2] - lrect[2])
                    check_pointer(idx, wh, hidx)
                    if hidx > 0 then
                        hname = wcprops[wcpHandleNames][idx][hidx]
                    else
                        hname = ""
                    end if
                    widget:wc_send_event(wname, "handle", {hname, "LeftUp", evdata[1] - lrect[1], evdata[2] - lrect[2]})
                    doredraw = 1
                end if
            
            case "RightDown" then        
                if in_rect(evdata[1], evdata[2], wrect) then
                    if in_rect(evdata[1], evdata[2], lrect) then
                        wname = widget_get_name(wid)
                        --widget:wc_send_event(wname, "RightDown", {evdata[1], evdata[2]})
                        hidx = identify_handle(idx, wh, evdata[1] - lrect[1], evdata[2] - lrect[2])
                        check_pointer(idx, wh, hidx)
                        if hidx > 0 then
                            hname = wcprops[wcpHandleNames][idx][hidx]
                        else
                            hname = ""
                        end if
                        widget:wc_send_event(wname, "handle", {hname, "RightDown", evdata[1] - lrect[1], evdata[2] - lrect[2]})
                    end if
                end if

            case "RightUp" then      
                if in_rect(evdata[1], evdata[2], lrect) then
                    wname = widget_get_name(wid)
                    --widget:wc_send_event(wname, "RightUp", {evdata[1], evdata[2]})
                    hidx = identify_handle(idx, wh, evdata[1] - lrect[1], evdata[2] - lrect[2])
                    check_pointer(idx, wh, hidx)
                    if hidx > 0 then
                        hname = wcprops[wcpHandleNames][idx][hidx]
                    else
                        hname = ""
                    end if
                    widget:wc_send_event(wname, "handle", {hname, "RightUp", evdata[1] - lrect[1], evdata[2] - lrect[2]})
                end if
            
            case "WheelMove" then
                if wcprops[wcpSoftFocus][idx] > 0 then
                    /*wname = widget_get_name(wid)
                    --widget:wc_send_event(wname, "WheelMove", evdata[2])
                    hidx = identify_handle(idx, wh, evdata[1] - lrect[1], evdata[2] - lrect[2])
                    check_pointer(idx, wh, hidx)
                    if hidx > 0 then
                        hname = wcprops[wcpHandleNames][idx][hidx]
                    else
                        hname = ""
                    end if
                    widget:wc_send_event(wname, "handle", {hname, "WheelMove", evdata[1], evdata[2]})
                    */
                    wc_call_command(wcprops[wcpScrollV][idx], "set_value_rel", -evdata[2] * optScrollIncrement)
                end if
            
            case "KeyDown" then
            
                if wcprops[wcpHardFocus][idx] then
                    wname = widget_get_name(wid)
                    widget:wc_send_event(wname, "KeyDown", evdata)
                    
                    if evdata[1] = 37 then --left
                        
                    elsif evdata[1] = 39 then --right
                        
                    elsif evdata[1] = 38 then --up
                        
                    elsif evdata[1] = 40 then --down
                        
                    elsif evdata[1] = 33 then --pgup
                    elsif evdata[1] = 34 then --pgdown
                    elsif evdata[1] = 36 then --home
                        
                    elsif evdata[1] = 35 then --end
                        
                    
                    end if
                    
                    doredraw = 1
                end if
                
            case "KeyPress" then
                if wcprops[wcpHardFocus][idx] then
                    wname = widget_get_name(wid)
                    widget:wc_send_event(wname, "KeyPress", evdata)
                
                    if evdata[1] > 13 then --normal characters
                        
                    end if
                    
                    doredraw = 1
                end if
                
            case "scroll" then
                if evdata[1] = wcprops[wcpScrollH][idx] then
                    wcprops[wcpScrollPosX][idx] = evdata[2]
                    doredraw = 1
                    wname = widget_get_name(wid)
                    widget:wc_send_event(wname, "scroll", {wcprops[wcpScrollPosX][idx], wcprops[wcpScrollPosY][idx]})
                end if
                if evdata[1] = wcprops[wcpScrollV][idx] then
                    wcprops[wcpScrollPosY][idx] = evdata[2]
                    doredraw = 1
                    wname = widget_get_name(wid)
                    widget:wc_send_event(wname, "scroll", {wcprops[wcpScrollPosX][idx], wcprops[wcpScrollPosY][idx]})
                end if
                
            case "LostFocus" then
                wcprops[wcpSoftFocus][idx] = 0
                doredraw = 1
                
            case "Timer" then
                if evdata[1] > 1 then
                    ampos = get_mouse_pos()
                    if in_rect(ampos[1], ampos[2], lrect) then
                        hidx = identify_handle(idx, wh, ampos[1] - lrect[1], ampos[2] - lrect[2])
                        check_pointer(idx, wh, hidx)
                    end if
                end if
                
            case "changed" then    
          
                --wc_call_command(wcprops[wcpScrollV][idx], "set_max", th)
                --wc_call_command(wcprops[wcpScrollV][idx], "set_range", vh)
                    
                
                
                
                --wcprops[wcpContentSize][idx] = {,}
                --check_scrollbars(idx, wid)

                
                --puts(1, "resized canvas:" & sprint(lrect) &  "\n")
                --lrect = wcprops[wcpCanvasRect][idx]
                --wname = widget_get_name(wid)
                --widget:wc_send_event(wname, "resized", {lrect[3] - lrect[1], lrect[4] - lrect[2]})
                
                --doredraw = 1
            
            case else
                --statusUpdateMsg(0, "gui: window event:" & evtype & sprint(evdata), 0)
        end switch     
           
        if doredraw then
            wc_call_draw(wid)
        end if
    end if
end procedure


procedure wc_resize(atom wid)
    atom idx = find(wid, wcprops[wcpID]), wh, wparent
    sequence wsize, txex, lpos, trect
    
    if idx > 0 then
        wh = widget_get_handle(wid)
        --label:
        oswin:set_font(wh, "Arial", 9, Normal)
        txex = oswin:get_text_extent(wh, wcprops[wcpLabel][idx])
        wsize = {txex[1] + 6, txex[2] + 6 + 30}
        
        widget:widget_set_min_size(wid, wsize[1] + 6, wsize[2])
        widget:widget_set_natural_size(wid, 0, 0)

        wparent = parent_of(wid)
        if wparent > 0 then
            wc_call_resize(wparent)
        end if
    end if
end procedure



procedure wc_arrange(atom wid)
    atom idx = find(wid, wcprops[wcpID]), wh
    sequence wpos, wsize, txex, trect, oldsize, newsize
    
    if idx > 0 then
        wpos = widget_get_pos(wid)
        wsize = widget_get_size(wid)
        
        wh = widget_get_handle(wid)
        
        if wcprops[wcpShowBorder][idx] = 1 then
            --label:
            oswin:set_font(wh, "Arial", 9, Normal)
            txex = oswin:get_text_extent(wh, wcprops[wcpLabel][idx])
            trect = {3, txex[2] + 6, wsize[1] - 3, wsize[2] - 3}
            wcprops[wcpLabelPos][idx] = {3, 3}
        else
            trect = {0, 0, wsize[1], wsize[2]}
            wcprops[wcpLabelPos][idx] = {0, 0}
        end if
        
        if not equal(wcprops[wcpCanvasRect][idx], trect) then
            wcprops[wcpCanvasRect][idx] = trect
            oldsize = wcprops[wcpVisibleSize][idx]
            newsize = {trect[3] - trect[1], trect[4] - trect[2]}
            if not equal(oldsize, newsize) then
                wcprops[wcpVisibleSize][idx] = newsize
                
                /*
                oswin:create_bitmap("temp", oldsize[1], oldsize[2])
                
                oswin:draw(wh, {
                    {DR_Image, wcprops[wcpBackgroundImage][idx], 0, 0, oldsize[1], oldsize[2]}
                }, "temp")
                oswin:create_bitmap(wcprops[wcpBackgroundImage][idx], newsize[1], newsize[2])
                oswin:draw(wh, {
                    --{DR_PenColor, th:cOuterFill},
                    --{DR_Rectangle, True, 0, 0, newsize[1], newsize[2]},
                    {DR_Image, "temp", 0, 0, oldsize[1], oldsize[2]}
                }, wcprops[wcpBackgroundImage][idx])
                
                oswin:draw(wh, {
                    {DR_Image, wcprops[wcpHandleImage][idx], 0, 0, oldsize[1], oldsize[2]}
                }, "temp")
                oswin:create_bitmap(wcprops[wcpHandleImage][idx], newsize[1], newsize[2])
                oswin:draw(wh, {
                    --{DR_PenColor, rgb(0, 0, 0)},
                    --{DR_Rectangle, True, 0, 0, newsize[1], newsize[2]},
                    {DR_Image, "temp", 0, 0, oldsize[1], oldsize[2]}
                }, wcprops[wcpHandleImage][idx])
                */
                
                check_scrollbars(idx, wid)
                widget:wc_send_event(widget_get_name(wid), "resized", wcprops[wcpVisibleSize][idx])
            end if
        end if
        

        if wcprops[wcpScrollV][idx] then
            trect[3] -= scrwidth
        end if
        if wcprops[wcpScrollH][idx] then
            trect[4] -= scrwidth
        end if
        
        if wcprops[wcpScrollV][idx] then
            widget_set_pos(wcprops[wcpScrollV][idx], wpos[1] + trect[3]+1, wpos[2] + trect[2])
            widget_set_size(wcprops[wcpScrollV][idx], scrwidth, trect[4] - trect[2] + 1)
        end if
        
        if wcprops[wcpScrollH][idx] then
            widget_set_pos(wcprops[wcpScrollH][idx], wpos[1] + trect[1]+1, wpos[2] + trect[4])
            widget_set_size(wcprops[wcpScrollH][idx], trect[3] - trect[1] + 1, scrwidth)
        end if
        
        wc_call_draw(wid)
        
        if wcprops[wcpScrollV][idx] then
            wc_call_arrange(wcprops[wcpScrollV][idx])
        end if
        if wcprops[wcpScrollH][idx] then
            wc_call_arrange(wcprops[wcpScrollH][idx])
        end if
    end if
end procedure


function wc_debug(atom wid)
    atom idx = find(wid, wcprops[wcpID])
    sequence debuginfo = {}
    
    if idx > 0 then    
        debuginfo = {
            {"SoftFocus", wcprops[wcpSoftFocus][idx]},
            {"HardFocus", wcprops[wcpHardFocus][idx]},
                          
            {"Label", wcprops[wcpLabel][idx]},
            {"ShowBorder", wcprops[wcpShowBorder][idx]},
            {"ScrollForeground", wcprops[wcpScrollForeground][idx]},

            {"BackgroundImage", wcprops[wcpBackgroundImage][idx]},
            {"HandleImage", wcprops[wcpHandleImage][idx]},
            {"ForegroundDrawCmds", wcprops[wcpForegroundDrawCmds][idx]},
            {"BackgroundDrawCmds", wcprops[wcpBackgroundDrawCmds][idx]},
                                
            --{"HandleRoutine", wcprops[wcpHandleRoutine][idx]},
                                
            {"HandleNames", wcprops[wcpHandleNames][idx]},
            {"HandleColors", wcprops[wcpHandleColors][idx]},
            {"HandleShapeCmds", wcprops[wcpHandleShapeCmds][idx]},
            --{"HandleDrawCmds", wcprops[wcpHandleDrawCmds][idx]},
            {"HandlePointers", wcprops[wcpHandlePointers][idx]},
                                
            {"BackgroundPointer", wcprops[wcpBackgroundPointer][idx]},
            {"OverridePointer", wcprops[wcpOverridePointer][idx]},
                         
            {"ShowHandleDebug", wcprops[wcpShowHandleDebug][idx]},
            {"ShowPerformanceDebug", wcprops[wcpShowPerformanceDebug][idx]},
     
            {"LabelPos", wcprops[wcpLabelPos][idx]},
            {"DocRect", wcprops[wcpCanvasRect][idx]},
            {"VisibleSize", wcprops[wcpVisibleSize][idx]},
            {"ContentSize", wcprops[wcpContentSize][idx]},
            {"ScrollXEnabled", wcprops[wcpScrollXEnabled][idx]},
            {"ScrollYEnabled", wcprops[wcpScrollYEnabled][idx]},
            {"ScrollPosX", wcprops[wcpScrollPosX][idx]},
            {"ScrollPosY", wcprops[wcpScrollPosY][idx]},
                          
            {"ScrollV", wcprops[wcpScrollV][idx]},
            {"ScrollH", wcprops[wcpScrollH][idx]}
        }
    end if
    return debuginfo
end function



wc_define(
    "canvas",
    routine_id("wc_create"),
    routine_id("wc_destroy"),
    routine_id("wc_draw"),
    routine_id("wc_event"),
    routine_id("wc_resize"),
    routine_id("wc_arrange"),
    routine_id("wc_debug")
)   
    

-- widgetclass commands -------------------------------------------------------


procedure cmd_set_label(atom wid, sequence txt)
    atom idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wcprops[wcpLabel][idx] = txt       
    end if
    
    wc_call_draw(wid)
    
end procedure
wc_define_command("canvas", "set_label", routine_id("cmd_set_label"))



procedure cmd_set_visible_size(atom wid, atom cx, atom cy) --doesn't work yet
    atom idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        --wcprops[wcpVisibleSize][idx]
    end if
end procedure
wc_define_command("canvas", "set_visible_size", routine_id("cmd_set_visible_size"))


procedure cmd_set_canvas_size(atom wid, atom cx, atom cy)
    atom idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wcprops[wcpContentSize][idx] = {cx, cy}
        
        if cx = 0 then
            wcprops[wcpScrollXEnabled][idx] = 0
            wcprops[wcpScrollPosX][idx] = 0
        else
            wcprops[wcpScrollXEnabled][idx] = 1
        end if
        if cy = 0 then
            wcprops[wcpScrollYEnabled][idx] = 0
            wcprops[wcpScrollPosY][idx] = 0
        else
            wcprops[wcpScrollYEnabled][idx] = 1
        end if
        
        check_scrollbars(idx, wid)
    end if
end procedure
wc_define_command("canvas", "set_canvas_size", routine_id("cmd_set_canvas_size"))


procedure cmd_set_background_pointer(atom wid, object mc)
    atom idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        if sequence(mc) then
            switch mc do
                case "Arrow" then
                    wcprops[wcpBackgroundPointer][idx] = mArrow
                case "ArrowBusy" then
                    wcprops[wcpBackgroundPointer][idx] = mArrowBusy
                case "Ibeam" then
                    wcprops[wcpBackgroundPointer][idx] = mIbeam
                case "Busy" then
                    wcprops[wcpBackgroundPointer][idx] = mBusy
                case "No" then
                    wcprops[wcpBackgroundPointer][idx] = mNo
                case "NS" then
                    wcprops[wcpBackgroundPointer][idx] = mNS
                case "EW" then
                    wcprops[wcpBackgroundPointer][idx] = mEW
                case "NWSE" then
                    wcprops[wcpBackgroundPointer][idx] = mNWSE
                case "NESW" then
                    wcprops[wcpBackgroundPointer][idx] = mNESW
                case "Crosshair" then
                    wcprops[wcpBackgroundPointer][idx] = mCrosshair
                case "None" then
                    wcprops[wcpBackgroundPointer][idx] = mNone
                case "Sleeping" then
                    wcprops[wcpBackgroundPointer][idx] = mSleeping
                case "Link" then
                    wcprops[wcpBackgroundPointer][idx] = mLink
            end switch
        else
            wcprops[wcpBackgroundPointer][idx] = mc
        end if
    end if
end procedure
wc_define_command("canvas", "set_background_pointer", routine_id("cmd_set_background_pointer"))


procedure cmd_draw_background(atom wid, sequence drawcmds)
    atom idx = find(wid, wcprops[wcpID]), t0
    sequence cmds
    
    if idx > 0 then
        --t0 = time()
        
        --cmds = {}
        --select the background bitmap
        --    {DR_SelectBitmap, wcprops[wcpBackgroundImage][idx]}
        --}
        --& drawcmds
        
        --wcprops[wcpBackgroundDrawCmds][idx] = drawcmds
        atom wh = widget:widget_get_handle(wid)
        oswin:draw(wh, drawcmds, wcprops[wcpBackgroundImage][idx])
        --wc_call_draw(wid)
        
        
        --if time() - t0 > 0 then
        --    puts(1, "wc_canvas.cmd_draw: " & sprint(length(drawcmds)) & " commands in " & sprint(time() - t0) & "s\n")
        --end if
        wc_call_draw(wid)
    end if
end procedure
wc_define_command("canvas", "draw_background", routine_id("cmd_draw_background"))

procedure cmd_draw_foreground(atom wid, object drawcmds) --drawcmds: 0 = clear, sequence = append draw commands
    atom idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        --if sequence(drawcmds) then
        wcprops[wcpForegroundDrawCmds][idx] = drawcmds
        --else  
        --    wcprops[wcpForegroundDrawCmds][idx] = {}
        --end if
        wc_call_draw(wid)
    end if
end procedure
wc_define_command("canvas", "draw_foreground", routine_id("cmd_draw_foreground"))
  

--procedure cmd_set_handle(atom wid, sequence hname, sequence hshape, sequence hdraw, object hpointer) --creates a new handle, or overrides an existing handle
procedure cmd_set_handle(atom wid, sequence hname, sequence hshape, object hpointer) --creates a new handle, or overrides an existing handle
    atom idx = find(wid, wcprops[wcpID]), hidx
    
    if idx > 0 then
        hidx = find(hname, wcprops[wcpHandleNames][idx])
        if hidx = 0 then
            wcprops[wcpHandleNames][idx] &= {hname}
            wcprops[wcpHandleColors][idx] &= {next_handle_color(idx)}
            wcprops[wcpHandleShapeCmds][idx] &= {hshape}
            --wcprops[wcpHandleDrawCmds][idx] &= {hdraw}
            wcprops[wcpHandlePointers][idx] &= {hpointer}
        else
            wcprops[wcpHandleNames][idx][hidx] = hname
            wcprops[wcpHandleShapeCmds][idx][hidx] = hshape
            --wcprops[wcpHandleDrawCmds][idx][hidx] = hdraw
            wcprops[wcpHandlePointers][idx][hidx] = hpointer
        end if
        
        draw_handles(wid, idx)
    end if
    
end procedure
wc_define_command("canvas", "set_handle", routine_id("cmd_set_handle"))


procedure cmd_clear_handles(atom wid)
    atom idx = find(wid, wcprops[wcpID]), hidx
    
    if idx > 0 then
        wcprops[wcpHandleNames][idx] = {}
        wcprops[wcpHandleColors][idx] = {}
        wcprops[wcpHandleShapeCmds][idx] = {}
        --wcprops[wcpHandleDrawCmds][idx] = {}
        wcprops[wcpHandlePointers][idx] = {}
    end if
    
    draw_handles(wid, idx)
end procedure
wc_define_command("canvas", "clear_handles", routine_id("cmd_clear_handles"))


procedure cmd_destroy_handle(atom wid, sequence hname)
    atom idx = find(wid, wcprops[wcpID]), hidx
    
    if idx > 0 then
        hidx = find(hname, wcprops[wcpHandleNames][idx])
        
        if hidx > 0 then
            wcprops[wcpHandleNames][idx] = remove(wcprops[wcpHandleNames][idx], hidx)
            wcprops[wcpHandleColors][idx] = remove(wcprops[wcpHandleColors][idx], hidx)
            wcprops[wcpHandleShapeCmds][idx] = remove(wcprops[wcpHandleShapeCmds][idx], hidx)
            --wcprops[wcpHandleDrawCmds][idx] = remove(wcprops[wcpHandleDrawCmds][idx], hidx)
            wcprops[wcpHandlePointers][idx] = remove(wcprops[wcpHandlePointers][idx], hidx)
        end if
    end if
    
    draw_handles(wid, idx)
end procedure
wc_define_command("canvas", "destroy_handle", routine_id("cmd_destroy_handle"))



function cmd_get_canvas_size(atom wid)
    atom idx = find(wid, wcprops[wcpID])
    sequence csize = {0, 0}
    
    if idx > 0 then
        csize = {wcprops[wcpCanvasRect][idx][3] - wcprops[wcpCanvasRect][idx][1], wcprops[wcpCanvasRect][idx][4] - wcprops[wcpCanvasRect][idx][2]}
        if wcprops[wcpScrollV][idx] > 0 then
            csize[1] -= scrwidth
        end if
        if wcprops[wcpScrollH][idx] > 0 then
            csize[2] -= scrwidth
        end if
    end if
    
    return csize
end function
wc_define_function("canvas", "get_canvas_size", routine_id("cmd_get_canvas_size"))




