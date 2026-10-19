## Character Movement Capability
## Normalized third-person character movement with state machine
##
## Sources:
## - Jeh3no/Godot-Third-Person-Controller (primary)
## - gtibo/Godot-Plush-Character (upstream)
## - godotengine/godot-demo-projects (reference)
## - studiobool/SuperTuxWorld (reference)

class_name CharacterMovement
extends CharacterBody3D

## Movement States
enum State {
	IDLE,
	WALK,
	RUN,
	JUMP,
	IN_AIR
}

## Export Variables - Movement
@export_group("Movement")
@export var walk_speed: float = 5.0
@export var run_speed: float = 10.0
@export var acceleration: float = 20.0
@export var deceleration: float = 15.0
@export var air_control: float = 0.5
@export var slope_limit: float = 45.0

## Export Variables - Jump
@export_group("Jump")
@export var jump_velocity: float = 12.0
@export var jump_buffer_time: float = 0.1
@export var coyote_time: float = 0.15
@export var max_jumps: int = 1
@export var gravity_multiplier: float = 2.5

## Export Variables - Run
@export_group("Run")
@export var run_toggle: bool = false

## Input Actions
@export_group("Input Actions")
@export var move_forward_action: String = "move_forward"
@export var move_backward_action: String = "move_backward"
@export var move_left_action: String = "move_left"
@export var move_right_action: String = "move_right"
@export var jump_action: String = "jump"
@export var run_action: String = "run"

## State Variables
var current_state: State = State.IDLE
var previous_state: State = State.IDLE
var input_direction: Vector3 = Vector3.ZERO
var movement_direction: Vector3 = Vector3.ZERO
var is_running: bool = false
var jump_count: int = 0
var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var was_on_floor: bool = false

## Node References
@onready var animation_tree: AnimationTree = $AnimationTree if has_node("AnimationTree") else null
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

## Signals
signal state_changed(old_state: State, new_state: State)
signal jumped
signal landed

func _ready() -> void:
	_setup_input_actions()
	_change_state(State.IDLE)

func _physics_process(delta: float) -> void:
	_update_input()
	_update_timers(delta)
	_apply_gravity(delta)
	_update_state(delta)
	_apply_movement(delta)
	_apply_jump(delta)
	move_and_slide()
	_update_animation()

## Setup default input actions if not configured
func _setup_input_actions() -> void:
	# Ensure input actions exist
	for action in [move_forward_action, move_backward_action, move_left_action, move_right_action, jump_action, run_action]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)

## Update input direction from input actions
func _update_input() -> void:
	input_direction = Vector3.ZERO
	
	# Forward/backward
	if Input.is_action_pressed(move_forward_action):
		input_direction.z -= 1.0
	if Input.is_action_pressed(move_backward_action):
		input_direction.z += 1.0
	
	# Left/right
	if Input.is_action_pressed(move_left_action):
		input_direction.x -= 1.0
	if Input.is_action_pressed(move_right_action):
		input_direction.x += 1.0
	
	# Normalize diagonal movement
	input_direction = input_direction.normalized()
	
	# Update run state
	if run_toggle:
		if Input.is_action_just_pressed(run_action):
			is_running = not is_running
	else:
		is_running = Input.is_action_pressed(run_action)

## Update timers for jump buffer and coyote time
func _update_timers(delta: float) -> void:
	# Jump buffer
	if Input.is_action_just_pressed(jump_action):
		jump_buffer_timer = jump_buffer_time
	elif jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	
	# Coyote time
	if was_on_floor and not is_on_floor():
		coyote_timer = coyote_time
	elif coyote_timer > 0:
		coyote_timer -= delta
	
	was_on_floor = is_on_floor()

## Apply gravity
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier * delta

## Update state based on current conditions
func _update_state(_delta: float) -> void:
	var new_state: State = current_state
	
	match current_state:
		State.IDLE:
			if input_direction.length() > 0:
				new_state = State.RUN if is_running else State.WALK
			elif not is_on_floor():
				new_state = State.IN_AIR
		
		State.WALK, State.RUN:
			if input_direction.length() == 0:
				new_state = State.IDLE
			elif is_running and current_state == State.WALK:
				new_state = State.RUN
			elif not is_running and current_state == State.RUN:
				new_state = State.WALK
			elif not is_on_floor():
				new_state = State.IN_AIR
		
		State.JUMP:
			if is_on_floor():
				new_state = State.IDLE
				landed.emit()
			elif velocity.y <= 0:
				new_state = State.IN_AIR
		
		State.IN_AIR:
			if is_on_floor():
				new_state = State.IDLE
				landed.emit()
				jump_count = 0
	
	if new_state != current_state:
		_change_state(new_state)

## Change state with notification
func _change_state(new_state: State) -> void:
	previous_state = current_state
	current_state = new_state
	state_changed.emit(previous_state, current_state)

## Apply movement based on current state
func _apply_movement(delta: float) -> void:
	var target_speed: float = 0.0
	var current_acceleration: float = deceleration
	
	match current_state:
		State.IDLE:
			target_speed = 0.0
			current_acceleration = deceleration
		
		State.WALK:
			target_speed = walk_speed
			current_acceleration = acceleration
		
		State.RUN:
			target_speed = run_speed
			current_acceleration = acceleration
		
		State.JUMP, State.IN_AIR:
			target_speed = walk_speed * air_control
			current_acceleration = acceleration
	
	# Calculate target velocity
	var target_velocity = input_direction * target_speed
	
	# Smooth acceleration/deceleration
	velocity.x = lerp(velocity.x, target_velocity.x, current_acceleration * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, current_acceleration * delta)
	
	# Rotate model to face movement direction
	if input_direction.length() > 0:
		var target_rotation = atan2(input_direction.x, input_direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 10.0 * delta)

## Apply jump if conditions are met
func _apply_jump(_delta: float) -> void:
	# Check for jump input with buffer
	var can_jump = false
	
	if is_on_floor() or coyote_timer > 0:
		can_jump = true
	elif jump_count < max_jumps - 1:
		can_jump = true
	
	if jump_buffer_timer > 0 and can_jump:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		jump_count += 1
		_change_state(State.JUMP)
		jumped.emit()

## Update animation based on state
func _update_animation() -> void:
	if animation_tree == null:
		return
	
	match current_state:
		State.IDLE:
			animation_tree["parameters/Idle/blend_position"] = 0.0
		State.WALK:
			animation_tree["parameters/Walk/blend_position"] = 0.5
		State.RUN:
			animation_tree["parameters/Walk/blend_position"] = 1.0
		State.JUMP, State.IN_AIR:
			animation_tree["parameters/Jump/blend_position"] = 1.0

## Public API
func get_current_state() -> State:
	return current_state

func get_state_name() -> String:
	match current_state:
		State.IDLE:
			return "Idle"
		State.WALK:
			return "Walk"
		State.RUN:
			return "Run"
		State.JUMP:
			return "Jump"
		State.IN_AIR:
			return "InAir"
	return "Unknown"

func is_grounded() -> bool:
	return is_on_floor()

func is_moving() -> bool:
	return input_direction.length() > 0

func get_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()

func getMovementVelocity() -> Vector3:
	return velocity

## Debug visualization
func _draw_debug() -> void:
	if Engine.is_editor_hint():
		return
	
	# Draw movement direction (requires DebugDraw3D addon)
	# DebugDraw3D.draw_line(global_position, global_position + input_direction * 2, Color.GREEN)
	# DebugDraw3D.draw_line(global_position, global_position + velocity * 0.1, Color.RED)
