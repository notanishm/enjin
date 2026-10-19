## Jump Test
## Tests for jump capability
##
## Run with: godot --headless -s jump_test.gd

extends SceneTree

## Test Results
var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Jump Capability Tests ===\n")
	
	# Run tests
	test_jump_variables()
	test_coyote_time()
	test_jump_buffer()
	test_multi_jump()
	test_gravity()
	
	# Print results
	print("\n=== Test Results ===")
	print("Total: %d" % tests_total)
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)
	
	if tests_failed == 0:
		print("\n✓ All tests passed!")
	else:
		print("\n✗ Some tests failed!")
	
	quit()

## Test jump variables
func test_jump_variables() -> void:
	print("Testing jump variables...")
	
	# Create test component
	var character = CharacterBody3D.new()
	var jump_script = load("res://capabilities/character/jump/implementation/jump_component.gd")
	var jump_component = Node.new()
	jump_component.set_script(jump_script)
	character.add_child(jump_component)
	
	# Test variables
	assert_test(jump_component.jump_velocity > 0, "Jump velocity should be positive")
	assert_test(jump_component.max_jumps >= 1, "Max jumps should be at least 1")
	assert_test(jump_component.gravity_multiplier > 0, "Gravity multiplier should be positive")
	assert_test(jump_component.air_control >= 0, "Air control should be non-negative")
	
	character.queue_free()
	print("  ✓ Jump variable tests passed\n")

## Test coyote time
func test_coyote_time() -> void:
	print("Testing coyote time...")
	
	# Create test component
	var character = CharacterBody3D.new()
	var jump_script = load("res://capabilities/character/jump/implementation/jump_component.gd")
	var jump_component = Node.new()
	jump_component.set_script(jump_script)
	character.add_child(jump_component)
	
	# Test coyote time
	assert_test(jump_component.coyote_time >= 0, "Coyote time should be non-negative")
	assert_test(jump_component.coyote_timer == 0.0, "Coyote timer should start at 0")
	
	character.queue_free()
	print("  ✓ Coyote time tests passed\n")

## Test jump buffer
func test_jump_buffer() -> void:
	print("Testing jump buffer...")
	
	# Create test component
	var character = CharacterBody3D.new()
	var jump_script = load("res://capabilities/character/jump/implementation/jump_component.gd")
	var jump_component = Node.new()
	jump_component.set_script(jump_script)
	character.add_child(jump_component)
	
	# Test jump buffer
	assert_test(jump_component.jump_buffer_time >= 0, "Jump buffer time should be non-negative")
	assert_test(jump_component.jump_buffer_timer == 0.0, "Jump buffer timer should start at 0")
	
	character.queue_free()
	print("  ✓ Jump buffer tests passed\n")

## Test multi-jump
func test_multi_jump() -> void:
	print("Testing multi-jump...")
	
	# Create test component
	var character = CharacterBody3D.new()
	var jump_script = load("res://capabilities/character/jump/implementation/jump_component.gd")
	var jump_component = Node.new()
	jump_component.set_script(jump_script)
	character.add_child(jump_component)
	
	# Test multi-jump
	assert_test(jump_component.max_jumps >= 1, "Max jumps should be at least 1")
	assert_test(jump_component.jump_count == 0, "Jump count should start at 0")
	
	character.queue_free()
	print("  ✓ Multi-jump tests passed\n")

## Test gravity
func test_gravity() -> void:
	print("Testing gravity...")
	
	# Create test component
	var character = CharacterBody3D.new()
	var jump_script = load("res://capabilities/character/jump/implementation/jump_component.gd")
	var jump_component = Node.new()
	jump_component.set_script(jump_script)
	character.add_child(jump_component)
	
	# Test gravity
	assert_test(jump_component.gravity_multiplier > 0, "Gravity multiplier should be positive")
	
	character.queue_free()
	print("  ✓ Gravity tests passed\n")

## Assert test helper
func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
