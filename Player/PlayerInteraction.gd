# res://Player/PlayerInteraction.gd
extends Area2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _on_area_entered(area: Area2D) -> void:
	if area is Interactable:
		DebugManager.print_interaction_log("Entered area of: " + area.get_parent().name)
		InteractionManager.register_interactable(area)


func _on_area_exited(area: Area2D) -> void:
	if area is Interactable:
		DebugManager.print_interaction_log("Exited area of: " + area.get_parent().name)
		InteractionManager.unregister_interactable(area)
