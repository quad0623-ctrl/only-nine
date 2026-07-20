extends Control

const IconFactory = preload("res://scripts/icon_factory.gd")
const UnitSprites = preload("res://scripts/unit_sprites.gd")
const MonsterSprites = preload("res://scripts/monster_sprites.gd")
const FxSprites = preload("res://scripts/fx_sprites.gd")
const UiStyle = preload("res://scripts/ui_style.gd")
const CELL := 96
const GAP := 6
const ATTACK_LIFE := 0.55
const TURRET_TURN_SPEED := 10.0 # higher = snappier Clash-like turn
const MOVE_SMOOTH := 14.0
const CRAFT_SIZE_BY_LEVEL := [0.0, 72.0, 84.0, 96.0]

const RangeOverlayScript = preload("res://scripts/range_overlay.gd")
const TrackRibbonScript = preload("res://scripts/track_ribbon.gd")

const SHADER_EMISSIVE := preload("res://shaders/sprite_emissive.gdshader")
const SHADER_OUTLINE := preload("res://shaders/sprite_outline.gdshader")

@onready var grid: GridContainer = $Grid
@onready var entity_layer: Control = $EntityLayer

var _cell_buttons: Array[Button] = []
var _monster_visuals: Dictionary = {} # id -> {root, body, hp_bg, hp_fill, display_pos}
var _unit_visuals: Dictionary = {} # id -> {turret, angle, recoil}
var _attack_visuals: Dictionary = {} # id -> {root, main, muzzle}
var _units_dirty: bool = true
var _drag_hover: Vector2i = Vector2i(-1, -1)
var _track_pulse: float = 0.0
var _range_overlay: Control
var _track_ribbon: Control
func _ready() -> void:
	custom_minimum_size = Vector2(CELL * 5 + GAP * 4, CELL * 5 + GAP * 4)
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", GAP)
	grid.add_theme_constant_override("v_separation", GAP)
	grid.z_index = 2
	for y in 5:
		for x in 5:
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(CELL, CELL)
			btn.focus_mode = Control.FOCUS_NONE
			btn.expand_icon = true
			btn.clip_text = true
			btn.add_theme_font_size_override("font_size", 11)
			var is_track := x == 0 or x == 4 or y == 0 or y == 4
			if is_track:
				btn.disabled = true
				btn.text = ""
				btn.modulate = Color(1, 1, 1, 0.55)
				btn.add_theme_stylebox_override("disabled", UiStyle.cell_track(0.0))
				btn.add_theme_stylebox_override("normal", UiStyle.cell_track(0.0))
			else:
				btn.add_theme_stylebox_override("normal", UiStyle.cell_pad())
				btn.add_theme_stylebox_override("hover", UiStyle.cell_pad("drop"))
				btn.add_theme_stylebox_override("pressed", UiStyle.cell_pad("occupied"))
				btn.add_theme_stylebox_override("disabled", UiStyle.cell_pad())
				var cx := x
				var cy := y
				btn.pressed.connect(func() -> void: GameState.on_cell_pressed(cx, cy))
			grid.add_child(btn)
			_cell_buttons.append(btn)
	entity_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entity_layer.size = Vector2(CELL * 5 + GAP * 4, CELL * 5 + GAP * 4)
	entity_layer.z_index = 4
	_track_ribbon = TrackRibbonScript.new()
	_track_ribbon.set_meta("cell_step", _cell_step())
	_track_ribbon.set_meta("cell", float(CELL))
	_track_ribbon.size = entity_layer.size
	_track_ribbon.z_index = 1
	add_child(_track_ribbon)
	move_child(_track_ribbon, 0)
	_range_overlay = RangeOverlayScript.new()
	_range_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_range_overlay.size = entity_layer.size
	_range_overlay.z_index = 5
	add_child(_range_overlay)
	GameState.monster_died_at.connect(_on_monster_died_at)
	GameState.gold_gained_at.connect(_on_gold_gained_at)
	GameState.drag_changed.connect(_update_range_preview)
	set_process(true)
	refresh()


func _make_outline_emissive(outline: Color, _glow: float = 0.35) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_OUTLINE
	mat.set_shader_parameter("outline_color", outline)
	mat.set_shader_parameter("outline_size", 1.4)
	mat.set_shader_parameter("alpha_threshold", 0.16)
	return mat


func _make_emissive_mat(tint: Color, strength: float = 0.5) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_EMISSIVE
	mat.set_shader_parameter("glow_strength", strength)
	mat.set_shader_parameter("glow_tint", tint)
	mat.set_shader_parameter("pulse_speed", 2.4)
	mat.set_shader_parameter("pulse_amount", 0.1)
	return mat


func _update_range_preview() -> void:
	if _range_overlay == null:
		return
	if GameState.drag_unit_type == "" or _drag_hover.x < 0:
		_range_overlay.clear_range()
		return
	var def: Dictionary = GameData.get_unit(GameState.drag_unit_type)
	if def.is_empty():
		_range_overlay.clear_range()
		return
	var sight := float(def["sight"]) * sqrt(2.0)
	var center := _grid_to_px(float(_drag_hover.x), float(_drag_hover.y))
	var radius := sight * _cell_step()
	var fac: Color = GameData.FACTIONS[str(def["faction"])]["color"]
	_range_overlay.set_range(center, radius, fac)


func _on_gold_gained_at(gx: float, gy: float, amount: int) -> void:
	var lbl := Label.new()
	lbl.text = "+%d" % amount
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.apply_label_font(lbl, 20, true, true)
	lbl.add_theme_color_override("font_color", UiStyle.GOLD)
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.1, 0.9))
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.position = _grid_to_px(gx, gy) + Vector2(-16, -32)
	lbl.z_index = 20
	lbl.pivot_offset = Vector2(16, 10)
	lbl.scale = Vector2(0.7, 0.7)
	entity_layer.add_child(lbl)
	var tw := lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 42.0, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.75).set_delay(0.15)
	tw.chain().tween_callback(lbl.queue_free)


func _on_monster_died_at(gx: float, gy: float, is_boss: bool) -> void:
	var pos := _grid_to_px(gx, gy)
	var burst := TextureRect.new()
	burst.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	burst.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.material = _make_add_material()
	burst.texture = FxSprites.splash("LUMINA" if not is_boss else "FERRUM")
	var s := CELL * (1.85 if is_boss else 1.05)
	burst.size = Vector2(s, s)
	burst.pivot_offset = Vector2(s * 0.5, s * 0.5)
	burst.position = pos - burst.pivot_offset
	burst.modulate = Color(1.55, 1.25, 0.65, 1.0) if is_boss else Color(1.25, 1.15, 1.05, 0.95)
	burst.z_index = 12
	entity_layer.add_child(burst)
	_spawn_hit_sparks(pos, Color(1.0, 0.85, 0.45) if is_boss else Color(0.6, 0.95, 1.0), 14 if is_boss else 8)
	var tw := burst.create_tween()
	tw.set_parallel(true)
	tw.tween_property(burst, "scale", Vector2.ONE * (2.1 if is_boss else 1.55), 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(burst, "modulate:a", 0.0, 0.42)
	tw.tween_property(burst, "rotation", 1.8, 0.42)
	tw.chain().tween_callback(burst.queue_free)
	if is_boss:
		_shake_board()


func _spawn_hit_sparks(pos: Vector2, color: Color, count: int) -> void:
	for i in count:
		var spark := ColorRect.new()
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spark.size = Vector2(3, 3)
		spark.color = color
		spark.position = pos
		spark.z_index = 15
		entity_layer.add_child(spark)
		var ang := randf() * TAU
		var dist := randf_range(18.0, 54.0)
		var dest := pos + Vector2(cos(ang), sin(ang)) * dist
		var tw := spark.create_tween()
		tw.set_parallel(true)
		tw.tween_property(spark, "position", dest, randf_range(0.22, 0.4)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(spark, "modulate:a", 0.0, 0.4)
		tw.tween_property(spark, "size", Vector2(1, 1), 0.4)
		tw.chain().tween_callback(spark.queue_free)


func _shake_board() -> void:
	var origin := position
	var tw := create_tween()
	for i in 5:
		var off := Vector2(randf_range(-6, 6), randf_range(-6, 6)) * (1.0 - float(i) / 5.0)
		tw.tween_property(self, "position", origin + off, 0.04)
	tw.tween_property(self, "position", origin, 0.05)


func refresh() -> void:
	_units_dirty = true


func clear_drag_hover() -> void:
	_drag_hover = Vector2i(-1, -1)
	_units_dirty = true
	_update_range_preview()


func set_drag_hover_from_global(global_pos: Vector2) -> void:
	var cell := get_cell_at_global(global_pos)
	if cell != _drag_hover:
		_drag_hover = cell
		_units_dirty = true
		_update_range_preview()


func try_drop_at_global(global_pos: Vector2) -> void:
	var cell := get_cell_at_global(global_pos)
	if cell.x < 0:
		GameState.clear_unit_drag()
		clear_drag_hover()
		return
	GameState.try_drop_unit(cell.x, cell.y)
	clear_drag_hover()


func get_cell_at_global(global_pos: Vector2) -> Vector2i:
	var local := get_global_transform_with_canvas().affine_inverse() * global_pos
	var step := _cell_step()
	var x := int(floor(local.x / step))
	var y := int(floor(local.y / step))
	if x < 0 or x > 4 or y < 0 or y > 4:
		return Vector2i(-1, -1)
	var is_track := x == 0 or x == 4 or y == 0 or y == 4
	if is_track:
		return Vector2i(-1, -1)
	return Vector2i(x, y)


func _process(delta: float) -> void:
	_track_pulse = 0.5 + 0.5 * sin(GameState.get_elapsed_time() * 2.2)
	_pulse_track_cells()
	if _units_dirty:
		_sync_unit_cells()
		_units_dirty = false
	_sync_unit_turrets(delta)
	_sync_monsters(delta)
	_sync_attacks()


func _pulse_track_cells() -> void:
	var style := UiStyle.cell_track(_track_pulse)
	var mod := UiStyle.track_modulate(_track_pulse)
	for y in 5:
		for x in 5:
			if not (x == 0 or x == 4 or y == 0 or y == 4):
				continue
			var btn: Button = _cell_buttons[y * 5 + x]
			btn.add_theme_stylebox_override("disabled", style)
			btn.add_theme_stylebox_override("normal", style)
			btn.modulate = mod


func _cell_step() -> float:
	return float(CELL + GAP)


func _grid_to_px(gx: float, gy: float) -> Vector2:
	var step := _cell_step()
	return Vector2(gx * step + CELL * 0.5, gy * step + CELL * 0.5)


func _monster_track_angle(progress: float) -> float:
	var clamped := clampf(progress, 0.0, 15.999)
	var index := int(floor(clamped))
	var next_index := mini(index + 1, 15)
	var p1: Vector2i = GameData.TRACK_PATH[index]
	var p2: Vector2i = GameData.TRACK_PATH[next_index]
	return Vector2(float(p2.x - p1.x), float(p2.y - p1.y)).angle()


func _sync_unit_cells() -> void:
	for y in 5:
		for x in 5:
			var idx := y * 5 + x
			var btn: Button = _cell_buttons[idx]
			var is_track := x == 0 or x == 4 or y == 0 or y == 4
			if is_track:
				continue
			var found: Dictionary = {}
			for u in GameState.units:
				if int(u["x"]) == x and int(u["y"]) == y:
					found = u
					break
			if found.is_empty():
				btn.text = ""
				btn.icon = null
				btn.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 0.9))
				var empty_hl := "drop" if GameState.drag_unit_type != "" and _drag_hover.x == x and _drag_hover.y == y else ""
				btn.add_theme_stylebox_override("normal", UiStyle.cell_pad(empty_hl))
				btn.add_theme_stylebox_override("hover", UiStyle.cell_pad("drop"))
				btn.modulate = UiStyle.pad_modulate(empty_hl)
			else:
				var def: Dictionary = GameData.get_unit(str(found["type"]))
				var faction: Dictionary = GameData.FACTIONS[str(def["faction"])]
				var tint: Color = faction["color"]
				var lv := int(found["level"])
				var hl := "occupied"
				if GameState.selected_action == "UPGRADE" and lv < GameData.MAX_UNIT_LEVEL:
					hl = "upgrade"
				elif GameState.selected_action == "SELL":
					hl = "sell"
				btn.add_theme_stylebox_override("normal", UiStyle.cell_pad(hl))
				btn.add_theme_stylebox_override("hover", UiStyle.cell_pad(hl))
				btn.modulate = UiStyle.pad_modulate(hl)
				btn.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 0.95))
				if UnitSprites.has_art(str(found["type"]), lv):
					btn.icon = null
					btn.text = "Lv.%d" % lv
					btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
				else:
					btn.icon = IconFactory.get_unit_icon(str(found["type"]), tint.darkened(0.15), lv)
					btn.text = "Lv.%d" % lv


func _sync_unit_turrets(delta: float) -> void:
	var live_ids: Dictionary = {}
	var now := GameState.get_elapsed_time()
	for u in GameState.units:
		var id := int(u["id"])
		live_ids[id] = true
		var type_key := str(u["type"])
		var lv := int(u["level"])
		var def: Dictionary = GameData.get_unit(type_key)
		var faction: Dictionary = GameData.FACTIONS[str(def["faction"])]
		var tint: Color = faction["color"]
		var use_art := UnitSprites.has_art(type_key, lv)

		if not _unit_visuals.has(id):
			var node: Control
			var craft_sz: float = CRAFT_SIZE_BY_LEVEL[clampi(lv, 1, 3)]
			if use_art:
				var tr := TextureRect.new()
				tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tr.size = Vector2(craft_sz, craft_sz)
				tr.pivot_offset = Vector2(craft_sz * 0.5, craft_sz * 0.5)
				tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
				tr.texture = UnitSprites.get_texture(type_key, tint, lv)
				tr.material = _make_emissive_mat(Color(tint.r, tint.g, tint.b, 1.0), 0.45 + 0.1 * float(lv))
				node = tr
			else:
				var turret := ColorRect.new()
				turret.size = Vector2(10, 28)
				turret.pivot_offset = Vector2(5, 22)
				turret.mouse_filter = Control.MOUSE_FILTER_IGNORE
				node = turret
			entity_layer.add_child(node)
			_unit_visuals[id] = {"node": node, "angle": 0.0, "art": use_art, "level": lv, "type": type_key}

		var vis: Dictionary = _unit_visuals[id]
		# Rebuild visual if tier art changed
		if bool(vis.get("art", false)) != use_art or int(vis.get("level", 1)) != lv or str(vis.get("type", "")) != type_key:
			(vis["node"] as CanvasItem).queue_free()
			_unit_visuals.erase(id)
			continue

		var node: Control = vis["node"]
		var center := _grid_to_px(float(u["x"]), float(u["y"]))
		var target_angle: float = float(vis["angle"])
		if bool(u.get("has_aim", false)):
			var aim := _grid_to_px(float(u["aim_x"]), float(u["aim_y"]))
			target_angle = (aim - center).angle()
			if not use_art:
				target_angle += PI * 0.5

		var t := 1.0 - exp(-TURRET_TURN_SPEED * delta)
		vis["angle"] = lerp_angle(float(vis["angle"]), target_angle, t)
		node.rotation = float(vis["angle"])

		var recoil := 0.0
		if float(u.get("recoil_until", 0.0)) > now:
			recoil = 3.0 if use_art else 4.0
		var tip := Vector2(-recoil, 0).rotated(float(vis["angle"])) if use_art else Vector2(0, -recoil).rotated(float(vis["angle"]))
		node.position = center - node.pivot_offset + tip

		if use_art:
			var pulse := 1.0 + 0.03 * sin(now * 3.5 + float(id))
			node.scale = Vector2(pulse, pulse)
			var glow := 1.04 + 0.06 * sin(now * 2.2 + float(id) * 0.7)
			node.modulate = Color(glow, glow, glow * 1.02, 1.0)
		else:
			(node as ColorRect).color = Color(tint.r, tint.g, tint.b, 0.95)

		_unit_visuals[id] = vis

	var to_remove: Array = []
	for id in _unit_visuals.keys():
		if not live_ids.has(id):
			(_unit_visuals[id]["node"] as CanvasItem).queue_free()
			to_remove.append(id)
	for id in to_remove:
		_unit_visuals.erase(id)


func _sync_monsters(delta: float) -> void:
	var live_ids: Dictionary = {}
	var now := GameState.get_elapsed_time()
	var step := _cell_step()
	for m in GameState.monsters:
		var id := int(m["id"])
		live_ids[id] = true
		var target := GameState.get_monster_position(float(m["progress"]))
		var target_px := Vector2(target.x * step + CELL * 0.5, target.y * step + CELL * 0.5)
		var size := CELL * (1.25 if m.get("is_boss", false) else 0.8)

		var type_key := str(m.get("type", "GOBLIN"))
		var is_boss := bool(m.get("is_boss", false))
		var use_art := MonsterSprites.has_art(type_key)

		if not _monster_visuals.has(id):
			var root := Control.new()
			root.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var body: Control
			if use_art:
				var tr := TextureRect.new()
				tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
				body = tr
			else:
				var cr := ColorRect.new()
				cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
				body = cr
			if use_art and body is TextureRect:
				var outline := Color(m["color"]) if m.has("color") else Color(1.0, 0.45, 0.4)
				var mat := _make_outline_emissive(Color(outline.r, outline.g, outline.b, 0.8), 0.35)
				(body as TextureRect).material = mat
			var hp_bg := ColorRect.new()
			hp_bg.color = Color(0.02, 0.04, 0.06, 0.82)
			hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var hp_fill := ColorRect.new()
			hp_fill.color = Color(0.25, 0.95, 0.55, 1.0)
			hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var hp_edge := ColorRect.new()
			hp_edge.color = Color(0.55, 0.95, 1.0, 0.55)
			hp_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			root.add_child(body)
			root.add_child(hp_bg)
			root.add_child(hp_fill)
			root.add_child(hp_edge)
			entity_layer.add_child(root)
			_monster_visuals[id] = {
				"root": root,
				"body": body,
				"hp_bg": hp_bg,
				"hp_fill": hp_fill,
				"hp_edge": hp_edge,
				"display_pos": target_px,
				"art": use_art,
				"type": type_key,
			}

		var vis: Dictionary = _monster_visuals[id]
		if bool(vis.get("art", false)) != use_art or str(vis.get("type", "")) != type_key:
			(vis["root"] as CanvasItem).queue_free()
			_monster_visuals.erase(id)
			continue

		var display: Vector2 = vis["display_pos"]
		var mt := 1.0 - exp(-MOVE_SMOOTH * delta)
		display = display.lerp(target_px, mt)
		vis["display_pos"] = display

		var body: Control = vis["body"]
		var flashing := float(m.get("flash_until", 0.0)) > now
		body.size = Vector2(size, size)
		body.position = Vector2(-size * 0.5, -size * 0.5)
		if use_art:
			var tr: TextureRect = body as TextureRect
			tr.texture = MonsterSprites.get_texture(type_key, m["color"], is_boss)
			tr.modulate = Color(1.2, 1.2, 1.2, 1.0) if flashing else Color.WHITE
			tr.pivot_offset = Vector2(size * 0.5, size * 0.5)
			tr.rotation = _monster_track_angle(float(m["progress"])) + PI * 0.5
			var wobble := 1.0 + 0.04 * sin(now * 5.0 + float(id)) if is_boss else 1.0
			tr.scale = Vector2(wobble, wobble)
		else:
			var cr: ColorRect = body as ColorRect
			cr.color = Color(1, 1, 1, 0.95) if flashing else m["color"]

		var hp_bg: ColorRect = vis["hp_bg"]
		var hp_fill: ColorRect = vis["hp_fill"]
		var hp_edge: ColorRect = vis.get("hp_edge")
		var bar_w := size * 0.92
		var bar_h := 5.0
		hp_bg.size = Vector2(bar_w, bar_h + 2.0)
		hp_bg.position = Vector2(-bar_w * 0.5, -size * 0.5 - 14)
		var ratio := clampf(float(m["hp"]) / maxf(float(m["max_hp"]), 0.01), 0.0, 1.0)
		hp_fill.size = Vector2(maxf(bar_w * ratio - 2.0, 0.0), bar_h)
		hp_fill.position = hp_bg.position + Vector2(1, 1)
		if ratio > 0.55:
			hp_fill.color = Color(0.35, 0.98, 0.7, 1.0)
		elif ratio > 0.28:
			hp_fill.color = Color(1.0, 0.86, 0.3, 1.0)
		else:
			hp_fill.color = Color(1.0, 0.38, 0.4, 1.0)
		if hp_edge:
			hp_edge.size = Vector2(2, bar_h)
			hp_edge.position = hp_fill.position + Vector2(hp_fill.size.x - 1.0, 0)
			hp_edge.visible = ratio > 0.04
			hp_edge.color = Color(1, 1, 1, 0.65)

		(vis["root"] as Control).position = display
		_monster_visuals[id] = vis

	var dead: Array = []
	for id in _monster_visuals.keys():
		if not live_ids.has(id):
			(_monster_visuals[id]["root"] as CanvasItem).queue_free()
			dead.append(id)
	for id in dead:
		_monster_visuals.erase(id)


func _make_add_material() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat


func _sync_attacks() -> void:
	var live_ids: Dictionary = {}
	var now := GameState.get_elapsed_time()
	var step := _cell_step()
	for a in GameState.attacks:
		var id := int(a["id"])
		live_ids[id] = true
		var age := now - float(a["time"])
		var life_t := clampf(1.0 - age / ATTACK_LIFE, 0.0, 1.0)
		var faction_color: Color = GameData.FACTIONS.get(str(a["faction"]), {}).get("color", Color.CYAN)
		var tint := FxSprites.faction_modulate(faction_color, 1.0)

		if not _attack_visuals.has(id):
			var fac := str(a["faction"])
			var root := Control.new()
			root.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var main := TextureRect.new()
			main.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			main.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			main.mouse_filter = Control.MOUSE_FILTER_IGNORE
			main.material = _make_add_material()
			var muzzle := TextureRect.new()
			muzzle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			muzzle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			muzzle.mouse_filter = Control.MOUSE_FILTER_IGNORE
			muzzle.material = _make_add_material()
			muzzle.texture = FxSprites.muzzle(fac)
			muzzle.size = Vector2(52, 52)
			muzzle.pivot_offset = Vector2(26, 26)
			if str(a["mode"]) == "splash":
				main.texture = FxSprites.splash(fac)
			else:
				main.texture = FxSprites.projectile(fac)
			root.add_child(main)
			root.add_child(muzzle)
			entity_layer.add_child(root)
			_attack_visuals[id] = {"root": root, "main": main, "muzzle": muzzle, "spawned_sparks": false}

		var vis: Dictionary = _attack_visuals[id]
		var main: TextureRect = vis["main"]
		var muzzle: TextureRect = vis["muzzle"]
		main.modulate = Color(tint.r, tint.g, tint.b, life_t)

		if str(a["mode"]) == "splash":
			var hit := Vector2(float(a["tx"]) * step + CELL * 0.5, float(a["ty"]) * step + CELL * 0.5)
			if not bool(vis.get("spawned_sparks", false)) and age < 0.05:
				_spawn_hit_sparks(hit, faction_color.lightened(0.35), 5)
				vis["spawned_sparks"] = true
				_attack_visuals[id] = vis
			var s := CELL * (1.2 + 1.0 * (1.0 - life_t))
			main.size = Vector2(s, s)
			main.pivot_offset = Vector2(s * 0.5, s * 0.5)
			main.position = hit - main.pivot_offset
			main.rotation = age * 2.8
			main.scale = Vector2.ONE * (0.85 + 0.4 * (1.0 - life_t))
			var mz := 60.0 * life_t
			muzzle.visible = age < 0.14
			muzzle.size = Vector2(mz, mz)
			muzzle.pivot_offset = Vector2(mz * 0.5, mz * 0.5)
			muzzle.position = hit - muzzle.pivot_offset
			muzzle.modulate = Color(tint.r * 1.15, tint.g * 1.15, tint.b * 1.15, life_t)
			muzzle.rotation = -age * 6.0
		else:
			var sx := float(a["sx"]) * step + CELL * 0.5
			var sy := float(a["sy"]) * step + CELL * 0.5
			var tx := float(a["tx"]) * step + CELL * 0.5
			var ty := float(a["ty"]) * step + CELL * 0.5
			var travel := 1.0 - life_t
			var p0 := Vector2(sx, sy).lerp(Vector2(tx, ty), clampf(travel * 1.2, 0.0, 1.0))
			var delta_v := Vector2(tx - sx, ty - sy)
			var beam_len := clampf(delta_v.length() * 0.35, 40.0, 120.0)
			main.size = Vector2(beam_len, 28)
			main.pivot_offset = Vector2(0, 14)
			main.position = p0 - Vector2(0, 14)
			main.rotation = delta_v.angle()
			muzzle.visible = age < 0.1
			muzzle.size = Vector2(52, 52)
			muzzle.pivot_offset = Vector2(26, 26)
			muzzle.position = Vector2(sx, sy) - muzzle.pivot_offset
			muzzle.modulate = Color(1.2, 1.2, 1.2, clampf(1.0 - age / 0.1, 0.0, 1.0))
			muzzle.rotation = delta_v.angle()
			muzzle.scale = Vector2.ONE * maxf(0.4, 1.2 - age * 4.0)

	var gone: Array = []
	for id in _attack_visuals.keys():
		if not live_ids.has(id):
			(_attack_visuals[id]["root"] as CanvasItem).queue_free()
			gone.append(id)
	for id in gone:
		_attack_visuals.erase(id)
