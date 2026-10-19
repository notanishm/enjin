## Ambient Audio
## Plays ambient background sounds
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name AmbientAudio
extends Node

## Export Variables
@export_group("Ambient Settings")
@export var fade_in_time: float = 1.0
@export var fade_out_time: float = 1.0
@export var volume_db: float = -15.0
@export var loop: bool = true

@export_group("Ambient Zones")
@export var ambient_zones: Dictionary = {}

## State Variables
var current_zone: String = ""
var target_volume: float = -15.0
var is_fading: bool = false
var fade_direction: int = 0  # 1 = fading in, -1 = fading out

## Node Reference
var audio_player: AudioStreamPlayer

## Signals
signal zone_changed(old_zone: String, new_zone: String)
signal fade_completed(faded_in: bool)

func _ready() -> void:
	_setup_audio_player()

func _setup_audio_player() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "AmbientPlayer"
	audio_player.volume_db = volume_db
	audio_player.bus = "Ambient"
	add_child(audio_player)

func _process(delta: float) -> void:
	if is_fading:
		_update_fade(delta)

## Update fade
func _update_fade(delta: float) -> void:
	var fade_amount = delta / (fade_in_time if fade_direction > 0 else fade_out_time)
	
	if fade_direction > 0:
		# Fading in
		audio_player.volume_db = min(audio_player.volume_db + (fade_amount * 40.0), target_volume)
		if audio_player.volume_db >= target_volume:
			is_fading = false
			fade_completed.emit(true)
	else:
		# Fading out
		audio_player.volume_db = max(audio_player.volume_db - (fade_amount * 40.0), -80.0)
		if audio_player.volume_db <= -80.0:
			audio_player.stop()
			is_fading = false
			fade_completed.emit(false)

## Change ambient zone
func change_zone(new_zone: String) -> void:
	if new_zone == current_zone:
		return
	
	var old_zone = current_zone
	current_zone = new_zone
	
	# Stop current ambient
	if audio_player.playing:
		_fade_out()
	
	# Start new ambient
	if ambient_zones.has(new_zone):
		var zone_data = ambient_zones[new_zone]
		_play_ambient(zone_data)
	
	zone_changed.emit(old_zone, new_zone)

## Play ambient sound
func _play_ambient(zone_data: Dictionary) -> void:
	if zone_data.has("stream"):
		audio_player.stream = zone_data["stream"]
		audio_player.volume_db = -80.0
		audio_player.play()
		_fade_in()

## Fade in
func _fade_in() -> void:
	target_volume = volume_db
	fade_direction = 1
	is_fading = true

## Fade out
func _fade_out() -> void:
	fade_direction = -1
	is_fading = true

## Public API
func set_volume(vol_db: float) -> void:
	volume_db = vol_db
	if audio_player and not is_fading:
		audio_player.volume_db = vol_db

func add_zone(zone_name: String, stream: AudioStream) -> void:
	ambient_zones[zone_name] = {"stream": stream}

func remove_zone(zone_name: String) -> void:
	ambient_zones.erase(zone_name)

func get_current_zone() -> String:
	return current_zone

func is_playing() -> bool:
	return audio_player.playing

func play() -> void:
	if ambient_zones.has(current_zone):
		_play_ambient(ambient_zones[current_zone])

func stop() -> void:
	_fade_out()

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"current_zone": current_zone,
		"volume_db": volume_db,
		"is_playing": audio_player.playing if audio_player else false,
		"is_fading": is_fading,
		"zones_count": ambient_zones.size()
	}
