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

# ===== §4.4.1 完整命中公式 =====
func _calc_hit(member, weapon, attacker, defender, cqb_active: bool = false) -> int:
	var base = member.bs

	# 武器精度
	base += weapon.get("bs_bonus", 0)

	# 士气命中修正 (§7.1)
	base += attacker.get_hit_modifier()

	# CQB命中修正 (§4.6)
	if cqb_active:
		var cqb_r = weapon.get("cqb_rating", 0)
		if cqb_r >= 3: base += 15
		elif cqb_r == 2: base += 5
		elif cqb_r == 1: base -= 10
		else: return -999  # CQB不可用

	# 目标防御值 (§2.1 evasion/concealment)
	for m in defender.members:
		if m.is_alive:
			if m.member_type in ["vehicle", "air"]:
				base -= m.evasion
			else:
				base -= m.concealment
			break

	# 压制命中减损 (§8.4)
	if attacker.suppression > 50:
		base -= 5
	if attacker.suppression > 80:
		base -= 10

	# 距离减损 (§4.4.1)
	var dist = HexUtil.hex_distance(attacker.hex_coord, defender.hex_coord)
	var range_max = weapon.get("range_max", 1)
	var range_min = weapon.get("range_min", 0)
	if dist > range_max:
		return -999
	if dist < range_min:
		return -999
	# 射程等级: C(0)=0, M(1)=0, L(2)=-5, L(3)=-10, A(4)=-15, A(5)=-20
	if dist == 0: pass  # C
	elif dist == 1: pass  # M
	elif dist == 2: base -= 5
	elif dist == 3: base -= 10
	elif dist == 4: base -= 15
	else: base -= 20

	# ZOC惩罚 (§8.2)
	var mn = GameManager.hex_map
	if mn and mn.has_enemy_zoc(attacker.hex_coord, attacker.team):
		base -= 10

	return clampi(base, 5, 95)

# ===== §4.4.2 穿透判定 =====
func _check_penetration(weapon, defender) -> bool:
	var pen = weapon.get("penetration", weapon.get("armor_piercing", 0))
	var def_armor = _get_max_armor(defender)
	var diff = pen - def_armor
	var chance = 0
	if diff >= 3: chance = 100
	elif diff == 2: chance = 90
	elif diff == 1: chance = 70
	elif diff == 0: chance = 50
	elif diff == -1: chance = 20
	elif diff == -2: chance = 5
	else: chance = 0
	return _roll(chance)

# ===== §4.4.3 伤害计算 =====
func _calc_damage(weapon, defender, attacker) -> int:
	var base = weapon.get("base_damage", 15)

	# 伤害波动 (§8.4)
	var lower = -20 - max(0, attacker.suppression - 30) * 0.2
	var upper = 20 - max(0, attacker.suppression - 30) * 0.5
	var fluct = randi() % int(upper - lower) + lower
	var dmg = base * (100 + int(fluct)) / 100.0
	if dmg < 1: dmg = 1
	# cover减伤 (§3.2)
	var mn = GameManager.hex_map
	if mn:
		var td = mn.get_terrain_at(defender.hex_coord)
		if td:
			var cover_val = td.defense_bonus
			var cover_pct = min(cover_val * 5, 70)
			dmg = dmg * (100 - cover_pct) / 100.0

	# 士气伤害修正 (§7.1 狂热×1.1)
	if attacker.get_state() == attacker.STATE_FRENZIED:
		dmg = int(dmg * 1.1)

	if dmg < 1: dmg = 1
	return dmg

func _get_max_armor(squad) -> int:
	var a = 0
	for m in squad.members:
		if m.is_alive and m.armor > a: a = m.armor
	return a

# ===== 主动性判定 (§2.5) =====
func _initiative_first(attacker, defender) -> bool:
	var diff = attacker.initiative - defender.initiative
	var chance = clampi(50 + diff * 10, 10, 90)
	return _roll(chance)

# ===== 单发火力投送 (resolve_fire) =====
func _resolve_fire(firer, target, is_cqb: bool = false) -> Dictionary:
	var total_dmg = 0
	var total_hits = 0
	var total_sup = 0
	var weapon_hits = {}

	for m in firer.members:
		if not m.is_alive: continue
		for w in m.weapons:
			if w.get("ammo", 0) <= 0: continue

			# CQB过滤: 仅 infantry + cqb_rating≥1
			if is_cqb:
				if m.member_type != "infantry": continue
				if w.get("cqb_rating", 0) < 1: continue

			# 射程检查
			var d = HexUtil.hex_distance(firer.hex_coord, target.hex_coord)
			if d < w.get("range_min", 0) or d > w.get("range_max", 1): continue

			w["ammo"] -= 1
			var wn = w.get("name", "?")
			if not weapon_hits.has(wn):
				weapon_hits[wn] = {"shots": 0, "hits": 0, "kills": 0, "suppression": 0}

			weapon_hits[wn].shots += 1

			# 命中判定
			var hit_chance = _calc_hit(m, w, firer, target, is_cqb)
			if hit_chance <= 0: continue
			if not _roll(hit_chance): continue

			total_hits += 1
			weapon_hits[wn].hits += 1

			# 目标成员分配 (随机存活成员, 等概率)
			var alive = []
			for tm in target.members:
				if tm.is_alive: alive.append(tm)
			if alive.is_empty(): break
			var t_member = alive[randi() % alive.size()]

			# 穿透判定
			var pen = w.get("penetration", w.get("armor_piercing", 0))
			var def_armor = t_member.armor
			var diff = pen - def_armor

			var penetrated = _roll(_pen_chance(diff))
			var dmg = 0
			if penetrated:
				dmg = _calc_damage(w, target, firer)
				t_member.take_damage(dmg)
				total_dmg += dmg
				if not t_member.is_alive:
					weapon_hits[wn].kills += 1
					firer.apply_morale(2)
			else:
				dmg = 1
				t_member.take_damage(1)

			var sup_val = w.get("suppression", 5)
			weapon_hits[wn].suppression += sup_val
			total_sup += sup_val

			# 目标部队全灭检查
			if target.get_alive_count() <= 0:
				target.is_alive = false
				break

	return {
		"damage": total_dmg,
		"hits": total_hits,
		"suppression": total_sup,
		"weapon_hits": weapon_hits,
	}

func _pen_chance(diff: int) -> int:
	if diff >= 3: return 100
	if diff == 2: return 90
	if diff == 1: return 70
	if diff == 0: return 50
	if diff == -1: return 20
	if diff == -2: return 5
	return 0

# ===== §4 常规攻击 =====
func resolve_combat(attacker, defender) -> Dictionary:
	var def_alive_before = defender.get_alive_count()
	var def_hp_before = defender.get_total_hp()
	var total_dmg_to_def = 0
	var total_dmg_to_atk = 0
	var num_counter = 0
	var all_weapon_hits = {}

	# §2.5 先手判定
	var attacker_first = _initiative_first(attacker, defender)

	# 第一轮: first射击second
	if attacker_first:
		var r1 = _resolve_fire(attacker, defender, false)
		total_dmg_to_def += r1.damage
		_merge_weapon_hits(all_weapon_hits, r1.weapon_hits)

		# 第二轮: 反击 (存活 + 距离≤1 + 士气正常 + 有反应)
		if defender.get_alive_count() > 0 and HexUtil.hex_distance(attacker.hex_coord, defender.hex_coord) <= 1:
			if defender.get_state() >= defender.STATE_NORMAL and defender.reactions > 0:
				var r2 = _resolve_fire(defender, attacker, false)
				total_dmg_to_atk += r2.damage
				num_counter += r2.hits
				_merge_weapon_hits(all_weapon_hits, r2.weapon_hits)
				defender.reactions -= 1
	else:
		var r1 = _resolve_fire(defender, attacker, false)
		total_dmg_to_atk += r1.damage
		_merge_weapon_hits(all_weapon_hits, r1.weapon_hits)

		if attacker.get_alive_count() > 0 and HexUtil.hex_distance(attacker.hex_coord, defender.hex_coord) <= 1:
			if attacker.get_state() >= attacker.STATE_NORMAL and attacker.reactions > 0:
				var r2 = _resolve_fire(attacker, defender, false)
				total_dmg_to_def += r2.damage
				num_counter += r2.hits
				_merge_weapon_hits(all_weapon_hits, r2.weapon_hits)
				attacker.reactions -= 1

	# 压制累积
	attacker.apply_suppression(total_dmg_to_atk)
	defender.apply_suppression(total_dmg_to_def)

	# 士气影响: 被命中次数
	attacker.apply_morale(-5 * num_counter)
	defender.apply_morale(-5 * total_dmg_to_def)

	attacker.has_acted = true
	attacker.spend_ap(2)
	attacker.update_visual()
	defender.update_visual()

	return {
		"damage_to_defender": total_dmg_to_def,
		"damage_to_attacker": total_dmg_to_atk,
		"num_hits": total_dmg_to_def,
		"num_counter_hits": num_counter,
		"defender_destroyed": not defender.is_alive,
		"attacker_destroyed": not attacker.is_alive,
		"weapon_hits": all_weapon_hits,
		"defender_hp_before": def_hp_before,
		"defender_hp_after": defender.get_total_hp(),
		"defender_alive_count_before": def_alive_before,
		"defender_alive_count_after": defender.get_alive_count(),
	}

func _merge_weapon_hits(dest, src):
	for wn in src:
		if not dest.has(wn):
			dest[wn] = {"shots": 0, "hits": 0, "kills": 0, "suppression": 0}
		dest[wn].shots += src[wn].shots
		dest[wn].hits += src[wn].hits
		dest[wn].kills += src[wn].kills
		dest[wn].suppression += src[wn].suppression

# ===== CQB突击 (§5) =====
func resolve_cqb(attacker, defender) -> Dictionary:
	# 双方同时开火
	var atk_result = _resolve_fire(attacker, defender, true)
	var def_result = _resolve_fire(defender, attacker, true)

	attacker.has_acted = true
	attacker.spend_ap(3)
	attacker.update_visual()
	defender.update_visual()

	return {
		"damage_to_defender": atk_result.damage,
		"damage_to_attacker": def_result.damage,
		"num_hits": atk_result.hits,
		"num_counter_hits": def_result.hits,
		"defender_destroyed": not defender.is_alive,
		"attacker_destroyed": not attacker.is_alive,
	}

# ===== ZOC借机攻击 (§6.3) =====
func resolve_zoc_attack(mover):
	var map_node = GameManager.hex_map
	if not map_node: return null
	var zoc_units = map_node.get_zoc_units_at(mover.hex_coord)
	if zoc_units.size() == 0: return null

	var best = null
	var best_dmg = 0
	for zu in zoc_units:
		if zu.team == mover.team or not zu.is_alive: continue
		if zu.has_acted or zu.reactions <= 0: continue
		if zu.get_state() < zu.STATE_NORMAL: continue
		# 简单伤害估算
		var t = 0
		for m in zu.members:
			if not m.is_alive: continue
			for w in m.weapons:
				t += w.get("base_damage", w.get("damage_vs", {}).get("infantry", 5))
		if t > best_dmg:
			best_dmg = t
			best = zu

	if not best: return null

	var result = _resolve_fire(best, mover, false)
	best.reactions -= 1

	best.apply_morale(-3)
	mover.apply_morale(-3)
	best.update_visual()
	mover.update_visual()

	return {"attacker": best, "damage": result.damage}

func _roll(chance: int) -> bool:
	return randi() % 100 < chance

# 战后缴获
func generate_loot(defeated_squad) -> Array:
	var loot = []
	for m in defeated_squad.members:
		if randi() % 100 < 40:
			for w in m.weapons:
				var wn = w.get("name", "")
				if wn and wn != "":
					loot.append(wn)
					break
	return loot
