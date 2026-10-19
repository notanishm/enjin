## Jump Component
## Standalone jump mechanic with coyote time and jump buffering
##
## Source: Jeh3no/Godot-Third-Person-Controller
## Normalized for capability reuse

class_name JumpComponent
extends Node

## Export Variables
@export_group("Jump Settings")
@export var jump_velocity: float = 12.0
@export var max_jumps: int = 1
@export var gravity_multiplier: float = 2.5
@export var air_control: float = 0.5

@export_group("Timing")
@export var coyote_time: float = 0.15
@export var jump_buffer_time: float = 0.1

@export_group("Input")
@export var jump_action: String = "jump"

## State Variables
var jump_count: int = 0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var is_jumping: bool = false

## Node Reference
var character: CharacterBody3D

## Signals
signal jumped
signal landed
signal jump_failed

func _ready() -> void:
	character = get_parent() as CharacterBody3D
	if not character:
		push_error("JumpComponent: Must be child of CharacterBody3D")

func _physics_process(delta: float) -> void:
	if not character:
		return
	
	_update_timers(delta)
	_apply_gravity(delta)
	_handle_jump_input()
	_update_state()

## Update timers
func _update_timers(delta: float) -> void:
	# Coyote time
	if was_on_floor and not character.is_on_floor():
		coyote_timer = coyote_time
	elif coyote_timer > 0:
		coyote_timer -= delta
	
	# Jump buffer
	if Input.is_action_just_pressed(jump_action):
		jump_buffer_timer = jump_buffer_time
	elif jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	
	was_on_floor = character.is_on_floor()

## Apply gravity
func _apply_gravity(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier * delta

## Handle jump input
func _handle_jump_input() -> void:
	if jump_buffer_timer <= 0:
		return
	
	var can_perform_jump = false
	
	# Check if we can jump
	if character.is_on_floor() or coyote_timer > 0:
		can_perform_jump = true
	elif jump_count < max_jumps - 1:
		can_perform_jump = true
	
	if can_perform_jump:
		_perform_jump()
	else:
		jump_failed.emit()

## Perform the jump
func _perform_jump() -> void:
	character.velocity.y = jump_velocity
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	jump_count += 1
	is_jumping = true
	jumped.emit()

## Update state
func _update_state() -> void:
	if character.is_on_floor():
		jump_count = 0
		if is_jumping:
			is_jumping = false
			landed.emit()

## Public API
func can_jump() -> bool:
	return character.is_on_floor() or coyote_timer > 0 or jump_count < max_jumps - 1

func is_grounded() -> bool:
	return character.is_on_floor()

func get_jump_count() -> int:
	return jump_count

func get_coyote_time_remaining() -> float:
	return coyote_timer

func get_jump_buffer_remaining() -> float:
	return jump_buffer_timer

## Force jump (external API)
func force_jump() -> void:
	if can_jump():
		_perform_jump()

## Reset jump state
func reset() -> void:
	jump_count = 0
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	is_jumping = false

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"jump_count": jump_count,
		"max_jumps": max_jumps,
		"coyote_timer": coyote_timer,
		"jump_buffer_timer": jump_buffer_timer,
		"is_grounded": is_grounded(),
		"can_jump": can_jump(),
		"is_jumping": is_jumping
	}
