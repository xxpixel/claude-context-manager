**English** | [中文](./README.md)

## Claude Context Manager

**🧠 Session Context Management Tool for Claude Code | Save, Restore & Search Your AI Coding Sessions**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-blue.svg)]()
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-green.svg)]()
[![GitHub Stars](https://img.shields.io/github/stars/gaoziman/claude-context-manager)](https://github.com/gaoziman/claude-context-manager/stargazers)

Claude Context Manager enables you to save Claude Code session contexts anytime through custom slash commands, quickly restore previous work states in new sessions, and completely solve the pain of losing context due to API errors.

---

## ✨ Highlights

- 💾 **One-Click Save**: `/save-context` intelligently extracts key information including requirements, decisions, code, and progress
- 🔄 **Quick Restore**: `/load-context` loads historical context in new sessions, Claude immediately understands project background
- 📋 **Session Management**: `/list-contexts` view all saved sessions with timestamps accurate to seconds
- 🔍 **Full-Text Search**: `/search-context` search historical sessions by title, tags, or content
- 🧠 **Smart Detection**: Automatically identifies session types (analysis/development/debug/config) with corresponding extraction strategies
- 🏷️ **Auto Tagging**: Automatically generates tags based on tech stack, task type, etc.
- ✅ **Quality Check**: Built-in 8-point quality checklist ensures context completeness and recoverability

## 😫 What Problems Does It Solve?

When using Claude Code, have you ever encountered:

| Pain Point | Description |
|------------|-------------|
| 😱 **API Errors** | Forced to open a new window due to 400/500 errors |
| 💔 **Context Loss** | Hard-earned conversation context disappears instantly |
| 🔄 **Repeated Explanations** | Need to re-explain project background in new sessions |
| 📉 **Reduced Efficiency** | Continuity of complex tasks is broken |

**Claude Context Manager was born to solve these problems!**

## ⚡️ Quick Start

### Requirements

- Claude Code installed and working properly
- macOS / Linux / Windows operating system

### macOS / Linux

```bash
# Clone the repository
git clone https://github.com/gaoziman/claude-context-manager.git
cd claude-context-manager

# Run installation script
chmod +x install.sh
./install.sh
```

### Windows

**PowerShell (Recommended)**

```powershell
# Clone the repository
git clone https://github.com/gaoziman/claude-context-manager.git
cd claude-context-manager

# Set execution policy (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run installation script
.\scripts\windows\install.ps1
```

**Batch Script (Better Compatibility)**

```cmd
git clone https://github.com/gaoziman/claude-context-manager.git
cd claude-context-manager
scripts\windows\install.bat
```

### Verify Installation

After restarting Claude Code, type `/` to see if these commands appear:

```
/save-context     - Save session context
/load-context     - Load session context
/list-contexts    - List saved sessions
/search-context   - Search session contexts
```

## 📖 Usage

### Save Context

```bash
# Auto-generate title
/save-context

# Specify title
/save-context User Authentication Development
```

### List Sessions

```bash
/list-contexts
```

Output example:

```
📚 Saved Sessions (3 total)

| No.  | Date Time             | Title                    | Project     | Tags           |
|------|-----------------------|--------------------------|-------------|----------------|
| [1]  | 2025-12-24 16:30:45  | User Auth Development    | my-project  | #auth #JWT     |
| [2]  | 2025-12-24 14:15:22  | API Interface Design     | my-project  | #api #design   |
| [3]  | 2025-12-24 10:08:33  | Database Architecture    | my-project  | #db #analysis  |
```

### Load Context

```bash
# Load by number
/load-context 1

# Load by keyword
/load-context auth
```

### Search Context

```bash
# Search keywords
/search-context JWT

# Search tags
/search-context #authentication
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Installation Flow                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   📦 Project Repository              🏠 User Directory           │
│   claude-context-manager/            ~/.claude/                  │
│                                                                 │
│   .claude/commands/*.md    ════════►  commands/*.md             │
│   .claude/skills/          ════════►  skills/context-manager/   │
│   .claude/conversations/   ════════►  conversations/            │
│                                                                 │
│              install.sh automatically copies to user directory   │
│              Globally available after installation               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

| Platform | Config Directory |
|----------|------------------|
| macOS | `~/.claude/` → `/Users/username/.claude/` |
| Linux | `~/.claude/` → `/home/username/.claude/` |
| Windows | `%USERPROFILE%\.claude\` → `C:\Users\username\.claude\` |

## 📁 Project Structure

```
claude-context-manager/
├── install.sh              # macOS/Linux installation script
├── uninstall.sh            # macOS/Linux uninstallation script
├── scripts/
│   ├── mac/                # macOS/Linux scripts
│   │   ├── install.sh
│   │   └── uninstall.sh
│   └── windows/            # Windows scripts
│       ├── install.ps1     # PowerShell install
│       ├── uninstall.ps1   # PowerShell uninstall
│       ├── install.bat     # Batch install
│       └── uninstall.bat   # Batch uninstall
├── .claude/
│   ├── commands/           # Slash command definitions
│   ├── skills/             # Skill definitions
│   └── conversations/      # Session templates
├── docs/                   # Documentation
└── examples/               # Example files
```

## ⚙️ Configuration

Installed file structure:

```
~/.claude/
├── commands/                      # Slash commands (globally available)
│   ├── save-context.md
│   ├── load-context.md
│   ├── list-contexts.md
│   └── search-context.md
├── skills/context-manager/
│   └── SKILL.md                  # Skill definition
└── conversations/                 # Session storage
    ├── index.json                # Index file
    └── *.md                      # Saved sessions
```

## 💡 Best Practices

### When to Save?

| Scenario | Recommendation |
|----------|----------------|
| ✅ Completed feature development | Save immediately |
| ✅ Completed architecture analysis | Save immediately |
| ✅ Solved complex bug | Save immediately |
| ✅ See "Conversation compacted" | **Save immediately!** |
| ❌ Simple Q&A | No need to save |

### Recommended Workflow

```
Phase 1: Requirements Analysis → /save-context Requirements
    ↓
Phase 2: Architecture Design → /save-context Architecture
    ↓
Phase 3: Feature Development → /save-context Development
    ↓
Phase 4: Testing & Fixes → /save-context Testing Complete
```

## ❓ FAQ

**1. Commands not showing after installation?**
> You must **completely restart** Claude Code, not just minimize and reopen.

**2. Windows shows execution policy restriction?**
> Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

**3. ~/.claude directory doesn't exist?**
> Run `claude` command once first, or manually create with `mkdir -p ~/.claude`

**4. Saved content is incomplete?**
> Claude has context window limitations, early content in long conversations gets compressed. Tip: **Save immediately after completing important phases**.

**5. Can I delete the project directory after installation?**
> Yes, but it's recommended to keep it for future upgrades.

## 🛠️ Uninstall

**macOS / Linux**

```bash
./uninstall.sh
```

**Windows**

```powershell
.\scripts\windows\uninstall.ps1
# or
scripts\windows\uninstall.bat
```

The uninstall script will ask if you want to backup saved session data.

## 🤝 Contributing

Issues and Pull Requests are welcome!

1. Fork this repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Submit a Pull Request

## 📚 Documentation

- [Getting Started Guide](./docs/getting-started.md)
- [Installation Guide](./docs/installation.md)
- [Usage Guide](./docs/usage.md)
- [Configuration](./docs/configuration.md)
- [Best Practices](./docs/best-practices.md)
- [FAQ](./docs/faq.md)


## 📜 License

This project is licensed under the [MIT License](./LICENSE).

---

**If this project helps you, please give it a ⭐️ Star!**

Made with ❤️ by [Leo Coder](https://github.com/gaoziman)
