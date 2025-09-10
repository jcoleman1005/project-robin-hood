# res://Singletons/DebugManager.gd
extends Node

@export_group("Log Categories")
@export var show_interaction_logs: bool = false
@export var show_player_state_logs: bool = false
@export var show_game_state_logs: bool = false # NEW CATEGORY

enum Category {
	INTERACTION,
	PLAYER_STATE,
	GAME_STATE # NEW CATEGORY
}

static func log(category: Category, message: String) -> void:
	if not Engine.has_singleton("DebugManager"):
		return

	var instance = Engine.get_singleton("DebugManager")
	if not is_instance_valid(instance): return

	var should_log: bool = false
	match category:
		Category.INTERACTION:
			should_log = instance.show_interaction_logs
		Category.PLAYER_STATE:
			should_log = instance.show_player_state_logs
		Category.GAME_STATE: # NEW CATEGORY
			should_log = instance.show_game_state_logs

	if should_log:
		print("[QA LOG]: ", message)
