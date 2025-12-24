#Requires -Version 5.1
<#
.SYNOPSIS
    Claude Context Manager - Windows Installation Script (PowerShell)

.DESCRIPTION
    This script installs Claude Context Manager to your ~/.claude directory on Windows.
    It copies command files, skill files, and initializes the conversation index.

.AUTHOR
    Leo Coder (gaoziman)

.LINK
    https://github.com/gaoziman/claude-context-manager

.LICENSE
    MIT
#>

#===============================================================================
# Configuration
#===============================================================================

$ErrorActionPreference = "Stop"

# Paths
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$BackupDir = Join-Path $env:USERPROFILE ".claude-backup-$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)

#===============================================================================
# Helper Functions
#===============================================================================

function Write-Banner {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host "                                                                     " -ForegroundColor Cyan
    Write-Host "       Claude Context Manager - Installation (PowerShell)            " -ForegroundColor Cyan
    Write-Host "                                                                     " -ForegroundColor Cyan
    Write-Host "       Save, manage, and restore your Claude Code sessions           " -ForegroundColor Cyan
    Write-Host "                                                                     " -ForegroundColor Cyan
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$StepNumber, [string]$Message)
    Write-Host "[Step $StepNumber] " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[!] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Error {
    param([string]$Message)
    Write-Host "[X] " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Write-Info {
    param([string]$Message)
    Write-Host "[i] " -ForegroundColor Cyan -NoNewline
    Write-Host $Message
}

#===============================================================================
# Pre-installation Checks
#===============================================================================

function Test-Requirements {
    Write-Step "1" "Checking requirements..."

    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    Write-Success "PowerShell version: $($psVersion.Major).$($psVersion.Minor)"

    # Check if ~/.claude directory exists
    if (Test-Path $ClaudeDir) {
        Write-Success "Found existing .claude directory: $ClaudeDir"
    } else {
        Write-Info ".claude directory will be created: $ClaudeDir"
    }

    # Check if source files exist
    $sourceCommandsDir = Join-Path $ProjectRoot ".claude\commands"
    if (-not (Test-Path $sourceCommandsDir)) {
        Write-Error "Source files not found at: $sourceCommandsDir"
        Write-Error "Please make sure you're running this script from the correct location."
        exit 1
    }
    Write-Success "Source files found"

    Write-Host ""
}

#===============================================================================
# Backup Existing Configuration
#===============================================================================

function Backup-ExistingFiles {
    Write-Step "2" "Checking for existing configuration..."

    $needsBackup = $false
    $commandFiles = @("save-context.md", "load-context.md", "list-contexts.md", "search-context.md")

    # Check for existing command files
    $commandsDir = Join-Path $ClaudeDir "commands"
    if (Test-Path $commandsDir) {
        foreach ($cmd in $commandFiles) {
            $cmdPath = Join-Path $commandsDir $cmd
            if (Test-Path $cmdPath) {
                $needsBackup = $true
                break
            }
        }
    }

    # Check for existing skills directory
    $skillsDir = Join-Path $ClaudeDir "skills\context-manager"
    if (Test-Path $skillsDir) {
        $needsBackup = $true
    }

    if ($needsBackup) {
        Write-Warning "Found existing context manager files"
        $response = Read-Host "Do you want to backup existing files? (y/n)"

        if ($response -match "^[Yy]") {
            # Create backup directory
            New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

            # Backup command files
            if (Test-Path $commandsDir) {
                foreach ($cmd in $commandFiles) {
                    $cmdPath = Join-Path $commandsDir $cmd
                    if (Test-Path $cmdPath) {
                        Copy-Item $cmdPath -Destination $BackupDir -Force
                    }
                }
            }

            # Backup skills directory
            if (Test-Path $skillsDir) {
                Copy-Item $skillsDir -Destination $BackupDir -Recurse -Force
            }

            Write-Success "Backup created at: $BackupDir"
        } else {
            Write-Info "Skipping backup, will overwrite existing files"
        }
    } else {
        Write-Success "No existing context manager files found"
    }

    Write-Host ""
}

#===============================================================================
# Installation
#===============================================================================

function Install-Files {
    Write-Step "3" "Installing Claude Context Manager..."

    # Create directories
    $commandsDir = Join-Path $ClaudeDir "commands"
    $skillsDir = Join-Path $ClaudeDir "skills\context-manager"
    $conversationsDir = Join-Path $ClaudeDir "conversations"

    New-Item -ItemType Directory -Path $commandsDir -Force | Out-Null
    New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
    New-Item -ItemType Directory -Path $conversationsDir -Force | Out-Null

    # Source paths
    $sourceCommands = Join-Path $ProjectRoot ".claude\commands"
    $sourceSkills = Join-Path $ProjectRoot ".claude\skills\context-manager"
    $sourceConversations = Join-Path $ProjectRoot ".claude\conversations"

    # Copy command files
    Write-Host "  Installing commands..."
    $commandFiles = @("save-context.md", "load-context.md", "list-contexts.md", "search-context.md")
    foreach ($cmd in $commandFiles) {
        $sourcePath = Join-Path $sourceCommands $cmd
        $destPath = Join-Path $commandsDir $cmd
        Copy-Item $sourcePath -Destination $destPath -Force
        Write-Success "  $cmd"
    }

    # Copy skill files
    Write-Host "  Installing skills..."
    $skillSource = Join-Path $sourceSkills "SKILL.md"
    $skillDest = Join-Path $skillsDir "SKILL.md"
    Copy-Item $skillSource -Destination $skillDest -Force
    Write-Success "  SKILL.md"

    # Initialize index.json if not exists
    $indexPath = Join-Path $conversationsDir "index.json"
    if (-not (Test-Path $indexPath)) {
        Write-Host "  Initializing conversation index..."
        $indexSource = Join-Path $sourceConversations "index.json"
        Copy-Item $indexSource -Destination $indexPath -Force
        Write-Success "  index.json initialized"
    } else {
        Write-Info "  index.json already exists, keeping existing data"
    }

    Write-Host ""
}

#===============================================================================
# Post-installation
#===============================================================================

function Test-Installation {
    Write-Step "4" "Verifying installation..."

    $allGood = $true
    $commandsDir = Join-Path $ClaudeDir "commands"
    $skillsDir = Join-Path $ClaudeDir "skills\context-manager"
    $conversationsDir = Join-Path $ClaudeDir "conversations"

    # Verify commands
    $commandFiles = @("save-context.md", "load-context.md", "list-contexts.md", "search-context.md")
    foreach ($cmd in $commandFiles) {
        $cmdPath = Join-Path $commandsDir $cmd
        if (Test-Path $cmdPath) {
            Write-Success $cmd
        } else {
            Write-Error "$cmd - NOT FOUND"
            $allGood = $false
        }
    }

    # Verify skills
    $skillPath = Join-Path $skillsDir "SKILL.md"
    if (Test-Path $skillPath) {
        Write-Success "SKILL.md"
    } else {
        Write-Error "SKILL.md - NOT FOUND"
        $allGood = $false
    }

    # Verify conversations directory
    if (Test-Path $conversationsDir) {
        Write-Success "conversations directory"
    } else {
        Write-Error "conversations directory - NOT FOUND"
        $allGood = $false
    }

    Write-Host ""
    return $allGood
}

function Write-Usage {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host "                    Installation Complete!                           " -ForegroundColor Green
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host ""

    Write-Host "Available Commands:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  /save-context [title]     Save current session context"
    Write-Host "  /list-contexts            List all saved contexts"
    Write-Host "  /load-context [id]        Load a saved context"
    Write-Host "  /search-context [keyword] Search saved contexts"
    Write-Host ""

    Write-Host "Quick Start:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Start or restart Claude Code"
    Write-Host "  2. Work on your project as usual"
    Write-Host "  3. Run /save-context to save your progress"
    Write-Host "  4. In a new session, run /load-context to restore"
    Write-Host ""

    Write-Host "Installation Location:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  $ClaudeDir"
    Write-Host ""

    Write-Host "Documentation:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  GitHub: https://github.com/gaoziman/claude-context-manager"
    Write-Host "  Issues: https://github.com/gaoziman/claude-context-manager/issues"
    Write-Host ""

    Write-Host "Note: Please restart Claude Code to activate the new commands." -ForegroundColor Yellow
    Write-Host ""
}

#===============================================================================
# Main
#===============================================================================

function Main {
    Write-Banner

    Test-Requirements
    Backup-ExistingFiles
    Install-Files

    if (Test-Installation) {
        Write-Usage
    } else {
        Write-Error "Installation completed with errors. Please check the output above."
        exit 1
    }
}

# Run main function
Main
