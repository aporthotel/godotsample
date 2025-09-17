## AnimationCoordinator - Handles movement animation and busy state coordination
## Extracted from GameBoard.gd to reduce complexity and improve maintainability
class_name AnimationCoordinator
extends Node

# Reference to GameBoard components
var _selection_manager: SelectionManager
var _movement_executor: MovementExecutor
var _unit_overlay: UnitOverlay
var _unit_path: UnitPath

# Animation state
var _animation_busy := false

# Signals for coordination
signal animation_started()
signal animation_completed()

func initialize(
	selection_manager: SelectionManager,
	movement_executor: MovementExecutor,
	unit_overlay: UnitOverlay,
	unit_path: UnitPath
) -> void:
	_selection_manager = selection_manager
	_movement_executor = movement_executor
	_unit_overlay = unit_overlay
	_unit_path = unit_path

	print("AnimationCoordinator: Initialized")

## Executes movement with full animation coordination
func execute_movement_async(target_cell: Vector2) -> bool:
	if not _selection_manager.get_active_unit():
		print("AnimationCoordinator: No active unit for movement")
		return false

	# Set animation busy state
	_animation_busy = true
	emit_signal("animation_started")
	print("AnimationCoordinator: Movement animation starting")

	# Clear all overlays immediately when movement starts to prevent visual confusion
	_unit_overlay.clear()
	_unit_path.stop()

	# Execute movement through MovementExecutor
	var success = await _movement_executor.execute_movement(_selection_manager.get_active_unit(), target_cell)

	# Clear animation busy state
	_animation_busy = false
	emit_signal("animation_completed")
	print("AnimationCoordinator: Movement animation completed")

	if success:
		print("AnimationCoordinator: Movement completed successfully")
	else:
		print("AnimationCoordinator: Movement execution failed")

	return success

## Gets current animation busy state
func is_animation_busy() -> bool:
	return _animation_busy

## Forces animation state reset (for error recovery)
func reset_animation_state() -> void:
	if _animation_busy:
		print("AnimationCoordinator: Forcing animation state reset")
		_animation_busy = false
		emit_signal("animation_completed")