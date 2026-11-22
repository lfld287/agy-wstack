# TypeScript 模式

以下是 `SKILL.md` 各规则的代码示例。背后的原则不限于某种语言。参见 **type-system-discipline** 和 **boundary-discipline** 原则技能。

## 品牌类型

给原始类型加上品牌以免混用。在边界验证一次，下游代码信赖类型。

```ts
type AgentId = string & { readonly __brand: "AgentId" };

function isAgentId(input: string): input is AgentId {
  return isUUID(input);
}

function parseAgentId(input: string): AgentId {
  if (!isAgentId(input)) throw new Error(`Invalid agent id: ${input}`);
  return input;
}

function focusAgent(id: AgentId): void {
  /* input is trusted */
}
```

沿用 `readonly __brand: 'X'` 形式，避免另立约定。

## 可辨识联合

用字面量字段区分各变体。所有变体共享字段名，各自使用唯一的值，因此无法表示互相矛盾的组合。

```ts
// Don't. Boolean + optionals lets contradictory states exist.
type DiffState = { loading: boolean; diff?: GitDiff; error?: string };

// Do. Only valid states exist.
type DiffState =
  | { kind: "loading" }
  | { kind: "ready"; diff: GitDiff }
  | { kind: "error"; error: string };
```

从 `kind`、`type`、`tag` 等名称中选一个，并保持一致。

## 构造式建模

用各自合法的部件组成类型，避免在宽松类型上反复附加运行时检查。

用可变长度元组表示非空。

```ts
type NonEmpty<T> = [T, ...T[]];

// Don't: T[] plus a length check every caller must repeat
function pickWinner(entries: string[]): string {
  if (entries.length === 0) throw new Error("no entries");
  return entries[Math.floor(Math.random() * entries.length)];
}

// Do: an empty value of the type can't exist
function pickWinner(entries: NonEmpty<string>): string {
  return entries[Math.floor(Math.random() * entries.length)];
}
```

拿到普通 `T[]` 时，通过类型守卫收窄一次，再用类型传递这个事实。

```ts
const isNonEmpty = <T>(arr: T[]): arr is NonEmpty<T> => arr.length > 0;
```

用成对的元素表示偶数长度。

```ts
type Pairs<T> = [T, T][];
```

用起点加持续时长表示时间区间。

```ts
// Don't: a comment holds the invariant
type UncheckedTimeRange = { start: Date; end: Date }; // start <= end

type NonNegativeMs = number & { readonly __brand: "NonNegativeMs" };

function parseNonNegativeMs(input: number): NonNegativeMs {
  if (!Number.isFinite(input) || input < 0) {
    throw new RangeError("Duration must be a finite non-negative number");
  }
  return input as NonNegativeMs;
}

type TimeRange = { start: Date; durationMs: NonNegativeMs };
```

在边界用 `parseNonNegativeMs` 验证原始时长。`TimeRange` 只接受验证过的时长，需要终点时再用 `rangeEnd()` 等辅助函数计算。

## 支持全定义操作的最简类型

按需收紧类型。所有操作在 `T[]` 上都有定义时，保留 `T[]`。

```ts
const sum = (xs: number[]) => xs.reduce((a, b) => a + b, 0); // [] is 0, fine
```

当宽松类型迫使调用处对编译器隐瞒事实时，才收紧类型。`!`、`arr[0] as T` 和「不该发生」的抛错都是信号。

```ts
// Don't: partiality smuggled past the compiler
function newestSession(sessions: Session[]): Session {
  return sessions.at(0)!;
}

// Do: strengthen the input; the assertion disappears
function newestSession(sessions: NonEmpty<Session>): Session {
  return sessions[0];
}
```

将返回值放宽为 `Session | undefined` 也是一种对所有输入都有定义的签名。

## 优先使用 `unknown`

外部数据始终用 `unknown`，使用前先收窄类型。

```ts
// Don't
function handle(input: any) {
  return input.foo.bar;
}

// Do
function handle(input: unknown) {
  if (typeof input === "object" && input !== null && "foo" in input) {
    // narrowed; compiler verifies access
  }
}
```

外部来源包括 RPC 载荷、`JSON.parse`、`postMessage`、IPC、文件内容、环境变量和数据库结果。

## 优先用 schema，按需手写守卫

为外部数据逐字段编写类型守卫之前，先查仓库已有的运行时 schema 库和 schema。让一个 schema 负责验证，再由它推导 TypeScript 类型。避免维护可能各自偏离的 schema、重复接口和守卫。

```ts
import { z } from "zod";

const UserSchema = z.object({
  id: z.string().uuid(),
  role: z.enum(["admin", "member"]),
});

type User = z.infer<typeof UserSchema>;

function parseUser(input: unknown): User {
  return UserSchema.parse(input);
}
```

预期会处理失败分支时，使用 `safeParse`。如果仓库用其他 schema 库，就用对应的推导工具。单个守卫无需引入新的 schema 依赖。优先采用代码库已验证过的 schema 系统。

## 限制 `as` 断言

每个 `as` 都可能造成运行时崩溃。由类型系统验证主张后，才执行断言。

```ts
import { z } from "zod";

// Don't
const user = data as User;

// Don't
function isUser(data: unknown): data is User {
  return typeof data === "object" && data !== null && "id" in data;
}

// Do
const userSchema = z.object({ id: z.string(), name: z.string() });
type User = z.infer<typeof userSchema>;

function parseUser(data: unknown): User {
  return userSchema.parse(data);
}
```

如果已有类型，就给验证器标注它所证明的类型。这样，验证器证明的信息不足时，编译器会拒绝。删去下面对象里的 `name`，赋值就无法编译。

```ts
type User = { id: string; name: string };

const userSchema: z.ZodType<User> = z.object({ id: z.string(), name: z.string() });
```

从现有代码移除 `as` 时，先找出 TypeScript 无法推导的原因。

- 缺少可辨识字段。添加它，并改用可辨识联合。
- 来源类型过宽，例如 `Record<string, unknown>`。先收窄类型。
- 边界没有类型。用定义该结构的 schema 解析。只有没有 schema 时才新增。
- 确实无法直接表达。用品牌类型或 `satisfies`。

## 类型收窄优先级

按优先顺序选择。

1. **按可辨识字段写 switch 或 if。** 编译器自动收窄。
2. **`in` 运算符。** `"key" in obj` 收窄到包含该键的变体。
3. **`typeof` 或 `instanceof`。** 用于原始值和类实例。
4. **自定义类型守卫。** 上述方式不足时使用。
5. **`as` 断言。** 验证后才使用。

```ts
function area(s: Shape): number {
  if ("radius" in s) return Math.PI * s.radius ** 2; // narrowed to circle
  return s.width * s.height; // narrowed to rect
}
```

## 类型守卫

守卫必须验证它声称的事实。写了一个谎报事实的守卫比直接用 `as` 更糟。

```ts
function isCircle(s: Shape): s is Shape & { kind: "circle" } {
  return s.kind === "circle";
}
```

能用可辨识字段收窄时优先使用。

## 穷尽性检查

在默认分支中，将待穷尽的值赋给类型为 `never` 的局部变量。

```ts
// Value-returning switch
function area(s: Shape): number {
  switch (s.kind) {
    case "circle":
      return Math.PI * s.radius ** 2;
    case "rect":
      return s.width * s.height;
    default: {
      const _exhaustive: never = s;
      return _exhaustive;
    }
  }
}

// Void switch
function handle(s: Shape): void {
  switch (s.kind) {
    case "circle":
      drawCircle(s);
      break;
    case "rect":
      drawRect(s);
      break;
    default: {
      const _exhaustive: never = s;
      void _exhaustive;
    }
  }
}
```

有返回值的 switch 用 return 形式，只执行语句的 switch 用 void 形式。

## 优先选择 `satisfies`

`satisfies` 检查类型且保留字面量类型。

```ts
// Don't. Widens, loses literal types.
const config = { theme: "dark", cols: 3 } as Config;

// Do. Validates AND preserves literal types.
const config = { theme: "dark", cols: 3 } satisfies Config;
// config.theme is "dark" (literal), not string
```

## 边界验证

数据进入时验证一次，边界内信赖类型。参见 **boundary-discipline** 原则技能。

- **传输格式**（proto、JSON-RPC）。解析时用 `ignoreUnknownFields`，让前向兼容的变更可以被旧客户端接受。
- **持久化 JSON。** 使用带版本的整体数据，解析处用 try/catch。
- **只在边界验证。** 调用链深处避免重复验证。

## 从 schema 派生类型

如果 `.proto`、OpenAPI 规约、GraphQL schema 或数据库迁移已经定义了结构，就用它生成的类型派生所需形状，避免重复定义。

```ts
// Don't. Duplicate shape, drifts when the schema changes.
type CheckSummary = {
  totalCount: number;
  checks: { name: string; status: string }[];
};
function renderChecks(s: CheckSummary) {
  /* ... */
}

// Do. Derive from the generated schema type.
import type { ChecksMessage } from "<generated module>";
function renderChecks(s: Pick<ChecksMessage, "totalCount" | "checks">) {
  /* ... */
}
```

编写新接口之前考虑 `Pick`、`Omit`、`Parameters`、`ReturnType`、`Awaited` 和 `typeof`。

## 对象参数

```ts
// Don't. Swap two args, still compiles.
openFile(uri, {
  startLineNumber: 10,
  startColumn: 1,
  endLineNumber: 10,
  endColumn: 1,
});

// Do. Order-independent, self-documenting.
openFile({
  uri,
  selection: {
    startLineNumber: 10,
    startColumn: 1,
    endLineNumber: 10,
    endColumn: 1,
  },
});
```

热路径可跳过此规则，例如逐帧渲染、词法分析、解析和其他对分配开销敏感的紧密循环。
