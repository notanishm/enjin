## Behavior Tree Test
## Tests the behavior tree system
##
## Run with: godot --headless -s behavior_tree_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Behavior Tree Tests ===\n")
	
	test_bt_initialization()
	test_sequence()
	test_selector()
	test_inverter()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_bt_initialization() -> void:
	print("Testing initialization...")
	
	var bt = SimpleBehaviorTree.new()
	assert_test(bt.enabled == true, "Should be enabled by default")
	assert_test(bt.get_current_state() == "", "Current state should be empty")
	
	print("  ✓ Initialization tests passed\n")

func test_sequence() -> void:
	print("Testing sequence...")
	
	var task1 = SimpleBehaviorTree.BTAction.new()
	task1.action_func = func(delta): return SimpleBehaviorTree.Status.SUCCESS
	
	var task2 = SimpleBehaviorTree.BTAction.new()
	task2.action_func = func(delta): return SimpleBehaviorTree.Status.SUCCESS
	
	var sequence = SimpleBehaviorTree.BTSequence.new()
	sequence.tasks = [task1, task2]
	
	var result = sequence.tick(0.016)
	assert_test(result == SimpleBehaviorTree.Status.SUCCESS, "Sequence should succeed")
	
	print("  ✓ Sequence tests passed\n")

func test_selector() -> void:
	print("Testing selector...")
	
	var task1 = SimpleBehaviorTree.BTAction.new()
	task1.action_func = func(delta): return SimpleBehaviorTree.Status.FAILURE
	
	var task2 = SimpleBehaviorTree.BTAction.new()
	task2.action_func = func(delta): return SimpleBehaviorTree.Status.SUCCESS
	
	var selector = SimpleBehaviorTree.BTSelector.new()
	selector.tasks = [task1, task2]
	
	var result = selector.tick(0.016)
	assert_test(result == SimpleBehaviorTree.Status.SUCCESS, "Selector should succeed on second task")
	
	print("  ✓ Selector tests passed\n")

func test_inverter() -> void:
	print("Testing inverter...")
	
	var task = SimpleBehaviorTree.BTAction.new()
	task.action_func = func(delta): return SimpleBehaviorTree.Status.SUCCESS
	
	var inverter = SimpleBehaviorTree.BTInverter.new()
	inverter.child = task
	
	var result = inverter.tick(0.016)
	assert_test(result == SimpleBehaviorTree.Status.FAILURE, "Inverter should flip SUCCESS to FAILURE")
	
	print("  ✓ Inverter tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
