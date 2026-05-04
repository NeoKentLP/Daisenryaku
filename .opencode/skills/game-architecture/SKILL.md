---
name: game-architecture
description: Project architecture - three-layer structure, battle flow, and system connections
---

## Three-Layer Structure
- `squad.gd` (extends Node2D) — 部队：管理成员列表、士气、AP、位置
- `member.gd` (extends RefCounted) — 成员：HP、武器列表、属性
- `weapon_data.gd` (extends RefCounted) — 武器静态工厂：武器属性字典生成
- `unit_type_data.gd` (extends Resource) — 兵种模板：编制定义

## Autoloads
- `GameManager` — 全局状态，管理部队列表、补给池、指挥官池、世界状态
- `HexUtil` — 六边形网格数学工具

## Battle Flow
1. 选中部队 → 显示行动菜单（移动/攻击/待机/工兵/补给）
2. 点击目标格 → 执行行动
3. 攻击流程：`battle_manager.resolve_combat()` → 三层判定（命中→穿透→伤害）
4. 回合管理：`GameManager.end_player_turn()` → AI → `GameManager.end_enemy_turn()`

## Combat Formula
- **命中**: BS + 武器修正 + 士气修正 - 地形惩罚 - 回避 - 隐蔽 - 射程修正 - ZOC惩罚
- **穿透**: 武器AP + rand(±2) ≥ 目标护甲
- **伤害**: 武器伤害值 × (1 ± 随机波动%) × 地形掩护减伤(DB×10%) × 士气修正

## Key Manager References (via GameManager)
- `hex_map` — 地图数据
- `battle_manager` — 战斗结算
- `ui_manager` — UI控制
- `world_controller` — 世界地图控制
