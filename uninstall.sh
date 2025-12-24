#!/bin/bash

#===============================================================================
# Claude Context Manager - Uninstallation Script
#
# This script removes Claude Context Manager from your ~/.claude directory
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
BACKUP_DIR="$HOME/.claude-context-backup-$(date +%Y%m%d_%H%M%S)"

#===============================================================================
# Helper Functions
#===============================================================================

print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                                                                   ║"
    echo "║       🧠 Claude Context Manager - Uninstallation                  ║"
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
# Uninstallation
#===============================================================================

confirm_uninstall() {
    print_step "1" "Confirmation"

    echo ""
    print_warning "This will remove the following files:"
    echo ""
    echo "  Commands:"
    echo "    - ~/.claude/commands/save-context.md"
    echo "    - ~/.claude/commands/load-context.md"
    echo "    - ~/.claude/commands/list-contexts.md"
    echo "    - ~/.claude/commands/search-context.md"
    echo ""
    echo "  Skills:"
    echo "    - ~/.claude/skills/context-manager/"
    echo ""

    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Uninstallation cancelled"
        exit 0
    fi

    echo ""
}

backup_conversations() {
    print_step "2" "Checking saved conversations..."

    if [ -d "$CLAUDE_DIR/conversations" ] && [ "$(ls -A $CLAUDE_DIR/conversations 2>/dev/null)" ]; then
        local file_count=$(ls -1 "$CLAUDE_DIR/conversations"/*.md 2>/dev/null | wc -l)

        if [ "$file_count" -gt 0 ]; then
            print_warning "Found $file_count saved conversation(s)"
            read -p "Do you want to backup conversations before uninstalling? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                mkdir -p "$BACKUP_DIR"
                cp -r "$CLAUDE_DIR/conversations" "$BACKUP_DIR/"
                print_success "Conversations backed up to: $BACKUP_DIR/conversations"
            fi

            read -p "Do you want to DELETE all saved conversations? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$CLAUDE_DIR/conversations"
                print_success "Conversations deleted"
            else
                print_info "Conversations preserved at ~/.claude/conversations/"
            fi
        else
            print_info "No conversation files found"
        fi
    else
        print_info "No conversations directory found"
    fi

    echo ""
}

remove_files() {
    print_step "3" "Removing Claude Context Manager files..."

    # Remove command files
    echo "  Removing commands..."
    for cmd in save-context load-context list-contexts search-context; do
        if [ -f "$CLAUDE_DIR/commands/${cmd}.md" ]; then
            rm "$CLAUDE_DIR/commands/${cmd}.md"
            print_success "  ${cmd}.md removed"
        else
            print_info "  ${cmd}.md not found (skipped)"
        fi
    done

    # Remove skill directory
    echo "  Removing skills..."
    if [ -d "$CLAUDE_DIR/skills/context-manager" ]; then
        rm -rf "$CLAUDE_DIR/skills/context-manager"
        print_success "  context-manager skill removed"
    else
        print_info "  context-manager skill not found (skipped)"
    fi

    echo ""
}

cleanup_empty_dirs() {
    print_step "4" "Cleaning up empty directories..."

    # Remove empty skills directory
    if [ -d "$CLAUDE_DIR/skills" ] && [ -z "$(ls -A $CLAUDE_DIR/skills 2>/dev/null)" ]; then
        rmdir "$CLAUDE_DIR/skills"
        print_success "Removed empty skills directory"
    fi

    # Remove empty commands directory
    if [ -d "$CLAUDE_DIR/commands" ] && [ -z "$(ls -A $CLAUDE_DIR/commands 2>/dev/null)" ]; then
        rmdir "$CLAUDE_DIR/commands"
        print_success "Removed empty commands directory"
    fi

    echo ""
}

print_complete() {
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                  ✅ Uninstallation Complete!                      ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo "Claude Context Manager has been removed from your system."
    echo ""

    if [ -d "$BACKUP_DIR" ]; then
        echo -e "${CYAN}Backup location:${NC} $BACKUP_DIR"
        echo ""
    fi

    echo "Thank you for using Claude Context Manager!"
    echo "If you have any feedback, please visit:"
    echo "https://github.com/gaoziman/claude-context-manager/issues"
    echo ""

    echo -e "${YELLOW}Note: Please restart Claude Code to apply changes.${NC}"
    echo ""
}

#===============================================================================
# Main
#===============================================================================

main() {
    print_banner

    confirm_uninstall
    backup_conversations
    remove_files
    cleanup_empty_dirs
    print_complete
}

# Run main function
main "$@"
