## Represents a unit on the game board.
## The board manages its position inside the game grid.
## The unit itself holds stats and a visual representation that moves smoothly in the game world.
@tool
class_name Unit
extends Path2D

## Unit types for different behaviors
enum UnitType {
	UNIT_PLAYER,  ## Player-controlled units
	UNIT_CPU,     ## AI-controlled enemy units
	UNIT_NPC      ## Basic wandering NPCs
}

## Emitted when the unit reached the end of a path along which it was walking.
signal walk_finished
## Emitted when the unit's turn ends
signal turn_ended
## Emitted when unit's HP changes
signal hp_changed(new_hp: int, max_hp: int)
## Emitted when unit's AP changes
signal ap_changed(new_ap: int, max_ap: int)
## Emitted when unit dies
signal unit_died(unit: Unit)

## Shared resource of type Grid, used to calculate map coordinates.
#@export var grid: Resource
@export var grid: Grid

## Type of unit determining its behavior
@export var unit_type: UnitType = UnitType.UNIT_PLAYER

@export_group("Combat Stats")
## Combat and action statistics - Create New UnitStats resource or assign existing one
@export var stats: UnitStats

## Texture representing the unit.
@export var skin: Texture:
	set(value):
		skin = value
		if not _sprite:
			# This will resume execution after this node's _ready()
			await ready
		_sprite.texture = value
## Offset to apply to the `skin` sprite in pixels.
@export var skin_offset := Vector2.ZERO:
	set(value):
		skin_offset = value
		if not _sprite:
			await ready
		_sprite.position = value

## Coordinates of the current cell the cursor moved to.
var cell := Vector2.ZERO:
	set(value):
		# When changing the cell's value, we don't want to allow coordinates outside
		#	the grid, so we clamp them
		cell = grid.grid_clamp(value)
## Toggles the "selected" animation on the unit.
var is_selected := false:
	set(value):
		is_selected = value
		if is_selected:
			_anim_player.play("selected")
		else:
			_anim_player.play("idle")

## Whether this unit is currently having its turn
var is_active_turn := false:
	set(value):
		is_active_turn = value
		# Visual indicator for active turn (can be expanded later)
		if is_active_turn:
			modulate = Color(1.2, 1.2, 1.2, 1.0)  # Slightly brighter
			# Reset turn stats when starting turn (AP recovery)
			if stats:
				stats.reset_turn_stats()
				print(name, ": Turn started - AP restored to ", stats.current_ap)
		else:
			modulate = Color.WHITE

var _is_walking := false:
	set(value):
		_is_walking = value
		set_process(_is_walking)

@onready var _sprite: Sprite2D = $PathFollow2D/Sprite
@onready var _anim_player: AnimationPlayer = $AnimationPlayer
@onready var _path_follow: PathFollow2D = $PathFollow2D


func _ready() -> void:
	set_process(false)
	_path_follow.rotates = false

	cell = grid.calculate_grid_coordinates(position)
	position = grid.calculate_map_position(cell)

	# Initialize stats if not assigned
	if not stats:
		stats = UnitStats.new()
	
	# Initialize movement system from UnitStats
	stats.moves_remaining = stats.move_range

	# We create the curve resource here because creating it in the editor prevents us from
	# moving the unit.
	if not Engine.is_editor_hint():
		curve = Curve2D.new()


func _process(delta: float) -> void:
	var current_speed = stats.move_speed if stats else 600.0
	_path_follow.progress += current_speed * delta

	if _path_follow.progress_ratio >= 1.0:
		_is_walking = false
		# Setting this value to 0.0 causes a Zero Length Interval error
		_path_follow.progress = 0.00001
		position = grid.calculate_map_position(cell)
		curve.clear_points()
		emit_signal("walk_finished")


## Starts walking along the `path`.
## `path` is an array of grid coordinates that the function converts to map coordinates.
func walk_along(path: PackedVector2Array) -> void:
	if path.is_empty():
		return

	# Clear previous curve data to prevent "zero length interval" error
	curve.clear_points()
	curve.add_point(Vector2.ZERO)
	for point in path:
		curve.add_point(grid.calculate_map_position(point) - position)
	cell = path[-1]
	_is_walking = true

## Ends this unit's turn
func end_turn() -> void:
	is_active_turn = false
	if stats:
		stats.reset_turn_stats()
		# Movement system already resets remaining moves in reset_turn_stats()
	turn_ended.emit()
	print("Turn ended for: ", name)

## Combat and stats methods
func take_damage(amount: int) -> int:
	if not stats:
		return 0
	
	var actual_damage = stats.take_damage(amount)
	hp_changed.emit(stats.current_hp, stats.max_hp)
	
	# Emit through EventBus if available
	if EventBus:
		EventBus.health_changed.emit(self, stats.current_hp, stats.max_hp)
	
	if not stats.is_alive:
		print(name, ": Unit died! HP = ", stats.current_hp)
		unit_died.emit(self)
		if EventBus:
			EventBus.unit_died.emit(self)
	
	return actual_damage

func heal(amount: int) -> int:
	if not stats:
		return 0
	
	var actual_healing = stats.heal(amount)
	hp_changed.emit(stats.current_hp, stats.max_hp)
	
	if EventBus:
		EventBus.health_changed.emit(self, stats.current_hp, stats.max_hp)
	
	return actual_healing

func can_act() -> bool:
	return stats and stats.can_act()

func can_move() -> bool:
	return stats and stats.can_move()

func can_attack() -> bool:
	return stats and stats.can_attack()

func consume_ap(amount: int) -> bool:
	if not stats:
		return false
	
	var success = stats.consume_ap(amount)
	if success:
		ap_changed.emit(stats.current_ap, stats.max_ap)
	return success

func get_grid_position() -> Vector2i:
	return Vector2i(cell)

func get_world_position() -> Vector2:
	return position

func is_alive() -> bool:
	return stats and stats.is_alive

func get_team_id() -> String:
	match unit_type:
		UnitType.UNIT_PLAYER:
			return "player"
		UnitType.UNIT_CPU:
			return "enemy"
		UnitType.UNIT_NPC:
			return "neutral"
		_:
			return "unknown"

func get_movement_range() -> int:
	# Return movement range from UnitStats
	if stats:
		return stats.move_range
	return 6  # Default fallback value
