## Impact Audio Test
## Tests the impact audio system
##
## Run with: godot --headless -s impact_audio_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Impact Audio Tests ===\n")
	
	test_impact_initialization()
	test_impact_settings()
	test_surface_sounds()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_impact_initialization() -> void:
	print("Testing initialization...")
	
	var impact = ImpactAudio.new()
	assert_test(impact.min_impact_velocity == 2.0, "Default min velocity should be 2.0")
	assert_test(impact.max_impact_velocity == 20.0, "Default max velocity should be 20.0")
	
	print("  ✓ Initialization tests passed\n")

func test_impact_settings() -> void:
	print("Testing impact settings...")
	
	var impact = ImpactAudio.new()
	
	impact.set_min_impact_velocity(5.0)
	assert_test(impact.min_impact_velocity == 5.0, "Min velocity should be 5.0")
	
	impact.set_volume(-5.0)
	assert_test(impact.volume_db == -5.0, "Volume should be -5.0")
	
	print("  ✓ Impact settings tests passed\n")

func test_surface_sounds() -> void:
	print("Testing surface sounds...")
	
	var impact = ImpactAudio.new()
	
	impact.add_surface_impact("metal", [])
	impact.add_surface_impact("wood", [])
	
	assert_test(impact.surface_impacts.has("metal"), "Should have metal sounds")
	assert_test(impact.surface_impacts.has("wood"), "Should have wood sounds")
	
	print("  ✓ Surface sounds tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
