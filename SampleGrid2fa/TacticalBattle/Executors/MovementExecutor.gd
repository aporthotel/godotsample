## MovementExecutor - Handles all movement and pathfinding logic
## Extends BaseExecutor with movement-specific functionality
class_name MovementExecutor
extends BaseExecutor

## Executor-specific initialization
func _setup_executor() -> void:
	print("MovementExecutor: Movement executor initialized")

## Calculates and returns the cells a unit can walk to
func get_walkable_cells(unit: Unit) -> Array:
	if not unit or not is_instance_valid(unit):
		print("MovementExecutor: Cannot get walkable cells - invalid unit")
		return []

	return _flood_fill(unit.cell, unit.get_movement_range())

## Returns an array with all the coordinates of walkable cells based on the max_distance (flood fill algorithm)
func _flood_fill(cell: Vector2, max_distance: int) -> Array:
	const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	var array := []
	var stack := [cell]

	while not stack.size() == 0:
		var current = stack.pop_back()
		if not _grid.is_within_bounds(current):
			continue
		if current in array:
			continue

		var difference: Vector2 = (current - cell).abs()
		var distance := int(difference.x + difference.y)
		if distance > max_distance:
			continue

		array.append(current)
		for direction in DIRECTIONS:
			var coordinates: Vector2 = current + direction
			if _is_cell_occupied(coordinates):
				continue
			if coordinates in array:
				continue
			if coordinates in stack:
				continue

			stack.append(coordinates)
	return array

## Executes unit movement to a new cell
func execute_movement(unit: Unit, target_cell: Vector2) -> bool:
	if not unit or not is_instance_valid(unit):
		print("MovementExecutor: Movement failed - invalid unit")
		return false

	# Validate movement target
	if _is_cell_occupied(target_cell):
		print("MovementExecutor: Movement failed - cell occupied")
		return false

	var walkable_cells = get_walkable_cells(unit)
	if not target_cell in walkable_cells:
		print("MovementExecutor: Movement failed - cell not walkable")
		return false

	# Consume AP for movement (includes built-in validation)
	if not unit.consume_ap(unit.stats.movement_cost):
		print("MovementExecutor: Movement failed - not enough AP")
		return false

	print("MovementExecutor: Executing movement for ", unit.name, " to ", target_cell)

	# Update units dictionary
	_units.erase(unit.cell)
	_units[target_cell] = unit

	# Calculate and execute path using PathFinder
	# Reuse walkable_cells from validation above
	var pathfinder = PathFinder.new(_grid, walkable_cells)
	var path = pathfinder.calculate_point_path(unit.cell, target_cell)
	_unit_path.current_path = path

	# Start movement animation
	unit.walk_along(_unit_path.current_path)
	await unit.walk_finished

	# Use BaseExecutor's standardized completion signal
	emit_action_completed("move", unit)
	return true

## Gets movement range for external systems (like overlay rendering)
func get_movement_range_cells(unit: Unit) -> Array:
	return get_walkable_cells(unit)