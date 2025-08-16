extends Control

func _on_back_pressed() -> void:
	$VoiceSans.play()
	get_tree().change_scene_to_file("res://scenes/save_select.tscn")
