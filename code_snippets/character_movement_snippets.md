# Character Movement Snippets

## Source: Jeh3no/Godot-Third-Person-Controller (MIT)
## Adapted for capability reuse

---

## 1. FSM-Based Movement Controller

```gdscript
## Source: Jeh3no/Godot-Third-Person-Controller
## Original: addons/JehenoThirdPersonController/Scripts/
## Adapted: Simplified for standalone use

extends CharacterBody3D

enum State { IDLE, WALK, RUN, JUMP, IN_AIR }

var current_state: State = State.IDLE
var input_direction: Vector3 = Vector3.ZERO

@export var walk_speed: float = 5.0
@export var run_speed: float = 10.0
@export var acceleration: float = 20.0
@export var deceleration: float = 30.0

func _physics_process(delta: float) -> void:
	_get_input()
	_update_state(delta)
	_apply_movement(delta)
	move_and_slide()

func _get_input() -> void:
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	input_direction = (transform.basis * Vector3(input.x, 0, input.y)).normalized()

func _update_state(delta: float) -> void:
	match current_state:
		State.IDLE:
			if input_direction.length() > 0:
				current_state = State.WALK
		State.WALK:
			if input_direction.length() == 0:
				current_state = State.IDLE
			elif Input.is_action_pressed("run"):
				current_state = State.RUN
		State.RUN:
			if input_direction.length() == 0:
				current_state = State.IDLE
			elif not Input.is_action_pressed("run"):
				current_state = State.WALK

func _apply_movement(delta: float) -> void:
	var target_speed = run_speed if current_state == State.RUN else walk_speed
	var target_velocity = input_direction * target_speed
	
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
```

---

## 2. Jump with Coyote Time and Buffer

```gdscript
## Source: Jeh3no/Godot-Third-Person-Controller
## Original: Jump and InAir states
## Adapted: Standalone component

extends Node

@export var jump_velocity: float = 8.0
@export var coyote_time: float = 0.15
@export var jump_buffer_time: float = 0.1
@export var max_jumps: int = 1
@export var gravity_multiplier: float = 1.0

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var jump_count: int = 0
var was_on_floor: bool = false

func process(delta: float, character: CharacterBody3D) -> void:
	# Update timers
	if character.is_on_floor():
		coyote_timer = coyote_time
		jump_count = 0
	else:
		coyote_timer -= delta
	
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta
	
	# Apply gravity
	if not character.is_on_floor():
		character.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier * delta
	
	# Handle jump
	if jump_buffer_timer > 0 and coyote_timer > 0:
		character.velocity.y = jump_velocity
		jump_count += 1
		coyote_timer = 0
		jump_buffer_timer = 0
	
	was_on_floor = character.is_on_floor()
```

---

## 3. Sprint with Stamina

```gdscript
## Source: studiobool/SuperTuxWorld (adapted)
## Original: Player movement with sprint
## Adapted: Standalone component

extends Node

@export var sprint_speed: float = 10.0
@export var walk_speed: float = 5.0
@export var stamina_max: float = 100.0
@export var stamina_drain: float = 20.0
@export var stamina_regen: float = 10.0

var current_stamina: float = 100.0
var is_sprinting: bool = false

func process(delta: float) -> void:
	# Handle sprint input
	if Input.is_action_pressed("run") and current_stamina > 0:
		is_sprinting = true
		current_stamina -= stamina_drain * delta
	else:
		is_sprinting = false
		current_stamina = min(current_stamina + stamina_regen * delta, stamina_max)

func get_speed() -> float:
	return sprint_speed if is_sprinting else walk_speed
```

---

## 4. Crouch with Height Modification

```gdscript
## Source: studiobool/SuperTuxWorld (adapted)
## Original: Crouch mechanic
## Adapted: Standalone component

extends Node

@export var crouch_speed: float = 2.5
@export var stand_speed: float = 5.0
@export var crouch_height: float = 1.0
@export var stand_height: float = 2.0
@export var transition_speed: float = 10.0

var is_crouching: bool = false
var current_height: float = 2.0

func process(delta: float) -> void:
	if Input.is_action_just_pressed("crouch"):
		is_crouching = not is_crouching
	
	# Smooth height transition
	var target_height = crouch_height if is_crouching else stand_height
	current_height = lerp(current_height, target_height, transition_speed * delta)

func get_speed() -> float:
	return crouch_speed if is_crouching else stand_speed
```

---

## 5. Input Manager (Centralized)

```gdscript
## Source: Jeh3no/Godot-Third-Person-Controller
## Original: input_management_component_script
## Adapted: Standalone input handler

extends Node

func is_move_forward() -> bool:
	return Input.is_action_pressed("move_forward")

func is_move_backward() -> bool:
	return Input.is_action_pressed("move_backward")

func is_move_left() -> bool:
	return Input.is_action_pressed("move_left")

func is_move_right() -> bool:
	return Input.is_action_pressed("move_right")

func is_run() -> bool:
	return Input.is_action_pressed("run")

func is_jump() -> bool:
	return Input.is_action_just_pressed("jump")

func is_crouch() -> bool:
	return Input.is_action_just_pressed("crouch")

func is_interact() -> bool:
	return Input.is_action_just_pressed("interact")

func get_move_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
```
