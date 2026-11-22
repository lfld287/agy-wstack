---
name: no-comments
description: "调用 Comment Sicko，修复采纳的问题，并提出将注释声称的约束落实为代码或检查的方案。"
disable-model-invocation: true
---

# 清理注释

调用 Comment Sicko，并处理采纳的问题。

尊重 Comment Sicko 的独立判断。

## 范围

使用调用者指定的文件或 diff。若未指定，检查当前状态相对基线分支的 diff。基线默认是 `main`，检查包括工作区。

## 步骤

1. 单席调用示例为 `invoke_subagent(TypeName: "comment-sicko", Role: "Comment review", Prompt: "在开始任何工作前，先完整阅读 <worker.md 的绝对路径>。\n只读审查 <diff 或文件列表> 并返回报告。", Model: "inherit", Workspace: "inherit")`。按 **poteto-mode** 技能的子代理章节为每项工作选择推理档位。直接引用该技能，省去规则复述。若 AGY 尚未注册 `comment-sicko`，用 `invoke_subagent` 调用通用只读子代理，逐字传入 [`references/comment-sicko.md`](references/comment-sicko.md) 的提示词，再附上 diff 或文件列表。在其他环境中，Claude Code 可用 `Agent`（`subagent_type: general-purpose`），OpenCode 可用 `task`（`subagent_type: general`），Codex 可用 `spawn_agent`，前提是工具权限可限制为只读。两类子代理均只使用只读工具并返回审查报告，禁止删除或编辑文件。无法提供只读子代理时，由主会话按该提示词审查。
2. 检查审查报告。驳回越界建议、删除例外保护注释的建议、理由失实的 `MUST KILL`，以及误判有意保留的代码的标记。自有代码中出人意料的行为仍应按标记调整结构，删除对应注释。补查范围内漏掉的 lint 和 TypeScript 抑制指令。涉及正确性或安全的抑制指令仍按 `MUST KILL` 处理。在采纳对缺少理由的 `IMPORTANT` 或 `do not remove` 的删除或保留建议前，追踪对应符号，或对它调用 `/why`。有范围内证据表明符合例外的注释予以保留。涉及外部规则的 `REVIEW` 项保留到有人核实该规则，并报告为未解决。驳回报告时指出原因并重跑一次。若重跑仍有结果被驳回，将它们列为未解决。由主会话执行采纳的删除和编辑。
3. 直接处理简单的已采纳问题，例如删除死代码路径、去掉参数或使用真实 API。如果修复需要重新设计结构，对已采纳的问题和周边代码调用一次 `/architect`，做到草图为止。由 `/architect` 确定结构，第 4 步负责实现。
4. 在范围内实现最小的根因修复，移除所有点名的变通代码。如果根因超出范围，完成范围内的最小修复，并把其余部分列为未解决。**principle-fix-root-causes** 和 **principle-redesign-from-first-principles** 只指导修复意图。遵守分析范围，避免修理范围外的同类问题。禁止追加只掩盖症状的防护逻辑。
5. 约束性注释会写 `do not remove`、`do not change wording` 或 `talk to X before changing`。我们无法改变的约束继续保留注释。提出范围内成本最低的类型约束、运行时检查、测试或 CI lint，并等待用户在交互中批准。无人值守和评估运行须由调用者预先批准。获批后先落实约束，再删除注释。否则删除注释，报告尚未落实的约束，并勾勒范围外的工作。
6. 报告删除数量、保留的注释、`REVIEW` 保留项、重跑情况、架构草图、修复、提出的约束落实方案、实际落实的约束、尚未强制执行的约束和其他未解决工作。
