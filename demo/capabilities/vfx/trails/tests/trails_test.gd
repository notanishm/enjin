## Trail Effect Test
## Tests the trail effect system
##
## Run with: godot --headless -s trails_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Trail Effect Tests ===\n")
	
	test_trail_initialization()
	test_trail_settings()
	test_trail_state()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_trail_initialization() -> void:
	print("Testing initialization...")
	
	var trail = TrailEffect.new()
	assert_test(trail.trail_length == 1.0, "Default length should be 1.0")
	assert_test(trail.trail_width == 0.1, "Default width should be 0.1")
	assert_test(trail.is_active == false, "Should not be active initially")
	
	print("  ✓ Initialization tests passed\n")

func test_trail_settings() -> void:
	print("Testing trail settings...")
	
	var trail = TrailEffect.new()
	
	trail.set_width(0.5)
	assert_test(trail.trail_width == 0.5, "Width should be 0.5")
	
	trail.set_length(2.0)
	assert_test(trail.trail_length == 2.0, "Length should be 2.0")
	
	trail.set_lifetime(1.0)
	assert_test(trail.trail_lifetime == 1.0, "Lifetime should be 1.0")
	
	print("  ✓ Trail settings tests passed\n")

func test_trail_state() -> void:
	print("Testing trail state...")
	
	var trail = TrailEffect.new()
	
	trail.start()
	assert_test(trail.is_active == true, "Should be active after start")
	assert_test(trail.trail_points.size() == 0, "Should have 0 points initially")
	
	trail.stop()
	assert_test(trail.is_active == false, "Should not be active after stop")
	
	print("  ✓ Trail state tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
