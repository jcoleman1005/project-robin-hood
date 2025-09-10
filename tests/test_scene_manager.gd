# res://tests/test_scene_manager.gd
extends GutTest

# This script will contain all the automated tests for our SceneManager singleton.

var scene_manager

# This special GUT function runs before each test to ensure a clean slate.
func before_each():
	# Get a direct reference to the SceneManager singleton.
	scene_manager = SceneManager
	# Reset its state so one test doesn't interfere with another.
	scene_manager.current_scene_key = ""
	
# --- TEST CASES ---

# This is our "vaccine" for the KillZone bug.
# Its only job is to prove that the change_scene function correctly
# updates the current_scene_key variable.
func test_change_scene_updates_current_scene_key():
	# 1. ARRANGE: We have our fresh scene_manager from before_each().
	
	# 2. ACT: We call the function we want to test with a sample key.
	#    NOTE: We are NOT actually changing scenes here. GUT runs in a
	#    separate environment, so this call only executes the LOGIC
	#    inside the function without the visual parts.
	scene_manager.change_scene("village_outskirts")
	
	# 3. ASSERT: We check if the result is what we expect.
	#    This line says: "Assert that the scene_manager's current_scene_key
	#    is now equal to 'village_outskirts'."
	assert_eq(scene_manager.current_scene_key, "village_outskirts", "current_scene_key should be set after change_scene is called.")
