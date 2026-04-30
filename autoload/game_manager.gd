extends Node

static var TERRAIN_DB: Dictionary = {}
static var UNIT_DB: Dictionary = {}
static var UNIT_TYPE_DB: Dictionary = {}

func _init():
	if TERRAIN_DB.is_empty():
		TERRAIN_DB = preload("res://resources/terrain/terrain_data.gd").create_defaults()
	if UNIT_DB.is_empty():
		UNIT_DB = preload("res://resources/units/unit_data.gd").create_defaults()
	if UNIT_TYPE_DB.is_empty():
		UNIT_TYPE_DB = preload("res://scripts/core/unit_type_data.gd").create_defaults()

var current_level: int = 0
var current_phase: int = 0
var turn_count: int = 0
var command_points: int = 100
var command_points_per_turn: int = 50

var player_squads: Array = []
var enemy_squads: Array = []
var all_squads: Array = []

var hex_map: Node = null
var battle_manager: Node = null
var ui_manager: Node = null

# 储备库: weapon_name -> count
var reserve_storage: Dictionary = {}

# 指挥官池
var commander_pool: Array = []
var squad_commanders: Dictionary = {}  # squad -> commander

func add_commander_to_pool(cmd) -> void:
	commander_pool.append(cmd)

func remove_commander_from_pool(cmd) -> void:
	commander_pool.erase(cmd)

func assign_commander(squad, cmd) -> bool:
	if not cmd or not squad: return false
	if squad_commanders.has(squad): return false
	squad_commanders[squad] = cmd
	cmd.assigned_squad = squad
	commander_pool.erase(cmd)
	return true

func unassign_commander(squad) -> void:
	if not squad_commanders.has(squad): return
	var cmd = squad_commanders[squad]
	cmd.assigned_squad = null
	squad_commanders.erase(squad)
	commander_pool.append(cmd)

func get_commander(squad):
	return squad_commanders.get(squad, null)

func add_to_storage(weapon_name: String, count: int = 1) -> void:
	if not reserve_storage.has(weapon_name):
		reserve_storage[weapon_name] = 0
	reserve_storage[weapon_name] += count

func remove_from_storage(weapon_name: String, count: int = 1) -> bool:
	if not reserve_storage.has(weapon_name) or reserve_storage[weapon_name] < count:
		return false
	reserve_storage[weapon_name] -= count
	if reserve_storage[weapon_name] <= 0:
		reserve_storage.erase(weapon_name)
	return true

func get_storage_count(weapon_name: String) -> int:
	return reserve_storage.get(weapon_name, 0)

signal phase_changed(phase: int)
signal command_points_changed(points: int)
signal turn_ended(turn: int)

func _ready():
	process_mode = PROCESS_MODE_ALWAYS

func start_battle():
	current_phase = 0
	turn_count = 1
	command_points = 100
	emit_signal("phase_changed", current_phase)
	emit_signal("command_points_changed", command_points)

func end_player_turn():
	current_phase = 1
	emit_signal("phase_changed", current_phase)
	# ZOC内每回合+压制
	var mn = hex_map
	for sq in player_squads:
		if sq.is_alive and mn and mn.has_enemy_zoc(sq.hex_coord, sq.team):
			sq.apply_suppression(5)
	if battle_manager:
		battle_manager.start_enemy_turn()

func end_enemy_turn():
	current_phase = 0
	turn_count += 1
	command_points += command_points_per_turn
	emit_signal("phase_changed", current_phase)
	emit_signal("command_points_changed", command_points)
	emit_signal("turn_ended", turn_count)
	for sq in all_squads:
		sq.has_acted = false
		sq.reset_ap()
		# 回合恢复
		sq.apply_morale(5)
		sq.suppression = max(0, sq.suppression - 20)
		sq.update_visual()
	if battle_manager:
		battle_manager.start_player_turn()

func spend_command_points(amount: int) -> bool:
	if command_points >= amount:
		command_points -= amount
		emit_signal("command_points_changed", command_points)
		return true
	return false

func register_squad(squad) -> void:
	all_squads.append(squad)
	if squad.team == 0:
		player_squads.append(squad)
	else:
		enemy_squads.append(squad)

func unregister_squad(squad) -> void:
	all_squads.erase(squad)
	player_squads.erase(squad)
	enemy_squads.erase(squad)

func get_squad_at(hex: Vector2i):
	for sq in all_squads:
		if sq.hex_coord == hex and sq.is_alive:
			return sq
	return null
