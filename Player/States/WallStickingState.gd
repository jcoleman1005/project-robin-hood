# WallStickingState.gd
extends State

func enter():
		# First, determine which wall we are on.
	var wall_normal = player.get_wall_normal()
	
	# Play the correct offset animation based on the wall's direction.
	if wall_normal.x > 0: # A positive normal means the wall is on the LEFT.
		player.animation_player.play("wall_stick_offset_left")
	else: # A negative normal means the wall is on the RIGHT.
		player.animation_player.play("wall_stick_offset_right")
	
	var input_x = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.WALL_STICKING, player.velocity, player.get_wall_normal(), input_x)

func process_physics(_delta):
	player.velocity.y = 1.0
	player.velocity.x = -player.get_wall_normal().x * 5.0

	if not Input.is_action_pressed("shift"):
		player.wall_stick_timer.stop()
		state_machine.change_state("OnWall")
	elif Input.is_action_just_pressed("jump"):
		player.wall_jump()
		state_machine.change_state("Falling")
	elif not player.is_on_wall():
		player.wall_stick_timer.stop()
		player._start_wall_coyote_time()
		state_machine.change_state("WallDetach")
	elif player.is_on_floor():
		player.wall_stick_timer.stop()
		state_machine.change_state("Idle")
