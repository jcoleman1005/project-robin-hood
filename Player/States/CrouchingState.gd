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
	# THE ROBUST FIX: We are only truly "falling" if we are not on the floor
	# AND we have downward vertical velocity. This prevents the one-frame flicker.
	if not player.is_on_floor() and player.velocity.y > 0:
		state_machine.change_state("Falling")
		return

	var input_x: float = Input.get_axis("left", "right")

	var target_velocity_x = input_x * player.stats.speed * player.stats.crouch_speed_multiplier
	player.velocity.x = lerp(player.velocity.x, target_velocity_x, player.stats.acceleration_smoothness)
	
	if Input.is_action_just_pressed("slide") and player.can_standing_slide:
		state_machine.change_state("Sliding")
	elif Input.is_action_just_pressed("jump"):
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
