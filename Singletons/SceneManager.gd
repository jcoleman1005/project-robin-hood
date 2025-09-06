# res://Singletons/SceneManager.gd
# Manages all scene transitions and dynamic player spawning.
extends CanvasLayer

## An array of SceneEntry resources. Configure this in the Godot editor's Inspector.
@export var scene_entries: Array[SceneEntry]

## The PackedScene for the player. Drag PlayerScene.tscn here in the Inspector.
@export var player_scene: PackedScene

# This dictionary is built at runtime from the scene_entries array for fast lookups.
var _scene_map: Dictionary = {}

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Build the scene map from our exported array for fast, safe access later.
	for entry in scene_entries:
		if entry and entry.scene and not entry.key.is_empty():
			_scene_map[entry.key] = entry.scene
		else:
			printerr("SceneManager: Invalid or empty entry found in scene_entries array.")

	# The SceneManager listens for requests from the entire game via the EventBus.
	EventBus.new_game_requested.connect(func(): change_scene("hideout"))
	EventBus.continue_game_requested.connect(func(): change_scene("hideout"))
	EventBus.return_to_hideout_requested.connect(func(): change_scene("hideout"))
	EventBus.start_mission_requested.connect(func(mission_key): change_scene(mission_key))


## The master function for handling all scene transitions.
func change_scene(scene_key: String) -> void:
	# A. Tell the UIManager to close any active UI that might be open.
	var ui_to_close = UIManager.close_current_ui()

	# B. If there was a UI to close, wait for it to be fully removed from the tree.
	if is_instance_valid(ui_to_close):
		await ui_to_close.tree_exited

	# 1. Safety Check: Ensure the requested scene key is valid.
	if not _scene_map.has(scene_key):
		printerr("SceneManager Error: Scene key '", scene_key, "' not found.")
		return

	# 2. Fade Out: Play the fade-out animation and wait for it to finish.
	animation_player.play("fade_to_black")
	await animation_player.animation_finished

	# 3. Change Scene: Load the new scene from our map.
	var scene_to_load: PackedScene = _scene_map[scene_key]
	get_tree().change_scene_to_packed(scene_to_load)

	# 4. Wait a Frame: Allow Godot to fully process the new scene tree.
	await get_tree().process_frame

	# 5. Spawn Player: Call our dedicated player spawning function.
	# <--- THIS IS THE CALL TO THE SPAWN FUNCTION.
	_spawn_player()

	# 6. Fade In: Play the fade-in animation to reveal the new scene.
	animation_player.play("fade_from_black")


# <--- THIS IS THE DEDICATED SPAWN FUNCTION.
## Handles instantiating and placing the player in the new scene.
func _spawn_player() -> void:
	# Safety check: ensure the player scene has been assigned in the editor.
	if not player_scene:
		printerr("SceneManager Error: player_scene has not been set in the Inspector!")
		return

	var current_scene = get_tree().current_scene
	# Find the designated spawn point within the newly loaded level.
	var spawn_point = current_scene.find_child("PlayerSpawnPoint", true, false)

	if is_instance_valid(spawn_point):
		var player_instance = player_scene.instantiate()
		# Position the player exactly where the spawn marker is.
		player_instance.global_position = spawn_point.global_position
		# Add the player as a child of the main level node.
		current_scene.add_child(player_instance)
		
