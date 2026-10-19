extends CharacterBody2D

const SPEED = 90.0
const SPRINT_SPEED = 125.0
const JUMP_VELOCITY = -245.0
const GRAVITY = 700.0

var is_dead := false
var facing_right := true
var can_move := true

@onready var mesh: MeshInstance2D = $MeshInstance2D
@onready var collision: CollisionShape2D = $CollisionShape2D

signal hit_block(block: Node2D)
signal coin_collected
signal enemy_stomped(enemy: Node2D)
signal player_died
signal player_hit

func _physics_process(delta: float) -> void:
	if is_dead or not can_move:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var speed = SPRINT_SPEED if Input.is_action_pressed("run") else SPEED
	var direction := Input.get_axis("move_left", "move_right")

	if direction:
		velocity.x = direction * speed
		facing_right = direction > 0
		mesh.scale.x = 1 if facing_right else -1
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

	for i in range(get_slide_collision_count()):
		var collision_data = get_slide_collision(i)
		var collider = collision_data.get_collider()

		if collider.is_in_group("enemy"):
			if velocity.y > 0 and global_position.y < collider.global_position.y:
				stomp_enemy(collider)
			else:
				take_damage()

func stomp_enemy(enemy: Node2D) -> void:
	velocity.y = JUMP_VELOCITY * 0.6
	enemy_stomped.emit(enemy)
	enemy.defeated()

func take_damage() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	player_died.emit()

func respawn(pos: Vector2) -> void:
	global_position = pos
	is_dead = false
	velocity = Vector2.ZERO

func disable_input() -> void:
	can_move = false
	velocity = Vector2.ZERO

func enable_input() -> void:
	can_move = true
