# res://Interactables/Interactable.gd
class_name Interactable
extends Area2D

signal interacted

@export var prompt_message: String = "Interact"

# This function is called by the player/manager.
func perform_interaction():
	interacted.emit()
