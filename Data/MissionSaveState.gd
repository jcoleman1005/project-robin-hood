# res://data/MissionSaveState.gd
class_name MissionSaveState
extends Resource

## A dictionary where keys are unique object_ids and values are their state.
@export var collected_objects: Dictionary = {}
## The global position of the last activated checkpoint.
@export var checkpoint_position: Vector2 = Vector2.ZERO
