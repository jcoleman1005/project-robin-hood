# res://Player/States/UnstickingState.gd
extends State

func enter() -> void:
	player.animation_controller.update_animation(player.States.UNSTICKING, player.velocity, Vector2.ZERO, 0)

func process_physics(delta: float) -> void:
	var last_dash_direction: Vector2 = Vector2(1 if not player.animated_sprite.flip_h else -1, 0)
	# Use stats resource for physics values
	player.global_position -= last_dash_direction * player.stats.speed * delta

	if not player.test_move(player.transform, Vector2.ZERO):
		player.velocity = -last_dash_direction * player.stats.speed * player.stats.dash_end_velocity_multiplier
		player.dash_cooldown_timer.start(player.DASH_COOLDOWN)
		state_machine.change_state("Falling")
