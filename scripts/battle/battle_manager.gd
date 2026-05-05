extends Node

func _ready():
	GameManager.battle_manager = self

func start_player_turn():
	pass

func start_enemy_turn():
	_do_enemy_ai()

func _do_enemy_ai():
	var ai = get_node_or_null("../AI")
	if ai:
		ai.process_enemy_turn()
	else:
		GameManager.end_enemy_turn()

func resolve_combat(attacker, defender) -> Dictionary:
	var total_dmg = 0
	var total_counter = 0
	var num_hits = 0
	var num_counter_hits = 0
	var total_suppression = 0

	# 攻击方开火
	for atk_member in attacker.members:
		if not atk_member.is_alive: continue
		for w in atk_member.weapons:
			if w.get("ammo", 0) <= 0: continue
			var d = HexUtil.hex_distance(attacker.hex_coord, defender.hex_coord)
			if d < w.get("range_min", 1) or d > w.get("range_max", 3): continue

			w["ammo"] -= 1

			var hit = _calc_hit(atk_member, w, attacker, defender)
			if _roll(hit):
				num_hits += 1
				total_suppression += w.get("suppression", 5)
				var pen = _calc_pen(w)
				var def_armor = _get_armor(defender)
				if pen >= def_armor:
					var dmg = _calc_dmg(w, defender, attacker)
					total_dmg += dmg
					defender.take_damage(dmg)

	# 防御方士气影响
	defender.apply_morale(-5 * num_hits)
	defender.apply_suppression(total_suppression)

	# 反击（仅相邻+soft武器）
	for def_member in defender.members:
		if not def_member.is_alive: continue
		for w in def_member.weapons:
			if w.get("ammo", 0) <= 0: continue
			if HexUtil.hex_distance(defender.hex_coord, attacker.hex_coord) > 1: continue
			if w.get("damage_type", "") != "soft": continue

			w["ammo"] -= 1

			var hit = _calc_hit(def_member, w, defender, attacker)
			if _roll(hit):
				num_counter_hits += 1
				var pen = _calc_pen(w)
				var atk_armor = _get_armor(attacker)
				if pen >= atk_armor:
					var dmg = _calc_dmg(w, attacker, defender)
					total_counter += dmg

	attacker.has_acted = true
	attacker.spend_ap(2)
	attacker.update_visual()

	defender.update_visual()

	return {
		"damage_to_defender": total_dmg,
		"damage_to_attacker": total_counter,
		"num_hits": num_hits,
		"num_counter_hits": num_counter_hits,
		"defender_destroyed": not defender.is_alive,
		"attacker_destroyed": not attacker.is_alive,
	}

func resolve_zoc_attack(mover):
	var map_node = GameManager.hex_map
	if not map_node: return null
	var zoc_units = map_node.get_zoc_units_at(mover.hex_coord)
	if zoc_units.size() == 0: return null

	var best = null
	var best_dmg = 0
	for zu in zoc_units:
		if zu.team == mover.team or not zu.is_alive: continue
		if zu.has_acted: continue
		var t = 0
		for m in zu.members:
			if not m.is_alive: continue
			for w in m.weapons:
				t += w.get("damage_vs", {}).get("infantry", 5)
		if t > best_dmg:
			best_dmg = t
			best = zu

	if not best: return null

	var dmg = 0
	for m in best.members:
		if not m.is_alive: continue
		for w in m.weapons:
			if w.get("ammo", 0) <= 0: continue
			w["ammo"] -= 1
			var hit = _calc_hit(m, w, best, mover)
			if _roll(hit):
				var pen = _calc_pen(w)
				var mv_armor = _get_armor(mover)
				if pen >= mv_armor:
					var dd = _calc_dmg(w, mover, null)
					dmg += dd
					mover.take_damage(dd)
			break

	best.apply_morale(-3)
	mover.apply_morale(-3)
	best.update_visual()
	mover.update_visual()

	return {"attacker": best, "damage": dmg}

func _calc_hit(member, weapon, attacker, defender) -> int:
	var base = member.bs
	base += weapon.get("bs_bonus", 0)
	base += attacker.get_hit_modifier()
	for m in defender.members:
		if m.is_alive:
			base -= m.evasion * 2
			break
	var dist = HexUtil.hex_distance(attacker.hex_coord, defender.hex_coord)
	base -= max(0, (dist - weapon.get("range_max", 3) / 2) * 5)
	var mn = GameManager.hex_map
	if mn and mn.has_enemy_zoc(attacker.hex_coord, attacker.team):
		base -= 10
	if base < 10: return 10
	if base > 95: return 95
	return base

func _calc_pen(weapon) -> int:
	return weapon.get("armor_piercing", 3) + randi() % 5 - 2

func _get_armor(squad) -> int:
	var a = 0
	for m in squad.members:
		if m.is_alive and m.armor > a: a = m.armor
	return a

func _calc_dmg(weapon, defender, attacker) -> int:
	var target_type = "infantry"
	for m in defender.members:
		if m.is_alive: target_type = m.member_type; break
	var base = weapon.get("damage_vs", {}).get(target_type, 10)
	var var_pct = randi() % 40 - 20
	var damage = base * (100 + var_pct) / 100

	# 压制影响伤害
	if attacker and (typeof(attacker) == TYPE_OBJECT) and attacker.has_method("get_suppression_damage_bonus_range"):
		var penalty = attacker.get_suppression_damage_bonus_range()
		damage = damage * (100 + int(penalty)) / 100

	# 士气影响伤害
	if attacker and (typeof(attacker) == TYPE_OBJECT) and attacker.has_method("get_damage_modifier"):
		damage = int(damage * attacker.get_damage_modifier())

	# 地形掩护减伤 (defender所在格)
	var mn = GameManager.hex_map
	if mn:
		var td = mn.get_terrain_at(defender.hex_coord)
		if td and td.defense_bonus > 0:
			var cover_pct = td.defense_bonus * 10
			damage = damage * (100 - cover_pct) / 100

	if damage < 1: damage = 1
	return damage

func resolve_cqb(attacker, defender) -> Dictionary:
	var atk_dmg = 0
	var def_dmg = 0
	var atk_hits = 0
	var def_hits = 0

	# CQB武器修正
	var atk_mod = _cqb_weapon_mod(attacker)
	var def_mod = _cqb_weapon_mod(defender)

	# 攻击方
	for m in attacker.members:
		if not m.is_alive: continue
		for w in m.weapons:
			if w.get("ammo", 0) <= 0: continue
			if w.get("damage_type", "") == "": continue
			w["ammo"] -= 1
			var hit_chance = _calc_cqb_hit(m, w, attacker, def_mod)
			if _roll(hit_chance):
				atk_hits += 1
				var pen = _calc_pen(w)
				var arm = _get_armor(defender)
				if pen >= arm:
					var dmg = _calc_dmg(w, defender, attacker)
					atk_dmg += dmg
					defender.take_damage(dmg)

	# 防御方（同时反击）
	for m in defender.members:
		if not m.is_alive: continue
		for w in m.weapons:
			if w.get("ammo", 0) <= 0: continue
			if w.get("damage_type", "") == "": continue
			w["ammo"] -= 1
			var hit_chance = _calc_cqb_hit(m, w, defender, atk_mod)
			if _roll(hit_chance):
				def_hits += 1
				var pen = _calc_pen(w)
				var arm = _get_armor(attacker)
				if pen >= arm:
					var dmg = _calc_dmg(w, attacker, defender)
					def_dmg += dmg

	attacker.has_acted = true
	attacker.spend_ap(3)
	attacker.update_visual()
	defender.update_visual()

	return {
		"damage_to_defender": atk_dmg,
		"damage_to_attacker": def_dmg,
		"num_hits": atk_hits,
		"num_counter_hits": def_hits,
		"defender_destroyed": not defender.is_alive,
		"attacker_destroyed": not attacker.is_alive,
	}

func _cqb_weapon_mod(squad) -> int:
	var total_mod = 0
	var total = 0
	for m in squad.members:
		if not m.is_alive: continue
		for w in m.weapons:
			if w.get("ammo", 0) <= 0: continue
			total += 1
			var wn = w.get("name", "").to_lower()
			if "mp40" in wn or "冲锋" in wn or "smg" in wn or "手枪" in wn or "汤普森" in wn or "ppsh" in wn:
				total_mod += 15
			elif "卡宾" in wn or "g43" in wn or "m1" in wn or "stg44" in wn or "突击" in wn:
				total_mod += 5
			elif "mg42" in wn or "机枪" in wn or "mg" in wn or "步枪" in wn or "kar98k" in wn or "莫辛" in wn:
				total_mod += -10
			else:
				total_mod += -15
	if total == 0: return 0
	return total_mod / total

func _calc_cqb_hit(member, weapon, squad, cqb_mod) -> int:
	var base = member.bs
	base += weapon.get("bs_bonus", 0)
	base += cqb_mod
	base += squad.get_hit_modifier()
	if base < 10: return 10
	if base > 95: return 95
	return base

func _roll(chance: int) -> bool:
	return randi() % 100 < chance

# 战后缴获
func generate_loot(defeated_squad) -> Array:
	var loot = []
	for m in defeated_squad.members:
		if randi() % 100 < 40:  # 40%概率缴获
			for w in m.weapons:
				var wn = w.get("name", "")
				if wn and wn != "":
					loot.append(wn)
					break
	return loot
