#singleinstance, force
#noenv
RegExMatch(A_ScriptDir, ".*(?=\\paths)", mainDir)
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
#Include ..\lib\pathReference.ahk

; revision by sanji (sir.moxxi) and Flash (drflash55)

; 2nd revision by InnocentHuman

; 3rd revision by InnocentHuman and _justalin (Allan)

; new version of default dolphsol collect_Ref path (eon1) - noteab 

Spot1() {
	if (options_Ref.VIP = 1) {
		walkSend_Ref("w","Down")
		walkSleep_Ref(5387)
		walkSend_Ref("w","Up")
		walkSleep_Ref(150)
		press_Ref("s", 230)
		walkSend_Ref("w","Down")
		walkSleep_Ref(150)
		jump_Ref() ; jump to cliff
	
		press_Ref("a", 3550)
		walkSend_Ref("w","Up")
		collect_Ref(1) ; collect item on the first cliff
		press_Ref("s", 355)
		press_Ref("d", 385)
		walkSend_Ref("a","Down") ; jump to second cliff
		walkSleep_Ref(280)
		jump_Ref()
	
		walkSleep_Ref(430)
		walkSend_Ref("a","Up")
		walkSend_Ref("w","Down")
		walkSleep_Ref(145)
		jump_Ref() ; jump to 3rd cliff
	
	
		walkSleep_Ref(1785)
		walkSend_Ref("w","Up")
		walkSend_Ref("a","Down")
		walkSleep_Ref(4045)
		walkSend_Ref("a","Up")
		press_Ref("w", 1250)
		collect_Ref(1) ; collect item next to path 1 rock
		press_Ref("d", 1300)
		collect_Ref(1) ; collect item next on the edge
		
		walkSend_Ref("a","Down")
		walkSend_Ref("s","Down")
		walkSleep_Ref(800)
		jump_Ref()
	
		walkSleep_Ref(395)
		walkSend_Ref("s","Up")
		walkSleep_Ref(2285)
		walkSend_Ref("a","Up")
		collect_Ref(1)
	
		walkSleep_Ref(75)
		walkSend_Ref("s","Down")
		walkSend_Ref("d","Down")
		walkSleep_Ref(3280)
		walkSend_Ref("d","Up")
		
		walkSleep_Ref(2422)
		walkSend_Ref("s","Up")
		press_Ref("a", 668)
		collect_Ref(1)
	
		press_Ref2("w", "d", 2476)
		press_Ref("d", 625)
		press_Ref("w", 350)
		collect_Ref(1)
		
	} else {
		walkSend_Ref("w","Down")
		walkSleep_Ref(5387)
		walkSend_Ref("w","Up")
		walkSleep_Ref(150)
		press_Ref("s", 230)
		walkSend_Ref("w","Down")
		walkSleep_Ref(150)
		jump_Ref() ; jump to cliff

		press_Ref("a", 3550)
		walkSend_Ref("w","Up")
		collect_Ref(1) ; collect item on the first cliff
		press_Ref("s", 355)
		press_Ref("d", 385)
		walkSend_Ref("a","Down") ; jump to second cliff
		walkSleep_Ref(280)
		jump_Ref()

		walkSleep_Ref(430)
		walkSend_Ref("a","Up")
		walkSend_Ref("w","Down")
		walkSleep_Ref(145)
		jump_Ref() ; jump to 3rd cliff


		walkSleep_Ref(2185)
		walkSend_Ref("w","Up")
		walkSend_Ref("a","Down")
		walkSleep_Ref(5055)
		walkSend_Ref("a","Up")
		press_Ref("w", 1450)
		collect_Ref(1) ; collect item next to path 1 rock
		press_Ref("d", 1650)
		collect_Ref(1) ; collect item next on the edge
		
		walkSend_Ref("a","Down")
		walkSend_Ref("s","Down")
		walkSleep_Ref(1135)
		jump_Ref()

		walkSleep_Ref(395)
		walkSend_Ref("s","Up")
		walkSleep_Ref(2585)
		walkSend_Ref("a","Up")
		collect_Ref(1)

		walkSleep_Ref(75)
		walkSend_Ref("s","Down")
		walkSend_Ref("d","Down")
		walkSleep_Ref(3880)
		walkSend_Ref("d","Up")
		
		walkSleep_Ref(3422)
		walkSend_Ref("s","Up")
		press_Ref("a", 868)
		collect_Ref(1)

		press_Ref2("w", "d", 3176)
		press_Ref("d", 525)
		press_Ref("w", 450)
		collect_Ref(1)
	}
	
}

Spot2() {

	if (options_Ref.VIP = 1) {
		walkSend_Ref("w","Down")
		walkSleep_Ref(4950)
		walkSend_Ref("w","Up")
		walkSend_Ref("d","Down")
		walkSleep_Ref(1850)
		walkSend_Ref("d","Up")
		press_Ref2("w", "a", 2150)
		press_Ref("a", 450)
		walkSleep_Ref(150)
		press_Ref("s", 140) ; edge aligning
	
		walkSleep_Ref(150)
		press_Ref("d", 1230)
		walkSleep_Ref(50)
		walkSend_Ref("d","Down")
		walkSend_Ref("s","Down")
		walkSleep_Ref(2485) ; stop at semi-tree obby
		walkSend_Ref("d","Up")
		walkSend_Ref("s","Up")
		walkSleep_Ref(50)
		press_Ref("d", 750)
		collect_Ref(2) ; collect item near semi-tree
		walkSend_Ref("d","Down")
		walkSleep_Ref(2389)
		walkSend_Ref("d","Up")
		walkSend_Ref("w","Down") ; going to next item collect in path 2
		walkSleep_Ref(2867)
		walkSend_Ref("w","Up")
		walkSend_Ref("d","Down")
		walkSleep_Ref(1165)
		walkSend_Ref("d","Up")
		press_Ref("w", 1230)
		press_Ref("d", 750)
		collect_Ref(2) ; collect item near 2nd tree
	
		; moving to next item collect in path 2
		walkSend_Ref("s","Down")
		walkSleep_Ref(2495)
		jump_Ref() ; jump to 1st cliff
		walkSleep_Ref(2995)
		jump_Ref() ; jump to 2nd cliff
		walkSleep_Ref(2674)
		walkSend_Ref("s","Up")
		walkSleep_Ref(85)
		press_Ref("a", 520)
		collect_Ref(2) ; collect item near 3rd tree
	
		walkSend_Ref("w","Down")
		walkSleep_Ref(2980)
		walkSend_Ref("w","Up")
		press_Ref("d", 2230)
		press_Ref("s", 934)
		collect_Ref(2) ; collect last item in path 2

	}
}

Spot3() {

	if (options_Ref.VIP = 1) {
		walkSend_Ref("w","Down")
        walkSleep_Ref(5387)
        walkSend_Ref("w","Up")
        walkSleep_Ref(150)
        press_Ref("s", 230)
        walkSend_Ref("w","Down")
        walkSleep_Ref(150)
        jump_Ref() ; jump to cliff
    
        press_Ref("a", 3550)
        walkSend_Ref("w","Up")
        collect_Ref(1) ; collect item on the first cliff
        press_Ref("s", 355)
        press_Ref("d", 385)
        walkSend_Ref("a","Down") ; jump to second cliff
        walkSleep_Ref(280)
        jump_Ref()
    
        walkSleep_Ref(430)
        walkSend_Ref("a","Up")
        walkSend_Ref("w","Down")
        walkSleep_Ref(145)
        jump_Ref() ; jump to 3rd cliff
    
    
        walkSleep_Ref(1785)
        walkSend_Ref("w","Up")
        walkSend_Ref("a","Down")
        walkSleep_Ref(4045)
        walkSend_Ref("a","Up")
        press_Ref("w", 1250)
        collect_Ref(3) ; collect item next to path 1 rock
        press_Ref("d", 1300)
        collect_Ref(3) ; collect item next on the edge
        
        walkSend_Ref("a","Down")
        walkSend_Ref("s","Down")
        walkSleep_Ref(655)
        jump_Ref()
    
        walkSleep_Ref(395)
        walkSend_Ref("s","Up")
        walkSleep_Ref(2285)
        walkSend_Ref("a","Up")
        collect_Ref(3)
    
        walkSleep_Ref(75)
        walkSend_Ref("s","Down")
        walkSend_Ref("d","Down")
        walkSleep_Ref(3280)
        walkSend_Ref("d","Up")
        
        walkSleep_Ref(2422)
        walkSend_Ref("s","Up")
        press_Ref("a", 668)
        collect_Ref(3)


        ; next item collect
        walkSend_Ref("a","Down") ; jump on next cliff
        walkSleep_Ref(234)
        jump_Ref()
        walkSleep_Ref(884)
        walkSend_Ref("a","Up")
        walkSend_Ref("s","Down")
        walkSleep_Ref(2679)
        walkSend_Ref("s","Up")
        press_Ref2("a", "s", 1738)
        press_Ref("s", 3286)
        press_Ref("a", 430)
        collect_Ref(3)

        ; next item collect 2
        walkSend_Ref("s","Down")
        walkSleep_Ref(1880)
        jump_Ref()
        walkSleep_Ref(83)
        walkSend_Ref("s","Up")
        walkSleep_Ref(350)
        walkSend_Ref("s","Down")
        walkSleep_Ref(78)
        jump_Ref()
        walkSleep_Ref(220)
        walkSend_Ref("s","Up")
        press_Ref("a", 1685)
        collect_Ref(3)
        press_Ref2("s", "d", 840)
        walkSend_Ref("s","Down")
        walkSleep_Ref(2256)
        walkSend_Ref("s","Up")
        walkSend_Ref("d","Down")
        walkSleep_Ref(688)
        walkSend_Ref("d","Up")
        collect_Ref(3)
	}
}

Spot4() {

	if (options_Ref.VIP = 1) {
		walkSend_Ref("s","Down")
        walkSleep_Ref(3500)
        press_Ref("a", 2450)
        walkSleep_Ref(360)
        walkSend_Ref("s","Up")
        press_Ref("d", 750)
        press_Ref("s", 950)
        walkSleep_Ref(360)
        press_Ref("w", 260)
        walkSleep_Ref(120)
        walkSend_Ref("s","Down")
        walkSleep_Ref(153)
        jump_Ref()
        walkSleep_Ref(1879)
        walkSend_Ref("s","Up")
        press_Ref("a", 1430)
        walkSleep_Ref(160)
        press_Ref("s", 5840)
        walkSleep_Ref(100)
        press_Ref("a", 1468)
        walkSleep_Ref(100)
        walkSend_Ref("s","Down")
        walkSleep_Ref(1350)
        press_Ref("a", 70)
        walkSleep_Ref(120)
        press_Ref("a", 85)
        walkSleep_Ref(120)
        press_Ref("a", 85)
        walkSleep_Ref(120)
        press_Ref("a", 85)
        walkSleep_Ref(120)
        walkSend_Ref("s","Up")
        press_Ref2("a", "s", 2168)
        walkSleep_Ref(120)
        press_Ref("d", 270)
        walkSleep_Ref(120)
        press_Ref("w", 230)
        walkSleep_Ref(120)
        walkSend_Ref("s","Down")
        walkSleep_Ref(160)
        jump_Ref()
        walkSleep_Ref(688)
        walkSend_Ref("s","Up")
        walkSend_Ref("a","Down")
        walkSleep_Ref(115)
        jump_Ref()
        walkSleep_Ref(350)
        walkSend_Ref("a","Up")
        press_Ref("s", 450)
        collect_Ref(4)

        press_Ref("a", 2889)
        collect_Ref(4)
        press_Ref("a", 665)
        press_Ref2("s", "a", 390)
        press_Ref("a", 440)
        collect_Ref(4)

        walkSend_Ref("d","Down")
        walkSleep_Ref(197)
        jump_Ref()
        walkSleep_Ref(1300)
        walkSend_Ref("w","Down")
        walkSleep_Ref(1178)
        walkSend_Ref("w","Up")
        walkSleep_Ref(2913)
        walkSend_Ref("d","Up")
        press_Ref("s", 1285)
        collect_Ref(4)

        press_Ref("w", 765)
        walkSleep_Ref(100)
        walkSend_Ref("d","Down")
        walkSleep_Ref(1189)
        jump_Ref()
        walkSleep_Ref(1166)
        walkSend_Ref("d","Up")
        press_Ref("s", 1442)

        walkSleep_Ref(350)
        walkSend_Ref("d","Down")
        walkSleep_Ref(750)
        press_Ref("s", 85)
        walkSleep_Ref(230)
        press_Ref("s", 85)
        walkSleep_Ref(230)
        press_Ref("s", 85)
        walkSleep_Ref(230)
        press_Ref("s", 125)
        walkSend_Ref("d","Up")
        collect_Ref(4)
	}
}



if options_Ref["ItemSpot1"] {
    Spot1()
    reset_Ref()
    Sleep, 1800
}

if options_Ref["ItemSpot2"] {
    Spot2()
    reset_Ref()
    Sleep, 1800
}

if options_Ref["ItemSpot3"] {
    Spot3()
    reset_Ref()
    Sleep, 1800
}

if options_Ref["ItemSpot4"] {
    Spot4()
    reset_Ref()
    Sleep, 1800
}

; if options_Ref["ItemSpot5"] {
;     Spot5()
;     reset_Ref()
;     Sleep, 1800
; }

; if options_Ref["ItemSpot6"] {
;     Spot6()
;     reset_Ref()
;     Sleep, 1800
; }

; if options_Ref["ItemSpot7"] {
;     Spot7()
;     reset_Ref()
;     Sleep, 1800
; }

; if options_Ref["ItemSpot8"] {
;     if options_Ref.VIP {
;         Spot8VIP()
;     } else {
;         Spot8()
;     }
;     reset_Ref()
;     Sleep, 1800
; }