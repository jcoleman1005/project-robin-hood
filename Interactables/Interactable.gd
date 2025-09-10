# res://Interactables/Interactable.gd
class_name Interactable
extends Area2D

signal interacted

@export var prompt_message: String = "Interact"
@export var prompt_vertical_offset: float = -40.0 ## Negative values move it up
@export var interaction_duration: float = 1.0 # Time in seconds to hold

# This function is called by the player/manager.
func perform_interaction():
	interacted.emit()
