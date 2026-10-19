## Impact VFX
## Creates visual effects on collision impacts
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name ImpactVFX
extends Node

## Export Variables
@export_group("Impact Settings")
@export var min_impact_velocity: float = 2.0
@export var max_impact_velocity: float = 20.0

## Impact Particles
var impact_particles: GPUParticles3D

## Node Reference
var parent: Node3D

## Signals
signal impact_played(position: Vector3, velocity: float)

func _ready() -> void:
	parent = get_parent() as Node3D
	_setup_particles()

func _setup_particles() -> void:
	impact_particles = GPUParticles3D.new()
	impact_particles.name = "ImpactParticles"
	impact_particles.emitting = false
	impact_particles.one_shot = true
	impact_particles.explosiveness = 1.0
	add_child(impact_particles)

## Handle collision
func on_collision(collision: KinematicCollision3D) -> void:
	var velocity = collision.get_travel().length()
	
	if velocity < min_impact_velocity:
		return
	
	var position = collision.get_position()
	var normal = collision.get_normal()
	
	_play_impact(position, normal, velocity)

## Play impact effect
func _play_impact(pos: Vector3, normal: Vector3, velocity: float) -> void:
	# Position and orient particles
	impact_particles.global_position = pos
	impact_particles.rotation = normal
	
	# Scale based on velocity
	var velocity_normalized = clampf(velocity / max_impact_velocity, 0.0, 1.0)
	impact_particles.scale = Vector3.ONE * (0.5 + velocity_normalized * 1.5)
	
	# Play particles
	impact_particles.emitting = true
	
	impact_played.emit(pos, velocity)

## Public API
func set_min_velocity(vel: float) -> void:
	min_impact_velocity = vel

func set_max_velocity(vel: float) -> void:
	max_impact_velocity = vel

func set_particles(particles: GPUParticles3D) -> void:
	impact_particles = particles

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"min_impact_velocity": min_impact_velocity,
		"max_impact_velocity": max_impact_velocity,
		"emitting": impact_particles.emitting if impact_particles else false
	}
