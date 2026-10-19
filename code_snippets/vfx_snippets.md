# VFX System Snippets

## Source: Simplified from common Godot patterns
## Adapted for capability reuse

---

## 1. Trail Effect

```gdscript
## Source: Simplified from common patterns
## Adapted: Trail mesh effect

extends Node3D

@export var trail_length: float = 1.0
@export var trail_width: float = 0.1
@export var trail_lifetime: float = 0.5

var trail_points: Array[Vector3] = []
var trail_times: Array[float] = []
var is_active: bool = false

func _physics_process(delta: float) -> void:
	if is_active:
		_add_point()
		_remove_old_points()
		_draw_trail()

func _add_point() -> void:
	trail_points.append(global_position)
	trail_times.append(Time.get_ticks_msec() / 1000.0)

func _remove_old_points() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	while trail_times.size() > 0 and current_time - trail_times[0] > trail_lifetime:
		trail_points.remove_at(0)
		trail_times.remove_at(0)

func _draw_trail() -> void:
	# Draw using ImmediateMesh or MeshInstance3D
	pass

func start() -> void:
	is_active = true
	trail_points.clear()

func stop() -> void:
	is_active = false
```

---

## 2. Dust Effect

```gdscript
## Source: Simplified from common patterns
## Adapted: Dust particles

extends GPUParticles3D

@export var dust_amount: int = 20
@export var dust_lifetime: float = 0.5

func _ready() -> void:
	amount = dust_amount
	lifetime = dust_lifetime
	emitting = false

func emit_dust(pos: Vector3) -> void:
	global_position = pos
	emitting = true
```

---

## 3. Impact VFX

```gdscript
## Source: Simplified from common patterns
## Adapted: Impact particles

extends Node

@export var min_impact_velocity: float = 2.0
var impact_particles: GPUParticles3D

func _ready() -> void:
	impact_particles = GPUParticles3D.new()
	impact_particles.emitting = false
	impact_particles.one_shot = true
	add_child(impact_particles)

func on_collision(collision: KinematicCollision3D) -> void:
	var velocity = collision.get_travel().length()
	if velocity < min_impact_velocity:
		return
	
	impact_particles.global_position = collision.get_position()
	impact_particles.emitting = true
```

---

## 4. Landing VFX

```gdscript
## Source: Simplified from common patterns
## Adapted: Landing particles

extends Node

@export var min_landing_velocity: float = 2.0
var landing_particles: GPUParticles3D

func _ready() -> void:
	landing_particles = GPUParticles3D.new()
	landing_particles.emitting = false
	landing_particles.one_shot = true
	add_child(landing_particles)

func on_landed(velocity: float) -> void:
	if velocity < min_landing_velocity:
		return
	
	landing_particles.global_position = get_parent().global_position
	landing_particles.emitting = true
```
