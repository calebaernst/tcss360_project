extends Node

static var db = _openDatabase()
static var usedIDs: Array = []

static func _openDatabase():
	db = SQLite.new()
	db.path="res://assets/TriviaQuestions.db"
	db.open_db()
