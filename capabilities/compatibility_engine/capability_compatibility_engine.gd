## Capability Compatibility Engine
## Tests source implementations against capability interfaces
## Calculates compatibility scores and generates integration recommendations

class_name CapabilityCompatibilityEngine
extends RefCounted

## Compatibility Factors
enum CompatibilityFactor {
	GODOT_VERSION,
	LANGUAGE,
	NODE_ARCHITECTURE,
	SCENE_ARCHITECTURE,
	PHYSICS_ARCHITECTURE,
	INPUT_ARCHITECTURE,
	ANIMATION_ARCHITECTURE,
	RESOURCE_ARCHITECTURE,
	DEPENDENCY_ARCHITECTURE,
	PLUGIN_REQUIREMENTS,
	ENGINE_MODIFICATIONS,
	RENDERING_ASSUMPTIONS,
	NETWORKING_ASSUMPTIONS,
	LICENSE,
	ASSET_DEPENDENCIES
}

## Compatibility Results
class CompatibilityResult:
	var source_id: String
	var target_project: String
	var overall_score: float
	var factor_scores: Dictionary
	var warnings: Array
	var errors: Array
	var recommendations: Array
	var is_compatible: bool
	var integration_difficulty: String
	
	func _init():
		factor_scores = {}
		warnings = []
		errors = []
		recommendations = []
		is_compatible = true
		integration_difficulty = "unknown"

## Project Profile
class ProjectProfile:
	var godot_version: String
	var language: String
	var node_types: Array
	var physics_engine: String
	var input_system: String
	var has_animation_tree: bool
	var has_physics: bool
	var has_networking: bool
	var license: String
	
	func _init():
		node_types = []
		godot_version = "4.x"
		language = "GDScript"
		physics_engine = "GodotPhysics3D"
		input_system = "Godot"
		has_animation_tree = false
		has_physics = true
		has_networking = false
		license = "MIT"

## Source Profile
class SourceProfile:
	var source_id: String
	var repository: String
	var license: String
	var godot_versions: Array
	var language: String
	var architecture: String
	var dependencies: Array
	var features: Array
	var required_components: Array
	var optional_components: Array
	
	func _init():
		godot_versions = []
		dependencies = []
		features = []
		required_components = []
		optional_components = []

## Main Analysis Function
func analyze_compatibility(source: SourceProfile, target: ProjectProfile) -> CompatibilityResult:
	var result = CompatibilityResult.new()
	result.source_id = source.source_id
	result.target_project = target.godot_version
	
	# Analyze each factor
	result.factor_scores[CompatibilityFactor.GODOT_VERSION] = _analyze_godot_version(source, target)
	result.factor_scores[CompatibilityFactor.LANGUAGE] = _analyze_language(source, target)
	result.factor_scores[CompatibilityFactor.NODE_ARCHITECTURE] = _analyze_node_architecture(source, target)
	result.factor_scores[CompatibilityFactor.PHYSICS_ARCHITECTURE] = _analyze_physics_architecture(source, target)
	result.factor_scores[CompatibilityFactor.INPUT_ARCHITECTURE] = _analyze_input_architecture(source, target)
	result.factor_scores[CompatibilityFactor.LICENSE] = _analyze_license(source, target)
	result.factor_scores[CompatibilityFactor.DEPENDENCY_ARCHITECTURE] = _analyze_dependencies(source, target)
	
	# Calculate overall score
	result.overall_score = _calculate_overall_score(result.factor_scores)
	
	# Determine compatibility
	result.is_compatible = result.overall_score >= 0.7
	
	# Determine integration difficulty
	result.integration_difficulty = _determine_difficulty(result.overall_score)
	
	# Generate recommendations
	result.recommendations = _generate_recommendations(source, target, result)
	
	# Generate warnings
	result.warnings = _generate_warnings(source, target, result)
	
	return result

## Analyze Godot Version Compatibility
func _analyze_godot_version(source: SourceProfile, target: ProjectProfile) -> float:
	for version in source.godot_versions:
		if version == target.godot_version:
			return 1.0
		elif version.begins_with(target.godot_version.left(1)):
			return 0.8
	
	# Check for version compatibility
	if target.godot_version.begins_with("4") and "4.x" in source.godot_versions:
		return 0.9
	
	return 0.3

## Analyze Language Compatibility
func _analyze_language(source: SourceProfile, target: ProjectProfile) -> float:
	if source.language == target.language:
		return 1.0
	
	# GDScript and C# are somewhat compatible
	if (source.language == "GDScript" and target.language == "C#") or \
	   (source.language == "C#" and target.language == "GDScript"):
		return 0.6
	
	return 0.3

## Analyze Node Architecture Compatibility
func _analyze_node_architecture(source: SourceProfile, target: ProjectProfile) -> float:
	var score = 1.0
	
	for component in source.required_components:
		if component in target.node_types:
			score *= 1.0
		else:
			score *= 0.5
	
	return score

## Analyze Physics Architecture Compatibility
func _analyze_physics_architecture(source: SourceProfile, target: ProjectProfile) -> float:
	if not target.has_physics:
		return 0.0
	
	# Most physics implementations are compatible
	return 0.9

## Analyze Input Architecture Compatibility
func _analyze_input_architecture(source: SourceProfile, target: ProjectProfile) -> float:
	# Input system is generally compatible
	return 0.9

## Analyze License Compatibility
func _analyze_license(source: SourceProfile, target: ProjectProfile) -> float:
	var license_compatibility = {
		"MIT": {"MIT": 1.0, "GPL": 1.0, "Apache": 1.0, "BSD": 1.0},
		"GPL": {"MIT": 0.0, "GPL": 1.0, "Apache": 0.8, "BSD": 0.8},
		"Apache": {"MIT": 1.0, "GPL": 1.0, "Apache": 1.0, "BSD": 1.0},
		"BSD": {"MIT": 1.0, "GPL": 1.0, "Apache": 1.0, "BSD": 1.0}
	}
	
	var source_license = source.license.get_slice(" ", 0)  # Get first word
	var target_license = target.license.get_slice(" ", 0)
	
	if source_license in license_compatibility and target_license in license_compatibility[source_license]:
		return license_compatibility[source_license][target_license]
	
	return 0.5

## Analyze Dependencies
func _analyze_dependencies(source: SourceProfile, target: ProjectProfile) -> float:
	if source.dependencies.is_empty():
		return 1.0
	
	# Each dependency reduces score
	return max(0.3, 1.0 - (source.dependencies.size() * 0.2))

## Calculate Overall Score
func _calculate_overall_score(factor_scores: Dictionary) -> float:
	if factor_scores.is_empty():
		return 0.0
	
	var total = 0.0
	for score in factor_scores.values():
		total += score
	
	return total / factor_scores.size()

## Determine Integration Difficulty
func _determine_difficulty(score: float) -> String:
	if score >= 0.9:
		return "easy"
	elif score >= 0.7:
		return "moderate"
	elif score >= 0.5:
		return "difficult"
	else:
		return "very_difficult"

## Generate Recommendations
func _generate_recommendations(source: SourceProfile, target: ProjectProfile, result: CompatibilityResult) -> Array:
	var recommendations = []
	
	if result.factor_scores.get(CompatibilityFactor.LANGUAGE, 1.0) < 0.8:
		recommendations.append("Consider rewriting in %s for better compatibility" % target.language)
	
	if result.factor_scores.get(CompatibilityFactor.LICENSE, 1.0) < 0.8:
		recommendations.append("Review license compatibility before integration")
	
	if source.dependencies.size() > 0:
		recommendations.append("Verify all dependencies are available in target project")
	
	if result.integration_difficulty == "difficult" or result.integration_difficulty == "very_difficult":
		recommendations.append("Consider using this as reference only, not direct integration")
	
	if result.overall_score >= 0.9:
		recommendations.append("High compatibility - safe for direct integration")
	
	return recommendations

## Generate Warnings
func _generate_warnings(source: SourceProfile, target: ProjectProfile, result: CompatibilityResult) -> Array:
	var warnings = []
	
	if result.factor_scores.get(CompatibilityFactor.GODOT_VERSION, 1.0) < 0.7:
		warnings.append("Godot version mismatch may cause issues")
	
	if result.factor_scores.get(CompatibilityFactor.LICENSE, 1.0) < 0.5:
		warnings.append("License incompatibility detected")
	
	if source.dependencies.size() > 3:
		warnings.append("High dependency count may cause integration issues")
	
	return warnings

## Generate Compatibility Report
func generate_report(source: SourceProfile, target: ProjectProfile) -> String:
	var result = analyze_compatibility(source, target)
	
	var report = """
=== Capability Compatibility Report ===

Source: %s
Target: %s

Overall Score: %.2f / 1.00
Compatible: %s
Integration Difficulty: %s

Factor Scores:
""" % [source.source_id, target.godot_version, result.overall_score, result.is_compatible, result.integration_difficulty]
	
	for factor in result.factor_scores:
		report += "  - %s: %.2f\n" % [CompatibilityFactor.keys()[factor], result.factor_scores[factor]]
	
	if result.warnings.size() > 0:
		report += "\nWarnings:\n"
		for warning in result.warnings:
			report += "  - %s\n" % warning
	
	if result.recommendations.size() > 0:
		report += "\nRecommendations:\n"
		for rec in result.recommendations:
			report += "  - %s\n" % rec
	
	return report
