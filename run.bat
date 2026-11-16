@echo off
setlocal enabledelayedexpansion

title BankCore-8086 DOSBox Runner

echo ===================================================
echo             BankCore-8086 Build and Run
echo ===================================================
echo.

set "DOSBOX_EXE="

:: 1. Check if DOSBox is in PATH
where dosbox >nul 2>nul
if %errorlevel% equ 0 (
    set "DOSBOX_EXE=dosbox"
    goto :found_dosbox
)

:: 2. Check standard installation directories
if exist "%ProgramFiles(x86)%\DOSBox-0.74-3\DOSBox.exe" (
    set "DOSBOX_EXE=%ProgramFiles(x86)%\DOSBox-0.74-3\DOSBox.exe"
    goto :found_dosbox
)

if exist "%ProgramFiles%\DOSBox-0.74-3\DOSBox.exe" (
    set "DOSBOX_EXE=%ProgramFiles%\DOSBox-0.74-3\DOSBox.exe"
    goto :found_dosbox
)

if exist "%LOCALAPPDATA%\Programs\DOSBox\DOSBox.exe" (
    set "DOSBOX_EXE=%LOCALAPPDATA%\Programs\DOSBox\DOSBox.exe"
    goto :found_dosbox
)

if exist "C:\DOSBox\dosbox.exe" (
    set "DOSBOX_EXE=C:\DOSBox\dosbox.exe"
    goto :found_dosbox
)

echo [!] DOSBox executable was not automatically detected on this system.
echo.
echo Please ensure DOSBox is installed or specify its full path below.
echo You can download DOSBox from: https://www.dosbox.com/download.php?main=1
echo.
set /p "DOSBOX_EXE=Enter path to dosbox.exe (or press Enter to exit): "
if "%DOSBOX_EXE%"=="" goto :exit

:found_dosbox
echo [*] Located DOSBox at: "%DOSBOX_EXE%"
echo [*] Mounting current directory: "%CD%"
echo.

:: Launch DOSBox, mount directory, and display shell ready for assembly
"%DOSBOX_EXE%" -c "mount c \"%CD%\"" -c "c:" -c "cls" -c "echo =========================================" -c "echo BankCore-8086 Ready" -c "echo To build with MASM: masm bank.asm; && link bank.obj; && bank.exe" -c "echo To build with TASM: tasm bank.asm && tlink bank.obj && bank.exe" -c "echo ========================================="

:exit
echo.
echo Process finished.
endlocal
