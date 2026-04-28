extends Node

# ============================================================
# 全量测试 (提交/打包前跑)
# 覆盖所有边界条件和回归检测
# 用法: godot --path <project> res://tests/test_full.tscn
# ============================================================

var _passed := 0
var _failed := 0
var _tests_run := 0
var _test_log := []

func _ready():
	print("=".repeat(60))
	print("  战棋游戏测试套件 v2.0")
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
	test_game_manager_basic()
	test_game_manager_command_points()
	test_game_manager_turn_cycle()
	test_terrain_data()
	test_unit_data()
	test_unit_creation_and_position()
	test_unit_movement()
	test_unit_take_damage()
	test_unit_can_attack()
	test_battle_combat_resolution()
	test_battle_counter_attack()
	test_hex_map_reachable()
	test_hex_map_attackable()
	test_has_acted_prevents_reselect()

func assert_eq(got, expected, desc: String):
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

func assert_approx(got: float, expected: float, tol: float, desc):
	_tests_run += 1
	if abs(got - expected) <= tol:
		_passed += 1
		_test_log.append("[PASS] " + desc)
	else:
		_failed += 1
		var msg = "[FAIL] " + desc + ": 期望 ~" + str(expected) + ", 实际 " + str(got)
		_test_log.append(msg)
		push_error(msg)

# ============================================================
# 测试用例 1-6: HexUtil 核心数学
# ============================================================

func test_hex_util_basic():
	print("  [模块] HexUtil 基础数学")
	var pixel = HexUtil.axial_to_pixel(0, 0, 32)
	assert_eq(pixel, Vector2(0, 0), "Hex(0,0) -> (0,0)")
	pixel = HexUtil.axial_to_pixel(1, 0, 32)
	assert_approx(pixel.x, 55.425, 0.01, "Hex(1,0) X")
	assert_eq(pixel.y, 0.0, "Hex(1,0) Y=0")
	pixel = HexUtil.axial_to_pixel(0, 1, 32)
	assert_approx(pixel.x, 27.712, 0.01, "Hex(0,1) X")
	assert_eq(pixel.y, 48.0, "Hex(0,1) Y=48")

func test_hex_util_distance():
	print("  [模块] HexUtil 距离计算")
	assert_eq(HexUtil.hex_distance(Vector2i(0,0), Vector2i(0,0)), 0, "同点")
	assert_eq(HexUtil.hex_distance(Vector2i(0,0), Vector2i(1,0)), 1, "邻格")
	assert_eq(HexUtil.hex_distance(Vector2i(0,0), Vector2i(5,0)), 5, "直线5")
	assert_eq(HexUtil.hex_distance(Vector2i(0,0), Vector2i(3,3)), 6, "六边形对角线距离")
	assert_eq(HexUtil.hex_distance(Vector2i(2,3), Vector2i(5,7)), 7, "任意两点")

func test_hex_util_neighbors():
	print("  [模块] HexUtil 邻居")
	var nbs = HexUtil.hex_neighbors(Vector2i(0, 0))
	assert_eq(nbs.size(), 6, "6个邻居")
	assert_true(nbs.has(Vector2i(1,0)), "含 (1,0)")
	assert_true(nbs.has(Vector2i(0,1)), "含 (0,1)")
	assert_true(nbs.has(Vector2i(-1,1)), "含 (-1,1)")
	assert_true(nbs.has(Vector2i(-1,0)), "含 (-1,0)")
	assert_true(nbs.has(Vector2i(0,-1)), "含 (0,-1)")
	assert_true(nbs.has(Vector2i(1,-1)), "含 (1,-1)")

func test_hex_util_range():
	print("  [模块] HexUtil 范围")
	var r1 = HexUtil.hexes_in_range(Vector2i(0, 0), 1)
	assert_eq(r1.size(), 7, "range=1 => 7 (含自身)")
	var r2 = HexUtil.hexes_in_range(Vector2i(0, 0), 2)
	assert_eq(r2.size(), 19, "range=2 => 19 (含自身)")
	var r3 = HexUtil.hexes_in_range(Vector2i(0, 0), 0)
	assert_eq(r3.size(), 1, "range=0 => 1")

func test_hex_util_pixel_roundtrip():
	print("  [模块] HexUtil 像素往返")
	var cases = [Vector2i(3,5), Vector2i(-2,4), Vector2i(0,0), Vector2i(7,-3)]
	for c in cases:
		var px = HexUtil.axial_to_pixel(c.x, c.y, 32)
		var back = HexUtil.pixel_to_axial(px.x, px.y, 32)
		assert_eq(back, c, "Hex(%d,%d) 往返一致" % [c.x, c.y])

func test_hex_util_astar():
	print("  [模块] HexUtil A*寻路")
	var passable = func(h): return h.x >= 0 and h.x < 5 and h.y >= 0 and h.y < 5
	var cost = func(h): return 1
	var path = HexUtil.astar_path(Vector2i(0,0), Vector2i(2,0), passable, cost)
	assert_true(path.size() > 0, "直线可达")
	assert_eq(path[0], Vector2i(0,0), "起点")
	assert_eq(path[path.size()-1], Vector2i(2,0), "终点")
	# 被阻挡
	var blocked = func(h): return h == Vector2i(1,0) or h == Vector2i(0,1) or h == Vector2i(1,1)
	var path2 = HexUtil.astar_path(Vector2i(0,0), Vector2i(2,0), blocked, cost)
	assert_eq(path2.size(), 0, "被阻挡时无路径")
	# 同点
	var path3 = HexUtil.astar_path(Vector2i(1,1), Vector2i(1,1), passable, cost)
	assert_eq(path3.size(), 1, "同点返回[起点]")

# ============================================================
# 测试用例 7-8: GameManager
# ============================================================

func test_game_manager_basic():
	print("  [模块] GameManager 基础")
	var gm := GameManager
	gm.player_units.clear()
	gm.enemy_units.clear()
	gm.all_units.clear()
	var unit = load("res://scripts/units/unit.gd").new()
	unit.team = 0
	unit.hex_coord = Vector2i(1, 1)
	unit.hp = 10
	gm.register_unit(unit)
	assert_eq(gm.all_units.size(), 1, "注册")
	assert_eq(gm.player_units.size(), 1, "玩家+1")
	assert_true(gm.get_unit_at(Vector2i(1,1)) != null, "查询到单位")
	gm.unregister_unit(unit)
	assert_eq(gm.all_units.size(), 0, "注销后空")
	assert_eq(gm.get_unit_at(Vector2i(1,1)), null, "注销后查不到")

func test_game_manager_command_points():
	print("  [模块] GameManager 指挥点")
	var gm = GameManager
	gm.command_points = 100
	assert_true(gm.spend_command_points(50), "消费50成功")
	assert_eq(gm.command_points, 50, "余额")
	assert_false(gm.spend_command_points(100), "余额不足失败")
	assert_eq(gm.command_points, 50, "失败余额不变")

func test_game_manager_turn_cycle():
	print("  [模块] GameManager 回合循环")
	var gm = GameManager
	gm.turn_count = 0

	# 模拟玩家回合开始
	gm.start_battle()
	assert_eq(gm.current_phase, 0, "初始phase=0 (玩家回合)")
	assert_eq(gm.turn_count, 1, "初始回合=1")

	# 模拟玩家行动：创建单位并标记已行动
	var unit = load("res://scripts/units/unit.gd").new()
	unit.team = 0
	unit.hex_coord = Vector2i(0, 0)
	unit.has_acted = true
	gm.register_unit(unit)

	# 玩家结束回合 -> 切换敌方回合
	gm.end_player_turn()
	assert_eq(gm.current_phase, 1, "结束玩家->phase=1 (敌方回合)")

	# 敌方结束回合 -> 新玩家回合
	gm.end_enemy_turn()
	assert_eq(gm.current_phase, 0, "结束敌方->phase=0 (玩家回合)")
	assert_eq(gm.turn_count, 2, "回合数+1")
	assert_eq(gm.command_points, 150, "获得指挥点 (100+50)")

	# 检查 has_acted 被重置
	assert_false(unit.has_acted, "新回合 has_acted 被重置")

	gm.unregister_unit(unit)

# ============================================================
# 测试用例 9-10: 数据定义
# ============================================================

func test_terrain_data():
	print("  [模块] 地形数据")
	var db = GameManager.TERRAIN_DB
	assert_true(db.has("plain"), "平地")
	assert_true(db.has("forest"), "森林")
	assert_true(db.has("mountain"), "山地")
	assert_true(db.has("city"), "城市")
	assert_eq(db["plain"].move_cost, 1, "平地移动=1")
	assert_eq(db["forest"].move_cost, 2, "森林移动=2")
	assert_eq(db["mountain"].move_cost, 3, "山地移动=3")
	assert_eq(db["mountain"].defense_bonus, 4, "山地防御+4")
	assert_eq(db["city"].defense_bonus, 3, "城市防御+3")

func test_unit_data():
	print("  [模块] 兵种数据")
	var db = GameManager.UNIT_DB
	assert_true(db.has("infantry"), "步兵")
	assert_true(db.has("tank"), "坦克")
	assert_true(db.has("artillery"), "火炮")
	assert_true(db.has("recon"), "侦察车")
	assert_eq(db["infantry"].attack, 2, "步兵攻击=2")
	assert_eq(db["tank"].attack, 5, "坦克攻击=5")
	assert_eq(db["tank"].defense, 3, "坦克防御=3")
	assert_eq(db["tank"].move_range, 4, "坦克移动=4")
	assert_eq(db["artillery"].attack_range, 3, "火炮射程=3")
	assert_false(db["artillery"].can_attack_after_move, "火炮不可移动攻击")

# ============================================================
# 测试用例 11-14: 单位行为
# ============================================================

func _make_unit(type_id: String, team: int, hex: Vector2i):
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

func test_unit_creation_and_position():
	print("  [模块] 单位创建")
	var unit = _make_unit("tank", 0, Vector2i(3, 4))
	assert_eq(unit.unit_data.display_name, "坦克", "名称")
	assert_eq(unit.max_hp, 15, "HP=15")
	assert_eq(unit.team, 0, "阵营=玩家")
	assert_true(unit.is_alive, "存活")

func test_unit_movement():
	print("  [模块] 单位移动")
	var unit = _make_unit("infantry", 0, Vector2i(0, 0))
	unit.move_to(Vector2i(2, 3))
	assert_eq(unit.hex_coord, Vector2i(2, 3), "移动到 (2,3)")
	unit.move_to(Vector2i(-1, 2))
	assert_eq(unit.hex_coord, Vector2i(-1, 2), "移动到 (-1,2)")

func test_unit_take_damage():
	print("  [模块] 单位受伤")
	var unit = _make_unit("tank", 0, Vector2i(0, 0))
	var hp_left = unit.take_damage(5)
	assert_eq(hp_left, unit.max_hp - 5, "扣5HP")
	assert_true(unit.is_alive, "HP>0 存活")
	unit.take_damage(unit.hp)
	assert_false(unit.is_alive, "HP=0 死亡")

func test_unit_can_attack():
	print("  [模块] 单位攻击判定")
	var tank = _make_unit("tank", 0, Vector2i(0, 0))
	var enemy = _make_unit("infantry", 1, Vector2i(1, 0))
	var ally = _make_unit("infantry", 0, Vector2i(0, 1))
	var far = _make_unit("infantry", 1, Vector2i(5, 0))

	assert_true(tank.can_attack(enemy), "邻格可攻击")
	assert_false(tank.can_attack(null), "空目标不可")
	assert_false(tank.can_attack(ally), "同阵营不可")
	tank.has_acted = true
	assert_false(tank.can_attack(enemy), "已行动不可")
	tank.has_acted = false
	assert_false(tank.can_attack(far), "超射程不可")

# ============================================================
# 测试用例 15-16: 战斗系统
# ============================================================

func test_battle_combat_resolution():
	print("  [模块] 战斗系统")
	var tank = _make_unit("tank", 0, Vector2i(0, 0))
	var infantry = _make_unit("infantry", 1, Vector2i(1, 0))
	var bm = load("res://scripts/battle/battle_manager.gd").new()
	var result = bm.resolve_combat(tank, infantry)

	# 坦克攻击=5, 步兵防御=1 => 伤害=4
	assert_eq(result.damage_to_defender, 4, "坦克->步兵 伤害4")
	assert_true(result.damage_to_defender > 0, "造成伤害")
	assert_eq(result.attacker, tank, "攻击者正确")
	assert_eq(result.defender, infantry, "防御者正确")
	assert_true(tank.has_acted, "已标记行动")

func test_battle_counter_attack():
	print("  [模块] 战斗反击")
	var infantry = _make_unit("infantry", 0, Vector2i(0, 0))
	var tank = _make_unit("tank", 1, Vector2i(1, 0))
	var bm = load("res://scripts/battle/battle_manager.gd").new()
	var result = bm.resolve_combat(infantry, tank)

	# 步兵攻击=2, 坦克防御=3 => 伤害=1 (max(1,2-3))
	assert_eq(result.damage_to_defender, 1, "步兵->坦克 伤害1")
	# 反击: 坦克攻击=5, 步兵防御=1 => 反击=4
	assert_eq(result.damage_to_attacker, 4, "坦克反击 伤害4")

# ============================================================
# 测试用例 17-18: 地图系统
# ============================================================

func test_hex_map_reachable():
	print("  [模块] HexMap 可达范围")
	var map_node = load("res://scripts/map/hex_map.gd").new()
	map_node.hex_size = 32.0
	map_node.map_width = 5
	map_node.map_height = 5
	map_node._terrain_db = GameManager.TERRAIN_DB
	for q in range(5):
		for r in range(5):
			map_node.terrain_grid[Vector2i(q, r)] = "plain"

	var reachable = map_node.get_reachable_hexes(Vector2i(2, 2), 3)
	assert_true(reachable.size() > 0, "有可达格子")
	assert_true(reachable.size() <= 36, "数量合理")
	assert_false(reachable.has(Vector2i(2, 2)), "不含起点")

	var reachable_corner = map_node.get_reachable_hexes(Vector2i(0, 0), 2)
	assert_true(reachable_corner.size() > 0, "角落可达")
	assert_false(reachable_corner.has(Vector2i(-1, 0)), "不出界")

func test_hex_map_attackable():
	print("  [模块] HexMap 攻击范围")
	var map_node = load("res://scripts/map/hex_map.gd").new()
	map_node.hex_size = 32.0
	map_node.map_width = 5
	map_node.map_height = 5
	map_node._terrain_db = GameManager.TERRAIN_DB
	for q in range(5):
		for r in range(5):
			map_node.terrain_grid[Vector2i(q, r)] = "plain"

	var attackable = map_node.get_attackable_hexes(Vector2i(2, 2), 1)
	assert_eq(attackable.size(), 6, "射程1 => 6格")
	assert_false(attackable.has(Vector2i(2, 2)), "不含自身")

	var attackable2 = map_node.get_attackable_hexes(Vector2i(0, 0), 2)
	assert_true(attackable2.size() > 0, "角落射程2")
	assert_false(attackable2.has(Vector2i(0, 0)), "不含自身")

func test_has_acted_prevents_reselect():
	print("  [模块] has_acted 禁止重复选中")
	var unit = _make_unit("infantry", 0, Vector2i(0, 0))
	assert_false(unit.has_acted, "初始未行动")
	assert_eq(unit.get_move_range(), 3, "行动前有移动范围")

	unit.has_acted = true
	assert_eq(unit.get_move_range(), 0, "行动后移动范围为0")
	assert_true(unit.has_acted, "已标记行动")

	# 关键: 即使调用 move_to 也不会重置 has_acted
	unit.move_to(Vector2i(2, 2))
	assert_true(unit.has_acted, "移动后仍保持已行动状态")
	assert_eq(unit.get_move_range(), 0, "移动后仍无移动范围")

	unit.has_acted = false
	unit.has_acted = true
	unit.take_damage(1)
	assert_true(unit.is_alive, "受伤不解除已行动")
	assert_true(unit.has_acted, "受伤不影响已行动状态")

# ============================================================
# 结果输出
# ============================================================

func _print_summary():
	print("")
	print("=".repeat(60))
	print("  测试报告")
	print("=".repeat(60))
	print("  总用例: %d" % _tests_run)
	print("  通过:   %d" % _passed)
	print("  失败:   %d" % _failed)
	print("-".repeat(60))
	if _failed > 0:
		print("  失败详情:")
		for line in _test_log:
			if line.begins_with("[FAIL]"):
				print("    %s" % line)
	else:
		print("  全部通过!")
	print("=".repeat(60))
