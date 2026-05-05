extends Node

# 不加载场景，直接模拟 _spawn_mission_squads 的完整逻辑

func _ready():
	print("=".repeat(60))
	print("  直接模拟 _spawn_mission_squads")
	print("=".repeat(60))

	# 1. 准备数据
	GameManager.selected_nation = "germany"
	GameManager.all_squads.clear()
	GameManager.player_squads.clear()
	GameManager.enemy_squads.clear()

	# 创建4个指挥官
	for i in range(4):
		var bg = ["infantry", "infantry", "vehicle", "artillery"][i]
		var cmd = preload("res://scripts/commander/commander.gd").new("germany", bg)
		if i == 0:
			cmd.set_rarity("英雄")
			cmd.random_quality_skills(3)
		GameManager.initial_commanders.append(cmd)
	print("[OK] 指挥官: " + str(GameManager.initial_commanders.size()) + "个")

	# 创建部署数据
	var wd = preload("res://scripts/core/weapon_data.gd")
	var ms = preload("res://scripts/core/member.gd")
	var places = {}
	for i in range(4):
		var members = []
		if i < 2:
			members.append(ms.new("班长", "infantry", 12, 60, wd.rifle()))
			for j in range(3): members.append(ms.new("步枪手", "infantry", 10, 60, wd.rifle()))
			members.append(ms.new("机枪手", "infantry", 12, 55, wd.mg()))
		elif i == 2:
			var crew = ms.new("车长", "vehicle", 15, 50, wd.rifle())
			crew.armor = 6
			members.append(crew)
		else:
			members.append(ms.new("炮长", "infantry", 10, 55, wd.pistol()))
			members.append(ms.new("炮手", "infantry", 10, 50, wd.artillery_gun()))
		var hex = [Vector2i(4, 7), Vector2i(5, 7), Vector2i(6, 7), Vector2i(5, 9)][i]
		places[hex] = {"idx": i, "name": "部队" + str(i+1), "type": ["infantry","infantry","vehicle","artillery"][i], "members": members}

	GameManager.mission_placed_squads = places
	print("[OK] 部署数据: " + str(places.size()) + "支部队")

	# 2. 创建 hex_map (模拟 main_controller 做的事)
	print("[...] 创建地图...")
	var map = load("res://scripts/map/hex_map.gd").new()
	map.map_width = 12
	map.map_height = 10
	map.name = "HexMap"
	add_child(map)
	await get_tree().process_frame
	print("[OK] 地图创建完成: " + str(map.terrain_grid.size()) + "格")

	# 检查 terrain_grid 是否正确
	var terrain_types = {}
	for h in map.terrain_grid:
		var t = map.terrain_grid[h]
		terrain_types[t] = terrain_types.get(t, 0) + 1
	print("[MAP] 地形分布: " + str(terrain_types))

	# 3. 模拟 _setup_prologue_terrain
	print("[...] 设置序章地形...")
	_setup_prologue_terrain(map)
	print("[OK] 地形设置完成")

	# 验证关键位置
	var checks = [
		Vector2i(5, 0), Vector2i(0, 0), Vector2i(11, 9),
		Vector2i(4, 4), Vector2i(5, 4),
		Vector2i(2, 3), Vector2i(3, 3),
		Vector2i(4, 5),
	]
	for c in checks:
		print("  (" + str(c.x) + "," + str(c.y) + ") = " + map.terrain_grid.get(c, "???"))
	print("[OK] 关键位置验证完成")

	# 4. 模拟战场部队生成
	print("[...] 生成部队...")
	var ss = load("res://scripts/core/squad.gd")
	var placed = GameManager.mission_placed_squads
	var squad_count = 0

	# 设置 HQ 地形
	map.terrain_grid[Vector2i(5, 8)] = "hq"

	for hex in placed:
		var sd = placed[hex]
		var sq = ss.new()
		var members = []
		for m_data in sd.members:
			var m = ms.new(m_data.member_name, m_data.member_type, m_data.hp, m_data.bs)
			for w in m_data.weapons:
				m.weapons.append(w.duplicate())
			m.armor = m_data.armor
			m.evasion = m_data.evasion
			m.concealment = m_data.concealment
			m.is_alive = m_data.is_alive
			m.hp = m_data.hp
			m.max_hp = m_data.max_hp
			members.append(m)
		sq.setup(sd.type, 0, hex, members)
		sq.name = "P_" + sd.name
		map.add_child(sq)
		sq.update_visual()
		GameManager.register_squad(sq)
		print("  [P] " + sd.name + " @ " + str(hex) + " - " + str(members.size()) + "人")

		# 分指挥官
		var cmd_idx = squad_count
		if cmd_idx < GameManager.initial_commanders.size():
			var cmd = GameManager.initial_commanders[cmd_idx]
			GameManager.assign_commander(sq, cmd)
		squad_count += 1

	print("[OK] 己方部队: " + str(squad_count) + "支")

	# 生成敌方
	var enemy_hexes = [Vector2i(5, 2), Vector2i(4, 1), Vector2i(6, 1)]
	var enemy_count = 0
	for hex in enemy_hexes:
		var sq = ss.new()
		var members = []
		for j in range(4):
			members.append(ms.new("步兵", "infantry", 10, 55, wd.rifle()))
		members.append(ms.new("机枪手", "infantry", 12, 50, wd.mg()))
		sq.setup("infantry", 1, hex, members)
		sq.name = "E_" + str(enemy_count)
		map.add_child(sq)
		sq.update_visual()
		GameManager.register_squad(sq)
		enemy_count += 1
	print("[OK] 敌方部队: " + str(enemy_count) + "支")

	# 敌方 HQ 地形
	map.terrain_grid[Vector2i(5, 1)] = "hq"

	# 验证
	print("=".repeat(60))
	print("[RESULT] total squads: " + str(GameManager.all_squads.size()))
	print("[RESULT] player: " + str(GameManager.player_squads.size()))
	print("[RESULT] enemy: " + str(GameManager.enemy_squads.size()))

	# 检查每支部队
	for sq in GameManager.all_squads:
		var team = "P" if sq.team == 0 else "E"
		print("  " + team + " " + sq.squad_name + " @ " + str(sq.hex_coord) + " alive=" + str(sq.get_alive_count()) + "/" + str(sq.get_total_count()))
		var cmd = GameManager.get_commander(sq)
		if cmd:
			print("    commander: " + cmd.commander_name + " [" + cmd.rarity + "]")
		for m in sq.members:
			var wpn_str = ""
			for w in m.weapons:
				wpn_str += w.get("name", "?") + " "
			print("    " + m.member_name + " HP=" + str(m.hp) + "/" + str(m.max_hp) + " armor=" + str(m.armor) + " weapons=" + wpn_str)

	print("[PASS] 所有验证完成!")
	get_tree().quit(0)

func _setup_prologue_terrain(mn):
	for q in range(12):
		for r in range(10):
			mn.terrain_grid[Vector2i(q, r)] = "plain"

	for q in range(12):
		mn.terrain_grid[Vector2i(q, 0)] = "forest"
		mn.terrain_grid[Vector2i(q, 9)] = "forest"

	mn.terrain_grid[Vector2i(0, 1)] = "forest"
	mn.terrain_grid[Vector2i(11, 1)] = "forest"
	mn.terrain_grid[Vector2i(2, 3)] = "forest"
	mn.terrain_grid[Vector2i(3, 3)] = "forest"
	mn.terrain_grid[Vector2i(6, 3)] = "forest"
	mn.terrain_grid[Vector2i(7, 3)] = "forest"
	mn.terrain_grid[Vector2i(4, 4)] = "city"
	mn.terrain_grid[Vector2i(5, 4)] = "city"
	mn.terrain_grid[Vector2i(0, 5)] = "mountain"
	mn.terrain_grid[Vector2i(1, 5)] = "mountain"
	mn.terrain_grid[Vector2i(3, 6)] = "forest"
	mn.terrain_grid[Vector2i(4, 6)] = "forest"
	mn.terrain_grid[Vector2i(5, 6)] = "forest"
	mn.terrain_grid[Vector2i(0, 8)] = "forest"
	mn.terrain_grid[Vector2i(11, 8)] = "forest"
