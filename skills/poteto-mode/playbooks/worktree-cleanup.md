### 清理工作树和模拟器

1. 记录现状并审计。先记录 `df -h /`，再运行 `<插件根目录>/skills/poteto-mode/scripts/worktree-audit.sh [-b <pr-base-ref>] [--no-fetch] [repo-path]`（**principle-build-the-lever**）。不传 `-b` 时按 `origin/HEAD` 判定 `MERGED`。PR 以其他分支为基线时，传 `-b origin/<branch>`。传 `--no-fetch` 可跳过 Git 远端引用刷新。脚本从 `git worktree list` 取路径，避免手填路径时漏掉位于隐藏目录中的工作树（**principle-encode-lessons-in-structure**）。脚本核对 PR 的 `head` 与 `base`，按大小、使用时间、合并状态、未提交工作、PR 状态和最近访问的会话给出建议分类，并在未扫描 AGY 会话时标注 `unchecked:agy`。扫描日志较慢，用 AGY `run_command` 在后台运行并靠完成通知与 `manage_task` 回收。对标注 `unchecked:agy` 或未覆盖 AGY 日志的工作树，按第 2、3 步用 AGY 会话信息补查。
2. 建议分类不能当作删除许可。按 **principle-prove-it-works**，以置顶和活跃会话为准。从用户或 AGY 侧边栏取得会话清单，与每个候选工作树交叉核对。脚本曾把用户置顶的工作树标成 `safe`，这时以置顶清单为准。
3. 删除前确认使用情况。对每个 `verify-recent-chat`、`unchecked:agy` 条目和任何存疑项，按[自主执行](autonomous-run.md)的 AGY 调度约定并行派子代理读日志（**principle-guard-the-context-window**）。优先使用宿主提供的 `transcriptPath`，其次在当前 AGY 会话数据目录中按已知会话 ID 定位日志。两者都不可用时，回退到 AGY CLI 默认路径 `~/.gemini/antigravity-cli/brain/<conversation-id>/.system_generated/logs/transcript.jsonl`。只在当前工作区已知会话范围内核对。报告会话是否置顶或仍在进行，以及它用到哪些工作树。置顶会话可能通过后台任务把 `arena` 或复现用工作树建在同级目录，这些工作树即使没在侧边栏单独显示，也属于使用中。
4. 遇到不可逆的损失就停。`wip:N` 表示有 N 项已跟踪但未提交的改动。先展示差异，再用 AGY `ask_question` 请用户决定。干净工作树可从分支恢复，未提交改动删除后会丢失。`scratch:N` 统计未跟踪的 `??` 条目，`ignored:M` 统计被忽略的 `!!` 条目。执行 `git worktree remove --force` 前，在候选工作树中用 `git status --short --untracked-files=all --ignored=matching` 列出两类条目。逐项核对文件和目录内容，确认没有只存于该工作树的重要本地配置或生成器输入，并确认所列内容可重建，或已保存到工作树之外且验证可恢复。无法确认就暂停，并列出相关文件。按 `SKILL.md` 的自主执行规则，干净、已合并且无人使用的工作树可继续处理。`wip` 或使用中就暂停。
5. 清理已确认的工作树。逐个执行 `git worktree remove --force <path>`。若忽略的构建产物让目录留存，对该目录用 `rm -rf`，再执行 `git worktree prune`。分支引用保留，提交也随之保留。再次运行 `df -h /` 并重新列出工作树确认。
6. 清理模拟器和其他可回收空间。模拟器通常能腾出第二多的空间。用 `xcrun simctl --set testing delete all` 清 XCTestDevices 克隆，用 `xcrun simctl delete unavailable` 清不可用的模拟器，用 `xcrun simctl runtime list` 列出运行时，再用 `xcrun simctl runtime delete <id>` 清旧运行时。需要时还可清 Xcode 的 `DerivedData`、`iOS DeviceSupport` 和包管理器缓存（pnpm、uv、brew、yarn）。仅在用户明确要求清理 Cursor 时处理其应用缓存。旧缓存位于 `~/Library/Application Support/Cursor`，例如 `state.vscdb.backup`，以及打开某个文件夹作为工作区后会膨胀的 `snapshots/roots/<root>`。只清用户未要求保留的缓存。

本手册会删除用户状态，也没有代码评审替你发现误操作，以上关卡就是本次审查。

**回复**应包含清理前后的 `df -h /`、回收空间、移除的工作树，以及每个暂缓项的一行理由（哪个会话在用，或有未提交工作）。
