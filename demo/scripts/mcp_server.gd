extends Node

signal command_received(command: String, args: Dictionary)
signal response_ready(response: String)

var server: TCPServer
var port: int = 8080
var clients: Array = []

func _ready() -> void:
	start_server()

func start_server() -> void:
	server = TCPServer.new()
	var error = server.listen(port)
	if error == OK:
		print("MCP Server running on port ", port)
	else:
		print("Failed to start MCP server: ", error)

func _process(_delta: float) -> void:
	if server and server.is_connection_available():
		var client = server.take_connection()
		clients.append(client)
		print("MCP Client connected")

	for i in range(clients.size() - 1, -1, -1):
		var client = clients[i]
		if client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			clients.remove_at(i)
			continue

		var available = client.get_available_bytes()
		if available > 0:
			var data = client.get_string(available)
			_process_message(client, data)

func _process_message(client: StreamPeerTCP, data: String) -> void:
	var json = JSON.new()
	if json.parse(data) != OK:
		_send_response(client, {"error": "Invalid JSON"})
		return

	var message = json.data
	var method = message.get("method", "")
	var params = message.get("params", {})
	var id = message.get("id", 0)

	var result = _handle_method(method, params)
	_send_response(client, {"id": id, "result": result})

func _handle_method(method: String, params: Dictionary) -> Dictionary:
	match method:
		"get_player_info":
			return _get_player_info()
		"spawn":
			return _spawn(params)
		"remove":
			return _remove(params)
		"set_property":
			return _set_property(params)
		"get_property":
			return _get_property(params)
		"get_level_info":
			return _get_level_info()
		_:
			return {"error": "Unknown method: " + method}

func _get_player_info() -> Dictionary:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return {"error": "No player found"}
	return {
		"position": {"x": player.global_position.x, "y": player.global_position.y},
		"velocity": {"x": player.velocity.x, "y": player.velocity.y},
		"is_dead": player.is_dead
	}

func _spawn(params: Dictionary) -> Dictionary:
	var type = params.get("type", "")
	var scene = get_tree().get_first_node_in_group("player")
	if not scene:
		return {"error": "No player found"}

	var pos = scene.global_position + Vector2(100, 0)

	match type:
		"enemy":
			var e = preload("res://scenes/enemy_2d.tscn").instantiate()
			e.global_position = pos
			scene.get_parent().get_node("Enemies").add_child(e)
			return {"success": true, "message": "Spawned enemy"}
		"coin":
			var c = preload("res://scenes/coin_2d.tscn").instantiate()
			c.global_position = pos + Vector2(0, -30)
			scene.get_parent().get_node("Coins").add_child(c)
			return {"success": true, "message": "Spawned coin"}
		_:
			return {"error": "Unknown type: " + type}

func _remove(params: Dictionary) -> Dictionary:
	var type = params.get("type", "")
	var group = type
	var count = 0
	for node in get_tree().get_nodes_in_group(group):
		node.queue_free()
		count += 1
	return {"success": true, "removed": count}

func _set_property(params: Dictionary) -> Dictionary:
	var prop = params.get("property", "")
	var value = params.get("value", 0)
	var scene = get_tree().get_first_node_in_group("player")
	if not scene:
		return {"error": "No player found"}

	match prop:
		"speed":
			scene.SPEED = value
			return {"success": true}
		"jump":
			scene.JUMP_VELOCITY = value
			return {"success": true}
		_:
			return {"error": "Unknown property"}

func _get_property(params: Dictionary) -> Dictionary:
	var prop = params.get("property", "")
	var scene = get_tree().get_first_node_in_group("player")
	if not scene:
		return {"error": "No player found"}

	match prop:
		"speed": return {"value": scene.SPEED}
		"jump": return {"value": scene.JUMP_VELOCITY}
		"pos": return {"x": scene.global_position.x, "y": scene.global_position.y}
		_: return {"error": "Unknown property"}

func _get_level_info() -> Dictionary:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var coins = get_tree().get_nodes_in_group("coin")
	return {
		"enemies": enemies.size(),
		"coins": coins.size(),
		"level": "World 1-1"
	}

func _send_response(client: StreamPeerTCP, data: Dictionary) -> void:
	var json = JSON.stringify(data)
	client.put_string(json)

func send_command(method: String, params: Dictionary = {}) -> void:
	for client in clients:
		if client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			var message = {"method": method, "params": params}
			_send_response(client, message)
