# res://UserInterface/InteractionUI.gd
extends Control

@onready var _label: Label = $Panel/Label
@onready var _panel: PanelContainer = $Panel

var _target_object: Node2D = null

func _ready() -> void:
	hide()
	print("DEBUG [InteractionUI]: Ready and hidden.")

func show_prompt(target: Node2D, prompt_text: String) -> void:
	print("---")
	print("DEBUG [InteractionUI]: show_prompt called.")
	print("  - Target: ", target.name if is_instance_valid(target) else "INVALID")
	print("  - Text: '", prompt_text, "'")

	_target_object = target
	_label.text = prompt_text
	show()

	print("  - My visibility: ", visible)
	print("  - Panel visibility: ", _panel.visible)
	print("  - Label visibility: ", _label.visible)
	print("  - Label modulate alpha: ", _label.modulate.a)
	print("  - Label text content: '", _label.text, "'")
	print("---")

func hide_prompt() -> void:
	print("DEBUG [InteractionUI]: hide_prompt called.")
	_target_object = null
	hide()

func _process(_delta: float) -> void:
	if is_instance_valid(_target_object) and visible:
		# Correct Godot 4 way to get screen coordinates
		var screen_pos := get_viewport().get_canvas_transform() * _target_object.global_position
		
		# LOGIC IMPROVEMENT: Set the panel's GLOBAL position directly.
		# This is more robust than setting the local position.
		_panel.global_position = screen_pos - (_panel.size / 2.0)
		
		# Request a redraw to show the debug shapes
		queue_redraw()
	else:
		# If not visible, still need to request a redraw to clear old debug shapes
		queue_redraw()

func _draw() -> void:
	# Only draw if the UI is supposed to be visible
	if is_instance_valid(_target_object) and visible:
		# LOGIC IMPROVEMENT: The _draw function works in the Control node's local coordinates.
		# We need to use the panel's local position for drawing, not a global one.
		
		# Draw the panel's bounding box
		var panel_rect := Rect2(_panel.position, _panel.size)
		draw_rect(panel_rect, Color.YELLOW, false, 2.0)
		
		# Calculate the target's center based on the panel's new position
		var target_center_local = _panel.position + (_panel.size / 2.0)
		draw_circle(target_center_local, 10.0, Color.RED)
