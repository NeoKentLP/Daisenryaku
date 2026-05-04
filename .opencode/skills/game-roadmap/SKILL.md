---
name: game-roadmap
description: Current development phase, roadmap progress, and session context management
---

## Development Phase
- 当前所在步数：查看 `docs/ROADMAP.md` 确认
- 每步的可验证标准在 ROADMAP 中有详细列明，必须全部满足才算完成
- 完成一步后更新 `docs/SESSION_SUMMARY.md`

## Session Context
- 新会首先读取 `docs/SESSION_SUMMARY.md` 恢复上下文
- 设计规格在 `docs/DESIGN.md`（24章完整设计）
- 已知问题在 `docs/ISSUES.md`

## 步10+11 已完成功能
- 世界地图（12据点/20路径/A*寻路/随机遇敌）
- 部署阶段（出战选择4名额/指挥官检查/撤退）
- 据点交互（休息/补给/招募/侦查/修理）
- main_scene 已改为 `world_map.tscn`

## 步12+13 待实现
- 空中单位系统（机场/飞机/燃料）
- 铁路移动系统
- 视野与战争迷雾
