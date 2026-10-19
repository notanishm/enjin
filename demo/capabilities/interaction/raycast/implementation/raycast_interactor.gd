## Raycast Interactor
## Performs raycasts to detect and interact with objects
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name RaycastInteractor
extends Node3D

## Export Variables
@export_group("Raycast Settings")
@export var ray_length: float = 10.0
@export var ray_width: float = 0.1
@export var collision_mask: int = 1
@export var interaction_action: String = "interact"

@export_group("Debug")
@export var show_raycast: bool = false
@export var debug_color: Color = Color.GREEN

## State Variables
var current_target: Node3D = null
var is_interacting: bool = false

## Node References
var camera: Camera3D
var raycast: RayCast3D

## Signals
signal target_found(target: Node3D)
signal target_lost(target: Node3D)
signal interaction_started(target: Node3D)
signal interaction_completed(target: Node3D)

func _ready() -> void:
	_setup_raycast()

func _setup_raycast() -> void:
	# Create raycast
	raycast = RayCast3D.new()
	raycast.name = "InteractRaycast"
	raycast.target_position = Vector3(0, 0, -ray_length)
	raycast.collision_mask = collision_mask
	raycast.enabled = true
	add_child(raycast)

func _physics_process(delta: float) -> void:
	_update_raycast()
	_check_input()

## Update raycast detection
func _update_raycast() -> void:
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		
		if collider != current_target:
			if current_target:
				_exit_target(current_target)
			
			current_target = collider as Node3D
			if current_target and current_target.has_method("on_interact_hover"):
				current_target.on_interact_hover()
				target_found.emit(current_target)
	else:
		if current_target:
			_exit_target(current_target)
			current_target = null

## Exit target
func _exit_target(target: Node3D) -> void:
	if target.has_method("on_interact_exit"):
		target.on_interact_exit()
	target_lost.emit(target)

## Check input
func _check_input() -> void:
	if Input.is_action_just_pressed(interaction_action):
		if current_target:
			_perform_interaction(current_target)

## Perform interaction
func _perform_interaction(target: Node3D) -> void:
	if not target:
		return
	
	if target.has_method("on_interact"):
		target.on_interact()
		interaction_started.emit(target)
		
		# Wait for interaction to complete
		if target.has_method("get_interaction_time"):
			var time = target.get_interaction_time()
			await get_tree().create_timer(time).timeout
		
		interaction_completed.emit(target)

## Public API
func get_current_target() -> Node3D:
	return current_target

func has_target() -> bool:
	return current_target != null

func set_ray_length(length: float) -> void:
	ray_length = length
	if raycast:
		raycast.target_position = Vector3(0, 0, -ray_length)

func set_collision_mask(mask: int) -> void:
	collision_mask = mask
	if raycast:
		raycast.collision_mask = mask

func set_interaction_action(action: String) -> void:
	interaction_action = action

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"ray_length": ray_length,
		"collision_mask": collision_mask,
		"current_target": current_target.name if current_target else "None",
		"is_interacting": is_interacting
	}
