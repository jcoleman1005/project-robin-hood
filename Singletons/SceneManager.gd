# res://Singletons/SceneManager.gd
extends CanvasLayer

@export var scene_entries: Array[SceneEntry]
@export var player_scene: PackedScene

var _scene_map: Dictionary = {}
var current_scene_key: String = ""
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	for entry in scene_entries:
		if entry and entry.scene and not entry.key.is_empty():
			_scene_map[entry.key] = entry.scene
		else:
			Loggie.error("SceneManager: Invalid entry in scene_entries array.", "setup")

	EventBus.new_game_requested.connect(_load_hideout_scene)
	EventBus.continue_game_requested.connect(_load_hideout_scene)
	EventBus.return_to_hideout_requested.connect(_load_hideout_scene)
	EventBus.start_mission_requested.connect(func(mission_key): change_scene(mission_key))


func _load_hideout_scene() -> void:
	var hideout_key = "hideout_" + str(GameManager.hideout_level)
	change_scene(hideout_key)


func change_scene(scene_key: String) -> void:
	current_scene_key = scene_key
	Loggie.info("Changing scene to: '%s'" % scene_key, "game_state")
	
	var ui_to_close = UIManager.close_current_ui()
	if is_instance_valid(ui_to_close):
		await ui_to_close.tree_exited
		
	animation_player.play("fade_to_black")
	await animation_player.animation_finished

	var scene_to_load: PackedScene = _scene_map[scene_key]
	get_tree().change_scene_to_packed(scene_to_load)
	
	await get_tree().process_frame
	
	var new_scene = get_tree().current_scene
	if new_scene.has_signal("level_generated"):
		new_scene.level_generated.connect(_spawn_player, CONNECT_ONE_SHOT)
	else:
		_spawn_player()
	
	animation_player.play("fade_from_black")


func _spawn_player() -> void:
	if not player_scene:
		Loggie.error("SceneManager Error: player_scene not set in Inspector!", "setup")
		return

	var current_scene = get_tree().current_scene
	
	var spawn_point_node = current_scene.find_child("PlayerSpawnPoint", true, false)
	if not is_instance_valid(spawn_point_node):
		Loggie.error("SceneManager Error: No PlayerSpawnPoint found in scene '%s'" % current_scene.name, "level")
		return
		
	var spawn_position: Vector2
	if GameManager.session_state and GameManager.session_state.checkpoint_position != Vector2.ZERO:
		spawn_position = GameManager.session_state.checkpoint_position
		Loggie.info("Spawning player at checkpoint: " + str(spawn_position), "game_state")
	else:
		spawn_position = spawn_point_node.global_position
		Loggie.info("Spawning player at default spawn point: " + str(spawn_position), "game_state")
		
	var player_instance = player_scene.instantiate()
	player_instance.global_position = spawn_position
	current_scene.add_child(player_instance)
	await get_tree().process_frame
