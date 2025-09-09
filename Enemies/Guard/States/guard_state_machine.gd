# res://Enemies/Guard/States/guard_state_machine.gd
class_name GuardStateMachine
extends Node

@export var initial_state: GuardState

var current_state: GuardState
var states: Dictionary = {}


func initialize():
	for child in get_children():
		if child is GuardState:
			states[child.name] = child
			child.state_machine = self

	if initial_state:
		current_state = initial_state
		current_state.enter()


# ADD THIS ENTIRE FUNCTION
func change_state(new_state_name: String):
	# Don't change to the same state.
	if current_state and current_state.name == new_state_name:
		return

	# Call the exit function on the current state before switching.
	if current_state:
		current_state.exit()
	
	# Find the new state in our dictionary of children.
	var new_state = states.get(new_state_name)
	if new_state:
		current_state = new_state
		current_state.enter()
	else:
		printerr("Guard State Machine Error: State '", new_state_name, "' not found.")
