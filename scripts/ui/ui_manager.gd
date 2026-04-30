extends CanvasLayer

var info_panel: Panel
var squad_name_label: Label
var squad_info_label: Label
var action_menu: VBoxContainer
var turn_label: Label
var cp_label: Label
var phase_label: Label
var message_label: Label
var turn_announce: Label
var end_turn_button: Button

var log_panel: Panel
var log_list: Array = []
var _assault_btn: Button
var _eng_trench_btn: Button
var _eng_mine_btn: Button
var _eng_clear_btn: Button
var _terrain_tooltip: Label
var _storage_panel: Panel
var _storage_list: VBoxContainer
var _var_log_label: Label
var _cmd_btn: Button
var _cmd_detail: Panel
var _cmd_detail_label: Label
var _current_cmd_squad = null
var _drag_panel = null
var _drag_offset: Vector2

func _ready():
	GameManager.ui_manager = self
	GameManager.phase_changed.connect(_on_phase_changed)
	GameManager.command_points_changed.connect(_on_cp_changed)
	GameManager.turn_ended.connect(_on_turn_ended)
	await get_tree().process_frame
	_build_ui()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			for p in [_cmd_detail, log_panel, _storage_panel]:
				if p and p.visible and event.position.x >= p.position.x and event.position.x <= p.position.x + p.size.x and event.position.y >= p.position.y and event.position.y <= p.position.y + p.size.y:
					_drag_panel = p
					_drag_offset = p.position - event.position
					break
		else:
			_drag_panel = null
	if event is InputEventMouseMotion and _drag_panel:
		_drag_panel.position = event.position + _drag_offset

func _build_ui():
	var screen = get_viewport().size

	info_panel = Panel.new()
	info_panel.position = Vector2(10, 10)
	info_panel.size = Vector2(220, 105)
	info_panel.hide()
	add_child(info_panel)

	squad_name_label = Label.new()
	squad_name_label.position = Vector2(10, 10)
	squad_name_label.size = Vector2(200, 20)
	info_panel.add_child(squad_name_label)

	squad_info_label = Label.new()
	squad_info_label.position = Vector2(10, 35)
	squad_info_label.size = Vector2(200, 80)
	squad_info_label.add_theme_font_size_override("font_size", 9)
	info_panel.add_child(squad_info_label)

	# 指挥官按钮（在信息面板下方）
	_cmd_btn = Button.new()
	_cmd_btn.position = Vector2(10, 118)
	_cmd_btn.text = "指挥官"
	_cmd_btn.pressed.connect(_on_cmd_btn)
	_cmd_btn.hide()
	add_child(_cmd_btn)

	# 指挥官详情弹窗
	_cmd_detail = Panel.new()
	_cmd_detail.position = Vector2(260, 10)
	_cmd_detail.size = Vector2(300, 250)
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

	action_menu = VBoxContainer.new()
	action_menu.position = Vector2(240, 10)
	action_menu.hide()
	add_child(action_menu)

	var wait_btn = Button.new()
	wait_btn.text = "待机"
	wait_btn.pressed.connect(_on_wait_pressed)
	action_menu.add_child(wait_btn)

	_assault_btn = Button.new()
	_assault_btn.text = "突击(3AP)"
	_assault_btn.pressed.connect(_on_assault_pressed)
	_assault_btn.hide()
	action_menu.add_child(_assault_btn)

	_eng_trench_btn = Button.new()
	_eng_trench_btn.text = "挖战壕(3AP)"
	_eng_trench_btn.pressed.connect(_on_eng_trench)
	_eng_trench_btn.hide()
	action_menu.add_child(_eng_trench_btn)

	_eng_mine_btn = Button.new()
	_eng_mine_btn.text = "布雷(3AP)"
	_eng_mine_btn.pressed.connect(_on_eng_mine)
	_eng_mine_btn.hide()
	action_menu.add_child(_eng_mine_btn)

	_eng_clear_btn = Button.new()
	_eng_clear_btn.text = "排雷(2AP)"
	_eng_clear_btn.pressed.connect(_on_eng_clear)
	_eng_clear_btn.hide()
	action_menu.add_child(_eng_clear_btn)

	turn_label = Label.new()
	turn_label.position = Vector2(screen.x - 150, 35)
	turn_label.text = "回合 1"
	turn_label.add_theme_font_size_override("font_size", 16)
	add_child(turn_label)

	cp_label = Label.new()
	cp_label.position = Vector2(screen.x - 150, 60)
	cp_label.text = "货币: 100"
	cp_label.add_theme_font_size_override("font_size", 16)
	add_child(cp_label)

	phase_label = Label.new()
	phase_label.position = Vector2(screen.x - 150, 10)
	phase_label.text = ""
	phase_label.add_theme_font_size_override("font_size", 18)
	add_child(phase_label)

	message_label = Label.new()
	message_label.position = Vector2(screen.x / 2 - 200, screen.y - 40)
	message_label.size = Vector2(400, 30)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 16)
	message_label.hide()
	add_child(message_label)

	turn_announce = Label.new()
	turn_announce.position = Vector2(screen.x / 2 - 200, screen.y / 2 - 40)
	turn_announce.size = Vector2(400, 80)
	turn_announce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_announce.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_announce.add_theme_font_size_override("font_size", 48)
	turn_announce.add_theme_color_override("font_color", Color(1, 1, 1))
	turn_announce.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	turn_announce.add_theme_constant_override("outline_size", 4)
	turn_announce.modulate = Color(1, 1, 1, 0)
	turn_announce.hide()
	add_child(turn_announce)

	# 战斗日志 - 放大+可滑动
	log_panel = Panel.new()
	log_panel.position = Vector2(screen.x - 360, screen.y - 360)
	log_panel.size = Vector2(350, 300)
	log_panel.hide()
	add_child(log_panel)

	var log_title = Label.new()
	log_title.position = Vector2(10, 10)
	log_title.text = "战斗日志"
	log_title.add_theme_font_size_override("font_size", 16)
	log_panel.add_child(log_title)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(10, 35)
	scroll.size = Vector2(330, 255)
	log_panel.add_child(scroll)

	_var_log_label = Label.new()
	_var_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_var_log_label.custom_minimum_size.x = 310
	_var_log_label.add_theme_font_size_override("font_size", 12)
	_var_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(_var_log_label)

	var log_toggle = Button.new()
	log_toggle.position = Vector2(screen.x - 120, screen.y - 370)
	log_toggle.text = "日志"
	log_toggle.pressed.connect(_toggle_log)
	add_child(log_toggle)

	# 储备库按钮
	var storage_btn = Button.new()
	storage_btn.position = Vector2(screen.x - 200, screen.y - 370)
	storage_btn.text = "储备库"
	storage_btn.pressed.connect(_toggle_storage)
	add_child(storage_btn)

	# 储备库面板
	_storage_panel = Panel.new()
	_storage_panel.position = Vector2(screen.x - 400, screen.y - 450)
	_storage_panel.size = Vector2(390, 400)
	_storage_panel.hide()
	add_child(_storage_panel)

	var st_title = Label.new()
	st_title.position = Vector2(10, 10)
	st_title.text = "储备库"
	st_title.add_theme_font_size_override("font_size", 16)
	_storage_panel.add_child(st_title)

	var st_scroll = ScrollContainer.new()
	st_scroll.position = Vector2(10, 35)
	st_scroll.size = Vector2(370, 320)
	_storage_panel.add_child(st_scroll)

	_storage_list = VBoxContainer.new()
	_storage_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_storage_list.custom_minimum_size.x = 350
	st_scroll.add_child(_storage_list)

	var st_close = Button.new()
	st_close.position = Vector2(340, 370)
	st_close.text = "关闭"
	st_close.pressed.connect(_toggle_storage)
	_storage_panel.add_child(st_close)

	_terrain_tooltip = Label.new()
	_terrain_tooltip.add_theme_font_size_override("font_size", 11)
	_terrain_tooltip.add_theme_color_override("font_color", Color(1, 1, 1))
	_terrain_tooltip.add_theme_color_override("bg_color", Color(0, 0, 0, 0.7))
	_terrain_tooltip.add_theme_stylebox_override("normal", _make_tooltip_bg())
	_terrain_tooltip.position = Vector2(10, screen.y - 140)
	_terrain_tooltip.size = Vector2(200, 90)
	_terrain_tooltip.hide()
	add_child(_terrain_tooltip)

	end_turn_button = Button.new()
	end_turn_button.position = Vector2(screen.x - 130, screen.y - 40)
	end_turn_button.text = "结束回合"
	end_turn_button.pressed.connect(_on_end_turn)
	add_child(end_turn_button)

func _make_tooltip_bg():
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.7)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(1, 1, 1, 0.3))
	return sb

func show_terrain_tooltip(text: String):
	if _terrain_tooltip:
		_terrain_tooltip.text = text
		_terrain_tooltip.show()

func hide_terrain_tooltip():
	if _terrain_tooltip:
		_terrain_tooltip.hide()

# 技能效果说明
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
		# 背景技能
		"装甲学校": return "所属装甲部队命中+5%，护甲+2"
		"步兵教导": return "所属步兵部队移动消耗-1，森林命中+10%"
		"炮术训练": return "所属炮兵部队射程+1，命中+5%"
		"侦察出身": return "所属侦察部队移动力+1，隐蔽+15%"
		"工兵训练": return "所属工兵部队建造速度+1回合"
		"防空训练": return "所属防空部队对空命中+15%"
		# 天赋技能
		"冷静": return "部队士气下降速度-20%"
		"敏锐": return "部队回避+10%"
		"坚韧": return "部队溃败阈值降低至20%"
		"果断": return "部队主动技能AP消耗-1(最低1)"
		"细致": return "部队命中+5%"
		"威严": return "部队经验获取+10%"
	return ""

func _on_cmd_close():
	if _cmd_detail: _cmd_detail.hide()

func _make_skill_label(skill: String) -> Label:
	var lbl = Label.new()
	var display = skill
	if skill.ends_with("(Lv2)"):
		display = skill.replace("(Lv2)", "") + " Lv.2"
	lbl.text = "  " + display
	lbl.add_theme_font_size_override("font_size", 12)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.6)
	lbl.add_theme_stylebox_override("normal", sb)
	return lbl

func _make_skill_row(skill: String, parent: VBoxContainer):
	var lbl = _make_skill_label(skill)
	parent.add_child(lbl)
	# 技能说明（小字灰色）
	var clean = skill.replace("(Lv2)", "")
	var desc = _skill_desc(clean)
	if desc != clean and desc != "":
		var d = Label.new()
		d.text = "    " + desc
		d.add_theme_font_size_override("font_size", 10)
		d.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		parent.add_child(d)

func _on_cmd_btn():
	if not _cmd_detail or not _current_cmd_squad: return
	var cmd = GameManager.get_commander(_current_cmd_squad)
	if not cmd:
		_cmd_detail.hide()
		return

	# 清空旧内容
	for c in _cmd_detail.get_children():
		if c == _cmd_detail_label: continue
		if c is Button: continue
		c.queue_free()

	# 用scroll展示技能
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(10, 10)
	scroll.size = Vector2(280, 200)
	_cmd_detail.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.custom_minimum_size.x = 260
	scroll.add_child(vbox)

	vbox.add_child(_make_skill_label("名称: " + cmd.commander_name))
	vbox.add_child(_make_skill_label("等级: " + str(cmd.level) + "/10  经验: " + str(cmd._exp)))

	vbox.add_child(Label.new())  # spacer

	var bg_lbl = _make_skill_label("背景: " + cmd.background_skill)
	bg_lbl.add_theme_color_override("font_color", Color(0.6, 1, 0.6))
	vbox.add_child(bg_lbl)
	_make_skill_row(cmd.background_skill, vbox)

	var tal_lbl = _make_skill_label("天赋: " + cmd.talent_skill)
	tal_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 1))
	vbox.add_child(tal_lbl)
	_make_skill_row(cmd.talent_skill, vbox)

	for s in cmd.quality_skills:
		var qlbl = _make_skill_label("品质: " + s)
		qlbl.add_theme_color_override("font_color", Color(1, 0.8, 0.6))
		vbox.add_child(qlbl)
		_make_skill_row(s, vbox)

	for s in cmd.level_skills:
		var llbl = _make_skill_label("升级: " + s)
		llbl.add_theme_color_override("font_color", Color(1, 1, 0.6))
		vbox.add_child(llbl)
		_make_skill_row(s, vbox)

	_cmd_detail_label.text = ""  # 不再使用大文本
	_cmd_detail.show()

func _toggle_log():
	log_panel.visible = not log_panel.visible

func _toggle_storage():
	if _storage_panel:
		_storage_panel.visible = not _storage_panel.visible
		if _storage_panel.visible:
			_refresh_storage()

func _refresh_storage():
	if not _storage_list: return
	# 清空旧内容
	for c in _storage_list.get_children():
		c.queue_free()
	# 从GameManager读取储备库数据
	var storage = GameManager.reserve_storage
	if storage.is_empty():
		var empty = Label.new()
		empty.text = "储备库为空"
		empty.add_theme_font_size_override("font_size", 14)
		_storage_list.add_child(empty)
		return
	# 按名称排序
	var names = storage.keys()
	names.sort()
	for wn in names:
		var cnt = storage[wn]
		var row = HBoxContainer.new()
		var lbl = Label.new()
		lbl.text = wn + "  ×" + str(cnt)
		lbl.add_theme_font_size_override("font_size", 14)
		row.add_child(lbl)
		_storage_list.add_child(row)

func add_log(text: String):
	log_list.append(text)
	if log_list.size() > 100:
		log_list.pop_front()
	_var_log_label.text = "\n".join(log_list)

func show_squad_info(squad):
	if not squad or not squad.is_alive:
		info_panel.hide()
		if _cmd_btn: _cmd_btn.hide()
		if _cmd_detail: _cmd_detail.hide()
		_current_cmd_squad = null
		return
	info_panel.show()
	squad_name_label.text = squad.squad_name
	_current_cmd_squad = squad
	var info = "成员:%d/%d  状态:%s\n士气:%d  压制:%d  AP:%d/%d" % [squad.get_alive_count(), squad.get_total_count(), squad.get_state_name(), squad.morale, squad.suppression, squad.ap, squad.max_ap]
	if squad.get_alive_count() > 0:
		var m = squad.members[0]
		info += "\n示例: " + m.member_name + " HP:" + str(m.hp) + "/" + str(m.max_hp)
	info += "\n武器: " + squad.get_weapon_summary()
	# 指挥官信息
	var cmd = GameManager.get_commander(squad)
	if cmd:
		info += "\n指挥官: " + cmd.commander_name + " Lv." + str(cmd.level)
		if _cmd_btn: _cmd_btn.show()
	else:
		info += "\n[无指挥官]"
		if _cmd_btn: _cmd_btn.hide()
	if _cmd_detail: _cmd_detail.hide()
	# ZOC影响
	var mn = GameManager.hex_map
	if mn and mn.has_enemy_zoc(squad.hex_coord, squad.team):
		info += "\n⚠ 敌方ZOC内: 命中-10% 每回合+5压制"
	squad_info_label.text = info

func show_action_menu():
	action_menu.show()

func hide_action_menu():
	action_menu.hide()
	if _assault_btn: _assault_btn.hide()
	if _eng_trench_btn: _eng_trench_btn.hide()
	if _eng_mine_btn: _eng_mine_btn.hide()
	if _eng_clear_btn: _eng_clear_btn.hide()

func show_assault_button(ap_ok: bool = true):
	if _assault_btn:
		_assault_btn.show()
		var c = Color(1, 1, 1) if ap_ok else Color(1, 0.3, 0.3)
		_assault_btn.add_theme_color_override("font_color", c)

func show_engineer_buttons(ap: int = 4):
	if _eng_trench_btn:
		_eng_trench_btn.show()
		_eng_trench_btn.add_theme_color_override("font_color", Color(1, 1, 1) if ap >= 3 else Color(1, 0.3, 0.3))
	if _eng_mine_btn:
		_eng_mine_btn.show()
		_eng_mine_btn.add_theme_color_override("font_color", Color(1, 1, 1) if ap >= 3 else Color(1, 0.3, 0.3))
	# 排雷
	_show_clear_if_needed()

func _show_clear_if_needed():
	var ctrl = _find_main_controller()
	var can_clear = ctrl and ctrl.has_method("_can_clear_mine") and ctrl._can_clear_mine()
	if _eng_clear_btn:
		if can_clear:
			_eng_clear_btn.show()
			_eng_clear_btn.add_theme_color_override("font_color", Color(1, 1, 1))
		else:
			_eng_clear_btn.hide()

func hide_engineer_buttons():
	if _eng_trench_btn: _eng_trench_btn.hide()
	if _eng_mine_btn: _eng_mine_btn.hide()
	if _eng_clear_btn: _eng_clear_btn.hide()

func _on_wait_pressed():
	var ctrl = _find_main_controller()
	if ctrl and ctrl.has_method("_on_squad_wait"):
		ctrl._on_squad_wait()
	hide_action_menu()
	if _assault_btn: _assault_btn.hide()

func _on_assault_pressed():
	var ctrl = _find_main_controller()
	if ctrl and ctrl.has_method("_on_squad_assault"):
		ctrl._on_squad_assault()
	hide_action_menu()
	if _assault_btn: _assault_btn.hide()

func _on_eng_trench():
	hide_action_menu()
	if _eng_trench_btn: _eng_trench_btn.hide()
	var ctrl = _find_main_controller()
	if ctrl and ctrl.has_method("_on_trench_build"):
		ctrl._on_trench_build()

func _on_eng_mine():
	hide_action_menu()
	if _eng_mine_btn: _eng_mine_btn.hide()
	var ctrl = _find_main_controller()
	if ctrl and ctrl.has_method("_on_mine_build"):
		ctrl._on_mine_build()

func _on_eng_clear():
	hide_action_menu()
	if _eng_clear_btn: _eng_clear_btn.hide()
	var ctrl = _find_main_controller()
	if ctrl and ctrl.has_method("_on_mine_clear"):
		ctrl._on_mine_clear()

func show_message(text: String):
	if not message_label:
		return
	message_label.text = text
	message_label.show()
	await get_tree().create_timer(2.0).timeout
	if message_label:
		message_label.hide()

func show_turn_announce(text: String):
	if not turn_announce:
		return
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
	if not turn_announce:
		return
	turn_announce.text = text
	turn_announce.modulate = Color(1, 1, 1, 0)
	turn_announce.show()
	var tw = create_tween()
	tw.tween_property(turn_announce, "modulate", Color(1, 1, 1, 1), 1.0)
	tw.tween_interval(3.0)
	tw.tween_property(turn_announce, "modulate", Color(1, 1, 1, 0), 1.5)
	await tw.finished
	turn_announce.hide()

func _on_end_turn():
	if GameManager.current_phase == 0:
		var ctrl = _find_main_controller()
		if ctrl and ctrl.has_method("_deselect_squad"):
			ctrl._deselect_squad()
		add_log("[系统] 结束回合")
		GameManager.end_player_turn()

func _on_phase_changed(phase: int):
	match phase:
		0:
			show_turn_announce("玩家回合")
			add_log("=== 玩家回合 ===")
		1:
			show_turn_announce("敌方回合")
			add_log("=== 敌方回合 ===")

func _on_cp_changed(points: int):
	cp_label.text = "货币: %d" % points

func _on_turn_ended(turn: int):
	turn_label.text = "回合 %d" % turn
	_var_log_label.text = "\n".join(log_list)

func _find_main_controller():
	var root = get_tree().current_scene
	if root:
		return root
	return null
