# Changelog

All notable changes to Claude Context Manager will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-24

### Added
- Initial release of Claude Context Manager
- `/save-context` command for saving session context
- `/load-context` command for loading saved contexts
- `/list-contexts` command for listing all contexts
- `/search-context` command for searching contexts
- Smart context extraction based on session type
- Intelligent tag generation
- Quality control checklist
- Context window limitation awareness
- Installation script (`install.sh`)
- Uninstallation script (`uninstall.sh`)
- Comprehensive SKILL.md documentation
- Chinese and English README

### Features
- **Session Type Detection**: Automatically detects analysis, development, debug, and config sessions
- **Smart Tagging**: Auto-generates relevant tags based on content
- **Quality Assurance**: Built-in quality checklist for context completeness
- **Time Precision**: Timestamps precise to seconds
- **Backup Support**: Installation script supports backing up existing configurations

## [Unreleased]

### Planned
- `/update-context` command for updating saved contexts
- `/delete-context` command for deleting contexts
- `/archive-context` command for archiving old contexts
- `/export-context` command for exporting to different formats
- `/merge-contexts` command for merging related contexts
- `/context-stats` command for statistics
- Web UI for context management
- VSCode extension integration
