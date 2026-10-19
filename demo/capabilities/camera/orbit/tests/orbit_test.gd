## Orbit Camera Test
## Tests the orbit camera system
##
## Run with: godot --headless -s orbit_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Orbit Camera Tests ===\n")
	
	test_orbit_initialization()
	test_orbit_settings()
	test_orbit_angle()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_orbit_initialization() -> void:
	print("Testing initialization...")
	
	var orbit = OrbitCamera.new()
	assert_test(orbit.orbit_distance == 5.0, "Default distance should be 5.0")
	assert_test(orbit.orbit_height == 2.0, "Default height should be 2.0")
	assert_test(orbit.orbit_speed == 0.5, "Default speed should be 0.5")
	
	print("  ✓ Initialization tests passed\n")

func test_orbit_settings() -> void:
	print("Testing orbit settings...")
	
	var orbit = OrbitCamera.new()
	
	orbit.set_orbit_distance(10.0)
	assert_test(orbit.orbit_distance == 10.0, "Distance should be 10.0")
	
	orbit.set_orbit_height(3.0)
	assert_test(orbit.orbit_height == 3.0, "Height should be 3.0")
	
	orbit.set_orbit_speed(1.0)
	assert_test(orbit.orbit_speed == 1.0, "Speed should be 1.0")
	
	print("  ✓ Orbit settings tests passed\n")

func test_orbit_angle() -> void:
	print("Testing orbit angle...")
	
	var orbit = OrbitCamera.new()
	
	orbit.set_angle(90.0)
	assert_test(orbit.get_angle() == 90.0, "Angle should be 90.0")
	
	print("  ✓ Orbit angle tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
