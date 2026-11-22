# agy-wstack 使用指南

给代理说明你要什么，以及怎么知道它做完了。由 `/poteto-mode` 选择 playbook，按步骤调用技能，并给你看证据。本指南用实际提示词说明这套做法。agy-wstack 是 pstack 的 Antigravity（AGY）适配版。

1. [安装和配置](./01-setup.md)。安装插件，选择模型。
2. [用 `/poteto-mode` 分派任务](./02-poteto-mode.md)。给出目标，看它如何选择 playbook。
3. [理解代码](./03-understand.md)。动手前先做只读调查，并使用 `/how`、`/why`、`/teach` 和 `/recall`。
4. [设计变更](./04-design.md)。代码定型前使用 `/architect`、`/arena`、`/pstack-swarm`、`/interrogate`，先验证原型，再定计划。
5. [实现变更并清理 diff](./05-build-and-clean.md)。了解实现类 playbook、`/tdd`、`/unslop` 和 `/no-comments`。
6. [验证与交付](./06-verify-and-ship.md)。在真实应用上验证行为，对测试难以触及的性质做形式验证，用 `/benchmark-checklist` 核实数据，再开一个聚焦的 PR 并推进合并。
7. [离开后继续运行](./07-overnight.md)。先验证自动化是否可靠，明确无人值守约定，保留可审计的决策日志，再扩展到多代理协调和自动化。
8. [用原则名称引导代理](./08-principles.md)。了解 24 条能在任务中途纠偏的原则。
9. [定制自己的工作方式](./09-make-it-yours.md)。创建个人模式，用 `/correct` 解决反复出现的错误，盲测技能变更。
10. [提示词示例与常见陷阱](./10-recipes-and-pitfalls.md)。复制可用的提示词，避开常见问题。

第一次按顺序读，之后可以单独查任一页。

卡住或不知道该用哪个技能时，输入 [`/poteto-help`](../../skills/poteto-help/SKILL.md)，附上问题。

```text
/poteto-help 我该用哪个技能审阅这个分支？
```

它会回答问题，给你一条可发送的提示词，并链接答案所在的技能或指南。运行 pstack 会消耗 token，所以由你准备好后再发送提示词。`/poteto-help` 仅在显式调用时运行。

## 首先记住怎么提任务

用自己的话给代理一个目标和一个可执行的检查。

```text
/poteto-mode 导出任务执行到一半遇到重试时会写入重复行。先复现，再修复并验证。
```

「先复现」和可检查的结果足以让 `/poteto-mode` 判断路径。它会匹配 Bug fix playbook，把步骤复制到待办，并在每一步调用相应技能。提示词里可以省去 playbook 名和技能清单。

下一页是[安装和配置](./01-setup.md)。
