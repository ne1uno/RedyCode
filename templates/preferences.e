-- Redy Application template (under construction)
--
-- <License info goes here>
--
-------------------------------------------------------------------------------


without warning

include gui/gui.e as gui
include app/msg.e as msg
include app/config.e as cfg

include std/task.e
include std/text.e
include std/pretty.e


procedure save_prefs()
--gui:wfunc(txtboxname, "get_text", {})

    cfg:set_var("Section1", "Something1", gui:wfunc("winPreferences.txtSomething1", "get_text", {}))
    cfg:set_var("Section1", "Something2", gui:wfunc("winPreferences.txtSomething2", "get_text", {}))
    cfg:set_var("Section1", "Something3", gui:wfunc("winPreferences.txtSomething3", "get_text", {}))
    cfg:set_var("Section2", "Something4", gui:wfunc("winPreferences.chkSomething4", "get_value", {}))
    cfg:set_var("Section2", "Something5", gui:wfunc("winPreferences.chkSomething5", "get_value", {}))
    cfg:set_var("Section2", "Something6", gui:wfunc("winPreferences.chkSomething6", "get_value", {}))
    
    save_config(App_Name & ".cfg")
end procedure


export procedure gui_event(object evwidget, object evtype, object evdata)

    switch evwidget do
         case "winPreferences.btnOk" then
            save_prefs()
            gui:wdestroy("winPreferences")
            
         case "winPreferences.btnCancel" then
            gui:wdestroy("winPreferences")
            
         case "winPreferences.btnApply" then
            save_prefs()
            --gui:wenable("winPreferences.btnOk", 0)
            --gui:wenable("winPreferences.btnApply", 0)
            
         case "winPreferences" then
            if equal(evtype, "closed") then
                gui:wdestroy("winPreferences")
            end if
            
    end switch
end procedure


function msg_event(sequence subscribername, sequence topicname, sequence msgname, object msgdata)
    switch topicname do
        case "command" then
            if equal(msgname, "preferences") then
                show()
            end if
    end switch
    
    return 1
end function


procedure show()
    if gui:wexists("winPreferences") then
         gui:wdestroy("winPreferences")
    end if
    
    object
    cfgSomething1 = cfg:get_var("Section1", "Something1"),
    cfgSomething2 = cfg:get_var("Section1", "Something2"),
    cfgSomething3 = cfg:get_var("Section1", "Something3"),
    cfgSomething4 = cfg:get_var("Section2", "Something4"),
    cfgSomething5 = cfg:get_var("Section2", "Something5"),
    cfgSomething6 = cfg:get_var("Section2", "Something6")
    
    if atom(cfgSomething1) then
        cfgSomething1 = "txt1"
    end if
    if atom(cfgSomething2) then
        cfgSomething2 = "txt2"
    end if
    if atom(cfgSomething3) then
        cfgSomething3 = "txt3"
    end if
    
    gui:wcreate({
        {"name", "winPreferences"},
        {"class", "window"},
        {"mode", "dialog"},
        {"handler", routine_id("gui_event")},
        {"title", "Preferences"},
        --{"modal", 1},
        {"topmost", 1} 
        --{"position", {350, 350}}
        --{"visible", 0}
    })
    gui:wcreate({
        {"name", "winPreferences.cntMain"},
        {"parent", "winPreferences"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    gui:wcreate({
        {"name", "winPreferences.cntTop"},
        {"parent", "winPreferences.cntMain"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"},
        {"size", {300, 0}}
    })
    
    --data entry:
    gui:wcreate({
        {"name",  "winPreferences.txtSomething1"},
        {"parent",  "winPreferences.cntTop"},
        {"class", "textbox"},
        {"label", "Something 1"},
        {"text", cfgSomething1}
    })
    gui:wcreate({
        {"name",  "winPreferences.txtSomething2"},
        {"parent",  "winPreferences.cntTop"},
        {"class", "textbox"},
        {"label", "Something 2"},
        {"text", cfgSomething2}
    })
    gui:wcreate({
        {"name",  "winPreferences.txtSomething3"},
        {"parent",  "winPreferences.cntTop"},
        {"class", "textbox"},
        {"label", "Something 3"},
        {"text", cfgSomething3}
    })
    
    gui:wcreate({
        {"name",  "winPreferences.chkSomething4"},
        {"parent",  "winPreferences.cntTop"},
        {"class", "toggle"},
        {"label", "Something 4"},
        {"value", cfgSomething4}
    })
    gui:wcreate({
        {"name",  "winPreferences.chkSomething5"},
        {"parent",  "winPreferences.cntTop"},
        {"class", "toggle"},
        {"label", "Something 5"},
        {"value", cfgSomething5}
    })
    gui:wcreate({
        {"name",  "winPreferences.chkSomething6"},
        {"parent",  "winPreferences.cntTop"},
        {"class", "toggle"},
        {"label", "Something 6"},
        {"value", cfgSomething6}
    })
    
    gui:wcreate({
        {"name", "winPreferences.cntBottom"},
        {"parent", "winPreferences.cntMain"},
        {"class", "container"},
        {"orientation", "horizontal"},
        {"sizemode_x", "equal"},
        {"sizemode_y", "normal"},
        {"justify_x", "right"}
    })
    
    gui:wcreate({
        {"name",  "winPreferences.btnOk"},
        {"parent",  "winPreferences.cntBottom"},
        {"class", "button"},
        {"label", "OK"}
    })
    
    gui:wcreate({
        {"name", "winPreferences.btnCancel"},
        {"parent",  "winPreferences.cntBottom"},
        {"class", "button"},
        {"label", "Cancel"}
    })
    
    gui:wcreate({
        {"name", "winPreferences.btnApply"},
        {"parent",  "winPreferences.cntBottom"},
        {"class", "button"},
        {"label", "Apply"}
    })
    
    /*gui:wenable("winPreferences.btnOk", 0)
    gui:wenable("winPreferences.btnApply", 0)*/
end procedure


export procedure start()
    msg:subscribe("preferences", "command", routine_id("msg_event"))
end procedure



