# res://Player/PlayerCamera.gd
extends Camera2D

# All the individual export variables have been replaced by this single resource.
@export var stats: CameraStats

# --- Node References ---
var _player: CharacterBody2D
@onready var _ground_ray: RayCast2D = get_parent().get_node("GroundRay")
@onready var _ledge_ray: RayCast2D = get_parent().get_node("LedgeRay")

# --- Internal State ---
var _target_position: Vector2 = Vector2.ZERO
var _last_known_ground_y: float = 0.0
var _current_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	_player = get_parent()
	if not is_instance_valid(_player):
		printerr("PlayerCamera has no valid parent!")
		return
	
	global_position = _player.global_position
	_target_position = _player.global_position
	_last_known_ground_y = _player.global_position.y

	call_deferred("_setup_level_limits")


func _setup_level_limits() -> void:
	var boundary_nodes = get_tree().get_nodes_in_group("camera_boundary")
	if boundary_nodes.is_empty(): return

	var boundary_area: Area2D = boundary_nodes[0]
	var shape_node: CollisionShape2D = boundary_area.get_node("CollisionShape2D")
	var global_rect: Rect2 = shape_node.get_global_transform() * shape_node.shape.get_rect()
	
	self.limit_left = int(global_rect.position.x)
	self.limit_top = int(global_rect.position.y)
	self.limit_right = int(global_rect.end.x)
	self.limit_bottom = int(global_rect.end.y)


func _physics_process(delta: float) -> void:
	# Add a safety check to ensure the stats resource has been assigned.
	if not is_instance_valid(_player) or not is_instance_valid(stats): 
		return
	
	var base_target_x = _player.global_position.x + (Input.get_axis("left", "right") * stats.lookahead_distance)
	var base_target_y = _calculate_stable_vertical_target()
	_target_position = Vector2(base_target_x, base_target_y)
	
	_update_dynamic_offset(delta)
	
	var final_target = _target_position + _current_offset
	self.global_position = self.global_position.lerp(final_target, delta * stats.smoothing_speed)
	
	DebugManager.print_camera_log(
		_player.global_position.x, _target_position.x, 
		_player.global_position.x - _target_position.x, 
		stats.horizontal_deadzone
	)
	DebugManager.print_camera_log_vertical(
		_player.global_position.y, _target_position.y, 
		_player.global_position.y - _target_position.y, 
		stats.vertical_deadzone
	)


func _update_dynamic_offset(delta: float) -> void:
	var diff = self.global_position - _target_position
	var target_offset = Vector2.ZERO
	
	if diff.x > stats.horizontal_deadzone:
		target_offset.x = diff.x - stats.horizontal_deadzone
	elif diff.x < -stats.horizontal_deadzone:
		target_offset.x = diff.x + stats.horizontal_deadzone
	
	if diff.y > stats.vertical_deadzone:
		target_offset.y = diff.y - stats.vertical_deadzone
	elif diff.y < -stats.vertical_deadzone:
		target_offset.y = diff.y + stats.vertical_deadzone

	if _player.velocity.y > 200:
		target_offset.y = lerp(target_offset.y, diff.y, delta * stats.smoothing_speed * stats.fall_speed_multiplier)

	var current_player_state = _player.get_current_state_name()
	
	if current_player_state == "OnWallState":
		target_offset.y = stats.wall_slide_peek_offset
	else:
		var look_input = Input.get_axis("up", "down")
		target_offset.y += look_input * stats.look_offset
	
	_current_offset = _current_offset.lerp(target_offset, delta * stats.look_speed)


func _calculate_stable_vertical_target() -> float:
	var facing_direction = -1.0 if _player.get_node("AnimatedSprite2D").flip_h else 1.0
	_ledge_ray.position.x = abs(_ledge_ray.position.x) * facing_direction
	
	var is_moving_fast_enough = abs(_player.velocity.x) > 10
	var is_ledge_ray_clear = not _ledge_ray.is_colliding()
	var is_looking_down = Input.is_action_pressed("down")

	if _player.is_on_floor() and is_moving_fast_enough and is_ledge_ray_clear:
		DebugManager.print_ledge_peek_log(true, "Automatic (running towards ledge).")
		if _ground_ray.is_colliding():
			_last_known_ground_y = _ground_ray.get_collision_point().y
			return _last_known_ground_y + stats.ledge_peek_offset
	
	elif _player.is_on_floor() and not is_moving_fast_enough and is_ledge_ray_clear and is_looking_down:
		DebugManager.print_ledge_peek_log(true, "Manual (holding down at ledge).")
		if _ground_ray.is_colliding():
			_last_known_ground_y = _ground_ray.get_collision_point().y
			return _last_known_ground_y + stats.ledge_peek_offset

	else:
		if not _player.is_on_floor():
			DebugManager.print_ledge_peek_log(false, "Player is airborne.")
		elif is_moving_fast_enough and not is_ledge_ray_clear:
			DebugManager.print_ledge_peek_log(false, "LedgeRay is colliding.")
		
	if _player.is_on_floor() and _ground_ray.is_colliding():
		_last_known_ground_y = _ground_ray.get_collision_point().y
		return _last_known_ground_y

	var vertical_diff = _player.global_position.y - _last_known_ground_y

	if abs(vertical_diff) < stats.vertical_deadzone:
		return _last_known_ground_y
	else:
		return _player.global_position.y - (stats.vertical_deadzone * sign(vertical_diff))
