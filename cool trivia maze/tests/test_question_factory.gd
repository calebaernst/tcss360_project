extends GutTest

## Load the script resource
const QF_PATH := "res://scripts/question_factory.gd"

var QF: Script      ## the script resource
var _backup_questions: Array = []
var _backup_prevent: bool = false

func before_each() -> void:
	QF = load(QF_PATH)

	## Back up static state (if undefined, fall back to defaults)
	var cur_q = QF.get("questionsArray")
	_backup_questions = cur_q if typeof(cur_q) == TYPE_ARRAY else []
	var cur_p = QF.get("preventDuplicates")
	_backup_prevent = cur_p if typeof(cur_p) == TYPE_BOOL else false

	## Default test data and using the same columns as the DB
	QF.set("questionsArray", [
		{
			"id": 1,
			"question type": "multiple choice",
			"question": "Capital of France?",
			"correct answer": "Paris",
			"incorrect answer(s)": "London;Berlin;Rome",
			"correct message": "Yep",
			"incorrect message": "Nope"
		},
		{
			"id": 2,
			"question type": "true/false",
			"question": "2+2=4",
			"correct answer": "True",
			"incorrect answer(s)": "False",
			"correct message": "Math!",
			"incorrect message": "Try again"
		}
	])
	QF.set("preventDuplicates", false)

func after_each() -> void:
	## Restore static state
	QF.set("questionsArray", _backup_questions.duplicate(true))
	QF.set("preventDuplicates", _backup_prevent)

# ---------------------------------------------------------------------------

func test_getRandomQuestion_returns_object_with_expected_fields() -> void:
	## Make selection deterministic (single row):
	QF.set("questionsArray", [{
		"id": 99,
		"question type": "multiple choice",
		"question": "2 + 2 = ?",
		"correct answer": "4",
		"incorrect answer(s)": "1;2;3",
		"correct message": "Correct!",
		"incorrect message": "Incorrect."
	}])

	var q = QF.call("getRandomQuestion")
	assert_not_null(q, "Factory should return a Question-like object")

	## We don't rely on 'is Question
	## just read the properties we expect your Question to expose.
	assert_eq(q.get("type"), "multiple choice")
	assert_eq(q.get("questionText"), "2 + 2 = ?")
	assert_eq(q.get("correctAnswer"), "4")

func test_preventDuplicates_true_removes_selected_row() -> void:
	QF.set("questionsArray", [
		{"id": 1, "question type": "mc", "question": "Q1", "correct answer": "A", "incorrect answer(s)": "B;C"},
		{"id": 2, "question type": "mc", "question": "Q2", "correct answer": "X", "incorrect answer(s)": "Y;Z"}
	])
	QF.set("preventDuplicates", true)

	var before_size: int = QF.get("questionsArray").size()
	var _q1 = QF.call("getRandomQuestion")
	assert_eq(QF.get("questionsArray").size(), before_size - 1, "Should shrink by 1 after draw with preventDuplicates=true")

	var _q2 = QF.call("getRandomQuestion")
	assert_eq(QF.get("questionsArray").size(), before_size - 2, "Should shrink again after second draw")

func test_preventDuplicates_false_keeps_array_size() -> void:
	QF.set("questionsArray", [
		{"id": 1, "question type": "mc", "question": "Q1", "correct answer": "A", "incorrect answer(s)": "B;C"},
		{"id": 2, "question type": "mc", "question": "Q2", "correct answer": "X", "incorrect answer(s)": "Y;Z"}
	])
	QF.set("preventDuplicates", false)

	var before_size: int = QF.get("questionsArray").size()
	var _q = QF.call("getRandomQuestion")
	assert_eq(QF.get("questionsArray").size(), before_size, "Size should be unchanged when preventDuplicates=false")
