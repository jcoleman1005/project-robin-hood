# res://UserInterface/UIManager.gd
# This manager is responsible for instantiating, showing, and hiding
# all modal UI scenes like the pause menu or mission end screens.
# It listens for global game state events from the EventBus and reacts
# by presenting the appropriate UI to the player.
extends CanvasLayer

# --- Scene References ---
# A dictionary mapping UI keys to their scene paths for easy management.
var _ui_scenes: Dictionary = {
	"PauseMenu": "res://UserInterface/PauseMenu.tscn",
	"MissionSuccessScreen": "res://UserInterface/MissionSuccessScreen.tscn",
	"MissionFailedScreen": "res://UserInterface/MissionFailedScreen.tscn"
}
var _dialogue_box_path: String = "res://UserInterface/DialogueBox.tscn"
var _interaction_ui_path: String = "res://UserInterface/InteractionUI.tscn"

# --- State Variables ---
var _current_ui: CanvasLayer = null
var _interaction_ui_instance: CanvasLayer = null


func _ready() -> void:
	# Connect to global events that trigger UI changes.
	EventBus.mission_succeeded.connect(_on_mission_succeeded)
	EventBus.mission_failed.connect(_on_mission_failed)
	EventBus.pause_toggled.connect(_on_pause_toggled)
	EventBus.show_dialogue.connect(_on_show_dialogue)

	# Instantiate the persistent interaction prompt UI.
	var interaction_scene: PackedScene = load(_interaction_ui_path)
	if interaction_scene:
		_interaction_ui_instance = interaction_scene.instantiate()
		add_child(_interaction_ui_instance)

	# Connect to the InteractionManager to show/hide prompts.
	InteractionManager.show_prompt.connect(_on_show_prompt)
	InteractionManager.hide_prompt.connect(_on_hide_prompt)


func _on_pause_toggled(is_pausing: bool) -> void:
	if is_pausing:
		# If the game is pausing and no other UI is open, show the pause menu.
		if not _current_ui:
			_show_ui("PauseMenu")
	else:
		# If the game is unpausing, close the pause menu if it's the active UI.
		if _current_ui and _current_ui.get_script().get_path().contains("PauseMenu.gd"):
			_close_ui()


func _on_show_dialogue(message: String) -> void:
	if _current_ui:
		return

	var dialogue_scene: PackedScene = load(_dialogue_box_path)
	if dialogue_scene:
		var dialogue_instance = dialogue_scene.instantiate()
		_current_ui = dialogue_instance
		_current_ui.closed.connect(_on_dialogue_closed)
		add_child(_current_ui)
		_current_ui.display_message(message)
		
		print("DEBUG: UIManager - Dialogue opened. Emitting pause_toggled(true).") #<-- ADD THIS
		EventBus.pause_toggled.emit(true)


func _on_dialogue_closed() -> void:
	_current_ui = null
	
	print("DEBUG: UIManager - Dialogue closed. Emitting pause_toggled(false).") #<-- ADD THIS
	EventBus.pause_toggled.emit(false)


func _on_show_prompt(interactable: Interactable) -> void:
	if is_instance_valid(_interaction_ui_instance):
		_interaction_ui_instance.show_prompt(interactable)


func _on_hide_prompt() -> void:
	if is_instance_valid(_interaction_ui_instance):
		_interaction_ui_instance.hide_prompt()


func _show_ui(ui_name: String) -> void:
	if _current_ui:
		return

	var scene_path = _ui_scenes.get(ui_name)
	if not scene_path:
		printerr("UIManager Error: UI scene '", ui_name, "' not found in dictionary.")
		return

	var loaded_scene: PackedScene = load(scene_path)
	if loaded_scene:
		_current_ui = loaded_scene.instantiate()
		add_child(_current_ui)
		# Showing a modal UI should always pause the game.
		EventBus.pause_toggled.emit(true)
	else:
		printerr("UIManager Error: Failed to load scene at path: ", scene_path)


func _close_ui() -> void:
	if is_instance_valid(_current_ui):
		_current_ui.queue_free()
		_current_ui = null
		# Closing the modal UI should always unpause the game.
		EventBus.pause_toggled.emit(false)


func _on_mission_succeeded() -> void:
	_show_ui("MissionSuccessScreen")


func _on_mission_failed() -> void:
	_show_ui("MissionFailedScreen")
	
## Closes the current UI and returns the node that is being queued for deletion.
## This allows other systems to await its removal.
func close_current_ui() -> Node:
	if is_instance_valid(_current_ui):
		var ui_node_to_close = _current_ui
		# _close_ui() already handles unpausing and calling queue_free().
		_close_ui()
		return ui_node_to_close
	return null
