extends CanvasLayer

var nation: String = "germany"
var deployable_hexes: Array = []
var placed_squads: Dictionary = {}  # hex -> squad_data
var selected_unit_idx: int = -1
var unit_list: Array = []
var unit_defs: Array = []

var _hex_size: float = 40.0
var _offset_x: float = 0
var _offset_y: float = 0
var _grid_nodes: Dictionary = {}  # Vector2i -> Polygon2D
var _placed_nodes: Dictionary = {}  # Vector2i -> Node2D
var _list_panel: Panel
var _list_container: VBoxContainer
var _info_label: Label
var _confirm_btn: Button
var _deploy_terrain: Dictionary = {}  # hex -> terrain_id

func _ready():
	nation = GameManager.selected_nation
	var loader = preload("res://scripts/core/unit_loader.gd").new()
	loader.ensure_loaded()
	unit_defs = []
	var starting = loader.get_starting_units(nation)
	for i in range(starting.size()):
		var u = starting[i]
		unit_defs.append({"id": u.id, "type": u.type, "name": u.name, "members": u.members})
	if unit_defs.is_empty():
		_generate_unit_defs()
	_generate_unit_list()
	_build_ui()

func _generate_unit_defs():
	var wd = preload("res://scripts/core/weapon_data.gd")
	var ms = preload("res://scripts/core/member.gd")

	if nation == "germany":
		unit_defs = [
			{"id": "ger_inf_1", "type": "infantry", "name": "第一步兵班", "members": _make_infantry_squad(wd, ms)},
			{"id": "ger_inf_2", "type": "infantry", "name": "第二步兵班", "members": _make_infantry_squad(wd, ms)},
			{"id": "ger_recon", "type": "vehicle", "name": "Sd.Kfz 221", "members": _make_recon_car(wd, ms)},
			{"id": "ger_mortar", "type": "artillery", "name": "81mm迫击炮班", "members": _make_mortar_squad(wd, ms)},
		]
	else:
		unit_defs = [
			{"id": "sov_inf_1", "type": "infantry", "name": "第一步兵班", "members": _make_infantry_squad(wd, ms)},
			{"id": "sov_inf_2", "type": "infantry", "name": "第二步兵班", "members": _make_infantry_squad(wd, ms)},
			{"id": "sov_recon", "type": "vehicle", "name": "BA-20装甲车", "members": _make_sov_recon_car(wd, ms)},
			{"id": "sov_mortar", "type": "artillery", "name": "82mm迫击炮", "members": _make_sov_mortar(wd, ms)},
		]

static func _make_infantry_squad(wd, ms) -> Array:
	var m = []
	m.append(ms.new("班长", "infantry", 12, 60, wd.rifle()))
	for i in range(4): m.append(ms.new("步枪手", "infantry", 10, 60, wd.rifle()))
	m.append(ms.new("机枪手", "infantry", 12, 55, wd.mg()))
	return m

static func _make_recon_car(wd, ms) -> Array:
	var m = []
	var crew = ms.new("车长", "vehicle", 15, 50, wd.rifle())
	crew.armor = 6
	m.append(crew)
	crew = ms.new("驾驶员", "vehicle", 12, 50, wd.rifle())
	crew.armor = 6
	m.append(crew)
	return m

static func _make_sov_recon_car(wd, ms) -> Array:
	var m = []
	var crew = ms.new("车长", "vehicle", 14, 50, wd.rifle())
	crew.armor = 5
	m.append(crew)
	crew = ms.new("驾驶员", "vehicle", 10, 50, wd.rifle())
	crew.armor = 5
	m.append(crew)
	return m

static func _make_mortar_squad(wd, ms) -> Array:
	var m = []
	m.append(ms.new("炮长", "infantry", 10, 55, wd.pistol()))
	m.append(ms.new("炮手", "infantry", 10, 50, wd.artillery_gun()))
	m.append(ms.new("弹药手", "infantry", 10, 50, wd.rifle()))
	return m

static func _make_sov_mortar(wd, ms) -> Array:
	var m = []
	m.append(ms.new("炮长", "infantry", 10, 55, wd.pistol()))
	m.append(ms.new("炮手", "infantry", 10, 50, wd.artillery_gun()))
	m.append(ms.new("弹药手", "infantry", 10, 50, wd.rifle()))
	return m

func _generate_unit_list():
	unit_list = []
	for i in range(unit_defs.size()):
		unit_list.append({"idx": i, "placed": false})

func _bold_font():
	var f = SystemFont.new()
	f.font_weight = 700
	return f

func _build_ui():
	var screen = get_viewport().size
	_build_bg(screen)
	_build_title(screen)
	_build_map_area(screen)
	_build_list_panel(screen)
	_add_map_click_catcher(screen)
	_build_footer(screen)

func _build_bg(screen):
	var bg = ColorRect.new()
	bg.color = Color(0.039, 0.039, 0.098, 1.0)
	bg.size = screen
	add_child(bg)

func _build_title(_screen):
	var title = Label.new()
	title.text = "部署阶段"
	title.position = Vector2(10, 10)
	title.size = Vector2(200, 30)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.add_theme_font_override("font", _bold_font())
	add_child(title)

	var info = Label.new()
	info.text = "从列表选择部队，然后点击地图上的高亮区域放置"
	info.position = Vector2(10, 40)
	info.size = Vector2(400, 20)
	info.add_theme_font_size_override("font_size", 11)
	info.add_theme_color_override("font_color", Color(0.53, 0.53, 0.53))
	add_child(info)

func _build_map_area(screen):
	var map_x = 280
	var map_y = 70
	var map_w = screen.x - map_x - 20
	var map_h = screen.y - map_y - 80

	# Center hex grid in available area: offset so map center (5.5,4.5) is at area center
	var area_cx = map_x + map_w / 2.0
	var area_cy = map_y + map_h / 2.0
	var map_center_pixel = HexUtil.axial_to_pixel(5.5, 4.5, _hex_size)
	_offset_x = area_cx - map_center_pixel.x
	_offset_y = area_cy - map_center_pixel.y

	_setup_deployment_terrain()
	_generate_terrain_grid()
	_render_grid()
	_highlight_deployable()

func _setup_deployment_terrain():
	_deploy_terrain.clear()
	for q in range(12):
		for r in range(10):
			_deploy_terrain[Vector2i(q, r)] = "plain"

	# Same terrain as prologue (DESIGN §21.5.3)
	for q in range(12):
		_deploy_terrain[Vector2i(q, 0)] = "forest"
		_deploy_terrain[Vector2i(q, 9)] = "forest"
	_deploy_terrain[Vector2i(0, 1)] = "forest"
	_deploy_terrain[Vector2i(11, 1)] = "forest"
	_deploy_terrain[Vector2i(2, 3)] = "forest"
	_deploy_terrain[Vector2i(3, 3)] = "forest"
	_deploy_terrain[Vector2i(6, 3)] = "forest"
	_deploy_terrain[Vector2i(7, 3)] = "forest"
	_deploy_terrain[Vector2i(4, 4)] = "city"
	_deploy_terrain[Vector2i(5, 4)] = "city"
	_deploy_terrain[Vector2i(0, 5)] = "mountain"
	_deploy_terrain[Vector2i(1, 5)] = "mountain"
	_deploy_terrain[Vector2i(3, 6)] = "forest"
	_deploy_terrain[Vector2i(4, 6)] = "forest"
	_deploy_terrain[Vector2i(5, 6)] = "forest"
	_deploy_terrain[Vector2i(0, 8)] = "forest"
	_deploy_terrain[Vector2i(11, 8)] = "forest"

	# HQ hex
	_deploy_terrain[Vector2i(5, 8)] = "hq"

func _generate_terrain_grid():
	deployable_hexes.clear()
	var hq_hex = Vector2i(5, 8)

	for q in range(12):
		for r in range(10):
			var hex = Vector2i(q, r)
			var dist = HexUtil.hex_distance(hex, hq_hex)
			if dist <= 4 and dist > 0:
				# 检查是否被占用（有部队）
				var occupied = false
				for h in placed_squads:
					if h == hex: occupied = true; break
				if not occupied:
					deployable_hexes.append(hex)

func _render_grid():
	for n in _grid_nodes.values(): n.queue_free()
	_grid_nodes.clear()

	var hq_hex = Vector2i(5, 8)
	var terrain_db = GameManager.TERRAIN_DB

	for q in range(12):
		for r in range(10):
			var hex = Vector2i(q, r)
			var pos = HexUtil.axial_to_pixel(q, r, _hex_size) + Vector2(_offset_x, _offset_y)
			var is_hq = (hex == hq_hex)

			# Base terrain color
			var tid = _deploy_terrain.get(hex, "plain")
			var td = terrain_db.get(tid, terrain_db["plain"])
			var base_color = td.color

			# Check if deployable
			var is_deployable = false
			for h in deployable_hexes:
				if h == hex: is_deployable = true; break

			# Final color: terrain + deployable tint overlay
			var final_color = base_color * Color(0.7, 0.7, 0.7, 1.0)  # dim all
			if is_hq:
				final_color = Color(0.27, 0.67, 0.53, 0.6)
			elif is_deployable:
				# Brighter with blue tint
				final_color = Color(
					base_color.r * 0.6 + 0.25,
					base_color.g * 0.6 + 0.4,
					base_color.b * 0.6 + 0.5,
					1.0
				)

			var poly = Polygon2D.new()
			poly.polygon = HexUtil.hex_corners(Vector2.ZERO, _hex_size - 1)
			poly.color = final_color
			poly.position = pos
			poly.name = "Hex_%d_%d" % [q, r]
			add_child(poly)
			_grid_nodes[hex] = poly

	# HQ label
	var hq_pos = HexUtil.axial_to_pixel(5, 8, _hex_size) + Vector2(_offset_x, _offset_y)
	var hq_label = Label.new()
	hq_label.text = "HQ"
	hq_label.position = hq_pos - Vector2(12, 8)
	hq_label.size = Vector2(24, 16)
	hq_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hq_label.add_theme_font_size_override("font_size", 9)
	hq_label.add_theme_color_override("font_color", Color(1, 1, 1))
	add_child(hq_label)

func _highlight_deployable():
	pass  # Colors set in _render_grid

func _rebuild_grid():
	_generate_terrain_grid()
	_render_grid()
	_render_placed_squads()

func _render_placed_squads():
	for n in _placed_nodes.values(): n.queue_free()
	_placed_nodes.clear()

	for hex in placed_squads:
		var sd = placed_squads[hex]
		var pos = HexUtil.axial_to_pixel(hex.x, hex.y, _hex_size) + Vector2(_offset_x, _offset_y)

		var container = Node2D.new()
		container.position = pos
		add_child(container)
		_placed_nodes[hex] = container

		var sprite = Polygon2D.new()
		sprite.polygon = HexUtil.hex_corners(Vector2.ZERO, _hex_size - 2)
		sprite.color = Color(0.27, 0.67, 0.53, 0.7)
		sprite.z_index = 1
		container.add_child(sprite)

		var label = Label.new()
		label.text = sd.name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(-30, -8)
		label.size = Vector2(60, 16)
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_color_override("font_color", Color(1, 1, 1))
		label.z_index = 2
		container.add_child(label)

func _build_list_panel(screen):
	_list_panel = Panel.new()
	_list_panel.position = Vector2(10, 70)
	_list_panel.size = Vector2(250, screen.y - 160)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.04)
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(1, 1, 1, 0.1))
	_list_panel.add_theme_stylebox_override("panel", sb)
	add_child(_list_panel)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(5, 5)
	scroll.size = Vector2(240, screen.y - 170)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_panel.add_child(scroll)

	_list_container = VBoxContainer.new()
	_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_container.custom_minimum_size.x = 220
	scroll.add_child(_list_container)

	_refresh_list()

func _refresh_list():
	for c in _list_container.get_children(): c.queue_free()

	for i in range(unit_defs.size()):
		var ud = unit_defs[i]
		var placed = false
		for h in placed_squads:
			if placed_squads[h].idx == i: placed = true; break

		var row = Panel.new()
		row.custom_minimum_size.y = 50
		var rsb = StyleBoxFlat.new()
		rsb.bg_color = Color(0.27, 0.67, 0.53, 0.08) if not placed else Color(1, 1, 1, 0.02)
		rsb.set_corner_radius_all(4)
		rsb.set_border_width_all(1)
		rsb.set_border_color(Color(0.27, 0.67, 0.53, 0.15) if not placed else Color(1, 1, 1, 0.04))
		row.add_theme_stylebox_override("panel", rsb)
		_list_container.add_child(row)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("margin_left", 8)
		hbox.add_theme_constant_override("margin_right", 8)
		hbox.add_theme_constant_override("margin_top", 4)
		hbox.add_theme_constant_override("margin_bottom", 4)
		row.add_child(hbox)

		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)

		var name_lbl = Label.new()
		name_lbl.text = ud.name
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", Color(0.93, 0.93, 0.93) if not placed else Color(0.53, 0.53, 0.53))
		info_vbox.add_child(name_lbl)

		var type_lbl = Label.new()
		type_lbl.text = ud.type + " | " + str(ud.members.size()) + "人"
		type_lbl.add_theme_font_size_override("font_size", 9)
		type_lbl.add_theme_color_override("font_color", Color(0.53, 0.53, 0.53))
		info_vbox.add_child(type_lbl)

		if placed:
			var placed_lbl = Label.new()
			placed_lbl.text = "✓ 已部署"
			placed_lbl.add_theme_font_size_override("font_size", 9)
			placed_lbl.add_theme_color_override("font_color", Color(0.27, 0.67, 0.53))
			hbox.add_child(placed_lbl)
			var remove_btn = Button.new()
			remove_btn.text = "撤销"
			remove_btn.custom_minimum_size = Vector2(40, 24)
			remove_btn.add_theme_font_size_override("font_size", 9)
			var rsb2 = StyleBoxFlat.new()
			rsb2.bg_color = Color(0.8, 0.27, 0.27, 0.08)
			rsb2.set_border_width_all(1)
			rsb2.set_border_color(Color(0.8, 0.27, 0.27, 0.15))
			rsb2.set_corner_radius_all(3)
			remove_btn.add_theme_stylebox_override("normal", rsb2)
			remove_btn.add_theme_color_override("font_color", Color(0.8, 0.27, 0.27))
			remove_btn.pressed.connect(_on_remove_unit.bind(i))
			hbox.add_child(remove_btn)
		else:
			var place_btn = Button.new()
			place_btn.text = "部署"
			place_btn.custom_minimum_size = Vector2(50, 28)
			place_btn.add_theme_font_size_override("font_size", 10)
			place_btn.pressed.connect(_on_place_unit.bind(i))
			var bsb = StyleBoxFlat.new()
			bsb.bg_color = Color(0.27, 0.67, 0.53, 0.1)
			bsb.set_border_width_all(1)
			bsb.set_border_color(Color(0.27, 0.67, 0.53, 0.15))
			bsb.set_corner_radius_all(3)
			place_btn.add_theme_stylebox_override("normal", bsb)
			hbox.add_child(place_btn)

func _on_place_unit(idx: int):
	selected_unit_idx = idx
	_generate_terrain_grid()
	if deployable_hexes.is_empty():
		_info_label.text = "无可部署位置!"
		return
	_info_label.text = "部署 " + unit_defs[idx].name + " - 点击地图高亮格子放置"
	_highlight_deploy_clickable()

func _on_remove_unit(idx: int):
	var to_remove = null
	for hex in placed_squads:
		if placed_squads[hex].idx == idx:
			to_remove = hex
			break
	if to_remove != null:
		placed_squads.erase(to_remove)
		_rebuild_grid()
		_refresh_list()
		_update_confirm_btn()
		_info_label.text = "已撤销 " + unit_defs[idx].name

func _highlight_deploy_clickable():
	for hex in _grid_nodes:
		var poly = _grid_nodes[hex]
		var is_valid = false
		for h in deployable_hexes:
			if h == hex: is_valid = true; break
		if is_valid:
			poly.color = Color(0.27, 0.67, 0.53, 0.5)

func _add_map_click_catcher(screen):
	var overlay = ColorRect.new()
	overlay.position = Vector2(260, 70)
	overlay.size = Vector2(screen.x - 260, screen.y - 130)
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	overlay.gui_input.connect(_on_map_click)

func _on_map_click(event):
	if not event is InputEventMouseButton: return
	if not event.pressed: return
	if event.button_index != MOUSE_BUTTON_LEFT: return
	if selected_unit_idx < 0: return

	var mouse_pos = get_viewport().get_mouse_position()
	var hex = _pixel_to_deploy_hex(mouse_pos)

	if hex == null: return

	# Check if valid deployable hex
	var is_valid = false
	for h in deployable_hexes:
		if h == hex: is_valid = true; break
	if not is_valid: return

	# Place unit
	var ud = unit_defs[selected_unit_idx]
	placed_squads[hex] = {"idx": selected_unit_idx, "name": ud.name, "type": ud.type, "members": ud.members}
	selected_unit_idx = -1
	_rebuild_grid()
	_refresh_list()
	_info_label.text = ud.name + " 已部署"

	_update_confirm_btn()

func _pixel_to_deploy_hex(mouse_pos: Vector2) -> Vector2i:
	var local_pos = mouse_pos - Vector2(_offset_x, _offset_y)
	return HexUtil.pixel_to_axial(local_pos.x, local_pos.y, _hex_size)

func _update_confirm_btn():
	var all_placed = true
	for i in range(unit_defs.size()):
		var found = false
		for h in placed_squads:
			if placed_squads[h].idx == i: found = true; break
		if not found: all_placed = false

	_confirm_btn.disabled = placed_squads.is_empty()
	if all_placed:
		_confirm_btn.text = "全部部署完毕，进入战斗!"
	else:
		_confirm_btn.text = "确认部署 (" + str(placed_squads.size()) + "/" + str(unit_defs.size()) + ")"

func _build_footer(screen):
	var footer = HBoxContainer.new()
	footer.position = Vector2(screen.x / 2 - 300, screen.y - 50)
	footer.size = Vector2(600, 40)
	footer.add_theme_constant_override("separation", 16)
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(footer)

	var back_btn = Button.new()
	back_btn.text = "← 返回"
	back_btn.custom_minimum_size = Vector2(100, 36)
	back_btn.add_theme_font_size_override("font_size", 12)
	back_btn.add_theme_color_override("font_color", Color(0.67, 0.67, 0.67))
	var bsb = StyleBoxFlat.new()
	bsb.bg_color = Color(1, 1, 1, 0.04)
	bsb.set_border_width_all(1)
	bsb.set_border_color(Color(1, 1, 1, 0.1))
	bsb.set_corner_radius_all(4)
	back_btn.add_theme_stylebox_override("normal", bsb)
	back_btn.pressed.connect(_on_back)
	footer.add_child(back_btn)

	var quick_btn = Button.new()
	quick_btn.text = "快速部署"
	quick_btn.custom_minimum_size = Vector2(100, 36)
	quick_btn.add_theme_font_size_override("font_size", 12)
	quick_btn.add_theme_color_override("font_color", Color(0.73, 0.93, 0.73))
	var qsb = StyleBoxFlat.new()
	qsb.bg_color = Color(0.27, 0.67, 0.53, 0.1)
	qsb.set_border_width_all(1)
	qsb.set_border_color(Color(0.27, 0.67, 0.53, 0.15))
	qsb.set_corner_radius_all(4)
	quick_btn.add_theme_stylebox_override("normal", qsb)
	quick_btn.pressed.connect(_on_quick_deploy)
	footer.add_child(quick_btn)

	_confirm_btn = Button.new()
	_confirm_btn.text = "确认部署"
	_confirm_btn.custom_minimum_size = Vector2(180, 36)
	_confirm_btn.add_theme_font_size_override("font_size", 13)
	_confirm_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	_confirm_btn.add_theme_font_override("font", _bold_font())
	_confirm_btn.disabled = true
	var csb = StyleBoxFlat.new()
	csb.bg_color = Color(0.27, 0.67, 0.53, 0.15)
	csb.set_border_width_all(1)
	csb.set_border_color(Color(0.27, 0.67, 0.53, 0.3))
	csb.set_corner_radius_all(4)
	_confirm_btn.add_theme_stylebox_override("normal", csb)
	_confirm_btn.pressed.connect(_on_confirm)
	footer.add_child(_confirm_btn)

	_info_label = Label.new()
	_info_label.position = Vector2(10, screen.y - 75)
	_info_label.size = Vector2(500, 20)
	_info_label.add_theme_font_size_override("font_size", 11)
	_info_label.add_theme_color_override("font_color", Color(0.73, 0.73, 0.73))
	add_child(_info_label)

func _on_back():
	SceneManager.goto_commander_create()

func _on_quick_deploy():
	_generate_terrain_grid()
	var to_place = []
	for i in range(unit_defs.size()):
		var found = false
		for h in placed_squads:
			if placed_squads[h].idx == i: found = true; break
		if not found:
			to_place.append(i)
	if to_place.is_empty() or deployable_hexes.is_empty():
		return
	var hexes = deployable_hexes.duplicate()
	hexes.shuffle()
	for i in range(min(to_place.size(), hexes.size())):
		var idx = to_place[i]
		var ud = unit_defs[idx]
		placed_squads[hexes[i]] = {"idx": idx, "name": ud.name, "type": ud.type, "members": ud.members}
	_rebuild_grid()
	_refresh_list()
	_update_confirm_btn()
	_info_label.text = "快速部署完成"

func _on_confirm():
	if placed_squads.is_empty(): return
	GameManager.mission_placed_squads = placed_squads.duplicate()
	GameManager.mission_new_game = true
	SceneManager.goto_battle()
