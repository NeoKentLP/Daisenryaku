extends RefCounted

# 武器升级路径: 每个武器可升级到的更高级型号
# 解锁条件: era + 势力关系

static func get_upgrade_paths() -> Dictionary:
	return {
		# 步枪系列
		"Kar98k": {"upgrades_to": ["G43", "StG44"], "era": 2, "cost": {}},
		"G43": {"upgrades_to": ["StG44"], "era": 2, "cost": {}},
		"StG44": {"upgrades_to": [], "era": 3, "cost": {}},

		# 坦克炮系列 (四号)
		"75mm炮": {"upgrades_to": ["75mmL48", "75mmL70"], "era": 2, "cost": {}},
		"75mmL48": {"upgrades_to": ["75mmL70"], "era": 3, "cost": {}},
		"75mmL70": {"upgrades_to": [], "era": 4, "cost": {}},

		# MG系列
		"MG34": {"upgrades_to": ["MG42"], "era": 2, "cost": {}},
		"MG42": {"upgrades_to": ["MG42/59"], "era": 3, "cost": {}},
		"MG42/59": {"upgrades_to": [], "era": 4, "cost": {}},
	}

static func get_variant_stats() -> Dictionary:
	return {
		"Kar98k": {"bs_bonus": 0, "armor_piercing": 3, "damage_vs": {"infantry": 15, "vehicle": 5}, "range_max": 4},
		"G43": {"bs_bonus": 2, "armor_piercing": 3, "damage_vs": {"infantry": 18, "vehicle": 5}, "range_max": 4},
		"StG44": {"bs_bonus": 5, "armor_piercing": 4, "damage_vs": {"infantry": 20, "vehicle": 8}, "range_max": 3},

		"75mm炮": {"bs_bonus": 0, "armor_piercing": 8, "damage_vs": {"infantry": 15, "vehicle": 45}, "range_max": 5},
		"75mmL48": {"bs_bonus": 0, "armor_piercing": 10, "damage_vs": {"infantry": 18, "vehicle": 50}, "range_max": 5},
		"75mmL70": {"bs_bonus": 0, "armor_piercing": 13, "damage_vs": {"infantry": 20, "vehicle": 60}, "range_max": 5},

		"MG34": {"bs_bonus": -5, "armor_piercing": 3, "damage_vs": {"infantry": 20, "vehicle": 6}, "range_max": 4, "suppression": 20},
		"MG42": {"bs_bonus": -5, "armor_piercing": 4, "damage_vs": {"infantry": 25, "vehicle": 8}, "range_max": 5, "suppression": 25},
		"MG42/59": {"bs_bonus": -3, "armor_piercing": 4, "damage_vs": {"infantry": 28, "vehicle": 10}, "range_max": 5, "suppression": 30},
	}

static func get_upgrade_cost(from_weapon: String, to_weapon: String) -> int:
	var paths = get_upgrade_paths()
	if not paths.has(from_weapon): return 999
	var upgrades = paths[from_weapon]["upgrades_to"]
	if to_weapon not in upgrades: return 999
	# 按等级差定价
	var era_from = paths[from_weapon]["era"]
	var era_to = paths[to_weapon]["era"] if paths.has(to_weapon) and paths[to_weapon].has("era") else (era_from + 1)
	return 100 + (era_to - era_from) * 50

# 武器匹配：检查武器名是否匹配某条升级链
static func get_weapon_family(name: String) -> String:
	if "Kar98k" in name: return "rifle"
	if "G43" in name: return "rifle"
	if "StG44" in name or "stg" in name.to_lower(): return "rifle"
	if "MG" in name: return "mg"
	if "75mm" in name: return "tank_gun"
	return ""
