extends Node2D

@export var debugMode: bool = true
@onready var debugConsole = get_parent().get_node("ConsoleDebug")

# prepare assets
var roomScene: PackedScene = preload("res://scenes/RoomScene.tscn")
@export var player: NodePath
@onready var playerNode = get_node(player)
@onready var BGM = $BGMPlayer

# room assets (instantiated later)
var currentRoomInstance: Node = null
# rooms are arranged in an array which also represents their actual arrangement
var mazeRooms: Array = []
@export var mazeWidth: int = 7
@export var mazeHeight: int = 7
# keep track of the current room coordinates of the player
var currentRoomX: int = 0
var currentRoomY: int = 0
var doorCooldown: bool = true

# Simple question system - make sure these are declared at class level
var pendingDoor: String = ""
var awaitingAnswer: bool = false

# On start
func _ready() -> void:
	prepareMazeArray()
	setStartingRoom()
	loadRoom()
	fixPlayerZ()
	
	BGM.play()
	BGM.finished.connect(loopBGM)
	
	debugConsole.roomCoordsDebug()
	if debugMode:
		debugConsole.debugPrints()

func loopBGM() -> void:
	BGM.play()

## generate maze rooms and store their data in an array
func prepareMazeArray() -> void:
	for x in range(mazeWidth):
		var column: Array = [] # reinitialize the column array on each loop to prevent cells from pointing at the same array
		for y in range(mazeHeight):
			var thisRoom = prepareRoom(x,y)
			print("prepared room at ", x, ",", y)
			column.append(thisRoom)
		mazeRooms.append(column)

## generates data for a single room (used in conjunction with prepareMazeArray)
func prepareRoom(x: int, y: int) -> Dictionary:
	# choose a layout for this room at random
	var chosenRoom = randi_range(1, 4) # the second number should be the number of room layouts available 
	
	var room = {
		"x": x, # X coordinate
		"y": y, # Y coordinate
		
		"chosenLayout": chosenRoom, # the layout of this room
		
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
		
		# placeholder questions for each door
		"doorQuestions": {
			"NorthDoor": {"question": "What is 2 + 2?", "correct": 2, "options": ["1) 3", "2) 4", "3) 5", "4) 6"]},
			"SouthDoor": {"question": "How many sides does a triangle have?", "correct": 1, "options": ["1) 3", "2) 4", "3) 5", "4) 6"]},
			"EastDoor": {"question": "What is 3 x 3?", "correct": 3, "options": ["1) 6", "2) 8", "3) 9", "4) 12"]},
			"WestDoor": {"question": "How many legs does a cat have?", "correct": 2, "options": ["1) 2", "2) 4", "3) 6", "4) 8"]}
		}
	}
	return room
	
## start the player in a certain room and unlock the starting doors
func setStartingRoom() -> void: 
	currentRoomX = int(mazeWidth / 2)
	currentRoomY = int(mazeHeight / 2)
	
	# Unlock doors in starting room
	if currentRoomX < mazeRooms.size() and currentRoomY < mazeRooms[currentRoomX].size():
		var startingRoom = mazeRooms[currentRoomX][currentRoomY]
		for doorName in startingRoom["doorLocks"].keys():
			startingRoom["doorLocks"][doorName] = false

## load the current/new room
func loadRoom() -> void:
	# clear previously loaded room to make way for new one
	if currentRoomInstance:
		currentRoomInstance.queue_free()
	# new room instance
	currentRoomInstance = roomScene.instantiate()
	add_child(currentRoomInstance)
	
	# actually show the room
	var room = currentRoom()
	var chosenRoomLayout = room["chosenLayout"]
	
	# hide all room layouts first
	var roomLayouts = currentRoomInstance.get_node("RoomLayouts")
	for child in roomLayouts.get_children():
		child.visible = false
	# show only the chosen room
	var chosenRoom = roomLayouts.get_node("Room" + str(chosenRoomLayout))
	chosenRoom.visible = true
	
	if currentRoomX == int(mazeWidth / 2) and currentRoomY == int(mazeHeight / 2):
		print("UNLOCKING STARTING ROOM DOORS")
		for doorName in room["doorLocks"].keys():
			room["doorLocks"][doorName] = false
	
	# let doors detect the player
	var currentRoomDoors = currentRoomInstance.get_node("Doors")
	for doorName in ["NorthDoor", "SouthDoor", "EastDoor", "WestDoor"]:
		var thisDoor = currentRoomDoors.get_node(doorName)
		thisDoor.connect("body_entered", Callable(self, "doorTouched").bind(doorName))
	
	updateDoors(room, currentRoomDoors)

## update the visual state and collidable state of doors
func updateDoors(room: Dictionary, currentRoomDoors: Node) -> void:
	for doorName in ["NorthDoor", "SouthDoor", "EastDoor", "WestDoor"]:
		var thisDoor = currentRoomDoors.get_node(doorName)
		var doorVisual = thisDoor.get_node("DoorVisual")
		var doorBody = thisDoor.get_node("DoorBody")
		
		if not room["doorExists"].get(doorName, false):
			doorVisual.modulate = Color(0, 0, 0)
			doorBody.set_deferred("disabled", false)
		elif not room["doorInteractable"].get(doorName, false) and room["doorLocks"].get(doorName, true):
			doorVisual.modulate = Color(1, 0, 0)
			doorBody.set_deferred("disabled", false)
		elif room["doorLocks"].get(doorName, true):
			doorVisual.modulate = Color(1, 0, 1)
			doorBody.set_deferred("disabled", false)
		else:
			doorVisual.modulate = Color(0, 1, 0)
			doorBody.set_deferred("disabled", true)
			if room["doorInteractable"].get(doorName, false) and room["doorLocks"].get(doorName, false):
				print("Error: A door is both interactable and unlocked.")
				# the case for Interactable AND NOT locked should NEVER happen

# so apparently collision detection works a lot like that propertychangeevent stuff but it's much less flexible so we need a helper method to even catch it
## Door interaction - test version with lots of debug
func doorTouched(body: Node, doorName: String) -> void:
	# print(">>> DOOR TOUCHED: ", doorName, " by: ", body.name)
	
	# is it the player?
	if body != playerNode:
		# print(">>> Not the player, ignoring")
		return
	
	# prevent pingpong effect
	if not doorCooldown:
		return
	
	var room = currentRoom()
	# check if the target direction goes out of bounds, and deny movement if it is
	var canMove = room["doorExists"].get(doorName, false)
	if canMove:
		# check if the door is locked
		var isLocked = room["doorLocks"][doorName]
		if isLocked:
			print(">>> BLOCKED! Door ", doorName, currentRoomString(), " is LOCKED.")
		else:
			print(">>> SUCCESS! Door ", doorName, currentRoomString(), " is UNLOCKED. Going through door...")
			doorCooldown = false
			moveRooms(doorName)
			get_tree().create_timer(0.25).timeout.connect(enableDoors)
	else:
		print(">>> Can't move - at maze boundary!")

# just resets the door cooldown
func enableDoors() -> void:
	doorCooldown = true

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
	
	debugConsole.roomCoordsDebug()

## sets the player to the highest z-index so that they are always visible
func fixPlayerZ() -> void:
	playerNode.z_index = 1000

# gets the current room of the player
func currentRoom() -> Dictionary:
	return mazeRooms[currentRoomX][currentRoomY]

func currentRoomString() -> String:
	return "(" + str(currentRoomX) + "," + str(currentRoomY) + ")"


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
