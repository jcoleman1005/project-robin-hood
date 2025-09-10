# res://UserInterface/UIManager.gd
extends CanvasLayer

var _ui_scenes: Dictionary = {
	"PauseMenu": "res://UserInterface/PauseMenu.tscn",
	"MissionSuccessScreen": "res://UserInterface/MissionSuccessScreen.tscn",
	"MissionFailedScreen": "res://UserInterface/MissionFailedScreen.tscn"
}
var _dialogue_box_path: String = "res://UserInterface/DialogueBox.tscn"
# We still need the path to create the instance.
var _interaction_ui_path: String = "res://UserInterface/InteractionUI.tscn"

var _current_ui: CanvasLayer = null
# We no longer need to hold a reference to the instance here,
# as it will manage itself after being added to the scene.

func _ready() -> void:
	EventBus.mission_succeeded.connect(_on_mission_succeeded)
	EventBus.mission_failed.connect(_on_mission_failed)
	EventBus.pause_toggled.connect(_on_pause_toggled)
	EventBus.show_dialogue.connect(_on_show_dialogue)
	EventBus.pause_menu_requested.connect(_on_pause_menu_requested)

	# --- THE FIX IS HERE ---
	# The UIManager's job is to create the UI, but that's it.
	# We no longer connect to the InteractionManager's signals here.
	var interaction_scene: PackedScene = load(_interaction_ui_path)
	if interaction_scene:
		var interaction_ui_instance = interaction_scene.instantiate()
		add_child(interaction_ui_instance)
	# The InteractionUI.gd script will handle its own signal connections in its own _ready() function.

# --- ALL OF THE FOLLOWING FUNCTIONS HAVE BEEN REMOVED ---
# func _on_show_prompt(...)
# func _on_hide_prompt(...)

func _on_pause_menu_requested():
	if not _current_ui:
		_show_ui("PauseMenu")

func _on_pause_toggled(is_pausing: bool) -> void:
	if not is_pausing:
		if _current_ui and _current_ui.get_script().get_path().contains("PauseMenu.gd"):
			_close_ui()

func _on_show_dialogue(message: String) -> void:
	if _current_ui: return
	var dialogue_scene: PackedScene = load(_dialogue_box_path)
	if dialogue_scene:
		var dialogue_instance = dialogue_scene.instantiate()
		_current_ui = dialogue_instance
		_current_ui.closed.connect(_on_dialogue_closed)
		add_child(dialogue_instance)
		dialogue_instance.display_message(message)
		EventBus.pause_toggled.emit(true)

func _on_dialogue_closed() -> void:
	_current_ui = null
	EventBus.pause_toggled.emit(false)

func _show_ui(ui_name: String) -> void:
	if _current_ui: return
	var scene_path = _ui_scenes.get(ui_name)
	if not scene_path:
		printerr("UIManager Error: UI scene '", ui_name, "' not found.")
		return
	var loaded_scene: PackedScene = load(scene_path)
	if loaded_scene:
		_current_ui = loaded_scene.instantiate()
		add_child(_current_ui)
		EventBus.pause_toggled.emit(true)

func _close_ui() -> void:
	if is_instance_valid(_current_ui):
		_current_ui.queue_free()
		_current_ui = null
		EventBus.pause_toggled.emit(false)

func _on_mission_succeeded() -> void:
	_show_ui("MissionSuccessScreen")

func _on_mission_failed() -> void:
	_show_ui("MissionFailedScreen")

func close_current_ui() -> Node:
	if is_instance_valid(_current_ui):
		var ui_node_to_close = _current_ui
		_close_ui()
		return ui_node_to_close
	return null
