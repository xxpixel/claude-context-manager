@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

REM ===============================================================================
REM Claude Context Manager - Windows Uninstallation Script (Batch)
REM
REM This script removes Claude Context Manager from your ~/.claude directory
REM
REM Author: Leo Coder (gaoziman)
REM Repository: https://github.com/gaoziman/claude-context-manager
REM License: MIT
REM ===============================================================================

REM Configuration
set "CLAUDE_DIR=%USERPROFILE%\.claude"

REM Get timestamp for backup
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "datetime=%%I"
set "BACKUP_DIR=%USERPROFILE%\.claude-context-backup-%datetime:~0,8%_%datetime:~8,6%"
set "BACKUP_CREATED=0"

REM ===============================================================================
REM Banner
REM ===============================================================================

echo.
echo =====================================================================
echo.
echo        Claude Context Manager - Uninstallation (Batch)
echo.
echo =====================================================================
echo.

REM ===============================================================================
REM Step 1: Confirmation
REM ===============================================================================

echo [Step 1] Confirmation
echo.
echo [!] This will remove the following files:
echo.
echo   Commands:
echo     - %CLAUDE_DIR%\commands\save-context.md
echo     - %CLAUDE_DIR%\commands\load-context.md
echo     - %CLAUDE_DIR%\commands\list-contexts.md
echo     - %CLAUDE_DIR%\commands\search-context.md
echo.
echo   Skills:
echo     - %CLAUDE_DIR%\skills\context-manager\
echo.

set /p "CONFIRM=Do you want to continue? (y/n): "
if /i not "%CONFIRM%"=="y" (
    echo [i] Uninstallation cancelled
    goto :end
)

echo.

REM ===============================================================================
REM Step 2: Backup Conversations
REM ===============================================================================

echo [Step 2] Checking saved conversations...

set "CONV_DIR=%CLAUDE_DIR%\conversations"

if exist "%CONV_DIR%" (
    REM Count .md files
    set "FILE_COUNT=0"
    for %%f in ("%CONV_DIR%\*.md") do set /a FILE_COUNT+=1

    if !FILE_COUNT! gtr 0 (
        echo [!] Found !FILE_COUNT! saved conversation(s^)

        set /p "BACKUP_CONV=Do you want to backup conversations before uninstalling? (y/n): "
        if /i "!BACKUP_CONV!"=="y" (
            mkdir "%BACKUP_DIR%" 2>nul
            xcopy "%CONV_DIR%" "%BACKUP_DIR%\conversations\" /E /I /Q >nul 2>&1
            set "BACKUP_CREATED=1"
            echo [OK] Conversations backed up to: %BACKUP_DIR%\conversations
        )

        set /p "DELETE_CONV=Do you want to DELETE all saved conversations? (y/n): "
        if /i "!DELETE_CONV!"=="y" (
            rmdir /s /q "%CONV_DIR%" 2>nul
            echo [OK] Conversations deleted
        ) else (
            echo [i] Conversations preserved at %CONV_DIR%
        )
    ) else (
        echo [i] No conversation files found
    )
) else (
    echo [i] No conversations directory found
)

echo.

REM ===============================================================================
REM Step 3: Remove Files
REM ===============================================================================

echo [Step 3] Removing Claude Context Manager files...

REM Remove command files
echo   Removing commands...

if exist "%CLAUDE_DIR%\commands\save-context.md" (
    del "%CLAUDE_DIR%\commands\save-context.md" >nul 2>&1
    echo [OK]   save-context.md removed
) else (
    echo [i]   save-context.md not found (skipped^)
)

if exist "%CLAUDE_DIR%\commands\load-context.md" (
    del "%CLAUDE_DIR%\commands\load-context.md" >nul 2>&1
    echo [OK]   load-context.md removed
) else (
    echo [i]   load-context.md not found (skipped^)
)

if exist "%CLAUDE_DIR%\commands\list-contexts.md" (
    del "%CLAUDE_DIR%\commands\list-contexts.md" >nul 2>&1
    echo [OK]   list-contexts.md removed
) else (
    echo [i]   list-contexts.md not found (skipped^)
)

if exist "%CLAUDE_DIR%\commands\search-context.md" (
    del "%CLAUDE_DIR%\commands\search-context.md" >nul 2>&1
    echo [OK]   search-context.md removed
) else (
    echo [i]   search-context.md not found (skipped^)
)

REM Remove skill directory
echo   Removing skills...

if exist "%CLAUDE_DIR%\skills\context-manager" (
    rmdir /s /q "%CLAUDE_DIR%\skills\context-manager" >nul 2>&1
    echo [OK]   context-manager skill removed
) else (
    echo [i]   context-manager skill not found (skipped^)
)

echo.

REM ===============================================================================
REM Step 4: Cleanup Empty Directories
REM ===============================================================================

echo [Step 4] Cleaning up empty directories...

REM Remove empty skills directory
if exist "%CLAUDE_DIR%\skills" (
    dir /b "%CLAUDE_DIR%\skills" 2>nul | findstr "." >nul
    if errorlevel 1 (
        rmdir "%CLAUDE_DIR%\skills" 2>nul
        echo [OK] Removed empty skills directory
    )
)

REM Remove empty commands directory
if exist "%CLAUDE_DIR%\commands" (
    dir /b "%CLAUDE_DIR%\commands" 2>nul | findstr "." >nul
    if errorlevel 1 (
        rmdir "%CLAUDE_DIR%\commands" 2>nul
        echo [OK] Removed empty commands directory
    )
)

echo.

REM ===============================================================================
REM Complete
REM ===============================================================================

echo =====================================================================
echo.
echo                  Uninstallation Complete!
echo.
echo =====================================================================
echo.
echo Claude Context Manager has been removed from your system.
echo.

if "%BACKUP_CREATED%"=="1" (
    echo Backup location: %BACKUP_DIR%
    echo.
)

echo Thank you for using Claude Context Manager!
echo If you have any feedback, please visit:
echo https://github.com/gaoziman/claude-context-manager/issues
echo.
echo Note: Please restart Claude Code to apply changes.
echo.

:end
endlocal
pause
