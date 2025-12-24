# 常见问题 (FAQ)

本文档收集了使用 Claude Context Manager 过程中的常见问题和解决方案。

## 安装问题

### Q1: 安装脚本没有执行权限

**问题**：
```bash
./install.sh: Permission denied
```

**解决方案**：
```bash
chmod +x install.sh
./install.sh
```

---

### Q2: ~/.claude 目录不存在

**问题**：
```
[✗] Claude 配置目录不存在
```

**解决方案**：

1. 确保已安装 Claude Code
2. 运行一次 Claude Code 命令让它自动创建配置目录：
   ```bash
   claude --version
   ```
3. 或者手动创建：
   ```bash
   mkdir -p ~/.claude
   ```

---

### Q3: 安装后命令不显示

**问题**：安装成功但在 Claude Code 中看不到新命令

**解决方案**：

1. **完全关闭 Claude Code**（不是最小化）
2. **重新打开 Claude Code**
3. **等待 3-5 秒**让配置加载
4. **输入 `/`** 查看命令列表

如果仍然不显示，检查文件是否正确安装：
```bash
ls -la ~/.claude/commands/ | grep context
```

---

### Q4: macOS 安全提示阻止运行

**问题**：macOS 提示"无法验证开发者"

**解决方案**：

```bash
# 方法1：在终端中直接运行
bash install.sh

# 方法2：移除隔离属性
xattr -d com.apple.quarantine install.sh
./install.sh
```

---

## 使用问题

### Q5: 保存的内容不完整

**问题**：保存的上下文缺少部分对话内容

**原因**：Claude 有上下文窗口限制，当对话过长时，早期内容会被压缩。

**解决方案**：

1. **尽早保存**：完成重要阶段后立即保存
2. **分段保存**：大任务分多次保存
3. **注意提示**：看到 "Conversation compacted" 立即保存

---

### Q6: 标签生成不准确

**问题**：自动生成的标签与内容不相关

**解决方案**：

1. **手动修改**：编辑保存的 `.md` 文件，修改 `tags` 字段
2. **在标题中提示**：使用包含关键词的标题
   ```
   /save-context React用户认证开发
   ```

---

### Q7: 加载上下文后 Claude 不理解

**问题**：加载历史上下文后，Claude 似乎没有理解之前的内容

**解决方案**：

1. **检查加载是否成功**：确认看到了上下文内容
2. **明确告知**：
   ```
   请根据上面加载的上下文，继续之前的任务...
   ```
3. **提供关键提示**：
   ```
   我们之前在开发用户认证功能，进度是...
   ```

---

### Q8: 搜索找不到结果

**问题**：明明有相关会话，但搜索不到

**可能原因**：
1. 搜索词拼写错误
2. 索引文件损坏
3. 搜索词不在索引范围内

**解决方案**：

1. **检查拼写**
2. **使用标签搜索**：`/search-context #认证`
3. **重建索引**：
   ```bash
   rm ~/.claude/conversations/index.json
   # 然后运行 /list-contexts 自动重建
   ```

---

### Q9: 时间戳显示不正确

**问题**：保存的时间与实际时间不符

**可能原因**：系统时区设置问题

**解决方案**：

1. **检查系统时区**：
   ```bash
   date
   ```
2. **设置正确时区**：
   - macOS: 系统偏好设置 → 日期与时间
   - Linux: `timedatectl set-timezone Asia/Shanghai`

---

## 文件问题

### Q10: 会话文件损坏

**问题**：某个会话文件无法打开或格式错误

**解决方案**：

1. **查看文件内容**：
   ```bash
   cat ~/.claude/conversations/文件名.md
   ```
2. **手动修复**：如果是 YAML frontmatter 格式问题，手动修正
3. **删除损坏文件**：如果无法修复，删除该文件
   ```bash
   rm ~/.claude/conversations/损坏文件.md
   ```

---

### Q11: 索引文件损坏

**问题**：`index.json` 格式错误导致命令失败

**解决方案**：

```bash
# 1. 删除损坏的索引
rm ~/.claude/conversations/index.json

# 2. 创建新的空索引
echo '{"version":"1.0.0","conversations":[]}' > ~/.claude/conversations/index.json

# 3. 运行 /list-contexts 自动重建索引
```

---

### Q12: 磁盘空间不足

**问题**：保存失败，提示空间不足

**解决方案**：

1. **检查空间**：
   ```bash
   df -h ~
   ```
2. **清理旧会话**：
   ```bash
   # 列出超过 30 天的文件
   find ~/.claude/conversations -name "*.md" -mtime +30

   # 删除旧文件（谨慎操作）
   find ~/.claude/conversations -name "*.md" -mtime +30 -delete
   ```
3. **归档会话**：移动到其他位置

---

## 兼容性问题

### Q13: 与其他 Claude Code 插件冲突

**问题**：安装后其他功能不正常

**解决方案**：

1. **检查冲突**：查看是否有同名文件
   ```bash
   ls ~/.claude/commands/
   ```
2. **备份并重装**：
   ```bash
   # 备份现有配置
   cp -r ~/.claude ~/.claude-backup

   # 重新安装
   ./install.sh
   ```

---

### Q14: 不同版本的 Claude Code 兼容性

**问题**：升级 Claude Code 后功能不正常

**解决方案**：

1. **重新安装**：运行最新版的安装脚本
2. **检查更新**：
   ```bash
   cd claude-context-manager
   git pull origin main
   ./install.sh
   ```

---

## 性能问题

### Q15: 保存/加载速度慢

**问题**：命令执行时间过长

**可能原因**：
1. 会话文件过多
2. 单个文件过大
3. 磁盘 I/O 慢

**解决方案**：

1. **清理旧会话**
2. **检查文件大小**：
   ```bash
   du -sh ~/.claude/conversations/*
   ```
3. **分割大文件**：如果单个会话过大，考虑分段保存

---

### Q16: 列表显示太慢

**问题**：`/list-contexts` 执行很慢

**解决方案**：

1. **检查会话数量**：
   ```bash
   ls ~/.claude/conversations/*.md | wc -l
   ```
2. **归档旧会话**：
   ```bash
   mkdir -p ~/.claude/conversations/archive
   mv ~/.claude/conversations/2024-*.md ~/.claude/conversations/archive/
   ```

---

## 数据安全

### Q17: 如何备份会话数据

**解决方案**：

```bash
# 简单备份
cp -r ~/.claude/conversations ~/claude-backup-$(date +%Y%m%d)

# 压缩备份
tar -czvf ~/claude-backup-$(date +%Y%m%d).tar.gz ~/.claude/conversations

# 同步到云存储
rsync -av ~/.claude/conversations ~/Dropbox/claude-backup/
```

---

### Q18: 如何恢复数据

**解决方案**：

```bash
# 从备份恢复
cp -r ~/claude-backup-20251224/* ~/.claude/conversations/

# 从压缩包恢复
tar -xzvf ~/claude-backup-20251224.tar.gz -C ~/.claude/
```

---

### Q19: 会话中有敏感信息

**问题**：会话中包含密码、密钥等敏感信息

**解决方案**：

1. **保存前检查**：确保不包含敏感信息
2. **编辑文件**：删除敏感内容
   ```bash
   vim ~/.claude/conversations/文件名.md
   ```
3. **使用环境变量**：代码中使用环境变量而不是硬编码

---

## 卸载问题

### Q20: 卸载后如何保留数据

**问题**：想卸载工具但保留历史会话

**解决方案**：

运行卸载脚本时选择保留数据：
```bash
./uninstall.sh
# 当询问是否删除会话数据时，选择 "n"
```

或手动卸载，只删除工具文件：
```bash
rm ~/.claude/commands/*-context.md
rm -rf ~/.claude/skills/context-manager
# 保留 ~/.claude/conversations
```

---

## 其他问题

### Q21: 如何查看完整错误日志

**解决方案**：

Claude Code 的日志通常在终端输出中。如需详细调试：
1. 在终端中运行 Claude Code
2. 观察执行命令时的输出
3. 记录错误信息

---

### Q22: 如何贡献代码或报告问题

**解决方案**：

1. **报告问题**：在 [GitHub Issues](https://github.com/gaoziman/claude-context-manager/issues) 提交
2. **贡献代码**：
   - Fork 仓库
   - 创建功能分支
   - 提交 Pull Request

---

### Q23: 如何获取帮助

**解决方案**：

1. **查看文档**：阅读本项目的所有文档
2. **GitHub Issues**：搜索或提交问题
3. **社区讨论**：在 GitHub Discussions 参与讨论

---

## 还有问题？

如果你的问题不在上述列表中，请：

1. **检查文档**：确保已阅读所有相关文档
2. **搜索 Issues**：查看是否有人遇到过类似问题
3. **提交 Issue**：详细描述你的问题，包括：
   - 操作系统版本
   - Claude Code 版本
   - 错误信息
   - 复现步骤

[提交 Issue](https://github.com/gaoziman/claude-context-manager/issues/new)
