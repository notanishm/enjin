## Camera Shake
## Screen shake effect for impacts and events
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name CameraShake
extends Node

## Export Variables
@export_group("Shake Settings")
@export var shake_intensity: float = 0.5
@export var shake_duration: float = 0.3
@export var shake_decay: float = 10.0

## State Variables
var current_shake: float = 0.0
var shake_time: float = 0.0
var is_shaking: bool = false

## Node Reference
var camera: Camera3D

## Signals
signal shake_started
signal shake_ended

func _ready() -> void:
	camera = _find_camera()

func _find_camera() -> Camera3D:
	var parent = get_parent()
	if parent is Camera3D:
		return parent
	for child in get_children():
		if child is Camera3D:
			return child
	return null

func _process(delta: float) -> void:
	if is_shaking:
		_update_shake(delta)

## Update shake
func _update_shake(delta: float) -> void:
	shake_time -= delta
	
	if shake_time <= 0:
		_stop_shake()
		return
	
	# Apply shake
	var offset = Vector3(
		randf_range(-1, 1) * current_shake,
		randf_range(-1, 1) * current_shake,
		0
	)
	
	if camera:
		camera.position += offset
	
	# Decay shake
	current_shake *= (1.0 - shake_decay * delta)

## Stop shake
func _stop_shake() -> void:
	is_shaking = false
	current_shake = 0.0
	shake_ended.emit()

## Public API
func shake(intensity: float = 0.0, duration: float = 0.0) -> void:
	current_shake = intensity if intensity > 0 else shake_intensity
	shake_time = duration if duration > 0 else shake_duration
	is_shaking = true
	shake_started.emit()

func set_shake_intensity(intensity: float) -> void:
	shake_intensity = intensity

func set_shake_duration(duration: float) -> void:
	shake_duration = duration

func set_shake_decay(decay: float) -> void:
	shake_decay = decay

func get_is_shaking() -> bool:
	return is_shaking

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"is_shaking": is_shaking,
		"current_shake": current_shake,
		"shake_time": shake_time,
		"shake_intensity": shake_intensity,
		"shake_duration": shake_duration
	}
