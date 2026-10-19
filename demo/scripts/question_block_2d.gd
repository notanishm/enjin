extends StaticBody2D

enum ContentType { COIN, MUSHROOM, STAR }

@export var content: ContentType = ContentType.COIN
@export var used := false

var bump_tween: Tween

@onready var mesh: MeshInstance2D = $MeshInstance2D

signal reward_spawned(type: String, pos: Vector2)
signal coin_collected

func hit() -> void:
	if used:
		return

	used = true
	mesh.modulate = Color(0.5, 0.35, 0.1)

	if bump_tween and bump_tween.is_valid():
		bump_tween.kill()

	bump_tween = create_tween()
	bump_tween.tween_property(mesh, "position:y", -8.0, 0.05)
	bump_tween.tween_property(mesh, "position:y", 0.0, 0.05)

	match content:
		ContentType.COIN:
			coin_collected.emit()
			reward_spawned.emit("coin", global_position + Vector2(0, -32))
		ContentType.MUSHROOM:
			reward_spawned.emit("mushroom", global_position + Vector2(0, -16))
		ContentType.STAR:
			reward_spawned.emit("star", global_position + Vector2(0, -16))
