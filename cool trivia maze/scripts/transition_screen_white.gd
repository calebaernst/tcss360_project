## Global Transition Animation player (Fade to White)
extends CanvasLayer

signal on_transition_white_finished

@onready var white_fade = $WhiteFade
@onready var fade_animation = $FadeAnimation

## calls the entire transition
func _ready():
	white_fade.visible = false
	fade_animation.animation_finished.connect(_on_animation_finished)

## handles transition for proper animation
func _on_animation_finished(anim_name):
	if anim_name == "fade_to_white":
		on_transition_white_finished.emit()
		fade_animation.play("fade_to_normal")
	elif anim_name== "fade_to_normal":
		white_fade.visible = false

## plays the fade to white animation
func transition_white():
	white_fade.visible = true
	fade_animation.play("fade_to_white")
