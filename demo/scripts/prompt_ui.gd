extends CanvasLayer

@onready var input: LineEdit = $VBoxContainer/Panel/MarginContainer/VBox/Input
@onready var output: RichTextLabel = $VBoxContainer/Panel/MarginContainer/VBox/Output
@onready var panel: PanelContainer = $VBoxContainer/Panel

var is_open := false
var is_processing := false

func _ready() -> void:
	visible = false
	input.text_submitted.connect(_on_submit)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle()

func toggle() -> void:
	is_open = not is_open
	visible = is_open
	if is_open:
		input.grab_focus()

func _on_submit(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	if is_processing:
		output.append_text("\nPlease wait...")
		return

	output.append_text("\n> " + text)
	input.clear()
	input.editable = false
	is_processing = true

	var result = await CommandEngine.execute(text)
	output.append_text("\n" + result)
	output.append_text("\n")

	input.editable = true
	is_processing = false
	input.grab_focus()

func log_message(msg: String) -> void:
	output.append_text("\n" + msg)
