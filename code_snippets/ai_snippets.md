# AI System Snippets

## Source: limbonaut/limboai (MIT)
## Reference: Relintai/broken_seals
## Adapted for capability reuse

---

## 1. Simple Behavior Tree

```gdscript
## Source: Simplified from limbonaut/limboai concepts
## Adapted: Lightweight BT without plugin dependency

extends Node

enum Status { SUCCESS, FAILURE, RUNNING }

class BTTask:
	var status: Status = Status.FAILURE
	
	func tick(delta: float) -> Status:
		return Status.FAILURE

class BTSequence:
	extends BTTask
	var tasks: Array[BTTask] = []
	var current_index: int = 0
	
	func tick(delta: float) -> Status:
		while current_index < tasks.size():
			var result = tasks[current_index].tick(delta)
			if result == Status.RUNNING:
				return Status.RUNNING
			if result == Status.FAILURE:
				current_index = 0
				return Status.FAILURE
			current_index += 1
		current_index = 0
		return Status.SUCCESS

class BTSelector:
	extends BTTask
	var tasks: Array[BTTask] = []
	var current_index: int = 0
	
	func tick(delta: float) -> Status:
		while current_index < tasks.size():
			var result = tasks[current_index].tick(delta)
			if result == Status.RUNNING:
				return Status.RUNNING
			if result == Status.SUCCESS:
				current_index = 0
				return Status.SUCCESS
			current_index += 1
		current_index = 0
		return Status.FAILURE

class BTInverter:
	extends BTTask
	var child: BTTask
	
	func tick(delta: float) -> Status:
		if not child:
			return Status.FAILURE
		var result = child.tick(delta)
		match result:
			Status.SUCCESS:
				return Status.FAILURE
			Status.FAILURE:
				return Status.SUCCESS
			_:
				return result

class BTCondition:
	extends BTTask
	var condition_func: Callable
	
	func tick(delta: float) -> Status:
		if condition_func and condition_func.call():
			return Status.SUCCESS
		return Status.FAILURE

class BTAction:
	extends BTTask
	var action_func: Callable
	
	func tick(delta: float) -> Status:
		if action_func:
			return action_func.call(delta)
		return Status.FAILURE
```

---

## 2. Simple State Machine

```gdscript
## Source: Simplified from common patterns
## Adapted: Lightweight state machine

extends Node

class State:
	var name: String
	var enter_func: Callable
	var exit_func: Callable
	var update_func: Callable
	
	func _init(state_name: String) -> void:
		name = state_name

var states: Dictionary = {}
var current_state: State = null
var is_running: bool = false

func add_state(name: String, enter: Callable = Callable(), exit: Callable = Callable(), update: Callable = Callable()) -> State:
	var state = State.new(name)
	state.enter_func = enter
	state.exit_func = exit
	state.update_func = update
	states[name] = state
	return state

func start() -> void:
	is_running = true
	if states.size() > 0:
		current_state = states.values()[0]
		if current_state.enter_func.is_valid():
			current_state.enter_func.call()

func change_state(new_state_name: String) -> void:
	if not states.has(new_state_name):
		return
	
	if current_state and current_state.exit_func.is_valid():
		current_state.exit_func.call()
	
	current_state = states[new_state_name]
	
	if current_state.enter_func.is_valid():
		current_state.enter_func.call()

func _process(delta: float) -> void:
	if is_running and current_state and current_state.update_func.is_valid():
		current_state.update_func.call(delta)
```

---

## 3. Simple Navigation

```gdscript
## Source: Simplified from common patterns
## Adapted: Basic pathfinding

extends Node3D

@export var move_speed: float = 5.0
@export var arrival_distance: float = 0.5

var target_position: Vector3 = Vector3.ZERO
var is_moving: bool = false
var character: CharacterBody3D

func _ready() -> void:
	character = get_parent() as CharacterBody3D

func _physics_process(delta: float) -> void:
	if not is_moving or not character:
		return
	
	var direction = (target_position - character.global_position).normalized()
	
	if character.global_position.distance_to(target_position) < arrival_distance:
		is_moving = false
		character.velocity = Vector3.ZERO
		return
	
	character.velocity = direction * move_speed
	character.move_and_slide()

func set_target(target: Vector3) -> void:
	target_position = target
	is_moving = true
```
