extends Node

@onready var maze = get_parent().get_node("Maze")

# Debug mode messages
func debugPrints():
	print("=== DEBUG CONTROLS ENABLED ===")
	print("Press U to UNLOCK all doors in current room")
	print("Press L to LOCK all doors in current room") 
	print("Press SPACE to show current door lock states")
	print("===================")

# Takes input from user
func _input(event):
	if not maze.debugInputs:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_U:
				unlockAllDoors()
			KEY_L:
				lockAllDoors()
			KEY_SPACE:
				showDoorStates()

# unlocks all doors in map
func unlockAllDoors():
	if not maze or maze.mazeRooms.is_empty():
		return
	var room = maze.mazeRooms[maze.currentRoomX][maze.currentRoomY]
	for doorName in room["doorLocks"].keys():
		room["doorLocks"][doorName] = false
	print("ALL DOORS UNLOCKED in room (", maze.currentRoomX, ",", maze.currentRoomY, ")")
	maze.updateDoorVisuals()
	showDoorStates()

# 
func lockAllDoors():
	if not maze or maze.mazeRooms.is_empty():
		return
	var room = maze.mazeRooms[maze.currentRoomX][maze.currentRoomY]
	for doorName in room["doorLocks"].keys():
		room["doorLocks"][doorName] = true
	print("ALL DOORS LOCKED in room (", maze.currentRoomX, ",", maze.currentRoomY, ")")
	maze.updateDoorVisuals()
	showDoorStates()

# 
func showDoorStates():
	if not maze or maze.mazeRooms.is_empty():
		return
	var room = maze.mazeRooms[maze.currentRoomX][maze.currentRoomY]
	print("=== ROOM (", maze.currentRoomX, ",", maze.currentRoomY, ") DOOR STATES ===")
	print(maze.getDoorStates())
	print("===================")
