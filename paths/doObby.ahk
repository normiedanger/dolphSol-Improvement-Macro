#singleinstance, force
#noenv
RegExMatch(A_ScriptDir, ".*(?=\\paths)", mainDir)
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
#Include ..\lib\pathReference.ahk


Sleep, 1000

if (options_Ref.IsNikoPath = 1) {
    walkSend_Ref("s", "Down")
    ;walkSleep_Ref(4880)
    walkSleep_Ref(4630)
    press_Ref("a",500)
    walkSleep_Ref(1000)
    press_Ref("a",250)
    walkSleep_Ref(100)
} else {
    walkSend_Ref("w", "Down")
    ;walkSleep_Ref(4880)
    walkSleep_Ref(4630)
    press_Ref("d",500)
    walkSleep_Ref(1000)
    press_Ref("d",250)
    walkSleep_Ref(100)
}

if (options_Ref.VIP){
    ; Boat jump_Ref (Niko)
    if (options_Ref.IsNikoPath = 1) {
        walkSend_Ref("s","Down")
        walkSend_Ref("a","Down")
        jump_Ref()
        walkSleep_Ref(500)
        walkSend_Ref("a","Up")
        walkSleep_Ref(200)
        jump_Ref()
        walkSleep_Ref(150)
        walkSend_Ref("s", "Up")
        Sleep, 500

        ; 1st Island
        jump_Ref()
        press_Ref("s", 500)
        Sleep, 200
        press_Ref("w", 50)
        Sleep, 100
        jump_Ref()
        walkSend_Ref("s", "Down")
        walkSleep_Ref(600)
        walkSend_Ref("a","Down")
        walkSleep_Ref(550)

        ; 2nd Island
        jump_Ref()
        walkSleep_Ref(350)
        walkSend_Ref("s", "Up")
        walkSleep_Ref(150)
        jump_Ref()
        walkSend_Ref("s", "Down")
        walkSleep_Ref(350)
        walkSend_Ref("a","Up")
        walkSleep_Ref(400)

        ; Star Island
        jump_Ref()
        walkSleep_Ref(100)
        walkSend_Ref("a","Down")
        jump_Ref()
        walkSleep_Ref(1500)
        walkSend_Ref("a","Up")
        walkSend_Ref("s","Up")

    } else {
        walkSend_Ref("w","Down")
        walkSend_Ref("d","Down")
        jump_Ref()
        walkSleep_Ref(500)
        walkSend_Ref("d","Up")
        walkSleep_Ref(200)
        jump_Ref()
        walkSleep_Ref(150)
        walkSend_Ref("w", "Up")
        Sleep, 500

        ; 1st Island
        jump_Ref()
        press_Ref("w", 500)
        Sleep, 200
        press_Ref("s", 50)
        Sleep, 100
        jump_Ref()
        walkSend_Ref("w", "Down")
        walkSleep_Ref(600)
        walkSend_Ref("d","Down")
        walkSleep_Ref(550)

        ; 2nd Island
        jump_Ref()
        walkSleep_Ref(350)
        walkSend_Ref("w", "Up")
        walkSleep_Ref(150)
        jump_Ref()
        walkSend_Ref("w", "Down")
        walkSleep_Ref(350)
        walkSend_Ref("d","Up")
        walkSleep_Ref(400)

        ; Star Island
        jump_Ref()
        walkSleep_Ref(100)
        walkSend_Ref("d","Down")
        jump_Ref()
        walkSleep_Ref(1500)
        walkSend_Ref("d","Up")
        walkSend_Ref("w","Up")
    }
 
} else {

    if (options_Ref.IsNikoPath = 1) {
        walkSend_Ref("s","Down")
        walkSend_Ref("a","Down")
        jump_Ref()
        walkSleep_Ref(600)
        walkSend_Ref("a","Up")
        walkSleep_Ref(150)
        walkSend_Ref("s","Up")
        walkSleep_Ref(150)
        walkSend_Ref("s","Down")
        jump_Ref()
        walkSleep_Ref(150)
        walkSend_Ref("s","Up")
        Sleep, 500

        ; 1st Island
        walkSend_Ref("s","Down")
        walkSleep_Ref(50)
        jump_Ref()
        walkSleep_Ref(450)
        walkSend_Ref("s","Up")
        Sleep, 200
        press_Ref("w", 50)
        Sleep, 100
        jump_Ref()
        walkSend_Ref("s", "Down")
        walkSleep_Ref(700)
        walkSend_Ref("a","Down")
        walkSleep_Ref(520)

        ; 2nd Island
        jump_Ref()
        walkSleep_Ref(200)
        walkSend_Ref("s", "Up")
        walkSleep_Ref(300)
        walkSend_Ref("a", "Up")
        walkSend_Ref("s", "Down")
        jump_Ref()
        walkSleep_Ref(200)
        walkSend_Ref("a", "Down")
        walkSend_Ref("s", "Up")
        walkSleep_Ref(350)
        walkSend_Ref("a", "Up")
        walkSend_Ref("s", "Down")
        walkSleep_Ref(300)
        jump_Ref()
        walkSleep_Ref(100)
        walkSend_Ref("a", "Down")

        ; Star Island
        walkSleep_Ref(300)
        walkSend_Ref("a", "Down")
        jump_Ref()
        walkSleep_Ref(1100)
        walkSend_Ref("a","Up")
        walkSleep_Ref(200)
        walkSend_Ref("s", "Up")
    }

    
}
