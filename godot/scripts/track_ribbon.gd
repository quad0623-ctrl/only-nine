extends Control

## Glowing energy ribbon along the monster track path

const UiStyle = preload("res://scripts/ui_style.gd")

var _pulse: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1
	set_process(true)


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func _draw() -> void:
	var path: Array = GameData.TRACK_PATH
	if path.is_empty():
		return
	var step := 102.0 # CELL + GAP default; board may override via set_meta
	if has_meta("cell_step"):
		step = float(get_meta("cell_step"))
	var cell := 96.0
	if has_meta("cell"):
		cell = float(get_meta("cell"))

	var pts: PackedVector2Array = PackedVector2Array()
	for p in path:
		pts.append(Vector2(float(p.x) * step + cell * 0.5, float(p.y) * step + cell * 0.5))
	# close loop
	pts.append(pts[0])

	var t := 0.55 + 0.45 * sin(_pulse * 2.4)
	var glow := Color(0.25, 0.85, 1.0, 0.12 + 0.08 * t)
	var core := Color(0.55, 0.98, 1.0, 0.35 + 0.25 * t)
	var hot := Color(0.85, 1.0, 1.0, 0.55 + 0.3 * t)

	_draw_polyline_soft(pts, glow, 22.0)
	_draw_polyline_soft(pts, core, 9.0)
	_draw_polyline_soft(pts, hot, 3.0)

	# traveling ticks
	var n := pts.size() - 1
	for i in n:
		var u := fposmod(_pulse * 0.55 + float(i) * 0.07, 1.0)
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var p: Vector2 = a.lerp(b, u)
		draw_circle(p, 3.2 + 1.2 * t, Color(0.7, 1.0, 1.0, 0.55 * t))


func _draw_polyline_soft(pts: PackedVector2Array, color: Color, width: float) -> void:
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1], color, width, true)
