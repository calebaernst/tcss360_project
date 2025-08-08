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

func _to_string() -> String:
	var output = "Question Data: \n {ID: %d | Type: %s | Text: %s | " % [id, type, questionText]
	if type != "open response":
		output += "Choices: %s | " % str(answerChoices)
	output += "Answer: %s | Correct: %s | Incorrect: %s}" % [correctAnswer, correctMessage, incorrectMessage]
	
	return output
