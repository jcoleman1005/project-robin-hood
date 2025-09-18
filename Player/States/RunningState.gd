# res://Player/States/RunningState.gd
extends State

func enter() -> void:
	
	var input_x: float = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.RUNNING, player.velocity, Vector2.ZERO, input_x)

func process_physics(_delta: float) -> void:
	var input_x: float = Input.get_axis("left", "right")

	if Input.is_action_just_pressed("slide"):
		state_machine.change_state("Sliding")
		return

	if input_x != 0 and sign(input_x) != sign(player.velocity.x) and abs(player.velocity.x) > 100:
		state_machine.change_state("Skidding")
		return

	player.velocity.x = lerp(player.velocity.x, input_x * player.stats.core_speed, player.stats.core_acceleration_smoothness)

	if input_x == 0:
		state_machine.change_state("Idle")
	elif Input.is_action_just_pressed("jump"):
		state_machine.change_state("Jumping")
	elif not player.is_on_floor():
		player.coyote_timer.start(player.stats.feel_coyote_time_duration)
		state_machine.change_state("Falling")
