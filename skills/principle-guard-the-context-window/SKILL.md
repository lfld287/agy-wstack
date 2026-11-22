---
name: principle-guard-the-context-window
description: "当大量输出、长文件、重复读取或规划并行分派导致上下文快被占满时使用。把大批量材料交给子代理处理，主线程只保留摘要。"
disable-model-invocation: true
---

# 保护上下文窗口

**上下文溢出**会降低推理质量，使压缩后的信息失真，并中断工作。

**做法**

- **控制各阶段的规模和范围。** 限制每个阶段的文件数量，设定交互轮次预算，并计入所用机制的开销。通过 `invoke_subagent` 委派大批量材料的处理，主线程只接收摘要。
