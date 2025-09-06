# res://Enemies/Guard/CustomVisionCone.gd
extends Area2D

@export_group("Cone Properties")
@export var radius: float = 200.0
@export var angle_degrees: float = 60.0
@export var ray_count: int = 30

@export_flags_2d_physics var collision_mask_override: int = 1

@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D
@onready var visual_polygon: Polygon2D = $VisionConePolygon


func _ready() -> void:
	# This ensures the collision mask is set correctly when the game starts.
	self.collision_mask = collision_mask_override


func _physics_process(_delta: float) -> void:
	update_cone_shape()


func update_cone_shape() -> void:
	print("DEBUG: CustomVisionCone is updating its shape NOW.")
	var points = PackedVector2Array()
	points.append(Vector2.ZERO)

	var angle_rad = deg_to_rad(angle_degrees)
	var angle_step = angle_rad / (ray_count - 1)
	# THE FIX: We now factor in the parent's rotation to the start angle.
	var start_angle = self.global_rotation - angle_rad / 2.0

	for i in range(ray_count):
		var current_angle = start_angle + i * angle_step
		# Use Vector2.from_angle() for a more stable direction calculation.
		var direction = Vector2.from_angle(current_angle)
		var collision_point = _cast_ray(direction * radius)
		points.append(collision_point)

	collision_polygon.polygon = points
	visual_polygon.polygon = points

func _cast_ray(target_local_pos: Vector2) -> Vector2:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + target_local_pos)
	# Use the built-in collision_mask property, which is set in _ready.
	query.collision_mask = self.collision_mask
	
	var result = space_state.intersect_ray(query)
	
	if result:
		return to_local(result.position)
	else:
		return target_local_pos
