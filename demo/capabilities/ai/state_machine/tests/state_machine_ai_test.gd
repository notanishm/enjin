## Simple State Machine Test
## Tests the AI state machine
##
## Run with: godot --headless -s state_machine_ai_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Simple State Machine Tests ===\n")
	
	test_state_machine_initialization()
	test_add_state()
	test_state_transitions()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_state_machine_initialization() -> void:
	print("Testing initialization...")
	
	var sm = SimpleStateMachine.new()
	assert_test(sm.states.size() == 0, "Should have 0 states initially")
	assert_test(sm.get_current_state() == "", "Current state should be empty")
	
	print("  ✓ Initialization tests passed\n")

func test_add_state() -> void:
	print("Testing add state...")
	
	var sm = SimpleStateMachine.new()
	sm.add_state("idle")
	sm.add_state("patrol")
	sm.add_state("chase")
	
	assert_test(sm.states.size() == 3, "Should have 3 states")
	assert_test(sm.has_state("idle"), "Should have idle state")
	assert_test(sm.has_state("patrol"), "Should have patrol state")
	assert_test(sm.has_state("chase"), "Should have chase state")
	
	print("  ✓ Add state tests passed\n")

func test_state_transitions() -> void:
	print("Testing state transitions...")
	
	var sm = SimpleStateMachine.new()
	sm.add_state("idle")
	sm.add_state("patrol")
	
	sm.start()
	assert_test(sm.get_current_state() == "idle", "Should start in idle")
	
	sm.change_state("patrol")
	assert_test(sm.get_current_state() == "patrol", "Should transition to patrol")
	
	sm.change_state("idle")
	assert_test(sm.get_current_state() == "idle", "Should transition back to idle")
	
	print("  ✓ State transition tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
