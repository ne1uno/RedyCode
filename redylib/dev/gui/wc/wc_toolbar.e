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
wcpOrientation, --children orientation mode 0: Vertical 1: Horizontal
wcpSizeModeX,   --0 = Children & Container will be Minimum sizes
wcpSizeModeY,   --1 = Chlldren will be the same size as the child with the largest Natural size, toolbar will be minimum size
                --2 = Container will stretch to size of parent toolbar, children will stretch to match toolbar's size
wcpJustifyX,    --0 = left, 1 = center, 2 = right
wcpJustifyY,    --0 = top, 1 = center, 2 = bottom --not implemented yet
wcpAdjust,      --list of adjustments: {firstchild, secondchild, etc...} integer: size in pixels, (decimal 0.01 - 0.99): size in percentage of toolbar's total size
wcpBoxAlign,    --0 = normal, 1=align boxes by makeing labels the same with as the widest label
wcpBoxWidth,    --width of children labels (if wcpBoxAlign = 1)
wcpGroupLabel,  -- atom: no group border, sequence: show group border with label
wcpMargin,      -- integer: margin width on all sides. {i, i}: top/bottom, right/left. {i, i, i}: top, right/left, bottom. {i, i, i, i}: top, right, bottom, left.
wcpSpacing      --integer: space between children


constant wcpLENGTH = wcpSpacing,
WSPACE = 1
--WPOSITION = 2 --0 = left, 1 = center, 2 = right


wcprops = repeat({}, wcpLENGTH)




-- Theme variables -------------------------------
atom thGroupBoxMargin = 8


-- widgetclass handlers ----------------------------

procedure wc_create(atom wid, object wprops)
    atom orientation = 0, smx = 0, smy = 0, wparent, justx = 0, justy = 0, boxalign = 1
    sequence wpos, wsize
    object adj = {}, lbl = 0, margin = {10, 3, 3, 3}, spacing = 2
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do          
                case "dock" then
                    if equal(wprops[p][2], "top") then
                        orientation = 1
                    elsif equal(wprops[p][2], "right") then
                        orientation = 0
                    elsif equal(wprops[p][2], "bottom") then
                        orientation = 1
                    elsif equal(wprops[p][2], "left") then
                        orientation = 0
                    end if
                
                case "orientation" then
                    if equal(wprops[p][2], "horizontal") then
                        orientation = 1
                    else
                        orientation = 0
                    end if
                    
                case "sizemode_x" then
                    if equal(wprops[p][2], "normal") then
                        smx = 0
                    elsif equal(wprops[p][2], "equal") then
                        smx = 1
                    elsif equal(wprops[p][2], "expand") then
                        smx = 2
                    else
                        smx = 0
                    end if
                    
                case "sizemode_y" then
                    if equal(wprops[p][2], "normal") then
                        smy = 0
                    elsif equal(wprops[p][2], "equal") then
                        smy = 1
                    elsif equal(wprops[p][2], "expand") then
                        smy = 2
                    else
                        smx = 0
                    end if
                    
                case "justify_x" then
                    if equal(wprops[p][2], "left") then
                        justx = 0
                    elsif equal(wprops[p][2], "center") then
                        justx = 1
                    elsif equal(wprops[p][2], "right") then
                        justx = 2
                    else
                        justx = 0
                    end if
                    
                case "justify_y" then
                    if equal(wprops[p][2], "top") then
                        justy = 0
                    elsif equal(wprops[p][2], "center") then
                        justy = 1
                    elsif equal(wprops[p][2], "bottom") then
                        justy = 2
                    else
                        justy = 0 
                    end if
                    
                case "adjust" then
                    adj = wprops[p][2]
                    
                case "box_align" then
                    boxalign = wprops[p][2]
                    
                case "label" then
                    lbl = wprops[p][2]
                
                case "margin" then
                    margin = wprops[p][2]
                
                case "spacing" then
                    spacing = wprops[p][2]
                    
            end switch
        end if
    end for
    
    wpos = widget:widget_get_pos(wid)
    wsize = widget:widget_get_size(wid)
    
    wcprops[wcpID] &= {wid}
    wcprops[wcpSoftFocus] &= {0}
    wcprops[wcpHardFocus] &= {0}
    wcprops[wcpOrientation] &= {orientation}
    wcprops[wcpSizeModeX] &= {smx}
    wcprops[wcpSizeModeY] &= {smy}
    wcprops[wcpJustifyX] &= {justx}
    wcprops[wcpJustifyY] &= {justy}
    wcprops[wcpAdjust] &= {adj}
    wcprops[wcpBoxAlign] &= {boxalign}
    wcprops[wcpBoxWidth] &= {{{}, {}}}
    wcprops[wcpGroupLabel] &= {lbl}
    wcprops[wcpMargin] &= {margin}
    wcprops[wcpSpacing] &= {spacing}
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
    sequence cmds = {}, wrect, hrect, chwid
    atom idx = find(wid, wcprops[wcpID]), wh, wf, hlcolor, shcolor, hicolor
    
    if idx > 0 then
        --toolbars don't need to draw anything, except for testing
        wrect = widget_get_rect(wid)
        wh = widget:widget_get_handle(wid)
        wf = (wh = oswin:get_window_focus())
        
        --if wcprops[wcpHardFocus][idx] and wf then
        --    hicolor = th:cOuterActive
        --elsif wcprops[wcpSoftFocus][idx] then
        --    hicolor = th:cOuterHover
        --else
        hicolor = th:cOuterFill
        --end if
        
        shcolor = th:cButtonShadow
        hlcolor = th:cButtonHighlight
        
        --draw border and label:
        cmds &= {
        --fill:
            {DR_PenColor, hicolor},
            {DR_Rectangle, True} & wrect
        }
        
        
        hrect = {wrect[1]+3, wrect[2]+3, wrect[1]+7, wrect[4]-3}
        cmds &= {
        --handle:
            {DR_PenColor, shcolor},
            {DR_Line, hrect[1]-1, hrect[2]-1, hrect[3], hrect[2]-1},
            {DR_Line, hrect[1]-1, hrect[2]-1, hrect[1]-1, hrect[4]},
            
            {DR_PenColor, hlcolor},
            
            {DR_Line, hrect[3], hrect[2]-1, hrect[3], hrect[4]},
            {DR_Line, hrect[1]-1, hrect[4], hrect[3], hrect[4]}
        }
        
        cmds &= {
        --border:
            {DR_PenColor, hlcolor},
            {DR_Line, wrect[1]-1, wrect[2]-1, wrect[3], wrect[2]-1},
            {DR_Line, wrect[1]-1, wrect[2]-1, wrect[1]-1, wrect[4]},
            
            {DR_PenColor, shcolor},
            
            {DR_Line, wrect[3], wrect[2]-1, wrect[3], wrect[4]},
            {DR_Line, wrect[1]-1, wrect[4], wrect[3], wrect[4]}
        }
        
        draw(wh, cmds)
        
        chwid = children_of(wid)
        for ch = 1 to length(chwid) do
            wc_call_draw(chwid[ch])
        end for
    end if
end procedure


procedure wc_event(atom wid, sequence evtype, object evdata)
    atom idx, chidx
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        switch evtype do        
            case "MouseMove" then
                if in_rect(evdata[1], evdata[2], widget_get_rect(wid)) then
                    if wcprops[wcpSoftFocus][idx] = 0 then
                        wcprops[wcpSoftFocus][idx] = 1
                        wc_call_draw(wid)
                        set_mouse_pointer(widget_get_handle(wid), mArrow)
                    end if
                else
                    if wcprops[wcpSoftFocus][idx] = 1 then
                        wcprops[wcpSoftFocus][idx] = 0
                        wc_call_draw(wid)
                    end if
                end if
                
            case "child created" then
                wcprops[wcpBoxWidth][idx][1] &= {evdata[1]} --boxwidth wid
                wcprops[wcpBoxWidth][idx][2] &= {0}       --boxwidth width
                
            case "child destroyed" then
                chidx = find(evdata, wcprops[wcpBoxWidth][idx][1])
                if chidx > 0 then
                    wcprops[wcpBoxWidth][idx][1] = remove(wcprops[wcpBoxWidth][idx][1], chidx)
                    wcprops[wcpBoxWidth][idx][2] = remove(wcprops[wcpBoxWidth][idx][2], chidx)
                end if
                
            case "setboxwidth" then
                chidx = find(evdata[1], wcprops[wcpBoxWidth][idx][1])
                if chidx > 0 then
                    wcprops[wcpBoxWidth][idx][2][chidx] = evdata[2]
                end if
                
            case "LostFocus" then
                wcprops[wcpSoftFocus][idx] = 0
                wc_call_draw(wid)
                
            --case else
                --statusUpdateMsg(0, "gui: window event:" & evtype & sprint(evdata), 0)
        end switch
    end if
end procedure


procedure wc_resize(atom wid)  --resizing affects parent and ancestors
    atom idx, wh, wparent
    sequence wch, ch = {}, temp, txex, msize = {{0}, {0}}, nsize = {{1}, {1}}, dsize = {{1}, {1}}, wmsize = {0, 0}, wnsize = {0, 0}, gbsize = {0, 0}
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        --get text extent of Group Label
        if sequence(wcprops[wcpGroupLabel][idx]) then
            wh = widget_get_handle(wid)
            oswin:set_font(wh, "Arial", 9, Normal)
            txex = oswin:get_text_extent(wh, wcprops[wcpGroupLabel][idx])
        end if
        
        --get list of visible children
        wch = children_of(wid)
        for w = 1 to length(wch) do
            if widget_is_visible(wch[w]) then
                ch &= wch[w]
            end if
        end for
        
        --build size lists
        for w = 1 to length(ch) do
            temp = widget_get_min_size(ch[w])
                msize[1] &= temp[1]
                msize[2] &= temp[2]
            temp = widget_get_natural_size(ch[w])
                nsize[1] &= temp[1]
                nsize[2] &= temp[2]
            temp = widget_get_default_size(ch[w])
                if temp[1] > msize[1][$] then
                    msize[1][$] = temp[1]
                end if
                if temp[2] > msize[2][$] then
                    msize[2][$] = temp[2] 
                end if
        end for
        
        --determine toolbar's size based on orientation, size mode, and children sizes 
        if wcprops[wcpOrientation][idx] = 0 then --vertical
            --Caluculate X
            if wcprops[wcpSizeModeX][idx] = 0 then    --natural sizes
                wmsize[1] = max(msize[1])
                --if find(0, nsize[1]) > 0 then
                ---    wnsize[1] = 0
                --else
                    wnsize[1] = max(nsize[1])
                --end if
            elsif wcprops[wcpSizeModeX][idx] = 1 then --largest natural size
                wmsize[1] = max(msize[1])
                --if find(0, nsize[1]) > 0 then
                --    wnsize[1] = 0
                --else
                    wnsize[1] = max(nsize[1])
                --end if
            elsif wcprops[wcpSizeModeX][idx] = 2 then --expand
                wmsize[1] = max(msize[1])
                if find(0, nsize[1]) > 0 then
                    wnsize[1] = 0
                else
                    wnsize[1] = max(nsize[1])
                end if
            end if
            if wcprops[wcpSizeModeY][idx] = 0 then    --natural sizes
                --Calculate Y
                wmsize[2] = sum(msize[2])
                --if find(0, nsize[2]) > 0 then
                --    wnsize[2] = 0
                --else
                    wnsize[2] = sum(nsize[2])
                --end if
            elsif wcprops[wcpSizeModeY][idx] = 1 then --largest natural size
                --Calculate Y
                wmsize[2] = max(msize[2]) * length(ch)
                --if find(0, nsize[2]) > 0 then
                --    wnsize[2] = 0
                --else
                    wnsize[2] = max(nsize[2]) * length(ch)
                --end if
            elsif wcprops[wcpSizeModeY][idx] = 2 then --expand
                --Calculate Y
                wmsize[2] = sum(msize[2])
                if find(0, nsize[2]) > 0 then
                    wnsize[2] = 0
                else
                    wnsize[2] = sum(nsize[2])
                end if
            end if
        elsif wcprops[wcpOrientation][idx] = 1 then --horizontal
            if wcprops[wcpSizeModeX][idx] = 0 then    --natural sizes
                --Caluculate X
                wmsize[1] = sum(msize[1])
                if find(0, nsize[1]) > 0 then
                    wnsize[1] = 0
                else
                    wnsize[1] = sum(nsize[1])
                end if
            elsif wcprops[wcpSizeModeX][idx] = 1 then --largest natural size
                --Caluculate X
                wmsize[1] = max(msize[1]) * length(ch)
                if find(0, nsize[1]) > 0 then
                    wnsize[1] = 0
                else
                    wnsize[1] = max(nsize[1]) * length(ch)
                end if
            elsif wcprops[wcpSizeModeX][idx] = 2 then --expand
                --Caluculate X
                wmsize[1] = sum(msize[1])
                if find(0, nsize[1]) > 0 then
                    wnsize[1] = 0
                else
                    wnsize[1] = sum(nsize[1])
                end if
            end if
            if wcprops[wcpSizeModeY][idx] = 0 then    --natural sizes
                --Calculate Y
                wmsize[2] = max(msize[2])
                --if find(0, nsize[2]) > 0 then
                --    wnsize[2] = 0
                --else
                    wnsize[2] = max(nsize[2])
                --end if
            elsif wcprops[wcpSizeModeY][idx] = 1 then --largest natural size
                --Calculate Y
                wmsize[2] = max(msize[2])
                --if find(0, nsize[2]) > 0 then
                --    wnsize[2] = 0
                --else
                    wnsize[2] = max(nsize[2])
                --end if
            elsif wcprops[wcpSizeModeY][idx] = 2 then --expand
                --Calculate Y
                wmsize[2] = max(msize[2])
                if find(0, nsize[2]) > 0 then
                    wnsize[2] = 0
                else
                    wnsize[2] = max(nsize[2])
                end if
            end if

        end if
        
        --Calculate size of groupbox and label
        /*if sequence(wcprops[wcpGroupLabel][idx]) then
            gbsize[1] = txex[1] + thGroupBoxMargin * 2
            gbsize[2] = txex[2] + thGroupBoxMargin * 2
            if wmsize[1] < gbsize[1] then
                wmsize[1] = gbsize[1]
            end if
            if wmsize[2] < gbsize[2] then
                wmsize[2] = gbsize[2]
            end if
            if wnsize[1] > 0 and wnsize[1] < gbsize[1] then
                wnsize[1] = gbsize[1]
            end if
            if wnsize[2] > 0 and wnsize[2] < gbsize[2] then
                wnsize[2] = gbsize[2]
            end if
        end if*/
        
        --Add Margins
        wmsize[1] += wcprops[wcpMargin][idx][1] + wcprops[wcpMargin][idx][3]
        wmsize[2] += wcprops[wcpMargin][idx][2] + wcprops[wcpMargin][idx][4]
        if wnsize[1] > 0 then
            wnsize[1] += wcprops[wcpMargin][idx][1] + wcprops[wcpMargin][idx][3]
        end if
        if wnsize[2] > 0 then
            wnsize[2] += wcprops[wcpMargin][idx][2] + wcprops[wcpMargin][idx][4]
        end if
        
        --Add space between widgets
        if length(ch) > 0 then
            if wcprops[wcpOrientation][idx] = 0 then --vertical
                wmsize[2] += wcprops[wcpSpacing][idx] * (length(ch) - 1)
                if wnsize[2] > 0 then
                    wnsize[2] += wcprops[wcpSpacing][idx] * (length(ch) - 1)
                end if
            else
                wmsize[1] += wcprops[wcpSpacing][idx] * (length(ch) - 1)
                if wnsize[1] > 0 then
                    wnsize[1] += wcprops[wcpSpacing][idx] * (length(ch) - 1)
                end if
            end if
        end if
        
        widget_set_min_size(wid, wmsize[1], wmsize[2])
        widget_set_natural_size(wid, wnsize[1], wnsize[2])
        
        wparent = parent_of(wid)
        if wparent > 0 then
            wc_call_resize(wparent)
        end if
    end if
end procedure


procedure wc_arrange(atom wid)  --arranging affects children and offspring
    atom idx, wh, xs, ys, xp, yp, sp, maxx = 0, maxy = 0, mx, ds
    sequence wch, ch = {}, exp, txex, crect, msize = {}, nsize = {}, dsize = {}, wsize = {}, wpos = {}
    
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        --Calculate Container rectagle
        crect = widget_get_rect(wid)
        
        /*if sequence(wcprops[wcpGroupLabel][idx]) then
            wh = widget_get_handle(wid)
            oswin:set_font(wh, "Arial", 9, Normal)
            txex = oswin:get_text_extent(wh, wcprops[wcpGroupLabel][idx])
            
            crect[1] += thGroupBoxMargin
            crect[2] += thGroupBoxMargin + txex[2]
            crect[3] -= thGroupBoxMargin
            crect[4] -= thGroupBoxMargin
        end if*/
        
        crect[1] += wcprops[wcpMargin][idx][1]
        crect[2] += wcprops[wcpMargin][idx][2]
        crect[3] -= wcprops[wcpMargin][idx][3] 
        crect[4] -= wcprops[wcpMargin][idx][4]
        
        --get list of visible children
        wch = children_of(wid)
        for w = 1 to length(wch) do
            if widget_is_visible(wch[w]) then
                ch &= wch[w]
            end if
        end for
        
        if length(ch) > 0 then
            --build size lists
            for w = 1 to length(ch) do
                msize &= {widget_get_min_size(ch[w])}
                nsize &= {widget_get_natural_size(ch[w])}
                dsize &= {widget_get_default_size(ch[w])}
                wpos &= {{0, 0}}
                wsize &= {{0, 0}}
                mx = max({msize[$][1], nsize[$][1], dsize[$][1]})
                if mx > maxx then
                    maxx = mx
                end if
                mx = max({msize[$][2], nsize[$][2], dsize[$][2]})
                if mx > maxy then
                    maxy = mx
                end if
            end for
            
            --calcululate the space available to distribute among the children
            sp = wcprops[wcpSpacing][idx]
            xs = crect[3] - crect[1]
            ys = crect[4] - crect[2]
            
            if wcprops[wcpOrientation][idx] = 0 then --vertical
                ys -= wcprops[wcpSpacing][idx] * (length(ch) - 1) --subtract the space between the children
            else
                xs -= wcprops[wcpSpacing][idx] * (length(ch) - 1)
            end if
            --calculate children sizes
            if wcprops[wcpSizeModeX][idx] = 0 then    --minimum sizes
                for c = 1 to length(ch) do
                    wsize[c][1] = max({msize[c][1], nsize[c][1], dsize[c][1]})
                end for
                
            elsif wcprops[wcpSizeModeX][idx] = 1 then --largest natural size
                for c = 1 to length(ch) do 
                    wsize[c][1] = maxx
                end for
                
            elsif wcprops[wcpSizeModeX][idx] = 2 then --expand
                if wcprops[wcpOrientation][idx] = 0 then --vertical
                    for c = 1 to length(ch) do
                        if nsize[c][1] = 0 and dsize[c][1] = 0 then
                            mx = xs 
                        else    
                            mx = max({msize[c][1], nsize[c][1], dsize[c][1]})
                            if mx > xs then
                                mx = xs
                            end if
                        end if
                        wsize[c][1] = mx
                    end for
                else                                --horizontal
                    exp = {} --first, find space taken up by widgets that can't expand
                    for c = 1 to length(ch) do
                        if nsize[c][1] = 0 and dsize[c][1] = 0 then
                            exp &= c --add to list of expandible widgets
                        else
                            mx = max({msize[c][1], nsize[c][1], dsize[c][1]})
                            wsize[c][1] = mx --widget cannot expand, so go ahead and "lock-in" it's size
                            xs -= mx --widget uses up some availible space
                        end if
                    end for
                    /*
                    if length(exp) > 0 then
                        ds = floor(xs / length(exp)) -- - sp * length(exp)
                        for e = 1 to length(exp) do --now, divide the remaining space to expandable widgets
                            wsize[exp[e]][1] = ds
                        end for
                    end if
                    */
                    if length(exp) > 0 then
                        for e = 1 to length(exp) do --now, divide the remaining space to expandable widgets
                            ds = floor(xs / (length(exp) - e + 1)) --improved formula
                            wsize[exp[e]][1] = ds
                            xs -= ds
                        end for
                    end if
                end if
            end if
            
            if wcprops[wcpSizeModeY][idx] = 0 then    --minimum sizes
                for c = 1 to length(ch) do 
                    wsize[c][2] = max({msize[c][2], nsize[c][2], dsize[c][2]})  --msize[c][2] --just assign minimum size
                end for
                
            elsif wcprops[wcpSizeModeY][idx] = 1 then --largest natural size
                for c = 1 to length(ch) do
                    wsize[c][2] = maxy --assign maximum natural size
                end for
                
            elsif wcprops[wcpSizeModeY][idx] = 2 then --expand
                if wcprops[wcpOrientation][idx] = 1 then --horizontal
                    for c = 1 to length(ch) do
                        if nsize[c][2] = 0 and dsize[c][2] = 0 then
                            mx = ys 
                        else    
                            mx = max({msize[c][2], nsize[c][2], dsize[c][2]})
                            if mx > ys then
                                mx = ys
                            end if
                        end if
                        wsize[c][2] = mx
                    end for
                else
                    exp = {} --first, find space taken up by widgets that can't expand
                    for c = 1 to length(ch) do
                        if nsize[c][2] = 0 and dsize[c][2] = 0 then
                            exp &= c --add to list of expandible widgets
                        else
                            mx = max({msize[c][2], nsize[c][2], dsize[c][2]})
                            wsize[c][2] = mx --widget cannot expand, so go ahead and "lock-in" it's size
                            ys -= mx --widget uses up some availible space
                        end if
                    end for
                    if length(exp) > 0 then
                        for e = 1 to length(exp) do --now, divide the remaining space to expandable widgets
                            ds = floor(ys / (length(exp) - e + 1))
                            wsize[exp[e]][2] = ds
                            ys -= ds
                        end for
                    end if
                end if
            end if
            
            --calculate children positions
            xp = crect[1]
            yp = crect[2]
            if wcprops[wcpOrientation][idx] = 0 then --vertical
                for c = 1 to length(ch) do 
                    wpos[c] = {xp, yp}
                    yp += wsize[c][2] + sp
                end for
            elsif wcprops[wcpOrientation][idx] = 1 then --horizontal
                for c = 1 to length(ch) do 
                    wpos[c] = {xp, yp}
                    xp += wsize[c][1] + sp
                end for
            end if
            
            --shift over for center or right justification
            xp -= sp
            yp -= sp
            if wcprops[wcpJustifyX][idx] = 1 then --center
                xs = floor((crect[3] - xp) / 2) --calculate the extra space, divide by 2 to center
                for c = 1 to length(ch) do 
                    wpos[c][1] += xs
                end for
            elsif wcprops[wcpJustifyX][idx] = 2 then --right
                xs = crect[3] - xp --calculate the extra space
                for c = 1 to length(ch) do 
                    wpos[c][1] += xs
                end for
            end if
            if wcprops[wcpJustifyY][idx] = 1 then --middle
                ys = floor((crect[4] - yp) / 2) --calculate the extra space, divide by 2 to center
                for c = 1 to length(ch) do 
                    wpos[c][2] += ys
                end for
            elsif wcprops[wcpJustifyY][idx] = 2 then --bottom
                ys = crect[4] - yp --calculate the extra space
                for c = 1 to length(ch) do 
                    wpos[c][2] += ys
                end for
            end if
            
            --apply widget positions and Actual sizes
            for c = 1 to length(ch) do
                widget_set_pos(ch[c], wpos[c][1], wpos[c][2])
                widget_set_size(ch[c], wsize[c][1], wsize[c][2])
            end for
        end if
        
        wc_call_draw(wid)
        
        for c = 1 to length(ch) do
            wc_call_arrange(ch[c])
        end for
    end if
end procedure


function wc_debug(atom wid)
    atom idx
    sequence debuginfo = {}
    
    idx = find(wid, wcprops[wcpID])
    if idx > 0 then
        debuginfo = {
            {"SoftFocus", wcprops[wcpSoftFocus][idx]},
            {"HardFocus", wcprops[wcpHardFocus][idx]},
            {"Orientation", wcprops[wcpOrientation][idx]},
            {"SizeModeX", wcprops[wcpSizeModeX ][idx]},
            {"SizeModeY", wcprops[wcpSizeModeY ][idx]},
            
            {"JustifyX", wcprops[wcpJustifyX][idx]},
            {"JustifyY", wcprops[wcpJustifyY][idx]},
            {"Adjust", wcprops[wcpAdjust][idx]},
            {"BoxAlign", wcprops[wcpBoxAlign][idx]},
            {"GroupLabel", wcprops[wcpGroupLabel][idx]},
            {"Margin", wcprops[wcpMargin][idx]},
            {"Spacing", wcprops[wcpSpacing ][idx]}
        }
    end if
    return debuginfo
end function



wc_define(
    "toolbar",
    routine_id("wc_create"),
    routine_id("wc_destroy"),
    routine_id("wc_draw"),
    routine_id("wc_event"),
    routine_id("wc_resize"),
    routine_id("wc_arrange"),
    routine_id("wc_debug")
)   
    

-- widgetclass commands -------------------------------------------------------

procedure cmd_set_props(atom wid, object wprops) 
    atom idx
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        for p = 1 to length(wprops) do
            if length(wprops[p]) = 2 then
                switch wprops[p][1] do          
                    case "orientation" then
                        wcprops[wcpOrientation][idx] = wprops[p][2]
                        
                    case "sizemode_x" then
                        wcprops[wcpSizeModeX][idx] = wprops[p][2]
                        
                    case "sizemode_y" then
                        wcprops[wcpSizeModeY][idx] = wprops[p][2]
                        
                end switch
            end if
        end for
        
        wc_call_arrange(wid)
        wc_call_draw(wid)
    end if
end procedure
wc_define_command("toolbar", "set_toolbar_props", routine_id("cmd_set_props"))



function cmd_get_box_width(atom wid) 
    atom idx, bw = 0
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 and wcprops[wcpBoxAlign][idx] = 1 and length(wcprops[wcpBoxWidth][idx][2]) > 0 then
        bw = max(wcprops[wcpBoxWidth][idx][2])
    end if
    
    return bw
end function
wc_define_function("toolbar", "get_box_width", routine_id("cmd_get_box_width"))



function cmd_get_orientation(atom wid) 
    atom idx, worient = 0
    idx = find(wid, wcprops[wcpID])
    
    if idx > 0 then
        worient = wcprops[wcpOrientation][idx]
    end if
    
    return worient
end function
wc_define_function("toolbar", "get_orientation", routine_id("cmd_get_orientation"))

