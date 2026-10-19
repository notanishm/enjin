## Animation State Machine
## Manages animation states and transitions
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name AnimationStateMachine
extends Node

## Export Variables
@export_group("Settings")
@export var auto_start: bool = true
@export var debug_mode: bool = false

## State Class
class AnimState:
	var name: String
	var animation: String
	var speed: float = 1.0
	var blend_time: float = 0.2
	var transitions: Dictionary = {}
	
	func _init(state_name: String, anim: String = "") -> void:
		name = state_name
		animation = anim if anim != "" else state_name

## Transition Class
class AnimTransition:
	var from: String
	var to: String
	var condition: Callable
	var priority: int = 0
	
	func _init(from_state: String, to_state: String, cond: Callable = Callable(), prio: int = 0) -> void:
		from = from_state
		to = to_state
		condition = cond
		priority = prio

## State Variables
var states: Dictionary = {}
var transitions: Array[AnimTransition] = []
var current_state: AnimState = null
var previous_state: AnimState = null
var is_playing: bool = false

## Node Reference
var animation_player: AnimationPlayer

## Signals
signal state_changed(old_state: String, new_state: String)
signal animation_finished(anim_name: String)

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
	
	# Check siblings
	if parent:
		for sibling in parent.get_children():
			if sibling is AnimationPlayer:
				return sibling
	
	return null

func _physics_process(delta: float) -> void:
	if is_playing and current_state:
		_check_transitions()

## Add a state
func add_state(name: String, animation: String = "", speed: float = 1.0, blend_time: float = 0.2) -> AnimState:
	var state = AnimState.new(name, animation)
	state.speed = speed
	state.blend_time = blend_time
	states[name] = state
	return state

## Add a transition
func add_transition(from: String, to: String, condition: Callable = Callable(), priority: int = 0) -> AnimTransition:
	var transition = AnimTransition.new(from, to, condition, priority)
	transitions.append(transition)
	return transition

## Start the state machine
func start(initial_state: String = "") -> void:
	is_playing = true
	
	if initial_state == "" and states.size() > 0:
		initial_state = states.keys()[0]
	
	if states.has(initial_state):
		_change_state(states[initial_state])

## Stop the state machine
func stop() -> void:
	is_playing = false
	if animation_player:
		animation_player.stop()

## Change state manually
func change_state(new_state_name: String) -> void:
	if states.has(new_state_name):
		_change_state(states[new_state_name])

## Change state internally
func _change_state(new_state: AnimState) -> void:
	if current_state == new_state:
		return
	
	previous_state = current_state
	current_state = new_state
	
	if animation_player and current_state:
		animation_player.play(current_state.animation)
		animation_player.speed_scale = current_state.speed
	
	state_changed.emit(
		previous_state.name if previous_state else "",
		current_state.name
	)

## Check transitions
func _check_transitions() -> void:
	var valid_transitions: Array[AnimTransition] = []
	
	# Find valid transitions from current state
	for transition in transitions:
		if transition.from == current_state.name:
			if transition.condition.is_valid():
				if transition.condition.call():
					valid_transitions.append(transition)
			else:
				valid_transitions.append(transition)
	
	# Sort by priority
	valid_transitions.sort_custom(func(a, b): return a.priority > b.priority)
	
	# Execute highest priority transition
	if valid_transitions.size() > 0:
		_change_state(states[valid_transitions[0].to])

## Get current state
func get_current_state() -> String:
	return current_state.name if current_state else ""

## Get previous state
func get_previous_state() -> String:
	return previous_state.name if previous_state else ""

## Check if state exists
func has_state(name: String) -> bool:
	return states.has(name)

## Get all states
func get_states() -> Array[String]:
	return states.keys()

## Animation finished callback
func _on_animation_finished(anim_name: String) -> void:
	animation_finished.emit(anim_name)

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"current_state": get_current_state(),
		"previous_state": get_previous_state(),
		"is_playing": is_playing,
		"states_count": states.size(),
		"transitions_count": transitions.size(),
		"states": states.keys()
	}
