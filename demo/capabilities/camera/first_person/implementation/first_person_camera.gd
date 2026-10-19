## First Person Camera
## FPS-style camera with mouse look
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name FirstPersonCamera
extends Node3D

## Export Variables
@export_group("Camera Settings")
@export var mouse_sensitivity: float = 0.002
@export var vertical_look_limit: float = 89.0

@export_group("Input")
@export var look_x_action: String = "camera_rotate_x"
@export var look_y_action: String = "camera_rotate_y"

## State Variables
var rotation_x: float = 0.0
var rotation_y: float = 0.0

## Node Reference
var camera: Camera3D

## Signals
signal camera_rotated(yaw: float, pitch: float)

func _ready() -> void:
	_setup_camera()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _setup_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Camera"
	add_child(camera)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation_y -= event.relative.x * mouse_sensitivity
		rotation_x -= event.relative.y * mouse_sensitivity
		
		# Clamp vertical rotation
		rotation_x = clamp(rotation_x, deg_to_rad(-vertical_look_limit), deg_to_rad(vertical_look_limit))
		
		# Apply rotation
		rotation.y = rotation_y
		rotation.x = rotation_x
		
		camera_rotated.emit(rotation_y, rotation_x)

## Public API
func set_sensitivity(sensitivity: float) -> void:
	mouse_sensitivity = sensitivity

func set_vertical_limit(limit: float) -> void:
	vertical_look_limit = limit

func get_yaw() -> float:
	return rotation_y

func get_pitch() -> float:
	return rotation_x

func get_camera() -> Camera3D:
	return camera

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"yaw": rotation_y,
		"pitch": rotation_x,
		"sensitivity": mouse_sensitivity,
		"vertical_limit": vertical_look_limit
	}
