# res://Player/States/LedgeClimb.gd
extends State

var ledge_position: Vector2

func enter() -> void:
	player.velocity = Vector2.ZERO
	player.animation_controller.update_animation(player.States.LEDGE_CLIMB, player.velocity, Vector2.ZERO, 0)

	var end_pos = ledge_position + player.stats.ledge_climb_end_offset
	var tween = get_tree().create_tween()
	tween.tween_property(player, "global_position", end_pos, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): state_machine.change_state("Idle"))


func process_physics(_delta: float) -> void:
	# Movement is handled by the tween
	pass
