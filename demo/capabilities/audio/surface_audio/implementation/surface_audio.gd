## Surface Audio
## Plays different sounds based on surface material
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name SurfaceAudio
extends Node

## Export Variables
@export_group("Surface Settings")
@export var volume_db: float = -10.0
@export var pitch_variation: float = 0.1

## Surface Sounds Dictionary
var surface_sounds: Dictionary = {}

## Node Reference
var audio_player: AudioStreamPlayer3D

## Signals
signal sound_played(surface: String, position: Vector3)

func _ready() -> void:
	_setup_audio_player()

func _setup_audio_player() -> void:
	audio_player = AudioStreamPlayer3D.new()
	audio_player.name = "SurfaceAudioPlayer"
	audio_player.volume_db = volume_db
	add_child(audio_player)

## Play sound for surface
func play_surface_sound(surface: String, position: Vector3 = Vector3.ZERO) -> void:
	if not surface_sounds.has(surface):
		return
	
	var sounds = surface_sounds[surface]
	if sounds.is_empty():
		return
	
	# Pick random sound
	var sound = sounds[randi() % sounds.size()]
	if not sound:
		return
	
	audio_player.global_position = position
	audio_player.stream = sound
	audio_player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	audio_player.play()
	
	sound_played.emit(surface, position)

## Add surface sounds
func add_surface(surface: String, sounds: Array[AudioStream]) -> void:
	surface_sounds[surface] = sounds

## Remove surface
func remove_surface(surface: String) -> void:
	surface_sounds.erase(surface)

## Get surfaces
func get_surfaces() -> Array[String]:
	return surface_sounds.keys()

## Public API
func set_volume(vol_db: float) -> void:
	volume_db = vol_db
	if audio_player:
		audio_player.volume_db = vol_db

func set_pitch_variation(variation: float) -> void:
	pitch_variation = variation

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"surfaces_count": surface_sounds.size(),
		"surfaces": surface_sounds.keys(),
		"volume_db": volume_db
	}
