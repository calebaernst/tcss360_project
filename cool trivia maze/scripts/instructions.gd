## Instructions Scene
extends Control

## Goes back to the save select screen
func _on_back_pressed() -> void:
	$VoiceSans.play()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://scenes/save_select.tscn")
