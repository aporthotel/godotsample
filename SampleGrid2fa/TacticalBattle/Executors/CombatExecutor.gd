## CombatExecutor - Handles all combat and attack logic
## Extends BaseExecutor with combat-specific functionality
class_name CombatExecutor
extends BaseExecutor

const CombatCalculatorScript = preload("res://Systems/CombatCalculator.gd")
var _combat_calculator: Node

# Combat-specific state
var _attack_range_cells := []
var _potential_targets: Array[Unit] = []

## Executor-specific initialization
func _setup_executor() -> void:
	# Create CombatCalculator instance
	_combat_calculator = CombatCalculatorScript.new()
	add_child(_combat_calculator)

	print("CombatExecutor: Combat executor initialized with CombatCalculator")

## Shows attack range overlay for the given unit
func show_attack_range(unit: Unit) -> void:
	if not unit or not unit.stats or not _attack_overlay:
		print("CombatExecutor: Cannot show attack range - missing components")
		return

	_attack_range_cells = _combat_calculator.get_attack_range_cells(unit, _grid)
	_attack_overlay.draw(_attack_range_cells)
	print("CombatExecutor: Attack range displayed for ", unit.name)

## Finds and highlights valid attack targets
func highlight_valid_targets(attacker: Unit) -> void:
	if not attacker:
		print("CombatExecutor: Cannot highlight targets - no attacker")
		return

	# Get all units as potential targets using BaseExecutor method
	var all_units = get_all_units()

	_potential_targets = _combat_calculator.get_units_in_attack_range(attacker, all_units)

	# Debug output for valid targets
	print("CombatExecutor: Found ", _potential_targets.size(), " valid targets for ", attacker.name)
	for target in _potential_targets:
		if is_instance_valid(target):
			print("CombatExecutor: Valid attack target - ", target.name, " at ", target.get_grid_position())

## Gets the current potential attack targets
func get_potential_targets() -> Array[Unit]:
	return _potential_targets

## Clears attack range visuals and data
func clear_attack_range() -> void:
	if _attack_overlay:
		_attack_overlay.clear()
	_potential_targets.clear()
	_attack_range_cells.clear()
	print("CombatExecutor: Attack range cleared")

## Executes an attack between two units
func execute_attack(attacker: Unit, target: Unit) -> bool:
	if not attacker or not target:
		print("CombatExecutor: Attack failed - missing attacker or target")
		return false

	# Safety check for freed units
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		print("CombatExecutor: Attack cancelled - one of the units is no longer valid")
		return false

	# Check if attacker has enough AP (CombatCalculator will consume it)
	if not attacker.can_attack():
		print("CombatExecutor: Attack failed - not enough AP")
		return false

	print("CombatExecutor: Executing attack - ", attacker.name, " attacks ", target.name)

	var result = _combat_calculator.execute_attack(attacker, target)

	# Display combat result
	if result.success:
		if result.hit:
			var damage_text = str(result.damage_dealt)
			if result.critical:
				damage_text += " (CRIT!)"
			print("CombatExecutor: Attack HIT for ", damage_text, " damage!")

			if result.counter and result.counter.hit:
				print("CombatExecutor: COUNTER-ATTACK - ", result.counter.damage_dealt, " damage", " (CRIT!)" if result.counter.critical else "")
		else:
			print("CombatExecutor: Attack MISSED!")
	else:
		print("CombatExecutor: Attack failed - ", result.get("error", "Unknown error"))

	# Handle unit death using BaseExecutor method
	if not target.is_alive():
		print("CombatExecutor: ", target.name, " has died!")
		emit_unit_died(target)

	if not attacker.is_alive():
		print("CombatExecutor: ", attacker.name, " died in combat!")
		emit_unit_died(attacker)

	# Use BaseExecutor's standardized completion signal
	emit_action_completed("attack", attacker)
	return true

## Validates if a target is valid for attack
func is_valid_attack_target(attacker: Unit, target: Unit) -> bool:
	if not target or not is_instance_valid(target):
		return false

	return target in _potential_targets

## Gets attack range cells for a unit (for external use)
func get_attack_range_cells(unit: Unit) -> Array:
	if not unit or not _grid:
		return []

	return _combat_calculator.get_attack_range_cells(unit, _grid)

## Enhanced unit removal with visual cleanup (extends BaseExecutor method)
func remove_unit_from_board_with_cleanup(unit: Unit) -> void:
	if not unit:
		return

	print("CombatExecutor: Removing unit from board with visual cleanup - ", unit.name)

	# Use BaseExecutor's core removal logic
	remove_unit_from_board(unit)

	# Combat-specific cleanup - death animation could go here
	unit.visible = false
	unit.queue_free()

	print("CombatExecutor: Unit cleanup completed for ", unit.name)