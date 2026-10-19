## Question Block
## Block that contains items

extends StaticBody3D

enum ContentType { COIN, MUSHROOM, STAR, FIRE_FLOWER }

@export var content: ContentType = ContentType.COIN
@export var coins_to_give: int = 1

var is_used: bool = false
var hit_animation: float = 0.0

@onready var sprite: Sprite3D = $Sprite3D

signal item_spawned(item_type: String)
signal coin_collected

func hit(from_below: bool = true) -> void:
	if is_used:
		return
	
	is_used = true
	hit_animation = 0.2
	
	match content:
		ContentType.COIN:
			_give_coins()
		ContentType.MUSHROOM:
			_spawn_mushroom()
		ContentType.STAR:
			_spawn_star()
		ContentType.FIRE_FLOWER:
			_spawn_fire_flower()
	
	# Change to empty block sprite
	sprite.modulate = Color(0.5, 0.35, 0.1)

func _give_coins() -> void:
	for i in range(coins_to_give):
		coin_collected.emit()
		item_spawned.emit("coin")

func _spawn_mushroom() -> void:
	item_spawned.emit("mushroom")

func _spawn_star() -> void:
	item_spawned.emit("star")

func _spawn_fire_flower() -> void:
	item_spawned.emit("fire_flower")

func _process(delta: float) -> void:
	if hit_animation > 0:
		hit_animation -= delta
		sprite.position.y = sin(hit_animation * 20) * 0.1
	else:
		sprite.position.y = 0
	
	# Animate unused block
	if not is_used:
		sprite.position.y += sin(Time.get_ticks_msec() * 0.003) * 0.02
