## ModeCoordinator - Handles move/attack mode transitions and visual coordination
## Extracted from GameBoard.gd to reduce complexity and improve maintainability
class_name ModeCoordinator
extends Node

# Reference to GameBoard components
var _selection_manager: SelectionManager
var _mode_manager: ModeManager
var _movement_executor: MovementExecutor
var _combat_executor: CombatExecutor
var _unit_overlay: UnitOverlay
var _unit_path: UnitPath

func initialize(
	selection_manager: SelectionManager,
	mode_manager: ModeManager,
	movement_executor: MovementExecutor,
	combat_executor: CombatExecutor,
	unit_overlay: UnitOverlay,
	unit_path: UnitPath
) -> void:
	_selection_manager = selection_manager
	_mode_manager = mode_manager
	_movement_executor = movement_executor
	_combat_executor = combat_executor
	_unit_overlay = unit_overlay
	_unit_path = unit_path

	print("ModeCoordinator: Initialized")

## Handles move mode activation/deactivation with visual coordination
func handle_move_mode_changed(is_active: bool) -> void:
	# Forward to ModeManager for state management
	_mode_manager._on_move_mode_changed(is_active)

	if _selection_manager.get_active_unit() and _selection_manager.get_active_unit().is_selected:
		if is_active:
			# Layer 2: Show move overlay and initialize path
			var walkable_cells = _selection_manager.get_walkable_cells()
			_unit_overlay.draw(walkable_cells)
			_unit_path.initialize(walkable_cells)
			print("ModeCoordinator: Move mode enabled - showing walkable cells (Layer 2)")
		else:
			# Back to Layer 1: Hide overlay but keep unit selected
			_unit_overlay.clear()
			_unit_path.stop()
			print("ModeCoordinator: Move mode disabled - back to Layer 1 (unit still selected)")
	else:
		print("ModeCoordinator: Move mode ", "enabled" if is_active else "disabled", " (no unit selected)")

## Handles attack mode activation/deactivation with visual coordination
func handle_attack_mode_changed(is_active: bool) -> void:
	# Forward to ModeManager for state management
	_mode_manager._on_attack_mode_changed(is_active)

	if _selection_manager.get_active_unit() and _selection_manager.get_active_unit().is_selected:
		if is_active:
			# Layer 2: Clear move visuals and show attack overlay
			_unit_overlay.clear()
			_unit_path.stop()

			# Layer 2: Show attack overlay and find targets
			_combat_executor.show_attack_range(_selection_manager.get_active_unit())
			_combat_executor.highlight_valid_targets(_selection_manager.get_active_unit())
			print("ModeCoordinator: Attack mode enabled - showing attack range (Layer 2)")
		else:
			# Back to Layer 1: Hide overlay but keep unit selected
			_combat_executor.clear_attack_range()
			print("ModeCoordinator: Attack mode disabled - back to Layer 1 (unit still selected)")
	else:
		print("ModeCoordinator: Attack mode ", "enabled" if is_active else "disabled", " (no unit selected)")

## Handles move mode cancellation with cleanup
func handle_move_mode_cancelled() -> void:
	# Clean up move visuals - handled by mode change
	print("ModeCoordinator: Move mode cancelled - visuals cleaned up")

## Handles attack mode cancellation with cleanup
func handle_attack_mode_cancelled() -> void:
	# Clean up attack visuals
	_combat_executor.clear_attack_range()
	print("ModeCoordinator: Attack mode cancelled - visuals cleaned up")