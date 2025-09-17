# Core Architecture

## Current Systems:
- **Grid-Based Movement**: Pathfinding with visual overlays and path preview
- **Turn-Based Combat**: Complete damage calculation, hit/miss/crit mechanics
- **Unit Management**: Player/AI/NPC unit types with individual stats and behaviors
- **Camera Controls**: WASD movement and edge scrolling for map navigation
- **Manual Turn Control**: Player-controlled turn ending with persistent action UI
- **Death System**: Comprehensive unit death handling with proper cleanup

## Key Components:

### Core Managers
- **GameBoard** (`GameBoard/GameBoard.gd`): Central orchestrator (497 lines - being reduced to ~100)
- **SelectionManager** (`TacticalBattle/Managers/SelectionManager.gd`): Unit selection and walkable cell management (~85 lines)
- **ModeManager** (`TacticalBattle/Managers/ModeManager.gd`): Move/attack mode state management (109 lines)
- **GridStateManager** (`TacticalBattle/Managers/GridStateManager.gd`): Grid state and unit placement (119 lines)
- **TurnManager** (`TacticalBattle/Managers/TurnManager.gd`): Turn sequence management and AI behavior

### Specialized Executors (New Architecture)
- **BaseExecutor** (`TacticalBattle/Executors/BaseExecutor.gd`): Shared executor infrastructure (84 lines)
- **MovementExecutor** (`TacticalBattle/Executors/MovementExecutor.gd`): Pathfinding and movement execution (89 lines)
- **CombatExecutor** (`TacticalBattle/Executors/CombatExecutor.gd`): Attack range, targeting, damage calculation (119 lines)

### Core Systems
- **Unit** (`Units/Unit.gd`): Visual representation with UnitStats resource integration
- **UnitStats** (`Resources/UnitStats.gd`): Complete unit statistics and combat data
- **CombatCalculator** (`Systems/CombatCalculator.gd`): Damage calculation and hit mechanics
- **EventBus** (`Autoload/EventBus.gd`): Global signal hub for system communication

### Visual Systems
- **OverlayRenderer** (`TacticalBattle/Visual/OverlayRenderer.gd`): Consolidated overlay rendering

## Architecture Notes:

### Coordinate System Technical Debt
- **Mixed Types**: Grid logic uses Vector2/Vector2i inconsistently due to Grid.gd half-cell calculations
- **Root Cause**: `Grid.calculate_map_position()` adds `_half_cell_size` for visual centering
- **Current Solution**: Type conversions in SelectionManager (`Vector2i(cell)` ↔ `Vector2(cell)`)
- **Tested Stability**: Works with odd cell sizes (33x33) - Godot auto-rounds, only visual offset issues
- **Impact**: No logic errors in production, stable for tactical gameplay
- **Future**: Could be resolved by separating logical grid coordinates from visual positioning

### Visual Components:
- **UnitOverlay**: Green walkable cell highlighting (`UnitOverlay/UnitOverlay.gd`)
- **AttackOverlay**: Red attack range display (`AttackOverlay/AttackOverlay.gd`)
- **UnitPath**: Path preview with autotiling (`GameBoard/UnitPath.gd`)
- **PlayerActionUI**: Persistent action panel with MOVE/ATTACK/END TURN (`CombatUI/InventoryUI.gd`)

## Executor Architecture (New)

### Base Class Pattern
The ActionExecutor has been split into a scalable architecture using inheritance:

```gdscript
BaseExecutor (84 lines)
├── Shared signals: action_completed, unit_died
├── Common infrastructure: grid references, AP validation, unit cleanup
└── Standardized methods for all executor types

MovementExecutor extends BaseExecutor (89 lines)
├── Pathfinding: get_walkable_cells(), _flood_fill()
├── Movement execution with animation support
└── Integration with UnitPath and visual overlays

CombatExecutor extends BaseExecutor (119 lines)
├── Attack range calculation and visualization
├── Target selection and validation
├── Combat execution with CombatCalculator integration
└── Death handling and cleanup
```

### Scalability for Future Features
This architecture is designed to support:
- **SkillExecutor**: Spell casting, AoE effects, elemental interactions
- **ItemExecutor**: Consumables, equipment usage, inventory management
- **SpellExecutor**: Complex spell synergies, elemental combinations
- **StatusExecutor**: Buffs, debuffs, persistent effects

### Benefits Achieved
- **Single Responsibility**: Each executor handles exactly one concern
- **Code Reuse**: BaseExecutor provides common functionality to all executors
- **Maintainability**: 89-line MovementExecutor + 119-line CombatExecutor vs 233-line monolith
- **Extensibility**: New action types can be added without modifying existing code