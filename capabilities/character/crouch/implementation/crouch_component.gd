## Crouch Component
## Standalone crouch mechanic with collision modification
##
## Source: studiobool/SuperTuxWorld
## Reference: godotengine/godot-demo-projects
## Normalized for capability reuse
##
## License: GPL-3.0 (from source)
## Consider re-implementing for MIT projects

class_name CrouchComponent
extends Node

## Export Variables
@export_group("Crouch Settings")
@export var crouch_speed: float = 2.5
@export var stand_speed: float = 5.0
@export var crouch_height: float = 1.0
@export var stand_height: float = 2.0
@export var crouch_toggle: bool = false
@export var crouch_transition_speed: float = 10.0

@export_group("Input")
@export var crouch_action: String = "crouch"

## State Variables
var is_crouching: bool = false
var current_height: float = 0.0
var target_height: float = 0.0
var current_speed: float = 0.0

## Node References
var character: CharacterBody3D
var collision_shape: CollisionShape3D

## Signals
signal crouch_started
signal crouch_ended
signal crouch_changed(is_crouching: bool)

func _ready() -> void:
	character = get_parent() as CharacterBody3D
	if not character:
		push_error("CrouchComponent: Must be child of CharacterBody3D")
	
	# Find collision shape
	collision_shape = character.get_node("CollisionShape3D") if character.has_node("CollisionShape3D") else null
	
	# Initialize height
	current_height = stand_height
	target_height = stand_height
	current_speed = stand_speed

func _physics_process(delta: float) -> void:
	if not character:
		return
	
	_handle_crouch_input()
	_update_height(delta)
	_update_speed(delta)

## Handle crouch input
func _handle_crouch_input() -> void:
	if crouch_toggle:
		# Toggle mode
		if Input.is_action_just_pressed(crouch_action):
			is_crouching = not is_crouching
			if is_crouching:
				crouch_started.emit()
			else:
				crouch_ended.emit()
			crouch_changed.emit(is_crouching)
	else:
		# Hold mode
		var was_crouching = is_crouching
		is_crouching = Input.is_action_pressed(crouch_action)
		
		if is_crouching and not was_crouching:
			crouch_started.emit()
			crouch_changed.emit(true)
		elif not is_crouching and was_crouching:
			crouch_ended.emit()
			crouch_changed.emit(false)

## Update height
func _update_height(delta: float) -> void:
	target_height = crouch_height if is_crouching else stand_height
	current_height = lerp(current_height, target_height, crouch_transition_speed * delta)
	
	# Update collision shape
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = current_height

## Update speed
func _update_speed(delta: float) -> void:
	var target_speed = crouch_speed if is_crouching else stand_speed
	current_speed = lerp(current_speed, target_speed, crouch_transition_speed * delta)

## Public API
func start_crouch() -> void:
	if not is_crouching:
		is_crouching = true
		crouch_started.emit()
		crouch_changed.emit(true)

func stop_crouch() -> void:
	if is_crouching:
		is_crouching = false
		crouch_ended.emit()
		crouch_changed.emit(false)

func toggle_crouch() -> void:
	if is_crouching:
		stop_crouch()
	else:
		start_crouch()

func get_speed() -> float:
	return current_speed

func get_height() -> float:
	return current_height

func get_is_crouching() -> bool:
	return is_crouching

func set_crouch_height(height: float) -> void:
	crouch_height = height

func set_stand_height(height: float) -> void:
	stand_height = height

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"is_crouching": is_crouching,
		"current_height": current_height,
		"target_height": target_height,
		"current_speed": current_speed,
		"crouch_speed": crouch_speed,
		"stand_speed": stand_speed
	}
