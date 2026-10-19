## Health System Test
## Tests the health system
##
## Run with: godot --headless -s health_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Health System Tests ===\n")
	
	test_health_initialization()
	test_damage_system()
	test_healing_system()
	test_death_system()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_health_initialization() -> void:
	print("Testing initialization...")
	
	var health = HealthSystem.new()
	assert_test(health.max_health == 100.0, "Default max health should be 100.0")
	assert_test(health.current_health == 100.0, "Current health should be 100.0")
	assert_test(health.is_alive == true, "Should be alive initially")
	
	print("  ✓ Initialization tests passed\n")

func test_damage_system() -> void:
	print("Testing damage system...")
	
	var health = HealthSystem.new()
	health.current_health = 100.0
	
	health.take_damage(30.0)
	assert_test(health.current_health == 70.0, "Health should decrease by damage amount")
	
	health.take_damage(50.0)
	assert_test(health.current_health == 20.0, "Health should decrease further")
	
	# Test damage to 0
	health.take_damage(20.0)
	assert_test(health.current_health == 0.0, "Health should be 0 after lethal damage")
	assert_test(health.is_alive == false, "Should be dead after health reaches 0")
	
	print("  ✓ Damage system tests passed\n")

func test_healing_system() -> void:
	print("Testing healing system...")
	
	var health = HealthSystem.new()
	health.current_health = 50.0
	health.is_alive = true
	
	health.heal(30.0)
	assert_test(health.current_health == 80.0, "Health should increase by heal amount")
	
	health.heal(50.0)
	assert_test(health.current_health == 100.0, "Health should not exceed max health")
	
	print("  ✓ Healing system tests passed\n")

func test_death_system() -> void:
	print("Testing death system...")
	
	var health = HealthSystem.new()
	health.current_health = 100.0
	
	# Die
	health.current_health = 0.0
	health.is_alive = false
	assert_test(health.is_alive == false, "Should be dead")
	
	# Respawn
	health.respawn()
	assert_test(health.current_health == 100.0, "Health should be full after respawn")
	assert_test(health.is_alive == true, "Should be alive after respawn")
	
	print("  ✓ Death system tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
