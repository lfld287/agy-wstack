---
name: show-me-your-work
description: "为长时间或无人值守的工作保留可审阅的 TSV 决策日志，每个决定一行，记录事项、理由、证据和结果。默认保留在本地，评审者需要这些记录来判断结果时才提交。用于 /show-me-your-work、自主或多阶段运行，以及用户离开后要回看工作时。"
disable-model-invocation: true
---

# 展示工作过程

维护一份权威日志。

## 格式

使用一个 TSV 文件。每个决定一行，每个单元格内只有一行。证据用指向原件的链接或路径。

复制 `references/decision-log-template.tsv`（表头行）创建空日志。各列如下。

- **ts.** ISO 8601 时间戳。
- **phase.** 阶段或工作线。
- **decision.** 一行写明选择或实际执行的动作。
- **why.** 用平实的话写理由。如果决定来自某条原则，解释实际理由，省去术语标签。
- **evidence.** 给出可核实的链接或路径，例如提交 SHA、PR 编号、`file:line`，或产物、跟踪记录、截图的路径。保持单行简短。
- **result.** 结果或完成条件的状态，例如 `tests green`、`reverted`、`pixel-diff 0`、`INCONCLUSIVE`、`open`。

下面的示例用平实的话记录决定，供评审者快速浏览。

```
ts	phase	decision	why	evidence	result
2026-05-24T09:02:00Z	frame	counted the work first, about 100 components and roughly 75 hours	wanted to know the size before starting a long run	commit 3a9f1c2	found 5 things to sort out before starting
2026-05-24T09:40:00Z	harness	took screenshots of the old version before changing anything	so we can compare old against new and catch any visual change	scripts/snapshot.sh, baseline/	saved 120 reference screenshots
2026-05-24T11:15:00Z	widget	moved the widget styles over without changing how it looks	keep the change small and the result identical	commit 7c21e0a, pixel-diff 0	looks identical, tests pass
2026-05-24T12:30:00Z	widget	threw out a helper's work because its screenshots were blank	checked the real files instead of trusting its summary	worktree reset	reverted, tightened the instructions for next time
```

## 追加记录

按向同事说明工作时的方式写。使用日常用语和具体动作。日志文字也应用 **unslop**。

用 `run_command` 调用 `<技能根目录>/scripts/log.sh <logfile> <phase> <decision> <why> <evidence> <result>`。脚本填入 `ts`，首次使用时写入表头，清理意外的制表符和换行，并给以 `=`、`+`、`-` 或 `@` 开头的单元格加单引号。也可以直接用 `printf` 追加一行。单元格来自生成结果或用户输入时，同样注意这些字符。

记录决策点和检查点，例如选定一条路径，完成一个单元及其验证结果，改变方向或撤回及其触发原因，发现阻塞，修复某道检查关卡。循环运行时每轮记录一行。跳过琐碎或一看便知的动作。

一次运行指一次代理会话，包括后续轮次及其摘要。接手、换代理或新建聊天都会开启新的运行。向已有记录的日志追加内容时，本次运行的第一行使用 `start`，在另一次运行的 `start` 行后恢复追加时也一样。因此，后续轮次回来使用同一日志时，先读最后几行，确认期间有无其他运行写入。`start` 行记下此前由其他运行写入的记录所覆盖的 `ts` 范围，证据列标明本次运行，例如代理 ID。`start` 只用于这个目的。

## 存放位置

默认把日志当本地工作产物。放在工作目录下的 `decisions.tsv`。多个任务同时进行时，使用 `.audit/<task-slug>.tsv`。默认排除在 Git 提交之外。

只有当工作规模大到评审者需要借助过程记录确认结果时，才提交日志。

## 规则

- 只追加。判断失误时追加一行覆盖原判断。禁止改写或删除历史。
- 优先使用已提交脚本产生的证据，少用临时手工检查。参见 **encode-lessons-in-structure** 原则技能。

## 对照会话记录审计日志

本轮运行结束、交还结果之前，核查日志是否属实。读取当前工作区对应的本次会话记录。AGY 优先使用宿主提供的 `transcriptPath`，其次在当前 AGY 会话数据目录中定位记录。两者都不可用时，回退到 AGY CLI 默认路径 `~/.gemini/antigravity-cli/brain/<conversation-id>/.system_generated/logs/transcript.jsonl`。Cursor 使用系统提示指定的 `agent-transcripts/`。Claude Code 使用 `~/.claude/projects/<slug>/`（工作区路径中所有非字母数字字符均换成 `-`）。Pi 使用 `~/.pi/agent/sessions/--<slug>--/`。Codex 使用 `~/.codex/sessions/` 下首行 `payload.cwd` 等于工作区路径的文件。只查当前项目，避免扫到其他项目的私密聊天。将本次运行写入的各段逐行与实际过程比对。每段从本次运行的一个 `start` 行开始，如果由本次运行创建日志，则从首行开始。下一次其他运行的 `start` 行标志该段结束。

- 核对每一行都对应真实的决定或行动。
- 核对每一行指向的证据可打开，内容也证明该行的说法。
- 如果影响工作的分支选择、方向调整或放弃的做法没有记录，追加一行补齐。

按事实修正日志。审计过程中任何行都保留，编造的行也一样。某行既无真实决定也无真实行动，或主张、证据有误时，追加一行说明实际经过，并提供可查的证据来覆盖旧行。审计只检查本次运行写入的各段。如果本轮工作另外发现其中某个范围外的条目有误，也像其他错误决定一样追加一行纠正。

## 跨模型审阅决策记录

交还结果前，安排与实施者来自不同供应商的模型审阅。按 **poteto-mode** 的子代理章节选择推理档位。AGY 内置子代理用 `invoke_subagent` 调用。需要不同供应商的模型时，可按模型规则用 `run_command` 启动 `codex` 或 `pi` 的后台审阅任务。每个简报首行要求读取绝对路径的 `worker.md`。审阅者阅读日志和本轮会话记录，标记用户该关注之处。审阅只检查不理想或有风险的地方，由独立审阅者完成。

- 记录的决定缺少证据，或证据不足。
- 跳过了验证，或声称验证但会话记录无法证明。
- 回头看有风险的选择，例如决定过早、扩大范围或掩盖症状。
- 用户粗读时容易错过的缺漏。

生成了决策日志的运行，每次回复末尾都加「需关注」（Attention）一节。首行单列审阅模型（`reviewed by <model>`），再逐条列标记，指向具体日志行或会话时刻。无标记时可写 `No flags`。模型名只放在首行。

## 审阅日志的方法

从上到下读，顺着证据指针抽查。GitHub 会把已提交的 TSV 显示为表格。终端里运行 `column -s$'\t' -t decisions.tsv`。

## 与其他技能配合

其他技能的审计日志统一交给本技能处理。按名称引用本技能，由它定义格式，省去列说明的复述。
