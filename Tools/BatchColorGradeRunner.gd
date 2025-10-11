@tool
extends EditorScript

# Run this script from the Script Editor (press the Run button) to batch-generate
# sunset-tinted versions of images in input_dir, saving to output_dir.

const INPUT_DIR := "res://assets/Backgrounds/Background/"
const OUTPUT_DIR := "res://assets/Backgrounds/Sunset/"
const STRENGTH := 0.85
const VIGNETTE_STRENGTH := 0.15

func _run() -> void:
	print("BatchColorGradeRunner: Processing ", INPUT_DIR)
	if _process_folder(INPUT_DIR, OUTPUT_DIR):
		print("Done. Output at ", OUTPUT_DIR)
		# Refresh the filesystem so new images appear immediately
		var fs := get_editor_interface().get_resource_filesystem()
		if fs:
			fs.scan()
	else:
		push_error("BatchColorGradeRunner: Failed processing folder")

func _process_folder(input_dir: String, output_dir: String) -> bool:
	var dir := DirAccess.open(input_dir)
	if dir == null:
		push_error("Cannot open input dir: %s" % input_dir)
		return false
	DirAccess.make_dir_recursive_absolute(output_dir)
	var ok := true
	for f in dir.get_files():
		if not f.to_lower().ends_with(".png"):
			continue
		var in_path := input_dir.path_join(f)
		var out_path := output_dir.path_join(f)
		if not _process_image(in_path, out_path):
			ok = false
			push_error("Failed processing %s" % in_path)
	return ok

func _process_image(in_path: String, out_path: String) -> bool:
	var img := Image.new()
	var err := img.load(in_path)
	if err != OK:
		return false
	img.convert(Image.FORMAT_RGBA8)
	img.lock()
	var w := img.get_width()
	var h := img.get_height()
	var center := Vector2(w, h) * 0.5
	var max_dist := center.length()
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			c = _sunset_grade(c)
			var dist := center.distance_to(Vector2(x, y)) / max_dist
			var vig := clamp(remap(dist, 0.6, 1.0, 0.0, VIGNETTE_STRENGTH), 0.0, VIGNETTE_STRENGTH)
			c.r = clamp(c.r * (1.0 - vig), 0.0, 1.0)
			c.g = clamp(c.g * (1.0 - vig), 0.0, 1.0)
			c.b = clamp(c.b * (1.0 - vig), 0.0, 1.0)
			img.set_pixel(x, y, c)
	img.unlock()
	return img.save_png(out_path) == OK

func _sunset_grade(c: Color) -> Color:
	var r := c.r
	var g := c.g
	var b := c.b
	var luma := r * 0.299 + g * 0.587 + b * 0.114
	var contrast := 1.08
	var brightness := -0.03
	var nr := clamp((r - 0.5) * contrast + 0.5 + brightness, 0.0, 1.0)
	var ng := clamp((g - 0.5) * contrast + 0.5 + brightness, 0.0, 1.0)
	var nb := clamp((b - 0.5) * contrast + 0.5 + brightness, 0.0, 1.0)
	nr = clamp(lerp(nr, nr + 0.12, STRENGTH), 0.0, 1.0)
	ng = clamp(lerp(ng, ng + 0.04, STRENGTH), 0.0, 1.0)
	nb = clamp(lerp(nb, nb - 0.12, STRENGTH), 0.0, 1.0)
	var highlight := smoothstep(0.55, 0.95, luma)
	nr = clamp(nr + 0.06 * highlight * STRENGTH, 0.0, 1.0)
	nb = clamp(nb + 0.03 * highlight * STRENGTH, 0.0, 1.0)
	return Color(nr, ng, nb, c.a)
