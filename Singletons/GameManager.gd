# res://Singletons/GameManager.gd
extends Node

signal resources_updated
signal checkpoint_set
signal hideout_upgraded ## NEW: To announce a successful upgrade.

@export var hideout_progression_data: HideoutProgressionData ## NEW: Link to our upgrade costs.

# --- Resource-based State Management ---
var session_state: MissionSaveState
var checkpoint_state: MissionSaveState

# --- Player Resources & Progress ---
var gold: int = 0
var villagers: int = 0
var archers: int = 0
var hideout_level: int = 1
var wall_kick_unlocked: bool = false

# --- Gameplay State ---
var is_gameplay_active: bool = true
var mission_objective_complete: bool = false

const SAVE_FILE_PATH = "user://savegame.json"

func _ready() -> void:
	load_game()
	EventBus.gold_collected.connect(_on_gold_collected)
	EventBus.villager_rescued.connect(_on_villager_rescued)
	EventBus.train_archer_requested.connect(_on_train_archer_requested)
	EventBus.mission_started.connect(_on_mission_started)
	EventBus.mission_objective_completed.connect(_on_mission_objective_completed)
	EventBus.player_detected.connect(_on_player_detected)
	EventBus.pause_toggled.connect(_on_pause_toggled)
	EventBus.player_died.connect(_on_player_died)

# NEW: The core logic for handling an upgrade attempt.
func try_upgrade_hideout():
	assert(is_instance_valid(hideout_progression_data), "HideoutProgressionData resource must be assigned to GameManager!")

	if hideout_level >= hideout_progression_data.max_level:
		print("DEBUG: Hideout is already at max level.")
		return

	# Array index is level - 1 (e.g., cost for level 2 is at index 0)
	var cost = hideout_progression_data.upgrade_costs[hideout_level - 1]

	if gold >= cost:
		gold -= cost
		hideout_level += 1
		print("SUCCESS: Hideout upgraded to level ", hideout_level)
		hideout_upgraded.emit()
		save_game()
	else:
		print("FAILED: Not enough gold. Need %d, have %d" % [cost, gold])


# ... (rest of the script is the same) ...
func get_persistent_state(object_id: String) -> Dictionary:
	if session_state and session_state.collected_objects.has(object_id):
		return session_state.collected_objects[object_id]
	return {}
func set_persistent_state(object_id: String, state: Dictionary) -> void:
	if session_state:
		session_state.collected_objects[object_id] = state
func save_checkpoint_data() -> void:
	if session_state:
		checkpoint_state = session_state.duplicate(true)
		DebugManager.log(DebugManager.Category.CHECKPOINT, "Checkpoint data saved.")
func _on_mission_started() -> void:
	mission_objective_complete = false
	session_state = MissionSaveState.new()
	checkpoint_state = null
func _on_player_died() -> void:
	if checkpoint_state:
		session_state = checkpoint_state.duplicate(true)
		DebugManager.log(DebugManager.Category.GAME_STATE, "Session state restored from checkpoint.")
	else:
		session_state = MissionSaveState.new()
		DebugManager.log(DebugManager.Category.GAME_STATE, "No checkpoint found. Starting with fresh session state.")
	if not SceneManager.current_scene_key.is_empty():
		SceneManager.change_scene(SceneManager.current_scene_key)
func set_checkpoint(pos: Vector2) -> void:
	if session_state:
		session_state.checkpoint_position = pos
	EventBus.checkpoint_set.emit(pos)
func _on_gold_collected(amount: int) -> void:
	gold += amount
	save_game()
func _on_villager_rescued() -> void:
	villagers += 1
	mission_objective_complete = true
	save_game()
func _on_train_archer_requested() -> void:
	if gold >= 10 and villagers > 0:
		gold -= 10
		villagers -= 1
		archers += 1
		save_game()
func _on_mission_objective_completed() -> void:
	EventBus.mission_succeeded.emit()
func _on_player_detected() -> void:
	EventBus.mission_failed.emit()
func _on_pause_toggled(is_paused: bool) -> void:
	get_tree().paused = is_paused
	is_gameplay_active = not is_paused
func reset_game_data() -> void:
	gold = 0
	villagers = 0
	archers = 0
	hideout_level = 1
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
	resources_updated.emit()
func save_game():
	var save_data = { "gold": gold, "villagers": villagers, "archers": archers, "hideout_level": hideout_level }
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
func load_game():
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	var data = JSON.parse_string(content)
	if data:
		gold = data.get("gold", 0)
		villagers = data.get("villagers", 0)
		archers = data.get("archers", 0)
		hideout_level = data.get("hideout_level", 1)
		resources_updated.emit()
