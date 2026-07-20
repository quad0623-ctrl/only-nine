extends RefCounted
class_name IconFactory

## Top-down craft silhouettes by unit type + level (1 small / 2 armed / 3 complete)

const SIZE := 64
static var _cache: Dictionary = {}


static func get_monster_icon(type_key: String, tint: Color = Color.WHITE, is_boss: bool = false) -> Texture2D:
	var cache_key := "M_%s_%s_%s" % [type_key, tint.to_html(false), is_boss]
	if _cache.has(cache_key):
		return _cache[cache_key]
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_monster(img, type_key, tint, is_boss)
	var tex := ImageTexture.create_from_image(img)
	_cache[cache_key] = tex
	return tex


static func get_unit_icon(type_key: String, tint: Color = Color.WHITE, level: int = 1) -> Texture2D:
	var lv := clampi(level, 1, 3)
	var cache_key := "%s_L%d_%s" % [type_key, lv, tint.to_html(false)]
	if _cache.has(cache_key):
		return _cache[cache_key]
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_craft(img, type_key, tint, lv)
	var tex := ImageTexture.create_from_image(img)
	_cache[cache_key] = tex
	return tex


static func _draw_monster(img: Image, type_key: String, color: Color, is_boss: bool) -> void:
	var c := Color(color.r, color.g, color.b, 1.0)
	var mid := Vector2(SIZE * 0.5, SIZE * 0.5)
	var scale := 1.15 if is_boss else 0.88
	var dark := Color(c.r * 0.45, c.g * 0.45, c.b * 0.45, 1.0)
	match type_key:
		"GOBLIN": # Spore — bio-drone core + limbs
			_fill_circle(img, mid, 11.0 * scale, c)
			_fill_ring(img, mid, 18.0 * scale, 15.0 * scale, c)
			for i in 6:
				var a := float(i) * TAU / 6.0
				_fill_circle(img, mid + Vector2(cos(a), sin(a)) * 16.0 * scale, 3.2 * scale, c)
			_fill_circle(img, mid, 4.0 * scale, dark)
		"ORC": # Assault — wedge gunship
			_fill_polygon(img, _scaled_poly([
				Vector2(mid.x, 10), Vector2(SIZE - 12, SIZE - 14), Vector2(mid.x, SIZE - 18), Vector2(12, SIZE - 14)
			], mid, scale), c)
			_fill_rect(img, _scaled_rect(Rect2i(int(mid.x) - 4, 20, 8, 18), mid, scale), dark)
			_fill_circle(img, mid + Vector2(0, -2) * scale, 3.5 * scale, Color(1, 0.9, 0.4, 1))
		"WOLF": # Skimmer — arrow interceptor
			_fill_polygon(img, _scaled_poly([
				Vector2(SIZE - 8, mid.y), Vector2(14, 18), Vector2(22, mid.y), Vector2(14, SIZE - 18)
			], mid, scale), c)
			_fill_circle(img, mid + Vector2(-8, 0) * scale, 3.0 * scale, Color(0.5, 0.95, 1.0, 1))
		"GOLEM": # Bastion — hex siege core
			_fill_hex(img, mid, 22.0 * scale, c)
			_fill_hex(img, mid, 13.0 * scale, dark)
			_fill_circle(img, mid, 5.0 * scale, Color(0.85, 0.7, 1.0, 1))
		"DRAGON": # Wyrm — ring gunship
			_fill_ring(img, mid, 22.0 * scale, 14.0 * scale, c)
			_fill_polygon(img, _scaled_poly([
				Vector2(mid.x, 8), Vector2(mid.x + 8, 28), Vector2(mid.x - 8, 28)
			], mid, scale), c)
			_fill_circle(img, mid, 5.0 * scale, dark)
		"DEMON": # Reaper — radial void core
			_fill_star(img, mid, 26.0 * scale, 8.0 * scale, 8, c)
			_fill_circle(img, mid, 7.0 * scale, dark)
			_fill_circle(img, mid, 3.5 * scale, Color(1, 0.95, 0.95, 1))
		_:
			_fill_circle(img, mid, 16.0 * scale, c)


static func _draw_craft(img: Image, type_key: String, color: Color, level: int) -> void:
	var c := Color(color.r, color.g, color.b, 1.0)
	var mid := Vector2(SIZE * 0.5, SIZE * 0.5)
	# Hull scale: small → medium → large
	var hull := 0.62 if level == 1 else (0.82 if level == 2 else 1.0)
	var accent := Color(c.r * 0.55, c.g * 0.55, c.b * 0.55, 1.0)

	match type_key:
		"PRISM":
			_fill_polygon(img, _scaled_poly([
				Vector2(mid.x, 10), Vector2(SIZE - 12, mid.y), Vector2(mid.x, SIZE - 10), Vector2(12, mid.y)
			], mid, hull), c)
			if level >= 2:
				_fill_circle(img, mid, 5.0 * hull + 2.0, accent)
			if level >= 3:
				_fill_ring(img, mid, 26.0 * hull, 22.0 * hull, c)
		"HALO":
			_fill_ring(img, mid, 24.0 * hull, 16.0 * hull, c)
			if level >= 2:
				_fill_ring(img, mid, 16.0 * hull, 11.0 * hull, accent)
			if level >= 3:
				_fill_circle(img, mid, 7.0, c)
		"AURORA":
			_fill_star(img, mid, 26.0 * hull, 11.0 * hull, 6, c)
			if level >= 2:
				_fill_circle(img, mid, 6.0, accent)
			if level >= 3:
				_fill_star(img, mid, 14.0, 6.0, 6, c)
		"DART":
			_fill_polygon(img, _scaled_poly([
				Vector2(SIZE - 8, mid.y), Vector2(14, 16), Vector2(20, mid.y), Vector2(14, SIZE - 16)
			], mid, hull), c)
			if level >= 2:
				_fill_rect(img, _scaled_rect(Rect2i(8, int(mid.y) - 3, 18, 6), mid, hull), accent)
			if level >= 3:
				_fill_rect(img, Rect2i(4, int(mid.y) - 10, 8, 20), c)
		"SEEKER":
			_fill_polygon(img, _scaled_poly([
				Vector2(mid.x, 10), Vector2(SIZE - 12, mid.y), Vector2(mid.x, SIZE - 10), Vector2(12, mid.y)
			], mid, hull), c)
			_fill_circle(img, mid, 6.0 * hull + 2.0, accent)
			if level >= 2:
				_fill_circle(img, mid + Vector2(10, 0) * hull, 3.0, c)
			if level >= 3:
				_fill_ring(img, mid, 28.0 * hull, 24.0 * hull, c)
		"BARRAGE":
			var w := int(6 + 2 * level)
			var gap := 10
			var start_x := int(mid.x - gap - w * 0.5)
			for i in 3:
				var x0 := start_x + i * gap
				var h := int((SIZE - 28) * hull) + (4 if level >= 3 else 0)
				var y0 := int(mid.y - h * 0.5)
				_fill_rect(img, Rect2i(x0, y0, w, h), c if i != 1 else accent)
			if level >= 2:
				_fill_rect(img, Rect2i(int(mid.x) - 14, int(mid.y) - 2, 28, 4), c)
		"SPIKE":
			_fill_polygon(img, _scaled_poly([
				Vector2(mid.x, 8), Vector2(SIZE - 12, SIZE - 12), Vector2(12, SIZE - 12)
			], mid, hull), c)
			if level >= 2:
				_fill_rect(img, Rect2i(int(mid.x) - 3, int(mid.y) - 4, 6, int(18 * hull)), accent)
			if level >= 3:
				_fill_polygon(img, [
					Vector2(mid.x, 4), Vector2(mid.x + 8, 18), Vector2(mid.x - 8, 18)
				], c)
		"APEX":
			_fill_hex(img, mid, 22.0 * hull, c)
			if level >= 2:
				_fill_hex(img, mid, 12.0 * hull, accent)
			if level >= 3:
				_fill_rect(img, Rect2i(int(mid.x) - 3, 6, 6, SIZE - 12), c)
		"RAIL":
			var thick := 6 + level * 2
			_fill_rect(img, Rect2i(8, int(mid.y) - thick / 2, SIZE - 16, thick), c)
			if level >= 2:
				_fill_rect(img, Rect2i(SIZE - 20, int(mid.y) - 12, 10, 24), accent)
			if level >= 3:
				_fill_rect(img, Rect2i(6, int(mid.y) - 14, 12, 28), c)
				_fill_rect(img, Rect2i(SIZE - 16, int(mid.y) - 16, 10, 32), c)
		_:
			_fill_circle(img, mid, 14.0 * hull, c)


static func _scaled_poly(points: Array, center: Vector2, scale: float) -> Array:
	var out: Array = []
	for p in points:
		out.append(center + (p - center) * scale)
	return out


static func _scaled_rect(rect: Rect2i, center: Vector2, scale: float) -> Rect2i:
	var c := Vector2(rect.position) + Vector2(rect.size) * 0.5
	var nc := center + (c - center) * scale
	var ns := Vector2(rect.size) * scale
	return Rect2i(int(nc.x - ns.x * 0.5), int(nc.y - ns.y * 0.5), maxi(1, int(ns.x)), maxi(1, int(ns.y)))


static func _fill_rect(img: Image, rect: Rect2i, color: Color) -> void:
	for y in range(maxi(0, rect.position.y), mini(SIZE, rect.position.y + rect.size.y)):
		for x in range(maxi(0, rect.position.x), mini(SIZE, rect.position.x + rect.size.x)):
			img.set_pixel(x, y, color)


static func _fill_circle(img: Image, center: Vector2, radius: float, color: Color) -> void:
	var r2 := radius * radius
	var min_x := maxi(0, int(center.x - radius))
	var max_x := mini(SIZE - 1, int(center.x + radius))
	var min_y := maxi(0, int(center.y - radius))
	var max_y := mini(SIZE - 1, int(center.y + radius))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if Vector2(x + 0.5, y + 0.5).distance_squared_to(center) <= r2:
				img.set_pixel(x, y, color)


static func _fill_ring(img: Image, center: Vector2, outer_r: float, inner_r: float, color: Color) -> void:
	var o2 := outer_r * outer_r
	var i2 := inner_r * inner_r
	var min_x := maxi(0, int(center.x - outer_r))
	var max_x := mini(SIZE - 1, int(center.x + outer_r))
	var min_y := maxi(0, int(center.y - outer_r))
	var max_y := mini(SIZE - 1, int(center.y + outer_r))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var d := Vector2(x + 0.5, y + 0.5).distance_squared_to(center)
			if d <= o2 and d >= i2:
				img.set_pixel(x, y, color)


static func _fill_polygon(img: Image, points: Array, color: Color) -> void:
	var min_x := SIZE
	var max_x := 0
	var min_y := SIZE
	var max_y := 0
	for p in points:
		min_x = mini(min_x, int(p.x))
		max_x = maxi(max_x, int(p.x))
		min_y = mini(min_y, int(p.y))
		max_y = maxi(max_y, int(p.y))
	min_x = maxi(0, min_x)
	max_x = mini(SIZE - 1, max_x)
	min_y = maxi(0, min_y)
	max_y = mini(SIZE - 1, max_y)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if _point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				img.set_pixel(x, y, color)


static func _point_in_polygon(point: Vector2, polygon: Array) -> bool:
	var inside := false
	var j := polygon.size() - 1
	for i in polygon.size():
		var pi: Vector2 = polygon[i]
		var pj: Vector2 = polygon[j]
		if ((pi.y > point.y) != (pj.y > point.y)) and \
				(point.x < (pj.x - pi.x) * (point.y - pi.y) / (pj.y - pi.y + 0.0001) + pi.x):
			inside = not inside
		j = i
	return inside


static func _fill_star(img: Image, center: Vector2, outer_r: float, inner_r: float, points: int, color: Color) -> void:
	var poly: Array = []
	for i in points * 2:
		var angle := -PI * 0.5 + float(i) * PI / float(points)
		var r := outer_r if i % 2 == 0 else inner_r
		poly.append(center + Vector2(cos(angle), sin(angle)) * r)
	_fill_polygon(img, poly, color)


static func _fill_hex(img: Image, center: Vector2, radius: float, color: Color) -> void:
	var poly: Array = []
	for i in 6:
		var angle := float(i) * TAU / 6.0 - PI * 0.5
		poly.append(center + Vector2(cos(angle), sin(angle)) * radius)
	_fill_polygon(img, poly, color)
