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
--
-- This library lets you create calendars on canvas widgets. By calling the
-- cal:event() procedure from the canvas's event handler, the calendar inside
-- the canvas can respond to canvas resizing or user input.

include redylib_0_9/gui.e as gui

include std/search.e
include std/pretty.e
include std/text.e
include std/stack.e
include std/math.e
include std/search.e
include std/task.e
include std/utils.e
include std/sequence.e as seq
include std/error.e
include std/datetime.e as dt
include std/convert.e


enum
cName,          --name of calendar
cRect,          --rectangle of calendar area
cSelectedDate,  --selected date
cSelectedDay,   --day index of selected date
cDayDates,      --list of dates of each day on the calendar
cDayStrings,    --list of string names of each day on the calendar with the format "YYYY-MM-DD"
cDayRects,      --list of rectancles representing the coordinates of each day on the calendar
cDrawCmds,      --rendered commands to draw calendar to canvas background
cHandleCmds     --rendered commands to generate day handles on canvas

constant cLENGTH = cHandleCmds

sequence cals = repeat({}, cLENGTH)


constant
DAYLABEL = rgb(200, 210, 255),
DAYLABEL2 = rgb(230, 240, 255),
DK_GREY = rgb(190, 190, 210),
LT_GREY = rgb(150, 150, 145),
RED = rgb(255, 50, 50),
YELLOW = rgb(255, 255, 0),
GREEN = rgb(0, 255, 50),
BLUE = rgb(50, 150, 255),
BLUEGREEN = rgb(50, 225, 255),
ORANGE = rgb(250, 100, 50),
LT_ORANGE = rgb(255, 180, 50), 
PINK = rgb(255, 0, 240),

HIGHL =  rgb(255, 255, 10),
BOXFILL1 = rgb(220, 216, 208), --rgb(240, 240, 240),
BOXFILL2 = rgb(230, 230, 230),
BOXBORDER = rgb(120, 120, 120),

BTNFILL = rgb(210, 210, 220),
BTNHOVER = rgb(200, 200, 10),
BTNBORDER = rgb(80, 80, 100),
BTNTEXT = rgb(10, 10, 50),

TEXT1 = rgb(0, 10, 110),
TEXT2 = rgb(10, 50, 10),
TEXT3 = rgb(20, 140, 0),
TEXT4 = rgb(10, 10, 10),

PLOT_BK1 = rgb(150, 150, 150),
PLOT_BK2 = rgb(180, 180, 180),
PLOT_BK3 = rgb(210, 210, 210),

statusGreen  = rgb(210, 255, 210),
statusYellow = rgb(255, 255, 210),
statusRed    = rgb(255, 210, 210),
statusGrey   = rgb(210, 210, 210)


export function exists(sequence calname)
    atom idx = find(calname, cals[cName])
    if idx > 0 then
        return 1
    else
        return 0
    end if
end function


export procedure create(sequence calname, object caldate = 0)
--create a calendar instance. If caldate = 0, assume dt:now() 
    
    atom idx = find(calname, cals[cName])
    if idx = 0 then
        cals[cName] &= {calname}
        cals[cRect] &= {0}
        cals[cSelectedDate] &= {{0, 0, 0, 0, 0, 0}}
        cals[cSelectedDay] &= {0}
        cals[cDayDates] &= {{}}
        cals[cDayStrings] &= {{}}
        cals[cDayRects] &= {{}}
        cals[cDrawCmds] &= {0}
        cals[cHandleCmds] &= {0}
        
        nav_date(calname, caldate) 
    end if
end procedure


export procedure destroy(sequence calname)
    atom idx = find(calname, cals[cName])
    if idx > 0 then
        for p = 1 to cLENGTH do
            cals[p] = remove(cals[p], idx)
        end for
    end if 
end procedure


export procedure nav_date(sequence calname, object navto)
--navigate calendar to a different date
    
    atom idx = find(calname, cals[cName])
    if idx > 0 then
        atom weekday, daypos
        sequence firstday, lastday, daydate, navdate, currdate
        currdate = cals[cSelectedDate][idx]
        
        if atom(navto) then
            if navto = -30 then
                navdate = dt:subtract(currdate, 1, MONTHS)
            elsif navto = 30 then
                navdate = dt:add(currdate, 1, MONTHS)
            elsif navto = -7 then
                navdate = dt:subtract(currdate, 1, WEEKS)
            elsif navto = 7 then
                navdate = dt:add(currdate, 1, WEEKS)
            elsif navto = -1 then
                navdate = dt:subtract(currdate, 1, DAYS)
            elsif navto = 1 then
                navdate = dt:add(currdate, 1, DAYS)
            else
                navdate = dt:now()
            end if
        else
            navdate = navto    
        end if
        navdate = navdate[1..3] & {0, 0, 0}
        
        if navdate[2] != currdate[2] then  --if navdate month != prevmonth then rebuild dates
            weekday = dt:weeks_day({navdate[1], navdate[2], 1, 0,0,0}) --get weekday of first day of current month
            if weekday < 5 then
                daypos = 6 + weekday
            else
                daypos = weekday - 1
            end if
            firstday = dt:subtract({navdate[1], navdate[2], 1, 0,0,0}, daypos, DAYS)
            
            --lastday = dt:add(firstday, 7*6, DAYS) 
            
            --cals[cSelectedDate][idx] = navdate      
            --plotStartDate = firstday
            
            --plotCurrDay = daypos + plotCurrDate[3]  
            --prevweek = weekStartIndex
            --weekStartIndex = plotCurrDay - dt:weeks_day(navdate) + 1
            
            daydate = firstday
            cals[cDayDates][idx] = {}
            cals[cDayStrings][idx] = {}
            for di = 1 to 42 do
                cals[cDayDates][idx] &= {daydate}
                cals[cDayStrings][idx] &= {dt:format(daydate, "%Y-%m-%d")}
                if equal(daydate, navdate) then
                    cals[cSelectedDay][idx] = di
                end if
                
                daydate = dt:add(daydate, 1, DAYS)
            end for
            
            cals[cSelectedDate][idx] = navdate
            cals[cDrawCmds][idx] = 0
            cals[cHandleCmds][idx] = 0
        end if
    end if
end procedure


export procedure draw_month(sequence calname, sequence canvasname, object calrect = 0) --, atom createhandles = 0)
--Draws a month calendar containing the day of <caldate> on <canvaswid> within the demensions of <calrect>.
--If caldate = 0, today's date is assumed. If calrect = 0, the full canvas rect is assumed.
    
    if not gui:wexists(canvasname) then
        return
    end if
    atom idx = find(calname, cals[cName])
    if idx = 0 then
        return
    end if
    
    sequence today, csize, calmonth, calyear, dayrects = {}
    sequence trect, txex, crect, dcmds = {}
    atom cw, ch, xp, yp, di, wh
    
    --draw graphics
    if atom(calrect) then
        csize = gui:wfunc(canvasname, "get_canvas_size", {})
        calrect = {0, 0, csize[1], csize[2]}
    end if
    
    if equal(calrect, cals[cRect][idx]) and sequence(cals[cDrawCmds][idx]) then  --rect hasn't changed, and cmds already rendered
        dcmds = cals[cDrawCmds][idx]
        
    else    --re-render calendar
        today = dt:now()  --dt:format(dt:now(), "%Y-%m-%d")
        today = today[1..3] & {0, 0, 0}
        
        trect = {calrect[1] + 4, calrect[2] + 4, calrect[3]-4, calrect[2] + 43} --title area 
        crect = {calrect[1] + 4, calrect[2] + 47, calrect[3]-4, calrect[4]-4}   --calendar area
        
        cw = (crect[3] - crect[1] - 1) / 7  
        ch = (crect[4] - crect[2] - 1) / 6
        
        calmonth = dt:month_names[cals[cSelectedDate][idx][2]]
        calyear = sprint(cals[cSelectedDate][idx][1])
        --center Month Year text:
        wh = widget_get_handle(canvasname)
        gui:set_font(wh, "Arial", 14, Bold)
        txex = gui:get_text_extent(wh, calmonth & " " & calyear)
        
        --Calendar
        dcmds &= {
            {DR_PenColor, BOXFILL1},
            --{DR_Rectangle, True, trect[1], trect[2], trect[3], trect[4]},
            {DR_Rectangle, True, calrect[1], calrect[2], calrect[3], calrect[4]},
            
            --{DR_PenColor, BOXBORDER},
            --{DR_Rectangle, False, crect[1]-4, crect[2]-47, crect[3]+4, crect[4]+4},
            
            {DR_TextColor, TEXT1},
            {DR_Font, "Arial", 14, Bold},
            
            --{DR_PenPos, crect[1] + 5, crect[2] - 40},
            {DR_PenPos, floor((calrect[3] - calrect[1]) / 2 - txex[1] / 2), crect[2] - 40},
            {DR_Puts, calmonth & " " & calyear},
            
            {DR_TextColor, TEXT4},
            {DR_Font, "Arial", 10, Bold},
            
            {DR_PenPos, crect[1] + cw * 1 / 2 - 12, crect[2] - 16},
            {DR_Puts, dt:day_abbrs[1]},  --"Sun"},
            
            {DR_PenPos, crect[1] + cw * 3 / 2 - 12, crect[2] - 16},
            {DR_Puts, dt:day_abbrs[2]},  --"Mon"},
            
            {DR_PenPos, crect[1] + cw * 5 / 2 - 12, crect[2] - 16},
            {DR_Puts, dt:day_abbrs[3]},  --"Tue"},
            
            {DR_PenPos, crect[1] + cw * 7 / 2 - 12, crect[2] - 16},
            {DR_Puts, dt:day_abbrs[4]},  --"Wed"},
            
            {DR_PenPos, crect[1] + cw * 9 / 2 - 12, crect[2] - 16},
            {DR_Puts, dt:day_abbrs[5]},  --"Thu"},
            
            {DR_PenPos, crect[1] + cw * 11 / 2 - 12, crect[2] - 16},
            {DR_Puts, dt:day_abbrs[6]},  --"Fri"},
            
            {DR_PenPos, crect[1] + cw * 13 / 2 - 12, crect[2] - 16},
            {DR_Puts, dt:day_abbrs[7]}   --"Sat"}
        }
        
        xp = crect[1]
        yp = crect[2]
        
        dcmds &= {
            {DR_PenColor, rgb(100, 100, 100)}
        }
        
        for x = 1 to 8 do
            dcmds &= {
                {DR_Line, floor(xp+0.5), crect[2], floor(xp+0.5), crect[4]}
            }
            xp += cw
        end for
        
        dcmds &= {
            {DR_PenColor, rgb(100, 100, 100)}
        }
        
        for y = 1 to 7 do
            dcmds &= {
                {DR_Line, crect[1], floor(yp+0.5), crect[3], floor(yp+0.5)}
            }    
            yp += ch
        end for
        
        xp = crect[1]
        yp = crect[2]
        di = 1              
        
        dcmds &= {
            {DR_PenColor, LT_GREY},
            {DR_TextColor, rgb(60, 60, 60)},
            {DR_Font, "Arial", 9, Bold}
        }
        for y = 1 to 6 do 
            for x = 1 to 7 do
                if cals[cDayDates][idx][di][2] = cals[cSelectedDate][idx][2] then
                    if equal(cals[cDayDates][idx][di], today) then  --cals[cSelectedDay][idx] then
                        dcmds &= {
                            {DR_PenColor, rgb(240, 240, 200)},
                            {DR_Rectangle, True, xp+2, yp+2, xp+cw, yp+ch}
                            --{DR_PenColor, LT_GREY}
                        }
                    else
                        dcmds &= {
                            {DR_PenColor, BOXFILL2},
                            {DR_Rectangle, True, xp+2, yp+2, xp+cw, yp+ch}
                            --{DR_PenColor, LT_GREY}
                        }
                    end if
                end if
                dcmds &= {
                    --{DR_Rectangle, True, floor(xp+3.5), floor(yp+15.5), floor(xp+cw-1.5), floor(yp+ch-1.5)},
                    {DR_PenPos, floor(xp+3.5), floor(yp+1.5)}
                }
                if cals[cDayDates][idx][di][3] = 1 then 
                    dcmds &= {
                        {DR_Puts, dt:month_abbrs[cals[cDayDates][idx][di][2]] & " " & sprint(cals[cDayDates][idx][di][3])}
                    }
                else
                    dcmds &= {
                        {DR_Puts, sprint(cals[cDayDates][idx][di][3])}
                    }
                end if                   
                dayrects &= {{floor(xp+3.5), floor(yp+15.5), floor(xp+cw-1.5), floor(yp+ch-1.5)}} 
                
                xp += cw
                di += 1
            end for
            xp = crect[1]
            yp += ch
        end for
        
        --cals[cSelectedDate][idx] = caldate
        --cals[cStartDate][idx] = startdate
        --cals[cHandleCmds][idx] = hcmds
        cals[cDrawCmds][idx] = dcmds 
        cals[cRect][idx] = calrect
        cals[cDayRects][idx] = dayrects
    end if
    
    gui:wproc(canvasname, "draw_background", {dcmds})
end procedure


export function day_rects(sequence calname)
--Return a list of rectancles representing the coordinates of each day on the calendar
    
    sequence dayrects = {}
    atom idx = find(calname, cals[cName])
    if idx > 0 then
        dayrects = cals[cDayRects][idx]
    end if
    
    return dayrects
end function


export function selected_date(sequence calname)
--Return a list of rectancles representing the coordinates of each day on the calendar
    
    sequence dayrects = {}
    atom idx = find(calname, cals[cName])
    if idx > 0 then
        dayrects = cals[cSelectedDate][idx]
    end if
    
    return dayrects
end function


export function selected_day_string(sequence calname)
--Return a string name of each day on the calendar with the format "YYYY-MM-DD".
--This is useful for using in combination with day_rects() to generate handles or other
--objects that need unique names associated with each day of the calendar.
    
    sequence dayrects = {}
    atom idx = find(calname, cals[cName])
    if idx > 0 then
        dayrects = cals[cSelectedDate][idx]
    end if
    
    return dayrects
end function


export function day_dates(sequence calname)
--Return a list of dates of each day on the calendar
    
    sequence daydates = {}
    atom idx = find(calname, cals[cName])
    if idx > 0 then
        daydates = cals[cDayDates][idx]
    end if
    
    return daydates
end function

export function day_strings(sequence calname)
--Return a list of string names of each day on the calendar with the format "YYYY-MM-DD".
--This is useful for using in combination with day_rects() to generate handles or other
--objects that need unique names associated with each day of the calendar.
    
    sequence daystrings = {}
    atom idx = find(calname, cals[cName])
    if idx > 0 then
        daystrings = cals[cDayStrings][idx]
    end if
    
    return daystrings
end function
