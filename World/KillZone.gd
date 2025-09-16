# res://World/Killzone.gd
extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		Loggie.info("Player entered KillZone. Emitting player_died signal.", "game_state")
		EventBus.player_died.emit()
