## GridStateManager - Handles grid state and unit placement management
## Extracted from GameBoard.gd for better separation of concerns
class_name GridStateManager
extends Node

signal unit_placed(unit: Unit, cell: Vector2)
signal unit_removed(unit: Unit, cell: Vector2)
signal grid_reinitialized()

## Mapping of coordinates of a cell to a reference to the unit it contains
var _units := {}
var _parent_node: Node

func initialize(parent_node: Node = null) -> void:
	_parent_node = parent_node
	print("GridStateManager: Initialized")

## Returns true if there's a unit at the given cell coordinates
func is_occupied(cell: Vector2) -> bool:
	return _units.has(cell)

## Gets the unit at a specific cell, returns null if no unit
func get_unit_at(cell: Vector2) -> Unit:
	return _units.get(cell)

## Places a unit at a specific cell
func place_unit(unit: Unit, cell: Vector2) -> void:
	if not unit:
		print("GridStateManager: Cannot place null unit")
		return

	# Remove unit from previous position if it exists
	if _units.has(unit.cell):
		_units.erase(unit.cell)

	# Place unit at new position
	_units[cell] = unit
	unit.cell = cell
	emit_signal("unit_placed", unit, cell)

## Removes a unit from the grid
func remove_unit(unit: Unit) -> void:
	if not unit:
		print("GridStateManager: Cannot remove null unit")
		return

	var unit_cell = unit.cell
	if _units.has(unit_cell):
		var unit_at_position = _units[unit_cell]
		if unit_at_position == unit:
			_units.erase(unit_cell)
			emit_signal("unit_removed", unit, unit_cell)
			print("GridStateManager: Removed unit ", unit.name, " from cell ", unit_cell)

## Clears and refills the _units dictionary with game objects that are on the board
func reinitialize_grid() -> void:
	_units.clear()
	print("GridStateManager: Reinitializing grid state...")

	if not _parent_node:
		print("GridStateManager: No parent node set, cannot find units")
		return

	# Find all Unit child nodes (original GameBoard logic)
	var found_units = []
	for child in _parent_node.get_children():
		if child is Unit:
			found_units.append(child)

	print("GridStateManager: Found ", found_units.size(), " units to register")

	for unit in found_units:
		_units[unit.cell] = unit
		print("GridStateManager: Registered unit ", unit.name, " at ", unit.cell)

	emit_signal("grid_reinitialized")
	print("GridStateManager: Grid reinitialization complete - ", _units.size(), " units registered")

## Gets all units currently on the grid
func get_all_units() -> Array:
	return _units.values()

## Gets the units dictionary (for executor compatibility)
func get_units_dict() -> Dictionary:
	return _units

## Gets the number of units on the grid
func get_unit_count() -> int:
	return _units.size()

## Checks if the grid has any units
func has_units() -> bool:
	return _units.size() > 0

## Moves a unit from one cell to another
func move_unit(unit: Unit, from_cell: Vector2, to_cell: Vector2) -> bool:
	if not unit:
		print("GridStateManager: Cannot move null unit")
		return false

	if not _units.has(from_cell) or _units[from_cell] != unit:
		print("GridStateManager: Unit not found at source cell ", from_cell)
		return false

	if is_occupied(to_cell):
		print("GridStateManager: Destination cell ", to_cell, " is occupied")
		return false

	# Remove from old position
	_units.erase(from_cell)

	# Place at new position
	_units[to_cell] = unit
	unit.cell = to_cell

	emit_signal("unit_removed", unit, from_cell)
	emit_signal("unit_placed", unit, to_cell)

	return true