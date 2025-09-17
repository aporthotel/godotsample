# Satellite Project Template

This template provides the standard structure for creating satellite projects that can be cleanly merged back into the main tactical RPG system.

## Project Structure

```
satellite_project/
├── project.godot                 # Minimal Godot project
├── Main.tscn                     # Test scene
├── TestEnvironment/              # Testing infrastructure
│   ├── TestGrid.tscn            # Basic grid for testing
│   ├── TestUnit.tscn            # Simple unit for testing  
│   └── TestUI.tscn              # Basic UI for testing
├── [SystemName]Manager.gd        # Main system manager
├── Resources/                    # Resource definitions (if new ones needed)
│   ├── [System]Data.gd
│   └── [System]Config.gd
├── UI/                          # System-specific UI
│   └── [System]UI.tscn/.gd
├── Tests/                       # Automated tests
│   └── [System]Test.gd
└── Documentation/               # System documentation
    ├── API.md                   # Interface documentation
    ├── INTEGRATION.md           # How to merge back
    └── TESTING.md               # How to test the system
```

## Required Components

### 1. EventBus Integration
```gdscript
# Copy from main project
# EventBus.gd should be identical to main project
```

### 2. Shared Resources  
```gdscript
# Copy these from main project:
# - Resources/UnitData.gd
# - Resources/ItemData.gd  
# - Resources/GameConfig.gd
# - Interfaces/IUnit.gd
# - Managers/SystemManager.gd
```

### 3. System Manager Implementation
```gdscript
class_name [System]Manager extends SystemManager

func _ready():
    system_name = "[System]Manager"
    super._ready()

func _connect_signals():
    super._connect_signals()
    # Connect to system-specific EventBus signals

func _setup_system():
    # System-specific initialization
```

### 4. Test Environment
Create a minimal test scene with:
- Grid (copy Grid.tres from main)
- Test units with basic IUnit implementation  
- UI for testing system functionality
- Clear visual feedback for system state

## Integration Checklist

When ready to merge back to main project:

- [ ] All EventBus signals used are defined in main EventBus.gd
- [ ] No new Resources created (or new ones documented)
- [ ] System Manager follows SystemManager pattern
- [ ] All dependencies are either in main project or documented
- [ ] UI components follow main project conventions
- [ ] No hardcoded references to specific file paths
- [ ] System can be disabled without breaking main project
- [ ] Documentation updated for new system

## Naming Conventions

### Files:
- **Managers**: `[System]Manager.gd`
- **Resources**: `[System]Data.gd`, `[System]Config.gd`
- **UI**: `[System]UI.tscn/.gd`
- **Tests**: `[System]Test.gd`

### Signals:
- **Pattern**: `action_subject` (e.g., `item_equipped`, `unit_died`)
- **Methods**: `_on_signal_name()` for handlers

### Classes:
- **Managers**: `[System]Manager` extends `SystemManager`
- **Resources**: `[System]Data` extends `Resource`
- **UI**: `[System]UI` extends appropriate UI node

## Example Systems

### Combat System Satellite
Focus: Damage calculation, attack resolution, combat effects
Dependencies: UnitData, EventBus, IUnit interface

### Inventory System Satellite  
Focus: Item management, equipment, item usage
Dependencies: ItemData, UnitData, EventBus, IUnit interface

### AI System Satellite
Focus: Decision making, behavior trees, AI actions
Dependencies: UnitData, EventBus, IUnit interface, Grid

### Save/Load System Satellite
Focus: Game state serialization, save file management
Dependencies: All data resources, EventBus

## Testing Strategy

Each satellite should include:
1. **Unit Tests**: Automated testing of core functionality
2. **Integration Tests**: Testing with mock main project components  
3. **Manual Testing**: Interactive test scene for visual validation
4. **Performance Tests**: Ensure system doesn't impact main project performance

## Communication Protocol

Systems communicate ONLY through EventBus - no direct references between systems.

### Signal Flow Example:
```
User Action → UI → EventBus Signal → System Manager → Logic → EventBus Signal → Other Systems
```

This ensures clean separation and easy integration/removal of systems.