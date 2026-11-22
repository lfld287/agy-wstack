# 创建笔记

用户可在浏览器或 CLI 保存带标题的笔记，取消未完成的草稿，并从另一个用户可见视图确认保存结果。

## 子功能

- `create-open` 从每个浏览器入口打开空白编辑器。
- `create-save` 持久化保存标题与正文。
- `create-cancel` 丢弃浏览器中未完成的草稿。
- `create-cli` 从终端创建同样结构的笔记。

## 如何进入（用户视角）

- 点击浏览器工具栏的 `New note`。
- 浏览器焦点处于可编辑字段之外时，按 `n`。
- 在终端执行 `notes create --title <title> --body <body>`。

## 使用 control-notes 驱动

前置条件。

- Notes 在 `http://127.0.0.1:4173` 正常运行。
- 当前没有标题为 `Release checklist` 的笔记。
- `control-notes doctor` 报告的 URL 和可丢弃数据目录与预期一致。

- **打开编辑器。** 选择 `New note`。运行 `control-notes browser click --role button --name "New note"`。出现名为 `Note editor` 的表单，焦点落在 `Title` 文本框。
- **填写内容。** 输入标题和正文。运行 `control-notes browser fill --role textbox --name "Title" --value "Release checklist"` 和 `control-notes browser fill --role textbox --name "Body" --value "Tag and publish"`。`Save note` 按钮变成可用。
- **保存笔记。** 选择 `Save note`。运行 `control-notes browser click --role button --name "Save note"`。出现名为 `Note saved` 的状态提示，标题显示 `Release checklist`。
- **确认持久化。** 回到笔记列表并重新打开笔记。运行 `control-notes browser click --role link --name "All notes"` 和 `control-notes browser click --role link --name "Release checklist"`。编辑器显示保存的标题和正文。
- **取消草稿。** 打开新笔记，输入 `Discard me`，选择 `Cancel`。运行 `control-notes browser click --role button --name "New note"`、`control-notes browser fill --role textbox --name "Title" --value "Discard me"` 和 `control-notes browser click --role button --name "Cancel"`。回到笔记列表，列表没有 `Discard me` 链接。
- **CLI 入口。** 创建第二篇笔记。运行 `control-notes cli -- notes create --title "CLI note" --body "Created from terminal" --format json`。退出码为 `0`，stdout 包含新笔记的 ID 和标题。
- **证明。** 从 `All notes` 重新打开两篇已保存的笔记。运行 `control-notes browser snapshot --aria --path artifacts/create-note/list.aria.txt` 和 `control-notes browser screenshot --path artifacts/create-note/list.png`。产物中应能看到 `Release checklist` 和 `CLI note`。

## 注意事项

- 文本框有焦点时按 `n` 会输入字符，焦点在可编辑字段外才会打开新编辑器。
- 保存时会裁掉标题首尾空白。断言页面最终呈现的标题。
- 保存提示本身不足以证明持久化。要从列表重新打开笔记。
- 清理测试数据时删掉 `Release checklist` 和 `CLI note`，保留对应的证明产物。
