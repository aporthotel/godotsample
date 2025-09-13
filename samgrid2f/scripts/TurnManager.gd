## Turn sequence manager for handling team-based turn order
class_name TurnManager
extends Node

## Team order priority (lower number = earlier turn)
enum TeamOrder {
	PLAYER_TEAM = 0,
	ENEMY_TEAM = 1, 
	CRITTER_TEAM = 2
}

## Signal emitted when turn changes
signal turn_changed(current_unit: Unit, turn_number: int)
signal round_completed(round_number: int)

## Current round number
var current_round: int = 1
## Current turn within the round
var current_turn_index: int = 0
## Array of all units sorted by turn order
var turn_order: Array[Unit] = []
## Currently active unit
var active_unit: Unit

func _ready() -> void:
	print("TurnManager initialized")

## Registers a unit in the turn order system
func register_unit(unit: Unit) -> void:
	if unit and unit not in turn_order:
		turn_order.append(unit)
		_sort_turn_order()
		print("Registered unit: ", unit.name, " Type: ", unit.unit_type)

## Removes a unit from turn order (when unit dies/is removed)
func unregister_unit(unit: Unit) -> void:
	if unit in turn_order:
		turn_order.erase(unit)
		print("TurnManager: Unregistered unit: ", unit.name)

## Sorts turn order by team priority, then by unit name for consistency
func _sort_turn_order() -> void:
	turn_order.sort_custom(_compare_turn_order)

## Custom comparison function for turn order sorting
func _compare_turn_order(a: Unit, b: Unit) -> bool:
	var team_a = _get_team_order(a.unit_type)
	var team_b = _get_team_order(b.unit_type)
	
	# First sort by team order
	if team_a != team_b:
		return team_a < team_b
	
	# Then sort by unit name for consistency within same team
	return a.name < b.name

## Maps unit type to team order priority
func _get_team_order(unit_type: Unit.UnitType) -> TeamOrder:
	match unit_type:
		Unit.UnitType.UNIT_PLAYER:
			return TeamOrder.PLAYER_TEAM
		Unit.UnitType.UNIT_CPU:
			return TeamOrder.ENEMY_TEAM
		Unit.UnitType.UNIT_NPC:
			return TeamOrder.CRITTER_TEAM
		_:
			return TeamOrder.CRITTER_TEAM

## Starts the turn sequence
func start_turn_sequence() -> void:
	if turn_order.is_empty():
		print("No units registered for turn sequence")
		return
	
	current_round = 1
	current_turn_index = 0
	print("Turn sequence started - Round ", current_round)
	_activate_current_unit()

## Advances to the next turn
func next_turn() -> void:
	if turn_order.is_empty():
		return
	
	# Deactivate current unit
	if active_unit:
		_deactivate_unit(active_unit)
	
	current_turn_index += 1
	
	# Check if round is complete
	if current_turn_index >= turn_order.size():
		current_turn_index = 0
		current_round += 1
		round_completed.emit(current_round)
		print("Round ", current_round - 1, " completed. Starting round ", current_round)
	
	_activate_current_unit()

## Activates the current unit in turn order
func _activate_current_unit() -> void:
	if current_turn_index < turn_order.size():
		active_unit = turn_order[current_turn_index]
		_activate_unit(active_unit)
		# Calculate turn number: each complete cycle is a round
		var total_turn = (current_round - 1) * turn_order.size() + current_turn_index + 1
		turn_changed.emit(active_unit, total_turn)
		print("Turn ", total_turn, " - ", active_unit.name, " (", Unit.UnitType.keys()[active_unit.unit_type], ")")

## Activates a unit for their turn
func _activate_unit(unit: Unit) -> void:
	if unit.unit_type == Unit.UnitType.UNIT_PLAYER:
		# Player units can be controlled
		print("Player turn: ", unit.name, " - waiting for input")
		# Player turn waits for manual input (no auto-advance)
	elif unit.unit_type == Unit.UnitType.UNIT_CPU:
		# AI units perform circular movement pattern
		print("AI turn: ", unit.name, " - moving in circle pattern")
		_perform_ai_movement(unit)
		await get_tree().create_timer(1.0).timeout
		next_turn()
	elif unit.unit_type == Unit.UnitType.UNIT_NPC:
		# NPCs perform same circular movement as AI
		print("NPC turn: ", unit.name, " - moving in circle pattern")
		_perform_ai_movement(unit)
		await get_tree().create_timer(1.0).timeout
		next_turn()

## Performs circular movement for AI/NPC units (up, right, down, left)
func _perform_ai_movement(unit: Unit) -> void:
	if not unit:
		return
	
	# Initialize movement step if not set
	if not unit.has_meta("movement_step"):
		unit.set_meta("movement_step", 0)
	
	var movement_step = unit.get_meta("movement_step")
	var directions = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	var direction = directions[movement_step % 4]
	
	# Calculate new position
	var new_cell = unit.cell + direction
	
	# Check if new position is valid and not occupied
	var game_board = unit.get_parent()
	if game_board and game_board.has_method("is_occupied"):
		# Make sure we're within grid bounds
		if unit.grid.is_within_bounds(new_cell) and not game_board.is_occupied(new_cell):
			# Update unit dictionary in GameBoard
			game_board._units.erase(unit.cell)
			game_board._units[new_cell] = unit
			
			# Create simple path for movement
			var path = PackedVector2Array([new_cell])
			unit.walk_along(path)
			
			print(unit.name, " moved ", ["up", "right", "down", "left"][movement_step % 4], " to ", new_cell)
		else:
			print(unit.name, " cannot move ", ["up", "right", "down", "left"][movement_step % 4], " - blocked or out of bounds")
	
	# Advance to next direction in circle
	unit.set_meta("movement_step", movement_step + 1)

## Deactivates a unit after their turn
func _deactivate_unit(unit: Unit) -> void:
	# Reset unit state after turn
	if unit:
		print("Deactivating: ", unit.name)

## Ends the current turn (called by player or AI)
func end_current_turn() -> void:
	if active_unit:
		print("Turn ended for: ", active_unit.name)
		next_turn()

## Gets information about current turn
func get_turn_info() -> Dictionary:
	var total_turn = 0
	if not turn_order.is_empty():
		total_turn = (current_round - 1) * turn_order.size() + current_turn_index + 1
	
	return {
		"round": current_round,
		"turn_in_round": current_turn_index + 1,
		"total_turn": total_turn,
		"active_unit": str(active_unit.name) if active_unit != null else str("None"),
		"total_units": turn_order.size()
	}
