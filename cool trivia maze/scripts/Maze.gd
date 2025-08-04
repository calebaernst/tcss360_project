# This is Essientally our Game Manager
extends Node2D

# Signals to decouple our Door logic 
signal door_locked(door_name: String, question_data: Dictionary)
signal door_unlocked(door_name: String)
signal room_loaded(room_x: int, room_y: int)
signal player_moved(from_room: Vector2i, to_room: Vector2i)
#Question system signals
signal question_answered_correctly(door_name: String)
signal question_answered_incorrectly(door_name: String)

#debug code 
@export var debugMode: bool = true
@onready var debugConsole = get_parent().get_node("ConsoleDebug")

# prepare assets
var roomScene: PackedScene = preload("res://scenes/RoomScene.tscn")
# reference the question menu
var questionMenuScene: PackedScene = preload("res://scenes/question_menu.tscn")
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
var questionMenuInstance: Node = null

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
		#Connect signals
	_connect_internal_signals()

#  ************************************************************
func _connect_internal_signals():
	door_locked.connect(_on_door_locked)
	door_unlocked.connect(_on_door_unlocked)
	room_loaded.connect(_on_room_loaded)
	player_moved.connect(_on_player_moved)

	question_answered_correctly.connect(_on_question_answered_correctly)
	question_answered_incorrectly.connect(_on_question_answered_incorrectly)
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
		
		# MODIFIED: Remove hardcoded questions - will use database questions instead
		"doorQuestions": {
			"NorthDoor": null,
			"SouthDoor": null,
			"EastDoor": null,
			"WestDoor": null
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
	#signal when room is loaded
	room_loaded.emit(currentRoomX, currentRoomY)

## update the visual state of doors
func updateDoors(room: Dictionary, currentRoomDoors: Node) -> void:
	for doorName in ["NorthDoor", "SouthDoor", "EastDoor", "WestDoor"]:
		var thisDoor = currentRoomDoors.get_node(doorName)
		var doorVisual = thisDoor.get_node("DoorVisual")
		var doorBody = thisDoor.get_node("DoorBody")
		
		if not room["doorExists"].get(doorName, false):
			# corresponds to the maze edge - uninteractable, unpassable
			doorVisual.modulate = Color(0, 0, 0)
		elif not room["doorInteractable"].get(doorName, false) and room["doorLocks"].get(doorName, true):
			# corresponds to a broken door - no longer interactable and remains locked
			doorVisual.modulate = Color(1, 0, 0)
		elif room["doorLocks"].get(doorName, true):
			# corresponds to a locked door - player must answer a question to unlock
			doorVisual.modulate = Color(1, 0, 1)
		else:
			# corresponds to an open door - uninteractable, passable
			doorVisual.modulate = Color(0, 1, 0)
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
	
	# Don't allow interaction if already waiting for answer
	if awaitingAnswer:
		return
		
	var room = currentRoom()
	# check if the target direction goes out of bounds, and deny movement if it is
	var canMove = room["doorExists"].get(doorName, false)
	if canMove:
		# check if the door is locked
		var isLocked = room["doorLocks"][doorName]
		var isInteractable = room["doorInteractable"][doorName]
		if isLocked and isInteractable:
			print(">>> BLOCKED! Door ", doorName, currentRoomString(), " is LOCKED. Showing question...")
			# Show question interface instead of simple print
			showQuestionForDoor(doorName)
		elif not isLocked:
			print(">>> SUCCESS! Door ", doorName, currentRoomString(), " is UNLOCKED. Going through door...")
			door_unlocked.emit(doorName)
			doorCooldown = false
			moveRooms(doorName)
			get_tree().create_timer(0.25).timeout.connect(enableDoors)
		else:
			print(">>> Door ", doorName, " has already been attempted.")
	else:
		print(">>> Can't move - at maze boundary!")

func showQuestionForDoor(doorName: String) -> void:
	if awaitingAnswer:
		return
		
	# Set pending door and awaiting state
	pendingDoor = doorName
	awaitingAnswer = true
	
	# Create question menu instance
	questionMenuInstance = questionMenuScene.instantiate()
	get_tree().current_scene.add_child(questionMenuInstance)
	
	# Connect to the question menu's completion signal
	# WE NEED TO DO THIS IN QUESTION MENU TSCN TOO!
	if questionMenuInstance.has_signal("question_completed"):
		questionMenuInstance.connect("question_completed", _on_question_completed)
	
	# Pause the game while question is showing
	get_tree().paused = true

## Handle question completion from the question menu
func _on_question_completed(is_correct: bool) -> void:
	if not awaitingAnswer:
		return
		
	# Clean up question menu
	if questionMenuInstance:
		questionMenuInstance.queue_free()
		questionMenuInstance = null
	
	# Resume game
	get_tree().paused = false
	
	var room = currentRoom()
	
	if is_correct:
		print("✓ CORRECT! Door unlocked.")
		# Emit signal for correct answer
		question_answered_correctly.emit(pendingDoor)
		
		# Unlock the door permanently
		room["doorLocks"][pendingDoor] = false
		# Mark door as non-interactable (question answered)
		room["doorInteractable"][pendingDoor] = false
		
		# Update door visuals
		var currentRoomDoors = currentRoomInstance.get_node("Doors")
		updateDoors(room, currentRoomDoors)
		
		# Now go through the door
		doorCooldown = false
		moveRooms(pendingDoor)
		get_tree().create_timer(0.25).timeout.connect(enableDoors)
	else:
		print("✗ INCORRECT! Door remains locked.")
		# Emit signal for incorrect answer
		question_answered_incorrectly.emit(pendingDoor)
		
		# Mark door as non-interactable (question answered, but still locked)
		room["doorInteractable"][pendingDoor] = false
		
		# Update door visuals to show red (attempted but failed)
		var currentRoomDoors = currentRoomInstance.get_node("Doors")
		updateDoors(room, currentRoomDoors)
	
	# Reset question state
	awaitingAnswer = false
	pendingDoor = ""
	
## just resets the door cooldown
func enableDoors() -> void:
	doorCooldown = true

## move the player to another room when they go through a door
func moveRooms(doorName: String) -> void:
	#Store old position for signal
	var old_position = Vector2i(currentRoomX, currentRoomY)
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

	var new_position = Vector2i(currentRoomX, currentRoomY)
	#Emit signal for movement between rooms
	player_moved.emit(old_position, new_position)
	
## sets the player to the highest z-index so that they are always visible
func fixPlayerZ() -> void:
	playerNode.z_index = 1000

# gets the current room of the player
func currentRoom() -> Dictionary:
	return mazeRooms[currentRoomX][currentRoomY]

func currentRoomString() -> String:
	return "(" + str(currentRoomX) + "," + str(currentRoomY) + ")"

func _on_door_locked(door_name: String, question_data: Dictionary):
	print("Question needed for ", door_name, ": ", question_data.question)

func _on_door_unlocked(door_name: String):
	print("Player used unlocked door: ", door_name)

func _on_room_loaded(room_x: int, room_y: int):
	print("Loaded room: (", room_x, ",", room_y, ")")

func _on_player_moved(from_room: Vector2i, to_room: Vector2i):
	print("Player moved from ", from_room, " to ", to_room)

func _on_question_answered_correctly(door_name: String):
	print("Player answered correctly for door: ", door_name)

func _on_question_answered_incorrectly(door_name: String):
	print("Player answered incorrectly for door: ", door_name)
	
