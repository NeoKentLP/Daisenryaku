extends Node

var current_action_unit = null
var is_processing: bool = false

func _ready():
	GameManager.battle_manager = self

func start_player_turn():
	is_processing = false
	current_action_unit = null

func start_enemy_turn():
	is_processing = true
	_do_enemy_ai()

func _do_enemy_ai():
	var ai = get_node_or_null("../AI")
	if ai:
		ai.process_enemy_turn()
	else:
		GameManager.end_enemy_turn()

func resolve_combat(attacker, defender) -> Dictionary:
	var atk_data = attacker.unit_data
	var def_data = defender.unit_data
	
	var def_map = GameManager.hex_map
	var def_terrain = def_map.get_terrain_at(defender.hex_coord) if def_map else null
	var def_bonus = def_terrain.defense_bonus if def_terrain else 0
	
	var base_damage = atk_data.attack
	var reduced_defense = max(0, def_data.defense - def_bonus)
	var damage = max(1, base_damage - reduced_defense)
	
	var counter_damage = 0
	if attacker.unit_data.attack_range <= 1 and def_data.attack_range >= 1:
		counter_damage = max(1, def_data.attack - atk_data.defense)
	
	var actual_damage = attacker.take_damage(counter_damage)
	var def_damage = defender.take_damage(damage)
	
	attacker.has_acted = true
	attacker.update_visual()

	return {
		"attacker": attacker,
		"defender": defender,
		"damage_to_defender": damage,
		"damage_to_attacker": counter_damage,
		"defender_hp_remaining": def_damage,
		"attacker_hp_remaining": actual_damage,
		"defender_destroyed": def_damage <= 0,
	}
