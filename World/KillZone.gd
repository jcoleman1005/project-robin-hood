# res://World/KillZone.gd
extends Area2D

# These will be set by the LevelGenerator before this node is added to the scene.
var start_pos: Vector2
var end_pos: Vector2

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _left_edge: Marker2D = $LeftEdge
@onready var _right_edge: Marker2D = $RightEdge


func _ready() -> void:
	assert(is_instance_valid(_left_edge), "KillZone Error: LeftEdge marker node not found.")
	assert(is_instance_valid(_right_edge), "KillZone Error: RightEdge marker node not found.")

	body_entered.connect(_on_body_entered)

	# Defer the shape update to ensure all positioning is settled.
	call_deferred("_update_shape")


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		Loggie.info("Player entered KillZone. Emitting player_died signal.", "game_state")
		EventBus.player_died.emit()


# REMOVED: set_extents is no longer needed.


func _update_shape() -> void:
	# Position the markers first, based on the public variables.
	_left_edge.global_position = start_pos
	_right_edge.global_position = end_pos

	# Position the KillZone root node at the starting marker.
	global_position = _left_edge.global_position

	var width = _right_edge.global_position.x - _left_edge.global_position.x
	var height = 1.0

	# Ensure the shape is a RectangleShape2D and set its size.
	if not _collision_shape.shape is RectangleShape2D:
		_collision_shape.shape = RectangleShape2D.new()
	_collision_shape.shape.size = Vector2(width, height)

	# Center the collision shape relative to the KillZone's new origin.
	_collision_shape.position.x = width / 2.0
	_collision_shape.position.y = height / 2.0
