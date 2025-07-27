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
 
func _ready():
	prepareMazeArray()
	setStartingRoom()
	loadRoom()
	roomCoordsDebug()

# generate tiles and store their data in an array
func prepareMazeArray():
	for x in range(mazeWidth):
		var column: Array = [] # reinitialize the column array on each loop to prevent cells from pointing at the same array
		for y in range(mazeHeight):
			var thisRoom = prepareRoom(x,y)
			print("prepared room at ", x, ",", y, " with tiles: ", thisRoom["tileData"].size())
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
		"tileData": tileData
	}
	return room

# start the player in the middle-most room
func setStartingRoom(): 
	currentRoomX = int(mazeWidth / 2) + 1
	currentRoomY = int(mazeHeight / 2) + 1

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
	# add door hitbox detection
	var doors = currentRoomInstance.get_node("Doors")
	for doorName in ["NorthDoor", "SouthDoor", "EastDoor", "WestDoor"]:
		var door = doors.get_node(doorName)
		door.connect("body_entered", Callable(self, "doorTouched").bind(doorName))

func doorTouched(doorName: String, body: Node):
	moveRooms(doorName)

# move the player to another room when they go through a door
func moveRooms(doorName: String):
	var enteringFrom = ""
	# match is literally just a switch statement
	match doorName:
		"NorthDoor":
			currentRoomY -= 1
			enteringFrom = "FromSouth"
		"SouthDoor":
			currentRoomY += 1
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
