extends RefCounted
class_name FxSprites

## Attack VFX textures — per-faction variants + cyan fallback

static var _cache: Dictionary = {}


static func projectile(faction: String = "") -> Texture2D:
	return _faction_tex("projectile", faction)


static func splash(faction: String = "") -> Texture2D:
	return _faction_tex("splash", faction)


static func muzzle(faction: String = "") -> Texture2D:
	return _faction_tex("muzzle", faction)


static func _faction_tex(kind: String, faction: String) -> Texture2D:
	var key := faction.to_upper()
	var suffix := "cyan"
	match key:
		"LUMINA":
			suffix = "lumina"
		"VECTRA":
			suffix = "vectra"
		"FERRUM":
			suffix = "ferrum"
	var path := "res://assets/sprites/fx/%s_%s.png" % [kind, suffix]
	var tex := _load(path)
	if tex == null:
		tex = _load("res://assets/sprites/fx/%s_cyan.png" % kind)
	return tex


static func _load(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	if ResourceLoader.exists(path):
		_cache[path] = load(path)
		return _cache[path]
	return null


static func faction_modulate(faction_color: Color, alpha: float = 1.0) -> Color:
	# Brighter additive-friendly tint (less muddy than old mix)
	return Color(
		clampf(0.55 + faction_color.r * 0.65, 0.0, 1.6),
		clampf(0.55 + faction_color.g * 0.65, 0.0, 1.6),
		clampf(0.55 + faction_color.b * 0.65, 0.0, 1.6),
		alpha
	)
