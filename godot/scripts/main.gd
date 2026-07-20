extends Control

const UiStyle = preload("res://scripts/ui_style.gd")
const UnitSprites = preload("res://scripts/unit_sprites.gd")

@onready var title_overlay: Control = $TitleOverlay
@onready var title_panel: PanelContainer = $TitleOverlay/Center/Panel
@onready var title_label: Label = $TitleOverlay/Center/Panel/Margin/VBox/Title
@onready var accent_line: ColorRect = $TitleOverlay/Center/Panel/Margin/VBox/AccentLine
@onready var start_button: Button = $TitleOverlay/Center/Panel/Margin/VBox/StartButton
@onready var game_root: Control = $GameRoot
@onready var game_over_overlay: Control = $GameOverOverlay
@onready var game_over_panel: PanelContainer = $GameOverOverlay/Center/Panel
@onready var game_over_label: Label = $GameOverOverlay/Center/Panel/Margin/VBox/ResultLabel
@onready var game_over_stats: Label = $GameOverOverlay/Center/Panel/Margin/VBox/StatsLabel
@onready var wave_banner: PanelContainer = $WaveBanner
@onready var wave_banner_label: Label = $WaveBanner/BannerLabel
@onready var pause_overlay: Control = $PauseOverlay
@onready var pause_panel: PanelContainer = $PauseOverlay/Center/Panel
@onready var bgm_slider: HSlider = $PauseOverlay/Center/Panel/Margin/VBox/BgmRow/BgmSlider
@onready var sfx_slider: HSlider = $PauseOverlay/Center/Panel/Margin/VBox/SfxRow/SfxSlider
@onready var board: Control = $GameRoot/BoardCenter/BoardWrap/Board
@onready var hud: Control = $GameRoot/HUD
@onready var build_menu: Control = $GameRoot/BuildShell/BuildMenu
@onready var drag_ghost: TextureRect = $DragGhost
@onready var flash: ColorRect = $Flash
@onready var vignette: ColorRect = $Vignette
@onready var scanlines: ColorRect = $Scanlines
@onready var dimmer: ColorRect = $Dimmer
@onready var tutorial_overlay: Control = $TutorialOverlay
@onready var tutorial_panel: PanelContainer = $TutorialOverlay/Center/Panel
@onready var logo_mark: TextureRect = $TitleOverlay/Center/Panel/Margin/VBox/LogoMark

var _title_time: float = 0.0


func _ready() -> void:
	theme = UiStyle.make_theme()
	_apply_panel_styles()
	_style_title_fonts()
	title_overlay.visible = true
	game_root.visible = false
	game_over_overlay.visible = false
	pause_overlay.visible = false
	tutorial_overlay.visible = false
	drag_ghost.visible = false
	flash.visible = false
	_setup_vignette()
	# Scanlines replaced by Atmosphere shader overlay in scene
	if scanlines:
		scanlines.visible = false
	_play_title_intro()
	_apply_mobile_layout()
	_style_build_shell_art()

	GameState.state_changed.connect(_on_state_changed)
	GameState.game_over_changed.connect(_on_game_over)
	GameState.drag_changed.connect(_on_drag_changed)
	GameState.phase_changed.connect(_on_phase_changed)
	GameState.monster_died_at.connect(_on_monster_died_flash)
	GameState.boss_spawned.connect(_on_boss_spawned)
	bgm_slider.value = Settings.bgm_volume
	sfx_slider.value = Settings.sfx_volume
	bgm_slider.value_changed.connect(func(v: float) -> void: Settings.set_bgm(v))
	sfx_slider.value_changed.connect(func(v: float) -> void: Settings.set_sfx(v))
	_ensure_pause_title_button()
	_ensure_game_over_title_button()
	set_process(true)
	set_process_input(true)


func _ensure_pause_title_button() -> void:
	var vbox: VBoxContainer = $PauseOverlay/Center/Panel/Margin/VBox
	if vbox == null or vbox.has_node("TitleButton"):
		return
	var btn := Button.new()
	btn.name = "TitleButton"
	btn.text = "타이틀로"
	btn.custom_minimum_size = Vector2(220, 44)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(_on_title_pressed)
	# Insert after Resume
	var resume: Node = vbox.get_node_or_null("ResumeButton")
	if resume:
		vbox.add_child(btn)
		vbox.move_child(btn, resume.get_index() + 1)
	else:
		vbox.add_child(btn)


func _ensure_game_over_title_button() -> void:
	var vbox: VBoxContainer = $GameOverOverlay/Center/Panel/Margin/VBox
	if vbox == null or vbox.has_node("TitleButton"):
		return
	var btn := Button.new()
	btn.name = "TitleButton"
	btn.text = "타이틀로"
	btn.custom_minimum_size = Vector2(220, 44)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(_on_title_pressed)
	var restart: Node = vbox.get_node_or_null("RestartButton")
	if restart:
		vbox.add_child(btn)
		vbox.move_child(btn, restart.get_index() + 1)
	else:
		vbox.add_child(btn)


func _apply_mobile_layout() -> void:
	if not (OS.has_feature("mobile") or OS.has_feature("android") or DisplayServer.is_touchscreen_available()):
		return
	# Larger drag ghost / touch-friendly ghost
	drag_ghost.custom_minimum_size = Vector2(96, 96)
	drag_ghost.size = Vector2(96, 96)


func _apply_panel_styles() -> void:
	title_panel.add_theme_stylebox_override("panel", UiStyle.glass_panel(16, UiStyle.CYAN_SOFT))
	pause_panel.add_theme_stylebox_override("panel", UiStyle.glass_panel(14, UiStyle.CYAN_DIM))
	game_over_panel.add_theme_stylebox_override("panel", UiStyle.glass_panel(14, UiStyle.CYAN_DIM))
	tutorial_panel.add_theme_stylebox_override("panel", UiStyle.glass_panel(14, UiStyle.CYAN_SOFT))
	wave_banner.add_theme_stylebox_override("panel", UiStyle.accent_panel(UiStyle.CYAN, 14))
	var panel_frame: Panel = $GameRoot/BuildShell/PanelFrame
	if panel_frame:
		panel_frame.add_theme_stylebox_override("panel", UiStyle.glass_panel(12, UiStyle.CYAN_DIM))
	start_button.add_theme_stylebox_override("normal", UiStyle.btn_box(
		Color(0.06, 0.22, 0.28, 0.98), UiStyle.CYAN, 2, 10
	))
	start_button.add_theme_stylebox_override("hover", UiStyle.btn_box(
		Color(0.1, 0.32, 0.38, 0.98), Color(0.55, 0.98, 1.0), 2, 10
	))


func _style_title_fonts() -> void:
	UiStyle.apply_label_font(title_label, 64, true, true)
	UiStyle.apply_label_font(wave_banner_label, 34, true, true)
	UiStyle.apply_label_font(game_over_label, 42, true, true)
	for path in [
		"TitleOverlay/Center/Panel/Margin/VBox/Eyebrow",
		"TitleOverlay/Center/Panel/Margin/VBox/Subtitle",
		"TitleOverlay/Center/Panel/Margin/VBox/HowTo",
	]:
		var l: Label = get_node_or_null(path)
		if l:
			UiStyle.apply_label_font(l, l.get_theme_font_size("font_size"), false)
	if logo_mark:
		logo_mark.pivot_offset = logo_mark.custom_minimum_size * 0.5


func _style_build_shell_art() -> void:
	var art: TextureRect = get_node_or_null("GameRoot/BuildShell/PanelArt") as TextureRect
	if art:
		art.modulate = Color(0.88, 0.96, 1.0, 0.78)


func _setup_vignette() -> void:
	# Soft radial darkening via GradientTexture2D
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.55)])
	grad.offsets = PackedFloat32Array([0.45, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 64
	tex.height = 64
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.02)
	vignette.color = Color.WHITE
	# ColorRect can't take texture easily — use TextureRect swap via modulate layer
	# Keep ColorRect as ambient dark corners using low alpha black; TextureRect sibling added in code
	var tr := TextureRect.new()
	tr.name = "VignetteTex"
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.modulate = Color(1, 1, 1, 0.85)
	vignette.add_child(tr)
	vignette.color = Color(0, 0, 0, 0)


func _setup_scanlines() -> void:
	var img := Image.create(2, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.set_pixel(0, 0, Color(0, 0, 0, 0.55))
	img.set_pixel(1, 0, Color(0, 0, 0, 0.55))
	var tex := ImageTexture.create_from_image(img)
	var tr := TextureRect.new()
	tr.name = "ScanTex"
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_TILE
	tr.modulate = Color(1, 1, 1, 0.22)
	scanlines.add_child(tr)
	scanlines.color = Color(0, 0, 0, 0)


func _play_title_intro() -> void:
	await get_tree().process_frame
	title_panel.modulate = Color(1, 1, 1, 0)
	title_panel.scale = Vector2(0.94, 0.94)
	title_panel.pivot_offset = title_panel.size * 0.5
	if logo_mark:
		logo_mark.modulate.a = 0.0
		logo_mark.scale = Vector2(0.7, 0.7)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(title_panel, "modulate:a", 1.0, 0.55)
	tw.tween_property(title_panel, "scale", Vector2.ONE, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(dimmer, "color:a", 0.42, 0.8)
	if logo_mark:
		tw.tween_property(logo_mark, "modulate:a", 1.0, 0.7)
		tw.tween_property(logo_mark, "scale", Vector2.ONE, 0.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_title_time += delta
	if title_overlay.visible:
		accent_line.modulate.a = 0.55 + 0.45 * sin(_title_time * 2.4)
		var glow: ColorRect = $TitleOverlay/TitleGlow
		if glow:
			glow.modulate.a = 0.7 + 0.3 * sin(_title_time * 1.3)
		if logo_mark:
			var s := 1.0 + 0.03 * sin(_title_time * 2.0)
			logo_mark.scale = Vector2(s, s)
			logo_mark.modulate = Color(0.7 + 0.15 * sin(_title_time), 1.0, 1.1, 1.0)
	if GameState.paused or GameState.drag_unit_type == "":
		return
	_update_drag_ghost(_pointer_pos())


func _pointer_pos() -> Vector2:
	return get_global_mouse_position()


func _update_drag_ghost(mp: Vector2) -> void:
	drag_ghost.global_position = mp - drag_ghost.size * 0.5
	if board.has_method("set_drag_hover_from_global"):
		board.set_drag_hover_from_global(mp)


func _try_drop_at(mp: Vector2) -> void:
	if board.has_method("try_drop_at_global"):
		board.try_drop_at_global(mp)
	else:
		GameState.clear_unit_drag()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and game_root.visible and not game_over_overlay.visible and not tutorial_overlay.visible:
		GameState.toggle_pause()
		get_viewport().set_input_as_handled()
		return

	# Touch drag tracking
	if event is InputEventScreenDrag and GameState.drag_unit_type != "" and not GameState.paused:
		_update_drag_ghost(event.position)
		get_viewport().set_input_as_handled()
		return

	if GameState.paused or GameState.drag_unit_type == "":
		return

	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_drop_at((event as InputEventMouseButton).global_position)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenTouch and not event.pressed:
		_try_drop_at((event as InputEventScreenTouch).position)
		get_viewport().set_input_as_handled()
		return


func _on_phase_changed(phase_type: String, wave: int) -> void:
	if not game_root.visible:
		return
	if phase_type == "COMBAT":
		_show_banner("WAVE %d" % wave, UiStyle.CYAN)
	else:
		_show_banner("REST — REARM", Color(0.45, 0.95, 0.7))


func _on_boss_spawned(type_key: String, is_final: bool) -> void:
	if not game_root.visible:
		return
	var nm := GameData.monster_display_name(type_key, true)
	var en := GameData.monster_display_name(type_key, false).to_upper()
	if is_final:
		_show_banner("FINAL — %s / %s" % [nm, en], UiStyle.DANGER)
	else:
		_show_banner("BOSS — %s" % nm, Color(0.85, 0.45, 1.0))


func _show_banner(text: String, color: Color) -> void:
	wave_banner_label.text = text
	wave_banner_label.add_theme_color_override("font_color", color)
	wave_banner.add_theme_stylebox_override("panel", UiStyle.accent_panel(color, 14))
	wave_banner.visible = true
	wave_banner.modulate = Color(1, 1, 1, 0)
	wave_banner.scale = Vector2(0.88, 0.88)
	wave_banner.pivot_offset = wave_banner.size * 0.5
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(wave_banner, "modulate:a", 1.0, 0.22)
	tw.tween_property(wave_banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(1.35)
	tw.chain().tween_property(wave_banner, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(func() -> void: wave_banner.visible = false)


func _on_monster_died_flash(_x: float, _y: float, is_boss: bool) -> void:
	if not is_boss:
		return
	flash.visible = true
	flash.color = Color(1, 0.85, 0.55, 0.28)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.35)
	tw.tween_callback(func() -> void: flash.visible = false)


func _on_drag_changed() -> void:
	if GameState.drag_unit_type == "":
		drag_ghost.visible = false
		drag_ghost.texture = null
		if board.has_method("clear_drag_hover"):
			board.clear_drag_hover()
		return
	var def: Dictionary = GameData.get_unit(GameState.drag_unit_type)
	var tint: Color = GameData.FACTIONS[str(def["faction"])]["color"]
	drag_ghost.texture = UnitSprites.get_texture(GameState.drag_unit_type, tint, 1)
	drag_ghost.visible = true
	drag_ghost.scale = Vector2(1.15, 1.15)


func _on_start_pressed() -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(title_overlay, "modulate:a", 0.0, 0.35)
	tw.tween_property(dimmer, "color:a", 0.28, 0.45)
	tw.chain().tween_callback(func() -> void:
		title_overlay.visible = false
		title_overlay.modulate = Color.WHITE
		game_root.visible = true
		game_root.modulate = Color(1, 1, 1, 0)
		game_over_overlay.visible = false
		GameState.start_game()
		if not Settings.tutorial_done:
			_show_tutorial()
	)
	tw.chain().tween_property(game_root, "modulate:a", 1.0, 0.4)


func _show_tutorial() -> void:
	GameState.paused = true
	pause_overlay.visible = false
	tutorial_overlay.visible = true
	tutorial_overlay.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(tutorial_overlay, "modulate:a", 1.0, 0.25)


func _on_tutorial_done() -> void:
	Settings.mark_tutorial_done()
	tutorial_overlay.visible = false
	GameState.paused = false
	pause_overlay.visible = false
	if hud.has_method("refresh"):
		hud.refresh()


func _on_restart_pressed() -> void:
	game_over_overlay.visible = false
	pause_overlay.visible = false
	GameState.restart_game()


func _on_resume_pressed() -> void:
	if GameState.paused:
		GameState.toggle_pause()


func _on_title_pressed() -> void:
	GameState.return_to_title()
	game_root.visible = false
	game_over_overlay.visible = false
	pause_overlay.visible = false
	tutorial_overlay.visible = false
	drag_ghost.visible = false
	title_overlay.visible = true
	title_overlay.modulate = Color.WHITE
	dimmer.color.a = 0.42
	if Music.has_method("stop_bgm"):
		Music.stop_bgm()


func _on_state_changed() -> void:
	pause_overlay.visible = (
		GameState.paused
		and game_root.visible
		and not game_over_overlay.visible
		and not tutorial_overlay.visible
	)
	if hud.has_method("refresh"):
		hud.refresh()
	if board.has_method("refresh"):
		board.refresh()
	if build_menu.has_method("refresh"):
		build_menu.refresh()


func _on_game_over(result: String) -> void:
	game_over_overlay.visible = true
	pause_overlay.visible = false
	game_over_stats.text = "처치 %d  ·  보스 %d  ·  잔여 골드 %d" % [GameState.kills, GameState.boss_kills, GameState.gold]
	game_over_panel.modulate = Color(1, 1, 1, 0)
	game_over_panel.scale = Vector2(0.92, 0.92)
	game_over_panel.pivot_offset = game_over_panel.size * 0.5
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(game_over_panel, "modulate:a", 1.0, 0.35)
	tw.tween_property(game_over_panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK)
	if result == "win":
		game_over_label.text = "작전 성공"
		game_over_label.add_theme_color_override("font_color", Color("#4ade80"))
	else:
		game_over_label.text = "작전 실패"
		game_over_label.add_theme_color_override("font_color", UiStyle.DANGER)
