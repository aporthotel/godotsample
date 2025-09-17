Project Overview
Tactical RPG system inspired by Divinity: Original Sin (elemental grid interactions), Rift Wizard 2 (spell synergies), Into the Breach (deterministic chains), and The Last Spell (massive scale). Built with Godot 4.4.1 using modern features (TileMapLayer, @export, @onready, await).
Current Architecture Status
✅ Completed Refactoring

ModeManager.gd (109 lines) - Move/attack mode state management
ActionExecutor.gd (195 lines) - Action execution logic

🚧 Current State
GameBoard.gd (~300 lines) is doing too much - mixing orchestration, game logic, and presentation. It needs to become a thin orchestrator (~100 lines).
Target Architecture
File Structure
res://
├── Autoload/                    # Global singletons
│   ├── EventBus.gd             ✓ Exists
│   ├── AudioManager.gd         ❌ Needed
│   ├── SaveManager.gd          ❌ Needed
│   └── SceneManager.gd         ❌ Needed
│
├── Systems/                     # Shared game logic
│   ├── CombatCalculator.gd     ✓ Exists (move here)
│   └── [Future systems]
│
├── TacticalBattle/             # Current game mode
│   ├── TacticalBattle.tscn    # Rename from Main.tscn
│   ├── GameBoard.gd           # Thin orchestrator only
│   ├── Managers/               # Scene-specific managers
│   │   ├── GridStateManager.gd     ❌ Extract from GameBoard
│   │   ├── SelectionManager.gd     ❌ Extract from GameBoard
│   │   ├── ModeManager.gd          ✓ Done
│   │   ├── TurnManager.gd          ✓ Exists
│   │   └── ActionExecutor.gd       ✓ Done
│   ├── Executors/              # Specialized action handlers
│   │   ├── MovementExecutor.gd     ❌ Split from ActionExecutor
│   │   ├── CombatExecutor.gd       ❌ Split from ActionExecutor
│   │   └── SkillExecutor.gd        ❌ Future
│   └── Visual/                 # Rendering managers
│       └── OverlayRenderer.gd      ❌ Extract overlay logic
Scene Tree Structure
Main (Node2D)
└── TacticalBattle (PackedScene)
    ├── GameBoard (Node2D) [100 lines max - orchestration only]
    ├── Managers (Node2D)
    │   ├── GridStateManager [owns _units dictionary]
    │   ├── SelectionManager [owns _active_unit]
    │   ├── TurnManager [already separate]
    │   ├── ModeManager [already separate]
    │   └── ActionExecutor [already separate]
    ├── Visuals (Node2D)
    │   ├── Map (TileMapLayer)
    │   ├── UnitOverlay (TileMapLayer)
    │   ├── AttackOverlay (TileMapLayer)
    │   └── UnitPath (TileMapLayer)
    └── Units (Node2D)
        └── [Unit instances]
Refactoring Priority
Phase 1: Extract State Management (NEXT)

Create GridStateManager.gd

Move _units dictionary from GameBoard
Handle cell occupancy checks
Manage unit position updates


Create SelectionManager.gd

Move _active_unit from GameBoard
Handle selection/deselection logic
Manage selection visual states



Phase 2: Split ActionExecutor

MovementExecutor.gd - Just movement and pathfinding
CombatExecutor.gd - Just combat resolution
SkillExecutor.gd - Future spell system

Phase 3: Visual Systems

OverlayRenderer.gd - Consolidate all overlay drawing
EffectRenderer.gd - Particle effects and animations

Key Architectural Rules
Communication Pattern
User Input → Manager → EventBus → Other Managers → Visual Update

Managers NEVER reference each other directly
All communication through EventBus signals
GameBoard.gd only calls public manager methods

Data Ownership

GridStateManager: Owns _units dictionary
SelectionManager: Owns _active_unit, _walkable_cells
TurnManager: Owns turn order, round count
ModeManager: Owns mode states
ActionExecutor: Stateless, operates on passed data

GameBoard.gd Target Structure
gdscript# ~100 lines - ONLY orchestration
extends Node2D

@onready var grid_state: GridStateManager = $Managers/GridStateManager
@onready var selection: SelectionManager = $Managers/SelectionManager
@onready var turn_manager: TurnManager = $Managers/TurnManager
@onready var mode_manager: ModeManager = $Managers/ModeManager
@onready var action_executor: ActionExecutor = $Managers/ActionExecutor

func _ready():
    # Wire manager connections
    _connect_managers()
    # Start battle
    _initialize_battle()

func _connect_managers():
    # Only signal connections, no logic

func _initialize_battle():
    # Only initialization calls to managers
Critical Success Metrics

GameBoard.gd: Under 100 lines
No manager: Over 200 lines
Every class: Single responsibility
All communication: Through EventBus
Zero: Direct manager-to-manager references

Audio Integration (Priority)
Audio is 50% of game feel. Add AudioManager.gd to Autoload immediately:

Combat sounds tied to EventBus.damage_dealt
Movement sounds tied to EventBus.unit_moved
Elemental reactions need unique audio
UI feedback for every player action

Future Expansion Preparation
Current refactoring must support:

Elemental Grid System (Divinity-style)
Spell Synergy Engine (Rift Wizard-style)
Deterministic Effect Chains (Into the Breach-style)
100+ unit battles (The Last Spell-style)

Keep these in mind when structuring managers - they need to scale.Retry

Extra note 1 AUDIO

Audio is 50% of Game Feel

gdscriptAudioManager (Singleton/Autoload)
├── Music System
│   ├── CrossfadeController - Smooth transitions
│   ├── DynamicMusicSystem - Combat/exploration layers
│   └── BeatSynchronizer - For rhythm-based mechanics
│
├── SFX System
│   ├── PooledSounds - Reusable audio streams
│   ├── PriorityMixer - Voice limiting
│   ├── SpatialController - 3D positioning
│   └── VariationPlayer - Randomized sounds
│
├── Feedback Systems
│   ├── HapticBridge - Controller rumble
│   ├── AudioVisualSync - Perfect timing
│   └── AdaptiveAudio - Reacts to game state
│
└── Accessibility
    ├── SubtitleManager - Audio cues as text
    ├── VolumeProfiles - User preferences
    └── AudioDescription - For visually impaired


Audio Integration Example
For your tactical game specifically:
gdscript# When unit moves
EventBus.unit_moved.connect(func(unit, from, to):
    AudioManager.play_3d("footstep", to, {
        "surface": GridManager.get_terrain(to),
        "unit_weight": unit.weight_class
    })
)

# Divinity-style elemental combos
EventBus.elemental_reaction.connect(func(type, position):
    match type:
        "steam": AudioManager.play_3d("hiss_steam", position)
        "explosion": 
            AudioManager.play_3d("boom", position)
            AudioManager.shake_listener(0.5, 1.0)  # Camera shake
)
The Missing Piece: Juice Systems
Beyond audio, for true game feel:
gdscriptJuiceManager (Game Feel)
├── ScreenEffects (screenshake, chromatic aberration)
├── TimeEffects (hitstop, slow-mo)
├── CameraEffects (zoom, focus pull)
├── UIEffects (number pop-ups, screen flash)
└── AudioEffects (reverb zones, ducking)
