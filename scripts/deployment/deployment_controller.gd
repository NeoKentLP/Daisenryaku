extends CanvasLayer

var _panel: Panel
var _squad_list: VBoxContainer
var _info_label: Label
var _confirm_btn: Button
var _cancel_btn: Button
var _max_slots: int = 4
var _selected: Dictionary = {}
var _wd = preload("res://scripts/world/world_data.gd")

func _ready():
	_build_ui()
	hide()

func _build_ui():
	var screen = get_viewport().size

	_panel = Panel.new()
	_panel.position = Vector2(screen.x / 2 - 300, 40)
	_panel.size = Vector2(600, screen.y - 100)
	_panel.add_theme_stylebox_override("panel", _make_bg())
	add_child(_panel)

	var title = Label.new()
	title.position = Vector2(20, 16)
	title.text = "部署阶段"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	_panel.add_child(title)

	_info_label = Label.new()
	_info_label.position = Vector2(20, 50)
	_info_label.size = Vector2(560, 40)
	_info_label.add_theme_font_size_override("font_size", 12)
	_info_label.add_theme_color_override("font_color", Color(0.73, 0.73, 0.73))
	_panel.add_child(_info_label)

	var slot_label = Label.new()
	slot_label.position = Vector2(20, 90)
	slot_label.text = "出战名额: 0/" + str(_max_slots)
	slot_label.name = "SlotLabel"
	slot_label.add_theme_font_size_override("font_size", 13)
	slot_label.add_theme_color_override("font_color", Color(0.47, 0.67, 1.0))
	_panel.add_child(slot_label)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(20, 115)
	scroll.size = Vector2(560, screen.y - 260)
	_panel.add_child(scroll)

	_squad_list = VBoxContainer.new()
	_squad_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_squad_list.custom_minimum_size.x = 540
	scroll.add_child(_squad_list)

	_confirm_btn = Button.new()
	_confirm_btn.position = Vector2(screen.x / 2 - 300 + 400, screen.y - 130)
	_confirm_btn.size = Vector2(100, 36)
	_confirm_btn.text = "出击!"
	_confirm_btn.disabled = true
	_confirm_btn.pressed.connect(_on_confirm)
	_panel.add_child(_confirm_btn)

	_cancel_btn = Button.new()
	_cancel_btn.position = Vector2(screen.x / 2 - 300 + 510, screen.y - 130)
	_cancel_btn.size = Vector2(80, 36)
	_cancel_btn.text = "撤退"
	_cancel_btn.pressed.connect(_on_cancel)
	_panel.add_child(_cancel_btn)

func _make_bg():
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.039, 0.039, 0.098, 0.97)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(1, 1, 1, 0.2))
	return sb

func open():
	_selected.clear()
	_refresh_list()
	var nd = GameManager.world_encounter_node
	if nd:
		_info_label.text = "遭遇: " + nd["name"] + "  (" + _wd.get_hub_display(nd["type"]) + ")"
	show()

func close():
	hide()

func _refresh_list():
	for c in _squad_list.get_children():
		c.queue_free()

	var slot_label = _panel.get_node("SlotLabel")
	if slot_label:
		slot_label.text = "出战名额: " + str(_selected.size()) + "/" + str(_max_slots)

	for sq in GameManager.player_squads:
		if not sq.is_alive: continue
		var row = _make_squad_row(sq)
		_squad_list.add_child(row)

func _make_squad_row(squad) -> Panel:
	var row = Panel.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.04)
	sb.set_corner_radius_all(4)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(1, 1, 1, 0.08))
	row.add_theme_stylebox_override("panel", sb)
	row.custom_minimum_size.y = 36

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("margin_left", 8)
	hbox.add_theme_constant_override("margin_right", 8)
	hbox.add_theme_constant_override("margin_top", 4)
	hbox.add_theme_constant_override("margin_bottom", 4)
	row.add_child(hbox)

	var name_lbl = Label.new()
	name_lbl.text = squad.squad_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color(0.93, 0.93, 0.93))
	hbox.add_child(name_lbl)

	var info_lbl = Label.new()
	var hp = str(squad.get_alive_count()) + "/" + str(squad.get_total_count())
	var cmd = GameManager.get_commander(squad)
	var cmd_str = cmd.commander_name if cmd else "无指挥官"
	info_lbl.text = hp + "  " + cmd_str
	info_lbl.add_theme_font_size_override("font_size", 10)
	info_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hbox.add_child(info_lbl)

	var check = CheckBox.new()
	check.toggle_mode = true
	check.disabled = (cmd == null)
	check.button_pressed = _selected.has(squad.squad_name)
	if not check.disabled:
		check.pressed.connect(_on_toggle.bind(squad))
	else:
		check.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		var reason = Label.new()
		reason.text = "需指挥官"
		reason.add_theme_font_size_override("font_size", 8)
		reason.add_theme_color_override("font_color", Color(1.0, 0.53, 0.53))
		hbox.add_child(reason)
	hbox.add_child(check)

	return row

func _on_toggle(squad):
	if _selected.has(squad.squad_name):
		_selected.erase(squad.squad_name)
	else:
		if _selected.size() >= _max_slots: return
		_selected[squad.squad_name] = squad
	_refresh_list()
	_confirm_btn.disabled = _selected.is_empty()

func _on_confirm():
	if _selected.is_empty(): return
	GameManager.world_selected_squads = _selected.values()
	close()
	var wc = get_node_or_null("/root/World")
	if wc:
		wc.trigger_battle()

func _on_cancel():
	close()
	var nd = GameManager.world_encounter_node
	if nd and _wd.is_enemy_hub(nd["type"]):
		var wc = get_node_or_null("/root/World")
		if wc:
			wc.return_to_world()
