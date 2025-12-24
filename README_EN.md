<div align="center">

# 🧠 Claude Context Manager

**Session Context Management Tool for Claude Code**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-blue.svg)]()
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-green.svg)]()

English | [简体中文](./README.md)

</div>

---

## 🎯 What is this?

**Claude Context Manager** is a session context management tool designed for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) users. It helps you:

- 💾 **Save** the complete context of your current session
- 📂 **Manage** all saved historical sessions
- 🔄 **Restore** previous work states in new sessions
- 🔍 **Search** historical sessions to quickly find relevant content

## 😫 What Problem Does It Solve?

Have you ever encountered these issues while using Claude Code?

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  😱 API errors (like 400 parameter errors) force you to open   │
│     a new window                                                │
│                                                                 │
│  💔 Hard-earned conversation context lost instantly             │
│                                                                 │
│  🔄 Need to re-explain project background and technical         │
│     decisions in new sessions                                   │
│                                                                 │
│  📉 Continuity of complex tasks broken, efficiency drops        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Claude Context Manager** was born to solve these problems!

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🧠 **Smart Extraction** | Auto-detects session types (analysis/development/debug/config) and applies corresponding strategies |
| 🏷️ **Intelligent Tagging** | Auto-generates tags based on tech stack, task type, project, etc. |
| ✅ **Quality Control** | Built-in 8-point quality checklist ensures context completeness |
| ⏱️ **Precise Timestamps** | Timestamps accurate to seconds for easy timeline tracking |
| 🔍 **Full-text Search** | Supports searching titles, tags, and content |
| 📊 **Structured Storage** | Markdown + YAML frontmatter, human-readable |

## 🚀 Quick Start

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/gaoziman/claude-context-manager.git

# 2. Enter directory
cd claude-context-manager

# 3. Run installation script
chmod +x install.sh
./install.sh
```

### Verify Installation

After restarting Claude Code, type `/` to see if these commands appear:

```
/save-context     - Save session context
/load-context     - Load session context
/list-contexts    - List saved contexts
/search-context   - Search contexts
```

## 📖 Usage Guide

### 1️⃣ Save Context

When you complete an important work phase, run:

```
/save-context
```

Or specify a title:

```
/save-context User Authentication Development
```

The system will automatically:
- Analyze current session content
- Extract key information (decisions, code, progress, etc.)
- Generate a structured context file
- Update the index for future retrieval

### 2️⃣ List All Sessions

```
/list-contexts
```

Example output:

```
📚 Saved Sessions (3 total)

| No.  | Date Time           | Title                    | Project      | Tags           |
|------|---------------------|--------------------------|--------------|----------------|
| [1]  | 2025-12-24 14:30:25 | User Auth Development    | my-project   | #auth #JWT     |
| [2]  | 2025-12-24 10:15:08 | Architecture Analysis    | my-project   | #arch #analysis|
| [3]  | 2025-12-23 16:45:30 | Bug Fix Record           | my-project   | #bug #fix      |
```

### 3️⃣ Load Context

```
/load-context 1
```

Or use keywords:

```
/load-context auth
```

After loading, Claude will display the complete context and provide intelligent suggestions for what you can continue doing.

### 4️⃣ Search Contexts

```
/search-context JWT
```

Supports searching:
- Titles
- Tags (use `#tag` format)
- Summary content

## 📁 File Structure

After installation, the following structure is created under `~/.claude/`:

```
~/.claude/
├── commands/                      # Command files
│   ├── save-context.md
│   ├── load-context.md
│   ├── list-contexts.md
│   └── search-context.md
├── skills/
│   └── context-manager/
│       └── SKILL.md              # Skill definition
└── conversations/                # Session storage
    ├── index.json                # Index file
    └── *.md                      # Session files
```

## 🎨 Session File Format

Each saved session is a Markdown file:

```markdown
---
id: "uuid"
title: "Session Title"
project: "Project Name"
created_at: "2025-12-24T14:30:25+08:00"
tags: ["tag1", "tag2"]
summary: "One-line summary"
---

# Session Context: [Title]

## 📋 Session Overview
...

## 🎯 User Requirements
...

## 📊 Core Content
...

## 💡 Key Decisions
...

## ✅ Task Progress
...

## 🚀 Next Steps Guide
...
```

## 💡 Best Practices

### When to Save?

| Scenario | Recommendation |
|----------|----------------|
| ✅ Completed feature development | Save immediately |
| ✅ Completed architecture analysis | Save immediately |
| ✅ Fixed complex bug | Save immediately |
| ✅ Saw "Conversation compacted" | Save immediately! |
| ❌ Simple Q&A | No need to save |

### Incremental Saving

```
┌─────────────────────────────────────────────────────────────────┐
│                    Recommended Workflow                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Phase 1: Complete Architecture Analysis                       │
│      │                                                          │
│      ▼                                                          │
│   /save-context Architecture  ← Save now!                       │
│      │                                                          │
│      ▼                                                          │
│   Phase 2: Start Feature Development                            │
│      │                                                          │
│      ▼                                                          │
│   /save-context Feature Dev   ← Save again!                     │
│      │                                                          │
│      ▼                                                          │
│   Phase 3: Bug Fixes                                            │
│      │                                                          │
│      ▼                                                          │
│   /save-context Bug Fixes     ← Keep saving!                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## ⚠️ Important Notes

### Context Window Limitations

Claude has context window limitations. When conversations get too long, early content gets compressed:

- **Short conversations**: Can save complete content ✅
- **Long conversations**: Can only save recent content + compressed summary ⚠️

**Recommendation**: Save immediately after completing important phases. Don't wait until the conversation is too long!

## 🛠️ Uninstallation

If you need to uninstall, run:

```bash
./uninstall.sh
```

The script will:
1. Ask if you want to backup saved sessions
2. Remove command and skill files
3. Optionally preserve session data

## 🤝 Contributing

Contributions, bug reports, and suggestions are welcome!

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Submit a Pull Request

## 📝 Changelog

See [CHANGELOG.md](./CHANGELOG.md) for version history.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## 🙏 Acknowledgments

- [Anthropic](https://www.anthropic.com/) - Claude AI
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) - CLI Tool
- All contributors and users

---

<div align="center">

**If this project helps you, please give it a ⭐️ Star!**

Made with ❤️ by [Leo Coder](https://github.com/gaoziman)

</div>
