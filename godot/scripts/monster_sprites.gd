extends RefCounted
class_name MonsterSprites

## Loads authored monster sprites when present; falls back to IconFactory.

const IconFactory = preload("res://scripts/icon_factory.gd")
static var _tex_cache: Dictionary = {}


static func clear_cache() -> void:
	_tex_cache.clear()


static func has_art(type_key: String) -> bool:
	return ResourceLoader.exists(_path(type_key))


static func get_texture(type_key: String, tint: Color, is_boss: bool = false) -> Texture2D:
	var path := _path(type_key)
	if ResourceLoader.exists(path):
		if not _tex_cache.has(path):
			_tex_cache[path] = load(path)
		return _tex_cache[path]
	return IconFactory.get_monster_icon(type_key, tint, is_boss)


static func _path(type_key: String) -> String:
	return "res://assets/sprites/monsters/%s.png" % type_key
