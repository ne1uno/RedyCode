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


include gui/gui.e as gui
include gui/themes.e as th

include std/sequence.e
include std/search.e
include std/pretty.e
include std/text.e
include std/task.e
include std/stack.e
include std/math.e
include std/search.e
include std/convert.e

--include euphoria/tokenize.e
include euphoria/syncolor.e

constant
debugparagraphs = 0,
debugtokens = 0


sequence            --Info about each textedit instances
iName = {},             --Unique String that identifies instance
iCanvasName = {},       --Name of canvas currently being used or "" if hidden
iParentName = {},       --Name of parentn of canvas currently being used
iLabel = {},            --Label text (file name, page title, etc.)

iSyntaxMode = {},       --type of syntax
iEditMode = {},         --edit mode
iLineNumbers = {},      --1=display line numbers, 0=hide line numbers
iLocked = {},           --editing: 0=unlocked, 1=locked
iWordWrap = {},         --1=word wrapping, 0=no word wrapping

iTokenStyles = {},      --syntax highlighting styles
iSyntaxFont = {},       --font name to use
iSyntaxSize = {},       --font size to use

iParaTokens = {},       --paragraph, list of tokens
iParaBookmark = {},     --paragraph, bookmark number, or 0 for not bookmarked
iParaFold = {},         --paragraph, fold status: 0=not foldable, 1=not folded, 2=folded
iParaTag = {},          --paragraph, string to identify line (for jumping to a routine)
iParaPos = {},          --paragraph, {X,Y} pixel position of paragraph
iParaSize = {},         --paragraph, {Hight, Width} pixel size of paragraph

iCursorState = {},      --is cursor visible or not
iIsSelecting = {},      --is currently selecting text
iSelStartPara = {},     --start paragraph idx
iSelStartToken = {},    --start token idx (in paragraph)
iSelStartChar = {},     --start character idx (in token)
iSelStartCharX = {},    --start character Y offset (relative to token Y pos)
iSelEndPara = {},       --end paragraph idx
iSelEndToken = {},      --end token idx (in paragraph)
iSelEndChar = {},       --end character idx (in token)
iSelEndCharX = {},      --start character Y offset (relative to token Y pos)
iScrollX = {},          --Scroll X position
iScrollY = {},          --Scroll Y position

iLineNumWidth = {},     --width of line number area (automatically adjusts)
iTotalHeight = {},      --total width of all paragraphs
iTotalWidth = {},       --total height of all paragraphs

iBusyStatus = {},       --0 = ready, 1-100 = busy
iBusyTime = {},         --time busy became > 0 (if busy for longer than 0.5s, show progress indicator)
iCmdQueue = {},         --queue of commands to process during process_task
iUndoQueue = {}         --history of commands that can be undone
 

enum            --iSyntaxMode - syntax modes
synPlain,
synEuphoria,
synCreole,
synHTML,
synCSS,
synXML,
synINI,
synC

enum            --iEditMode
emNormal,           --normal selection editing
emBlock,            --block selection
emTable             --allign tokens into columns and for special row/column editing

enum            --iParaTokens (paragraphs are split into groups of characters)
tokenText,          --text of token
tokenPos,           --{X,Y} pixel position of token (relative to paragraph position)
tokenSize,          --{Hight, Width} pixel size of token 
tokenType,          --what kind of data is in the token
tokenInfo           --Extra information related to token type (to determine color, behavior, etc.)

enum            --iParaTokens[tokenType]
ttNone,             --none (plain text)
ttInvalid,          --invalid syntax
ttFound,            --highlight text of search result
ttIdentifier,       --identifier string
ttKeyword,          --keyword string
ttBuiltin,          --builtin word
ttNumber,           --number
ttSymbol,           --operator or other punctuation
ttBracket,          --() {} []
ttString,           --string inside quotes
ttComment          --comment text


sequence
euIdentifiers = {}, --words recognised as declared identifiers (from analyzing existing source)
ttStyles = repeat({}, ttComment) --token styles: {textfont, textsize, textstyle, textcolor}

enum            --not quite sure how i should break down the different commands...
cmdCancelled = 0,
cmdCreateEditor,
cmdDestroyEditor,
cmdInsertText,
cmdUpdateCursor,
cmdStartSelection,
cmdHoverToken,
cmdEndSelection,
cmdSetSelection,
cmdMoveCursor,
cmdScroll,
cmdResize,
cmdUndo,
cmdRedo

enum
selNone,
selRange,
selToken,
selParagraph,
selAll

enum
moveTo,
moveUp,
moveDown,
moveLeft,
moveRight,
moveHome,
moveEnd,
movePageUp,
movePageDown


-- Theme variables -------------------------------
constant
headingheight = 16,
thCurrLineBkColor = th:cButtonFace,
thMonoFont = "Liberation Mono", --"DejaVu Sans Mono",
thNormalFont = "Arial",
thMonoFontSize = 10,
thLineNumberWidth = 40,
thBookmarkWidth = 16,
thLineFoldingWidth = 16,
thBackColor = th:cInnerFill --th:cButtonFace

ttStyles[ttNone] = {thMonoFont, thMonoFontSize, Normal, th:cButtonLabel}
ttStyles[ttInvalid] = {thMonoFont, thMonoFontSize, Normal, th:cButtonLabel}
ttStyles[ttFound] = {thMonoFont, thMonoFontSize, Normal, th:cButtonLabel}
ttStyles[ttIdentifier] = {thMonoFont, thMonoFontSize, Normal, rgb(100, 0, 0)}
ttStyles[ttKeyword] = {thMonoFont, thMonoFontSize, Bold, rgb(0, 0, 100)}
ttStyles[ttBuiltin] = {thMonoFont, thMonoFontSize, Bold, rgb(0, 0, 128)}
ttStyles[ttNumber] = {thMonoFont, thMonoFontSize, Normal, rgb(0, 0, 80)}
ttStyles[ttSymbol] = {thMonoFont, thMonoFontSize, Normal, rgb(0, 0, 0)}
ttStyles[ttBracket] = {thMonoFont, thMonoFontSize, Normal,  rgb(200, 0, 0)}
ttStyles[ttString] = {thMonoFont, thMonoFontSize, Normal, rgb(0, 128, 0)}
ttStyles[ttComment] = {thMonoFont, thMonoFontSize, Italic, rgb(120, 100, 160)}


constant ctable = {  --color table, just to make it easy to give each plot a unique default color
rgb(#04, #FF, #00),
rgb(#FF, #BB, #00),
rgb(#00, #C4, #FF),
rgb(#FF, #7B, #00),
rgb(#00, #FF, #BB),
rgb(#FF, #3C, #00),
rgb(#00, #FF, #FB),
rgb(#FF, #FB, #00),
rgb(#00, #84, #FF),
rgb(#C3, #FF, #00)

/*   rgb(#FF, #3C, #00),
   rgb(#FF, #7B, #00),
   rgb(#FF, #BB, #00),
   rgb(#FF, #FB, #00),
   rgb(#C3, #FF, #00),
   rgb(#04, #FF, #00),
   rgb(#00, #FF, #BB),
   rgb(#00, #FF, #FB),
   rgb(#00, #C4, #FF),
   rgb(#00, #84, #FF)*/
}

function pick_color(atom idx) --pick a color from the color table
    atom len = length(ctable)
    while idx > len do  --wrap around if idx > length(ctable)
        idx -= len
    end while
    return ctable[idx]
end function


atom
ProcessTask = task_create(routine_id("process_task"), {}),
CursorBlinkTask = task_create(routine_id("cursor_blink_task"), {})


procedure cursor_blink_task()
    while 1 do
        for idx = 1 to length(iName) do
            if length(iCanvasName[idx]) > 0 then
                call_cmd(iName[idx], cmdUpdateCursor, {})
            end if
        end for
        task_yield()
    end while
end procedure




function parse_syntax(atom idx, sequence txt)
    sequence ttexts, ttypes, tinfos
    atom isfoldable = 0, currcol = 1
    
    ttexts = {}
    ttypes = {}
    tinfos = {}
    
    switch iSyntaxMode[idx] do
        case synEuphoria then
            --euKeywords
            --euIdentifiers
            ttexts = {}
            --tokenize:string_numbers(1)
            --sequence tokens = tokenize:tokenize_string(txt)  --{tokens, ERR, ERR_LNUM, ERR_LPOS} tokens: {TTYPE, TDATA, TLNUM, TLPOS, TFORM}
            
            sequence tokens = syncolor:SyntaxColor(txt), tokwords
            object toktype
            
            for t = 1 to length(tokens) do
                toktype = tokens[t][1]
                tokwords = split(tokens[t][2])
                if length(tokwords) > 1 then
                    for tt = 1 to length(tokwords)-1 do
                        tokwords[tt] &= ' '
                    end for
                end if
                for tt = 1 to length(tokwords) do
                    if toktype < 0 then
                        ttypes &= {ttBracket}
                        tinfos &= {0}
                        --tinfos &= {-toktype} --wierd negative number hack to identify different bracket colors
                    else
                        ttypes &= {toktype}
                        tinfos &= {0}
                    end if
                    ttexts &= {tokwords[tt]}
                end for
            end for
                --ttexts &= {split(tokens[1][t][tokenize:TDATA])}
                --puts(1, tokens[1][t][tokenize:TDATA])
                
                --if find(tokens[1][t][tokenize:TTYPE], {T_DELIMITER}) then
                
                --else
                --    ttexts &= {tokens[1][t][tokenize:TDATA]}
                --end if
                
                                        
/*
T_EOF,
T_NULL,
T_SHBANG,
T_NEWLINE,
T_COMMENT,
T_NUMBER,
T_CHAR,
T_STRING,
T_IDENTIFIER,
T_KEYWORD,
T_DOUBLE_OPS,
T_PLUSEQ = T_DOUBLE_OPS,
T_MINUSEQ,
T_MULTIPLYEQ,
T_DIVIDEEQ,
T_LTEQ,
T_GTEQ,
T_NOTEQ,
T_CONCATEQ,
T_DELIMITER,
T_PLUS = T_DELIMITER,
T_MINUS,
T_MULTIPLY,
T_DIVIDE,
T_LT,
T_GT,
T_NOT,
T_CONCAT,
T_SINGLE_OPS,
T_EQ = T_SINGLE_OPS,
T_LPAREN,
T_RPAREN,
T_LBRACE,
T_RBRACE,
T_LBRACKET,
T_RBRACKET,
T_QPRINT,
T_COMMA,
T_PERIOD,
T_COLON,
T_DOLLAR,
T_SLICE
*/
                
                
                --currcol = tokens[1][t][tokenize:TLPOS]
                --ttexts &= {token_names[tokens[1][t][tokenize:TTYPE]] & ":" & tokens[1][t][tokenize:TDATA]}
                --ttexts &= {tokens[1][t][tokenize:TDATA]}
                

            --end for
            
            --ttexts = split(pretty_sprint(ttexts, {2}))
            if length(ttexts) = 0 then
                ttexts &= {""}
            end if
            ttypes &= repeat(ttNone, length(ttexts))
            tinfos &= repeat(0, length(ttexts))
            /*
            for t = 1 to length(ttexts)-1 do
                if isComment then
                    ttypes[t] = ttStyles[ttComment]
                    
                elsif isQuote then
                    ttypes[t] = ttStyles[ttString]
                    
                --elsif ttypes[t] = ttStyles[ttFound]  --results of find, not implemented yet
                
                else
                    
                    if find(ttexts[t], EuWhitespace) then
                        ttypes[t] = ttStyles[ttWhiteSpace]
                        
                    elsif find(ttexts[t], EuNumber) then
                        ttypes[t] = ttStyles[ttNumber]
                        
                    elsif find(ttexts[t], EuSymbol) then
                        --isComment = 1
                        --isQuote = 1
                        --ttypes[t] = ttStyles[ttOpenSymb]
                        --ttypes[t] = ttStyles[ttCloseSymb]
                        ttypes[t] = ttStyles[ttSymbol]
                        
                    elsif find(ttexts[t], EuIdentifier) then
                        ttypes[t] = ttStyles[ttIdentifier]
                        
                    elsif find(ttexts[t], EuKeywords) then
                        ttypes[t] = ttStyles[ttKeyword]
                        
                    else
                        --ttypes[t] = ttStyles[ttInvalid]
                        ttypes[t] = ttStyles[ttNone]
                    end if
                end if
            end for
            */
            /*--color test:
            for t = 1 to length(ttexts)-1 do
                ttexts[t] &= ' '
                ttypes[t] = temptype
                --tinfos[t] = 0
                if temptype = ttNone then
                    temptype = ttIdentifier
                elsif temptype = ttIdentifier then
                    temptype = ttKeyword
                elsif temptype = ttKeyword then
                    temptype = ttNumber
                elsif temptype = ttNumber then
                    temptype = ttSymbol
                elsif temptype = ttSymbol then
                    temptype = ttNone
                end if
            end for*/
            
        --case synCreole then
            
        /*case synHTML then
            ttexts = split(txt)
            if length(ttexts) > 1 then
                for t = 1 to length(ttexts)-1 do
                    ttexts[t] &= ' '
                end for
            end if
            if length(ttexts) = 0 then
                ttexts = {""}
            end if
            ttypes &= repeat(ttNone, length(ttexts))
            tinfos &= repeat(0, length(ttexts))
            */
        --case synCSS then
            
        --case synXML then
            
        --case synINI then
            
        --case synC then
            
        case else
            ttexts = split(txt)
            if length(ttexts) > 1 then
                for t = 1 to length(ttexts)-1 do
                    ttexts[t] &= ' '
                end for
            end if
            if length(ttexts) = 0 then
                ttexts = {""}
            end if
            ttypes &= repeat(ttNone, length(ttexts))
            tinfos &= repeat(0, length(ttexts))
            
    end switch
    
    return {ttexts, ttypes, tinfos, isfoldable}
end function


procedure keep_cursor_in_view(atom idx, sequence trect)
   /* atom cx, cy

    cx = trect[1] + wcprops[wcpIndent][idx] - floor(wcprops[wcpScrollPosX][idx]) + 2 + wcprops[wcpSelStartX][idx]
    cy = trect[2] - floor(wcprops[wcpScrollPosY][idx]) + wcprops[wcpSelStartLine][idx] * wcprops[wcpLineHeight][idx] - wcprops[wcpLineHeight][idx]
    
    if cx > trect[3] - 20 then --to the right
        if wcprops[wcpScrollH][idx] > 0 then
            wc_call_command(wcprops[wcpScrollH][idx], "set_value_rel", cx - trect[1] - floor((trect[3] - trect[1]) / 2))
        end if
    elsif cx < trect[1] + 20 then --to the left
        if wcprops[wcpScrollH][idx] > 0 then
            wc_call_command(wcprops[wcpScrollH][idx], "set_value_rel", cx - trect[1] - floor((trect[3] - trect[1]) / 2))
        end if
    end if
    if cy > trect[4] - wcprops[wcpLineHeight][idx] - 20 then --below
        if wcprops[wcpScrollV][idx] > 0 then
            wc_call_command(wcprops[wcpScrollV][idx], "set_value_rel", cy - trect[2] - floor((trect[4] - trect[2]) / 2) + wcprops[wcpLineHeight][idx])
        end if
    elsif cy < trect[2] + wcprops[wcpLineHeight][idx] + 20 then --above
        if wcprops[wcpScrollV][idx] > 0 then
            wc_call_command(wcprops[wcpScrollV][idx], "set_value_rel", cy - trect[2] - floor((trect[4] - trect[2]) / 2))
        end if
    end if*/
end procedure


function get_mouse_pos(atom idx, atom mx, atom my)
    sequence te, tokens, ret = {}
    atom px, py,
    whnd = gui:widget_get_handle(iCanvasName[idx])
    set_font(whnd, thMonoFont, thMonoFontSize, 0)
    
    --todo: instead of scanning from paragraph 1, start from known 1st visible paragraph to improve speed
    for p = 1 to length(iParaTokens[idx]) do
        tokens = iParaTokens[idx][p]
        px = iParaPos[idx][p][1] - iScrollX[idx]
        py = iParaPos[idx][p][2] - iScrollY[idx]
        --find paragraphs that are within view
        if  px < mx  --and px + iParaSize[idx][p][1] > mx 
        --and py < my
        and py + iParaSize[idx][p][2] >= my then
            for t = 1 to length(tokens[tokenText]) do
                if py + tokens[tokenPos][t][2] < my then 
                --and py + tokens[tokenPos][t][2] + tokens[tokenSize][t][2] >= my then
                    if mx >= px + tokens[tokenPos][t][1] then
                        ret = {p, t, 0, 0}
                        for c = 1 to length(tokens[tokenText][t]) do
                            te = get_text_extent(whnd, tokens[tokenText][t][1..c])
                            if px + tokens[tokenPos][t][1] + te[1] < mx then
                                ret = {p, t, c, te[1]}
                            end if 
                        end for
                    end if
                end if
            end for
            if length(ret) = 4 then
                --? ret
                return ret
            end if
        end if
    end for
    atom lp, lt, lc
    
    
    if my > iParaPos[idx][$][2] +  iParaSize[idx][$][2] - iScrollY[idx] then  --below paragraphs
        --todo: get exact x position
        lp = length(iParaTokens[idx])
        lt = length(iParaTokens[idx][lp][tokenText])
        lc = length(iParaTokens[idx][lp][tokenText][lt])
        te = get_text_extent(whnd, iParaTokens[idx][lp][tokenText][lt][1..lc])
        
        ret = {lp, lt, lc, te[1]}
    elsif my < iParaPos[idx][1][2] - iScrollY[idx] then  --above paragraphs
        --todo: get exact x position
        lp = 1
        lt = 1
        lc = 0
        te = {0, 0}
        
        ret = {lp, lt, lc, te[1]}
    
    else
        ret = {0, 0, 0, 0}
    end if
    
    return ret
end function


procedure arrange_tokens(atom idx, atom startp)
    atom whnd, prevlnw
    object newtxt, txt, src, tokens
    sequence te
    
    iBusyTime[idx] = time()
    
    whnd = gui:widget_get_handle(iCanvasName[idx])
--set linenumber width:
    set_font(whnd, thMonoFont, thMonoFontSize, 0)
    te = get_text_extent(whnd, sprint(length(iParaTokens[idx]))) --get width of string of maximum line number
    prevlnw = iLineNumWidth[idx]
    iLineNumWidth[idx] = te[1] + thMonoFontSize * 2 + 12 --add extra space for bookmark/line folding symbols
    
--get canvas size, etc.
    set_font(whnd, thMonoFont, thMonoFontSize, 0)
    --iTokenStyles[idx][t]  --{thBackColor, rgb(0, 0, 0), 0, 0, 0}
    --set_font(whnd, currStyle[sFont], currStyle[sFontsize], or_all({currStyle[sBold], currStyle[sItalics], currStyle[sUnderline]}))
    
    --sequence csize = get_text_extent(whnd, repeat(' ', 80))
    sequence
    csize = gui:wfunc(iCanvasName[idx], "get_canvas_size", {}),
    emptysize = get_text_extent(whnd, " ")
    atom MaxWidth = csize[1] - iLineNumWidth[idx] - 2 - th:scrwidth
    
    iTotalWidth[idx] = 0
    iTotalHeight[idx] =  0
    
    atom tt = time()
    --puts(1, "building tokens...")
    
    if prevlnw != iLineNumWidth[idx] then
        startp = 0
    end if 
    
    if startp > 0 then --refresh starting with specified paragraph
        startp -= 1 --reduce by one so "if p > startp" can be used instead of "if p >= startp" (does this make it faster?)
    else --refresh all paragraghs
        iParaSize[idx] = repeat(0, length(iParaTokens[idx])) --mark all paragraphs to be rearranged
    end if
    
    for p = 1 to length(iParaTokens[idx]) do --need to start at 1 to find the maximum width
        if p > startp then
            --scan for paragraphs that need all tokens rebuilt (syntax parsing and wordwrap)
            if atom(iParaSize[idx][p]) then --paragraph's tokens have changed
                iParaSize[idx][p] = emptysize
                tokens = iParaTokens[idx][p]
                
                for t = 1 to length(tokens[tokenText]) do
                    if atom(tokens[tokenSize][t]) then --need to recalculate size of token text
                        tokens[tokenSize][t] = get_text_extent(whnd, tokens[tokenText][t])
                        tokens[tokenSize][t][2] += 2
                    end if
                    --increment token positions with wordwrap
                    tokens[tokenPos][t] = {0, 0}
                    if t > 1 then
                        tokens[tokenPos][t][1] = tokens[tokenPos][t-1][1] + tokens[tokenSize][t-1][1]
                        tokens[tokenPos][t][2] = tokens[tokenPos][t-1][2]
                        --wordwrap:
                        if tokens[tokenPos][t][1] + tokens[tokenSize][t][1] > MaxWidth then
                            tokens[tokenPos][t][1] = 0
                            tokens[tokenPos][t][2] = tokens[tokenPos][t-1][2] + tokens[tokenSize][t-1][2]
                        end if
                    end if
                    if iParaSize[idx][p][1] < tokens[tokenPos][t][1] + tokens[tokenSize][t][1] then
                        iParaSize[idx][p][1] = tokens[tokenPos][t][1] + tokens[tokenSize][t][1]
                    end if
                    if iParaSize[idx][p][2] < tokens[tokenPos][t][2] + tokens[tokenSize][t][2] then
                        iParaSize[idx][p][2] = tokens[tokenPos][t][2] + tokens[tokenSize][t][2]
                    end if
                end for
                iParaTokens[idx][p] = tokens
            end if
            
            --update paragraph position (based on previous paragraph)
            if p = 1 then
                iParaPos[idx][p] = {iLineNumWidth[idx], 0}
            elsif p > 1 then
                iParaPos[idx][p] = {iLineNumWidth[idx], iParaPos[idx][p-1][2] + iParaSize[idx][p-1][2]}
            end if
        end if
        
        if iTotalWidth[idx] < iParaPos[idx][p][1] + iParaSize[idx][p][1] then
            iTotalWidth[idx] = iParaPos[idx][p][1] + iParaSize[idx][p][1]
        end if
        if iTotalHeight[idx] < iParaPos[idx][p][2] + iParaSize[idx][p][2] then
            iTotalHeight[idx] = iParaPos[idx][p][2] + iParaSize[idx][p][2]
        end if
        
        if time() - iBusyTime[idx] > 0.05 then
            gui:wproc(iCanvasName[idx], "set_background_pointer", {"Busy"})
            iBusyStatus[idx] = floor(p / (p - startp) )
            task_yield()
            --iBusyTime[idx] = time()
            set_font(whnd, thMonoFont, thMonoFontSize, 0)
        end if
    end for
    --? time() - tt
    
    gui:wproc(iCanvasName[idx], "set_canvas_size", {iTotalWidth[idx], iTotalHeight[idx]})
    
    iBusyStatus[idx] = 0
    iBusyTime[idx] = 0
    gui:wproc(iCanvasName[idx], "set_background_pointer", {"Ibeam"})
    
    draw(iName[idx], 1)
end procedure




procedure process_task()
    atom idx = 0, whnd
    object newtxt, txt, src, tokens
    
    while 1 do
        idx += 1
                
        --Check queue for visible text editors. If the queue containes commands,
        --show busy/progress indicator and select this editor to process commands immediately.
        /*for i = 1 to length(iCmdQueue) do
            --gui:debug("iCmdQueue[" & sprint(i) & "]", iCmdQueue[i])
            if length(iCanvasName[i]) > 0 then   --find editor currently linked to a canvas
                if length(iCmdQueue[i]) > 0 then --if commands are in the queue
                    idx = i --select this editor to process commands immediately
                    
                    if iBusyStatus[idx] = 0 then
                        iBusyTime[idx] = time()
                        iBusyStatus[idx] = 1
                        gui:wproc(iCanvasName[idx], "set_background_pointer", {"Busy"})
                    else
                        if time() - iBusyTime[idx] > 0.5 then
                            --todo: show progress indicator
                        end if
                    end if
                else
                    if iBusyStatus[i] > 0 then
                        iBusyStatus[i] = 0
                        iBusyTime[i] = 0
                        gui:wproc(iCanvasName[i], "set_background_pointer", {"Ibeam"})
                    end if
                end if
            end if
        end for
        */
        
        --Process Commands of selected editor:
        if idx > length(iCmdQueue) then
            idx = 0
        else
            task_schedule(ProcessTask, 500)
            
            if length(iCmdQueue[idx]) > 0 then
                iBusyTime[idx] = time()
                switch iCmdQueue[idx][1][1] do
                    case cmdDestroyEditor then --iCmdQueue[idx][1][2] = {}
                        gui:wdestroy(iName[idx])
                        
                        iName[idx]          = remove(iName[idx], idx)
                        iCanvasName[idx]    = remove(iCanvasName[idx], idx)
                        iParentName[idx]    = remove(iParentName[idx], idx)
                        iLabel[idx]         = remove(iLabel[idx], idx)
                        
                        iSyntaxMode[idx]    = remove(iSyntaxMode[idx], idx)
                        iEditMode[idx]      = remove(iEditMode[idx], idx)
                        iLineNumbers[idx]   = remove(iLineNumbers[idx], idx)
                        iLocked[idx]        = remove(iLocked[idx], idx)
                        iWordWrap[idx]      = remove(iWordWrap[idx], idx)
                        
                        iTokenStyles[idx]   = remove(iTokenStyles[idx], idx)
                        iSyntaxFont[idx]    = remove(iSyntaxFont[idx], idx)
                        iSyntaxSize[idx]    = remove(iSyntaxSize[idx], idx)
                        
                        iParaTokens[idx]    = remove(iParaTokens[idx], idx)
                        iParaBookmark[idx]  = remove(iParaBookmark[idx], idx)
                        iParaFold[idx]      = remove(iParaFold[idx], idx)
                        iParaTag[idx]       = remove(iParaTag[idx], idx)
                        iParaPos[idx]       = remove(iParaPos[idx], idx)
                        iParaSize[idx]      = remove(iParaSize[idx], idx)
                        
                        iCursorState[idx]   = remove(iCursorState[idx], idx)
                        iIsSelecting[idx]   = remove(iIsSelecting[idx], idx)
                        iSelStartPara[idx]  = remove(iSelStartPara[idx], idx)
                        iSelStartToken[idx] = remove(iSelStartToken[idx], idx)
                        iSelStartChar[idx]  = remove(iSelStartChar[idx], idx)
                        iSelStartCharX[idx] = remove(iSelStartCharX[idx], idx)
                        iSelEndPara[idx]    = remove(iSelEndPara[idx], idx)
                        iSelEndToken[idx]   = remove(iSelEndToken[idx], idx)
                        iSelEndChar[idx]    = remove(iSelEndChar[idx], idx)
                        iSelEndCharX[idx]   = remove(iSelEndCharX[idx], idx)
                        iScrollX[idx]       = remove(iScrollX[idx], idx)
                        iScrollY[idx]       = remove(iScrollY[idx], idx)
                        
                        iLineNumWidth[idx]  = remove(iLineNumWidth[idx], idx)
                        iTotalHeight[idx]   = remove(iTotalHeight[idx], idx)
                        iTotalWidth[idx]    = remove(iTotalWidth[idx], idx)
                        
                        iBusyStatus[idx]    = remove(iBusyStatus[idx], idx)
                        iBusyTime[idx]      = remove(iBusyTime[idx], idx)
                        iCmdQueue[idx]      = remove(iCmdQueue[idx], idx)
                        iUndoQueue[idx]     = remove(iUndoQueue[idx], idx)
                        
                        idx = 0
                        
                    case cmdInsertText then --iCmdQueue[idx][1][2] = character or string
                        newtxt = iCmdQueue[idx][1][2]
                        
                        atom selSp, selSt, selSc, selScX, selEp, selEt, selEc, selEcX, tfe, cfe
                        
                        if iSelStartPara[idx] > iSelEndPara[idx] then
                            selSp = iSelEndPara[idx]
                            selSt = iSelEndToken[idx]
                            selSc = iSelEndChar[idx]
                            selScX = iSelEndCharX[idx]
                            selEp = iSelStartPara[idx]
                            selEt = iSelStartToken[idx]
                            selEc = iSelStartChar[idx]
                            selEcX = iSelStartCharX[idx]
                        elsif iSelStartPara[idx] = iSelEndPara[idx] and iSelStartToken[idx] > iSelEndToken[idx] then
                            selSp = iSelStartPara[idx]
                            selSt = iSelEndToken[idx]
                            selSc = iSelEndChar[idx]
                            selScX = iSelEndCharX[idx]
                            selEp = iSelEndPara[idx]
                            selEt = iSelStartToken[idx]
                            selEc = iSelStartChar[idx]
                            selScX = iSelStartCharX[idx]
                        elsif iSelStartPara[idx] = iSelEndPara[idx] and iSelStartToken[idx] = iSelEndToken[idx] and iSelStartChar[idx] > iSelEndChar[idx] then
                            selSp = iSelStartPara[idx]
                            selSt = iSelStartToken[idx]
                            selSc = iSelEndChar[idx]
                            selScX = iSelEndCharX[idx]
                            selEp = iSelEndPara[idx]
                            selEt = iSelEndToken[idx]
                            selEc = iSelStartChar[idx]
                            selScX = iSelStartCharX[idx]
                        else
                            selSp = iSelStartPara[idx]
                            selSt = iSelStartToken[idx]
                            selSc = iSelStartChar[idx]
                            selScX = iSelStartCharX[idx]
                            selEp = iSelEndPara[idx]
                            selEt = iSelEndToken[idx]
                            selEc = iSelEndChar[idx]
                            selScX = iSelEndCharX[idx]
                        end if
                        tfe = length(iParaTokens[idx][selEp][tokenText]) - selEt
                        cfe = length(iParaTokens[idx][selEp][tokenText][selEt]) - selEc
                        
                        if atom(newtxt) then
                            if newtxt = 8 then --backspace
                                txt = {""}
                                if selSp = selEp and selSt = selEt and selSc = selEc then --set selection to 1 char left of cursor
                                    sequence te
                                    atom p, t, c
                                    
                                    p = selSp
                                    t = selSt
                                    c = selSc - 1
                                    whnd = gui:widget_get_handle(iCanvasName[idx])
                                    set_font(whnd, thMonoFont, thMonoFontSize, 0)
                                    
                                    if c < 0 then
                                        t = t - 1
                                        if t < 1 then
                                            p = p - 1
                                            if p < 1 then
                                                p = 1
                                                t = 1
                                                c = 0
                                            else
                                                t = length(iParaTokens[idx][p][tokenText])
                                                c = length(iParaTokens[idx][p][tokenText][t])
                                            end if
                                        else
                                            c = length(iParaTokens[idx][p][tokenText][t]) - 1
                                            if c < 0 then
                                                c = 0
                                            end if
                                        end if
                                    end if
                                    te = get_text_extent(whnd, iParaTokens[idx][p][tokenText][t][1..c])
                                    
                                    selSp = p
                                    selSt = t
                                    selSc = c
                                    selScX = te[1]
                                end if
                                
                            elsif newtxt = 46 then --delete
                                txt = {""}
                                if selSp = selEp and selSt = selEt and selSc = selEc then --set selection to 1 char left of cursor
                                    sequence te
                                    atom p, t, c
                                    
                                    p = selSp
                                    t = selSt
                                    c = selSc + 1
                                    whnd = gui:widget_get_handle(iCanvasName[idx])
                                    set_font(whnd, thMonoFont, thMonoFontSize, 0)
                                    
                                    if c > length(iParaTokens[idx][p][tokenText][t]) then
                                        t = t + 1
                                        if t > length(iParaTokens[idx][p][tokenText]) then
                                            p = p + 1
                                            if p > length(iParaTokens[idx]) then
                                                p = length(iParaTokens[idx])
                                                t = length(iParaTokens[idx][p][tokenText])
                                                c = length(iParaTokens[idx][p][tokenText][t])
                                            else
                                                t = 1
                                                c = 0
                                            end if
                                        else
                                            if length(iParaTokens[idx][p][tokenText][t]) = 0 then
                                                c = 0
                                            else
                                                c = 1
                                            end if
                                        end if
                                    end if
                                    te = get_text_extent(whnd, iParaTokens[idx][p][tokenText][t][1..c])
                                    
                                    selEp = p
                                    selEt = t
                                    selEc = c
                                    selScX = te[1]
                                end if
                                
                            elsif newtxt = 13 then --newline
                                txt = {"", ""}
                                
                            else
                                txt = {newtxt}
                                
                            end if
                        else
                            if length(newtxt) = 0 then --empty string
                                txt = {""}
                            else
                                if atom(newtxt[1]) then  --insert string, convert to sequence of strings separated by newlines
                                    txt = split_any(newtxt,{10,13}, 0, 1)
                                else    --insert sequence of strings
                                    txt = newtxt
                                end if
                            end if
                        end if
                        --todo: add more filters to replace invalid characters
                        
                        --get cursor position and split paragraph text
                        sequence
                        ptxt1 = join(iParaTokens[idx][selSp][tokenText][1..selSt-1], "") & iParaTokens[idx][selSp][tokenText][selSt][1..selSc],
                        ptxt2 = iParaTokens[idx][selEp][tokenText][selEt][selEc+1..$] & join(iParaTokens[idx][selEp][tokenText][selEt+1..$], "")
                        
                        txt[1] = ptxt1 & txt[1]
                        txt[$] = txt[$] & ptxt2
                        
                        --insert paragraphs:
                        iParaTokens[idx]    = iParaTokens[idx][1..selSp-1] & repeat(0, length(txt)) & iParaTokens[idx][selEp+1..$]
                        iParaBookmark[idx]  = iParaBookmark[idx][1..selSp-1] & repeat(0, length(txt)) & iParaBookmark[idx][selEp+1..$]
                        iParaFold[idx]      = iParaFold[idx][1..selSp-1] & repeat(0, length(txt)) & iParaFold[idx][selEp+1..$]
                        iParaTag[idx]       = iParaTag[idx][1..selSp-1] & repeat(0, length(txt)) & iParaTag[idx][selEp+1..$]
                        iParaPos[idx]       = iParaPos[idx][1..selSp-1] & repeat(0, length(txt)) & iParaPos[idx][selEp+1..$]
                        iParaSize[idx]      = iParaSize[idx][1..selSp-1] & repeat(0, length(txt)) & iParaSize[idx][selEp+1..$]
                        
                        /*whnd = gui:widget_get_handle(iCanvasName[idx])
                        set_font(whnd, thMonoFont, thMonoFontSize, 0)
                        sequence te = get_text_extent(whnd, sprint(length(txt))) --get width of string of maximum line number
                        iLineNumWidth[idx] = te[1] + thMonoFontSize * 2 + 12 --add extra space for bookmark/line folding symbols*/
                        
                        syncolor:set_colors({
                            {"NORMAL", ttNone},
                            {"COMMENT", ttComment},
                            {"KEYWORD", ttKeyword},
                            {"BUILTIN", ttBuiltin},
                            {"STRING", ttString},
                            {"BRACKET", {ttBracket, -1, -2, -3, -4, -5, -6, -7, -8, -9, -10}}
                        })
                        
                        syncolor:reset()
                        
                        atom pidx = selSp
                        for p = 1 to length(txt) do
                            --puts(1, txt[p] & "\n")
                            src = parse_syntax(idx, txt[p]) --returns {texts, types, infos, isfoldable}
                            
                            --build tokens:
                            tokens = {{}, {}, {}, {}, {}}  --{tokenText, tokenPos, tokenSize, tokenType, tokenInfo}
                            tokens[tokenText] = src[1]
                            tokens[tokenPos]  = repeat(0, length(src[1]))
                            tokens[tokenSize] = repeat(0, length(src[1]))
                            tokens[tokenType] = src[2]
                            tokens[tokenInfo] = src[3]
                            
                            iParaTokens[idx][pidx] = tokens
                            iParaFold[idx][pidx]   = src[4]
                            pidx += 1
                        end for
                        --puts(1, "\n\n\n")
                        arrange_tokens(idx, selSp)
                        
                        --todo: figure out what to do in different cases: backspace, delete, etc. if there was or selection, or not?
                        if atom(newtxt) and newtxt = 8 then --backspace
                            iSelStartPara[idx] = selSp
                            iSelStartToken[idx] = selSt
                            iSelStartChar[idx] = selSc
                            iSelStartCharX[idx] = selScX
                            iSelEndPara[idx] = selSp
                            iSelEndToken[idx] = selSt
                            iSelEndChar[idx] = selSc
                            iSelEndCharX[idx] = selScX
                            
                        elsif atom(newtxt) and newtxt = 46 then --delete
                            iSelStartPara[idx] = selSp
                            iSelStartToken[idx] = selSt
                            iSelStartChar[idx] = selSc
                            iSelStartCharX[idx] = selScX
                            iSelEndPara[idx] = selSp
                            iSelEndToken[idx] = selSt
                            iSelEndChar[idx] = selSc
                            iSelEndCharX[idx] = selScX
                            
                        else
                            atom newp, newt, newc, cx, cy
                    
                            newp = selSp + length(txt) - 1
                            newt = length(iParaTokens[idx][newp][tokenText]) - tfe
                            newc = length(iParaTokens[idx][newp][tokenText][newt]) - cfe
                            
                            whnd = gui:widget_get_handle(iCanvasName[idx])
                            set_font(whnd, thMonoFont, thMonoFontSize, 0)
                            
                            sequence te = get_text_extent(whnd, iParaTokens[idx][newp][tokenText][newt][1..newc])
                            
                            iIsSelecting[idx] = 0
                            iCursorState[idx] = 1
                            iSelStartPara[idx] = newp
                            iSelStartToken[idx] = newt
                            iSelStartChar[idx] = newc
                            iSelStartCharX[idx] = te[1]
                            iSelEndPara[idx] = iSelStartPara[idx] 
                            iSelEndToken[idx] = iSelStartToken[idx]
                            iSelEndChar[idx] = iSelStartChar[idx] 
                            iSelEndCharX[idx] = iSelStartCharX[idx]
                            draw(iName[idx], 1)
                        end if
                        
                    case cmdUpdateCursor then --iCmdQueue[idx][1][2] = {}
                        if iIsSelecting[idx] = 0 then
                        --and iSelStartPara[idx] = iSelEndPara[idx] 
                        --and iSelStartToken[idx] = iSelEndToken[idx]
                        --and iSelStartChar[idx] = iSelEndChar[idx] then
                            if iCursorState[idx] = 1 then
                                iCursorState[idx] = 0
                            else
                                iCursorState[idx] = 1
                            end if
                            draw(iName[idx], 2)
                        end if
                        
                    case cmdStartSelection then --iCmdQueue[idx][1][2] = {x, y}
                        sequence mpos = get_mouse_pos(idx, iCmdQueue[idx][1][2][1], iCmdQueue[idx][1][2][2]) --{p, t, c, te[1]}
                        iIsSelecting[idx] = 1
                        iCursorState[idx] = 1
                        iSelStartPara[idx] = mpos[1]
                        iSelStartToken[idx] = mpos[2]
                        iSelStartChar[idx] = mpos[3]
                        iSelStartCharX[idx] = mpos[4]
                        iSelEndPara[idx] = mpos[1]
                        iSelEndToken[idx] = mpos[2]
                        iSelEndChar[idx] = mpos[3]
                        iSelEndCharX[idx] = mpos[4]
                        draw(iName[idx], 1)
                        
                    case cmdHoverToken then --iCmdQueue[idx][1][2] = {x, y}
                        if iIsSelecting[idx] = 1 then
                            sequence mpos = get_mouse_pos(idx, iCmdQueue[idx][1][2][1], iCmdQueue[idx][1][2][2]) --{p, t, c, te[1]}
                            iSelEndPara[idx] = mpos[1]
                            iSelEndToken[idx] = mpos[2]
                            iSelEndChar[idx] = mpos[3]
                            iSelEndCharX[idx] = mpos[4]
                            draw(iName[idx], 1)
                        end if
                        
                    case cmdEndSelection then --iCmdQueue[idx][1][2] = {x, y}
                        if iIsSelecting[idx] = 1 then
                            sequence mpos = get_mouse_pos(idx, iCmdQueue[idx][1][2][1], iCmdQueue[idx][1][2][2]) --{p, t, c, te[1]}
                            iIsSelecting[idx] = 0
                            iCursorState[idx] = 1
                            iSelEndPara[idx] = mpos[1]
                            iSelEndToken[idx] = mpos[2]
                            iSelEndChar[idx] = mpos[3]
                            iSelEndCharX[idx] = mpos[4]
                            draw(iName[idx], 1)
                        end if
                        
                    case cmdSetSelection then --iCmdQueue[idx][1][2] = {selmode, data1, data2}
                        if iCmdQueue[idx][1][2][1] = selNone then
                            
                        elsif iCmdQueue[idx][1][2][1] = selRange then
                            
                        elsif iCmdQueue[idx][1][2][1] = selToken then
                            
                        elsif iCmdQueue[idx][1][2][1] = selParagraph then
                            
                        elsif iCmdQueue[idx][1][2][1] = selAll then
                            
                        end if
                        
                    case cmdMoveCursor then --iCmdQueue[idx][1][2] = {direction, distance}
                        if iCmdQueue[idx][1][2][1] = moveUp then
                            sequence te, mpos
                            atom p, t, c, cx, cy
                            
                            p = iSelEndPara[idx]
                            t = iSelEndToken[idx]
                            c = iSelEndChar[idx]
                                              
                            cx = iParaPos[idx][p][1] - iScrollX[idx]
                                + iParaTokens[idx][p][tokenPos][t][1]
                                + iSelEndCharX[idx]
                                + 1
                            cy = iParaPos[idx][p][2] - iScrollY[idx]
                                + iParaTokens[idx][p][tokenPos][t][2]
                                - 1
                                --+ iParaTokens[idx][p][tokenSize][t][2]
                            
                            
                            mpos = get_mouse_pos(idx, cx, cy) --{p, t, c, te[1]}
                            
                            whnd = gui:widget_get_handle(iCanvasName[idx])
                            set_font(whnd, thMonoFont, thMonoFontSize, 0)
                            
                            te = get_text_extent(whnd, iParaTokens[idx][p][tokenText][t][1..c])
                            
                            iIsSelecting[idx] = 0
                            iCursorState[idx] = 1
                            iSelStartPara[idx] = mpos[1]
                            iSelStartToken[idx] = mpos[2]
                            iSelStartChar[idx] = mpos[3]
                            iSelStartCharX[idx] = mpos[4]
                            iSelEndPara[idx] = iSelStartPara[idx] 
                            iSelEndToken[idx] = iSelStartToken[idx]
                            iSelEndChar[idx] = iSelStartChar[idx] 
                            iSelEndCharX[idx] = iSelStartCharX[idx]
                            draw(iName[idx], 1)
                            
                        elsif iCmdQueue[idx][1][2][1] = moveDown then
                            sequence te, mpos
                            atom p, t, c, cx, cy
                            
                            p = iSelEndPara[idx]
                            t = iSelEndToken[idx]
                            c = iSelEndChar[idx]
                                                        
                            cx = iParaPos[idx][p][1] - iScrollX[idx]
                                + iParaTokens[idx][p][tokenPos][t][1]
                                + iSelEndCharX[idx]
                                + 1
                            cy = iParaPos[idx][p][2] - iScrollY[idx]
                                + iParaTokens[idx][p][tokenPos][t][2]
                                + iParaTokens[idx][p][tokenSize][t][2]
                                + 1
                            
                            mpos = get_mouse_pos(idx, cx, cy) --{p, t, c, te[1]}
                            
                            whnd = gui:widget_get_handle(iCanvasName[idx])
                            set_font(whnd, thMonoFont, thMonoFontSize, 0)
                            
                            te = get_text_extent(whnd, iParaTokens[idx][p][tokenText][t][1..c])
                            
                            iIsSelecting[idx] = 0
                            iCursorState[idx] = 1
                            iSelStartPara[idx] = mpos[1]
                            iSelStartToken[idx] = mpos[2]
                            iSelStartChar[idx] = mpos[3]
                            iSelStartCharX[idx] = mpos[4]
                            iSelEndPara[idx] = iSelStartPara[idx] 
                            iSelEndToken[idx] = iSelStartToken[idx]
                            iSelEndChar[idx] = iSelStartChar[idx] 
                            iSelEndCharX[idx] = iSelStartCharX[idx]
                            draw(iName[idx], 1)
                            
                        elsif iCmdQueue[idx][1][2][1] = moveLeft then
                            sequence te
                            atom p, t, c
                            
                            p = iSelEndPara[idx]
                            t = iSelEndToken[idx]
                            c = iSelEndChar[idx] - 1
                            whnd = gui:widget_get_handle(iCanvasName[idx])
                            set_font(whnd, thMonoFont, thMonoFontSize, 0)
                            
                            if c < 0 then
                                t = t - 1
                                if t < 1 then
                                    p = p - 1
                                    if p < 1 then
                                        p = 1
                                        t = 1
                                        c = 0
                                    else
                                        t = length(iParaTokens[idx][p][tokenText])
                                        c = length(iParaTokens[idx][p][tokenText][t])
                                    end if
                                else
                                    c = length(iParaTokens[idx][p][tokenText][t]) - 1
                                    if c < 0 then
                                        c = 0
                                    end if
                                end if
                            end if
                            te = get_text_extent(whnd, iParaTokens[idx][p][tokenText][t][1..c])
                            
                            iIsSelecting[idx] = 0
                            iCursorState[idx] = 1
                            iSelStartPara[idx] = p
                            iSelStartToken[idx] = t
                            iSelStartChar[idx] = c
                            iSelStartCharX[idx] = te[1]
                            iSelEndPara[idx] = iSelStartPara[idx] 
                            iSelEndToken[idx] = iSelStartToken[idx]
                            iSelEndChar[idx] = iSelStartChar[idx] 
                            iSelEndCharX[idx] = iSelStartCharX[idx]
                            draw(iName[idx], 1)
                            
                        elsif iCmdQueue[idx][1][2][1] = moveRight then
                            sequence te
                            atom p, t, c
                            
                            p = iSelEndPara[idx]
                            t = iSelEndToken[idx]
                            c = iSelEndChar[idx] + 1
                            whnd = gui:widget_get_handle(iCanvasName[idx])
                            set_font(whnd, thMonoFont, thMonoFontSize, 0)
                            
                            if c > length(iParaTokens[idx][p][tokenText][t]) then
                                t = t + 1
                                if t > length(iParaTokens[idx][p][tokenText]) then
                                    p = p + 1
                                    if p > length(iParaTokens[idx]) then
                                        p = length(iParaTokens[idx])
                                        t = length(iParaTokens[idx][p][tokenText])
                                        c = length(iParaTokens[idx][p][tokenText][t])
                                    else
                                        t = 1
                                        c = 0
                                    end if
                                else
                                    if length(iParaTokens[idx][p][tokenText][t]) = 0 then
                                        c = 0
                                    else
                                        c = 1
                                    end if 
                                end if
                            end if
                            te = get_text_extent(whnd, iParaTokens[idx][p][tokenText][t][1..c])
                            
                            iIsSelecting[idx] = 0
                            iCursorState[idx] = 1
                            iSelStartPara[idx] = p
                            iSelStartToken[idx] = t
                            iSelStartChar[idx] = c
                            iSelStartCharX[idx] = te[1]
                            iSelEndPara[idx] = iSelStartPara[idx] 
                            iSelEndToken[idx] = iSelStartToken[idx]
                            iSelEndChar[idx] = iSelStartChar[idx] 
                            iSelEndCharX[idx] = iSelStartCharX[idx]
                            draw(iName[idx], 1)
                            
                        elsif iCmdQueue[idx][1][2][1] = moveHome then
                            
                        elsif iCmdQueue[idx][1][2][1] = moveEnd then
                            
                        elsif iCmdQueue[idx][1][2][1] = movePageUp then
                            
                        elsif iCmdQueue[idx][1][2][1] = movePageDown then
                            
                        end if
                        
                    case cmdScroll then --iCmdQueue[idx][1][2] = {x, y}
                        iScrollX[idx] = iCmdQueue[idx][1][2][1]
                        iScrollY[idx] = iCmdQueue[idx][1][2][2]
                        
                        draw(iName[idx], 1)
                        
                    case cmdUndo then --iCmdQueue[idx][1][2] = {}
                        
                    case cmdRedo then --iCmdQueue[idx][1][2] = {}
                    
                    case cmdResize then --iCmdQueue[idx][1][2] = rebuild_paragraphs
                        iParaPos[idx] = repeat(0, length(iParaTokens[idx]))
                        iParaSize[idx] = repeat(0, length(iParaTokens[idx]))
                        
                        arrange_tokens(idx, 0)
                end switch
                
                if idx > 0 then
                    iCmdQueue[idx] = iCmdQueue[idx][2..$]
                end if
            end if
        end if
        --task_suspend(task_self())
        task_schedule(ProcessTask, 100)
        task_yield()
    end while
end procedure


task_schedule(ProcessTask, 100)
task_schedule(CursorBlinkTask, {0.5, 0.6})

export procedure call_cmd(sequence iname, atom cmdid, object cmddata)
    atom idx = find(iname, iName)
    if idx > 0 then
        --Cancel old commands for command types that are not accumulative:
        if find(cmdid, {cmdStartSelection, cmdHoverToken, cmdEndSelection, cmdScroll, cmdResize}) then
            for c = 1 to length(iCmdQueue[idx]) do
                if iCmdQueue[idx][c][1] = cmdid then
                    iCmdQueue[idx][c][1] = cmdCancelled
                end if
            end for
        end if
        
        iCmdQueue[idx] &= {{cmdid, cmddata}}
        
        /*if iBusyStatus[idx] = 0 then
            iBusyTime[idx] = time()
            iBusyStatus[idx] = 1
            gui:wproc(iCanvasName[idx], "set_background_pointer", {"Busy"})
        end if*/
    end if
end procedure



export procedure create(sequence wprops)
    object nText    = "",
    
    nName           = "",
    nCanvasName     = "",
    nParentName     = "",
    nLabel          = "", 
    
    nSyntaxMode     = synPlain,
    nEditMode       = emNormal,
    nLineNumbers    = 1,
    nLocked         = 0,
    nWordWrap       = 1,
    
    nTokenStyles    = {     --each token type: {tsBackColor, tsTextColor, tsBold, tsItalic, tsUnderline}
        {thBackColor, rgb(0, 0, 0), 0, 0, 0},  --ttNone
        {thBackColor, rgb(0, 0, 0), 0, 0, 0},  --ttInvalid
        {thBackColor, rgb(0, 0, 0), 0, 0, 0},  --ttFound
        {thBackColor, rgb(0, 0, 0), 0, 0, 0},  --ttIdentifier
        {thBackColor, rgb(0, 0, 0), 0, 0, 0},  --ttKeyword
        {thBackColor, rgb(0, 0, 0), 0, 0, 0},  --ttBuiltin
        {thBackColor, rgb(0, 0, 0), 0, 0, 0},  --ttNumber
        {thBackColor, rgb(0, 0, 0), 0, 0, 0},  --ttSymbol
        {thBackColor, rgb(0, 0, 0), 0, 0, 0},  --ttBracket
        {thBackColor, rgb(0, 0, 0), 0, 0, 0},  --ttString
        {thBackColor, rgb(0, 0, 0), 0, 0, 0}   --ttComment
    },
    nSyntaxFont     = "DejaVu Sans Mono",
    nSyntaxSize     = 12
    
    for p = 1 to length(wprops) do
        if length(wprops[p]) = 2 then
            switch wprops[p][1] do         
                case "name" then
                    nName = wprops[p][2]
                    
                case "label" then
                    nLabel = wprops[p][2]
                    
                case "text" then
                    nText = wprops[p][2]
                    
                case "syntax_mode" then
                    if equal(text:lower(wprops[p][2]), "euphoria") then
                        nSyntaxMode = synEuphoria
                    elsif equal(text:lower(wprops[p][2]), "creole") then
                        nSyntaxMode = synCreole
                    elsif equal(text:lower(wprops[p][2]), "html") then
                        nSyntaxMode = synHTML
                    elsif equal(text:lower(wprops[p][2]), "css") then
                        nSyntaxMode = synCSS
                    elsif equal(text:lower(wprops[p][2]), "xml") then
                        nSyntaxMode = synXML
                    elsif equal(text:lower(wprops[p][2]), "ini") then
                        nSyntaxMode = synINI
                    elsif equal(text:lower(wprops[p][2]), "c") then
                        nSyntaxMode = synC
                    end if
                    
                case "edit_mode" then
                    if equal(text:lower(wprops[p][2]), "normal") then
                        nEditMode = emNormal
                    elsif equal(text:lower(wprops[p][2]), "block") then
                        nEditMode = emBlock
                    elsif equal(text:lower(wprops[p][2]), "table") then
                        nEditMode = emTable 
                    end if
                    
                case "line_numbers" then
                    nLineNumbers = wprops[p][2]
                    
                case "locked" then
                    nLocked = wprops[p][2]
                /*    
                case "word_wrap" then
                    nWordWrap = wprops[p][2]
                    
                case "token_styles" then
                    nTokenStyles = wprops[p][2]
                    
                case "syntax_font" then
                    nSyntaxFont = wprops[p][2]
                    
                case "syntax_size" then
                    nSyntaxSize = wprops[p][2]
                */
                    
            end switch
        end if
    end for
    
    iName           &= {nName}
    iCanvasName     &= {nCanvasName}
    iParentName     &= {nParentName}
    iLabel          &= {nLabel}
    
    iSyntaxMode     &= {nSyntaxMode}
    iEditMode       &= {nEditMode}
    iLineNumbers    &= {nLineNumbers}
    iLocked         &= {nLocked}
    iWordWrap       &= {nWordWrap}
    
    iTokenStyles    &= {nTokenStyles}
    iSyntaxFont     &= {nSyntaxFont}
    iSyntaxSize     &= {nSyntaxSize}
    
    iParaTokens     &= {{{
        {""},   --tokenText
        {0},    --tokenPos
        {0},    --tokenSize
        {0},    --tokenType
        {0}     --tokenInfo
    }}}
    iParaBookmark   &= {{0}}
    iParaFold       &= {{0}}
    iParaTag        &= {{0}}
    iParaPos        &= {{0}}
    iParaSize       &= {{0}}
    
    iCursorState    &= {0}
    iIsSelecting    &= {0}
    iSelStartPara   &= {1}
    iSelStartToken  &= {1}
    iSelStartChar   &= {0}
    iSelStartCharX  &= {0}
    iSelEndPara     &= {1}
    iSelEndToken    &= {1}
    iSelEndChar     &= {0}
    iSelEndCharX    &= {0}
    iScrollX        &= {0}
    iScrollY        &= {0}

    iLineNumWidth   &= {0}
    iTotalHeight    &= {0}
    iTotalWidth     &= {0}
    
    iBusyStatus     &= {0}
    iBusyTime       &= {0}
    iCmdQueue       &= {{}}
    iUndoQueue      &= {{}}
    
    if length(nText) > 0 then
        set_text(nName, nText)
    end if
end procedure



export procedure destroy(sequence iname)
    atom idx = find(iname, iName)
    if idx > 0 then
        call_cmd(iname, cmdDestroyEditor, {})
    end if
end procedure


procedure draw(sequence iname, atom drawmode)
    atom idx = find(iname, iName)
    if idx > 0 then
        if drawmode = 0 then     --draw current line only
            
        elsif drawmode = 1 then --draw entire visible area
            atom bwidth = iLineNumWidth[idx],
            ih = thMonoFontSize+4
            sequence tokens, tokstyle,
            csize = gui:wfunc(iCanvasName[idx], "get_canvas_size", {}),
            brect = {0, 0, bwidth, csize[2]},
            trect = {bwidth, 0, csize[1], csize[2]},
            ccmds = {   --cursor commands
                --{DR_PenColor, rgb(0, 0, 0)},
                --{DR_Line, cx, cy, cx, cy+ih}
            },
            bcmds = {
                {DR_PenColor, th:cButtonFace},
                {DR_Rectangle, True, brect[1], brect[2], brect[3], brect[4]}
            },
            tcmds = {   --text area commands
                {DR_PenColor, thBackColor},
                {DR_Rectangle, True, trect[1], trect[2], trect[3], trect[4]}
                --{DR_TextColor, th:cButtonLabel},
                --{DR_Font, thMonoFont, thMonoFontSize, Normal}
                --{DR_Restrict, trect[1], trect[2], trect[3], trect[4]}
            },
            lcmds = {   --line number, bookmark, folding (margin) area commands
                --{DR_Release},
                {DR_TextColor, th:cButtonLabel},
                {DR_Font, thMonoFont, thMonoFontSize, Normal}
            },
            hshape = {  --handle shape for line number, bookmark, folding (margin) area
                {DR_Rectangle, True, brect[1], brect[2], brect[3], brect[4]}
            }
            
            atom px, py,
            lnx = brect[1] + thMonoFontSize + 6,
            vtop = 0,             --top of visible area
            vbottom = csize[2],  --bottom of visible area
            --todo: detect whether 'start' is before or after 'end'
            selmode,
            selSp, selSt, selSc, selScX, selEp, selEt, selEc, selEcX
            
            if iSelStartPara[idx] > iSelEndPara[idx] then
                selSp = iSelEndPara[idx]      
                selSt = iSelEndToken[idx]     
                selSc = iSelEndChar[idx]      
                selScX = iSelEndCharX[idx]    
                selEp = iSelStartPara[idx]    
                selEt = iSelStartToken[idx]   
                selEc = iSelStartChar[idx]    
                selEcX = iSelStartCharX[idx]
                
            elsif iSelStartPara[idx] = iSelEndPara[idx] and iSelStartToken[idx] > iSelEndToken[idx] then
                selSp = iSelStartPara[idx]
                selSt = iSelEndToken[idx]
                selSc = iSelEndChar[idx]
                selScX = iSelEndCharX[idx]
                selEp = iSelEndPara[idx]
                selEt = iSelStartToken[idx]
                selEc = iSelStartChar[idx]
                selEcX = iSelStartCharX[idx]
            elsif iSelStartPara[idx] = iSelEndPara[idx] and iSelStartToken[idx] = iSelEndToken[idx] and iSelStartChar[idx] > iSelEndChar[idx] then
                selSp = iSelStartPara[idx]
                selSt = iSelStartToken[idx]
                selSc = iSelEndChar[idx]
                selScX = iSelEndCharX[idx]
                selEp = iSelEndPara[idx]
                selEt = iSelEndToken[idx]
                selEc = iSelStartChar[idx]
                selEcX = iSelStartCharX[idx]
            else
                selSp = iSelStartPara[idx]
                selSt = iSelStartToken[idx]
                selSc = iSelStartChar[idx]
                selScX = iSelStartCharX[idx]
                selEp = iSelEndPara[idx]
                selEt = iSelEndToken[idx]
                selEc = iSelEndChar[idx]
                selEcX = iSelEndCharX[idx]
            end if
            
            
            for p = 1 to length(iParaTokens[idx]) do
                tokens = iParaTokens[idx][p]
                px = iParaPos[idx][p][1] - iScrollX[idx]
                py = iParaPos[idx][p][2] - iScrollY[idx]
                
                --find paragraphs that are within view
                if py + iParaSize[idx][p][2] >= vtop and py < vbottom then
                    --append line number drawing commands
                    lcmds &= {
                        {DR_PenPos, lnx, py},
                        {DR_Puts, sprintf("%d", {p})}
                    }
                    if iParaBookmark[idx][p] = 1 then
                        lcmds &= {  --draw bookmark symbol
                            {DR_PenColor, rgb(180, 180, 250)},
                            {DR_RoundRect, True, brect[1]+2, py+1, brect[1]+ih, py+ih-1, ih, ih}
                        }
                    end if
                    if iParaFold[idx][p] = 1 then
                        lcmds &= {  --draw fold symbol
                            {DR_PenColor, rgb(128, 128, 128)},
                            {DR_Rectangle, False, brect[3]-ih, py+1, brect[3]-2, py+ih-1},
                            {DR_Line, floor((brect[3]-ih + brect[3]-2) / 2), py+1+2, floor((brect[3]-ih + brect[3]-2) / 2), py+ih-1-2},
                            {DR_Line, brect[3]-ih+2, floor((py+1 + py+ih-1) / 2), brect[3]-2-2, floor((py+1 + py+ih-1) / 2)}
                        }
                    end if
                    if debugparagraphs = 1 then
                        tcmds &= {
                                --paragraph border rectangle, for debugging:
                                {DR_PenColor, rgb(155, 0, 155)},
                                {DR_Rectangle, False, 
                                    px, py,
                                    px + iParaSize[idx][p][1], py + iParaSize[idx][p][2]}
                        }
                    end if
                    
                    for t = 1 to length(tokens[tokenText]) do
                        if py + tokens[tokenPos][t][2]+tokens[tokenSize][t][2] >= vtop and py + tokens[tokenPos][t][2] < vbottom then
                            /*tokens[tokenText]
                            tokens[tokenPos]
                            tokens[tokenSize]
                            tokens[tokenType]
                            tokens[tokenInfo]*/
                            --append token drawing commands
                            if debugtokens = 1 then
                                tcmds &= {
                                    --token border rectangle, for debugging:
                                    {DR_PenColor, rgb(0, 155, 155)},
                                    {DR_Rectangle, False, 
                                        px + tokens[tokenPos][t][1], py + tokens[tokenPos][t][2],
                                        px + tokens[tokenPos][t][1]+tokens[tokenSize][t][1], py + tokens[tokenPos][t][2]+tokens[tokenSize][t][2]}
                                }
                            end if
                            
                            selmode = 0
                            if selSp = selEp then
                                if p = selSp then
                                    if selSt = selEt then
                                        if t = selSt then
                                            selmode = 4
                                        end if
                                    else
                                        if t = selSt then
                                            selmode = 1
                                        elsif t > selSt and t < selEt then
                                            selmode = 2
                                        elsif t = selEt then
                                            selmode = 3
                                        end if
                                    end if
                                end if
                            else
                                if p = selSp then
                                    if t = selSt then
                                        selmode = 1
                                    elsif t > selSt then
                                        selmode = 2
                                    end if
                                elsif p > selSp and p < selEp then
                                    selmode = 2
                                elsif p = selEp then
                                    if t < selEt then
                                        selmode = 2
                                    elsif t = selEt then
                                        selmode = 3
                                    end if
                                end if
                            end if
                            
                            tokstyle = ttStyles[tokens[tokenType][t]]
                            
                            if tokens[tokenType][t] = ttBracket and tokens[tokenInfo][t] > 0 then
                                tokstyle[4] = pick_color(tokens[tokenInfo][t])
                            end if
                            
                            
                            if selmode = 0 then --no selection
                                tcmds &= {
                                    --unselected text: 
                                    {DR_TextColor, tokstyle[4]},
                                    {DR_Font, tokstyle[1], tokstyle[2], tokstyle[3]},
                                    {DR_PenPos, px + tokens[tokenPos][t][1], py + tokens[tokenPos][t][2]},
                                    {DR_Puts, tokens[tokenText][t]}
                                }
                            elsif selmode = 1 then --beginning of selection
                                tcmds &= {
                                    --unselected text: 
                                    {DR_TextColor, tokstyle[4]},
                                    {DR_Font, tokstyle[1], tokstyle[2], tokstyle[3]},
                                    {DR_PenPos, px + tokens[tokenPos][t][1], py + tokens[tokenPos][t][2]},
                                    {DR_Puts, tokens[tokenText][t][1..selSc]},
                                    --selection background:
                                    {DR_PenColor, rgb(200, 200, 255)},
                                    {DR_Rectangle, True, 
                                        px + tokens[tokenPos][t][1] + selScX,
                                        py + tokens[tokenPos][t][2],
                                        px + tokens[tokenPos][t][1] + tokens[tokenSize][t][1],
                                        py + tokens[tokenPos][t][2] + tokens[tokenSize][t][2]
                                    },
                                    --selected text: 
                                    {DR_TextColor, rgb(0, 0, 0)},
                                    {DR_Font, tokstyle[1], tokstyle[2], tokstyle[3]},
                                    {DR_PenPos, px + tokens[tokenPos][t][1] + selScX, py + tokens[tokenPos][t][2]},
                                    {DR_Puts, tokens[tokenText][t][selSc+1..$]}
                                }
                                
                            elsif selmode = 2 then --middle of selection
                                tcmds &= {
                                    --selection background:
                                    {DR_PenColor, rgb(200, 200, 255)},
                                    {DR_Rectangle, True, 
                                        px + tokens[tokenPos][t][1],
                                        py + tokens[tokenPos][t][2],
                                        px + tokens[tokenPos][t][1] + tokens[tokenSize][t][1],
                                        py + tokens[tokenPos][t][2] + tokens[tokenSize][t][2]
                                    },
                                    --selected text: 
                                    {DR_TextColor, rgb(0, 0, 0)},
                                    {DR_Font, tokstyle[1], tokstyle[2], tokstyle[3]},
                                    {DR_PenPos, px + tokens[tokenPos][t][1], py + tokens[tokenPos][t][2]},
                                    {DR_Puts, tokens[tokenText][t]}
                                }
                            elsif selmode = 3 then --end of selection
                                tcmds &= {
                                    --selection background:
                                    {DR_PenColor, rgb(200, 200, 255)},
                                    {DR_Rectangle, True, 
                                        px + tokens[tokenPos][t][1],
                                        py + tokens[tokenPos][t][2],
                                        px + tokens[tokenPos][t][1] + selEcX,
                                        py + tokens[tokenPos][t][2] + tokens[tokenSize][t][2]
                                    },
                                    --selected text: 
                                    {DR_TextColor, rgb(0, 0, 0)},
                                    {DR_Font, tokstyle[1], tokstyle[2], tokstyle[3]},
                                    {DR_PenPos, px + tokens[tokenPos][t][1], py + tokens[tokenPos][t][2]},
                                    {DR_Puts, tokens[tokenText][t][1..selEc]},
                                    --unselected text: 
                                    {DR_TextColor, tokstyle[4]},
                                    {DR_Font, tokstyle[1], tokstyle[2], tokstyle[3]},
                                    {DR_PenPos, px + tokens[tokenPos][t][1] + selEcX, py + tokens[tokenPos][t][2]},
                                    {DR_Puts, tokens[tokenText][t][selEc+1..$]}
                                }
                            elsif selmode = 4 then --start and end of selection in the same token
                                tcmds &= {
                                    --unselected text: 
                                    {DR_TextColor, tokstyle[4]},
                                    {DR_Font, tokstyle[1], tokstyle[2], tokstyle[3]},
                                    {DR_PenPos, px + tokens[tokenPos][t][1], py + tokens[tokenPos][t][2]},
                                    {DR_Puts, tokens[tokenText][t]},
                                    --selection background:
                                    {DR_PenColor, rgb(200, 200, 255)},
                                    {DR_Rectangle, True, 
                                        px + tokens[tokenPos][t][1] + selScX,
                                        py + tokens[tokenPos][t][2],
                                        px + tokens[tokenPos][t][1] + selEcX,
                                        py + tokens[tokenPos][t][2] + tokens[tokenSize][t][2]
                                    },
                                    --selected text: 
                                    {DR_TextColor, rgb(0, 0, 0)},
                                    {DR_Font, tokstyle[1], tokstyle[2], tokstyle[3]},
                                    {DR_PenPos, px + tokens[tokenPos][t][1] + selScX, py + tokens[tokenPos][t][2]},
                                    {DR_Puts, tokens[tokenText][t][selSc+1..selEc]}
                                }
                            end if
                        end if
                    end for
                    if time() - iBusyTime[idx] > 0.5 then
                        iBusyStatus[idx] = 1
                        gui:wproc(iCanvasName[idx], "set_background_pointer", {"Busy"})
                        task_yield()
                        --iBusyTime[idx] = time()
                    end if
                end if
            end for
            
            /*atom whnd = gui:widget_get_handle(iCanvasName[idx])
            set_font(whnd, thMonoFont, 16, 0)
            sequence dtxt = "Refresh time: " & sprint(time() - iBusyTime[idx]) & "s",
            dsize = get_text_extent(whnd, dtxt),
            dcmds = { --debugging/performance info
                {DR_PenColor, rgb(80, 80, 80)},
                {DR_Rectangle, True, 10-2, 10-2, 10+dsize[1]+2, 10+dsize[2]+2}, 
                {DR_TextColor, rgb(255, 255, 0)},
                {DR_Font, thMonoFont, 16, Normal},
                {DR_PenPos, 10, 10},
                {DR_Puts, dtxt}
            }
            gui:wproc(iCanvasName[idx], "draw_foreground", {dcmds})
            */
            
            gui:wproc(iCanvasName[idx], "draw_background", {tcmds & bcmds & lcmds})
            
            --gui:wproc(iCanvasName[idx], "clear_handles", {})
            gui:wproc(iCanvasName[idx], "set_handle", {"lineheaders", hshape, "Arrow"})
            
            iBusyStatus[idx] = 0
            iBusyTime[idx] = 0
            gui:wproc(iCanvasName[idx], "set_background_pointer", {"Ibeam"})
            
        end if
        if drawmode = 1 or drawmode = 2 then --draw cursor only
            atom p, t, c, px, py
            sequence tokens, ccmds
            
            ccmds = {}
            /*
            p = iSelStartPara[idx]
            t = iSelStartToken[idx]
            c = iSelStartChar[idx]
            if p > 0 and p <= length(iParaTokens[idx]) then
                tokens = iParaTokens[idx][p]
                px = iParaPos[idx][p][1] - iScrollX[idx]
                py = iParaPos[idx][p][2] - iScrollY[idx]
                if t > 0 and t <= length(tokens[tokenText]) then
                    ccmds &= {
                        {DR_PenColor, rgb(200, 0, 0)},
                        {DR_Rectangle, False, 
                            px + tokens[tokenPos][t][1],
                            py + tokens[tokenPos][t][2],
                            px + tokens[tokenPos][t][1] + tokens[tokenSize][t][1],
                            py + tokens[tokenPos][t][2] + tokens[tokenSize][t][2]
                        },
                        {DR_Line, 
                            px + tokens[tokenPos][t][1] + iSelStartCharX[idx],
                            py + tokens[tokenPos][t][2],
                            px + tokens[tokenPos][t][1] + iSelStartCharX[idx],
                            py + tokens[tokenPos][t][2] + tokens[tokenSize][t][2]
                        }
                    }
                end if
            end if*/
            
            if iCursorState[idx] = 1 and iLocked[idx] = 0 then
                p = iSelEndPara[idx]
                t = iSelEndToken[idx]
                c = iSelEndChar[idx]
                if p > 0 and p <= length(iParaTokens[idx]) then
                    tokens = iParaTokens[idx][p]
                    px = iParaPos[idx][p][1] - iScrollX[idx]
                    py = iParaPos[idx][p][2] - iScrollY[idx]
                    if t > 0 and t <= length(tokens[tokenText]) then
                        ccmds &= {
                            {DR_PenColor, rgb(0, 0, 200)},
                            /*{DR_Rectangle, False, 
                                px + tokens[tokenPos][t][1],
                                py + tokens[tokenPos][t][2],
                                px + tokens[tokenPos][t][1] + tokens[tokenSize][t][1],
                                py + tokens[tokenPos][t][2] + tokens[tokenSize][t][2]
                            },*/
                            {DR_Line, 
                                px + tokens[tokenPos][t][1] + iSelEndCharX[idx],
                                py + tokens[tokenPos][t][2],
                                px + tokens[tokenPos][t][1] + iSelEndCharX[idx],
                                py + tokens[tokenPos][t][2] + tokens[tokenSize][t][2]
                            }
                        }
                    end if
                    --? {p, t, c, iSelEndCharX[idx]}
                end if
            end if
            gui:wproc(iCanvasName[idx], "draw_foreground", {ccmds})
        end if
    end if
end procedure



export procedure show(sequence iname, sequence cname, sequence cparent)
    atom idx = find(iname, iName)
    if idx > 0 then
        if gui:wexists(iname) then
            gui:wdestroy(iname)
        end if
        
        atom inuse = find(cname, iCanvasName) --if a text editor is already using this canvas, then unlink it
        if inuse > 0 then
            iCanvasName[inuse] = ""
            iParentName[inuse] = ""
        end if
        iCanvasName[idx] = cname
        iParentName[idx] = cparent
        
        gui:wcreate({
            {"name", cname},
            {"parent", cparent},
            {"class", "canvas"},
            {"label", iLabel[idx]},
            {"scroll_foreground", 0},
            {"background_pointer", "Ibeam"},
            {"handler", routine_id("textedit_event_handler")}
        })
        
        gui:wproc(iCanvasName[idx], "set_background_pointer", {"Busy"})
        
    end if
end procedure


export procedure hide(sequence iname)
    atom idx = find(iname, iName)
    if idx > 0 then
        if gui:wexists(iname) then
            gui:wdestroy(iname)
            gui:wcreate({
                {"name", iCanvasName[idx]},
                {"parent", iParentName[idx]},
                {"class", "canvas"},
                --{"label", ""},
                {"background_pointer", "Ibeam"},
                {"handler", routine_id("textedit_event_handler")}
            })
        end if
        
        iCanvasName[idx] = ""
        iParentName[idx] = ""
    end if
end procedure


export procedure set_text(sequence iname, sequence txt)
    atom idx = find(iname, iName)
    if idx > 0 then
        call_cmd(iname, cmdSetSelection, {selAll})
        call_cmd(iname, cmdInsertText, txt)
    else
        --todo: report error to debug console: text editor <iname> does not exist
    end if
end procedure


export procedure append_text(sequence iname, sequence txt)
    atom idx = find(iname, iName)
    if idx > 0 then
        call_cmd(iname, cmdMoveCursor, {-2, -2})
        call_cmd(iname, cmdInsertText, txt)
    end if
end procedure


export procedure clear_text(sequence iname)
    atom idx = find(iname, iName)
    if idx > 0 then
        call_cmd(iname, cmdSetSelection, {selAll})
        call_cmd(iname, cmdInsertText, 46)
    end if
end procedure


procedure textedit_event_handler(object evwidget, object evtype, object evdata)
    atom idx = find(evwidget, iCanvasName)
    if idx > 0 then
        switch evtype do
            case "resized" then
                call_cmd(iName[idx], cmdResize, {})
                
            case "handle" then  --evdata = {"HandleName", "EventType", data1, data2})
                
                if length(evdata[1]) = 0 then --background area
                    switch evdata[2] do
                        case "MouseMove" then
                            call_cmd(iName[idx], cmdHoverToken, {evdata[3], evdata[4]})
                            
                        case "LeftDown" then
                            call_cmd(iName[idx], cmdStartSelection, {evdata[3], evdata[4]})
                            
                        case "LeftUp" then
                            call_cmd(iName[idx], cmdEndSelection, {evdata[3], evdata[4]})
            
                        case "RightDown" then
                            
                            
                        case "RightUp" then
                            
                            
                    end switch
                    
                elsif equal(evdata[1], "lineheaders") then
                    /*if equal(evdata[2], "MouseMove") then --evdata = {"handle", {hname, "MouseMove", mx, my}}
                        grect = graphs[grRect][gr[i]]
                        if gui:in_rect(evdata[3], evdata[4], grect) then --in_rect(atom xpos, atom ypos, sequence rect)
                            cmds &= {
                                {DR_PenColor, rgb(255, 127, 127)},
                                {DR_Line, grect[1], evdata[4], grect[3], evdata[4]},
                                {DR_Line, evdata[3], grect[2], evdata[3], grect[4]}
                            }
                        end if
                    end if
                    
                    --call_proc(htForms[fPropHandler][idx], {evwidget, evtype, evdata[1]})
                    call_cmd(iName[idx], cmdHoverToken, {evdata[1], evdata[2]})
                    */
                end if
            
            case "KeyDown" then
                if evdata[1] = 37 then --left
                    call_cmd(iName[idx], cmdMoveCursor, {moveLeft, 1})
                elsif evdata[1] = 39 then --right
                    call_cmd(iName[idx], cmdMoveCursor, {moveRight, 1})
                elsif evdata[1] = 38 then --up
                    call_cmd(iName[idx], cmdMoveCursor, {moveUp, 1})
                elsif evdata[1] = 40 then --down
                    call_cmd(iName[idx], cmdMoveCursor, {moveDown, 1})
                elsif evdata[1] = 33 then --pgup
                    call_cmd(iName[idx], cmdMoveCursor, {movePageUp, 1})
                elsif evdata[1] = 34 then --pgdown
                    call_cmd(iName[idx], cmdMoveCursor, {movePageDown, 1})
                elsif evdata[1] = 36 then --home
                    call_cmd(iName[idx], cmdMoveCursor, {moveHome, 1})
                elsif evdata[1] = 35 then --end
                    call_cmd(iName[idx], cmdMoveCursor, {moveEnd, 1})
                elsif evdata[1] = 8 and iLocked[idx] = 0 then --backspace
                    call_cmd(iName[idx], cmdInsertText, 8)
                elsif evdata[1] = 46 and iLocked[idx] = 0 then --delete
                    call_cmd(iName[idx], cmdInsertText, 46)
                end if
                
            case "KeyPress" then
                if evdata[1] = 13 and iLocked[idx] = 0 then --newline
                    call_cmd(iName[idx], cmdInsertText, 13)
                elsif evdata[1] > 13 and iLocked[idx] = 0 then --normal character
                    call_cmd(iName[idx], cmdInsertText, evdata[1])
                end if
                                
                
            --case "destroyed" then
            
            case "scroll" then
                --? evdata
                --draw(iName[idx], 1)
                call_cmd(iName[idx], cmdScroll, {evdata[1], evdata[2]})
                
        end switch
    end if
end procedure
























