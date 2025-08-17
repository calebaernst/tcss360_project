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
var playerSelectedAnswer: String = ""  # Store the player's answer

var currentRoomInstance: Node = null
var mazeRooms: Array = []
var currentRoomX: int
var currentRoomY: int
var exitX: int
var exitY: int
const cardinalDoors = ["NorthDoor", "SouthDoor", "EastDoor", "WestDoor"]
var doorsOffCooldown: bool = true

## Question System Integration
var questionMenuInstance: Control = null
var pendingDoor: String = ""
var awaitingAnswer: bool = false
var currentQuestion: Question = null
var lastAnswerCorrect: bool = false   ## remember result until Exit is pressed

## On start
func _ready() -> void:
	SaveManager.theMaze = self
	exitX = mazeWidth / 2
	exitY = mazeHeight / 2
	
	_prepareMazeArray()
	_setStartingRoom()
	loadRoom()
	
	playerNode.z_index = 1000 # fix the player to always be visible
	BGM.play()
	
	# debug inputs can be enabled/disabled from the inspector menu for the "Maze" node
	if debugInputs:
		debugConsole.debugPrints()

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
	
	linkDoors()

## links adjacent doors so that they always share the same state (point to the same reference)
## should only be called upon game initialization or loading a save file
func linkDoors() -> void:
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
	
	## Unlock doors in starting room
	var startingRoom = mazeRooms[currentRoomX][currentRoomY]
	for doorName in cardinalDoors:
		startingRoom[doorName]["locked"] = false

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
	var chosenRoom = roomLayouts.get_node("Room" + str(int(chosenRoomLayout)))
	chosenRoom.visible = true
	
	## let doors detect the player
	var currentRoomDoors = currentRoomInstance.get_node("Doors")
	for doorName in cardinalDoors:
		var thisDoor = currentRoomDoors.get_node(doorName)
		thisDoor.connect("body_entered", Callable(self, "doorTouched").bind(doorName))
	
	# display and enable the exit point if the room being loaded in is the exit room
	var exitPoint = currentRoomInstance.get_node("ExitPoint")
	if currentRoomX == exitX and currentRoomY == exitY:
		if not exitPoint.is_connected("body_entered", Callable(self, "victory")): # prevent duplicate signal
			exitPoint.connect("body_entered", Callable(self, "victory"))
		exitPoint.visible = true
		exitPoint.get_node("PlayerDetector").set_deferred("monitoring", true)
	else:
		exitPoint.visible = false
		exitPoint.get_node("PlayerDetector").set_deferred("monitoring", false)
	
	updateDoorVisuals()
	print("Room Coordinates: ", currentRoomCoords())

## update the door visuals to reflect their internal state
func updateDoorVisuals() -> void:
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
func updateWinCon() -> void:
	var gameLost = not _canReachExit()
	if gameLost:
		defeat()

## called only when the player reaches the exit
func victory(body: Node) -> void:
	if body == playerNode:
		print("you have reached the exit (congrats)")

func defeat() -> void:
	print("you can't make it to the exit any more, so you lose :(")

## creates a simple dictionary of the door states in the current room, based on the exists/interactable/locked values
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


## Door interaction - with question system integration
func doorTouched(body: Node, doorName: String) -> void:
	# do nothing if the touching object is not the player
	# also prevent pingpong effect
	if body != playerNode or not doorsOffCooldown or awaitingAnswer:
		return
	

	var room = getCurrentRoom()
	var door = room[doorName]
	## If the door was already answered and marked non-interactable, do nothing
	if not door["interactable"] and door["locked"]:
		## brief cooldown to avoid spam when standing in the trigger
		doorsOffCooldown = false
		get_tree().create_timer(0.2).timeout.connect(_enableDoors)
		print(">>> DOOR DISABLED: %s at %s" % [doorName, currentRoomCoords()])
		return
	
	# check if the target direction goes out of bounds, and deny movement if it is
	var canMove = door["exists"]
	if canMove:
		# check if the door is locked
		var isLocked = door["locked"]
		if isLocked:
			print(">>> BLOCKED! Door ", doorName, currentRoomCoords(), " is LOCKED.")
			showTriviaQuestion(doorName)
		else:
			print(">>> SUCCESS! ", doorName, currentRoomCoords(), " is UNLOCKED. Going through door...")
			doorsOffCooldown = false
			call_deferred("moveRooms", doorName) # used to be moveRooms(doorName) but godot doesn't like that (functions effectively the same either way)
			get_tree().create_timer(0.25).timeout.connect(_enableDoors)
	else:
		print(">>> Can't move - at maze boundary!")

## just resets the door cooldown
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
		_:
			push_error("moveRooms called with invalid door name")
			return
	
	loadRoom()
	
	var markers = currentRoomInstance.get_node("EntryPoint")
	var entryPoint = markers.get_node(enteringFrom)
	playerNode.global_position = entryPoint.global_position


## Show trivia question when player touches locked door
func showTriviaQuestion(door_name: String) -> void:
	if awaitingAnswer: return
	pendingDoor = door_name
	awaitingAnswer = true
	currentQuestion = getCurrentRoom()[door_name]["question"]

	playerNode.set_physics_process(false)

	questionMenuInstance = questionMenuScene.instantiate()

	## ensure a UI CanvasLayer exists and add the menu there ---
	var root := get_tree().current_scene
	var ui := root.get_node_or_null("UI")
	if ui == null:
		ui = CanvasLayer.new()
		ui.name = "UI"
		ui.layer = 100  # above world
		root.add_child(ui)
	ui.add_child(questionMenuInstance)

	## draw in screen space and fill viewport
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
		
	## Set the question text
	var questionLabel = questionMenuInstance.get_node("Label")
	questionLabel.text = currentQuestion.questionText
	
	## Handle different question types
	match currentQuestion.type:
		"multiple choice":
			setupMultipleChoiceQuestion()
		"true/false":
			setupTrueFalseQuestion()
		"open response":
			setupOpenResponseQuestion()
			
	# Make Exit available again for a fresh question
	var exit_btn := questionMenuInstance.get_node_or_null("Exit") as Button
	if exit_btn:
		exit_btn.visible = true
		exit_btn.disabled = false
		exit_btn.mouse_filter = Control.MOUSE_FILTER_STOP


## Setup multiple choice question display
func setupMultipleChoiceQuestion() -> void:
	var buttons = [
		questionMenuInstance.get_node("Button"),
		questionMenuInstance.get_node("Button2"),
		questionMenuInstance.get_node("Button3"),
		questionMenuInstance.get_node("Button4")
	]
	
	## Show all answer buttons
	for i in range(buttons.size()):
		if i < currentQuestion.answerChoices.size():
			buttons[i].visible = true
			buttons[i].text = currentQuestion.answerChoices[i]
		else:
			buttons[i].visible = false
	
	## Hide open response elements
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
	
	## Show only first two buttons for True/False
	buttons[0].visible = true
	buttons[1].visible = true
	buttons[2].visible = false
	buttons[3].visible = false
	
	## Set True/False text
	for i in range(min(2, currentQuestion.answerChoices.size())):
		buttons[i].text = currentQuestion.answerChoices[i]
	
	## Hide open response elements
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

	var door_to_move := pendingDoor
	var room := getCurrentRoom()

	var isCorrect := selectedAnswer.strip_edges().to_lower() \
		== str(currentQuestion.correctAnswer).strip_edges().to_lower()
	lastAnswerCorrect = isCorrect
	playerSelectedAnswer = selectedAnswer

	## Decide message + update door state
	var msg := ""
	if isCorrect:
		msg = str(currentQuestion.correctMessage)
		if msg.strip_edges() == "":
			msg = "Correct!"
		room[door_to_move]["locked"] = false
		room[door_to_move]["interactable"] = false
	else:
		var base := str(currentQuestion.incorrectMessage)
		if base.strip_edges() == "":
			base = "Incorrect."
		msg = base + "\n\nCorrect Answer: " + str(currentQuestion.correctAnswer)
		room[door_to_move]["interactable"] = false
		updateWinCon()

	updateDoorVisuals()

	## put the result "in place of" the question, hide all inputs, show Continue
	_showResultAndContinue(msg, isCorrect)

## Hide all answer inputs (buttons 1-4, Response, Submit)
func _hideAllQuestionInputs() -> void:
	if not questionMenuInstance: return
	var ids = ["Button", "Button2", "Button3", "Button4", "Response", "Submit"]
	for id in ids:
		var n = questionMenuInstance.get_node_or_null(id)
		if n:
			n.visible = false
			if "disabled" in n: n.disabled = true

## Show the result message where the question label is, and reveal a Continue button
func _showResultAndContinue(message: String, isCorrect: bool) -> void:
	if not questionMenuInstance:
		return

	## 1) Replace the question text with the result message
	var questionLabel := questionMenuInstance.get_node("Label") as Label
	questionLabel.text = message
	var result_color := Color(0.2, 0.95, 0.2) if isCorrect else Color(0.95, 0.25, 0.25)
	questionLabel.add_theme_color_override("font_color", result_color)

	## 2) Hide all inputs so only the message and Continue remain
	_hideAllQuestionInputs()

	## Hide the Exit button after answering
	var exit_btn := questionMenuInstance.get_node_or_null("Exit") as Button
	if exit_btn:
		exit_btn.visible = false
		exit_btn.disabled = true
		exit_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE  # so it can't eat clicks
		
	## 3) Use the pre-made Continue button I made in question.menu
	var cont := questionMenuInstance.get_node("Continue") as Button

	## size & centering
	cont.custom_minimum_size = Vector2(220, 60)
	cont.set_anchors_preset(Control.PRESET_CENTER, false)
	cont.offset_left   = -cont.custom_minimum_size.x * 0.5
	cont.offset_top    = -cont.custom_minimum_size.y * 0.5
	cont.offset_right  =  cont.custom_minimum_size.x * 0.5
	cont.offset_bottom =  cont.custom_minimum_size.y * 0.5

	if not cont.is_connected("pressed", Callable(self, "_onContinuePressed")):
		cont.connect("pressed", Callable(self, "_onContinuePressed"))

	cont.visible = true
	cont.disabled = false
	cont.grab_focus()

## controller for the continue button being presseda
func _onContinuePressed() -> void:
	var door_to_move := pendingDoor
	_closeQuestionMenu()
	awaitingAnswer = false
	if lastAnswerCorrect and door_to_move != "":
		doorsOffCooldown = false
		call_deferred("moveRooms", door_to_move)
		get_tree().create_timer(0.25).timeout.connect(_enableDoors)


## utility to set both normal and disabled text color on Buttons
func _set_button_text_color(b: Button, c: Color) -> void:
	b.add_theme_color_override("font_color", c)
	b.add_theme_color_override("font_disabled_color", c)

## Highlight the correct answer in the button interface (using text color)
func highlightCorrectAnswer(playerAnswer: String) -> void:
	if not questionMenuInstance or not currentQuestion:
		return
		
	var buttons = [
		questionMenuInstance.get_node("Button"),
		questionMenuInstance.get_node("Button2"),
		questionMenuInstance.get_node("Button3"),
		questionMenuInstance.get_node("Button4")
	]

	var correctLower = currentQuestion.correctAnswer.strip_edges().to_lower()
	var playerLower  = playerAnswer.strip_edges().to_lower()

	var GREEN = Color(0.2, 0.95, 0.2)
	var RED   = Color(0.95, 0.25, 0.25)
	var GRAY  = Color(0.65, 0.65, 0.65)
	
	for button in buttons:
		if not button.visible:
			continue
		var txt = button.text.strip_edges().to_lower()
		if txt == correctLower:
			_set_button_text_color(button, GREEN)
		elif txt == playerLower:
			_set_button_text_color(button, RED)
		else:
			_set_button_text_color(button, GRAY)

## Handle when player exits question menu without answering OR after feedback
func _onQuestionMenuExited() -> void:
	var door_to_move := pendingDoor          ## move only if correct

	_closeQuestionMenu()                     ## re-enable player input
	awaitingAnswer = false                   ## allow doors again
	
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

## check if there is a valid path from the player's current room to the exit room
## this utilizes a brute force-y approach and so is relatively computationally expensive
func _canReachExit() -> bool:
	## if you're in the exit room you can definitely reach the exit
	if currentRoomX == exitX and currentRoomY == exitY:
		return true
	
	var queue = [[currentRoomX, currentRoomY]]  # queue of [x, y] coordinates, representing rooms marked to be explored next
	var visited = {}  # track visited rooms (dictionary is insanely more efficient than array for this purpose)
	visited[str(currentRoomX) + "," + str(currentRoomY)] = true
	
	while queue.size() > 0:
		var pathHead = queue.pop_front()
		var pathHeadX = pathHead[0]
		var pathHeadY = pathHead[1]
		var thisRoom = mazeRooms[pathHeadX][pathHeadY]
		
		## dictionary for the relative coordinate offsets for the surrounding rooms/directions
		var cardinalDirections = [ # for the sake of simplicity, we name all of the keys "door"
			{"door": "NorthDoor", "dx": 0, "dy": 1}, # north
			{"door": "SouthDoor", "dx": 0, "dy": -1}, # south
			{"door": "EastDoor", "dx": 1, "dy": 0}, # east
			{"door": "WestDoor", "dx": -1, "dy": 0} # west
		]
		
		for direction in cardinalDirections:
			var thisDoor = thisRoom[direction.door]
			var aheadX = pathHeadX + direction.dx
			var aheadY = pathHeadY + direction.dy
			var aheadCoords = str(aheadX) + "," + str(aheadY)
			
			## skip this room if already visited
			if visited.has(aheadCoords):
				continue
			# skip this door if it's a wall or broken
			if not thisDoor["exists"] or (thisDoor["locked"] and not thisDoor["interactable"]):
				continue
			# if target is reached, a valid path exists
			if aheadX == exitX and aheadY == exitY:
				return true
			
			## if the door is locked or unlocked, add the ahead room to the queue and mark it as visited (because it will be visited via the queue)
			visited[aheadCoords] = true
			queue.append([aheadX, aheadY])
	
	## if the while loop completes, no path exists
	return false
