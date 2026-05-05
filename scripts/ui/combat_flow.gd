extends CanvasLayer

var result_data: Dictionary = {}
var close_callback = null

func _ready():
	hide()

func open(data: Dictionary, callback):
	result_data = data
	close_callback = callback
	_build_panel()
	show()

func close():
	for c in get_children(): c.queue_free()
	hide()
	result_data = {}
	close_callback = null

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

func _build_panel():
	var screen = get_viewport().size

	var blocker = ColorRect.new()
	blocker.color = Color(0, 0, 0, 0.3)
	blocker.size = screen
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(blocker)

	var panel = Panel.new()
	panel.position = Vector2(screen.x / 2 - 300, screen.y / 2 - 250)
	panel.size = Vector2(600, 500)
	panel.add_theme_stylebox_override("panel", _make_bg())
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 16)
	vbox.size = Vector2(560, 468)
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "战斗报告"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.add_theme_font_override("font", _bold_font())
	vbox.add_child(title)

	# Combatants
	var atk_name = result_data.get("attacker_name", "攻击方")
	var def_name = result_data.get("defender_name", "防御方")
	var combatants = Label.new()
	combatants.text = atk_name + "  →  " + def_name
	combatants.add_theme_font_size_override("font_size", 12)
	combatants.add_theme_color_override("font_color", Color(0.73, 0.73, 0.73))
	vbox.add_child(combatants)
	vbox.add_child(_make_sep())

	# Weapon hits detail
	var hits_label = Label.new()
	hits_label.text = "攻击方火力"
	hits_label.add_theme_font_size_override("font_size", 11)
	hits_label.add_theme_color_override("font_color", Color(0.27, 0.67, 0.53))
	hits_label.add_theme_font_override("font", _bold_font())
	vbox.add_child(hits_label)

	var weapon_hits = result_data.get("weapon_hits", {})
	if weapon_hits.is_empty():
		var no_hit = Label.new()
		no_hit.text = "  全部未命中"
		no_hit.add_theme_font_size_override("font_size", 10)
		no_hit.add_theme_color_override("font_color", Color(0.67, 0.67, 0.67))
		vbox.add_child(no_hit)
	else:
		for wn in weapon_hits:
			var wh = weapon_hits[wn]
			var row = HBoxContainer.new()
			var name_lbl = Label.new()
			name_lbl.text = "  " + wn
			name_lbl.add_theme_font_size_override("font_size", 10)
			name_lbl.add_theme_color_override("font_color", Color(0.93, 0.93, 0.93))
			row.add_child(name_lbl)
			var info_lbl = Label.new()
			info_lbl.text = "  命中: " + str(wh.hits) + "/" + str(wh.shots) + "  击杀: " + str(wh.kills) + "  压制: " + str(wh.suppression)
			info_lbl.add_theme_font_size_override("font_size", 10)
			info_lbl.add_theme_color_override("font_color", Color(0.67, 0.67, 0.67))
			row.add_child(info_lbl)
			vbox.add_child(row)

	var total_dmg = result_data.get("damage_to_defender", 0)
	var dmg_row = Label.new()
	dmg_row.text = "  总伤害: " + str(total_dmg)
	dmg_row.add_theme_font_size_override("font_size", 10)
	dmg_row.add_theme_color_override("font_color", Color(0.93, 0.93, 0.93))
	vbox.add_child(dmg_row)

	# Counter-attack
	var counter = result_data.get("counter_hits", 0)
	if counter > 0:
		vbox.add_child(_make_sep())
		var counter_label = Label.new()
		counter_label.text = "反击（" + def_name + "）"
		counter_label.add_theme_font_size_override("font_size", 11)
		counter_label.add_theme_color_override("font_color", Color(0.8, 0.27, 0.27))
		counter_label.add_theme_font_override("font", _bold_font())
		vbox.add_child(counter_label)
		var counter_row = Label.new()
		counter_row.text = "  命中 " + str(result_data.get("counter_hits", 0)) + "次  伤害 " + str(result_data.get("damage_to_attacker", 0))
		counter_row.add_theme_font_size_override("font_size", 10)
		counter_row.add_theme_color_override("font_color", Color(0.8, 0.27, 0.27))
		vbox.add_child(counter_row)

	# Target status
	vbox.add_child(_make_sep())
	var status_label = Label.new()
	status_label.text = "目标状态变化"
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color", Color(0.47, 0.67, 1.0))
	vbox.add_child(status_label)

	var _def_hp = result_data.get("defender_hp_before", 0)
	var _def_hp_after = result_data.get("defender_hp_after", 0)
	var def_alive = result_data.get("defender_alive_count_before", 0)
	var def_alive_after = result_data.get("defender_alive_count_after", 0)
	var status_info = Label.new()
	status_info.text = "  成员: " + str(def_alive) + "→" + str(def_alive_after)
	status_info.add_theme_font_size_override("font_size", 10)
	status_info.add_theme_color_override("font_color", Color(0.73, 0.73, 0.73))
	vbox.add_child(status_info)

	if result_data.get("defender_destroyed", false):
		var destroy_label = Label.new()
		destroy_label.text = "  ⚠ 部队已被消灭!"
		destroy_label.add_theme_font_size_override("font_size", 12)
		destroy_label.add_theme_color_override("font_color", Color(1.0, 0.33, 0.33))
		destroy_label.add_theme_font_override("font", _bold_font())
		vbox.add_child(destroy_label)

	vbox.add_spacer(true)

	# Close button
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(120, 36)
	close_btn.add_theme_font_size_override("font_size", 12)
	close_btn.add_theme_color_override("font_color", Color(0.93, 0.93, 0.93))
	var csb = StyleBoxFlat.new()
	csb.bg_color = Color(1, 1, 1, 0.06)
	csb.set_border_width_all(1)
	csb.set_border_color(Color(1, 1, 1, 0.12))
	csb.set_corner_radius_all(4)
	close_btn.add_theme_stylebox_override("normal", csb)
	close_btn.pressed.connect(_on_close)
	btn_row.add_child(close_btn)

func _make_sep():
	var sep = ColorRect.new()
	sep.color = Color(1, 1, 1, 0.08)
	sep.custom_minimum_size.y = 1
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return sep

func _on_close():
	var cb = close_callback
	close()
	if cb:
		cb.call()
