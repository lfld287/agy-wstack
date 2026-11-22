# 搜索笔记

用户可以按标题或正文查找笔记、查看匹配结果，并分辨没有匹配项和搜索功能不可用的情况。

## 子功能

- `search-open` 从每个受支持的浏览器入口打开搜索。
- `search-match` 返回标题或正文匹配的结果，保持笔记数据原样。
- `search-open-result` 在笔记编辑器中打开一条结果。
- `search-empty` 对无匹配项的查询显示完整的空状态。
- `search-clear` 清除查询并恢复最近笔记视图。
- `search-cli` 从终端返回相同的匹配笔记。

## 如何进入（用户视角）

- 点击浏览器工具栏的 `Search`。
- 浏览器焦点处于可编辑字段之外时，按 `/`。
- 在终端运行 `notes search <query>`。

## 使用 control-notes 驱动

前置条件。

- Notes 在 `http://127.0.0.1:4173` 正常运行。
- 可丢弃的数据目录中有一篇标题为 `Quarterly plan`、正文为 `Draft budget` 的笔记。
- `control-notes doctor` 报告的 URL 和数据目录与预期一致。

- **工具栏入口。** 选择 `Search`。运行 `control-notes browser click --role button --name "Search"`。出现名为 `Search notes` 的对话框，焦点在搜索框。
- **键盘入口。** 关闭对话框，把焦点移到页面上，再按 `/`。运行 `control-notes browser press --key "/"`。应打开同一个对话框，页面没有插入斜杠。
- **标题匹配。** 输入 `quarterly`。运行 `control-notes browser fill --role searchbox --name "Search notes" --value "quarterly"`。`Search results` 列表包含 `Quarterly plan`，没有 `Grocery list`。
- **证明。** 在 `quarterly` 的匹配结果出现后采集证据。运行 `control-notes browser snapshot --aria --path artifacts/search/results.aria.txt` 和 `control-notes browser screenshot --path artifacts/search/results.png`。两件产物均能辨认出 Notes、所用查询和 `Quarterly plan`。
- **正文匹配。** 将查询改成 `budget`。运行 `control-notes browser fill --role searchbox --name "Search notes" --value "budget"`。`Quarterly plan` 仍在结果中，并显示匹配正文的摘要。
- **打开结果。** 选择 `Quarterly plan`。运行 `control-notes browser click --role link --name "Quarterly plan"`。对话框关闭，编辑器标题显示 `Quarterly plan`。
- **空状态。** 重新打开搜索并输入 `volcano`。运行 `control-notes browser fill --role searchbox --name "Search notes" --value "volcano"`。搜索完成后出现名为 `No matching notes` 的状态提示。
- **清除查询。** 选择 `Clear search`。运行 `control-notes browser click --role button --name "Clear search"`。搜索框清空，结果列表被 `Recent notes` 区域替换。
- **CLI 匹配。** 从终端搜索。运行 `control-notes cli -- notes search "quarterly" --format json`。退出码为 `0`，stdout 包含一个标题为 `Quarterly plan` 的对象。
- **CLI 无匹配。** 搜索不存在的值。运行 `control-notes cli -- notes search "volcano" --format json`。退出码为 `0`，stdout 为 `[]`。

## 注意事项

- 编辑器或搜索框有焦点时按 `/` 会输入文本。焦点移到其他区域才能用它打开搜索。
- 搜索结果会在短暂的防抖延迟后更新。等待结果列表或空状态出现，避免固定时长的等待。
- 归档的笔记默认不参与搜索，用户启用 `Include archived` 后才包含。
- CLI 默认输出供人阅读的格式。稳定断言使用 `--format json`。
- 打开一条结果会改变浏览器状态。验证下一个查询前先重新打开搜索。
