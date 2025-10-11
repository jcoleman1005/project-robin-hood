@tool
extends EditorScript

const OUT_PATH: String = "res://assets/Backgrounds/Sunset/Sunset_PixelBG.png"
const TARGET_W: int = 1920
const TARGET_H: int = 1080
const LOW_W: int = 320
const LOW_H: int = 180

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/Backgrounds/Sunset")
	var img: Image = Image.create(LOW_W, LOW_H, false, Image.FORMAT_RGBA8)
	img.lock()
	_paint_gradient(img)
	_paint_sun(img, Vector2(LOW_W / 2.0, int(LOW_H * 0.62)), 22)
	_paint_clouds(img, 7, 123456)
	_paint_hills(img, 0.80, Color(0.24, 0.12, 0.34, 1.0), 8.0, 0.018, 0.042)
	_paint_hills(img, 0.88, Color(0.34, 0.16, 0.46, 1.0), 12.0, 0.026, 0.053)
	img.unlock()
	img.resize(TARGET_W, TARGET_H, Image.INTERPOLATE_NEAREST)
	var ok: bool = img.save_png(OUT_PATH) == OK
	if ok:
		print("Saved pixel sunset to ", OUT_PATH)
		var fs: EditorFileSystem = get_editor_interface().get_resource_filesystem()
		if fs:
			fs.scan()
	else:
		push_error("Failed to save pixel sunset at " + OUT_PATH)

func _paint_gradient(img: Image) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var top: Color = Color(0.10, 0.06, 0.15)
	var horizon: Color = Color(0.98, 0.50, 0.20)
	for y: int in range(h):
		var t: float = float(y) / float(h - 1)
		# Ease towards the horizon color around 60-65% height
		var k: float = clamp(smoothstep(0.10, 0.65, t), 0.0, 1.0)
		var row: Color = top.lerp(horizon, k)
		for x: int in range(w):
			img.set_pixel(x, y, row)

func _paint_sun(img: Image, c: Vector2, r: int) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var sun_col: Color = Color(1.0, 0.80, 0.40)
	for y: int in range(max(0, int(c.y) - r - 2), min(h, int(c.y) + r + 2)):
		for x: int in range(max(0, int(c.x) - r - 2), min(w, int(c.x) + r + 2)):
			var d: float = c.distance_to(Vector2(x, y))
			if d <= float(r):
				var t: float = clamp(1.0 - (d / float(r)), 0.0, 1.0)
				var base: Color = img.get_pixel(x, y)
				img.set_pixel(x, y, base.lerp(sun_col, t * 0.95))

func _paint_hills(img: Image, base_h: float, col: Color, amp: float, f1: float, f2: float) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var base_y: int = int(h * base_h)
	for x: int in range(w):
		var y_curve: int = base_y + int(sin(float(x) * f1) * amp + sin(float(x) * f2) * amp * 0.5)
		for y: int in range(max(0, y_curve), h):
			img.set_pixel(x, y, col)

func _paint_clouds(img: Image, count: int, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var w: int = img.get_width()
	var h: int = img.get_height()
	for i: int in range(count):
		var cx: int = rng.randi_range(12, w - 12)
		var cy: int = rng.randi_range(int(h * 0.18), int(h * 0.52))
		var cw: int = rng.randi_range(10, 22)
		var ch: int = rng.randi_range(3, 7)
		var col: Color = Color(1.0, 0.78, 0.62)
		for py: int in range(-ch, ch + 1):
			for px: int in range(-cw, cw + 1):
				var nx: int = cx + px
				var ny: int = cy + py
				if nx < 0 or ny < 0 or nx >= w or ny >= h:
					continue
				var el: float = 1.0 - clamp(Vector2(float(px) / float(cw), float(py) / float(ch)).length(), 0.0, 1.0)
				if el <= 0.0:
					continue
				var base: Color = img.get_pixel(nx, ny)
				img.set_pixel(nx, ny, base.lerp(col, el * 0.5))
