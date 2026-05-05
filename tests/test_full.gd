extends Node

# ============================================================
# 全量测试
# ============================================================

var _passed := 0
var _failed := 0
var _tests_run := 0
var _test_log := []

func _ready():
	print("=".repeat(60))
	print("  全量测试")
	print("=".repeat(60))
	print("")
	run_all_tests()
	_print_summary()
	get_tree().quit(_failed)

func run_all_tests():
	test_hex_util_basic()
	test_hex_util_distance()
	test_hex_util_neighbors()
	test_hex_util_range()
	test_hex_util_pixel_roundtrip()
	test_hex_util_astar()
	test_member_basic()
	test_member_damage()
	test_member_death()
	test_squad_basic()
	test_squad_members()
	test_squad_damage()
	test_squad_move()
	test_squad_get_hp()
	test_squad_has_acted()
	test_squad_ap_basic()
	test_squad_ap_spend()
	test_squad_ap_reset()
	test_squad_move_with_ap()
	test_squad_move_not_enough_ap()
	test_battle_with_weapons()
	test_battle_tank_vs_infantry()
	test_cqb_terrain_check()
	test_cqb_weapon_mod()
	test_squad_state_normal()
	test_squad_state_confused()
	test_squad_state_broken()
	test_squad_morale_change()
	test_squad_suppression()
	test_squad_zoc_check()
	test_unit_type_data()
	test_unit_type_cost()
	test_game_manager_basic()
	test_game_manager_squad()
	test_game_manager_multi_squad()
	test_game_manager_turn_cycle()
	test_terrain_data()
	test_hex_map_reachable()
	test_hex_map_attackable()
	test_squad_move_range()
	test_tier_boundary_no_empty_lines()
	test_tier_boundary_same_tier_no_line()
	test_tier_boundary_adjacent_tiers()
	test_squad_ap_deduct_move()
	test_squad_move_then_attack_ap()

func assert_eq(got, expected, desc: String = ""):
	_tests_run += 1
	if got == expected:
		_passed += 1
		if desc: _test_log.append("[PASS] " + desc)
	else:
		_failed += 1
		var msg = "[FAIL] " + desc + ": 期望 " + str(expected) + ", 实际 " + str(got)
		_test_log.append(msg)
		push_error(msg)

func assert_true(cond, desc: String = ""):
	assert_eq(cond, true, desc)

func assert_false(cond, desc: String = ""):
	assert_eq(cond, false, desc)

func _M(name, type, hp):
	return preload("res://scripts/core/member.gd").new(name, type, hp)

func _S(type_id, team, hex, members):
	var sq = load("res://scripts/core/squad.gd").new()
	sq.setup(type_id, team, hex, members)
	return sq

# ========== HexUtil ==========

func test_hex_util_basic():
	print("  HexUtil 基础数学")
	var p = HexUtil.axial_to_pixel(0, 0, 32)
	assert_eq(p, Vector2(0, 0), "Hex(0,0)")
	p = HexUtil.axial_to_pixel(1, 0, 32)
	assert_eq(int(p.x), 55, "Hex(1,0) X=55")

func test_hex_util_distance():
	print("  HexUtil 距离计算")
	assert_eq(HexUtil.hex_distance(Vector2i(0,0), Vector2i(0,0)), 0, "同点")
	assert_eq(HexUtil.hex_distance(Vector2i(0,0), Vector2i(1,0)), 1, "邻格")
	assert_eq(HexUtil.hex_distance(Vector2i(0,0), Vector2i(5,0)), 5, "直线5")
	assert_eq(HexUtil.hex_distance(Vector2i(0,0), Vector2i(3,3)), 6, "对角线")

func test_hex_util_neighbors():
	print("  HexUtil 邻居")
	var nbs = HexUtil.hex_neighbors(Vector2i(0, 0))
	assert_eq(nbs.size(), 6, "6个邻居")
	assert_true(nbs.has(Vector2i(1,0)), "含(1,0)")

func test_hex_util_range():
	print("  HexUtil 范围")
	var r1 = HexUtil.hexes_in_range(Vector2i(0, 0), 1)
	assert_eq(r1.size(), 7, "range=1 => 7")
	var r3 = HexUtil.hexes_in_range(Vector2i(0, 0), 0)
	assert_eq(r3.size(), 1, "range=0 => 1")

func test_hex_util_pixel_roundtrip():
	print("  HexUtil 像素往返")
	for c in [Vector2i(3,5), Vector2i(-2,4), Vector2i(0,0)]:
		var px = HexUtil.axial_to_pixel(c.x, c.y, 32)
		var back = HexUtil.pixel_to_axial(px.x, px.y, 32)
		assert_eq(back, c, "往返一致")

func test_hex_util_astar():
	print("  HexUtil A*寻路")
	var passable = func(h): return h.x >= 0 and h.x < 5 and h.y >= 0 and h.y < 5
	var cost = func(h): return 1
	var path = HexUtil.astar_path(Vector2i(0,0), Vector2i(2,0), passable, cost)
	assert_true(path.size() > 0, "可达")
	assert_eq(path[0], Vector2i(0,0), "起点")
	assert_eq(path[path.size()-1], Vector2i(2,0), "终点")
	var blocked = func(h): return h == Vector2i(1,0) or h == Vector2i(0,1) or h == Vector2i(1,1)
	var path2 = HexUtil.astar_path(Vector2i(0,0), Vector2i(2,0), blocked, cost)
	assert_eq(path2.size(), 0, "阻挡不可达")

# ========== Member ==========

func test_member_basic():
	print("  Member 基础")
	var m = _M("班长", "infantry", 12)
	assert_eq(m.member_name, "班长")
	assert_eq(m.member_type, "infantry")
	assert_eq(m.max_hp, 12)
	assert_eq(m.hp, 12)
	assert_true(m.is_alive)

func test_member_damage():
	print("  Member 受伤")
	var m = _M("兵", "infantry", 10)
	m.take_damage(3)
	assert_eq(m.hp, 7)
	m.take_damage(7)
	assert_eq(m.hp, 0)
	assert_false(m.is_alive)

func test_member_death():
	print("  Member 死亡")
	var m = _M("兵", "infantry", 10)
	m.take_damage(10)
	assert_eq(m.hp, 0)
	assert_false(m.is_alive)

# ========== Squad ==========

func test_squad_basic():
	print("  Squad 基础")
	var sq = _S("infantry", 0, Vector2i(1, 2), [
		_M("A", "infantry", 10), _M("B", "infantry", 10), _M("C", "infantry", 10)
	])
	assert_eq(sq.team, 0)
	assert_eq(sq.hex_coord, Vector2i(1, 2))
	assert_eq(sq.get_total_count(), 3)
	assert_eq(sq.get_alive_count(), 3)
	assert_eq(sq.get_total_hp(), 30)
	assert_eq(sq.get_max_hp(), 30)
	assert_false(sq.has_acted)
	assert_true(sq.is_alive)

func test_squad_members():
	print("  Squad 成员")
	var members = [_M("A", "infantry", 10), _M("B", "infantry", 10)]
	var sq = _S("infantry", 0, Vector2i(0, 0), members)
	assert_eq(sq.members.size(), 2)
	assert_eq(sq.members[0].member_name, "A")

func test_squad_damage():
	print("  Squad 受伤")
	var members = [_M("A", "infantry", 10), _M("B", "infantry", 10)]
	var sq = _S("infantry", 0, Vector2i(0, 0), members)
	sq.take_damage(4)
	assert_eq(sq.get_alive_count(), 2)
	assert_true(sq.is_alive)
	sq.take_damage(20)
	assert_eq(sq.get_alive_count(), 1)
	assert_true(sq.is_alive)

func test_squad_move():
	print("  Squad 移动")
	var sq = _S("infantry", 0, Vector2i(0, 0), [_M("A", "infantry", 10)])
	sq.move_to(Vector2i(3, 4))
	assert_eq(sq.hex_coord, Vector2i(3, 4))

func test_squad_get_hp():
	print("  Squad HP")
	var sq = _S("infantry", 0, Vector2i(0, 0), [
		_M("A", "infantry", 10), _M("B", "infantry", 8)
	])
	assert_eq(sq.get_total_hp(), 18)
	assert_eq(sq.get_max_hp(), 18)

func test_squad_has_acted():
	print("  Squad 已行动")
	var sq = _S("infantry", 0, Vector2i(0, 0), [_M("A", "infantry", 10)])
	assert_eq(sq.get_move_range(), 2, "未行动可移动2格")
	sq.has_acted = true
	assert_eq(sq.get_move_range(), 0, "已行动不可移动")

func test_squad_ap_basic():
	print("  Squad AP基础")
	var sq = _S("infantry", 0, Vector2i(0, 0), [_M("A", "infantry", 10)])
	assert_eq(sq.ap, 3, "初始AP=3")
	assert_eq(sq.max_ap, 3, "最大AP=3")
	assert_true(sq.can_afford(2), "够攻击")
	assert_true(sq.can_afford(3), "够移动3格")
	assert_false(sq.can_afford(4), "不够4AP")

func test_squad_ap_spend():
	print("  Squad AP消耗")
	var sq = _S("infantry", 0, Vector2i(0, 0), [_M("A", "infantry", 10)])
	sq.spend_ap(2)
	assert_eq(sq.ap, 1, "攻击后剩1AP")
	sq.spend_ap(1)
	assert_eq(sq.ap, 0, "再花1AP=0")
	assert_false(sq.can_afford(1), "0AP不能行动")

func test_squad_ap_reset():
	print("  Squad AP重置")
	var sq = _S("infantry", 0, Vector2i(0, 0), [_M("A", "infantry", 10)])
	sq.spend_ap(2)
	assert_eq(sq.ap, 1, "花2AP剩1")
	sq.reset_ap()
	assert_eq(sq.ap, 3, "重置后满AP")

func test_squad_move_with_ap():
	print("  Squad 移动+AP")
	var sq = _S("infantry", 0, Vector2i(0, 0), [_M("A", "infantry", 10)])
	var dist = HexUtil.hex_distance(Vector2i(0,0), Vector2i(2,0))
	assert_eq(dist, 2, "到(2,0)需2AP")
	assert_true(sq.can_afford(dist), "有足够AP移动")
	sq.move_to(Vector2i(2,0))
	sq.spend_ap(dist)
	assert_eq(sq.hex_coord, Vector2i(2,0), "移动到(2,0)")
	assert_eq(sq.ap, 1, "花2AP剩1")

func test_squad_move_not_enough_ap():
	print("  Squad AP不足不能移动")
	var sq = _S("infantry", 0, Vector2i(0, 0), [_M("A", "infantry", 10)])
	sq.spend_ap(2)
	assert_eq(sq.ap, 1, "仅剩1AP")
	var dist = HexUtil.hex_distance(Vector2i(0,0), Vector2i(2,0))
	assert_eq(dist, 2, "到(2,0)需2AP")
	assert_false(sq.can_afford(dist), "AP不足不能移动")

func test_battle_with_weapons():
	print("  Squad 战斗(带武器)")
	var wd = preload("res://scripts/core/weapon_data.gd")
	var member_atk = preload("res://scripts/core/member.gd").new("步兵", "infantry", 10, 60, wd.rifle())
	var member_def = preload("res://scripts/core/member.gd").new("步兵", "infantry", 10, 60, wd.rifle())
	var atk = _S("infantry", 0, Vector2i(0,0), [member_atk])
	var def = _S("infantry", 1, Vector2i(1,0), [member_def])
	
	var bm = load("res://scripts/battle/battle_manager.gd").new()
	var result = bm.resolve_combat(atk, def)
	
	assert_true(result.damage_to_defender >= 0, "造成伤害≥0")
	assert_true(atk.has_acted, "攻击后标记已行动")
	assert_true(atk.ap < 3, "攻击消耗AP")

func test_battle_tank_vs_infantry():
	print("  Squad 坦克vs步兵")
	var wd = preload("res://scripts/core/weapon_data.gd")
	var tank_member = preload("res://scripts/core/member.gd").new("车长", "vehicle", 15, 50, wd.tank_gun())
	tank_member.armor = 10
	var inf_member = preload("res://scripts/core/member.gd").new("步兵", "infantry", 10, 60, wd.rifle())
	
	var tank = _S("tank", 0, Vector2i(0,0), [tank_member])
	var inf = _S("infantry", 1, Vector2i(1,0), [inf_member])
	
	var bm = load("res://scripts/battle/battle_manager.gd").new()
	var result = bm.resolve_combat(tank, inf)
	
	assert_true(result.has("damage_to_defender"), "战斗返回有效结果")

func test_cqb_terrain_check():
	print("  CQB 地形检测")
	# 验证CQB相关地形的数据存在
	var db = GameManager.TERRAIN_DB
	assert_true(db.has("city"), "城市存在")
	assert_true(db.has("forest"), "森林存在")
	assert_true(db.has("ruins"), "废墟存在")
	assert_true(db.has("trench"), "战壕存在")
	assert_true(db.has("bunker"), "堡垒存在")

func test_cqb_weapon_mod():
	print("  CQB 武器修正")
	var wd = preload("res://scripts/core/weapon_data.gd")
	assert_eq(wd.smg().cqb_rating, 3, "冲锋枪CQB评级3")
	assert_eq(wd.rifle().cqb_rating, 1, "步枪CQB评级1")
	assert_eq(wd.mg().cqb_rating, 1, "机枪CQB评级1")
	assert_eq(wd.tank_gun().cqb_rating, 0, "坦克炮CQB评级0")

# ========== State Tests ==========

func test_squad_state_normal():
	print("  Squad 正常状态")
	var sq = _S("infantry", 0, Vector2i(0, 0), [_M("A", "infantry", 10)])
	assert_eq(sq.get_state(), 2, "默认70士气=正常")
	assert_eq(sq.get_state_name(), "正常")
	assert_eq(sq.get_hit_modifier(), 0, "正常无命中修正")

func test_squad_state_confused():
	print("  Squad 混乱状态")
	var sq = _S("infantry", 0, Vector2i(0, 0), [_M("A", "infantry", 10)])
	sq.morale = 15
	assert_eq(sq.get_state(), 1, "士气15=混乱")
	assert_eq(sq.get_hit_modifier(), -15, "混乱命中-15")
	assert_eq(int(sq.get_damage_modifier() * 100), 80, "混乱伤害80%")

func test_squad_state_broken():
	print("  Squad 溃败状态")
	var sq = _S("infantry", 0, Vector2i(0, 0), [_M("A", "infantry", 10)])
	sq.morale = 0
	assert_eq(sq.get_state(), 0, "士气0=溃败")
	assert_eq(sq.get_move_range(), 0, "溃败不能移动")
	assert_false(sq.can_attack(null), "溃败不能攻击")

func test_squad_morale_change():
	print("  Squad 士气变化")
	var sq = _S("infantry", 0, Vector2i(0, 0), [_M("A", "infantry", 10)])
	sq.apply_morale(-20)
	assert_eq(sq.morale, 50, "扣20士气=50")
	sq.apply_morale(100)
	assert_eq(sq.morale, 100, "不能超过100")

func test_squad_suppression():
	print("  Squad 压制")
	var sq = _S("infantry", 0, Vector2i(0, 0), [_M("A", "infantry", 10)])
	sq.apply_suppression(50)
	assert_eq(sq.suppression, 50, "压制50")
	var bonus_range = sq.get_suppression_damage_bonus_range()
	assert_true(bonus_range >= -30 and bonus_range <= -5, "压制50→伤害范围-30%~-5% (实际:" + str(int(bonus_range)) + ")")

func test_squad_zoc_check():
	print("  ZOC检测函数")
	var mn = load("res://scripts/map/hex_map.gd").new()
	mn.hex_size = 32.0
	mn.map_width = 5
	mn.map_height = 5
	mn._terrain_db = GameManager.TERRAIN_DB
	for q in range(5):
		for r in range(5):
			mn.terrain_grid[Vector2i(q, r)] = "plain"

	# 创建两个不同阵营的Squad
	var wd = preload("res://scripts/core/weapon_data.gd")
	var sq_a = _S("infantry", 0, Vector2i(2, 2), [preload("res://scripts/core/member.gd").new("A","infantry",10,60,wd.rifle())])
	var sq_b = _S("infantry", 1, Vector2i(2, 3), [preload("res://scripts/core/member.gd").new("B","infantry",10,60,wd.rifle())])

	GameManager.all_squads = [sq_a, sq_b]

	assert_true(mn.has_enemy_zoc(Vector2i(2,4), 0), "敌方ZOC检测(2,4)")
	assert_false(mn.has_enemy_zoc(Vector2i(0,0), 0), "无ZOC(0,0)")

	var zoc_units = mn.get_zoc_units_at(Vector2i(2,3))
	assert_true(zoc_units.size() > 0, "ZOC范围内有单位")

	GameManager.all_squads = []

# ========== UnitType ==========

func test_unit_type_data():
	print("  UnitType 数据")
	var db = GameManager.UNIT_TYPE_DB
	assert_true(db.has("infantry"))
	assert_true(db.has("tank"))
	assert_true(db.has("recon"))
	assert_true(db.has("artillery"))

func test_unit_type_cost():
	print("  UnitType 价格")
	var db = GameManager.UNIT_TYPE_DB
	assert_true(db["infantry"].cost > 0)
	assert_true(db["tank"].cost > db["infantry"].cost)

# ========== GameManager ==========

func test_game_manager_basic():
	print("  GameManager 基础")
	assert_true(GameManager.TERRAIN_DB.size() > 0)
	assert_true(GameManager.UNIT_TYPE_DB.size() > 0)

func test_game_manager_squad():
	print("  GameManager Squad")
	var gm = GameManager
	gm.all_squads.clear()
	gm.player_squads.clear()
	var sq = _S("infantry", 0, Vector2i(3, 3), [_M("A", "infantry", 10)])
	gm.register_squad(sq)
	assert_eq(gm.all_squads.size(), 1)
	assert_true(gm.get_squad_at(Vector2i(3, 3)) != null)
	gm.unregister_squad(sq)
	assert_eq(gm.get_squad_at(Vector2i(3, 3)), null)

func test_game_manager_multi_squad():
	print("  GameManager 多Squad")
	var gm = GameManager
	gm.all_squads.clear()
	gm.player_squads.clear()
	gm.enemy_squads.clear()
	
	var p1 = _S("infantry", 0, Vector2i(0,0), [_M("a","infantry",10)])
	var p2 = _S("tank", 0, Vector2i(1,0), [_M("b","vehicle",15)])
	var e1 = _S("infantry", 1, Vector2i(5,5), [_M("c","infantry",10)])
	
	gm.register_squad(p1)
	gm.register_squad(p2)
	gm.register_squad(e1)
	assert_eq(gm.all_squads.size(), 3)
	assert_eq(gm.player_squads.size(), 2)
	assert_eq(gm.enemy_squads.size(), 1)

func test_game_manager_turn_cycle():
	print("  GameManager 回合循环")
	var gm = GameManager
	gm.turn_count = 0
	gm.start_battle()
	assert_eq(gm.current_phase, 0)
	assert_eq(gm.turn_count, 1)
	gm.end_player_turn()
	assert_eq(gm.current_phase, 1)
	gm.end_enemy_turn()
	assert_eq(gm.current_phase, 0)
	assert_eq(gm.turn_count, 2)

# ========== Terrain ==========

func test_terrain_data():
	print("  地形数据")
	var db = GameManager.TERRAIN_DB
	assert_true(db.has("plain"))
	assert_true(db.has("forest"))
	assert_true(db.has("mountain"))
	assert_true(db.has("city"))
	assert_eq(db["plain"].move_cost, 1)
	assert_eq(db["mountain"].move_cost, 3)
	assert_eq(db["mountain"].defense_bonus, 4)

# ========== HexMap ==========

func test_hex_map_reachable():
	print("  HexMap 可达范围")
	var map_node = load("res://scripts/map/hex_map.gd").new()
	map_node.hex_size = 32.0
	map_node.map_width = 5
	map_node.map_height = 5
	map_node._terrain_db = GameManager.TERRAIN_DB
	for q in range(5):
		for r in range(5):
			map_node.terrain_grid[Vector2i(q, r)] = "plain"

	var r = map_node.get_reachable_hexes(Vector2i(2, 2), 3)
	assert_true(r.size() > 0)
	assert_false(r.has(Vector2i(2, 2)))

	var rc = map_node.get_reachable_hexes(Vector2i(0, 0), 2)
	assert_true(rc.size() > 0)

func test_hex_map_attackable():
	print("  HexMap 攻击范围")
	var map_node = load("res://scripts/map/hex_map.gd").new()
	map_node.hex_size = 32.0
	map_node.map_width = 5
	map_node.map_height = 5
	map_node._terrain_db = GameManager.TERRAIN_DB
	for q in range(5):
		for r in range(5):
			map_node.terrain_grid[Vector2i(q, r)] = "plain"

	var a1 = map_node.get_attackable_hexes(Vector2i(2, 2), 1)
	assert_eq(a1.size(), 6)
	assert_false(a1.has(Vector2i(2, 2)))

	var a2 = map_node.get_attackable_hexes(Vector2i(0, 0), 2)
	assert_true(a2.size() > 0)

# ========== Movement & Border Tests ==========

func test_squad_move_range():
	print("  Squad 移动力")
	var sq = _S("infantry", 0, Vector2i(0, 0), [_M("A", "infantry", 10)])
	assert_eq(sq.move_range, 2, "步兵移动力2")
	sq = _S("vehicle", 0, Vector2i(0, 0), [_M("A", "vehicle", 10)])
	assert_eq(sq.move_range, 3, "载具移动力3")
	sq = _S("recon", 0, Vector2i(0, 0), [_M("A", "vehicle", 10)])
	assert_eq(sq.move_range, 4, "侦察移动力4")

func test_tier_boundary_no_empty_lines():
	print("  边界线: 空格子不应画线")
	var tiers = {Vector2i(2,2): 1, Vector2i(3,2): 1, Vector2i(4,2): 2, Vector2i(6,2): 3}
	var dirs = [Vector2i(1,0), Vector2i(0,1), Vector2i(-1,1), Vector2i(-1,0), Vector2i(0,-1), Vector2i(1,-1)]
	var lines = 0
	for hex in tiers:
		var ap_this = tiers[hex]
		for di in range(dirs.size()):
			var nb = hex + dirs[di]
			var ap_nb = tiers.get(nb, 0)
			if ap_nb <= 0 or ap_this <= ap_nb: continue
			lines += 1
	# (4,2)T2左边(3,2)T1 → 画1条. (6,2)T3邻格均不在tiers → 不画
	assert_eq(lines, 1, "只有(4,2)→(3,2)这一对跨层级边界")

func test_tier_boundary_same_tier_no_line():
	print("  边界线: 同级不应画线")
	var tiers = {Vector2i(2,2): 1, Vector2i(3,2): 1}
	var dirs = [Vector2i(1,0), Vector2i(0,1), Vector2i(-1,1), Vector2i(-1,0), Vector2i(0,-1), Vector2i(1,-1)]
	var lines = 0
	for hex in tiers:
		var ap_this = tiers[hex]
		for di in range(dirs.size()):
			var nb = hex + dirs[di]
			var ap_nb = tiers.get(nb, 0)
			if ap_nb <= 0 or ap_this <= ap_nb: continue
			lines += 1
	assert_eq(lines, 0, "同级不画线")

func test_tier_boundary_adjacent_tiers():
	print("  边界线: 相邻层级应画线")
	var tiers = {Vector2i(2,2): 1, Vector2i(3,2): 2}
	var dirs = [Vector2i(1,0), Vector2i(0,1), Vector2i(-1,1), Vector2i(-1,0), Vector2i(0,-1), Vector2i(1,-1)]
	var lines = 0
	for hex in tiers:
		var ap_this = tiers[hex]
		for di in range(dirs.size()):
			var nb = hex + dirs[di]
			var ap_nb = tiers.get(nb, 0)
			if ap_nb <= 0 or ap_this <= ap_nb: continue
			lines += 1
	assert_eq(lines, 1, "1对边界画1条线(从高层侧)")

func test_squad_ap_deduct_move():
	print("  Squad 移动AP扣除")
	var sq = _S("infantry", 0, Vector2i(0, 0), [_M("A", "infantry", 10)])
	sq.ap = 3
	sq.spend_ap(1)
	assert_eq(sq.ap, 2, "移动1次消耗1AP")
	sq.spend_ap(2)
	assert_eq(sq.ap, 0, "再花2AP=0")

func test_squad_move_then_attack_ap():
	print("  Squad 移动+攻击AP")
	var sq = _S("infantry", 0, Vector2i(0, 0), [_M("A", "infantry", 10)])
	sq.ap = 3
	sq.spend_ap(1)  # 移动1次
	assert_eq(sq.ap, 2, "移动后剩2AP")
	assert_true(sq.can_afford(2), "够攻击(2AP)")
	sq.spend_ap(2)  # 攻击
	assert_eq(sq.ap, 0, "攻击后0AP")
	assert_false(sq.can_afford(1), "不能继续行动")

# ========== Summary ==========

func _print_summary():
	print("")
	print("=".repeat(60))
	print("  全量测试报告")
	print("=".repeat(60))
	print("  用例: %d  通过: %d  失败: %d" % [_tests_run, _passed, _failed])
	if _failed > 0:
		print("  失败详情:")
		for line in _test_log:
			if line.begins_with("[FAIL]"):
				print("  " + line)
	else:
		print("  全部通过!")
	print("=".repeat(60))
