@tool
extends EditorPlugin

var panel: Control
var dock: Control

func _enter_tree() -> void:
	_add_ai_dock()
	_add_menu_item()
	print("[AI Assistant] Plugin enabled")

func _exit_tree() -> void:
	_remove_ai_dock()
	_remove_menu_item()
	print("[AI Assistant] Plugin disabled")

func _add_ai_dock() -> void:
	panel = preload("res://addons/ai_assistant/ai_panel.tscn").instantiate()
	add_control_to_bottom_panel(panel, "AI Assistant")

func _remove_ai_dock() -> void:
	if panel:
		remove_control_from_bottom_panel(panel)
		panel.queue_free()

func _add_menu_item() -> void:
	add_tool_menu_item("AI Assistant Settings", _open_settings)

func _remove_menu_item() -> void:
	remove_tool_menu_item("AI Assistant Settings")

func _open_settings() -> void:
	var settings = preload("res://addons/ai_assistant/settings_dialog.tscn").instantiate()
	EditorInterface.get_base_control().add_child(settings)
	settings.popup_centered()
