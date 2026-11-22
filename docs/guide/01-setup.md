# 安装和配置 agy-wstack

先在 Antigravity 安装插件，再选模型并跑一次实际任务。模型配置只需一条命令和几次选择。

## 安装插件

把包含 `plugin.json`、`skills/`、`agents/` 和 `scripts/` 的插件根目录放到以下任一位置。

- 用户级使用 `~/.gemini/config/plugins/agy-wstack`。
- 项目级使用 `.agents/plugins/agy-wstack`，由当前工作区加载。

如需显式注册，在对应配置根目录的 `plugins.json` 中加入父目录。用户文件是 `~/.gemini/config/plugins.json`，项目文件是 `.agents/plugins.json`。合并到现有 `entries`，保留其他条目。扫描父目录下一层，用 `include_only` 选中插件。把示例路径替换为实际的绝对路径，项目注册使用工作区内可信路径。

```json
{
  "entries": [
    {
      "path": "/absolute/path/to/plugins",
      "include_only": ["agy-wstack"]
    }
  ]
}
```

验证插件清单并确认 AGY 已加载。

```sh
agy plugin validate "/absolute/path/to/plugins/agy-wstack"
agy plugin list
```

上游版在 Cursor 聊天中运行 `/add-plugin pstack` 安装，Cursor 会反馈安装状态。在 Claude Code 中先运行 `/plugin marketplace add cursor/plugins`，再运行 `/plugin install pstack@cursor-plugins`。Claude Code 给插件命令加 `pstack:` 前缀，例如 `/pstack:setup-pstack`，它把模型规则写入 `~/.claude/rules/pstack-models.md`。其他差异见 [Claude Code 适配手册](https://github.com/backnotprop/pstack/blob/main/docs/harness/claude-code.md)。本指南的流程以 [AGY 适配手册](../harness/antigravity.md)为准。

## 选择模型

在 AGY 中运行下列技能。

```text
/setup-pstack
```

[`/setup-pstack`](../../skills/setup-pstack/SKILL.md) 探测可访问的模型，使用 `ask_question` 询问推理预算，列出各角色（代码执行、判断和评审小组等），并询问你的选择。它把配置写到普通 Markdown 文件 `~/.gemini/config/rules/pstack-models.md`。项目可用 `.agents/rules/pstack-models.md` 按角色覆盖，技能读取两者。

默认预算为 `large`。代码、文字和判断默认走 `agy:pro`，机械任务和普通验证默认走 `agy:flash`，未配置的评审小组可由两者组成。外部模型按支持的档位配置，复杂工作上限为 `xhigh`。`medium` 和 `small` 的推理预算目标分别下调一档和两档，成本相应下降。AGY 原生模型档位与外部推理等级没有一一对应关系。上游默认曾用 Opus 5.5 的 `xhigh` 负责代码、文字和判断，评审和 swarm 使用 `high`。

只覆盖你关心的角色。没有配置行的角色保持该技能默认值。恢复默认时删除相应行，两处都未配置才回到默认。重跑 `/setup-pstack` 会保留不同于默认的有效选择。默认值更新后，旧规则仍可能固定旧值。重跑配置会替换可识别的旧默认值，说明替换了哪些，并保留其他选择。要解除一个未识别的固定项，先删除该行或规则文件。

希望使用当前会话模型时，把角色设置为 `agy:inherit`。旧别名 `auto` 和 `inherit-parent` 意义相同。它们是继承配置值。原生调度使用 `Model: inherit`。并发面板的每个配置项对应一个子代理，因此其列表长度决定面板大小。`arena cross-judge pool` 是候选列表，Arena 按偏好依序选择首个符合条件且可用的只读评审，每次最多运行 1 席。配置也设置 `swarm workers`，作为 `/swarm` 工作代理的默认模型。竞跑可逐席指定模型。

### 两条模型调度路径

| 模型规则中的值 | AGY 如何运行 |
|---|---|
| `agy:pro`、`agy:flash`、`agy:flash_lite`、`agy:inherit` | 用 `invoke_subagent` 启动内置子代理，`Model` 分别传 `pro`、`flash`、`flash_lite`、`inherit`。 |
| `codex:<模型或 profile>`、`pi:<供应商/模型:推理档位>` | 通过 `run_command` 调用 `scripts/multi-model-dispatch.sh`，将本地 CLI 放到后台运行。Codex profile 写作 `codex:profile:<名称>`。 |

先运行脚本的 `--check` 探测已装 CLI。为每个外部席位确认具体模型和凭证，目录探测成功只表示目录可读。混合调度时先用 `run_command` 发外部任务（`WaitMsBeforeAsync: 500`），再在同轮为原生席并发逐席调用 `invoke_subagent`，每次在顶层传 `TypeName`、`Role`、`Prompt`、`Model`、`Workspace`。外部任务用独立结果文件，必要时通过 `manage_task` 查状态。完整参数见 [AGY 双引擎调度](../harness/antigravity.md#双引擎调度)。

## 选择是否建立验证技能

配置结束前，`/setup-pstack` 会查项目有没有可证明应用行为的办法，例如 `verify-*` 技能或现成的验证工具。两者都没有时，它会询问一次是否通过 [`/create-verification-skill`](../../skills/create-verification-skill/SKILL.md) 创建。

答应后，技能会写入项目目录 `.agents/skills/verify-<app>/`，告诉代理如何像用户一样操作应用。交付前会实际运行一次证明技能有效。拒绝后配置继续。也可以随时自己调用 `/create-verification-skill`。详细用法见[创建项目验证技能](./06-verify-and-ship.md#create-a-project-verification-skill)。

刚开始用 pstack 时，建议接受。能亲自验收的代理可以继续工作直到检查通过。没有验证入口时，你得手工核对代理交回的每份结果。这是本指南里收益最大的一项配置。

接着，如果项目还没有形式验证技能，配置会询问一次是否通过 [`/create-formal-verification-skill`](../../skills/create-formal-verification-skill/SKILL.md) 生成。测试覆盖有人想到并写下的情况。形式验证技能会在声明的范围内检查每种情况是否满足一个关键性质，例如「同一个任务永远不会并发执行两次」。如果代码有并发、重试、状态机或解析器，且出错成本高、测试难以碰到失败情形，可以接受。否则先拒绝，情况改变后再运行。参见[用形式验证技能证明一个性质](./06-verify-and-ship.md#prove-a-property-with-a-formal-verification-skill)。

配置后新开一个聊天。模型规则应用于新会话。

## 控制成本

子代理和评审席位会消耗额外 token。可以这样控制成本。

- 重跑 `/setup-pstack` 选择较小预算或较低成本的模型。主会话用强模型，普通实现用更快、成本更低的模型。
- 角色使用 `agy:inherit`（兼容 `auto` 和 `inherit-parent`），以继承本会话的模型。
- 缩短并发面板列表，每项各运行一个子代理。`arena cross-judge pool` 只运行选中的 1 席，成本按实际选中的评审估算。
- 把 `/poteto-mode` 用在确实需要严谨流程的任务。小而明显的编辑可以直接做。

<a id="run-your-first-task"></a>

## 运行第一项任务

选一项真实但不大的工作，像向同事说明一样描述。

```text
/poteto-mode 为这条命令添加 --json 参数。文本输出保持逐字节一致。两种输出都要验证。
```

看待办列表。第一批待办来自匹配到的 playbook。本例匹配 Feature。

接下来可以用普通对话跟进。AGY 中，在本次会话要持续按此模式工作时，启动时把要求写清楚。换一项任务时重新输入 `/poteto-mode` 或显式说 “new task”。在上游 Cursor 中，普通 Enter 只附着到一条消息，后续会淡出。Mac 用 Option+Enter、Windows 用 Alt+Enter 从斜杠菜单选择技能可进入 [Custom Mode](https://cursor.com/docs/skills#using-a-skill-as-a-custom-mode)，直到退出前每轮都保留上下文。Cursor 的 Agents Window 和 CLI 都支持该功能。

下一页是[用 `/poteto-mode` 分派任务](./02-poteto-mode.md)。
