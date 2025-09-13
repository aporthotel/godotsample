## Unit Info Panel for displaying selected unit information
extends CanvasLayer

@onready var info_label: Label = $InfoPanel/InfoLabel

var selected_unit: Unit = null

func _ready() -> void:
	clear_selection()

## Clears the unit selection display
func clear_selection() -> void:
	# Disconnect from current unit's signals
	if selected_unit:
		if selected_unit.hp_changed.is_connected(_on_unit_hp_changed):
			selected_unit.hp_changed.disconnect(_on_unit_hp_changed)
		if selected_unit.ap_changed.is_connected(_on_unit_ap_changed):
			selected_unit.ap_changed.disconnect(_on_unit_ap_changed)
	
	selected_unit = null
	update_display()

## Sets the selected unit and updates the display
func set_selected_unit(unit: Unit) -> void:
	# Disconnect from previous unit's signals
	if selected_unit:
		if selected_unit.hp_changed.is_connected(_on_unit_hp_changed):
			selected_unit.hp_changed.disconnect(_on_unit_hp_changed)
		if selected_unit.ap_changed.is_connected(_on_unit_ap_changed):
			selected_unit.ap_changed.disconnect(_on_unit_ap_changed)
	
	selected_unit = unit
	
	# Connect to new unit's signals
	if selected_unit:
		selected_unit.hp_changed.connect(_on_unit_hp_changed)
		selected_unit.ap_changed.connect(_on_unit_ap_changed)
	
	update_display()

## Updates the information display
func update_display() -> void:
	if not info_label:
		return
		
	if not selected_unit:
		info_label.text = "Selected Unit:\nNone"
		return
	
	var info_text = "Selected Unit:\n"
	info_text += selected_unit.name + "\n\n"
	
	if selected_unit.stats:
		info_text += "HP: " + str(selected_unit.stats.current_hp) + "/" + str(selected_unit.stats.max_hp) + "\n"
		info_text += "AP: " + str(selected_unit.stats.current_ap) + "/" + str(selected_unit.stats.max_ap) + "\n\n"
		info_text += "Attack: " + str(selected_unit.stats.attack_damage) + "\n"
		info_text += "Defense: " + str(selected_unit.stats.defense) + "\n"
		info_text += "Move Range: " + str(selected_unit.stats.move_range)
	else:
		info_text += "HP: N/A\nAP: N/A"
	
	info_label.text = info_text

## Called when the selected unit's HP changes
func _on_unit_hp_changed(_new_hp: int, _max_hp: int) -> void:
	update_display()

## Called when the selected unit's AP changes
func _on_unit_ap_changed(_new_ap: int, _max_ap: int) -> void:
	update_display()

## Updates HP display for the currently selected unit
func update_hp() -> void:
	if selected_unit:
		update_display()