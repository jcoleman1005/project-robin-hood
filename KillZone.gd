# res://World/Killzone.gd
extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# This log will confirm our collision is working.
		DebugManager.log(DebugManager.Category.GAME_STATE, "Player entered KillZone. Emitting player_died signal.")
		EventBus.player_died.emit()

func respawn_player(player: Node2D) -> void:
	if GameManager.current_checkpoint != Vector2.ZERO:
		player.global_position = GameManager.current_checkpoint
	else:
		# fallback to level start
		player.global_position = get_node("/root/SceneManager").get_level_start()
	
	# Reset stats
	player.reset_stats()
