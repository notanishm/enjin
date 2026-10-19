## Impact Audio
## Plays sounds on collisions/impacts
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name ImpactAudio
extends Node

## Export Variables
@export_group("Impact Settings")
@export var min_impact_velocity: float = 2.0
@export var max_impact_velocity: float = 20.0
@export var volume_db: float = -5.0
@export var pitch_variation: float = 0.2

@export_group("Impact Sounds")
@export var impact_sounds: Array[AudioStream] = []
@export var surface_impacts: Dictionary = {}

## State Variables
var last_impact_time: float = 0.0
var impact_cooldown: float = 0.1

## Node Reference
var audio_player: AudioStreamPlayer3D

## Signals
signal impact_played(surface: String, velocity: float, position: Vector3)

func _ready() -> void:
	_setup_audio_player()

func _setup_audio_player() -> void:
	audio_player = AudioStreamPlayer3D.new()
	audio_player.name = "ImpactPlayer"
	audio_player.volume_db = volume_db
	add_child(audio_player)

## Handle collision
func on_collision(collision: KinematicCollision3D) -> void:
	var velocity = collision.get_travel().length()
	
	# Check cooldown
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_impact_time < impact_cooldown:
		return
	
	# Check minimum velocity
	if velocity < min_impact_velocity:
		return
	
	# Get surface from collision
	var surface = _get_surface(collision)
	
	# Play impact sound
	_play_impact(surface, velocity, collision.get_position())
	last_impact_time = current_time

## Get surface from collision
func _get_surface(collision: KinematicCollision3D) -> String:
	# Try to get surface from collider
	var collider = collision.get_collider()
	
	if collider and collider.has_method("get_surface_type"):
		return collider.get_surface_type()
	
	return "default"

## Play impact sound
func _play_impact(surface: String, velocity: float, position: Vector3) -> void:
	# Get appropriate sound
	var sound = _get_impact_sound(surface)
	
	if not sound:
		return
	
	# Calculate volume based on velocity
	var velocity_normalized = clampf(velocity / max_impact_velocity, 0.0, 1.0)
	var adjusted_volume = volume_db + (velocity_normalized * 10.0)
	
	# Play sound
	audio_player.global_position = position
	audio_player.stream = sound
	audio_player.volume_db = adjusted_volume
	audio_player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	audio_player.play()
	
	impact_played.emit(surface, velocity, position)

## Get impact sound for surface
func _get_impact_sound(surface: String) -> AudioStream:
	# Check surface-specific sounds
	if surface_impacts.has(surface):
		var sounds = surface_impacts[surface]
		if not sounds.is_empty():
			return sounds[randi() % sounds.size()]
	
	# Fall back to default sounds
	if not impact_sounds.is_empty():
		return impact_sounds[randi() % impact_sounds.size()]
	
	return null

## Public API
func set_volume(vol_db: float) -> void:
	volume_db = vol_db
	if audio_player:
		audio_player.volume_db = vol_db

func add_impact_sound(sound: AudioStream) -> void:
	impact_sounds.append(sound)

func add_surface_impact(surface: String, sounds: Array[AudioStream]) -> void:
	surface_impacts[surface] = sounds

func set_min_impact_velocity(vel: float) -> void:
	min_impact_velocity = vel

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"min_impact_velocity": min_impact_velocity,
		"impact_sounds_count": impact_sounds.size(),
		"surface_impacts_count": surface_impacts.size()
	}
