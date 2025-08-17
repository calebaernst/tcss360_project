# This is the unit test file for the player
extends GutTest

# Declare an instance of a player
var Player = preload("res://scripts/player.gd")
var player : Player

# Creates instance for each test
func before_each() -> void:
	player = Player.new()
	add_child(player)
	await get_tree().process_frame

# Removes instance for each test
func after_each() -> void:
	player.queue_free()

"""
	remember! 
	all test functions must start with "test_" 
	or else the GUT plugin won't detect your test!
"""

func test_initial_speed() -> void:
	assert_eq(player.SPEED, 100.0, "Player speed should be initialized to 100.0")

func test_run_button_increases_speed() -> void:
	Input.action_press("run")
	player.runActive()
	assert_eq(player.SPEED, 200.0, "Player speed should be 200.0 when run is pressed")
	Input.action_release("run")

func test_run_button_releases_speed() -> void:
	Input.action_press("run")
	player.runActive()
	Input.action_release("run")
	player.runActive()
	assert_eq(player.SPEED, 100.0, "Player speed should return to 100.0 when run is released")

func test_idle_animation_when_not_moving() -> void:
	player.velocity = Vector2.ZERO
	player.select_animation()
	assert_eq(player.playback.get_current_node(), "Idle", "Player should play Idle animation when not moving")

func test_walk_animation_when_moving() -> void:
	player.velocity = Vector2(1, 0)
	player.select_animation()
	assert_eq(player.playback.get_current_node(), "Walk", "Player should play Walk animation when moving")

func test_blend_position_updates() -> void:
	player.input = Vector2(1, 0)
	player.update_animation_parameters()
	assert_eq(player.animation_tree["parameters/Idle/blend_position"], Vector2(1, 0), "Idle blend_position should update")
	assert_eq(player.animation_tree["parameters/Walk/blend_position"], Vector2(1, 0), "Walk blend_position should update")
