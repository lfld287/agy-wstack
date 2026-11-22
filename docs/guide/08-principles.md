# 用原则名称引导代理

pstack 有 24 条原则，每条都是一个技能。`/poteto-mode` 在每项多步骤任务开始时读原则索引，应用被任务触发的条目。回复中说明实际用过的原则和它改变的决定。

通常直接说原则名即可。每个名字指向代理已经读过的一条完整规则。一句短话就能准确纠正方向。

## 如何引导

代理打算在三个适配器上再叠一层时，可以说。

```text
用 subtract before you add。先删过时的适配器，再设计剩余部分。
```

代理因为构建通过就声称成功时，可以说。

```text
应用 prove it works。跑真实的导入流程，把写入的记录给我看。
```

两次并行尝试即将写入同一分支时，可以说。

```text
应用 separate before serializing shared state。每个尝试各用一个 worktree，别加锁。
```

这些短语有用，是因为规则表达了具体动作。代理仍要在回复中说明规则改变了哪一项决定。只引用名称，说明还没有给出实际应用的证据。

## 24 条原则速览

核心原则决定做多少，以及何时重想设计。

- [Laziness Protocol](../../skills/principle-laziness-protocol/SKILL.md) 优先删除，并选择能解决问题的最小改动。
- [Foundational Thinking](../../skills/principle-foundational-thinking/SKILL.md) 在写逻辑之前确定核心数据结构。
- [Redesign from First Principles](../../skills/principle-redesign-from-first-principles/SKILL.md) 把新要求当成从第一天就存在的条件，重新设计。
- [Attack the Premise](../../skills/principle-attack-the-premise/SKILL.md) 写下两次或更多失败修复共享的前提，下次修前先直接检验前提。
- [Subtract Before You Add](../../skills/principle-subtract-before-you-add/SKILL.md) 在扩建之前先清除无用部分。
- [Minimize Reader Load](../../skills/principle-minimize-reader-load/SKILL.md) 减少读者需要同时追踪的层级和隐含状态。
- [Outcome-Oriented Execution](../../skills/principle-outcome-oriented-execution/SKILL.md) 让重写向目标设计收敛，去掉只为过渡存在的兼容状态。
- [Experience First](../../skills/principle-experience-first/SKILL.md) 根据使用者得到的结果做决定。
- [Exhaust the Design Space](../../skills/principle-exhaust-the-design-space/SKILL.md) 缺少先例时做两三个可对照的原型。
- [Build the Lever](../../skills/principle-build-the-lever/SKILL.md) 编写执行或证明工作结果的脚本，评审者可以重跑。代理反复手工做同一件事时，让它写出希望已有的工具或技能。步骤能每次用脚本以相同方式完成，就用脚本，把需要判断的事交给代理。

架构原则决定状态、验证及兼容性放在哪里。

- [Model the Domain](../../skills/principle-model-the-domain/SKILL.md) 用一个结构表达反复出现的规则，减少散落的条件判断。
- [Boundary Discipline](../../skills/principle-boundary-discipline/SKILL.md) 在边界验证，在内部信赖类型。
- [Type System Discipline](../../skills/principle-type-system-discipline/SKILL.md) 让非法状态无法表示。
- [Make Operations Idempotent](../../skills/principle-make-operations-idempotent/SKILL.md) 让重试收敛到同一个最终状态。
- [Migrate Callers Then Delete Legacy APIs](../../skills/principle-migrate-callers-then-delete-legacy-apis/SKILL.md) 在同一轮迁移调用方并删除旧 API。
- [Separate Before Serializing Shared State](../../skills/principle-separate-before-serializing-shared-state/SKILL.md) 加协调之前，先消除能拆掉的共享状态。

验证原则定义什么证据算数。

- [Prove It Works](../../skills/principle-prove-it-works/SKILL.md) 验证真实产物。
- [Fix Root Causes](../../skills/principle-fix-root-causes/SKILL.md) 修改代码前，先复现并追到根因。
- [Sequence Work into Verifiable Units](../../skills/principle-sequence-verifiable-units/SKILL.md) 每个小单元先验收，再开始下一单元。
- [Test Behavior, Not Implementation](../../skills/principle-test-behavior-not-implementation/SKILL.md) 断言使用者能观察到的行为。行为出错时测试应失败，内部实现变化但行为一致时测试应通过。
- [Explain the Number](../../skills/principle-explain-the-number/SKILL.md) 在相信或报告数字前，说明它受什么限制，并排除测成其他事的可能。[`/benchmark-checklist`](../../skills/benchmark-checklist/SKILL.md) 将它化成七个需用实际运行回答的问题。

委派原则约束并行工作。

- [Guard the Context Window](../../skills/principle-guard-the-context-window/SKILL.md) 把大量阅读分派给子代理，主会话保留发现。
- [Never Block on the Human](../../skills/principle-never-block-on-the-human/SKILL.md) 可逆工作直接推进，再给出结果。

最后是一条用于落实其他原则的规则。

- [Encode Lessons in Structure](../../skills/principle-encode-lessons-in-structure/SKILL.md) 把反复提了两次的建议写成 lint、检查或脚本。[`/correct`](../../skills/correct/SKILL.md) 会把它应用到整个仓库，见[用 `/correct` 修好工作环境](./09-make-it-yours.md#fix-the-environment-with-correct)。

先扫一遍即可。发现代理正在做本可由某项原则避免的事，再回来查名字。用上几次就会记住。

下一页是[定制自己的工作方式](./09-make-it-yours.md)。
