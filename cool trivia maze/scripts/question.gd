## Question Object
extends RefCounted
class_name Question

# question instance variables
var id: int
var type: String
var questionText: String
var answerChoices: Array
var correctAnswer: String
var correctMessage: String
var incorrectMessage: String


## question constructor
func _init(theId: int, theType: String, theQuestionText: String, theCorrectAnswer: String, theIncorrectAnswers: Array, theCorrectMessage: String, theIncorrectMessage: String):
	id = theId
	type = theType
	questionText = theQuestionText
	correctAnswer = theCorrectAnswer
	correctMessage = theCorrectMessage
	incorrectMessage = theIncorrectMessage
	
	answerChoices = theIncorrectAnswers.duplicate()
	answerChoices.append(theCorrectAnswer)
	answerChoices.shuffle()

## simple toString method
func _to_string() -> String:
	var output = "Question Data: \n {ID: %d | Type: %s | Text: %s | " % [id, type, questionText]
	if type != "open response":
		output += "Choices: %s | " % str(answerChoices)
	output += "Answer: %s | Correct: %s | Incorrect: %s}" % [correctAnswer, correctMessage, incorrectMessage]
	
	return output

## save/load serialization support (write)
func serialize() -> Dictionary:
	return {
		"questionText": questionText,
		"type": type,
		"answerChoices": answerChoices,
		"correctAnswer": correctAnswer,
		"correctMessage": correctMessage,
		"incorrectMessage": incorrectMessage
	}

## save/load serialization support (read)
static func deserialize(data: Dictionary) -> Question:
	var incorrect_answers = []
	var correct_answer = data.get("correctAnswer", "")
	var answer_choices = data.get("answerChoices", [])
	
	for choice in answer_choices:
		if choice != correct_answer:
			incorrect_answers.append(choice)
	
	var question = Question.new(
		data.get("id", 0),
		data.get("type", ""),
		data.get("questionText", ""),
		correct_answer,
		incorrect_answers,
		data.get("correctMessage", ""),
		data.get("incorrectMessage", "")
	)
	
	return question
