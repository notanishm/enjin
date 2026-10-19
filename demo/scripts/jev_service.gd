class_name JevService

static var api_key: String = ""
static var base_url: String = "https://api.typesafe.ai"

static func classify(user_prompt: String) -> Dictionary:
	_ensure_loaded()

	if api_key.is_empty():
		return {"error": "No Jev API key"}

	var url = base_url + "/v1/systemone"

	var body = {
		"model": "jev-1.13.0",
		"state": user_prompt,
		"questions": {
			"action": {
				"type": "choice",
				"instructions": "What game action should be taken?",
				"criteria": {
					"spawn_enemy": "Add enemies to the level",
					"spawn_coin": "Add coins to the level",
					"spawn_block": "Add question blocks",
					"remove_entity": "Remove enemies, coins, or blocks",
					"teleport": "Move player to a location",
					"god_mode": "Toggle invincibility",
					"set_speed": "Change player movement speed",
					"set_jump": "Change jump height or physics",
					"add_platform": "Add floating platforms",
					"list_objects": "Show what's in the level",
					"help": "Show available commands",
					"other": "Doesn't fit predefined actions"
				}
			},
			"needs_llm": {
				"type": "noul",
				"instructions": "Does this request need custom code generation?"
			}
		}
	}

	var json_body = JSON.stringify(body)

	var http = HTTPRequest.new()
	http.timeout = 15
	Engine.get_main_loop().root.add_child(http)

	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key
	]

	var error = http.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		http.queue_free()
		return {"error": "Request failed with code " + str(error)}

	var result = await http.request_completed
	http.queue_free()

	var request_result = result[0]
	var response_code = result[1]
	var response_body = result[3].get_string_from_utf8()

	if request_result != HTTPRequest.RESULT_SUCCESS:
		return {"error": "Connection failed"}

	if response_code != 200:
		return {"error": "Jev returned " + str(response_code)}

	var json = JSON.new()
	if json.parse(response_body) != OK:
		return {"error": "Could not parse response"}

	var data = json.data
	if data.has("answers"):
		var action = data["answers"]["action"]["choice"]
		var needs_llm = data["answers"]["needs_llm"]["noul"] > 0.5
		var complexity = data["answers"]["complexity"]["score"]
		return {"action": action, "needs_llm": needs_llm, "complexity": complexity}

	return {"error": "No answers"}

static func _ensure_loaded() -> void:
	if api_key.is_empty():
		EnvLoader.load_env()
		var k = EnvLoader.get_value("JEV_API_KEY")
		if not k.is_empty():
			api_key = k
