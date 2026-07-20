extends RefCounted
class_name UnitSprites

## Loads authored sprites when present; falls back to IconFactory.

const IconFactory = preload("res://scripts/icon_factory.gd")
static var _tex_cache: Dictionary = {}


static func has_art(type_key: String, level: int = 1) -> bool:
	return ResourceLoader.exists(_path(type_key, level))


static func get_texture(type_key: String, tint: Color, level: int = 1) -> Texture2D:
	var lv := clampi(level, 1, 3)
	var path := _path(type_key, lv)
	if ResourceLoader.exists(path):
		var key := path
		if not _tex_cache.has(key):
			_tex_cache[key] = load(path)
		return _tex_cache[key]
	# try lower tier art
	for try_lv in range(lv, 0, -1):
		path = _path(type_key, try_lv)
		if ResourceLoader.exists(path):
			if not _tex_cache.has(path):
				_tex_cache[path] = load(path)
			return _tex_cache[path]
	return IconFactory.get_unit_icon(type_key, tint, lv)


static func _path(type_key: String, level: int) -> String:
	return "res://assets/sprites/units/%s_L%d.png" % [type_key, level]
