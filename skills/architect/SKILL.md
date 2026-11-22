---
name: architect
description: "先勾勒类型、签名和模块结构，再在实现过程中持续跟进设计。用于 /architect、「给这个做架构设计」「设计一下」（architect this、design this），或直接写代码容易过早定型的复杂任务。"
disable-model-invocation: true
---

# 架构设计

动笔写代码前，梳理改动涉及的每个系统，分别勾勒两种方案的类型、签名和模块边界。选择每份状态只有一个所有者、每项任务只有一条实现路径、调用方所需背景最少的方案。在实现过程中持续检查设计是否成立。如果同一种权宜做法一再出现，就重新设计。

设计规模较大或存在争议时，使用 [**arena**](../arena/SKILL.md) 技能并行推演。用 `read_file` 读取用户规则 `~/.gemini/config/rules/pstack-models.md` 和项目规则 `.agents/rules/pstack-models.md`，按角色应用项目覆盖，缺少设置时用 arena 默认值。根据 `arena runners` 与 `arena cross-judge pool` 选择候选和交叉评审。

按 [双引擎调度](../../docs/harness/antigravity.md#双引擎调度) 在同一轮派发两种引擎。先用 `run_command` 设置 `WaitMsBeforeAsync: 500`，通过 `scripts/multi-model-dispatch.sh` 发出配置中的 `codex` 或 `pi` 后台任务，再用 `invoke_subagent` 启动 AGY 原生批次。`Model` 可选 `inherit`、`pro`、`flash`、`flash_lite`。`Workspace` 可选 `inherit`、`share`、`branch`，只读设计可共享，需要隔离写入时采用获准的独立工作区。给两类候选相同的任务与输入、各自的输出位置。用 `manage_task` 核对外部任务是否完成。收齐结果后，按同一标准比较至少两种方案，参考独立评审，选出基础方案并验证综合后的设计。
