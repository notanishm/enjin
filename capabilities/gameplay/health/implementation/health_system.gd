## Health System
## Manages health, damage, healing, and death
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name HealthSystem
extends Node

## Export Variables
@export_group("Health Settings")
@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var regeneration_rate: float = 0.0
@export var invincibility_time: float = 0.0

@export_group("State")
@export var is_alive: bool = true
@export var is_invincible: bool = false

## State Variables
var invincibility_timer: float = 0.0

## Signals
signal health_changed(old_health: float, new_health: float)
signal damage_taken(amount: float, source: Node)
signal healed(amount: float, source: Node)
signal died()
signal respawned()

func _ready() -> void:
	current_health = max_health

func _process(delta: float) -> void:
	# Handle invincibility timer
	if is_invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false
	
	# Handle regeneration
	if regeneration_rate > 0 and is_alive:
		heal(regeneration_rate * delta, self)

## Take damage
func take_damage(amount: float, source: Node = null) -> void:
	if not is_alive or is_invincible:
		return
	
	var old_health = current_health
	current_health = max(current_health - amount, 0.0)
	
	health_changed.emit(old_health, current_health)
	damage_taken.emit(amount, source)
	
	# Check for death
	if current_health <= 0:
		_die()

## Heal
func heal(amount: float, source: Node = null) -> void:
	if not is_alive:
		return
	
	var old_health = current_health
	current_health = min(current_health + amount, max_health)
	
	if current_health != old_health:
		health_changed.emit(old_health, current_health)
		healed.emit(amount, source)

## Die
func _die() -> void:
	is_alive = false
	died.emit()

## Respawn
func respawn() -> void:
	current_health = max_health
	is_alive = true
	respawned.emit()

## Set invincible
func set_invincible(duration: float) -> void:
	is_invincible = true
	invincibility_timer = duration

## Public API
func set_max_health(health: float) -> void:
	max_health = health
	current_health = min(current_health, max_health)
	health_changed.emit(current_health, current_health)

func get_health() -> float:
	return current_health

func get_max_health() -> float:
	return max_health

func get_health_percent() -> float:
	return (current_health / max_health) * 100.0

func is_full_health() -> bool:
	return current_health >= max_health

func set_regeneration_rate(rate: float) -> void:
	regeneration_rate = rate

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"current_health": current_health,
		"max_health": max_health,
		"health_percent": get_health_percent(),
		"is_alive": is_alive,
		"is_invincible": is_invincible,
		"regeneration_rate": regeneration_rate
	}
