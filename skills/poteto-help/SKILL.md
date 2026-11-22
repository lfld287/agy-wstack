---
name: poteto-help
description: "帮助用户配置 pstack、使用 /poteto-mode，并为任务选择技能、playbook 或原则。输入 /poteto-help 并附上问题。"
disable-model-invocation: true
---

# Poteto 帮助

回答用户关于 pstack 的问题，提供一条可以直接发送的提示词，并链接答案所在文件。帮助类问题回答如何做即可。运行 pstack 会实际消耗 token，由用户准备好后发送提示词。

「用 pstack 修这个缺陷」之类的消息是在委托工作。读取 [`poteto-mode`](../poteto-mode/SKILL.md)，按它执行。说明一次如何在 AGY 中让后续任务继续遵循该模式。

本文件把问题映射到对应技能和指南。细节以目标文件为准。引用前先读目标文件，若与本索引冲突，以目标文件为准。这里的链接指向本机安装目录，用户未必能打开。优先给出工作区中的中文版路径，需要公开上游对照时，从 `https://github.com/cursor/plugins/blob/main/pstack/` 拼接文件相对路径。

## 确定用户需要什么

从消息和谈话推断需求。用户给了具体场景，例如「哪个技能审查 PR」，直接进入对应小节。如果仍不明确，用 `ask_question` 给出以下选项，只回答用户选中的一项。

- 完成安装配置
- 用 `/poteto-mode` 开始任务
- 为场景选择技能
- 挽救跑偏的任务
- 定制我的 pstack

检查会影响答案的状态，仅在确实影响时说明。

- AGY 的用户规则 `~/.gemini/config/rules/pstack-models.md` 和项目覆盖 `.agents/rules/pstack-models.md` 都不存在，说明当前没有配置角色。各角色使用默认模型。Claude Code 的用户规则在 `~/.claude/rules/pstack-models.md`，其他兼容环境可用 `~/.agents/pstack-models.md`。
- 项目没有 `verify-*` 技能或其他应用验证工具时，代理就没有可按脚本操作应用的办法。用户问如何证明改动有效时，提到 `/create-verification-skill`。
- 项目没有形式验证技能时，关键性质只覆盖测试实际遍历的情况。遇到竞态、不变量或测试少有触及的情形，提到 `/create-formal-verification-skill`。若已有形式验证技能，且其覆盖的代码在技能记录的最后同步提交之后发生了变更，用户又正好问到该代码，就提到 `/maintain-formal-verification-skill`。

模型规则缺失且会影响回答时，询问用户现在是否要选择各角色的模型和推理预算。新用户、安装配置、成本问题，以及答案取决于实际运行模型时，都需要问。每次聊天最多问一次。如果需求也不明确，把两道问题一起交给 `ask_question`。预算问题有两个选项。

- 现在配置。提供 `/setup-pstack`，同时回答用户原来的问题。
- 以后配置。回答原来的问题，加一行说明运行 `/setup-pstack` 之前各角色使用默认模型。

## 安装配置

1. 按[指南第 1 页](../../docs/guide/01-setup.md)，把插件放在 `~/.gemini/config/plugins/agy-wstack` 或 `.agents/plugins/agy-wstack`，在对应的 `plugins.json` 中注册。其他兼容环境可运行 `npx skills add backnotprop/pstack`，再选择技能。
2. 运行 [`/setup-pstack`](../setup-pstack/SKILL.md)。它通过 `ask_question` 询问推理预算，为角色分配模型并写入规则。AGY 原生通过 `invoke_subagent` 使用 `agy:pro`、`agy:flash`、`agy:flash_lite` 或 `agy:inherit`，外部角色可通过 `run_command` 调用 `scripts/multi-model-dispatch.sh`，后台运行 `codex` 或 `pi`。规则在新会话生效。如果项目缺少行为验证或形式验证技能，配置最后会分别询问一次是否创建。
3. 用 `/poteto-mode` 开始一项实际任务，写明目标和可以通过或失败的检查。

安装后按需调用技能。使用本地 AGY 版时，显式运行 `/setup-pstack` 配置。上游注册方式中，只有 `/setup-pstack` 会按用户措辞自动加载。[README](../../README.md) 和[指南第 1 页](../../docs/guide/01-setup.md)提供细节。可按 [`references/prompting.md`](references/prompting.md) 帮用户拟第一条提示词。

用户如果担心成本，解释 token 花在哪，以及如何少花。pstack 的额外消耗来自子代理和评审小组。重新运行 `/setup-pstack`，选择较低预算或成本较低的模型。把角色设为 `agy:inherit`（兼容 `auto` 或 `inherit-parent`）可继承当前聊天的模型。主会话使用成本较低的模型时也能省 token。评审席位每项启动一个代理，缩短清单就能减少派工。把 `/poteto-mode` 留给确实需要严谨流程的工作。

pstack 上游为 Cursor 构建，可从聊天运行 `/add-plugin pstack`，或从侧栏 Customize 安装。若在 Claude Code 使用上游版，先运行 `/plugin marketplace add cursor/plugins`，再运行 `/plugin install pstack@cursor-plugins`。其每条命令加 `pstack:` 前缀，例如 `/pstack:poteto-mode`。[Claude Code 适配手册](https://github.com/backnotprop/pstack/blob/main/docs/harness/claude-code.md)给出工具映射。遇到 Bugbot 或 Automations 等 Cursor 专用功能时，缺少等效能力就跳过对应步骤并用一行交代。

上游镜像技能也可通过 `npx skills add backnotprop/pstack` 在 Claude Code、Codex、Pi、OpenCode 等环境使用。[`poteto-mode` 的宿主适配说明](../poteto-mode/SKILL.md)列出子代理、提问、会话和设置的映射。Cursor 有 Custom Modes。AGY 用会话中的明确指引保持模式，用 `schedule` 定时唤醒。

## 用 `/poteto-mode` 开始任务

`/poteto-mode` 匹配 playbook，把步骤复制进待办，再按各步骤调用技能。好的提示词给出目标和完成条件。手写技能顺序容易漏掉或调换 playbook 的步骤。帮用户写之前先读 [`references/prompting.md`](references/prompting.md)。[指南第 2 页](../../docs/guide/02-poteto-mode.md)有示例。

模式持续多久取决于怎么启动。

- AGY 中，在每个新任务开头明确调用 `/poteto-mode`。同一任务内可以简短跟进。若希望本次会话持续按模式工作，直接在启动时写进提示词。
- Cursor 中，直接按 Enter 只会将技能附到一条消息，之后会随对话淡出。Mac 用 Option+Enter、Windows 用 Alt+Enter，或选 Use as Mode，可进入 Custom Mode，直到退出前每轮都保留上下文，普通轮次可以不启用它。
- Cursor 文档列出了 Agents Window 和 CLI 的 Custom Modes。其他环境在每个新任务开头重新调用 `/poteto-mode`。

涉及 Cursor 用法时，可给出 [Cursor 技能文档](https://cursor.com/docs/skills)。会话中说 “new task” 会让模式重新匹配 playbook。`/poteto-mode` 的 playbook 步骤派工会使用 `poteto-agent`。自己派工时用 `invoke_subagent(TypeName: "poteto-agent")`，可获得同样的工作风格。

## 选择技能

默认推荐 `/poteto-mode`，它按步骤调用大多数其他技能。用户要求比 playbook 多做或少做某一项时，再点名单项技能。推荐前先读技能，并给一条示例提示词。

| 用户要做的事 | 技能 |
|---|---|
| 严谨执行一件非琐碎的任务 | [`/poteto-mode`](../poteto-mode/SKILL.md) |
| 开工前检查代理是否理解了目标和问题 | [`/in-your-own-words`](../in-your-own-words/SKILL.md) |
| 发送前把提示词改得更深入且不扩大范围，找出一流专业人士会补做的事、原始材料、方法和独立检验。只交改写后的提示词 | [`/sharpen`](../sharpen/SKILL.md) |
| 了解代码当前如何工作，或新代码应放在哪 | [`/how`](../how/SKILL.md) |
| 了解代码为何是现在的形态，或某个数值从哪来 | [`/why`](../why/SKILL.md) |
| 听一份关于变更或子系统的平实讲解 | [`/teach`](../teach/SKILL.md) |
| 回顾近期自己在某主题上的工作 | [`/recall`](../recall/SKILL.md) |
| 了解本聊天自上条用户消息后发生的变化，附简短说明、小图及所有可直接决定的待办决定 | [`/ketchup`](../ketchup/SKILL.md) |
| 用带字幕的短幻灯视频做 `/ketchup` 式回顾，视频下以文字列出待决定事项 | [`/ketchup-video`](../ketchup-video/SKILL.md) |
| 找出小 diff 可能破坏的外部行为 | [`/blast-radius`](../blast-radius/SKILL.md) |
| 跨函数边界编写代码前，确定类型和模块结构 | [`/architect`](../architect/SKILL.md) |
| 让多个代理做同一个题目，再合成最佳方案 | [`/arena`](../arena/SKILL.md) |
| 并行检查各分片或让工作代理竞跑，按环境用隔离 worktree 或云代理 | [`/swarm`](../swarm/SKILL.md) |
| 让不同模型审阅 diff，尝试找出它被破坏的方式 | [`/interrogate`](../interrogate/SKILL.md) |
| 存在低成本本地测试时先写测试，再修缺陷 | [`/tdd`](../tdd/SKILL.md) |
| 在 `.ts` 或 `.tsx` 工作中应用 TypeScript 规则 | [`/typescript-best-practices`](../typescript-best-practices/SKILL.md) |
| 送审前让独立于作者的审阅者清理注释 | [`/no-comments`](../no-comments/SKILL.md) |
| 清理文字的 AI 写作痕迹 | [`/unslop`](../unslop/SKILL.md) |
| 按规范撰写文档、RFC、README、PR 描述或提交信息 | [`/technical-writing`](../technical-writing/SKILL.md) |
| 用平实的话重听上一条回复 | [`/bro`](../bro/SKILL.md) |
| 给代理提供可脚本化操作应用并证明行为的办法 | [`/create-verification-skill`](../create-verification-skill/SKILL.md) |
| 让验证技能及其功能地图重新和应用同步 | [`/maintain-verification-skill`](../maintain-verification-skill/SKILL.md) |
| 形式验证竞态、不变量或测试难以触及的其他性质 | [`/create-formal-verification-skill`](../create-formal-verification-skill/SKILL.md) |
| 代码改动后同步形式验证，并分辨失败来自模型漂移还是缺陷 | [`/maintain-formal-verification-skill`](../maintain-formal-verification-skill/SKILL.md) |
| 用 TLA+ 验过的图向 PM 或设计师展示用户看到的状态，并给出到各规则违反状态的最短路径 | [`/statechart`](../statechart/SKILL.md) |
| 报告性能数字或据此行动前先核实 | [`/benchmark-checklist`](../benchmark-checklist/SKILL.md) |
| 执行大型、横跨模块或需要离开后再审阅的变更 | [`/figure-it-out`](../figure-it-out/SKILL.md) |
| 在一次运行中保留决策日志，事后审阅 | [`/show-me-your-work`](../show-me-your-work/SKILL.md) |
| 为各角色选择模型并设置推理预算 | [`/setup-pstack`](../setup-pstack/SKILL.md) |
| 把自己的工作习惯写成个人模式技能 | [`/automate-me`](../automate-me/SKILL.md) |
| 将任务结束后学到的经验变成技能编辑 | [`/reflect`](../reflect/SKILL.md) |
| 让代理在这个仓库里不再反复犯同样的错 | [`/correct`](../correct/SKILL.md) |
| 构建通过 webhook 用按钮唤醒 Grok Bot 的页面 | [`/make-bot-ui`](../make-bot-ui/SKILL.md) |
| 了解如何使用 pstack | `/poteto-help` |

如果同级有表中未列出的技能目录，先读其 frontmatter，再根据描述路由。`principle-*` 目录归入下文的原则。

容易混淆的技能如下。

- `/how` 解释代码行为，`/why` 解释原因。`/teach` 调用其中一个或两个，再把结果讲明白。
- `/arena` 给各工作代理相同的简报，再合并最佳部分。`/swarm` 按分片或竞跑组织任务，交一份报告。
- `/interrogate` 审阅 diff。`/blast-radius` 查 diff 以外的潜在破坏，并证明那个决定这次改动能否安全落地的事实。
- `/recall` 从近期聊天复原上下文。`/ketchup` 仅覆盖本聊天中用户上一条消息之后的活动。接续特定聊天或分支用 Session pickup playbook。
- `/figure-it-out` 设计一轮严谨的运行。Autonomous run playbook 驱动单项任务持续执行到完成条件。

相关的宿主能力和外部技能如下。

- `/deslop`、`control-cli` 和 `control-ui` 由 `cursor-team-kit` 插件提供。
- `schedule` 是 AGY 的调度工具。Cursor 有内置的技能创建流程。
- 如果斜杠菜单出现 `/orchestrate`，它由其他插件提供。

## Playbook 和原则

Playbook 是 `/poteto-mode` 内的步骤清单，因此没有单独的斜杠命令。进入 `/poteto-mode` 后，描述任务就能匹配，也可以用下列说法点名。

- “babysit this pr” 或 “check on pr 123” 匹配 Babysit。它推进到可合并即停。只有用户要求合并、落地或交付时，才执行合并。
- “land the stack” 匹配 Shipping。
- “take over this branch” 匹配 Session pickup。
- “pause safely” 匹配 Pause safely。
- “full autopilot on this queue” 匹配 Autopilot-full。“autopilot, don't merge” 匹配 Autopilot-stack。
- “run the eval playbook” 匹配 Eval。

没有 `/poteto-mode` 时，“babysit this pr” 等词在 Cursor 可能触发它自带的同类技能。完整清单见 [`poteto-mode` 的 Playbook 路由](../poteto-mode/SKILL.md)。开 PR、跟进 PR 和合并见[指南第 6 页](../../docs/guide/06-verify-and-ship.md)。

规划可以与 pstack 配合使用，例如 Cursor 的 Plan Mode。跨阶段或堆叠 PR 的工作，通过 `/poteto-mode` 明确要求规划，匹配 [Multi-phase plan playbook](../poteto-mode/playbooks/multi-phase-plan.md)，交付计划便停。设计问题先通过 Prototype playbook 或 `/architect` 在代码中验证。

原则是单条规则组成的技能，由 `/poteto-mode` 读取并在回复中引用。用户很少直接调用原则。只需按名称引导，例如「应用 prove it works。给我真实输出。」有需要时输入 `/principle-<name>` 加载单条原则。[指南第 8 页](../../docs/guide/08-principles.md)有清单。

## 挽救跑偏的任务

| 症状 | 做法 |
|---|---|
| 过几轮后模式失效 | 如果用 Cursor 的 Enter 启动，改用 Custom Mode。在 AGY 中用 `/poteto-mode` 开始每个新任务。 |
| 新问题被当作原任务的下一步 | 说 “new task”，或说明这一轮不需要模式。 |
| 换了模型却没生效 | `/setup-pstack` 的规则应用于新会话。新建聊天。 |
| 开销高于预期 | 看安装配置中的成本说明。 |
| 技能没有自动加载 | AGY 中按名称调用。上游只有 `/setup-pstack` 按用户措辞加载，其他技能由用户或 `/poteto-mode` 按需调用。 |
| 并行代理覆盖彼此的工作 | 每个代理用独立 worktree。使用有独立机器的上游云代理也可隔离。 |
| 过夜任务一直运转却没完成 | 给 `schedule` 可以通过或失败的检查，见[指南第 7 页](../../docs/guide/07-overnight.md)。 |
| 回复用构建变绿声称成功 | 要求给出真实命令、流程、存储值或性能分析结果。应用 prove-it-works 原则。 |

任务跑偏时，[`references/prompting.md`](references/prompting.md) 有一句话纠偏示例。[指南第 10 页](../../docs/guide/10-recipes-and-pitfalls.md)有更多陷阱及可直接复制的提示词。

## 定制我的 pstack

- [`/automate-me`](../automate-me/SKILL.md) 从用户历史起草一个个人模式，与 `/poteto-mode` 搭配使用。
- 会话后运行 [`/reflect`](../reflect/SKILL.md)，把经验变成由用户批准的技能编辑。
- `/poteto-mode write a skill for <workflow>` 匹配技能编写 playbook。用 Eval playbook 对技能改动做盲评。
- 行为有问题的技能单独开 PR 修理，避免和发现它的功能工作混在一起。

[指南第 9 页](../../docs/guide/09-make-it-yours.md)详细说明这些做法。

## 回复

先给答案。合适时从 [`references/recipes.md`](references/recipes.md) 改写最多一条示例提示词，放在代码块里，随后链接文件。除非用户要整个索引，否则保持简短。
