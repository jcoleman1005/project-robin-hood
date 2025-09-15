# res://Levels/Chunks/ChunkData.gd
class_name ChunkData
extends Resource

## The category of this chunk, used by the generator for path building.
enum Category { START, END, TRAVERSAL, STEALTH, TRANSITION, SECRET, VERTICAL_TRAVERSAL }

@export_group("Core Properties")
@export var chunk_scene: PackedScene ## The .tscn file for this level chunk.
@export var category: Category = Category.TRAVERSAL ## The type of chunk this is.
@export var difficulty: int = 1 ## A general difficulty rating (e.g., 1-5).

@export_group("Connection Points")
## Tag describing the entry point, chosen from a predefined list.
@export_enum("none", "floor_left", "floor_right", "wall_left", "wall_right", "ceiling_left", "ceiling_right") var entry_tag: String = "floor_left"
## Tag describing the exit point, chosen from a predefined list.
@export_enum("none", "floor_left", "floor_right", "wall_left", "wall_right", "ceiling_left", "ceiling_right") var exit_tag: String = "floor_right"

@export_group("Requirements")
## Flags for the generator to know which abilities are needed to clear this chunk.
@export var requires_double_jump: bool = false
@export var requires_dash: bool = false
@export var requires_wall_kick: bool = false
