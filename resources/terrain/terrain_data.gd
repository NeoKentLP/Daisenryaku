extends Resource

@export var id: String
@export var display_name: String
@export var move_cost: int = 1
@export var defense_bonus: int = 0
@export var color: Color = Color.WHITE
@export var is_passable: bool = true
@export var blocks_sight: bool = false

func _init(p_id: String = "", p_name: String = "", p_cost: int = 1, p_defense: int = 0, p_color: Color = Color.GRAY):
	id = p_id
	display_name = p_name
	move_cost = p_cost
	defense_bonus = p_defense
	color = p_color

static func create_defaults() -> Dictionary:
	var db := {}
	db["plain"] = new("plain", "平地", 1, 0, Color(0.6, 0.8, 0.4))
	db["forest"] = new("forest", "森林", 2, 2, Color(0.2, 0.5, 0.1))
	db["mountain"] = new("mountain", "山地", 3, 4, Color(0.5, 0.4, 0.2))
	db["river"] = new("river", "河流", 2, 0, Color(0.3, 0.5, 0.9))
	db["road"] = new("road", "道路", 1, 0, Color(0.7, 0.6, 0.4))
	db["city"] = new("city", "城市", 1, 3, Color(0.5, 0.5, 0.5))
	db["hq"] = new("hq", "指挥部", 1, 3, Color(0.8, 0.2, 0.2))
	db["factory"] = new("factory", "工厂", 1, 2, Color(0.6, 0.4, 0.1))
	db["ruins"] = new("ruins", "废墟", 2, 3, Color(0.4, 0.35, 0.3))
	db["trench"] = new("trench", "战壕", 1, 4, Color(0.5, 0.3, 0.15))
	db["bunker"] = new("bunker", "堡垒", 1, 6, Color(0.4, 0.3, 0.2))
	db["minefield"] = new("minefield", "雷区", 1, 0, Color(0.9, 0.1, 0.1))
	return db
