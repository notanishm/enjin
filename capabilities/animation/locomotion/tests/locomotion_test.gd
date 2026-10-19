## Locomotion Blender Test
## Tests the locomotion animation blending
##
## Run with: godot --headless -s locomotion_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Locomotion Blender Tests ===\n")
	
	test_locomotion_initialization()
	test_velocity_update()
	test_animation_selection()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_locomotion_initialization() -> void:
	print("Testing initialization...")
	
	var locomotion = LocomotionBlender.new()
	assert_test(locomotion.blend_speed == 10.0, "Default blend speed should be 10.0")
	assert_test(locomotion.idle_threshold == 0.1, "Default idle threshold should be 0.1")
	assert_test(locomotion.walk_threshold == 0.5, "Default walk threshold should be 0.5")
	
	print("  ✓ Initialization tests passed\n")

func test_velocity_update() -> void:
	print("Testing velocity update...")
	
	var locomotion = LocomotionBlender.new()
	
	locomotion.set_velocity(Vector3(0, 0, 5))
	assert_test(locomotion.velocity.z == 5.0, "Velocity should be updated")
	
	locomotion.set_grounded(false)
	assert_test(locomotion.is_grounded == false, "Should not be grounded")
	
	locomotion.set_jumping(true)
	assert_test(locomotion.is_jumping == true, "Should be jumping")
	
	print("  ✓ Velocity update tests passed\n")

func test_animation_selection() -> void:
	print("Testing animation selection...")
	
	var locomotion = LocomotionBlender.new()
	
	# Test animation names
	assert_test(locomotion.idle_animation == "idle", "Idle animation should be idle")
	assert_test(locomotion.walk_animation == "walk", "Walk animation should be walk")
	assert_test(locomotion.run_animation == "run", "Run animation should be run")
	
	# Test setting custom animation
	locomotion.set_animation("custom_anim")
	assert_test(locomotion.target_animation == "custom_anim", "Target animation should be custom")
	
	print("  ✓ Animation selection tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
