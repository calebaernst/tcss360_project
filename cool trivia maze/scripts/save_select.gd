extends Control
class_name MenuScreen

""" When hooking up the save functionality, when a save is detected in the 
	proper slot, then change the button names to "Save Slot X" where X is the 
	number of the slot. 
	i.e. have $SaveFile1 = Save Slot 1 when a save exists
"""

var inGame = false
var confirmStart = {1: false, 2: false, 3: false}
var confirmDelete = {1: false, 2: false, 3: false}
var confirmReturn = false
var confirmQuit = false

func _ready() -> void:
	inGame = SaveManager.theMaze != null
	updateButtons()

## updates save slot buttons to show their current state 
func updateButtons() -> void:
	for saveSlot in range(1, 4):
		var slotButton = get_node("Slot" + str(saveSlot) + "/SaveFile" + str(saveSlot))
		var deleteButton = get_node("Slot" + str(saveSlot) + "/DeleteFile" + str(saveSlot))
		deleteButton.text = ""
		if SaveManager.saveExists(saveSlot):
			slotButton.text = "Save " + str(saveSlot) + ": " + SaveManager.getSlotDisplay(saveSlot)
		else:
			slotButton.text = "Save " + str(saveSlot) + ": Empty"
	if inGame:
		get_node("Instructions").text = "Return to Main Menu"

## saves/loads a selected file slot, after asking for confirmation
## can only save while in game; can only load while in menu
func _slotClicked(saveSlot: int) -> void:
	var slotButton = get_node("Slot" + str(saveSlot) + "/SaveFile" + str(saveSlot))
	if not confirmStart[saveSlot]:
		$VoiceSans.play()
		_resetConfirms()
		updateButtons()
		confirmStart[saveSlot] = true
		if inGame:
			slotButton.text = "Save Game?"
		elif SaveManager.saveExists(saveSlot):
			slotButton.text = "Load Game?"
		else:
			slotButton.text = "New Game?"
	else:
		$VoiceSans.play()
		await get_tree().create_timer(0.2).timeout
		if inGame:
			SaveManager.saveGame(saveSlot)
			_resetConfirms()
			updateButtons()
		else:
			SaveManager.currentSlot = saveSlot
			get_tree().change_scene_to_file("res://scenes/cool_trivia_maze.tscn")

## deletes a selected save file, after asking for confirmation
func _deleteFile(saveSlot: int) -> void:
	var deleteButton = get_node("Slot" + str(saveSlot) + "/DeleteFile" + str(saveSlot))
	if not confirmDelete[saveSlot]:
		$VoiceSans.play()
		_resetConfirms()
		updateButtons()
		confirmDelete[saveSlot] = true
		deleteButton.text = "Delete \n Save " + str(saveSlot) + "?"
	else:
		$VoiceSans.play()
		SaveManager.deleteSave(saveSlot)
		updateButtons()
		confirmDelete[saveSlot] = false

## resets confirmations for all buttons
func _resetConfirms() -> void:
	for saveSlot in range(1, 4):
		confirmStart[saveSlot] = false
		confirmDelete[saveSlot] = false
	confirmReturn = false
	confirmQuit = false

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
	await get_tree().create_timer(0.2).timeout
	
	if inGame:
		if confirmReturn:
			get_tree().change_scene_to_file("res://scenes/save_select.tscn")
		else:
			$Instructions.text = "Are you sure?"
			confirmReturn = true
	else:
		get_tree().change_scene_to_file("res://scenes/instructions.tscn")

func _on_quit_button_down() -> void:
	$VoiceSans.play()
	if confirmQuit:
			get_tree().quit()
	else: 
		$Quit.text = "Are you sure?"
		confirmQuit = true
