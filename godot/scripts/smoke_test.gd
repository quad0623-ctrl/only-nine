extends Node

## Headless smoke: uses project autoloads (run via --scene)

const IconFactory = preload("res://scripts/icon_factory.gd")
const MonsterSprites = preload("res://scripts/monster_sprites.gd")


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	GameState.start_game()
	if not GameState.enabled:
		push_error("FAIL: game did not enable")
		get_tree().quit(1)
		return

	GameState.build_unit(1, 1, "PRISM")
	if GameState.units.is_empty():
		push_error("FAIL: build_unit failed")
		get_tree().quit(1)
		return
	if GameState.gold != 40:
		push_error("FAIL: expected gold 40 after Prism, got %d" % GameState.gold)
		get_tree().quit(1)
		return

	# Level cap 3 + tier icons path
	GameState.gold = 999
	GameState.upgrade_unit(1, 1)
	GameState.upgrade_unit(1, 1)
	if int(GameState.units[0]["level"]) != 3:
		push_error("FAIL: expected level 3, got %d" % int(GameState.units[0]["level"]))
		get_tree().quit(1)
		return
	GameState.upgrade_unit(1, 1)
	if int(GameState.units[0]["level"]) != 3:
		push_error("FAIL: level exceeded max")
		get_tree().quit(1)
		return
	var icon := IconFactory.get_unit_icon("PRISM", Color.CYAN, 3)
	if icon == null:
		push_error("FAIL: tier icon null")
		get_tree().quit(1)
		return
	for mtype in ["GOBLIN", "ORC", "WOLF", "GOLEM", "DRAGON", "DEMON"]:
		if not MonsterSprites.has_art(mtype):
			push_error("FAIL: missing monster art %s" % mtype)
			get_tree().quit(1)
			return
		if MonsterSprites.get_texture(mtype, Color.WHITE) == null:
			push_error("FAIL: monster texture null %s" % mtype)
			get_tree().quit(1)
			return

	var total := GameData.total_duration()
	if total < 180.0 or total > 280.0:
		push_error("FAIL: unexpected timeline duration %.1f" % total)
		get_tree().quit(1)
		return

	for i in 120:
		await get_tree().process_frame

	var phase := GameState.get_current_phase()
	print("OK smoke: gold=%d units=%d level=%d monsters=%d phase=%s wave=%s time=%.1f total=%.1f" % [
		GameState.gold,
		GameState.units.size(),
		int(GameState.units[0]["level"]),
		GameState.monsters.size(),
		str(phase.get("type", "")),
		str(phase.get("wave", "")),
		GameState.time_remaining,
		total,
	])

	# Verify export presets file exists
	var presets := FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	if presets == null:
		push_error("FAIL: export_presets.cfg missing")
		get_tree().quit(1)
		return
	var text := presets.get_as_text()
	if not ("Windows Steam" in text and "Android" in text):
		push_error("FAIL: export presets incomplete")
		get_tree().quit(1)
		return

	# Settings persistence smoke
	Settings.set_bgm(0.4)
	Settings.set_sfx(0.6)
	Settings.load_settings()
	if absf(Settings.bgm_volume - 0.4) > 0.001 or absf(Settings.sfx_volume - 0.6) > 0.001:
		push_error("FAIL: settings persist mismatch")
		get_tree().quit(1)
		return
	Settings.set_bgm(1.0)
	Settings.set_sfx(1.0)

	get_tree().quit(0)
