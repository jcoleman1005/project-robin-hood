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
			printerr("SceneManager: Invalid entry in scene_entries array.")

	EventBus.new_game_requested.connect(func(): change_scene("hideout"))
	EventBus.continue_game_requested.connect(func(): change_scene("hideout"))
	EventBus.return_to_hideout_requested.connect(func(): change_scene("hideout"))
	EventBus.start_mission_requested.connect(func(mission_key): change_scene(mission_key))


func change_scene(scene_key: String) -> void:
	# THE FIX IS HERE: Remember which scene we are loading.
	current_scene_key = scene_key
	
	DebugManager.log(DebugManager.Category.GAME_STATE, "Changing scene to: '%s'" % scene_key)
	
	var ui_to_close = UIManager.close_current_ui()
	if is_instance_valid(ui_to_close):
		await ui_to_close.tree_exited
		
	animation_player.play("fade_to_black")
	await animation_player.animation_finished

	var scene_to_load: PackedScene = _scene_map[scene_key]
	get_tree().change_scene_to_packed(scene_to_load)

	await get_tree().process_frame

	_spawn_player()

	animation_player.play("fade_from_black")


func _spawn_player() -> void:
	if not player_scene:
		printerr("SceneManager Error: player_scene not set in Inspector!")
		return

	var current_scene = get_tree().current_scene
	var spawn_point = current_scene.find_child("PlayerSpawnPoint", true, false)

	if is_instance_valid(spawn_point):
		var player_instance = player_scene.instantiate()
		player_instance.global_position = spawn_point.global_position
		current_scene.add_child(player_instance)
		await get_tree().process_frame
