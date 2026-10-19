## Movement Test
## Tests for character movement capability
##
## Run with: godot --headless -s movement_test.gd

extends SceneTree

## Test Results
var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Character Movement Tests ===\n")
	
	# Run tests
	test_state_enum()
	test_input_direction()
	test_movement_calculation()
	test_jump_mechanics()
	test_coyote_time()
	test_jump_buffer()
	
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

## Test state enumeration
func test_state_enum() -> void:
	print("Testing state enumeration...")
	
	# Create test character
	var character = CharacterBody3D.new()
	var movement_script = load("res://capabilities/character/movement/implementation/character_movement.gd")
	character.set_script(movement_script)
	
	# Test initial state
	assert_test(character.current_state == 0, "Initial state should be IDLE")
	
	# Test state enum values
	assert_test(character.State.IDLE == 0, "IDLE state should be 0")
	assert_test(character.State.WALK == 1, "WALK state should be 1")
	assert_test(character.State.RUN == 2, "RUN state should be 2")
	assert_test(character.State.JUMP == 3, "JUMP state should be 3")
	assert_test(character.State.IN_AIR == 4, "IN_AIR state should be 4")
	
	character.queue_free()
	print("  ✓ State enum tests passed\n")

## Test input direction calculation
func test_input_direction() -> void:
	print("Testing input direction calculation...")
	
	# Create input manager
	var input_manager = Node.new()
	var input_script = load("res://capabilities/character/movement/implementation/input_manager.gd")
	input_manager.set_script(input_script)
	
	# Test movement direction
	var direction = input_manager.get_movement_direction()
	assert_test(direction is Vector3, "Direction should be Vector3")
	assert_test(direction.length() <= 1.0, "Direction should be normalized")
	
	input_manager.queue_free()
	print("  ✓ Input direction tests passed\n")

## Test movement calculation
func test_movement_calculation() -> void:
	print("Testing movement calculation...")
	
	# Create test character
	var character = CharacterBody3D.new()
	var movement_script = load("res://capabilities/character/movement/implementation/character_movement.gd")
	character.set_script(movement_script)
	
	# Test speed variables
	assert_test(character.walk_speed > 0, "Walk speed should be positive")
	assert_test(character.run_speed > character.walk_speed, "Run speed should be greater than walk speed")
	assert_test(character.acceleration > 0, "Acceleration should be positive")
	assert_test(character.deceleration > 0, "Deceleration should be positive")
	
	character.queue_free()
	print("  ✓ Movement calculation tests passed\n")

## Test jump mechanics
func test_jump_mechanics() -> void:
	print("Testing jump mechanics...")
	
	# Create test character
	var character = CharacterBody3D.new()
	var movement_script = load("res://capabilities/character/movement/implementation/character_movement.gd")
	character.set_script(movement_script)
	
	# Test jump variables
	assert_test(character.jump_velocity > 0, "Jump velocity should be positive")
	assert_test(character.max_jumps >= 1, "Max jumps should be at least 1")
	assert_test(character.gravity_multiplier > 0, "Gravity multiplier should be positive")
	
	character.queue_free()
	print("  ✓ Jump mechanics tests passed\n")

## Test coyote time
func test_coyote_time() -> void:
	print("Testing coyote time...")
	
	# Create test character
	var character = CharacterBody3D.new()
	var movement_script = load("res://capabilities/character/movement/implementation/character_movement.gd")
	character.set_script(movement_script)
	
	# Test coyote time variable
	assert_test(character.coyote_time >= 0, "Coyote time should be non-negative")
	assert_test(character.coyote_timer == 0.0, "Coyote timer should start at 0")
	
	character.queue_free()
	print("  ✓ Coyote time tests passed\n")

## Test jump buffer
func test_jump_buffer() -> void:
	print("Testing jump buffer...")
	
	# Create test character
	var character = CharacterBody3D.new()
	var movement_script = load("res://capabilities/character/movement/implementation/character_movement.gd")
	character.set_script(movement_script)
	
	# Test jump buffer variables
	assert_test(character.jump_buffer_time >= 0, "Jump buffer time should be non-negative")
	assert_test(character.jump_buffer_timer == 0.0, "Jump buffer timer should start at 0")
	
	character.queue_free()
	print("  ✓ Jump buffer tests passed\n")

## Assert test helper
func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
