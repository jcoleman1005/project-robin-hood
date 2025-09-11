# res://Player/States/SlidingState.gd
extends State

func enter() -> void:
	player.slide_timer.start(player.stats.slide_duration)
	player.set_crouching_collision()

	# Check if this is a standing slide and apply cooldown if necessary.
	if abs(player.velocity.x) < 10.0:
		var direction = 1.0 if not player.animated_sprite.flip_h else -1.0
		player.velocity.x = player.stats.standing_slide_speed * direction
		
		player.can_standing_slide = false
		player.standing_slide_cooldown_timer.start(1.0)

	var input_x: float = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.SLIDING, player.velocity, Vector2.ZERO, input_x)


func exit() -> void:
	player.slide_timer.stop()
	if player.is_head_clear():
		player.set_standing_collision()


func process_physics(_delta: float) -> void:
	# --- Apply friction and handle falling off ledges ---
	player.velocity.x = lerp(player.velocity.x, 0.0, player.stats.slide_friction)
	if not player.ground_ray.is_colliding():
		state_machine.change_state("Falling")
		return

	# --- Determine if the player WANTS to or SHOULD stop sliding ---
	var wants_to_exit_slide = Input.is_action_just_released("slide")
	var must_exit_slide = player.slide_timer.is_stopped()

	# --- Handle Jumping out of a slide ---
	# A player can always try to jump out of a slide.
	if Input.is_action_just_pressed("jump"):
		# But only if their head is clear.
		if player.is_head_clear():
			state_machine.change_state("Jumping")
		# If head is not clear, the jump input is ignored and we continue sliding.
		return

	# --- Handle Exiting the slide by stopping or timer timeout ---
	if wants_to_exit_slide or must_exit_slide:
		# We can only exit the slide if the player's head is clear.
		if player.is_head_clear():
			# If head is clear, transition to the appropriate state based on input.
			if Input.is_action_pressed("down"):
				state_machine.change_state("Crouching")
			else:
				state_machine.change_state("Idle")
		# If head is NOT clear, we do nothing and let the slide continue,
		# effectively extending it until the player emerges from the tunnel.
