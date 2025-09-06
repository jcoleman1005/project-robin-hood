# res://World/MissionBoard.gd
extends StaticBody2D

@onready var _interactable: Interactable = $Interactable

func _ready() -> void:
	_interactable.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	# Announce the user wants to start the mission.
	EventBus.start_mission_requested.emit("village_outskirts")
