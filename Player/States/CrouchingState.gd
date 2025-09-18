# res://Player/States/CrouchingState.gd
extends State

func enter() -> void:
	player.set_crouching_collision()
	player.crouch_timer.start(player.JUMP_CHARGE_DURATION)
	player.is_jump_charged = false


func exit() -> void:
	player.crouch_timer.stop()
	if player.is_head_clear():
		player.set_standing_collision()


func process_physics(_delta: float) -> void:
	# Only transition to falling if we are ACTUALLY falling (airborne and moving down).
	if not player.is_on_floor() and player.velocity.y > 0:
		state_machine.change_state("Falling")
		return # <-- ADDED: Stop processing after state change

	var input_x: float = Input.get_axis("left", "right")

	var target_velocity_x = input_x * player.stats.ground_crouch_speed_multiplier
	player.velocity.x = lerp(player.velocity.x, target_velocity_x, player.stats.core_acceleration_smoothness)
	
	if Input.is_action_just_pressed("slide") and player.can_standing_slide:
		state_machine.change_state("Sliding")
		return # <-- ADDED: Stop processing after state change
	elif Input.is_action_just_pressed("jump"):
		if player.is_head_clear():
			if player.is_jump_charged:
				player.velocity.y = player.stats.charged_jump_velocity
			else:
				player.velocity.y = player.stats.jump_velocity
			player.current_jumps = 1
			state_machine.change_state("Jumping")
			return # <-- ADDED: Stop processing after state change
	
	elif not Input.is_action_pressed("down"):
		if player.is_head_clear():
			if input_x != 0:
				state_machine.change_state("Running")
				return # <-- ADDED: Stop processing after state change
			else:
				state_machine.change_state("Idle")
				return # <-- ADDED: Stop processing after state change
			
	# This line will now only be reached if no state change occurs.
	player.animation_controller.update_animation(
		player.States.CROUCHING, player.velocity, Vector2.ZERO, input_x
	)
