-- Redy Application template (under construction)
--
-- <License info goes here>
--
-------------------------------------------------------------------------------


include gui/gui.e as gui
include gui/objects/textedit.e as txte
include gui/dialogs/dialog_file.e as dlgfile
include gui/dialogs/msgbox.e as msgbox
include app/msg.e as msg

include std/task.e
include std/text.e
include std/pretty.e
include std/utils.e
include std/sequence.e
include std/filesys.e



procedure show_help()
    gui:wcreate({
        {"name", "panelHelp"},
        {"parent", "winMain"},
        {"class", "panel"},
        {"label", "Help"},
        {"dock", "right"}
    })
    
    gui:wcreate({
        {"name", "cntHelp"},
        {"parent", "panelHelp"},
        {"class", "container"},
        {"orientation", "vertical"},
        {"sizemode_x", "expand"},
        {"sizemode_y", "expand"}
    })
    
    gui:wcreate({
        {"name", "txtHelp"},
        {"parent", "cntHelp"},
        {"class", "textbox"},
        {"text", ExampleText}
    })
end procedure 
    
    
procedure gui_event(object evwidget, object evtype, object evdata)
    switch evwidget do
        
    end switch
end procedure


function msg_event(sequence subscribername, sequence topicname, sequence msgname, object msgdata)
    --gui:debug("msg_event", {"subscribername=" & subscribername, "topicname=" & topicname, "msgname=" & msgname, "msgdata=" & sprint(msgdata)})
    switch topicname do
        case "command" then
            if equal(msgname, "help") then
                show_help()
            end if
    end switch
    return 1
end function


export procedure start()
    msg:subscribe("help", "command", routine_id("msg_event"))
end procedure


