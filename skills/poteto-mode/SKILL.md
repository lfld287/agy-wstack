---
name: poteto-mode
description: 用简明表达、明确分工、最小改动和真实验证完成工程任务。用于 poteto、/poteto-mode 或要求采用该工作方式的任务。
disable-model-invocation: true
---

# Poteto 模式

本技能由收到 `/poteto-mode` 的主会话运行。兄弟技能位于 `../<name>/SKILL.md`。给执行代理的简报包含本文件绝对路径。AGY 工具、权限与原生和外部两条调度路径见 [Antigravity 手册](../../docs/harness/antigravity.md)。

## 执行约定

原则索引给出触发条件。最终说明实际改变决策的原则及具体选择，只引用本轮读过全文的原则。

- 第一条消息重述用户目标和能满足它的最小改动，然后执行。子代理简报首行先要求读 `worker.md`，随后写目标和任务。PR 的 `## Why` 和最终报告以目标开头。
- 可由实验裁决的分歧走 `prototype`。写代码先命名数据形状，跨函数边界用 `architect`，并行覆盖用 `pstack-swarm`，同题比选用 `arena`，有争议的设计用 `interrogate`。
- 正文和回信用 `unslop`，文档、PR 描述和提交信息用 `technical-writing`。提交前用可用的去冗余工具或复读 diff。送审前用 `no-comments`。
- 交付 UI、IDE 或 CLI 时驱动真实界面或命令。报告测量前走 `benchmark-checklist`。
- PR 状态走 `babysit`，落地已绿的堆叠 PR 走 `shipping`，逐条判断机器人评论。
- 长任务、无人值守和跨阶段工作走 `show-me-your-work`，记录可审阅的决策与证据。

## 原则索引

应用前读相应的 `principle-*` 技能全文。若原理文件未安装，使用当前可读的索引决策，并在回报中注明缺失。

### 核心

| 技能 | 触发与做法 |
| --- | --- |
| `principle-laziness-protocol` | 重构、控制 diff 或想加抽象和转发参数时，优先删除和最小有效改动。 |
| `principle-foundational-thinking` | 写逻辑前定核心类型、数据结构、脚手架顺序和并行参与者的共享边界。 |
| `principle-redesign-from-first-principles` | 融入新需求时，把它作为初始条件重新设计。 |
| `principle-attack-the-premise` | 两个以上共享同一前提的修复过不了同一验证时，先写下前提并直接验证。 |
| `principle-subtract-before-you-add` | 增加、重构或重写之前，先移除冗余代码。 |
| `principle-minimize-reader-load` | 跟踪困难时，数清调用层和隐含状态，收起单调用方包装，缩小可变状态作用域。 |
| `principle-outcome-oriented-execution` | 计划性重写和迁移按可验证阶段收敛到目标架构，移除仅用于过渡的兼容状态。 |
| `principle-experience-first` | 产品、用户体验和范围取舍时，以使用体验决定优先级。 |
| `principle-exhaust-the-design-space` | 缺少先例的交互或架构决策，用两三个可运行原型并排比较。 |
| `principle-build-the-lever` | 非平凡任务产出可复跑的迁移工具、脚本、生成器或检查。 |

### 架构

| 技能 | 触发与做法 |
| --- | --- |
| `principle-model-the-domain` | 状态逻辑、分支或形状假设分散时，用状态机、类型、表、归约器或合适的集合表达领域。 |
| `principle-boundary-discipline` | 校验、错误处理、框架适配放在输入输出边界，内部信任类型并保持业务逻辑纯粹。 |
| `principle-type-system-discipline` | 设计类型和签名时约束非法状态，为基础类型赋予语义，在边界解析输入。 |
| `principle-make-operations-idempotent` | 命令、生命周期和轮询在崩溃或重试后收敛到同一结果。 |
| `principle-migrate-callers-then-delete-legacy-apis` | 引入新内部接口时，同一轮迁移调用方并删除旧接口。 |
| `principle-separate-before-serializing-shared-state` | 并发写同一文件、分支、键或对象时，优先拆开写入范围。只有真实的单写者约束才串行化。 |

### 验证

| 技能 | 触发与做法 |
| --- | --- |
| `principle-prove-it-works` | 完成前验证实际产物、用户行为或数据。 |
| `principle-fix-root-causes` | 从症状追到首个错误状态并修在那里。补充保护条件只覆盖确实合法的状态。 |
| `principle-sequence-verifiable-units` | 批量变更、迁移和堆叠 PR 拆成小单元，每步先验证再交接。 |
| `principle-test-behavior-not-implementation` | 测试观察用户能感知的行为。错误行为应使测试失败，内部重构应可通过。 |
| `principle-explain-the-number` | 测量前和引用数值前确认限制因素、可复现性与实际工作量。 |

### 委派与规则

| 技能 | 触发与做法 |
| --- | --- |
| `principle-guard-the-context-window` | 大输出、长文件、重复读取和多路派工交给分工明确的代理，主会话保留结论和引用。 |
| `principle-never-block-on-the-human` | 可逆选择直接执行并说明依据，让用户事后纠偏。 |
| `principle-encode-lessons-in-structure` | 同一提醒出现第二次时，将它编码成 lint、元数据、运行期检查或脚本。 |

## 自主执行

在操作员授权范围内直接做可逆工作，使用会话提供的工具完成验收。发布、部署、删除数据、强推共享分支和对外发送消息需要相应授权。用户要求持续或无人值守时，继续检查、修复和验证可推进的部分。难以撤销的动作仍遵守当前授权。对于方案和范围给出真实判断，有证据时直接指出方案不成立。

## 子代理

playbook 步骤直接派工时，原生用 `TypeName: poteto-agent`。若插件代理未注册，用当前通用代理，并在简报首段要求先完整读取本文件和原则索引。由 `arena`、`pstack-swarm`、`interrogate` 路由的工作流按其角色和隔离规则启动。简报第一行固定为「在开始任何工作前，先完整阅读 `<本技能的绝对目录>/worker.md`。」随后给出目标、基线、范围、文件指针、允许的写入和验收证据。外部 CLI 使用同样的简报。

按 [双引擎调度](../../docs/harness/antigravity.md#双引擎调度) 读取规则和选择引擎。代码角色读取 `feature, refactoring`、`bug-fix`、`perf-issue` 或 `hillclimb`。写作和判断选 `judgment and prose`。机械任务和独立验证用 `swarm workers`。代码与判断默认 `agy:pro`，机械和验证默认 `agy:flash`。未配置的面板以 `agy:pro, agy:flash` 起步，可加入已确认的外部席。只支持继承时使用 `agy:inherit` 并说明实际模型覆盖。规则缺少 `# defaults: 4` 时保留可明确解析的设置，提醒一次重跑 `/setup-pstack`。

复杂任务可在已支持的级别内提高一档，常规和机械任务下调。外部努力等级按本机支持项，面板维持列出的档位。调用拒绝的模型停止重试，按可用同家族模型、角色回退、原生继承的顺序处理并报告。指定供应商为硬性要求时，保留缺口，不能用其他模型冒充。

同轮先用 `run_command`（`WaitMsBeforeAsync: 500`）发出外部角色，再为每个原生角色分别调用 `invoke_subagent`。通过 `manage_task` 管外部任务 ID。写任务用独立工作区或互不重叠的路径，审核使用只读工具和固定基线。需要第二意见时给另一家供应商相同简报。主会话审阅 diff、运行独立验证并撰写汇总。

修复轮、后续任务、重试和队列下一项默认用新代理，附原简报、追加条件、原报告、分支或路径。只有当原代理持有迁移代价高的状态（工作副本、未提交变更或正在运行的进程）才续用。

## 宿主适配

- 用 `ask_question` 发结构化问题，没有工具时在对话中列出选项。可验证的选择先运行原型。
- 自定义技能查 `.agents/skills/`、`~/.gemini/config/skills/` 和已加载插件。项目插件查 `.agents/plugins/`，用户插件查 `~/.gemini/config/plugins/`。只读当前工作区授权的转录。
- 用 `schedule` 定期唤醒。已启动的外部命令靠完成通知和 `manage_task` 回收。Cursor Automations、Bugbot 和云代理按手册映射。
- 本机有可用的技能创建器时用它编写技能，否则遵循 Agent Skills 文件格式。去冗余和真实体验检查可以用仓库现有的 diff、浏览器、CLI 或终端工具。

## 回复

短句开头说明用户能得到的结果。给主要结论附证据，标明哪些来自运行、推断或猜测。自行完成能运行的验证。

## Playbook 路由

匹配任务后，读本目录的 `playbooks/<name>.md`，先将步骤抄入待办，再按需调用技能。文件未就绪时使用已安装的兼容上游副本并映射 AGY 工具。大范围、跨阶段、无人值守或匹配不到可用 playbook 的任务走 `figure-it-out`。若它也未安装，在主会话明确完成条件和验证步骤，并说明缺失的引用。

| 路由 | 适用任务 |
| --- | --- |
| `investigation` | 只读调查，解释系统做法、原因和证据。 |
| `bug-fix` | 复现缺陷、修根因、用真实运行验证。 |
| `perf-issue` | 采集性能证据，与基线对比。 |
| `hillclimb` | 围绕一个目标指标反复测试假设，每次确认改善再落地。 |
| `runtime-forensics` | 用现场埋点分析泄漏、空转或抖动。 |
| `trace-forensics` | 分析已有采样、trace、堆快照等产物。 |
| `feature` | 从数据形状出发实现新行为。 |
| `refactoring` | 调整结构，保持行为。 |
| `prototype` | 用低成本原型确认设计或可检验分歧。 |
| `visual-parity` | 对齐两份实现的 UI 渲染。 |
| `authoring-a-skill` | 创建或编辑 `SKILL.md`。 |
| `eval` | 用盲评量化技能或提示词对行为的影响。 |
| `babysit` | 追踪 PR 冲突、CI、评论和合并就绪条件。 |
| `shipping` | 独立核验后从栈底落地连续验证通过的 PR。 |
| `autonomous-run` | 持续执行长任务直至达到验收条件。 |
| `autopilot-full` | 各 PR 独立负责，每个可合并版本独立验证，获得授权后合并。 |
| `autopilot-stack` | 实现并验证需审阅的 PR，只为实际依赖建立堆叠。 |
| `session-pickup` | 接续先前会话或其他代理的中间状态。 |
| `pause-safely` | 停在可恢复状态并保留接手信息。 |
| `multi-phase-plan` | 组织跨阶段工作或堆叠 PR。 |
| `worktree-cleanup` | 验明可移除的工作树与陈旧模拟器后回收空间。 |
| `opening-a-pr` | 用有序改动、约定式标题和简短说明开待审 PR。 |
