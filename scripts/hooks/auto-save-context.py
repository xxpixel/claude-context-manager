#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Claude Code Stop Hook - 自动保存会话上下文

当 Claude Code 任务停止时自动执行，将当前会话保存到 conversations 目录。
与 Claude Context Manager 系统集成。

作者: Leo Coder
版本: 1.0.0
"""

import json
import os
import sys
import uuid
import re
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Optional, Tuple

# ============================================
# 配置常量
# ============================================

CLAUDE_DIR = Path.home() / ".claude"
CONVERSATIONS_DIR = CLAUDE_DIR / "conversations"
PROJECTS_DIR = CLAUDE_DIR / "projects"
INDEX_FILE = CONVERSATIONS_DIR / "index.json"
LOG_FILE = CLAUDE_DIR / "auto-save.log"

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
        pass  # 日志写入失败不影响主流程

# ============================================
# 核心函数
# ============================================

def get_encoded_path(project_path: str) -> str:
    """将项目路径编码为 Claude Code 使用的目录名格式"""
    # Claude Code 使用 - 替换 /，保留开头的 -
    encoded = project_path.replace("/", "-")
    return encoded

def find_latest_session(project_path: str) -> Optional[Path]:
    """查找项目对应的最新会话 JSONL 文件"""
    encoded_path = get_encoded_path(project_path)
    session_dir = PROJECTS_DIR / encoded_path

    if not session_dir.exists():
        log(f"会话目录不存在: {session_dir}", "WARNING")
        return None

    # 查找所有 JSONL 文件（排除 agent- 开头的子代理文件）
    jsonl_files = [
        f for f in session_dir.glob("*.jsonl")
        if not f.name.startswith("agent-")
    ]

    if not jsonl_files:
        log(f"未找到会话文件: {session_dir}", "WARNING")
        return None

    # 按修改时间排序，返回最新的
    latest = max(jsonl_files, key=lambda f: f.stat().st_mtime)
    return latest

def parse_jsonl(file_path: Path) -> Tuple[List[Dict], str]:
    """
    解析 JSONL 文件，提取用户消息

    返回: (用户消息列表, 会话ID)
    """
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

                # 获取会话 ID
                if not session_id and "sessionId" in data:
                    session_id = data["sessionId"]

                # 只处理用户消息
                if data.get("type") != "user":
                    continue

                message = data.get("message", {})
                content = message.get("content", "")
                timestamp = data.get("timestamp", "")

                # 提取消息内容
                text = ""
                if isinstance(content, str):
                    text = content
                elif isinstance(content, list):
                    for item in content:
                        if isinstance(item, dict) and item.get("type") == "text":
                            text = item.get("text", "")
                            break

                # 过滤命令消息和空消息
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
        return f"自动保存 - {project_name}"

    # 取第一条有效消息的前 30 个字符
    first_msg = user_messages[0]["content"]
    # 清理换行、多余空格和特殊字符
    first_msg = re.sub(r'\s+', ' ', first_msg).strip()
    first_msg = re.sub(r'[#*`\[\](){}]', '', first_msg)  # 移除 Markdown 符号

    if len(first_msg) > 30:
        title = first_msg[:27] + "..."
    else:
        title = first_msg

    # 如果标题太短或为空，使用项目名
    if len(title) < 5:
        return f"自动保存 - {project_name}"

    return f"自动保存 - {title}"

def generate_tags(user_messages: List[Dict]) -> List[str]:
    """根据用户消息内容生成标签"""
    tags = ["auto-save", "自动保存"]

    # 合并所有消息内容
    all_content = " ".join([m["content"] for m in user_messages]).lower()

    # 关键词匹配
    keyword_tags = {
        "bug": "debug",
        "fix": "debug",
        "error": "debug",
        "分析": "analysis",
        "analysis": "analysis",
        "架构": "architecture",
        "设计": "design",
        "测试": "testing",
        "test": "testing",
        "部署": "deployment",
        "deploy": "deployment",
        "api": "api",
        "数据库": "database",
        "database": "database",
        "前端": "frontend",
        "后端": "backend",
        "react": "React",
        "vue": "Vue",
        "python": "Python",
        "java": "Java",
        "typescript": "TypeScript",
        "javascript": "JavaScript",
    }

    for keyword, tag in keyword_tags.items():
        if keyword in all_content and tag not in tags:
            tags.append(tag)

    return tags[:8]  # 最多 8 个标签

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
    source_file: str
) -> Tuple[str, Dict]:
    """
    生成 Markdown 文件内容和元数据

    返回: (Markdown 内容, 元数据字典)
    """
    now = datetime.now()
    timestamp = now.strftime("%Y-%m-%dT%H:%M:%S+08:00")
    date_str = now.strftime("%Y-%m-%d %H:%M:%S")

    # 生成元数据
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
        "summary": "Stop Hook 自动保存的会话上下文",
        "type": "auto-save",
        "source_session": session_id
    }

    # 生成 YAML Frontmatter
    yaml_tags = json.dumps(tags, ensure_ascii=False)
    frontmatter = f'''---
id: "{doc_id}"
title: "{title}"
project: "{project_name}"
project_path: "{project_path}"
created_at: "{timestamp}"
updated_at: "{timestamp}"
tags: {yaml_tags}
summary: "Stop Hook 自动保存的会话上下文"
type: "auto-save"
source_session: "{session_id}"
---'''

    # 生成 Markdown 内容
    content = f'''{frontmatter}

# 自动保存的会话上下文

> 此文件由 Stop Hook 自动生成。如需完整的智能总结，请使用 `/save-context` 命令覆盖。

## 📋 会话信息

| 属性 | 值 |
|------|------|
| **项目** | {project_name} |
| **路径** | {project_path} |
| **保存时间** | {date_str} |
| **保存类型** | 自动保存 (Stop Hook) |
| **会话ID** | {session_id} |
| **源文件** | {source_file} |

## 💬 用户消息记录

'''

    # 添加用户消息
    for i, msg in enumerate(user_messages, 1):
        msg_time = format_timestamp(msg["timestamp"]) if msg["timestamp"] else "未知时间"
        msg_content = msg["content"]

        # 截断过长的消息
        if len(msg_content) > 2000:
            msg_content = msg_content[:1997] + "..."

        content += f'''### 消息 {i} ({msg_time})

{msg_content}

'''

    # 添加注意事项
    content += f'''## ⚠️ 注意事项

1. 此文件为自动保存，内容为原始用户消息
2. 如需智能总结和结构化内容，请使用 `/save-context` 命令
3. 使用 `/save-context` 会覆盖此自动保存文件

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
    """查找已存在的同一会话的自动保存记录"""
    for i, conv in enumerate(index_data.get("conversations", [])):
        if conv.get("type") == "auto-save" and conv.get("source_session") == session_id:
            return i
    return None

def main():
    """主函数"""
    log("=" * 50)
    log("Stop Hook 自动保存开始")

    # 获取当前工作目录
    project_path = os.getcwd()
    project_name = os.path.basename(project_path)

    log(f"项目路径: {project_path}")
    log(f"项目名称: {project_name}")

    # 确保 conversations 目录存在
    CONVERSATIONS_DIR.mkdir(parents=True, exist_ok=True)

    # 查找最新的会话文件
    session_file = find_latest_session(project_path)
    if not session_file:
        log("未找到会话文件，跳过自动保存")
        return

    log(f"会话文件: {session_file}")

    # 解析 JSONL 文件
    user_messages, session_id = parse_jsonl(session_file)

    if not user_messages:
        log("未找到用户消息，跳过自动保存")
        return

    log(f"提取到 {len(user_messages)} 条用户消息")
    log(f"会话ID: {session_id}")

    # 生成 Markdown 内容
    markdown_content, metadata = generate_markdown(
        user_messages,
        project_name,
        project_path,
        session_id,
        session_file.name
    )

    # 加载索引
    index_data = load_index()

    # 检查是否已有同一会话的自动保存
    existing_idx = find_existing_auto_save(index_data, session_id)

    if existing_idx is not None:
        # 更新现有记录
        old_file = index_data["conversations"][existing_idx].get("file", "")
        old_file_path = CONVERSATIONS_DIR / old_file

        # 删除旧文件
        if old_file_path.exists():
            old_file_path.unlink()
            log(f"删除旧的自动保存文件: {old_file}")

        # 更新索引记录
        index_data["conversations"][existing_idx] = metadata
        log("更新现有自动保存记录")
    else:
        # 添加新记录（插入到列表开头）
        index_data["conversations"].insert(0, metadata)
        log("添加新的自动保存记录")

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
        return

    # 更新索引中的文件名
    if existing_idx is not None:
        index_data["conversations"][existing_idx]["file"] = filename
    else:
        index_data["conversations"][0]["file"] = filename

    # 保存索引
    save_index(index_data)
    log("更新 index.json 完成")

    # 更新会话索引
    update_session_index(project_path)

    # 发送系统通知（macOS）
    try:
        import subprocess
        subprocess.run([
            "osascript", "-e",
            f'display notification "会话已自动保存: {project_name}" with title "Claude Context Manager" sound name "Glass"'
        ], capture_output=True, timeout=5)
    except Exception:
        pass  # 通知失败不影响主流程

    log("Stop Hook 自动保存完成")
    log("=" * 50)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        log(f"自动保存失败: {e}", "ERROR")
        sys.exit(1)
