# ============================================================
# 数据配置表校验器 (_validate.gd)
# 用法: 拖入Godot场景或直接在编辑器中运行
# 检查 data/germany/ 下4个JSON文件的所有引用完整性
# ============================================================
extends Node

var errors := []

func _ready() -> void:
    var dir = "res://data/germany/"
    _load_and_validate(dir + "weapons.json",  _check_weapons)
    _load_and_validate(dir + "units.json",    _check_units)
    _load_and_validate(dir + "tree.json",     _check_tree)
    _load_and_validate(dir + "equipment.json",_check_equipment)
    
    if errors.is_empty():
        print("[PASS] All germany data files validated OK")
    else:
        for e in errors:
            printerr("[FAIL] " + e)
        printerr("[FAIL] %d errors found" % errors.size())

func _e(msg: String) -> void:
    errors.append(msg)

# 缓存: 加载数据供后续校验引用
var weapons := []
var units := []
var nodes := []

func _load_and_validate(path: String, check_fn: Callable) -> void:
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        _e("Cannot open: " + path)
        return
    var json = JSON.parse_string(file.get_as_text())
    if json == null:
        _e("Invalid JSON: " + path)
        return
    check_fn.call(json)

# ---------- W: Weapons ----------
func _check_weapons(data: Array) -> void:
    weapons = data
    for w in data:
        if w.id.is_empty():          _e("Weapon: empty id")
        if w.penetration < 0:        _e("%s: pen < 0" % w.id)
        if w.range_min > w.range_max: _e("%s: range_min > max" % w.id)
    var ids = data.map(func(w): return w.id)
    if ids.size() != ids.duplicate().size():
        _e("Weapons: duplicate ID found")

# ---------- U: Units ----------
func _check_units(data: Array) -> void:
    units = data
    var weapon_ids = weapons.map(func(w): return w.id)
    for u in data:
        if u.members.is_empty():     _e("%s: no members" % u.id)
        if u.cost <= 0:              _e("%s: cost <= 0" % u.id)
        for m in u.members:
            for w in m.weapons:
                if not w in weapon_ids:
                    _e("%s: unknown weapon '%s'" % [u.id, w])
    var ids = data.map(func(u): return u.id)
    if ids.size() != ids.duplicate().size():
        _e("Units: duplicate ID found")

# ---------- T: Tree ----------
func _check_tree(data: Array) -> void:
    nodes = data
    var unit_ids = units.map(func(u): return u.id)
    var all_ids = data.map(func(n): return n.id)
    for n in data:
        if not n.unit_type_id in unit_ids:
            _e("%s: unknown unit_type '%s'" % [n.id, n.unit_type_id])
    if not n.tech_tier_required in [0,1,2,3]:
        _e("%s: bad tech_tier" % n.id)
        if n.parent_id != null and not n.parent_id in all_ids:
            _e("%s: unknown parent '%s'" % [n.id, n.parent_id])
        if n.parent_id != null:
            var parent = _find(all_ids, n.parent_id)
            var p = data[all_ids.find(n.parent_id)]
            if p.nation != n.nation or p.branch != n.branch:
                _e("%s: parent branch/nation mismatch" % n.id)
    # 循环检测 (BFS cycle)
    var visited := {}
    for n in data:
        if _has_cycle(n, data, visited):
            _e("%s: cyclic dependency" % n.id)
            break

func _has_cycle(node, all: Array, visited: Dictionary) -> bool:
    if visited.get(node.id, false): return true
    if node.parent_id == null:      return false
    visited[node.id] = true
    for n in all:
        if n.id == node.parent_id:
            return _has_cycle(n, all, visited)
    return false

func _find(list: Array, id: String) -> int:
    return list.find(id)

# ---------- E: Equipment ----------
func _check_equipment(data: Array) -> void:
    var unit_ids = units.map(func(u): return u.id)
    for e in data:
        if not e.rarity in ["green","purple","orange"]:
            _e("%s: bad rarity" % e.id)
        if e.replaces_unit_type and not e.replaces_unit_type in unit_ids:
            _e("%s: unknown unit_type '%s'" % [e.id, e.replaces_unit_type])
