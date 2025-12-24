<div align="center">

# 🧠 Claude Context Manager

**为 Claude Code 打造的会话上下文管理工具**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-blue.svg)]()
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-green.svg)]()

[English](./README_EN.md) | 简体中文

</div>

---

## 🎯 这是什么？

**Claude Context Manager** 是一个为 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 用户设计的会话上下文管理工具。它可以帮助你：

- 💾 **保存**当前会话的完整上下文
- 📂 **管理**所有保存的历史会话
- 🔄 **恢复**之前的工作状态到新会话
- 🔍 **搜索**历史会话快速找到相关内容

## 😫 解决什么痛点？

使用 Claude Code 时，你是否遇到过这些问题：

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  😱 遇到 API 错误（如 400 参数错误）被迫开启新窗口              │
│                                                                 │
│  💔 辛苦建立的对话上下文瞬间丢失                                │
│                                                                 │
│  🔄 需要在新会话中重复解释项目背景、技术决策                    │
│                                                                 │
│  📉 复杂任务的连续性被打断，效率大幅降低                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Claude Context Manager** 正是为解决这些问题而生！

## ✨ 核心特性

| 特性 | 描述 |
|------|------|
| 🧠 **智能提取** | 自动识别会话类型（分析/开发/调试/配置），采用对应的提取策略 |
| 🏷️ **智能标签** | 根据内容自动生成技术栈、任务类型、项目等标签 |
| ✅ **质量控制** | 内置 8 项质量检查清单，确保上下文完整可恢复 |
| ⏱️ **时间精确** | 时间戳精确到秒，方便追踪会话时间线 |
| 🔍 **全文搜索** | 支持标题、标签、内容的全文搜索 |
| 📊 **结构化存储** | Markdown + YAML frontmatter，人类可读 |

## 🚀 快速开始

### 安装

```bash
# 1. 克隆仓库
git clone https://github.com/gaoziman/claude-context-manager.git

# 2. 进入目录
cd claude-context-manager

# 3. 运行安装脚本
chmod +x install.sh
./install.sh
```

### 验证安装

重启 Claude Code 后，输入 `/` 查看是否出现以下命令：

```
/save-context     - 保存会话上下文
/load-context     - 加载会话上下文
/list-contexts    - 列出保存的会话上下文
/search-context   - 搜索会话上下文
```

## 📖 使用指南

### 1️⃣ 保存上下文

当你完成一个重要的工作阶段，执行：

```
/save-context
```

或指定标题：

```
/save-context 用户认证功能开发
```

系统会自动：
- 分析当前会话内容
- 提取关键信息（决策、代码、进度等）
- 生成结构化的上下文文件
- 更新索引便于后续查找

### 2️⃣ 列出所有会话

```
/list-contexts
```

输出示例：

```
📚 保存的会话列表（共 3 个）

| 序号 | 日期时间            | 标题                    | 项目         | 标签            |
|------|---------------------|-------------------------|--------------|-----------------|
| [1]  | 2025-12-24 14:30:25 | 用户认证功能开发         | my-project   | #auth #JWT      |
| [2]  | 2025-12-24 10:15:08 | 架构分析报告             | my-project   | #架构 #分析     |
| [3]  | 2025-12-23 16:45:30 | Bug 修复记录             | my-project   | #bug #修复      |
```

### 3️⃣ 加载上下文

```
/load-context 1
```

或使用关键词：

```
/load-context 认证
```

加载后，Claude 会显示完整的上下文内容，并提供智能建议告诉你可以继续做什么。

### 4️⃣ 搜索上下文

```
/search-context JWT
```

支持搜索：
- 标题
- 标签（使用 `#标签` 格式）
- 摘要内容

## 📁 文件结构

安装后，会在 `~/.claude/` 目录下创建以下结构：

```
~/.claude/
├── commands/                      # 命令文件
│   ├── save-context.md
│   ├── load-context.md
│   ├── list-contexts.md
│   └── search-context.md
├── skills/
│   └── context-manager/
│       └── SKILL.md              # 技能定义
└── conversations/                # 会话存储
    ├── index.json                # 索引文件
    └── *.md                      # 会话文件
```

## 🎨 会话文件格式

每个保存的会话都是一个 Markdown 文件：

```markdown
---
id: "uuid"
title: "会话标题"
project: "项目名称"
created_at: "2025-12-24T14:30:25+08:00"
tags: ["标签1", "标签2"]
summary: "一句话摘要"
---

# 会话上下文：[标题]

## 📋 会话概述
...

## 🎯 用户需求
...

## 📊 核心内容
...

## 💡 关键决策
...

## ✅ 任务进度
...

## 🚀 下次继续指南
...
```

## 💡 最佳实践

### 何时保存？

| 场景 | 建议 |
|------|------|
| ✅ 完成功能开发 | 立即保存 |
| ✅ 完成架构分析 | 立即保存 |
| ✅ 解决复杂 Bug | 立即保存 |
| ✅ 看到 "Conversation compacted" | 立即保存！ |
| ❌ 简单问答 | 不需要保存 |

### 分段保存

```
┌─────────────────────────────────────────────────────────────────┐
│                     推荐的工作流程                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   阶段 1：完成架构分析                                           │
│      │                                                          │
│      ▼                                                          │
│   /save-context 架构分析  ← 立即保存！                          │
│      │                                                          │
│      ▼                                                          │
│   阶段 2：开始功能开发                                           │
│      │                                                          │
│      ▼                                                          │
│   /save-context 功能开发  ← 再次保存！                          │
│      │                                                          │
│      ▼                                                          │
│   阶段 3：Bug 修复                                               │
│      │                                                          │
│      ▼                                                          │
│   /save-context Bug修复   ← 继续保存！                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## ⚠️ 注意事项

### 上下文窗口限制

Claude 有上下文窗口限制，当对话过长时，早期内容会被压缩：

- **短对话**：可以保存完整内容 ✅
- **长对话**：只能保存近期内容 + 压缩摘要 ⚠️

**建议**：完成重要阶段后立即保存，不要等到对话很长才保存！

## 🛠️ 卸载

如果需要卸载，运行：

```bash
./uninstall.sh
```

脚本会：
1. 询问是否备份已保存的会话
2. 删除命令和技能文件
3. 可选保留会话数据

## 🤝 贡献

欢迎贡献代码、报告 Bug 或提出建议！

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

## 📝 更新日志

查看 [CHANGELOG.md](./CHANGELOG.md) 了解版本更新历史。

## 📄 开源协议

本项目采用 MIT 协议 - 查看 [LICENSE](./LICENSE) 文件了解详情。

## 🙏 致谢

- [Anthropic](https://www.anthropic.com/) - Claude AI
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) - CLI 工具
- 所有贡献者和用户

---

<div align="center">

**如果这个项目对你有帮助，请给一个 ⭐️ Star！**

Made with ❤️ by [Leo Coder](https://github.com/gaoziman)

</div>
