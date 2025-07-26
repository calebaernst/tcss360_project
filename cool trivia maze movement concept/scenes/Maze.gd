extends Node2D

# rooms are arranged in an array which also represents their actual arrangement
var mazeRooms: Array = []
@export var mazeWidth: int = 7
@export var mazeHeight: int = 7

# keep track of the current room coordinates of the player
var currentRoomX: int = 0
var currentRoomY: int = 0
# TODO: if able, add a timer here (only to be active in hard mode)
 
func prepareMazeArray():
	for x in range(mazeWidth):
		var column: Array = [] # reinitialize the column array on each loop to prevent cells from pointing at the same array
		for y in range(mazeHeight):
			column.append(prepareRoom(x,y))
		mazeRooms.append(column)

func prepareRoom(x: int, y: int):
	var room = {
		"x": x,
		"y": y, 
		"northDoor": y < mazeHeight - 1,
		"southDoor": y > 0,
		"eastDoor": x < mazeWidth - 1,
		"westDoor": x > 0
	}
	return room
