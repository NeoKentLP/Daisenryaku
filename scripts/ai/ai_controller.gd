extends Node

const DELAY_BETWEEN_ACTIONS: float = 0.6

func process_enemy_turn():
	var enemies = GameManager.enemy_units
	var players = GameManager.player_units

	if enemies.is_empty() or players.is_empty():
		GameManager.end_enemy_turn()
		return

	var map_node = GameManager.hex_map
	if not map_node:
		GameManager.end_enemy_turn()
		return

	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.is_alive or enemy.has_acted:
			continue
		_process_enemy_unit(enemy, players, map_node)
		await get_tree().create_timer(DELAY_BETWEEN_ACTIONS).timeout

	GameManager.end_enemy_turn()

func _process_enemy_unit(enemy, players, map_node):
	var nearest = _find_nearest_enemy(enemy, players)
	if nearest == null:
		return

	var dist = HexUtil.hex_distance(enemy.hex_coord, nearest.hex_coord)

	if dist <= enemy.unit_data.attack_range:
		if enemy.can_attack(nearest):
			var battle = GameManager.battle_manager
			if battle:
				battle.resolve_combat(enemy, nearest)
		else:
			enemy.has_acted = true
		return

	var reachable = map_node.get_reachable_hexes(enemy.hex_coord, enemy.get_move_range())
	if reachable.is_empty():
		enemy.has_acted = true
		return

	var best_hex = enemy.hex_coord
	var best_dist = dist
	for hex in reachable:
		var d = HexUtil.hex_distance(hex, nearest.hex_coord)
		if d < best_dist:
			best_dist = d
			best_hex = hex

	if best_hex != enemy.hex_coord:
		enemy.move_to(best_hex)

	var new_dist = HexUtil.hex_distance(enemy.hex_coord, nearest.hex_coord)
	if new_dist <= enemy.unit_data.attack_range and enemy.can_attack(nearest):
		var battle = GameManager.battle_manager
		if battle:
			battle.resolve_combat(enemy, nearest)
	else:
		enemy.has_acted = true

func _find_nearest_enemy(unit, enemies):
	var nearest = null
	var best_dist = 9999
	for e in enemies:
		if not is_instance_valid(e) or not e.is_alive:
			continue
		var d = HexUtil.hex_distance(unit.hex_coord, e.hex_coord)
		if d < best_dist:
			best_dist = d
			nearest = e
	return nearest
