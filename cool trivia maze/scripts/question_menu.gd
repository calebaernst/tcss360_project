extends Control

## Signals for communication with Maze
signal question_answered(selectedAnswer: String)
signal menu_exited()

## instance fields
var myDatabase : SQLite # initialize SQLite database field
var myQuestionChoices : Array # randomly chosen question field
var myAnswerButtons : Array # array of buttons for answers field
var selectedAnswerText: String = ""

## enumerated variable
enum Select {
	submit,
	button1,
	button2,
	button3, 
	button4
}


func _ready() -> void:
	## Don't initialize database here - let the Maze handle question setup
	myAnswerButtons = [$Button, $Button2, $Button3, $Button4] # array of buttons
	set_default()

	## Connect button signals manually if not connected in scene
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

## Called every frame. 'delta' is the elapsed time since the previous frame.
## setter: ensure default button states - declare initial states
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
	for i in range(myAnswerButtons.size()):
		myAnswerButtons[i].disabled = false
	$Submit.disabled = false

## Button signal handlers - UPDATED to emit signals
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

func _on_exit_button_down() -> void:
	menu_exited.emit()

func _process(_delta: float) -> void:
	pass
