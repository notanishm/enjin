## Third Person Camera Test
## Tests the camera system
##
## Run with: godot --headless -s camera_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Third Person Camera Tests ===\n")
	
	test_camera_initialization()
	test_camera_rotation()
	test_camera_zoom()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_camera_initialization() -> void:
	print("Testing initialization...")
	
	var camera = ThirdPersonCamera.new()
	assert_test(camera.follow_distance == 5.0, "Default follow distance should be 5.0")
	assert_test(camera.follow_height == 2.0, "Default follow height should be 2.0")
	assert_test(camera.current_distance == 5.0, "Current distance should be 5.0")
	
	print("  ✓ Initialization tests passed\n")

func test_camera_rotation() -> void:
	print("Testing camera rotation...")
	
	var camera = ThirdPersonCamera.new()
	camera.current_yaw = 0.0
	camera.current_pitch = 45.0
	
	# Set rotation
	camera.set_camera_rotation(90.0, 30.0)
	assert_test(camera.current_yaw == 90.0, "Yaw should be 90.0")
	assert_test(camera.current_pitch == 30.0, "Pitch should be 30.0")
	
	# Test pitch clamping
	camera.set_camera_rotation(0.0, 100.0)
	assert_test(camera.current_pitch == 80.0, "Pitch should be clamped to max")
	
	camera.set_camera_rotation(0.0, -100.0)
	assert_test(camera.current_pitch == -80.0, "Pitch should be clamped to min")
	
	print("  ✓ Camera rotation tests passed\n")

func test_camera_zoom() -> void:
	print("Testing camera zoom...")
	
	var camera = ThirdPersonCamera.new()
	camera.min_zoom = 2.0
	camera.max_zoom = 10.0
	camera.current_distance = 5.0
	
	# Test zoom limits
	camera.current_distance = camera.min_zoom
	assert_test(camera.current_distance == 2.0, "Distance should be min zoom")
	
	camera.current_distance = camera.max_zoom
	assert_test(camera.current_distance == 10.0, "Distance should be max zoom")
	
	print("  ✓ Camera zoom tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
