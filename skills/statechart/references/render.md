# 渲染状态图

用 npm 包 `pele@1.9.0` 渲染每个要展示的 `.mmd` 文件，并把 SVG 交给用户。在仓库外安装一次 Pele。各 SVG 保存到相应 `.mmd` 所在目录，使用相同的主文件名。API 文档见 <https://pele.run/api>。调用 `render` 时传入选项 `{ limit: 1_000_000, outputLimit: 8_000_000, maxEdges: 10_000 }`。Pele 的默认上限可能容不下 500 个状态。若 Pele 抛出 `PeleError`，把 Mermaid 文本及错误展示给用户。

## 配色

Pele 忽略 Mermaid 的 `theme` 和 `themeVariables`。在 `.pele` 上设置它的 `--pele-*` CSS 变量。变量见 <https://pele.run/theming>。命令给各状态添加所属分组的颜色类，例如 `class sN teal`。违反规则的状态标为 `class sN breaks` 或 `class sN mayBreak`。通往缺陷的最短路径上的状态标为 `class sN bugPath`。PROPERTY 反例中无限重复的各状态标为 `class sN repeats`。Pele 把这些类写在状态节点上，用 CSS 为它们设色。

`.mmd` 文件为 `breaks` 和 `mayBreak` 提供 `classDef` 行，因此任意 Mermaid 查看器都能显示缺陷标记。分组颜色、`bugPath` 和 `repeats` 没有 `classDef`。Pele 将各 `classDef` 的颜色写为节点的 `style` 属性，优先级高于普通 CSS 规则。因此下列标记规则用 `!important`。缺少它时，深色主题仍会沿用浅色标记。缺陷标记设置填充和文字，`bugPath` 与 `repeats` 设置边框。把标记规则放在分组颜色后面，让标记覆盖分组颜色。

下列建议颜色沿用旧版技能的配色。把它们放在每个 SVG 开头的 `<style>` 元素中，SVG 就能跟随查看器的浅色或深色设置。

```css
.pele {
  --pele-bg: #ffffff;
  --pele-fg: #1c1c1c;
  --pele-muted: #656565;
  --pele-line: #808080;
  --pele-surface: #fcfcfc;
  --pele-surface-alt: #f1f1f1;
  --pele-border: #c9c9c9;
}
.pele .blue rect { fill: #c3e0ff; }
.pele .orange rect { fill: #f0d3bf; }
.pele .purple rect { fill: #e3d5ff; }
.pele .yellow rect { fill: #f0dcbf; }
.pele .teal rect { fill: #bfe3df; }
.pele .tan rect { fill: #e5d9ce; }
.pele .pink rect { fill: #ffcbe6; }
.pele .breaks rect {
  fill: #ffecee !important;
  stroke: #e72e3b !important;
  stroke-width: 2.5px !important;
}
.pele .breaks text {
  fill: #cd2834 !important;
}
.pele .mayBreak rect {
  fill: #fff3e6 !important;
  stroke: #e8730c !important;
  stroke-width: 2.5px !important;
}
.pele .mayBreak text {
  fill: #b85a06 !important;
}
.pele .bugPath rect {
  stroke: #1680f3 !important;
  stroke-width: 2.5px !important;
}
.pele .repeats rect {
  stroke: #9b35d6 !important;
  stroke-width: 2.5px !important;
  stroke-dasharray: 6 3;
}
@media (prefers-color-scheme: dark) {
  .pele {
    --pele-bg: #1f1f1f;
    --pele-fg: #f5f5f5;
    --pele-muted: #acacac;
    --pele-line: #939393;
    --pele-surface: #121212;
    --pele-surface-alt: #2c2c2c;
    --pele-border: #4e4e4e;
  }
  .pele .blue rect { fill: #1b3857; }
  .pele .orange rect { fill: #573117; }
  .pele .purple rect { fill: #3c2e57; }
  .pele .yellow rect { fill: #573d17; }
  .pele .teal rect { fill: #174641; }
  .pele .tan rect { fill: #3d3127; }
  .pele .pink rect { fill: #57233e; }
  .pele .breaks rect {
    fill: #2e2021 !important;
    stroke: #cf2b35 !important;
  }
  .pele .breaks text {
    fill: #ff6463 !important;
  }
  .pele .mayBreak rect {
    fill: #2e2619 !important;
    stroke: #d0700f !important;
  }
  .pele .mayBreak text {
    fill: #ffa257 !important;
  }
  .pele .bugPath rect {
    stroke: #116dd2 !important;
  }
  .pele .repeats rect {
    stroke: #9a3fcf !important;
  }
}
```
