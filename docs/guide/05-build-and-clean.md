# 实现变更并清理 diff

实现类 playbook 有一条共同的做法。你说清观察到什么，由 playbook 要求证据。这里说明各类实现任务的提示词怎么写，以及如何清理 diff，让评审者看得懂。

## 按任务说出你已知的事实

缺陷提示词说明症状，并要求先复现。

```text
/poteto-mode 这条命令在重试后输出两条记录。先复现，再修复并验证。
```

功能提示词说明新行为和需要保留的行为。

```text
/poteto-mode 添加 --json 参数。文本输出保持逐字节一致。验证两种输出。
```

重构提示词在调整结构前锁定行为。

```text
/poteto-mode 把解析代码集中到一个模块，行为零变化。先记录当前输出，再证明改完后一致。
```

性能提示词给出测量结果。

```text
/poteto-mode 在这个 fixture 上启动耗时 1.8 秒。追踪并修复实测成因，给我看前后对比。
```

以上提示词分别路由到对应 playbook（[Bug fix](../../skills/poteto-mode/playbooks/bug-fix.md)、[Feature](../../skills/poteto-mode/playbooks/feature.md)、[Refactoring](../../skills/poteto-mode/playbooks/refactoring.md)、[Perf issue](../../skills/poteto-mode/playbooks/perf-issue.md)）。playbook 会补上没写的步骤，包括先复现再修，先定义数据结构再实现，先锁定行为再改结构，先做性能分析再优化。

要持续改进一个数值，使用 [Hillclimb playbook](../../skills/poteto-mode/playbooks/hillclimb.md)。给出指标、目标和最少尝试次数，它会冻结测量流程，每轮只验证一个假设。保留有效的改动，撤回其余尝试。

两种性能 playbook 都会对数据运行 [`/benchmark-checklist`](../../skills/benchmark-checklist/SKILL.md)。Perf issue 核实基线及后续每个数据点。Hillclimb 在冻结测量流程前核实它。[用 `/benchmark-checklist` 核实测量结果](./06-verify-and-ship.md#vet-a-measured-number-with-benchmark-checklist) 说明何时手动调用。

有时要先查原因。内存泄漏、空闲时 CPU 忙转、界面异常等实时症状，交给 [Runtime forensics playbook](../../skills/poteto-mode/playbooks/runtime-forensics.md) 给运行进程加观测。已有性能采样文件时，[Trace forensics playbook](../../skills/poteto-mode/playbooks/trace-forensics.md) 读取产物，将热点栈帧映射到源码。两者都先交诊断结果。

```text
/poteto-mode 这是启动缓慢时抓到的 cpuprofile。告诉我时间花在哪里，对应哪些源码行。先别修。
```

## 用 `/tdd` 先写失败的测试

缺陷有低成本的本地测试入口时，提示词可以很短。

```text
/tdd implement
```

在上下文里，这就足够了。[`/tdd`](../../skills/tdd/SKILL.md) 先写因预期原因失败的最小测试，再修复并重跑。测试若要大范围搭环境或用脆弱的 mock，技能会说明，并改用最接近的可执行检查。真实命令能提供更有力的证据时，无须强加一个测试。

## 点名加载 TypeScript 规则

[`typescript-best-practices`](../../skills/typescript-best-practices/SKILL.md) 将类型系统原则落实为具体规则，包括可辨识联合、边界用 `unknown`、变体穷尽检查、从 schema 派生类型。它需要显式加载。任务涉及 `.ts` 或 `.tsx` 时，输入 `/typescript-best-practices`。

## 提交前清理

[Opening a PR playbook](../../skills/poteto-mode/playbooks/opening-a-pr.md) 要在每次提交前清理 diff，poteto-mode 会用 [`/unslop`](../../skills/unslop/SKILL.md) 处理 PR 描述和提交正文。`/deslop` 随上游的 `cursor-team-kit` 插件提供。AGY 没有这个工具时，可以直接描述同样的验收要求，让代理移除叙述代码的注释、缺少依据的防护逻辑、无用的兼容路径和无关改动。

处理文字时，把目标和额外规则交给 `/unslop`。

```text
/unslop 清理 README 的变更，不用破折号。
```

用熟悉后可以更简短。「unslop 那段，收紧一点」也足以说明意图。

## 用 `/no-comments` 清理注释

作者容易为自己的注释辩护。送审前把注释交给另一位审阅者。

```text
/no-comments 检查 diff。
```

[`/no-comments`](../../skills/no-comments/SKILL.md) 通过 `invoke_subagent(TypeName: "comment-sicko")` 调用 [Comment Sicko](../../agents/comment-sicko.md)。它只读审查，报告建议删除的注释和要重构的符号，由主会话接受并执行。保留清单很短，包括许可证头、定义公开 API 的文档注释、解释代码无法表达的约束的链接，以及无法改变的外部依赖所强制的行为。其余按技能规则清理。自有代码中出人意料的行为会带重构标记，由 `/no-comments` 从根因修复所采纳的标记。对「不要删除」之类的约束声明，技能会提出用类型、测试或 lint 落实。对可控制的约束，即便不采纳落实方案也会删除原注释，并报告遗留事项。

`/deslop` 清理代码里的赘余，`/unslop` 清理文字，`/no-comments` 让独立的审阅者清理注释。

**常见陷阱。** 清理是交付的一部分。复述代码的注释和没有依据的防护逻辑让 diff 显得还没做完，下一处缺陷也容易藏在多余代码里。diff 显得臃肿时，在提交前要求清理。

下一页是[验证与交付](./06-verify-and-ship.md)。
