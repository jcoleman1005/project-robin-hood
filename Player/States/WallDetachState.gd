# res://Player/States/WallDetachState.gd
extends State

func enter() -> void:
	var input_x: float = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.WALL_DETACH, player.velocity, Vector2.ZERO, input_x)

func process_physics(delta: float) -> void:
	var input_x: float = Input.get_axis("left", "right")
	
	# Use stats resource for physics values
	player.velocity.y += player.stats.fall_gravity * player.stats.wall_detach_gravity_scale * delta
	player.velocity.x = move_toward(player.velocity.x, input_x * player.stats.speed, player.stats.air_control_acceleration)
	
	if Input.is_action_just_pressed("jump"):
		if not player.wall_coyote_timer.is_stopped():
			player.wall_jump(player.last_wall_normal)
			player.wall_detach_timer.stop()
			state_machine.change_state("Falling")
		else:
			player.jump_buffered = true
			player.jump_buffer_timer.start(player.stats.jump_buffer_duration)
	elif player.wall_detach_timer.is_stopped():
		state_machine.change_state("Falling")
