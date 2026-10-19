## Game Manager
## Handles score, lives, time, and level state

extends Node

## Export Variables
@export_group("Game Settings")
@export var start_lives: int = 3
@export var level_time: int = 400
@export var time_warning: int = 100

## State Variables
var score: int = 0
var coins: int = 0
var lives: int = 3
var time_remaining: int = 400
var is_game_over: bool = false
var is_level_complete: bool = false

## Node References
@onready var player: CharacterBody3D = get_parent().get_node("Player")
@onready var score_label: Label = get_parent().get_node("UI/ScoreValue")
@onready var coins_label: Label = get_parent().get_node("UI/CoinsValue")
@onready var lives_label: Label = get_parent().get_node("UI/LivesValue")
@onready var time_label: Label = get_parent().get_node("UI/TimeValue")
@onready var timer: Timer = $Timer

## Signals
signal score_changed(new_score: int)
signal coins_changed(new_coins: int)
signal lives_changed(new_lives: int)
signal time_changed(new_time: int)
signal game_over
signal level_complete

func _ready() -> void:
	lives = start_lives
	time_remaining = level_time
	_update_ui()
	
	if player:
		player.coin_collected.connect(_on_coin_collected)
		player.stomped.connect(_on_enemy_stomped)
	
	if timer:
		timer.timeout.connect(_on_timer_tick)
		timer.start()

func _on_coin_collected() -> void:
	coins += 1
	score += 200
	
	if coins >= 100:
		coins -= 100
		lives += 1
		lives_changed.emit(lives)
	
	coins_changed.emit(coins)
	score_changed.emit(score)
	_update_ui()

func _on_enemy_stomped(_enemy: Node3D) -> void:
	score += 100
	score_changed.emit(score)
	_update_ui()

func _on_timer_tick() -> void:
	time_remaining -= 1
	time_changed.emit(time_remaining)
	_update_ui()
	
	if time_remaining <= 0:
		_player_die()

func _player_die() -> void:
	lives -= 1
	lives_changed.emit(lives)
	
	if lives <= 0:
		is_game_over = true
		game_over.emit()
	else:
		time_remaining = level_time
		_update_ui()

func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)
	_update_ui()

func _update_ui() -> void:
	if score_label:
		score_label.text = "%06d" % score
	if coins_label:
		coins_label.text = "x%02d" % coins
	if lives_label:
		lives_label.text = "x%d" % lives
	if time_label:
		time_label.text = "%d" % time_remaining
