extends Node2D

var squad_name: String = ""
var unit_type_id: String = "infantry"
var team: int = 0
var hex_coord: Vector2i = Vector2i.ZERO

var members: Array = []
var has_acted: bool = false
var is_alive: bool = true

var morale: int = 70
var max_morale: int = 100
var suppression: int = 0
var ap: int = 3
var max_ap: int = 3

const STATE_BROKEN = 0
const STATE_CONFUSED = 1
const STATE_NORMAL = 2
const STATE_ELEVATED = 3
const STATE_FRENZIED = 4

var _sprite: Polygon2D
var _label: Label
var _done_label: Label

func setup(type_id: String, team_id: int, hex: Vector2i, squad_members: Array):
	unit_type_id = type_id
	team = team_id
	hex_coord = hex
	members = squad_members
	squad_name = _auto_name()
	_ensure_visual()

func _auto_name() -> String:
	var names = ["第一", "第二", "第三", "第四", "第五", "第六"]
	var idx = randi() % names.size()
	var type_name = unit_type_id
	var db = GameManager.UNIT_TYPE_DB
	if db and db.has(unit_type_id):
		type_name = db[unit_type_id].display_name
	return names[idx] + type_name

func get_state_name() -> String:
	match get_state():
		STATE_BROKEN: return "溃败"
		STATE_CONFUSED: return "混乱"
		STATE_NORMAL: return "正常"
		STATE_ELEVATED: return "高昂"
		STATE_FRENZIED: return "狂热"
		_: return "正常"

func get_state() -> int:
	if morale <= 0: return STATE_BROKEN
	if morale <= 20: return STATE_CONFUSED
	if morale <= 70: return STATE_NORMAL
	if morale <= 90: return STATE_ELEVATED
	return STATE_FRENZIED

func get_hit_modifier() -> int:
	match get_state():
		STATE_BROKEN: return -30
		STATE_CONFUSED: return -15
		STATE_ELEVATED: return 10
		STATE_FRENZIED: return 20
	return 0

func get_damage_modifier() -> float:
	match get_state():
		STATE_BROKEN: return 0.5
		STATE_CONFUSED: return 0.8
		STATE_ELEVATED: return 1.15
		STATE_FRENZIED: return 1.3
	return 1.0

func get_suppression_damage_bonus_range() -> float:
	var lower = -20 - suppression * 0.2
	var upper = 20 - suppression * 0.5
	return randi() % int(upper - lower) + lower

func apply_morale(delta: int):
	morale = clampi(morale + delta, 0, max_morale)

func apply_suppression(delta: int):
	suppression = clampi(suppression + delta, 0, 100)

func get_total_hp() -> int:
	var total = 0
	for m in members:
		if m.is_alive: total += m.hp
	return total

func get_max_hp() -> int:
	var total = 0
	for m in members: total += m.max_hp
	return total

func get_alive_count() -> int:
	var c = 0
	for m in members:
		if m.is_alive: c += 1
	return c

func get_total_count() -> int:
	return members.size()

func get_move_range() -> int:
	if has_acted: return 0
	if get_state() == STATE_BROKEN: return 0
	return ap

func can_afford(cost: int) -> bool:
	return ap >= cost

func spend_ap(cost: int) -> void:
	ap = max(0, ap - cost)

func reset_ap() -> void:
	ap = max_ap

func get_remaining_movement_ap() -> int:
	return ap

func get_weapon_summary() -> String:
	var c = {}
	for m in members:
		if not m.is_alive: continue
		for w in m.weapons:
			var n = w.get("name", "?")
			c[n] = c.get(n, 0) + 1
	var r = []
	for k in c: r.append(str(c[k]) + "x" + k)
	return ", ".join(r)

func _ready():
	_ensure_visual()
	_update_position()

func _ensure_visual():
	if _sprite: return
	_create_visual()
	_update_visual()

func _create_visual():
	_sprite = Polygon2D.new()
	_sprite.polygon = HexUtil.hex_corners(Vector2.ZERO, 20)
	_sprite.color = _team_color()
	_sprite.z_index = 1
	add_child(_sprite)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 8)
	_label.size = Vector2(56, 48)
	_label.position = Vector2(-28, -24)
	_label.z_index = 3
	add_child(_label)

	_done_label = Label.new()
	_done_label.text = "E"
	_done_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_done_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_done_label.add_theme_font_size_override("font_size", 14)
	_done_label.add_theme_color_override("font_color", Color(1, 1, 0))
	_done_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_done_label.add_theme_constant_override("outline_size", 2)
	_done_label.size = Vector2(20, 20)
	_done_label.position = Vector2(14, -24)
	_done_label.z_index = 4
	_done_label.hide()
	add_child(_done_label)

func _team_color() -> Color:
	var col = Color(0.3, 0.7, 0.3) if team == 0 else Color(0.7, 0.2, 0.2)
	if get_state() == STATE_BROKEN:
		col = Color(0.3, 0.3, 0.3)
	elif get_state() == STATE_FRENZIED:
		col = Color(1.0, 0.5, 0.0) if team == 0 else Color(0.9, 0.1, 0.1)
	return col

func update_visual():
	if not is_alive: return
	_update_visual()

func _update_visual():
	if not is_alive: return
	if _sprite:
		_sprite.color = _team_color()
	if _label:
		_label.text = (squad_name if squad_name else "部队") + "\n" + str(get_alive_count()) + "/" + str(get_total_count())
	if _done_label:
		_done_label.visible = has_acted

func _update_position():
	var mn = GameManager.hex_map
	if mn: position = mn.hex_to_pixel(hex_coord)

func move_to(new_hex: Vector2i):
	hex_coord = new_hex
	_update_position()

func take_damage(amount: int) -> int:
	if members.is_empty(): return 0
	var alive = []
	for m in members:
		if m.is_alive: alive.append(m)
	if alive.is_empty(): return 0
	var t = alive[randi() % alive.size()]
	t.take_damage(amount)
	if get_alive_count() <= 0:
		is_alive = false
		_destroy_visual()
	else:
		_update_visual()
	return amount

func _find_weakest():
	var w = null
	var l = 999
	for m in members:
		if m.is_alive and m.hp < l:
			l = m.hp; w = m
	if w == null:
		for m in members:
			if m.is_alive: w = m; break
	return w

func _destroy_visual():
	if _sprite: _sprite.hide()
	if _label: _label.hide()
	if _done_label: _done_label.hide()

func has_ammo() -> bool:
	for m in members:
		if m.is_alive and m.has_weapon(""):
			return true
	return false

func get_total_ammo() -> int:
	var total = 0
	for m in members:
		if not m.is_alive: continue
		for w in m.weapons:
			total += w.get("ammo", 0)
	return total

func get_max_ammo() -> int:
	var total = 0
	for m in members:
		if not m.is_alive: continue
		for w in m.weapons:
			total += w.get("max_ammo", w.get("ammo", 0))
	return total

func needs_supply() -> bool:
	for m in members:
		if m.is_alive and m.needs_supply():
			return true
	return false

func resupply() -> void:
	for m in members:
		if m.is_alive:
			m.resupply_weapons()

func is_near_supply_source() -> bool:
	var mn = GameManager.hex_map
	if not mn: return false
	var tid = mn.terrain_grid.get(hex_coord, "plain")
	if tid == "hq" or tid == "factory": return true
	for nb in HexUtil.hex_neighbors(hex_coord):
		var nt = mn.terrain_grid.get(nb, "plain")
		if nt == "hq" or nt == "factory": return true
		var sq = GameManager.get_squad_at(nb)
		if sq and sq.team == team and sq.is_alive and sq.unit_type_id == "transport":
			return true
	return false

func can_attack(target) -> bool:
	if not target or not target.is_alive: return false
	if target.team == team: return false
	if has_acted: return false
	if get_state() == STATE_BROKEN: return false
	if not can_afford(2): return false
	if not has_ammo(): return false
	var d = HexUtil.hex_distance(hex_coord, target.hex_coord)
	return d >= 1 and d <= 3

func clampi(v, lo, hi):
	if v < lo: return lo
	if v > hi: return hi
	return v
