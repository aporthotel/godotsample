## ModeManager - Handles move/attack mode states and transitions
## Extracted from GameBoard.gd to reduce complexity and improve maintainability
class_name ModeManager
extends Node

signal move_mode_cancelled()
signal attack_mode_cancelled()

var _move_mode_active := false
var _attack_mode_active := false

## Gets the current active mode
func get_active_mode() -> String:
	if _move_mode_active:
		return "move"
	elif _attack_mode_active:
		return "attack"
	else:
		return "none"

## Checks if move mode is active
func is_move_mode_active() -> bool:
	return _move_mode_active

## Checks if attack mode is active
func is_attack_mode_active() -> bool:
	return _attack_mode_active

## Checks if any mode is active
func is_any_mode_active() -> bool:
	return _move_mode_active or _attack_mode_active

## Activates move mode (deactivates attack mode if needed)
func activate_move_mode() -> void:
	if _attack_mode_active:
		_attack_mode_active = false
		emit_signal("attack_mode_cancelled")
	
	if not _move_mode_active:
		_move_mode_active = true
		print("ModeManager: Move mode activated")

## Activates attack mode (deactivates move mode if needed)
func activate_attack_mode() -> void:
	if _move_mode_active:
		_move_mode_active = false
		emit_signal("move_mode_cancelled")
	
	if not _attack_mode_active:
		_attack_mode_active = true
		print("ModeManager: Attack mode activated")

## Cancels move mode
func cancel_move_mode() -> void:
	if _move_mode_active:
		_move_mode_active = false
		emit_signal("move_mode_cancelled")
		print("ModeManager: Move mode cancelled")

## Cancels attack mode
func cancel_attack_mode() -> void:
	if _attack_mode_active:
		_attack_mode_active = false
		emit_signal("attack_mode_cancelled")
		print("ModeManager: Attack mode cancelled")

## Cancels all active modes
func cancel_all_modes() -> void:
	var had_active_mode = false
	
	if _move_mode_active:
		_move_mode_active = false
		emit_signal("move_mode_cancelled")
		had_active_mode = true
	
	if _attack_mode_active:
		_attack_mode_active = false
		emit_signal("attack_mode_cancelled")
		had_active_mode = true
	
	if had_active_mode:
		print("ModeManager: All modes cancelled")

## Called when move mode is toggled from UI
func _on_move_mode_changed(is_active: bool) -> void:
	if is_active:
		activate_move_mode()
	else:
		cancel_move_mode()

## Called when attack mode is toggled from UI
func _on_attack_mode_changed(is_active: bool) -> void:
	if is_active:
		activate_attack_mode()
	else:
		cancel_attack_mode()

## Handles ESC key cancellation logic
func handle_esc_input() -> bool:
	if _attack_mode_active:
		print("ModeManager: ESC pressed: Canceling attack mode")
		cancel_attack_mode()
		return true
	elif _move_mode_active:
		print("ModeManager: ESC pressed: Canceling move mode")
		cancel_move_mode()
		return true
	else:
		print("ModeManager: ESC pressed: No active mode to cancel")
		return false