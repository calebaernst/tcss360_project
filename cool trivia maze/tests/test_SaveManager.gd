# This is the unit test file for the Save Manager
extends GutTest

# Declare an instance of a player
var SaveManager = preload("res://scripts/SaveManager.gd")
var save_manager : SaveManager

"""
# Creates instance for each test
func before_each() -> void:
	save_manager = SaveManager.new()
	add_child(save_manager)
	await get_tree().process_frame

# Removes instance for each test
func after_each() -> void:
	save_manager.queue_free()
"""

"""
	remember! 
	all test functions must start with "test_" 
	or else the GUT plugin won't detect your test!
"""
