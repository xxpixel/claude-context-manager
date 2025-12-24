#Requires -Version 5.1
<#
.SYNOPSIS
    Claude Context Manager - Windows Uninstallation Script (PowerShell)

.DESCRIPTION
    This script removes Claude Context Manager from your ~/.claude directory on Windows.
    It provides options to backup and preserve conversation data.

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
$BackupDir = Join-Path $env:USERPROFILE ".claude-context-backup-$(Get-Date -Format 'yyyyMMdd_HHmmss')"

#===============================================================================
# Helper Functions
#===============================================================================

function Write-Banner {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host "                                                                     " -ForegroundColor Cyan
    Write-Host "       Claude Context Manager - Uninstallation (PowerShell)          " -ForegroundColor Cyan
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
# Uninstallation Functions
#===============================================================================

function Confirm-Uninstall {
    Write-Step "1" "Confirmation"
    Write-Host ""

    Write-Warning "This will remove the following files:"
    Write-Host ""
    Write-Host "  Commands:"
    Write-Host "    - $ClaudeDir\commands\save-context.md"
    Write-Host "    - $ClaudeDir\commands\load-context.md"
    Write-Host "    - $ClaudeDir\commands\list-contexts.md"
    Write-Host "    - $ClaudeDir\commands\search-context.md"
    Write-Host ""
    Write-Host "  Skills:"
    Write-Host "    - $ClaudeDir\skills\context-manager\"
    Write-Host ""

    $response = Read-Host "Do you want to continue? (y/n)"
    if ($response -notmatch "^[Yy]") {
        Write-Info "Uninstallation cancelled"
        exit 0
    }

    Write-Host ""
}

function Backup-Conversations {
    Write-Step "2" "Checking saved conversations..."

    $conversationsDir = Join-Path $ClaudeDir "conversations"

    if (Test-Path $conversationsDir) {
        $mdFiles = Get-ChildItem -Path $conversationsDir -Filter "*.md" -ErrorAction SilentlyContinue
        $fileCount = ($mdFiles | Measure-Object).Count

        if ($fileCount -gt 0) {
            Write-Warning "Found $fileCount saved conversation(s)"

            $backupResponse = Read-Host "Do you want to backup conversations before uninstalling? (y/n)"
            if ($backupResponse -match "^[Yy]") {
                New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
                Copy-Item -Path $conversationsDir -Destination $BackupDir -Recurse -Force
                Write-Success "Conversations backed up to: $BackupDir\conversations"
            }

            $deleteResponse = Read-Host "Do you want to DELETE all saved conversations? (y/n)"
            if ($deleteResponse -match "^[Yy]") {
                Remove-Item -Path $conversationsDir -Recurse -Force
                Write-Success "Conversations deleted"
            } else {
                Write-Info "Conversations preserved at $conversationsDir"
            }
        } else {
            Write-Info "No conversation files found"
        }
    } else {
        Write-Info "No conversations directory found"
    }

    Write-Host ""
}

function Remove-Files {
    Write-Step "3" "Removing Claude Context Manager files..."

    $commandsDir = Join-Path $ClaudeDir "commands"
    $skillsDir = Join-Path $ClaudeDir "skills\context-manager"

    # Remove command files
    Write-Host "  Removing commands..."
    $commandFiles = @("save-context.md", "load-context.md", "list-contexts.md", "search-context.md")

    foreach ($cmd in $commandFiles) {
        $cmdPath = Join-Path $commandsDir $cmd
        if (Test-Path $cmdPath) {
            Remove-Item $cmdPath -Force
            Write-Success "  $cmd removed"
        } else {
            Write-Info "  $cmd not found (skipped)"
        }
    }

    # Remove skill directory
    Write-Host "  Removing skills..."
    if (Test-Path $skillsDir) {
        Remove-Item $skillsDir -Recurse -Force
        Write-Success "  context-manager skill removed"
    } else {
        Write-Info "  context-manager skill not found (skipped)"
    }

    Write-Host ""
}

function Remove-EmptyDirectories {
    Write-Step "4" "Cleaning up empty directories..."

    # Remove empty skills directory
    $skillsParentDir = Join-Path $ClaudeDir "skills"
    if (Test-Path $skillsParentDir) {
        $items = Get-ChildItem -Path $skillsParentDir -ErrorAction SilentlyContinue
        if (($items | Measure-Object).Count -eq 0) {
            Remove-Item $skillsParentDir -Force
            Write-Success "Removed empty skills directory"
        }
    }

    # Remove empty commands directory
    $commandsDir = Join-Path $ClaudeDir "commands"
    if (Test-Path $commandsDir) {
        $items = Get-ChildItem -Path $commandsDir -ErrorAction SilentlyContinue
        if (($items | Measure-Object).Count -eq 0) {
            Remove-Item $commandsDir -Force
            Write-Success "Removed empty commands directory"
        }
    }

    Write-Host ""
}

function Write-Complete {
    Write-Host ""
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host "                  Uninstallation Complete!                           " -ForegroundColor Green
    Write-Host "=====================================================================" -ForegroundColor Green
    Write-Host ""

    Write-Host "Claude Context Manager has been removed from your system."
    Write-Host ""

    if (Test-Path $BackupDir) {
        Write-Host "Backup location: " -ForegroundColor Cyan -NoNewline
        Write-Host $BackupDir
        Write-Host ""
    }

    Write-Host "Thank you for using Claude Context Manager!"
    Write-Host "If you have any feedback, please visit:"
    Write-Host "https://github.com/gaoziman/claude-context-manager/issues"
    Write-Host ""

    Write-Host "Note: Please restart Claude Code to apply changes." -ForegroundColor Yellow
    Write-Host ""
}

#===============================================================================
# Main
#===============================================================================

function Main {
    Write-Banner

    Confirm-Uninstall
    Backup-Conversations
    Remove-Files
    Remove-EmptyDirectories
    Write-Complete
}

# Run main function
Main
