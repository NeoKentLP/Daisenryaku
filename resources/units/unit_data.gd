extends Resource

@export var id: String
@export var display_name: String
@export var unit_type: int = 0  # UnitType enum
@export var max_hp: int = 10
@export var attack: int = 3
@export var defense: int = 1
@export var move_range: int = 3
@export var attack_range: int = 1
@export var can_attack_after_move: bool = true
@export var cost: int = 100  # 指挥点消耗
@export var color: Color = Color.GREEN
@export var icon_char: String = "T"  # 用字符作为临时图标

static func create_defaults() -> Dictionary:
	var db := {}
	db["infantry"] = _make("infantry", "步兵", 0, 10, 2, 1, 3, 1, true, 50, Color(0.3, 0.7, 0.3), "I")
	db["mechanized"] = _make("mechanized", "机械化步兵", 1, 12, 3, 2, 4, 1, true, 80, Color(0.3, 0.6, 0.4), "M")
	db["tank"] = _make("tank", "坦克", 2, 15, 5, 3, 4, 1, true, 150, Color(0.4, 0.6, 0.2), "T")
	db["artillery"] = _make("artillery", "火炮", 3, 8, 4, 1, 2, 3, false, 200, Color(0.6, 0.3, 0.3), "A")
	db["recon"] = _make("recon", "侦察车", 4, 8, 1, 1, 6, 1, true, 70, Color(0.5, 0.7, 0.5), "R")
	db["anti_air"] = _make("anti_air", "防空车", 5, 12, 4, 2, 3, 2, true, 120, Color(0.5, 0.5, 0.2), "AA")
	db["transport"] = _make("transport", "运输车", 6, 6, 0, 1, 5, 0, false, 40, Color(0.6, 0.6, 0.5), "C")
	return db

static func _make(id: String, name: String, utype: int, hp: int, atk: int, def: int, mv: int, atk_range: int, can_move_atk: bool, cost: int, col: Color, icon: String):
	var d := new()
	d.id = id
	d.display_name = name
	d.unit_type = utype
	d.max_hp = hp
	d.attack = atk
	d.defense = def
	d.move_range = mv
	d.attack_range = atk_range
	d.can_attack_after_move = can_move_atk
	d.cost = cost
	d.color = col
	d.icon_char = icon
	return d
