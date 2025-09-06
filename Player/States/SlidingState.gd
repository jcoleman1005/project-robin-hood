# res://Player/States/SlidingState.gd
extends State

func enter() -> void:
	player.slide_timer.start(player.stats.slide_duration)
	player.set_crouching_collision()
	var input_x: float = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.SLIDING, player.velocity, Vector2.ZERO, input_x)

func exit() -> void:
	player.slide_timer.stop()
	if player.is_head_clear():
		player.set_standing_collision()

func process_physics(_delta: float) -> void:
	# Use stats resource for physics values
	player.velocity.x = lerp(player.velocity.x, 0.0, player.stats.slide_friction)

	if not player.is_on_floor():
		state_machine.change_state("Falling")
	elif player.slide_timer.is_stopped():
		if player.is_head_clear():
			state_machine.change_state("Idle")
		else:
			state_machine.change_state("Crouching")
	elif Input.is_action_just_pressed("jump"):
		state_machine.change_state("Jumping")
