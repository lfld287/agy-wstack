---
name: principle-migrate-callers-then-delete-legacy-apis
description: "引入新内部 API 且仍有旧 API 的调用方时使用。在同一轮改动中迁移调用方并删除旧 API，避免留下兼容层。"
disable-model-invocation: true
---

# 迁移调用方后删除旧 API

- 更新测试以断言新契约，并删除只保护重构前实现细节的测试。

**适用条件**

- 没有外部用户依赖向后兼容。
- 项目能够承受协调进行的破坏性变更。
- 新 API 是简化或重构工作的一部分。
