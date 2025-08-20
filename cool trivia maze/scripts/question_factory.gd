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
	if questionsArray.is_empty():
		_initialize()
	if questionsArray.is_empty():
		# Fallback if DB is empty
		return Question.new(-1, "multiple choice", "", "", [], "", "")

	var selectedIndex: int = randi_range(0, questionsArray.size() - 1)
	var selectedData: Dictionary = questionsArray[selectedIndex]

	var incorrect_raw = selectedData.get("incorrect answer(s)", [])
	var incorrectAnswers: Array = []
	match typeof(incorrect_raw):
		TYPE_STRING:
			incorrectAnswers = (incorrect_raw as String).split(";")
		TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY:
			incorrectAnswers = incorrect_raw
		_:
			incorrectAnswers = []

	var question := Question.new(
		selectedData.get("id", -1),
		selectedData.get("question type", "multiple choice"),
		selectedData.get("question", ""),
		selectedData.get("correct answer", ""),
		incorrectAnswers,
		selectedData.get("correct message", ""),   # <— safe
		selectedData.get("incorrect message", "")  # <— safe
	)

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
