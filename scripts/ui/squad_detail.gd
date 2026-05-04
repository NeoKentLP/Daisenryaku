extends Panel

var _squad = null
var _scroll_left: ScrollContainer
var _scroll_right: ScrollContainer
var _close_btn: Button
var _content: Node

func _ready():
	mouse_filter = MOUSE_FILTER_STOP
	hide()

func open(squad):
	if not squad or not squad.is_alive:
		hide()
		return
	_squad = squad
	_build()
	show()

func close():
	hide()
	_squad = null

func _build():
	for c in get_children():
		c.queue_free()
	if not _squad: return

	var screen = get_viewport().size
	size = Vector2(640, min(520, screen.y - 80))
	position = Vector2((screen.x - size.x) / 2, 40)
	add_theme_stylebox_override("panel", _make_bg())

	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	add_child(vbox)

	_build_header(vbox)
	_build_body(vbox)

func _make_bg():
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.039, 0.039, 0.098, 0.97)
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(1, 1, 1, 0.2))
	return sb

func _build_header(parent: VBoxContainer):
	var hdr = HBoxContainer.new()
	hdr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_theme_constant_override("separation", 0)
	parent.add_child(hdr)

	var title = Label.new()
	title.text = _squad.squad_name + "  "
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	hdr.add_child(title)

	var type_tag = Label.new()
	type_tag.text = _get_type_tag_text()
	type_tag.add_theme_font_size_override("font_size", 10)
	type_tag.add_theme_color_override("font_color", Color(1, 1, 1))
	var tsb = StyleBoxFlat.new()
	tsb.bg_color = _get_type_tag_color()
	tsb.set_corner_radius_all(3)
	type_tag.add_theme_stylebox_override("normal", tsb)
	hdr.add_child(type_tag)

	hdr.add_stretch_ratio(1.0)

	_close_btn = Button.new()
	_close_btn.text = "✕ 关闭"
	_close_btn.add_theme_font_size_override("font_size", 10)
	_close_btn.pressed.connect(close)
	hdr.add_child(_close_btn)

	var sep = HSeparator.new()
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sep.add_theme_color_override("color", Color(1, 1, 1, 0.1))
	parent.add_child(sep)

func _get_type_tag_text() -> String:
	var db = GameManager.UNIT_TYPE_DB
	if db and db.has(_squad.unit_type_id):
		return db[_squad.unit_type_id].display_name
	return _squad.unit_type_id

func _get_type_tag_color() -> Color:
	match _squad.unit_type_id:
		"infantry": return Color(0.27, 0.67, 0.53)
		"tank": return Color(0.6, 0.4, 0.2)
		"artillery": return Color(0.67, 0.27, 0.27)
		"recon": return Color(0.27, 0.53, 0.67)
		"engineer": return Color(0.8, 0.6, 0.2)
		_: return Color(0.4, 0.4, 0.4)

func _build_body(parent: VBoxContainer):
	var body = HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 0)
	parent.add_child(body)

	_scroll_left = ScrollContainer.new()
	_scroll_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_scroll_left)

	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_left.add_child(left)

	_build_props(left)
	_build_modifiers(left)
	_build_skills(left)
	_build_member_hp(left)
	_build_weapons(left)

	var right_sep = VSeparator.new()
	right_sep.add_theme_color_override("color", Color(1, 1, 1, 0.08))
	right_sep.custom_minimum_size.x = 1
	body.add_child(right_sep)

	_scroll_right = ScrollContainer.new()
	_scroll_right.custom_minimum_size.x = 165
	_scroll_right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_scroll_right)

	var right = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_right.add_child(right)

	_build_commander(right)

func _section(parent: VBoxContainer, title: String) -> VBoxContainer:
	var lbl = Label.new()
	lbl.text = "■ " + title
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.47, 0.67, 1.0))
	lbl.add_theme_constant_override("margin_top", 8)
	parent.add_child(lbl)

	var sep = HSeparator.new()
	sep.add_theme_color_override("color", Color(1, 1, 1, 0.07))
	parent.add_child(sep)

	var box = VBoxContainer.new()
	parent.add_child(box)
	return box

func _build_props(parent: VBoxContainer):
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	_make_prop(row, "士气", str(_squad.morale) + "/" + str(_squad.max_morale))
	var badge = Label.new()
	badge.text = _squad.get_state_name()
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", Color(1, 1, 1))
	var bs = StyleBoxFlat.new()
	bs.bg_color = _morale_color()
	bs.set_corner_radius_all(3)
	badge.add_theme_stylebox_override("normal", bs)
	row.add_child(badge)

	_make_prop(row, "压制", str(_squad.suppression) + "/100")
	var ap_container = HBoxContainer.new()
	var ap_lbl = Label.new()
	ap_lbl.text = "AP "
	ap_lbl.add_theme_font_size_override("font_size", 11)
	ap_lbl.add_theme_color_override("font_color", Color(0.53, 0.53, 0.53))
	ap_container.add_child(ap_lbl)
	for i in range(_squad.max_ap):
		var dot = Label.new()
		dot.text = "●"
		dot.add_theme_font_size_override("font_size", 13)
		dot.add_theme_color_override("font_color", Color(0.27, 0.8, 0.27) if i < _squad.ap else Color(0.27, 0.27, 0.27))
		dot.add_theme_constant_override("margin_left", -2)
		ap_container.add_child(dot)
	var ap_txt = Label.new()
	ap_txt.text = " " + str(_squad.ap) + "/" + str(_squad.max_ap)
	ap_txt.add_theme_font_size_override("font_size", 11)
	ap_txt.add_theme_color_override("font_color", Color(0.93, 0.93, 0.93))
	ap_container.add_child(ap_txt)
	row.add_child(ap_container)
	_make_prop(row, "状态", _action_status())

func _morale_color() -> Color:
	match _squad.get_state():
		_squad.STATE_BROKEN: return Color(0.53, 0.27, 0.27)
		_squad.STATE_CONFUSED: return Color(0.53, 0.4, 0.27)
		_squad.STATE_NORMAL: return Color(0.27, 0.53, 0.27)
		_squad.STATE_ELEVATED: return Color(0.53, 0.53, 0.27)
		_squad.STATE_FRENZIED: return Color(0.8, 0.53, 0.0)
	return Color(0.27, 0.53, 0.27)

func _action_status() -> String:
	if _squad.has_acted: return "已行动"
	if _squad.has_ammo(): return "未行动"
	return "弹药耗尽"

func _make_prop(parent: HBoxContainer, label: String, value: String):
	var c = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label + " "
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.53, 0.53, 0.53)
)
	c.add_child(lbl)
	var val = Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 11)
	val.add_theme_color_override("font_color", Color(0.93, 0.93, 0.93))
	c.add_child(val)
	parent.add_child(c)

func _build_modifiers(parent: VBoxContainer):
	var box = _section(parent, "战况修正")

	var sum_row = HBoxContainer.new()
	sum_row.add_theme_constant_override("separation", 12)
	var sum_bg = StyleBoxFlat.new()
	sum_bg.bg_color = Color(1, 1, 1, 0.04)
	sum_bg.set_corner_radius_all(6)
	sum_row.add_theme_stylebox_override("panel", sum_bg)
	box.add_child(sum_row)

	var hit_mod = _squad.get_hit_modifier()
	_make_summary(sum_row, "命中", ("> " if hit_mod > 0 else "") + str(hit_mod) + "%", Color(1, 0.53, 0.53) if hit_mod < 0 else Color(0.53, 1, 0.53))

	var dmg_mod = _squad.get_damage_modifier()
	var dmg_pct = int((dmg_mod - 1.0) * 100)
	_make_summary(sum_row, "伤害", ("> " if dmg_pct > 0 else "") + str(dmg_pct) + "%", Color(0.53, 1, 0.53) if dmg_pct > 0 else Color(1, 0.53, 0.53) if dmg_pct < 0 else Color(0.93, 0.93, 0.93))

	var sup_range = _squad.get_suppression_damage_bonus_range()
	_make_summary(sum_row, "压制波动", str(int(sup_range)) + "%", Color(1, 0.53, 0.53))

	var mn = GameManager.hex_map
	if mn and mn.has_enemy_zoc(_squad.hex_coord, _squad.team):
		_make_summary(sum_row, "ZOC压制", "+5/回合", Color(1, 0.53, 0.53))

	var factors = HBoxContainer.new()
	factors.add_theme_constant_override("separation", 4)
	box.add_child(factors)

	var terrain_tid = "plain"
	if mn: terrain_tid = mn.terrain_grid.get(_squad.hex_coord, "plain")
	match terrain_tid:
		"city": _make_factor(factors, "城市", "-15%")
		"forest": _make_factor(factors, "森林", "-10%")
		"mountain": _make_factor(factors, "山地", "-20%")
		"river": _make_factor(factors, "河流", "-5%")

	if mn and mn.has_overlay(_squad.hex_coord):
		var ov = mn.get_overlay(_squad.hex_coord)
		if ov == "trench": _make_factor(factors, "战壕", "+4防")
		if ov == "bunker": _make_factor(factors, "堡垒", "+6防")

	if mn and mn.has_enemy_zoc(_squad.hex_coord, _squad.team):
		_make_factor(factors, "ZOC", "-10%")

func _make_summary(parent: HBoxContainer, label: String, value: String, color: Color):
	var c = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label + " "
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.53, 0.53, 0.53))
	c.add_child(lbl)
	var val = Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 10)
	val.add_theme_color_override("font_color", color)
	c.add_child(val)
	parent.add_child(c)

func _make_factor(parent: HBoxContainer, name: String, value: String):
	var btn = HBoxContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.05)
	sb.set_corner_radius_all(4)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(1, 1, 1, 0.08))
	btn.add_theme_stylebox_override("panel", sb)
	var lbl = Label.new()
	lbl.text = name
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.87, 0.87, 0.87))
	btn.add_child(lbl)
	var val = Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 9)
	var vc = Color(1, 0.53, 0.53) if value.begins_with("-") else Color(0.53, 1, 0.53) if value.begins_with("+") else Color(0.87, 0.87, 0.87)
	val.add_theme_color_override("font_color", vc)
	btn.add_child(val)
	parent.add_child(btn)

func _build_skills(parent: VBoxContainer):
	var has_skill = false
	for m in _squad.members:
		if m.is_alive and m.skill_name:
			has_skill = true
			break
	if not has_skill: return

	var box = _section(parent, "部队技能")
	var grid = HBoxContainer.new()
	grid.add_theme_constant_override("separation", 4)
	box.add_child(grid)

	for m in _squad.members:
		if m.is_alive and m.skill_name:
			var sk = HBoxContainer.new()
			var sb = StyleBoxFlat.new()
			sb.bg_color = Color(1, 1, 1, 0.06)
			sb.set_corner_radius_all(4)
			sb.set_border_width_all(1)
			sb.set_border_color(Color(1, 1, 1, 0.1))
			sk.add_theme_stylebox_override("panel", sb)

			var ap = Label.new()
			if m.skill_ap > 0:
				ap.text = str(m.skill_ap) + "AP "
				ap.add_theme_color_override("font_color", Color(0.27, 0.8, 0.27))
			else:
				ap.text = "被动 "
				ap.add_theme_color_override("font_color", Color(0.53, 0.73, 1.0))
			ap.add_theme_font_size_override("font_size", 9)
			sk.add_child(ap)

			var name = Label.new()
			name.text = m.skill_name
			name.add_theme_font_size_override("font_size", 9)
			name.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			sk.add_child(name)

			grid.add_child(sk)

func _build_member_hp(parent: VBoxContainer):
	if _squad.members.is_empty(): return
	var total = _squad.get_total_count()
	var alive = _squad.get_alive_count()

	var box = _section(parent, "成员列表 (" + str(alive) + "/" + str(total) + ")")

	_render_hp_grid(box, _squad.members)

func _render_hp_grid(parent: VBoxContainer, members: Array):
	var cols = 5
	var row_count = ceili(members.size() / float(cols))
	for ri in range(row_count):
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		parent.add_child(row)
		for ci in range(cols):
			var idx = ri * cols + ci
			if idx >= members.size(): break
			var m = members[idx]

			var cell = Panel.new()
			cell.custom_minimum_size.x = 50
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
			var csb = StyleBoxFlat.new()
			csb.bg_color = Color(1, 1, 1, 0.06)
			csb.set_corner_radius_all(3)
			cell.add_theme_stylebox_override("panel", csb)
			row.add_child(cell)

			var fill = ColorRect.new()
			fill.anchor_right = 1.0
			fill.anchor_bottom = 1.0
			var fill_pct = float(m.hp) / m.max_hp if m.max_hp > 0 else 0
			fill.size = cell.size * Vector2(1, 1)
			if not m.is_alive:
				fill.color = Color(0.2, 0.2, 0.2, 0.4)
			elif fill_pct > 0.6:
				fill.color = Color(0.2, 0.67, 0.2)
			elif fill_pct > 0.3:
				fill.color = Color(0.8, 0.67, 0.27)
			else:
				fill.color = Color(0.8, 0.27, 0.27)
			cell.add_child(fill)

			var txt = Label.new()
			txt.text = str(m.hp) + "/" + str(m.max_hp)
			txt.anchor_right = 1.0
			txt.anchor_bottom = 1.0
			txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			txt.add_theme_font_size_override("font_size", 8)
			txt.add_theme_color_override("font_color", Color(1, 1, 1) if m.is_alive else Color(0.33, 0.33, 0.33))
			cell.add_child(txt)

			# Resize fill when cell size changes
			var resizer = func():
				fill.size = cell.size
			cell.resized.connect(resizer)

func _build_weapons(parent: VBoxContainer):
	var weapon_groups = {}
	for m in _squad.members:
		if not m.is_alive: continue
		for w in m.weapons:
			var wn = w.get("name", "?")
			if not weapon_groups.has(wn):
				weapon_groups[wn] = {"weapon": w, "count": 0}
			weapon_groups[wn]["count"] += 1

	if weapon_groups.is_empty(): return

	var box = _section(parent, "武器装备")

	for wn in weapon_groups:
		var g = weapon_groups[wn]
		var w = g["weapon"]

		var group = Panel.new()
		var gsb = StyleBoxFlat.new()
		gsb.bg_color = Color(1, 1, 1, 0.03)
		gsb.set_corner_radius_all(5)
		gsb.set_border_width_all(1)
		gsb.set_border_color(Color(1, 1, 1, 0.06))
		group.add_theme_stylebox_override("panel", gsb)
		box.add_child(group)

		var gv = VBoxContainer.new()
		gv.add_theme_constant_override("margin_left", 8)
		gv.add_theme_constant_override("margin_right", 8)
		gv.add_theme_constant_override("margin_top", 5)
		gv.add_theme_constant_override("margin_bottom", 5)
		group.add_child(gv)

		var name = HBoxContainer.new()
		var n = Label.new()
		n.text = wn + "  "
		n.add_theme_font_size_override("font_size", 11)
		n.add_theme_color_override("font_color", Color(1, 1, 1))
		name.add_child(n)
		var cnt = Label.new()
		cnt.text = "×" + str(g["count"])
		cnt.add_theme_font_size_override("font_size", 9)
		cnt.add_theme_color_override("font_color", Color(0.53, 0.53, 0.53))
		name.add_child(cnt)
		gv.add_child(name)

		var stats = HBoxContainer.new()
		stats.add_theme_constant_override("separation", 8)
		gv.add_child(stats)

		_make_weapon_stat(stats, "伤", str(w.get("damage_vs", {}).get("infantry", 0)))
		_make_weapon_stat(stats, "穿", str(w.get("armor_piercing", 0)))
		_make_weapon_stat(stats, "射程", str(w.get("range_min", 1)) + "-" + str(w.get("range_max", 3)))
		_make_weapon_stat(stats, "命中", str(60 + w.get("bs_bonus", 0)) + "%")
		_make_weapon_stat(stats, "弹药", str(w.get("ammo", 0)) + "/" + str(w.get("max_ammo", 0)))
		var sup = w.get("suppression", 0)
		if sup > 0:
			_make_weapon_stat(stats, "压制", str(sup))

		# CQB优势标签
		var w_name = w.get("name", "")
		var cqb_weapons = ["MP40", "冲锋枪", "手枪", "smg"]
		var is_cqb = false
		for c in cqb_weapons:
			if c.to_lower() in w_name.to_lower():
				is_cqb = true
				break
		if is_cqb:
			var cqb_lbl = Label.new()
			cqb_lbl.text = "CQB优势"
			cqb_lbl.add_theme_font_size_override("font_size", 10)
			cqb_lbl.add_theme_color_override("font_color", Color(0.27, 0.67, 0.27))
			stats.add_child(cqb_lbl)

func _make_weapon_stat(parent: HBoxContainer, label: String, value: String):
	var lbl = Label.new()
	lbl.text = label + " " + value
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.67, 0.67, 0.67))
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.04)
	sb.set_corner_radius_all(2)
	lbl.add_theme_stylebox_override("normal", sb)
	parent.add_child(lbl)

func _build_commander(parent: VBoxContainer):
	var cmd = GameManager.get_commander(_squad)
	if not cmd: return

	_section(parent, "指挥官")

	var block = Panel.new()
	var bsb = StyleBoxFlat.new()
	bsb.bg_color = Color(1, 1, 0.78, 0.04)
	bsb.set_corner_radius_all(6)
	bsb.set_border_width_all(1)
	bsb.set_border_color(Color(1, 1, 0.78, 0.1))
	block.add_theme_stylebox_override("panel", bsb)
	parent.add_child(block)

	var bv = VBoxContainer.new()
	bv.add_theme_constant_override("margin_left", 6)
	bv.add_theme_constant_override("margin_right", 6)
	bv.add_theme_constant_override("margin_top", 8)
	bv.add_theme_constant_override("margin_bottom", 6)
	bv.add_theme_constant_override("separation", 4)
	block.add_child(bv)

	var portrait = Panel.new()
	portrait.custom_minimum_size = Vector2(48, 64)
	var psb = StyleBoxFlat.new()
	psb.bg_color = Color(1, 1, 1, 0.08)
	psb.set_corner_radius_all(4)
	portrait.add_theme_stylebox_override("panel", psb)

	var pi = Label.new()
	pi.anchor_right = 1.0
	pi.anchor_bottom = 1.0
	pi.text = "🎖"
	pi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pi.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pi.add_theme_font_size_override("font_size", 20)
	portrait.add_child(pi)

	var portrait_container = HBoxContainer.new()
	portrait_container.add_child(portrait)
	bv.add_child(portrait_container)

	var name = Label.new()
	name.text = cmd.commander_name
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override("font_size", 11)
	name.add_theme_color_override("font_color", Color(1, 0.93, 0.53))
	bv.add_child(name)

	var lvl = Label.new()
	var exp_needed = 999
	var exp_table = [0, 100, 200, 350, 550, 800, 1100, 1500, 2000, 3000]
	if cmd.level < 10: exp_needed = exp_table[cmd.level]
	var exp_display = "Lv." + str(cmd.level)
	if cmd.level < 10: exp_display += " · " + str(cmd._exp) + "/" + str(exp_needed)
	lvl.text = exp_display
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl.add_theme_font_size_override("font_size", 9)
	lvl.add_theme_color_override("font_color", Color(0.53, 0.73, 1.0))
	bv.add_child(lvl)

	var sep = HSeparator.new()
	sep.add_theme_color_override("color", Color(1, 1, 1, 0.06))
	bv.add_child(sep)

	var skills = VBoxContainer.new()
	skills.add_theme_constant_override("separation", 3)
	bv.add_child(skills)

	_make_cmd_skill(skills, "背景", cmd.background_skill, Color(0.33, 0.8, 0.33))
	_make_cmd_skill(skills, "天赋", cmd.talent_skill, Color(0.4, 0.53, 1.0))
	for s in cmd.quality_skills:
		_make_cmd_skill(skills, "品质", s, Color(1.0, 0.67, 0.4))
	for s in cmd.level_skills:
		_make_cmd_skill(skills, "升级", s, Color(1.0, 1.0, 0.4))

func _make_cmd_skill(parent: VBoxContainer, label: String, skill: String, color: Color):
	var c = HBoxContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.06)
	sb.set_corner_radius_all(4)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(1, 1, 1, 0.1))
	c.add_theme_stylebox_override("panel", sb)
	parent.add_child(c)

	var lbl = Label.new()
	lbl.text = " " + label + " "
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", color)
	c.add_child(lbl)

	var name = Label.new()
	name.text = " " + skill
	name.add_theme_font_size_override("font_size", 9)
	name.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	c.add_child(name)
