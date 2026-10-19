extends Node

var score: int = 0
var coins: int = 0
var lives: int = 3
var time: int = 400
var current_section: int = 0
var checkpoint_position: Vector2 = Vector2(48, 176)

@onready var player: CharacterBody2D = get_parent().get_node("Player")
@onready var timer: Timer = $Timer

func _ready() -> void:
	if timer:
		timer.timeout.connect(_on_timer_tick)
		timer.start()

func _on_timer_tick() -> void:
	time -= 1
	if time <= 0:
		player_died()

func add_coin() -> void:
	coins += 1
	score += 200
	if coins >= 100:
		coins -= 100
		lives += 1

func add_score(points: int) -> void:
	score += points

func enemy_defeated() -> void:
	score += 100

func set_checkpoint(pos: Vector2) -> void:
	checkpoint_position = pos

func player_died() -> void:
	lives -= 1
	if lives <= 0:
		game_over()
	else:
		time = 400
		player.respawn(checkpoint_position)

func game_over() -> void:
	get_tree().reload_current_scene()

func complete_level() -> void:
	score += time * 50
