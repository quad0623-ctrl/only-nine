extends VBoxContainer

const UnitSprites = preload("res://scripts/unit_sprites.gd")
const UiStyle = preload("res://scripts/ui_style.gd")

@onready var faction_row: HBoxContainer = $FactionRow
@onready var build_row: VBoxContainer = $BuildScroll/BuildRow
@onready var hint_label: Label = $HintLabel
@onready var ops_row: HBoxContainer = $OpsRow

var _faction_buttons: Dictionary = {}
var _unit_cards: Array[PanelContainer] = []
var _built_faction: String = ""
var _upgrade_btn: Button
var _sell_btn: Button


func _ready() -> void:
	# Convert FactionRow to horizontal if it was VBox in scene
	if faction_row == null:
		faction_row = get_node_or_null("FactionRow") as HBoxContainer
	_build_faction_tabs()
	_build_ops()
	UiStyle.apply_label_font(hint_label, 14, false)
	hint_label.add_theme_color_override("font_color", UiStyle.TEXT_MUTED)
	refresh()


func _build_faction_tabs() -> void:
	for child in faction_row.get_children():
		child.queue_free()
	_faction_buttons.clear()
	for faction_id in ["LUMINA", "VECTRA", "FERRUM"]:
		var f: Dictionary = GameData.FACTIONS[faction_id]
		var btn := Button.new()
		btn.text = str(f["name"]).to_upper()
		btn.custom_minimum_size = Vector2(0, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 14)
		var fid: String = faction_id
		btn.pressed.connect(func() -> void: GameState.set_faction_tab(fid))
		faction_row.add_child(btn)
		_faction_buttons[faction_id] = btn


func _build_ops() -> void:
	if ops_row == null:
		return
	for child in ops_row.get_children():
		child.queue_free()
	_upgrade_btn = Button.new()
	_upgrade_btn.text = "업그레이드"
	_upgrade_btn.custom_minimum_size = Vector2(0, 48)
	_upgrade_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgrade_btn.focus_mode = Control.FOCUS_NONE
	_upgrade_btn.pressed.connect(func() -> void: GameState.set_selected_action("UPGRADE"))
	ops_row.add_child(_upgrade_btn)

	_sell_btn = Button.new()
	_sell_btn.text = "판매"
	_sell_btn.custom_minimum_size = Vector2(0, 48)
	_sell_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sell_btn.focus_mode = Control.FOCUS_NONE
	_sell_btn.pressed.connect(func() -> void: GameState.set_selected_action("SELL"))
	ops_row.add_child(_sell_btn)


func refresh() -> void:
	for faction_id in _faction_buttons.keys():
		var btn: Button = _faction_buttons[faction_id]
		var c: Color = GameData.FACTIONS[faction_id]["color"]
		var active: bool = faction_id == GameState.faction_tab
		var box := UiStyle.btn_box(
			Color(c.r * 0.15, c.g * 0.15, c.b * 0.18, 0.95) if active else UiStyle.NAVY,
			Color(c.r, c.g, c.b, 0.9) if active else UiStyle.CYAN_DIM,
			2 if active else 1,
			8
		)
		btn.add_theme_stylebox_override("normal", box)
		btn.add_theme_stylebox_override("hover", box)
		btn.add_theme_stylebox_override("pressed", box)
		btn.add_theme_color_override("font_color", c.lightened(0.25) if active else UiStyle.TEXT_MUTED)

	if _built_faction != GameState.faction_tab or _unit_cards.is_empty():
		_rebuild_unit_cards()

	for card in _unit_cards:
		var key := str(card.get_meta("unit_key"))
		var def: Dictionary = GameData.get_unit(key)
		var can_afford: bool = GameState.gold >= int(def["cost"])
		card.modulate = Color(1, 1, 1, 1) if can_afford else Color(0.55, 0.55, 0.6, 0.85)
		var dragging: bool = GameState.drag_unit_type == key
		var accent: Color = GameData.FACTIONS[str(def["faction"])]["color"]
		card.add_theme_stylebox_override("panel", UiStyle.accent_panel(
			accent if dragging or can_afford else Color(0.3, 0.35, 0.4),
			12
		))

	if _upgrade_btn:
		var on: bool = GameState.selected_action == "UPGRADE"
		_upgrade_btn.add_theme_stylebox_override("normal", UiStyle.btn_box(
			Color(0.18, 0.1, 0.28, 0.95) if on else UiStyle.NAVY,
			Color(0.75, 0.45, 1.0) if on else UiStyle.CYAN_DIM,
			2 if on else 1, 8
		))
	if _sell_btn:
		var on2: bool = GameState.selected_action == "SELL"
		_sell_btn.add_theme_stylebox_override("normal", UiStyle.btn_box(
			Color(0.28, 0.08, 0.1, 0.95) if on2 else UiStyle.NAVY,
			UiStyle.DANGER if on2 else UiStyle.CYAN_DIM,
			2 if on2 else 1, 8
		))

	_update_hint()


func _update_hint() -> void:
	if hint_label == null:
		return
	if GameState.drag_unit_type != "":
		var def: Dictionary = GameData.get_unit(GameState.drag_unit_type)
		hint_label.text = "배치 중 · %s — 빈 칸에 놓으세요" % str(def.get("name", ""))
	elif GameState.selected_action == "UPGRADE":
		hint_label.text = "업그레이드할 유닛을 선택 (최대 Lv.%d)" % GameData.MAX_UNIT_LEVEL
	elif GameState.selected_action == "SELL":
		hint_label.text = "판매할 유닛을 선택 · 골드 50%% 환급"
	else:
		hint_label.text = "카드를 잡아 보드로 드래그하세요"


func _rebuild_unit_cards() -> void:
	for c in _unit_cards:
		c.queue_free()
	_unit_cards.clear()
	_built_faction = GameState.faction_tab

	# Remove old unit buttons left in BuildRow from previous layout
	for child in build_row.get_children():
		if child.name.begins_with("Upgrade") or child.name.begins_with("Sell"):
			child.queue_free()
		elif child is PanelContainer or child is Button:
			# clear all; ops live in OpsRow now
			if not (child.name == "UpgradeBtn" or child.name == "SellBtn"):
				child.queue_free()

	var keys: Array = GameData.UNIT_KEYS_BY_FACTION[GameState.faction_tab]
	for type_key in keys:
		var def: Dictionary = GameData.get_unit(type_key)
		var tint: Color = GameData.FACTIONS[str(def["faction"])]["color"]
		var card := _make_unit_card(str(type_key), def, tint)
		build_row.add_child(card)
		_unit_cards.append(card)


func _make_unit_card(type_key: String, def: Dictionary, tint: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 92)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.set_meta("unit_key", type_key)
	card.add_theme_stylebox_override("panel", UiStyle.accent_panel(tint, 12))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(68, 68)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = UnitSprites.get_texture(type_key, tint, 1)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)

	var title_row := HBoxContainer.new()
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(title_row)

	var name_l := Label.new()
	name_l.text = str(def["name"])
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.apply_label_font(name_l, 18, true)
	name_l.add_theme_color_override("font_color", Color.WHITE)
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(name_l)

	var cost_l := Label.new()
	cost_l.text = "%d G" % int(def["cost"])
	UiStyle.apply_label_font(cost_l, 16, true)
	cost_l.add_theme_color_override("font_color", UiStyle.GOLD)
	cost_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(cost_l)

	var blurb := Label.new()
	blurb.text = str(def.get("blurb", ""))
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label_font(blurb, 13, false)
	blurb.add_theme_color_override("font_color", UiStyle.TEXT_MUTED)
	blurb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(blurb)

	card.gui_input.connect(func(ev: InputEvent) -> void:
		if GameState.paused or GameState.game_over != "":
			return
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			GameState.begin_unit_drag(type_key)
		elif ev is InputEventScreenTouch and ev.pressed:
			GameState.begin_unit_drag(type_key)
	)
	return card
