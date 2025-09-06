# res://Singletons/InteractionManager.gd
extends Node

signal show_prompt(interactable)
signal hide_prompt

var _current_interactable = null

func _ready() -> void:
	EventBus.interact_pressed.connect(_on_interact_pressed)
	EventBus.mission_started.connect(clear_interactable)

func clear_interactable() -> void:
	print("DEBUG: InteractionManager - Clearing interactable.")
	_current_interactable = null
	hide_prompt.emit()

func register_interactable(interactable: Interactable) -> void:
	# Get the parent of the interactable area (e.g., the Chest or MissionBoard node).
	var parent_node = interactable.get_parent()
	print("DEBUG: InteractionManager - Registering: ", parent_node.name)
	_current_interactable = interactable
	show_prompt.emit(_current_interactable)


func unregister_interactable(interactable: Interactable) -> void:
	var parent_node = interactable.get_parent()
	if _current_interactable == interactable:
		print("DEBUG: InteractionManager - Unregistering: ", parent_node.name)
		_current_interactable = null
		hide_prompt.emit()


func _on_interact_pressed() -> void:
	if is_instance_valid(_current_interactable):
		_current_interactable.perform_interaction()
