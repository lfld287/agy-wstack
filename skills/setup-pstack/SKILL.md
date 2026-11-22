---
name: setup-pstack
description: 探测 AGY 子代理和本地模型 CLI，按推理预算为 pstack 角色选模型并写入规则。用于 /setup-pstack 和调整模型配置。
---

# 配置 pstack 模型

在用户规则 `~/.gemini/config/rules/pstack-models.md` 中为每个角色写一行。项目可以通过 `.agents/rules/pstack-models.md` 按角色覆盖。技能读两个文件，无对应行时才使用默认值。

## 1. 探测可用模型

- 枚举当前 `invoke_subagent` 的 `Model` 取值，将可用项记为 `agy:pro`、`agy:flash`、`agy:flash_lite`、`agy:inherit`。以工具 schema 为准。`agy models` 可辅助确认会话模型，CLI 列出的模型 ID 不能直接当作原生子代理参数。继承父会话用 `agy:inherit`，旧别名 `auto`、`inherit-parent` 读取时等价。
- 定位已安装插件的根目录，用 `run_command` 执行 `<插件根目录>/scripts/multi-model-dispatch.sh --check`。状态为 `ready` 的 Codex 通过了登录检查。用本机模型选择器或已配置的 profile 确认具体模型。配置写作 `codex:<slug>` 或 `codex:profile:<name>`。
- 需要查看具体模型时，在临时空目录执行 `pi --list-models`，避免触发 Pi 的项目配置迁移。从本机模型选择器、供应商配置或用户确认中核实凭证和实际可用项。Pi 支持 `pi:<provider>/<model>:<effort>`。本机 Pi 支持时可用 `pi auth check --model <id> --no-refresh` 核对凭证状态。保持凭证私密。
- 遇到目录失败或能力不明确，记录原因，使用已确认项起草配置。若用户希望补充外部模型，用 `ask_question` 询问其可用的 ID 或 profile。

## 2. 读取现有配置

读取用户规则、项目覆盖和预算行。以第 5 节的九个键为准，列出并移除用户规则中已废弃的键，例如 `hardest tasks`、`architect runners`、`reflect tooling`、`why investigators`。保留项目覆盖，预览时展示它影响哪些角色。

迁移无 `# defaults: 4` 的规则时，将已知旧宿主默认改为本节对应的 AGY 默认。旧默认包括 Opus 5.5 的标准代码和快速席位、面板中的 Gemini 4 Neon 默认席、上游 Fable/Opus/Gemini 默认面板。无 `# defaults: 3` 时也检查旧三席交叉评审池（Fable 与 Opus 都算 Anthropic）和 `unlimited` 预算（映射到 `large`）。无 `# defaults: 2` 的已知旧 Grok 默认席一并重新选择。保留其他确认可用的显式选择和席位顺序。旧宿主自定义 slug 需要明确映射到本机引擎，无法确认时列为待选。逐项说明转换、移除和保留的设置。

## 3. 选预算和角色

先用 `ask_question` 询问预算。显示现有预算，首次配置默认 `large`。工具缺失时在对话中提供相同选项。

| 选项 | 推理预算目标 | 原生角色起点 |
| --- | --- | --- |
| `large` | 复杂任务以 `xhigh` 为上限 | 代码和判断用 `agy:pro`，机械工作和验证用 `agy:flash`。 |
| `medium` | 在 `xhigh > high > medium > low` 上下调一档 | 复杂工作可用 `agy:pro`，常规任务和验证用 `agy:flash`。 |
| `small` | 下调两档，最低 `low` | 常规任务用 `agy:flash`，轻量任务用 `agy:flash_lite`。 |

预算选择 AGY 的模型级别，AGY 级别没有与外部 reasoning 参数一一对应的关系。可显式保留 `agy:inherit`。外部引擎仅在已确认模型支持该设置时调整推理预算。Pi 使用支持的后缀。Codex 通过本机已配置的 profile 固定努力等级。保留原供应商或模型家族，在目标档不可用时选同家族支持的最高低档，仍无选项时标记待选。已选面板席位在运行时保持配置中的档位。

用 `ask_question` 展示九个角色的最终候选值和迁移项，请用户确认或指定要调整的角色。单角色值只能有一个。 `arena runners` 和 `interrogate reviewers` 的每项代表一个席位，含继承项。优先保留原生席和至少一个已确认可用的外部席，再考虑已确认的跨供应商差异。 `arena cross-judge pool` 是按偏好排序的候选，Arena 只运行一位，跳过继承项及与父会话同供应商的项。 `swarm workers` 是每个工作者的默认值，异构对比可逐席指定。

## 4. 校验与回退

校验每个前缀、外部 ID、profile 和已声明的努力等级。面板保留至少两席。外部项未探测成功时，优先用其他已确认的引擎，或改为可用的 `agy:pro, agy:flash`。原生级别不可用时用已支持的级别或 `agy:inherit`，并告知哪些席位共用模型。如果无法满足明确的异构或异厂要求，说明缺口。用户选了未确认项时，请其换成验证过的选项。

`arena cross-judge pool` 和 `interrogate reviewers` 等只读 Codex 席位使用 `codex:profile:reviewer-codex`。本机缺少该 profile 时，先创建只读 profile，或选用已禁用可写 MCP 的配置。配置和核对方式见 [双引擎调度](../../docs/harness/antigravity.md#双引擎调度)。

## 5. 写入用户规则

以普通 Markdown 写入 `~/.gemini/config/rules/pstack-models.md`，更新整个规则文件以保持重复执行一致。示例中的外部值仅在第 1 步确认后写入。删除单行可恢复该角色的回退顺序。解析时以行的首个冒号分隔键和值，保留值内的冒号。

```text
# pstack 角色模型。每行一个角色。项目可以按角色覆盖。
# defaults: 4
# budget: large (xhigh)
feature, refactoring: agy:pro
bug-fix: agy:pro
perf-issue: agy:pro
hillclimb: agy:pro
judgment and prose: agy:pro
arena runners: agy:pro, codex:gpt-5.4, pi:anthropic/claude-opus-4-6:high
arena cross-judge pool: codex:profile:reviewer-codex, pi:anthropic/claude-opus-4-6:high, agy:flash
swarm workers: agy:flash
interrogate reviewers: agy:pro, codex:profile:reviewer-codex, pi:anthropic/claude-opus-4-6:high
```

## 6. 确认结果

回读规则，核对全部角色、面板顺序和预算。报告写入路径、项目覆盖、检测结果和任何回退。重跑本技能可更新配置。

## 7. 可选的行为验证技能

检查项目是否有 `verify-*` 技能或可按真实用户方式驱动应用的现有工具。缺失时询问一次是否创建。用户同意且入口可用时，运行 `/create-verification-skill`。

## 8. 可选的形式验证技能

检查项目是否已有可运行的模型检查、证明或其他形式验证技能。缺失时询问一次是否为关键性质创建。用户同意且入口可用时，运行 `/create-formal-verification-skill`。
