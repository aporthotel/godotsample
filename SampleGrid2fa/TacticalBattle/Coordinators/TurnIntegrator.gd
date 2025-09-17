## TurnIntegrator - Handles all turn system coordination and unit lifecycle
## Extracted from GameBoard.gd to reduce complexity and improve maintainability
class_name TurnIntegrator
extends Node

# Reference to GameBoard components
var _turn_manager: TurnManager
var _selection_manager: SelectionManager
var _mode_manager: ModeManager
var _grid_state_manager: GridStateManager

# Signals for GameBoard to forward
signal unit_info_selected(unit: Unit)
signal unit_info_deselected()

func initialize(
	turn_manager: TurnManager,
	selection_manager: SelectionManager,
	mode_manager: ModeManager,
	grid_state_manager: GridStateManager
) -> void:
	_turn_manager = turn_manager
	_selection_manager = selection_manager
	_mode_manager = mode_manager
	_grid_state_manager = grid_state_manager

	print("TurnIntegrator: Initialized")

## Registers all units with the turn manager during initialization
func register_all_units() -> void:
	print("TurnIntegrator: Registering all units with turn manager...")

	var all_units = _grid_state_manager.get_all_units()
	print("TurnIntegrator: Found ", all_units.size(), " units to register")

	for unit in all_units:
		if unit and is_instance_valid(unit):
			_turn_manager.register_unit(unit)
			# Connect to unit turn ended signal
			unit.turn_ended.connect(_on_unit_turn_ended)
			print("TurnIntegrator: Registered unit: ", unit.name)

	print("TurnIntegrator: Unit registration complete")

## Handles turn changes from TurnManager
func handle_turn_changed(current_unit: Unit, turn_number: int) -> void:
	var unit_name = current_unit.name if current_unit else "None"
	print("TurnIntegrator: Turn ", turn_number, " - ", unit_name, " is now active")

	# Clear any existing selections and modes
	_selection_manager.deselect_active_unit()
	_mode_manager.cancel_all_modes()

	# Update unit active state for ALL units (triggers AP recovery for active unit)
	var all_units = _grid_state_manager.get_all_units()
	for unit in all_units:
		if unit and is_instance_valid(unit):
			unit.is_active_turn = (unit == current_unit)

	# Set the new active unit based on turn
	if current_unit and current_unit.unit_type == Unit.UnitType.UNIT_PLAYER:
		# Player unit - select and show info
		_selection_manager.select_unit(current_unit)
		emit_signal("unit_info_selected", current_unit)
		print("TurnIntegrator: Player turn - unit selected and info panel updated")
	else:
		# AI/NPC unit - clear selection and info panel
		_selection_manager.clear_selection()
		emit_signal("unit_info_deselected")
		print("TurnIntegrator: AI/NPC turn - info panel cleared")

## Handles round completion from TurnManager
func handle_round_completed(round_number: int) -> void:
	print("TurnIntegrator: Round ", round_number - 1, " completed! Starting round ", round_number)
	# Could add round-specific logic here (status effects, regeneration, etc.)

## Handles unit turn ended signal
func _on_unit_turn_ended() -> void:
	print("TurnIntegrator: Unit ended turn - advancing to next unit")
	if _turn_manager:
		_turn_manager.next_turn()

## Handles unit death cleanup
func handle_unit_death(unit: Unit) -> void:
	if not is_instance_valid(unit):
		print("TurnIntegrator: Cannot handle death - invalid unit")
		return

	print("TurnIntegrator: Handling unit death: ", unit.name)

	# Disconnect turn ended signal if connected
	if unit.turn_ended.is_connected(_on_unit_turn_ended):
		unit.turn_ended.disconnect(_on_unit_turn_ended)

	# Unregister from turn manager
	_turn_manager.unregister_unit(unit)

	# Clear selection if this unit was selected
	if _selection_manager.get_active_unit() == unit:
		_selection_manager.clear_selection()
		emit_signal("unit_info_deselected")

	print("TurnIntegrator: Unit death cleanup completed for ", unit.name)

## Handles action completion and mode management
func handle_action_completed(action_type: String, unit: Unit) -> void:
	var unit_name = unit.name if unit else "unknown unit"
	print("TurnIntegrator: Action completed - ", action_type, " by ", unit_name)

	# Handle different action types
	match action_type:
		"move":
			# Movement completed - cancel move mode to return to Layer 1 (unit selected)
			if unit and unit.unit_type == Unit.UnitType.UNIT_PLAYER:
				_mode_manager.cancel_move_mode()
				print("TurnIntegrator: Move completed - returned to Layer 1 (unit selected)")
		"attack":
			# Attack completed - could add attack-specific logic here
			print("TurnIntegrator: Attack completed")
		_:
			print("TurnIntegrator: Unknown action type: ", action_type)

## Gets current turn information for external systems
func get_turn_info() -> Dictionary:
	if _turn_manager:
		return _turn_manager.get_turn_info()
	else:
		return {"error": "TurnManager not available"}