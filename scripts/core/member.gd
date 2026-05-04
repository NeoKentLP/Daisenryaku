extends RefCounted

var member_name: String = ""
var member_type: String = "infantry"
var hp: int = 10
var max_hp: int = 10
var is_alive: bool = true

var bs: int = 60
var evasion: int = 5
var armor: int = 0
var concealment: int = 0
var move_type: String = "foot"

var skill_name: String = ""
var skill_ap: int = 0
var skill_description: String = ""

var weapons: Array = []

func _init(name: String = "", type: String = "infantry", hp_val: int = 10, bs_val: int = 60, weapon_data: Dictionary = {}):
	member_name = name
	member_type = type
	max_hp = hp_val
	hp = max_hp
	bs = bs_val
	if not weapon_data.is_empty():
		weapons.append(weapon_data)

func take_damage(amount: int) -> int:
	hp = max(0, hp - amount)
	if hp <= 0:
		is_alive = false
	return hp

func has_weapon(atype: String) -> bool:
	for w in weapons:
		if w.get("ammo", 0) > 0:
			return true
	return false

func consume_ammo() -> void:
	for i in range(weapons.size()):
		var w = weapons[i]
		if w.get("ammo", 0) > 0:
			w["ammo"] -= 1
			break

func resupply_weapons() -> void:
	for w in weapons:
		w["ammo"] = w.get("max_ammo", w.get("ammo", 0))

func get_ammo_summary() -> String:
	var parts = []
	for w in weapons:
		parts.append(w.get("name", "?") + " " + str(w.get("ammo", 0)) + "/" + str(w.get("max_ammo", 0)))
	return ", ".join(parts)

func needs_supply() -> bool:
	for w in weapons:
		if w.get("ammo", 0) < w.get("max_ammo", 0):
			return true
	return false
