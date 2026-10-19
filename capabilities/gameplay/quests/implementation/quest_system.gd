## Quest System
## Manages quests, objectives, and rewards
##
## Source: Simplified from common Godot patterns
## Normalized for capability reuse

class_name QuestSystem
extends Node

## Export Variables
@export_group("Quest Settings")
@export var max_active_quests: int = 10
@export var auto_track: bool = true

## Quest Status Enum
enum QuestStatus {
	NOT_STARTED,
	ACTIVE,
	COMPLETED,
	FAILED
}

## Objective Class
class QuestObjective:
	var id: String
	var description: String
	var target_type: String  # "kill", "collect", "talk", "reach", "custom"
	var target_id: String
	var required_amount: int
	var current_amount: int
	var is_completed: bool
	
	func _init(obj_id: String, desc: String, type: String, target: String, required: int) -> void:
		id = obj_id
		description = desc
		target_type = type
		target_id = target
		required_amount = required
		current_amount = 0
		is_completed = false

## Quest Class
class Quest:
	var id: String
	var title: String
	var description: String
	var status: QuestStatus
	var objectives: Array[QuestObjective]
	var rewards: Dictionary
	var prerequisites: Array[String]
	var next_quest: String
	
	func _init(quest_id: String, quest_title: String, quest_desc: String) -> void:
		id = quest_id
		title = quest_title
		description = quest_desc
		status = QuestStatus.NOT_STARTED
		objectives = []
		rewards = {}
		prerequisites = []
		next_quest = ""

## State Variables
var quests: Dictionary = {}
var active_quests: Array[String] = []
var completed_quests: Array[String] = []

## Signals
signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)
signal objective_updated(quest_id: String, objective_id: String)
signal objective_completed(quest_id: String, objective_id: String)
signal quest_accepted(quest_id: String)

func _ready() -> void:
	pass

## Add quest
func add_quest(quest: Quest) -> void:
	quests[quest.id] = quest

## Start quest
func start_quest(quest_id: String) -> bool:
	if not quests.has(quest_id):
		return false
	
	var quest = quests[quest_id]
	
	# Check prerequisites
	for prereq in quest.prerequisites:
		if prereq not in completed_quests:
			return false
	
	# Check max active quests
	if active_quests.size() >= max_active_quests:
		return false
	
	quest.status = QuestStatus.ACTIVE
	active_quests.append(quest_id)
	
	quest_started.emit(quest_id)
	quest_accepted.emit(quest_id)
	return true

## Complete quest
func complete_quest(quest_id: String) -> bool:
	if not quests.has(quest_id):
		return false
	
	var quest = quests[quest_id]
	
	# Check if all objectives are completed
	for objective in quest.objectives:
		if not objective.is_completed:
			return false
	
	quest.status = QuestStatus.COMPLETED
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)
	
	quest_completed.emit(quest_id)
	return true

## Fail quest
func fail_quest(quest_id: String) -> bool:
	if not quests.has(quest_id):
		return false
	
	var quest = quests[quest_id]
	quest.status = QuestStatus.FAILED
	active_quests.erase(quest_id)
	
	quest_failed.emit(quest_id)
	return true

## Update objective
func update_objective(quest_id: String, objective_id: String, amount: int = 1) -> bool:
	if not quests.has(quest_id):
		return false
	
	var quest = quests[quest_id]
	
	for objective in quest.objectives:
		if objective.id == objective_id:
			objective.current_amount = min(objective.current_amount + amount, objective.required_amount)
			objective_updated.emit(quest_id, objective_id)
			
			if objective.current_amount >= objective.required_amount:
				objective.is_completed = true
				objective_completed.emit(quest_id, objective_id)
			
			return true
	
	return false

## Get quest
func get_quest(quest_id: String) -> Quest:
	return quests.get(quest_id)

## Get active quests
func get_active_quests() -> Array[Quest]:
	var result: Array[Quest] = []
	for quest_id in active_quests:
		if quests.has(quest_id):
			result.append(quests[quest_id])
	return result

## Check if quest is active
func is_quest_active(quest_id: String) -> bool:
	return quest_id in active_quests

## Check if quest is completed
func is_quest_completed(quest_id: String) -> bool:
	return quest_id in completed_quests

## Public API
func get_quests() -> Dictionary:
	return quests

func get_completed_quests() -> Array[String]:
	return completed_quests

func get_quest_count() -> int:
	return quests.size()

func get_active_count() -> int:
	return active_quests.size()

func get_completed_count() -> int:
	return completed_quests.size()

func clear() -> void:
	quests.clear()
	active_quests.clear()
	completed_quests.clear()

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"total_quests": quests.size(),
		"active_quests": active_quests.size(),
		"completed_quests": completed_quests.size(),
		"max_active": max_active_quests
	}
