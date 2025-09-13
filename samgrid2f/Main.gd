## Main game controller that handles global input and UI management
extends Node2D

@onready var player_action_ui: PlayerActionUI = $PlayerActionUI
@onready var game_board: GameBoard = $GameBoard
@onready var turn_counter: CanvasLayer = $TurnCounter
@onready var debug_ui: CanvasLayer = $DebugUI
@onready var unit_info_panel: CanvasLayer = $UnitInfoPanel

func _ready() -> void:
	# Connect player action UI signals to game board and main
	player_action_ui.move_mode_changed.connect(game_board._on_move_mode_changed)
	player_action_ui.move_mode_changed.connect(_on_move_mode_changed)
	player_action_ui.attack_mode_changed.connect(game_board._on_attack_mode_changed)
	player_action_ui.attack_mode_changed.connect(_on_attack_mode_changed)
# action_panel_closed signal removed in simplified architecture
	player_action_ui.end_turn_requested.connect(_on_end_turn_requested)
	
	# Connect GameBoard signals (simplified architecture - no unit selection)
	game_board.unit_info_selected.connect(_on_unit_info_selected)
	game_board.unit_info_deselected.connect(_on_unit_info_deselected)
	game_board.move_mode_cancelled.connect(_on_move_mode_cancelled)
	game_board.attack_mode_cancelled.connect(_on_attack_mode_cancelled)
	
	# Wait for GameBoard to be ready, then connect turn manager signals
	game_board.gameboard_ready.connect(_on_gameboard_ready)
	print("Main: Waiting for GameBoard to be ready...")

## Called when GameBoard is fully initialized and ready
func _on_gameboard_ready() -> void:
	print("Main: GameBoard ready! Connecting turn manager signals...")
	game_board._turn_manager.turn_changed.connect(_on_turn_changed)
	game_board._turn_manager.round_completed.connect(_on_round_completed)
	print("Main: Turn manager signals connected successfully!")

# No longer needed - UI shows/hides automatically on unit selection

## Called when turn changes - update UI
func _on_turn_changed(current_unit: Unit, turn_number: int) -> void:
	print("Main: _on_turn_changed called - Unit: ", current_unit.name, " Turn: ", turn_number, " Type: ", current_unit.unit_type)
	
	# Update turn counter
	if turn_counter:
		turn_counter.set_turn(turn_number)
		print("Main: Turn counter updated")
	
	# Update debug UI
	if debug_ui:
		debug_ui.set_current_turn(turn_number)
		debug_ui.set_selected_unit(current_unit.name)
		print("Main: Debug UI updated")
	
	# Auto-show action panel for player units (simplified architecture)
	if current_unit.unit_type == Unit.UnitType.UNIT_PLAYER:
		print("Main: Player unit detected - showing action panel...")
		player_action_ui.show_action_panel()
		player_action_ui.update_unit_display(current_unit)
		if debug_ui:
			debug_ui.set_unit_state("Action Panel Ready")
		print("Main: Action panel shown for player unit: ", current_unit.name)
	else:
		print("Main: Non-player unit - hiding action panel...")
		player_action_ui.hide_action_panel()
		if debug_ui:
			debug_ui.set_unit_state("AI/NPC Turn")
		print("Main: Action panel hidden for AI/NPC unit: ", current_unit.name)

## Called when round completes
func _on_round_completed(round_number: int) -> void:
	print("Main: Round ", round_number, " started")

## Called when move mode changes - update debug state
func _on_move_mode_changed(is_active: bool) -> void:
	if debug_ui:
		if is_active:
			debug_ui.set_unit_state("Move Mode Active")
		else:
			debug_ui.set_unit_state("Action Panel Ready")
	print("Main: Move mode ", "activated" if is_active else "deactivated")

## Called when attack mode changes - update debug state
func _on_attack_mode_changed(is_active: bool) -> void:
	if debug_ui:
		if is_active:
			debug_ui.set_unit_state("Attack Mode Active")
		else:
			debug_ui.set_unit_state("Action Panel Ready")
	print("Main: Attack mode ", "activated" if is_active else "deactivated")

## Called when any unit is selected for info display (all units)
func _on_unit_info_selected(unit: Unit) -> void:
	if unit_info_panel:
		unit_info_panel.set_selected_unit(unit)
	print("Main: Unit info selected: ", unit.name)

## Called when unit info should be cleared
func _on_unit_info_deselected() -> void:
	if unit_info_panel:
		unit_info_panel.clear_selection()
	print("Main: Unit info cleared")

## Action panel no longer closes via ESC in simplified architecture
# _on_action_panel_closed removed - action panel auto-shows/hides with turns

## Called when ESC cancels move mode - turn off move button
func _on_move_mode_cancelled() -> void:
	# Use the safe cancel method to prevent signal recursion
	player_action_ui.cancel_move_mode()
	if debug_ui:
		debug_ui.set_unit_state("Action Panel Ready")
	print("Move mode cancelled via ESC - back to action panel ready")

## Called when ESC cancels attack mode - turn off attack button
func _on_attack_mode_cancelled() -> void:
	# Use the safe cancel method to prevent signal recursion
	player_action_ui.cancel_attack_mode()
	if debug_ui:
		debug_ui.set_unit_state("Action Panel Ready")
	print("Attack mode cancelled via ESC - back to action panel ready")

## Called when END TURN button is pressed
func _on_end_turn_requested() -> void:
	print("Main: End turn requested by player")
	if game_board._turn_manager and game_board._active_unit:
		game_board._turn_manager.end_current_turn()
	else:
		print("Main: Cannot end turn - no active unit or turn manager")
