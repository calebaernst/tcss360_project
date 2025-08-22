# Player Object
class_name Player extends CharacterBody2D

# Fields
@export var SPEED : float = 100.0
@export var animation_tree : AnimationTree
var input : Vector2
var playback : AnimationNodeStateMachinePlayback

# On ready function 
func _ready():
	# activates animations
	playback = animation_tree["parameters/playback"]

# Controls the player
func _physics_process(_delta: float) -> void:
	# get WASD input
	input = Input.get_vector("left", "right", "up", "down")
	
	velocity = input * SPEED

	move_and_slide()
	select_animation()
	update_animation_parameters()
	runActive()
	
## Handles animation of player
func select_animation():
	if velocity == Vector2.ZERO:
		playback.travel("Idle")
	else:
		playback.travel("Walk")

## Updates animations
func update_animation_parameters():
	if input == Vector2.ZERO:
		return
	animation_tree["parameters/Idle/blend_position"] = input
	animation_tree["parameters/Walk/blend_position"] = input

## Checks if player is holding down the run button
func runActive():
	if Input.is_action_pressed("run"):
		SPEED = 200.0
	else:
		SPEED = 100.0
