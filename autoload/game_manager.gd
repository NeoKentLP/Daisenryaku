extends Node

static var TERRAIN_DB: Dictionary = {}
static var UNIT_DB: Dictionary = {}

func _init():
	if TERRAIN_DB.is_empty():
		TERRAIN_DB = preload("res://resources/terrain/terrain_data.gd").create_defaults()
	if UNIT_DB.is_empty():
		UNIT_DB = preload("res://resources/units/unit_data.gd").create_defaults()

var current_level: int = 0
var current_phase: int = 0  # Phase enum
var turn_count: int = 0
var command_points: int = 100
var command_points_per_turn: int = 50

var player_units: Array = []
var enemy_units: Array = []
var all_units: Array = []

var hex_map: Node = null
var battle_manager: Node = null
var ui_manager: Node = null

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
	if battle_manager:
		battle_manager.start_enemy_turn()

func end_enemy_turn():
	current_phase = 0
	turn_count += 1
	command_points += command_points_per_turn
	emit_signal("phase_changed", current_phase)
	emit_signal("command_points_changed", command_points)
	emit_signal("turn_ended", turn_count)
	for unit in all_units:
		unit.has_acted = false
		unit.update_visual()
	if battle_manager:
		battle_manager.start_player_turn()

func spend_command_points(amount: int) -> bool:
	if command_points >= amount:
		command_points -= amount
		emit_signal("command_points_changed", command_points)
		return true
	return false

func register_unit(unit) -> void:
	all_units.append(unit)
	if unit.team == 0:
		player_units.append(unit)
	else:
		enemy_units.append(unit)

func unregister_unit(unit) -> void:
	all_units.erase(unit)
	player_units.erase(unit)
	enemy_units.erase(unit)

func get_unit_at(hex: Vector2i) -> Node:
	for unit in all_units:
		if unit.hex_coord == hex and unit.hp > 0:
			return unit
	return null
