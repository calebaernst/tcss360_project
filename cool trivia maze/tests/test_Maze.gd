extends GutTest

const MazeScript := preload("res://scripts/Maze.gd") # <-- adjust path if needed

## tiny mocks 
class MockPlayer:
	extends Node2D
	var velocity: Vector2 = Vector2.ZERO
	var physics_enabled := true
	func select_animation() -> void: pass
	

class MockQuestion:
	var questionText := "2+2?"
	var type := "multiple choice"
	var answerChoices := ["4","3","2","1"]
	var correctAnswer := "4"
	var correctMessage := "Correct"
	var incorrectMessage := "Wrong"

# Subclass Maze to bypass scenes/UI/autoloads and keep tests deterministic.
class TestMaze:
	extends MazeScript
	var show_trivia_called_with: String = ""
	var defeat_called: bool = false
	var moved_to: String = ""
	var move_count: int = 0

	func _ready() -> void:
		# skip real _ready() (SaveManager, scenes, audio, etc.)
		pass

	# Remove QuestionFactory dependency and keep door 'exists' logic intact.
	func _prepareDoor(direction: String, x: int, y: int) -> Dictionary:
		var exists := false
		match direction:
			"North": exists = y < mazeHeight - 1
			"South": exists = y > 0
			"East":  exists = x < mazeWidth - 1
			"West":  exists = x > 0
		return {
			"exists": exists,
			"interactable": true,
			"locked": true,
			"question": MockQuestion.new()
		}

	# Don’t instantiate scenes; only update coordinates.
	func moveRooms(door: String) -> void:
		match door:
			"NorthDoor": currentRoomY += 1
			"SouthDoor": currentRoomY -= 1
			"EastDoor":  currentRoomX += 1
			"WestDoor":  currentRoomX -= 1
			_: pass
		moved_to = door
		move_count += 1

	# Stub trivia & defeat
	func showTriviaQuestion(door_name: String) -> void:
		show_trivia_called_with = door_name
		awaitingAnswer = true
		pendingDoor = door_name

	func defeat() -> void:
		defeat_called = true

var maze: TestMaze
var player: MockPlayer

func before_each() -> void:
	maze = TestMaze.new()
	maze.mazeWidth = 3
	maze.mazeHeight = 3

	player = MockPlayer.new()
	player.name = "Player"
	maze.playerNode = player   # Maze methods read this directly
	maze.add_child(player)

	maze.exitX = 1
	maze.exitY = 1

	maze._prepareMazeArray()   # builds rooms and links doors
	maze._setStartingRoom()    # unlocks doors in starting room

func after_each() -> void:
	maze.queue_free()

# ---------- tests ----------

func test_prepare_maze_array_dimensions() -> void:
	assert_eq(maze.mazeRooms.size(), 3)
	for x in range(3):
		assert_eq(maze.mazeRooms[x].size(), 3)
		var room: Dictionary = maze.mazeRooms[x][0]
		for k in ["x","y","chosenLayout","NorthDoor","SouthDoor","EastDoor","WestDoor"]:
			assert_true(room.has(k), "room has '%s'" % k)

func test_link_doors_share_state_between_adjacent_rooms() -> void:
	var a: Dictionary = maze.mazeRooms[0][0]
	var b: Dictionary = maze.mazeRooms[1][0]
	a["EastDoor"]["locked"] = false
	assert_false(b["WestDoor"]["locked"], "linked door state mirrors neighbor")

func test_set_starting_room_unlocks_all_doors_in_that_room() -> void:
	var start: Dictionary = maze.mazeRooms[maze.currentRoomX][maze.currentRoomY]
	for name in ["NorthDoor","SouthDoor","EastDoor","WestDoor"]:
		assert_false(start[name]["locked"], "starting-room door '%s' is unlocked" % name)

func test_get_current_room_and_coords() -> void:
	var room: Dictionary = maze.getCurrentRoom()
	assert_eq(maze.currentRoomCoords(), "(" + str(room["x"]) + "," + str(room["y"]) + ")")

func test_get_door_states_wall_broken_locked_unlocked() -> void:
	var room: Dictionary = maze.getCurrentRoom()
	room["NorthDoor"]["exists"] = false                                                  # WALL
	room["SouthDoor"]["exists"] = true; room["SouthDoor"]["locked"] = true; room["SouthDoor"]["interactable"] = false # BROKEN
	room["EastDoor"]["exists"]  = true; room["EastDoor"]["locked"]  = true; room["EastDoor"]["interactable"]  = true  # LOCKED
	room["WestDoor"]["exists"]  = true; room["WestDoor"]["locked"]  = false                                         # UNLOCKED
	var states := maze.getDoorStates()
	assert_eq(states["NorthDoor"], "WALL")
	assert_eq(states["SouthDoor"], "BROKEN")
	assert_eq(states["EastDoor"],  "LOCKED")
	assert_eq(states["WestDoor"],  "UNLOCKED")

func test__canReachExit_true_when_path_exists() -> void:
	for x in range(3):
		for y in range(3):
			for dn in ["NorthDoor","SouthDoor","EastDoor","WestDoor"]:
				var d: Dictionary = maze.mazeRooms[x][y][dn]
				d["interactable"] = true
				d["locked"] = false
	assert_true(maze._canReachExit())

func test__canReachExit_false_when_everything_is_broken() -> void:
	for x in range(3):
		for y in range(3):
			for dn in ["NorthDoor","SouthDoor","EastDoor","WestDoor"]:
				var d: Dictionary = maze.mazeRooms[x][y][dn]
				d["interactable"] = false
				d["locked"] = true
	assert_false(maze._canReachExit())

func test_updateWinCon_calls_defeat_when_unreachable() -> void:
	for x in range(3):
		for y in range(3):
			for dn in ["NorthDoor","SouthDoor","EastDoor","WestDoor"]:
				var d: Dictionary = maze.mazeRooms[x][y][dn]
				d["interactable"] = false
				d["locked"] = true
	maze.updateWinCon()
	assert_true(maze.defeat_called)

func test_moveRooms_updates_coordinates_only() -> void:
	maze.currentRoomX = 1
	maze.currentRoomY = 1
	maze.moveRooms("NorthDoor")
	assert_eq(maze.currentRoomX, 1)
	assert_eq(maze.currentRoomY, 2)
	assert_eq(maze.moved_to, "NorthDoor")

func test_doorTouched_on_locked_door_triggers_trivia() -> void:
	maze.currentRoomX = 1
	maze.currentRoomY = 1
	maze.awaitingAnswer = false
	maze.doorsOffCooldown = true
	var room: Dictionary = maze.getCurrentRoom()
	var door: Dictionary = room["NorthDoor"]
	door["exists"] = true
	door["locked"] = true
	door["interactable"] = true

	maze.doorTouched(player, "NorthDoor")
	assert_eq(maze.show_trivia_called_with, "NorthDoor")
	assert_true(maze.awaitingAnswer)
