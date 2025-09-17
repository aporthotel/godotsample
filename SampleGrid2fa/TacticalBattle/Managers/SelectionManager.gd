## SelectionManager - Handles unit selection and walkable cell management
## Extracted from GameBoard.gd for better separation of concerns
class_name SelectionManager
extends Node

signal unit_selected(unit: Unit)
signal unit_deselected(unit: Unit)
signal walkable_cells_updated(cells: Array)

var _active_unit: Unit
var _walkable_cells := []
var _movement_executor: MovementExecutor

func initialize(movement_executor: MovementExecutor) -> void:
	_movement_executor = movement_executor
	print("SelectionManager: Initialized")

## Gets the currently active unit
func get_active_unit() -> Unit:
	return _active_unit

## Gets the walkable cells for the active unit
func get_walkable_cells() -> Array:
	return _walkable_cells

## Checks if there is an active unit selected
func has_active_unit() -> bool:
	return _active_unit != null

## Selects a unit and calculates its walkable cells
func select_unit(unit: Unit) -> void:
	if not unit:
		print("SelectionManager: Cannot select null unit")
		return

	# Deselect previous unit if any
	if _active_unit:
		deselect_active_unit()

	# Select new unit
	_active_unit = unit
	_active_unit.is_selected = true
	_walkable_cells = _movement_executor.get_walkable_cells(_active_unit)

	print("SelectionManager: Unit selected - ", _active_unit.name)
	emit_signal("unit_selected", _active_unit)
	emit_signal("walkable_cells_updated", _walkable_cells)

## Deselects the currently active unit
func deselect_active_unit() -> void:
	if not _active_unit:
		print("SelectionManager: Warning - deselect called but no active unit")
		return

	var deselected_unit = _active_unit
	_active_unit.is_selected = false

	emit_signal("unit_deselected", deselected_unit)
	print("SelectionManager: Unit deselected - ", deselected_unit.name)

## Clears the active unit and walkable cells
func clear_selection() -> void:
	_active_unit = null
	_walkable_cells.clear()
	emit_signal("walkable_cells_updated", _walkable_cells)
	print("SelectionManager: Selection cleared")

## Checks if a cell is walkable by the active unit
func is_cell_walkable(cell: Vector2i) -> bool:
	# NOTE: MovementExecutor returns Vector2 walkable cells, but GameBoard passes Vector2i
	# Convert Vector2i to Vector2 for proper array comparison
	# TECHNICAL DEBT: Coordinate system mixed types - flood_fill uses logical coordinates
	# but returns Vector2. Godot auto-rounds fractional coordinates in practice.
	# Tested with odd cell_sizes (33x33) - only visual offset issues, no logic errors.
	return Vector2(cell) in _walkable_cells

## Updates walkable cells for the current active unit (useful after movement)
func refresh_walkable_cells() -> void:
	if not _active_unit or not _movement_executor:
		return

	_walkable_cells = _movement_executor.get_walkable_cells(_active_unit)
	emit_signal("walkable_cells_updated", _walkable_cells)

## Called when a unit dies - clear selection if it was the active unit
func handle_unit_death(dead_unit: Unit) -> void:
	if _active_unit == dead_unit:
		print("SelectionManager: Active unit died, clearing selection")
		clear_selection()