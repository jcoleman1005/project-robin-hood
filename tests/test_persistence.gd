# res://tests/test_persistence.gd
extends GutTest

# Test-double for our persistence component to isolate GameManager logic.
class MockPersistenceComponent extends Node:
	var object_id: String
	var applied_state: Dictionary = {}
	func apply_state(state: Dictionary):
		applied_state = state

# We need a direct reference to the singleton for testing.
var game_manager

func before_each():
	game_manager = GameManager
	# Clear out any state from previous tests.
	game_manager._persistent_objects_session.clear()
	game_manager._persistent_objects_checkpoint.clear()

func test_set_and_get_persistent_state():
	var state = {"is_collected": true}
	game_manager.set_persistent_state("test_id_01", state)
	assert_eq(game_manager.get_persistent_state("test_id_01"), state, "Should retrieve the exact state that was set.")
	assert_null(game_manager.get_persistent_state("non_existent_id"), "Should return null for an unknown ID.")

func test_checkpoint_saves_session_data():
	game_manager.set_persistent_state("chest_01", {"is_collected": true})
	game_manager.save_checkpoint_data()
	assert_eq(game_manager._persistent_objects_checkpoint.size(), 1, "Checkpoint data should have one entry.")
	assert_true(game_manager._persistent_objects_checkpoint.has("chest_01"), "Checkpoint data should contain the collected chest's ID.")

func test_player_death_restores_checkpoint_data():
	# 1. Collect an object and save at a checkpoint.
	game_manager.set_persistent_state("chest_01", {"is_collected": true})
	game_manager.save_checkpoint_data()
	
	# 2. Collect another object but DON'T save at a checkpoint.
	game_manager.set_persistent_state("prisoner_01", {"is_rescued": true})
	assert_eq(game_manager._persistent_objects_session.size(), 2, "Session should have two objects before death.")
	
	# 3. Simulate player death (scene change is mocked).
	game_manager._on_player_died() # This should restore the checkpoint data.
	
	# 4. Assert the state is correct after respawn.
	assert_eq(game_manager._persistent_objects_session.size(), 1, "Session should revert to one object after death.")
	assert_true(game_manager._persistent_objects_session.has("chest_01"), "The checkpointed chest should still be in the session.")
	assert_false(game_manager._persistent_objects_session.has("prisoner_01"), "The non-checkpointed prisoner should be gone.")

func test_new_mission_clears_all_persistence_data():
	game_manager.set_persistent_state("chest_01", {"is_collected": true})
	game_manager.save_checkpoint_data()
	game_manager.set_persistent_state("prisoner_01", {"is_rescued": true})
	
	# Act: Start a new mission
	game_manager._on_mission_started()
	
	# Assert: Both dictionaries should be empty.
	assert_true(game_manager._persistent_objects_session.is_empty(), "Session data should be empty on new mission.")
	assert_true(game_manager._persistent_objects_checkpoint.is_empty(), "Checkpoint data should be empty on new mission.")
