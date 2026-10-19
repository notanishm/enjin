## Proximity Detector Test
## Tests the proximity detection system
##
## Run with: godot --headless -s proximity_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Proximity Detector Tests ===\n")
	
	test_proximity_initialization()
	test_detection_settings()
	test_closest_object()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_proximity_initialization() -> void:
	print("Testing initialization...")
	
	var proximity = ProximityDetector.new()
	assert_test(proximity.detection_radius == 3.0, "Default radius should be 3.0")
	assert_test(proximity.is_active == true, "Should be active by default")
	assert_test(proximity.detected_objects.size() == 0, "Should have 0 detected objects")
	
	print("  ✓ Initialization tests passed\n")

func test_detection_settings() -> void:
	print("Testing detection settings...")
	
	var proximity = ProximityDetector.new()
	
	proximity.set_detection_radius(5.0)
	assert_test(proximity.detection_radius == 5.0, "Radius should be 5.0")
	
	proximity.set_active(false)
	assert_test(proximity.is_active == false, "Should be inactive")
	
	print("  ✓ Detection settings tests passed\n")

func test_closest_object() -> void:
	print("Testing closest object...")
	
	var proximity = ProximityDetector.new()
	
	# Add some objects
	var obj1 = Node3D.new()
	obj1.global_position = Vector3(1, 0, 0)
	var obj2 = Node3D.new()
	obj2.global_position = Vector3(5, 0, 0)
	
	proximity.detected_objects = [obj1, obj2]
	proximity.global_position = Vector3.ZERO
	
	var closest = proximity._find_closest_object()
	assert_test(closest == obj1, "Closest should be obj1")
	
	print("  ✓ Closest object tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
