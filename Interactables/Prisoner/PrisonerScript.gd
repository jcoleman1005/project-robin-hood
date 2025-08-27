extends StaticBody2D

# A signal to announce when the villager has been rescued.
signal villager_rescued

@export var prompt_message: String = "Press A to free the prisoner"

# A flag to prevent the villager from being rescued more than once.
var is_rescued: bool = false
var player_in_area = null

@onready var interaction_area = $InteractionArea
@onready var sprite = $AnimatedSprite2D

func _ready():
	# Connect the signals from the Area2D to our script's functions.
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

# This is the public function that our player controller will call.
func interact():
	if is_rescued:
		return
	
	is_rescued = true
	
	# For the MVP, we can just make the villager disappear after being rescued.
	hide() 
	
	# Announce that the villager has been rescued.
	# Instead of emitting a signal, we'll directly tell the player the mission is over.
	if is_instance_valid(player_in_area):
		player_in_area.add_villager() # First, add the villager.
		player_in_area.complete_mission() # Then, complete the mission.
	
	if is_instance_valid(player_in_area):
		player_in_area.interaction_controller.unregister_interactable(self)


# This function is called when a body (like the player) enters our interaction area.
func _on_body_entered(body):
	if body.is_in_group("player") and not is_rescued:
		player_in_area = body
		## The prisoner's only job is to tell the controller it's here.
		InteractionManager.register_interactable(self, prompt_message)

# This function is called when a body leaves our interaction area.
func _on_body_exited(body):
	if body.is_in_group("player"):
		## The prisoner's only job is to tell the controller it's gone.
		InteractionManager.register_interactable(self, prompt_message)
		
		if body == player_in_area:
			player_in_area = null
