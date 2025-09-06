# Interactable.gd
class_name Interactable
extends Area2D

## This signal is emitted when the player interacts with this object.
signal interacted

## The message to display (e.g., "Press E to Open").
@export var prompt_message: String = "Interact"

# This function is called by the player.
func perform_interaction():
	interacted.emit()
