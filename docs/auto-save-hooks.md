# 自动保存 Hooks 配置指南

本文档介绍如何配置 Claude Code 的 Hooks 机制来实现自动保存上下文，防止意外丢失。

## 快速安装

```bash
# 进入项目目录
cd claude-context-manager

# 安装 Stop Hook（默认）
./scripts/hooks/install-hooks.sh

# 或安装所有 Hooks（包括 PostToolUse 周期保存）
./scripts/hooks/install-hooks.sh --all
```

安装后会自动配置：
- **Stop Hook**：任务停止时自动保存
- **PostToolUse Hook**（可选）：周期性自动保存
- **会话索引器**：支持 `/recover-context` 命令的会话列表和搜索功能

## Hooks 机制简介

Claude Code 支持以下 Hooks 类型：

| Hook 类型 | 触发时机 | 用途 |
|-----------|----------|------|
| `PreToolUse` | 工具调用前 | 审查、记录即将执行的操作 |
| `PostToolUse` | 工具调用后 | 记录操作结果、触发后续动作 |
| `Notification` | 通知消息时 | 监听系统通知 |
| `Stop` | 任务停止时 | 清理、保存状态 |

## 方案一：基于 Stop Hook 的自动保存

当 Claude Code 任务停止时自动保存上下文：

### 配置示例

在 `~/.claude/settings.json` 中添加：

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/auto-save-context.sh"
          }
        ]
      }
    ]
  }
}
```

### 自动保存脚本

创建 `~/.claude/scripts/auto-save-context.sh`：

```bash
#!/bin/bash

# 自动保存上下文脚本
# 在任务停止时自动调用

CONVERSATIONS_DIR="$HOME/.claude/conversations"
INDEX_FILE="$CONVERSATIONS_DIR/index.json"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
PROJECT_NAME=$(basename "$PWD")

# 创建目录
mkdir -p "$CONVERSATIONS_DIR"

# 获取当前会话信息
encoded_path=$(echo "$PWD" | sed 's/\//-/g' | sed 's/^-//')
session_dir="$HOME/.claude/projects/$encoded_path"
latest_session=$(ls -t "$session_dir"/*.jsonl 2>/dev/null | head -1)

if [ -n "$latest_session" ]; then
    # 记录自动保存信息
    echo "[$(date)] Auto-saved session from: $latest_session" >> "$HOME/.claude/auto-save.log"

    # 可选：发送系统通知
    if command -v osascript &> /dev/null; then
        osascript -e 'display notification "会话已自动保存" with title "Claude Context Manager"'
    fi
fi
```

## 方案二：基于 PostToolUse 的周期性保存

每隔 N 次工具调用自动保存一次：

### 配置示例

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/periodic-save.sh"
          }
        ]
      }
    ]
  }
}
```

### 周期性保存脚本

```bash
#!/bin/bash

# 周期性保存脚本
# 每 10 次重要操作保存一次

COUNTER_FILE="/tmp/claude-save-counter"
SAVE_INTERVAL=10

# 读取计数器
if [ -f "$COUNTER_FILE" ]; then
    count=$(cat "$COUNTER_FILE")
else
    count=0
fi

# 增加计数
count=$((count + 1))
echo $count > "$COUNTER_FILE"

# 达到间隔时保存
if [ $((count % SAVE_INTERVAL)) -eq 0 ]; then
    echo "[$(date)] Periodic save triggered (count: $count)" >> "$HOME/.claude/auto-save.log"
    # 这里可以添加实际的保存逻辑
fi
```

## 方案三：关键操作前自动快照

在执行危险操作前自动创建快照：

### 配置示例

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/pre-operation-snapshot.sh \"$TOOL_NAME\" \"$TOOL_INPUT\""
          }
        ]
      }
    ]
  }
}
```

## 最佳实践

### 1. 组合使用多种策略

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [{ "type": "command", "command": "~/.claude/scripts/on-stop-save.sh" }]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{ "type": "command", "command": "~/.claude/scripts/track-changes.sh" }]
      }
    ]
  }
}
```

### 2. 保存日志便于排查

所有自动保存操作都应记录日志：

```bash
LOG_FILE="$HOME/.claude/auto-save.log"
echo "[$(date)] Event: $EVENT_TYPE | Project: $PROJECT | Session: $SESSION_ID" >> "$LOG_FILE"
```

### 3. 定期清理旧日志

```bash
# 清理 7 天前的日志
find "$HOME/.claude/" -name "*.log" -mtime +7 -delete
```

## 注意事项

1. **性能影响**：Hooks 脚本应尽量轻量，避免影响 Claude Code 响应速度
2. **错误处理**：脚本应有良好的错误处理，避免因脚本错误影响主流程
3. **权限设置**：确保脚本有执行权限 (`chmod +x`)
4. **路径问题**：使用绝对路径避免工作目录问题

## 会话索引器

安装 Hooks 后，会同时安装会话索引器脚本 (`session-indexer.py`)，用于支持 `/recover-context` 命令。

### 功能特性

- **智能标题提取**：按优先级从命令名称、提示词标题、用户消息中提取会话标题
- **4字中文标签**：自动生成技术标签（如 `#错误修复 #功能开发 #接口开发`）
- **增量索引**：只处理新增或修改的会话文件
- **搜索功能**：支持按标题、标签、日期搜索会话

### 标题提取策略

会话标题按以下优先级提取：

1. **命令名称**：如 `/recover-context` → "恢复会话上下文"
2. **提示词标题**：如 `# 项目架构分析` → "项目架构分析"
3. **用户消息**：第一条有意义的用户请求
4. **默认**：如果都没有，显示"无标题会话"

### 命令行使用

```bash
# 自动发现当前项目的会话
python3 ~/.claude/scripts/session-indexer.py --auto

# 显示前 30 个会话
python3 ~/.claude/scripts/session-indexer.py --auto -l 30

# 搜索会话
python3 ~/.claude/scripts/session-indexer.py --auto -s "错误处理"

# 输出 JSON 格式
python3 ~/.claude/scripts/session-indexer.py --auto -o json
```

## 相关链接

- [Claude Code Hooks 官方文档](https://docs.anthropic.com/claude-code/hooks)
- [Shell 脚本最佳实践](https://google.github.io/styleguide/shellguide.html)
