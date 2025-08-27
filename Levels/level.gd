extends Node2D

@onready var guard = $Guard
@onready var mission_failed_screen = $MissionFailedScreen
@onready var mission_success_screen = $MissionSuccessScreen
@onready var player = $sm_player # Make sure you have a reference to your player instance.

func _ready():
	# Connect the guard's signal to our failure function.
	if is_instance_valid(guard):
		guard.player_detected.connect(_on_guard_player_detected)
	
	# Connect the player's new signal to our success function.
	## This is the fix! Check if the player node is valid before connecting.
	if is_instance_valid(player):
		player.mission_completed.connect(_on_player_mission_completed)

func _on_guard_player_detected():
	mission_failed_screen.show_failure_screen()

func _on_player_mission_completed(gold_earned, villagers_rescued):
	mission_success_screen.show_success_screen(gold_earned, villagers_rescued)
