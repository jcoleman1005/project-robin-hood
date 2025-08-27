extends StaticBody2D

# A signal to announce when the chest has been opened.
signal opened

@export var prompt_message: String = "Press A to open"

# A flag to prevent the chest from being opened more than once.
var is_open: bool = false
var player_in_area = null

# A reference to the Area2D node that detects the player.
@onready var interaction_area = $InteractionArea
# A reference to the sprite for the chest (so we can change its appearance).
@onready var sprite = $Sprite2D

func _ready():
	# Connect the signals from the Area2D to our script's functions.
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

# This is the public function that our player controller will call.
func interact():
	# If the chest is already open, do nothing.
	if is_open:
		return
	
	# Mark the chest as open and update its appearance.
	is_open = true
	
	if is_instance_valid(sprite):
		sprite.modulate = Color.GRAY
	
	# Announce that the chest has been opened.
	emit_signal("opened")
	
	if is_instance_valid(player_in_area):
		player_in_area.interaction_controller.unregister_interactable(self)


# This function is called when a body (like the player) enters our interaction area.
func _on_body_entered(body):
	# First, check if the body is the player and if the chest isn't already open.
	if body.is_in_group("player") and not is_open:
		player_in_area = body
		## The chest's only job is to tell the controller it's here.
		InteractionManager.register_interactable(self, prompt_message)

# This function is called when a body leaves our interaction area.
func _on_body_exited(body):
	# Check if the body is the player.
	if body.is_in_group("player"):
		## The chest's only job is to tell the controller it's gone.
		InteractionManager.unregister_interactable(self)
		
		if body == player_in_area:
			player_in_area = null
