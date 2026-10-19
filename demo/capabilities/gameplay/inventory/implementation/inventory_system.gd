## Inventory System
## Manages items, slots, and inventory operations
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name InventorySystem
extends Node

## Export Variables
@export_group("Inventory Settings")
@export var max_slots: int = 20
@export var stack_size: int = 99
@export var allow_stack: bool = true
@export var allow_drop: bool = true

## Item Class
class Item:
	var id: String
	var name: String
	var description: String
	var icon: Texture2D
	var stack_count: int = 1
	var max_stack: int = 99
	var properties: Dictionary = {}
	
	func _init(item_id: String, item_name: String, desc: String = "") -> void:
		id = item_id
		name = item_name
		description = desc

## Slot Class
class InventorySlot:
	var item: Item
	var quantity: int
	var locked: bool
	
	func _init() -> void:
		item = null
		quantity = 0
		locked = false

## State Variables
var slots: Array[InventorySlot] = []
var selected_slot: int = -1

## Signals
signal item_added(item: Item, slot: int)
signal item_removed(item: Item, slot: int, quantity: int)
signal item_moved(from_slot: int, to_slot: int)
signal slot_changed(slot: int)
signal inventory_full()
signal inventory_changed()

func _ready() -> void:
	_initialize_slots()

func _initialize_slots() -> void:
	slots.clear()
	for i in range(max_slots):
		slots.append(InventorySlot.new())

## Add item
func add_item(item: Item, quantity: int = 1) -> bool:
	# Try to stack with existing items
	if allow_stack:
		for i in range(slots.size()):
			if slots[i].item and slots[i].item.id == item.id:
				var can_add = min(quantity, slots[i].item.max_stack - slots[i].quantity)
				if can_add > 0:
					slots[i].quantity += can_add
					quantity -= can_add
					item_added.emit(item, i)
					inventory_changed.emit()
					
					if quantity <= 0:
						return true
	
	# Add to empty slots
	while quantity > 0:
		var empty_slot = _find_empty_slot()
		if empty_slot == -1:
			inventory_full.emit()
			return false
		
		var new_item = Item.new(item.id, item.name, item.description)
		new_item.icon = item.icon
		new_item.max_stack = item.max_stack
		new_item.properties = item.properties.duplicate()
		
		var add_count = min(quantity, new_item.max_stack)
		slots[empty_slot].item = new_item
		slots[empty_slot].quantity = add_count
		quantity -= add_count
		
		item_added.emit(new_item, empty_slot)
		inventory_changed.emit()
	
	return true

## Remove item
func remove_item(item_id: String, quantity: int = 1) -> bool:
	var remaining = quantity
	
	for i in range(slots.size()):
		if slots[i].item and slots[i].item.id == item_id:
			var remove_count = min(remaining, slots[i].quantity)
			slots[i].quantity -= remove_count
			remaining -= remove_count
			
			item_removed.emit(slots[i].item, i, remove_count)
			
			if slots[i].quantity <= 0:
				slots[i].item = null
				slots[i].quantity = 0
			
			inventory_changed.emit()
			
			if remaining <= 0:
				return true
	
	return remaining <= 0

## Remove item from slot
func remove_item_from_slot(slot: int, quantity: int = 1) -> bool:
	if slot < 0 or slot >= slots.size():
		return false
	
	if not slots[slot].item:
		return false
	
	var remove_count = min(quantity, slots[slot].quantity)
	slots[slot].quantity -= remove_count
	
	item_removed.emit(slots[slot].item, slot, remove_count)
	
	if slots[slot].quantity <= 0:
		slots[slot].item = null
		slots[slot].quantity = 0
	
	inventory_changed.emit()
	return true

## Move item
func move_item(from_slot: int, to_slot: int) -> bool:
	if from_slot < 0 or from_slot >= slots.size():
		return false
	if to_slot < 0 or to_slot >= slots.size():
		return false
	
	# Check if we can stack
	if slots[from_slot].item and slots[to_slot].item:
		if slots[from_slot].item.id == slots[to_slot].item.id and allow_stack:
			var can_stack = min(slots[from_slot].quantity, slots[to_slot].item.max_stack - slots[to_slot].quantity)
			slots[to_slot].quantity += can_stack
			slots[from_slot].quantity -= can_stack
			
			if slots[from_slot].quantity <= 0:
				slots[from_slot].item = null
			
			item_moved.emit(from_slot, to_slot)
			inventory_changed.emit()
			return true
	
	# Swap items
	var temp_item = slots[from_slot].item
	var temp_quantity = slots[from_slot].quantity
	
	slots[from_slot].item = slots[to_slot].item
	slots[from_slot].quantity = slots[to_slot].quantity
	
	slots[to_slot].item = temp_item
	slots[to_slot].quantity = temp_quantity
	
	item_moved.emit(from_slot, to_slot)
	inventory_changed.emit()
	return true

## Find empty slot
func _find_empty_slot() -> int:
	for i in range(slots.size()):
		if not slots[i].item and not slots[i].locked:
			return i
	return -1

## Has item
func has_item(item_id: String, quantity: int = 1) -> bool:
	var count = 0
	for slot in slots:
		if slot.item and slot.item.id == item_id:
			count += slot.quantity
	return count >= quantity

## Get item count
func get_item_count(item_id: String) -> int:
	var count = 0
	for slot in slots:
		if slot.item and slot.item.id == item_id:
			count += slot.quantity
	return count

## Public API
func get_slot(slot: int) -> InventorySlot:
	if slot >= 0 and slot < slots.size():
		return slots[slot]
	return null

func get_slots() -> Array[InventorySlot]:
	return slots

func get_used_slots() -> int:
	var count = 0
	for slot in slots:
		if slot.item:
			count += 1
	return count

func get_free_slots() -> int:
	return max_slots - get_used_slots()

func is_full() -> bool:
	return get_free_slots() <= 0

func clear() -> void:
	slots.clear()
	_initialize_slots()
	inventory_changed.emit()

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"max_slots": max_slots,
		"used_slots": get_used_slots(),
		"free_slots": get_free_slots(),
		"is_full": is_full(),
		"selected_slot": selected_slot
	}
