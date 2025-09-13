# CombatManager.gd - Combat System Manager
# Handles damage calculations, combat resolution, and combat-related events
# Example implementation of the SystemManager pattern

class_name CombatManager extends SystemManager

# Combat settings
@export var critical_hit_multiplier: float = 1.5
@export var flanking_bonus: int = 10
@export var height_advantage_bonus: int = 5

# Combat state tracking
var active_combats: Dictionary = {}  # attacker_id -> target_id
var combat_queue: Array[Dictionary] = []

func _ready():
	system_name = "CombatManager"
	super._ready()

func _connect_signals():
	super._connect_signals()
	
	if EventBus:
		EventBus.attack_started.connect(_on_attack_started)
		EventBus.damage_dealt.connect(_on_damage_dealt)
		EventBus.unit_died.connect(_on_unit_died)

func _setup_system():
	log_debug("Combat system initialized with critical multiplier: " + str(critical_hit_multiplier))

# Main combat resolution method
func resolve_attack(attacker: IUnit, target: IUnit, position_context: Dictionary = {}) -> Dictionary:
	if not attacker or not target:
		return {"success": false, "error": "Invalid combatants"}
	
	if not attacker.is_alive() or not target.is_alive():
		return {"success": false, "error": "Dead unit cannot participate in combat"}
	
	var attacker_data = attacker.get_unit_data()
	var target_data = target.get_unit_data()
	
	# Calculate base damage
	var base_damage = calculate_base_damage(attacker_data, target_data)
	
	# Apply modifiers
	var final_damage = apply_damage_modifiers(base_damage, attacker, target, position_context)
	
	# Accuracy check
	if not accuracy_check(attacker_data, target_data):
		EventBus.attack_started.emit(attacker, target)
		return {
			"success": true, 
			"hit": false, 
			"damage": 0,
			"message": "Attack missed!"
		}
	
	# Critical hit check
	var is_critical = critical_hit_check(attacker_data)
	if is_critical:
		final_damage = int(final_damage * critical_hit_multiplier)
	
	# Apply damage
	var actual_damage = target_data.take_damage(final_damage)
	
	# Emit combat events
	EventBus.attack_started.emit(attacker, target)
	EventBus.damage_dealt.emit(attacker, target, actual_damage)
	EventBus.attack_completed.emit(attacker, target, actual_damage)
	
	return {
		"success": true,
		"hit": true,
		"damage": actual_damage,
		"critical": is_critical,
		"target_died": not target.is_alive(),
		"message": "Attack hit for " + str(actual_damage) + " damage" + (" (Critical!)" if is_critical else "")
	}

func calculate_base_damage(attacker_data: UnitData, target_data: UnitData) -> int:
	var attack_value = attacker_data.get_total_attack()
	var defense_value = target_data.get_total_defense()
	
	# Basic damage formula: Attack - Defense, minimum 1
	var damage = max(1, attack_value - defense_value)
	
	# Add some randomness (±20%)
	var variance = damage * 0.2
	damage += randi_range(-variance, variance)
	
	return max(1, int(damage))

func apply_damage_modifiers(base_damage: int, attacker: IUnit, target: IUnit, context: Dictionary) -> int:
	var modified_damage = base_damage
	
	# Flanking bonus
	if context.get("flanking", false):
		modified_damage += flanking_bonus
		log_debug("Flanking bonus applied: +" + str(flanking_bonus))
	
	# Height advantage
	if context.get("height_advantage", false):
		modified_damage += height_advantage_bonus
		log_debug("Height advantage bonus applied: +" + str(height_advantage_bonus))
	
	# Type effectiveness (could be expanded)
	var type_modifier = get_type_effectiveness(attacker.get_unit_type(), target.get_unit_type())
	modified_damage = int(modified_damage * type_modifier)
	
	return max(1, modified_damage)

func get_type_effectiveness(attacker_type: Unit.UnitType, target_type: Unit.UnitType) -> float:
	# Simple type effectiveness system - can be expanded
	match [attacker_type, target_type]:
		[Unit.UnitType.UNIT_PLAYER, Unit.UnitType.UNIT_CPU]:
			return 1.0  # Normal effectiveness
		[Unit.UnitType.UNIT_CPU, Unit.UnitType.UNIT_PLAYER]:
			return 1.0  # Normal effectiveness
		_:
			return 1.0  # Default to normal

func accuracy_check(attacker_data: UnitData, target_data: UnitData) -> bool:
	var hit_chance = attacker_data.accuracy
	
	# Could add evasion stat to target_data later
	# hit_chance -= target_data.evasion
	
	var roll = randi_range(1, 100)
	return roll <= hit_chance

func critical_hit_check(attacker_data: UnitData) -> bool:
	var crit_chance = attacker_data.critical_chance
	var roll = randi_range(1, 100)
	return roll <= crit_chance

# Combat state management
func _on_attack_started(attacker: IUnit, target: IUnit):
	var attacker_data = attacker.get_unit_data()
	var target_data = target.get_unit_data()
	
	active_combats[attacker_data.unit_id] = target_data.unit_id
	log_debug("Combat started: " + attacker_data.unit_name + " vs " + target_data.unit_name)

func _on_damage_dealt(attacker: IUnit, target: IUnit, amount: int):
	var attacker_data = attacker.get_unit_data()
	var target_data = target.get_unit_data()
	
	log_debug(attacker_data.unit_name + " dealt " + str(amount) + " damage to " + target_data.unit_name)

func _on_unit_died(unit: IUnit):
	var unit_data = unit.get_unit_data()
	log_debug("Unit died: " + unit_data.unit_name)
	
	# Remove from active combats
	active_combats.erase(unit_data.unit_id)
	for attacker_id in active_combats.keys():
		if active_combats[attacker_id] == unit_data.unit_id:
			active_combats.erase(attacker_id)

# Utility methods
func can_attack(attacker: IUnit, target: IUnit) -> Dictionary:
	if not attacker or not target:
		return {"can_attack": false, "reason": "Invalid units"}
	
	if not attacker.is_alive():
		return {"can_attack": false, "reason": "Attacker is dead"}
	
	if not target.is_alive():
		return {"can_attack": false, "reason": "Target is dead"}
	
	if attacker.get_team_id() == target.get_team_id():
		return {"can_attack": false, "reason": "Cannot attack allies"}
	
	# Range check would go here
	# var distance = get_distance(attacker.get_grid_position(), target.get_grid_position())
	# if distance > attack_range: return false
	
	return {"can_attack": true, "reason": ""}

func get_combat_preview(attacker: IUnit, target: IUnit) -> Dictionary:
	if not attacker or not target:
		return {}
	
	var attacker_data = attacker.get_unit_data() 
	var target_data = target.get_unit_data()
	
	var base_damage = calculate_base_damage(attacker_data, target_data)
	var hit_chance = attacker_data.accuracy
	var crit_chance = attacker_data.critical_chance
	
	return {
		"min_damage": max(1, base_damage - int(base_damage * 0.2)),
		"max_damage": base_damage + int(base_damage * 0.2),
		"crit_damage": int((base_damage + int(base_damage * 0.2)) * critical_hit_multiplier),
		"hit_chance": hit_chance,
		"crit_chance": crit_chance,
		"will_kill": base_damage >= target_data.current_health
	}