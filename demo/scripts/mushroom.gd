## Mushroom Power-up
## Makes Mario grow bigger

extends CharacterBody3D

@export var move_speed: float = 3.0
@export var rise_speed: float = 2.0

var is_rising: bool = true
var direction: float = 1.0

@onready var sprite: Sprite3D = $Sprite3D

signal collected

func _ready() -> void:
	add_to_group("powerup")

func _physics_process(delta: float) -> void:
	# Rise from block
	if is_rising:
		velocity.y = -rise_speed
		if position.y <= -1.0:
			is_rising = false
	else:
		# Apply gravity
		if not is_on_floor():
			velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
		
		# Move
		velocity.x = direction * move_speed
	
	move_and_slide()
	
	# Turn at walls
	if is_on_wall():
		direction *= -1
		sprite.flip_h = direction < 0

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.collect_power_up("mushroom")
		collected.emit()
		queue_free()
