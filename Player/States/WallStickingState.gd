# WallStickingState.gd
extends State

func enter():
	var wall_normal = player.get_wall_normal()
	
	if wall_normal.x > 0:
		player.animation_player.play("wall_stick_offset_left")
	else:
		player.animation_player.play("wall_stick_offset_right")
	
	var input_x = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.WALL_STICKING, player.velocity, player.get_wall_normal(), input_x)

func process_physics(_delta):
	player.velocity.y = 1.0
	player.velocity.x = -player.get_wall_normal().x * 5.0

	var input_x: float = Input.get_axis("left", "right")
	var wall_normal = player.get_wall_normal()

	if Input.is_action_just_pressed("jump"):
		# NEW: Check for kick-off input here
		if GameManager.wall_kick_unlocked and input_x != 0 and sign(input_x) == sign(wall_normal.x):
			state_machine.change_state("WallKick")
		else:
			# If not kicking off, perform a normal stick jump
			player.wall_jump()
			# We can add a VFX for the stick jump here later if we want.
			state_machine.change_state("Falling")
		return

	elif not Input.is_action_pressed("shift"):
		player.wall_stick_timer.stop()
		state_machine.change_state("OnWall")
	elif not player.is_on_wall():
		player.wall_stick_timer.stop()
		player._start_wall_coyote_time()
		state_machine.change_state("WallDetach")
	elif player.is_on_floor():
		player.wall_stick_timer.stop()
		state_machine.change_state("Idle")
