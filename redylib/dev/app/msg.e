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


--Subscribe/Publish message system 

include std/text.e
include std/pretty.e
include std/error.e
include euphoria/info.e

sequence
tNames = {},
tSubscriberNames = {},
tSubscriberRids = {}

atom debugRid = 0


public procedure publish(sequence subscribername, sequence topicname, sequence msgname, object msgdata)
--sync data with other subscribers in group
--note: subscriber's handler function must return 1 to indicate success
    atom idx = find(topicname, tNames), result
    sequence errlist = {}
    if idx > 0 then
        for s = 1 to length(tSubscriberNames[idx]) do
            --if not equal(tSubscriberNames[idx][s], subscribername) then
            if tSubscriberRids[idx][s] > 0 then
                --puts(1, "subscribername = " & subscribername & ", topicname = " & topicname & ", msgname = " & msgname & ", msgdata = " & sprint(msgdata) & "\n")
                --? tSubscriberRids[idx][s]
                
                result = call_func(tSubscriberRids[idx][s], {subscribername, topicname, msgname, msgdata})
                if result = 0 then
                    errlist &= {subscribername}
                end if
            end if
            --end if 
        end for
    end if
    if debugRid > 0 then
        call_proc(debugRid, {subscribername, topicname, msgname, msgdata, errlist})
    end if
end procedure


public procedure subscribe(sequence subscribername, sequence topicname, atom msghandlerid)
--subscribe to a sync group to receive sync updates
--note: if the subscriber only needs to publish but not recieve messages, set msgshandlerid = 0
    --puts(1, "subscribername = " & subscribername & ", topicname = " & topicname & ", msghandlerid = " & sprint(msghandlerid) & "\n")
    
    --atom idx = find(subscribername, tSubscriberNames)
    --if idx > 0 then
    --    puts(1, "subscriber already exists")
    --end if
    
    atom idx = find(topicname, tNames)
    if idx > 0 then
        tSubscriberNames[idx] &= {subscribername}
        tSubscriberRids[idx] &= {msghandlerid}
    else
        tNames &= {topicname}
        tSubscriberNames &= {{subscribername}}
        tSubscriberRids &= {{msghandlerid}}
    end if
    --puts(1, "tNames=" & sprint(tNames) & "\n")
    --puts(1, "tSubscriberNames=" & sprint(tSubscriberNames) & "\n")
    --puts(1, "tSubscriberRids=" & sprint(tSubscriberRids) & "\n")
end procedure


public procedure unsubscribe(sequence subscribername, sequence topicname)
--unsubscribe from a sync group
    atom idx = find(topicname, tNames)
    if idx > 0 then
        tNames = remove(tNames, idx)
        tSubscriberNames = remove(tSubscriberNames, idx)
        tSubscriberRids = remove(tSubscriberRids, idx)
    end if
end procedure


public function list_groups()
--list all sync groups
    return tNames
end function


public function list_subscribers(sequence topicname)
--list all subscribers in a specified sync group
    atom idx = find(topicname, tNames)
    if idx > 0 then
        return tSubscriberNames[idx]
    else
        return 0
    end if
end function


public procedure debug(atom debughandlerid)
--register a routine to be called for debug messages
    debugRid = debughandlerid
end procedure

