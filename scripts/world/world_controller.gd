extends Node2D

var world_data = preload("res://scripts/world/world_data.gd")

var nodes: Array = []
var edges: Array = []
var current_hub_id: String = "hq"
var _node_sprites: Dictionary = {}
var _edge_sprites: Array = []
var _current_pos: Vector2
var _player_marker: Sprite2D
var _path_line: Line2D
var _moving: bool = false
var _info_label: Label
var _day_label: Label

const ENCOUNTER_CHANCE = 0.35

func _ready():
	GameManager.world_controller = self
	nodes = world_data.create_default_nodes()
	edges = world_data.create_default_edges()
	_render_map()
	_update_player_position()

func _render_map():
	_render_edges()
	_render_nodes()
	_render_player()
	_render_ui()

func _render_edges():
	for c in _edge_sprites: c.queue_free()
	_edge_sprites.clear()
	for e in edges:
		var from_node = _find_node(e["from"])
		var to_node = _find_node(e["to"])
		if from_node.is_empty() or to_node.is_empty(): continue

		var line = Line2D.new()
		line.points = [from_node["pos"], to_node["pos"]]
		line.width = 2
		line.default_color = Color(1, 1, 1, 0.1)
		line.z_index = -1
		add_child(line)
		_edge_sprites.append(line)

func _render_nodes():
	for c in _node_sprites.values(): c.queue_free()
	_node_sprites.clear()
	for nd in nodes:
		var container = Node2D.new()
		container.position = nd["pos"]
		add_child(container)
		_node_sprites[nd["id"]] = container

		var col = world_data.get_hub_color(nd["type"])
		var radius = 14 if not world_data.is_enemy_hub(nd["type"]) else 18

		var circle = _make_circle(radius, col if nd["captured"] else Color(col.r * 0.5, col.g * 0.5, col.b * 0.5, 0.8))
		circle.z_index = 1
		container.add_child(circle)

		if world_data.is_enemy_hub(nd["type"]):
			var inner = _make_circle(8, Color(1, 1, 1, 0.2))
			inner.z_index = 2
			container.add_child(inner)

		var label = Label.new()
		label.text = nd["name"]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(1, 1, 1) if nd["captured"] else Color(0.6, 0.6, 0.6))
		label.position = Vector2(-40, 20)
		label.size = Vector2(80, 20)
		label.z_index = 3
		container.add_child(label)

		if nd["type"] == world_data.HUB_HQ:
			var flag = Label.new()
			flag.text = "★"
			flag.position = Vector2(-6, -14)
			flag.add_theme_font_size_override("font_size", 12)
			flag.add_theme_color_override("font_color", Color(1, 0.87, 0.4))
			flag.z_index = 4
			container.add_child(flag)

func _make_circle(radius: float, color: Color) -> Sprite2D:
	var s = Sprite2D.new()
	var img = Image.create(radius * 2 + 4, radius * 2 + 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in range(radius * 2 + 4):
		for y in range(radius * 2 + 4):
			var dx = x - radius - 2
			var dy = y - radius - 2
			if dx * dx + dy * dy <= radius * radius:
				img.set_pixel(x, y, color)
	var tex = ImageTexture.create_from_image(img)
	s.texture = tex
	s.centered = true
	return s

func _render_player():
	_player_marker = Sprite2D.new()
	var img = Image.create(20, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in range(20):
		for y in range(20):
			var dx = x - 10
			var dy = y - 10
			if dx * dx + dy * dy <= 36:
				img.set_pixel(x, y, Color(0.47, 0.67, 1.0, 0.8))
			elif dx * dx + dy * dy <= 64:
				img.set_pixel(x, y, Color(0.47, 0.67, 1.0, 0.3))
	var tex = ImageTexture.create_from_image(img)
	_player_marker.texture = tex
	_player_marker.centered = true
	_player_marker.z_index = 5
	add_child(_player_marker)

	_path_line = Line2D.new()
	_path_line.width = 3
	_path_line.default_color = Color(0.47, 0.67, 1.0, 0.6)
	_path_line.z_index = 0
	add_child(_path_line)

func _render_ui():
	var screen = get_viewport().size

	_info_label = Label.new()
	_info_label.position = Vector2(10, 40)
	_info_label.size = Vector2(400, 50)
	_info_label.add_theme_font_size_override("font_size", 13)
	_info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	add_child(_info_label)

	_day_label = Label.new()
	_day_label.position = Vector2(screen.x - 120, 10)
	_day_label.size = Vector2(110, 30)
	_day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_day_label.add_theme_font_size_override("font_size", 14)
	_day_label.add_theme_color_override("font_color", Color(1, 1, 1))
	add_child(_day_label)

func _update_player_position():
	var nd = _find_node(current_hub_id)
	if not nd.is_empty():
		_current_pos = nd["pos"]
		_player_marker.position = _current_pos
	_update_info()

func _update_info():
	var nd = _find_node(current_hub_id)
	if nd.is_empty(): return
	var txt = "当前位置: " + nd["name"] + "  (" + world_data.get_hub_display(nd["type"]) + ")"
	txt += "\n点击据点移动 · 经过敌占区可能遇敌"
	_info_label.text = txt
	_day_label.text = "第 " + str(GameManager.world_day) + " 天"

func _find_node(id: String) -> Dictionary:
	for n in nodes:
		if n["id"] == id: return n
	return {}

func _unhandled_input(event):
	if _moving: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos = get_global_mouse_position()
		for nd in nodes:
			var dist = click_pos.distance_to(nd["pos"])
			if dist < 30 and nd["id"] != current_hub_id:
				_on_node_clicked(nd["id"])
				return

func _on_node_clicked(target_id: String):
	var path = world_data.find_path(nodes, edges, current_hub_id, target_id)
	if path.is_empty(): return
	_start_move(path)

func _start_move(path: Array):
	_moving = true
	_path_line.points = []
	for pid in path:
		var nd = _find_node(pid)
		if not nd.is_empty(): _path_line.points.append(nd["pos"])

	var total_cost = 0
	for i in range(1, path.size()):
		var f = _find_node(path[i-1])
		var t = _find_node(path[i])
		if f and t:
			for e in edges:
				if (e["from"] == f["id"] and e["to"] == t["id"]) or (e["from"] == t["id"] and e["to"] == f["id"]):
					total_cost += e.get("cost", 1)
					break

	_do_move_animation(path)

func _do_move_animation(path: Array):
	var tw = create_tween()
	tw.set_parallel(false)

	for i in range(1, path.size()):
		var nd = _find_node(path[i])
		if nd.is_empty(): continue
		tw.tween_property(_player_marker, "position", nd["pos"], 0.4)
		tw.tween_callback(_check_encounter.bind(path[i]))
		tw.tween_interval(0.1)

	tw.tween_callback(_finish_move.bind(path))

func _check_encounter(node_id: String):
	var nd = _find_node(node_id)
	if nd.is_empty(): return
	if nd["captured"]: return
	if world_data.is_enemy_hub(nd["type"]):
		_start_battle(nd)
		return
	if randf() < ENCOUNTER_CHANCE:
		_trigger_random_encounter(nd)

func _trigger_random_encounter(nd):
	GameManager.world_encounter_node = nd
	_info_label.text = "遇敌! 准备战斗..."
	_open_deployment()

func _start_battle(nd):
	GameManager.world_encounter_node = nd
	_info_label.text = "进攻 " + nd["name"] + "!"
	_open_deployment()

func _finish_move(path: Array):
	_path_line.points = []
	current_hub_id = path[path.size() - 1]
	var nd = _find_node(current_hub_id)
	if not nd.is_empty():
		_player_marker.position = nd["pos"]
		GameManager.world_day += 1
	_update_info()
	_moving = false

	if not nd.is_empty() and not nd["captured"] and not world_data.is_enemy_hub(nd["type"]):
		_on_arrive_hub(nd)

func _on_arrive_hub(nd):
	_info_label.text = "到达 " + nd["name"]
	GameManager.world_current_hub = nd
	var hub_ui = get_node_or_null("../HubUI")
	if not hub_ui: hub_ui = get_node_or_null("HubUI")
	if hub_ui and hub_ui.has_method("open"):
		hub_ui.open(nd)

func _open_deployment():
	var deployment = get_node_or_null("Deployment")
	if not deployment: deployment = get_node_or_null("../Deployment")
	if deployment and deployment.has_method("open"):
		deployment.open()

func trigger_battle():
	var scene = load("res://scenes/battle/main_scene.tscn")
	get_tree().change_scene_to_packed(scene)

func return_to_world():
	GameManager.world_day += 1
	var scene = load("res://scenes/world/world_map.tscn")
	get_tree().change_scene_to_packed(scene)
