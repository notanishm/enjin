## First Person Camera Test
## Tests the first person camera
##
## Run with: godot --headless -s first_person_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== First Person Camera Tests ===\n")
	
	test_camera_initialization()
	test_sensitivity()
	test_rotation_limits()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_camera_initialization() -> void:
	print("Testing initialization...")
	
	var camera = FirstPersonCamera.new()
	assert_test(camera.mouse_sensitivity == 0.002, "Default sensitivity should be 0.002")
	assert_test(camera.vertical_look_limit == 89.0, "Default vertical limit should be 89.0")
	
	print("  ✓ Initialization tests passed\n")

func test_sensitivity() -> void:
	print("Testing sensitivity...")
	
	var camera = FirstPersonCamera.new()
	
	camera.set_sensitivity(0.01)
	assert_test(camera.mouse_sensitivity == 0.01, "Sensitivity should be 0.01")
	
	print("  ✓ Sensitivity tests passed\n")

func test_rotation_limits() -> void:
	print("Testing rotation limits...")
	
	var camera = FirstPersonCamera.new()
	
	camera.set_vertical_limit(60.0)
	assert_test(camera.vertical_look_limit == 60.0, "Vertical limit should be 60.0")
	
	camera.rotation_x = deg_to_rad(70.0)
	assert_test(rad_to_deg(camera.rotation_x) == 70.0, "Rotation should be set")
	
	print("  ✓ Rotation limits tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
