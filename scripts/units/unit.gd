extends Node2D

@export var unit_data_id: String = "infantry"
@export var team: int = 0
@export var hex_coord: Vector2i = Vector2i.ZERO

var unit_data
var hp: int = 10
var max_hp: int = 10
var has_acted: bool = false
var is_alive: bool = true

var _sprite: Polygon2D
var _label: Label
var _done_label: Label

func _ready():
	var db = GameManager.UNIT_DB
	unit_data = db.get(unit_data_id, db["infantry"])
	if not unit_data:
		unit_data = db["infantry"]
	max_hp = unit_data.max_hp
	hp = max_hp
	_create_visual()
	_update_position()

func _create_visual():
	_sprite = Polygon2D.new()
	_sprite.polygon = HexUtil.hex_corners(Vector2.ZERO, 24)
	_sprite.color = unit_data.color
	_sprite.z_index = 1
	add_child(_sprite)

	_label = Label.new()
	_label.text = unit_data.display_name + "\nHP:" + str(hp)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 9)
	_label.size = Vector2(56, 48)
	_label.position = Vector2(-28, -24)
	_label.z_index = 3
	add_child(_label)

	_done_label = Label.new()
	_done_label.text = "E"
	_done_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_done_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_done_label.add_theme_font_size_override("font_size", 14)
	_done_label.add_theme_color_override("font_color", Color(1, 1, 0))
	_done_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_done_label.add_theme_constant_override("outline_size", 2)
	_done_label.size = Vector2(20, 20)
	_done_label.position = Vector2(14, -24)
	_done_label.z_index = 4
	_done_label.hide()
	add_child(_done_label)

	_update_visual()

func update_visual():
	_update_visual()

func _update_visual():
	if _sprite:
		var col = unit_data.color
		if team == 0:
			_sprite.color = Color(col.r, col.g, col.b, 1.0)
		else:
			_sprite.color = Color(col.r * 0.5, col.g * 0.2, col.b * 0.2, 1.0)
	if _label:
		_label.text = unit_data.display_name + "\nHP:" + str(hp) + "/" + str(max_hp)
	if _done_label:
		_done_label.visible = has_acted

func _update_position():
	var map_node = GameManager.hex_map
	if map_node:
		position = map_node.hex_to_pixel(hex_coord)

func move_to(new_hex: Vector2i):
	hex_coord = new_hex
	_update_position()

func take_damage(amount: int) -> int:
	hp = max(0, hp - amount)
	_update_visual()
	if hp <= 0:
		is_alive = false
		_die()
	return hp

func _die():
	GameManager.unregister_unit(self)
	queue_free()

func can_attack(target):
	if not target or not target.is_alive:
		return false
	if target.team == team:
		return false
	if has_acted:
		return false
	var dist = HexUtil.hex_distance(hex_coord, target.hex_coord)
	return dist >= 1 and dist <= unit_data.attack_range

func get_move_range() -> int:
	if has_acted:
		return 0
	return unit_data.move_range

func get_attack_range() -> int:
	return unit_data.attack_range
