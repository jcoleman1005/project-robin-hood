# res://Player/States/CrouchingState.gd
extends State

func enter() -> void:
	player.set_crouching_collision()
	player.crouch_timer.start(player.JUMP_CHARGE_DURATION)
	player.is_jump_charged = false # Reset the charged flag.


func exit() -> void:
	# Stop the timer when we leave this state.
	player.crouch_timer.stop()
	# Change collision back to standing, but only if there's room.
	if player.is_head_clear():
		player.set_standing_collision()


func process_physics(_delta: float) -> void:
	# ADD THIS CHECK: If we are not on the floor, we should be falling.
	if not player.is_on_floor():
		state_machine.change_state("Falling")
		return # Exit early.

	var input_x: float = Input.get_axis("left", "right")

	# Apply movement at a reduced speed
	var target_velocity_x = input_x * player.stats.speed * player.stats.crouch_speed_multiplier
	player.velocity.x = lerp(player.velocity.x, target_velocity_x, player.stats.acceleration_smoothness)
	
	# --- Handle State Transitions ---
	if Input.is_action_just_pressed("jump"):
		if player.is_head_clear():
			if player.is_jump_charged:
				player.velocity.y = player.stats.charged_jump_velocity
			else:
				player.velocity.y = player.stats.jump_velocity
			player.current_jumps = 1
			state_machine.change_state("Jumping")
	
	elif not Input.is_action_pressed("down"):
		if player.is_head_clear():
			state_machine.change_state("Idle")
			
	player.animation_controller.update_animation(
		player.States.CROUCHING, player.velocity, Vector2.ZERO, input_x
	)
