extends CanvasLayer

var nations = []
var current_index: int = 0

@onready var title = %Title
@onready var step_label = %StepLabel
@onready var desc = %Desc
@onready var flag_bar = %FlagBar
@onready var name_cn = %NameCN
@onready var name_en = %NameEN
@onready var nation_desc = %NationDesc
@onready var forces = %Forces
@onready var enemy_label = %EnemyLabel
@onready var prev_btn = %PrevBtn
@onready var next_btn = %NextBtn
@onready var dot0 = %Dot0
@onready var dot1 = %Dot1
@onready var back_btn = %BackBtn
@onready var confirm_btn = %ConfirmBtn

func _ready():
	_init_nations()
	_connect_signals()
	_show_nation(0)

func _init_nations():
	var loader = preload("res://scripts/core/unit_loader.gd").new()
	loader.ensure_loaded()

	var nations_data = [
		{
			"id": "germany",
			"name": "德国",
			"name_en": "Germany",
			"desc": "精锐的装甲部队与训练有素的步兵，以闪电战战术闻名于世。",
			"enemy": "soviet",
			"color": Color(0.4, 0.4, 0.4, 1),
			"unit_ids": ["ger_inf_sq39", "ger_inf_sq39", "ger_sdkfz221", "ger_mortar81"],
		},
		{
			"id": "soviet",
			"name": "苏联",
			"name_en": "Soviet Union",
			"desc": "广袤的国土与坚强的意志，钢铁洪流将碾碎一切敌人。",
			"enemy": "germany",
			"color": Color(0.6, 0.2, 0.1, 1),
			"unit_ids": ["sov_inf_sq39", "sov_inf_sq39", "sov_ba20", "sov_pm37"],
		},
	]

	for nd in nations_data:
		var unit_lines = []
		var seen = {}
		for uid in nd.unit_ids:
			var u = loader.get_unit(uid)
			if u:
				var n = u.get("name", uid)
				seen[n] = seen.get(n, 0) + 1
		for name in seen:
			var cnt = seen[name]
			if cnt > 1:
				unit_lines.append("    " + name + " ×" + str(cnt))
			else:
				unit_lines.append("    " + name)
		nd.forces = "\n".join(unit_lines)
		nd.enemy_name = "苏联" if nd.enemy == "soviet" else "德国"
		nations.append(nd)

func _connect_signals():
	prev_btn.pressed.connect(_on_prev)
	next_btn.pressed.connect(_on_next)
	back_btn.pressed.connect(_on_back)
	confirm_btn.pressed.connect(_on_confirm)

func _show_nation(idx: int):
	var nat = nations[idx]
	name_cn.text = nat.name
	name_en.text = nat.name_en
	nation_desc.text = nat.desc
	forces.text = nat.forces
	enemy_label.text = "首战敌军: " + nat.enemy_name
	flag_bar.color = nat.color
	desc.text = "选择初始部队所属国家，决定初始编制及首战敌军。"

	var total = nations.size()
	step_label.text = "第" + str(idx + 1) + "步 / 共" + str(total) + "步"

	prev_btn.disabled = idx == 0
	next_btn.disabled = idx == total - 1

	dot0.color = Color(0.47, 0.67, 1.0, 1) if idx == 0 else Color(1, 1, 1, 0.1)
	dot1.color = Color(0.47, 0.67, 1.0, 1) if idx == 1 else Color(1, 1, 1, 0.1)

func _on_prev():
	if current_index > 0:
		current_index -= 1
		_show_nation(current_index)

func _on_next():
	if current_index < nations.size() - 1:
		current_index += 1
		_show_nation(current_index)

func _on_back():
	SceneManager.goto_main_menu()

func _on_confirm():
	var nat = nations[current_index]
	GameManager.selected_nation = nat.id
	SceneManager.goto_commander_create()
