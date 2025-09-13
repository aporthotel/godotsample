# CombatCalculator.gd - Combat Resolution Singleton
# Handles all combat calculations, damage resolution, and attack previews
# Integrates with EventBus for combat events

extends Node

signal combat_preview_calculated(attacker: Unit, defender: Unit, preview: Dictionary)
signal combat_resolved(attacker: Unit, defender: Unit, result: Dictionary)

func calculate_attack_preview(attacker: Unit, defender: Unit) -> Dictionary:
	if not attacker or not defender or not attacker.stats or not defender.stats:
		return {"error": "Invalid units or missing stats"}
	
	var attacker_stats = attacker.stats
	var defender_stats = defender.stats
	
	# Calculate hit chance (accuracy vs evasion)
	var hit_chance = clamp(attacker_stats.accuracy - defender_stats.evasion, 5, 95)
	
	# Calculate damage (attack vs defense)
	var base_damage = attacker_stats.attack_damage
	var defense_reduction = defender_stats.defense
	var final_damage = max(1, base_damage - defense_reduction)  # Minimum 1 damage
	
	# Calculate critical hit
	var crit_chance = attacker_stats.critical_chance
	var crit_damage = int(final_damage * attacker_stats.critical_multiplier)
	
	# Check if defender can counter-attack
	var can_counter = defender_stats.can_counter and defender_stats.is_alive and _is_in_range(defender, attacker)
	
	# Calculate if this attack would be lethal
	var kills = defender_stats.current_hp <= final_damage
	var crit_kills = defender_stats.current_hp <= crit_damage
	
	var preview = {
		"hit_chance": hit_chance,
		"damage": final_damage,
		"crit_chance": crit_chance,
		"crit_damage": crit_damage,
		"can_counter": can_counter,
		"kills": kills,
		"crit_kills": crit_kills,
		"attacker_hp": attacker_stats.current_hp,
		"defender_hp": defender_stats.current_hp,
		"attacker_ap": attacker_stats.current_ap,
		"ap_cost": attacker_stats.attack_cost
	}
	
	# Add counter-attack preview if applicable
	if can_counter:
		preview["counter_preview"] = calculate_counter_preview(defender, attacker)
	
	combat_preview_calculated.emit(attacker, defender, preview)
	return preview

func calculate_counter_preview(defender: Unit, original_attacker: Unit) -> Dictionary:
	if not defender or not original_attacker or not defender.stats or not original_attacker.stats:
		return {}
	
	var defender_stats = defender.stats
	var attacker_stats = original_attacker.stats
	
	var counter_hit_chance = clamp(defender_stats.accuracy - attacker_stats.evasion, 5, 95)
	var counter_damage = max(1, defender_stats.attack_damage - attacker_stats.defense)
	var counter_crit_damage = int(counter_damage * defender_stats.critical_multiplier)
	
	return {
		"hit_chance": counter_hit_chance,
		"damage": counter_damage,
		"crit_chance": defender_stats.critical_chance,
		"crit_damage": counter_crit_damage,
		"kills": attacker_stats.current_hp <= counter_damage,
		"crit_kills": attacker_stats.current_hp <= counter_crit_damage
	}

func execute_attack(attacker: Unit, defender: Unit) -> Dictionary:
	if not attacker or not defender:
		return {"success": false, "error": "Invalid units"}
	
	if not attacker.can_attack():
		return {"success": false, "error": "Attacker cannot attack"}
	
	if not defender.is_alive():
		return {"success": false, "error": "Defender is already dead"}
	
	var preview = calculate_attack_preview(attacker, defender)
	if preview.has("error"):
		return preview
	
	var result = {
		"success": true,
		"hit": false,
		"critical": false,
		"damage_dealt": 0,
		"defender_died": false,
		"counter": null,
		"attacker_died": false
	}
	
	# Emit attack started event
	if EventBus:
		EventBus.attack_started.emit(attacker, defender)
	
	# Roll for hit
	var hit_roll = randf() * 100
	if hit_roll <= preview.hit_chance:
		result.hit = true
		
		# Roll for critical
		var crit_roll = randf() * 100
		if crit_roll <= preview.crit_chance:
			result.critical = true
			result.damage_dealt = preview.crit_damage
		else:
			result.damage_dealt = preview.damage
		
		# Apply damage to defender
		var actual_damage = defender.take_damage(result.damage_dealt)
		result.damage_dealt = actual_damage
		result.defender_died = not defender.is_alive()
		
		# Emit damage event
		if EventBus:
			EventBus.damage_dealt.emit(attacker, defender, actual_damage)
		
		# Handle counter-attack if defender survives and can counter
		if defender.is_alive() and preview.can_counter and defender.stats.can_counter:
			result.counter = _execute_counter_attack(defender, attacker)
			defender.stats.can_counter = false  # Prevent counter chains
			result.attacker_died = not attacker.is_alive()
	
	# Consume attacker's AP
	attacker.consume_ap(attacker.stats.attack_cost)
	attacker.stats.has_attacked = true
	
	# Emit attack completed event
	if EventBus:
		EventBus.attack_completed.emit(attacker, defender, result.damage_dealt)
	
	combat_resolved.emit(attacker, defender, result)
	return result

func _execute_counter_attack(counter_attacker: Unit, original_attacker: Unit) -> Dictionary:
	var counter_result = {
		"hit": false,
		"critical": false,
		"damage_dealt": 0,
		"kills": false
	}
	
	var counter_preview = calculate_counter_preview(counter_attacker, original_attacker)
	if counter_preview.is_empty():
		return counter_result
	
	# Roll for counter hit
	var counter_hit_roll = randf() * 100
	if counter_hit_roll <= counter_preview.hit_chance:
		counter_result.hit = true
		
		# Roll for counter critical
		var counter_crit_roll = randf() * 100
		if counter_crit_roll <= counter_preview.crit_chance:
			counter_result.critical = true
			counter_result.damage_dealt = counter_preview.crit_damage
		else:
			counter_result.damage_dealt = counter_preview.damage
		
		# Apply counter damage
		var actual_damage = original_attacker.take_damage(counter_result.damage_dealt)
		counter_result.damage_dealt = actual_damage
		counter_result.kills = not original_attacker.is_alive()
		
		# Emit counter events
		if EventBus:
			EventBus.damage_dealt.emit(counter_attacker, original_attacker, actual_damage)
	
	return counter_result

func _is_in_range(attacker: Unit, target: Unit) -> bool:
	if not attacker or not target or not attacker.stats:
		return false
	
	var attacker_pos = attacker.get_grid_position()
	var target_pos = target.get_grid_position()
	var distance = attacker_pos.distance_to(target_pos)
	
	return distance <= attacker.stats.attack_range

func can_attack_target(attacker: Unit, target: Unit) -> Dictionary:
	if not attacker or not target:
		return {"can_attack": false, "reason": "Invalid units"}
	
	if not attacker.can_attack():
		return {"can_attack": false, "reason": "Attacker cannot attack (no AP or dead)"}
	
	if not target.is_alive():
		return {"can_attack": false, "reason": "Target is already dead"}
	
	if attacker.get_team_id() == target.get_team_id():
		return {"can_attack": false, "reason": "Cannot attack allies"}
	
	if not _is_in_range(attacker, target):
		return {"can_attack": false, "reason": "Target out of range"}
	
	return {"can_attack": true, "reason": "Attack is valid"}

func get_units_in_attack_range(attacker: Unit, all_units: Array[Unit]) -> Array[Unit]:
	var targets_in_range: Array[Unit] = []
	
	if not attacker or not attacker.stats:
		return targets_in_range
	
	var attacker_pos = attacker.get_grid_position()
	var attack_range = attacker.stats.attack_range
	
	for unit in all_units:
		if unit == attacker:
			continue
		
		if not unit.is_alive():
			continue
		
		if unit.get_team_id() == attacker.get_team_id():
			continue  # Skip allies
		
		var target_pos = unit.get_grid_position()
		var distance = attacker_pos.distance_to(target_pos)
		
		if distance <= attack_range:
			targets_in_range.append(unit)
	
	return targets_in_range

func get_attack_range_cells(attacker: Unit, grid: Grid) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	
	if not attacker or not attacker.stats or not grid:
		return cells
	
	var attacker_pos = attacker.get_grid_position()
	var attack_range = attacker.stats.attack_range
	
	# Generate all cells within attack range
	for x in range(-attack_range, attack_range + 1):
		for y in range(-attack_range, attack_range + 1):
			var cell = attacker_pos + Vector2i(x, y)
			var distance = attacker_pos.distance_to(cell)
			
			if distance <= attack_range and distance > 0:  # Exclude attacker's own cell
				if grid.is_within_bounds(cell):
					cells.append(cell)
	
	return cells