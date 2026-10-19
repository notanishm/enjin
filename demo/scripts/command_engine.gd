class_name CommandEngine

static func execute(text: String) -> String:
	var args = text.strip_edges().split(" ", false)
	if args.is_empty():
		return "No command entered"

	var cmd = args[0].to_lower()

	match cmd:
		"help":
			return _help()
		"spawn":
			return _spawn(args)
		"remove":
			return _remove(args)
		"move":
			return _move(args)
		"list":
			return _list(args)
		"set":
			return _set_prop(args)
		"get":
			return _get_prop(args)
		"clear":
			return _clear()
		"teleport":
			return _teleport(args)
		"god":
			return _god()
		"platform":
			return _add_platform(args)
		"camera":
			return _camera_action(args)
		"audio":
			return _audio_action(args)
		"vfx":
			return _vfx_action(args)
		"ai":
			return await _ai_prompt(args)
		_:
			return "Unknown command: " + cmd + ". Type 'help' for commands."

static func _help() -> String:
	return """COMMANDS:
  spawn [enemy|coin|block]  - Add entities
  remove [enemy|coin|block] - Remove entities
  platform [x] [y] [w]     - Add platform
  camera [follow|shake]     - Camera actions
  audio [play|stop] [name]  - Audio actions
  vfx [dust|trail|impact]   - Visual effects
  set [speed|jump] [value]  - Modify properties
  get [pos|speed|jump]      - Get properties
  teleport                  - Go to goal
  god                       - Toggle invincibility
  list                      - Show all objects
  help                      - Show this list"""

static func _spawn(args: Array) -> String:
	if args.size() < 2:
		return "Usage: spawn [enemy|coin|block]"
	var type = args[1].to_lower()
	var scene = get_tree().get_first_node_in_group("player")
	if not scene:
		return "No player found"

	var pos = scene.global_position + Vector2(100, 0)
	var parent = scene.get_parent()

	match type:
		"enemy":
			var e = preload("res://scenes/enemy_2d.tscn").instantiate()
			e.global_position = pos
			if parent.has_node("Enemies"):
				parent.get_node("Enemies").add_child(e)
			else:
				parent.add_child(e)
			return "Spawned enemy at " + str(pos)
		"coin":
			var c = preload("res://scenes/coin_2d.tscn").instantiate()
			c.global_position = pos + Vector2(0, -30)
			if parent.has_node("Coins"):
				parent.get_node("Coins").add_child(c)
			else:
				parent.add_child(c)
			return "Spawned coin at " + str(pos)
		"block":
			var b = preload("res://scenes/question_block_2d.tscn").instantiate()
			b.global_position = pos + Vector2(0, -40)
			if parent.has_node("Blocks"):
				parent.get_node("Blocks").add_child(b)
			else:
				parent.add_child(b)
			return "Spawned block at " + str(pos)
	return "Unknown type: " + type

static func _remove(args: Array) -> String:
	if args.size() < 2:
		return "Usage: remove [enemy|coin|block]"
	var type = args[1].to_lower()
	var group = type
	var count = 0
	for node in get_tree().get_nodes_in_group(group):
		node.queue_free()
		count += 1
	return "Removed " + str(count) + " " + type + "s"

static func _move(args: Array) -> String:
	if args.size() < 3:
		return "Usage: move [x|y] [amount]"
	var axis = args[0].to_lower()
	var amount = args[1].to_float()
	var scene = get_tree().get_first_node_in_group("player")
	if not scene:
		return "No player found"
	scene.global_position += Vector2(amount, 0) if axis == "x" else Vector2(0, amount)
	return "Moved player"

static func _list(args: Array) -> String:
	var types = ["enemy", "coin", "block"]
	var result = ""
	for t in types:
		var nodes = get_tree().get_nodes_in_group(t)
		result += t + ": " + str(nodes.size()) + "\n"
	return result

static func _set_prop(args: Array) -> String:
	if args.size() < 3:
		return "Usage: set [property] [value]"
	var prop = args[1]
	var val = args[2]
	var scene = get_tree().get_first_node_in_group("player")
	if not scene:
		return "No player found"
	match prop:
		"speed":
			scene.SPEED = val.to_float()
			return "Speed set to " + val
		"jump":
			scene.JUMP_VELOCITY = val.to_float()
			return "Jump set to " + val
	return "Unknown property: " + prop

static func _get_prop(args: Array) -> String:
	if args.size() < 2:
		return "Usage: get [property]"
	var prop = args[1]
	var scene = get_tree().get_first_node_in_group("player")
	if not scene:
		return "No player found"
	match prop:
		"speed": return "Speed: " + str(scene.SPEED)
		"jump": return "Jump: " + str(scene.JUMP_VELOCITY)
		"pos": return "Position: " + str(scene.global_position)
	return "Unknown property"

static func _clear() -> String:
	return ""

static func _teleport(args: Array) -> String:
	var scene = get_tree().get_first_node_in_group("player")
	if not scene:
		return "No player found"
	scene.global_position = Vector2(4960, 176)
	return "Teleported to goal"

static func _god() -> String:
	var scene = get_tree().get_first_node_in_group("player")
	if not scene:
		return "No player found"
	scene.is_dead = false
	scene.can_move = true
	return "God mode: You cannot die"

static func _add_platform(args: Array) -> String:
	if args.size() < 4:
		return "Usage: platform [x] [y] [width]"
	var x = args[1].to_float()
	var y = args[2].to_float()
	var w = args[3].to_float()

	var platform = StaticBody2D.new()
	platform.position = Vector2(x, y)

	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(w, 8)
	shape.shape = rect
	platform.add_child(shape)

	var mesh = MeshInstance2D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(w, 8)
	mesh.mesh = quad
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.4, 0.2)
	mesh.material_override = mat
	platform.add_child(mesh)

	var scene = get_tree().get_first_node_in_group("player")
	if scene:
		scene.get_parent().add_child(platform)
	return "Added platform at " + str(x) + "," + str(y)

static func _camera_action(args: Array) -> String:
	if args.size() < 2:
		return "Usage: camera [follow|shake]"
	var action = args[1].to_lower()
	var scene = get_tree().get_first_node_in_group("player")
	if not scene:
		return "No player found"

	match action:
		"follow":
			var cam = scene.get_node_or_null("Camera2D")
			if cam:
				return "Camera already following"
			cam = Camera2D.new()
			cam.position_smoothing_enabled = true
			cam.position_smoothing_speed = 5.0
			scene.add_child(cam)
			return "Camera now following player"
		"shake":
			return "Camera shake not implemented yet"
	return "Unknown camera action"

static func _audio_action(args: Array) -> String:
	if args.size() < 3:
		return "Usage: audio [play|stop] [name]"
	return "Audio system not implemented yet"

static func _vfx_action(args: Array) -> String:
	if args.size() < 2:
		return "Usage: vfx [dust|trail|impact]"
	return "VFX system not implemented yet"

static func _ai_prompt(args: Array) -> String:
	if args.size() < 2:
		return "Usage: ai [your question or request]"
	var prompt = " ".join(args.slice(1))
	var context = _get_game_context()
	var result = await AIService.chat(prompt, context)
	return result

static func _get_game_context() -> String:
	var scene = get_tree().get_first_node_in_group("player")
	if not scene:
		return "No player in scene"
	var enemies = get_tree().get_nodes_in_group("enemy")
	var coins = get_tree().get_nodes_in_group("coin")
	return "Player pos: %s | Enemies: %d | Coins: %d" % [str(scene.global_position), enemies.size(), coins.size()]

static func get_tree() -> SceneTree:
	return Engine.get_main_loop()
