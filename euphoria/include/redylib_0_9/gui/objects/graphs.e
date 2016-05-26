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


--This library lets you create multiple graphs on the same canvas or on multiple canvases without taking complete
--control over the canvas. You can create a graph, set options, add data, and then display in in any existing canvas
--widget at specific coordinates inside the canvas. By calling the graph:event() procedure from the canvas's event
--handler, the graphs inside the canvas can respond to canvas resizing or user input.


include redylib_0_9/gui.e as gui

include std/sequence.e
include std/search.e
include std/pretty.e
include std/text.e
include std/stack.e
include std/math.e
include std/search.e
include std/convert.e

enum
grName, --name of graph
grWidget, --widget
grEventHandler, --event handler
grRect, --rect

grOptXRange, --{min, max}
grOptYRange, --{min, max}
grOptXGrid, --xgrid
grOptYGrid, --ygrid
grOptGridColor, --gridcolor
grOptBackColor, --background color
grOptBorderColor, --border color
grPlots --list of plots to display on graph
constant
grLENGTH = grPlots
sequence graphs = repeat({}, grLENGTH)

enum
plName,
plLabel,
plDataX,
plDataY,
plColor,
plStyle  --0=line, 1=fill below, 1=fill above, 2=fill left, 3=fill right
 
constant
plLENGTH = plStyle


constant ctable = {  --color table, just to make it easy to give each plot a unique default color
   rgb(#FF, #3C, #00),
   rgb(#FF, #7B, #00),
   rgb(#FF, #BB, #00),
   rgb(#FF, #FB, #00),
   rgb(#C3, #FF, #00),
   rgb(#04, #FF, #00),
   rgb(#00, #FF, #BB),
   rgb(#00, #FF, #FB),
   rgb(#00, #C4, #FF),
   rgb(#00, #84, #FF)
}

function pick_color(atom idx) --pick a color from the color table
    atom len = length(ctable)
    while idx > len do  --wrap around if idx > length(ctable)
        idx -= len
    end while
    return ctable[idx]
end function



procedure draw_graph(atom idx, atom dmode) --process data and redraw graph 

    --temp draw test
    sequence cmds, dcmds, hcmds, pllabel, pldatax, pldatay, pts,
    rect = graphs[grRect][idx],
    grdata = graphs[grPlots][idx]
    object 
    xrange = graphs[grOptXRange][idx],
    yrange = graphs[grOptYRange][idx]
    atom
    xgrid = graphs[grOptXGrid][idx],
    ygrid = graphs[grOptYGrid][idx],
    gridcolor = graphs[grOptGridColor][idx],
    cidx = 1, dcolor, xp, yp
    atom plcolor, plstyle, xmin, xmax, ymin, ymax, xs, ys
    
    --gui:wproc(graphs[grWidget][idx], "draw_foreground", {{}})
    
    --draw background:
    cmds = {
        {DR_PenColor, graphs[grOptBackColor][idx]},
        {DR_Rectangle, True, rect[1], rect[2], rect[3], rect[4]}
    }
    
    --draw grid:
    
    
    --draw data sets:
    for p = 1 to length(graphs[grPlots][idx][plName]) do
        pldatax = graphs[grPlots][idx][plDataX][p]
        pldatay = graphs[grPlots][idx][plDataY][p]
        plcolor = graphs[grPlots][idx][plColor][p]
        plstyle = graphs[grPlots][idx][plStyle][p]
        
        if length(pldatay) > 0 then
            if atom(xrange) then --automatically set the X range
                if length(pldatax) = length(pldatay) then
                    xmin = min(pldatax)
                    xmax = max(pldatax)                                        
                else  --when no x data is provided, set x range to the number of y data points
                    xmin = 0
                    xmax = length(pldatay) - 1
                end if
            else
                xmin = graphs[grOptXRange][idx][1]
                xmax = graphs[grOptXRange][idx][2]
            end if
            if atom(yrange) then --automatically set the Y range
                ymin = min(pldatay)
                ymax = max(pldatay)
                ymin -= (rect[4] - rect[2]-1) / (ymax - ymin)
                ymax += (rect[4] - rect[2]-1) / (ymax - ymin)                
            else
                ymin = graphs[grOptYRange][idx][1]
                ymax = graphs[grOptYRange][idx][2]
            end if
            xs = (rect[3] - rect[1]) / (xmax - xmin)
            ys = (rect[4] - rect[2]) / (ymax - ymin)
            
            --Plot points in specified style:
            if plstyle = 0 then --line
                cmds &= {{DR_PenColor, plcolor}}
                pts = repeat({0, 0}, length(pldatay))
                if length(pldatax) = length(pldatay) then
                    for d = 1 to length(pldatay) do    
                        xp = rect[1] + floor(xmax - pldatax[d] * xs)
                        yp = rect[2] + floor(ymax - pldatay[d] * ys)
                        pts[d] = {xp, yp}
                    end for
                else  --when no x data is provided (or doesn't match y data), automatically increment xpos
                    xp = rect[1]
                    for d = 1 to length(pldatay) do    
                        yp = rect[2] + floor(pldatay[d] * ys)
                        pts[d] = {floor(xp), yp}
                        xp += xs
                    end for
                end if
                cmds &= {{DR_PolyLine, False, pts}}
                
            elsif plstyle = 1 then --fill below
                cmds &= {
                    {DR_PenColor, plcolor},
                    {DR_BrushColor, plcolor}
                }
                pts = repeat({0, 0}, length(pldatay))
                if length(pldatax) = length(pldatay) then
                    for d = 1 to length(pldatay) do    
                        xp = rect[1] + floor(pldatax[d] * xs)
                        yp = rect[2] + floor(pldatay[d] * ys)
                        pts[d] = {xp, yp}
                    end for
                    pts &= {
                        {rect[3], rect[4]},
                        {rect[1], rect[4]},
                        {rect[1] + floor(pldatax[1] * xs), rect[2] + floor(pldatay[1] * ys)}
                    }
                else  --when no x data is provided (or doesn't match y data), automatically increment xpos
                    xp = rect[1]
                    for d = 1 to length(pldatay) do    
                        yp = rect[2] + floor(pldatay[d] * ys)
                        pts[d] = {floor(xp), yp}
                        xp += xs
                    end for
                    pts &= {
                        {rect[3], rect[4]},
                        {rect[1], rect[4]},
                        {rect[1], rect[2] + floor(pldatay[1] * ys)}
                    }
                end if
                cmds &= {{DR_PolyLine, True, pts}}
                
            elsif plstyle = 2 then --fill above
            elsif plstyle = 3 then --fill left
            elsif plstyle = 4 then --fill right
            end if
            
            
            
            /*
                cmds &= {
                    {DR_PenColor, plcolor},
                    {DR_BrushColor, plcolor}
                }                                    
                atom lx, ly
                                                
                if length(pldatax) = length(pldatay) then
                    lx = rect[1] + floor(pldatax[1] * xs)
                    ly = rect[2] + floor(pldatay[1] * ys)
                    for d = 2 to length(pldatay) do    
                        xp = rect[1] + floor(pldatax[d] * xs)
                        yp = rect[2] + floor(pldatay[d] * ys)
                        cmds &= {{DR_PolyLine, True, {
                            {lx, rect[4]},
                            {lx, ly},
                            {xp, yp},
                            {xp, rect[4]},
                            {lx, rect[4]}                            
                        }}}
                    end for
                else  --when no x data is provided (or doesn't match y data), automatically increment xpos
                    lx = rect[1]
                    ly = rect[1] + floor(pldatay[1] * ys)
                    xp = rect[1] + xs
                    for d = 2 to length(pldatay) do    
                        yp = rect[2] + floor(pldatay[d] * ys)
                        cmds &= {{DR_PolyLine, True, {
                            {lx, rect[4]},
                            {lx, ly},
                            {xp, yp},
                            {xp, rect[4]},
                            {lx, rect[4]}
                        }}}
                        xp += xs
                    end for
                end if
            
            
            -- old
            for s = 1 to length(pldatay) do    
                cmds &= {{DR_PenColor, plcolor}}
                dcmds = repeat({}, length(grdata[s]))
                
                if graphs[grOptType][idx] = 0 then --not sure what to call this graph type
                    for d = 1 to length(grdata[s]) do
                        xp = rect[1] + floor(grdata[s][d][1] * xs)
                        yp = rect[2] + floor(grdata[s][d][2] * ys)
                        dcmds[d] = {DR_Line, xp, yp, xp, rect[4]}
                    end for
                elsif graphs[grOptType][idx] = 0 then --another graph type, not sure what to call it
                end if    
                cmds &= dcmds
                
                cidx += 1 --cycle through DataColors for each data set
                if cidx > length(graphs[grOptDataColors][idx]) then
                    cidx = 1
                end if
            end for*/
        end if
    end for
    
    --draw border:
    cmds &= {
        {DR_PenColor, graphs[grOptBorderColor][idx]},
        {DR_Rectangle, False, rect[1], rect[2], rect[3]+1, rect[4]+1}
    }
    
    --draw handle:
    hcmds = {
        {DR_Rectangle, True, rect[1], rect[2], rect[3]+1, rect[4]+1}
    }
    
    --{DR_TextColor, currStyle[sTextcolor]}
    --{DR_Font, currStyle[sFont], currStyle[sFontsize], or_all({currStyle[sBold], currStyle[sItalics], currStyle[sUnderline]})}
    --{DR_PenPos, cx - txex[1], cy},
    --{DR_Puts, " "}
    
    --if dmode = 1 then
    gui:wproc(graphs[grWidget][idx], "draw_background", {cmds})
    --else
    --    gui:wproc(graphs[grWidget][idx], "draw_foreground", {cmds})
    --end if
    gui:wproc(graphs[grWidget][idx], "set_handle", {"graph." & graphs[grName][idx], hcmds, "Crosshair"})
end procedure


export procedure create(sequence grname, sequence grcanvas, atom greventrid)
    atom idx
    idx = find(grname, graphs[grName])
    
    if idx = 0 then
        graphs[grName] &= {grname}
        graphs[grWidget] &= {grcanvas}
        graphs[grEventHandler] &= {greventrid}
        graphs[grRect] &= {{0, 0, 10, 10}}
        graphs[grOptXRange] &= {0}
        graphs[grOptYRange] &= {0}
        graphs[grOptXGrid] &= {0}
        graphs[grOptYGrid] &= {0}
        graphs[grOptGridColor] &= {rgb(105, 105, 115)}
        graphs[grOptBackColor] &= {rgb(100, 100, 110)}
        graphs[grOptBorderColor] &= {rgb(240, 240, 240)}
        graphs[grPlots] &= {repeat({}, plLENGTH)}
    end if
end procedure


export procedure destroy(sequence grname)
    atom idx
    idx = find(grname, graphs[grName])
    
    if idx > 0 then
        for p = 1 to grLENGTH do
            graphs[p] = remove(graphs[p], idx)
        end for
    end if
end procedure


export procedure set_options(sequence grname, sequence groptions = {})
    atom idx
    idx = find(grname, graphs[grName])
    
    if idx > 0 then
        for opt = 1 to length(groptions) do
            if length(groptions[opt]) = 2 then
                switch groptions[opt][1] do
                    case "x_range" then
                        graphs[grOptXRange][idx] = groptions[opt][2]
                    case "y_range" then
                        graphs[grOptYRange][idx] = groptions[opt][2]
                    case "x_grid" then
                        graphs[grOptXGrid][idx] = groptions[opt][2]
                    case "y_crid" then
                        graphs[grOptYGrid][idx] = groptions[opt][2]
                    case "grid_color" then
                        graphs[grOptGridColor][idx] = groptions[opt][2]
                    case "back_color" then
                        graphs[grOptBackColor][idx] = groptions[opt][2]
                    case "border_color" then
                        graphs[grOptBorderColor][idx] = groptions[opt][2]
                end switch
            end if
        end for
        
        if gui:wexists(graphs[grWidget][idx]) then
            draw_graph(idx, 1)
        end if
    end if
end procedure


export procedure display(sequence grname, sequence grrect, object groptions = {})
    atom idx
    idx = find(grname, graphs[grName])
    
    if idx > 0 then
        graphs[grRect][idx] = grrect
        set_options(grname, groptions)
        if gui:wexists(graphs[grWidget][idx]) then
            draw_graph(idx, 1)
        end if
    end if
end procedure


export procedure create_plot(sequence grname, sequence plname, sequence pllabel = "", atom plstyle = 0, object plcolor = {0})
    atom idx, pidx
    idx = find(grname, graphs[grName])
    
    if idx > 0 then
        pidx = find(plname, graphs[grPlots][idx][plName])
        if sequence(plcolor) then
            if length(plcolor) = 1 and integer(plcolor[1]) and plcolor[1] > 0 then
                plcolor = pick_color(plcolor)
            else
                plcolor = pick_color(length(graphs[grPlots][idx][plName]) + 1)
            end if
        end if
        if pidx = 0 then
            graphs[grPlots][idx][plName] &= {plname}
            graphs[grPlots][idx][plLabel] &= {pllabel}
            graphs[grPlots][idx][plDataX] &= {{}}
            graphs[grPlots][idx][plDataY] &= {{}}
            graphs[grPlots][idx][plColor] &= {plcolor}
            graphs[grPlots][idx][plStyle] &= {plstyle}
        else
            graphs[grPlots][idx][plName][pidx] = plname
            graphs[grPlots][idx][plLabel][pidx] = pllabel
            graphs[grPlots][idx][plColor][pidx] = plcolor
            graphs[grPlots][idx][plStyle][pidx] = plstyle
            if gui:wexists(graphs[grWidget][idx]) then
                draw_graph(idx, 1)
            end if
        end if
    end if
end procedure


export procedure stream_plot_data(sequence grname, sequence plname, sequence pldatax, sequence pldatay)
    atom idx, pidx
    idx = find(grname, graphs[grName])
    
    if idx > 0 then
        pidx = find(plname, graphs[grPlots][idx][plName])
        if pidx > 0 then
            graphs[grPlots][idx][plDataX][pidx] = pldatax
            graphs[grPlots][idx][plDataY][pidx] = pldatay
            if gui:wexists(graphs[grWidget][idx]) then
                draw_graph(idx, 2)
            end if
        end if
    end if
end procedure


export procedure set_plot_data(sequence grname, sequence plname, sequence pldatax, sequence pldatay)
    atom idx, pidx
    idx = find(grname, graphs[grName])
    
    if idx > 0 then
        pidx = find(plname, graphs[grPlots][idx][plName])
        if pidx > 0 then
            graphs[grPlots][idx][plDataX][pidx] = pldatax
            graphs[grPlots][idx][plDataY][pidx] = pldatay
            if gui:wexists(graphs[grWidget][idx]) then
                draw_graph(idx, 1)
            end if
        end if
    end if
end procedure


export procedure destroy_plot(sequence grname, sequence plname)
    atom idx, pidx
    idx = find(grname, graphs[grName])
    
    if idx > 0 then
        pidx = find(plname, graphs[grPlots][idx][plName])
        if pidx > 0 then
            for p = 1 to plLENGTH do
                graphs[grPlots][idx][p] = remove(graphs[grPlots][idx][p], idx)
            end for
            if gui:wexists(graphs[grWidget][idx]) then
                draw_graph(idx, 1)
            end if
        end if
    end if
end procedure


export procedure clear_plots(sequence grname)
    atom idx
    idx = find(grname, graphs[grName])
    
    if idx > 0 then
        graphs[grPlots][idx] = {}
        if gui:wexists(graphs[grWidget][idx]) then
            draw_graph(idx, 1)
        end if
    end if
end procedure


export procedure event(object evwidget, object evtype, object evdata) --call this from the canvas's event handler
    --pretty_print(1, {"event", evwidget, evtype, evdata}, {2})
    sequence gr = find_all(evwidget, graphs[grWidget]) --find any graphs attached to this canvas, call graph event handler
    
    if length(gr) > 0 then
        sequence cmds = {}, grsize = gui:wfunc(evwidget, "get_canvas_size", {}), grect
        switch evtype do
            case "resized" then
                for i = 1 to length(gr) do
                    call_proc(graphs[grEventHandler][gr[i]], {graphs[grName][gr[i]], "resized", evdata})
                end for
            case "handle" then  --evdata = {"HandleName", "EventType", data1, data2})
                for i = 1 to length(gr) do
                    call_proc(graphs[grEventHandler][gr[i]], {graphs[grName][gr[i]], "handle", evdata})
                    if equal(evdata[2], "MouseMove") then --evdata = {"handle", {hname, "MouseMove", mx, my}}
                        grect = graphs[grRect][gr[i]]
                        if gui:in_rect(evdata[3], evdata[4], grect) then --in_rect(atom xpos, atom ypos, sequence rect)
                            cmds &= {
                                {DR_PenColor, rgb(255, 127, 127)},
                                {DR_Line, grect[1], evdata[4], grect[3], evdata[4]},
                                {DR_Line, evdata[3], grect[2], evdata[3], grect[4]}
                            }
                        end if
                    end if
                end for
                gui:wproc(evwidget, "draw_foreground", {cmds})
            case "destroyed" then
                for i = 1 to length(gr) do
                    call_proc(graphs[grEventHandler][gr[i]], {graphs[grName][gr[i]], "handle", evdata})
                end for
        end switch
    end if
end procedure


