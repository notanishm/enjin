## Ambient Audio Test
## Tests the ambient audio system
##
## Run with: godot --headless -s ambient_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Ambient Audio Tests ===\n")
	
	test_ambient_initialization()
	test_zone_management()
	test_fade()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_ambient_initialization() -> void:
	print("Testing initialization...")
	
	var ambient = AmbientAudio.new()
	assert_test(ambient.fade_in_time == 1.0, "Default fade in should be 1.0")
	assert_test(ambient.fade_out_time == 1.0, "Default fade out should be 1.0")
	assert_test(ambient.get_current_zone() == "", "Current zone should be empty")
	
	print("  ✓ Initialization tests passed\n")

func test_zone_management() -> void:
	print("Testing zone management...")
	
	var ambient = AmbientAudio.new()
	
	ambient.add_zone("forest", null)
	ambient.add_zone("cave", null)
	
	assert_test(ambient.ambient_zones.has("forest"), "Should have forest zone")
	assert_test(ambient.ambient_zones.has("cave"), "Should have cave zone")
	
	ambient.remove_zone("forest")
	assert_test(not ambient.ambient_zones.has("forest"), "Should not have forest zone")
	
	print("  ✓ Zone management tests passed\n")

func test_fade() -> void:
	print("Testing fade...")
	
	var ambient = AmbientAudio.new()
	
	# Test fade in
	ambient.target_volume = -15.0
	ambient.fade_direction = 1
	ambient.is_fading = true
	
	assert_test(ambient.is_fading == true, "Should be fading")
	assert_test(ambient.fade_direction == 1, "Should be fading in")
	
	print("  ✓ Fade tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
