#NoEnv
    #Persistent
    #SingleInstance Force
    SetBatchLines, -1
    CoordMode, Mouse, Screen

    walkSend_Ref(k, t := "") {
        Send, { }
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
Sleep, 812
MouseClick, Left, 665, 1064
Sleep, 250
MouseClick, Left, 836, 749
Sleep, 282
press_Ref("s", 0)
Sleep, 359
press_Ref("Space", 0)
Sleep, 422
press_Ref("a", 0)
Sleep, 265
press_Ref("w", 0)
Sleep, 250
press_Ref("d", 0)
Sleep, 3969
MouseClick, Left, 1392, 590
press_Ref(a, 4578)
press_Ref(d, 4063)
press_Ref(s, 5375)
press_Ref(Space, 5016)
press_Ref(w, 4344)
