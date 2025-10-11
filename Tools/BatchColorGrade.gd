@tool
extends Node
class_name BatchColorGrade

## Utility: Apply simple sunset grade to a folder of PNGs, saving to an output dir.
## Uses Image to process pixels. Non-destructive: reads from input, writes to output.

@export var input_dir: String = "res://assets/Backgrounds/Background/"
@export var output_dir: String = "res://assets/Backgrounds/Sunset/"
@export_range(0.0, 1.0) var strength: float = 0.85
@export var vignette_strength: float = 0.15

func _ready() -> void:
	# Run automatically when placed in a scene (editor + game due to @tool)
	process_folder()

func process_folder() -> void:
	var dir := DirAccess.open(input_dir)
	if dir == null:
		push_error("Cannot open input dir: %s" % input_dir)
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	var files := dir.get_files()
	for f in files:
		if not f.to_lower().ends_with(".png"):
			continue
		var in_path := input_dir + f
		var out_path := output_dir + f
		if not _process_image(in_path, out_path):
			push_error("Failed processing %s" % in_path)
	print("BatchColorGrade complete. Output at %s" % output_dir)

func _process_image(in_path: String, out_path: String) -> bool:
	var img := Image.new()
	var err := img.load(in_path)
	if err != OK:
		return false
	img.convert(Image.FORMAT_RGBA8)
	img.lock()
	var w := img.get_width()
	var h := img.get_height()
	# Precompute vignette center/radius
	var center := Vector2(w, h) * 0.5
	var max_dist := center.length()
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			c = _sunset_grade(c)
			# subtle vignette
			var dist := center.distance_to(Vector2(x, y)) / max_dist
			var vig := clamp(remap(dist, 0.6, 1.0, 0.0, vignette_strength), 0.0, vignette_strength)
			c.r = clamp(c.r * (1.0 - vig), 0.0, 1.0)
			c.g = clamp(c.g * (1.0 - vig), 0.0, 1.0)
			c.b = clamp(c.b * (1.0 - vig), 0.0, 1.0)
			img.set_pixel(x, y, c)
	img.unlock()
	return img.save_png(out_path) == OK

func _sunset_grade(c: Color) -> Color:
	# Warm push: raise reds/oranges, lower blues slightly, add magenta in mid/highs
	var r := c.r
	var g := c.g
	var b := c.b
	# Luma for subtle contrast
	var luma := r * 0.299 + g * 0.587 + b * 0.114
	# Contrast and slight brightness down
	var contrast := 1.08
	var brightness := -0.03
	var nr := clamp((r - 0.5) * contrast + 0.5 + brightness, 0.0, 1.0)
	var ng := clamp((g - 0.5) * contrast + 0.5 + brightness, 0.0, 1.0)
	var nb := clamp((b - 0.5) * contrast + 0.5 + brightness, 0.0, 1.0)
	# Warm tone map
	nr = clamp(lerp(nr, nr + 0.12, strength), 0.0, 1.0)
	ng = clamp(lerp(ng, ng + 0.04, strength), 0.0, 1.0)
	nb = clamp(lerp(nb, nb - 0.12, strength), 0.0, 1.0)
	# Add a touch of magenta in highlights
	var highlight := smoothstep(0.55, 0.95, luma)
	nr = clamp(nr + 0.06 * highlight * strength, 0.0, 1.0)
	nb = clamp(nb + 0.03 * highlight * strength, 0.0, 1.0)
	return Color(nr, ng, nb, c.a)
