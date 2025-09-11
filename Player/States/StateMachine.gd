# StateMachine.gd
class_name StateMachine
extends Node

## The starting state for the machine. Set this in the Inspector.
@export var initial_state: NodePath
signal state_changed(new_state_name: String)

var current_state: State
var states: Dictionary = {}

# The _ready function is now empty.
func _ready():
	pass

# This new function will be called by the Player after it's ready.
func initialize():
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.state_machine = self
	
	if initial_state:
		current_state = get_node(initial_state)
		current_state.enter()

## Changes the active state.
func change_state(state_name: String):
	var new_state_node_name = state_name + "State"

	# Don't change to the same state.
	if current_state.name == new_state_node_name:
		return
	
	DebugManager.log(DebugManager.Category.PLAYER_STATE, "Changing state from '%s' to '%s'" % [current_state.name, new_state_node_name])
	
	# Call the exit function on the current state.
	if current_state:
		current_state.exit()
	
	# Find the new state in our dictionary.
	var new_state = states.get(new_state_node_name)
	if new_state:
		current_state = new_state
		current_state.enter()
		state_changed.emit(state_name)
	else:
		printerr("State '" + new_state_node_name + "' not found in StateMachine.")

## Pass the engine callbacks to the active state.
func _input(event: InputEvent):
	if current_state:
		current_state.process_input(event)

func _physics_process(delta: float):
	if current_state:
		current_state.process_physics(delta)
