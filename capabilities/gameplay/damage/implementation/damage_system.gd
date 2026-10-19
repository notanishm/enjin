## Damage System
## Calculates and applies damage with modifiers
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name DamageSystem
extends Node

## Export Variables
@export_group("Damage Settings")
@export var base_damage: float = 10.0
@export var critical_multiplier: float = 2.0
@export var critical_chance: float = 0.1

@export_group("Modifiers")
@export var damage_types: Array[String] = ["physical"]
@export var resistances: Dictionary = {}
@export var vulnerabilities: Dictionary = {}

## Damage Result Class
class DamageResult:
	var raw_damage: float
	var final_damage: float
	var is_critical: bool
	var damage_type: String
	var blocked: bool
	var resisted: bool
	
	func _init() -> void:
		raw_damage = 0.0
		final_damage = 0.0
		is_critical = false
		damage_type = "physical"
		blocked = false
		resisted = false

## Calculate damage
func calculate_damage(attacker: Node, target: Node, damage_type: String = "physical") -> DamageResult:
	var result = DamageResult.new()
	
	# Base damage
	result.raw_damage = base_damage
	result.damage_type = damage_type
	
	# Check for critical hit
	result.is_critical = randf() < critical_chance
	if result.is_critical:
		result.raw_damage *= critical_multiplier
	
	# Apply resistances
	if resistances.has(damage_type):
		var resistance = resistances[damage_type]
		result.raw_damage *= (1.0 - resistance)
		result.resisted = resistance > 0
	
	# Apply vulnerabilities
	if vulnerabilities.has(damage_type):
		var vulnerability = vulnerabilities[damage_type]
		result.raw_damage *= (1.0 + vulnerability)
	
	# Apply modifiers from attacker
	if attacker.has_method("get_damage_modifier"):
		result.raw_damage *= attacker.get_damage_modifier()
	
	# Apply modifiers from target
	if target.has_method("get_defense_modifier"):
		result.raw_damage *= (1.0 / target.get_defense_modifier())
	
	# Final damage
	result.final_damage = max(result.raw_damage, 0.0)
	
	return result

## Apply damage to target
func apply_damage(attacker: Node, target: Node, damage_type: String = "physical") -> DamageResult:
	var result = calculate_damage(attacker, target, damage_type)
	
	# Apply damage to health system
	if target.has_method("take_damage"):
		target.take_damage(result.final_damage, attacker)
	
	return result

## Public API
func set_base_damage(damage: float) -> void:
	base_damage = damage

func set_critical_chance(chance: float) -> void:
	critical_chance = clamp(chance, 0.0, 1.0)

func set_critical_multiplier(multiplier: float) -> void:
	critical_multiplier = multiplier

func add_resistance(damage_type: String, resistance: float) -> void:
	resistances[damage_type] = clamp(resistance, 0.0, 1.0)

func add_vulnerability(damage_type: String, vulnerability: float) -> void:
	vulnerabilities[damage_type] = max(vulnerability, 0.0)

func remove_resistance(damage_type: String) -> void:
	resistances.erase(damage_type)

func remove_vulnerability(damage_type: String) -> void:
	vulnerabilities.erase(damage_type)

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"base_damage": base_damage,
		"critical_chance": critical_chance,
		"critical_multiplier": critical_multiplier,
		"resistances": resistances,
		"vulnerabilities": vulnerabilities
	}
