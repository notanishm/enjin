## Trail Effect
## Creates trailing visual effects
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name TrailEffect
extends Node3D

## Export Variables
@export_group("Trail Settings")
@export var trail_length: float = 1.0
@export var trail_width: float = 0.1
@export var trail_lifetime: float = 0.5
@export var trail_segments: int = 10

@export_group("Appearance")
@export var color: Color = Color.WHITE
@export var gradient: Gradient
@export var texture: Texture2D

@export_group("Behavior")
@export var follow_speed: float = 10.0
@export var min_velocity: float = 0.1
@export var fade_out: bool = true

## State Variables
var trail_points: Array[Vector3] = []
var trail_times: Array[float] = []
var is_active: bool = false
var last_position: Vector3 = Vector3.ZERO

## Node Reference
var mesh_instance: MeshInstance3D
var immediate_mesh: ImmediateMesh

func _ready() -> void:
	_setup_mesh()

func _setup_mesh() -> void:
	immediate_mesh = ImmediateMesh.new()
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = immediate_mesh
	add_child(mesh_instance)

func _physics_process(delta: float) -> void:
	if is_active:
		_update_trail(delta)

## Update trail
func _update_trail(delta: float) -> void:
	# Add new point
	var current_pos = global_position
	if current_pos.distance_to(last_position) > min_velocity * delta:
		trail_points.append(current_pos)
		trail_times.append(Time.get_ticks_msec() / 1000.0)
		last_position = current_pos
	
	# Remove old points
	var current_time = Time.get_ticks_msec() / 1000.0
	while trail_times.size() > 0 and current_time - trail_times[0] > trail_lifetime:
		trail_points.remove_at(0)
		trail_times.remove_at(0)
	
	# Draw trail
	_draw_trail()

## Draw trail mesh
func _draw_trail() -> void:
	if trail_points.size() < 2:
		return
	
	immediate_mesh.clear_surfaces()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	for i in range(trail_points.size()):
		var point = trail_points[i]
		var progress = float(i) / float(trail_points.size() - 1)
		
		# Calculate width based on gradient or progress
		var width = trail_width
		if gradient:
			width *= gradient.sample(progress).a
		
		# Add vertices for strip
		var offset = Vector3(width, 0, 0)
		immediate_mesh.surface_add_vertex(point + offset)
		immediate_mesh.surface_add_vertex(point - offset)
	
	immediate_mesh.surface_end()

## Public API
func start() -> void:
	is_active = true
	trail_points.clear()
	trail_times.clear()

func stop() -> void:
	is_active = false

func set_color(new_color: Color) -> void:
	color = new_color

func set_width(width: float) -> void:
	trail_width = width

func set_length(length: float) -> void:
	trail_length = length

func set_lifetime(lifetime: float) -> void:
	trail_lifetime = lifetime

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"is_active": is_active,
		"trail_points_count": trail_points.size(),
		"trail_length": trail_length,
		"trail_width": trail_width
	}
