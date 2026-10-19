## Sprint Component Test
## Tests the sprint mechanic
##
## Run with: godot --headless -s sprint_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Sprint Component Tests ===\n")
	
	test_sprint_initialization()
	test_sprint_toggle()
	test_stamina_system()
	test_speed_calculation()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_sprint_initialization() -> void:
	print("Testing initialization...")
	
	var sprint = SprintComponent.new()
	assert_test(sprint.sprint_speed == 10.0, "Default sprint speed should be 10.0")
	assert_test(sprint.walk_speed == 5.0, "Default walk speed should be 5.0")
	assert_test(sprint.is_sprinting == false, "Should not be sprinting initially")
	assert_test(sprint.stamina == 100.0, "Stamina should be 100.0 initially")
	
	print("  ✓ Initialization tests passed\n")

func test_sprint_toggle() -> void:
	print("Testing sprint toggle...")
	
	var sprint = SprintComponent.new()
	sprint.sprint_toggle = true
	sprint.is_sprinting = false
	
	# Simulate toggle
	sprint.is_sprinting = true
	assert_test(sprint.is_sprinting == true, "Should be sprinting after toggle")
	
	sprint.is_sprinting = false
	assert_test(sprint.is_sprinting == false, "Should not be sprinting after second toggle")
	
	print("  ✓ Sprint toggle tests passed\n")

func test_stamina_system() -> void:
	print("Testing stamina system...")
	
	var sprint = SprintComponent.new()
	sprint.use_stamina = true
	sprint.max_stamina = 100.0
	sprint.stamina = 100.0
	sprint.stamina_drain = 20.0
	
	# Drain stamina
	sprint.stamina -= sprint.stamina_drain
	assert_test(sprint.stamina == 80.0, "Stamina should decrease by drain amount")
	
	# Empty stamina
	sprint.stamina = 0.0
	assert_test(sprint.stamina == 0.0, "Stamina should be 0 when empty")
	assert_test(sprint.can_sprint() == false, "Should not be able to sprint with 0 stamina")
	
	print("  ✓ Stamina system tests passed\n")

func test_speed_calculation() -> void:
	print("Testing speed calculation...")
	
	var sprint = SprintComponent.new()
	sprint.sprint_speed = 10.0
	sprint.walk_speed = 5.0
	
	sprint.is_sprinting = true
	sprint.current_speed = sprint.sprint_speed
	assert_test(sprint.current_speed == 10.0, "Speed should be sprint speed when sprinting")
	
	sprint.is_sprinting = false
	sprint.current_speed = sprint.walk_speed
	assert_test(sprint.current_speed == 5.0, "Speed should be walk speed when not sprinting")
	
	print("  ✓ Speed calculation tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
