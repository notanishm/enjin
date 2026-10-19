## Simple State Machine
## Lightweight state machine for AI and gameplay
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name SimpleStateMachine
extends Node

## Export Variables
@export_group("Settings")
@export var auto_start: bool = true
@export var debug_mode: bool = false

## State Class
class State:
	var name: String
	var enter_func: Callable
	var exit_func: Callable
	var update_func: Callable
	var physics_func: Callable
	
	func _init(state_name: String) -> void:
		name = state_name

## State Variables
var states: Dictionary = {}
var current_state: State = null
var previous_state: State = null
var is_running: bool = false

## Signals
signal state_changed(old_state: String, new_state: String)

func _ready() -> void:
	if auto_start and states.size() > 0:
		start()

func _process(delta: float) -> void:
	if is_running and current_state and current_state.update_func.is_valid():
		current_state.update_func.call(delta)

func _physics_process(delta: float) -> void:
	if is_running and current_state and current_state.physics_func.is_valid():
		current_state.physics_func.call(delta)

## Add state
func add_state(name: String, enter: Callable = Callable(), exit: Callable = Callable(), update: Callable = Callable(), physics: Callable = Callable()) -> State:
	var state = State.new(name)
	state.enter_func = enter
	state.exit_func = exit
	state.update_func = update
	state.physics_func = physics
	states[name] = state
	return state

## Start state machine
func start() -> void:
	is_running = true
	if states.size() > 0:
		_change_state(states.values()[0])

## Stop state machine
func stop() -> void:
	is_running = false

## Change state
func change_state(new_state_name: String) -> void:
	if states.has(new_state_name):
		_change_state(states[new_state_name])

## Change state internally
func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	
	# Exit current state
	if current_state and current_state.exit_func.is_valid():
		current_state.exit_func.call()
	
	previous_state = current_state
	current_state = new_state
	
	# Enter new state
	if current_state and current_state.enter_func.is_valid():
		current_state.enter_func.call()
	
	state_changed.emit(
		previous_state.name if previous_state else "",
		current_state.name if current_state else ""
	)

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

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"is_running": is_running,
		"current_state": get_current_state(),
		"previous_state": get_previous_state(),
		"states_count": states.size(),
		"states": states.keys()
	}
