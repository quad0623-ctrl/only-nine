extends Control

var center: Vector2 = Vector2.ZERO
var radius: float = 0.0
var color: Color = Color(0.35, 0.92, 1.0, 0.5)
var _t: float = 0.0


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	if radius > 1.0:
		_t += delta
		queue_redraw()


func set_range(p_center: Vector2, p_radius: float, p_color: Color) -> void:
	center = p_center
	radius = p_radius
	color = p_color
	queue_redraw()


func clear_range() -> void:
	radius = 0.0
	queue_redraw()


func _draw() -> void:
	if radius <= 1.0:
		return
	var pulse := 0.5 + 0.5 * sin(_t * 3.2)
	draw_circle(center, radius, Color(color.r, color.g, color.b, 0.07 + 0.04 * pulse))
	draw_circle(center, radius * 0.22, Color(color.r, color.g, color.b, 0.08))
	draw_arc(center, radius, 0.0, TAU, 96, Color(color.r, color.g, color.b, 0.55 + 0.25 * pulse), 2.8, true)
	draw_arc(center, radius * 0.72, 0.0, TAU, 72, Color(1, 1, 1, 0.12), 1.2, true)
	# dashed outer ticks
	var ticks := 24
	for i in ticks:
		var a0 := (float(i) / float(ticks)) * TAU + _t * 0.6
		var a1 := a0 + 0.08
		var p0 := center + Vector2(cos(a0), sin(a0)) * radius
		var p1 := center + Vector2(cos(a1), sin(a1)) * (radius + 5.0)
		draw_line(p0, p1, Color(color.r, color.g, color.b, 0.45), 2.0, true)
