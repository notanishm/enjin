## Equipment System Test
## Tests the equipment system
##
## Run with: godot --headless -s equipment_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Equipment System Tests ===\n")
	
	test_equipment_initialization()
	test_equip_item()
	test_unequip_item()
	test_stat_calculation()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_equipment_initialization() -> void:
	print("Testing initialization...")
	
	var equipment = EquipmentSystem.new()
	assert_test(equipment.slots.size() == 6, "Should have 6 equipment slots")
	assert_test(equipment.equipment_slots.has("head"), "Should have head slot")
	assert_test(equipment.equipment_slots.has("weapon"), "Should have weapon slot")
	
	print("  ✓ Initialization tests passed\n")

func test_equip_item() -> void:
	print("Testing equip item...")
	
	var equipment = EquipmentSystem.new()
	var sword = EquipmentSystem.Item.new("sword", "Iron Sword", "weapon")
	sword.stats = {"attack": 10}
	
	var equipped = false
	equipment.item_equipped.connect(func(item, slot): equipped = true)
	
	equipment.equip(sword)
	
	assert_test(equipped == true, "Should emit equipped signal")
	assert_test(equipment.get_item("weapon") == sword, "Should have sword in weapon slot")
	assert_test(equipment.get_stat("attack") == 10.0, "Attack stat should be 10")
	
	print("  ✓ Equip item tests passed\n")

func test_unequip_item() -> void:
	print("Testing unequip item...")
	
	var equipment = EquipmentSystem.new()
	var shield = EquipmentSystem.Item.new("shield", "Wooden Shield", "shield")
	shield.stats = {"defense": 5}
	
	equipment.equip(shield)
	assert_test(equipment.get_item("shield") == shield, "Should have shield")
	
	var unequipped = false
	equipment.item_unequipped.connect(func(item, slot): unequipped = true)
	
	equipment.unequip("shield")
	
	assert_test(unequipped == true, "Should emit unequipped signal")
	assert_test(equipment.get_item("shield") == null, "Should not have shield")
	assert_test(equipment.get_stat("defense") == 0.0, "Defense stat should be 0")
	
	print("  ✓ Unequip item tests passed\n")

func test_stat_calculation() -> void:
	print("Testing stat calculation...")
	
	var equipment = EquipmentSystem.new()
	
	# Equip multiple items
	var helmet = EquipmentSystem.Item.new("helmet", "Iron Helmet", "helmet")
	helmet.stats = {"defense": 5, "health": 10}
	
	var armor = EquipmentSystem.Item.new("armor", "Iron Armor", "chest")
	armor.stats = {"defense": 10, "health": 20}
	
	equipment.equip(helmet)
	equipment.equip(armor)
	
	assert_test(equipment.get_stat("defense") == 15.0, "Total defense should be 15")
	assert_test(equipment.get_stat("health") == 30.0, "Total health should be 30")
	
	print("  ✓ Stat calculation tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
