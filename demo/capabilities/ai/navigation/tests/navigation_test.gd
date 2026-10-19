## Simple Navigation Test
## Tests the navigation system
##
## Run with: godot --headless -s navigation_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Simple Navigation Tests ===\n")
	
	test_navigation_initialization()
	test_target_setting()
	test_movement_settings()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_navigation_initialization() -> void:
	print("Testing initialization...")
	
	var nav = SimpleNavigation.new()
	assert_test(nav.move_speed == 5.0, "Default speed should be 5.0")
	assert_test(nav.is_moving == false, "Should not be moving initially")
	assert_test(nav.path.size() == 0, "Path should be empty")
	
	print("  ✓ Initialization tests passed\n")

func test_target_setting() -> void:
	print("Testing target setting...")
	
	var nav = SimpleNavigation.new()
	nav.target_position = Vector3(10, 0, 10)
	
	assert_test(nav.get_target() == Vector3(10, 0, 10), "Target should be set")
	
	print("  ✓ Target setting tests passed\n")

func test_movement_settings() -> void:
	print("Testing movement settings...")
	
	var nav = SimpleNavigation.new()
	
	nav.set_move_speed(10.0)
	assert_test(nav.move_speed == 10.0, "Speed should be 10.0")
	
	nav.stop()
	assert_test(nav.is_moving == false, "Should not be moving after stop")
	
	print("  ✓ Movement settings tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
