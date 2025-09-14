# res://Interactables/Campfire/Campfire.gd
extends StaticBody2D

@onready var _interactable: Interactable = $Interactable

func _ready() -> void:
	assert(is_instance_valid(_interactable), "Campfire scene must have an Interactable child node.")
	_interactable.interacted.connect(_on_interacted)

	if OS.is_debug_build():
		_verify_prompt_cost()

func _on_interacted() -> void:
	GameManager.try_upgrade_hideout()

func _verify_prompt_cost() -> void:
	if not is_instance_valid(GameManager.hideout_progression_data):
		return

	var current_level = GameManager.hideout_level
	var max_level = GameManager.hideout_progression_data.max_level

	if current_level < max_level:
		var real_cost: int = GameManager.hideout_progression_data.upgrade_costs[current_level - 1]
		var prompt_text: String = _interactable.prompt_message

		var regex = RegEx.new()
		regex.compile("(\\d+)")
		var result = regex.search(prompt_text)

		if result:
			var text_cost = int(result.get_string())
			if text_cost != real_cost:
				# MODIFIED: Print a clear error and then pause the game.
				printerr("BREAKPOINT: Campfire UI cost (%d) does not match the actual upgrade cost (%d). Update the prompt text or the variable in GameManager.tscn." % [text_cost, real_cost])
				
		else:
			# MODIFIED: Print a clear error and then pause the game.
			printerr("BREAKPOINT: Campfire prompt message does not contain a number to verify against the upgrade cost.")
			
