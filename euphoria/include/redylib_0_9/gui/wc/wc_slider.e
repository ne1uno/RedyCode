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


public include redylib_0_9/gui/widgets.e as widget
public include redylib_0_9/oswin.e as oswin
public include redylib_0_9/gui/themes.e as th

include std/sequence.e

-- Internal class variables and routines

sequence wcprops

enum
    wcpID,
    wcpSoftFocus,
    wcpHardFocus,
    wcpKeyFocus,

    wcpMin,
    wcpMax,
    wcpValue,
    wcpRange,

    wcpLength,
    wcpOrientation,
    
    wcpMinPos,
    wcpScrStartPos,
    wcpScrEndPos,
    wcpMaxPos,
    
    wcpSubStartPos,
    wcpSubEndPos,
    wcpAddStartPos,
    wcpAddEndPos,

    wcpPressed,  --0=none, 1=sub, 2=fastsub,3=scroller,4=fastadd,5=add
    wcpClicked,
    wcpOffset,

    wcpAttachedWidget
    
    
constant wcpLENGTH = wcpAttachedWidget

wcprops = repeat({}, wcpLENGTH)

constant
    scrV = 0,
    scrH = 1

-- Theme variables -------------------------------

atom 
scrSize = 16,
scrStyle = 0, --style of button placement, 0 = buttons on each end, 1 = buttons on top/left, 2 = buttons on bottom/right, 3 = no buttons
scrForeColor = th:cButtonFace,
scrBackColor = th:cButtonDark,
scrSoftFocusColor = th:cButtonHover,
scrBackSoftFocusColor = th:cButtonDark,
scrShadowColor = th:cButtonShadow,
scrHighlightColor = th:cButtonHighlight,

barsz = 6,

scrSizeOverride = 10


-- local routines ---------------------------------
-- --- wcpSubStartPos
-- [ ] 
-- --- wcpSubEndPos
-- --- wcpMinPos
--     
-- --- wcpScrStartPos
-- *** 
-- *** 
-- *** 
-- --- wcpScrEndPos
--     
--     
-- --- wcpMaxPos
-- --- wcpAddStartPos
-- [ ] 
-- --- wcpAddEndPos


procedure set_scroll(atom wid)
    atom idx
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        position_scroller(wid)
        widget:wc_call_event(wcprops[wcpAttachedWidget][idx], "scroll", {wid, wcprops[wcpValue][idx]})
        wc_call_draw(wid)
    end if
end procedure
            
            
procedure position_scroller(atom wid)
    atom idx, f, p, w, e, ss, se, ow, nw
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        f = wcprops[wcpMaxPos][idx] - wcprops[wcpMinPos][idx]
        e = wcprops[wcpMax][idx] - wcprops[wcpMin][idx]
        p = wcprops[wcpValue][idx]
        w = p + wcprops[wcpRange][idx]
                
        if e > 0 then
            ss = floor(p * f / e)
            se = floor(w * f / e)
            
            --if se - ss < scrSizeOverride then --if scroller is < minimum allowed size, then overide size, and do some math to make range behave properly
                ow = f - (se - ss)
                nw = f - scrSizeOverride
                
                if ow > 0 and nw > 0 then
                    ss = floor(ss *  nw / ow)
                    se = ss + scrSizeOverride
                else
                    ss = 0
                    se = f
                end if
            --end if
            
            wcprops[wcpScrStartPos][idx] = wcprops[wcpMinPos][idx] + ss
            wcprops[wcpScrEndPos][idx] = wcprops[wcpMinPos][idx] + se
        else
            wcprops[wcpScrStartPos][idx] = wcprops[wcpMinPos][idx]
            wcprops[wcpScrEndPos][idx] = wcprops[wcpMaxPos][idx]        
        end if
        
        if wcprops[wcpScrEndPos][idx] > wcprops[wcpMaxPos][idx] then
            wcprops[wcpScrEndPos][idx] = wcprops[wcpMaxPos][idx]
        end if
        if wcprops[wcpScrStartPos][idx] < wcprops[wcpMinPos][idx] then
            wcprops[wcpScrStartPos][idx] = wcprops[wcpMinPos][idx]
        end if
    end if
end procedure


function which_part(atom wid, atom mpos)
    atom idx
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        if mpos >= wcprops[wcpSubStartPos][idx] and mpos < wcprops[wcpSubEndPos][idx] then --sub
            return 1
        elsif mpos >= wcprops[wcpMinPos][idx] and mpos < wcprops[wcpScrStartPos][idx] then --fastsub
            return 2
        elsif mpos >= wcprops[wcpScrStartPos][idx] and mpos < wcprops[wcpScrEndPos][idx] then --scroller
            return 3
        elsif mpos >= wcprops[wcpScrEndPos][idx] and mpos < wcprops[wcpMaxPos][idx] then --fastadd
            return 4
        elsif mpos >= wcprops[wcpAddStartPos][idx] and mpos < wcprops[wcpAddEndPos][idx] then --add
            return 5
        else
            return 0                    
        end if
    else
        return 0
    end if
end function

-- widgetclass handlers ----------------------------

procedure wc_create(atom wid, object wprops)
    atom wMin = 0, wMax = 1, wValue = 0, wRange = 0, wLength = scrSize*2, wOrientation = 0, wMinPos = 0, wMaxPos = 0,
    wSubStartPos = 0, wSubEndPos = 0, wAddStartPos = 0, wAddEndPos = 0, wPressed = 0, wClicked = 0, wMovingOffset = 0, wAttachedWidget = 0
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do
                case "min" then
                    wMin = wprops[p][2]
                
                case "max" then
                    wMax = wprops[p][2]
                
                case "value" then
                    wValue = wprops[p][2]
                
                case "range" then
                    wRange = wprops[p][2]
                
                case "length" then
                    wLength = wprops[p][2]
                
                case "orientation" then
                    if equal(wprops[p][2], "horizontal") then
                        wOrientation = scrH
                    else
                        wOrientation = scrV
                    end if
                
                case "attach" then
                    wAttachedWidget = wprops[p][2]
                
            end switch
        end if
    end for
    
    wcprops[wcpID] &= {wid}
    wcprops[wcpSoftFocus] &= {0}
    wcprops[wcpHardFocus] &= {0}
    wcprops[wcpKeyFocus] &= {0}

    wcprops[wcpMin] &= {wMin}
    wcprops[wcpMax] &= {wMax}
    wcprops[wcpValue] &= {wValue}
    wcprops[wcpRange] &= {wRange}

    wcprops[wcpLength] &= {wLength}
    wcprops[wcpOrientation] &= {wOrientation}
    
    wcprops[wcpMinPos] &= {wMinPos}
    wcprops[wcpScrStartPos] &= {0}
    wcprops[wcpScrEndPos] &= {0}
    wcprops[wcpMaxPos] &= {wMaxPos}
    
    wcprops[wcpSubStartPos] &= {wSubStartPos}
    wcprops[wcpSubEndPos] &= {wSubEndPos}
    wcprops[wcpAddStartPos] &= {wAddStartPos}
    wcprops[wcpAddEndPos] &= {wAddEndPos}

    wcprops[wcpPressed] &= {wPressed}
    wcprops[wcpClicked] &= {wClicked}
    wcprops[wcpOffset] &= {wMovingOffset}

    wcprops[wcpAttachedWidget] &= {wAttachedWidget}
end procedure


procedure wc_destroy(atom wid)
    atom idx
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        for p = 1 to wcpLENGTH do
            wcprops[p] = remove(wcprops[p], idx)
        end for
    end if
end procedure


procedure wc_draw(atom wid)
    sequence cmds, wrect, subrect, addrect, fastsubrect, fastaddrect, scrrect, sliderect
    atom idx, wh, hlcolor, shcolor, fillcolor, areacolor, x1, y1, x2, y2
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wrect = widget_get_rect(wid)
        wh = widget:widget_get_handle(wid)
    
        if wcprops[wcpOrientation][idx] = scrV then
            subrect = {wrect[1], wrect[2] + wcprops[wcpSubStartPos][idx], wrect[3], wrect[2] + wcprops[wcpSubEndPos][idx]}
            addrect = {wrect[1], wrect[2] + wcprops[wcpAddStartPos][idx], wrect[3], wrect[2] + wcprops[wcpAddEndPos][idx]}
            fastsubrect = {wrect[1], wrect[2] + wcprops[wcpMinPos][idx], wrect[3], wrect[2] + wcprops[wcpScrStartPos][idx]}
            fastaddrect = {wrect[1], wrect[2] + wcprops[wcpScrEndPos][idx], wrect[3], wrect[2] + wcprops[wcpMaxPos][idx]}
            sliderect = {wrect[1] + barsz, wrect[2] + wcprops[wcpMinPos][idx], wrect[3] - barsz, wrect[2] + wcprops[wcpMaxPos][idx]}
            scrrect = {wrect[1], wrect[2] + wcprops[wcpScrStartPos][idx], wrect[3], wrect[2] + wcprops[wcpScrEndPos][idx]}

        else
            subrect = {wrect[1] + wcprops[wcpSubStartPos][idx], wrect[2], wrect[1] + wcprops[wcpSubEndPos][idx], wrect[4]}
            addrect = {wrect[1] + wcprops[wcpAddStartPos][idx], wrect[2], wrect[1] + wcprops[wcpAddEndPos][idx], wrect[4]}
            fastsubrect = {wrect[1] + wcprops[wcpMinPos][idx], wrect[2], wrect[1] + wcprops[wcpScrStartPos][idx], wrect[4]}
            fastaddrect = {wrect[1] + wcprops[wcpScrEndPos][idx], wrect[2], wrect[1] + wcprops[wcpMaxPos][idx], wrect[4]}
            sliderect = {wrect[1] + wcprops[wcpMinPos][idx], wrect[2] + barsz, wrect[1] + wcprops[wcpMaxPos][idx], wrect[4] - barsz}
            scrrect = {wrect[1] + wcprops[wcpScrStartPos][idx], wrect[2], wrect[1] + wcprops[wcpScrEndPos][idx], wrect[4]}
        end if
    
        cmds = {}    
--fastsubfill:
       if wcprops[wcpSoftFocus][idx] = 2 then --0=none, 1=sub, 2=fastsub,3=scroller,4=fastadd,5=add
            fillcolor = scrSoftFocusColor
            areacolor = scrBackSoftFocusColor
        else
            fillcolor = scrForeColor
            areacolor = scrBackColor
        end if
        cmds &= {
            --{DR_PenColor, fillcolor},
            --{DR_Rectangle, True} & fastsubrect,
            {DR_PenColor, areacolor},
            {DR_Rectangle, True} & fastsubrect
        }
        
        
--fastaddfill:
       if wcprops[wcpSoftFocus][idx] = 4 then --0=none, 1=sub, 2=fastsub,3=scroller,4=fastadd,5=add
            fillcolor = scrSoftFocusColor
            areacolor = scrBackSoftFocusColor
        else
            fillcolor = scrForeColor
            areacolor = scrBackColor
        end if
        cmds &= {
            --{DR_PenColor, fillcolor},
            --{DR_Rectangle, True} & wrect,
            {DR_PenColor, areacolor},
            {DR_Rectangle, True} & fastaddrect
        }
        
        
--sub button:          
        if wcprops[wcpPressed][idx] = 1 then --0=none, 1=sub, 2=fastsub,3=scroller,4=fastadd,5=add
            hlcolor = scrShadowColor
            shcolor = scrHighlightColor
        else
            hlcolor = scrHighlightColor
            shcolor = scrShadowColor
        end if
        if wcprops[wcpSoftFocus][idx] = 1 then
            fillcolor = scrSoftFocusColor
            areacolor = scrBackSoftFocusColor
        else
            fillcolor = scrForeColor
            areacolor = scrBackColor
        end if
        x1 = subrect[1]
        y1 = subrect[2]
        x2 = subrect[3]
        y2 = subrect[4]
        
        cmds &= {
            {DR_PenColor, areacolor},
            {DR_Rectangle, True} & subrect
            --{DR_PenColor, hlcolor}
            --{DR_Line, x1, y1, x2 - 1, y1},
            --{DR_Line, x1, y1, x1, y2 - 1}
        }
        
        /*
        if wcprops[wcpOrientation][idx] = scrV then
            cmds &= {
                {DR_Line, floor(x1 + scrSize *.2), floor(y1 + scrSize *.8), floor(x1 + scrSize *.5), floor(y1 + scrSize *.1)}
            }
        else
            cmds &= {
                {DR_Line, floor(x1 + scrSize *.8), floor(y1 + scrSize *.2), floor(x1 + scrSize *.1), floor(y1 + scrSize *.5)}
            }
        end if
        
                            
        cmds &= {
            {DR_PenColor, shcolor}
            --{DR_Line, x2 - 1, y1, x2 - 1, y2 - 1},
            --{DR_Line, x1, y2 - 1, x2 - 1, y2 - 1}
        }
        if wcprops[wcpOrientation][idx] = scrV then
            cmds &= {
                {DR_Line, floor(x1 + scrSize *.2), floor(y1 + scrSize *.8), floor(x1 + scrSize *.8), floor(y1 + scrSize *.8)},
                {DR_Line, floor(x1 + scrSize *.8), floor(y1 + scrSize *.8), floor(x1 + scrSize *.5), floor(y1 + scrSize *.1)}
            }
        else
            cmds &= {
                {DR_Line, floor(x1 + scrSize *.8), floor(y1 + scrSize *.2), floor(x1 + scrSize *.8), floor(y1 + scrSize *.8)},
                {DR_Line, floor(x1 + scrSize *.8), floor(y1 + scrSize *.8), floor(x1 + scrSize *.1), floor(y1 + scrSize *.5)}
            }
        end if
        */
        
--add button:
        if wcprops[wcpPressed][idx] = 5 then --0=none, 1=sub, 2=fastsub,3=scroller,4=fastadd,5=add
            hlcolor = scrShadowColor
            shcolor = scrHighlightColor
        else
            hlcolor = scrHighlightColor
            shcolor = scrShadowColor
        end if
        if wcprops[wcpSoftFocus][idx] = 5 then
            fillcolor = scrSoftFocusColor
            areacolor = scrBackSoftFocusColor
        else
            fillcolor = scrForeColor
            areacolor = scrBackColor
        end if
        x1 = addrect[1]
        y1 = addrect[2]
        x2 = addrect[3]
        y2 = addrect[4]
        
        cmds &= {
            {DR_PenColor, areacolor},
            {DR_Rectangle, True} & addrect
            --{DR_PenColor, hlcolor}
            --{DR_Line, x1, y1, x2 - 1, y1},
            --{DR_Line, x1, y1, x1, y2 - 1}
        }
        /*
        if wcprops[wcpOrientation][idx] = scrV then
            cmds &= {
                {DR_Line, floor(x1 + scrSize *.2), floor(y1 + scrSize *.2), floor(x1 + scrSize *.8), floor(y1 + scrSize *.2)},
                {DR_Line, floor(x1 + scrSize *.2), floor(y1 + scrSize *.2), floor(x1 + scrSize *.5), floor(y1 + scrSize *.9)}
            }
        else
            cmds &= {
                {DR_Line, floor(x1 + scrSize *.2), floor(y1 + scrSize *.2), floor(x1 + scrSize *.2), floor(y1 + scrSize *.8)},
                {DR_Line, floor(x1 + scrSize *.2), floor(y1 + scrSize *.2), floor(x1 + scrSize *.9), floor(y1 + scrSize *.5)}
            }
        end if
            
        cmds &= {   
            {DR_PenColor, shcolor}
            --{DR_Line, x2 - 1, y1, x2 - 1, y2 - 1},
            --{DR_Line, x1, y2 - 1, x2 - 1, y2 - 1}
        }
        if wcprops[wcpOrientation][idx] = scrV then
            cmds &= {
                {DR_Line, floor(x1 + scrSize *.8), floor(y1 + scrSize *.2), floor(x1 + scrSize *.5), floor(y1 + scrSize *.9)}
            }
        else
            cmds &= {
                {DR_Line, floor(x1 + scrSize *.2), floor(y1 + scrSize *.8), floor(x1 + scrSize *.9), floor(y1 + scrSize *.5)}
            }
        end if
        */
        
--slide bar:
        hlcolor = scrHighlightColor
        shcolor = scrShadowColor

        x1 = sliderect[1]
        y1 = sliderect[2] 
        x2 = sliderect[3]
        y2 = sliderect[4] 
        
        cmds &= {
            {DR_PenColor, fillcolor}, --areacolor},
            {DR_Rectangle, True, x1, y1, x2, y2},
            {DR_PenColor, hlcolor},
            {DR_Line, x1, y1, x2 - 1, y1},
            {DR_Line, x1, y1, x1, y2 - 1},
            {DR_PenColor, shcolor},
            {DR_Line, x2 - 1, y1, x2 - 1, y2 - 1},
            {DR_Line, x1, y2 - 1, x2 - 1, y2 - 1}
        }

--scroller:
        if wcprops[wcpPressed][idx] = 3 or wcprops[wcpOffset][idx] > 0 then --0=none, 1=sub, 2=fastsub,3=scroller,4=fastadd,5=add
            hlcolor = scrShadowColor
            shcolor = scrHighlightColor
        else
            hlcolor = scrHighlightColor
            shcolor = scrShadowColor
        end if
        if wcprops[wcpSoftFocus][idx] = 3 or wcprops[wcpOffset][idx] > 0  then
            fillcolor = scrSoftFocusColor
            areacolor = scrBackSoftFocusColor
        else
            fillcolor = scrForeColor
            areacolor = scrBackColor
        end if
        cmds &= {
            --fill:
            {DR_PenColor, fillcolor},
            {DR_Rectangle, True} & scrrect,
            
            --border:
            {DR_PenColor, hlcolor},
            {DR_Line, scrrect[1] + 1, scrrect[2], scrrect[3] - 1, scrrect[2]},
            {DR_Line, scrrect[1], scrrect[2] + 1, scrrect[1], scrrect[4] - 1},

            {DR_Line, scrrect[3] - 1 - 2, scrrect[2] + 2, scrrect[3] - 1 - 2, scrrect[4] - 1 - 2},
            {DR_Line, scrrect[1] + 2, scrrect[4] - 1 - 2, scrrect[3] - 1 - 2, scrrect[4] - 1 - 2},
                        
            {DR_PenColor, shcolor},

            {DR_Line, scrrect[3] - 1, scrrect[2], scrrect[3] - 1, scrrect[4] - 1},
            {DR_Line, scrrect[1], scrrect[4] - 1, scrrect[3] - 1, scrrect[4] - 1},

            {DR_Line, scrrect[1] + 1 + 2, scrrect[2] + 2, scrrect[3] - 1 - 2, scrrect[2] + 2},
            {DR_Line, scrrect[1] + 2, scrrect[2] + 1 + 2, scrrect[1] + 2, scrrect[4] - 1 - 2}
        }
        
        oswin:draw(wh, cmds, "", wrect)
    end if
end procedure


procedure wc_event(atom wid, sequence evtype, object evdata)
    sequence ampos, wrect, mousepos, winpos
    atom idx, doredraw = 0, mpos, whichpart, wh
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wh = widget:widget_get_handle(wid)
        wrect = widget_get_rect(wid)
        wrect[3] -= 1
        wrect[4] -= 1
        
        switch evtype do        
            case "MouseMove" then --{x, y, shift, mousepos[1], mousepos[2]}
                if in_rect(evdata[1], evdata[2], wrect) then
                    if wcprops[wcpOrientation][idx] = scrV then
                        whichpart = which_part(wid, evdata[2] - wrect[2])
                    else
                        whichpart = which_part(wid, evdata[1] - wrect[1])
                    end if
                    
                    if wcprops[wcpSoftFocus][idx] != whichpart then
                        wcprops[wcpSoftFocus][idx] = whichpart
                        doredraw = 1
                    end if
                    --if evdata[3] = 16 and 
                    if wcprops[wcpClicked][idx] = 1 then --if button is down?
                        wcprops[wcpPressed][idx] = whichpart
                        doredraw = 1
                    end if
                else
                    if wcprops[wcpSoftFocus][idx] > 0 then
                        wcprops[wcpSoftFocus][idx] = 0
                        wc_call_draw(wid)
                        doredraw = 1
                    end if
                    if wcprops[wcpPressed][idx] > 0 and wcprops[wcpClicked][idx] = 1 then
                        wcprops[wcpPressed][idx] = 0
                        wc_call_draw(wid)
                        doredraw = 1
                    end if
                end if
                if wcprops[wcpClicked][idx] = 1 and wcprops[wcpOffset][idx] > 0 then
                    if wcprops[wcpOrientation][idx] = scrV then
                        mpos = evdata[2] - wrect[2] - wcprops[wcpMinPos][idx] - wcprops[wcpOffset][idx]
                    else
                        mpos = evdata[1] - wrect[1] - wcprops[wcpMinPos][idx] - wcprops[wcpOffset][idx]
                    end if
                    cmd_set_value(wid, wcprops[wcpMin][idx] +
                        mpos * (wcprops[wcpMax][idx] - wcprops[wcpMin][idx] ) --+ wcprops[wcpRange][idx])
                        / (wcprops[wcpMaxPos][idx] - wcprops[wcpMinPos][idx])
                    )
                    
                    -------------------------
                    
                    atom f, e, p, w, ss, se, ow, nw, om
                    f = wcprops[wcpMaxPos][idx] - wcprops[wcpMinPos][idx]
                    e = wcprops[wcpMax][idx] - wcprops[wcpMin][idx]
                    p = wcprops[wcpValue][idx]
                    w = p + wcprops[wcpRange][idx]
                    om = mpos
                    
                    if e > 0 then
                        ss = floor(p * f / e)
                        se = floor(w * f / e)
                        
                        --set scroller size
                        ow = f - (se - ss)
                        nw = f - scrSizeOverride
                        
                        if ow > 0 and nw > 0 then
                            om = floor(om *  ow / nw)
                        end if
                    end if
                    
                    cmd_set_value(wid, wcprops[wcpMin][idx] + om * e / f)
                end if
            
            case "LeftDown" then    
                if in_rect(evdata[1], evdata[2], wrect) then
                    oswin:capture_mouse(wh)
                    if wcprops[wcpOrientation][idx] = scrV then
                        whichpart = which_part(wid, evdata[2] - wrect[2])
                    else
                        whichpart = which_part(wid, evdata[1] - wrect[1])
                    end if
                    wcprops[wcpPressed][idx] = whichpart
                    wcprops[wcpClicked][idx] = 1
                    
                    if whichpart = 1 then  --1=sub
                        cmd_set_value(wid, wcprops[wcpValue][idx] - 1)
                    
                    elsif whichpart = 2 then  --2=fastsub
                        cmd_set_value(wid, wcprops[wcpValue][idx] - wcprops[wcpRange][idx])
                    
                    elsif whichpart = 3 then  --3=scroller
                        
                        if wcprops[wcpOrientation][idx] = scrV then
                            wcprops[wcpOffset][idx] = evdata[2] - wrect[2] - wcprops[wcpScrStartPos][idx]
                        else
                            wcprops[wcpOffset][idx] = evdata[1] - wrect[1] - wcprops[wcpScrStartPos][idx]
                        end if
                    
                    elsif whichpart = 4 then  --4=fastadd
                        cmd_set_value(wid, wcprops[wcpValue][idx] + wcprops[wcpRange][idx])
                    
                    elsif whichpart = 5 then  --5=add                  
                        cmd_set_value(wid, wcprops[wcpValue][idx] + 1)
                    end if
                    
                    wcprops[wcpHardFocus][idx] = 1
                    --widget:wc_send_event(widget_get_name(wid), "GotFocus", {})
                    widget:set_key_focus(wid)
                    doredraw = 1
                end if

            case "LeftUp" then      
                if wcprops[wcpClicked][idx] = 1 then --and wcprops[wcpPressed][idx] > 0 then
                    doredraw = 1
                end if
                wcprops[wcpClicked][idx] = 0
                wcprops[wcpPressed][idx] = 0
                wcprops[wcpOffset][idx] = 0

            case "WheelMove" then
                if wcprops[wcpSoftFocus][idx] > 0 then
                    position_scroller(wid)
                    cmd_set_value(wid, wcprops[wcpValue][idx] - evdata[2]*5)
                end if
            
            case "Timer" then
                if wcprops[wcpClicked][idx] and evdata[1] = 2 then
                    mousepos = get_mouse_pos()
                    wh = widget:widget_get_handle(wid)
                    winpos = get_window_pos(wh)
                    --mousepos[1..2] -= winpos[1..2]
                    
                    if wcprops[wcpOrientation][idx] = scrV then
                        whichpart = which_part(wid, mousepos[2] - wrect[2])
                    else
                        whichpart = which_part(wid, mousepos[1] - wrect[1])
                    end if
                    if whichpart = 1 then  --1=sub
                        cmd_set_value(wid, wcprops[wcpValue][idx] - 5)
                    
                    elsif whichpart = 2 then  --2=fastsub
                        cmd_set_value(wid, wcprops[wcpValue][idx] - wcprops[wcpRange][idx])
                    
                    elsif whichpart = 4 then  --4=fastadd
                        cmd_set_value(wid, wcprops[wcpValue][idx] + wcprops[wcpRange][idx])
                    
                    elsif whichpart = 5 then  --5=add                  
                        cmd_set_value(wid, wcprops[wcpValue][idx] + 5)
                    
                    end if
                end if
                
            case "LostFocus" then
                wcprops[wcpSoftFocus][idx] = 0
                doredraw = 1
                
            case "KeyFocus" then
                if evdata = wid then
                    wcprops[wcpKeyFocus][idx] = 1
                else
                    wcprops[wcpKeyFocus][idx] = 0
                end if
                
            case else
                --statusUpdateMsg(0, "gui: window event:" & evtype & sprint(evdata), 0)
        end switch
        
        if doredraw = 1 then
            wc_call_draw(wid)
        end if
    end if
end procedure


procedure wc_resize(atom wid)
    atom idx, wh, wparent
    sequence wsize, txex, txpos
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        if wcprops[wcpOrientation][idx] = scrV then
            widget:widget_set_min_size(wid, scrSize, wcprops[wcpLength][idx]) --scrSize*2)
            widget:widget_set_natural_size(wid, scrSize, 0)
        else
            widget:widget_set_min_size(wid, wcprops[wcpLength][idx], scrSize) --scrSize*2, scrSize)
            widget:widget_set_natural_size(wid, 0, scrSize)
        end if
        
        wparent = parent_of(wid)
        if wparent > 0 then
            wc_call_resize(wparent)
        end if
    end if
end procedure


-- Fix below: -------------------------------------------------------------------

procedure wc_arrange(atom wid)
    atom idx
    sequence wpos, wsize
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wpos = widget:widget_get_pos(wid)
        wsize = widget:widget_get_size(wid)
        
        if wcprops[wcpOrientation][idx] = scrV then
            wcprops[wcpLength][idx] = wsize[2]
        else
            wcprops[wcpLength][idx] = wsize[1]
        end if
        
        if scrStyle = 0 then --0 = buttons on each end
            wcprops[wcpMinPos][idx] = floor(scrSize / 3)
            wcprops[wcpMaxPos][idx] = wcprops[wcpLength][idx] - floor(scrSize / 3)
            
            wcprops[wcpSubStartPos][idx] = 0
            wcprops[wcpSubEndPos][idx] = floor(scrSize / 3)
            wcprops[wcpAddStartPos][idx] = wcprops[wcpLength][idx] - floor(scrSize / 3)
            wcprops[wcpAddEndPos][idx] = wcprops[wcpLength][idx]
        
        elsif scrStyle = 1 then --1 = buttons on top/left,
        elsif scrStyle = 2 then --2 = buttons on bottom/right
        elsif scrStyle = 3 then --3 = no buttons
        end if
    end if
    
    position_scroller(wid)
    wc_call_draw(wid)

end procedure


function wc_debug(atom wid)
    atom idx
    sequence debuginfo = {}
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then    
        debuginfo = {
            {"SoftFocus", wcprops[wcpSoftFocus][idx]},
            {"HardFocus", wcprops[wcpHardFocus][idx]},
            {"KeyFocus", wcprops[wcpKeyFocus][idx]},
        
            {"Min", wcprops[wcpMin][idx]},
            {"Max", wcprops[wcpMax][idx]},
            {"Value", wcprops[wcpValue][idx]},
            {"Range", wcprops[wcpRange][idx]},
        
            {"Length", wcprops[wcpLength][idx]},
            {"Orientation", wcprops[wcpOrientation][idx]},
            
            {"MinPos", wcprops[wcpMinPos][idx]},
            {"ScrStartPos", wcprops[wcpScrStartPos][idx]},
            {"ScrEndPos", wcprops[wcpScrEndPos][idx]},
            {"MaxPos", wcprops[wcpMaxPos][idx]},
            
            {"SubStartPos", wcprops[wcpSubStartPos][idx]},
            {"SubEndPos", wcprops[wcpSubEndPos][idx]},
            {"AddStartPos", wcprops[wcpAddStartPos][idx]},
            {"AddEndPos", wcprops[wcpAddEndPos][idx]},
        
            {"Pressed", wcprops[wcpPressed][idx]},
            {"Clicked", wcprops[wcpClicked][idx]},
            {"Offset", wcprops[wcpOffset][idx]},
        
            {"AttachedWidget", wcprops[wcpAttachedWidget][idx]}
        }
    end if
    return debuginfo
end function


wc_define(
    "slider",
    routine_id("wc_create"),
    routine_id("wc_destroy"),
    routine_id("wc_draw"),
    routine_id("wc_event"),
    routine_id("wc_resize"),
    routine_id("wc_arrange"),
    routine_id("wc_debug")
)   
    

-- widgetclass commands -------------------------------------------------------

procedure cmd_set_length(atom wid, atom slen)
    
end procedure
wc_define_command("slider", "set_length", routine_id("cmd_set_length"))


procedure cmd_set_min(atom wid, atom smin)
    atom idx
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        if wcprops[wcpValue][idx] > wcprops[wcpMax][idx] - wcprops[wcpRange][idx] then
            wcprops[wcpValue][idx] = wcprops[wcpMax][idx] - wcprops[wcpRange][idx]
        end if
        if wcprops[wcpValue][idx] < smin then
            wcprops[wcpValue][idx] = smin
        end if
             
        wcprops[wcpMin][idx] = smin
        set_scroll(wid)
    end if
end procedure
wc_define_command("slider", "set_min", routine_id("cmd_set_min"))


procedure cmd_set_max(atom wid, atom smax)
    atom idx
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        if wcprops[wcpValue][idx] > smax - wcprops[wcpRange][idx] then
            wcprops[wcpValue][idx] = smax - wcprops[wcpRange][idx]
        end if
        if wcprops[wcpValue][idx] < wcprops[wcpMin][idx] then
            wcprops[wcpValue][idx] = wcprops[wcpMin][idx]
        end if
        
        --if wcprops[wcpValue][idx] = wcprops[wcpMax][idx] and wcprops[wcpStayAtBottom][idx] then
        --    wcprops[wcpValue][idx] = smax        
        --end if

        wcprops[wcpMax][idx] = smax
        set_scroll(wid)
    end if
end procedure
wc_define_command("slider", "set_max", routine_id("cmd_set_max"))


procedure cmd_set_range(atom wid, atom srange)
    atom idx
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        if srange > wcprops[wcpMax][idx] then
            srange = wcprops[wcpMax][idx]
        end if
        if srange < wcprops[wcpMin][idx] then
            srange = wcprops[wcpMin][idx]
        end if
        
        wcprops[wcpRange][idx] = srange

        if wcprops[wcpValue][idx] > wcprops[wcpMax][idx] - wcprops[wcpRange][idx] then
            wcprops[wcpValue][idx] = wcprops[wcpMax][idx] - wcprops[wcpRange][idx]
        end if
        if wcprops[wcpValue][idx] < wcprops[wcpMin][idx] then
            wcprops[wcpValue][idx] = wcprops[wcpMin][idx]
        end if
        
        set_scroll(wid)
    end if
end procedure
wc_define_command("slider", "set_range", routine_id("cmd_set_range"))



procedure cmd_set_value(atom wid, atom sv)
    atom idx
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        if sv > wcprops[wcpMax][idx] - wcprops[wcpRange][idx] then
            sv = wcprops[wcpMax][idx] - wcprops[wcpRange][idx]
        end if
        if sv < wcprops[wcpMin][idx] then
            sv = wcprops[wcpMin][idx]
        end if
        
        wcprops[wcpValue][idx] = sv
        set_scroll(wid)
    end if
end procedure
wc_define_command("slider", "set_value", routine_id("cmd_set_value"))


procedure cmd_set_value_rel(atom wid, atom sv)
    atom idx
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        sv += wcprops[wcpValue][idx]
         
        if sv > wcprops[wcpMax][idx] - wcprops[wcpRange][idx] then
            sv = wcprops[wcpMax][idx] - wcprops[wcpRange][idx]
        end if
        if sv < wcprops[wcpMin][idx] then
            sv = wcprops[wcpMin][idx]
        end if
        
        wcprops[wcpValue][idx] = sv
        set_scroll(wid)
    end if
end procedure
wc_define_command("slider", "set_value_rel", routine_id("cmd_set_value_rel"))

