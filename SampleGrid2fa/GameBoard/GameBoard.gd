## Represents and manages the game board. Stores references to entities that are in each cell and
## tells whether cells are occupied or not.
## Units can only move around the grid one at a time.
class_name GameBoard
extends Node2D

signal unit_info_selected(unit: Unit)  # For info panel display (all units)
signal unit_info_deselected()  # For clearing info panel
signal move_mode_cancelled()  # Forwarded from ModeManager
signal attack_mode_cancelled()  # Forwarded from ModeManager
signal gameboard_ready()  # Emitted when GameBoard is fully initialized

const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

## Resource of type Grid.
#@export var grid: Resource
@export var grid: Grid

# _attack_range_cells and _potential_targets moved to CombatExecutor
var _last_click_time := 0
var _click_delay_ms := 200  # 200ms delay between clicks
var _board_busy := false  # Prevents selection during unit movement/animations

@onready var _unit_overlay: UnitOverlay = $UnitOverlay
@onready var _unit_path: UnitPath = $UnitPath
@onready var _turn_manager: TurnManager

# PathFinder no longer needed - MovementExecutor creates instances as needed

# Mode management
var _mode_manager: ModeManager

# Action execution (split into specialized executors)
var _movement_executor: MovementExecutor
var _combat_executor: CombatExecutor

# Selection management
var _selection_manager: SelectionManager

# Grid state management
var _grid_state_manager: GridStateManager

# Optional attack overlay - will be null if node doesn't exist
var _attack_overlay: AttackOverlay = null

# Coordinators (Router Pattern - business logic extracted)
var _input_handler: InputHandler
var _turn_integrator: TurnIntegrator
var _selection_coordinator: SelectionCoordinator
var _mode_coordinator: ModeCoordinator
var _animation_coordinator: AnimationCoordinator

# System initialization coordinator (Phase 6A)
var _initializer: GameBoardInitializer


func _ready() -> void:
	# Create and use initializer for system setup (Phase 6A - Opus41.md architecture)
	_initializer = preload("res://TacticalBattle/Coordinators/GameBoardInitializer.gd").new()
	add_child(_initializer)
	await _initializer.initialize_systems(self)


func _unhandled_input(event: InputEvent) -> void:
	if _selection_manager.has_active_unit() and event.is_action_pressed("ui_cancel"):
		# Block ESC during busy state (unit movement)
		if _board_busy:
			print("GameBoard: ESC blocked - board busy (unit moving)")
			get_viewport().set_input_as_handled()
			return
		
		# Let ModeManager handle ESC logic (visuals cleaned up by internal signal handlers)
		_mode_manager.handle_esc_input()
		
		get_viewport().set_input_as_handled()


func _get_configuration_warning() -> String:
	var warning := ""
	if not grid:
		warning = "You need a Grid resource for this node to work."
	return warning


## Returns `true` if the cell is occupied by a unit.
# Legacy function removed - use GridStateManager.is_occupied() directly





# Legacy function removed - use MovementExecutor.get_walkable_cells() directly




# Legacy function removed - use MovementExecutor._flood_fill() directly


# Movement function moved to MovementExecutor.gd - now handled by _execute_movement_async()


## Selects the unit in the `cell` if there's one there.
## Sets it as the active unit and draws its walkable cells and interactive move path. 
func _select_unit(cell: Vector2) -> void:
	if not _grid_state_manager.is_occupied(cell):
		return
	
	# Board busy protection - prevent selection during animations
	if _board_busy:
		print("GameBoard: Selection blocked - board busy (unit moving)")
		return
	
	# Click delay protection - prevent spam clicking
	var current_time = Time.get_ticks_msec()
	if current_time - _last_click_time < _click_delay_ms:
		print("GameBoard: Click blocked - too fast (", current_time - _last_click_time, "ms delay)")
		return
	_last_click_time = current_time

	var unit = _grid_state_manager.get_unit_at(cell)
	
	# Only allow info selection during player turns (simplified architecture)
	if _turn_manager and _turn_manager.active_unit and _turn_manager.active_unit.unit_type == Unit.UnitType.UNIT_PLAYER:
		emit_signal("unit_info_selected", unit)
		print("Info panel updated for: ", unit.name)
	else:
		print("Unit selection disabled - not player turn")
		return
	
	# No more Layer 1 unit selection - action panel auto-shows on turn start
	# Unit clicking is now ONLY for info panel updates


## Deselects the active unit, clearing the cells overlay and interactive path drawing.
func _deselect_active_unit() -> void:
	_selection_manager.deselect_active_unit()
	_unit_overlay.clear()
	_unit_path.stop()
	
	# Emit signals for UI updates
	emit_signal("unit_info_deselected")  # Clear info panel


## Clears the reference to the active unit and the corresponding walkable cells.
func _clear_active_unit() -> void:
	_selection_manager.clear_selection()


## Router: Delegates cursor input to InputHandler
func _on_Cursor_accept_pressed(cell: Vector2) -> void:
	_input_handler.handle_cursor_click(cell, _turn_manager)


## Async wrapper for movement execution
func _execute_movement_async(target_cell: Vector2) -> void:
	if not _selection_manager.get_active_unit():
		return

	# Set board busy to prevent additional input during movement animation
	_board_busy = true
	print("GameBoard: Board set to busy - movement starting")

	# Clear all overlays immediately when movement starts to prevent visual confusion
	_unit_overlay.clear()
	_unit_path.stop()

	# Execute movement through MovementExecutor
	var success = await _movement_executor.execute_movement(_selection_manager.get_active_unit(), target_cell)

	# Clear board busy after movement completes
	_board_busy = false
	print("GameBoard: Board no longer busy - movement completed")
	if success:
		# Movement completed successfully, handled by _on_action_completed signal
		pass
	else:
		print("GameBoard: Movement execution failed")

## Router: Delegates cursor movement to InputHandler
func _on_Cursor_moved(new_cell: Vector2) -> void:
	_input_handler.handle_cursor_movement(new_cell)

## Router: Delegates move mode changes to ModeCoordinator
func _on_move_mode_changed(is_active: bool) -> void:
	_mode_coordinator.handle_move_mode_changed(is_active)

## Router: Delegates attack mode changes to ModeCoordinator
func _on_attack_mode_changed(is_active: bool) -> void:
	_mode_coordinator.handle_attack_mode_changed(is_active)

## Router: Delegates unit registration to TurnIntegrator
func _register_all_units() -> void:
	_turn_integrator.register_all_units()

## Router: Delegates turn changes to TurnIntegrator
func _on_turn_changed(current_unit: Unit, turn_number: int) -> void:
	_board_busy = false  # Ensure board is not busy during turn transitions
	_turn_integrator.handle_turn_changed(current_unit, turn_number)

## Router: Delegates round completion to TurnIntegrator
func _on_round_completed(round_number: int) -> void:
	_turn_integrator.handle_round_completed(round_number)

## Called when a unit ends their turn
func _on_unit_turn_ended() -> void:
	if _turn_manager:
		_turn_manager.end_current_turn()

## Router: Delegates mode cancellation to ModeCoordinator
func _on_move_mode_cancelled_internal() -> void:
	_mode_coordinator.handle_move_mode_cancelled()
	emit_signal("move_mode_cancelled")

## Router: Delegates attack mode cancellation to ModeCoordinator
func _on_attack_mode_cancelled_internal() -> void:
	_mode_coordinator.handle_attack_mode_cancelled()
	emit_signal("attack_mode_cancelled")

# Attack range and target highlighting functions moved to CombatExecutor.gd

# Attack execution function moved to CombatExecutor.gd

## Removes a unit from the board when it dies
func _remove_unit_from_board(unit: Unit) -> void:
	if not is_instance_valid(unit):
		print("GameBoard: Warning - trying to remove invalid unit")
		return
		
	
	# Remove from grid state
	_grid_state_manager.remove_unit(unit)
	
	# Remove from turn manager
	if _turn_manager:
		_turn_manager.unregister_unit(unit)
	
	# Clean up any active unit references
	if _selection_manager.get_active_unit() == unit:
		print("GameBoard: Cleared active unit reference for dead unit")
		_selection_manager.handle_unit_death(unit)
		emit_signal("unit_info_deselected")
	
	# Disconnect signals to prevent issues
	if unit.turn_ended.is_connected(_on_unit_turn_ended):
		unit.turn_ended.disconnect(_on_unit_turn_ended)
	
	# Visual cleanup - could add death animation here
	unit.visible = false
	unit.queue_free()

## Handles unit death signal from MovementExecutor and CombatExecutor
func _on_unit_died(unit: Unit) -> void:
	if is_instance_valid(unit):
		_remove_unit_from_board(unit)

## Handles action completion from MovementExecutor and CombatExecutor
func _on_action_completed(action_type: String, unit: Unit) -> void:
	var unit_name = unit.name if unit else "unknown unit"
	print("GameBoard: Action completed - ", action_type, " by ", unit_name)
	
	if action_type == "move":
		# Movement completed - cancel move mode and return to Layer 1 (unit selected)
		if unit and unit.unit_type == Unit.UnitType.UNIT_PLAYER:
			# Cancel move mode to return to Layer 1
			_mode_manager.cancel_move_mode()
			# Re-activate the unit and update unit info
			_selection_manager.select_unit(unit)
			emit_signal("unit_info_selected", unit)
			print("Player movement complete - walkable cells updated for new position")
	elif action_type == "attack":
		# Attack completed - exit attack mode
		if unit and unit.is_alive():
			_mode_manager.cancel_attack_mode()  # Visuals cleaned up by internal handler
			# Note: No automatic turn ending - players must press END TURN

## Router Callback Methods (called by coordinators)

## Forwards unit_info_selected signal from coordinators
func _on_unit_info_selected(unit: Unit) -> void:
	emit_signal("unit_info_selected", unit)

## Forwards unit_info_deselected signal from coordinators
func _on_unit_info_deselected() -> void:
	emit_signal("unit_info_deselected")

## Handles movement execution request from InputHandler
func _on_movement_execution_needed(target_cell: Vector2) -> void:
	_animation_coordinator.execute_movement_async(target_cell)

## Handles attack execution request from InputHandler
func _on_attack_execution_needed(attacker: Unit, target: Unit) -> void:
	_board_busy = true
	_input_handler.set_board_busy(true)
	print("GameBoard: Executing attack - ", attacker.name, " attacks ", target.name)

	# Execute attack through CombatExecutor
	await _combat_executor.execute_attack(attacker, target)

	_board_busy = false
	_input_handler.set_board_busy(false)
	print("GameBoard: Attack completed")

## Handles animation start (updates busy state)
func _on_animation_started() -> void:
	_board_busy = true
	_input_handler.set_board_busy(true)

## Handles animation completion (clears busy state)
func _on_animation_completed() -> void:
	_board_busy = false
	_input_handler.set_board_busy(false)
