---
name: game-ui-pattern
description: UI design system - full-screen menus, battle HUD layout, color palette, typography, and tooltip patterns
---

## 全屏界面样式（主菜单 / 国家选择 / 等）

### 布局
- 根节点: `CanvasLayer`
- 背景色: `Color(0.0745, 0.0863, 0.1373, 1)` / `#131623`
- 内容居中排列, 标题约在 20% 垂直位置, 按钮组在标题下方

### 标题样式
- 主标题: 52px, 白色, `SystemFont` font_weight=700（代码中设置）
- 副标题: 14px, `Color(0.55, 0.63, 0.78, 1)` / `#8CA1C6`, letter_spacing=4
- 分隔线: 160x1px, `Color(0.55, 0.63, 0.78, 0.2)`, 居中

### 菜单按钮（260×48）
- **Normal**: bg=`rgba(255,255,255,0.03)` border=`rgba(255,255,255,0.1)` corner=4
- **Hover**: bg=`rgba(255,255,255,0.08)` border=`rgba(255,255,255,0.2)` corner=4
- **Disabled**: bg=`rgba(255,255,255,0.015)` border=`rgba(255,255,255,0.05)` corner=4
- 内部: LabelCN（16px 粗体白, 居中）+ LabelEN（10px `#7A8DB1`, 居中）
- LabelCN/LabelEN 作为 Button 的直接子节点, `layout_mode=1` 锚点填充

### 弹窗面板
- 背景: `Color(0.039, 0.039, 0.098, 0.95)` / `#0a0a19` at 95%
- 边框: 1px `rgba(255,255,255,0.12)` 圆角10px
- 内边距: 14-16px

### 步骤指示器
- Dots: 8x8px, 高亮 `#77aaff`, 非高亮 `rgba(255,255,255,0.1)`

### tscn 注意事项
- Color 必须 4 参数: `Color(r, g, b, a)` — Steam 版不支持 3 参数简写
- StyleBox 用 sub_resource 定义, 不写在代码中
- 粗体用 `_bold_font()` 在 gd 脚本中设置, 不在 tscn 用 SystemFont sub_resource
- ext_resource 必须写在 sub_resource 之前，否则解析失败
- ext_resource 的 uid 必须与 .gd.uid 文件一致，否则编辑器保存时可能删除脚本引用 → 优先省略 uid 用文本路径
- 所有节点需要 unique_id（编辑器自动生成），缺少 unique_id 时部分 Steam 版解析失败
- 按钮内子标签 `unique_name_in_owner` 不可同名; 用 `btn.get_node("LabelCN")` 访问

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
- 全屏背景: `#131623`
- 面板背景: `#0a0a19` 95% alpha
- 己方: `#44aa88` | 敌方: `#cc4444` | 高亮: `#77aaff`
- 按钮英文: `#7A8DB1` | 版本号: `#3F517A`
- 士气色: 溃败#844 / 混乱#864 / 正常#484 / 高昂#884 / 狂热#c80

## Font Sizes (所有值)
- 主标题: 52px / 界面标题: 26px / 弹窗标题: 14px
- 按钮中文: 16px / 按钮英文: 10px / 副标题: 14px
- 区块12px / 正文11px / 辅助10px / 标注9px / 极小8px

## Tooltip
- 用 `_add_tooltip(control, text)` 添加自定义tooltip
- `mouse_entered`/`mouse_exited` 控制显示
- `position: fixed` 方式定位（父容器外），防屏幕溢出
