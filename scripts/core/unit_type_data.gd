extends Resource

@export var id: String
@export var display_name: String
@export var cost: int = 100
@export var unlock_era: int = 1

var member_types = []
var member_weapons = {}

# 示例编制:
# german_infantry: 班长x1(Kar98k) + 步枪手x6(Kar98k) + 机枪手x1(MG42) + 副射手x1(Kar98k)
# panzer_iv: 车长x1(手枪) + 炮手x1(手枪) + 驾驶员x1(手枪) + 装填手x1(手枪) + 坦克(75mm炮)

static func create_defaults() -> Dictionary:
	var db = {}
	db["infantry"] = _make_infantry()
	db["mechanized"] = _make_mechanized()
	db["tank"] = _make_tank()
	db["artillery"] = _make_artillery()
	db["recon"] = _make_recon()
	db["anti_air"] = _make_anti_air()
	db["transport"] = _make_transport()
	db["command"] = _make_command()
	return db

static func _make_command():
	var t = new()
	t.id = "command"
	t.display_name = "指挥部"
	t.cost = 0
	t.member_types = ["指挥"]
	return t

static func _make_infantry():
	var t = new()
	t.id = "infantry"
	t.display_name = "步兵班"
	t.cost = 200
	t.member_types = ["步兵"]  # placeholder
	return t

static func _make_mechanized():
	var t = new()
	t.id = "mechanized"
	t.display_name = "机械化步兵班"
	t.cost = 350
	t.member_types = ["步兵", "载具"]
	return t

static func _make_tank():
	var t = new()
	t.id = "tank"
	t.display_name = "坦克"
	t.cost = 800
	t.member_types = ["载具"]
	return t

static func _make_artillery():
	var t = new()
	t.id = "artillery"
	t.display_name = "火炮班"
	t.cost = 600
	t.member_types = ["步兵", "火炮"]
	return t

static func _make_recon():
	var t = new()
	t.id = "recon"
	t.display_name = "侦察车"
	t.cost = 300
	t.member_types = ["载具"]
	return t

static func _make_anti_air():
	var t = new()
	t.id = "anti_air"
	t.display_name = "防空班"
	t.cost = 500
	t.member_types = ["载具", "步兵"]
	return t

static func _make_transport():
	var t = new()
	t.id = "transport"
	t.display_name = "运输车"
	t.cost = 200
	t.member_types = ["载具"]
	return t
