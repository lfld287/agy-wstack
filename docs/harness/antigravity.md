# 在 Antigravity 中使用 pstack

`agy-wstack` 将上游 pstack 的流程接到 Antigravity（AGY）。下文的 `<插件根目录>` 包含 `plugin.json`、`agents/`、`skills/` 和 `scripts/`。阅读上游附带的 playbook 或独立技能时，按当前会话的工具 schema 转换调用。

## 插件与技能

AGY 从 `~/.gemini/config/plugins/agy-wstack` 发现用户插件，从 `.agents/plugins/agy-wstack` 发现项目插件。也可以在用户或项目配置根目录的 `plugins.json` 中用 `entries[].path` 注册插件的父目录，用 `include_only` 选中 `agy-wstack`。注册目录按一层扫描。项目配置使用工作区或仓库内的可信路径。用 `agy plugin list` 查看加载结果，用 `agy plugin validate <插件根目录>` 检查清单与文件。

输入 `/poteto-mode` 等技能名启动技能。被路由的技能从 `<插件根目录>/skills/<name>/SKILL.md` 读取，或使用本项目已经安装的兼容副本。上游流程提到 README、guide 或其他参考资料时优先读已安装副本。使用上游英文资产时仍按本手册映射工具。

## 工具映射

| 上游写法 | AGY 写法 |
| --- | --- |
| `Task` | 每席调用一次 `invoke_subagent`。并发时在同一轮发出多次调用。 |
| `AskQuestion`（Claude Code 的 `AskUserQuestion`） | `ask_question`。当前会话未提供该工具时，在对话中列出选项。 |
| `Read` / `Edit` / `Write` / `Bash` | `read_file` / `edit_file` / `write_file` / `run_command`。 |
| `Grep` / `Glob` | 使用当前会话提供的搜索工具，或用 `run_command` 执行 `rg` / `rg --files`。 |
| Todo 清单 | 使用当前会话的计划或待办工具。没有时在主会话保留并更新清单。 |
| `/loop` | 用 `schedule` 安排有明确检查条件的定时唤醒。用后台任务完成通知等待命令退出。 |
| Forge 内建 PR 操作 | 使用当前 forge 的命令或工具，例如 GitHub 的 `gh pr view`。创建或合并以操作员授权为准。 |

`<插件根目录>/skills/poteto-mode/scripts/watch-pr/watch-pr` 依赖本机安装的 `bun`，首次运行会在脚本目录安装依赖。也可以在安装后预先进入 `<插件根目录>/skills/poteto-mode/scripts` 执行 `bun install --frozen-lockfile`。本机缺少 `bun`，或者插件目录为只读且未预装依赖时，直接改用 `gh pr view`、`gh pr checks` 和 `gh api` 执行单次或轮询检查。

## 原生子代理参数

每次 `invoke_subagent` 调用直接传顶层字段 `TypeName`、`Role`、`Prompt`、`Model`、`Workspace`。

| 上游字段或要求 | AGY 映射 |
| --- | --- |
| `subagent_type` | `TypeName`，使用当前注册的 `poteto-agent`、`comment-sicko` 或通用代理类型。不硬编码另一个宿主的通用类型名。 |
| 角色描述 | `Role`，用 2 至 5 个词描述职责，使同轮的不同席位易于区分。 |
| `prompt`、`file_attachments` | `Prompt`，写明目标、作用范围、路径、证据和交付物。每个简报首行要求读取绝对路径的 `worker.md`。 |
| `model` | `Model: inherit\|pro\|flash\|flash_lite`。未配置角色规则且用户未显式指定时默认传 `inherit`，继承父会话；已通过 `pstack-models.md` 或显式指令指定时，按配置传入 `pro`、`flash`、`flash_lite` 或 `inherit`。按当前 schema 枚举，不能传外部 CLI 模型 slug。 |
| `environment` / `isolation` | `Workspace: inherit\|share\|branch`。`inherit` 使用父会话的同一工作区。`share` 使用共享仓库对象的独立工作区。`branch` 使用从父工作区派生的隔离副本。按实际基线和权限选择。 |
| `readonly: true` | 选用仅暴露所需工具的代理，简报明确只读。`comment-sicko` 仅有 `read_file`，由主会话提供 diff 或文件列表。其他代理使用 `run_command` 时限定为只读命令。审查前后核对范围内的工作区状态。 |
| `run_in_background` | 先发外部命令，再在同一轮为每个原生席单独调用 `invoke_subagent`。外部任务可在等待原生结果期间运行。 |
| `cloud_base_branch` | 简报写明分支、提交或快照，启动前校验副本。分支操作需在允许的工作区内进行。 |
| `resume` | 优先新建代理并附上旧报告。只有原代理持有迁移成本高的状态且工具支持继续交互时，才使用原会话。 |

简报首行写「在开始任何工作前，先完整阅读 `<插件根目录>/skills/poteto-mode/worker.md`。」，填写绝对路径。原生 `poteto-agent` 还要先完整读 `skills/poteto-mode/SKILL.md`。

## 双引擎调度

技能选模型时先读用户规则 `~/.gemini/config/rules/pstack-models.md`，再读项目规则 `.agents/rules/pstack-models.md`。项目按角色覆盖用户规则，同一文件中后出现的同名行生效。配置为普通 Markdown，无 `.mdc` 前置元数据。项目未设置的角色继承用户值。规则已配置或用户显式指定档位时，严格按指定的 `agy:pro`、`agy:flash`、`agy:flash_lite` 等档位或外部席调度。两处都未配置且用户未显式指定模型档位时，原生子代理默认传 `agy:inherit`，遵循 `invoke_subagent.Model` 契约且不擅自按复杂度切换档位，可通过 `/setup-pstack` 显式写入各角色档位。旧别名 `auto`、`inherit-parent` 等价于 `agy:inherit`。

按键名读取角色行，在第一个冒号处分开角色和值。面板的右侧按逗号拆成席位。每席只在第一个冒号处分开引擎前缀和参数，后续冒号属于参数，例如 `codex:profile:reviewer-codex` 与 `pi:anthropic/claude-opus-4-6:high`。

| 配置示例 | 调度方式 |
| --- | --- |
| `agy:pro`、`agy:flash`、`agy:flash_lite`、`agy:inherit` | 用 `invoke_subagent` 传相应的 `Model`。 |
| `codex:gpt-5.4`、`codex:profile:reviewer-codex` | 脚本的 `--engine codex --model gpt-5.4` 或 `--model profile:reviewer-codex`。 |
| `pi:anthropic/claude-opus-4-6:high` | 脚本的 `--engine pi --model anthropic/claude-opus-4-6:high`。 |

示例中的外部模型需在本机确认可用。用绝对路径运行 `<插件根目录>/scripts/multi-model-dispatch.sh --check` 检查二进制、Codex 登录与 Pi 模型目录。探测在临时空目录中执行 `pi --list-models`，退出后清理目录。这样 Pi 的 `runMigrations(cwd)` 只会在临时目录中查找项目配置。探测成功且有目录条目时报告 `catalog-ok`，仍需确认指定模型和凭证。空白输出或含 `No models available.` 的输出记为 `catalog-empty`。命令失败记为 `unavailable`。检查不发起推理，脚本退出码为 0，以各行状态为准。

一轮混编任务的顺序如下。

1. 准备同一份基线和权限明确的简报。给每席独立提示词、结果文件和可写路径。先创建结果目录。对比时各席共享相同任务和资料，只替换路径、编号等执行信息。
2. 在同一父会话轮次先为每个外部席发出 `run_command` 并设置 `WaitMsBeforeAsync: 500`，收集任务 ID。调用 `<插件根目录>/scripts/multi-model-dispatch.sh` 时传入 `--cwd <工作区绝对路径>`；普通命令需要切换目录时，在 `CommandLine` 中写 `cd -- "<workdir>" && ...` 或使用工具自身目录参数，例如 `git -C`。随后在同一轮为每个原生席分别调用 `invoke_subagent`，期间外部命令继续运行。任务短至同步完成时直接记下退出码。
3. 接收原生返回和外部完成通知。取回命令结果需要时调用 `manage_task` 的 `Action: status` 加 `TaskId`。用 `Action: kill` 取消指定任务，确认已退出后才回收目录。完成后确认退出码与独立产物，失败或缺产物的席位记为缺口。重试使用新的结果文件。

外部调用的 `CommandLine` 示例，替换示例中的本地绝对路径和模型。

```bash
"/path/to/agy-wstack/scripts/multi-model-dispatch.sh" \
  --engine codex --model profile:reviewer-codex \
  --cwd "/path/to/workspace" --mode readonly \
  --output "/path/to/run/codex-review.md" \
  --prompt-file "/path/to/run/codex-prompt.md"
```

脚本以调用目录为基准将 `PATH` 的相对和空条目转为绝对路径，引擎也以绝对路径调用。提示词文件和内联提示词都经标准输入传入，大提示词使用 `--prompt-file`。Codex 用 `exec ... -`，Pi 用 `-p --no-session` 且不传位置提示词。`@` 开头和形如 `--help`、`--offline` 的内容按正文传入。脚本透传引擎退出码，Codex 用 `-o` 写入最后一条回复，Pi 将标准输出写入结果文件。

- **Codex** 的 `readonly` 使用 `read-only` 沙箱，`write` 使用 `workspace-write` 沙箱。仅在选定的工作目录是非 Git 目录时添加 `--skip-git-check`。由于本机 Codex 即使传入 `-c 'mcp_servers={}'` 也会启用已配置的服务器，`<插件根目录>/scripts/multi-model-dispatch.sh` 在 `readonly` 模式下会先在目标工作目录执行 `codex mcp list` 预检，使用 profile 时执行 `codex -p <名称> mcp list`，存在状态为 `enabled` 的 MCP 服务器时直接拒绝启动。`arena cross-judge pool`、`interrogate reviewers` 与只读 `blast-radius` 等只读 Codex 席位不得裸用可能开启可写 MCP 的模型 slug，须选用已禁用可写 MCP 的只读 profile，例如 `codex:profile:reviewer-codex`。本机缺少该 profile 时，先创建只读 profile，对每个可写 MCP 服务器设置 `mcp_servers.<名称>.enabled = false`，同时禁用提供可写 MCP 工具的插件，并在目标工作目录用 `codex -p <名称> mcp list` 核对无 `enabled` 服务器。
- **Pi** 的 `readonly` 只开放 `read,grep,find,ls`，并用 `--no-extensions` 停用扩展。由扩展提供的供应商可能因此无法使用。脚本在目标目录存在 `.pi/commands` 且缺少 `.pi/prompts` 时拒绝启动只读任务，防止 Pi 的 `runMigrations(cwd)` 重命名旧目录。Pi 仅在成功退出后替换输出文件。

Pi 的工具限制作用于模型调用。启动 Pi 和探测模型目录时仍可能写入其用户状态目录。工作区的文件系统隔离由宿主负责。`write` 模式使用 Pi 的常规工具配置。审查需要 Shell 复现时，在隔离副本上运行，或由主会话重跑。

模型与供应商分别记录。原生 AGY 级别与 CLI 名称都不足以证明供应商差异。同一供应商经不同 CLI 启动，依旧算同一供应商。Pi 优先用带供应商的模型 ID。Codex profile 的供应商以实际 profile 为准。供应商未知时明确记录，避免把该结果当作异厂交叉验证。按技能说明选择可用回退，披露退席、替换和实际模型。

## 会话记录

优先使用宿主提供的 `transcriptPath`，其次在当前 AGY 会话数据目录中按已知会话 ID 定位记录。两者都不可用时，回退到 AGY CLI 默认路径 `~/.gemini/antigravity-cli/brain/<conversation-id>/.system_generated/logs/transcript.jsonl`。使用当前会话或已授权续接会话的 ID，只读与当前工作区有关的记录。外部 CLI 任务使用临时会话模式，其交付依据是指定结果文件和任务日志。

## Cursor 专属功能

| 上游步骤 | AGY 处理方式 |
| --- | --- |
| Cursor Automations 的例程、状态接口、webhook、唤醒、密钥交接 | 当前会话的周期检查可用 `schedule`。需要 Cursor 服务的步骤记为跳过，继续执行后续可做步骤，依赖项写明缺少哪个 URL、密钥或状态。 |
| Bugbot | 用 forge 工具读取已有检查和 PR 评论，按 [Bugbot 分流](../../skills/poteto-mode/references/bugbot-triage.md) 处理。需要启动、配置或等待 Bugbot 且没有对应检查时跳过该步。 |
| Cursor Cloud Agents | 本地任务使用 AGY `share` 或 `branch`，或给外部 CLI 准备隔离目录。依赖 Cursor 云端机器、面板状态或专用接口的步骤记为跳过。 |
| `deslop`、`control-ui`、`control-cli` | 用本机已授权工具复读 diff、驱动真实 UI 或运行 CLI，再记录证据。 |
| `create-skill` | 使用当前会话的技能创建工具，或按 Agent Skills 格式编写。 |

每个跳过项用一行说明原步骤和缺失的依赖。未获得发布、部署或发送外部消息授权时，继续本地实现和可执行的验证。
