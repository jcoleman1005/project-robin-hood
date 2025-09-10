# res://UserInterface/InteractionUI.gd
extends Control

# --- Configuration ---
@export_group("Interaction Fill")
@export var default_panel_color: Color = Color("2d2d2d") # A dark grey
@export var fill_panel_color: Color = Color("ffffff")    # White
# The global vertical_offset has been removed from this script.

# --- Node References ---
@onready var _label: Label = $Panel/Label
@onready var _panel: PanelContainer = $Panel
@onready var _hold_progress_bar: ProgressBar = $Panel/HoldProgressBar

# --- Internal State ---
# We now type-hint this as an Interactable to make the code clearer.
var _target_object: Interactable = null
var _panel_stylebox: StyleBoxFlat

func _ready() -> void:
	hide()
	_hold_progress_bar.visible = false
	
	var base_stylebox = _panel.get_theme_stylebox("panel")
	if base_stylebox is StyleBoxFlat:
		_panel_stylebox = base_stylebox.duplicate(true)
		_panel.add_theme_stylebox_override("panel", _panel_stylebox)
	else:
		printerr("InteractionUI Error: Panel's theme style is not a StyleBoxFlat. Cannot change color.")

	EventBus.interaction_progress_updated.connect(_on_interaction_progress_updated)
	InteractionManager.show_prompt.connect(_on_show_prompt)
	InteractionManager.hide_prompt.connect(hide_prompt)

func _on_show_prompt(interactable: Interactable) -> void:
	_target_object = interactable
	_label.text = interactable.prompt_message
	
	if is_instance_valid(_panel_stylebox):
		_panel_stylebox.bg_color = default_panel_color
		
	show()

func hide_prompt() -> void:
	_target_object = null
	hide()

func _process(_delta: float) -> void:
	if is_instance_valid(_target_object) and visible:
		var screen_pos := get_viewport().get_canvas_transform() * _target_object.global_position
		
		# THE KEY CHANGE: We now read the offset from the target object itself.
		var offset_vector = Vector2(0, _target_object.prompt_vertical_offset)
		_panel.global_position = (screen_pos - (_panel.size / 2.0)) + offset_vector
	else:
		hide()

func _on_interaction_progress_updated(progress: float) -> void:
	if is_instance_valid(_panel_stylebox):
		_panel_stylebox.bg_color = default_panel_color.lerp(fill_panel_color, progress)
