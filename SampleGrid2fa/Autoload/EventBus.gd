# EventBus.gd - Central Event Hub (Autoload)
# Global signal hub that all systems communicate through to avoid direct dependencies

extends Node

# Combat System Signals
signal damage_dealt(attacker: Unit, target: Unit, amount: int)
signal unit_died(unit: Unit)
signal health_changed(unit: Unit, new_health: int, max_health: int)
signal attack_started(attacker: Unit, target: Unit)
signal attack_completed(attacker: Unit, target: Unit, damage: int)

# Turn Management Signals (Enhanced)
signal turn_started(unit: Unit)
signal turn_ended(unit: Unit)
signal round_completed(round_number: int)
signal turn_order_changed(new_order: Array[Unit])

# Unit Management Signals
signal unit_selected(unit: Unit)
signal unit_deselected(unit: Unit)
signal unit_moved(unit: Unit, from_pos: Vector2i, to_pos: Vector2i)
signal unit_spawned(unit: Unit, position: Vector2i)
signal unit_despawned(unit: Unit)

# Inventory System Signals
signal item_equipped(item: Resource, unit: Unit, slot_type: String)
signal item_unequipped(item: Resource, unit: Unit, slot_type: String)
signal item_used(item: Resource, unit: Unit)
signal inventory_changed(unit: Unit)
signal item_picked_up(item: Resource, unit: Unit)
signal item_dropped(item: Resource, position: Vector2i)

# Save/Load System Signals
signal save_requested(slot: int)
signal load_requested(slot: int)
signal game_state_changed()
signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)

# AI System Signals  
signal ai_decision_needed(unit: Unit)
signal ai_action_completed(unit: Unit, action_type: String)
signal ai_behavior_changed(unit: Unit, new_behavior: String)

# UI System Signals
signal ui_panel_opened(panel_name: String)
signal ui_panel_closed(panel_name: String)
signal move_mode_changed(is_active: bool)
signal action_panel_closed()

# Game State Signals
signal game_paused()
signal game_resumed()
signal victory_condition_met(team: String)
signal defeat_condition_met(team: String)

# Configuration Signals
signal setting_changed(setting_name: String, new_value)
signal debug_mode_toggled(enabled: bool)

func _ready():
	print("EventBus: Initialized - All systems can now communicate through signals")

# Utility functions for common signal patterns
func emit_unit_action(unit: Unit, action: String, data: Dictionary = {}):
	print("EventBus: Unit action - ", unit.name, " performed ", action)
	
func emit_system_event(system: String, event: String, data: Dictionary = {}):
	print("EventBus: System event - ", system, " fired ", event)
