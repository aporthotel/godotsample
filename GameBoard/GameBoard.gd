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

## Mapping of coordinates of a cell to a reference to the unit it contains.
var _units := {}
var _active_unit: Unit
var _walkable_cells := []
# _attack_range_cells and _potential_targets moved to ActionExecutor
var _last_click_time := 0
var _click_delay_ms := 200  # 200ms delay between clicks
var _board_busy := false  # Prevents selection during unit movement/animations

@onready var _unit_overlay: UnitOverlay = $UnitOverlay
@onready var _unit_path: UnitPath = $UnitPath
@onready var _turn_manager: TurnManager

# PathFinder no longer needed - ActionExecutor creates instances as needed

# Mode management
var _mode_manager: ModeManager

# Action execution
var _action_executor: ActionExecutor

# Optional attack overlay - will be null if node doesn't exist
var _attack_overlay: AttackOverlay = null


func _ready() -> void:
	# Try to get attack overlay if it exists
	if has_node("AttackOverlay"):
		_attack_overlay = get_node("AttackOverlay")
		print("GameBoard: AttackOverlay found and initialized")
	else:
		print("GameBoard: AttackOverlay not found - attack mode will work without visual overlay")
	
	# PathFinder no longer needed globally - ActionExecutor creates instances as needed
	
	# Create turn manager
	_turn_manager = TurnManager.new()
	add_child(_turn_manager)
	
	# Create mode manager
	_mode_manager = ModeManager.new()
	add_child(_mode_manager)
	
	# Create action executor
	_action_executor = ActionExecutor.new()
	add_child(_action_executor)
	_action_executor.initialize(grid, _units, _unit_overlay, _unit_path, _attack_overlay)
	
	# Connect turn manager signals
	_turn_manager.turn_changed.connect(_on_turn_changed)
	_turn_manager.round_completed.connect(_on_round_completed)
	
	# Connect mode manager signals (forward to external listeners + handle visual cleanup)
	_mode_manager.move_mode_cancelled.connect(_on_move_mode_cancelled_internal)
	_mode_manager.attack_mode_cancelled.connect(_on_attack_mode_cancelled_internal)
	
	# Connect action executor signals
	_action_executor.unit_died.connect(_on_unit_died)
	_action_executor.action_completed.connect(_on_action_completed)
	
	_reinitialize()
	
	# Register all units with turn manager after initialization
	print("GameBoard: Waiting for initialization...")
	await get_tree().process_frame
	await get_tree().process_frame  # Extra delay for safety
	
	print("GameBoard: Registering units...")
	_register_all_units()
	
	print("GameBoard: Emitting ready signal...")
	emit_signal("gameboard_ready")
	
	print("GameBoard: Starting turn sequence...")
	_turn_manager.start_turn_sequence()
	print("GameBoard: Turn sequence started")


func _unhandled_input(event: InputEvent) -> void:
	if _active_unit and event.is_action_pressed("ui_cancel"):
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
func is_occupied(cell: Vector2) -> bool:
	return _units.has(cell)





## Returns an array of cells a given unit can walk using the flood fill algorithm.
func get_walkable_cells(unit: Unit) -> Array:
	return _flood_fill(unit.cell, unit.get_movement_range())


## Clears, and refills the `_units` dictionary with game objects that are on the board.
func _reinitialize() -> void:
	_units.clear()

	for child in get_children():
		var unit := child as Unit
		if not unit:
			continue
		_units[unit.cell] = unit
		# Connect to unit death signal to handle cleanup
		if not unit.unit_died.is_connected(_on_unit_died):
			unit.unit_died.connect(_on_unit_died)


## Returns an array with all the coordinates of walkable cells based on the `max_distance`.
func _flood_fill(cell: Vector2, max_distance: int) -> Array:
	var array := []
	var stack := [cell]
	while not stack.size() == 0:
		var current = stack.pop_back()
		if not grid.is_within_bounds(current):
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
			if is_occupied(coordinates):
				continue
			if coordinates in array:
				continue
			# Minor optimization: If this neighbor is already queued
			#	to be checked, we don't need to queue it again
			if coordinates in stack:
				continue

			stack.append(coordinates)
	return array


# Movement function moved to ActionExecutor.gd - now handled by _execute_movement_async()


## Selects the unit in the `cell` if there's one there.
## Sets it as the `_active_unit` and draws its walkable cells and interactive move path. 
func _select_unit(cell: Vector2) -> void:
	if not _units.has(cell):
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

	var unit = _units[cell]
	
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
	if _active_unit == null:
		print("Warning: _deselect_active_unit called but _active_unit is null")
		return
		
	_active_unit.is_selected = false
	_unit_overlay.clear()
	_unit_path.stop()
	
	# Emit signals for UI updates
	emit_signal("unit_info_deselected")  # Clear info panel


## Clears the reference to the _active_unit and the corresponding walkable cells.
func _clear_active_unit() -> void:
	_active_unit = null
	_walkable_cells.clear()


## Selects, moves, or attacks based on where the cursor is.
func _on_Cursor_accept_pressed(cell: Vector2) -> void:
	# Check if there's a unit at the clicked cell
	var unit_at_cell = _units.get(cell)
	
	if not _active_unit:
		# No unit selected, try to select one
		_select_unit(cell)
	elif _active_unit.is_selected:
		if _mode_manager.is_attack_mode_active():
			# Attack mode active - try to attack target
			if unit_at_cell and is_instance_valid(unit_at_cell) and _action_executor.is_valid_attack_target(_active_unit, unit_at_cell):
				await _action_executor.execute_attack(_active_unit, unit_at_cell)
			else:
				print("No valid target at clicked cell")
			return
		elif unit_at_cell:
			# Clicking on any unit - update info panel (independent component)
			if _turn_manager and _turn_manager.active_unit and _turn_manager.active_unit.unit_type == Unit.UnitType.UNIT_PLAYER:
				emit_signal("unit_info_selected", unit_at_cell)
				print("Info panel updated for: ", unit_at_cell.name, " (turn unit: ", _turn_manager.active_unit.name, ")")
			
			# Only allow action control for the current turn's unit (simplified architecture)
			if unit_at_cell == _turn_manager.active_unit and unit_at_cell != _active_unit:
				# This should rarely happen since _active_unit is set on turn start,
				# but handle the case where somehow they're out of sync
				print("Resetting active unit to match turn manager")
				# Cancel any active modes first (visuals cleaned up by internal handlers)
				_mode_manager.cancel_all_modes()
				_deselect_active_unit()
				_clear_active_unit()
				_select_unit(cell)
			return
		else:
			# Clicking empty cell - only allow movement if move mode is active
			if not _mode_manager.is_move_mode_active():
				print("Move mode not active - click MOVE button in action panel first!")
				return
			# Check if the clicked cell is a valid move target
			if is_occupied(cell) or not cell in _walkable_cells:
				# Invalid move target - for player units, cancel move mode and return to Layer 1
				if _active_unit and _active_unit.unit_type == Unit.UnitType.UNIT_PLAYER:
					print("Invalid move target - cancelling move mode")
					_mode_manager.cancel_move_mode()
					# Clear move visuals but keep unit selected and action panel visible
					_unit_overlay.clear()
					_unit_path.stop()
				else:
					print("Invalid move target for AI unit")
				return
			# Valid move target - execute movement
			_execute_movement_async(cell)


## Async wrapper for movement execution
func _execute_movement_async(target_cell: Vector2) -> void:
	if not _active_unit:
		return
	
	# Execute movement through ActionExecutor
	var success = await _action_executor.execute_movement(_active_unit, target_cell)
	if success:
		# Movement completed successfully, handled by _on_action_completed signal
		pass
	else:
		print("GameBoard: Movement execution failed")

## Updates the interactive path's drawing if there's an active and selected unit.
func _on_Cursor_moved(new_cell: Vector2) -> void:
	if _mode_manager.is_move_mode_active() and _active_unit and _active_unit.is_selected:
		_unit_path.draw(_active_unit.cell, new_cell)

## Called when move mode is toggled from inventory UI
func _on_move_mode_changed(is_active: bool) -> void:
	_mode_manager._on_move_mode_changed(is_active)
	
	if _active_unit and _active_unit.is_selected:
		if is_active:
			# Layer 2: Show move overlay and initialize path
			_unit_overlay.draw(_walkable_cells)
			_unit_path.initialize(_walkable_cells)
			print("GameBoard: Move mode enabled - showing move range (Layer 2)")
		else:
			# Back to Layer 1: Hide overlay but keep unit selected
			_unit_overlay.clear()
			_unit_path.stop()
			print("GameBoard: Move mode disabled - back to Layer 1 (unit still selected)")
	else:
		print("GameBoard: Move mode ", "enabled" if is_active else "disabled", " (no unit selected)")

## Called when attack mode is toggled from inventory UI
func _on_attack_mode_changed(is_active: bool) -> void:
	_mode_manager._on_attack_mode_changed(is_active)
	
	if _active_unit and _active_unit.is_selected:
		if is_active:
			# Clear any active move visuals when switching to attack mode
			_unit_overlay.clear()
			_unit_path.stop()
			
			# Layer 2: Show attack overlay and find targets
			_action_executor.show_attack_range(_active_unit)
			_action_executor.highlight_valid_targets(_active_unit)
			print("GameBoard: Attack mode enabled - showing attack range (Layer 2)")
		else:
			# Back to Layer 1: Hide overlay but keep unit selected
			_action_executor.clear_attack_range()
			print("GameBoard: Attack mode disabled - back to Layer 1 (unit still selected)")
	else:
		print("GameBoard: Attack mode ", "enabled" if is_active else "disabled", " (no unit selected)")

## Registers all units with the turn manager
func _register_all_units() -> void:
	for child in get_children():
		var unit := child as Unit
		if unit:
			_turn_manager.register_unit(unit)
			# Connect unit turn ended signal
			unit.turn_ended.connect(_on_unit_turn_ended)

## Called when turn changes
func _on_turn_changed(current_unit: Unit, turn_number: int) -> void:
	print("GameBoard: Turn changed to ", current_unit.name, " (Turn ", turn_number, ")")
	
	# Ensure board is not busy during turn transitions
	_board_busy = false
	
	# Clean up previous turn's UI state
	if _active_unit:
		print("GameBoard: Cleaning up previous turn state")
		_mode_manager.cancel_all_modes()
		_deselect_active_unit()
		_clear_active_unit()
	
	# Set active unit for player turns (simplified architecture)
	if current_unit.unit_type == Unit.UnitType.UNIT_PLAYER:
		_active_unit = current_unit
		_active_unit.is_selected = true
		_walkable_cells = _action_executor.get_walkable_cells(_active_unit)
		print("GameBoard: Player turn started - active unit set to ", _active_unit.name)
	else:
		emit_signal("unit_info_deselected")
		print("GameBoard: AI/NPC turn - info panel cleared")
	
	# Update unit active state
	for child in get_children():
		var unit := child as Unit
		if unit:
			unit.is_active_turn = (unit == current_unit)

## Called when round completes
func _on_round_completed(round_number: int) -> void:
	print("GameBoard: Round ", round_number, " started")

## Called when a unit ends their turn
func _on_unit_turn_ended() -> void:
	if _turn_manager:
		_turn_manager.end_current_turn()

## Internal handler for move mode cancellation - handles visual cleanup + signal forwarding
func _on_move_mode_cancelled_internal() -> void:
	# Clean up move visuals
	_unit_overlay.clear()
	_unit_path.stop()
	
	# Forward signal to external listeners
	emit_signal("move_mode_cancelled")
	print("GameBoard: Move mode visuals cleaned up")

## Internal handler for attack mode cancellation - handles visual cleanup + signal forwarding  
func _on_attack_mode_cancelled_internal() -> void:
	# Clean up attack visuals
	_action_executor.clear_attack_range()
	
	# Forward signal to external listeners
	emit_signal("attack_mode_cancelled")
	print("GameBoard: Attack mode visuals cleaned up")

# Attack range and target highlighting functions moved to ActionExecutor.gd

# Attack execution function moved to ActionExecutor.gd

## Removes a unit from the board when it dies
func _remove_unit_from_board(unit: Unit) -> void:
	if not is_instance_valid(unit):
		print("GameBoard: Warning - trying to remove invalid unit")
		return
		
	var unit_cell = unit.cell  # Keep as Vector2 to match dictionary key type
	
	# Remove from units dictionary
	if _units.has(unit_cell):
		var unit_at_position = _units[unit_cell]
		# Only remove if it's actually the same unit object
		if unit_at_position == unit:
			_units.erase(unit_cell)
		else:
			print("GameBoard: WARNING - Different unit at position during cleanup")
	
	# Remove from turn manager
	if _turn_manager:
		_turn_manager.unregister_unit(unit)
	
	# Clean up any active unit references
	if _active_unit == unit:
		print("GameBoard: Cleared active unit reference for dead unit")
		_active_unit = null
		emit_signal("unit_info_deselected")
	
	# Disconnect signals to prevent issues
	if unit.turn_ended.is_connected(_on_unit_turn_ended):
		unit.turn_ended.disconnect(_on_unit_turn_ended)
	
	# Visual cleanup - could add death animation here
	unit.visible = false
	unit.queue_free()

## Handles unit death signal from ActionExecutor
func _on_unit_died(unit: Unit) -> void:
	if is_instance_valid(unit):
		_remove_unit_from_board(unit)

## Handles action completion from ActionExecutor
func _on_action_completed(action_type: String, unit: Unit) -> void:
	print("GameBoard: Action completed - ", action_type, " by ", unit.name if unit else "unknown unit")
	
	if action_type == "move":
		# Movement completed - cancel move mode and return to Layer 1 (unit selected)
		if unit and unit.unit_type == Unit.UnitType.UNIT_PLAYER:
			# Cancel move mode to return to Layer 1
			_mode_manager.cancel_move_mode()
			# Re-activate the unit and update unit info
			_active_unit = unit
			_walkable_cells = _action_executor.get_walkable_cells(_active_unit)
			emit_signal("unit_info_selected", unit)
			print("Player movement complete - walkable cells updated for new position")
	elif action_type == "attack":
		# Attack completed - exit attack mode
		if unit and unit.is_alive():
			_mode_manager.cancel_attack_mode()  # Visuals cleaned up by internal handler
			# Note: No automatic turn ending - players must press END TURN
