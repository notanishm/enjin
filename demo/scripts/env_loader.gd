class_name EnvLoader

static var _env: Dictionary = {}

static func load_env(path: String = "res://.env") -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("Could not open .env file")
		return

	while not file.eof_reached():
		var line = file.get_line()
		line = String(line)
		line = line.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var parts = line.split("=", true, 1)
		if parts.size() == 2:
			var key = String(parts[0]).strip_edges()
			var value = String(parts[1]).strip_edges()
			_env[key] = value
	file.close()

static func get_value(key: String, default: String = "") -> String:
	if _env.is_empty():
		load_env()
	return String(_env.get(key, default))
