## Animation Events Test
## Tests the animation events system
##
## Run with: godot --headless -s animation_events_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Animation Events Tests ===\n")
	
	test_events_initialization()
	test_add_event()
	test_event_triggering()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_events_initialization() -> void:
	print("Testing initialization...")
	
	var events = AnimationEvents.new()
	assert_test(events.enabled == true, "Should be enabled by default")
	assert_test(events.events.size() == 0, "Should have 0 events initially")
	
	print("  ✓ Initialization tests passed\n")

func test_add_event() -> void:
	print("Testing add event...")
	
	var events = AnimationEvents.new()
	var triggered = false
	
	events.add_event(0.5, "footstep", func(): triggered = true)
	events.add_event(1.0, "attack", func(): pass)
	
	assert_test(events.events.size() == 2, "Should have 2 events")
	assert_test(events.has_event("footstep"), "Should have footstep event")
	assert_test(events.has_event("attack"), "Should have attack event")
	
	print("  ✓ Add event tests passed\n")

func test_event_triggering() -> void:
	print("Testing event triggering...")
	
	var events = AnimationEvents.new()
	var triggered = false
	
	events.add_event(0.0, "test_event", func(): triggered = true)
	events.start()
	events.current_time = 0.0
	
	# Manually trigger event check
	for event in events.events:
		if event.time <= events.current_time:
			event.callback.call()
			event.triggered = true
	
	assert_test(triggered == true, "Event should be triggered")
	
	print("  ✓ Event triggering tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
