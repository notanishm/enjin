## Compatibility Engine Test
## Tests the capability compatibility engine
##
## Run with: godot --headless -s compatibility_test.gd

extends SceneTree

## Test Results
var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Capability Compatibility Engine Tests ===\n")
	
	# Run tests
	test_engine_initialization()
	test_source_profile_creation()
	test_project_profile_creation()
	test_compatibility_analysis()
	test_report_generation()
	
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

## Test engine initialization
func test_engine_initialization() -> void:
	print("Testing engine initialization...")
	
	var engine = CapabilityCompatibilityEngine.new()
	assert_test(engine != null, "Engine should be created")
	assert_test(engine is CapabilityCompatibilityEngine, "Engine should be correct type")
	
	print("  ✓ Engine initialization tests passed\n")

## Test source profile creation
func test_source_profile_creation() -> void:
	print("Testing source profile creation...")
	
	var profile = CapabilityCompatibilityEngine.SourceProfile.new()
	profile.source_id = "test_source"
	profile.repository = "test/repo"
	profile.license = "MIT"
	profile.godot_versions = ["4.x"]
	profile.language = "GDScript"
	profile.architecture = "CharacterBody3D"
	profile.dependencies = []
	profile.features = ["movement", "jump"]
	profile.required_components = ["CharacterBody3D"]
	profile.optional_components = ["AnimationTree"]
	
	assert_test(profile.source_id == "test_source", "Source ID should be set")
	assert_test(profile.license == "MIT", "License should be set")
	assert_test(profile.godot_versions.size() == 1, "Godot versions should have 1 entry")
	
	print("  ✓ Source profile creation tests passed\n")

## Test project profile creation
func test_project_profile_creation() -> void:
	print("Testing project profile creation...")
	
	var profile = CapabilityCompatibilityEngine.ProjectProfile.new()
	profile.godot_version = "4.x"
	profile.language = "GDScript"
	profile.node_types = ["CharacterBody3D"]
	profile.physics_engine = "GodotPhysics3D"
	profile.input_system = "Godot"
	profile.has_animation_tree = true
	profile.has_physics = true
	profile.has_networking = false
	profile.license = "MIT"
	
	assert_test(profile.godot_version == "4.x", "Godot version should be set")
	assert_test(profile.language == "GDScript", "Language should be set")
	assert_test(profile.node_types.size() == 1, "Node types should have 1 entry")
	
	print("  ✓ Project profile creation tests passed\n")

## Test compatibility analysis
func test_compatibility_analysis() -> void:
	print("Testing compatibility analysis...")
	
	var engine = CapabilityCompatibilityEngine.new()
	
	# Create source profile
	var source = CapabilityCompatibilityEngine.SourceProfile.new()
	source.source_id = "third_person_controller"
	source.repository = "Jeh3no/Godot-Third-Person-Controller"
	source.license = "MIT"
	source.godot_versions = ["4.x"]
	source.language = "GDScript"
	source.architecture = "CharacterBody3D"
	source.dependencies = []
	source.features = ["movement", "jump", "camera"]
	source.required_components = ["CharacterBody3D"]
	source.optional_components = ["AnimationTree", "Camera3D"]
	
	# Create target project profile
	var target = CapabilityCompatibilityEngine.ProjectProfile.new()
	target.godot_version = "4.x"
	target.language = "GDScript"
	target.node_types = ["CharacterBody3D"]
	target.physics_engine = "GodotPhysics3D"
	target.input_system = "Godot"
	target.has_animation_tree = true
	target.has_physics = true
	target.has_networking = false
	target.license = "MIT"
	
	# Analyze compatibility
	var result = engine.analyze_compatibility(source, target)
	
	assert_test(result != null, "Result should be created")
	assert_test(result.source_id == "third_person_controller", "Source ID should match")
	assert_test(result.overall_score > 0.0, "Overall score should be positive")
	assert_test(result.overall_score <= 1.0, "Overall score should be <= 1.0")
	assert_test(result.is_compatible == true, "Should be compatible")
	assert_test(result.integration_difficulty == "easy", "Difficulty should be easy")
	
	print("  ✓ Compatibility analysis tests passed\n")

## Test report generation
func test_report_generation() -> void:
	print("Testing report generation...")
	
	var engine = CapabilityCompatibilityEngine.new()
	
	# Create source profile
	var source = CapabilityCompatibilityEngine.SourceProfile.new()
	source.source_id = "third_person_controller"
	source.repository = "Jeh3no/Godot-Third-Person-Controller"
	source.license = "MIT"
	source.godot_versions = ["4.x"]
	source.language = "GDScript"
	source.architecture = "CharacterBody3D"
	source.dependencies = []
	source.features = ["movement", "jump"]
	source.required_components = ["CharacterBody3D"]
	source.optional_components = ["AnimationTree"]
	
	# Create target project profile
	var target = CapabilityCompatibilityEngine.ProjectProfile.new()
	target.godot_version = "4.x"
	target.language = "GDScript"
	target.node_types = ["CharacterBody3D"]
	target.physics_engine = "GodotPhysics3D"
	target.input_system = "Godot"
	target.has_animation_tree = true
	target.has_physics = true
	target.has_networking = false
	target.license = "MIT"
	
	# Generate report
	var report = engine.generate_report(source, target)
	
	assert_test(report != null, "Report should be generated")
	assert_test(report.length() > 0, "Report should not be empty")
	assert_test(report.contains("third_person_controller"), "Report should contain source ID")
	assert_test(report.contains("Overall Score"), "Report should contain score")
	
	print("  ✓ Report generation tests passed\n")
	
	# Print sample report
	print("Sample Report:")
	print(report)

## Assert test helper
func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
