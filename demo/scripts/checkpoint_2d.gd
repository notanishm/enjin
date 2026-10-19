extends Area2D

var activated := false

@onready var mesh: MeshInstance2D = $MeshInstance2D

signal checkpoint_reached(pos: Vector2)

func _on_body_entered(body: Node2D) -> void:
	if activated:
		return
	if body.is_in_group("player"):
		activated = true
		mesh.modulate = Color(0, 1, 0)
		checkpoint_reached.emit(global_position)
