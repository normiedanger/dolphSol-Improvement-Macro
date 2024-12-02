@echo off

set "PYTHON_URL=https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe"
set "TESSERACT_URL=https://github.com/tesseract-ocr/tesseract/releases/download/5.5.0/tesseract-ocr-w64-setup-5.5.0.20241111.exe"

set "PYTHON_INSTALLER=python-3.12.7-amd64.exe"
set "TESSERACT_INSTALLER=tesseract-ocr-w64-setup.exe"

set "AHK_URL=https://www.autohotkey.com/download/ahk-install.exe"
set "VSCODE_URL=https://update.code.visualstudio.com/latest/win32-x64-user/stable"

set "AHK_INSTALLER=ahk-install.exe"
set "VSCODE_INSTALLER=VSCodeSetup.exe"

:menu
cls
echo ============================================
echo Improvement Sol's Macro Setup (Noteab)
echo ============================================
echo [1] Download AutoHotkey v1.1 Installer
echo [2] Download Visual Studio Code Installer
echo [3] Download Python and Tesseract Installers
echo [4] Install required Python Packages
echo [5] Exit
echo ============================================
set /p "choice=Choose an option (1/2/3/4/5): "

if "%choice%"=="1" goto download_ahk
if "%choice%"=="2" goto download_vscode
if "%choice%"=="3" goto download_installers
if "%choice%"=="4" goto install_packages
if "%choice%"=="5" exit
echo Invalid option. Please choose 1, 2, 3, 4, or 5.
pause
goto menu

:download_ahk
cls
echo Downloading AutoHotkey v1.1 installer...
curl -L -o "%AHK_INSTALLER%" "%AHK_URL%"
if errorlevel 1 (
    echo Failed to download AutoHotkey installer. Check your internet connection or URL.
    pause
    exit /b
)

echo ============================================
echo AutoHotkey installer downloaded successfully.
echo Please run "%AHK_INSTALLER%" manually.
echo ============================================
pause
goto menu

:download_vscode
cls
echo Downloading Visual Studio Code installer...
curl -L -o "%VSCODE_INSTALLER%" "%VSCODE_URL%"
if errorlevel 1 (
    echo Failed to download Visual Studio Code installer. Check your internet connection or URL.
    pause
    exit /b
)

echo ============================================
echo Visual Studio Code installer downloaded successfully.
echo Please run "%VSCODE_INSTALLER%" manually.
echo ============================================
pause
goto menu


:download_installers
cls

where curl >nul 2>&1
if errorlevel 1 (
    echo Curl is not installed on your system. Please install curl or download the files manually.
    pause
    exit /b
)

echo Downloading Python 3.12.7 installer...
curl -L -o "%PYTHON_INSTALLER%" "%PYTHON_URL%"
if errorlevel 1 (
    echo Failed to download Python installer. Check your internet connection or URL.
    pause
    exit /b
)

echo ============================================
echo Python installer downloaded successfully.
echo Please run "%PYTHON_INSTALLER%" manually.
echo IMPORTANT: During installation, ensure you enable the "Add Python to PATH" option.
echo ============================================
pause

echo Downloading Tesseract 5.5.0 installer...
curl -L -o "%TESSERACT_INSTALLER%" "%TESSERACT_URL%"
if errorlevel 1 (
    echo Failed to download Tesseract installer. Check your internet connection or URL.
    pause
    exit /b
)

echo ============================================
echo Tesseract installer downloaded successfully.
echo Please run "%TESSERACT_INSTALLER%" manually.
echo ============================================
pause
goto menu

:install_packages
cls

echo Installing required Python packages...
python -m pip --version >nul 2>&1
if errorlevel 1 (
    echo Pip is not installed. Attempting to install pip...
    python -m ensurepip --upgrade
    if errorlevel 1 (
        echo Failed to install pip. Please check your Python installation.
        pause
        goto menu
    )
)

python -m pip install --upgrade pip
if exist "requirements.txt" (
    python -m pip install -r requirements.txt
) else (
    echo ============================================
    echo requirements.txt not found in the current directory.
    echo Please create a requirements.txt file with the required packages listed.
    echo ============================================
    pause
    goto menu
)

if errorlevel 1 (
    echo Failed to install one or more Python packages. Please check your internet connection or package names.
    pause
    goto menu
)

echo ============================================
echo All required Python packages installed successfully.
echo ============================================
pause
goto menu
