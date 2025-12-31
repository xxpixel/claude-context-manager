[English](./README_EN.md) | **中文**

## Claude Context Manager

**🧠 为 Claude Code 打造的会话上下文管理工具｜保存、恢复、搜索你的 AI 编程会话**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-blue.svg)]()
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-green.svg)]()
[![GitHub Stars](https://img.shields.io/github/stars/gaoziman/claude-context-manager)](https://github.com/gaoziman/claude-context-manager/stargazers)

Claude Context Manager 通过自定义斜杠命令，让你能够随时保存 Claude Code 的会话上下文，在新会话中快速恢复之前的工作状态，彻底解决 API 错误导致上下文丢失的痛点。

---

## ✨ 核心功能 Highlights

- 💾 **一键保存**：`/save-context` 智能提取当前会话的关键信息，包括需求、决策、代码、进度等
- 🔄 **快速恢复**：`/load-context` 在新会话中加载历史上下文，Claude 立即理解项目背景
- 📋 **会话管理**：`/list-contexts` 查看所有保存的会话，支持时间戳精确到秒
- 🔍 **全文搜索**：`/search-context` 按标题、标签、内容搜索历史会话
- 🆘 **紧急恢复**：`/recover-context` 从 Claude Code 自动保存的 JSONL 文件恢复上下文（400 错误后救命功能！）
- 🤖 **自动保存**：Stop Hook 自动保存功能，任务停止时自动保存会话上下文（可选安装）
- 🧠 **智能识别**：自动识别会话类型（分析/开发/调试/配置），采用对应提取策略
- 🏷️ **自动标签**：根据内容自动生成技术栈、任务类型等标签
- ✅ **质量检查**：内置 8 项质量检查清单，确保上下文完整可恢复

## 😫 解决什么痛点？

使用 Claude Code 时，你是否遇到过：

| 痛点 | 描述 |
|------|------|
| 😱 **API 错误** | 遇到 400/500 错误被迫开启新窗口 |
| 💔 **上下文丢失** | 辛苦建立的对话上下文瞬间消失 |
| 🔄 **重复解释** | 需要在新会话中重复说明项目背景 |
| 📉 **效率下降** | 复杂任务的连续性被打断 |

**Claude Context Manager 正是为解决这些问题而生！**

## ⚡️ 快速开始 Quick Start

### 环境要求

- Claude Code 已安装并可正常使用
- macOS / Linux / Windows 操作系统

### macOS / Linux

```bash
# 克隆仓库
git clone https://github.com/gaoziman/claude-context-manager.git
cd claude-context-manager

# 运行安装脚本
chmod +x install.sh
./install.sh
```

### Windows

**PowerShell（推荐）**

```powershell
# 克隆仓库
git clone https://github.com/gaoziman/claude-context-manager.git
cd claude-context-manager

# 设置执行策略（如需要）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 运行安装脚本
.\scripts\windows\install.ps1
```

**批处理（兼容性更好）**

```cmd
git clone https://github.com/gaoziman/claude-context-manager.git
cd claude-context-manager
scripts\windows\install.bat
```

### 验证安装

重启 Claude Code 后，输入 `/` 查看是否出现以下命令：

```
/save-context     - 保存会话上下文
/load-context     - 加载会话上下文
/list-contexts    - 列出保存的会话
/search-context   - 搜索会话上下文
/recover-context  - 从 JSONL 恢复上下文（400 错误后使用）
```

## 📖 使用指南 Usage

### 保存上下文

```bash
# 自动生成标题
/save-context

# 指定标题
/save-context 用户认证功能开发
```

### 查看会话列表

```bash
/list-contexts
```

输出示例：

```
📚 保存的会话列表（共 3 个）

| 序号 | 日期时间              | 标题                | 项目        | 标签           |
|------|-----------------------|---------------------|-------------|----------------|
| [1]  | 2025-12-24 16:30:45  | 用户认证功能开发     | my-project  | #auth #JWT     |
| [2]  | 2025-12-24 14:15:22  | API 接口设计        | my-project  | #api #design   |
| [3]  | 2025-12-24 10:08:33  | 数据库架构分析       | my-project  | #db #analysis  |
```

### 加载上下文

```bash
# 按序号加载
/load-context 1

# 按关键词加载
/load-context 认证
```

### 搜索上下文

```bash
# 搜索关键词
/search-context JWT

# 搜索标签
/search-context #authentication
```

### 紧急恢复（400 错误后）

当遇到 400 错误导致窗口不可用时，在新窗口中使用：

```bash
# 查看可恢复的会话
/recover-context

# 恢复最近的会话
/recover-context latest
```

## 🏗️ 安装原理 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        安装流程                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   📦 项目仓库                          🏠 用户目录                │
│   claude-context-manager/             ~/.claude/                │
│                                                                 │
│   .claude/commands/*.md    ════════►  commands/*.md            │
│   .claude/skills/          ════════►  skills/context-manager/  │
│   .claude/conversations/   ════════►  conversations/           │
│                                                                 │
│              install.sh 自动复制到用户目录                        │
│              安装后全局可用，无需每个项目安装                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

| 平台 | 配置目录 |
|------|----------|
| macOS | `~/.claude/` → `/Users/用户名/.claude/` |
| Linux | `~/.claude/` → `/home/用户名/.claude/` |
| Windows | `%USERPROFILE%\.claude\` → `C:\Users\用户名\.claude\` |

## 📁 项目结构 Structure

```
claude-context-manager/
├── install.sh              # macOS/Linux 安装脚本
├── uninstall.sh            # macOS/Linux 卸载脚本
├── scripts/
│   ├── mac/                # macOS/Linux 脚本
│   │   ├── install.sh
│   │   └── uninstall.sh
│   ├── windows/            # Windows 脚本
│   │   ├── install.ps1     # PowerShell 安装
│   │   ├── uninstall.ps1   # PowerShell 卸载
│   │   ├── install.bat     # 批处理安装
│   │   └── uninstall.bat   # 批处理卸载
│   ├── hooks/              # Hooks 脚本
│   │   ├── auto-save-context.py      # Stop Hook 自动保存脚本
│   │   ├── periodic-save-context.py  # PostToolUse Hook 周期保存脚本
│   │   ├── install-hooks.sh          # Hooks 安装脚本
│   │   └── uninstall-hooks.sh        # Hooks 卸载脚本
│   └── session-indexer.py  # 会话索引器（支持 /recover-context）
├── .claude/
│   ├── commands/           # 斜杠命令定义
│   ├── skills/             # 技能定义
│   └── conversations/      # 会话模板
├── docs/                   # 详细文档
└── examples/               # 示例文件
```

## ⚙️ 配置说明 Configuration

安装后文件结构：

```
~/.claude/
├── commands/                      # 斜杠命令（全局可用）
│   ├── save-context.md
│   ├── load-context.md
│   ├── list-contexts.md
│   ├── search-context.md
│   └── recover-context.md         # 紧急恢复命令
├── scripts/                       # 脚本目录（Hooks 安装后）
│   ├── auto-save-context.py       # Stop Hook 自动保存脚本
│   ├── periodic-save-context.py   # PostToolUse Hook 周期保存脚本
│   └── session-indexer.py         # 会话索引器
├── skills/context-manager/
│   └── SKILL.md                  # 技能定义
└── conversations/                 # 会话存储
    ├── index.json                # 索引文件
    └── *.md                      # 保存的会话
```

### 安装自动保存功能（可选）

如果你想启用 Stop Hook 自动保存功能：

```bash
# 进入项目目录
cd claude-context-manager

# 运行 Hooks 安装脚本（默认只安装 Stop Hook）
./scripts/hooks/install-hooks.sh

# 或安装所有 Hooks（包括 PostToolUse 周期保存）
./scripts/hooks/install-hooks.sh --all
```

安装后的功能：
- **Stop Hook**：当 Claude Code 任务停止时自动保存会话上下文
- **PostToolUse Hook**（可选）：每 20 次工具调用或每 5 分钟自动保存
- **会话索引器**：为 `/recover-context` 命令提供会话列表和搜索功能

## 💡 最佳实践 Best Practices

### 何时保存？

| 场景 | 建议 |
|------|------|
| ✅ 完成功能开发 | 立即保存 |
| ✅ 完成架构分析 | 立即保存 |
| ✅ 解决复杂 Bug | 立即保存 |
| ✅ 看到 "Conversation compacted" | **立即保存！** |
| ❌ 简单问答 | 无需保存 |

### 推荐工作流

```
阶段 1：需求分析 → /save-context 需求分析
    ↓
阶段 2：架构设计 → /save-context 架构设计
    ↓
阶段 3：功能开发 → /save-context 功能开发
    ↓
阶段 4：测试修复 → /save-context 测试完成
```

## ❓ FAQ

**1. 安装后看不到命令？**
> 必须**完全重启** Claude Code，不是最小化后再打开。

**2. Windows 提示执行策略限制？**
> 运行 `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

**3. ~/.claude 目录不存在？**
> 先运行一次 `claude` 命令，或手动创建 `mkdir -p ~/.claude`

**4. 保存的内容不完整？**
> Claude 有上下文窗口限制，长对话早期内容会被压缩。建议：**完成重要阶段后立即保存**。

**5. 安装后项目目录可以删除吗？**
> 可以，但建议保留用于升级。

**6. 遇到 400 错误后如何恢复？**
> 在新窗口中使用 `/recover-context` 命令，它会从 Claude Code 自动保存的 JSONL 文件中恢复上下文。

## 🛠️ 卸载 Uninstall

**macOS / Linux**

```bash
./uninstall.sh
```

**Windows**

```powershell
.\scripts\windows\uninstall.ps1
# 或
scripts\windows\uninstall.bat
```

卸载脚本会询问是否备份已保存的会话数据。

## 🤝 贡献指南 Contributing

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add AmazingFeature'`)
4. 推送分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

## 📚 相关文档 Documentation

- [新手入门指南](./docs/getting-started.md)
- [安装指南](./docs/installation.md)
- [使用指南](./docs/usage.md)
- [配置说明](./docs/configuration.md)
- [最佳实践](./docs/best-practices.md)
- [常见问题](./docs/faq.md)
- [自动保存 Hooks 配置](./docs/auto-save-hooks.md)

## 📜 许可证 License

本项目采用 [MIT License](./LICENSE)，可自由使用与二次开发。

---

**如果这个项目对你有帮助，请给一个 ⭐️ Star！**

Made with ❤️ by [Leo Coder](https://github.com/gaoziman)
