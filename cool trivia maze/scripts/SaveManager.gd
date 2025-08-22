## Save Manager Code
extends RefCounted
class_name SaveManager

static var theMaze: Maze = null
static var currentSlot: int = 0

## get the filepath for the specified save slot (3 save slots)
static func getSaveFilepath(saveSlot: int) -> String:
	match saveSlot:
		1:
			return "user://saveSlot1"
		2:
			return "user://saveSlot2"
		3:
			return "user://saveSlot3"
	
	# this should never happen, and if it does is indication that something is wrong in the code
	push_error("Invalid save slot requested: ", saveSlot)
	return ""

## save game data to a file
static func saveGame(saveSlot: int) -> void:
	var saveFilePath = getSaveFilepath(saveSlot)
	var targetFile = FileAccess.open(saveFilePath, FileAccess.WRITE)
	# if insufficient write permissions, or malformed filepath, abort the process and throw an error
	if targetFile == null:
		push_error("Cannot write save file to path: " + saveFilePath)
		return
	
	var serializedMaze = []
	for x in range(len(theMaze.mazeRooms)):
		var column = []
		for y in range(len(theMaze.mazeRooms[x])):
			var roomData = theMaze.mazeRooms[x][y].duplicate(true)
			var cardinalDoors = ["NorthDoor", "SouthDoor", "EastDoor", "WestDoor"]
			for doorName in cardinalDoors:
				if roomData.has(doorName) and roomData[doorName].has("question"):
					var question = roomData[doorName]["question"]
					if question is Question:
						roomData[doorName]["question"] = question.serialize()
			
			column.append(roomData)
		serializedMaze.append(column)
	
	# prepare all data relevant to "current game state" 
	var saveData = {
		"currentRoomX": theMaze.currentRoomX,
		"currentRoomY": theMaze.currentRoomY,
		"mazeRooms": serializedMaze
		}
	
	targetFile.store_string(JSON.stringify(saveData))
	targetFile.close()
	print("Saved to slot ", saveSlot)

## load game data from a file
static func loadGame(saveSlot: int) -> void:
	var saveData = getSaveData(saveSlot)
	if saveData == null:
		return
	
	var loadedMaze = []
	for x in range(len(saveData["mazeRooms"])):
		var column = []
		for y in range(len(saveData["mazeRooms"][x])):
			var roomData = saveData["mazeRooms"][x][y]
			var reconstructedRoom = roomData.duplicate(true)
			var cardinalDoors = ["NorthDoor", "SouthDoor", "EastDoor", "WestDoor"]
			for doorName in cardinalDoors:
				if reconstructedRoom.has(doorName) and reconstructedRoom[doorName].has("question"):
					var questionData = reconstructedRoom[doorName]["question"]
					if questionData is Dictionary:
						reconstructedRoom[doorName]["question"] = Question.deserialize(questionData)
			
			column.append(reconstructedRoom)
		loadedMaze.append(column)
	
	theMaze.currentRoomX = saveData["currentRoomX"]
	theMaze.currentRoomY = saveData["currentRoomY"]
	theMaze.mazeRooms = loadedMaze
	theMaze.linkDoors()
	theMaze.loadRoom()
	theMaze.playerNode.global_position = Vector2(0,0)
	print("Loaded save from slot ", saveSlot)

## delete a save file
static func deleteSave(saveSlot: int) -> void:
	var saveFilePath = getSaveFilepath(saveSlot)
	if FileAccess.file_exists(saveFilePath):
		var dir = DirAccess.open("user://")
		if dir == null:
			push_error("Cannot access directory")
			return
		var targetFileName = saveFilePath.get_file()
		var deletionResult = dir.remove(targetFileName)
		if deletionResult == OK:
			print("Deleted save file ", saveSlot)
		else: 
			print("Failed to delete save file ", saveSlot)
	else:
		# you should not be able to do this
		print("Attempted deletion of save file ", saveSlot ," which is already empty.")

static func saveExists(saveSlot: int) -> bool:
	return FileAccess.file_exists(getSaveFilepath(saveSlot))

static func getSaveData(saveSlot: int):
	var saveFilePath = getSaveFilepath(saveSlot)
	var targetFile = FileAccess.open(saveFilePath, FileAccess.READ)
	# if insufficient read permissions, malformed filepath, or file does not exist, abort the process and throw an error
	if targetFile == null:
		print("Cannot read save file: " + saveFilePath)
		return
	
	var jsonString = targetFile.get_as_text()
	var json = JSON.new()
	var parseResult = json.parse(jsonString)
	var saveData = json.data
	targetFile.close()
	if not parseResult == OK:
		print("Save file ", jsonString, " cannot be parsed.")
		return
	
	return saveData

static func getSlotDisplay(saveSlot: int) -> String:
	var saveData = getSaveData(saveSlot)
	if saveData == null:
		return ""
	
	# put here whatever set of variables you want tracked by this thing
	var x: int = saveData.get("currentRoomX", -1)
	var y: int = saveData.get("currentRoomY", -1)
	
	return "(" + str(x) + ", " + str(y) + ")"
