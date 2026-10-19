## Mario Player Controller
## Uses capabilities from the corpus for platformer mechanics

extends CharacterBody3D

@export_group("Movement")
@export var walk_speed: float = 5.0
@export var run_speed: float = 8.0
@export var acceleration: float = 20.0
@export var deceleration: float = 30.0
@export var air_acceleration: float = 10.0

@export_group("Jump")
@export var jump_velocity: float = 12.0
@export var gravity_multiplier: float = 2.5
@export var max_fall_speed: float = 20.0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

@export_group("Stomp")
@export var stomp_bounce_velocity: float = 10.0
@export var stomp_damage: int = 1

var current_speed: float = 0.0
var is_running: bool = false
var is_jumping: bool = false
var was_on_floor: bool = false
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var facing_right: bool = true

@onready var model: Node3D = $Model
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

signal jumped
signal stomped(enemy: Node3D)
signal coin_collected
signal power_up_collected(power_up: String)

func _physics_process(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
		is_jumping = false
	else:
		coyote_timer -= delta
	
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta
	
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier * delta
		velocity.y = max(velocity.y, -max_fall_speed)
	
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = jump_velocity
		is_jumping = true
		coyote_timer = 0
		jump_buffer_timer = 0
		jumped.emit()
	
	if is_jumping and not Input.is_action_pressed("jump") and velocity.y > 0:
		velocity.y *= 0.5
	
	var input_dir = Input.get_axis("move_left", "move_right")
	
	is_running = Input.is_action_pressed("run")
	var target_speed = run_speed if is_running else walk_speed
	
	var accel = acceleration if is_on_floor() else air_acceleration
	if input_dir != 0:
		velocity.x = move_toward(velocity.x, input_dir * target_speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
	
	if input_dir > 0:
		facing_right = true
		if model:
			model.scale.x = abs(model.scale.x)
	elif input_dir < 0:
		facing_right = false
		if model:
			model.scale.x = -abs(model.scale.x)
	
	move_and_slide()
	
	_check_stomp()
	was_on_floor = is_on_floor()

func _check_stomp() -> void:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider.is_in_group("enemy"):
			if velocity.y < 0 and global_position.y > collider.global_position.y:
				collider.take_damage(stomp_damage)
				velocity.y = stomp_bounce_velocity
				stomped.emit(collider)

func take_damage() -> void:
	print("Mario hit!")

func collect_coin() -> void:
	coin_collected.emit()

func collect_power_up(_power_up: String) -> void:
	pass

func get_speed() -> float:
	return Vector3(velocity.x, 0, velocity.z).length()

func is_moving() -> bool:
	return abs(velocity.x) > 0.1

func respawn() -> void:
	velocity = Vector3.ZERO
