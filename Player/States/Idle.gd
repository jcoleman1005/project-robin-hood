# IdleState.gd
extends State

func enter() -> void:
	# Play the idle animation.
	var input_x: float = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.IDLE, player.velocity, Vector2.ZERO, input_x)


func process_physics(_delta: float) -> void:
	# Apply friction to slow the player down using our stats resource.
	player.velocity.x = lerp(player.velocity.x, 0.0, player.stats.friction_smoothness)
	
	# --- Check for transitions to other states ---
	var input_x: float = Input.get_axis("left", "right")
	
	if Input.is_action_pressed("ui_down"):
		state_machine.change_state("Crouching")
	elif input_x != 0:
		state_machine.change_state("Running")
	elif Input.is_action_just_pressed("jump"):
		state_machine.change_state("Jumping")
	elif not player.is_on_floor():
		# This handles walking off a ledge.
		player.coyote_timer.start(player.stats.coyote_time_duration)
		player.fall_zoom_timer.start(player.stats.fall_zoom_delay)
		state_machine.change_state("Falling")
