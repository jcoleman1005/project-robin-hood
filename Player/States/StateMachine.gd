# StateMachine.gd
class_name StateMachine
extends Node

@export var initial_state: NodePath
signal state_changed(new_state_name: String)

var current_state: State
var states: Dictionary = {}

func initialize():
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.state_machine = self
	
	if initial_state:
		current_state = get_node(initial_state)
		current_state.enter()

func change_state(state_name: String):
	var new_state_node_name = state_name + "State"

	if current_state.name == new_state_node_name:
		return
	
	DebugManager.print_player_state_log("Changing state from '%s' to '%s'" % [current_state.name, new_state_node_name])
	
	if current_state:
		current_state.exit()
	
	var new_state = states.get(new_state_node_name)
	if new_state:
		current_state = new_state
		current_state.enter()
		state_changed.emit(state_name)
	else:
		printerr("State '" + new_state_node_name + "' not found in StateMachine.")

func _input(event: InputEvent):
	if current_state:
		current_state.process_input(event)

func _physics_process(delta: float):
	if current_state:
		current_state.process_physics(delta)
