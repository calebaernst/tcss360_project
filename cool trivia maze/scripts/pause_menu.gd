extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	testEsc()


func _on_save_game_button_down() -> void:
	pass # Replace with function body.


func _on_quit_button_down() -> void:
	get_tree().quit()


func _on_resume_button_down() -> void:
	set_resume()

# setter: resume game
func set_resume() -> void:
	get_tree().paused = false
	$play_blur.play_backwards("blur_animation")

# setter: pause game
func set_pause() -> void:
	get_tree().paused = true
	$play_blur.play("blur_animation")

func testEsc():
	if Input.is_action_just_pressed("pause") and get_tree().paused == false:
		set_pause()
	elif Input.is_action_just_pressed("pause") and get_tree().paused == true:
		set_resume()
