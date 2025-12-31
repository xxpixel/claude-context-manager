#!/bin/bash

# ============================================
# Claude Context Manager - Hooks 卸载脚本
#
# 功能：卸载 Stop Hook 和 PostToolUse Hook 自动保存功能
# 作者：Leo Coder
# 版本：1.1.0
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 路径定义
CLAUDE_DIR="$HOME/.claude"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
STATE_DIR="$CLAUDE_DIR/periodic-save-state"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 删除脚本文件
remove_scripts() {
    print_info "删除自动保存脚本..."

    # 删除 Stop Hook 脚本
    local script_path="$SCRIPTS_DIR/auto-save-context.py"
    if [ -f "$script_path" ]; then
        rm "$script_path"
        print_success "已删除: $script_path"
    else
        print_warning "Stop Hook 脚本不存在，跳过"
    fi

    # 删除 PostToolUse Hook 脚本
    local periodic_path="$SCRIPTS_DIR/periodic-save-context.py"
    if [ -f "$periodic_path" ]; then
        rm "$periodic_path"
        print_success "已删除: $periodic_path"
    else
        print_warning "PostToolUse Hook 脚本不存在，跳过"
    fi
}

# 更新 settings.json
update_settings() {
    print_info "更新 settings.json 配置..."

    if [ ! -f "$SETTINGS_FILE" ]; then
        print_warning "settings.json 不存在，跳过"
        return
    fi

    # 使用 Python 更新 JSON 配置
    python3 << 'EOF'
import json
import os

settings_file = os.path.expanduser("~/.claude/settings.json")

try:
    with open(settings_file, "r", encoding="utf-8") as f:
        settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    print("无法读取 settings.json")
    exit(0)

# 移除 Stop Hook 中的自动保存配置
if "hooks" in settings and "Stop" in settings["hooks"]:
    original_count = len(settings["hooks"]["Stop"])

    settings["hooks"]["Stop"] = [
        h for h in settings["hooks"]["Stop"]
        if not any(
            "auto-save-context.py" in hook.get("command", "")
            for hook in h.get("hooks", [])
        )
    ]

    removed_count = original_count - len(settings["hooks"]["Stop"])

    if removed_count > 0:
        print(f"已移除 {removed_count} 个 Stop Hook 配置")

    # 如果 Stop 数组为空，删除它
    if not settings["hooks"]["Stop"]:
        del settings["hooks"]["Stop"]

# 移除 PostToolUse Hook 中的周期保存配置
if "hooks" in settings and "PostToolUse" in settings["hooks"]:
    original_count = len(settings["hooks"]["PostToolUse"])

    settings["hooks"]["PostToolUse"] = [
        h for h in settings["hooks"]["PostToolUse"]
        if not any(
            "periodic-save-context.py" in hook.get("command", "")
            for hook in h.get("hooks", [])
        )
    ]

    removed_count = original_count - len(settings["hooks"]["PostToolUse"])

    if removed_count > 0:
        print(f"已移除 {removed_count} 个 PostToolUse Hook 配置")

    # 如果 PostToolUse 数组为空，删除它
    if not settings["hooks"]["PostToolUse"]:
        del settings["hooks"]["PostToolUse"]

# 如果 hooks 对象为空，删除它
if "hooks" in settings and not settings["hooks"]:
    del settings["hooks"]

# 保存配置
with open(settings_file, "w", encoding="utf-8") as f:
    json.dump(settings, f, ensure_ascii=False, indent=2)

print("settings.json 更新完成")
EOF

    print_success "settings.json 配置更新完成"
}

# 询问是否删除日志和状态文件
ask_remove_logs() {
    echo ""
    read -p "是否删除自动保存日志和状态文件？(y/N): " choice

    case "$choice" in
        y|Y)
            # 删除日志文件
            if [ -f "$CLAUDE_DIR/auto-save.log" ]; then
                rm "$CLAUDE_DIR/auto-save.log"
                print_success "已删除 auto-save.log"
            fi

            if [ -f "$CLAUDE_DIR/periodic-save.log" ]; then
                rm "$CLAUDE_DIR/periodic-save.log"
                print_success "已删除 periodic-save.log"
            fi

            # 删除状态目录
            if [ -d "$STATE_DIR" ]; then
                rm -rf "$STATE_DIR"
                print_success "已删除状态目录: $STATE_DIR"
            fi
            ;;
        *)
            print_info "保留日志和状态文件"
            ;;
    esac
}

# 显示卸载结果
show_result() {
    echo ""
    echo "============================================"
    echo -e "${GREEN}Hooks 自动保存功能已卸载！${NC}"
    echo "============================================"
    echo ""
    echo "已删除的文件："
    echo "  - $SCRIPTS_DIR/auto-save-context.py"
    echo "  - $SCRIPTS_DIR/periodic-save-context.py"
    echo ""
    echo "注意事项："
    echo "  1. 需要重启 Claude Code 使配置生效"
    echo "  2. 已保存的会话文件不会被删除"
    echo "  3. 可以随时重新安装此功能"
    echo ""
}

# 主函数
main() {
    echo ""
    echo "============================================"
    echo "Claude Context Manager - Hooks 卸载程序"
    echo "============================================"
    echo ""

    # 删除脚本
    remove_scripts

    # 更新配置
    update_settings

    # 询问是否删除日志
    ask_remove_logs

    # 显示结果
    show_result
}

# 执行主函数
main "$@"
