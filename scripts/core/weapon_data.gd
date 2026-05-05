extends RefCounted

# 武器属性按 DESIGN §4.1 12字段
# name, weapon_type, base_damage, penetration, range_min/max,
# bs_bonus, suppression, cqb_rating, ammo/max_ammo, supply_cost

static func rifle() -> Dictionary:
	return {
		"name": "Kar98k",
		"weapon_type": "rifle",
		"base_damage": 22,
		"damage_type": "soft",
		"penetration": 1,
		"bs_bonus": 0,
		"range_min": 1, "range_max": 1,
		"ammo": 10, "max_ammo": 10,
		"suppression": 10,
		"cqb_rating": 1,
		"supply_cost": 2,
		# 向后兼容
		"armor_piercing": 1,
		"damage_vs": {"infantry": 22, "vehicle": 5, "helicopter": 0, "fixed_wing": 0},
	}

static func smg() -> Dictionary:
	return {
		"name": "MP40",
		"weapon_type": "smg",
		"base_damage": 15,
		"damage_type": "soft",
		"penetration": 0,
		"bs_bonus": 5,
		"range_min": 0, "range_max": 0,
		"ammo": 30, "max_ammo": 30,
		"suppression": 8,
		"cqb_rating": 3,
		"supply_cost": 1,
		"armor_piercing": 0,
		"damage_vs": {"infantry": 15, "vehicle": 3, "helicopter": 0, "fixed_wing": 0},
	}

static func mg() -> Dictionary:
	return {
		"name": "MG42",
		"weapon_type": "mg",
		"base_damage": 18,
		"damage_type": "soft",
		"penetration": 2,
		"bs_bonus": -5,
		"range_min": 1, "range_max": 1,
		"ammo": 50, "max_ammo": 50,
		"suppression": 20,
		"cqb_rating": 1,
		"supply_cost": 2,
		"armor_piercing": 2,
		"damage_vs": {"infantry": 18, "vehicle": 8, "helicopter": 3, "fixed_wing": 0},
	}

static func tank_gun() -> Dictionary:
	return {
		"name": "75mm炮",
		"weapon_type": "tank_gun",
		"base_damage": 40,
		"damage_type": "armored",
		"penetration": 9,
		"bs_bonus": 0,
		"range_min": 1, "range_max": 1,
		"ammo": 20, "max_ammo": 20,
		"suppression": 12,
		"cqb_rating": 0,
		"supply_cost": 3,
		"armor_piercing": 9,
		"damage_vs": {"infantry": 25, "vehicle": 50, "helicopter": 5, "fixed_wing": 0},
	}

static func pistol() -> Dictionary:
	return {
		"name": "手枪",
		"weapon_type": "pistol",
		"base_damage": 12,
		"damage_type": "soft",
		"penetration": 0,
		"bs_bonus": 0,
		"range_min": 0, "range_max": 0,
		"ammo": 15, "max_ammo": 15,
		"suppression": 5,
		"cqb_rating": 3,
		"supply_cost": 1,
		"armor_piercing": 0,
		"damage_vs": {"infantry": 12, "vehicle": 2, "helicopter": 0, "fixed_wing": 0},
	}

static func artillery_gun() -> Dictionary:
	return {
		"name": "105mm榴弹炮",
		"weapon_type": "artillery",
		"base_damage": 35,
		"damage_type": "soft",
		"penetration": 5,
		"bs_bonus": -10,
		"range_min": 2, "range_max": 3,
		"ammo": 10, "max_ammo": 10,
		"suppression": 15,
		"cqb_rating": 0,
		"supply_cost": 4,
		"armor_piercing": 5,
		"damage_vs": {"infantry": 35, "vehicle": 25, "helicopter": 10, "fixed_wing": 0},
	}
