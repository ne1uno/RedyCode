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


--Environment Info (standard about dialog, copyright & version info, etc.)


include std/text.e
include std/pretty.e
include std/error.e
include euphoria/info.e

/*
    "Redy Application Environment™ version " & RedyAE_Version & "\n" &
    RedyAE_Copyright & "\n" &
    "http://redy-project.org/\n" &
    "\n" &
    "[Platform Information]\n" &
    "platform_name: " & platform_name() & "\n" &
    "[Euphoria Information]\n" &
    "version_string: " & version_string(0) & "\n" &
    "version_node: " & version_node(0) & "\n" &
    "version_date: " & version_date(0) & "\n" &
    "version_type: " & version_type() & "\n" &
    "version_string_long: " & version_string_long(0) & "\n" &
    "include_paths: " & pretty_sprint(include_paths(0), {2}) & "\n" &
    "option_switches: " & pretty_sprint(option_switches(), {2})
*/

