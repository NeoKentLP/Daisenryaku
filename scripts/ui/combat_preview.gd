extends CanvasLayer

var attacker = null
var target = null
var callback = null
var weapon_groups: Dictionary = {}
var selected_types: Array = []

func _ready():
	hide()

func open(atk, def, confirm_callback):
	attacker = atk
	target = def
	callback = confirm_callback
	_build_panel()
	show()

func close():
	for c in get_children(): c.queue_free()
	hide()
	attacker = null
	target = null
	callback = null

func _bold_font():
	var f = SystemFont.new()
	f.font_weight = 700
	return f

func _make_bg() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.039, 0.039, 0.098, 0.97)
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(1, 1, 1, 0.2))
	return sb

func _estimate_hit_rate(atk_member, weapon, atk_squad, def_squad) -> int:
	var base = atk_member.bs
	base += weapon.get("bs_bonus", 0)
	base += atk_squad.get_hit_modifier()
	var dist = HexUtil.hex_distance(atk_squad.hex_coord, def_squad.hex_coord)
	if dist > weapon.get("range_max", 1) or dist < weapon.get("range_min", 0):
		return 0
	# Distance falloff
	if dist >= 4: base -= 15
	elif dist >= 3: base -= 10
	elif dist >= 2: base -= 5
	# Target defense
	for m in def_squad.members:
		if m.is_alive:
			if m.member_type in ["vehicle", "air"]:
				base -= m.evasion
			else:
				base -= m.concealment
			break
	# Suppression penalty
	if atk_squad.suppression > 50: base -= 5
	if atk_squad.suppression > 80: base -= 10
	# ZOC
	var mn = GameManager.hex_map
	if mn and mn.has_enemy_zoc(atk_squad.hex_coord, atk_squad.team):
		base -= 10
	if base < 5: return 5
	if base > 95: return 95
	return base

func _estimate_damage(weapon, def_squad) -> int:
	var base = weapon.get("base_damage", 15)
	var pen = weapon.get("penetration", weapon.get("armor_piercing", 0))
	var def_armor = 0
	for m in def_squad.members:
		if m.is_alive and m.armor > def_armor: def_armor = m.armor
	# Check penetration probability
	var diff = pen - def_armor
	var pen_chance = 0
	if diff >= 3: pen_chance = 100
	elif diff == 2: pen_chance = 90
	elif diff == 1: pen_chance = 70
	elif diff == 0: pen_chance = 50
	elif diff == -1: pen_chance = 20
	elif diff == -2: pen_chance = 5
	else: pen_chance = 0
	if pen_chance <= 0: return 1
	# Estimate: base × 80% (conservative) × cover
	return base * 80 / 100

func _build_panel():
	if not attacker or not target: return

	var screen = get_viewport().size

	var blocker = ColorRect.new()
	blocker.color = Color(0, 0, 0, 0)
	blocker.size = screen
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(blocker)

	var panel = Panel.new()
	panel.position = Vector2(screen.x / 2 - 250, screen.y / 2 - 220)
	panel.size = Vector2(500, 440)
	panel.add_theme_stylebox_override("panel", _make_bg())
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(16, 12)
	vbox.size = Vector2(468, 416)
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "战斗预览"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.add_theme_font_override("font", _bold_font())
	vbox.add_child(title)

	var info = Label.new()
	info.text = attacker.squad_name + "  →  " + target.squad_name
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color(0.73, 0.73, 0.73))
	vbox.add_child(info)
	vbox.add_child(_make_sep())

	var weapon_label = Label.new()
	weapon_label.text = "武器选择（点击取消可省弹药）"
	weapon_label.add_theme_font_size_override("font_size", 10)
	weapon_label.add_theme_color_override("font_color", Color(0.53, 0.53, 0.53))
	vbox.add_child(weapon_label)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 140
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var weapon_box = VBoxContainer.new()
	weapon_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_box.add_theme_constant_override("separation", 3)
	scroll.add_child(weapon_box)

	weapon_groups.clear()
	selected_types.clear()

	for m in attacker.members:
		if not m.is_alive: continue
		for w in m.weapons:
			if w.get("ammo", 0) <= 0: continue
			var dist = HexUtil.hex_distance(attacker.hex_coord, target.hex_coord)
			if dist < w.get("range_min", 1) or dist > w.get("range_max", 3): continue

			var wtype = w.get("weapon_type", w.get("name", "武器"))
			if not weapon_groups.has(wtype):
				weapon_groups[wtype] = {"weapon": w, "count": 0, "ammo": 0}
			weapon_groups[wtype]["count"] += 1
			weapon_groups[wtype]["ammo"] += w.get("ammo", 0)
			selected_types.append(wtype)

	for wtype in weapon_groups:
		var g = weapon_groups[wtype]
		var w = g["weapon"]
		var hit_rate = _estimate_hit_rate(attacker.members[0], w, attacker, target)
		var est_dmg = _estimate_damage(w, target)

		var row = HBoxContainer.new()
		var rsb = StyleBoxFlat.new()
		rsb.bg_color = Color(1, 1, 1, 0.04)
		rsb.set_corner_radius_all(4)
		rsb.set_border_width_all(1)
		rsb.set_border_color(Color(1, 1, 1, 0.08))
		row.add_theme_stylebox_override("panel", rsb)
		weapon_box.add_child(row)

		var check = CheckBox.new()
		check.button_pressed = true
		check.pressed.connect(_on_toggle_weapon.bind(wtype, check))
		row.add_child(check)

		var name_lbl = Label.new()
		name_lbl.text = w.get("name", "?") + "×" + str(g["count"])
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color", Color(0.93, 0.93, 0.93))
		row.add_child(name_lbl)

		var info_lbl = Label.new()
		info_lbl.text = "命中 " + str(hit_rate) + "%  伤 ~" + str(est_dmg)
		info_lbl.add_theme_font_size_override("font_size", 10)
		info_lbl.add_theme_color_override("font_color", Color(0.67, 0.67, 0.67))
		row.add_child(info_lbl)

		var ammo_lbl = Label.new()
		ammo_lbl.text = "弹药 " + str(g["ammo"])
		ammo_lbl.add_theme_font_size_override("font_size", 9)
		ammo_lbl.add_theme_color_override("font_color", Color(0.53, 0.53, 0.53))
		row.add_child(ammo_lbl)

	vbox.add_child(_make_sep())

	var total_dmg = 0
	for g in weapon_groups.values():
		total_dmg += _estimate_damage(g["weapon"], target) * g["count"]
	var summary = Label.new()
	summary.text = "预期总伤害 ~" + str(total_dmg)
	summary.add_theme_font_size_override("font_size", 11)
	summary.add_theme_color_override("font_color", Color(0.73, 0.73, 0.73))
	vbox.add_child(summary)

	vbox.add_spacer(true)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(120, 36)
	cancel_btn.add_theme_font_size_override("font_size", 12)
	cancel_btn.add_theme_color_override("font_color", Color(0.67, 0.67, 0.67))
	var csb = StyleBoxFlat.new()
	csb.bg_color = Color(1, 1, 1, 0.04)
	csb.set_border_width_all(1)
	csb.set_border_color(Color(1, 1, 1, 0.1))
	csb.set_corner_radius_all(4)
	cancel_btn.add_theme_stylebox_override("normal", csb)
	cancel_btn.pressed.connect(close)
	btn_row.add_child(cancel_btn)

	var confirm_btn = Button.new()
	confirm_btn.text = "确认攻击"
	confirm_btn.custom_minimum_size = Vector2(120, 36)
	confirm_btn.add_theme_font_size_override("font_size", 12)
	confirm_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	confirm_btn.add_theme_font_override("font", _bold_font())
	var ccsb = StyleBoxFlat.new()
	ccsb.bg_color = Color(0.27, 0.67, 0.53, 0.15)
	ccsb.set_border_width_all(1)
	ccsb.set_border_color(Color(0.27, 0.67, 0.53, 0.3))
	ccsb.set_corner_radius_all(4)
	confirm_btn.add_theme_stylebox_override("normal", ccsb)
	confirm_btn.pressed.connect(_on_confirm)
	btn_row.add_child(confirm_btn)

func _make_sep():
	var sep = ColorRect.new()
	sep.color = Color(1, 1, 1, 0.08)
	sep.custom_minimum_size.y = 1
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return sep

func _on_toggle_weapon(wtype: String, check: CheckBox):
	if check.button_pressed:
		if not wtype in selected_types: selected_types.append(wtype)
	else:
		selected_types.erase(wtype)

func _on_confirm():
	if callback:
		callback.call(selected_types)
	close()
