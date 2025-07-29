extends Node2D

# prepare assets to go (also makes debugging a little easier via inspector panel)
@export var roomScene: PackedScene = preload("res://scenes/RoomScene.tscn")
@export var player: NodePath
@onready var playerNode = get_node(player)

# room assets (instantiated later)
var currentRoomInstance: Node = null
var tilemap: TileMap = null

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

func _ready():
	prepareMazeArray()
	setStartingRoom()
	loadRoom()
	roomCoordsDebug()
	print(" CONTROLS ")
	print("Press U to UNLOCK all doors in current room")
	print("Press L to LOCK all doors in current room") 
	print("Press SPACE to show current door lock states")
	print("Press U to UNLOCK all doors in current room")
	print("Press L to LOCK all doors in current room") 
	print("Press SPACE to show current door lock states")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_U:
				unlockAllDoors()
			KEY_L:
				lockAllDoors()
			KEY_SPACE:
				showDoorStates()

func unlockAllDoors():
	var room = mazeRooms[currentRoomX][currentRoomY]
	for doorName in room["doorLocks"].keys():
		room["doorLocks"][doorName] = false
	print("ALL DOORS UNLOCKED in room (", currentRoomX, ",", currentRoomY, ")")
	showDoorStates()

func lockAllDoors():
	var room = mazeRooms[currentRoomX][currentRoomY]
	for doorName in room["doorLocks"].keys():
		room["doorLocks"][doorName] = true
	print("ALL DOORS LOCKED in room (", currentRoomX, ",", currentRoomY, ")")
	showDoorStates()

func showDoorStates():
	var room = mazeRooms[currentRoomX][currentRoomY]
	print("=== DOOR STATES ===")
	for doorName in room["doorLocks"].keys():
		var status = "LOCKED" if room["doorLocks"][doorName] else "UNLOCKED"
		print(doorName, ": ", status)
	print("===================")
	
# generate tiles and store their data in an array
func prepareMazeArray():
	for x in range(mazeWidth):
		var column: Array = [] # reinitialize the column array on each loop to prevent cells from pointing at the same array
		for y in range(mazeHeight):
			var thisRoom = prepareRoom(x,y)
			print("prepared room at ", x, ",", y)
			column.append(thisRoom)
		mazeRooms.append(column)

# generates data for a single room
func prepareRoom(x: int, y: int):
	var roomInstance = roomScene.instantiate()
	var sceneTilemap = roomInstance.get_node("Room1")
	var tileData = getTileData(sceneTilemap)
	
	var room = {
		"x": x,
		"y": y, 
		"northDoor": y < mazeHeight - 1,
		"southDoor": y > 0,
		"eastDoor": x < mazeWidth - 1,
		"westDoor": x > 0,
		"tileData": tileData,
		# Door lock states - all doors start locked except starting room
		"doorLocks": {
			"NorthDoor": true,
			"SouthDoor": true,
			"EastDoor": true,
			"WestDoor": true
		},
		# Simple questions for each door
		"doorQuestions": {
			"NorthDoor": {"question": "What is 2 + 2?", "correct": 2, "options": ["1) 3", "2) 4", "3) 5", "4) 6"]},
			"SouthDoor": {"question": "How many sides does a triangle have?", "correct": 1, "options": ["1) 3", "2) 4", "3) 5", "4) 6"]},
			"EastDoor": {"question": "What is 3 x 3?", "correct": 3, "options": ["1) 6", "2) 8", "3) 9", "4) 12"]},
			"WestDoor": {"question": "How many legs does a cat have?", "correct": 2, "options": ["1) 2", "2) 4", "3) 6", "4) 8"]}
		}
	}
	return room
	
# start the player in the middle-most room and unlock the starting doors
func setStartingRoom(): 
	currentRoomX = int(mazeWidth / 2)
	currentRoomY = int(mazeHeight / 2)
	
	# Unlock doors in starting room
	if currentRoomX < mazeRooms.size() and currentRoomY < mazeRooms[currentRoomX].size():
		var startingRoom = mazeRooms[currentRoomX][currentRoomY]
		for doorName in startingRoom["doorLocks"].keys():
			startingRoom["doorLocks"][doorName] = false


func getTileData(thisTileMap: TileMap):
	var data: Array = []
	for cell in thisTileMap.get_used_cells(0):
		var tileID = thisTileMap.get_cell_source_id(0, cell)
		data.append({"position": cell, "tileID": tileID})
	return data

# load the current room
func loadRoom():
	# clear previously loaded room to make way for new one
	if currentRoomInstance:
		currentRoomInstance.queue_free()
	# new room instance
	currentRoomInstance = roomScene.instantiate()
	add_child(currentRoomInstance)
	tilemap = currentRoomInstance.get_node("Room1")
	tilemap.clear()
	# actually generate the room
	var room = mazeRooms[currentRoomX][currentRoomY]
	var data = room["tileData"]
	for cell in data:
		tilemap.set_cell(0, cell["position"], cell["tileID"])
	if currentRoomX == int(mazeWidth / 2) and currentRoomY == int(mazeHeight / 2):
		print("UNLOCKING STARTING ROOM DOORS")
		for doorName in room["doorLocks"].keys():
			room["doorLocks"][doorName] = false
	# add door hitbox detection
	var doors = currentRoomInstance.get_node("Doors")
	for doorName in ["NorthDoor", "SouthDoor", "EastDoor", "WestDoor"]:
		var door = doors.get_node(doorName)
		door.connect("body_entered", Callable(self, "doorTouched").bind(doorName))

# so apparently collision detection works a lot like that propertychangeevent stuff but it's much less flexible so we need a helper method to even catch it
# Door interaction - test version with lots of debug
func doorTouched(body: Node, doorName: String):
	print(">>> DOOR TOUCHED: ", doorName, " by: ", body.name)
	
	# is it the player?
	if body != playerNode:
		print(">>> Not the player, ignoring")
		return
	
	# prevent pingpong effect
	if not doorCooldown:
		print(">>> Door cooldown active, ignoring")
		return
	
	var room = mazeRooms[currentRoomX][currentRoomY]
	var isLocked = room["doorLocks"][doorName]
	
	print(">>> Door ", doorName, " is: ", "LOCKED" if isLocked else "UNLOCKED")
	
	if isLocked:
		print(">>> BLOCKED! Door is locked. Press U to unlock doors.")
	else:
		print(">>> SUCCESS! Going through door...")
		
		# Check if we can actually move in this direction
		var canMove = false
		match doorName:
			"NorthDoor":
				canMove = currentRoomY < mazeHeight - 1
			"SouthDoor":
				canMove = currentRoomY > 0
			"EastDoor":
				canMove = currentRoomX < mazeWidth - 1
			"WestDoor":
				canMove = currentRoomX > 0
		
		if canMove:
			print(">>> Moving to new room...")
			doorCooldown = false
			moveRooms(doorName)
			get_tree().create_timer(0.25).timeout.connect(enableDoors)
		else:
			print(">>> Can't move - at maze boundary!")


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

# just resets the door cooldown
func enableDoors():
	doorCooldown = true

# move the player to another room when they go through a door
func moveRooms(doorName: String):
	var enteringFrom = ""
	# match is literally just a switch statement
	match doorName:
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
	
	roomCoordsDebug()

# show current room coordinates for debug
func roomCoordsDebug():
	print("room coordinates: ", currentRoomX, ",", currentRoomY)
