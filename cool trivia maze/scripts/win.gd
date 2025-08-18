# Win Script
extends Control

@onready var yayy = $yayy
@onready var fanfare = $fanfare

func _ready() -> void:
	yayy.play()
	fanfare.play()

func _on_return_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
