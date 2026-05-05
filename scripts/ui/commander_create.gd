extends CanvasLayer

var commanders: Array = []
var nation: String = "germany"
var original_names: Dictionary = {}
var has_manual_edit: Dictionary = {}

const CARD_SCENE = preload("res://scenes/ui/commander_card.tscn")

@onready var title = %Title
@onready var subtitle = %Subtitle
@onready var card_box = %CardBox
@onready var back_btn = %BackBtn
@onready var confirm_btn = %ConfirmBtn

func _ready():
	nation = GameManager.selected_nation
	_generate_commanders()
	_connect_signals()
	_build_cards()

func _generate_commanders():
	commanders.clear()
	original_names.clear()
	has_manual_edit.clear()

	for i in range(4):
		var bg_type = "infantry"
		match i:
			0: bg_type = "infantry"
			1: bg_type = "infantry"
			2: bg_type = "vehicle"
			3: bg_type = "artillery"

		var cmd = preload("res://scripts/commander/commander.gd").new(nation, bg_type)

		if i == 0:
			cmd.set_rarity("英雄")
			cmd.random_quality_skills(3)
		else:
			var rarities = ["菜鸟", "预备军官", "老兵", "英雄"]
			var weights = [50, 30, 15, 5]
			var roll = randi() % 100
			var r = "菜鸟"
			var acc = 0
			for j in range(rarities.size()):
				acc += weights[j]
				if roll < acc:
					r = rarities[j]
					break
			cmd.set_rarity(r)
			var qcount = cmd.get_quality_slot_count()
			if qcount > 0:
				cmd.random_quality_skills(qcount)

		commanders.append(cmd)
		original_names[i] = cmd.commander_name

func _connect_signals():
	back_btn.pressed.connect(_on_back)
	confirm_btn.pressed.connect(_on_confirm)

func _bold_font():
	var f = SystemFont.new()
	f.font_weight = 700
	return f

func _clear_cards():
	for c in card_box.get_children():
		c.queue_free()

func _build_cards():
	_clear_cards()
	for i in range(commanders.size()):
		var cmd = commanders[i]
		var card = CARD_SCENE.instantiate()
		card_box.add_child(card)
		_fill_card(card, cmd, i)

func _fill_card(card, cmd, index: int):
	var name_lbl = card.get_node("%NameLabel")
	var rarity = card.get_node("%RarityTag")
	var level = card.get_node("%LevelLabel")
	var desc = card.get_node("%DescLabel")
	var protagonist = card.get_node("%ProtagonistTag")
	var reroll_btn = card.get_node("%RerollBtn")

	name_lbl.text = cmd.commander_name
	name_lbl.add_theme_font_override("font", _bold_font())

	rarity.text = cmd.rarity
	rarity.add_theme_font_override("font", _bold_font())
	rarity.add_theme_color_override("font_color", _rarity_color(cmd.rarity))

	level.text = "Lv" + str(cmd.level)

	protagonist.visible = index == 0

	desc.text = cmd.background_skill + "专长的指挥官"

	reroll_btn.pressed.connect(_on_reroll.bind(index))

	var bg = card.get_node("%Name1")
	var bg_dots = card.get_node("%Dots1")
	bg.text = cmd.background_skill
	bg.add_theme_color_override("font_color", Color(0.31, 0.62, 0.255, 1))
	_set_dots(bg_dots, [true, false, false], Color(0.31, 0.62, 0.255, 1))

	var talent = card.get_node("%Name2")
	var talent_dots = card.get_node("%Dots2")
	talent.text = cmd.talent_skill + " Lv" + str(cmd.talent_level)
	talent.add_theme_color_override("font_color", Color(0.278, 0.357, 0.773, 1))
	_set_dots(talent_dots, [true, true, false], Color(0.278, 0.357, 0.773, 1))

	var qskill_keys = ["%Name3", "%Name4", "%Name5"]
	var qdot_keys = ["%Dots3", "%Dots4", "%Dots5"]
	var qslots = [card.get_node("%Slot3"), card.get_node("%Slot4"), card.get_node("%Slot5")]

	for si in range(qskill_keys.size()):
		var slot = qslots[si]
		var skill_name_lbl = card.get_node(qskill_keys[si])
		var dots = card.get_node(qdot_keys[si])
		if si < cmd.quality_skills.size():
			slot.show()
			skill_name_lbl.text = cmd.quality_skills[si]
			skill_name_lbl.add_theme_color_override("font_color", Color(0.776, 0.541, 0.255, 1))
			_set_dots(dots, [true, false, false], Color(0.776, 0.541, 0.255, 1))
		else:
			slot.hide()

func _set_dots(dot_container, pattern: Array, color: Color):
	var children = dot_container.get_children()
	for i in range(min(children.size(), pattern.size())):
		var dot = children[i]
		dot.color = color
		dot.visible = pattern[i]

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"菜鸟": return Color(0.53, 0.53, 0.53, 1)
		"预备军官": return Color(0.33, 0.8, 0.33, 1)
		"老兵": return Color(0.47, 0.67, 1.0, 1)
		"英雄": return Color(1.0, 0.67, 0.27, 1)
	return Color(0.53, 0.53, 0.53, 1)

func _on_reroll(index: int):
	var bg_types = ["infantry", "infantry", "vehicle", "artillery"]
	var bg_type = bg_types[index]
	var cmd = preload("res://scripts/commander/commander.gd").new(nation, bg_type)

	if index == 0:
		cmd.set_rarity("英雄")
		cmd.random_quality_skills(3)
	else:
		var rarities = ["菜鸟", "预备军官", "老兵", "英雄"]
		var weights = [50, 30, 15, 5]
		var roll = randi() % 100
		var r = "菜鸟"
		var acc = 0
		for j in range(rarities.size()):
			acc += weights[j]
			if roll < acc:
				r = rarities[j]
				break
		cmd.set_rarity(r)
		var qcount = cmd.get_quality_slot_count()
		if qcount > 0:
			cmd.random_quality_skills(qcount)

	if has_manual_edit.get(index, false):
		cmd.commander_name = original_names[index]

	commanders[index] = cmd
	_build_cards()

func _on_rename(index: int):
	var dialog = AcceptDialog.new()
	dialog.title = "修改名称"
	dialog.dialog_text = "输入新名称:"
	dialog.size = Vector2(300, 120)
	add_child(dialog)

	var line_edit = LineEdit.new()
	line_edit.text = commanders[index].commander_name
	line_edit.position = Vector2(20, 50)
	line_edit.size = Vector2(260, 24)
	dialog.add_child(line_edit)

	dialog.confirmed.connect(func():
		var new_name = line_edit.text.strip_edges()
		if new_name != "":
			commanders[index].set_name(new_name)
			original_names[index] = new_name
			has_manual_edit[index] = true
			_build_cards()
	)

	line_edit.grab_focus()
	dialog.popup_centered()

func _on_confirm():
	GameManager.initial_commanders = []
	for cmd in commanders:
		GameManager.initial_commanders.append(cmd)
	SceneManager.goto_deployment()

func _on_back():
	SceneManager.goto_nation_select()
