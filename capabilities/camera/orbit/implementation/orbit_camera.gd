## Orbit Camera
## Camera that orbits around a target
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name OrbitCamera
extends Node3D

## Export Variables
@export_group("Orbit Settings")
@export var orbit_distance: float = 5.0
@export var orbit_height: float = 2.0
@export var orbit_speed: float = 0.5
@export var orbit_smoothing: float = 10.0

@export_group("Camera Limits")
@export var min_pitch: float = -80.0
@export var max_pitch: float = 80.0

## State Variables
var current_angle: float = 0.0
var current_pitch: float = 45.0
var target_position: Vector3 = Vector3.ZERO

## Node Reference
var camera: Camera3D
var follow_target: Node3D

## Signals
signal orbit_changed(angle: float)

func _ready() -> void:
	_setup_camera()

func _setup_camera() -> void:
	camera = Camera3D.new()
	camera.name = "OrbitCamera"
	add_child(camera)

func _physics_process(delta: float) -> void:
	if follow_target:
		_follow_target(delta)
	_update_camera(delta)

## Follow target
func _follow_target(delta: float) -> void:
	target_position = follow_target.global_position
	global_position = global_position.lerp(target_position, orbit_smoothing * delta)

## Update camera position
func _update_camera(delta: float) -> void:
	# Auto orbit
	current_angle += orbit_speed * delta
	
	# Calculate camera position
	var offset = Vector3(
		sin(current_angle) * orbit_distance,
		orbit_height,
		cos(current_angle) * orbit_distance
	)
	
	camera.position = offset
	camera.look_at(Vector3.ZERO, Vector3.UP)
	
	orbit_changed.emit(current_angle)

## Public API
func set_follow_target(target: Node3D) -> void:
	follow_target = target

func set_orbit_distance(distance: float) -> void:
	orbit_distance = distance

func set_orbit_height(height: float) -> void:
	orbit_height = height

func set_orbit_speed(speed: float) -> void:
	orbit_speed = speed

func set_angle(angle: float) -> void:
	current_angle = angle

func get_angle() -> float:
	return current_angle

func get_camera() -> Camera3D:
	return camera

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"orbit_distance": orbit_distance,
		"orbit_height": orbit_height,
		"orbit_speed": orbit_speed,
		"current_angle": current_angle,
		"target": follow_target.name if follow_target else "None"
	}
