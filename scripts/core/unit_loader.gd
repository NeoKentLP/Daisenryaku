extends RefCounted

var _weapons_cache: Dictionary = {}
var _units_cache: Dictionary = {}
var _loaded: bool = false

func ensure_loaded():
	if _loaded: return
	_loaded = true  # 先设标志防止递归
	_weapons_cache = _load_weapons("res://data/germany/weapons.json")
	_weapons_cache.merge(_load_weapons("res://data/soviet/weapons.json"))
	
	for f in ["res://data/germany/units.json", "res://data/soviet/units.json"]:
		var units = _load_units(f)
		for u in units:
			_units_cache[u.id] = u

func _load_weapons(path: String) -> Dictionary:
	var result = {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return result
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_ARRAY: return result
	for w in data:
		var wid = w.get("id", "")
		if wid == "": continue
		# Map JSON fields to weapon Dictionary
		result[wid] = {
			"name": w.get("name", wid),
			"weapon_type": w.get("type", "rifle"),
			"base_damage": w.get("base_damage", 15),
			"penetration": w.get("penetration", 0),
			"range_min": w.get("range_min", 0),
			"range_max": w.get("range_max", 1),
			"bs_bonus": w.get("bs_bonus", 0),
			"suppression": w.get("suppression", 5),
			"cqb_rating": w.get("cqb_rating", 0),
			"ammo": w.get("ammo", 10),
			"max_ammo": w.get("max_ammo", 10),
			"supply_cost": w.get("supply_cost", 1),
			# Backward compat
			"damage_type": "soft",
			"damage_vs": {},
		}
	return result

func _load_units(path: String) -> Array:
	var result = []
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return result
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_ARRAY: return result
	for u in data:
		var uid = u.get("id", "")
		if uid == "": continue
		var unit_type = u.get("type", "infantry")
		# Infer member_type from unit type
		var default_member_type = "infantry"
		if unit_type in ["vehicle"]:
			default_member_type = "vehicle"
		elif unit_type in ["air"]:
			default_member_type = "air"
		elif unit_type in ["artillery"]:
			default_member_type = "infantry"
		
		var members = []
		for m in u.get("members", []):
			var role = m.get("role", "兵")
			var mtype = m.get("member_type", default_member_type)
			var hp = m.get("hp", 10)
			var bs = m.get("bs", 60)
			var count = m.get("count", 1)
			var armor = m.get("armor", 0)
			var evasion = m.get("evasion", 0)
			var conceal = m.get("conceal", 0)
			for ci in range(count):
				var ms = preload("res://scripts/core/member.gd")
				var member = ms.new(role, mtype, hp, bs)
				member.armor = armor
				member.evasion = evasion
				member.concealment = conceal
				for wid in m.get("weapons", ["kar98k"]):
					var w = get_weapon(wid)
					if w:
						member.weapons.append(w.duplicate(true))
				members.append(member)
		result.append({
			"id": uid,
			"name": u.get("name", uid),
			"type": u.get("type", "infantry"),
			"nation": u.get("nation", "germany"),
			"members": members,
			"initiative": u.get("initiative", 4),
		})
	return result

func get_weapon(wid: String):
	ensure_loaded()
	return _weapons_cache.get(wid, null)

func get_unit(uid: String):
	ensure_loaded()
	return _units_cache.get(uid, null)

func get_starting_units(nation: String) -> Array:
	ensure_loaded()
	var result = []
	if nation == "germany":
		for uid in ["ger_inf_sq39", "ger_inf_sq39", "ger_sdkfz221", "ger_mortar81"]:
			var u = get_unit(uid)
			if u: result.append(u)
	else:
		for uid in ["sov_inf_sq39", "sov_inf_sq39", "sov_ba20", "sov_pm37"]:
			var u = get_unit(uid)
			if u: result.append(u)
	return result

func get_enemy_units(nation: String) -> Array:
	ensure_loaded()
	var enemy_nation = "soviet" if nation == "germany" else "germany"
	var result = []
	if enemy_nation == "soviet":
		for uid in ["sov_inf_sq39", "sov_inf_sq39", "sov_mg_sq"]:
			var u = get_unit(uid)
			if u: result.append(u)
	else:
		for uid in ["ger_inf_sq39", "ger_inf_sq39", "ger_mg_sq"]:
			var u = get_unit(uid)
			if u: result.append(u)
	return result
