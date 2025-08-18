# This is the unit test file for the Maze
extends GutTest

# Declare an instance of a player
var Maze = preload("res://scripts/Maze.gd")
var maze : Maze

# Creates instance for each test
func before_each() -> void:
	maze = Maze.new()
	add_child(maze)
	await get_tree().process_frame

# Removes instance for each test
func after_each() -> void:
	maze.queue_free()

"""
	remember!
	all test functions must start with "test_" 
	or else the GUT plugin won't detect your test!
"""
