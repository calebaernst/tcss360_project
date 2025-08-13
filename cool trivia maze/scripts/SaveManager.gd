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
	
	# prepare all data relevant to "current game state" 
	var saveData = {
		"currentRoomX": maze.currentRoomX,
		"currentRoomY": maze.currentRoomY,
		"mazeRooms": maze.mazeRooms
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
		push_error("Cannot read save file: " + saveFilePath)
		return
	
	var jsonString = targetFile.get_as_text()
	var json = JSON.new()
	var parseResult = json.parse(jsonString)
	if not parseResult == OK:
		push_error("Save file cannot be parsed.")
		return
	var saveData = json.data
	
	maze.currentRoomX = saveData["currentRoomX"]
	maze.currentRoomY = saveData["currentRoomY"]
	maze.mazeRooms = saveData["mazeRooms"]
	
	targetFile.close()
	maze.loadRoom()
	print("Loaded save from slot ", saveSlot)

## delete a save
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
			push_error("Failed to delete save file ", saveSlot)
	else:
		# you should not be able to do this
		push_error("Attempted deletion of a save file which does not exist.")
