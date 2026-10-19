## Interactable Component
## Add to any object to make it interactable
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name Interactable
extends Node3D

## Export Variables
@export_group("Interaction Settings")
@export var interactable_name: String = "Object"
@export var interaction_prompt: String = "Press E to interact"
@export var interaction_time: float = 0.0
@export var one_shot: bool = false
@export var enabled: bool = true

@export_group("Visual Feedback")
@export var highlight_enabled: bool = true
@export var highlight_color: Color = Color.YELLOW
@export var outline_enabled: bool = false

## State Variables
var is_hovered: bool = false
var is_interacting: bool = false
var has_been_interacted: bool = false

## Signals
signal interacted
signal hovered
signal unhovered

## Virtual Methods - Override in subclasses
func on_interact() -> void:
	if not enabled:
		return
	
	if one_shot and has_been_interacted:
		return
	
	is_interacting = true
	has_been_interacted = true
	interacted.emit()
	
	# Override this method in subclasses to add behavior
	_on_interact()

func on_interact_hover() -> void:
	if not enabled:
		return
	
	is_hovered = true
	hovered.emit()
	
	# Apply visual feedback
	if highlight_enabled:
		_apply_highlight(true)
	
	# Override this method in subclasses
	_on_hover()

func on_interact_exit() -> void:
	is_hovered = false
	unhovered.emit()
	
	# Remove visual feedback
	if highlight_enabled:
		_apply_highlight(false)
	
	# Override this method in subclasses
	_on_exit()

## Internal methods - Override _on_* versions in subclasses
func _on_interact() -> void:
	# Default implementation - override in subclasses
	pass

func _on_hover() -> void:
	# Default implementation - override in subclasses
	pass

func _on_exit() -> void:
	# Default implementation - override in subclasses
	pass

## Get interaction time
func get_interaction_time() -> float:
	return interaction_time

## Apply highlight effect
func _apply_highlight(show_highlight: bool) -> void:
	# Find mesh instances and apply material override
	for child in get_children():
		if child is MeshInstance3D:
			if show_highlight:
				# Create highlight material
				var mat = StandardMaterial3D.new()
				mat.albedo_color = highlight_color
				mat.emission_enabled = true
				mat.emission = highlight_color
				mat.emission_energy_multiplier = 0.5
				child.material_override = mat
			else:
				child.material_override = null

## Public API
func set_interactable_name(new_name: String) -> void:
	interactable_name = new_name

func set_interaction_prompt(prompt: String) -> void:
	interaction_prompt = prompt

func set_enabled(new_enabled: bool) -> void:
	enabled = new_enabled

func is_enabled() -> bool:
	return enabled

func get_interactable_name() -> String:
	return interactable_name

func get_interaction_prompt() -> String:
	return interaction_prompt

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"name": interactable_name,
		"enabled": enabled,
		"is_hovered": is_hovered,
		"is_interacting": is_interacting,
		"has_been_interacted": has_been_interacted,
		"one_shot": one_shot
	}
