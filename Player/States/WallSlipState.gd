# res://Player/States/WallSlipState.gd
extends State

func enter() -> void:
	player.wall_slip_timer.start(player.stats.wall_slip_duration)
	var input_x: float = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.WALL_SLIP, player.velocity, player.get_wall_normal(),input_x )

func exit() -> void:
	player.wall_slip_timer.stop()

func process_physics(delta: float) -> void:
	player.velocity.y = move_toward(player.velocity.y, player.stats.wall_slide_friction, player.stats.jump_fall_gravity * delta)
	player.velocity.x = -player.get_wall_normal().x * 5.0

	if player.wall_slip_timer.is_stopped():
		player.can_wall_stick = false
		player.wall_stick_timer.start(player.WALL_STICK_DURATION)
		state_machine.change_state("WallSticking")
	elif not Input.is_action_pressed("shift"):
		state_machine.change_state("OnWall")
	elif Input.is_action_just_pressed("jump"):
		player.wall_jump()
		state_machine.change_state("Falling")
	elif not player.is_on_wall():
		player._start_wall_coyote_time()
		state_machine.change_state("WallDetach")
