## Landing VFX Test
## Tests the landing visual effects
##
## Run with: godot --headless -s landing_vfx_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Landing VFX Tests ===\n")
	
	test_landing_initialization()
	test_landing_settings()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_landing_initialization() -> void:
	print("Testing initialization...")
	
	var landing = LandingVFX.new()
	assert_test(landing.min_landing_velocity == 2.0, "Default min velocity should be 2.0")
	assert_test(landing.max_landing_velocity == 15.0, "Default max velocity should be 15.0")
	
	print("  ✓ Initialization tests passed\n")

func test_landing_settings() -> void:
	print("Testing landing settings...")
	
	var landing = LandingVFX.new()
	
	landing.set_min_velocity(3.0)
	assert_test(landing.min_landing_velocity == 3.0, "Min velocity should be 3.0")
	
	landing.set_max_velocity(20.0)
	assert_test(landing.max_landing_velocity == 20.0, "Max velocity should be 20.0")
	
	print("  ✓ Landing settings tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
