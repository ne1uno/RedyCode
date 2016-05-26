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


--Application Configuration (remember window position, user preferences, etc.)


include redylib_0_9/err.e as err

include std/sequence.e as seq
include std/convert.e
include std/text.e
include std/pretty.e
include std/error.e
include std/filesys.e


sequence cfgVars = {{}, {}, {}, {}}

enum 
iConfigFile,
iSectionName,
iVarName,
iVarData

sequence cmdline = command_line()
sequence DefaultConfigFile = pathname(cmdline[2]) & "\\" & filebase(cmdline[2]) & ".cfg"

global sequence ExePath = pathname(cmdline[2])


export procedure set_default_file(sequence fname)
    --example:  cfg:set_default_file(app:info("path") & "\\" & app:info("name") & ".cfg")
    DefaultConfigFile = fname
end procedure


export procedure load_config(sequence fname)
    if length(fname) = 0 then
        fname = DefaultConfigFile
    end if
    atom idx = find(fname, cfgVars[iConfigFile])
    if idx = 0 then
        cfgVars[iConfigFile] &= {fname}
        cfgVars[iSectionName] &= {{}}
        cfgVars[iVarName] &= {{}}
        cfgVars[iVarData] &= {{}}
        idx = length(cfgVars[iConfigFile])
    end if
    
    atom fn, eq
    object ln, cdata = {}, vdata
    sequence csection = "", vname
    
    fn = open(fname, "r")
    if fn = -1 then
        err:warn("config.e", "Unable to read config file \"" & fname & "\".")
    else
        while 1 do
            ln = gets(fn)
            if sequence(ln) then
                ln = trim_head(ln)
                ln = trim_tail(ln)
                ln = seq:filter(ln, "in",  {32,255}, "[]")
                cdata &= {ln}
            else
                exit
            end if
        end while
        close(fn)
    end if
    
    --pretty_print(1, cdata)
    
    for i = 1 to length(cdata) do
        if length(cdata[i]) > 2 and cdata[i][1] = '['  and cdata[i][$] = ']' then
            csection = cdata[i][2..$-1]
            --puts(1, csection)
        elsif length(cdata[i]) > 0 and find(cdata[i][1], ";#") then --comment
        else
            eq = find('=', cdata[i])
            if eq > 1 and eq < length(cdata[i])-1 then
                vname = cdata[i][1..eq-1]
                vname = trim_tail(vname)
                vdata = cdata[i][eq+1..$]
                vdata = trim_head(vdata)
                if vdata[1] = '\"' and vdata[$] = '\"' then
                    vdata = vdata[2..$-1]
                    cfgVars[iSectionName][idx] &= {csection} 
                    cfgVars[iVarName][idx] &= {vname} 
                    cfgVars[iVarData][idx] &= {vdata}
                else
                    vdata = to_number(vdata)
                    cfgVars[iSectionName][idx] &= {csection} 
                    cfgVars[iVarName][idx] &= {vname} 
                    cfgVars[iVarData][idx] &= {vdata}
                end if
            end if
        end if
    end for
    
    --pretty_print(1, cfgVars[idx])
end procedure


export procedure save_config(sequence fname)
    if length(fname) = 0 then
        fname = DefaultConfigFile
    end if
    atom idx = find(fname, cfgVars[iConfigFile])
    if idx > 0 then
        sequence csection = ""
        object fn
        
        fn = open(fname, "w")
        if fn = -1 then
            err:warn("config.e", "Unable to write config file \"" & fname & "\".")
        else
            for v = 1 to length(cfgVars[iSectionName][idx]) do
                if not equal(cfgVars[iSectionName][idx][v], csection) then
                    csection = cfgVars[iSectionName][idx][v]
                    puts(fn, "[" & csection & "]\n")
                end if
                if atom(cfgVars[iVarData][idx][v]) then
                    puts(fn, cfgVars[iVarName][idx][v] & " = " & sprint(cfgVars[iVarData][idx][v]) & "\n")
                elsif sequence(cfgVars[iVarData][idx][v]) then
                    puts(fn, cfgVars[iVarName][idx][v] & " = \"" & cfgVars[iVarData][idx][v] & "\"\n")
                end if
            end for
            close(fn)
        end if
    end if
end procedure


export procedure close_config(sequence fname)
    if length(fname) = 0 then
        fname = DefaultConfigFile
    end if
    atom idx = find(fname, cfgVars[iConfigFile])
    if idx > 0 then
        cfgVars[iConfigFile][idx] = remove(cfgVars[iConfigFile], idx)
        cfgVars[iSectionName][idx] = remove(cfgVars[iSectionName], idx)
        cfgVars[iVarName][idx] = remove(cfgVars[iVarName], idx)
        cfgVars[iVarData][idx] = remove(cfgVars[iVarData], idx)
    end if
end procedure


export procedure clear_config(sequence fname)
    if length(fname) = 0 then
        fname = DefaultConfigFile
    end if
    atom idx = find(fname, cfgVars[iConfigFile])
    if idx > 0 then
        cfgVars[iSectionName][idx] = {}
        cfgVars[iVarName][idx] = {}
        cfgVars[iVarData][idx] = {}
    end if
end procedure


export procedure delete_section(sequence fname, sequence sectionname)
    if length(fname) = 0 then
        fname = DefaultConfigFile
    end if
    atom idx = find(fname, cfgVars[iConfigFile])
    if idx > 0 then
        atom v = 1
        while v <= length(cfgVars[iSectionName][idx]) do
            if equal(cfgVars[iSectionName][idx][v], sectionname) then
                cfgVars[iSectionName][idx] = remove(cfgVars[iSectionName][idx], v)
                cfgVars[iVarName][idx] = remove(cfgVars[iVarName][idx], v)
                cfgVars[iVarData][idx] = remove(cfgVars[iVarData][idx], v)
            else
                v += 1
            end if
        end while
    end if
end procedure


export function list_sections(sequence fname)
    if length(fname) = 0 then
        fname = DefaultConfigFile
    end if
    atom idx = find(fname, cfgVars[iConfigFile])
    if idx > 0 then
        return remove_dups(cfgVars[iSectionName][idx], RD_INPLACE)
    else
        return {}
    end if
end function


export function list_vars(sequence fname, sequence sectionname)
    if length(fname) = 0 then
        fname = DefaultConfigFile
    end if
    atom idx = find(fname, cfgVars[iConfigFile])
    if idx > 0 then
        sequence varnames = {}
        
        for v = 1 to length(cfgVars[iSectionName][idx]) do
            if equal(cfgVars[iSectionName][idx][v], sectionname) then
                varnames &= {cfgVars[iVarName][idx][v]}
            end if
        end for
        
        return varnames
    else
        return {}
    end if
end function


export function get_var(sequence fname, sequence sectionname, sequence varname)
    if length(fname) = 0 then
        fname = DefaultConfigFile
    end if
    atom idx = find(fname, cfgVars[iConfigFile])
    if idx > 0 then
        object vardata = 0
        
        for v = 1 to length(cfgVars[iSectionName][idx]) do
            if equal(cfgVars[iSectionName][idx][v], sectionname) and equal(cfgVars[iVarName][idx][v], varname) then
                vardata = cfgVars[iVarData][idx][v]
                exit
            end if
        end for
        
        return vardata
    else
        return {}
    end if
end function


export procedure set_var(sequence fname, sequence sectionname, sequence varname, object vardata)
    if length(fname) = 0 then
        fname = DefaultConfigFile
    end if
    atom idx = find(fname, cfgVars[iConfigFile])
    if idx > 0 then
        atom vidx = 0
        
        for v = 1 to length(cfgVars[iSectionName][idx]) do
            if equal(cfgVars[iSectionName][idx][v], sectionname) and equal(cfgVars[iVarName][idx][v], varname) then
                vidx = v
                exit
            end if
        end for
        
        if vidx > 0 then --variable exists, overwrite value
            cfgVars[iVarData][idx][vidx] = vardata
        else            --variable doesn't exist, append variable
            cfgVars[iSectionName][idx] &= {sectionname} 
            cfgVars[iVarName][idx] &= {varname} 
            cfgVars[iVarData][idx] &= {vardata}
        end if
    end if
end procedure


export procedure delete_var(sequence fname, sequence sectionname, sequence varname)
    if length(fname) = 0 then
        fname = DefaultConfigFile
    end if
    atom idx = find(fname, cfgVars[iConfigFile])
    if idx > 0 then
        for v = 1 to length(cfgVars[iSectionName][idx]) do
            if equal(cfgVars[iSectionName][idx][v], sectionname) and equal(cfgVars[iVarName][idx][v], varname) then
                cfgVars[iSectionName][idx] = remove(cfgVars[iSectionName][idx], v)
                cfgVars[iVarName][idx] = remove(cfgVars[iVarName][idx], v)
                cfgVars[iVarData][idx] = remove(cfgVars[iVarData][idx], v)
                exit
            end if
        end for
    end if
end procedure


load_config("")


