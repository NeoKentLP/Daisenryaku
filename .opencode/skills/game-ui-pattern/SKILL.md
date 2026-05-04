---
name: game-ui-pattern
description: UI design system - battle_main_v7 layout, color palette, typography, and tooltip patterns
---

## Battle Main UI Layout (battle_main_v7)
Bottom horizontal strip (left → right):
```
[部队信息模块] → [Buff行(上) + 按钮行(下)] → [地形横排]  … [结束回合(右下角独立)]
```

- **部队信息**: 图标50×66 + 名称 + 士气条(90px) + 属性行 + HP网格(5×2) + 武器标签
- **Buff行**: 压制/ZOC/士气状态图标，横排
- **按钮行**: 待机/射击/突击/战壕/布雷/排雷/补给
- **地形横排**: 名称 | 移X | 防X | 命中X | [CQB] [补给站]
- **结束回合**: 56×56 右下角
- **顶部栏**: 左:大战略|回合X|阶段 / 右:货币|补给|日志|储备库

## Squad Detail Popup (squad_detail_v7)
- 点击部队图标/名称打开
- 左栏: 属性 + 战况修正(汇总+因素列表) + 部队技能 + 成员HP网格(5×2) + 武器分组
- 右栏: 指挥官(头像48×64竖版 + 名称 + 等级 + 技能竖向排列)

## Color Palette
- 面板: `#0a0a19` 95% alpha
- 己方: `#44aa88` | 敌方: `#cc4444` | 高亮: `#77aaff`
- 士气色: 溃败#844 / 混乱#864 / 正常#484 / 高昂#884 / 狂热#c80

## Font Sizes
- 标题14-16px / 区块12px / 正文11px / 辅助10px / 标注9px / 极小8px

## Tooltip
- 用 `_add_tooltip(control, text)` 添加自定义tooltip
- `mouse_entered`/`mouse_exited` 控制显示
- `position: fixed` 方式定位（父容器外），防屏幕溢出
