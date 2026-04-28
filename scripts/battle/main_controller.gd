extends Node2D

var map
var battle
var ai
var ui

var selected_unit = null
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
	_spawn_test_units()
	GameManager.start_battle()

func _process(delta):
	if not _cam:
		return
	var dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir.x += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		dir.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		dir.y += 1
	if dir != Vector2.ZERO:
		_cam.position += dir.normalized() * CAM_SPEED * delta

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not _is_dragging:
			_on_map_clicked()
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if selected_unit:
				_deselect_unit()
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_drag_start = get_global_mouse_position()
				_is_dragging = true
			else:
				_is_dragging = false
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_cam.zoom = Vector2(
				min(CAM_ZOOM_MAX, _cam.zoom.x + 0.2),
				min(CAM_ZOOM_MAX, _cam.zoom.y + 0.2)
			)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_cam.zoom = Vector2(
				max(CAM_ZOOM_MIN, _cam.zoom.x - 0.2),
				max(CAM_ZOOM_MIN, _cam.zoom.y - 0.2)
			)

	if event is InputEventMouseMotion and _is_dragging:
		var mouse_pos = get_global_mouse_position()
		var delta = mouse_pos - _drag_start
		_cam.position -= delta
		_drag_start = mouse_pos

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if selected_unit:
			_deselect_unit()

func _on_map_clicked():
	if GameManager.current_phase != 0:
		return

	var map_node = GameManager.hex_map
	if not map_node:
		return

	var world_pos = get_global_mouse_position()
	var hex = map_node.pixel_to_hex(world_pos)

	if not map_node.terrain_grid.has(hex):
		return

	var clicked_unit = GameManager.get_unit_at(hex)

	# 攻击优先：不管 action_mode 是什么，点击红色目标=攻击
	if valid_attack_hexes.has(hex):
		_execute_attack(hex)
		return

	if action_mode == "move" and valid_hexes.has(hex) and not valid_attack_hexes.has(hex):
		_execute_move(hex)
		return

	if clicked_unit and clicked_unit.team == 0 and not clicked_unit.has_acted and clicked_unit.is_alive:
		if selected_unit != clicked_unit:
			_select_unit(clicked_unit)
	elif selected_unit:
		_deselect_unit()

func _select_unit(unit):
	_deselect_unit()
	selected_unit = unit
	ui.show_unit_info(unit)

	var map_node = GameManager.hex_map
	if not map_node:
		return

	var move_hexes = map_node.get_reachable_hexes(unit.hex_coord, unit.get_move_range())
	valid_attack_hexes = _find_attackable_hexes(unit)

	if move_hexes.size() > 0:
		action_mode = "move"
		valid_hexes = move_hexes
		map_node.highlight_hexes(move_hexes, Color(0.3, 0.8, 0.3, 0.4))
	elif valid_attack_hexes.size() > 0:
		action_mode = "attack"
		valid_hexes = valid_attack_hexes
	else:
		action_mode = ""

	if valid_attack_hexes.size() > 0:
		for hex in valid_attack_hexes:
			map_node.add_highlight(hex, Color(0.9, 0.2, 0.2, 0.4))

	ui.show_action_menu()
	ui.show_message("选择格子移动、攻击或点击待机")

func _find_attackable_hexes(unit):
	var map_node = GameManager.hex_map
	if not map_node:
		return []
	var hexes = []
	for h in map_node.get_attackable_hexes(unit.hex_coord, unit.unit_data.attack_range):
		var target = GameManager.get_unit_at(h)
		if target and target.team != unit.team and target.is_alive:
			hexes.append(h)
	return hexes

func _deselect_unit():
	selected_unit = null
	action_mode = ""
	valid_hexes.clear()
	valid_attack_hexes.clear()
	var map_node = GameManager.hex_map
	if map_node:
		map_node.clear_highlights()
	ui.show_unit_info(null)
	ui.hide_action_menu()

func _execute_move(hex):
	var map_node = GameManager.hex_map
	if not map_node or not selected_unit:
		return

	map_node.clear_highlights()
	selected_unit.move_to(hex)
	_show_attack_options(selected_unit)

func _show_attack_options(unit):
	var map_node = GameManager.hex_map
	if not map_node:
		return

	var attack_hexes = _find_attackable_hexes(unit)

	if attack_hexes.size() > 0:
		action_mode = "attack"
		valid_hexes = attack_hexes
		valid_attack_hexes = attack_hexes
		map_node.highlight_hexes(attack_hexes, Color(0.9, 0.2, 0.2, 0.4))
		ui.show_message("选择攻击目标或点击待机")
		ui.show_action_menu()
	else:
		_end_unit_action()

func _end_unit_action():
	if not selected_unit:
		return
	var map_node = GameManager.hex_map
	if map_node:
		map_node.clear_highlights()
	selected_unit.has_acted = true
	selected_unit.update_visual()
	_deselect_unit()
	_check_all_acted()

func _execute_attack(hex):
	var map_node = GameManager.hex_map
	if not map_node or not selected_unit:
		return

	map_node.clear_highlights()
	var target = GameManager.get_unit_at(hex)
	if target and target.is_alive and target.team != selected_unit.team:
		var result = battle.resolve_combat(selected_unit, target)
		var msg = "攻击! %s -> %s 伤害: %d" % [selected_unit.unit_data.display_name, target.unit_data.display_name, result.damage_to_defender]
		if result.damage_to_attacker > 0:
			msg += " (反击伤害: %d)" % result.damage_to_attacker
		if result.defender_destroyed:
			msg += " 目标被摧毁!"
		ui.show_message(msg)

	_deselect_unit()
	_check_win_condition()
	_check_all_acted()

func _on_unit_wait():
	if selected_unit:
		_end_unit_action()

func _check_all_acted():
	if GameManager.current_phase != 0:
		return
	var all_done = true
	for unit in GameManager.player_units:
		if unit.is_alive and not unit.has_acted:
			all_done = false
			break
	if all_done:
		ui.show_message("全部单位行动完毕")
		await get_tree().create_timer(1.0).timeout
		GameManager.end_player_turn()

func _spawn_test_units():
	var map_node = GameManager.hex_map
	if not map_node:
		return

	var player_data = [
		{"id": "tank", "hex": Vector2i(1, 1)},
		{"id": "infantry", "hex": Vector2i(0, 1)},
		{"id": "infantry", "hex": Vector2i(1, 0)},
		{"id": "artillery", "hex": Vector2i(0, 2)},
		{"id": "recon", "hex": Vector2i(2, 1)},
	]

	var enemy_data = [
		{"id": "tank", "hex": Vector2i(13, 8)},
		{"id": "infantry", "hex": Vector2i(14, 8)},
		{"id": "infantry", "hex": Vector2i(13, 7)},
		{"id": "mechanized", "hex": Vector2i(12, 8)},
	]

	var unit_script = load("res://scripts/units/unit.gd")
	for d in player_data:
		var u = unit_script.new()
		u.unit_data_id = d.id
		u.team = 0
		u.hex_coord = d.hex
		u.name = "PlayerUnit_%s_%d_%d" % [d.id, d.hex.x, d.hex.y]
		map_node.add_child(u)
		GameManager.register_unit(u)

	for d in enemy_data:
		var u = unit_script.new()
		u.unit_data_id = d.id
		u.team = 1
		u.hex_coord = d.hex
		u.name = "EnemyUnit_%s_%d_%d" % [d.id, d.hex.x, d.hex.y]
		map_node.add_child(u)
		GameManager.register_unit(u)

func _check_win_condition():
	var alive_enemies = 0
	for u in GameManager.enemy_units:
		if is_instance_valid(u) and u.is_alive:
			alive_enemies += 1
	if alive_enemies == 0:
		ui.show_victory("胜利! 所有敌人被消灭!")
