#Include Gdip_All.ahk

if !pToken := Gdip_Startup() {
    MsgBox, Failed to start GDI+.
    ExitApp
}


tesseractDir := "C:\Program Files\Tesseract-OCR"
tesseractExe := "tesseract.exe"
tesseractPath := tesseractDir "\" tesseractExe

imagePath := A_ScriptDir "\biome_ss.jpg"
merchantImagePath := A_ScriptDir "\merchant_ocr_ss.jpg"
miscellaneousImagePath := A_ScriptDir "\miscellaneous_ocr_ss.jpg"
outputPath := A_ScriptDir "\tesseract_output"



CheckTesseractPath() {
    global tesseractDir, tesseractExe, tesseractPath

    if !FileExist(tesseractDir) {
        MsgBox, The specified directory does not exist: %tesseractDir%
        ExitApp
    }

    Loop, Files, %tesseractDir%\%tesseractExe%, F
    {
        tesseractPath := A_LoopFileFullPath
        break
    }

    if !FileExist(tesseractPath) {
        MsgBox, 4, Tesseract Not Found, Tesseract is not installed or the path is incorrect.`nWould you like to download and install it now?
        IfMsgBox, Yes
        {
            Run, https://github.com/tesseract-ocr/tesseract/releases/download/5.5.0/tesseract-ocr-w64-setup-5.5.0.20241111.exe
            MsgBox, Please install Tesseract if you haven't installed it yet..?
        }
        else
        {
            MsgBox, Adjust the Tesseract exe path in the script to match your installation directory, it is most likely in C:\Program Files\Tesseract-OCR i think so lol
        }
        ExitApp
    }
}

CaptureScreen(x, y, width, height) {
    global imagePath
    pBitmap := Gdip_BitmapFromScreen(x "|" y "|" width "|" height)

    ApplyImageEffects(pBitmap)
    Gdip_SaveBitmapToFile(pBitmap, imagePath)
    Gdip_DisposeImage(pBitmap)
    return PerformOCR(imagePath)
}

Merchant_CaptureScreen(x, y, width, height) {
    global merchantImagePath
    merchantImagePath := A_ScriptDir "\lib\merchant_ocr_ss.jpg"
    pBitmap := Gdip_BitmapFromScreen(x "|" y "|" width "|" height)

    ;Apply_Merchant_ImageEffects(pBitmap)
    Gdip_SaveBitmapToFile(pBitmap, merchantImagePath)
    Gdip_DisposeImage(pBitmap)
    return PerformOCR(merchantImagePath)
}

Miscellaneous_CaptureScreen(x, y, width, height) {
    global miscellaneousImagePath
    miscellaneousImagePath := A_ScriptDir "\lib\miscellaneous_ocr_ss.jpg"
    pBitmap := Gdip_BitmapFromScreen(x "|" y "|" width "|" height)

    Apply_Merchant_ImageEffects(pBitmap)
    Gdip_SaveBitmapToFile(pBitmap, miscellaneousImagePath)
    Gdip_DisposeImage(pBitmap)
    return PerformOCR(miscellaneousImagePath)
}


CaptureScreenFromImage(imagePath_Retrieve) {
    capturePath := A_ScriptDir "\" imagePath_Retrieve

    if !FileExist(capturePath) {
        MsgBox, Image file does not exist duh: %capturePath%
        return
    }

    pBitmap := Gdip_CreateBitmapFromFile(capturePath)
    if !pBitmap {
        MsgBox, Failed to load image.
        return
    }

    Apply_Merchant_ImageEffects(pBitmap)
    Gdip_SaveBitmapToFile(pBitmap, capturePath)
    Gdip_DisposeImage(pBitmap)
    return PerformOCR(capturePath)
}



ApplyImageEffects(pBitmap) {
    effect := Gdip_CreateEffect(3,"2|0|0|0|0" . "|" . "0|1.5|0|0|0" . "|" . "0|0|1|0|0" . "|" . "0|0|0|1|0" . "|" . "0|0|0.2|0|1",0)
    effect2 := Gdip_CreateEffect(5, -80,250)
    effect3 := Gdip_CreateEffect(2,5,30)
    
    Gdip_BitmapApplyEffect(pBitmap,effect)
    Gdip_BitmapApplyEffect(pBitmap,effect2)
    Gdip_BitmapApplyEffect(pBitmap,effect3)
}


Apply_Merchant_ImageEffects(pBitmap) {
    effectSharpen := Gdip_CreateEffect(2, 2, 5)
    
    Gdip_BitmapApplyEffect(pBitmap, effectSharpen)
    Gdip_DisposeEffect(effectSharpen)
}


PerformOCR(imagePath) {
    global tesseractPath, outputPath
    RunWait, %tesseractPath% "%imagePath%" "%outputPath%" --oem 3 --psm 3, , Hide
    FileRead, ocrText, %outputPath%.txt
    return ocrText
}


; Example usage
CheckTesseractPath()

; CaptureScreen(5,908,212,25) ; here is you put your x,y,width,height
;CaptureScreenFromImage("merchant_ocr_ss.jpg")


