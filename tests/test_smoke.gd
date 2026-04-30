extends Node

# ============================================================
# 烟雾测试 (快速，每次修改必跑)
# 覆盖三层结构：Member → Squad → UnitType
# ============================================================

var _passed := 0
var _failed := 0
var _tests_run := 0
var _test_log := []

func _ready():
	print("=".repeat(40))
	print("  烟雾测试")
	print("=".repeat(40))
	print("")

	run_smoke_tests()
	_print_summary()
	get_tree().quit(_failed)

func run_smoke_tests():
	test_hex_util_basic()
	test_hex_util_distance()
	test_hex_util_neighbors()
	test_hex_util_pixel_roundtrip()
	test_member_basic()
	test_member_damage()
	test_squad_basic()
	test_squad_members()
	test_squad_damage()
	test_unit_type_data()
	test_game_manager_basic()
	test_game_manager_squad()
	test_terrain_data()
	test_cqb_terrain_list()
	test_cqb_weapon_bonus()
	test_engineer_detection()
	test_minefield_terrain()
	test_equipment_upgrade_paths()
	test_reserve_storage()
	test_commander_basic()
	test_commander_exp()
	test_commander_pool()

func assert_eq(got, expected, desc):
	_tests_run += 1
	if got == expected:
		_passed += 1
		_test_log.append("[PASS] " + desc)
	else:
		_failed += 1
		var msg = "[FAIL] " + desc + ": 期望 " + str(expected) + ", 实际 " + str(got)
		_test_log.append(msg)
		push_error(msg)

func assert_true(cond, desc):
	assert_eq(cond, true, desc)

func assert_false(cond, desc):
	assert_eq(cond, false, desc)

func _make_member(name: String, type: String, hp: int):
	return preload("res://scripts/core/member.gd").new(name, type, hp)

func _make_squad(type_id: String, team: int, hex: Vector2i, members: Array):
	var sq = load("res://scripts/core/squad.gd").new()
	sq.setup(type_id, team, hex, members)
	return sq

# ============================================================
# HexUtil (unchanged)
# ============================================================

func test_hex_util_basic():
	print("  HexUtil 基础")
	var p = HexUtil.axial_to_pixel(0, 0, 32)
	assert_eq(p, Vector2(0, 0), "Hex(0,0)")
	p = HexUtil.axial_to_pixel(1, 0, 32)
	assert_eq(int(p.x), 55, "Hex(1,0) X=55")

func test_hex_util_distance():
	print("  HexUtil 距离")
	assert_eq(HexUtil.hex_distance(Vector2i(0,0), Vector2i(0,0)), 0, "同点")
	assert_eq(HexUtil.hex_distance(Vector2i(0,0), Vector2i(1,0)), 1, "邻格")
	assert_eq(HexUtil.hex_distance(Vector2i(0,0), Vector2i(5,0)), 5, "直线5")

func test_hex_util_neighbors():
	print("  HexUtil 邻居")
	var nbs = HexUtil.hex_neighbors(Vector2i(0, 0))
	assert_eq(nbs.size(), 6, "6个邻居")
	assert_true(nbs.has(Vector2i(1,0)), "含(1,0)")

func test_hex_util_pixel_roundtrip():
	print("  HexUtil 往返")
	for c in [Vector2i(3,5), Vector2i(-2,4)]:
		var px = HexUtil.axial_to_pixel(c.x, c.y, 32)
		var back = HexUtil.pixel_to_axial(px.x, px.y, 32)
		assert_eq(back, c, "Hex(%d,%d)" % [c.x, c.y])

# ============================================================
# Member
# ============================================================

func test_member_basic():
	print("  Member 基础")
	var m = _make_member("步枪手", "infantry", 10)
	assert_eq(m.member_name, "步枪手", "名称")
	assert_eq(m.member_type, "infantry", "类型")
	assert_eq(m.max_hp, 10, "HP")
	assert_eq(m.hp, 10, "初始HP")
	assert_true(m.is_alive, "存活")

func test_member_damage():
	print("  Member 受伤")
	var m = _make_member("步枪手", "infantry", 10)
	m.take_damage(4)
	assert_eq(m.hp, 6, "扣4HP")
	assert_true(m.is_alive, "存活")
	m.take_damage(6)
	assert_eq(m.hp, 0, "扣光HP")
	assert_false(m.is_alive, "死亡")

# ============================================================
# Squad
# ============================================================

func test_squad_basic():
	print("  Squad 基础")
	var members = [
		_make_member("班长", "infantry", 12),
		_make_member("步枪手", "infantry", 10),
		_make_member("步枪手", "infantry", 10),
	]
	var sq = _make_squad("infantry", 0, Vector2i(2, 3), members)
	assert_eq(sq.team, 0, "阵营")
	assert_eq(sq.hex_coord, Vector2i(2, 3), "位置")
	assert_eq(sq.get_total_count(), 3, "总成员数")
	assert_eq(sq.get_alive_count(), 3, "存活数")
	assert_eq(sq.get_total_hp(), 32, "总HP")

func test_squad_members():
	print("  Squad 成员管理")
	var members = [
		_make_member("A", "infantry", 10),
		_make_member("B", "infantry", 10),
	]
	var sq = _make_squad("infantry", 0, Vector2i(0, 0), members)
	assert_eq(sq.members.size(), 2, "成员数量")
	assert_eq(sq.members[0].member_name, "A", "成员A")

func test_squad_damage():
	print("  Squad 受伤")
	var members = [
		_make_member("A", "infantry", 10),
		_make_member("B", "infantry", 10),
	]
	var sq = _make_squad("infantry", 0, Vector2i(0, 0), members)
	sq.take_damage(5)
	assert_eq(sq.get_alive_count(), 2, "轻伤无人阵亡")
	sq.take_damage(3)
	assert_eq(sq.get_alive_count(), 2, "累计无人阵亡")
	sq.take_damage(15)
	assert_eq(sq.get_alive_count(), 1, "过量伤害有人阵亡")

# ============================================================
# UnitType Data
# ============================================================

func test_unit_type_data():
	print("  UnitType 数据")
	var db = GameManager.UNIT_TYPE_DB
	assert_true(db.has("infantry"), "步兵")
	assert_true(db.has("tank"), "坦克")
	assert_true(db.has("recon"), "侦察")
	assert_eq(db["infantry"].cost, 200, "步兵价格")

# ============================================================
# GameManager
# ============================================================

func test_game_manager_basic():
	print("  GameManager 基础")
	var gm = GameManager
	assert_true(gm.TERRAIN_DB.size() > 0, "地形数据加载")

func test_game_manager_squad():
	print("  GameManager Squad管理")
	var gm = GameManager
	gm.player_squads.clear()
	gm.enemy_squads.clear()
	gm.all_squads.clear()
	
	var m = _make_member("test", "infantry", 10)
	var sq = _make_squad("infantry", 0, Vector2i(5, 5), [m])
	gm.register_squad(sq)
	assert_eq(gm.all_squads.size(), 1, "注册1个Squad")
	assert_eq(gm.player_squads.size(), 1, "玩家Squad+1")
	
	var found = gm.get_squad_at(Vector2i(5, 5))
	assert_true(found != null, "get_squad_at找到")
	assert_eq(found, sq, "正确的Squad")
	
	gm.unregister_squad(sq)
	assert_eq(gm.all_squads.size(), 0, "注销后空")

# ============================================================
# Terrain
# ============================================================

func test_terrain_data():
	print("  地形数据")
	var db = GameManager.TERRAIN_DB
	assert_true(db.has("plain"), "平地")
	assert_true(db.has("forest"), "森林")
	assert_true(db.has("mountain"), "山地")
	assert_true(db.has("city"), "城市")
	assert_eq(db["plain"].move_cost, 1, "平地移动=1")
	assert_eq(db["mountain"].move_cost, 3, "山地移动=3")
	assert_eq(db["mountain"].defense_bonus, 4, "山地防御+4")

func test_cqb_terrain_list():
	print("  CQB地形")
	var cqb = ["city", "forest", "ruins", "trench", "bunker"]
	assert_true(cqb.has("city"), "城市CQB")
	assert_true(cqb.has("forest"), "森林CQB")
	assert_true(cqb.has("ruins"), "废墟CQB")
	assert_eq(cqb.size(), 5, "共5种CQB地形")

func test_cqb_weapon_bonus():
	print("  CQB武器修正")
	var bm = load("res://scripts/battle/battle_manager.gd").new()
	var wd = preload("res://scripts/core/weapon_data.gd")
	# 冲锋枪正修正
	var smg = _make_member("突击", "infantry", 10)
	smg.weapons.append(wd.smg())
	var sq_smg = _make_squad("infantry", 0, Vector2i(0,0), [smg])
	assert_true(bm._cqb_weapon_mod(sq_smg) > 0, "冲锋枪CQB正修正")

	# 步枪非正修正
	var rifle = _make_member("步兵", "infantry", 10)
	rifle.weapons.append(wd.rifle())
	var sq_rifle = _make_squad("infantry", 0, Vector2i(0,0), [rifle])
	assert_true(bm._cqb_weapon_mod(sq_rifle) <= 0, "步枪CQB非正修正")

func test_engineer_detection():
	print("  工兵检测")
	var wd = preload("res://scripts/core/weapon_data.gd")
	var eng = _make_member("工兵", "infantry", 10)
	var tools = wd.rifle().duplicate()
	tools["name"] = "工兵工具"
	eng.weapons.append(tools)
	var sq = _make_squad("infantry", 0, Vector2i(0,0), [eng])
	# 根据main_controller的_is_engineer逻辑: 武器名含"工具"或"工兵"
	var is_eng = false
	for m in sq.members:
		if not m.is_alive: continue
		for w in m.weapons:
			var wn = w.get("name", "")
			if "工具" in wn or "工兵" in wn: is_eng = true
	assert_true(is_eng, "工兵被正确识别")

func test_minefield_terrain():
	print("  雷区地形")
	var db = GameManager.TERRAIN_DB
	assert_true(db.has("minefield"), "雷区地形存在")
	assert_true(db.has("trench"), "战壕存在")
	assert_true(db.has("bunker"), "堡垒存在")

func test_equipment_upgrade_paths():
	print("  装备升级路径")
	var eq = preload("res://scripts/equipment/equipment_upgrade.gd")
	var paths = eq.get_upgrade_paths()
	assert_true(paths.has("Kar98k"), "Kar98k可升级")
	assert_true(paths.has("MG42"), "MG42可升级")
	assert_eq(paths["Kar98k"]["upgrades_to"][0], "G43", "Kar98k→G43")

func test_reserve_storage():
	print("  储备库")
	var gm = GameManager
	gm.reserve_storage = {}
	gm.add_to_storage("Kar98k", 3)
	assert_eq(gm.get_storage_count("Kar98k"), 3, "加3把Kar98k")
	assert_true(gm.remove_from_storage("Kar98k", 1), "取出1把")
	assert_eq(gm.get_storage_count("Kar98k"), 2, "剩余2把")
	assert_false(gm.remove_from_storage("MP40", 1), "不存在返回false")

func test_commander_basic():
	print("  指挥官基础")
	var cmd = preload("res://scripts/commander/commander.gd").new()
	assert_true(cmd.commander_name.length() > 0, "有名字")
	assert_true(cmd.background_skill.length() > 0, "有背景技能")
	assert_true(cmd.talent_skill.length() > 0, "有天赋技能")
	assert_eq(cmd.level, 1, "初始等级1")

func test_commander_exp():
	print("  指挥官经验")
	var cmd = preload("res://scripts/commander/commander.gd").new()
	cmd._exp = 0
	cmd.level = 1
	cmd.gain_exp(100)
	assert_eq(cmd.level, 2, "100经验升2级")
	cmd.gain_exp(200)
	assert_eq(cmd.level, 3, "再200经验升3级")

func test_commander_pool():
	print("  指挥官池")
	var gm = GameManager
	gm.commander_pool.clear()
	gm.squad_commanders.clear()
	var cmd = preload("res://scripts/commander/commander.gd").new()
	gm.add_commander_to_pool(cmd)
	assert_eq(gm.commander_pool.size(), 1, "池中有1个")
	
	var sq = _make_squad("infantry", 0, Vector2i(0,0), [_make_member("A","infantry",10)])
	assert_true(gm.assign_commander(sq, cmd), "任命成功")
	assert_eq(gm.commander_pool.size(), 0, "池中移除")
	assert_true(gm.get_commander(sq) != null, "可查到指挥官")

	gm.unassign_commander(sq)
	assert_eq(gm.commander_pool.size(), 1, "卸载后回池")
	assert_eq(gm.get_commander(sq), null, "Squad不再有指挥官")

# ============================================================
# Summary
# ============================================================

func _print_summary():
	print("")
	print("=".repeat(40))
	print("  烟雾测试报告")
	print("=".repeat(40))
	print("  用例: %d  通过: %d  失败: %d" % [_tests_run, _passed, _failed])
	if _failed > 0:
		for line in _test_log:
			if line.begins_with("[FAIL]"):
				print("  " + line)
	else:
		print("  全部通过!")
	print("=".repeat(40))
