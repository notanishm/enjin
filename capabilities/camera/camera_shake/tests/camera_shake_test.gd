## Camera Shake Test
## Tests the camera shake system
##
## Run with: godot --headless -s camera_shake_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Camera Shake Tests ===\n")
	
	test_shake_initialization()
	test_shake_settings()
	test_shake_activation()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_shake_initialization() -> void:
	print("Testing initialization...")
	
	var shake = CameraShake.new()
	assert_test(shake.shake_intensity == 0.5, "Default intensity should be 0.5")
	assert_test(shake.shake_duration == 0.3, "Default duration should be 0.3")
	assert_test(shake.is_shaking == false, "Should not be shaking initially")
	
	print("  ✓ Initialization tests passed\n")

func test_shake_settings() -> void:
	print("Testing shake settings...")
	
	var shake = CameraShake.new()
	
	shake.set_shake_intensity(1.0)
	assert_test(shake.shake_intensity == 1.0, "Intensity should be 1.0")
	
	shake.set_shake_duration(0.5)
	assert_test(shake.shake_duration == 0.5, "Duration should be 0.5")
	
	shake.set_shake_decay(5.0)
	assert_test(shake.shake_decay == 5.0, "Decay should be 5.0")
	
	print("  ✓ Shake settings tests passed\n")

func test_shake_activation() -> void:
	print("Testing shake activation...")
	
	var shake = CameraShake.new()
	var started = false
	shake.shake_started.connect(func(): started = true)
	
	shake.shake(1.0, 0.5)
	
	assert_test(shake.is_shaking == true, "Should be shaking")
	assert_test(shake.current_shake == 1.0, "Current shake should be 1.0")
	assert_test(shake.shake_time == 0.5, "Shake time should be 0.5")
	assert_test(started == true, "Should emit shake started")
	
	print("  ✓ Shake activation tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
