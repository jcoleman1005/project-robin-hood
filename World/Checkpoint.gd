# res://World/Checkpoint.gd
extends Area2D

signal checkpoint_activated(position: Vector2)

@export var respawn_point: NodePath

@onready var _respawn_marker: Marker2D = get_node_or_null(respawn_point) as Marker2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		assert(is_instance_valid(_respawn_marker), "RespawnPoint NodePath must be set on Checkpoint in the editor.")
		var respawn_pos: Vector2 = _respawn_marker.global_position
		
		checkpoint_activated.emit(respawn_pos)
		GameManager.set_checkpoint(respawn_pos)
		GameManager.save_checkpoint_data()
		Loggie.info("Checkpoint activated. Respawn at: " + str(respawn_pos), "checkpoint")
