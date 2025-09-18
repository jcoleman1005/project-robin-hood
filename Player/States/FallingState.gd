# res://Player/States/FallingState.gd
extends State

@export var wall_jump_vfx: VFXData

func enter() -> void:
	player.fall_start_y = player.global_position.y
	var input_x: float = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.FALLING, player.velocity, Vector2.ZERO, input_x)

func process_physics(delta: float) -> void:
	var input_x: float = Input.get_axis("left", "right")

	if not player.is_on_floor():
		player.velocity.y += player.stats.jump_fall_gravity * delta
	player.velocity.x = move_toward(player.velocity.x, input_x * player.stats.core_speed, player.stats.jump_air_control_acceleration)

	if Input.is_action_pressed("up"):
		state_machine.change_state("Gliding")
		return
	elif player.is_on_floor():
		if Input.is_action_pressed("slide"):
			state_machine.change_state("Sliding")
		else:
			state_machine.change_state("Landing")
		return
	elif player.is_on_wall():
		if not (sign(player.get_wall_normal().x) == sign(input_x)):
			state_machine.change_state("OnWall")
			return
	elif Input.is_action_just_pressed("jump"):
		if player.wall_check_ray_right.is_colliding():
			player.wall_jump(Vector2(-1, 0))
			if wall_jump_vfx:
				player.vfx.play_effect(wall_jump_vfx)
			state_machine.change_state("Jumping")
			return
		elif player.wall_check_ray_left.is_colliding():
			player.wall_jump(Vector2(1, 0))
			if wall_jump_vfx:
				player.vfx.play_effect(wall_jump_vfx)
			state_machine.change_state("Jumping")
			return

		if not player.wall_coyote_timer.is_stopped():
			player.wall_jump(player.last_wall_normal)
			if wall_jump_vfx:
				player.vfx.play_effect(wall_jump_vfx)
			state_machine.change_state("Jumping")
			return
		elif player.current_jumps < player.MAX_JUMPS:
			state_machine.change_state("Jumping")
			return
		else:
			player.jump_buffered = true
			player.jump_buffer_timer.start(player.stats.feel_jump_buffer_duration)

	player.animation_controller.update_animation(player.States.FALLING, player.velocity, Vector2.ZERO, input_x)
