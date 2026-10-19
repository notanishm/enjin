## Third Person Camera
## Follow camera with orbit, collision, and smoothing
##
## Source: Jeh3no/Godot-Third-Person-Controller
## Reference: ramokz/phantom-camera
## Normalized for capability reuse

class_name ThirdPersonCamera
extends Node3D

## Export Variables
@export_group("Camera Settings")
@export var follow_distance: float = 5.0
@export var follow_height: float = 2.0
@export var follow_smoothing: float = 10.0
@export var rotation_speed: float = 0.002
@export var zoom_speed: float = 0.5
@export var min_zoom: float = 2.0
@export var max_zoom: float = 10.0

@export_group("Camera Limits")
@export var min_pitch: float = -80.0
@export var max_pitch: float = 80.0

@export_group("Input")
@export var rotate_x_action: String = "camera_rotate_x"
@export var rotate_y_action: String = "camera_rotate_y"
@export var zoom_in_action: String = "camera_zoom_in"
@export var zoom_out_action: String = "camera_zoom_out"

## State Variables
var current_yaw: float = 0.0
var current_pitch: float = 45.0
var current_distance: float = 5.0
var enabled: bool = true

## Node References
var camera: Camera3D
var spring_arm: SpringArm3D
var follow_target: Node3D

## Signals
signal camera_rotated(yaw: float, pitch: float)
signal camera_zoomed(distance: float)

func _ready() -> void:
	_setup_camera()
	current_distance = follow_distance

func _setup_camera() -> void:
	spring_arm = SpringArm3D.new()
	spring_arm.name = "SpringArm"
	spring_arm.spring_length = current_distance
	spring_arm.position = Vector3(0, follow_height, 0)
	add_child(spring_arm)
	
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0, 0, current_distance)
	spring_arm.add_child(camera)

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	
	if follow_target:
		_follow_target(delta)
	
	_update_camera_rotation()

func _follow_target(delta: float) -> void:
	var target_pos = follow_target.global_position
	target_pos.y += follow_height
	global_position = global_position.lerp(target_pos, follow_smoothing * delta)

func _update_camera_rotation() -> void:
	var input_x = Input.get_action_raw_strength(rotate_x_action)
	var input_y = Input.get_action_raw_strength(rotate_y_action)
	
	if input_x != 0 or input_y != 0:
		current_yaw += input_x * rotation_speed * 100
		current_pitch += input_y * rotation_speed * 100
		current_pitch = clamp(current_pitch, min_pitch, max_pitch)
		current_yaw = fmod(current_yaw, 360.0)
		
		rotation.y = deg_to_rad(current_yaw)
		spring_arm.rotation.x = deg_to_rad(-current_pitch)
		
		camera_rotated.emit(current_yaw, current_pitch)
	
	var zoom_in = Input.get_action_raw_strength(zoom_in_action)
	var zoom_out = Input.get_action_raw_strength(zoom_out_action)
	
	if zoom_in != 0 or zoom_out != 0:
		var zoom_delta = (zoom_in - zoom_out) * zoom_speed
		current_distance = clamp(current_distance + zoom_delta, min_zoom, max_zoom)
		spring_arm.spring_length = current_distance
		camera_zoomed.emit(current_distance)

func set_follow_target(target: Node3D) -> void:
	follow_target = target

func set_follow_distance(distance: float) -> void:
	follow_distance = distance
	current_distance = distance
	if spring_arm:
		spring_arm.spring_length = distance

func set_follow_height(height: float) -> void:
	follow_height = height
	if spring_arm:
		spring_arm.position.y = height

func set_camera_rotation(yaw: float, pitch: float) -> void:
	current_yaw = yaw
	current_pitch = clamp(pitch, min_pitch, max_pitch)
	rotation.y = deg_to_rad(current_yaw)
	if spring_arm:
		spring_arm.rotation.x = deg_to_rad(-current_pitch)

func get_yaw() -> float:
	return current_yaw

func get_pitch() -> float:
	return current_pitch

func get_distance() -> float:
	return current_distance

func get_camera() -> Camera3D:
	return camera

func get_spring_arm() -> SpringArm3D:
	return spring_arm

func get_debug_info() -> Dictionary:
	var target_name = "None"
	if follow_target:
		target_name = follow_target.name
	return {
		"follow_distance": follow_distance,
		"follow_height": follow_height,
		"current_yaw": current_yaw,
		"current_pitch": current_pitch,
		"current_distance": current_distance,
		"target": target_name
	}
