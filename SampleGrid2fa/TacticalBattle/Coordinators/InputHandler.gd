## InputHandler - Handles all cursor and input logic for GameBoard
## Extracted from GameBoard.gd to reduce complexity and improve maintainability
class_name InputHandler
extends Node

# Reference to GameBoard components
var _selection_manager: SelectionManager
var _mode_manager: ModeManager
var _movement_executor: MovementExecutor
var _combat_executor: CombatExecutor
var _grid_state_manager: GridStateManager
var _unit_overlay: UnitOverlay
var _unit_path: UnitPath

# Busy state management
var _board_busy := false

# Signals for GameBoard to forward
signal unit_info_selected(unit: Unit)
signal unit_info_deselected()
signal movement_execution_needed(target_cell: Vector2)
signal attack_execution_needed(attacker: Unit, target: Unit)

func initialize(
	selection_manager: SelectionManager,
	mode_manager: ModeManager,
	movement_executor: MovementExecutor,
	combat_executor: CombatExecutor,
	grid_state_manager: GridStateManager,
	unit_overlay: UnitOverlay,
	unit_path: UnitPath
) -> void:
	_selection_manager = selection_manager
	_mode_manager = mode_manager
	_movement_executor = movement_executor
	_combat_executor = combat_executor
	_grid_state_manager = grid_state_manager
	_unit_overlay = unit_overlay
	_unit_path = unit_path

	print("InputHandler: Initialized")

## Sets board busy state (called by GameBoard during animations)
func set_board_busy(busy: bool) -> void:
	_board_busy = busy

## Handles cursor click input - main input routing logic
func handle_cursor_click(cell: Vector2, turn_manager: TurnManager) -> void:
	# Board busy protection - prevent ALL actions during animations
	if _board_busy:
		print("InputHandler: Input blocked - board busy (unit moving/attacking)")
		return

	# Check if there's a unit at the clicked cell
	var unit_at_cell = _grid_state_manager.get_unit_at(cell)

	if not _selection_manager.get_active_unit():
		# No unit selected, try to select one
		_handle_unit_selection(cell, turn_manager)
	elif _selection_manager.get_active_unit().is_selected:
		if _mode_manager.is_attack_mode_active():
			# Attack mode active - try to attack target
			_handle_attack_input(unit_at_cell)
		elif unit_at_cell:
			# Clicking on any unit - update info panel (independent component)
			_handle_unit_info_update(unit_at_cell, turn_manager)
		else:
			# Clicking empty cell - only process if move mode is active
			if _mode_manager.is_move_mode_active():
				_handle_movement_input(cell)

## Handles unit selection logic
func _handle_unit_selection(cell: Vector2, turn_manager: TurnManager) -> void:
	var unit = _grid_state_manager.get_unit_at(cell)

	if not unit:
		print("InputHandler: No unit at clicked cell")
		return

	# Only allow info selection during player turns
	if turn_manager and turn_manager.active_unit and turn_manager.active_unit.unit_type == Unit.UnitType.UNIT_PLAYER:
		emit_signal("unit_info_selected", unit)
		print("InputHandler: Info panel updated for: ", unit.name)
	else:
		print("InputHandler: Unit selection disabled - not player turn")

## Handles attack input during attack mode
func _handle_attack_input(target_unit: Unit) -> void:
	if target_unit and is_instance_valid(target_unit) and _combat_executor.is_valid_attack_target(_selection_manager.get_active_unit(), target_unit):
		# Valid attack target - signal GameBoard to execute attack
		print("InputHandler: Valid attack target - requesting attack execution")

		# Clear all overlays immediately when attack starts
		_unit_overlay.clear()
		_unit_path.stop()
		_combat_executor.clear_attack_range()

		# Signal GameBoard to execute the attack
		emit_signal("attack_execution_needed", _selection_manager.get_active_unit(), target_unit)
	else:
		print("InputHandler: No valid target at clicked cell")

## Handles unit info panel updates
func _handle_unit_info_update(unit_at_cell: Unit, turn_manager: TurnManager) -> void:
	# Clicking on any unit - update info panel (independent component)
	if turn_manager and turn_manager.active_unit and turn_manager.active_unit.unit_type == Unit.UnitType.UNIT_PLAYER:
		emit_signal("unit_info_selected", unit_at_cell)
		print("InputHandler: Info panel updated for: ", unit_at_cell.name, " (turn unit: ", turn_manager.active_unit.name, ")")

	# Only allow action control for the current turn's unit
	if unit_at_cell == turn_manager.active_unit and unit_at_cell != _selection_manager.get_active_unit():
		# This should rarely happen since active unit is set on turn start,
		# but handle the case where somehow they're out of sync
		print("InputHandler: Resetting active unit to match turn manager")
		# GameBoard will handle the actual reselection logic

## Handles movement input during move mode
func _handle_movement_input(cell: Vector2) -> void:
	# Clicking empty cell - only allow movement if move mode is active
	if not _mode_manager.is_move_mode_active():
		print("InputHandler: Move mode not active - click MOVE button in action panel first!")
		return

	# Check if the clicked cell is a valid move target
	if _grid_state_manager.is_occupied(cell) or not _selection_manager.is_cell_walkable(Vector2i(cell)):
		# Invalid move target - for player units, cancel move mode and return to Layer 1
		if _selection_manager.get_active_unit() and _selection_manager.get_active_unit().unit_type == Unit.UnitType.UNIT_PLAYER:
			print("InputHandler: Invalid move target - requesting mode cancellation")
			_mode_manager.cancel_move_mode()
			# Clear move visuals but keep unit selected and action panel visible
			_unit_overlay.clear()
			_unit_path.stop()
		else:
			print("InputHandler: Invalid move target for AI unit")
		return

	# Valid move target - signal GameBoard to execute movement
	print("InputHandler: Valid move target - requesting movement execution")
	emit_signal("movement_execution_needed", cell)

## Handles cursor movement for path preview
func handle_cursor_movement(new_cell: Vector2) -> void:
	# Block path preview during board busy state (unit moving/attacking)
	if _board_busy:
		return

	if _mode_manager.is_move_mode_active() and _selection_manager.get_active_unit() and _selection_manager.get_active_unit().is_selected:
		_unit_path.draw(_selection_manager.get_active_unit().cell, new_cell)