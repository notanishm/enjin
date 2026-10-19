## Dust Effect
## Creates dust particles on movement/landing
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name DustEffect
extends GPUParticles3D

## Export Variables
@export_group("Dust Settings")
@export var dust_amount: int = 20
@export var dust_lifetime: float = 0.5
@export var dust_spread: float = 45.0

@export_group("Emission")
@export var emission_shape: Shape = Shape.POINT
@export var emission_radius: float = 0.5

## Shape Types
enum Shape {
	POINT,
	SPHERE,
	BOX
}

func _ready() -> void:
	_setup_particles()

func _setup_particles() -> void:
	# Configure particles
	amount = dust_amount
	lifetime = dust_lifetime
	explosiveness = 1.0
	randomness = 0.5
	
	# Set process material
	var process_material = ParticleProcessMaterial.new()
	
	# Emission shape
	match emission_shape:
		Shape.POINT:
			process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
		Shape.SPHERE:
			process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			process_material.emission_sphere_radius = emission_radius
		Shape.BOX:
			process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			process_material.emission_box_extents = Vector3(emission_radius, 0.1, emission_radius)
	
	# Direction and spread
	process_material.direction = Vector3(0, 1, 0)
	process_material.spread = dust_spread
	process_material.initial_velocity_min = 1.0
	process_material.initial_velocity_max = 2.0
	
	# Gravity
	process_material.gravity = Vector3(0, -9.8, 0)
	
	# Scale
	process_material.scale_min = 0.5
	process_material.scale_max = 1.5
	
	# Color
	process_material.color = Color(0.8, 0.7, 0.6, 0.5)
	
	self.process_material = process_material

## Emit dust at position
func emit_dust(pos: Vector3) -> void:
	global_position = pos
	emitting = true

## Emit dust at position with normal
func emit_dust_with_normal(pos: Vector3, normal: Vector3) -> void:
	global_position = pos
	
	# Align emission direction with normal
	if process_material is ParticleProcessMaterial:
		process_material.direction = normal
	
	emitting = true

## Public API
func set_dust_amount(amount: int) -> void:
	dust_amount = amount
	self.amount = amount

func set_dust_lifetime(lifetime: float) -> void:
	dust_lifetime = lifetime
	self.lifetime = lifetime

func set_dust_color(c: Color) -> void:
	if process_material is ParticleProcessMaterial:
		process_material.color = c

func set_dust_spread(spread: float) -> void:
	dust_spread = spread
	if process_material is ParticleProcessMaterial:
		process_material.spread = spread

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"amount": dust_amount,
		"lifetime": dust_lifetime,
		"spread": dust_spread,
		"emitting": emitting
	}
