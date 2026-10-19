@tool
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
	provider_option.add_item("OpenRouter", 2)
	provider_option.add_item("GitHub Copilot", 3)
	provider_option.add_item("Direct (No LLM)", 4)
	_load_settings()

func _on_save() -> void:
	var panel = get_parent()
	if panel and panel.has_method("save_settings"):
		panel.jev_key = jev_key_input.text.strip_edges()
		panel.llm_key = llm_key_input.text.strip_edges()
		var provider_text = provider_option.get_item_text(provider_option.selected)
		match provider_text:
			"OpenAI": panel.llm_provider = "openai"
			"Anthropic": panel.llm_provider = "anthropic"
			"OpenRouter": panel.llm_provider = "openrouter"
			"GitHub Copilot": panel.llm_provider = "copilot"
			_: panel.llm_provider = "direct"
		panel.save_settings()
		status_label.text = "Settings saved!"
		status_label.modulate = Color(0, 1, 0)
	else:
		status_label.text = "Error: Panel not found"
		status_label.modulate = Color(1, 0, 0)

func _load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://ai_assistant_settings.cfg")
	if err == OK:
		jev_key_input.text = config.get_value("api", "jev_key", "")
		llm_key_input.text = config.get_value("api", "llm_key", "")
		var provider = config.get_value("api", "llm_provider", "openai")
		match provider:
			"openai": provider_option.selected = 0
			"anthropic": provider_option.selected = 1
			"openrouter": provider_option.selected = 2
			"copilot": provider_option.selected = 3
			_: provider_option.selected = 4
