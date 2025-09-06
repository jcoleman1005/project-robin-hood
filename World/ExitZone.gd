# res://World/exit_zone.gd
extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# Check the GameManager's state to see if we can exit.
		if GameManager.mission_objective_complete:
			# Announce that the objective is complete. The GameManager will
			# hear this and trigger the mission success sequence.
			EventBus.mission_objective_completed.emit()
			
			$CollisionShape2D.set_deferred("disabled", true)
