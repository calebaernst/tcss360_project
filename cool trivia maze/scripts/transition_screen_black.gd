## Global Transition Animation player (Fade to Black)
extends CanvasLayer

signal on_transition_black_finished

@onready var black_fade = $BlackFade
@onready var fade_animation = $FadeAnimation

## calls the entire transition
func _ready():
	black_fade.visible = false
	fade_animation.animation_finished.connect(_on_animation_finished)

## handles transition for proper animation
func _on_animation_finished(anim_name):
	if anim_name == "fade_to_black":
		on_transition_black_finished.emit()
		fade_animation.play("fade_to_normal")
	elif anim_name== "fade_to_normal":
		black_fade.visible = false

## plays the fade to black animation
func transition_black():
	black_fade.visible = true
	fade_animation.play("fade_to_black")
