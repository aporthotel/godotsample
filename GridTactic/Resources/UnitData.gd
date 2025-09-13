# UnitData.gd - Unit Resource Definition
# Shared data structure for all unit statistics and properties
# Used by all systems (Combat, AI, Save/Load) to avoid coupling

class_name UnitData extends Resource

@export_group("Identity")
@export var unit_id: String = ""
@export var unit_name: String = ""
@export var unit_type: Unit.UnitType = Unit.UnitType.UNIT_PLAYER

@export_group("Combat Stats")
@export var max_health: int = 100
@export var current_health: int = 100
@export var attack: int = 10
@export var defense: int = 5
@export var accuracy: int = 85
@export var critical_chance: int = 5

@export_group("Movement")
@export var movement_range: int = 3
@export var movement_speed: float = 200.0

@export_group("Inventory")
@export var inventory_slots: int = 6
@export var max_equipment_weight: int = 50
@export var current_equipment_weight: int = 0

@export_group("AI Behavior")
@export var ai_behavior_type: String = "defensive"
@export var aggression_level: int = 3
@export var preferred_range: int = 2

@export_group("Experience")
@export var level: int = 1
@export var experience: int = 0
@export var experience_to_next_level: int = 100

# Equipment slots
@export var equipped_weapon: Resource = null
@export var equipped_armor: Resource = null
@export var equipped_accessory: Resource = null

func _init(p_unit_id: String = "", p_unit_name: String = ""):
	unit_id = p_unit_id
	unit_name = p_unit_name
	current_health = max_health

func get_total_attack() -> int:
	var total = attack
	if equipped_weapon and equipped_weapon is ItemData:
		total += equipped_weapon.attack_bonus
	return total

func get_total_defense() -> int:
	var total = defense  
	if equipped_armor and equipped_armor is ItemData:
		total += equipped_armor.defense_bonus
	return total

func is_alive() -> bool:
	return current_health > 0

func take_damage(amount: int) -> int:
	var old_health = current_health
	current_health = max(0, current_health - amount)
	var actual_damage = old_health - current_health
	
	# Signal through EventBus
	if EventBus:
		EventBus.health_changed.emit(self, current_health, max_health)
		if current_health <= 0:
			EventBus.unit_died.emit(self)
	
	return actual_damage

func heal(amount: int) -> int:
	var old_health = current_health
	current_health = min(max_health, current_health + amount)
	var actual_healing = current_health - old_health
	
	# Signal through EventBus
	if EventBus:
		EventBus.health_changed.emit(self, current_health, max_health)
	
	return actual_healing

func can_equip_item(item: Resource) -> bool:
	if not item:
		return false
		
	# Check weight limit
	var item_weight = 0
	if item is ItemData:
		item_weight = item.weight
	return (current_equipment_weight + item_weight) <= max_equipment_weight
