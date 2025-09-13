## Turn counter UI for tracking game turns
extends CanvasLayer

@export var current_turn: int = 1

@onready var turn_label: Label = $TurnLabel

func _ready() -> void:
	update_turn_display()

## Updates the turn display with current turn number
func update_turn_display() -> void:
	if turn_label:
		turn_label.text = "Turn: " + str(current_turn)

## Advances to the next turn
func next_turn() -> void:
	current_turn += 1
	update_turn_display()
	print("Advanced to turn: ", current_turn)

## Resets turn counter to 1
func reset_turns() -> void:
	current_turn = 1
	update_turn_display()
	print("Turn counter reset to: ", current_turn)

## Sets turn to specific number
func set_turn(turn_number: int) -> void:
	current_turn = max(1, turn_number)
	update_turn_display()
	print("Turn set to: ", current_turn)