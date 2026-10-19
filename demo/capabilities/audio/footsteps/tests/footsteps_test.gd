## Footstep Player Test
## Tests the footstep audio system
##
## Run with: godot --headless -s footsteps_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Footstep Player Tests ===\n")
	
	test_footstep_initialization()
	test_surface_sounds()
	test_timing()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_footstep_initialization() -> void:
	print("Testing initialization...")
	
	var footsteps = FootstepPlayer.new()
	assert_test(footsteps.min_interval == 0.3, "Default min interval should be 0.3")
	assert_test(footsteps.max_interval == 0.5, "Default max interval should be 0.5")
	assert_test(footsteps.is_walking == false, "Should not be walking initially")
	
	print("  ✓ Initialization tests passed\n")

func test_surface_sounds() -> void:
	print("Testing surface sounds...")
	
	var footsteps = FootstepPlayer.new()
	
	var concrete_sounds: Array[AudioStream] = []
	var grass_sounds: Array[AudioStream] = []
	
	footsteps.add_surface_sound("concrete", concrete_sounds)
	footsteps.add_surface_sound("grass", grass_sounds)
	
	assert_test(footsteps.surface_sounds.has("concrete"), "Should have concrete sounds")
	assert_test(footsteps.surface_sounds.has("grass"), "Should have grass sounds")
	
	footsteps.set_surface("concrete")
	assert_test(footsteps.get_current_surface() == "concrete", "Current surface should be concrete")
	
	print("  ✓ Surface sounds tests passed\n")

func test_timing() -> void:
	print("Testing timing...")
	
	var footsteps = FootstepPlayer.new()
	footsteps.min_interval = 0.3
	footsteps.max_interval = 0.5
	
	# Test random interval
	footsteps._randomize_interval()
	assert_test(footsteps.next_interval >= 0.3, "Interval should be >= min")
	assert_test(footsteps.next_interval <= 0.5, "Interval should be <= max")
	
	# Test walking state
	footsteps.start_walking()
	assert_test(footsteps.is_walking == true, "Should be walking")
	
	footsteps.stop_walking()
	assert_test(footsteps.is_walking == false, "Should not be walking")
	
	print("  ✓ Timing tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
