extends Camera2D

@export var camera_speed: float = 400.0
@export var edge_scroll_margin: int = 50
@export var edge_scroll_speed: float = 300.0

var screen_size: Vector2

func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	enabled = true
	#print("Camera2D initialized at position: ", global_position)
	#print("Camera2D enabled: ", enabled)

func _process(delta: float) -> void:
	var velocity = Vector2.ZERO
	
	# WASD camera movement - use direct key detection to avoid cursor conflicts
	if Input.is_key_pressed(KEY_W):
		velocity.y -= 1
		#print("W pressed - moving camera up")
	if Input.is_key_pressed(KEY_S):
		velocity.y += 1
		#print("S pressed - moving camera down")
	if Input.is_key_pressed(KEY_A):
		velocity.x -= 1
		#print("A pressed - moving camera left")
	if Input.is_key_pressed(KEY_D):
		velocity.x += 1
		#print("D pressed - moving camera right")
	
	# Normalize diagonal movement
	if velocity.length() > 0:
		velocity = velocity.normalized() * camera_speed * delta
		global_position += velocity
		#print("Camera position: ", global_position)
	
	# Edge scrolling
	_handle_edge_scrolling(delta)

func _handle_edge_scrolling(delta: float) -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var edge_velocity = Vector2.ZERO
	
	# Get mouse position relative to screen
	var local_mouse = get_viewport().get_mouse_position()
	
	# Debug: Check if mouse is in window
	if local_mouse.x < 0 or local_mouse.x > viewport_size.x or local_mouse.y < 0 or local_mouse.y > viewport_size.y:
		return
	
	# Check screen edges
	if local_mouse.x < edge_scroll_margin:
		edge_velocity.x = -1
	elif local_mouse.x > viewport_size.x - edge_scroll_margin:
		edge_velocity.x = 1
	
	if local_mouse.y < edge_scroll_margin:
		edge_velocity.y = -1
	elif local_mouse.y > viewport_size.y - edge_scroll_margin:
		edge_velocity.y = 1
	
	# Apply edge scrolling movement
	if edge_velocity.length() > 0:
		edge_velocity = edge_velocity.normalized() * edge_scroll_speed * delta
		global_position += edge_velocity
		#print("Edge scrolling: ", edge_velocity, " Camera pos: ", global_position)
