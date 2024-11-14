/*

    Arrays 'ScheduleItems' and 'biomes' are defined in staticData.json

*/

; Thank you to amraki, and the others (so sorry i forgot) for creating this entire script

; Create the Item Scheduler settings popup
ShowItemSchedulerSettings() {
    global

    Gui ItemSchedulerSettings:New, +AlwaysOnTop +LabelItemSchedulerGui
    ; Gui Font, s10 w600
    ; Gui Add, Text, x16 y10 w300 h30, Auto Item Scheduler
    Gui Font, s9 norm

    ; Initialize position variables
    startXPos := 16
    startYPos := 10
    xPos := startXPos
    yPos := startYPos

    ; Add button to add new entry and Highlight Coordinates
    Gui Add, Button, x%xPos% y%yPos% w100 h25 gAddNewItemEntry vAddNewItemEntryButton, New Entry
    Gui Add, Button, x+50 wp w150 h25 gHighlightItemCoordinates vHighlightItemCoordinatesButton, Test Mouse Clicks (Highlight)
    yPos += 30

    ; Create headers
    Gui Add, Text, x%xPos% y%yPos% Section w50 h20, Enable
    Gui Add, Text, x+30 yp w100 h20, Item
    Gui Add, Text, x+-25 yp w50 h20, Quantity
    Gui Add, Text, x+20 yp w50 h20, Frequency
    Gui Add, Text, x+55 yp w50 h20, Biome
    yPos += 20

    ; Create entries for each item usage configuration
    xPos := 20
    for index, entry in ItemSchedulerEntries {
        ; OutputDebug, % "# Entries: " ItemSchedulerEntries.Length()
        if (!entry) {
            ; OutputDebug, % "*Item " index ": " entry.ItemName
            break
        }
        ; OutputDebug, % "Item " index ": " entry.ItemName
        AddItemEntry(index, entry, xPos, yPos)
        yPos += 30
    }

    Gui Show, % "w500 h400", Auto Item Scheduler
}

; Function to add item entry to GUI
AddItemEntry(idx, entry, xPos, yPos) {
    global

    OutputDebug, % "Adding entry " idx " at yPos " yPos

    ; Concatenate item names for the dropdown list
    itemList := ""
    for each, item in ScheduleItems {
        itemList .= item "|"
    }

    ; Concatenate biome names for the dropdown list
    biomeList := "Any|"
    for each, biome in biomes {
        biomeList .= biome "|"
    }

    ; Add controls for the entry
    Gui Add, CheckBox, % "vEnable" idx "CheckBox Section x" xPos " y" yPos " w30 h20 Checked" entry.Enabled, % idx
    Gui Add, DropDownList, vItem%idx%DropDown x+ yp w115 h20 R10, % itemList
    GuiControl, ChooseString, Item%idx%DropDown, % entry.ItemName
    Gui Add, Edit, vQuantity%idx%Edit x+5 yp wp+10 w40 h20 Number Center, % entry.Quantity
    Gui Add, Edit, vFrequency%idx%Edit x+5 yp w30 h20 Number Center, % entry.Frequency
    Gui Add, DropDownList, vTimeUnit%idx%DropDown x+ yp w80 h20 R3, Seconds||Minutes||Hours

    ; Select the correct time unit
    GuiControl, ChooseString, TimeUnit%idx%DropDown, % entry.TimeUnit ? entry.TimeUnit : "Minutes"

    Gui Add, DropDownList, vBiome%idx%DropDown x+ yp w75 h20 R10, % biomeList
    GuiControl, ChooseString, Biome%idx%DropDown, % entry.Biome ? entry.Biome : "Any"
    Gui Add, Button, gDeleteItemEntry vDelete%idx% x+m yp w80 h20, Delete
}

; Function to add a new empty item entry
AddNewItemEntry() {
    ; Calculate yPos based on non-deleted entries
    yPos := 60
    for each, entry in ItemSchedulerEntries {
        if (!entry.Deleted) {
            yPos += 30
        }
    }

    entry := {Enabled: 1
        , ItemName: ""
        , Quantity: 1
        , Frequency: 1
        , TimeUnit: "Minutes"
        , Biome: "Any"}
    
    idx := ItemSchedulerEntries.Length() + 1
    AddItemEntry(idx, entry, 20, yPos)
    ItemSchedulerEntries.Push(entry)
}

; Function to save item settings
SaveItemSchedulerSettings() {
    global configPath, options, ItemSchedulerEntries

    ; Clear current entries
    ItemSchedulerEntries := []

    ; Flush entries from options to avoid leaving deleted entries
    for i, v in options {
        if (InStr(i, "ISEntry", 1) = 1) {
            options.Delete(i)
        }
    }

    ; Save each entry's settings
    Gui, ItemSchedulerSettings:Default
    idx := 1
    Loop {
        ; OutputDebug, % "Saving index " idx

        GuiControlGet, visible, Visible, Enable%idx%CheckBox
        if (ErrorLevel) {
            break
        }

        if (!visible) { ; Skip "deleted" entries - AHK v1 has no way to delete controls so they are hidden instead
            idx++
            continue
        }

        ; Retrieve values from the controls
        GuiControlGet, enabled,, Enable%idx%CheckBox
        GuiControlGet, itemName,, Item%idx%DropDown
        GuiControlGet, quantity,, Quantity%idx%Edit
        GuiControlGet, frequency,, Frequency%idx%Edit
        GuiControlGet, timeUnit,, TimeUnit%idx%DropDown
        GuiControlGet, biome,, Biome%idx%DropDown

        if (itemName = "" || quantity < 1 || frequency < 1) { ; Skip incomplete entries
            idx++
            continue
        }

        ; OutputDebug, % "  Item: " itemName
        ; OutputDebug, % "  Enabled: " enabled
        ; OutputDebug, % "  Quantity: " quantity
        ; OutputDebug, % "  Frequency: " frequency
        ; OutputDebug, % "  Min/Hr: " timeUnit
        ; OutputDebug, % "  Biome: " biome

        entry := {Enabled: enabled
            , ItemName: itemName
            , Quantity: quantity
            , Frequency: frequency
            , TimeUnit: timeUnit
            , Biome: biome}

        ; Add the entry to the ItemSchedulerEntries array
        ItemSchedulerEntries.Push(entry)

        idx++
    }

    ; Save settings to global options
    for i, entry in ItemSchedulerEntries {
        options["ISEntry" i] := entry.Enabled "," entry.ItemName "," entry.Quantity "," entry.Frequency "," entry.TimeUnit "," entry.Biome
    }
}

; Function to delete an item entry
DeleteItemEntry() {
    Gui, ItemSchedulerSettings:Default

    ; Extract the index from the control's variable name
    RegExMatch(A_GuiControl, "\d+", idx)

    ; Mark the entry as deleted (keeps the array length consistent)
    ItemSchedulerEntries[idx].Deleted := true

    ; Hide the controls associated with the entry
    GuiControl, Hide, Enable%idx%CheckBox
    GuiControl, Hide, Item%idx%DropDown
    GuiControl, Hide, Quantity%idx%Edit
    GuiControl, Hide, Frequency%idx%Edit
    GuiControl, Hide, TimeUnit%idx%DropDown
    GuiControl, Hide, Biome%idx%DropDown
    GuiControl, Hide, Delete%idx%

    ; Reposition remaining controls
    yPos := 60
    for i, entry in ItemSchedulerEntries {
        if (!entry.Deleted) {
            ; Update the position of visible controls
            GuiControl, Move, Enable%i%CheckBox, y%yPos%
            GuiControl, Move, Item%i%DropDown, y%yPos%
            GuiControl, Move, Quantity%i%Edit, y%yPos%
            GuiControl, Move, Frequency%i%Edit, y%yPos%
            GuiControl, Move, TimeUnit%i%DropDown, y%yPos%
            GuiControl, Move, Biome%i%DropDown, y%yPos%
            GuiControl, Move, Delete%i%, y%yPos%

            ; Force redraw to ensure no blurriness or overlap
            GuiControl, MoveDraw, Enable%i%CheckBox
            GuiControl, MoveDraw, Item%i%DropDown
            GuiControl, MoveDraw, Quantity%i%Edit
            GuiControl, MoveDraw, Frequency%i%Edit
            GuiControl, MoveDraw, TimeUnit%i%DropDown
            GuiControl, MoveDraw, Biome%i%DropDown
            GuiControl, MoveDraw, Delete%i%
            yPos += 30
        }
    }
}

LoadItemSchedulerOptions() {
    global configPath, ItemSchedulerEntries, ScheduleItems

    ; Load items available for use
    ScheduleItems := sData.scheduleItems

    savedRetrieve := getINIData(configPath)
    if (!savedRetrieve) {
        logMessage("[LoadItemSchedulerOptions] Unable to read config.ini")
        return
    }

    ItemSchedulerEntries := []
    for i, v in savedRetrieve {
        if (InStr(i, "ISEntry", 1) = 1) {
            parts := StrSplit(v, ",")
            entry := {Enabled: parts[1], ItemName: parts[2], Quantity: parts[3], Frequency: parts[4], TimeUnit: parts[5], Biome: parts[6]}
            entry.NextRunTime := getUnixTime() ; Run once on load. TODO: Add option to menu entries

            if (entry.ItemName = "") {
                continue
            }
            ItemSchedulerEntries.Push(entry)
        }
    }

    ; Add entries to options - Handled in Save function which is only called when Scheduler is closed
    for i, entry in ItemSchedulerEntries {
        options["ISEntry" i] := entry.Enabled "," entry.ItemName "," entry.Quantity "," entry.Frequency "," entry.TimeUnit "," entry.Biome
    }
}

; Function to highlight coordinates
HighlightItemCoordinates() {
    if (!GetRobloxHWND()){
        MsgBox, 262144, Roblox Not Found, Please make sure that Roblox is open to test coordinates.
        return
    }
    ; Highlight where mouse will click to automatically use items
    ; For user to test accuracy

    ; 850, 330 Search box
    searchBar := getPositionFromAspectRatioUV(0.56, -0.39, storageAspectRatio)
    Highlight(searchBar[1]-5, searchBar[2]-5, 10, 10, 5000)

    ; 860, 400 1st search result
    selectItem := getPositionFromAspectRatioUV(-0.18, -0.25, storageAspectRatio)
    Highlight(selectItem[1]-5, selectItem[2]-5, 10, 10, 5000)

    ; 590, 600 Quantity box
    updateQuantity:= getPositionFromAspectRatioUV(-0.70, 0.12, storageAspectRatio)
    Highlight(updateQuantity[1]-5, updateQuantity[1]-5, 10, 10, 5000)

    ; 700, 600 Use button
    clickUse:= getPositionFromAspectRatioUV(-0.46, 0.12, storageAspectRatio)
    Highlight(clickUse[1]-5, clickUse[2]-5, 10, 10, 5000)
}