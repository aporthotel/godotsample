## SelectionCoordinator - Handles unit selection logic and visual coordination
## Extracted from GameBoard.gd to reduce complexity and improve maintainability
class_name SelectionCoordinator
extends Node

# Reference to GameBoard components
var _selection_manager: SelectionManager
var _grid_state_manager: GridStateManager
var _unit_overlay: UnitOverlay
var _unit_path: UnitPath

# Signals for GameBoard to forward
signal unit_info_selected(unit: Unit)
signal unit_info_deselected()

func initialize(
	selection_manager: SelectionManager,
	grid_state_manager: GridStateManager,
	unit_overlay: UnitOverlay,
	unit_path: UnitPath
) -> void:
	_selection_manager = selection_manager
	_grid_state_manager = grid_state_manager
	_unit_overlay = unit_overlay
	_unit_path = unit_path

	print("SelectionCoordinator: Initialized")

## Selects a unit at the given cell with full visual coordination
func select_unit_at_cell(cell: Vector2, turn_manager: TurnManager) -> void:
	var unit = _grid_state_manager.get_unit_at(cell)

	if not unit:
		print("SelectionCoordinator: No unit at cell ", cell)
		return

	# Board busy protection would be handled by InputHandler
	# Click delay protection would be handled by InputHandler

	# Only allow info selection during player turns (simplified architecture)
	if turn_manager and turn_manager.active_unit and turn_manager.active_unit.unit_type == Unit.UnitType.UNIT_PLAYER:
		emit_signal("unit_info_selected", unit)
		print("SelectionCoordinator: Info panel updated for: ", unit.name)
	else:
		print("SelectionCoordinator: Unit selection disabled - not player turn")
		return

	# No more Layer 1 unit selection - action panel auto-shows on turn start
	# Unit clicking is now ONLY for info panel updates
	print("SelectionCoordinator: Unit selection completed for: ", unit.name)

## Deselects the active unit with full visual cleanup
func deselect_active_unit() -> void:
	_selection_manager.deselect_active_unit()
	_unit_overlay.clear()
	_unit_path.stop()

	# Emit signals for UI updates
	emit_signal("unit_info_deselected")  # Clear info panel

	print("SelectionCoordinator: Unit deselected with visual cleanup")

## Clears the active unit selection
func clear_active_unit() -> void:
	_selection_manager.clear_selection()
	print("SelectionCoordinator: Active unit cleared")

## Handles unit resynchronization with turn manager
func handle_unit_resync(unit_at_cell: Unit, turn_manager: TurnManager) -> bool:
	# Only allow action control for the current turn's unit (simplified architecture)
	if unit_at_cell == turn_manager.active_unit and unit_at_cell != _selection_manager.get_active_unit():
		# This should rarely happen since _selection_manager.get_active_unit() is set on turn start,
		# but handle the case where somehow they're out of sync
		print("SelectionCoordinator: Resetting active unit to match turn manager")
		return true  # Indicate that resync is needed

	return false  # No resync needed