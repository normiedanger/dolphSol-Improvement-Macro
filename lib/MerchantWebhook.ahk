Merchant_WebhooksGui() {
    global merchantOptions, NewWebhookAlias, NewWebhookURL, NewPingUserID, NewMerchantPrivateServerLink, WebhookList, NewJesterPingUserID
    
    Gui, MerchantWebhooksSettings:New, +AlwaysOnTop +LabelWebhooksGui
    Gui Color, 0xDADADA
    Gui Font, s9 norm

    ; Title
    Gui, Add, Text, x16 y10 w300 h30, ==Merchant Webhook== (only 1 webhook supported, more webhook ping will be avail soon)
    
    ; New Webhook Section
    Gui, Add, Text, x16 y40 w250, Webhook Alias (e.g., Mari or Jester omg real??! or any silly name you want):
    Gui, Add, Edit, x16 y70 w250 vNewWebhookAlias, % merchantOptions.MerchantWebhookAlias

    Gui, Add, Text, x16 y100 w250, Webhook URL:
    Gui, Add, Edit, x16 y120 w250 r1 vNewWebhookURL, % merchantOptions.MerchantWebhookLink

    Gui, Add, Text, x16 y150 w250, Ping Mari User ID/Role ID (Optional):
    Gui, Add, Edit, x16 y170 w250 vNewPingUserID, % merchantOptions.MerchantWebhook_Mari_UserID

    Gui, Add, Text, x16 y200 w250, Ping Jester User ID/Role ID (Optional):
    Gui, Add, Edit, x16 y220 w250 vNewJesterPingUserID, % merchantOptions.MerchantWebhook_Jester_UserID

    Gui, Add, Text, x16 y250 w250, Merchant Private Server Link (Optional):
    Gui, Add, Edit, x16 y270 w250 r1 vNewMerchantPrivateServerLink, % merchantOptions["MerchantWebhook_PS_Link"]

    GuiControl,, NewWebhookAlias, % merchantOptions.MerchantWebhookAlias
    GuiControl,, NewWebhookURL, % merchantOptions.MerchantWebhookLink
    GuiControl,, NewPingUserID, % merchantOptions.MerchantWebhook_Mari_UserID
    GuiControl,, NewJesterPingUserID, % merchantOptions.MerchantWebhook_Jester_UserID
    GuiControl,, NewMerchantPrivateServerLink, % merchantOptions.MerchantWebhook_PS_Link

    Gui, Add, Button, x16 y320 w120 h30 gMerchant_AddWebhook, Add Webhook

    Gui, Add, Button, x220 y295 w95 h25 gMari_PingTest, Mari Ping (Test)
    Gui, Add, Button, x220 y323 w95 h25 gJester_PingTest, Jester Ping (Test)

    ; Existing Webhooks Section
    Gui, Add, ListBox, x16 y350 w300 h150 vWebhookList, % Merchant_ListWebhooks()

    ; Add Delete Webhook Button
    Gui, Add, Button, x16 y520 w120 h30 gMerchant_DeleteWebhook, Delete Webhook
    
    Gui, Show, , Discord Webhooks
}


Merchant_AddWebhook() {
    global merchantOptions, NewWebhookAlias, NewWebhookURL, NewPingUserID, NewMerchantPrivateServerLink, NewJesterPingUserID
    Gui, Submit, NoHide

    ; Validate the webhook URL
    if (!validateWebhookLink(NewWebhookURL)) {
        MsgBox, Invalid webhook URL! Please input a valid Discord webhook URL.
        return
    }

    merchantOptions.MerchantWebhookAlias := NewWebhookAlias
    merchantOptions.MerchantWebhookLink := NewWebhookURL
    merchantOptions.MerchantWebhook_Mari_UserID := NewPingUserID
    merchantOptions.MerchantWebhook_Jester_UserID := NewJesterPingUserID
    merchantOptions.MerchantWebhook_PS_Link := NewMerchantPrivateServerLink
    Save_Merchant_WebhookSettings()

    ; Update ListBox with the new webhook (limit to one webhook)
    GuiControl,, WebhookList, % NewWebhookAlias " | " NewWebhookURL
    
    ; Clear the input fields after submission
    GuiControl,, NewWebhookAlias
    GuiControl,, NewWebhookURL
    GuiControl,, NewPingUserID
    GuiControl,, NewJesterPingUserID
    GuiControl,, NewMerchantPrivateServerLink
}

Merchant_DeleteWebhook() {
    global merchantOptions

    merchantOptions.MerchantWebhookAlias := ""
    merchantOptions.MerchantWebhookLink := ""
    merchantOptions.MerchantWebhook_Mari_UserID := ""
    merchantOptions.MerchantWebhook_Jester_UserID := ""
    merchantOptions.MerchantWebhook_PS_Link := ""
    GuiControl,, WebhookList,
}

Merchant_ListWebhooks() {
    global merchantOptions
    output := ""
    if (merchantOptions.MerchantWebhookAlias != "") {
        output := merchantOptions.MerchantWebhookAlias " | " merchantOptions.MerchantWebhookLink
    }
    return output
}


Mari_PingTest() {
    Sleep, 1500
    Merchant_Webhook_Main("Mari", merchantOptions["MerchantWebhookLink"], merchantOptions["MerchantWebhook_PS_Link"], merchantOptions["MerchantWebhook_Mari_UserID"], "Merchant Face Screenshot (PING TEST)")
    Merchant_Webhook_Main("Mari", merchantOptions["MerchantWebhookLink"], , , "Item Screenshot (PING TEST)")
}

Jester_PingTest() {
    Sleep, 1500
    Merchant_Webhook_Main("Jester", merchantOptions["MerchantWebhookLink"], merchantOptions["MerchantWebhook_PS_Link"], merchantOptions["MerchantWebhook_Jester_UserID"], "Merchant Face Screenshot (PING TEST)")
    Merchant_Webhook_Main("Jester", merchantOptions["MerchantWebhookLink"], , , "Item Screenshot (PING TEST)")
}

Save_Merchant_WebhookSettings() {
    global merchantOptions, merchantConfigPath, configHeader
    iniData := {}
    iniData["MerchantWebhookAlias"] := merchantOptions.MerchantWebhookAlias
    iniData["MerchantWebhookLink"] := merchantOptions.MerchantWebhookLink
    iniData["MerchantWebhook_Mari_UserID"] := merchantOptions.MerchantWebhook_Mari_UserID
    iniData["MerchantWebhook_Jester_UserID"] := merchantOptions.MerchantWebhook_Jester_UserID
    iniData["MerchantWebhook_PS_Link"] := merchantOptions.MerchantWebhook_PS_Link
    writeToINI(merchantConfigPath, iniData, configHeader)
}

