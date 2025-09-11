extends Area2D

signal checkpoint_activated(position: Vector2)

@export var respawn_position: Vector2

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		respawn_position = global_position
		checkpoint_activated.emit(respawn_position)
	GameManager.set_checkpoint(respawn_position)
