# res://World/Killzone.gd
extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# This log will confirm our collision is working.
		DebugManager.log(DebugManager.Category.GAME_STATE, "Player entered KillZone. Emitting player_died signal.")
		EventBus.player_died.emit()
