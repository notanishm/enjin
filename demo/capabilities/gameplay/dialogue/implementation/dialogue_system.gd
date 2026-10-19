## Dialogue System
## Manages dialogue trees and conversations
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name DialogueSystem
extends Node

## Export Variables
@export_group("Dialogue Settings")
@export var dialogue_speed: float = 0.05
@export var auto_advance: bool = false
@export var auto_advance_delay: float = 2.0

## Dialogue Node Class
class DialogueNode:
	var id: String
	var speaker: String
	var text: String
	var choices: Array[DialogueChoice]
	var next_node: String
	
	func _init(node_id: String, speaker_name: String, dialogue_text: String) -> void:
		id = node_id
		speaker = speaker_name
		text = dialogue_text
		choices = []
		next_node = ""

## Dialogue Choice Class
class DialogueChoice:
	var text: String
	var next_node: String
	var condition: Callable
	var consequence: Callable
	
	func _init(choice_text: String, next: String, cond: Callable = Callable(), cons: Callable = Callable()) -> void:
		text = choice_text
		next_node = next
		condition = cond
		consequence = cons

## State Variables
var dialogue_tree: Dictionary = {}
var current_node: DialogueNode = null
var is_dialogue_active: bool = false
var dialogue_history: Array[String] = []

## Signals
signal dialogue_started(speaker: String)
signal dialogue_line(speaker: String, text: String)
signal dialogue_choice(choices: Array[DialogueChoice])
signal dialogue_ended()

func _ready() -> void:
	pass

## Start dialogue
func start_dialogue(start_node: String) -> void:
	if not dialogue_tree.has(start_node):
		return
	
	current_node = dialogue_tree[start_node]
	is_dialogue_active = true
	dialogue_history.clear()
	
	dialogue_started.emit(current_node.speaker)
	_display_current_node()

## Display current node
func _display_current_node() -> void:
	if not current_node:
		return
	
	dialogue_line.emit(current_node.speaker, current_node.text)
	
	# Check for choices
	if current_node.choices.size() > 0:
		# Filter valid choices
		var valid_choices: Array[DialogueChoice] = []
		for choice in current_node.choices:
			if choice.condition.is_valid():
				if choice.condition.call():
					valid_choices.append(choice)
			else:
				valid_choices.append(choice)
		
		if valid_choices.size() > 0:
			dialogue_choice.emit(valid_choices)
			return
	
	# Auto-advance if no choices
	if auto_advance:
		await get_tree().create_timer(auto_advance_delay).timeout
		advance_dialogue()

## Advance dialogue
func advance_dialogue() -> void:
	if not current_node:
		return
	
	# Record history
	dialogue_history.append(current_node.id)
	
	# Move to next node
	if current_node.next_node != "":
		if dialogue_tree.has(current_node.next_node):
			current_node = dialogue_tree[current_node.next_node]
			_display_current_node()
		else:
			end_dialogue()
	else:
		end_dialogue()

## Select choice
func select_choice(choice_index: int) -> void:
	if not current_node or choice_index >= current_node.choices.size():
		return
	
	var choice = current_node.choices[choice_index]
	
	# Execute consequence
	if choice.consequence.is_valid():
		choice.consequence.call()
	
	# Move to next node
	if dialogue_tree.has(choice.next_node):
		current_node = dialogue_tree[choice.next_node]
		_display_current_node()
	else:
		end_dialogue()

## End dialogue
func end_dialogue() -> void:
	current_node = null
	is_dialogue_active = false
	dialogue_ended.emit()

## Add dialogue node
func add_node(id: String, speaker: String, text: String, next_node: String = "") -> DialogueNode:
	var node = DialogueNode.new(id, speaker, text)
	node.next_node = next_node
	dialogue_tree[id] = node
	return node

## Add choice to node
func add_choice(node_id: String, text: String, next_node: String, condition: Callable = Callable(), consequence: Callable = Callable()) -> void:
	if dialogue_tree.has(node_id):
		var choice = DialogueChoice.new(text, next_node, condition, consequence)
		dialogue_tree[node_id].choices.append(choice)

## Public API
func is_active() -> bool:
	return is_dialogue_active

func get_current_speaker() -> String:
	return current_node.speaker if current_node else ""

func get_current_text() -> String:
	return current_node.text if current_node else ""

func get_history() -> Array[String]:
	return dialogue_history

func clear_dialogue() -> void:
	dialogue_tree.clear()
	current_node = null
	is_dialogue_active = false

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"is_active": is_dialogue_active,
		"current_node": current_node.id if current_node else "None",
		"nodes_count": dialogue_tree.size(),
		"history_count": dialogue_history.size()
	}
