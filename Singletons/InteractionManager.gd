# res://Singletons/InteractionManager.gd
extends Node

signal show_prompt(interactable)
signal hide_prompt

var _current_interactable = null

func _ready() -> void:
	EventBus.interact_pressed.connect(_on_interact_pressed)
	EventBus.mission_started.connect(clear_interactable)

func clear_interactable() -> void:
	_current_interactable = null
	hide_prompt.emit()

func register_interactable(interactable: Interactable) -> void:
	var parent_node = interactable.get_parent()
	_current_interactable = interactable
	show_prompt.emit(_current_interactable)

func unregister_interactable(interactable: Interactable) -> void:
	if _current_interactable == interactable:
		_current_interactable = null
		hide_prompt.emit()

func _on_interact_pressed() -> void:
	if is_instance_valid(_current_interactable):
		_current_interactable.perform_interaction()
