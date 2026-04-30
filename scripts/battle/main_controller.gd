extends Node2D

const CQB_TERRAINS = ["city", "forest", "ruins", "trench", "bunker"]

var map
var battle
var ai
var ui

var selected_squad = null
var action_mode: String = ""
var valid_hexes = []
var valid_attack_hexes = []

var _cam
var _drag_start: Vector2
var _is_dragging: bool = false
const CAM_SPEED: float = 400.0
const CAM_ZOOM_MIN: float = 0.5
const CAM_ZOOM_MAX: float = 3.0

func _ready():
	map = load("res://scripts/map/hex_map.gd").new()
	map.name = "HexMap"
	add_child(map)
	battle = load("res://scripts/battle/battle_manager.gd").new()
	battle.name = "BattleManager"
	add_child(battle)
	ai = load("res://scripts/ai/ai_controller.gd").new()
	ai.name = "AI"
	add_child(ai)
	_cam = Camera2D.new()
	_cam.name = "Camera2D"
	_cam.zoom = Vector2(1.5, 1.5)
	_cam.enabled = true
	map.add_child(_cam)
	ui = load("res://scripts/ui/ui_manager.gd").new()
	ui.name = "UIManager"
	add_child(ui)
	await get_tree().process_frame
	_spawn_test_squads()
	GameManager.start_battle()

func _process(delta):
	if not _cam: return
	var d = Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): d.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): d.x += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): d.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): d.y += 1
	if d != Vector2.ZERO: _cam.position += d.normalized() * CAM_SPEED * delta

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not _is_dragging: _on_map_clicked()
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and selected_squad: _deselect_squad()
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed: _drag_start = get_global_mouse_position(); _is_dragging = true
			else: _is_dragging = false
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed: _cam.zoom = Vector2(min(CAM_ZOOM_MAX, _cam.zoom.x + 0.2), min(CAM_ZOOM_MAX, _cam.zoom.y + 0.2))
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed: _cam.zoom = Vector2(max(CAM_ZOOM_MIN, _cam.zoom.x - 0.2), max(CAM_ZOOM_MIN, _cam.zoom.y - 0.2))
	if event is InputEventMouseMotion and _is_dragging:
		var p = get_global_mouse_position(); var dd = p - _drag_start; _cam.position -= dd; _drag_start = p
	if event is InputEventMouseMotion and not _is_dragging:
		_update_terrain_tooltip()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and selected_squad: _deselect_squad()

func _on_map_clicked():
	if GameManager.current_phase != 0: return
	var mn = GameManager.hex_map
	if not mn: return
	var hex = mn.pixel_to_hex(get_global_mouse_position())
	if not mn.terrain_grid.has(hex): return
	var clicked = GameManager.get_squad_at(hex)

	if valid_attack_hexes.has(hex):
		if action_mode == "assault":
			_execute_assault(hex); return
		if action_mode == "clear_mine":
			_execute_mine_clear(hex); return
		_execute_attack(hex); return
	if action_mode == "move" and valid_hexes.has(hex) and not valid_attack_hexes.has(hex): _execute_move(hex); return

	if clicked and clicked.is_alive:
		if clicked.team == 0 and not clicked.has_acted and clicked.get_state() != 0:
			if selected_squad != clicked: _select_squad(clicked)
		else: _view_squad(clicked)
	elif selected_squad: _deselect_squad()

func _select_squad(squad):
	if selected_squad == squad: return
	_deselect_squad()
	selected_squad = squad
	ui.show_squad_info(squad)
	var mn = GameManager.hex_map
	if not mn: return
	var move_hexes = mn.get_reachable_hexes(squad.hex_coord, squad.get_remaining_movement_ap())
	valid_attack_hexes = _find_attackable_hexes(squad)

	# 过滤ZOC格子：进入ZOC的会停，标记它们
	var zoc_blocked = []
	for h in move_hexes:
		if mn.has_enemy_zoc(h, squad.team):
			zoc_blocked.append(h)

	if move_hexes.size() > 0:
		action_mode = "move"
		valid_hexes = move_hexes
		mn.highlight_hexes(move_hexes, Color(0.3, 0.8, 0.3, 0.4))
		# ZOC格子用橙色标记
		if zoc_blocked.size() > 0:
			for hx in zoc_blocked:
				mn.add_highlight(hx, Color(1.0, 0.6, 0.0, 0.4))
	elif valid_attack_hexes.size() > 0:
		action_mode = "attack"
		valid_hexes = valid_attack_hexes

	if valid_attack_hexes.size() > 0:
		for hx in valid_attack_hexes: mn.add_highlight(hx, Color(0.9, 0.2, 0.2, 0.4))

	ui.show_action_menu()
	if _can_assault(squad):
		ui.show_assault_button(squad.can_afford(3))
	if _is_engineer(squad):
		ui.show_engineer_buttons(squad.ap)
	var msg = "AP:%d" % squad.ap
	if _can_assault(squad): msg += " 可突击(3AP)"
	elif zoc_blocked.size() > 0: msg += " 橙色=ZOC(进入即停)"
	else: msg += " 选移动或攻击"
	ui.show_message(msg)

func _view_squad(squad):
	_deselect_squad()
	ui.show_squad_info(squad)
	ui.show_message("查看: " + squad.squad_name)

func _find_attackable_hexes(squad):
	var mn = GameManager.hex_map
	if not mn or not squad.can_afford(2): return []
	var r = []
	for h in mn.get_attackable_hexes(squad.hex_coord, 3):
		var t = GameManager.get_squad_at(h)
		if t and t.team != squad.team and t.is_alive: r.append(h)
	return r

func _deselect_squad():
	selected_squad = null; action_mode = ""; valid_hexes.clear(); valid_attack_hexes.clear()
	var mn = GameManager.hex_map
	if mn: mn.clear_highlights()
	ui.show_squad_info(null); ui.hide_action_menu()

func _can_assault(squad) -> bool:
	if squad.get_state() == 0: return false
	var mn = GameManager.hex_map
	if not mn: return false

	# 检查相邻敌人是否在CQB地形(地形或overlay)
	for nb in HexUtil.hex_neighbors(squad.hex_coord):
		var t = GameManager.get_squad_at(nb)
		if t and t.team != squad.team and t.is_alive:
			var t_terrain = mn.terrain_grid.get(nb, "plain")
			var ov = mn.get_overlay(nb)
			if ov == "trench" or ov == "bunker":
				return true
			if t_terrain in CQB_TERRAINS:
				return true
	return false

func _on_squad_assault():
	if not selected_squad: return
	if not selected_squad.can_afford(3):
		ui.show_message("AP不足!需要3AP")
		return
	var mn = GameManager.hex_map
	if not mn: return
	mn.clear_highlights()

	# 高亮CQB地形上的相邻敌人
	var cqb_targets = []
	for nb in HexUtil.hex_neighbors(selected_squad.hex_coord):
		var t = GameManager.get_squad_at(nb)
		if t and t.team != selected_squad.team and t.is_alive:
			var terr = mn.terrain_grid.get(nb, "plain")
			var ov = mn.get_overlay(nb)
			if ov == "trench" or ov == "bunker" or terr in CQB_TERRAINS:
				cqb_targets.append(nb)
				mn.add_highlight(nb, Color(0.9, 0.2, 0.2, 0.6))

	if cqb_targets.is_empty(): return
	action_mode = "assault"
	valid_attack_hexes = cqb_targets
	ui.show_message("选择突击目标")

func _execute_assault(hex):
	if not selected_squad: return
	if not selected_squad.can_afford(3):
		ui.show_message("AP不足!需要3AP"); return
	var target = GameManager.get_squad_at(hex)
	if not target or not target.is_alive or target.team == selected_squad.team: return

	var mn = GameManager.hex_map
	if mn: mn.clear_highlights()
	selected_squad.spend_ap(3)

	var result = battle.resolve_cqb(selected_squad, target)
	var msg = "[CQB] " + selected_squad.squad_name + " → " + target.squad_name
	msg += " 命中" + str(result.num_hits) + "次 伤" + str(result.damage_to_defender)
	if result.damage_to_attacker > 0:
		msg += " (受反击" + str(result.damage_to_attacker) + ")"
	if result.defender_destroyed:
		msg += " 目标被摧毁!"
		_try_loot(target)
		# 突击成功且己方存活→占领格子
		if selected_squad.is_alive and selected_squad.get_alive_count() > 0:
			selected_squad.move_to(hex)

	ui.add_log(msg)
	ui.show_message(msg)
	selected_squad.has_acted = true
	selected_squad.update_visual()
	_deselect_squad()
	_check_win_condition()
	_check_all_acted()

func _try_loot(defeated_squad):
	var loot = battle.generate_loot(defeated_squad)
	if loot.is_empty(): return
	# 统计数量
	var counts = {}
	for w in loot:
		counts[w] = counts.get(w, 0) + 1
	var msg = ""
	for wn in counts:
		if msg: msg += ", "
		msg += wn + "×" + str(counts[wn])
		GameManager.add_to_storage(wn, counts[wn])
	ui.add_log("[缴获] 获得: " + msg)

func _is_engineer(squad) -> bool:
	# 兵种ID匹配
	if squad.unit_type_id == "engineer":
		return true
	# 后备: 检查成员武器
	for m in squad.members:
		if not m.is_alive: continue
		for w in m.weapons:
			var wn = w.get("name", "")
			if "工具" in wn or "工兵" in wn:
				return true
	return false

func _on_trench_build():
	if not selected_squad or not selected_squad.can_afford(3): return
	var mn = GameManager.hex_map
	if not mn: return
	var hex = selected_squad.hex_coord
	if mn.has_overlay(hex):
		ui.show_message("该格已有建造物"); return
	mn.set_overlay(hex, "trench", Color(0.5, 0.3, 0.15))
	selected_squad.spend_ap(3)
	selected_squad.has_acted = true
	ui.add_log("[工兵] " + selected_squad.squad_name + " 建造战壕")
	_deselect_squad()
	_check_all_acted()

func _can_clear_mine() -> bool:
	if not selected_squad or not selected_squad.can_afford(2): return false
	var mn = GameManager.hex_map
	if not mn: return false
	for nb in HexUtil.hex_neighbors(selected_squad.hex_coord):
		if mn.get_overlay(nb) == "minefield":
			return true
	return false

func _on_mine_build():
	if not selected_squad or not selected_squad.can_afford(3): return
	var mn = GameManager.hex_map
	if not mn: return
	var hex = selected_squad.hex_coord
	if mn.has_overlay(hex) and mn.get_overlay(hex) == "minefield":
		ui.show_message("该格已有雷区"); return
	mn.set_overlay(hex, "minefield", Color(0.9, 0.1, 0.1))
	selected_squad.spend_ap(3)
	selected_squad.has_acted = true
	ui.add_log("[工兵] " + selected_squad.squad_name + " 布雷")
	_deselect_squad()
	_check_all_acted()

func _on_mine_clear():
	if not selected_squad or not selected_squad.can_afford(2): return
	var mn = GameManager.hex_map
	if not mn: return

	# 高亮相邻雷区
	var targets = []
	for nb in HexUtil.hex_neighbors(selected_squad.hex_coord):
		if mn.get_overlay(nb) == "minefield":
			targets.append(nb)
			mn.add_highlight(nb, Color(0.9, 0.9, 0.2, 0.6))

	if targets.is_empty():
		ui.show_message("相邻无雷区")
		return
	action_mode = "clear_mine"
	valid_attack_hexes = targets
	ui.show_message("选择要排除的雷区")

func _execute_mine_clear(hex):
	if not selected_squad or not selected_squad.can_afford(2): return
	var mn = GameManager.hex_map
	if not mn: return
	if mn.get_overlay(hex) != "minefield":
		ui.show_message("该格不是雷区"); return
	mn.remove_overlay(hex)
	selected_squad.spend_ap(2)
	selected_squad.has_acted = true
	ui.add_log("[工兵] " + selected_squad.squad_name + " 排雷")
	_deselect_squad()
	_check_all_acted()

func _execute_move(hex):
	var mn = GameManager.hex_map
	if not mn or not selected_squad: return

	# 计算完整路径
	var path = mn.find_path(selected_squad.hex_coord, hex, selected_squad)
	if path.size() < 2: return

	# 跳过起点(path[0])，从第一步开始
	var total_cost = 0
	for i in range(1, path.size()):
		total_cost += mn.get_movement_cost(path[i])
	if not selected_squad.can_afford(total_cost): return

	mn.clear_highlights()

	# 逐步移动动画
	for i in range(1, path.size()):
		var step = path[i]
		var step_cost = mn.get_movement_cost(step)
		selected_squad.move_to(step)
		selected_squad.spend_ap(step_cost)
		await get_tree().create_timer(0.12).timeout

	# 更新信息面板
	ui.show_squad_info(selected_squad)

	# 雷区检测
	if mn.get_overlay(selected_squad.hex_coord) == "minefield":
		selected_squad.take_damage(10)
		mn.remove_overlay(selected_squad.hex_coord)
		ui.add_log("[雷区] " + selected_squad.squad_name + " 触发地雷!")
		if not selected_squad.is_alive:
			_deselect_squad()
			_check_win_condition()
			return

	_show_attack_options(selected_squad)

func _show_attack_options(squad):
	var mn = GameManager.hex_map
	if not mn: return
	var attack_hexes = _find_attackable_hexes(squad)
	if attack_hexes.size() > 0:
		action_mode = "attack"; valid_hexes = attack_hexes; valid_attack_hexes = attack_hexes
		mn.highlight_hexes(attack_hexes, Color(0.9, 0.2, 0.2, 0.4))
		ui.show_message("AP:%d 选目标攻击或待机" % squad.ap)
	else:
		ui.show_message("AP:%d 无攻击目标" % squad.ap)
	# 移动后检查CQB
	if _can_assault(squad):
		ui.show_assault_button(squad.can_afford(3))
	ui.show_action_menu()

func _end_squad_action():
	if not selected_squad: return
	var mn = GameManager.hex_map
	if mn: mn.clear_highlights()
	selected_squad.has_acted = true
	selected_squad.update_visual()
	ui.add_log(selected_squad.squad_name + " 行动完毕")
	_deselect_squad()
	_check_all_acted()

func _on_squad_wait():
	if selected_squad: _end_squad_action()

func _execute_attack(hex):
	var mn = GameManager.hex_map
	if not mn or not selected_squad: return
	mn.clear_highlights()
	var target = GameManager.get_squad_at(hex)
	if target and target.is_alive and target.team != selected_squad.team:
		# 检查ZOC:在ZOC内攻击有命中惩罚(已在内置射手公式),但允许攻击
		var result = battle.resolve_combat(selected_squad, target)
		var msg = "[攻击] " + selected_squad.squad_name + " → " + target.squad_name
		msg += " 命中" + str(result.num_hits) + "次 伤" + str(result.damage_to_defender)
		if result.damage_to_attacker > 0: msg += " (反击" + str(result.num_counter_hits) + "次 伤" + str(result.damage_to_attacker) + ")"
		if result.defender_destroyed:
			msg += " 目标被摧毁!"
			_try_loot(target)
		ui.add_log(msg)
		ui.show_message(msg)
	_deselect_squad()
	_check_win_condition()
	_check_all_acted()

func _check_all_acted():
	if GameManager.current_phase != 0: return
	for sq in GameManager.player_squads:
		if sq.is_alive and not sq.has_acted: return
	ui.add_log("[系统] 全部部队行动完毕")
	ui.show_message("全部部队行动完毕")
	await get_tree().create_timer(1.0).timeout
	GameManager.end_player_turn()

func _spawn_test_squads():
	var mn = GameManager.hex_map
	if not mn: return
	var ss = load("res://scripts/core/squad.gd")
	var wd = preload("res://scripts/core/weapon_data.gd")
	var ms = preload("res://scripts/core/member.gd")

	# 设定地形：把部分区域设为城市/森林用于CQB测试
	mn.terrain_grid[Vector2i(3,2)] = "city"
	mn.terrain_grid[Vector2i(3,3)] = "city"
	mn.terrain_grid[Vector2i(3,4)] = "city"

	# 玩家部队
	var pd = [
		{"id": "infantry", "hex": Vector2i(0, 3)},       # 普通步兵
		{"id": "smg", "hex": Vector2i(2, 2)},            # 冲锋枪班(近战)
		{"id": "tank", "hex": Vector2i(1, 4)},           # 坦克
		{"id": "engineer", "hex": Vector2i(4, 1)},       # 工兵
	]
	var ed = [
		{"id": "tank", "hex": Vector2i(6, 3)},           # 敌方坦克
		{"id": "infantry", "hex": Vector2i(4, 3)},       # 敌方步兵(在城市)
		{"id": "infantry", "hex": Vector2i(7, 2)},       # 敌方步兵
	]

	for d in pd:
		var sq = ss.new()
		var m = []
		match d.id:
			"tank":
				var mm = ms.new("车长", "vehicle", 15, 50, wd.tank_gun()); mm.armor = 10; m.append(mm)
			"smg":
				m.append(ms.new("班长", "infantry", 12, 65, wd.smg()))
				for i in range(5): m.append(ms.new("突击兵", "infantry", 10, 65, wd.smg()))
				m.append(ms.new("机枪手", "infantry", 12, 55, wd.mg()))
			"engineer":
				m.append(ms.new("工兵长", "infantry", 12, 60, wd.smg()))
				var tools = wd.rifle().duplicate()
				tools["name"] = "工兵工具"
				m.append(ms.new("工兵", "infantry", 10, 55, tools))
			_:
				for i in range(4): m.append(ms.new("步兵", "infantry", 10, 60, wd.rifle()))
				m.append(ms.new("机枪手", "infantry", 12, 55, wd.mg()))
		sq.setup(d.id, 0, d.hex, m); sq.name = "P_" + d.id
		mn.add_child(sq); sq.update_visual(); GameManager.register_squad(sq)

	for d in ed:
		var sq = ss.new()
		var m = []
		if d.id == "tank":
			var mm = ms.new("车长", "vehicle", 15, 50, wd.tank_gun()); mm.armor = 10; m.append(mm)
		else:
			for i in range(4): m.append(ms.new("步兵", "infantry", 10, 55, wd.rifle()))
			m.append(ms.new("机枪手", "infantry", 12, 50, wd.mg()))
		sq.setup(d.id, 1, d.hex, m); sq.name = "E_" + d.id
		mn.add_child(sq); sq.update_visual(); GameManager.register_squad(sq)

	# 预置雷区(overlay层)
	mn.set_overlay(Vector2i(5, 4), "minefield", Color(0.9, 0.1, 0.1))

	# 生成指挥官并任命
	var cmd_script = preload("res://scripts/commander/commander.gd")
	for sq in GameManager.player_squads:
		if sq.is_alive:
			var cmd = cmd_script.new()
			cmd.commander_name = sq.squad_name + "长"
			GameManager.add_commander_to_pool(cmd)
			GameManager.assign_commander(sq, cmd)

func _update_terrain_tooltip():
	var mn = GameManager.hex_map
	if not mn or not ui or not ui.has_method("show_terrain_tooltip"):
		return
	var wp = get_global_mouse_position()
	var hex = mn.pixel_to_hex(wp)
	if not mn.terrain_grid.has(hex):
		ui.hide_terrain_tooltip()
		return

	var tid = mn.terrain_grid.get(hex, "plain")
	var td = mn.get_terrain_at(hex)
	if not td:
		ui.hide_terrain_tooltip()
		return

	var is_cqb = "city,forest,ruins".find(tid) >= 0
	var ov = mn.get_overlay(hex)
	if ov == "trench" or ov == "bunker": is_cqb = true
	var hit_penalty = 0
	match tid:
		"city": hit_penalty = -15
		"forest": hit_penalty = -10
		"mountain": hit_penalty = -20
		"river": hit_penalty = -5

	var txt = td.display_name + "\n"
	if ov:
		txt += "[" + ("战壕" if ov == "trench" else "雷区" if ov == "minefield" else ov) + "]\n"
	txt += "移动消耗: " + str(td.move_cost) + "\n"
	txt += "防御加成: +" + str(td.defense_bonus) + "减伤\n"
	if hit_penalty != 0: txt += "命中惩罚: " + str(hit_penalty) + "%\n"
	if is_cqb: txt += "[CQB地形]"
	ui.show_terrain_tooltip(txt)

func _check_win_condition():
	var ae = 0
	for sq in GameManager.enemy_squads:
		if is_instance_valid(sq) and sq.is_alive: ae += 1
	if ae == 0:
		ui.add_log("[系统] 胜利!所有敌人被消灭!")
		ui.show_victory("胜利!所有敌人被消灭!")
