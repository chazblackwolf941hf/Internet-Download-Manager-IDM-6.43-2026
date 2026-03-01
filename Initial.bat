@echo off
setlocal enabledelayedexpansion

:: =====================================================
::  Advanced Backup System with Integrity Check
::  Author: IT Automation Specialist
::  Version: 1.3
::  Purpose: Automated folder backup with verification
:: =====================================

:: Configuration
set "SOURCE_FOLDERS=C:\Users\%USERNAME%\Documents,C:\Projects\Current"
set "BACKUP_ROOT=D:\Backups"
set "LOG_FILE=%BACKUP_ROOT%\backup_log_%DATE:/=%.txt"
set "NOTIFICATION_FILE=%BACKUP_ROOT%\notifications.txt"
set "ZIP_TOOL=C:\Program Files\7-Zip\7z.exe"
set "MIN_ARCHIVE_SIZE_KB=100"

:: Create backup root if it doesn't exist
if not exist "%BACKUP_ROOT%" mkdir "%BACKUP_ROOT%"

:: Initialize log
echo [Backup System Started] %DATE% %TIME% >> "%LOG_FILE%"
echo ============================================== >> "%LOG_FILE%"

:: Function to create timestamp
call :GET_TIMESTAMP
set "TIMESTAMP=%YEAR%-%MONTH%-%DAY%_%HOUR%-%MINUTE%-%SECOND%"

:: Process each source folder
for %%F in (%SOURCE_FOLDERS%) do (
    call :BACKUP_FOLDER "%%~F"
)

:: Final notification
echo Backup process completed. Check log at: %LOG_FILE%
echo Notification file: %NOTIFICATION_FILE%

endlocal
exit /b

:: ======================================
:: Functions
:: ======================================

:GET_TIMESTAMP
    for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "DT=%%I"
    set "YEAR=%DT:~0,4%"
    set "MONTH=%DT:~4,2%"
    set "DAY=%DT:~6,2%"
    set "HOUR=%DT:~8,2%"
    set "MINUTE=%DT:~10,2%"
    set "SECOND=%DT:~12,2%"
exit /b

:BACKUP_FOLDER
    set "SOURCE_PATH=%~1"
    set "FOLDER_NAME=%~n1"

    :: Handle root directories (remove trailing backslash)
    if "%FOLDER_NAME%"=="" set "FOLDER_NAME=%~nx1"

    set "ARCHIVE_NAME=%BACKUP_ROOT%\%FOLDER_NAME%_%TIMESTAMP%.zip"
    echo. >> "%LOG_FILE%"
    echo [Processing: %SOURCE_PATH%] >> "%LOG_FILE%"

    :: Check if source exists
    if not exist "%SOURCE_PATH%" (
        echo ERROR: Source folder not found: %SOURCE_PATH% >> "%LOG_FILE%"
        echo [NOTIFICATION] Backup FAILED for %FOLDER_NAME%: Source not found >> "%NOTIFICATION_FILE%"
        exit /b 1
    )

    :: Create archive using 7-Zip
    echo Creating archive: %ARCHIVE_NAME% >> "%LOG_FILE%"
    "%ZIP_TOOL%" a -tzip "%ARCHIVE_NAME%" "%SOURCE_PATH%" -r >> "%LOG_FILE%" 2>&1

    :: Verify archive creation and size
    if exist "%ARCHIVE_NAME%" (
        for %%A in ("%ARCHIVE_NAME%") do set ARCHIVE_SIZE=%%~zA
        set /a ARCHIVE_SIZE_KB=!ARCHIVE_SIZE!/1024

        if !ARCHIVE_SIZE_KB! LSS %MIN_ARCHIVE_SIZE_KB% (
            echo WARNING: Archive size too small: !ARCHIVE_SIZE_KB! KB >> "%LOG_FILE%"
            echo [NOTIFICATION] Backup WARNING: %FOLDER_NAME% archive is unusually small >> "%NOTIFICATION_FILE%"
        ) else (
            echo SUCCESS: Backup created. Size: !ARCHIVE_SIZE_KB! KB >> "%LOG_FILE%"
            echo [NOTIFICATION] Backup COMPLETED for %FOLDER_NAME% (%ARCHIVE_SIZE_KB% KB) >> "%NOTIFICATION_FILE%"
        )
    ) else (
        echo ERROR: Failed to create archive for %SOURCE_PATH% >> "%LOG_FILE%"
        echo [NOTIFICATION] Backup FAILED for %FOLDER_NAME%: Archive creation failed >> "%NOTIFICATION_FILE%"
    )
exit /b

:: ======================================
:: End of Script
:: ======================================
