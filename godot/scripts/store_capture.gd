extends Node

## Auto-capture Play Store screenshots from the real main scene.
## Run: Godot --path godot --scene res://scenes/store_capture.tscn
## Writes legal/play-store/screenshot_01.png … _04.png then quits.

const OUT_REL := "../legal/play-store"
const CAPTURE_SIZE := Vector2i(1920, 1080)

var _main: Control
var _out_dir: String


func _ready() -> void:
	Settings.tutorial_done = true
	Settings.save_settings()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	get_window().size = Vector2i(1280, 720)

	var godot_root := ProjectSettings.globalize_path("res://").rstrip("/\\")
	_out_dir = godot_root.path_join(OUT_REL).simplify_path()
	DirAccess.make_dir_recursive_absolute(_out_dir)
	print("store_capture: output dir = ", _out_dir)

	var packed: PackedScene = load("res://scenes/main.tscn")
	_main = packed.instantiate()
	add_child(_main)
	await get_tree().process_frame
	await get_tree().process_frame

	# Shot 1: title screen
	await _wait_frames(20)
	await _save_shot("screenshot_01.png")

	# Enter gameplay (mirror start button without tween wait)
	_enter_game()
	GameState.gold = 200
	GameState.build_unit(1, 1, "PRISM")
	GameState.build_unit(2, 1, "HALO")
	GameState.build_unit(1, 2, "DART")
	GameState.time_scale = 4.0

	# Shot 2: early combat with units
	await _wait_until(func() -> bool: return GameState.monsters.size() >= 2, 12.0)
	await _wait_frames(30)
	await _save_shot("screenshot_02.png")

	# Shot 3: denser board + more units
	GameState.gold = 500
	GameState.build_unit(3, 1, "SPIKE")
	GameState.build_unit(2, 2, "RAIL")
	GameState.build_unit(3, 2, "SEEKER")
	GameState.upgrade_unit(1, 1)
	GameState.upgrade_unit(1, 1)
	await _wait_until(func() -> bool: return GameState.monsters.size() >= 4, 15.0)
	await _wait_frames(45)
	await _save_shot("screenshot_03.png")

	# Shot 4: fast-forward toward mid-game / boss window
	GameState.time_scale = 12.0
	await _wait_until(func() -> bool:
		var phase := GameState.get_current_phase()
		return int(phase.get("wave", 0)) >= 2 and (
			GameState.monsters.size() >= 3 or bool(phase.get("type", "") == "COMBAT")
		)
	, 45.0)
	# Prefer a frame with a boss if present
	var deadline := Time.get_ticks_msec() + 20000
	while Time.get_ticks_msec() < deadline:
		var has_boss := false
		for m in GameState.monsters:
			if bool(m.get("is_boss", false)):
				has_boss = true
				break
		if has_boss or GameState.monsters.size() >= 6:
			break
		await get_tree().process_frame
	GameState.time_scale = 1.0
	await _wait_frames(20)
	await _save_shot("screenshot_04.png")

	print("store_capture: done")
	get_tree().quit(0)


func _enter_game() -> void:
	var title: Control = _main.get_node_or_null("TitleOverlay")
	var game_root: Control = _main.get_node_or_null("GameRoot")
	var tutorial: Control = _main.get_node_or_null("TutorialOverlay")
	var game_over: Control = _main.get_node_or_null("GameOverOverlay")
	var pause: Control = _main.get_node_or_null("PauseOverlay")
	if title:
		title.visible = false
	if tutorial:
		tutorial.visible = false
	if game_over:
		game_over.visible = false
	if pause:
		pause.visible = false
	if game_root:
		game_root.visible = true
		game_root.modulate = Color.WHITE
	GameState.start_game()
	GameState.paused = false


func _wait_frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _wait_until(pred: Callable, timeout_sec: float) -> void:
	var start := Time.get_ticks_msec()
	var limit_ms := int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() - start < limit_ms:
		if pred.call():
			return
		await get_tree().process_frame


func _save_shot(filename: String) -> void:
	# Let a full frame render with current state
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var tex := get_viewport().get_texture()
	if tex == null:
		push_error("store_capture: viewport texture null for %s" % filename)
		return
	var img: Image = tex.get_image()
	if img == null:
		push_error("store_capture: image null for %s" % filename)
		return
	if img.get_width() != CAPTURE_SIZE.x or img.get_height() != CAPTURE_SIZE.y:
		img.resize(CAPTURE_SIZE.x, CAPTURE_SIZE.y, Image.INTERPOLATE_LANCZOS)
	var path := _out_dir.path_join(filename)
	var err := img.save_png(path)
	if err != OK:
		push_error("store_capture: save failed %s err=%d" % [path, err])
	else:
		print("store_capture: wrote ", path, " ", img.get_width(), "x", img.get_height())
