---
name: game-test
description: Test workflow - smoke tests first, then full tests, all must pass before completing a step
---

## Test Workflow
After every change, run tests in this order:

1. **Smoke tests** (quick, ~5s):
   ```
   "D:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless tests/test_smoke.tscn --path "D:\项目\godot\大战略01"
   ```
   Covers: HexUtil, Member, Squad, GameManager, Terrain, CQB, Engineer, Equipment, Commander, Supply
   Current: 94 cases

2. **Full tests** (comprehensive, ~15s):
   ```
   "D:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless tests/test_full.tscn --path "D:\项目\godot\大战略01"
   ```
   Covers: All hex math, member/squad lifecycle, combat resolution, turn cycle, map queries
   Current: 122 cases

## Rules
- 烟雾测试和全量测试**全部通过**才算改动完成
- 如果测试失败，先修复失败用例再继续
- 新增功能需添加对应的测试用例
- 测试文件：`tests/test_smoke.gd` 和 `tests/test_full.gd`
- 测试的模式：`assert_eq(got, expected, desc)` / `assert_true(cond, desc)` / `assert_false(cond, desc)`
