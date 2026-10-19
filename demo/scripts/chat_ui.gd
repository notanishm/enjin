extends CanvasLayer

@onready var input: LineEdit = $Panel/VBox/InputRow/LineEdit
@onready var output: RichTextLabel = $Panel/VBox/Output
@onready var llm_key_input: LineEdit = $Panel/VBox/LLMKeyRow/LineEdit
@onready var llm_provider_option: OptionButton = $Panel/VBox/LLMKeyRow/OptionButton
@onready var send_btn: Button = $Panel/VBox/InputRow/SendBtn
@onready var save_btn: Button = $Panel/VBox/SaveRow/SaveBtn

var is_open := false
var is_processing := false
var last_error: String = ""

func _ready() -> void:
	visible = true
	input.text_submitted.connect(_on_submit)
	send_btn.pressed.connect(_on_send)
	save_btn.pressed.connect(_on_save_keys)
	llm_provider_option.add_item("OpenAI", 0)
	llm_provider_option.add_item("Anthropic", 1)
	llm_provider_option.add_item("Direct (No LLM)", 2)
	_load_saved_keys()
	output.append_text("\n[Jev] Key loaded from .env")
	output.append_text("\n[Ready] Paste your API key and click Save.")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle()

func toggle() -> void:
	is_open = not is_open
	visible = is_open
	if is_open:
		input.grab_focus()

func _on_save_keys() -> void:
	var llm_key = llm_key_input.text.strip_edges()
	var provider_text = llm_provider_option.get_item_text(llm_provider_option.selected)

	var config = FileAccess.open("user://llm_key.cfg", FileAccess.WRITE)
	if config:
		config.store_line(llm_key)
		config.store_line(provider_text)
		config.close()
		output.append_text("\n[OK] " + provider_text + " key saved")
		_apply_keys()
	else:
		output.append_text("\n[ERROR] Could not save")

func _load_saved_keys() -> void:
	var config = FileAccess.open("user://llm_key.cfg", FileAccess.READ)
	if config:
		var llm_key = config.get_line().strip_edges()
		var provider = config.get_line().strip_edges()
		config.close()
		if not llm_key.is_empty():
			llm_key_input.text = llm_key
		if provider == "OpenAI":
			llm_provider_option.selected = 0
		elif provider == "Anthropic":
			llm_provider_option.selected = 1
		else:
			llm_provider_option.selected = 2
		_apply_keys()

func _apply_keys() -> void:
	JevService.api_key = EnvLoader.get_value("JEV_API_KEY")
	LLMService.api_key = llm_key_input.text.strip_edges()
	var provider_text = llm_provider_option.get_item_text(llm_provider_option.selected)
	match provider_text:
		"OpenAI":
			LLMService.provider = "openai"
		"Anthropic":
			LLMService.provider = "anthropic"
		"Direct (No LLM)":
			LLMService.provider = "direct"

func _on_submit(text: String) -> void:
	_process_input(text)

func _on_send() -> void:
	_process_input(input.text)

func _process_input(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	if is_processing:
		output.append_text("\n[WAIT] Processing...")
		return
	if JevService.api_key.is_empty():
		output.append_text("\n[ERROR] Jev key not loaded")
		return

	output.append_text("\n> " + text)
	input.clear()
	input.editable = false
	send_btn.disabled = true
	is_processing = true

	output.append_text("\n[JEV] Classifying...")
	var classification = await JevService.classify(text)

	if classification.has("error"):
		output.append_text("\n[JEV ERROR] " + classification["error"])
		_reset_ui()
		return

	var action = classification["action"]
	var needs_llm = classification["needs_llm"]
	var complexity = classification.get("complexity", 1)
	output.append_text("\n[JEV] Action: " + action + " | LLM: " + str(needs_llm) + " | Level: " + str(complexity))

	var command = ""

	if LLMService.provider != "direct" and not LLMService.api_key.is_empty():
		output.append_text("\n[LLM] Generating...")
		var context = _get_game_context()

		if not last_error.is_empty():
			command = await LLMService.fix_error(command, last_error)
			last_error = ""
		else:
			command = await LLMService.generate_code(text, context)

		if command.is_empty():
			command = LLMService.execute_direct(action)
			output.append_text("\n[LLM] Fallback: " + command)
		else:
			output.append_text("\n[LLM] Generated: " + command)
	else:
		command = LLMService.execute_direct(action)
		output.append_text("\n[DIRECT] " + command)

	output.append_text("\n[EXEC] " + command)
	var result = await CommandEngine.execute(command)

	if result.begins_with("Error") or result.begins_with("Unknown"):
		last_error = result
		output.append_text("\n[ERROR] " + result)
		output.append_text("\n[LLM] Will auto-fix next request")
	else:
		output.append_text("\n" + result)

	output.append_text("\n")
	_reset_ui()

func _reset_ui() -> void:
	input.editable = true
	send_btn.disabled = false
	is_processing = false
	input.grab_focus()

func _get_game_context() -> String:
	var scene = get_tree().get_first_node_in_group("player")
	if not scene:
		return "No player in scene"
	var enemies = get_tree().get_nodes_in_group("enemy")
	var coins = get_tree().get_nodes_in_group("coin")
	return "Player pos: %s | Enemies: %d | Coins: %d" % [str(scene.global_position), enemies.size(), coins.size()]

func log_message(msg: String) -> void:
	output.append_text("\n" + msg)
