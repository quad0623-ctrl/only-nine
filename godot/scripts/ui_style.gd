extends RefCounted
class_name UiStyle

## Commercial cyber UI — deep navy glass, sharp cyan accents
## Fonts (OFL, commercial OK): Pretendard + Orbitron (+ Oxanium fallback)

const CYAN := Color(0.35, 0.92, 1.0, 1.0)
const CYAN_SOFT := Color(0.25, 0.78, 0.88, 0.75)
const CYAN_DIM := Color(0.18, 0.55, 0.65, 0.55)
const GOLD := Color(1.0, 0.84, 0.35, 1.0)
const DANGER := Color(1.0, 0.38, 0.42, 1.0)
const NAVY := Color(0.035, 0.055, 0.09, 0.92)
const NAVY_HOVER := Color(0.06, 0.1, 0.16, 0.95)
const NAVY_PRESSED := Color(0.09, 0.16, 0.22, 0.98)
const GLASS := Color(0.04, 0.07, 0.12, 0.72)
const TEXT := Color(0.92, 0.96, 0.98, 1.0)
const TEXT_MUTED := Color(0.52, 0.68, 0.76, 1.0)

const FONT_REG := "res://assets/fonts/Pretendard-Regular.ttf"
const FONT_MED := "res://assets/fonts/Pretendard-Medium.ttf"
const FONT_SEMI := "res://assets/fonts/Pretendard-SemiBold.ttf"
const FONT_BOLD := "res://assets/fonts/Pretendard-Bold.ttf"
const FONT_XBOLD := "res://assets/fonts/Pretendard-ExtraBold.ttf"
const FONT_ORBITRON := "res://assets/fonts/Orbitron-Variable.ttf"
const FONT_OXANIUM := "res://assets/fonts/Oxanium-Variable.ttf"

static var _font_reg: Font
static var _font_med: Font
static var _font_bold: Font
static var _font_display: Font


static func ensure_fonts() -> void:
	if _font_reg != null:
		return

	_font_reg = _load_res_font(FONT_REG)
	_font_med = _load_res_font(FONT_MED)
	if _font_med == null:
		_font_med = _font_reg

	_font_bold = _load_res_font(FONT_BOLD)
	if _font_bold == null:
		_font_bold = _load_res_font(FONT_SEMI)
	if _font_bold == null:
		_font_bold = _font_reg

	# Display: cyber Latin (Orbitron/Oxanium) → Hangul via Pretendard ExtraBold fallback
	var latin := _load_res_font(FONT_ORBITRON)
	if latin == null:
		latin = _load_res_font(FONT_OXANIUM)
	var hangul_display := _load_res_font(FONT_XBOLD)
	if hangul_display == null:
		hangul_display = _font_bold
	if latin != null and hangul_display != null:
		latin.fallbacks = [hangul_display]
		_font_display = latin
	else:
		_font_display = hangul_display if hangul_display else _font_bold


static func _load_res_font(path: String) -> Font:
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		push_warning("UiStyle: missing font %s" % path)
		return null
	var f := FontFile.new()
	var err := f.load_dynamic_font(path)
	if err != OK:
		push_warning("UiStyle: failed to load font %s (%s)" % [path, error_string(err)])
		return null
	return f


static func make_theme() -> Theme:
	ensure_fonts()
	var t := Theme.new()
	if _font_med:
		t.default_font = _font_med
		t.default_font_size = 15

	var normal := btn_box(NAVY, CYAN_DIM, 1, 8)
	var hover := btn_box(NAVY_HOVER, CYAN, 1, 8)
	var pressed := btn_box(NAVY_PRESSED, CYAN, 2, 8)
	var disabled := btn_box(Color(0.04, 0.05, 0.07, 0.65), Color(0.25, 0.3, 0.35, 0.35), 1, 8)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box: StyleBoxFlat = normal if state == "normal" else (hover if state == "hover" or state == "focus" else (pressed if state == "pressed" else disabled))
		t.set_stylebox(state, "Button", box)

	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color(1, 1, 1))
	t.set_color("font_pressed_color", "Button", CYAN)
	t.set_color("font_disabled_color", "Button", Color(0.4, 0.45, 0.5))
	if _font_bold:
		t.set_font("font", "Button", _font_bold)
	t.set_font_size("font_size", "Button", 15)

	t.set_color("font_color", "Label", TEXT)
	if _font_med:
		t.set_font("font", "Label", _font_med)
	t.set_font_size("font_size", "Label", 15)
	t.set_constant("h_separation", "HBoxContainer", 14)
	t.set_constant("v_separation", "VBoxContainer", 10)

	var panel := glass_panel(6, CYAN_DIM)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)

	# Sliders
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = CYAN
	grabber.set_corner_radius_all(8)
	grabber.set_content_margin_all(6)
	var grabber_hl := grabber.duplicate()
	grabber_hl.bg_color = Color(0.55, 0.98, 1.0)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.08, 0.12, 0.18, 0.9)
	track.set_corner_radius_all(4)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", StyleBoxEmpty.new())
	t.set_stylebox("grabber_area_highlight", "HSlider", StyleBoxEmpty.new())
	t.set_stylebox("grabber", "HSlider", grabber)
	t.set_stylebox("grabber_highlight", "HSlider", grabber_hl)

	return t


static func glass_panel(radius: int = 10, border: Color = CYAN_DIM) -> StyleBoxFlat:
	var panel := StyleBoxFlat.new()
	panel.bg_color = GLASS
	panel.border_color = border
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(radius)
	panel.shadow_color = Color(0, 0, 0, 0.45)
	panel.shadow_size = 10
	panel.shadow_offset = Vector2(0, 4)
	panel.content_margin_left = 16
	panel.content_margin_right = 16
	panel.content_margin_top = 14
	panel.content_margin_bottom = 14
	return panel


static func accent_panel(accent: Color, radius: int = 10) -> StyleBoxFlat:
	var panel := glass_panel(radius, Color(accent.r, accent.g, accent.b, 0.7))
	panel.bg_color = Color(0.025, 0.04, 0.08, 0.88)
	panel.border_width_left = 1
	panel.border_width_top = 1
	panel.border_width_right = 1
	panel.border_width_bottom = 3
	panel.border_color = Color(accent.r, accent.g, accent.b, 0.75)
	panel.shadow_color = Color(accent.r, accent.g, accent.b, 0.18)
	panel.shadow_size = 14
	return panel


static func btn_box(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.shadow_color = Color(border.r, border.g, border.b, 0.22)
	box.shadow_size = 6
	box.shadow_offset = Vector2(0, 2)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box


static func _load_ui_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func cell_track(_pulse: float = 0.0) -> StyleBox:
	var tex := _load_ui_tex("res://assets/ui/track_tile.png")
	if tex:
		var box := StyleBoxTexture.new()
		box.texture = tex
		box.set_content_margin_all(4)
		return box
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color(0.04, 0.09, 0.14, 0.45)
	flat.border_color = Color(0.2, 0.65, 0.78, 0.45)
	flat.set_border_width_all(2)
	flat.set_corner_radius_all(6)
	return flat


static func track_modulate(pulse: float = 0.0) -> Color:
	var glow := lerpf(0.4, 1.0, pulse)
	return Color(0.65 + 0.25 * glow, 0.9 + 0.1 * glow, 1.0, 0.4 + 0.45 * glow)


static func cell_pad(highlight: String = "") -> StyleBox:
	## Let arena plate show through; use crisp borders + soft fills
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(10)
	match highlight:
		"drop":
			box.bg_color = Color(0.12, 0.42, 0.48, 0.55)
			box.border_color = CYAN
			box.set_border_width_all(2)
			box.shadow_color = Color(0.25, 0.95, 1.0, 0.4)
			box.shadow_size = 10
		"upgrade":
			box.bg_color = Color(0.22, 0.1, 0.32, 0.58)
			box.border_color = Color(0.78, 0.5, 1.0, 0.95)
			box.set_border_width_all(2)
			box.shadow_color = Color(0.7, 0.4, 1.0, 0.28)
			box.shadow_size = 8
		"sell":
			box.bg_color = Color(0.32, 0.08, 0.1, 0.58)
			box.border_color = DANGER
			box.set_border_width_all(2)
		"occupied":
			box.bg_color = Color(0.04, 0.08, 0.12, 0.28)
			box.border_color = Color(0.35, 0.55, 0.65, 0.45)
			box.set_border_width_all(1)
		_:
			var tex := _load_ui_tex("res://assets/ui/pad_tile.png")
			if tex:
				var tb := StyleBoxTexture.new()
				tb.texture = tex
				tb.set_content_margin_all(6)
				return tb
			box.bg_color = Color(0.05, 0.1, 0.14, 0.32)
			box.border_color = Color(0.25, 0.5, 0.6, 0.55)
			box.set_border_width_all(1)
	return box


static func pad_modulate(highlight: String = "") -> Color:
	match highlight:
		"drop":
			return Color(0.75, 1.15, 1.2, 1.0)
		"upgrade":
			return Color(1.1, 0.85, 1.25, 1.0)
		"sell":
			return Color(1.2, 0.7, 0.7, 1.0)
		"occupied":
			return Color(0.9, 0.95, 1.0, 0.95)
		_:
			return Color(0.9, 0.95, 1.0, 0.85)


static func apply_label_font(label: Label, size: int, bold: bool = false, display: bool = false) -> void:
	ensure_fonts()
	var f: Font
	if display and _font_display:
		f = _font_display
	elif bold and _font_bold:
		f = _font_bold
	else:
		f = _font_med if _font_med else _font_reg
	if f:
		label.add_theme_font_override("font", f)
	label.add_theme_font_size_override("font_size", size)
