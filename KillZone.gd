# res://World/Killzone.gd
extends Area2D

func _ready() -> void:
	# Connect the signal for when a body enters this area.
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	# Check if the body that entered is the player.
	if body.is_in_group("player"):
		# Announce that the player has died.
		EventBus.player_died.emit()
