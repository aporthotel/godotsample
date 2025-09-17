# GameConfig.gd - Configuration Resource
# Centralized settings for all game systems
# Tunable values that systems can reference without hard-coding

class_name GameConfig extends Resource

@export_group("Gameplay Settings")
@export var enable_fog_of_war: bool = false
@export var ai_difficulty: int = 1  # 1-5 scale
@export var turn_time_limit: float = 30.0  # seconds, 0 = unlimited
@export var auto_end_turn: bool = false

@export_group("Combat Settings")
@export var critical_hit_multiplier: float = 1.5
@export var flanking_bonus: int = 10
@export var height_advantage_bonus: int = 5
@export var enable_friendly_fire: bool = false

@export_group("Movement Settings")  
@export var movement_animation_speed: float = 1.0
@export var allow_diagonal_movement: bool = true
@export var movement_cost_diagonal: float = 1.4  # sqrt(2) approximation

@export_group("UI Settings")
@export var show_damage_numbers: bool = true
@export var show_movement_preview: bool = true
@export var show_attack_range: bool = true
@export var ui_animation_speed: float = 1.0

@export_group("Audio Settings")
@export var master_volume: float = 1.0
@export var sfx_volume: float = 1.0  
@export var music_volume: float = 0.7
@export var ui_sound_volume: float = 0.8

@export_group("Inventory Settings")
@export var max_inventory_size: int = 20
@export var auto_pickup_items: bool = true
@export var stack_similar_items: bool = true
@export var show_item_tooltips: bool = true

@export_group("Save Settings")
@export var auto_save_interval: float = 300.0  # 5 minutes
@export var max_save_slots: int = 10
@export var compress_saves: bool = true

@export_group("Debug Settings")
@export var debug_mode: bool = false
@export var show_grid_coordinates: bool = false
@export var show_pathfinding_debug: bool = false
@export var log_ai_decisions: bool = false

@export_group("Performance Settings")
@export var max_particles: int = 100
@export var enable_vsync: bool = true
@export var target_fps: int = 60
@export var reduce_effects_on_low_fps: bool = true

# Static instance for global access
static var instance: GameConfig

func _init():
	if not instance:
		instance = self

static func get_setting(setting_path: String, default_value = null):
	if not instance:
		print("Warning: GameConfig not initialized")
		return default_value
		
	var parts = setting_path.split(".")
	var current = instance
	
	for part in parts:
		if current.has_method("get"):
			current = current.get(part)
		else:
			return default_value
	
	return current if current != null else default_value

static func set_setting(setting_path: String, value):
	if not instance:
		print("Warning: GameConfig not initialized")
		return
	
	var parts = setting_path.split(".")
	var current = instance
	
	# Navigate to the parent of the final property
	for i in range(parts.size() - 1):
		current = current.get(parts[i])
		if current == null:
			print("Warning: Invalid setting path: ", setting_path)
			return
	
	# Set the final property
	var final_property = parts[-1]
	if current.has_method("set"):
		current.set(final_property, value)
		
		# Signal the change through EventBus
		if EventBus:
			EventBus.setting_changed.emit(setting_path, value)
	else:
		print("Warning: Cannot set property: ", final_property)