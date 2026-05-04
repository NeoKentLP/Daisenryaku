extends CanvasLayer

var _panel: Panel
var _title_label: Label
var _info_label: Label
var _action_vbox: VBoxContainer
var _current_hub = null
var _wd = preload("res://scripts/world/world_data.gd")

func _ready():
	_build_ui()
	hide()

func _build_ui():
	_panel = Panel.new()
	_panel.position = Vector2(100, 60)
	_panel.size = Vector2(400, 500)
	_panel.add_theme_stylebox_override("panel", _make_bg())
	add_child(_panel)

	_title_label = Label.new()
	_title_label.position = Vector2(20, 16)
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_panel.add_child(_title_label)

	_info_label = Label.new()
	_info_label.position = Vector2(20, 50)
	_info_label.size = Vector2(360, 40)
	_info_label.add_theme_font_size_override("font_size", 12)
	_info_label.add_theme_color_override("font_color", Color(0.73, 0.73, 0.73))
	_panel.add_child(_info_label)

	_action_vbox = VBoxContainer.new()
	_action_vbox.position = Vector2(20, 100)
	_action_vbox.size = Vector2(360, 300)
	_action_vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(_action_vbox)

	var close_btn = Button.new()
	close_btn.position = Vector2(300, 450)
	close_btn.size = Vector2(80, 36)
	close_btn.text = "离开"
	close_btn.pressed.connect(_on_close)
	_panel.add_child(close_btn)

func _make_bg():
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.039, 0.039, 0.098, 0.97)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(1, 1, 1, 0.2))
	return sb

func open(hub):
	_current_hub = hub
	_title_label.text = hub["name"]
	_info_label.text = "类型: " + _wd.get_hub_display(hub["type"])
	_build_actions(hub)
	show()

func _build_actions(hub):
	for c in _action_vbox.get_children():
		c.queue_free()

	match hub["type"]:
		"hq", "city":
			_add_action("休息", "恢复全队HP", _on_rest)
			_add_action("补充弹药", "消耗补给池补满弹药", _on_resupply)
		"factory":
			_add_action("补充弹药", "消耗补给池补满弹药", _on_resupply)
			_add_action("修理载具", "恢复载具HP", _on_repair)
		"village":
			_add_action("休息", "恢复全队部分HP", _on_rest)
			_add_action("招募", "用货币招募新兵", _on_recruit)
		"forest":
			_add_action("侦查", "查看周围情报", _on_scout)
		"mountain":
			_add_action("侦查", "查看周围情报", _on_scout)

	_add_action("继续行军", "离开据点", _on_close)

func _add_action(text: String, desc: String, callback: Callable):
	var btn = Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size.y = 36
	btn.text = text + "\n  " + desc
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", Color(0.87, 0.87, 0.87))
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.05)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(1, 1, 1, 0.1))
	sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", sb)
	btn.pressed.connect(callback)
	_action_vbox.add_child(btn)

func _on_rest():
	for sq in GameManager.player_squads:
		if sq.is_alive:
			for m in sq.members:
				if m.is_alive:
					var heal = ceili(m.max_hp * 0.5)
					m.hp = mini(m.max_hp, m.hp + heal)
	var wc = get_node_or_null("/root/World")
	if wc: wc._info_label.text = "全军休息完毕"
	GameManager.world_day += 1
	hide()

func _on_resupply():
	for sq in GameManager.player_squads:
		if sq.is_alive:
			sq.resupply()
	var wc = get_node_or_null("/root/World")
	if wc: wc._info_label.text = "弹药补给完毕"
	hide()

func _on_repair():
	for sq in GameManager.player_squads:
		if sq.is_alive:
			for m in sq.members:
				if m.is_alive and m.member_type == "vehicle":
					m.hp = m.max_hp
	var wc = get_node_or_null("/root/World")
	if wc: wc._info_label.text = "载具修理完毕"
	hide()

func _on_recruit():
	if GameManager.spend_command_points(50):
		var wd = preload("res://scripts/core/weapon_data.gd")
		var ms = preload("res://scripts/core/member.gd")
		var ss = load("res://scripts/core/squad.gd")
		var sq = ss.new()
		var m = []
		for i in range(4):
			m.append(ms.new("新兵", "infantry", 8, 50, wd.rifle()))
		m.append(ms.new("机枪手", "infantry", 10, 45, wd.mg()))
		sq.setup("infantry", 0, Vector2i(0, 0), m)
		sq.squad_name = "新编班"
		GameManager.player_squads.append(sq)
		var wc = get_node_or_null("/root/World")
		if wc: wc._info_label.text = "新兵加入!"
		GameManager.world_day += 1
		hide()

func _on_scout():
	var wc = get_node_or_null("/root/World")
	if wc:
		var nearby = []
		for e in _wd.create_default_edges():
			if e["from"] == _current_hub["id"] or e["to"] == _current_hub["id"]:
				var nid = e["to"] if e["from"] == _current_hub["id"] else e["from"]
				var nd = _find_world_node(nid)
				if nd: nearby.append(nd["name"])
		var msg = "周围据点: " + (", ".join(nearby) if nearby.size() > 0 else "无")
		wc._info_label.text = msg
	GameManager.world_day += 1
	hide()

func _find_world_node(id: String):
	var wc = get_node_or_null("/root/World")
	if wc:
		for n in wc.nodes:
			if n["id"] == id: return n
	return null

func _on_close():
	hide()
