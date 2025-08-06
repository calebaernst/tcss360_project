extends Node

static var db = _openDatabase()
static var totalQuestions = get_table_count()
static var usedIDs: Array = []

static func _openDatabase():
	db = SQLite.new()
	db.path="res://assets/TriviaQuestions.db"
	db.open_db()

# getter: gets total amount of rows in a table
static func get_table_count() -> int:
	var output = 0
	db.query("select * from Questions")
	for i in db.query_result:
		output += 1
	return output
