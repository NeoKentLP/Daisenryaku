extends CanvasLayer

var victory: bool = true
var stats: Dictionary = {}

func _ready():
	hide()

func open(is_victory: bool, battle_stats: Dictionary):
	victory = is_victory
	stats = battle_stats
	_build_panel()
	show()

func _bold_font():
	var f = SystemFont.new()
	f.font_weight = 700
	return f

func _make_bg() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.039, 0.039, 0.098, 0.97)
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(1, 1, 1, 0.2))
	return sb

func _build_panel():
	var screen = get_viewport().size

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.size = screen
	add_child(overlay)

	var panel = Panel.new()
	panel.position = Vector2(screen.x / 2 - 200, screen.y / 2 - 180)
	panel.size = Vector2(400, 360)
	panel.add_theme_stylebox_override("panel", _make_bg())
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	vbox.size = Vector2(360, 320)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var result = Label.new()
	result.text = "胜利!" if victory else "失败!"
	result.add_theme_font_size_override("font_size", 36)
	result.add_theme_font_override("font", _bold_font())
	result.add_theme_color_override("font_color", Color(0.27, 0.67, 0.53) if victory else Color(0.8, 0.27, 0.27))
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(result)

	var subtitle = Label.new()
	subtitle.text = "己方全灭敌军!" if victory else "己方部队全部损失"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.73, 0.73, 0.73))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	var sep = ColorRect.new()
	sep.color = Color(1, 1, 1, 0.1)
	sep.custom_minimum_size.y = 1
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(sep)

	var stats_title = Label.new()
	stats_title.text = "战斗统计"
	stats_title.add_theme_font_size_override("font_size", 12)
	stats_title.add_theme_color_override("font_color", Color(0.47, 0.67, 1.0))
	vbox.add_child(stats_title)

	var kills = stats.get("kills", 0)
	var remaining = stats.get("remaining", 0)
	var turns = stats.get("turns", 0)

	_make_stat_row(vbox, "消灭敌军", str(kills) + "支部队")
	_make_stat_row(vbox, "存活部队", str(remaining) + "支")
	_make_stat_row(vbox, "所用回合", str(turns) + "回合")

	vbox.add_spacer(true)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var btn = Button.new()
	btn.text = "返回主菜单"
	btn.custom_minimum_size = Vector2(160, 40)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_font_override("font", _bold_font())
	var bsb = StyleBoxFlat.new()
	bsb.bg_color = Color(0.27, 0.67, 0.53, 0.15)
	bsb.set_border_width_all(1)
	bsb.set_border_color(Color(0.27, 0.67, 0.53, 0.3))
	bsb.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", bsb)
	btn.pressed.connect(_on_back_to_menu)
	btn_row.add_child(btn)

func _make_stat_row(parent: VBoxContainer, label: String, value: String):
	var row = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label + ":  "
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.67, 0.67, 0.67))
	row.add_child(lbl)
	var val = Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 11)
	val.add_theme_color_override("font_color", Color(0.93, 0.93, 0.93))
	row.add_child(val)
	parent.add_child(row)

func _on_back_to_menu():
	for c in get_children():
		c.queue_free()
	GameManager.all_squads.clear()
	GameManager.player_squads.clear()
	GameManager.enemy_squads.clear()
	SceneManager.goto_main_menu()
