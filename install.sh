#!/bin/bash

#===============================================================================
# Claude Context Manager - Installation Script
#
# This script installs Claude Context Manager to your ~/.claude directory
#
# Author: Leo Coder (gaoziman)
# Repository: https://github.com/gaoziman/claude-context-manager
# License: MIT
#===============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$HOME/.claude-backup-$(date +%Y%m%d_%H%M%S)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#===============================================================================
# Helper Functions
#===============================================================================

print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                                                                   ║"
    echo "║       🧠 Claude Context Manager - Installation                    ║"
    echo "║                                                                   ║"
    echo "║       Save, manage, and restore your Claude Code sessions         ║"
    echo "║                                                                   ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}[Step $1]${NC} $2"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

#===============================================================================
# Pre-installation Checks
#===============================================================================

check_requirements() {
    print_step "1" "Checking requirements..."

    # Check if running on macOS or Linux
    if [[ "$OSTYPE" != "darwin"* ]] && [[ "$OSTYPE" != "linux"* ]]; then
        print_error "This script only supports macOS and Linux"
        exit 1
    fi
    print_success "Operating system: $(uname -s)"

    # Check if ~/.claude directory structure exists
    if [ -d "$CLAUDE_DIR" ]; then
        print_success "Found existing ~/.claude directory"
    else
        print_info "~/.claude directory will be created"
    fi

    echo ""
}

#===============================================================================
# Backup Existing Configuration
#===============================================================================

backup_existing() {
    print_step "2" "Checking for existing configuration..."

    local needs_backup=false

    # Check if commands directory exists with files
    if [ -d "$CLAUDE_DIR/commands" ] && [ "$(ls -A $CLAUDE_DIR/commands 2>/dev/null)" ]; then
        # Check for our specific command files
        for cmd in save-context load-context list-contexts search-context recover-context; do
            if [ -f "$CLAUDE_DIR/commands/${cmd}.md" ]; then
                needs_backup=true
                break
            fi
        done
    fi

    # Check if skills directory exists
    if [ -d "$CLAUDE_DIR/skills/context-manager" ]; then
        needs_backup=true
    fi

    if [ "$needs_backup" = true ]; then
        print_warning "Found existing context manager files"
        read -p "Do you want to backup existing files? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mkdir -p "$BACKUP_DIR"

            # Backup commands
            if [ -d "$CLAUDE_DIR/commands" ]; then
                for cmd in save-context load-context list-contexts search-context recover-context; do
                    if [ -f "$CLAUDE_DIR/commands/${cmd}.md" ]; then
                        cp "$CLAUDE_DIR/commands/${cmd}.md" "$BACKUP_DIR/" 2>/dev/null || true
                    fi
                done
            fi

            # Backup skills
            if [ -d "$CLAUDE_DIR/skills/context-manager" ]; then
                cp -r "$CLAUDE_DIR/skills/context-manager" "$BACKUP_DIR/" 2>/dev/null || true
            fi

            print_success "Backup created at: $BACKUP_DIR"
        else
            print_info "Skipping backup, will overwrite existing files"
        fi
    else
        print_success "No existing context manager files found"
    fi

    echo ""
}

#===============================================================================
# Installation
#===============================================================================

install_files() {
    print_step "3" "Installing Claude Context Manager..."

    # Create directories
    mkdir -p "$CLAUDE_DIR/commands"
    mkdir -p "$CLAUDE_DIR/skills/context-manager"
    mkdir -p "$CLAUDE_DIR/conversations"

    # Copy command files
    echo "  Installing commands..."
    cp "$SCRIPT_DIR/.claude/commands/save-context.md" "$CLAUDE_DIR/commands/"
    print_success "  save-context.md"

    cp "$SCRIPT_DIR/.claude/commands/load-context.md" "$CLAUDE_DIR/commands/"
    print_success "  load-context.md"

    cp "$SCRIPT_DIR/.claude/commands/list-contexts.md" "$CLAUDE_DIR/commands/"
    print_success "  list-contexts.md"

    cp "$SCRIPT_DIR/.claude/commands/search-context.md" "$CLAUDE_DIR/commands/"
    print_success "  search-context.md"

    cp "$SCRIPT_DIR/.claude/commands/recover-context.md" "$CLAUDE_DIR/commands/"
    print_success "  recover-context.md"

    # Copy skill files
    echo "  Installing skills..."
    cp "$SCRIPT_DIR/.claude/skills/context-manager/SKILL.md" "$CLAUDE_DIR/skills/context-manager/"
    print_success "  SKILL.md"

    # Initialize index.json if not exists
    if [ ! -f "$CLAUDE_DIR/conversations/index.json" ]; then
        echo "  Initializing conversation index..."
        cp "$SCRIPT_DIR/.claude/conversations/index.json" "$CLAUDE_DIR/conversations/"
        print_success "  index.json initialized"
    else
        print_info "  index.json already exists, keeping existing data"
    fi

    echo ""
}

#===============================================================================
# Post-installation
#===============================================================================

verify_installation() {
    print_step "4" "Verifying installation..."

    local all_good=true

    # Verify commands
    for cmd in save-context load-context list-contexts search-context recover-context; do
        if [ -f "$CLAUDE_DIR/commands/${cmd}.md" ]; then
            print_success "$cmd.md"
        else
            print_error "$cmd.md - NOT FOUND"
            all_good=false
        fi
    done

    # Verify skills
    if [ -f "$CLAUDE_DIR/skills/context-manager/SKILL.md" ]; then
        print_success "SKILL.md"
    else
        print_error "SKILL.md - NOT FOUND"
        all_good=false
    fi

    # Verify conversations directory
    if [ -d "$CLAUDE_DIR/conversations" ]; then
        print_success "conversations directory"
    else
        print_error "conversations directory - NOT FOUND"
        all_good=false
    fi

    echo ""

    if [ "$all_good" = true ]; then
        return 0
    else
        return 1
    fi
}

print_usage() {
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                    ✅ Installation Complete!                      ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo -e "${CYAN}Available Commands:${NC}"
    echo ""
    echo "  /save-context [title]     Save current session context"
    echo "  /list-contexts            List all saved contexts"
    echo "  /load-context [id]        Load a saved context"
    echo "  /search-context [keyword] Search saved contexts"
    echo "  /recover-context          Recover context from JSONL files"
    echo ""

    echo -e "${CYAN}Quick Start:${NC}"
    echo ""
    echo "  1. Start or restart Claude Code"
    echo "  2. Work on your project as usual"
    echo "  3. Run /save-context to save your progress"
    echo "  4. In a new session, run /load-context to restore"
    echo ""

    echo -e "${CYAN}Enable Auto-Save (Optional):${NC}"
    echo ""
    echo "  To enable auto-save and /recover-context features:"
    echo "  ./scripts/hooks/install-hooks.sh"
    echo ""

    echo -e "${CYAN}Documentation:${NC}"
    echo ""
    echo "  GitHub: https://github.com/gaoziman/claude-context-manager"
    echo "  Issues: https://github.com/gaoziman/claude-context-manager/issues"
    echo ""

    echo -e "${YELLOW}Note: Please restart Claude Code to activate the new commands.${NC}"
    echo ""
}

#===============================================================================
# Main
#===============================================================================

main() {
    print_banner

    check_requirements
    backup_existing
    install_files

    if verify_installation; then
        print_usage
    else
        print_error "Installation completed with errors. Please check the output above."
        exit 1
    fi
}

# Run main function
main "$@"
