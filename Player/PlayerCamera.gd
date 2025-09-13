# res://Player/PlayerCamera.gd
extends Camera2D

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
	assert(is_instance_valid(_player), "PlayerCamera must be a child of a valid player node.")
	
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
	if not is_instance_valid(_player) or not is_instance_valid(stats): 
		return
	
	var facing_direction = 1.0 if not _player.animated_sprite.flip_h else -1.0
	var horizontal_offset = 0.0
	var move_input = Input.get_axis("left", "right")
	
	if move_input != 0:
		horizontal_offset = move_input * nvl(stats.lookahead_distance, 120.0)
	else:
		horizontal_offset = facing_direction * nvl(stats.facing_offset, 50.0)
	
	var base_target_x = _player.global_position.x + horizontal_offset
	var base_target_y = _calculate_stable_vertical_target()
	_target_position = Vector2(base_target_x, base_target_y)
	
	_update_dynamic_offset(delta)
	
	var final_target = _target_position + _current_offset
	var smoothing = nvl(stats.smoothing_speed, 6.0)
	self.global_position = self.global_position.lerp(final_target, delta * smoothing)


func _update_dynamic_offset(delta: float) -> void:
	var diff = self.global_position - _target_position
	var target_offset = Vector2.ZERO
	
	if diff.x > stats.horizontal_deadzone:
		target_offset.x = diff.x - stats.horizontal_deadzone
	elif diff.x < -stats.horizontal_deadzone:
		target_offset.x = diff.x + stats.horizontal_deadzone
	
	if _player.velocity.y < -stats.upward_velocity_threshold:
		target_offset.y = stats.vertical_lookahead_amount
		_current_offset = _current_offset.lerp(target_offset, delta * stats.vertical_lookahead_speed)
		return 
	
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
	# --- REFACTORED LEDGE PEEK LOGIC ---
	# First, correctly position the ledge ray based on player facing direction.
	var facing_direction = 1.0 if not _player.animated_sprite.flip_h else -1.0
	_ledge_ray.position.x = abs(_ledge_ray.position.x) * facing_direction
	
	# The one condition to check for a peek is if the player is on the floor AND the ledge ray is not touching anything.
	var is_at_ledge = _player.is_on_floor() and not _ledge_ray.is_colliding()

	if is_at_ledge:
		# If we are at a ledge, find the ground position and return the peek offset.
		if _ground_ray.is_colliding():
			_last_known_ground_y = _ground_ray.get_collision_point().y
			return _last_known_ground_y + stats.ledge_peek_offset

	# --- DEFAULT BEHAVIOR (If not at a ledge) ---
	# If on the floor, update the last known ground position.
	if _player.is_on_floor() and _ground_ray.is_colliding():
		_last_known_ground_y = _ground_ray.get_collision_point().y
		return _last_known_ground_y

	# If airborne, use the deadzone logic based on the last known ground position.
	var vertical_diff = _player.global_position.y - _last_known_ground_y
	if abs(vertical_diff) < stats.vertical_deadzone:
		return _last_known_ground_y
	else:
		return _player.global_position.y - (stats.vertical_deadzone * sign(vertical_diff))


func nvl(value, if_null):
	if value == null:
		return if_null
	return value
