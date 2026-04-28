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
7. [开发规范与陷阱](#7-开发规范与陷阱)
8. [测试指南](#8-测试指南)
9. [已知问题与路线图](#9-已知问题与路线图)
10. [变更记录](#10-变更记录)

---

## 1. 项目概述

### 1.1 游戏定位

二战背景的六边形格战棋游戏，俯视视角，排级规模战斗。

### 1.2 核心特性

| 特性 | 当前状态 |
|------|---------|
| 六边形网格地图 (15×10) | ✅ 完成 |
| 7种地形 (平地/森林/山地/河流/道路/城市/指挥部) | ✅ 完成 |
| 7种兵种 (步兵/机械化步兵/坦克/火炮/侦察/防空/运输) | ✅ 完成 |
| 回合制战斗 (我方→敌方) | ✅ 完成 |
| 移动→攻击/待机流程 | ✅ 完成 |
| 基础AI (就近攻击) | ✅ 完成 |
| 镜头移动 (键盘/拖拽/缩放) | ✅ 完成 |
| 单位E标识 (行动完成) | ✅ 完成 |
| 指挥点系统 | ⬜ 计划中 |
| 增援系统 | ⬜ 计划中 |
| 关卡系统/战役 | ⬜ 计划中 |

---

## 2. 游戏设计

### 2.1 设定

- **题材**: 二战现代军事
- **视角**: 俯视 (Top-down)
- **地图**: 六边形网格 (Hex, Pointy-top)
- **战斗规模**: 排级 (10-30单位)
- **战斗模式**: 回合制 (玩家全动 → 敌方全动)

### 2.2 胜利条件

多种胜利条件 (全灭敌军/占领/特殊目标)，暂未完全实现，当前仅支持全灭判定。

### 2.3 指挥点与增援

- 每回合获得固定指挥点
- 可在己方部署区召唤增援
- 剧情事件也可触发增援
- **状态**: ⬜ 计划中

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
│   │   └── hex_util.gd                  # [autoload] 六边形数学
│   ├── map/
│   │   └── hex_map.gd                   # 地图控制器
│   ├── units/
│   │   └── unit.gd                      # 单位
│   ├── battle/
│   │   ├── main_controller.gd           # 主控器 (输入/流程)
│   │   └── battle_manager.gd            # 战斗系统
│   ├── ai/
│   │   └── ai_controller.gd             # 敌方AI
│   └── ui/
│       └── ui_manager.gd                # 界面
│
├── resources/
│   ├── terrain/
│   │   └── terrain_data.gd              # 地形定义
│   └── units/
│       └── unit_data.gd                 # 兵种定义
│
├── scenes/
│   └── battle/
│       └── main_scene.tscn              # 主场景
│
├── tests/
│   ├── test_runner.gd                   # 测试运行器
│   ├── test_scene.tscn                  # 测试场景
│   ├── test_minimal.gd / .tscn          # 最小测试
│   └── test_result.log                  # (运行时生成)
│
└── docs/
    ├── ISSUES.md                        # 问题备忘录
    └── (本文件)                          # 开发文档
```

---

## 4. 核心架构

### 4.1 autoload 列表

| 名称 | 文件 | 职责 |
|------|------|------|
| `GameManager` | `autoload/game_manager.gd` | 全局状态、单位注册、回合管理、指挥点 |
| `HexUtil` | `scripts/core/hex_util.gd` | 六边形数学工具 (坐标转换/寻路/距离) |

**注意**: 不使用 `class_name`。所有类型通过 `load()` / `preload()` 获取。

### 4.2 模块职责

| 模块 | 文件 | 核心职责 |
|------|------|---------|
| hex_map | `scripts/map/hex_map.gd` | 地图生成、地形数据、可达范围、攻击范围、高亮、坐标转换 |
| unit | `scripts/units/unit.gd` | 单位属性、视觉(颜色/文字/E标识)、移动、受伤/死亡、攻击判定 |
| battle_manager | `scripts/battle/battle_manager.gd` | 战斗结算、反击、调用AI |
| ai_controller | `scripts/ai/ai_controller.gd` | 敌方AI: 就近攻击逻辑 |
| main_controller | `scripts/battle/main_controller.gd` | 输入处理(点击/键盘/镜头)、选中→移动→攻击流程、回合检查 |
| ui_manager | `scripts/ui/ui_manager.gd` | UI面板、信息显示、消息提示、待机按钮、结束回合按钮 |

### 4.3 回合流程

```
┌─────────────────────┐
│  玩家回合开始        │
│  Phase 0             │
└─────────┬───────────┘
          ▼
┌─────────────────────┐
│  选择己方单位        │
│  → 显示移动范围      │
└─────────┬───────────┘
          ▼
┌─────────────────────┐
│  点击绿色格子移动    │
│  → 显示攻击范围      │
└─────────┬───────────┘
          ▼
   ┌─────────────┐
   │  有可攻击目标? │
   └──────┬──────┘
     是↓        ↓否
   ┌──────┐ ┌──────────┐
   │攻击  │ │点击"待机"│
   │→结算 │ │→标记已行动│
   └──┬───┘ └────┬─────┘
      ↓          ↓
   ┌─────────────────────┐
   │  标记 has_acted=true  │
   │  显示黄色 "E"       │
   └─────────┬───────────┘
             ▼
   ┌─────────────────────┐
   │  检查是否全部行动    │
   │  是→自动结束回合    │
   │  否→等待操作        │
   └─────────┬───────────┘
             ▼
   ┌─────────────────────┐
   │  敌方回合开始        │
   │  Phase 1             │
   │  AI自动行动         │
   └─────────┬───────────┘
             ▼
   ┌─────────────────────┐
   │  AI全部行动完毕     │
   │  增加指挥点         │
   │  重置 has_acted     │
   │  → 回到玩家回合     │
   └─────────────────────┘
```

### 4.4 战斗公式

```
伤害 = max(1, 攻击力 - max(0, 防御力 - 地形加成))

反击 = 攻击者是近战(attack_range<=1)且防御者有近战能力
反击伤害 = max(1, 防御者攻击力 - 攻击者防御力)
```

---

## 5. 数据定义

### 5.1 地形表

| ID | 名称 | 移动消耗 | 防御加成 |
|----|------|---------|---------|
| plain | 平地 | 1 | 0 |
| forest | 森林 | 2 | 2 |
| mountain | 山地 | 3 | 4 |
| river | 河流 | 2 | 0 |
| road | 道路 | 1 | 0 |
| city | 城市 | 1 | 3 |
| hq | 指挥部 | 1 | 3 |

定义文件: `resources/terrain/terrain_data.gd`

### 5.2 兵种表

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

---

## 6. 游戏流程

### 6.1 操作方式

| 操作 | 功能 |
|------|------|
| 鼠标左键点击单位 | 选中己方单位 |
| 鼠标左键点击绿色格子 | 移动 |
| 鼠标左键点击红色格子 | 攻击 |
| 鼠标滚轮 | 缩放镜头 (0.5x~3x) |
| 鼠标中键拖拽 | 平移镜头 |
| WASD / 方向键 | 键盘平移 |
| 「结束回合」按钮 | 结束玩家回合 |

### 6.2 单位视觉规范

| 状态 | 外观 |
|------|------|
| 我方单位 | 原色 (绿色系) |
| 敌方单位 | 红色偏暗 |
| 已行动 | 黄色 "E" 标识 |
| 被选中 | 绿色/红色高亮格子 |

### 6.3 主场景结构

```
Main (Node2D)
├── HexMap (Node2D)
│   ├── Camera2D
│   ├── Tile_0_0 ~ Tile_14_9 (Polygon2D, 地形色块)
│   ├── PlayerUnit_* (Unit, Node2D)
│   │   ├── Polygon2D (单位色块)
│   │   ├── Label (兵种名+HP)
│   │   └── Label ("E" 标识)
│   └── EnemyUnit_* (Unit, Node2D)
│       └── ...
├── BattleManager (Node)
├── AI (Node)
└── UIManager (CanvasLayer)
```

---

## 7. 开发规范与陷阱

### 7.1 GDScript 语法限制 (Godot 4.6.2 Steam 版)

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

### 7.2 文件编码

- 所有 `.gd` / `.tscn` 文件使用 **UTF-8 无 BOM**
- 不要用 PowerShell `Set-Content` 操作含中文的文件
- 用 `.NET` 方法: `[System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))`

### 7.3 类型安全策略

因为 class_name 不可用，代码中使用 **鸭子类型 (duck typing)**:
```gdscript
# 不要写类型注解
func resolve_combat(attacker, defender):
    attacker.has_acted = true   # 按属性名访问，不依赖类型

# 创建实例用 load()
var u = load("res://scripts/units/unit.gd").new()
```

---

## 8. 测试指南

### 8.1 运行测试

```powershell
# 烟雾测试 (快速，每次修改后跑)
$p = Start-Process -FilePath $godot -ArgumentList "--headless --path <project> res://tests/test_smoke.tscn --quit" -NoNewWindow -PassThru

# 全量测试 (提交/打包前跑)
$p = Start-Process -FilePath $godot -ArgumentList "--headless --path <project> res://tests/test_full.tscn --quit" -NoNewWindow -PassThru
```

**注意**: 不要使用 `RedirectStandardOutput + ReadToEnd()`，否则进程阻塞。

### 8.2 测试覆盖

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

### 8.3 添加新测试

在 `tests/test_runner.gd` 中添加:
1. 在 `run_all_tests()` 中添加调用
2. 编写 `func test_xxx():` 使用 `assert_eq` / `assert_true` / `assert_false`

---

## 9. 已知问题与路线图

### 9.1 当前问题

| 问题 | 优先级 | 状态 |
|------|--------|------|
| Steam 版 CLI 不支持 `--quit-after` | 低 | ⬜ 已知 |
| 退出时 "ObjectDB instances leaked" 警告 | 低 | ✅ 无害，headless 模式正常现象 |
| 无雾霾/视野系统 (全图可见) | 中 | ⬜ 按设计跳过 |
| 无经验/升级系统 | 中 | ⬜ 按设计跳过 |

### 9.2 路线图

| 阶段 | 内容 | 状态 |
|------|------|------|
| Phase 1 | 项目搭建 + Hex地图 + 单位 + 回合 + AI + UI | ✅ 完成 |
| Phase 2 | 指挥点 + 增援系统 | ⬜ 计划中 |
| Phase 3 | 关卡系统 + 多关卡战役 + 胜利条件 | ⬜ 计划中 |
| Phase 4 | 素材替换 + 润色 + 测试 | ⬜ 计划中 |

---

## 10. 变更记录

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
| 2026-04-28 | 文档 | 创建 ISSUES.md 和 开发文档 | docs/ |
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
| 2026-04-28 | 重构 | 拆分烟雾/全量测试: smoke(36例/4s) + full(102例/10s) | tests/ |
| 2026-04-28 | 修复 | 选中时可直接攻击(去掉action_mode检查) | main_controller.gd |
| 2026-04-28 | 功能 | 敌方AI逐行动画(0.6s间隔) | ai_controller.gd |
| 2026-04-28 | 修复 | 移动范围被攻击高亮覆盖 (highlight_hexes清空逻辑) | hex_map.gd, main_controller.gd |
| 2026-04-28 | 功能 | 胜利提示改为居中大字 (show_victory) | ui_manager.gd, main_controller.gd |

### 变更记录规范

每次修改需记录:
- **日期**: YYYY-MM-DD
- **类型**: 功能 / 修复 / 重构 / 文档 / 测试
- **描述**: 1-2句话说明
- **涉及文件**: 修改的文件列表
