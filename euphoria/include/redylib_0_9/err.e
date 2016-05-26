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


--Error and warning message library

--errors can be displayed in the gui, console, or logged in a debug log.


include std/io.e
include std/datetime.e as dt
include std/text.e
include std/pretty.e
include std/error.e
include std/filesys.e

include euphoria/info.e


atom WarnProc = 0, DieProc = 0
object ErrLogFile = 0
sequence errLog = {}


function reset_dir(integer dummy)
    sequence cmdline = command_line()
    chdir(pathname(cmdline[2]))

    return 0 and dummy
end function
crash_routine(routine_id("reset_dir"))


procedure append_error_log(sequence errdata, sequence errnicetxt)
    errLog &= {errdata}
    
    if sequence(ErrLogFile) then
        --fn = open(ErrLogFile, "a")
        --puts(fn, errnicetxt)
        --close(fn)
    end if
end procedure


/* --this doesn't work :-( windows stop responding for some reason.
function crash_report(integer dummy)
    die("Program", "Runtime Error", "ex.err") --read_file("ex.err"))
    
    task_schedule(task_self(), {0.1, 0.5})
    
    while 1 do
        task_yield()
    end while
    
    return 0 and dummy
end function
*/


-- Public Routines ------------------------------------------------------------


public procedure warn(sequence errorigin, sequence errmsgtxt, object errdebugdata = 0)
    --throw a warning (non-critical exception)
    sequence errtime = dt:format(dt:now(), "%Y-%m-%d %H:%M:%S")
    sequence errnicetxt, errdata
    
    errdata = {errtime, "warn", errorigin, errmsgtxt, errdebugdata}
    errnicetxt = "[" & errtime & "] Warning: " & errorigin & ": " & errmsgtxt & ", Debug Data = " & pretty_sprint(errdebugdata, {2}) & "\n"
    
    append_error_log(errdata, errnicetxt)
    
    ifdef debug then
        if WarnProc > 0 then
            call_proc(WarnProc, {errdata, errnicetxt})
        else
            puts(1, errnicetxt)
        end if
    end ifdef
end procedure


public procedure die(sequence errorigin, sequence errmsgtxt, object errdebugdata = 0)
    --throw a critical exception, and cause program to quit as gracefully as possible.
    sequence errtime = dt:format(dt:now(), "%Y-%m-%d %H:%M:%S")
    sequence errnicetxt, errdata
    
    errdata = {errtime, "die", errorigin, errmsgtxt, errdebugdata}
    errnicetxt = "[" & errtime & "] ERROR: " & errorigin & ": " & errmsgtxt & ", Debug Data = " & pretty_sprint(errdebugdata, {2}) & "\n"
    
    append_error_log(errdata, errnicetxt)
    
    if DieProc > 0 then
        call_proc(DieProc, {errdata, errnicetxt})
    else
        crash(errnicetxt)
    end if
end procedure


public procedure set_warn_callback(atom warnrid)
    WarnProc = warnrid
end procedure


public procedure set_die_callback(atom dierid)
    if dierid > 0 then
        --crash_routine(routine_id("crash_report"))
    end if
    DieProc = dierid
end procedure


public procedure set_error_log_file(object logfile = 0)
    if sequence(logfile) and file_exists(logfile) then
        ErrLogFile = logfile
    else
        ErrLogFile = 0
    end if
end procedure


public function get_errors(sequence errcount = 1, object errtype = 0, object errorigin = 0)
--return one or more error messages, with optional filter for error type ("warn" or "die") or origin.
--if errcount = 0, then return all matching error messages, if errcount > 0, return specified number
--of matching messages.

    object errmsgs = {}
    atom ecount = 0, ismatch = 0
    for e = length(errLog) to 1 by -1 do
        ismatch = 0
        if atom(errtype) and atom(errorigin) then
            ismatch = 1
        elsif atom(errtype) and equal(errorigin, errLog[e][2]) then
            ismatch = 1
        elsif equal(errtype, errLog[e][1]) and atom(errorigin) then
            ismatch = 1
        elsif equal(errtype, errLog[e][1]) and equal(errorigin, errLog[e][2]) then
            ismatch = 1
        end if
        if ismatch then
            errmsgs &= {errLog[e]}
            ecount += 1
        end if
        if errcount > 0 and ecount = errcount then
            exit
        end if
    end for
    
    return errmsgs
end function

