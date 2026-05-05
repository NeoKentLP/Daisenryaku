extends CanvasLayer

var squad_detail: Panel

# Top bar
var _top_bar: Panel
var _turn_label: Label
var _phase_label: Label
var _cp_label: Label
var _supply_label: Label

# Bottom strip
var _bottom_strip: HBoxContainer
var _squad_module: Panel
var _squad_name_label: Label
var _morale_bar: Panel
var _morale_fill: ColorRect
var _morale_text: Label
var _stats_label: Label
var _hp_grid: HBoxContainer
var _weapons_container: HBoxContainer

# Buff + action
var _buff_action_stack: VBoxContainer
var _buff_module: HBoxContainer
var _action_module: HBoxContainer
var _assault_btn: Button
var _eng_trench_btn: Button
var _eng_mine_btn: Button
var _eng_clear_btn: Button
var _supply_btn: Button
var _wait_btn: Button
var _shoot_btn: Button

# Terrain
var _terrain_strip: Panel
var _terrain_name: Label
var _terrain_info: Label

# End turn
var _end_turn_btn: Button

# Log
var log_panel: Panel
var log_list: Array = []
var _var_log_label: Label

# Storage
var _storage_panel: Panel
var _storage_list: VBoxContainer

# Tooltip
var _tooltip: Panel
var _tooltip_label: Label
var _terrain_tooltip: Label

# Commander
var _cmd_detail: Panel
var _cmd_detail_label: Label

# Drag
var _drag_panel = null
var _drag_offset: Vector2

# State
var _current_squad = null
var _hp_cells: Array = []

var message_label: Label
var turn_announce: Label

func _ready():
	GameManager.ui_manager = self
	GameManager.phase_changed.connect(_on_phase_changed)
	GameManager.command_points_changed.connect(_on_cp_changed)
	GameManager.turn_ended.connect(_on_turn_ended)
	GameManager.supply_changed.connect(_on_supply_changed)
	await get_tree().process_frame
	_build_ui()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			for p in [_cmd_detail, log_panel, _storage_panel]:
				if p and p.visible and _is_in_rect(event.position, p):
					_drag_panel = p
					_drag_offset = p.position - event.position
					break
		else:
			_drag_panel = null
	if event is InputEventMouseMotion and _drag_panel:
		_drag_panel.position = event.position + _drag_offset

func _is_in_rect(pos: Vector2, node: Control) -> bool:
	return pos.x >= node.position.x and pos.x <= node.position.x + node.size.x and pos.y >= node.position.y and pos.y <= node.position.y + node.size.y

func _build_ui():
	var screen = get_viewport().size

	_build_top_bar(screen)
	_build_bottom_strip(screen)
	_build_end_turn_btn(screen)
	_build_log(screen)
	_build_storage(screen)
	_build_message(screen)
	_build_tooltip()
	_build_commander_detail(screen)
	_build_squad_detail()

func _make_bg(alpha: float = 0.94) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.039, 0.039, 0.098, alpha)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(1, 1, 1, 0.12))
	return sb

func _make_card(alpha: float = 0.88, border_alpha: float = 0.1) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.039, 0.039, 0.098, alpha)
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(1, 1, 1, border_alpha))
	return sb

# ===== Top Bar =====
func _build_top_bar(screen: Vector2):
	_top_bar = Panel.new()
	_top_bar.position = Vector2(0, 0)
	_top_bar.size = Vector2(screen.x, 30)
	_top_bar.add_theme_stylebox_override("panel", _make_bg(0.92))
	_top_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_top_bar)

	var left = HBoxContainer.new()
	left.position = Vector2(12, 0)
	left.size = Vector2(500, 30)
	left.add_theme_constant_override("separation", 6)
	_top_bar.add_child(left)

	_make_top_left(left)

	var right = HBoxContainer.new()
	right.position = Vector2(screen.x - 400, 0)
	right.size = Vector2(380, 30)
	right.add_theme_constant_override("separation", 4)
	right.alignment = BoxContainer.ALIGNMENT_END
	_top_bar.add_child(right)

	_make_top_right(right)

func _make_top_left(parent: HBoxContainer):
	var title = Label.new()
	title.text = "大战略"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.47, 0.67, 1.0))
	title.add_theme_font_override("font", _bold_font())
	parent.add_child(title)

	var sep = Label.new()
	sep.text = "|"
	sep.add_theme_font_size_override("font_size", 10)
	sep.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	parent.add_child(sep)

	_turn_label = Label.new()
	_turn_label.text = "回合 1"
	_turn_label.add_theme_font_size_override("font_size", 10)
	_turn_label.add_theme_color_override("font_color", Color(0.53, 0.53, 0.53))
	parent.add_child(_turn_label)

	sep = Label.new()
	sep.text = "|"
	sep.add_theme_font_size_override("font_size", 10)
	sep.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	parent.add_child(sep)

	_phase_label = Label.new()
	_phase_label.text = "玩家回合"
	_phase_label.add_theme_font_size_override("font_size", 11)
	_phase_label.add_theme_color_override("font_color", Color(0.27, 0.67, 0.53))
	parent.add_child(_phase_label)

func _make_top_right(parent: HBoxContainer):
	var cp_icon = Label.new()
	cp_icon.text = "货币 "
	cp_icon.add_theme_font_size_override("font_size", 10)
	cp_icon.add_theme_color_override("font_color", Color(0.53, 0.53, 0.53))
	parent.add_child(cp_icon)

	_cp_label = Label.new()
	_cp_label.text = "100"
	_cp_label.add_theme_font_size_override("font_size", 11)
	_cp_label.add_theme_color_override("font_color", Color(0.93, 0.93, 0.93))
	parent.add_child(_cp_label)

	var sp_sep = Label.new()
	sp_sep.text = "|"
	sp_sep.add_theme_font_size_override("font_size", 10)
	sp_sep.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	parent.add_child(sp_sep)

	var sup_icon = Label.new()
	sup_icon.text = "补给 "
	sup_icon.add_theme_font_size_override("font_size", 10)
	sup_icon.add_theme_color_override("font_color", Color(0.53, 0.53, 0.53))
	parent.add_child(sup_icon)

	_supply_label = Label.new()
	_supply_label.text = "充足"
	_supply_label.add_theme_font_size_override("font_size", 11)
	_supply_label.add_theme_color_override("font_color", Color(0.33, 0.8, 0.33))
	parent.add_child(_supply_label)

	parent.add_spacer(false)

	var log_btn = _make_top_btn("日志")
	log_btn.pressed.connect(_toggle_log)
	parent.add_child(log_btn)

	var storage_btn = _make_top_btn("储备库")
	storage_btn.pressed.connect(_toggle_storage)
	parent.add_child(storage_btn)

func _make_top_btn(text: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", Color(0.53, 0.53, 0.53))
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.04)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(1, 1, 1, 0.08))
	sb.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h = StyleBoxFlat.new()
	sb_h.bg_color = Color(0.39, 0.67, 1, 0.08)
	sb_h.set_border_width_all(1)
	sb_h.set_border_color(Color(1, 1, 1, 0.15))
	sb_h.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("hover", sb_h)
	return btn

func _bold_font():
	var f = SystemFont.new()
	f.font_weight = 700
	return f

# ===== Bottom Strip =====
func _build_bottom_strip(screen: Vector2):
	_bottom_strip = HBoxContainer.new()
	_bottom_strip.position = Vector2(10, screen.y - 190)
	_bottom_strip.size = Vector2(screen.x - 80, 180)
	_bottom_strip.add_theme_constant_override("separation", 6)
	_bottom_strip.alignment = BoxContainer.ALIGNMENT_END
	add_child(_bottom_strip)

	_build_squad_module()
	_build_buff_action_stack()
	_build_terrain_strip()

func _build_squad_module():
	_squad_module = Panel.new()
	_squad_module.add_theme_stylebox_override("panel", _make_card(0.94, 0.12))
	_squad_module.custom_minimum_size.x = 380
	_squad_module.hide()
	_bottom_strip.add_child(_squad_module)

	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("margin_left", 8)
	outer.add_theme_constant_override("margin_right", 8)
	outer.add_theme_constant_override("margin_top", 6)
	outer.add_theme_constant_override("margin_bottom", 6)
	outer.add_theme_constant_override("separation", 3)
	_squad_module.add_child(outer)

	# Top: image + name area
	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	outer.add_child(top_row)

	var img_box = Panel.new()
	img_box.custom_minimum_size = Vector2(50, 66)
	var isb = StyleBoxFlat.new()
	isb.bg_color = Color(1, 1, 1, 0.04)
	isb.set_border_width_all(1)
	isb.set_border_color(Color(1, 1, 1, 0.08))
	isb.set_corner_radius_all(4)
	img_box.add_theme_stylebox_override("panel", isb)
	img_box.mouse_filter = Control.MOUSE_FILTER_STOP
	img_box.gui_input.connect(_on_squad_icon_clicked)
	_add_tooltip(img_box, "点击查看部队详情")
	top_row.add_child(img_box)

	var name_area = VBoxContainer.new()
	name_area.size_flags_vertical = Control.SIZE_SHRINK_END
	top_row.add_child(name_area)

	_squad_name_label = Label.new()
	_squad_name_label.add_theme_font_size_override("font_size", 15)
	_squad_name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_squad_name_label.add_theme_font_override("font", _bold_font())
	_squad_name_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_squad_name_label.gui_input.connect(_on_squad_name_clicked)
	_add_tooltip(_squad_name_label, "点击查看部队详情")
	name_area.add_child(_squad_name_label)

	var morale_row = HBoxContainer.new()
	morale_row.add_theme_constant_override("separation", 4)
	morale_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_area.add_child(morale_row)

	_morale_bar = Panel.new()
	_morale_bar.custom_minimum_size = Vector2(90, 12)
	var msb = StyleBoxFlat.new()
	msb.bg_color = Color(1, 1, 1, 0.06)
	msb.set_corner_radius_all(3)
	_morale_bar.add_theme_stylebox_override("panel", msb)
	morale_row.add_child(_morale_bar)

	_morale_fill = ColorRect.new()
	_morale_fill.anchor_right = 0.0
	_morale_fill.anchor_bottom = 1.0
	_morale_fill.size = Vector2(63, 12)
	_morale_fill.color = Color(0.2, 0.67, 0.2)
	_morale_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_morale_bar.add_child(_morale_fill)
	_morale_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_add_tooltip(_morale_bar, "士气状态\n溃败(0) 不可控\n混乱(1-20) 命中-15%\n正常(21-70) 无修正\n高昂(71-90) 命中+10% 伤害+15%\n狂热(91-100) 命中+20% 伤害+30%")

	_morale_text = Label.new()
	_morale_text.anchor_right = 1.0
	_morale_text.anchor_bottom = 1.0
	_morale_text.text = "士气 70/100"
	_morale_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_morale_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_morale_text.add_theme_font_size_override("font_size", 8)
	_morale_text.add_theme_color_override("font_color", Color(1, 1, 1))
	_morale_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_morale_bar.add_child(_morale_text)

	# Stats row
	outer.add_child(_make_h_sep(0.05))
	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 10)
	_stats_label.add_theme_color_override("font_color", Color(0.67, 0.67, 0.67))
	outer.add_child(_stats_label)

	# HP grid
	_hp_grid = HBoxContainer.new()
	_hp_grid.add_theme_constant_override("separation", 3)
	outer.add_child(_hp_grid)

	# Weapons
	_weapons_container = HBoxContainer.new()
	_weapons_container.add_theme_constant_override("separation", 4)
	outer.add_child(_weapons_container)

func _build_buff_action_stack():
	_buff_action_stack = VBoxContainer.new()
	_buff_action_stack.add_theme_constant_override("separation", 3)
	_buff_action_stack.alignment = BoxContainer.ALIGNMENT_BEGIN
	_buff_action_stack.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_bottom_strip.add_child(_buff_action_stack)

	# Buff row
	_buff_module = HBoxContainer.new()
	_buff_module.add_theme_constant_override("separation", 3)
	_buff_module.hide()
	_buff_action_stack.add_child(_buff_module)

	# Action buttons
	_action_module = HBoxContainer.new()
	_action_module.add_theme_constant_override("separation", 3)
	_action_module.hide()
	_buff_action_stack.add_child(_action_module)

	_wait_btn = _make_action_btn("待机", Color(0.4, 0.4, 0.4))
	_wait_btn.pressed.connect(_on_wait_pressed)
	_add_tooltip(_wait_btn, "待机\n结束当前部队行动，不消耗AP")
	_action_module.add_child(_wait_btn)

	_shoot_btn = _make_action_btn("射击\n2AP", Color(0.73, 0.73, 0.73))
	_shoot_btn.hide()
	_add_tooltip(_shoot_btn, "射击\n对选定目标发动攻击\n消耗2AP")
	_action_module.add_child(_shoot_btn)

	_assault_btn = _make_action_btn("突击\n3AP", Color(0.27, 0.67, 0.53))
	_assault_btn.hide()
	_assault_btn.pressed.connect(_on_assault_pressed)
	_add_tooltip(_assault_btn, "突击\nCQB近距离突击，双方同时开火\n消耗3AP 需要CQB地形+目标相邻")
	_action_module.add_child(_assault_btn)

	_eng_trench_btn = _make_action_btn("战壕\n3AP", Color(0.73, 0.73, 0.73))
	_eng_trench_btn.hide()
	_eng_trench_btn.pressed.connect(_on_eng_trench)
	_add_tooltip(_eng_trench_btn, "挖战壕\n在脚下建造战壕（工兵）\n消耗3AP")
	_action_module.add_child(_eng_trench_btn)

	_eng_mine_btn = _make_action_btn("布雷\n3AP", Color(0.73, 0.73, 0.73))
	_eng_mine_btn.hide()
	_eng_mine_btn.pressed.connect(_on_eng_mine)
	_add_tooltip(_eng_mine_btn, "布雷\n在脚下布设地雷区（工兵）\n消耗3AP")
	_action_module.add_child(_eng_mine_btn)

	_eng_clear_btn = _make_action_btn("排雷\n2AP", Color(0.73, 0.73, 0.73))
	_eng_clear_btn.hide()
	_eng_clear_btn.pressed.connect(_on_eng_clear)
	_add_tooltip(_eng_clear_btn, "排雷\n排除相邻地雷（工兵）\n消耗2AP")
	_action_module.add_child(_eng_clear_btn)

	_supply_btn = _make_action_btn("补给\n1AP", Color(0.4, 0.73, 1.0))
	_supply_btn.hide()
	_supply_btn.pressed.connect(_on_supply_pressed)
	_add_tooltip(_supply_btn, "补给\n补充全队弹药\n消耗1AP 需要HQ/工厂/补给车相邻")
	_action_module.add_child(_supply_btn)

func _make_action_btn(text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 9)
	btn.add_theme_color_override("font_color", color)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.05)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(1, 1, 1, 0.1))
	sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h = StyleBoxFlat.new()
	sb_h.bg_color = Color(0.39, 0.67, 1, 0.08)
	sb_h.set_border_width_all(1)
	sb_h.set_border_color(Color(1, 1, 1, 0.15))
	sb_h.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.custom_minimum_size = Vector2(48, 36)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return btn

func _build_terrain_strip():
	_terrain_strip = Panel.new()
	_terrain_strip.add_theme_stylebox_override("panel", _make_card(0.88))
	_terrain_strip.custom_minimum_size.x = 180
	_terrain_strip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_terrain_strip.hide()
	_bottom_strip.add_child(_terrain_strip)

	var inner = HBoxContainer.new()
	inner.add_theme_constant_override("margin_left", 10)
	inner.add_theme_constant_override("margin_right", 10)
	inner.add_theme_constant_override("margin_top", 4)
	inner.add_theme_constant_override("margin_bottom", 4)
	inner.add_theme_constant_override("separation", 8)
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	_terrain_strip.add_child(inner)

	_terrain_name = Label.new()
	_terrain_name.add_theme_font_size_override("font_size", 11)
	_terrain_name.add_theme_color_override("font_color", Color(1, 1, 1))
	_terrain_name.add_theme_font_override("font", _bold_font())
	inner.add_child(_terrain_name)

	var tsp = Label.new()
	tsp.text = "|"
	tsp.add_theme_font_size_override("font_size", 8)
	tsp.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	inner.add_child(tsp)

	_terrain_info = Label.new()
	_terrain_info.add_theme_font_size_override("font_size", 9)
	_terrain_info.add_theme_color_override("font_color", Color(0.67, 0.67, 0.67))
	inner.add_child(_terrain_info)

func _make_h_sep(alpha: float = 0.08):
	var sep = HSeparator.new()
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sep.add_theme_color_override("color", Color(1, 1, 1, alpha))
	return sep

# ===== End Turn Button =====
func _build_end_turn_btn(screen: Vector2):
	_end_turn_btn = Button.new()
	_end_turn_btn.position = Vector2(screen.x - 66, screen.y - 66)
	_end_turn_btn.size = Vector2(56, 56)
	_end_turn_btn.text = "结束\n回合"
	_end_turn_btn.add_theme_font_size_override("font_size", 10)
	_end_turn_btn.add_theme_color_override("font_color", Color(0.87, 0.47, 0.47))
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.78, 0.24, 0.24, 0.1)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(0.78, 0.24, 0.24, 0.2))
	sb.set_corner_radius_all(6)
	_end_turn_btn.add_theme_stylebox_override("normal", sb)
	var sb_h = StyleBoxFlat.new()
	sb_h.bg_color = Color(0.78, 0.24, 0.24, 0.18)
	sb_h.set_border_width_all(1)
	sb_h.set_border_color(Color(0.78, 0.24, 0.24, 0.3))
	sb_h.set_corner_radius_all(6)
	_end_turn_btn.add_theme_stylebox_override("hover", sb_h)
	_end_turn_btn.pressed.connect(_on_end_turn)
	_add_tooltip(_end_turn_btn, "结束回合\n所有未行动部队将自动待机")
	add_child(_end_turn_btn)

# ===== Log =====
func _build_log(screen: Vector2):
	log_panel = Panel.new()
	log_panel.position = Vector2(screen.x - 460, screen.y - 480)
	log_panel.size = Vector2(450, 400)
	log_panel.add_theme_stylebox_override("panel", _make_bg(0.95))
	log_panel.hide()
	add_child(log_panel)

	var log_title = Label.new()
	log_title.position = Vector2(10, 10)
	log_title.text = "战斗日志"
	log_title.add_theme_font_size_override("font_size", 14)
	log_title.add_theme_color_override("font_color", Color(0.87, 0.87, 0.87))
	log_panel.add_child(log_title)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(10, 35)
	scroll.size = Vector2(430, 355)
	log_panel.add_child(scroll)

	_var_log_label = Label.new()
	_var_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_var_log_label.custom_minimum_size.x = 310
	_var_log_label.add_theme_font_size_override("font_size", 11)
	_var_log_label.add_theme_color_override("font_color", Color(0.67, 0.67, 0.67))
	_var_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(_var_log_label)

# ===== Storage =====
func _build_storage(screen: Vector2):
	_storage_panel = Panel.new()
	_storage_panel.position = Vector2(screen.x - 500, screen.y - 570)
	_storage_panel.size = Vector2(490, 520)
	_storage_panel.add_theme_stylebox_override("panel", _make_bg(0.95))
	_storage_panel.hide()
	add_child(_storage_panel)

	var st_title = Label.new()
	st_title.position = Vector2(10, 10)
	st_title.text = "储备库"
	st_title.add_theme_font_size_override("font_size", 14)
	st_title.add_theme_color_override("font_color", Color(0.87, 0.87, 0.87))
	_storage_panel.add_child(st_title)

	var st_scroll = ScrollContainer.new()
	st_scroll.position = Vector2(10, 35)
	st_scroll.size = Vector2(470, 440)
	_storage_panel.add_child(st_scroll)

	_storage_list = VBoxContainer.new()
	_storage_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_storage_list.custom_minimum_size.x = 450
	st_scroll.add_child(_storage_list)

	var st_close = Button.new()
	st_close.position = Vector2(420, 485)
	st_close.text = "关闭"
	st_close.add_theme_font_size_override("font_size", 11)
	st_close.pressed.connect(_toggle_storage)
	_storage_panel.add_child(st_close)

# ===== Message =====
func _build_message(screen: Vector2):
	message_label = Label.new()
	message_label.position = Vector2(screen.x / 2 - 300, screen.y - 35)
	message_label.size = Vector2(600, 30)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 14)
	message_label.add_theme_color_override("font_color", Color(1, 1, 1))
	message_label.hide()
	add_child(message_label)

	turn_announce = Label.new()
	turn_announce.position = Vector2(screen.x / 2 - 300, screen.y / 2 - 40)
	turn_announce.size = Vector2(600, 80)
	turn_announce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_announce.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_announce.add_theme_font_size_override("font_size", 48)
	turn_announce.add_theme_color_override("font_color", Color(1, 1, 1))
	turn_announce.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	turn_announce.add_theme_constant_override("outline_size", 4)
	turn_announce.modulate = Color(1, 1, 1, 0)
	turn_announce.hide()
	add_child(turn_announce)

# ===== Tooltip =====
func _build_tooltip():
	_tooltip = Panel.new()
	_tooltip.add_theme_stylebox_override("panel", _make_tooltip_bg())
	_tooltip.hide()
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tooltip)

	_tooltip_label = Label.new()
	_tooltip_label.position = Vector2(6, 4)
	_tooltip_label.size = Vector2(200, 40)
	_tooltip_label.add_theme_font_size_override("font_size", 9)
	_tooltip_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip.add_child(_tooltip_label)

	_terrain_tooltip = Label.new()
	_terrain_tooltip.add_theme_font_size_override("font_size", 10)
	_terrain_tooltip.add_theme_color_override("font_color", Color(1, 1, 1))
	_terrain_tooltip.add_theme_color_override("bg_color", Color(0, 0, 0, 0.7))
	_terrain_tooltip.add_theme_stylebox_override("normal", _make_tooltip_bg())
	_terrain_tooltip.hide()
	add_child(_terrain_tooltip)

func _make_tooltip_bg() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.94)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(1, 1, 1, 0.15))
	sb.set_corner_radius_all(4)
	return sb

func _add_tooltip(node: Control, text: String):
	node.mouse_entered.connect(func(): _show_tooltip_at(text, node))
	node.mouse_exited.connect(hide_tooltip)

func _show_tooltip_at(text: String, node: Control):
	if not _tooltip: return
	_tooltip_label.text = text
	_tooltip_label.size = Vector2(260, 80)
	_tooltip.size = Vector2(272, 88)
	var gp = node.get_global_mouse_position()
	var screen = get_viewport().size
	var tx = gp.x + 10
	var ty = gp.y - _tooltip.size.y - 6
	if ty < 30: ty = gp.y + 20
	if tx + _tooltip.size.x > screen.x - 4: tx = screen.x - 4 - _tooltip.size.x
	if tx < 4: tx = 4
	_tooltip.position = Vector2(tx, ty)
	_tooltip.show()

func show_tooltip(text: String):
	if _tooltip:
		_tooltip_label.text = text
		_tooltip_label.size = Vector2(200, 60)
		_tooltip.size = Vector2(212, 68)
		_tooltip.show()

func hide_tooltip():
	if _tooltip:
		_tooltip.hide()

func show_terrain_tooltip(text: String, pos: Vector2 = Vector2(-1, -1)):
	if _terrain_tooltip:
		_terrain_tooltip.text = text
		if pos.x >= 0:
			_terrain_tooltip.position = Vector2(pos.x + 12, pos.y - 20)
			if _terrain_tooltip.position.y < 30: _terrain_tooltip.position.y = pos.y + 20
			if _terrain_tooltip.position.x + _terrain_tooltip.size.x > get_viewport().size.x - 10:
				_terrain_tooltip.position.x = pos.x - 12 - _terrain_tooltip.size.x
		_terrain_tooltip.size = Vector2(180, 100)
		_terrain_tooltip.show()

func hide_terrain_tooltip():
	if _terrain_tooltip:
		_terrain_tooltip.hide()

# ===== Commander Detail =====
func _build_commander_detail(_screen: Vector2):
	_cmd_detail = Panel.new()
	_cmd_detail.position = Vector2(260, 10)
	_cmd_detail.size = Vector2(300, 250)
	_cmd_detail.add_theme_stylebox_override("panel", _make_bg(0.95))
	_cmd_detail.hide()
	add_child(_cmd_detail)

	_cmd_detail_label = Label.new()
	_cmd_detail_label.position = Vector2(10, 10)
	_cmd_detail_label.size = Vector2(280, 200)
	_cmd_detail_label.add_theme_font_size_override("font_size", 11)
	_cmd_detail.add_child(_cmd_detail_label)

	var cmd_close = Button.new()
	cmd_close.position = Vector2(260, 218)
	cmd_close.text = "关闭"
	cmd_close.pressed.connect(_on_cmd_close)
	_cmd_detail.add_child(cmd_close)

# ===== Squad Detail =====
func _build_squad_detail():
	squad_detail = preload("res://scripts/ui/squad_detail.gd").new()
	squad_detail.name = "SquadDetail"
	add_child(squad_detail)

func _on_squad_icon_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _current_squad and _current_squad.is_alive:
			squad_detail.open(_current_squad)

func _on_squad_name_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _current_squad and _current_squad.is_alive:
			squad_detail.open(_current_squad)

# ===== Public API =====

func show_squad_info(squad):
	if not squad or not squad.is_alive:
		_squad_module.hide()
		_terrain_strip.hide()
		_current_squad = null
		_buff_module.hide()
		_action_module.hide()
		return

	_squad_module.show()
	_current_squad = squad

	var db = GameManager.UNIT_TYPE_DB
	var type_name = squad.unit_type_id
	if db and db.has(squad.unit_type_id):
		type_name = db[squad.unit_type_id].display_name
	_squad_name_label.text = squad.squad_name + " [" + type_name + "]"

	# Morale
	var pct = float(squad.morale) / squad.max_morale
	_morale_fill.size = Vector2(90 * pct, 12)
	_morale_text.text = "士气 " + str(squad.morale) + "/" + str(squad.max_morale)
	match squad.get_state():
		squad.STATE_BROKEN: _morale_fill.color = Color(0.53, 0.27, 0.27)
		squad.STATE_CONFUSED: _morale_fill.color = Color(0.53, 0.4, 0.27)
		squad.STATE_NORMAL: _morale_fill.color = Color(0.27, 0.67, 0.27)
		squad.STATE_ELEVATED: _morale_fill.color = Color(0.67, 0.67, 0.27)
		squad.STATE_FRENZIED: _morale_fill.color = Color(0.8, 0.53, 0.0)

	# Stats
	var mn = GameManager.hex_map
	var move_type = "步行"
	var concealment = 0
	var armor = 0
	for m in squad.members:
		if m.is_alive:
			move_type = m.move_type
			concealment = m.concealment
			if m.armor > armor: armor = m.armor
			break
	var move_label = {"foot":"步行", "wheel":"轮式", "track":"履带", "flight":"飞行"}
	var mv = move_label.get(move_type, move_type)
	var ammo_str = str(squad.get_total_ammo()) + "/" + str(squad.get_max_ammo())
	_stats_label.text = "AP " + str(squad.ap) + "/" + str(squad.max_ap) + "  |  弹药 " + ammo_str + "  |  隐蔽 " + str(concealment) + "  |  机动 " + mv + "  |  护甲 " + str(armor)

	_rebuild_hp_grid(squad)

	var weapon_counts = {}
	for m in squad.members:
		if not m.is_alive: continue
		for w in m.weapons:
			var wn = w.get("name", "?")
			if not weapon_counts.has(wn):
				weapon_counts[wn] = {"count": 0, "ammo": 0, "max_ammo": 0}
			weapon_counts[wn]["count"] += 1
			weapon_counts[wn]["ammo"] += w.get("ammo", 0)
			weapon_counts[wn]["max_ammo"] += w.get("max_ammo", w.get("ammo", 0))
	_rebuild_weapon_tags(weapon_counts)

	# Buffs
	_build_buffs(squad)

	# Terrain
	_build_terrain_info(squad)

func _rebuild_hp_grid(squad):
	for c in _hp_grid.get_children():
		c.queue_free()
	_hp_cells.clear()

	var members = squad.members
	if members.is_empty(): return

	var cols = 5
	var row_count = ceili(members.size() / float(cols))
	for ri in range(row_count):
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		_hp_grid.add_child(row)
		for ci in range(cols):
			var idx = ri * cols + ci
			if idx >= members.size(): break
			var m = members[idx]
			_hp_cells.append(_make_hp_cell(row, m))

func _rebuild_weapon_tags(weapon_counts: Dictionary):
	for c in _weapons_container.get_children():
		c.queue_free()
	for wn in weapon_counts:
		var g = weapon_counts[wn]
		var tag = Panel.new()
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.04)
		sb.set_border_width_all(1)
		sb.set_border_color(Color(1, 1, 1, 0.06))
		sb.set_corner_radius_all(2)
		tag.add_theme_stylebox_override("panel", sb)

		var lbl = Label.new()
		var ammo_color = Color(0.67, 0.67, 0.67)
		if g["count"] > 1:
			lbl.text = wn + "×" + str(g["count"])
		else:
			lbl.text = wn
		if g["max_ammo"] > 0 and g["ammo"] <= 0:
			ammo_color = Color(1.0, 0.33, 0.33)
		lbl.text = wn + " " + str(g["ammo"]) + "/" + str(g["max_ammo"])
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.add_theme_color_override("font_color", ammo_color)
		tag.add_child(lbl)
		_weapons_container.add_child(tag)

func _make_hp_cell(parent: HBoxContainer, member) -> Panel:
	var cell = Panel.new()
	cell.custom_minimum_size = Vector2(44, 16)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var csb = StyleBoxFlat.new()
	csb.bg_color = Color(1, 1, 1, 0.06)
	csb.set_corner_radius_all(2)
	cell.add_theme_stylebox_override("panel", csb)
	parent.add_child(cell)

	var fill = ColorRect.new()
	fill.anchor_right = 0.0
	fill.anchor_bottom = 1.0
	var fill_pct = float(member.hp) / member.max_hp if member.max_hp > 0 else 0
	if not member.is_alive:
		fill.color = Color(0.2, 0.2, 0.2, 0.4)
	elif fill_pct > 0.6:
		fill.color = Color(0.2, 0.67, 0.2)
	elif fill_pct > 0.3:
		fill.color = Color(0.8, 0.67, 0.27)
	else:
		fill.color = Color(0.8, 0.27, 0.27)
	cell.add_child(fill)

	var txt = Label.new()
	txt.anchor_right = 1.0
	txt.anchor_bottom = 1.0
	txt.text = str(member.hp) + "/" + str(member.max_hp)
	txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	txt.add_theme_font_size_override("font_size", 7)
	txt.add_theme_color_override("font_color", Color(1, 1, 1) if member.is_alive else Color(0.33, 0.33, 0.33))
	cell.add_child(txt)

	var resizer = func():
		fill.size = cell.size
	cell.resized.connect(resizer)

	return cell

func _build_buffs(squad):
	for c in _buff_module.get_children():
		c.queue_free()
	_buff_module.hide()

	var has_buff = false

	# Suppression
	if squad.suppression > 0:
		has_buff = true
		_buff_module.add_child(_make_buff_icon("压制 " + str(squad.suppression) + "%", Color(0.78, 0.53, 0.53), Color(0.78, 0.24, 0.24, 0.12)))

	# ZOC
	var mn = GameManager.hex_map
	if mn and mn.has_enemy_zoc(squad.hex_coord, squad.team):
		has_buff = true
		_buff_module.add_child(_make_buff_icon("ZOC", Color(0.53, 0.73, 1.0), Color(0.39, 0.67, 1.0, 0.1)))

	# Supply
	if squad.is_near_supply_source():
		has_buff = true
		_buff_module.add_child(_make_buff_icon("补给源", Color(0.53, 1.0, 0.53), Color(0.27, 0.67, 0.53, 0.12)))

	# Morale state
	var state_name = squad.get_state_name()
	if state_name in ["高昂", "狂热"]:
		has_buff = true
		_buff_module.add_child(_make_buff_icon(state_name, Color(0.53, 1.0, 0.53), Color(0.27, 0.67, 0.53, 0.12)))
	elif state_name in ["溃败", "混乱"]:
		has_buff = true
		_buff_module.add_child(_make_buff_icon(state_name, Color(1.0, 0.53, 0.53), Color(0.78, 0.24, 0.24, 0.12)))

	if has_buff:
		_buff_module.show()

func _make_buff_icon(text: String, text_color: Color, bg_color: Color):
	var c = HBoxContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.set_border_width_all(1)
	sb.set_border_color(Color(text_color.r, text_color.g, text_color.b, 0.12))
	sb.set_corner_radius_all(3)
	c.add_theme_stylebox_override("panel", sb)
	var lbl = Label.new()
	lbl.text = "  " + text + "  "
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", text_color)
	c.add_child(lbl)
	return c

func _build_terrain_info(squad):
	var mn = GameManager.hex_map
	if not mn:
		_terrain_strip.hide()
		return
	_terrain_strip.show()

	var hex = squad.hex_coord
	var tid = mn.terrain_grid.get(hex, "plain")
	var td = mn.get_terrain_at(hex)
	if not td:
		_terrain_strip.hide()
		return

	_terrain_name.text = td.display_name

	var hit_penalty = 0
	match tid:
		"city": hit_penalty = -15
		"forest": hit_penalty = -10
		"mountain": hit_penalty = -20
		"river": hit_penalty = -5

	var parts = []
	parts.append("移 " + str(td.move_cost))
	parts.append("防 " + ("> " if td.defense_bonus > 0 else "") + str(td.defense_bonus))
	if hit_penalty != 0:
		parts.append("命中 " + str(hit_penalty) + "%")
	else:
		parts.append("命中 0%")

	var is_cqb = tid in ["city", "forest", "ruins"]
	var ov = mn.get_overlay(hex)
	if ov == "trench" or ov == "bunker":
		is_cqb = true
	if is_cqb:
		parts.append("[CQB]")

	if mn.is_supply_station(hex):
		parts.append("[补给站]")

	_terrain_info.text = " | ".join(parts)

func show_action_menu():
	_action_module.show()

func hide_action_menu():
	_action_module.hide()
	_assault_btn.hide()
	_eng_trench_btn.hide()
	_eng_mine_btn.hide()
	_eng_clear_btn.hide()
	_supply_btn.hide()
	_shoot_btn.hide()
	_buff_module.hide()

func show_assault_button(ap_ok: bool = true):
	_assault_btn.show()
	_assault_btn.add_theme_color_override("font_color", Color(0.27, 0.67, 0.53) if ap_ok else Color(1, 0.3, 0.3))

func show_engineer_buttons(ap: int = 4):
	_eng_trench_btn.show()
	_eng_trench_btn.add_theme_color_override("font_color", Color(0.73, 0.73, 0.73) if ap >= 3 else Color(1, 0.3, 0.3))
	_eng_mine_btn.show()
	_eng_mine_btn.add_theme_color_override("font_color", Color(0.73, 0.73, 0.73) if ap >= 3 else Color(1, 0.3, 0.3))
	_show_clear_if_needed()

func show_supply_button(ap_ok: bool = true):
	_supply_btn.show()
	_supply_btn.add_theme_color_override("font_color", Color(0.4, 0.73, 1.0) if ap_ok else Color(1, 0.3, 0.3))

func add_log(text: String):
	log_list.append(text)
	if log_list.size() > 100:
		log_list.pop_front()
	_var_log_label.text = "\n".join(log_list)

func show_message(text: String):
	if not message_label: return
	message_label.text = text
	message_label.show()
	await get_tree().create_timer(2.0).timeout
	if message_label:
		message_label.hide()

func show_turn_announce(text: String):
	if not turn_announce: return
	turn_announce.text = text
	turn_announce.modulate = Color(1, 1, 1, 0)
	turn_announce.show()
	var tw = create_tween()
	tw.tween_property(turn_announce, "modulate", Color(1, 1, 1, 1), 0.3)
	tw.tween_interval(1.0)
	tw.tween_property(turn_announce, "modulate", Color(1, 1, 1, 0), 0.5)
	await tw.finished
	turn_announce.hide()

func show_victory(text: String):
	if not turn_announce: return
	turn_announce.text = text
	turn_announce.modulate = Color(1, 1, 1, 0)
	turn_announce.show()
	var tw = create_tween()
	tw.tween_property(turn_announce, "modulate", Color(1, 1, 1, 1), 1.0)
	tw.tween_interval(3.0)
	tw.tween_property(turn_announce, "modulate", Color(1, 1, 1, 0), 1.5)
	await tw.finished
	turn_announce.hide()

# ===== Signal Handlers =====

func _on_phase_changed(phase: int):
	match phase:
		0:
			show_turn_announce("玩家回合")
			add_log("=== 玩家回合 ===")
			_phase_label.text = "玩家回合"
			_phase_label.add_theme_color_override("font_color", Color(0.27, 0.67, 0.53))
		1:
			show_turn_announce("敌方回合")
			add_log("=== 敌方回合 ===")
			_phase_label.text = "敌方回合"
			_phase_label.add_theme_color_override("font_color", Color(0.8, 0.27, 0.27))

func _on_cp_changed(points: int):
	_cp_label.text = str(points)

func _on_supply_changed(pool: int):
	_supply_label.text = "充足" if pool > 0 else "紧缺"
	_supply_label.add_theme_color_override("font_color", Color(0.33, 0.8, 0.33) if pool > 0 else Color(1.0, 0.53, 0.53))

func _on_turn_ended(turn: int):
	_turn_label.text = "回合 " + str(turn)

func _on_end_turn():
	if GameManager.current_phase == 0:
		var ctrl = _find_main_controller()
		if ctrl and ctrl.has_method("_deselect_squad"):
			ctrl._deselect_squad()
		add_log("[系统] 结束回合")
		hide_action_menu()
		GameManager.end_player_turn()

func _on_wait_pressed():
	var ctrl = _find_main_controller()
	if ctrl and ctrl.has_method("_on_squad_wait"):
		ctrl._on_squad_wait()
	hide_action_menu()

func _on_assault_pressed():
	var ctrl = _find_main_controller()
	if ctrl and ctrl.has_method("_on_squad_assault"):
		ctrl._on_squad_assault()
	hide_action_menu()

func _on_eng_trench():
	hide_action_menu()
	var ctrl = _find_main_controller()
	if ctrl and ctrl.has_method("_on_trench_build"):
		ctrl._on_trench_build()

func _on_eng_mine():
	hide_action_menu()
	var ctrl = _find_main_controller()
	if ctrl and ctrl.has_method("_on_mine_build"):
		ctrl._on_mine_build()

func _on_eng_clear():
	hide_action_menu()
	var ctrl = _find_main_controller()
	if ctrl and ctrl.has_method("_on_mine_clear"):
		ctrl._on_mine_clear()

func _on_supply_pressed():
	hide_action_menu()
	var ctrl = _find_main_controller()
	if ctrl and ctrl.has_method("_execute_supply"):
		ctrl._execute_supply()

func _on_cmd_close():
	_cmd_detail.hide()

func _toggle_log():
	log_panel.visible = not log_panel.visible
	if log_panel.visible:
		_storage_panel.hide()

func _toggle_storage():
	_storage_panel.visible = not _storage_panel.visible
	if _storage_panel.visible:
		_refresh_storage()

func _refresh_storage():
	if not _storage_list: return
	for c in _storage_list.get_children():
		c.queue_free()
	var storage = GameManager.reserve_storage
	if storage.is_empty():
		var empty = Label.new()
		empty.text = "储备库为空"
		empty.add_theme_font_size_override("font_size", 13)
		empty.add_theme_color_override("font_color", Color(0.67, 0.67, 0.67))
		_storage_list.add_child(empty)
		return
	var names = storage.keys()
	names.sort()
	for wn in names:
		var cnt = storage[wn]
		var row = HBoxContainer.new()
		var lbl = Label.new()
		lbl.text = wn + "  ×" + str(cnt)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.87, 0.87, 0.87))
		row.add_child(lbl)
		_storage_list.add_child(row)

func _show_clear_if_needed():
	var ctrl = _find_main_controller()
	var can_clear = ctrl and ctrl.has_method("_can_clear_mine") and ctrl._can_clear_mine()
	if _eng_clear_btn:
		if can_clear:
			_eng_clear_btn.show()
			_eng_clear_btn.add_theme_color_override("font_color", Color(0.73, 0.73, 0.73))
		else:
			_eng_clear_btn.hide()

func _find_main_controller():
	var root = get_tree().current_scene
	if root:
		return root
	return null

# Keep skill desc for backward compatibility
static func _skill_desc(s: String) -> String:
	match s:
		"鼓舞士气": return "消耗1AP，所属部队恢复20士气"
		"精确射击": return "消耗1AP，本回合指定武器命中+20%"
		"火力压制": return "消耗1AP，目标部队本回合命中-15%"
		"战术撤退": return "消耗1AP，免费后撤1格(无视ZOC)"
		"战场侦查": return "消耗1AP，揭示周围2格敌军"
		"铁壁防御": return "消耗1AP，本回合掩护减伤翻倍"
		"呼叫炮击": return "消耗3AP，CD3回合，呼叫炮兵轰击目标格"
		"领导力光环": return "被动，所属部队士气下降减缓30%"
		"战术规划": return "被动，所属部队AP上限+1"
		"精准指挥": return "被动，所属部队命中+5%"
		"弹药管理": return "被动，所属部队弹药上限+15%"
		"急行军": return "被动，所属部队移动消耗-1(最低1)"
		"应急治疗": return "消耗1AP，恢复部队HP总量15%"
		"弹药调配": return "消耗1AP，恢复一个武器弹夹"
		"战场抢修": return "消耗1AP，恢复载具HP总量15%"
		"快速侦察": return "消耗1AP，揭示周围3格敌军"
		"经验累积": return "战斗后额外获得10%经验"
		"装甲学校": return "所属装甲部队命中+5%，护甲+2"
		"步兵教导": return "所属步兵部队移动消耗-1，森林命中+10%"
		"炮术训练": return "所属炮兵部队射程+1，命中+5%"
		"侦察出身": return "所属侦察部队移动力+1，隐蔽+15%"
		"工兵训练": return "所属工兵部队建造速度+1回合"
		"防空训练": return "所属防空部队对空命中+15%"
		"冷静": return "部队士气下降速度-20%"
		"敏锐": return "部队回避+10%"
		"坚韧": return "部队溃败阈值降低至20%"
		"果断": return "部队主动技能AP消耗-1(最低1)"
		"细致": return "部队命中+5%"
		"威严": return "部队经验获取+10%"
	return ""
