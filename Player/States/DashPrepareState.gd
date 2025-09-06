# DashPrepareState.gd
extends State

func enter():
	player.can_dash = false
	player.velocity = Vector2.ZERO
	player.dash_freeze_timer.start(player.stats.dash_freeze_duration)
	var input_x = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.DASH_PREPARE, player.velocity, Vector2.ZERO, input_x)

func process_physics(_delta):
	# This state is controlled by a timer.
	# The logic is in the _on_dash_freeze_timer_timeout() function in PlayerScript.gd.
	# When that timer finishes, it will change the state to Dashing.
	pass
