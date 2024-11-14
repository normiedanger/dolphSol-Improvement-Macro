#singleinstance, force
#noenv
RegExMatch(A_ScriptDir, ".*(?=\\paths)", mainDir)
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
#Include ..\lib\pathReference.ahk
; revision by sanji (sir.moxxi) and Flash (drflash55)

; 2nd revision by InnocentHuman

; 3rd revision by InnocentHuman and _justalin (Allan)

; new version of default dolphsol collect_Ref path - noteab 

Spot1() { ; Allan's Fix
	
	if (options_Ref.IsNikoPath = 1) {
		walkSend_Ref("w","Down")
		walkSend_Ref("d","Down")
		walkSleep_Ref(1100)
		walkSend_Ref("d","Up")
		walkSleep_Ref(2500)
		walkSend_Ref("w","Up")
		collect_Ref(1)
		
	} else {
		walkSend_Ref("s","Down")
		walkSend_Ref("a","Down")
		walkSleep_Ref(1100)
		walkSend_Ref("a","Up")
		walkSleep_Ref(2500)
		walkSend_Ref("s","Up")
		collect_Ref(1)
	}
	
}

Spot2() {  ; Allan's Fix

	if (options_Ref.IsNikoPath = 1) {
		walkSend_Ref("a","Down")
		walkSleep_Ref(3400)
		walkSend_Ref("a", "Up")
		collect_Ref(2)
	} else {
		walkSend_Ref("d","Down")
		walkSleep_Ref(3400)
		walkSend_Ref("d", "Up")
		collect_Ref(2)
	}

}

Spot3() {

	if (options_Ref.IsNikoPath = 1) {
		walkSend_Ref("a", "Down")
		walkSleep_Ref(300)
		jump_Ref()
		walkSleep_Ref(350)
		walkSend_Ref("s","Down")
		walkSleep_Ref(250)
		jump_Ref()
		walkSleep_Ref(350)
		walkSend_Ref("a", "Up")
		walkSleep_Ref(250)
		jump_Ref()
		walkSleep_Ref(350)
		walkSend_Ref("s","Up")
		walkSend_Ref("a", "Down")
		walkSleep_Ref(100)
		jump_Ref()
		walkSleep_Ref(350)
		walkSend_Ref("w","Down")
		walkSleep_Ref(750)
		walkSend_Ref("a", "Up")
		walkSend_Ref("w","Up")
		collect_Ref(3)

	} else {
		walkSend_Ref("d","Down")
		walkSleep_Ref(300)
		jump_Ref()
		walkSleep_Ref(350)
		walkSend_Ref("w","Down")
		walkSleep_Ref(250)
		jump_Ref()
		walkSleep_Ref(350)
		walkSend_Ref("d","Up")
		walkSleep_Ref(250)
		jump_Ref()
		walkSleep_Ref(350)
		walkSend_Ref("w","Up")
		walkSend_Ref("d","Down")
		walkSleep_Ref(100)
		jump_Ref()
		walkSleep_Ref(350)
		walkSend_Ref("s","Down")
		walkSleep_Ref(750)
		walkSend_Ref("d","Up")
		walkSend_Ref("s","Up")
		collect_Ref(3)
	}
	

}

Spot4() { ; Allan's Fix

	if (options_Ref.IsNikoPath = 1) {
		walkSend_Ref("s", "Down")
		walkSleep_Ref(1500)
		walkSend_Ref("s", "Up")
		walkSend_Ref("a","Down")
		walkSleep_Ref(820)
		walkSend_Ref("a","Up")
		walkSend_Ref("w", "Down")
		walkSleep_Ref(600)
		walkSend_Ref("w", "Up")
		collect_Ref(4)
	} else {
		walkSend_Ref("d","Down")
		walkSleep_Ref(200)
		walkSend_Ref("w","Down")
		walkSleep_Ref(750)
		walkSend_Ref("d","Up")
		walkSleep_Ref(200)
		walkSend_Ref("w","Up")
		collect_Ref(4)
	}

}

Spot5() { ; Allan's Fix

	if (options_Ref.IsNikoPath = 1) {
		walkSend_Ref("d","Down")
		walkSend_Ref("s","Down")
		walkSleep_Ref(3700)
		walkSend_Ref("d","Up")
		walkSleep_Ref(150)
		jump_Ref()
		walkSleep_Ref(500)
		walkSend_Ref("s","Up")
		collect_Ref(5)
	} else {
		walkSend_Ref("a","Down")
		walkSend_Ref("w","Down")
		walkSleep_Ref(3700)
		walkSend_Ref("a","Up")
		walkSleep_Ref(150)
		jump_Ref()
		walkSleep_Ref(500)
		walkSend_Ref("w","Up")
		collect_Ref(5)
	}
}

Spot6() { ; Allan's Fix
	if (options_Ref.IsNikoPath = 1) {
		walkSend_Ref("d","Down")
		walkSleep_Ref(900)
		jump_Ref()
		press_Ref("s", 400)
		walkSleep_Ref(2500)
		walkSleep_Ref(100)
		walkSend_Ref("d","Up")
		press_Ref("w", 300)
		collect_Ref(6)
	} else {
		walkSend_Ref("a","Down")
		walkSleep_Ref(900)
		jump_Ref()
		press_Ref("w", 400)
		walkSleep_Ref(2500)
		walkSleep_Ref(100)
		walkSend_Ref("a","Up")
		press_Ref("s", 300)
		collect_Ref(6)
	}
	
}

Spot7() { ; Allan's Fix

	if (options_Ref.IsNikoPath = 1) {
		walkSend_Ref("d","Down") ; Walks to 
		walkSleep_Ref(2500)
		walkSend_Ref("d","Up")

		walkSend_Ref("w","Down")
		walkSleep_Ref(500)
		jump_Ref()
		walkSleep_Ref(600)
		walkSend_Ref("w", "Up")
		walkSend_Ref("d","Down")
		walkSleep_Ref(100)
		jump_Ref()
		walkSleep_Ref(200)
		walkSend_Ref("d","Up")
		walkSend_Ref("w","Down")
		walkSleep_Ref(200)
		jump_Ref()
		walkSleep_Ref(600)
		walkSend_Ref("d","Down")
		jump_Ref()
		walkSleep_Ref(200)
		walkSend_Ref("d","Up")
		walkSleep_Ref(100)
		walkSend_Ref("w", "Up")

		walkSend_Ref("w","Down")
		walkSleep_Ref(200)
		jump_Ref()
		walkSleep_Ref(500)
		press_Ref("d","200")
		jump_Ref()
		walkSleep_Ref(400)
		walkSend_Ref("w", "Up")
		walkSend_Ref("a", "Down")
		walkSleep_Ref(400)
		walkSend_Ref("a", "Up")
		collect_Ref(7)
	} else {
		walkSend_Ref("a","Down")
		walkSleep_Ref(2500)
		walkSend_Ref("a","Up")

		walkSend_Ref("s","Down")
		walkSleep_Ref(500)
		jump_Ref()
		walkSleep_Ref(600)
		walkSend_Ref("s", "Up")
		walkSend_Ref("a","Down")
		walkSleep_Ref(100)
		jump_Ref()
		walkSleep_Ref(200)
		walkSend_Ref("a","Up")
		walkSend_Ref("s","Down")
		walkSleep_Ref(200)
		jump_Ref()
		walkSleep_Ref(600)
		walkSend_Ref("a","Down")
		jump_Ref()
		walkSleep_Ref(200)
		walkSend_Ref("a","Up")
		walkSleep_Ref(100)
		walkSend_Ref("s", "Up")

		walkSend_Ref("s","Down")
		walkSleep_Ref(200)
		jump_Ref()
		walkSleep_Ref(500)
		press_Ref("a","200")
		jump_Ref()
		walkSleep_Ref(400)
		walkSend_Ref("s", "Up")
		walkSend_Ref("d", "Down")
		walkSleep_Ref(400)
		walkSend_Ref("d", "Up")
		collect_Ref(7)
	}
}

Spot8VIP() { ; All credits to Allan & me

	if (options_Ref.IsNikoPath = 1) {
		;tree obby
		walkSend_Ref("w","Down")
		walkSleep_Ref(1800)
		press_Ref("d",500)
		walkSend_Ref("w","Up")
		sleep, 400

		walkSend_Ref("a","Down")
		walkSleep_Ref(420)
		walkSend_Ref("a","Up")

		walkSend_Ref("w","Down")
		walkSleep_Ref(100)
		jump_Ref()
		walkSleep_Ref(1500)
		walkSend_Ref("d","Down")
		walkSleep_Ref(20)
		jump_Ref()
		sleep, 700

		jump_Ref()
		walkSleep_Ref(100)
		walkSend_Ref("w","Up")
		walkSleep_Ref(300)

		walkSend_Ref("w","Down")
		walkSleep_Ref(100)
		jump_Ref()
		walkSleep_Ref(500)
		walkSend_Ref("w","Up")
		walkSleep_Ref(200)
		jump_Ref()
		walkSleep_Ref(400)
		jump_Ref()
		walkSleep_Ref(650)
		walkSend_Ref("d","Up")
		sleep, 300


		;mountain obby

		walkSend_Ref("s","Down")
		walkSleep_Ref(300)
		jump_Ref()
		walkSleep_Ref(800)
		jump_Ref()
		walkSleep_Ref(800)
		walkSend_Ref("s","Up")

		press_Ref("w","200")
		walkSend_Ref("s","Down")
		walkSend_Ref("d","Down")
		walkSleep_Ref(300)
		jump_Ref()
		walkSleep_Ref(200)
		walkSend_Ref("d","Up")
		walkSend_Ref("a","Down")
		walkSleep_Ref(500)
		walkSend_Ref("a","Up")
		walkSleep_Ref(400)
		jump_Ref()

		walkSleep_Ref(800)
		walkSend_Ref("s","Up")
		walkSend_Ref("a","Down")
		walkSleep_Ref(800)
		walkSend_Ref("a","Up")

		walkSend_Ref("s","Down")
		jump_Ref()
		walkSleep_Ref(900)
		walkSend_Ref("s","Up")

		walkSend_Ref("d","Down")
		walkSleep_Ref(1000)
		walkSend_Ref("d","Up")

		walkSend_Ref("w","Down")
		walkSend_Ref("d","Down")
		jump_Ref()
		walkSleep_Ref(50)
		walkSend_Ref("w","Up")
		walkSleep_Ref(200)
		walkSend_Ref("s","Down")
		walkSleep_Ref(500)
		walkSend_Ref("s","Up")

		jump_Ref()
		walkSleep_Ref(400)
		walkSend_Ref("s","Down")
		walkSend_Ref("d","Up")
		jump_Ref()
		walkSleep_Ref(1700)
		walkSend_Ref("s","Up")

		walkSend_Ref("a","Down")
		walkSleep_Ref(800)
		walkSend_Ref("a","Up")
		walkSend_Ref("s","Down")
		walkSleep_Ref(300)
		walkSend_Ref("s","Up")

		walkSend_Ref("w","Down")
		walkSleep_Ref(300)
		walkSend_Ref("w","Up")
		walkSend_Ref("a","Down")
		walkSleep_Ref(800)
		jump_Ref()
		walkSleep_Ref(500)
		walkSend_Ref("a","Up")

		walkSend_Ref("w","Down")
		walkSleep_Ref(270)
		walkSend_Ref("w","Up")
		walkSend_Ref("a","Down")
		walkSleep_Ref(420)


		jump_Ref()
		walkSleep_Ref(100)
		walkSend_Ref("a","Up")
		walkSend_Ref("s","Down")
		walkSend_Ref("a","Down")
		walkSleep_Ref(300)
		walkSend_Ref("a","Up")
		walkSend_Ref("s","Up")

		;end part

		sleep, 500
		walkSend_Ref("d","Down")
		walkSleep_Ref(500)
		walkSend_Ref("d","Up")
		walkSend_Ref("s","Down")
		walkSleep_Ref(300)
		walkSend_Ref("s","Up")
		walkSend_Ref("a","Down")
		walkSleep_Ref(400)
		walkSend_Ref("a","Up")
		walkSleep_Ref(500)
		walkSend_Ref("s","Down")
		walkSleep_Ref(300)
		walkSend_Ref("d","Down")
		walkSleep_Ref(150)
		walkSend_Ref("d","up")
		walkSleep_Ref(350)
		walkSend_Ref("s","Up")
		walkSend_Ref("d","Down")
		walkSleep_Ref(300)
		walkSend_Ref("d","Up")

		collect_Ref(8)
	} else {
		;tree obby

		walkSend_Ref("s","Down")
		walkSleep_Ref(1800)
		press_Ref("a",500)
		walkSend_Ref("s","Up")
		sleep, 400

		walkSend_Ref("d","Down")
		walkSleep_Ref(420)
		walkSend_Ref("d","Up")

		walkSend_Ref("s","Down")
		walkSleep_Ref(100)
		jump_Ref()
		walkSleep_Ref(1500)
		walkSend_Ref("a","Down")
		walkSleep_Ref(20)
		jump_Ref()
		sleep, 700

		jump_Ref()
		walkSleep_Ref(100)
		walkSend_Ref("s","Up")
		walkSleep_Ref(300)

		walkSend_Ref("s","Down")
		walkSleep_Ref(100)
		jump_Ref()
		walkSleep_Ref(500)
		walkSend_Ref("s","Up")
		walkSleep_Ref(200)
		jump_Ref()
		walkSleep_Ref(400)
		jump_Ref()
		walkSleep_Ref(650)
		walkSend_Ref("a","Up")
		sleep, 300


		;mountain obby

		walkSend_Ref("w","Down")
		walkSleep_Ref(300)
		jump_Ref()
		walkSleep_Ref(800)
		jump_Ref()
		walkSleep_Ref(800)
		walkSend_Ref("w","Up")

		press_Ref("w","200")
		walkSend_Ref("w","Down")
		walkSend_Ref("a","Down")
		walkSleep_Ref(300)
		jump_Ref()
		walkSleep_Ref(200)
		walkSend_Ref("a","Up")
		walkSend_Ref("d","Down")
		walkSleep_Ref(500)
		walkSend_Ref("d","Up")
		walkSleep_Ref(400)
		jump_Ref()

		walkSleep_Ref(800)
		walkSend_Ref("w","Up")
		walkSend_Ref("d","Down")
		walkSleep_Ref(800)
		walkSend_Ref("d","Up")

		walkSend_Ref("w","Down")
		jump_Ref()
		walkSleep_Ref(900)
		walkSend_Ref("w","Up")

		walkSend_Ref("a","Down")
		walkSleep_Ref(1000)
		walkSend_Ref("a","Up")

		walkSend_Ref("s","Down")
		walkSend_Ref("a","Down")
		jump_Ref()
		walkSleep_Ref(50)
		walkSend_Ref("s","Up")
		walkSleep_Ref(200)
		walkSend_Ref("w","Down")
		walkSleep_Ref(500)
		walkSend_Ref("w","Up")

		jump_Ref()
		walkSleep_Ref(400)
		walkSend_Ref("w","Down")
		walkSend_Ref("a","Up")
		jump_Ref()
		walkSleep_Ref(1700)
		walkSend_Ref("w","Up")

		walkSend_Ref("d","Down")
		walkSleep_Ref(800)
		walkSend_Ref("d","Up")
		walkSend_Ref("w","Down")
		walkSleep_Ref(300)
		walkSend_Ref("w","Up")

		walkSend_Ref("s","Down")
		walkSleep_Ref(300)
		walkSend_Ref("s","Up")
		walkSend_Ref("d","Down")
		walkSleep_Ref(800)
		jump_Ref()
		walkSleep_Ref(500)
		walkSend_Ref("d","Up")

		walkSend_Ref("s","Down")
		walkSleep_Ref(270)
		walkSend_Ref("s","Up")
		walkSend_Ref("d","Down")
		walkSleep_Ref(420)


		jump_Ref()
		walkSleep_Ref(100)
		walkSend_Ref("d","Up")
		walkSend_Ref("w","Down")
		walkSend_Ref("d","Down")
		walkSleep_Ref(300)
		walkSend_Ref("d","Up")
		walkSend_Ref("w","Up")

		;end part

		sleep, 500
		walkSend_Ref("a","Down")
		walkSleep_Ref(500)
		walkSend_Ref("a","Up")
		walkSend_Ref("w","Down")
		walkSleep_Ref(300)
		walkSend_Ref("w","Up")
		walkSend_Ref("d","Down")
		walkSleep_Ref(400)
		walkSend_Ref("d","Up")
		walkSleep_Ref(500)
		walkSend_Ref("w","Down")
		walkSleep_Ref(300)
		walkSend_Ref("a","Down")
		walkSleep_Ref(150)
		walkSend_Ref("a","up")
		walkSleep_Ref(350)
		walkSend_Ref("s","Up")
		walkSend_Ref("a","Down")
		walkSleep_Ref(300)
		walkSend_Ref("a","Up")

		collect_Ref(8)
	}
}

Spot8() { ; All credits to Allan & Me

	if (options_Ref.IsNikoPath = 1) {
		;tree obby

		walkSend_Ref("w","Down")
		walkSleep_Ref(1800)
		press_Ref("d",500)
		walkSend_Ref("w","Up")
		sleep, 400

		walkSend_Ref("a","Down")
		walkSleep_Ref(420)
		walkSend_Ref("a","Up")

		walkSend_Ref("w","Down")
		walkSleep_Ref(100)
		jump_Ref()
		walkSleep_Ref(550)
		jump_Ref()
		walkSleep_Ref(950)
		walkSend_Ref("w","Up")

		sleep, 500

		walkSend_Ref("w","Down")
		walkSend_Ref("d","Down")
		walkSleep_Ref(100)
		jump_Ref()
		walkSleep_Ref(500)
		jump_Ref()
		walkSleep_Ref(200)
		jump_Ref()
		walkSend_Ref("w","Up")
		walkSleep_Ref(200)
		jump_Ref()
		walkSend_Ref("w","Down")
		walkSleep_Ref(500)
		jump_Ref()
		walkSend_Ref("w","Up")
		walkSleep_Ref(300)
		jump_Ref()
		walkSleep_Ref(300)
		jump_Ref()
		walkSleep_Ref(600)
		walkSend_Ref("d","Up")

		;mountain obby

		walkSend_Ref("s","Down")
		walkSleep_Ref(400)
		jump_Ref()
		walkSleep_Ref(900)
		jump_Ref()
		walkSleep_Ref(800)
		walkSend_Ref("s","Up")

		press_Ref("w","200")
		walkSend_Ref("s","Down")
		walkSend_Ref("d","Down")
		walkSleep_Ref(300)
		jump_Ref()
		walkSleep_Ref(200)
		walkSend_Ref("d","Up")
		walkSend_Ref("a","Down")
		walkSleep_Ref(500)
		walkSend_Ref("a","Up")
		walkSleep_Ref(400)
		jump_Ref()

		walkSleep_Ref(800)
		walkSend_Ref("s","Up")
		walkSend_Ref("a","Down")
		walkSleep_Ref(800)
		walkSend_Ref("a","Up")

		walkSend_Ref("s","Down")
		jump_Ref()
		walkSleep_Ref(900)
		walkSend_Ref("s","Up")

		walkSend_Ref("d","Down")
		walkSleep_Ref(1000)
		walkSend_Ref("d","Up")

		walkSend_Ref("w","Down")
		walkSend_Ref("d","Down")
		jump_Ref()
		walkSleep_Ref(50)
		walkSend_Ref("w","Up")
		walkSleep_Ref(200)
		walkSend_Ref("d","Up")
		walkSend_Ref("s","Down")
		walkSend_Ref("d","Down")
		walkSleep_Ref(500)
		walkSleep_Ref(500)
		walkSend_Ref("s","Up")
		walkSend_Ref("d","Up")

		walkSend_Ref("d","Down")
		jump_Ref()
		walkSleep_Ref(350)
		walkSend_Ref("d","Up")

		jump_Ref()
		walkSend_Ref("s","Down")
		walkSleep_Ref(1700)
		walkSend_Ref("s","Up")

		walkSend_Ref("a","Down")
		walkSleep_Ref(800)
		walkSend_Ref("a","Up")
		walkSend_Ref("s","Down")
		walkSleep_Ref(300)
		walkSend_Ref("s","Up")

		walkSend_Ref("w","Down")
		walkSleep_Ref(300)
		walkSend_Ref("w","Up")
		walkSend_Ref("a","Down")
		walkSleep_Ref(800)
		jump_Ref()
		walkSleep_Ref(500)
		walkSend_Ref("a","Up")



		walkSend_Ref("w","Down")
		walkSleep_Ref(270)
		walkSend_Ref("w","Up")
		walkSend_Ref("a","Down")
		walkSleep_Ref(470)
		walkSend_Ref("a","Up")


		walkSend_Ref("a","Down")
		jump_Ref()
		walkSleep_Ref(100)
		walkSend_Ref("s","Down")
		walkSleep_Ref(500)
		walkSend_Ref("s","Up")
		walkSleep_Ref(100)
		walkSend_Ref("a","Up")
		sleep, 500
		walkSend_Ref("d","Down")
		walkSleep_Ref(1000)
		walkSend_Ref("d","Up")
		walkSend_Ref("s","Down")
		walkSleep_Ref(600)
		walkSend_Ref("s","Up")
		walkSleep_Ref(100)
		walkSend_Ref("a","Down")
		walkSleep_Ref(400)
		walkSend_Ref("a","Up")
		walkSleep_Ref(500)
		walkSend_Ref("s","Down")
		walkSleep_Ref(700)
		walkSend_Ref("s","Up")
		walkSend_Ref("d","Down")
		walkSleep_Ref(300)
		walkSend_Ref("d","Up")


		collect_Ref(8)

	} else {
		;tree obby
		walkSend_Ref("s","Down")
		walkSleep_Ref(1800)
		press_Ref("a",500)
		walkSend_Ref("s","Up")
		sleep, 400

		walkSend_Ref("d","Down")
		walkSleep_Ref(420)
		walkSend_Ref("d","Up")

		walkSend_Ref("s","Down")
		walkSleep_Ref(100)
		jump_Ref()
		walkSleep_Ref(550)
		jump_Ref()
		walkSleep_Ref(950)
		walkSend_Ref("s","Up")

		sleep, 500

		walkSend_Ref("s","Down")
		walkSend_Ref("a","Down")
		walkSleep_Ref(100)
		jump_Ref()
		walkSleep_Ref(500)
		jump_Ref()
		walkSleep_Ref(200)
		jump_Ref()
		walkSend_Ref("s","Up")
		walkSleep_Ref(200)
		jump_Ref()
		walkSend_Ref("s","Down")
		walkSleep_Ref(500)
		jump_Ref()
		walkSend_Ref("s","Up")
		walkSleep_Ref(300)
		jump_Ref()
		walkSleep_Ref(300)
		jump_Ref()
		walkSleep_Ref(600)
		walkSend_Ref("a","Up")

		;mountain obby

		walkSend_Ref("w","Down")
		walkSleep_Ref(400)
		jump_Ref()
		walkSleep_Ref(900)
		jump_Ref()
		walkSleep_Ref(800)
		walkSend_Ref("w","Up")

		press_Ref("s","200")
		walkSend_Ref("w","Down")
		walkSend_Ref("a","Down")
		walkSleep_Ref(300)
		jump_Ref()
		walkSleep_Ref(200)
		walkSend_Ref("a","Up")
		walkSend_Ref("d","Down")
		walkSleep_Ref(500)
		walkSend_Ref("d","Up")
		walkSleep_Ref(400)
		jump_Ref()

		walkSleep_Ref(800)
		walkSend_Ref("w","Up")
		walkSend_Ref("d","Down")
		walkSleep_Ref(800)
		walkSend_Ref("d","Up")

		walkSend_Ref("w","Down")
		jump_Ref()
		walkSleep_Ref(900)
		walkSend_Ref("w","Up")

		walkSend_Ref("a","Down")
		walkSleep_Ref(1000)
		walkSend_Ref("a","Up")

		walkSend_Ref("s","Down")
		walkSend_Ref("a","Down")
		jump_Ref()
		walkSleep_Ref(50)
		walkSend_Ref("s","Up")
		walkSleep_Ref(200)
		walkSend_Ref("a","Up")
		walkSend_Ref("w","Down")
		walkSend_Ref("a","Down")
		walkSleep_Ref(500)
		walkSleep_Ref(500)
		walkSend_Ref("w","Up")
		walkSend_Ref("a","Up")

		walkSend_Ref("a","Down")
		jump_Ref()
		walkSleep_Ref(350)
		walkSend_Ref("a","Up")

		jump_Ref()
		walkSend_Ref("w","Down")
		walkSleep_Ref(1700)
		walkSend_Ref("w","Up")

		walkSend_Ref("d","Down")
		walkSleep_Ref(800)
		walkSend_Ref("d","Up")
		walkSend_Ref("w","Down")
		walkSleep_Ref(300)
		walkSend_Ref("w","Up")

		walkSend_Ref("s","Down")
		walkSleep_Ref(300)
		walkSend_Ref("s","Up")
		walkSend_Ref("d","Down")
		walkSleep_Ref(800)
		jump_Ref()
		walkSleep_Ref(500)
		walkSend_Ref("d","Up")

		walkSend_Ref("s","Down")
		walkSleep_Ref(270)
		walkSend_Ref("s","Up")
		walkSend_Ref("d","Down")
		walkSleep_Ref(470)
		walkSend_Ref("d","Up")


		walkSend_Ref("d","Down")
		jump_Ref()
		walkSleep_Ref(100)
		walkSend_Ref("w","Down")
		walkSleep_Ref(500)
		walkSend_Ref("w","Up")
		walkSleep_Ref(100)
		walkSend_Ref("d","Up")
		sleep, 500
		walkSend_Ref("a","Down")
		walkSleep_Ref(1000)
		walkSend_Ref("a","Up")
		walkSend_Ref("w","Down")
		walkSleep_Ref(600)
		walkSend_Ref("w","Up")
		walkSleep_Ref(100)
		walkSend_Ref("d","Down")
		walkSleep_Ref(400)
		walkSend_Ref("d","Up")
		walkSleep_Ref(500)
		walkSend_Ref("w","Down")
		walkSleep_Ref(700)
		walkSend_Ref("w","Up")
		walkSend_Ref("a","Down")
		walkSleep_Ref(300)
		walkSend_Ref("a","Up")

		collect_Ref(8)
	}

}

if options_Ref["ItemSpot" . 1] or options_Ref["ItemSpot" . 2] {
	
	Spot1()
	
	if options_Ref["ItemSpot" . 2] {
	
		Spot2()
		
	}
	
	reset_Ref()
	Sleep, 1800
	
}

if options_Ref["ItemSpot" . 3] or options_Ref["ItemSpot" . 4] {
	
	Spot3()
	
	if options_Ref["ItemSpot" . 4] {
	
		Spot4()
		
	}
	
	reset_Ref()
	Sleep, 1800
	
}

if options_Ref["ItemSpot" . 5] or options_Ref["ItemSpot" . 6] or options_Ref["ItemSpot" . 7] or options_Ref["ItemSpot" . 8] {
	
	Spot5()
	
	if options_Ref["ItemSpot" . 6] or options_Ref["ItemSpot" . 7] or options_Ref["ItemSpot" . 8] {
	
		Spot6()

		if options_Ref["ItemSpot" . 7] or options_Ref["ItemSpot" . 8] {
		
			Spot7()

			if options_Ref["ItemSpot" . 8] and options_Ref.VIP {
			
				Spot8VIP()

			}
			
			if options_Ref["ItemSpot" . 8] and !options_Ref.VIP {
			
				Spot8()

			}

		}
	}
}