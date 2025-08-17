extends Control

""" When hooking up the save functionality, when a save is detected in the 
	proper slot, then change the button names to "Save Slot X" where X is the 
	number of the slot. 
	i.e. have $SaveFile1 = Save Slot 1 when a save exists
"""

var confirmStart = {1: false, 2: false, 3: false}
var confirmDelete = {1: false, 2: false, 3: false}

func _ready() -> void:
	updateButtons()

## updates save slot buttons to show their current state 
func updateButtons() -> void:
	for saveSlot in range(1, 4):
		var button = get_node("SaveFile" + str(saveSlot))
		get_node("DeleteFile" + str(saveSlot)).text = ""
		
		if SaveManager.saveExists(saveSlot):
			button.text = "Save " + str(saveSlot) + ": " + SaveManager.getSlotDisplay(saveSlot)
		else:
			button.text = "Save " + str(saveSlot) + ": Empty"

##
func _slotClicked(saveSlot: int) -> void:
	var button = get_node("SaveFile" + str(saveSlot))
	if not confirmStart[saveSlot]:
		$VoiceSans.play()
		_resetConfirms()
		updateButtons()
		confirmStart[saveSlot] = true
		if SaveManager.saveExists(saveSlot):
			button.text = "Load Game?"
		else:
			button.text = "New Game?"
	else:
		$VoiceSans.play()
		SaveManager.currentSlot = saveSlot
		get_tree().change_scene_to_file("res://scenes/cool_trivia_maze.tscn")

##
func _deleteFile(saveSlot: int) -> void:
	var button = get_node("DeleteFile" + str(saveSlot))
	if not confirmDelete[saveSlot]:
		$VoiceSans.play()
		_resetConfirms()
		updateButtons()
		confirmDelete[saveSlot] = true
		button.text = "Delete \n Save " + str(saveSlot) + "?"
	else:
		$VoiceSans.play()
		SaveManager.deleteSave(saveSlot)
		updateButtons()
		confirmDelete[saveSlot] = false

##
func _resetConfirms() -> void:
	for saveSlot in range(1, 4):
		confirmStart[saveSlot] = false
		confirmDelete[saveSlot] = false

func _on_save_file_1_button_down() -> void:
	_slotClicked(1)

func _on_save_file_2_button_down() -> void:
	_slotClicked(2)

func _on_save_file_3_button_down() -> void:
	_slotClicked(3)

func _on_delete_file_1_button_down() -> void:
	_deleteFile(1)

func _on_delete_file_2_button_down() -> void:
	_deleteFile(2)

func _on_delete_file_3_button_down() -> void:
	_deleteFile(3)

func _on_instructions_button_down() -> void:
	$VoiceSans.play()
	get_tree().change_scene_to_file("res://scenes/instructions.tscn")
