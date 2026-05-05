extends Node2D

@export var hex_size: float = 48.0
@export var map_width: int = 15
@export var map_height: int = 10

var terrain_grid: Dictionary = {}  # Vector2i -> terrain_id string
var tile_nodes: Dictionary = {}    # Vector2i -> Polygon2D
var highlight_nodes: Dictionary = {}    # Vector2i -> Polygon2D
var overlay_nodes: Dictionary = {}    # Vector2i -> Polygon2D (trench/minefield)

var _terrain_db: Dictionary = {}

func _ready():
	_terrain_db = GameManager.TERRAIN_DB
	GameManager.hex_map = self
	_generate_map()
	await get_tree().process_frame
	_center_camera()

func _generate_map():
	for q in range(map_width):
		for r in range(map_height):
			var hex := Vector2i(q, r)
			var terrain_id := _pick_terrain(q, r)
			terrain_grid[hex] = terrain_id
			_create_tile(hex, terrain_id)

func _pick_terrain(q: int, r: int) -> String:
	if q == 0 and r == 0:
		return "hq"
	if q == map_width - 1 and r == map_height - 1:
		return "hq"
	if q == 0 or q == map_width - 1 or r == 0 or r == map_height - 1:
		return "river"
	if q > map_width / 2.0 - 2 and q < map_width / 2.0 + 2 and r > map_height / 2.0 - 2 and r < map_height / 2.0 + 2:
		return "city" if (q + r) % 3 != 0 else "plain"
	if q > 2 and q < 6 and r > 2 and r < 5:
		return "forest"
	if q > map_width - 5 and q < map_width - 2 and r > 1 and r < 4:
		return "mountain"
	if (q + r) % 7 == 0:
		return "road"
	return "plain"

func _create_tile(hex: Vector2i, terrain_id: String):
	var terrain = _terrain_db.get(terrain_id, _terrain_db["plain"])
	var pos = HexUtil.axial_to_pixel(hex.x, hex.y, hex_size)
	
	var poly = Polygon2D.new()
	poly.polygon = HexUtil.hex_corners(Vector2.ZERO, hex_size)
	poly.color = terrain.color
	poly.position = pos
	poly.name = "Tile_%d_%d" % [hex.x, hex.y]
	add_child(poly)
	tile_nodes[hex] = poly

func set_terrain(hex: Vector2i, terrain_id: String):
	terrain_grid[hex] = terrain_id
	if tile_nodes.has(hex):
		var terrain = _terrain_db.get(terrain_id, _terrain_db["plain"])
		tile_nodes[hex].color = terrain.color

var highlight_poly: Polygon2D = null

func highlight_hexes(hexes: Array, color: Color):
	_clear_highlights()
	for hex in hexes:
		_add_highlight(hex, color)

func add_highlight(hex: Vector2i, color: Color):
	_add_highlight(hex, color)

func _add_highlight(hex: Vector2i, color: Color):
	if highlight_nodes.has(hex):
		highlight_nodes[hex].queue_free()
		highlight_nodes.erase(hex)
	var pos = HexUtil.axial_to_pixel(hex.x, hex.y, hex_size)
	var poly = Polygon2D.new()
	poly.polygon = HexUtil.hex_corners(Vector2.ZERO, hex_size)
	poly.color = color
	poly.position = pos
	poly.z_index = 1
	add_child(poly)
	highlight_nodes[hex] = poly

func highlight_hexes_tiered(tiers: Dictionary):
	# tiers: { hex -> ap_cost (1/2/3) }
	# 绿色从浅到深: 1AP最亮, 3AP最深
	var colors = {
		1: Color(0.35, 0.85, 0.35, 0.40),
		2: Color(0.30, 0.75, 0.30, 0.38),
		3: Color(0.25, 0.65, 0.25, 0.36),
	}
	_clear_highlights()
	for hex in tiers:
		var ap = tiers[hex]
		_add_highlight(hex, colors.get(ap, Color(0.3, 0.8, 0.3, 0.4)))

func _clear_highlights():
	for n in highlight_nodes.values():
		n.queue_free()
	highlight_nodes.clear()

func clear_highlights():
	_clear_highlights()

func has_overlay(hex: Vector2i) -> bool:
	return overlay_nodes.has(hex)

func get_overlay(hex: Vector2i):
	if overlay_nodes.has(hex):
		var n = overlay_nodes[hex]
		if n.has_meta("type"): return n.get_meta("type")
	return null

func set_overlay(hex: Vector2i, type: String, color: Color):
	_remove_overlay(hex)
	var pos = HexUtil.axial_to_pixel(hex.x, hex.y, hex_size)
	var poly = Polygon2D.new()
	poly.polygon = HexUtil.hex_corners(Vector2.ZERO, hex_size * 0.65)
	poly.color = color
	poly.position = pos
	poly.z_index = 0
	poly.set_meta("type", type)
	add_child(poly)
	overlay_nodes[hex] = poly

func remove_overlay(hex: Vector2i):
	_remove_overlay(hex)

func _remove_overlay(hex: Vector2i):
	if overlay_nodes.has(hex):
		overlay_nodes[hex].queue_free()
		overlay_nodes.erase(hex)

func get_terrain_at(hex: Vector2i):
	var tid = terrain_grid.get(hex, "plain")
	return _terrain_db.get(tid, _terrain_db["plain"])

func is_passable(hex: Vector2i) -> bool:
	if not terrain_grid.has(hex):
		return false
	if GameManager.get_squad_at(hex) != null:
		return false
	var t = get_terrain_at(hex)
	return t != null and t.is_passable

func get_movement_cost(hex: Vector2i) -> int:
	var t = get_terrain_at(hex)
	return t.move_cost if t else 99

func get_reachable_hexes(from: Vector2i, move_range: int) -> Array:
	var visited = { from: 0 }
	var queue = [from]
	var result: Array = []
	while not queue.is_empty():
		var current = queue.pop_front()
		var cost = visited[current]
		if cost > 0:
			result.append(current)
		if cost >= move_range:
			continue
		for nb in HexUtil.hex_neighbors(current):
			if visited.has(nb):
				continue
			if not terrain_grid.has(nb):
				continue
			var mc = get_movement_cost(nb)
			var new_cost = cost + mc
			if new_cost > move_range:
				continue
			if GameManager.get_squad_at(nb) != null:
				continue
			visited[nb] = new_cost
			queue.append(nb)
	return result

func get_attackable_hexes(from: Vector2i, attack_range: int) -> Array:
	var result: Array = []
	for hex in HexUtil.hexes_in_range(from, attack_range):
		if terrain_grid.has(hex) and hex != from:
			result.append(hex)
	return result

func find_path(from: Vector2i, to: Vector2i, ignore_squad = null) -> Array:
	var passable_func = func(hex):
		if not terrain_grid.has(hex): return false
		if ignore_squad and GameManager.get_squad_at(hex) == ignore_squad:
			pass
		elif GameManager.get_squad_at(hex) != null:
			return false
		var t = get_terrain_at(hex)
		return t and t.is_passable

	return HexUtil.astar_path(from, to, passable_func, get_movement_cost)

func has_enemy_zoc(hex: Vector2i, my_team: int) -> bool:
	for sq in GameManager.all_squads:
		if sq.team != my_team and sq.is_alive:
			if HexUtil.hex_distance(sq.hex_coord, hex) == 1:
				return true
	return false

func get_zoc_units_at(hex: Vector2i) -> Array:
	var result = []
	for sq in GameManager.all_squads:
		if sq.is_alive and HexUtil.hex_distance(sq.hex_coord, hex) == 1:
			result.append(sq)
	return result

func is_supply_station(hex: Vector2i) -> bool:
	var tid = terrain_grid.get(hex, "plain")
	if tid == "hq" or tid == "factory": return true
	# Check for HQ squad
	var sq = GameManager.get_squad_at(hex)
	if sq and sq.unit_type_id == "command":
		return true
	return false

func hex_to_pixel(hex: Vector2i) -> Vector2:
	return HexUtil.axial_to_pixel(hex.x, hex.y, hex_size)

func pixel_to_hex(pos: Vector2) -> Vector2i:
	return HexUtil.pixel_to_axial(pos.x, pos.y, hex_size)

func _center_camera():
	var cx = map_width / 2.0
	var cy = map_height / 2.0
	var center = HexUtil.axial_to_pixel(cx, cy, hex_size)
	var cam = get_viewport().get_camera_2d()
	if cam:
		cam.position = center
