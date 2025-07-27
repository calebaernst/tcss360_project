extends Node2D

# prepare assets to go (also makes debugging a little easier via inspector panel)
@export var roomScene: PackedScene = preload("res://scenes/RoomScene.tscn")
@export var player: NodePath
@onready var player_node = get_node(player)

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
# TODO: if able, add a timer here (only to be active in hard mode)
 
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
		var tileID = thisTileMap.get_cell(0, cell)
		data.append({"position": cell, "tileID": tileID})
	return data

# load the current room
func loadRoom():
	if currentRoomInstance:
		currentRoomInstance.queue_free()
	currentRoomInstance = roomScene.instantiate()
	add_child(currentRoomInstance)
	tilemap = currentRoomInstance.get_node("Room1")
	tilemap.clear()
	var room = mazeRooms[currentRoomX][currentRoomY]
	var data = room["tileData"]
	for cell in data:
		tilemap.set_cell(0, cell["position"], cell["tileID"])

# show current room coordinates for debug
func roomCoordsDebug():
	print("room coordinates: ", currentRoomX, ",", currentRoomY)
