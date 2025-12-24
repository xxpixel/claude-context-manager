# 配置说明

本文档介绍 Claude Context Manager 的配置选项和自定义方法。

## 目录结构

安装后的目录结构：

```
~/.claude/
├── commands/                      # 命令文件目录
│   ├── save-context.md           # 保存上下文命令
│   ├── load-context.md           # 加载上下文命令
│   ├── list-contexts.md          # 列出会话命令
│   └── search-context.md         # 搜索会话命令
├── skills/
│   └── context-manager/
│       └── SKILL.md              # 技能定义文件
└── conversations/                 # 会话存储目录
    ├── index.json                # 索引文件
    └── *.md                      # 会话文件
```

## 配置文件说明

### 索引文件 (index.json)

索引文件存储所有会话的元数据，用于快速检索。

```json
{
  "version": "1.0.0",
  "description": "Claude Code Session Context Index",
  "last_updated": "2025-12-24T16:30:45+08:00",
  "conversations": [
    {
      "id": "uuid-here",
      "title": "会话标题",
      "project": "项目名称",
      "project_path": "/path/to/project",
      "created_at": "2025-12-24T16:30:45+08:00",
      "tags": ["tag1", "tag2"],
      "summary": "一句话摘要",
      "type": "development",
      "file": "2025-12-24_163045_会话标题.md"
    }
  ]
}
```

### 技能定义文件 (SKILL.md)

技能文件定义了 Claude 如何处理上下文保存和恢复。主要配置项：

```markdown
---
name: context-manager
description: 会话上下文管理技能
version: 1.0.0
---

# 技能配置

## 会话类型定义
- analysis: 分析类会话
- development: 开发类会话
- debug: 调试类会话
- config: 配置类会话

## 质量检查项
1. 项目信息完整性
2. 需求描述清晰度
3. 决策记录完整性
...
```

## 自定义配置

### 修改存储位置

默认情况下，会话文件存储在 `~/.claude/conversations/`。如需修改：

1. 编辑 `~/.claude/skills/context-manager/SKILL.md`
2. 找到存储路径配置
3. 修改为目标路径

```markdown
## 存储配置

会话文件存储路径：`~/.claude/conversations/`
```

### 自定义标签规则

编辑 SKILL.md 文件中的标签生成规则：

```markdown
## 标签生成规则

### 技术栈标签
根据以下关键词自动识别：
- Java/Spring → #Java #Spring
- JavaScript/React → #JavaScript #React
- Python/Django → #Python #Django
- ...

### 任务类型标签
- 新功能开发 → #feature
- Bug 修复 → #bugfix
- 代码重构 → #refactor
- 性能优化 → #performance
- ...
```

### 自定义会话模板

编辑 SKILL.md 中的模板部分：

```markdown
## 会话文件模板

### 标准模板
```markdown
---
id: "{uuid}"
title: "{title}"
...
---

# 会话上下文：{title}

## 📋 会话概述
[自定义内容区域]

## 🎯 用户需求
[自定义内容区域]

...
```
```

### 添加自定义字段

如需在会话文件中添加自定义字段：

1. 编辑 SKILL.md 的模板部分
2. 添加新字段定义
3. 在 YAML frontmatter 中添加字段

示例：添加优先级字段

```yaml
---
id: "uuid"
title: "会话标题"
priority: "high"  # 新增字段
---
```

## 命令配置

### 修改命令描述

编辑对应的命令文件：

```markdown
# save-context.md

保存当前会话的完整上下文到本地文件。

## 用法
/save-context [标题]

## 参数
- 标题（可选）：自定义会话标题
```

### 添加新命令

1. 在 `~/.claude/commands/` 创建新的 `.md` 文件
2. 按照现有格式编写命令定义
3. 重启 Claude Code 使命令生效

示例：创建删除命令

```markdown
# delete-context.md

删除指定的历史会话。

## 用法
/delete-context <序号>

## 参数
- 序号：要删除的会话序号

## 执行逻辑
1. 根据序号查找会话文件
2. 确认删除操作
3. 删除文件并更新索引
```

## 高级配置

### 配置自动保存

可以通过修改 SKILL.md 添加自动保存提示：

```markdown
## 自动保存提示

在以下情况下提醒用户保存：
- 会话达到一定长度
- 完成重要任务
- 检测到 "Conversation compacted" 提示
```

### 配置会话类型检测规则

编辑 SKILL.md 中的类型检测规则：

```markdown
## 会话类型检测规则

### 分析类 (analysis)
关键词：分析、设计、架构、方案、评估、调研

### 开发类 (development)
关键词：开发、实现、编码、功能、特性

### 调试类 (debug)
关键词：bug、错误、修复、问题、调试、排查

### 配置类 (config)
关键词：配置、设置、环境、部署、安装
```

### 配置质量检查

编辑 SKILL.md 中的质量检查配置：

```markdown
## 质量检查配置

### 必要项（必须通过）
1. [ ] 项目路径完整
2. [ ] 需求描述存在
3. [ ] 时间戳正确

### 推荐项（建议通过）
4. [ ] 包含关键决策
5. [ ] 包含代码示例
6. [ ] 包含下一步建议
7. [ ] 包含注意事项
8. [ ] 标签数量合理（3-8个）
```

## 数据管理

### 备份会话数据

```bash
# 备份整个 conversations 目录
cp -r ~/.claude/conversations ~/claude-backup-$(date +%Y%m%d)

# 或使用 tar 压缩
tar -czvf claude-backup-$(date +%Y%m%d).tar.gz ~/.claude/conversations
```

### 恢复会话数据

```bash
# 从备份恢复
cp -r ~/claude-backup-20251224/conversations ~/.claude/
```

### 清理旧会话

```bash
# 删除 30 天前的会话文件（谨慎操作）
find ~/.claude/conversations -name "*.md" -mtime +30 -delete

# 删除后需要重建索引
# 可以通过运行 /list-contexts 让系统自动重建
```

### 导出数据

会话文件是标准的 Markdown 格式，可以直接：
- 用任何文本编辑器打开
- 导入到其他笔记软件
- 转换为其他格式（PDF、HTML 等）

## 故障排除

### 重置配置

如需重置为默认配置：

```bash
# 1. 卸载
./uninstall.sh

# 2. 重新安装
./install.sh
```

### 重建索引

如果索引文件损坏：

```bash
# 删除索引文件
rm ~/.claude/conversations/index.json

# 运行 /list-contexts 会自动重建索引
```

### 检查配置完整性

```bash
# 检查所有必要文件
ls -la ~/.claude/commands/
ls -la ~/.claude/skills/context-manager/
ls -la ~/.claude/conversations/
```

## 下一步

- 查看 [使用指南](./usage.md) 了解如何使用各项功能
- 查看 [最佳实践](./best-practices.md) 了解高效使用方法
- 查看 [常见问题](./faq.md) 解决常见问题
