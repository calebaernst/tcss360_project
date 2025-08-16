extends RefCounted
class_name SaveManager

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
static func saveGame(maze: Maze, saveSlot: int) -> void:
	var saveFilePath = getSaveFilepath(saveSlot)
	var targetFile = FileAccess.open(saveFilePath, FileAccess.WRITE)
	# if insufficient write permissions, or malformed filepath, abort the process and throw an error
	if targetFile == null:
		push_error("Cannot write save file to path: " + saveFilePath)
		return
	
	var serializedMaze = []
	for x in range(len(maze.mazeRooms)):
		var column = []
		for y in range(len(maze.mazeRooms[x])):
			var roomData = maze.mazeRooms[x][y].duplicate(true)
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
		"currentRoomX": maze.currentRoomX,
		"currentRoomY": maze.currentRoomY,
		"mazeRooms": serializedMaze
		}
	
	targetFile.store_string(JSON.stringify(saveData))
	targetFile.close()
	print("Saved to slot ", saveSlot)

## load game data from a file
static func loadGame(maze: Maze, saveSlot: int) -> void:
	var saveFilePath = getSaveFilepath(saveSlot)
	var targetFile = FileAccess.open(saveFilePath, FileAccess.READ)
	# if insufficient read permissions, malformed filepath, or file does not exist, abort the process and throw an error
	if targetFile == null:
		print("Cannot read save file: " + saveFilePath)
		return
	
	var jsonString = targetFile.get_as_text()
	var json = JSON.new()
	var parseResult = json.parse(jsonString)
	if not parseResult == OK:
		print("Save file ", jsonString, " cannot be parsed.")
		return
	var saveData = json.data
	
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
	
	maze.currentRoomX = saveData["currentRoomX"]
	maze.currentRoomY = saveData["currentRoomY"]
	maze.mazeRooms = loadedMaze
	maze.linkDoors()
	targetFile.close()
	maze.loadRoom()
	maze.playerNode.global_position = Vector2(0,0)
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
		print("Attempted deletion of a save ", saveSlot ," which is already empty.")
