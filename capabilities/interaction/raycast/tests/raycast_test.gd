## Raycast Interactor Test
## Tests the raycast interaction system
##
## Run with: godot --headless -s raycast_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Raycast Interactor Tests ===\n")
	
	test_raycast_initialization()
	test_target_detection()
	test_interaction()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_raycast_initialization() -> void:
	print("Testing initialization...")
	
	var raycast = RaycastInteractor.new()
	assert_test(raycast.ray_length == 10.0, "Default ray length should be 10.0")
	assert_test(raycast.has_target() == false, "Should have no target initially")
	
	print("  ✓ Initialization tests passed\n")

func test_target_detection() -> void:
	print("Testing target detection...")
	
	var raycast = RaycastInteractor.new()
	
	# Simulate finding target
	var target = Node3D.new()
	raycast.current_target = target
	
	assert_test(raycast.has_target() == true, "Should have target")
	assert_test(raycast.get_current_target() == target, "Should return current target")
	
	# Clear target
	raycast.current_target = null
	assert_test(raycast.has_target() == false, "Should have no target")
	
	print("  ✓ Target detection tests passed\n")

func test_interaction() -> void:
	print("Testing interaction...")
	
	var raycast = RaycastInteractor.new()
	
	# Create interactable target
	var target = Node3D.new()
	target.on_interact = func(): pass
	target.on_interact_hover = func(): pass
	target.on_interact_exit = func(): pass
	
	raycast.current_target = target
	
	# Test interaction started signal
	var interacted = false
	raycast.interaction_started.connect(func(t): interacted = true)
	
	raycast._perform_interaction(target)
	assert_test(interacted == true, "Should emit interaction started")
	
	print("  ✓ Interaction tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
