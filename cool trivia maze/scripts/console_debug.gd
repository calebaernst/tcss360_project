extends Node

@onready var maze = get_parent().get_node("Maze")

## show keybinds for debug inputs
func debugPrints():
	print("=== DEBUG CONTROLS ENABLED ===")
	print("Press ; to UNLOCK all doors in current room")
	print("Press ' to LOCK all doors in current room") 
	print("Press / to BREAK all doors in current room") 
	print("Press SPACE to show current door lock states")
	print("Press 1 to SAVE to SLOT 1")
	print("Press 2 to SAVE to SLOT 2")
	print("Press 3 to SAVE to SLOT 3")
	print("Press 4 to LOAD from SLOT 1")
	print("Press 5 to LOAD from SLOT 2")
	print("Press 6 to LOAD from SLOT 3")
	print("Press 7 to DELETE SLOT 1")
	print("Press 8 to DELETE SLOT 2")
	print("Press 9 to DELETE SLOT 3")
	print("===================")

## Takes input from user
func _input(event):
	if not maze.debugInputs or maze.currentQuestion:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SEMICOLON:
				unlockAllDoors()
			KEY_APOSTROPHE:
				lockAllDoors()
			KEY_SLASH:
				breakAllDoors()
			KEY_SPACE:
				printDoorStates()
				
				
			KEY_1:
				SaveManager.saveGame(1)
			KEY_2:
				SaveManager.saveGame(2)
			KEY_3:
				SaveManager.saveGame(3)
			KEY_4:
				SaveManager.loadGame(1)
			KEY_5:
				SaveManager.loadGame(2)
			KEY_6:
				SaveManager.loadGame(3)
			KEY_7:
				SaveManager.deleteSave(1)
			KEY_8:
				SaveManager.deleteSave(2)
			KEY_9:
				SaveManager.deleteSave(3)

# unlocks all doors in the current room
func unlockAllDoors() -> void:
	if not maze or maze.mazeRooms.is_empty():
		return
	var room = maze.mazeRooms[maze.currentRoomX][maze.currentRoomY]
	for doorName in maze.cardinalDoors:
		room[doorName]["locked"] = false
		room[doorName]["interactable"] = false
	print("ALL DOORS UNLOCKED in room ", maze.currentRoomCoords())
	debugRoutine()

## locks all doors in the current room
func lockAllDoors() -> void:
	if not maze or maze.mazeRooms.is_empty():
		return
	var room = maze.mazeRooms[maze.currentRoomX][maze.currentRoomY]
	for doorName in maze.cardinalDoors:
		room[doorName]["locked"] = true
		room[doorName]["interactable"] = true
	print("ALL DOORS LOCKED in room ", maze.currentRoomCoords())
	debugRoutine()

func breakAllDoors() -> void:
	if not maze or maze.mazeRooms.is_empty():
		return
	var room = maze.mazeRooms[maze.currentRoomX][maze.currentRoomY]
	for doorName in maze.cardinalDoors:
		room[doorName]["locked"] = true
		room[doorName]["interactable"] = false
	print("ALL DOORS BROKEN in room ", maze.currentRoomCoords())
	debugRoutine()

func debugRoutine() -> void:
	maze.updateDoorVisuals()
	maze.updateWinCon()
	printDoorStates()

## print to the console the state of doors in the current room
func printDoorStates() -> void:
	if not maze or maze.mazeRooms.is_empty():
		return
	print("=== ROOM ", maze.currentRoomCoords(), " DOOR STATES ===")
	print(maze.getDoorStates())
	print("===================")
