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
	if shuffledQuestionsQueue.is_empty(): # if the question queue has run out, reset it
		_resetFactory()
	
	var selectedData = shuffledQuestionsQueue.pop_front()
	# construct question
	var question = Question.new(selectedData["id"], selectedData["question type"], selectedData["question"], selectedData["correct answer"], selectedData["incorrect answer(s)"].split(";"), selectedData["correct message"], selectedData["incorrect message"])
	
	return question

## loads in the database and saves its contents to an array
## this should only ever be run once per game
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
