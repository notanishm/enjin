## Demo UI Script
## Shows demo information and controls

extends CanvasLayer

## Export Variables
@export_group("UI Settings")
@export var show_controls: bool = true
@export var show_demo_info: bool = true

## Node References
@onready var demo_label: Label = $DemoLabel
@onready var controls_label: Label = $ControlsLabel
@onready var info_label: Label = $InfoLabel
@onready var health_bar: ProgressBar = $HealthBar
@onready var inventory_label: Label = $InventoryLabel

## State Variables
var current_demo: String = ""

func _ready() -> void:
	_update_ui()

func _process(delta: float) -> void:
	_update_health_display()
	_update_inventory_display()

## Update UI
func _update_ui() -> void:
	if demo_label:
		demo_label.text = "Demo: %s" % current_demo.capitalize()
	
	if controls_label and show_controls:
		controls_label.text = _get_controls_text()
	
	if info_label and show_demo_info:
		info_label.text = _get_demo_info()

## Get controls text
func _get_controls_text() -> String:
	return """
Controls:
- WASD: Move
- Space: Jump
- Shift: Sprint
- C: Crouch
- E: Interact
- Tab: Inventory
- Enter: Next Demo
- Esc: End Demo
"""

## Get demo info
func _get_demo_info() -> String:
	match current_demo:
		"movement":
			return "Movement Demo: Use WASD to move around"
		"jump":
			return "Jump Demo: Press Space to jump"
		"sprint":
			return "Sprint Demo: Hold Shift to sprint"
		"crouch":
			return "Crouch Demo: Press C to crouch"
		"camera":
			return "Camera Demo: Move mouse to look around"
		"interaction":
			return "Interaction Demo: Press E near objects"
		"inventory":
			return "Inventory Demo: Press Tab to open inventory"
		"equipment":
			return "Equipment Demo: Items are auto-equipped"
		"dialogue":
			return "Dialogue Demo: Talk to NPCs"
		"health":
			return "Health Demo: Take damage and heal"
		"quests":
			return "Quests Demo: Complete objectives"
		_:
			return "Press Enter to start a demo"

## Update health display
func _update_health_display() -> void:
	if health_bar:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_node("HealthSystem"):
			var health = player.get_node("HealthSystem")
			health_bar.value = health.get_health_percent()

## Update inventory display
func _update_inventory_display() -> void:
	if inventory_label:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_node("InventorySystem"):
			var inventory = player.get_node("InventorySystem")
			inventory_label.text = "Items: %d/%d" % [inventory.get_used_slots(), inventory.max_slots]

## Public API
func set_demo(demo_name: String) -> void:
	current_demo = demo_name
	_update_ui()

func show_message(message: String) -> void:
	if info_label:
		info_label.text = message
