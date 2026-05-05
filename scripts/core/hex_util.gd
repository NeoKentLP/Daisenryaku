extends Node

const SQRT3 := 1.7320508075688772

func axial_to_pixel(q: float, r: float, size: float) -> Vector2:
	var x = size * (SQRT3 * q + SQRT3 / 2.0 * r)
	var y = size * (3.0 / 2.0 * r)
	return Vector2(x, y)

func pixel_to_axial(px: float, py: float, size: float) -> Vector2i:
	var q = (SQRT3 / 3.0 * px - 1.0 / 3.0 * py) / size
	var r = (2.0 / 3.0 * py) / size
	return _hex_round(q, r)

func _hex_round(q: float, r: float) -> Vector2i:
	var s = -q - r
	var rq = round(q)
	var rr = round(r)
	var rs = round(s)
	var dq = abs(rq - q)
	var dr = abs(rr - r)
	var ds = abs(rs - s)
	if dq > dr and dq > ds:
		rq = -rr - rs
	elif dr > ds:
		rr = -rq - rs
	return Vector2i(rq, rr)

func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var dq = a.x - b.x
	var dr = a.y - b.y
	return (abs(dq) + abs(dq + dr) + abs(dr)) / 2

func hex_neighbors(hex: Vector2i) -> Array:
	var dirs = [
		Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1),
		Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)
	]
	var result = []
	for d in dirs:
		result.append(hex + d)
	return result

func hexes_in_range(center: Vector2i, radius: int) -> Array:
	var result = []
	for dq in range(-radius, radius + 1):
		var dr_min = max(-radius, -dq - radius)
		var dr_max = min(radius, -dq + radius)
		for dr in range(dr_min, dr_max + 1):
			result.append(Vector2i(center.x + dq, center.y + dr))
	return result

func hex_corners(center: Vector2, size: float) -> PackedVector2Array:
	var corners = PackedVector2Array()
	for i in range(6):
		var angle = PI / 3.0 * i - PI / 2.0
		corners.append(Vector2(
			center.x + size * cos(angle),
			center.y + size * sin(angle)
		))
	return corners

func astar_path(
	start: Vector2i,
	goal: Vector2i,
	func_is_passable: Callable,
	func_movement_cost: Callable,
	max_iterations: int = 500
) -> Array:
	if start == goal:
		return [start]

	var open_set = { start: true }
	var came_from = {}
	var g_score = { start: 0 }
	var f_score = { start: hex_distance(start, goal) }

	while not open_set.is_empty():
		var current = null
		var lowest_f = INF
		for hex in open_set:
			var f = f_score.get(hex, INF)
			if f < lowest_f:
				lowest_f = f
				current = hex
		if current == goal:
			return _reconstruct_path(came_from, current)
		open_set.erase(current)
		for neighbor in hex_neighbors(current):
			if not func_is_passable.call(neighbor):
				continue
			var move_cost = func_movement_cost.call(neighbor)
			var tentative_g = g_score[current] + move_cost
			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + hex_distance(neighbor, goal)
				open_set[neighbor] = true
		max_iterations -= 1
		if max_iterations <= 0:
			break
	return []

func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array:
	var path = [current]
	while came_from.has(current):
		current = came_from[current]
		path.append(current)
	path.reverse()
	return path
