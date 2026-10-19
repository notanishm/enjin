## Animation Events
## Triggers events during animation playback
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name AnimationEvents
extends Node

## Export Variables
@export_group("Settings")
@export var enabled: bool = true
@export var debug_mode: bool = false

## Event Class
class AnimEvent:
	var time: float
	var event_name: String
	var callback: Callable
	var one_shot: bool = false
	var triggered: bool = false
	
	func _init(t: float, name: String, cb: Callable, shot: bool = false) -> void:
		time = t
		event_name = name
		callback = cb
		one_shot = shot

## State Variables
var events: Array[AnimEvent] = []
var current_time: float = 0.0
var is_playing: bool = false

## Node Reference
var animation_player: AnimationPlayer

## Signals
signal event_triggered(event_name: String, time: float)

func _ready() -> void:
	# Find AnimationPlayer
	animation_player = _find_animation_player()
	
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)

func _find_animation_player() -> AnimationPlayer:
	# Check parent
	var parent = get_parent()
	if parent is AnimationPlayer:
		return parent
	
	# Check children
	for child in get_children():
		if child is AnimationPlayer:
			return child
	
	return null

func _physics_process(delta: float) -> void:
	if is_playing and animation_player:
		_update_time()
		_check_events()

## Update current time
func _update_time() -> void:
	if animation_player:
		current_time = animation_player.current_animation_position

## Check events
func _check_events() -> void:
	for event in events:
		if not event.triggered and current_time >= event.time:
			if event.one_shot:
				event.triggered = true
			
			if event.callback.is_valid():
				event.callback.call()
			
			event_triggered.emit(event.event_name, event.time)

## Add event
func add_event(time: float, event_name: String, callback: Callable, one_shot: bool = false) -> AnimEvent:
	var event = AnimEvent.new(time, event_name, callback, one_shot)
	events.append(event)
	return event

## Remove event
func remove_event(event_name: String) -> void:
	events = events.filter(func(e): return e.event_name != event_name)

## Clear all events
func clear_events() -> void:
	events.clear()

## Start playing
func start() -> void:
	is_playing = true
	_reset_triggered()

## Stop playing
func stop() -> void:
	is_playing = false

## Reset triggered flags
func _reset_triggered() -> void:
	for event in events:
		event.triggered = false

## Animation finished callback
func _on_animation_finished(anim_name: String) -> void:
	is_playing = false

## Get events
func get_events() -> Array[AnimEvent]:
	return events

## Get event by name
func get_event(event_name: String) -> AnimEvent:
	for event in events:
		if event.event_name == event_name:
			return event
	return null

## Check if event exists
func has_event(event_name: String) -> bool:
	return get_event(event_name) != null

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"enabled": enabled,
		"is_playing": is_playing,
		"current_time": current_time,
		"events_count": events.size(),
		"events": events.map(func(e): return {"name": e.event_name, "time": e.time, "triggered": e.triggered})
	}
