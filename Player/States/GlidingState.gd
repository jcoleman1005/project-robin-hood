# res://Player/States/GlidingState.gd
extends State

func enter() -> void:
	# Announce that gliding has started.
	player.gliding_started.emit()
	var input_x: float = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.GLIDING, player.velocity, Vector2.ZERO, input_x)

func exit() -> void:
	# Announce that gliding has ended.
	player.gliding_ended.emit()

func process_physics(_delta: float) -> void:
	var input_x: float = Input.get_axis("left", "right")

	player.velocity.y = player.stats.special_glide_velocity
	player.velocity.x = move_toward(player.velocity.x, input_x * player.stats.core_speed, 150)

	if player.is_on_floor():
		state_machine.change_state("Landing")
	elif player.is_on_wall():
		state_machine.change_state("OnWall")
	elif Input.is_action_just_released("up"):
		state_machine.change_state("Falling")
	elif Input.is_action_just_pressed("jump"):
		if player.current_jumps < player.MAX_JUMPS:
			state_machine.change_state("Jumping")
		else:
			player.jump_buffered = true
			player.jump_buffer_timer.start(player.stats.feel_jump_buffer_duration)
