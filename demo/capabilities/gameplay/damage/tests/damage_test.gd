## Damage System Test
## Tests the damage system
##
## Run with: godot --headless -s damage_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Damage System Tests ===\n")
	
	test_damage_initialization()
	test_critical_hits()
	test_resistances()
	test_vulnerabilities()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_damage_initialization() -> void:
	print("Testing initialization...")
	
	var damage = DamageSystem.new()
	assert_test(damage.base_damage == 10.0, "Default base damage should be 10.0")
	assert_test(damage.critical_multiplier == 2.0, "Default crit multiplier should be 2.0")
	assert_test(damage.critical_chance == 0.1, "Default crit chance should be 0.1")
	
	print("  ✓ Initialization tests passed\n")

func test_critical_hits() -> void:
	print("Testing critical hits...")
	
	var damage = DamageSystem.new()
	damage.base_damage = 10.0
	damage.critical_multiplier = 2.0
	damage.critical_chance = 1.0  # 100% crit for testing
	
	# Create mock attacker and target
	var attacker = Node.new()
	var target = Node.new()
	target.take_damage = func(amount, src): pass
	
	var result = damage.calculate_damage(attacker, target)
	
	assert_test(result.is_critical == true, "Should be critical hit with 100% chance")
	assert_test(result.raw_damage == 20.0, "Raw damage should be doubled")
	
	print("  ✓ Critical hit tests passed\n")

func test_resistances() -> void:
	print("Testing resistances...")
	
	var damage = DamageSystem.new()
	damage.base_damage = 10.0
	damage.add_resistance("fire", 0.5)  # 50% resistance
	
	var attacker = Node.new()
	var target = Node.new()
	target.take_damage = func(amount, src): pass
	
	var result = damage.calculate_damage(attacker, target, "fire")
	
	assert_test(result.raw_damage == 5.0, "Damage should be halved by resistance")
	
	print("  ✓ Resistance tests passed\n")

func test_vulnerabilities() -> void:
	print("Testing vulnerabilities...")
	
	var damage = DamageSystem.new()
	damage.base_damage = 10.0
	damage.add_vulnerability("ice", 0.5)  # 50% vulnerability
	
	var attacker = Node.new()
	var target = Node.new()
	target.take_damage = func(amount, src): pass
	
	var result = damage.calculate_damage(attacker, target, "ice")
	
	assert_test(result.raw_damage == 15.0, "Damage should be increased by vulnerability")
	
	print("  ✓ Vulnerability tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
