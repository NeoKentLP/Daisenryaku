extends CanvasLayer

@onready var title = %Title
@onready var subtitle = %Subtitle
@onready var continue_btn = %ContinueBtn
@onready var new_game_btn = %NewGameBtn
@onready var load_btn = %LoadBtn
@onready var settings_btn = %SettingsBtn
@onready var quit_btn = %QuitBtn
@onready var version = %Version

func _ready():
	subtitle.add_theme_constant_override("letter_spacing", 4)
	_apply_bold()
	_connect_signals()

func _bold_font():
	var f = SystemFont.new()
	f.font_weight = 700
	return f

func _apply_bold():
	var bold = _bold_font()
	title.add_theme_font_override("font", bold)
	for btn in [continue_btn, new_game_btn, settings_btn, quit_btn]:
		btn.get_node("LabelCN").add_theme_font_override("font", bold)

func _connect_signals():
	continue_btn.pressed.connect(_on_continue)
	new_game_btn.pressed.connect(_on_new_game)
	load_btn.pressed.connect(_on_load)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)

func _on_new_game():
	SceneManager.goto_nation_select()

func _on_continue():
	pass

func _on_load():
	pass

func _on_settings():
	pass

func _on_quit():
	SceneManager.quit_game()
