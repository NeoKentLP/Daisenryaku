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
const CAM_SPEED: float = 600.0
const CAM_ZOOM_MIN: float = 0.5
const CAM_ZOOM_MAX: float = 3.0

func _ready():
	map = load("res://scripts/map/hex_map.gd").new()
	map.name = "HexMap"
	if GameManager.mission_placed_squads and not GameManager.mission_placed_squads.is_empty():
		map.map_width = 12
		map.map_height = 10
	add_child(map)
	battle = load("res://scripts/battle/battle_manager.gd").new()
	battle.name = "BattleManager"
	add_child(battle)
	ai = load("res://scripts/ai/ai_controller.gd").new()
	ai.name = "AI"
	add_child(ai)
	_cam = Camera2D.new()
	_cam.zoom = Vector2(1.0, 1.0)
	_cam.enabled = true
	map.add_child(_cam)

	# Center camera on map center (matches deployment overview position)
	_cam.position = map.hex_to_pixel(Vector2i(map.map_width / 2, map.map_height / 2))
	ui = load("res://scripts/ui/ui_manager.gd").new()
	ui.name = "UIManager"
	add_child(ui)
	await get_tree().process_frame
	if GameManager.mission_placed_squads and not GameManager.mission_placed_squads.is_empty():
		_spawn_mission_squads()
		GameManager.mission_placed_squads.clear()
	elif GameManager.world_selected_squads.is_empty():
		_spawn_test_squads()
	else:
		_spawn_world_squads()
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
		_show_combat_preview(hex); return
	if action_mode == "move" and valid_hexes.has(hex) and not valid_attack_hexes.has(hex): _execute_move(hex); return

	if clicked and clicked.is_alive:
		if clicked.team == 0 and clicked.unit_type_id == "command" and not clicked.has_acted:
			_view_squad(clicked)
		elif clicked.team == 0 and not clicked.has_acted and clicked.get_state() != 0:
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

	# 按AP层级计算可达范围，用边框区分
	var tiered_hexes = {}  # hex -> ap_cost
	var all_valid = []

	# AP层级1: move_range格内 (1AP)
	if squad.can_afford(1):
		for h in mn.get_reachable_hexes(squad.hex_coord, squad.move_range):
			tiered_hexes[h] = 1
			all_valid.append(h)

	# AP层级2: move_range×2格内 (2AP)
	if squad.can_afford(2):
		for h in mn.get_reachable_hexes(squad.hex_coord, squad.move_range * 2):
			if not tiered_hexes.has(h):
				tiered_hexes[h] = 2
				all_valid.append(h)

	# AP层级3: move_range×3格内 (3AP)
	if squad.can_afford(3):
		for h in mn.get_reachable_hexes(squad.hex_coord, squad.move_range * 3):
			if not tiered_hexes.has(h):
				tiered_hexes[h] = 3
				all_valid.append(h)

	valid_attack_hexes = _find_attackable_hexes(squad)

	# 过滤ZOC格子
	var zoc_blocked = []
	for h in all_valid:
		if mn.has_enemy_zoc(h, squad.team):
			zoc_blocked.append(h)

	if all_valid.size() > 0:
		action_mode = "move"
		valid_hexes = all_valid
		mn.highlight_hexes_tiered(tiered_hexes)
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
	if _can_supply(squad):
		ui.show_supply_button(true)
	var msg = "AP:%d  移%d格/次" % [squad.ap, squad.move_range]
	if _can_supply(squad): msg += " 可补给(1AP)"
	elif _can_assault(squad): msg += " 可突击(3AP)"
	elif zoc_blocked.size() > 0: msg += " 橙色=ZOC(进入即停)"
	else: msg += " 选格子移动(边框=消耗多AP)"
	ui.show_message(msg)

func _can_supply(squad) -> bool:
	if not squad or not squad.is_alive: return false
	if not squad.needs_supply(): return false
	if not squad.can_afford(1): return false
	return squad.is_near_supply_source()

func _execute_supply():
	if not selected_squad: return
	if not _can_supply(selected_squad):
		ui.show_message("无法补给")
		return
	var mn = GameManager.hex_map
	if mn: mn.clear_highlights()
	selected_squad.resupply()
	selected_squad.spend_ap(1)
	ui.add_log("[补给] " + selected_squad.squad_name + " 已补给")
	ui.show_message("补给完成")
	ui.show_squad_info(selected_squad)
	if not selected_squad.can_afford(2):
		selected_squad.has_acted = true
		selected_squad.update_visual()
	_deselect_squad()
	_check_all_acted()

func _view_squad(squad):
	_deselect_squad()
	ui.show_squad_info(squad)
	ui.show_message("查看: " + squad.squad_name)

func _find_attackable_hexes(squad):
	var mn = GameManager.hex_map
	if not mn or not squad.can_afford(2) or not squad.has_ammo(): return []
	var max_range = _get_squad_max_range(squad)
	var r = []
	for h in mn.get_attackable_hexes(squad.hex_coord, max_range):
		var t = GameManager.get_squad_at(h)
		if t and t.team != squad.team and t.is_alive: r.append(h)
	return r

func _get_squad_max_range(squad) -> int:
	var mr = 0
	for m in squad.members:
		if not m.is_alive: continue
		for w in m.weapons:
			if w.get("ammo", 0) <= 0: continue
			var r = w.get("range_max", 1)
			if r > mr: mr = r
	return mr

func _deselect_squad():
	selected_squad = null; action_mode = ""; valid_hexes.clear(); valid_attack_hexes.clear()
	var mn = GameManager.hex_map
	if mn: mn.clear_highlights()
	ui.show_squad_info(null); ui.hide_action_menu()

func _can_assault(squad) -> bool:
	if squad.get_state() == 0: return false
	if not squad.has_ammo(): return false
	var mn = GameManager.hex_map
	if not mn: return false

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
	if not selected_squad.has_ammo():
		ui.show_message("弹药耗尽!无法突击")
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

	# 计算移动需要的AP数
	var dist = HexUtil.hex_distance(selected_squad.hex_coord, hex)
	var ap_needed = max(1, int(ceil(float(dist) / selected_squad.move_range)))
	if not selected_squad.can_afford(ap_needed): return

	# 计算完整路径
	var path = mn.find_path(selected_squad.hex_coord, hex, selected_squad)
	if path.size() < 2: return
	# 路径格数不能超过move_range×AP
	if path.size() - 1 > selected_squad.move_range * ap_needed: return

	mn.clear_highlights()

	# 逐步移动动画，每 move_range 格计为1次移动动作
	var prev_hex = selected_squad.hex_coord
	var steps_in_action = 0
	for i in range(1, path.size()):
		var step = path[i]
		steps_in_action += 1

		# ZOC脱离检查
		if mn.has_enemy_zoc(prev_hex, selected_squad.team):
			if not mn.has_enemy_zoc(step, selected_squad.team):
				if battle and battle.has_method("resolve_zoc_attack"):
					var zoc_result = battle.resolve_zoc_attack(selected_squad)
					if zoc_result:
						var zmsg = "[ZOC] " + selected_squad.squad_name + " 遭" + zoc_result.attacker.squad_name + "借机攻击 伤" + str(zoc_result.damage)
						ui.add_log(zmsg)

		selected_squad.move_to(step)
		prev_hex = step
		await get_tree().create_timer(0.12).timeout

	# 移动消耗对应AP
	selected_squad.spend_ap(ap_needed)

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

	# 还有AP则继续选中显示范围
	if selected_squad.ap > 0 and not selected_squad.has_acted:
		var sq = selected_squad
		_deselect_squad()
		_select_squad(sq)
	else:
		_show_attack_options(selected_squad)

func _show_attack_options(squad):
	var mn = GameManager.hex_map
	if not mn: return
	var attack_hexes = _find_attackable_hexes(squad)
	if attack_hexes.size() > 0:
		action_mode = "attack"; valid_hexes = attack_hexes; valid_attack_hexes = attack_hexes
		mn.highlight_hexes(attack_hexes, Color(0.9, 0.2, 0.2, 0.5))
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

func _show_combat_preview(hex):
	var target = GameManager.get_squad_at(hex)
	if not target or not target.is_alive or target.team == selected_squad.team: return
	var preview = preload("res://scenes/ui/combat_preview.tscn").instantiate()
	add_child(preview)
	preview.open(selected_squad, target, func(selected_types):
		_execute_attack(hex)
	)

func _execute_attack(hex):
	var mn = GameManager.hex_map
	if not mn or not selected_squad: return
	mn.clear_highlights()
	var target = GameManager.get_squad_at(hex)
	if target and target.is_alive and target.team != selected_squad.team:
		var result = battle.resolve_combat(selected_squad, target)

		result["attacker_name"] = selected_squad.squad_name
		result["defender_name"] = target.squad_name

		# Show combat flow panel
		var flow = preload("res://scenes/ui/combat_flow.tscn").instantiate()
		add_child(flow)
		flow.open(result, func():
			if result.defender_destroyed:
				_try_loot(target)
			_deselect_squad()
			_check_win_condition()
			_check_all_acted()
		)
	else:
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

func _spawn_world_squads():
	var mn = GameManager.hex_map
	if not mn: return
	var selected = GameManager.world_selected_squads
	var start_hexes = [Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4), Vector2i(0, 5)]
	for i in range(selected.size()):
		var sq = selected[i]
		if i < start_hexes.size():
			mn.add_child(sq)
			sq.hex_coord = start_hexes[i]
			sq.position = mn.hex_to_pixel(start_hexes[i])
			sq.update_visual()
			GameManager.register_squad(sq)
	# 敌方(从encounter_node读部队配置)
	var nd = GameManager.world_encounter_node
	var enemy_count = 2
	if nd and nd.has("enemy_garrison"):
		enemy_count = nd["enemy_garrison"]
	_spawn_enemy_squads(enemy_count)
	# 清空世界选择
	GameManager.world_selected_squads.clear()

func _spawn_enemy_squads(count: int):
	var mn = GameManager.hex_map
	if not mn: return
	var ss = load("res://scripts/core/squad.gd")
	var wd = preload("res://scripts/core/weapon_data.gd")
	var ms = preload("res://scripts/core/member.gd")
	var enemy_hexes = [Vector2i(8, 2), Vector2i(8, 4), Vector2i(10, 3), Vector2i(6, 5)]
	for i in range(min(count, enemy_hexes.size())):
		var sq = ss.new()
		var m = []
		for j in range(4):
			m.append(ms.new("步兵", "infantry", 10, 55, wd.rifle()))
		m.append(ms.new("机枪手", "infantry", 12, 50, wd.mg()))
		sq.setup("infantry", 1, enemy_hexes[i], m)
		sq.name = "E_" + str(i)
		mn.add_child(sq)
		sq.update_visual()
		GameManager.register_squad(sq)

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
	if mn.is_supply_station(hex): txt += "\n[补给站]"
	ui.show_terrain_tooltip(txt, wp)

func _return_to_world():
	GameManager.enemy_squads.clear()
	GameManager.player_squads.clear()
	GameManager.all_squads.clear()
	var scene = load("res://scenes/world/world_map.tscn")
	get_tree().change_scene_to_packed(scene)

func _spawn_mission_squads():
	var mn = GameManager.hex_map
	if not mn: return

	_setup_prologue_terrain(mn)

	var ss = load("res://scripts/core/squad.gd")
	var ms = preload("res://scripts/core/member.gd")

	var nation_enemy = {"germany": "soviet", "soviet": "germany"}
	var _enemy_nat = nation_enemy.get(GameManager.selected_nation, "soviet")

	# Create HQ as special squad unit (not terrain)
	var hq_member = ms.new("HQ", "command", 50, 60)
	hq_member.armor = 5
	var hq = ss.new()
	hq.setup("command", 0, Vector2i(5, 8), [hq_member])
	hq.name = "HQ"
	hq.squad_name = "己方指挥部"
	hq.morale = 100
	hq.max_morale = 100
	mn.add_child(hq)
	hq.update_visual()
	GameManager.register_squad(hq)

	# Spawn player squads from deployment data
	var placed = GameManager.mission_placed_squads
	if placed and not placed.is_empty():
		var cmd_idx = 0
		for hex in placed:
			var sd = placed[hex]
			var sq = ss.new()
			var members = []
			for m_data in sd.members:
				var m = ms.new(m_data.member_name, m_data.member_type, m_data.hp, m_data.bs)
				for w in m_data.weapons:
					m.weapons.append(w.duplicate())
				m.armor = m_data.armor
				m.evasion = m_data.evasion
				m.concealment = m_data.concealment
				m.is_alive = m_data.is_alive
				m.hp = m_data.hp
				m.max_hp = m_data.max_hp
				members.append(m)
			sq.setup(sd.type, 0, hex, members)
			sq.name = "P_" + sd.name
			mn.add_child(sq)
			sq.update_visual()
			GameManager.register_squad(sq)

			# Assign commander
			if cmd_idx < GameManager.initial_commanders.size():
				var cmd = GameManager.initial_commanders[cmd_idx]
				GameManager.assign_commander(sq, cmd)
			cmd_idx += 1

	# Spawn enemy squads around enemy HQ at (5, 1)
	var enemy_units = _get_enemy_squads()
	var enemy_hexes = [Vector2i(5, 2), Vector2i(4, 1), Vector2i(6, 1)]
	for i in range(min(enemy_units.size(), enemy_hexes.size())):
		var hex = enemy_hexes[i]
		var eu = enemy_units[i]
		var sq = ss.new()
		var members = eu.members.duplicate()
		sq.setup(eu.type, 1, hex, members)
		sq.name = "E_" + str(i)
		mn.add_child(sq)
		sq.update_visual()
		GameManager.register_squad(sq)

	# Enemy HQ squad at (5, 1)
	var enemy_hq_member = ms.new("HQ", "command", 50, 60)
	enemy_hq_member.armor = 5
	var enemy_hq = ss.new()
	enemy_hq.setup("command", 1, Vector2i(5, 1), [enemy_hq_member])
	enemy_hq.name = "HQ_E"
	enemy_hq.squad_name = "敌方指挥部"
	enemy_hq.morale = 100
	enemy_hq.max_morale = 100
	mn.add_child(enemy_hq)
	enemy_hq.update_visual()
	GameManager.register_squad(enemy_hq)

	# Redraw terrain visuals
	mn.clear_highlights()
	for q in range(12):
		for r in range(10):
			var hex = Vector2i(q, r)
			if mn.tile_nodes.has(hex):
				var tid = mn.terrain_grid.get(hex, "plain")
				var td = GameManager.TERRAIN_DB.get(tid, GameManager.TERRAIN_DB["plain"])
				mn.tile_nodes[hex].color = td.color

	# Clear mission data
	GameManager.mission_placed_squads.clear()
	GameManager.initial_commanders.clear()

func _get_enemy_squads() -> Array:
	var loader = preload("res://scripts/core/unit_loader.gd").new()
	loader.ensure_loaded()
	return loader.get_enemy_units(GameManager.selected_nation)

func _setup_prologue_terrain(mn):
	for q in range(12):
		for r in range(10):
			mn.terrain_grid[Vector2i(q, r)] = "plain"

	# Row 0: all forest (map border)
	for q in range(12):
		mn.terrain_grid[Vector2i(q, 0)] = "forest"

	# Row 1: side forests + center plain for HQ
	mn.terrain_grid[Vector2i(0, 1)] = "forest"
	mn.terrain_grid[Vector2i(11, 1)] = "forest"

	# Row 3: forest clusters
	mn.terrain_grid[Vector2i(2, 3)] = "forest"
	mn.terrain_grid[Vector2i(3, 3)] = "forest"
	mn.terrain_grid[Vector2i(6, 3)] = "forest"
	mn.terrain_grid[Vector2i(7, 3)] = "forest"

	# Row 4: village (2 hexes)
	mn.terrain_grid[Vector2i(4, 4)] = "city"
	mn.terrain_grid[Vector2i(5, 4)] = "city"

	# Row 5: hills
	mn.terrain_grid[Vector2i(0, 5)] = "mountain"
	mn.terrain_grid[Vector2i(1, 5)] = "mountain"

	# Row 6: forest cluster
	mn.terrain_grid[Vector2i(3, 6)] = "forest"
	mn.terrain_grid[Vector2i(4, 6)] = "forest"
	mn.terrain_grid[Vector2i(5, 6)] = "forest"

	# Row 8: side forests
	mn.terrain_grid[Vector2i(0, 8)] = "forest"
	mn.terrain_grid[Vector2i(11, 8)] = "forest"

	# Row 9: all forest (map border)
	for q in range(12):
		mn.terrain_grid[Vector2i(q, 9)] = "forest"

func _check_win_condition():
	var ae = 0
	var ap = 0
	for sq in GameManager.enemy_squads:
		if is_instance_valid(sq) and sq.is_alive: ae += 1
	for sq in GameManager.player_squads:
		if is_instance_valid(sq) and sq.is_alive: ap += 1
	if ae == 0:
		var stats = {
			"kills": _count_enemy_killed(),
			"remaining": ap,
			"turns": GameManager.turn_count,
		}
		GameManager.enemy_squads.clear()
		GameManager.player_squads.clear()
		GameManager.all_squads.clear()
		_show_victory(true, stats)
	elif ap == 0:
		var stats = {"kills": _count_enemy_killed(), "remaining": 0, "turns": GameManager.turn_count}
		GameManager.enemy_squads.clear()
		GameManager.player_squads.clear()
		GameManager.all_squads.clear()
		_show_victory(false, stats)

func _count_enemy_killed() -> int:
	return 3  # Placeholder: prologue has 3 enemy squads max

func _show_victory(is_win: bool, stats: Dictionary):
	ui.show_message("")
	var victory_scene = preload("res://scenes/ui/victory.tscn").instantiate()
	add_child(victory_scene)
	victory_scene.open(is_win, stats)
