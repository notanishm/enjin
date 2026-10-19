## Simple Navigation
## Basic pathfinding without NavigationServer dependency
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name SimpleNavigation
extends Node3D

## Export Variables
@export_group("Navigation Settings")
@export var move_speed: float = 5.0
@export var arrival_distance: float = 0.5
@export var path_update_interval: float = 0.5

## State Variables
var target_position: Vector3 = Vector3.ZERO
var path: Array[Vector3] = []
var current_path_index: int = 0
var is_moving: bool = false
var path_timer: float = 0.0

## Node Reference
var character: CharacterBody3D

## Signals
signal path_completed
signal path_updated
signal target_reached

func _ready() -> void:
	character = get_parent() as CharacterBody3D

func _physics_process(delta: float) -> void:
	if not is_moving or not character:
		return
	
	# Update path periodically
	path_timer += delta
	if path_timer >= path_update_interval:
		path_timer = 0.0
		_update_path()
	
	# Follow path
	_follow_path(delta)

## Update path to target
func _update_path() -> void:
	# Simple direct path (no NavigationServer)
	path.clear()
	path.append(target_position)
	current_path_index = 0
	path_updated.emit()

## Follow current path
func _follow_path(delta: float) -> void:
	if path.is_empty():
		_arrive_at_target()
		return
	
	var target = path[current_path_index]
	var direction = (target - character.global_position).normalized()
	
	# Check if we've reached the current point
	if character.global_position.distance_to(target) < arrival_distance:
		current_path_index += 1
		
		if current_path_index >= path.size():
			_arrive_at_target()
			return
	
	# Move character
	character.velocity = direction * move_speed
	character.move_and_slide()

## Arrive at target
func _arrive_at_target() -> void:
	is_moving = false
	character.velocity = Vector3.ZERO
	path.clear()
	target_reached.emit()
	path_completed.emit()

## Public API
func set_target(target: Vector3) -> void:
	target_position = target
	is_moving = true
	path_timer = 0.0
	_update_path()

func set_move_speed(speed: float) -> void:
	move_speed = speed

func get_target() -> Vector3:
	return target_position

func is_path_active() -> bool:
	return is_moving

func stop() -> void:
	is_moving = false
	character.velocity = Vector3.ZERO

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"is_moving": is_moving,
		"target_position": target_position,
		"path_points": path.size(),
		"current_index": current_path_index,
		"move_speed": move_speed
	}
