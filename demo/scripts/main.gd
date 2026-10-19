## Demo Main Script
## Showcases all capabilities from the corpus

extends Node3D

## Export Variables
@export_group("Demo Settings")
@export var show_ui: bool = true
@export var auto_start_demo: bool = true

## Node References
@onready var player: CharacterBody3D = $Player
@onready var camera = $Player/ThirdPersonCamera
@onready var movement = $Player/CharacterMovement
@onready var jump = $Player/JumpComponent
@onready var sprint = $Player/SprintComponent
@onready var crouch = $Player/CrouchComponent
@onready var health = $Player/HealthSystem
@onready var inventory = $Player/InventorySystem
@onready var equipment = $Player/EquipmentSystem
@onready var dialogue = $UI/DialogueSystem
@onready var quest = $QuestSystem

## State Variables
var current_demo: String = ""
var demo_index: int = 0
var demos: Array[String] = [
	"movement",
	"jump",
	"sprint",
	"crouch",
	"camera",
	"interaction",
	"inventory",
	"equipment",
	"dialogue",
	"health",
	"quests"
]

## Signals
signal demo_changed(demo_name: String)
signal demo_completed(demo_name: String)

func _ready() -> void:
	_setup_demos()
	if auto_start_demo:
		_start_next_demo()

func _setup_demos() -> void:
	# Connect signals
	if jump:
		jump.jump_started.connect(_on_jump_started)
	if sprint:
		sprint.sprint_started.connect(_on_sprint_started)
	if crouch:
		crouch.crouch_started.connect(_on_crouch_started)
	if health:
		health.damage_taken.connect(_on_damage_taken)
		health.healed.connect(_on_healed)

func _input(event: InputEvent) -> void:
	# Handle demo navigation
	if event.is_action_pressed("ui_accept"):
		_start_next_demo()
	elif event.is_action_pressed("ui_cancel"):
		_end_current_demo()

func _start_next_demo() -> void:
	if demo_index >= demos.size():
		demo_index = 0
	
	current_demo = demos[demo_index]
	demo_index += 1
	
	# Configure demo
	match current_demo:
		"movement":
			_setup_movement_demo()
		"jump":
			_setup_jump_demo()
		"sprint":
			_setup_sprint_demo()
		"crouch":
			_setup_crouch_demo()
		"camera":
			_setup_camera_demo()
		"interaction":
			_setup_interaction_demo()
		"inventory":
			_setup_inventory_demo()
		"equipment":
			_setup_equipment_demo()
		"dialogue":
			_setup_dialogue_demo()
		"health":
			_setup_health_demo()
		"quests":
			_setup_quests_demo()
	
	demo_changed.emit(current_demo)

func _end_current_demo() -> void:
	demo_completed.emit(current_demo)
	current_demo = ""

## Demo Setup Functions
func _setup_movement_demo() -> void:
	if movement:
		movement.enabled = true

func _setup_jump_demo() -> void:
	if jump:
		jump.enabled = true

func _setup_sprint_demo() -> void:
	if sprint:
		sprint.enabled = true

func _setup_crouch_demo() -> void:
	if crouch:
		crouch.enabled = true

func _setup_camera_demo() -> void:
	if camera:
		camera.enabled = true

func _setup_interaction_demo() -> void:
	# Enable interaction objects
	for obj in get_tree().get_nodes_in_group("interactable"):
		obj.set_process(true)

func _setup_inventory_demo() -> void:
	if inventory:
		# Add sample items using Item class from InventorySystem
		var item_class = inventory.get_script().get_meta("ItemClass", null)
		if item_class:
			var sword = item_class.new("sword", "Iron Sword", "A sharp sword")
			sword.max_stack = 1
			inventory.add_item(sword)

func _setup_equipment_demo() -> void:
	if equipment:
		# Equip sample item using Item class from EquipmentSystem
		var item_class = equipment.get_script().get_meta("ItemClass", null)
		if item_class:
			var helmet = item_class.new("helmet", "Iron Helmet", "helmet")
			helmet.stats = {"defense": 5}
			equipment.equip(helmet)

func _setup_dialogue_demo() -> void:
	if dialogue:
		# Start sample dialogue
		dialogue.add_node("start", "NPC", "Welcome to the demo!")
		dialogue.add_node("end", "NPC", "Goodbye!")
		dialogue.start_dialogue("start")

func _setup_health_demo() -> void:
	if health:
		# Take sample damage
		health.take_damage(25.0)

func _setup_quests_demo() -> void:
	if quest:
		# Add sample quest using Quest class from QuestSystem
		var quest_class = quest.get_script().get_meta("QuestClass", null)
		if quest_class:
			var q = quest_class.new("demo_quest", "Demo Quest", "Complete the demo")
			quest.add_quest(q)
			quest.start_quest("demo_quest")

## Signal Handlers
func _on_jump_started() -> void:
	print("Jump triggered")

func _on_sprint_started() -> void:
	print("Sprint triggered")

func _on_crouch_started() -> void:
	print("Crouch triggered")

func _on_damage_taken(amount: float, source: Node) -> void:
	print("Damage taken: ", amount)

func _on_healed(amount: float, source: Node) -> void:
	print("Healed: ", amount)

## Public API
func get_current_demo() -> String:
	return current_demo

func get_demo_list() -> Array[String]:
	return demos

func get_demo_index() -> int:
	return demo_index
