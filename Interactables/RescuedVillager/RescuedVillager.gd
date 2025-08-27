# RescuedVillager.gd
extends StaticBody2D

# This variable may not be used by the InteractionManager, but we can leave it for now.
@export var prompt_message: String = "Press A to talk"
@export_multiline var dialogue_message: String = "Thank you for rescuing me! We can use the gold you find to train more archers."

var player_in_area = null

@onready var interaction_area = $InteractionArea
@onready var collision_shape = $CollisionShape2D

func _ready():
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

	if GameManager.villagers <= 0:
		hide()
		collision_shape.set_deferred("disabled", true)

func interact():
	# This part is correct! It tells the InteractionManager what to say.
	InteractionManager.show_message(dialogue_message, global_position)

# --- CORRECTED FUNCTIONS ---

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_area = body
		# FIX #1: Register with the global InteractionManager singleton.
		InteractionManager.register_interactable(self)

func _on_body_exited(body):
	if body.is_in_group("player"):
		# FIX #2: Unregister from the global InteractionManager singleton.
		InteractionManager.unregister_interactable(self)
		if body == player_in_area:
			player_in_area = null
