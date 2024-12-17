#singleinstance, force
#noenv
RegExMatch(A_ScriptDir, ".*(?=\\paths)", mainDir)
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
#Include ..\lib\pathReference.ahk


Sleep, 1500

if (options_Ref.VIP){
        walkSend_Ref("w","Down")
        walkSleep_Ref(5520)
        walkSend_Ref("w","Up")
        walkSend_Ref("d","Down")
        walkSleep_Ref(1850)
        walkSend_Ref("d","Up")
        press_Ref2("w", "a", 2150)
        press_Ref("a", 450)
        walkSleep_Ref(150)
        press_Ref("s", 140)
        walkSleep_Ref(150)
        press_Ref("d", 3350)
        press_Ref2("d", "s", 5438)
        walkSleep_Ref(250)
        press_Ref("a", 150)


        walkSend_Ref("d","Down")
        walkSleep_Ref(160)
        jump_Ref()
        walkSleep_Ref(3200)
        walkSend_Ref("d","Up")
        press_Ref("w", 1130)
        press_Ref("d", 1510)
        walkSleep_Ref(160)
        walkSend_Ref("s","Down")
        walkSleep_Ref(195)
        walkSend_Ref("d","Down")
        jump_Ref()

        walkSleep_Ref(430)
        walkSend_Ref("d","Up")
        walkSleep_Ref(135)
        walkSend_Ref("s","Up")
        walkSleep_Ref(500)
        press_Ref2("s", "d", 380)

        ; walkSleep_Ref(4300)
        ; walkSend_Ref("w","Up")
        ; walkSend_Ref("d","Down")
        ; walkSleep_Ref(1350)
        ; walkSend_Ref("d","Up")
        ; walkSend_Ref("w","Down")
        ; walkSend_Ref("a","Down")
        ; walkSleep_Ref(1700)
        ; walkSend_Ref("w","Up")
        ; walkSend_Ref("a","Up")
        ; walkSend_Ref("s","Down")
        ; walkSleep_Ref(250)
        ; walkSend_Ref("s","Up")
        ; walkSend_Ref("d","Down")
        ; walkSleep_Ref(3200)
        ; walkSend_Ref("s","Down")
        ; walkSleep_Ref(5200)
        ; walkSend_Ref("s","Up")
        ; walkSend_Ref("d","Up")
        ; walkSleep_Ref(300)
        ; press_Ref("a", 175)
        ; walkSend_Ref("d","Down")
        ; walkSleep_Ref(150)
        ; jump_Ref()
        ; walkSleep_Ref(3150)
        ; walkSend_Ref("d","Up")
        ; press_Ref("w", 2730)
        ; press_Ref("d", 1250)


        ; walkSend_Ref("a","Up")
        ; walkSleep_Ref(200)
        ; jump_Ref()
        ; walkSleep_Ref(150)
        ; walkSend_Ref("s", "Up")
        ; Sleep, 500

        ; ; 1st Island
        ; jump_Ref()
        ; press_Ref("s", 500)
        ; Sleep, 200
        ; press_Ref("w", 50)
        ; Sleep, 100
        ; jump_Ref()
        ; walkSend_Ref("s", "Down")
        ; walkSleep_Ref(600)
        ; walkSend_Ref("a","Down")
        ; walkSleep_Ref(550)

        ; ; 2nd Island
        ; jump_Ref()
        ; walkSleep_Ref(350)
        ; walkSend_Ref("s", "Up")
        ; walkSleep_Ref(150)
        ; jump_Ref()
        ; walkSend_Ref("s", "Down")
        ; walkSleep_Ref(350)
        ; walkSend_Ref("a","Up")
        ; walkSleep_Ref(400)

        ; ; Star Island
        ; jump_Ref()
        ; walkSleep_Ref(100)
        ; walkSend_Ref("a","Down")
        ; jump_Ref()
        ; walkSleep_Ref(1500)
        ; walkSend_Ref("a","Up")
        ; walkSend_Ref("s","Up")

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
