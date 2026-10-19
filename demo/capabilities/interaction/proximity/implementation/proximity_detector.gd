## Proximity Detector
## Detects objects entering/exiting a detection area
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name ProximityDetector
extends Area3D

## Export Variables
@export_group("Detection Settings")
@export var detection_radius: float = 3.0
@export var detection_height: float = 2.0
@export var detection_shape: ShapeType = ShapeType.SPHERE
@export var collision_layer: int = 1
@export var collision_mask: int = 1

@export_group("Target Filtering")
@export var target_groups: Array[String] = []
@export var require_line_of_sight: bool = false
@export var ignore_owner: bool = true

## Shape Types
enum ShapeType {
	SPHERE,
	BOX,
	CAPSULE
}

## State Variables
var detected_objects: Array[Node3D] = []
var closest_object: Node3D = null
var is_active: bool = true

## Signals
signal object_entered(object: Node3D)
signal object_exited(object: Node3D)
signal detection_updated(objects: Array[Node3D])
signal closest_changed(object: Node3D)

func _ready() -> void:
	_setup_detection_area()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _setup_detection_area() -> void:
	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	
	match detection_shape:
		ShapeType.SPHERE:
			var shape = SphereShape3D.new()
			shape.radius = detection_radius
			collision_shape.shape = shape
		ShapeType.BOX:
			var shape = BoxShape3D.new()
			shape.size = Vector3(detection_radius * 2, detection_height, detection_radius * 2)
			collision_shape.shape = shape
		ShapeType.CAPSULE:
			var shape = CapsuleShape3D.new()
			shape.radius = detection_radius
			shape.height = detection_height
			collision_shape.shape = shape
	
	add_child(collision_shape)

func _physics_process(delta: float) -> void:
	if is_active:
		_update_detection()

## Update detection
func _update_detection() -> void:
	# Find closest object
	var new_closest = _find_closest_object()
	
	if new_closest != closest_object:
		closest_object = new_closest
		closest_changed.emit(closest_object)
	
	# Emit update signal
	detection_updated.emit(detected_objects)

## Find closest object
func _find_closest_object() -> Node3D:
	if detected_objects.is_empty():
		return null
	
	var closest = null
	var closest_distance = INF
	
	for obj in detected_objects:
		if not is_instance_valid(obj):
			continue
		
		var distance = global_position.distance_to(obj.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = obj
	
	return closest

## Body entered detection area
func _on_body_entered(body: Node3D) -> void:
	# Check if body should be detected
	if not _should_detect(body):
		return
	
	# Check line of sight if required
	if require_line_of_sight and not _has_line_of_sight(body):
		return
	
	if body not in detected_objects:
		detected_objects.append(body)
		object_entered.emit(body)

## Body exited detection area
func _on_body_exited(body: Node3D) -> void:
	if body in detected_objects:
		detected_objects.erase(body)
		object_exited.emit(body)

## Check if object should be detected
func _should_detect(body: Node3D) -> bool:
	# Ignore owner
	if ignore_owner and body == get_owner():
		return false
	
	# Check groups
	if not target_groups.is_empty():
		for group in target_groups:
			if body.is_in_group(group):
				return true
		return false
	
	return true

## Check line of sight
func _has_line_of_sight(target: Node3D) -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position,
		target.global_position,
		collision_mask
	)
	var result = space_state.intersect_ray(query)
	
	# If we hit something, check if it's the target
	if result:
		return result.collider == target
	return true

## Public API
func set_detection_radius(radius: float) -> void:
	detection_radius = radius
	# Rebuild collision shape
	_rebuild_shape()

func set_detection_height(height: float) -> void:
	detection_height = height
	_rebuild_shape()

func set_detection_shape(shape: ShapeType) -> void:
	detection_shape = shape
	_rebuild_shape()

func _rebuild_shape() -> void:
	# Remove existing shape
	for child in get_children():
		if child is CollisionShape3D:
			child.queue_free()
	
	# Create new shape
	_setup_detection_area()

func set_active(active: bool) -> void:
	is_active = active
	monitoring = active
	monitorable = active

func get_detected_objects() -> Array[Node3D]:
	return detected_objects

func get_closest_object() -> Node3D:
	return closest_object

func has_detected_objects() -> bool:
	return not detected_objects.is_empty()

func is_object_detected(obj: Node3D) -> bool:
	return obj in detected_objects

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"detection_radius": detection_radius,
		"is_active": is_active,
		"detected_count": detected_objects.size(),
		"closest_object": closest_object.name if closest_object else "None",
		"detected_objects": detected_objects.map(func(o): return o.name if is_instance_valid(o) else "Invalid")
	}
