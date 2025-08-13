extends Node

@onready var maze = get_parent().get_node("Maze")

## show keybinds for debug inputs
func debugPrints():
	print("=== DEBUG CONTROLS ENABLED ===")
	print("Press 1 to UNLOCK all doors in current room")
	print("Press 2 to LOCK all doors in current room") 
	print("Press 3 to BREAK all doors in current room") 
	print("Press 4 to show current door lock states")
	print("===================")

## Takes input from user
func _input(event):
	if not maze.debugInputs or maze.currentQuestion:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				unlockAllDoors()
			KEY_2:
				lockAllDoors()
			KEY_3:
				breakAllDoors()
			KEY_4:
				printDoorStates()

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
