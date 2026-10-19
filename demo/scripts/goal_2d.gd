extends Area2D

var reached := false

signal level_completed

func _on_body_entered(body: Node2D) -> void:
	if reached:
		return
	if body.is_in_group("player"):
		reached = true
		body.disable_input()
		level_completed.emit()
