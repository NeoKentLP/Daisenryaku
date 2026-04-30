extends Node

const DELAY = 0.6

func process_enemy_turn():
	var enemies = GameManager.enemy_squads
	var players = GameManager.player_squads
	if enemies.is_empty() or players.is_empty(): GameManager.end_enemy_turn(); return
	var mn = GameManager.hex_map
	if not mn: GameManager.end_enemy_turn(); return

	for sq in enemies:
		if not is_instance_valid(sq) or not sq.is_alive or sq.has_acted: continue
		if sq.get_state() == 0: # 溃败不动
			sq.has_acted = true; continue
		_process_ai(sq, players, mn)
		await get_tree().create_timer(DELAY).timeout
	# ZOC检查: 敌方在ZOC内+压制
	for sq in enemies:
		if sq.is_alive and mn.has_enemy_zoc(sq.hex_coord, sq.team):
			sq.apply_suppression(5)
	GameManager.end_enemy_turn()

func _process_ai(sq, players, mn):
	var nearest = _nearest(sq, players)
	if nearest == null: return
	var dist = HexUtil.hex_distance(sq.hex_coord, nearest.hex_coord)
	if dist <= 1:
		if sq.can_attack(nearest):
			var b = GameManager.battle_manager
			if b:
				var r = b.resolve_combat(sq, nearest)
				var msg = "[AI] " + sq.squad_name + " 攻击 " + nearest.squad_name
				msg += " 命中" + str(r.num_hits) + "次 伤" + str(r.damage_to_defender)
				if r.damage_to_attacker > 0: msg += " (反伤" + str(r.damage_to_attacker) + ")"
				if r.defender_destroyed: msg += " 消灭!"
				var ui = GameManager.ui_manager
				if ui: ui.add_log(msg)
		else: sq.has_acted = true
		return

	# 检查是否能直接进入目标格（避开ZOC）
	var reachable = []
	for h in mn.get_reachable_hexes(sq.hex_coord, sq.get_move_range()):
		if not mn.has_enemy_zoc(h, sq.team) or h == nearest.hex_coord:
			reachable.append(h)

	if reachable.is_empty():
		sq.has_acted = true
		return

	var best = sq.hex_coord
	var best_d = dist
	for h in reachable:
		var d = HexUtil.hex_distance(h, nearest.hex_coord)
		if d < best_d: best_d = d; best = h

	if best != sq.hex_coord:
		var move_dist = HexUtil.hex_distance(sq.hex_coord, best)
		sq.move_to(best)
		sq.spend_ap(move_dist)
		# 如果进入ZOC，触发借机攻击(玩家触发, AI同样处理)
		if mn.has_enemy_zoc(sq.hex_coord, sq.team):
			var b = GameManager.battle_manager
			if b: b.resolve_zoc_attack(sq)

	var nd = HexUtil.hex_distance(sq.hex_coord, nearest.hex_coord)
	if nd <= 1 and sq.can_attack(nearest):
		var b = GameManager.battle_manager
		if b:
			var r = b.resolve_combat(sq, nearest)
			var msg = "[AI] " + sq.squad_name + " 攻击 " + nearest.squad_name
			msg += " 命中" + str(r.num_hits) + "次 伤" + str(r.damage_to_defender)
			if r.damage_to_attacker > 0: msg += " (反伤" + str(r.damage_to_attacker) + ")"
			if r.defender_destroyed: msg += " 消灭!"
			var ui = GameManager.ui_manager
			if ui: ui.add_log(msg)
	else: sq.has_acted = true

func _nearest(sq, targets):
	var n = null; var b = 9999
	for t in targets:
		if not is_instance_valid(t) or not t.is_alive: continue
		var d = HexUtil.hex_distance(sq.hex_coord, t.hex_coord)
		if d < b: b = d; n = t
	return n
