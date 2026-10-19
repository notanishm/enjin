## Interactable Test
## Tests the interactable component
##
## Run with: godot --headless -s interactable_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Interactable Tests ===\n")
	
	test_interactable_initialization()
	test_enable_disable()
	test_interaction()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_interactable_initialization() -> void:
	print("Testing initialization...")
	
	var interactable = Interactable.new()
	assert_test(interactable.interactable_name == "Object", "Default name should be Object")
	assert_test(interactable.enabled == true, "Should be enabled by default")
	assert_test(interactable.one_shot == false, "Should not be one-shot by default")
	
	print("  ✓ Initialization tests passed\n")

func test_enable_disable() -> void:
	print("Testing enable/disable...")
	
	var interactable = Interactable.new()
	
	interactable.set_enabled(false)
	assert_test(interactable.is_enabled() == false, "Should be disabled")
	
	interactable.set_enabled(true)
	assert_test(interactable.is_enabled() == true, "Should be enabled")
	
	print("  ✓ Enable/disable tests passed\n")

func test_interaction() -> void:
	print("Testing interaction...")
	
	var interactable = Interactable.new()
	var interacted = false
	interactable.interacted.connect(func(): interacted = true)
	
	interactable.on_interact()
	assert_test(interacted == true, "Should emit interacted signal")
	assert_test(interactable.has_been_interacted == true, "Should be marked as interacted")
	
	# Test one-shot
	interactable.one_shot = true
	interacted = false
	interactable.on_interact()
	assert_test(interacted == false, "Should not interact again with one-shot")
	
	print("  ✓ Interaction tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
