## Handles volume control for user to use
extends HSlider

@export var bus_name: String

var bus_index: int

## connects slider to bus and tracks changes
func _ready() -> void:
	bus_index = AudioServer.get_bus_index(bus_name)
	value_changed.connect(_on_value_changed)
	value = db_to_linear(
		AudioServer.get_bus_volume_db(bus_index)
	)

## handles volume changes
func _on_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		bus_index,
		linear_to_db(value)
	)
