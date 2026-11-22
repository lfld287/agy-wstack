# 定制自己的工作方式

poteto-mode 沿用一位作者的工作风格。它的 playbook、任务路由和模型角色也可以按你的习惯使用。本页介绍如何生成个人模式、记录会话经验、修好反复诱发代理错误的仓库结构、编写聚焦的技能，以及在长期使用前测试技能改动。

从小处开始。第一天既不需要很多技能，也未必需要整个插件。用平实的提示词，观察代理在哪里失败。同一问题出现两次时再加技能或检查。

## 用 `/automate-me` 生成个人模式

```text
/automate-me
```

[`/automate-me`](../../skills/automate-me/SKILL.md) 从历史记录里找你的工作风格。在 AGY 中读取当前工作区近期会话的 `~/.gemini/antigravity-cli/brain/<conversation-id>/.system_generated/logs/transcript.jsonl`。它调查你对回复、委派、验证、代码、文字和流程的反复偏好，再用 `ask_question` 请你确认哪些确实代表你的习惯。它通过本机可用的技能创建工具，或按 Agent Skills 格式，在 `.agents/skills/<你的名字>-mode/SKILL.md` 起草个人模式，用 [`/unslop`](../../skills/unslop/SKILL.md) 校订。获准送审时从 worktree 开 PR，像其他改动一样审阅。上游 Cursor 用内置的 `create-skill` 流程。

习惯变化时再运行一遍。

```text
/automate-me 用上次编辑之后的记录来更新我的模式技能。
```

更新时只调查技能上次修改后的历史。未被新行为推翻的规则保留，有新证据的就改，只有确实出现新模式才增加小节。

用户插件通常位于 `~/.gemini/config/plugins/agy-wstack`，项目插件位于 `.agents/plugins/agy-wstack`，由相应配置根目录的 `plugins.json` 注册。个人技能保存在 `.agents/skills/` 或 `~/.gemini/config/skills/`。调整角色模型时用 `/setup-pstack` 更新 `~/.gemini/config/rules/pstack-models.md`，或在 `.agents/rules/pstack-models.md` 按项目覆盖。这样各项目可沿用同一套插件和不同偏好。注册与配置见[安装和配置](./01-setup.md)。

## 用 `/reflect` 提炼会话经验

一项任务刚让你学到东西时，运行下面的提示词。

```text
/reflect 这次花了太久。记录学到的东西，避免下次再碰到同样的问题。
```

[`/reflect`](../../skills/reflect/SKILL.md) 读取会话记录，只保留会改变未来代理做法的经验，分成 `Accepted`、`Rejected` 和 `Backlog`。任何技能变更都等你批准。只批准能改变未来决策的提案。一次反常会话只是一条个案。

<a id="fix-the-environment-with-correct"></a>

## 用 `/correct` 修好工作环境

同一个错误反复需要你纠正时，把修复写进仓库。按约束的可靠程度排序。

1. 用架构或更好的数据结构使错误无法发生。
2. 用类型、lint 或 CI 检查拦住错误，并在错误消息中写明如何修正。
3. 用测试捕获错误。
4. 写成文档或代理规则。代理忽略规则时不会有检查失败，因此排在最后。

让评审者在每个 PR 都抓住同一个错误，正是这里要解决的问题。用 [`/correct`](../../skills/correct/SKILL.md) 处理。

```text
/correct 代理总是直接调用数据库客户端，绕过仓储层。
```

它读近期提交、撤回、评审评论和解释变通做法的代码注释，再把错误分类。相同类型发生两次才计入。先修最常见的类别，每类一个提交，优先选有效的最高层约束，并用真实旧错误证明每项新检查确实会失败。它还在代理指令文件中维护一张表，列出每条规则及强制执行它的机制。没有机制支持的规则会显示为可重复发生的问题。回复逐类列出证据、所选层级，以及更高层级不可行的原因。

无参数运行时，它会自行从历史中找类别。`/reflect` 从一段会话改进技能。`/correct` 修改仓库，让一类错误无法再次发生。需要建立新边界时，将 `/correct` 与 `/architect` 搭配。[并行协调多个项目](./07-overnight.md#run-many-projects-in-parallel) 有一条在整个仓库里组合这两个技能的提示词。

## 编写聚焦的技能

已清楚要记录什么流程时，可以这样说。

```text
/poteto-mode 为这个仓库的数据库迁移验证流程写一个技能。
```

这会匹配 [Authoring or modifying a skill playbook](../../skills/poteto-mode/playbooks/authoring-a-skill.md)。在 AGY 中用当前会话的技能创建工具，或按 Agent Skills 格式编写。上游 Cursor 调用内置 `create-skill` 流程。用 `read_file` 读现有约定，按需用 `write_file` 或 `edit_file` 写目标技能，再通过 `run_command` 核对 frontmatter 和链接。获准送审时由 Opening a PR playbook 交付。面向代理的文字要求更高，因为一句无用的话可能成为未来代理会照做的指令。由 playbook 负责守住这个标准。

两类技能有专用生成器。要驱动应用并证明行为，使用 [`/create-verification-skill`](../../skills/create-verification-skill/SKILL.md) 及 [`/maintain-verification-skill`](../../skills/maintain-verification-skill/SKILL.md)。要通过模型检查器、证明或其他验证工具检查代码性质，使用 [`/create-formal-verification-skill`](../../skills/create-formal-verification-skill/SKILL.md) 及 [`/maintain-formal-verification-skill`](../../skills/maintain-formal-verification-skill/SKILL.md)。[验证与交付](./06-verify-and-ship.md#prove-a-property-with-a-formal-verification-skill)涵盖两种验证方式。

## 用 `/technical-writing` 规范技术文档

技能之外，文档、RFC、README、PR 描述和提交信息也都需要清楚的写作。

```text
/technical-writing 审阅 README 的改动。
```

[`/technical-writing`](../../skills/technical-writing/SKILL.md) 适用分层规范，目标是让疲惫的工程师读一遍就懂。先选择文档类型（教程、操作指南、参考资料或解释），再逐句处理。写清谁做什么，每句只表达一个意思，消除歧义。可以用它审阅你或代理写的内容，也可以在委托写作时提前点名。

## 盲测技能变更

一次技能编辑会影响以后每次会话，所以按实验方式验证。引入别人写的技能也是一样。在保留前先查证它能让代理更好地处理你的工作。

```text
/poteto-mode 对这次技能改动运行 eval playbook。两个变体做同一个任务，候选代理保持盲测。
```

技能反复漏掉某件事，且你知道正确做法时，可以在同一项任务中改动并测试。

```text
/poteto-mode 更新审阅技能，让它标记漏掉的迁移，并评估这项改动。
```

一开始要求评估可以约束改法。从一次糟糕会话拟出的修复容易只适合那一次。此类编辑多了，技能会逐步偏离应有行为。评估可在交付前发现偏移。

[Eval playbook](../../skills/poteto-mode/playbooks/eval.md) 特别处理观察者效应。知道自己在受测的代理会改变行为。因此候选代理只在已清理的独立目录收到正常的任务，不会看到 “eval” 或 “candidate”，也不知道还有其他候选。一名评委用中性标签为所有产物打分。是否顺着指引实际读了文件，以每个候选真正读过什么为准。

AGY 原生候选用 `invoke_subagent`，模型值来自 `agy:pro`、`agy:flash`、`agy:flash_lite` 或 `agy:inherit`。需要外部模型时，使用 `run_command` 调用 `scripts/multi-model-dispatch.sh`，让 `codex` 或 `pi` 在各自独立目录后台运行。测试技能版本的影响时，各候选应使用相同模型和配置。外部结果与原生结果一样，只用匿名标签交给评委。

接受判定前亲自读每份产物。如果不同意评委，先检查评分标准是否合适。

## 用 `/make-bot-ui` 构建 Bot 界面

[`/make-bot-ui`](../../skills/make-bot-ui/SKILL.md) 适用于 Grok Bot 的用户。可以构建一个小页面，点击按钮时通过 webhook 例程唤醒 Bot。例如，在审阅队列里滑动各项，每次滑动都让 Bot 处理对应事项。发送方密钥只留在本机服务器，浏览器和聊天里都不会收到它。使用 Grok Bot 宿主提供的例程。用户明确要求时，技能还介绍如何用 Tailscale 提供访问。

**常见陷阱。** 技能在任务中表现不佳时，先推进手头任务。把技能修复单独放进一个 PR。和功能改动混在一起的技能修改难以审阅，也无法独立评估。

下一页是[提示词示例与常见陷阱](./10-recipes-and-pitfalls.md)。
