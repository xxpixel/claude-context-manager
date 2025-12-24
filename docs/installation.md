# 安装指南

本文档详细介绍 Claude Context Manager 的安装过程。

## 系统要求

### 操作系统
- macOS 10.15+ (Catalina 或更高版本)
- Linux (Ubuntu 18.04+, Debian 10+, CentOS 7+, 或其他主流发行版)

### 软件依赖
- **Claude Code**: 必须已安装并能正常使用
- **Bash**: 版本 4.0 或更高
- **Git**: 用于克隆仓库（可选，也可手动下载）

### 检查环境

```bash
# 检查 Bash 版本
bash --version

# 检查 Claude Code 是否安装
which claude

# 检查 ~/.claude 目录是否存在
ls -la ~/.claude
```

## 安装方式

### 方式一：使用 Git 克隆（推荐）

```bash
# 1. 克隆仓库
git clone https://github.com/gaoziman/claude-context-manager.git

# 2. 进入项目目录
cd claude-context-manager

# 3. 添加执行权限
chmod +x install.sh

# 4. 运行安装脚本
./install.sh
```

### 方式二：下载 ZIP 包

1. 访问 [GitHub Releases](https://github.com/gaoziman/claude-context-manager/releases)
2. 下载最新版本的 ZIP 文件
3. 解压到任意目录
4. 运行安装脚本：

```bash
cd claude-context-manager
chmod +x install.sh
./install.sh
```

### 方式三：手动安装

如果自动安装遇到问题，可以手动安装：

```bash
# 1. 创建必要的目录
mkdir -p ~/.claude/commands
mkdir -p ~/.claude/skills/context-manager
mkdir -p ~/.claude/conversations

# 2. 复制命令文件
cp .claude/commands/*.md ~/.claude/commands/

# 3. 复制技能文件
cp .claude/skills/context-manager/SKILL.md ~/.claude/skills/context-manager/

# 4. 初始化索引文件（如果不存在）
if [ ! -f ~/.claude/conversations/index.json ]; then
    echo '{"version":"1.0.0","conversations":[]}' > ~/.claude/conversations/index.json
fi
```

## 安装过程详解

### 安装脚本执行流程

1. **环境检查**
   - 检查操作系统类型
   - 检查 `~/.claude` 目录是否存在

2. **备份现有配置**
   - 如果存在同名文件，会询问是否备份
   - 备份文件存放在 `~/.claude/backups/` 目录

3. **文件安装**
   - 复制命令文件到 `~/.claude/commands/`
   - 复制技能文件到 `~/.claude/skills/context-manager/`
   - 创建会话存储目录 `~/.claude/conversations/`

4. **初始化索引**
   - 如果索引文件不存在，创建初始 `index.json`

5. **验证安装**
   - 检查所有必要文件是否存在
   - 显示安装结果

### 安装输出示例

```
╔══════════════════════════════════════════════════════════════╗
║           Claude Context Manager 安装程序                      ║
║                      v1.0.0                                    ║
╚══════════════════════════════════════════════════════════════╝

[✓] 操作系统检查通过: darwin
[✓] Claude 配置目录存在: /Users/username/.claude

正在安装文件...
[✓] 已安装: save-context.md
[✓] 已安装: load-context.md
[✓] 已安装: list-contexts.md
[✓] 已安装: search-context.md
[✓] 已安装: SKILL.md
[✓] 会话存储目录已创建

═══════════════════════════════════════════════════════════════
✓ 安装完成！
═══════════════════════════════════════════════════════════════

请重启 Claude Code 后，输入 / 查看新命令。

可用命令：
  /save-context     - 保存当前会话上下文
  /load-context     - 加载历史会话上下文
  /list-contexts    - 列出所有保存的会话
  /search-context   - 搜索会话上下文
```

## 验证安装

### 方法一：检查文件

```bash
# 检查命令文件
ls -la ~/.claude/commands/ | grep context

# 预期输出：
# -rw-r--r--  1 user  staff  xxxx save-context.md
# -rw-r--r--  1 user  staff  xxxx load-context.md
# -rw-r--r--  1 user  staff  xxxx list-contexts.md
# -rw-r--r--  1 user  staff  xxxx search-context.md
```

### 方法二：在 Claude Code 中验证

1. 重启 Claude Code（重要！）
2. 输入 `/` 字符
3. 查看命令列表中是否出现：
   - `/save-context`
   - `/load-context`
   - `/list-contexts`
   - `/search-context`

## 常见安装问题

### 问题 1：权限不足

**症状**：
```
Permission denied: ./install.sh
```

**解决方案**：
```bash
chmod +x install.sh
./install.sh
```

### 问题 2：~/.claude 目录不存在

**症状**：
```
[✗] Claude 配置目录不存在
```

**解决方案**：
1. 确保已安装 Claude Code
2. 运行一次 Claude Code 让它创建配置目录
3. 或手动创建：`mkdir -p ~/.claude`

### 问题 3：命令不显示

**症状**：
- 安装成功但在 Claude Code 中看不到新命令

**解决方案**：
1. 完全关闭 Claude Code
2. 重新打开 Claude Code
3. 等待几秒钟让它加载配置
4. 输入 `/` 查看命令

### 问题 4：Bash 版本过低

**症状**：
```
语法错误或脚本执行异常
```

**解决方案**：

macOS 用户：
```bash
# 使用 Homebrew 安装新版 Bash
brew install bash

# 使用新版 Bash 运行脚本
/opt/homebrew/bin/bash install.sh
```

Linux 用户：
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install bash

# CentOS/RHEL
sudo yum install bash
```

## 升级安装

如果你之前已经安装过旧版本，升级步骤如下：

```bash
# 1. 进入项目目录
cd claude-context-manager

# 2. 获取最新代码
git pull origin main

# 3. 重新运行安装脚本
./install.sh
```

安装脚本会自动处理升级，并在必要时备份旧文件。

## 下一步

安装完成后，请查看 [使用指南](./usage.md) 了解如何使用 Claude Context Manager。
