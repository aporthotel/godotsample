## BaseExecutor - Shared functionality for all action executors
## Provides common infrastructure for movement, combat, skills, and items
class_name BaseExecutor
extends Node

# Shared signals for all action types
signal action_completed(action_type: String, unit: Unit)
signal unit_died(unit: Unit)

# Shared game state references
var _grid: Grid
var _units: Dictionary  # Reference to GameBoard's units dictionary

# Shared visual components
var _unit_overlay: UnitOverlay
var _unit_path: UnitPath
var _attack_overlay: AttackOverlay

## Common initialization for all executors
func initialize(grid: Grid, units_dict: Dictionary,
				unit_overlay: UnitOverlay, unit_path: UnitPath, attack_overlay: AttackOverlay) -> void:
	_grid = grid
	_units = units_dict
	_unit_overlay = unit_overlay
	_unit_path = unit_path
	_attack_overlay = attack_overlay

	print("BaseExecutor: Base initialization completed")

## Validates if a unit is valid for action (basic check only)
func is_valid_unit(unit: Unit) -> bool:
	if not unit or not is_instance_valid(unit):
		print("BaseExecutor: Action failed - invalid unit")
		return false

	return true

## Checks if a cell is occupied by any unit
func _is_cell_occupied(cell: Vector2) -> bool:
	return _units.has(cell)

## Gets the unit at a specific cell, returns null if no unit
func get_unit_at_cell(cell: Vector2) -> Unit:
	return _units.get(cell)

## Gets all units on the board as an array
func get_all_units() -> Array[Unit]:
	var units: Array[Unit] = []
	for unit in _units.values():
		if is_instance_valid(unit):
			units.append(unit)
	return units

## Removes a dead unit from the board (shared cleanup logic)
func remove_unit_from_board(unit: Unit) -> void:
	if not unit:
		print("BaseExecutor: Cannot remove null unit")
		return

	print("BaseExecutor: Removing unit ", unit.name, " from board")

	# Find and remove unit from units dictionary
	var unit_pos = unit.cell
	if _units.has(unit_pos):
		_units.erase(unit_pos)
		print("BaseExecutor: Unit removed from position ", unit_pos)

## Emits action completed signal (standardized across all executors)
func emit_action_completed(action_type: String, unit: Unit) -> void:
	emit_signal("action_completed", action_type, unit)
	print("BaseExecutor: Action '", action_type, "' completed for ", unit.name)

## Emits unit died signal (standardized across all executors)
func emit_unit_died(unit: Unit) -> void:
	emit_signal("unit_died", unit)
	print("BaseExecutor: Unit died signal emitted for ", unit.name)

## Virtual method for executor-specific initialization (override in subclasses)
func _setup_executor() -> void:
	pass
