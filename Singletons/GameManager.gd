# res://Singletons/GameManager.gd
extends Node

signal resources_updated
<<<<<<< Updated upstream
=======

>>>>>>> Stashed changes
var gold: int = 0
var villagers: int = 0
var archers: int = 0
var is_gameplay_active: bool = true

var mission_objective_complete: bool = false

# --- Persistence State ---
var _persistent_objects_session: Dictionary = {}
var _persistent_objects_checkpoint: Dictionary = {}

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

# --- Public Persistence API ---
func get_persistent_state(id: String):
	return _persistent_objects_session.get(id, null)

func set_persistent_state(id: String, state: Dictionary) -> void:
	_persistent_objects_session[id] = state
	DebugManager.log(DebugManager.Category.PERSISTENCE, "State saved for object_id '" + id + "': " + str(state))

# --- Checkpoint & Respawn Logic ---
func save_checkpoint_data() -> void:
	_persistent_objects_checkpoint = _persistent_objects_session.duplicate(true)
	DebugManager.log(DebugManager.Category.CHECKPOINT, "Checkpoint data saved. " + str(_persistent_objects_checkpoint.size()) + " objects tracked.")

func _on_player_died() -> void:
	_persistent_objects_session = _persistent_objects_checkpoint.duplicate(true)
	DebugManager.log(DebugManager.Category.GAME_STATE, "Player died. Restoring checkpoint data.")
	
	if not SceneManager.current_scene_key.is_empty():
		SceneManager.change_scene(SceneManager.current_scene_key)

func _on_mission_started() -> void:
	_persistent_objects_session.clear()
	_persistent_objects_checkpoint.clear()
	mission_objective_complete = false
	DebugManager.log(DebugManager.Category.GAME_STATE, "New mission started. All persistence data cleared.")

# --- Event Handlers & Save/Load (mostly unchanged) ---
func _on_gold_collected(amount: int) -> void:
	gold += amount
	DebugManager.log(DebugManager.Category.GAME_STATE, "Player received " + str(amount) + " gold. Total gold: " + str(gold))
	save_game()

func _on_villager_rescued() -> void:
	villagers += 1
	mission_objective_complete = true
	DebugManager.log(DebugManager.Category.GAME_STATE, "Villager rescued! Total villagers: " + str(villagers))
	save_game()

func _on_train_archer_requested() -> void:
	if gold >= 10 and villagers > 0:
		gold -= 10
		villagers -= 1
		archers += 1
		save_game()
		DebugManager.log(DebugManager.Category.GAME_STATE, "Archer trained!")
	else:
		DebugManager.log(DebugManager.Category.GAME_STATE, "Cannot train archer. Not enough resources.")

func _on_mission_objective_completed() -> void:
	EventBus.mission_succeeded.emit()

func _on_player_detected() -> void:
	EventBus.mission_failed.emit()

func _on_pause_toggled(is_paused: bool) -> void:
	get_tree().paused = is_paused
	is_gameplay_active = not is_paused
	DebugManager.log(DebugManager.Category.GAME_STATE, "Game Paused: " + str(is_paused))

func reset_game_data() -> void:
	gold = 0
	villagers = 0
	archers = 0
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
	resources_updated.emit()

func save_game():
	var save_data = {
		"gold": gold,
		"villagers": villagers,
		"archers": archers
	}
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	DebugManager.log(DebugManager.Category.GAME_STATE, "Game saved!")

func load_game():
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		DebugManager.log(DebugManager.Category.GAME_STATE, "No save file found.")
		return
		
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	var data = JSON.parse_string(content)
	
	if data:
		gold = data.get("gold", 0)
		villagers = data.get("villagers", 0)
		archers = data.get("archers", 0)
		DebugManager.log(DebugManager.Category.GAME_STATE, "load_game() called. Villagers loaded as " + str(villagers))
		resources_updated.emit()
	else:
<<<<<<< Updated upstream
		print("DEBUG: GameManager - Error loading save file.") #<-- ADD THIS
func _on_player_died() -> void:
	
	if not SceneManager.current_scene_key.is_empty():
		SceneManager.change_scene(SceneManager.current_scene_key)
=======
		DebugManager.log(DebugManager.Category.GAME_STATE, "Error loading save file.")

func set_checkpoint(pos: Vector2) -> void:
	current_checkpoint = pos
	EventBus.checkpoint_set.emit(pos)
>>>>>>> Stashed changes
