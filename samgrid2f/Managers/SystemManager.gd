# SystemManager.gd - Base System Manager Template
# Base class for all system managers (Combat, Inventory, AI, etc.)
# Provides common functionality and EventBus integration pattern

class_name SystemManager extends Node

@export var system_name: String = "BaseSystem"
@export var auto_initialize: bool = true
@export var debug_logging: bool = false

var is_initialized: bool = false
var registered_units: Dictionary = {}  # unit_id -> IUnit

func _ready():
	if auto_initialize:
		initialize()

# Override this in derived managers
func initialize() -> void:
	if is_initialized:
		return
		
	_connect_signals()
	_setup_system()
	is_initialized = true
	
	if debug_logging:
		print(system_name, ": System initialized")

# Override this to connect to specific EventBus signals
func _connect_signals() -> void:
	# Base connections that most systems need
	if EventBus:
		EventBus.unit_spawned.connect(_on_unit_spawned)
		EventBus.unit_despawned.connect(_on_unit_despawned)
		EventBus.game_paused.connect(_on_game_paused)
		EventBus.game_resumed.connect(_on_game_resumed)

# Override this for system-specific setup
func _setup_system() -> void:
	pass

# Unit registration methods
func register_unit(unit: IUnit) -> void:
	if not unit:
		print("Warning: Attempting to register null unit to ", system_name)
		return
		
	var unit_data = unit.get_unit_data()
	if not unit_data:
		print("Warning: Unit has no UnitData for ", system_name)
		return
	
	var unit_id = unit_data.unit_id
	if unit_id.is_empty():
		print("Warning: Unit has no ID for ", system_name) 
		return
	
	registered_units[unit_id] = unit
	_on_unit_registered(unit)
	
	if debug_logging:
		print(system_name, ": Registered unit ", unit_id)

func unregister_unit(unit: IUnit) -> void:
	if not unit:
		return
		
	var unit_data = unit.get_unit_data()
	if not unit_data:
		return
	
	var unit_id = unit_data.unit_id
	if registered_units.has(unit_id):
		registered_units.erase(unit_id)
		_on_unit_unregistered(unit)
		
		if debug_logging:
			print(system_name, ": Unregistered unit ", unit_id)

func get_registered_unit(unit_id: String) -> IUnit:
	return registered_units.get(unit_id, null)

func get_all_registered_units() -> Array[IUnit]:
	var units: Array[IUnit] = []
	for unit in registered_units.values():
		units.append(unit)
	return units

# Override these in derived managers
func _on_unit_registered(unit: IUnit) -> void:
	pass

func _on_unit_unregistered(unit: IUnit) -> void:
	pass

# EventBus signal handlers
func _on_unit_spawned(unit: IUnit, position: Vector2i) -> void:
	register_unit(unit)

func _on_unit_despawned(unit: IUnit) -> void:
	unregister_unit(unit)

func _on_game_paused() -> void:
	# Override for system-specific pause behavior
	pass

func _on_game_resumed() -> void:
	# Override for system-specific resume behavior  
	pass

# Utility methods
func log_debug(message: String) -> void:
	if debug_logging:
		print(system_name, ": ", message)

func emit_system_event(event: String, data: Dictionary = {}) -> void:
	if EventBus:
		EventBus.emit_system_event(system_name, event, data)

# Cleanup
func _exit_tree():
	registered_units.clear()
	is_initialized = false
