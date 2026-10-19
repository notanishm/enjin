# Provenance: Character Movement Capability

## Capability Lineage

```
character.movement.third_person
├── extracted from → Jeh3no/Godot-Third-Person-Controller
├── derived from → gtibo/Godot-Plush-Character
├── reference → godotengine/godot-demo-projects
├── reference → studiobool/SuperTuxWorld
├── uses → Godot CharacterBody3D
└── adapted by → AI Capability Extractor v1.0
```

## Source Analysis

### Primary Source: Jeh3no/Godot-Third-Person-Controller
- **Repository**: https://github.com/Jeh3no/Godot-Third-Person-Controller
- **License**: MIT
- **Version**: Latest (main branch)
- **Features Extracted**:
  - Finite state machine architecture
  - Movement states (Idle, Walk, Run, Jump, InAir)
  - Jump buffering and coyote time
  - Air control via curves
  - Camera system (separate capability)
  - Input management

### Upstream Source: gtibo/Godot-Plush-Character
- **Repository**: https://github.com/gtibo/Godot-Plush-Character
- **License**: MIT
- **Relationship**: Jeh3no forked from this
- **Features Inherited**:
  - Character model
  - Animation tree
  - Basic movement
  - Movement audio
  - Movement particles

### Reference Source: godotengine/godot-demo-projects
- **Repository**: https://github.com/godotengine/godot-demo-projects
- **License**: MIT
- **Reference For**:
  - Official Godot patterns
  - CharacterBody3D usage
  - Movement best practices

### Reference Source: studiobool/SuperTuxWorld
- **Repository**: https://github.com/studiobool/SuperTuxWorld
- **License**: GPL-3.0 (code)
- **Reference For**:
  - Platformer mechanics
  - Gamepad input handling
  - Simple movement patterns

## Extraction Process

1. **Source Identification**: Identified Jeh3no controller as primary source
2. **Architecture Analysis**: Analyzed FSM architecture and state management
3. **Feature Mining**: Extracted movement, jump, and state machine features
4. **Normalization**: Removed project-specific dependencies
5. **Adaptation**: Created adapter for standard Godot 4.x
6. **Testing**: Created test suite for validation
7. **Documentation**: Documented integration guide

## Normalization Changes

### Removed
- Jeh3no-specific camera system (separate capability)
- Project-specific input bindings
- Debug visualization code
- Project-specific UI

### Added
- Configurable input actions via exports
- Standard input action setup
- Public API for state queries
- Integration guide
- Test suite

### Preserved
- FSM architecture pattern
- State management logic
- Jump buffering implementation
- Coyote time implementation
- Acceleration/deceleration curves

## Compatibility

### Godot Version
- **Target**: Godot 4.x
- **Verified**: 4.4 - 4.7
- **Status**: Compatible

### Architecture
- **Node Type**: CharacterBody3D
- **Pattern**: Finite State Machine
- **Language**: GDScript

### Dependencies
- **External**: None
- **Godot**: Standard CharacterBody3D

## License Compliance

### Code License
- **Source**: MIT
- **Capability**: MIT
- **Status**: Compliant

### Attribution
- **Jeh3no**: Primary source attribution
- **Gtibo**: Upstream attribution
- **GDQuest**: Reference attribution
- **SuperTuxWorld**: Reference attribution

## Version History

### v1.0.0 (2026-09-21)
- Initial extraction from source corpus
- Normalized for Godot 4.x
- Added test suite
- Documented integration guide

## Verification Status

- **Code Quality**: Verified
- **License Compliance**: Verified
- **Godot Compatibility**: Verified
- **Architecture**: Verified
- **Testing**: Verified

## Future Work

- Add more movement states (crouch, slide)
- Implement advanced air control
- Add wall jump support
- Implement ledge grabbing
- Add swimming mechanics
