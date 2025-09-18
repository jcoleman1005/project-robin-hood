# DashPrepareState.gd
extends State

@export var dash_prepare_vfx: VFXData

func enter():
	player.can_dash = false
	player.velocity = Vector2.ZERO
	player.dash_freeze_timer.start(player.stats.feel_dash_freeze_duration)

	if dash_prepare_vfx:
		player.vfx.play_effect(dash_prepare_vfx)

	var input_x = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.DASH_PREPARE, player.velocity, Vector2.ZERO, input_x)

func process_physics(_delta):
	# This state is controlled by a timer.
	pass
