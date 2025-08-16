extends Control

""" When hooking up the save functionality, when a save is detected in the 
	proper slot, then change the button names to "Save Slot X" where X is the 
	number of the slot. 
	i.e. have $SaveFile1 = Save Slot 1 when a save exists
"""

func _on_save_file_1_button_down() -> void:
	$VoiceSans.play()
	SaveManager.loadGame(1)

func _on_save_file_2_button_down() -> void:
	$VoiceSans.play()
	SaveManager.loadGame(2)

func _on_save_file_3_button_down() -> void:
	$VoiceSans.play()
	SaveManager.loadGame(3)

func _on_instructions_button_down() -> void:
	$VoiceSans.play()
	get_tree().change_scene_to_file("res://scenes/instructions.tscn")
