## OverlayRenderer - Consolidates all overlay drawing logic
## Manages UnitOverlay, AttackOverlay, and UnitPath rendering
class_name OverlayRenderer
extends Node

var _unit_overlay: UnitOverlay
var _attack_overlay: AttackOverlay
var _unit_path: UnitPath

func initialize(unit_overlay: UnitOverlay, attack_overlay: AttackOverlay, unit_path: UnitPath) -> void:
	_unit_overlay = unit_overlay
	_attack_overlay = attack_overlay
	_unit_path = unit_path

## Clear all overlays
func clear_all_overlays() -> void:
	if _unit_overlay:
		_unit_overlay.clear()
	if _unit_path:
		_unit_path.stop()
	if _attack_overlay:
		_attack_overlay.clear()

## Show walkable cells for selected unit
func show_walkable_cells(cells: Array) -> void:
	if _unit_overlay:
		_unit_overlay.draw(cells)
	if _unit_path:
		_unit_path.initialize(cells)

## Clear walkable cells display
func clear_walkable_cells() -> void:
	if _unit_overlay:
		_unit_overlay.clear()
	if _unit_path:
		_unit_path.stop()

## Show attack range cells
func show_attack_range(cells: Array) -> void:
	if _attack_overlay:
		_attack_overlay.draw(cells)

## Clear attack range display
func clear_attack_range() -> void:
	if _attack_overlay:
		_attack_overlay.clear()

## Draw movement path from current cell to target
func draw_movement_path(from_cell: Vector2i, to_cell: Vector2i) -> void:
	if _unit_path:
		_unit_path.draw(from_cell, to_cell)

## Stop showing movement path
func stop_movement_path() -> void:
	if _unit_path:
		_unit_path.stop()