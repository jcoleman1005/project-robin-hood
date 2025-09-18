# res://Player/States/DashingState.gd
extends State

func enter() -> void:
	player.animation_controller.update_animation(player.States.DASHING, player.velocity, Vector2.ZERO, 0)


func process_physics(_delta: float) -> void:
	if not player.stats.dash_is_blink and player.is_on_wall():
		# If we hit a wall, do the cleanup...
		player.end_dash()
		# ...and then transition directly to the OnWallState.
		state_machine.change_state("OnWall")
		return
