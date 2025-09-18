# res://Player/States/WallKickState.gd
extends State

@export var wall_kick_vfx: VFXData

func enter() -> void:
	var wall_normal = player.get_wall_normal()
	var input_x = Input.get_axis("left", "right")
	
	player.velocity.x = wall_normal.x * player.stats.wall_kick_horizontal_velocity
	player.velocity.y = player.stats.wall_kick_vertical_velocity
	
	player.wall_kick_timer.start(player.stats.wall_kick_duration)
	
	player.animation_controller.update_animation(player.States.DASHING, player.velocity, wall_normal, input_x)
	
	if is_instance_valid(wall_kick_vfx):
		player.vfx.play_effect(wall_kick_vfx)
	
	player.vfx.play_dash_effects(player.dash_particles)


func process_physics(delta: float) -> void:
	player.velocity.y += player.stats.jump_fall_gravity * delta
	
	if player.is_on_ceiling():
		state_machine.change_state("Falling")


func exit() -> void:
	player.vfx.stop_dash_effects(player.dash_particles)
	player.wall_kick_timer.stop()
