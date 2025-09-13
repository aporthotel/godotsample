# IUnit.gd - Unit Interface Contract
# Defines the standard interface that all unit implementations must follow
# Ensures compatibility across different systems and managers

class_name IUnit

# Position and Grid Methods
func get_grid_position() -> Vector2i:
	assert(false, "IUnit.get_grid_position() must be implemented")
	return Vector2i.ZERO

func set_grid_position(position: Vector2i) -> void:
	assert(false, "IUnit.set_grid_position() must be implemented")

func get_world_position() -> Vector2:
	assert(false, "IUnit.get_world_position() must be implemented")
	return Vector2.ZERO

# Unit Data Access
func get_unit_data() -> UnitData:
	assert(false, "IUnit.get_unit_data() must be implemented")
	return null

func set_unit_data(data: UnitData) -> void:
	assert(false, "IUnit.set_unit_data() must be implemented")

# Health and Status
func get_current_health() -> int:
	assert(false, "IUnit.get_current_health() must be implemented")
	return 0

func get_max_health() -> int:
	assert(false, "IUnit.get_max_health() must be implemented")
	return 0

func set_health(value: int) -> void:
	assert(false, "IUnit.set_health() must be implemented")

func is_alive() -> bool:
	assert(false, "IUnit.is_alive() must be implemented")
	return false

# Combat Interface
func can_attack(target: IUnit) -> bool:
	assert(false, "IUnit.can_attack() must be implemented")
	return false

func get_attack_damage() -> int:
	assert(false, "IUnit.get_attack_damage() must be implemented")
	return 0

func get_defense() -> int:
	assert(false, "IUnit.get_defense() must be implemented")  
	return 0

# Movement Interface
func can_move_to(position: Vector2i) -> bool:
	assert(false, "IUnit.can_move_to() must be implemented")
	return false

func get_movement_range() -> int:
	assert(false, "IUnit.get_movement_range() must be implemented")
	return 0

func move_to(position: Vector2i) -> void:
	assert(false, "IUnit.move_to() must be implemented")

# Team and Type
func get_unit_type() -> Unit.UnitType:
	assert(false, "IUnit.get_unit_type() must be implemented")
	return Unit.UnitType.UNIT_PLAYER

func get_team_id() -> String:
	assert(false, "IUnit.get_team_id() must be implemented")
	return ""

# Visual and Animation
func show_highlight(enabled: bool) -> void:
	assert(false, "IUnit.show_highlight() must be implemented")

func play_animation(animation_name: String) -> void:
	assert(false, "IUnit.play_animation() must be implemented")

# Inventory Interface (Optional)
func get_inventory() -> Array:
	# Default implementation returns empty inventory
	return []

func add_item(item: ItemData) -> bool:
	# Default implementation rejects items
	return false

func remove_item(item: ItemData) -> bool:
	# Default implementation rejects removal
	return false
