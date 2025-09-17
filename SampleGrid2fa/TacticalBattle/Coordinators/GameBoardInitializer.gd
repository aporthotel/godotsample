## GameBoardInitializer - Handles GameBoard system initialization
## Extracted from GameBoard.gd to achieve Opus41.md "thin orchestrator" architecture
class_name GameBoardInitializer
extends Node

## Initializes all GameBoard systems, managers, and coordinators
func initialize_systems(gameboard: GameBoard) -> void:
	print("GameBoardInitializer: Starting system initialization")

	# Initialize overlay reference
	_setup_attack_overlay(gameboard)

	# Create and initialize managers (order matters - dependencies)
	_create_managers(gameboard)

	# Create and initialize coordinators
	_create_coordinators(gameboard)

	# Connect all system signals
	_connect_signals(gameboard)

	# Finalize initialization
	await _finalize_initialization(gameboard)

	print("GameBoardInitializer: System initialization complete")

## Sets up attack overlay reference if it exists
func _setup_attack_overlay(gameboard: GameBoard) -> void:
	if gameboard.has_node("AttackOverlay"):
		gameboard._attack_overlay = gameboard.get_node("AttackOverlay")
		print("GameBoard: AttackOverlay found and initialized")
	else:
		print("GameBoard: AttackOverlay not found - attack mode will work without visual overlay")

## Creates and initializes all managers in dependency order
func _create_managers(gameboard: GameBoard) -> void:
	# Create turn manager
	gameboard._turn_manager = preload("res://TacticalBattle/Managers/TurnManager.gd").new()
	gameboard.add_child(gameboard._turn_manager)

	# Create grid state manager first (needed by other managers)
	gameboard._grid_state_manager = preload("res://TacticalBattle/Managers/GridStateManager.gd").new()
	gameboard.add_child(gameboard._grid_state_manager)
	gameboard._grid_state_manager.initialize(gameboard)

	# Create mode manager
	gameboard._mode_manager = preload("res://TacticalBattle/Managers/ModeManager.gd").new()
	gameboard.add_child(gameboard._mode_manager)

	# Create movement executor
	gameboard._movement_executor = preload("res://TacticalBattle/Executors/MovementExecutor.gd").new()
	gameboard.add_child(gameboard._movement_executor)
	gameboard._movement_executor.initialize(gameboard.grid, gameboard._grid_state_manager.get_units_dict(), gameboard._unit_overlay, gameboard._unit_path, gameboard._attack_overlay)
	gameboard._movement_executor._setup_executor()

	# Create combat executor
	gameboard._combat_executor = preload("res://TacticalBattle/Executors/CombatExecutor.gd").new()
	gameboard.add_child(gameboard._combat_executor)
	gameboard._combat_executor.initialize(gameboard.grid, gameboard._grid_state_manager.get_units_dict(), gameboard._unit_overlay, gameboard._unit_path, gameboard._attack_overlay)
	gameboard._combat_executor._setup_executor()

	# Create selection manager (uses movement executor for walkable cells)
	gameboard._selection_manager = preload("res://TacticalBattle/Managers/SelectionManager.gd").new()
	gameboard.add_child(gameboard._selection_manager)
	gameboard._selection_manager.initialize(gameboard._movement_executor)

## Creates and initializes all coordinators (Router Pattern)
func _create_coordinators(gameboard: GameBoard) -> void:
	# Input Handler
	gameboard._input_handler = preload("res://TacticalBattle/Coordinators/InputHandler.gd").new()
	gameboard.add_child(gameboard._input_handler)
	gameboard._input_handler.initialize(gameboard._selection_manager, gameboard._mode_manager, gameboard._movement_executor, gameboard._combat_executor, gameboard._grid_state_manager, gameboard._unit_overlay, gameboard._unit_path)

	# Turn Integrator
	gameboard._turn_integrator = preload("res://TacticalBattle/Coordinators/TurnIntegrator.gd").new()
	gameboard.add_child(gameboard._turn_integrator)
	gameboard._turn_integrator.initialize(gameboard._turn_manager, gameboard._selection_manager, gameboard._mode_manager, gameboard._grid_state_manager)

	# Selection Coordinator
	gameboard._selection_coordinator = preload("res://TacticalBattle/Coordinators/SelectionCoordinator.gd").new()
	gameboard.add_child(gameboard._selection_coordinator)
	gameboard._selection_coordinator.initialize(gameboard._selection_manager, gameboard._grid_state_manager, gameboard._unit_overlay, gameboard._unit_path)

	# Mode Coordinator
	gameboard._mode_coordinator = preload("res://TacticalBattle/Coordinators/ModeCoordinator.gd").new()
	gameboard.add_child(gameboard._mode_coordinator)
	gameboard._mode_coordinator.initialize(gameboard._selection_manager, gameboard._mode_manager, gameboard._movement_executor, gameboard._combat_executor, gameboard._unit_overlay, gameboard._unit_path)

	# Animation Coordinator
	gameboard._animation_coordinator = preload("res://TacticalBattle/Coordinators/AnimationCoordinator.gd").new()
	gameboard.add_child(gameboard._animation_coordinator)
	gameboard._animation_coordinator.initialize(gameboard._selection_manager, gameboard._movement_executor, gameboard._unit_overlay, gameboard._unit_path)

## Connects all system signals
func _connect_signals(gameboard: GameBoard) -> void:
	# Connect turn manager signals
	gameboard._turn_manager.turn_changed.connect(gameboard._on_turn_changed)
	gameboard._turn_manager.round_completed.connect(gameboard._on_round_completed)

	# Connect mode manager signals (forward to external listeners + handle visual cleanup)
	gameboard._mode_manager.move_mode_cancelled.connect(gameboard._on_move_mode_cancelled_internal)
	gameboard._mode_manager.attack_mode_cancelled.connect(gameboard._on_attack_mode_cancelled_internal)

	# Connect executor signals (both movement and combat)
	gameboard._movement_executor.unit_died.connect(gameboard._on_unit_died)
	gameboard._movement_executor.action_completed.connect(gameboard._on_action_completed)
	gameboard._combat_executor.unit_died.connect(gameboard._on_unit_died)
	gameboard._combat_executor.action_completed.connect(gameboard._on_action_completed)

	# Connect coordinator signals (Router Pattern)
	gameboard._input_handler.unit_info_selected.connect(gameboard._on_unit_info_selected)
	gameboard._input_handler.unit_info_deselected.connect(gameboard._on_unit_info_deselected)
	gameboard._input_handler.movement_execution_needed.connect(gameboard._on_movement_execution_needed)
	gameboard._input_handler.attack_execution_needed.connect(gameboard._on_attack_execution_needed)

	gameboard._turn_integrator.unit_info_selected.connect(gameboard._on_unit_info_selected)
	gameboard._turn_integrator.unit_info_deselected.connect(gameboard._on_unit_info_deselected)

	gameboard._selection_coordinator.unit_info_selected.connect(gameboard._on_unit_info_selected)
	gameboard._selection_coordinator.unit_info_deselected.connect(gameboard._on_unit_info_deselected)

	gameboard._animation_coordinator.animation_started.connect(gameboard._on_animation_started)
	gameboard._animation_coordinator.animation_completed.connect(gameboard._on_animation_completed)

## Finalizes initialization and starts the game systems
func _finalize_initialization(gameboard: GameBoard) -> void:
	gameboard._grid_state_manager.reinitialize_grid()

	# Register all units with turn manager after initialization
	print("GameBoard: Waiting for initialization...")
	await gameboard.get_tree().process_frame
	await gameboard.get_tree().process_frame  # Extra delay for safety

	print("GameBoard: Registering units...")
	gameboard._register_all_units()

	print("GameBoard: Emitting ready signal...")
	gameboard.emit_signal("gameboard_ready")

	print("GameBoard: Starting turn sequence...")
	gameboard._turn_manager.start_turn_sequence()
	print("GameBoard: Turn sequence started")