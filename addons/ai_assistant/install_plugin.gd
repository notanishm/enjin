@tool
extends EditorScript

func _run() -> void:
	var plugin_path = "res://addons/ai_assistant"
	var dir = DirAccess.open("res://")

	if not dir.dir_exists(plugin_path):
		dir.make_dir_recursive(plugin_path)

	_copy_plugin_files()

	var config = ConfigFile.new()
	var err = config.load("res://project.godot")
	if err == OK:
		var plugins = config.get_value("editor_plugins", "enabled", [])
		if not plugins.has("res://addons/ai_assistant/plugin.cfg"):
			plugins.append("res://addons/ai_assistant/plugin.cfg")
			config.set_value("editor_plugins", "enabled", plugins)
			config.save("res://project.godot")
			print("[AI Assistant] Plugin enabled in project settings")
	else:
		print("[AI Assistant] Could not load project.godot")

	print("[AI Assistant] Installation complete!")
	print("[AI Assistant] Restart Godot to activate the plugin.")

func _copy_plugin_files() -> void:
	var files = {
		"plugin.cfg": _get_plugin_cfg(),
		"plugin.gd": _get_plugin_gd(),
		"ai_panel.gd": _get_panel_gd(),
		"ai_panel.tscn": _get_panel_tscn(),
		"settings_dialog.gd": _get_settings_gd(),
		"settings_dialog.tscn": _get_settings_tscn()
	}

	for file_name in files:
		var file = FileAccess.open("res://addons/ai_assistant/" + file_name, FileAccess.WRITE)
		if file:
			file.store_string(files[file_name])
			file.close()

func _get_plugin_cfg() -> String:
	return """[plugin]

name="AI Game Assistant"
description="Jev + LLM powered AI assistant for game development"
author="Capability Corpus"
version="1.0.0"
script="plugin.gd"
"""

func _get_plugin_gd() -> String:
	return """@tool
extends EditorPlugin

var panel: Control

func _enter_tree() -> void:
	panel = preload("res://addons/ai_assistant/ai_panel.tscn").instantiate()
	add_control_to_bottom_panel(panel, "AI Assistant")
	add_tool_menu_item("AI Assistant Settings", _open_settings)

func _exit_tree() -> void:
	if panel:
		remove_control_from_bottom_panel(panel)
		panel.queue_free()
	remove_tool_menu_item("AI Assistant Settings")

func _open_settings() -> void:
	var settings = preload("res://addons/ai_assistant/settings_dialog.tscn").instantiate()
	EditorInterface.get_base_control().add_child(settings)
	settings.popup_centered()
"""

func _get_panel_gd() -> String:
	return """@tool
extends Control

@onready var output: RichTextLabel = $VBoxContainer/Output
@onready var input: LineEdit = $VBoxContainer/InputRow/LineEdit
@onready var send_btn: Button = $VBoxContainer/InputRow/SendBtn
@onready var clear_btn: Button = $VBoxContainer/TopRow/ClearBtn
@onready var settings_btn: Button = $VBoxContainer/TopRow/SettingsBtn

var jev_key: String = ""
var llm_key: String = ""
var llm_provider: String = "openai"
var is_processing: bool = false

func _ready() -> void:
	send_btn.pressed.connect(_on_send)
	input.text_submitted.connect(_on_send)
	clear_btn.pressed.connect(_on_clear)
	settings_btn.pressed.connect(_on_settings)
	_load_settings()
	output.append_text("[AI Assistant] Ready. Enter your prompt below.\\n")

func _on_send(text: String = "") -> void:
	var prompt = text if not text.is_empty() else input.text
	if prompt.strip_edges().is_empty():
		return
	if is_processing:
		return

	input.clear()
	is_processing = true
	send_btn.disabled = true

	output.append_text("\\n> " + prompt + "\\n")
	output.append_text("[JEV] Classifying...\\n")

	var classification = await _classify(prompt)

	if classification.has("error"):
		output.append_text("[ERROR] " + classification["error"] + "\\n")
		_reset()
		return

	var action = classification["action"]
	output.append_text("[JEV] Action: " + action + "\\n")

	var command = await _generate_command(prompt, action)
	output.append_text("[LLM] Command: " + command + "\\n")

	output.append_text("[EXEC] Running...\\n")
	var result = _execute_command(command)
	output.append_text(result + "\\n")

	_reset()

func _reset() -> void:
	is_processing = false
	send_btn.disabled = false
	input.grab_focus()

func _on_clear() -> void:
	output.clear()
	output.append_text("[AI Assistant] Cleared.\\n")

func _on_settings() -> void:
	var dialog = preload("res://addons/ai_assistant/settings_dialog.tscn").instantiate()
	add_child(dialog)
	dialog.popup_centered()

func _classify(prompt: String) -> Dictionary:
	if jev_key.is_empty():
		return {"error": "No Jev API key. Open Settings to add."}

	var url = "https://api.typesafe.ai/v1/systemone"

	var body = {
		"model": "jev-1.13.0",
		"state": prompt,
		"questions": {
			"action": {
				"type": "choice",
				"instructions": "What game development action should be taken?",
				"criteria": {
					"add_node": "Add a node to the scene",
					"modify_node": "Change properties of existing nodes",
					"create_script": "Generate GDScript code",
					"fix_error": "Fix a code error",
					"run_scene": "Run or test the current scene",
					"help": "Show available commands",
					"other": "Doesn't fit predefined actions"
				}
			}
		}
	}

	var json_body = JSON.stringify(body)
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + jev_key
	]

	var http = HTTPRequest.new()
	http.timeout = 15
	add_child(http)

	var error = http.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		http.queue_free()
		return {"error": "Request failed"}

	var result = await http.request_completed
	http.queue_free()

	var request_result = result[0]
	var response_code = result[1]
	var response_body = result[3].get_string_from_utf8()

	if request_result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return {"error": "Jev returned " + str(response_code)}

	var json = JSON.new()
	if json.parse(response_body) != OK:
		return {"error": "Could not parse response"}

	var data = json.data
	if data.has("answers"):
		return {"action": data["answers"]["action"]["choice"]}

	return {"error": "No answers"}

func _generate_command(prompt: String, action: String) -> String:
	if llm_key.is_empty():
		return _direct_command(action)

	var system_prompt = "You are a Godot GDScript expert. Generate commands or code. Respond with ONLY the command."

	var body = {}
	var url = ""

	if llm_provider == "openai":
		body = {
			"model": "gpt-4",
			"messages": [
				{"role": "system", "content": system_prompt},
				{"role": "user", "content": prompt}
			],
			"temperature": 0.3,
			"max_tokens": 500
		}
		url = "https://api.openai.com/v1/chat/completions"
	elif llm_provider == "anthropic":
		body = {
			"model": "claude-3-sonnet-20240229",
			"max_tokens": 500,
			"system": system_prompt,
			"messages": [{"role": "user", "content": prompt}]
		}
		url = "https://api.anthropic.com/v1/messages"
	else:
		return _direct_command(action)

	var json_body = JSON.stringify(body)
	var headers = []
	if llm_provider == "openai":
		headers = ["Content-Type: application/json", "Authorization: Bearer " + llm_key]
	elif llm_provider == "anthropic":
		headers = ["Content-Type: application/json", "x-api-key: " + llm_key, "anthropic-version: 2023-06-01"]

	var http = HTTPRequest.new()
	http.timeout = 30
	add_child(http)

	var error = http.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		http.queue_free()
		return _direct_command(action)

	var result = await http.request_completed
	http.queue_free()

	var request_result = result[0]
	var response_code = result[1]
	var response_body = result[3].get_string_from_utf8()

	if request_result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return _direct_command(action)

	var json = JSON.new()
	if json.parse(response_body) != OK:
		return _direct_command(action)

	var data = json.data
	if llm_provider == "openai" and data.has("choices"):
		return String(data["choices"][0]["message"]["content"]).strip_edges()
	elif llm_provider == "anthropic" and data.has("content"):
		return String(data["content"][0]["text"]).strip_edges()

	return _direct_command(action)

func _direct_command(action: String) -> String:
	match action:
		"add_node": return "Add a new node"
		"modify_node": return "Modify selected node"
		"create_script": return "Create new script"
		"fix_error": return "Fix the error"
		"run_scene": return "Run current scene"
		"help": return "Show help"
		_: return "Execute: " + action

func _execute_command(command: String) -> String:
	if command.begins_with("Add"):
		var node_type = command.replace("Add a new ", "").strip_edges()
		if node_type.is_empty():
			node_type = "Node3D"
		var scene_root = EditorInterface.get_edited_scene_root()
		if scene_root:
			var node = Node.new()
			node.name = node_type
			scene_root.add_child(node)
			node.owner = scene_root
			return "Added " + node_type
		return "No scene open"
	elif command.begins_with("Run"):
		EditorInterface.play_main_scene()
		return "Running scene..."
	elif command.begins_with("Create"):
		return "Create script: " + command
	return "Command: " + command

func _load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://ai_assistant_settings.cfg")
	if err == OK:
		jev_key = config.get_value("api", "jev_key", "")
		llm_key = config.get_value("api", "llm_key", "")
		llm_provider = config.get_value("api", "llm_provider", "openai")

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("api", "jev_key", jev_key)
	config.set_value("api", "llm_key", llm_key)
	config.set_value("api", "llm_provider", llm_provider)
	config.save("user://ai_assistant_settings.cfg")
"""

func _get_panel_tscn() -> String:
	return """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://addons/ai_assistant/ai_panel.gd" id="1"]

[node name="AIAssistant" type="Control"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="VBoxContainer" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0

[node name="TopRow" type="HBoxContainer" parent="VBoxContainer"]
layout_mode = 2

[node name="Title" type="Label" parent="VBoxContainer/TopRow"]
layout_mode = 2
size_flags_horizontal = 3
text = "AI Assistant"

[node name="ClearBtn" type="Button" parent="VBoxContainer/TopRow"]
layout_mode = 2
text = "Clear"

[node name="SettingsBtn" type="Button" parent="VBoxContainer/TopRow"]
layout_mode = 2
text = "Settings"

[node name="HSep" type="HSeparator" parent="VBoxContainer"]
layout_mode = 2

[node name="Output" type="RichTextLabel" parent="VBoxContainer"]
layout_mode = 2
size_flags_vertical = 3
scroll_following = true

[node name="HSep2" type="HSeparator" parent="VBoxContainer"]
layout_mode = 2

[node name="InputRow" type="HBoxContainer" parent="VBoxContainer"]
layout_mode = 2

[node name="LineEdit" type="LineEdit" parent="VBoxContainer/InputRow"]
layout_mode = 2
size_flags_horizontal = 3
placeholder_text = "Enter prompt..."

[node name="SendBtn" type="Button" parent="VBoxContainer/InputRow"]
layout_mode = 2
text = "Send"
"""

func _get_settings_gd() -> String:
	return """@tool
extends Window

@onready var jev_key_input: LineEdit = $VBoxContainer/JevKeyRow/LineEdit
@onready var llm_key_input: LineEdit = $VBoxContainer/LLMKeyRow/LineEdit
@onready var provider_option: OptionButton = $VBoxContainer/ProviderRow/OptionButton
@onready var save_btn: Button = $VBoxContainer/SaveBtn
@onready var status_label: Label = $VBoxContainer/Status

func _ready() -> void:
	save_btn.pressed.connect(_on_save)
	provider_option.add_item("OpenAI", 0)
	provider_option.add_item("Anthropic", 1)
	provider_option.add_item("Direct", 2)
	_load_settings()

func _on_save() -> void:
	var config = ConfigFile.new()
	config.set_value("api", "jev_key", jev_key_input.text.strip_edges())
	config.set_value("api", "llm_key", llm_key_input.text.strip_edges())
	var provider_text = provider_option.get_item_text(provider_option.selected)
	match provider_text:
		"OpenAI": config.set_value("api", "llm_provider", "openai")
		"Anthropic": config.set_value("api", "llm_provider", "anthropic")
		_: config.set_value("api", "llm_provider", "direct")
	config.save("user://ai_assistant_settings.cfg")
	status_label.text = "Saved!"
	status_label.modulate = Color(0, 1, 0)

func _load_settings() -> void:
	var config = ConfigFile.new()
	if config.load("user://ai_assistant_settings.cfg") == OK:
		jev_key_input.text = config.get_value("api", "jev_key", "")
		llm_key_input.text = config.get_value("api", "llm_key", "")
"""

func _get_settings_tscn() -> String:
	return """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://addons/ai_assistant/settings_dialog.gd" id="1"]

[node name="SettingsDialog" type="Window"]
title = "AI Assistant Settings"
size = Vector2i(400, 300)
script = ExtResource("1")

[node name="VBoxContainer" type="VBoxContainer" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0

[node name="Title" type="Label" parent="VBoxContainer"]
layout_mode = 2
text = "AI Assistant Settings"
horizontal_alignment = 1

[node name="HSep" type="HSeparator" parent="VBoxContainer"]
layout_mode = 2

[node name="JevLabel" type="Label" parent="VBoxContainer"]
layout_mode = 2
text = "Jev API Key:"

[node name="JevKeyRow" type="HBoxContainer" parent="VBoxContainer"]
layout_mode = 2

[node name="LineEdit" type="LineEdit" parent="VBoxContainer/JevKeyRow"]
layout_mode = 2
size_flags_horizontal = 3
secret = true

[node name="LLMLabel" type="Label" parent="VBoxContainer"]
layout_mode = 2
text = "LLM API Key:"

[node name="LLMKeyRow" type="HBoxContainer" parent="VBoxContainer"]
layout_mode = 2

[node name="LineEdit" type="LineEdit" parent="VBoxContainer/LLMKeyRow"]
layout_mode = 2
size_flags_horizontal = 3
secret = true

[node name="ProviderLabel" type="Label" parent="VBoxContainer"]
layout_mode = 2
text = "Provider:"

[node name="ProviderRow" type="HBoxContainer" parent="VBoxContainer"]
layout_mode = 2

[node name="OptionButton" type="OptionButton" parent="VBoxContainer/ProviderRow"]
layout_mode = 2

[node name="HSep2" type="HSeparator" parent="VBoxContainer"]
layout_mode = 2

[node name="SaveBtn" type="Button" parent="VBoxContainer"]
layout_mode = 2
text = "Save"

[node name="Status" type="Label" parent="VBoxContainer"]
layout_mode = 2
horizontal_alignment = 1
"""
