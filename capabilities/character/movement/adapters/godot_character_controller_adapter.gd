## Godot Character Controller Adapter
## Adapts the Character Movement capability for standard Godot projects
##
## This adapter provides a simple interface for integrating the
## character movement capability into existing projects.

class_name GodotCharacterControllerAdapter
extends Node

## Adapter Configuration
@export_group("Adapter Settings")
@export var auto_setup: bool = true
@export var debug_mode: bool = false

## Character Reference
var character: CharacterBody3D
var movement_capability: Node

## Signals
signal adapter_ready
signal movement_started
signal movement_stopped
signal jumped
signal landed

func _ready() -> void:
	if auto_setup:
		setup()

## Setup the adapter with a character node
func setup(target_character: CharacterBody3D = null) -> void:
	if target_character:
		character = target_character
	else:
		character = get_parent() as CharacterBody3D
	
	if not character:
		push_error("GodotCharacterControllerAdapter: No CharacterBody3D found")
		return
	
	# Load and attach movement capability
	var movement_script = load("res://capabilities/character/movement/implementation/character_movement.gd")
	if movement_script:
		movement_capability = CharacterBody3D.new()
		movement_capability.set_script(movement_script)
		character.add_child(movement_capability)
		
		# Connect signals
		movement_capability.state_changed.connect(_on_state_changed)
		movement_capability.jumped.connect(_on_jumped)
		movement_capability.landed.connect(_on_landed)
		
		adapter_ready.emit()
		
		if debug_mode:
			print("GodotCharacterControllerAdapter: Setup complete")
	else:
		push_error("GodotCharacterControllerAdapter: Could not load movement script")

## Get current movement state
func get_state() -> String:
	if movement_capability:
		return movement_capability.get_state_name()
	return "Unknown"

## Check if character is grounded
func is_grounded() -> bool:
	if movement_capability:
		return movement_capability.is_grounded()
	return false

## Check if character is moving
func is_moving() -> bool:
	if movement_capability:
		return movement_capability.is_moving()
	return false

## Get current speed
func get_speed() -> float:
	if movement_capability:
		return movement_capability.get_speed()
	return 0.0

## Get movement direction
func get_direction() -> Vector3:
	if movement_capability:
		return movement_capability.input_direction
	return Vector3.ZERO

## Force jump
func force_jump() -> void:
	if movement_capability and movement_capability.is_grounded():
		movement_capability.velocity.y = movement_capability.jump_velocity
		movement_capability._change_state(movement_capability.State.JUMP)
		jumped.emit()

## Set walk speed
func set_walk_speed(speed: float) -> void:
	if movement_capability:
		movement_capability.walk_speed = speed

## Set run speed
func set_run_speed(speed: float) -> void:
	if movement_capability:
		movement_capability.run_speed = speed

## Set acceleration
func set_acceleration(acc: float) -> void:
	if movement_capability:
		movement_capability.acceleration = acc

## Set jump velocity
func set_jump_velocity(vel: float) -> void:
	if movement_capability:
		movement_capability.jump_velocity = vel

## Enable/disable running
func set_running(enabled: bool) -> void:
	if movement_capability:
		movement_capability.is_running = enabled

## Callback handlers
func _on_state_changed(old_state: int, new_state: int) -> void:
	if debug_mode:
		print("State changed: %s -> %s" % [
			movement_capability.State.keys()[old_state],
			movement_capability.State.keys()[new_state]
		])
	
	if new_state == movement_capability.State.WALK or new_state == movement_capability.State.RUN:
		movement_started.emit()
	elif new_state == movement_capability.State.IDLE:
		movement_stopped.emit()

func _on_jumped() -> void:
	jumped.emit()
	if debug_mode:
		print("Jumped")

func _on_landed() -> void:
	landed.emit()
	if debug_mode:
		print("Landed")

## Get debug information
func get_debug_info() -> Dictionary:
	return {
		"state": get_state(),
		"is_grounded": is_grounded(),
		"is_moving": is_moving(),
		"speed": get_speed(),
		"direction": get_direction(),
		"velocity": movement_capability.velocity if movement_capability else Vector3.ZERO
	}

## Static factory method
static func create(target_character: CharacterBody3D, parent: Node = null) -> GodotCharacterControllerAdapter:
	var adapter = GodotCharacterControllerAdapter.new()
	if parent:
		parent.add_child(adapter)
	else:
		target_character.add_child(adapter)
	adapter.setup(target_character)
	return adapter
