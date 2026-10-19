## Sprint Component
## Standalone sprint mechanic with toggle and hold modes
##
## Source: Jeh3no/Godot-Third-Person-Controller
## Reference: studiobool/SuperTuxWorld
## Normalized for capability reuse

class_name SprintComponent
extends Node

## Export Variables
@export_group("Sprint Settings")
@export var sprint_speed: float = 10.0
@export var walk_speed: float = 5.0
@export var sprint_toggle: bool = false
@export var sprint_acceleration: float = 20.0

@export_group("Stamina (Optional)")
@export var use_stamina: bool = false
@export var max_stamina: float = 100.0
@export var stamina_drain: float = 20.0
@export var stamina_regen: float = 10.0

@export_group("Input")
@export var run_action: String = "run"

## State Variables
var is_sprinting: bool = false
var current_speed: float = 0.0
var stamina: float = 0.0

## Node Reference
var character: CharacterBody3D

## Signals
signal sprint_started
signal sprint_ended
signal stamina_depleted
signal stamina_recovered

func _ready() -> void:
	character = get_parent() as CharacterBody3D
	if not character:
		push_error("SprintComponent: Must be child of CharacterBody3D")
	stamina = max_stamina

func _physics_process(delta: float) -> void:
	if not character:
		return
	
	_handle_sprint_input()
	_update_stamina(delta)
	_update_speed(delta)

## Handle sprint input
func _handle_sprint_input() -> void:
	if sprint_toggle:
		# Toggle mode
		if Input.is_action_just_pressed(run_action):
			if use_stamina and stamina <= 0:
				return
			is_sprinting = not is_sprinting
			if is_sprinting:
				sprint_started.emit()
			else:
				sprint_ended.emit()
	else:
		# Hold mode
		var was_sprinting = is_sprinting
		is_sprinting = Input.is_action_pressed(run_action) and (not use_stamina or stamina > 0)
		
		if is_sprinting and not was_sprinting:
			sprint_started.emit()
		elif not is_sprinting and was_sprinting:
			sprint_ended.emit()

## Update stamina
func _update_stamina(delta: float) -> void:
	if not use_stamina:
		return
	
	if is_sprinting:
		stamina -= stamina_drain * delta
		if stamina <= 0:
			stamina = 0
			is_sprinting = false
			stamina_depleted.emit()
			sprint_ended.emit()
	else:
		if stamina < max_stamina:
			stamina += stamina_regen * delta
			if stamina >= max_stamina:
				stamina = max_stamina
				stamina_recovered.emit()

## Update speed
func _update_speed(delta: float) -> void:
	var target_speed = sprint_speed if is_sprinting else walk_speed
	current_speed = lerp(current_speed, target_speed, sprint_acceleration * delta)

## Public API
func start_sprint() -> void:
	if use_stamina and stamina <= 0:
		return
	is_sprinting = true
	sprint_started.emit()

func stop_sprint() -> void:
	is_sprinting = false
	sprint_ended.emit()

func toggle_sprint() -> void:
	if is_sprinting:
		stop_sprint()
	else:
		start_sprint()

func get_speed() -> float:
	return current_speed

func get_stamina() -> float:
	return stamina

func get_stamina_percent() -> float:
	if not use_stamina:
		return 100.0
	return (stamina / max_stamina) * 100.0

func get_is_sprinting() -> bool:
	return is_sprinting

func can_sprint() -> bool:
	return not use_stamina or stamina > 0

func set_stamina(value: float) -> void:
	stamina = clamp(value, 0, max_stamina)

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"is_sprinting": is_sprinting,
		"current_speed": current_speed,
		"stamina": stamina,
		"max_stamina": max_stamina,
		"stamina_percent": get_stamina_percent(),
		"can_sprint": can_sprint()
	}
