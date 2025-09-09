# res://Enemies/Guard/States/caught_state.gd
extends GuardState

# This state does nothing. Its only purpose is to stop the guard
# from running the patrol logic after the player is caught.
func enter() -> void:
	pass

func process_physics(_delta: float) -> void:
	pass
