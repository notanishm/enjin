## Dust Effect Test
## Tests the dust particle effect
##
## Run with: godot --headless -s dust_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Dust Effect Tests ===\n")
	
	test_dust_initialization()
	test_dust_settings()
	test_dust_emission()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_dust_initialization() -> void:
	print("Testing initialization...")
	
	var dust = DustEffect.new()
	assert_test(dust.dust_amount == 20, "Default amount should be 20")
	assert_test(dust.dust_lifetime == 0.5, "Default lifetime should be 0.5")
	
	print("  ✓ Initialization tests passed\n")

func test_dust_settings() -> void:
	print("Testing dust settings...")
	
	var dust = DustEffect.new()
	
	dust.set_dust_amount(50)
	assert_test(dust.dust_amount == 50, "Amount should be 50")
	
	dust.set_dust_lifetime(1.0)
	assert_test(dust.dust_lifetime == 1.0, "Lifetime should be 1.0")
	
	print("  ✓ Dust settings tests passed\n")

func test_dust_emission() -> void:
	print("Testing dust emission...")
	
	var dust = DustEffect.new()
	
	dust.emit_dust(Vector3(1, 2, 3))
	assert_test(dust.global_position == Vector3(1, 2, 3), "Position should be set")
	
	print("  ✓ Dust emission tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
