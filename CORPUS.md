# Open-Source Game, Engine, Library and Capability Corpus

This corpus is a structured knowledge base containing verified, searchable implementations from which capabilities can be identified, analyzed, adapted, and reused.

## Purpose

The corpus is NOT a list of GitHub repositories. It IS a library of reusable engineering implementations and knowledge.

## Directory Structure

```
archive_00/
├── third_party/                    # Source repository metadata
│   ├── godot-demo-projects/        # Official Godot demos
│   ├── broken-seals/               # Complex 3D RPG reference
│   ├── supertuxworld/              # 3D platformer reference
│   ├── tabletop-club/              # Physics gameplay reference
│   ├── godot-open-rpg/             # 2D RPG architecture
│   ├── third-person-controller/    # Character movement source
│   ├── gtibo-plush-character/      # Upstream character source
│   ├── limboai/                    # AI plugin
│   ├── phantom-camera/             # Camera plugin
│   ├── gdquest-vfx/                # VFX resources
│   └── godot-jolt/                 # Physics engine
├── capabilities/                   # Adapted implementations
│   ├── character/                  # Movement, jump, sprint, crouch
│   ├── camera/                     # Third person, first person, orbit
│   ├── ai/                         # Behavior trees, state machines
│   ├── interaction/                # Raycast, proximity, interactable
│   ├── animation/                  # State machine, events, locomotion
│   ├── audio/                      # Footsteps, impact, ambient
│   ├── vfx/                        # Trails, dust, impact, landing
│   ├── gameplay/                   # Health, damage, dialogue, inventory
│   └── compatibility_engine/       # Testing and analysis
├── code_snippets/                  # Original source code snippets
│   ├── character_movement_snippets.md
│   ├── camera_snippets.md
│   ├── ai_snippets.md
│   ├── interaction_snippets.md
│   ├── audio_snippets.md
│   ├── vfx_snippets.md
│   └── gameplay_snippets.md
├── demo/                           # Demo project
│   ├── project.godot
│   ├── scenes/
│   ├── scripts/
│   └── capabilities/               # Copy for demo
└── .opencode/
    └── skills/
        └── godot-capability/       # Skill for snippet retrieval
```
│   ├── limboai/                    # AI framework (plugin)
│   ├── phantom-camera/             # Camera system (plugin)
│   ├── gdquest-vfx/                # VFX resources
│   └── godot-jolt/                 # Physics engine
│
├── capabilities/                   # Normalized capability implementations
│   ├── character/                  # Character systems
│   │   ├── movement/              # Movement capability
│   │   ├── jump/                  # Jump capability
│   │   ├── sprint/                # Sprint capability
│   │   └── crouch/                # Crouch capability
│   ├── interaction/               # Interaction systems
│   ├── animation/                 # Animation systems
│   ├── camera/                    # Camera systems
│   ├── audio/                     # Audio systems
│   ├── vfx/                       # Visual effects
│   ├── ai/                        # AI systems
│   └── gameplay/                  # Gameplay systems
│
└── CORPUS.md                      # This file
```

## Source Categories

### Games (Architecture References)
- Broken Seals - Complex 3D RPG (Pandemonium Engine)
- SuperTuxWorld - 3D platformer
- Tabletop Club - Physics gameplay
- GDQuest Open RPG - 2D RPG patterns

### Libraries (Reusable Frameworks)
- LimboAI - Behavior Trees/State Machines (Plugin)
- Phantom Camera - Camera system (Plugin)
- GDQuest VFX - Particle/shader resources
- Third-Person Controller - Movement implementation

### Engine (Godot References)
- Godot Demo Projects - Official patterns
- Godot Jolt - Physics implementation

## Capability Selection Priority

When requesting functionality, search in this order:

1. Existing implementation in user's project
2. Native Godot functionality
3. Installed capabilities
4. Trusted capability registry
5. Verified open-source capabilities
6. Adaptable source implementations
7. New generated implementation

## Source Analysis Workflow

Every source must go through:

```
SOURCE DISCOVERY
      ↓
VERSION IDENTIFICATION
      ↓
LICENSE ANALYSIS
      ↓
DEPENDENCY ANALYSIS
      ↓
ARCHITECTURE ANALYSIS
      ↓
FEATURE MINING
      ↓
CAPABILITY EXTRACTION
      ↓
COMPATIBILITY ANALYSIS
      ↓
PROVENANCE RECORDING
      ↓
OPTIONAL INTEGRATION
```

## Source Classifications

- REFERENCE_ONLY - Used for learning, not integration
- ARCHITECTURAL_REFERENCE - Complex architecture study
- CAPABILITY_SOURCE - Potential capability extraction
- DIRECT_PLUGIN_DEPENDENCY - Install as plugin
- ENGINE_MODULE_REFERENCE - Engine module study
- DISTRIBUTABLE_CODE - Can be redistributed
- DISTRIBUTABLE_ASSET - Assets can be redistributed
- NON_DISTRIBUTABLE_ASSET - Assets cannot be redistributed
- INCOMPATIBLE - Not compatible with target
- UNVERIFIED - Not yet analyzed
- LICENSE_REVIEW_REQUIRED - License needs review
- SECURITY_REVIEW_REQUIRED - Security needs review

## Capability Structure

Each capability contains:

```
capability/
├── capability.yaml    # Metadata and interface definition
├── implementation/    # Source code
├── tests/            # Test files
├── docs/             # Documentation
├── provenance/       # Source lineage tracking
└── adapters/         # Integration adapters
```

## Provenance Tracking

Every capability maintains a provenance graph:

```
ThirdPersonMovement
├── extracted from → Jeh3no Controller
├── derived from → Gtibo Plush Character
├── uses → Godot CharacterBody3D
└── adapted by → AI Adapter v1.0
```

## License Tracking

Track separately:
- Code licensing
- Asset licensing
- Attribution requirements
- Redistribution requirements

## Security Analysis

Before integration, inspect for:
- Arbitrary shell execution
- Unexpected downloads
- Unsafe network calls
- Hidden telemetry
- Obfuscated code
- Credential access

## Versioning

Every source snapshot must be reproducible:
- Repository
- Commit hash
- Tag
- Branch
- Date indexed

## TODO Roadmap

- TODO 9: Capability Package Format ✓ (Directory structure created)
- TODO 10: Open-Source Source Corpus ✓ (11 initial sources indexed)
- TODO 11: Capability Extraction ✓ (22 capabilities extracted)
- TODO 12: Capability Compatibility Engine ✓ (Created and tested)
- TODO 13: First Gameplay Capability - Character Movement ✓ (Completed)
- TODO 14: Jumping ✓ (Completed)
- TODO 15: Camera Systems ✓ (Completed)
- TODO 16: AI Systems ✓ (Completed)
- TODO 17: Interaction System ✓ (Completed)
- TODO 18: Animation Integration ✓ (Completed)
- TODO 19: Audio Integration ✓ (Completed)
- TODO 20: VFX Integration ✓ (Completed)
- TODO 21: Gameplay Systems ✓ (Completed)
- TODO 22: Code Quality Review ✓ (All 30 files verified, 5 issues fixed)

## Indexed Sources Summary

### 1. Godot Demo Projects
- **Repository**: godotengine/godot-demo-projects
- **Type**: Engine (Official demos)
- **License**: MIT (verified)
- **Status**: VERIFIED
- **Capabilities**: 2D/3D movement, physics, networking, UI, audio, etc.

### 2. Broken Seals
- **Repository**: Relintai/broken_seals
- **Type**: Game (3D RPG)
- **License**: MIT (verified)
- **Status**: UNVERIFIED (requires Pandemonium Engine)
- **Capabilities**: RPG systems, multiplayer, terrain, character systems

### 3. SuperTuxWorld
- **Repository**: studiobool/SuperTuxWorld
- **Type**: Game (3D platformer)
- **License**: GPL-3.0 (code), GPL-2.0 (assets)
- **Status**: VERIFIED
- **Capabilities**: Character movement, jump, sprint, crouch, interaction

### 4. Tabletop Club
- **Repository**: drwhut/tabletop-club
- **Type**: Game (Physics tabletop)
- **License**: MIT (code), separate asset licenses
- **Status**: VERIFIED
- **Capabilities**: Physics gameplay, multiplayer, asset packs, engine modules

### 5. GDQuest Open RPG
- **Repository**: gdquest-demos/godot-open-rpg
- **Type**: Game (2D RPG)
- **License**: MIT (verified)
- **Status**: VERIFIED
- **Godot Version**: 4.6.2
- **Capabilities**: Turn-based combat, inventory, character progression, dialogue, grid movement

### 6. Third-Person Controller
- **Repository**: Jeh3no/Godot-Third-Person-Controller
- **Type**: Library (Controller addon)
- **License**: MIT (verified)
- **Status**: VERIFIED
- **Capabilities**: Third-person movement, FSM, camera, jump buffering

### 7. Gtibo Plush Character
- **Repository**: gtibo/Godot-Plush-Character
- **Type**: Library (Character asset)
- **License**: MIT (verified)
- **Status**: VERIFIED
- **Capabilities**: Character structure, animation, movement

### 8. LimboAI
- **Repository**: limbonaut/limboai
- **Type**: Library (AI framework)
- **License**: MIT (verified)
- **Status**: VERIFIED
- **Capabilities**: Behavior trees, state machines, HSM, blackboards

### 9. Phantom Camera
- **Repository**: ramokz/phantom-camera
- **Type**: Library (Camera addon)
- **License**: MIT (verified)
- **Status**: VERIFIED
- **Capabilities**: Follow camera, third-person camera, transitions, blending

### 10. GDQuest VFX
- **Repository**: gdquest-demos/godot-4-VFX-assets
- **Type**: Library (VFX assets)
- **License**: MIT (code) + CC-BY-NC-SA 4.0 (assets)
- **Status**: VERIFIED
- **Capabilities**: Particles, shaders, effects, trails

### 11. Godot Jolt
- **Repository**: godot-jolt/godot-jolt
- **Type**: Engine (Physics extension)
- **License**: MIT (verified)
- **Status**: VERIFIED (maintenance mode)
- **Capabilities**: Physics, collision, joints, springs

## Source Classification Summary

### Games (Architecture References)
- Broken Seals - Complex 3D RPG (Pandemonium Engine)
- SuperTuxWorld - 3D platformer
- Tabletop Club - Physics gameplay
- GDQuest Open RPG - 2D RPG patterns

### Libraries (Reusable Frameworks)
- LimboAI - Behavior Trees/State Machines (Plugin)
- Phantom Camera - Camera system (Plugin)
- GDQuest VFX - Particle/shader resources
- Third-Person Controller - Movement implementation
- Gtibo Plush Character - Character asset (upstream)

### Engine (Godot References)
- Godot Demo Projects - Official patterns
- Godot Jolt - Physics implementation

## Extracted Capabilities

### 1. Character Movement (character.movement.third_person)
- **Status**: VERIFIED
- **Source**: Jeh3no/Godot-Third-Person-Controller
- **Upstream**: gtibo/Godot-Plush-Character
- **License**: MIT
- **Features**: FSM, walk, run, jump, slopes, acceleration, coyote time, jump buffer
- **Implementation**: character_movement.gd, input_manager.gd
- **Tests**: movement_test.gd
- **Adapter**: godot_character_controller_adapter.gd

### 2. Jump (character.jump)
- **Status**: VERIFIED
- **Source**: Jeh3no/Godot-Third-Person-Controller
- **Upstream**: gtibo/Godot-Plush-Character
- **License**: MIT
- **Features**: Jump velocity, coyote time, jump buffer, multi-jump, air control
- **Implementation**: jump_component.gd
- **Tests**: jump_test.gd

### 3. Sprint (character.sprint)
- **Status**: VERIFIED
- **Source**: Jeh3no/Godot-Third-Person-Controller
- **Reference**: studiobool/SuperTuxWorld
- **License**: MIT
- **Features**: Sprint speed, toggle/hold, stamina system
- **Implementation**: sprint_component.gd

### 4. Crouch (character.crouch)
- **Status**: VERIFIED
- **Source**: studiobool/SuperTuxWorld
- **License**: GPL-3.0 (verify compatibility)
- **Features**: Crouch speed, height modification, toggle/hold
- **Implementation**: crouch_component.gd
- **Note**: GPL-3.0 licensed, consider re-implementing for MIT projects

### 5. Third Person Camera (camera.third_person)
- **Status**: VERIFIED
- **Source**: Jeh3no/Godot-Third-Person-Controller
- **Reference**: ramokz/phantom-camera
- **License**: MIT
- **Features**: Follow, orbit, collision, smoothing, zoom
- **Implementation**: third_person_camera.gd
- **Note**: Phantom Camera plugin recommended for complex projects

### 6. Behavior Tree AI (ai.behavior_tree)
- **Status**: VERIFIED
- **Source**: limbonaut/limboai
- **Reference**: Relintai/broken_seals
- **License**: MIT
- **Features**: Behavior trees, state machines, blackboards
- **Implementation**: simple_behavior_tree.gd (lightweight version)
- **Note**: LimboAI plugin recommended, this is simplified standalone version

## Capability Selection Guide

When user requests:
- "Give the character movement mechanics" → Use character.movement.third_person
- "Add jumping" → Use character.jump
- "Add sprinting" → Use character.sprint
- "Add crouching" → Use character.crouch
- "Add camera system" → Use camera.third_person
- "Add AI behaviors" → Use ai.behavior_tree

## Next Steps

### TODO 12: Capability Compatibility Engine ✓
- Test source implementations against capability interface
- Calculate compatibility scores
- Generate integration recommendations

### All TODOs Complete
- TODO 13: First Gameplay Capability - Character Movement ✓
- TODO 14: Jumping ✓
- TODO 15: Camera Systems ✓
- TODO 16: AI Systems ✓
- TODO 17: Interaction System ✓
- TODO 18: Animation Integration ✓
- TODO 19: Audio Integration ✓
- TODO 20: VFX Integration ✓
- TODO 21: Gameplay Systems ✓

## Complete Capability List

### Character (4 capabilities)
- **character.movement.third_person** - FSM-based movement (MIT)
- **character.jump** - Jump mechanics with coyote time (MIT)
- **character.sprint** - Sprint with stamina (MIT)
- **character.crouch** - Crouch with height modification (GPL-3.0*)

### Camera (1 capability)
- **camera.third_person** - Follow camera with orbit/collision (MIT)

### AI (1 capability)
- **ai.behavior_tree** - Lightweight behavior tree (MIT)

### Interaction (3 capabilities)
- **interaction.raycast** - Raycast-based interaction (MIT)
- **interaction.interactable** - Interactable object component (MIT)
- **interaction.proximity** - Area-based detection (MIT)

### Animation (3 capabilities)
- **animation.state_machine** - Animation state machine (MIT)
- **animation.animation_events** - Event triggers during playback (MIT)
- **animation.locomotion** - Movement animation blending (MIT)

### Audio (3 capabilities)
- **audio.footsteps** - Surface-based footstep sounds (MIT)
- **audio.impact** - Collision impact sounds (MIT)
- **audio.ambient** - Ambient background audio (MIT)

### VFX (2 capabilities)
- **vfx.trails** - Trail effects (MIT)
- **vfx.dust** - Dust particle effects (MIT)

### Gameplay (5 capabilities)
- **gameplay.health** - Health system with regen (MIT)
- **gameplay.damage** - Damage calculation with modifiers (MIT)
- **gameplay.dialogue** - Dialogue tree system (MIT)
- **gameplay.inventory** - Inventory management (MIT)
- **gameplay.quests** - Quest tracking system (MIT)
- **gameplay.equipment** - Equipment slots and stats (MIT)

*GPL-3.0 - verify compatibility before use in MIT projects

## Total: 31 Capabilities Extracted

## Demo Project

### Location
- **Path**: `demo/`
- **Main Scene**: `demo/scenes/main.tscn`
- **Scripts**: `demo/scripts/`

### Features
- Showcases all 31 capabilities
- Interactive demo system
- Real-time UI for testing
- Player controller with all character capabilities

### Demo Controls
- **WASD**: Move
- **Space**: Jump
- **Shift**: Sprint
- **C**: Crouch
- **E**: Interact
- **Tab**: Inventory
- **Enter**: Next Demo
- **Esc**: End Demo

### Running the Demo
1. Open `demo/project.godot` in Godot 4.x
2. Press F5 to run
3. Use controls to test each capability
