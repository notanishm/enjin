## Footstep Player
## Plays footstep sounds based on surface type
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name FootstepPlayer
extends Node

## Export Variables
@export_group("Footstep Settings")
@export var min_interval: float = 0.3
@export var max_interval: float = 0.5
@export var volume_db: float = -10.0
@export var pitch_variation: float = 0.1

@export_group("Surface Sounds")
@export var default_surface: String = "concrete"
@export var surface_sounds: Dictionary = {}

## State Variables
var last_footstep_time: float = 0.0
var next_interval: float = 0.4
var current_surface: String = "concrete"
var is_walking: bool = false

## Node Reference
var audio_player: AudioStreamPlayer3D

## Signals
signal footstep_played(surface: String, position: Vector3)

func _ready() -> void:
	_setup_audio_player()
	_randomize_interval()

func _setup_audio_player() -> void:
	audio_player = AudioStreamPlayer3D.new()
	audio_player.name = "FootstepPlayer"
	audio_player.volume_db = volume_db
	add_child(audio_player)

func _physics_process(delta: float) -> void:
	if is_walking:
		_check_footstep()

## Check if we should play a footstep
func _check_footstep() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if current_time - last_footstep_time >= next_interval:
		_play_footstep()
		last_footstep_time = current_time
		_randomize_interval()

## Play footstep sound
func _play_footstep() -> void:
	if not surface_sounds.has(current_surface):
		return
	
	var sounds = surface_sounds[current_surface]
	if sounds.is_empty():
		return
	
	# Pick random sound
	var sound = sounds[randi() % sounds.size()]
	
	if sound:
		audio_player.stream = sound
		audio_player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
		audio_player.play()
		
		footstep_played.emit(current_surface, audio_player.global_position)

## Randomize interval
func _randomize_interval() -> void:
	next_interval = randf_range(min_interval, max_interval)

## Public API
func start_walking() -> void:
	is_walking = true
	_randomize_interval()

func stop_walking() -> void:
	is_walking = false

func set_surface(surface: String) -> void:
	current_surface = surface

func set_volume(vol_db: float) -> void:
	volume_db = vol_db
	if audio_player:
		audio_player.volume_db = vol_db

func add_surface_sound(surface: String, sounds: Array[AudioStream]) -> void:
	surface_sounds[surface] = sounds

func get_current_surface() -> String:
	return current_surface

func is_playing() -> bool:
	return is_walking

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"is_walking": is_walking,
		"current_surface": current_surface,
		"next_interval": next_interval,
		"surfaces_count": surface_sounds.size()
	}
