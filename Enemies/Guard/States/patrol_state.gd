# res://Enemies/Guard/States/patrol_state.gd
extends GuardState

var _detection_progress: float = 0.0
@onready var vision_cone_node: Node2D = guard.get_node("VisionCone2D")
@onready var ground_check_ray: RayCast2D = guard.get_node("GroundCheckRay")


func enter() -> void:
	_detection_progress = 0.0
	guard.animated_sprite.play("walk")


func process_physics(delta: float) -> void:
	guard.velocity.y += delta * 1200.0

	if ground_check_ray.is_colliding() and guard.turn_cooldown_timer.is_stopped():
		if not guard.ledge_check_ray.is_colliding() or guard.wall_check_ray.is_colliding():
			guard.turn_around()
			
	guard.velocity.x = guard.speed * guard.direction

	var is_facing_left = (guard.direction < 0)
	guard.animated_sprite.flip_h = is_facing_left
	
	guard.ledge_check_ray.position.x = abs(guard.ledge_check_ray.position.x) * guard.direction
	guard.wall_check_ray.target_position.x = abs(guard.wall_check_ray.target_position.x) * guard.direction
	
	vision_cone_node.rotation_degrees = 90 if is_facing_left else -90
	
	if guard.is_player_in_cone and not get_tree().get_first_node_in_group("player").is_invisible:
		_detection_progress += delta / 1.5
	else:
		_detection_progress -= delta / 1.5
	
	_detection_progress = clamp(_detection_progress, 0.0, 1.0)
	
	var target_color: Color
	if _detection_progress < 0.5:
		target_color = guard.vision_cone_neutral_color.lerp(guard.vision_cone_suspicious_color, _detection_progress * 2)
	else:
		target_color = guard.vision_cone_suspicious_color.lerp(guard.vision_cone_alert_color, (_detection_progress - 0.5) * 2)

	guard.vision_cone_renderer.color = target_color

	if _detection_progress >= 1.0:
		# THE FIX: Emit the signal AND immediately change to an inert state.
		EventBus.player_detected.emit()
		state_machine.change_state("CaughtState")
