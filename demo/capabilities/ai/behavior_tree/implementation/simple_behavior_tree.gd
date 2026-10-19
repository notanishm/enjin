## Simple Behavior Tree
## Lightweight behavior tree implementation without plugin dependencies
##
## Source: Simplified from limbonaut/limboai concepts
## Reference: Relintai/broken_seals AI patterns
## Normalized for capability reuse

class_name SimpleBehaviorTree
extends Node

## Behavior Tree Status
enum Status {
	SUCCESS,
	FAILURE,
	RUNNING
}

## Export Variables
@export var enabled: bool = true
@export var debug_mode: bool = false

## Node Reference
var owner_node: Node3D

## Signals
signal tree_completed(status: Status)
signal tree_ticked(status: Status)

func _ready() -> void:
	owner_node = get_parent() as Node3D

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	
	var status = tick(delta)
	tree_ticked.emit(status)

## Main tick function - override in subclasses
func tick(delta: float) -> Status:
	return Status.SUCCESS

## Get behavior tree status name
func status_to_string(status: Status) -> String:
	match status:
		Status.SUCCESS:
			return "SUCCESS"
		Status.FAILURE:
			return "FAILURE"
		Status.RUNNING:
			return "RUNNING"
	return "UNKNOWN"

## Base Task Class
class BTTask:
	var status: Status = Status.FAILURE
	var is_running: bool = false
	
	func tick(delta: float) -> Status:
		return Status.FAILURE
	
	func start() -> void:
		is_running = true
	
	func stop() -> void:
		is_running = false

## Composite Classes
class BTSequence:
	extends BTTask
	var tasks: Array[BTTask] = []
	var current_index: int = 0
	
	func tick(delta: float) -> Status:
		while current_index < tasks.size():
			var result = tasks[current_index].tick(delta)
			
			match result:
				Status.RUNNING:
					return Status.RUNNING
				Status.FAILURE:
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
			
			match result:
				Status.RUNNING:
					return Status.RUNNING
				Status.SUCCESS:
					current_index = 0
					return Status.SUCCESS
			
			current_index += 1
		
		current_index = 0
		return Status.FAILURE

## Decorator Classes
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

class BTRepeater:
	extends BTTask
	var child: BTTask
	var repeat_count: int = -1  # -1 for infinite
	var current_count: int = 0
	
	func tick(delta: float) -> Status:
		if not child:
			return Status.FAILURE
		
		var result = child.tick(delta)
		
		if result != Status.RUNNING:
			current_count += 1
			
			if repeat_count > 0 and current_count >= repeat_count:
				current_count = 0
				return Status.SUCCESS
		
		return Status.RUNNING

## Leaf Classes
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

## Helper Functions
static func create_sequence(tasks: Array[BTTask]) -> BTSequence:
	var sequence = BTSequence.new()
	sequence.tasks = tasks
	return sequence

static func create_selector(tasks: Array[BTTask]) -> BTSelector:
	var selector = BTSelector.new()
	selector.tasks = tasks
	return selector

static func create_inverter(child: BTTask) -> BTInverter:
	var inverter = BTInverter.new()
	inverter.child = child
	return inverter

static func create_repeater(child: BTTask, count: int = -1) -> BTRepeater:
	var repeater = BTRepeater.new()
	repeater.child = child
	repeater.repeat_count = count
	return repeater
