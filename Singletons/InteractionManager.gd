# InteractionManager.gd
extends Node
# --- NEW SIGNALS ---
signal prompt_shown(message)
signal prompt_hidden
signal message_shown(message, speaker_position)
signal message_hidden

var current_interactables = []
var player = null

func _ready():
	# This tells the manager to keep running at all times,
	# both when the game is paused and unpaused.
	process_mode = Node.PROCESS_MODE_ALWAYS

	# We wait one frame to make sure the entire scene is loaded before finding the player.
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _process(_delta):
	# This check happens every frame, regardless of the input chain.
	if Input.is_action_just_pressed("interact"):
		# If the game is paused, it means we're in a dialogue.
		if get_tree().paused:
			# So, hide the message and unpause.
			hide_message()
			get_viewport().set_input_as_handled()
		# Otherwise, if the game is NOT paused...
		else:
			# ...find the closest NPC and tell it to interact.
			var closest_npc = find_closest_interactable()
			if is_instance_valid(closest_npc):
				closest_npc.interact()
				# Consume the input event so the player doesn't also jump.
				get_viewport().set_input_as_handled()

func show_message(message: String, speaker_position: Vector2):
	# When a message is shown, we should hide the prompt.
	emit_signal("prompt_hidden")
	emit_signal("message_shown", message, speaker_position)
	get_tree().paused = true

func hide_message():
	emit_signal("message_hidden")
	get_tree().paused = false

# --- MODIFIED FUNCTIONS for NPCs to call ---

# This function now accepts the prompt message.
func register_interactable(obj, prompt_message: String):
	if not obj in current_interactables:
		current_interactables.append(obj)
	# Tell any listening UI to show the prompt.
	emit_signal("prompt_shown", prompt_message)

func unregister_interactable(obj):
	if obj in current_interactables:
		current_interactables.erase(obj)
	# Tell any listening UI to hide the prompt.
	emit_signal("prompt_hidden")

# A helper function to find the closest NPC to the player.
func find_closest_interactable():
	if current_interactables.is_empty() or not is_instance_valid(player):
		return null
	
	var closest_obj = null
	var closest_dist_sq = INF
	
	for obj in current_interactables:
		var dist_sq = player.global_position.distance_squared_to(obj.global_position)
		if dist_sq < closest_dist_sq:
			closest_dist_sq = dist_sq
			closest_obj = obj
			
	return closest_obj
