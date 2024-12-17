#singleinstance, force
#noenv
#persistent


global loggingEnabled := 1 ; disabled for public release, set to 1 to enable


OnError("LogError")
OnExit, ShowCursor

SetWorkingDir, % A_ScriptDir
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

#Include, GDIP_All.ahk
#Include, ocr.ahk
#Include, jxon.ahk
#Include, tesseract_ocr.ahk

Gdip_Startup()

global mainDir
RegExMatch(A_ScriptDir, "(.*)\\", mainDir)
global lastLoggedMessage := ""

global configPath := mainDir . "settings\config.ini"
global ssPath := "ss.jpg"
global biome_ssPath := "biome_ss.jpg"
global imageDir := mainDir . "images\"

logMessage("") ; empty line for separation
logMessage("status.ahk opened")

global webhookEnabled := 0
global webhookURL := ""
global discordID := ""
global discordGlitchID := ""
global sendMinimum := 10000
global pingMinimum := 100000
global recordEnabled := 0
global recordMinimum := 100000
global auraImages := 0

global rareDisplaying := 0

global currentBiome := "Normal"
global currentBiomeTimer := 0
global currentBiomeDisplayed := 0
global PrivateServerId = ""
global PrivateServerPre = "https://www.roblox.com/games/15532962292/Sols-RNG?privateServerLinkCode="

global biomeData := {"Normal":{color: 0xdddddd}
,"Windy":{color: 0x9ae5ff, duration: 120, display: 0, ping: 0}
,"Rainy":{color: 0x027cbd, duration: 120, display: 0, ping: 0}
,"Snowy":{color: 0xDceff9, duration: 120, display: 0, ping: 0}
,"Sandstorm":{color: 0x8F7057, duration: 600, display: 1, ping: 0}
,"Hell":{color: 0xff4719, duration: 660, display: 1, ping: 0}
,"Starfall":{color: 0x011ab7, duration: 600, display: 0, ping: 0}
,"Corruption":{color: 0x6d32a8, duration: 660, display: 0, ping: 0}
,"Null":{color: 0x838383, duration: 90, display: 0, ping: 0}
,"Glitched":{color: 0xbfff00, duration: 164, display: 1, ping: 1}}

global options := {}
global auraNames := []

global guis := Object(), timers := Object()

Highlight(x="", y="", w="", h="", showTime=2000, color="Red", d=2) {
    ; If no coordinates are provided, clear all highlights
    if (x = "" || y = "" || w = "" || h = "") {
        for key, timer in timers {
            SetTimer, % timer, Off
            Gui, %key%Top:Destroy
            Gui, %key%Left:Destroy
            Gui, %key%Bottom:Destroy
            Gui, %key%Right:Destroy
            guis.Delete(key)
        }
        timers := Object()
        return
    }

    x := Floor(x)
    y := Floor(y)
    w := Floor(w)
    h := Floor(h)

    ; Create a new highlight
    key := "Highlight" x y w h
    Gui, %key%Top:New, +AlwaysOnTop -Caption +ToolWindow
    Gui, %key%Top:Color, %color%
    Gui, %key%Top:Show, x%x% y%y% w%w% h%d%

    Gui, %key%Left:New, +AlwaysOnTop -Caption +ToolWindow
    Gui, %key%Left:Color, %color%
    Gui, %key%Left:Show, x%x% y%y% h%h% w%d%

    Gui, %key%Bottom:New, +AlwaysOnTop -Caption +ToolWindow
    Gui, %key%Bottom:Color, %color%
    Gui, %key%Bottom:Show, % "x"x "y"(y+h-d) "w"w "h"d

    Gui, %key%Right:New, +AlwaysOnTop -Caption +ToolWindow
    Gui, %key%Right:Color, %color%
    Gui, %key%Right:Show, % "x"(x+w-d) "y"y "w"d "h"h

    ; Store the gui and set a timer to remove it
    guis[key] := true
    if (showTime > 0) {
        timerKey := Func("RemoveHighlight").Bind(key)
        timers[key] := timerKey
        SetTimer, % timerKey, -%showTime%
    }
}

RemoveHighlight(key) {
    global guis, timers
    Gui, %key%Top:Destroy
    Gui, %key%Left:Destroy
    Gui, %key%Bottom:Destroy
    Gui, %key%Right:Destroy
    guis.Delete(key)
    timers.Delete(key)
}

FileRead, retrieved, %configPath%

if (!ErrorLevel){
    RegExMatch(retrieved, "(?<=WebhookEnabled=)(.*)", webhookEnabled)
    RegExMatch(retrieved, "(?<=WebhookLink=)(.*)", webhookURL)
    if (!webhookEnabled || !webhookURL){
        ExitApp
    }
    RegExMatch(retrieved, "(?<=DiscordUserID=)(.*)", discordID)
    RegExMatch(retrieved, "(?<=DiscordGlitchID=)(.*)", discordGlitchID)
    RegExMatch(retrieved, "(?<=WebhookRollSendMinimum=)(.*)", sendMinimum)
    RegExMatch(retrieved, "(?<=WebhookRollPingMinimum=)(.*)", pingMinimum)
    RegExMatch(retrieved, "(?<=WebhookAuraRollImages=)(.*)", auraImages)
    RegExMatch(retrieved, "(?<=RecordAuraMinimum=)(.*)", recordMinimum)
    RegExMatch(retrieved, "(?<=RecordAura=)(.*)", recordEnabled)
    RegExMatch(retrieved, "(?<=PrivateServerId=)(.*)", PrivateServerId)
} else {
    logMessage("An error occurred while reading config data. Discord messages will not be sent.")
    return
}

FileRead, staticDataContent, % "staticData.json"
global staticData := Jxon_Load(staticDataContent)[1]

; for defaulting <1m auras to have a black corner
for i,v in staticData.stars {
    if (v.rarity < 1000000 && !v.mutations){
        v.cornerColor := 0
    }
}

LogError(exc) {
    logMessage("[LogError] Error on line " exc.Line ": " exc.Message)
    FormatTime, fTime, , HH:mm:ss
    try webhookPost({embedContent: "[Error on line " exc.Line "]: " fTime " - " exc.Message, embedColor: 15548997})
}

checkOCRLanguage() {
    languages := ocr("ShowAvailableLanguages")
    if (languages) {
        logMessage("OCR languages installed:")
        logMessage(languages)

        if (InStr(languages, "en-US")) {
            return
        }
    } else {
        logMessage("An error occurred while checking for OCR languages")
    }

    ; Check if the script is running as admin
    if (!A_IsAdmin) {
        logMessage("status.ahk not running as admin")

        MsgBox, 4, , % "You will need the 'English (United States)' language pack installed to detect biomes.`n`n"
            . "Would you like to run this file as an administrator to attempt to install it automatically?"

        IfMsgBox Yes
            logMessage("Restarting status.ahk as admin")
            RunWait, *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
            return
    } else {
        logMessage("status.ahk running as admin")

        ; Give the option to auto install the language pack
        MsgBox, 4, , % "You will need the 'English (United States)' language pack installed to detect biomes.`n`n"
            . "Select 'No' to do it yourself through Settings > Time & Language > Language & Region > Add a language.`n"
            . "Select 'Yes' to attempt to install it automatically.`n`n"
            . "Both options will require you to log out and back in to take effect."

        IfMsgBox Yes
            logMessage("Attempting to install the language pack")
            try {
                RunWait, *RunAs powershell.exe -ExecutionPolicy Bypass Install-Language en-US
            } catch e {
                logMessage("An error occurred while attempting to install the language pack")
                logMessage(e, 1)
                MsgBox, 16, Error, % "An error occurred while attempting to install the language pack.`n`n"
                    . "Please install it manually through Settings > Time & Language > Language & Region > Add a language."
            }
    }
}
; checkOCRLanguage()

getUnixTime(){
    now := A_NowUTC
    EnvSub, now,1970, seconds
    return now
}

isFullscreen() {
	WinGetPos,,, w, h, Roblox
	return (w = A_ScreenWidth && h = A_ScreenHeight)
}

GetRobloxHWND()
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

getRobloxPos(ByRef x := "", ByRef y := "", ByRef width := "", ByRef height := "", hwnd := ""){
    if !hwnd
        hwnd := GetRobloxHWND()
    VarSetCapacity( buf, 16, 0 )
    DllCall( "GetClientRect" , "UPtr", hwnd, "ptr", &buf)
    DllCall( "ClientToScreen" , "UPtr", hwnd, "ptr", &buf)

    x := NumGet(&buf,0,"Int")
    y := NumGet(&buf,4,"Int")
    width := NumGet(&buf,8,"Int")
    height := NumGet(&buf,12,"Int")
}

getUV(x,y,oX,oY,width,height){
    return [((x-oX)*2 - width)/height,((y-oY)*2 - height)/height]
}
getFromUV(uX,uY,oX,oY,width,height){
    return [Floor((uX*height + width)/2)+oX,Floor((uY*height + height)/2)+oY]
}

global storageAspectRatio := 952/1649
global storageEquipUV := [-0.875,0.054] ; equip button

getAspectRatioSize(ratio, width, height){
    fH := width*ratio
    fW := height*(1/ratio)

    if (height >= fH){
        fW := width
    } else {
        fH := height
    }

    return [Floor(fW+0.5), Floor(fH+0.5)]
}

getPositionFromAspectRatioUV(x,y,aspectRatio){
    getRobloxPos(rX, rY, width, height)

    ar := getAspectRatioSize(aspectRatio, width, height)

    oX := Floor((width-ar[1])/2) + rX
    oY := Floor((height-ar[2])/2) + rY

    p := getFromUV(x,y,oX,oY,ar[1],ar[2]) ; [Floor((x*ar[2] + ar[1])/2)+oX,Floor((y*ar[2] + ar[2])/2)+oY]

    return p
}

getAspectRatioUVFromPosition(x,y,aspectRatio){
    getRobloxPos(rX, rY, width, height)

    ar := getAspectRatioSize(aspectRatio, width, height)

    oX := Floor((width-ar[1])/2) + rX
    oY := Floor((height-ar[2])/2) + rY

    p := getUV(x,y,oX,oY,ar[1],ar[2])

    return p
}

getColorComponents(color){
    return [color & 255, (color >> 8) & 255, (color >> 16) & 255]
}

compareColors(color1, color2) ; determines how far apart 2 colors are
{
    color1V := getColorComponents(color1)
    color2V := getColorComponents(color2)

    cV := [color1V[1] - color2V[1], color1V[2] - color2V[2], color1V[3] - color2V[3]]
    dist := Abs(cV[1]) + Abs(cV[2]) + Abs(cV[3])
    return dist
}

getINIData(path){
    FileRead, retrieved, %path%

    if (!retrieved){
        logMessage("[getINIData] No data found in " path)
        MsgBox, An error occurred while reading %path% data, please review the file.
        return
    }

    retrievedData := {}
    readingPoint := 0

    ls := StrSplit(retrieved,"`n")
        for i,v in ls {
            ; Remove any carriage return characters
            v := Trim(v, "`r")

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
    return retrievedData
}

loadWebhookSettings(){
    global
    logMessage("") ; empty line for separation
    logMessage("[loadData] Loading config data from " configPath)

    local savedRetrieve := getINIData(configPath)
    if (!savedRetrieve){
        logMessage("[loadData] Unable to retrieve config data, Resetting to defaults.")
        MsgBox, Unable to retrieve config data, your settings have been set to their defaults.
        savedRetrieve := {}
    }

    ; Load Biome OCR values
    options["Biome_OCR_X"] := savedRetrieve.HasKey("Biome_OCR_X") ? savedRetrieve["Biome_OCR_X"] : 4
    options["Biome_OCR_Y"] := savedRetrieve.HasKey("Biome_OCR_Y") ? savedRetrieve["Biome_OCR_Y"] : 903
    options["Biome_OCR_W"] := savedRetrieve.HasKey("Biome_OCR_W") ? savedRetrieve["Biome_OCR_W"] : 228
    options["Biome_OCR_H"] := savedRetrieve.HasKey("Biome_OCR_H") ? savedRetrieve["Biome_OCR_H"] : 31

    ; Load aura names from JSON
    auraNames := []
    for key, value in staticData.stars {
        auraNames.push(value.name)
        if (value.mutations) {
            for index, mutation in value.mutations {
                auraNames.push(mutation.name)
            }
        }
    }

    ; Load aura settings with prefix
    for index, auraName in auraNames {
        sAuraName := RegExReplace(auraName, "[^a-zA-Z0-9]+", "_") ; Replace all non-alphanumeric characters with underscore
        sAuraName := RegExReplace(sAuraName, "\_$", "") ; Remove any trailing underscore
        key := "wh" . sAuraName
        if (savedRetrieve.HasKey(key)) {
            options[key] := savedRetrieve[key]
        } else {
            options[key] := 1 ; default value
        }
        ; logMessage("[loadData] Aura: " auraName " - " sAuraName " - " options[key])
    }

    ; Load biome settings
    for biome in biomeData {
        key := "Biome" . biome
        if (savedRetrieve.HasKey(key)) {
            biomeData[biome].ping := savedRetrieve[key] = "Ping" ? 1 : 0
            ; Technically not required since Ping overrides Display anyway. Might be required after future changes
            biomeData[biome].display := savedRetrieve[key] = "Message" ? 1 : 0
            ; logMessage("[loadData] Biome: " biome " - d:" biomeData[biome].display ", p:" biomeData[biome].ping)
        }
    }
}
loadWebhookSettings()

webhookPost1(data := 0){ ; test
    data := data ? data : {}

    url := testURL1

    if (!url){
        ExitApp
    }

    ; Append extra ping id for glitch biome - can be a role or a user. role is prefixed with "&"
    if (data.biome && data.biome = "Glitched" && discordGlitchID) {
        data.content := data.content ? data.content " <" discordID_i ">" : "<" discordID_i ">"
    }

    ; Append extra ping id for auras containing "Apex"
    apexPingID := "" ; can be a role or a user. role is prefixed with "&"
    if (data.auraName && apexPingID && InStr(data.auraName, "Apex")) {
        data.content := data.content ? data.content " <@" apexPingID ">" : "<@" apexPingID ">"
    }

    payload_json := "
		(LTrim Join
		{
			""content"": """ data.content """,
			""embeds"": [{
                " (data.embedAuthor ? """author"": {""name"": """ data.embedAuthor """" (data.embedAuthorImage ? ",""icon_url"": """ data.embedAuthorImage """" : "") "}," : "") "
                " (data.embedTitle ? """title"": """ data.embedTitle """," : "") "
				""description"": """ data.embedContent """,
                " (data.embedThumbnail ? """thumbnail"": {""url"": """ data.embedThumbnail """}," : "") "
                " (data.embedImage ? """image"": {""url"": """ data.embedImage """}," : "") "
                " (data.embedFooter ? """footer"": {""text"": """ data.embedFooter """}," : "") "
				""color"": """ (data.embedColor ? data.embedColor : 0) """
			}]
		}
		)"

    if ((!data.embedContent && !data.embedTitle) || data.noEmbed)
        payload_json := RegExReplace(payload_json, ",.*""embeds.*}]", "")


    objParam := {payload_json: payload_json}

    for i,v in (data.files ? data.files : []) {
        objParam["file" i] := [v]
    }

    CreateFormData(postdata,hdr_ContentType,objParam)

    WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    WebRequest.Open("POST", url, true)
    WebRequest.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko")
    WebRequest.SetRequestHeader("Content-Type", hdr_ContentType)
    WebRequest.SetRequestHeader("Pragma", "no-cache")
    WebRequest.SetRequestHeader("Cache-Control", "no-cache, no-store")
    WebRequest.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
    WebRequest.Send(postdata)
    WebRequest.WaitForResponse()
}

commaFormat(num){
    len := StrLen(num)
    final := ""
    Loop %len% {
        char := (len-A_Index)+1
        if (Mod(A_Index-1,3) = 0 && A_Index <= len && A_Index-1){
            final := "," . final
        }
        final := SubStr(num, char, 1) . final
    }
    return final
}

; CreateFormData() by tmplinshi, AHK Topic: https://autohotkey.com/boards/viewtopic.php?t=7647
; Thanks to Coco: https://autohotkey.com/boards/viewtopic.php?p=41731#p41731
; Modified version by SKAN, 09/May/2016
; Rewritten by iseahound in September 2022

CreateFormData(ByRef retData, ByRef retHeader, objParam) {
	New CreateFormData(retData, retHeader, objParam)
}

Class CreateFormData {

    __New(ByRef retData, ByRef retHeader, objParam) {

        Local CRLF := "`r`n", i, k, v, str, pvData
        ; Create a random Boundary
        Local Boundary := this.RandomBoundary()
        Local BoundaryLine := "------------------------------" . Boundary

        ; Create an IStream backed with movable memory.
        hData := DllCall("GlobalAlloc", "uint", 0x2, "uptr", 0, "ptr")
        DllCall("ole32\CreateStreamOnHGlobal", "ptr", hData, "int", False, "ptr*", pStream:=0, "uint")
        this.pStream := pStream

        ; Loop input paramters
        For k, v in objParam
        {
            If IsObject(v) {
                For i, FileName in v
                {
                    str := BoundaryLine . CRLF
                    . "Content-Disposition: form-data; name=""" . k . """; filename=""" . FileName . """" . CRLF
                    . "Content-Type: " . this.MimeType(FileName) . CRLF . CRLF

                    this.StrPutUTF8( str )
                    this.LoadFromFile( Filename )
                    this.StrPutUTF8( CRLF )

                }
            } Else {
                str := BoundaryLine . CRLF
                . "Content-Disposition: form-data; name=""" . k """" . CRLF . CRLF
                . v . CRLF
                this.StrPutUTF8( str )
            }
        }

        this.StrPutUTF8( BoundaryLine . "--" . CRLF )

        this.pStream := ObjRelease(pStream) ; Should be 0.
        pData := DllCall("GlobalLock", "ptr", hData, "ptr")
        size := DllCall("GlobalSize", "ptr", pData, "uptr")

        ; Create a bytearray and copy data in to it.
        retData := ComObjArray( 0x11, size ) ; Create SAFEARRAY = VT_ARRAY|VT_UI1
        pvData  := NumGet( ComObjValue( retData ), 8 + A_PtrSize , "ptr" )
        DllCall( "RtlMoveMemory", "Ptr", pvData, "Ptr", pData, "Ptr", size )

        DllCall("GlobalUnlock", "ptr", hData)
        DllCall("GlobalFree", "Ptr", hData, "Ptr")                   ; free global memory

        retHeader := "multipart/form-data; boundary=----------------------------" . Boundary
    }

    StrPutUTF8( str ) {
        length := StrPut(str, "UTF-8") - 1 ; remove null terminator
        VarSetCapacity(utf8, length)
        StrPut(str, &utf8, length, "UTF-8")
        DllCall("shlwapi\IStream_Write", "ptr", this.pStream, "ptr", &utf8, "uint", length, "uint")
    }

    LoadFromFile( filepath ) {
        DllCall("shlwapi\SHCreateStreamOnFileEx"
                    ,   "wstr", filepath
                    ,   "uint", 0x0             ; STGM_READ
                    ,   "uint", 0x80            ; FILE_ATTRIBUTE_NORMAL
                    ,    "int", False           ; fCreate is ignored when STGM_CREATE is set.
                    ,    "ptr", 0               ; pstmTemplate (reserved)
                    ,   "ptr*", pFileStream:=0
                    ,   "uint")
        DllCall("shlwapi\IStream_Size", "ptr", pFileStream, "uint64*", size:=0, "uint")
        DllCall("shlwapi\IStream_Copy", "ptr", pFileStream , "ptr", this.pStream, "uint", size, "uint")
        ObjRelease(pFileStream)
    }

    RandomBoundary() {
        str := "0|1|2|3|4|5|6|7|8|9|a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z"
        Sort, str, D| Random
        str := StrReplace(str, "|")
        Return SubStr(str, 1, 12)
    }

    MimeType(FileName) {
        n := FileOpen(FileName, "r").ReadUInt()
        Return (n        = 0x474E5089) ? "image/png"
            :  (n        = 0x38464947) ? "image/gif"
            :  (n&0xFFFF = 0x4D42    ) ? "image/bmp"
            :  (n&0xFFFF = 0xD8FF    ) ? "image/jpeg"
            :  (n&0xFFFF = 0x4949    ) ? "image/tiff"
            :  (n&0xFFFF = 0x4D4D    ) ? "image/tiff"
            :  "application/octet-stream"
    }
}

webhookPost(data := 0){
    data := data ? data : {}

    url := webhookURL

    if (!url){
        ExitApp
    }

    if (data.pings){
        data.content := data.content ? data.content " <@" discordID ">" : "<@" discordID ">"
    }

    ; Append extra ping id for glitch biome - can be a role or a user. role is prefixed with "&"
    if (data.biome && data.biome = "Glitched" && discordGlitchID) {
        data.content := data.content ? data.content " <@" discordGlitchID ">" : "<@" discordGlitchID ">"
    }

    ; Append extra ping id for auras containing "Apex"
    apexPingID := "" ; can be a role or a user. role is prefixed with "&"
    if (data.auraName && apexPingID && InStr(data.auraName, "Apex")) {
        data.content := data.content ? data.content " <@" apexPingID ">" : "<@" apexPingID ">"
    }

    payload_json := "
		(LTrim Join
		{
			""content"": """ data.content """,
			""embeds"": [{
                " (data.embedAuthor ? """author"": {""name"": """ data.embedAuthor """" (data.embedAuthorImage ? ",""icon_url"": """ data.embedAuthorImage """" : "") "}," : "") "
                " (data.embedTitle ? """title"": """ data.embedTitle """," : "") "
				""description"": """ data.embedContent """,
                " (data.embedThumbnail ? """thumbnail"": {""url"": """ data.embedThumbnail """}," : "") "
                " (data.embedImage ? """image"": {""url"": """ data.embedImage """}," : "") "
                " (data.embedFooter ? """footer"": {""text"": """ data.embedFooter """}," : "") "
				""color"": """ (data.embedColor ? data.embedColor : 0) """
			}]
		}
		)"

    if ((!data.embedContent && !data.embedTitle) || data.noEmbed)
        payload_json := RegExReplace(payload_json, ",.*""embeds.*}]", "")


    objParam := {payload_json: payload_json}

    for i,v in (data.files ? data.files : []) {
        objParam["file" i] := [v]
    }

    CreateFormData(postdata,hdr_ContentType,objParam)

    WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    WebRequest.Open("POST", url, true)
    WebRequest.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko")
    WebRequest.SetRequestHeader("Content-Type", hdr_ContentType)
    WebRequest.SetRequestHeader("Pragma", "no-cache")
    WebRequest.SetRequestHeader("Cache-Control", "no-cache, no-store")
    WebRequest.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
    WebRequest.Send(postdata)
    WebRequest.WaitForResponse()
}

Merchant_Webhook_Main(Merchant_Name, webhook_url, ps_link := "", ping_user_id := "", embedField := "") {
    getRobloxPos(rX, rY, w, h)
    ssMap := Gdip_BitmapFromScreen(rX "|" rY "|" w "|" h)
    Gdip_SaveBitmapToFile(ssMap, merchant_ssPath)
    Gdip_DisposeBitmap(ssMap)

    ;message content (only ping if ping_user_id is provided)
    if (ping_user_id != "") {
        messageContent := "<@" ping_user_id ">"
    } else {
        messageContent := ""
    }

    if (ps_link) {
        messageContent .= " " ps_link
    }

    ; Format the merchant name properly
    StringUpper, Merchant_Name, Merchant_Name, T

    embedContent := Merchant_Name " has been detected on your screen."
    embedTitle := "**" Merchant_Name " Detected!**"
    embedColor := (Merchant_Name = "Mari") ? "255" : "8388736"  ; Blue for Mari, Purple for others
    embedThumbnail := (Merchant_Name = "Mari")
        ? "https://static.wikia.nocookie.net/sol-rng/images/3/37/MARI_HIGH_QUALITYY.png/revision/latest?cb=20240704045119"
        : "https://static.wikia.nocookie.net/sol-rng/images/d/db/Headshot_of_Jester.png/revision/latest?cb=20240630142936"

    ; Construct the payload for the webhook
    payload_json := "{""content"": """ messageContent ""","
                  . """embeds"": [{"
                  . """title"": """ embedTitle ""","
                  . """description"": """ embedContent ""","
                  . """color"": " embedColor ","
                  . """thumbnail"": {""url"": """ embedThumbnail """},"
                  . """image"": {""url"": ""attachment://hewo_merchant.jpg""},"
                  . """fields"": [{""name"": ""**" embedField "**"",""value"": """"}],"
                  . """footer"": {""text"": ""Auto Merchant Detection""}"
                  . "}]}"

    ; Loop all webhook URLs and send the notification in parallel
    ; for i, url in webhook_urls {}
    try {
        objParam := {payload_json: payload_json}
        objParam["file0"] := [merchant_ssPath]
        Merchant_Webhook_Send(webhook_url, objParam)  ; Send the webhook

    } catch e {
        logMessage("Error sending webhook to " webhook_url ": " e, 1)
    }
}

Merchant_Webhook_Send(url, objParam) {
    try {
        CreateFormData(postdata, hdr_ContentType, objParam)

        WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        WebRequest.Open("POST", url, true)
        WebRequest.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko")
        WebRequest.SetRequestHeader("Content-Type", hdr_ContentType)
        WebRequest.Send(postdata)
        WebRequest.WaitForResponse()

    } catch e {
        logMessage("[Webhook_Send] Error sending data: " e, 1)
    }
}

global similarCharacters := {"1":"l"
    ,"n":"m"
    ,"o":"d"
    ,"O":"D"
    ,"m":"n"
    ,"t":"f"
    ,"f":"t"
    ,"s":"S"
    ,"S":"s"
    ,"w":"W"
    ,"W":"w"
    ,"V":"Y"}

    identifyBiome(inputStr){
        if (!inputStr)
            return 0

        internalStr := RegExReplace(inputStr,"\s")
        internalStr := RegExReplace(internalStr,"^([\[\(\{\|IJ]+)")
        internalStr := RegExReplace(internalStr,"([\]\)\}\|IJ]+)$")

        highestRatio := 0
        matchingBiome := ""

        for v,_ in biomeData {
            if (v = "Glitched"){
                continue
            }
            scanIndex := 1
            accuracy := 0
            Loop % StrLen(v) {
                checkingChar := SubStr(v,A_Index,1)
                Loop % StrLen(internalStr) - scanIndex + 1 {
                    index := scanIndex + A_Index - 1
                    targetChar := SubStr(internalStr, index, 1)
                    if (targetChar = checkingChar){
                        accuracy += 3 - A_Index
                        scanIndex := index+1
                        break
                    } else if (similarCharacters[targetChar] = checkingChar){
                        accuracy += 2.5 - A_Index
                        scanIndex := index+1
                        break
                    }
                }
            }
            ratio := accuracy/(StrLen(v)*2)
            if (ratio > highestRatio){
                matchingBiome := v
                highestRatio := ratio
            }
        }

        if (highestRatio < 0.70){
            matchingBiome := 0
            glitchedCheck := StrLen(internalStr)-StrLen(RegExReplace(internalStr,"\d")) + (RegExMatch(internalStr,"\.") ? 4 : 0)
            if (glitchedCheck >= 20){
                OutputDebug, % "glitched biome pro!"
                matchingBiome := "Glitched"
            }
        }

        return matchingBiome
}


determineBiome(){
    ; logMessage("[determineBiome] Determining biome...")
    ; if (!WinActive("ahk_id " GetRobloxHWND()) && !WinActive("Roblox")){
    ;     logMessage("[determineBiome] Roblox window not active.")
    ;     Sleep, 5000
    ;     return
    ; }
    getRobloxPos(rX,rY,width,height)
    
    x := options["Biome_OCR_X"]
    y := options["Biome_OCR_Y"]
    w := options["Biome_OCR_W"]
    h := options["Biome_OCR_H"]

    identifiedBiome := 0
    Loop 20 {
        st := A_TickCount

        ocrResult := CaptureScreen(x,y,w,h)
        ;logMessage("[determineBiome] Biome OCR result: " ocrResult)
        identifiedBiome := identifyBiome(ocrResult)
        

        if (identifiedBiome){
            break
        }
    }

    if (identifiedBiome && identifiedBiome != "Normal") {
        ; logMessage("[determineBiome] OCR result: " RegExReplace(ocrResult,"(\n|\r)+",""))
        ; logMessage("[determineBiome] Identified biome: " identifiedBiome)
        pBM := Gdip_BitmapFromScreen(x "|" y "|" w "|" h)
        effect := Gdip_CreateEffect(3,"2|0|0|0|0" . "|" . "0|1.5|0|0|0" . "|" . "0|0|1|0|0" . "|" . "0|0|0|1|0" . "|" . "0|0|0.2|0|1",0)
        effect2 := Gdip_CreateEffect(5, -80,250)
        effect3 := Gdip_CreateEffect(2,5,30)
        Gdip_BitmapApplyEffect(pBM,effect)
        Gdip_BitmapApplyEffect(pBM,effect2)
        Gdip_BitmapApplyEffect(pBM,effect3)
        Gdip_SaveBitmapToFile(pBM,ssPath)

        Gdip_DisposeEffect(effect)
        Gdip_DisposeEffect(effect2)
        Gdip_DisposeEffect(effect3)
        Gdip_DisposeBitmap(retrievedMap)
        Gdip_DisposeBitmap(pBM)
    }

    

    DllCall("psapi.dll\EmptyWorkingSet", "ptr", -1)

    return identifiedBiome
}


getAuraInfo(starColor := 0, cornerColor := 0, is100k := 0, is1m := 0){
    tData := staticData.stars[starColor]
    if (tData && (tData.cornerColor ? (compareColors(cornerColor,tData.cornerColor) <= 16) : 1)){
        if (tData.mutations){
            for i,v in tData.mutations {
                if (v.cornerColor && (compareColors(cornerColor,v.cornerColor) > 16)){
                    continue
                }
                if (v.requirements.is100k && is100k){
                    tData := v
                    break
                }
                if (v.requirements.is1m && is1m){
                    tData := v
                    break
                }
            }
        }

        displayName := tData.name
        displayRarity := tData.rarity

        if (tData.biome){
            if (tData.biome.name = currentBiome){
                displayName .= " [From " currentBiome "]"
                displayRarity := Floor(displayRarity/tData.biome.factor)
            }
        }

        return {name:displayName,image:tData.image,rarity:displayRarity,color:starColor}
    } else {
        lowestCompNum := 0xffffff * 3
        targetColor := 0
        for targetId,v in staticData.stars {
            if (targetId && (v.cornerColor ? (compareColors(cornerColor,v.cornerColor) <= 16) : 1)){
                comp := compareColors(starColor,targetId)
                if (comp < lowestCompNum){
                    lowestCompNum := comp
                    targetColor := targetId
                }
            }
        }
        if (lowestCompNum > 32){
            return 0
        }
        return getAuraInfo(targetColor,cornerColor,is100k,is1m)
    }
}

global pi := 4*ATan(1)

; not in use
determine1mStar(ByRef starMap){
    totalPixels := 32*32

    starCheckMap := Gdip_ResizeBitmap(starMap,32,32,0,2)

    effect := Gdip_CreateEffect(5,30,150)
    Gdip_BitmapApplyEffect(starCheckMap,effect)

    starPixels := 0
    Loop, % 32 {
        x := A_Index - 1
        Loop, % 32 {
            y := A_Index - 1

            pixelColor := Gdip_GetPixel(starCheckMap, x, y)

            if (compareColors(pixelColor,0x000000) > 32) {
                starPixels += 1
            }
        }
    }

    Gdip_DisposeEffect(effect)
    Gdip_DisposeBitmap(starCheckMap)
    Gdip_DisposeBitmap(retrievedMap)

    return starPixels/totalPixels >= 0.13
}

handleRollPost(bypass,auraInfo,starMap,originalCorners) {
    Gdip_SaveBitmapToFile(starMap,ssPath)

    if (auraInfo && sendMinimum && sendMinimum <= auraInfo.rarity) {
        ; Remove 'From {biome}' text, if present
        sAuraName := RegExReplace(auraInfo.name, "\s\[From\s\w+\]", "")

        ; Convert to name used in config
        sAuraName := RegExReplace(sAuraName, "[^a-zA-Z0-9]+", "_") ; Replace with underscores
        sAuraName := RegExReplace(sAuraName, "\_$", "") ; Remove any trailing underscores

        if (options["wh" . sAuraName]) {
            webhookPost({auraName: auraInfo.name, embedContent: "# You rolled " auraInfo.name "!\n> ### 1/" commaFormat(auraInfo.rarity) " Chance",embedTitle: "Roll",embedColor: auraInfo.color,embedImage: auraImages ? auraInfo.image : 0,embedFooter: "Detected color " . bypass . (!isColorBlack(originalCorners[4]) ? " | Corner color: " . originalCorners[4] : "") ,pings: (pingMinimum && pingMinimum <= auraInfo.rarity),files:[ssPath],embedThumbnail:"attachment://ss.jpg"})
        }
    }
    
    Gdip_DisposeBitmap(starMap)
}

isColorBlack(c){
    return compareColors(c,0x000000) < 8
}
isColorWhite(c){
    return compareColors(c,0xffffff) < 8
}


recordAura()
{
    Sleep, 8000
    SendInput {LWin down}{Alt down}{g down}{LWin up}{Alt up}{g up}
}

rollDetection(bypass := 0,is1m := 0,starMap := 0,originalCorners := 0){
    if (rareDisplaying && !bypass) {
        return
    }

    if (!GetRobloxHWND()){
        rareDisplaying := 0
        return
    }
    getRobloxPos(rX,rY,width,height)

    scanPoints := [[rX+1,rY+1],[rX+width-2,rY+1],[rX+1,rY+height-2],[rX+width-2,rY+height-2]]
    blackCorners := 0
    whiteCorners := 0
    cornerResults := []
    for i,point in scanPoints {
        PixelGetColor, pColor, % point[1], % point[2], RGB
        blackCorners += isColorBlack(pColor)
        whiteCorners += isColorWhite(pColor)

        cornerResults[i] := pColor
    }
    PixelGetColor, cColor, % rX + width*0.5, % rY + height*0.5, RGB
    centerColored := !isColorBlack(cColor)
    possible1m := getAuraInfo(cColor,cornerResults[4],0,1)

    if (!bypass && (blackCorners >= 4 || (possible1m && isColorBlack(cornerResults[1]) && isColorBlack(cornerResults[2]) && !isColorWhite(cornerResults[4])))){
        rareDisplaying := 1
        if (centerColored){
            if (possible1m && blackCorners < 4){
                is1m := 1
            }
            rareDisplaying := 2
            Sleep, 750
            blackCorners := 0
            for i,point in scanPoints {
                PixelGetColor, pColor, % point[1], % point[2], RGB
                blackCorners += compareColors(pColor,0x000000) < 8
            }
            PixelGetColor, cColor, % rX + width*0.5, % rY + height*0.5, RGB
            if ((blackCorners < 4 && !getAuraInfo(cColor,cornerResults[4],0,1)) || isColorBlack(cColor)){
                ; false detect
                rareDisplaying := 0
                return
            }

            topLeft := getFromUV(-0.25,-0.25,rX,rY,width,height)
            bottomRight := getFromUV(0.25,0.25,rX,rY,width,height)
            squareScale := [bottomRight[1]-topLeft[1]+1,bottomRight[2]-topLeft[2]+1]

            SystemCursor("Off")
            starMap := Gdip_BitmapFromScreen(topLeft[1] "|" topLeft[2] "|" squareScale[1] "|" squareScale[2])
            SystemCursor("On")

            Sleep, 8000
            rollDetection(cColor,is1m,starMap,cornerResults)
        } else {
            if (sendMinimum && sendMinimum < 10000) {
                webhookPost({embedContent:"You rolled a 1/1k+",embedTitle:"Roll",pings: (pingMinimum && pingMinimum < 10000)})
            }
            if (recordEnabled == 1 && recordMinimum < 10000)
            {
                recordAura()
            }
            Sleep, 5000
            rareDisplaying := 0
            return
        }
    }
    if (!bypass) {
        return
    }

    is100k := whiteCorners >= 3
    if (!is100k){
        Loop 4 {
            Sleep, 500
            whiteCorners := 0
            for i,point in scanPoints {
                PixelGetColor, pColor, % point[1], % point[2], RGB
                whiteCorners += compareColors(pColor,0xFFFFFF) < 8
            }
            is100k := whiteCorners >= 3
            if (is100k){
                break
            }
        }
    }

    if (is100k && rareDisplaying >= 2){
        rareDisplaying := 3
        auraInfo := getAuraInfo(bypass,0,1)
        handleRollPost(bypass,auraInfo,starMap,originalCorners)
        Sleep, 6000
        rareDisplaying := 0
    } else if (rareDisplaying >= 2){
        auraInfo := getAuraInfo(bypass,originalCorners[4],0,is1m)
        if ((auraInfo.rarity >= 99999) && (auraInfo.rarity < 1000000)){
            rareDisplaying := 0
            return
        }
        handleRollPost(bypass,auraInfo,starMap,originalCorners)
        rareDisplaying := 0
    }

    if (recordEnabled == 1 && RecordMinimum <= auraInfo.rarity)
    {
        recordAura()
    }
}


SystemCursor(OnOff=1)   ; INIT = "I","Init"; OFF = 0,"Off"; TOGGLE = -1,"T","Toggle"; ON = others
{
    static AndMask, XorMask, $, h_cursor
        ,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13 ; system cursors
        , b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13   ; blank cursors
        , h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13   ; handles of default cursors
    if (OnOff = "Init" or OnOff = "I" or $ = "")       ; init when requested or at first call
    {
        $ := "h"                                       ; active default cursors
        VarSetCapacity( h_cursor,4444, 1 )
        VarSetCapacity( AndMask, 32*4, 0xFF )
        VarSetCapacity( XorMask, 32*4, 0 )
        system_cursors := "32512,32513,32514,32515,32516,32642,32643,32644,32645,32646,32648,32649,32650"
        StringSplit c, system_cursors, `,
        Loop %c0%
        {
            h_cursor   := DllCall( "LoadCursor", "Ptr",0, "Ptr",c%A_Index% )
            h%A_Index% := DllCall( "CopyImage", "Ptr",h_cursor, "UInt",2, "Int",0, "Int",0, "UInt",0 )
            b%A_Index% := DllCall( "CreateCursor", "Ptr",0, "Int",0, "Int",0
                , "Int",32, "Int",32, "Ptr",&AndMask, "Ptr",&XorMask )
        }
    }
    if (OnOff = 0 or OnOff = "Off" or $ = "h" and (OnOff < 0 or OnOff = "Toggle" or OnOff = "T"))
        $ := "b"  ; use blank cursors
    else
        $ := "h"  ; use the saved cursors

    Loop %c0%
    {
        h_cursor := DllCall( "CopyImage", "Ptr",%$%%A_Index%, "UInt",2, "Int",0, "Int",0, "UInt",0 )
        DllCall( "SetSystemCursor", "Ptr",h_cursor, "UInt",c%A_Index% )
    }
}

SendToMain(ByRef StringToSend) {
    TargetScript := "ahk_class AutoHotkeyGUI"

    VarSetCapacity(CopyDataStruct, 3*A_PtrSize, 0)
    SizeInBytes := (StrLen(StringToSend) + 1) * (A_IsUnicode ? 2 : 1)
    NumPut(SizeInBytes, CopyDataStruct, A_PtrSize)
    NumPut(&StringToSend, CopyDataStruct, 2*A_PtrSize)

    Prev_DetectHiddenWindows := A_DetectHiddenWindows
    Prev_TitleMatchMode := A_TitleMatchMode
    DetectHiddenWindows On
    SetTitleMatchMode 2

    SendMessage, 0x4a, 0, &CopyDataStruct,, %TargetScript%

    DetectHiddenWindows %Prev_DetectHiddenWindows%
    SetTitleMatchMode %Prev_TitleMatchMode%
    return ErrorLevel
}

secondTick() {
    rollDetection()

    detectedBiome := determineBiome()
    if (!detectedBiome || detectedBiome == currentBiome) {
        return
    }

    if (detectedBiome == !currentBiome) {
        logMessage("[secondTick] Biome Ended: " currentBiome)
        currentBiome := detectedBiome
        SendToMain(currentBiome)
    } else {
        currentBiome := detectedBiome
        logMessage("[secondTick] Detected biome: " currentBiome)
        SendToMain(currentBiome)


        targetData := biomeData[currentBiome]

        if(detectedBiome == "Glitched") {
            GlitchTest := 0
            Loop 20 {
                if (determineBiome() == "Glitched") {
                    GlitchTest += 1
                }
                sleep, 50
            }
            if (GlitchTest > 4) {
                FormatTime, fTime, , HH:mm:ss
                webhookPost({embedContent: "[" fTime "]: (Double Checked - Real Glitch Biome) Biome Started - " currentBiome " Private Server Link: " PrivateServerPre PrivateServerId, files:[ssPath], embedImage:"attachment://ss.jpg", embedColor: targetData.color, pings: targetData.ping, biome: currentBiome})
                webhookPost({embedContent: "[" fTime "]: Biome Started - " currentBiome, files:[ssPath], embedImage:"attachment://ss.jpg", embedColor: targetData.color, pings: targetData.ping, biome: currentBiome})

                webhookPost1({embedContent: "[" fTime "]: (Double Checked - Real Glitch Biome) Biome Started - " currentBiome " Private Server Link: " PrivateServerPre PrivateServerId, files:[ssPath], embedImage:"attachment://ss.jpg", embedColor: targetData.color, pings: targetData.ping, biome: currentBiome})
                webhookPost1({embedContent: "[" fTime "]: Biome Started - " currentBiome, files:[ssPath], embedImage:"attachment://ss.jpg", embedColor: targetData.color, pings: targetData.ping, biome: currentBiome})
            } else {
                targetData := biomeData[determineBiome()]
                if (targetData.display || targetData.ping) {
                    FormatTime, fTime, , HH:mm:ss
                    webhookPost({embedContent: "[" fTime "]: (PLEASE IGNORE IF IT WAS FALSE DETECTION!!) Biome Started - " currentBiome " Private Server Link: " PrivateServerPre PrivateServerId, files:[ssPath], embedImage:"attachment://ss.jpg", embedColor: targetData.color, pings: targetData.ping, biome: currentBiome})
                    webhookPost({embedContent: "[" fTime "]: Biome Started - " currentBiome, files:[ssPath], embedImage:"attachment://ss.jpg", embedColor: targetData.color, pings: targetData.ping, biome: currentBiome})


                    webhookPost1({embedContent: "[" fTime "]: (PLEASE IGNORE IF IT WAS FALSE DETECTION!!) Biome Started - " currentBiome " Private Server Link: " PrivateServerPre PrivateServerId, files:[ssPath], embedImage:"attachment://ss.jpg", embedColor: targetData.color, pings: targetData.ping, biome: currentBiome})
                    webhookPost1({embedContent: "[" fTime "]: Biome Started - " currentBiome, files:[ssPath], embedImage:"attachment://ss.jpg", embedColor: targetData.color, pings: targetData.ping, biome: currentBiome})
                }
            }
        } else if (targetData.display || targetData.ping) {
            FormatTime, fTime, , HH:mm:ss

            webhookPost({embedContent: "[" fTime "]: Biome Started - " currentBiome, files:[ssPath], embedImage:"attachment://ss.jpg", embedColor: targetData.color, pings: targetData.ping, biome: currentBiome})
        }
    }
}

SetTimer, secondTimer, 1000

logMessage(message, indent := 0) {
    global loggingEnabled, mainDir, lastLoggedMessage
    maxLogSize := 1048576 ; 1 MB

    if (!loggingEnabled) {
        return
    }

    ; Avoid logging the same message again
    if (message = lastLoggedMessage) {
        return
    }

    logFile := mainDir . "\lib\macro_status_log.txt"

    ; Check the log file size and truncate if necessary
    if (FileExist(logFile) && FileGetSize(logFile) > maxLogSize) {
        FileDelete, %logFile%
    }

    if (indent) {
        message := "    " . message
    }
    FormatTime, fTime, , HH:mm:ss
    FileAppend, % fTime " " message "`n", %logFile%
    OutputDebug, % fTime " " message

    ; Update the last logged message
    lastLoggedMessage := message
}

; Function to get the size of a file
FileGetSize(filePath) {
    FileGetSize, fileSize, %filePath%
    return fileSize
}

return

secondTimer:
secondTick()
return

ShowCursor:
SystemCursor("On")
ExitApp
