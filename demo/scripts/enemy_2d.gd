extends CharacterBody2D

@export var speed: float = 25.0
@export var gravity: float = 700.0

var direction := -1.0
var is_defeated := false

@onready var mesh: MeshInstance2D = $MeshInstance2D
@onready var floor_check: RayCast2D = $FloorCheck
@onready var wall_check: RayCast2D = $WallCheck

func _ready() -> void:
	add_to_group("enemy")

func _physics_process(delta: float) -> void:
	if is_defeated:
		return

	velocity.y += gravity * delta

	velocity.x = direction * speed

	if is_on_floor():
		if floor_check and not floor_check.is_colliding():
			direction *= -1
			floor_check.position.x *= -1
			if wall_check:
				wall_check.position.x *= -1

	if wall_check and wall_check.is_colliding():
		direction *= -1
		floor_check.position.x *= -1
		wall_check.position.x *= -1

	move_and_slide()

	mesh.scale.x = 1 if direction < 0 else -1

func defeated() -> void:
	is_defeated = true
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0

	var tween = create_tween()
	tween.tween_property(mesh, "scale:y", 0.1, 0.2)
	tween.tween_callback(queue_free)
