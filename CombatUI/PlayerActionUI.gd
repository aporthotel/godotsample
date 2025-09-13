## Player Action UI window for combat actions - ATTACK/MOVE/SKILL/END TURN buttons
class_name PlayerActionUI
extends CanvasLayer

signal action_panel_closed
signal move_mode_changed(is_active: bool)
signal attack_mode_changed(is_active: bool)
signal end_turn_requested

@onready var move_button: TextureButton = $ActionWindow/GridContainer/MoveButton

# Optional UI elements - will be null if nodes don't exist
var attack_button: TextureButton = null
var end_turn_button: TextureButton = null
var hp_label: Label = null
var ap_label: Label = null

var move_button_selected := false
var attack_button_selected := false
var flash_tween: Tween
var attack_flash_tween: Tween
var current_unit: Unit = null

func _ready() -> void:
	# Start hidden
	visible = false
	print("PlayerActionUI ready - visible set to: ", visible)
	
	# Try to get optional UI nodes
	if has_node("ActionWindow/GridContainer/AttackButton"):
		attack_button = get_node("ActionWindow/GridContainer/AttackButton")
		attack_button.pressed.connect(_on_attack_button_pressed)
		print("PlayerActionUI: Attack button found and connected")
	else:
		print("PlayerActionUI: Attack button not found - attack mode will work without button")
	
	if has_node("ActionWindow/GridContainer/EndTurnButton"):
		end_turn_button = get_node("ActionWindow/GridContainer/EndTurnButton")
		print("PlayerActionUI: End turn button found")
	else:
		print("PlayerActionUI: End turn button not found")
	
	if has_node("ActionWindow/GridContainer/HPLabel"):
		hp_label = get_node("ActionWindow/GridContainer/HPLabel")
		print("PlayerActionUI: HP label found")
	else:
		print("PlayerActionUI: HP label not found - will work without HP display")
	
	if has_node("ActionWindow/GridContainer/APLabel"):
		ap_label = get_node("ActionWindow/GridContainer/APLabel")
		print("PlayerActionUI: AP label found") 
	else:
		print("PlayerActionUI: AP label not found - will work without AP display")
	
	# Connect move button signal
	move_button.pressed.connect(_on_move_button_pressed)

func _unhandled_input(event: InputEvent) -> void:
	# In simplified architecture, action panel should never close via ESC during player turns
	# Action panel auto-shows/hides based on turn changes, not user ESC
	# All ESC handling is done by GameBoard for mode cancellation only
	pass

func show_action_panel() -> void:
	visible = true
	print("PlayerActionUI: Action panel shown - visible: ", visible)

func hide_action_panel() -> void:
	visible = false
	print("PlayerActionUI: Action panel hidden - visible: ", visible)

func _on_close_button_pressed() -> void:
	hide_action_panel()
	emit_signal("action_panel_closed")

func _on_move_button_pressed() -> void:
	# Toggle move button selection state
	move_button_selected = !move_button_selected
	print("Move mode ", "activated" if move_button_selected else "deactivated")
	
	if move_button_selected:
		_start_continuous_flash(move_button)
	else:
		_stop_flash(move_button)
	
	# Emit signal to notify GameBoard of move mode change
	emit_signal("move_mode_changed", move_button_selected)

func _start_continuous_flash(button: TextureButton) -> void:
	# Stop any existing flash
	if flash_tween:
		flash_tween.kill()
	
	# Create continuous flash animation
	flash_tween = create_tween()
	flash_tween.set_loops()  # Infinite loops
	flash_tween.tween_property(button, "modulate", Color.WHITE * 1.5, 0.3)
	flash_tween.tween_property(button, "modulate", Color.WHITE, 0.3)

func _stop_flash(button: TextureButton) -> void:
	# Stop flashing and reset to normal color
	if flash_tween:
		flash_tween.kill()
		flash_tween = null
	button.modulate = Color.WHITE

## Cancel move mode without emitting signals (to prevent recursion)
func cancel_move_mode() -> void:
	if move_button_selected:
		move_button_selected = false
		_stop_flash(move_button)
		print("Move mode cancelled (no signal emission)")

func _on_attack_button_pressed() -> void:
	if not attack_button:
		return
	
	# Toggle attack button selection state
	attack_button_selected = !attack_button_selected
	print("Attack mode ", "activated" if attack_button_selected else "deactivated")
	
	if attack_button_selected:
		_start_continuous_flash_attack(attack_button)
	else:
		_stop_flash_attack(attack_button)
	
	# Emit signal to notify GameBoard of attack mode change
	emit_signal("attack_mode_changed", attack_button_selected)

func _start_continuous_flash_attack(button: TextureButton) -> void:
	# Stop any existing flash
	if attack_flash_tween:
		attack_flash_tween.kill()
	
	# Create continuous flash animation (red tint for attack)
	attack_flash_tween = create_tween()
	attack_flash_tween.set_loops()  # Infinite loops
	attack_flash_tween.tween_property(button, "modulate", Color.RED * 1.3, 0.3)
	attack_flash_tween.tween_property(button, "modulate", Color.WHITE, 0.3)

func _stop_flash_attack(button: TextureButton) -> void:
	# Stop flashing and reset to normal color
	if attack_flash_tween:
		attack_flash_tween.kill()
		attack_flash_tween = null
	button.modulate = Color.WHITE

## Cancel attack mode without emitting signals (to prevent recursion)
func cancel_attack_mode() -> void:
	if attack_button_selected:
		attack_button_selected = false
		if attack_button:
			_stop_flash_attack(attack_button)
		print("Attack mode cancelled (no signal emission)")

## Update UI display with unit stats
func update_unit_display(unit: Unit) -> void:
	# Disconnect from previous unit if any
	if current_unit and current_unit.ap_changed.is_connected(_on_unit_ap_changed):
		current_unit.ap_changed.disconnect(_on_unit_ap_changed)
	
	current_unit = unit
	
	if not unit or not unit.stats:
		if hp_label:
			hp_label.text = "HP: --/--"
		if ap_label:
			ap_label.text = "AP: --/--"
		if attack_button:
			attack_button.disabled = true
		move_button.disabled = true
		return
	
	# Connect to new unit's AP changes for real-time updates
	if not unit.ap_changed.is_connected(_on_unit_ap_changed):
		unit.ap_changed.connect(_on_unit_ap_changed)
	
	# Update HP display
	if hp_label:
		hp_label.text = "HP: %d/%d" % [unit.stats.current_hp, unit.stats.max_hp]
	
	# Update AP display  
	if ap_label:
		ap_label.text = "AP: %d/%d" % [unit.stats.current_ap, unit.stats.max_ap]
	
	# Update button states based on AP and capabilities
	if attack_button:
		attack_button.disabled = not unit.can_attack()
		attack_button.modulate = Color.WHITE if not attack_button.disabled else Color.GRAY
	move_button.disabled = not unit.can_move()
	move_button.modulate = Color.WHITE if not move_button.disabled else Color.GRAY
	
	print("PlayerActionUI: Updated display for ", unit.name, " - HP: ", unit.stats.current_hp, "/", unit.stats.max_hp, " AP: ", unit.stats.current_ap, "/", unit.stats.max_ap)

## Clear unit display
func clear_unit_display() -> void:
	current_unit = null
	if hp_label:
		hp_label.text = "HP: --/--"
	if ap_label:
		ap_label.text = "AP: --/--"
	if attack_button:
		attack_button.disabled = true
		attack_button.modulate = Color.GRAY
	move_button.disabled = true
	move_button.modulate = Color.GRAY

## Called when end turn button is pressed
func _on_end_turn_button_pressed() -> void:
	print("PlayerActionUI: End turn button pressed")
	emit_signal("end_turn_requested")

## Called when unit's AP changes - update display in real-time
func _on_unit_ap_changed(new_ap: int, max_ap: int) -> void:
	if ap_label:
		ap_label.text = "AP: %d/%d" % [new_ap, max_ap]
		print("PlayerActionUI: AP updated to ", new_ap, "/", max_ap)
	
	# Update button states based on new AP
	if current_unit:
		if attack_button:
			attack_button.disabled = not current_unit.can_attack()
		move_button.disabled = not current_unit.can_move()
