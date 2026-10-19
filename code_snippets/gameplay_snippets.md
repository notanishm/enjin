# Gameplay System Snippets

## Source: Simplified from common Godot patterns
## Adapted for capability reuse

---

## 1. Health System

```gdscript
## Source: Simplified from common patterns
## Adapted: Health management

extends Node

@export var max_health: float = 100.0
var current_health: float = 100.0
var is_alive: bool = true

func take_damage(amount: float, source: Node = null) -> void:
	if not is_alive:
		return
	
	current_health = max(current_health - amount, 0.0)
	if current_health <= 0:
		is_alive = false

func heal(amount: float, source: Node = null) -> void:
	if not is_alive:
		return
	current_health = min(current_health + amount, max_health)

func respawn() -> void:
	current_health = max_health
	is_alive = true

func get_health_percent() -> float:
	return (current_health / max_health) * 100.0
```

---

## 2. Inventory System

```gdscript
## Source: Simplified from common patterns
## Adapted: Inventory management

extends Node

@export var max_slots: int = 20
@export var allow_stack: bool = true

class Item:
	var id: String
	var name: String
	var max_stack: int = 99
	
	func _init(item_id: String, item_name: String) -> void:
		id = item_id
		name = item_name

var slots: Array = []

func add_item(item: Item, quantity: int = 1) -> bool:
	# Try to stack
	if allow_stack:
		for slot in slots:
			if slot.item and slot.item.id == item.id:
				if slot.quantity < item.max_stack:
					slot.quantity += quantity
					return true
	
	# Add new slot
	if slots.size() < max_slots:
		slots.append({"item": item, "quantity": quantity})
		return true
	
	return false

func remove_item(item_id: String, quantity: int = 1) -> bool:
	for i in range(slots.size()):
		if slots[i].item and slots[i].item.id == item_id:
			slots[i].quantity -= quantity
			if slots[i].quantity <= 0:
				slots.remove_at(i)
			return true
	return false

func has_item(item_id: String) -> bool:
	for slot in slots:
		if slot.item and slot.item.id == item_id:
			return true
	return false
```

---

## 3. Dialogue System

```gdscript
## Source: Simplified from common patterns
## Adapted: Dialogue trees

extends Node

class DialogueNode:
	var id: String
	var speaker: String
	var text: String
	var next_node: String

var dialogue_tree: Dictionary = {}
var current_node: DialogueNode = null
var is_active: bool = false

func add_node(id: String, speaker: String, text: String, next: String = "") -> void:
	var node = DialogueNode.new()
	node.id = id
	node.speaker = speaker
	node.text = text
	node.next_node = next
	dialogue_tree[id] = node

func start_dialogue(start_id: String) -> void:
	if dialogue_tree.has(start_id):
		current_node = dialogue_tree[start_id]
		is_active = true

func advance() -> void:
	if current_node and current_node.next_node != "":
		if dialogue_tree.has(current_node.next_node):
			current_node = dialogue_tree[current_node.next_node]
		else:
			is_active = false
	else:
		is_active = false
```

---

## 4. Quest System

```gdscript
## Source: Simplified from common patterns
## Adapted: Quest tracking

extends Node

enum QuestStatus { NOT_STARTED, ACTIVE, COMPLETED, FAILED }

class Quest:
	var id: String
	var title: String
	var status: QuestStatus

var quests: Dictionary = {}

func add_quest(quest: Quest) -> void:
	quests[quest.id] = quest

func start_quest(quest_id: String) -> void:
	if quests.has(quest_id):
		quests[quest_id].status = QuestStatus.ACTIVE

func complete_quest(quest_id: String) -> void:
	if quests.has(quest_id):
		quests[quest_id].status = QuestStatus.COMPLETED

func is_quest_active(quest_id: String) -> bool:
	return quests.has(quest_id) and quests[quest_id].status == QuestStatus.ACTIVE
```

---

## 5. Equipment System

```gdscript
## Source: Simplified from common patterns
## Adapted: Equipment slots

extends Node

var equipment_slots: Dictionary = {}
var total_stats: Dictionary = {}

class EquipmentItem:
	var id: String
	var name: String
	var slot: String
	var stats: Dictionary = {}

func equip(item: EquipmentItem) -> void:
	equipment_slots[item.slot] = item
	_recalculate_stats()

func unequip(slot: String) -> void:
	equipment_slots.erase(slot)
	_recalculate_stats()

func _recalculate_stats() -> void:
	total_stats.clear()
	for slot in equipment_slots:
		var item = equipment_slots[slot]
		for stat in item.stats:
			if not total_stats.has(stat):
				total_stats[stat] = 0
			total_stats[stat] += item.stats[stat]

func get_stat(stat_name: String) -> float:
	return total_stats.get(stat_name, 0.0)
```
