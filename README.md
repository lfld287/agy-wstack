# agy-wstack

`agy-wstack` 是 Lauren Tan（Poteto）的 pstack 在 Antigravity（AGY）上的简体中文移植。它用 playbook 把调查、实现、审查和验证串成可重跑的流程，让并行任务有明确的输入、写入边界和完成条件。上游源码及提交记录见 [cursor/plugins/pstack](https://github.com/cursor/plugins/tree/main/pstack)，独立镜像见 [backnotprop/pstack](https://github.com/backnotprop/pstack)。

## 安装

将含 `plugin.json`、`agents/`、`skills/`、`scripts/` 的本地插件目录放在以下任一位置。

| 范围 | 目录 |
| --- | --- |
| 用户 | `~/.gemini/config/plugins/agy-wstack` |
| 项目 | `.agents/plugins/agy-wstack` |
| 显式注册 | 用户的 `~/.gemini/config/plugins.json` 或项目的 `.agents/plugins.json` |

显式注册时，`entries[].path` 指向插件的**父目录**，AGY 扫描其直接子目录。例如本地插件在 `~/dev/plugins/agy-wstack` 时，可在用户配置中添加：

```json
{
  "entries": [
    { "path": "~/dev/plugins", "include_only": ["agy-wstack"] }
  ]
}
```

已有设置时合并该条目。项目配置使用可信工作区或仓库内的路径。重新打开会话后，用 `agy plugin list` 查看加载状态，或用 `agy plugin validate <插件根目录>` 检查文件。

## 开始使用

1. 运行 [`/setup-pstack`](skills/setup-pstack/SKILL.md)，确认原生级别、本地 CLI 和各角色的推理预算。用户规则写到 `~/.gemini/config/rules/pstack-models.md`。项目可在 `.agents/rules/pstack-models.md` 逐角色覆盖。
2. 对需要调查、实现或审查的任务运行 [`/poteto-mode`](skills/poteto-mode/SKILL.md)。主会话选择 playbook，建立待办并按步骤调度。独立技能也可直接调用。
3. 跑重复检查时用 `schedule`，在简报里明确完成条件和允许的外部操作。需要恢复任务时提供上一轮会话和现场证据。

```text
/poteto-mode 空闲时滚动位置仍在偏移。先复现，修根因，再驱动界面确认。
/poteto-mode 用同一输入比较两个 Markdown 渲染原型，保留各自结果。
/arena 给出同一模块的多个设计，按调用边界、可读性和验证成本比较。
/pstack-swarm 检查每个包的本地验证脚本。每个工作者负责一组，交一份汇总。
/interrogate 审查这个变更。只保留能用实际命令证实的问题。
```

`poteto-agent` 执行被分配的工作。它读完整的 Poteto 模式和原则索引，主会话负责 playbook 和独立验收。 `comment-sicko` 只读审查注释，通常由 `no-comments` 调用。两者都用 AGY 原生代理定义。 [poteto-agent](agents/poteto-agent.md)、[comment-sicko](agents/comment-sicko.md)

## 双引擎多模型

| 路径 | 调度 | 模型值示例 |
| --- | --- | --- |
| AGY 原生 | 同轮并发逐席调用 `invoke_subagent`，每次在顶层传 `TypeName`、`Role`、`Prompt`、`Model`、`Workspace` | `agy:pro`、`agy:flash`、`agy:flash_lite`、`agy:inherit` |
| 本地 CLI | `run_command`（`WaitMsBeforeAsync: 500`）运行分发脚本，`manage_task` 管理后台任务 | `codex:gpt-5.4`、`codex:profile:reviewer`、`pi:anthropic/claude-opus-4-6:high` |

混编的一轮先发出所有外部任务，再在同轮并发逐席调用 `invoke_subagent`。每席使用独立输出和明确的工作区，父会话验证实际产物。执行引擎和模型供应商分别记录，同一模型经不同 CLI 调用仍是一家供应商。

```bash
./scripts/multi-model-dispatch.sh --check
```

探测命令检查 CLI、Codex 登录和 Pi 模型目录。具体模型、凭证和 profile 仍需在本机确认。例如三项均可用时，规则可写成以下一行：

```text
arena runners: agy:pro, codex:gpt-5.4, pi:anthropic/claude-opus-4-6:high
```

未配置时，代码和判断用 `agy:pro`，机械工作和验证用 `agy:flash`。原生面板以 `agy:pro, agy:flash` 起步，已确认的外部模型可加入。模型可用性不足时说明具体退席或回退。工具字段、工作区模式、规则格式和后台任务示例见 [Antigravity 手册](docs/harness/antigravity.md)。

## 22 个 playbook

路径相对于插件根目录为 `skills/poteto-mode/playbooks/<name>.md`。先读对应的正文。当前安装缺少正文时，可用兼容的上游副本。

| 文件 | 适用场景 |
| --- | --- |
| `investigation.md` | 只读调查系统行为、数据流和实现缘由。 |
| `bug-fix.md` | 先复现，再修根因，最后运行真实路径验证。 |
| `perf-issue.md` | 对已有性能问题采样，对照基线改进。 |
| `hillclimb.md` | 围绕一个目标指标反复验证假设并落地可测改善。 |
| `runtime-forensics.md` | 通过现场埋点诊断泄漏、空转和抖动。 |
| `trace-forensics.md` | 分析已捕获的 profile、trace、spindump 或堆快照。 |
| `feature.md` | 从数据形状和行为契约出发实现功能。 |
| `refactoring.md` | 调整结构，维持已有行为。 |
| `prototype.md` | 用独立原型低成本验证分歧或选择设计。 |
| `visual-parity.md` | 验证两份界面实现的像素级一致性。 |
| `authoring-a-skill.md` | 创建或编辑技能。 |
| `eval.md` | 用盲评衡量技能或提示词变化的影响。 |
| `babysit.md` | 追踪 PR 冲突、审查线程、CI 与合并条件。 |
| `shipping.md` | 独立核验后按授权从栈底落地连续验证通过的 PR。 |
| `autonomous-run.md` | 持续执行长任务直到满足验收条件。 |
| `autopilot-full.md` | 按 PR 分派，验证每个可合并版本，按授权合并。 |
| `autopilot-stack.md` | 准备经过验证的待审 PR，按真实依赖堆叠。 |
| `session-pickup.md` | 恢复上一会话或接手代理未完成的工作。 |
| `pause-safely.md` | 留下可恢复的状态和继续执行所需的证据。 |
| `multi-phase-plan.md` | 组织跨阶段迁移或堆叠 PR。 |
| `worktree-cleanup.md` | 安全清理陈旧工作树及 iOS 模拟器。 |
| `opening-a-pr.md` | 从有序变更创建一份可审阅的 PR。 |

## 58 个技能速查

以下与上游技能目录同名。五个核心入口附本地链接，其余条目可按名称查找。单独安装时检查依赖。`teach` 使用 `how` 和 `why`，`technical-writing` 使用 `unslop`，`architect` 使用 `arena`，`blast-radius` 使用 `arena`、`how`、`why` 和 `unslop`。行为验证与形式验证各有创建和维护入口，形式验证使用 `statechart`。`ketchup` 使用 `bro`，`ketchup-video` 使用两者。`poteto-mode` 按任务调用原则和其他技能，`poteto-help` 按当前问题查阅相关技能。

| 技能 | 何时使用 |
| --- | --- |
| `architect` | 跨边界前定义类型、签名、调用姿势与模块形状。 |
| [`arena`](skills/arena/SKILL.md) | 同题并行产出多份候选，交叉评审后整合验证。 |
| `automate-me` | 从已有会话提炼个人工作模式，生成或更新 `<name>-mode`。 |
| `benchmark-checklist` | 报告性能数据前核对限制因素、调参、误差和可复现性。 |
| `blast-radius` | 用实际运行证明小改动的关键安全条件，查找 diff 外影响。 |
| `bro` | 用普通语言重述上一条消息。 |
| `correct` | 找出反复发生的代理错误，用架构、类型、lint 或测试阻止重犯。 |
| `create-formal-verification-skill` | 给竞态、重试、状态机等高风险问题建立形式验证技能。 |
| `create-verification-skill` | 生成按真实用户方式驱动 UI、CLI 或服务的项目验证技能。 |
| `figure-it-out` | 缺少合适 playbook 时，设计可审计、能验证的任务流程。 |
| `how` | 讲解子系统结构、运行路径和归属边界。 |
| `in-your-own-words` | 在动手前用自己的话复述目标与问题。 |
| [`interrogate`](skills/interrogate/SKILL.md) | 让不同模型挑战变更，只保留实际运行证明的发现。 |
| `ketchup` | 用简明语言和小图回顾上次消息后进展及需要用户决策的事项。 |
| `ketchup-video` | 把进度回顾做成带字幕的短视频，并附待决事项。 |
| `maintain-formal-verification-skill` | 在代码演进后同步、重跑形式验证并判定失败根因。 |
| `maintain-verification-skill` | 对照源码与真实运行校验验证技能的功能图。 |
| `make-bot-ui` | 为已有 Grok Bot 设计 webhook 控制面板，处理 sender key 与 Tailscale。 |
| `no-comments` | 调用 Comment Sicko 审查注释并处理有根据的发现。 |
| `poteto-help` | 了解如何安装或选择技能、playbook 与原则。 |
| [`poteto-mode`](skills/poteto-mode/SKILL.md) | 用于需要明确分工和验收的工程任务，总入口。 |
| `principle-attack-the-premise` | 多次同类修复失败时，直接检验共同前提。 |
| `principle-boundary-discipline` | 在系统边界校验输入，保持内部逻辑清楚。 |
| `principle-build-the-lever` | 交付能执行或验证任务的工具。 |
| `principle-encode-lessons-in-structure` | 将重复提醒编码进结构或自动检查。 |
| `principle-exhaust-the-design-space` | 对缺乏先例的决策做两三个方案原型。 |
| `principle-experience-first` | 优先解决用户体验中的实际问题。 |
| `principle-explain-the-number` | 查明测量限制和数据实际代表的内容。 |
| `principle-fix-root-causes` | 找到最早错误状态并修根因。 |
| `principle-foundational-thinking` | 先定数据形状、脚手架顺序和共享状态边界。 |
| `principle-guard-the-context-window` | 委派长读与大输出，主会话保留必要证据。 |
| `principle-laziness-protocol` | 优先删除冗余，选择最小有效改动。 |
| `principle-make-operations-idempotent` | 让崩溃和重试后的操作收敛到同一状态。 |
| `principle-migrate-callers-then-delete-legacy-apis` | 同一轮迁移调用方并删除旧内部 API。 |
| `principle-minimize-reader-load` | 减少追踪层级和隐含状态。 |
| `principle-model-the-domain` | 用合适的结构表达领域状态和规则。 |
| `principle-never-block-on-the-human` | 授权范围内自行完成可逆选择。 |
| `principle-outcome-oriented-execution` | 按可验证阶段收敛到迁移或重写目标。 |
| `principle-prove-it-works` | 交付前验证真实产物和行为。 |
| `principle-redesign-from-first-principles` | 将新需求纳入整体设计。 |
| `principle-separate-before-serializing-shared-state` | 并发先拆分写入对象，再考虑串行约束。 |
| `principle-sequence-verifiable-units` | 每个变更单元都能独立验证。 |
| `principle-subtract-before-you-add` | 先清理旧负担，再添加或重构。 |
| `principle-test-behavior-not-implementation` | 以可观察行为编写测试。 |
| `principle-type-system-discipline` | 用类型表达约束，减少可表示的非法状态。 |
| `recall` | 从已授权的会话与项目记录恢复工作上下文。 |
| `reflect` | 从本次会话提炼长期经验并更新承载它的技能。 |
| [`setup-pstack`](skills/setup-pstack/SKILL.md) | 探测可用模型，设定角色及预算，写模型规则。 |
| `sharpen` | 追问任务应有的证据、专业方法和验收，改写提示词。 |
| `show-me-your-work` | 用 TSV 留下长任务的决策、理由和证据。 |
| `statechart` | 检查 TLA+ 模型并绘制 Mermaid 状态图，给出反例最短路径。 |
| [`pstack-swarm`](skills/pstack-swarm/SKILL.md) | 并行覆盖多个切片或竞速，给出统一报告（为避开 AGY 原生 `/swarm` 命令而重命名）。 |
| `tdd` | 明确要求 TDD、回归测试，或缺陷有便宜可靠的本地测试路径时使用。 |
| `teach` | 合并 `how` 与 `why`，逐步解释系统及设计动机。 |
| `technical-writing` | 按文档层次与技术写作规则检查文档、RFC 和 PR。 |
| `typescript-best-practices` | 读写 TypeScript 时检查具体类型和语法。 |
| `unslop` | 删除冗余、套话和模板化表达。 |
| `why` | 从提交、PR 和原始记录追溯设计取舍，标明推断。 |

## 与上游宿主的差异

| 环节 | Cursor | Claude Code | Antigravity |
| --- | --- | --- | --- |
| 插件 | Cursor 插件市场 | `cursor-plugins` 市场的生成版，命令通常带 `/pstack:` 命名空间 | 本地原生插件或 `plugins.json` 注册，沿用技能名 |
| 代理 | `Task`、模型 slug、可选云代理 | `Agent`、模型和 effort、可选 worktree | `invoke_subagent` 的 AGY 级别与 workspace，外部 CLI 后台调度 |
| 模型规则 | `~/.cursor/rules/pstack-models.mdc` | `~/.claude/rules/pstack-models.md` | 用户／项目的 `pstack-models.md` 按角色合并 |
| 定时与 PR | `/loop`、Cursor Automations、Bugbot、云代理 | 命令或逐步跳过 Cursor 专属能力 | `schedule`、`manage_task`、现有 forge 检查与审查线程 |
| 发布前验证 | `cursor-team-kit` 的控制和去冗余技能 | 已安装的等效工具 | 符合当前权限的本地 CLI、UI 驱动和 diff 检查 |

上游 Benny 自动化包依赖 Cursor Automations。AGY 中的等效动作与跳过规则见 [宿主适配手册](docs/harness/antigravity.md#cursor-专属功能)。可在安装了相应技能后用 `/automate-me` 从会话总结个人工作模式，用 `/setup-pstack` 更新模型规则。上游教程涵盖首次任务、设计、构建、验证、无人值守和接手。 [上游指南](https://github.com/backnotprop/pstack/tree/main/docs/guide)

## 许可

MIT。保留 pstack 原作者 Lauren Tan 的版权声明。 [LICENSE](LICENSE)
