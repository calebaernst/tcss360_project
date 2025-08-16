extends Control

@export var save_select_scene: PackedScene = preload("res://scenes/save_select.tscn")

func _ready():
	# Make sure input is processed even without UI focus
	set_process_input(true)
	#AudioPlayer.play_music_menu()

func _input(event: InputEvent) -> void:
	# Any keyboard press
	if event is InputEventKey and event.pressed and not event.echo:
		_go_to_save_select()
	# Any mouse click
	elif event is InputEventMouseButton and event.pressed:
		_go_to_save_select()

func _go_to_save_select():
	if save_select_scene:
		get_tree().change_scene_to_packed(save_select_scene)
