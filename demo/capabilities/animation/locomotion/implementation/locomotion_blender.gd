## Locomotion Blender
## Blends animations based on movement parameters
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name LocomotionBlender
extends Node

## Export Variables
@export_group("Animation Settings")
@export var blend_speed: float = 10.0
@export var idle_threshold: float = 0.1
@export var walk_threshold: float = 0.5
@export var run_threshold: float = 0.8

@export_group("Animation Names")
@export var idle_animation: String = "idle"
@export var walk_animation: String = "walk"
@export var run_animation: String = "run"
@export var jump_animation: String = "jump"
@export var fall_animation: String = "fall"

## State Variables
var current_animation: String = ""
var target_animation: String = ""
var blend_value: float = 0.0
var velocity: Vector3 = Vector3.ZERO
var is_grounded: bool = true
var is_jumping: bool = false

## Node Reference
var animation_player: AnimationPlayer
var animation_tree: AnimationTree

## Signals
signal animation_changed(old_anim: String, new_anim: String)

func _ready() -> void:
	# Find animation nodes
	animation_player = _find_animation_player()
	animation_tree = _find_animation_tree()

func _find_animation_player() -> AnimationPlayer:
	var parent = get_parent()
	if parent is AnimationPlayer:
		return parent
	for child in get_children():
		if child is AnimationPlayer:
			return child
	return null

func _find_animation_tree() -> AnimationTree:
	var parent = get_parent()
	if parent is AnimationTree:
		return parent
	for child in get_children():
		if child is AnimationTree:
			return child
	return null

func _physics_process(delta: float) -> void:
	_update_blend(delta)
	_play_animation()

## Update blend value
func _update_blend(delta: float) -> void:
	var speed = Vector2(velocity.x, velocity.z).length()
	
	# Determine target blend based on speed
	if speed < idle_threshold:
		target_animation = idle_animation
		blend_value = lerp(blend_value, 0.0, blend_speed * delta)
	elif speed < walk_threshold:
		target_animation = walk_animation
		blend_value = lerp(blend_value, 0.5, blend_speed * delta)
	else:
		target_animation = run_animation
		blend_value = lerp(blend_value, 1.0, blend_speed * delta)
	
	# Override for airborne states
	if not is_grounded:
		if is_jumping:
			target_animation = jump_animation
		else:
			target_animation = fall_animation

## Play animation
func _play_animation() -> void:
	if target_animation != current_animation:
		if animation_player:
			animation_player.play(target_animation)
		elif animation_tree:
			# Use blend tree if available
			_animation_tree_blend()
		
		animation_changed.emit(current_animation, target_animation)
		current_animation = target_animation

## Animation tree blend
func _animation_tree_blend() -> void:
	if not animation_tree:
		return
	
	# Set blend parameters
	if animation_tree.has_parameter("Idle/Run/blend"):
		animation_tree["parameters/Idle/Run/blend"] = blend_value

## Set movement parameters
func set_velocity(vel: Vector3) -> void:
	velocity = vel

func set_grounded(grounded: bool) -> void:
	is_grounded = grounded

func set_jumping(jumping: bool) -> void:
	is_jumping = jumping

## Get current animation
func get_current_animation() -> String:
	return current_animation

## Get blend value
func get_blend_value() -> float:
	return blend_value

## Set custom animation
func set_animation(anim: String) -> void:
	target_animation = anim

## Force animation change
func force_animation(anim: String) -> void:
	current_animation = ""
	target_animation = anim

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"current_animation": current_animation,
		"target_animation": target_animation,
		"blend_value": blend_value,
		"velocity": velocity.length(),
		"is_grounded": is_grounded,
		"is_jumping": is_jumping
	}
