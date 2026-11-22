### 编写或修改技能

**由你把握技能的行文风格。**

1. AGY 中用 `skill-creator` 完成 Cursor `create-skill` 的工作。未安装 `skill-creator` 时，按 agentskills.io 的 Agent Skills 格式编写。
2. 校验技能。确认 frontmatter 包含 `name` 和 `description`，引用的文件存在，跨技能链接可解析。
3. 涉及结构时编写测试用例。纯主观判断可跳过。
4. 执行[开 PR](opening-a-pr.md)。

拿不准就删，只留会影响决策的文字。直接写要做什么，只有规则难以理解时才解释缘由。措辞与适用范围相称。按 **principle-encode-lessons-in-structure** 指向类型定义、README 或配置等结构化依据。用路径把任务交给其他技能，避免重复写已有规则。遇到反复执行却没有记录的流程，提议新建技能。

**回复**应包含技能概要、关键设计决定和校验结果。
