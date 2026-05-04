extends RefCounted

# 据点类型
const HUB_HQ = "hq"
const HUB_CITY = "city"
const HUB_FACTORY = "factory"
const HUB_STRONGHOLD = "stronghold"
const HUB_VILLAGE = "village"
const HUB_FOREST = "forest"
const HUB_MOUNTAIN = "mountain"

static func get_hub_display(type: String) -> String:
	match type:
		HUB_HQ: return "指挥部"
		HUB_CITY: return "城市"
		HUB_FACTORY: return "工厂"
		HUB_STRONGHOLD: return "堡垒"
		HUB_VILLAGE: return "村庄"
		HUB_FOREST: return "林地"
		HUB_MOUNTAIN: return "山地"
	return type

static func get_hub_color(type: String) -> Color:
	match type:
		HUB_HQ: return Color(0.27, 0.67, 0.53)
		HUB_CITY: return Color(0.6, 0.6, 0.6)
		HUB_FACTORY: return Color(0.6, 0.4, 0.1)
		HUB_STRONGHOLD: return Color(0.8, 0.27, 0.27)
		HUB_VILLAGE: return Color(0.53, 0.67, 0.4)
		HUB_FOREST: return Color(0.2, 0.5, 0.1)
		HUB_MOUNTAIN: return Color(0.5, 0.4, 0.2)
	return Color(0.4, 0.4, 0.4)

static func is_enemy_hub(type: String) -> bool:
	return type == HUB_STRONGHOLD

static func create_default_nodes() -> Array:
	return [
		{"id": "hq", "name": "司令部", "type": HUB_HQ, "pos": Vector2(200, 320), "captured": true, "enemy_garrison": 0},
		{"id": "village1", "name": "格林村", "type": HUB_VILLAGE, "pos": Vector2(380, 240), "captured": false, "enemy_garrison": 0},
		{"id": "forest1", "name": "黑森林", "type": HUB_FOREST, "pos": Vector2(400, 420), "captured": false, "enemy_garrison": 0},
		{"id": "city1", "name": "林茨城", "type": HUB_CITY, "pos": Vector2(560, 200), "captured": false, "enemy_garrison": 0},
		{"id": "factory1", "name": "克虏伯工厂", "type": HUB_FACTORY, "pos": Vector2(580, 360), "captured": false, "enemy_garrison": 0},
		{"id": "mountain1", "name": "阿尔卑斯山口", "type": HUB_MOUNTAIN, "pos": Vector2(620, 480), "captured": false, "enemy_garrison": 0},
		{"id": "village2", "name": "圣彼得村", "type": HUB_VILLAGE, "pos": Vector2(720, 280), "captured": false, "enemy_garrison": 0},
		{"id": "stronghold1", "name": "前线堡垒", "type": HUB_STRONGHOLD, "pos": Vector2(760, 400), "captured": false, "enemy_garrison": 2},
		{"id": "city2", "name": "维也纳", "type": HUB_CITY, "pos": Vector2(860, 180), "captured": false, "enemy_garrison": 0},
		{"id": "village3", "name": "多瑙村", "type": HUB_VILLAGE, "pos": Vector2(870, 340), "captured": false, "enemy_garrison": 0},
		{"id": "stronghold2", "name": "东方要塞", "type": HUB_STRONGHOLD, "pos": Vector2(1000, 260), "captured": false, "enemy_garrison": 3},
		{"id": "mountain2", "name": "喀尔巴阡隘口", "type": HUB_MOUNTAIN, "pos": Vector2(1020, 420), "captured": false, "enemy_garrison": 0},
	]

static func create_default_edges() -> Array:
	return [
		{"from": "hq", "to": "village1", "cost": 1},
		{"from": "hq", "to": "forest1", "cost": 1},
		{"from": "village1", "to": "city1", "cost": 1},
		{"from": "village1", "to": "factory1", "cost": 1},
		{"from": "forest1", "to": "factory1", "cost": 1},
		{"from": "forest1", "to": "mountain1", "cost": 1},
		{"from": "city1", "to": "village2", "cost": 1},
		{"from": "city1", "to": "city2", "cost": 1},
		{"from": "factory1", "to": "village2", "cost": 1},
		{"from": "factory1", "to": "stronghold1", "cost": 1},
		{"from": "mountain1", "to": "stronghold1", "cost": 1},
		{"from": "village2", "to": "city2", "cost": 1},
		{"from": "village2", "to": "village3", "cost": 1},
		{"from": "village2", "to": "stronghold1", "cost": 1},
		{"from": "city2", "to": "stronghold2", "cost": 1},
		{"from": "city2", "to": "village3", "cost": 1},
		{"from": "village3", "to": "stronghold2", "cost": 1},
		{"from": "stronghold1", "to": "mountain2", "cost": 1},
		{"from": "mountain1", "to": "mountain2", "cost": 1},
		{"from": "mountain2", "to": "stronghold2", "cost": 1},
	]

static func find_path(nodes: Array, edges: Array, from_id: String, to_id: String) -> Array:
	var graph = {}
	for e in edges:
		if not graph.has(e["from"]): graph[e["from"]] = []
		if not graph.has(e["to"]): graph[e["to"]] = []
		graph[e["from"]].append({"node": e["to"], "cost": e.get("cost", 1)})
		graph[e["to"]].append({"node": e["from"], "cost": e.get("cost", 1)})

	if not graph.has(from_id) or not graph.has(to_id):
		return []

	var dist = {}
	var prev = {}
	var pq = [[0, from_id]]
	dist[from_id] = 0
	while not pq.is_empty():
		pq.sort_custom(func(a, b): return a[0] < b[0])
		var cur = pq.pop_front()
		var cd = cur[0]
		var cn = cur[1]
		if cn == to_id:
			var path = []
			var n = to_id
			while n != from_id:
				path.push_front(n)
				n = prev[n]
			path.push_front(from_id)
			return path
		if cd > dist.get(cn, 999):
			continue
		for nb in graph.get(cn, []):
			var nd = cd + nb["cost"]
			if nd < dist.get(nb["node"], 999):
				dist[nb["node"]] = nd
				prev[nb["node"]] = cn
				pq.append([nd, nb["node"]])
	return []
