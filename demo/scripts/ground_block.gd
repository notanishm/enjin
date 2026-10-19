## Ground Block
## Standard ground tile

extends StaticBody3D

@export var block_size: float = 1.0

@onready var sprite: Sprite3D = $Sprite3D

func _ready() -> void:
	# Setup collision
	var shape = BoxShape3D.new()
	shape.size = Vector3(block_size, block_size, block_size)
	$CollisionShape3D.shape = shape
