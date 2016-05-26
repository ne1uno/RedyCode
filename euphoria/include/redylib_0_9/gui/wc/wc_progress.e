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

include std/text.e

-- Internal class variables and routines

sequence wcprops

enum
wcpID,
wcpSoftFocus,

wcpLabel, --- progress bar layout: [ labeltext |=======---35%---------| ]
wcpValue, --value between 0 and 100%, or a special state: -1=not started, -2=error, -3=skipped, -4=stalled

wcpVagueMode, --0 = normal, 1 = Vague Mode (show dotted bar, no percentage indicator). Cycling wcpValue through 1-100 will animate (or 100-1 to animate in reverse)

wcpLabelPos, --label position (x, y)
wcpProgStartPos  --progress bar start position (x)

constant wcpLENGTH = wcpProgStartPos

wcprops = repeat({}, wcpLENGTH)




-- Theme variables -------------------------------

atom
thMinProgWidth = 50,
thProgHeight = 20

-- widgetclass handlers ----------------------------

procedure wc_create(atom wid, object wprops) 
    atom pvalue = 0, pstartpos = 0, pvague = 0
    sequence plabel = ""
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do          
                case "label" then
                    plabel = wprops[p][2]
                    
                case "value" then
                    pvalue = wprops[p][2]
                    
                case "vague" then
                    pvague = wprops[p][2]
                    
            end switch
        end if
    end for
    
    wcprops[wcpID] &= {wid}
    wcprops[wcpSoftFocus] &= {0}
    
    wcprops[wcpLabel] &= {plabel}
    wcprops[wcpValue] &= {pvalue}
    
    wcprops[wcpVagueMode] &= {pvague}
    
    wcprops[wcpLabelPos] &= {{0, 0}}
    wcprops[wcpProgStartPos] &= {pstartpos}
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
    sequence cmds, wrect, plbltxt, plblpos, pvaltxt, pvalpos, prect, txex
    atom idx, wh, hlcolor, shcolor, fillcolor, pcolor, px, pvalue, pspos
    atom divstart, divwidth
    sequence divpoints = {}
            
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wrect = widget_get_rect(wid)
        wh = widget_get_handle(wid)

        plblpos = wrect[1..2] + wcprops[wcpLabelPos][idx] 
        plbltxt = wcprops[wcpLabel][idx]

        pvalue = wcprops[wcpValue][idx]
        pspos = wcprops[wcpProgStartPos][idx]
        
        
        --pvalue between 0 and 100%, or a special state: -1=not started, -2=error, -3=skipped, -4=stalled
        if pvalue > 100 then
            pvalue = 100
        end if
        
        prect = {
            wrect[1] + pspos + 2,
            wrect[2] + 2,
            wrect[3] - 2,
            wrect[4] - 2
        }
        px = prect[3] - prect[1]
        
        if pvalue = -1 then
            pvaltxt = ""
            pcolor = 0
            
        elsif pvalue = -2 then
            pvaltxt = "Error"
            pcolor = rgb(255, 200, 200)
            
        elsif pvalue = -3 then
            pvaltxt = "Skipped"
            pcolor = rgb(200, 255, 200)
            
        elsif pvalue = -4 then
            px = 0
            pvaltxt = "Stalled"
            pcolor = rgb(120, 255, 120)
            
        elsif pvalue = 100 then
            px = (prect[3] - prect[1])
            pvaltxt = "100% - Complete"
            pcolor = rgb(120, 255, 120)
            
        else
            px = floor((prect[3] - prect[1]) / 100 * pvalue)

            pvaltxt = sprint(floor(pvalue)) & "%"
            pcolor = rgb(120, 255, 120)
        end if
        
        if wcprops[wcpVagueMode][idx] = 1 and pvalue > -1 then
            px = floor((prect[3] - prect[1]) / 100 * pvalue / 10)
        
            pvaltxt = ""
            pcolor = rgb(120, 255, 120)
        end if

        oswin:set_font(wh, "Arial", 9, Normal)
        txex = oswin:get_text_extent(wh, pvaltxt)
        pvalpos = {
            prect[1] + floor((prect[3] - prect[1]) / 2 - txex[1] / 2),
            wrect[2] + floor((prect[4] - prect[2]) / 2 - txex[2] / 2) - 1
        }


        hlcolor = th:cButtonHighlight
        shcolor = th:cButtonShadow
        fillcolor = th:cButtonFace
        
        --draw background
        cmds = {
            {DR_PenColor, fillcolor},
            {DR_Rectangle, True} & wrect,
            
            {DR_TextColor, rgb(0, 0, 0)},
            {DR_Font, "Arial", 10, Normal},
            {DR_PenPos, plblpos[1], plblpos[2]},
            {DR_Puts, plbltxt}
        }
        if wcprops[wcpVagueMode][idx] = 1 then
            divwidth = floor((prect[3] - prect[1]) / 10)
            divstart = prect[1] - divwidth + px
            
            for dp = 0 to 12 do
                divpoints &= divstart + divwidth * dp
                if divpoints[$] < prect[1] then
                    divpoints[$] = prect[1] 
                end if
                if divpoints[$] > prect[3] then
                    divpoints[$] = prect[3] 
                end if
            end for
            
            cmds &= {            
                {DR_PenColor, rgb(200, 200, 200)},
                {DR_Rectangle, True,  prect[1] - 2, prect[2] - 2, prect[3] + 2, prect[4] + 2}
            }
            
            for dp = 1 to 11 by 2 do
                cmds &= {
                    {DR_PenColor, pcolor},
                    {DR_Rectangle, True,  divpoints[dp], prect[2], divpoints[dp + 1], prect[4]}
                }
            end for
            
            cmds &= {
                {DR_PenColor, rgb(0, 0, 50)},
                {DR_Rectangle, False, prect[1] - 2, prect[2] - 2, prect[3] + 2, prect[4] + 2}
            } 
                      
        elsif pvalue != -1 then
            cmds &= {            
                {DR_PenColor, rgb(200, 200, 200)},
                {DR_Rectangle, True,  prect[1] - 2, prect[2] - 2, prect[3] + 2, prect[4] + 2},
                
                {DR_PenColor, pcolor},
                {DR_Rectangle, True,  prect[1], prect[2], prect[1] + px, prect[4]}, 
                
                {DR_PenColor, rgb(0, 0, 50)},
                {DR_Rectangle, False, prect[1] - 2, prect[2] - 2, prect[3] + 2, prect[4] + 2},
        
                {DR_TextColor, rgb(100, 100, 0)},
                {DR_PenPos, pvalpos[1] + 4, pvalpos[2] + 2},
                {DR_Puts, pvaltxt}
            }     
        end if
        
        draw(wh, cmds)
    end if
end procedure


procedure wc_event(atom wid, sequence evtype, object evdata)
    sequence ampos, wrect
    atom idx, wh, doredraw = 0
    sequence wname
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wh = widget:widget_get_handle(wid)
        wrect = widget_get_rect(wid)
        wrect[3] -= 1
        wrect[4] -= 1
        
        switch evtype do        
            case "MouseMove" then --{x, y, shift, mousepos[1], mousepos[2]}
                if in_rect(evdata[1], evdata[2], wrect) then
                    if wcprops[wcpSoftFocus][idx] = 0 then
                        wcprops[wcpSoftFocus][idx] = 1
                        set_mouse_pointer(wh, mArrow)
                        doredraw = 1
                    end if
                else
                    if wcprops[wcpSoftFocus][idx] = 1 then
                        wcprops[wcpSoftFocus][idx] = 0
                        wc_call_draw(wid)
                        doredraw = 1
                    end if
                end if
            
            case "LeftDown" then
            
            case "LeftUp" then
            
            case "LostFocus" then
                wcprops[wcpSoftFocus][idx] = 0
                doredraw = 1
                
            case else
            
        end switch
        
        if doredraw = 1 then
            wc_call_draw(wid)
        end if
    end if
end procedure


procedure wc_resize(atom wid)
    atom idx, wh, wparent, pstartpos
    sequence wsize, txex, lblpos
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wh = widget_get_handle(wid)
        oswin:set_font(wh, "Arial", 9, Normal)
        txex = oswin:get_text_extent(wh, wcprops[wcpLabel][idx])
        wsize = {2 + txex[1] + 10 + 2 + thMinProgWidth + 2, thProgHeight}
        --pstartpos = 2 + txex[1] + 10 + 2
        --lblpos = {
        --    4,
        --    floor(wsize[2] / 2 - txex[2] / 2) - 1
        --}
        --wcprops[wcpLabelPos][idx] = lblpos
        --wcprops[wcpProgStartPos][idx] = pstartpos
        
        widget:widget_set_min_size(wid, wsize[1], wsize[2])
        widget:widget_set_natural_size(wid, 0, wsize[2])
        
        wparent = parent_of(wid)
        if wparent > 0 then
            if equal(widget_get_class(wparent), "container") then
                widget:wc_call_event(wparent, "setboxwidth", {wid, txex[1]})
            end if
            wc_call_resize(wparent)
        end if
    end if
end procedure


procedure wc_arrange(atom wid)
    atom idx, wh, wparent, bw, pstartpos
    sequence wsize, txex, lblpos
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        wh = widget_get_handle(wid)
        oswin:set_font(wh, "Arial", 9, Normal)
        txex = oswin:get_text_extent(wh, wcprops[wcpLabel][idx])
        wparent = parent_of(wid)
        if wparent > 0 and equal(widget_get_class(wparent), "container") then
            bw = widget:wc_call_function(wparent, "get_box_width", {})
            if bw > 0 then
                txex[1] = bw
            end if
        end if
        
        wsize = {2 + txex[1] + 10 + 2 + thMinProgWidth + 2, thProgHeight}
        pstartpos = 2 + txex[1] + 10 + 2
        lblpos = {
            4,
            floor(wsize[2] / 2 - txex[2] / 2) - 1
        }
        wcprops[wcpLabelPos][idx] = lblpos
        wcprops[wcpProgStartPos][idx] = pstartpos
    
        wc_call_draw(wid)
    end if
end procedure


function wc_debug(atom wid)
    atom idx
    sequence debuginfo = {}
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then    
        debuginfo = {
            {"SoftFocus", wcprops[wcpSoftFocus][idx]},
            
            {"Label", wcprops[wcpLabel][idx]},
            {"Value", wcprops[wcpValue][idx]},
            
            {"VagueMode", wcprops[wcpVagueMode][idx]},
            
            {"LabelPos", wcprops[wcpLabelPos][idx]},
            {"ProgStartPos", wcprops[wcpProgStartPos][idx]}
        }
    end if
    return debuginfo
end function



wc_define(
    "progress",
    routine_id("wc_create"),
    routine_id("wc_destroy"),
    routine_id("wc_draw"),
    routine_id("wc_event"),
    routine_id("wc_resize"),
    routine_id("wc_arrange"),
    routine_id("wc_debug")
)   
    
-- widgetclass commands -------------------------------------------------------

procedure cmd_set_value(atom wid, atom sv)
    atom idx
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        wcprops[wcpValue][idx] = sv
        wc_call_draw(wid)
    end if
end procedure
wc_define_command("progress", "set_value", routine_id("cmd_set_value"))
