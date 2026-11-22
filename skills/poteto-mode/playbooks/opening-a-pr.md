### 开 PR

作为其他手册的收尾步骤，在本次任务授权开 PR 时执行。

沿用承载本次改动的工作树，核对当前 `HEAD` 与目标基线分支。堆叠 PR 以父 PR 分支为目标基线。若尚未隔离工作树，在开发阶段提前分出独立工作树并在其中完成本次改动。用 rebase 整理出小而可合入的提交。提交前逐行复读差异，手动去掉冗余、空话和无用注释，对应 Cursor 的 `cursor-team-kit` 中的 `/deslop`。

标题用 `type(scope): subject`。若改动集中在某个具体符号上，点出真实符号名。正文少于 40 行，一分钟能读完。按 `worker.md` 的固定二级标题依次写改动原因（`## Why`）、改动内容（`## What changed`）、改动范围（`## Scope`）、取舍（`## Tradeoffs`，只写评审者很可能追问的被否决方案）、影响范围（`## Blast Radius`）和验证（`## Verification`）。空节省略。

有依赖的后续 PR 按基线分支堆叠。通过本次执行所用的 PR 工具用 `draft: false` 创建可评审 PR。没有专用工具时，运行不带 `--draft` 的 `gh pr create`。Origin CLI 能识别仓库时，可用 `origin pr create --status open`。开 PR 不会自动进入[盯 PR](babysit.md)。
