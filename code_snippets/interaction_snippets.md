# Interaction System Snippets

## Source: Simplified from common Godot patterns
## Adapted for capability reuse

---

## 1. Raycast Interactor

```gdscript
## Source: Simplified from common patterns
## Adapted: Raycast-based interaction

extends Node3D

@export var ray_length: float = 10.0
@export var interaction_action: String = "interact"

var current_target: Node3D = null
var camera: Camera3D

func _ready() -> void:
	camera = get_viewport().get_camera_3d()

func _physics_process(delta: float) -> void:
	_update_raycast()
	_check_input()

func _update_raycast() -> void:
	if not camera:
		return
	
	var ray_origin = camera.global_position
	var ray_end = ray_origin + (-camera.global_basis.z * ray_length)
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result = space_state.intersect_ray(query)
	
	if result:
		var new_target = result.collider as Node3D
		if new_target != current_target:
			current_target = new_target
	else:
		current_target = null

func _check_input() -> void:
	if Input.is_action_just_pressed(interaction_action):
		if current_target and current_target.has_method("on_interact"):
			current_target.on_interact()
```

---

## 2. Interactable Object

```gdscript
## Source: Simplified from common patterns
## Adapted: Interactable component

extends Node3D

@export var interactable_name: String = "Object"
@export var interaction_prompt: String = "Press E to interact"
@export var enabled: bool = true

var is_hovered: bool = false

func on_interact() -> void:
	if not enabled:
		return
	_on_interact()

func on_interact_hover() -> void:
	if not enabled:
		return
	is_hovered = true
	_apply_highlight(true)

func on_interact_exit() -> void:
	is_hovered = false
	_apply_highlight(false)

func _on_interact() -> void:
	pass  # Override in subclasses

func _apply_highlight(show_highlight: bool) -> void:
	for child in get_children():
		if child is MeshInstance3D:
			if show_highlight:
				var mat = StandardMaterial3D.new()
				mat.albedo_color = Color.YELLOW
				mat.emission_enabled = true
				child.material_override = mat
			else:
				child.material_override = null
```

---

## 3. Proximity Detector

```gdscript
## Source: Simplified from common patterns
## Adapted: Area-based detection

extends Area3D

@export var detection_radius: float = 3.0
@export var target_groups: Array[String] = []

var detected_objects: Array[Node3D] = []
var closest_object: Node3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if _should_detect(body) and body not in detected_objects:
		detected_objects.append(body)
		_update_closest()

func _on_body_exited(body: Node3D) -> void:
	detected_objects.erase(body)
	_update_closest()

func _should_detect(body: Node3D) -> bool:
	if target_groups.is_empty():
		return true
	for group in target_groups:
		if body.is_in_group(group):
			return true
	return false

func _update_closest() -> void:
	closest_object = null
	var closest_distance = INF
	for obj in detected_objects:
		if is_instance_valid(obj):
			var dist = global_position.distance_to(obj.global_position)
			if dist < closest_distance:
				closest_distance = dist
				closest_object = obj
```
