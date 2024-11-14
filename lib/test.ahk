#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

; Requires Windows 10 or later
GetOCRTextFromImage(imagePath) {
    ocr := ComObjCreate("MODI.Document")
    ocr.Create(imagePath)
    ocr.Ocr(9, True, True)
    text := ""
    for page in ocr.Images
        text .= page.Layout.Text
    return text
}

; Load and test OCR on an image file
testPath := A_ScriptDir . "\ss.jpg"
if !FileExist(testPath) {
    MsgBox, Error: ss.jpg not found in the directory.
} else {
    result := GetOCRTextFromImage(testPath)
    MsgBox, OCR Result: %result%
}
