## ActionExecutor - Handles all action execution logic (move, attack, skills, items)
## Extracted from GameBoard.gd to reduce complexity and enable easier expansion
class_name ActionExecutor
extends Node

signal action_completed(action_type: String, unit: Unit)
signal unit_died(unit: Unit)

var _grid: Grid
var _units: Dictionary  # Reference to GameBoard's units dictionary
# PathFinder instances created as needed for pathfinding
var _unit_overlay: UnitOverlay
var _unit_path: UnitPath
var _attack_overlay: AttackOverlay

# Attack-related state
var _attack_range_cells := []
var _potential_targets: Array[Unit] = []

func initialize(grid: Grid, units_dict: Dictionary, 
                unit_overlay: UnitOverlay, unit_path: UnitPath, attack_overlay: AttackOverlay) -> void:
	_grid = grid
	_units = units_dict
	_unit_overlay = unit_overlay
	_unit_path = unit_path
	_attack_overlay = attack_overlay
	print("ActionExecutor: Initialized with game components")

## Calculates and returns the cells a unit can walk to
func get_walkable_cells(unit: Unit) -> Array:
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
	# Validate movement
	if _is_cell_occupied(target_cell):
		print("ActionExecutor: Movement failed - cell occupied")
		return false
	
	var walkable_cells = get_walkable_cells(unit)
	if not target_cell in walkable_cells:
		print("ActionExecutor: Movement failed - cell not walkable")
		return false
	
	# Consume AP for movement
	if not unit.consume_ap(unit.stats.movement_cost):
		print("ActionExecutor: Movement failed - not enough AP")
		return false
	
	print("ActionExecutor: Executing movement for ", unit.name, " to ", target_cell)
	
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
	
	emit_signal("action_completed", "move", unit)
	print("ActionExecutor: Movement completed for ", unit.name)
	return true

## Shows attack range overlay for the given unit
func show_attack_range(unit: Unit) -> void:
	if not unit or not unit.stats or not _attack_overlay:
		print("ActionExecutor: Cannot show attack range - missing components")
		return
	
	_attack_range_cells = CombatCalculator.get_attack_range_cells(unit, _grid)
	_attack_overlay.draw(_attack_range_cells)
	print("ActionExecutor: Attack range displayed for ", unit.name)

## Finds and highlights valid attack targets
func highlight_valid_targets(attacker: Unit) -> void:
	if not attacker:
		print("ActionExecutor: Cannot highlight targets - no attacker")
		return
	
	# Get all units as potential targets
	var all_units: Array[Unit] = []
	for unit in _units.values():
		if is_instance_valid(unit):
			all_units.append(unit)
		else:
			print("ActionExecutor: Warning - Found invalid unit in _units dictionary")
	
	_potential_targets = CombatCalculator.get_units_in_attack_range(attacker, all_units)
	
	# Debug output for valid targets
	print("ActionExecutor: Found ", _potential_targets.size(), " valid targets for ", attacker.name)
	for target in _potential_targets:
		if is_instance_valid(target):
			print("ActionExecutor: Valid attack target - ", target.name, " at ", target.get_grid_position())

## Gets the current potential attack targets
func get_potential_targets() -> Array[Unit]:
	return _potential_targets

## Clears attack range visuals and data
func clear_attack_range() -> void:
	if _attack_overlay:
		_attack_overlay.clear()
	_potential_targets.clear()
	_attack_range_cells.clear()
	print("ActionExecutor: Attack range cleared")

## Executes an attack between two units
func execute_attack(attacker: Unit, target: Unit) -> bool:
	if not attacker or not target:
		print("ActionExecutor: Attack failed - missing attacker or target")
		return false
	
	# Safety check for freed units
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		print("ActionExecutor: Attack cancelled - one of the units is no longer valid")
		return false
	
	# Check if attacker has enough AP (CombatCalculator will consume it)
	if not attacker.can_attack():
		print("ActionExecutor: Attack failed - not enough AP")
		return false
	
	print("ActionExecutor: Executing attack - ", attacker.name, " attacks ", target.name)
	
	var result = CombatCalculator.execute_attack(attacker, target)
	
	# Display combat result
	if result.success:
		if result.hit:
			var damage_text = str(result.damage_dealt)
			if result.critical:
				damage_text += " (CRIT!)"
			print("ActionExecutor: Attack HIT for ", damage_text, " damage!")
			
			if result.counter and result.counter.hit:
				print("ActionExecutor: COUNTER-ATTACK - ", result.counter.damage_dealt, " damage", " (CRIT!)" if result.counter.critical else "")
		else:
			print("ActionExecutor: Attack MISSED!")
	else:
		print("ActionExecutor: Attack failed - ", result.get("error", "Unknown error"))
	
	# Handle unit death
	if not target.is_alive():
		print("ActionExecutor: ", target.name, " has died!")
		emit_signal("unit_died", target)
	
	if not attacker.is_alive():
		print("ActionExecutor: ", attacker.name, " died in combat!")
		emit_signal("unit_died", attacker)
	
	emit_signal("action_completed", "attack", attacker)
	return true

## Removes a dead unit from the board
func remove_unit_from_board(unit: Unit) -> void:
	if not unit:
		return
	
	print("ActionExecutor: Removing unit from board - ", unit.name)
	
	# Remove from units dictionary
	var unit_pos = unit.get_grid_position()
	if _units.has(unit_pos) and _units[unit_pos] == unit:
		_units.erase(unit_pos)
		print("ActionExecutor: Unit removed from position ", unit_pos)
	
	# Visual cleanup - could add death animation here
	unit.visible = false
	unit.queue_free()
	
	print("ActionExecutor: Unit cleanup completed for ", unit.name)

## Checks if a cell is occupied by a unit
func _is_cell_occupied(cell: Vector2) -> bool:
	return _units.has(cell)

## Validates if a target is valid for attack
func is_valid_attack_target(attacker: Unit, target: Unit) -> bool:
	if not target or not is_instance_valid(target):
		return false
	
	return target in _potential_targets

## Gets attack range cells for a unit (for external use)
func get_attack_range_cells(unit: Unit) -> Array:
	if not unit or not _grid:
		return []
	
	return CombatCalculator.get_attack_range_cells(unit, _grid)