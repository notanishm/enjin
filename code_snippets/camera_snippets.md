# Camera System Snippets

## Source: Jeh3no/Godot-Third-Person-Controller (MIT)
## Reference: ramokz/phantom-camera (MIT)
## Adapted for capability reuse

---

## 1. Third Person Camera with SpringArm

```gdscript
## Source: Jeh3no/Godot-Third-Person-Controller
## Original: Camera system with orbit and collision
## Adapted: Standalone camera component

extends Node3D

@export var follow_distance: float = 5.0
@export var follow_height: float = 2.0
@export var follow_smoothing: float = 10.0
@export var rotation_speed: float = 0.002
@export var min_pitch: float = -80.0
@export var max_pitch: float = 80.0

var camera: Camera3D
var spring_arm: SpringArm3D
var follow_target: Node3D
var current_yaw: float = 0.0
var current_pitch: float = 45.0

func _ready() -> void:
	spring_arm = SpringArm3D.new()
	spring_arm.spring_length = follow_distance
	spring_arm.position = Vector3(0, follow_height, 0)
	add_child(spring_arm)
	
	camera = Camera3D.new()
	camera.position = Vector3(0, 0, follow_distance)
	spring_arm.add_child(camera)

func _physics_process(delta: float) -> void:
	if follow_target:
		_follow_target(delta)
	_handle_rotation()

func _follow_target(delta: float) -> void:
	var target = follow_target.global_position
	target.y += follow_height
	global_position = global_position.lerp(target, follow_smoothing * delta)

func _handle_rotation() -> void:
	var mouse_x = Input.get_action_raw_strength("camera_rotate_x")
	var mouse_y = Input.get_action_raw_strength("camera_rotate_y")
	
	current_yaw -= mouse_x * rotation_speed
	current_pitch -= mouse_y * rotation_speed
	current_pitch = clamp(current_pitch, min_pitch, max_pitch)
	
	rotation.y = current_yaw
	spring_arm.rotation.x = deg_to_rad(-current_pitch)
```

---

## 2. Camera Collision Handling

```gdscript
## Source: Jeh3no/Godot-Third-Person-Controller
## Original: Camera collision with raycast
## Adapted: Collision detection helper

func check_camera_collision() -> void:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position,
		follow_target.global_position,
		1  # collision mask
	)
	
	var result = space_state.intersect_ray(query)
	if result:
		# Adjust spring arm length to avoid clipping
		var distance = global_position.distance_to(result.position)
		spring_arm.spring_length = min(follow_distance, distance - 0.5)
	else:
		spring_arm.spring_length = follow_distance
```

---

## 3. Camera Zoom

```gdscript
## Source: Jeh3no/Godot-Third-Person-Controller
## Original: Camera zoom system
## Adapted: Zoom component

@export var zoom_speed: float = 0.5
@export var min_zoom: float = 2.0
@export var max_zoom: float = 10.0

var current_zoom: float = 5.0

func handle_zoom() -> void:
	var zoom_in = Input.is_action_just_pressed("camera_zoom_in")
	var zoom_out = Input.is_action_just_pressed("camera_zoom_out")
	
	if zoom_in:
		current_zoom = max(min_zoom, current_zoom - zoom_speed)
	elif zoom_out:
		current_zoom = min(max_zoom, current_zoom + zoom_speed)
	
	spring_arm.spring_length = current_zoom
```

---

## 4. First Person Camera

```gdscript
## Source: Simplified from common patterns
## Adapted: FPS camera with mouse look

extends Node3D

@export var mouse_sensitivity: float = 0.002
@export var vertical_limit: float = 89.0

var camera: Camera3D
var rotation_x: float = 0.0
var rotation_y: float = 0.0

func _ready() -> void:
	camera = Camera3D.new()
	add_child(camera)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation_y -= event.relative.x * mouse_sensitivity
		rotation_x -= event.relative.y * mouse_sensitivity
		rotation_x = clamp(rotation_x, deg_to_rad(-vertical_limit), deg_to_rad(vertical_limit))
		
		rotation.y = rotation_y
		rotation.x = rotation_x
```

---

## 5. Orbit Camera

```gdscript
## Source: Simplified from common patterns
## Adapted: Camera that orbits around target

extends Node3D

@export var orbit_distance: float = 5.0
@export var orbit_height: float = 2.0
@export var orbit_speed: float = 0.5

var camera: Camera3D
var follow_target: Node3D
var current_angle: float = 0.0

func _ready() -> void:
	camera = Camera3D.new()
	add_child(camera)

func _physics_process(delta: float) -> void:
	if follow_target:
		global_position = follow_target.global_position
	
	current_angle += orbit_speed * delta
	
	var offset = Vector3(
		sin(current_angle) * orbit_distance,
		orbit_height,
		cos(current_angle) * orbit_distance
	)
	
	camera.position = offset
	camera.look_at(Vector3.ZERO, Vector3.UP)
```
