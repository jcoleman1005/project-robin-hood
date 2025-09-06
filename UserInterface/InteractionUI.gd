# res://UserInterface/interaction_ui.gd
extends CanvasLayer

# THE FIX: Update the node path to find the Label inside the PanelContainer.
@onready var _label: Label = $Panel/Label

var _target_interactable: Node2D = null


func _ready() -> void:
	# The PanelContainer now handles all positioning, so we don't need
	# the old anchoring code here anymore.
	hide()


func show_prompt(target: Node2D) -> void:
	_target_interactable = target
	_label.text = target.prompt_message
	show()


func hide_prompt() -> void:
	_target_interactable = null
	hide()
