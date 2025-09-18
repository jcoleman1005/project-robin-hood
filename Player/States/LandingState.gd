# res://Player/States/LandingState.gd
extends State

@export var land_vfx: VFXData

func enter() -> void:
	player.current_jumps = 0
	
	var fall_distance = player.global_position.y - player.fall_start_y
	if fall_distance >= player.stats.feel_long_fall_distance:
		player.landing_shake_emitter.emit()

	player.animation_player.play("land_squish")

	var input_x: float = Input.get_axis("left", "right")
	player.animation_controller.update_animation(player.States.LANDING, player.velocity, Vector2.ZERO, input_x)

	if land_vfx:
		player.vfx.play_effect(land_vfx)

func exit() -> void:
	pass

func process_physics(_delta: float) -> void:
	if Input.is_action_just_pressed("jump") or player.jump_buffered:
		player.jump_buffered = false
		player.jump_buffer_timer.stop()
		state_machine.change_state("Jumping")
		return

	player.velocity.x = lerp(player.velocity.x, 0.0, player.stats.core_friction_smoothness)
