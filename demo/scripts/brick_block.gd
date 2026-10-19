## Brick Block
## Breakable brick block

extends StaticBody3D

@export var breaks_when_hit: bool = true
@export var requires_big_mario: bool = false

var is_hit: bool = false
var hit_animation: float = 0.0

@onready var sprite: Sprite3D = $Sprite3D
@onready var collision: CollisionShape3D = $CollisionShape3D

func hit(from_below: bool = true) -> void:
	if is_hit:
		return
	
	is_hit = true
	hit_animation = 0.2
	
	if breaks_when_hit and not requires_big_mario:
		_break_block()
	else:
		_bump_block()

func _break_block() -> void:
	# Spawn break particles
	# Remove block
	queue_free()

func _bump_block() -> void:
	# Bump animation
	pass

func _process(delta: float) -> void:
	if hit_animation > 0:
		hit_animation -= delta
		# Bump animation
		sprite.position.y = sin(hit_animation * 20) * 0.1
	else:
		sprite.position.y = 0
