## Landing VFX
## Creates visual effects when landing
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name LandingVFX
extends Node

## Export Variables
@export_group("Landing Settings")
@export var min_landing_velocity: float = 2.0
@export var max_landing_velocity: float = 15.0

## Landing Particles
var landing_particles: GPUParticles3D

## Node Reference
var parent: Node3D

## Signals
signal landed(position: Vector3, velocity: float)

func _ready() -> void:
	parent = get_parent() as Node3D
	_setup_particles()

func _setup_particles() -> void:
	landing_particles = GPUParticles3D.new()
	landing_particles.name = "LandingParticles"
	landing_particles.emitting = false
	landing_particles.one_shot = true
	landing_particles.explosiveness = 1.0
	add_child(landing_particles)

## Handle landing
func on_landed(velocity: float) -> void:
	if velocity < min_landing_velocity:
		return
	
	var position = parent.global_position if parent else Vector3.ZERO
	_play_landing(position, velocity)

## Play landing effect
func _play_landing(pos: Vector3, velocity: float) -> void:
	# Position particles
	landing_particles.global_position = pos
	
	# Scale based on velocity
	var velocity_normalized = clampf(velocity / max_landing_velocity, 0.0, 1.0)
	landing_particles.scale = Vector3.ONE * (0.5 + velocity_normalized * 1.5)
	
	# Play particles
	landing_particles.emitting = true
	
	landed.emit(pos, velocity)

## Public API
func set_min_velocity(vel: float) -> void:
	min_landing_velocity = vel

func set_max_velocity(vel: float) -> void:
	max_landing_velocity = vel

func set_particles(particles: GPUParticles3D) -> void:
	landing_particles = particles

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"min_landing_velocity": min_landing_velocity,
		"max_landing_velocity": max_landing_velocity,
		"emitting": landing_particles.emitting if landing_particles else false
	}
