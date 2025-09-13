# ItemData.gd - Item Resource Definition  
# Shared data structure for all items, equipment, and consumables
# Used by Inventory, Combat, and Save/Load systems

class_name ItemData extends Resource

enum ItemType {
	WEAPON,
	ARMOR, 
	ACCESSORY,
	CONSUMABLE,
	QUEST_ITEM,
	MATERIAL
}

enum ItemRarity {
	COMMON,
	UNCOMMON, 
	RARE,
	EPIC,
	LEGENDARY
}

@export_group("Identity")
@export var item_id: String = ""
@export var item_name: String = ""
@export var description: String = ""
@export var item_type: ItemType = ItemType.CONSUMABLE
@export var rarity: ItemRarity = ItemRarity.COMMON

@export_group("Properties")
@export var stack_size: int = 1
@export var weight: int = 1
@export var value: int = 10
@export var is_consumable: bool = false
@export var is_quest_item: bool = false

@export_group("Combat Bonuses")
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var health_bonus: int = 0
@export var accuracy_bonus: int = 0
@export var critical_bonus: int = 0
@export var movement_bonus: int = 0

@export_group("Consumable Effects") 
@export var healing_amount: int = 0
@export var mana_restore: int = 0
@export var buff_duration: float = 0.0
@export var status_effects: Array[String] = []

@export_group("Visual")
@export var icon_texture: Texture2D = null
@export var world_sprite: Texture2D = null

# Equipment slot requirements
@export var required_level: int = 1
@export var class_restrictions: Array[String] = []

func _init(p_item_id: String = "", p_item_name: String = ""):
	item_id = p_item_id
	item_name = p_item_name

func can_be_equipped_by(unit_data: UnitData) -> bool:
	if not unit_data:
		return false
		
	# Level requirement
	if unit_data.level < required_level:
		return false
		
	# Weight requirement  
	if unit_data.current_equipment_weight + weight > unit_data.max_equipment_weight:
		return false
		
	return true

func use_item(unit_data: UnitData) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"effects": []
	}
	
	if not is_consumable:
		result.message = "Item is not consumable"
		return result
	
	if not unit_data:
		result.message = "No target unit"
		return result
	
	# Apply healing
	if healing_amount > 0:
		var healed = unit_data.heal(healing_amount)
		result.effects.append({"type": "heal", "amount": healed})
	
	# Apply status effects
	for effect in status_effects:
		result.effects.append({"type": "status", "effect": effect, "duration": buff_duration})
	
	result.success = true
	result.message = "Item used successfully"
	
	# Signal through EventBus
	if EventBus:
		EventBus.item_used.emit(self, unit_data)
	
	return result

func get_total_stat_bonus(stat_name: String) -> int:
	match stat_name:
		"attack": return attack_bonus
		"defense": return defense_bonus
		"health": return health_bonus
		"accuracy": return accuracy_bonus
		"critical": return critical_bonus
		"movement": return movement_bonus
		_: return 0

func get_rarity_color() -> Color:
	match rarity:
		ItemRarity.COMMON: return Color.WHITE
		ItemRarity.UNCOMMON: return Color.GREEN
		ItemRarity.RARE: return Color.BLUE
		ItemRarity.EPIC: return Color.PURPLE
		ItemRarity.LEGENDARY: return Color.ORANGE
		_: return Color.WHITE