extends Node

## Persistent settings via user://settings.cfg

const PATH := "user://settings.cfg"

var bgm_volume: float = 1.0
var sfx_volume: float = 1.0
var tutorial_done: bool = false


func _ready() -> void:
	load_settings()
	# Apply after Music creates buses
	call_deferred("_apply_audio")


func _apply_audio() -> void:
	if Music:
		Music.set_bgm_volume(bgm_volume)
		Music.set_sfx_volume(sfx_volume)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	bgm_volume = float(cfg.get_value("audio", "bgm", 1.0))
	sfx_volume = float(cfg.get_value("audio", "sfx", 1.0))
	tutorial_done = bool(cfg.get_value("meta", "tutorial_done", false))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "bgm", bgm_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("meta", "tutorial_done", tutorial_done)
	cfg.save(PATH)


func set_bgm(v: float) -> void:
	bgm_volume = clampf(v, 0.0, 1.0)
	Music.set_bgm_volume(bgm_volume)
	save_settings()


func set_sfx(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	Music.set_sfx_volume(sfx_volume)
	save_settings()


func mark_tutorial_done() -> void:
	tutorial_done = true
	save_settings()
