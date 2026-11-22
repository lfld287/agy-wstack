# 可直接复制的提示词

换成实际路径、技能和完成检查。用日常说话的方式就行。

## 理解

- `/poteto-mode 阅读 <讨论串>，用自己的话平实地复述根本问题。`
- `/in-your-own-words <冗长或杂乱的请求>`
- `/sharpen <你将要发送的提示词>`
- `/poteto-mode 调查 <症状> 为什么出现。告诉我已知事实、用到的数据和最可能的假设。先别改代码。`
- `用 /how 了解 <子系统>，再用 /why 查它最近为何出了问题。`
- `/recall 回顾我上周在 <主题> 上的工作，然后读 <工单>。`
- `/teach 告诉我为什么你用了现在的实现，和 <替代做法> 相比有什么取舍？`
- `/poteto-mode take over this branch. 读决策日志，找出已完成的部分再继续。跳过已做完的工作。`

## 实现

- 缺陷。`/poteto-mode <症状>。先复现，再修复和验证。`
- 应用里的缺陷。`/poteto-mode 用 /verify-<app> 复现。如果 main 上能复现，就修复并录一段视频给我作证。`
- 有低成本测试的缺陷。`/poteto-mode 先复现 <缺陷>。测试成本低就用 /tdd。然后修复并重跑。`
- 功能。`/poteto-mode 添加 <行为>。<当前输出> 保持逐字节一致。验证两者。`
- 重构。`/poteto-mode 把 <代码> 移入一个模块，行为零变化。先记录当前输出，再证明重构后输出一致。`
- 性能。`/poteto-mode <操作> 在 <fixture> 上耗时 <时间>。追踪并修复实测成因，给我前后对比。`

## 设计与规划

- `/poteto-mode 为 <功能> 做几个方案原型。截图或录像给我比较。`
- `/poteto-mode 我们需要 <功能>。先 /architect，再用原型解答开放性问题。等我审阅后再继续。`
- `/poteto-mode 先写一份 <新包> 的使用教程，再用 /teach 讲清它比现有包好在哪。`
- `针对这串讨论和当前做法，请 /arena 给个独立意见。`
- `/poteto-mode 把这份设计变成计划，拆成可验证的小 PR，每个 PR 有独立验证步骤。`
- `/poteto-mode 规划从 <库> 到 <目标> 的迁移。拆成可验证的小 PR。结果必须与原版完全一致，包括原有缺陷。`

## 审阅与交付

- `/interrogate 以怀疑的态度审查整个分支。先不改东西。只报真实缺陷或回归。` 也读 Dropped 清单。
- `/create-formal-verification-skill 证明 <性质> 在 <模块> 中成立，包括 <步骤> 交错执行或重试时。` 这些代码合并或重构后，运行 `/maintain-formal-verification-skill`。
- `/swarm 按各包的检查脚本核查 <目录> 下的所有包。每包一个工作代理，交一份报告。`
- `/poteto-mode open the pr. 拆成小而有序的提交，在描述中附证据。`
- `/poteto-mode babysit this pr. 跟进直到全绿。` 只看状态则用 `/poteto-mode check on pr <编号>。还有遗留项吗？`
- `/poteto-mode land the stack.`

## 离开与回来

- `/poteto-mode im going to bed. 从 <基线> 开新 worktree，完成 <目标>。完成条件是 <检查>。保留决策日志，提交前不用问我。用 schedule 持续唤醒，做到完成。如果几小时后确实卡死，停下并写清原因。`
- `/show-me-your-work 告诉我你昨晚做了什么。` 先看「需关注」（Attention）一节。
- `/ketchup` 回顾此聊天自你上条消息后的变化，并列出每个等你决定的事项。
- `/poteto-mode full autopilot on this queue. 各项互相独立。`
- `/poteto-mode autopilot these changes, but don't merge. 我来合并。`
- `/reflect 记录我们学到的经验，避免下次重蹈覆辙。` 只批准能改变未来决定的编辑。
- `/bro` 用平实的话复述上一条回复。
