## Inventory System Test
## Tests the inventory system
##
## Run with: godot --headless -s inventory_test.gd

extends SceneTree

var tests_passed: int = 0
var tests_failed: int = 0
var tests_total: int = 0

func _init() -> void:
	print("=== Inventory System Tests ===\n")
	
	test_inventory_initialization()
	test_add_item()
	test_remove_item()
	test_stacking()
	
	print("\n=== Results ===")
	print("Total: %d | Passed: %d | Failed: %d" % [tests_total, tests_passed, tests_failed])
	
	if tests_failed == 0:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed!")
	
	quit()

func test_inventory_initialization() -> void:
	print("Testing initialization...")
	
	var inventory = InventorySystem.new()
	assert_test(inventory.max_slots == 20, "Default max slots should be 20")
	assert_test(inventory.slots.size() == 20, "Should have 20 slots")
	assert_test(inventory.get_used_slots() == 0, "Used slots should be 0")
	assert_test(inventory.get_free_slots() == 20, "Free slots should be 20")
	
	print("  ✓ Initialization tests passed\n")

func test_add_item() -> void:
	print("Testing add item...")
	
	var inventory = InventorySystem.new()
	var item = InventorySystem.Item.new("sword", "Sword", "A sharp sword")
	item.max_stack = 1
	
	var result = inventory.add_item(item)
	assert_test(result == true, "Should add item successfully")
	assert_test(inventory.get_used_slots() == 1, "Used slots should be 1")
	assert_test(inventory.has_item("sword"), "Should have sword")
	assert_test(inventory.get_item_count("sword") == 1, "Should have 1 sword")
	
	print("  ✓ Add item tests passed\n")

func test_remove_item() -> void:
	print("Testing remove item...")
	
	var inventory = InventorySystem.new()
	var item = InventorySystem.Item.new("potion", "Potion", "Health potion")
	item.max_stack = 10
	
	inventory.add_item(item, 5)
	assert_test(inventory.get_item_count("potion") == 5, "Should have 5 potions")
	
	inventory.remove_item("potion", 3)
	assert_test(inventory.get_item_count("potion") == 2, "Should have 2 potions")
	
	inventory.remove_item("potion", 2)
	assert_test(inventory.get_item_count("potion") == 0, "Should have 0 potions")
	assert_test(not inventory.has_item("potion"), "Should not have potions")
	
	print("  ✓ Remove item tests passed\n")

func test_stacking() -> void:
	print("Testing stacking...")
	
	var inventory = InventorySystem.new()
	inventory.allow_stack = true
	inventory.max_slots = 5
	
	var item = InventorySystem.Item.new("arrow", "Arrow", "Ammo")
	item.max_stack = 99
	
	# Add multiple stacks
	inventory.add_item(item, 50)
	inventory.add_item(item, 50)
	
	assert_test(inventory.get_item_count("arrow") == 100, "Should have 100 arrows")
	assert_test(inventory.get_used_slots() == 2, "Should use 2 slots")
	
	print("  ✓ Stacking tests passed\n")

func assert_test(condition: bool, message: String) -> void:
	tests_total += 1
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)
