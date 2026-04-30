extends RefCounted

# 武器属性生成辅助
# 每种武器有: name, damage_type, damage_vs(dict), bs_bonus, armor_piercing,
#             range_min, range_max, ammo, suppression, supply_cost

static func rifle() -> Dictionary:
	return {
		"name": "Kar98k",
		"damage_type": "soft",
		"damage_vs": {"infantry": 15, "vehicle": 5, "helicopter": 0, "fixed_wing": 0},
		"bs_bonus": 0,
		"armor_piercing": 3,
		"range_min": 1, "range_max": 4,
		"ammo": 20, "max_ammo": 20,
		"suppression": 5,
		"supply_cost": 1,
	}

static func smg() -> Dictionary:
	return {
		"name": "MP40",
		"damage_type": "soft",
		"damage_vs": {"infantry": 20, "vehicle": 3, "helicopter": 0, "fixed_wing": 0},
		"bs_bonus": 5,
		"armor_piercing": 2,
		"range_min": 1, "range_max": 2,
		"ammo": 30, "max_ammo": 30,
		"suppression": 8,
		"supply_cost": 1,
	}

static func mg() -> Dictionary:
	return {
		"name": "MG42",
		"damage_type": "soft",
		"damage_vs": {"infantry": 25, "vehicle": 8, "helicopter": 3, "fixed_wing": 0},
		"bs_bonus": -5,
		"armor_piercing": 4,
		"range_min": 1, "range_max": 5,
		"ammo": 50, "max_ammo": 50,
		"suppression": 25,
		"supply_cost": 2,
	}

static func tank_gun() -> Dictionary:
	return {
		"name": "75mm炮",
		"damage_type": "armored",
		"damage_vs": {"infantry": 15, "vehicle": 50, "helicopter": 5, "fixed_wing": 0},
		"bs_bonus": 0,
		"armor_piercing": 12,
		"range_min": 1, "range_max": 5,
		"ammo": 30, "max_ammo": 30,
		"suppression": 15,
		"supply_cost": 5,
	}

static func artillery_gun() -> Dictionary:
	return {
		"name": "105mm榴弹炮",
		"damage_type": "soft",
		"damage_vs": {"infantry": 40, "vehicle": 25, "helicopter": 10, "fixed_wing": 0},
		"bs_bonus": -10,
		"armor_piercing": 8,
		"range_min": 2, "range_max": 6,
		"ammo": 10, "max_ammo": 10,
		"suppression": 45,
		"supply_cost": 10,
	}
