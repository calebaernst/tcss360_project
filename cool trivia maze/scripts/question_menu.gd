extends Control

<<<<<<< Updated upstream
# instance fields
var db : SQLite # initialize SQLite database field
var question_choices : Array # randomly chosen question field
var answer_buttons : Array # array of buttons for answers field
=======
## Signals for communication with Maze
signal question_answered(selectedAnswer: String)
signal menu_exited()

## instance fields
var myDatabase : SQLite # initialize SQLite database field
var myQuestionChoices : Array # randomly chosen question field
var myAnswerButtons : Array # array of buttons for answers field
var selectedAnswerText: String = ""

# enumerated variable
enum Select {
	submit,
	button1,
	button2,
	button3, 
	button4
}
>>>>>>> Stashed changes

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Don't initialize database here - let the Maze handle question setup
	myAnswerButtons = [$Button, $Button2, $Button3, $Button4] # array of buttons
	set_default()
	
	# Connect button signals manually if not connected in scene
	if not $Button.button_down.is_connected(_on_button_button_down):
		$Button.button_down.connect(_on_button_button_down)
	if not $Button2.button_down.is_connected(_on_button_2_button_down):
		$Button2.button_down.connect(_on_button_2_button_down)
	if not $Button3.button_down.is_connected(_on_button_3_button_down):
		$Button3.button_down.connect(_on_button_3_button_down)
	if not $Button4.button_down.is_connected(_on_button_4_button_down):
		$Button4.button_down.connect(_on_button_4_button_down)
	if not $Submit.button_down.is_connected(_on_submit_button_down):
		$Submit.button_down.connect(_on_submit_button_down)
	if not $Exit.button_down.is_connected(_on_exit_button_down):
		$Exit.button_down.connect(_on_exit_button_down)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

<<<<<<< Updated upstream
# "constructor": opens the database
func open_database():
	db = SQLite.new()
	db.path="res://TriviaQuestions.db"
	db.open_db()

# constructor: puts the menu together
func build_menu():
	answer_buttons = [$Button, $Button2, $Button3, $Button4] # array of buttons
	question_choices = get_question()
	$Label.text = question_choices[0]["question"] 
	set_default()
	var question_type = get_type()
	if (question_type != "open response"):
		var choices = get_answers(question_choices)
		choices.shuffle()
		set_buttons(choices, question_type)

# getter: gets the type of the question
func get_type() -> String:
	var type : String = question_choices[0]["question type"] 
	match type:
		"multiple choice":
			$Button3.visible = true
			$Button4.visible = true 
		"open response":
			$Button.visible = false
			$Button2.visible = false
			$Response.visible = true
			$Submit.visible = true
	return type

# getter: gets all of the answers of the question and puts them in an array
func get_answers(theQues : Array) -> Array:
	var correctAns = theQues[0]["correct answer"]
	var incorrectAns = theQues[0]["incorrect answer(s)"]
	var answers = incorrectAns.split(";")
	answers.append(correctAns)
	return answers

# getter: randomly selects a question from the database
func get_question() -> Array:
	var max_count = get_table_count()
	var rng = RandomNumberGenerator.new() # declare rng
	var randNum = rng.randi_range(1, max_count) # get random integer
	# select all rows random id
	var array = db.select_rows("Questions", "id ='" + str(randNum) + "'", ["*"])
	return array

# getter: gets total amount of rows in a table
func get_table_count() -> int:
	var output = 0
	db.query("select * from Questions")
	for i in db.query_result:
		output += 1
	return output

# setter: enseure default button states
=======
>>>>>>> Stashed changes
func set_default():
	# default visibility
	$Response.visible = false
	$Button.visible = true
	$Button2.visible = true
	$Button3.visible = false
	$Button4.visible = false 
	$Submit.visible = false
	$Exit.visible = true  # Always show exit button
	
	# default active
	for i in range(answer_buttons.size()):
		answer_buttons[i].disabled = false
	$Submit.disabled = false

<<<<<<< Updated upstream
# setter: deactivates buttons
func set_inactive() -> void:
	for i in range(answer_buttons.size()):
		answer_buttons[i].disabled = true
	$Submit.disabled = true

# setter: sets the buttons
func set_buttons(theChoices : Array, theType : String) -> void:
	var button_amount : int = answer_buttons.size()
	
	if (theType == "true/false"):
		button_amount = 2

	button_amount = min(button_amount, theChoices.size()) # ensure button amount does not exceed choices
	
	for i in range(button_amount):
		answer_buttons[i].text = theChoices[i] # set button text to answer

# verifier: checks if answer is correct and prints correct/incorrect message
func check_answer(theInput : int) -> void:
	var is_correct : bool = false
	if (theInput == 0): # if the user submitted an open response
		is_correct = $Response.text == question_choices[0]["correct answer"]
	else:
		var selected_button = answer_buttons[theInput - 1]
		is_correct = selected_button.text == question_choices[0]["correct answer"]
	
	if (is_correct):
		$Label.text = question_choices[0]["correct message"]
	else:
		$Label.text = question_choices[0]["incorrect message"]
	
	set_inactive()
	$Exit.visible = true

# the following functions are called when the user presses their respective buttons
func _on_button_button_down() -> void: # Button node 1 (top right)
	check_answer(1)

func _on_button_2_button_down() -> void: # Button node 2 (top left)
	check_answer(2)

func _on_button_3_button_down() -> void: # Button node 3 (bottom right)
	check_answer(3)

func _on_button_4_button_down() -> void: # Button node 4 (bottom left)
	check_answer(4)

func _on_submit_button_down() -> void:
	check_answer(0)
=======
# Button signal handlers - UPDATED to emit signals
func _on_button_button_down() -> void:
	selectedAnswerText = $Button.text
	question_answered.emit(selectedAnswerText)

func _on_button_2_button_down() -> void:
	selectedAnswerText = $Button2.text
	question_answered.emit(selectedAnswerText)

func _on_button_3_button_down() -> void:
	selectedAnswerText = $Button3.text
	question_answered.emit(selectedAnswerText)

func _on_button_4_button_down() -> void:
	selectedAnswerText = $Button4.text
	question_answered.emit(selectedAnswerText)

func _on_submit_button_down() -> void:
	selectedAnswerText = $Response.text
	question_answered.emit(selectedAnswerText)
>>>>>>> Stashed changes

func _on_exit_button_down() -> void:
	menu_exited.emit()
	
# "constructor": opens the database
#func open_database():
	#myDatabase = SQLite.new()
	#myDatabase.path="res://TriviaQuestions.db"
	#myDatabase.open_db()
#
## constructor: puts the menu together
#func build_menu():
	#myAnswerButtons = [$Button, $Button2, $Button3, $Button4] # array of buttons
	#myQuestionChoices = get_question()
	#$Label.text = myQuestionChoices[0]["question"]
	#set_default()
	#var question_type : String = get_type()
	#if (question_type != "open response"):
		#var choices = get_answers(myQuestionChoices)
		#choices.shuffle()
		#set_buttons(choices, question_type)
#
## getter: gets the type of the question
#func get_type() -> String:
	#var type : String = myQuestionChoices[0]["question type"] 
	#match type:
		#"multiple choice":
			#$Button3.visible = true
			#$Button4.visible = true 
		#"open response":
			#$Button.visible = false
			#$Button2.visible = false
			#$Response.visible = true
			#$Submit.visible = true
	#return type
#
## getter: gets all of the answers of the question and puts them in an array
#func get_answers(theQues : Array) -> Array:
	#var correctAns = theQues[0]["correct answer"]
	#var incorrectAns = theQues[0]["incorrect answer(s)"]
	#var answers = incorrectAns.split(";")
	#answers.append(correctAns)
	#return answers
#
## getter: randomly selects a question from the database
#func get_question() -> Array:
	#var max_count : int = get_table_count()
	#var rng : Object = RandomNumberGenerator.new() # declare rng
	#var randNum : int = rng.randi_range(1, max_count) # get random integer
	## select all rows random id
	#var array : Array = myDatabase.select_rows("Questions", "id ='" + str(randNum) + "'", ["*"])
	#return array
#
## getter: gets total amount of rows in a table
#func get_table_count() -> int:
	#var output = 0
	#myDatabase.query("select * from Questions")
	#for i in myDatabase.query_result:
		#output += 1
	#return output
#
## setter: ensure default button states - declare initial states
#func set_default():
	## default visibility
	#$Response.visible = false
	#$Button.visible = true
	#$Button2.visible = true
	#$Button3.visible = false
	#$Button4.visible = false 
	#$Submit.visible = false
	#$Exit.visible = false
	#
	## default active
	#for i in range(myAnswerButtons.size()):
		#myAnswerButtons[i].disabled = false
	#$Submit.disabled = false
	#$Response.text = "" # clear the input box
#
## setter: deactivates buttons
#func set_inactive() -> void:
	#for i in range(myAnswerButtons.size()):
		#myAnswerButtons[i].disabled = true
	#$Submit.disabled = true
#
## setter: sets the buttons
#func set_buttons(theChoices : Array, theType : String) -> void:
	#var button_amount : int = myAnswerButtons.size()
	#
	#if (theType == "true/false"):
		#button_amount = 2
#
	#button_amount = min(button_amount, theChoices.size()) # ensure button amount does not exceed choices
	#
	#for i in range(button_amount):
		#myAnswerButtons[i].text = theChoices[i] # set button text to answer
#
## verifier: checks if answer is correct and prints correct/incorrect message
#func check_answer(theInput : Select) -> void:
	#var is_correct : bool = false
	#if (theInput == 0): # if the user submitted an open response
		#is_correct = $Response.text == myQuestionChoices[0]["correct answer"]
	#else:
		#var selected_button = myAnswerButtons[theInput - 1]
		#is_correct = selected_button.text == myQuestionChoices[0]["correct answer"]
	#
	#if (is_correct):
		#$Label.text = myQuestionChoices[0]["correct message"]
		#print("The answer is correct!")
	#else:
		#$Label.text = myQuestionChoices[0]["incorrect message"]
		#print("The answer is INCORRECT")
	#
	#set_inactive()
	#$Exit.visible = true
#
## the following functions are called when the user presses their respective buttons
#func _on_button_button_down() -> void: # Button node 1 (top right)
	#check_answer(Select.button1) 
#
#func _on_button_2_button_down() -> void: # Button node 2 (top left)
	#check_answer(Select.button2)
#
#func _on_button_3_button_down() -> void: # Button node 3 (bottom right)
	#check_answer(Select.button3)
#
#func _on_button_4_button_down() -> void: # Button node 4 (bottom left)
	#check_answer(Select.button4)
#
#func _on_submit_button_down() -> void:
	#check_answer(Select.submit)
#
#func _on_exit_button_down() -> void:
	#build_menu()
	##replace with scene change
