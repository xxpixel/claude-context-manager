#!/bin/bash

# ============================================
# Claude Context Manager - Hooks 安装脚本
#
# 功能：安装 Stop Hook 和 PostToolUse Hook 自动保存功能
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
CLAUDE_DIR="$HOME/.claude"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# 安装选项
INSTALL_STOP_HOOK=true
INSTALL_PERIODIC_HOOK=false

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

# 检查 Python3 环境
check_python() {
    print_info "检查 Python3 环境..."

    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1)
        print_success "Python3 已安装: $PYTHON_VERSION"
        return 0
    else
        print_error "未找到 Python3，请先安装 Python3"
        return 1
    fi
}

# 创建目录
create_directories() {
    print_info "创建必要目录..."

    mkdir -p "$SCRIPTS_DIR"
    mkdir -p "$CLAUDE_DIR/conversations"

    print_success "目录创建完成"
}

# 复制脚本文件
copy_scripts() {
    print_info "复制自动保存脚本..."

    # 复制 Stop Hook 脚本
    local source_script="$PROJECT_ROOT/scripts/hooks/auto-save-context.py"
    local target_script="$SCRIPTS_DIR/auto-save-context.py"

    if [ ! -f "$source_script" ]; then
        print_error "源脚本不存在: $source_script"
        return 1
    fi

    cp "$source_script" "$target_script"
    chmod +x "$target_script"
    print_success "Stop Hook 脚本已复制到: $target_script"

    # 复制 PostToolUse Hook 脚本（如果选择安装）
    if [ "$INSTALL_PERIODIC_HOOK" = true ]; then
        local periodic_source="$PROJECT_ROOT/scripts/hooks/periodic-save-context.py"
        local periodic_target="$SCRIPTS_DIR/periodic-save-context.py"

        if [ ! -f "$periodic_source" ]; then
            print_error "周期保存脚本不存在: $periodic_source"
            return 1
        fi

        cp "$periodic_source" "$periodic_target"
        chmod +x "$periodic_target"
        print_success "PostToolUse Hook 脚本已复制到: $periodic_target"
    fi

    # 复制会话索引器脚本（用于 /recover-context 命令）
    local indexer_source="$PROJECT_ROOT/scripts/session-indexer.py"
    local indexer_target="$SCRIPTS_DIR/session-indexer.py"

    if [ -f "$indexer_source" ]; then
        cp "$indexer_source" "$indexer_target"
        chmod +x "$indexer_target"
        print_success "会话索引器脚本已复制到: $indexer_target"
    else
        print_warning "会话索引器脚本不存在: $indexer_source"
    fi
}

# 更新 settings.json
update_settings() {
    print_info "更新 settings.json 配置..."

    # 如果 settings.json 不存在，创建基础配置
    if [ ! -f "$SETTINGS_FILE" ]; then
        print_warning "settings.json 不存在，创建新文件"
        echo '{}' > "$SETTINGS_FILE"
    fi

    # 使用 Python 更新 JSON 配置
    python3 << EOF
import json
import os

settings_file = os.path.expanduser("~/.claude/settings.json")
install_periodic = "$INSTALL_PERIODIC_HOOK" == "true"

# 读取现有配置
try:
    with open(settings_file, "r", encoding="utf-8") as f:
        settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    settings = {}

# 添加 hooks 配置
if "hooks" not in settings:
    settings["hooks"] = {}

# 添加 Stop Hook
stop_hook = {
    "matcher": "",
    "hooks": [
        {
            "type": "command",
            "command": "python3 ~/.claude/scripts/auto-save-context.py"
        }
    ]
}

# 检查是否已存在 Stop Hook
if "Stop" not in settings["hooks"]:
    settings["hooks"]["Stop"] = [stop_hook]
    print("添加 Stop Hook 配置")
else:
    existing_hooks = settings["hooks"]["Stop"]
    has_auto_save = any(
        "auto-save-context.py" in h.get("hooks", [{}])[0].get("command", "")
        for h in existing_hooks
    )

    if not has_auto_save:
        settings["hooks"]["Stop"].append(stop_hook)
        print("追加 Stop Hook 配置")
    else:
        print("Stop Hook 已存在，跳过")

# 添加 PostToolUse Hook（如果选择安装）
if install_periodic:
    periodic_hook = {
        "matcher": "",
        "hooks": [
            {
                "type": "command",
                "command": "python3 ~/.claude/scripts/periodic-save-context.py"
            }
        ]
    }

    if "PostToolUse" not in settings["hooks"]:
        settings["hooks"]["PostToolUse"] = [periodic_hook]
        print("添加 PostToolUse Hook 配置")
    else:
        existing_hooks = settings["hooks"]["PostToolUse"]
        has_periodic = any(
            "periodic-save-context.py" in h.get("hooks", [{}])[0].get("command", "")
            for h in existing_hooks
        )

        if not has_periodic:
            settings["hooks"]["PostToolUse"].append(periodic_hook)
            print("追加 PostToolUse Hook 配置")
        else:
            print("PostToolUse Hook 已存在，跳过")

# 保存配置
with open(settings_file, "w", encoding="utf-8") as f:
    json.dump(settings, f, ensure_ascii=False, indent=2)

print("settings.json 更新完成")
EOF

    print_success "settings.json 配置更新完成"
}

# 验证安装
verify_installation() {
    print_info "验证安装..."

    # 检查 Stop Hook 脚本
    local script_path="$SCRIPTS_DIR/auto-save-context.py"
    if [ ! -f "$script_path" ]; then
        print_error "Stop Hook 脚本不存在: $script_path"
        return 1
    fi

    if python3 -m py_compile "$script_path" 2>/dev/null; then
        print_success "Stop Hook 脚本语法检查通过"
    else
        print_error "Stop Hook 脚本语法错误"
        return 1
    fi

    # 检查 PostToolUse Hook 脚本（如果安装）
    if [ "$INSTALL_PERIODIC_HOOK" = true ]; then
        local periodic_path="$SCRIPTS_DIR/periodic-save-context.py"
        if [ ! -f "$periodic_path" ]; then
            print_error "PostToolUse Hook 脚本不存在: $periodic_path"
            return 1
        fi

        if python3 -m py_compile "$periodic_path" 2>/dev/null; then
            print_success "PostToolUse Hook 脚本语法检查通过"
        else
            print_error "PostToolUse Hook 脚本语法错误"
            return 1
        fi
    fi

    # 检查 settings.json 中的 hooks 配置
    if python3 -c "
import json
import os
with open(os.path.expanduser('~/.claude/settings.json')) as f:
    s = json.load(f)
    if 'hooks' in s and 'Stop' in s['hooks']:
        print('OK')
    else:
        exit(1)
" 2>/dev/null; then
        print_success "Hooks 配置验证通过"
    else
        print_error "Hooks 配置验证失败"
        return 1
    fi

    print_success "安装验证完成"
}

# 显示安装结果
show_result() {
    echo ""
    echo "============================================"
    echo -e "${GREEN}Hooks 自动保存功能安装成功！${NC}"
    echo "============================================"
    echo ""
    echo "已安装的功能："
    echo "  ✅ Stop Hook - 任务停止时自动保存"
    if [ "$INSTALL_PERIODIC_HOOK" = true ]; then
        echo "  ✅ PostToolUse Hook - 周期性自动保存"
    fi
    echo "  ✅ 会话索引器 - 支持 /recover-context 命令"
    echo ""
    echo "已安装的文件："
    echo "  - $SCRIPTS_DIR/auto-save-context.py"
    if [ "$INSTALL_PERIODIC_HOOK" = true ]; then
        echo "  - $SCRIPTS_DIR/periodic-save-context.py"
    fi
    echo "  - $SCRIPTS_DIR/session-indexer.py"
    echo ""
    echo "配置文件："
    echo "  - $SETTINGS_FILE"
    echo ""
    echo "功能说明："
    echo "  Stop Hook: 当 Claude Code 任务停止时，自动保存会话上下文"
    if [ "$INSTALL_PERIODIC_HOOK" = true ]; then
        echo "  PostToolUse Hook: 每 20 次工具调用或每 5 分钟自动保存"
    fi
    echo "  会话索引器: 为 /recover-context 命令提供会话列表和搜索功能"
    echo ""
    echo "保存位置："
    echo "  ~/.claude/conversations/"
    echo ""
    echo "日志文件："
    echo "  ~/.claude/auto-save.log"
    if [ "$INSTALL_PERIODIC_HOOK" = true ]; then
        echo "  ~/.claude/periodic-save.log"
    fi
    echo ""
    echo "注意事项："
    echo "  1. 需要重启 Claude Code 使配置生效"
    echo "  2. 自动保存的文件标记为 type: \"auto-save\" 或 \"periodic-save\""
    echo "  3. 可以使用 /save-context 覆盖自动保存的内容"
    echo ""
}

# 显示帮助信息
show_help() {
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --all, -a       安装所有 Hooks（Stop + PostToolUse）"
    echo "  --periodic, -p  同时安装 PostToolUse Hook 周期性保存"
    echo "  --help, -h      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0              # 仅安装 Stop Hook（默认）"
    echo "  $0 --all        # 安装所有 Hooks"
    echo "  $0 --periodic   # 安装 Stop Hook + PostToolUse Hook"
    echo ""
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --all|-a)
                INSTALL_PERIODIC_HOOK=true
                shift
                ;;
            --periodic|-p)
                INSTALL_PERIODIC_HOOK=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 主函数
main() {
    # 解析命令行参数
    parse_args "$@"

    echo ""
    echo "============================================"
    echo "Claude Context Manager - Hooks 安装程序"
    echo "============================================"
    echo ""

    if [ "$INSTALL_PERIODIC_HOOK" = true ]; then
        print_info "安装模式: Stop Hook + PostToolUse Hook"
    else
        print_info "安装模式: 仅 Stop Hook"
    fi
    echo ""

    # 检查 Python3
    if ! check_python; then
        exit 1
    fi

    # 创建目录
    create_directories

    # 复制脚本
    if ! copy_scripts; then
        exit 1
    fi

    # 更新配置
    update_settings

    # 验证安装
    if ! verify_installation; then
        print_error "安装验证失败"
        exit 1
    fi

    # 显示结果
    show_result
}

# 执行主函数
main "$@"
