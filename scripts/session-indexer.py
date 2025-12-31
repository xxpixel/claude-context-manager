#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Claude Code 会话索引器

功能：
1. 解析 JSONL 会话文件，提取标题和标签
2. 生成/更新 .session-index.json 索引文件
3. 支持增量更新，只处理新增或修改的文件
4. 支持自动发现当前项目的会话目录

使用方式：
    python3 session-indexer.py <session_dir> [--output json|table]
    python3 session-indexer.py --auto [--output json|table]
"""

import json
import os
import sys
import re
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# 配置常量
MAX_TITLE_LENGTH = 40  # 标题最大长度
MAX_TAGS = 3  # 最大标签数量
INDEX_FILE_NAME = ".session-index.json"
INDEX_VERSION = "1.0.0"

# Claude 目录配置
CLAUDE_DIR = Path.home() / ".claude"
PROJECTS_DIR = CLAUDE_DIR / "projects"

# ============================================
# 分层优先级标签规则（4字中文）
# ============================================

# 优先级1：任务类型（最重要，描述会话做了什么）
TASK_TAGS = {
    "错误修复": ["fix", "bug", "error", "错误", "报错", "修复", "解决", "异常", "失败"],
    "功能开发": ["feature", "implement", "新增", "添加", "开发", "实现", "创建", "功能"],
    "代码重构": ["refactor", "重构", "优化", "改进", "整理", "清理"],
    "问题调试": ["debug", "调试", "排查", "定位", "问题", "排错"],
    "项目部署": ["deploy", "部署", "发布", "上线", "production", "线上"],
    "环境配置": ["config", "配置", "设置", "环境", "env", "setting"],
    "单元测试": ["test", "测试", "jest", "vitest", "单元测试", "e2e"],
    "文档编写": ["doc", "文档", "readme", "注释", "说明", "document"],
    "需求分析": ["分析", "analysis", "研究", "调研", "了解", "理解"],
    "架构设计": ["设计", "design", "架构", "方案", "规划", "architecture"],
    "代码提交": ["commit", "提交", "push", "pr", "pull request", "merge"],
    "代码审查": ["review", "审查", "检查", "code review"],
}

# 优先级2：业务领域
DOMAIN_TAGS = {
    "接口开发": ["api", "接口", "endpoint", "路由", "route", "rest"],
    "数据存储": ["database", "db", "sql", "mysql", "postgresql", "数据库"],
    "用户认证": ["auth", "login", "登录", "认证", "授权", "权限", "token"],
    "缓存优化": ["cache", "redis", "缓存", "ioredis"],
    "界面交互": ["ui", "界面", "组件", "样式", "css", "交互", "页面"],
    "性能优化": ["performance", "性能", "优化", "加速", "慢"],
    "钩子脚本": ["hook", "钩子", "mcp", "pre-commit", "post-tool"],
}

# 优先级3：技术框架（仅作为补充）
TECH_TAGS = {
    "React框架": ["react", "jsx", "tsx", "usestate", "useeffect", "component"],
    "Vue框架": ["vue", "vuex", "pinia"],
    "Next框架": ["next.js", "nextjs", "app router"],
    "Python": ["python", ".py", "pip"],
    "Java开发": ["java", "spring", "maven"],
    "Docker": ["docker", "container", "容器", "镜像"],
    "Git操作": ["git", "branch", "仓库"],
}

# ============================================
# 命令名称到标题的映射表
# ============================================
COMMAND_TITLE_MAP = {
    # 上下文管理命令
    "recover-context": "恢复会话上下文",
    "load-context": "加载会话上下文",
    "save-context": "保存会话上下文",
    "list-contexts": "列出会话上下文",
    "search-context": "搜索会话上下文",
    # 项目分析命令
    "analysis": "项目架构分析",
    "company": "页面功能分析",
    # Git 相关命令
    "git": "Git 操作",
    "commit": "代码提交",
    # 代码相关命令
    "code-explain": "代码解释分析",
    "ai-review": "AI 代码审查",
    "smart-debug": "智能调试",
    "test-generate": "生成测试用例",
    "doc-generate": "生成文档",
    # 项目脚手架命令
    "rust-project": "Rust 项目创建",
    "typescript-scaffold": "TypeScript 项目创建",
    # 其他命令
    "blog": "技术博客写作",
    "feature-development": "功能开发",
    "frontend-design": "前端设计",
}

# 应该跳过的命令（不作为标题）
SKIP_COMMANDS = [
    "clear",  # 清空会话命令，不代表会话内容
]

# 需要跳过的消息前缀
SKIP_PREFIXES = [
    "<command-",
    "Caveat:",
    "<local-",
    "This session is being continued",
    "<system-reminder>",
    "```",  # 代码块开头
    '{"type":',  # JSON 元数据
    "⏺",  # 特殊标记
]

# 不适合作为标题的消息前缀（用于标题提取）
SKIP_TITLE_PREFIXES = [
    # 问候语
    "你好",
    "您好",
    "hi ",
    "hello",
    # 命令
    "# 恢复会话上下文",
    "# 列出保存的会话上下文",
    "# 搜索会话上下文",
    "# 加载会话上下文",
    "# 保存会话上下文",
    "# 项目架构师",
    "/recover-context",
    "/save-context",
    "/list-contexts",
    "/load-context",
    "/search-context",
    "> /",  # 命令输出
    # 工具输出结果
    "📁",
    "📋",
    "❌",
    "✅",
    "⏺",
    "Exit code",
    "<tool_use_error>",
    "| 序号 |",
    "💡",
    # 系统消息
    "Todos have been",
    "(eval):",
    "no matches found",
    "Shell cwd",
    "The file",
    "Here's the result",
    "File created",
    "File updated",
    "Successfully",
    # 命令行输出
    "ls:",
    "-rw",
    "-r-",
    "drw",
    "===",
    "user:",
    "File content",
    "File size",
    "null Caveat",
    "User has answered",
    "35 /Users",
    "file-history",
    "Bash(",
]

# 不适合作为标题的消息模式（正则表达式）
SKIP_TITLE_PATTERNS = [
    r'^\d+\s+total',  # 如 "107881 total"
    r'^[\d\s]+$',  # 纯数字
    r'^[a-f0-9-]{36}',  # UUID
    r'^\s*$',  # 空白
    r'^\d+\s+/Users',  # 如 "35 /Users/..."
    r'^total\s+\d+',  # 如 "total 123"
    r'^\d+→',  # 如 "1→{"
    r'^\[\s*\{',  # JSON数组开头 "[ {"
    r'^null\s',  # null 开头
    r'^/Users/',  # 路径开头
    r'^[📄📝📁📋❌✅⏺💡🔍]',  # emoji开头
]

# 需要跳过的完整匹配
SKIP_EXACT = [
    "",
    " ",
]


def extract_command_name(content: str) -> Optional[str]:
    """
    从命令消息中提取命令名称

    支持的格式：
    1. <command-name>/xxx</command-name>
    2. <command-message>xxx</command-message>
    """
    if not content:
        return None

    # 匹配 <command-name>/xxx</command-name> 格式
    match = re.search(r'<command-name>/([^<]+)</command-name>', content)
    if match:
        return match.group(1).strip()

    # 匹配 <command-message>xxx</command-message> 格式
    match = re.search(r'<command-message>([^<]+)</command-message>', content)
    if match:
        return match.group(1).strip()

    return None


def extract_title_from_prompt(content: str) -> Optional[str]:
    """
    从提示词第一行提取标题

    支持的格式：
    1. # 标题内容
    2. ## 标题内容
    """
    if not content:
        return None

    # 获取第一行非空内容
    lines = content.strip().split('\n')
    for line in lines:
        line = line.strip()
        if not line:
            continue

        # 匹配 Markdown 标题格式 (# 或 ##)
        match = re.match(r'^#{1,2}\s+(.+)$', line)
        if match:
            title = match.group(1).strip()
            # 过滤掉太长的标题（可能是完整的提示词）
            if len(title) <= 20:
                return title

        break  # 只检查第一行非空内容

    return None


def get_title_from_command(command_name: str) -> Optional[str]:
    """
    根据命令名称获取对应的标题
    """
    if not command_name:
        return None

    # 清理命令名称
    clean_name = command_name.lstrip('/')

    # 跳过不应该作为标题的命令
    if clean_name in SKIP_COMMANDS:
        return None

    # 直接从映射表查找
    if clean_name in COMMAND_TITLE_MAP:
        return COMMAND_TITLE_MAP[clean_name]

    # 如果映射表中没有，生成一个默认标题
    # 将 kebab-case 转换为可读格式
    readable = clean_name.replace('-', ' ').replace('_', ' ').title()
    if len(readable) <= 20:
        return f"{readable} 命令"

    return None


def extract_content_string(content) -> str:
    """
    从消息内容中提取字符串

    消息内容可能是：
    1. 字符串类型 - 用户直接输入的消息
    2. 列表类型 - 工具调用结果（tool_result）
    """
    if content is None:
        return ""

    if isinstance(content, str):
        return content

    if isinstance(content, list):
        # 遍历列表，提取文本内容
        text_parts = []
        for item in content:
            if isinstance(item, str):
                text_parts.append(item)
            elif isinstance(item, dict):
                # 处理 tool_result 类型
                if item.get('type') == 'tool_result':
                    result_content = item.get('content', '')
                    if isinstance(result_content, str):
                        text_parts.append(result_content)
                # 处理 text 类型
                elif item.get('type') == 'text':
                    text_parts.append(item.get('text', ''))
        return ' '.join(text_parts)

    return str(content)


def is_valid_user_message(content: str) -> bool:
    """判断是否为有效的用户消息"""
    if not content:
        return False

    content_stripped = content.strip()

    # 长度检查
    if len(content_stripped) < 5:
        return False

    # 完整匹配检查
    if content_stripped in SKIP_EXACT:
        return False

    # 前缀检查
    if any(content_stripped.startswith(prefix) for prefix in SKIP_PREFIXES):
        return False

    # 跳过纯工具结果输出（通常以特定格式开头）
    if content_stripped.startswith('     1→') or content_stripped.startswith('total '):
        return False

    return True


def truncate_title(text: str, max_len: int = MAX_TITLE_LENGTH) -> str:
    """截断标题，保留完整词汇"""
    # 移除换行符和多余空格
    text = re.sub(r'\s+', ' ', text.strip())

    if len(text) <= max_len:
        return text

    # 截断并添加省略号
    truncated = text[:max_len - 3].strip()
    # 尝试在词边界截断（对于英文）
    last_space = truncated.rfind(' ')
    if last_space > max_len * 0.6:
        truncated = truncated[:last_space]

    return truncated + "..."


def is_good_title(content: str) -> bool:
    """判断消息是否适合作为标题（描述会话内容的一句话）"""
    if not content:
        return False

    content_stripped = content.strip()

    # 跳过不适合作为标题的消息前缀
    for prefix in SKIP_TITLE_PREFIXES:
        if content_stripped.lower().startswith(prefix.lower()):
            return False

    # 跳过匹配正则模式的消息
    for pattern in SKIP_TITLE_PATTERNS:
        if re.match(pattern, content_stripped, re.IGNORECASE):
            return False

    # 跳过太短的消息（如"你好"、"ok"等）
    if len(content_stripped) < 8:
        return False

    # 跳过纯问候语
    greetings = ["你好", "您好", "hi", "hello", "hey", "嗨", "ok", "好的", "谢谢", "thanks"]
    for greeting in greetings:
        if content_stripped.lower() == greeting.lower():
            return False
        if content_stripped.lower().startswith(greeting.lower() + ",") or content_stripped.lower().startswith(greeting.lower() + "，"):
            # 如果问候语后面有实际内容，提取后面的部分
            return False

    # 跳过只包含模型ID询问的消息
    if "模型" in content_stripped and "id" in content_stripped.lower() and len(content_stripped) < 20:
        return False

    return True


def extract_title_from_message(content: str) -> str:
    """从消息中提取标题，处理问候语等情况"""
    content = content.strip()

    # 如果以问候语开头，尝试提取后面的内容
    greeting_patterns = [
        r'^(你好|您好|hi|hello|hey|嗨)[,，。.!！\s]*',
    ]

    for pattern in greeting_patterns:
        match = re.match(pattern, content, re.IGNORECASE)
        if match:
            remaining = content[match.end():].strip()
            if len(remaining) >= 8:
                return truncate_title(remaining)

    return truncate_title(content)


def generate_tags(content: str, max_tags: int = MAX_TAGS) -> List[str]:
    """
    分层优先级标签生成

    优先级顺序：任务类型 > 业务领域 > 技术框架
    确保标签能描述会话内容，而不仅仅是技术栈
    """
    content_lower = content.lower()
    tags = []

    # 第一层：任务类型（最重要，至少匹配1-2个）
    for tag, keywords in TASK_TAGS.items():
        if any(kw.lower() in content_lower for kw in keywords):
            if tag not in tags:
                tags.append(tag)
                if len(tags) >= 2:  # 最多2个任务类型
                    break

    # 第二层：业务领域
    if len(tags) < max_tags:
        for tag, keywords in DOMAIN_TAGS.items():
            if any(kw.lower() in content_lower for kw in keywords):
                if tag not in tags:
                    tags.append(tag)
                    if len(tags) >= max_tags:
                        break

    # 第三层：技术框架（填充剩余位置）
    if len(tags) < max_tags:
        for tag, keywords in TECH_TAGS.items():
            if any(kw.lower() in content_lower for kw in keywords):
                if tag not in tags:
                    tags.append(tag)
                    if len(tags) >= max_tags:
                        break

    return tags[:max_tags]


def parse_jsonl_file(file_path: Path) -> Tuple[Optional[str], List[str], int, Optional[str], Optional[str]]:
    """
    解析 JSONL 文件，提取会话信息

    标题提取策略（组合方案）：
    1. 优先从命令名称提取（如 /recover-context → "恢复会话上下文"）
    2. 如果没有命令，从提示词第一行提取（如 # 项目架构分析）
    3. 如果都没有，从用户消息中找到好的标题
    4. 最后才显示"无标题会话"

    返回: (标题, 标签列表, 消息数量, 创建时间, 会话ID)
    """
    title = None
    command_title = None  # 从命令提取的标题
    prompt_title = None   # 从提示词提取的标题
    all_content = []
    all_user_messages = []  # 保存所有用户消息，用于找到好的标题
    all_raw_messages = []   # 保存原始消息，用于命令和提示词提取
    message_count = 0
    created_at = None
    session_id = None

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f):
                if line_num > 500:  # 只读取前500行以提高性能
                    break

                try:
                    data = json.loads(line.strip())
                except json.JSONDecodeError:
                    continue

                # 提取会话ID
                if not session_id and data.get('sessionId'):
                    session_id = data['sessionId']

                # 提取创建时间（第一条记录的时间戳）
                if not created_at and data.get('timestamp'):
                    created_at = data['timestamp']

                # 处理用户消息
                if data.get('type') == 'user':
                    message = data.get('message', {})
                    raw_content = message.get('content', '')

                    # 保存原始消息用于命令和提示词提取（只保存前20条）
                    if len(all_raw_messages) < 20:
                        if isinstance(raw_content, str):
                            all_raw_messages.append(raw_content)
                        elif isinstance(raw_content, list):
                            for item in raw_content:
                                if isinstance(item, dict):
                                    if item.get('type') == 'text':
                                        all_raw_messages.append(item.get('text', ''))

                    content = extract_content_string(raw_content)

                    if is_valid_user_message(content):
                        message_count += 1
                        all_content.append(content)
                        all_user_messages.append(content)

                # 处理助手消息（用于标签分析）
                elif data.get('type') == 'assistant':
                    message = data.get('message', {})
                    raw_content = message.get('content', '')
                    content = extract_content_string(raw_content)
                    if content and len(content) > 10:
                        all_content.append(content[:500])  # 只取前500字符

    except Exception as e:
        print(f"Error parsing {file_path}: {e}", file=sys.stderr)
        return None, [], 0, None, None

    # ============================================
    # 组合方案：标题提取
    # ============================================

    # 方案1：从命令名称提取标题
    for msg in all_raw_messages[:10]:
        cmd_name = extract_command_name(msg)
        if cmd_name:
            command_title = get_title_from_command(cmd_name)
            if command_title:
                break

    # 方案2：从提示词第一行提取标题
    if not command_title:
        for msg in all_raw_messages[:10]:
            prompt_title = extract_title_from_prompt(msg)
            if prompt_title:
                break

    # 方案3：从用户消息中找到好的标题
    user_title = None
    for msg in all_user_messages[:15]:
        if is_good_title(msg):
            user_title = extract_title_from_message(msg)
            break

    # 按优先级选择标题
    if command_title:
        title = command_title
    elif prompt_title:
        title = prompt_title
    elif user_title:
        title = user_title
    else:
        title = "无标题会话"

    # 生成标签（基于所有内容）
    combined_content = ' '.join(all_content[:10])  # 取前10条消息
    tags = generate_tags(combined_content)

    return title, tags, message_count, created_at, session_id


def get_file_info(file_path: Path) -> Dict:
    """获取文件基本信息"""
    stat = file_path.stat()
    return {
        "size": stat.st_size,
        "mtime": datetime.fromtimestamp(stat.st_mtime).isoformat(),
    }


def load_existing_index(index_path: Path) -> Dict:
    """加载现有索引"""
    if index_path.exists():
        try:
            with open(index_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception:
            pass
    return {
        "version": INDEX_VERSION,
        "updated_at": None,
        "sessions": {}
    }


def save_index(index_path: Path, index_data: Dict):
    """保存索引文件"""
    index_data["updated_at"] = datetime.now().isoformat()
    with open(index_path, 'w', encoding='utf-8') as f:
        json.dump(index_data, f, ensure_ascii=False, indent=2)


def update_index(session_dir: Path, force: bool = False) -> Dict:
    """
    更新会话索引

    Args:
        session_dir: 会话目录路径
        force: 是否强制全量更新

    Returns:
        更新后的索引数据
    """
    index_path = session_dir / INDEX_FILE_NAME
    index_data = load_existing_index(index_path)

    # 获取所有 JSONL 文件
    jsonl_files = list(session_dir.glob("*.jsonl"))

    # 跳过 agent-*.jsonl 文件（子代理会话）
    jsonl_files = [f for f in jsonl_files if not f.name.startswith("agent-")]

    # 当前文件集合
    current_files = {f.stem: f for f in jsonl_files}

    # 删除不存在的会话索引
    sessions_to_remove = [
        sid for sid in index_data["sessions"]
        if sid not in current_files
    ]
    for sid in sessions_to_remove:
        del index_data["sessions"][sid]

    # 更新或添加会话索引
    updated_count = 0
    for session_id, file_path in current_files.items():
        file_info = get_file_info(file_path)
        existing = index_data["sessions"].get(session_id, {})

        # 检查是否需要更新
        needs_update = force or (
            not existing or
            existing.get("file_size") != file_info["size"] or
            existing.get("file_mtime") != file_info["mtime"]
        )

        if needs_update:
            title, tags, msg_count, created_at, _ = parse_jsonl_file(file_path)

            index_data["sessions"][session_id] = {
                "title": title,
                "tags": tags,
                "message_count": msg_count,
                "file_size": file_info["size"],
                "file_mtime": file_info["mtime"],
                "created_at": created_at,
                "last_indexed": datetime.now().isoformat(),
            }
            updated_count += 1

    # 保存索引
    if updated_count > 0 or sessions_to_remove:
        save_index(index_path, index_data)

    return index_data


def format_size(size_bytes: int) -> str:
    """格式化文件大小"""
    if size_bytes < 1024:
        return f"{size_bytes} B"
    elif size_bytes < 1024 * 1024:
        return f"{size_bytes / 1024:.0f} KB"
    else:
        return f"{size_bytes / (1024 * 1024):.1f} MB"


def format_table_output(session_dir: Path, index_data: Dict, limit: int = 10, search: str = None) -> str:
    """格式化表格输出

    Args:
        session_dir: 会话目录路径
        index_data: 索引数据
        limit: 显示的最大行数，0 表示不限制
        search: 搜索关键词（匹配标题、标签、日期）
    """
    sessions = index_data.get("sessions", {})

    if not sessions:
        return "暂无可恢复的会话文件"

    # 按文件修改时间排序（倒序）
    sorted_sessions = sorted(
        sessions.items(),
        key=lambda x: x[1].get("file_mtime", ""),
        reverse=True
    )

    total_count = len(sorted_sessions)

    # 应用搜索过滤
    if search:
        search_lower = search.lower()
        filtered_sessions = []
        for session_id, info in sorted_sessions:
            # 搜索标题
            title = (info.get("title") or "").lower()
            # 搜索标签
            tags = " ".join(info.get("tags", [])).lower()
            # 搜索日期
            mtime = info.get("file_mtime", "")

            if (search_lower in title or
                search_lower in tags or
                search_lower in mtime or
                search_lower in session_id.lower()):
                filtered_sessions.append((session_id, info))

        sorted_sessions = filtered_sessions

    # 构建表格
    lines = []
    lines.append(f"📁 会话目录: {session_dir}")
    lines.append("")

    filtered_count = len(sorted_sessions)

    # 搜索模式下的标题
    if search:
        if filtered_count == 0:
            lines.append(f"🔍 搜索 \"{search}\" 无结果（共 {total_count} 个会话）")
            lines.append("")
            lines.append("💡 尝试其他关键词，或使用 `--limit 0` 查看全部会话")
            return "\n".join(lines)
        else:
            lines.append(f"🔍 搜索 \"{search}\" 找到 {filtered_count} 个匹配（共 {total_count} 个会话）：")
    else:
        # 应用 limit
        if limit > 0 and filtered_count > limit:
            sorted_sessions = sorted_sessions[:limit]
            lines.append(f"📋 可恢复的会话文件（按时间倒序，显示前 {limit} 个，共 {total_count} 个）：")
        else:
            lines.append(f"📋 可恢复的会话文件（按时间倒序，共 {total_count} 个）：")

    lines.append("")
    lines.append("| 序号 | 文件名                               | 修改时间         | 主要内容                          | 标签                              | 大小     |")
    lines.append("|------|--------------------------------------|------------------|----------------------------------|-----------------------------------|----------|")

    for idx, (session_id, info) in enumerate(sorted_sessions, 1):
        # 解析修改时间
        mtime = info.get("file_mtime", "")
        if mtime:
            try:
                dt = datetime.fromisoformat(mtime)
                mtime_str = dt.strftime("%Y-%m-%d %H:%M")
            except:
                mtime_str = mtime[:16]
        else:
            mtime_str = "未知"

        # 标题（限制长度）
        title = info.get("title") or "无标题"
        if len(title) > 32:
            title = title[:29] + "..."

        # 标签（完整显示，不截断）
        tags = info.get("tags", [])
        tags_str = " ".join([f"#{t}" for t in tags]) if tags else "-"

        # 大小
        size = info.get("file_size", 0)
        size_str = format_size(size)
        # 大文件标记
        if size > 1024 * 1024:  # > 1MB
            size_str += " ⭐"

        # 文件名（session_id + .jsonl）
        filename = f"{session_id}.jsonl"

        # 格式化行（标签列宽度增加到35字符）
        lines.append(
            f"| [{idx:2d}] | {filename:36s} | {mtime_str:16s} | {title:32s} | {tags_str:35s} | {size_str:8s} |"
        )

    lines.append("")
    lines.append("---")
    lines.append("💡 使用 `/recover-context [序号]` 恢复指定会话（如 `/recover-context 3`）")
    lines.append("💡 使用 `/recover-context latest` 恢复最新会话")
    if not search:
        if limit > 0 and total_count > limit:
            lines.append(f"💡 输入 `more` 显示更多，或 `more 50` 显示前 50 个")
        lines.append(f"💡 输入 `search 关键词` 搜索会话（如 `search 错误处理`）")

    return "\n".join(lines)


def format_json_output(index_data: Dict) -> str:
    """格式化 JSON 输出"""
    return json.dumps(index_data, ensure_ascii=False, indent=2)


def auto_discover_session_dir() -> Optional[Path]:
    """
    自动发现当前项目的会话目录

    根据当前工作目录，自动查找对应的 Claude Code 会话目录
    """
    cwd = os.getcwd()

    # Claude Code 使用 - 替换 / 作为目录名
    encoded_path = cwd.replace("/", "-")

    # 尝试两种可能的路径格式
    possible_paths = [
        PROJECTS_DIR / encoded_path,           # 标准格式
        PROJECTS_DIR / f"-{encoded_path}",     # 带前缀格式（某些系统）
    ]

    for session_dir in possible_paths:
        if session_dir.exists():
            # 验证目录中有 JSONL 文件
            jsonl_files = list(session_dir.glob("*.jsonl"))
            if jsonl_files:
                return session_dir

    return None


def main():
    """主函数"""
    import argparse

    parser = argparse.ArgumentParser(description="Claude Code 会话索引器")
    parser.add_argument("session_dir", nargs='?', default=None,
                        help="会话目录路径（可选，使用 --auto 时自动发现）")
    parser.add_argument("--auto", "-a", action="store_true",
                        help="自动发现当前项目的会话目录")
    parser.add_argument("--output", "-o", choices=["json", "table"], default="table",
                        help="输出格式 (default: table)")
    parser.add_argument("--force", "-f", action="store_true",
                        help="强制全量更新索引")
    parser.add_argument("--limit", "-l", type=int, default=10,
                        help="表格显示的最大行数 (default: 10, 0=不限制)")
    parser.add_argument("--search", "-s", type=str, default=None,
                        help="搜索关键词（匹配标题、标签、日期）")

    args = parser.parse_args()

    # 确定会话目录
    if args.auto:
        session_dir = auto_discover_session_dir()
        if not session_dir:
            print("❌ 未找到当前项目的会话目录", file=sys.stderr)
            print(f"提示: 请确认在项目目录中运行，或手动指定会话目录路径", file=sys.stderr)
            sys.exit(1)
    elif args.session_dir:
        session_dir = Path(args.session_dir)
    else:
        # 既没有 --auto 也没有指定目录，显示帮助
        parser.print_help()
        print("\n示例用法:")
        print("  python3 session-indexer.py --auto           # 自动发现当前项目会话")
        print("  python3 session-indexer.py /path/to/dir     # 指定会话目录")
        sys.exit(1)

    if not session_dir.exists():
        print(f"错误: 目录不存在 - {session_dir}", file=sys.stderr)
        sys.exit(1)

    # 更新索引
    index_data = update_index(session_dir, force=args.force)

    # 输出结果
    if args.output == "json":
        print(format_json_output(index_data))
    else:
        print(format_table_output(session_dir, index_data, limit=args.limit, search=args.search))


if __name__ == "__main__":
    main()
