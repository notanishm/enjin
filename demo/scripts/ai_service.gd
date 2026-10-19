class_name AIService

static var api_key: String = ""
static var base_url: String = "https://typesafe.ai"

static func chat(user_message: String, context: String = "") -> String:
	_ensure_loaded()

	if api_key.is_empty():
		return "Error: No API key configured"

	var url = base_url + "/v1/chat/completions"

	var body = {
		"model": "jev",
		"messages": [
			{"role": "system", "content": "You are an AI game assistant."},
			{"role": "user", "content": user_message}
		]
	}

	var json_body = JSON.stringify(body)

	var http = HTTPRequest.new()
	http.timeout = 30
	Engine.get_main_loop().root.add_child(http)

	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key
	]

	var error = http.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		http.queue_free()
		return "Error: Request failed"

	var result = await http.request_completed
	http.queue_free()

	var request_result = result[0]
	var response_code = result[1]
	var response_body = result[3].get_string_from_utf8()

	if request_result != HTTPRequest.RESULT_SUCCESS:
		return "Error: Connection failed"

	if response_code != 200:
		return "Error: Code " + str(response_code)

	var json = JSON.new()
	if json.parse(response_body) != OK:
		return "Error: Could not parse response"

	var data = json.data
	if data.has("choices") and data["choices"].size() > 0:
		return String(data["choices"][0]["message"]["content"])

	return "Error: No response content"

static func _ensure_loaded() -> void:
	if api_key.is_empty():
		EnvLoader.load_env()
		var k = EnvLoader.get_value("TYPESAFE_API_KEY")
		var u = EnvLoader.get_value("TYPESAFE_BASE_URL")
		if not k.is_empty():
			api_key = k
		if not u.is_empty():
			base_url = u
