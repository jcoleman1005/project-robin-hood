# res://Singletons/LevelGenerator.gd
extends Node2D

const CHUNK_DATA_PATH = "res://Levels/Chunks/data"

@export_group("Generator Settings")
@export_range(2, 50) var min_length: int = 5
@export_range(2, 50) var max_length: int = 8
@export_range(0.0, 1.0) var stealth_chunk_chance: float = 0.25
@export_range(0.0, 1.0) var verticality_chance: float = 0.3
@export_range(0.0, 1.0) var reverse_direction_chance: float = 0.2
@export var min_chunks_between_dashes: int = 2
@export var max_recent_chunks: int = 3
@export_range(0, 5) var difficulty_variance: int = 1

@export_group("Scene Dependencies")
@export var kill_zone_scene: PackedScene

@export_group("Layout")
@export var killzone_offset_height: float = 20.0
@export var killzone_horizontal_padding: float = 20.0

@export_group("Debugging")
@export var show_chunk_debug: bool = true
@export var show_debug_text: bool = true

var _chunks_by_category: Dictionary = {
	ChunkData.Category.START: [] as Array[ChunkData],
	ChunkData.Category.END: [] as Array[ChunkData],
	ChunkData.Category.TRAVERSAL: [] as Array[ChunkData],
	ChunkData.Category.STEALTH: [] as Array[ChunkData],
	ChunkData.Category.TRANSITION: [] as Array[ChunkData],
	ChunkData.Category.SECRET: [] as Array[ChunkData],
	ChunkData.Category.VERTICAL_TRAVERSAL: [] as Array[ChunkData],
}
var _level_root: Node2D = null
var _recently_used_chunks: Array[ChunkData] = []
var _chunks_since_last_dash: int = 0

@onready var _debug_font: Font = load("res://UserInterface/8bitlimr.ttf")

func _ready():
	_load_all_chunk_data()
	_validate_settings()


func _process(_delta: float) -> void:
	if show_chunk_debug and is_instance_valid(_level_root):
		queue_redraw()


func _draw() -> void:
	if not (show_chunk_debug and is_instance_valid(_level_root)):
		return

	for i in _level_root.get_child_count():
		var chunk: Node2D = _level_root.get_child(i)
		if not is_instance_valid(chunk) or not chunk.has_meta("chunk_data"): continue

		var entry: Marker2D = chunk.get_node_or_null("entry")
		if is_instance_valid(entry):
			draw_circle(entry.global_position, 8, Color.RED)
			if show_debug_text:
				draw_string(_debug_font, entry.global_position + Vector2(10, 0), "ENTRY", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.RED)

		var exit: Marker2D = chunk.get_node_or_null("exit")
		if is_instance_valid(exit):
			draw_circle(exit.global_position, 8, Color.BLUE)
			if show_debug_text:
				draw_string(_debug_font, exit.global_position + Vector2(10, 0), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.BLUE)
		
		if show_debug_text:
			var chunk_data = chunk.get_meta("chunk_data", null) as ChunkData
			if is_instance_valid(chunk_data):
				var text_pos = chunk.global_position + Vector2(20, 20)
				var info_text = "%s\nCat: %s\nDiff: %d" % [
					chunk.name.get_slice("_", 0),
					ChunkData.Category.keys()[chunk_data.category],
					chunk_data.difficulty
				]
				draw_string(_debug_font, text_pos, info_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


func _validate_settings() -> void:
	if min_length > max_length:
		Loggie.error("LevelGenerator Config Error: min_length (%d) cannot be greater than max_length (%d)." % [min_length, max_length], "proc_gen")
	if _chunks_by_category[ChunkData.Category.START].is_empty():
		Loggie.error("LevelGenerator Config Error: No START chunks have been defined in %s." % CHUNK_DATA_PATH, "proc_gen")
	if _chunks_by_category[ChunkData.Category.END].is_empty():
		Loggie.warn("LevelGenerator Config Warning: No END chunks have been defined in %s." % CHUNK_DATA_PATH, "proc_gen")


func _load_all_chunk_data() -> void:
	var dir = DirAccess.open(CHUNK_DATA_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var chunk_data: ChunkData = load(CHUNK_DATA_PATH.path_join(file_name))
				if is_instance_valid(chunk_data):
					_chunks_by_category[chunk_data.category].append(chunk_data)
			file_name = dir.get_next()
	else:
		Loggie.error("Could not open chunk data path: " + CHUNK_DATA_PATH, "proc_gen")


func generate_level(seed_value: int = -1) -> Node2D:
	if seed_value != -1:
		seed(seed_value)

	if is_instance_valid(_level_root):
		_level_root.queue_free()

	_level_root = Node2D.new()
	_level_root.name = "GeneratedLevel"

	var length = randi_range(min_length, max_length)
	Loggie.info("--- Starting Level Generation (Length: %d, Seed: %s) ---" % [length, seed_value if seed_value != -1 else "Random"], "proc_gen")

	var last_chunk: Dictionary = {"instance": null, "data": null}
	_recently_used_chunks.clear()
	_chunks_since_last_dash = min_chunks_between_dashes

	last_chunk = _add_chunk_of_category(_level_root, ChunkData.Category.START, last_chunk, 0, length)
	
	for i in range(length):
		if not is_instance_valid(last_chunk.instance):
			Loggie.warn("Halting generation, previous chunk was invalid or had no exit.", "proc_gen")
			break

		var category_to_spawn: int
		if randf() < verticality_chance: category_to_spawn = ChunkData.Category.VERTICAL_TRAVERSAL
		elif randf() < reverse_direction_chance: category_to_spawn = ChunkData.Category.TRANSITION
		elif randf() < stealth_chunk_chance: category_to_spawn = ChunkData.Category.STEALTH
		else: category_to_spawn = ChunkData.Category.TRAVERSAL
		
		var next_chunk = _add_chunk_of_category(_level_root, category_to_spawn, last_chunk, i + 1, length)

		if not is_instance_valid(next_chunk.instance) or next_chunk.instance == last_chunk.instance:
			Loggie.info("... Failed to find suitable chunk for category %s. Falling back to TRAVERSAL." % ChunkData.Category.keys()[category_to_spawn], "proc_gen")
			next_chunk = _add_chunk_of_category(_level_root, ChunkData.Category.TRAVERSAL, last_chunk, i + 1, length)
		
		last_chunk = next_chunk

	if is_instance_valid(last_chunk.instance):
		_add_chunk_of_category(_level_root, ChunkData.Category.END, last_chunk, length + 1, length)

	await get_tree().process_frame
	
	var level_extents = _calculate_level_extents(_level_root)
	if not level_extents.is_empty():
		await _add_killzone(_level_root, level_extents)

	Loggie.info("--- Level Generation Complete ---", "proc_gen")
	return _level_root


func _get_target_difficulty(chunk_index: int, total_length: int) -> int:
	var progress: float = clamp(float(chunk_index) / float(total_length), 0.0, 1.0)
	return int(round(1 + progress * 4))


func _select_random_chunk(category: int, required_entry_tag: String, chunk_index: int, total_length: int) -> ChunkData:
	var all_chunks: Array[ChunkData] = _chunks_by_category.get(category, [])
	var compatible_chunks: Array[ChunkData]

	if category == ChunkData.Category.START:
		compatible_chunks = all_chunks
	else:
		compatible_chunks = all_chunks.filter(func(c): return c.entry_tag == required_entry_tag)

	if compatible_chunks.is_empty(): return null
	
	if _chunks_since_last_dash < min_chunks_between_dashes:
		var no_dash_chunks = compatible_chunks.filter(func(c): return not c.requires_dash)
		if not no_dash_chunks.is_empty():
			compatible_chunks = no_dash_chunks
	
	var target_diff = _get_target_difficulty(chunk_index, total_length)
	var difficulty_chunks = compatible_chunks.filter(func(c): return abs(c.difficulty - target_diff) <= difficulty_variance)
	if not difficulty_chunks.is_empty():
		compatible_chunks = difficulty_chunks
	
	var final_chunks = compatible_chunks.filter(func(c): return not _recently_used_chunks.has(c))
	if final_chunks.is_empty():
		final_chunks = compatible_chunks

	if final_chunks.is_empty(): return null
	return final_chunks.pick_random()


func _add_chunk_of_category(parent: Node, category: int, previous_chunk: Dictionary, chunk_index: int, total_length: int) -> Dictionary:
	var required_entry_tag = "none"
	if is_instance_valid(previous_chunk.data):
		required_entry_tag = _get_compatible_tag(previous_chunk.data.exit_tag)
	
	var chosen_chunk_data = _select_random_chunk(category, required_entry_tag, chunk_index, total_length)
	
	if not is_instance_valid(chosen_chunk_data):
		Loggie.warn("No compatible chunk found for category: %s with entry tag: %s" % [ChunkData.Category.keys()[category], required_entry_tag], "proc_gen")
		return {"instance": previous_chunk.instance, "data": previous_chunk.data}
		
	var chunk_instance = chosen_chunk_data.chunk_scene.instantiate()
	chunk_instance.set_meta("chunk_data", chosen_chunk_data)
	
	var log_message = "Placing [%s] chunk: %s | Entry: <%s> | Exit: <%s> | Diff: %d" % [
		ChunkData.Category.keys()[category],
		chosen_chunk_data.chunk_scene.resource_path.get_file(),
		chosen_chunk_data.entry_tag,
		chosen_chunk_data.exit_tag,
		chosen_chunk_data.difficulty
	]
	Loggie.info(log_message, "proc_gen")

	_recently_used_chunks.append(chosen_chunk_data)
	if _recently_used_chunks.size() > max_recent_chunks:
		_recently_used_chunks.pop_front()

	if chosen_chunk_data.requires_dash:
		_chunks_since_last_dash = 0
	else:
		_chunks_since_last_dash += 1
		
	chunk_instance.name = chosen_chunk_data.chunk_scene.resource_path.get_file().get_basename() + "_" + str(chunk_index)
	parent.add_child(chunk_instance)

	if is_instance_valid(previous_chunk.instance):
		var previous_exit_marker = previous_chunk.instance.get_node_or_null("exit")
		if not is_instance_valid(previous_exit_marker): return {"instance": null, "data": null}
		var entry_marker: Marker2D = chunk_instance.get_node_or_null("entry")
		if not is_instance_valid(entry_marker):
			Loggie.error("Chunk " + chosen_chunk_data.chunk_scene.resource_path + " is missing an 'entry' marker.", "proc_gen")
			chunk_instance.queue_free()
			return {"instance": null, "data": null}
		chunk_instance.global_position = previous_exit_marker.global_position - entry_marker.position
	
	if chosen_chunk_data.exit_tag == "none":
		return {"instance": chunk_instance, "data": null}
	
	return {"instance": chunk_instance, "data": chosen_chunk_data}


func _get_compatible_tag(exit_tag: String) -> String:
	if exit_tag.ends_with("_right"): return exit_tag.replace("_right", "_left")
	if exit_tag.ends_with("_left"): return exit_tag.replace("_left", "_right")
	if exit_tag.ends_with("_top"): return exit_tag.replace("_top", "_bottom")
	if exit_tag.ends_with("_bottom"): return exit_tag.replace("_bottom", "_top")
	return "none"


func _calculate_level_extents(level_node: Node2D) -> Dictionary:
	var min_x = INF
	var max_x = -INF
	var lowest_y = -INF
	var has_bounds = false

	for chunk in level_node.get_children():
		if not chunk.has_meta("chunk_data"): continue
		var tilemap = _find_child_by_type(chunk, "TileMapLayer") as TileMapLayer
		if is_instance_valid(tilemap):
			has_bounds = true
			var used_rect = tilemap.get_used_rect()
			var local_pos_start = tilemap.map_to_local(used_rect.position)
			var local_pos_end = tilemap.map_to_local(used_rect.end)
			var global_pos_start = chunk.to_global(local_pos_start)
			var global_pos_end = chunk.to_global(local_pos_end)
			
			min_x = min(min_x, global_pos_start.x)
			max_x = max(max_x, global_pos_end.x)
			lowest_y = max(lowest_y, global_pos_end.y)

	if not has_bounds:
		return {}
		
	return {"min_x": min_x, "max_x": max_x, "lowest_y": lowest_y}


func _add_killzone(level_node: Node2D, extents: Dictionary) -> void:
	if not is_instance_valid(kill_zone_scene): return
	
	var killzone = kill_zone_scene.instantiate()
	if not killzone.has_method("set_extents"):
		Loggie.error("KillZone.tscn's script is missing the 'set_extents' function.", "proc_gen")
		killzone.queue_free()
		return
	
	level_node.add_child(killzone)
	await get_tree().process_frame
	
	var start_x = extents.min_x - killzone_horizontal_padding
	var end_x = extents.max_x + killzone_horizontal_padding
	var y_pos = extents.lowest_y + killzone_offset_height
	
	var start_vector = Vector2(start_x, y_pos)
	var end_vector = Vector2(end_x, y_pos)
	
	killzone.set_extents(start_vector, end_vector)
	Loggie.info("Added KillZone from %s to %s" % [start_vector.round(), end_vector.round()], "proc_gen")


func _find_child_by_type(node: Node, type: String) -> Node:
	for child in node.get_children():
		if child.get_class() == type:
			return child
		var found = _find_child_by_type(child, type)
		if is_instance_valid(found):
			return found
	return null
