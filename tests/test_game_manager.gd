# res://Debugging/TestScripts/test_game_manager.gd
extends GutTest

var game_manager

func before_each():
	game_manager = GameManager
	game_manager.gold = 0
	game_manager.villagers = 0
	game_manager.archers = 0


func test_gold_collected_updates_correctly():
	game_manager._on_gold_collected(15)
	assert_eq(game_manager.gold, 15, "Gold should be 15 after collecting 15.")

func test_train_archer_succeeds_with_resources():
	game_manager.gold = 20
	game_manager.villagers = 5
	game_manager._on_train_archer_requested()
	assert_eq(game_manager.gold, 10, "Gold should be reduced by 10.")
	assert_eq(game_manager.villagers, 4, "Villagers should be reduced by 1.")
	assert_eq(game_manager.archers, 1, "Archers should increase to 1.")

func test_train_archer_fails_without_enough_gold():
	game_manager.gold = 5
	game_manager.villagers = 5
	game_manager._on_train_archer_requested()
	assert_eq(game_manager.gold, 5, "Gold should not change on failure.")
	assert_eq(game_manager.villagers, 5, "Villagers should not change on failure.")
	assert_eq(game_manager.archers, 0, "Archers should not increase on failure.")

func test_train_archer_fails_without_enough_villagers():
	game_manager.gold = 20
	game_manager.villagers = 0
	game_manager._on_train_archer_requested()
	assert_eq(game_manager.gold, 20, "Gold should not change on failure.")
	assert_eq(game_manager.villagers, 0, "Villagers should not change on failure.")
	assert_eq(game_manager.archers, 0, "Archers should not increase on failure.")
