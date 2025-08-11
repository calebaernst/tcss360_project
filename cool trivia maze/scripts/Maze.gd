extends Node2D
class_name Maze

@export var debugInputs: bool = true
@onready var debugConsole = get_parent().get_node("DebugInputs")

## prepare game assets
var roomScene: PackedScene = preload("res://scenes/RoomScene.tscn")
var questionMenuScene: PackedScene = preload("res://scenes/question_menu.tscn")
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
@onready var doorsOffCooldown: bool = true

## Question System Integration
var questionMenuInstance: Control = null
var pendingDoor: String = ""
var awaitingAnswer: bool = false
var currentQuestion: Question = null

## On start
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
	
	## Unlock doors in starting room
	var startingRoom = mazeRooms[currentRoomX][currentRoomY]
	for doorName in startingRoom["doorLocks"].keys():
		startingRoom["doorLocks"][doorName] = false

## load the current/new room
func loadRoom() -> void:
	## clear previously loaded room from memory
	if currentRoomInstance:
		currentRoomInstance.queue_free()
	## new room instance
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
	
	## let doors detect the player
	var currentRoomDoors = currentRoomInstance.get_node("Doors")
	for doorName in ["NorthDoor", "SouthDoor", "EastDoor", "WestDoor"]:
		var thisDoor = currentRoomDoors.get_node(doorName)
		thisDoor.connect("body_entered", Callable(self, "doorTouched").bind(doorName))
	
	updateDoorVisuals()
	updateWinCon()
	print("Room Coordinates: ", currentRoomToString())

## update the door visuals to reflect their internal state
func updateDoorVisuals() -> void:
	var room = getCurrentRoom()
	var doorStates = getDoorStates()
	var currentRoomDoors = currentRoomInstance.get_node("Doors")
	
	for doorName in ["NorthDoor", "SouthDoor", "EastDoor", "WestDoor"]:
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
				if room["doorInteractable"].get(doorName, false) and room["doorLocks"].get(doorName, false):
					push_error("Door ", thisDoor," is both interactable and unlocked.")
					# the case for Interactable AND NOT locked should NEVER happen

## updates the status of the exit point and checks whether or not the player has lost
func updateWinCon():
	var exitPoint = currentRoomInstance.get_node("ExitPoint")
	
	if currentRoomX != exitX or currentRoomY != exitY:
		exitPoint.visible = false
		exitPoint.get_node("PlayerDetector").set_deferred("monitoring", false)
	else:
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


## Door interaction - with question system integration
func doorTouched(body: Node, doorName: String) -> void:
	# do nothing if the touching object is not the player
	# also prevent pingpong effect
	if body != playerNode or not doorsOffCooldown or awaitingAnswer:
		return
	

	var room = currentRoom()
## If the door was already answered and marked non-interactable, do nothing
	if (not room["doorInteractable"].get(doorName, true)) and room["doorLocks"].get(doorName, true):
		## brief cooldown to avoid spam when standing in the trigger
		doorsOffCooldown = false
		get_tree().create_timer(0.2).timeout.connect(_enableDoors)
		print(">>> DOOR DISABLED: %s at %s" % [doorName, currentRoomToString()])
		return
	## check if the target direction goes out of bounds, and deny movement if it is
  
	var canMove = room["doorExists"].get(doorName, false)
	if canMove:
		## check if the door is locked
		var isLocked = room["doorLocks"][doorName]
		if isLocked:
			print(">>> BLOCKED! Door ", doorName, currentRoomToString(), " is LOCKED.")
			showTriviaQuestion(doorName)  # This is the missing line!
		else:
			print(">>> SUCCESS! ", doorName, currentRoomToString(), " is UNLOCKED. Going through door...")
			doorsOffCooldown = false
			call_deferred("moveRooms", doorName) # used to be moveRooms(doorName) but godot doesn't like that (functions effectively the same either way)
			get_tree().create_timer(0.25).timeout.connect(_enableDoors)
	else:
		print(">>> Can't move - at maze boundary!")

## Show trivia question when player touches locked door
func showTriviaQuestion(door_name: String) -> void:
	if awaitingAnswer: return
	pendingDoor = door_name
	awaitingAnswer = true
	currentQuestion = currentRoom()["doorQuestions"][door_name]

	playerNode.set_physics_process(false)

	questionMenuInstance = questionMenuScene.instantiate()

	# --- ensure a UI CanvasLayer exists and add the menu there ---
	var root := get_tree().current_scene
	var ui := root.get_node_or_null("UI")
	if ui == null:
		ui = CanvasLayer.new()
		ui.name = "UI"
		ui.layer = 100  # above world
		root.add_child(ui)
	ui.add_child(questionMenuInstance)

	# draw in screen space and fill viewport
	questionMenuInstance.top_level = true
	questionMenuInstance.set_anchors_preset(Control.PRESET_FULL_RECT)
	questionMenuInstance.visible = true

	setupQuestionMenu()

	questionMenuInstance.connect("question_answered", _onQuestionAnswered)
	questionMenuInstance.connect("menu_exited", _onQuestionMenuExited)

## Setup the question menu with the current question
func setupQuestionMenu() -> void:
	if not questionMenuInstance or not currentQuestion:
		return
		
	# Set the question text
	var questionLabel = questionMenuInstance.get_node("Label")
	questionLabel.text = currentQuestion.questionText
	
	# Handle different question types
	match currentQuestion.type:
		"multiple choice":
			setupMultipleChoiceQuestion()
		"true/false":
			setupTrueFalseQuestion()
		"open response":
			setupOpenResponseQuestion()

## Setup multiple choice question display
func setupMultipleChoiceQuestion() -> void:
	var buttons = [
		questionMenuInstance.get_node("Button"),
		questionMenuInstance.get_node("Button2"),
		questionMenuInstance.get_node("Button3"),
		questionMenuInstance.get_node("Button4")
	]
	
	# Show all answer buttons
	for i in range(buttons.size()):
		if i < currentQuestion.answerChoices.size():
			buttons[i].visible = true
			buttons[i].text = currentQuestion.answerChoices[i]
		else:
			buttons[i].visible = false
	
	# Hide open response elements
	questionMenuInstance.get_node("Response").visible = false
	questionMenuInstance.get_node("Submit").visible = false

## Setup true/false question (use first two buttons)
func setupTrueFalseQuestion() -> void:
	var buttons = [
		questionMenuInstance.get_node("Button"),
		questionMenuInstance.get_node("Button2"),
		questionMenuInstance.get_node("Button3"),
		questionMenuInstance.get_node("Button4")
	]
	
	# Show only first two buttons for True/False
	buttons[0].visible = true
	buttons[1].visible = true
	buttons[2].visible = false
	buttons[3].visible = false
	
	# Set True/False text
	for i in range(min(2, currentQuestion.answerChoices.size())):
		buttons[i].text = currentQuestion.answerChoices[i]
	
	# Hide open response elements
	questionMenuInstance.get_node("Response").visible = false
	questionMenuInstance.get_node("Submit").visible = false

## Setup open response question
func setupOpenResponseQuestion() -> void:
	# Hide all multiple choice buttons
	questionMenuInstance.get_node("Button").visible = false
	questionMenuInstance.get_node("Button2").visible = false
	questionMenuInstance.get_node("Button3").visible = false
	questionMenuInstance.get_node("Button4").visible = false
	
	# Show text input and submit button
	questionMenuInstance.get_node("Response").visible = true
	questionMenuInstance.get_node("Submit").visible = true
	questionMenuInstance.get_node("Response").text = ""

## Handle when player answers a question
func _onQuestionAnswered(selectedAnswer: String) -> void:
	if not awaitingAnswer or not currentQuestion:
		return

	var door_to_move := pendingDoor       # cache before closing
	var room := currentRoom()

	var isCorrect := selectedAnswer.strip_edges().to_lower() == \
		currentQuestion.correctAnswer.strip_edges().to_lower()

	if isCorrect:
		print("✓ CORRECT! ", currentQuestion.correctMessage)
		room["doorLocks"][door_to_move] = false
		room["doorInteractable"][door_to_move] = false  # no re-quiz

		_closeQuestionMenu()  # this clears pendingDoor, but we cached it

		await get_tree().create_timer(0.5).timeout
		doorsOffCooldown = false
		moveRooms(door_to_move)  # <<< use the cached value
		get_tree().create_timer(0.25).timeout.connect(_enableDoors)
	else:
		print("✗ INCORRECT! ", currentQuestion.incorrectMessage)
		room["doorInteractable"][door_to_move] = false
		_closeQuestionMenu()

	updateDoorVisuals()
	
## Handle when player exits question menu without answering
func _onQuestionMenuExited() -> void:
	_closeQuestionMenu()

## Close and cleanup question menu
func _closeQuestionMenu(preserve_state: bool = false) -> void:
	if questionMenuInstance:
		questionMenuInstance.queue_free()
		questionMenuInstance = null
	playerNode.set_physics_process(true)
	awaitingAnswer = false
	if not preserve_state:
		pendingDoor = ""
		currentQuestion = null


## just resets the door cooldown
func _enableDoors() -> void:
	doorsOffCooldown = true

## move the player to another room when they go through a door
func moveRooms(doorName: String) -> void:
	if doorName == null or doorName == "":
		push_error("moveRooms called with empty door name")
		return
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
	
	getCurrentRoom()["doorLocks"][entryDoor] = false
	loadRoom()
	
	var markers = currentRoomInstance.get_node("EntryPoint")
	var entryPoint = markers.get_node(enteringFrom)
	playerNode.global_position = entryPoint.global_position
