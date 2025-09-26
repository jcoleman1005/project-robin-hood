# res://Player/States/LedgeGrab.gd
extends State

var ledge_position: Vector2

func enter() -> void:
	player.velocity = Vector2.ZERO
	player.global_position = ledge_position
	player.animation_controller.update_animation(player.States.LEDGE_GRAB, player.velocity, Vector2.ZERO, 0)


func process_physics(_delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		state_machine.get_node("LedgeClimbState").ledge_position = ledge_position
		state_machine.change_state("LedgeClimb")
	elif Input.is_action_just_pressed("down"):
		# Detach from the wall slightly to prevent re-grabbing
		player.animated_sprite.flip_h = not player.animated_sprite.flip_h
		state_machine.change_state("Falling")
