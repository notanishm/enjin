extends Area2D

var collected := false

@onready var mesh: MeshInstance2D = $MeshInstance2D

func _process(delta: float) -> void:
	if not collected:
		mesh.position.y += sin(Time.get_ticks_msec() * 0.005) * 0.1

func _on_body_entered(body: Node2D) -> void:
	if collected:
		return
	if body.is_in_group("player"):
		collected = true
		body.coin_collected.emit()
		var tween = create_tween()
		tween.tween_property(mesh, "position:y", mesh.position.y - 24, 0.2)
		tween.parallel().tween_property(mesh, "modulate:a", 0.0, 0.2)
		tween.tween_callback(queue_free)
