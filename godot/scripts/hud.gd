extends HBoxContainer

const UiStyle = preload("res://scripts/ui_style.gd")

@onready var gold_label: Label = $GoldCard/Margin/VBox/Value
@onready var wave_label: Label = $WaveCard/Margin/VBox/Value
@onready var monster_label: Label = $ThreatCard/Margin/VBox/Value
@onready var speed_button: Button = $SpeedCard/Margin/VBox/SpeedButton
@onready var gold_card: PanelContainer = $GoldCard
@onready var wave_card: PanelContainer = $WaveCard
@onready var threat_card: PanelContainer = $ThreatCard
@onready var speed_card: PanelContainer = $SpeedCard

var _prev_gold: int = -1
var _pause_button: Button


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_style_card(gold_card, UiStyle.GOLD)
	_style_card(wave_card, UiStyle.CYAN)
	_style_card(threat_card, UiStyle.DANGER)
	_style_card(speed_card, UiStyle.CYAN_SOFT)
	speed_button.focus_mode = Control.FOCUS_NONE
	speed_button.pressed.connect(func() -> void: GameState.toggle_speed())
	_style_caption("GoldCard/Margin/VBox/Label", UiStyle.GOLD)
	_style_caption("WaveCard/Margin/VBox/Label", UiStyle.CYAN)
	_style_caption("ThreatCard/Margin/VBox/Label", UiStyle.DANGER)
	_style_caption("SpeedCard/Margin/VBox/Label", UiStyle.CYAN_SOFT)
	UiStyle.apply_label_font(gold_label, 30, true, true)
	UiStyle.apply_label_font(wave_label, 17, true, true)
	UiStyle.apply_label_font(monster_label, 28, true, true)
	gold_label.add_theme_color_override("font_color", UiStyle.GOLD)
	monster_label.add_theme_color_override("font_color", UiStyle.DANGER)
	_add_pause_card()
	refresh()


func _add_pause_card() -> void:
	if has_node("PauseCard"):
		_pause_button = get_node("PauseCard/Margin/VBox/PauseButton") as Button
		if _pause_button:
			_pause_button.pressed.connect(func() -> void: GameState.toggle_pause())
		return

	var card := PanelContainer.new()
	card.name = "PauseCard"
	card.custom_minimum_size = Vector2(100, 76)
	add_child(card)
	_style_card(card, Color(0.55, 0.75, 0.85))

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var caption := Label.new()
	caption.name = "Label"
	caption.text = "PAUSE"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label_font(caption, 11, true, true)
	caption.add_theme_color_override("font_color", Color(0.55, 0.75, 0.85, 0.85))
	vbox.add_child(caption)

	_pause_button = Button.new()
	_pause_button.name = "PauseButton"
	_pause_button.text = "Ⅱ"
	_pause_button.custom_minimum_size = Vector2(0, 34)
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.add_theme_font_size_override("font_size", 18)
	_pause_button.pressed.connect(func() -> void: GameState.toggle_pause())
	vbox.add_child(_pause_button)


func _style_caption(path: String, accent: Color) -> void:
	var l: Label = get_node_or_null(path)
	if l == null:
		return
	UiStyle.apply_label_font(l, 11, true, true)
	l.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.8))


func _style_card(card: PanelContainer, accent: Color) -> void:
	if card == null:
		return
	card.add_theme_stylebox_override("panel", UiStyle.accent_panel(accent, 10))
	card.custom_minimum_size = Vector2(maxi(int(card.custom_minimum_size.x), 100), 76)


func refresh() -> void:
	var paused_suffix := "  ·  PAUSED" if GameState.paused else ""
	if _prev_gold >= 0 and GameState.gold != _prev_gold:
		_punch(gold_label)
	_prev_gold = GameState.gold
	gold_label.text = str(GameState.gold)
	var phase := GameState.get_current_phase()
	var phase_name := "COMBAT" if str(phase.get("type", "")) == "COMBAT" else ("REST" if str(phase.get("type", "")) == "REST" else str(phase.get("type", "")))
	wave_label.text = "W%s  %s  %ds%s" % [str(phase.get("wave", 1)), phase_name, int(ceil(GameState.time_remaining)), paused_suffix]
	monster_label.text = "%d / %d" % [GameState.monsters.size(), GameData.MAX_MONSTERS]
	var fast: bool = GameState.time_scale > 1.5
	speed_button.text = "×2" if fast else "×1"
	speed_button.add_theme_stylebox_override("normal", UiStyle.btn_box(
		Color(0.08, 0.22, 0.24, 0.95) if fast else UiStyle.NAVY,
		UiStyle.CYAN if fast else UiStyle.CYAN_DIM,
		2 if fast else 1,
		8
	))
	if _pause_button:
		_pause_button.text = "▶" if GameState.paused else "Ⅱ"
		_pause_button.add_theme_stylebox_override("normal", UiStyle.btn_box(
			Color(0.12, 0.2, 0.28, 0.95) if GameState.paused else UiStyle.NAVY,
			UiStyle.CYAN if GameState.paused else UiStyle.CYAN_DIM,
			2 if GameState.paused else 1,
			8
		))


func _punch(node: Control) -> void:
	node.pivot_offset = node.size * 0.5
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector2(1.18, 1.18), 0.08)
	tw.tween_property(node, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)
