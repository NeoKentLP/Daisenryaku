# 战棋游戏开发问题备忘录

> 面向: Godot 4.6.2.stable.steam (Steam版)
> 引擎路径: D:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe
> 项目路径: D:\项目\godot\大战略01

---

## 目录

1. [GDScript 语法与类型系统](#1-gdscript-语法与类型系统)
2. [class_name 注册问题](#2-class_name-注册问题)
3. [静态方法调用](#3-静态方法调用)
4. [字符串运算符](#4-字符串运算符)
5. [文件编码与中文路径](#5-文件编码与中文路径)
6. [autoload 使用规范](#6-autoload-使用规范)
7. [函数返回类型注解](#7-函数返回类型注解)
8. [CLI 运行与测试](#8-cli-运行与测试)
9. [Hex 坐标系统](#9-hex-坐标系统)
10. [Godot Steam 版差异](#10-godot-steam-版差异)

---

## 1. GDScript 语法与类型系统

### 1.1 禁止使用 `var x := function_call()` 推导类型

**问题描述**: Godot 4.6.2 中，当函数的返回类型没有显式声明时，`:=` 操作符无法推导类型，编译报错:
```
SCRIPT ERROR: Parse Error: Cannot infer the type of "x" variable
```

**触发场景**: 所有从自定义函数返回值的变量赋值。
```gdscript
# 错误
var pos := axial_to_pixel(hex.x, hex.y, hex_size)
var result := resolve_combat(a, b)
var reachable := get_reachable_hexes(from, range)

# 正确
var pos = axial_to_pixel(hex.x, hex.y, hex_size)
var result = resolve_combat(a, b)
var reachable = get_reachable_hexes(from, range)
```

**解决方案**: 统一使用 `var x = expr` 而非 `var x := expr`。

**涉及文件**: hex_map.gd, unit.gd, battle_manager.gd, ai_controller.gd, ui_manager.gd, main_controller.gd, test_runner.gd

---

### 1.2 变量类型从 Variant 推导时警告被视为错误

**问题描述**: 当 `:=` 右侧是 Variant 时，Godot 4.6.2 将警告提升为错误:
```
SCRIPT ERROR: Parse Error: The variable type is being inferred from a Variant value,
so it will be typed as Variant. (Warning treated as error.)
```

**解决方案**: 与 1.1 相同，使用 `var x = expr`。

---

### 1.3 const 不能使用函数调用结果

**问题描述**: GDScript 中 `const` 必须是编译期常量，不能是函数调用或方法调用的结果:
```gdscript
# 错误
const DB: Dictionary = preload("...").create_defaults()

# 正确
static var DB: Dictionary = {}
func _init():
    if DB.is_empty():
        DB = preload("...").create_defaults()
```

**涉及文件**: autoload/game_manager.gd (原代码)

---

## 2. class_name 注册问题

### 2.1 Godot 4.6.2 Steam 版 class_name 不注册

**问题描述**: `class_name` 关键字在 Godot 4.6.2 Steam 版中不工作。所有使用 `class_name` 声明的类型在其他文件中均无法解析:
```
SCRIPT ERROR: Parse Error: Could not find type "HexUtil" in the current scope.
SCRIPT ERROR: Parse Error: Could not find type "TerrainData" in the current scope.
SCRIPT ERROR: Parse Error: Could not find type "Unit" in the current scope.
```

**原因**: 可能是 Steam 版的 GDScript 编译器行为差异，class_name 在脚本加载时未能正确注册到全局作用域。

**解决方案**: 完全放弃使用 `class_name`。改用:
- 工具类 (如 HexUtil): 注册为 autoload 单例
- 数据类 (如 TerrainData, UnitData): 通过 `preload()` 在需要时加载
- Node 类 (如 HexMap, Unit): 在创建时使用 `load("res://...").new()` 而非类型引用

**涉及文件**: 全部脚本

**移除的 class_name 列表**:
| 文件 | 原 class_name | 替代方案 |
|------|-------------|---------|
| scripts/core/hex_util.gd | HexUtil | autoload |
| resources/terrain/terrain_data.gd | TerrainData | preload |
| resources/units/unit_data.gd | UnitData | preload |
| scripts/map/hex_map.gd | HexMap | load() |
| scripts/units/unit.gd | Unit | load() |
| scripts/battle/battle_manager.gd | BattleManager | load() |
| scripts/ai/ai_controller.gd | AIController | load() |
| scripts/ui/ui_manager.gd | UIManager | load() |

### 2.2 class_name 在同一文件内自引用

**问题描述**: 即使 class_name 正常工作，也不能在同一文件的 `static func` 中自引用:
```gdscript
# terrain_data.gd
class_name TerrainData
static func create_defaults():
    var db = {}
    db["plain"] = TerrainData.new(...)  # 错误: Identifier not found
```

**解决方案**: 改用 `new()` (不带类名前缀):
```gdscript
db["plain"] = new("plain", ...)
```

---

## 3. 静态方法调用

### 3.1 preload 后不能调用静态方法

**问题描述**: 在 Godot 4.6.2 中，用 `preload()` 获取 GDScript 引用后，不能直接调用其 `static func`:
```gdscript
const HexUtil = preload("res://scripts/core/hex_util.gd")
HexUtil.axial_to_pixel(...)  # 错误: Nonexistent function in base 'GDScript'
```

**原因**: `preload()` 返回的是 `GDScript` 资源对象，静态方法在 4.6.2 中无法通过 GDScript 引用直接访问。

**解决方案**: 改为 autoload 单例模式，把 static func 改为普通方法。

---

## 4. 字符串运算符

### 4.1 字符串 * 整数 不再支持

**问题描述**: Godot 4.6.2 不允许 `"text" * N` 来重复字符串:
```
SCRIPT ERROR: Parse Error: Invalid operands to operator *, String and int.
```

**解决方案**: 使用 `.repeat(N)` 方法:
```gdscript
# 错误
print("=" * 60)

# 正确
print("=".repeat(60))
```

---

## 5. 文件编码与中文路径

### 5.1 PowerShell 破坏 UTF-8 编码

**问题描述**: PowerShell 的 `Set-Content` 默认使用系统 ANSI 编码，会破坏含中文的 UTF-8 文件。

**触发场景**: 通过 PowerShell 修改含有中文的 `project.godot`:
```powershell
$content = Get-Content "project.godot" -Raw     # 用默认编码读取
$content = $content -replace "old", "new"
Set-Content "project.godot" $content             # 写入 ANSI 编码 → 中文乱码
```

**解决方案**:
- 用 `.NET` 方法操作文件:
```powershell
$utf8_no_bom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($path, $content, $utf8_no_bom)
```
- 或者用 `Out-File -Encoding UTF8`
- 优先使用 Godot 内置工具写入文件

### 5.2 UTF-8 BOM 导致解析错误

**问题描述**: 带 BOM (Byte Order Mark) 的 UTF-8 文件会导致 Godot 解析错误:
```
ERROR: Error parsing project.godot at line 19: Unterminated String
```

**原因**: `[System.Text.Encoding]::UTF8` 默认带 BOM (0xEF BB BF)。Godot 4.6.2 不能正确处理 BOM。

**解决方案**: 创建不带 BOM 的 UTF8 编码器:
```powershell
$utf8_no_bom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($path, $content, $utf8_no_bom)
```

### 5.3 中文路径显示问题

**问题描述**: PowerShell 终端无法正确显示中文路径，可能出现:
```
D:\��Ŀ\godot\��ս��01
```

但这**不影响 Godot 运行**。底层字节是正确的 UTF-8。

---

## 6. autoload 使用规范

### 6.1 注册方式

在 `project.godot` 的 `[autoload]` 节注册:
```ini
[autoload]
GameManager="*res://autoload/game_manager.gd"
HexUtil="*res://scripts/core/hex_util.gd"
```

`*` 前缀表示该 autoload 为单例 (Singleton)，可以直接通过名称访问。

### 6.2 当前 autoload 列表

| 名称 | 文件 | 用途 |
|------|------|------|
| GameManager | autoload/game_manager.gd | 全局状态管理 |
| HexUtil | scripts/core/hex_util.gd | 六边形数学工具 |

### 6.3 autoload 的 _init vs _ready

```gdscript
# autoload 的 _init() 在场景树构建前执行，适合初始化静态数据
func _init():
    if TERRAIN_DB.is_empty():
        TERRAIN_DB = preload("...").create_defaults()

# _ready() 在场景树就绪后执行
func _ready():
    process_mode = PROCESS_MODE_ALWAYS
```

---

## 7. 函数返回类型注解

### 7.1 禁止使用自定义类型作为注解

**问题描述**: 由于 class_name 不工作，所有自定义类型都不能用作函数参数或返回值的类型注解:
```gdscript
# 错误
func resolve_combat(attacker: Unit, defender: Unit) -> Dictionary:
func show_unit_info(unit: Unit):
func _find_nearest_enemy(unit: Unit, enemies: Array) -> Unit:
```

**解决方案**: 省略类型注解:
```gdscript
func resolve_combat(attacker, defender):
func show_unit_info(unit):
func _find_nearest_enemy(unit, enemies):
```

---

## 8. CLI 运行与测试

### 8.1 Steam 版 CLI 限制

**问题描述**: Steam 版 Godot 4.6.2 在 CLI 下行为不同:
- `--version`: ✅ 工作 (输出 `4.6.2.stable.steam.71f334935`)
- `--help`: ❌ 超时 (进程不退出)
- `--quit`: ⚠️ 部分工作 (配合 `--headless` 时工作)
- `--quit-after N`: ❌ 不工作 (进程不退出)

**解决方案**:
- 测试时使用 `--headless --path <project>`
- 不加 `--quit` (进程会被我们手动 kill)
- 标准输出通过 `Start-Process -NoNewWindow -PassThru` 捕获

### 8.2 正确运行命令

```powershell
# 运行主游戏 (无输出重定向)
$godot = "D:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
$p = Start-Process -FilePath $godot -ArgumentList "--path <project>" -NoNewWindow -PassThru

# headless 模式测试
$p = Start-Process -FilePath $godot -ArgumentList "--headless --path <project> --quit" -NoNewWindow -PassThru

# 运行指定场景
$p = Start-Process -FilePath $godot -ArgumentList "--path <project> res://tests/test_scene.tscn" -NoNewWindow -PassThru
```

### 8.3 ReadToEnd() 阻塞陷阱

**问题描述**: `Process.StandardOutput.ReadToEnd()` 在进程不退出时会**永久阻塞**。

**解决方案**: 不使用 `RedirectStandardOutput + ReadToEnd`。直接用 `Start-Process -NoNewWindow` 让输出显示在当前控制台。

---

## 9. Hex 坐标系统

### 9.1 轴向坐标距离公式

**正确定义**: 六边形的对角线距离不等同于欧几里得距离。

轴向坐标 (q, r) 中，距离公式:
```gdscript
func hex_distance(a: Vector2i, b: Vector2i) -> int:
    var dq = a.x - b.x
    var dr = a.y - b.y
    return (abs(dq) + abs(dq + dr) + abs(dr)) / 2
```

**常见误区**: `hex_distance((0,0), (3,3))` = 6 (不是 3!)
因为六边形从 (0,0) 到 (1,1) 需要**2步** (0,0)→(1,0)→(1,1) 或 (0,0)→(0,1)→(1,1)。

### 9.2 邻居方向 (pointy-top)

轴向坐标邻居:
```
(1, 0)   (0, 1)   (-1, 1)
(-1, 0)  (0, -1)  (1, -1)
```

注意: 不存在 `(1, 1)` 或 `(-1, -1)` 邻居。

### 9.3 hexes_in_range 包含自身

`hexes_in_range(center, range)` 返回的结果**包含中心格子**。
- range=1: 返回 7 个格子 (中心 + 6 邻居)
- range=2: 返回 19 个格子
- 公式: `1 + 3 * range * (range + 1)`

---

## 10. Godot Steam 版差异

### 10.1 已知差异汇总

| 特性 | 标准版 | Steam 版 (4.6.2) |
|------|-------|-----------------|
| class_name 注册 | 正常 | 不工作 |
| 静态方法调用 | 支持 | 不支持 |
| 字符串 `*` 运算符 | 支持 | 不支持 |
| `var x := func()` | 支持 | 不支持 |
| `--quit` CLI | 正常 | 部分工作 |
| `--help` CLI | 正常 | 超时 |
| UTF-8 BOM 处理 | 可能正常 | 报错 |
| 输出重定向 | 正常 | 需特殊处理 |

### 10.2 步1常见问题（2026-04-28）

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| `get_unit_at` 残留引用导致运行时错误 | hex_map.gd中有一处引用未更新 | 改为`get_squad_at` |
| 测试文件引用旧`player_units`属性 | GameManager重构为`player_squads` | 测试同步更新 |
| `assert_eq`调用缺少desc参数 | GDScript不支持可选参数的默认值方式 | 改为`func assert_eq(got, expected, desc: String = "")` | 建议

- 脚本编写时遵循**最保守的 GDScript 语法**
- 避免使用高级类型特性 (class_name, 类型注解, 静态方法, 类型推导)
- 优先使用 autoload 代替 class_name
- 测试时用 `Start-Process -NoNewWindow` 而非重定向 stdout

---

## 11. Bug 模式记录

> 每次修复 Bug 后在此记录根因和修复模式，防止同类问题反复出现。

### 11.1 模式: close() 提前置空回调引用

| 字段 | 值 |
|------|-----|
| **现象** | 战后回调不执行，导致 `_deselect_squad`、`_check_win_condition` 永不被调用，攻击者可重复攻击 |
| **根因** | `close()` 函数在执行回调前先将 `close_callback = null`，然后 `_on_close()` 检查 null 后跳过回调 |
| **修复方案** | 在 `close()` 执行前保存回调引用：`var cb = close_callback; close(); if cb: cb.call()` |
| **涉及文件** | `combat_flow.gd`, `combat_preview.gd` |
| **预防** | 所有带回调的弹窗类，`close()` 函数不应销毁回调引用；或者调用者先存引用 |

### 11.2 模式: Godot 4 API 变更 (vs Godot 3)

| 问题 | 旧写法 | 新写法 |
|------|--------|--------|
| HBoxContainer 拉伸 | `hdr.add_stretch_ratio(1.0)` | `hdr.add_spacer(true)` |
| ScrollContainer 水平滚动 | `scroll.scroll_horizontal_enabled = false` | `scroll.horizontal_scroll_mode = SCROLL_MODE_DISABLED` |
| SystemFont 粗体 | `f.bold = true` | `f.font_weight = 700` |

### 11.3 模式: CanvasLayer 缺少 Node2D 方法

| 现象 | 根因 | 修复 |
|------|------|------|
| 部署界面 Hex 点击不触发 | `_unhandled_input` 在 CanvasLayer 上不可靠 | 改用 `gui_input` + 透明 ColorRect overlay |
| `get_global_mouse_position()` 报错 | CanvasLayer 无此方法 | 用 `get_viewport().get_mouse_position()` |

### 11.4 模式: 变量作用域泄漏

| 现象 | 根因 | 修复 |
|------|------|------|
| 确认部署后崩溃 "ms not declared" | 敌 HQ 创建代码混在 `_get_enemy_squads()` 后，引用了上层函数的局部变量 `ms` | 保持代码在正确的函数作用域内，不在函数间插入散落代码 |

### 11.5 模式: ensure_loaded 无限递归

| 现象 | 根因 | 修复 |
|------|------|------|
| 部署崩溃，堆栈溢出 | `ensure_loaded()` 末尾才设 `_loaded = true`，但 `_load_units` 调用 `get_weapon` → 再次调用 `ensure_loaded` | `_loaded = true` 移至函数开头，防止重入 |

### 11.6 模式: 移动后不重新选择

| 现象 | 根因 | 修复 |
|------|------|------|
| 分次移动后不显示剩余范围 | `_select_squad(sq)` 首行检查 `selected_squad == squad` 直接返回 | 移动后先 `_deselect_squad()` 清空再 `_select_squad(sq)` |

### 11.7 模式: 重叠节点无法清理

| 现象 | 根因 | 修复 |
|------|------|------|
| 移动后高亮边框不消失 | Tiered highlights 创建了多个节点但只存了一个引用 | 用父子节点关系管理（父 freed → 子自动 freed）或用独立数组全量跟踪 |

### 10.1 已知差异汇总

| 特性 | 标准版 | Steam 版 (4.6.2) |
|------|-------|-----------------|
| class_name 注册 | 正常 | 不工作 |
| 静态方法调用 | 支持 | 不支持 |
| 字符串 `*` 运算符 | 支持 | 不支持 |
| `var x := func()` | 支持 | 不支持 |
| `--quit` CLI | 正常 | 部分工作 |
| `--help` CLI | 正常 | 超时 |
| UTF-8 BOM 处理 | 可能正常 | 报错 |
| 输出重定向 | 正常 | 需特殊处理 |

### 10.2 步1常见问题（2026-04-28）

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| `get_unit_at` 残留引用导致运行时错误 | hex_map.gd中有一处引用未更新 | 改为`get_squad_at` |
| 测试文件引用旧`player_units`属性 | GameManager重构为`player_squads` | 测试同步更新 |
| `assert_eq`调用缺少desc参数 | GDScript不支持可选参数的默认值方式 | 改为`func assert_eq(got, expected, desc: String = "")` | 建议

- 脚本编写时遵循**最保守的 GDScript 语法**
- 避免使用高级类型特性 (class_name, 类型注解, 静态方法, 类型推导)
- 优先使用 autoload 代替 class_name
- 测试时用 `Start-Process -NoNewWindow` 而非重定向 stdout

---

## 附录: 文件清单

```
大战略01/
├── project.godot                        # 项目配置
├── icon.svg                             # 项目图标
├── autoload/
│   └── game_manager.gd                  # 全局状态管理 (autoload)
├── scripts/
│   ├── core/
│   │   ├── hex_util.gd                  # 六边形数学工具 (autoload)
│   │   ├── squad.gd                     # 部队类 (替换旧unit.gd)
│   │   ├── member.gd                    # 成员类
│   │   └── unit_type_data.gd            # 兵种模板数据
│   ├── map/
│   ├── map/
│   │   └── hex_map.gd                   # 地图控制器
│   ├── units/
│   │   └── unit.gd                      # 单位
│   ├── battle/
│   │   ├── battle_manager.gd            # 战斗系统
│   │   └── main_controller.gd           # 主控器
│   ├── ai/
│   │   └── ai_controller.gd             # AI
│   └── ui/
│       └── ui_manager.gd                # UI
├── resources/
│   ├── terrain/
│   │   └── terrain_data.gd              # 地形定义
│   └── units/
│       └── unit_data.gd                 # 兵种定义
├── scenes/
│   └── battle/
│       └── main_scene.tscn              # 主场景
├── tests/
│   ├── test_runner.gd                   # 测试运行器
│   ├── test_scene.tscn                  # 测试场景
│   ├── test_minimal.gd                  # 最小测试
│   └── test_minimal.tscn                # 最小测试场景
└── docs/
    └── ISSUES.md                        # 本文件
```
