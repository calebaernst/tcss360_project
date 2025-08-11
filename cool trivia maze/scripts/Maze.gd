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
@export var mazeWidth: int = 7
@export var mazeHeight: int = 7
var currentRoomInstance: Node = null
var mazeRooms: Array = []
var currentRoomX: int
var currentRoomY: int
@onready var doorsOffCooldown: bool = true

# Simple question system - make sure these are declared at class level
var pendingDoor: String = ""
var awaitingAnswer: bool = false

# On start
func _ready() -> void:
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
func currentRoom() -> Dictionary:
	return mazeRooms[currentRoomX][currentRoomY]

func currentRoomToString() -> String:
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

## generates data for a single room (used exclusively in conjunction with prepareMazeArray)
func _prepareRoom(x: int, y: int) -> Dictionary:
	# choose a layout for this room at random
	var chosenLayout = randi_range(1, 4) # the second number should be the number of room layouts available 
	
	var room = {
		"x": x, # X coordinate
		"y": y, # Y coordinate
		
		"chosenLayout": chosenLayout, # the layout of this room
		
		# tell whether the room should have a door in a given direction (edge detection)
		"doorExists": {
			"NorthDoor": y < mazeHeight - 1,
			"SouthDoor": y > 0,
			"EastDoor": x < mazeWidth - 1,
			"WestDoor": x > 0,
		},
		
		# tell whether doors can be interacted with 
		# set to false after the player answers the question, regardless of if it was correct or not
		"doorInteractable": {
			"NorthDoor": true,
			"SouthDoor": true,
			"EastDoor": true,
			"WestDoor": true
		},
		
		# tell whether doors are locked or not (default to true, set to false upon correct answer)
		# true = locked; locked doors cannot be passed; unlocked doors enable movement to adjacent rooms
		"doorLocks": {
			"NorthDoor": true,
			"SouthDoor": true,
			"EastDoor": true,
			"WestDoor": true
		},
		
		# questions for each door
		"doorQuestions": {
			"NorthDoor": QuestionFactory.getRandomQuestion(),
			"SouthDoor": QuestionFactory.getRandomQuestion(),
			"EastDoor": QuestionFactory.getRandomQuestion(),
			"WestDoor": QuestionFactory.getRandomQuestion()
		}
	}
	return room

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
	for doorName in startingRoom["doorLocks"].keys():
		startingRoom["doorLocks"][doorName] = false

## load the current/new room
func loadRoom() -> void:
	# clear previously loaded room from memory
	if currentRoomInstance:
		currentRoomInstance.queue_free()
	# new room instance
	currentRoomInstance = roomScene.instantiate()
	add_child(currentRoomInstance)
	
	var room = currentRoom()
	var chosenRoomLayout = room["chosenLayout"]
	var roomLayouts = currentRoomInstance.get_node("RoomLayouts")
	# this works by setting the selected layout to visible and all others to invisible
	for child in roomLayouts.get_children():
		child.visible = false
	var chosenRoom = roomLayouts.get_node("Room" + str(chosenRoomLayout))
	chosenRoom.visible = true
	
	# let doors detect the player
	var currentRoomDoors = currentRoomInstance.get_node("Doors")
	for doorName in ["NorthDoor", "SouthDoor", "EastDoor", "WestDoor"]:
		var thisDoor = currentRoomDoors.get_node(doorName)
		thisDoor.connect("body_entered", Callable(self, "doorTouched").bind(doorName))
	
	updateDoorVisuals()
	print("Room Coordinates: ", currentRoomToString())

## update the visual state of doors based on their actual state
func updateDoorVisuals() -> void:
	var room = currentRoom()
	var doorStates = getDoorStates()
	var currentRoomDoors = currentRoomInstance.get_node("Doors")
	
	for doorName in ["NorthDoor", "SouthDoor", "EastDoor", "WestDoor"]:
		var thisDoor = currentRoomDoors.get_node(doorName)
		var doorVisual = thisDoor.get_node("DoorVisual")
		
		match doorStates[doorName]:
			"WALL":
				doorVisual.visible = false
			"BROKEN":
				doorVisual.visible = true
				doorVisual.texture = preload("res://assets/CTM_Door3.png")
			"LOCKED":
				doorVisual.visible = true
				doorVisual.texture = preload("res://assets/CTM_Door1.png")
			"UNLOCKED":
				doorVisual.visible = true
				doorVisual.texture = preload("res://assets/CTM_Door2.png")
				if room["doorInteractable"].get(doorName, false) and room["doorLocks"].get(doorName, false):
					print("Error: A door is both interactable and unlocked.")
					# the case for Interactable AND NOT locked should NEVER happen

## creates a simple dictionary of the door states in the current room, based on the exists/interactable/locked values
## use doorstates[doorName] to get the state of a specific door
func getDoorStates() -> Dictionary:
	var room = currentRoom()
	var doorStates = {}
	
	for doorName in ["NorthDoor", "SouthDoor", "EastDoor", "WestDoor"]:
		if not room["doorExists"].get(doorName, false):
			doorStates[doorName] = "WALL"
		elif not room["doorInteractable"].get(doorName, true) and room["doorLocks"].get(doorName, true):
			doorStates[doorName] = "BROKEN"
		elif room["doorLocks"].get(doorName, true):
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
	
	var room = currentRoom()
	print(room["doorQuestions"].get(doorName)) # remove this once question menu is implemented
	# check if the target direction goes out of bounds, and deny movement if it is
	var canMove = room["doorExists"].get(doorName, false)
	if canMove:
		# check if the door is locked
		var isLocked = room["doorLocks"][doorName]
		if isLocked:
			print(">>> BLOCKED! Door ", doorName, currentRoomToString(), " is LOCKED.")
		else:
			print(">>> SUCCESS! ", doorName, currentRoomToString(), " is UNLOCKED. Going through door...")
			doorsOffCooldown = false
			call_deferred("moveRooms", doorName) # used to be moveRooms(doorName) but godot doesn't like that (functions effectively the same either way)
			get_tree().create_timer(0.25).timeout.connect(_enableDoors)
	else:
		print(">>> Can't move - at maze boundary!")

# just resets the door cooldown
func _enableDoors() -> void:
	doorsOffCooldown = true

## move the player to another room when they go through a door
func moveRooms(doorName: String) -> void:
	var enteringFrom = ""
	var entryDoor = ""
	# match is literally just a switch statement
	match doorName:
		"NorthDoor":
			currentRoomY += 1
			enteringFrom = "FromSouth"
			entryDoor = "SouthDoor"
		"SouthDoor":
			currentRoomY -= 1
			enteringFrom = "FromNorth"
			entryDoor = "NorthDoor"
		"EastDoor":
			currentRoomX += 1
			enteringFrom = "FromWest"
			entryDoor = "WestDoor"
		"WestDoor":
			currentRoomX -= 1
			enteringFrom = "FromEast"
			entryDoor = "EastDoor"
	
	currentRoom()["doorLocks"][entryDoor] = false
	loadRoom()
	
	var markers = currentRoomInstance.get_node("EntryPoint")
	var entryPoint = markers.get_node(enteringFrom)
	playerNode.global_position = entryPoint.global_position

## Show question in console (simple implementation)
#func showQuestion(doorName: String, questionData: Dictionary):
	#pendingDoor = doorName
	#awaitingAnswer = true
	#
	#print("\n=== DOOR LOCKED ===")
	#print("Question: " + questionData["question"])
	#for option in questionData["options"]:
		#print(option)
	#print("Press the number key (1-4) for your answer")
	#print("==================")

# Check if answer is correct
#func checkAnswer(answerNum: int):
	#if not awaitingAnswer:
		#return
		#
	#var room = mazeRooms[currentRoomX][currentRoomY]
	#var questionData = room["doorQuestions"][pendingDoor]
	#
	#if answerNum == questionData["correct"]:
		#print("✓ CORRECT! Door unlocked.")
		## Unlock the door permanently
		#room["doorLocks"][pendingDoor] = false
		## Now go through the door
		#doorCooldown = false
		#moveRooms(pendingDoor)
		#get_tree().create_timer(0.25).timeout.connect(enableDoors)
	#else:
		#print("✗ INCORRECT! Door remains locked.")
	#
	## Reset question state
	#awaitingAnswer = false
	#pendingDoor = ""
