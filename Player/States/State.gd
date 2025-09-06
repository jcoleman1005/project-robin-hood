# State.gd
class_name State
extends Node

# A reference to the parent state machine.
var state_machine: Node

# A reference to the player character. We get this from the owner.
@onready var player: CharacterBody2D = get_owner()

## This virtual function is called when the state is entered.
func enter():
	pass # To be overridden by child states.

## This virtual function is called when the state is exited.
func exit():
	pass # To be overridden by child states.

## This virtual function runs during the _input() process.
func process_input(_event: InputEvent):
	pass # To be overridden by child states.

## This virtual function runs during the _physics_process().
func process_physics(_delta: float):
	pass # To be overridden by child states.
