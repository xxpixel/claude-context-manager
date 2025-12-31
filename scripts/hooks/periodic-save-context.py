#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Claude Code PostToolUse Hook - 周期性保存会话上下文

每次工具调用后触发，达到阈值时保存会话上下文。
与 Claude Context Manager 系统集成。

作者: Leo Coder
版本: 1.0.0
"""

import json
import os
import sys
import uuid
import re
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Dict, Optional, Tuple

# ============================================
# 配置常量
# ============================================

CLAUDE_DIR = Path.home() / ".claude"
CONVERSATIONS_DIR = CLAUDE_DIR / "conversations"
PROJECTS_DIR = CLAUDE_DIR / "projects"
STATE_DIR = CLAUDE_DIR / "periodic-save-state"
INDEX_FILE = CONVERSATIONS_DIR / "index.json"
LOG_FILE = CLAUDE_DIR / "periodic-save.log"

# 触发阈值配置
SAVE_INTERVAL_COUNT = 20      # 每 20 次工具调用保存一次
SAVE_INTERVAL_MINUTES = 5     # 或每 5 分钟保存一次

# ============================================
# 日志函数
# ============================================

def log(message: str, level: str = "INFO"):
    """记录日志到文件"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"[{timestamp}] [{level}] {message}\n"

    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(log_entry)
    except Exception:
        pass

# ============================================
# 状态管理函数
# ============================================

def get_state_file(project_path: str) -> Path:
    """获取项目对应的状态文件路径"""
    # 使用项目路径的 hash 作为文件名，避免路径字符问题
    import hashlib
    path_hash = hashlib.md5(project_path.encode()).hexdigest()[:16]
    return STATE_DIR / f"{path_hash}.json"

def load_state(project_path: str) -> Dict:
    """加载项目的保存状态"""
    state_file = get_state_file(project_path)

    if not state_file.exists():
        return {
            "count": 0,
            "last_save": None,
            "session_id": None,
            "project_path": project_path
        }

    try:
        with open(state_file, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        log(f"加载状态文件失败: {e}", "ERROR")
        return {
            "count": 0,
            "last_save": None,
            "session_id": None,
            "project_path": project_path
        }

def save_state(project_path: str, state: Dict):
    """保存项目的保存状态"""
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    state_file = get_state_file(project_path)

    try:
        with open(state_file, "w", encoding="utf-8") as f:
            json.dump(state, f, ensure_ascii=False, indent=2)
    except Exception as e:
        log(f"保存状态文件失败: {e}", "ERROR")

def should_save(state: Dict) -> Tuple[bool, str]:
    """
    判断是否应该保存

    返回: (是否保存, 原因)
    """
    # 检查计数阈值
    if state["count"] >= SAVE_INTERVAL_COUNT:
        return True, f"达到计数阈值 ({state['count']} >= {SAVE_INTERVAL_COUNT})"

    # 检查时间间隔
    if state["last_save"]:
        try:
            last_save_time = datetime.fromisoformat(state["last_save"])
            time_diff = datetime.now() - last_save_time
            if time_diff >= timedelta(minutes=SAVE_INTERVAL_MINUTES):
                return True, f"达到时间阈值 ({time_diff.total_seconds() / 60:.1f} 分钟)"
        except Exception:
            pass

    return False, "未达到保存阈值"

# ============================================
# 核心函数（复用 auto-save-context.py 的逻辑）
# ============================================

def get_encoded_path(project_path: str) -> str:
    """将项目路径编码为 Claude Code 使用的目录名格式"""
    encoded = project_path.replace("/", "-")
    return encoded

def find_latest_session(project_path: str) -> Optional[Path]:
    """查找项目对应的最新会话 JSONL 文件"""
    encoded_path = get_encoded_path(project_path)
    session_dir = PROJECTS_DIR / encoded_path

    if not session_dir.exists():
        return None

    jsonl_files = [
        f for f in session_dir.glob("*.jsonl")
        if not f.name.startswith("agent-")
    ]

    if not jsonl_files:
        return None

    latest = max(jsonl_files, key=lambda f: f.stat().st_mtime)
    return latest

def parse_jsonl(file_path: Path) -> Tuple[List[Dict], str]:
    """解析 JSONL 文件，提取用户消息"""
    user_messages = []
    session_id = ""

    try:
        with open(file_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue

                try:
                    data = json.loads(line)
                except json.JSONDecodeError:
                    continue

                if not session_id and "sessionId" in data:
                    session_id = data["sessionId"]

                if data.get("type") != "user":
                    continue

                message = data.get("message", {})
                content = message.get("content", "")
                timestamp = data.get("timestamp", "")

                text = ""
                if isinstance(content, str):
                    text = content
                elif isinstance(content, list):
                    for item in content:
                        if isinstance(item, dict) and item.get("type") == "text":
                            text = item.get("text", "")
                            break

                if text and not text.startswith("<command-message>"):
                    user_messages.append({
                        "content": text,
                        "timestamp": timestamp
                    })

    except Exception as e:
        log(f"解析 JSONL 失败: {e}", "ERROR")

    return user_messages, session_id

def generate_title(user_messages: List[Dict], project_name: str) -> str:
    """根据用户消息生成标题"""
    if not user_messages:
        return f"周期保存 - {project_name}"

    first_msg = user_messages[0]["content"]
    first_msg = re.sub(r'\s+', ' ', first_msg).strip()
    first_msg = re.sub(r'[#*`\[\](){}]', '', first_msg)

    if len(first_msg) > 30:
        title = first_msg[:27] + "..."
    else:
        title = first_msg

    if len(title) < 5:
        return f"周期保存 - {project_name}"

    return f"周期保存 - {title}"

def generate_tags(user_messages: List[Dict]) -> List[str]:
    """根据用户消息内容生成标签"""
    tags = ["periodic-save", "周期保存"]

    all_content = " ".join([m["content"] for m in user_messages]).lower()

    keyword_tags = {
        "bug": "debug", "fix": "debug", "error": "debug",
        "分析": "analysis", "analysis": "analysis",
        "架构": "architecture", "设计": "design",
        "测试": "testing", "test": "testing",
        "部署": "deployment", "deploy": "deployment",
        "api": "api", "数据库": "database", "database": "database",
        "前端": "frontend", "后端": "backend",
        "react": "React", "vue": "Vue",
        "python": "Python", "java": "Java",
        "typescript": "TypeScript", "javascript": "JavaScript",
    }

    for keyword, tag in keyword_tags.items():
        if keyword in all_content and tag not in tags:
            tags.append(tag)

    return tags[:8]

def format_timestamp(iso_timestamp: str) -> str:
    """格式化 ISO 时间戳为可读格式"""
    try:
        dt = datetime.fromisoformat(iso_timestamp.replace("Z", "+00:00"))
        return dt.strftime("%Y-%m-%d %H:%M:%S")
    except Exception:
        return iso_timestamp

def generate_markdown(
    user_messages: List[Dict],
    project_name: str,
    project_path: str,
    session_id: str,
    source_file: str,
    save_reason: str
) -> Tuple[str, Dict]:
    """生成 Markdown 文件内容和元数据"""
    now = datetime.now()
    timestamp = now.strftime("%Y-%m-%dT%H:%M:%S+08:00")
    date_str = now.strftime("%Y-%m-%d %H:%M:%S")

    doc_id = str(uuid.uuid4())
    title = generate_title(user_messages, project_name)
    tags = generate_tags(user_messages)

    metadata = {
        "id": doc_id,
        "title": title,
        "project": project_name,
        "project_path": project_path,
        "created_at": timestamp,
        "updated_at": timestamp,
        "tags": tags,
        "summary": "PostToolUse Hook 周期性保存的会话上下文",
        "type": "periodic-save",
        "source_session": session_id
    }

    yaml_tags = json.dumps(tags, ensure_ascii=False)
    frontmatter = f'''---
id: "{doc_id}"
title: "{title}"
project: "{project_name}"
project_path: "{project_path}"
created_at: "{timestamp}"
updated_at: "{timestamp}"
tags: {yaml_tags}
summary: "PostToolUse Hook 周期性保存的会话上下文"
type: "periodic-save"
source_session: "{session_id}"
---'''

    content = f'''{frontmatter}

# 周期性保存的会话上下文

> 此文件由 PostToolUse Hook 周期性自动生成。如需完整的智能总结，请使用 `/save-context` 命令覆盖。

## 📋 会话信息

| 属性 | 值 |
|------|------|
| **项目** | {project_name} |
| **路径** | {project_path} |
| **保存时间** | {date_str} |
| **保存类型** | 周期保存 (PostToolUse Hook) |
| **触发原因** | {save_reason} |
| **会话ID** | {session_id} |
| **源文件** | {source_file} |

## 💬 用户消息记录

'''

    for i, msg in enumerate(user_messages, 1):
        msg_time = format_timestamp(msg["timestamp"]) if msg["timestamp"] else "未知时间"
        msg_content = msg["content"]

        if len(msg_content) > 2000:
            msg_content = msg_content[:1997] + "..."

        content += f'''### 消息 {i} ({msg_time})

{msg_content}

'''

    content += f'''## ⚠️ 注意事项

1. 此文件为周期性自动保存，内容为原始用户消息
2. 如需智能总结和结构化内容，请使用 `/save-context` 命令
3. 使用 `/save-context` 会覆盖此周期保存文件
4. Stop Hook 的自动保存也会覆盖此文件

## 🔗 相关文件

- 源 JSONL 文件：`~/.claude/projects/{get_encoded_path(project_path)}/{source_file}`
'''

    return content, metadata

def load_index() -> Dict:
    """加载 index.json"""
    if not INDEX_FILE.exists():
        return {
            "version": "1.0.0",
            "description": "Claude Code 会话上下文索引文件",
            "conversations": []
        }

    try:
        with open(INDEX_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        log(f"加载 index.json 失败: {e}", "ERROR")
        return {
            "version": "1.0.0",
            "description": "Claude Code 会话上下文索引文件",
            "conversations": []
        }

def save_index(index_data: Dict):
    """保存 index.json"""
    try:
        with open(INDEX_FILE, "w", encoding="utf-8") as f:
            json.dump(index_data, f, ensure_ascii=False, indent=2)
    except Exception as e:
        log(f"保存 index.json 失败: {e}", "ERROR")
        raise

def update_session_index(project_path: str):
    """更新会话索引文件"""
    try:
        import subprocess

        # 获取会话目录路径
        encoded_path = get_encoded_path(project_path)
        session_dir = PROJECTS_DIR / encoded_path

        if not session_dir.exists():
            log(f"会话目录不存在，跳过索引更新: {session_dir}", "WARNING")
            return

        # 查找索引脚本
        indexer_script = Path(__file__).parent.parent / "session-indexer.py"

        if not indexer_script.exists():
            log(f"索引脚本不存在: {indexer_script}", "WARNING")
            return

        # 调用索引脚本
        result = subprocess.run(
            ["python3", str(indexer_script), str(session_dir), "-o", "json"],
            capture_output=True,
            text=True,
            timeout=30
        )

        if result.returncode == 0:
            log(f"会话索引更新成功: {session_dir}")
        else:
            log(f"会话索引更新失败: {result.stderr}", "WARNING")

    except subprocess.TimeoutExpired:
        log("会话索引更新超时", "WARNING")
    except Exception as e:
        log(f"会话索引更新异常: {e}", "WARNING")

def find_existing_auto_save(index_data: Dict, session_id: str) -> Optional[int]:
    """查找已存在的同一会话的自动保存记录（包括 auto-save 和 periodic-save）"""
    for i, conv in enumerate(index_data.get("conversations", [])):
        conv_type = conv.get("type", "")
        if conv_type in ("auto-save", "periodic-save") and conv.get("source_session") == session_id:
            return i
    return None

def do_save(project_path: str, project_name: str, save_reason: str) -> bool:
    """执行保存操作"""
    log(f"开始周期性保存: {save_reason}")

    # 确保目录存在
    CONVERSATIONS_DIR.mkdir(parents=True, exist_ok=True)

    # 查找最新的会话文件
    session_file = find_latest_session(project_path)
    if not session_file:
        log("未找到会话文件，跳过保存")
        return False

    # 解析 JSONL 文件
    user_messages, session_id = parse_jsonl(session_file)

    if not user_messages:
        log("未找到用户消息，跳过保存")
        return False

    log(f"提取到 {len(user_messages)} 条用户消息")

    # 生成 Markdown 内容
    markdown_content, metadata = generate_markdown(
        user_messages,
        project_name,
        project_path,
        session_id,
        session_file.name,
        save_reason
    )

    # 加载索引
    index_data = load_index()

    # 检查是否已有同一会话的自动保存
    existing_idx = find_existing_auto_save(index_data, session_id)

    if existing_idx is not None:
        old_file = index_data["conversations"][existing_idx].get("file", "")
        old_file_path = CONVERSATIONS_DIR / old_file

        if old_file_path.exists():
            old_file_path.unlink()
            log(f"删除旧的保存文件: {old_file}")

        index_data["conversations"][existing_idx] = metadata
        log("更新现有保存记录")
    else:
        index_data["conversations"].insert(0, metadata)
        log("添加新的保存记录")

    # 生成文件名
    date_prefix = datetime.now().strftime("%Y-%m-%d")
    safe_title = re.sub(r'[^\w\u4e00-\u9fff\-]', '_', metadata["title"])[:50]
    filename = f"{date_prefix}_{safe_title}.md"
    metadata["file"] = filename

    # 保存 Markdown 文件
    md_file_path = CONVERSATIONS_DIR / filename
    try:
        with open(md_file_path, "w", encoding="utf-8") as f:
            f.write(markdown_content)
        log(f"保存 Markdown 文件: {filename}")
    except Exception as e:
        log(f"保存 Markdown 文件失败: {e}", "ERROR")
        return False

    # 更新索引中的文件名
    if existing_idx is not None:
        index_data["conversations"][existing_idx]["file"] = filename
    else:
        index_data["conversations"][0]["file"] = filename

    # 保存索引
    save_index(index_data)
    log("周期性保存完成")

    # 更新会话索引
    update_session_index(project_path)

    return True

# ============================================
# 主函数
# ============================================

def main():
    """主函数"""
    # 获取当前工作目录
    project_path = os.getcwd()
    project_name = os.path.basename(project_path)

    # 加载状态
    state = load_state(project_path)

    # 增加计数
    state["count"] = state.get("count", 0) + 1

    # 判断是否需要保存
    need_save, reason = should_save(state)

    if need_save:
        log(f"触发周期性保存: {reason}")

        # 执行保存
        success = do_save(project_path, project_name, reason)

        if success:
            # 重置状态
            state["count"] = 0
            state["last_save"] = datetime.now().isoformat()
            log("状态已重置")
    else:
        log(f"计数 +1 (当前: {state['count']}), 未达到保存阈值")

    # 保存状态
    save_state(project_path, state)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        log(f"周期性保存失败: {e}", "ERROR")
        sys.exit(1)
