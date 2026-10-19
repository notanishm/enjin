## Equipment System
## Manages equipment slots and stat bonuses
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name EquipmentSystem
extends Node

## Export Variables
@export_group("Equipment Settings")
@export var equipment_slots: Array[String] = ["head", "chest", "legs", "feet", "weapon", "shield"]

## Equipment Slot Class
class EquipmentSlot:
	var slot_name: String
	var item: Item
	var locked: bool
	
	func _init(name: String) -> void:
		slot_name = name
		item = null
		locked = false

## Item Class (reusing from inventory)
class Item:
	var id: String
	var name: String
	var description: String
	var icon: Texture2D
	var stats: Dictionary = {}
	var slot_type: String
	
	func _init(item_id: String, item_name: String, slot: String) -> void:
		id = item_id
		name = item_name
		slot_type = slot

## State Variables
var slots: Dictionary = {}
var total_stats: Dictionary = {}

## Signals
signal item_equipped(item: Item, slot: String)
signal item_unequipped(item: Item, slot: String)
signal stats_changed(old_stats: Dictionary, new_stats: Dictionary)

func _ready() -> void:
	_initialize_slots()

func _initialize_slots() -> void:
	for slot_name in equipment_slots:
		slots[slot_name] = EquipmentSlot.new(slot_name)

## Equip item
func equip(item: Item) -> bool:
	if not slots.has(item.slot_type):
		return false
	
	var slot = slots[item.slot_type]
	
	# Unequip current item if any
	if slot.item:
		unequip(item.slot_type)
	
	slot.item = item
	item_equipped.emit(item, item.slot_type)
	_recalculate_stats()
	return true

## Unequip item
func unequip(slot_name: String) -> bool:
	if not slots.has(slot_name):
		return false
	
	var slot = slots[slot_name]
	
	if not slot.item:
		return false
	
	var item = slot.item
	slot.item = null
	item_unequipped.emit(item, slot_name)
	_recalculate_stats()
	return true

## Recalculate stats
func _recalculate_stats() -> void:
	var old_stats = total_stats.duplicate()
	total_stats.clear()
	
	for slot_name in slots:
		var slot = slots[slot_name]
		if slot.item:
			for stat in slot.item.stats:
				if not total_stats.has(stat):
					total_stats[stat] = 0
				total_stats[stat] += slot.item.stats[stat]
	
	stats_changed.emit(old_stats, total_stats)

## Get item in slot
func get_item(slot_name: String) -> Item:
	if slots.has(slot_name):
		return slots[slot_name].item
	return null

## Get total stat
func get_stat(stat_name: String) -> float:
	return total_stats.get(stat_name, 0.0)

## Check if slot is occupied
func is_slot_occupied(slot_name: String) -> bool:
	if slots.has(slot_name):
		return slots[slot_name].item != null
	return false

## Public API
func get_slots() -> Dictionary:
	return slots

func get_equipped_items() -> Array[Item]:
	var items: Array[Item] = []
	for slot_name in slots:
		if slots[slot_name].item:
			items.append(slots[slot_name].item)
	return items

func get_total_stats() -> Dictionary:
	return total_stats

func clear() -> void:
	for slot_name in slots:
		slots[slot_name].item = null
	_recalculate_stats()

## Get debug info
func get_debug_info() -> Dictionary:
	var equipped = 0
	for slot_name in slots:
		if slots[slot_name].item:
			equipped += 1
	
	return {
		"total_slots": slots.size(),
		"equipped_slots": equipped,
		"total_stats": total_stats
	}
