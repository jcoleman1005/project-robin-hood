# res://Player/States/FallingState.gd
extends State

func enter() -> void:
	var input_x: float = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.FALLING, player.velocity, Vector2.ZERO, input_x)

func process_physics(delta: float) -> void:
	var input_x: float = Input.get_axis("left", "right")

	# Physics logic
	if not player.is_on_floor():
		player.velocity.y += player.stats.fall_gravity * delta
	player.velocity.x = move_toward(player.velocity.x, input_x * player.stats.speed, player.stats.air_control_acceleration)

	# --- Check for transitions ---
	if Input.is_action_pressed("up"):
		state_machine.change_state("Gliding")
		return

	elif player.is_on_floor():
		state_machine.change_state("Landing")
		return

	elif player.is_on_wall():
		if not (sign(player.get_wall_normal().x) == sign(input_x)):
			state_machine.change_state("OnWall")
			return

	elif Input.is_action_just_pressed("jump"):
		# NEW LOGIC: Check for nearby walls with RayCasts first.
		if player.wall_check_ray_right.is_colliding():
			# If the right ray hits a wall, we perform a wall jump as if we hit a wall on our right.
			player.wall_jump(Vector2(-1, 0)) # Provide a left-pointing normal.
			state_machine.change_state("Jumping")
			return
		elif player.wall_check_ray_left.is_colliding():
			# If the left ray hits a wall, we jump as if we hit a wall on our left.
			player.wall_jump(Vector2(1, 0)) # Provide a right-pointing normal.
			state_machine.change_state("Jumping")
			return
		
		# --- Original Logic ---
		# If no nearby walls, check for coyote time or double jump.
		if not player.wall_coyote_timer.is_stopped():
			player.wall_jump(player.last_wall_normal)
			state_machine.change_state("Jumping")
			return
		elif player.current_jumps < player.MAX_JUMPS:
			state_machine.change_state("Jumping")
			return
		else:
			player.jump_buffered = true
			player.jump_buffer_timer.start(player.stats.jump_buffer_duration)

	player.animation_controller.update_animation(player.States.FALLING, player.velocity, Vector2.ZERO, input_x)
