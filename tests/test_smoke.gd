extends Node

# ============================================================
# 烟雾测试 (快速，每次修改必跑)
# 覆盖核心逻辑，确保基本功能可用
# 用法: godot --path <project> res://tests/test_smoke.tscn
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
	test_game_manager_basic()
	test_game_manager_command_points()
	test_terrain_data()
	test_unit_data()
	test_unit_creation_and_position()
	test_unit_movement()
	test_unit_take_damage()
	test_battle_combat_resolution()

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

func _hex(p):
	return HexUtil.axial_to_pixel(p.x, p.y, 32)

func _make_unit(type_id, team, hex):
	var unit = load("res://scripts/units/unit.gd").new()
	unit.unit_data_id = type_id
	unit.team = team
	unit.hex_coord = hex
	var db = GameManager.UNIT_DB
	unit.unit_data = db.get(type_id, db["infantry"])
	unit.max_hp = unit.unit_data.max_hp
	unit.hp = unit.max_hp
	unit.is_alive = true
	unit.has_acted = false
	return unit

# ============================================================
# 烟雾测试用例
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

func test_game_manager_basic():
	print("  GameManager 基础")
	var gm = GameManager
	gm.player_units.clear()
	gm.enemy_units.clear()
	gm.all_units.clear()
	var u = load("res://scripts/units/unit.gd").new()
	u.team = 0
	u.hex_coord = Vector2i(1, 1)
	u.hp = 10
	gm.register_unit(u)
	assert_eq(gm.all_units.size(), 1, "注册")
	assert_true(gm.get_unit_at(Vector2i(1,1)) != null, "查得到")
	gm.unregister_unit(u)
	assert_eq(gm.get_unit_at(Vector2i(1,1)), null, "注销后查不到")

func test_game_manager_command_points():
	print("  GameManager 指挥点")
	var gm = GameManager
	gm.command_points = 100
	assert_true(gm.spend_command_points(50), "消费成功")
	assert_eq(gm.command_points, 50, "余额50")
	assert_false(gm.spend_command_points(100), "余额不足失败")

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

func test_unit_data():
	print("  兵种数据")
	var db = GameManager.UNIT_DB
	assert_true(db.has("infantry"), "步兵")
	assert_true(db.has("tank"), "坦克")
	assert_true(db.has("artillery"), "火炮")
	assert_eq(db["infantry"].attack, 2, "步兵攻击=2")
	assert_eq(db["tank"].attack, 5, "坦克攻击=5")
	assert_eq(db["tank"].move_range, 4, "坦克移动=4")

func test_unit_creation_and_position():
	print("  单位创建")
	var u = _make_unit("tank", 0, Vector2i(3, 4))
	assert_eq(u.unit_data.display_name, "坦克", "名称")
	assert_eq(u.max_hp, 15, "HP=15")

func test_unit_movement():
	print("  单位移动")
	var u = _make_unit("infantry", 0, Vector2i(0, 0))
	u.move_to(Vector2i(2, 3))
	assert_eq(u.hex_coord, Vector2i(2, 3), "移动到(2,3)")

func test_unit_take_damage():
	print("  单位受伤")
	var u = _make_unit("tank", 0, Vector2i(0, 0))
	u.take_damage(5)
	assert_eq(u.hp, u.max_hp - 5, "扣5HP")
	assert_true(u.is_alive, "存活")
	u.take_damage(u.hp)
	assert_false(u.is_alive, "死亡")

func test_battle_combat_resolution():
	print("  战斗系统")
	var tank = _make_unit("tank", 0, Vector2i(0, 0))
	var inf = _make_unit("infantry", 1, Vector2i(1, 0))
	var bm = load("res://scripts/battle/battle_manager.gd").new()
	var r = bm.resolve_combat(tank, inf)
	assert_eq(r.damage_to_defender, 4, "坦克->步兵 伤害4")
	assert_true(tank.has_acted, "已标记行动")

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
