# res://Enemies/Guard/States/guard_state.gd
class_name GuardState
extends Node

var state_machine: Node
@onready var guard: CharacterBody2D = get_owner() as CharacterBody2D

func enter() -> void:
	pass

func exit() -> void:
	pass

func process_physics(_delta: float) -> void:
	pass
