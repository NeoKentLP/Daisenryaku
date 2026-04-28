extends CanvasLayer

var info_panel: Panel
var unit_name_label: Label
var hp_label: Label
var action_menu: VBoxContainer
var turn_label: Label
var cp_label: Label
var phase_label: Label
var message_label: Label
var turn_announce: Label
var end_turn_button: Button

var _msg_tween: Tween

func _ready():
	GameManager.ui_manager = self
	GameManager.phase_changed.connect(_on_phase_changed)
	GameManager.command_points_changed.connect(_on_cp_changed)
	GameManager.turn_ended.connect(_on_turn_ended)
	await get_tree().process_frame
	_build_ui()

func _build_ui():
	var screen = get_viewport().size

	info_panel = Panel.new()
	info_panel.position = Vector2(10, 10)
	info_panel.size = Vector2(180, 80)
	info_panel.hide()
	add_child(info_panel)

	unit_name_label = Label.new()
	unit_name_label.position = Vector2(10, 10)
	unit_name_label.size = Vector2(160, 20)
	info_panel.add_child(unit_name_label)

	hp_label = Label.new()
	hp_label.position = Vector2(10, 35)
	hp_label.size = Vector2(160, 20)
	info_panel.add_child(hp_label)

	action_menu = VBoxContainer.new()
	action_menu.position = Vector2(200, 10)
	action_menu.hide()
	add_child(action_menu)

	var wait_btn = Button.new()
	wait_btn.text = "待机"
	wait_btn.pressed.connect(_on_wait_pressed)
	action_menu.add_child(wait_btn)

	turn_label = Label.new()
	turn_label.position = Vector2(10, screen.y - 80)
	turn_label.text = "回合 1"
	turn_label.add_theme_font_size_override("font_size", 16)
	add_child(turn_label)

	cp_label = Label.new()
	cp_label.position = Vector2(10, screen.y - 55)
	cp_label.text = "指挥点: 100"
	cp_label.add_theme_font_size_override("font_size", 16)
	add_child(cp_label)

	phase_label = Label.new()
	phase_label.position = Vector2(screen.x - 150, 10)
	phase_label.text = ""
	phase_label.add_theme_font_size_override("font_size", 18)
	add_child(phase_label)

	message_label = Label.new()
	message_label.position = Vector2(screen.x / 2 - 200, screen.y - 40)
	message_label.size = Vector2(400, 30)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 16)
	message_label.hide()
	add_child(message_label)

	turn_announce = Label.new()
	turn_announce.position = Vector2(screen.x / 2 - 200, screen.y / 2 - 40)
	turn_announce.size = Vector2(400, 80)
	turn_announce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_announce.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_announce.add_theme_font_size_override("font_size", 48)
	turn_announce.add_theme_color_override("font_color", Color(1, 1, 1))
	turn_announce.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	turn_announce.add_theme_constant_override("outline_size", 4)
	turn_announce.modulate = Color(1, 1, 1, 0)
	turn_announce.hide()
	add_child(turn_announce)

	end_turn_button = Button.new()
	end_turn_button.position = Vector2(screen.x - 130, screen.y - 40)
	end_turn_button.text = "结束回合"
	end_turn_button.pressed.connect(_on_end_turn)
	add_child(end_turn_button)

func show_unit_info(unit):
	if not unit or not unit.is_alive:
		info_panel.hide()
		return
	info_panel.show()
	unit_name_label.text = unit.unit_data.display_name
	hp_label.text = "HP: %d/%d" % [unit.hp, unit.max_hp]

func show_action_menu():
	action_menu.show()

func hide_action_menu():
	action_menu.hide()

func _on_wait_pressed():
	var ctrl = _find_main_controller()
	if ctrl and ctrl.has_method("_on_unit_wait"):
		ctrl._on_unit_wait()
	hide_action_menu()

func show_message(text: String):
	if not message_label:
		return
	message_label.text = text
	message_label.show()
	await get_tree().create_timer(2.0).timeout
	if message_label:
		message_label.hide()

func show_turn_announce(text: String):
	if not turn_announce:
		return
	turn_announce.text = text
	turn_announce.modulate = Color(1, 1, 1, 0)
	turn_announce.show()
	var tw = create_tween()
	tw.tween_property(turn_announce, "modulate", Color(1, 1, 1, 1), 0.3)
	tw.tween_interval(1.0)
	tw.tween_property(turn_announce, "modulate", Color(1, 1, 1, 0), 0.5)
	await tw.finished
	turn_announce.hide()

func show_victory(text: String):
	if not turn_announce:
		return
	turn_announce.text = text
	turn_announce.modulate = Color(1, 1, 1, 0)
	turn_announce.show()
	var tw = create_tween()
	tw.tween_property(turn_announce, "modulate", Color(1, 1, 1, 1), 1.0)
	tw.tween_interval(3.0)
	tw.tween_property(turn_announce, "modulate", Color(1, 1, 1, 0), 1.5)
	await tw.finished
	turn_announce.hide()

func _on_end_turn():
	if GameManager.current_phase == 0:
		GameManager.end_player_turn()

func _on_phase_changed(phase: int):
	match phase:
		0:
			phase_label.text = ""
			show_turn_announce("玩家回合")
		1:
			phase_label.text = ""
			show_turn_announce("敌方回合")

func _on_cp_changed(points: int):
	cp_label.text = "指挥点: %d" % points

func _on_turn_ended(turn: int):
	turn_label.text = "回合 %d" % turn

func _find_main_controller():
	var root = get_tree().current_scene
	if root:
		return root
	return null
