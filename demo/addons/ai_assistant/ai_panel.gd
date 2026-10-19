@tool
extends Control

@onready var output: RichTextLabel = $VBoxContainer/Output
@onready var input: LineEdit = $VBoxContainer/InputRow/LineEdit
@onready var send_btn: Button = $VBoxContainer/InputRow/SendBtn
@onready var clear_btn: Button = $VBoxContainer/TopRow/ClearBtn
@onready var settings_btn: Button = $VBoxContainer/TopRow/SettingsBtn

var jev_key: String = ""
var llm_key: String = ""
var llm_provider: String = "openai"
var llm_model: String = ""  # optional override; empty = provider default
var is_processing: bool = false

# Session memory: what we've already built / modified (survives prompts, resets on Clear)
var session_memory: Dictionary = {
	"characters": [],      # node paths of characters we made/found
	"last_character": "",  # node path of the active/target character
	"skills_applied": {},  # character path -> [skill names]
	"created": [],         # labels of things created this session
	"history": [],         # recent prompts for context
	"objects": [],         # [{path, name, hint}] visual nodes we can modify
	"last_object": "",     # last object modified/created (for "it"/"that" follow-ups)
}

func _ready() -> void:
	send_btn.pressed.connect(_on_send)
	input.text_submitted.connect(_on_send)
	clear_btn.pressed.connect(_on_clear)
	settings_btn.pressed.connect(_on_settings)
	_load_settings()
	output.append_text("[AI Assistant] Ready. Enter your prompt below.\n")

func _on_send(text: String = "") -> void:
	var prompt = text if not text.is_empty() else input.text
	if prompt.strip_edges().is_empty():
		return
	if is_processing:
		return

	input.clear()
	is_processing = true
	send_btn.disabled = true

	# Keep memory in sync with the actual open scene (user may edit manually)
	_refresh_scene_memory()

	session_memory["history"].append(prompt)
	if session_memory["history"].size() > 20:
		session_memory["history"].pop_front()

	output.append_text("\n> " + prompt + "\n")
	if session_memory["last_character"] != "":
		output.append_text("[MEM] Active character: " + session_memory["last_character"] + "\n")
	if session_memory["skills_applied"].size() > 0:
		var skill_summary := []
		for path in session_memory["skills_applied"]:
			skill_summary.append(path.get_file() + ": " + ", ".join(session_memory["skills_applied"][path]))
		output.append_text("[MEM] Skills: " + "; ".join(skill_summary) + "\n")

	# Shortcuts that don't need the pipeline
	var p := prompt.strip_edges().to_lower()
	if p == "help":
		output.append_text(_help_text() + "\n")
		_reset()
		return
	if p == "list":
		output.append_text(_execute_command("List") + "\n")
		_reset()
		return
	if p == "clear":
		_on_clear()
		_reset()
		return

	# Both keys are equally important — fail fast with a clear message
	var llm_ok := llm_provider == "copilot" or (not llm_key.is_empty() and llm_provider in ["openai", "anthropic", "openrouter"])
	if not llm_ok:
		output.append_text("[ERROR] LLM API key required (Settings -> provider + key).\n")
		_reset()
		return
	if jev_key.is_empty():
		output.append_text("[ERROR] Jev API key required (Settings).\n")
		_reset()
		return

	# --- Layer 1: LLM planner ---
	output.append_text("[PLAN] LLM planning task(s)...\n")
	var tasks = await _plan_tasks(prompt)
	if tasks.size() == 1 and tasks[0].has("clarify"):
		output.append_text("[PLAN] Need more info: " + str(tasks[0]["clarify"]) + "\n")
		_reset()
		return
	if tasks.size() == 1 and tasks[0].has("error"):
		output.append_text("[ERROR] " + tasks[0]["error"] + "\n")
		_reset()
		return
	if tasks.is_empty():
		output.append_text("[PLAN] No actionable tasks recognized. Type 'help' for examples.\n")
		_reset()
		return
	for t in tasks:
		output.append_text("[PLAN] %s / %s (target: %s)\n" % [t["skillset"], t["skill"], t.get("target", "?")])

	# --- Layer 2: Jev validation (single batched call) ---
	output.append_text("[JEV] Validating %d task(s)...\n" % tasks.size())
	tasks = await _validate_tasks(tasks)
	if tasks.size() == 1 and tasks[0].has("error"):
		output.append_text("[ERROR] " + tasks[0]["error"] + "\n")
		_reset()
		return
	for t in tasks:
		if t.get("corrected", false):
			output.append_text("[JEV] task adjusted: %s -> %s\n" % [t.get("llm_skill", "?"), t["skill"]])
		elif t.get("validated", false):
			output.append_text("[JEV] confirmed: %s\n" % t["skill"])

	# --- Layer 3: local executors ---
	var intents = _tasks_to_intents(tasks)
	if intents.is_empty():
		output.append_text("[EXEC] Nothing to execute.\n")
		_reset()
		return
	for intent in intents:
		output.append_text("[INTENT] " + str(intent.get("label", intent.get("kind", "?"))) + "\n")
		output.append_text("[EXEC] Building...\n")
		var result = _build_intent(intent)
		output.append_text(result + "\n")

	_reset()

func _reset() -> void:
	is_processing = false
	send_btn.disabled = false
	input.grab_focus()

func output_append_note(text: String) -> void:
	if output:
		output.append_text(text)

func _on_clear() -> void:
	output.clear()
	session_memory = {
		"characters": [],
		"last_character": "",
		"skills_applied": {},
		"created": [],
		"history": [],
		"objects": [],
		"last_object": "",
	}
	output.append_text("[AI Assistant] Cleared (memory reset).\n")

func _on_settings() -> void:
	var dialog = preload("res://addons/ai_assistant/settings_dialog.tscn").instantiate()
	add_child(dialog)
	dialog.popup_centered()

# --- Semantic intent resolution -------------------------------------------------
# Maps what the USER means (cube, walkable surface, playable character...)
# to complete prefab builders, not just bare node classes.

func _resolve_intent(prompt: String, action: String) -> Dictionary:
	var p = prompt.to_lower()
	var wants_3d := _wants_3d(p)
	var wants_2d := _wants_2d(p)
	# Default dimension: 3D for props/surfaces/characters unless 2D hinted
	if not wants_3d and not wants_2d:
		wants_3d = true
	var dim := 3 if wants_3d else 2

	# --- Skills on EXISTING objects (checked FIRST so we never spawn a duplicate) ---
	if action == "apply_skill" or _looks_like_skill_request(p):
		var skill = _resolve_skill(p)
		if not skill.is_empty():
			return skill
		# skill request but no matching skill - fall through

	# --- Characters (only spawn if user explicitly wants a NEW one and none usable) ---
	var is_character_spawn_word := _any(p, ["spawn", "create", "add", "make", "new", "give me", "put"])
	var existing_char := _find_target_character()

	if _any(p, ["playable character", "player character", "player", "avatar", "hero", "main character"]):
		# If they already have a character and aren't explicitly asking for a new one, target it
		if existing_char != "" and not _any(p, ["another", "new player", "second", "extra", "new character", "another character", "new npc"]):
			return {"kind": "focus_character", "target": existing_char, "label": "Using existing character: " + existing_char.get_file()}
		return {"kind": "character", "role": "player", "dim": dim, "label": "Playable character (%dD)" % dim}
	if _any(p, ["npc", "enemy", "mob", "creature", "villager", "guard", "bot", "ai character", "hostile"]):
		if existing_char != "" and not _any(p, ["another", "new npc", "second", "extra", "another enemy", "another npc"]):
			return {"kind": "focus_character", "target": existing_char, "label": "Using existing character: " + existing_char.get_file()}
		return {"kind": "character", "role": "npc", "dim": dim, "label": "NPC/Enemy (%dD)" % dim}
	if _any(p, ["character", "person", "guy", "doll"]) and is_character_spawn_word:
		if existing_char != "" and not _any(p, ["another", "new", "second", "extra"]):
			return {"kind": "focus_character", "target": existing_char, "label": "Using existing character: " + existing_char.get_file()}
		return {"kind": "character", "role": "player", "dim": dim, "label": "Character (%dD)" % dim}

	# --- Walkable surfaces ---
	if _any(p, ["walkable", "walk on", "ground", "floor", "terrain", "platform", "surface to walk",
			"ground plane", "floor plane", "base plate", "ground level"]):
		return {"kind": "surface", "shape": _surface_shape(p), "dim": dim, "label": "Walkable surface (%dD)" % dim}
	if _any(p, ["ceiling"]):
		return {"kind": "surface", "shape": "box", "dim": dim, "ceiling": true, "label": "Ceiling (%dD)" % dim}
	if _any(p, ["ramp", "slope", "stairs", "staircase"]):
		return {"kind": "surface", "shape": "ramp", "dim": dim, "label": "Ramp/stairs (%dD)" % dim}
	if _any(p, ["wall", "barrier", "fence"]):
		return {"kind": "surface", "shape": "wall", "dim": dim, "label": "Wall (%dD)" % dim}

	# --- Props / mesh shapes ---
	# NOTE: skill/camera requests must be matched BEFORE props so
	# "camera lookaround" doesn't false-positive on "round" -> sphere.
	var shape := ""
	if _any(p, ["cube", "box", "crate", "block", "rectangular", "rect "]):
		shape = "box"
	elif _any(p, ["sphere", "ball", "orb", "globe"]) or (_any(p, ["round"]) and not _any(p, ["look", "camera", "around"])):
		shape = "sphere"
	elif _any(p, ["cylinder", "pipe", "column", "pillar", "barrel", "can", "tube"]):
		shape = "cylinder"
	elif _any(p, ["capsule", "pill", "pills"]):
		shape = "capsule"
	elif _any(p, ["plane", "quad", "sheet", "flat"]):
		shape = "plane"
	elif _any(p, ["cone", "spike"]):
		shape = "cone"
	elif _any(p, ["tree"]):
		return {"kind": "prop", "shape": "tree", "dim": dim, "label": "Tree (%dD)" % dim}
	elif _any(p, ["rock", "stone", "boulder"]):
		return {"kind": "prop", "shape": "rock", "dim": dim, "label": "Rock (%dD)" % dim}
	elif _any(p, ["water"]):
		return {"kind": "environment", "element": "water", "dim": dim, "label": "Water (%dD)" % dim}

	if not shape.is_empty():
		return {"kind": "prop", "shape": shape, "dim": dim, "label": "%s prop (%dD)" % [shape.capitalize(), dim]}

	# --- Environment ---
	if _any(p, ["sun", "directional light", "daylight"]):
		return {"kind": "environment", "element": "sun", "dim": dim, "label": "Sun light (%dD)" % dim}
	if _any(p, ["light", "lamp", "lantern", "point light"]):
		return {"kind": "environment", "element": "light", "dim": dim, "label": "Light (%dD)" % dim}
	if _any(p, ["camera"]):
		return {"kind": "environment", "element": "camera", "dim": dim, "label": "Camera (%dD)" % dim}
	if _any(p, ["sky", "environment", "world environment", "fog"]):
		return {"kind": "environment", "element": "world", "dim": dim, "label": "World environment (%dD)" % dim}

	# --- Particles / VFX ---
	if _any(p, ["particle", "fire", "smoke", "explosion", "spark", "rain", "snow", "dust", "magic"]):
		var vfx := "fire"
		if "smoke" in p: vfx = "smoke"
		elif "rain" in p: vfx = "rain"
		elif "snow" in p: vfx = "snow"
		elif "explosion" in p or "spark" in p: vfx = "sparks"
		elif "magic" in p: vfx = "magic"
		return {"kind": "particles", "effect": vfx, "dim": dim, "label": "Particles: " + vfx + " (%dD)" % dim}

	# --- Scene creation ---
	if action == "create_scene" or _any(p, ["new scene", "create scene", "start a scene", "empty scene"]):
		if _any(p, ["ui", "menu", "interface", "control"]):
			return {"kind": "scene", "root": "Control", "label": "UI scene"}
		return {"kind": "scene", "root": "Node3D" if wants_3d else "Node2D", "label": "%dD scene" % dim}

	return {}

# --- Scene / session memory ------------------------------------------------------

func _refresh_scene_memory() -> void:
	var root = EditorInterface.get_edited_scene_root()
	if root == null:
		return
	var found: Array[String] = []
	_scan_for_characters(root, found)
	session_memory["characters"] = found
	# Drop stale paths
	if session_memory["last_character"] != "" and not session_memory["last_character"] in found:
		session_memory["last_character"] = found[0] if found.size() > 0 else ""
	# Keep skill entries only for living nodes
	var alive := {}
	for path in session_memory["skills_applied"]:
		if root.has_node(NodePath(_rel_path(path, root))):
			alive[path] = session_memory["skills_applied"][path]
	session_memory["skills_applied"] = alive
	# Index visual objects for resize/placement targeting
	var objs: Array[Dictionary] = []
	_scan_for_objects(root, root, objs)
	session_memory["objects"] = objs
	if session_memory["last_object"] != "" and not _object_path_exists(session_memory["last_object"], objs):
		session_memory["last_object"] = ""

func _object_path_exists(path: String, objs: Array) -> bool:
	for o in objs:
		if o["path"] == path:
			return true
	return false

func _scan_for_objects(node: Node, root: Node, out: Array[Dictionary]) -> void:
	if node != root and _is_visual_object(node):
		# Meshes that belong to a character body are parts, not standalone targets
		var parent := node.get_parent()
		if parent != null and (parent is CharacterBody2D or parent is CharacterBody3D
				or parent is RigidBody2D or parent is RigidBody3D):
			return
		var rel := str(root.get_path_to(node))
		if rel.begins_with("../"):
			rel = str(node.get_path())
		out.append({"path": rel, "name": node.name, "hint": _object_shape_hint(node)})
		return  # children are parts of this object, not separate targets
	for c in node.get_children():
		_scan_for_objects(c, root, out)

func _is_visual_object(node: Node) -> bool:
	if node is MeshInstance3D or node is Node3D and node.get_script() == null and _node_has_mesh_child(node):
		return true
	if node is MeshInstance2D or node is Node2D and _node_has_visual_child(node):
		return true
	return false

func _node_has_mesh_child(node: Node) -> bool:
	for c in node.get_children():
		if c is MeshInstance3D:
			return true
	return false

func _node_has_visual_child(node: Node) -> bool:
	for c in node.get_children():
		if c is MeshInstance2D or c is Polygon2D or c is Sprite2D:
			return true
	return false

# Cheap shape classification from node name + mesh types (used for "the sphere" targeting)
func _object_shape_hint(node: Node) -> String:
	var n := str(node.name).to_lower()
	for probe in ["sphere", "ball", "orb", "cube", "box", "crate", "block", "cylinder",
			"capsule", "plane", "cone", "tree", "rock", "wall", "floor", "ground",
			"ramp", "platform", "player", "npc", "light", "camera"]:
		if probe in n:
			return probe
	# Fall back to mesh class of first mesh child
	var mesh := _find_child_of_type(node, "MeshInstance3D")
	if mesh and mesh.mesh != null:
		var mn := str(mesh.mesh.get_class()).to_lower()
		if "sphere" in mn: return "sphere"
		if "box" in mn or "prism" in mn and "box" in mn: return "box"
		if "cylinder" in mn: return "cylinder"
		if "capsule" in mn: return "capsule"
		if "plane" in mn: return "plane"
		if "cone" in mn: return "cone"
	var mesh2 := _find_child_of_type(node, "MeshInstance2D")
	if mesh2 and mesh2.mesh != null:
		var mn2 := str(mesh2.mesh.get_class()).to_lower()
		if "circle" in mn2 or "sphere" in mn2: return "sphere"
		if "rect" in mn2: return "box"
	return ""

func _rel_path(abs_or_rel: String, root: Node) -> String:
	# session stores paths relative to scene root when possible
	return abs_or_rel

func _scan_for_characters(node: Node, out: Array[String]) -> void:
	if node is CharacterBody2D or node is CharacterBody3D or node is RigidBody2D or node is RigidBody3D:
		var path := str(node.get_path())
		# Prefer relative path from scene root
		var root = EditorInterface.get_edited_scene_root()
		if root and node != root:
			var rel = str(root.get_path_to(node))
			if rel.begins_with("../"):
				path = str(node.get_path())
			else:
				path = rel
		out.append(path)
	for c in node.get_children():
		_scan_for_characters(c, out)

func _find_target_character() -> String:
	_refresh_scene_memory()
	if session_memory["last_character"] != "":
		var root = EditorInterface.get_edited_scene_root()
		if root and root.has_node(NodePath(session_memory["last_character"])):
			return session_memory["last_character"]
	var chars: Array = session_memory["characters"]
	if chars.size() > 0:
		# Prefer one named Player or containing "player"
		for c in chars:
			if "player" in str(c).to_lower():
				session_memory["last_character"] = c
				return c
		session_memory["last_character"] = chars[0]
		return chars[0]
	return ""

func _resolve_node(path: String) -> Node:
	var root = EditorInterface.get_edited_scene_root()
	if root == null:
		return null
	if root.has_node(NodePath(path)):
		return root.get_node(NodePath(path))
	# Try absolute
	var n = get_node_or_null(NodePath(path))
	if n:
		return n
	# Search by name
	return _find_by_name(root, path.get_file())

func _find_by_name(node: Node, name_lower: String) -> Node:
	if node.name.to_lower() == name_lower.to_lower():
		return node
	for c in node.get_children():
		var f = _find_by_name(c, name_lower)
		if f:
			return f
	return null

# --- Modify target resolution (resize / placement / rotate / delete) -------------
# Returns {ok, node} or {ok:false, error:"..."} with a helpful message.

func _resolve_modify_target(target: String, fragment: String) -> Dictionary:
	_refresh_scene_memory()
	var root = EditorInterface.get_edited_scene_root()
	if root == null:
		return {"ok": false, "error": "No scene open. Create or open a scene first."}
	var objs: Array = session_memory["objects"]
	if objs.is_empty():
		return {"ok": false, "error": "No objects found in this scene to modify. Spawn one first (e.g. 'add a cube')."}

	var t := target.strip_edges().to_lower()
	var frag := fragment.to_lower()

	# 1) Explicit node name/path from the planner
	if t != "" and t not in ["existing_character", "new", "existing_object", "it", "that", "this", "object", "prop"]:
		var node = _resolve_node(target)
		if node != null and _node_is_modifiable(node, root):
			return {"ok": true, "node": node}
		# Partial name match against indexed objects
		var by_name := _match_objects(target, objs)
		if by_name.size() == 1:
			node = _resolve_node(str(by_name[0]["path"]))
			if node:
				return {"ok": true, "node": node}
		if by_name.size() > 1:
			return {"ok": false, "error": "'%s' matches %d objects (%s). Say which one." % [
				target, by_name.size(), _obj_names(by_name)]}

	# 2) Shape/keyword match from the prompt fragment ("the sphere" -> Sphere)
	var hinted := _match_objects(frag, objs)
	if hinted.is_empty():
		# try target string as a hint too
		hinted = _match_objects(t, objs)
	if hinted.size() == 1:
		var n = _resolve_node(str(hinted[0]["path"]))
		if n:
			return {"ok": true, "node": n}
	if hinted.size() > 1:
		return {"ok": false, "error": "Multiple objects match (%s). Say which one, e.g. 'resize the first one' by name." % _obj_names(hinted)}

	# 3) "it" / "that" follow-up -> last object, else last character
	if t in ["it", "that", "this", "existing_character", ""] or frag.begins_with("it ") or frag.begins_with("that "):
		if session_memory["last_object"] != "":
			var lo = _resolve_node(session_memory["last_object"])
			if lo:
				return {"ok": true, "node": lo}
		var lc = _find_target_character()
		if lc != "":
			var lcn = _resolve_node(lc)
			if lcn and _node_is_modifiable(lcn, root):
				return {"ok": true, "node": lcn}

	# 4) Fallback: the most recently created object (or only object)
	if objs.size() >= 1:
		var last = _resolve_node(str(objs[objs.size() - 1]["path"]))
		if last:
			return {"ok": true, "node": last}

	return {"ok": false, "error": "Couldn't identify the object to modify. Objects in scene: " + _obj_names(objs) + ". Name one, e.g. 'make Sphere bigger'."}

func _node_is_modifiable(node: Node, root: Node) -> bool:
	return node != null and node != root and (node is Node2D or node is Node3D)

# Substring/word match of query tokens against object names + shape hints
func _match_objects(query: String, objs: Array) -> Array:
	if query.strip_edges().is_empty():
		return []
	var out: Array = []
	var q := query.to_lower()
	for o in objs:
		var name_l := str(o["name"]).to_lower()
		var hint := str(o["hint"]).to_lower()
		var matched := false
		# whole-word-ish containment
		if name_l != "" and (q.contains(name_l) or name_l.contains(q)):
			matched = true
		elif hint != "" and (q.contains(hint) or hint.contains(q)):
			matched = true
		else:
			# token overlap: any word in query (len>=3) appearing in name
			for word in q.split(" "):
				var w := word.strip_edges().trim_prefix("the ").trim_prefix("a ").trim_prefix("an ")
				if w.length() >= 3 and w in name_l:
					matched = true
					break
		if matched:
			out.append(o)
	return out

func _obj_names(objs: Array) -> String:
	var names: Array[String] = []
	for o in objs:
		names.append(str(o["name"]))
	return ", ".join(names) if names.size() else "(none)"

# --- Skill vocabulary (high-level user language -> low-level mechanics) ----------
# High level terms the user might say are mapped to concrete feature flags.

const SKILL_MOVEMENT_TERMS := [
	"movement", "move", "walking", "walk", "run", "running", "sprint", "sprinting",
	"jump", "jumping", "crouch", "crouching", "crawl", "slide", "sliding",
	"dash", "dashing", "dodge", "roll", "double jump", "doublejump", "wall jump",
	"wasd", "arrow keys", "controls", "controller", "controllable", "input",
	"locomotion", "character controller", "physics body movement", "gravity",
	"air control", "coyote", "jump buffer", "momentum", "acceleration",
	"strafe", "backpedal", "sneak", "prone", "swim", "climb", "ladder",
	"grapple", "grappling", "glide", "float", "hover", "fly", "flight",
	"grounded", "airborne", "is_on_floor", "floor detection",
]

const SKILL_CAMERA_TERMS := [
	"camera follow", "follow camera", "third person camera", "first person",
	"fps camera", "orbit camera", "look at", "mouse look", "free look",
	"camera controller", "spring arm",
	"lookaround", "look around", "camera look", "look around camera",
	"mouse lookaround", "camera orbit", "free lookaround",
]

const SKILL_ANIMATION_TERMS := [
	"animation", "animate", "walk animation", "run animation", "idle animation",
	"anim", "blend tree", "state machine animation",
]

const SKILL_ALL_TERMS := []  # filled at runtime from the above

# Single source of truth: skillset -> { skill: description }
# Consumed by the LLM planner prompt, Jev validation criteria, and local executors.
const SKILL_REGISTRY := {
	"movement": {
		"walk": "basic walking locomotion",
		"run": "running",
		"sprint": "hold-to-sprint fast movement",
		"jump": "single jump",
		"double_jump": "jump again in mid-air",
		"crouch": "crouch/sneak/duck",
		"slide": "slide while sprinting",
		"dash": "short burst dash/dodge",
		"air_control": "steer while airborne",
		"coyote_time": "brief jump grace after leaving ledge",
		"jump_buffer": "queue jump input before landing",
		"wall_jump": "jump off walls",
		"strafe": "sideways movement",
		"swim": "swimming in water",
		"climb": "climb ladders",
		"grapple": "grappling hook",
		"glide": "glide/parachute",
		"fly": "free flight, no gravity",
		"wasd": "WASD keyboard controls",
		"gravity": "apply gravity to character",
	},
	"camera": {
		"camera_follow": "camera follows the character",
		"mouse_look": "mouse look / lookaround / free look orbit",
		"fps_camera": "first person camera",
		"spring_arm": "third person orbit spring arm camera",
	},
	"animation": {
		"animation": "AnimationPlayer with basic state clips (idle/walk/run/jump...)",
	},
	"spawn_prop": {
		"box": "cube/box/crate/block",
		"sphere": "sphere/ball/orb",
		"cylinder": "cylinder/pipe/column/barrel",
		"capsule": "capsule/pill",
		"plane": "flat plane/quad",
		"cone": "cone/spike",
		"tree": "tree",
		"rock": "rock/stone/boulder",
	},
	"spawn_surface": {
		"floor": "walkable floor/ground/platform",
		"ramp": "ramp/slope/stairs",
		"wall": "wall/barrier/fence",
		"ceiling": "ceiling",
	},
	"spawn_character": {
		"player": "playable character/avatar/hero",
	},
	"spawn_npc": {
		"npc": "NPC/enemy/mob/creature",
	},
	"spawn_environment": {
		"sun": "directional sun light",
		"light": "point light/lamp",
		"camera": "camera node (no character attached)",
		"water": "water volume",
		"world": "world environment/sky/fog",
	},
	"spawn_particles": {
		"fire": "fire particles",
		"smoke": "smoke particles",
		"rain": "rain particles",
		"snow": "snow particles",
		"sparks": "explosion/spark particles",
		"magic": "magic particles",
	},
	"create_scene": {
		"new_scene": "create a new scene (specify 2D/3D/UI)",
	},
	"modify_scale": {
		"scale_up": "make an existing object bigger/larger/enlarge/increase size (relative)",
		"scale_down": "make an existing object smaller/shrink/reduce size/halve (relative)",
		"scale_to": "set an object to an absolute size/dimensions (e.g. 2 meters tall)",
		"scale_axis": "stretch/widen/flatten/elongate an object along one axis (x/y/z)",
	},
	"modify_placement": {
		"move": "move/reposition an object to a location or by an offset (left/right/up/down/forward meters)",
		"place_on": "place/put an object on top of / above / onto another object or surface",
		"align": "align an object next to / beside / centered with another object (left of, right of, between)",
		"rotate": "rotate/turn/spin an object by degrees or to face a direction",
		"delete": "delete/remove an object from the scene",
	},
}

func _looks_like_skill_request(p: String) -> bool:
	for t in SKILL_MOVEMENT_TERMS:
		if t in p:
			return true
	for t in SKILL_CAMERA_TERMS:
		if t in p:
			return true
	for t in SKILL_ANIMATION_TERMS:
		if t in p:
			return true
	# "give it X" / "make it X" patterns with capability words
	if _any(p, ["give it", "give the", "add movement", "add controls", "make it move",
			"make it walk", "make it jump", "wire up", "hook up", "implement"]):
		return true
	return false

func _resolve_skill(p: String) -> Dictionary:
	var target_path := _find_target_character()

	# Determine which skill family
	var wants_movement := false
	for t in SKILL_MOVEMENT_TERMS:
		if t in p:
			wants_movement = true
			break
	if _any(p, ["implement", "wire up", "hook up", "give it", "add controls"]) and not wants_movement:
		# vague "implement X" - check remaining skill words already did; default movement if body exists
		wants_movement = target_path != ""

	var wants_camera := false
	for t in SKILL_CAMERA_TERMS:
		if t in p:
			wants_camera = true
			break

	var wants_anim := false
	for t in SKILL_ANIMATION_TERMS:
		if t in p:
			wants_anim = true
			break

	if not wants_movement and not wants_camera and not wants_anim:
		return {}

	# If no character exists yet, CREATE one first then apply skill (single flow)
	if target_path == "":
		var dim := 3
		if _wants_2d(p):
			dim = 2
		return {
			"kind": "character_with_skill",
			"role": "player",
			"dim": dim,
			"skills": _collect_skill_flags(p, wants_movement, wants_camera, wants_anim),
			"movement": wants_movement,
			"camera": wants_camera,
			"animation": wants_anim,
			"label": "New character + " + _skill_label(wants_movement, wants_camera, wants_anim) + " (%dD)" % dim,
		}

	# Character exists -> apply skills to it (NEVER spawn another)
	var skills := _collect_skill_flags(p, wants_movement, wants_camera, wants_anim)
	return {
		"kind": "skill",
		"target": target_path,
		"skills": skills,
		"movement": wants_movement,
		"camera": wants_camera,
		"animation": wants_anim,
		"label": _skill_label(wants_movement, wants_camera, wants_anim) + " -> " + target_path.get_file(),
	}

func _skill_label(m: bool, c: bool, a: bool) -> String:
	var parts: Array[String] = []
	if m: parts.append("Movement")
	if c: parts.append("Camera")
	if a: parts.append("Animation")
	return "Skill[" + "+".join(parts) + "]" if parts.size() else "Skill"

# Parse high-level prompt into concrete movement feature flags (low-level language)
func _collect_skill_flags(p: String, movement: bool, camera: bool, anim: bool) -> Dictionary:
	var flags := {
		# Locomotion
		"walk": movement,
		"run": movement or _any(p, ["run", "sprint", "fast"]),
		"sprint": movement and _any(p, ["sprint", "run fast", "hold shift", "dash"]),
		"jump": movement,
		"double_jump": movement and _any(p, ["double jump", "doublejump", "double-jump", "two jumps"]),
		"crouch": movement and _any(p, ["crouch", "sneak", "crawl", "prone", "duck"]),
		"slide": movement and _any(p, ["slide", "sliding", "slide cancel"]),
		"dash": movement and _any(p, ["dash", "dashing", "dodge", "burst"]),
		"air_control": movement,
		"coyote_time": movement,
		"jump_buffer": movement,
		"gravity": movement,
		"floor_snap": movement,
		# Input
		"wasd": movement,
		"arrows": movement and _any(p, ["arrow"]),
		# Camera
		"camera_follow": camera,
		"mouse_look": camera and _any(p, ["mouse", "look", "orbit", "free look", "lookaround", "look around", "camera look"]),
		"fps_camera": camera and _any(p, ["first person", "fps", "first-person"]),
		"spring_arm": camera and (_any(p, ["third person", "3rd person", "orbit", "spring"]) or _any(p, ["lookaround", "look around", "mouse", "orbit"])),
		# Animation hooks (script emits signals / sets anim names)
		"animation": anim or movement,  # movement scripts drive anim even without explicit anim request
		"walk_anim": anim or movement,
		"run_anim": anim or _any(p, ["run", "sprint"]),
		"jump_anim": anim or movement,
		"idle_anim": anim or movement,
		# Extras in movement scope
		"strafe": movement and _any(p, ["strafe"]),
		"swim": movement and _any(p, ["swim", "water"]),
		"climb": movement and _any(p, ["climb", "ladder"]),
		"wall_jump": movement and _any(p, ["wall jump", "walljump"]),
		"grapple": movement and _any(p, ["grapple", "grappling", "hookshot"]),
		"glide": movement and _any(p, ["glide", "glider", "parachute"]),
		"fly": movement and _any(p, ["fly", "flight", "hover", "levitate"]),
		"no_gravity": movement and _any(p, ["no gravity", "zero gravity", "float", "weightless"]),
	}
	# Tunable params from prompt
	if _any(p, ["fast", "high speed", "speedy"]):
		flags["walk_speed"] = 12.0
		flags["sprint_speed"] = 18.0
	elif _any(p, ["slow", "casual", "walking pace"]):
		flags["walk_speed"] = 3.0
		flags["sprint_speed"] = 5.0
	else:
		flags["walk_speed"] = 6.0
		flags["sprint_speed"] = 10.0
	if _any(p, ["high jump", "big jump", "moon jump"]):
		flags["jump_velocity"] = 12.0
	elif _any(p, ["low jump", "small jump", "short hop"]):
		flags["jump_velocity"] = 4.0
	else:
		flags["jump_velocity"] = 7.0
	return flags

func _wants_3d(p: String) -> bool:
	return _any(p, ["3d", "3-d", "three dimensional", "three-dimensional", "3 dimensional"])

func _wants_2d(p: String) -> bool:
	return _any(p, ["2d", "2-d", "two dimensional", "two-dimensional", "side scroller", "platformer", "top down", "top-down"])

func _any(text: String, needles: Array) -> bool:
	for n in needles:
		if n in text:
			return true
	return false

func _surface_shape(p: String) -> String:
	if _any(p, ["circle", "round", "circular"]):
		return "cylinder"
	if _any(p, ["narrow", "plank", "beam"]):
		return "box"
	return "box"

# --- Prefab builders ------------------------------------------------------------

func _build_intent(intent: Dictionary) -> String:
	# --- Resize / placement / rotate / delete on EXISTING object ---
	if intent["kind"] == "modify":
		return _apply_modify(intent)
	# --- Skill application to EXISTING character (no spawn) ---
	if intent["kind"] == "skill":
		return _apply_skills_to(intent)
	if intent["kind"] == "focus_character":
		session_memory["last_character"] = intent.get("target", "")
		return "Active character set to: " + str(intent.get("target", "?")).get_file()
	if intent["kind"] == "character_with_skill":
		var scene_root0 = EditorInterface.get_edited_scene_root()
		var dim0: int = intent.get("dim", 3)
		if scene_root0:
			if dim0 == 3 and scene_root0 is Node2D and not (scene_root0 is Node3D):
				scene_root0 = null
			elif dim0 == 2 and scene_root0 is Node3D:
				scene_root0 = null
		if not scene_root0:
			scene_root0 = _create_new_scene("Node3D" if dim0 == 3 else "Node2D")
			if not scene_root0:
				return "Failed to create scene"
		var ch = _build_character(intent)
		ch.name = _unique_name(scene_root0, ch.name)
		scene_root0.add_child(ch)
		_set_owner_recursive(ch, scene_root0)
		# Record in memory BEFORE applying skills so _find_target_character works
		var rel = str(scene_root0.get_path_to(ch))
		session_memory["characters"].append(rel)
		session_memory["last_character"] = rel
		session_memory["created"].append(intent.get("label", ch.name))
		var skill_intent = intent.duplicate()
		skill_intent["kind"] = "skill"
		skill_intent["target"] = rel
		var skill_result = _apply_skills_to(skill_intent)
		return "Created " + ch.name + ". " + skill_result

	var scene_root = EditorInterface.get_edited_scene_root()
	var dim: int = intent.get("dim", 3)
	var wants_3d = dim == 3
	var created = false

	# Dimension mismatch -> fresh scene of correct type
	if scene_root:
		if wants_3d and scene_root is Node2D and not (scene_root is Node3D):
			scene_root = null
		elif not wants_3d and scene_root is Node3D:
			scene_root = null

	if not scene_root:
		var root_type = "Node3D" if wants_3d else "Node2D"
		if intent["kind"] == "scene":
			root_type = intent.get("root", root_type)
		scene_root = _create_new_scene(root_type)
		created = true
		if not scene_root:
			return "Failed to create scene"

	var built: Node = null
	match intent["kind"]:
		"prop":
			built = _build_prop(intent)
		"surface":
			built = _build_surface(intent)
		"character":
			built = _build_character(intent)
		"environment":
			built = _build_environment(intent)
		"particles":
			built = _build_particles(intent)
		"scene":
			return "Created new " + str(scene_root.get_class()) + " scene: " + scene_root.name

	if built == null:
		return "Failed to build " + str(intent.get("label", "object"))

	built.name = _unique_name(scene_root, built.name)
	scene_root.add_child(built)
	_set_owner_recursive(built, scene_root)

	# Track in session memory
	var rel_path = str(scene_root.get_path_to(built))
	session_memory["created"].append(intent.get("label", built.name))
	if intent["kind"] == "character":
		session_memory["characters"].append(rel_path)
		session_memory["last_character"] = rel_path
	if intent["kind"] in ["prop", "surface"]:
		session_memory["last_object"] = rel_path

	var prefix = "Created new scene and added " if created else "Added "
	return prefix + intent.get("label", built.name)

# --- Skill application ------------------------------------------------------------

func _apply_skills_to(intent: Dictionary) -> String:
	var target_path: String = intent.get("target", "")
	var node = _resolve_node(target_path)
	if node == null:
		# Last chance: refresh and retry
		_refresh_scene_memory()
		node = _resolve_node(_find_target_character())
	if node == null:
		return "No character found to apply skills to. Create a character first."

	var flags: Dictionary = intent.get("skills", {})
	var applied: Array[String] = []
	var msgs: Array[String] = []

	# Record target as active
	session_memory["last_character"] = target_path

	# --- Movement skill: generate/update controller script ---
	if intent.get("movement", false):
		var script_path = _apply_movement_script(node, flags)
		if script_path != "":
			applied.append("movement")
			msgs.append("Movement controller -> " + script_path.get_file())

	# Ensure CharacterBody (movement requires it)
	if intent.get("movement", false) and not (node is CharacterBody2D or node is CharacterBody3D):
		# Rigid/static body can't take our controller - warn but try
		msgs.append("Warning: " + node.name + " is " + node.get_class() + " (movement works best on CharacterBody)")

	# --- Camera skill ---
	if intent.get("camera", false):
		var cam_msg = _apply_camera_skill(node, flags)
		if cam_msg != "":
			applied.append("camera")
			msgs.append(cam_msg)
		# Mouse-look lives in the movement controller script — always (re)generate
		# it when camera+mouse_look is requested, even if movement wasn't asked for.
		# Force movement flags so we don't strip walk/jump from an existing controller.
		if flags.get("mouse_look", false):
			var cam_flags := flags.duplicate()
			cam_flags["movement"] = true
			for k in ["walk", "run", "jump", "air_control", "coyote_time", "jump_buffer", "gravity", "floor_snap", "wasd", "animation", "walk_anim", "jump_anim", "idle_anim"]:
				if not cam_flags.get(k, false):
					cam_flags[k] = true
			var script_path = _apply_movement_script(node, cam_flags)
			if script_path != "":
				if "movement" not in applied:
					applied.append("movement")
				msgs.append("Mouse-look controller -> " + script_path.get_file())

	# --- Animation skill: set up anim names / placeholder tree hooks ---
	if intent.get("animation", false):
		var anim_msg = _apply_animation_skill(node, flags)
		if anim_msg != "":
			applied.append("animation")
			msgs.append(anim_msg)

	# Merge into memory (don't duplicate skill names)
	if not session_memory["skills_applied"].has(target_path):
		session_memory["skills_applied"][target_path] = []
	for a in applied:
		if a not in session_memory["skills_applied"][target_path]:
			session_memory["skills_applied"][target_path].append(a)

	if msgs.is_empty():
		return "No skills applied to " + node.name
	return "Applied to " + node.name + ": " + "; ".join(msgs)

func _apply_camera_skill(node: Node, flags: Dictionary) -> String:
	var is_3d = node is Node3D
	if is_3d:
		# Find existing Camera3D under character
		var existing_cam = _find_child_of_type(node, "Camera3D")
		if existing_cam:
			# Ensure spring arm orbit setup exists for mouse look
			if flags.get("mouse_look", false) and not _find_child_of_type(node, "SpringArm3D"):
				var arm = SpringArm3D.new()
				arm.name = "SpringArm"
				arm.spring_length = 4.0
				arm.position = Vector3(0, 1.5, 0)
				var cam = Camera3D.new()
				cam.name = "Camera"
				arm.add_child(cam)
				node.add_child(arm)
				arm.owner = EditorInterface.get_edited_scene_root()
				cam.owner = EditorInterface.get_edited_scene_root()
				# Remove old standalone cam if it was direct child
				if existing_cam.get_parent() == node:
					node.remove_child(existing_cam)
					existing_cam.queue_free()
				return "Camera re-rigged under SpringArm for orbit mouse-look"
			return "Camera already present: " + existing_cam.name
		# Prefer SpringArm for third person
		if flags.get("spring_arm", true) and not flags.get("fps_camera", false):
			var arm = SpringArm3D.new()
			arm.name = "SpringArm"
			arm.spring_length = 4.0
			arm.position = Vector3(0, 1.5, 0)
			var cam = Camera3D.new()
			cam.name = "Camera"
			arm.add_child(cam)
			node.add_child(arm)
			arm.owner = EditorInterface.get_edited_scene_root()
			cam.owner = EditorInterface.get_edited_scene_root()
			return "Camera3D + SpringArm added"
		var cam2 = Camera3D.new()
		cam2.name = "Camera"
		cam2.position = Vector3(0, 1.5, 3) if not flags.get("fps_camera", false) else Vector3(0, 1.6, 0.1)
		node.add_child(cam2)
		cam2.owner = EditorInterface.get_edited_scene_root()
		return "Camera3D added"
	else:
		var existing = _find_child_of_type(node, "Camera2D")
		if existing:
			return "Camera already present: " + existing.name
		var cam = Camera2D.new()
		cam.name = "Camera"
		node.add_child(cam)
		cam.owner = EditorInterface.get_edited_scene_root()
		return "Camera2D added"

func _apply_animation_skill(node: Node, flags: Dictionary) -> String:
	# Movement script already drives animation via set("anim_state", ...) and signals.
	# Add an AnimationPlayer with basic clips if missing so user can fill frames.
	var ap = _find_child_of_type(node, "AnimationPlayer")
	if ap:
		return "AnimationPlayer already present"
	ap = AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	# Create empty but named libraries so the controller can switch
	var lib = AnimationLibrary.new()
	for anim_name in ["idle", "walk", "run", "jump", "crouch", "fall", "slide", "dash"]:
		if not lib.has_animation(anim_name):
			var a = Animation.new()
			a.length = 0.5
			lib.add_animation(anim_name, a)
	ap.add_animation_library("", lib)
	node.add_child(ap)
	ap.owner = EditorInterface.get_edited_scene_root()
	return "AnimationPlayer with idle/walk/run/jump/crouch/fall/slide/dash clips"

# --- Modify executor: resize / placement / rotate / delete -----------------------
# All mutations go through EditorUndoRedoManager so every AI edit is Ctrl+Z-able.

func _apply_modify(intent: Dictionary) -> String:
	var res := _resolve_modify_target(str(intent.get("target", "")), str(intent.get("fragment", "")))
	if not bool(res.get("ok", false)):
		return "[ERROR] " + str(res.get("error", "Could not resolve target."))
	var node: Node = res["node"]
	var op := str(intent.get("op", ""))
	var params: Dictionary = intent.get("params", {})
	var frag := str(intent.get("fragment", "")).to_lower()
	var msg := ""
	match op:
		"scale_up", "scale_down", "scale_to", "scale_axis":
			msg = _exec_scale(node, op, params)
		"move":
			msg = _exec_move(node, params, frag)
		"place_on", "align":
			msg = _exec_place(node, op, params, frag)
		"rotate":
			msg = _exec_rotate(node, params)
		"delete":
			msg = _exec_delete(node)
		_:
			return "[ERROR] Unknown modify operation: " + op
	if not msg.begins_with("[ERROR]"):
		session_memory["last_object"] = _node_rel_path(node)
	return msg

func _node_rel_path(node: Node) -> String:
	var root = EditorInterface.get_edited_scene_root()
	if root and node != root:
		var rel = str(root.get_path_to(node))
		if not rel.begins_with("../"):
			return rel
	return str(node.get_path())

func _num(v, fallback: float) -> float:
	if v == null:
		return fallback
	if v is int or v is float:
		return float(v)
	var s := str(v).strip_edges()
	if s.is_valid_float():
		return s.to_float()
	return fallback

func _has_word(frag: String, word: String) -> bool:
	for w in frag.split(" "):
		if w.strip_edges().trim_suffix(",").trim_suffix(".") == word:
			return true
	return false

func _collect_meshes(node: Node, out: Array[Node]) -> void:
	if node is MeshInstance3D:
		out.append(node)
	for c in node.get_children():
		_collect_meshes(c, out)

# Approximate world-space size in meters (3D) or pixels (2D)
func _measure_size(node: Node) -> Vector3:
	if node is Node3D:
		var meshes: Array[Node] = []
		_collect_meshes(node, meshes)
		var aabb := AABB()
		var has := false
		for m in meshes:
			var mi := m as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			var a: AABB = mi.global_transform * mi.get_aabb()
			if not has:
				aabb = a
				has = true
			else:
				aabb = aabb.merge(a)
		if has:
			return aabb.size
		return Vector3.ONE
	if node is Node2D:
		var poly := _find_child_of_type(node, "Polygon2D")
		if poly is Polygon2D and (poly as Polygon2D).polygon.size() > 0:
			var pts: PackedVector2Array = (poly as Polygon2D).polygon
			var rect := Rect2(pts[0], Vector2.ZERO)
			for i in range(1, pts.size()):
				rect = rect.expand(pts[i])
			return Vector3(rect.size.x / maxf(absf(node.scale.x), 0.001),
					rect.size.y / maxf(absf(node.scale.y), 0.001), 1.0)
	return Vector3.ONE

func _exec_scale(node: Node, op: String, params: Dictionary) -> String:
	if not (node is Node2D or node is Node3D):
		return "[ERROR] " + node.name + " cannot be scaled."
	var old_scale = node.scale
	var size := _measure_size(node)
	var axis := str(params.get("axis", "all")).to_lower()
	var factor := 1.0
	match op:
		"scale_up":
			factor = _num(params.get("amount"), 1.5)
			if factor <= 0.0:
				factor = 1.5
		"scale_down":
			factor = _num(params.get("amount"), 0.7)
			if factor <= 0.0 or factor >= 1.0:
				factor = 0.7
		"scale_axis":
			factor = _num(params.get("amount"), 1.5)
			if factor <= 0.0:
				factor = 1.5
		"scale_to":
			var target := _num(params.get("size"), -1.0)
			if target <= 0.0:
				return "[ERROR] scale_to needs params.size in meters."
			var cur := 1.0
			match axis:
				"x": cur = size.x
				"y": cur = size.y
				"z": cur = size.z
				_: cur = maxf(size.x, maxf(size.y, size.z))
			if cur <= 0.0001:
				return "[ERROR] Cannot measure " + node.name + " for absolute size."
			factor = target / cur
	var new_scale
	if node is Node3D:
		var s: Vector3 = old_scale
		if op == "scale_axis" and axis in ["x", "y", "z"]:
			match axis:
				"x": s.x = s.x * factor
				"y": s.y = s.y * factor
				"z": s.z = s.z * factor
		else:
			s = s * factor
		new_scale = s.clamp(Vector3(0.001, 0.001, 0.001), Vector3(1000, 1000, 1000))
	else:
		var s2: Vector2 = old_scale
		if op == "scale_axis" and axis in ["x", "y"]:
			if axis == "x":
				s2.x = s2.x * factor
			else:
				s2.y = s2.y * factor
		else:
			s2 = s2 * factor
		new_scale = s2.clamp(Vector2(0.001, 0.001), Vector2(1000, 1000))
	var ur := EditorInterface.get_editor_undo_redo()
	ur.create_action("AI: scale " + node.name)
	ur.add_do_property(node, "scale", new_scale)
	ur.add_undo_property(node, "scale", old_scale)
	ur.commit_action(true)
	return "%s scaled %.2gx (axis: %s)" % [node.name, factor, axis]

func _parse_direction(frag: String) -> Vector3:
	if _has_word(frag, "left") or _has_word(frag, "west"):
		return Vector3(-1, 0, 0)
	if _has_word(frag, "right") or _has_word(frag, "east"):
		return Vector3(1, 0, 0)
	if _has_word(frag, "up") or _has_word(frag, "above") or _has_word(frag, "higher"):
		return Vector3(0, 1, 0)
	if _has_word(frag, "down") or _has_word(frag, "below") or _has_word(frag, "lower"):
		return Vector3(0, -1, 0)
	if _has_word(frag, "forward") or _has_word(frag, "front"):
		return Vector3(0, 0, -1)
	if _has_word(frag, "back") or _has_word(frag, "backward") or _has_word(frag, "behind"):
		return Vector3(0, 0, 1)
	return Vector3.ZERO

func _exec_move(node: Node, params: Dictionary, frag: String) -> String:
	if not (node is Node2D or node is Node3D):
		return "[ERROR] " + node.name + " cannot be moved."
	var offset := Vector3(_num(params.get("dx"), 0.0), _num(params.get("dy"), 0.0), _num(params.get("dz"), 0.0))
	if offset == Vector3.ZERO:
		var dir := _parse_direction(frag)
		if dir == Vector3.ZERO:
			return "[ERROR] move needs dx/dy/dz params or a direction word (left/right/up/down/forward/back)."
		var dist := _num(params.get("distance"), 1.0)
		if dist <= 0.0:
			dist = 1.0
		offset = dir * dist
	# Snap offset to 0.25 grid (Unreal/Roblox-style increments)
	offset = offset.snapped(Vector3(0.25, 0.25, 0.25))
	if offset == Vector3.ZERO:
		return "[ERROR] move distance rounds to zero on the 0.25 grid; use a larger distance."
	var ur := EditorInterface.get_editor_undo_redo()
	ur.create_action("AI: move " + node.name)
	if node is Node2D:
		var old2: Vector2 = node.global_position
		var new2: Vector2 = old2 + Vector2(offset.x, offset.y)
		ur.add_do_property(node, "global_position", new2)
		ur.add_undo_property(node, "global_position", old2)
		ur.commit_action(true)
		return "%s moved by (%.2f, %.2f)" % [node.name, offset.x, offset.y]
	var old3: Vector3 = node.global_position
	var new3: Vector3 = old3 + offset
	ur.add_do_property(node, "global_position", new3)
	ur.add_undo_property(node, "global_position", old3)
	ur.commit_action(true)
	return "%s moved by (%.2f, %.2f, %.2f)" % [node.name, offset.x, offset.y, offset.z]

func _exec_place(node: Node, op: String, params: Dictionary, frag: String) -> String:
	if not (node is Node2D or node is Node3D):
		return "[ERROR] place/align needs a 2D/3D node."
	var ref_name := str(params.get("target", ""))
	var ref: Node = null
	if ref_name != "" and ref_name.to_lower() not in ["it", "that", "existing_object", "object"]:
		var rn = _resolve_node(ref_name)
		if rn and rn != node:
			ref = rn
	if ref == null:
		var npath := _node_rel_path(node)
		for o in _match_objects(frag, session_memory["objects"]):
			if str(o["path"]) != npath and str(o["name"]).to_lower() != node.name.to_lower():
				ref = _resolve_node(str(o["path"]))
				break
	if ref == null:
		return "[ERROR] " + op + " needs a reference object (e.g. 'on the floor', 'next to the crate')."
	if node is Node3D and ref is Node3D:
		var self_size := _measure_size(node)
		var ref_size := _measure_size(ref)
		var old_pos: Vector3 = node.global_position
		var new_pos := old_pos
		match op:
			"place_on":
				var ref_top: float = ref.global_position.y + ref_size.y * 0.5
				new_pos.y = ref_top + self_size.y * 0.5
				# Center over the reference only if already roughly above it
				var dx: float = ref.global_position.x - new_pos.x
				var dz: float = ref.global_position.z - new_pos.z
				if absf(dx) < ref_size.x:
					new_pos.x = new_pos.x + dx * 0.5
				if absf(dz) < ref_size.z:
					new_pos.z = new_pos.z + dz * 0.5
			"align":
				var rel := str(params.get("relation", "right")).to_lower()
				match rel:
					"left":
						new_pos.x = ref.global_position.x - ref_size.x * 0.5 - self_size.x * 0.5
					"front":
						new_pos.z = ref.global_position.z - ref_size.z * 0.5 - self_size.z * 0.5
					"behind", "back":
						new_pos.z = ref.global_position.z + ref_size.z * 0.5 + self_size.z * 0.5
					"center":
						new_pos.x = ref.global_position.x
						new_pos.z = ref.global_position.z
					_:
						new_pos.x = ref.global_position.x + ref_size.x * 0.5 + self_size.x * 0.5
		var ur := EditorInterface.get_editor_undo_redo()
		ur.create_action("AI: " + op + " " + node.name)
		ur.add_do_property(node, "global_position", new_pos)
		ur.add_undo_property(node, "global_position", old_pos)
		ur.commit_action(true)
		return "%s %s %s (y: %.2f -> %.2f)" % [node.name, op, ref.name, old_pos.y, new_pos.y]
	if node is Node2D and ref is Node2D:
		var self_size2 := _measure_size(node)
		var ref_size2 := _measure_size(ref)
		var old2: Vector2 = node.global_position
		var new2 := old2
		if op == "place_on":
			# 2D: y grows downward, so "on top" = above = smaller y
			var ref_top2: float = ref.global_position.y - ref_size2.y * 0.5
			new2.y = ref_top2 - self_size2.y * 0.5
		var ur2 := EditorInterface.get_editor_undo_redo()
		ur2.create_action("AI: " + op + " " + node.name)
		ur2.add_do_property(node, "global_position", new2)
		ur2.add_undo_property(node, "global_position", old2)
		ur2.commit_action(true)
		return "%s %s %s" % [node.name, op, ref.name]
	return "[ERROR] Cannot place a %s relative to a %s." % [node.get_class(), ref.get_class()]

func _exec_rotate(node: Node, params: Dictionary) -> String:
	if not (node is Node2D or node is Node3D):
		return "[ERROR] " + node.name + " cannot be rotated."
	var axis := str(params.get("axis", "")).to_lower()
	var deg := _num(params.get("degrees"), 90.0)
	var ur := EditorInterface.get_editor_undo_redo()
	ur.create_action("AI: rotate " + node.name)
	if node is Node2D:
		var old2: float = node.rotation_degrees
		var new2: float = old2 + deg
		ur.add_do_property(node, "rotation_degrees", new2)
		ur.add_undo_property(node, "rotation_degrees", old2)
		ur.commit_action(true)
		return "%s rotated %.0f deg" % [node.name, deg]
	var old3: Vector3 = node.rotation_degrees
	var new3 := old3
	if axis in ["x", "z"]:
		if axis == "x":
			new3.x = old3.x + deg
		else:
			new3.z = old3.z + deg
	else:
		new3.y = old3.y + deg
		axis = "y"
	ur.add_do_property(node, "rotation_degrees", new3)
	ur.add_undo_property(node, "rotation_degrees", old3)
	ur.commit_action(true)
	return "%s rotated %.0f deg around %s" % [node.name, deg, axis]

func _exec_delete(node: Node) -> String:
	var parent := node.get_parent()
	if parent == null:
		return "[ERROR] " + node.name + " has no parent; cannot delete."
	var root = EditorInterface.get_edited_scene_root()
	var idx := node.get_index()
	var ur := EditorInterface.get_editor_undo_redo()
	ur.create_action("AI: delete " + node.name)
	ur.add_do_method(parent, "remove_child", node)
	ur.add_do_reference(node)
	ur.add_undo_method(parent, "add_child", node)
	ur.add_undo_method(parent, "move_child", node, idx)
	if root:
		ur.add_undo_method(self, "_restore_owner_recursive", node, root)
	ur.commit_action(true)
	var rel := _node_rel_path(node)
	if session_memory["last_object"] == rel:
		session_memory["last_object"] = ""
	if rel in session_memory["characters"]:
		session_memory["characters"].erase(rel)
	session_memory["skills_applied"].erase(rel)
	_refresh_scene_memory()
	return node.name + " deleted (Ctrl+Z to undo)"

func _restore_owner_recursive(node: Node, root: Node) -> void:
	if node == null or not is_instance_valid(node) or root == null:
		return
	_set_owner_recursive(node, root)

# Local fallback classifier used when the LLM plan is unparseable/empty.
# Builds a registry-grounded task from keywords alone (no network).
func _heuristic_modify_task(prompt: String) -> Dictionary:
	var p := prompt.strip_edges().to_lower()
	if p.is_empty():
		return {}
	# Never hijack spawn-style prompts
	if _any(p, ["add a ", "add an ", "add some", "spawn", "create", "new scene",
			"make a ", "make an ", "give me a"]):
		return {}

	var task := {"skillset": "", "skill": "", "target": "existing_object",
			"params": {}, "fragment": prompt, "heuristic": true}
	if _any(p, ["delete", "remove", "get rid of", "erase"]):
		task["skillset"] = "modify_placement"
		task["skill"] = "delete"
		return task
	if _any(p, ["on top of", "onto ", "put it on", "place it on", "next to", "beside", "align", "center it"]):
		task["skillset"] = "modify_placement"
		task["skill"] = "place_on" if _any(p, ["on top of", "onto", "put it on", "place it on"]) else "align"
		return task
	if _any(p, ["rotate", "spin", "turn it", "turn around"]):
		task["skillset"] = "modify_placement"
		task["skill"] = "rotate"
		var deg := 90.0
		var re := RegEx.new()
		if re.compile("(-?\\d+(?:\\.\\d+)?)\\s*deg") == OK:
			var m := re.search(p)
			if m:
				deg = m.get_string(1).to_float()
		task["params"] = {"degrees": deg}
		return task
	var is_up := _any(p, ["bigger", "larger", "enlarge", "grow it", "increase size", "scale up", "double", "twice", "triple"])
	var is_down := _any(p, ["smaller", "shrink", "reduce size", "halve", "half the", "scale down", "tinier"])
	if is_up or is_down:
		task["skillset"] = "modify_scale"
		task["skill"] = "scale_up" if is_up else "scale_down"
		var amt := 1.5 if is_up else 0.7
		if _any(p, ["double", "twice"]):
			amt = 2.0
		elif _any(p, ["triple"]):
			amt = 3.0
		elif _any(p, ["half", "halve"]):
			amt = 0.5
		task["params"] = {"amount": amt}
		return task
	if _any(p, ["move", "shift", "reposition", "nudge"]):
		task["skillset"] = "modify_placement"
		task["skill"] = "move"
		var dir_word := ""
		for w in ["left", "right", "up", "down", "forward", "backward", "back", "front"]:
			if _has_word(p, w):
				dir_word = w
				break
		var dist := 1.0
		var re2 := RegEx.new()
		if re2.compile("(\\d+(?:\\.\\d+)?)\\s*(?:m|meter|meters|units)?") == OK:
			var m2 := re2.search(p)
			if m2:
				dist = m2.get_string(1).to_float()
		task["params"] = {"direction": dir_word, "distance": dist}
		return task
	return {}

func _find_child_of_type(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name:
		return node
	for c in node.get_children():
		var f = _find_child_of_type(c, type_name)
		if f:
			return f
	return null

# Generate (or update) a full movement controller GDScript from skill flags.
func _apply_movement_script(node: Node, flags: Dictionary) -> String:
	var is_3d = node is Node3D or node is CharacterBody3D
	var is_2d = node is Node2D or node is CharacterBody2D
	if not is_3d and not is_2d:
		# Infer from class name
		is_3d = "3D" in node.get_class()
		is_2d = "2D" in node.get_class() or not is_3d

	var script_code = _generate_movement_script(flags, is_3d)

	# Save script next to the scene if possible, else res://scripts/
	var scene_path = ""
	var root = EditorInterface.get_edited_scene_root()
	if root and root.scene_file_path != "":
		scene_path = str(root.scene_file_path)
	var dir = "res://scripts"
	if scene_path != "":
		var base = scene_path.get_base_dir()
		if base.is_empty() or base == "res://":
			dir = "res://scripts"
		elif base.ends_with("/"):
			dir = base + "scripts"
		else:
			dir = base + "/scripts"
	if not dir.ends_with("/"):
		dir += "/"
	# Ensure directory exists (use absolute API; avoids res:/// double-slash bug)
	if not DirAccess.dir_exists_absolute(dir):
		var mk_err = DirAccess.make_dir_recursive_absolute(dir)
		if mk_err != OK and not DirAccess.dir_exists_absolute(dir):
			dir = "res://"

	# Always overwrite the movement script so fixes take effect
	var script_name = node.name.to_lower().replace(" ", "_") + "_movement.gd"
	var script_path = dir + script_name

	var f = FileAccess.open(script_path, FileAccess.WRITE)
	if f == null:
		script_path = "res://" + script_name
		f = FileAccess.open(script_path, FileAccess.WRITE)
		if f == null:
			push_error("AI: could not write " + script_path)
			return ""
	f.store_string(script_code)
	f.close()

	_ensure_input_actions()

	# Force reload from disk (bypass cache so edits apply immediately)
	var script = ResourceLoader.load(script_path, "Script", ResourceLoader.CACHE_MODE_REPLACE)
	if script == null:
		push_error("AI: failed to load script " + script_path)
		return ""
	if script is Script and (script as Script).get_source_code().is_empty():
		push_error("AI: script empty: " + script_path)
		return ""

	# Replace any old movement/controller script on this node
	if node.get_script():
		var spath = str((node.get_script() as Script).resource_path)
		if "movement" in spath or "controller" in spath or spath == script_path:
			node.set_script(null)
	node.set_script(script)

	# Push tunables
	for key in ["walk_speed", "sprint_speed", "jump_velocity"]:
		if flags.has(key):
			try_set_script_var(node, key, flags[key])

	# Ensure collision shape exists on CharacterBody
	if node is CharacterBody3D or node is CharacterBody2D:
		var has_shape = _find_child_of_type(node, "CollisionShape3D" if is_3d else "CollisionShape2D")
		if not has_shape:
			var cs = (CollisionShape3D.new() if is_3d else CollisionShape2D.new())
			cs.name = "CollisionShape" + ("3D" if is_3d else "2D")
			if is_3d:
				var cap = CapsuleShape3D.new()
				cap.radius = 0.35
				cap.height = 1.7
				cs.shape = cap
				cs.position = Vector3(0, 0.85, 0)
			else:
				var rs = RectangleShape2D.new()
				rs.size = Vector2(24, 40)
				cs.shape = rs
			node.add_child(cs)
			cs.owner = EditorInterface.get_edited_scene_root()

	# Save scene so the script reference persists
	var eroot = EditorInterface.get_edited_scene_root()
	if eroot and eroot.scene_file_path != "":
		EditorInterface.save_scene()

	return script_path

func try_set_script_var(node: Node, key: String, value) -> void:
	if node.get_script() == null:
		return
	node.set(key, value)

func _ensure_input_actions() -> void:
	var needed := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_forward": [KEY_W, KEY_UP],
		"move_backward": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE],
		"run": [KEY_SHIFT],
		"crouch": [KEY_CTRL, KEY_C],
		"interact": [KEY_E],
	}
	var changed := false
	for action in needed:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			changed = true
		# Always ensure at least one binding exists
		var events = InputMap.action_get_events(action)
		if events.is_empty():
			for key in needed[action]:
				var ev = InputEventKey.new()
				ev.physical_keycode = key
				InputMap.action_add_event(action, ev)
			changed = true
	if changed:
		# Persist to project.godot so the game runtime sees the actions
		var ps = ProjectSettings
		# Saving ProjectSettings writes input/* entries
		var err = ps.save()
		if err != OK:
			push_warning("AI: could not save ProjectSettings input map (err %s)" % err)
		else:
			print("[AI] InputMap actions saved to project.godot")

# Build the GDScript source for movement mechanics from high-level flags.
func _generate_movement_script(flags: Dictionary, is_3d: bool) -> String:
	var walk_speed = flags.get("walk_speed", 6.0)
	var sprint_speed = flags.get("sprint_speed", 10.0)
	var jump_velocity = flags.get("jump_velocity", 7.0)
	var body_type = "CharacterBody3D" if is_3d else "CharacterBody2D"
	var gravity_default = 20.0 if is_3d else 980.0

	var lines: Array[String] = []
	lines.append("extends " + body_type)
	lines.append("")
	lines.append("## Auto-generated movement controller")
	lines.append("## Skills: " + _flags_to_skill_list(flags))
	lines.append("")
	lines.append("@export var walk_speed: float = %.1f" % walk_speed)
	lines.append("@export var sprint_speed: float = %.1f" % sprint_speed)
	lines.append("@export var jump_velocity: float = %.1f" % jump_velocity)
	lines.append("@export var crouch_speed: float = %.1f" % (walk_speed * 0.4))
	lines.append("@export var acceleration: float = 14.0")
	lines.append("@export var air_acceleration: float = 6.0")
	lines.append("@export var friction: float = 16.0")
	lines.append("@export var mouse_sensitivity: float = 0.003")
	lines.append("@export var gravity: float = %.1f" % gravity_default)
	if flags.get("double_jump", false):
		lines.append("@export var double_jump_enabled: bool = true")
	if flags.get("coyote_time", true):
		lines.append("@export var coyote_time: float = 0.12")
	if flags.get("jump_buffer", true):
		lines.append("@export var jump_buffer_time: float = 0.1")
	if flags.get("dash", false):
		lines.append("@export var dash_speed: float = %.1f" % (sprint_speed * 2.2))
		lines.append("@export var dash_time: float = 0.18")
		lines.append("@export var dash_cooldown: float = 0.6")
	if flags.get("slide", false):
		lines.append("@export var slide_speed: float = %.1f" % (sprint_speed * 1.3))
		lines.append("@export var slide_time: float = 0.7")
	if flags.get("fly", false) or flags.get("no_gravity", false):
		lines.append("@export var fly_speed: float = %.1f" % sprint_speed)
		lines.append("@export var fly_enabled: bool = true")
	lines.append("")
	lines.append("var is_sprinting: bool = false")
	lines.append("var is_crouching: bool = false")
	lines.append("var is_jumping: bool = false")
	lines.append("var is_airborne: bool = false")
	if flags.get("double_jump", false):
		lines.append("var jumps_left: int = 2")
	if flags.get("coyote_time", true):
		lines.append("var coyote_timer: float = 0.0")
	if flags.get("jump_buffer", true):
		lines.append("var jump_buffer_timer: float = 0.0")
	if flags.get("dash", false):
		lines.append("var dash_timer: float = 0.0")
		lines.append("var dash_cooldown_timer: float = 0.0")
		lines.append("var is_dashing: bool = false")
		lines.append("var dash_direction: Vector3 = Vector3.ZERO" if is_3d else "var dash_direction: Vector2 = Vector2.ZERO")
	if flags.get("slide", false):
		lines.append("var slide_timer: float = 0.0")
		lines.append("var is_sliding: bool = false")
		lines.append("var slide_dir: Vector3 = Vector3.ZERO" if is_3d else "var slide_dir: Vector2 = Vector2.ZERO")
	lines.append("var _was_on_floor: bool = false")
	lines.append("")
	lines.append("func _ready() -> void:")
	lines.append("\tset_meta(\"movement_skills\", \"" + _flags_to_skill_list(flags) + "\")")
	if flags.get("mouse_look", false) and is_3d:
		lines.append("\tInput.mouse_mode = Input.MOUSE_MODE_CAPTURED")
	lines.append("")
	lines.append("func _physics_process(delta: float) -> void:")
	# Gravity
	if not flags.get("no_gravity", false) and not flags.get("fly", false):
		lines.append("\tif not is_on_floor():")
		lines.append("\t\tvelocity.y -= gravity * delta")
	else:
		lines.append("\tif fly_enabled and not is_on_floor():")
		lines.append("\t\tvelocity.y = 0  # fly mode: no gravity")
	# Coyote + jump buffer timers
	if flags.get("coyote_time", true):
		lines.append("\tif is_on_floor():")
		lines.append("\t\tcoyote_timer = coyote_time")
		lines.append("\telse:")
		lines.append("\t\tcoyote_timer = maxf(0.0, coyote_timer - delta)")
	if flags.get("jump_buffer", true):
		lines.append("\tjump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)")
	# Horizontal input — safe helpers fall back to ui_* / raw keys if actions missing
	lines.append("\tvar input_dir := _move_vector()")
	if is_3d:
		lines.append("\tvar direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()")
	else:
		lines.append("\tvar direction := Vector2(input_dir.x, 0)")
	lines.append("\tvar on_floor := is_on_floor()")
	# Crouch
	if flags.get("crouch", true):
		lines.append("\tvar crouch_pressed: bool = _action_pressed(\"crouch\")")
		lines.append("\tis_crouching = crouch_pressed and on_floor")
		lines.append("\tvar current_speed := crouch_speed if is_crouching else walk_speed")
	else:
		lines.append("\tvar current_speed := walk_speed")
	# Sprint
	if flags.get("sprint", true):
		lines.append("\tis_sprinting = _action_pressed(\"run\") and not is_crouching and direction != " + ("Vector3.ZERO" if is_3d else "Vector2.ZERO"))
		lines.append("\tif is_sprinting:")
		lines.append("\t\tcurrent_speed = sprint_speed")
	# Dash
	if flags.get("dash", false):
		lines.append("\tdash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta)")
		lines.append("\tif _action_just_pressed(\"ui_accept\") and dash_cooldown_timer <= 0.0 and dash_timer <= 0.0 and direction != " + ("Vector3.ZERO" if is_3d else "Vector2.ZERO") + ":")
		lines.append("\t\tdash_timer = dash_time")
		lines.append("\t\tdash_cooldown_timer = dash_cooldown")
		lines.append("\t\tdash_direction = direction")
		lines.append("\t\tis_dashing = true")
		lines.append("\t\t_emit_skill_event(\"dash_started\")")
		lines.append("\tif dash_timer > 0.0:")
		lines.append("\t\tdash_timer -= delta")
		lines.append("\t\tvelocity.x = dash_direction.x * dash_speed")
		if is_3d:
			lines.append("\t\tvelocity.z = dash_direction.z * dash_speed")
		lines.append("\t\tif dash_timer <= 0.0:")
		lines.append("\t\t\tis_dashing = false")
		lines.append("\t\treturn  # skip normal move during dash")
	# Slide
	if flags.get("slide", false):
		lines.append("\tif is_sliding:")
		lines.append("\t\tslide_timer -= delta")
		lines.append("\t\tvelocity.x = slide_dir.x * slide_speed")
		if is_3d:
			lines.append("\t\tvelocity.z = slide_dir.z * slide_speed")
		lines.append("\t\tif slide_timer <= 0.0 or not on_floor:")
		lines.append("\t\t\tis_sliding = false")
		lines.append("\t\treturn")
		lines.append("\tif _action_just_pressed(\"crouch\") and on_floor and is_sprinting and direction != " + ("Vector3.ZERO" if is_3d else "Vector2.ZERO") + ":")
		lines.append("\t\tis_sliding = true")
		lines.append("\t\tslide_timer = slide_time")
		lines.append("\t\tslide_dir = direction")
		lines.append("\t\t_emit_skill_event(\"slide_started\")")
	# Acceleration / friction
	lines.append("\tvar accel := acceleration if on_floor else air_acceleration")
	lines.append("\tif direction != " + ("Vector3.ZERO" if is_3d else "Vector2.ZERO") + ":")
	lines.append("\t\tvelocity.x = move_toward(velocity.x, direction.x * current_speed, accel * delta)")
	if is_3d:
		lines.append("\t\tvelocity.z = move_toward(velocity.z, direction.z * current_speed, accel * delta)")
	else:
		pass
	lines.append("\telse:")
	lines.append("\t\tvelocity.x = move_toward(velocity.x, 0, friction * delta)")
	if is_3d:
		lines.append("\t\tvelocity.z = move_toward(velocity.z, 0, friction * delta)")
	# Jump
	lines.append("\tif _jump_pressed():")
	if flags.get("jump_buffer", true):
		lines.append("\t\tjump_buffer_timer = jump_buffer_time")
	if flags.get("coyote_time", true):
		lines.append("\tif jump_buffer_timer > 0.0 and (on_floor or coyote_timer > 0.0):")
		lines.append("\t\tvelocity.y = jump_velocity")
		lines.append("\t\tjump_buffer_timer = 0.0")
		lines.append("\t\tcoyote_timer = 0.0")
		lines.append("\t\tis_jumping = true")
		lines.append("\t\t_emit_skill_event(\"jumped\")")
		if flags.get("double_jump", false):
			lines.append("\t\tjumps_left = 1")
	else:
		lines.append("\t\tif on_floor:")
		lines.append("\t\t\tvelocity.y = jump_velocity")
		lines.append("\t\t\tis_jumping = true")
		lines.append("\t\t\t_emit_skill_event(\"jumped\")")
	# Double jump
	if flags.get("double_jump", false):
		lines.append("\tif _jump_pressed() and not on_floor and jumps_left > 0:")
		lines.append("\t\tvelocity.y = jump_velocity")
		lines.append("\t\tjumps_left -= 1")
		lines.append("\t\t_emit_skill_event(\"double_jumped\")")
	# Reset jumps on floor
	lines.append("\tif on_floor:")
	if flags.get("double_jump", false):
		lines.append("\t\tjumps_left = 2")
	lines.append("\t\tis_jumping = false")
	lines.append("\t\t_was_on_floor = true")
	lines.append("\telse:")
	lines.append("\t\tif _was_on_floor:")
	lines.append("\t\t\t_emit_skill_event(\"left_ground\")")
	lines.append("\t\t_was_on_floor = false")
	lines.append("\tis_airborne = not on_floor")
	# Fly vertical
	if flags.get("fly", false) or flags.get("no_gravity", false):
		lines.append("\tif fly_enabled and not on_floor:")
		lines.append("\t\tif Input.is_action_pressed(\"ui_up\"):")
		lines.append("\t\t\tvelocity.y = fly_speed")
		lines.append("\t\telif Input.is_action_pressed(\"ui_down\"):")
		lines.append("\t\t\tvelocity.y = -fly_speed")
		lines.append("\t\telse:")
		lines.append("\t\t\tvelocity.y = move_toward(velocity.y, 0, friction * delta)")
	# Climb / swim hooks
	if flags.get("climb", false):
		lines.append("\t# Climb: hold ui_up near a ladder Area to ascend (wire Area2D/3D \"ladder\" groups)")
		lines.append("\tif on_floor == false and Input.is_action_pressed(\"ui_up\") and _near_ladder():")
		lines.append("\t\tvelocity.y = walk_speed * 0.6")
	if flags.get("swim", false):
		lines.append("\t# Swim: reduce gravity in water group")
		lines.append("\tif _in_water():")
		lines.append("\t\tvelocity.y = move_toward(velocity.y, 0, gravity * delta)")
		lines.append("\t\tcurrent_speed = walk_speed * 0.55")
	if flags.get("grapple", false):
		lines.append("\t# Grapple: raycast forward on interact")
		lines.append("\tif _action_just_pressed(\"interact\"):")
		lines.append("\t\t_try_grapple()")
	if flags.get("wall_jump", false):
		lines.append("\tif not on_floor and is_on_wall() and _jump_pressed():")
		lines.append("\t\tvar wall_n := get_wall_normal()")
		if is_3d:
			lines.append("\t\tvelocity = (wall_n * jump_velocity * 0.8) + Vector3(0, jump_velocity, 0)")
		else:
			lines.append("\t\tvelocity = Vector2(wall_n.x * jump_velocity * 0.8, -jump_velocity)")
		lines.append("\t\t_emit_skill_event(\"wall_jumped\")")
	# Move
	lines.append("\tmove_and_slide()")
	# Animation state emit
	if flags.get("animation", true):
		lines.append("\t_update_animation_state(direction, on_floor)")
	# Mouse look
	if flags.get("mouse_look", false) and is_3d:
		lines.append("")
		lines.append("func _unhandled_input(event: InputEvent) -> void:")
		lines.append("\tif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:")
		lines.append("\t\trotate_y(-event.relative.x * mouse_sensitivity)")
		lines.append("\t\tvar arm := get_node_or_null(\"SpringArm\")")
		lines.append("\t\tif arm:")
		lines.append("\t\t\tarm.rotation.x = clampf(arm.rotation.x - event.relative.y * mouse_sensitivity, -1.2, 1.2)")
		lines.append("\t\telse:")
		lines.append("\t\t\tvar cam := get_node_or_null(\"Camera\")")
		lines.append("\t\t\tif cam:")
		lines.append("\t\t\t\tcam.rotation.x = clampf(cam.rotation.x - event.relative.y * mouse_sensitivity, -1.2, 1.2)")
		lines.append("\tif event.is_action_pressed(\"ui_cancel\"):")
		lines.append("\t\tInput.mouse_mode = Input.MOUSE_MODE_VISIBLE")
		lines.append("\tif event is InputEventMouseButton and event.pressed:")
		lines.append("\t\tInput.mouse_mode = Input.MOUSE_MODE_CAPTURED")
	# Animation state machine driver
	if flags.get("animation", true):
		lines.append("")
		lines.append("func _update_animation_state(direction, on_floor: bool) -> void:")
		lines.append("\tvar state := \"idle\"")
		lines.append("\tif is_crouching and on_floor:")
		lines.append("\t\tstate = \"crouch\"")
		if flags.get("slide", false):
			lines.append("\telif is_sliding:")
			lines.append("\t\tstate = \"slide\"")
		if flags.get("dash", false):
			lines.append("\telif is_dashing:")
			lines.append("\t\tstate = \"dash\"")
		lines.append("\telif not on_floor:")
		lines.append("\t\tstate = \"jump\" if velocity.y > 0.1 else \"fall\"")
		lines.append("\telif direction != " + ("Vector3.ZERO" if is_3d else "Vector2.ZERO") + ":")
		lines.append("\t\tstate = \"run\" if is_sprinting else \"walk\"")
		lines.append("\tif state != str(get_meta(\"_last_anim\", \"\")):")
		lines.append("\t\tset_meta(\"_last_anim\", state)")
		lines.append("\t\tvar ap := get_node_or_null(\"AnimationPlayer\")")
		lines.append("\t\tif ap and ap.has_animation(state):")
		lines.append("\t\t\tap.play(state)")
		lines.append("\t\t_emit_skill_event(\"anim_\" + state)")
	# Helpers
	lines.append("")
	lines.append("func _emit_skill_event(skill: String) -> void:")
	lines.append("\t# Hook for game manager / audio / VFX")
	lines.append("\tget_tree().call_group(\"skill_listener\", \"on_skill_event\", name, skill)")
	lines.append("")
	lines.append("func _action_pressed(action: String) -> bool:")
	lines.append("\tif InputMap.has_action(action):")
	lines.append("\t\treturn Input.is_action_pressed(action)")
	lines.append("\treturn false")
	lines.append("")
	lines.append("func _action_just_pressed(action: String) -> bool:")
	lines.append("\tif InputMap.has_action(action):")
	lines.append("\t\treturn Input.is_action_just_pressed(action)")
	lines.append("\treturn false")
	lines.append("")
	lines.append("func _move_vector() -> Vector2:")
	lines.append("\tif InputMap.has_action(\"move_left\") and InputMap.has_action(\"move_right\") and InputMap.has_action(\"move_forward\") and InputMap.has_action(\"move_backward\"):")
	lines.append("\t\treturn Input.get_vector(\"move_left\", \"move_right\", \"move_forward\", \"move_backward\")")
	lines.append("\t# Fallback: raw keys (A/D/W/S + arrows) if actions missing")
	lines.append("\tvar x := 0.0")
	lines.append("\tvar y := 0.0")
	lines.append("\tif Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): x -= 1.0")
	lines.append("\tif Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): x += 1.0")
	lines.append("\tif Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): y -= 1.0")
	lines.append("\tif Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): y += 1.0")
	lines.append("\treturn Vector2(x, y)")
	lines.append("")
	lines.append("var _prev_space: bool = false")
	lines.append("")
	lines.append("func _jump_pressed() -> bool:")
	lines.append("\tif InputMap.has_action(\"jump\"):")
	lines.append("\t\treturn Input.is_action_just_pressed(\"jump\")")
	lines.append("\tvar space := Input.is_physical_key_pressed(KEY_SPACE)")
	lines.append("\tvar just := space and not _prev_space")
	lines.append("\t_prev_space = space")
	lines.append("\treturn just")
	if flags.get("climb", false) or flags.get("swim", false) or flags.get("grapple", false):
		lines.append("")
	if flags.get("climb", false):
		lines.append("func _near_ladder() -> bool:")
		lines.append("\treturn get_tree().get_nodes_in_group(\"ladder\").any(func(n): return n is Node2D or n is Node3D)")
	if flags.get("swim", false):
		lines.append("")
		lines.append("func _in_water() -> bool:")
		lines.append("\treturn get_tree().get_nodes_in_group(\"water\").size() > 0")
	if flags.get("grapple", false):
		lines.append("")
		lines.append("func _try_grapple() -> void:")
		if is_3d:
			lines.append("\tvar space := get_world_3d().direct_space_state")
			lines.append("\tvar from := global_position")
			lines.append("\tvar to := from - transform.basis.z * 30.0")
			lines.append("\tvar q := PhysicsRayQueryParameters3D.create(from, to)")
			lines.append("\tvar hit := space.intersect_ray(q)")
			lines.append("\tif hit:")
			lines.append("\t\tvelocity = (hit.position - from).normalized() * sprint_speed * 1.5")
			lines.append("\t\t_emit_skill_event(\"grapple_hit\")")
		else:
			lines.append("\tvar space := get_world_2d().direct_space_state")
			lines.append("\tvar from := global_position")
			lines.append("\tvar to := from - Vector2(transform.x.x, transform.x.y) * 30.0")
			lines.append("\tvar q := PhysicsRayQueryParameters2D.create(from, to)")
			lines.append("\tvar hit := space.intersect_ray(q)")
			lines.append("\tif hit:")
			lines.append("\t\tvelocity = (hit.position - from).normalized() * sprint_speed * 1.5")
			lines.append("\t\t_emit_skill_event(\"grapple_hit\")")

	return "\n".join(lines)

func _flags_to_skill_list(flags: Dictionary) -> String:
	var parts: Array[String] = []
	var map := {
		"walk": "walk", "run": "run", "sprint": "sprint", "jump": "jump",
		"double_jump": "double_jump", "crouch": "crouch", "slide": "slide",
		"dash": "dash", "air_control": "air_control", "coyote_time": "coyote",
		"jump_buffer": "jump_buffer", "camera_follow": "camera", "mouse_look": "mouse_look",
		"fps_camera": "fps", "spring_arm": "spring_arm", "animation": "animation",
		"wall_jump": "wall_jump", "swim": "swim", "climb": "climb", "grapple": "grapple",
		"glide": "glide", "fly": "fly", "no_gravity": "no_gravity", "strafe": "strafe",
	}
	for k in map:
		if flags.get(k, false):
			parts.append(str(map[k]))
	return ", ".join(parts) if parts.size() else "basic_move"

func _unique_name(parent: Node, base: String) -> String:
	if parent.get_node_or_null(NodePath(base)) == null:
		return base
	var i = 2
	while parent.get_node_or_null(NodePath(base + str(i))) != null:
		i += 1
	return base + str(i)

func _set_owner_recursive(node: Node, owner: Node) -> void:
	node.owner = owner
	for c in node.get_children():
		_set_owner_recursive(c, owner)

func _mat(color: Color, metallic: float = 0.0, rough: float = 0.7) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = rough
	return m

func _mat2d(color: Color) -> CanvasItemMaterial:
	var m = CanvasItemMaterial.new()
	m.color = color
	return m

func _build_prop(intent: Dictionary) -> Node:
	var is_3d: bool = intent["dim"] == 3
	var shape: String = intent.get("shape", "box")

	if not is_3d:
		# 2D: colored Polygon2D / ColorRect style visual
		var n = Node2D.new()
		n.name = shape.capitalize() + "2D"
		var poly = Polygon2D.new()
		poly.name = "Visual"
		poly.material = _mat2d(_shape_color(shape))
		match shape:
			"sphere", "ball":
				var pts = PackedVector2Array()
				for i in range(32):
					var a = TAU * i / 32.0
					pts.append(Vector2(cos(a), sin(a)) * 32.0)
				poly.polygon = pts
			"capsule":
				poly.polygon = PackedVector2Array([Vector2(-20,-30), Vector2(20,-30), Vector2(20,30), Vector2(-20,30)])
			"plane":
				poly.polygon = PackedVector2Array([Vector2(-48,-8), Vector2(48,-8), Vector2(48,8), Vector2(-48,8)])
			_:
				poly.polygon = PackedVector2Array([Vector2(-32,-32), Vector2(32,-32), Vector2(32,32), Vector2(-32,32)])
		n.add_child(poly)
		# Simple physics for 2D props
		var body = StaticBody2D.new()
		body.name = "Body"
		var cs = CollisionShape2D.new()
		cs.name = "Shape"
		if shape in ["sphere", "ball"]:
			var s = CircleShape2D.new()
			s.radius = 32
			cs.shape = s
		else:
			var s = RectangleShape2D.new()
			s.size = Vector2(64, 64)
			cs.shape = s
		body.add_child(cs)
		n.add_child(body)
		return n

	# 3D prop
	if shape in ["tree", "rock"]:
		var root3 = Node3D.new()
		root3.name = shape.capitalize()
		var mi = MeshInstance3D.new()
		mi.name = "Mesh"
		if shape == "tree":
			var trunk = CylinderMesh.new()
			trunk.top_radius = 0.15
			trunk.bottom_radius = 0.25
			trunk.height = 2.0
			var trunk_mi = MeshInstance3D.new()
			trunk_mi.name = "Trunk"
			trunk_mi.mesh = trunk
			trunk_mi.material_override = _mat(Color(0.4, 0.25, 0.1))
			trunk_mi.position = Vector3(0, 1, 0)
			root3.add_child(trunk_mi)
			var foliage = SphereMesh.new()
			foliage.radius = 1.2
			foliage.height = 2.0
			mi.mesh = foliage
			mi.material_override = _mat(Color(0.15, 0.55, 0.15))
			mi.position = Vector3(0, 2.8, 0)
			root3.add_child(mi)
		else:
			var s = SphereMesh.new()
			s.radius = 0.6
			s.height = 1.0
			mi.mesh = s
			mi.material_override = _mat(Color(0.5, 0.5, 0.52), 0.0, 0.9)
			mi.position = Vector3(0, 0.5, 0)
			mi.scale = Vector3(1, 0.7, 1.1)
			root3.add_child(mi)
		var body = StaticBody3D.new()
		body.name = "Body"
		var cs = CollisionShape3D.new()
		cs.name = "Shape"
		var ss = SphereShape3D.new()
		ss.radius = 0.6 if shape == "rock" else 1.5
		cs.shape = ss
		cs.position = Vector3(0, 0.5 if shape == "rock" else 1.5, 0)
		body.add_child(cs)
		root3.add_child(body)
		return root3

	var mesh: Mesh
	match shape:
		"sphere", "ball":
			var s = SphereMesh.new()
			s.radius = 0.5
			s.height = 1.0
			mesh = s
		"cylinder", "pipe", "column", "pillar", "barrel", "tube":
			var c = CylinderMesh.new()
			c.top_radius = 0.4
			c.bottom_radius = 0.4
			c.height = 1.2
			mesh = c
		"capsule", "pill":
			var c = CapsuleMesh.new()
			c.radius = 0.35
			c.height = 1.2
			mesh = c
		"plane", "quad", "sheet", "flat":
			var q = PlaneMesh.new()
			q.size = Vector2(2, 2)
			mesh = q
		"cone":
			var c = CylinderMesh.new()
			c.top_radius = 0.0
			c.bottom_radius = 0.5
			c.height = 1.0
			mesh = c
		_:
			var b = BoxMesh.new()
			b.size = Vector3(1, 1, 1)
			mesh = b
	return _wrap_mesh_and_body(shape, mesh, _shape_color(shape))

func _wrap_mesh_and_body(shape: String, mesh: Mesh, color: Color) -> Node3D:
	var wrap = Node3D.new()
	wrap.name = shape.capitalize()
	var mi = MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	mi.material_override = _mat(color)
	var y = 0.5
	if shape in ["plane", "flat", "quad", "sheet"]:
		y = 0.05
	mi.position = Vector3(0, y, 0)
	wrap.add_child(mi)
	var body = StaticBody3D.new()
	body.name = "Body"
	var cs = CollisionShape3D.new()
	cs.name = "Shape"
	match shape:
		"sphere", "ball":
			var s = SphereShape3D.new(); s.radius = 0.5; cs.shape = s
		"cylinder", "pipe", "column", "pillar", "barrel", "tube":
			var s = CylinderShape3D.new(); s.radius = 0.4; s.height = 1.2; cs.shape = s
		"capsule", "pill":
			var s = CapsuleShape3D.new(); s.radius = 0.35; s.height = 1.2; cs.shape = s
		"plane", "flat", "quad", "sheet":
			var s = BoxShape3D.new(); s.size = Vector3(2, 0.1, 2); cs.shape = s
			cs.position = Vector3(0, 0.05, 0)
		"cone":
			var s = CylinderShape3D.new(); s.radius = 0.5; s.height = 1.0; cs.shape = s
			cs.position = Vector3(0, y, 0)
		_:
			var s = BoxShape3D.new(); s.size = Vector3(1, 1, 1); cs.shape = s
			cs.position = Vector3(0, y, 0)
	if shape not in ["plane", "flat", "quad", "sheet"] and shape != "cone":
		cs.position = Vector3(0, y, 0)
	body.add_child(cs)
	wrap.add_child(body)
	return wrap

func _shape_color(shape: String) -> Color:
	match shape:
		"sphere", "ball": return Color(0.9, 0.5, 0.2)
		"cylinder", "pipe", "column", "pillar", "barrel", "tube": return Color(0.7, 0.7, 0.75)
		"capsule", "pill": return Color(0.3, 0.7, 0.9)
		"cone": return Color(0.85, 0.3, 0.3)
		"plane", "flat", "quad", "sheet": return Color(0.5, 0.7, 0.4)
		"tree": return Color(0.2, 0.5, 0.2)
		"rock": return Color(0.5, 0.5, 0.52)
		_: return Color(0.8, 0.6, 0.3) # box/crate wood

func _build_surface(intent: Dictionary) -> Node:
	var is_3d: bool = intent["dim"] == 3
	var shape: String = intent.get("shape", "box")
	var ceiling: bool = intent.get("ceiling", false)
	var is_ramp: bool = shape == "ramp"
	var is_wall: bool = shape == "wall"

	if not is_3d:
		var wrap = Node2D.new()
		wrap.name = "WalkableSurface2D"
		var poly = Polygon2D.new()
		poly.name = "Visual"
		poly.material = _mat2d(Color(0.45, 0.35, 0.25))
		if is_wall:
			poly.polygon = PackedVector2Array([Vector2(-16,-128), Vector2(16,-128), Vector2(16,128), Vector2(-16,128)])
		else:
			poly.polygon = PackedVector2Array([Vector2(-256,-16), Vector2(256,-16), Vector2(256,16), Vector2(-256,16)])
		wrap.add_child(poly)
		var body = StaticBody2D.new()
		body.name = "Body"
		var cs = CollisionShape2D.new()
		cs.name = "Shape"
		var rs = RectangleShape2D.new()
		if is_wall:
			rs.size = Vector2(32, 256)
		else:
			rs.size = Vector2(512, 32)
		cs.shape = rs
		body.add_child(cs)
		wrap.add_child(body)
		return wrap

	# 3D walkable surface
	var wrap = Node3D.new()
	wrap.name = "WalkableSurface"
	var mi = MeshInstance3D.new()
	mi.name = "Mesh"
	var body = StaticBody3D.new()
	body.name = "Body"
	var cs = CollisionShape3D.new()
	cs.name = "Shape"

	if is_ramp:
		var box = BoxMesh.new()
		box.size = Vector3(4, 0.3, 8)
		mi.mesh = box
		mi.material_override = _mat(Color(0.55, 0.45, 0.35))
		mi.rotation_degrees = Vector3(-20, 0, 0)
		mi.position = Vector3(0, 0.5, 0)
		var s = BoxShape3D.new()
		s.size = Vector3(4, 0.3, 8)
		cs.shape = s
		cs.position = mi.position
		cs.rotation_degrees = mi.rotation_degrees
		wrap.add_child(mi)
		body.add_child(cs)
		wrap.add_child(body)
		return wrap

	if is_wall:
		var box = BoxMesh.new()
		box.size = Vector3(0.3, 3, 8)
		mi.mesh = box
		mi.material_override = _mat(Color(0.6, 0.6, 0.62))
		mi.position = Vector3(0, 1.5, 0)
		var s = BoxShape3D.new()
		s.size = Vector3(0.3, 3, 8)
		cs.shape = s
		cs.position = mi.position
		wrap.add_child(mi)
		body.add_child(cs)
		wrap.add_child(body)
		return wrap

	# Floor / platform
	if shape == "cylinder":
		var cyl = CylinderMesh.new()
		cyl.top_radius = 4
		cyl.bottom_radius = 4
		cyl.height = 0.3
		mi.mesh = cyl
		mi.material_override = _mat(Color(0.4, 0.55, 0.35))
		mi.position = Vector3(0, 0.15, 0)
		var s = CylinderShape3D.new()
		s.radius = 4
		s.height = 0.3
		cs.shape = s
		cs.position = mi.position
	else:
		var box = BoxMesh.new()
		box.size = Vector3(20, 0.3, 20)
		mi.mesh = box
		mi.material_override = _mat(Color(0.4, 0.55, 0.35))
		mi.position = Vector3(0, 0.15, 0)
		var s = BoxShape3D.new()
		s.size = Vector3(20, 0.3, 20)
		cs.shape = s
		cs.position = mi.position
	if ceiling:
		mi.position.y = 3.0
		cs.position.y = 3.0
		mi.material_override = _mat(Color(0.5, 0.5, 0.5))
	wrap.add_child(mi)
	body.add_child(cs)
	wrap.add_child(body)
	return wrap

func _build_character(intent: Dictionary) -> Node:
	var is_3d: bool = intent["dim"] == 3
	var is_player: bool = intent.get("role", "npc") == "player"

	if not is_3d:
		var wrap = CharacterBody2D.new()
		wrap.name = "Player" if is_player else "NPC"
		var cs = CollisionShape2D.new()
		cs.name = "Shape"
		var rs = RectangleShape2D.new()
		rs.size = Vector2(24, 40)
		cs.shape = rs
		wrap.add_child(cs)
		var visual = Polygon2D.new()
		visual.name = "Visual"
		visual.material = _mat2d(Color(0.2, 0.5, 0.9) if is_player else Color(0.8, 0.25, 0.25))
		visual.polygon = PackedVector2Array([
			Vector2(-12, -20), Vector2(12, -20), Vector2(12, 20), Vector2(-12, 20)
		])
		wrap.add_child(visual)
		if is_player:
			var cam = Camera2D.new()
			cam.name = "Camera"
			wrap.add_child(cam)
		return wrap

	var wrap = CharacterBody3D.new()
	wrap.name = "Player" if is_player else "NPC"

	var cs = CollisionShape3D.new()
	cs.name = "Shape"
	var cap = CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	cs.shape = cap
	cs.position = Vector3(0, 0.85, 0)
	wrap.add_child(cs)

	var mesh = CapsuleMesh.new()
	mesh.radius = 0.35
	mesh.height = 1.7
	var mi = MeshInstance3D.new()
	mi.name = "Body"
	mi.mesh = mesh
	mi.material_override = _mat(Color(0.2, 0.5, 0.9) if is_player else Color(0.8, 0.25, 0.25))
	mi.position = Vector3(0, 0.85, 0)
	wrap.add_child(mi)

	# Head indicator
	var head = MeshInstance3D.new()
	head.name = "Head"
	var hs = SphereMesh.new()
	hs.radius = 0.25
	hs.height = 0.5
	head.mesh = hs
	head.material_override = _mat(Color(0.95, 0.8, 0.65))
	head.position = Vector3(0, 1.7, 0)
	wrap.add_child(head)

	if is_player:
		var cam = Camera3D.new()
		cam.name = "Camera"
		cam.position = Vector3(0, 1.5, 4)
		wrap.add_child(cam)
		var spring = SpringArm3D.new()
		spring.name = "SpringArm"
		spring.spring_length = 4.0
		spring.position = Vector3(0, 1.5, 0)
		# Move camera under spring arm for orbit style
		wrap.remove_child(cam)
		spring.add_child(cam)
		cam.position = Vector3.ZERO
		wrap.add_child(spring)
	else:
		# NPC gets a name label
		var label = Label3D.new()
		label.name = "NameLabel"
		label.text = "NPC"
		label.position = Vector3(0, 2.2, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		wrap.add_child(label)

	return wrap

func _build_environment(intent: Dictionary) -> Node:
	var is_3d: bool = intent["dim"] == 3
	var element: String = intent.get("element", "light")

	if not is_3d:
		match element:
			"camera":
				var cam = Camera2D.new()
				cam.name = "Camera"
				return cam
			"sun", "light":
				var l = DirectionalLight2D.new()
				l.name = "Light"
				return l
			"water":
				var n = Node2D.new()
				n.name = "Water"
				var poly = Polygon2D.new()
				poly.material = _mat2d(Color(0.2, 0.4, 0.8, 0.7))
				poly.polygon = PackedVector2Array([Vector2(-256,0), Vector2(256,0), Vector2(256,128), Vector2(-256,128)])
				n.add_child(poly)
				return n
			_:
				var n = Node2D.new()
				n.name = "Environment"
				return n

	match element:
		"sun":
			var l = DirectionalLight3D.new()
			l.name = "Sun"
			l.rotation_degrees = Vector3(-45, -30, 0)
			l.shadow_enabled = true
			return l
		"light":
			var l = OmniLight3D.new()
			l.name = "Light"
			l.position = Vector3(0, 2, 0)
			l.light_energy = 2.0
			return l
		"camera":
			var cam = Camera3D.new()
			cam.name = "Camera"
			cam.position = Vector3(0, 2, 5)
			return cam
		"water":
			var mi = MeshInstance3D.new()
			mi.name = "Water"
			var plane = PlaneMesh.new()
			plane.size = Vector2(20, 20)
			mi.mesh = plane
			var m = StandardMaterial3D.new()
			m.albedo_color = Color(0.15, 0.35, 0.75, 0.7)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.metallic = 0.3
			m.roughness = 0.1
			mi.material_override = m
			mi.position = Vector3(0, 0.05, 0)
			return mi
		"world", "sky", "fog":
			var env = WorldEnvironment.new()
			env.name = "WorldEnvironment"
			var e = Environment.new()
			e.background_mode = Environment.BG_SKY
			var sky = Sky.new()
			var sky_mat = ProceduralSkyMaterial.new()
			sky.sky_material = sky_mat
			sky.sky_material.sky_top_color = Color(0.3, 0.5, 0.8)
			sky.sky_material.sky_horizon_color = Color(0.6, 0.7, 0.85)
			e.sky = sky
			if "fog" in intent.get("label", "").to_lower() or "fog" in str(intent):
				e.fog_enabled = true
			env.environment = e
			return env
		_:
			var n = Node3D.new()
			n.name = "Environment"
			return n

func _build_particles(intent: Dictionary) -> Node:
	var is_3d: bool = intent["dim"] == 3
	var effect: String = intent.get("effect", "fire")

	var colors := {
		"fire": [Color(1, 0.5, 0.1), Color(1, 0.9, 0.2)],
		"smoke": [Color(0.4, 0.4, 0.4), Color(0.2, 0.2, 0.2)],
		"rain": [Color(0.5, 0.6, 0.9), Color(0.7, 0.8, 1)],
		"snow": [Color(1, 1, 1), Color(0.9, 0.95, 1)],
		"sparks": [Color(1, 0.9, 0.3), Color(1, 0.4, 0.1)],
		"magic": [Color(0.6, 0.2, 1), Color(0.2, 0.8, 1)],
	}
	var cols: Array = colors.get(effect, colors["fire"])

	if not is_3d:
		var cp = CPUParticles2D.new()
		cp.name = effect.capitalize() + "Particles"
		cp.amount = 64
		cp.lifetime = 1.5
		cp.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		cp.emission_sphere_radius = 16
		cp.gravity = Vector2(0, 200 if effect != "rain" else 600)
		cp.color = cols[0]
		cp.scale_amount_min = 2
		cp.scale_amount_max = 6
		cp.emitting = true
		return cp

	var p: Node3D
	var particles = GPUParticles3D.new()
	particles.name = effect.capitalize() + "Particles"
	particles.amount = 128
	particles.lifetime = 2.0
	particles.emitting = true
	var mat = ParticleProcessMaterial.new()
	match effect:
		"rain":
			mat.direction = Vector3(0, -1, 0)
			mat.spread = 0
			mat.initial_velocity_min = 8
			mat.initial_velocity_max = 12
			mat.gravity = Vector3(0, -20, 0)
			mat.scale_min = 0.02
			mat.scale_max = 0.05
		"snow":
			mat.direction = Vector3(0, -1, 0)
			mat.spread = 30
			mat.initial_velocity_min = 0.5
			mat.initial_velocity_max = 1.5
			mat.gravity = Vector3(0, -1, 0)
			mat.scale_min = 0.05
			mat.scale_max = 0.12
		_:
			mat.direction = Vector3(0, 1, 0)
			mat.spread = 25
			mat.initial_velocity_min = 1
			mat.initial_velocity_max = 3
			mat.gravity = Vector3(0, 2, 0)
			mat.scale_min = 0.1
			mat.scale_max = 0.4
	var grad = Gradient.new()
	grad.colors = PackedColorArray([cols[0], cols[1], Color(cols[1], 0)])
	var grad_tex = GradientTexture1D.new()
	grad_tex.gradient = grad
	mat.color_ramp = grad_tex
	particles.process_material = mat
	# Simple box mesh as particle visual
	var bm = BoxMesh.new()
	bm.size = Vector3(0.15, 0.15, 0.15)
	var m = StandardMaterial3D.new()
	m.albedo_color = cols[0]
	m.emission_enabled = true
	m.emission = cols[0]
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.material = m
	particles.draw_pass_1 = bm
	p = particles
	return p

# --- Pipeline: LLM planner -> Jev validator -> local executors ----------------

func _memory_context() -> String:
	var lines: Array[String] = []
	lines.append("Active character: " + (session_memory["last_character"] if session_memory["last_character"] != "" else "(none)"))
	lines.append("Characters: " + (", ".join(session_memory["characters"]) if session_memory["characters"].size() else "(none)"))
	for path in session_memory["skills_applied"]:
		lines.append("Skills on " + path + ": " + ", ".join(session_memory["skills_applied"][path]))
	var objs: Array = session_memory["objects"]
	if objs.size():
		var names: Array[String] = []
		for o in objs:
			names.append(str(o["name"]))
		lines.append("Objects in scene: " + ", ".join(names))
	else:
		lines.append("Objects in scene: (none)")
	if session_memory["last_object"] != "":
		lines.append("Last modified/created object: " + session_memory["last_object"])
	return "\n".join(lines)

# Reads the GitHub Copilot OAuth access token from opencode's auth store so the
# credential stays fresh when opencode refreshes it. Falls back to llm_key.
func _copilot_token() -> String:
	var candidates := [
		OS.get_environment("USERPROFILE") + "/.local/share/opencode/auth.json",
		OS.get_environment("HOME") + "/.local/share/opencode/auth.json",
	]
	for path in candidates:
		if path.strip_edges().length() < 10 or not FileAccess.file_exists(path):
			continue
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var j := JSON.new()
		if j.parse(f.get_as_text()) != OK:
			continue
		var d = j.data
		if d is Dictionary and d.has("github-copilot"):
			var gc = d["github-copilot"]
			if gc is Dictionary and gc.has("access"):
				var tok := str(gc["access"]).strip_edges()
				if tok != "":
					return tok
	return llm_key

func _llm_chat(system_prompt: String, user_prompt: String) -> Dictionary:
	var body = {}
	var url := ""
	var model := ""
	if llm_provider == "openai":
		model = "gpt-4"
		url = "https://api.openai.com/v1/chat/completions"
	elif llm_provider == "anthropic":
		url = "https://api.anthropic.com/v1/messages"
	elif llm_provider == "openrouter":
		model = "openai/gpt-4o-mini"
		url = "https://openrouter.ai/api/v1/chat/completions"
	elif llm_provider == "copilot":
		model = "gpt-4o"
		url = "https://api.githubcopilot.com/chat/completions"
	else:
		return {"error": "Unknown LLM provider: " + llm_provider}
	if llm_model != "":
		model = llm_model

	if llm_provider == "anthropic":
		body = {
			"model": model,
			"max_tokens": 1500,
			"system": system_prompt,
			"messages": [{"role": "user", "content": user_prompt}]
		}
	else:
		body = {
			"model": model,
			"messages": [
				{"role": "system", "content": system_prompt},
				{"role": "user", "content": user_prompt}
			],
			"temperature": 0.2,
			"max_tokens": 1500
		}

	var headers := []
	match llm_provider:
		"openai":
			headers = ["Content-Type: application/json", "Authorization: Bearer " + llm_key]
		"anthropic":
			headers = ["Content-Type: application/json", "x-api-key: " + llm_key, "anthropic-version: 2023-06-01"]
		"openrouter":
			headers = ["Content-Type: application/json", "Authorization: Bearer " + llm_key, "X-Title: Godot AI Assistant"]
		"copilot":
			var tok := _copilot_token()
			if tok == "":
				return {"error": "Copilot token not found (opencode auth.json) and no LLM key set."}
			headers = [
				"Content-Type: application/json",
				"Authorization: Bearer " + tok,
				"Editor-Version: vscode/1.90.0",
				"Copilot-Integration-Id: copilot-chat",
			]

	var json_body = JSON.stringify(body)
	var http = HTTPRequest.new()
	http.timeout = 30
	add_child(http)

	var error = http.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		http.queue_free()
		return {"error": "LLM request failed to start"}

	var result = await http.request_completed
	http.queue_free()

	if result[0] != HTTPRequest.RESULT_SUCCESS or result[1] != 200:
		return {"error": "LLM returned " + str(result[1])}

	var json = JSON.new()
	if json.parse(result[3].get_string_from_utf8()) != OK:
		return {"error": "Could not parse LLM response"}

	var data = json.data
	if data.has("choices"):
		return {"text": String(data["choices"][0]["message"]["content"])}
	elif llm_provider == "anthropic" and data.has("content"):
		return {"text": String(data["content"][0]["text"])}
	return {"error": "LLM response missing content"}

func _parse_tasks_json(text: String) -> Dictionary:
	# Returns {ok:bool, tasks:Array, clarify:String, unknown:Array}
	var t := text.strip_edges()
	# Strip markdown fences if present
	if t.begins_with("```"):
		var first_nl := t.find("\n")
		if first_nl >= 0:
			t = t.substr(first_nl + 1)
		if "```" in t:
			t = t.substr(0, t.rfind("```"))
		t = t.strip_edges()
	var json := JSON.new()
	if json.parse(t) != OK:
		# Try to salvage the outermost {...}
		var start := t.find("{")
		var end := t.rfind("}")
		if start >= 0 and end > start:
			t = t.substr(start, end - start + 1)
			if json.parse(t) != OK:
				return {"ok": false, "tasks": [], "clarify": "", "unknown": []}
		else:
			return {"ok": false, "tasks": [], "clarify": "", "unknown": []}
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return {"ok": false, "tasks": [], "clarify": "", "unknown": []}
	# LLM can ask the user a clarifying question instead of guessing
	if data.has("clarify"):
		return {"ok": true, "tasks": [], "clarify": str(data["clarify"]), "unknown": []}
	if not data.has("tasks") or typeof(data["tasks"]) != TYPE_ARRAY:
		return {"ok": false, "tasks": [], "clarify": "", "unknown": []}
	var out: Array = []
	var unknown: Array = []
	for task in data["tasks"]:
		if typeof(task) != TYPE_DICTIONARY:
			continue
		var ss := str(task.get("skillset", ""))
		if not SKILL_REGISTRY.has(ss):
			if ss != "":
				unknown.append(ss)
			continue
		var sk := str(task.get("skill", ""))
		if not SKILL_REGISTRY[ss].has(sk):
			if sk != "":
				unknown.append(ss + "/" + sk)
			continue
		var params = task.get("params", {})
		if typeof(params) != TYPE_DICTIONARY:
			params = {}
		out.append({
			"skillset": ss,
			"skill": sk,
			"target": str(task.get("target", "existing_character")),
			"params": params,
			"fragment": str(task.get("fragment", "")),
		})
	return {"ok": true, "tasks": out, "clarify": "", "unknown": unknown}

func _excerpt(text: String, length: int = 240) -> String:
	var t := text.strip_edges().replace("\n", " ")
	if t.length() > length:
		return t.substr(0, length) + "..."
	return t

# Layer 1: LLM understands the prompt and decomposes it into registry-grounded tasks
func _plan_tasks(prompt: String) -> Array:
	if llm_key.is_empty() and llm_provider != "copilot":
		return [{"error": "LLM API key required. Open Settings to add."}]
	if llm_provider != "openai" and llm_provider != "anthropic" and llm_provider != "openrouter" and llm_provider != "copilot":
		return [{"error": "LLM provider must be openai, anthropic, openrouter, or copilot (Settings)."}]

	var system := """You are a Godot editor task planner. Break the user's prompt into concrete tasks.
Reply with ONLY a JSON object. No explanation, no markdown fences.
Schema:
{"tasks":[{"skillset":"<registry key>","skill":"<skill key inside that skillset>","target":"existing_character|new|<node name>","params":{...},"fragment":"<short echo of the relevant part of the prompt>"}]}
Rules:
- skillset MUST be a top-level key of SKILL_REGISTRY; skill MUST be a key inside that skillset's skills object. Anything else is invalid.
- Behavior applied to an existing character (movement/camera/animation): target "existing_character".
- If the user explicitly wants a NEW character/NPC, use spawn_character/spawn_npc with target "new".
- modify_scale / modify_placement operate on an EXISTING object. Put the object's name in "target" when the prompt names one (e.g. "the sphere" -> "Sphere"). Use session memory's Objects list for real node names. Otherwise target "existing_object".
- modify_scale params: scale_up/scale_down use {"amount": <multiplier>} (e.g. 2 for double, 0.5 for half; default 1.5 / 0.7). scale_to uses {"size": <number>, "axis": "x|y|z|all"} in meters. scale_axis uses {"axis":"x|y|z","amount":<multiplier>}.
- modify_placement params: move uses {"dx":..,"dy":..,"dz":..} meters (or {"direction":"left|right|up|down|forward|back","distance":<m>}). place_on uses {"target":"<node name>"}. align uses {"relation":"left|right|center|front|behind","target":"<node name>"}. rotate uses {"axis":"x|y|z","degrees":<n>}. delete needs no params.
- Decompose multi-part prompts into multiple tasks, preserving execution order.
- dim is 3 unless the prompt clearly asks for 2D / side-scroller / platformer (modify tasks can omit dim).
- If the prompt is not a game-dev request, return {"tasks":[]}.
- If the request is too vague to act on safely (missing which object, or an amount you cannot reasonably default), return {"clarify":"<one short question to the user>"} instead of guessing. Prefer {"tasks":[]} over clarify when a sensible default exists.
SKILL_REGISTRY:
"""
	system += JSON.stringify(SKILL_REGISTRY)
	system += "\nSession memory:\n" + _memory_context()

	var retry_prompt := prompt
	var raw_text := ""
	var parsed := {}
	for attempt in 2:
		var resp := await _llm_chat(system, retry_prompt)
		if resp.has("error"):
			return [{"error": resp["error"]}]
		raw_text = str(resp.get("text", ""))
		parsed = _parse_tasks_json(raw_text)
		if bool(parsed.get("ok", false)):
			var ts: Array = parsed["tasks"]
			if not ts.is_empty():
				return ts
			var clarify := str(parsed.get("clarify", ""))
			if clarify != "":
				return [{"clarify": clarify}]
			# Valid plan, but nothing matched — last resort: local heuristic
			var heur := _heuristic_modify_task(prompt)
			if not heur.is_empty():
				return [heur]
			return []
		var unknown: Array = parsed.get("unknown", [])
		if unknown.size() > 0:
			retry_prompt = prompt + "\n\nIMPORTANT: these are NOT valid: " \
				+ ", ".join(unknown) + ". Valid skillset keys: " \
				+ ", ".join(SKILL_REGISTRY.keys()) \
				+ ". Reply with ONLY valid JSON matching the schema."
		else:
			retry_prompt = prompt + "\n\nIMPORTANT: reply with ONLY valid JSON matching the schema."
	# Both attempts produced unparseable JSON — try the local fallback before failing
	var heur2 := _heuristic_modify_task(prompt)
	if not heur2.is_empty():
		output_append_note("[PLAN] LLM plan unparseable; using local fallback classification.\n")
		return [heur2]
	var msg := "LLM returned invalid task JSON after retry."
	if raw_text != "":
		msg += " Raw response was: \"" + _excerpt(raw_text) + "\""
	return [{"error": msg}]

# Layer 2: Jev validates every task in ONE batched call; Jev wins on disagreement
func _validate_tasks(tasks: Array) -> Array:
	if jev_key.is_empty():
		return [{"error": "Jev API key required. Open Settings to add."}]

	var questions := {}
	for i in tasks.size():
		var ss: String = tasks[i]["skillset"]
		var criteria := {}
		for s in SKILL_REGISTRY[ss]:
			criteria[s] = SKILL_REGISTRY[ss][s]
		questions["task_%d" % i] = {
			"type": "choice",
			"instructions": "Pick the single exact skill that best fulfills this task fragment.",
			"criteria": criteria,
		}

	var state := "Task fragments to classify:\n"
	for i in tasks.size():
		state += "task_%d: %s\n" % [i, tasks[i]["fragment"]]

	var body := {
		"model": "jev-1.13.0",
		"state": state,
		"questions": questions,
	}
	var headers := [
		"Content-Type: application/json",
		"Authorization: Bearer " + jev_key
	]

	var http := HTTPRequest.new()
	http.timeout = 15
	add_child(http)
	var error = http.request("https://api.typesafe.ai/v1/systemone", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		http.queue_free()
		return [{"error": "Jev request failed to start"}]

	var result = await http.request_completed
	http.queue_free()
	if result[0] != HTTPRequest.RESULT_SUCCESS or result[1] != 200:
		return [{"error": "Jev returned " + str(result[1])}]

	var json := JSON.new()
	if json.parse(result[3].get_string_from_utf8()) != OK:
		return [{"error": "Could not parse Jev response"}]

	var data = json.data
	if not data.has("answers"):
		return [{"error": "Jev returned no answers"}]

	var answers = data["answers"]
	for i in tasks.size():
		var key := "task_%d" % i
		if not answers.has(key):
			continue
		var answer = answers[key]
		if typeof(answer) != TYPE_DICTIONARY or not answer.has("choice"):
			continue
		var choice := str(answer["choice"])
		var ss: String = tasks[i]["skillset"]
		if SKILL_REGISTRY[ss].has(choice) and choice != tasks[i]["skill"]:
			tasks[i]["llm_skill"] = tasks[i]["skill"]
			tasks[i]["skill"] = choice
			tasks[i]["corrected"] = true
		tasks[i]["validated"] = true
	return tasks

# Layer 3 prep: merge confirmed tasks into local intent dicts
func _tasks_to_intents(tasks: Array) -> Array:
	var intents: Array = []
	var skill_names := {}
	var want_movement := false
	var want_camera := false
	var want_anim := false
	var target_mode := "existing_character"
	var dim := 3
	var frag_parts: Array[String] = []

	for t in tasks:
		var ss: String = t["skillset"]
		var skill: String = t["skill"]
		var params: Dictionary = t.get("params", {})
		dim = int(params.get("dim", dim))
		match ss:
			"movement", "camera", "animation":
				skill_names[skill] = true
				if ss == "movement": want_movement = true
				elif ss == "camera": want_camera = true
				else: want_anim = true
				if t.get("target", "") == "new":
					target_mode = "new"
				var frag := str(t.get("fragment", ""))
				if frag != "" and frag not in frag_parts:
					frag_parts.append(frag)
			"create_scene":
				intents.append({"kind": "scene", "root": "Node3D" if dim == 3 else "Node2D", "label": "New scene (%dD)" % dim})
			"spawn_prop":
				intents.append({"kind": "prop", "shape": skill, "dim": dim, "label": "%s prop (%dD)" % [skill.capitalize(), dim]})
			"spawn_surface":
				intents.append({"kind": "surface", "shape": skill, "dim": dim, "label": "Surface %s (%dD)" % [skill, dim]})
			"spawn_character":
				intents.append({"kind": "character", "role": skill, "dim": dim, "label": "Character %s (%dD)" % [skill, dim]})
			"spawn_npc":
				intents.append({"kind": "character", "role": "npc", "dim": dim, "label": "NPC (%dD)" % dim})
			"spawn_environment":
				intents.append({"kind": "environment", "element": skill, "dim": dim, "label": "Environment: %s (%dD)" % [skill, dim]})
			"spawn_particles":
				intents.append({"kind": "particles", "effect": skill, "dim": dim, "label": "Particles: %s (%dD)" % [skill, dim]})
			"modify_scale", "modify_placement":
				intents.append({
					"kind": "modify",
					"op": skill,
					"skillset": ss,
					"target": str(t.get("target", "")),
					"params": params,
					"fragment": str(t.get("fragment", "")),
					"label": "%s: %s" % [skill, str(t.get("fragment", "")).strip_edges()],
				})

	# Flush merged behavior-skill intent (one script regen, not N)
	if not skill_names.is_empty():
		var p := " ".join(frag_parts).to_lower()
		var flags := _collect_skill_flags(p, want_movement, want_camera, want_anim)
		# Force flags to exactly the Jev-confirmed skills
		for skillset in SKILL_REGISTRY:
			for s in SKILL_REGISTRY[skillset]:
				if flags.has(s):
					flags[s] = s in skill_names
		var existing := _find_target_character()
		var label := _skill_label(want_movement, want_camera, want_anim)
		if existing != "" and target_mode != "new":
			intents.insert(0, {
				"kind": "skill",
				"target": existing,
				"skills": flags,
				"movement": want_movement,
				"camera": want_camera,
				"animation": want_anim,
				"label": label + " -> " + existing.get_file(),
			})
		else:
			intents.insert(0, {
				"kind": "character_with_skill",
				"role": "player",
				"dim": dim,
				"skills": flags,
				"movement": want_movement,
				"camera": want_camera,
				"animation": want_anim,
				"label": "New character + " + label + " (%dD)" % dim,
			})
	return intents

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
					"apply_skill": "Add behavior/mechanics to an EXISTING character or object: movement, walking, sprinting, jumping, crouching, controls, wasd, camera follow, gravity, physics, AI, state machine — do NOT create a new character if one exists",
					"spawn_prop": "Add a visible object/prop: cube, box, sphere, ball, cylinder, capsule, plane, rock, tree, barrel, crate, pillar, wall, prop",
					"spawn_surface": "Add a walkable/collidable surface: floor, ground, platform, walkable surface, terrain, ceiling, ramp, stairs, path",
					"spawn_character": "Add a NEW character only if none exists: player, playable character, character, avatar, hero",
					"spawn_npc": "Add an NPC or enemy: npc, enemy, mob, creature, ai, bot, villager, guard",
					"spawn_environment": "Add environment: light, sky, water, fog, camera, environment, sun",
					"spawn_particles": "Add effects: particles, fire, smoke, explosion, sparks, rain, snow, dust",
					"add_node": "Add a plain Godot node not covered by other categories",
					"create_scene": "Create a new scene (2D, 3D, or UI based on prompt)",
					"modify_node": "Change properties of existing nodes or player",
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
		return _direct_command(action, prompt)

	var system_prompt = """You are a Godot editor command generator. Reply with ONLY one command, no explanation.
Semantic mappings (user words -> command):
- cube/box/crate -> Spawn prop box
- sphere/ball -> Spawn prop sphere
- walkable surface/floor/ground/platform -> Spawn surface floor
- playable character/player -> Spawn character player
- npc/enemy -> Spawn character npc
- tree/rock -> Spawn prop tree / Spawn prop rock
- sun/light -> Spawn environment sun / light
- fire/smoke/rain particles -> Spawn particles fire/smoke/rain
- create 3d scene -> Create scene Node3D
- add Camera3D -> Add a new Camera3D
Match 2D/3D to the user's request. If unsure reply: Show help"""

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
		return _direct_command(action, prompt)

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
		return _direct_command(action, prompt)

	var result = await http.request_completed
	http.queue_free()

	var request_result = result[0]
	var response_code = result[1]
	var response_body = result[3].get_string_from_utf8()

	if request_result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return _direct_command(action, prompt)

	var json = JSON.new()
	if json.parse(response_body) != OK:
		return _direct_command(action, prompt)

	var data = json.data
	if llm_provider == "openai" and data.has("choices"):
		return String(data["choices"][0]["message"]["content"]).strip_edges()
	elif llm_provider == "anthropic" and data.has("content"):
		return String(data["content"][0]["text"]).strip_edges()

	return _direct_command(action, prompt)

func _direct_command(action: String, prompt: String = "") -> String:
	var p = prompt.to_lower()
	var wants_3d := "3d" in p or "3-d" in p or "3 d" in p
	var wants_ui := "ui" in p or "control" in p or "interface" in p

	match action:
		"apply_skill":
			# Intent resolver handles the real work; this is LLM/direct fallback
			return "Apply skill to existing character"
		"add_node":
			var node_type := _extract_node_type(p, wants_3d)
			return "Add a new " + node_type
		"spawn_prop":
			return "Spawn prop " + _guess_prop_shape(p)
		"spawn_surface":
			return "Spawn surface floor"
		"spawn_character":
			var role := "npc" if _any(p, ["npc", "enemy", "mob"]) else "player"
			return "Spawn character " + role
		"spawn_npc":
			return "Spawn character npc"
		"spawn_environment":
			if _any(p, ["sun", "directional"]): return "Spawn environment sun"
			if _any(p, ["camera"]): return "Spawn environment camera"
			if _any(p, ["water"]): return "Spawn environment water"
			if _any(p, ["sky", "world", "fog"]): return "Spawn environment world"
			return "Spawn environment light"
		"spawn_particles":
			var fx := "fire"
			if "smoke" in p: fx = "smoke"
			elif "rain" in p: fx = "rain"
			elif "snow" in p: fx = "snow"
			elif "spark" in p or "explosion" in p: fx = "sparks"
			elif "magic" in p: fx = "magic"
			return "Spawn particles " + fx
		"create_scene":
			if wants_ui:
				return "Create scene Control"
			return "Create scene Node3D" if wants_3d else "Create scene Node2D"
		"modify_node": return "Modify selected node"
		"create_script": return "Create new script"
		"fix_error": return "Fix the error"
		"run_scene": return "Run current scene"
		"help": return "Show help"
		_: return "Execute: " + action

func _guess_prop_shape(p: String) -> String:
	if _any(p, ["sphere", "ball", "orb"]): return "sphere"
	if _any(p, ["cylinder", "pipe", "column", "pillar", "barrel"]): return "cylinder"
	if _any(p, ["capsule", "pill"]): return "capsule"
	if _any(p, ["plane", "flat"]): return "plane"
	if _any(p, ["cone"]): return "cone"
	if _any(p, ["tree"]): return "tree"
	if _any(p, ["rock", "stone"]): return "rock"
	return "box"

func _extract_node_type(p: String, wants_3d: bool) -> String:
	# Common Godot node names users ask for, longest match first
	var known_3d := [
		"camera3d", "characterbody3d", "animatablebody3d", "staticbody3d",
		"rigidbody3d", "collisionshape3d", "collisionpolygon3d",
		"meshinstance3d", "multimeshinstance3d", "csgbox3d", "csgcombiner3d",
		"directionallight3d", "omnilight3d", "spotlight3d", "worldenvironment",
		"gpuparticles3d", "cpuparticles3d", "sprite3d", "label3d",
		"path3d", "pathfollow3d", "skeleton3d", "boneattachment3d",
		"vehiclebody3d", "vehiclewheel3d", "joint3d", "generic6dofjoint3d",
		"softbody3d", "voxelgi", "lightmapgi", "reflectionprobe",
		"node3d", "marker3d", "remoteTransform3d".to_lower(),
	]
	var known_2d := [
		"characterbody2d", "animatablebody2d", "staticbody2d", "rigidbody2d",
		"collisionshape2d", "collisionpolygon2d", "raycast2d", "shapecast2d",
		"springarm2d", "jointsync2d".to_lower(), "joint2d", "pinjoint2d",
		"sliderjoint2d", "generic6dofjoint2d", "groovejoint2d",
		"camera2d", "meshinstance2d", "multimeshinstance2d",
		"sprite2d", "animatedsprite2d", "label", "richtextlabel",
		"path2d", "pathfollow2d", "line2d", "polygon2d",
		"tilemap", "tilemaplayer", "light2d", "pointlight2d", "directionallight2d",
		"cpuparticles2d", "gpuparticles2d", "visibleonscreennotifier2d",
		"remoteTransform2d", "node2d", "marker2d", "y-sort",
		"button", "texturebutton", "label3d",
	]
	# Try to find an explicit node type mentioned in the prompt
	for n in known_3d:
		if n in p:
			return _godot_class_name(n)
	for n in known_2d:
		if n in p:
			return _godot_class_name(n)
	# Generic words
	if "camera" in p:
		return "Camera3D" if wants_3d else "Camera2D"
	if "light" in p:
		return "DirectionalLight3D" if wants_3d else "PointLight2D"
	if "body" in p or "physics" in p or "player" in p:
		return "CharacterBody3D" if wants_3d else "CharacterBody2D"
	if "mesh" in p or "cube" in p or "box" in p:
		return "MeshInstance3D" if wants_3d else "MeshInstance2D"
	if "sprite" in p or "image" in p or "texture" in p:
		return "Sprite3D" if wants_3d else "Sprite2D"
	if "collision" in p or "shape" in p:
		return "CollisionShape3D" if wants_3d else "CollisionShape2D"
	if "particles" in p or "particle" in p:
		return "GPUParticles3D" if wants_3d else "GPUParticles2D"
	if "ui" in p or "button" in p or "panel" in p or "menu" in p:
		return "Button" if "button" in p else "Control"
	return "Node3D" if wants_3d else "Node2D"

func _godot_class_name(snake: String) -> String:
	# Convert snake/lowercase godot name to proper ClassDB name, e.g. camera3d -> Camera3D
	var special := {
		"csgbox3d": "CSGBox3D", "csgcombiner3d": "CSGCombiner3D",
		"gpuparticles3d": "GPUParticles3D", "cpuparticles3d": "CPUParticles3D",
		"gpuparticles2d": "GPUParticles2D", "cpuparticles2d": "CPUParticles2D",
		"voxelgi": "VoxelGI", "lightmapgi": "LightmapGI",
		"richTextLabel".to_lower(): "RichTextLabel",
		"tileMapLayer".to_lower(): "TileMapLayer",
		"pointLight2d".to_lower(): "PointLight2D",
		"directionalLight2d".to_lower(): "DirectionalLight2D",
		"directionalLight3d".to_lower(): "DirectionalLight3D",
		"remoteTransform2d".to_lower(): "RemoteTransform2D",
		"remoteTransform3d".to_lower(): "RemoteTransform3D",
		"visibleOnscreenNotifier2d".to_lower(): "VisibleOnscreenNotifier2D",
	}
	if special.has(snake):
		return special[snake]
	# Default: capitalize first letter, keep rest (camera3d -> Camera3d wrong)
	# Better: split digit suffix
	if ClassDB.class_exists(snake.capitalize().replace(" ", "")):
		return snake.capitalize().replace(" ", "")
	# Try progressive matching against ClassDB
	for i in range(snake.length(), 0, -1):
		var candidate = snake.substr(0, i).capitalize().replace(" ", "") + snake.substr(i)
		if ClassDB.class_exists(candidate):
			return candidate
		var candidate2 = snake.substr(0, i).capitalize().replace(" ", "") + snake.substr(i).to_upper()
		if ClassDB.class_exists(candidate2):
			return candidate2
	return snake.capitalize().replace(" ", "")

func _execute_command(command: String) -> String:
	if command.begins_with("Add"):
		var node_type = command.replace("Add a new ", "").replace("Add ", "").strip_edges()
		if node_type.is_empty() or not ClassDB.class_exists(node_type):
			node_type = "Node2D"
		var wants_3d = node_type.ends_with("3D") or node_type in ["Node3D", "WorldEnvironment", "ReflectionProbe"]
		var wants_2d = node_type.ends_with("2D") or node_type in ["Node2D", "TileMap", "TileMapLayer"]
		var scene_root = EditorInterface.get_edited_scene_root()
		var created = false

		# Dimension mismatch: open 2D scene but need 3D (or vice versa) -> new scene
		if scene_root and wants_3d and scene_root is Node2D and not scene_root is Node3D:
			scene_root = null
		elif scene_root and wants_2d and scene_root is Node3D:
			scene_root = null

		if not scene_root:
			var root_type = "Node3D" if wants_3d else "Node2D"
			scene_root = _create_new_scene(root_type)
			created = true
			if not scene_root:
				return "Failed to create scene"

		var node = ClassDB.instantiate(node_type)
		if node == null:
			return "Unknown node type: " + node_type
		node.name = node_type
		scene_root.add_child(node)
		node.owner = scene_root
		# 3D nodes need a transform-capable parent chain; Node2D parent can't show them properly
		if created:
			return "Created new " + ("3D" if wants_3d else "2D") + " scene and added " + node_type
		return "Added " + node_type
	elif command.begins_with("Create scene") or command.begins_with("New scene") or command.begins_with("Create Scene"):
		var root_type = "Node2D"
		var cl = command.to_lower()
		if "node3d" in cl or " 3d" in cl or "3d " in cl:
			root_type = "Node3D"
		elif "control" in cl or " ui" in cl or "ui " in cl:
			root_type = "Control"
		elif "node" in cl and "3d" not in cl and "2d" not in cl:
			root_type = "Node"
		var scene_root = _create_new_scene(root_type)
		if scene_root:
			return "Created new " + root_type + " scene: " + scene_root.name
		return "Failed to create scene"
	elif command.begins_with("Spawn"):
		return _execute_spawn(command)
	elif command.begins_with("Apply skill"):
		# Fallback when intent resolver didn't catch it — treat prompt history as skill request
		var last_prompt: String = session_memory["history"].back() if session_memory["history"].size() else ""
		var skill = _resolve_skill(last_prompt.to_lower())
		if skill.is_empty():
			return "No character/skill detected. Try: 'give my player WASD movement and jump'"
		return _build_intent(skill)
	elif command.begins_with("Show help") or command == "help":
		return _help_text()
	elif command.begins_with("List"):
		var root = EditorInterface.get_edited_scene_root()
		if not root:
			return "No scene open"
		var lines = ["Scene: " + str(root.name)]
		if session_memory["last_character"]:
			lines.append("Active character: " + session_memory["last_character"])
		for c in session_memory["characters"]:
			var skills: Array = session_memory["skills_applied"].get(c, [])
			lines.append("  char: " + c + ("  skills=[" + ", ".join(skills) + "]" if skills.size() else ""))
		for cr in session_memory["created"]:
			lines.append("  created: " + cr)
		return "\n".join(lines)
	elif command.begins_with("Run"):
		EditorInterface.play_main_scene()
		return "Running scene..."
	elif command.begins_with("Create"):
		return "Create script: " + command
	return "Command: " + command

func _help_text() -> String:
	return """Natural language (preferred):
  Objects: 'add a cube', 'spawn sphere', 'walkable floor', 'tree', 'crate'
  Characters: 'playable character', 'npc'  (reuses existing — will NOT duplicate)
  Modify existing objects (undoable):
    resize: 'make the sphere bigger', 'shrink the cube by half', 'double the crate'
    move:   'move the sphere 2 meters left', 'shift the tree up'
    place:  'put the cube on the floor', 'align the rock next to the tree'
    rotate: 'rotate the sphere 45 degrees'
    delete: 'remove the cube'
  Movement skills (on EXISTING character):
    walk, sprint, jump, double jump, crouch/sneak, slide, dash,
    air control, coyote time, jump buffer, wall jump, strafe,
    swim, climb, grapple, glide, fly, wasd/controls, gravity
  Camera: 'camera follow', 'third person', 'mouse look', 'fps camera'
  Animation: 'walk animation', 'idle animation' (creates AnimationPlayer clips)
  Examples: 'give controllable character movement with wasd'
            'add sprinting and double jump to my player'
            'make it crouch and slide'
Memory: existing characters/skills are remembered across prompts.
'list' shows what's been built. 'clear' resets memory."""

func _execute_spawn(command: String) -> String:
	var parts = command.split(" ", false, 0)
	# Spawn <kind> <detail...>
	if parts.size() < 2:
		return "Unknown spawn command: " + command
	var kind = parts[1].to_lower()
	var detail = ""
	if parts.size() > 2:
		detail = " ".join(parts.slice(2)).to_lower()
	var p = (kind + " " + detail).to_lower()
	var dim = 3
	if _wants_2d(p) or "2d" in command.to_lower():
		dim = 2
	var intent: Dictionary
	match kind:
		"prop":
			var shape = _guess_prop_shape(command.to_lower())
			intent = {"kind": "prop", "shape": shape, "dim": dim, "label": shape.capitalize() + " (%dD)" % dim}
		"surface":
			intent = {"kind": "surface", "shape": "ramp" if "ramp" in p or "stair" in p else ("wall" if "wall" in p else "box"), "dim": dim, "label": "Walkable surface (%dD)" % dim}
		"character":
			var role = "npc" if "npc" in p or "enemy" in p else "player"
			intent = {"kind": "character", "role": role, "dim": dim, "label": ("NPC/Enemy" if role == "npc" else "Playable character") + " (%dD)" % dim}
		"environment", "env":
			var el = "light"
			if "sun" in p: el = "sun"
			elif "camera" in p: el = "camera"
			elif "water" in p: el = "water"
			elif "sky" in p or "world" in p or "fog" in p: el = "world"
			intent = {"kind": "environment", "element": el, "dim": dim, "label": "Environment: " + el + " (%dD)" % dim}
		"particles", "vfx", "effect":
			var fx = detail if not detail.is_empty() else "fire"
			intent = {"kind": "particles", "effect": fx, "dim": dim, "label": "Particles: " + fx + " (%dD)" % dim}
		"scene":
			var root = "Node3D" if dim == 3 else "Node2D"
			if "control" in p or "ui" in p: root = "Control"
			intent = {"kind": "scene", "root": root, "label": root + " scene"}
		_:
			return "Unknown spawn kind: " + kind
	if intent.is_empty():
		return "Unknown spawn command"
	# Re-resolve dim from full command for 2d/3d keywords
	if _wants_2d(command.to_lower()):
		intent["dim"] = 2
	elif _wants_3d(command.to_lower()):
		intent["dim"] = 3
	return _build_intent(intent)

func _create_new_scene(root_type: String) -> Node:
	if not ClassDB.class_exists(root_type):
		root_type = "Node2D"
	var root = ClassDB.instantiate(root_type)
	if root == null:
		root = Node2D.new()
	if not (root is Node):
		root.free()
		return null
	root.name = "Scene"
	var scene = PackedScene.new()
	if scene.pack(root) != OK:
		root.free()
		return null
	var path = "res://untitled_scene.tscn"
	var counter = 1
	while FileAccess.file_exists(path):
		path = "res://untitled_scene_%d.tscn" % counter
		counter += 1
	if ResourceSaver.save(scene, path) != OK:
		root.free()
		return null
	root.free()
	EditorInterface.open_scene_from_path(path)
	return EditorInterface.get_edited_scene_root()

func _load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://ai_assistant_settings.cfg")
	if err == OK:
		jev_key = config.get_value("api", "jev_key", "")
		llm_key = config.get_value("api", "llm_key", "")
		llm_provider = config.get_value("api", "llm_provider", "openai")
		llm_model = config.get_value("api", "llm_model", "")

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("api", "jev_key", jev_key)
	config.set_value("api", "llm_key", llm_key)
	config.set_value("api", "llm_provider", llm_provider)
	config.set_value("api", "llm_model", llm_model)
	config.save("user://ai_assistant_settings.cfg")
