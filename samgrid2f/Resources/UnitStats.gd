# UnitStats.gd - Core Combat Statistics Resource
# Comprehensive stats system for turn-based tactical combat
# Integrates with existing movement and turn systems

class_name UnitStats extends Resource

@export_group("Health")
@export var max_hp: int = 100
@export var current_hp: int = 100

@export_group("Action Economy")
@export var max_ap: int = 2  # Action Points per turn
@export var current_ap: int = 2
@export var movement_cost: int = 1  # AP cost to move
@export var attack_cost: int = 1  # AP cost to attack

@export_group("Movement") 
@export var move_range: int = 6  # Distance unit can move in cells
@export var move_speed: float = 600.0  # Movement animation speed
@export var moves_remaining: int = 6  # Moves remaining this turn

@export_group("Combat Stats")
@export var attack_damage: int = 25
@export var attack_range: int = 1  # 1 = melee, 2+ = ranged
@export var defense: int = 5
@export var accuracy: int = 90  # Percentage
@export var evasion: int = 10  # Percentage
@export var critical_chance: int = 10  # Percentage
@export var critical_multiplier: float = 1.5

@export_group("Status Flags")
@export var is_alive: bool = true
@export var has_moved: bool = false
@export var has_attacked: bool = false
@export var can_counter: bool = true  # For counter-attacks

func _init():
	current_hp = max_hp
	current_ap = max_ap
	moves_remaining = move_range

func reset_turn_stats() -> void:
	current_ap = max_ap
	moves_remaining = move_range
	has_moved = false
	has_attacked = false
	can_counter = true

func take_damage(amount: int) -> int:
	var old_hp = current_hp
	current_hp = max(0, current_hp - amount)
	var actual_damage = old_hp - current_hp
	
	if current_hp <= 0 and is_alive:
		is_alive = false
	
	return actual_damage

func heal(amount: int) -> int:
	var old_hp = current_hp
	current_hp = min(max_hp, current_hp + amount)
	var actual_healing = current_hp - old_hp
	return actual_healing

func can_act() -> bool:
	return current_ap > 0 and is_alive

func can_move() -> bool:
	return current_ap >= movement_cost and is_alive and moves_remaining > 0

func can_attack() -> bool:
	return current_ap >= attack_cost and is_alive

func consume_ap(amount: int) -> bool:
	if current_ap >= amount:
		current_ap -= amount
		return true
	return false

func consume_movement(tiles: int) -> bool:
	if moves_remaining >= tiles:
		moves_remaining -= tiles
		has_moved = true
		return true
	return false

func get_health_percentage() -> float:
	if max_hp <= 0:
		return 0.0
	return float(current_hp) / float(max_hp)

func is_at_full_health() -> bool:
	return current_hp == max_hp

func is_critically_wounded() -> bool:
	return get_health_percentage() <= 0.25

func get_status_text() -> String:
	var status_parts: Array[String] = []
	
	if not is_alive:
		status_parts.append("Dead")
	elif is_critically_wounded():
		status_parts.append("Critical")
	
	if has_moved:
		status_parts.append("Moved")
	if has_attacked:
		status_parts.append("Attacked")
	if current_ap <= 0:
		status_parts.append("Exhausted")
	
	return ", ".join(status_parts) if not status_parts.is_empty() else "Ready"
