# res://Singletons/GameManager.gd
extends Node

signal resources_updated
signal checkpoint_set

# --- Resource-based State Management ---
var session_state: MissionSaveState
var checkpoint_state: MissionSaveState

# --- Player Resources ---
var gold: int = 0
var villagers: int = 0
var archers: int = 0
var is_gameplay_active: bool = true
var mission_objective_complete: bool = false
var wall_kick_unlocked: bool = true ## NEW: Set to true to enable the ability for testing.

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

# --- Persistence API ---
func get_persistent_state(object_id: String) -> Dictionary:
	if session_state and session_state.collected_objects.has(object_id):
		return session_state.collected_objects[object_id]
	# FIX: Return an empty dictionary instead of null to match the function's return type.
	return {}

func set_persistent_state(object_id: String, state: Dictionary) -> void:
	if session_state:
		session_state.collected_objects[object_id] = state

func save_checkpoint_data() -> void:
	if session_state:
		checkpoint_state = session_state.duplicate(true)
		DebugManager.log(DebugManager.Category.CHECKPOINT, "Checkpoint data saved.")

# --- Event Handlers ---
func _on_mission_started() -> void:
	mission_objective_complete = false
	session_state = MissionSaveState.new()
	checkpoint_state = null

func _on_player_died() -> void:
	if checkpoint_state:
		session_state = checkpoint_state.duplicate(true)
		DebugManager.log(DebugManager.Category.GAME_STATE, "Session state restored from checkpoint.")
	else:
		# No checkpoint was hit, so start with a fresh state
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
	print("Player received " + str(amount) + " gold. Total gold: " + str(gold))
	save_game()

func _on_villager_rescued() -> void:
	villagers += 1
	mission_objective_complete = true
	print("Villager rescued! Total villagers: " + str(villagers))
	save_game()

func _on_train_archer_requested() -> void:
	if gold >= 10 and villagers > 0:
		gold -= 10
		villagers -= 1
		archers += 1
		save_game()
		print("Archer trained!")
	else:
		print("Cannot train archer. Not enough resources.")

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
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
	resources_updated.emit()

func save_game():
	var save_data = {"gold": gold, "villagers": villagers, "archers": archers}
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
		resources_updated.emit()
