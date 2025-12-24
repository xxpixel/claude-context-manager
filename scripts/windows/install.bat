@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

REM ===============================================================================
REM Claude Context Manager - Windows Installation Script (Batch)
REM
REM This script installs Claude Context Manager to your ~/.claude directory
REM
REM Author: Leo Coder (gaoziman)
REM Repository: https://github.com/gaoziman/claude-context-manager
REM License: MIT
REM ===============================================================================

REM Configuration
set "CLAUDE_DIR=%USERPROFILE%\.claude"
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%..\.."

REM Get timestamp for backup
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "datetime=%%I"
set "BACKUP_DIR=%USERPROFILE%\.claude-backup-%datetime:~0,8%_%datetime:~8,6%"

REM ===============================================================================
REM Banner
REM ===============================================================================

echo.
echo =====================================================================
echo.
echo        Claude Context Manager - Installation (Batch)
echo.
echo        Save, manage, and restore your Claude Code sessions
echo.
echo =====================================================================
echo.

REM ===============================================================================
REM Step 1: Check Requirements
REM ===============================================================================

echo [Step 1] Checking requirements...

REM Check Windows version
ver | find "Windows" >nul
if %errorlevel% neq 0 (
    echo [X] This script requires Windows
    exit /b 1
)
echo [OK] Operating system: Windows

REM Check if source files exist
if not exist "%PROJECT_ROOT%\.claude\commands\save-context.md" (
    echo [X] Source files not found
    echo [X] Please make sure you're running this script from the correct location
    exit /b 1
)
echo [OK] Source files found

REM Check if .claude directory exists
if exist "%CLAUDE_DIR%" (
    echo [OK] Found existing .claude directory
) else (
    echo [i] .claude directory will be created
)

echo.

REM ===============================================================================
REM Step 2: Backup Existing Files
REM ===============================================================================

echo [Step 2] Checking for existing configuration...

set "NEEDS_BACKUP=0"

REM Check for existing command files
if exist "%CLAUDE_DIR%\commands\save-context.md" set "NEEDS_BACKUP=1"
if exist "%CLAUDE_DIR%\commands\load-context.md" set "NEEDS_BACKUP=1"
if exist "%CLAUDE_DIR%\commands\list-contexts.md" set "NEEDS_BACKUP=1"
if exist "%CLAUDE_DIR%\commands\search-context.md" set "NEEDS_BACKUP=1"

REM Check for existing skills directory
if exist "%CLAUDE_DIR%\skills\context-manager" set "NEEDS_BACKUP=1"

if "%NEEDS_BACKUP%"=="1" (
    echo [!] Found existing context manager files
    set /p "BACKUP_CHOICE=Do you want to backup existing files? (y/n): "

    if /i "!BACKUP_CHOICE!"=="y" (
        mkdir "%BACKUP_DIR%" 2>nul

        REM Backup command files
        if exist "%CLAUDE_DIR%\commands\save-context.md" copy "%CLAUDE_DIR%\commands\save-context.md" "%BACKUP_DIR%\" >nul 2>&1
        if exist "%CLAUDE_DIR%\commands\load-context.md" copy "%CLAUDE_DIR%\commands\load-context.md" "%BACKUP_DIR%\" >nul 2>&1
        if exist "%CLAUDE_DIR%\commands\list-contexts.md" copy "%CLAUDE_DIR%\commands\list-contexts.md" "%BACKUP_DIR%\" >nul 2>&1
        if exist "%CLAUDE_DIR%\commands\search-context.md" copy "%CLAUDE_DIR%\commands\search-context.md" "%BACKUP_DIR%\" >nul 2>&1

        REM Backup skills directory
        if exist "%CLAUDE_DIR%\skills\context-manager" xcopy "%CLAUDE_DIR%\skills\context-manager" "%BACKUP_DIR%\context-manager\" /E /I /Q >nul 2>&1

        echo [OK] Backup created at: %BACKUP_DIR%
    ) else (
        echo [i] Skipping backup, will overwrite existing files
    )
) else (
    echo [OK] No existing context manager files found
)

echo.

REM ===============================================================================
REM Step 3: Install Files
REM ===============================================================================

echo [Step 3] Installing Claude Context Manager...

REM Create directories
if not exist "%CLAUDE_DIR%\commands" mkdir "%CLAUDE_DIR%\commands"
if not exist "%CLAUDE_DIR%\skills\context-manager" mkdir "%CLAUDE_DIR%\skills\context-manager"
if not exist "%CLAUDE_DIR%\conversations" mkdir "%CLAUDE_DIR%\conversations"

REM Copy command files
echo   Installing commands...

copy "%PROJECT_ROOT%\.claude\commands\save-context.md" "%CLAUDE_DIR%\commands\" >nul
if %errorlevel% equ 0 (
    echo [OK]   save-context.md
) else (
    echo [X]   Failed to copy save-context.md
)

copy "%PROJECT_ROOT%\.claude\commands\load-context.md" "%CLAUDE_DIR%\commands\" >nul
if %errorlevel% equ 0 (
    echo [OK]   load-context.md
) else (
    echo [X]   Failed to copy load-context.md
)

copy "%PROJECT_ROOT%\.claude\commands\list-contexts.md" "%CLAUDE_DIR%\commands\" >nul
if %errorlevel% equ 0 (
    echo [OK]   list-contexts.md
) else (
    echo [X]   Failed to copy list-contexts.md
)

copy "%PROJECT_ROOT%\.claude\commands\search-context.md" "%CLAUDE_DIR%\commands\" >nul
if %errorlevel% equ 0 (
    echo [OK]   search-context.md
) else (
    echo [X]   Failed to copy search-context.md
)

REM Copy skill files
echo   Installing skills...

copy "%PROJECT_ROOT%\.claude\skills\context-manager\SKILL.md" "%CLAUDE_DIR%\skills\context-manager\" >nul
if %errorlevel% equ 0 (
    echo [OK]   SKILL.md
) else (
    echo [X]   Failed to copy SKILL.md
)

REM Initialize index.json if not exists
if not exist "%CLAUDE_DIR%\conversations\index.json" (
    echo   Initializing conversation index...
    copy "%PROJECT_ROOT%\.claude\conversations\index.json" "%CLAUDE_DIR%\conversations\" >nul
    echo [OK]   index.json initialized
) else (
    echo [i]   index.json already exists, keeping existing data
)

echo.

REM ===============================================================================
REM Step 4: Verify Installation
REM ===============================================================================

echo [Step 4] Verifying installation...

set "ALL_GOOD=1"

REM Verify command files
if exist "%CLAUDE_DIR%\commands\save-context.md" (
    echo [OK] save-context.md
) else (
    echo [X] save-context.md - NOT FOUND
    set "ALL_GOOD=0"
)

if exist "%CLAUDE_DIR%\commands\load-context.md" (
    echo [OK] load-context.md
) else (
    echo [X] load-context.md - NOT FOUND
    set "ALL_GOOD=0"
)

if exist "%CLAUDE_DIR%\commands\list-contexts.md" (
    echo [OK] list-contexts.md
) else (
    echo [X] list-contexts.md - NOT FOUND
    set "ALL_GOOD=0"
)

if exist "%CLAUDE_DIR%\commands\search-context.md" (
    echo [OK] search-context.md
) else (
    echo [X] search-context.md - NOT FOUND
    set "ALL_GOOD=0"
)

REM Verify skill files
if exist "%CLAUDE_DIR%\skills\context-manager\SKILL.md" (
    echo [OK] SKILL.md
) else (
    echo [X] SKILL.md - NOT FOUND
    set "ALL_GOOD=0"
)

REM Verify conversations directory
if exist "%CLAUDE_DIR%\conversations" (
    echo [OK] conversations directory
) else (
    echo [X] conversations directory - NOT FOUND
    set "ALL_GOOD=0"
)

echo.

REM ===============================================================================
REM Complete
REM ===============================================================================

if "%ALL_GOOD%"=="1" (
    echo =====================================================================
    echo.
    echo                    Installation Complete!
    echo.
    echo =====================================================================
    echo.
    echo Available Commands:
    echo.
    echo   /save-context [title]     Save current session context
    echo   /list-contexts            List all saved contexts
    echo   /load-context [id]        Load a saved context
    echo   /search-context [keyword] Search saved contexts
    echo.
    echo Quick Start:
    echo.
    echo   1. Start or restart Claude Code
    echo   2. Work on your project as usual
    echo   3. Run /save-context to save your progress
    echo   4. In a new session, run /load-context to restore
    echo.
    echo Installation Location:
    echo   %CLAUDE_DIR%
    echo.
    echo Documentation:
    echo   GitHub: https://github.com/gaoziman/claude-context-manager
    echo.
    echo Note: Please restart Claude Code to activate the new commands.
    echo.
) else (
    echo [X] Installation completed with errors. Please check the output above.
    exit /b 1
)

endlocal
pause
