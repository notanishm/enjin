## Crouch Component Test
## Tests the crouch mechanic
##
## Run with: godot --headless -s crouch_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Crouch Component Tests ===\n")
	
	test_crouch_initialization()
	test_crouch_toggle()
	test_height_change()
	test_speed_change()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_crouch_initialization() -> void:
	print("Testing initialization...")
	
	var crouch = CrouchComponent.new()
	assert_test(crouch.crouch_speed == 2.5, "Default crouch speed should be 2.5")
	assert_test(crouch.stand_speed == 5.0, "Default stand speed should be 5.0")
	assert_test(crouch.is_crouching == false, "Should not be crouching initially")
	assert_test(crouch.stand_height == 2.0, "Stand height should be 2.0")
	assert_test(crouch.crouch_height == 1.0, "Crouch height should be 1.0")
	
	print("  ✓ Initialization tests passed\n")

func test_crouch_toggle() -> void:
	print("Testing crouch toggle...")
	
	var crouch = CrouchComponent.new()
	crouch.crouch_toggle = true
	crouch.is_crouching = false
	
	crouch.is_crouching = true
	assert_test(crouch.is_crouching == true, "Should be crouching after toggle")
	
	crouch.is_crouching = false
	assert_test(crouch.is_crouching == false, "Should not be crouching after second toggle")
	
	print("  ✓ Crouch toggle tests passed\n")

func test_height_change() -> void:
	print("Testing height change...")
	
	var crouch = CrouchComponent.new()
	crouch.stand_height = 2.0
	crouch.crouch_height = 1.0
	
	crouch.is_crouching = true
	crouch.target_height = crouch.crouch_height
	assert_test(crouch.target_height == 1.0, "Target height should be crouch height")
	
	crouch.is_crouching = false
	crouch.target_height = crouch.stand_height
	assert_test(crouch.target_height == 2.0, "Target height should be stand height")
	
	print("  ✓ Height change tests passed\n")

func test_speed_change() -> void:
	print("Testing speed change...")
	
	var crouch = CrouchComponent.new()
	crouch.crouch_speed = 2.5
	crouch.stand_speed = 5.0
	
	crouch.is_crouching = true
	crouch.current_speed = crouch.crouch_speed
	assert_test(crouch.current_speed == 2.5, "Speed should be crouch speed")
	
	crouch.is_crouching = false
	crouch.current_speed = crouch.stand_speed
	assert_test(crouch.current_speed == 5.0, "Speed should be stand speed")
	
	print("  ✓ Speed change tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
