---
name: godot-gdscript
description: Godot 4.6 GDScript coding patterns, class loading, and best practices for this project
---

## GDScript Rules
- `class_name` 不注册，所有类型用 `load()`/`preload()` 获取
- 避免用 `exp` 作变量名（与内置函数冲突），用 `_exp`
- Steam 版 `tooltip` 属性不支持，用自定义悬浮面板实现
- 中文字符串注意编码：PowerShell 操作用 .NET 方法，不用 `Set-Content`
- 成员类型 `member_type` 用字符串标识（infantry/vehicle），不用枚举
- 武器数据通过 `weapon_data.gd` 静态方法创建，用 `.duplicate()` 避免引用共享
- `extends RefCounted` 用于数据类（member/weapon_data/commander），`extends Node` 用于有生命周期管理的类

## Godot 4.6 注意事项
- 信号连接用 `signal.connect(callable)` 语法，不用字符串
- `@export` 用于编辑器可调参数
- 用 `is_instance_valid(obj)` 检查对象是否被销毁
- `randi()` 返回 int，`randf()` 返回 float
- `clampi()` / `clampf()` 替代手写 clamp
- `Vector2i` 用于 hex 坐标，`Vector2` 用于像素位置
