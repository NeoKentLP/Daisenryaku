# 大战略 — 二战战棋游戏开发文档

> 引擎: Godot 4.6.2.stable.steam
> 语言: GDScript
> 项目路径: D:\项目\godot\大战略01

---

## 目录

1. [项目概述](#1-项目概述)
2. [游戏设计](#2-游戏设计)
3. [项目结构](#3-项目结构)
4. [核心架构](#4-核心架构)
5. [数据定义](#5-数据定义)
6. [游戏流程](#6-游戏流程)
7. [UI 技术方案](#7-ui-技术方案)
8. [美术资源工作流](#8-美术资源工作流)
9. [开发规范与陷阱](#9-开发规范与陷阱)
10. [测试指南](#10-测试指南)
11. [第一阶段开发计划](#11-第一阶段开发计划)
12. [变更记录](#12-变更记录)

---

## 1. 项目概述

### 1.1 游戏定位

二战背景的六边形格战棋游戏，俯视视角，排级规模战斗。

### 1.2 核心特性

| 特性 | 当前状态 |
|------|---------|
| 六边形网格地图 (15×10) | ✅ 完成 |
| 7种地形 (平地/森林/山地/河流/道路/城市/指挥部) | ✅ 完成 |
| 回合制战斗 (我方→敌方) | ✅ 完成 |
| 移动→攻击/待机流程 | ✅ 完成 |
| 基础AI (就近攻击) | ✅ 完成 |
| 镜头移动 (键盘/拖拽/缩放) | ✅ 完成 |
| 单位E标识 (行动完成) | ✅ 完成 |
| 3层战斗系统 (命中→穿透→伤害) | ✅ 完成 |
| 兵种→部队→成员三层结构 | ✅ 完成 |
| AP行动点系统 (3AP) | ✅ 完成 |
| 士气/状态系统 (0-100, 5状态) | ✅ 完成 |
| ZOC控制区域 | ✅ 完成 |
| CQB突击 (3AP同时开火) | ✅ 完成 |
| 工兵系统 (战壕/布雷/排雷) | ✅ 完成 |
| 补给系统 (弹药/燃料) | ✅ 完成 |
| 指挥官池骨架 | ✅ 完成 (基础生成/任命) |
| 移动类型系统 (步行/轮式/履带等) | ✅ 完成 |
| 等级系统 (新兵→王牌) | ⬜ 设计完成，未接入 |
| 世界地图 | ✅ 完成 (占位场景) |
| 经济/货币系统 | ⬜ 设计完成 |
| 关卡系统/战役 | ⬜ 设计完成 |
| 完整UI流程 (国家选择/指挥官创建/部署等) | ⬜ 待实现 (HTML原型完成) |
| 第一关数据 (序章·边境冲突) | ⬜ 待配置 |

> 详细设计见 `docs/DESIGN_0.1.md`

---

## 2. 游戏设计

### 2.1 设定

- **题材**: 二战现代军事
- **视角**: 俯视 (Top-down)
- **地图**: 六边形网格 (Hex, Pointy-top)
- **战斗规模**: 排级 (10-30单位)
- **战斗模式**: 回合制 (玩家全动 → 敌方全动)
- **三层结构**: 兵种(模板) → 部队(战场实体) → 成员(个体)

> 完整战斗系统设计见 `docs/DESIGN_0.1.md`

### 2.2 胜利条件

多种胜利条件 (全灭敌军/占领据点/坚守阵地/突破防线/摧毁目标/护送撤离)，当前仅实现全灭判定。

### 2.3 操作方式

| 操作 | 功能 |
|------|------|
| 鼠标左键点击单位 | 选中己方单位 |
| 鼠标左键点击绿色格子 | 移动 |
| 鼠标左键点击红色格子 | 攻击 |
| 鼠标滚轮 | 缩放镜头 (0.5x~3x) |
| 鼠标中键拖拽 | 平移镜头 |
| WASD / 方向键 | 键盘平移 |
| 「结束回合」按钮 | 结束玩家回合 |

### 2.4 回合流程

```
己方回合:
  [阶段1·回合开始]  条件增援部署→压制恢复判定→溃败timer-1→
                     士气恢复+5→CD-1→重置AP为3→重置反应次数
  [阶段2·行动阶段]  玩家依次操作各部队（移动/攻击/警戒/固守/补给等）
  [阶段3·回合结束]  触发"回合末"效果→标记已行动→传递回合给对手

AI回合:
  [阶段1-3] 同己方回合，AI自动执行
```

---

## 3. 项目结构

```
大战略01/
├── project.godot                        # 项目配置 (UTF-8无BOM)
├── icon.svg                             # 项目图标
│
├── autoload/
│   ├── game_manager.gd                  # [autoload] 全局状态
│   └── (HexUtil 在 scripts/core/ 作为 autoload)
│
├── scripts/
│   ├── core/
│   │   ├── hex_util.gd                  # [autoload] 六边形数学
│   │   ├── squad.gd                     # 部队类 (Node2D, 管理成员列表)
│   │   ├── member.gd                    # 成员类 (RefCounted, HP/武器)
│   │   ├── weapon_data.gd              # 武器数据
│   │   ├── game_enums.gd               # 枚举常量
│   │   └── unit_type_data.gd           # 兵种模板数据
│   ├── map/
│   │   └── hex_map.gd                   # 地图控制器 (Node2D)
│   ├── units/
│   │   └── unit.gd                      # [旧] 旧单位类 (待废弃)
│   ├── battle/
│   │   ├── main_controller.gd           # 主控器 (输入/流程, Node2D)
│   │   └── battle_manager.gd            # 战斗系统 (Node)
│   ├── ai/
│   │   └── ai_controller.gd             # 敌方AI (Node)
│   ├── commander/
│   │   └── commander.gd                 # 指挥官类 (RefCounted)
│   ├── ui/
│   │   ├── ui_manager.gd                # UI管理器 (CanvasLayer)
│   │   ├── ui_style.gd                  # UI工具样式集 (RefCounted)
│   │   └── squad_detail.gd              # 部队详情弹窗 (Panel)
│   ├── deployment/                      # ⬜ 待创建
│   │   └── deployment_controller.gd     # ⬜ 部署控制
│   └── world/                           # ⬜ 待创建
│       └── world_controller.gd          # ⬜ 世界地图控制
│
├── resources/
│   ├── terrain/
│   │   └── terrain_data.gd              # 地形定义 (11种)
│   ├── units/
│   │   └── unit_data.gd                 # 旧兵种定义
│   └── levels/                          # ⬜ 关卡数据
│
├── scenes/
│   ├── battle/
│   │   └── main_scene.tscn              # 战斗主场景
│   ├── world/
│   │   └── world_map.tscn               # 世界地图场景
│   ├── deployment/                      # ⬜ 部署场景
│   └── ui/                              # ⬜ UI场景 (逐步创建)
│       ├── main_menu.tscn               # ⬜ 主菜单
│       ├── nation_select.tscn           # ⬜ 国家选择
│       ├── commander_create.tscn        # ⬜ 指挥官创建
│       ├── deployment.tscn              # ⬜ 部署界面
│       ├── combat_preview.tscn          # ⬜ 战斗预览
│       ├── combat_log.tscn              # ⬜ 战斗日志
│       ├── victory.tscn                 # ⬜ 胜利结算
│       └── battle_hud.tscn              # ⬜ 战场HUD
│
├── assets/
│   ├── sprites/                         # ⬜ 精灵图 (美术素材)
│   ├── tiles/                           # ⬜ 地形瓦片
│   ├── portraits/                       # ⬜ 指挥官头像
│   └── icons/                           # ⬜ UI图标
│
├── data/
│   ├── germany/                         # 德国编制树数据
│   ├── soviet/                          # 苏联编制树数据
│   ├── skills.json                      # 技能定义
│   ├── _gen_all.py                     # 数据生成脚本
│   ├── _update_pen.py                  # PEN数据更新
│   └── _verify_pen.py                  # PEN数据验证
│
├── tests/
│   ├── test_runner.gd                   # 测试运行器
│   ├── test_scene.tscn                  # 测试场景
│   ├── test_smoke.gd / .tscn           # 烟雾测试
│   ├── test_full.gd / .tscn            # 全量测试
│   └── test_minimal.gd / .tscn         # 最小测试
│
├── ui_prototypes/                       # HTML UI原型
│   ├── index.html                       # 导航入口
│   ├── shared.css                       # 共享CSS
│   ├── UI_STYLE.md                      # UI风格指南
│   ├── main_menu/                       # 主菜单原型
│   ├── new_game/                        # 新游戏原型
│   ├── battle/                          # 战场原型
│   └── deployment/                      # 部署原型
│
├── resources/
│   └── units/
│       └── unit_data.gd                 # 兵种数据
│
├── docs/
│   ├── DESIGN_0.1.md                    # 完整设计规格书 (3507行)
│   ├── ROADMAP.md                       # 开发路线图
│   ├── DEVELOPMENT.md                   # 本文件
│   ├── SESSION_SUMMARY.md              # 会话进度摘要
│   ├── ISSUES.md                        # 问题备忘录
│   └── DESIGN_METHODOLOGY.md            # 设计方法论
│
├── addons/                              # Godot编辑器插件
│   ├── auto_reload/
│   ├── godot_mcp_editor/
│   └── godot_mcp_runtime/
│
└── 功能框架.xmind                       # 功能思维导图
```

---

## 4. 核心架构

### 4.1 autoload 列表

| 名称 | 文件 | 职责 |
|------|------|------|
| `GameManager` | `autoload/game_manager.gd` | 全局状态、部队注册、回合管理、指挥点、补给池、指挥官池 |
| `HexUtil` | `scripts/core/hex_util.gd` | 六边形数学工具 (坐标转换/寻路/距离) |

**注意**: 不使用 `class_name`。所有类型通过 `load()` / `preload()` 获取。

### 4.2 模块职责

| 模块 | 文件 | 核心职责 |
|------|------|---------|
| hex_map | `scripts/map/hex_map.gd` | 地图生成、地形数据、可达范围、攻击范围、高亮、ZOC检测、overlay层 |
| squad | `scripts/core/squad.gd` | 部队属性、视觉(颜色/文字/E标识)、移动、士气/压制、补给、战斗状态 |
| member | `scripts/core/member.gd` | 成员个体HP/武器/属性、弹药管理 |
| battle_manager | `scripts/battle/battle_manager.gd` | 战斗结算(命中→穿透→伤害)、反击、CQB、缴获 |
| ai_controller | `scripts/ai/ai_controller.gd` | 敌方AI: 就近攻击逻辑、ZOC感知 |
| main_controller | `scripts/battle/main_controller.gd` | 输入处理、选中→移动→攻击流程、工兵操作、胜利条件 |
| ui_manager | `scripts/ui/ui_manager.gd` | 所有UI面板、信息显示、行动按钮、日志、储备库 |
| commander | `scripts/commander/commander.gd` | 指挥官类: 生成、技能、经验升级 |
| ui_style | `scripts/ui/ui_style.gd` | UI工具样式集: 色彩/字体/面板统一风格 |

### 4.3 主场景结构 (战斗)

```
Main (Node2D) - main_controller.gd
├── HexMap (Node2D) - hex_map.gd
│   ├── Camera2D
│   ├── Tile_0_0 ~ Tile_14_9 (Polygon2D, 地形色块)
│   ├── PlayerSquad_* (Squad, Node2D)
│   │   ├── Polygon2D (部队色块)
│   │   ├── Label (部队名+人数)
│   │   └── Label ("E" 标识)
│   └── EnemySquad_* (Squad, Node2D)
│       └── ...
├── BattleManager (Node) - battle_manager.gd
├── AI (Node) - ai_controller.gd
└── UIManager (CanvasLayer) - ui_manager.gd
```

---

## 5. 数据定义

### 5.1 地形表 (11种)

| ID | 名称 | 移动消耗 | 防御加成 | CQB |
|----|------|---------|---------|-----|
| plain | 平地 | 1 | 0 | ❌ |
| forest | 森林 | 2 | 2 | ✅ |
| mountain | 山地 | 3 | 4 | ❌ |
| river | 河流 | 2 | 0 | ❌ |
| road | 道路 | 1 | 0 | ❌ |
| city | 城市 | 1 | 3 | ✅ |
| hq | 指挥部 | 1 | 3 | ❌ |
| factory | 工厂 | 1 | 2 | ❌ |
| ruins | 废墟 | 2 | 3 | ✅ |
| trench | 战壕 | 1 | 4 | ✅ |
| bunker | 堡垒 | 1 | 6 | ✅ |
| minefield | 雷区 | 1 | 0 | ❌ |

定义文件: `resources/terrain/terrain_data.gd`

### 5.2 兵种模板 (7种)

| ID | 名称 | HP | 攻击 | 防御 | 移动 | 射程 | 消耗 |
|----|------|----|------|------|------|------|------|
| infantry | 步兵 | 10 | 2 | 1 | 3 | 1 | 50 |
| mechanized | 机械化步兵 | 12 | 3 | 2 | 4 | 1 | 80 |
| tank | 坦克 | 15 | 5 | 3 | 4 | 1 | 150 |
| artillery | 火炮 | 8 | 4 | 1 | 2 | 3 | 200 |
| recon | 侦察车 | 8 | 1 | 1 | 6 | 1 | 70 |
| anti_air | 防空车 | 12 | 4 | 2 | 3 | 2 | 120 |
| transport | 运输车 | 6 | 0 | 1 | 5 | 0 | 40 |

定义文件: `resources/units/unit_data.gd`

> **注意**: 当前 `unit_data.gd` 是旧版单层数据。真正的三层数据（成员编制、武器分配）在 `scripts/core/unit_type_data.gd` 中定义。

---

## 6. 游戏流程

### 6.1 完整UI流程 (新游戏→第一关结束)

```
主菜单 → [新游戏]
         → [国家选择] 轮播选国家
         → [指挥官创建] 4卡横排, 可重掷/编成/改名
         → [部署] 左栏部队列表→选中→操作按钮→点地图放置
         → [战场主界面]
              ├→ [部队详情] 点击己方部队
              ├→ [战斗预览] 选动作→点目标→期望值
              │   → [战斗过程] 确认→自动结算
              │       → [战斗详情] 战斗日志弹窗
              └→ [胜利结算] 达成胜利条件
                  → 返回基地 (后续设计)
```

### 6.2 战场操作流程

```
选中己方部队 → 显示移动范围(绿色) + 攻击范围(红色)
  ├→ 点击绿色格子 → 移动(消耗1AP)
  │   → 显示攻击范围 → 点击红色格子 → 攻击(消耗2AP)
  │   → 或点击[待机] → 结束行动
  ├→ 点击红色格子 → 直接攻击(消耗2AP)
  ├→ 点击[突击] → 选择CQB目标(消耗3AP)
  ├→ 点击[补给] → 补充弹药(消耗1AP)
  └→ 右键/ESC → 取消选中
```

---

## 7. UI 技术方案

### 7.1 方案选择: Scene-Based UI

所有UI界面使用 **.tscn 场景文件**（Control节点树）实现，而非纯代码创建。

**优势:**
| 对比 | 纯代码 (.new()) | Scene式 (.tscn) |
|------|----------------|-----------------|
| 编辑器中可见 | ❌ | ✅ |
| 拖拽调整位置 | ❌ | ✅ |
| 实时预览颜色/字号 | ❌ | ✅ |
| 对美术/策划友好 | ❌ | ✅ |

**工作流:**
1. 我创建 `.tscn` 文件（Control节点层级）
2. 你在 Godot 编辑器中打开 `.tscn`
3. 拖拽/调整位置/颜色/大小 → 保存 → 立即生效
4. 运行游戏 → 场景被加载 → 显示调整后的UI

### 7.2 场景文件组织

```
scenes/ui/
├── main_menu.tscn           # 主菜单 (全屏)
├── nation_select.tscn       # 国家选择 (弹窗)
├── commander_create.tscn    # 指挥官创建 (弹窗)
├── deployment.tscn          # 部署界面 (全屏)
├── combat_preview.tscn      # 战斗预览 (弹窗)
├── combat_log.tscn          # 战斗日志 (弹窗)
├── victory.tscn             # 胜利结算 (弹窗)
└── battle_hud.tscn          # 战场HUD (底部栏+顶部栏)
```

### 7.3 代码引用方式

```gdscript
# 加载场景
@onready var preview_scene = preload("res://scenes/ui/combat_preview.tscn")

# 实例化
var preview = preview_scene.instantiate()
add_child(preview)

# 引用场景中的节点 (通过 @onready 和 % 唯一名称)
@onready var squad_name_label = %SquadNameLabel
@onready var attack_btn = %AttackBtn
```

### 7.4 迁移策略 (渐进式)

- **新界面**（主菜单、国家选择、指挥官创建、部署、战斗预览、胜利结算）→ 全部用 `.tscn`
- **现有战场UI**（`ui_manager.gd` 的1171行代码创建）→ 分阶段迁移:
  - 第一步: 弹窗类 (战斗预览/日志/胜利结算) 拆为独立 `.tscn`
  - 第二步: 底部栏 (Squad Module / Action Buttons) 拆为独立 `.tscn`
  - 第三步: 顶部栏 + HUD 组件 拆为独立 `.tscn`

### 7.5 布局原则

| 原则 | 说明 |
|------|------|
| **锚点布局** | 使用 Control 节点的 anchor 实现分辨率自适应 |
| **Container** | 用 HBoxContainer/VBoxContainer 做弹性布局，避免写死坐标 |
| **Theme** | 统一引用 `.theme` 资源文件，定义字体/颜色/面板样式 |
| **ui_style.gd** | 已有的颜色/字体常量 (`COLOR_PANEL_BG`, `COLOR_FRIENDLY` 等) 继续保持引用 |
| **Size Flags** | 用 `size_flags_horizontal/vertical` 控制伸缩行为 |

---

## 8. 美术资源工作流

### 8.1 资源分类

| 类别 | 我能生成的 | 你需要提供的 | 格式 | 存放位置 |
|------|-----------|------------|------|---------|
| **地形瓦片** | 纯色 Polygon2D（当前方案） | 六边形纹理贴图 | PNG 256×256 | `assets/tiles/` |
| **部队图标** | 简单几何形+文字 | 兵种Sprite图 | PNG 64×64 | `assets/sprites/` |
| **UI面板/按钮** | 纯色圆角 Panel (StyleBoxFlat) | 背景图/按钮纹理/9-patch | PNG | `assets/ui/` |
| **指挥官头像** | ❌ 无法生成 | 头像图片（统一尺寸） | PNG 80×120 | `assets/portraits/` |
| **战场装饰** | 纯色背景 | 树木/建筑Sprite | PNG | `assets/env/` |
| **图标** | 文字+圆圈 | 精致的图标集 | PNG 32×32 | `assets/icons/` |

### 8.2 分阶段美术策略

| 阶段 | 内容 | 依赖 |
|------|------|------|
| **第一阶段 (当前)** | 纯色几何图形 + 文字标签（无需任何美术资源） | 无 |
| **第二阶段** | 你提供少量核心兵种图（坦克、步兵、火炮、侦察车各1张），我替换到Squad显示 | `assets/sprites/` |
| **第三阶段** | 全面替换UI背景、地形纹理、头像 | `assets/tiles/`, `assets/portraits/`, `assets/icons/` |

### 8.3 导入流程

```
1. 你准备好图片（PNG格式，透明背景）
2. 放入 assets/ 对应子目录
3. Godot 自动生成 .png.import 文件
4. 代码中引用: preload("res://assets/sprites/tank.png")
5. 或你在 .tscn 编辑器中直接拖入 Sprite2D 的 Texture 属性
```

### 8.4 格式规范

| 规范 | 要求 |
|------|------|
| 格式 | PNG（Godot原生支持最好） |
| 背景 | 透明 |
| 命名 | 英文小写 + 下划线 (如 `tank_pz4.png`) |
| 尺寸 | 基础尺寸 + `@2x` 备用 (如 `tank.png` 64px + `tank@2x.png` 128px) |
| 编码 | UTF-8 无 BOM 文件名 |

---

## 9. 开发规范与陷阱

### 9.1 GDScript 语法限制 (Godot 4.6.2 Steam 版)

| 语法 | 状态 | 替代方案 |
|------|------|---------|
| `var x := func_call()` | ❌ | `var x = func_call()` |
| `class_name Foo` | ❌ | autoload / load() |
| `script_ref.static_func()` | ❌ | autoload 普通方法 |
| `"s" * N` | ❌ | `"s".repeat(N)` |
| `func(x: Type)` 自定义类型 | ❌ | 省略类型注解 |
| `const X = func_call()` | ❌ | `static var` + `_init()` |
| `preload(...).static_func()` | ❌ | autoload 单例 |

完整列表见 `docs/ISSUES.md` 第 1-4、7 节。

### 9.2 文件编码

- 所有 `.gd` / `.tscn` 文件使用 **UTF-8 无 BOM**
- 不要用 PowerShell `Set-Content` 操作含中文的文件
- 用 `.NET` 方法: `[System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))`

### 9.3 类型安全策略

因为 class_name 不可用，代码中使用 **鸭子类型 (duck typing)**:
```gdscript
# 不要写类型注解
func resolve_combat(attacker, defender):
    attacker.has_acted = true   # 按属性名访问，不依赖类型

# 创建实例用 load()
var u = load("res://scripts/core/squad.gd").new()
```

### 9.4 UI 场景开发规则

| 规则 | 说明 |
|------|------|
| **节点命名** | 使用 `%UniqueName` 唯一名称，便于代码 `@onready var xxx = %Xxx` 引用 |
| **锚点** | 弹窗类用居中锚点 (0.5, 0.5); 全屏类用四角拉伸 |
| **theme** | 场景引用全局 theme，不写死字体颜色 |
| **ui_style.gd** | 颜色从 `ui_style.gd` 常量取，不硬编码 |
| **预加载** | `preload()` 频繁使用的场景，`load()` 按需加载的场景 |

### 9.5 版本控制

- 每步完成后确保烟雾测试通过
- 不提交未通过测试的代码
- `.tscn` 文件是文本格式，可正常 diff

---

## 10. 测试指南

### 10.1 运行测试

```powershell
# 烟雾测试 (快速，每次修改后跑)
$p = Start-Process -FilePath $godot -ArgumentList "--headless --path <project> res://tests/test_smoke.tscn --quit" -NoNewWindow -PassThru

# 全量测试 (提交/打包前跑)
$p = Start-Process -FilePath $godot -ArgumentList "--headless --path <project> res://tests/test_full.tscn --quit" -NoNewWindow -PassThru
```

**注意**: 不要使用 `RedirectStandardOutput + ReadToEnd()`，否则进程阻塞。

### 10.2 测试覆盖

| 层级 | 文件 | 用例数 | 耗时 | 时机 |
|------|------|--------|------|------|
| 烟雾 (smoke) | `tests/test_smoke.tscn` | 36 | ~4s | 每次修改后 |
| 全量 (full) | `tests/test_full.tscn` | 102 | ~10s | 提交/打包前 |

| 模块 | 用例数 |
|------|--------|
| HexUtil 数学 | 29 |
| GameManager | 10 |
| 数据定义 | 14 |
| 单位行为 | 13 |
| 战斗系统 | 8 |
| HexMap | 13 |

### 10.3 测试规范

| 规则 | 说明 |
|------|------|
| 烟雾测试 | 快速验证核心功能，每次修改后必跑 |
| 全量测试 | 包含所有用例，提交前必跑 |
| 新增功能 | 必须附带至少2个测试用例 |
| 旧用例 | 必须保持通过，不降级 |

---

## 11. 第一阶段开发计划

### 11.1 范围定义

**目标**: 可完整游玩"新游戏 → 第一关胜利"的完整循环。

```
主菜单 → 国家选择 → 指挥官创建 → 部署(放部队到地图) →
战场(选部队→移动→攻击→战斗预览→战斗过程→战斗日志) → 胜利结算 → 返回基地(占位)
```

### 11.2 任务拆解 (8步)

#### 步1: 项目基础建设
- 更新测试套件适配新三层结构（squad/member，废弃旧unit引用）
- 确保烟雾+全量测试通过
- 确认所有编码规范生效
- 创建 `scenes/ui/` 目录结构

#### 步2: 主菜单 + 场景管理框架
- 实现主菜单场景 `scenes/ui/main_menu.tscn`
  - 标题 + [新游戏] [载入] [设置] [退出] 按钮
  - dark military 风格（参照 `main_menu_v1.html`）
- 实现场景管理器（主菜单→新游戏→战场→胜利→返回菜单）
- 创建 `scripts/ui/scene_manager.gd` (autoload)

#### 步3: 国家选择 + 指挥官创建
- 实现国家选择界面 `scenes/ui/nation_select.tscn`
  - 轮播式选国家（德国/苏联）
  - 确定后锁定初始国家
- 实现指挥官创建界面 `scenes/ui/commander_create.tscn`
  - 4卡横排（1主角英雄 + 3随机）
  - 背景/天赋/品质技能按 §11 规则生成
  - 重掷/改名功能
  - 确认后进入部署

#### 步4: 部署界面
- 实现部署场景 `scenes/ui/deployment.tscn`
- 左栏: 已选部队列表（4支初始编制）
- 地图: 己方HQ放置 → 显示部署区范围
- 点击部队 → 点击HQ相邻格放置
- 确认 → 进入战斗场景

#### 步5: 战场主界面升级
- 底部操作栏 `scenes/ui/battle_hud.tscn`
  - 选中部队后显示: 射击/突击/待机/补给按钮
  - 部队信息卡片 (名称/士气/AP/HP网格/武器)
  - 地形信息条
- 选部队 → 显示移动范围(绿) + 攻击范围(红)
- ZOC 橙色标记
- 顶部栏: 回合数/阶段/货币

#### 步6: 战斗预览 + 战斗过程 + 战斗日志
- 战斗预览 `scenes/ui/combat_preview.tscn`
  - 左: 武器列表(按类型分组, 可取消特定组)
  - 右: 命中率/伤害范围/压制值/反击预期
  - 底: [确认] [取消]
- 战斗过程动画 (resolve_fire 逐发动画)
- 战斗日志 `scenes/ui/combat_log.tscn`
  - 按攻击分组显示
  - 武器分组命中数/击杀/压制
  - 目标状态变化
  - 士气事件

#### 步7: 第一关数据配置
- 12×10 地图地形配置 (DESIGN §21.5)
- 德国/苏联双方初始编制（DESIGN §21.4）
- HQ放置 + 胜利条件(全灭敌军)
- 关卡配置文件 `resources/levels/prologue.gd`

#### 步8: 胜利结算 + 整体测试
- 胜利/失败结算 `scenes/ui/victory.tscn`
- 战后统计数据
- 返回基地占位场景
- 全局测试通过（烟雾+全量）
- 新功能配套测试用例

### 11.3 时间线建议

```
步1 (基础)     → 步2 (主菜单)
                         ↘
                步3 (国家选择+指挥官创建) → 步4 (部署)
                                                  ↘
                    步5 (战场HUD) → 步6 (战斗预览) → 步7 (第一关数据)
                                                              ↘
                                                        步8 (胜利+测试)
```

步1-2 可并行, 步5-6 依赖步4, 步7 依赖步5-6。

### 11.4 完成标准

| 条件 | 说明 |
|------|------|
| 烟雾测试 | 全部通过 (新增用例覆盖新功能) |
| 全量测试 | 全部通过 |
| 完整流程 | 主菜单 → 选国家 → 创指挥官 → 部署 → 打第一关 → 胜利 |
| 编辑器可调 | 所有UI场景可在Godot编辑器中打开并调整 |

---

## 12. 变更记录

> 所有开发过程中的需求变更和 Bug 修复需在此记录。

| 日期 | 类型 | 描述 | 涉及文件 |
|------|------|------|---------|
| 2026-04-28 | 初始 | 完成 Phase 1 基础框架 | 全部 |
| 2026-04-28 | 修复 | `const` 不能用函数返回值; `class_name` 不注册; 类型推导失败; 文件编码问题 | 全部脚本 + project.godot |
| 2026-04-28 | 修复 | Hex 距离测试期望值错误 | tests/test_runner.gd |
| 2026-04-28 | 功能 | Issue 1: 镜头移动 (WASD+拖拽+滚轮) | main_controller.gd |
| 2026-04-28 | 修复 | Issue 2: 单位文字层级低于地形 | unit.gd (z_index) |
| 2026-04-28 | 修复 | Issue 3: 单位可多次移动 (流程漏洞) | main_controller.gd |
| 2026-04-28 | 功能 | Issue 4: 行动完成 E 标识 | unit.gd |
| 2026-04-28 | 修复 | Issue 5: 无法结束回合 (has_acted 未正确置位) | main_controller.gd + ui_manager.gd |
| 2026-04-28 | 文档 | 创建 ISSUES.md 和 DEVELOPMENT.md | docs/ |
| 2026-04-28 | 修复 | Issue 1: 中键松开后退出拖拽 | main_controller.gd |
| 2026-04-28 | 修复 | Issue 2: 单位Label视觉居中 | unit.gd (size+position) |
| 2026-04-28 | 修复 | Issue 3a: 操作中禁止deselect导致连续移动 | main_controller.gd |
| 2026-04-28 | 修复 | Issue 3b: 结束回合可跳过未行动单位 | ui_manager.gd |
| 2026-04-28 | 测试 | 新增回合循环测试 (7例) | test_runner.gd |
| 2026-04-28 | 修复 | `result.counter_damage` → `result.damage_to_attacker` | main_controller.gd |
| 2026-04-28 | 修复 | 连续移动bug: 无攻击目标时自动 `_end_unit_action()` | main_controller.gd |
| 2026-04-28 | 测试 | 新增 has_acted 防复发测试 (8例) | test_runner.gd |
| 2026-04-28 | 修复 | E标识位置左上角→右上角; 新回合`update_visual()`清除 | unit.gd, game_manager.gd |
| 2026-04-28 | 修复 | 攻击后E不显示: `attacker.update_visual()` | battle_manager.gd |
| 2026-04-28 | 功能 | Option A流程: 选中即显示移动+攻击+待机; 可原地攻击/待机 | main_controller.gd |
| 2026-04-28 | 功能 | 右键+空白+ESC取消选中 | main_controller.gd |
| 2026-04-28 | 功能 | 回合切换大字淡入淡出 | ui_manager.gd |
| 2026-04-28 | 修复 | 攻击时移动到目标格子 (valid_hexes/attack_hexes分离) | main_controller.gd |
| 2026-04-28 | 重构 | 拆分烟雾/全量测试: smoke + full | tests/ |
| 2026-04-28 | 功能 | 敌方AI逐行动画 | ai_controller.gd |
| 2026-04-28 | 修复 | 移动范围被攻击高亮覆盖 | hex_map.gd, main_controller.gd |
| 2026-04-28 | 功能 | 胜利提示改为居中大字 | ui_manager.gd, main_controller.gd |
| 2026-04-28 | 步1 | 三层结构重构: Squad+Member+UnitType | 新建 squad/member/unit_type_data，重写 game_manager/main_controller/ui_manager/battle_manager/ai_controller |
| 2026-05-05 | 文档 | 完整重写 DEVELOPMENT.md: 新增UI方案/美术资源工作流/第一阶段计划/项目结构更新 | 全部 docs/ |

### 变更记录规范

每次修改需记录:
- **日期**: YYYY-MM-DD
- **类型**: 功能 / 修复 / 重构 / 文档 / 测试
- **描述**: 1-2句话说明
- **涉及文件**: 修改的文件列表
