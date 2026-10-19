class_name LLMService

static var api_key: String = ""
static var base_url: String = ""
static var provider: String = ""
static var conversation_history: Array = []

static func chat(user_message: String, context: String = "", error_context: String = "") -> String:
	_ensure_loaded()

	if api_key.is_empty():
		return ""

	var system_prompt = """You are a Godot GDScript expert for a 2D platformer game.
You generate and fix GDScript code. When given an error, you fix it.

Available node types:
- CharacterBody2D (player, enemies)
- StaticBody2D (ground, blocks, platforms)
- Area2D (coins, checkpoints, triggers)
- MeshInstance2D (visuals - use QuadMesh for rectangles)
- CollisionShape2D (collision)

Available commands you can generate:
- spawn enemy at position
- spawn coin at position
- spawn block at position
- platform x y width
- set speed value
- set jump value
- teleport
- god

When fixing errors, analyze the error message and provide fixed code.
Respond with ONLY the command, no markdown."""

	var messages = []
	var sys_msg = {"role": "system", "content": system_prompt}
	messages.append(sys_msg)

	for entry in conversation_history.slice(-5):
		messages.append(entry)

	var user_content = user_message
	if not context.is_empty():
		user_content += "\nContext: " + context
	if not error_context.is_empty():
		user_content += "\nError to fix: " + error_context

	var user_msg = {"role": "user", "content": user_content}
	messages.append(user_msg)

	var body = {}
	var headers = []

	if provider == "openai":
		body = {
			"model": "gpt-4",
			"messages": messages,
			"temperature": 0.3,
			"max_tokens": 500
		}
		headers = [
			"Content-Type: application/json",
			"Authorization: Bearer " + api_key
		]
		base_url = "https://api.openai.com/v1/chat/completions"
	elif provider == "anthropic":
		body = {
			"model": "claude-3-sonnet-20240229",
			"max_tokens": 500,
			"system": system_prompt,
			"messages": messages
		}
		headers = [
			"Content-Type: application/json",
			"x-api-key: " + api_key,
			"anthropic-version: 2023-06-01"
		]
		base_url = "https://api.anthropic.com/v1/messages"
	else:
		return ""

	var json_body = JSON.stringify(body)

	var http = HTTPRequest.new()
	http.timeout = 30
	Engine.get_main_loop().root.add_child(http)

	var error = http.request(base_url, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		http.queue_free()
		return ""

	var result = await http.request_completed
	http.queue_free()

	var request_result = result[0]
	var response_code = result[1]
	var response_body = result[3].get_string_from_utf8()

	if request_result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return ""

	var json = JSON.new()
	if json.parse(response_body) != OK:
		return ""

	var data = json.data
	var response_text = ""

	if provider == "openai":
		if data.has("choices") and data["choices"].size() > 0:
			response_text = String(data["choices"][0]["message"]["content"]).strip_edges()
	elif provider == "anthropic":
		if data.has("content") and data["content"].size() > 0:
			response_text = String(data["content"][0]["text"]).strip_edges()

	conversation_history.append({"role": "user", "content": user_content})
	conversation_history.append({"role": "assistant", "content": response_text})

	if conversation_history.size() > 10:
		conversation_history = conversation_history.slice(-10)

	return response_text

static func fix_error(code: String, error_msg: String) -> String:
	var prompt = "Fix this GDScript code:\n" + code + "\nError:\n" + error_msg
	return await chat(prompt)

static func generate_code(description: String, context: String = "") -> String:
	var snippet_context = _get_relevant_snippets(description)
	var prompt = "Generate command for: " + description
	if not snippet_context.is_empty():
		prompt += "\n\nReference code:\n" + snippet_context
	return await chat(prompt, context)

static func _get_relevant_snippets(description: String) -> String:
	var desc_lower = description.to_lower()
	var snippets = ""

	if "enemy" in desc_lower or "goomba" in desc_lower or "enemy" in desc_lower:
		snippets += _load_snippet("ai")
	if "coin" in desc_lower or "collect" in desc_lower:
		snippets += _load_snippet("gameplay")
	if "camera" in desc_lower:
		snippets += _load_snippet("camera")
	if "jump" in desc_lower or "move" in desc_lower or "speed" in desc_lower:
		snippets += _load_snippet("character")
	if "sound" in desc_lower or "music" in desc_lower or "audio" in desc_lower:
		snippets += _load_snippet("audio")
	if "particle" in desc_lower or "effect" in desc_lower or "vfx" in desc_lower:
		snippets += _load_snippet("vfx")

	return snippets

static func _load_snippet(category: String) -> String:
	var path = "res://code_snippets/" + category + "_snippets.md"
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		return content.left(1000)
	return ""

static func execute_direct(action: String) -> String:
	match action:
		"spawn_enemy": return "spawn enemy"
		"spawn_coin": return "spawn coin"
		"spawn_block": return "spawn block"
		"remove_entity": return "remove enemy"
		"teleport": return "teleport"
		"god_mode": return "god"
		"set_speed": return "set speed 150"
		"set_jump": return "set jump -300"
		"add_platform": return "platform 300 120 64"
		"add_camera": return "camera follow"
		"add_audio": return "audio play jump"
		"add_vfx": return "vfx dust"
		"add_ai": return "help"
		"add_interaction": return "help"
		"modify_level": return "help"
		"list_objects": return "list"
		"help": return "help"
		_: return "help"

static func _ensure_loaded() -> void:
	if api_key.is_empty():
		EnvLoader.load_env()
		var k = EnvLoader.get_value("LLM_API_KEY")
		var p = EnvLoader.get_value("LLM_PROVIDER")
		if not k.is_empty():
			api_key = k
		if not p.is_empty():
			provider = p
