extends Node

@onready var maze = get_parent().get_node("Maze")

## show keybinds for debug inputs
func debugPrints():
	print("=== DEBUG CONTROLS ENABLED ===")
	print("Press U to UNLOCK all doors in current room")
	print("Press L to LOCK all doors in current room") 
	print("Press B to BREAK all doors in current room") 
	print("Press SPACE to show current door lock states")
	print("===================")

## Takes input from user
func _input(event):
	if not maze.debugInputs:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_U:
				unlockAllDoors()
			KEY_L:
				lockAllDoors()
			KEY_B:
				breakAllDoors()
			KEY_SPACE:
				printDoorStates()

# unlocks all doors in the current room
func unlockAllDoors() -> void:
	if not maze or maze.mazeRooms.is_empty():
		return
	var room = maze.mazeRooms[maze.currentRoomX][maze.currentRoomY]
	for doorName in room["doorLocks"].keys():
		room["doorLocks"][doorName] = false
	print("ALL DOORS UNLOCKED in room ", maze.currentRoomToString())
	debugRoutine()

## locks all doors in the current room
func lockAllDoors() -> void:
	if not maze or maze.mazeRooms.is_empty():
		return
	var room = maze.mazeRooms[maze.currentRoomX][maze.currentRoomY]
	for doorName in room["doorLocks"].keys():
		room["doorLocks"][doorName] = true
	print("ALL DOORS LOCKED in room ", maze.currentRoomToString())
	debugRoutine()

func breakAllDoors() -> void:
	if not maze or maze.mazeRooms.is_empty():
		return
	var room = maze.mazeRooms[maze.currentRoomX][maze.currentRoomY]
	for doorName in room["doorLocks"].keys():
		room["doorLocks"][doorName] = true
		room["doorInteractable"][doorName] = false
	print("ALL DOORS BROKEN in room ", maze.currentRoomToString())
	debugRoutine()

func debugRoutine() -> void:
	maze.updateDoorVisuals()
	maze.updateWinCon()
	printDoorStates()

## print to the console the state of doors in the current room
func printDoorStates() -> void:
	if not maze or maze.mazeRooms.is_empty():
		return
	var room = maze.mazeRooms[maze.currentRoomX][maze.currentRoomY]
	print("=== ROOM ", maze.currentRoomToString(), " DOOR STATES ===")
	print(maze.getDoorStates())
	print("===================")
