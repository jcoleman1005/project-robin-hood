# res://Player/PlayerCamera.gd
extends Camera2D

@export_group("Camera Tuning")
@export var default_camera_zoom: float = 1.0
@export var fall_camera_zoom: float = 0.9
@export var glide_camera_zoom: float = 0.9
@export var camera_zoom_out_speed: float = 0.05
@export var camera_zoom_in_speed: float = 0.2
@export var look_up_offset: float = -75.0
@export var look_down_offset: float = 75.0
@export var camera_vertical_lerp_speed: float = 0.1
@export var horizontal_lookahead: float = 80.0
@export var smoothing_speed: float = 5.0


# --- Private State ---
var player: CharacterBody2D
var _is_in_long_fall: bool = false
var _is_gliding: bool = false
@onready var ground_ray: RayCast2D = get_parent().get_node("GroundRay")
@onready var ledge_ray: RayCast2D = get_parent().get_node("LedgeRay")
var _target_position: Vector2
var _vertical_threshold: float


func _ready() -> void:
	print("DEBUG: PlayerCamera - A new camera has been initialized (_ready called).")
	
	player = get_parent()
	if not is_instance_valid(player):
		printerr("PlayerCamera has no valid parent!")
		return
	
	# Set the initial target position.
	_target_position = player.global_position
	
	# Calculate the 30% screen height threshold in pixels.
	_vertical_threshold = get_viewport_rect().size.y * 0.3
	
	# Connect to the player's signals to track its state.
	player.long_fall_started.connect(func(): _is_in_long_fall = true)
	player.long_fall_ended.connect(func(): _is_in_long_fall = false)
	player.gliding_started.connect(func(): _is_gliding = true)
	player.gliding_ended.connect(func(): _is_gliding = false)
	
	# Wait one frame for the level tree to be fully ready before setting limits.
	call_deferred("_setup_level_limits")


func _setup_level_limits() -> void:
	var boundary_nodes = get_tree().get_nodes_in_group("camera_boundary")
	if boundary_nodes.is_empty():
		return # No boundary found, so we do nothing.
	
	var boundary_area: Area2D = boundary_nodes[0]
	var shape_node: CollisionShape2D = boundary_area.get_node("CollisionShape2D")
	
	# This robustly gets the rectangle's true global coordinates.
	var global_rect: Rect2 = shape_node.get_global_transform() * shape_node.shape.get_rect()
	
	# Apply the correctly calculated values to the camera's limits.
	self.limit_left = int(global_rect.position.x)
	self.limit_top = int(global_rect.position.y)
	self.limit_right = int(global_rect.end.x)
	self.limit_bottom = int(global_rect.end.y)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
		
	# Start with a baseline target. The camera always tracks the player's X,
	# but the Y is determined by the logic below.
	var target_y = _target_position.y
		
	# --- Ledge Look-Down Logic ---
	# Flip the ledge ray's position based on the player's velocity.
	if abs(player.velocity.x) > 10:
		ledge_ray.position.x = abs(ledge_ray.position.x) * sign(player.velocity.x)

	# If the player is on the floor and moving towards a ledge...
	if player.is_on_floor() and not ledge_ray.is_colliding() and abs(player.velocity.x) > 10:
		# ...the target is the last known platform height PLUS the offset.
		if ground_ray.is_colliding():
			target_y = ground_ray.get_collision_point().y + look_down_offset
	
	# --- Settle on Platform Logic ---
	# Otherwise, if not at a ledge but on the floor, lock the target to the platform's surface.
	elif player.is_on_floor() and ground_ray.is_colliding():
		target_y = ground_ray.get_collision_point().y
	
	# --- Jump Deadzone & Fall Logic (runs when airborne) ---
	var vertical_diff = target_y - player.global_position.y
	if vertical_diff > _vertical_threshold:
		target_y = player.global_position.y + _vertical_threshold

	if player.global_position.y > target_y:
		target_y = player.global_position.y
		
	# --- Final Update ---
	# Assemble the final target position from our calculated X and Y.
	_target_position = Vector2(player.global_position.x, target_y)
	# Smoothly move the camera towards its final target.
	self.global_position = self.global_position.lerp(_target_position, delta * smoothing_speed)


func _update_camera_zoom() -> void:
	var target_zoom_value: float = default_camera_zoom
	if _is_in_long_fall:
		target_zoom_value = fall_camera_zoom
	elif _is_gliding:
		target_zoom_value = glide_camera_zoom
	
	var lerp_speed: float = camera_zoom_in_speed if target_zoom_value == default_camera_zoom else camera_zoom_out_speed
	var target_zoom: Vector2 = Vector2(target_zoom_value, target_zoom_value)
	self.zoom = lerp(self.zoom, target_zoom, lerp_speed)


func _update_camera_offset() -> void:
	var target_offset_y: float = 0.0
	if _is_in_long_fall:
		target_offset_y = look_down_offset
	elif player.is_on_floor() and Input.is_action_pressed("ui_up"):
		target_offset_y = look_up_offset
	
	var input_direction_x = Input.get_axis("left", "right")
	var target_offset_x = input_direction_x * horizontal_lookahead
	self.offset.x = lerp(self.offset.x, target_offset_x, camera_vertical_lerp_speed)
	
	self.offset.y = lerp(self.offset.y, target_offset_y, camera_vertical_lerp_speed)
