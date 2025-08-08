extends RefCounted
class_name QuestionFactory

# set to false if not enough questions in database to fill maze; cannot be marked with @export
static var preventDuplicates: bool = false

static var db: SQLite 
static var questionsArray: Array = []

# this basically is to be treated as _init, but _init functions are automatically called on instantiation while this script/node is never instantiated
## runs the functions to load in the question data (should only ever run once per game)
static func _initialize() -> void:
	_openDatabase()
	_loadQuestions()

## gets a random question, and removes it from the array if preventDuplicates is true
static func getRandomQuestion() -> Question:
	if not questionsArray: # load in data if not already
		_initialize()
	
	# select random row and grab its data
	var selectedIndex = randi_range(0, questionsArray.size() - 1)
	var selectedData = questionsArray[selectedIndex]
	var incorrectAnswers = selectedData["incorrect answer(s)"].split(";")
	# construct question
	var question = Question.new(selectedData["id"], selectedData["question type"], selectedData["question"], selectedData["correct answer"], incorrectAnswers, selectedData["correct message"], selectedData["incorrect message"])
	
	# remove the question data from the array if we want to prevent duplicates
	if preventDuplicates:
		questionsArray.remove_at(selectedIndex)
	
	return question

static func _openDatabase() -> void:
	db = SQLite.new()
	db.path="res://assets/TriviaQuestions.db"
	db.open_db()

static func _loadQuestions():
	questionsArray = db.select_rows("Questions", "", ["*"])
	print("Loaded ", questionsArray.size(), " questions.")
