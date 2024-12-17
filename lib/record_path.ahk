#Persistent
#SingleInstance Force
SetBatchLines, -1

full_command_line := DllCall("GetCommandLine", "str")
if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)")) {
    try {
        RunWait, *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
    }
}
; Define the output file path
outputFile := "recorded_actions.ahk"

CoordMode, Mouse, Screen
recording := false
lastTimestamp := 0
heldKeys := {}

Gui, Recorder:New, +AlwaysOnTop, Recorder
Gui, Add, Text, x10 y10, Recording Status:
Gui, Add, Text, x120 y10 vStatusText, Not Recording
Gui, Recorder:Add, Button, x10 y40 gStartRecording, Start Recording
Gui, Recorder:Add, Button, x120 y40 gStopRecording, Stop Recording
Gui, Recorder:Add, Button, x10 y70 gReplayRecording, Replay Recording
Gui, Recorder:Show, w250 h130, Recorder

; Function to start recording
StartRecording:
    if (recording) {
        MsgBox, Recording is already in progress.
        return
    }
    recording := true
    lastTimestamp := A_TickCount

    ; Clear the output file and write headers
    FileDelete, %outputFile%
    FileAppend, 
    (
    #NoEnv
    #Persistent
    #SingleInstance Force
    SetBatchLines, -1
    CoordMode, Mouse, Screen

    walkSend_Ref(k, t := "") {
        Send, {%k% %t%}
    }

    press_Ref(k, duration := 50) {
        walkSend_Ref(k, "Down")
        Sleep, duration
        walkSend_Ref(k, "Up")
    }

    press_Ref2(k, k2, duration := 50) {
        walkSend_Ref(k, "Down")
        walkSend_Ref(k2, "Down")
        Sleep, duration
        walkSend_Ref(k, "Up")
        walkSend_Ref(k2, "Up")
    }

    ), %outputFile%

    GuiControl,, StatusText, Recording
    return

; Function to stop recording
StopRecording:
    if (!recording) {
        MsgBox, No recording is in progress.
        return
    }
    recording := false

    ; Handle any held keys
    For key, startTime in heldKeys {
        RecordKeyRelease(key, startTime)
    }

    heldKeys := {}  ; Clear held keys
    GuiControl,, StatusText, Not Recording
    return

ReplayRecording:
    if (recording) {
        MsgBox, Please stop recording before replaying.
        return
    }
    if !FileExist(outputFile) {
        MsgBox, No recording found to replay.
        return
    }
    GuiControl,, StatusText, Replaying
    Run, %outputFile%
    Sleep, 1000
    GuiControl,, StatusText, Not Recording
    return


AppendAction(action) {
    global lastTimestamp, outputFile
    currentTimestamp := A_TickCount
    delay := currentTimestamp - lastTimestamp

    if (delay > 0) {
        FileAppend, % "Sleep, " delay "`n" action "`n", %outputFile%
    } else {
        FileAppend, % action "`n", %outputFile%
    }
    lastTimestamp := currentTimestamp
}

RecordKeyRelease(key, startTime) {
    global outputFile
    holdDuration := A_TickCount - startTime
    FileAppend, % "press_Ref(" key ", " holdDuration ")" "`n", %outputFile%
}


walkSend_Ref(k, t := "") {
    Send, {%k% %t%}
}

press_Ref(k, duration := 50) {
    walkSend_Ref(k, "Down")
    Sleep, duration
    walkSend_Ref(k, "Up")
}

press_Ref2(k, k2, duration := 50) {
    walkSend_Ref(k, "Down")
    walkSend_Ref(k2, "Down")
    Sleep, duration
    walkSend_Ref(k, "Up")
    walkSend_Ref(k2, "Up")
}

; Mouse click event
~LButton::
~RButton::
    if (recording) {
        MouseGetPos, x, y
        button := (A_ThisHotkey = "~LButton") ? "Left" : "Right"
        action := Format("MouseClick, {}, {}, {}", button, x, y)
        AppendAction(action)
    }
    return

; Key press event
~*a::
~*b::
~*c::
~*d::
~*e::
~*f::
~*g::
~*h::
~*i::
~*j::
~*k::
~*l::
~*m::
~*n::
~*o::
~*p::
~*q::
~*r::
~*s::
~*t::
~*u::
~*v::
~*w::
~*x::
~*y::
~*z::
~*1::
~*2::
~*3::
~*4::
~*5::
~*6::
~*7::
~*8::
~*9::
~*0::
~*Space::
~*Enter::
~*Shift::
~*Ctrl::
~*Alt::
~*Esc::
~*Tab::
~*Backspace::
~*CapsLock::
~*F1::
~*F2::
~*F3::
~*F4::
~*F5::
~*F6::
~*F7::
~*F8::
~*F9::
~*F10::
~*F11::
~*F12::
~*Up::
~*Down::
~*Left::
~*Right::
; Add more keys as needed
    if (recording) {
        key := SubStr(A_ThisHotkey, 3)
        if (!heldKeys.HasKey(key)) {
            heldKeys[key] := A_TickCount
            action := "press_Ref(""" key """, 0)"
            AppendAction(action)
        }
    }
    return

; Key release event
~*a Up::
~*b Up::
~*c Up::
~*d Up::
~*e Up::
~*f Up::
~*g Up::
~*h Up::
~*i Up::
~*j Up::
~*k Up::
~*l Up::
~*m Up::
~*n Up::
~*o Up::
~*p Up::
~*q Up::
~*r Up::
~*s Up::
~*t Up::
~*u Up::
~*v Up::
~*w Up::
~*x Up::
~*y Up::
~*z Up::
~*1 Up::
~*2 Up::
~*3 Up::
~*4 Up::
~*5 Up::
~*6 Up::
~*7 Up::
~*8 Up::
~*9 Up::
~*0 Up::
~*Space Up::
~*Enter Up::
~*Shift Up::
~*Ctrl Up::
~*Alt Up::
~*Esc Up::
~*Tab Up::
~*Backspace Up::
~*CapsLock Up::
~*F1 Up::
~*F2 Up::
~*F3 Up::
~*F4 Up::
~*F5 Up::
~*F6 Up::
~*F7 Up::
~*F8 Up::
~*F9 Up::
~*F10 Up::
~*F11 Up::
~*F12 Up::
~*Up Up::
~*Down Up::
~*Left Up::
~*Right Up::
    if (recording) {
        key := SubStr(A_ThisHotkey, 3)
        if (heldKeys.HasKey(key)) {
            startTime := heldKeys[key]
            holdDuration := A_TickCount - startTime
            action := "press_Ref(""" key """, " holdDuration ")"
            AppendAction(action)
            heldKeys.Delete(key)
        }
    }
    return

GuiClose:
    ExitApp