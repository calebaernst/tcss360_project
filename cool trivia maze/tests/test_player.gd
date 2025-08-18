# This is the unit test file for the player
extends GutTest

# Declare an instance of a player
var PlayerInst = preload("res://scripts/player.gd")
var player : Player

# Mock classes for AnimationTree and Playback
class MockAnimationTree extends AnimationTree:
	var params = {
		"parameters/playback": null,
		"parameters/Idle/blend_position": Vector2.ZERO,
		"parameters/Walk/blend_position": Vector2.ZERO
	}    

	func _set(property, value):
		params[property] = value
		return true

	func _get(property):
		return params.get(property, null)

	func __setitem__(property, value):
		params[property] = value

	func __getitem__(property):
		return params.get(property, null)

class MockPlayback extends AnimationNodeStateMachinePlayback:
	var current_node = "Idle"
	func mock_travel(to_node: StringName, _reset: bool = false) -> void:
		current_node = to_node
	func get_mock_current_node() -> String:
		return current_node

# Creates instance for each test
func before_each() -> void:
	player = PlayerInst.new()
	player.animation_tree = MockAnimationTree.new() 
	player.playback = MockPlayback.new() 
	player.animation_tree.params["parameters/playback"] = player.playback
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

# Test player speed 
func test_initial_speed():
	assert_eq(player.SPEED, 100.0, "Player speed should be initialized to 100.0")

func test_run_active_increases_speed():
	Input.action_press("run")
	player.runActive()
	assert_eq(player.SPEED, 200.0, "Player speed should be 200.0 when run is pressed")
	Input.action_release("run")

func test_run_active_resets_speed():
	Input.action_press("run")
	player.runActive()
	Input.action_release("run")
	player.runActive()
	assert_eq(player.SPEED, 100.0, "Player speed should reset to 100.0 when run is released")

func test_velocity_calculation():
	Input.action_press("right")	# Simulate pressing the right key
	player.SPEED = 100.0
	player._physics_process(0.016)
	assert_eq(player.velocity, Vector2(100, 0), "Velocity should be input * SPEED")
	Input.action_release("right")	# Clean up after test
