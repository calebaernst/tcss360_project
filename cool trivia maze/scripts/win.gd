# Win Script
extends Control

func _on_return_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
