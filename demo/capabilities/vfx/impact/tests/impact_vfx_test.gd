## Impact VFX Test
## Tests the impact visual effects
##
## Run with: godot --headless -s impact_vfx_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Impact VFX Tests ===\n")
	
	test_impact_initialization()
	test_impact_settings()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_impact_initialization() -> void:
	print("Testing initialization...")
	
	var impact = ImpactVFX.new()
	assert_test(impact.min_impact_velocity == 2.0, "Default min velocity should be 2.0")
	assert_test(impact.max_impact_velocity == 20.0, "Default max velocity should be 20.0")
	
	print("  ✓ Initialization tests passed\n")

func test_impact_settings() -> void:
	print("Testing impact settings...")
	
	var impact = ImpactVFX.new()
	
	impact.set_min_velocity(5.0)
	assert_test(impact.min_impact_velocity == 5.0, "Min velocity should be 5.0")
	
	impact.set_max_velocity(30.0)
	assert_test(impact.max_impact_velocity == 30.0, "Max velocity should be 30.0")
	
	print("  ✓ Impact settings tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
