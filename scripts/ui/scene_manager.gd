extends Node

func goto_main_menu():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func goto_nation_select():
	get_tree().change_scene_to_file("res://scenes/ui/nation_select.tscn")

func goto_commander_create():
	get_tree().change_scene_to_file("res://scenes/ui/commander_create.tscn")

func goto_deployment():
	get_tree().change_scene_to_file("res://scenes/ui/deployment.tscn")

func goto_battle():
	get_tree().change_scene_to_file("res://scenes/battle/main_scene.tscn")

func goto_victory():
	get_tree().change_scene_to_file("res://scenes/ui/victory.tscn")

func goto_world():
	get_tree().change_scene_to_file("res://scenes/world/world_map.tscn")

func quit_game():
	get_tree().quit()
