## Dialogue System Test
## Tests the dialogue system
##
## Run with: godot --headless -s dialogue_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Dialogue System Tests ===\n")
	
	test_dialogue_initialization()
	test_add_dialogue_node()
	test_start_dialogue()
	test_advance_dialogue()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_dialogue_initialization() -> void:
	print("Testing initialization...")
	
	var dialogue = DialogueSystem.new()
	assert_test(dialogue.is_active() == false, "Should not be active initially")
	assert_test(dialogue.dialogue_tree.size() == 0, "Dialogue tree should be empty")
	
	print("  ✓ Initialization tests passed\n")

func test_add_dialogue_node() -> void:
	print("Testing add dialogue node...")
	
	var dialogue = DialogueSystem.new()
	
	dialogue.add_node("start", "NPC", "Hello, traveler!")
	dialogue.add_node("end", "NPC", "Goodbye!")
	
	assert_test(dialogue.dialogue_tree.size() == 2, "Should have 2 nodes")
	assert_test(dialogue.dialogue_tree.has("start"), "Should have start node")
	assert_test(dialogue.dialogue_tree.has("end"), "Should have end node")
	
	var start_node = dialogue.dialogue_tree["start"]
	assert_test(start_node.speaker == "NPC", "Speaker should be NPC")
	assert_test(start_node.text == "Hello, traveler!", "Text should match")
	
	print("  ✓ Add dialogue node tests passed\n")

func test_start_dialogue() -> void:
	print("Testing start dialogue...")
	
	var dialogue = DialogueSystem.new()
	dialogue.add_node("start", "NPC", "Hello!")
	dialogue.add_node("next", "NPC", "How are you?")
	
	# Connect signal to capture
	var started = false
	dialogue.dialogue_started.connect(func(s): started = true)
	
	dialogue.start_dialogue("start")
	
	assert_test(dialogue.is_active() == true, "Should be active after start")
	assert_test(dialogue.get_current_speaker() == "NPC", "Speaker should be NPC")
	assert_test(dialogue.get_current_text() == "Hello!", "Text should match")
	
	print("  ✓ Start dialogue tests passed\n")

func test_advance_dialogue() -> void:
	print("Testing advance dialogue...")
	
	var dialogue = DialogueSystem.new()
	dialogue.add_node("start", "NPC", "Line 1", "next")
	dialogue.add_node("next", "NPC", "Line 2")
	
	dialogue.start_dialogue("start")
	dialogue.advance_dialogue()
	
	assert_test(dialogue.get_current_text() == "Line 2", "Should advance to next line")
	
	dialogue.advance_dialogue()
	assert_test(dialogue.is_active() == false, "Should end after last line")
	
	print("  ✓ Advance dialogue tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
