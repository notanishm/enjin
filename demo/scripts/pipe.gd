## Pipe
## Warp pipe (decorative or functional)

extends StaticBody3D

@export var is_warp_pipe: bool = false
@export var warp_target: Vector3 = Vector3.ZERO
@export var pipe_height: float = 2.0

@onready var sprite: Sprite3D = $Sprite3D

func _ready() -> void:
	# Setup collision shape based on height
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.0, pipe_height, 1.0)
	$CollisionShape3D.shape = shape

func interact() -> void:
	if is_warp_pipe:
		# Warp player
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.global_position = warp_target
