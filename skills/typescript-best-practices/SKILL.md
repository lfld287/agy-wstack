---
name: typescript-best-practices
description: "TypeScript 最佳实践。读取或编辑任何 .ts 或 .tsx 文件时使用。"
paths: ["**/*.ts", "**/*.tsx"]
disable-model-invocation: true
---

# TypeScript 最佳实践

先应用 **type-system-discipline** 原则技能。

| 规则 | 要点 |
|------|------|
| 可辨识联合 | 用 `kind` 字面量字段区分变体，让非法组合无法表示。避免堆砌可选字段。 |
| 品牌类型 | 用 `& { readonly __brand: "X" }` 区分原始类型，防止混用。在边界验证一次。用真正验证值的类型守卫（`input is AgentId`）赋予品牌，禁止用 `as` 直接赋予品牌。 |
| 构造式建模 | 用类型结构使非法值无法构造。非空用 `[T, ...T[]]`，偶数长度用 `[T, T][]`，区间用 `start` 加 `duration`。在边界校验并构造品牌类型后，内部链路可免去重复校验。 |
| 支持全定义操作的最简类型 | 只要在 `T[]` 上的每个操作都有定义，就保留 `T[]`。只有宽松类型迫使你用 `!`、类型断言或抛出「不该发生」的错误时，才收紧到 `NonEmpty<T>`。 |
| 优先 `unknown` | 外部数据用 `unknown`。 |
| 优先使用 schema | 在逐字段手写类型守卫前，先用仓库的运行时 schema 库，通过 `z.infer` 等方法从 schema 推导类型。 |
| 限制 `as` 断言 | 每个 `as` 都可能在运行时崩溃。验证后才可以断言。 |
| 类型收窄优先级 | 可辨识字段的 switch > `in` > `typeof` 或 `instanceof` > 自定义类型守卫 > `as`。 |
| 类型守卫 | 必须验证它声称的事实。失实的守卫比 `as` 更糟，因为名字会掩盖问题。用 `isX` 或 `hasX` 命名。 |
| 穷尽性检查 | 在默认分支内写 `const _exhaustive: never = x;`，使新增变体时编译器报错。 |
| 优先 `satisfies` | 检查值是否符合类型，同时保留其字面量类型。 |
| 边界验证 | 数据进入时解析为具名领域类型。`Record<string, unknown>` 或同类宽类型到解析入口为止。内部信赖类型。参见 **boundary-discipline** 原则技能。 |
| 从现有定义派生类型 | 声明新接口前，先考虑 `Pick`、`Omit`、`Parameters`、`ReturnType`、`Awaited` 和 `typeof`。 |
| 对象参数 | 用对象表达参数含义，避免靠位置识别参数。热路径除外，例如逐帧渲染、词法分析器、解析器。 |
| 真实测试 | 能运行的就直接运行。优先用框架的真实测试能力，检查泄漏和可释放资源，并在运行中的构建验证界面。只 mock 本地跑不了的东西。 |
| 结构化遥测 | 优先用日志器输出有足够上下文的结构化诊断信息，使人能根据 ID 排查。发布代码中不要用 `console.log`。 |

示例见 `references/patterns.md`。
