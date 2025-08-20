extends RefCounted
class_name QuestionFactory

static var db: SQLite 
static var shuffledQuestionsQueue: Array = []
static var backupArray: Array = []

## gets a question from the shuffled factory queue
## because the queue is shuffled, the question is always randomly selected
static func getRandomQuestion() -> Question:
	if backupArray.is_empty(): # load in data if not already
		_loadQuestions()
		if backupArray.is_empty():
			# Fallback if DB is empty
			return Question.new(-1, "multiple choice", "", "", [], "", "")
	if shuffledQuestionsQueue.is_empty(): # if the question queue has run out, reset it
		_resetFactory()
	
	# grab data from the front of the shuffled queue 
	var selectedData: Dictionary = shuffledQuestionsQueue.pop_front()
	# designate incorrect answers
	var incorrect_raw = selectedData.get("incorrect answer(s)", [])
	var incorrectAnswers: Array = []
	match typeof(incorrect_raw):
		TYPE_STRING:
			incorrectAnswers = (incorrect_raw as String).split(";")
		TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY:
			incorrectAnswers = incorrect_raw
		_:
			incorrectAnswers = []

	# construct question with selected data
	var question := Question.new(
		selectedData.get("id", -1),
		selectedData.get("question type", "multiple choice"),
		selectedData.get("question", ""),
		selectedData.get("correct answer", ""),
		incorrectAnswers,
		selectedData.get("correct message", ""),   # <— safe
		selectedData.get("incorrect message", "")  # <— safe
	)
	
	return question

static func _loadQuestions() -> void:
	db = SQLite.new()
	db.path="res://assets/TriviaQuestions.db"
	db.open_db()
	
	backupArray = db.select_rows("Questions", "", ["*"])
	_resetFactory()
	print("Loaded ", shuffledQuestionsQueue.size(), " questions.")
	
	db.close_db()

## resets and reshuffles the question queue to ensure the factory can always output Questions and that the order of output questions is random
static func _resetFactory() -> void:
	shuffledQuestionsQueue = backupArray.duplicate(true)
	shuffledQuestionsQueue.shuffle()
