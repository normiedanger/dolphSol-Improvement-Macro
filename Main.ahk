; dolpSol Macro
;   A macro for Sol's RNG on Roblox
;   GNU General Public License
;   Free for anyone to use
;   Modifications are welcome, however stealing credit is not
;   Hope you enjoy - BuilderDolphin
;   A "small" project started on 03/07/2024
;   
;   https://github.com/BuilderDolphin/dolphSol-Macro
;   
;   Feel free to provide any suggestions (through discord preferably, @builderdolphin). 

#Requires AutoHotkey v1.1+ 64-bit
#SingleInstance, force
#NoEnv
#Persistent
SetBatchLines, -1


global loggingEnabled := 1 ; Debug logging to file, disabled for public to prevent storage overload, change to 1 to enable


OnError("LogError")
OnMessage(0x4a, "ReceiveFromStatus")

SetWorkingDir, % A_ScriptDir "\lib"
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

#Include *i %A_ScriptDir%\lib
#Include *i ocr.ahk
#Include *i tesseract_ocr.ahk
#Include *i Gdip_All.ahk
#Include *i Gdip_ImageSearch.ahk
#Include *i jxon.ahk
#Include *i ItemScheduler.ahk
#Include *i MerchantWebhook.ahk


global version := "v1.5.2 Experimental (12/11)"
global currentVersion := version

if (RegExMatch(A_ScriptDir,"\.zip") || IsFunc("ocr") = 0) {
    ; File is not extracted or not saved with other necessary files
    MsgBox, 16, % "dolphSol Macro " version, % "Unable to access all necessary files to run correctly.`n"
            . "Please make sure the macro folder is extracted by right clicking the downloaded file and choosing 'Extract All'."
    ExitApp
}

Gdip_Startup()

; Run macro as admin to avoid issues with Roblox input
full_command_line := DllCall("GetCommandLine", "str")
if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)")) {
    try {
        RunWait, *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
    }
}

; TODO: change some of these to static variables
global disableAlignment := false ; Toggle with F5
global lastLoggedMessage := ""
global delayMultiplier := 3 ; Delay multiplier for slower computers - Mainly for camera mode changes
global auraNames := [] ; List of aura names for webhook pings
global biomes := []
global lastMerchantTime := {}
global ItemSchedulerEntries := []  ; Initialize the array for item usage entries
global MerchantEntries := [] ; Merchant Item Holder
global Jester_Exchange_ItemEntries := [] ; Jester item exchange entries
global Merchant_Webhooks := []
global StellaPortalDelay := 0 ; Extra wait time (ms) after entering portal before moving to cauldron - 1000ms = 1s
global currentBiome := ""

global robloxId := 0

global canStart := 0
global macroStarted := 0
global reconnecting := 0

global isSpawnCentered := 0
global atSpawn := 0

global pathsRunning := []

obbyCooldown := 180 ; 180 seconds
lastObby := A_TickCount - obbyCooldown*1000
hasObbyBuff := 0

obbyStatusEffectColor := 0x9CFFAC
craftingCompleteColor := 0x1C821A

statusEffectSpace := 5

global mainDir := A_ScriptDir "\"

logMessage("") ; empty line for separation
logMessage("Macro opened")

configPath := mainDir . "settings\config.ini"
secondaryConfigPath := mainDir . "settings\secondary_config.ini"
merchantConfigPath := mainDir . "settings\merchant_webhook_config.ini"
merchantConfigPath_2 := mainDir . "settings\merchant_item_config.ini"

global ssPath := "ss.jpg"
global pathDir := mainDir . "paths\"
global merchant_ssPath := "hewo_merchant.jpg"
global imgDir := mainDir . "images\"

global camFollowMode := 0

configHeader := "; dolphSol Settings`n;   Do not put spaces between equals`n;   Additions may break this file and the macro overall, please be cautious`n;   If you mess up this file, clear it entirely and restart the macro`n`n[Options]`r`n"

global importantStatuses := {"Starting Macro":1
    ,"Roblox Disconnected":1
    ,"Reconnecting":1
    ,"Reconnecting, Roblox Opened":0
    ,"Reconnecting, Game Loaded":0
    ,"Reconnect Complete":1
    ,"Initializing":0
    ,"Macro Stopped":1}

global potionIndex := {0:"None"
    ,1:"Fortune Potion I"
    ,2:"Fortune Potion II"
    ,3:"Fortune Potion III"
    ,4:"Haste Potion I"
    ;,5:"Haste Potion II"
    ,5:"Haste Potion III"
    ,6:"Heavenly Potion I"
    ,7:"Heavenly Potion II"
    ,8:"Warp Potion"}

global craftingInfo := {"Fortune Potion I":{slot:1, potion_page:1,subSlot:1,addSlots:4,maxes:[5,1,5,1],attempts:2}
    ,"Fortune Potion II":{slot:2, potion_page:1,subSlot:2,addSlots:5,maxes:[1,10,5,10,2],attempts:2}
    ,"Fortune Potion III":{slot:3, potion_page:1,subSlot:3,addSlots:5,maxes:[1,15,10,15,5],attempts:2}
    ,"Haste Potion I":{slot:4, potion_page:1,subSlot:1,addSlots:4,maxes:[10,5,10,1],attempts:2}
    ;,"Haste Potion II":{slot:1, potion_page:2,subSlot:2,addSlots:5,maxes:[1,10,10,15,2],attempts:2}
    ,"Haste Potion III":{slot:1, potion_page:2,subSlot:3,addSlots:5,maxes:[1,20,15,25,4],attempts:2}
    ,"Heavenly Potion I":{slot:2, potion_page:2,subSlot:1,addSlots:4,maxes:[100,50,20,1],attempts:2}
    ,"Heavenly Potion II":{slot:3, potion_page:2,subSlot:2,addSlots:5,maxes:[2,125,75,50,1],attempts:2}
    ,"Warp Potion":{slot:4, potion_page:2,subSlot:3,addSlots:6,maxes:[1,250,200,300,400,75,2],attempts:2}}

global rarityIndex := {0:"None"
    ,1:"1/1k+"
    ,2:"1/10k+"
    ,3:"1/100k+"}

reverseIndices(t){
    newT := {}
    for i,v in t {
        newT[v] := i
    }
    return newT
}

global reversePotionIndex := reverseIndices(potionIndex)
global reverseRarityIndex := reverseIndices(rarityIndex)

; defaults
global sData := {}

global merchantOptions := {"MerchantWebhookAlias": ""
    ,"MerchantWebhookLink": ""
    ,"MerchantWebhook_Mari_UserID": ""
    ,"MerchantWebhook_Jester_UserID": ""
    ,"MerchantWebhook_PS_Link": ""}

global merchant_ItemOptions := {"Mari_ItemSlot1":0
    ,"Mari_ItemSlot2":0
    ,"Mari_ItemSlot3":0
    ,"Mari_ItemSlot4":0
    ,"Mari_ItemSlot5":0
    ,"Mari_ItemSlot6":0
    ,"Mari_ItemSlot7":0
    ,"Mari_ItemSlot8":0
    ,"Mari_ItemSlot9":0
    ,"Mari_ItemSlot10":0
    ,"Mari_ItemSlot11":0
    ,"Mari_ItemSlot12":0
    ,"Mari_ItemSlot13":0
    ,"Mari_ItemSlot14":0
    ,"Jester_ItemSlot1":0
    ,"Jester_ItemSlot2":0
    ,"Jester_ItemSlot3":0
    ,"Jester_ItemSlot4":0
    ,"Jester_ItemSlot5":0
    ,"Jester_ItemSlot6":0
    ,"Jester_ItemSlot7":0
    ,"Jester_ItemSlot8":0
    ,"Jester_ItemSlot9":0
    ,"Jester_ItemSlot10":0
    ,"Jester_ItemSlot11":0
    ,"Jester_ItemSlot12":0
    ,"Jester_ItemSlot13":0
    ,"Jester_ItemSlot14":0
    ,"Jester_ItemSlot15":0
    ,"Jester_ItemSlot16":0}


global JesterItemsArray := ["Oblivion Potion"
    ,"Heavenly Potion (buy both I and II)"
    ,"Rune of Everything"
    ,"Rune of Nothing"
    ,"Rune Of Corruption"
    ,"Rune Of Hell"
    ,"Rune of Galaxy"
    ,"Rune of Rainstorm"
    ,"Rune of Frost"
    ,"Rune of Wind"
    ,"Strange Potion (buy both I and II)"
    ,"Stella's Candle"
    ,"Merchant Tracker"
    ,"Random Potion Sack"]

global MariItemsArray := ["Void Coin"
    ,"Lucky Penny"
    ,"Fortune Spoid (buy both I and II and III)"
    ,"Mixed Potion"
    ,"Lucky Potion"
    ,"Lucky Potion L"
    ,"Lucky Potion XL"
    ,"Speed Potion"
    ,"Speed Potion L"
    ,"Speed Potion XL"
    ,"Gear A"
    ,"Gear B"]

global secondaryOptions := {"AuraStorageX": 1017
    ,"AuraStorageY": 502
    ,"RegularAuraTabX": 1002
    ,"RegularAuraTabY": 539
    ,"SpecialAuraTabX": 1030
    ,"SpecialAuraTabY": 632
    ,"AuraSearchBarX": 572
    ,"AuraSearchBarY": 454
    ,"FirstAuraSlotX": 591
    ,"FirstAuraSlotY": 683
    ,"EquipButtonX": 975
    ,"EquipButtonY": 439
    ,"CollectionMenuX": 673
    ,"CollectionMenuY": 419
    ,"CollectionExitButtonX": 677
    ,"CollectionExitButtonY": 445
    ,"InventoryMenuX": 1017
    ,"InventoryMenuY": 444
    ,"ItemsTabX": 1141
    ,"ItemsTabY": 538
    ,"QuestMenuX": 620
    ,"QuestMenuY": 348
    ,"DailyTabX": 620
    ,"DailyTabY": 548
    ,"FirstQuestSlotX": 794
    ,"FirstQuestSlotY": 260
    ,"ClaimButtonX": 615
    ,"ClaimButtonY": 377
    ,"SearchBarX": 1225
    ,"SearchBarY": 478
    ,"FirstItemSlotX": 1200
    ,"FirstItemSlotY": 529
    ,"AmountBoxX": 1202
    ,"AmountBoxY": 558
    ,"UseButtonX": 1213
    ,"UseButtonY": 339
    ,"AutoButtonX": 1225
    ,"AutoButtonY": 478
    ,"PotionSearchBarX": 121
    ,"PotionSearchBarY": 478
    ,"FirstPotionSlotX": 1225
    ,"FirstPotionSlotY": 478
    ,"CraftButtonX": 1225
    ,"CraftButtonY": 478
    ,"1_potion_manual_x": 800
    ,"1_potion_manual_y": 508
    ,"2_potion_manual_x": 800
    ,"2_potion_manual_y": 538
    ,"3_potion_manual_x": 800
    ,"3_potion_manual_y": 568
    ,"4_potion_manual_x": 800
    ,"4_potion_manual_y": 598
    ,"5_potion_manual_x": 800
    ,"5_potion_manual_y": 628
    ,"6_potion_manual_x": 800
    ,"6_potion_manual_y": 658
    ,"BiomeCorruption": "Message"
    ,"BiomeGlitched": "Message"
    ,"BiomeHell": "Message"
    ,"BiomeNull": "Message"
    ,"BiomeRainy": "Message"
    ,"BiomeSnowy": "Message"
    ,"BiomeStarfall": "Message"
    ,"BiomeStorm": "Message"
    ,"BiomeWindy": "Message"}

global options := {"DoingObby":0
    ,"AzertyLayout":0
    ,"ArcanePath":0
    ,"CheckObbyBuff":0
    ,"CollectItems":1
    ,"ItemSpot1":1
    ,"ItemSpot2":1
    ,"ItemSpot3":1
    ,"ItemSpot4":1
    ; ,"ItemSpot5":1
    ; ,"ItemSpot6":1
    ; ,"ItemSpot7":1
    ; ,"ItemSpot8":1
    ,"Screenshotinterval":60
    ,"WindowX":100
    ,"WindowY":100
    ,"VIP":0
    ,"BackOffset":0
    ,"ReconnectEnabled":1
    ,"AutoEquipEnabled":0
    ,"AutoEquipAura":""
    ,"AutoEquipX":-0.415
    ,"AutoEquipY":-0.438
    ,"PrivateServerId":""
    ,"InOwnPrivateServer":1 ; Determines side button positions
    ,"ScanLoopInterval":1 ; How many attempts/tries to scan and count left side buttons (If 7 buttons then you're on friend/public server, 8 is you are on your PS instead) - Noteab
    ,"StorageButtonYPosScanVALUE":318 ; Storage Y Pos value in main option - Noteab
    ,"StorageYOffsetIntervalVALUE":70 ; Storage Y Pos highlight box for easier look while adjusting - Noteab
    ,"WebhookEnabled":0
    ,"WebhookLink":""
    ,"WebhookImportantOnly":0
    ,"DiscordUserID":""
    ,"DiscordGlitchID":"" ; Used in status.ahk for biome ping in Discord - Defaults to DiscordUserID if not set
    ,"glitchIDMsgShown":0
    ,"WebhookRollSendMinimum":10000
    ,"WebhookRollPingMinimum":100000
    ,"WebhookAuraRollImages":0
    ,"StatusBarEnabled":0
    ,"WasRunning":0
    ,"FirstTime":0
    ,"InvScreenshotsEnabled":1
    ,"LastInvScreenshot":0
    ,"OCREnabled":0
    ,"RestartRobloxEnabled":0
    ,"RestartRobloxInterval":1
    ,"LastRobloxRestart":0
    ,"LastAnnouncement":0
    ,"RobloxUpdatedUI":2 ; Default to "New"
    ,"ClaimDailyQuests":0       ; Stewart
    ,"SearchSpecialAuras":0     ; Stewart
    ,"Shifter":0
    ,"IsNikoPath":1

    ; Merchant config options (Noteab)
    ,"AutoMerchantEnabled":0
    ,"JesterExchangeEnabled":0
    ,"Biome_OCR_X":3
    ,"Biome_OCR_Y":904
    ,"Biome_OCR_W":266
    ,"Biome_OCR_H":29
    ,"Merchant_slider_X":711
    ,"Merchant_slider_Y":734

    ,"Merchant_Purchase_Amount_X":646
    ,"Merchant_Purchase_Amount_Y":613

    ,"Merchant_Purchase_Button_X":713
    ,"Merchant_Purchase_Button_Y":658

    ,"Merchant_Open_Button_X":512
    ,"Merchant_Open_Button_Y":881

    ,"Merchant_Username_OCR_X":758
    ,"Merchant_Username_OCR_Y":585
    ,"Merchant_Username_OCR_W":100
    ,"Merchant_Username_OCR_H":20

    ,"Merchant_ItemName_OCR_X":758
    ,"Merchant_ItemName_OCR_Y":386
    ,"Merchant_ItemName_OCR_W":100
    ,"Merchant_ItemName_OCR_H":20

    ,"Merchant_FirstItem_Pos_X":611
    ,"Merchant_FirstItem_Pos_Y":722

    ,"Jester_Exchange_Button_X":828
    ,"Jester_Exchange_Button_Y":881

    ,"Jester_Item_Search_Bar_X":686
    ,"Jester_Item_Search_Bar_Y":787
    ,"Jester_First_Item_Exchange_Slot_X":556
    ,"Jester_First_Item_Exchange_Slot_Y":726

    ,"Mari_Amount_1":0
    ,"Mari_Amount_2":0
    ,"Mari_Amount_3":0
    ,"Jester_Amount_1":0
    ,"Jester_Amount_2":0
    ,"Jester_Amount_3":0

    ; EXCHANGE ITEM SECION
    ,"Jester_Exchange_ItemSlot1":0
    ,"Jester_Exchange_ItemSlot2":0
    ,"Jester_Exchange_ItemSlot3":0
    ,"Jester_Exchange_ItemSlot4":0
    ,"Jester_Exchange_ItemSlot5":0
    ,"Jester_Exchange_ItemSlot6":0
    ,"Jester_Exchange_ItemSlot7":0
    ,"Jester_Exchange_ItemSlot8":0
    ,"Jester_Custom_Exchange_Amounts":"50, 25, 5"

    ; Merchant config options
    
    ; Crafting
    ,"ItemCraftingEnabled":0
    ,"CraftingInterval":10
    ,"LastCraftSession":0
    ,"PotionCraftingEnabled":0
    ,"PotionCraftingSlot1":0
    ,"PotionCraftingSlot2":0
    ,"PotionCraftingSlot3":0
    ,"PotionAutoAddEnabled":0
    ,"PotionAutoAddInterval":10
    ,"LastPotionAutoAdd":0
    ,"PotionLastCraftedIndex":1

    ,"ExtraRoblox":0 ; mainly for me (builderdolphin) to run my 3rd acc on 2nd monitor, not used for anything else, not intended for public use unless yk what you're doing i guess

    ; not really options but stats i guess
    ,"RunTime":0
    ,"Disconnects":0
    ,"ObbyCompletes":0
    ,"ObbyAttempts":0
    ,"CollectionLoops":0

    ; plus options
    ,"RecordAura":0
    ,"RecordAuraMinimum":100000}

global privateServerPre := "https://www.roblox.com/games/15532962292/Sols-RNG?privateServerLinkCode="

; Must be called in correct order
Load_Merchant_WebhookSettings()
loadData() ; Load config data
;updateStaticData() ; Get latest data for update check, aura names, etc.

; Disable OCR mode if resolution isn't supported
; Now enabling the mode will notify of requirements

if (options.ItemCraftingEnabled) {
    if (options.ItemCraftingEnabled = 1) {
        options.ItemCraftingEnabled := 0
    }
}

global currentLanguage := getCurrentLanguage() ; Get the current language for OCR check
getCurrentLanguage() {
    try {
        hWnd := GetRobloxHWND() ? WinExist("ahk_id" . GetRobloxHWND()) : WinExist("A")
        currentLanguage := GetInputLangName(GetInputLangID(hWnd))
        logMessage("Current Language: " currentLanguage)
        return currentLanguage
    }
    return "Unknown"
}
getOCRLanguages() {
    ; Macro requires "en-US" to be installed for OCR library (as of 06/21/24)

    languages := ocr("ShowAvailableLanguages")
    if (!languages) {
        logMessage("An error occurred while checking for OCR languages")
        return 0
    }

    logMessage("OCR languages installed:")
    logMessage(languages)
    return languages

    ; Check if the script is running as admin
    if (!A_IsAdmin) {
        logMessage("Main.ahk not running as admin")

        MsgBox, 4, , % "You will need the 'English (United States)' language pack installed for enhanced functionality.`n`n"
            . "Would you like to run this file as an administrator to attempt to install it automatically?"

        IfMsgBox Yes
            logMessage("Restarting Main.ahk as admin")
            RunWait, *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
            return
    } else {
        logMessage("Main.ahk running as admin")

        ; Give the option to auto install the language pack
        MsgBox, 4, , % "You will need the 'English (United States)' language pack installed for enhanced functionality.`n`n"
            . "Select 'No' to do it yourself through Settings > Time & Language > Language & Region > Add a language.`n"
            . "Select 'Yes' to attempt to install it automatically.`n`n"
            . "Both options will require you to log out and back in (or restart) to take effect."

        IfMsgBox Yes
            logMessage("Attempting to install the language pack")
            try {
                RunWait, *RunAs powershell.exe -ExecutionPolicy Bypass Install-Language en-US
                ExitApp
            } catch e {
                logMessage("An error occurred while attempting to install the language pack")
                logMessage(e, 1)
                MsgBox, 16, Error, % "An error occurred while attempting to install the language pack.`n`n"
                    . "Please install it manually through Settings > Time & Language > Language & Region > Add a language."
            }
    }
}

/*
    Begin Language Functions

    GetInputLangID(), GetInputLangName()
    Last submitted by teadrinker 20 Sep 2020 at https://www.autohotkey.com/boards/viewtopic.php?style=17&p=353708&sid=4498caf4025f947e56ee1f190c7f2227#p353708
*/
GetInputLangID(hWnd) {
   WinExist("ahk_id" . hWnd)
   WinGet, processName, ProcessName
   if (processName != "ApplicationFrameHost.exe") {
      ControlGetFocus, focused
      if !ErrorLevel
         ControlGet, hWnd, hwnd,, % focused
      threadId := DllCall("GetWindowThreadProcessId", "Ptr", hWnd, "Ptr", 0)
   }
   else {
      WinGet, PID, PID
      WinGet, controlList, ControlListHwnd
      Loop, parse, controlList, `n
         threadId := DllCall("GetWindowThreadProcessId", "Ptr", A_LoopField, "UIntP", childPID)
      until childPID != PID
   }
   lyt := DllCall("GetKeyboardLayout", "Ptr", threadId, "UInt")
   return langID := Format("{:#x}", lyt & 0x3FFF)
}
GetInputLangName(langId) {
   static LOCALE_SENGLANGUAGE := 0x1001
   charCount := DllCall("GetLocaleInfo", "UInt", langId, "UInt", LOCALE_SENGLANGUAGE, "UInt", 0, "UInt", 0)
   VarSetCapacity(localeSig, size := charCount << !!A_IsUnicode, 0)
   DllCall("GetLocaleInfo", "UInt", langId, "UInt", LOCALE_SENGLANGUAGE, "Str", localeSig, "UInt", size)
   return localeSig
}
/*
    End Language Functions
*/

getINIData(path){
    FileRead, retrieved, %path%

    if (!retrieved){
        logMessage("[getINIData] No data found in " path)
        ; MsgBox, An error occurred while reading %path% data, please review the file.
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

writeToINI(path,object,header){
    ; if (!FileExist(path)){
    ;     MsgBox, You are missing the file: %path%, please ensure that it is in the correct location.
    ;     return
    ; }

    formatted := header

    for i,v in object {
        formatted .= i . "=" . v . "`r`n"
    }

    if (FileExist(path)) {
        FileDelete, %path%
    }
    FileAppend, %formatted%, %path%
}

WriteToINI_v2(path, section, key, value) {
    IniWrite, %value%, %path%, %section%, %key%
}

getURLContent(url) {
    try {
        WinHttp := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        WinHttp.Open("GET", url, false)
        WinHttp.SetRequestHeader("Cache-Control", "no-cache")
        WinHttp.SetRequestHeader("Pragma", "no-cache")
        WinHttp.Send()

        If (WinHttp.Status = 200) {
            return WinHttp.ResponseText
        }

        return ""
    } catch {
        return ""
    }
}

updateStaticData() {
    updateURL := "https://raw.githubusercontent.com/noteab/dolphSol-Improvement-Macro/Noteab-Improvement/lib/staticData.json"

    content := getURLContent(updateURL)
    if (content != "") {
        FileDelete, staticData.json
        FileAppend, %content%, staticData.json

        officialData := Jxon_Load(content)[1]
        officialVersion := officialData.updateInfo.latestVersion
    }

    if (content == "") {
        MsgBox, 16, Update Check, % "Unable to check for update. Error: " . e.Message . "`nContinuing with current StaticData.json data.`nCheck your network connection and restart to try again."
        return
    }

    ; Show Announcement once daily at most
    sData := officialData
    if (sData.announcement != "" && (getUnixTime() - options.LastAnnouncement >= 24*60*60*1000)) { ; 24hrs
        MsgBox, 0, Macro Announcement, % sData.announcement
        options.LastAnnouncement := getUnixTime()
    }
    
    if (officialVersion && officialVersion != currentVersion) {
        updateMessage := officialData.updateInfo.updateNotes
    } else {
        return
    }

    uNotes := sData.updateInfo.updateNotes
    MsgBox, 36, New Update Available, % "`nWould you like to head to the GitHub page to update your macro?" . (uNotes ? ("`n`nUpdate Notes:`n" . uNotes) : "")
    IfMsgBox No
        return

    options.FirstTime := 0
    vLink := sData.updateInfo.versionLink
    Run % (vLink ? vLink : "https://github.com/noteab/dolphSol-Improvement-Macro/releases/latest")
    ExitApp
}

; data loading

loadData(){
    global
    logMessage("[loadData] Loading config data")

    savedRetrieve := getINIData(configPath)
    if (!savedRetrieve){
        logMessage("[loadData] Unable to retrieve config data, Resetting to defaults.")
        MsgBox, % "Unable to retrieve config data, your settings have been set to their defaults."
        savedRetrieve := {}
    }

    ; Load secondary config
    secondaryRetrieve := getINIData(secondaryConfigPath)
    if (!secondaryRetrieve){
        logMessage("[loadData] Unable to retrieve secondary config data, Resetting to defaults.")
        secondaryRetrieve := {}
    }

    
    local newOptions := {}
    local finalized_retrieve := {}
    local finalized_options := {}

    ; Combine secondary and main retrieve
    for i, v in secondaryRetrieve {
        finalized_retrieve[i] := v
    }
    for i, v in savedRetrieve {
        finalized_retrieve[i] := v
    }

    ; Combine secondary and main options
    for i, v in secondaryOptions {
        finalized_options[i] := v
    }
    for i, v in options {
        finalized_options[i] := v
    }

    for i, v in finalized_options { ; Iterating through defined options does not load dynamic settings - currently aura, biomes
        
        if (finalized_retrieve.HasKey(i)) {
            newOptions[i] := finalized_retrieve[i]

            ; Temporary code to fix time error
            for _, key in ["LastCraftSession","LastInvScreenshot","LastPotionAutoAdd"] {
                if (i = key && finalized_retrieve[i] > getUnixTime()) {
                    ; logMessage("Resetting " i)
                    ; Reset value so it's not too high to trigger
                    newOptions[i] := 0
                }
            }
            
        } else {
            logMessage("[loadData] Missing key: " i)
            newOptions[i] := v
        }
    }

    options := newOptions

    ; Load aura names from JSON
    FileRead, staticDataContent, % "staticData.json"
    sData := Jxon_Load(staticDataContent)[1]
    auraNames := []
    for key, value in sData.stars {
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
            options[key] := 1 ; default enabled
        }
        ; logMessage("[loadData] Aura: " auraName " - " sAuraName " - " options[key])
    }

    ; Load biome settings
    biomes := ["Windy", "Rainy", "Snowy", "Storm", "Hell", "Starfall", "Corruption", "Null", "Glitched"]
    for i, biome in biomes {
        key := "Biome" . biome
        if (finalized_retrieve.HasKey(key)) {
            options[key] := finalized_retrieve[key]
        } else {
            options[key] := "Message" ; Set default
        }
        ; logMessage("[loadData] Biome: " biome " - " options[key])
    }

    LoadItemSchedulerOptions()
}

Load_Merchant_WebhookSettings() {
    global merchantOptions, merchant_ItemOptions, merchantConfigPath, merchantConfigPath_2

    ; Retrieve saved webhook settings
    savedRetrieve := getINIData(merchantConfigPath)
    savedRetrieveItems := getINIData(merchantConfigPath_2)
    if (!savedRetrieve) {
        logMessage("[Load_Merchant_WebhookSettings] Unable to retrieve merchant config data, resetting to defaults.")
        savedRetrieve := {}
    }
    
    ; Load Merchant Webhook settings
    merchantOptions.MerchantWebhookAlias := savedRetrieve.HasKey("MerchantWebhookAlias") ? savedRetrieve["MerchantWebhookAlias"] : ""
    merchantOptions.MerchantWebhookLink := savedRetrieve.HasKey("MerchantWebhookLink") ? savedRetrieve["MerchantWebhookLink"] : ""
    merchantOptions.MerchantWebhook_Mari_UserID := savedRetrieve.HasKey("MerchantWebhook_Mari_UserID") ? savedRetrieve["MerchantWebhook_Mari_UserID"] : ""
    merchantOptions.MerchantWebhook_Jester_UserID := savedRetrieve.HasKey("MerchantWebhook_Jester_UserID") ? savedRetrieve["MerchantWebhook_Jester_UserID"] : ""
    IniRead, psLink, %merchantConfigPath%, Options, MerchantWebhook_PS_Link

    if (psLink != "") {
        merchantOptions.MerchantWebhook_PS_Link := psLink
    }


    if (!savedRetrieveItems) {
        logMessage("[Load_Merchant_WebhookSettings] Unable to retrieve merchant item data, resetting to defaults.")
        savedRetrieveItems := {}
    }

    Loop, 14 {
        slotKey := "Mari_ItemSlot" A_Index
        merchant_ItemOptions[slotKey] := savedRetrieveItems.HasKey(slotKey) ? savedRetrieveItems[slotKey] : 0
    }

    Loop, 16 {
        slotKey := "Jester_ItemSlot" A_Index
        merchant_ItemOptions[slotKey] := savedRetrieveItems.HasKey(slotKey) ? savedRetrieveItems[slotKey] : 0
    }
}

Save_Merchant_ItemSettings() {
    global merchant_ItemOptions, merchantConfigPath_2, configHeader
    iniData := {}

    Loop, 14 {
        slotKey := "Mari_ItemSlot" A_Index
        iniData[slotKey] := merchant_ItemOptions[slotKey]
    }

    Loop, 16 {
        slotKey := "Jester_ItemSlot" A_Index
        iniData[slotKey] := merchant_ItemOptions[slotKey]
    }

    writeToINI(merchantConfigPath_2, iniData, configHeader)
}

saveOptions() {
    global configPath, configHeader, options, secondaryOptions, secondaryConfigPath
    writeToINI(configPath, options, configHeader)
    writeToINI(secondaryConfigPath, secondaryOptions, configHeader)
}
saveOptions()

updateYesClicked(){
    vLink := sData.updateInfo.versionLink
    Run % (vLink ? vLink : "https://github.com/noteab/dolphSol-Improvement-Macro/releases/latest")
    ExitApp
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

    url := options.webhookLink

    if (data.pings){
        data.content := data.content ? data.content " <@" options.DiscordUserID ">" : "<@" options.DiscordUserID ">"
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

    try {
        CreateFormData(postdata, hdr_ContentType, objParam)

        WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        WebRequest.Open("POST", url, true)
        WebRequest.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko")
        WebRequest.SetRequestHeader("Content-Type", hdr_ContentType)
        WebRequest.SetRequestHeader("Pragma", "no-cache")
        WebRequest.SetRequestHeader("Cache-Control", "no-cache, no-store")
        WebRequest.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
        WebRequest.Send(postdata)
        WebRequest.WaitForResponse()
    } catch e {
        logMessage("[webhookPost] Error creating webhook data:")
        logMessage(e, 1)
        ; MsgBox, 0, Webhook Error, % "An error occurred while creating the webhook data: " e
        return
    }
}

HasVal(haystack, needle) {
    for index, value in haystack
        if (value = needle)
            return index
    if !(IsObject(haystack))
        throw Exception("Bad haystack!", -1, haystack)
    return 0
}

global possibleDowns := ["w","a","s","d","Space","Enter","Esc","r"]
liftKeys(){
    for i,v in possibleDowns {
        Send {%v% Up}
    }
}

stop(terminate := 0, restart := 0) {
    global
    if (running && !restart){
        running := 0
        updateStatus("Macro Stopped")
    }

    if (terminate){
        options.WasRunning := 0
    }

    DetectHiddenWindows, On
    for i,v in pathsRunning {
        logMessage("[stop] Exiting running path: " . v, 1)
        WinClose, % v
    }

    liftKeys()
    removeDim()

    if (!restart){
        WinClose, % mainDir . "lib\status.ahk"
    }

    if (camFollowMode){
        rotateCameraMode()
    }

    applyNewUIOptions()
    saveOptions()

    if (terminate){
        logMessage("[stop] Terminating application.")
        OutputDebug, Terminated
        ExitApp
    }
}

global pauseDowns := []
global paused := 0
handlePause(){
    paused := !paused
    if (A_IsPaused){
        ResumePaths()

        updateStatus("Macro Running")
        Gui, mainUI:+LastFoundExist
        WinSetTitle, % "dolphSol's Macro " version " (Running)"

        applyNewUIOptions()
        saveOptions()
        updateUIOptions()

        Pause, Off ; Unpause the script
    } else {
        PausePaths()

        updateStatus("Macro Paused")
        Gui, mainUI:+LastFoundExist
        WinSetTitle, % "dolphSol's Macro " version " (Paused)"
      
        updateUIOptions()
        Gui mainUI:Show

        Pause, On, 1 ; Pause the main thread
    }
}

StopPaths() {
    global pathsRunning, camFollowMode

    logMessage("Paths running: " pathsRunning.Length())

    ; Close external AHK files
    DetectHiddenWindows, On
    for _, v in pathsRunning {
        logMessage("[StopPaths] Stopping path: " . v, 1)
        WinClose, % v
        pathsRunning.Remove(HasVal(pathsRunning,v))
    }

    liftKeys()
    removeDim()

    if (camFollowMode){
        rotateCameraMode()
    }

    saveOptions()
}

PausePaths() {
    global pathsRunning

    logMessage("Paths running: " pathsRunning.Length())
    if (pathsRunning.Length() = 0) {
        return
    }

    ; Send Pause to external AHK files
    DetectHiddenWindows, On
    WM_COMMAND := 0x0111
    ID_FILE_PAUSE := 65403
    for _, v in pathsRunning {
        logMessage("[PausePaths] Pausing path: " . v, 1)
        PostMessage, WM_COMMAND, ID_FILE_PAUSE,,, % v ahk_class AutoHotkey

        hWnd := WinExist(v "ahk_class AutoHotkey")
        logMessage("Paused: " JEE_AhkWinIsPaused(hWnd), 2)
    }

        pauseDowns := []
        for i,v in possibleDowns {
            state := GetKeyState(v)
            if (state){
                pauseDowns.Push(v)
                Send {%v% Up}
            }
        }
}

ResumePaths() {
    logMessage("Paths running: " pathsRunning.Length())
    if (pathsRunning.Length() = 0) {
        return
    }

    ; Send Un-Pause to external AHK files
    DetectHiddenWindows, On
    WM_COMMAND := 0x0111
    ID_FILE_PAUSE := 65403
    for i, v in pathsRunning {
        logMessage("[ResumePaths] Resuming path: " . v, 1)
        PostMessage, WM_COMMAND, ID_FILE_PAUSE,,, % v ahk_class AutoHotkey

        hWnd := WinExist(v "ahk_class AutoHotkey")
        logMessage("Paused: " JEE_AhkWinIsPaused(hWnd), 2)
    }

    ; Restore any previously paused key states
    WinActivate, ahk_id %robloxId%
    for i, v in pauseDowns {
        Send {%v% Down}
    }
}

; JEE_ScriptIsPaused - Detects if an external script is paused
JEE_AhkWinIsPaused(hWnd) {
	vDHW := A_DetectHiddenWindows
	DetectHiddenWindows, On
	SendMessage, 0x211,,,, % "ahk_id " hWnd ;WM_ENTERMENULOOP := 0x211
	SendMessage, 0x212,,,, % "ahk_id " hWnd ;WM_EXITMENULOOP := 0x212
	hMenuBar := DllCall("GetMenu", Ptr,hWnd, Ptr)
	hMenuFile := DllCall("GetSubMenu", Ptr,hMenuBar, Int,0, Ptr)
	;ID_FILE_PAUSE := 65403
	vState := DllCall("GetMenuState", Ptr,hMenuFile, UInt,65403, UInt,0, UInt)
	vIsPaused := (vState >> 3) & 1
	DetectHiddenWindows, % vDHW
	return vIsPaused
}

global regWalkFactor := 1.25 ; since i made the paths all with vip, normalize

getWalkTime(d){
    baseTime := d * (1 + (regWalkFactor - 1) * (1 - options.VIP))
    
    if (options.Shifter) {
        baseTime := baseTime / 1.50
    }
    
    return baseTime
}

walkSleep(d){
    Sleep, % getWalkTime(d)
}

global azertyReplace := {"w":"z","a":"q"}

walkSend(k,t){
    if (options.AzertyLayout && azertyReplace[k]){
        k := azertyReplace[k]
    }
    Send, % "{" . k . (t ? " " . t : "") . "}"
}

press(k, duration := 50) {
    walkSend(k,"Down")
    walkSleep(duration)
    walkSend(k,"Up")
}

press2(k, k2, duration := 50) {
    walkSend(k,"Down")
    walkSend(k2,"Down")
    walkSleep(duration)
    walkSend(k,"Up")
    walkSend(k2,"Up")
}

reset() {
    global atSpawn

    ; if (atSpawn) {
    ;     return
    ; }

    press("Esc",150)
    Sleep, 50 * delayMultiplier
    press("r",150)
    Sleep, 50 * delayMultiplier
    press("Enter",150)
    Sleep, 50 * delayMultiplier

    atSpawn := 1
}

jump() {
    press("Space")
}

arcaneTeleport(){
    press("x",50)
}

; main stuff

global initialized := 0
global running := 0
global isFirstScan := 0
global Storage_YPos_Scan := 0
global Storage_YOffset_Scan := 0


initialize() {
    initialized := 1
    Sleep, 500

    if (disableAlignment) {
        ; Re-enable for reconnects
        disableAlignment := false
    } else {
        if (options.IsNikoPath = 1) {
            resetCameraAngle()
            Sleep, 750
        } else {
            alignCamera()
            Sleep, 750
        }
    }
}

resetZoom(){
    Loop 2 {
        if (checkInvOpen()){
            clickMenuButton(1)
        } else {
            break
        }
        Sleep, 400
    }

    ; press("i", 1000)
    ; Sleep, 200
    ; press("o", 200) ; TODO: Allow user to configure zoom distance
    ; Sleep, 200

    Sleep, 200
    Loop 40 {
        Click, WheelUp
        Sleep, 50
    }

    Loop 10 {
        Click, WheelDown
        Sleep, 50
    }

}

; x 385, y = 113
resetCameraAngle(){
    ; tysm @unconstitutional :3
    reset()
    Sleep, 750

    clickMouse(options["CollectionMenuX"], options["CollectionMenuY"])

    Sleep, 550
    getRobloxPos(rX,rY,rW,rH)
    clickMouse(options["CollectionExitButtonX"], options["CollectionExitButtonY"])
    Sleep, 650
    MouseClick
    Sleep, 650

    MouseClickDrag, R, options["CollectionExitButtonX"], options["CollectionExitButtonY"], options["CollectionExitButtonX"], options["CollectionExitButtonY"] + 70

    ; Sleep, 650
    ; press("i", 1500)
    ; Sleep, 350
    ; press("o", 415)
}

MouseClickDrag(x1, y1, x2, y2) {
    ; Move to start position
    MoveMouseDll(x1, y1, false)
    Sleep, 50
    Send {RButton Down} ; Press the button
    Sleep, 50
    
    ; Drag to end position
    MoveMouseDll(x2 - x1, y2 - y1, true)
    Sleep, 50
    Send, {RButton Up} ; Release the button
}

MoveMouseDll(x, y, relative := true) {
    MOUSEEVENTF_MOVE := 0x0001
    MOUSEEVENTF_ABSOLUTE := 0x8000
    
    flags := MOUSEEVENTF_MOVE
    if (!relative) {
        flags := flags | MOUSEEVENTF_ABSOLUTE
    }
    
    DllCall("mouse_event", "UInt", flags, "Int", x, "Int", y, "UInt", 0, "UInt", 0)
}

; MouseClickDragDll(button, x1, y1, x2, y2) {
;     MOUSEEVENTF_LEFTDOWN := 0x0002
;     MOUSEEVENTF_LEFTUP := 0x0004
;     MOUSEEVENTF_RIGHTDOWN := 0x0008
;     MOUSEEVENTF_RIGHTUP := 0x0010
    
;     buttonDown := (button = "Right") ? MOUSEEVENTF_RIGHTDOWN : MOUSEEVENTF_LEFTDOWN
;     buttonUp := (button = "Right") ? MOUSEEVENTF_RIGHTUP : MOUSEEVENTF_LEFTUP

;     ; Move to start position
;     MoveMouse(x1, y1, false)
;     Sleep, 50
    
;     ; Press the button
;     ; DllCall("mouse_event", "UInt", buttonDown, "Int", 0, "Int", 0, "UInt", 0, "UInt", 0)
;     Send {RButton Down}
;     Sleep, 50
    
;     ; Drag to end position
;     MoveMouse(x2 - x1, y2 - y1, true)
;     Sleep, 50
    
;     ; Release the button
;     Send, {RButton Up}
;     ; DllCall("mouse_event", "UInt", buttonUp, "Int", 0, "Int", 0, "UInt", 0, "UInt", 0)
; }

; Paths

rotateCameraMode(){
    ; Initialize retry counter
    static retryCount := 0
    maxRetries := 5 ; Set the maximum number of retries

    ; Update to the new camera mode
    camFollowMode := !camFollowMode
    mode := camFollowMode ? "Follow" : "Default"

    press("Esc")
    Sleep, 500
    press("Tab")
    Sleep, 500
    press("Down")
    Sleep, 150 * delayMultiplier
    press("Right")
    Sleep, 150 * delayMultiplier
    press("Right")
    Sleep, 150 * delayMultiplier

    ; If enabled, use OCR to confirm the camera mode change

    while (options.OCREnabled && !containsText(1055, 305, 120, 30, mode)) {
        ; Avoid infinite loop
        if (retryCount >= maxRetries) {
            logMessage("[rotateCameraMode] Failed to change camera mode to " mode)
            camFollowMode := !camFollowMode ; Reset to previous state
            retryCount := 0 ; Reset retry counter for the next call
            return
        }

        press("Right")
        Sleep, 150 * delayMultiplier

        retryCount++
    }

    press("Esc")
    Sleep, 250

    ; Reset retry counter after successful execution
    retryCount := 0
}

alignCamera(){
    startDim(1,"Aligning Camera, Please wait...")

    WinActivate, % "ahk_id " GetRobloxHWND()
    Sleep, 500

    closeChat()
    Sleep, 200

    reset()
    Sleep, 100

    rotateCameraMode() ; Follow

    clickMenuButton(2)
    Sleep, 500

    
    getRobloxPos(rX,rY,rW,rH)
    MouseMove, % rX + rW*0.15, % rY + 44 + rH*0.05 + options.BackOffset
    Sleep, 200
    MouseClick
    Sleep, 200

    rotateCameraMode() ; Default(Classic)
    Sleep, 100
    
    Loop 35 {
        Click, WheelUp
        Sleep, 50
    }
    
    Loop 10 {
        Click, WheelDown
        Sleep, 50
    }
    
    Sleep, 350

    walkSend("d","Down")
    walkSleep(200)
    jump()
    walkSleep(400)
    walkSend("d","Up")
    walkSend("w","Down")
    walkSleep(500)
    jump()
    walkSleep(800)
    jump()
    walkSleep(500)

    ; go to jake house
    walkSend("w","Up")
    walkSend("d","Down")
    walkSleep(300) 
    jump()
    walkSleep(780)
    walkSend("d","Up")
    walkSend("s","Down")
    walkSleep(460)
    walkSend("d","Down")
    walkSend("s","Up")
    walkSleep(920)
    walkSend("d","Up")
    walkSend("w","Down")
    walkSleep(1550)
    walkSend("w","Up")

    Sleep, 200


    rotateCameraMode() ; Follow
    Sleep, 1800
    rotateCameraMode() ; Default(Classic)
    Sleep, 850
    
    MouseClickDrag, R, rX + rW*0.15, rY + 44 + rH*0.05, rX + rW*0.15, rY + 444 + rH*0.05

    Sleep, 700
    removeDim()
    reset()
    Sleep, 2000
}

align(){ ; align v2
    if (isSpawnCentered && forCollection){
        isSpawnCentered := 0
        atSpawn := 0
        return
    }
    updateStatus("Aligning Character")
    if (atSpawn){
        atSpawn := 0
    } else {
        reset()
        Sleep, 2000
    }

    walkSend("d","Down")
    walkSend("w","Down")
    walkSleep(2500)
    walkSend("w","Up")
    walkSleep(750)
    walkSend("d","Up")
    Sleep, 50
    press("a",2500)
    Sleep, 50
}

collect(num){
    if (!options["ItemSpot" . num]){
        return
    }
    Loop, 6 
    {
        Send {f}
        Sleep, 75
    }
    Send {e}
    Sleep, 50
}

runPath(pathName,voidPoints,noCenter = 0){
    try {
        targetDir := pathDir . pathName . ".ahk"
        if (!FileExist(targetDir)){
            MsgBox, 0, % "Error",% "Path file: " . targetDir . " does not exist."
            return
        }
        if (HasVal(pathsRunning,targetDir)){
            return
        }
        pathsRunning.Push(targetDir)
        
        DetectHiddenWindows, On
        Run, % """" . A_AhkPath . """ """ . targetDir . """"
        pathRuntime := A_TickCount

        stopped := 0

        Loop 5 {
            if (WinExist(targetDir)){
                break
            }
            Sleep, 200
        }

        getRobloxPos(rX,rY,width,height)
        scanPoints := [[rX+1,rY+1],[rX+width-2,rY+1],[rX+1,rY+height-2],[rX+width-2,rY+height-2]]

        voidPoints := voidPoints ? voidPoints : []
        startTick := A_TickCount
        expectedVoids := 0
        voidCooldown := 0

        while (WinExist(targetDir)){
            if (!running){
                stopped := 1
                break
            }

            if (A_IsPaused){
                Sleep, 100
                continue
            }
            
            checkItemScheduler()
            Sleep, 1000

            for i,v in voidPoints {
                if (v){
                    if (A_TickCount-startTick >= getWalkTime(v)){
                        expectedVoids += 1
                        voidPoints[i] := 0
                    }
                }
            }
        }
        ; elapsedTime := (A_TickCount - pathRuntime)//1000
        ; logMessage("[runPath] " pathName " completed in " elapsedTime " seconds")

        if (stopped){
            WinClose, % targetDir
            isSpawnCentered := 0
            atSpawn := 1
        } else if (!noCenter) {
            isSpawnCentered := 1
        }
        liftKeys()
        pathsRunning.Remove(HasVal(pathsRunning,targetDir))
    } catch e {
        MsgBox, 0,Path Error,% "An error occurred when running path: " . pathDir . "`n:" . e
    }
}

searchForItems(){
    updateStatus("Searching for Items")
    atSpawn := 0

    runPath("searchForItems",[8250,18000],1)

    options.CollectionLoops += 1

    ; logMessage("[searchForItems] Items collected")
}

;searchForitems item scheduler
checkItemScheduler() {
    currentUnixTime := getUnixTime()

    for each, entry in ItemSchedulerEntries {
        if (entry.Enabled && currentUnixTime >= entry.NextRunTime) {
            ; Account for biome
            if (!entry.Biome || entry.Biome == "Any" || entry.Biome == currentBiome) {
                ; Pause paths
                PausePaths()

                Sleep, 750

                ; Use specified number of item
                UseItem(entry.ItemName, entry.Quantity)

                ; Update the NextRunTime for the next scheduled run
                if (entry.TimeUnit = "Seconds") {
                    frequencyInSeconds := entry.Frequency
                } else if (entry.TimeUnit = "Minutes") {
                    frequencyInSeconds := entry.Frequency * 60
                } else if (entry.TimeUnit = "Hours") {
                    frequencyInSeconds := entry.Frequency * 3600
                }

                nextRunTime := currentUnixTime + frequencyInSeconds
                entry.NextRunTime := nextRunTime
            }
        }
    }
}

doObby(){
    updateStatus("Doing Obby")
    
    runPath("doObby",[],1)

    options.ObbyAttempts += 1
}

obbyRun(){
    global lastObby
    Sleep, 250
    doObby()
    lastObby := A_TickCount
    Sleep, 100
}

walkToJakesShop(){
    press("w",800)
    press("a",1200)
}

walkToPotionCrafting(){
    sleep, 2000
    if (options.IsNikoPath = 1) {
        walkSend("s","Down")
        walkSend("d","Down")
        walkSleep(3800)
        walkSend("d","Up")
        walkSleep(675)
        walkSend("s","Up")
        walkSend("d","Down")
        walkSleep(777)
        jump()
        walkSend("s","Down")
        walkSleep(200)
        walkSend("s","Up")
        walkSend("d","Down")
        walkSleep(800)
        walkSend("w","Down")
        walkSleep(235)
        walkSend("w","Up")
        walkSleep(1225)
        jump()
        walkSleep(350)
        walkSend("d","Up")
        walkSend("d","Down")
        walkSleep(2500)
        press("w",500)
        walkSend("d","Up")
        walkSend("w","Down")
        walkSleep(100)
        jump()
        walkSleep(800)
        walkSend("d","Down")
        walkSleep(400)
        jump()
        walkSleep(200)
        walkSend("w","Up")
        walkSleep(500)
        jump()
        walkSleep(740)
        walkSend("d","up")
        walkSleep(200)
        walkSend("w","down")
        walkSleep(3050)
        walkSend("w","up")

    } else {
        walkSend("w","Down")
        walkSend("a","Down")
        walkSleep(3800)
        walkSend("a","Up")
        walkSleep(675)
        walkSend("w","Up")
        walkSend("a","Down")
        walkSleep(777)
        jump()
        walkSend("w","Down")
        walkSleep(200)
        walkSend("w","Up")
        walkSend("a","Down")
        walkSleep(800)
        walkSend("s","Down")
        walkSleep(235)
        walkSend("s","Up")
        walkSleep(1225)
        jump()
        walkSleep(350)
        walkSend("a","Up")
        walkSend("a","Down")
        walkSleep(2500)
        press("s",500)
        walkSend("a","Up")
        walkSend("s","Down")
        walkSleep(100)
        jump()
        walkSleep(800)
        walkSend("a","Down")
        walkSleep(400)
        jump()
        walkSleep(200)
        walkSend("s","Up")
        walkSleep(500)
        jump()
        walkSleep(740)
        walkSend("a","up")
        walkSleep(200)
        walkSend("s","down")
        walkSleep(3050)
        walkSend("s","up")
    }
    
    Sleep, 200
}

; End of paths

closeChat(){
    offsetX := 95
    offsetY := 25 ; Changed from 12
    if (options["RobloxUpdatedUI"] = 2) {
        offsetX := 126
        offsetY := 30
    }

    getRobloxPos(pX,pY,width,height)
    ;Highlight(pX + offsetX, pY + offsetY, 5, 5, 0x000000, 3500)

    PixelGetColor, chatCheck, % pX + offsetX, % pY + offsetY, RGB
    isWhite := compareColors(chatCheck,0xF1F1F3) < 16
    isGray := compareColors(chatCheck,0x36353A ) < 16
    if (isWhite || isGray){ ; is chat open??
        ClickMouse(pX + offsetX, pY + offsetY)
    }
}

checkInvOpen(){
    getRobloxPos(pX, pY, pW, pH)
    x := pX + (715 * (pW / 1920))
    y := pY + (267 * (pH / 1080))
    
    alreadyOpen := False

    PixelSearch, invFoundX, invFoundY, x - 50, y, x+150, y+150, 0x010304, 5, Fast RGB
    if (!ErrorLevel) {
        alreadyOpen := True
    } else {
        alreadyOpen := False
    }

    return alreadyOpen
}

mouseActions(){
    updateStatus("Performing Mouse Actions")
    getRobloxPos(rX, rY, width, height)
    MaxBank_X := Round(rX + (0.499 * width)) ; 958 / 1920 = 0.499
    MaxBank_Y := Round(rY + (0.737 * height)) ; 796 / 1080 = 0.737

    ; close jake shop if popup
    openP := getPositionFromAspectRatioUV(0.718,0.689,599/1015)
    openP2 := getPositionFromAspectRatioUV(0.718,0.689,1135/1015)
    ClickMouse(openP[1], openP2[2])
    ClickMouse(MaxBank_X, MaxBank_Y)

    if (options.ExtraRoblox){ ; for afking my 3rd alt lol
        MouseMove, 2150, 700
        Sleep, 300
        MouseClick
        Sleep, 250
        jump()
        Sleep, 500
        Loop 5 {
            Send {f}
            Sleep, 200
        }
        MouseMove, 2300,800
        Sleep, 300
        MouseClick
        Sleep, 250
    }
}

isFullscreen() {
	WinGetPos,,, w, h, % "ahk_id " . GetRobloxHWND()
	return (w = A_ScreenWidth && h = A_ScreenHeight)
}

; used from natro
GetRobloxHWND(){
	if (hwnd := WinExist("Roblox ahk_exe RobloxPlayerBeta.exe")) {
		return hwnd
	} else if (WinExist("Roblox ahk_exe ApplicationFrameHost.exe")) {
		ControlGet, hwnd, Hwnd, , ApplicationFrameInputSinkWindow1
		return hwnd
	} else {
        logMessage("[GetRobloxHWND] Roblox Process: Unknown", 1)
        Sleep, 5000
		return 0
    }
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

    ; What to do if Roblox isn't open
    if (macroStarted && !width) {
        attemptReconnect()
        return
    }
}

; screen stuff

checkHasObbyBuff(BRCornerX, BRCornerY, statusEffectHeight){
    if (!options.CheckObbyBuff){
        return 1
    }
    global obbyStatusEffectColor,obbyStatusEffectColor2,hasObbyBuff,statusEffectSpace
    Loop, 10
    {
        targetX := BRCornerX - (statusEffectHeight/2) - (statusEffectHeight + statusEffectSpace)*(A_Index-1)
        targetY := BRCornerY - (statusEffectHeight/2)
        PixelGetColor, color, targetX, targetY, RGB
        if (compareColors(color, obbyStatusEffectColor) < 16){
            hasObbyBuff := 1
            options.ObbyCompletes += 1
            updateStatus("Completed Obby")
            return 1
        }
    }  
    hasObbyBuff := 0
    return 0
}

spawnCheck(){ ; not in use
    if (!options.ExtraAlignment) {
        return 1
    }
    getRobloxPos(rX, rY, width, height)
    startPos := getFromUV(-0.55,-0.9,rX,rY,width,height)
    targetPos := getFromUV(-0.45,-0.9,rX,rY,width,height)
    startX := startPos[1]
    startY := startPos[2]
    distance := targetPos[1]-startX
    bitMap := Gdip_BitmapFromScreen(startX "|" startY "|" distance "|1")
    vEffect := Gdip_CreateEffect(5,50,30)
    Gdip_BitmapApplyEffect(bitMap,vEffect)
    ;Gdip_SaveBitmapToFile(bitMap,"test1.png")
    prev := 0
    greatestDiff := 0
    cat := 0
    Loop, %distance%
    {
        c := Gdip_GetPixelColor(bitMap,A_Index-1,0,1)
        if (!prev){
            prev := c
        }
        comp := compareColors(prev,c)
        greatestDiff := Max(comp,greatestDiff)
        if (greatestDiff = comp){
            cat := A_Index
        }
        prev := c
    }
    Gdip_DisposeEffect(vEffect)
    Gdip_DisposeBitmap(bitMap)
    return greatestDiff >= 5
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

    if (color2 not in 0x000000,0xffffff,0x393b3d){
        logMessage("[compareColors] " color1 " " color2 " " dist, 1)
    }
    return dist
}

clamp(x,mn,mx){
    nX := Min(x,mx)
    nX := Max(nX,mn)
    return nX
}

; menu ui stuff (ingame)

global menuBarOffset := 20 ;10 pixels from left edge

getMenuButtonPosition(num, ByRef posX := "", ByRef posY := ""){ ; num is 1-7, 1 being top, 7 only existing if you are the private server owner
    num := options["InOwnPrivateServer"] ? num : num + 1
    
    getRobloxPos(rX, rY, width, height)

    menuBarVSpacing := 10.5*(height/1080)
    menuBarButtonSize := 58*(width/1920)
    menuEdgeCenter := [rX + menuBarOffset, rY + (height/2)]
    startPos := [menuEdgeCenter[1]+(menuBarButtonSize/2),menuEdgeCenter[2]+(menuBarButtonSize/4)-(menuBarButtonSize+menuBarVSpacing-1)*3.5] ; final factor = 0.5x (x is number of menu buttons visible to all, so exclude private server button)
    
    posX := startPos[1]
    posY := startPos[2] + (menuBarButtonSize+menuBarVSpacing)*(num-0.5)

    MouseMove, % posX, % posY
}

clickMenuButton(num){
    getMenuButtonPosition(num, posX, posY)

    MouseMove, posX, posY
    Sleep, 200
    MouseClick
}

; storage ratio: w1649 : h952
global storageAspectRatio := 952/1649
global storageEquipUV := [-0.625,0.169] ; equip button
global storageSearchUV := [-0.2833,-0.3374]
global storageSearchResultUV := [-0.28, -0.18]
global specialStorageSearchUV := [-0.2833,0.105]
global specialStorageSearchResultUV := [-0.3, 0.2]

getUV(x,y,oX,oY,width,height){
    return [((x-oX)*2 - width)/height,((y-oY)*2 - height)/height]
}

getFromUV(uX,uY,oX,oY,width,height){
    return [Floor((uX*height + width)/2)+oX,Floor((uY*height + height)/2)+oY]
}

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

; Convert 1920x1080 coordinates to UV coordinates and then to user's screen coordinates
convertScreenCoordinates(x, y, ByRef cX := "", ByRef cY := "") {
    ; aspectRatio := 1920/1080
    
    ; getRobloxPos(rX, rY, width, height)
    ; robloxAspectRatio := width/height

    ; Convert screen coordinates to UV coordinates
    ; uv := getAspectRatioUVFromPosition(x, y, aspectRatio)

    ; Convert UV coordinates back to screen coordinates for mouse clicks
    ; cPos := getPositionFromAspectRatioUV(uv[1], uv[2], robloxAspectRatio)
    ; cX := cPos[1]
    ; cY := cPos[2]
    
    ; Use original 1920x1080 coordinates to avoid conversion issues as of 6/24
    cX := x
    cY := y
}

getScreenCenter(){
    getRobloxPos(rX, rY, width, height)
    return [rX + width/2, rY + height/2]
}

ShowMousePos() {
    MouseGetPos, mx,my
    p := getAspectRatioUVFromPosition(mx,my,storageAspectRatio)
    c := convertScreenCoordinates(mx,my)
    Tooltip, % "Current: " mx ", " my "`n"
            . "UV Ratio: " p[1] ", " p[2] "`n"
            . "1920x1080: " c[1] ", " c[2]
    Sleep, 5200
    Tooltip
}

isCraftingMenuOpen() {
    getRobloxPos(rX,rY,width,height)
    centerPos := [width*0.182, height*0.06]
    areaDims := [125, 50]
    closeX := rX + centerPos[1] - (areaDims[1]/2)
    closeY := rY + centerPos[2] - (areaDims[2]/2)

    if (containsText(closeX, closeY, areaDims[1], areaDims[2], "Close")) {
        return 1
    }

    PixelSearch, blackX, blackY, closeX, closeY, closeX+areaDims[1], closeY+areaDims[2], 0x060A09, 16, Fast RGB
    PixelSearch, whiteX, whiteY, closeX, closeY, closeX+areaDims[1], closeY+areaDims[2], 0xFFFFFF, 16, Fast RGB
    if (blackX && whiteX) {
        logMessage("Close button found")
        return 1
    }

    return 0
}

clickCraftingSlot(num,isPotionSlot := 0){
    getRobloxPos(rX,rY,width,height)

    scrollCenter := 0.17*width + rX
    scrollerHeight := 0.78*height
    scrollStartY := 0.15*height + rY

    slotHeight := (width/1920)*129 ; Changed 138 to 129 - Fixed gilded coin in Era 7

    if (isPotionSlot){ ; potion select sub menu
        scrollCenter := 0.365*width + rX
        scrollerHeight := 0.38*height
        scrollStartY := 0.325*height + rY
        ; slotHeight is the same for both crafting menus as of Era 7. May change again in the future
    }

    MouseMove, % scrollCenter, % scrollStartY-2
    Sleep, 250
    Click, WheelDown ; in case res upd
    Sleep, 100
    Loop 10 {
        Click, WheelUp
        Sleep, 75
    }

    fittingSlots := Floor(scrollerHeight/slotHeight) + (Mod(scrollerHeight, slotHeight) > height*0.045)
    if (fittingSlots < num){
        rCount := num-fittingSlots
        if (num = 13 && !isPotionSlot){
            rCount += 5
        }
        Loop %rCount% {
            Click, WheelDown
            Sleep, 200
        }
        if (isPotionSlot || (num != 13)){
            MouseMove, % scrollCenter, % scrollStartY + slotHeight*(fittingSlots-1) + rCount
        } else {
            MouseMove, % scrollCenter, % scrollStartY + slotHeight*(fittingSlots-3) + rCount
        }
    } else {
        MouseMove, % scrollCenter, % scrollStartY + slotHeight*(num-1)
    }

    Sleep, 300
    MouseClick
    Sleep, 200
    MouseGetPos, mouseX,mouseY
    MouseMove, % mouseX + width/4, % mouseY
}

craftingClickAdd(totalSlots, maxes := 0, isGear := 0) {
    if (!maxes){
        maxes := []
    }

    getRobloxPos(rX,rY,width,height)

    startXAmt := 0.6*width + rX
    startX := 0.635*width + rX
    startY := 0.413*height + rY
    slotSize := 0.033*height

    if (isGear){
        startXAmt := 0.582*width + rX
        startX := 0.62*width + rX
        startY := 0.395*height + rY
        slotSize := 0.033*height
    }

    fractions := [1, 0.5, 0.1, 0]

    slotI := 1 ; Maybe use A_Index instead?
    Loop %totalSlots% {
        ; Skip crafting slot if already complete
        slotPosY := startY + slotSize*(A_Index-1)
        PixelGetColor, checkC, startX, slotPosY, RGB
        ; logMessage("Slot " slotI " Color: " checkC, 1)
        if (!isGear && compareColors(checkC, 0x178111) < 6) {
            logMessage("Skipping completed slot " slotI " - color: " checkC, 1)
            slotI += 1
            continue
        }

        for _, fraction in fractions {
            ; Calculate the input quantity based on the maximum amount
            inputQty := Max(1, Floor(maxes[slotI] * fraction))
            ; logMessage("Crafting Slot " slotI " - Input Quantity: " inputQty " - Fraction: " fraction, 1)

            MouseMove, % startXAmt, % slotPosY
            Sleep, 200
            MouseClick
            Sleep, 200
            SendInput, % inputQty
            Sleep, 200

            ; Click the "Add" button
            MouseMove, % startX, % slotPosY
            Sleep, 200
            Loop 3 {
                MouseClick
                Sleep, 200
            }

            ; Check if the crafting slot is complete
            PixelGetColor, checkC, startX, slotPosY, RGB
            if (compareColors(checkC, 0x178111) < 20) {
                break
            }

            ; Avoid the fraction loop if the quantity is 1
            if (inputQty = 1) {
                break
            }
        }

        slotI += 1
    }

    ; Click the "Craft" button
    if (isGear){
        MouseMove, % 0.43*width + rX, % 0.635*height + rY
    } else {
        MouseMove, % 0.46*width + rX, % 0.63*height + rY
    }
    Sleep, 250
    MouseClick
}

; craftLocation: 0 = none, 1 = Stella, 2 = Jake
; retryCount: limit retry attempts to prevent infinite loop
handleCrafting(craftLocation := 0, retryCount := 0){
    static potionAutoAdd := 0

    getRobloxPos(rX,rY,rW,rH)
    if (retryCount = 0) {
        updateStatus("Beginning Crafting Cycle")
        Sleep, 2000
    } else if (retryCount = 2) {
        updateStatus("Crafting Failed. Fixing Camera...")
        Sleep, 2000
        resetCameraAngle()
        reset()
        Sleep, 500
        handleCrafting(0,retryCount+1)
        return
    } else if (retryCount > 2) {
        updateStatus("Crafting Failed. Continuing...")
        Sleep, 2000
        return
    }

    if (options.PotionCraftingEnabled && craftLocation != 2){
        ; align() is this even needed?
        reset()
        updateStatus("Walking to Stella's Cave (Crafting)")
        walkToPotionCrafting()
        Sleep, % (StellaPortalDelay && StellaPortalDelay > 0) ? StellaPortalDelay : 0
        Sleep, 2000
        walkSend("d","Down")
        walkSleep(200)
        walkSend("d","Up")
        walkSleep(500)
        press("f")
        walkSleep(1000)

        ; OCR - Check for "Close" button
        if (!isCraftingMenuOpen()) {
            updateStatus("Failed to open Potion menu")
            resetCameraAngle()
            handleCrafting(1,retryCount+1)
            return
        }

        updateStatus("Crafting Potions")

        if (options.potionAutoAddEnabled) {
            if ((getUnixTime() - options.LastPotionAutoAdd) >= ((options.PotionAutoAddInterval-1) * 60)) { ; 1m buffer to avoid waiting another cycle
                options.LastPotionAutoAdd := getUnixTime()

                ; Determine which potion to Auto Add next
                Loop 3 {
                    v := options["PotionCraftingSlot" A_Index]
                    if (v) {
                        maxIndex := A_Index
                    }
                }
                potionAutoAdd := (potionAutoAdd >= maxIndex) ? 1 : potionAutoAdd + 1
                logMessage("Auto Add Potion: " potionIndex[potionAutoAdd], 1)
            }
        }

        Loop 3 {
            v := options["PotionCraftingSlot" A_Index]
            logMessage("  Crafting: " potionIndex[v])
            if (v && craftingInfo[potionIndex[v]]){
                info := craftingInfo[potionIndex[v]]
                loopCount := info.attempts
                clickCraftingSlot(info.slot)
                Sleep, 200
                clickCraftingSlot(info.subSlot,1)
                Sleep, 200

                ; Loop %loopCount% {
                craftingClickAdd(info.addSlots,info.maxes)
                Sleep, 200
                ; }

                if (A_Index = potionAutoAdd) { ; Need to make sure this doesn't toggle Auto Add off
                    logMessage("Auto Add potion: " potionIndex[v], 1)
                    enableAutoAdd()
                    Sleep, 200
                }
            }
        }

        ; Click the "Close" button
        MouseMove, % rX + rW*0.175, % rY + rH*0.05
        Sleep, 200
        MouseClick

        ; alignCamera()
    }
    if (options.ItemCraftingEnabled && craftLocation != 1){
        ; align()
        updateStatus("Walking to Jake's Shop (Crafting)")
        walkToJakesShop()
        Sleep, 100
        press("f")
        Sleep, 4500
        openP := getPositionFromAspectRatioUV(-0.718,0.689,599/1015)
        openP2 := getPositionFromAspectRatioUV(-0.718,0.689,1135/1015)
        MouseMove, % openP[1], % openP2[2]
        Sleep, 200
        MouseClick
        Sleep, 1000

        ; OCR - Check for "Close" button
        if (!isCraftingMenuOpen()) {
            updateStatus("Failed to open Jake's Shop")
            handleCrafting(2,retryCount+1)
            resetCameraAngle()
            return
        }

        ; Click the "Close" button
        MouseMove, % rX + rW*0.175, % rY + rH*0.05
        Sleep, 200
        MouseClick

        ; alignCamera()
    }

    ; reset()
}

walkToStellaCave_Eon1(){
    updateStatus("Walking to Stella's Cave (Crafting)")
    if (options.VIP = 1){
        reset()
        Sleep, 650
        walkSend("s","Down")
        press("a", 120)
        walkSleep(3500)
        press("a", 2450)
        walkSleep(360)
        walkSend("s","Up")
        press("d", 750)
        press("s", 950)
        walkSleep(360)
        press("w", 260)
        walkSleep(120)
        walkSend("s","Down")
        walkSleep(152)
        jump()
        walkSleep(1879)
        walkSend("s","Up")
        press("a", 1430)
        walkSleep(160)
        press("s", 5840)
        walkSleep(100)
        press("a", 1468)
        walkSleep(100)
        walkSend("s","Down")
        walkSleep(1350)
        press("a", 70)
        walkSleep(120)
        press("a", 55)
        walkSleep(120)
        press("a", 55)
        walkSleep(120)
        press("a", 55)
        walkSleep(120)
        walkSend("s","Up")
        press2("a", "s", 2168)
        walkSleep(120)
        press("d", 270)
        walkSleep(120)
        press("w", 230)
        walkSleep(120)
        walkSend("s","Down")
        walkSleep(160)
        jump()
        walkSleep(688)
        walkSend("s","Up")
        walkSend("a","Down")
        walkSleep(115)
        jump()
        walkSleep(3160)
        walkSend("a","Up")
        press("s", 1659)

        ; entered the cave -> go to the cauldron
        walkSleep(1350)
        press("w", 175)
        walkSleep(100)
        press("a", 1330)
    } else {
        walkSend("s","Down")
        walkSleep(4320)
        press("a", 3250)
        walkSleep(360)
        walkSend("s","Up")
        press("d", 750)
        press("s", 950)
        walkSleep(360)
        press("w", 260)
        walkSleep(120)
        walkSend("s","Down")
        walkSleep(215)
        jump()
        walkSleep(1879)
        walkSend("s","Up")
        press("a", 1730)
        walkSleep(160)
        press("s", 7540)
        walkSleep(100)
        press("a", 1868)
        walkSleep(100)
        walkSend("s","Down")
        walkSleep(1550)
        press("a", 70)
        walkSleep(300)
        press("a", 85)
        walkSleep(300)
        press("a", 85)
        walkSleep(300)
        press("a", 85)
        walkSleep(300)
        press("a", 85)
        walkSleep(300)
        press("a", 35)
        walkSend("s","Up")
        Sleep, 2445
        press2("a", "s", 2368)
        walkSleep(120)
        press("d", 270)
        walkSleep(120)
        press("w", 230)
        walkSleep(120)
        walkSend("s","Down")
        walkSleep(160)
        jump()
        walkSleep(688)
        walkSend("s","Up")
        walkSend("a","Down")
        walkSleep(115)
        jump()
        walkSleep(3976)
        walkSend("a","Up")
        press("s", 2638)

        ; entered the cave -> go to the cauldron
        walkSleep(1350)
        press("w", 315)
        walkSleep(100)
        press("a", 1330)
    }
}

stellaCaveCrafting_Eon1() {
    if (options.PotionCraftingEnabled) {
        walkToStellaCave_Eon1()
        Sleep, 300
        updateStatus("Crafting Potions in Stella's Cave")
        press("f")
        Sleep, 2753

        if (!options.HasKey("PotionLastCraftedIndex")) {
            options.PotionLastCraftedIndex := 1
        }

        Loop {
            nextPotionIndex := options.PotionLastCraftedIndex
            v := options["PotionCraftingSlot" nextPotionIndex]
        
            if (v = 0) {
                options.PotionLastCraftedIndex := Mod(nextPotionIndex, 3) + 1
                
                if (options["PotionCraftingSlot1"] = 0 && options["PotionCraftingSlot2"] = 0 && options["PotionCraftingSlot3"] = 0) {
                    return
                }
                
                continue
            }
            break
        }
        
        logMessage("  Crafting: " potionIndex[v])

        if (v && craftingInfo[potionIndex[v]]) {
            info := craftingInfo[potionIndex[v]]

            ; Potion_SearchBar := [options["PotionSearchBarX"], options["PotionSearchBarY"]]
            ; ClickMouse(Potion_SearchBar[1], Potion_SearchBar[2])

            ; Sleep, 200
            ; SendInput, {Backspace}
            ; Sleep, 200
            ; SendInput, % potionIndex[v]
            ; Sleep, 200
            ; SendInput, {Enter}
            ; Sleep, 200

            if (info.potion_page = 2) {
                ClickMouse(options["FirstPotionSlotX"], options["FirstPotionSlotY"])
                Sleep, 350

                Loop, 10 {
                    MouseClick, WheelDown
                    Sleep, 30
                }
            } else if (info.potion_page = 1) {
                ClickMouse(options["FirstPotionSlotX"], options["FirstPotionSlotY"])
                Sleep, 350

                Loop, 10 {
                    MouseClick, WheelUp
                    Sleep, 30
                }
            }

            Sleep, 450
            
            ; Select potion
            FirstPotionSlot := [options["FirstPotionSlotX"], options["FirstPotionSlotY"] + ((info.slot - 1) * 113.4)]
            ClickMouse(FirstPotionSlot[1], FirstPotionSlot[2])
            Sleep, 200


            PixelSearch, Px, Py, FirstPotionSlot[1] - 50, FirstPotionSlot[2], FirstPotionSlot[1]+100, FirstPotionSlot[2]+25, 0x205b03, 16, Fast RGB
            if (ErrorLevel) {
                CraftButton := [options["CraftButtonX"], options["CraftButtonY"]]
                ClickMouse(CraftButton[1], CraftButton[2])
                Sleep, 200

                ; Auto
                AutoButton := [options["AutoButtonX"], options["AutoButtonY"]]
                ClickMouse(AutoButton[1], AutoButton[2])
                Sleep, 200

                logMessage("PotionAuto Add clicked", 1)
            } else {
                logMessage("Potion already on auto, skipping auto click")
                CraftButton := [options["CraftButtonX"], options["CraftButtonY"]]
                ClickMouse(CraftButton[1], CraftButton[2])
                Sleep, 200
            }

            ; here's the massive auto add loop thing
            if (options.PotionAutoAddEnabled) {
                addSlots := info.addSlots
                Loop, %addSlots% {
                    manualX := options[A_Index "_potion_manual_x"]
                    manualY := options[A_Index "_potion_manual_y"]

                    if (A_Index = 1) {
                        ClickMouse(manualX, manualY)
                        Sleep, 120
                        Loop, 10 {
                            MouseClick, WheelUp
                            Sleep, 30
                        }
                    }
                    
                    if (A_Index = 5) {
                        ClickMouse(manualX, manualY)
                        Sleep, 200
                        
                        Loop, 10 {
                            MouseClick, WheelDown
                            Sleep, 30
                        }

                    }

                    for index, maxAmount in info.maxes {
                        ClickMouse(manualX, manualY)
                        Sleep, 50
                        SendInput, ^a
                        Sleep, 50
                        SendInput, {Del} 
                        Sleep, 50
                        SendInput, % maxAmount
                        Sleep, 50
                        ClickMouse(manualX + 74, manualY)
                        Sleep, 130
                    }
                    
                }
            }

            Sleep, 350
            ClickMouse(options["FirstPotionSlotX"], options["FirstPotionSlotY"])
            Sleep, 550

            Loop, 10 {
                MouseClick, WheelUp
                Sleep, 30
            }

            Sleep, 450

            options.PotionLastCraftedIndex := Mod(nextPotionIndex, 3) + 1 ; Update the last crafted index for the next cycle
            Sleep, 1730
            reset()
        }
    }
}

; Click Auto Add if not enabled (old)
enableAutoAdd() {
    getRobloxPos(rX,rY,width,height)
    centerPos := [width*0.599, height*0.629]
    areaDims := [100, 50]
    autoX := rX + centerPos[1] - (areaDims[1]/2)
    autoY := rY + centerPos[2] - (areaDims[2]/2)

    PixelSearch,,, autoX, autoY, autoX+areaDims[1], autoY+areaDims[2], 0x30FF20, 16, Fast RGB
    if (ErrorLevel) {
        ClickMouse(rX + centerPos[1], rY + centerPos[2])
        logMessage("Auto Add clicked", 1)
    } else { ; Skip if Auto Add is already enabled
        logMessage("Auto Add already enabled", 1)
    }
}

waitForInvVisible(){
    Loop 10 {
        alreadyOpen := checkInvOpen()
        if (alreadyOpen)
            break
        Sleep, 50
    }
}

screenshotInventories(){ ; from all closed
    updateStatus("Inventory screenshots")
    topLeft := getPositionFromAspectRatioUV(-1.3,-0.9,storageAspectRatio)
    bottomRight := getPositionFromAspectRatioUV(1.3,0.75,storageAspectRatio)
    totalSize := [bottomRight[1]-topLeft[1]+1,bottomRight[2]-topLeft[2]+1]

    closeChat()

    
    ClickMouse(options["AuraStorageX"], options["AuraStorageY"])
    Sleep, 350

    ClickMouse(options["RegularAuraTabX"], options["RegularAuraTabY"])
    Sleep, 200

    waitForInvVisible()

    ssMap := Gdip_BitmapFromScreen(topLeft[1] "|" topLeft[2] "|" totalSize[1] "|" totalSize[2])
    Gdip_SaveBitmapToFile(ssMap,ssPath)
    Gdip_DisposeBitmap(ssMap)
    try webhookPost({files:[ssPath],embedImage:"attachment://ss.jpg",embedTitle: "Aura Storage"})

    Sleep, 200
    ClickMouse(options["InventoryMenuX"], options["InventoryMenuY"])
    Sleep, 200

    waitForInvVisible()

    itemButton := [options["ItemsTabX"], options["ItemsTabY"]]
    ClickMouse(itemButton[1], itemButton[2])
    Sleep, 200

    ssMap := Gdip_BitmapFromScreen(topLeft[1] "|" topLeft[2] "|" totalSize[1] "|" totalSize[2])
    Gdip_SaveBitmapToFile(ssMap,ssPath)
    Gdip_DisposeBitmap(ssMap)
    try webhookPost({files:[ssPath],embedImage:"attachment://ss.jpg",embedTitle: "Item Inventory"})

    Sleep, 200
    ClickMouse(options["QuestMenuX"], options["QuestMenuY"])
    Sleep, 200

    waitForInvVisible()

    dailyTab := [options["DailyTabX"], options["DailyTabY"]]
    ClickMouse(dailyTab[1], dailyTab[2])

    Sleep, 3000

    ssMap := Gdip_BitmapFromScreen(topLeft[1] "|" topLeft[2] "|" totalSize[1] "|" totalSize[2])
    Gdip_SaveBitmapToFile(ssMap,ssPath)
    Gdip_DisposeBitmap(ssMap)
    try webhookPost({files:[ssPath],embedImage:"attachment://ss.jpg",embedTitle: "Quests"})

    Sleep, 200
    ClickMouse(options["QuestMenuX"], options["QuestMenuY"])
    Sleep, 200
}

ClaimQuests() {
    updateStatus("Checking Quests")
    
    ClickMouse(options["QuestMenuX"], options["QuestMenuY"])
    waitForInvVisible()

    dailyTab := [options["DailyTabX"], options["DailyTabY"]]
    ClickMouse(dailyTab[1], dailyTab[2])

    btnYList := [0, 85, 155]


    claimButton := [options["ClaimButtonX"], options["ClaimButtonY"]]

    for _, btnY in btnYList {
        quest_list := [options["FirstQuestSlotX"], options["FirstQuestSlotY"]]
        ClickMouse(quest_list[1], quest_list[2] + btnY)
        Sleep, 250
        ClickMouse(claimButton[1], claimButton[2])
        Sleep, 250
    }

    ; Close Quest Menu
    ClickMouse(options["QuestMenuX"], options["QuestMenuY"])
    Sleep, 200
}

; Simplify frequent code
ClickMouse(posX, posY) {
    MouseMove, % posX, % posY
    Sleep, 100
    MouseClick
    Sleep, 100

    ; Highlight(posX-5, posY-5, 10, 10, 5000) ; Highlight for 5 seconds
}

Hold_LeftClick(posX, posY, holdTime := 3300) {
    MouseMove, %posX%, %posY%
    Sleep, 350

    if !GetKeyState("LButton", "P")
    {
        Click Down
    }

    totalSleepTime := 0
    interval := 50
    while (totalSleepTime < holdTime) {
        Sleep, %interval%
        totalSleepTime += interval
        if !GetKeyState("LButton", "P") 
        {
            Click Down
        }
    }

    Click Up
}

EquipAura(auraName := "") {
    if (auraName = "") {
        return
    }

    closeChat()

    ClickMouse(options["AuraStorageX"], options["AuraStorageY"])
    Sleep, 300
    
    ; click special tab (if user enabled it)
    if (options.SearchSpecialAuras = 1) {
        posBtn := [options["SpecialAuraTabX"], options["SpecialAuraTabY"]]
    } else {
        posBtn := [options["RegularAuraTabX"], options["RegularAuraTabY"]]
    }

    ClickMouse(posBtn[1], posBtn[2])
    Sleep, 280
    
    ; Search
    if (options.SearchSpecialAuras = 1) {
        posBtn := [options["AuraSearchBarX"], options["AuraSearchBarY"]]
    } else {
        posBtn := [options["AuraSearchBarX"], options["AuraSearchBarY"]]
    }

    ClickMouse(posBtn[1], posBtn[2])
    SendInput, % auraName
    Sleep, 200

    ; Search Result
    if (options.SearchSpecialAuras = 1) {
        posBtn := [options["FirstAuraSlotX"], options["FirstAuraSlotY"]]
    } else {
        posBtn := [options["FirstAuraSlotX"], options["FirstAuraSlotY"]]
    }
    
    MouseMove, posBtn[1], posBtn[2]

    Loop, 17 {
        MouseClick, WheelUp
        Sleep, 30
    }

    Sleep, 350

    ClickMouse(posBtn[1], posBtn[2])

    Sleep, 200

    ; Equip
    
    PixelGetColor, equipColor, options["EquipButtonX"], options["EquipButtonY"], RGB
    if (compareColors(equipColor, 0x1d361e) < 35 || compareColors(equipColor, 0x8aff7e) < 35) {
        posBtn := [options["EquipButtonX"], options["EquipButtonY"]]
        ClickMouse(posBtn[1], posBtn[2])
    } 

    Sleep, 200

    ; Clear Search - Necessary for screenshot
    if (options.SearchSpecialAuras = 1) {
        posBtn := [options["AuraSearchBarX"], options["AuraSearchBarY"]]
    } else {
        posBtn := [options["AuraSearchBarX"], options["AuraSearchBarY"]]
    }
    ClickMouse(posBtn[1], posBtn[2])

    Sleep, 100
    ClickMouse(options["AuraStorageX"], options["AuraStorageY"])
}

useItem(itemName, useAmount := 1) {
    updateStatus("Using items")
    logMessage("Using item: " itemName, 1)
    merchantPing := 0
    WinGetPos, winX, winY, currentWinWidth, currentWinHeight, ahk_exe RobloxPlayerBeta.exe
    
    ; Testing log
    ; logMessage("Merchant OCR X: " options["Merchant_Username_OCR_X"])
    ; logMessage("mari ping userid: " merchantPing)
    
    ; Open Inventory
    ClickMouse(options["InventoryMenuX"], options["InventoryMenuY"])
    waitForInvVisible()

    ; Select Items tab
    itemTab := [options["ItemsTabX"], options["ItemsTabY"]]
    ClickMouse(itemTab[1], itemTab[2])
    Sleep, 200

    ; Search for item
    searchBar := [options["SearchBarX"], options["SearchBarY"]]
    ClickMouse(searchBar[1], searchBar[2])

    SendInput, % itemName
    Sleep, 200

    ; Select item
    selectItem := [options["FirstItemSlotX"], options["FirstItemSlotY"]]
    ClickMouse(selectItem[1], selectItem[2])

    ; Update quantity - Must be done each time to reset amount from previous item, ctrl a then press delete
    updateQuantity:= [options["AmountBoxX"], options["AmountBoxY"]]
    ClickMouse(updateQuantity[1], updateQuantity[2])
    Sleep, 150
    Send, {Ctrl down}{a down}
    Sleep, 100
    
    Loop, 5 {
        Send, {Backspace}
    }

    Send, {Ctrl up}{a up}

    SendInput, % useAmount
    Sleep, 200

    ; Click Use
    clickUse:= [options["UseButtonX"], options["UseButtonY"]]
    ClickMouse(clickUse[1], clickUse[2])

    ; Clear search result
    ClickMouse(searchBar[1], searchBar[2])

    ; Close inventory
    ClickMouse(options["InventoryMenuX"], options["InventoryMenuY"])
    Sleep, 350

    ; Special case for "Merchant Teleport"
    if (itemName = "Merchant Teleport") {

        if (IsMerchantOnCooldown("Mari") || IsMerchantOnCooldown("Jester")) {
            return
        }

        if (options.AutoMerchantEnabled = 1) {
            logMessage("Pressing E for Merchant", 1)
            Sleep, 320
            Send, {E 3}
            sleep, 340
            
            Loop, 7 {
                Highlight(options["Merchant_Username_OCR_X"], options["Merchant_Username_OCR_Y"], options["Merchant_Username_OCR_W"], options["Merchant_Username_OCR_H"], 350)
                
                ocrResult := Merchant_CaptureScreen(options["Merchant_Username_OCR_X"], options["Merchant_Username_OCR_Y"], options["Merchant_Username_OCR_W"], options["Merchant_Username_OCR_H"])
                ;logMessage("[Merchant Detection]: OCR result: " ocrResult, 1)


                if (InStr(ocrResult, "Maori") || InStr(ocrResult, "MarorI") || InStr(ocrResult, "Mori") || InStr(ocrResult, "MarI") || InStr(ocrResult, "Maor!")) {
                    merchantName := "Mari"
                    logMessage("[Merchant Detection]: Mari name found!", 1)
                } else if (InStr(ocrResult, "Jester")) {
                    merchantName := "Jester"
                    logMessage("[Merchant Detection]: Jester name found!", 1)
                }

                if (merchantName != "") {
                    if (IsMerchantOnCooldown(merchantName)) {
                        logMessage(merchantName " is on cooldown. Skipping purchase.", 1)
                        Sleep, 350
                        leave_x := winX + (1321.0 * (currentWinWidth / 1920.0))
                        leave_y := winY + (923.0 * (currentWinHeight / 1080.0)) + 1.23
                        ClickMouse(leave_x, leave_y)
                        break
                    }

                    updateStatus("Merchant found! Pausing the macro...")
                    
                    Hold_LeftX := winX + (973.0 * (currentWinWidth / 1920.0))
                    Hold_LeftY := winY + (820.0 * (currentWinHeight / 1080.0)) + 2.75
                    Hold_LeftClick(Hold_LeftX, Hold_LeftY, 1860)

                    Sleep, 300

                    ; Merchant Handler function
                    Merchant_Handler(merchantName)
                    ClickMouse(900, 100)

                    Sleep, 450

                    ; if (merchantName = "Jester" && options.JesterExchangeEnabled = 1) {
                    ;     logMessage("[item scheduler] Starting Jester Exchange...", 1)
                    ;     clickMenuButton(3)
                    ;     waitForInvVisible()
                    ;     clickMenuButton(3)
                    ;     Sleep, 450
                    ;     Send, {E 3}
                    ;     Hold_LeftClick(Hold_LeftX, Hold_LeftY, 2870)
                    ;     jesterFound := false

                    ;     Loop, 3 {
                    ;         if (containsText(options["Merchant_Username_OCR_X"], options["Merchant_Username_OCR_Y"], 200, 42, "Jester") 
                    ;             || containsText(options["Merchant_Username_OCR_X"], options["Merchant_Username_OCR_Y"], 200, 42, "Jes1er")
                    ;             || containsText(options["Merchant_Username_OCR_X"], options["Merchant_Username_OCR_Y"], 200, 42, "Jes!er")
                    ;             || containsText(options["Merchant_Username_OCR_X"], options["Merchant_Username_OCR_Y"], 200, 42, "Jeste!") 
                    ;             || containsText(options["Merchant_Username_OCR_X"], options["Merchant_Username_OCR_Y"], 200, 42, "Jest3r")) {
                    ;             jesterFound := true
                    ;             break
                    ;         }
                    ;         Sleep, 350
                    ;     }

                    ;     if (jesterFound) {
                    ;         Jester_Exchange_Handler()
                    ;     } 
                    ; }

                    break
                }

                Sleep, 500
            }

            Loop, 3 {
                ClickMouse(1500, 300)
            }

            Sleep, 400

        } else {
            logMessage("Auto merchant disabled", 1)
        }
    }
    
    ResumePaths()
}

; check if the merchant is still on cooldown
IsMerchantOnCooldown(merchantName) {
    cooldownPeriod := 280000
    
    if (lastMerchantTime.HasKey(merchantName)) {
        elapsedTime := A_TickCount - lastMerchantTime[merchantName]
        if (elapsedTime < cooldownPeriod) {
            remainingTime := Round((cooldownPeriod - elapsedTime) / 1000)
            logMessage(merchantName " is on cooldown for " remainingTime " more seconds.", 1)
            return true
        }
    }
    return false
}

UpdateMerchantCooldown(merchantName) {
    lastMerchantTime[merchantName] := A_TickCount
    logMessage(merchantName " cooldown started. Will be on cooldown for 4 minutes.", 1)
}


LoadMerchantOptions(merchantName) {
    global merchantConfigPath_2, MerchantEntries

    MerchantItems := getINIData(merchantConfigPath_2)
    if (!MerchantItems) {
        logMessage("[LoadMerchantOptions] Unable to read merchant setting in config.ini")
        return
    }

    MerchantEntries := []
    
    removePatterns := [" \(buy both I and II\)", " \(buy both I and II and III\)"]

    for i, v in MerchantItems {
        if ((merchantName = "Mari" && InStr(i, "Mari_ItemSlot")) || (merchantName = "Jester" && InStr(i, "Jester_ItemSlot"))) {
            values := StrSplit(v, ",")

            if (values[2] = "True") {
                amount := (values[3] != "") ? values[3] : 1

                if (merchantName = "Mari") {
                    itemlist := MariItemsArray
                } else {
                    itemlist := JesterItemsArray
                }

                itemIndex := FindFirstNumber(i)
                item := itemlist[itemIndex]

                for _, pattern in removePatterns {
                    item := RegExReplace(item, pattern, "")
                }

                entry := {MerchantName: merchantName, ItemName: item, Amount: amount}
                MerchantEntries.Push(entry)
            }
        }
    }
}


FindFirstNumber(str) {
    RegExMatch(str, "\d+", number) ; Match the first sequence of digits
    return number
}


LoadJesterExchangeOptions() {
    global configPath, Jester_Exchange_ItemEntries
    Jester_Exchange_ItemEntries := []
    
    savedOptions := getINIData(configPath)
    if (!savedOptions) {
        logMessage("[LoadJesterExchangeOptions] Unable to read Jester Exchange settings from config.ini")
        return
    }

    for i, v in savedOptions {
        if (InStr(i, "Jester_Exchange_ItemSlot")) {
            slotNumber := StrReplace(i, "Jester_Exchange_ItemSlot")

            if (v != "None" && v != "") {
                entry := {SlotNumber: slotNumber, ItemName: v}
                Jester_Exchange_ItemEntries.Push(entry)
            }
        }
    }

    for i, entry in Jester_Exchange_ItemEntries {
        logMessage("[Jester Exchange] Item Slot " entry.SlotNumber " Loaded: " entry.ItemName, 1)
    }
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

    ; Format the merchant name properly
    StringUpper, Merchant_Name, Merchant_Name, T

    embedContent := Merchant_Name " has been detected on your screen."
    embedTitle := "**" Merchant_Name " Detected!**"
    embedColor := (Merchant_Name = "Mari") ? "255" : "8388736"  ; Blue for Mari, Purple for Jester
    embedThumbnail := (Merchant_Name = "Mari") 
        ? "https://static.wikia.nocookie.net/sol-rng/images/d/df/Mari_cropped.png/revision/latest?cb=20241015111527"
        : "https://static.wikia.nocookie.net/sol-rng/images/d/db/Headshot_of_Jester.png/revision/latest?cb=20240630142936"

    ; Construct the payload for the webhook
    payload_json := "{""content"": """ messageContent """," 
                  . """embeds"": [{"
                  . """title"": """ embedTitle """," 
                  . """description"": """ embedContent """," 
                  . """color"": " embedColor "," 
                  . """thumbnail"": {""url"": """ embedThumbnail """}," 
                  . """image"": {""url"": ""attachment://hewo_merchant.jpg""}," 
                  . """fields"": [{""name"": ""**" embedField "**"",""value"": """"}, {""name"": ""**Merchant PS: \n** **" ps_link "**"",""value"": """"}],"
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


Merchant_Handler(merchantName) {
    logMessage("Starting " merchantName " merchant handler", 1)
    updateStatus("Processing " merchantName " Autobuy...")
    getRobloxPos(rX, rY, rH, rW)
    LoadMerchantOptions(merchantName)
    WinGetPos, winX, winY, currentWinWidth, currentWinHeight, ahk_exe RobloxPlayerBeta.exe


    if (merchantName = "Mari") {
        merchantPing := merchantOptions["MerchantWebhook_Mari_UserID"]
    } else if (merchantName = "Jester") {
        merchantPing := merchantOptions["MerchantWebhook_Jester_UserID"]
    }

    if (IsMerchantOnCooldown(merchantName)) {
        return
    }

    ; Press open button 
    Loop, 4 {
        ClickMouse(options["Merchant_Open_Button_X"], options["Merchant_Open_Button_Y"])
        Sleep, 80
    }
    
    Merchant_Webhook_Main(merchantName, merchantOptions["MerchantWebhookLink"], merchantOptions["MerchantWebhook_PS_Link"], merchantPing, "Item screenshot")
    Sleep, 150


    if (MerchantEntries.MaxIndex() > 0) {
        logMessage("Items loaded for purchase: " MerchantEntries.MaxIndex(), 1)
        merchantItemNames := []
        purchasedItems := []

        for i, entry in MerchantEntries {
            if (entry.ItemName != "" && entry.ItemName != "None") {
                logMessage("Adding merchant item to list: " entry.ItemName, 1)
                merchantItemNames.Push(entry.ItemName)
            }
        }

        
        ; Initialize
        itemCount := 0
        totalItemsToPurchase := merchantItemNames.MaxIndex()
        itemsPurchased := 0

        ; Loop through merchant slots
        Loop, 10 {
            if (itemsPurchased >= totalItemsToPurchase) {
                logMessage("All items have been successfully purchased. Exiting loop.", 1)
                break
            }

            ; both merchant have 5 slots in eon 1 so yeah it will reset back to the first slot
            if (itemCount >= 5) {
                itemCount := 0
            }

            itemYPos := options["Merchant_FirstItem_Pos_Y"]
            itemXPos := options["Merchant_FirstItem_Pos_X"] + (itemCount * 182.2)

            logMessage("Clicking item slot " A_Index " at position X:" itemXPos " Y:" itemYPos, 1)
            Click, %itemXPos%, %itemYPos%
            Sleep, 550

            Loop, % merchantItemNames.MaxIndex() {
                itemName := merchantItemNames[A_Index]
                StringLower, itemNameLower, itemName
                itemNameTrimmed := Trim(itemNameLower)

                ; Skip items that have already been purchased
                if (purchasedItems.HasValue(itemNameTrimmed)) {
                    logMessage("Item " itemNameTrimmed " has already been purchased. Skipping...", 1)
                    continue
                }

                ; OCR detection for autobuy the item
                ocrResult := Merchant_CaptureScreen(options["Merchant_ItemName_OCR_X"], options["Merchant_ItemName_OCR_Y"], options["Merchant_ItemName_OCR_W"], options["Merchant_ItemName_OCR_H"])
                
                ; mostly the ingame item name issue, letter "a" is misdetected as "o" in the game due to sol rng dev using funny font causing this problem
                ocrMisdetect_Key := {"heovenly potion": "heavenly potion"
                ,"rune of goloxy": "rune of galaxy"
                ,"rune of roinstorm": "rune of rainstorm"
                ,"stronge potion": "strange potion"
                ,"stello's condle": "stella's candle"
                ,"merchont trocker": "merchant tracker"
                ,"rondom potion sock": "random potion sack"
                ,"geor a": "gear a"
                ,"geor b": "gear b"}

                StringLower, ocrResultLower, ocrResult
                logMessage("[Auto Merchant] OCR text: " ocrResultLower, 1)

                ; replace da misdetected ocr result with the correct one
                for misdetectedText, correctText in ocrMisdetect_Key {
                    if (InStr(ocrResultLower, misdetectedText)) {
                        logMessage("Found misdetected text: " misdetectedText " -> " correctText, 1)
                        ocrResultLower := StrReplace(ocrResultLower, misdetectedText, correctText)
                        break
                    }
                }
                
                if (InStr(ocrResultLower, itemNameTrimmed)) {
                    logMessage("Matching item found: " itemNameTrimmed, 1)

                    if (Merchant_HasMultipleVariants(itemNameTrimmed)) {
                        Loop, 5 {
                            currentSlotX := options["Merchant_FirstItem_Pos_X"] + ((A_Index - 1) * 182.2)
                            Click, %currentSlotX%, %itemYPos%
                            Sleep, 320
                            
                            variantOcrResult := Merchant_CaptureScreen(options["Merchant_ItemName_OCR_X"], options["Merchant_ItemName_OCR_Y"], options["Merchant_ItemName_OCR_W"], options["Merchant_ItemName_OCR_H"])
                            StringLower, variantOcrLower, variantOcrResult
                            
                            if (InStr(variantOcrLower, itemNameTrimmed)) {
                                itemAmount := MerchantEntries[A_Index].Amount
                                ClickMouse(options["Merchant_Purchase_Amount_X"], options["Merchant_Purchase_Amount_Y"])
                                Send, %itemAmount%
                                Sleep, 150
                                
                                ClickMouse(options["Merchant_Purchase_Button_X"], options["Merchant_Purchase_Button_Y"])
                                Hold_LeftX := winX + (973.0 * (currentWinWidth / 1920.0))
                                Hold_LeftY := winY + (820.0 * (currentWinHeight / 1080.0)) + 2.75
                                Hold_LeftClick(Hold_LeftX, Hold_LeftY, 2750)
                                Sleep, 350

                                logMessage("Purchase completed for variant of " itemNameTrimmed, 1)
                            }
                        }
                    } else {
                        itemAmount := MerchantEntries[A_Index].Amount
                        ClickMouse(options["Merchant_Purchase_Amount_X"], options["Merchant_Purchase_Amount_Y"])
                        Send, %itemAmount%
                        Sleep, 150
    
                        ClickMouse(options["Merchant_Purchase_Button_X"], options["Merchant_Purchase_Button_Y"])

                        Hold_LeftX := winX + (973.0 * (currentWinWidth / 1920.0))
                        Hold_LeftY := winY + (820.0 * (currentWinHeight / 1080.0)) + 2.75
                        Hold_LeftClick(Hold_LeftX, Hold_LeftY, 2750)
                        Sleep, 450
        
                        logMessage("Purchase completed for " itemNameTrimmed, 1)
        
                        ; Add the purchased item to the list and increment counters
                        purchasedItems.Push(itemNameTrimmed)
                        itemsPurchased++
                        merchantItemNames.RemoveAt(A_Index)
                        break
                    }
                }
            }

            itemCount++
        }

        ; Update merchant cooldown after successful purchases
        UpdateMerchantCooldown(merchantName)
    } else {
        logMessage("No items loaded for " merchantName " from config womp", 1)
    }

    ; Yeah annd we still update merchant cooldown even if you don't want to buy any items (womp)
    UpdateMerchantCooldown(merchantName)
}

Merchant_HasMultipleVariants(itemName) {
    return InStr(itemName, "fortune spoid") 
        || InStr(itemName, "strange potion")
        || InStr(itemName, "heavenly potion")
}

Jester_Exchange_Handler() {
    LoadJesterExchangeOptions()
    logMessage("Starting Jester exchange...", 1)
    updateStatus("Processing Jester Exchange...")
    getRobloxPos(rX, rY, rH, rW)

    WinGetPos, winX, winY, currentWinWidth, currentWinHeight, ahk_exe RobloxPlayerBeta.exe
    ItemNotEnough_closeButtonX := winX + (960.0 * (currentWinWidth / 1920.0))
    ItemNotEnough_closeButtonY := winY + (652.0 * (currentWinHeight / 1080.0)) + 3.82
    Hold_LeftX := winX + (1200.0 * (currentWinWidth / 1920.0))
    Hold_LeftY := winY + (747.0 * (currentWinHeight / 1080.0))
    
    ; Click the Jester exchange open button
    Loop, 4 {
        ClickMouse(options["Jester_Exchange_Button_X"], options["Jester_Exchange_Button_Y"])
        Sleep, 80
    }
    
    Hold_LeftClick(Hold_LeftX, Hold_LeftY, 2300)

    Sleep, 850
    Send, {E 3}
    Sleep, 450

    MouseClickDrag, R, rX + rW*0.15, rY + 44 + rH*0.05, rX + rW*0.15, rY + 444 + rH*0.05
    Sleep, 550

    customAmountsInput := options["Jester_Custom_Exchange_Amounts"]
    if (customAmountsInput) {
        customAmounts := StrSplit(customAmountsInput, ",")
    } else {
        customAmounts := [50, 25, 5] ; Default exchange values if you dont give any goofy amount
    }

    ; Randomize the order of the Jester exchange items
    if (Jester_Exchange_ItemEntries.MaxIndex() > 0) {
        Jester_Exchange_ItemEntries := Jester_ItemShuffle(Jester_Exchange_ItemEntries)
        logMessage("Items randomized for exchange: " Jester_Exchange_ItemEntries.MaxIndex(), 1)

        exchangedItems := []
        itemConversionCount := 0

        for i, entry in Jester_Exchange_ItemEntries {
            if (itemConversionCount >= 3) {
                break
            }

            itemName := entry.ItemName
            logMessage("[Jester Exchange] Searching and selecting item: " itemName, 1)
            ClickMouse(ItemNotEnough_closeButtonX, ItemNotEnough_closeButtonY)
            Sleep, 150
            ClickMouse(options["Jester_Item_Search_Bar_X"], options["Jester_Item_Search_Bar_Y"])
            Sleep, 200
            Send, %itemName%
            Sleep, 200
            ClickMouse(options["Jester_First_Item_Exchange_Slot_X"], options["Jester_First_Item_Exchange_Slot_Y"])
            Sleep, 250

            ; skip void coin if it actually about to exchange it
            if (containsText(options["Merchant_ItemName_OCR_X"], options["Merchant_ItemName_OCR_Y"], 323, 30, "Void Coin")) {
                continue
            }

            for amountIndex, amount in customAmounts {
                ClickMouse(ItemNotEnough_closeButtonX, ItemNotEnough_closeButtonY)
                Sleep, 100
                ClickMouse(options["Merchant_Purchase_Amount_X"], options["Merchant_Purchase_Amount_Y"])
                Sleep, 250
                Send, %amount%
                Sleep, 350
                ClickMouse(options["Merchant_Purchase_Button_X"], options["Merchant_Purchase_Button_Y"])
                ;Hold_LeftClick(Hold_LeftX, Hold_LeftY, 2550)
            }

            exchangedItems.Push(itemName)
            itemConversionCount++
            Sleep, 200
        }

        logMessage("Jester Exchange completed for two items.", 1)
    } else {
        logMessage("No items loaded for Jester Item Exchange.", 1)
    }
}



Jester_ItemShuffle(arr) {
    Random, rSeed, 1, 999999
    Random, , %rSeed%
    shuffled := []

    while (arr.MaxIndex()) {
        Random, idx, 1, arr.MaxIndex()
        shuffled.Push(arr.RemoveAt(idx))
    }

    return shuffled
}


checkBottomLeft(){
    getRobloxPos(rX,rY,width,height)

    start := [rX, rY + height*0.86]
    finish := [rX + width*0.14, rY + height]
    totalSize := [finish[1]-start[1]+1, finish[2]-start[2]+1]
    readMap := Gdip_BitmapFromScreen(start[1] "|" start[2] "|" totalSize[1] "|" totalSize[2])
    ;Gdip_ResizeBitmap(readMap,500,500,1)
    readEffect1 := Gdip_CreateEffect(7,100,-100,50)
    readEffect2 := Gdip_CreateEffect(2,10,100)
    Gdip_BitmapApplyEffect(readMap,readEffect1)
    Gdip_BitmapApplyEffect(readMap,readEffect2)
    Gdip_SaveBitmapToFile(readMap,ssPath)
    OutputDebug, % ocrFromBitmap(readMap)
    Gdip_DisposeBitmap(readMap)
    Gdip_DisposeEffect(readEffect1)
}

getUnixTime() {
    now := A_NowUTC
    EnvSub, now, 1970, seconds
    return now
}

closeRoblox(){
    WinClose, % "ahk_id " . GetRobloxHWND()
    WinClose, % "Roblox Crash"
}

isGameNameVisible() {
    getRobloxPos(pX,pY,width,height)

    ; Game Logo/Name
    x := pX + (width * 0.25)
    y := pY + (height * 0.05)
    w := width // 5
    h := height // 5

    colors := [0xD356FF, 0x8528FF, 0x140E46, 0x000000] ; Lavender, Purple, Dark Blue, Black
    variation := 10

    foundColors := 0

    ; Search for each color in the defined area
    for color in colors {
        PixelSearch, FoundX, FoundY, x, y, x + w, y + h, color, variation, Fast RGB
        if (ErrorLevel = 0) {
            foundColors++
            logMessage("[GameName] Color " color " found at " FoundX ", " FoundY)
            Highlight(FoundX-5, FoundY-5, 10, 10, 5000, "Yellow") ; Temporary for debug
        } else {
            return false
        }
    }
    if (foundColors = colors.Length()) {
        logMessage("[GameName] Colors found: " foundColors " out of " colors.Length())
        Highlight(x, y, w, h, 2500) ; Temporary for debug
        return true
    }
    return false
}

getPlayButtonColorRatio() {
    getRobloxPos(pX,pY,width,height)
    
    ; Play Button Text
    targetW := height * 0.15
    startX := width * 0.5 - targetW * 0.55
    x := pX + startX
    y := pY + height * 0.8
    w := targetW * 1.1
    h := height * 0.1
    ; OutputDebug, % x ", " y ", " w ", " h
    ; Highlight(x, y, w, h, 5000)

    retrievedMap := Gdip_BitmapFromScreen(x "|" y "|" w "|" h)
    ; Gdip_SaveBitmapToFile(retrievedMap, "retrievedMap.png")
    effect := Gdip_CreateEffect(5,-60,80)
    Gdip_BitmapApplyEffect(retrievedMap,effect)
    ; Gdip_SaveBitmapToFile(retrievedMap, "retrievedMap_effect.png")
    playMap := Gdip_ResizeBitmap(retrievedMap,32,32,0)
    ; Gdip_SaveBitmapToFile(playMap, "playMap.png")
    Gdip_GetImageDimensions(playMap, Width, Height)
    ; OutputDebug, % "playMap dimensions: " Width "w x " Height "h"

    blackPixels := 0
    whitePixels := 0

    Loop, %Width% {
        tX := A_Index-1
        Loop, %Height% {
            tY := A_Index-1
            pixelColor := Gdip_GetPixel(playMap, tX, tY)
            blackPixels += compareColors(pixelColor,0x000000) < 32
            whitePixels += compareColors(pixelColor,0xffffff) < 32
        }
    }
    ; OutputDebug, % "Black Pixels: " blackPixels
    ; OutputDebug, % "White Pixels: " whitePixels

    Gdip_DisposeEffect(effect)
    Gdip_DisposeBitmap(playMap)
    Gdip_DisposeBitmap(retrievedMap)
    
    if (whitePixels > 30 && blackPixels > 30){
        ratio := whitePixels/blackPixels
        OutputDebug, % "ratio: " ratio "`n"

        ; return (ratio > 0.35) && (ratio < 0.65)
        return ratio
    }
    return 0
}

isPlayButtonVisible(){ ; Era 8 Play button: 750,860,420,110 (covers movement area)
    getRobloxPos(pX,pY,width,height)

    ; Play Button Area
    targetW := height * 0.3833
    startX := width * 0.5 - targetW * 0.55
    x := pX + startX
    y := pY + height * 0.8
    w := targetW * 1.1
    h := height * 0.1

    ;Highlight(x, y, w, h, 5000)

    startButton := Miscellaneous_CaptureScreen(x, y, w, h)

    if (InStr(startButton, "Start") || InStr(startButton, "Stort")) {
        logMessage("[isPlayButtonVisible] Play button detected with OCR")
        return true
    }

    ; Check again after delay to avoid false positives
    ; if (isGameNameVisible()) {
    ;     Sleep, 5000
    ;     return isGameNameVisible()
    ; }

    ; Compare after 5 checks to rule out false positives
    ratioSum := 0
    Loop, 5 {
        ratioSum += getPlayButtonColorRatio()
    }
    ratioAvg := ratioSum / 5
    if (ratioAvg >= 0.09 && ratioAvg <= 0.13) {
        logMessage("[isPlayButtonVisible] Color Ratio: " ratioAvg " (Average of 5 checks)")
        return true
    }
    return false
}

; Assumes button was previously detected using isPlayButtonVisible()
ClickPlay() {
    updateStatus("Game Loaded")

    StopPaths()
    getRobloxPos(pX,pY,width,height)

    rHwnd := GetRobloxHWND()
    if (rHwnd) {
        WinActivate, ahk_id %rHwnd%
    }
    
    ; Click Play
    Loop, 10 {
        ClickMouse(pX + (width*0.5), pY + (height*0.85))
        Sleep, 750
    }

    ; Skip existing aura prompt
    ClickMouse(pX + (width*0.6), pY + (height*0.85))
    Sleep, 2000

    ; zoom in and out 
    press("i", 1650)
    Sleep, 350
    press("o", 415)
    
    ; Enable Auto Roll - Completely removed from Initialize() to avoid toggling when macro is restarted, but game is not
    ;ClickMouse(pX + (width*0.35), pY + (height*0.95))

    ; Enable Merchant Tracker - Introduced Era 8.5 Update
    ; No harm if user doesn't own
    ; Sleep, 2000
    ; useItem("Merchant Tracker")
}

; Clear RAM by restarting Roblox
; Used with Reconnect setting to relaunch game
ClearRAM() {
    ; Abort conditions
    if (!options.RestartRobloxEnabled || !options.ReconnectEnabled || !running) {
        return 0
    }

    updateStatus("Restarting Roblox to clear RAM")
    sleep, 2000
    rHwnd := GetRobloxHWND()
    if (rHwnd) {
        WinClose, ahk_id %rHwnd%
    }
    attemptReconnect()
    
    return 1 ; Notify calling function that Roblox was restarted
}

; Enable Auto Roll - OCR detect if Auto Roll is OFF and click to enable
enableAutoRoll() {
    getRobloxPos(pX,pY,width,height)

    btnX := pX + (width*0.35)
    btnY := pY + (height*0.95)
    if (containsText(btnX - 100, btnY - 25, 200, 50, "OFF")) {
        ClickMouse(btnX, btnY)
    }
}

ReceiveFromStatus(wParam, lParam) {
    StringAddress := NumGet(lParam + 2*A_PtrSize)
    CopyDataSize := NumGet(lParam + A_PtrSize)

    VarSetCapacity(ReceivedData, CopyDataSize)
    DllCall("RtlMoveMemory", "Ptr", &ReceivedData, "Ptr", StringAddress, "Ptr", CopyDataSize)
    
    ; Ensure null termination for the string
    ReceivedData := StrGet(&ReceivedData, CopyDataSize/2)

    currentBiome := ReceivedData
    logMessage("New Biome: " currentBiome)
}

LogError(exc) {
    logMessage("[LogError] Error on line " exc.Line ": " exc.Message)
    try webhookPost({embedContent: "[Error - Main.ahk - Line " exc.Line "]: " exc.Message, embedColor: statusColors["Roblox Disconnected"]})
}

logMessage(message, indent := 0) {
    global loggingEnabled, mainDir, lastLoggedMessage
    maxLogSize := 1048576 ; 1 MB

    if (!loggingEnabled) {
        return
    }

    ; Sanitize message
    message := StrReplace(message, options.WebhookLink, "*WebhookLink*")


    ; Avoid logging the same message again
    if (message = lastLoggedMessage) {
        return
    }
    
    logFile := mainDir . "\lib\macro_log.txt"
    try {
        ; Check the log file size and truncate if necessary
        if (FileExist(logFile) && FileGetSize(logFile) > maxLogSize) {
            FileDelete, %logFile%
        }

        if (indent) {
            message := "    " . message
        }
        FormatTime, fTime, , hh:mm:ss
        FileAppend, % fTime " " message "`n", %logFile%
        OutputDebug, % fTime " " message

        ; Update the last logged message
        lastLoggedMessage := message
    } catch e {
        ; TODO: handle gracefully
        ; ignore error popup for now
    }
}

; Function to get the size of a file
FileGetSize(filePath) {
    FileGetSize, fileSize, %filePath%
    return fileSize
}

; Check if area contains the specified text
containsText(x, y, width, height, text) {
    ; Potential improvement by ignoring non-alphanumeric characters
    ; Highlight(x-10, y-10, width+20, height+20, 2000)
    
    try {
        pbm := Gdip_BitmapFromScreen(x "|" y "|" width "|" height)
        pbm := Gdip_ResizeBitmap(pbm,500,500,true)
        ocrText := ocrFromBitmap(pbm)
        Gdip_DisposeBitmap(pbm)

        if (!ocrText) {
            return false
        }
        ocrText := RegExReplace(ocrText,"(\n|\r)+"," ")
        StringLower, ocrText, ocrText
        StringLower, text, text
        textFound := InStr(ocrText, text)

        if (textFound > 0) { ; Reduce logging by only saving when found
            logMessage("[containsText] Searching: " text "  |  Found: '" ocrText "'", 1)
        }

        return textFound > 0
    } catch e {
        logMessage("[containsText] Error searching '" text "': `n" e, 1)
        return -1
    }
}

FindSolsRNGButtons() {
    try {
        Gui, Default

        GuiControlGet, storage_Y_Offset_option, , StorageYOffsetInterval
        if (storage_Y_Offset_option = "")
        {
            storage_Y_Offset_option := Storage_YOffset_Scan 
            logMessage("[FindSolsRNGButton] GuiControlGet failed for StorageYOffsetInterval, using global Storage_YOffset_Scan")
        }

        GuiControlGet, storage_Y_Pos_option, , StorageYPosScanInterval
        if (storage_Y_Pos_option = "")
        {
            storage_Y_Pos_option := Storage_YPos_Scan
            logMessage("[FindSolsRNGButton] GuiControlGet failed for StorageYPosScanInterval, using global Storage_YPos_Scan")
        }

        GuiControlGet, scan_loops_attempt, , ScanLoopAttemptsUpDownInterval
        if (scan_loops_attempt = "")
        {
            scan_loops_attempt := 1
            logMessage("[FindSolsRNGButton] GuiControlGet failed for ScanLoopAttemptsUpDownInterval, using default value 1")
        }
    } catch e {
        logMessage("[FindSolsRNGButton] Error with GuiControlGet: " e.Message)
        storage_Y_Offset_option := Storage_YOffset_Scan
        storage_Y_Pos_option := Storage_YPos_Scan
        scan_loops_attempt := 2
    }

    updateStatus("Scanning button... (Tries: )")
    buttonCoords := []  ; Initialize an empty array to store button coordinates if needed
    global_Button_Found := 0

    ; Get current Roblox window size and client area size
    WinGetPos, , , currentWinWidth, currentWinHeight, ahk_exe RobloxPlayerBeta.exe

    ; Reference resolution (1920x1080)
    refWidth := 1920
    refHeight := 1080

    ; Calculate scaling factors
    scaleX := currentWinWidth / refWidth
    scaleY := currentWinHeight / refHeight

    ; Original dimensions
    origX := 15
    origY := storage_Y_Pos_option
    origW := 52
    origH := 55
    origYOffsetIncrement := storage_Y_Offset_option

    ; Scaled dimensions
    x := origX
    y := Floor(origY * scaleY)
    w := Floor(origW * scaleX)
    h := Floor(origH * scaleY)
    yOffsetIncrement := Floor(origYOffsetIncrement * scaleY)

    ; Pixel color for the button
    buttonPixelColor := 0xFFFFFF

    Loop, %scan_loops_attempt% {  ; Retry loop based on user input
        yOffset := 0   ; Initialize yOffset before each retry
        numButtonsFound := 0 ; Variable to count if found the button pixel and count it

        Loop, 5 { ; Loop through buttons
            buttonIndex := A_Index
            centerX := x + w / 2
            centerY := y + yOffset + h / 2
            MouseMove, %centerX%, %centerY%
            Sleep, 30  ; Delay before getting the pixel color

            ; Scan within the button area for the white pixel color
            ScanArea := { "left": x, "top": y + yOffset, "right": x + w - 1, "bottom": y + yOffset + h - 1 }
            PixelSearch, Px, Py, ScanArea.left, ScanArea.top, ScanArea.right, ScanArea.bottom, buttonPixelColor, 0, Fast

            if !ErrorLevel {
                MouseMove, %Px%, %Py%
                numButtonsFound++ ; Increment the counter
                global_Button_Found := numButtonsFound
            }

            yOffset += yOffsetIncrement  ; Offset y to move to the next button position
            ; Check if reached the bottom of the window
            if (y + yOffset + h > currentWinHeight) {
                break
            }
        }

        updateStatus("Scanning button... (Tries: " A_Index ")")
        logMessage("[FindSolsRNGButton] Attempt " A_Index " completed. Buttons found so far: " numButtonsFound)
        isFirstScan := 1
        Sleep, 1000
    }

    if (global_Button_Found > 0) {  ; If at least one button was found
        logMessage("[FindSolsRNGButton] Total buttons found: " global_Button_Found) ; Log the count 

        if (global_Button_Found == 7) {
            options["InOwnPrivateServer"] := 0
        } else if (global_Button_Found == 8) {
            options["InOwnPrivateServer"] := 1
        }

        return true  ; Exit the function and return true (success)
    }

    logMessage("[FindSolsRNGButton] Could not find Sol's RNG button after " scan_loops_attempt " attempts.")
    return false ; If no buttons are found after the specified number of attempts
}


; Noteab (Windy) Progress
ToggleStorageYPOS_Highlight() {
    GuiControlGet, newStorageYPosScan, , StorageYPosScanInterval
    GuiControlGet, newStorageYOffset, , StorageYOffsetInterval

    ; Get current Roblox window size and client area size
    WinGetPos, , , currentWinWidth, currentWinHeight, ahk_exe RobloxPlayerBeta.exe

    ; Reference resolution (1920x1080)
    refWidth := 1920
    refHeight := 1080

    ; Calculate scaling factors
    scaleX := currentWinWidth / refWidth
    scaleY := currentWinHeight / refHeight

    ; Original dimensions
    origX := 15
    origY := newStorageYPosScan
    origW := 52
    origH := 55
    origYOffsetIncrement := newStorageYOffset

    ; Scaled dimensions
    x := origX  ; X value is fine, no scaling needed for x
    y := Floor(origY * scaleY)
    w := Floor(origW * scaleX)
    h := Floor(origH * scaleY)
    yOffsetIncrement := Floor(origYOffsetIncrement * scaleY)

    ; Highlight the search area for all potential button positions
    Loop, 5 {
        yOffset := (A_Index - 1) * yOffsetIncrement
        if (y + yOffset + h > currentWinHeight) {
            break
        }
        Highlight(x, y + yOffset, w, h, 6000)
    }
}

attemptReconnect(failed := 0){
    ; Set default y position and offset of storage instead since guicontrolget dumped error when reconnecting, gg my macro :broken_heart:
    Storage_YPos_Scan := 318
    Storage_YOffset_Scan := 70 
    
    logMessage("[attemptReconnect] Reconnect check - Fail count: " failed)
    initialized := 0
    if (reconnecting && !failed){
        return
    }
    if (!options.ReconnectEnabled){
        logMessage("[attemptReconnect] Reconnect not enabled. Stopping...", 1)
        stop()
        return
    }
    reconnecting := 1
    macroStarted := 0
    success := 0
    
    ; stop(0, 1)
    StopPaths()
    closeRoblox()

    updateStatus("Reconnecting")
    Sleep, 5000
    Loop 5 {
        Sleep, % (A_Index-1)*10000
        try {
            if (options.PrivateServerId && A_Index < 3){
                Run % """roblox://placeID=15532962292&linkCode=" options.PrivateServerId """"
            } ;else {
            ;     Run % """roblox://placeID=15532962292""" ; fallback to public
            ; }
        } catch e {
            logMessage("[attemptReconnect] Unable to open Private Server. Error: " e.message)
            continue
        }

        Loop 240 {
            rHwnd := GetRobloxHWND()
            if (rHwnd) {
                WinActivate, ahk_id %rHwnd%
                updateStatus("Roblox Opened")
                logMessage("[attemptReconnect] Detected Roblox opened at loop " A_Index, 1)
                break
            }
            if (A_Index == 240) { 
                logMessage("[attemptReconnect] Unable to get Roblox HWND.")
                Sleep, 10000
                continue 2
            }
            Sleep 1000
        }

        Loop 120 {
            getRobloxPos(pX,pY,width,height)

            valid := 0
            if (isPlayButtonVisible()){
                Sleep, 2000
                valid := isPlayButtonVisible()
            }
            
            if (valid){
                ClickPlay()
                break
            }

            if (A_Index == 120 || !GetRobloxHWND()) {
                logMessage("[attemptReconnect] Play button not found or Roblox closed.")
                continue 2
            }
            Sleep 1000
        }

        options.LastRobloxRestart := getUnixTime() ; Reset timer
        updateStatus("Reconnect Complete")
        success := 1
        break
    }

    if (success){
        reconnecting := 0
    } else {
        if (failed < 3) { ; Limit the number of attempts to prevent infinite recursion
            Sleep, 30000
            attemptReconnect(failed + 1)
        } else {
            updateStatus("Reconnect Failed")
            logMessage("[attemptReconnect] Failed to reconnect after multiple attempts.")
            reconnecting := 0
        }
    }
}

checkDisconnect(wasChecked := 0){
    logMessage("[checkDisconnect] Checking for disconnect")
    getRobloxPos(windowX, windowY, windowWidth, windowHeight)

    ; if (options.OCREnabled) {
    if (containsText(845, 407, 235, 75, "Disconnected")) { ; 1025, 450
        logMessage("[checkDisconnect] 'Disconnected' popup found with OCR")
        updateStatus("Roblox Disconnected")
        options.Disconnects += 1
        return 1
    }
        ; return 0 ; Commented out to allow secondary check below
    ; }

	if ((windowWidth > 0) && !WinExist("Roblox Crash")) {
		pBMScreen := Gdip_BitmapFromScreen(windowX+(windowWidth/4) "|" windowY+(windowHeight/2) "|" windowWidth/2 "|1")
        matches := 0
        hW := windowWidth/2
		Loop %hW% {
            matches += (compareColors(Gdip_GetPixelColor(pBMScreen,A_Index-1,0,1),0x393b3d) < 8)
            if (matches >= 128) {
                logMessage("[checkDisconnect] High probability of Disconnect screen found after " A_Index " loops", 1)
                break
            }
        }
        Gdip_DisposeBitmap(pBMScreen)
        if (matches < 128) {
            return 0
        }
	}
    if (wasChecked) {
        updateStatus("Roblox Disconnected")
        options.Disconnects += 1
        return 1
    } else {
        Sleep, 3000
        return checkDisconnect(1)
    }
}

RemoveTooltip(interval) {
    SetTimer, ClearToolTip, % -interval * 1000
}

; Closes all "instance already running" alerts
CloseBSAlerts() {
    WinGet, id, List, Bloxstrap ahk_exe Bloxstrap.exe
    Loop, %id% {
        this_id := id%A_Index%
        PostMessage, 0x0112, 0xF060,,, % "ahk_id" this_id ; 0x0112 = WM_SYSCOMMAND, 0xF060 = SC_CLOSE

        logMessage("[Bloxstrap Alert] Closed popup " this_id, 1)
    }
}

/*
testPath := mainDir "images\test.png"
OutputDebug, testPath
pbm := Gdip_LoadImageFromFile(testPath) ; Gdip_BitmapFromScreen("0|0|100|100")
pbm2 := Gdip_ResizeBitmap(pbm,1500,1500,true)
Gdip_SaveBitmapToFile(pbm2,"test2.png")

MsgBox, % ocrFromBitmap(pbm2)
ExitApp
*/

reconnectTimeout := 60000 ; 60 seconds
mainLoop(){
    Global
    if (reconnecting) { ; TODO: Avoid infinite loop from reconnect error
        Sleep, 1000
        return

        ; Track the start time
        ; startTime := A_TickCount

        ; ; Loop until reconnecting is false or timeout is exceeded
        ; while (!GetRobloxHWND()) {
        ;     Sleep, 15000
        ;     elapsedTime := A_TickCount - startTime
        ;     if (elapsedTime > reconnectTimeout) {
        ;         ; Log an error and take appropriate action
        ;         logMessage("[Error] Reconnect timeout exceeded. Please check the program status.", 1)
        ;         attemptReconnect(1)
        ;         return
        ;     }
        ; }
    }

    currentId := GetRobloxHWND()
    if (!currentId){
        logMessage("[mainLoop] Roblox not found. Attempting to reconnect.")
        attemptReconnect()
        return
    } else if (currentId != robloxId){
        logMessage("[mainLoop] New Roblox window found. Switching..")
        OutputDebug, "Window switched"
        robloxId := currentId
    }

    if (checkDisconnect()){
        logMessage("[mainLoop] Roblox disconnected. Attempting to reconnect.")
        attemptReconnect()
        return
    }

    ; Restart Roblox to clear RAM
    if (options.RestartRobloxEnabled && getUnixTime()-options.LastRobloxRestart >= (options.RestartRobloxInterval*60*60)) {
        if (ClearRAM()) {
            return
        }
    }

    WinActivate, ahk_id %robloxId%

    ; Checks to avoid idling
    CloseBSAlerts() ; Prevent infinite Bloxstrap error popups
    
    if (isPlayButtonVisible()) {
        ClickPlay()
    }
	
    enableAutoRoll() ; Check after ClickPlay to make sure not left off due to lag, etc

    ; if (!isFirstScan){
    ;     FindSolsRNGButtons()
    ; }


    ; Equip preferred aura
    if (options.AutoEquipEnabled) {
        EquipAura(options.AutoEquipAura)
        enableAutoRoll()
    }
    
    if (!initialized){
        updateStatus("Initializing")
        initialize()
    }

    mouseActions()
    
    Sleep, 250

    ; Reset to spawn before taking screenshots or using items
    ; reset()
    
    ; Attempt to claim quests every 30 minutes
    if (options.ClaimDailyQuests && !lastClaim || A_TickCount - lastClaim > 1800000) {
        ClaimQuests()
        lastClaim := A_TickCount
    }

    ; Take Screenshots - Aura Storage, Item Inventory, Quests
    if (options.InvScreenshotsEnabled && getUnixTime()-options.LastInvScreenshot >= (options.ScreenshotInterval*60)) {
        options.LastInvScreenshot := getUnixTime()
        screenshotInventories()
    }

    Sleep, 250

    ; Run Item Scheduler entries
    checkItemScheduler()

    Sleep, 250

    if (options.PotionCraftingEnabled){ ; fun fact: || is stand for "or" -> options.PotionCraftingEnabled || options.ItemCraftingEnabled
        if (getUnixTime()-options.LastCraftSession >= (options.CraftingInterval*60)) {
            options.LastCraftSession := getUnixTime()
            stellaCaveCrafting_Eon1()
        }

        ;stellaCaveCrafting_Eon1()
    }

    ; if (options.DoingObby && (A_TickCount - lastObby) >= (obbyCooldown*1000)){
    ;     ; align()

    ;     if (options.IsNikoPath == 1) {
    ;         resetCameraAngle()
    ;     }

    ;     reset()
    ;     Sleep, 700
    ;     obbyRun()

    ;     ; MouseGetPos, mouseX, mouseY
    ;     local TLCornerX, TLCornerY, width, height
    ;     getRobloxPos(TLCornerX, TLCornerY, width, height)
    ;     BRCornerX := TLCornerX + width
    ;     BRCornerY := TLCornerY + height
    ;     statusEffectHeight := Floor((height/1080)*54)

    ;     hasBuff := checkHasObbyBuff(BRCornerX,BRCornerY,statusEffectHeight)
    ;     Sleep, 1000
    ;     hasBuff := hasBuff || checkHasObbyBuff(BRCornerX,BRCornerY,statusEffectHeight)
    ;     if (!hasBuff){
    ;         Sleep, 5000
    ;         hasBuff := hasBuff || checkHasObbyBuff(BRCornerX,BRCornerY,statusEffectHeight)
    ;     }
    ;     if (!hasBuff)
    ;     {
    ;         ; align()
    ;         updateStatus("Obby Failed, Retrying")
    ;         lastObby := A_TickCount - obbyCooldown*1000
    ;         obbyRun()
    ;         hasBuff := checkHasObbyBuff(BRCornerX,BRCornerY,statusEffectHeight)
    ;         Sleep, 1000
    ;         hasBuff := hasBuff || checkHasObbyBuff(BRCornerX,BRCornerY,statusEffectHeight)
    ;         if (!hasBuff){
    ;             Sleep, 5000
    ;             hasBuff := hasBuff || checkHasObbyBuff(BRCornerX,BRCornerY,statusEffectHeight)
    ;         }
    ;         if (!hasBuff){
    ;             lastObby := A_TickCount - obbyCooldown*1000
    ;         }
    ;     }
    ; }


    if (options.CollectItems) {
        resetCameraAngle()
        Sleep, 1500
        searchForItems()
    }

    /*
    ;MouseMove, targetX, targetY
    Gui test1:Color, %color%
    GuiControl,,TestT,% checkHasObbyBuff(BRCornerX,BRCornerY,statusEffectHeight)
    */
}

CreateMainUI() {
    global

; main ui
    try {
        Menu Tray, Icon, % mainDir "images\dSIM.ico" ; Use icon if available
    } catch {
        Menu Tray, Icon, shell32.dll, 3
    }

    Gui mainUI: New, +hWndhGui
    ; Gui Color, 0xDADADA
    Gui Add, Button, gStartClick vStartButton x8 y254 w80 h23 -Tabstop, F1 - Start
    Gui Add, Button, gPauseClick vPauseButton x96 y254 w80 h23 -Tabstop, F2 - Pause
    Gui Add, Button, gStopClick vStopButton x184 y254 w80 h23 -Tabstop, F3 - Stop

    Gui Font, s11 Norm, Segoe UI
    Gui Add, Picture, gDiscordServerClick w26 h20 x495 y254, % mainDir "images\discordIcon.png"

    Gui Add, Tab3, vMainTabs x8 y8 w600 h240, Main|Crafting|Webhook|Settings|Credits|Extras|Merchant

    ; main tab
    Gui Tab, 1

    Gui Font, s10 w600
    Gui Add, GroupBox, x16 y40 w231 h70 vObbyOptionGroup -Theme +0x50000007, Obby
    Gui Font, s9 norm
    Gui Add, CheckBox, vObbyCheckBox x32 y59 w180 h26 +0x2 +Disabled, % " Do Obby (Every 3 Mins)"
    Gui Add, CheckBox, vObbyBuffCheckBox x32 y80 w200 h26 +0x2 +Disabled, % " Check for Obby Buff Effect"
    Gui Add, Button, gObbyHelpClick vObbyHelpButton x221 y50 w23 h23, ?

    Gui Font, s10 w600
    Gui Add, GroupBox, x252 y40 w231 h70 vAutoEquipGroup -Theme +0x50000007, Auto Equip
    Gui Font, s9 norm
    Gui Add, CheckBox, vAutoEquipCheckBox x268 y61 w190 h22 +0x2, % " Enable Auto Equip"
    Gui Add, Button, +gShowAuraEquipSearch x268 y83 w115 h22, Configure Search
    Gui Add, Button, gAutoEquipHelpClick vAutoEquipHelpButton x457 y50 w23 h23, ?

    Gui Font, s10 w600
    Gui Add, GroupBox, x16 y110 w500 h130 vCollectOptionGroup -Theme +0x50000007, Item Collecting
    Gui Font, s9 norm
    Gui Add, CheckBox, vCollectCheckBox x32 y129 w190 h26 +0x2 +BackgroundTrans, % " Collect Items Around Map"
    Gui Add, Button, gCollectHelpClick vCollectHelpButton x457 y128 w23 h23, ?


    Gui Add, Button, gAssignMenuButtonsClick vAssignMenuButtonsButton x230 y129 w100 h30, Assign Menu Buttons

    Gui Add, GroupBox, x26 y175 w447 h48 vCollectSpotsHolder -Theme +0x50000007, Collect From Spots
    Gui Add, CheckBox, vCollectSpot1CheckBox x42 y190 w30 h26 +0x2 -Tabstop, % " 1"
    Gui Add, CheckBox, vCollectSpot2CheckBox x82 y190 w30 h26 +0x2 -Tabstop, % " 2"
    Gui Add, CheckBox, vCollectSpot3CheckBox x122 y190 w30 h26 +0x2 -Tabstop, % " 3"
    Gui Add, CheckBox, vCollectSpot4CheckBox x162 y190 w30 h26 +0x2 -Tabstop, % " 4"
    Gui Add, CheckBox, vCollectSpot5CheckBox x202 y190 w30 h26 +0x2 -Tabstop +Disabled, % " 5"
    Gui Add, CheckBox, vCollectSpot6CheckBox x242 y190 w30 h26 +0x2 -Tabstop +Disabled, % " 6"
    Gui Add, CheckBox, vCollectSpot7CheckBox x282 y190 w30 h26 +0x2 -Tabstop +Disabled, % " 7"
    Gui Add, CheckBox, vCollectSpot8CheckBox x322 y190 w30 h26 +0x2 -Tabstop +Disabled, % " 8*"
    Gui Add, Button, gSpot8HelpClick vSpot8HelpButton x443 y190 w23 h23, ?

    ; crafting tab
    Gui Tab, 2
    Gui Font, s10 w600
    Gui Add, GroupBox, x16 y40 w231 h110 vItemCraftingGroup -Theme +0x50000007, Item Crafting
    Gui Font, s9 norm
    Gui Add, CheckBox, vItemCraftingCheckBox x32 y58 w190 h22 +Disabled, % " Automatic Item Crafting"
    Gui Font, s9 w600
    Gui Add, GroupBox, x21 y80 w221 h65 vItemCraftingOptionsGroup -Theme +0x50000007, Crafting Options

    ; Potion Crafting Settings
    potionSlotOptions := "None||Fortune Potion I|Fortune Potion II|Fortune Potion III|Haste Potion I|Haste Potion II|Haste Potion III|Heavenly Potion I|Heavenly Potion II|Warp Potion"
    Gui Font, s10 w600
    Gui Add, GroupBox, x252 y40 w231 h170 vPotionCraftingGroup -Theme +0x50000007, Potion Crafting
    Gui Font, s9 norm
    Gui Add, CheckBox, vPotionCraftingCheckBox x268 y58 w200 h22 +0x2, % " Automatic Potion Crafting"
    Gui Add, CheckBox, vPotionAutoAddCheckBox x268 y78 w200 h22 +0x2, % " Use Auto Add (Cycles Slots)"
    
    ; Potion Crafting Slots
    Gui Font, s9 w600
    Gui Add, GroupBox, x257 y100 w221 h105 vPotionCraftingSlotsGroup -Theme +0x50000007, Crafting Slots
    Gui Font, s9 norm
    Gui Add, Text, x270 y122 w100 h16 vItemCraftingSlot1Header BackgroundTrans, Slot 1:
    Gui Add, DropDownList, x312 y118 w120 h10 vPotionCraftingSlot1DropDown R9, % potionSlotOptions
    Gui Add, Text, x270 y152 w100 h16 vItemCraftingSlot2Header BackgroundTrans, Slot 2:
    Gui Add, DropDownList, x312 y148 w120 h10 vPotionCraftingSlot2DropDown R9, % potionSlotOptions
    Gui Add, Text, x270 y182 w100 h16 vItemCraftingSlot3Header BackgroundTrans, Slot 3:
    Gui Add, DropDownList, x312 y178 w120 h10 vPotionCraftingSlot3DropDown R9, % potionSlotOptions

    ; Crafting Interval
    Gui Font, s10 w600
    Gui Add, GroupBox, x16 y150 w231 h60 vCraftingIntervalGroup -Theme +0x50000007, Crafting Intervals
    Gui Font, s9 norm

    Gui Add, Text, x32 y170 h35 vCraftingIntervalText BackgroundTrans Section, Craft every
    Gui Add, Edit, ys wp w45 h18 vCraftingIntervalInput Number, 10
    Gui Add, UpDown, vCraftingIntervalUpDown Range1-300, 10
    Gui Add, Text, ys wp w60 h35 BackgroundTrans, minutes

    ; webhook tab
    Gui Tab, 3
    Gui Font, s10 w600
    Gui Add, GroupBox, x16 y40 w130 h170 vStatsGroup -Theme +0x50000007, Stats
    Gui Font, s8 norm
    Gui Add, Text, vStatsDisplay x22 y58 w118 h146, runtime: 123`ndisconnects: 1000

    Gui Font, s10 w600
    Gui Add, GroupBox, x151 y40 w235 h200 vWebhookGroup -Theme +0x50000007, Discord Webhook

    Gui Font, s7.5 norm
    Gui Add, CheckBox, vWebhookCheckBox x166 y63 w120 h16 +0x2 gEnableWebhookToggle, % " Enable Webhook"
    Gui Add, Text, x161 y85 w100 h20 vWebhookInputHeader BackgroundTrans, Webhook URL:
    Gui Add, Edit, x166 y103 w169 h18 vWebhookInput,% ""
    Gui Add, Button, gWebhookHelpClick vWebhookHelpButton x360 y50 w23 h23, ?

    Gui Add, CheckBox, vWebhookImportantOnlyCheckBox x166 y126 w140 h16 +0x2, % " Important events only"
    Gui Add, Text, vWebhookUserIDHeader x161 y145 w150 h14 BackgroundTrans, % "Discord User ID (Pings):"
    Gui Add, Edit, x166 y162 w169 h16 vWebhookUserIDInput,% ""

    ; New field for "Discord User/Role ID Glitch Biome Ping"
    Gui Add, Text, vWebhookGlitchIDHeader x161 y180 w250 h14 BackgroundTrans, % "Discord User/Role ID Glitch Biome Ping:"
    Gui Add, Edit, x166 y195 w169 h16 vWebhookGlitchIDInput,% ""

    Gui Font, s7.4 norm
    Gui Add, CheckBox, vWebhookInventoryScreenshots x166 y218 w130 h15 +0x2, % "Inventory Screenshots (mins)"
    Gui Add, Edit, x299 y218 w50 h18
    Gui Add, UpDown, vInvScreenshotinterval Range1-1440

    Gui Font, s10 w600
    Gui Add, GroupBox, x396 y40 w127 h50 vStatusOtherGroup -Theme +0x50000007, Other
    Gui Font, s9 norm
    Gui Add, CheckBox, vStatusBarCheckBox x406 y63 w110 h20 +0x2, % " Enable Status Bar"

    Gui Font, s9 w600
    Gui Add, GroupBox, x396 y90 w127 h120 vRollDetectionGroup -Theme +0x50000007, Roll Detection
    Gui Font, s8 norm
    Gui Add, Button, gRollDetectionHelpClick vRollDetectionHelpButton x497 y99 w23 h23, ?
    Gui Add, Text, vWebhookRollSendHeader x405 y110 w110 h16 BackgroundTrans, % "Send Minimum:"
    Gui Add, Edit, vWebhookRollSendInput x410 y126 w102 h18, 10000
    Gui Add, Text, vWebhookRollPingHeader x405 y146 w110 h16 BackgroundTrans, % "Ping Minimum:"
    Gui Add, Edit, vWebhookRollPingInput x410 y162 w102 h18, 100000
    Gui Add, CheckBox, vWebhookRollImageCheckBox gWebhookRollImageCheckBoxClick x405 y183 w90 h18, Aura Images
    Gui Add, Picture, gShowAuraSettings vShowAuraSettingsIcon x498 y183 w20 h20, % mainDir "images\settingsIcon.png"

    ; Assign the g-label to the icon/button to show the Aura settings popup
    GuiControl, +gShowAuraSettings, vShowAuraSettingsIcon

    ; settings tab
    Gui Tab, 4
    Gui Font, s10 w600
    Gui Add, GroupBox, x16 y40 w259 h175 vGeneralSettingsGroup -Theme +0x50000007, General
    Gui Font, s9 norm
    Gui Add, CheckBox, vVIPCheckBox x32 y58 w150 h22 +0x2, % " VIP Gamepass Owned"
    Gui Add, CheckBox, vAzertyCheckBox x32 y78 w200 h22 +0x2, % " AZERTY Keyboard Layout"
    Gui Add, CheckBox, vClaimDailyQuestsCheckBox x32 y98 w200 h22 +0x2, % " Auto Claim Daily Quests (30 min)"
    Gui Add, CheckBox, gShifterCheckBoxClick vShifterCheckBox x32 y118 w220 h22 +0x2 +Disabled, % " Abyssal Shifter Mode (Not work atm)"
    Gui Add, Text, x32 y141 w200 h22, % "Collection Back Button Y Offset:" ; increase by 30 to move down
    Gui Add, Edit, x206 y140 w50 h18
    Gui Add, UpDown, vBackOffsetUpDown Range-500-500, 0

    Gui Font, s10 w600
    Gui Add, GroupBox, x320 y40 w203 h138 vReconnectSettingsGroup -Theme +0x50000007, Reconnect
    Gui Font, s9 norm

    ; Reconnect Options
    Gui Add, CheckBox, x336 y61 w150 h16 +0x2 vReconnectCheckBox Section, % " Enable Reconnect"

    ; Restart Roblox
    Gui Add, CheckBox, x336 y81 h16 +0x2 vRestartRobloxCheckBox Section, % " Restart Roblox every"
    Gui Add, Edit, x336 y101 w45 h18 vRestartRobloxIntervalInput Number, 1
    Gui Add, UpDown, vRestartRobloxIntervalUpDown Range1-24, 1
    Gui Add, Text, x390 y102 w130 h16 BackgroundTrans, % "hour(s) (Clears RAM)"

    ; Private Server Link
    Gui Add, Text, x330 y131 w100 h20 vPrivateServerInputHeader BackgroundTrans, Private Server Link:
    Gui Add, Edit, x334 y148 w177 h20 vPrivateServerInput, % ""

    ; Import 
    Gui Add, Button, vImportSettingsButton gImportSettingsClick x357 y186 w130 h20, Import Settings
    
    ; credits tab
    Gui Tab, 5
    Gui Font, s10 w600
    Gui Add, GroupBox, x16 y40 w231 h133 vCreditsGroup -Theme +0x50000007, The Creator
    Gui Add, Picture, w75 h75 x23 y62, % mainDir "images\pfp.png"
    Gui Font, s12 w600
    Gui Add, Text, x110 y57 w130 h22,BuilderDolphin
    Gui Font, s8 norm italic
    Gui Add, Text, x120 y78 w80 h18,(dolphin)
    Gui Font, s8 norm
    Gui Add, Text, x115 y95 w124 h40,"This was supposed to be a short project to learn AHK..."
    Gui Font, s8 norm
    Gui Add, Text, x28 y145 w200 h32 BackgroundTrans,% "More to come soon perhaps..."
    Gui Add, Button, x28 y177 w206 h32 gMoreCreditsClick,% "More Credits"

    Gui Font, s10 w600
    Gui Add, GroupBox, x282 y40 w231 h90 vCreditsGroup2 -Theme +0x50000007, dSIM Credits
    Gui Add, Picture, w60 h60 x289 y62, % mainDir "images\noteab.ico" ; noteab insert your pfp - ok sir
    Gui Font, s8 norm
    Gui Add, Text, x356 y59 w150 h68,% "Noteab and Steve are the main contributors.`nCurious Pengu just does stuff" ; change this all you like

    Gui Font, s10 w600
    Gui Add, GroupBox, x282 y130 w231 h80 vCreditsGroup3 -Theme +0x50000007, Other
    Gui Font, s9 norm
    Gui Add, Link, x298 y150 w200 h55, Join the <a href="https://discord.gg/DYUqwJchuV">Discord Server</a>! (Community)`n`nVisit the <a href="https://github.com/noteab/dolphSol-Improvement-Macro">GitHub</a>! (Updates + Versions)

    ; extras tab
    Gui Tab, 6
    Gui Font, s10 w600

    ; General
    Gui Add, GroupBox, x16 y40 w467 h43 vGeneralEnhancementsGroup -Theme +0x50000007, General
    Gui Font, s9 norm
    Gui Add, CheckBox, gOCREnabledCheckBoxClick vOCREnabledCheckBox x32 y57 w400 h22 +0x2 Section, % " Enable OCR for Self-Correction (Requires English-US PC Language)"
    Gui Add, Button, gOCRHelpClick vOCRHelpButton x457 y50 w23 h23, ?

    Gui Add, Button, gShowBiomeSettings vBiomeButton x350 y95 w128, Configure Biomes
    Gui Add, Button, gShowItemSchedulerSettings vSchedulerGUIButton x350 y+5 w128, Item Scheduler

    Gui Add, Button, gUIHelpClick vUIHelpButton x430 y220 w100 h23, How can I tell?

    ; Roblox UI style to determine Chat button position
    Gui Font, s10 w600
    Gui Add, Text, x450 y160, Roblox UI
    Gui Font, s9 norm

    ; options["RobloxUpdatedUI"]
    Gui Add, Radio, AltSubmit gGetRobloxVersion vRobloxUpdatedUIRadio1 x470 y180, Old
    Gui Add, Radio, AltSubmit gGetRobloxVersion vRobloxUpdatedUIRadio2, New
    GuiControl,, RobloxUpdatedUIRadio1, % (options["RobloxUpdatedUI"] = 1) ? 1 : 0
    GuiControl,, RobloxUpdatedUIRadio2, % (options["RobloxUpdatedUI"] = 2) ? 1 : 0

    ; Record Aura
    Gui Font, s10 w600
    Gui Add, GroupBox, x16 y83 w328 h67 vRecordAuraGroup -Theme +0x50000007, Record Aura
    Gui Font, s9 norm
    Gui Add, CheckBox, vRecordAuraCheckBox x32 y100 w260 h22 +0x2 Section, % " Record Aura Rolls using Xbox Game Bar"
    Gui Add, Button, gRecordAuraHelp vRecordAuraHelpButton x318 y93 w23 h23, ?
    Gui Add, Text, vRecordAuraMinimumHeader x25 y123 w110 h16 BackgroundTrans, % "Record Minimum:"
    Gui Add, Edit, vRecordAuraMinimumInput x135 y123 w200 h18, 100000

    ; Window Title
    Gui Show, % "w545 h294 x" clamp(options.WindowX,10,A_ScreenWidth-100) " y" clamp(options.WindowY,10,A_ScreenHeight-100), % "dolphSol's Improvement Macro " version
    
    ; Merchant tab (Mari and Jester!!)
    Gui, Tab, 7
    Gui Font, s9 norm

    ; Enable/Disable Auto-Merchant
    Gui, Add, CheckBox, vAutoMerchantBooleanBox gAutoMerchantReminder x25 y115 w145 BackgroundTrans, Enable Auto Merchant
    Gui Add, Button, gAutoMerchantHelp vAutoMerchantHelpTrigger x170 y112 w23 h23, ?
    
    Gui Add, Button, gMerchantSettings vMerchantSettingsClick x25 y145 w140 h25, Merchant Calibrations
    Gui Add, Button, gMerchant_WebhooksGui vWebhookMerchantSettingsClick x25 y180 w140 h25, Merchant Webhooks

    ; Mari's GroupBox and Item Selection
    Gui Font, s10 w600
    Gui, Add, GroupBox, x16 y35 w255 h65 vMariGroup -Theme +0x50000007, Mari
    Gui Font, s9 norm
    Gui Add, Button, gMariMerchantSettings vMariMerchantSettingsClick x25 y59 w140 h25, Mari Item Settings

    ; Jester's GroupBox and Item Selection
    Gui Font, s10 w600
    Gui, Add, GroupBox, x285 y35 w255 h105 vJesterGroup -Theme +0x50000007, Jester
    Gui Font, s9 norm
    Gui Add, Button, gJesterMerchantSettings vJesterMerchantSettingsClick x294 y59 w140 h25, Jester Item Settings
    Gui Add, Button, gJester_Exchange_GUI vJesterExchangeClick x294 y100 w140 h25 BackgroundTrans +Disabled, Item Exchange (Jester)
    Gui, Add, CheckBox, vJesterExchangeBooleanBox x483 y105 w30 BackgroundTrans +Disabled
    Gui Add, Text, vJesterExchangeBooleanReminder x440 y105 w110 h16 BackgroundTrans +Disabled, Enable:
    

    ; status bar
    Gui statusBar:New, +AlwaysOnTop -Caption
    Gui Font, s10 norm
    Gui Add, Text, x5 y5 w210 h15 vStatusBarText, Status: Waiting...

    Gui mainUI:Default
}
CreateMainUI()

global currentPage := 1

AssignMenuButtonsClick() {
    global currentPage, options
    global AuraStorageX, AuraStorageY, RegularAuraTabX, RegularAuraTabY
    global SpecialAuraTabX, SpecialAuraTabY, AuraSearchBarX, AuraSearchBarY
    global FirstAuraSlotX, FirstAuraSlotY, EquipButtonX, EquipButtonY
    global CollectionMenuX, CollectionMenuY, CollectionExitButtonX, CollectionExitButtonY
    global InventoryMenuX, InventoryMenuY, ItemsTabX, ItemsTabY
    global SearchBarX, SearchBarY, FirstItemSlotX, FirstItemSlotY
    global AmountBoxX, AmountBoxY, UseButtonX, UseButtonY
    global QuestMenuX, QuestMenuY, DailyTabX, DailyTabY
    global FirstQuestSlotX, FirstQuestSlotY, ClaimButtonX, ClaimButtonY
    global PotionSearchBarX, PotionSearchBarY, FirstPotionSlotX, FirstPotionSlotY
    global CraftButtonX, CraftButtonY, AutoButtonX, AutoButtonY
    global 1_potion_manual_x, 1_potion_manual_y, 2_potion_manual_x, 2_potion_manual_y
    global 3_potion_manual_x, 3_potion_manual_y, 4_potion_manual_x, 4_potion_manual_y 
    global 5_potion_manual_x, 5_potion_manual_y, 6_potion_manual_x, 6_potion_manual_y
    global AssignButton1, AssignButton2, AssignButton3, AssignButton4
    global AssignButton5, AssignButton6, AssignButton7, AssignButton8
    global AssignButton9, AssignButton10, AssignButton11, AssignButton12
    global AssignButton13, AssignButton14, AssignButton15, AssignButton16
    global AssignButton17, AssignButton18, AssignButton19, AssignButton20
    global AssignButton21, AssignButton22, AssignButton23, AssignButton24
    global AssignButton25, AssignButton26, AssignButton27, AssignButton28

    Gui, AssignMenuButtons:New, +AlwaysOnTop, Assign Menu Buttons

    if (currentPage = 1) {
        ; Page 1: Aura Equip
        Gui, Add, GroupBox, x10 y10 w320 h240, Aura Equip
        Gui, Add, Text, x20 y30, Aura Storage:
        Gui, Add, Edit, x120 y28 w60 vAuraStorageX, % options["AuraStorageX"]
        Gui, Add, Edit, x190 y28 w60 vAuraStorageY, % options["AuraStorageY"]
        Gui, Add, Button, x260 y28 w50 h20 gAssignClick vAssignButton1, Assign

        Gui, Add, Text, x20 y60, Regular Aura Tab:
        Gui, Add, Edit, x120 y58 w60 vRegularAuraTabX, % options["RegularAuraTabX"]
        Gui, Add, Edit, x190 y58 w60 vRegularAuraTabY, % options["RegularAuraTabY"]
        Gui, Add, Button, x260 y58 w50 h20 gAssignClick vAssignButton2, Assign

        Gui, Add, Text, x20 y90, Special Aura Tab:
        Gui, Add, Edit, x120 y88 w60 vSpecialAuraTabX, % options["SpecialAuraTabX"]
        Gui, Add, Edit, x190 y88 w60 vSpecialAuraTabY, % options["SpecialAuraTabY"]
        Gui, Add, Button, x260 y88 w50 h20 gAssignClick vAssignButton3, Assign

        Gui, Add, Text, x20 y120, Aura Search Bar:
        Gui, Add, Edit, x120 y118 w60 vAuraSearchBarX, % options["AuraSearchBarX"]
        Gui, Add, Edit, x190 y118 w60 vAuraSearchBarY, % options["AuraSearchBarY"]
        Gui, Add, Button, x260 y118 w50 h20 gAssignClick vAssignButton4, Assign

        Gui, Add, Text, x20 y150, First Aura Slot:
        Gui, Add, Edit, x120 y148 w60 vFirstAuraSlotX, % options["FirstAuraSlotX"]
        Gui, Add, Edit, x190 y148 w60 vFirstAuraSlotY, % options["FirstAuraSlotY"]
        Gui, Add, Button, x260 y148 w50 h20 gAssignClick vAssignButton5, Assign

        Gui, Add, Text, x20 y180, Equip Button:
        Gui, Add, Edit, x120 y178 w60 vEquipButtonX, % options["EquipButtonX"]
        Gui, Add, Edit, x190 y178 w60 vEquipButtonY, % options["EquipButtonY"]
        Gui, Add, Button, x260 y178 w50 h20 gAssignClick vAssignButton6, Assign

        Gui, Add, Button, x10 y260 w100 h30 gNextPage, Next
    } else if (currentPage = 2) {
        ; Page 2: Alignment
        Gui, Add, GroupBox, x10 y10 w320 h140, Alignment
        Gui, Add, Text, x20 y30, Collection Menu:
        Gui, Add, Edit, x120 y28 w60 vCollectionMenuX, % options["CollectionMenuX"]
        Gui, Add, Edit, x190 y28 w60 vCollectionMenuY, % options["CollectionMenuY"]
        Gui, Add, Button, x260 y28 w50 h20 gAssignClick vAssignButton7, Assign

        Gui, Add, Text, x20 y60, Collection Exit Button:
        Gui, Add, Edit, x120 y58 w60 vCollectionExitButtonX, % options["CollectionExitButtonX"]
        Gui, Add, Edit, x190 y58 w60 vCollectionExitButtonY, % options["CollectionExitButtonY"]
        Gui, Add, Button, x260 y58 w50 h20 gAssignClick vAssignButton8, Assign

        Gui, Add, Button, x10 y160 w100 h30 gPreviousPage, Previous
        Gui, Add, Button, x120 y160 w100 h30 gNextPage, Next
    } else if (currentPage = 3) {
        ; Page 3: Inventory
        Gui, Add, GroupBox, x10 y10 w320 h240, Inventory
        Gui, Add, Text, x20 y30, Inventory Menu:
        Gui, Add, Edit, x120 y28 w60 vInventoryMenuX, % options["InventoryMenuX"]
        Gui, Add, Edit, x190 y28 w60 vInventoryMenuY, % options["InventoryMenuY"]
        Gui, Add, Button, x260 y28 w50 h20 gAssignClick vAssignButton9, Assign

        Gui, Add, Text, x20 y60, Items Tab:
        Gui, Add, Edit, x120 y58 w60 vItemsTabX, % options["ItemsTabX"]
        Gui, Add, Edit, x190 y58 w60 vItemsTabY, % options["ItemsTabY"]
        Gui, Add, Button, x260 y58 w50 h20 gAssignClick vAssignButton10, Assign

        Gui, Add, Text, x20 y90, Search Bar:
        Gui, Add, Edit, x120 y88 w60 vSearchBarX, % options["SearchBarX"]
        Gui, Add, Edit, x190 y88 w60 vSearchBarY, % options["SearchBarY"]
        Gui, Add, Button, x260 y88 w50 h20 gAssignClick vAssignButton11, Assign

        Gui, Add, Text, x20 y120, First Item Slot:
        Gui, Add, Edit, x120 y118 w60 vFirstItemSlotX, % options["FirstItemSlotX"]
        Gui, Add, Edit, x190 y118 w60 vFirstItemSlotY, % options["FirstItemSlotY"]
        Gui, Add, Button, x260 y118 w50 h20 gAssignClick vAssignButton12, Assign

        Gui, Add, Text, x20 y150, Amount Box:
        Gui, Add, Edit, x120 y148 w60 vAmountBoxX, % options["AmountBoxX"]
        Gui, Add, Edit, x190 y148 w60 vAmountBoxY, % options["AmountBoxY"]
        Gui, Add, Button, x260 y148 w50 h20 gAssignClick vAssignButton13, Assign

        Gui, Add, Text, x20 y180, Use Button:
        Gui, Add, Edit, x120 y178 w60 vUseButtonX, % options["UseButtonX"]
        Gui, Add, Edit, x190 y178 w60 vUseButtonY, % options["UseButtonY"]
        Gui, Add, Button, x260 y178 w50 h20 gAssignClick vAssignButton14, Assign

        Gui, Add, Button, x10 y260 w100 h30 gPreviousPage, Previous
        Gui, Add, Button, x120 y260 w100 h30 gNextPage, Next
    } else if (currentPage = 4) {
        ; Page 4: Quest
        Gui, Add, GroupBox, x10 y10 w320 h240, Quest
        Gui, Add, Text, x20 y30, Quest Menu:
        Gui, Add, Edit, x120 y28 w60 vQuestMenuX, % options["QuestMenuX"]
        Gui, Add, Edit, x190 y28 w60 vQuestMenuY, % options["QuestMenuY"]
        Gui, Add, Button, x260 y28 w50 h20 gAssignClick vAssignButton15, Assign

        Gui, Add, Text, x20 y60, Daily Tab:
        Gui, Add, Edit, x120 y58 w60 vDailyTabX, % options["DailyTabX"]
        Gui, Add, Edit, x190 y58 w60 vDailyTabY, % options["DailyTabY"]
        Gui, Add, Button, x260 y58 w50 h20 gAssignClick vAssignButton16, Assign

        Gui, Add, Text, x20 y90, First Quest Slot:
        Gui, Add, Edit, x120 y88 w60 vFirstQuestSlotX, % options["FirstQuestSlotX"]
        Gui, Add, Edit, x190 y88 w60 vFirstQuestSlotY, % options["FirstQuestSlotY"]
        Gui, Add, Button, x260 y88 w50 h20 gAssignClick vAssignButton17, Assign

        Gui, Add, Text, x20 y120, Claim Button:
        Gui, Add, Edit, x120 y118 w60 vClaimButtonX, % options["ClaimButtonX"]
        Gui, Add, Edit, x190 y118 w60 vClaimButtonY, % options["ClaimButtonY"]
        Gui, Add, Button, x260 y118 w50 h20 gAssignClick vAssignButton18, Assign

        Gui, Add, Button, x10 y260 w100 h30 gPreviousPage, Previous
        Gui, Add, Button, x120 y260 w100 h30 gNextPage, Next
    } else if (currentPage = 5) {
        ; Page 5: Potion Crafting
        Gui, Add, GroupBox, x10 y10 w320 h240, Potion Crafting

        Gui, Add, Text, x20 y60, Potion Search Bar:
        Gui, Add, Edit, x120 y58 w60 vPotionSearchBarX, % options["PotionSearchBarX"]
        Gui, Add, Edit, x190 y58 w60 vPotionSearchBarY, % options["PotionSearchBarY"]
        Gui, Add, Button, x260 y58 w50 h20 gAssignClick vAssignButton19, Assign

        Gui, Add, Text, x20 y90, First Potion Slot:
        Gui, Add, Edit, x120 y88 w60 vFirstPotionSlotX, % options["FirstPotionSlotX"]
        Gui, Add, Edit, x190 y88 w60 vFirstPotionSlotY, % options["FirstPotionSlotY"]
        Gui, Add, Button, x260 y88 w50 h20 gAssignClick vAssignButton20, Assign

        Gui, Add, Text, x20 y120, Craft Button:
        Gui, Add, Edit, x120 y118 w60 vCraftButtonX, % options["CraftButtonX"]
        Gui, Add, Edit, x190 y118 w60 vCraftButtonY, % options["CraftButtonY"]
        Gui, Add, Button, x260 y118 w50 h20 gAssignClick vAssignButton21, Assign

        Gui, Add, Text, x20 y150, Auto Button:
        Gui, Add, Edit, x120 y148 w60 vAutoButtonX, % options["AutoButtonX"]
        Gui, Add, Edit, x190 y148 w60 vAutoButtonY, % options["AutoButtonY"]
        Gui, Add, Button, x260 y148 w50 h20 gAssignClick vAssignButton22, Assign

        Gui, Add, Button, x10 y260 w100 h30 gPreviousPage, Previous
        Gui, Add, Button, x120 y260 w100 h30 gNextPage, Next

    } else if (currentPage = 6) {
        ; Page 6: Potion Manual Item Click
        Gui, Add, GroupBox, x10 y10 w335 h240, Potion Manual Add

        Gui, Add, Text, x20 y60, #1 manual aura add box:
        Gui, Add, Edit, x150 y58 w60 v1_potion_manual_x, % options["1_potion_manual_x"]
        Gui, Add, Edit, x220 y58 w60 v1_potion_manual_y, % options["1_potion_manual_y"]
        Gui, Add, Button, x290 y58 w50 h20 gAssignClick vAssignButton23, Assign

        Gui, Add, Text, x20 y90, #2 manual aura add box:
        Gui, Add, Edit, x150 y88 w60 v2_potion_manual_x, % options["2_potion_manual_x"]
        Gui, Add, Edit, x220 y88 w60 v2_potion_manual_y, % options["2_potion_manual_y"]
        Gui, Add, Button, x290 y88 w50 h20 gAssignClick vAssignButton24, Assign

        Gui, Add, Text, x20 y120, #3 manual aura add box:
        Gui, Add, Edit, x150 y118 w60 v3_potion_manual_x, % options["3_potion_manual_x"]
        Gui, Add, Edit, x220 y118 w60 v3_potion_manual_y, % options["3_potion_manual_y"]
        Gui, Add, Button, x290 y118 w50 h20 gAssignClick vAssignButton25, Assign

        Gui, Add, Text, x20 y150, #4 manual aura add box:
        Gui, Add, Edit, x150 y148 w60 v4_potion_manual_x, % options["4_potion_manual_x"]
        Gui, Add, Edit, x220 y148 w60 v4_potion_manual_y, % options["4_potion_manual_y"]
        Gui, Add, Button, x290 y148 w50 h20 gAssignClick vAssignButton26, Assign

        Gui, Add, Text, x20 y180, #5 manual aura add box:
        Gui, Add, Edit, x150 y178 w60 v5_potion_manual_x, % options["5_potion_manual_x"]
        Gui, Add, Edit, x220 y178 w60 v5_potion_manual_y, % options["5_potion_manual_y"]
        Gui, Add, Button, x290 y178 w50 h20 gAssignClick vAssignButton27, Assign

        Gui, Add, Text, x20 y210, #6 manual aura add box:
        Gui, Add, Edit, x150 y208 w60 v6_potion_manual_x, % options["6_potion_manual_x"]
        Gui, Add, Edit, x220 y208 w60 v6_potion_manual_y, % options["6_potion_manual_y"]
        Gui, Add, Button, x290 y208 w50 h20 gAssignClick vAssignButton28, Assign

        Gui, Add, Button, x10 y260 w100 h30 gPreviousPage, Previous
    }

    Gui, Show, w350 h320, Assign Sol's Menu
}


NextPage() {
    global currentPage
    currentPage++
    if (currentPage > 6) {
        currentPage := 1
    }
    Gui, Destroy
    AssignMenuButtonsClick()
}

PreviousPage() {
    global currentPage
    currentPage--
    if (currentPage < 1) {
        currentPage := 6
    }
    Gui, Destroy
    AssignMenuButtonsClick()
}

AssignClick() {
    global configPath, options, configHeader

    Control := A_GuiControl

    startDim(1, "Click to assign position!")

    ; Wait for the user to click the left mouse button
    KeyWait, LButton, D
    MouseGetPos, mouseX, mouseY
    removeDim()

    controlMap := { "AssignButton1": ["AuraStorageX", "AuraStorageY"]
                  , "AssignButton2": ["RegularAuraTabX", "RegularAuraTabY"]
                  , "AssignButton3": ["SpecialAuraTabX", "SpecialAuraTabY"]
                  , "AssignButton4": ["AuraSearchBarX", "AuraSearchBarY"]
                  , "AssignButton5": ["FirstAuraSlotX", "FirstAuraSlotY"]
                  , "AssignButton6": ["EquipButtonX", "EquipButtonY"]
                  , "AssignButton7": ["CollectionMenuX", "CollectionMenuY"]
                  , "AssignButton8": ["CollectionExitButtonX", "CollectionExitButtonY"]
                  , "AssignButton9": ["InventoryMenuX", "InventoryMenuY"]
                  , "AssignButton10": ["ItemsTabX", "ItemsTabY"]
                  , "AssignButton11": ["SearchBarX", "SearchBarY"]
                  , "AssignButton12": ["FirstItemSlotX", "FirstItemSlotY"]
                  , "AssignButton13": ["AmountBoxX", "AmountBoxY"]
                  , "AssignButton14": ["UseButtonX", "UseButtonY"]
                  , "AssignButton15": ["QuestMenuX", "QuestMenuY"]
                  , "AssignButton16": ["DailyTabX", "DailyTabY"]
                  , "AssignButton17": ["FirstQuestSlotX", "FirstQuestSlotY"]
                  , "AssignButton18": ["ClaimButtonX", "ClaimButtonY"]
                  , "AssignButton19": ["PotionSearchBarX", "PotionSearchBarY"]
                  , "AssignButton20": ["FirstPotionSlotX", "FirstPotionSlotY"]
                  , "AssignButton21": ["CraftButtonX", "CraftButtonY"]
                  , "AssignButton22": ["AutoButtonX", "AutoButtonY"]
                  , "AssignButton23": ["1_potion_manual_x", "1_potion_manual_y"]
                  , "AssignButton24": ["2_potion_manual_x", "2_potion_manual_y"]
                  , "AssignButton25": ["3_potion_manual_x", "3_potion_manual_y"]
                  , "AssignButton26": ["4_potion_manual_x", "4_potion_manual_y"]
                  , "AssignButton27": ["5_potion_manual_x", "5_potion_manual_y"]
                  , "AssignButton28": ["6_potion_manual_x", "6_potion_manual_y"]}

    if (controlMap.HasKey(Control)) {
        keys := controlMap[Control]
        options[keys[1]] := mouseX
        options[keys[2]] := mouseY
        
        saveOptions()
        
        Gui, AssignMenuButtons:Default

        keyX := keys[1]
        keyY := keys[2]

        GuiControl,, %keyX%, %mouseX%
        GuiControl,, %keyY%, %mouseY%
    }
}


; // MERCHANT SECTION \\ ;

global JesterExchangeOptions := "None||Curruptaine||Eternal Flame||Piece of Star||Rainy Bottle||NULL||Wind Essence||Icicle"

Jester_Exchange_GUI() {
    global
    Gui, JesterGUI:New, +AlwaysOnTop +LabelJesterUI
    Gui Font, s10 w600

    Gui Font, s9 norm
    Gui Add, Text, x25 y8 w100 h16 BackgroundTrans, Exchange Item:

    Gui Add, Text, x25 y38 w100 h16 BackgroundTrans, Item 1:
    Gui Add, DropDownList, x65 y35 w120 h20 vJesterItem1DropDown R9, % JesterExchangeOptions
    GuiControl, Choose, JesterItem1DropDown, % (options["Jester_Exchange_ItemSlot1"] ? options["Jester_Exchange_ItemSlot1"] : "None")

    Gui Add, Text, x25 y68 w100 h16 BackgroundTrans, Item 2:
    Gui Add, DropDownList, x65 y65 w120 h20 vJesterItem2DropDown R9, % JesterExchangeOptions
    GuiControl, Choose, JesterItem2DropDown, % (options["Jester_Exchange_ItemSlot2"] ? options["Jester_Exchange_ItemSlot2"] : "None")

    Gui Add, Text, x25 y98 w100 h16 BackgroundTrans, Item 3:
    Gui Add, DropDownList, x65 y95 w120 h20 vJesterItem3DropDown R9, % JesterExchangeOptions
    GuiControl, Choose, JesterItem3DropDown, % (options["Jester_Exchange_ItemSlot3"] ? options["Jester_Exchange_ItemSlot3"] : "None")

    Gui Add, Text, x25 y128 w100 h16 BackgroundTrans, Item 4:
    Gui Add, DropDownList, x65 y125 w120 h20 vJesterItem4DropDown R9, % JesterExchangeOptions
    GuiControl, Choose, JesterItem4DropDown, % (options["Jester_Exchange_ItemSlot4"] ? options["Jester_Exchange_ItemSlot4"] : "None")

    Gui Add, Text, x25 y158 w100 h16 BackgroundTrans, Item 5:
    Gui Add, DropDownList, x65 y155 w120 h20 vJesterItem5DropDown R9, % JesterExchangeOptions
    GuiControl, Choose, JesterItem5DropDown, % (options["Jester_Exchange_ItemSlot5"] ? options["Jester_Exchange_ItemSlot5"] : "None")

    Gui Add, Text, x25 y188 w100 h16 BackgroundTrans, Item 6:
    Gui Add, DropDownList, x65 y185 w120 h20 vJesterItem6DropDown R9, % JesterExchangeOptions
    GuiControl, Choose, JesterItem6DropDown, % (options["Jester_Exchange_ItemSlot6"] ? options["Jester_Exchange_ItemSlot6"] : "None")

    Gui Add, Text, x25 y218 w100 h16 BackgroundTrans, Item 7:
    Gui Add, DropDownList, x65 y215 w120 h20 vJesterItem7DropDown R9, % JesterExchangeOptions
    GuiControl, Choose, JesterItem7DropDown, % (options["Jester_Exchange_ItemSlot7"] ? options["Jester_Exchange_ItemSlot7"] : "None")

    Gui Add, Text, x25 y248 w100 h16 BackgroundTrans, Item 8:
    Gui Add, DropDownList, x65 y245 w120 h20 vJesterItem8DropDown R9, % JesterExchangeOptions
    GuiControl, Choose, JesterItem8DropDown, % (options["Jester_Exchange_ItemSlot8"] ? options["Jester_Exchange_ItemSlot8"] : "None")

    ; Jester Exchange Button
    Gui, Add, Text, x200 y38 w250, Jester Pink Exchange Button (X, Y):
    Gui, Add, Edit, x200 y58 w50 vJesterExchangeButtonX, % options["Jester_Exchange_Button_X"]
    Gui, Add, UpDown, vJesterExchangeButtonX_UpDown Range0-7000, % options["Jester_Exchange_Button_X"]
    Gui, Add, Edit, x260 y58 w50 vJesterExchangeButtonY, % options["Jester_Exchange_Button_Y"]
    Gui, Add, UpDown, vJesterExchangeButtonY_UpDown Range0-7000, % options["Jester_Exchange_Button_Y"]
    Gui, Add, Button, x320 y58 w80 h20 gJester_ExchangeSelectPosition vSelectButton8, Select Pos

    ; Jester Item Search Bar
    Gui, Add, Text, x200 y88 w250, Jester Item Search Bar (X, Y):
    Gui, Add, Edit, x200 y108 w50 vJesterItemSearchBarX, % options["Jester_Item_Search_Bar_X"]
    Gui, Add, UpDown, vJesterItemSearchBarX_UpDown Range0-7000, % options["Jester_Item_Search_Bar_X"]
    Gui, Add, Edit, x260 y108 w50 vJesterItemSearchBarY, % options["Jester_Item_Search_Bar_Y"]
    Gui, Add, UpDown, vJesterItemSearchBarY_UpDown Range0-7000, % options["Jester_Item_Search_Bar_Y"]
    Gui, Add, Button, x320 y108 w80 h20 gJester_ExchangeSelectPosition vSelectButton9, Select Pos

    ; Jester First Exchange Item Slot
    Gui, Add, Text, x200 y138 w250, Jester First Exchange Item Slot (X, Y):
    Gui, Add, Edit, x200 y158 w50 vJesterFirstExchangeSlotX, % options["Jester_First_Item_Exchange_Slot_X"]
    Gui, Add, UpDown, vFirstItemExchangeSlotX_UpDown Range0-7000, % options["Jester_First_Item_Exchange_Slot_X"]
    Gui, Add, Edit, x260 y158 w50 vJesterFirstExchangeSlotY, % options["Jester_First_Item_Exchange_Slot_Y"]
    Gui, Add, UpDown, vFirstItemExchangeSlotY_UpDown Range0-7000, % options["Jester_First_Item_Exchange_Slot_Y"]
    Gui, Add, Button, x320 y158 w80 h20 gJester_ExchangeSelectPosition vSelectButton10, Select Pos

    ; custom exchange amounts
    Gui, Add, Text, x200 y188 w250, Exchange step amount (Example: 120,40,15,5...):
    Gui, Add, Edit, x200 y208 w150 vCustomAmounts, % options["Jester_Custom_Exchange_Amounts"]


    Gui, Add, Button, x200 y250 w200 h25 gJester_ExchangeItemHighlight, Highlight Jester Click
    Gui, Add, Button, x200 y280 w200 h25 gJester_Exchange_Save_Calibration, Save Calibration
    
    Gui Show, w450 h340, Jester Item Exchange
}

MerchantSettings() {
    global
    Gui, MerchantSettings:New, +AlwaysOnTop +LabelMerchantGui
    Gui Color, 0xDADADA
    Gui Font, s9 norm
    Gui, Add, Text, x16 y10 w300 h30, More merchant features coming soon weee!
    Gui, Add, Text, x16 y25 w300 h30, (Press F9 to show mouse x,y position)


    ; Merchant Open Button
    Gui, Add, Text, x16 y50 w250, Merchant Open Button (X, Y):
    Gui, Add, Edit, x16 y70 w50 vMerchantOpenButtonX, % options["Merchant_Open_Button_X"]
    Gui, Add, UpDown, vOpenButtonX_UpDown Range0-7000, % options["Merchant_Open_Button_X"]
    Gui, Add, Edit, x70 y70 w50 vMerchantOpenButtonY, % options["Merchant_Open_Button_Y"]
    Gui, Add, UpDown, vOpenButtonY_UpDown Range0-7000, % options["Merchant_Open_Button_Y"]
    Gui, Add, Button, x130 y70 w80 h20 gSelectPosition vSelectButton4, Select Pos

    ; Purchase Amount Button
    Gui, Add, Text, x16 y100 w250, Purchase Amount Button (X, Y):
    Gui, Add, Edit, x16 y120 w50 vMerchantPurchaseAmountX, % options["Merchant_Purchase_Amount_X"]
    Gui, Add, UpDown, vPurchaseAmountX_UpDown Range0-4000, % options["Merchant_Purchase_Amount_X"]
    Gui, Add, Edit, x70 y120 w50 vMerchantPurchaseAmountY, % options["Merchant_Purchase_Amount_Y"]
    Gui, Add, UpDown, vPurchaseAmountY_UpDown Range0-4000, % options["Merchant_Purchase_Amount_Y"]
    Gui, Add, Button, x130 y120 w80 h20 gSelectPosition vSelectButton2, Select Pos

    ; Purchase Button
    Gui, Add, Text, x16 y150 w250, Purchase Button (X, Y):
    Gui, Add, Edit, x16 y170 w50 vMerchantPurchaseButtonX, % options["Merchant_Purchase_Button_X"]
    Gui, Add, UpDown, vPurchaseButtonX_UpDown Range0-7000, % options["Merchant_Purchase_Button_X"]
    Gui, Add, Edit, x70 y170 w50 vMerchantPurchaseButtonY, % options["Merchant_Purchase_Button_Y"]
    Gui, Add, UpDown, vPurchaseButtonY_UpDown Range0-7000, % options["Merchant_Purchase_Button_Y"]
    Gui, Add, Button, x130 y170 w80 h20 gSelectPosition vSelectButton3, Select Pos

    
    ; Username OCR Position
    Gui, Add, Text, x16 y200 w250, Merchant Name OCR Position (X, Y, W, H):
    Gui, Add, Edit, x16 y220 w50 vMerchantUsernameOCRX, % options["Merchant_Username_OCR_X"]
    Gui, Add, UpDown, vUsernameOCRX_UpDown Range0-7000, % options["Merchant_Username_OCR_X"]
    Gui, Add, Edit, x70 y220 w50 vMerchantUsernameOCRY, % options["Merchant_Username_OCR_Y"]
    Gui, Add, UpDown, vUsernameOCRY_UpDown Range0-7000, % options["Merchant_Username_OCR_Y"]
    Gui, Add, Edit, x130 y220 w50 vMerchantUsernameOCRW, % options["Merchant_Username_OCR_W"]
    Gui, Add, UpDown, vUsernameOCRW_UpDown Range0-7000, % options["Merchant_Username_OCR_W"]
    Gui, Add, Edit, x190 y220 w50 vMerchantUsernameOCRH, % options["Merchant_Username_OCR_H"]
    Gui, Add, UpDown, vUsernameOCRH_UpDown Range0-7000, % options["Merchant_Username_OCR_H"]
    Gui, Add, Button, x250 y220 w80 h20 gSelectPosition vSelectButton5, Select Pos

    ; Item Name OCR Position
    Gui, Add, Text, x16 y250 w250, Item Name OCR Position (X, Y, W, H):
    Gui, Add, Edit, x16 y270 w50 vMerchantItemNameOCRX, % options["Merchant_ItemName_OCR_X"]
    Gui, Add, UpDown, vItemNameOCRX_UpDown Range0-7000, % options["Merchant_ItemName_OCR_X"]
    Gui, Add, Edit, x70 y270 w50 vMerchantItemNameOCRY, % options["Merchant_ItemName_OCR_Y"]
    Gui, Add, UpDown, vItemNameOCRY_UpDown Range0-7000, % options["Merchant_ItemName_OCR_Y"]
    Gui, Add, Edit, x130 y270 w50 vMerchantItemNameOCRW, % options["Merchant_ItemName_OCR_W"]
    Gui, Add, UpDown, vItemNameOCRW_UpDown Range0-7000, % options["Merchant_ItemName_OCR_W"]
    Gui, Add, Edit, x190 y270 w50 vMerchantItemNameOCRH, % options["Merchant_ItemName_OCR_H"]
    Gui, Add, UpDown, vItemNameOCRH_UpDown Range0-7000, % options["Merchant_ItemName_OCR_H"]
    Gui, Add, Button, x250 y270 w80 h20 gSelectPosition vSelectButton6, Select Pos

    ; First Item Slot Position
    Gui, Add, Text, x16 y300 w250, First Item Slot Position (X, Y):
    Gui, Add, Edit, x16 y320 w50 vMerchantFirstItemPosX, % options["Merchant_FirstItem_Pos_X"]
    Gui, Add, UpDown, vFirstItemPosX_UpDown Range0-7000, % options["Merchant_FirstItem_Pos_X"]
    Gui, Add, Edit, x70 y320 w50 vMerchantFirstItemPosY, % options["Merchant_FirstItem_Pos_Y"]
    Gui, Add, UpDown, vFirstItemPosY_UpDown Range0-7000, % options["Merchant_FirstItem_Pos_Y"]
    Gui, Add, Button, x130 y320 w80 h20 gSelectPosition vSelectButton7, Select Pos

    ; Help text and button moved above
    Gui, Add, Text, vMerchantCalibrationHelpPls x16 y350 w250 h25 BackgroundTrans, Got trouble at calibration? Click this help button
    Gui, Add, Button, gMerchantCalibrationHelp vMerchantCalibrationHelpTrigger x245 y346 w23 h23, ?

    ; Highlight merchant click region button
    Gui, Add, Button, x50 y390 w200 h25 gMerchant_ItemHighlight, Highlight Merchant Click
    Gui, Add, Button, x50 y420 w200 h25 gSave_Merchant_Calibration, Save Calibration

    Gui, Show, , Merchant Calibration
    Gui MerchantSettings:Default
}

MariMerchantSettings() {
    global
    Gui, MariMerchantSettings:New, +AlwaysOnTop
    Gui Color, 0xDADADA

    Gui Font, s9 norm
    Gui Add, Text, x10 y10 w100 h15 BackgroundTrans, % "Item Name"
    Gui Add, Text, x190 y10 w50 h15 BackgroundTrans, % "Amount:"

    for i, itemName in MariItemsArray {
        v := merchant_ItemOptions["Mari_ItemSlot" . i]
        values := SplitNumbers(v)

        checkBoxState := (values[2] = "True") ? 1 : 0
        amount := values[3]

        if (!amount || amount = "") {
            amount := 1
        }

        yValue := i * 30
        Gui Add, CheckBox, vMariSlot%i%Item x10 y%yValue% w180, %itemName%
        GuiControl, , MariSlot%i%Item, % checkBoxState
        Gui Add, Edit, vMariSlot%i%Amount x200 y%yValue% w30 h20, %amount%
    }

    yValue := (MariItemsArray.MaxIndex() + 1) * 30
    Gui Add, Button, gMariMerchantSettingsSave x10 y%yValue% w220 h25, Save Selections

    Gui, Show, w250, Mari Items
}



MariMerchantSettingsSave() {
    Gui, MariMerchantSettings:Default
    global merchant_ItemOptions

    for i, itemName in MariItemsArray {
        itemControl := "MariSlot" . i . "Item"
        amountControl := "MariSlot" . i . "Amount"

        GuiControlGet, MariSlotItem, , %itemControl% ; checkbox
        GuiControlGet, MariSlotAmount, , %amountControl%

        shortItemName := RegExReplace(itemName, "\s*\(.*\)")

        ; config formatto: ItemName, True/False (checkbox thing), Amount
        checkBoxState := (MariSlotItem = 1) ? "True" : "False"
        merchant_ItemOptions["Mari_ItemSlot" . i] := shortItemName . "," . checkBoxState . "," . MariSlotAmount
    }

    Save_Merchant_ItemSettings()
}


JesterMerchantSettings() {
    global
    Gui, JesterMerchantSettings:New, +AlwaysOnTop
    Gui Color, 0xDADADA

    Gui Font, s9 norm
    Gui Add, Text, x10 y10 w100 h15 BackgroundTrans, % "Item Name"
    Gui Add, Text, x195 y10 w50 h15 BackgroundTrans, % "Amount:"

    for i, itemName in JesterItemsArray {
        v := merchant_ItemOptions["Jester_ItemSlot" . i]
        values := SplitNumbers(v)

        checkBoxState := (values[2] = "True") ? 1 : 0
        amount := values[3]

        if (!amount || amount = "") {
            amount := 1
        }

        yValue := i * 30
        Gui Add, CheckBox, vJesterSlot%i%Item x10 y%yValue% w180, %itemName%
        GuiControl, , JesterSlot%i%Item, % checkBoxState
        Gui Add, Edit, vJesterSlot%i%Amount x200 y%yValue% w30 h20, %amount%
    }

    yValue := (JesterItemsArray.MaxIndex() + 1) * 30
    Gui Add, Button, gJesterMerchantSettingsSave x10 y%yValue% w220 h25, Save Selections

    Gui, Show, w250, Jester Items
}


JesterMerchantSettingsSave() {
    Gui, JesterMerchantSettings:Default
    global merchant_ItemOptions

    for i, itemName in JesterItemsArray {
        itemControl := "JesterSlot" . i . "Item"
        amountControl := "JesterSlot" . i . "Amount"

        GuiControlGet, JesterSlotItem, , %itemControl% ; checkbox
        GuiControlGet, JesterSlotAmount, , %amountControl%

        shortItemName := RegExReplace(itemName, "\s*\(.*\)")

        ; Format: ItemName,True/False,Amount
        checkBoxState := (JesterSlotItem = 1) ? "True" : "False"
        merchant_ItemOptions["Jester_ItemSlot" . i] := shortItemName . "," . checkBoxState . "," . JesterSlotAmount
    }

    Save_Merchant_ItemSettings()
}

SplitNumbers(inputString) {
    StringSplit, numbers, inputString, `,

    result := []

    Loop, % numbers0
    {
        num := numbers%A_Index%
        result.Push(num)
    }

    return result
}

AutoMerchantReminder() {
    Gui mainUI:Default
    GuiControlGet, isChecked,, AutoMerchantBooleanBox
    if (isChecked){
        MsgBox, 0, Auto Merchant Reminder, % "Please turn off Shift Lock before starting auto merchant feature! So your mouse wont be get locked to center and cannot press merchant open button! Also make sure you have the 'Merchant Teleporter' added in Item Scheduler in Extras Tab!"
    }
    return
}

Save_Merchant_Calibration() {
    Gui MerchantSettings:Default
    global options

    screenWidth := A_ScreenWidth
    screenHeight := A_ScreenHeight

    GuiControlGet, SliderX_UpDown
    GuiControlGet, SliderY_UpDown
    GuiControlGet, PurchaseAmountX_UpDown
    GuiControlGet, PurchaseAmountY_UpDown
    GuiControlGet, PurchaseButtonX_UpDown
    GuiControlGet, PurchaseButtonY_UpDown
    GuiControlGet, OpenButtonX_UpDown
    GuiControlGet, OpenButtonY_UpDown
    GuiControlGet, UsernameOCRX_UpDown
    GuiControlGet, UsernameOCRY_UpDown
    GuiControlGet, ItemNameOCRX_UpDown
    GuiControlGet, ItemNameOCRY_UpDown
    GuiControlGet, FirstItemPosX_UpDown
    GuiControlGet, FirstItemPosY_UpDown
    GuiControlGet, JesterExchangeButtonX_UpDown
    GuiControlGet, JesterExchangeButtonY_UpDown
    GuiControlGet, JesterItemSearchBarX_UpDown
    GuiControlGet, JesterItemSearchBarY_UpDown
    GuiControlGet, FirstItemExchangeSlotX_UpDown
    GuiControlGet, FirstItemExchangeSlotY_UpDown

    options["Merchant_slider_X"] := SliderX_UpDown
    options["Merchant_slider_Y"] := SliderY_UpDown
    options["Merchant_Purchase_Amount_X"] := PurchaseAmountX_UpDown
    options["Merchant_Purchase_Amount_Y"] := PurchaseAmountY_UpDown
    options["Merchant_Purchase_Button_X"] := PurchaseButtonX_UpDown
    options["Merchant_Purchase_Button_Y"] := PurchaseButtonY_UpDown
    options["Merchant_Open_Button_X"] := OpenButtonX_UpDown
    options["Merchant_Open_Button_Y"] := OpenButtonY_UpDown
    options["Merchant_Username_OCR_X"] := UsernameOCRX_UpDown
    options["Merchant_Username_OCR_Y"] := UsernameOCRY_UpDown
    options["Merchant_ItemName_OCR_X"] := ItemNameOCRX_UpDown
    options["Merchant_ItemName_OCR_Y"] := ItemNameOCRY_UpDown
    options["Merchant_FirstItem_Pos_X"] := FirstItemPosX_UpDown
    options["Merchant_FirstItem_Pos_Y"] := FirstItemPosY_UpDown

    saveOptions()
}

Jester_Exchange_Save_Calibration() {
    Gui JesterGUI:Default
    global options
    
    GuiControlGet, JesterExchangeButtonX_UpDown
    GuiControlGet, JesterExchangeButtonY_UpDown
    GuiControlGet, JesterItemSearchBarX_UpDown
    GuiControlGet, JesterItemSearchBarY_UpDown
    GuiControlGet, FirstItemExchangeSlotX_UpDown
    GuiControlGet, FirstItemExchangeSlotY_UpDown

    options["Jester_Exchange_Button_X"] := JesterExchangeButtonX_UpDown
    options["Jester_Exchange_Button_Y"] := JesterExchangeButtonY_UpDown
    options["Jester_Item_Search_Bar_X"] := JesterItemSearchBarX_UpDown
    options["Jester_Item_Search_Bar_Y"] := JesterItemSearchBarY_UpDown
    options["Jester_First_Item_Exchange_Slot_X"] := FirstItemExchangeSlotX_UpDown
    options["Jester_First_Item_Exchange_Slot_Y"] := FirstItemExchangeSlotY_UpDown

    saveOptions()
}

SelectPosition() {
    global options
    Gui, MerchantSettings:Submit, NoHide
    startDim(1, "Click to select merchant position")

    Control := A_GuiControl

    if (Control = "SelectButton5" || Control = "SelectButton6") {
        KeyWait, LButton, D
        MouseGetPos, startX, startY

        Gui, Snip:New, +AlwaysOnTop -Caption +E0x20
        Gui, Color, FFFFFF
        Gui, +LastFound +AlwaysOnTop -Caption +ToolWindow
        WinSet, Transparent, 100


        Gui, Show, x%startX% y%startY% w1 h1, Snip

        Loop {
            MouseGetPos, currentX, currentY
            width := Abs(currentX - startX)
            height := Abs(currentY - startY)
            x := Min(startX, currentX)
            y := Min(startY, currentY)
            Gui, Snip:Show, x%x% y%y% w%width% h%height%
            Sleep, 10
            GetKeyState, state, LButton, P
            if (state = "U")
                break
        }

        Gui, Snip:Hide
        Gui, Snip:Destroy
        removeDim()

        width := Abs(currentX - startX)
        height := Abs(currentY - startY)

        x := Min(startX, currentX)
        y := Min(startY, currentY)

        if (Control = "SelectButton5") {
            options["Merchant_Username_OCR_X"] := x
            options["Merchant_Username_OCR_Y"] := y
            options["Merchant_Username_OCR_W"] := width
            options["Merchant_Username_OCR_H"] := height

            GuiControl, MerchantSettings:, MerchantUsernameOCRX, %x%
            GuiControl, MerchantSettings:, MerchantUsernameOCRY, %y%
            GuiControl, MerchantSettings:, MerchantUsernameOCRW, %width%
            GuiControl, MerchantSettings:, MerchantUsernameOCRH, %height%
        } else {
            options["Merchant_ItemName_OCR_X"] := x
            options["Merchant_ItemName_OCR_Y"] := y
            options["Merchant_ItemName_OCR_W"] := width
            options["Merchant_ItemName_OCR_H"] := height

            GuiControl, MerchantSettings:, MerchantItemNameOCRX, %x%
            GuiControl, MerchantSettings:, MerchantItemNameOCRY, %y%
            GuiControl, MerchantSettings:, MerchantItemNameOCRW, %width%
            GuiControl, MerchantSettings:, MerchantItemNameOCRH, %height%
        }

        Highlight(x, y, width, height, 6500, "blue")
    }
    else {
        KeyWait, LButton, D
        MouseGetPos, mouseX, mouseY

        removeDim()

        if (Control = "SelectButton1") {
            GuiControl,MerchantSettings:, MerchantSliderX, %mouseX%
            GuiControl,MerchantSettings:, SliderX_UpDown, %mouseX%
            GuiControl,MerchantSettings:, MerchantSliderY, %mouseY%
            GuiControl,MerchantSettings:, SliderY_UpDown, %mouseY%
            options["Merchant_slider_X"] := mouseX
            options["Merchant_slider_Y"] := mouseY
            Highlight(mouseX, mouseY, 10, 10, 6500)
        }
        else if (Control = "SelectButton2") {
            GuiControl,MerchantSettings:, MerchantPurchaseAmountX, %mouseX%
            GuiControl,MerchantSettings:, PurchaseAmountX_UpDown, %mouseX%
            GuiControl,MerchantSettings:, MerchantPurchaseAmountY, %mouseY%
            GuiControl,MerchantSettings:, PurchaseAmountY_UpDown, %mouseY%
            options["Merchant_Purchase_Amount_X"] := mouseX
            options["Merchant_Purchase_Amount_Y"] := mouseY
            Highlight(mouseX-5, mouseY-5, 10, 10, 6500, "lime")
        }
        else if (Control = "SelectButton3") {
            GuiControl,MerchantSettings:, MerchantPurchaseButtonX, %mouseX%
            GuiControl,MerchantSettings:, PurchaseButtonX_UpDown, %mouseX%
            GuiControl,MerchantSettings:, MerchantPurchaseButtonY, %mouseY%
            GuiControl,MerchantSettings:, PurchaseButtonY_UpDown, %mouseY%
            options["Merchant_Purchase_Button_X"] := mouseX
            options["Merchant_Purchase_Button_Y"] := mouseY
            Highlight(mouseX-5, mouseY-5, 10, 10, 6500, "lime")
        }
        else if (Control = "SelectButton4") {
            GuiControl,MerchantSettings:, MerchantOpenButtonX, %mouseX%
            GuiControl,MerchantSettings:, OpenButtonX_UpDown, %mouseX%
            GuiControl,MerchantSettings:, MerchantOpenButtonY, %mouseY%
            GuiControl,MerchantSettings:, OpenButtonY_UpDown, %mouseY%
            options["Merchant_Open_Button_X"] := mouseX
            options["Merchant_Open_Button_Y"] := mouseY
            Highlight(mouseX, mouseY, 10, 10, 6500)
        }
        else if (Control = "SelectButton7") {
            GuiControl,MerchantSettings:, MerchantFirstItemPosX, %mouseX%
            GuiControl,MerchantSettings:, FirstItemPosX_UpDown, %mouseX%
            GuiControl,MerchantSettings:, MerchantFirstItemPosY, %mouseY%
            GuiControl,MerchantSettings:, FirstItemPosY_UpDown, %mouseY%
            options["Merchant_FirstItem_Pos_X"] := mouseX
            options["Merchant_FirstItem_Pos_Y"] := mouseY
            Highlight(mouseX-5, mouseY-5, 10, 10, 6500, "Yellow")
            Highlight(mouseX+180, mouseY-5, 10, 10, 6500, "Yellow")
        }
    }
}

Jester_ExchangeSelectPosition() {
    global options
    Gui, JesterGUI:Submit, NoHide
    startDim(1, "Click to select merchant position")
    
    KeyWait, LButton, D
    MouseGetPos, mouseX, mouseY
    removeDim()

    Control := A_GuiControl

    if (Control = "SelectButton8") {
        GuiControl,JesterGUI:, JesterExchangeButtonX, %mouseX%
        GuiControl,JesterGUI:, JesterExchangeButtonX_UpDown, %mouseX%
        GuiControl,JesterGUI:, JesterExchangeButtonY, %mouseY%
        GuiControl,JesterGUI:, JesterExchangeButtonY_UpDown, %mouseY%
        options["Jester_Exchange_Button_X"] := mouseX
        options["Jester_Exchange_Button_Y"] := mouseY
        Highlight(mouseX, mouseY, 10, 10, 6500, "Aqua")
        Highlight(mouseX, mouseY, 10, 10, 6500, "Aqua")
    }

    else if (Control = "SelectButton9") {
        GuiControl,JesterGUI:, JesterItemSearchBarX, %mouseX%
        GuiControl,JesterGUI:, JesterItemSearchBarX_UpDown, %mouseX%
        GuiControl,JesterGUI:, JesterItemSearchBarY, %mouseY%
        GuiControl,JesterGUI:, JesterItemSearchBarY_UpDown, %mouseY%
        options["Jester_Item_Search_Bar_X"] := mouseX
        options["Jester_Item_Search_Bar_Y"] := mouseY
        Highlight(mouseX, mouseY, 10, 10, 6500, "Fuchsia")
        Highlight(mouseX, mouseY, 10, 10, 6500, "Fuchsia")
    }

    else if (Control = "SelectButton10") {
        GuiControl,JesterGUI:, JesterFirstExchangeSlotX, %mouseX%
        GuiControl,JesterGUI:, FirstItemExchangeSlotX_UpDown, %mouseX%
        GuiControl,JesterGUI:, JesterFirstExchangeSlotY, %mouseY%
        GuiControl,JesterGUI:, FirstItemExchangeSlotY_UpDown, %mouseY%
        options["Jester_First_Item_Exchange_Slot_X"] := mouseX
        options["Jester_First_Item_Exchange_Slot_Y"] := mouseY
        Highlight(mouseX, mouseY, 10, 10, 6500, "Lime")
        Highlight(mouseX, mouseY, 10, 10, 6500, "Lime")
    }
}


Merchant_ItemHighlight() {
    global options

    ; Get current screen resolution
    screenWidth := A_ScreenWidth
    screenHeight := A_ScreenHeight

    ; Get positions for various elements
    GuiControlGet, SliderX_UpDown
    GuiControlGet, SliderY_UpDown
    GuiControlGet, PurchaseAmountX_UpDown
    GuiControlGet, PurchaseAmountY_UpDown
    GuiControlGet, PurchaseButtonX_UpDown
    GuiControlGet, PurchaseButtonY_UpDown
    GuiControlGet, OpenButtonX_UpDown
    GuiControlGet, OpenButtonY_UpDown
    GuiControlGet, UsernameOCRX_UpDown
    GuiControlGet, UsernameOCRY_UpDown
    GuiControlGet, UsernameOCRW_UpDown
    GuiControlGet, UsernameOCRH_UpDown
    
    GuiControlGet, ItemNameOCRX_UpDown
    GuiControlGet, ItemNameOCRY_UpDown
    GuiControlGet, ItemNameOCRW_UpDown
    GuiControlGet, ItemNameOCRH_UpDown
    GuiControlGet, FirstItemPosX_UpDown
    GuiControlGet, FirstItemPosY_UpDown

    ; Jester exchange thingie
    GuiControlGet, JesterExchangeButtonX_UpDown
    GuiControlGet, JesterExchangeButtonY_UpDown
    GuiControlGet, JesterItemSearchBarX_UpDown
    GuiControlGet, JesterItemSearchBarY_UpDown
    GuiControlGet, FirstItemExchangeSlotX_UpDown
    GuiControlGet, FirstItemExchangeSlotY_UpDown

    secondItemX := FirstItemPosX_UpDown + 185 

    ; Draw highlights with tooltips
    Highlight(SliderX_UpDown-5, SliderY_UpDown-5, 10, 10, 8500) ; merchant slider box
    Highlight(PurchaseAmountX_UpDown-5, PurchaseAmountY_UpDown-5, 10, 10, 8500, "lime") ; purchase amount pos
    Highlight(PurchaseButtonX_UpDown-5, PurchaseButtonY_UpDown-5, 10, 10, 8500, "lime") ; purchase button po
    Highlight(OpenButtonX_UpDown, OpenButtonY_UpDown, 10, 10, 8500) ; merchant open button
    Highlight(UsernameOCRX_UpDown, UsernameOCRY_UpDown, UsernameOCRW_UpDown, UsernameOCRH_UpDown, 8500, "blue") ; merchant username ocr
    Highlight(ItemNameOCRX_UpDown, ItemNameOCRY_UpDown, ItemNameOCRW_UpDown, ItemNameOCRH_UpDown, 8500) ; merchant on-sale item name ocr

    ; Highlight first and second item slots
    Highlight(FirstItemPosX_UpDown-5, FirstItemPosY_UpDown-5, 10, 10, 8500, "Yellow") ; first item name slot
    Highlight(secondItemX-5, FirstItemPosY_UpDown-5, 10, 10, 8500, "Yellow") ; second item slot
}


Jester_ExchangeItemHighlight() {
    global options
    ; Jester exchange thingie
    GuiControlGet, JesterExchangeButtonX_UpDown
    GuiControlGet, JesterExchangeButtonY_UpDown
    GuiControlGet, JesterItemSearchBarX_UpDown
    GuiControlGet, JesterItemSearchBarY_UpDown
    GuiControlGet, FirstItemExchangeSlotX_UpDown
    GuiControlGet, FirstItemExchangeSlotY_UpDown

    ; Jester Item Exchange stuff
    Highlight(JesterExchangeButtonX_UpDown, JesterExchangeButtonY_UpDown, 10, 10, 8500, "Aqua")
    Highlight(JesterItemSearchBarX_UpDown, JesterItemSearchBarY_UpDown, 10, 10, 8500, "Fuchsia")

    ; first item exchange slot
    Highlight(FirstItemExchangeSlotX_UpDown, FirstItemExchangeSlotY_UpDown, 10, 10, 8500, "Lime")
}


; Merchant_WebhooksGui() {
;     global options, NewWebhookAlias, NewWebhookURL, NewPingUserID, NewMerchantPrivateServerLink, WebhookList, NewJesterPingUserID
    
;     Gui, MerchantWebhooksSettings:New, +AlwaysOnTop +LabelWebhooksGui
;     Gui Color, 0xDADADA
;     Gui Font, s9 norm

;     ; Title
;     Gui, Add, Text, x16 y10 w300 h30, ==Merchant Webhook== (only 1 webhook supported, more webhook ping will be avail soon)
    
;     ; New Webhook Section
;     Gui, Add, Text, x16 y40 w250, Webhook Alias (e.g., Mari or Jester omg real??! or any silly name you want):
;     Gui, Add, Edit, x16 y70 w250 vNewWebhookAlias, % options.MerchantWebhookAlias

;     Gui, Add, Text, x16 y100 w250, Webhook URL:
;     Gui, Add, Edit, x16 y120 w250 r1 vNewWebhookURL, % options.MerchantWebhookLink

;     Gui, Add, Text, x16 y150 w250, Ping Mari User ID/Role ID (Optional):
;     Gui, Add, Edit, x16 y170 w250 vNewPingUserID, % options.MerchantWebhook_Mari_UserID

;     Gui, Add, Text, x16 y200 w250, Ping Jester User ID/Role ID (Optional):
;     Gui, Add, Edit, x16 y220 w250 vNewJesterPingUserID, % options.MerchantWebhook_Jester_UserID

;     Gui, Add, Text, x16 y250 w250, Merchant Private Server Link (Optional):
;     Gui, Add, Edit, x16 y270 w250 r1 vNewMerchantPrivateServerLink, % options.MerchantWebhook_PS_Link ; Use the ps_link variable here

;     Gui, Add, Button, x16 y320 w120 h30 gMerchant_AddWebhook, Add Webhook

;     Gui, Add, Button, x220 y295 w95 h25 gMari_PingTest, Mari Ping (Test)
;     Gui, Add, Button, x220 y323 w95 h25 gJester_PingTest, Jester Ping (Test)

;     ; Existing Webhooks Section
;     Gui, Add, ListBox, x16 y350 w300 h150 vWebhookList, % Merchant_ListWebhooks()

;     ; Add Delete Webhook Button
;     Gui, Add, Button, x16 y520 w120 h30 gMerchant_DeleteWebhook, Delete Webhook
    
;     GuiControl,, NewMerchantPrivateServerLink, %mouseY%
;     Gui, Show, , Discord Webhooks
; }

; Merchant_AddWebhook() {
;     global options, NewWebhookAlias, NewWebhookURL, NewPingUserID, NewMerchantPrivateServerLink, NewJesterPingUserID

;     Gui, Submit, NoHide
;     ; Validate the webhook URL
;     if (!validateWebhookLink(NewWebhookURL)) {
;         MsgBox, Invalid webhook URL! Please input a valid Discord webhook URL.
;         return
;     }

;     GuiControlGet, Merchant_PS,, NewMerchantPrivateServerLink
;     ; Update the options with new values
;     options.MerchantWebhookAlias := NewWebhookAlias
;     options.MerchantWebhookLink := NewWebhookURL
;     options.MerchantWebhook_Mari_UserID := NewPingUserID
;     options.MerchantWebhook_Jester_UserID := NewJesterPingUserID
;     options.MerchantWebhook_PS_Link := Merchant_PS

;     ; Update ListBox with the new webhook (limit to one webhook)
;     GuiControl,, WebhookList, % NewWebhookAlias " | " NewWebhookURL
    
;     ; Clear the input fields after submission
;     GuiControl,, NewWebhookURL
;     GuiControl,, NewPingUserID
;     GuiControl,, NewJesterPingUserID
;     GuiControl,, NewMerchantPrivateServerLink
; }

; Merchant_DeleteWebhook() {
;     global options

;     options.MerchantWebhookAlias := ""
;     options.MerchantWebhookLink := ""
;     options.MerchantWebhook_Mari_UserID := ""
;     options.MerchantWebhook_Jester_UserID := ""
;     options.MerchantWebhook_PS_Link := ""

;     ; Clear the ListBox
;     GuiControl,, WebhookList,
; }

; Merchant_ListWebhooks() {
;     global options
;     output := ""
;     if (options.MerchantWebhookAlias != "") {
;         output := options.MerchantWebhookAlias " | " options.MerchantWebhookLink
;     }
;     return output
; }


; Mari_PingTest() {
;     Sleep, 1500
;     Merchant_Webhook_Main("Mari", options["MerchantWebhookLink"], options["MerchantWebhook_PS_Link"], options["MerchantWebhook_Mari_UserID"], "Merchant Face Screenshot (PING TEST)")
;     Merchant_Webhook_Main("Mari", options["MerchantWebhookLink"], , , "Item Screenshot (PING TEST)")
; }

; Jester_PingTest() {
;     Sleep, 1500
;     Merchant_Webhook_Main("Jester", options["MerchantWebhookLink"], options["MerchantWebhook_PS_Link"], options["MerchantWebhook_Jester_UserID"], "Merchant Face Screenshot (PING TEST)")
;     Merchant_Webhook_Main("Jester", options["MerchantWebhookLink"], , , "Item Screenshot (PING TEST)")
; }


; // MERCHANT SECTION \\ ;


; Create the Aura settings popup
ShowAuraSettings() {
    global ; Needed for GUI variables
    Gui, AuraSettings:New, +AlwaysOnTop +LabelAuraGui
    Gui Font, s10 w600
    Gui Add, Text, x16 y10 w300 h30, Aura Webhook Toggles
    Gui Font, s9 norm
    Gui Add, Text, x16 y30 w300 h30, Uncheck to disable Discord notification

    ; Calculate the number of items per column
    itemsPerColumn := Ceil(auraNames.Length() / 2.0)

    ; Initialize position variables
    local startXPos := 16
    local startYPos := 50
    local xPos := startXPos
    local yPos := startYPos
    local columnCounter := 0
    local columnWidth := 240

    ; Sort names
    sortedNames := {}
    for k, v in auraNames
        sortedNames[v] := v
    auraNames := sortedNames

    ; Create checkboxes for each aura
    for _, auraName in auraNames {
        ; Convert the aura name to a valid variable name
        sAuraName := RegExReplace(auraName, "[^a-zA-Z0-9]+", "_") ; Replace with underscore
        sAuraName := RegExReplace(sAuraName, "\_$", "") ; Remove any trailing underscore

        try {
            ; outputDebug, % "Adding checkbox for " auraName " (" sAuraName ") at x" xPos ", y" yPos
            Gui Add, CheckBox, % "v" sAuraName "CheckBox x" xPos " y" yPos " w220 h20 +0x2 Checked"options["wh" . sAuraName], % auraName
        } catch e {
            logMessage("[ShowAuraSettings] Error adding checkbox for " auraName "(" sAuraName ") : " e.Message)
        }
        yPos += 25
        columnCounter += 1

        ; Adjust if more than one column is needed
        if (columnCounter >= itemsPerColumn) {
            columnCounter := 0
            xPos += columnWidth  ; Move to the next column
            yPos := startYPos
        }
    }
    Gui Show, % "w500", Aura Settings
}

ShowAuraEquipSearch() {
    global
    Gui, AuraSearch:New, +AlwaysOnTop +LabelAuraSearchGui
    Gui Font, s11 w300
    Gui Add, Text, x16 y10 w300 h50, % "Enter aura name to be used for search.`nThe first result will be equipped so be specific."
    
    Gui Add, CheckBox, vSearchSpecialAurasCheckBox x200 y148 w300 h22, % "Search in Special Auras"
    GuiControl,, SearchSpecialAurasCheckBox, % options.SearchSpecialAuras

    defaultAura := options.AutoEquipAura ? options.AutoEquipAura : "Quartz"
    Gui Add, Edit, vAuraNameInput x8 y110 w382 h22, % defaultAura

    Gui Add, Button, gSubmitAuraName x32 y144 w100 h30, Submit

    Gui Show, % "w400 h190 x" clamp(options.WindowX,10,A_ScreenWidth-100) " y" clamp(options.WindowY,10,A_ScreenHeight-100), % "Auto Equip Aura"
}

applyAuraSettings() {
    global auraNames, options

    Gui AuraSettings:Default  ; Ensure we are in the context of AuraSettings GUI

    ; Save aura settings with prefix
    for _, auraName in auraNames {
        sAuraName := RegExReplace(auraName, "[^a-zA-Z0-9]+", "_") ; Replace all non-alphanumeric characters with underscore
        sAuraName := RegExReplace(sAuraName, "\_$", "") ; Remove any trailing underscore
        
        GuiControlGet, rValue,, %sAuraName%CheckBox
        options["wh" . sAuraName] := rValue
        ; logMessage("[applyAuraSettings] Updating Aura Setting: " auraName " - " sAuraName " - " options["wh" . sAuraName])
    }
}

; Create the Biome settings popup
ShowBiomeSettings() {
    global ; Needed for GUI variables
    Gui, BiomeSettings:New, +AlwaysOnTop +LabelBiomeGui
    Gui Color, 0xDADADA
    Gui Font, s10 w600
    Gui Add, Text, x16 y10 w300 h30, Biome Alerts
    Gui Font, s9 norm
    Gui Add, Text, x16 y30 w300 h30, % "Message = Discord Message`n       Ping = Message + Ping User/Role"
    Gui Add, Button, x232 y7 w150 h25 gSnipBiomeOCR, Snip Biome OCR Region
    Gui Add, Button, x232 y37 w150 h25 gHighlightBiomeRegion, Highlight Biome Region

    col := 1
    colW := 40 ; Spacing between name and dropdown (Biome in first column are mostly shorter)
    yPos := 75

    For i, biome in biomes {
        if (i = 5) {
            ; Start a new column
            col := 2
            colW := 60
            yPos := 75
        }

        xPos := (col = 1) ? 16 : 175

        Gui Add, Text, Section x%xPos% y%yPos% w%colW% h20, % biome ":"
        Gui Add, DropDownList, % "x+m ys-2 w80 h20 R3 v" biome "DropDown", None||Message|Ping
        GuiControl, ChooseString, %biome%DropDown, % options["Biome" . biome]

        yPos += 25
    }

    Gui Show, , Biome Settings
}

SnipBiomeOCR() {
    global options
    startDim(1, "Drag left mouse to select the Biome OCR region")

    KeyWait, LButton, D
    MouseGetPos, startX, startY

    Gui, BiomeSnip:New, +AlwaysOnTop -Caption +E0x20
    Gui, Color, FFFFFF
    Gui, +LastFound +AlwaysOnTop -Caption +ToolWindow
    WinSet, Transparent, 100

    Gui, Show, x%startX% y%startY% w1 h1, BiomeSnip

    Loop {
        MouseGetPos, currentX, currentY
        width := Abs(currentX - startX)
        height := Abs(currentY - startY)
        x := Min(startX, currentX)
        y := Min(startY, currentY)
        Gui, BiomeSnip:Show, x%x% y%y% w%width% h%height%
        Sleep, 10
        GetKeyState, state, LButton, P
        if (state = "U")
            break
    }

    Gui, BiomeSnip:Hide
    Gui, BiomeSnip:Destroy
    removeDim()

    width := Abs(currentX - startX)
    height := Abs(currentY - startY)

    x := Min(startX, currentX)
    y := Min(startY, currentY)

    options["Biome_OCR_X"] := x
    options["Biome_OCR_Y"] := y
    options["Biome_OCR_W"] := width
    options["Biome_OCR_H"] := height

    saveOptions()

    Highlight(x, y, width, height, 3500, "blue")
}

HighlightBiomeRegion() {
    global options
    Highlight(options["Biome_OCR_X"], options["Biome_OCR_Y"], options["Biome_OCR_W"], options["Biome_OCR_H"], 4568, "blue")
}

applyBiomeSettings() {
    global biomes, options

    Gui BiomeSettings:Default  ; Ensure we are in the context of the correct GUI

    ; Save settings with prefix
    for index, biome in biomes {
        GuiControlGet, rValue,, %biome%DropDown
        options["Biome" . biome] := rValue
        ; logMessage("[applyBiomeSettings] Updating Biome Setting: " biome " - " options["Biome" . biome])
    }
}

global directValues := {"ObbyCheckBox":"DoingObby"
    ,"AzertyCheckBox":"AzertyLayout"
    ,"ObbyBuffCheckBox":"CheckObbyBuff"
    ,"CollectCheckBox":"CollectItems"
    ,"VIPCheckBox":"VIP"
    ,"BackOffsetUpDown":"BackOffset"
    ,"AutoEquipCheckBox":"AutoEquipEnabled"
    ,"CraftingIntervalUpDown":"CraftingInterval"
    ,"ItemCraftingCheckBox":"ItemCraftingEnabled"
    ,"InvScreenshotinterval":"ScreenshotInterval"
    ,"PotionCraftingCheckBox":"PotionCraftingEnabled"
    ,"PotionAutoAddCheckBox":"PotionAutoAddEnabled"
    ,"PotionAutoAddIntervalUpDown":"PotionAutoAddInterval"
    ,"ReconnectCheckBox":"ReconnectEnabled"
    ,"RestartRobloxCheckBox":"RestartRobloxEnabled"
    ,"RestartRobloxIntervalUpDown":"RestartRobloxInterval"
    ,"WebhookCheckBox":"WebhookEnabled"
    ,"WebhookInput":"WebhookLink"
    ,"WebhookImportantOnlyCheckBox":"WebhookImportantOnly"
    ,"WebhookRollImageCheckBox":"WebhookAuraRollImages"
    ,"WebhookUserIDInput":"DiscordUserID"
    ,"WebhookGlitchIDInput":"DiscordGlitchID"
    ,"WebhookInventoryScreenshots":"InvScreenshotsEnabled"
    ,"StatusBarCheckBox":"StatusBarEnabled"
    ,"ClaimDailyQuestsCheckBox":"ClaimDailyQuests"
    ,"OCREnabledCheckBox":"OCREnabled"
    ,"ShifterCheckBox":"Shifter"
    ,"RecordAuraCheckBox":"RecordAura" ; Curious Pengu
    ,"AutoMerchantBooleanBox": "AutoMerchantEnabled"
    ,"JesterExchangeBooleanBox": "JesterExchangeEnabled"
    ,"ScanLoopAttemptsUpDownInterval": "ScanLoopInterval" ; Noteab
    ,"StorageYPosScanInterval":"StorageButtonYPosScanVALUE" ; Noteab
    ,"StorageYOffsetInterval": "StorageYOffsetIntervalVALUE"
    ,"MariSlot1Amount": "Mari_Amount_1"
    ,"MariSlot2Amount": "Mari_Amount_2" 
    ,"MariSlot3Amount": "Mari_Amount_3"
    ,"JesterSlot1Amount": "Jester_Amount_1"
    ,"JesterSlot2Amount": "Jester_Amount_2"
    ,"JesterSlot3Amount": "Jester_Amount_3"} ; Noteab

global directNumValues := {"WebhookRollSendInput":"WebhookRollSendMinimum"
    ,"WebhookRollPingInput":"WebhookRollPingMinimum", "RecordAuraMinimumInput":"RecordAuraMinimum"}
updateUIOptions(){
    for i,v in directValues {
        GuiControl,,%i%,% options[v]
    }

    for i,v in directNumValues {
        GuiControl,,%i%,% options[v]
    }

    if (options.PrivateServerId){
        GuiControl,, PrivateServerInput,% privateServerPre options.PrivateServerId
    } else {
        GuiControl,, PrivateServerInput,% ""
    }

    Loop 8 {
        v := options["ItemSpot" . A_Index]
        GuiControl,,CollectSpot%A_Index%CheckBox,%v%
    }

    Loop 3 {
        v := options["PotionCraftingSlot" . A_Index]
        GuiControl,ChooseString,PotionCraftingSlot%A_Index%DropDown,% potionIndex[v]
    }
}
updateUIOptions()

validateWebhookLink(link){
    return RegexMatch(link, "i)https:\/\/(canary\.|ptb\.)?(discord|discordapp)\.com\/api\/webhooks\/([\d]+)\/([a-z0-9_-]+)") ; filter by natro
}

applyNewUIOptions(){
    global hGui
    Gui mainUI:Default

    VarSetCapacity(wp, 44), NumPut(44, wp)
    DllCall("GetWindowPlacement", "uint", hGUI, "uint", &wp)
	x := NumGet(wp, 28, "int"), y := NumGet(wp, 32, "int")
    
    options.WindowX := x
    options.WindowY := y

    for i,v in directValues {
        GuiControlGet, rValue,,%i%
        options[v] := rValue
    }

    for i,v in directNumValues {
        GuiControlGet, rValue,,%i%
        m := 0
        if rValue is number
            m := 1
        options[v] := m ? rValue : 0
    }

    GuiControlGet, privateServerL,,PrivateServerInput
    if (privateServerL){
        RegExMatch(privateServerL, "(?<=privateServerLinkCode=)(.{32})", serverId)
        if (!serverId && RegExMatch(privateServerL, "(?<=code=)(.{32})")){
            MsgBox, % "The private server link you provided is a share link, this is not safe to use due to fake link will get your account terminated. To get the code link, paste the share link into your browser and run it. This should convert the link to a privateServerLinkCode link. Copy and paste the converted link into the Private Server setting to fix this issue.`n`nThe link should look like: https://www.roblox.com/games/15532962292/Sols-RNG?privateServerLinkCode=..."
        }
        options.PrivateServerId := serverId ""
    }

    GuiControlGet, webhookLink,,WebhookInput
    if (webhookLink){
        valid := validateWebhookLink(webhookLink)
        if (valid){
            options.WebhookLink := webhookLink
        } else {
            if (options.WebhookLink){
                MsgBox,0,New Webhook Link Invalid, % "Invalid webhook link, the link has been reverted to your previous valid one."
            } else {
                MsgBox,0,Webhook Link Invalid, % "Invalid webhook link, the webhook option has been disabled."
                options.WebhookEnabled := 0
            }
        }
    }

    GuiControlGet, glitchID,,WebhookGlitchIDInput
    if (glitchID && !options.glitchIDMsgShown) {
        if (privateServerL) {
            RegExMatch(privateServerL, "(?<=privateServerLinkCode=)(.{32})", serverId)
            if (serverId) {
                MsgBox, 0, Glitch Biome Ping, % "Adding a glitch biome ping will ensure it sends your private server link to discord webhook whenever a glitch is found. This also helps track your glitch biome easier. You can also ping second person or custom roleid without being limited to only one person so this would be help alot for glitch hunting"
                options.DiscordGlitchID := glitchID
            } else {
                MsgBox, 0, Glitch Biome Ping Error, % "The link you provided is a share link, not a privateServerLinkCode link. Using a share link can expose you to malicious or fake games, which may result in account termination. Please ensure you use an official Sol's RNG private server link."
                options.DiscordGlitchID := ""
            }
        } else {
            MsgBox, 0, Glitch Biome Ping Error, % "Please provide a valid private server link (In macro 'Settings' tab -> 'Reconnect' Frame -> 'Private Server') to enable glitch biome ping."
            options.DiscordGlitchID := ""
        }
        options.glitchIDMsgShown := True
    }

    Loop 8 {
        GuiControlGet, rValue,,CollectSpot%A_Index%CheckBox
        options["ItemSpot" . A_Index] := rValue
    }

    Loop 3 {
        GuiControlGet, rValue,,PotionCraftingSlot%A_Index%DropDown
        options["PotionCraftingSlot" . A_Index] := reversePotionIndex[rValue]
    }
    
}

Jester_Exchange_SaveOptions(){
    Gui JesterGUI:Default
    GuiControlGet, CustomAmounts
    options["Jester_Custom_Exchange_Amounts"] := CustomAmounts

    Loop 8 {
        GuiControlGet, jesterItemValue,, JesterItem%A_Index%DropDown
        options["Jester_Exchange_ItemSlot" . A_Index] := jesterItemValue   
    }

    saveOptions()
}

global importingSettings := 0
global importingSettings := 0

handleImportSettings() {
    global configPath, merchantConfigPath

    if (importingSettings) {
        return
    }

    MsgBox, % 1 + 4096, % "Import Settings", % "To import the settings from a previous version folder of the Macro, please select both the ""config.ini"" and ""merchant_config"" files located in the previous version's ""settings"" folder when prompted. Press OK to begin."

    IfMsgBox, Cancel
        return

    importingSettings := 1

    ; Import config.ini
    FileSelectFile, targetConfigPath, 3,, Import dolphSol Settings Through a config.ini File, % "Configuration settings (config.ini)"
    
    ; Import merchant_config
    FileSelectFile, targetMerchantConfigPath, 3,, Import merchant_config File, % "Merchant configuration (merchant_config)"
    
    ; Handle config.ini import
    if (targetConfigPath && RegExMatch(targetConfigPath, "\\config\.ini")) {
        if (targetConfigPath != configPath) {
            FileRead, retrievedConfig, %targetConfigPath%

            if (!ErrorLevel) {
                FileDelete, %configPath%
                FileAppend, %retrievedConfig%, %configPath%
            } else {
                MsgBox, 0, Import Settings Error, % "An error occurred while reading the config.ini file, please try again."
                importingSettings := 0
                return
            }
        } else {
            MsgBox, 0, Import Settings Error, % "Cannot import settings from the current macro's config.ini!"
        }
    }

    ; Handle merchant_config import
    if (targetMerchantConfigPath && RegExMatch(targetMerchantConfigPath, "\\merchant_config")) {
        if (targetMerchantConfigPath != merchantConfigPath) {
            FileRead, retrievedMerchantConfig, %targetMerchantConfigPath%

            if (!ErrorLevel) {
                FileDelete, %merchantConfigPath%
                FileAppend, %retrievedMerchantConfig%, %merchantConfigPath%
            } else {
                MsgBox, 0, Import Settings Error, % "An error occurred while reading the merchant_config file, please try again."
                importingSettings := 0
                return
            }
        } else {
            MsgBox, 0, Import Settings Error, % "Cannot import settings from the current macro's merchant_config!"
        }
    }

    loadData()
    updateUIOptions()
    saveOptions()

    MsgBox, 0, Import Settings, % "Success!"

    importingSettings := 0
}

handleWebhookEnableToggle(){
    Gui mainUI:Default
    GuiControlGet, rValue,,WebhookCheckBox

    if (rValue){
        GuiControlGet, link,,WebhookInput
        if (!validateWebhookLink(link)){
            GuiControl, , WebhookCheckBox,0
            MsgBox,0,Webhook Link Invalid, % "Invalid webhook link, the webhook option has been disabled."
        }
    }
}

global statDisplayInfo := {"RunTime":"Run Time"
    ,"Disconnects":"Disconnects"
    ,"ObbyCompletes":"Obby Completes"
    ,"ObbyAttempts":"Obby Attempts"
    ,"CollectionLoops":"Collection Loops"}

formatNum(n,digits := 2){
    n := Floor(n+0.5)
    cDigits := Max(1,Ceil(Log(Max(n,1))))
    final := n
    if (digits > cDigits){
        loopCount := digits-cDigits
        Loop %loopCount% {
            final := "0" . final
        }
    }
    return final
}

getTimerDisplay(t){
    return formatNum(Floor(t/86400)) . ":" . formatNum(Floor(Mod(t,86400)/3600)) . ":" . formatNum(Floor(Mod(t,3600)/60)) . ":" . formatNum(Mod(t,60))
}

updateStats(){
    ; per 1s
    if (running){
        options.RunTime += 1
    }

    statText := ""
    for i,v in statDisplayInfo {
        value := options[i]
        if (statText){
            statText .= "`n"
        }
        if (i = "RunTime"){
            value := getTimerDisplay(value)
        }
        statText .= v . ": " . value
    }
    Gui mainUI:Default
    GuiControl, , StatsDisplay, % statText
}
SetTimer, updateStats, 1000

global statusColors := {"Starting Macro":3447003
    ,"Roblox Disconnected":15548997
    ,"Reconnecting":9807270
    ,"Reconnecting, Roblox Opened":9807270
    ,"Reconnecting, Game Loaded":9807270
    ,"Reconnect Complete":3447003
    ,"Initializing":3447003
    ,"Searching for Items":15844367
    ,"Doing Obby":15105570
    ,"Completed Obby":5763719
    ,"Obby Failed, Retrying":11027200
    ,"Macro Stopped":3447003
    ,"Beginning Crafting Cycle":1752220}

updateStatus(newStatus){
    logMessage("[updateStatus] New status: " newStatus)
    if (options.WebhookEnabled){
        FormatTime, fTime, , HH:mm:ss
        if (!options.WebhookImportantOnly || importantStatuses[newStatus]){
            try webhookPost({embedContent: "[" fTime "]: " newStatus,embedColor: (statusColors[newStatus] ? statusColors[newStatus] : 1)})
        }
    }
    GuiControl,statusBar:,StatusBarText,% "Status: " newStatus
}

startDim(clickthru := 0,topText := ""){
    removeDim()
    w:=A_ScreenWidth,h:=A_ScreenHeight-2
    if (clickthru){
        Gui Dimmer:New,+AlwaysOnTop +ToolWindow -Caption +E0x20 ;Clickthru
    } else {
        Gui Dimmer:New,+AlwaysOnTop +ToolWindow -Caption
    }
    Gui Color, 333333
    Gui Show,NoActivate x0 y0 w%w% h%h%,Dimmer
    WinSet Transparent,% 75,Dimmer
    Gui DimmerTop:New,+AlwaysOnTop +ToolWindow -Caption +E0x20
    Gui Color, 222222
    Gui Font, s13
    Gui Add, Text, % "x0 y0 w400 h40 cWhite 0x200 Center", % topText
    Gui Show,% "NoActivate x" (A_ScreenWidth/2)-200 " y25 w400 h40"
}

removeDim(){
    Gui Dimmer:Destroy
    Gui DimmerTop:Destroy
}

global selectingAutoEquip := 0
startAutoEquipSelection(){
    if (selectingAutoEquip || macroStarted){
        return
    }

    MsgBox, % 1 + 4096, Begin Auto Equip Selection, % "Once you press OK, please click on the inventory slot that you would like to automatically equip.`n`nPlease ensure that your storage is open upon pressing OK. Press Cancel if it is not open yet."

    IfMsgBox, Cancel
        return
    
    if (macroStarted){
        return
    }

    selectingAutoEquip := 1

    startDim(1,"Click the target storage slot (Right-click to cancel)")

    Gui mainUI:Hide
}

cancelAutoEquipSelection(){
    if (!selectingAutoEquip) {
        return
    }
    removeDim()
    Gui mainUI:Show
    selectingAutoEquip := 0
}

completeAutoEquipSelection(){
    if (!selectingAutoEquip){
        return
    }

    applyNewUIOptions()

    MouseGetPos, mouseX,mouseY
    uv := getAspectRatioUVFromPosition(mouseX,mouseY,storageAspectRatio)
    options.AutoEquipX := uv[1]
    options.AutoEquipY := uv[2]

    saveOptions()
    cancelAutoEquipSelection()

    MsgBox, 0,Auto Equip Selection,Success!
}

handleLClick(){
    if (selectingAutoEquip){
        completeAutoEquipSelection()
    }
}

handleRClick(){
    if (selectingAutoEquip){
        cancelAutoEquipSelection()
    }
}

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

startMacro(){
    logMessage("=====================================")
    updateStatus("Starting Macro")

    ; Log system information and relevant variables
    logMessage("System Information:")
    logMessage("OS Version: " A_OSVersion, 1)
    logMessage("AHK Version: " A_AhkVersion, 1)
    logMessage("Screen Width: " A_ScreenWidth, 1)
    logMessage("Screen Height: " A_ScreenHeight, 1)
    logMessage("Screen DPI: " A_ScreenDPI, 1)
    logMessage("Active Language: " getCurrentLanguage(), 1)

    ; Log macro variables
    logMessage("Macro Variables:")
    logMessage("Version: " version, 1)
    logMessage("OCR Enabled: " options.OCREnabled, 1)

    if (!canStart){
        logMessage("[startMacro] canStart is false, exiting...")
        return
    }
    if (macroStarted && running) { ; Added extra running check to prevent exiting prematurely
        logMessage("[startMacro] macroStarted is already true, exiting...")
        return
    }

    macroStarted := 1
    updateStatus("Macro Started")

    ; cancel any interfering stuff
    cancelAutoEquipSelection()

    ; Save any changes made in the UI
    applyNewUIOptions()
    saveOptions()

    Gui, mainUI:+LastFoundExist
    WinSetTitle, % "dolphSol Macro " version " (Running)"

    ; Run, % """" . A_AhkPath . """ """ mainDir . "lib\status.ahk"""
    Run, *RunAs "%A_AhkPath%" /restart "%mainDir%lib\status.ahk"

    if (options.StatusBarEnabled){
        Gui statusBar:Show, % "w220 h25 x" (A_ScreenWidth-300) " y100", dolphSol Status
    }
    
    ; Log game information and relevant variables
    logMessage("Roblox Information:")
    
    robloxId := GetRobloxHWND()
    if (!robloxId){
        logMessage("[startMacro] Roblox ID not found, attempting to reconnect...")
        attemptReconnect()
    }

    ; Get window position and size
    getRobloxPos(pX,pY,width,height)
    logMessage("Window ID: " robloxId, 1)
    logMessage("Width: " width, 1)
    logMessage("Height: " height, 1)


    options.LastRobloxRestart := getUnixTime() ; Reset so isn't immediately triggered
    running := 1
    logMessage("") ; empty line for separation
    logMessage("[startMacro] Starting main loop")
    WinActivate, ahk_id %robloxId%
    while running {
        try {
            mainLoop()
        } catch e {
            ewhat := e.what, efile := e.file, eline := e.line, emessage := e.message, eextra := e.extra
            logMessage("[startMacro] Error: `nwhat: " ewhat "`nfile: " efile "`nline: " eline "`nmessage: " emessage "`nextra: " eextra)
            try {
                webhookPost({embedContent: "what: " e.what ", file: " e.file
                . ", line: " e.line ", message: " e.message ", extra: " e.extra, embedTitle: "Error Received", color: 15548997})
            }
            MsgBox, 16,, % "Error!`n`nwhat: " e.what "`nfile: " e.file
                . "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
            
            running := 0
        }
        
        Sleep, 2000
    }
}

if (!options.FirstTime){
    options.FirstTime := 1
    saveOptions()
    MsgBox, 0,dolphSol Macro - Welcome, % "Welcome to dolphSol macro!`n`nIf this is your first time here, go through all of the tabs to make sure your settings are right.`n`nIf you are here from an update, remember that you can import all of your previous settings in the Settings menu.`n`nJoin the Discord server and check the GitHub page for the community and future updates, which can both be found in the Credits page."
}

if (!options.WasRunning){
    options.WasRunning := 1
    saveOptions()
}

canStart := 1

return

; button stuff

StartClick:
    if (running) {
        return
    }
    startMacro()
    return

PauseClick:
    if (!running) {
        return
    }
    ; MsgBox, 0,% "Pause",% "Please note that the pause feature isn't very stable currently. It is suggested to stop instead."
    handlePause()
    return

StopClick:
    if (!running) {
        return
    }
    stop()
    Reload
    return

SubmitAuraName:
    Gui, AuraSearch:Submit, NoHide

    if (AuraNameInput != "") {
        options.AutoEquipAura := AuraNameInput
        options.SearchSpecialAuras := SearchSpecialAurasCheckBox
        saveOptions()
        Gui, AuraSearch:Destroy
    }

    return

DiscordServerClick:
    Run % "https://discord.gg/DYUqwJchuV"
    return

EnableWebhookToggle:
    handleWebhookEnableToggle()
    return

ImportSettingsClick:
    handleImportSettings()
    return

WebhookRollImageCheckBoxClick:
    Gui mainUI:Default
    GuiControlGet, v,, WebhookRollImageCheckBox
    if (v){
        MsgBox, 0, Aura Roll Image Warning, % "Warning: Currently, the aura image display for the webhook is fairly unstable, and may cause random delays in webhook sends due to image loading. Enable at your own risk."
    }
    return

GetRobloxVersion:
    Gui, Submit, NoHide
    options["RobloxUpdatedUI"] := (RobloxUpdatedUIRadio1 = 1) ? 1 : 2
    return

Niko_OR_DefaultPath:
    Gui, Submit, NoHide
    options["IsNikoPath"] := (CollectPathRadio1 = 1) ? 1 : 2
    return

ShifterCheckBoxClick:
    Gui mainUI:Default
    GuiControlGet, v,, ShifterCheckBox
    if (v){
    MsgBox, 0, Important, % "Shifter mode has not been tested with a non vip account and does not currently have Obby capabilites."
    }
    return

OCREnabledCheckBoxClick:
    Gui mainUI:Default
    GuiControlGet, v,, OCREnabledCheckBox
    if (v) {
        options.OCREnabled := 0
        currentLanguage := getCurrentLanguage()
        if (currentLanguage = "English") {
            options.OCREnabled := 1
        }
        ocrLanguages := getOCRLanguages()
        if (InStr(ocrLanguages, "en-US")) {
            options.OCREnabled := 1
        }

        if (options.OCREnabled) { ; Confirm resolution settings
            if (A_ScreenWidth <> 1920 || A_ScreenHeight <> 1080 || A_ScreenDPI <> 96) {
                options.OCREnabled := 0
                MsgBox, 0, OCR Error, % "A monitor resolution of 1920x1080 with a 100% scale is required for OCR at this time.`n"
                                      . "We will continue working to support more configurations."
            } else {
                ; getRobloxPos(pX, pY, pW, pH)
                ; if not (pW = 1920 && pH = 1080 && A_ScreenDPI = 96) { ; Disable if Roblox isnt in fullscreen
                ;     MsgBox, 0, Another Error, % "Roblox must be in fullscreen to use OCR."
                ;     options.OCREnabled := 0
                ; } else {
                ;     return
                ; }
            }
        } else {
            MsgBox, 0, OCR Language Error, % "Unable to use OCR. Please set your language to English-US in your PC settings and restart to enable OCR."
        }
        ; GuiControl, , OCREnabledCheckBox, 0
    }
    return

MoreCreditsClick:
    creditText =
(
Development

 v1.5.0+ Contributors
  - Amraki (amraki)
  - Stewart (unoriginalstew)
  - Big thank you to these people, as well as everyone else who helped work on this version over the few months of my inactivity!

- Assistant Developer - Stanley (stanleyrekt)
- Path Contribution - sanji (sir.moxxi), Flash (drflash55)
- Path Inspiration - Aod_Shanaenae

Supporters (Donations)

- Bigman, sir.moxxi (sanji), @zrx, @dj_frost, @jw, dead_is4, CorruptExpy_II, Ami.n, JujuFRFX, Xon67, @nottheofficialblx, v2isballin, Luke_, a11xn, @ashkarti, da.cheese, Xander, Aki, .heavenlyy, 1vqs, xpersonie, @ItsLinkCraft, @l3m0n_0, churchuk, cookie

 Members
  - FlamePrince101, Maz, @s.a.t.s, UnamedWasp, NightLT98, DeclanPickle, Fantesium, Jirach1, notkenno

= Dolphsol's Improvement macro (dSIM) Credits =
- noteab (Main developer for Auto merchant, rework internal codes for the macro)
- Curious Penguin (Co-owner of the macro, responsible for Record Aura feature)
- _justalin (Spot 8, potion collecting)
- Aod_Shanaenae aka Niko (Spot 8, potion collecting)

** dSIM Macro Testers (Discord) **
- !|CaCO3|! Suggestions dweller - criticize.
- 『❖』SmileNightOFC - smile.night
- Allan - _justalin
- Cataster - catast3r
- DiEgO - diego696969
- Dolphinatorツ - wtr_dolphinator
- enzo | Ping and i'll answer - enzomtp
- justimon. - imonjusty
- ManasAarohi - manasaarohi
- Pach | Minn Worshiper - pachulin911
- Parham - parham125
- root da war veteran - taachyon
- ZekeDaYes - zekedayes

Thank you to everyone who currently supports and uses the macro! You guys are amazing!
)
    MsgBox, 0, More Credits, % creditText
    return

; help buttons
ObbyHelpClick:
    MsgBox, 0, Obby, % "Section for attempting to complete the Obby on the map for the +30% luck buff every 2 minutes. If you have the VIP Gamepass, make sure to enable it in Settings.`n`nCheck For Obby Buff Effect - Checks your status effects upon completing the obby and attempts to find the buff. If it is missing, the macro will retry the obby one more time. Disable this if your macro keeps retrying the obby after completing it. The ObbyCompletes stat will only increase if this check is enabled.`n`nPLEASE NOTE: The macro's obby completion ability HIGHLY depends on a stable frame-rate, and will likely fail from any frame freezes. If your macro is unable to complete the obby at all, it is best to disable this option."
    return

AutoEquipHelpClick:
    MsgBox, 0, Auto Equip, % "Section for automatically equipping a specified aura every macro round. This is important for equipping auras without walk animations, which may interfere with the macro.`n`nThis feature is HIGHLY RECOMMENDED to be used on a non-animation aura for best optimization."
    return

CollectHelpClick:
    MsgBox, 0, Item Collecting, % "Section for automatically collecting naturally spawned items around the map. Enabling this will have the macro check the selected spots every loop after doing the obby (if enabled and ready).`n`nYou can also specify which spots to collect from. If a spot is disabled, the macro will not grab any items from the spot. Please note that the macro always takes the same path, it just won't collect from a spot if it's disabled. This feature is useful if you are sharing a server with a friend, and split the spots with them.`n`nItem Spots:`n 1 - Left of the Leaderboards`n 2 - Bottom left edge of the Map`n 3 - Under a tree next to the House`n 4 - Inside the House`n 5 - Under the tree next to Jake's Shop`n 6 - Under the tree next to the Mountain`n 7 - On top of the Hill with the Cave"
    return

WebhookHelpClick:
    MsgBox, 0, Discord Webhook, % "Section for connecting a Discord Webhook to have status messages displayed in a target Discord Channel. Enable this option by entering a valid Discord Webhook link.`n`nTo create a webhook, you must have Administrator permissions in a server (preferably your own, separate server). Go to your target channel, then configure it. Go to Integrations, and create a Webhook in the Webhooks Section. After naming it whatever you like, copy the Webhook URL, then paste it into the macro. Now you can enable the Discord Webhook option!`n`nRequires a valid Webhook URL to enable.`n`nImportant events only - The webhook will only send important events such as disconnects, rolls, and initialization, instead of all of the obby/collecting/crafting ones.`n`nYou can provide your Discord ID here as well to be pinged for rolling a rarity group or higher when detected by the system. You can select the minimum notification/send rarity in the Roll Detection system.`n`nHourly Inventory Screenshots - Screenshots of both your Aura Storage and Item Inventory are sent to your webhook."
    return

    RecordAuraHelp:
    Gui mainUI:Default
    helpText = 
(
Recording Auras uses Xbox Game Bar's record last 30 Seconds feature to record you rolling your auras.
To enable this:
1. Open Roblox
2. Press Win+G
3. Enable Record Last 30 Seconds Option
    - If there is any problem with xbox game bar reinstall it
        - Search up eleven forums reinstall game bar
    - If xbox bar greyed out
        - Search up ARG99 Xbox game bar greyed out on YOUTUBE
4. Open Main.ahk
5. Enable Record Last 30 Seconds Option
6. Check the Checbock: Enable Gaming features for this app to record gameplay


Record Minimum:
You can specify the minimum rarity of rolls to record. 
Default = 100000
)
    MsgBox, 0, Recording Auras, % helpText
    return

RollDetectionHelpClick:
    MsgBox, 0, Roll Detection, % "Section for detecting rolled auras through the registered star color (if 10k+). Any 10k+ auras that can be sent will be sent to the webhook, with the option to ping if the rarity is above the minimum.`n`nFor minimum settings, the number determines the lowest possible rarity the webhook will send/ping for. Values of 0 will disable the option completely. Values under 10,000 will toggle all 1k+ rolls, due to them being near undetectable.`n`nAura Images can be toggled to show the wiki-based images of your rolled auras in the webhook. WARNING: After some testing, this has proven to show some lag, leading to some send delay issues. Use at your own risk!"
    return

OCRHelpClick:
    MsgBox, 0, OCR, % "OCR allows the macro to respond to events instead of blindly pressing keys and moving the mouse. Currently requires Roblox to be ran at 1920x1080 resolution and 100% scale."
	return

Spot8HelpClick:
    MsgBox, 0, Spots Status, % "Path Notice:`n`nSpot 1: Experimental (VIP recommended, may fail due to FPS lag) - made by noteab`nSpot 2: Experimental (VIP recommended, may fail due to FPS lag) - made by noteab`nSpot 3: Experimental (VIP recommended, may fail due to FPS lag) - made by noteab`nSpot 4: Experimental (VIP recommended, may fail due to FPS lag) - made by noteab`nSpot 5: Not yet implemented`nSpot 6: Not yet implemented`nSpot 7: Not yet implemented`nSpot 8: Not yet implemented"
    return

AutoMerchantHelp:
    MsgBox, 0, Auto Merchant, % "In order to make this work correctly, this requires: `n`n`1. Your Merchant Teleport should be added and enabled in Item Scheduler (Extras Tab) (2-3 minutes every uses recommended) `n`n`2. You've correct calibrated everything in merchant setting (If you want the bot notify you when merchant was found then make sure it had properly set up in 'Merchant Webhooks') `n`n`3. You have turned off Shiftlock mode in roblox setting so it can press merchant open button and able to do autobuy!"
    return

UIHelpClick:
    Gui, New 
    Gui, Add, Picture, x20 y50, % mainDir "images\UIInformation.png" ; Change to the path of your image fil7
    Gui, Show, AutoSize  ; Adjust the GUI window size to fit the image
    return

MerchantCalibrationHelp:
    Gui, New
    Gui, Add, Picture, x30 y10, % mainDir "images\merchant_skibidiTut.png"
    Gui, Add, Text, x50 y635 w350, Some cool reminders:
    Gui, Add, Text, x50 y655 w350, -> Item Name OCR: Wait for merchant like Mari to spawn and then open her menu, there should be a bar showing her item and make sure to calibrate like as example image does
    Gui, Add, Text, x50 y698 w350, -> Merchant Name OCR and Merchant Open Button: You can do Jake's shop as a reference to save time since his and mari are the same dialogue (Note: Make sure to assign the open button at left side of the button because jester open button is smaller than mari, so assigning center or right side causing make the macro miss click the jester open button)
    Gui, Add, Text, x50 y768 w350, -> First Item Position: Just calibrate the position to the center of the first item of the merchant they're selling so it can reliably and click others slot seamlessly
    Gui, Show, w500 h850, Merchant Calibration Help
    return

gRecordPathClick:
    MsgBox, Record Path button clicked!
    return

; gui close buttons
mainUIGuiClose:
    stop(1)
return

AuraGuiClose:
    applyAuraSettings() ; Update options with the new aura settings
    saveOptions()  ; Save the options to the config file
    Gui, AuraSettings:Destroy
return

AuraSearchGuiClose:
    saveOptions()
    Gui, AuraSearch:Destroy
return

BiomeGuiClose:
    applyBiomeSettings() ; Update options
    saveOptions()  ; Save the options
    Gui, BiomeSettings:Destroy
return

ItemSchedulerGuiClose:
    SaveItemSchedulerSettings() ; Update options
    saveOptions()  ; Save the options
    Gui, ItemSchedulerSettings:Destroy
return

JesterUIClose:
    Jester_Exchange_SaveOptions()
    saveOptions()
    Gui, JesterGUI:Destroy
return

ClearToolTip:
    ToolTip
return

HideToolTip:
    ToolTip 
return



; hotkeys
#If !running
    F1::startMacro()

    F9:: ShowMousePos()


    ; F11::
    ;     ;Highlight(1039, 245, 150, 40, 5000) ; highlight box of shiftlock
    ;     ; WinGetPos, winX, winY, currentWinWidth, currentWinHeight, ahk_exe RobloxPlayerBeta.exe
    ;     ; ItemNotEnough_closeButtonX := winX + (491 * (currentWinWidth / 1920)) ; 960 for windowed 1920x1080
    ;     ; ItemNotEnough_closeButtonY := winY + (882 * (currentWinHeight / 1080)) + 9.5 ; 619 for windowed 1920x1080
    ;     ; ClickMouse(ItemNotEnough_closeButtonX, ItemNotEnough_closeButtonY)
    ;     return
    
#If

#If running || reconnecting
    F2::handlePause()

    F3::
        stop()
        Reload
        return
#If

#If selectingAutoEquip
~LButton::handleLClick()
~RButton::handleRClick()
#If

; Disable keyboard control of macro GUI to avoid accidental changes
#If WinActive("ahk_id" hGUI)
    Up::
    Down::
    Left::
    Right::
    Space::
    Tab::
    Enter::Return
#If

F4::
    Gui mainUI:Show
    return

F5:: ; For debugging/testing
    disableAlignment := !disableAlignment
    ToolTip, % disableAlignment ? "Initial Align Disabled" : "Initial Align Enabled"
    SetTimer, ClearToolTip, -5000
    return


