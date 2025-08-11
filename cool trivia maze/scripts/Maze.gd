extends Node2D
class_name Maze

@export var debugInputs: bool = true
@onready var debugConsole = get_parent().get_node("DebugInputs")

# prepare game assets
var roomScene: PackedScene = preload("res://scenes/RoomScene.tscn")
@export var player: NodePath
@onready var playerNode = get_node(player)
@onready var BGM = $BGMPlayer

# maze dimensions/coordinates/navigation variables
@export var mazeWidth: int = 9
@export var mazeHeight: int = 9
var currentRoomInstance: Node = null
var mazeRooms: Array = []
var currentRoomX: int
var currentRoomY: int
var exitX: int
var exitY: int
const cardinalDoors = ["NorthDoor", "SouthDoor", "EastDoor", "WestDoor"]
var doorsOffCooldown: bool = true

# On start
func _ready() -> void:
	exitX = mazeWidth / 2
	exitY = mazeHeight / 2
	
	_prepareMazeArray()
	_setStartingRoom()
	loadRoom()
	
	playerNode.z_index = 1000 # fix the player to always be visible
	BGM.play() # play BGM
	BGM.finished.connect(_loopBGM) # set BGM to loop
	
	# debug inputs can be enabled/disabled from the inspector menu for the "Maze" node
	if debugInputs:
		debugConsole.debugPrints()

## just repeats the BGM when it finishes playing (because there is no inherent function to do this)
func _loopBGM() -> void:
	BGM.play()

# gets the current room of the player
func getCurrentRoom() -> Dictionary:
	return mazeRooms[currentRoomX][currentRoomY]

func currentRoomCoords() -> String:
	return "(" + str(currentRoomX) + "," + str(currentRoomY) + ")"

## generate maze rooms and store their data in an array
func _prepareMazeArray() -> void:
	if not mazeRooms:
		for x in range(mazeWidth):
			var column: Array = [] # reinitialize the column array on each loop to prevent cells from pointing at the same array
			for y in range(mazeHeight):
				var thisRoom = _prepareRoom(x,y)
				print("prepared room at ", x, ",", y)
				column.append(thisRoom)
			mazeRooms.append(column)
		
		# link adjacent doors so that they always share the same state (point to the same reference)
		for x in range(mazeWidth):
			for y in range(mazeHeight):
				var room = mazeRooms[x][y]
				
				# link north door with south door of room above (vertical link)
				if y < mazeHeight - 1:
					var northRoom = mazeRooms[x][y + 1]
					var sharedDoor = room["NorthDoor"]
					northRoom["SouthDoor"] = sharedDoor
				
				# link east door with west door of room to the right (horizontal link)
				if x < mazeWidth - 1:
					var eastRoom = mazeRooms[x + 1][y]
					var sharedDoor = room["EastDoor"]
					eastRoom["WestDoor"] = sharedDoor

## generates data for a single room (used exclusively in conjunction with prepareMazeArray)
func _prepareRoom(x: int, y: int) -> Dictionary:
	# choose a layout for this room at random
	var chosenLayout = randi_range(1, 4) # the second number should be the number of room layouts available 
	
	var room = {
		"x": x, # X coordinate
		"y": y, # Y coordinate
		
		"chosenLayout": chosenLayout, # the layout of this room
		
		"NorthDoor": _prepareDoor("North", x, y),
		"SouthDoor": _prepareDoor("South", x, y),
		"EastDoor": _prepareDoor("East", x, y),
		"WestDoor": _prepareDoor("West", x, y),
		}
	return room

## prepares a door with values which determine its state
func _prepareDoor(direction: String, x: int, y: int) -> Dictionary:
	var exists
	match direction:
		"North":
			exists = y < mazeHeight - 1
		"South":
			exists = y > 0
		"East":
			exists = x < mazeWidth - 1
		"West":
			exists = x > 0
		_:
			exists = false
			push_error("Invalid door direction designated")
	
	var newDoor = {
		"exists": exists,
		"interactable": true, 
		"locked": true,
		"question": QuestionFactory.getRandomQuestion()
		}
	return newDoor

## start the player in a random corner and unlock the valid doors in that room 
func _setStartingRoom() -> void: 
	match randi_range(1, 4):
		1:
			currentRoomX = int(0)
			currentRoomY = int(0)
		2:
			currentRoomX = int(mazeWidth - 1)
			currentRoomY = int(0)
		3:
			currentRoomX = int(0)
			currentRoomY = int(mazeHeight - 1)
		4:
			currentRoomX = int(mazeWidth - 1)
			currentRoomY = int(mazeHeight - 1)
	
	# Unlock doors in starting room
	var startingRoom = mazeRooms[currentRoomX][currentRoomY]
	for doorName in cardinalDoors:
		startingRoom[doorName]["locked"] = false

## load the current/new room
func loadRoom() -> void:
	# clear previously loaded room from memory
	if currentRoomInstance:
		currentRoomInstance.queue_free()
	# new room instance
	currentRoomInstance = roomScene.instantiate()
	add_child(currentRoomInstance)
	
	var room = getCurrentRoom()
	var chosenRoomLayout = room["chosenLayout"]
	var roomLayouts = currentRoomInstance.get_node("RoomLayouts")
	# this works by setting the selected layout to visible and all others to invisible
	for child in roomLayouts.get_children():
		child.visible = false
	var chosenRoom = roomLayouts.get_node("Room" + str(chosenRoomLayout))
	chosenRoom.visible = true
	
	# let doors detect the player
	var currentRoomDoors = currentRoomInstance.get_node("Doors")
	for doorName in cardinalDoors:
		var thisDoor = currentRoomDoors.get_node(doorName)
		thisDoor.connect("body_entered", Callable(self, "doorTouched").bind(doorName))
	
	updateDoorVisuals()
	updateWinCon()
	print("Room Coordinates: ", currentRoomCoords())

## update the door visuals to reflect their internal state
func updateDoorVisuals() -> void:
	var room = getCurrentRoom()
	var doorStates = getDoorStates()
	var currentRoomDoors = currentRoomInstance.get_node("Doors")
	
	for doorName in cardinalDoors:
		var thisDoor = currentRoomDoors.get_node(doorName)
		var doorVisual = thisDoor.get_node("DoorVisual")
		
		match doorStates[doorName]:
			"WALL":
				thisDoor.visible = false
			"BROKEN":
				thisDoor.visible = true
				doorVisual.texture = preload("res://assets/CTM_Door3.png")
			"LOCKED":
				thisDoor.visible = true
				doorVisual.texture = preload("res://assets/CTM_Door1.png")
			"UNLOCKED":
				thisDoor.visible = true
				doorVisual.texture = preload("res://assets/CTM_Door2.png")

## updates the status of the exit point and checks whether or not the player has lost
func updateWinCon():
	var exitPoint = currentRoomInstance.get_node("ExitPoint")
	
	if currentRoomX != exitX or currentRoomY != exitY:
		exitPoint.visible = false
		exitPoint.get_node("PlayerDetector").set_deferred("monitoring", false)
	else:
		if not exitPoint.is_connected("body_entered", Callable(self, "victory")): # prevent duplicate signal (similar to pingpong effect)
			exitPoint.connect("body_entered", Callable(self, "victory"))
		exitPoint.visible = true
		exitPoint.get_node("PlayerDetector").set_deferred("monitoring", true)

## called only when the player reaches the exit
func victory(body: Node):
	if body == playerNode:
		print("you have reached the exit (congrats)")

## creates a simple dictionary of the door states in the current room, based on the exists/interactable/locked values
## use doorstates[doorName] to get the state of a specific door
func getDoorStates() -> Dictionary:
	var room = getCurrentRoom()
	var doorStates = {}
	
	for doorName in cardinalDoors:
		var door = room[doorName]
		if not door["exists"]:
			doorStates[doorName] = "WALL"
		elif not door["interactable"] and door["locked"]:
			doorStates[doorName] = "BROKEN"
		elif door["locked"]:
			doorStates[doorName] = "LOCKED"
		else:
			doorStates[doorName] = "UNLOCKED"
	
	return doorStates

## Door interaction - test version with lots of debug
func doorTouched(body: Node, doorName: String) -> void:
	# do nothing if the touching object is not the player
	# also prevent pingpong effect
	if body != playerNode or not doorsOffCooldown:
		return
	
	var room = getCurrentRoom()
	var door = room[doorName]
	print(door["question"]) # TODO: remove this once question menu is implemented
	
	# check if the target direction goes out of bounds, and deny movement if it is
	var canMove = door["exists"]
	if canMove:
		# check if the door is locked
		var isLocked = door["locked"]
		if isLocked:
			print(">>> BLOCKED! Door ", doorName, currentRoomCoords(), " is LOCKED.")
		else:
			print(">>> SUCCESS! ", doorName, currentRoomCoords(), " is UNLOCKED. Going through door...")
			doorsOffCooldown = false
			call_deferred("moveRooms", doorName) # used to be moveRooms(doorName) but godot doesn't like that (functions effectively the same either way)
			get_tree().create_timer(0.25).timeout.connect(_enableDoors)
	else:
		print(">>> Can't move - at maze boundary!")

# just resets the door cooldown
func _enableDoors() -> void:
	doorsOffCooldown = true

## move the player to another room when they go through a door
func moveRooms(door: String) -> void:
	var enteringFrom = ""
	match door:
		"NorthDoor":
			currentRoomY += 1
			enteringFrom = "FromSouth"
		"SouthDoor":
			currentRoomY -= 1
			enteringFrom = "FromNorth"
		"EastDoor":
			currentRoomX += 1
			enteringFrom = "FromWest"
		"WestDoor":
			currentRoomX -= 1
			enteringFrom = "FromEast"
	
	loadRoom()
	
	var markers = currentRoomInstance.get_node("EntryPoint")
	var entryPoint = markers.get_node(enteringFrom)
	playerNode.global_position = entryPoint.global_position
