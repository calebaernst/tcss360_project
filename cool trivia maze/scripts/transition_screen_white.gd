extends CanvasLayer

signal on_transition_white_finished

@onready var white_fade = $WhiteFade
@onready var fade_animation = $FadeAnimation

func _ready():
	white_fade.visible = false
	fade_animation.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name):
	if anim_name == "fade_to_white":
		on_transition_white_finished.emit()
		fade_animation.play("fade_to_normal")
	elif anim_name== "fade_to_normal":
		white_fade.visible = false

func transition_white():
	white_fade.visible = true
	fade_animation.play("fade_to_white")
