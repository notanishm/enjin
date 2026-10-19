## Goomba Enemy
## Basic enemy that walks and can be stomped

extends CharacterBody3D

@export var move_speed: float = 2.0
@export var health: int = 1
@export var stomp_points: int = 100

var is_alive: bool = true
var direction: float = -1.0

@onready var mesh: MeshInstance3D = $Mesh

signal died(points: int)
signal stomped

func _ready() -> void:
	add_to_group("enemy")

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
	velocity.x = direction * move_speed
	
	move_and_slide()
	
	if is_on_wall():
		direction *= -1
		if mesh:
			mesh.scale.x = direction

func take_damage(_amount: int = 1) -> void:
	health -= _amount
	if health <= 0:
		_die()

func _die() -> void:
	is_alive = false
	died.emit(stomp_points)
	stomped.emit()
	
	velocity = Vector3.ZERO
	$CollisionShape3D.set_deferred("disabled", true)
	
	if mesh:
		mesh.rotation.x = PI
	
	velocity.y = 5.0
	
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.velocity.y < 0 and body.global_position.y > global_position.y:
			take_damage(1)
		else:
			body.take_damage()
