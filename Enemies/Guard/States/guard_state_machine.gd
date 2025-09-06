# res://Enemies/Guard/States/guard_state_machine.gd
class_name GuardStateMachine
extends Node

@export var initial_state: GuardState

var current_state: GuardState
var states: Dictionary = {}

func initialize() -> void:
	for child in get_children():
		if child is GuardState:
			states[child.name] = child
			child.state_machine = self
	
	if initial_state:
		current_state = initial_state
		current_state.enter()

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.process_physics(delta)

func change_state(state_name: String) -> void:
	if not states.has(state_name):
		printerr("Guard FSM Error: State '", state_name, "' not found.")
		return
	
	if current_state:
		current_state.exit()
	
	current_state = states[state_name]
	current_state.enter()
