## Input Manager Component
## Centralizes input configuration for character movement
##
## Source: Jeh3no/Godot-Third-Person-Controller
## Normalized for capability reuse

extends Node

## Input Action Configuration
@export_group("Movement Actions")
@export var move_forward: String = "move_forward"
@export var move_backward: String = "move_backward"
@export var move_left: String = "move_left"
@export var move_right: String = "move_right"

@export_group("Action Actions")
@export var jump: String = "jump"
@export var run: String = "run"

@export_group("Camera Actions")
@export var camera_toggle: String = "camera_toggle"
@export var aim_camera: String = "aim_camera"
@export var camera_zoom_in: String = "camera_zoom_in"
@export var camera_zoom_out: String = "camera_zoom_out"

## Default Keybindings
var default_bindings: Dictionary = {
	"move_forward": [KEY_W, KEY_UP],
	"move_backward": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"jump": [KEY_SPACE],
	"run": [KEY_SHIFT],
	"camera_toggle": [KEY_T],
	"aim_camera": [KEY_MOUSE_BUTTON_RIGHT],
	"camera_zoom_in": [KEY_V, MOUSE_BUTTON_WHEEL_UP],
	"camera_zoom_out": [KEY_B, MOUSE_BUTTON_WHEEL_DOWN]
}

## Signals
signal input_action_pressed(action: String)
signal input_action_released(action: String)

func _ready() -> void:
	_setup_default_input_actions()

## Setup default input actions if they don't exist
func _setup_default_input_actions() -> void:
	for action_name in default_bindings.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			
			# Add default keybindings
			for key in default_bindings[action_name]:
				var event: InputEvent
				if key is Key:
					event = InputEventKey.new()
					event.keycode = key
				elif key is MouseButton:
					event = InputEventMouseButton.new()
					event.button_index = key
				
				if event:
					InputMap.action_add_event(action_name, event)

## Get movement direction from input
func get_movement_direction() -> Vector3:
	var direction = Vector3.ZERO
	
	if Input.is_action_pressed(move_forward):
		direction.z -= 1.0
	if Input.is_action_pressed(move_backward):
		direction.z += 1.0
	if Input.is_action_pressed(move_left):
		direction.x -= 1.0
	if Input.is_action_pressed(move_right):
		direction.x += 1.0
	
	return direction.normalized()

## Check if jump is pressed
func is_jump_pressed() -> bool:
	return Input.is_action_just_pressed(jump)

## Check if run is pressed
func is_run_pressed() -> bool:
	return Input.is_action_pressed(run)

## Check if specific action is pressed
func is_action_pressed(action_name: String) -> bool:
	return Input.is_action_pressed(action_name)

## Check if specific action is just pressed
func is_action_just_pressed(action_name: String) -> bool:
	return Input.is_action_just_pressed(action_name)

## Check if specific action is just released
func is_action_just_released(action_name: String) -> bool:
	return Input.is_action_just_released(action_name)

## Get input strength for analog input
func get_input_strength(action_name: String) -> float:
	return Input.get_action_strength(action_name)

## Get axis value (for dual-axis input like movement)
func get_axis(negative_action: String, positive_action: String) -> float:
	return Input.get_axis(negative_action, positive_action)

## Get vector value (for 2D movement)
func get_vector(negative_x: String, positive_x: String, negative_y: String, positive_y: String) -> Vector2:
	return Input.get_vector(negative_x, positive_x, negative_y, positive_y)

## Validate all required input actions exist
func validate_input_actions() -> Dictionary:
	var result = {
		"valid": true,
		"missing_actions": [],
		"existing_actions": []
	}
	
	var required_actions = [
		move_forward, move_backward, move_left, move_right,
		jump, run
	]
	
	for action in required_actions:
		if InputMap.has_action(action):
			result.existing_actions.append(action)
		else:
			result.missing_actions.append(action)
			result.valid = false
	
	return result

## Get debug info about input state
func get_debug_info() -> Dictionary:
	return {
		"movement_direction": get_movement_direction(),
		"jump_pressed": is_jump_pressed(),
		"run_pressed": is_run_pressed(),
		"input_actions_valid": validate_input_actions()
	}
