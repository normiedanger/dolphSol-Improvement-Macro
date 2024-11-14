#SingleInstance, Force
SetWorkingDir, %A_ScriptDir%

; Reference script for paths

getINIData_Ref(path){
    FileRead, retrieved, %path%

    retrievedData := {}
    readingPoint := 0

    if (!ErrorLevel){
        ls := StrSplit(retrieved,"`r`n")
        for i,v in ls {
            isHeader := RegExMatch(v,"\[(.*)]")
            if (v && readingPoint && !isHeader){
                RegExMatch(v,"(.*)(?==)",index)
                RegExMatch(v,"(?<==)(.*)",value)
                if (index){
                    retrievedData[index] := value
                }
            } else if (isHeader){
                readingPoint := 1
            }
        }
    } else {
        MsgBox, An error occurred while reading %path% data, please review the file.
        return
    }
    return retrievedData
}
global options_Ref = getINIData_Ref("..\settings\config.ini")

global regWalkFactor_Ref := 1.25 ; since i made the paths all with vip, normalize

getWalkTime_Ref(d){
    baseTime := d * (1 + (regWalkFactor_Ref - 1) * (1 - options_Ref.VIP))
    
    if (options_Ref.Shifter) {
        baseTime := baseTime / 1.50
    }
    
    return baseTime
}

walkSleep_Ref(d){
    Sleep, % getWalkTime_Ref(d)
}

global azertyReplace_Ref := {"w":"z","a":"q"}

walkSend_Ref(k,t){
    if (options_Ref.AzertyLayout && azertyReplace_Ref[k]){
        k := azertyReplace_Ref[k]
    }
    Send, % "{" . k . (t ? " " . t : "") . "}"
}

press_Ref(k, duration := 50) {
    walkSend_Ref(k,"Down")
    walkSleep_Ref(duration)
    walkSend_Ref(k,"Up")
}
press_Ref2(k, k2, duration := 50) {
    walkSend_Ref(k,"Down")
    walkSend_Ref(k2,"Down")
    walkSleep_Ref(duration)
    walkSend_Ref(k,"Up")
    walkSend_Ref(k2,"Up")
}

reset_Ref() {
    press_Ref("Esc")
    Sleep, 100
    press_Ref("r")
    Sleep, 100
    press_Ref("Enter")
    Sleep, 100
}

jump_Ref() {
    press_Ref("Space")
}

collect_Ref(num){
    if (!options_Ref["ItemSpot" . num]){
        return
    }
    Loop, 5
    {
        Send {f}
        Sleep, 100
    }
    Send {e}
    Sleep, 100
}

isFullscreen_Ref() {
	WinGetPos,,, w, h, Roblox
	return (w = A_ScreenWidth && h = A_ScreenHeight)
}

GetRobloxHWND_Ref()
{
	if (hwnd := WinExist("Roblox ahk_exe RobloxPlayerBeta.exe"))
		return hwnd
	else if (WinExist("Roblox ahk_exe ApplicationFrameHost.exe"))
	{
		ControlGet, hwnd, Hwnd, , ApplicationFrameInputSinkWindow1
		return hwnd
	}
	else
		return 0
}

getRobloxPos_Ref(ByRef x := "", ByRef y := "", ByRef width := "", ByRef height := "", hwnd := ""){
    if !hwnd
        hwnd := GetRobloxHWND_Ref()
    VarSetCapacity( buf, 16, 0 )
    DllCall( "GetClientRect" , "UPtr", hwnd, "ptr", &buf)
    DllCall( "ClientToScreen" , "UPtr", hwnd, "ptr", &buf)

    x := NumGet(&buf,0,"Int")
    y := NumGet(&buf,4,"Int")
    width := NumGet(&buf,8,"Int")
    height := NumGet(&buf,12,"Int")
}

getColorComponents_Ref(color){
    return [color & 255, (color >> 8) & 255, (color >> 16) & 255]
}

compareColors_Ref(color1, color2) ; determines how far apart 2 colors are
{
    color1V := getColorComponents_Ref(color1)
    color2V := getColorComponents_Ref(color2)

    cV := [color1V[1] - color2V[1], color1V[2] - color2V[2], color1V[3] - color2V[3]]
    dist := Abs(cV[1]) + Abs(cV[2]) + Abs(cV[3])
    return dist
}

closeChat_Ref(){
    getRobloxPos_Ref(pX,pY,width,height)
    PixelGetColor, chatCheck, % pX + 75, % pY + 12, RGB
    if (compareColors_Ref(chatCheck,0xffffff) < 16){ ; is chat open??
        MouseMove, % pX + 75, % pY + 12
        Sleep, 300
        MouseClick
        Sleep, 100
    }
}

global menuBarOffset_Ref := 10 ;10 pixels from left edge

getMenuButtonPosition_Ref(num, ByRef posX := "", ByRef posY := ""){ ; num is 1-7, 1 being top, 7 only existing if you are the private server owner
    getRobloxPos_Ref(rX, rY, width, height)

    menuBarVSpacing := 10.5*(height/1080)
    menuBarButtonSize := 58*(width/1920)
    menuEdgeCenter := [rX + menuBarOffset_Ref, rY + (height/2)]
    startPos := [menuEdgeCenter[1]+(menuBarButtonSize/2),menuEdgeCenter[2]+(menuBarButtonSize/4)-(menuBarButtonSize+menuBarVSpacing-1)*3.5] ; final factor = 0.5x (x is number of menu buttons visible to all, so exclude private server button)
    
    posX := startPos[1]
    posY := startPos[2] + (menuBarButtonSize+menuBarVSpacing)*(num-1)

    MouseMove, % posX, % posY
}

clickMenuButton_Ref(num){
    getMenuButtonPosition_Ref(num, posX, posY)
    MouseMove, posX, posY
    Sleep, 200
    MouseClick
}

rotateCameraMode_Ref(){
    press_Ref("Esc")
    Sleep, 500
    press_Ref("Tab")
    Sleep, 500
    press_Ref("Down")
    Sleep, 150
    press_Ref("Right")
    Sleep, 150
    press_Ref("Right")
    Sleep, 150
    press_Ref("Esc")
    Sleep, 250

    camFollowMode := !camFollowMode
}

alignCamera_Ref(){
    closeChat_Ref()
    Sleep, 200

    reset_Ref()
    Sleep, 100

    getRobloxPos_Ref(rX,rY,rW,rH)

    rotateCameraMode_Ref()

    clickMenuButton_Ref(2)
    Sleep, 500
    
    MouseMove, % rX + rW*0.15, % rY + 44 + rH*0.05 + options_Ref.BackOffset
    Sleep, 200
    MouseClick
    Sleep, 200

    rotateCameraMode_Ref()

    Sleep, 100

    walkSend_Ref("d","Down")
    walkSleep_Ref(200)
    jump_Ref()
    walkSleep_Ref(400)
    walkSend_Ref("d","Up")
    walkSend_Ref("w","Down")
    walkSleep_Ref(500)
    jump_Ref()
    walkSleep_Ref(900)
    walkSend_Ref("w","Up")

    rotateCameraMode_Ref()

    Sleep, 1500

    rotateCameraMode_Ref()

    reset_Ref()
    Sleep, 2000
}

global azertyReplace_Ref := {"w": "z", "a": "q"} 

sendKey_Ref(key, type = ""){
 azertyKey := azertyReplace_Ref[key]
 key := options_Ref.AzertyLayout && azertyKey ? azertyKey : key
 
 Send {%key% %type%}
}

arcaneTeleport_Ref(){
    press_Ref("x",50)
}