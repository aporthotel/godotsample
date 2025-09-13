## Debug UI for tracking and debugging game numbers
extends CanvasLayer

@onready var debug_label: Label = $DebugPanel/DebugLabel

var fps_counter: int = 0
var unit_count: int = 0
var current_turn: int = 1
var selected_unit_name: String = "None"
var unit_state: String = "No Selection"

func _ready() -> void:
	update_debug_info()

func _process(_delta: float) -> void:
	# Update FPS every few frames to avoid flickering
	fps_counter += 1
	if fps_counter % 30 == 0:
		update_debug_info()

## Updates all debug information display
func update_debug_info() -> void:
	if debug_label:
		var fps = Engine.get_frames_per_second()
		var debug_text = "Debug Info:\n"
		debug_text += "FPS: " + str(fps) + "\n"
		debug_text += "Units: " + str(unit_count) + "\n"
		debug_text += "Turn: " + str(current_turn) + "\n"
		debug_text += "Selected: " + selected_unit_name + "\n"
		debug_text += "State: " + unit_state
		debug_label.text = debug_text

## Sets the unit count for display
func set_unit_count(count: int) -> void:
	unit_count = count
	update_debug_info()

## Sets the current turn for display
func set_current_turn(turn: int) -> void:
	current_turn = turn
	update_debug_info()

## Sets the selected unit name for display
func set_selected_unit(unit_name: String) -> void:
	selected_unit_name = unit_name
	update_debug_info()

## Sets the unit state for display
func set_unit_state(state: String) -> void:
	unit_state = state
	update_debug_info()

## Adds a custom debug line
func add_debug_line(key: String, value: String) -> void:
	if debug_label:
		debug_label.text += "\n" + key + ": " + value