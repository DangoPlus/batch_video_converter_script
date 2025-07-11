@echo off
setlocal enabledelayedexpansion

:: =================================================================================
:: AMD Hardware Accelerated Transcoder - V14 (Definitive Core-Rewrite)
:: Author: Gemini & User Collaboration
:: Version: 14.0
:: Date: 2025-07-11
:: UPDATE: The core loop logic has been completely rebuilt to use a direct
::         FOR /R loop, bypassing the file-based loop that caused all
::         previous variable expansion failures. This is the most direct and
::         robust approach to guarantee success.
:: =================================================================================

echo.
echo =======================================================================
echo ==  AMD AMF Video Batch Transcoder (V14 - Definitive Core-Rewrite)   ==
echo =======================================================================
echo.

:: ################################################################################
:: #
:: #                            USER CONFIGURATION
:: #
:: ################################################################################

:: --- 1. Path Settings ---
SET "sourceFolder=D:\testv"
SET "outputFolder=D:\testout"
SET "originalsFolder=D:\Original_Files_Backup"

:: --- 2. Transcoding Quality ---
SET "qualityPreset=balanced"

:: --- 3. Resolution Scaling ---
SET "outputResolution="

:: --- 4. Audio Processing ---
rem SET "audioCommand=-c:a copy"
SET "audioCommand=-c:a aac -b:a 192k"

:: ################################################################################
:: #                      CORE SCRIPT LOGIC (DO NOT MODIFY)
:: ################################################################################

:: --- Path Sanitization ---
if "!sourceFolder:~-1!"=="\" SET "sourceFolder=!sourceFolder:~0,-1!"

:: --- Internal Variables ---
SET "logFile=%~dp0completed_list.log"

:: --- Environment Check ---
echo [INFO] Checking for FFmpeg...
where ffmpeg >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] ffmpeg.exe not found in system PATH.
    pause
    exit /b
)
echo [SUCCESS] FFmpeg environment is OK.
echo.

:: --- Folder Creation ---
if not exist "%outputFolder%" (echo [INFO] Creating output folder... & mkdir "%outputFolder%")
if not exist "%originalsFolder%" (echo [INFO] Creating backup folder... & mkdir "%originalsFolder%")
if not exist "%logFile%" (echo [INFO] Creating log file... & type nul > "%logFile%")

:: --- Processing Tasks ---
echo [PROCESS] Starting conversion tasks...
echo.

:: =========================================================================
:: ===           ROBUST DIRECT-LOOP LOGIC (V14)                          ===
:: =========================================================================
for /r "%sourceFolder%" %%I in (*.mkv, *.mp4, *.mov, *.avi, *.flv, *.webm) do (
    
    :: Check if the file has already been processed
    findstr /L /X /C:"%%I" "%logFile%" >nul
    
    :: If errorlevel is 1, it means the file was NOT found in the log, so we process it.
    if !errorlevel! equ 1 (
    
        :: 1. Safely extract the clean components from the original full path
        set "fullPath=%%I"
        set "sourceFileDir=%%~dpI"
        set "baseName=%%~nI"
        set "fileExt=%%~xI"

        :: 2. Safely calculate the subdirectory structure
        set "subDirs=!sourceFileDir:%sourceFolder%=!"

        :: 3. Determine the output extension
        if /i "!fileExt!"==".mkv" (
            set "outputExtension=.mkv"
        ) else (
            set "outputExtension=.mp4"
        )

        :: 4. Rebuild the final output path from the clean, safe components
        set "finalOutputDir=%outputFolder%!subDirs!"
        set "outputFile=!finalOutputDir!!baseName!!outputExtension!"
        
        :: Create the destination sub-directory if it doesn't exist
        if not exist "!finalOutputDir!" mkdir "!finalOutputDir!"
        
        set "scaleFilterCommand="
        if not "!outputResolution%"=="" (
            set "scaleFilterCommand=-vf scale=!outputResolution!"
        )

        echo ----------------------------------------------------------------------
        echo [CONVERTING] File: !baseName!!fileExt!
        echo [FROM]       Path: !fullPath!
        echo [TO]         Path: !outputFile!
        echo ----------------------------------------------------------------------

        :: --- FFmpeg Core Command ---
        ffmpeg -hide_banner -hwaccel dxva2 -i "%%I" !scaleFilterCommand! -map 0 -c:v hevc_amf -quality !qualityPreset! !audioCommand! -c:s copy -y "!outputFile!"

        if not !errorlevel! equ 0 (
            echo. & echo [ERROR] FAILED to convert: !baseName!!fileExt! & echo.
        ) else (
            echo.
            echo [SUCCESS] Converted successfully: !baseName!!fileExt!
            
            :: Rebuild backup path with the same robust logic
            set "backupDir=%originalsFolder%!subDirs!"
            set "backupFile=!backupDir!!baseName!!fileExt!"
            
            if not exist "!backupDir!" mkdir "!backupDir!"
            
            echo [MOVING] Moving original file to backup folder...
            move "%%I" "!backupFile!" >nul
            
            :: Log the file as completed
            echo %%I >> "%logFile%"
            echo.
        )
    )
)

echo [PROCESS] All tasks are done.

:end
echo.
echo =======================================================================
echo ==                        Execution Finished                         ==
echo =======================================================================
pause
