# Core Architecture

## Current Systems:
- **Grid-Based Movement**: Pathfinding with visual overlays and path preview
- **Turn-Based Combat**: Complete damage calculation, hit/miss/crit mechanics
- **Unit Management**: Player/AI/NPC unit types with individual stats and behaviors
- **Camera Controls**: WASD movement and edge scrolling for map navigation
- **Manual Turn Control**: Player-controlled turn ending with persistent action UI
- **Death System**: Comprehensive unit death handling with proper cleanup

## Key Components:

- **GameBoard** (`GameBoard/GameBoard.gd`): Central coordinator managing unit selection, movement, and board state
- **ModeManager** (`GameBoard/ModeManager.gd`): Move/attack mode state management
- **ActionExecutor** (`GameBoard/ActionExecutor.gd`): Action execution logic (IN PROGRESS - has bugs)
- **Unit** (`Units/Unit.gd`): Visual representation with UnitStats resource integration
- **UnitStats** (`Resources/UnitStats.gd`): Complete unit statistics and combat data
- **CombatCalculator** (`CombatCalculator.gd`): Damage calculation and hit mechanics
- **TurnManager** (`scripts/TurnManager.gd`): Turn sequence management and AI behavior
- **EventBus** (`EventBus.gd`): Global signal hub for system communication

## Visual Systems:
- **UnitOverlay**: Green walkable cell highlighting (`UnitOverlay/UnitOverlay.gd`)
- **AttackOverlay**: Red attack range display (`AttackOverlay/AttackOverlay.gd`)
- **UnitPath**: Path preview with autotiling (`GameBoard/UnitPath.gd`)
- **PlayerActionUI**: Persistent action panel with MOVE/ATTACK/END TURN (`CombatUI/InventoryUI.gd`)