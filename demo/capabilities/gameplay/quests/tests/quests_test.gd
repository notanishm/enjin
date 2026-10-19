## Quest System Test
## Tests the quest system
##
## Run with: godot --headless -s quests_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Quest System Tests ===\n")
	
	test_quest_initialization()
	test_add_quest()
	test_start_quest()
	test_complete_quest()
	test_objectives()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_quest_initialization() -> void:
	print("Testing initialization...")
	
	var quests = QuestSystem.new()
	assert_test(quests.quests.size() == 0, "Should have 0 quests initially")
	assert_test(quests.active_quests.size() == 0, "Should have 0 active quests")
	
	print("  ✓ Initialization tests passed\n")

func test_add_quest() -> void:
	print("Testing add quest...")
	
	var quests = QuestSystem.new()
	var quest = QuestSystem.Quest.new("quest1", "Kill Rats", "Kill 5 rats in the basement")
	
	quests.add_quest(quest)
	
	assert_test(quests.quests.size() == 1, "Should have 1 quest")
	assert_test(quests.quests.has("quest1"), "Should have quest1")
	
	print("  ✓ Add quest tests passed\n")

func test_start_quest() -> void:
	print("Testing start quest...")
	
	var quests = QuestSystem.new()
	var quest = QuestSystem.Quest.new("quest1", "Kill Rats", "Kill 5 rats")
	quests.add_quest(quest)
	
	var started = false
	quests.quest_started.connect(func(id): started = true)
	
	quests.start_quest("quest1")
	
	assert_test(started == true, "Should emit started signal")
	assert_test(quest.status == QuestSystem.QuestStatus.ACTIVE, "Quest should be active")
	assert_test(quests.active_quests.has("quest1"), "Should be in active quests")
	
	print("  ✓ Start quest tests passed\n")

func test_complete_quest() -> void:
	print("Testing complete quest...")
	
	var quests = QuestSystem.new()
	var quest = QuestSystem.Quest.new("quest1", "Kill Rats", "Kill 5 rats")
	quests.add_quest(quest)
	quests.start_quest("quest1")
	
	# Add and complete objective
	var obj = QuestSystem.QuestObjective.new("obj1", "Kill rats", "kill", "rat", 5)
	quest.objectives.append(obj)
	
	# Complete objectives
	for i in range(5):
		quests.update_objective("quest1", "obj1")
	
	quests.complete_quest("quest1")
	
	assert_test(quest.status == QuestSystem.QuestStatus.COMPLETED, "Quest should be completed")
	assert_test(quests.completed_quests.has("quest1"), "Should be in completed quests")
	
	print("  ✓ Complete quest tests passed\n")

func test_objectives() -> void:
	print("Testing objectives...")
	
	var quests = QuestSystem.new()
	var quest = QuestSystem.Quest.new("quest1", "Collect Items", "Collect 10 items")
	quests.add_quest(quest)
	
	var obj = QuestSystem.QuestObjective.new("obj1", "Collect items", "collect", "item", 10)
	quest.objectives.append(obj)
	
	# Update objective
	quests.update_objective("quest1", "obj1", 3)
	assert_test(obj.current_amount == 3, "Should have 3 items")
	assert_test(obj.is_completed == false, "Should not be completed")
	
	# Complete objective
	quests.update_objective("quest1", "obj1", 7)
	assert_test(obj.current_amount == 10, "Should have 10 items")
	assert_test(obj.is_completed == true, "Should be completed")
	
	print("  ✓ Objectives tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
