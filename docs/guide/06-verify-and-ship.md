# 验证结果并开 PR

「编译通过」只能证明代码能编译。[Prove It Works 原则](../../skills/principle-prove-it-works/SKILL.md) 要求代理在报告成功前检查真实产物。你要让这个产物有明确的检查方法。这里涵盖完成条件、核实测量、为应用建立验证技能、形式验证测试难以触及的性质，以及开 PR 后如何推进合并。

验证通常是代理工作中最慢的一步，因为常常要等人。让代理自己验证，就能从你这里移除等待。跳过验证，增加代理只会产生更多未经检查的工作。

![原型飞机飞过实际测试路线，她用秒表计时，机器人拍摄并核对清单。终端显示 verify: pass 和 evidence: captured。](./images/verification.jpg)

## 一开始就给完成条件

在第一条提示词里写清什么算完成，用你习惯的表达。

```text
/poteto-mode 给这条命令添加 JSON 输出。文本输出保持逐字节一致，JSON 应能解析，两种输出都用示例项目实际跑一遍。给我看证据。
```

现在代理有三个可执行检查。回复应带上准确的命令和输出。有检查跑不了时，实话写 `inconclusive`。语气肯定却没有证据的回复值得追问。

验证方式随改动而定。

- CLI 变更运行真实命令。
- UI 变更在运行中的应用走一遍改过的流程。要求逐像素匹配参考时，[Visual parity playbook](../../skills/poteto-mode/playbooks/visual-parity.md) 将截图与冻结的基线做像素比较。
- 解析器或迁移变更重放保存过的输入。
- 性能变更比较优化前后的性能分析结果。
- 存储变更回读写入的值。

要求提供能亲自检查的产物，例如先失败后通过的测试、前后对比录像、trace 或截图。修复已经合并时，在 main 再跑同一个检查。产物便于核查，无须为质疑某个结论重放整轮工作。

对不完全放心的小 diff，用 [`/blast-radius`](../../skills/blast-radius/SKILL.md) 查它可能破坏别处的什么行为。它找出决定改动安全与否的一个事实，再靠运行代码证明那个事实。

<a id="vet-a-measured-number-with-benchmark-checklist"></a>

## 用 `/benchmark-checklist` 核实测量结果

性能前后对比很容易无意中测错。热缓存、一方用调试构建，或者本应计时的操作根本没在计时区间发生，都可能产生看似可信的加速。报告或使用数字前，先输入下列提示词。

```text
/benchmark-checklist 导出加速的数据要写进 PR，先核实这组数字。
```

[`/benchmark-checklist`](../../skills/benchmark-checklist/SKILL.md) 提出七个问题，每项都要提供实际运行的证据。

1. 什么限制了这个数字？为什么它不能翻倍？
2. 各方是否都按生产环境的方式调优和运行？
3. 结果是否超过磁盘带宽、核心数之类的物理上限？
4. 有没有出错或返回错误结果？
5. 交替多次运行能复现吗？中位数和范围是多少？
6. 在用户实际等待的端到端路径上，这个差异有意义吗？
7. 被测工作确实发生在计时区间内吗？

结论为更快、更慢、无可测差异或无法判定，并附运行次数、范围和限制因素。无法指出限制因素，或某方未按预期调优时，结论为无法判定。`/poteto-mode` 已在 Perf issue 和 Hillclimb playbook 中运行此清单。在这些流程之外测量，或他人的数字好得可疑时再直接调用。它落实了 [Explain the Number 原则](../../skills/principle-explain-the-number/SKILL.md)。

<a id="create-a-project-verification-skill"></a>

## 创建项目验证技能

验证界面需要可脚本化操作应用的办法。已有这种入口时直接用，否则运行下列技能。

```text
/create-verification-skill
```

[`/create-verification-skill`](../../skills/create-verification-skill/SKILL.md) 先调查仓库。它找出用户会操作什么、应用如何在本地启动、使用什么工具可驱动应用、哪些证据能证明行为，以及两份实例能否并行运行。优先复用现有验证入口，其次才考虑浏览器和 CDP、PTY 或普通 HTTP。只有代码无法回答的问题才通过 `ask_question` 问你。

它在 AGY 项目中写入 `.agents/skills/verify-<app>/`。技能面向代理，提供明确的 Launch、Doctor、Drive、Evidence 和 Cleanup 小节。有辅助脚本时再写 Helpers。它还在 `features/` 下建立功能地图，索引应用能做什么、什么结果能证明每项功能有效。技能附有一份[完整的功能地图示例](../../skills/create-verification-skill/references/feature-map-example/)，其中有 README 索引，每个功能一份文件，包含四个规定的二级标题。交付前生成器会端到端验证一次。启动应用、运行健康检查、操作一个功能、收集证据、清理并确认清理后证据仍在。若这次验证失败，先别用生成的技能。

之后，「在应用里验证」就成了本仓库任何代理都能执行的步骤，无须再解释怎么布置环境。需要特定形式的证据时，在提示词里点名。

```text
/poteto-mode 实现批量归档。用 /verify-<app> 验证改动，给我视频和截图作证。
```

```text
/poteto-mode 用 /verify-<app> 复现这个问题。如果在 main 上能复现，就修复并录一段视频作证。
```

验证技能跑通后，[`/pstack-swarm`](../../skills/pstack-swarm/SKILL.md) 可以把全面验证按功能地图条目分给多个代理，再汇总结果。也可让多个验证代理用足够大的样本确认性能提升，或在 PR 交付前用模糊测试搜寻回归。

把验证技能当作基础设施维护。将它提交到仓库，团队成员和代理就能用同样的方式操作应用。接着实践 [Build the Lever](../../skills/principle-build-the-lever/SKILL.md)。代理如果反复写一次性脚本在应用里点来点去，就让它做一个供技能调用的小型控制 CLI。这样能节约 token，每次运行也都可重复。适合代理使用的 CLI 有以下特点。

- 命令少、可组合，每个都完成一项实质工作，避免大量薄包装。
- 有破坏性的操作提供 `--dry-run`。
- 通过子命令逐层提供功能。
- 错误消息写明接下来怎么做。
- `--help` 内容充足。
- 能输出 JSON 等机器可读格式。

开发环境也做成可重复的。准备预置数据和测试用户，用一条命令以同样方式启动环境。

## 保持验证技能准确

应用会变，功能地图也会过时。至少每天运行一次以下技能，最好用 AGY 的 `schedule` 定期触发，省去手工记忆。

```text
/maintain-verification-skill
```

[`/maintain-verification-skill`](../../skills/maintain-verification-skill/SKILL.md) 审核生成的技能。每个功能先安排一个只读代理并行读源码，然后在运行中的应用走一遍功能地图的全部条目。最终只能是三种结果之一。`clean` 表示覆盖完整，无须交付改动。`changed` 表示一份经验证的修订 PR，改动只在验证技能自身目录。`blocked` 写明阻塞。产品代码由原工作流程处理。在运行中发现产品回归时，只报告回归，避免用改文档掩盖。

<a id="prove-a-property-with-a-formal-verification-skill"></a>

## 用形式验证技能证明一个性质

验证技能可以证明自己操作过的路径。有些缺陷藏在很少走到的路径里，例如两次重试交叠、写入中途锁过期、状态变更乱序到达。测试很少触及这些情况。缺陷代价高的代码可以用以下技能。

```text
/create-formal-verification-skill
```

[`/create-formal-verification-skill`](../../skills/create-formal-verification-skill/SKILL.md) 从代码里选出一项承诺。该承诺被破坏时会伤害用户，而且测试很少触及失败场景。挑影响最大的目标。也可以点名一个区域或缺陷，从那里开始。

```text
/create-formal-verification-skill 检查任务租约和重试逻辑。同一个任务绝不能同时运行两次。
```

问题决定工具。要查事件会不会出现非法顺序，适合用模型检查器检查小型设计模型。无论实现语言是什么，这类任务默认用 TLA+。要查代码对所有输入的行为，适合直接对代码运行验证器。如果没有适用该语言的验证器，代理应说明情况，然后用生成的输入测试真实代码，避免用手写函数模型替代。必须对任意规模成立的性质可能需要证明。代理会报告所选工具和理由。

每次验证一个性质，并展示该性质如何在故意破坏的代码变体上失败。验证检查至少要证明自己能捕获一次预期的失败。如果现有代码已违反这个性质，你会收到一小串用代码实际概念描述的反例步骤。保留原性质，才能保留这个发现。只有你要求时才改产品代码。

生成器写入一个项目本地技能，告诉下一个代理如何判断变更是否碰到已验证代码、如何用一条命令运行检查，以及如何区分建模错误与真实缺陷。交付前，它会在临时副本故意破坏此性质，再按技能运行一次，检查必须捕获错误。交付时注明验证对象、采用的工具和边界、检查发现，以及覆盖不到的情况。通过只证明模型或所声明边界里的结论。

技能还记录每项检查覆盖的代码，以及上次两者相符的提交。合并或重构后如果没运行技能，检查可能仍对已消失的代码描述给出通过结果。这时运行 [`/maintain-formal-verification-skill`](../../skills/maintain-formal-verification-skill/SKILL.md)。它按代码更新验证并重跑，证明更新后的每项检查仍能捕获失败，并说明失败来自验证偏离现状还是代码缺陷。

## 用状态图展示行为

用模型术语给出反例可以说服你，但负责产品行为的 PM 或设计师需要用熟悉的词来看。运行下列提示词。

```text
/statechart 展示用户离线编辑笔记时会看到什么。
```

[`/statechart`](../../skills/statechart/SKILL.md) 从 TLA+ 模型生成面向用户所见的 Mermaid 状态图，两者始终来自同一份模型。读图人的规则，例如「离线时绝不会显示 Synced」，成为不变量。图上标记每个违反规则的状态，报告用读图人的话给出到达它的最短路径。交付前代理在真实代码重放各条缺陷路径，以免把建模错误当成缺陷报出去。

## 开 PR

```text
/poteto-mode open the pr. small ordered commits, evidence in the description.
```

[Opening a PR playbook](../../skills/poteto-mode/playbooks/opening-a-pr.md) 在 worktree 工作，将改动 rebase 成小而可独立落地的提交，清理 diff，准备一分钟能读完的描述，再以可审阅状态开 PR。后续工作叠成新的 PR，比让原分支一直变大好。开 PR 和推送须有相应授权。

## 用 Babysit 把 PR 推进到可合并

PR 打开后，检查可能失败，评审会留评论，主干也在推进。把这些变动交给 [Babysit playbook](../../skills/poteto-mode/playbooks/babysit.md)。

```text
/poteto-mode babysit this pr. get it green.
```

Babysit 在 GitHub 上使用随附的监视脚本，有 Origin CLI 时也可通过它监视 PR。AGY 用 `run_command` 启动适用的监视任务，或用 `schedule` 在下一次检查时唤醒。处理顺序是冲突、评审线程、CI。它禁止自行 rebase 或强制推送。遇到冲突或基线过旧会告诉你需要 rebase 的分支。对评论逐条判断，因为人和机器人都会报真问题，也都会制造噪声。有依据就修，缺乏依据就在获准发帖时把反证贴到对应线程。只要状态时，缩小请求，Babysit 可以直接回答。

```text
/poteto-mode check on pr 123. anything outstanding?
```

Babysit 到可合并就停。全绿后是否合并，仍由你决定。

## 用 Shipping 合并一组堆叠 PR

就绪后明确发出合并指令。

```text
/poteto-mode land the stack.
```

[Shipping playbook](../../skills/poteto-mode/playbooks/shipping.md) 在启动合并前独立验证每个 PR。每个 PR 由一名没参与编写的新代理在实际运行中证明行为。然后只从栈底逐个合并连续验证通过的 PR，默认用 GitHub，有可用 Origin CLI 时可用 Origin。报告第一个中断这段连续验证的 PR。某个已验证的 PR 下方还有一个未验证的 PR 时，它必须等，合并上层会把缺口一并拉进来。

下一页是[离开后继续运行](./07-overnight.md)。
